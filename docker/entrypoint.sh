#!/bin/sh
set -e

# Ensure a ZFS implementation is available.  This script prefers the kernel
# module but falls back to the userspace fuse daemon if necessary.  The
# container must exit immediately if neither is usable.
if ! command -v zpool >/dev/null 2>&1; then
  echo "zpool command not found" >&2
  exit 1
fi

# Start zfs-fuse if the kernel module is missing.
if ! zpool list >/dev/null 2>&1; then
  if command -v zfs-fuse >/dev/null 2>&1; then
    zfs-fuse >/dev/null 2>&1 &
    # give the daemon a moment to start
    sleep 1
  fi
  if ! zpool list >/dev/null 2>&1; then
    echo "ZFS is not available" >&2
    exit 1
  fi
fi

if [ ! -e /hostdata/pgpool.img ]; then
  truncate -s "${ZPOOL_SIZE:-60G}" /hostdata/pgpool.img
  if ! zpool create -f -o ashift=12 pgpool /hostdata/pgpool.img; then
    echo "failed to create zpool" >&2
    exit 1
  fi
  if ! zfs create -o mountpoint=/pgpool/pgdata pgpool/pgdata; then
    echo "failed to create ZFS dataset" >&2
    exit 1
  fi
  chown -R postgres:postgres /pgpool
else
  if ! zpool import -d /hostdata pgpool; then
    echo "failed to import zpool" >&2
    exit 1
  fi
fi

if [ ! -s /pgpool/pgdata/PG_VERSION ]; then
  su - postgres -c "initdb -D /pgpool/pgdata"
  su - postgres -c "pg_ctl -D /pgpool/pgdata -w start"
  su - postgres -c "createdb -D pg_default maindb"
  su - postgres -c "pg_ctl -D /pgpool/pgdata stop"
fi

su - postgres -c "python3 /pgbranchd/main.py &"
exec su - postgres -c "postgres -D /pgpool/pgdata"
