FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
        nginx \
        openssl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl && \
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/C=JP/ST=Tokyo/L=Tokyo/O=42Tokyo/OU=kinamura/CN=kinamura.42.fr"

COPY conf/nginx.conf /etc/nginx/nginx.conf

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
