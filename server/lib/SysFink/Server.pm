package SysFink::Server;

use strict;
use warnings;

use base 'SysFink::Base';

use FindBin;
use File::Spec::Functions;

use SysFink::Server::SSHRPCClient;

use SysFink::Conf::DBIC;
use SysFink::Utils::Conf;
use SysFink::Utils::DB;

use DateTime; # scan_cmd
use Fcntl ':mode'; # get_mode_str


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
    my $class = shift;
    my $self = $class->SUPER::new( @_ );

    $self->{RealBin} = $FindBin::RealBin;

    $self->{rpc} = undef;
    $self->{rpc_ssh_connected} = 0;

    $self->{conf_path} = catdir( $self->{RealBin}, 'conf' );

    return $self;
}


=head2 run

Start options processing and run given command.

=cut

sub run {
    my ( $self, $opt ) = @_;

    $self->{ver} = $opt->{ver} if defined $opt->{ver};
    $self->dump( 'Given parameters', $opt ) if $self->{ver} >= 6;

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
            'load_host_conf_from_db_if_no' => [ qw/ host_dist_type / ],
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
            'ssh_connect' => 1,
            'connect_to_db' => 1,
            'start_rpc_shell' => 1,
            'load_host_conf_from_db' => 1,
            'type' => 'self',
        },

        'scan' => {
            'ssh_connect' => 1,
            'connect_to_db' => 1,
            'start_rpc_shell' => 1,
            'load_host_conf_from_db' => 1,
            'type' => 'self',
        },

        'mconf_to_db' => {
            'connect_to_db' => 1,
            'get_who' => { mandatory => 0, },
            'type' => 'self',
        },

        'diff' => {
            'connect_to_db' => 1,
            'validate_host_name_if_given' => 1,
            'type' => 'self',
        },

        'audit' => {
            'connect_to_db' => 1,
            'validate_host_name_if_given' => 1,
            'get_who' => { mandatory => 1, },
            'type' => 'self',
        },

    }; # $all_cmd_confs end

    # Options used somewhere below:
    # * no_db

    my $cmd = lc( $opt->{cmd} );

    unless ( exists $all_cmd_confs->{$cmd} ) {
        $self->err("Unknown command '$cmd'.");
        return 0;
    }

    my $cmd_conf = $all_cmd_confs->{ $cmd };
    
    # Special params.
    if ( $cmd_conf->{'load_host_conf_from_db_if_no'} ) {
        my $all_found = 1;
        foreach my $conf_param_name ( @{ $cmd_conf->{'load_host_conf_from_db_if_no'} } ) {
            if ( not defined $opt->{ $conf_param_name } ) {
                $all_found = 0;
                last;
            }
        }
        if ( ! $all_found ) {
            $cmd_conf->{connect_to_db} = 1;
            $cmd_conf->{load_host_conf_from_db} = 1;
        }
    }

    # Load db config and connect to DB.
    if ( $cmd_conf->{connect_to_db} && !$opt->{no_db} ) {
        return 0 unless $self->connect_db();
    }

    # Check given host name in DB.
    if ( $cmd_conf->{validate_host_name_if_given} && defined $opt->{host} ) {
        return 0 unless $self->validate_host_name( $opt->{host} );
    }
    
    # Get user_id from given login or who (get_login).
    if ( $cmd_conf->{get_who} ) {
        return 0 unless $self->get_who( $opt->{who}, $cmd_conf->{get_who}->{mandatory} );
    }
    
    # Load host config for given hostname from connected DB.
    if ( $cmd_conf->{ssh_connect} ) {
        return 0 unless $self->prepare_base_host_conf( $opt );
    }

    if ( $cmd_conf->{load_host_conf_from_db} && !$opt->{no_db} ) {
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
    return $self->$cmd_method_name( $opt );
}


=head2 rpc_err

Set error message to error from RPC object. Return 0 as method err.

=cut

sub rpc_err  {
    my ( $self ) = @_;

    return undef unless defined $self->{rpc};
    my $rpc_err = $self->{rpc}->err();
    return $self->err( $rpc_err, 1 );
}


=head2 mconf_err

Set error message to error from conf object. Return 0 as method err.

=cut

sub mconf_err  {
    my ( $self ) = @_;

    return undef unless defined $self->{mconf_obj};
    my $mconf_err = $self->{mconf_obj}->err();
    return $self->err( $mconf_err, 1 );
}


=head2 set_mandatory_param_err

Set 'param is mandatory' error and return undef.

=cut

sub set_mandatory_param_err {
    my ( $self, $param_name, $err_msg_end ) = @_;
    my $err_msg = "Parameter --${param_name} is mandatory";
    if ( $err_msg_end ) {
        $err_msg .= $err_msg_end 
    } else {
        $err_msg .= '.';
    }
    return $self->err( $err_msg, 1 );
}


