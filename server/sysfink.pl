#!/usr/bin/perl

use strict;
use warnings;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);
use File::Spec::Functions;
use Data::Dumper;

use Net::OpenSSH;

use lib 'lib';
use lib 'libext';

use SSH::RPC::PP::Client;
use SysFink::Conf::DBIC;
use SysFink::Utils::Conf qw(load_conf_multi);
use SysFink::Utils::DB qw(get_connected_schema);


my $ver = 5;
my $machine_name = $ARGV[0] || 'tapir1';
my $user = $ARGV[1] || 'root';
my $dist_type = 'linux-bin-64b';
# test2
#$dist_type = 'linux-perl-md5';

my $debugging_on_client = 0;

my $conf_fp;


$conf_fp = catdir( $RealBin, 'conf' ) unless defined $conf_fp;
croak "Conf dir '$conf_fp' not found." unless -d $conf_fp;

my $conf = load_conf_multi( $conf_fp, 'db' );
my $schema = get_connected_schema( $conf->{db} );




my $conf_obj = SysFink::Conf::DBIC->new({ schema => $schema, });

my $machine_id = $conf_obj->get_machine_id( { 'name' => $machine_name } );
my $mconf_id = $conf_obj->get_machine_active_mconf_id( $machine_id );

my $general_conf = $conf_obj->load_general_conf( $machine_id, $mconf_id );
print Dumper( $general_conf );


my $host = $general_conf->{hostname};

# test3 - irix test
if ( 0 ) {
    $host = 'efis.ro.vutbr.cz';
    $dist_type = 'irix-bin-64b';
}


sub check_user {
    my ( $user ) = @_;
    return 0 unless $user;
    return 0 if $user =~ /\s/;
    return 0 if $user =~ /[\.\:\;\\\/]/;
    return 1;
}


sub user_to_clientdir {
    my ( $user ) = @_;
    return '/root/sysfink-client' if $user eq 'root';
    return '/home/' . $user . '/sysfink-client';
}


sub run_ssh_cmd {
    my ( $ssh, $cmd ) = @_;

    my ( $out, $err ) = $ssh->capture2( $cmd );
    if ( $out || $err ) {
        print "out: '$out', err:'$err'\n";
    }
    return ( $out, $err );
}


sub ls_output_contains_unknown_dir {
    my ( $out ) = @_;

    chomp($out);
    my @lines = split( /\n/, $out );
    shift @lines; # remove line "total \d+"
    foreach my $line ( @lines ) {
        if ( $line =~ /^\s*d/ ) {
            return 1 if $line !~ /(bin|lib|libcpan|libdist){1}\s*$/;
        }
    }
    return 0;
}



croak "Bad user name '$user'." unless check_user( $user );

my $ssh = Net::OpenSSH->new( $host, user => $user, master_opts => [ '-T'] );
$ssh->error and die "Couldn't establish SSH connection: ". $ssh->error;

my ($out, $err);
($out, $err) = $ssh->capture2('hostname');
$ssh->error and die "remote 'hostname' command failed: " . $ssh->error;

my $hostname = $out;
chomp($hostname);

print "hostname '$host' connected ";
if ( $hostname eq $host ) {
    print "ok\n";
} else {
    print "ERROR (got '$hostname')\n";
    exit 0;
}

my $client_dir = user_to_clientdir( $user );
print "client_dir: '$client_dir'\n" if $ver >= 2;

($out, $err) = run_ssh_cmd( $ssh, "ls -l $client_dir" );

if ( $err =~ /No such file or directory/i ) {
    print "Directory '$client_dir' doesn't exists on host.\n" if $ver >= 3;
} else {
    if ( ls_output_contains_unknown_dir($out) ) {
        croak "Directory '$client_dir' on '$host' contains some unknown directories.\nCmd 'ls -l' output is\n$out.\n";
    }
    # ToDo - je to jiz dost bezpecne?
    run_ssh_cmd( $ssh, "rm -rf $client_dir" );
}

