package SysFink::ScanHost;

use strict;
use warnings;

use base 'SSH::RPC::Shell::PP::Cmd::BaseJSON';

use Fcntl ':mode';

=head1 NAME

SysFink::ScanHost - Scannig on clients class.

=head1 SYNOPSIS

ToDo. See L<SysFink::Client>.

=head1 DESCRIPTION

Run 'scan' client command.

=head1 METHODS


=head2 new

Constructor.

=cut


sub new {
    my ( $class, $hash_obj ) = @_;

    my $self = $class->SUPER::new();
    $self->{hash_obj} = $hash_obj;

    return $self;
}


=head2 get_canon_dir

Canonize given path.

=cut

sub get_canon_dir {
    my ( $self, $dir ) = @_;

    my $canon_dir = undef;

    if ( $dir eq '' ) {
        $canon_dir = '/';

    } else {
        $canon_dir = $dir . '/';
    }

    $canon_dir =~ s{ \/{2,} }{\/}gx;
    return $canon_dir;
}


=head2 join_flags

Join flags.

=cut

sub join_flags {
    my ( $self, $base_flags, $flags_to_add ) = @_;

    my $flags = { %$base_flags };

    # Add flags.
    foreach my $flag_name ( keys %$flags_to_add ) {
        $flags->{ $flag_name } = $flags_to_add->{ $flag_name };
    }

    my $plus_found = 0;
    # Check if there is some positive flag.
    foreach my $value ( values %$flags ) {
        if ( $value eq '+' ) {
            $plus_found = 1;
            last;
        }
    }

    return ( $flags, $plus_found );
}


=head2 get_flags

Get flags for given path or base_flags if not found.

=cut

sub get_flags {
    my ( $self, $full_path, $base_flags ) = @_;

    my $flags;
    my $plus_found = 0;

    # Config for given path doesn't exist.
    if ( not exists $self->{paths}->{ $full_path } ) {
        $flags = $base_flags;

    # Config exists. Join it with base_flags.
    } else {
        $flags = { %$base_flags };
        my $path_flags = $self->{paths}->{ $full_path }->{flags};
        foreach my $flag_name ( keys %$path_flags ) {
            $flags->{ $flag_name } = $path_flags->{ $flag_name };
        }

        # Add to already processed paths.
        $self->{paths_with_processed_flags}->{ $full_path } = { %$flags };
    }

    # Check if there is some positive flag.
    foreach my $value ( values %$flags ) {
        if ( $value eq '+' ) {
            $plus_found = 1;
            last;
        }
    }

    return ( $flags, $plus_found );
}


=head2 get_parent_path_flags

Find and return flags for given path. Lookup inside configuration for given
path. If not found then for parent direcotry of path. If not found then for 
parent of parent ...

=cut

