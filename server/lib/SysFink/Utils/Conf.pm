package SysFink::Utils::Conf;

use strict;
use warnings;
use Carp qw(carp croak verbose);

use base 'Exporter';
our $VERSION = 0.10;
our @EXPORT = qw(load_conf_multi);

use Config::General;
use File::Spec::Functions;


=head2 load_conf_multi

Use same way as to load config as SysFink::Web and then delete all but required parts (keys).

=cut

sub load_conf_multi {
    my ( $conf_fpath, @keys ) = @_;

    $conf_fpath = catfile( $FindBin::Bin , '..', 'conf', 'sysfink.conf' ) unless defined $conf_fpath;
    die "No config file '$conf_fpath' found." unless -f $conf_fpath;

    my $cg_obj = Config::General->new(
         -ConfigFile => $conf_fpath,
    );
    my %conf = $cg_obj->getall();

    if ( scalar(@keys) ) {
        my %keys = map { $_ => 1 } @keys;
        foreach my $key ( keys %conf ) {
            unless ( exists $keys{$key} ) {
                delete $conf{$key};
            }
        }
    }

    return \%conf;
}

1;