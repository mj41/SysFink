package SSH::RPC::Shell::PP::TestCmds;

$__PACKAGE__::VERSION = '0.100';

use strict;
use base 'SSH::RPC::Shell::PP::Cmd::BaseJSON';


=head2 run_test_noop ()

This command method just returns a successful status so you know that communication is working.

=cut

sub run_test_noop {
    my ( $self ) = @_;

    my $result = { test => 'noop' };
    return $self->send_ok_response( $result );
}


=head2 run_test_tree_parts()

ToDo

=cut

sub run_test_three_parts {
    my ( $self ) = @_;

    my $result = {
        test => 'three_parts',
        part_num => undef,
    };

    $result->{part_num} = 1;
    $self->send_ok_response( $result, 0 );

    $result->{part_num} = 2;
    $self->send_ok_response( $result, 0 );

    $result->{part_num} = 3;
    return $self->send_ok_response( $result, 1 );
}

1;