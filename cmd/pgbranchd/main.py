#!/usr/bin/env python3
import os
import socket
import subprocess
import shlex
sock='/run/pgbranchd.sock'
if os.path.exists(sock):
    os.remove(sock)
s=socket.socket(socket.AF_UNIX,socket.SOCK_STREAM)
s.bind(sock)
os.chmod(sock,0o666)
s.listen()
while True:
    c,_=s.accept()
    d=c.recv(1024).decode().strip()
    p=shlex.split(d)
    if p and p[0].upper()=='SNAPSHOT' and len(p)==3:
        src=p[1]
        dst=p[2]
        subprocess.run(['zfs','snapshot',f'pgpool/db_{src}@snap'],check=True)
        subprocess.run(['zfs','clone',f'pgpool/db_{src}@snap',f'pgpool/db_{dst}'],check=True)
        subprocess.run(['psql','-c',f"CREATE TABLESPACE db_{dst} LOCATION '/pgpool/db_{dst}';"],check=True)
        subprocess.run(['psql','-c',f"CREATE DATABASE {dst} TABLESPACE db_{dst} TEMPLATE {src};"],check=True)
    if p and p[0].upper()=='DROP' and len(p)==2:
        dst=p[1]
        subprocess.run(['dropdb',dst],check=True)
        subprocess.run(['zfs','destroy','-r',f'pgpool/db_{dst}'],check=True)
    c.close()
