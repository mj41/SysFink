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

use SysFink::ScanHostTest;
use SysFink::FileHashTest;

my $debug_out = $ARGV[0] || 0;
my $test_num_to_run = $ARGV[1] || undef;

my $default_flags = {
   'S' => '-',
   'B' => '-',
   'H' => '-',
   'M' => '+',
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
        '/',
        '/etc/',
        '/myfile',
    ];

    $test_case->{paths_to_scan} = [
        [ '', $default_flags, ],
    ];

    $test_case->{expected} = [
        {
            'mode' => 16877,
            'path' => '/'
        },
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
        '/',
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
            'path' => '/'
        },
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
        },
    ];

    push @all_test_cases, $test_case;
}


# --- test 3 -----------------------------------------------------------------
{
    my $test_case = {};
    $test_case->{tescase_name} = 'skip some items';

    $test_case->{test_obj_conf} = [
        '/',
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
            'path' => '/'
        },
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
    $test_case->{tescase_name} = 'items included inside excluded dir, root dir excluded';

    $test_case->{test_obj_conf} = [
        '/',
        '/etc/',
        '/home/',
        '/home/file1',
        '/home/mjdir/',
        '/home/mjdir/subfile2no',
        '/home/mjdir/subfile3yes',
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
        [ '', $skip_flags ],
        [ '/', $my_flags ],
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


# --- test 5 -----------------------------------------------------------------
{
    my $test_case = {};
    $test_case->{tescase_name} = "dir vs. dir's content, duplicated conf";

    $test_case->{test_obj_conf} = [
        '/',
        '/aroot-file1',
        '/home/',
        '/home/file2',
        '/home/mjdir/',
        '/home/mjdir/fileC',
        '/home/mjdir/subdirA/',
        '/home/mjdir/subdirA/file3',
        '/home/mjdir/subdirA/subdirB1/',
        '/home/mjdir/subdirA/subdirB1/file4',
        '/home/mjdir/subdirA/subdirB1/file5',
        '/home/mjdir/subdirA/subdirB2/',
        '/home/mjdir/subdirA/subdirB2/file6',
        '/home/mjdir/subdirA/subdirB2/file7',
        '/home/mjdir/subdirA/subdirB3/',
        '/home/mjdir/subdirA/subdirB3/file8',
        '/home/mjdir/subdirA/subdirB3/file9',
        '/tmp/',
        '/tmp/tmp.11',
    ];

    my $my_flags = { %$default_flags };
    $my_flags->{5} = '-';
    $test_case->{paths_to_scan} = [
        [ '', $my_flags ],
        [ '/', $skip_flags ],

        # duplicated conf
        [ '/home', $my_flags ],
        [ '/home/mjdir/', $skip_flags ],
        [ '/home', $my_flags ],
        [ '/home/mjdir/', $skip_flags ],

        [ '/home/mjdir/subdirA/subdirB1', $my_flags ],
        [ '/home/mjdir/subdirA/subdirB2/', $skip_flags ],
        [ '/home/mjdir/subdirA/subdirB3', $my_flags ],
        [ '/home/mjdir/subdirA/subdirB3/', $skip_flags ],
    ];

    $test_case->{expected} = [
        {
            'mode' => 16877,
            'path' => '/'
        },
        {
            'mode' => 16877,
            'path' => '/home'
        },
        {
            'mode' => 33188,
            'path' => '/home/file2'
        },
        {
            'mode' => 16877,
            'path' => '/home/mjdir'
        },
        {
            'mode' => 16877,
            'path' => '/home/mjdir/subdirA/subdirB1'
        },
        {
            'mode' => 33188,
            'path' => '/home/mjdir/subdirA/subdirB1/file4'
        },
        {
            'mode' => 33188,
            'path' => '/home/mjdir/subdirA/subdirB1/file5'
        },
        {
            'mode' => 16877,
            'path' => '/home/mjdir/subdirA/subdirB3'
        }
    ];
    push @all_test_cases, $test_case;
}


# --- test 6 -----------------------------------------------------------------
{
    my $test_case = {};
    $test_case->{tescase_name} = 'two simple items';

    $test_case->{test_obj_conf} = [
        '/',
        '/etc/',
        '/myfile',
    ];

    $test_case->{paths_to_scan} = [
        [ '', $default_flags, ],
        [ '/unknow-name-xyz', $default_flags, ],
    ];

    $test_case->{expected} = [
        {
            'mode' => 16877,
            'path' => '/'
        },
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


# ----------------------------------------------------------------------------

my @test_nums = ( 0..$#all_test_cases );
@test_nums = ( $test_num_to_run-1 ) if defined $test_num_to_run;
plan tests => scalar( @test_nums ) + 1;

my $max_items_in_one_response = 2;
my $max_items_in_one_response_errors = 0;
foreach my $num ( @test_nums ) {
    my $test_case = $all_test_cases[ $num ];

    my $shared_data = {};
    my $hash_obj = SysFink::FileHashTest->new();
    my $scan_obj = SysFink::ScanHostTest->new( $test_case->{test_obj_conf}, $hash_obj );

    my $scan_conf = {
        'paths' => [ sort { $a->[0] cmp $b->[0] } @{ $test_case->{paths_to_scan} } ],
        'debug_out' => $debug_out,
        'max_items_in_one_response' => $max_items_in_one_response,
    };

    my $ret_code = $scan_obj->run_scan_host( $scan_conf );
    my $all_results = $scan_obj->get_all_results();

    my $joined_results = {};
    $joined_results->{errors} = [];
    $joined_results->{loaded_items} = [];
    foreach my $result ( @$all_results ) {

        # $max_items_in_one_response check
        if ( scalar(@{$result->{response}->{loaded_items}}) > $max_items_in_one_response ) {
            $max_items_in_one_response_errors++;
        }

        $joined_results->{loaded_items} = [
            @{$joined_results->{loaded_items}},
            @{$result->{response}->{loaded_items}}
        ];
        $joined_results->{errors} = [
            @{$joined_results->{errors}},
            @{$result->{response}->{errors}}
        ];
    }

    #use Data::Dumper; print Dumper( $all_results ); print Dumper( $joined_results );

    my $loaded = $joined_results->{loaded_items};
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

is( $max_items_in_one_response_errors, 0, 'max_items_in_one_response test');