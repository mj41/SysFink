package SysFink::FileHash;

use base 'SysFink::FileHash::BaseBinUtil';


sub hash_type {
    return '64bit-linux-md5sum-utility';
}


sub hash_type_desc {
    return <<"DESC_END"
Binary /usr/bin/md5sum utility copied from 64bit.
ldd md5sum
libc.so.6 => /lib64/libc.so.6
/lib64/ld-linux-x86-64.so.2
DESC_END
;

}

1;
