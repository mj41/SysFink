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

    my $self = $class->SUPER::new( $params, @_ );
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
    my ( $self, $mconf_sec_kv_rs ) = @_;

    my $data = {};
    while ( my $row_obj = $mconf_sec_kv_rs->next ) {
        my %row = ( $row_obj->get_columns() );
        my $key = $row{key};
        my $new_value = $row{value};
        if ( exists $data->{$key} ) {
            if ( ref $data->{$key} eq 'ARRAY' ) {
                my $prev_val = $data->{$key};
                push @{$data->{$key}}, $new_value;
            } else {
                my $prev_val = $data->{$key};
                $data->{$key} = [ $prev_val, $new_value ];
            }
        } else {
            $data->{$key} = $new_value;
        }
    }

    # Prepare paths. Should be sorted already.
    if ( exists $data->{paths} && $data->{paths} ) {
        # Only one value. Change to array ref.
        if ( not ref $data->{paths} ) {
            $data->{paths} = [ $data->{paths} ];
        }

        my $new_paths = [];
        foreach my $num ( 0..$#{$data->{paths}} ) {
            my $flags_and_path = $data->{paths}->[ $num ];

            # Try to split path and flags.
            if ( my ( $path, $flags_str ) = $flags_and_path =~ m{^ (.*) \[ (.+?) \] $}x ) {
                my %flags = $self->flags_str_to_hash( $flags_str );
                push @$new_paths, [ $path, \%flags, ];

            } else {
                # ToDo - error
            }
        }
        $data->{paths} = $new_paths;
    }
    return $data;
}


=head2 load_general_conf

Load and canonize configuration for given machine_id and 'general' configuration 
of mconf_id.

=cut

sub load_general_conf {
    my ( $self, $machine_id, $mconf_id ) = @_;

    my $mconf_sec_kv_rs = $self->{schema}->resultset('mconf_sec_kv')->search(
        {
            'mconf_sec_id.mconf_id' => $mconf_id,
            'mconf_sec_id.name' => 'general',
        },
        {
            'join' => [ 'mconf_sec_id' ],
            'select' => [ 'key', 'value', 'num' ],
            'order_by' => [ 'key', 'num' ],
        },
    );

    my $data = $self->load_conf_data_from_rs( $mconf_sec_kv_rs );
    return $data;
}


=head2 load_sec_conf

Load and canonize configuration for given machine_id and mconf_sec_id.

=cut

sub load_sec_conf {
    my ( $self, $machine_id, $mconf_sec_id ) = @_;

    my $mconf_sec_kv_rs = $self->{schema}->resultset('mconf_sec_kv')->search(
        {
            'me.mconf_sec_id' => $mconf_sec_id,
        },
        {
            'select' => [ 'key', 'value', 'num' ],
            'order_by' => [ 'key', 'num' ],
        },
    );

    my $data = $self->load_conf_data_from_rs( $mconf_sec_kv_rs );
    return $data;
}


=head1 SEE ALSO

L<SysFink::Conf>, L<SysFink>

=head1 LICENSE

This file is part of SysFink. See L<SysFink> license.

=cut


1;
