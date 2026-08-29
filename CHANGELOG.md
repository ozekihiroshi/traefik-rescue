# Changelog

All notable changes to this project will be documented in this file.

## Unreleased

### Changed

- Replaced application-specific architecture and migration text with generic
  consumer and embedded-gateway guidance.
- Added a documented external, mode-0600 deployment environment workflow.
- Expanded ignore rules for private environment variants and certificate files.

## [0.1.0-alpha.1] - 2026-08-27

### Added

- Independent Traefik 3.6 gateway for multiple Docker Compose projects.
- Shared `rescue_proxy` network and persistent ACME state.
- HTTP-to-HTTPS redirection, TLS policy, health checks, and JSON access logs.
- Explicit consumer opt-in through `traefik.rescue.gateway=true`.
- Loopback-only diagnostic dashboard override.
- Generic consumer integration and staged migration guidance.

### Known limitations

- Alpha quality; a production cutover has not been performed by this release.
- Single gateway instance with no automatic failover.
- Docker discovery still requires access to the local Docker API socket.
- Monitoring, ACME backup automation, and DNS automation are not bundled.
