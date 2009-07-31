use strict;
use warnings;

# Testing SSH connect.
# You should have ssh keys configured. This is test without password.

use Net::SSH::Expect;

my $host = $ARGV[0] || 'tapir1.ro.vutbr.cz';
my $user = $ARGV[1] || 'root';

my $ssh = Net::SSH::Expect->new(
    host => $host,
    user => $user,
    raw_pty => 1,
    no_terminal => 1
);

$ssh->run_ssh() or die "SSH process couldn't start: $!";
#$ssh->exec("stty raw -echo");

my $hostname = $ssh->exec('hostname');
chomp($hostname);

print "got hostname '$hostname' - ";
if ( $hostname eq $host ) {
    print "OK";
} else {
    print "ERROR (expected '$host')"
}
print "\n";

$ssh->close();