=head2 validate_host_name

Validate if given hostname is ok.

=cut

sub validate_host_name {
    my ( $self, $hostname ) = @_;

    return 1 unless defined $hostname;

    my $host_row = $self->{schema}->resultset('machine')->find({ 
        'name' => $hostname,
    });
    return $self->err("Couldn't find hostname '$hostname' inside DB.") unless defined $host_row;
    return $self->err("Given host '$hostname' is disabled.") if ! $host_row->active;
    print "Hostname '$hostname' validated ok.\n" if $self->{ver} >= 6;
    return 1;
}


=head2 prepare_base_host_conf

Init base host_conf from given options.

=cut

sub prepare_base_host_conf {
    my ( $self, $opt ) = @_;

    my $host_conf = {
        ver => $self->{ver},
        RealBin => $self->{RealBin},
        host => $opt->{host},
    };

    $host_conf->{user} = $opt->{ssh_user} if defined $opt->{ssh_user};
    $host_conf->{rpc_ver} = $opt->{rpc_ver} if defined $opt->{rpc_ver};
    $host_conf->{client_src_dir} = $opt->{client_src_dir} if defined $opt->{client_src_dir};
    $host_conf->{host_dist_type} = $opt->{host_dist_type} if defined $opt->{host_dist_type};
    $host_conf->{conf_section_name} = lc( $opt->{section} ) if defined $opt->{section};

    $self->{host_conf} = $host_conf;
    $self->dump( 'Host conf:', $self->{host_conf} ) if $self->{ver} >= 6;
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


=head2 get_who

Init user_id from --who or from perl get_login (tty user name).

=cut

sub get_who {
    my ( $self, $who, $mandatory ) = @_;

    my $schema = $self->{schema};
    $self->{user_id} = undef;

    if ( $who ) {
        my $user_row = $schema->resultset('user')->find({ login => $who });
        return $self->err("User '$who' not found in DB.") unless $user_row;
        $self->{user_id} = $user_row->user_id;
    
    } else {
        my $tty_who = getlogin();

        my $found = 0;
        if ( $tty_who ) {
            my $user_row = $schema->resultset('user')->find({ who => $tty_who });
            if ( $user_row ) {
                $found = 1;
                $self->{user_id} = $user_row->user_id;
            }
        }

        if  ( ! $found || ! $tty_who ) {
            if ( $mandatory ) {
                return $self->err("Can't determine user_id. Try to use --who parameter.");
            } else {
                print "Can't determine user_id (who '$tty_who'). Try to use --who parameter.\n" if $self->{ver} >= 3;
            }
        }
    }

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


=head2 init_mconf_obj

Initializce Conf::DBIC object for various uses.

=cut

sub init_mconf_obj  {
    my ( $self ) = @_;

    return 1 if $self->{mconf_obj};

    my $mconf_obj = SysFink::Conf::DBIC->new({
        ver => $self->{ver},
        schema => $self->{schema},
    });
    return $self->err("Can't load config object.") unless $mconf_obj;
    $self->{mconf_obj} = $mconf_obj;
    return 1;
}


=head2 prepare_host_conf_from_db

Load host related configuration from database for given configuratin's section name.

=cut

sub prepare_host_conf_from_db {
    my ( $self ) = @_;

    return 0 unless $self->init_mconf_obj();
    my $mconf_obj = $self->{mconf_obj};

    my $host = $self->{host_conf}->{host};
    return $self->set_mandatory_param_err('host') unless $host;

    my $conf_section_name = 'general'; # default is 'general'
    $conf_section_name = $self->{host_conf}->{conf_section_name} if defined $self->{host_conf}->{conf_section_name};

    my $machine_id = $mconf_obj->get_machine_id( $host );
    return $self->mconf_err() unless $machine_id;
    
    my $mconf_sec_data = $mconf_obj->get_machine_active_mconf_sec_info( $machine_id, $conf_section_name );
    return $self->mconf_err() unless $mconf_sec_data;
    my ( $mconf_sec_id, $mconf_id ) = @$mconf_sec_data;

    # Load 'general' configuration's section.
    my $section_conf = $mconf_obj->load_general_conf( $machine_id, $mconf_id );
    return $self->mconf_err() unless $section_conf;

    # Load configuration's section selected by user. Use keys/values from this section to replace
    # these loaded from 'general' section.
    if ( $conf_section_name ne 'general' ) {
        my $tmp_section_conf = $mconf_obj->load_sec_conf( $machine_id, $mconf_sec_id );
        return $self->mconf_err() unless $tmp_section_conf;
        foreach my $name ( keys %$tmp_section_conf ) {
            $section_conf->{ $name } = $tmp_section_conf->{ $name };
        }
    }

    if ( exists $section_conf->{paths} ) {
        $section_conf->{paths} = $mconf_obj->prepare_path_regexes( $section_conf->{paths} );
        $section_conf->{path_filter_conf} = $mconf_obj->get_path_filter_conf( $section_conf->{paths} );
    }

    # All options given on command line are rewrited by values loaded from DB.
    my $mandatory_keys = {
        paths => 'paths',
        path_filter_conf => 'path_filter_conf',
        dist_type => 'host_dist_type',
        ssh_user => 'user',
    };

    # Check mandatory if not definned on command line.
    foreach my $name ( keys %$mandatory_keys ) {
        unless ( exists $self->{host_conf}->{ $name } ) {
            unless ( $section_conf->{ $name } ) {
                return $self->err("Can't find mandatory configuration key '$name' for host '$host' in DB.");
            }
        }
    }

    $self->{host_conf}->{machine_id} = $machine_id;
    $self->{host_conf}->{mconf_id} = $mconf_id;
    $self->{host_conf}->{mconf_sec_id} = $mconf_sec_id;

    # Set mandatory.
    foreach my $name ( keys %$mandatory_keys ) {
        unless ( exists $self->{host_conf}->{ $name } ) {
            my $host_conf_key = $mandatory_keys->{ $name };
            $self->{host_conf}->{ $host_conf_key } = $section_conf->{ $name };
        }
    }

    # Optional.
    my $max_items_in_one_response = 1_000;
    if ( defined $section_conf->{max_items_in_one_response} ) {
        $max_items_in_one_response = $section_conf->{max_items_in_one_response}
    }
    $self->{host_conf}->{max_items_in_one_response} = $max_items_in_one_response;

    $self->dump( 'Host conf from DB:', $self->{host_conf} ) if $self->{ver} >= 6;
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
    $scan_conf->{ver} = 1 if $debug_run;

    return $scan_conf;
}


=head2 scan_test_cmd

Run scan_test command. Similar to scan_cmd, but do not update database, only list
items info while scanning on client.

=cut

sub scan_test_cmd {
    my ( $self ) = @_;

    my $scan_conf = $self->get_scan_conf( 1 );
    #$scan_conf->{debug_recursion_limit} = 1_000; # debug
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
        mtime => 0,
        mode => 1,
        size => 1,
        uid => 1,
        gid => 1,
        hash => 0,
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

    my $select_items = [ 'me.sc_idata_id', 'me.sc_mitem_id', 'path_id.path', 'scan_id.mconf_sec_id' ];
    my $select_as_items = [ 'sc_idata_id', 'sc_mitem_id', 'path', 'mconf_sec_id' ];

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
            'join' => [
                { 'sc_mitem_id' => 'path_id' },
                'scan_id'
            ],
            'select' => $select_items,
            'as' => $select_as_items,
            'order_by' => [ 'path_id.path', ],
            'result_class' => 'DBIx::Class::ResultClass::HashRefInflator',
        },
    );

    return $prev_sc_idata_rs;
}


