#!/usr/bin/env bash

source ~/.kettle/kettle.properties
export PGPASSWORD=$REPORTING_DB_PW

echo "Creating database ${REPORTING_DB_NAME} on ${REPORTING_DB_HOST} ..."
psql -h $REPORTING_DB_HOST -p $REPORTING_DB_PORT -U $REPORTING_DB_USER -d postgres -c "create database $REPORTING_DB_NAME;"

echo "Creating schemas ..."
psql -h $REPORTING_DB_HOST -p $REPORTING_DB_PORT -U $REPORTING_DB_USER -d $REPORTING_DB_NAME -c "create schema dw;"
psql -h $REPORTING_DB_HOST -p $REPORTING_DB_PORT -U $REPORTING_DB_USER -d $REPORTING_DB_NAME -c "create schema mart;"

echo "Executing DDL ..."
~/.pdi-buildpack/liquibase/liquibase --username=$REPORTING_DB_USER --password=$REPORTING_DB_PW --url=jdbc:postgresql://$REPORTING_DB_HOST:$REPORTING_DB_PORT/$REPORTING_DB_NAME update

echo "Done"