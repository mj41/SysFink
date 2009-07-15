package SysFink::DB::SchemaAdd;

use base 'SysFink::DB::Schema';

# ViewMD - view metadata

package SysFink::DB::Schema::machine;
__PACKAGE__->restricted_cols( { 'passwd' => 1, 'ip' => 1, } );
__PACKAGE__->cols_in_foreign_tables( [ qw/name/ ] );

package SysFink::DB::Schema::user;
__PACKAGE__->restricted_cols( { 'passwd' => 1, } );
__PACKAGE__->cols_in_foreign_tables( [ qw/login/ ] );

1;
