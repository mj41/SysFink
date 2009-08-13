package SysFink::FileHash;

use SysFinkFileHashBase; # SysFink::FileHash::Base
use base 'SysFink::FileHash::Base';


sub hash_type {
    return '64bit-linux-md5sum-utility';
}


sub hash_type_desc {
    return <<"DESC_END"
Binary /usr/bin/md5sum utility for 64bit IRIX.
DESC_END
;

}


sub hash_file {
    my ( $full_sysfink_client_path, $file_path ) = @_;
    my $cmd = $full_sysfink_client_path . '/sysfink-md5sum';
    my $out = `$cmd "$file_path"`;
    my ( $hash ) = $out =~ /^\s*(\S+)/;
    return $hash;
}


1;