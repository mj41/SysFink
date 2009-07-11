#!perl

use strict;
use warnings;
use lib qw( lib );

my @default_tests = (
    't/*.t',
    't/base/*',
);
my @tests = map { glob($_) } (@ARGV ? @ARGV : @default_tests);

use TAP::Harness;

my $harness = TAP::Harness->new({
    verbosity => $ENV{HARNESS_VERBOSE},
    merge     => 0,
    jobs      => $ENV{TEST_JOBS} || 1,
    directives => 1,
});
my $results = $harness->runtests(@tests);

exit ( $results->all_passed() ? 0 : 1 );
