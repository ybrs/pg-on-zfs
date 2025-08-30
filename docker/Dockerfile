FROM ubuntu:22.04
RUN apt-get update && \
    apt-get install -y curl gnupg lsb-release && \
    curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get install -y postgresql-16 zfsutils-linux libpq-dev netcat golang-go && \
    rm -rf /var/lib/apt/lists/*
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
COPY cmd/pgbranchd/ /pgbranchd
RUN go build -o /usr/local/bin/pgbranchd /pgbranchd
VOLUME /hostdata
EXPOSE 5432
ENTRYPOINT ["/entrypoint.sh"]
