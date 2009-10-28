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
        user => undef,
        host => undef,
        host_dist_type => undef,
   };

    my $options_ok = GetOptions(
        'help|h|?' => \$help,
        'ver|v=i' => \$options->{'ver'},

        'cmd=s' => \$options->{'cmd'},

        'user=s' => \$options->{'user'},
        'host=s' => \$options->{'host'},
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
    --help
    --ver=$NUM .. Verbosity level 0..5. Default 2.

    --cmd

    --cmd=test_hostname
        For testing purpose. Run hostname command on client and compare it to --host.
        Return nothing (on success) or error message.
        Also required: --host, --user.

    --cmd=check_client_dir_content
        Run 'ls -l' command on client and validate output.
        Return nothing (on success) or error message.
        Also required: --host, --user.

    --cmd=empty_client_dir
        Same as 'check_client_dir_content' command but also erase all content of SysFink directory
        on client.
        Return nothing (on success) or error message.
        Also required: --host, --user.

    --cmd=put_client_src_code
        Put client source code (scripts and libraries) on client machine. You should call 'empty_client_dir'
        first probably.
        Return nothing (on success) or error message.
        Also required: --host, --user.
        Also used: --host_dist_type.

    --user .. User name for SSH connect.

    --host .. Full hostname of client for SSH connect.

    --host_dist_type .. Distribution type for hashing (linux-bin-64b, linux-bin-64b, ... ). See client 'dist'
                        directory content.


=head1 DESCRIPTION

B<This program> run SysFink server command.

=cut
