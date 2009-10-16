package SysFink::FileHashTest;

sub new {
    my ( $class ) = @_;

    my $self  = {};
    bless( $self, $class );
    return $self;
}


sub hash_type {
    return 'hash-fake';
}


sub hash_type_desc {
    return 'Fake hash function for testing.';
}


sub hash_file {
    my ( $self, $fpath ) = @_;
    return substr( 'HASH:' . $fpath, 0, 50 );
}


1;
