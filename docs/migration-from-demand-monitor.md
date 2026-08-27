# Migration from the Demand Monitor gateway

This runbook avoids running two processes on host ports 80 and 443 and keeps a
rollback path. Commands are examples; inspect the rendered Compose model and
backups before running them on a production host.

## 1. Inventory and prepare

- Record every current hostname, router, middleware, and upstream port.
- Confirm DNS points at the intended gateway host.
- Copy `.env.example` to `.env` and set the ACME email and network name.
- Run `sh scripts/verify.sh` without starting Traefik Rescue.
- Render each consumer with `docker compose config` and verify that only its
  public service joins `rescue_proxy`.
- Add `traefik.rescue.gateway=true` only to public services that are ready for
  the new gateway; leave it absent during preparation and rollback rehearsals.

## 2. Preserve rollback material

- Back up Demand Monitor's Compose file.
- Back up its current `traefik/acme.json` with permissions and ownership.
- Export `docker inspect` results for the old Traefik container and network.
- Record the command that starts only the old Traefik service.

Do not commit the ACME backup or copy it into an image. Decide deliberately
whether to migrate that account state or allow the new gateway to request new
certificates. Use the ACME staging endpoint during rehearsals.

## 3. Prepare the shared network

Traefik Rescue creates the stable named network `rescue_proxy` when started.
Consumer projects declare it as external. If consumers must be rendered before
the gateway starts, create it explicitly:

```sh
docker network create rescue_proxy
```

Creating an existing network returns an error, so inspect first with:

```sh
docker network inspect rescue_proxy
```

## 4. Maintenance-window cutover

1. Stop only the old Traefik service; keep Demand Monitor application services
   running.
2. Confirm host ports 80 and 443 are free.
3. Start Traefik Rescue.
4. Recreate each consumer's public service so it joins `rescue_proxy`.
5. Test HTTPS, certificate chain, redirects, login, uploads, LTI launch, and
   application-specific health paths for every hostname.
6. Observe access and error logs before ending the maintenance window.

## 5. Rollback

If a critical route fails:

1. Stop Traefik Rescue without deleting volumes.
2. Restore the old network/configuration if it was changed.
3. Start the old Demand Monitor Traefik service.
4. Re-test all hostnames.

## 6. Cleanup after observation

Only after a stable observation period:

- Remove the Traefik service and certificate ownership from Demand Monitor.
- Move DB, Redis, MongoDB, queue, and worker services onto private networks.
- Remove obsolete port 8080 publication.
- Update operational documentation and backup jobs to name Traefik Rescue as
  the gateway owner.
