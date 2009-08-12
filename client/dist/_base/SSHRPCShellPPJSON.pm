package SSH::RPC::Shell::PP::JSON;

use base 'SSH::RPC::Shell::PP::Base';

#use JSONPP;
#use JSONPP5005;

use strict;
use JSON;



=head2 run ()

Main method. Run one command. Pack request/response as JSON.

=cut

sub run {
    my ( $self, $fh ) = shift;

    $fh = \*STDIN unless defined $fh;

    my $json = JSON->new->utf8;
    my $request;
    while ( my $line = <$fh> ) {
        $request = eval { $json->incr_parse($line) };
        if ( $@ ) {
            warn $@;
            print '{ "error" : "Malformed request.", "status" : "400" }' . "\n";
            return 0;
        }
        last if defined $request;
    }

    my $result = $self->process_request($request);
    my $encoded_result = eval{ JSON->new->pretty->utf8->encode($result) };
    if ( $@ ) {
        print '{ "error" : "Malformed response.", "status" : "511" }' . "\n";
        return 0;
    }

    print $encoded_result."\n";
    return 1;
}


1;
