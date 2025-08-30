FROM ubuntu:22.04
RUN apt-get update && apt-get install -y postgresql-16 zfsutils-linux libpq-dev netcat python3
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
COPY cmd/pgbranchd/ /pgbranchd
RUN chmod +x /pgbranchd/main.py
VOLUME /hostdata
EXPOSE 5432
ENTRYPOINT ["/entrypoint.sh"]
