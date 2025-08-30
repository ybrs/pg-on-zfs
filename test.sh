#!/bin/bash
# Strict mode
set -euo pipefail

container="${1:-pgtest}"
timeout_seconds=30
start=$(date +%s)

# Print container logs on any error for easier debugging
trap 'echo "\n--- docker logs for $container ---"; docker logs "$container" || true' ERR

# wait for postgres with timeout
until docker exec "$container" pg_isready -U postgres >/dev/null 2>&1; do
  if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
    echo "Container $container is not running"
    docker logs "$container" || true
    exit 1
  fi
  elapsed=$(( \
    $(date +%s) - start \
  ))
  if [ "$elapsed" -ge "$timeout_seconds" ]; then
    echo "Timed out waiting for postgres after ${timeout_seconds}s"
    docker logs "$container" || true
    exit 1
  fi
  sleep 1
done
echo "Postgres is ready"
# check connection to maindb
docker exec "$container" psql -U postgres -d maindb -c 'SELECT 1;'
# clone database
docker exec "$container" psql -U postgres -c "CREATE DATABASE clonedb TEMPLATE maindb;"
# connect to cloned database
docker exec "$container" psql -U postgres -d clonedb -c 'SELECT 1;'
# drop cloned database
docker exec "$container" psql -U postgres -c "DROP DATABASE clonedb;"
