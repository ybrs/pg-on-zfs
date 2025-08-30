#!/bin/bash
set -euo pipefail
container="${1:-pgtest}"
# wait for postgres (timeout after 30s)
timeout=30
while ! docker exec "$container" pg_isready -U postgres >/dev/null 2>&1; do
  # if container has stopped exit early with logs
  if ! docker ps --format '{{.Names}}' | grep -q "^$container$"; then
    echo "Container $container is not running" >&2
    docker logs "$container" || true
    exit 1
  fi
  sleep 1
  timeout=$((timeout - 1))
  if [ "$timeout" -le 0 ]; then
    echo "PostgreSQL did not become ready within 30 seconds" >&2
    docker logs "$container" || true
    exit 1
  fi
done
# check connection to maindb
docker exec "$container" psql -U postgres -d maindb -c 'SELECT 1;'
# clone database
docker exec "$container" psql -U postgres -c "CREATE DATABASE clonedb TEMPLATE maindb;"
# connect to cloned database
docker exec "$container" psql -U postgres -d clonedb -c 'SELECT 1;'
# drop cloned database
docker exec "$container" psql -U postgres -c "DROP DATABASE clonedb;"
