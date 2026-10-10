# AM STUDIO DISTRIBUTION — API CONTRACT v0.3

Status: BACKEND-READY SANDBOX + LEDGER FOUNDATION CONTRACT
Base path target: `/v1`
Rule: Android only calls AM STUDIO services. Provider credentials and DSP-specific payloads never enter the APK.

## Identity

### POST /v1/auth/session
Target production contract for creating/refreshing an authenticated AM STUDIO session.
Current DEV_SANDBOX implementation uses a bearer-token auth boundary only; production identity/token refresh is not yet implemented.

### GET /v1/me
Returns user, organization/label memberships, KYC/KYB state, roles, plan and payout eligibility.

## Catalog

### POST /v1/releases
Create canonical release draft.
Response includes AM STUDIO `releaseId` only.

### GET /v1/releases
List canonical releases with lifecycle state.

### GET /v1/releases/{releaseId}
Read release, tracks, contributors, rights, assets, destinations and deliveries.

### PATCH /v1/releases/{releaseId}
Update only fields allowed by current release state. Server rejects illegal lifecycle edits.

## Media

### POST /v1/uploads
Request upload session for AUDIO_MASTER or ARTWORK.
Request contains file name, size, MIME and SHA-256 checksum.
Response contains `assetId`, upload method/target and expiry.

### PUT /v1/uploads/{assetId}/content
Streams actual asset bytes to AM STUDIO storage adapter.
Server computes SHA-256 from received bytes and rejects size/checksum mismatch.
Current sandbox storage is local filesystem; production target is signed object storage behind the same canonical flow.

### POST /v1/uploads/{assetId}/complete
Completes technical asset metadata only after server byte verification succeeds.
Audio currently supplies duration; artwork supplies width/height. Asset becomes VERIFIED only after required technical metadata passes.

## Preflight / moderation

### POST /v1/releases/{releaseId}/preflight
Returns structured checks:
- audio
- artwork
- metadata
- contributors
- composition/publishing
- rights
- territories
- schedule
- identifiers
- duplicates

### POST /v1/releases/{releaseId}/submit-review
Transitions READY_FOR_REVIEW -> IN_REVIEW after server validation.

### GET /v1/releases/{releaseId}/qc
Target endpoint for QC checks and repair instructions.

## Distribution

### POST /v1/releases/{releaseId}/distribute
Target endpoint: creates durable distribution job only after approval and provider configuration.
Provider API token remains server-side.

### GET /v1/releases/{releaseId}/deliveries
Target endpoint: destination-level delivery states. Provider IDs may be returned only as opaque mappings for admin/debug roles.

### POST /v1/releases/{releaseId}/metadata-update
Target controlled post-delivery update request.

### POST /v1/releases/{releaseId}/takedown
Target takedown request with reason/evidence and audit event.

## Provider adapter internal boundary

Not exposed to Android. Distribution orchestrator calls adapters through canonical commands:
- validateRelease
- createRelease
- mapAssets
- submitRelease
- fetchDeliveryStatus
- requestMetadataUpdate
- requestTakedown
- fetchAnalytics
- fetchRoyaltyStatements

First technical adapter target: LabelGrid Engine API. The adapter is fail-closed without a configured server-side token. LabelGrid remains replaceable; it never becomes the canonical AM STUDIO data model.

Provider outlet IDs are never hard-coded into the canonical release. AM STUDIO maps canonical destination names against the provider's live `/distro-outlets` response and fails closed if a destination is missing or ambiguous.

## Analytics

### GET /v1/analytics/summary
Canonical normalized metrics by date, release, track, territory and destination.

## Royalties

Money rule: authoritative ledger amounts are integer `amountMinor` values in an explicit 3-letter currency. Floating-point monetary values are rejected.

### GET /v1/royalties/statements
Target statement summaries after ingestion/reconciliation.

### GET /v1/royalties/ledger
IMPLEMENTED in sandbox. Returns the authenticated owner's append-only journal entries.
Current buckets:
- `PENDING`
- `AVAILABLE`
- `HELD`
- `PAID`

Raw provider statement rows enter `PENDING`. Existing rows are never edited in place.

### GET /v1/wallet
IMPLEMENTED in sandbox. Returns bucket totals per currency derived from append-only ledger entries. Android must not calculate authoritative balances locally.

### POST /v1/admin/royalties/ingest
IMPLEMENTED sandbox/admin boundary. Adds one normalized provider statement line as `ROYALTY_RAW -> PENDING`.
Idempotency key is derived from provider + statement ID + provider line reference, preventing duplicate ingestion of the same statement row.

### POST /v1/admin/royalties/reconcile
IMPLEMENTED sandbox/admin boundary. Moves an amount append-only from `PENDING` to `AVAILABLE` using paired debit/credit journal entries and an idempotent transfer identity.

No AM STUDIO commission percentage, artist split percentage, tax deduction, provider fee, or payout fee is hard-coded into this ledger foundation. Those are separate configurable engines that must append explicit journal entries later.

## Payouts

### POST /v1/payouts
Creates payout request only when KYC/tax/payment/threshold gates pass.

### GET /v1/payouts
Payout history and state.

## Idempotency

Every mutating production endpoint supports an idempotency key. Retrying a timed-out create/submit/payout request must not duplicate business actions.
Royalty raw ingestion and reconciliation already enforce idempotency in the sandbox foundation.

## Audit

Every sensitive state change writes an immutable AuditEvent with actor, action, entity, prior state, next state, request/job ID and timestamp.

## Error shape

```json
{
  "error": {
    "code": "RELEASE_PREFLIGHT_FAILED",
    "message": "Release has blocking checks",
    "requestId": "req_...",
    "issues": [
      {"field":"tracks[0].rights","code":"RIGHTS_DECLARATION_REQUIRED"}
    ]
  }
}
```

Clients use stable `code` values, never parse human-readable messages for logic.
