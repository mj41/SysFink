package SysFink::Conf::DBIC;

use strict;
use warnings;

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


=head2 load_general_conf

Constructor. Parameters: schema.

=cut

sub load_general_conf {
    my ( $self, $machine_name ) = @_;

    my $mconf_rs = $self->{schema}->resultset('mconf_sec_kv')->search(
        {
            'machine_id.name' => $machine_name,
            'mconf_sec_id.name' => 'general',
        },
        {
            'join' => { 'mconf_sec_id' => 'machine_id' },
            'select' => [ 'key', 'value', 'num' ],
            'order_by' => [ 'key', 'num' ],
        },
    );


    my $data = {};
    while (my $row_obj = $mconf_rs->next) {
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


=head1 SEE ALSO

L<SysFink::Conf>, L<SysFink>

=head1 LICENSE

This file is part of SysFink. See L<SysFink> license.

=cut


1;
