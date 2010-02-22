package SysFink::Web::Controller::CWM;

use strict;
use warnings;
use base 'CatalystX::Controller::CWebMagic';

=head1 NAME

SysFink::Web::Controller::CWM - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller for SysFink magic web application part.

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

L<SysFink::Web>, L<Catalyst::ControllerX::CWebMagic>. L<DBIx::Class::CWebMagic>

=head1 AUTHOR

Michal Jurosz <mj@mj41.cz>

=head1 LICENSE

This file is part of SysFink. See L<SysFink> license.

=cut


1;