sub get_parent_path_flags {
    my ( $self, $full_path ) = @_;

    return {} if $full_path eq '';
    return {} if $full_path eq '/';

    # Try to find parent path ( or parent of parent path or ... ) with flags definition.
    # This flags should be already processed (paths_with_processed_flags).
    my $path = $full_path;
    while ( my ( $parent_path ) = $path =~ m{ ^ (.+) \/ [^\/]+ $ }x ) {

        if ( exists $self->{paths_with_processed_flags}->{ $parent_path } ) {
            return $self->{paths_with_processed_flags}->{ $parent_path };
        }

        if ( exists $self->{paths}->{ $parent_path }->{flags} ) {
            print " >>> error $self->{paths}->{$parent_path}->{flags}\n";
            return \%{ $self->{paths}->{ $parent_path }->{flags} };
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


=head2 get_dir_items

Load directory items list. Subclassed by L<SysFink::ScanHostTest> for testing.

=cut

sub get_dir_items {
    my ( $self, $dir_name ) = @_;

    # Load direcotry items list.
    my $dir_handle;
    if ( not opendir($dir_handle, $dir_name) ) {
        $self->add_error("Directory '$dir_name' not open for read.");
        return 0;
    }
    my @all_dir_items = readdir($dir_handle);
    close($dir_handle);

    my @dir_items = ();
    foreach my $item ( @all_dir_items ) {
        next if $item eq '.';
        next if $item eq '..';
        next if $item =~ /^\s*$/;
        push @dir_items, $item;
    }

    return \@dir_items;
}


=head2 my_lstat

Encapsulate 'lstat' function. Subclassed by L<SysFink::ScanHostTest> for testing.

=cut

sub my_lstat {
    my ( $self, $full_path ) = @_;

    # Root path '' is '/' for lstat.
    my $lstat_full_path = $full_path;
    $lstat_full_path = '/' unless $full_path;
    
    my @lstat = lstat( $lstat_full_path );
    return ( 0 ) unless scalar @lstat;
    return ( 1, @lstat );
}


=head2 add_item_and_send_if_needed

Loads item (directory, file, symlink, ... ) information. Push it to result buffer.
Send result buffer if its full enought.

=cut

sub add_item_and_send_if_needed {
    my ( $self, $full_path, $flags, $add_it, $debug_prefix ) = @_;

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

    my ( $path_exists, $dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks ) = $self->my_lstat( $full_path );
    
    unless ( $path_exists ) {
        print "Can't lstat '$full_path'. Path probably doesn't exists.\n" if $self->{debug_out} >= 6;
        return ( 0, undef );
    }
    
    print $debug_prefix."  mode '$mode', nlink '$nlink', uid '$uid', gid '$gid', size '$size'\n" if $self->{debug_out} >= 3;
    #print $debug_prefix."  atime '$atime', mtime '$mtime', ctime '$ctime'\n" if $self->{debug_out} if $self->{debug_out} >= 3;
    #print $debug_prefix."  dev '$dev', ino '$ino', rdev '$rdev', size '$size', blksize '$blksize', blocks '$blocks'\n" if $self->{debug_out} if $self->{debug_out} >= 3;

    my $is_dir = S_ISDIR($mode);
    
    return ( 1, $is_dir ) unless $add_it;

    my $tmp_full_path = $full_path;
    $tmp_full_path = '/' unless $full_path;
    my $item_info = {
        path => $tmp_full_path,
        mode => $mode,
    };

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
        # flag S - file size
        if ( $flags->{S} eq '+' && $size > 0 ) {
            $item_info->{size} = $size;
        }

        # flag 5 - file md5 sum
        if ( $flags->{5} eq '+' ) {
            my $hash = $self->{hash_obj}->hash_file( $full_path );
            $item_info->{hash} = $hash;
        }
    }

    # flag U - user
    if ( $flags->{U} eq '+' ) {
        $item_info->{uid} = $uid;
        my $user_name = undef;
        $user_name = getgrgid( $uid ) if defined $uid;
        $item_info->{user_name} = $user_name if defined $user_name;
    }

    # flag G - group
    if ( $flags->{G} eq '+' ) {
        $item_info->{gid} = $gid;
        my $group_name = undef;
        $group_name = getgrgid( $gid ) if defined $gid;
        $item_info->{group_name} = $group_name if defined $group_name;
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
        $item_info->{dev_num} = $dev;
        $item_info->{ino_num} = $ino;
    }

    # B - do backup this item
    # Add nothing special here.

    push @{ $self->{loaded_items} }, $item_info;

    if ( scalar(@{$self->{loaded_items}}) >= $self->{max_items_in_one_response} ) {
        $self->send_state( 0 );
    }

    return ( 1, $is_dir );
}


=head2 processs_path_regexes

Try each regex on given path and join flags for those which match.

=cut

sub process_path_regexes {
    my ( $self, $debug_prefix, $regexes_conf, $full_path, $base_flags, $base_plus_found ) = @_;

    my $add_dir = 0;
    my $flags = { %$base_flags };
    my $plus_found = $base_plus_found;
    
    foreach my $regex_conf ( @$regexes_conf ) {
        my ( $regex, $regex_flags, $is_recursive ) = @$regex_conf;
        print $debug_prefix."  trying '$regex' $is_recursive\n" if $self->{debug_out} >= 10;

        # Recursive regex should be checked recursive.
        $add_dir = 1 if $is_recursive;

        if ( $full_path =~ /^$regex$/ ) {
            print $debug_prefix."  matched with '$regex', '" . $self->flags_hash_to_str( %$regex_flags ) . "'\n" if $self->{debug_out} >= 9;
            ( $flags, $plus_found ) = $self->join_flags( $flags, $regex_flags );
        }
    }
    return ( $add_dir, $flags, $plus_found );
}


=head2 scan_recurse

Start recursive scanning from given path.

=cut

sub scan_recurse {
    my ( $self, $recursion_depth, $dir_name, $dir_flags, $dir_regexes ) = @_;

    # Prepare debug prefix string.
    my $debug_prefix;
    $debug_prefix = '  ' x $recursion_depth if $self->{debug_out};

    # Print some debug output.
    if ( $self->{debug_out} > 4 ) {
        print "\n";
        print "in '$dir_name' ($recursion_depth), base flags '" . $self->flags_hash_to_str( %$dir_flags ) . "':\n";

    } elsif ( $self->{debug_out} == 4 ) {
        print "$dir_name\n";
    }

    # Directory number limit (this is not file number limit nor recursion limit).
    # Depends on client memory (and swap) size.
    if ( ( $self->{debug_out} && $self->{all_loaded_items_num_offset} > 1_000 )
         || ( defined $self->{debug_recursion_limit} && $self->{all_loaded_items_num_offset} > $self->{debug_recursion_limit} )
    ) {
        unless ( $self->{debug_data}->{recursive_limit} ) {
            $self->add_error("No all files. Recursion limit reached!");
            $self->{debug_data}->{recursive_limit} = 1;
        }
        return 1;
    }

    # Canonize directory path;
    $dir_name = $self->get_canon_dir( $dir_name );
    #$self->dump( $dir_name ); # debug

    # Load directory items.
    my $dir_items = $self->get_dir_items( $dir_name );
    return 0 unless ref $dir_items;


    # Sub dirs to follow using recursive call of this sub.
    my $sub_dirs = [];

    # For each directory item loop. Add items to result buffer and prepare dir list 
    # (and their flags config) for recursive scanning. 
    my $full_path;
    ITEM: foreach my $name ( sort @$dir_items ) {
        $full_path = $dir_name . $name;
        print $debug_prefix."item '$full_path'\n" if $self->{debug_out} >= 2;

        # Get path flags. Use parent's flags as default.
        my ( $flags, $plus_found ) = $self->get_flags( $full_path, $dir_flags );
        print $debug_prefix."  flags '" . $self->flags_hash_to_str( %$flags ) . "' (plus_found=$plus_found)\n" if $self->{debug_out} >= 5;
        
        my $add_dir = 0;
        $add_dir = 1 if $plus_found;

        if ( (defined $dir_regexes) && @$dir_regexes ) {
            my ( $tmp_add_dir );
            ( $tmp_add_dir, $flags, $plus_found ) = $self->process_path_regexes( $debug_prefix, $dir_regexes, $full_path, $flags, $plus_found );
            print $debug_prefix."  regex process results add_dir=$tmp_add_dir, flags='" . $self->flags_hash_to_str( %$flags ) . "', plus_found=$plus_found\n" if $self->{debug_out} >= 5;
            $add_dir = 1 if $tmp_add_dir;
        }

        # Get item (directory, file, symlink, ...) info. Send results if buffer is full.
        my ( $ret_code, $is_dir ) = $self->add_item_and_send_if_needed(
            $full_path, 
            $flags,      
            $plus_found, # $add_it
            $debug_prefix
        );
        # Check if stat not failed.
        next ITEM unless $ret_code;

        if ( $is_dir && $add_dir ) {
            # ToDo - why not '$flags' only instead of '{ %$flags }' ?
            push @$sub_dirs, [ $full_path, { %$flags } ];
        }
    }

    $sub_dirs = [ sort { $a->[0] cmp $b->[0] } @$sub_dirs ];
    
    # For each subdirectory also run this method (scan_recurse).
    SUB_DIR: foreach my $sub_dir_data ( @$sub_dirs ) {
        my ( $sub_dir_path, $sub_dir_flags ) = @$sub_dir_data;
        
        my $content_full_path = $sub_dir_path . '/';
        my ( $content_flags, $content_plus_found ) = $self->get_flags( $content_full_path, $sub_dir_flags );
        print $debug_prefix."  '$sub_dir_path' dir content flags '" . $self->flags_hash_to_str( %$content_flags ) . "' (plus_found=$content_plus_found)\n" if $self->{debug_out} >= 3;

        my $scan_content = $content_plus_found;

        my $content_regexes = [];
        # Add recursive regexes.
        foreach my $regex_conf ( @$dir_regexes ) {
            if ( $regex_conf->[3] ) {
                $scan_content = 1;
                push @$content_regexes, $regex_conf;
            }
        }
        
        if ( exists $self->{paths}->{ $content_full_path }->{regexes} ) {
            $scan_content = 1;
            # Add all path regexes.
            $content_regexes = [
                @$content_regexes,
                @{ $self->{paths}->{ $content_full_path }->{regexes} }
            ];
            # Resort by order.
            $content_regexes = [ sort { $a->[2] <=> $b->[2] } @$content_regexes ];
        }
        
        print $debug_prefix."  scan '$sub_dir_path' dir content $scan_content\n" if $self->{debug_out} >= 3;

        next SUB_DIR unless $scan_content;
        
        $self->scan_recurse(
            $recursion_depth+1,
            $sub_dir_path,
            $content_flags,
            $content_regexes
        );
    }

    return 1;
}


=head2 reset_state

Reset info about result's buffer.

=cut

sub reset_state {
    my ( $self, $full_reset ) = @_;

    if ( $full_reset ) {
        $self->{all_loaded_items_num_offset} = 0;
    } else {
        $self->{all_loaded_items_num_offset} += scalar( @{$self->{loaded_items}} );
    }

    $self->{loaded_items} = [];
    $self->{errors} = [];

    return 1;
}


=head2 send_state

Send actual result's buffer.

=cut

sub send_state {
    my ( $self, $is_last ) = @_;

    my $result = {
        loaded_items => $self->{loaded_items},
        errors => $self->{errors},
    };
    my $ret_code = $self->send_ok_response( $result, $is_last );
    $self->reset_state( 0 );
    return $ret_code;
}


=head2 scan

Main scanning part. Call 'scan_recurse' method for each path in given paths 
configuration.

=cut

sub scan {
    my ( $self ) = @_;

    my $ret_code;
    PATH_CONF: foreach my $conf_full_path ( sort keys %{ $self->{paths} } ) {
        my $full_path = $conf_full_path;
        $full_path =~ s{\/$}{};
        print "\n===> conf path: '$conf_full_path'\n" if $self->{debug_out} >= 5;
        
        # Skip already scanned items. E.g. will skip '/a/b' here for config 
        # include '/a', include '/a/b', because '/a/b' is found during '/a' scanning.
        # But do not skip '/a/b/c' here for config include '/a', exclude '/a/b', 
        # include '/a/b/c'.
        next PATH_CONF if exists $self->{paths_with_processed_flags}->{ $conf_full_path };

        # Get path flags. Use parent's flags as default.
        my $parent_flags = $self->get_parent_path_flags( $conf_full_path );
        my ( $flags, $plus_found ) = $self->get_flags( $conf_full_path, $parent_flags );
        print " >>> '$conf_full_path' flags '" . $self->flags_hash_to_str( %$flags ) . "' (plus_found=$plus_found)\n" if $self->{debug_out} >= 3;

        my $is_dir = 1;
        # Add item to results.
        # Get item (directory, file, symlink, ...) info. Send results if buffer is full.
        my $s_ret_code;
        ( $s_ret_code, $is_dir ) = $self->add_item_and_send_if_needed( 
            $full_path, 
            $flags,      
            $plus_found, # $add_it
            ''           # $debug_prefix
        );
        next PATH_CONF unless $s_ret_code;

        # Start recursive scanning for this directory.
        if ( $is_dir ) {

            my $content_full_path = $full_path . '/';
            my ( $content_flags, $content_plus_found ) = $self->get_flags( $content_full_path, $flags );
            print "  >>> '$content_full_path' content flags '" . $self->flags_hash_to_str( %$content_flags ) . "' (plus_found=$content_plus_found)\n" if $self->{debug_out} >= 3;
            
            my $scan_content = 0;
            if ( $content_plus_found ) {
                $scan_content = 1;
            } elsif ( exists $self->{paths}->{ $content_full_path }->{regexes} ) {
                $scan_content = 1;
            }
            print "  >>> '$content_full_path' scan_content $scan_content\n" if $self->{debug_out} >= 3;

            next PATH_CONF unless $scan_content;

            $ret_code = $self->scan_recurse(
                0,
                $full_path,
                $content_flags,
                $self->{paths}->{ $content_full_path }->{regexes}
            );
        }

        last unless $ret_code;
    }

    $self->send_state( 1 ) if scalar(@{$self->{loaded_items}}) > 0;

    return $ret_code;
}



=head2 run_scan_host

Start 'scan_host' command. Prepare all variables, reset state and call 'scan' method.

=cut

sub run_scan_host {
    my ( $self, $args ) = @_;

    $self->process_base_command_args( $args );

    $self->{max_items_in_one_response} = 1_000;
    $self->{max_items_in_one_response} = $args->{max_items_in_one_response} if defined $args->{max_items_in_one_response};

    $self->{debug_recursion_limit} = undef;
    $self->{debug_recursion_limit} = $args->{debug_recursion_limit} if defined $args->{debug_recursion_limit};


    $self->{paths} = $args->{paths};
    $self->{paths_with_processed_flags} = {};

    unless ( exists $self->{paths}->{''} ) {
        $self->add_error("Base path not found.");
        return 0;
    }

    #$self->send_ok_response( { info => 'parameters are ok', } );

    $self->reset_state( 1 );
    return $self->scan();
}


1;
