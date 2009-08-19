package SysFink::RunObj::Base;

use strict;
use Data::Dumper;


sub new {
    my ( $class, $shared_data ) = @_;

    my $self  = {};
    $self->{errors} = [];
    $self->{shared_data} = $shared_data;

    bless( $self, $class );
    return $self;
}


sub add_error {
    my ( $self, $err_str ) = @_;
    push @{$self->{errors}}, $err_str;
    return 1;
}


sub get_errors {
    my ( $self ) = @_;
    return $self->{errors};
}


sub debug {
    my ( $self, $output_to_add ) = @_;
    $self->{shared_data}->{debug_output} .= $output_to_add;
    return 1;
}


sub dump {
    my @caller0 = caller(0);
    my @caller1 = caller(1);
    my ( $self, @data ) = @_;

    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 1;
    my $debug_output = "dump called on line $caller0[2] of $caller1[3] - " . Data::Dumper->Dump( \@data );
    $self->debug( $debug_output );
    return 1;
}


1;