=head2 has_same_data

Return 1 if given hashs has same attributes' values.

=cut

sub has_same_data {
    my ( $self, $new, $old, $ignore_not_found ) = @_;

    my $attrs = $self->get_item_attrs();
    # Add additional attribute 'found'.
    $attrs->{found} = 1;

    foreach my $attr_name ( keys %$attrs ) {
        if ( $ignore_not_found && (not defined $new->{ $attr_name }) ) {
            next;
        }
        
        my $is_numeric = $attrs->{$attr_name};
        #print "$attr_name is_numeric=$is_numeric\n";
        if ( $is_numeric ) {
            return 0 if defined $new->{$attr_name} && ( (not defined $old->{$attr_name}) || $old->{$attr_name} != $new->{$attr_name} );
            return 0 if defined $old->{$attr_name} && ( (not defined $new->{$attr_name}) || $new->{$attr_name} != $old->{$attr_name} );
        } else {
            return 0 if defined $new->{$attr_name} && ( (not defined $old->{$attr_name}) || $old->{$attr_name} ne $new->{$attr_name} );
            return 0 if defined $old->{$attr_name} && ( (not defined $new->{$attr_name}) || $new->{$attr_name} ne $old->{$attr_name} );
        }
        #print "  -> are same\n";
    }

    return 1;
}


=head2 get_base_idata

Return hash ref for database. Hash is created from base_data completed with values from raw_data.

=cut

