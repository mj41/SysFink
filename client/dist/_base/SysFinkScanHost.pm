package SysFink::ScanHost;

use strict;
use base 'SysFink::RunObj::Base';

 
sub scan {
    my ( $self, $dirs_conf, $debug ) = @_;
    
    use Data::Dumper;

    my $loaded_dirs = [ 'aaa', 'bbb' ];
    $self->debug( Dumper( $loaded_dirs ) );
    
    return $loaded_dirs;
}


1;