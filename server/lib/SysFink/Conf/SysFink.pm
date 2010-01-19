package SysFink::Conf::SysFink;

use strict;
use warnings;

use lib '../client/lib';
use base 'SysFink::Conf';

use File::Spec::Functions;


=head1 NAME

SysFink::Conf::SysFink - SysFink configuration class for SysFink config format.

=head1 SYNOPSIS

ToDo

=head1 DESCRIPTION

ToDo

=head1 METHODS


=head2 new

Constructor. Parameters: conf_dir_path.

=cut

sub new {
    my ( $class, $params ) = @_;

    my $self = $class->SUPER::new( $params, @_ );
    $self->{conf_dir_path} = $params->{conf_dir_path};
    $self->{conf_dir_path} = $self->{temp_dir} . '../sysfink-conf/' unless defined $self->{conf_dir_path};

    $self->{keyword_flags} = $self->get_default_keyword_flags();

    $self->{conf} = {};
    $self->{conf_meta} = {};

    return $self;
}


sub conf {
    my $self = shift;
    if (@_) { $self->{conf} = shift }
    return $self->{conf};
}


sub conf_meta {
    my $self = shift;
    if (@_) { $self->{conf_meta} = shift }
    return $self->{conf_meta};
}


sub clear_conf {
    my $self = shift;
    $self->{conf} = {};
    $self->{conf_meta} = {};
    return 1;
}


sub get_file_content {
    my ( $self, $fpath ) = @_;

    my $fh;
    unless ( open( $fh, '<', $fpath ) ) {
        $@ = "Can't open file '$fpath': $!";
        return undef;
    }
    my $content;
    {
        local $/ = undef;
        $content = <$fh>;
    }
    close $fh;
    return $content;
}


sub get_files_rh_for_dir {
    my ( $self, $dir_path ) = @_;

    my $dir_handle;
    unless ( opendir($dir_handle, $dir_path) ) {
        $@ = "Directory '$dir_path' not open for read.";
        return undef;
    }
    my @items = readdir($dir_handle);
    close($dir_handle);

    my $rh_files = {};
    foreach my $item ( @items ) {
        my $item_path = catfile( $dir_path, $item );
        next unless -f $item_path;
        $rh_files->{$item} = $item_path;
    }
    return $rh_files;
}


=head2 get_default_root_flags

Return hash of default flags (flags for '/' path).

=cut

sub get_default_root_flags {
    my ( $this ) = @_;

    my $keyword_flags = $this->get_keyword_flags();
    my $flags_str = $keyword_flags->{'include'};
    my %flags_hash = $this->flags_str_to_hash( $flags_str );
    return %flags_hash;
}


=head2 join_path_and_flags

Join $path and $flags_str to one string.

=cut

sub join_path_and_flags {
    my ( $this, $path, $flags_str ) = @_;
    return $path . '[' . $flags_str . ']';
}


=head2 conf_dir_path

Set/get conf_dir_path.

=cut

sub conf_dir_path {
    my $self = shift;
    if (@_) { $self->{conf_dir_path} = shift }
    return $self->{conf_dir_path};
}


=head2 canon_joined_flag_strs

Canonize flag strings joined together. E.g. -B+B+S-S-B -> -B-S.

=cut

