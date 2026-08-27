# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0-alpha.1] - 2026-08-27

### Added

- Independent Traefik 3.6 gateway for the Rescue family of Compose projects.
- Shared `rescue_proxy` network and persistent ACME state.
- HTTP-to-HTTPS redirection, TLS policy, health checks, and JSON access logs.
- Explicit consumer opt-in through `traefik.rescue.gateway=true`.
- Loopback-only diagnostic dashboard override.
- Integration guidance for Moodle Rescue, Python Lab Rescue, and Demand Monitor.
- Staged migration and rollback runbook for the existing embedded gateway.

### Known limitations

- Alpha quality; production cutover has not been performed by this release.
- Single gateway instance with no automatic failover.
- Docker discovery still requires access to the local Docker API socket.
- Monitoring, ACME backup automation, and DNS automation are not bundled.
