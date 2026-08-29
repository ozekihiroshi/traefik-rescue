#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

env_file=${TRAEFIK_ENV_FILE:-.env}
if [ ! -f "$env_file" ]; then
    echo "Missing environment file: $env_file" >&2
    echo "Set TRAEFIK_ENV_FILE to the same file used at startup." >&2
    exit 1
fi

docker compose --env-file "$env_file" stop

echo "Traefik stopped. The ACME volume and shared proxy network were retained."
