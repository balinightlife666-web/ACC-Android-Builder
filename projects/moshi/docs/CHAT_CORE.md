# MOSHI — CHAT CORE v1.0

Status: IMPLEMENTED / PHASE 2

## Scope
Phase 2 establishes persistent direct messaging before media, groups, or AI summarization are enabled.

## Backend contract
- `GET /v1/users/search?q=` — authenticated user discovery
- `POST /v1/conversations/direct` — idempotent 1:1 conversation creation
- `GET /v1/conversations` — conversation list ordered by activity
- `GET /v1/conversations/{id}/messages` — persisted message history/catch-up
- `POST /v1/conversations/{id}/messages` — idempotent text-message send using `client_message_id`
- `POST /v1/conversations/{id}/read` — read acknowledgement
- `WS /v1/ws?token=` — authenticated realtime event channel

## Delivery model
1. Client creates a unique `client_message_id`.
2. Backend persists the message before acknowledging success.
3. Duplicate retries with the same sender + client ID resolve to the same server message.
4. If recipient has an active WebSocket, `message.created` is pushed immediately and delivery receipt is recorded.
5. If recipient is offline, history/catch-up through REST records delivery when retrieved.
6. Opening/reading marks the incoming message read and emits `message.read` to the sender when connected.

## Message states
- `sent` — persisted by MOSHI server
- `delivered` — recipient device/socket has received or fetched it
- `read` — recipient explicitly marked it read

## Android slice
- conversation list
- unread counter
- username search
- direct conversation creation
- text message history
- text send
- realtime WebSocket listener
- sent/delivered/read display

## Not in Phase 2
- media upload
- voice notes
- edit/delete/reactions/reply/forward
- group chat
- push notifications / FCM
- offline Room database/outbox
- E2EE
- AI summary
