package SysFink::Web::Controller::Table;

use strict;
use warnings;
use base 'CatalystX::Controller::TableBrowser';

=head1 NAME

SysFink::Web::Controller::Table - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller for SysFink simple table browsing.

=head1 METHODS

=cut


sub db_schema_base_class_name {
  return 'WebDB';
}

sub db_schema_class_name {
  return 'SysFink::Web::Model::WebDB';
}


=head2 index

Base table browser action.

=cut

sub index : Path  {
    my $self = shift;
    return $self->base_index( @_ );
}


=head1 SEE ALSO

L<SysFink::Web>, L<Catalyst::Controller>

=head1 AUTHOR

Michal Jurosz <mj@mj41.cz>

=head1 LICENSE

This file is part of SysFink. See L<SysFink> license.

=cut


1;
