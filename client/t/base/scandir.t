use strict;
use warnings;
use Test::More;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);
use File::Spec::Functions;

use lib 't/lib';

use lib 'lib';
use lib 'libext';
use lib 'dist/_base/lib';

use SysFinkScanHostTest; # SysFink::ScanHostTest
use SysFinkFileHashTest; # SysFink::FileHashTest

my $debug_out = $ARGV[0] || 0;
my $test_num_to_run = $ARGV[1] || undef;

my $default_flags = {
   'S' => '-',
   'B' => '+',
   'H' => '-',
   'M' => '-',
   'D' => '-',
   'G' => '-',
   'L' => '-',
   'U' => '-',
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
        [ '', $default_flags, ],
    ];

    $test_case->{expected} = [
        {
            'mode' => 16877,
            'path' => '/etc'
        },
        {
            'hash' => 'HASH:/myfile',
            'mode' => 33188,
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
        [ '', $default_flags, ],
    ];

    $test_case->{expected} = [
        {
            'mode' => 16877,
            'path' => '/etc'
        },
        {
            'mode' => 16877,
            'path' => '/home'
        },
        {
            'mode' => 16877,
            'path' => '/tmp'
        },
        {
            'hash' => 'HASH:/etc/passwd',
            'mode' => 33188,
            'path' => '/etc/passwd'
        },
        {
            'mode' => 16876,
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
        [ '', $my_flags ],
        [ '/home/mjdir', { '5' => '+' } ],
        [ '/tmp', $skip_flags ],
    ];

    $test_case->{expected} = [
        {
            'mode' => 16877,
            'path' => '/etc'
        },
        {
            'mode' => 16877,
            'path' => '/home'
        },
        {
            'mode' => 33188,
            'path' => '/home/file1'
        },
        {
            'mode' => 16877,
            'path' => '/home/mjdir'
        },
        {
            'hash' => 'HASH:/home/mjdir/sfile2',
            'mode' => 33188,
            'path' => '/home/mjdir/sfile2'
        },
    ];
    push @all_test_cases, $test_case;
}

# --- test 4 -----------------------------------------------------------------
{
    my $test_case = {};
    $test_case->{tescase_name} = 'items included inside excluded dir';

    $test_case->{test_obj_conf} = [
        '/etc/',
        '/home/',
        '/home/file1',
        '/home/mjdir/',
        '/home/mjdir/sfile2no',
        '/home/mjdir/sfile3yes',
        '/home/mjdir/subdir/',
        '/home/mjdir/subdir/subfile4yes',
        '/home/mjdir/asdir1/',
        '/home/mjdir/asdir1/asdir2/',
        '/home/mjdir/asdir1/asdir2/sfile5no',
        '/home/mjdir/asdir1/asdir2/asdir3/',
        '/home/mjdir/asdir1/asdir2/asdir3/sfile6yes',
        '/home/mjdir/asdir1/asdir2/asdir3/sfile7no',
        '/tmp/',
        '/tmp/somefile',
        '/tmp/sdir/',
    ];

    my $my_flags = { %$default_flags };
    $my_flags->{5} = '-';
    $test_case->{paths_to_scan} = [
        [ '', $my_flags ],
        [ '/home/mjdir', $skip_flags ],
        [ '/home/mjdir/subfile3yes', { '5' => '+' } ],
        [ '/home/mjdir/asdir1/asdir2/asdir3/sfile6yes', { '5' => '+' } ],
        [ '/home/mjdir/subdir', { '5' => '+' } ],
        [ '/tmp', $skip_flags ],
    ];

    $test_case->{expected} = [
        {
            'mode' => 16877,
            'path' => '/etc'
        },
        {
            'mode' => 16877,
            'path' => '/home'
        },
        {
            'mode' => 33188,
            'path' => '/home/file1'
        },
        {
            'hash' => 'HASH:/home/mjdir/asdir1/asdir2/asdir3/sfile6yes',
            'mode' => 33188,
            'path' => '/home/mjdir/asdir1/asdir2/asdir3/sfile6yes'
        },
        {
            'mode' => 16877,
            'path' => '/home/mjdir/subdir'
        },
        {
            'hash' => 'HASH:/home/mjdir/subdir/subfile4yes',
            'mode' => 33188,
            'path' => '/home/mjdir/subdir/subfile4yes'
        },
        {
            'hash' => 'HASH:/home/mjdir/subfile3yes',
            'mode' => 33188,
            'path' => '/home/mjdir/subfile3yes'
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
        'paths' => [ sort { $a->[0] cmp $b->[0] } @{ $test_case->{paths_to_scan} } ],
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