FROM ubuntu:22.04
RUN apt-get update && \
    apt-get install -y curl gnupg lsb-release && \
    sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && \
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/pgdg.gpg && \
    apt-get update && \
    apt-get install -y postgresql-16 postgresql-client-16 zfsutils-linux libpq-dev netcat golang && \
    rm -rf /var/lib/apt/lists/*
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
COPY go.mod go.sum cmd/pgbranchd/ /build/
RUN cd /build && go build -o /usr/local/bin/pgbranchd ./cmd/pgbranchd
VOLUME /hostdata
EXPOSE 5432
ENTRYPOINT ["/entrypoint.sh"]
