package SysFink::FileHash::Base;

our $VERSION = 0.01;

use strict;
use base 'SSH::RPC::Shell::PP::Cmd::BaseJSON';


sub run_hash_file {
    my ( $self, $file_path ) = @_;
    my $hash = $self->hash_file( $file_path );
    return $self->pack_ok_response( { hash => $hash, }, 1 );
}


sub run_hash_type {
    my ( $self ) = @_;
    my $type = $self->hash_type();
    return $self->pack_ok_response( { type => $type, }, 1 );
}


sub run_hash_type_desc {
    my ( $self ) = @_;
    my $type_desc = $self->hash_type_desc();
    return $self->pack_ok_response( { type_desc => $type_desc, }, 1 );
}


1;
