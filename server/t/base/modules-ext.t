use strict;
use warnings;
use Test::More tests => 5;

use lib 'lib';
use lib 'libext';

BEGIN {
    use_ok 'DBD::SQLite';
    use_ok 'DBIx::Class::ViewMD';
    use_ok 'DBIx::Class';
    use_ok 'YAML::Any';
    use_ok 'Config::Multi';
}
