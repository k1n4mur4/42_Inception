FROM debian:bookworm

RUN apt update && apt install -y mariadb-server \
	&& mkdir -p /run/mysqld \
	&& chown mysql /run/mysqld

COPY tools/init.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init.sh

CMD ["/usr/local/bin/init.sh"]
