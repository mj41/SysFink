package SysFink::Server::SSHRPCClient;

use strict;
use warnings;

use Net::OpenSSH;


=head1 NAME

SysFink::Server::SSHRPCClient - The requestor of an RPC call over SSH.

=head1 SYNOPSIS

ToDo

=head1 DESCRIPTION

In RPC this requestor is considered client side. SysFink run this on server.

=head1 METHODS


=head2 new

Constructor.

=cut

sub new {
    my ( $class ) = @_;

    my $self  = {};

    $self->{debug} = 0;
    $self->{host} = 'localhost';
    $self->{user} = 'root';

    $self->{ver} = 0;
    $self->{err} = undef;
    $self->{ssh} = undef;

    bless $self, $class;
    return $self;
}


=head2 set_options

Validate and sets options.

=cut

sub set_options {
    my ( $self, $options ) = @_;

    $self->{ver} = $options->{ver} if defined $options->{ver};

    if ( defined $options->{host} ) {
        $self->set_host( $options->{host} ) || return 0;
    }

    if ( defined $options->{user} ) {
        $self->set_user( $options->{user} ) || return 0;
    }

    return 1;
}


=head2 err

Get/set error message and return 0.

=cut

sub err {
    my ( $self, $err) = @_;

    # Get.
    return $self->{err} unless defined $err;

    # Set.
    $self->{err} = $err;
    print "Setting error to: '$err'\n" if $self->{ver} >= 5;

    # return 0 is ok here.
    # You can use  e.g.
    #   return $self->err('Err msg') if $some_error;
    return 0;
}



=head2 disconnect

Disconnect from client.

=cut

sub disconnect {
    my ( $self ) = @_;

    $self->{ssh} = undef;
    return 1;
}


=head2 set_host

Validate hostname and set it.

=cut

sub set_host {
    my ( $self, $host ) = @_;

    $self->disconnect if defined $self->{ssh};
    $self->{host} = $host;
    return 1;
}


=head2 set_user

Validate user name and set it.

=cut

sub set_user {
    my ( $self, $user ) = @_;

    unless ( defined $user ) {
        $self->err('No user name defined');
        return 0;
    }

    unless ( $user ) {
        $self->err('User name is empty');
        return 0;
    }

    if ( $user =~ /\s/ ) {
        $self->err('User name contains empty string.');
        return 0;
    }

    if ( $user =~ /[\.\:\;\\\/]/ ) {
        $self->err('User name contains not allowed char.');
        return 0;
    }

    $self->disconnect if defined $self->{ssh};
    $self->{user} = $user;
    return 1;
}


=head2 connect

Connect to remote host.

=cut

sub connect {
    my ( $self, $host, $user ) = @_;

    return $self->err('No hostname sets.') if (not defined $host) && (not defined $self->{host});
    $host = $self->{host} unless defined $host;

    return $self->err("Bad user name '$user'.") if $user && ! $self->check_user_name( $user );

    if ( defined $user ) {
        $self->set_user( $user ) || return 0;
    } else {
        return $self->err('No user sets.') unless defined $self->{user};
        $host = $self->{user} unless defined $user;
    }

    my $ssh = Net::OpenSSH->new(
        $self->{host},
        user => $self->{user},
        master_opts => [ '-T']
    );
    return $self->err("Couldn't establish SSH connection: ". $ssh->error ) if $ssh->error;

    $self->{ssh} = $ssh;
    return 1;
}


=head2 test_hostname

Call hostname command on client and compare it.

=cut

sub test_hostname {
    my ( $self ) = @_;

    my ( $out, $err ) = $self->{ssh}->capture2('hostname');
    return $self->err("Remote 'hostname' command failed: ". $self->{ssh}->error ) if $self->{ssh}->error;

    my $hostname = $out;
    chomp( $hostname );

    return 1 if $self->{host} eq $hostname;
    return $self->err("Hostname reported from client is '$hostname', but object attribute host is '$self->{host}'.");
}


=head1 SEE ALSO

L<SSH::RPC::PP::Client>, L<SysFink>.

=head1 LICENSE

This file is part of SysFink. See L<SysFink> license.

=cut


1;
