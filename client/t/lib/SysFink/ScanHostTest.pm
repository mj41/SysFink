package SysFink::ScanHostTest;

use strict;
use warnings;

use base 'SysFink::ScanHost';


sub new {
    my $class = shift;
    my $test_conf = shift;

    my $self = $class->SUPER::new( @_ );

    # Prepare $test_conf to more useful structures.
    $self->{_test_conf_paths} = [];
    $self->{_test_conf_paths_hash} = {};
    $self->{_test_conf_dirs} = {};
    $self->{_test_conf_stat_modifs} = {};
    $self->{_test_all_results} = [];

    # ToDo - add or check if parent dirs exists
    foreach my $num ( 0..$#$test_conf ) {
        my $item = $test_conf->[ $num ];

        my $full_path;
        if ( ref $item eq 'ARRAY' ) {
            $full_path = $item->[ 0 ];
            $self->{_test_conf_stat_modifs}->{ $full_path } = $item->[ 1 ];
        } else {
            $full_path = $item;
        }
        
        # The last char is backslash.
        if ( my ( $base_name ) = $full_path =~ m{^ (.*) \/ $}x ) {
            $self->{_test_conf_dirs}->{ $base_name } = 1;
            $self->{_test_conf_items}->{ $base_name } = 1;
        } else {
            $self->{_test_conf_items}->{ $full_path } = 1;
        }

        push @{$self->{_test_conf_paths}}, $full_path;
    }
    #use Data::Dumper; print Dumper( $self ); exit;
    
    return $self;
}


sub get_dir_items {
    my ( $self, $dir_name ) = @_;

    my $dir_items = [];
    foreach my $num ( 0..$#{ $self->{_test_conf_paths} } ) {
        my $full_path = $self->{_test_conf_paths}->[ $num ];
        if ( my ( $name ) = $full_path =~ m{^ \Q$dir_name\E ([^\/]+) \/? $}x ) {
            push @$dir_items, $name;
        }
    }
    return [ sort @$dir_items ];
}


sub my_lstat {
    my ( $self, $full_path ) = @_;

    # Check if path exists.
    return ( 0 ) unless exists $self->{_test_conf_items}->{ $full_path };
        
        
    #  0 dev - device number of filesystem
    #  1 ino - inode number
    #  2 mode - file mode (type and permissions)
    #  3 nlink - number of (hard) links to the file
    #  4 uid - numeric user ID of file's owner
    #  5 gid - numeric group ID of file's owner
    #  6 rdev - the device identifier (special files only)
    #  7 size - total size of file, in bytes
    #  8 atime - last access time in seconds since the epoch
    #  9 mtime - last modify time in seconds since the epoch
    # 10 ctime - inode change time in seconds since the epoch (non-portable)
    # 11 blksize - preferred block size for file system I/O
    # 12 blocks - actual number of blocks allocated

    my %stat = ();

    $stat{dev} = int( rand(1000)+1 );
    $stat{ino} = $stat{dev} + 1000;

    my $mode;

    if ( exists $self->{_test_conf_dirs}->{ $full_path } ) {
        $stat{mode} = 16877; # directory
    } else {
        $stat{mode} = 33188; # file
    }

    $stat{nlink} = 0;
    $stat{uid} = 1;
    $stat{gid} = 1;
    $stat{rdev} = undef;
    $stat{size} = 100;

    my $time = 1251765432;
    $stat{time} = $time;
    $stat{atime} = $time -  1 * 3600;
    $stat{mtime} = $time -  5 * 3600;
    $stat{ctime} = $time - 10 * 3600;

    $stat{blocks} = int( $stat{size} / 512 ) + 1;
    $stat{blksize} = 4096;

    if ( exists $self->{_test_conf_stat_modifs}->{$full_path} ) {
        my $stat_modif = $self->{_test_conf_stat_modifs}->{$full_path};
        foreach my $key ( keys %$stat_modif ) {
            $stat{ $key } = $stat_modif->{ $key };
        }
    }

    return (
        1, # path exists
        $stat{dev}, $stat{ino}, $stat{mode}, $stat{nlink},
        $stat{uid}, $stat{gid}, $stat{rdev}, $stat{size},
        $stat{atime}, $stat{mtime}, $stat{ctime},
        $stat{blksize}, $stat{blocks}
    );
}


sub send_ok_response {
    my ( $self, $response, $is_last ) = @_;

    my $result = $self->pack_ok_response( $response, $is_last );
    push @{$self->{_test_all_results}}, $result;
    return 1;
}


sub get_all_results {
    my ( $self ) = @_;

    return $self->{_test_all_results};
}


1;
