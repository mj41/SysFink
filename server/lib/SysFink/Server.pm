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
    $self->{rpc_ssh_connected} = 0;

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

    # Next commands needs prepared SSH part of object.
    return 0 unless $self->prepare_rpc_ssh_part( $opt );

    return $self->test_hostname() if $opt->{cmd} eq 'test_hostname';

    return $self->check_client_dir() if $opt->{cmd} eq 'check_client_dir';
    return $self->remove_client_dir() if $opt->{cmd} eq 'remove_client_dir';
    return $self->renew_client_dir() if $opt->{cmd} eq 'renew_client_dir';


    my $psh_commands = {
        'test_noop_rpc' => 1,
    };
    if ( exists $psh_commands->{ $opt->{cmd} } ) {
        # Start perl shell on client.
        return 0 unless $self->start_rpc_shell();

        # Run command.
        return $self->test_noop_rpc() if $opt->{cmd} eq 'test_noop_rpc';
    }

    $self->err("Unknown command '$opt->{cmd}'.");
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

Initializce object for RPC over SSH and connect to client. Do not start perl shell for RPC.

=cut

sub init_rpc_obj  {
    my ( $self, $opt ) = @_;

    my $rpc = SysFink::Server::SSHRPCClient->new();
    unless ( defined $rpc ) {
        $self->err('Initialization of SSH RPC Client object failed.');
        return 0;
    }

    $self->{rpc} = $rpc;
    $self->{rpc_ssh_connected} = 0;

    my $full_opt = { %$opt };
    $full_opt->{RealBin} = $self->{RealBin};

    return $self->rpc_err() unless $self->{rpc}->set_options( $full_opt );
    return 1;
}


=head2 prepare_rpc_ssh_part

Prepare SSH part of RPC object.

=cut

sub prepare_rpc_ssh_part {
    my ( $self, $opt ) = @_;

    return 1 if $self->{rpc_ssh_connected};

    unless ( defined $self->{rpc} ) {
        return 0 unless $self->init_rpc_obj( $opt );
    }

    unless ( $self->{rpc_ssh_connected} ) {
        return $self->rpc_err() unless $self->{rpc}->connect();
        $self->{rpc_ssh_connected} = 1;
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


=head2 check_client_dir

Call command check_client_dir on client.

=cut

sub check_client_dir {
    my ( $self ) = @_;

    return $self->rpc_err() unless $self->{rpc}->check_client_dir();
    return 1;
}


=head2 remove_client_dir

Call command remove_client_dir on client.

=cut

sub remove_client_dir {
    my ( $self ) = @_;

    return $self->rpc_err() unless $self->{rpc}->remove_client_dir();
    return 1;
}


=head2 renew_client_dir

Call command renew_client_dir on client.

=cut

sub renew_client_dir {
    my ( $self ) = @_;

    return $self->rpc_err() unless $self->{rpc}->renew_client_dir();
    return 1;
}


=head2 start_rpc_shell

Start perl shell on client.

=cut

sub start_rpc_shell {
    my ( $self ) = @_;

    return $self->rpc_err() unless $self->{rpc}->start_rpc_shell();
    return 1;
}


=head2 test_noop_rpc

Call command test_noop on client's perl shell.

=cut

sub test_noop_rpc {
    my ( $self ) = @_;

    return $self->rpc_err() unless $self->{rpc}->test_noop_rpc();
    return 1;
}


=head1 SEE ALSO

L<SysFink>

=head1 LICENSE

This file is part of SysFink. See L<SysFink> license.

=cut


1;
