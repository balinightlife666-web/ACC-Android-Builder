# MOSHI — CURRENT STATE

Authority: MASTER PLAN v1.1 + PRODUCT SPEC v1.0 + IDENTITY/AUTH v1.0 + CHAT CORE v1.0
Status: ACTIVE / PHASE 3 MESSAGING TOOLS — A+B BUILD VERIFIED

## Foundation verified
- monorepo scaffold
- Android Jetpack Compose shell
- FastAPI backend
- Business Mode in the same MOSHI app
- AI Summary contract placeholder
- GitHub CI workflow
- source hosted inside `balinightlife666-web/ACC-Android-Builder` under `projects/moshi/`

## Phase 1 verified
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

## Phase 3A verified — messaging actions
- reply-to message contract + Android UI
- edit own message
- soft-delete own message
- per-user emoji reactions
- cumulative read receipts
- realtime `message.updated`
- Android reply/reaction/edit/delete action controls

## Phase 3B build verified — offline resilience
- Room local conversation cache
- Room local message cache
- persistent outbox table
- optimistic local `queued` messages
- retry preserves the original `client_message_id`
- successful retry atomically replaces local optimistic message with server message
- manual `Retry now` control
- WebSocket reconnect loop while chat UI is active
- outbox automatically flushes when realtime reconnects
- cached conversation/message hydration before network sync

## Verification
- backend chat/auth/messaging suite: PASS
- Android Phase 3A complete `:app:assembleDebug`: PASS
- Android Phase 3B Room/outbox build: PASS
- Android Phase 3B reconnect/outbox final `:app:assembleDebug`: PASS
- MOSHI CI debug APK artifact: CREATED
- PR #53 remains stacked on the verified Phase 2 baseline

## Device QA still required
Build verification does not yet prove real-device network interruption behavior. Before release, test on Android hardware:
1. open existing chat online
2. disable network
3. confirm cached history remains visible
4. send one or more messages and confirm `queued`
5. close/reopen MOSHI and confirm queued messages persist
6. restore network
7. confirm reconnect sends each queued message exactly once
8. confirm sent/delivered/read state catches up

## Next implementation target
PHASE 3C — IMAGE / FILE MESSAGE CONTRACT

Priority slice:
1. attachment persistence model
2. authorized upload-init contract
3. attachment ownership + size/type validation
4. attachment metadata in message responses
5. Android image/file picker
6. upload progress + retry integration with outbox
7. voice-note contract
8. FCM background notification contract
