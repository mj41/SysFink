use strict;
use warnings;
use Test::More tests => 20;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);
use File::Spec::Functions;

use lib 'lib';
use lib 'libext';

use SysFink::Conf::SysFink;


my $conf_obj = SysFink::Conf::SysFink->new({
    conf_dir_path => catdir( $RealBin, '..', 'conf-data', 'tconf-1-sysfink' )
});

isa_ok( $conf_obj, 'SysFink::Conf::SysFink' );
isa_ok( $conf_obj, 'SysFink::Conf' );


# splitq method tests

my @spliq_conf_cases = (
    [ 'text', [ 'text' ], undef ],
    [ 'part1, part2,part3', [ 'part1', 'part2', 'part3' ], undef ],
    [ 'part1   part2 part3', [ 'part1', 'part2', 'part3' ], undef ],

    [ '"qtext"', [ 'qtext' ], undef ],
    [ '"qpart1", "qpart2"', [ 'qpart1', 'qpart2' ], undef ],
    [ '"qsep part 1", "qsep part 2","qsep part 3"', [ 'qsep part 1', 'qsep part 2', 'qsep part 3' ], undef ],

    [ '"qtext" text', [ 'qtext', 'text' ], undef ],
    [ '"qtext", text', [ 'qtext', 'text' ], undef ],

    [ 'quote\"_in_not_quoted_text', [ 'quote"_in_not_quoted_text' ], undef ],
    [ '\"quote_as_first_char_in_not_quoted_text', [ '"quote_as_first_char_in_not_quoted_text' ], undef ],
    [ 'part1_quote\"_in_not_quoted_text, part2', [ 'part1_quote"_in_not_quoted_text', 'part2' ], undef ],

    [ '"qtext \\" qinside"', [ 'qtext " qinside' ], undef ],
    [ '"qtext \\" qinside",part2, "qsep \\"part 3"', [ 'qtext " qinside', 'part2', 'qsep "part 3' ], undef ],

);

#use Data::Dumper; print Dumper( $spliq_conf_cases[10-1] );
foreach my $conf_num ( 0..$#spliq_conf_cases ) {
    my $conf = $spliq_conf_cases[ $conf_num ];
    my ( $text, $expected, $todo_reason ) = @$conf;

    my $test_name = "splitq test " . ($conf_num+1) . ' - ' . $text;

    my @got = $conf_obj->splitq( $text );
    if ( defined $todo_reason ) {
        TODO: {
            local $TODO = $todo_reason;
            is_deeply( [ @got ], $expected, $test_name );
        };
    } else {
        is_deeply( [ @got ], $expected, $test_name );
    }

}



# process_config_file_content method tests

my @conf_cases = ();
my ( $test_case_content, $test_case_expected_results );


# test case 1
$test_case_content = <<TEST_CASE_CONTENT;
hostname    gorilla-sysfink-tc1.test.sysfink.org
TEST_CASE_CONTENT

$test_case_expected_results = {};
$test_case_expected_results->{general} = {
    'hostname' => 'gorilla-sysfink-tc1.test.sysfink.org',
};

push @conf_cases, [ $test_case_content, $test_case_expected_results ];


# test case 2
$test_case_content = <<TEST_CASE_CONTENT;
comment     "Complicated text comment 2 \\" 3", part2
TEST_CASE_CONTENT
# fix my editor syntax highlighting - "

$test_case_expected_results = {};
$test_case_expected_results->{general} = {
    'comment' => [ 'Complicated text comment 2 " 3', 'part2', ],
};

push @conf_cases, [ $test_case_content, $test_case_expected_results ];


# test case 3
$test_case_content = <<TEST_CASE_CONTENT;
hostname    gorilla-sysfink-tc2.test.sysfink.org
comment     "Text comment"
TEST_CASE_CONTENT

$test_case_expected_results = {};
$test_case_expected_results->{general} = {
    'hostname' => 'gorilla-sysfink-tc2.test.sysfink.org',
    'comment' => 'Text comment',
};

push @conf_cases, [ $test_case_content, $test_case_expected_results ];


# test case 4
$test_case_content = <<TEST_CASE_CONTENT;
comment     "Text comment part 1"
hostname    gorilla-sysfink.test.sysfink.org
comment     "Text comment part 2"
TEST_CASE_CONTENT

$test_case_expected_results = {};
$test_case_expected_results->{general} = {
    'hostname' => 'gorilla-sysfink.test.sysfink.org',
    'comment' => [ "Text comment part 1", "Text comment part 2", ]
};

push @conf_cases, [ $test_case_content, $test_case_expected_results ];


# test case 5
$test_case_content = <<TEST_CASE_CONTENT;
[general]
  hostname    gorilla-sysfink.test.sysfink.org
  comment     "Text comment part 1 section 1"
  comment     "Text comment part 2 section 1"
[empty_section]
[second_section]
  comment     "Text comment part 1 section 2"
  comment     "Text comment part 2 section 2"
TEST_CASE_CONTENT

$test_case_expected_results = {};
$test_case_expected_results->{general} = {
    'hostname' => 'gorilla-sysfink.test.sysfink.org',
    'comment' => [ "Text comment part 1 section 1", "Text comment part 2 section 1", ]
};
$test_case_expected_results->{empty_section} = {};
$test_case_expected_results->{second_section} = {
    'comment' => [ "Text comment part 1 section 2", "Text comment part 2 section 2", ]
};

push @conf_cases, [ $test_case_content, $test_case_expected_results ];


#use Data::Dumper; print Dumper( \@conf_cases );
#use Data::Dumper; print Dumper( $conf_cases[2-1] );
foreach my $conf_num ( 0..$#conf_cases ) {
    my $host_name = 'host-sysfink-' . $conf_num;
    my $test_name = "process_config_file_content test " . ($conf_num+1);

    my $conf = $conf_cases[ $conf_num ];
    my ( $file_content, $host_conf_expected_base ) = @$conf;
    my $host_conf_expected = {
        $host_name => $host_conf_expected_base,
    };

    $conf_obj->conf( undef );
    $conf_obj->process_config_file_content( $host_name, $file_content, 0 );
    my $host_conf_got = $conf_obj->conf;
    is_deeply( $host_conf_got, $host_conf_expected, $test_name );

    #use Data::Dumper; print Dumper( $host_conf_got );
    #use Data::Dumper; print Dumper( $host_conf_expected );
}
