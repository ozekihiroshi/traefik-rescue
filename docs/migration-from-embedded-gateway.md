# Migration from an application-owned gateway

This runbook replaces a reverse proxy embedded in an application repository
with the independent Traefik Rescue gateway. It avoids running two processes on
host ports 80 and 443 and preserves a rollback path. Commands are examples;
inspect rendered Compose models, real project names, and verified backups
before changing a production host.

## 1. Inventory and prepare

- Record every current hostname, router, middleware, upstream port, redirect,
  and non-HTTP published port.
- Confirm DNS points at the intended gateway host.
- Put site-specific values in a mode-0600 environment file outside Git.
- Run `TRAEFIK_ENV_FILE=/path/to/gateway.env sh scripts/verify.sh` without
  starting Traefik Rescue.
- Render each consumer with `docker compose config` and verify that only its
  public service joins `rescue_proxy`.
- Add `traefik.rescue.gateway=true` only to public services ready for cutover.
- Confirm the old and new Compose project names and resolved volume names.

## 2. Preserve rollback material

- Back up the application Compose file and its private environment.
- Back up the existing ACME state with permissions and ownership.
- Create and restore-test current application data backups.
- Export `docker inspect` results for the old gateway container and network,
  storing the output outside Git.
- Record the exact command that starts only the old gateway service.

Do not commit ACME state, environment files, private keys, database dumps, or
inspection output. Decide deliberately whether to migrate the existing ACME
account state or let the new gateway request certificates. Use the ACME staging
endpoint during rehearsals.

## 3. Prepare the shared network

Traefik Rescue creates the stable named network `rescue_proxy` when started.
Consumer projects declare it as external. If a consumer must be rendered first,
create the network explicitly after checking that it does not already exist:

```sh
docker network inspect rescue_proxy || docker network create rescue_proxy
```

## 4. Maintenance-window cutover

1. Stop only the old gateway; keep application and data services running when
   their Compose design safely allows it.
2. Confirm host ports 80 and 443 are free.
3. Start Traefik Rescue with the protected environment file.
4. Recreate each consumer public front end so it joins `rescue_proxy`.
5. Test HTTPS, certificate chains, redirects, login, callbacks, uploads,
   streaming, and application-specific health paths for every hostname.
6. Observe access, error, and application logs before ending the window.

Never run `docker compose down -v` as part of an ordinary cutover. The `-v`
option can delete material application or certificate data.

## 5. Rollback

If a critical route fails:

1. Stop Traefik Rescue without deleting volumes.
2. Restore the old application network and Compose configuration if changed.
3. Start the old gateway service with its retained private environment.
4. Re-test all hostnames and critical application paths.

## 6. Cleanup after observation

Only after a stable observation period:

- remove the embedded gateway service from the application repository;
- transfer certificate-state ownership and backup responsibility to Traefik
  Rescue;
- keep databases, caches, queues, workers, and jobs on private networks;
- remove obsolete dashboard and gateway host-port publications;
- update startup, monitoring, incident, and rollback documentation;
- rotate credentials exposed by obsolete tracked environment files or history.
