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

    bless $self, $class;
    return $self;
}


=head2 conf_dir_path

Set/get conf_dir_path.

=cut

sub conf_dir_path {
    my $self = shift;
    if (@_) { $self->{conf_dir_path} = shift }
    return $self->{conf_dir_path};
}


sub process_config_file_content {
    my ( $self, $fname, $fpath ) = @_;

    print "Loading '$fname' ('$fpath').\n" if $self->{debug};

    $self->{conf_meta}->{$fname} = {
        'fpath' => $fpath
    };

    $self->{conf}->{$fname} = {
    };

    return 1;
}


sub _load_one_config_file {
    my ( $self, $fname ) = @_;

    my $fpath = catfile( $self->{conf_dir_path}, $fname );
    unless ( -f $fpath ) {
        $@ = "Config file '$fpath' not found.";
        return 0;
    }

    return $self->process_config_file_content( $fname, $fpath );
}


=head2 load_config

Load all config files (or selected by first parameter) from config directory.

Apply process_config_file_content for each loaded.

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
        my $ret_code = $self->process_config_file_content( $fname, $fpath );
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
