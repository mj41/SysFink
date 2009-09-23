package main;

use strict;
use FindBin qw($RealBin);

use lib "$RealBin/libcpan";
use lib "$RealBin/lib";
use lib "$RealBin/libdist";
use SysFink::SSH::RPC::Shell;


my $ver = $ARGV[0] || 2;

my $client = Sysfink::SSH::RPC::Shell->new( $ver, $RealBin );
$client->run();