sub canon_joined_flag_strs {
    my ( $self, $flags_str ) = @_;

    my %flags = $self->flags_str_to_hash( $flags_str );
    my $out_flags_str = $self->flags_hash_to_str( %flags );
    return $out_flags_str;

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


=head2 get_keyword_flags

TODO ...

=cut

sub get_keyword_flags {
    my ( $self, $keyword_name, $flags_and_path ) = @_;

    my $path = undef;

    my %flags = $self->flags_str_to_hash( $self->{keyword_flags}->{ $keyword_name } );

    # Try to split the flags and path.
    if ( my ( $t_flags, $t_path ) = $flags_and_path =~ m{^ \[ (.+?) \] (.*) $}x ) {
        $path = $t_path if $t_path;

        my %acc_flags = $self->flags_str_to_hash( $t_flags );
        foreach my $key ( keys %acc_flags ) {
            $flags{$key} = $acc_flags{$key};
        }

    } else {
        $path = $flags_and_path;
    }

    my $flags_str = $self->flags_hash_to_str( %flags );
    return ( $flags_str, $path );
}


=head2 canon_path

Canonize path.

=cut

sub canon_path {
    my ( $self, $path ) = @_;

    return '' unless $path;

    # Remove many slashes in sequence.
    $path =~ s{ \/{2,} }{\/}gx;
    # Remove dot directories.
    $path =~ s{ \/\.\/ }{\/}gx;

    return $path;
}



=head2 splitq

Split values from one line (eg line fld1, "fld \"fld5" fld7 produces array ("fld1", "fld \"fld5", "fld7"). Accept quotes.

=cut

sub splitq {
    my ( $self, $str ) = @_;

    my $debug = 0;

    my @parts = ();
    my $part_num = 0;
    my $state_names = [
        'part start',       # 0
        'in string',        # 1
        'in quoted string', # 2
        'char after slash in string',        # 3
        'char after slash in quoted string', # 4
    ];
    my $state = 0;
    foreach my $ch ( split(//, $str) ) {
        # in char after slash in string
        if ( $state == 3 ) {
            $parts[ $part_num ] .= $ch; # add char to part
            $state = 1; # in string

        # in char after slash in quoted string
        } elsif ( $state == 4 ) {
            $parts[ $part_num ] .= $ch; # add char to part
            $state = 2; # in quoted string

        # slash found
        } elsif ( $ch eq '\\') {
            if ( $state == 2 ) { # in quoted string
                $state = 4; # to char after slash in quoted string
            } else { # part start, in string
                $state = 3; # to char after slash in string
            }

        # quote found
        } elsif ( $ch eq '"' ) {
            if ( $state == 2 ) { # in quoted string
                $state = 0; # to part start
            } else {
                $state = 2; # to in quoted string
            }

        # (space or delimiter) and not in quoted string
        } elsif ( $ch =~ /[\s,]/ && $state != 2 ) {
            if ( $parts[$part_num] ) { # prev part has content
                $part_num++;
            }
            $state = 0; # to part start

        # other char
        } else {
            # add char to part
            if ( defined($parts[$part_num]) ) {
                $parts[$part_num] .= $ch;
            } else {
                $parts[$part_num] = $ch;
            }
            $state = 1 if $state == 0;
        }

        if ( $debug ) {
            my $state_name = $state_names->[ $state ];
            print "ch: '$ch', part_num:$part_num, state: $state ($state_name)\n";
        }
    }

    if ( $debug ) {
        require Data::Dumper;
        print Data::Dumper->Dump( [ \@parts ] );
    }
    return @parts;
}


=head2 process_config_file_content

Process text/config. Load included files by use keyword.

=cut

sub process_config_file_content {
    my ( $self, $host_name, $file_content, $recursion_deep, $section ) = @_;


    if ( $recursion_deep > 10 ) {
        $@ = "Recursion limit reached.";
        return 0;
    }

    $self->{conf}->{$host_name} = {} unless defined $self->{conf}->{$host_name};
    my $host_conf = $self->{conf}->{$host_name};

    my @lines = split( /\n/, $file_content );

    $section = 'general' unless defined $section;
    foreach my $line_num ( 0..$#lines ) {
        my $line = $lines[ $line_num ];
        chomp $line;

        # Skip blank lines
        next if $line =~ /^\s*$/;

        # Ignore characters after # and ;
        next if $line =~ /^\s*(\#|\:)/;

        if ( $line =~ m/^ \s* \[ /x ) {
            if ( my ( $t_section ) = $line =~ m/^ \s* \[ \s* ([^\]]+) \s* \] \s* $/x ) {
                $section = lc $t_section;

                # initialization
                $host_conf->{$section} = {} unless defined $host_conf->{$section};

                next;
            } else {
                $@ = "Error on line '$line'. Begin char [ found, but no section def.";
                return 0;
            }
        }

        my ( $key, @vals ) = $self->splitq( $line );
        $key = lc $key;

        # include file
        if ( $key eq 'use' ) {
            foreach my $val ( @vals ) {
                my $inc_fpath = catfile( $self->{conf_dir_path}, $val );

                unless ( -f $inc_fpath ) {
                    $@ = "Config file '$inc_fpath' included in config for host '$host_name' not found.";
                    return 0;
                }

                my $inc_file_content = $self->get_file_content( $inc_fpath );
                return 0 unless defined $inc_file_content;
                my $ret_code = $self->process_config_file_content( $host_name, $inc_file_content, $recursion_deep + 1, $section );
                return $ret_code unless $ret_code;
            }
            next;
        }


        # Process keywords such as path, include, exclude, backup, ...
        if ( defined($self->{keyword_flags}->{$key}) ) {
            foreach my $val ( @vals ) {
                # Set default flags for this keyword and combine it with flags set by user.
                my ( $flags, $path ) = $self->get_keyword_flags(
                    $key, # $keyword_name
                    $val  # $flags_and_path
                );
                $path = $self->canon_path( $path );
                push @{$host_conf->{$section}->{'paths'} }, [ $path, $flags ];
            }
            next;
        }

        # add values into config
        unless ( defined($host_conf->{$section}->{$key}) ) {
            #use Data::Dumper; print Dumper( \@vals );

            unless ( defined $vals[1] ) {
                $host_conf->{$section}->{$key} = $vals[0];
            } else {
                $host_conf->{$section}->{$key} = [ @vals ];
            }
        } else {
            # change one value to array containing one value
            if ( ref $host_conf->{$section}->{$key} ne 'ARRAY' ) {
                $host_conf->{$section}->{$key} = [ $host_conf->{$section}->{$key} ];
            }
            push @{$host_conf->{$section}->{$key}}, @vals;
        }
    }

    $self->{conf}->{$host_name} = $host_conf;
    return 1;
}


=head2 process_config_file

Process one config file.

=cut

sub process_config_file {
    my ( $self, $host_name, $fpath ) = @_;

    print "Loading config for '$host_name' ('$fpath').\n" if $self->{ver} >= 5;

    $self->{conf_meta}->{$host_name} = {
        'fpath' => $fpath
    };

    my $file_content = $self->get_file_content( $fpath );
    return 0 unless defined $file_content;
    return $self->process_config_file_content(
        $host_name,
        $file_content,
        0,      # $recursion_deep
        undef   # $section
    );
}


sub _load_one_config_file {
    my ( $self, $fname ) = @_;

    my $fpath = catfile( $self->{conf_dir_path}, $fname );
    unless ( -f $fpath ) {
        $@ = "Config file '$fpath' not found.";
        return 0;
    }

    my $host_name = $fname;
    return $self->process_config_file( $host_name, $fpath );
}


=head2 normalize_paths

Sort path parts. Add '/' as first (default) directory if not found.

=cut

sub normalize_paths {
    my ( $self, $host_name ) = @_;

    my $host_conf = $self->{conf}->{ $host_name };

    return 1 unless $host_conf;

    my ( $def_flags, $def_path )  = ( undef, undef );
    foreach my $section ( keys %$host_conf ) {
        my $sec_conf = $host_conf->{ $section };

        if ( exists $sec_conf->{paths} ) {
            # Lazy loading.
            unless ( defined $def_flags ) {
                ( $def_flags, $def_path ) = $self->get_keyword_flags( 'include', '' );
            }

            # Sort it.
            $sec_conf->{paths} = [ sort { $a->[0] cmp $b->[0] } @{$sec_conf->{paths}} ];

            # If first item isn't root path ('').
            if ( $sec_conf->{paths}->[0]->[0] ne '' ) {
                unshift @{$sec_conf->{paths}}, [ $def_path, $def_flags ];

            } else {
                my $base_flag_str = $def_flags . $sec_conf->{paths}->[0]->[1];
                $sec_conf->{paths}->[0]->[1] = $self->canon_joined_flag_strs( $base_flag_str );
            }

            #use Data::Dumper; print Dumper( $sec_conf->{paths} ); # debug

            my @str_paths;
            my $last_num = $#{ $sec_conf->{paths} };

            my ( $prev_path, $prev_flags_str ) = @{ $sec_conf->{paths}->[ 0 ] };
            foreach my $num ( 1..$last_num ) {
                my ( $path, $flags_str ) = @{ $sec_conf->{paths}->[ $num ] };

                #print "$prev_path - $path, $prev_flags_str - $flags_str\n"; # debug

                # Previous path is same as new.
                if ( $prev_path eq $path ) {
                    $prev_flags_str .= $flags_str;
                    next;
                }

                # Path changed -> save previous.
                my $canon_flags_str = $self->canon_joined_flag_strs( $prev_flags_str );
                push @str_paths, $self->join_path_and_flags( $prev_path, $canon_flags_str );
                $prev_path = $path;
                $prev_flags_str = $flags_str;
            }

            # Last one.
            my $canon_flags_str = $self->canon_joined_flag_strs( $prev_flags_str );
            push @str_paths, $self->join_path_and_flags( $prev_path, $canon_flags_str );

            $sec_conf->{paths} = \@str_paths;
            #use Data::Dumper; print Dumper( $sec_conf->{paths} ); # debug
        }
    }

    #use Data::Dumper; print Dumper( $host_conf ); exit;
    return 1;
}


=head2 load_config

Load all config files (or selected by first parameter) from config directory.

Apply process_config_file and normalize_config for each one loaded.

=cut

sub load_config {
    my ( $self, $host_name ) = @_;

    unless ( -d $self->{conf_dir_path} ) {
        $@ = "Config directory '$self->{conf_dir_path}' not found.";
        return 0;
    }

    if ( $host_name ) {
        my $config_fname = $host_name;
        return $self->_load_one_config_file( $config_fname );
    }

    my $rh_files = $self->get_files_rh_for_dir( $self->{conf_dir_path} );
    return 0 unless ref $rh_files;

    foreach my $fname ( keys %$rh_files ) {
        my $fpath = $rh_files->{$fname};
        my $host_name = $fname;
        my $ret_code;

        $ret_code = $self->process_config_file( $host_name, $fpath );
        unless ( $ret_code ) {
            print $@;
            return 0;
        }

        $ret_code = $self->normalize_paths( $host_name );
        unless ( $ret_code ) {
            print $@;
            return 0;
        }
    }
    return 1;
}


=head1 SEE ALSO

L<SysFink::Conf>, L<SysFink>

=head1 LICENSE

This file is part of SysFink. See L<SysFink> license.

=cut


1;
