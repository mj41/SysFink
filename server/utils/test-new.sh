#!/bin/bash

function echo_help {
    echo "Usage:"
    echo "  utils/test-new.sh dev|current hostname.example.com verbosity_level linux-bin-64b"
    echo ""
    echo "Example:"
    echo "  utils/test-new.sh dev gorilla 3 linux-perl-md5"
    echo "  utils/test-new.sh current gorilla 3 linux-perl-md5"
}

if [ -z "$4" ]; then
    echo_help
    exit
fi 

clear

TEST_TYPE="$1"
HOST="$2"
VER="$3"
DIST_TYPE="$4"

BACKUP_DB_FILE="sysfink.db-test.backup"

if [ $TEST_TYPE != "dev" -a $TEST_TYPE != "current" ]; then
    echo "Error: Uknown test_type '$TEST_TYPE'."
    echo ""
    echo_help
    exit
fi

echo "Starting '$TEST_TYPE' tests:";
echo ""

if [ $TEST_TYPE = "dev" ]; then

    if [ -f "sysfink.db" ]; then
        echo "Moving 'sysfink.db' to '$BACKUP_DB_FILE'."
        mv sysfink.db $BACKUP_DB_FILE || ( echo "Can't move." && exit )
    fi

    echo "Running utils/all-sql.sh"
    ./utils/all-sql.sh 1
    echo ""

    if [ -f "sysfink.db" ]; then
        echo "Removing sysfink.db"
        rm sysfink.db
    echo ""
    fi
    
    echo "Executing temp/schema-raw-create-sqlite.sql (perl utils/db-run-sqlscript.pl):"
    perl ./utils/db-run-sqlscript.pl temp/schema-raw-create-sqlite.sql 1
    echo ""
    
    echo "Executing sql/data-base.pl:"
    perl ./sql/data-base.pl
    echo ""

    echo "Copying 'sysfink.db' to 'sysfink-empty.db'."
    cp sysfink.db sysfink-empty.db
    echo ""
    
    echo "perl sysfink.pl --cmd=mconf_to_db --mconf_path=\"t/conf-machines-test\""
    perl sysfink.pl --cmd=mconf_to_db --mconf_path="t/conf-machines-test"
    echo ""
fi


echo "Harness tests on server:"
perl t/harness.pl
echo ""

echo "Harness tests on client:"
cd ../client && perl t/harness.pl
cd ../server
echo ""

echo "Online tests on host '$HOST':" \
&& echo "" \
&& perl sysfink.pl --no_db --ssh_user=root --host=$HOST --cmd=test_hostname --ver=$VER \
&& echo "" \
&& perl sysfink.pl --no_db --ssh_user=root --host=$HOST --cmd=check_client_dir --ver=$VER \
&& echo "" \
&& perl sysfink.pl --no_db --ssh_user=root --host=$HOST --cmd=remove_client_dir --ver=$VER \
&& echo "" \
&& perl sysfink.pl --no_db --ssh_user=root --host=$HOST --cmd=renew_client_dir --host_dist_type=$DIST_TYPE --ver=$VER \
&& echo "" \
&& perl sysfink.pl --no_db --ssh_user=root --host=$HOST --cmd=test_noop_rpc --ver=$VER \
&& echo "" \
&& perl sysfink.pl --no_db --ssh_user=root --host=$HOST --cmd=test_three_parts_rpc --ver=$VER \
&& echo "" \
&& echo "Running 'perl ... --cmd=scan_test | tail -n 15':" \
&& perl sysfink.pl --host=$HOST --cmd=scan_test --section=fastscan --ver=$VER | tail -n 15 \
&& echo ""

if [ $TEST_TYPE = "dev" ]; then
    echo "Moving 'sysfink.db' to 'temp/sysfink-dev.db'."
    mv sysfink.db temp/sysfink-dev.db || ( echo "Moving failed." && exit )

    if [ -f "$BACKUP_DB_FILE" ]; then
        echo "Moving '$BACKUP_DB_FILE' back to 'sysfink.db'."
        mv $BACKUP_DB_FILE sysfink.db || ( echo "Moving back failed." && exit )
    fi
fi
