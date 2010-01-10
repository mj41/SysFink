#!/bin/bash

function echo_help {
cat <<USAGE_END
Usage:
  utils/test-new.sh dev|current hostname.example.com verbosity_level host_dist_type

Example:
  utils/test-new.sh dev gorilla 3 linux-perl-md5
  utils/test-new.sh current gorilla 3 linux-perl-md5

Advanced example: 
  clear && echo "Running 'dev' and 'current' tests an tee to 'temp/test-new.out.'" \\
  && echo "Go ..." | tee temp/test-new.out \\
  && utils/test-new.sh dev gorilla 3 linux-perl-md5 | tee -a temp/test-new.out \\
  && utils/test-new.sh current gorilla 3 linux-perl-md5 | tee -a temp/test-new.out \\
  && echo "" && echo "All done. Use 'cat temp/test-new.out | more' to see output again."

USAGE_END
}

if [ -z "$4" ]; then
    echo_help
    exit
fi 


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

echo "-------------------------------------------------------------------------------------"
echo "Starting '$TEST_TYPE' tests:";
echo ""

if [ -f "sysfink.db" ]; then
    echo "Copying 'sysfink.db' to '$BACKUP_DB_FILE'."
    cp sysfink.db $BACKUP_DB_FILE || ( echo "Can't move." && exit )
    echo ""
fi

if [ $TEST_TYPE = "dev" ]; then

    export SYSFINK_DEVEL=1

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
    
    echo "Running perl sysfink.pl --cmd=mconf_to_db --mconf_path=\"t/conf-machines-test\""
    perl sysfink.pl --cmd=mconf_to_db --mconf_path="t/conf-machines-test"
    echo ""

else
    echo "Running perl sysfink.pl --cmd=mconf_to_db"
    perl sysfink.pl --cmd=mconf_to_db
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
    echo ""

    export SYSFINK_DEVEL=0
else 
    echo "Moving 'sysfink.db' to 'temp/sysfink-current.db'."
    mv sysfink.db temp/sysfink-current.db || ( echo "Moving failed." && exit )
    echo ""
fi

if [ -f "$BACKUP_DB_FILE" ]; then
    echo "Moving '$BACKUP_DB_FILE' back to 'sysfink.db'."
    mv $BACKUP_DB_FILE sysfink.db || ( echo "Moving back failed." && exit )
    echo ""
fi
