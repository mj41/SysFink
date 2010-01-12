package SysFink::Conf::DBIC;

use strict;
use warnings;

use DateTime;
use Data::Compare;

use SysFink::Conf::SysFink;

use lib '../client/lib';
use base 'SysFink::Conf';


=head1 NAME

SysFink::Conf::DBIC - SysFink configuration class for loading by DBIx::Class schema object.

=head1 SYNOPSIS

ToDo. See L<SysFink>.

=head1 DESCRIPTION

ToDo. See L<SysFink>.

=head1 METHODS

=head2 new

Constructor. Parameters: DBIx::Class schema object.

=cut

sub new {
    my ( $class, $params ) = @_;
    my $self = $class->SUPER::new( $params );

    $self->{schema} = $params->{schema};
    return $self;
}


=head2 get_machine_id

Return machine_id for given host.

=cut

sub get_machine_id {
    my ( $self, $host ) = @_;

    my $machine_row = $self->{schema}->resultset('machine')->find({ name => $host, });
    return $self->err("Can't find machine_id for host '$host' in DB.") unless defined $machine_row;
    return $machine_row->machine_id;
}


=head2 get_machine_active_mconf_sec_info

Return active mconf_id for machine_id and sec_name.

=cut

sub get_machine_active_mconf_sec_info {
    my ( $self, $machine_id, $section_name ) = @_;

    my $row = $self->{schema}->resultset('mconf_sec')->find({
        'machine_id.machine_id' => $machine_id,
        'mconf_id.active' => 1,
        'me.name' => $section_name,
    },{
        'join' => { 'mconf_id' => 'machine_id' },
        'select' => [ 'me.mconf_sec_id', 'me.mconf_id', ],
        'as' => [ 'mconf_sec_id', 'mconf_id', ],
    });

    return $self->err("Can't find mconf_sec_id for machine_id '$machine_id' and section name '$section_name' in DB.") unless $row;
    return [ $row->get_column('mconf_sec_id'), $row->get_column('mconf_id') ];
}


=head2 load_conf_data_from_rs

Load and normalize configuration from given record set.

=cut

sub load_conf_data_from_rs {
    my ( $self, $mconf_sec_kv_rs, $only_one_section, $unwrap_paths ) = @_;

    my $all_data = {};
    my $mdata = {};
    my $last_machine_name = '';
    my $last_section_name = '';
    my $machines_found = 0;
    my $sections_found = 0;
    while ( my $row_obj = $mconf_sec_kv_rs->next ) {
        my %row = ( $row_obj->get_columns() );
        
        if ( $row{section_name} ne $last_section_name || $row{machine_name} ne $last_machine_name ) {
            if ( $row{machine_name} ne $last_machine_name ) {
                $all_data->{ $row{machine_name} } = {};
                $machines_found++;
            }
            $all_data->{ $row{machine_name} }->{ $row{section_name} } = {};
            $mdata = $all_data->{ $row{machine_name} }->{ $row{section_name} };
            $sections_found++;
            $last_machine_name = $row{machine_name};
            $last_section_name = $row{section_name};
        }

        my $name = $row{name};
        my $new_value = $row{value};
        
        if ( exists $mdata->{$name} ) {
            if ( ref $mdata->{$name} eq 'ARRAY' ) {
                my $prev_val = $mdata->{$name};
                push @{$mdata->{$name}}, $new_value;
            } else {
                my $prev_val = $mdata->{$name};
                $mdata->{$name} = [ $prev_val, $new_value ];
            }
        } else {
            $mdata->{$name} = $new_value;
        }
    }

    return $all_data unless $unwrap_paths;
    
    foreach my $machine_name ( keys %$all_data ) {
        foreach my $section_name ( keys %{ $all_data->{ $machine_name } } ) {
            my $mdata = $all_data->{ $machine_name }->{ $section_name };

            # Prepare paths. Should be sorted already.
            if ( exists $mdata->{paths} && $mdata->{paths} ) {
                # Only one value. Change to array ref.
                if ( not ref $mdata->{paths} ) {
                    $mdata->{paths} = [ $mdata->{paths} ];
                }

                my $new_paths = [];
                foreach my $num ( 0..$#{$mdata->{paths}} ) {
                    my $flags_and_path = $mdata->{paths}->[ $num ];

                    # Try to split path and flags.
                    if ( my ( $path, $flags_str ) = $flags_and_path =~ m{^ (.*) \[ (.+?) \] $}x ) {
                        my %flags = $self->flags_str_to_hash( $flags_str );
                        push @$new_paths, [ $path, \%flags, ];

                    } else {
                        # ToDo - error
                    }
                }
                $mdata->{paths} = $new_paths;
            }
        }
    }


    if ( $only_one_section ) {
        if ( $sections_found != 1 || $machines_found != 1 ) {
            return $self->err("Should found one section on one machine, but found $sections_found on $machines_found.");
        }
        return $all_data->{ $last_machine_name }-> { $last_section_name };
    }

    return $all_data;
}


