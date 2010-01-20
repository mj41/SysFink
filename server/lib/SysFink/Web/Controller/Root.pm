package SysFink::Web::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';


# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in Web.pm

__PACKAGE__->config->{namespace} = '';

=head1 NAME

SysFink::Web::Controller::Root - Root Controller for SysFink::Web

=head1 DESCRIPTION

SysFink root path action.

=head1 METHODS

=cut

=head2 default

=cut

sub default : Private {
    my ( $self, $c ) = @_;

    $c->stash->{template} =  'index.tt2';
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}


=head1 SEE ALSO

L<SysFink::Web>, L<Catalyst::Controller>

=head1 AUTHOR

Michal Jurosz <mj@mj41.cz>

=head1 LICENSE

This file is part of SysFink. See L<SysFink> license.

=cut


1;
