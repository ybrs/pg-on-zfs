package main
import (
 "bufio"
 "net"
 "os/exec"
 "strings"
 "database/sql"
 _ "github.com/lib/pq"
)
func main() {
 l, _ := net.Listen("unix", "/run/pgbranchd.sock")
 for {
  c, _ := l.Accept()
  go handle(c)
 }
}
func handle(c net.Conn) {
 r := bufio.NewScanner(c)
 for r.Scan() {
  parts := strings.Fields(r.Text())
  if len(parts) < 1 { continue }
  switch parts[0] {
  case "SNAPSHOT":
   snapshot(parts[1], parts[2])
  case "DROP":
   drop(parts[1])
  }
 }
}
func snapshot(src, dst string) {
 db, _ := sql.Open("postgres", "user=postgres dbname=postgres sslmode=disable")
 db.Exec("SELECT pg_advisory_lock(hashtext($1))", src)
 exec.Command("psql", "-U", "postgres", "-d", src, "-c", "CHECKPOINT").Run()
 snap := "snap_" + dst
 exec.Command("zfs", "snapshot", "pgpool/db_"+src+"@"+snap).Run()
 exec.Command("zfs", "clone", "pgpool/db_"+src+"@"+snap, "pgpool/db_"+dst).Run()
 db.Exec("CREATE TABLESPACE db_"+dst+" LOCATION '/pgpool/db_"+dst+"'")
 db.Exec("CREATE DATABASE "+dst+" TABLESPACE db_"+dst)
 db.Exec("SELECT pg_advisory_unlock(hashtext($1))", src)
}
func drop(name string) {
 db, _ := sql.Open("postgres", "user=postgres dbname=postgres sslmode=disable")
 db.Exec("DROP DATABASE IF EXISTS "+name)
 exec.Command("zfs", "destroy", "-r", "pgpool/db_"+name).Run()
}
