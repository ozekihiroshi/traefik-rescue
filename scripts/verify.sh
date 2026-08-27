#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

env_file="${TRAEFIK_ENV_FILE:-.env}"
if [ ! -f "$env_file" ]; then
    env_file=.env.example
fi

docker compose --env-file "$env_file" config --quiet
docker compose --env-file "$env_file" config --format json | python3 -c '
import json
import sys

model = json.load(sys.stdin)
service = model["services"]["traefik"]
command = set(service.get("command", []))

required_arguments = {
    "--api.dashboard=false",
    "--providers.docker.exposedbydefault=false",
    "--providers.docker.constraints=Label(`traefik.rescue.gateway`,`true`)",
}
missing = required_arguments - command
assert not missing, f"missing secure Traefik arguments: {sorted(missing)}"

published_ports = {int(item["published"]) for item in service.get("ports", [])}
assert published_ports == {80, 443}, f"unexpected published ports: {sorted(published_ports)}"

assert service.get("read_only") is True, "Traefik root filesystem must be read-only"
assert "no-new-privileges:true" in service.get("security_opt", []), "no-new-privileges is required"

socket_mounts = [
    mount for mount in service.get("volumes", [])
    if mount.get("source") == "/var/run/docker.sock"
    and mount.get("target") == "/var/run/docker.sock"
]
assert len(socket_mounts) == 1, "exactly one Docker socket mount is required"
assert socket_mounts[0].get("read_only") is True, "Docker socket must be mounted read-only"

acme_mounts = [mount for mount in service.get("volumes", []) if mount.get("target") == "/letsencrypt"]
assert len(acme_mounts) == 1, "the ACME state volume is required"
'

if docker compose --env-file "$env_file" ps --status running --services | grep -qx traefik; then
    health="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' traefik-rescue-traefik-1)"
    [ "$health" = healthy ] || {
        echo "Traefik is running but not healthy: $health" >&2
        exit 1
    }
fi

echo "Traefik Rescue Compose and security invariants verified."
