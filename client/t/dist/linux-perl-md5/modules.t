use strict;
use warnings;
use Test::More tests => 2;

# linux-perl-md5

use lib 'dist/_base/lib';
use lib 'dist/_base/libcpan';

use lib 'dist/linux-perl-md5/libdist';

BEGIN {
    use_ok 'SysFink::FileHash';
    use_ok 'SysFink::SSH::RPC::Shell';
}
