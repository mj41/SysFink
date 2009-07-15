use strict;
use warnings;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);

use lib "$RealBin/../lib";
use lib "$RealBin/../libext";

use SQL::Translator;

use Data::Dumper;

my $to = $ARGV[0] || 'dbix';
my $input_file = $ARGV[1] || './temp/schema-raw-create.sql';
my $debug = $ARGV[2] || 0;

print "to: $to, input '$input_file', debug: $debug\n" if $debug;

croak "Input file '$input_file' not found." unless -f $input_file;


# package - DBIx::Class - .pm
if ( $to eq 'dbix' || $to eq 'ALL' ) {
    my $translator = SQL::Translator->new(
        filename  => $input_file,
        parser    => 'MySQL',
        producer  => 'DBIx::Class::FileMJ',
        producer_args => {
            prefix => 'SysFink::DB::SchemaBase',
            base_class_name => 'SysFink::DB::DBIxClassBase',
        },
    ) or die SQL::Translator->error;

    my $out_fn = './lib/SysFink/DB/SchemaBase.pm';
    my $content = $translator->translate;
    my $fh;
    open ( $fh, '>', $out_fn ) || die $!;
    print $fh $content;
    close $fh;

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
