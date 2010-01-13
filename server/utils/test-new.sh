#!/bin/bash

function echo_help {
cat <<USAGE_END
Usage:
  utils/test-new.sh dev mysql|sqlite hostname verbosity_level host_dist_type
  utils/test-new.sh current auto hostname verbosity_level host_dist_type
  utils/test-new.sh current_clear auto hostname verbosity_level host_dist_type

Example:
  utils/test-new.sh dev sqlite tapir1 3 linux-perl-md5
  utils/test-new.sh dev mysql tapir1 3 linux-perl-md5
  utils/test-new.sh current auto tapir1 3 linux-perl-md5
  utils/test-new.sh current_clear auto tapir1 3 linux-perl-md5

Advanced example: 
  clear && echo "Running 'dev' and 'current' tests and tee to 'temp/test-new.out.'" \\
  && echo "Go ..." | tee temp/test-new.out \\
  && utils/test-new.sh dev sqlite tapir1 3 linux-perl-md5 | tee -a temp/test-new.out \\
  && utils/test-new.sh dev mysql tapir1 3 linux-perl-md5 | tee -a temp/test-new.out \\
  && utils/test-new.sh current auto tapir1 3 linux-perl-md5 | tee -a temp/test-new.out \\
  && echo -n "Grep 'fail' summary: " && cat temp/test-new.out | grep -i "fail" | wc -l \\
  && echo "" && echo "All done. Use 'cat temp/test-new.out | more' to see output again."

USAGE_END
}

# Check number of params.
if [ -z "$5" ]; then
    echo_help
    exit
fi 

TEST_TYPE="$1"
DB_TYPE="$2"
HOST="$3"
VER="$4"
DIST_TYPE="$5"

CLEAR=0

if [ $TEST_TYPE != "dev" -a $TEST_TYPE != "current" -a $TEST_TYPE != "current_clear" ]; then
    echo "Error: Unknown test_type '$TEST_TYPE'."
    echo ""
    echo_help
    exit
fi

if [ $TEST_TYPE = "dev" ]; then
    if [ $DB_TYPE != "sqlite" -a $DB_TYPE != "mysql" ]; then
        echo "Error: Unknown db_type '$DB_TYPE'."
        echo ""
        echo_help
        exit
    fi
else 
    if [ $TEST_TYPE = "current_clear" ]; then
        TEST_TYPE="current"
        CLEAR=2
    fi

    if [ $DB_TYPE != "auto" ]; then
        echo "Error: For test type 'current' only 'auto' db_type allowed."
        echo ""
        echo_help
        exit
    fi
fi


TEST_CONF_FILE="t/conf-test/web_db.yml-$DB_TYPE"

echo "-------------------------------------------------------------------------------------"

if [ $TEST_TYPE = "current" ]; then
    GREP=`cat conf/web_db.yml | grep SQLite`
    if [ -z "$GREP" ]; then
        DB_TYPE="mysql"
    else
        DB_TYPE="sqlite"
    fi
    echo "Found db_type '$DB_TYPE'."
fi    

echo "Starting '$TEST_TYPE' '$DB_TYPE' tests:";
echo ""


