use strict;
use warnings;
use Test::More tests => 8;

use lib 'lib';
use lib 'libext';

BEGIN {
    use_ok 'Carp';
    use_ok 'File::Spec::Functions';

    use_ok 'Net::OpenSSH';

    # config
    use_ok 'YAML::Any';
    use_ok 'Config::Multi';

    # DB
    use_ok 'DBIx::Class';

    # DBD modules
    use_ok 'DBD::SQLite';

    # TapTinder imported
    use_ok 'DBIx::Class::ViewMD';
}
