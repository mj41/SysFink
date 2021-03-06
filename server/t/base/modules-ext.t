use strict;
use warnings;
use Test::More tests => 10;

use lib 'lib';
use lib 'libext';

BEGIN {
    use_ok 'Carp';
    use_ok 'File::Spec::Functions';

    # config
    use_ok 'Config::General';

    # Server
    use_ok 'Net::OpenSSH';
    use_ok 'Data::Dumper';
    use_ok 'DateTime';
    use_ok 'Data::Compare';

    # DB
    use_ok 'DBIx::Class';

    # DBD modules
    use_ok 'DBD::SQLite';

    # TapTinder imported
    use_ok 'DBIx::Class::CWebMagic';
}
