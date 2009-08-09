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
    my ($self, $request) = @_;
    
    my $command_sub_name = 'run_'.$request->{command};
    my $args = $request->{args};
    if ( my $sub = $self->can($command_sub_name) ) {
        return $sub->( $self, $args );
    }
    return { "error" => "Method not allowed.", "status" => "405" };
}


=head2 pack_ok_response () 

Pack result to success response.

=cut

sub pack_ok_response {
    my ( $self, %response ) = @_;
    return { status => 200, response => \%response };
}


=head2 run_noop () 

This command method just returns a successful status so you know that communication is working.

=cut

sub run_noop {
    return { status => 200 };
}

1;
