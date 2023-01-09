#!/bin/sh
set -e
JVM_OPTS="-Xms4096M -Xmx1GB"
sleep 20
until PGPASSWORD=$POSTGRES_PASSWORD psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d "ins_validation_svc" -c '\q'; do
  >&2 echo "Flyway Info: Postgres is unavailable - sleeping"
  sleep 20
done

>&2 echo "Flyway Info: Postgres is up - Beginning Migration"
flyway migrate
>&2 echo "Flyway Info: Migration Complete"
