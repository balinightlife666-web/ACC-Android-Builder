# AM STUDIO MUSIC DISTRIBUTION — CURRENT STATE

Date: 2026-09-09
Authority: MASTERPLAN v1.0
Phase: A — BACKEND-READY SANDBOX / PHYSICAL RUNTIME QC + PROVIDER ONBOARDING NEXT

## Source
- Repository: `balinightlife666-web/ACC-Android-Builder`
- Branch: `feat/am-studio-distribution-foundation`
- Pull request: #92 (DRAFT / UNMERGED)
- Android package: `com.amstudio.distribution`
- App version: `0.3.0-backend-ready` / versionCode 3
- Verified APK source commit: `020fd8d301c2e88a85a7b92d827a177efec72e08`
- Verified APK CI run: `34347864249` — PASS
- Verified APK SHA-256: `1babe0385c1e50c7a3b14a0080e9358561fc1845abcb989e1ccc9ee3d392844b`
- Latest backend/provider/deployment test run: `34348382833` — PASS

## Android implemented and CI-verified
- Dedicated project isolated at `tools/am-studio-distribution`
- Provider-neutral canonical release model and lifecycle
- Local canonical release draft persistence
- Home / Releases / New Release / Earnings / Account screens
- Real Android document picker for master audio and cover artwork
- Persistable read URI permission for selected files
- Local media inspection: audio duration, name, MIME, size; artwork dimensions, MIME, size
- Release metadata: title, artist, label, genre, release date, songwriter, composer, copyright owner, explicit flag
- Rights declaration gate
- DSP destination selection
- Sandbox preflight requires WAV/FLAC, cover 1:1 >= 3000x3000, metadata, rights, and destinations
- Official AM STUDIO vector app mark applied to header and launcher
- HTTPS-only network policy; cleartext remains blocked
- AM STUDIO API client foundation
- Content-URI SHA-256 hashing
- Backend operations supported by client layer: current user, create/patch release, upload session, streamed PUT asset upload, upload completion, preflight, submit review
- Backend/provider credentials are NOT hard-coded into APK

## Backend implemented and test-verified
- Isolated Node 22 backend at `tools/am-studio-distribution/backend`
- Canonical server-side release lifecycle and edit-state lock
- Bearer-token auth boundary in DEV_SANDBOX
- Durable JSON-file persistence adapter with atomic replacement
- Release create/list/read/patch operations
- AUDIO_MASTER / ARTWORK upload-session registry
- Actual request-byte media storage adapter
- Server-computed SHA-256 verification; checksum mismatch fails closed
- Server-side release preflight using VERIFIED assets
- READY_FOR_REVIEW -> IN_REVIEW transition gate
- Audit event stream for sensitive state changes
- Stable coded error boundary
- Automated tests for lifecycle, edit locks, preflight, auth, persistence restart, byte hashing, checksum rejection and provider isolation — PASS

## Deployment foundation
- Sandbox Dockerfile implemented
- Configurable HOST/PORT binding
- Persistent state/media paths defined for mounted volume
- Android remains HTTPS-only; no cleartext workaround allowed
- Deployment contract documented in `DEPLOYMENT.md`
- Real public HTTPS sandbox host: NOT YET PROVISIONED
- Current JSON/local-filesystem adapters remain DEV/SANDBOX only, not production persistence

## Provider strategy
- First technical target: LabelGrid Engine API
- `LabelGridAdapter` implemented as SERVER-ONLY adapter foundation
- Sandbox/production base URL separation
- Server-side bearer token only
- Foundation operations: provider user, distro outlets, release/track create pass-through, track upload URL, validate, quality report, distribute, takedown, statements, analytics summary
- Provider registry fails closed when no provider/token is configured
- Commercial status: NOT CONTRACTED / NO SANDBOX TOKEN YET
- Publicly listed API plan starts at USD 139/month billed yearly; API/sandbox access requires paid API plan
- Sandbox may require IP allowlisting

## Runtime evidence status
- Android v0.3 CI compile/package: PASS
- Backend/provider automated tests: PASS
- Physical Android install v0.3: PENDING
- Launcher/icon visual QC: PENDING
- Audio picker runtime QC: PENDING
- Artwork picker/runtime dimension QC: PENDING
- Draft persistence after app restart: PENDING
- Local preflight PASS/FAIL on real files: PENDING
- Backend-connected Android end-to-end upload: NOT TESTED (no deployed HTTPS AM STUDIO API endpoint yet)
- LabelGrid sandbox end-to-end delivery: NOT TESTED (commercial/API onboarding required)

## Explicitly NOT production-ready
- Production identity provider / user login / token refresh
- Production database (current durable adapter is DEV JSON file)
- Production object storage / signed uploads (current adapter is DEV local filesystem)
- Real KYC/KYB
- Active LabelGrid/other provider contract and credentials
- Canonical -> provider metadata/entity mapping completion
- Real DSP delivery
- ISRC/UPC issuance/import workflow
- Royalty statement ingestion and reconciliation
- Append-only production ledger and split engine
- Payment/payout provider
- Copyright/takedown operations backend
- Fraud/artificial-streaming controls
- Admin console
- Production legal/commercial launch

## Next implementation order
1. Physical Android v0.3 runtime QC.
2. Provision a real HTTPS sandbox host and deploy current container with provider disabled.
3. Run Android -> AM STUDIO backend end-to-end upload against sandbox host.
4. Replace DEV auth/JSON/local media adapters with production identity + database + object storage adapters while preserving interfaces.
5. Commercial onboarding for LabelGrid Engine API + sandbox token/IP allowlist.
6. Implement canonical AM STUDIO -> LabelGrid artist/label/track/release/DSP mapping.
7. End-to-end LabelGrid sandbox release: assets -> validation/QC -> review -> distribution evidence.
8. KYC/rights/admin moderation.
9. Royalty raw-ingest + normalized append-only ledger + splits.
10. Payout workflow.
11. Controlled beta, multi-provider routing, then direct DSP/DDEX evolution.

## Safety lock
Do not call a release LIVE, monetized, royalty-bearing, production-distributed, or payout-eligible unless corresponding provider/DSP/ledger evidence exists.

Do not put provider API secrets into the APK. All production provider integrations live behind AM STUDIO backend adapters.