run_ssh_cmd( $ssh, "mkdir $client_dir" );

my $client_src_dir = catdir( $RealBin, '..', 'client' );

my $client_src_name = 'sysfink-client.pl';
my $client_src_fpath = catfile( $client_src_dir, $client_src_name );
my $client_src_dest_dir = catdir( $client_dir );
$ssh->scp_put( $client_src_fpath, $client_src_dest_dir );



sub get_dir_items {
    my ( $dir_name ) = @_;

    # Load direcotry items list.
    my $dir_handle;
    if ( not opendir($dir_handle, $dir_name) ) {
        #add_error("Directory '$dir_name' not open for read.");
        return 0;
    }
    my @dir_items = readdir($dir_handle);
    close($dir_handle);
    return  \@dir_items;
}



sub transfer_dir_content {
    my ( $base_src_dir, $sub_src_dir, $base_dest_dir  ) = @_;

    my $full_src_dir = catdir( $base_src_dir, $sub_src_dir );
    my $dir_items = get_dir_items( $full_src_dir );
    return 0 unless ref $dir_items;

    my $sub_dirs = [];
    my $full_src_path;
    ITEM: foreach my $name ( sort @$dir_items ) {

        next if $name =~ /^\.$/;
        next if $name =~ /^\..$/;
        next if $name =~ /^\s*$/;

        $full_src_path = catdir( $full_src_dir, $name );

        if ( -d $full_src_path ) {
            next if $name =~ /^\.svn$/; # ignore Subversion dirs
            push @$sub_dirs, $name;

        } elsif ( -f $full_src_path ) {
            my $full_dest_fpath = catfile( $base_dest_dir, $sub_src_dir, $name );
            #print "item '$full_src_path' -> '$full_dest_fpath'\n";
            $ssh->scp_put( $full_src_path, $full_dest_fpath );
        }
    }

    foreach my $sub_dir ( sort @$sub_dirs ) {
        my $new_sub_src_dir = catdir( $sub_src_dir, $sub_dir );
        my $full_dest_fpath = catdir( $base_dest_dir, $new_sub_src_dir );
        run_ssh_cmd( $ssh, "mkdir $full_dest_fpath" );
        transfer_dir_content( $base_src_dir, $new_sub_src_dir, $base_dest_dir );
    }

    return 1;
}


sub get_item_attrs {
    return {
        mtime => 1,
        mode => 1,
        size => 1,
        uid => 1,
        gid => 1,
        hash => 1,
        nlink => 1,
        dev_num => 1,
        ino_num => 1,
        user_name => 0,
        group_name => 0,
    };
}

sub has_same_data {
    my ( $ra, $rb ) = @_;

    my $attrs = get_item_attrs();
    $attrs->{found} = 1;
    foreach my $attr_name ( keys %$attrs ) {
        my $is_numeric = $attrs->{$attr_name};
        #print "$attr_name is_numeric=$is_numeric\n";
        if ( $is_numeric ) {
            return 0 if defined $ra->{$attr_name} && ( (not defined $rb->{$attr_name}) || $rb->{$attr_name} != $ra->{$attr_name} );
            return 0 if defined $rb->{$attr_name} && ( (not defined $ra->{$attr_name}) || $ra->{$attr_name} != $rb->{$attr_name} );
        } else {
            return 0 if defined $ra->{$attr_name} && ( (not defined $rb->{$attr_name}) || $rb->{$attr_name} ne $ra->{$attr_name} );
            return 0 if defined $rb->{$attr_name} && ( (not defined $ra->{$attr_name}) || $ra->{$attr_name} ne $rb->{$attr_name} );
        }
    }

    return 1;
}


sub get_base_idata {
    my ( $base_data, $raw_data ) = @_;

    my $data = { %$base_data };

    my $attrs = get_item_attrs();
    foreach my $attr_name ( keys %$attrs ) {
        if ( exists $raw_data->{ $attr_name } ) {
            $data->{ $attr_name } = $raw_data->{ $attr_name };
        } else {
            $data->{ $attr_name } = undef;
        }
    }
    return $data;
}



