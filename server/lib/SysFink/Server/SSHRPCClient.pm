package SysFink::Server::SSHRPCClient;

use strict;
use warnings;

use base 'SysFink::Base';


use Net::OpenSSH;
use File::Spec::Functions;

use SSH::RPC::PP::Client;


=head1 NAME

SysFink::Server::SSHRPCClient - The requestor of an RPC call over SSH.

=head1 SYNOPSIS

ToDo

=head1 DESCRIPTION

In RPC this requestor is considered client side. SysFink run this on server.

=head1 METHODS


=head2 new

Constructor.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );

    return undef unless $self->set_default_values();
    return $self;
}


=head2 set_default_values

Validate and sets options.

=cut

sub set_default_values {
    my ( $self ) = @_;

    $self->{ssh} = undef;

    $self->{user} = 'root';
    $self->{host} = 'localhost';
    $self->{host_dist_type} = undef;
    $self->{client_dir} = $self->set_client_dir();

    $self->{rpc} = undef;
    $self->{rpc_ver} = $self->{ver};
    $self->{rpc_nice} = 10;
    $self->{rpc_last_cmd} = undef;

    $self->{RealBin} = '';
    $self->{client_src_dir} = $self->get_client_src_dir();

    return 1;
}


=head2 set_options

Validate and sets options.

=cut

sub set_options {
    my ( $self, $options ) = @_;

    $self->{ver} = $options->{ver} if defined $options->{ver};

    if ( defined $options->{user} ) {
        return 0 unless $self->set_user( $options->{user} );
    }

    if ( defined $options->{host} ) {
        return 0 unless $self->set_host( $options->{host} );
    }

    if ( defined $options->{host_dist_type} ) {
        $self->{host_dist_type} = $options->{host_dist_type};
    }

    if ( defined $options->{client_src_dir} ) {
        $self->{client_src_dir} = $options->{client_src_dir};
    } elsif ( defined $options->{RealBin} ) {
        $self->{RealBin} = $options->{RealBin};
        $self->{client_src_dir} = $self->get_client_src_dir();
    }

    if ( defined $options->{rpc_ver} ) {
        $self->{rpc_ver} = $options->{rpc_ver};
    } else {
        $self->{rpc_ver} = $self->{ver};
    }

    return 1;
}


=head2 disconnect

Disconnect from client.

=cut

sub disconnect {
    my ( $self ) = @_;

    $self->stop_perl_shell() if defined $self->{rpc};
    $self->{ssh} = undef;
    return 1;
}


=head2 set_host

Validate hostname and set it.

=cut

sub set_host {
    my ( $self, $host ) = @_;

    $self->disconnect if defined $self->{ssh};
    $self->{host} = $host;
    return 1;
}


=head2 get_client_dir

Return SysFink directory path on client for user name.

=cut

sub get_client_dir {
    my ( $self ) = @_;

    return '/root/sysfink-client' if $self->{user} eq 'root';
    return '/home/' . $self->{user} . '/sysfink-client';
}


=head2 set_client_dir

Sets SysFink directory path on client for user name.

=cut

sub set_client_dir {
    my ( $self ) = @_;

    $self->{client_dir} = $self->get_client_dir();
    print "New client_dir: '$self->{client_dir}'\n" if $self->{ver} >= 5;
    return 1;
}


=head2 set_user

Validate user name and set it.

=cut

sub set_user {
    my ( $self, $user ) = @_;

    unless ( defined $user ) {
        $self->err('No user name defined');
        return 0;
    }

    unless ( $user ) {
        $self->err('User name is empty');
        return 0;
    }

    if ( $user =~ /\s/ ) {
        $self->err('User name contains empty string.');
        return 0;
    }

    if ( $user =~ /[\.\:\;\\\/]/ ) {
        $self->err('User name contains not allowed char.');
        return 0;
    }

    $self->disconnect if defined $self->{ssh};
    $self->{user} = $user;

    return $self->set_client_dir();
}


=head2 get_client_src_dir

Return SysFink source code directory path on server.

=cut

