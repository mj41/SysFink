package SSH::RPC::PP::Client;

our $VERSION = 1.200;

use strict;
use JSON;
use SSH::RPC::PP::Result;

=head1 NAME

SSH::RPC::PP::Client - The requestor, or client side, of an RPC call over SSH.

=head1 SYNOPSIS

ToDo. See L<SysFink>.

=head1 DESCRIPTION

Based on SSH::RPC::Client, but without Class::InsideOut.

=head1 METHODS

=head2 new

Constructor. Parameters: conf_dir_path.

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
    my ( $self, $command, $args ) = @_;
    my $json = JSON->new->utf8->pretty->encode({
        command => $command,
        args    => $args,
    }) . "\n";
    my $ssh = $self->{ssh};
    my $response;

    my $out_fh;
    my ($in_fh, $out_fh, undef, $pid) = $ssh->open_ex(
        { stdin_pipe => 1, stdout_pipe => 1, ssh_opts => ['-T'] },
        $self->{client_start_cmd}
    );

    if ( defined $pid ) {
        print $in_fh $json;

        my $out = '';
        while ( my $line = <$out_fh> ) {
            $out .= $line;
        }

        $response = eval { JSON->new->utf8->decode($out) };
        if ( $@ ) {
            $response = { error=>"Response translation error. $@".$ssh->error, status=>510 };
        }

    } else {
        $response = { error=>"Transmission error. ".$ssh->error, status=>406 };
    }
    my $response = SSH::RPC::PP::Result->new($response);
    #use Data::Dumper; print Dumper( $response ); exit;
    return $response;
}


sub debug_run {
    my ( $self, $command, $args ) = @_;
    my $json = JSON->new->utf8->pretty->encode({
        command => $command,
        args    => $args,
    }) . "\n";
    my $ssh = $self->{ssh};
    my $ret_code = $ssh->system( { stdin_data => $json, ssh_opts => ['-T'] }, $self->{client_start_cmd} );
    return $ret_code;
}

1;
