# AM STUDIO DISTRIBUTION — API CONTRACT v0.1

Status: FOUNDATION CONTRACT
Base path target: `/v1`
Rule: Android only calls AM STUDIO services. Provider credentials and DSP-specific payloads never enter the APK.

## Identity

### POST /v1/auth/session
Creates/refreshes an authenticated AM STUDIO session.

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
Request short-lived upload session for AUDIO_MASTER or ARTWORK.
Request contains file name, size, MIME and checksum.
Response contains `assetId`, upload target and expiry.

### POST /v1/uploads/{assetId}/complete
Server verifies object, checksum and media policy. Asset remains non-distributable until verification passes.

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
Returns QC checks and repair instructions.

## Distribution

### POST /v1/releases/{releaseId}/distribute
Creates durable distribution job after approval. Response: `jobId`, canonical status.

### GET /v1/releases/{releaseId}/deliveries
Returns destination-level delivery states. Provider IDs may be returned only as opaque mappings for admin/debug roles.

### POST /v1/releases/{releaseId}/metadata-update
Creates controlled post-delivery update request.

### POST /v1/releases/{releaseId}/takedown
Creates takedown request with reason/evidence and audit event.

## Analytics

### GET /v1/analytics/summary
Canonical normalized metrics by date, release, track, territory and destination.

## Royalties

### GET /v1/royalties/statements
Statement summaries after ingestion/reconciliation.

### GET /v1/royalties/ledger
Append-only user-visible ledger. Never calculate authoritative balances on-device.

### GET /v1/wallet
Returns verified available, pending, held and paid balances.

## Payouts

### POST /v1/payouts
Creates payout request only when KYC/tax/payment/threshold gates pass.

### GET /v1/payouts
Payout history and state.

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

## Idempotency

Every mutating production endpoint supports an idempotency key. Retrying a timed-out create/submit/payout request must not duplicate business actions.

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
