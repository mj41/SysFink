#! perl

use strict;
use warnings;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);

use DBI;
use Config::General;
use File::Spec::Functions;

use lib "$RealBin/../lib";
use SysFink::Utils::Cmd qw(run_cmd_ipc);

my $sql_fpath = $ARGV[0] || undef;
my $noipc = $ARGV[1] || 0;


sub run_mysql {
    my ( $sql_fpath, $noipc, $conf ) = @_;

    croak "Database name not found.\n" unless $conf->{db}->{name};
    croak "Database user name not found.\n" unless $conf->{db}->{user};
    croak "Database user password not found.\n" unless $conf->{db}->{pass};

    my $cmd = 'mysql -u ' . $conf->{db}->{user};
    if ( $noipc ) {
        $cmd .= " -p'" . $conf->{db}->{pass} . "'";
    } else {
        $cmd .= ' -p';
    }
    $cmd .= ' ' . $conf->{db}->{name};
    $cmd .= ' < ' . $sql_fpath;
    #print "cmd: '$cmd'\n";

    # TODO IPC version (no password on command line or process list)

    print "Running SQL file on database '$conf->{db}->{name}':\n";
    my $msg = "Enter database password for user '$conf->{db}->{user}': ";
    SysFink::Utils::Cmd::run_cmd_ipc( $cmd, $noipc, $msg );
}


sub run_sqlite {
    my ( $sql_fpath, $noipc, $conf ) = @_;

    croak "Database name not found.\n" unless $conf->{db}->{name};
    my $db_file_name = $conf->{db}->{name} . '.db';

    my $sqlite_cmd_fpath = catfile( $RealBin, '..', 'temp', 'sqlite-cmd-file.sqlite' );

    my $cmd_fh;
    open( $cmd_fh, '>', $sqlite_cmd_fpath ) or croak "Can't open file '$sqlite_cmd_fpath' for write: $!";
    print $cmd_fh <<END_CMD_FILE;
.read ${sql_fpath}
.tables
.quit
END_CMD_FILE
    close $cmd_fh or croak "Can't close '$sqlite_cmd_fpath': $!";

    my $cmd = 'sqlite3 ' . $db_file_name;
    $cmd .= ' < ' . $sqlite_cmd_fpath;

    print "Running SQL file on SQLite database '$db_file_name':\n";
    SysFink::Utils::Cmd::run_cmd_ipc( $cmd, 0 );
}


croak "SQL file '$sql_fpath' not found." unless -f $sql_fpath;

my $conf_fpath = catfile( $RealBin, '..', 'conf', 'sysfink.conf' );
my $cg_obj = Config::General->new( -ConfigFile => $conf_fpath, );
my $conf = { $cg_obj->getall() };
croak "Configuration for database loaded from '$conf_fpath' is empty.\n" unless $conf->{db};

croak "Database 'dbi_dsn' not found.\n" unless $conf->{db}->{dbi_dsn};

my ( $db_type ) = $conf->{db}->{dbi_dsn} =~ /^dbi\:(.+?)\:/i;
$db_type = lc( $db_type );

if ( $db_type eq 'sqlite' ) {
    run_sqlite( $sql_fpath, $noipc, $conf );
} else {
    run_mysql( $sql_fpath, $noipc, $conf );
}

