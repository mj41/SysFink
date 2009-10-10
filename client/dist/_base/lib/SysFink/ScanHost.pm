package SysFink::ScanHost;

use strict;
use warnings;
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
    my ( $self, $full_path, $base_flags ) = @_;

    my $flags;
    my $plus_found = 0;

    unless ( exists $self->{paths}->{ $full_path } ) {
        $flags = $base_flags;

    } else {
        $flags = { %$base_flags };
        my $path_flags = $self->{paths}->{ $full_path };
        foreach my $flag_name ( keys %$path_flags ) {
            $flags->{ $flag_name } = $path_flags->{ $flag_name };
        }

        # Add to already processed paths.
        $self->{paths_with_processed_flags}->{ $full_path } = { %$flags };
    }

    foreach my $value ( values %$flags ) {
        if ( $value eq '+' ) {
            $plus_found = 1;
            last;
        }
    }

    return ( $flags, $plus_found );
}


sub get_parent_path_flags {
    my ( $self, $full_path ) = @_;

    return {} if $full_path eq '/';

    # Try to find parent path ( or parent of parent path or ... ) with flags definition.
    # This flags should be already processed (paths_with_processed_flags).
    my $path = $full_path;
    while ( my ( $parent_path ) = $path =~ m{ ^ (.+) \/ [^\/]+ $ }x ) {

        if ( exists $self->{paths_with_processed_flags}->{ $parent_path } ) {
            return $self->{paths_with_processed_flags}->{ $parent_path };
        }

        if ( exists $self->{paths}->{ $parent_path } ) {
            print " >>> error $self->{paths}->{$parent_path}\n";
            return \%{ $self->{paths}->{$parent_path} };
        }

        $path = $parent_path;
    }

    return {};
}


=head2 flags_hash_to_str

Sort hash keys and join its to canonized flags string.

=cut

sub flags_hash_to_str {
    my ( $self, %flags ) = @_;

    my $flags_str = '';
    foreach my $key ( sort keys %flags ) {
        $flags_str .= sprintf( "%1s%1s", $flags{$key}, $key );
    }

    return $flags_str;
}


=head2 flags_hash_to_str

Convert numeric node number to ls format.

=cut

