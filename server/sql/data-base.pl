use strict;
use warnings;

use lib 'lib';
use lib 'libext';
use SysFink::Utils::Conf qw(load_conf_multi);
use SysFink::Utils::DB qw(get_connected_schema);


my $conf_fp = 'conf/sysfink.conf';
my $conf = load_conf_multi( $conf_fp, 'db' );
my $schema = get_connected_schema( $conf->{db} );

$schema->storage->txn_begin;


# table: aud_status
$schema->resultset('aud_status')->delete_all();

$schema->resultset('aud_status')->populate([
    [ qw/ aud_status_id name descr / ],
    [ 1,  'ok (my)',  'Ok. I did it.',                  ],
    [ 2,  'ok',       'Ok. I didn\'t do it.',           ],
    [ 3,  'unknown',  'I don\'t know. ',                ],
    [ 4,  'error',    'Error. Somebody should fix it.', ],
    [ 5,  'alert',    'Security alert. Fix it soon.',   ],
]);


# table: pkg_type
$schema->resultset('pkg_type')->delete_all();

$schema->resultset('pkg_type')->populate([
    [ qw/ pkg_type_id name descr / ],
    [ 1, 'dir', 'Items/idata in directory on server filesystem. Structure starts inside pkgdir (config parameter).', ],
    [ 2, 'tar', 'Packed directory. Same as dir, but packed to tar file format or to any compressed tar.', ],
    [ 3, 'rpm', 'Items/idata in RPM (a software package file format).', ],
    [ 4, 'deb', 'Items/idata in DEB (a software package format used by the Debian project).', ],
]);


$schema->storage->txn_commit;
