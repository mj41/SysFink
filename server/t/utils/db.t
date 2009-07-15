use strict;
use warnings;
use Test::More tests => 2;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);
use File::Spec::Functions;

use lib 'lib';
use lib 'libext';

use SysFink::Utils::Conf qw(load_conf_multi);
use SysFink::Utils::DB qw(get_connected_schema);


my $conf_fp = 'conf';
my $conf = load_conf_multi( $conf_fp, 'db' );
ok( $conf->{db}, 'some configuration for database loaded');

my $schema = get_connected_schema( $conf->{db} );

my $rs = $schema->resultset('machine')->search( {}, {} );
ok( $rs->count, 'rs->count on build should succeed' );
