package SysFink::Conf;

use strict;
use warnings;

use File::Spec::Functions;

=head1 NAME

SysFink::Conf - Base class for SysFink configuration.

=head1 SYNOPSIS

ToDo. See L<SysFink>.

=head1 DESCRIPTION

ToDo. See L<SysFink>.

=head1 METHODS


=head2 new

Constructor. Parameters: conf_dir_path.

=cut

sub new {
    my ( $class, $params ) = @_;

    my $self  = {
        ver => 3,
    };
    $self->{ver} = $params->{ver} if defined $params->{ver};

    bless $self, $class;
    return $self;
}


=head2 get_flag_desc

Default flags and flags aliases definition. These aliases can be used in a config files.

If item has any of flags sets, then item is scanned and inserted to result list.

Default:
* uid - user id
* gid - group id
* mode - ls string, eg. drwxr-x---

Items of any type:
* U - user
* G - group
* M - mtime

* H - hard links number
* D - major and minor device number
* B - do backup this item

Regular files only:
* 5 - file md5 sum
* S - file size

Symlinks only:
* L - symlink path

=cut

sub get_flag_desc {
    my ( $this, $flag ) = @_;

    my %flags_desc = (
        'U' => 'user',
        'G' => 'group',
        'M' => 'mtime',
        '5' => 'file md5 sum',
        'L' => 'symlink path',

        'S' => 'file size',
        'H' => 'hard links number',
        'D' => 'major and minor device number',

        'B' => 'do backup this item',
    );
    return \%flags_desc unless $flag;
    return $flags_desc{ $flag } if exists $flags_desc{ $flag };
    return undef;
}


=head2 get_default_keyword_flags

Return hash ref with flag or flag modification for each keyword.

=cut

sub get_default_keyword_flags {
    return {
        'include'   => '+UGM5LSHD-B',
        'exclude'   => '-UGM5LSHDB',
        'backup'    => '+B',
        'path'      => ''
    };
}


=head2 flags_str_to_hash

Convert flag string to hash. Do it in characters order so canonize it.

$flags_str - input string with flags in format +x-x...

=cut

sub flags_str_to_hash {
    my ( $this, $flags_str ) = @_;

    my %flags;
    my $sign = undef;

    # Replace special chars before string to hash conversion.
    $flags_str =~ s{\-\*}{-UGM5LSHDB}g;
    $flags_str =~ s{\+\*}{+UGM5LSHDB}g;
    if ( $flags_str =~ m{\#} ) {
        my $default_keyword_flags = $this->get_default_keyword_flags();
        my $default_include_flags = $default_keyword_flags->{include};
        $flags_str =~ s{\#}{$default_include_flags}g;
    }

    my $pos = 1;
    my @flag_chars = split( //, $flags_str );
    foreach my $flag ( @flag_chars ) {
        $flag = uc( $flag );
        # the sign symbol
        if ( $flag eq '+' || $flag eq '-' ) {
            $sign = $flag;

        } elsif ( defined $sign ) {
            $flags{ $flag } = $sign;

        } else {
            # ToDo - error
            print "Unknown character '$flag' on position $pos inside '$flags_str'.";
        }
        $pos++;
    }

    return %flags;
}


=head2 process_regexp

Translate config reg_expr to perl regular expression.

=cut

sub process_regexp {
    my ( $self, $in_reg_expr ) = @_;

    my $is_recursive = 0;
    if ( $in_reg_expr =~ m{\*\*}x ) {
        $is_recursive = 1;
    } elsif ( $in_reg_expr =~ m{ [\*\?] .* \/ .* [\*\?] }x ) {
        $is_recursive = 1;
    }
    
    my $reg_expr = $in_reg_expr;

    # escape
    $reg_expr =~ s{ ([  \- \) \( \] \[ \. \$ \^ \{ \} \\ \/ \: \; \, \# \! \> \< ]) }{\\$1}gx;

    # ?
    $reg_expr =~ s{ \? }{\[\^\\/\]\?}gx;

    # *
    #$reg_expr =~ s{ (?!\*) \* (?!\*)  }{\[\^\\\/\]\*}gx;
    # * - old way
    $reg_expr =~ s{   ([^\*])  \* ([^\*])     }{$1\[\^\\\/\]\*$2}gx;
    $reg_expr =~ s{   ([^\*])  \*           $ }{$1\[^\\\/\]\*}gx;
    $reg_expr =~ s{ ^          \*  ([^\*])    }{\[\^\\\/\]\*$1}gx;

    # **
    $reg_expr =~ s{ \*{2,} }{\.\*}gx;
    
    print "Reg expr transform: '$in_reg_expr' => '$reg_expr'\n" if $self->{ver} >= 5;
    return ( $is_recursive, $reg_expr );
}


=head2 prepare_path_regexes

Prepare paths regexes.

=cut

sub prepare_path_regexes {
    my ( $self, $in_paths ) = @_;
    
    my $paths = {};
    
    # Prepare paths.
    foreach my $path_num ( 0..$#$in_paths ) {
        my $path_conf = $in_paths->[ $path_num ];
        my $full_path_expr = $path_conf->[ 0 ];

        my $full_path = $full_path_expr;
        my $reg_expr = undef;
        my $recursive_reg_expr = 0;

        if ( my ($tmp_full_path, $tmp_reg_epxr ) = $full_path_expr =~ m{^ (.*?) \/ ( [^\/]* [\*\?] .* ) $}x ) {
            if ( $tmp_reg_epxr ) {
                $full_path = $tmp_full_path . '/';
                ( $recursive_reg_expr, $reg_expr ) = $self->process_regexp( $full_path_expr );
            }
        }

        if ( not defined $reg_expr ) {
            $paths->{ $full_path }->{flags} = $path_conf->[ 1 ];

        } elsif ( ! $recursive_reg_expr ) {
            $paths->{ $full_path }->{regexes} = [] unless exists $paths->{ $full_path }->{regexes};
            push @{ $paths->{ $full_path }->{regexes} }, [ 
                $reg_expr,         # 0 - regex
                $path_conf->[ 1 ], # 1 - flags
                $path_num,         # 2 - order number
                0                  # 3 - is_recursive
            ];

        } else {
            $paths->{ $full_path }->{regexes} = [] unless exists $paths->{ $full_path }->{regexes};
            push @{ $paths->{ $full_path }->{regexes} }, [ 
                $reg_expr,         # 0 - regex
                $path_conf->[ 1 ], # 1 - flags
                $path_num,         # 2 - order number
                1                  # 3 - is_recursive
            ];
        }
    }
    #use Data::Dumper; print Dumper( $paths );
    return $paths;
}


=head1 SEE ALSO

L<SysFink>

=head1 LICENSE

This file is part of SysFink. See L<SysFink> license.

=cut


1;
