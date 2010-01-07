

package SysFink::DB::Schema::aud_idata;
use base 'SysFink::DB::DBIxClassBase';

__PACKAGE__->table('aud_idata');


__PACKAGE__->add_columns(
    'aud_idata_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'aud_idata_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'aud_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'aud_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'sc_idata_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'sc_idata_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'aud_status_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'aud_status_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'newer_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 1,
      'name' => 'newer_id',
      'is_nullable' => 1,
      'size' => '11'
    },
);
__PACKAGE__->set_primary_key('aud_idata_id');


package SysFink::DB::Schema::path;
use base 'SysFink::DB::DBIxClassBase';

__PACKAGE__->table('path');


__PACKAGE__->add_columns(
    'path_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'path_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'path' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'path',
      'is_nullable' => 0,
      'size' => '255'
    },
);
__PACKAGE__->set_primary_key('path_id');


package SysFink::DB::Schema::sc_mitem;
use base 'SysFink::DB::DBIxClassBase';

__PACKAGE__->table('sc_mitem');


__PACKAGE__->add_columns(
    'sc_mitem_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'sc_mitem_id',
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
    'path_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'path_id',
      'is_nullable' => 0,
      'size' => '11'
    },
);
__PACKAGE__->set_primary_key('sc_mitem_id');


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
    'num' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'num',
      'is_nullable' => 1,
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


package SysFink::DB::Schema::mconf;
use base 'SysFink::DB::DBIxClassBase';

__PACKAGE__->table('mconf');


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
    'active' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'active',
      'is_nullable' => 0,
      'size' => '11'
    },
    'create_time' => {
      'data_type' => 'DATETIME',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'create_time',
      'is_nullable' => 0,
      'size' => 0
    },
);
__PACKAGE__->set_primary_key('mconf_sec_id');


package SysFink::DB::Schema::scan;
use base 'SysFink::DB::DBIxClassBase';

__PACKAGE__->table('scan');


__PACKAGE__->add_columns(
    'scan_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'scan_id',
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
    'start_time' => {
      'data_type' => 'DATETIME',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'start_time',
      'is_nullable' => 0,
      'size' => 0
    },
    'stop_time' => {
      'data_type' => 'DATETIME',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'stop_time',
      'is_nullable' => 1,
      'size' => 0
    },
    'pid' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'pid',
      'is_nullable' => 0,
      'size' => '11'
    },
    'items' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'items',
      'is_nullable' => 1,
      'size' => '11'
    },
);
__PACKAGE__->set_primary_key('scan_id');


package SysFink::DB::Schema::aud_status;
use base 'SysFink::DB::DBIxClassBase';

__PACKAGE__->table('aud_status');


__PACKAGE__->add_columns(
    'aud_status_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'aud_status_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'name' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'name',
      'is_nullable' => 1,
      'size' => '10'
    },
    'legend' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'legend',
      'is_nullable' => 1,
      'size' => '1500'
    },
);
__PACKAGE__->set_primary_key('aud_status_id');


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


package SysFink::DB::Schema::aud;
use base 'SysFink::DB::DBIxClassBase';

__PACKAGE__->table('aud');


__PACKAGE__->add_columns(
    'aud_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'aud_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'date' => {
      'data_type' => 'DATETIME',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'date',
      'is_nullable' => 0,
      'size' => 0
    },
    'user_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'user_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'msg' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'msg',
      'is_nullable' => 1,
      'size' => '1000'
    },
);
__PACKAGE__->set_primary_key('aud_id');


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
    'mconf_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'mconf_id',
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


package SysFink::DB::Schema::sc_idata;
use base 'SysFink::DB::DBIxClassBase';

__PACKAGE__->table('sc_idata');


