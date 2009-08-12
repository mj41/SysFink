package SysFink::RunObj::Base;

use strict;
use Data::Dumper;


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


sub dump {
    my @caller = (caller 1);
    my ( $self, @data ) = @_;

    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 1;
    my $debug_output = "dump called on line $caller[2] of $caller[3] - " . Data::Dumper->Dump( \@data );
    $self->debug( $debug_output );
    return 1;
}


1;