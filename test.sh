#!/bin/bash
set -euo pipefail
container="${1:-pgtest}"
# wait for postgres
until docker exec "$container" pg_isready -U postgres >/dev/null 2>&1; do
  sleep 1
done
# check connection to maindb
docker exec "$container" psql -U postgres -d maindb -c 'SELECT 1;'
# clone database
docker exec "$container" psql -U postgres -c "CREATE DATABASE clonedb TEMPLATE maindb;"
# connect to cloned database
docker exec "$container" psql -U postgres -d clonedb -c 'SELECT 1;'
# drop cloned database
docker exec "$container" psql -U postgres -c "DROP DATABASE clonedb;"
