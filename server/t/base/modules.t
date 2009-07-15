use strict;
use warnings;
use Test::More tests => 3;

use lib 'lib';
use lib 'libext';

BEGIN {
    use_ok 'SysFink';
    use_ok 'SysFink::Server';

    # only these one needed
    use_ok 'SysFink::DB::SchemaAdd';

    # utils tests are inside modules-utils.t
}
