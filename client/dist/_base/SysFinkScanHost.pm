package SysFink::ScanHost;

use strict;
use base 'SysFink::RunObj::Base';


sub get_dir_search {
    my ( $self, $dir ) = @_;

    my $dir_search = undef;

    if ( $dir eq "" ) {
        $dir_search = '/*';
    } else {
        $dir_search = $dir . '/*';
    }

    $dir_search =~ s{ \/{2,} }{ \/ }gx;
    return $dir_search;
}


sub scan {
    my ( $self, $args ) = @_;

    my $debug = $args->{debug};
    my $paths = $args->{paths};

    my $loaded_dirs = [];

    #my $dir_search = $self->get_dir_search( $dir );
    #$self->dump( $dir_search );
    my $dir_search = '/*';

    LOOP: foreach my $item ( glob($dir_search) ) {
        my $file = $item;
        $self->dump( $file );

    }

    return $loaded_dirs;
}


1;