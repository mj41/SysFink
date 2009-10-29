#!/bin/bash

if [ -z "$2" ]; then
    echo "Usage:"
    echo "  utils/test-new.sh hostname.example.com verbosity_level"
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

echo "Online tests on host '$HOST':"
echo ""

perl sysfink-new.pl --user=root --host=$HOST --cmd=test_hostname --ver=$VER

perl sysfink-new.pl --user=root --host=$HOST --cmd=check_client_dir --ver=$VER
perl sysfink-new.pl --user=root --host=$HOST --cmd=remove_client_dir --ver=$VER

perl sysfink-new.pl --user=root --host=$HOST --cmd=renew_client_dir --ver=$VER

perl sysfink-new.pl --user=root --host=$HOST --cmd=test_noop_rpc --ver=$VER

perl sysfink-new.pl --user=root --host=$HOST --cmd=test_three_parts_rpc --ver=$VER

echo ""
