# Traefik Rescue

Traefik Rescue is the shared HTTPS gateway for the Rescue family of Docker
Compose projects. It lets Moodle Rescue, Python Lab Rescue, Demand Monitor,
Growi, and future services share ports 80 and 443 without making any one
application own the reverse proxy.

This repository owns only the public gateway, its certificate state, and the
stable Docker proxy network. Databases, application data, learner workspaces,
and application credentials stay in their respective projects.

## Status

This is an alpha configuration. The same-host topology is intended for a
small, invite-only pilot on a dedicated Linux server. A wider deployment must
put Python Lab on a separate host because JupyterHub controls a Docker daemon
to create learner containers.

## Architecture

```text
Internet
   |
   v
Traefik Rescue :80/:443
   |-- Moodle Rescue       learn.example.org
   |-- Python Lab Rescue   lab.example.org
   |-- Demand Monitor      portal.example.org
   `-- Growi               wiki.example.org
```

Only public web front ends join the shared `${TRAEFIK_NETWORK}`. Databases,
Redis, MongoDB, Moodle cron, backup jobs, and learner containers remain on
private application networks.

## Prepare in WSL or Linux

Docker Desktop is not required. On the target Linux host or Ubuntu 24.04 in
WSL:

```sh
cd /mnt/d/workspace/traefik-rescue
cp .env.example .env
```

Set a real operational email address in `.env`. The example uses Let's Encrypt
staging so rehearsals cannot consume production issuance limits. Change it to
the production endpoint only for the real cutover:

```text
ACME_CA_SERVER=https://acme-v02.api.letsencrypt.org/directory
```

Validate before starting:

```sh
sh scripts/verify.sh
```

Start the gateway only after ports 80 and 443 are free:

```sh
sh scripts/start.sh
```

Stop without deleting certificate state or the shared network:

```sh
sh scripts/stop.sh
```

Do not run `docker compose down -v` during an ordinary stop. The `-v` option
deletes the ACME certificate volume.

## Dashboard

The production Compose file does not expose the Traefik dashboard. For local
administrative diagnostics only, bind it to loopback:

```sh
docker compose -f docker-compose.yml -f docker-compose.dashboard.yml up -d
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

Only its public service joins `proxy`. It must opt in explicitly with
both `traefik.enable=true` and `traefik.rescue.gateway=true`. The second label
prevents this gateway from adopting containers that belong to an older or
unrelated Traefik deployment. See [consumer integration](docs/consumer-integration.md)
for Moodle, Python Lab, and Demand Monitor examples.

## Migration from Demand Monitor

The existing Traefik in Demand Monitor currently owns ports 80 and 443. Do not
start this project at the same time. Follow the staged runbook in
[migration-from-demand-monitor.md](docs/migration-from-demand-monitor.md):

1. Validate this project without starting it.
2. Connect and validate each consumer Compose model.
3. Back up the existing ACME state.
4. Schedule a maintenance window.
5. Stop only the old Traefik service.
6. Start Traefik Rescue and test every hostname.
7. Remove the old service definition only after successful observation.

## Security boundary

The Docker provider currently reads the local Docker socket. The read-only
mount prevents changing the socket file but does not make Docker API access
harmless. Treat compromise of Traefik as potential compromise of the Docker
host. Keep the image pinned, expose no dashboard, and use a dedicated host for
the pilot. A later hardening stage may replace Docker discovery with explicit
file-provider routes or a narrowly filtered Docker API proxy.

See [SECURITY.md](SECURITY.md) before any public deployment.

## License

Copyright © 2026 Hiroshi Ozeki. Licensed under GNU GPL version 3 or, at your
option, any later version. See [LICENSE](LICENSE).
