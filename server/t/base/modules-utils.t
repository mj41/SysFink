use strict;
use warnings;
use Test::More tests => 3;

use lib 'lib';
use lib 'libext';

BEGIN {
    use_ok 'SysFink::Utils::Cmd';
    use_ok 'SysFink::Utils::Conf';
    use_ok 'SysFink::Utils::DB';
}
