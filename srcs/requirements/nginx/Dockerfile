FROM debian:bookworm

RUN	apt-get update \
	&& apt-get install -y --no-install-recommends nginx openssl \
	&& rm -rf /var/lib/apt/lists/*

CMD ["nginx", "-g", "daemon off;"]