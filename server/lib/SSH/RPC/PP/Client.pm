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
       my $empty_lines = 0;

       $self->{next_response_sub} = sub {

            my $out_to_decode = undef;
            while ( my $line = <$out_fh> ) {
                if ( $line eq "\n" ) {
                    $empty_lines++;

                } else {
                    # two empty lines -> output to decode send
                    if ( $empty_lines >= 2 ) {
                        $out_to_decode = $out;
                        $empty_lines = 0;
                        $out = $line;
                        last;
                    }

                    $empty_lines = 0;
                    $out .= $line;
                }
            }

            $out_to_decode = $out unless defined $out_to_decode;

            if ( $out_to_decode ) {
                my $response = eval { JSON->new->utf8->decode( $out_to_decode ) };
                if ( $@ ) {
                    $response = { error=>"Response translation error. $@".$ssh->error, status=>510 };
                }
                return $response;
            }

            return { error=>"No response from client.", status=>600 };

        }; # sub end

        $response = $self->{next_response_sub}->();

    } else {
        $response = { error=>"Transmission error. ".$ssh->error, status=>406 };
    }
    my $result_obj = SSH::RPC::PP::Result->new($response);
    #use Data::Dumper; print Dumper( $result_obj ); exit;
    return $result_obj;
}


sub get_next_response {
    my ( $self ) = @_;

    my $response = $self->{next_response_sub}->();
    my $result_obj = SSH::RPC::PP::Result->new( $response );
    return $result_obj;
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
