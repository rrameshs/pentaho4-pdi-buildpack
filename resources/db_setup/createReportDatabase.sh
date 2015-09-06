#!/usr/bin/env bash

source ~/.kettle/kettle.properties
export PGPASSWORD=$REPORTING_DB_PW

echo "Creating database ${REPORTING_DB_NAME} on ${REPORTING_DB_HOST} ..."
DB_EXISTS=`psql -h $REPORTING_DB_HOST -p $REPORTING_DB_PORT -U $REPORTING_DB_USER -l | grep $REPORTING_DB_NAME | wc -l`
if [$DB_EXISTS -eq 1]; then
	echo "Database already exists"
else
	psql -h $REPORTING_DB_HOST -p $REPORTING_DB_PORT -U $REPORTING_DB_USER -d postgres -c "create database $REPORTING_DB_NAME;"
fi

echo "Creating dw schema"
DW_EXISTS=`psql -h $REPORTING_DB_HOST -p $REPORTING_DB_PORT -U $REPORTING_DB_USER -d $REPORTING_DB_NAME -c "select 'DW_EXISTS' from pg_namespace where nspname = 'dw';" | grep 'DW_EXISTS' | wc -l`
if [$DW_EXISTS -eq 1]; then
	echo "Schema already exists"
else
	psql -h $REPORTING_DB_HOST -p $REPORTING_DB_PORT -U $REPORTING_DB_USER -d $REPORTING_DB_NAME -c "create schema if not exists dw;"
fi

echo "Creating mart schema"
MART_EXISTS=`psql -h $REPORTING_DB_HOST -p $REPORTING_DB_PORT -U $REPORTING_DB_USER -d $REPORTING_DB_NAME -c "select 'MART_EXISTS' from pg_namespace where nspname = 'mart';" | grep 'MART_EXISTS' | wc -l`
if [$MART_EXISTS -eq 1]; then
	echo "Schema already exists"
else
	psql -h $REPORTING_DB_HOST -p $REPORTING_DB_PORT -U $REPORTING_DB_USER -d $REPORTING_DB_NAME -c "create schema if not exists mart;"
fi

echo "Executing DDL"
~/.pdi-buildpack/liquibase/liquibase --username=$REPORTING_DB_USER --password=$REPORTING_DB_PW --url=jdbc:postgresql://$REPORTING_DB_HOST:$REPORTING_DB_PORT/$REPORTING_DB_NAME --changeLogFile=$HOME/.pdi-buildpack/db_setup/reportdb_template/changelog-master.xml --classpath=$HOME/.pdi-buildpack/pdi/data-integration/libext/JDBC/postgresql-8.4-702.jdbc3.jar update

echo "Done"