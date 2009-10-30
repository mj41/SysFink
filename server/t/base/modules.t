use strict;
use warnings;
use Test::More tests => 10;

use lib 'lib';
use lib 'libext';

BEGIN {
    use_ok 'SysFink';

    # Schema modules - only these one needed
    use_ok 'SysFink::DB::SchemaAdd';

    # Based on
    # * SysFink::Conf
    use_ok 'SysFink::Conf::SysFink';
    use_ok 'SysFink::Conf::DBIC';

    use_ok 'SSH::RPC::PP::Result';

    # RPC (SysFink server, RPC client).
    # Based on
    # * SSH::RPC::PP::Client
    use_ok 'SysFink::Server::SSHRPCClient';

    # Utils
    use_ok 'SysFink::Utils::Cmd';
    use_ok 'SysFink::Utils::Conf';
    use_ok 'SysFink::Utils::DB';

    # Require some of modules above.
    use_ok 'SysFink::Server';
}
