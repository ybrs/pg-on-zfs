#!/bin/sh
set -e
if [ ! -e /hostdata/pgpool.img ]; then
  truncate -s ${ZPOOL_SIZE:-60G} /hostdata/pgpool.img
  zpool create -f -o ashift=12 pgpool /hostdata/pgpool.img
  zfs create -o mountpoint=/pgpool/pgdata pgpool/pgdata
  chown -R postgres:postgres /pgpool
else
  zpool import -d /hostdata pgpool
fi
if [ ! -s /pgpool/pgdata/PG_VERSION ]; then
  su - postgres -c "initdb -D /pgpool/pgdata"
  su - postgres -c "pg_ctl -D /pgpool/pgdata -w start"
  su - postgres -c "createdb -D pg_default maindb"
  su - postgres -c "pg_ctl -D /pgpool/pgdata stop"
fi
su - postgres -c "python3 /pgbranchd/main.py serve &"
exec su - postgres -c "postgres -D /pgpool/pgdata"