my $dist_src_dir;

$dist_src_dir = catdir( $client_src_dir, 'dist', '_base' );
transfer_dir_content( $dist_src_dir, '', $client_src_dest_dir );

$dist_src_dir = catdir( $client_src_dir, 'dist', $dist_type );
transfer_dir_content( $dist_src_dir, '', $client_src_dest_dir );

run_ssh_cmd( $ssh, "ls -R $client_src_dest_dir" );


my $client_src_dest_fp = catfile( $client_src_dest_dir, $client_src_name );
my $client_start_cmd = "nice -n 10 /usr/bin/perl $client_src_dest_fp 5";
my $rpc = SSH::RPC::PP::Client->new( $ssh, $client_start_cmd );

my $result_obj;

$result_obj = $rpc->run( 'test_noop', $client_src_dest_fp );
$result_obj->dump();

$result_obj = $rpc->run( 'test_three_parts', $client_src_dest_fp );
$result_obj->dump();
while ( $result_obj->isSuccess && !$result_obj->isLast ) {
    $result_obj = $rpc->get_next_response();
    $result_obj->dump();
}


my $file_to_hash = catfile( $client_src_dest_dir, '/lib/SysFink/FileHash/Base.pm' );
$result_obj = $rpc->run( 'hash_file', $file_to_hash );
$result_obj->dump();


$result_obj = $rpc->run( 'hash_type' );
$result_obj->dump();

$result_obj = $rpc->run( 'hash_type_desc' );
$result_obj->dump();


my $max_items_in_one_response = 1_000;
$max_items_in_one_response = $general_conf->{max_items_in_one_response} if defined $general_conf->{max_items_in_one_response};
my $scan_conf = {
    'paths' => $general_conf->{paths},
    'max_items_in_one_response' => $max_items_in_one_response,
};

