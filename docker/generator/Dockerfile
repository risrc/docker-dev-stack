FROM nginxproxy/docker-gen

RUN apk update && apk add --no-cache bash curl jq

WORKDIR /tmp
COPY install-mkcert install-mkcert
RUN ./install-mkcert && rm install-mkcert

WORKDIR /etc/docker-gen
COPY templates templates
COPY config config

COPY generate-certificates /usr/local/bin/generate-certificates


