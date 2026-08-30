# MOSHI — SECURITY BASELINE v1.0

## Phase 0/1 rules
- TLS for all production traffic
- passwords never stored in plaintext
- short-lived access tokens + rotating/revocable refresh sessions
- device session list and remote logout
- rate limiting for auth and messaging endpoints
- media access via scoped authorization
- secrets never committed to repository
- structured audit events for sensitive account actions

## Encryption claim rule
MOSHI must not claim End-to-End Encryption until an established, reviewed protocol is actually implemented and tested. Do not invent a custom cryptographic protocol.

## Business data
Private customer notes are never visible to customers. Staff permissions will be explicit when multi-user business profiles are added.
