# MOSHI — CURRENT STATE

Authority: MASTER PLAN v1.1 + PRODUCT SPEC v1.0 + IDENTITY/AUTH v1.0 + CHAT CORE v1.0
Status: ACTIVE / PHASE 4B GROUP CHAT CORE — BUILD VERIFIED

## Foundation verified
- monorepo scaffold
- Android Jetpack Compose shell
- FastAPI backend
- Business Mode in the same MOSHI app
- AI Summary contract placeholder
- GitHub CI workflow
- source hosted inside `balinightlife666-web/ACC-Android-Builder` under `projects/moshi/`

## Phase 1 verified — identity/auth
- persistent users + device sessions
- username registration/login
- Argon2 password hashing
- JWT access token + rotating refresh token
- session revoke/logout
- Android auth UI + encrypted refresh-token vault
- profile + server-persisted Business Mode

## Phase 2 verified — direct chat core
- persistent direct conversations
- user search
- message persistence
- sender-side idempotency via `client_message_id`
- authenticated realtime WebSocket
- realtime `message.created` + `message.read`
- sent/delivered/read receipt contract
- message history/catch-up endpoint
- conversation unread counts
- Android conversation list + direct chat UI

## Phase 3A verified — messaging actions
- reply
- edit own message
- soft-delete own message
- per-user emoji reactions
- cumulative read receipts
- realtime `message.updated`

## Phase 3B verified — offline resilience
- Room conversation/message cache
- persistent outbox
- optimistic queued messages
- retry preserves original `client_message_id`
- automatic WebSocket reconnect + outbox flush
- cached hydration before network sync

## Phase 3C verified — attachments
- image/file upload-init and ownership authorization
- attachment metadata in messages
- Android system document picker
- persistent attachment retry across restart
- streaming upload from persisted URI
- authenticated download
- secure open through FileProvider
- 20 MB validation boundary

## Phase 3D verified — voice notes
- Android native microphone recording
- AAC/M4A `audio/mp4`
- 5 minute recorder cap
- app-private queued recordings
- voice notes reuse attachment outbox/retry/download pipeline
- Android voice-note bubble + Play action
- CI run #102 PASS

## Phase 4A verified — notification plumbing
- per-session FCM token registry
- token ownership lifecycle and cleanup
- realtime-first message delivery
- FCM fallback only when no WebSocket receives `message.created`
- privacy-first push payload: generic `MOSHI / New message`
- Android Firebase Messaging service + notification channel
- Android 13+ notification permission
- backend FCM HTTP v1 sender through deployment credentials
- no Firebase service-account credential committed to source
- CI run #104 PASS

### FCM deployment boundary
The notification code is build verified but real push is not claimed LIVE until a MOSHI Firebase project is provisioned, Android Firebase config is installed, backend Google credentials + `MOSHI_FCM_PROJECT_ID` are injected, and physical-device background/process-death QA passes.

## Phase 4B verified — group chat core
- migration-safe `group_profiles` and `group_member_roles` tables
- create group with optional initial members
- admin / moderator / member roles
- admin group profile update contract
- admin/moderator member management
- admin-only role changes
- last-admin protection
- group metadata integrated into normal conversation list
- group chats reuse existing realtime messages, receipts, reply/edit/delete, reactions, attachments, voice notes, offline outbox and push fallback
- Android New Group flow in Chats
- Android group title/member-count display
- Android Members panel
- add/remove member UI
- role-management UI
- group sender labels resolved from current member list

## Phase 4B verification
- backend integration tests: PASS
- Android `:app:assembleDebug --stacktrace`: PASS
- MOSHI CI run #110: PASS
- debug artifact: `MOSHI-debug-apk`
- artifact id: `9717445670`
- artifact size: `11,502,448 bytes`
- artifact digest: `sha256:c8f5b0e786fde9ac9f4c5c3c872a4adb40ccdc4080c97b57fc76d455f44438f9`
- verified code head: `09cd80695dbca6e8003ed96784a28b790d6c08f1`
- PR #61 stacked on verified Phase 4A baseline

## Device QA still required
Build verification does not replace physical Android testing. Before release, validate at minimum:
1. two or more devices create/join a group
2. realtime group messages arrive once
3. sender labels and unread counts remain correct
4. admin/moderator/member permissions behave correctly
5. removed member immediately loses group access
6. queued group text/media/voice survives restart and resends once
7. FCM group notification path after Firebase activation

## Next implementation target
PHASE 5A — BUSINESS CATALOG CORE

Priority slice:
1. business profile persistence
2. product/service catalog CRUD
3. photos, price, description, availability/stock fields
4. catalog visible from business profile
5. share catalog item as a chat card
6. customer inquiry / order draft entrypoint
7. quick replies + customer labels after catalog contract is stable

MOSHI remains one APK: personal use and Business Mode stay inside the same application.
