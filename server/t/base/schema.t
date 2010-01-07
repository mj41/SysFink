use strict;
use warnings;
use Test::More tests => 2;

use YAML::Any qw/LoadFile/;

use lib 'lib';
use lib 'libext';

use SysFink::DB::SchemaAdd;


my $fpath = './conf/web_db.yml';
my $conf = LoadFile($fpath);

my %dbi_params = ();
my $schema = SysFink::DB::Schema->connect(
    $conf->{db}->{dbi_dsn},
    $conf->{db}->{user},
    $conf->{db}->{pass},
    \%dbi_params
);

ok( $schema, 'Connect should succeed' );

#export DBIC_TRACE=1
#use Data::Dumper; print Dumper( $schema );

my $rs = $schema->resultset('aud_status')->search( {}, {} );
ok( $rs->count, 'rs->count on aud_status table should succeed' );
