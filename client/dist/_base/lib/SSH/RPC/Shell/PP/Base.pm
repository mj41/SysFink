package SSH::RPC::Shell::PP::Base;

use strict;

$SSH::RPC::Shell::PP::Base::VERSION = '0.100';


sub new {
    my ( $class, $ver ) = @_;

    my $self  = {};
    $self->{ver} = $ver;

    bless( $self, $class );
    return $self;
}


=head2 process_request( request )

Process request.

=cut

sub process_request {
    my ( $self, $request ) = @_;

    my $command_sub_name = 'run_'.$request->{command};
    my $args = $request->{args};
    if ( my $sub = $self->can($command_sub_name) ) {
        return $sub->( $self, $args );
    }
    return { "error" => "Method not allowed.", "status" => "405" };
}


sub init_test_obj {
    my ( $self ) = @_;
    $self->{test_obj} = SSH::RPC::Shell::PP::TestCmds->new();
}


sub run_test_noop {
    my ( $self, $file ) = @_;
    $self->init_test_obj() unless $self->{test_obj};
    return $self->{test_obj}->run_test_noop();
}


sub run_test_three_parts {
    my ( $self, $file ) = @_;
    $self->init_test_obj() unless $self->{test_obj};
    return $self->{test_obj}->run_test_three_parts();
}


1;
