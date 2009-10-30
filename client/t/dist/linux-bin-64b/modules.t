use strict;
use warnings;
use Test::More tests => 2;

# linux-bin-64b

use lib 'dist/_base/lib';
use lib 'dist/_base/libcpan';

use lib 'dist/linux-bin-64b/libdist';

BEGIN {
    use_ok 'SysFink::FileHash';
    use_ok 'SysFink::SSH::RPC::Shell';
}
