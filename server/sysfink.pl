#!/usr/bin/perl

use strict;
use warnings;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);

use Getopt::Long;
use Pod::Usage;

use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/libext";

use SysFink::Server;

sub main {

    my $help = 0;

    my $options = {
        ver => 2,
        cmd => undef,
        host => undef,
        section => undef,

        no_db => 0,
        ssh_user => undef,
        host_dist_type => undef,
   };

    my $options_ok = GetOptions(
        'help|h|?' => \$help,

        'ver|v=i' => \$options->{'ver'},
        'cmd=s' => \$options->{'cmd'},
        'host=s' => \$options->{'host'},
        'section=s' => \$options->{'section'},

        'no_db' => \$options->{'no_db'},
        'ssh_user=s' => \$options->{'ssh_user'},
        'host_dist_type=s' => \$options->{'host_dist_type'},
    );

    if ( $help || !$options_ok ) {
        pod2usage(1);
        return 0 unless $options_ok;
        return 1;
    }

    my $server_obj = SysFink::Server->new();
    my $ret_code = $server_obj->run( $options );
    print STDERR $server_obj->err() . "\n" unless $ret_code;
    return $ret_code;
}


my $ret_code = main();
# 0 is ok, 1 is error. See Unix style exit codes.
exit(1) unless $ret_code;
exit(0);


=head1 NAME

sysfink.pl - Run SysFink server commands.

=head1 SYNOPSIS

perl sysfink.pl [options]

 Options:
    --help ... Prints this help informations.
    
    --ver=$NUM ... Verbosity level 0..10 Default 2.

    --cmd=? ... See availible commands below:

    --cmd=test_hostname
        For testing purpose. Run 'hostname' command on client and compare it to --host.
        Return nothing (on success) or error message.
        Also required --host.
        Also require --ssh_user if --no_db given.

    --cmd=check_client_dir
        Run 'ls -l' command on client and validate output.
        Return nothing (on success) or error message.
        Also required --host.
        Also require --ssh_user if --no_db given.

    --cmd=remove_client_dir
        Remove SysFink directory on client. Call 'check_client_dir' to ensure that anything else will be removed.
        Return nothing (on success) or error message.
        Also required --host.
        Also require --ssh_user if --no_db given.

    --cmd=renew_client_dir
        Remove old and put new client source code (scripts and libraries) on client machine. Call 'remove_client_dir'
        (and 'check_client_dir') and then put new code.
        Return nothing (on success) or error message.
        Also required --host.
        Also require --ssh_user and --host_dist_type if --no_db given.

    --cmd=test_noop_rpc
        Try to run 'noop' test command on client shell over RPC. You should run 'renew_client_dir' cmd to transfer
        RPC source code to client first.
        Return nothing (on success) or error message.
        Also required --host.
        Also require --ssh_user if --no_db given.

    --cmd=test_three_parts_rpc
        Try to run 'tree_parts' test command on client shell over RPC. You should run 'renew_client_dir' cmd to transfer
        RPC source code to client first.
        Return nothing (on success) or error message.
        Also required --host.
        Also require --ssh_user if --no_db given.

    --cmd=scan_test
        Run scan_test command on given host. Load config from database, run scan comand in debug mode (online debug
        output) and do not change anything inside DB.
        Return nothing (on success) or error message.
        Also required --host.
        Also require --ssh_user if --no_db given.

    --cmd=scan
        Run scan on given host. Load config from database and save results there.
        Return nothing (on success) or error message.
        Also required --host.
        Also require --ssh_user if --no_db given.

    --host ... Full hostname of client for SSH connect.

    --section ... Configuration section name to use.

    --no_db 
        Do not connect to DB. Parameters like ssh_user or host_dist_type are required
        for some commands.
    
    --ssh_user ... User name for SSH connect.

    --host_dist_type ... Distribution type e.g. irix-bin-64b, linux-perl-md5, ...

=head1 DESCRIPTION

B<This program> run SysFink server command.

=cut
