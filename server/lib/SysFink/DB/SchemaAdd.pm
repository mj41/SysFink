package SysFink::DB::SchemaAdd;

use base 'SysFink::DB::Schema';

# CWebMagic metadata

package SysFink::DB::Schema::aud;
__PACKAGE__->cwm_col_type({ 'date' => 'G', });

package SysFink::DB::Schema::machine;
__PACKAGE__->cwm_col_auth({ 'ip' => 'R', });

package SysFink::DB::Schema::mconf_change;
__PACKAGE__->cwm_col_type({ 'date' => 'G',  });

package SysFink::DB::Schema::user;
__PACKAGE__->cwm_col_auth({
    'passwd' => 'R',
    'who' => 'R',
} );


1;
