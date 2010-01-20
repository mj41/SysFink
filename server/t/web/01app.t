#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;

use lib 'lib';
use lib 'libext';

BEGIN { use_ok 'Catalyst::Test', 'SysFink::Web' }

ok( request('/')->is_success, 'Request should succeed' );
