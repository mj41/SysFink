

package SysFink::DB::Schema::user;
use base 'SysFink::DB::DBIxClassBase';

__PACKAGE__->table('user');


__PACKAGE__->add_columns(
    'user_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'user_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'login' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'login',
      'is_nullable' => 0,
      'size' => '20'
    },
    'passwd' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'passwd',
      'is_nullable' => 0,
      'size' => '20'
    },
    'first_name' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => '',
      'is_foreign_key' => 0,
      'name' => 'first_name',
      'is_nullable' => 0,
      'size' => '255'
    },
    'last_name' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => '',
      'is_foreign_key' => 0,
      'name' => 'last_name',
      'is_nullable' => 0,
      'size' => '255'
    },
    'active' => {
      'data_type' => 'BOOLEAN',
      'is_auto_increment' => 0,
      'default_value' => '1',
      'is_foreign_key' => 0,
      'name' => 'active',
      'is_nullable' => 0,
      'size' => 0
    },
    'created' => {
      'data_type' => 'DATETIME',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'created',
      'is_nullable' => 0,
      'size' => 0
    },
);
__PACKAGE__->set_primary_key('user_id');


package SysFink::DB::Schema::mconf_sec;
use base 'SysFink::DB::DBIxClassBase';

__PACKAGE__->table('mconf_sec');


__PACKAGE__->add_columns(
    'mconf_sec_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'mconf_sec_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'machine_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'machine_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'name' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'name',
      'is_nullable' => 0,
      'size' => '50'
    },
);
__PACKAGE__->set_primary_key('mconf_sec_id');


package SysFink::DB::Schema::mconf_sec_kv;
use base 'SysFink::DB::DBIxClassBase';

__PACKAGE__->table('mconf_sec_kv');


__PACKAGE__->add_columns(
    'mconf_sec_kv_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'mconf_sec_kv_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'mconf_sec_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'mconf_sec_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'key' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'key',
      'is_nullable' => 0,
      'size' => '50'
    },
    'value' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'value',
      'is_nullable' => 0,
      'size' => '255'
    },
);
__PACKAGE__->set_primary_key('mconf_sec_kv_id');


package SysFink::DB::Schema::machine;
use base 'SysFink::DB::DBIxClassBase';

__PACKAGE__->table('machine');


__PACKAGE__->add_columns(
    'machine_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'machine_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'name' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'name',
      'is_nullable' => 0,
      'size' => '50'
    },
    'desc' => {
      'data_type' => 'TEXT',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'desc',
      'is_nullable' => 1,
      'size' => '65535'
    },
    'ip' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => 'NUL',
      'is_foreign_key' => 0,
      'name' => 'ip',
      'is_nullable' => 1,
      'size' => '15'
    },
    'disabled' => {
      'data_type' => 'BOOLEAN',
      'is_auto_increment' => 0,
      'default_value' => '0',
      'is_foreign_key' => 0,
      'name' => 'disabled',
      'is_nullable' => 0,
      'size' => 0
    },
);
__PACKAGE__->set_primary_key('machine_id');

package SysFink::DB::Schema::mconf_sec;

__PACKAGE__->belongs_to('machine_id','SysFink::DB::Schema::machine','machine_id');

__PACKAGE__->has_many('get_mconf_sec_kv', 'SysFink::DB::Schema::mconf_sec_kv', 'mconf_sec_id');

package SysFink::DB::Schema::mconf_sec_kv;

__PACKAGE__->belongs_to('mconf_sec_id','SysFink::DB::Schema::mconf_sec','mconf_sec_id');


package SysFink::DB::Schema::machine;

__PACKAGE__->has_many('get_mconf_sec', 'SysFink::DB::Schema::mconf_sec', 'machine_id');



package SysFink::DB::Schema;
use base 'DBIx::Class::Schema';
use strict;
use warnings;

__PACKAGE__->register_class('user', 'SysFink::DB::Schema::user');

__PACKAGE__->register_class('mconf_sec', 'SysFink::DB::Schema::mconf_sec');

__PACKAGE__->register_class('mconf_sec_kv', 'SysFink::DB::Schema::mconf_sec_kv');

__PACKAGE__->register_class('machine', 'SysFink::DB::Schema::machine');

1;
