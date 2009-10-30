package SysFink::Server;

use strict;
use warnings;

use FindBin;
use Data::Dumper;
use File::Spec::Functions;

use SysFink::Server::SSHRPCClient;

use SysFink::Conf::DBIC;
use SysFink::Utils::Conf;
use SysFink::Utils::DB;


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

    $self->{ver} = 1;
    $self->{err} = undef;
    $self->{RealBin} = $FindBin::RealBin;

    $self->{rpc} = undef;
    $self->{rpc_ssh_connected} = 0;

    $self->{conf_path} = catdir( $self->{RealBin}, 'conf' );

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

    $self->{ver} = $opt->{ver} if defined $opt->{ver};

    print Dumper( $opt ) if $self->{ver} >= 5;

    return $self->err("No command selected. Use --cmd option.") unless $opt->{cmd};

    # Commands configuration.
    my $all_cmd_confs = {

        # Base remote command.
        'test_hostname' => {
            'ssh_connect' => 1,
            'type' => 'rpc',
        },
        'check_client_dir' => {
            'ssh_connect' => 1,
            'type' => 'rpc',
        },
        'remove_client_dir' => {
            'ssh_connect' => 1,
            'type' => 'rpc',
        },
        'renew_client_dir' => {
            'ssh_connect' => 1,
            'type' => 'rpc',
        },

        # Base test procedure calls.
        'test_noop_rpc' => {
            'ssh_connect' => 1,
            'start_rpc_shell' => 1,
            'type' => 'rpc',
        },
        'test_three_parts_rpc' => {
            'ssh_connect' => 1,
            'start_rpc_shell' => 1,
            'type' => 'rpc',
        },

        # Commands which work with database.
        'scan_test' => {
            'connect_to_db' => 1,
            'load_host_conf_from_db' => 1,
            'ssh_connect' => 1,
            'start_rpc_shell' => 1,
            'type' => 'self',
        },

        'scan' => {
            'connect_to_db' => 1,
            'load_host_conf_from_db' => 1,
            'ssh_connect' => 1,
            'start_rpc_shell' => 1,
            'type' => 'self',
        },

    }; # $all_cmd_confs end


    my $cmd = lc( $opt->{cmd} );

    unless ( exists $all_cmd_confs->{$cmd} ) {
        $self->err("Unknown command '$cmd'.");
        return 0;
    }

    my $cmd_conf = $all_cmd_confs->{ $cmd };

    # Load db config and connect do DB.
    if ( $cmd_conf->{connect_to_db} ) {
        return 0 unless $self->connect_db();
    }

    # Load host config from connected DB.
    return 0 unless $self->prepare_base_host_conf( $opt );
    if ( $cmd_conf->{load_host_conf_from_db} ) {
        return 0 unless $self->prepare_host_conf_from_db();
    }

    # Next commands needs prepared SSH part of object.
    if ( $cmd_conf->{ssh_connect} ) {
        return 0 unless $self->prepare_rpc_ssh_part();
    }

    # Start perl shell on client.
    if ( $cmd_conf->{start_rpc_shell} ) {
        return 0 unless $self->start_rpc_shell();
    }

    my $cmd_type = $cmd_conf->{type};

    # Run simple RPC command on RPC object.
    if ( $cmd_type eq 'rpc' ) {
        my $rpc_obj = $self->{rpc};
        my $cmd_method_name = $cmd;
        return $self->rpc_err() unless $rpc_obj->$cmd_method_name();
        return 1;
    }

    # Run given comman method.
    my $cmd_method_name = $cmd . '_cmd';
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


=head2 prepare_base_host_conf

Init base host_conf from fiven options.

=cut

sub prepare_base_host_conf {
    my ( $self, $opt ) = @_;

    my $host_conf = {
        ver => $self->{ver},
        RealBin => $self->{RealBin},

        user => $opt->{user},
        host => $opt->{host},
    };

    $host_conf->{rpc_ver} = $opt->{rpc_ver} if defined $opt->{rpc_ver};
    $host_conf->{client_src_dir} = $opt->{client_src_dir} if defined $opt->{client_src_dir};

    $self->{host_conf} = $host_conf;
    return 1;
}


=head2 init_rpc_obj

Initializce object for RPC over SSH and connect to client. Do not start perl shell for RPC.

=cut

