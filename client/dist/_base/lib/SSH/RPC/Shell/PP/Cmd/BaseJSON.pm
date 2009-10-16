package SSH::RPC::Shell::PP::Cmd::BaseJSON;

use strict;
use base 'SSH::RPC::Shell::PP::Cmd::Base';

use JSON;


sub send_ok_response {
    my ( $self, $response, $is_last ) = @_;

    my $result = $self->pack_ok_response( $response, $is_last );
    my $encoded_result = eval{ JSON->new->pretty->utf8->encode( $result ) };
    if ( $@ ) {
        print '{ "error" : "Malformed response.", "status" : "511" }' . "\n";
        print "\n\n";
        return 0;
    }

    print $encoded_result."\n";
    print "\n\n";
    return 1;
}


1;
