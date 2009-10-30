use strict;
use warnings;
use Test::More tests => 5;

use lib 'dist/_base/lib';
use lib 'dist/_base/libcpan';

BEGIN {
    use_ok 'Data::Dumper';

    # RPC shell (SysFink client, RPC server).
    # Based on
    # * SSH::RPC::Shell::PP::JSON
    # * SSH::RPC::Shell::PP::Base
    use_ok 'SSH::RPC::Shell::PP::TestCmds';

    # Base for commands.
    # Based on
    # * SSH::RPC::Shell::PP::Cmd::BaseJSON,
    # * SSH::RPC::Shell::PP::Cmd::Base
    use_ok 'SysFink::FileHash::Base';
    use_ok 'SysFink::ScanHost';
    # Based on
    # * SysFink::FileHash::Base
    use_ok 'SysFink::FileHash::BaseBinUtil';

    # This can't be tested without dist libraries.
    # Tested in t/dist/*.
    # use_ok 'Sysfink::SSH::RPC::Shell';

}
