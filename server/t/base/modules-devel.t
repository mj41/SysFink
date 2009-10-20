use strict;
use warnings;
use Test::More;

use lib 'lib';
use lib 'libext';

BEGIN {
    if ( $ENV{SYSFINK_DEVEL} ) {
        plan tests => 2;
    } else {
        plan skip_all => 'Mandatory only for development.'
    }

    use_ok 'SQL::Translator';
    use_ok 'SQL::Translator::Producer::DBIx::Class::FileMJ';
    done_testing();
}
