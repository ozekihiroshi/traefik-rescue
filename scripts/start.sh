#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

if [ ! -f .env ]; then
    echo "Missing .env. Copy .env.example and set ACME_EMAIL." >&2
    exit 1
fi

docker compose config --quiet
docker compose up -d
docker compose ps