sub get_base_idata {
    my ( $self, $base_data, $raw_data, $old_data ) = @_;

    my $data = { %$base_data };

    my $attrs = get_item_attrs();
    foreach my $attr_name ( keys %$attrs ) {
        # Use new value.
        if ( exists $raw_data->{ $attr_name } ) {
            $data->{ $attr_name } = $raw_data->{ $attr_name };

        # Use old value.
        } elsif ( defined $old_data->{ $attr_name } ) {
            $data->{ $attr_name } = $old_data->{ $attr_name };

        # Use undef.
        } else {
            $data->{ $attr_name } = undef;
        }
    }
    return $data;
}


=head2 flags_hash_to_str

Sort hash keys and join its to canonized flags string.

=cut

# Copied from ScanHost::flags_hash_to_str method.
sub flags_hash_to_str {
    my ( $self, %flags ) = @_;

    my $flags_str = '';
    foreach my $key ( sort keys %flags ) {
        $flags_str .= sprintf( "%1s%1s", $flags{$key}, $key );
    }

    return $flags_str;
}


=head2 join_flags

Join flags.

=cut

# Based on ScanHost::join_flags method.
sub join_flags {
    my ( $self, $base_flags, $flags_to_add ) = @_;

    my $flags = { %$base_flags };

    # Add flags.
    foreach my $flag_name ( keys %$flags_to_add ) {
        $flags->{ $flag_name } = $flags_to_add->{ $flag_name };
    }

    my $plus_found = 0;
    # Check if there is some positive flag.
    foreach my $value ( values %$flags ) {
        if ( $value eq '+' ) {
            $plus_found = 1;
            last;
        }
    }

    return ( $flags, $plus_found );
}


=head2 processs_path_regexes

Try each regex on given path and join flags for those which match.

=cut

# Based on ScanHost::processs_path_regexes method.
sub process_path_regexes {
    my ( $self, $regexes_conf, $full_path, $base_flags, $base_plus_found ) = @_;
    
    my $debug_prefix = '  ';

    my $flags = { %$base_flags };
    my $plus_found = $base_plus_found;
    
    foreach my $regex_conf ( @$regexes_conf ) {
        my ( $regex, $regex_flags, $is_recursive ) = @$regex_conf;
        print $debug_prefix."  trying '$regex' $is_recursive\n" if $self->{ver} >= 10;

        if ( $full_path =~ /^$regex$/ ) {
            print $debug_prefix."  matched with '$regex', '" . $self->flags_hash_to_str( %$regex_flags ) . "'\n" if $self->{ver} >= 9;
            ( $flags, $plus_found ) = $self->join_flags( $flags, $regex_flags );
        }
    }
    return $plus_found;
}


=head2 flags_or_regex_succeed

Try to 

=cut

sub flags_or_regex_succeed {
    my ( $self, $full_path ) = @_;

    my $path = $full_path;
    $path = '' if $path eq '/'; # special for root path

    # Try to find parent path ( or parent of parent path or ... ).
    if ( not exists $self->{host_conf}->{path_filter_conf}->{ $path } ) {
        my $last_run = ( $full_path ne '' );
        while ( ( my ( $parent_path ) = $path =~ m{ ^ (.+) \/ [^\/]+ $ }x  ) || $last_run ) {

            unless ( $parent_path ) {
                $last_run = 0;
                $parent_path = '';
            }
            # print "$full_path ($flags_completed) - parent_path: '$parent_path'\n";

            if ( exists $self->{host_conf}->{path_filter_conf}->{ $parent_path . '/' } ) {
                $path = $parent_path . '/';
                last;
            }

            if ( exists $self->{host_conf}->{path_filter_conf}->{ $parent_path } ) {
                $path = $parent_path;
                last;
            }

            $path = $parent_path;
        }
    }

    my $path_conf = $self->{host_conf}->{path_filter_conf}->{ $path };

    my $plus_found = 0;

    # Check if there is some positive flag.
    foreach my $value ( values %{ $path_conf->{flags} } ) {
        if ( $value eq '+' ) {
            $plus_found = 1;
            last;
        }
    }

    return $plus_found unless exists $self->{host_conf}->{path_filter_conf}->{$path}->{regexes};

    my $regexes_conf = $self->{host_conf}->{path_filter_conf}->{$path}->{regexes};
    $plus_found = $self->process_path_regexes( 
        $regexes_conf,
        $full_path,
        $path_conf->{flags},
        $plus_found
    );
  
    return $plus_found;
}


=head2 scan_cmd

Run scan command.

=cut

