package SysFink::DB::SchemaAdd;

use base 'SysFink::DB::Schema';

# ViewMD - view metadata

package SysFink::DB::Schema::aud;
__PACKAGE__->cols_in_foreign_tables( [ qw/aud_id user_id date/ ] );

package SysFink::DB::Schema::aud_status;
__PACKAGE__->cols_in_foreign_tables( [ qw/name/ ] );

package SysFink::DB::Schema::aud_status;
__PACKAGE__->cols_in_foreign_tables( [ qw/name/ ] );

package SysFink::DB::Schema::machine;
__PACKAGE__->restricted_cols( { 'ip' => 1, } );
__PACKAGE__->cols_in_foreign_tables( [ qw/name/ ] );

package SysFink::DB::Schema::mconf_sec;
__PACKAGE__->cols_in_foreign_tables( [ qw/mconf_sec_id name mconf_id/ ] );

package SysFink::DB::Schema::path;
__PACKAGE__->cols_in_foreign_tables( [ qw/path/ ] );

package SysFink::DB::Schema::user;
__PACKAGE__->restricted_cols( { 'passwd' => 1, } );
__PACKAGE__->cols_in_foreign_tables( [ qw/login/ ] );

1;
