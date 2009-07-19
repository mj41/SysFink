package SysFink::Conf::SysFink;

use strict;
use warnings;
use File::Spec::Functions;

use base 'SysFink::Conf';

=head1 METHODS

=head2 new

Constructor. Parameters: conf_dir_path.

=cut

sub new {
    my ( $class, $params ) = @_;

    my $self = $class->SUPER::new( $params, @_ );
    $self->{conf_dir_path} = $params->{conf_dir_path};
    $self->{conf_dir_path} = $self->{temp_dir} . '../sysfink-conf/' unless defined $self->{conf_dir_path};

    $self->{default_flags} = get_default_flags();

    bless $self, $class;
    return $self;
}


=head2 get_default_flags

Default flags and flags aliases definition. These aliases can be used in a config files.

=cut

sub get_default_flags {
    return {
        'include'   => '[+UGM5TL]',
        'exclude'   => '[-UGM5TL]',
        'backup'    => '[+B]',
        'path'      => "[]"
    };
}


=head2 conf_dir_path

Set/get conf_dir_path.

=cut

sub conf_dir_path {
    my $self = shift;
    if (@_) { $self->{conf_dir_path} = shift }
    return $self->{conf_dir_path};
}


# add flags into the path, compute flags to the path
# @ arg        - flags prefix also possible (eg. "/usr", "[+M+G]/usr", "[+M-G+U+T]", "[-M+T]", ...)
# return flags - result flags enclosed in []
# return path  - path in clear forrmat  - if input path not defined returns undef
#
sub add_flags {
    my ( $self, @args ) = @_;

    my $path = undef;
    my %flags;

    # traverse all arguments
    foreach my $arg ( @args ) {
        # try to split the path and flags from arguments
        if ( my ( $t_flags, $t_path ) = $arg =~ /\[(.+)\]\s*(.*)/ ) {
            $path = $t_path if $t_path;
            %flags = $self->get_flags( $t_flags );
        } else {
            $path = $arg;
        }
    }

    my $sflags = '';
    while ( my ($key, $val) = each %flags ) {
        $sflags .= sprintf( "%1s%1s", $val, $key );
    }

    $sflags = "[".$sflags."]";
    return ( $sflags, $path );
}


# return hash with possitive flags set
# @ flags - input string with flags inf ormat [+x+x...]
# @ mask  - +      return only possive flags,
#           -      return only negative flags,
#           undef  return the positive and negative flags
sub get_flags {
    my ( $self, $flags, $mask ) = @_;

    my %flags;

    $flags =~ s/^\[//;
    $flags =~ s/\]$//;

    my $sign = undef;
    my @flags = split( //, $flags );
    foreach my $flag ( @flags ) {
        $flag = uc( $flag );
        # the sign symbol
        if ( $flag eq '+' || $flag eq '-' ) {
            $sign = $flag;

        } elsif ( defined($sign) && ( !defined($mask) || $sign eq $mask) ) {
            $flags{ $flag } = $sign;
        }
    }

    return %flags;
}



# convert a shell patter to a regexp pattern
sub glob2pat {
    my ( $self, $globstr ) = @_;
    my %patmap = (
        '*' => '.*',
        '?' => '.',
        '[' => '[',
        ']' => ']',
    );
    $globstr =~ s{(.)} { $patmap{$1} || "\Q$1" }ge;
    return '^' . $globstr . '$';
}


# split values with accept quotes (eg line fld1, "fld \"fld5" fld7 produces array ("fld1", "fld \"fld5", "fld7")
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


sub process_config_file_content {
    my ( $self, $host_name, $file_content ) = @_;

    my $host_conf = {};

    my @lines = split( /\n/, $file_content );

    my $section = 'general';
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
        if ( $key eq "use" ) {
            # todo
            #foreach (@val) { load_config($sysname, $line); }
            next;
        }


        # process fields path, include, exclude, backup, ...
        if ( defined($self->{default_flags}->{$key}) ) {
            foreach my $val ( @vals ) {
                # set default flags and combine it with flags set by user
                my ($flags, $path) = $self->add_flags( $self->{default_flags}->{$key}, $val );

                $path = $self->glob2pat( $path );

                # combine the current flags with a previously set flags
                push @{$host_conf->{$section}->{'paths'} }, $flags.$path;
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


sub process_config_file {
    my ( $self, $host_name, $fpath ) = @_;

    print "Loading config for '$host_name' ('$fpath').\n" if $self->{debug};

    $self->{conf_meta}->{$host_name} = {
        'fpath' => $fpath
    };

    my $file_content = $self->get_file_content( $fpath );
    return 0 unless defined $file_content;
    return $self->process_config_file_content( $host_name, $file_content );
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


=head2 load_config

Load all config files (or selected by first parameter) from config directory.

Apply process_config_file for each loaded.

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
        my $ret_code = $self->process_config_file( $host_name, $fpath );
        return 0 unless $ret_code;
    }
    return 1;
}


=head1 NAME

SysFink::Conf::SysFink - SysFink configuration class for SysFink config format.

=head1 SYNOPSIS

See L<SysFink::Conf>

=head1 DESCRIPTION

SysFink server.

=head1 SEE ALSO

L<SysFink::Conf>, L<SysFink>

=head1 LICENSE

This file is part of SysFink. See L<SysFink> license.

=cut


1;
