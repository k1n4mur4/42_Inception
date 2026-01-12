FROM debian:bookworm

RUN apt update && apt install -y \
    php-fpm \
    php-mysql \
    curl \
    && mkdir -p /run/php \
    && mkdir -p /var/www/html

RUN curl -O https://wordpress.org/wordpress-6.4.2.tar.gz \
    && tar -xzf wordpress-6.4.2.tar.gz \
    && mv wordpress /var/www/html/ \
    && rm wordpress-6.4.2.tar.gz \
    && chown -R www-data:www-data /var/www/html/wordpress

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/init.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init.sh

CMD ["/usr/local/bin/init.sh"]
