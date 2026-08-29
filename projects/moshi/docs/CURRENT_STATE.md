# MOSHI — CURRENT STATE

Authority: MASTER PLAN v1.1 + PRODUCT SPEC v1.0 + IDENTITY/AUTH v1.0
Status: ACTIVE / PHASE 1 IDENTITY-AUTH IMPLEMENTED (BUILD VERIFICATION PENDING)

## Foundation verified
- monorepo scaffold
- Android Jetpack Compose shell
- FastAPI backend
- Business Mode in the same MOSHI app
- AI Summary contract placeholder
- CI workflow

## Phase 1 implemented
- persistent `users` and `device_sessions` models
- username registration
- password login
- Argon2 password hashing
- short-lived JWT access token
- rotating opaque refresh token
- refresh-token hash storage
- logout/session revoke
- authenticated `GET /v1/me`
- editable display name
- server-persisted Business Mode toggle
- Android Login/Create Account UI
- Android startup session restore
- Android refresh token encrypted with Android Keystore AES/GCM
- debug-only cleartext networking; release expects HTTPS

## Verification
- backend tests: 6/6 PASS
- Python compile: PASS
- `git diff --check`: PASS
- Android build: PENDING because the current local execution environment has no Android SDK/Gradle installation. GitHub Actions remains the authoritative Android build path once the repository is created/pushed.

## Next implementation target
PHASE 2 — CHAT CORE

Acceptance slice:
1. conversation persistence
2. direct-conversation creation
3. message persistence
4. authenticated WebSocket session
5. realtime send/receive between two accounts
6. reconnect + message catch-up contract
7. delivered/read state contract
8. Android conversation list + chat screen
