# AM STUDIO MUSIC DISTRIBUTION — CURRENT STATE

Date: 2026-09-09
Authority: MASTERPLAN v1.0
Phase: A — SANDBOX CONNECT READY / HTTPS HOST + PHYSICAL E2E NEXT

## Source
- Repository: `balinightlife666-web/ACC-Android-Builder`
- Branch: `feat/am-studio-distribution-foundation`
- Pull request: #92 (DRAFT / UNMERGED)
- Android package: `com.amstudio.distribution`
- App version: `0.4.0-sandbox-connect` / versionCode 4
- Verified APK source commit: `c8de2fdb40a9cee49d3b36d4932d02f1eeff6f7d`
- Verified APK CI run: `34358916879` — PASS
- Verified APK SHA-256: `95e8fa9d1afb71d5bef8b0647bdcaab778201ce60146d78d494a96791992a019`
- Backend test run for same checkpoint: `34358916868` — PASS

## Android implemented and CI-verified
- Dedicated package `com.amstudio.distribution`
- AM STUDIO branding / launcher icon
- Home / Releases / New Release / Earnings / Account
- Real WAV/FLAC and artwork document picker
- Persistable URI permission
- Audio metadata + artwork dimension inspection
- Local preflight and rights gate
- HTTPS-only backend networking; cleartext disabled
- Account sandbox connection screen
- Persisted HTTPS endpoint
- Session token kept in memory only, not persisted to disk
- Authenticated `/v1/me` connection test
- Exact file fingerprint from bytes: SHA-256 + actual byte count
- Backend release orchestrator: create canonical release -> upload audio bytes -> upload artwork bytes -> patch asset IDs -> server preflight -> submit review
- Canonical backend release ID persisted separately from local draft ID
- Provider/API secrets remain absent from APK

## Backend implemented and test-verified
- Node 22 backend
- Bearer auth boundary
- Durable atomic JSON persistence adapter
- Local sandbox media storage adapter
- Server-computed SHA-256 + exact-size verification
- Release create/list/read/patch
- Upload sessions + raw PUT bytes + completion
- Server preflight and lifecycle gates
- Audit trail
- Docker sandbox scaffold
- LabelGrid server-only adapter foundation
- Provider registry fail-closed without credentials

## Runtime evidence status
- Android v0.4 CI compile/package: PASS
- Backend tests: PASS
- Physical Android install v0.4: PENDING
- Launcher/icon visual QC: PENDING
- Audio picker real-device QC: PENDING
- Artwork picker real-device QC: PENDING
- Local draft persistence real-device QC: PENDING
- Account HTTPS connection real-device QC: PENDING
- Android -> AM STUDIO backend real file upload E2E: NOT TESTED because no public HTTPS sandbox host is provisioned yet
- LabelGrid sandbox delivery: NOT TESTED because commercial/API onboarding and sandbox token are not active

## Provider strategy
- First technical target: LabelGrid Engine API
- Adapter is SERVER-ONLY
- Sandbox/production separation retained
- Commercial status: NOT CONTRACTED / NO SANDBOX TOKEN
- Never call distribution LIVE without provider evidence

## Explicitly NOT production-ready
- Public HTTPS AM STUDIO sandbox host
- Production identity/login/token refresh
- Production DB and object storage
- KYC/KYB
- Active white-label provider credentials
- Canonical provider mapping completion
- Real DSP delivery
- ISRC/UPC production workflow
- Royalty statement ingestion/reconciliation
- Append-only royalty ledger/splits
- Payout provider
- Fraud/takedown/admin production operations

## Next implementation order
1. Install and physical-QC v0.4 APK.
2. Provision a public HTTPS sandbox host and deploy current Docker backend with provider disabled.
3. Test Account -> `/v1/me` from Android.
4. Run Android -> backend real release upload E2E with WAV/FLAC + artwork.
5. Replace DEV persistence/auth/storage with production adapters while keeping contracts stable.
6. Complete LabelGrid commercial sandbox onboarding and token/IP allowlist.
7. Canonical AM STUDIO -> LabelGrid mapping and provider sandbox distribution evidence.
8. KYC/admin moderation.
9. Royalty ingestion -> reconciliation -> append-only ledger -> splits.
10. Payout workflow -> controlled beta -> multi-provider -> direct DSP/DDEX evolution.

## Safety lock
Do not call a release LIVE, monetized, royalty-bearing, production-distributed, or payout-eligible unless corresponding provider/DSP/ledger evidence exists.

Do not put provider API secrets into the APK. All production provider integrations live behind AM STUDIO backend adapters.
