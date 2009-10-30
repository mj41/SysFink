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

use DateTime; # scan_cmd


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


=head2 get_item_attrs

Return list of monitored attributes. Key is name. Value tupe (1 number, 0 string).

=cut

sub get_item_attrs {
    my ( $self ) = @_;

    return {
        mtime => 1,
        mode => 1,
        size => 1,
        uid => 1,
        gid => 1,
        hash => 1,
        nlink => 1,
        dev_num => 1,
        ino_num => 1,
        user_name => 0,
        group_name => 0,
    };
}


=head2 get_sc_idata_rs

Return ResultSet to actual idata for given machine_id.

=cut

sub get_sc_idata_rs {
    my ( $self, $machine_id ) = @_;

    my $select_items = [ 'me.sc_idata_id', 'me.sc_mitem_id', 'sc_mitem_id.path', ];
    my $select_as_items = [ 'sc_idata_id', 'sc_mitem_id', 'path', ];

    my $attrs = $self->get_item_attrs();
    foreach my $attr_name ( keys %$attrs ) {
        push @$select_items, 'me.' . $attr_name;
        push @$select_as_items, $attr_name;
    }

    my $prev_sc_idata_rs = $self->{schema}->resultset('sc_idata')->search(
        {
            'me.found' => 1,
            'me.newer_id' => undef,
            'sc_mitem_id.machine_id' => $machine_id,
        },
        {
            'join' => [ 'sc_mitem_id' ],
            'select' => $select_items,
            'as' => $select_as_items,
            'order_by' => [ 'sc_mitem_id.path', ],
        },
    );

    return $prev_sc_idata_rs;
}


=head2 has_same_data

Run scan command.

=cut

sub has_same_data {
    my ( $self, $ra, $rb ) = @_;

    my $attrs = $self->get_item_attrs();
    # Add additional attribute 'found'.
    $attrs->{found} = 1;

    foreach my $attr_name ( keys %$attrs ) {
        my $is_numeric = $attrs->{$attr_name};
        #print "$attr_name is_numeric=$is_numeric\n";
        if ( $is_numeric ) {
            return 0 if defined $ra->{$attr_name} && ( (not defined $rb->{$attr_name}) || $rb->{$attr_name} != $ra->{$attr_name} );
            return 0 if defined $rb->{$attr_name} && ( (not defined $ra->{$attr_name}) || $ra->{$attr_name} != $rb->{$attr_name} );
        } else {
            return 0 if defined $ra->{$attr_name} && ( (not defined $rb->{$attr_name}) || $rb->{$attr_name} ne $ra->{$attr_name} );
            return 0 if defined $rb->{$attr_name} && ( (not defined $ra->{$attr_name}) || $ra->{$attr_name} ne $rb->{$attr_name} );
        }
    }

    return 1;
}


=head2 get_base_idata

Return hash ref for database. Hash is created from base_data completed with values from raw_data.

=cut

sub get_base_idata {
    my ( $self, $base_data, $raw_data ) = @_;

    my $data = { %$base_data };

    my $attrs = get_item_attrs();
    foreach my $attr_name ( keys %$attrs ) {
        if ( exists $raw_data->{ $attr_name } ) {
            $data->{ $attr_name } = $raw_data->{ $attr_name };
        } else {
            $data->{ $attr_name } = undef;
        }
    }
    return $data;
}


=head2 scan_cmd

Run scan command.

=cut

