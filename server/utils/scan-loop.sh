#!/bin/bash

if [ -z "$2" ]; then
    echo "Usage:"
    echo "  utils/scan-loop.sh hostname verbosity_level [sleep_time]"
    echo ""
    echo "  nice -n 10 utils/scan-loop.sh tapir1 3 | tee temp/scan-loop-out.txt"
    echo ""
    exit
fi

# mandatory
HOST="$1"
VER="$2"

# optional
SLEEP_TIME="$3"
if [ -z "$SLEEP_TIME" ]; then
    SLEEP_TIME=30
fi


for ((i=1;1;i++)); do
    echo "Run number: " $i
    date
    echo ""
    
    echo "Running --cmd=mconf_to_db:"
    perl sysfink.pl --cmd=mconf_to_db
    echo ""
    
    echo "Running --cmd=renew_client_dir"
    perl sysfink.pl --host=$HOST --cmd=renew_client_dir --ver=$VER
    echo ""

    echo "Running $HOST 'tmpscan':"
    perl sysfink.pl --host=$HOST --cmd=scan --section=tmpscan --ver=$VER
    echo ""

    echo "Running 'diff' on 'tmpscan' section:"
    perl sysfink.pl --cmd=diff --host=$HOST --section=tmpscan --ver=$VER
    echo ""

    echo "Running $HOST 'fastscan':"
    perl sysfink.pl --host=$HOST --cmd=scan --section=fastscan --ver=$VER
    echo ""

    echo "Running 'diff' on 'fastscan' section:"
    perl sysfink.pl --cmd=diff --host=$HOST --section=fastscan --ver=$VER
    echo ""

    echo "Sleeping $SLEEP_TIME s ..."
    sleep $SLEEP_TIME

    echo ""
    echo ""
done 

