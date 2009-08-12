package SysFink::RunObj::Base;

use strict;


sub new {
    my ( $class, $shared_data ) = @_;

    my $self  = {};
    $self->{shared_data} = $shared_data;

    bless( $self, $class );
    return $self;
}


sub debug {
    my ( $self, $output_to_add ) = @_;
    $self->{shared_data}->{debug_output} .= $output_to_add;
    return 1;
}


1;