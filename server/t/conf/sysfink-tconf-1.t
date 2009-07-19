use strict;
use warnings;
use Test::More tests => 4;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);
use File::Spec::Functions;

use lib 'lib';
use lib 'libext';

use SysFink::Conf::SysFink;


my $conf_obj = SysFink::Conf::SysFink->new({
    conf_dir_path => catdir( $RealBin, '..', 'conf-data', 'tconf-1-sysfink' )
});

like( $conf_obj->conf_dir_path, qr/tconf\-1\-sysfink/, 'Path returned from conf_dir_path seems ok' );

ok( $conf_obj->load_config(), 'load config' );

my $conf = $conf_obj->conf;

my @loaded_hosts = ( sort keys %$conf );
is_deeply( \@loaded_hosts, [ 'gorilla', 'lion' ], 'gorilla and lion conf loaded ok' );

#use Data::Dumper; print Dumper( $conf );
is_deeply(
    $conf,
    {
        'gorilla' => {
            'comment' => 'my text comment',
            'parts' => [
                'part1',
                'part2',
                'part 3',
                'part 4'
            ],
            'hostname' => 'gorilla-sysfink-tconf-1.test.sysfink.org',
            'rpmpkg' => [
                'samba',
                'cdrecord',
            ],
        },
        'lion' => {
            'comment' => 'my lion text comment',
            'hostname' => 'lion-sysfink-tconf-1.test.sysfink.org',
        },
    },
    'loaded conf is ok'
);