sub get_client_src_dir {
    my ( $self ) = @_;
    return catdir( $self->{RealBin}, '..', 'client' );
}


=head2 connect

Connect to remote host.

=cut

sub connect {
    my ( $self, $host, $user ) = @_;

    return $self->err('No hostname sets.') if (not defined $host) && (not defined $self->{host});
    $host = $self->{host} unless defined $host;

    return $self->err("Bad user name '$user'.") if $user && ! $self->check_user_name( $user );

    if ( defined $user ) {
        return 0 unless $self->set_user( $user );
    } else {
        return $self->err('No user sets.') unless defined $self->{user};
        $host = $self->{user} unless defined $user;
    }

    my $ssh = Net::OpenSSH->new(
        $self->{host},
        user => $self->{user},
        master_opts => [ '-T']
    );
    return $self->err("Couldn't establish SSH connection: ". $ssh->error ) if $ssh->error;

    $self->{ssh} = $ssh;
    return 1;
}


=head2 err_rcc_cmd

Create and set error message for command.

=cut

sub err_rcc_cmd {
    my ( $self, $cmd, $err ) = @_;

    chomp($err);
    my $full_err = "RCC '$cmd' return error output: '$err'";
    return $self->err( $full_err );
}


=head2 do_rcc

Run command on client over SSH.

=cut

sub do_rcc {
    my ( $self, $cmd, $report_err ) = @_;
    $report_err = 1 unless defined $report_err;

    print "Running client command '$cmd':\n" if $self->{ver} >= 6;

    my ( $out, $err ) = $self->{ssh}->capture2( $cmd );
    my $exit_code = $?;

    if ( $self->{ver} >= 5 && ( $out || $err || $exit_code ) ) {
        my $msg_out = 'undef';
        $msg_out = "'" . $out . "'" if defined $out;

        my $msg_err = 'undef';
        $msg_err = "'" . $err . "'" if defined $err;

        my $msg_exit_code = 'undef';
        $msg_exit_code = "'" . $exit_code . "'" if defined $exit_code;

        print "out: $msg_out, err: $msg_err, exit_code: $msg_exit_code\n";
    }

    # Set error. Caller should do "return 0 if $err;".
    if ( $err && $report_err ) {
        $self->err_rcc_cmd( $cmd, $err );
    }

    return ( $out, $err, $exit_code );
}


=head2 test_hostname

Call hostname command on client and compare it.

=cut

sub test_hostname {
    my ( $self ) = @_;

    my ( $out, $err ) = $self->do_rcc( 'hostname', 1 );
    return 0 if $err;

    my $hostname = $out;
    chomp( $hostname );

    my $ok = 0;
    if ( $self->{host} eq $hostname ) {
        $ok = 1;
    
    } elsif ( $self->{host} !~ m{\.} ) {
        if ( my ($base_hostname) = $hostname =~ m{ ^ ([^\.]+) \. }x ) {
            if ( $base_hostname eq $self->{host} ) {
                print "Hostname reported from client is '$hostname' and probably match given '$self->{host}'.\n" if $self->{ver} >= 4;
                $ok = 1;
            }
        }
    }
    
    unless ( $ok ) {
        return $self->err("Hostname reported from client is '$hostname', but object attribute host is '$self->{host}'.");
    }

    print "Command 'test_hostname' succeeded.\n" if $self->{ver} >= 3;
    return 1;
}


=head2 check_is_dir

