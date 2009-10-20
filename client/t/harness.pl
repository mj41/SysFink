#!perl

use strict;
use warnings;
use FindBin qw($RealBin);

use lib "$RealBin/../../../sysfink-cpan/lib";

use TAP::Harness;

my @default_tests = (
    't/*.t',
    't/base/*',
);
my @tests = map { glob($_) } (@ARGV ? @ARGV : @default_tests);

my $harness = TAP::Harness->new({
    verbosity => $ENV{HARNESS_VERBOSE},
    merge     => 0,
    jobs      => $ENV{TEST_JOBS} || 1,
    directives => 1,
});
my $results = $harness->runtests(@tests);

exit ( $results->all_passed() ? 0 : 1 );
