use strict;
use warnings;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);
use File::Spec::Functions;
use Data::Dumper;

use Getopt::Long;
use Pod::Usage;
use DateTime;

use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../libext";

use SysFink::Conf::SysFink;
use SysFink::Utils::Conf qw(load_conf_multi);
use SysFink::Utils::DB qw(get_connected_schema);


my $help = 0;
my $ver = 2;

my $conf_fp = undef;
my $machine_conf_fp = undef;
my $delete_old = 0;

my $options_ok = GetOptions(
    'help|h|?' => \$help,
    'ver|v=i' => \$ver,
    'conf_path|cp=s' => \$conf_fp,
    'machine_conf_path|mcp=s' => \$machine_conf_fp,
    'delete_old' => \$delete_old,
);
pod2usage(1) if $help || !$options_ok;

$machine_conf_fp = catdir( $RealBin, '..', 'conf-machines' ) unless defined $machine_conf_fp;
$conf_fp = catdir( $RealBin, '..', 'conf' ) unless defined $conf_fp;

croak "Machine conf dir '$machine_conf_fp' not found." unless -d $machine_conf_fp;
croak "Conf dir '$conf_fp' not found." unless -d $conf_fp;


sub get_rs_for_my_attrs {
    my ( $schema, $search_cond, $conf ) = @_;

    my ( $table_name, $joins ) = @$conf;
    print "deleting from table: $table_name\n" if $ver >= 3;
    my $search_attrs = { alias => $table_name.'_id' };
    $search_attrs->{prefetch} = $joins if defined $joins;
    my $rs = $schema->resultset($table_name)->search( $search_cond, $search_attrs );
}


sub do_delete_old {
    my ( $schema, $search_cond ) = @_;
    $search_cond = {} unless defined $search_cond;

    my $all_confs = [
        [
            'mconf_sec_kv',
            { 'mconf_sec_id' => { 'mconf_id' => 'machine_id' } },
        ],
        [
            'mconf_sec',
            { 'mconf_sec_id' => 'mconf_id' },
        ],
        [
            'mconf',
            'machine_id',
        ],
        [
            'machine',
        ],
    ];

    # Delete direct data.
    foreach my $conf_num ( 0..$#$all_confs ) {
        my $rs = get_rs_for_my_attrs( $schema, $search_cond, $all_confs->[ $conf_num ] );
        $rs->delete_all;
    }
    return 1;
}


my $conf = load_conf_multi( $conf_fp, 'db' );
my $schema = get_connected_schema( $conf->{db} );

$schema->storage->txn_begin;

if ( $delete_old ) {
    print "deleting old values\n" if $ver >= 2;
    do_delete_old( $schema );
}


my $mconf_obj = SysFink::Conf::SysFink->new({ conf_dir_path => $machine_conf_fp });
$mconf_obj->load_config();
my $mconf = $mconf_obj->conf;

#print Dumper( $mconf );


print "inserting new values\n" if $ver >= 2;
foreach my $machine_name ( keys %$mconf ) {

    print "machine: $machine_name\n" if $ver >= 3;
    my $machine_section = $mconf->{$machine_name};

    # Get machine_id by machine name.
    my $machine_row = $schema->resultset('machine')->find_or_create({
        'name' => $machine_name,
    });
    my $machine_id = $machine_row->id;

    # Inactivate all machine configs (mconf).
    my $mconf_to_inactivate_rs = $schema->resultset('mconf')->search({
        'machine_id' => $machine_id,
        'active' => 1,
    });
    $mconf_to_inactivate_rs->update({
        'active' => 0,
    });

    # print "$machine_name $machine_id\n"; # debug

    my $mconf_row = $schema->resultset('mconf')->find_or_create({
        'machine_id' => $machine_id,
        'active' => 1,
        'create_time'=> DateTime->now,
    });

    my $order_number = {};
    foreach my $section_name ( keys %$machine_section ) {

        print "  section: $section_name\n" if $ver >= 3;
        my $section_kv = $machine_section->{$section_name};

        my $mconf_sec_row = $schema->resultset('mconf_sec')->find_or_create({
            'mconf_id' => $mconf_row->id,
            'name' => $section_name,
        });

        foreach my $key ( keys %$section_kv ) {

            $order_number->{$section_name}->{$key} = 0 unless exists $order_number->{$section_name}->{$key};

            my $value = $section_kv->{$key};
            print "    key-value: $key\n" if $ver >= 3;

            if ( ref $value eq 'ARRAY' ) {
                foreach my $value_index ( 0..$#$value ) {
                    my $one_value = $value->[ $value_index ];
                    $order_number->{$section_name}->{$key}++;
                    my $mconf_sec_kv_row = $schema->resultset('mconf_sec_kv')->create({
                        'mconf_sec_id' => $mconf_sec_row->id,
                        'num' => $order_number->{$section_name}->{$key},
                        'key' => $key,
                        'value' => $one_value,
                    });
                }

            } elsif ( not ref $value ) {
                $order_number->{$section_name}->{$key}++;
                my $mconf_sec_kv_row = $schema->resultset('mconf_sec_kv')->create({
                    'mconf_sec_id' => $mconf_sec_row->id,
                    'num' => $order_number->{$section_name}->{$key},
                    'key' => $key,
                    'value' => $value,
                });

            } else {
                croak "Uknown value for key $machine_name:$section_name:$key.";
            }
        }
    }
}

$schema->storage->txn_commit;


=head1 NAME

conf-to-db.pl - Inserting machine configuration to DB.

=head1 SYNOPSIS

perl tests-to-db.pl [options]

 Options:
   --help
   --ver=$NUM .. Verbosity level 0..5. Default 2.
   --delete_old .. Empty all machine config tables before inserting new machine config.
   --conf_path .. Configuration path. Default './conf'.
   --machine_conf_path .. Machine configuration path. Default './conf-machines'.

=head1 DESCRIPTION

B<This program> will delete ..

=cut
