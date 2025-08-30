#!/bin/sh
set -e

# location of PostgreSQL binaries
PG_BINDIR=$(pg_config --bindir)

if [ ! -e /hostdata/pgpool.img ]; then
  truncate -s ${ZPOOL_SIZE:-60G} /hostdata/pgpool.img
  zpool create -f -o ashift=12 pgpool /hostdata/pgpool.img
  zfs create -o mountpoint=/pgpool/pgdata pgpool/pgdata
  chown -R postgres:postgres /pgpool
else
  zpool import -d /hostdata pgpool
fi

if [ ! -s /pgpool/pgdata/PG_VERSION ]; then
  su postgres -c "$PG_BINDIR/initdb -D /pgpool/pgdata"
  su postgres -c "$PG_BINDIR/pg_ctl -D /pgpool/pgdata -w start"
  su postgres -c "$PG_BINDIR/createdb -D pg_default maindb"
  su postgres -c "$PG_BINDIR/pg_ctl -D /pgpool/pgdata stop"
fi

su postgres -c "python3 /pgbranchd/main.py &"
exec su postgres -c "$PG_BINDIR/postgres -D /pgpool/pgdata"
