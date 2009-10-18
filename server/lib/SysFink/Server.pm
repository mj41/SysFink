package SysFink::Server;

use strict;
use warnings;

use Data::Dumper;
use SysFink::Server::SSHRPCClient;

=head1 NAME

SysFink::Server - SysFink server.

=head1 SYNOPSIS

See L<SysFink>

=head1 DESCRIPTION

SysFink server.

=head1 METHODS


=head2 new

Constructor.

=cut

sub new {
    my ( $class ) = @_;

    my $self  = {};

    $self->{ver} = 0;
    $self->{err} = undef;
    $self->{rpc} = undef;

    bless $self, $class;
    return $self;
}


=head2 err

Get/set error message and return 0.

=cut

sub err {
    my ( $self, $err) = @_;

    # Get.
    return $self->{err} unless defined $err;

    # Set.
    print "Setting error to: '$err'\n" if $self->{ver} >= 5;
    $self->{err} = $err;

    # return 0 is ok here.
    # You can use  e.g.
    #   return $self->err('Err msg') if $some_error;
    return 0;
}


=head2 run

Start options processing and run given command.

=cut

sub run {
    my ( $self, $opt ) = @_;

    my $ver = $opt->{ver}; # shortcup
    print Dumper( $opt ) if $ver >= 5;

    return $self->err("No command selected. Use --cmd option.") unless $opt->{cmd};
    $opt->{cmd} = lc( $opt->{cmd} );

    return $self->test_hostname( $opt ) if $opt->{cmd} eq 'test_hostname';

    return 1;
}


=head2 rpc_err

Set error message to error from RPC object. Return 0 as method err.

=cut

sub rpc_err  {
    my ( $self ) = @_;

    return undef unless defined $self->{rpc};
    my $rpc_err = $self->{rpc}->err();
    return $self->err( $rpc_err );
}


=head2 init_rpc_obj

Initializce object for RPC over SSH and connect to client.

=cut

sub init_rpc_obj  {
    my ( $self, $opt ) = @_;

    my $rpc = SysFink::Server::SSHRPCClient->new();
    return 0 unless $rpc;
    $self->{rpc} = $rpc;

    return $self->rpc_err() unless $self->{rpc}->set_options( $opt );
    return 1;
}


=head2 test_hostname

Call command test_hostname on client.

=cut

sub test_hostname {
    my ( $self, $opt ) = @_;

    return 0 unless $self->init_rpc_obj( $opt );
    return $self->rpc_err() unless $self->{rpc}->connect( $opt );
    return $self->rpc_err() unless $self->{rpc}->test_hostname();
    return 1;
}


=head1 SEE ALSO

L<SysFink>

=head1 LICENSE

This file is part of SysFink. See L<SysFink> license.

=cut


1;
