#!/bin/bash

echo -n "updating some temp/*.sql - "
perl utils/wiki_schema.pl sql/schema.wiki > temp/schema.sql

echo -n "creating temp/schema-raw-create.sql - "
perl utils/wiki_schema.pl sql/schema.wiki 0 1 0 > temp/schema-raw-create.sql && echo done

echo -n "creating temp/schema-raw-create-comments.sql - "
perl utils/wiki_schema.pl sql/schema.wiki 0 1 1 > temp/schema-raw-create-comments.sql && echo done

echo "Transforming MySQL to SQLite (temp/schema-raw-create.sql > temp/schema-raw-create-sqlite.sql) :"
sqlt --parser MySQL --producer SQLite temp/schema-raw-create.sql > temp/schema-raw-create-sqlite.sql


cat temp/schema.sql > temp/all.sql
cat sql/data-base.sql >> temp/all.sql
echo "" >  temp/all-sqlite.sql
perl utils/filter-sqlite.pl temp/schema-raw-create-sqlite.sql >> temp/all-sqlite.sql
perl utils/filter-sqlite.pl sql/data-base.sql >> temp/all-sqlite.sql


cat temp/all.sql > temp/all-dev.sql
cat sql/data-dev.sql >> temp/all-dev.sql
echo "" > temp/all-dev-sqlite.sql
perl utils/filter-sqlite.pl temp/schema-raw-create-sqlite.sql >> temp/all-dev-sqlite.sql
perl utils/filter-sqlite.pl sql/data-dev.sql >> temp/all-dev-sqlite.sql


cat temp/all.sql > temp/all-stable.sql
cat sql/data-stable.sql >> temp/all-stable.sql
echo "" > temp/all-stable-sqlite.sql
perl utils/filter-sqlite.pl temp/schema-raw-create-sqlite.sql >> temp/all-stable-sqlite.sql
perl utils/filter-sqlite.pl sql/data-stable.sql >> temp/all-stable-sqlite.sql
echo done


if [ "$1" = "1" -o "$1" = "2" ]; then
    echo -n "updating SysFink::DB::Schema.pm - "
    perl utils/sqlt-sysfink.pl dbix temp/schema-raw-create.sql 0 && echo done
fi


if [ "$1" = "2" ]; then
    echo -n "updating temp/schema.png - "
    perl utils/sqlt-sysfink.pl dbdoc temp/schema-raw-create-comments.sql 0 && echo done
fi
