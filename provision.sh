#!/bin/bash

set -e

service postgresql start
# Provisioning bash script
root_dir=/data/openstreetmap-website
cd $root_dir
db_user_exists=$(psql postgres -tAc "select 1 from pg_roles where rolname='ubuntu'")
if [ "$db_user_exists" != "1" ]; then
		su -l postgres -c "createuser -s ubuntu"
		createdb -E UTF-8 -O ubuntu openstreetmap
		createdb -E UTF-8 -O ubuntu osm_test
		# add btree_gist extension
		psql -c "create extension btree_gist" openstreetmap
		psql -c "create extension btree_gist" osm_test
fi

cd ${root_dir}/db/functions
make
psql openstreetmap -c "CREATE OR REPLACE FUNCTION maptile_for_point(int8, int8, int4) RETURNS int4 AS '/data/openstreetmap-website/db/functions/libpgosm.so', 'maptile_for_point' LANGUAGE C STRICT"
psql openstreetmap -c "CREATE OR REPLACE FUNCTION tile_for_point(int4, int4) RETURNS int8 AS '/data/openstreetmap-website/db/functions/libpgosm.so', 'tile_for_point' LANGUAGE C STRICT"
psql openstreetmap -c "CREATE OR REPLACE FUNCTION xid_to_int4(xid) RETURNS int4 AS '/data/openstreetmap-website/db/functions/libpgosm.so', 'xid_to_int4' LANGUAGE C STRICT"
cd $root_dir
bundle install
# set up sample configs
if [ ! -f config/database.yml ]; then
		cp config/example.database.yml config/database.yml
fi
if [ ! -f config/application.yml ]; then
		cp config/example.application.yml config/application.yml
fi

# migrate the database to the latest version
rake db:migrate

exec "$@"
