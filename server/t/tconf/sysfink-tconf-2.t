use strict;
use warnings;
use Test::More tests => 14;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);
use File::Spec::Functions;

use lib 'lib';
use lib 'libext';

use SysFink::Conf::SysFink;


my $conf_obj = SysFink::Conf::SysFink->new({
    conf_dir_path => catdir( $RealBin, '..', 'tconf-data', 'tconf-2-sysfink' )
});

ok( $conf_obj->load_config(), 'load config' );

my $conf = $conf_obj->conf;

# some test cases

my @loaded_hosts = ( sort keys %$conf );
is_deeply( \@loaded_hosts, [ 'gorilla', 'lion', 'tapir' ], 'three confs loaded ok' );

# gorilla

my @gorilla_keys = ( sort keys %{ $conf->{gorilla}->{general} } );
is_deeply( \@gorilla_keys, [ qw/hostname inkey1 inkey2 paths rpmpkg sendmail/ ], 'gorilla keys ok' );

is( $conf->{gorilla}->{general}->{hostname}, 'gorilla-sysfink-tconf-2.test.sysfink.org', 'gorilla hostname is ok' );
is_deeply( $conf->{gorilla}->{general}->{rpmpkg}, [ qw/in-base in-base2 in-base3 samba samba-swat cdrecord/ ], 'gorilla rpmpkg ok' );

is( $conf->{gorilla}->{general}->{inkey1}, 'in-value', 'gorilla included conf with one value ok' );

is_deeply( $conf->{gorilla}->{general}->{inkey2}, [ qw/in-value1 in-value2/ ], 'gorilla included conf with many value ok' );

# lion

my @lion_keys = ( sort keys %{ $conf->{lion}->{general} } );
is_deeply( \@lion_keys, [ qw/dirpkg hostname paths rpmpkg sendmail/ ], 'lion keys ok' );

is_deeply( $conf->{lion}->{general}->{rpmpkg}, [ qw/kernel-2.6.18-8.1.8.main.el5.i686 samba dvd+rw-tools/ ], 'lion rpmpkg ok' );
is_deeply( $conf->{lion}->{general}->{sendmail}, [ qw/gorilla-sysfink-tconf-2-A@test.sysfink.org gorilla-sysfink-tconf-2-B@test.sysfink.org/ ], 'lion sendmail ok' );


# tapir

# use Data::Dumper; print Dumper( $conf );

my @tapir_general_keys = ( sort keys %{ $conf->{tapir}->{general} } );
is_deeply( \@tapir_general_keys, [ qw/hostname inkey1 inkey2 key3 key4-gen rpmpkg sendmail/ ], 'tapir general keys ok' );
is_deeply( $conf->{tapir}->{general}->{inkey2}, [ qw/in-value-gen-1 in-value1 in-value2 in-value-gen-2/ ], 'tapir general inkey2 ok' );

my @tapir_secA_keys = ( sort keys %{ $conf->{tapir}->{sec_a} } );
is_deeply( \@tapir_secA_keys, [ qw/inkey1 inkey2 key1-sec key3 key4-sec rpmpkg/ ], 'tapir sec_a keys ok' );
is_deeply( $conf->{tapir}->{sec_a}->{inkey2}, [ qw/in-value-sec_a-1 in-value1 in-value2 in-value-sec_a-2/ ], 'tapir sec_a inkey2 ok' );

