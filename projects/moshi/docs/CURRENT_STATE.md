# MOSHI — CURRENT STATE

Authority: MASTER PLAN v1.1 + PRODUCT SPEC v1.0 + IDENTITY/AUTH v1.0 + CHAT CORE v1.0
Status: ACTIVE / PHASE 2 CHAT CORE VERIFIED

## Foundation verified
- monorepo scaffold
- Android Jetpack Compose shell
- FastAPI backend
- Business Mode in the same MOSHI app
- AI Summary contract placeholder
- GitHub CI workflow
- source hosted inside `balinightlife666-web/ACC-Android-Builder` under `projects/moshi/`

## Phase 1 implemented
- persistent users + device sessions
- username registration/login
- Argon2 password hashing
- JWT access token + rotating refresh token
- session revoke/logout
- Android auth UI + encrypted refresh-token vault
- profile + server-persisted Business Mode

## Phase 2 verified
- persistent direct conversations
- user search
- message persistence
- sender-side idempotency via `client_message_id`
- authenticated realtime WebSocket
- realtime `message.created`
- realtime `message.read`
- sent/delivered/read receipt contract
- message history/catch-up endpoint
- conversation unread counts
- Android conversation list
- Android user search + start direct chat
- Android text chat screen
- Android WebSocket listener using OkHttp

## Verification
- backend chat/auth suite: PASS (8/8 Phase 2 baseline)
- Android complete Phase 2 `:app:assembleDebug`: PASS
- MOSHI CI debug APK artifact: CREATED
- duplicate CI runs fixed using path filters + concurrency/cancel-in-progress

## Next implementation target
PHASE 3 — MEDIA & MESSAGING TOOLS

Priority slice:
1. local Room cache + reliable outbox/retry
2. reply
3. reactions
4. edit/delete
5. image/file upload contract
6. voice-note contract
7. FCM background notification contract
