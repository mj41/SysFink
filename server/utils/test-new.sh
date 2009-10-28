#!/bin/bash

clear

if [ -z "$2" ]; then
    echo "Usage:"
    echo "  utils/test-new.sh hostname.example.com verbosity_level"
    exit
fi 

HOST="$1"
VER="$2"

perl sysfink-new.pl --user=root --host=$HOST --cmd=test_hostname --ver=$VER

perl sysfink-new.pl --user=root --host=$HOST --cmd=check_client_dir --ver=$VER
perl sysfink-new.pl --user=root --host=$HOST --cmd=remove_client_dir --ver=$VER

perl sysfink-new.pl --user=root --host=$HOST --cmd=renew_client_dir --ver=$VER

perl sysfink-new.pl --user=root --host=$HOST --cmd=test_noop_rpc --ver=$VER