=head2 get_mconf_sec_kv_rs

Return RecorSet prepared fo load_conf_data_from_rs method.

=cut

sub get_mconf_sec_kv_rs {
    my ( $self, $search_conf ) = @_;

    my $mconf_sec_kv_rs = $self->{schema}->resultset('mconf_sec_kv')->search(
        $search_conf,
        {
            'join' => { 'mconf_sec_id' => { 'mconf_id' => 'machine_id' } },
            'select' => [ 'machine_id.name', 'mconf_sec_id.name', 'me.name', 'me.value', 'me.num' ],
            'as' => [ 'machine_name', 'section_name', 'name', 'value', 'num' ],
            'order_by' => [ 'machine_id.machine_id', 'mconf_sec_id.mconf_sec_id', 'me.name', 'me.num' ],
        }
    );

    return $mconf_sec_kv_rs;
}


=head2 load_general_conf

Load and canonize configuration for given machine_id and 'general' configuration 
of mconf_id.

=cut

sub load_general_conf {
    my ( $self, $machine_id, $mconf_id ) = @_;

    my $mconf_sec_kv_rs = $self->get_mconf_sec_kv_rs({
        'mconf_sec_id.mconf_id' => $mconf_id,
        'mconf_sec_id.name' => 'general',
    });

    my $data = $self->load_conf_data_from_rs(
        $mconf_sec_kv_rs,
        1, # $only_one_section
        1  # $unwrap_paths
    );
    return $self->err("Can't load general configuration for machine_id '$machine_id' and mconf_id '$mconf_id' in DB.") unless $data;
    return $data;
}


=head2 load_sec_conf

Load and canonize configuration for given machine_id and mconf_sec_id.

=cut

sub load_sec_conf {
    my ( $self, $machine_id, $mconf_sec_id ) = @_;

    my $mconf_sec_kv_rs = $self->get_mconf_sec_kv_rs({
        'me.mconf_sec_id' => $mconf_sec_id,
    });

    my $data = $self->load_conf_data_from_rs(
        $mconf_sec_kv_rs,
        1, # $only_one_section
        1  # $unwrap_paths
    );
    return $self->err("Can't load section configuration for machine_id '$machine_id' and mconf_sec_id '$mconf_sec_id' in DB.") unless $data;
    return $data;
}



=head2 load_active_conf

Load active configuration for given machine_id or for all machines. Do not unwrap paths
if $not_unwrap_paths is set.

=cut

sub load_active_conf {
    my ( $self, $machine_id, $not_unwrap_paths ) = @_;
    $not_unwrap_paths = 0 unless defined $not_unwrap_paths;

    my $search_conf = {
        'machine_id.active' => 1,
        'mconf_id.active' => 1,
    };
    $search_conf->{'machine_id.machine_id'} = $machine_id if defined $machine_id;

    my $mconf_sec_kv_rs = $self->get_mconf_sec_kv_rs( $search_conf );

    my $data = $self->load_conf_data_from_rs(
        $mconf_sec_kv_rs,
        0, # $only_one_section
        ! $not_unwrap_paths
    );
    return $data;
}


=head2 mconf_to_db

Actualize machines configurations in DB by these loaded from configuration files
inside machine-conf directory.

=cut