__PACKAGE__->add_columns(
    'sc_idata_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 1,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'sc_idata_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'sc_mitem_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'sc_mitem_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'scan_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 1,
      'name' => 'scan_id',
      'is_nullable' => 0,
      'size' => '11'
    },
    'newer_id' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 1,
      'name' => 'newer_id',
      'is_nullable' => 1,
      'size' => '11'
    },
    'found' => {
      'data_type' => 'BOOL',
      'is_auto_increment' => 0,
      'default_value' => undef,
      'is_foreign_key' => 0,
      'name' => 'found',
      'is_nullable' => 0,
      'size' => 0
    },
    'mtime' => {
      'data_type' => 'DATETIME',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'mtime',
      'is_nullable' => 1,
      'size' => 0
    },
    'mode' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'mode',
      'is_nullable' => 1,
      'size' => '11'
    },
    'size' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'size',
      'is_nullable' => 1,
      'size' => '11'
    },
    'uid' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'uid',
      'is_nullable' => 1,
      'size' => '11'
    },
    'user_name' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'user_name',
      'is_nullable' => 1,
      'size' => '50'
    },
    'gid' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'gid',
      'is_nullable' => 1,
      'size' => '11'
    },
    'group_name' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'group_name',
      'is_nullable' => 1,
      'size' => '50'
    },
    'hash' => {
      'data_type' => 'VARCHAR',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'hash',
      'is_nullable' => 1,
      'size' => '32'
    },
    'nlink' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'nlink',
      'is_nullable' => 1,
      'size' => '11'
    },
    'dev_num' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'dev_num',
      'is_nullable' => 1,
      'size' => '11'
    },
    'ino_num' => {
      'data_type' => 'int',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'ino_num',
      'is_nullable' => 1,
      'size' => '11'
    },
);
__PACKAGE__->set_primary_key('sc_idata_id');


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
    'legend' => {
      'data_type' => 'TEXT',
      'is_auto_increment' => 0,
      'default_value' => 'NULL',
      'is_foreign_key' => 0,
      'name' => 'legend',
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

package SysFink::DB::Schema::aud_idata;

__PACKAGE__->belongs_to('aud_id','SysFink::DB::Schema::aud','aud_id');

__PACKAGE__->belongs_to('sc_idata_id','SysFink::DB::Schema::sc_idata','sc_idata_id');

__PACKAGE__->belongs_to('aud_status_id','SysFink::DB::Schema::aud_status','aud_status_id');

__PACKAGE__->belongs_to('newer_id','SysFink::DB::Schema::aud_idata','newer_id',{join_type => 'left'});

__PACKAGE__->has_many('get_aud_idata', 'SysFink::DB::Schema::aud_idata', 'newer_id');

package SysFink::DB::Schema::path;

__PACKAGE__->has_many('get_sc_mitem', 'SysFink::DB::Schema::sc_mitem', 'path_id');

package SysFink::DB::Schema::sc_mitem;

__PACKAGE__->belongs_to('machine_id','SysFink::DB::Schema::machine','machine_id');

__PACKAGE__->belongs_to('path_id','SysFink::DB::Schema::path','path_id');

__PACKAGE__->has_many('get_sc_idata', 'SysFink::DB::Schema::sc_idata', 'sc_mitem_id');

package SysFink::DB::Schema::mconf_sec_kv;

__PACKAGE__->belongs_to('mconf_sec_id','SysFink::DB::Schema::mconf_sec','mconf_sec_id');


package SysFink::DB::Schema::mconf;

__PACKAGE__->belongs_to('machine_id','SysFink::DB::Schema::machine','machine_id');

__PACKAGE__->has_many('get_mconf_sec', 'SysFink::DB::Schema::mconf_sec', 'mconf_id');

package SysFink::DB::Schema::scan;

__PACKAGE__->belongs_to('mconf_sec_id','SysFink::DB::Schema::mconf_sec','mconf_sec_id');

__PACKAGE__->has_many('get_sc_idata', 'SysFink::DB::Schema::sc_idata', 'scan_id');

package SysFink::DB::Schema::aud_status;

__PACKAGE__->has_many('get_aud_idata', 'SysFink::DB::Schema::aud_idata', 'aud_status_id');

package SysFink::DB::Schema::user;

__PACKAGE__->has_many('get_aud', 'SysFink::DB::Schema::aud', 'user_id');

package SysFink::DB::Schema::aud;

__PACKAGE__->belongs_to('user_id','SysFink::DB::Schema::user','user_id');

__PACKAGE__->has_many('get_aud_idata', 'SysFink::DB::Schema::aud_idata', 'aud_id');

package SysFink::DB::Schema::mconf_sec;

__PACKAGE__->belongs_to('mconf_id','SysFink::DB::Schema::mconf','mconf_id');

__PACKAGE__->has_many('get_mconf_sec_kv', 'SysFink::DB::Schema::mconf_sec_kv', 'mconf_sec_id');
__PACKAGE__->has_many('get_scan', 'SysFink::DB::Schema::scan', 'mconf_sec_id');

package SysFink::DB::Schema::sc_idata;

__PACKAGE__->belongs_to('sc_mitem_id','SysFink::DB::Schema::sc_mitem','sc_mitem_id');

__PACKAGE__->belongs_to('scan_id','SysFink::DB::Schema::scan','scan_id');

__PACKAGE__->belongs_to('newer_id','SysFink::DB::Schema::sc_idata','newer_id',{join_type => 'left'});

__PACKAGE__->has_many('get_sc_idata', 'SysFink::DB::Schema::sc_idata', 'newer_id');
__PACKAGE__->has_many('get_aud_idata', 'SysFink::DB::Schema::aud_idata', 'sc_idata_id');

package SysFink::DB::Schema::machine;

__PACKAGE__->has_many('get_mconf', 'SysFink::DB::Schema::mconf', 'machine_id');
__PACKAGE__->has_many('get_sc_mitem', 'SysFink::DB::Schema::sc_mitem', 'machine_id');



package SysFink::DB::Schema;
use base 'DBIx::Class::Schema';
use strict;
use warnings;

__PACKAGE__->register_class('aud_idata', 'SysFink::DB::Schema::aud_idata');

__PACKAGE__->register_class('path', 'SysFink::DB::Schema::path');

__PACKAGE__->register_class('sc_mitem', 'SysFink::DB::Schema::sc_mitem');

__PACKAGE__->register_class('mconf_sec_kv', 'SysFink::DB::Schema::mconf_sec_kv');

__PACKAGE__->register_class('mconf', 'SysFink::DB::Schema::mconf');

__PACKAGE__->register_class('scan', 'SysFink::DB::Schema::scan');

__PACKAGE__->register_class('aud_status', 'SysFink::DB::Schema::aud_status');

__PACKAGE__->register_class('user', 'SysFink::DB::Schema::user');

__PACKAGE__->register_class('aud', 'SysFink::DB::Schema::aud');

__PACKAGE__->register_class('mconf_sec', 'SysFink::DB::Schema::mconf_sec');

__PACKAGE__->register_class('sc_idata', 'SysFink::DB::Schema::sc_idata');

__PACKAGE__->register_class('machine', 'SysFink::DB::Schema::machine');

1;
