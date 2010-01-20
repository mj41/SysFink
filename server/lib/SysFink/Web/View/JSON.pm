package SysFink::Web::View::JSON;

use base 'Catalyst::View::JSON';
use strict;

=head1 NAME

SysFink::Web::View::JSON - SysFink JSON Site View

=head1 SYNOPSIS

See L<SysFink::Web>

=head1 DESCRIPTION

SysFink JSON Site View.

=cut

__PACKAGE__->config({
    #allow_callback  => 1,    # defaults to 0
    #callback_param  => 'cb', # defaults to 'callback'
    expose_stash    => [ qw(data ot) ], # defaults to everything
    #no_x_json_header => 1,
});

=head1 AUTHOR

Michal Jurosz <mj@mj41.cz>

=head1 LICENSE

This file is part of SysFink. See L<SysFink> license.

=cut

1;