Run test -d on client and return 1 (exists and is directory), 0 (not exists or isn't directory) or undef (error).

=cut

sub check_is_dir {
    my ( $self, $path ) = @_;

    my $cmd = "test -d $path";
    my ( $out, $err, $exit_code ) = $self->do_rcc( $cmd, 1 );
    return undef if $err;
    return 0 if $exit_code;
    return 1;
}


=head2 ls_output_contains_unknown_dir

Return 1 if output captured from ls command contains any unknown directory. This is useful to check
if we are not doing critical mistake by recursively removing (rm -rf).

=cut

sub ls_output_contains_unknown_dir {
    my ( $self, $out ) = @_;

    chomp $out;
    my @lines = split( /\n/, $out );
    shift @lines; # remove line "total \d+"
    foreach my $line ( @lines ) {
        if ( $line =~ /^\s*d/ ) {
            return 1 if $line !~ /(bin|lib|libcpan|libdist){1}\s*$/;
        }
    }
    return 0;
}


=head2 check_client_dir

Run ls command on client and validate output. See L<ls_output_contains_unknown_dir> method.

=cut

sub check_client_dir {
    my ( $self ) = @_;

    my $client_dir = $self->{client_dir};

    # Process error output of command own way.
    my $cmd = "ls -l $client_dir";
    my ( $out, $err ) = $self->do_rcc( $cmd, 0 );
    if ( $err ) {
        if ( $err =~ /No such file or directory/i ) {
            print "Directory '$client_dir' doesn't exists on host.\n" if $self->{ver} >= 3;
        } else {
            return $self->err_rcc_cmd( $cmd, $err );
        }

    } elsif ( $self->ls_output_contains_unknown_dir($out) ) {
        $self->err("Directory '$client_dir' on client contains some unknown directories.\nCmd 'ls -l' output is\n$out.");
        return 0;
    }

    print "Command 'check_client_dir' succeeded.\n" if $self->{ver} >= 3;
    return 1;
}


=head2 remove_client_dir

L<check_client_dir> and erase its content with rm -rf.

=cut

sub remove_client_dir {
    my ( $self ) = @_;

    # ToDo - safe enought?
    return 0 unless $self->check_client_dir();

    my $client_dir = $self->{client_dir};

    my ( $out, $err );

    # ToDo - path escaping?
    ( $out, $err ) = $self->do_rcc( "rm -rf $client_dir", 1 );
    return 0 if $err;

    print "Command 'remove_client_dir' succeeded.\n" if $self->{ver} >= 3;
    return 1;
}


=head2 get_server_dir_items

Return items list of given directory (on server).

=cut

sub get_server_dir_items {
    my ( $self, $dir_name ) = @_;

    # Load direcotry items list.
    my $dir_handle;
    if ( not opendir($dir_handle, $dir_name) ) {
        #add_error("Directory '$dir_name' not open for read.");
        return 0;
    }
    my @all_dir_items = readdir($dir_handle);
    close($dir_handle);

    my @dir_items = ();
    foreach my $item ( @all_dir_items ) {
        next if $item eq '.';
        next if $item eq '..';
        next if $item =~ /^\s*$/;
        push @dir_items, $item;
    }

    return \@dir_items;
}


=head2 put_dir_content

Put given directory on client. Skips Subversion directories.

=cut

sub put_dir_content {
    my ( $self, $base_src_dir, $sub_src_dir, $base_dest_dir  ) = @_;

    my $full_src_dir = catdir( $base_src_dir, $sub_src_dir );
    my $dir_items = $self->get_server_dir_items( $full_src_dir );
    return 0 unless ref $dir_items;

    my $sub_dirs = [];
    my $full_src_path;
    ITEM: foreach my $name ( sort @$dir_items ) {

        $full_src_path = catdir( $full_src_dir, $name );

        if ( -d $full_src_path ) {
            # ignore Subversion dirs
            next if $name eq '.svn';
            next if $name eq '_svn';
            push @$sub_dirs, $name;

        } elsif ( -f $full_src_path ) {
            my $full_dest_fpath = catfile( $base_dest_dir, $sub_src_dir, $name );
            print "putting item '$full_src_path' -> '$full_dest_fpath'\n" if $self->{ver} >= 5;
            $self->{ssh}->scp_put( $full_src_path, $full_dest_fpath );
        }
    }

    foreach my $sub_dir ( sort @$sub_dirs ) {
        my $new_sub_src_dir = catdir( $sub_src_dir, $sub_dir );
        my $full_dest_fpath = catdir( $base_dest_dir, $new_sub_src_dir );
        my ( $err, $out ) = $self->do_rcc( "mkdir $full_dest_fpath", 1 );
        return 0 if $err;
        return 0 unless $self->put_dir_content( $base_src_dir, $new_sub_src_dir, $base_dest_dir );
    }

    return 1;
}


=head2 renew_client_dir

Remove old (if needed) and put new SysFink source files (script, base dist and
arch dist libraries) on client.

=cut

sub renew_client_dir {
    my ( $self ) = @_;

    unless ( $self->{host_dist_type} ) {
        return $self->err("Parameter 'host_dist_type' is mandatory for this command.");
    }

    my $client_src_dir = $self->{client_src_dir};
    my $client_dir = $self->{client_dir};

    # check if dir (source on client) exists
    my $dir_exists = $self->check_is_dir( $client_dir );
    return 0 unless defined $dir_exists;

    # remove old dir
    if ( $dir_exists ) {
        return 0 unless $self->remove_client_dir();
    }

    # create new
    my ( $err, $out ) = $self->do_rcc( "mkdir $client_dir", 1 );
    return 0 if $err;

    # put base script
    my $client_src_name = 'sysfink-client.pl';
    my $client_src_fpath = catfile( $client_src_dir, $client_src_name );
    $self->{ssh}->scp_put( $client_src_fpath, $client_dir );

    # put base dist directory
    my $dist_base_src_dir = catdir( $client_src_dir, 'dist', '_base' );
    return 0 unless $self->put_dir_content( $dist_base_src_dir, '', $client_dir );

    # put arch dist directory
    my $dist_type = $self->{host_dist_type};
    my $dist_arch_src_dir = catdir( $client_src_dir, 'dist', $dist_type );
    return 0 unless $self->put_dir_content( $dist_arch_src_dir, '', $client_dir );

    print "Command 'renew_client_dir' succeeded.\n" if $self->{ver} >= 3;
    return 1;
}


=head2 start_rpc_shell

Start SysFink RPC shell on client machine.

=cut

sub start_rpc_shell {
    my ( $self ) = @_;

    my $client_src_name = 'sysfink-client.pl';
    my $client_script_fpath = catfile( $self->{client_dir}, $client_src_name );

    my $client_start_cmd = "nice -n $self->{rpc_nice} /usr/bin/perl $client_script_fpath $self->{rpc_ver}";
    #$client_script_fpath = 'c:\cygwin\home\jurosz\sysfink-client\sysfink-client.pl';
    #$client_start_cmd = "nice -n $self->{rpc_nice} perl '$client_script_fpath' $self->{rpc_ver}";
    
    print "Client start command: '$client_start_cmd'\n" if $self->{ver} >= 5;

    my $rpc = SSH::RPC::PP::Client->new(
        $self->{ssh},
        $client_start_cmd,
        $self->{ver}
    );
    $self->{rpc} = $rpc;
    $self->{rpc_last_cmd} = undef;

    return 1;
}


=head2 stop_rpc_shell

Stop SysFink RPC shell on client machine.

=cut

sub stop_rpc_shell {
    my ( $self ) = @_;

    $self->{rpc} = undef;
    $self->{rpc_last_cmd} = undef;
    return 1;
}


=head2 validate_result_obj

Validate result_obj from do_rpc or get_next_response method.

=cut

sub validate_result_obj {
    my ( $self, $result_obj, $report_response_error ) = @_;

    my $is_ok = $result_obj->isSuccess;

    $result_obj->dump() if $self->{ver} >= 7 || ( !$is_ok && $self->{ver} >= 1 );

    if ( ! $is_ok ) {
        my $err_msg = "Fatal error for client shell command '$self->{rpc_last_cmd}': '" . $result_obj->getStatusMessage() . "'";
        $self->err( $err_msg );
        return undef;
    }

    if ( $report_response_error ) {
        my $err = $result_obj->getResponseError();
        if ( defined  $err )  {
            my $err_msg = "Error for client shell command '$self->{rpc_last_cmd}': '$err'";
            $self->err( $err_msg );
            return undef;
        }
    }

    return $result_obj;

}


=head2 do_rpc

Run command (remote procedure) on client shell. Return result_obj or undef (on error).

=cut

sub do_rpc {
    my ( $self, $cmd, $cmd_conf, $report_response_error ) = @_;
    $report_response_error = 1 unless defined $report_response_error;

    print "Running shell command '$cmd':\n" if $self->{ver} >= 5;
    $self->{rpc_last_cmd} = $cmd;

    my $result_obj = $self->{rpc}->run( $cmd, $cmd_conf );
    return $self->validate_result_obj( $result_obj, $report_response_error );
}


=head2 do_debug_rpc

Run command (remote procedure) on client shell in debug mode. Return exit code of SSH system command.

=cut

sub do_debug_rpc {
    my ( $self, $cmd, $cmd_conf ) = @_;

    print "Running shell command '$cmd' in debug mode:\n" if $self->{ver} >= 5;
    $self->{rpc_last_cmd} = $cmd;

    my $ret_code = $self->{rpc}->debug_run( $cmd, $cmd_conf );
    return $ret_code;
}


=head2 get_next_response

Run next response for running command started by do_rpc method.

=cut

sub get_next_response {
    my ( $self, $report_response_error ) = @_;
    $report_response_error = 1 unless defined $report_response_error;

    my $result_obj = $self->{rpc}->get_next_response();
    return $self->validate_result_obj( $result_obj, $report_response_error );
}


=head2 compare_test_name

Compare test name in given response. Return 1 on succeed or sets error.

=cut

sub compare_test_name {
    my ( $self, $response, $expected_test_name ) = @_;

    my $test_name = $response->{test};

    if ( (not defined $test_name) || $test_name ne $expected_test_name ) {
        my $msg_test_name = 'undef';
        $msg_test_name = "'$test_name'" if defined $test_name;
        return $self->err("Response should contain '$expected_test_name' as test name, but contains $msg_test_name.");
    }

    return 1;
}


=head2 test_noop_rpc

Run 'test_noop' remote procedure.

=cut

sub test_noop_rpc {
    my ( $self ) = @_;

    my $result_obj = $self->do_rpc( 'test_noop', undef, 1 );
    return 0 unless defined $result_obj;

    my $response = $result_obj->getResponse();
    return 0 unless $self->compare_test_name( $response, 'noop' );

    print "Command 'test_noop' succeeded.\n" if $self->{ver} >= 3;
    return 1;
}


=head2 compare_test_three_parts_response

Compare test name in given response. Return 1 on succeed or sets error.

=cut

sub compare_test_three_parts_response {
    my ( $self, $response, $expected_test_name, $expected_test_part_num ) = @_;

    return 0 unless $self->compare_test_name( $response, $expected_test_name );

    my $test_part_num = $response->{part_num};
    if ( (not defined $test_part_num) || $test_part_num ne $expected_test_part_num ) {
        $test_part_num = 'undef' unless defined $test_part_num;
        return $self->err("Attribute part_num in response should be $expected_test_part_num, but is $test_part_num.");
    }

    return 1;
}


=head2 test_three_parts_rpc

Run 'test_three_parts' remote procedure.

=cut

sub test_three_parts_rpc {
    my ( $self ) = @_;

    my $expected_test_part_num = 1;
    my $result_obj = $self->do_rpc( 'test_three_parts', undef, 1 );
    return 0 unless defined $result_obj;

    my $response = $result_obj->getResponse();
    return 0 unless $self->compare_test_three_parts_response( $response, 'three_parts', $expected_test_part_num );

    while ( $result_obj->isSuccess && !$result_obj->isLast ) {
        $expected_test_part_num++;
        $result_obj = $self->get_next_response( 1 );

        $response = $result_obj->getResponse();
        return 0 unless $self->compare_test_three_parts_response( $response, 'three_parts', $expected_test_part_num );
    }

    print "Command 'test_three_parts_rpc' succeeded.\n" if $self->{ver} >= 3;
    return 1;
}


=head1 SEE ALSO

L<SSH::RPC::PP::Client>, L<SysFink>.

=head1 LICENSE

This file is part of SysFink. See L<SysFink> license.

=cut


1;
