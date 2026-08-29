#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

env_file=${TRAEFIK_ENV_FILE:-.env}
if [ ! -f "$env_file" ]; then
    echo "Missing environment file: $env_file" >&2
    echo "Copy .env.example to an ignored file or set TRAEFIK_ENV_FILE." >&2
    exit 1
fi

docker compose --env-file "$env_file" config --quiet
docker compose --env-file "$env_file" up -d
docker compose --env-file "$env_file" ps