# test type: dev
if [ $TEST_TYPE = "dev" ]; then
    if [ ! -f $TEST_CONF_FILE ]; then
        echo "Can't find test config file '$TEST_CONF_FILE'."
        exit
    fi

    IN_FILE="conf/web_db.yml"
    OUT_FILE="conf/web_db.yml-test.backup"
    if [ -f "$IN_FILE" ]; then
        echo "Moving '$IN_FILE' to '$OUT_FILE'."
        mv "$IN_FILE" "$OUT_FILE" || ( echo "Can't move." && exit )
        echo ""
    fi

    IN_FILE="$TEST_CONF_FILE"
    OUT_FILE="conf/web_db.yml"
    if [ -f "$IN_FILE" ]; then
        echo "Copying '$IN_FILE' to '$OUT_FILE'."
        cp "$IN_FILE" "$OUT_FILE" || ( echo "Can't move." && exit )
        echo ""
    fi

    export SYSFINK_DEVEL=1

    echo "Running utils/all-sql.sh 1"
    ./utils/all-sql.sh 1
    echo ""

    if [ "$DB_TYPE" = "sqlite" ]; then
        if [ -f "sysfink-dev.db" ]; then
            echo "Removing sysfink-dev.db"
            rm "sysfink-dev.db"
            echo ""
        fi
    fi
    
    if [ "$DB_TYPE" = "sqlite" ]; then
        echo "Executing temp/schema-raw-create-sqlite.sql (perl utils/db-run-sqlscript.pl):"
        perl ./utils/db-run-sqlscript.pl temp/schema-raw-create-sqlite.sql 1
    else 
        echo "Executing temp/schema.sql (perl utils/db-run-sqlscript.pl):"
        perl ./utils/db-run-sqlscript.pl temp/schema.sql 1
    fi
    echo ""
    
    echo "Executing sql/data-base.pl:"
    perl ./sql/data-base.pl
    echo ""

    if [ "$DB_TYPE" = "sqlite" ]; then
        IN_FILE="sysfink-dev.db"
        OUT_FILE="sysfink-empty.db"
        if [ -f "$IN_FILE" ]; then
            echo "Copying '$IN_FILE' to '$OUT_FILE'."
            cp "$IN_FILE" "$OUT_FILE" || ( echo "Can't move." && exit )
            echo ""
        else 
            echo "Input file '$IN_FILE' not found."
            exit
        fi
    fi

    echo "Executing sql/data-dev.pl:"
    perl ./sql/data-dev.pl
    echo ""

    echo "Running perl sysfink.pl --cmd=mconf_to_db --mconf_path=\"t/conf-machines-test\""
    perl sysfink.pl --cmd=mconf_to_db --mconf_path="t/conf-machines-test"
    echo ""

# test type: current
else
    if [ "$DB_TYPE" = "sqlite" ]; then
        if [ ! -f "sysfink.db" ]; then
            echo "Current, but sysfink.db not found -> recreating:";
            CLEAR=1
        fi

        # backup old sqlite db file
        if [ "$CLEAR" = "0" ]; then
            IN_FILE="sysfink.db"
            OUT_FILE="temp/$IN_FILE-test.backup"
            if [ -f "$IN_FILE" ]; then
                echo "Copying '$IN_FILE' to '$OUT_FILE'."
                cp "$IN_FILE" "$OUT_FILE" || ( echo "Can't copy." && exit )
                echo ""
            fi
        fi
    fi

    if [ "$CLEAR" != "0" ]; then
        echo "Running utils/all-sql.sh $CLEAR"
        ./utils/all-sql.sh $CLEAR
        echo ""

        if [ "$DB_TYPE" = "sqlite" ]; then
            echo "Executing temp/schema-raw-create-sqlite.sql (perl utils/db-run-sqlscript.pl):"
            perl ./utils/db-run-sqlscript.pl temp/schema-raw-create-sqlite.sql 1
        else 
            echo "Executing temp/schema.sql (perl utils/db-run-sqlscript.pl):"
            perl ./utils/db-run-sqlscript.pl temp/schema.sql 1
        fi

        echo "Executing sql/data-base.pl:"
        perl ./sql/data-base.pl
        echo ""

        echo "Executing sql/data-dev.pl:"
        perl ./sql/data-stable.pl
        echo ""
    fi

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
&& perl sysfink.pl --ssh_user=root --host=$HOST --cmd=renew_client_dir --ver=$VER \
&& echo "" \
&& perl sysfink.pl --ssh_user=root --host=$HOST --cmd=test_three_parts_rpc --ver=$VER \
&& echo "" \
&& echo "Running 'perl ... --cmd=scan_test | tail -n 15':" \
&& perl sysfink.pl --host=$HOST --cmd=scan_test --section=fastscan --ver=$VER | tail -n 15 \
&& echo ""

# test type: dev
if [ $TEST_TYPE = "dev" ]; then
    echo "Running 'perl ... --cmd=scan --section=testscan'."
    perl sysfink.pl --host=$HOST --cmd=scan --section=testscan --ver=$VER
    echo "Done."

    export SYSFINK_DEVEL=0

    IN_FILE="sysfink-dev.db"
    OUT_FILE="temp/$IN_FILE"
    if [ -f "$IN_FILE" ]; then
        echo "Moving '$IN_FILE' to '$OUT_FILE'."
        mv "$IN_FILE" "$OUT_FILE" || ( echo "Can't move." && exit )
        echo ""
    fi

    IN_FILE="conf/web_db.yml-test.backup"
    OUT_FILE="conf/web_db.yml"
    if [ -f "$IN_FILE" ]; then
        echo "Moving '$IN_FILE' to '$OUT_FILE'."
        mv "$IN_FILE" "$OUT_FILE" || ( echo "Can't move." && exit )
        echo ""
    fi
fi
