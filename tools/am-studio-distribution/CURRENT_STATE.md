# AM STUDIO MUSIC DISTRIBUTION — CURRENT STATE

Date: 2026-09-09
Authority: MASTERPLAN v1.0
Phase: A — SANDBOX CONNECT READY / PERMANENT SIGNING MIGRATION + HTTPS HOST NEXT

## Source
- Repository: `balinightlife666-web/ACC-Android-Builder`
- Branch: `feat/am-studio-distribution-foundation`
- Pull request: #92 (DRAFT / UNMERGED)
- Android package: `com.amstudio.distribution`
- App version: `0.4.0-sandbox-connect` / versionCode 4
- Verified v0.4 debug APK source commit: `c8de2fdb40a9cee49d3b36d4932d02f1eeff6f7d`
- Verified v0.4 debug APK CI run: `34358916879` — PASS
- Verified v0.4 debug APK SHA-256: `95e8fa9d1afb71d5bef8b0647bdcaab778201ce60146d78d494a96791992a019`
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

## APK signing migration
- Package identity remains locked: `com.amstudio.distribution`.
- Debug CI and user-facing signed release channels are now separated.
- Automatic branch/PR CI creates artifacts explicitly marked DEBUG / NOT UPGRADE-SAFE.
- Manual Signed Release job uses `:app:assembleRelease` and fails closed unless permanent signing secrets exist.
- Release Gradle config only signs with the permanent AM STUDIO key supplied through environment variables.
- Required GitHub Actions secrets: `AM_STUDIO_KEYSTORE_B64`, `AM_STUDIO_KEYSTORE_PASSWORD`, `AM_STUDIO_KEY_ALIAS`, `AM_STUDIO_KEY_PASSWORD`.
- Permanent keystore/private key is forbidden from repository source.
- Signed releases emit APK SHA-256 + certificate receipt.
- v0.4 and earlier development/debug APKs may require uninstall when moving onto the permanent signed channel.
- The FIRST successful permanent signed APK becomes the upgrade-signing baseline; all later user-facing APKs must use exactly the same certificate.
- Signing procedure authority: `SIGNING.md`.
- Permanent keystore secrets: NOT YET PROVISIONED, therefore no build is yet claimed UPGRADE-SAFE.

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
- Android v0.4 debug CI compile/package: PASS
- Backend tests: PASS
- Permanent signed-release build: BLOCKED until signing secrets are provisioned
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
- Permanent release-signing secrets/first signed baseline
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
1. Provision permanent AM STUDIO Android signing key as GitHub Actions secrets and produce the first SIGNED upgrade-channel APK.
2. Install that signed baseline once (uninstall old debug APK if Android requires it); after this point normal upgrades must preserve app data.
3. Provision a public HTTPS sandbox host and deploy current Docker backend with provider disabled.
4. Test Account -> `/v1/me` from Android.
5. Run Android -> backend real release upload E2E with WAV/FLAC + artwork.
6. Replace DEV persistence/auth/storage with production adapters while keeping contracts stable.
7. Complete LabelGrid commercial sandbox onboarding and token/IP allowlist.
8. Canonical AM STUDIO -> LabelGrid mapping and provider sandbox distribution evidence.
9. KYC/admin moderation.
10. Royalty ingestion -> reconciliation -> append-only ledger -> splits -> payout -> controlled beta -> multi-provider -> direct DSP/DDEX evolution.

## Safety lock
Do not call a release LIVE, monetized, royalty-bearing, production-distributed, payout-eligible, or UPGRADE-SAFE unless corresponding provider/DSP/ledger/signing evidence exists.

Do not put provider API secrets or Android signing private keys into the APK or repository. Production provider integrations live behind AM STUDIO backend adapters; signing keys live only in secure secret storage/offline backup.
