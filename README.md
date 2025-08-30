# pg-on-zfs

Local PostgreSQL branching on macOS using ZFS inside Docker. This proof of concept keeps a stock Postgres cluster and uses ZFS clones for instant writable snapshots. The included Python `pgbranchd` listens on a Unix socket and handles simple `SNAPSHOT` and `DROP` commands.

## Current state

- Minimal Docker setup with ZFS and PostgreSQL 16
- Prototype `pgbranchd` daemon implemented in Python
- Basic Makefile and docker-compose for local runs
- GitHub workflow builds the container image to verify the Dockerfile

## Usage

```bash
make lint
cd docker
# run the container
# docker compose up -d
```
Commands can be sent with `nc -U /run/pgbranchd.sock` inside the container.
