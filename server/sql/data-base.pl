use strict;
use warnings;

use lib 'lib';
use lib 'libext';
use SysFink::Utils::Conf qw(load_conf_multi);
use SysFink::Utils::DB qw(get_connected_schema);


my $conf_fp = 'conf';
my $conf = load_conf_multi( $conf_fp, 'db' );
my $schema = get_connected_schema( $conf->{db} );

$schema->storage->txn_begin;


# table: rev_status
$schema->resultset('rev_status')->delete_all();

$schema->resultset('rev_status')->populate([
    [ qw/ rev_status_id name legend / ],
    [ 1,  'ok (my)',  'Ok. I did it.',                  ],
    [ 2,  'ok',       'Ok. I didn\'t do it.',           ],
    [ 3,  'unknown',  'I don\'t know. ',                ],
    [ 4,  'error',    'Error. Somebody should fix it.', ],
    [ 5,  'alert',    'Security alert. Fix it soon.',   ],
]);

$schema->storage->txn_commit;