sub scan_cmd {
    my ( $self ) = @_;

    my $ver = $self->{ver};
    my $schema  = $self->{schema};

    my $scan_conf = $self->get_scan_conf( 0 );

    my $machine_id = $self->{host_conf}->{machine_id};
    my $mconf_id = $self->{host_conf}->{mconf_id};

    # Insert scan row.
    my $scan_row = $schema->resultset('scan')->create({
        mconf_id => $mconf_id,
        start_time => DateTime->now,
        stop_time => undef,
        pid => $$,
        items => undef,
    });
    my $scan_id = $scan_row->scan_id;

    $schema->storage->txn_begin;

    #$scan_conf->{debug_recursion_limit} = int( rand(100)+1 ); # debug
    #$scan_conf->{debug_recursion_limit} = 1_000; # debug

    # First part.
    my $result_obj = $self->{rpc}->do_rpc( 'scan_host', $scan_conf, 1 );
    return 0 unless defined $result_obj;

    my $response = $result_obj->getResponse();
    my $loaded_items = $response->{loaded_items};

    # Next parts.
    while ( $result_obj->isSuccess && !$result_obj->isLast ) {
        $result_obj = $self->{rpc}->get_next_response( 1 );
        $response = $result_obj->getResponse();
        $loaded_items = [
            @$loaded_items,
            @{$response->{loaded_items}}
        ];
    }
    # print Dumper( $loaded_items ); exit; # debug

    my %path_to_num = ();
    foreach my $num ( 0..$#$loaded_items ) {
        my $item = $loaded_items->[ $num ];
        print "$item->{path} ($num)\n" if $ver >= 5;
        # 2 .. found on host, initial status
        # if not changed to 0 (in db and the same) or 1 (in db and changed) then 2 means 'new' -> insert to db
        $path_to_num{ $item->{path} } = [ 2, $num ];
    }

    my $prev_sc_idata_rs = $self->get_sc_idata_rs( $machine_id );

    my $sc_mitem_rs = $schema->resultset('sc_mitem');
    my $sc_idata_rs = $schema->resultset('sc_idata');

    while ( my $row_obj = $prev_sc_idata_rs->next ) {
        my %row = ( $row_obj->get_columns() );
        my $path = $row{path};
        #print Dumper( \%row ) if $ver >= 5;

        my $insert_idata = undef;

        # Found.
        if ( exists $path_to_num{ $path } ) {
            my $new_item_data = $loaded_items->[ $path_to_num{ $path }->[1] ];
            if ( $self->has_same_data($new_item_data,\%row) ) {
                # Same data -> do nothing.
                $path_to_num{ $path }->[0] = 0; # 0 .. found in db and not changed

            } else {
                # Data changed -> do update.
                $path_to_num{ $path }->[0] = 1; # 1 .. found in db and changed
                if ( $ver >= 4 ) {
                    print "Item data changed:\n";
                    print Dumper( $new_item_data );
                    print Dumper ( \%row );
                }

                my $sc_mitem_id = $row{'sc_mitem_id'};
                print "updating status to new values sc_mitem_id $sc_mitem_id\n" if $ver >= 5;
                my $insert_idata_base = {
                    sc_mitem_id => $sc_mitem_id,
                    scan_id => $scan_id,
                    newer_id => undef,
                    found => 1,
                };
                #$new_item_data->{size} = int rand(500); # debug
                $insert_idata = $self->get_base_idata( $insert_idata_base, $new_item_data );
            }

        # Not found on during scan on client machine -> delete.
        } else {
            my $sc_mitem_id = $row{'sc_mitem_id'};
            print "updating status to delete sc_mitem_id $sc_mitem_id\n" if $ver >= 5;
            my $insert_idata_base = {
                sc_mitem_id => $sc_mitem_id,
                scan_id => $scan_id,
                newer_id => undef,
                found => 0,
            };
            $insert_idata = $self->get_base_idata( $insert_idata_base, {} );
        }

        if ( defined $insert_idata ) {
            my $sc_idata_row = $sc_idata_rs->create( $insert_idata );
            my $new_sc_idata_id = $sc_idata_row->sc_idata_id;

            my $old_sc_idata_rs = $schema->resultset('sc_idata')->find( $row{'sc_idata_id'} );
            $old_sc_idata_rs->update({ newer_id => $new_sc_idata_id });
        }
    }


    foreach my $num ( 0..$#$loaded_items ) {
        my $item = $loaded_items->[ $num ];
        my $path = $item->{path};
        # insert
        if ( $path_to_num{ $path }->[0] == 2 ) {
            print "inserting path $path (sc_mitem_id=" if $ver >= 4;

            my $sc_mitme_row = $sc_mitem_rs->find_or_create({
                machine_id => $machine_id,
                path => $path,
            });
            my $sc_mitem_id = $sc_mitme_row->sc_mitem_id;
            print $sc_mitem_id if $ver >= 4;

            my $insert_idata_base = {
                sc_mitem_id => $sc_mitem_id,
                scan_id => $scan_id,
                newer_id => undef,
                found => 1,
            };
            my $insert_idata = $self->get_base_idata( $insert_idata_base, $item );
            my $sc_idata_row = $sc_idata_rs->create( $insert_idata );
            my $new_sc_idata_id = $sc_idata_row->sc_idata_id;
            print ", sc_idata_id=" . $new_sc_idata_id if $ver >= 4;
            print ")\n"  if $ver >= 4;
        }
    }

    #print Dumper( \%path_to_num ) if $ver >= 5;

    $schema->storage->txn_commit;

    # Update scan row.
    $scan_row->update({
        items => scalar(@$loaded_items),
        stop_time => DateTime->now,
    });

    #print "sleeping ...\n"; sleep(10*60); # debug size of used memory
    print "Command 'scan' succeeded.\n" if $self->{ver} >= 3;
    return 1;
}


=head1 SEE ALSO

L<SysFink>

=head1 LICENSE

This file is part of SysFink. See L<SysFink> license.

=cut


1;
