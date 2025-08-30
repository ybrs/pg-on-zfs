# pg-on-zfs

Local, instant Postgres branching on macOS using ZFS inside Docker. This proof of concept lets you spin up writable database branches from production-sized snapshots in milliseconds without doubling disk usage.

## Why

* Developers often work with 10–20 GB production snapshots.
* They need multiple experiment branches without copying data or waiting for `pg_dump`.
* macOS APFS cannot create writable snapshots; ZFS inside a lightweight VM **can**.
* We run stock Postgres 16 in Docker and add a small sidecar that turns
  `SNAPSHOT maindb experiment1` into a ZFS clone plus catalog entry.

## Architecture

```
host (APFS)
└─ ~/pgbranch-data/pgpool.img   ← sparse file, actual blocks on demand
    ⬑ bind-mounted into container
        └─ ZFS pool pgpool
           ├─ pgpool/pgdata         ← cluster global dir
           ├─ pgpool/db_maindb      ← dataset for maindb
           └─ pgpool/db_<branch>    ← ZFS clones born in milliseconds
```

* **Postgres 16** runs normally, each database on its own tablespace (`/pgpool/db_<name>`).
* **pgbranchd** daemon listens on a Unix socket and executes:
  * `SNAPSHOT src dst` – checkpoint, ZFS snapshot, ZFS clone, create tablespace, create DB
  * `DROP dst` – drop database, destroy ZFS clone and origin snapshot

## Runtime flow

1. **Container start**
   - Creates or imports `/hostdata/pgpool.img` (size via `$ZPOOL_SIZE`, default 60 G).
   - Imports ZFS pool, initialises cluster if empty, seeds `maindb`.
2. **Branch creation**
   ```bash
   echo "SNAPSHOT maindb experiment1" | nc -U /run/pgbranchd.sock
   ```
   - Advisory lock on `maindb`
   - `zfs snapshot pgpool/db_maindb@snap_<ts>`
   - `zfs clone pgpool/db_maindb@snap_<ts> pgpool/db_experiment1`
   - `CREATE TABLESPACE db_experiment1 LOCATION '/pgpool/db_experiment1';`
   - Insert row into `pg_database`
3. **Developer connects**
   ```bash
   psql -h localhost -d experiment1
   ```
4. **Drop branch**
   ```bash
   echo "DROP experiment1" | nc -U /run/pgbranchd.sock
   ```
   - Drops DB, destroys clone & snapshot.
5. **Disk trims** (optional)
   ```bash
   zpool trim -d pgpool
   ```

## Project layout

```
/
├─ docker/
│   ├─ Dockerfile
│   ├─ entrypoint.sh
│   └─ docker-compose.yml
├─ cmd/pgbranchd/
│   ├─ main.go
│   └─ go.mod, go.sum
└─ README.md
```

## Quick start

```bash
git clone <this repo>
cd pg-on-zfs/docker
# make a place for the sparse file
mkdir -p ../hostdata
# build and run
docker compose up -d

# branch
echo "SNAPSHOT maindb exp1" | nc -U /run/pgbranchd.sock
psql -h localhost -d exp1

# drop
echo "DROP exp1" | nc -U /run/pgbranchd.sock
```

The container requires a host with ZFS kernel modules. On macOS, Docker Desktop provides a Linux VM that supports loading ZFS modules when run in privileged mode. The setup also works on native Linux hosts.

## Next steps

| Phase      | Deliverable                                                   |
|------------|----------------------------------------------------------------|
| POC week 1 | Build image, confirm instant branch/destroy on 20 GB dataset.  |
| Week 2     | CLI wrapper (`pgz branch`, `pgz drop`), basic tests.           |
| Week 3     | Docs, trim support, pool auto-expand.                          |
| Week 4     | Multi-user auth, advisory-lock hardening, CI pipeline.        |

## License

MIT