sub mode_to_lsmode() {
    my ( $self, $mode ) = @_;

    unless ( defined($mode) ) {
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


sub get_dir_items {
    my ( $self, $dir_name ) = @_;

    # Load direcotry items list.
    my $dir_handle;
    if ( not opendir($dir_handle, $dir_name) ) {
        $self->add_error("Directory '$dir_name' not open for read.");
        return 0;
    }
    my @dir_items = readdir($dir_handle);
    close($dir_handle);
    return  \@dir_items;
}


sub my_lstat {
    my ( $self, $full_path ) = @_;
    return lstat( $full_path );
}


sub add_item {
    my ( $self, $full_path, $flags, $debug_prefix ) = @_;

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
    my ( $dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks ) = $self->my_lstat( $full_path );
    print $debug_prefix."  mode '$mode', nlink '$nlink', uid '$uid', gid '$gid', size '$size'\n" if $self->{debug_out} >= 3;
    #print $debug_prefix."  atime '$atime', mtime '$mtime', ctime '$ctime'\n" if $self->{debug_out} if $self->{debug_out} >= 3;
    #print $debug_prefix."  dev '$dev', ino '$ino', rdev '$rdev', size '$size', blksize '$blksize', blocks '$blocks'\n" if $self->{debug_out} if $self->{debug_out} >= 3;

    #my $lsmode_str = $self->mode_to_lsmode( $mode );
    my $item_info = {
        path => $full_path,
        mode => $mode,
    };

    my $is_dir = S_ISDIR($mode);

    # directory
    if ( $is_dir ) {

    # symlink
    } elsif ( S_ISLNK($mode) ) {
        # flag L - symlink path
        if ( $flags->{L} eq '+' ) {
            $item_info->{symlink} = readlink( $full_path );
        }

    # file
    } elsif ( S_ISREG($mode) ) {
        # flag 5 - file md5 sum
        if ( $flags->{5} eq '+' ) {
            my $hash = $self->{hash_obj}->hash_file( $full_path );
            $item_info->{hash} = $hash;
        }

        # flag S - file size
        if ( $flags->{S} eq '+' ) {
            $item_info->{size} = $size;
        }

    }

    # flag U - user
    if ( $flags->{U} eq '+' ) {
        $item_info->{uid} = $uid;
        my $user_name = getpwuid( $uid );
        $item_info->{user} = $user_name if defined $user_name;
    }

    # flag G - group
    if ( $flags->{G} eq '+' ) {
        $item_info->{gid} = $gid;
        my $group_name = getgrgid( $gid );
        $item_info->{group} = $group_name if defined $group_name;
    }

    # flag M - mtime
    if ( $flags->{G} eq '+' ) {
        $item_info->{mtime} = $mtime;
    }

    # H - hard links number
    if ( $flags->{H} eq '+' ) {
        $item_info->{nlink} = $nlink;
    }

    # D - major and minor device number
    if ( $flags->{D} eq '+' ) {
        $item_info->{dev} = $dev;
        $item_info->{ino} = $ino;
    }

    # B - do backup this item
    # Add nothing special here.

    push @{ $self->{loaded_items} }, $item_info;

    return ( 1, $is_dir );
}


sub scan_recurse {
    my ( $self, $recursion_depth, $dir_name, $dir_flags ) = @_;

    my $debug_prefix = '  ' x $recursion_depth;
    if ( $self->{debug_out} > 1 ) {
        print "\n";
        print "in '$dir_name' ($recursion_depth):\n";

    } elsif ( $self->{debug_out} == 1 ) {
        print "$dir_name\n";
    }

    # Directory number limit (this is not file number limit nor recursion limit).
    # Depends on client memory (and swap) size.
    if ( $self->{debug_out} && $#{ $self->{loaded_items} } > 1_000 ) {
        unless ( $self->{debug_data}->{recursive_limit} ) {
            $self->add_error("No all files. Recursion limit reached!");
            $self->{debug_data}->{recursive_limit} = 1;
        }
        return 1;
    }

    $dir_name = $self->get_canon_dir( $dir_name );
    #$self->dump( $dir_name );

    my $dir_items = $self->get_dir_items( $dir_name );
    return 0 unless ref $dir_items;


    # Sub dirs to follow using recursive call of this sub.
    my $sub_dirs = [];

    my $full_path;
    ITEM: foreach my $name ( sort @$dir_items ) {
        next if $name =~ /^\.$/;
        next if $name =~ /^\..$/;
        next if $name =~ /^\s*$/;

        $full_path = $dir_name . $name;
        print $debug_prefix."item $full_path\n" if $self->{debug_out} >= 2;

        my ( $flags, $plus_found ) = $self->get_flags( $full_path, $dir_flags );
        print $debug_prefix."  flags '" . $self->flags_hash_to_str( %$flags ) . "' (plus_found=$plus_found)\n" if $self->{debug_out} >= 3;

        # Skip this file/directory if nothing to check selected.
        next ITEM unless $plus_found;

        my ( $ret_code, $is_dir ) = $self->add_item( $full_path, $flags, $debug_prefix  );

        if ( $is_dir ) {
            # ToDo - why not '$flags' only instead of '{ %$flags }' ?
            push @$sub_dirs, [ $full_path, { %$flags } ];
        }
    }

    foreach my $sub_dir_data ( sort @$sub_dirs ) {
        my ( $sub_dir_path, $sub_dir_flags ) = @$sub_dir_data;
        $self->scan_recurse( $recursion_depth+1, $sub_dir_path, $sub_dir_flags );
    }

    return 1;
}


sub reset_state {
    my ( $self ) = @_;

    $self->{paths} = {};

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

    # Prepare paths.
    $self->{paths} = {};
    $self->{paths_ordered} = [];
    foreach my $path_conf ( @{ $args->{paths} } ) {
        my $full_path = $path_conf->[ 0 ];
        $self->{paths}->{ $full_path } = $path_conf->[ 1 ];
        push @{ $self->{paths_ordered} }, $full_path;
    }

    $self->{paths_with_processed_flags} = {};

    unless ( exists $self->{paths}->{'/'} ) {
        $self->add_error("Base path  not found.");
        return 0;
    }


    $self->{loaded_items} = [];
    my $ret_code;
    foreach my $full_path ( sort keys %{ $self->{paths} } ) {
        # Skip already scanned items.
        next if exists $self->{paths_with_processed_flags}->{ $full_path };

        my $parent_flags = $self->get_parent_path_flags( $full_path );
        my ( $flags, $plus_found ) = $self->get_flags( $full_path, $parent_flags );
        print " >>> $full_path flags '" . $self->flags_hash_to_str( %$flags ) . "' (plus_found=$plus_found)\n" if $self->{debug_out} >= 3;

        my $is_dir = 1;
        if ( $full_path ne '/' ) {
            my $s_ret_code;
            ( $s_ret_code, $is_dir ) = $self->add_item( $full_path, $flags, '' );
        }

        if ( $is_dir ) {
            $ret_code = $self->scan_recurse( 0, $full_path, $flags );
        }

        last unless $ret_code;
    }

    return $ret_code;
}


1;