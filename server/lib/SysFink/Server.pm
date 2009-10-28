package SysFink::Server;

use strict;
use warnings;

use FindBin;
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
    $self->{rpc_connected} = 0;

    $self->{RealBin} = $FindBin::RealBin;

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

    # Commands:

    # Next commands needs prepared SSH RPC object.
    return 0 unless $self->prepare_rpc( $opt );

    return $self->test_hostname() if $opt->{cmd} eq 'test_hostname';
    return $self->check_client_dir_content() if $opt->{cmd} eq 'check_client_dir_content';
    return $self->empty_client_dir() if $opt->{cmd} eq 'empty_client_dir';
    return $self->put_client_src_code() if $opt->{cmd} eq 'put_client_src_code';

    $self->err("Unknown command '$self->{cmd}'.");
    return 0;
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
    unless ( defined $rpc ) {
        $self->err('Initialization of SSH RPC Client object failed.');
        return 0;
    }

    $self->{rpc} = $rpc;
    $self->{rpc_connected} = 0;

    my $full_opt = { %$opt };
    $full_opt->{RealBin} = $self->{RealBin};

    return $self->rpc_err() unless $self->{rpc}->set_options( $full_opt );
    return 1;
}


=head2 prepare_rpc

Call command test_hostname on client.

=cut

sub prepare_rpc {
    my ( $self, $opt ) = @_;

    return 1 if $self->{rpc_connected};

    unless ( defined $self->{rpc} ) {
        return 0 unless $self->init_rpc_obj( $opt );
    }

    unless ( $self->{rpc_connected} ) {
        return $self->rpc_err() unless $self->{rpc}->connect();
        $self->{rpc_connected} = 1;
    }

    return 1;
}


=head2 test_hostname

Call command test_hostname on client.

=cut

sub test_hostname {
    my ( $self ) = @_;

    return $self->rpc_err() unless $self->{rpc}->test_hostname();
    return 1;
}


=head2 check_client_dir_content

Call command check_client_dir_content on client.

=cut

sub check_client_dir_content {
    my ( $self ) = @_;

    return $self->rpc_err() unless $self->{rpc}->check_client_dir_content();
    return 1;
}


=head2 empty_client_dir

Call command empty_client_dir on client.

=cut

sub empty_client_dir {
    my ( $self ) = @_;

    return $self->rpc_err() unless $self->{rpc}->empty_client_dir();
    return 1;
}


=head2 put_client_src_code

Call command put_client_src_code on client.

=cut

sub put_client_src_code {
    my ( $self ) = @_;

    return $self->rpc_err() unless $self->{rpc}->put_client_src_code();
    return 1;
}


=head1 SEE ALSO

L<SysFink>

=head1 LICENSE

This file is part of SysFink. See L<SysFink> license.

=cut


1;
