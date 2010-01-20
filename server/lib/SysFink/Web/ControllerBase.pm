package SysFink::Web::ControllerBase;

use strict;
use warnings;
use base 'Catalyst::Controller';

use Data::Page::HTML qw();
use DBIx::Dumper qw();
use Data::Dumper qw();

=head1 NAME

SysFink::Web::Controller::Report - Catalyst Controller

=head1 DESCRIPTION

Base class for some SysFink::Web::Controller::*.

=head1 METHODS

=cut

sub dadd {
    my $self = shift;
    my $c = shift;
    my $str = shift;
    $c->stash->{ot} .= $str;
}


sub dumper {
    my $self = shift;
    my $c = shift;

    return unless $c->log->is_debug;

    foreach my $val ( @_ ) {
        my $var_type = ref($val);
        if ( $var_type =~ /^SysFink\:\:Web\:\:Model/ ) {
            $c->stash->{ot} .= "dump_row:\n";
            $c->stash->{ot} .= DBIx::Dumper::dump_row( $val );
        } else {
            #$c->stash->{ot} .= "normal dumper: \n";
            $c->stash->{ot} .= Data::Dumper::Dumper( $val );
        }
    }
}


=head1 SEE ALSO

L<SysFink::Web>, L<Catalyst::Controller>

=head1 AUTHOR

Michal Jurosz <mj@mj41.cz>

=head1 LICENSE

This file is part of SysFink. See L<SysFink> license.

=cut


1;
