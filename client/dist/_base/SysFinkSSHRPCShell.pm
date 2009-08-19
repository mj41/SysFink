package Sysfink::SSH::RPC::Shell;

$__PACKAGE__::VERSION = '0.100';

use base 'SSH::RPC::Shell::PP::JSON';

use strict;
use SysFinkRunObjBase; # SysFink::RunObj::Base
use SysFinkFileHash; # SysFink::FileHash
use SysFinkScanHost; # SysFink::ScanHost


sub new {
    my ($class, $ver, $md5sum_path) = @_;

    my $self = $class->SUPER::new( $ver );
    $self->{hash_conf} = {
        'md5sum_path' => $md5sum_path,
    };
    $self->{shared_data} = {
        'debug_output' => '',
    };

    return $self;
}


sub init_hash_obj {
    my ( $self ) = @_;
    $self->{hash_obj} = SysFink::FileHash->new(
        $self->{shared_data},
        $self->{hash_conf}->{md5sum_path}
    );
}


sub init_scanhost_obj {
    my ( $self ) = @_;

    $self->init_hash_obj() unless $self->{hash_obj};

    $self->{scanhost_obj} = SysFink::ScanHost->new(
        $self->{shared_data},
        $self->{hash_obj}
    );
}


=head2 pack_ok_response ()

Pack result to success response and add debug_output.

=cut

sub pack_ok_response {
    my ( $self, %response ) = @_;

    my $result = {
        status => 200,
        response => \%response,
        version => $__PACKAGE__::VERSION,
    };

    my $debug_output = $self->flush_debug_output();
    $result->{debug_output} = $debug_output if $debug_output;

    return $result;
}


sub flush_debug_output {
    my ( $self ) = @_;
    my $debug_output = $self->{shared_data}->{debug_output};
    $self->{shared_data}->{debug_output} = '';
    return $debug_output;
}


sub run_hash_file {
    my ( $self, $file ) = @_;
    $self->init_hash_obj() unless $self->{hash_obj};
    my $hash = $self->{hash_obj}->hash_file( $file );
    return $self->pack_ok_response( hash => $hash );
}


sub run_hash_type {
    my ( $self ) = @_;
    $self->init_hash_obj() unless $self->{hash_obj};
    my $type = $self->{hash_obj}->hash_type();
    return $self->pack_ok_response( type => $type );
}


sub run_hash_type_desc {
    my ( $self ) = @_;
    $self->init_hash_obj() unless $self->{hash_obj};
    my $type = $self->{hash_obj}->hash_type_desc();
    return $self->pack_ok_response( type_desc => $type );
}


sub run_scan_host {
    my ( $self, $args ) = @_;

    $self->init_scanhost_obj() unless $self->{scanhost_obj};

    my $ret_code = $self->{scanhost_obj}->scan( $args );
    return $self->pack_ok_response( $self->{scanhost_obj}->get_result() );
}


1;
