use strict;
use warnings;

use utf8;
use DateTime;

use lib 'lib';
use lib 'libext';
use SysFink::Utils::Conf qw(load_conf_multi);
use SysFink::Utils::DB qw(get_connected_schema);


my $conf_fp = 'conf';
my $conf = load_conf_multi( $conf_fp, 'db' );
my $schema = get_connected_schema( $conf->{db} );

my $now = DateTime->now;

$schema->storage->txn_begin;


# table: user
$schema->resultset('user')->delete_all();

$schema->resultset('user')->populate([
    [ qw/ user_id login passwd who first_name last_name active created / ],
    [ 1, 'poder', 'abc', undef,  'Tomáš',  'Podermański', 1, $now, ],
    [ 2, 'mj41',  'mno', 'r-mj', 'Michal', 'Jurosz',      1, $now, ],
]);


# table: machine
$schema->resultset('machine')->delete_all();

$schema->resultset('machine')->populate([
    [ qw/  machine_id name desc ip active / ],
    [ 1, 'tapir1.ro.vutbr.cz', undef, '147.229.191.11', 1, ],
]);

$schema->storage->txn_commit;
