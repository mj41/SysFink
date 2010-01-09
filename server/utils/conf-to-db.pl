use strict;
use warnings;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);
use File::Spec::Functions;
use Data::Dumper;

use Getopt::Long;
use Pod::Usage;
use DateTime;
use Data::Compare;

use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../libext";

use SysFink::Conf::SysFink;
use SysFink::Conf::DBIC;
use SysFink::Utils::Conf qw(load_conf_multi);
use SysFink::Utils::DB qw(get_connected_schema);


my $help = 0;
my $ver = 3;

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

my $conf = load_conf_multi( $conf_fp, 'db' );
my $schema = get_connected_schema( $conf->{db} );

$schema->storage->txn_begin;


my $db_conf_obj = SysFink::Conf::DBIC->new({ schema => $schema });
my $old_confs = $db_conf_obj->load_active_conf( undef, 1 );
#print Dumper( $old_confs );


my $mconf_obj = SysFink::Conf::SysFink->new({ conf_dir_path => $machine_conf_fp });
$mconf_obj->load_config();
my $mconf = $mconf_obj->conf;

#print Dumper( $mconf );


# Change counter.
my $ch_count = {
    found => 0,
    added => 0,
    changed => 0,
    removed => 0,
};

my $mconf_change_values = {
    'date'=> DateTime->now,
    'user_id' => undef,
};
my $mconf_change_row = $schema->resultset('mconf_change')->create( $mconf_change_values );


# Insert and modify.
NEW_MACHINE_CONF: foreach my $machine_name ( keys %$mconf ) {

    print "machine: $machine_name\n" if $ver >= 4;
    my $machine_conf = $mconf->{$machine_name};

    # Get machine_id by machine name.
    my $machine_row = $schema->resultset('machine')->find_or_create({
        'name' => $machine_name,
        'active' => 1,
    });
    my $machine_id = $machine_row->id;
    
    $ch_count->{found}++;
    if ( exists $old_confs->{ $machine_name } ) {
        my $compare_obj = new Data::Compare( $old_confs->{ $machine_name }, $machine_conf );
        if ( $compare_obj->Cmp ) {
            print "Machine '$machine_name' configuration not changed.\n" if $ver >= 3;
            # are same
            next NEW_MACHINE_CONF;
        } else {
            print "Machine '$machine_name' configuration changed.\n" if $ver >= 3;
        }
    } else {
        $ch_count->{added}++;
        print "Machine '$machine_name' added.\n" if $ver >= 3;
    }

    # Inactivate all machine configs (mconf).
    my $mconf_to_inactivate_rs = $schema->resultset('mconf')->search({
        'machine_id' => $machine_id,
        'active' => 1,
        
    });
    $mconf_to_inactivate_rs->update({
        'active' => 0,
    });

    # print "$machine_name $machine_id\n"; # debug

    my $mconf_row = $schema->resultset('mconf')->create({
        'machine_id' => $machine_id,
        'mconf_change_id' => $mconf_change_row->id,
        'active' => 1,
    });

    my $order_number = {};
    foreach my $section_name ( keys %$machine_conf ) {

        print "  section: $section_name\n" if $ver >= 4;
        my $section_kv = $machine_conf->{$section_name};

        my $mconf_sec_row = $schema->resultset('mconf_sec')->create({
            'mconf_id' => $mconf_row->id,
            'name' => $section_name,
        });

        foreach my $key ( keys %$section_kv ) {

            $order_number->{$section_name}->{$key} = 0 unless exists $order_number->{$section_name}->{$key};

            my $value = $section_kv->{$key};
            print "    key-value: $key\n" if $ver >= 4;

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


# Delete removed machines.
foreach my $machine_name ( keys %$old_confs ) {
    next if exists $mconf->{ $machine_name };
    
    print "Machine '$machine_name' was removed.\n" if $ver >= 3;
    $ch_count->{removed}++;
    
    my $machine_row = $schema->resultset('machine')->find({
        'name' => $machine_name,
        'active' => 1,
    });
    $machine_row->update({ 'active' => 0 });

    my $mconf_row = $schema->resultset('mconf')->find({
        'machine_id' => $machine_row->machine_id,
        'active' => 1,
    });
    $mconf_row->update({ 'active' => 0 });
}


$mconf_change_row->update(       $ch_count );


$schema->storage->txn_commit;


=head1 NAME

conf-to-db.pl - Inserting machine configuration to DB.

=head1 SYNOPSIS

perl tests-to-db.pl [options]

 Options:
   --help
   --ver=$NUM .. Verbosity level 0..10. Default 3.
   --delete_old .. Empty all machine config tables before inserting new machine config.
   --conf_path .. Configuration path. Default './conf'.
   --machine_conf_path .. Machine configuration path. Default './conf-machines'.

=head1 DESCRIPTION

B<This program> will delete ..

=cut
