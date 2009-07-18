package SysFink::Conf;

use strict;
use warnings;
use File::Spec::Functions;


sub new {
    my $class = shift;
    my $params = shift;

    my $self  = {};

    $self->{debug} = $params->{debug};

    $self->{conf} = {};
    $self->{conf_meta} = {};

    bless $self, $class;
    return $self;
}


sub debug {
    my $self = shift;
    if (@_) { $self->{debug} = shift }
    return $self->{debug};
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


sub load_config {
    my ( $self, $host_name ) = @_;
    $@ = 'Your class should implement this method.';
    return 0;
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


=head1 NAME

SysFink::Conf - Base class for SysFink configuration modules.

=head1 SYNOPSIS

See L<SysFink>

=head1 DESCRIPTION

SysFink server.

=head1 SEE ALSO

L<SysFink>

=head1 LICENSE

This file is part of SysFink. See L<SysFink> license.

=cut


1;
