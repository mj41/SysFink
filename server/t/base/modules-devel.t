use strict;
use warnings;
use Test::More tests => 2;

use lib 'lib';
use lib 'libext';

BEGIN {
    use_ok 'SQL::Translator';
    use_ok 'SQL::Translator::Producer::DBIx::Class::FileMJ';
}
