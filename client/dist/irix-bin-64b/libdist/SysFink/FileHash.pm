package SysFink::FileHash;

use base 'SysFink::FileHash::BaseBinUtil';


sub hash_type {
    return '64bit-linux-md5sum-utility';
}


sub hash_type_desc {
    return <<"DESC_END"
Binary /usr/bin/md5sum utility for 64bit IRIX.
DESC_END
;

}


1;
