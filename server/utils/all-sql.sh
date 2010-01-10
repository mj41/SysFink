#!/bin/bash

echo -n "Updating some temp/*.sql - "
perl utils/wiki_schema.pl sql/schema.wiki > temp/schema.sql || ( echo "failed." && exit )
echo "done."

echo -n "Creating temp/schema-raw-create.sql - "
perl utils/wiki_schema.pl sql/schema.wiki 0 1 0 > temp/schema-raw-create.sql || ( echo "failed." && exit )
echo "done."

echo -n "Creating temp/schema-raw-create-comments.sql - "
perl utils/wiki_schema.pl sql/schema.wiki 0 1 1 > temp/schema-raw-create-comments.sql || ( echo "failed." && exit )
echo "done."

echo "Transforming MySQL to SQLite (temp/schema-raw-create.sql > temp/schema-raw-create-sqlite.sql)."
sqlt --parser MySQL --producer SQLite temp/schema-raw-create.sql > temp/schema-raw-create-sqlite.sql
echo "Done."


if [ "$1" = "1" -o "$1" = "2" ]; then
    echo -n "Updating SysFink::DB::Schema.pm - "
    perl utils/sqlt-sysfink.pl dbix temp/schema-raw-create.sql 0 || ( echo "failed." && exit )
    echo "done."
fi


if [ "$1" = "2" ]; then
    echo -n "Removing old dbdoc - "
    rm -rf temp/dbdoc || ( echo "failed." && exit )
    echo "done."
    
    echo "Updating temp/dbdoc (schema images)."
    perl utils/sqlt-sysfink.pl dbdoc temp/schema-raw-create-comments.sql 3 || ( echo "Failed." && exit )
    echo "Done."
fi

echo "Done."