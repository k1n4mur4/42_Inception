FROM debian:bookworm

RUN apt update && apt install -y nginx openssl mariadb-client

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY ssl/nginx.crt /etc/nginx/ssl/nginx.crt
COPY ssl/nginx.key /etc/nginx/ssl/nginx.key
COPY html/index.html /var/www/html/index.html

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]