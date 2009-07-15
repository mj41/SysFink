use strict;
use warnings;

use Carp qw(carp croak verbose);
use FindBin qw($RealBin);

use lib "$RealBin/../lib";
use lib "$RealBin/../libext";

my $input_file = $ARGV[0] || './temp/schema-raw-create.sql';

croak "Input file '$input_file' not found." unless -f $input_file;

my $in_data = do {
    local $/;
    open INFH, $input_file or croak $!;
    <INFH>;
};

$in_data =~ s{(SET\s+FOREIGN_KEY_CHECKS\=[01]\;\s*\n?)}{-- $1}gisx;

$in_data =~ s{(begin\s+transaction;\s*\n?)}{-- $1}gisx;
$in_data =~ s{(commit;\s*\n?)}{-- $1}gisx;

print $in_data;
