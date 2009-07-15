package SysFink::Utils::DB;

use strict;
use warnings;
use Carp qw(carp croak verbose);

use base 'Exporter';
our @EXPORT = qw(get_connected_schema);

use SysFink::DB::SchemaAdd;

=head2 get_connected_schema

Return SysFink::DB::Schema->connect(...)

=cut

sub get_connected_schema {
    my ( $db_conf ) = @_;

    my $schema = SysFink::DB::Schema->connect(
        $db_conf->{dbi_dsn},
        $db_conf->{user},
        $db_conf->{pass},
        { AutoCommit => 1 },
    );
    return $schema;
}

1;