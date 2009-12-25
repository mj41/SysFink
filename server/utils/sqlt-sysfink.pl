use strict;
use warnings;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);

use lib "$RealBin/../lib";
use lib "$RealBin/../libext";

use SQL::Translator;
use SQL::Translator::Utils::GenDoc qw/produce_db_doc/;

use Data::Dumper;

my $to = $ARGV[0] || 'dbix';
my $input_file = $ARGV[1] || './temp/schema-raw-create.sql';
my $ver = $ARGV[2] || 3;

my $producer_prefix = 'SysFink::DB::Schema';
my $producer_base_class_name = 'SysFink::DB::DBIxClassBase';
my $table_name_url_prefix = 'http://dev.taptinder.org/wiki/DB_Schema#';

print "to: $to, input '$input_file', ver $ver\n" if $ver >= 3;

croak "Input file '$input_file' not found." unless -f $input_file;


# package - DBIx::Class - .pm
if ( $to eq 'dbix' || $to eq 'ALL' ) {
    my $translator = SQL::Translator->new(
        filename  => $input_file,
        parser    => 'MySQL',
        producer  => 'DBIx::Class::FileMJ',
        producer_args => {
            prefix => $producer_prefix,
            base_class_name => $producer_base_class_name,
        },
    ) or die SQL::Translator->error;

    my $out_fn = './lib/SysFink/DB/Schema.pm';
    my $content = $translator->translate;
    my $fh;
    open ( $fh, '>', $out_fn ) || die $!;
    print $fh $content;
    close $fh;

} elsif ( $to eq 'dbdoc' || $to eq 'ALL' ) {
    produce_db_doc(
        $ver,
        $input_file,
        $table_name_url_prefix
    );

} elsif ( $to eq 'sqlite' || $to eq 'ALL' ) {

     my $in_data = do {
        local $/;
        open INFH, $input_file or croak $!;
        <INFH>;
    };
    $in_data =~ s{SET\s+FOREIGN_KEY_CHECKS\=[01]\;\s*\n?}{}gisx;
    $in_data =~ s{begin\s+transaction;\s*\n?}{}gisx;
    $in_data =~ s{commit;\s*\n?}{}gisx;
    print $in_data;
    #exit;

    my $translator = SQL::Translator->new(
        data  => $in_data,
        parser    => 'MySQL',
        producer  => 'SQLite',
    ) or croak SQL::Translator->error;

    my $content = $translator->translate;
    print $content;
}
