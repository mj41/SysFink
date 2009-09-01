use strict;
use warnings;
use Test::More;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);
use File::Spec::Functions;

use lib 't/lib';

use lib 'lib';
use lib 'libext';
use lib 'dist/_base';

use SysFinkRunObjBase; # SysFink::ScanHost
use SysFinkScanHost; # SysFink::ScanHost
use SysFinkScanHostTest; # SysFink::ScanHostTest
use SysFinkFileHashTest; # SysFink::FileHashTest

my $debug_out = $ARGV[0] || 0;
my $test_num_to_run = $ARGV[1] || undef;

my $default_flags = {
   'S' => '+',
   'B' => '-',
   'H' => '+',
   'M' => '+',
   'D' => '+',
   'G' => '+',
   'L' => '+',
   'U' => '+',
   '5' => '+'
};

my $skip_flags = {
   'S' => '-',
   'B' => '-',
   'H' => '-',
   'M' => '-',
   'D' => '-',
   'G' => '-',
   'L' => '-',
   'U' => '-',
   '5' => '-'
};

my @all_test_cases = ();


# --- test 1 -----------------------------------------------------------------
{
    my $test_case = {};
    $test_case->{tescase_name} = 'two simple items';

    $test_case->{test_obj_conf} = [
        '/etc/',
        '/myfile',
    ];

    $test_case->{paths_to_scan} = [
        [ '/*', $default_flags, ],
    ];

    $test_case->{expected} = [
        {
            'mode' => 'drwxr-xr-x',
            'path' => '/etc'
        },
        {
            'hash' => 'HASH:/myfile',
            'mode' => '-rw-r--r--',
            'path' => '/myfile'
        },
    ];

    push @all_test_cases, $test_case;
}


# --- test 2 -----------------------------------------------------------------
{
    my $test_case = {};
    $test_case->{tescase_name} = 'more items, mode modification';

    $test_case->{test_obj_conf} = [
        '/etc/',
        '/etc/passwd',
        '/home/',
        '/tmp/',
        [ '/tmp/myfile', { mode => 16876, }, ],
    ];

    $test_case->{paths_to_scan} = [
        [ '/*', $default_flags, ],
    ];

    $test_case->{expected} = [
        {
            'mode' => 'drwxr-xr-x',
            'path' => '/etc'
        },
        {
            'mode' => 'drwxr-xr-x',
            'path' => '/home'
        },
        {
            'mode' => 'drwxr-xr-x',
            'path' => '/tmp'
        },
        {
            'hash' => 'HASH:/etc/passwd',
            'mode' => '-rw-r--r--',
            'path' => '/etc/passwd'
        },
        {
            'mode' => 'drwxr-xr--',
            'path' => '/tmp/myfile'
        }
    ];

    push @all_test_cases, $test_case;
}


# --- test 3 -----------------------------------------------------------------
{
    my $test_case = {};
    $test_case->{tescase_name} = 'skip some items';

    $test_case->{test_obj_conf} = [
        '/etc/',
        '/home/',
        '/home/file1',
        '/home/mjdir/',
        '/home/mjdir/sfile2',
        '/tmp/',
        '/tmp/somefile',
        '/tmp/sdir/',
    ];

    my $my_flags = { %$default_flags };
    $my_flags->{5} = '-';
    $test_case->{paths_to_scan} = [
        [ '/*', $my_flags ],
        [ '/tmp/*', $skip_flags ],
        [ '/home/mjdir/*', { '5' => '+' } ],
    ];

    $test_case->{expected} = [
        {
            'mode' => 'drwxr-xr-x',
            'path' => '/etc'
        },
        {
            'mode' => 'drwxr-xr-x',
            'path' => '/home'
        },
        {
            'mode' => '-rw-r--r--',
            'path' => '/home/file1'
        },
        {
            'mode' => 'drwxr-xr-x',
            'path' => '/home/mjdir'
        },
        {
            'hash' => 'HASH:/home/mjdir/sfile2',
            'mode' => '-rw-r--r--',
            'path' => '/home/mjdir/sfile2'
        },
    ];
    push @all_test_cases, $test_case;
}

# ----------------------------------------------------------------------------

my @test_nums = ( 0..$#all_test_cases );
@test_nums = ( $test_num_to_run-1 ) if defined $test_num_to_run;
plan tests => scalar( @test_nums );
foreach my $num ( @test_nums ) {
    my $test_case = $all_test_cases[ $num ];

    my $shared_data = {};
    my $hash_obj = SysFink::FileHashTest->new();
    my $scan_obj = SysFink::ScanHostTest->new( $test_case->{test_obj_conf}, $shared_data, $hash_obj );

    my $scan_conf = {
        'paths' => $test_case->{paths_to_scan},
        'debug_out' => $debug_out,
    };

    my $ret_code = $scan_obj->scan( $scan_conf );
    my %result = $scan_obj->get_result();

    unless ( $ret_code ) {
        foreach my $error ( @{ $result{errors} } ) {
            print "$error\n";
        }
    }

    my $loaded = $result{loaded_items};
    my $test_name = $test_case->{tescase_name};
    my $ok = is_deeply( $loaded, $test_case->{expected}, $test_name );

    if ( $debug_out ) {
        use Data::Dumper;
        if ( !$ok ) {
            print Dumper( { loaded=>$loaded, expected=>$test_case->{expected}, } );
        } elsif ( defined $test_num_to_run ) {
            print Dumper( $loaded );
        }
    }
}