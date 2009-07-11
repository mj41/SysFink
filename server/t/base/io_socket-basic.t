#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 9;
use Test::Fork;

use lib 'lib';

BEGIN {
    use_ok 'IO::Socket';
}

my $listen = IO::Socket::INET->new(
    Listen => 2,
    Proto => 'tcp',
    Timeout => 15,
) or die "$!";

is( ref $listen, 'IO::Socket::INET', 'IO::Socket::INET->new ok' );

my $port = $listen->sockport;

my $pid = fork_ok( 3, sub {
    # child process
    my $sock = IO::Socket::INET->new(
        PeerPort => $port,
        Proto => 'tcp',
        PeerAddr => 'localhost'
    )
    || IO::Socket::INET->new(
        PeerPort => $port,
        Proto => 'tcp',
        PeerAddr => '127.0.0.1'
    )
    or die "$! (maybe your system does not have a localhost at all, 'localhost' or 127.0.0.1)";
    ok( $sock, "sock on child created ok");

    $sock->autoflush(1);

    print $sock "child to parent message\n";

    # will print 'ok 4 - message from parent to child'
    my $line = $sock->getline();
    is( $line, "message from parent to child\n", 'parent to child message received ok'  );

    $sock->close;

    pass( "child done ok" );
});


# parent process
my $sock = $listen->accept() or die "accept failed: $!";
ok( $sock, "sock on parent created ok");

$sock->autoflush(1);
my $line = $sock->getline();
is( $line, "child to parent message\n", 'child to parent message received ok' );

print $sock "message from parent to child\n";

$sock->close;

waitpid($pid,0);

pass( "parent done ok" );
