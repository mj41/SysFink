package Sysfink::SSH::RPC::Shell;

$__PACKAGE__::VERSION = '0.100';

use base 'SSH::RPC::Shell::PP::JSON';

use strict;

use SSH::RPC::Shell::PP::TestCmds;
use SysFink::FileHash;
use SysFink::ScanHost;


=head1 NAME

Sysfink::SSH::RPC::Shell - The SysFink shell of an RPC call over SSH.

=head1 SYNOPSIS

ToDo. See L<SysFink>.

=head1 DESCRIPTION

In RPC this shell is considered server side. SysFink run this on clients.

=head1 METHODS


=head2 new

Constructor.

=cut

sub new {
    my ($class, $ver, $md5sum_path) = @_;

    my $self = $class->SUPER::new( $ver );
    $self->{hash_conf} = {
        'md5sum_path' => $md5sum_path,
    };
    return $self;
}


=head2 init_hash_obj

Initialize object to get checksum of files.

=cut

sub init_hash_obj {
    my ( $self ) = @_;
    $self->{hash_obj} = SysFink::FileHash->new(
        $self->{hash_conf}->{md5sum_path}
    );
}


=head2 init_scanhost_obj

Initialize object to scan host.

=cut

sub init_scanhost_obj {
    my ( $self ) = @_;

    $self->init_hash_obj() unless $self->{hash_obj};

    $self->{scanhost_obj} = SysFink::ScanHost->new(
        $self->{hash_obj}
    );
}


=head2 run_hash_file

Run run_hash_file command.

=cut

sub run_hash_file {
    my ( $self, $file ) = @_;
    $self->init_hash_obj() unless $self->{hash_obj};
    return $self->{hash_obj}->run_hash_file( $file );
}


=head2 run_hash_type

Run run_hash_type command.

=cut

sub run_hash_type {
    my ( $self ) = @_;
    $self->init_hash_obj() unless $self->{hash_obj};
    return $self->{hash_obj}->run_hash_type();
}


=head2 run_hash_type_desc

Run run_hash_type_desc command.

=cut

sub run_hash_type_desc {
    my ( $self ) = @_;
    $self->init_hash_obj() unless $self->{hash_obj};
    return $self->{hash_obj}->run_hash_type_desc();
}


=head2 run_scan_host

Run run_scan_host command.

=cut

sub run_scan_host {
    my ( $self, $args ) = @_;
    $self->init_scanhost_obj() unless $self->{scanhost_obj};
    return $self->{scanhost_obj}->run_scan_host( $args );
}


1;
