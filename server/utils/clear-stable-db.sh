clear

if [ -z "$1" ]; then
    echo "Help:"
    echo "  clear-stable-dh.sh 0 2 ... create fresh db, update schema files"
    exit
fi


if [ "$1" = "0" ]; then

    echo "Going to change database to clear version. All data will be lost."
    echo "Press <Enter> to continue or <Ctrl+C> to cancel ..."
    read

    echo "Running utils/all-sql.sh"
    ./utils/all-sql.sh $2
    echo ""

    echo "Removing sysfink.db"
    rm sysfink.db
    
    echo "Executing temp/schema-raw-create-sqlite.sql (perl utils/db-run-sqlscript.pl):"
    perl ./utils/db-run-sqlscript.pl temp/schema-raw-create-sqlite.sql 1

    echo "Executing sql/data-base.pl:"
    perl ./sql/data-base.pl

    echo "Executing sql/data-stable.pl:"
    perl ./sql/data-stable.pl
fi

echo "Done."
