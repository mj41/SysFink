use strict;
use warnings;
use Test::More tests => 2;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);
use File::Spec::Functions;

use lib 'lib';
use lib 'libext';

use SysFink::Conf::SysFink;


my $conf_obj = SysFink::Conf::SysFink->new({
    conf_dir_path => catdir( $RealBin, '..', 'conf-data', 'tconf-3-sysfink' )
});

ok( $conf_obj->load_config(), 'load config' );

my $conf = $conf_obj->conf;


my $expected_paths = [
    '[-5-B-D-G-H-L-M-S-U]',
    '/[-5-B-D]',
    '/dev[+5+B+D+G]',
    '/dev/[-5-B-D-G]',
    '/dev/bar[-5-B+D-G+H+L+M+S+U]',
    '/dev/foo[-5-B+D+G-H-L-M-S-U]',
    '/dev/some/[+5+B]',
    '/home/*[+5-B+D+G+H+L+M+S+U]',
    '/var/[-5-B-D-G-H-L-M-S-U]'
];

#use Data::Dumper; print Dumper( $conf ); print Dumper( $expected_paths ); exit;

is_deeply( $conf->{gorilla}->{general}->{paths}, $expected_paths, 'gorilla paths are ok' );

