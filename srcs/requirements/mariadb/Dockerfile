FROM debian:bookworm

RUN apt-get update \
	&& apt-get install -y --no-install-recommends mariadb-server \
	&& rm -rf /var/lib/apt/lists/* \
	&& mkdir -p /run/mysqld \
	&& chown mysql:mysql /run/mysqld

COPY tools/init.sql /usr/local/share/init.sql
COPY tools/init.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init.sh

CMD ["/usr/local/bin/init.sh"]