# Security boundary

Traefik Rescue is an internet-facing component. A successful compromise can
expose routing metadata, certificate state, and—while the Docker provider is
enabled—access to the Docker API visible through the mounted socket.

## Required for a public pilot

- Run on a dedicated, supported Linux host with current security updates.
- Publish only TCP 80 and 443. Restrict SSH to an administrative VPN or
  allowlist.
- Keep the dashboard disabled. If temporarily enabled, bind it to
  `127.0.0.1` and use an SSH tunnel.
- Require the gateway-specific `traefik.rescue.gateway=true` label.
- Set `providers.docker.exposedByDefault=false` and opt in each public service.
- Attach only public front ends to the proxy network.
- Never attach databases, message queues, backup containers, learner
  containers, or Docker management services to the proxy network.
- Protect the ACME volume and back it up as sensitive operational state.
- Use Let's Encrypt staging during repeated configuration tests.
- Pin and regularly update the Traefik image after testing in staging.
- Monitor access logs, certificate renewal, container health, CPU, memory, and
  disk use.
- Define a tested rollback procedure before replacing an existing gateway.

## Docker socket

The production Compose model mounts `/var/run/docker.sock` read-only for
Traefik's Docker provider. Read-only is not a complete security boundary:
socket clients can still issue Docker API requests supported by their access.
Use this model only on a dedicated gateway/application host whose workloads
share an accepted trust boundary.

For stronger isolation, choose one of these designs:

1. Use Traefik's file provider with explicit upstream addresses and remove the
   Docker socket entirely.
2. Put a narrowly configured Docker API proxy between Traefik and the daemon,
   after reviewing exactly which endpoints are needed.
3. Place Python Lab on a separate host and route to it through a private
   network or VPN.

Do not expose an unauthenticated Docker TCP endpoint. Treat any credential
that can control a Docker daemon like a root credential.

## Certificates and secrets

- Do not commit `.env`, ACME account state, private keys, access logs, or
  application secrets.
- Use a monitored operational email address for ACME notices.
- Give application projects separate credentials; the gateway does not own
  Moodle, database, S3, or LTI secrets.
- Rotate secrets after suspected host or volume compromise.

## Application responsibilities

TLS termination does not make an application secure. Moodle must enable its
reverse-proxy and secure-cookie settings and run its security report. Python
Lab must disable development authentication, use HTTPS LTI 1.3 endpoints, and
keep learner containers away from Moodle and gateway networks.

## Reporting

Do not open a public issue containing private keys, credentials, personal
data, or an active exploit. Contact the maintainer privately and include the
affected version and a minimal reproduction.
