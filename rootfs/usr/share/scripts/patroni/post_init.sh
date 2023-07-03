#!/usr/bin/env bash
set -Eeu

if [[ ( -n "$DRYCC_TIMESERIES_USER") &&  ( -n "$DRYCC_TIMESERIES_PASSWORD")]]; then
  echo "Creating user ${DRYCC_TIMESERIES_USER}"
  psql "$1" -w -c "create user ${DRYCC_TIMESERIES_USER} WITH LOGIN ENCRYPTED PASSWORD '${DRYCC_TIMESERIES_PASSWORD}'"
  for dbname in ${DRYCC_TIMESERIES_INIT_NAMES//,/ }
  do
    echo "Creating database ${dbname}"
    psql "$1" -w -c "CREATE DATABASE ${dbname} OWNER ${DRYCC_TIMESERIES_USER}"
    psql "$1" -w << EOF
\c ${dbname};
CREATE EXTENSION timescaledb;
GRANT USAGE ON FOREIGN DATA WRAPPER timescaledb_fdw TO ${DRYCC_TIMESERIES_USER};
EOF
  done
else
  echo "Skipping user creation"
  echo "Skipping database creation"
fi
