import argparse, socket, subprocess, time, os

def run(cmd):
    try:
        subprocess.run(cmd)
    except FileNotFoundError:
        pass

def snapshot(src, dst):
    ts = int(time.time())
    snap = f"pgpool/db_{src}@snap_{ts}"
    run(["zfs", "snapshot", snap])
    run(["zfs", "clone", snap, f"pgpool/db_{dst}"])
    run(["psql", "-c", f"CREATE TABLESPACE db_{dst} LOCATION '/pgpool/db_{dst}'"])
    run(["createdb", "-T", src, dst])


def drop(db):
    run(["dropdb", db])
    run(["zfs", "destroy", f"pgpool/db_{db}"])


def serve():
    path = "/run/pgbranchd.sock"
    if os.path.exists(path):
        os.remove(path)
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.bind(path)
    s.listen(1)
    while True:
        c, _ = s.accept()
        data = c.recv(1024).decode().strip().split()
        if data and data[0] == "SNAPSHOT":
            snapshot(data[1], data[2])
        if data and data[0] == "DROP":
            drop(data[1])
        c.close()


p = argparse.ArgumentParser()
sub = p.add_subparsers(dest="cmd")
sub.add_parser("serve")
s = sub.add_parser("snapshot")
s.add_argument("src")
s.add_argument("dst")
d = sub.add_parser("drop")
d.add_argument("db")
a = p.parse_args()
if a.cmd == "serve":
    serve()
elif a.cmd == "snapshot":
    snapshot(a.src, a.dst)
elif a.cmd == "drop":
    drop(a.db)
