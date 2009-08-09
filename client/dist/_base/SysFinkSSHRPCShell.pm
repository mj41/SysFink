package Sysfink::SSH::RPC::Shell;

use base 'SSH::RPC::Shell::PP::JSON';

use strict;
use SysFinkFileHash; # SysFink::FileHash


sub new {
    my ($class, $ver, $md5sum_path) = @_;

    my $self = $class->SUPER::new( $ver );
    $self->{hash_obj} = SysFink::FileHash->new( $md5sum_path );
    return $self;
}


sub run_hash_file {
    my ( $self, $file ) = @_;
    my $hash = $self->{hash_obj}->hash_file( $file );
    return $self->pack_ok_response( hash => $hash );
}


sub run_hash_type {
    my ( $self ) = @_;
    my $type = $self->{hash_obj}->hash_type();
    return $self->pack_ok_response( type => $type );
}


sub run_hash_type_desc {
    my ( $self ) = @_;
    my $type = $self->{hash_obj}->hash_type_desc();
    return $self->pack_ok_response( type_desc => $type );
}


1;
