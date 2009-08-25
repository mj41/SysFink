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

    my $self  = {};
    $self->{debug} = $params->{debug};

    bless $self, $class;
    return $self;
}


sub debug {
    my $self = shift;
    if (@_) { $self->{debug} = shift }
    return $self->{debug};
}



=head2 get_flag_desc

Default flags and flags aliases definition. These aliases can be used in a config files.

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

        'B' => 'do backup this file or directory',
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

Convert flash string to hash. Do it in characters order so canonize it.

$flags_str - input string with flags in format +x-x...

=cut

sub flags_str_to_hash {
    my ( $this, $flags_str ) = @_;

    my %flags;
    my $sign = undef;
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
        }
    }

    return %flags;
}


=head1 SEE ALSO

L<SysFink>

=head1 LICENSE

This file is part of SysFink. See L<SysFink> license.

=cut


1;
