FROM debian:bookworm

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		php-fpm \
		php-mysql \
		mariadb-client \
		curl \
		ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

RUN curl -O https://wordpress.org/wordpress-6.4.2.tar.gz \
	&& tar -xzf wordpress-6.4.2.tar.gz \
	&& mkdir -p /var/www/html \
	&& mv wordpress /var/www/html/wordpress-src \
	&& rm wordpress-6.4.2.tar.gz \
	&& chown -R www-data:www-data /var/www/html/wordpress-src

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x wp-cli.phar \
	&& mv wp-cli.phar /usr/local/bin/wp

COPY tools/wp-config.php /usr/local/share/wp-config.php
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/init.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init.sh

CMD ["/usr/local/bin/init.sh"]