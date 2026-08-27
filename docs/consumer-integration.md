# Consumer integration

All examples assume the shared network name `rescue_proxy` and the certificate
resolver name `myresolver`. Both are kept compatible with Moodle Rescue's
current production Compose labels.

## Common rules

Each application project declares, but does not create, the shared network:

```yaml
networks:
  proxy:
    external: true
    name: ${TRAEFIK_NETWORK:-rescue_proxy}
```

Only its public web service joins `proxy`. Every public service needs an
explicit `traefik.enable=true` label because discovery defaults to disabled.
It also needs `traefik.rescue.gateway=true`; Traefik Rescue rejects containers
without this gateway-specific migration label.

## Moodle Rescue

Moodle Rescue already has the required router labels and an external proxy
network. Set these production values:

```text
MOODLE_HOST=learn.example.org
TRAEFIK_NETWORK=rescue_proxy
```

The Moodle web service joins both its private `internal` network and `proxy`.
The database and cron services do not join `proxy`. Confirm that Moodle's
generated configuration treats the deployment as an HTTPS reverse proxy.

The optional shared security-header middleware can be added after checking
Moodle iframe and LTI requirements. Do not apply `frameDeny=true` blindly to
routes that must be embedded by an approved platform.

## Python Lab Rescue: same-host pilot

Create a production override in Python Lab that removes its loopback port and
joins only JupyterHub to the shared proxy network:

```yaml
services:
  jupyterhub:
    ports: []
    labels:
      - traefik.enable=true
      - traefik.rescue.gateway=true
      - traefik.docker.network=${TRAEFIK_NETWORK:-rescue_proxy}
      - traefik.http.routers.python-lab.rule=Host(`${LAB_HOST}`)
      - traefik.http.routers.python-lab.entrypoints=websecure
      - traefik.http.routers.python-lab.tls.certresolver=myresolver
      - traefik.http.services.python-lab.loadbalancer.server.port=8000
    networks:
      - lab_internal
      - proxy

networks:
  proxy:
    external: true
    name: ${TRAEFIK_NETWORK:-rescue_proxy}
```

Production values must include:

```text
LAB_HOST=lab.example.org
LAB_AUTH_MODE=lti13
LAB_LOCAL_DEVELOPMENT=false
LTI13_URI_SCHEME=https
```

Do not run the local JWKS proxy in production. Point `LTI13_JWKS_ENDPOINT`
directly to Moodle's public HTTPS certificate endpoint. Learner containers
remain only on `lab_internal`; they never join `proxy`.

## Python Lab Rescue: separate-host production

Do not attempt to share a Docker bridge network across hosts. Attach
JupyterHub only to its Lab host networks and publish it to a private host
address. Configure the gateway with a file-provider service whose upstream is
that private address, protected by a firewall or VPN. The public hostname and
LTI endpoints remain `https://lab.example.org`.

## Demand Monitor

After removing the embedded Traefik service, declare `web` as the shared
external network or rename it to `proxy`. Only `webserver`, Growi, and other
intentionally public front ends should join it. Database, Redis, MongoDB,
queues, and application workers should use private project networks.

Every migrated router must keep `traefik.enable=true`, add
`traefik.rescue.gateway=true`, use a unique router name, the `websecure`
entrypoint, and `tls.certresolver=myresolver`.
