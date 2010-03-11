package SysFink::DB::SchemaAdd;

use base 'SysFink::DB::Schema';


# CWebMagic metadata

package SysFink::DB::Schema::aud;
__PACKAGE__->cwm_conf( {
    col_conf => {
        'date' => 'G',
    },
    max_deep => 2,
} );

package SysFink::DB::Schema::aud_idata;
__PACKAGE__->cwm_conf( {
    max_deep => 4,
} );

package SysFink::DB::Schema::machine;
__PACKAGE__->cwm_conf( { 
    auth => {
        'ip' => 'R',
    },
} );

package SysFink::DB::Schema::mconf_change;
__PACKAGE__->cwm_conf( {
    col_conf => {
        'date' => 'G',
    },
} );

package SysFink::DB::Schema::mconf_sec_kv;
__PACKAGE__->cwm_conf( {
     max_deep => 5,
} );

package SysFink::DB::Schema::mconf_sec;
__PACKAGE__->cwm_conf( {
     max_deep => 3,
} );

package SysFink::DB::Schema::user;
__PACKAGE__->cwm_conf( {
    auth => {
        'passwd' => 'R',
        'who' => 'R',
    },
} );

package SysFink::DB::Schema::path;
__PACKAGE__->cwm_conf( {
    col_conf => { 
        'path_id' => 'S',
        'path' => 'G',
    },
    #max_deep => 1,
} );


package SysFink::DB::Schema::sc_mitem;
__PACKAGE__->cwm_conf( {
     max_deep => 3,
} );


1;
