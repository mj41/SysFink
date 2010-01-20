package SysFink::Web::Model::WebDB;

use strict;
use warnings;
use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    schema_class => 'SysFink::DB::SchemaAdd',
    connect_info => [
       SysFink::Web->config->{db}->{dbi_dsn},
       SysFink::Web->config->{db}->{user},
       SysFink::Web->config->{db}->{pass},
        { AutoCommit => 1 },
    ],
);


1;
