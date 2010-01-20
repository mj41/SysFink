package SysFink::Web::View::TT;

use base 'Catalyst::View::TT';
use strict;

=head1 NAME

SysFink::Web::View::TT - SysFink TT (TemplateToolkit) Site View

=head1 SYNOPSIS

See L<SysFink::Web>

=head1 DESCRIPTION

SysFink TT Site View.

=cut

__PACKAGE__->config({
    CATALYST_VAR => 'c',
    INCLUDE_PATH => [
        SysFink::Web->path_to( 'root', 'src' ),
        SysFink::Web->path_to( 'root', 'lib' )
    ],
    PRE_PROCESS  => 'config/main',
    WRAPPER      => 'site/wrapper',
    ERROR        => 'error.tt2',
    TIMER        => 0,
    TEMPLATE_EXTENSION => '.tt2',
    #COMPILE_DIR => '/tmp/SysFink/cache',
});

=head1 AUTHOR

Michal Jurosz <mj@mj41.cz>

=head1 LICENSE

This file is part of SysFink. See L<SysFink> license.

=cut

1;
