use strict;
use warnings;

use Carp qw(carp croak verbose);
use Data::Dumper;

use Test::More;

use lib 'lib';
use lib 'libext';
use SysFink::Server;
use SysFink::Conf;

use lib 't/lib';
use SysFink::ScanData;


my $ver = $ARGV[0] || 0;
my $test_num_to_run = $ARGV[1] || undef;

my @all_test_cases = SysFink::ScanData::get_test_test_cases();

my @test_nums = ( 0..$#all_test_cases );
@test_nums = ( $test_num_to_run-1 ) if defined $test_num_to_run;
plan tests => scalar( @test_nums );

my $max_items_in_one_response = 2;
my $max_items_in_one_response_errors = 0;
foreach my $num ( @test_nums ) {
    my $test_case = $all_test_cases[ $num ];

    my $conf_obj = SysFink::Conf->new();
    my $prepared_paths = $conf_obj->prepare_path_regexes( $test_case->{paths_to_scan} );
    # print Dumper( $prepared_paths ); # debug

    my $path_filter_conf = $conf_obj->get_path_filter_conf( $prepared_paths );
    #print Dumper( $path_filter_conf ); # debug

    my $server = SysFink::Server->new();
    $server->{ver} = $ver;
    $server->{host_conf}->{path_filter_conf} = $path_filter_conf;

    my $paths_expected = [];
    foreach my $val ( @{ $test_case->{expected} } ) {
        my $path = $val->{path};
        $path =~ s{\/$}{} if $path ne '/';
        push @$paths_expected, $path;
    }
    @$paths_expected = sort @$paths_expected;

    my $paths_to_test = [];
    foreach my $item ( @{ $test_case->{test_obj_conf} } ) {
        my $full_path;
        if ( ref $item eq 'ARRAY' ) {
            $full_path = $item->[ 0 ];
        } else {
            $full_path = $item;
        }
        my $path = $full_path;
        $path =~ s{\/$}{} if $path ne '/';
        push @$paths_to_test, $path;
    }
    @$paths_to_test = sort @$paths_to_test;

    my $paths_found = [];
    foreach my $path ( @$paths_to_test ) {
        my $found = $server->flags_or_regex_succeed( $path );
        # print "path: $path $found\n"; # debug
        push( @$paths_found, $path ) if $found;
    }

    my $test_name = $test_case->{tescase_name};
    my $ok = is_deeply( $paths_found, $paths_expected, $test_name );

    if ( $ver ) {
        if ( !$ok ) {
            print Dumper( { paths_found=>$paths_found, paths_expected=>$paths_expected, } );
        } elsif ( defined $test_num_to_run ) {
            print Dumper( $paths_found );
        }
    }
}
