# MOSHI Internal Alpha v0.1 — Deploy & APK Build

Status: deployment-ready source. A public server, Firebase project, and stable signing secrets are external runtime configuration and are not committed to this repository.

## Ports

MOSHI Alpha API uses local port `8010` so it does not collide with other local FastAPI projects commonly using `8000`.

## Path A — proper internal alpha (PostgreSQL)

Use this on a Docker-capable host/VPS.

```bash
cd projects/moshi
cp .env.alpha.example .env.alpha
```

Replace both `CHANGE_ME` values in `.env.alpha` with long random values. Then:

```bash
docker compose --env-file .env.alpha -f docker-compose.alpha.yml up -d --build
curl http://127.0.0.1:8010/health
curl http://127.0.0.1:8010/ready
```

Expected responses include `status: ok` and `status: ready`.

The compose stack provides PostgreSQL 16 plus persistent volumes for database data and uploaded media. Local upload volume is acceptable for Internal Alpha only; public production must move media to object storage.

Expose `127.0.0.1:8010` only through an HTTPS reverse proxy/tunnel. Do not expose the raw HTTP port directly to the internet.

## Path B — phone smoke server (temporary SQLite)

This is specifically for real-device smoke testing when a Docker/PostgreSQL host is not available yet. It is not the production database path.

From the MOSHI project checkout in Termux/Ubuntu:

```bash
bash scripts/alpha-smoke-termux.sh
```

The script generates and preserves a private random JWT secret, uses `alpha-smoke` mode, stores a local SQLite DB, stores uploads locally, and listens only on `127.0.0.1:8010`.

In another shell, after `cloudflared` is installed:

```bash
bash scripts/alpha-cloudflare-tunnel.sh
```

Copy the generated `https://...trycloudflare.com` URL. Quick Tunnel URLs can change after restart.

## Build an APK pinned to the public endpoint

After this branch is merged to `main`, open GitHub Actions and run **MOSHI Alpha APK** manually.

Input:
- `api_base_url`: the public HTTPS API URL, without requiring `/v1`.
- `build_label`: optional label such as `alpha-v0.1-device-test`.

The workflow rejects non-HTTPS endpoints and `.invalid` placeholders, compiles the Android app with that endpoint, and uploads:
- `MOSHI-alpha.apk`
- `MOSHI-alpha.sha256`
- `MOSHI-alpha-build.txt`

The build receipt records the exact commit and API endpoint.

## Stable signing and no-uninstall upgrades

The workflow supports stable signing when all four repository Actions secrets exist:
- `MOSHI_ALPHA_KEYSTORE_B64`
- `MOSHI_ALPHA_KEY_ALIAS`
- `MOSHI_ALPHA_KEY_PASSWORD`
- `MOSHI_ALPHA_STORE_PASSWORD`

Without all four, the workflow emits a normal CI debug-signed APK and records `stable_signing=false`. Debug signing is enough for the first smoke test, but future CI runners may use a different debug key and Android can require uninstall before installing an update.

Never commit the keystore or passwords to the repository.

## Firebase boundary

Notification plumbing is already compiled and tested, but real FCM push is not live until a MOSHI Firebase Android app and backend Google credentials are provisioned. Do not claim push notifications are live until they pass physical-device background/process-death tests.

## Alpha security boundary

`MOSHI_ENVIRONMENT=alpha` rejects:
- the development JWT secret;
- JWT secrets shorter than 32 characters;
- SQLite database URLs.

`alpha-smoke` also rejects the development/short JWT secret, but allows SQLite only for temporary phone smoke testing.

## Before any public beta

Internal Alpha's `create_all` schema bootstrap and local media volume are temporary. Before public beta, add a real migration system, PostgreSQL backups, object storage, Redis fan-out/presence, stable HTTPS/domain infrastructure, production signing, Firebase credentials, monitoring, and recovery procedures.
