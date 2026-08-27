#!/bin/sh
set -eu

cd "$(dirname "$0")/.."
docker compose stop

echo "Traefik stopped. The ACME volume and shared proxy network were retained."
