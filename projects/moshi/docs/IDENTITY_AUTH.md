# MOSHI — IDENTITY / AUTH v1.0

Status: IMPLEMENTED / PHASE 1 FOUNDATION SLICE

## Identity

Public identity is username-first. Phone number is not required by the current contract.

- `user.id`: immutable internal UUID
- `username`: unique, lowercase, 3–30 chars (`a-z`, `0-9`, `_`)
- `display_name`: editable public name
- `business_mode`: same-account capability switch; no second APK/account required

## Password and session security

- Passwords are hashed with Argon2; plaintext passwords are never stored.
- Access tokens are signed JWTs and expire after 15 minutes by default.
- Refresh tokens are opaque random secrets, stored server-side only as SHA-256 hashes.
- Refresh is rotating: using a refresh token revokes that device session token and returns a new one.
- Logout revokes the matching session.
- Android does not persist the access token. It persists only the refresh token, encrypted with an AES/GCM key held by Android Keystore.
- Release builds must use HTTPS. Cleartext HTTP is enabled only through the debug manifest for local development.

Before public deployment:

- replace `MOSHI_JWT_SECRET` with a long random production secret;
- move production storage from SQLite to PostgreSQL;
- add account recovery / verification policy;
- add login rate limiting and suspicious-session telemetry;
- add database migrations rather than relying on `create_all`;
- add server-side device/session management UI.

## API contract

### `POST /v1/auth/register`

Creates a user and device session.

Request fields: `username`, `display_name`, `password`, `device_name`.

Returns user profile + access token + rotating refresh token.

### `POST /v1/auth/login`

Authenticates username/password and creates a new device session.

### `POST /v1/auth/refresh`

Rotates a valid refresh token and returns a new auth session.

### `POST /v1/auth/logout`

Revokes the matching refresh/session token. Idempotent.

### `GET /v1/me`

Requires bearer access token. Returns current profile.

### `PATCH /v1/me`

Requires bearer access token. Current Phase 1 fields:

- `display_name`
- `business_mode`

Business Mode remains a capability of the same MOSHI account and app.

## Android Phase 1 flow

1. App launches.
2. Encrypted refresh token, if present, is loaded from Android Keystore-backed vault.
3. Client rotates it through `/auth/refresh` and obtains a fresh access token.
4. No session → Login / Create Account screen.
5. Authenticated session → main MOSHI shell.
6. `Me` can edit display name and logout.
7. `Business` can enable/disable server-persisted Business Mode.

Debug Android API URL: `http://10.0.2.2:8000` for an Android emulator talking to a backend on the host machine.
