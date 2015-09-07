#!/usr/bin/env bash

create_db() {
	
	local kettle_props=$1
	source $kettle_props

	#create the report db specified in kettle.properties
	export PGPASSWORD=$REPORTING_DB_PW
	echo "Creating database ${REPORTING_DB_NAME} on ${REPORTING_DB_HOST} ..."
	report_db_exists=`psql -h $REPORTING_DB_HOST -p $REPORTING_DB_PORT -U $REPORTING_DB_USER -l | grep $REPORTING_DB_NAME | wc -l`
	if [[ $report_db_exists -eq 1 ]]; then
		echo "Database already exists"
	else
		psql -h $REPORTING_DB_HOST -p $REPORTING_DB_PORT -U $REPORTING_DB_USER -d postgres -c "create database $REPORTING_DB_NAME;"
	fi
	
	echo "Creating dw schema"
	dw_exists=`psql -h $REPORTING_DB_HOST -p $REPORTING_DB_PORT -U $REPORTING_DB_USER -d $REPORTING_DB_NAME -c "select 'DW_EXISTS' from pg_namespace where nspname = 'dw';" | grep 'DW_EXISTS' | wc -l`
	if [[ $dw_exists -eq 1 ]]; then
		echo "Schema already exists"
	else
		psql -h $REPORTING_DB_HOST -p $REPORTING_DB_PORT -U $REPORTING_DB_USER -d $REPORTING_DB_NAME -c "create schema if not exists dw;"
	fi
	
	echo "Creating mart schema"
	mart_exists=`psql -h $REPORTING_DB_HOST -p $REPORTING_DB_PORT -U $REPORTING_DB_USER -d $REPORTING_DB_NAME -c "select 'MART_EXISTS' from pg_namespace where nspname = 'mart';" | grep 'MART_EXISTS' | wc -l`
	if [[ $mart_exists -eq 1 ]]; then
		echo "Schema already exists"
	else
		psql -h $REPORTING_DB_HOST -p $REPORTING_DB_PORT -U $REPORTING_DB_USER -d $REPORTING_DB_NAME -c "create schema if not exists mart;"
	fi
	
	#create any call log dbs specified in kettle.properties
	counter=1
	key=LOGGING_${counter}_DB_NAME
	while [[ `grep $key $kettle_props | wc -l` -gt 0 ]]; do

		eval dbname=\$LOGGING_${counter}_DB_NAME
		eval dbhost=\$LOGGING_${counter}_DB_HOST
		eval dbport=\$LOGGING_${counter}_DB_PORT
		eval dbuser=\$LOGGING_${counter}_DB_USER
		eval dbpwd=\$LOGGING_${counter}_DB_PW
		
		echo "Creating database ${dbname} on ${dbhost} ..."
		export PGPASSWORD=$dbpwd
		db_exists=`psql -h $dbhost -p $dbport -U $dbuser -l | grep $dbname | wc -l`
		if [[ $db_exists -eq 1 ]]; then
			echo "Database already exists"
		else
			psql -h $dbhost -p $dbport -U $dbuser -d postgres -c "create database ${dbname};"
		fi	

        let counter+=1
        key=LOGGING_${counter}_DB_NAME
	done
	
	echo "Done"
}
