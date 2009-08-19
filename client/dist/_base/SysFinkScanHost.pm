package SysFink::ScanHost;

use strict;
use base 'SysFink::RunObj::Base';

use Fcntl ':mode';


sub new {
    my ( $class, $shared_data, $hash_obj ) = @_;

    my $self = $class->SUPER::new( $shared_data );
    $self->{hash_obj} = $hash_obj;

    return $self;
}

sub get_canon_dir {
    my ( $self, $dir ) = @_;

    my $canon_dir = undef;

    if ( $dir eq "" ) {
        $canon_dir = '/';

    } else {
        $canon_dir = $dir . '/';
    }

    $canon_dir =~ s{ \/{2,} }{\/}gx;
    return $canon_dir;
}


sub get_flags {
    my ( $self, $dir_name, $parent_flags ) = @_;
    return $parent_flags;
}


# convert numeric node number to ls format
sub mode_to_lsmode() {
    my ( $self, $mode ) = @_;

    if (!defined($mode)) {
        return "??????????";
    }

    my @flag;

    $flag[0] = S_ISDIR($mode) ? 'd' : '-';
    $flag[0] = 'l' if (S_ISLNK($mode));
    $flag[0] = 'b' if (S_ISBLK($mode));
    $flag[0] = 'c' if (S_ISCHR($mode)) ;
    $flag[0] = 'p' if (S_ISFIFO($mode));
    $flag[0] = 's' if (S_ISSOCK($mode));

    $flag[1] = ($mode & S_IRUSR) >> 6 ? 'r' : '-';
    $flag[2] = ($mode & S_IWUSR) >> 6 ? 'w' : '-';
    $flag[3] = ($mode & S_IXUSR) >> 6 ? 'x' : '-';
    $flag[3] = 's' if (($mode & S_ISUID) >> 6);

    $flag[4] = ($mode & S_IRGRP) >> 3 ? 'r' : '-';
    $flag[5] = ($mode & S_IWGRP) >> 3 ? 'w' : '-';
    $flag[6] = ($mode & S_IXGRP) >> 3 ? 'x' : '-';
    $flag[6] = 's' if (($mode & S_ISGID) >> 6);

    $flag[7] = ($mode & S_IROTH) >> 0 ? 'r' : '-';
    $flag[8] = ($mode & S_IWOTH) >> 0 ? 'w' : '-';
    $flag[9] = ($mode & S_IXOTH) >> 0 ? 'x' : '-';
    $flag[9] = 't' if (($mode & S_ISVTX) >> 0);

#   ($mode & S_IRGRP) >> 3;

    return join('', @flag);
}


sub scan_recurse {
    my ( $self, $loaded_items, $dir_name, $parent_flags ) = @_;

    print "$dir_name\n" if $self->{debug_out};

    # Directory number limit (this is not file number limit nor recursion limit).
    # Depends on client memory (and swap) size.
    if ( scalar(@$loaded_items) > 1_000 ) {
        unless ( $self->{debug_data}->{recursive_limit} ) {
            $self->add_error("No all files. Recursion limit reached!");
            $self->{debug_data}->{recursive_limit} = 1;
        }
        return $loaded_items;
    }

    my $dir_name = $self->get_canon_dir( $dir_name );
    #$self->dump( $dir_name );

    my $flags = $self->get_flags( $dir_name, $parent_flags );


    # Load direcotry items list.
    my $dir_handle;
    if ( not opendir($dir_handle, $dir_name) ) {
        $self->add_error("Directory '$dir_name' not open for read.");
        return 0;
    }
    my @dir_items = readdir($dir_handle);
    close($dir_handle);


    # Sub dirs to follow using recursive call of this sub.
    my $sub_dirs = [];

    my $full_path;
    foreach my $name ( sort @dir_items ) {
        next if $name =~ /^\.$/;
        next if $name =~ /^\..$/;
        next if $name =~ /^\s*$/;

        $full_path = $dir_name . $name;

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
        my ( $dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks ) = lstat( $full_path );

        # is directory
        if ( S_ISDIR($mode) ) {
            push @$sub_dirs, $full_path;
        }

        my $lsmode_str = $self->mode_to_lsmode( $mode );
        my $item_info = {
            mode => $lsmode_str,
        };

        # is file
        if ( S_ISREG($mode) ) {
            my $hash = $self->{hash_obj}->hash_file( $full_path );
            $item_info->{hash} = $hash;
        }

        push @$loaded_items, [ $full_path, $item_info ];

    }

    LOOP: foreach my $sub_dir_path ( sort @$sub_dirs ) {
        $self->scan_recurse( $loaded_items, $sub_dir_path, $flags );
    }

    return 1;
}


sub reset_state {
    my ( $self ) = @_;
    $self->{loaded_items} = undef;
    $self->{errors} = [];
    return 1;
}


sub get_result {
    my ( $self ) = @_;
    return (
        loaded_items => $self->{loaded_items},
        errors => $self->{errors},
    );
}


sub scan {
    my ( $self, $args ) = @_;

    $self->process_base_command_args( $args );
    my $paths = $args->{paths};

    my $dir = '/';
    $self->{loaded_items} = [];
    my $ret_code = $self->scan_recurse( $self->{loaded_items}, $dir, $args->{default_root_flags} );
    return $ret_code;
}


1;