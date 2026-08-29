# Private deployment configuration

The public repository contains only example values. A real deployment should
not require committing its domain names, operational email, bind addresses,
certificate account, logs, or consumer inventory.

## Recommended location

Keep the real environment outside the Git checkout:

```sh
sudo install -d -m 0700 /etc/traefik-rescue
sudo install -m 0600 .env.example /etc/traefik-rescue/gateway.env
sudoedit /etc/traefik-rescue/gateway.env
```

Use it consistently:

```sh
export TRAEFIK_ENV_FILE=/etc/traefik-rescue/gateway.env
sh scripts/verify.sh
sh scripts/start.sh
sh scripts/stop.sh
```

Do not source the file into an interactive shell. The helper scripts pass it to
Docker Compose with `--env-file`.

## Public versus private

Safe to publish as examples:

- variable names and placeholder values under `example.org`;
- the generic proxy network name;
- router-label templates;
- security and migration procedures without real inventories.

Keep private:

- real hostnames and DNS inventory when operational privacy matters;
- ACME account email and account state;
- private keys and locally trusted development certificates;
- access logs and `docker inspect` output;
- IP addresses, VPN routes, upstream inventory, and firewall rules;
- credentials or application environment files.

The repository ignores `.env`, `.env.*` except `.env.example`, certificate key
extensions, `private/`, `letsencrypt/`, and `logs/`. Ignore rules reduce
accidental commits but are not a secret-management system. Use restricted file
permissions, a password manager or secret store, and credential rotation.

## If a value was committed

Removing a secret from the latest commit does not revoke it or erase Git
history. Rotate the value first. Then stop tracking the file and decide whether
the repository history and all clones must be rewritten. Treat author name and
email in Git commit metadata separately from server configuration.
