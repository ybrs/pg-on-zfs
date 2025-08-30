#!/bin/sh
set -e

container="$1"
if [ -z "$container" ]; then
  echo "usage: $0 <container>" >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required" >&2
  exit 1
fi

until docker exec "$container" pg_isready -U postgres >/dev/null 2>&1; do
  sleep 1
done

docker exec "$container" su - postgres -c "psql -d maindb -c 'SELECT 1'"

docker exec "$container" su - postgres -c "createdb -T maindb clonedb"

docker exec "$container" su - postgres -c "psql -d clonedb -c 'SELECT 1'"

docker exec "$container" su - postgres -c "dropdb clonedb"
