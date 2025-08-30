# pg-on-zfs

Local Postgres branching on macOS using ZFS in a lightweight Docker VM. The container hosts a ZFS pool where each database lives on its own dataset so clones appear instantly and consume space on write.

## Current status

This repository is a proof of concept. It contains:

- Docker image that installs PostgreSQL, ZFS tools and a tiny Python daemon.
- Minimal `pgbranchd` CLI that can snapshot or drop databases and runs as a Unix socket service inside the container.
- Simple `Makefile` helpers and an example `docker-compose.yml`.

The implementation is intentionally small; the daemon does not handle errors or authentication.

## Quick start

```bash
docker compose -f docker/docker-compose.yml up -d
# create clone
make snapshot SRC=maindb DST=exp1
# drop clone
make drop DB=exp1
```

## Why ZFS

APFS on macOS cannot create writable snapshots. Running ZFS inside Docker gives developers fast database branches without duplicating gigabytes.
