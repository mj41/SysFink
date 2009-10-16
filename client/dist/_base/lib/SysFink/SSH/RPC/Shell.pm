package Sysfink::SSH::RPC::Shell;

$__PACKAGE__::VERSION = '0.100';

use base 'SSH::RPC::Shell::PP::JSON';

use strict;

use SSH::RPC::Shell::PP::TestCmds;
use SysFink::FileHash;
use SysFink::ScanHost;


sub new {
    my ($class, $ver, $md5sum_path) = @_;

    my $self = $class->SUPER::new( $ver );
    $self->{hash_conf} = {
        'md5sum_path' => $md5sum_path,
    };
    return $self;
}


sub init_hash_obj {
    my ( $self ) = @_;
    $self->{hash_obj} = SysFink::FileHash->new(
        $self->{hash_conf}->{md5sum_path}
    );
}


sub init_scanhost_obj {
    my ( $self ) = @_;

    $self->init_hash_obj() unless $self->{hash_obj};

    $self->{scanhost_obj} = SysFink::ScanHost->new(
        $self->{hash_obj}
    );
}


sub run_hash_file {
    my ( $self, $file ) = @_;
    $self->init_hash_obj() unless $self->{hash_obj};
    return $self->{hash_obj}->run_hash_file( $file );
}


sub run_hash_type {
    my ( $self ) = @_;
    $self->init_hash_obj() unless $self->{hash_obj};
    return $self->{hash_obj}->run_hash_type();
}


sub run_hash_type_desc {
    my ( $self ) = @_;
    $self->init_hash_obj() unless $self->{hash_obj};
    return $self->{hash_obj}->run_hash_type_desc();
}


sub run_scan_host {
    my ( $self, $args ) = @_;
    $self->init_scanhost_obj() unless $self->{scanhost_obj};
    return $self->{scanhost_obj}->run_scan_host( $args );
}


1;