sub scan_cmd {
    my ( $self, $opt ) = @_;

    my $ver = $self->{ver};
    my $schema  = $self->{schema};

    my $scan_conf = $self->get_scan_conf( 0 );

    my $machine_id = $self->{host_conf}->{machine_id};
    my $mconf_sec_id = $self->{host_conf}->{mconf_sec_id};

    # Insert scan row. Before transaction start.
    my $scan_row = $schema->resultset('scan')->create({
        mconf_sec_id => $mconf_sec_id,
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

    my $print_progress = ( $self->{ver} >= 4 );

    my $response_num = 1;
    my $response = $result_obj->getResponse();
    my $loaded_items = $response->{loaded_items};

    # Next parts.
    while ( $result_obj->isSuccess && !$result_obj->isLast ) {
        $result_obj = $self->{rpc}->get_next_response( 1 );
        $response = $result_obj->getResponse();
        $response_num++;
        $loaded_items = [
            @$loaded_items,
            @{$response->{loaded_items}}
        ];
        if ( $print_progress ) {
            my $last_path = $loaded_items->[ -1 ]->{path};
            $self->print_progress( "%s: path '%s', items %s", $response_num, $last_path, $#$loaded_items+1 );
        }
    }
    $self->print_progress() if $print_progress;
    # $self->dump( 'Loaded items', $loaded_items ); exit; # debug

    my %path_to_num = ();
    foreach my $num ( 0..$#$loaded_items ) {
        my $item = $loaded_items->[ $num ];
        print "Loaded item $item->{path} ($num)\n" if $ver >= 7;
        # 2 .. found on host, initial status
        # if not changed to 0 (in db and the same) or 1 (in db and changed) then 2 means 'new' -> insert to db
        $path_to_num{ $item->{path} } = [ 2, $num ];
    }

    my $prev_sc_idata_rs = $self->get_sc_idata_rs( $machine_id );

    my $path_rs = $schema->resultset('path');
    my $sc_mitem_rs = $schema->resultset('sc_mitem');
    my $sc_idata_rs = $schema->resultset('sc_idata');

    NEXT_DB_ITEM: while ( my $row = $prev_sc_idata_rs->next ) {
        my $path = $row->{path};
        
        #$self->dump( 'Prev idata row', $row ) if $ver >= 6;
        if ( $mconf_sec_id != $row->{'mconf_sec_id'} ) {
            unless ( $self->flags_or_regex_succeed( $path ) ) {
                print "Skipping '$path' (from DB) - no valid for this configuration.\n" if $self->{ver} >= 6;
                next NEXT_DB_ITEM;
            }
        }

        my $insert_idata = undef;

        # Found.
        if ( exists $path_to_num{ $path } ) {
            my $new_item_data = $loaded_items->[ $path_to_num{ $path }->[1] ];
            if ( $self->has_same_data( $new_item_data, $row, 1 ) ) {
                # Same data -> do nothing.
                $path_to_num{ $path }->[0] = 0; # 0 .. found in db and not changed
                print "Item '$path' not changed.\n" if $ver >= 6;

            } else {
                # Data changed -> do update.
                $path_to_num{ $path }->[0] = 1; # 1 .. found in db and changed
                if ( $ver >= 5 ) {
                    print "Item data changed:\n";
                    $self->dump( 'new item data', $new_item_data );
                    $self->dump( 'prev item data', $row );
                }

                my $sc_mitem_id = $row->{'sc_mitem_id'};
                print "Updating status to new values sc_mitem_id $sc_mitem_id.\n" if $ver >= 4;
                my $insert_idata_base = {
                    sc_mitem_id => $sc_mitem_id,
                    scan_id => $scan_id,
                    newer_id => undef,
                    found => 1,
                };
                #$new_item_data->{size} = int rand(500); # debug
                $insert_idata = $self->get_base_idata( $insert_idata_base, $new_item_data, $row );
            }

        # Not found during scan on client machine -> delete.
        } else {
            my $sc_mitem_id = $row->{'sc_mitem_id'};
            print "Updating status to delete sc_mitem_id $sc_mitem_id.\n" if $ver >= 4;
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

            my $old_sc_idata_rs = $schema->resultset('sc_idata')->find( $row->{'sc_idata_id'} );
            $old_sc_idata_rs->update({ newer_id => $new_sc_idata_id });
        }
    }


    foreach my $num ( 0..$#$loaded_items ) {
        my $item = $loaded_items->[ $num ];
        my $path = $item->{path};
        # insert
        if ( $path_to_num{ $path }->[0] == 2 ) {
            print "Inserting path $path (path_id=" if $ver >= 4;

            my $path_row = $path_rs->find_or_create({
                path => $path,
            });
            my $path_id = $path_row->path_id;
            print $path_id.', sc_mitem_id=' if $ver >= 4;

            my $sc_mitme_row = $sc_mitem_rs->find_or_create({
                machine_id => $machine_id,
                path_id => $path_id,
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
            print ").\n"  if $ver >= 4;
        }
    }

    #$self->dump( 'Path to num', \%path_to_num ) if $ver >= 6;

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



=head2 mconf_to_db

Prepare params and call mconf_to_db method on L<SysFink::Conf::DBIC>.

=cut

sub mconf_to_db_cmd {
    my ( $self, $opt ) = @_;

    return 0 unless $self->init_mconf_obj();

    my $mconf_path = 'conf-machines';
    $mconf_path = $opt->{mconf_path} if defined $opt->{mconf_path};

    my $absolute_mconf_path;
    if ( $mconf_path =~ m{^\/} ) {
        $absolute_mconf_path = $mconf_path;
    } else {
        $absolute_mconf_path = catdir( $self->{RealBin}, $mconf_path );
    }

    unless ( -d $absolute_mconf_path ) {
        return $self->err("Machine conf directory '$mconf_path' ('$absolute_mconf_path') not found.");;
    }

    return $self->mconf_err() unless $self->{mconf_obj}->mconf_to_db( $absolute_mconf_path, $self->{user_id} );
    return 1;
}


=head2 get_mode_str

Convert numeric node number to ls format. Used for debug output.

=cut

sub get_mode_str() {
    my ( $self, $mode ) = @_;

    unless ( defined($mode) ) {
        return "??????????";
    }

    my @flag;

    $flag[0] = S_ISDIR($mode) ? 'd' : '-';
    $flag[0] = 'l' if (S_ISLNK($mode));
    $flag[0] = 'b' if (S_ISBLK($mode));
    $flag[0] = 'c' if (S_ISCHR($mode)) ;
    $flag[0] = 'p' if (S_ISFIFO($mode));
    $flag[0] = 's' if (S_ISSOCK($mode));

    $flag[1] = ($mode & S_IRUSR) >> 6 ? 'r' : '-';
    $flag[2] = ($mode & S_IWUSR) >> 6 ? 'w' : '-';
    $flag[3] = ($mode & S_IXUSR) >> 6 ? 'x' : '-';
    $flag[3] = 's' if (($mode & S_ISUID) >> 6);

    $flag[4] = ($mode & S_IRGRP) >> 3 ? 'r' : '-';
    $flag[5] = ($mode & S_IWGRP) >> 3 ? 'w' : '-';
    $flag[6] = ($mode & S_IXGRP) >> 3 ? 'x' : '-';
    $flag[6] = 's' if (($mode & S_ISGID) >> 6);

    $flag[7] = ($mode & S_IROTH) >> 0 ? 'r' : '-';
    $flag[8] = ($mode & S_IWOTH) >> 0 ? 'w' : '-';
    $flag[9] = ($mode & S_IXOTH) >> 0 ? 'x' : '-';
    $flag[9] = 't' if (($mode & S_ISVTX) >> 0);

#   ($mode & S_IRGRP) >> 3;

    return join('', @flag);
}


=head2 get_attr_str

Run string representation for given value of given attribute type.

=cut

sub get_attr_str {
    my ( $self, $attr, $value ) = @_;

    return 'undef' unless defined $value;

    if ( $attr eq 'mode' ) {
        return $self->get_mode_str( $value );
    }

    if ( $attr eq 'mtime' ) {
        return DateTime->from_epoch( epoch => $value )->datetime;;
    }
    
    return $value;
}


=head2 check_and_load_host_and_section

Check and load machine_id and mconf_sec_id from given --host and --section.

=cut

sub check_and_load_host_and_section {
    my ( $self, $opt ) = @_;

    # Check params.
    my $host = $opt->{host};
    if ( $opt->{section} ) {
        return $self->set_mandatory_param_err('host', ' when --section given.') unless $host;
    }

    # Load hosts with not audited diffs or check if given host/section has not audited diffs.
    my $machine_id = undef;
    my $mconf_sec_id = undef;
    if ( $host ) {
        return 0 unless $self->init_mconf_obj();
        $machine_id = $self->{mconf_obj}->get_machine_id( $host );
        return $self->mconf_err() unless $machine_id;
        
        if ( $opt->{section} ) {
            my $section_name = lc( $opt->{section} );
            my $mconf_sec_data = $self->{mconf_obj}->get_machine_active_mconf_sec_info( $machine_id, $section_name );
            return $self->mconf_err() unless $mconf_sec_data;
            $mconf_sec_id = $mconf_sec_data->[0];
        }
    }
    
    return ( 1, $machine_id, $mconf_sec_id );
}


=head2 diff_cmd

Run diff command.

=cut

sub diff_cmd {
    my ( $self, $opt ) = @_;

    my ( $ret_code, $machine_id, $mconf_sec_id ) = $self->check_and_load_host_and_section( $opt );
    return 0 unless $ret_code;

    my $ver = $self->{ver};
    my $schema  = $self->{schema};

    my $attrs_conf = get_item_attrs();

    my $cols = [ qw/ 
        mc.machine_id
        path.path
        sd.sc_idata_id
        psd.sc_idata_id
        sd.found
        si.sc_mitem_id
        psd.found
        machine.name
        aid.aud_status_id
    / ];

    my $idata_items = [];
    foreach my $item ( keys %$attrs_conf ) {
        push @$cols, 'sd.' . $item;
    }
    foreach my $item ( keys %$attrs_conf ) {
        push @$cols, 'psd.' . $item;
    }

    
    my $cols_sql_str = '';
    #$cols_sql_str = join( q{, }, @$cols );
    my $name_to_pos = {};
    my $pos_to_name = [];
    foreach my $col_num ( 0..$#$cols ) {
        my $col = $cols->[ $col_num ];
        $cols_sql_str .= ",\n" if $cols_sql_str;
        $cols_sql_str .= $col;
        if ( $col =~ /\./ ) {
            my $esc_col = $col;
            $esc_col =~ tr{\.}{\_};
            $cols_sql_str .= ' as ' . $esc_col;
            $name_to_pos->{ $esc_col } = $col_num;
            $pos_to_name->[ $col_num ] = $esc_col;
        } else {
            $name_to_pos->{ $cols_sql_str } = $col_num;
            $pos_to_name->[ $col_num ] = $col;
        }
    }
    
    if ( $self->{ver} >= 10 ) {
        $self->dump( 'cols', $cols );
        $self->dump( '$cols_sql_str', $cols_sql_str );
        $self->dump( '$name_to_pos', $name_to_pos );
        $self->dump( '$pos_to_name', $pos_to_name );
    }

    my $data = $schema->storage->dbh_do(
        sub {
            my ( $storage, $dbh, $cols_str, $in_params ) = @_;
            return $dbh->selectall_arrayref("
                 select $cols_str
                   from sc_idata sd
                   left join sc_idata psd on psd.newer_id = sd.sc_idata_id
                   left join aud_idata aid on (
                             aid.sc_idata_id = sd.sc_idata_id
                         and aid.newer_id is null
                    )
                  inner join sc_mitem si on si.sc_mitem_id = sd.sc_mitem_id
                  inner join path on path.path_id = si.path_id
                  inner join scan on scan.scan_id = sd.scan_id
                  inner join mconf_sec mcs on mcs.mconf_sec_id = scan.mconf_sec_id
                  inner join mconf mc on mc.mconf_id = mcs.mconf_id
                  inner join machine on machine.machine_id = mc.machine_id
                  where sd.newer_id is null
                    and ( ? is null or scan.mconf_sec_id = ? )
                    and ( ? is null or machine.machine_id = ? )
                    and machine.active = 1
                    and ( aid.aud_idata_id is null 
                          or ( aid.aud_status_id != 1 and aid.aud_status_id != 2 )
                    )
                  order by machine.machine_id, path.path
                ",
                {}, @$in_params
            );
        },
        $cols_sql_str,
        [ $mconf_sec_id, $mconf_sec_id, $machine_id, $machine_id ]
    );
    #$self->dump( 'data', $data );

    my $prev_machine_name = '';
    my $machine_str = undef;
    foreach my $row ( @$data ) {
        # machine
        my $machine_name = $row->[ $name_to_pos->{machine_name} ];
        if ( $prev_machine_name ne $machine_name ) {
            my $machine_str = $machine_name;
            $prev_machine_name = $machine_name;
        }

        # path
        my $path_str = "  " . $row->[ $name_to_pos->{path_path} ];
        $path_str .= " (sc_mitem=" . $row->[ $name_to_pos->{si_sc_mitem_id} ] . ")" if $self->{ver} >= 4;

        # diff_str init
        my $diff_str = '';

        if ( ! $row->[ $name_to_pos->{'psd_found'} ] ) {
            $path_str .= " - added";
            foreach my $attr ( keys %$attrs_conf ) {
                my $new = $row->[ $name_to_pos->{'sd_'.$attr} ];
                $diff_str .= "    $attr: " . $self->get_attr_str($attr, $new) . "\n";
            }

        } elsif ( ! $row->[ $name_to_pos->{'sd_found'} ] ) {
            $path_str .= " - deleted"; 
            foreach my $attr ( keys %$attrs_conf ) {
                my $old = $row->[ $name_to_pos->{'psd_'.$attr} ];
                $diff_str .= "    $attr: " . $self->get_attr_str($attr, $old) . "\n";
            }
            
        } else {
            $path_str .= " - changed"; 

            # attrs changes
            foreach my $attr ( keys %$attrs_conf ) {
                my $new = $row->[ $name_to_pos->{'sd_'.$attr} ];
                my $old = $row->[ $name_to_pos->{'psd_'.$attr} ];
                
                my $is_number = $attrs_conf->{ $attr };
                if ( (not defined $new) || (not defined $old) ) {
                    if ( (not defined $new) && (not defined $old) ) {
                        # ok
                    } elsif ( not defined $new ) {
                        $diff_str .= "    $attr: ";
                        $diff_str .= $self->get_attr_str($attr, $old);
                        $diff_str .= " -> undef\n";
                    } else {
                        $diff_str .= "    $attr: undef -> ";
                        $diff_str .= $self->get_attr_str($attr, $new);
                        $diff_str .=  "\n";
                    }

                } elsif ( ($is_number && $new != $old) || (!$is_number && $new ne $old) ) {
                    $diff_str .=  "    $attr: ";
                    $diff_str .= $self->get_attr_str($attr, $old);
                    $diff_str .=  " -> ";
                    $diff_str .= $self->get_attr_str($attr, $new);
                    $diff_str .=  "\n";
                }
            } # foreach
        }

        $path_str .= " (id:" . $row->[ $name_to_pos->{sd_sc_idata_id} ] . ")";
        if ( $diff_str ) {
            if ( defined $machine_str ) {
                print $machine_str . "\n";
                $machine_str = undef;
            }
            if ( defined $path_str ) {
                print $path_str . "\n"; 
                $path_str = undef;
            }
            print $diff_str;
            $diff_str = undef;
            
            if ( defined $row->[ $name_to_pos->{aid_aud_status_id} ] ) {
                print "    last audit status: " . $row->[ $name_to_pos->{aid_aud_status_id} ] . "\n";
            }
            print "\n";
        }
    }
    
    return 1;
}


=head2 audit_cmd

Run audit command.

=cut

sub audit_cmd {
    my ( $self, $opt ) = @_;

    my ( $ret_code, $machine_id, $mconf_sec_id ) = $self->check_and_load_host_and_section( $opt );
    return 0 unless $ret_code;

    my $aud_status_id = 1;
    
    my $ver = $self->{ver};
    my $schema  = $self->{schema};

    $schema->storage->txn_begin;

    my $msg = undef;

    # Insert aud info.
    my $aud_row = $schema->resultset('aud')->create({
        date => DateTime->now,
        user_id => $self->{user_id},
        msg => $msg,
    });
    my $aud_id = $aud_row->aud_id;

    my $cols_sql_str = "sd.sc_idata_id";
    my $data = $schema->storage->dbh_do(
        sub {
            my ( $storage, $dbh, $cols_str, $in_params ) = @_;
            return $dbh->selectall_arrayref("
                 select $cols_str
                   from sc_idata sd
                  inner join sc_mitem si on si.sc_mitem_id = sd.sc_mitem_id
                  inner join path on path.path_id = si.path_id
                  inner join scan on scan.scan_id = sd.scan_id
                  inner join mconf_sec mcs on mcs.mconf_sec_id = scan.mconf_sec_id
                  inner join mconf mc on mc.mconf_id = mcs.mconf_id
                  inner join machine on machine.machine_id = mc.machine_id
                  where sd.newer_id is null
                    and ( ? is null or scan.mconf_sec_id = ? )
                    and ( ? is null or machine.machine_id = ? )
                    and machine.active = 1
                    and not exists (
                      select 1
                        from aud_idata aid
                       where aid.sc_idata_id = sd.sc_idata_id
                         and aid.newer_id is null
                    )
                  order by machine.machine_id, path.path
                ",
                {}, @$in_params
            );
        },
        $cols_sql_str,
        [ $mconf_sec_id, $mconf_sec_id, $machine_id, $machine_id ],
        
    );

    foreach my $row ( @$data ) {
        my $sc_idata_id = $row->[0];
        my $aud_idata_row = $schema->resultset('aud_idata')->create({
            aud_id => $aud_id,
            sc_idata_id => $sc_idata_id,
            aud_status_id => $aud_status_id,
            newer_id => undef,
        });
        print "sc_idata_id $sc_idata_id audit status sets to $aud_status_id\n" if $ver >= 4;
    }
    
    $schema->storage->txn_commit;
    
    return 1;
}


=head1 SEE ALSO

L<SysFink>

=head1 LICENSE

This file is part of SysFink. See L<SysFink> license.

=cut


1;
