Docker Dev Stack
================

This project provides an easy to set up ssl proxy for local docker compose based web development.

It utilises [docker-gen](https://github.com/nginx-proxy/docker-gen) and [mkcert](https://github.com/FiloSottile/mkcert)
to watch container events and generates self-signed SSL certificates for new launched containers.

The nginx proxy configuration is updated automatically and an index page with all currently available vhosts is provided on `https://localhost`.

Additionally, [MailDev](#maildev) is provided for local email testing.

Supported OS
------------
- Linux
- MacOS
- Windows (tested with WSL2 running Ubuntu and Docker Desktop)

Requirements
------------
- [Docker CE](https://docs.docker.com/engine/install/)
- [Docker Compose](https://docs.docker.com/compose/)
- bash shell (to run the init script)
- certutil (necessary for mkcert)
- [jq](https://jqlang.github.io/jq/) (used in init script)

The init script tries to resolve missing `certutil` and `jq` dependencies or provides links for setup instructions

Usage
-----

### Start the proxy
1. Clone this repository
2. run `bin/init` from the project root and resolve missing dependencies if necessary
3. start the containers by running `docker compose up -d`

### Using the proxy in other compose projects
Add the proxy as external network in your compose file.
```
networks:
  proxy:
    name: dev_proxy
    external: true
```

Configure your service to access the proxy network and add the `VIRTUAL_HOST` environment variable
to provide the desired local domain name.

```
services:
  ..
  my_vhost_service:
    ..
    networks:
      - proxy # connect to proxy network
      - default # preserve access to other project containers (i.e. database)
    environment:
      VIRTUAL_HOST: my-domain.localhost
```


If the service exposes only one port, this will be used by the generated nginx upstream,
otherwise it will fall back to port `80`.

To configure a specific port, the `VIRTUAL_PORT` environment variable is available.
```
  environment:
    VIRTUAL_HOST: my-domain.localhost
    VIRTUAL_PORT: 8080
```

How it works
------------
### Initializing a local root certificate and handling the local truststores
- the init script downloads the current version of mkcert available for the host machine
- mkcert generates a new rootCA and updates your local truststore
  (Windows users, please see [troubleshooting](#mkcert-isnt-able-to-install-the-rootca-in-the-windows-truststore) instructions) 

### Generating new SSL certificates for docker containers on the fly
- **docker-gen** listens to container events using the read-only mounted `docker.sock`
- when a container is started/stopped and vhost entries are added/removed:
  - missing SSL certificates are generated
  - the nginx configuration is updated
  - the index page is updated with all available projects and their defined vhosts

Additional Utilities
--------------------
### maildev
[MailDev](https://github.com/maildev/maildev) is a simple way to test your project's generated emails during development,
with an easy-to-use web interface that runs on your machine.

#### Usage
Configure your application to send emails via `SMTP` on port `1025`.

The MailDev user interface is available at [maildev.localhost](https://maildev.localhost)

Troubleshooting
---------------
### mkcert isn't able to install the rootCA in the Windows truststore
The certificate can be installed manually
- if WSL2 is detected from the init script, it will display a hint pointing to the rootCA location
- open (double-click) the mentioned rootCA.crt file and follow the instructions from the dialog
  (the correct target truststore should be selected manually)

Solution is based on these comments from the mkcert issue tracker:  [\[1\]](https://github.com/FiloSottile/mkcert/issues/357#issuecomment-1466762021), [\[2\]](https://github.com/FiloSottile/mkcert/issues/357#issuecomment-1471909333)

### websocket connections cause error with http2
If you encounter similar errors to "Illegal connection-specific header 'upgrade' encountered",
you can disable http2 for the container by setting the `DISABLE_HTTP2` environment variable to `true`.

```
  environment:
    DISABLE_HTTP2: true
```

LICENSE
-------
[MIT](LICENSE)
