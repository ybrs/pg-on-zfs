#!/bin/sh
set -e

# ensure ZFS tools and kernel modules are available
if ! command -v zpool >/dev/null 2>&1 || ! command -v zfs >/dev/null 2>&1; then
  echo "ZFS utilities are not installed" >&2
  exit 1
fi

if ! zpool list >/dev/null 2>&1; then
  echo "ZFS kernel modules are not loaded" >&2
  exit 1
fi

# create or import the pgpool pool
if ! zpool list -H -o name | grep -q '^pgpool$'; then
  if [ -e /hostdata/pgpool.img ]; then
    zpool import -d /hostdata pgpool || \
      zpool create -f -o ashift=12 pgpool /hostdata/pgpool.img
  else
    truncate -s ${ZPOOL_SIZE:-60G} /hostdata/pgpool.img
    zpool create -f -o ashift=12 pgpool /hostdata/pgpool.img
  fi
fi

# create dataset for PostgreSQL data if needed
if ! zfs list pgpool/pgdata >/dev/null 2>&1; then
  zfs create -o mountpoint=/pgpool/pgdata pgpool/pgdata
fi

chown -R postgres:postgres /pgpool

if [ ! -s /pgpool/pgdata/PG_VERSION ]; then
  su - postgres -c "initdb -D /pgpool/pgdata"
  su - postgres -c "pg_ctl -D /pgpool/pgdata -w start"
  su - postgres -c "createdb -D pg_default maindb"
  su - postgres -c "pg_ctl -D /pgpool/pgdata stop"
fi

su - postgres -c "python3 /pgbranchd/main.py &"
exec su - postgres -c "postgres -D /pgpool/pgdata"
