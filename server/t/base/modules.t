use strict;
use warnings;
use Test::More tests => 5;

use lib 'lib';
use lib 'libext';

BEGIN {
    use_ok 'SysFink';
    use_ok 'SysFink::Server';

    # schema modules - only these one needed
    use_ok 'SysFink::DB::SchemaAdd';

    # conf modules
    use_ok 'SysFink::Conf';
    use_ok 'SysFink::Conf::SysFink';

    # utils tests are inside modules-utils.t
}
