#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use lib 'lib';
use lib 'libext';

eval "use Test::Pod::Coverage 1.04";
plan skip_all => 'Test::Pod::Coverage 1.04 required' if $@;
plan skip_all => 'set TEST_POD to enable this test' unless $ENV{TEST_POD};

all_pod_coverage_ok();