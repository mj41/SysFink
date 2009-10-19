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
    bless $self, $class;

    return undef unless $self->set_default_values();
    return $self;
}


=head2 set_default_values

Validate and sets options.

=cut

sub set_default_values {
    my ( $self ) = @_;

    $self->{ver} = 0;
    $self->{err} = undef;
    $self->{ssh} = undef;

    $self->{host} = 'localhost';
    $self->{user} = 'root';
    $self->{client_dir} = $self->set_client_dir();

    return 1;
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


=head2 get_client_dir

Return SysFink directory path on client for user name.

=cut

sub get_client_dir {
    my ( $self ) = @_;

    return '/root/sysfink-client' if $self->{user} eq 'root';
    return '/home/' . $self->{user} . '/sysfink-client';
}


=head2 set_client_dir

Sets SysFink directory path on client for user name.

=cut

sub set_client_dir {
    my ( $self ) = @_;

    $self->{client_dir} = $self->get_client_dir();
    print "New client_dir: '$self->{client_dir}'\n" if $self->{ver} >= 4;
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

    return $self->set_client_dir();
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


sub err_rpc_cmd {
    my ( $self, $cmd, $err ) = @_;
    my $full_err = "RPC '$cmd' return error output: '$err'";
    return $self->err( $full_err );
}


=head2 do_rpc

Run command on client over SSH.

=cut

sub do_rpc {
    my ( $self, $cmd, $report_err ) = @_;
    $report_err = 1 unless defined $report_err;

    print "Running client command '$cmd':\n" if $self->{ver} >= 5;
    my ( $out, $err ) = $self->{ssh}->capture2( $cmd );
    if ( $self->{ver} >= 4 && ( $out || $err ) ) {
        print "out: '$out', err:'$err'\n";
    }

    # Set error. Caller should do "return 0 if $err;".
    if ( $err && $report_err ) {
        $self->err_rpc_cmd( $cmd, $err );
    }

    return ( $out, $err );
}


=head2 test_hostname

Call hostname command on client and compare it.

=cut

sub test_hostname {
    my ( $self ) = @_;

    my ( $out, $err ) = $self->do_rpc( 'hostname', 1 );
    return $self->err("Remote 'hostname' command failed: ". $self->{ssh}->error ) if $self->{ssh}->error;

    my $hostname = $out;
    chomp( $hostname );

    return 1 if $self->{host} eq $hostname;
    return $self->err("Hostname reported from client is '$hostname', but object attribute host is '$self->{host}'.");
}


=head2 ls_output_contains_unknown_dir

Return 1 if output captured from ls command contains any unknown directory. This is useful to check
if we are not doing critical mistake by recursively removing (rm -rf).

=cut

sub ls_output_contains_unknown_dir {
    my ( $self, $out ) = @_;

    chomp $out;
    my @lines = split( /\n/, $out );
    shift @lines; # remove line "total \d+"
    foreach my $line ( @lines ) {
        if ( $line =~ /^\s*d/ ) {
            return 1 if $line !~ /(bin|lib|libcpan|libdist){1}\s*$/;
        }
    }
    return 0;
}


=head2 check_client_dir_content

Run ls command on client and validate output. See L<ls_output_contains_unknown_dir> method.

=cut

sub check_client_dir_content {
    my ( $self ) = @_;

    my $client_dir = $self->{client_dir};

    # Process error output of command own way.
    my $cmd = "ls -l $client_dir";
    my ( $out, $err ) = $self->do_rpc( $cmd, 0 );
    if ( $err ) {
        if ( $err =~ /No such file or directory/i ) {
            print "Directory '$client_dir' doesn't exists on host." if $self->{ver} >= 3;
        } else {
            return $self->err_rpc_cmd( $cmd, $err );
        }

    } elsif ( $self->ls_output_contains_unknown_dir($out) ) {
        $self->err("Directory '$client_dir' on client contains some unknown directories.\nCmd 'ls -l' output is\n$out.");
        return 0;
    }

    return 1;
}


=head2 empty_client_dir

L<check_client_dir_content> and erase its content with rm -rf.

=cut

sub empty_client_dir {
    my ( $self ) = @_;

    # ToDo - safe enought?
    return 0 unless $self->check_client_dir_content();

    my $client_dir = $self->{client_dir};

    my ( $out, $err );

    # ToDo - path escaping?
    ( $out, $err ) = $self->do_rpc( "rm -rf $client_dir/*", 1 );
    return 0 if $err;

    return 1;
}



=head1 SEE ALSO

L<SSH::RPC::PP::Client>, L<SysFink>.

=head1 LICENSE

This file is part of SysFink. See L<SysFink> license.

=cut


1;
