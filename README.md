# pg-on-zfs — local, instant Postgres branching on macOS

`pg-on-zfs` is a proof‑of‑concept that lets developers instantly branch large
PostgreSQL databases without consuming additional disk space.  It combines a
standard PostgreSQL server with a small sidecar daemon that uses ZFS writable
clones to create new databases in milliseconds.

Although the primary target is macOS (where APFS lacks writable snapshots),
the Docker image also runs on Linux and our CI checks build on both
platforms.

## Why

* Production snapshots are typically tens of gigabytes.
* Developers need multiple branches of this data without waiting for
  `pg_dump` or doubling disk usage.
* ZFS inside a lightweight Docker VM provides fast, writable snapshots
  while keeping Postgres stock.

## Architecture

```
host (APFS or ext4)
└─ ~/pgbranch-data/pgpool.img   ← sparse file, blocks allocated on demand
     ⬑ bind-mounted into container
        └─ ZFS pool pgpool
           ├─ pgpool/pgdata         ← cluster global dir
           ├─ pgpool/db_maindb      ← dataset for maindb
           └─ pgpool/db_<branch>    ← ZFS clones born in milliseconds
```

* PostgreSQL 16 runs normally; each database lives in its own tablespace
  (`/pgpool/db_<name>`).
* `pgbranchd` listens on a Unix socket and reacts to simple commands:

```
SNAPSHOT src dst   → checkpoint; zfs snapshot; zfs clone; CREATE TABLESPACE; CREATE DATABASE
DROP dst           → DROP DATABASE; zfs destroy clone & origin snapshot
```

## Quick start

> **Prerequisites:** Docker Desktop on macOS (with virtualization), or Docker on
> a Linux host capable of loading the ZFS kernel module.

```bash
git clone <repo-url>/pg-on-zfs
cd pg-on-zfs/docker
docker compose up -d

# create a branch
echo "SNAPSHOT maindb exp1" | nc -U /run/pgbranchd.sock
psql -h localhost -d exp1

# destroy the branch
echo "DROP exp1" | nc -U /run/pgbranchd.sock
```

The first run creates a sparse `pgpool.img` (60 GiB default) under
`~/pgbranch-data`.  Subsequent runs import the existing pool so your branches
survive container restarts.

## Repository layout

```
/
├─ docker/                 Docker image and compose file
├─ cmd/pgbranchd/          Go sidecar daemon
└─ README.md               This document
```

## Roadmap

| Phase      | Deliverable                                                   |
| ---------- | ------------------------------------------------------------- |
| POC week 1 | Build image, confirm instant branch/destroy on 20 GB dataset. |
| Week 2     | CLI wrapper (`pgz branch`, `pgz drop`), basic tests.          |
| Week 3     | Docs, trim support, pool auto‑expand.                         |
| Week 4     | Multi-user auth, advisory-lock hardening, CI pipeline.        |

## License

This project is licensed under the terms of the MIT license.  See
[LICENSE](LICENSE) for details.
