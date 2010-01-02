use strict;
use warnings;

use Carp qw(carp croak verbose);
use Data::Dumper;

use Test::More;

use lib 'dist/_base/lib';

use lib 'lib';
use SysFink::Conf;

use lib 't/lib';
use SysFink::ScanData;
use SysFink::ScanHostTest;
use SysFink::FileHashTest;


my $debug_out = $ARGV[0] || 0;
my $test_num_to_run = $ARGV[1] || undef;

my @all_test_cases = SysFink::ScanData::get_test_test_cases();

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

    my $conf_obj = SysFink::Conf->new();
    my $prepared_paths = [ sort { $a->[0] cmp $b->[0] } @{ $test_case->{paths_to_scan} } ];
    $prepared_paths = $conf_obj->prepare_path_regexes( $prepared_paths );
    my $scan_conf = {
        'paths' => $prepared_paths,
        'debug_out' => $debug_out,
        'max_items_in_one_response' => $max_items_in_one_response,
    };
    # print Dumper( $scan_conf );

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

    #print Dumper( $all_results ); print Dumper( $joined_results );

    my $loaded = $joined_results->{loaded_items};
    my $test_name = $test_case->{tescase_name};
    my $ok = is_deeply( $loaded, $test_case->{expected}, $test_name );

    if ( $debug_out ) {
        if ( !$ok ) {
            print Dumper( { loaded=>$loaded, expected=>$test_case->{expected}, } );
        } elsif ( defined $test_num_to_run ) {
            print Dumper( $loaded );
        }
    }
}

is( $max_items_in_one_response_errors, 0, 'max_items_in_one_response test');