sub init_rpc_obj  {
    my ( $self ) = @_;

    my $rpc = SysFink::Server::SSHRPCClient->new();
    unless ( defined $rpc ) {
        $self->err('Initialization of SSH RPC Client object failed.');
        return 0;
    }

    $self->{rpc} = $rpc;
    $self->{rpc_ssh_connected} = 0;

    return $self->rpc_err() unless $self->{rpc}->set_options( $self->{host_conf} );
    return 1;
}


=head2 prepare_rpc_ssh_part

Prepare SSH part of RPC object.

=cut

sub prepare_rpc_ssh_part {
    my ( $self ) = @_;

    return 1 if $self->{rpc_ssh_connected};

    unless ( defined $self->{rpc} ) {
        return 0 unless $self->init_rpc_obj();
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


=head2 connect_db

Load configs and connect do database.

=cut

sub connect_db {
    my ( $self ) = @_;

    my $conf = SysFink::Utils::Conf::load_conf_multi( $self->{conf_path}, 'db' );
    return $self->err("Can't load database configuration from conf path '$self->{conf_path}'.") unless $conf;

    $self->{conf} = $conf;
    my $schema = SysFink::Utils::DB::get_connected_schema( $self->{conf}->{db} );
    return $self->err("Can't connect do database.") unless $schema;

    $self->{schema} = $schema;
    return 1;
}


=head2 prepare_host_conf_from_db

Load host related configuration from database.

=cut

sub prepare_host_conf_from_db {
    my ( $self ) = @_;

    my $conf_obj = SysFink::Conf::DBIC->new({
        schema => $self->{schema},
    });
    return $self->err("Can't load config object.") unless $conf_obj;

    my $host = $self->{host_conf}->{host};

    my $machine_id = $conf_obj->get_machine_id( { 'name' => $host } );
    return $self->err("Can't find machine_if for host '$host' in DB.") unless $machine_id;

    my $mconf_id = $conf_obj->get_machine_active_mconf_id( $machine_id );
    return $self->err("Can't find mconf_id for machine_id '$machine_id' in DB.") unless $mconf_id;

    my $general_conf = $conf_obj->load_general_conf( $machine_id, $mconf_id );
    return $self->err("Can't load configuration for machine_id ''$machine_id and mconf_id '$mconf_id' in DB.") unless $general_conf;

    my @mandatory_keys = qw/paths dist_type/;

    # Check mandatory.
    foreach my $key ( @mandatory_keys ) {
        unless ( $general_conf->{ $key } ) {
            return $self->err("Can't find mandatory configuration key '$key' for host '$host' DB.");
        }
    }

    $self->{host_conf}->{machine_id} = $machine_id;
    $self->{host_conf}->{mconf_id} = $mconf_id;

    # Set mandatory.
    foreach my $key ( @mandatory_keys ) {
         $self->{host_conf}->{ $key } = $general_conf->{ $key };
    }

    # Optional.
    my $max_items_in_one_response = 1_000;
    if ( defined $general_conf->{max_items_in_one_response} ) {
        $max_items_in_one_response = $general_conf->{max_items_in_one_response}
    }
    $self->{host_conf}->{max_items_in_one_response} = $max_items_in_one_response;

    return 1;
}


=head2 get_scan_conf

Return configuration for scan command.

=cut

sub get_scan_conf {
    my ( $self, $debug_run ) = @_;

    my $scan_conf = {
        'paths' => $self->{host_conf}->{paths},
        'max_items_in_one_response' => $self->{host_conf}->{max_items_in_one_response},
    };
    $scan_conf->{debug_out} = 1 if $debug_run;

    return $scan_conf;
}



=head2 scan_test_cmd

Run scan_test command. Similar to scan_cmd, but do not update database, only list
items info while scanning on client.

=cut

sub scan_test_cmd {
    my ( $self ) = @_;

    my $scan_conf = $self->get_scan_conf( 1 );
    return $self->rpc_err() unless $self->{rpc}->do_debug_rpc( 'scan_host', $scan_conf );
    print "Command 'scan_test' succeeded.\n" if $self->{ver} >= 3;
    return 1;
}


=head2 scan_cmd

Run scan command.

=cut

sub scan_cmd {
    my ( $self ) = @_;

    my $scan_conf = $self->get_scan_conf( 0 );

    print "Command 'scan' succeeded.\n" if $self->{ver} >= 3;
    return 1;
}


=head1 SEE ALSO

L<SysFink>

=head1 LICENSE

This file is part of SysFink. See L<SysFink> license.

=cut


1;
