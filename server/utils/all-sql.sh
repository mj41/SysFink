#!/bin/bash

echo -n "updating some temp/*.sql - "
perl utils/wiki_schema.pl sql/schema.wiki > temp/schema.sql

echo -n "creating temp/schema-raw-create.sql - "
perl utils/wiki_schema.pl sql/schema.wiki 0 1 0 > temp/schema-raw-create.sql && echo done

echo -n "creating temp/schema-raw-create-comments.sql - "
perl utils/wiki_schema.pl sql/schema.wiki 0 1 1 > temp/schema-raw-create-comments.sql && echo done

echo "Transforming MySQL to SQLite (temp/schema-raw-create.sql > temp/schema-raw-create-sqlite.sql) :"
sqlt --parser MySQL --producer SQLite temp/schema-raw-create.sql > temp/schema-raw-create-sqlite.sql


if [ "$1" = "1" -o "$1" = "2" ]; then
    echo -n "updating SysFink::DB::Schema.pm - "
    perl utils/sqlt-sysfink.pl dbix temp/schema-raw-create.sql 0 && echo done
fi


if [ "$1" = "2" ]; then
    echo -n "updating temp/schema.png - "
    perl utils/sqlt-sysfink.pl dbdoc temp/schema-raw-create-comments.sql 0 && echo done
fi
