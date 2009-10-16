package SysFink::FileHash;

use base 'SysFink::FileHash::Base';


use Digest::MD5;


sub new {
    my ( $class ) = @_;

    my $self  = {};
    bless( $self, $class );
    return $self;
}


sub hash_type {
    return 'Digest::MD5';
}


sub hash_type_desc {
    return 'Perl Digest::MD5 module already installed on client system.';
}


sub hash_file {
    my ( $self, $fpath ) = @_;
    unless ( open( FH, '<', $fpath ) ) {
        print "Can't open '$fpath': $!\n" if $ver >= 2;
        return undef;
    }
    my $ctx = Digest::MD5->new;
    $ctx->addfile(*FH);
    return $ctx->hexdigest;
}


1;