sub mconf_to_db  {
    my ( $self, $machine_conf_fp, $user_id ) = @_;

    my $schema = $self->{schema};
    $schema->storage->txn_begin;

    my $old_confs = $self->load_active_conf( undef, 1 );
    print $self->dump( 'loaded_from_db', $old_confs ) if $self->{ver} >= 10;

    my $mconf_obj = SysFink::Conf::SysFink->new({ conf_dir_path => $machine_conf_fp });
    $mconf_obj->load_config();
    my $mconf = $mconf_obj->conf;

    #print Dumper( $mconf );


    # Change counter.
    my $ch_count = {
        found => 0,
        added => 0,
        changed => 0,
        removed => 0,
    };

    my $mconf_change_values = {
        'date'=> DateTime->now,
        'user_id' => $user_id,
    };
    my $mconf_change_row = $schema->resultset('mconf_change')->create( $mconf_change_values );


    # Insert and modify.
    NEW_MACHINE_CONF: foreach my $machine_name ( keys %$mconf ) {

        print "machine: $machine_name\n" if $self->{ver} >= 4;
        my $machine_conf = $mconf->{$machine_name};

        # Get machine_id by machine name.
        my $machine_row = $schema->resultset('machine')->find_or_create({
            'name' => $machine_name,
        });
        my $machine_id = $machine_row->id;
        $machine_row->update({ active => 1, }) unless $machine_row->active;
        
        $ch_count->{found}++;
        if ( exists $old_confs->{ $machine_name } ) {
            my $compare_obj = new Data::Compare( $old_confs->{ $machine_name }, $machine_conf );
            if ( $compare_obj->Cmp ) {
                print "Machine '$machine_name' configuration not changed.\n" if $self->{ver} >= 3;
                # are same
                next NEW_MACHINE_CONF;
            } else {
                print "Machine '$machine_name' configuration changed.\n" if $self->{ver} >= 3;
            }
        } else {
            $ch_count->{added}++;
            print "Machine '$machine_name' added.\n" if $self->{ver} >= 3;
        }

        # Inactivate all machine configs (mconf).
        my $mconf_to_inactivate_rs = $schema->resultset('mconf')->search({
            'machine_id' => $machine_id,
            'active' => 1,
            
        });
        $mconf_to_inactivate_rs->update({
            'active' => 0,
        });

        # print "$machine_name $machine_id\n"; # debug

        my $mconf_row = $schema->resultset('mconf')->create({
            'machine_id' => $machine_id,
            'mconf_change_id' => $mconf_change_row->id,
            'active' => 1,
        });

        my $order_number = {};
        foreach my $section_name ( keys %$machine_conf ) {

            print "  section: $section_name\n" if $self->{ver} >= 4;
            my $section_kv = $machine_conf->{$section_name};

            my $mconf_sec_row = $schema->resultset('mconf_sec')->create({
                'mconf_id' => $mconf_row->id,
                'name' => $section_name,
            });

            foreach my $name ( keys %$section_kv ) {

                $order_number->{$section_name}->{$name} = 0 unless exists $order_number->{$section_name}->{$name};

                my $value = $section_kv->{$name};
                print "    key-value: $name\n" if $self->{ver} >= 4;

                if ( ref $value eq 'ARRAY' ) {
                    foreach my $value_index ( 0..$#$value ) {
                        my $one_value = $value->[ $value_index ];
                        $order_number->{$section_name}->{$name}++;
                        my $mconf_sec_kv_row = $schema->resultset('mconf_sec_kv')->create({
                            'mconf_sec_id' => $mconf_sec_row->id,
                            'num' => $order_number->{$section_name}->{$name},
                            'name' => $name,
                            'value' => $one_value,
                        });
                    }

                } elsif ( not ref $value ) {
                    $order_number->{$section_name}->{$name}++;
                    my $mconf_sec_kv_row = $schema->resultset('mconf_sec_kv')->create({
                        'mconf_sec_id' => $mconf_sec_row->id,
                        'num' => $order_number->{$section_name}->{$name},
                        'name' => $name,
                        'value' => $value,
                    });

                } else {
                    return $self->err("Uknown value for key $machine_name:$section_name:$name.");
                }
            }
        }
    }


    # Delete removed machines.
    foreach my $machine_name ( keys %$old_confs ) {
        next if exists $mconf->{ $machine_name };
        
        print "Machine '$machine_name' was removed.\n" if $self->{ver} >= 3;
        $ch_count->{removed}++;
        
        my $machine_row = $schema->resultset('machine')->find({
            'name' => $machine_name,
            'active' => 1,
        });
        $machine_row->update({ 'active' => 0 });

        my $mconf_row = $schema->resultset('mconf')->find({
            'machine_id' => $machine_row->machine_id,
            'active' => 1,
        });
        $mconf_row->update({ 'active' => 0 });
    }

    # Update found, added, ... values.
    $mconf_change_row->update( $ch_count );

    $schema->storage->txn_commit;
    return 1;
}


=head1 SEE ALSO

L<SysFink::Conf>, L<SysFink>

=head1 LICENSE

This file is part of SysFink. See L<SysFink> license.

=cut


1;
