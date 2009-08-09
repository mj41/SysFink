package SSH::RPC::PP::Client;

our $VERSION = 1.200;

use strict;
use JSON;
use SSH::RPC::PP::Result;

=head1 NAME

SSH::RPC::PP::Client - The requestor, or client side, of an RPC call over SSH.

=head1 DESCRIPTION

Based on SSH::RPC::Client, but without Class::InsideOut.

=cut

sub new {
    my ( $class, $ssh_obj, $client_start_cmd ) = @_;

    my $self = {};
    $self->{ssh} = $ssh_obj;
    $self->{client_start_cmd} = $client_start_cmd;
    bless( $self, $class );
    return $self;
}


sub run {
    my ($self, $command, $args) = @_;
    my $json = JSON->new->utf8->pretty->encode({
        command => $command,
        args    => $args,
    }) . "\n";
    my $ssh = $self->{ssh};
    my $out;
    my $response;
    if ( $out = $ssh->capture({ stdin_data => $json, ssh_opts => ['-T'] }, $self->{client_start_cmd}) ) {
        $response = eval { JSON->new->utf8->decode($out) };
        if ( $@ ) {
            $response = { error=>"Response translation error. $@".$ssh->error, status=>510 };
        }
    }
    else {
        $response = { error=>"Transmission error. ".$ssh->error, status=>406 };
    }
    return SSH::RPC::PP::Result->new($response);
}

1;
