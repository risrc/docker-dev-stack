FROM nginxproxy/docker-gen

RUN apk update && apk add --no-cache bash curl jq

WORKDIR /tmp
COPY install-mkcert install-mkcert
RUN ./install-mkcert && rm install-mkcert

COPY templates /etc/docker-gen/templates
COPY config /etc/docker-gen/config
COPY generate-certificates /usr/local/bin/generate-certificates
RUN ls -alh /etc/docker-gen/
