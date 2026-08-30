# MOSHI — CURRENT STATE

Authority: MASTER PLAN v1.1 + PRODUCT SPEC + verified GitHub CI receipts
Status: ACTIVE / INTERNAL ALPHA v0.1 PREPARATION

## Integrated verified baseline
The verified MOSHI feature stack through Phase 5C is now merged into repository `main` under `projects/moshi/`.

### Identity & chat
- username accounts, Argon2 passwords, JWT access + rotating refresh sessions
- Android Keystore refresh-token vault
- direct realtime chat over authenticated WebSocket
- persistent messages, idempotent send, sent/delivered/read states
- reply, reactions, edit, soft-delete
- Room cache, persistent outbox, reconnect + automatic retry

### Media
- photo/file attachments
- authenticated upload/download
- restart-safe attachment outbox
- streaming upload
- secure FileProvider open
- native AAC/M4A voice notes

### Groups
- group creation
- admin / moderator / member roles
- member add/remove and role management
- last-admin protection
- group messaging reuses realtime/media/offline pipeline

### Notifications
- per-session FCM token registry
- realtime-first delivery with push fallback
- Android notification channel/service/permission
- FCM HTTP v1 backend abstraction
- real Firebase push remains deployment/device-QA BLOCKED until Firebase is provisioned

### Business & commerce
- Business Mode in the same MOSHI APK
- Business Profile
- product + service catalog CRUD
- price, stock, availability and catalog photos
- catalog card snapshots shared into chat
- visual Ask / Order actions
- persistent Order Drafts
- order lifecycle: draft → awaiting_confirmation → confirmed → processing → completed; cancelled before completion
- stock decremented once on confirmation and restored when applicable on cancellation
- quick replies
- private per-business customer labels
- Orders & CRM Android panel

## Latest feature verification
Phase 5C verified by MOSHI CI run #138:
- backend pytest PASS
- Android `assembleDebug` PASS
- `MOSHI-debug-apk` artifact PASS
- verified feature head `36405120f6a73a70ac8e0a4287d0c97eeec12da6`
- artifact SHA256 `324a6b261026c6c7f2aaa2e8c4080684a8a1f526359e612e0e32fdbd559dad4c`

The complete verified stack was subsequently consolidated into `main` with merge commits preserving branch ancestry. Main after Phase 5C integration: `2f65880af70177b40189f837edde9ad6d4d42f86`.

## Internal Alpha v0.1 preparation
Branch: `feat/moshi-alpha-v0.1`

Alpha work adds:
- PostgreSQL driver
- hardened alpha/production config checks
- database readiness endpoint `/ready`
- Docker backend image on port 8010
- PostgreSQL 16 compose stack with persistent DB/media volumes
- phone-only `alpha-smoke` launcher for temporary SQLite smoke testing
- Cloudflare Quick Tunnel launcher
- build-configurable Android API endpoint
- Android version `0.4.0-alpha.1`, versionCode 3
- manual `MOSHI Alpha APK` GitHub workflow requiring an HTTPS API endpoint
- optional stable signing through repository Actions secrets
- two-device physical QA checklist
- CI validation for pytest + compose config + Docker image + Android build

## Alpha boundaries
Do not claim these as live until actually provisioned/tested:
- public HTTPS MOSHI backend
- production PostgreSQL service
- real Firebase push
- stable production/alpha signing key
- physical two-device pass

For Internal Alpha, local persistent upload volume is temporary. Before public beta, move media to object storage and add real DB migrations/backups/monitoring.

## Current execution target
1. make Alpha branch CI green
2. merge Alpha tooling to main
3. start an actual backend endpoint (proper PostgreSQL preferred; phone `alpha-smoke` acceptable for first device smoke only)
4. run `MOSHI Alpha APK` with that HTTPS endpoint
5. install the resulting APK on two Android devices
6. execute `docs/ALPHA_QA.md`
7. after the communication/business baseline is stable, proceed to Phase 6 — MOSHI AI Catch Me Up / Summarize Unread
