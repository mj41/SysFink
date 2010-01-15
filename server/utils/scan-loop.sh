#!/bin/bash

if [ -z "$3" ]; then
    echo "Usage:"
    echo "  utils/scan-loop.sh hostname verbosity_level do_full_scan [sleep_time]"
    echo ""
    echo "  utils/scan-loop.sh tapir1 3 0 30"
    echo ""
    echo "  nice -n 10 utils/scan-loop.sh tapir1 3 1 1800 | tee temp/scan-loop-out.txt"
    echo ""
    exit
fi

# mandatory
HOST="$1"
VER="$2"
DO_FULL_SCAN="$3"

# optional
SLEEP_TIME="$4"
if [ -z "$SLEEP_TIME" ]; then
    SLEEP_TIME=1800
fi

DO_TEST_SCAN=1

echo "Parameters:"
echo "  host: $HOST"
echo "  verbosity: $VER"
echo "  do full scan: $DO_FULL_SCAN"
echo "  sleep time: $SLEEP_TIME"
echo "  test scan: $TEST_SCAN"
echo ""

for ((inum=1;1;inum++)); do
    echo "Run number $inum"

    echo "Running --cmd=mconf_to_db:"
    perl sysfink.pl --cmd=mconf_to_db
    echo ""
    
    echo "Running --cmd=renew_client_dir"
    perl sysfink.pl --host=$HOST --cmd=renew_client_dir --ver=$VER
    echo ""


    if [ "$DO_FULL_SCAN" = "1" ]; then
        echo "Running full scan on $HOST:"
        time perl sysfink.pl --host=$HOST --cmd=scan --ver=$VER
        echo ""

        echo "Running full 'diff' for host $HOST:"
        time perl sysfink.pl --cmd=diff --host=$HOST --ver=$VER
        echo ""

        echo "Running full 'audit' for host $HOST:"
        time perl sysfink.pl --cmd=audit --host=$HOST --ver=$VER
        echo ""
        echo ""
    fi


    for ((jnum=1;jnum<=24;jnum++)); do
        echo -n "Fast run number $jnum - "
        date
        echo ""

        if [ "$DO_TEST_SCAN" = "1" ]; then

            echo "Running 'testscanA' on $HOST:"
            perl sysfink.pl --host=$HOST --cmd=scan --section=testscanA --ver=$VER
            echo ""

            echo "Running 'diff' for section 'testscanA' and host $HOST:"
            perl sysfink.pl --cmd=diff --host=$HOST --section=testscanA --ver=$VER
            echo ""

            echo "Running 'audit' for section 'testscanA' and host $HOST:"
            perl sysfink.pl --cmd=audit --host=$HOST --section=testscanA --ver=$VER
            echo ""


            echo "Running 'testscanB' on $HOST:"
            perl sysfink.pl --host=$HOST --cmd=scan --section=testscanB --ver=$VER
            echo ""

            echo "Running 'diff' for section 'testscanB' and host $HOST:"
            perl sysfink.pl --cmd=diff --host=$HOST --section=testscanB --ver=$VER
            echo ""

            echo "Running 'audit' for section 'testscanB' and host $HOST:"
            perl sysfink.pl --cmd=audit --host=$HOST --section=testscanB --ver=$VER
            echo ""

        else 

            echo "Running 'tmpscan' on $HOST:"
            perl sysfink.pl --host=$HOST --cmd=scan --section=tmpscan --ver=$VER
            echo ""

            echo "Running 'diff' for section 'tmpscan' and host $HOST:"
            perl sysfink.pl --cmd=diff --host=$HOST --section=tmpscan --ver=$VER
            echo ""
            
            echo "Running 'audit' for section 'tmpscan' and host $HOST:"
            perl sysfink.pl --cmd=audit --host=$HOST --section=tmpscan --ver=$VER
            echo ""


            echo "Running 'fastscan' on $HOST:"
            perl sysfink.pl --host=$HOST --cmd=scan --section=fastscan --ver=$VER
            echo ""

            echo "Running 'diff' for section 'fastscan' and host $HOST:"
            perl sysfink.pl --cmd=diff --host=$HOST --section=fastscan --ver=$VER
            echo ""

            echo "Running 'audit' for section 'fastscan' and host $HOST:"
            perl sysfink.pl --cmd=audit --host=$HOST --section=fastscan --ver=$VER
            echo ""

        fi

        echo "Sleeping $SLEEP_TIME s ..."
        sleep $SLEEP_TIME

        echo ""
        echo ""
    done

done 

