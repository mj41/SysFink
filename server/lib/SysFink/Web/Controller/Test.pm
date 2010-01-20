package SysFink::Web::Controller::Test;

use strict;
use warnings;
use base 'SysFink::Web::ControllerBase';

=head1 NAME

SysFink::Web::Controller::Test - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller for SysFink Web developing.

=head1 METHODS

=cut

=head2 index

Base action.

=cut

sub index : Path  {
    my ( $self, $c, $params, @args ) = @_;

    $self->dumper( $c, $c->config );
 }


=head1 SEE ALSO

L<SysFink::Web>, L<Catalyst::Controller>

=head1 AUTHOR

Michal Jurosz <mj@mj41.cz>

=head1 LICENSE

This file is part of SysFink. See L<SysFink> license.

=cut


1;
