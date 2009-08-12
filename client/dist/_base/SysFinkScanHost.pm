package SysFink::ScanHost;

use strict;
use base 'SysFink::RunObj::Base';


sub scan {
    my ( $self, $args ) = @_;

    $self->dump( $args );
    my $loaded_dirs = [ 'aaa', 'bbb' ];
    $self->dump( $loaded_dirs );

    return $loaded_dirs;
}


1;