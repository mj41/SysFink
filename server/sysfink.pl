#!/usr/bin/perl

use strict;
use warnings;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);
use File::Spec::Functions;
use Data::Dumper;

use Net::OpenSSH;


my $host = $ARGV[0] || 'tapir1.ro.vutbr.cz';
my $user = $ARGV[1] || 'root';

my $ssh = Net::OpenSSH->new( $host, user => $user );
$ssh->error and die "Couldn't establish SSH connection: ". $ssh->error;

my ($out, $err) = $ssh->capture2('hostname');
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

sub run_ssh_cmd {
    my ( $ssh, $cmd ) = @_;

    my ($out, $err) = $ssh->capture2( $cmd );
    if ( $out || $err ) {
        print "out: '$out', err:'$err'\n";
    }
}

my $client_dir = '/home/sysfink-client';
run_ssh_cmd( $ssh, "rm -rf $client_dir" );
run_ssh_cmd( $ssh, "mkdir $client_dir" );

my $client_src_name = 'sysfink-client.pl';
my $client_src = catfile('..','client', $client_src_name);
my $client_src_dest_dir = catdir($client_dir);
$ssh->scp_put($client_src, $client_src_dest_dir);

my $client_src_dest_fp = catfile( $client_src_dest_dir, $client_src_name );
run_ssh_cmd( $ssh, "/usr/bin/perl $client_src_dest_fp" );

undef $ssh;
