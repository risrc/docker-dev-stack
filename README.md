Dev Proxy
=========

This project provides an easy to set up ssl proxy for local docker-compose based web development.

It utilises [docker-gen]() and [mkcert]() to watch container events and automatically generate self-signed SSL
certificates for new launched containers. The nginx proxy configuration is updated and an index page
listing all available vhosts is provided.

Requirements
------------
- bash shell to run the init script
- [docker]()
- [docker-compose]()
- certutil (for [mkcert certificate generation]())
- [jq]() during setup

The init script tries to resolve missing `certutil` and `jq` dependencies or provides some setup information

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

Configure your service to join the network and add VIRTUAL_HOST environment variable
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


Troubleshooting
---------------

Windows support (using WSL2)
https://github.com/FiloSottile/mkcert/issues/357#issuecomment-1466762021

