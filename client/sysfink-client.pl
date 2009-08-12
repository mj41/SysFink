package main;

use strict;
use FindBin qw($RealBin);

use lib "$RealBin/.";
use SSHRPCShellPPBase; # SSH::RPC::Shell::PP::Base
use SSHRPCShellPPJSON; # SSH::RPC::Shell::PP::JSON
use SysFinkSSHRPCShell; # SysFink::SSH::RPC::Shell


my $ver = $ARGV[0] || 2;

my $client = Sysfink::SSH::RPC::Shell->new( $ver, $RealBin );
$client->run();
