#!/usr/bin/perl

use strict;
use warnings;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);
use File::Spec::Functions;
use Data::Dumper;

use Net::OpenSSH;

use lib 'lib';
use SSH::RPC::PP::Client;


my $ver = 5;
my $host = $ARGV[0] || 'tapir1.ro.vutbr.cz';
my $user = $ARGV[1] || 'root';
my $dist_type = 'linux-bin-64b';

# test2
#$dist_type = 'linux-perl-md5';

# test3 - irix test
if ( 0 ) {
    $host = 'efis.ro.vutbr.cz';
    $dist_type = 'irix-bin-64b';
}


sub check_user {
    my ( $user ) = @_;
    return 0 unless $user;
    return 0 if $user =~ /\s/;
    return 0 if $user =~ /[\.\:\;\\\/]/;
    return 1;
}


sub user_to_clientdir {
    my ( $user ) = @_;
    return '/root/sysfink-client' if $user eq 'root';
    return '/home/' . $user . '/sysfink-client';
}


sub run_ssh_cmd {
    my ( $ssh, $cmd ) = @_;

    my ( $out, $err ) = $ssh->capture2( $cmd );
    if ( $out || $err ) {
        print "out: '$out', err:'$err'\n";
    }
    return ( $out, $err );
}


sub ls_output_contains_dir {
    my ( $out ) = @_;
    
    chomp($out);
    my @lines = split( /\n/, $out );
    foreach my $line ( @lines ) {
        return 1 if $line =~ /^\s*d/;
    }
    return 0;
}




croak "Bad user name '$user'." unless check_user( $user );

my $ssh = Net::OpenSSH->new( $host, user => $user, master_opts => [ '-T'] );
$ssh->error and die "Couldn't establish SSH connection: ". $ssh->error;

my ($out, $err);
($out, $err) = $ssh->capture2('hostname');
$ssh->error and die "remote 'hostname' command failed: " . $ssh->error;

my $hostname = $out;
chomp($hostname);

print "hostname '$host' connected ";
if ( $hostname eq $host ) {
    print "ok\n";
} else {
    print "ERROR (got '$hostname')\n";
    exit 0;
}

my $client_dir = user_to_clientdir( $user );
print "client_dir: '$client_dir'\n" if $ver >= 2;

($out, $err) = run_ssh_cmd( $ssh, "ls -l $client_dir" );

if ( $err =~ /No such file or directory/i ) {
    print "Directory '$client_dir' doesn't exists on host.\n" if $ver >= 3;
} else {
    if ( ls_output_contains_dir($out) ) {
        croak "Directory '$client_dir' on '$host' contains some directories.\nCmd 'ls -l' output is\n$out.\n";
    }
    # ToDo - je to jiz dost bezpecne?
    run_ssh_cmd( $ssh, "rm -rf $client_dir" );
}

run_ssh_cmd( $ssh, "mkdir $client_dir" );

my $client_src_dir = catdir( $RealBin, '..', 'client' );

my $client_src_name = 'sysfink-client.pl';
my $client_src_fpath = catfile( $client_src_dir, $client_src_name );
my $client_src_dest_dir = catdir( $client_dir );
$ssh->scp_put( $client_src_fpath, $client_src_dest_dir );

my $dist_src_dir;

$dist_src_dir = catdir( $client_src_dir, 'dist', '_base' );
foreach my $dist_fpath ( glob("$dist_src_dir/*") ) {
    print "Transfering '$dist_fpath' to client.\n" if $ver >= 4;
    $ssh->scp_put( $dist_fpath, $client_src_dest_dir );
}

$dist_src_dir = catdir( $client_src_dir, 'dist', $dist_type );
foreach my $dist_fpath ( glob("$dist_src_dir/*") ) {
    print "Transfering '$dist_fpath' to client.\n" if $ver >= 4;
    $ssh->scp_put( $dist_fpath, $client_src_dest_dir );
}


run_ssh_cmd( $ssh, "ls $client_src_dest_dir" );

my $client_src_dest_fp = catfile( $client_src_dest_dir, $client_src_name );

my $client_start_cmd = "/usr/bin/perl $client_src_dest_fp 5";

# ToDo - use only one Perl process
#my ( $in_pipe, $out_pipe, undef, $pid ) = $ssh->open_ex(
#    {
#        stdin_pipe => 1,
#        stdout_pipe => 1 
#   },
#    @cmd
#);


my $rpc = SSH::RPC::PP::Client->new( $ssh, $client_start_cmd );

my $result;

$result = $rpc->run( 'noop', $client_src_dest_fp );
if ( $result->isSuccess ) {
    print "ok: " . Dumper($result->getResponse) . "\n";
} else {
    carp "err: " . $result->getError;
}

my $file_to_hash = catfile( $client_src_dest_dir, 'SysFinkFileHashBase.pm' );
$result = $rpc->run( 'hash_file', $file_to_hash );
if ( $result->isSuccess ) {
    print "ok: " . Dumper($result->getResponse) . "\n";
} else {
    carp "err: " . $result->getError;
}

$result = $rpc->run( 'hash_type' );
if ( $result->isSuccess ) {
    print "ok: " . Dumper($result->getResponse) . "\n";
} else {
    carp "err: " . $result->getError;
}

$result = $rpc->run( 'hash_type_desc' );
if ( $result->isSuccess ) {
    print "ok: " . Dumper($result->getResponse) . "\n";
} else {
    carp "err: " . $result->getError;
}


undef $ssh;
