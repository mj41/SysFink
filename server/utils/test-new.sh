#!/bin/bash

if [ -z "$2" ]; then
    echo "Usage:"
    echo "  utils/test-new.sh hostname.example.com verbosity_level linux-bin-64b"
    echo ""
    echo "Example:"
    echo "  utils/test-new.sh gorilla 3 linux-perl-md5"
    exit
fi 

clear

echo "Harness tests on server:"
perl t/harness.pl
echo ""

echo "Harness tests on client:"
cd ../client && perl t/harness.pl
cd ../server
echo ""

HOST="$1"
VER="$2"
DIST_TYPE="$3"

echo "Online tests on host '$HOST':"
echo ""

perl sysfink.pl --user=root --host=$HOST --cmd=test_hostname --ver=$VER

perl sysfink.pl --user=root --host=$HOST --cmd=check_client_dir --ver=$VER
echo ""

perl sysfink.pl --user=root --host=$HOST --cmd=remove_client_dir --ver=$VER
echo ""

perl sysfink.pl --user=root --host=$HOST --cmd=renew_client_dir --host_dist_type=$DIST_TYPE --ver=$VER
echo ""

perl sysfink.pl --user=root --host=$HOST --cmd=test_noop_rpc --ver=$VER
echo ""

perl sysfink.pl --user=root --host=$HOST --cmd=test_three_parts_rpc --ver=$VER
echo ""

echo "Running 'perl ... --cmd=scan_test | tail -n 10':"
perl sysfink.pl --user=root --host=$HOST --cmd=scan_test --ver=$VER | tail -n 10

echo ""
