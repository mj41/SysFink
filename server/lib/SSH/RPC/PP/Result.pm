package SSH::RPC::PP::Result;

our $VERSION = 1.200;

use strict;

=head1 NAME

SSH::RPC::PP::Result - Provides methods for the response from a SSH::RPC::Client run() method request.

=head1 DESCRIPTION

Based on SSH::RPC::Result, but without Class::InsideOut.

=cut


sub new {
    my ( $class, $response ) = @_;

    my $self = {};
    $self->{response} = $response;
    bless( $self, $class );
    return $self;
}


=head2 getError ()

Returns the human readable error message (if any).

=cut

sub getError {
    my $self = shift;
    return $self->{response}->{error};
}


=head2 getResponse ()

Returns the return value(s) from the RPC, whether that be a scalar value, or a hash reference or array reference.

=cut

sub getResponse {
    my $self = shift;
    return $self->{response}->{response};
}


=head2 getShellVersion ()

Returns the $VERSION from the shell. This is useful if you have different versions of your shell running on different machines, and you need to do something differently to account for that.

=cut

sub getShellVersion {
    my $self = shift;
    return $self->{response}->{version};
}


=head2 getStatus ()

Returns a status code for the RPC. The built in status codes are:

 200 - Success
 400 - Malform request received by shell.
 405 - RPC called a method that doesn't exist.
 406 - Error transmitting RPC.
 500 - An undefined error occured in the shell.
 510 - Error translating return document in client.
 511 - Error translating return document in shell.

=cut

sub getStatus {
    my $self = shift;
    return $self->{response}->{status};
}


=head2 isSuccess ()

Returns true if the request was successful, or false if it wasn't.

=cut

sub isSuccess {
    my $self = shift;
    return ($self->getStatus == 200);
}


1;

