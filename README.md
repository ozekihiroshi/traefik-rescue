# Traefik Rescue

Traefik Rescue is a shared HTTPS gateway for independent Docker Compose
projects. It lets multiple applications share ports 80 and 443 without making
any one application own the reverse proxy.

This repository owns only the public gateway, its certificate state, and the
stable Docker proxy network. Databases, application data, workspaces, and
application credentials stay in their respective projects.

All tracked hostnames, addresses, email values, and credentials are examples.
Site-specific configuration belongs in an ignored `.env` file or, preferably,
in a mode-0600 environment file outside the Git checkout.

## Status

This is an alpha configuration intended for a small, controlled deployment on
a dedicated Linux server. High-risk workloads that control a Docker daemon or
execute untrusted user code should be placed on a separate host and reached
through a private network or VPN.

## Alpha limitations

This release provides one gateway container, one persistent ACME volume, a
stable proxy network, explicit consumer opt-in, and a generic migration
runbook. It does not provide:

- high availability or automatic failover;
- DNS automation or DNS-01 challenges;
- automated ACME backup, monitoring, or alert delivery;
- a Docker API proxy or socket-free discovery mode;
- automatic migration from an existing application-owned gateway;
- a broad public deployment security review.

## Architecture

```text
Internet
   |
   v
Traefik Rescue :80/:443
   |-- app-a.example.org     public front end A
   |-- app-b.example.org     public front end B
   `-- admin.example.org     optional administration front end
```

Only intentionally public front ends join the shared `${TRAEFIK_NETWORK}`.
Databases, queues, workers, backup jobs, and user workload containers remain on
private application networks.

## Requirements

- A supported Linux host or Ubuntu 24.04 in WSL with Docker Engine.
- Docker Compose v2 with support for `config --format json`.
- Public DNS records for every production hostname.
- Host ports 80 and 443 available to this gateway at cutover time.
- A maintenance and rollback window when replacing an existing gateway.

Docker Desktop is not required. Do not start Traefik Rescue while another
gateway still owns ports 80 or 443.

## Keep deployment values private

For a local evaluation, copy the tracked example to the ignored `.env` file:

```sh
cp .env.example .env
```

For a server, keep the real file outside the checkout:

```sh
sudo install -d -m 0700 /etc/traefik-rescue
sudo install -m 0600 .env.example /etc/traefik-rescue/gateway.env
sudoedit /etc/traefik-rescue/gateway.env
```

Then pass its path to every helper:

```sh
TRAEFIK_ENV_FILE=/etc/traefik-rescue/gateway.env sh scripts/verify.sh
TRAEFIK_ENV_FILE=/etc/traefik-rescue/gateway.env sh scripts/start.sh
TRAEFIK_ENV_FILE=/etc/traefik-rescue/gateway.env sh scripts/stop.sh
```

See [private deployment configuration](docs/private-configuration.md) for the
boundary between published examples and private operational state.

The example uses the Let's Encrypt staging endpoint so rehearsals cannot
consume production issuance limits. Change it only for the real cutover:

```text
ACME_CA_SERVER=https://acme-v02.api.letsencrypt.org/directory
```

Do not run `docker compose down -v` during an ordinary stop. The `-v` option
deletes the ACME certificate volume.

## Dashboard

The production Compose file does not expose the Traefik dashboard. For local
administrative diagnostics only, bind it to loopback:

```sh
docker compose --env-file /path/to/gateway.env \
  -f docker-compose.yml -f docker-compose.dashboard.yml up -d
```

Then use an SSH tunnel or open `http://127.0.0.1:8080/dashboard/` on the host.
Never publish port 8080 to the internet.

## Connect an application

An application Compose project declares the gateway network as external:

```yaml
networks:
  proxy:
    external: true
    name: ${TRAEFIK_NETWORK:-rescue_proxy}
```

Only its public service joins `proxy`. It must opt in explicitly with both
`traefik.enable=true` and `traefik.rescue.gateway=true`. The second label
prevents this gateway from adopting containers that belong to an older or
unrelated Traefik deployment.

See [consumer integration](docs/consumer-integration.md) for a generic Compose
template and [migration from an embedded gateway](docs/migration-from-embedded-gateway.md)
for a staged cutover and rollback process.

## Security boundary

The Docker provider currently reads the local Docker socket. The read-only
mount prevents changing the socket file but does not make Docker API access
harmless. Treat compromise of Traefik as potential compromise of the Docker
host. Keep the image pinned, expose no dashboard, and use a dedicated host for
the accepted trust boundary. A later hardening stage may replace Docker
discovery with explicit file-provider routes or a narrowly filtered Docker API
proxy.

See [SECURITY.md](SECURITY.md) before any public deployment.

## License

Copyright (c) 2026 Hiroshi Ozeki. Licensed under GNU GPL version 3 or, at your
option, any later version. See [LICENSE](LICENSE).
