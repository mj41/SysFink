#!/usr/bin/perl

use strict;
use warnings;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);
use File::Spec::Functions;
use Data::Dumper;

use Net::OpenSSH;

use lib 'lib';
use lib 'libext';

use SSH::RPC::PP::Client;
use SysFink::Conf::SysFink;
use SysFink::Utils::Conf qw(load_conf_multi);
use SysFink::Utils::DB qw(get_connected_schema);


my $ver = 5;
my $machine = $ARGV[0] || 'tapir1';
my $user = $ARGV[1] || 'root';
my $dist_type = 'linux-bin-64b';
# test2
#$dist_type = 'linux-perl-md5';

my $debugging_on_client = 1;

my $conf_fp;


$conf_fp = catdir( $RealBin, 'conf' ) unless defined $conf_fp;
croak "Conf dir '$conf_fp' not found." unless -d $conf_fp;

my $conf = load_conf_multi( $conf_fp, 'db' );
my $schema = get_connected_schema( $conf->{db} );


sub load_general_conf {
    my ( $schema, $machine ) = @_;

    my $mconf_rs = $schema->resultset('mconf_sec_kv')->search(
        {
            'machine_id.name' => $machine,
            'mconf_sec_id.name' => 'general',
        },
        {
            'join' => { 'mconf_sec_id' => 'machine_id' },
            'select' => [ 'key', 'value', 'num' ],
            'order_by' => [ 'key', 'num' ],
        },
    );


    my $data = {};
    while (my $row_obj = $mconf_rs->next) {
        my %row = ( $row_obj->get_columns() );
        my $key = $row{key};
        my $new_value = $row{value};
        if ( exists $data->{$key} ) {
            if ( ref $data->{$key} eq 'ARRAY' ) {
                my $prev_val = $data->{$key};
                push @{$data->{$key}}, $new_value;
            } else {
                my $prev_val = $data->{$key};
                $data->{$key} = [ $prev_val, $new_value ];
            }
        } else {
            $data->{$key} = $new_value;
        }
    }

    return $data;
}


my $general_conf = load_general_conf( $schema, $machine );
print Dumper( $general_conf );

my $host = $general_conf->{hostname};

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

if ( $debugging_on_client ) {
    my $client_src_test_name = 'sysfink-client-test.pl';
    my $client_src_test_fpath = catfile( $client_src_dir, $client_src_test_name );
    $ssh->scp_put( $client_src_test_fpath, $client_src_dest_dir );
}

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

my $client_start_cmd = "nice -n 10 /usr/bin/perl $client_src_dest_fp 5";

# ToDo - use only one Perl process
#my ( $in_pipe, $out_pipe, undef, $pid ) = $ssh->open_ex(
#    {
#        stdin_pipe => 1,
#        stdout_pipe => 1
#   },
#    @cmd
#);


my $rpc = SSH::RPC::PP::Client->new( $ssh, $client_start_cmd );

my $result_obj;

$result_obj = $rpc->run( 'noop', $client_src_dest_fp );
$result_obj->dump();


my $file_to_hash = catfile( $client_src_dest_dir, 'SysFinkFileHashBase.pm' );
$result_obj = $rpc->run( 'hash_file', $file_to_hash );
$result_obj->dump();


$result_obj = $rpc->run( 'hash_type' );
$result_obj->dump();

$result_obj = $rpc->run( 'hash_type_desc' );
$result_obj->dump();


my %default_root_flags = SysFink::Conf::SysFink->get_default_root_flags();
my $scan_conf = {
    'paths' => $general_conf->{paths},
    'default_root_flags' => \%default_root_flags,
    'debug' => 1,
};

if ( $debugging_on_client ) {
    print "Client debugging:\n";
    my $ret_code = $rpc->debug_run( 'scan_host', $scan_conf );

} else {
    print "Client prepared for debugging.\n";
    $result_obj = $rpc->run( 'scan_host', $scan_conf );
    $result_obj->dump();
}


undef $ssh;
