package SysFink::DB::DBIxClassBase;

use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/ViewMD Core/);

1;
