use strict;
use warnings;
use Test::More tests => 2;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);
use File::Spec::Functions;

use lib 't/lib';

use lib 'lib';
use lib 'libext';
use lib 'dist/_base';

use SysFinkRunObjBase; # SysFink::ScanHost
use SysFinkScanHost; # SysFink::ScanHost
use SysFinkScanHostTest; # SysFink::ScanHostTest
use SysFinkFileHashTest; # SysFink::FileHashTest

#sub scan_recurse {
#    my ( $self, $loaded_items, $dir_name, $parent_flags ) = @_;


my $scanhosttest_obj_conf = [
    '/etc/',
    '/etc/passwd',
    '/home/',
    '/tmp/',
    '/root/',
    [ '/root/myfile', { mode => 16876, }, ],
];

my $shared_data = {};
my $hash_obj = SysFink::FileHashTest->new();
my $scan_obj = SysFink::ScanHostTest->new( $scanhosttest_obj_conf, $shared_data, $hash_obj );

my $default_flags = {
   'S' => '+',
   'B' => '-',
   'H' => '+',
   'M' => '+',
   'D' => '+',
   'G' => '+',
   'L' => '+',
   'U' => '+',
   '5' => '+'
};
my $paths = [
    '/*', $default_flags,
];

my $scan_conf = {
    'paths' => $paths,
    'debug_out' => 1,
};

my $ret_code = $scan_obj->scan( $scan_conf );
my %result = $scan_obj->get_result();

use Data::Dumper; print Dumper( \%result );
