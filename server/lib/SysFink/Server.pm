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

    # Commands configuration.
    my $all_cmd_confs = {
        'test_hostname' => {
            'ssh' => 1,
            'type' => 'rpc',
        },
        'check_client_dir' => {
            'ssh' => 1,
            'type' => 'rpc',
        },
        'remove_client_dir' => {
            'ssh' => 1,
            'type' => 'rpc',
        },
        'renew_client_dir' => {
            'ssh' => 1,
            'type' => 'rpc',
        },
        'test_noop_rpc' => {
            'ssh' => 1,
            'rpc' => 1,
            'type' => 'rpc',
        },
        'test_three_parts_rpc' => {
            'ssh' => 1,
            'rpc' => 1,
            'type' => 'rpc',
        },
    };

    my $cmd = lc( $opt->{cmd} );

    unless ( exists $all_cmd_confs->{$cmd} ) {
        $self->err("Unknown command '$cmd'.");
        return 0;
    }

    my $cmd_conf = $all_cmd_confs->{ $cmd };

    if ( $cmd_conf->{ssh} ) {
        # Next commands needs prepared SSH part of object.
        return 0 unless $self->prepare_rpc_ssh_part( $opt );
    }

    if ( $cmd_conf->{rpc} ) {
        # Start perl shell on client.
        return 0 unless $self->start_rpc_shell();
    }

    my $cmd_type = $cmd_conf->{type};
    my $cmd_method_name = $cmd;

    # Run simple RPC command on RPC object.
    if ( defined $cmd_type && $cmd_type eq 'rpc' ) {
        my $rpc_obj = $self->{rpc};
        return $self->rpc_err() unless $rpc_obj->$cmd_method_name();
        return 1;
    }

    # Run given comman method.
    return $self->$cmd_method_name();
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


=head2 start_rpc_shell

Start perl shell on client.

=cut

sub start_rpc_shell {
    my ( $self ) = @_;

    return $self->rpc_err() unless $self->{rpc}->start_rpc_shell();
    return 1;
}


=head1 SEE ALSO

L<SysFink>

=head1 LICENSE

This file is part of SysFink. See L<SysFink> license.

=cut


1;
