package SysFink::Conf::DBIC;

use strict;
use warnings;

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

Return machine_id for given search params.

=cut

sub get_machine_id {
    my ( $self, $search_data ) = @_;

    my $machine_row = $self->{schema}->resultset('machine')->find( $search_data );
    return undef unless defined $machine_row;
    return $machine_row->machine_id;
}


=head2 get_machine_active_mconf_sec_info

Return active mconf_id for machine_id and sec_name.

=cut

sub get_machine_active_mconf_sec_info {
    my ( $self, $machine_id, $sec_name ) = @_;

    my $row = $self->{schema}->resultset('mconf_sec')->find({
        'machine_id.machine_id' => $machine_id,
        'mconf_id.active' => 1,
        'me.name' => $sec_name,
    },{
        'join' => { 'mconf_id' => 'machine_id' },
        'select' => [ 'me.mconf_sec_id', 'me.mconf_id', ],
        'as' => [ 'mconf_sec_id', 'mconf_id', ],
    });

    return undef unless defined $row;
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

        my $key = $row{key};
        my $new_value = $row{value};
        
        if ( exists $mdata->{$key} ) {
            if ( ref $mdata->{$key} eq 'ARRAY' ) {
                my $prev_val = $mdata->{$key};
                push @{$mdata->{$key}}, $new_value;
            } else {
                my $prev_val = $mdata->{$key};
                $mdata->{$key} = [ $prev_val, $new_value ];
            }
        } else {
            $mdata->{$key} = $new_value;
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
            'select' => [ 'machine_id.name', 'mconf_sec_id.name', 'key', 'value', 'num' ],
            'as' => [ 'machine_name', 'section_name', 'key', 'value', 'num' ],
            'order_by' => [ 'machine_id.machine_id', 'mconf_sec_id.mconf_sec_id', 'key', 'num' ],
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



=head1 SEE ALSO

L<SysFink::Conf>, L<SysFink>

=head1 LICENSE

This file is part of SysFink. See L<SysFink> license.

=cut


1;
