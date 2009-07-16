use strict;
use warnings;
use Test::More tests => 5;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);
use File::Spec::Functions;

use lib 'lib';
use lib 'libext';

use SysFink::Conf::SysFink;


my $conf_obj = SysFink::Conf::SysFink->new({
    conf_dir_path => catdir( $RealBin, '..', 'conf-data', 'sysfink-tconf-1' )
});

isa_ok( $conf_obj, 'SysFink::Conf::SysFink' );
isa_ok( $conf_obj, 'SysFink::Conf' );

like( $conf_obj->conf_dir_path, qr/sysfink-tconf/, 'Path returned from conf_dir_path seems ok' );

ok( $conf_obj->load_config(), 'load config' );

my $conf = $conf_obj->conf;
my @loaded_hosts = ( sort keys %$conf );

is_deeply( \@loaded_hosts, [ 'gorilla' ], 'gorilla conf loaded ok' );

# use Data::Dumper; print Dumper( $conf ); exit;
