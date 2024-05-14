Dev Proxy
=========

This project provides an easy to set up ssl proxy for local docker-compose based web development.

It utilises [docker-gen]() and [mkcert]() to watch container events and automatically generate self-signed SSL
certificates for new launched containers. The nginx proxy configuration is updated as well and an index page
listing all currently available vhosts is provided.

Supported OS
------------
- Linux
- MacOS
- Windows (tested with Docker Desktop and WSL2 running Ubuntu)

Requirements
------------
- [docker]()
- [docker-compose]()
- bash shell (to run the init script)
- certutil (for [mkcert]() certificate generation)
- [jq]() during setup

The init script tries to resolve missing `certutil` and `jq` dependencies or provides links to setup instructions

Usage
-----

### Start the proxy
1. Clone this repository
2. run `bin/init` from the project root and resolve missing dependencies if necessary
3. start the containers by running `docker compose up -d`

### Use the proxy in other compose projects
Add the proxy as external network in your compose file.
```
networks:
  proxy:
    name: dev_proxy
    external: true
```

Configure your service to join the network and add `VIRTUAL_HOST` environment variable
to provide the desired local domain name.

```
services:
  ..
  my_vhost_service:
    ..
    networks:
      - proxy
      - default # to also access the default network for communication with other containers in this project.
    environment:
      VIRTUAL_HOST: my-domain.localhost
```


If the service exposes only one port, this will be used by the generated nginx upstream,
otherwise it will fall back to port `80`. To configure a port the `VIRTUAL_PORT` environment variable can be used.
```
  environment:
    VIRTUAL_HOST: my-domain.localhost
    VIRTUAL_PORT: 8080
```

How it works
------------
The init script downloads the current version of mkcert available for the host machine.
Mkcert generates a new rootCA and updates your local truststore. 

While the containers are running, docker-gen listens to container events using the read-only mounted `docker.sock`.

Every time a container is started/stopped, the defined templates are recompiled. If the vhost entries have changed:
- a notify command is executed to generate missing SSL certificates
- the nginx configuration is updated by sending a SIGHUP signal to the nginx container 
- an index page is generated, listing all available projects with their vhosts

Troubleshooting
---------------
### mkcert cannot install the rootCA in the Windows truststore
The certificate has to be installed manually.
If WSL2 is detected from the init script, it will display a hint pointing to the rootCA location.

Open (double-click) the mentioned rootCA.crt file and follow the instructions from the dialog.

See also [this comment](https://github.com/FiloSottile/mkcert/issues/357#issuecomment-1466762021)
from the mkcert issue tracker. 

Hint: the target truststore should be selected manually
