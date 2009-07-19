use strict;
use warnings;
use Test::More tests => 8;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);
use File::Spec::Functions;

use lib 'lib';
use lib 'libext';

use SysFink::Conf::SysFink;


my $conf_obj = SysFink::Conf::SysFink->new({
    conf_dir_path => catdir( $RealBin, '..', 'conf-data', 'tconf-2-sysfink' )
});

ok( $conf_obj->load_config(), 'load config' );

my $conf = $conf_obj->conf;

# some test cases

my @loaded_hosts = ( sort keys %$conf );
is_deeply( \@loaded_hosts, [ 'gorilla', 'lion' ], 'gorilla conf loaded ok' );

# gorilla

my @gorilla_keys = ( sort keys %{ $conf->{gorilla} } );
is_deeply( \@gorilla_keys, [ qw/hostname paths rpmpkg sendmail/ ], 'gorilla keys ok' );

is( $conf->{gorilla}->{hostname}, 'gorilla-sysfink-tconf-2.test.sysfink.org', 'gorilla hostname is ok' );
is_deeply( $conf->{gorilla}->{rpmpkg}, [ qw/samba samba-swat cdrecord/ ], 'gorilla rpmpkg ok' );

# lion

my @lion_keys = ( sort keys %{ $conf->{lion} } );
is_deeply( \@lion_keys, [ qw/dirpkg hostname paths rpmpkg sendmail/ ], 'lion keys ok' );

is_deeply( $conf->{lion}->{rpmpkg}, [ qw/kernel-2.6.18-8.1.8.main.el5.i686 samba dvd+rw-tools/ ], 'lion rpmpkg ok' );
is_deeply( $conf->{lion}->{sendmail}, [ qw/gorilla-sysfink-tconf-2-A@test.sysfink.org gorilla-sysfink-tconf-2-B@test.sysfink.org/ ], 'lion sendmail ok' );

#use Data::Dumper; print Dumper( $conf );