if ( $debugging_on_client ) {
    print "Client prepared for debugging.\n";
    $scan_conf->{debug_out} = 1;
    my $ret_code = $rpc->debug_run( 'scan_host', $scan_conf );

} else {

    use DateTime;

    # insert scan
    my $scan_row = $schema->resultset('scan')->create({
        mconf_id => $mconf_id,
        start_time => DateTime->now,
        stop_time => undef,
        pid => $$,
        items => undef,
    });
    my $scan_id = $scan_row->scan_id;

    $schema->storage->txn_begin;

    #$scan_conf->{debug_recursion_limit} = int( rand(100)+1 ); # debug
    #$scan_conf->{debug_recursion_limit} = 1_000; # debug

    $result_obj = $rpc->run( 'scan_host', $scan_conf );
    my $response = $result_obj->getResponse();
    my $loaded_items = $response->{loaded_items};

    while ( $result_obj->isSuccess && !$result_obj->isLast ) {
        $result_obj = $rpc->get_next_response();
        #$result_obj->dump();
        $response = $result_obj->getResponse();
        $loaded_items = [
            @$loaded_items,
            @{$response->{loaded_items}}
        ];
    }
    #use Data::Dumper; print Dumper( $loaded_items );


    my %path_to_num = ();
    foreach my $num ( 0..$#$loaded_items ) {
        my $item = $loaded_items->[ $num ];
        print "$item->{path} ($num)\n";
        # 2 .. found on host, initial status
        # if not changed to 0 (in db and the same) or 1 (in db and changed) then 2 means 'new' -> insert to db
        $path_to_num{ $item->{path} } = [ 2, $num ];
    }

    my $prev_sc_idata_rs = $schema->resultset('sc_idata')->search(
        {
            'me.found' => 1,
            'me.newer_id' => undef,
            'sc_mitem_id.machine_id' => $machine_id,
        },
        {
            'join' => [ 'sc_mitem_id' ],
            'select' => [ 'me.sc_idata_id', 'me.sc_mitem_id', 'sc_mitem_id.path', 'me.mtime', ],
            'as' => [ 'sc_idata_id', 'sc_mitem_id', 'path', 'mtime', ],
            'order_by' => [ 'sc_mitem_id.path', ],
        },
    );

    my $sc_mitem_rs = $schema->resultset('sc_mitem');
    my $sc_idata_rs = $schema->resultset('sc_idata');

    while ( my $row_obj = $prev_sc_idata_rs->next ) {
        my %row = ( $row_obj->get_columns() );
        my $path = $row{path};
        #print Dumper( \%row ) if $ver >= 5;

        my $insert_idata = undef;

        # Found.
        if ( exists $path_to_num{ $path } ) {
            my $new_item_data = $loaded_items->[ $path_to_num{ $path }->[1] ];
            if ( has_same_data($new_item_data,\%row) ) {
                # Same data -> do nothing.
                $path_to_num{ $path }->[0] = 0; # 0 .. found in db and not changed

            } else {
                # Data changed -> do update.
                $path_to_num{ $path }->[0] = 1; # 1 .. found in db and changed

                my $sc_mitem_id = $row{'sc_mitem_id'};
                print "updating status to new values sc_mitem_id $sc_mitem_id\n" if $ver >= 4;
                my $insert_idata_base = {
                    sc_mitem_id => $sc_mitem_id,
                    scan_id => $scan_id,
                    newer_id => undef,
                    found => 1,
                };
                #$new_item_data->{size} = int rand(500); # debug
                $insert_idata = get_base_idata( $insert_idata_base, $new_item_data );
            }

        # Not found on during scan on client machine -> delete.
        } else {
            my $sc_mitem_id = $row{'sc_mitem_id'};
            print "updating status to delete sc_mitem_id $sc_mitem_id\n" if $ver >= 4;
            my $insert_idata_base = {
                sc_mitem_id => $sc_mitem_id,
                scan_id => $scan_id,
                newer_id => undef,
                found => 0,
            };
            $insert_idata = get_base_idata( $insert_idata_base, {} );
        }

        if ( defined $insert_idata ) {
            my $sc_idata_row = $sc_idata_rs->create( $insert_idata );
            my $new_sc_idata_id = $sc_idata_row->sc_idata_id;

            my $old_sc_idata_rs = $schema->resultset('sc_idata')->find( $row{'sc_idata_id'} );
            $old_sc_idata_rs->update({ newer_id => $new_sc_idata_id });
        }
    }


    foreach my $num ( 0..$#$loaded_items ) {
        my $item = $loaded_items->[ $num ];
        my $path = $item->{path};
        # insert
        if ( $path_to_num{ $path }->[0] == 2 ) {
            print "inserting path $path (sc_mitem_id=" if $ver >= 4;

            my $sc_mitme_row = $sc_mitem_rs->find_or_create({
                machine_id => $machine_id,
                path => $path,
            });
            my $sc_mitem_id = $sc_mitme_row->sc_mitem_id;
            print $sc_mitem_id if $ver >= 4;

            my $insert_idata_base = {
                sc_mitem_id => $sc_mitem_id,
                scan_id => $scan_id,
                newer_id => undef,
                found => 1,
            };
            my $insert_idata = get_base_idata( $insert_idata_base, $item );
            my $sc_idata_row = $sc_idata_rs->create( $insert_idata );
            my $new_sc_idata_id = $sc_idata_row->sc_idata_id;
            print ", sc_idata_id=" . $new_sc_idata_id if $ver >= 4;
            print ")\n"  if $ver >= 4;
        }
    }

    $schema->storage->txn_commit;

    #print Dumper( \%path_to_num ) if $ver >= 5;

    # update scan
    $scan_row->update({
        items => scalar(@$loaded_items),
        stop_time => DateTime->now,
    });

    #print "sleeping ...\n"; sleep(10*60); # debug size of used memory
}


undef $ssh;
