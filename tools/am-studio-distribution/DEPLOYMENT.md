# AM STUDIO MUSIC DISTRIBUTION — SANDBOX DEPLOYMENT CONTRACT

Status: DEPLOYMENT FOUNDATION READY / HOST NOT YET PROVISIONED

## Container

Backend image source:
`tools/am-studio-distribution/backend/Dockerfile`

Container port: `8787`
Health endpoint: `GET /health`
Application API: `/v1/*`

## Required environment

- `HOST=0.0.0.0`
- `PORT=8787`
- `AM_AUTH_MODE=DEV_TOKEN` for current sandbox only
- `AM_DEV_TOKEN=<secret>`
- `AM_STATE_FILE=/data/state/am-studio-state.json`
- `AM_MEDIA_DIR=/data/media`
- `AM_DISTRIBUTION_PROVIDER=disabled` until provider onboarding

When LabelGrid sandbox is commercially activated:
- `AM_DISTRIBUTION_PROVIDER=labelgrid`
- `LABELGRID_ENV=sandbox`
- `LABELGRID_API_TOKEN=<server secret>`

Never bake secrets into the image, repository, Android APK, Dockerfile, or CI logs.

## Networking

The Android client accepts HTTPS only. The sandbox backend therefore needs:
- a real HTTPS hostname;
- valid TLS certificate;
- reverse proxy/load balancer terminating TLS;
- request size limits large enough for audio masters;
- persistent volume for current DEV JSON/media adapters.

Do not weaken Android cleartext policy to make deployment easier.

## Current storage warning

The Docker container is deployment-capable for sandbox testing, but the current JSON-file catalog and local filesystem media adapters are not the target production persistence layer.

Before controlled beta, replace them behind the same interfaces with:
- managed relational database;
- managed object storage with signed upload URLs;
- production identity/session provider;
- secret manager/vault;
- backups and retention policies.

## Sandbox evidence sequence

1. Build container.
2. Start with provider disabled.
3. Verify `/health`.
4. Authenticate to `/v1/me` with sandbox bearer token.
5. Create release.
6. Create upload session.
7. PUT actual file bytes.
8. Complete technical asset metadata.
9. Patch release with verified asset IDs.
10. Run preflight.
11. Submit review.
12. Verify persistence after container restart with mounted volume.
13. Configure provider only after provider account/token/IP allowlist are ready.

## Production promotion gate

A sandbox deployment is not production just because it is reachable over HTTPS. Production promotion additionally requires KYC/KYB, rights/moderation operations, production database/object storage, provider production approval, audit/monitoring, fraud controls, royalty ledger, payout controls, legal terms, privacy/data-retention controls, backups, incident handling, and controlled release governance.
