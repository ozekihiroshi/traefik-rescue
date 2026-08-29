# Consumer integration

This guide uses the example network name `rescue_proxy`, certificate resolver
name `myresolver`, hostname `app.example.org`, and container port `8000`.
Replace them through private environment values; do not commit live hostnames,
addresses, or credentials.

## Common rules

Each application project declares, but does not create, the shared network:

```yaml
networks:
  proxy:
    external: true
    name: ${TRAEFIK_NETWORK:-rescue_proxy}
```

Only an intentionally public front end joins `proxy`. Databases, caches,
queues, workers, scheduled jobs, backup containers, and user workloads stay on
private project networks.

Every public service needs both opt-in labels because Docker discovery defaults
to disabled and the gateway applies a provider constraint:

```yaml
labels:
  traefik.enable: "true"
  traefik.rescue.gateway: "true"
```

## Same-host Compose example

The public front end joins its private application network and the shared proxy
network. Its database joins only the private network.

```yaml
services:
  web:
    image: example/application:1.0
    labels:
      traefik.enable: "true"
      traefik.rescue.gateway: "true"
      traefik.docker.network: ${TRAEFIK_NETWORK:-rescue_proxy}
      traefik.http.routers.example-app.rule: Host(`${APP_HOST}`)
      traefik.http.routers.example-app.entrypoints: websecure
      traefik.http.routers.example-app.tls.certresolver: ${TRAEFIK_CERT_RESOLVER:-myresolver}
      traefik.http.routers.example-app.service: example-app
      traefik.http.services.example-app.loadbalancer.server.port: "8000"
    networks:
      - application
      - proxy

  db:
    image: example/database:1.0
    networks:
      - application

networks:
  application:
    driver: bridge
  proxy:
    external: true
    name: ${TRAEFIK_NETWORK:-rescue_proxy}
```

Use globally unique router, middleware, and service names. Do not publish the
application container port on the host when Traefik is its only intended entry
point.

## Reverse-proxy application settings

Each application remains responsible for its own proxy-aware configuration.
Verify at least the following:

- its public base URL uses `https` and the intended hostname;
- forwarded host and protocol headers are trusted only from the accepted proxy
  boundary;
- secure cookies and callback URLs use HTTPS;
- WebSocket or streaming paths work through the proxy when required;
- iframe policy is compatible with any intentional embedding;
- health checks do not expose confidential data.

Do not apply the optional `secure-headers@file` middleware blindly. Its
`frameDeny=true` setting is unsuitable for applications that must be embedded
by an approved parent site.

## Multiple public front ends

If one application project has multiple public front ends, attach each one
individually to `proxy` and give each route a unique name. Do not attach the
entire private application network to Traefik.

## Separate-host application

A Docker bridge network cannot span hosts. On a separate application host,
publish the front end only to a protected private address and firewall it to
the gateway host or VPN. Configure Traefik's file provider with that private
upstream. Keep the public hostname in private deployment configuration rather
than in this repository.

## Validation checklist

Before deployment, render the consumer model with `docker compose config` and
confirm:

1. only intended public front ends join the external proxy network;
2. every public front end has both required opt-in labels;
3. `traefik.docker.network` names the same external network as the gateway;
4. router, middleware, and service names are unique;
5. the upstream container port is correct;
6. no database, cache, queue, worker, backup, or workload service joins the
   external proxy network.
