package SysFink::FileHash::BaseBinUtil;

use strict;
use base 'SysFink::FileHash::Base';


sub new {
    my ( $class, $md5sum_util_path ) = @_;

    my $self = $class->SUPER::new();
    $self->{md5sum_util_path} = $md5sum_util_path;

    return $self;
}


sub hash_file {
    my ( $self, $file_path ) = @_;

    my $cmd = $self->{md5sum_util_path} . '/bin/sysfink-md5sum';
    my $out = `$cmd "$file_path"`;
    my ( $hash ) = $out =~ /^\s*(\S+)/;
    return $hash;
}

1;