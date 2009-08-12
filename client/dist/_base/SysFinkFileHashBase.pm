package SysFink::FileHash::Base;

our $VERSION = 0.01;


sub new {
    my ( $class, $shared_data, $md5sum_util_path ) = @_;

    my $self  = {};
    $self->{shared_data} = $shared_data;
    $self->{md5sum_util_path} = $md5sum_util_path;

    bless( $self, $class );
    return $self;
}


sub hash_file {
    my ( $self, $file_path ) = @_;

    my $cmd = $self->{md5sum_util_path} . '/sysfink-md5sum';
    my $out = `$cmd "$file_path"`;
    my ( $hash ) = $out =~ /^\s*(\S+)/;
    return $hash;
}


1;
