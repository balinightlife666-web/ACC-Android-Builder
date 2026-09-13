# AM STUDIO MUSIC DISTRIBUTION — CURRENT STATE

Date: 2026-09-09
Authority: MASTERPLAN v1.0
Phase: A — LEDGER-READY SANDBOX / SIGNED BASELINE + HTTPS HOST NEXT

## Source
- Repository: `balinightlife666-web/ACC-Android-Builder`
- Branch: `feat/am-studio-distribution-foundation`
- Pull request: #92 (DRAFT / UNMERGED)
- Android package: `com.amstudio.distribution`
- App version: `0.5.0-ledger-ready` / versionCode 5
- v0.5 development/debug CI run: `34380022664` — PASS
- v0.5 backend test run: `34380022681` — PASS
- Royalty/provider foundation validation run: `34379524546` — PASS

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
- Earnings reads `/v1/wallet` and `/v1/royalties/ledger`; no device-side authoritative balance calculation
- Multi-currency wallet display does not convert currencies into a fake total
- Provider/API secrets remain absent from APK

## Permanent APK signing authority
- Package identity lock: `com.amstudio.distribution`.
- Permanent key generated outside repository.
- Alias: `amstudio-release`.
- Key: RSA 4096 / SHA256withRSA / PKCS12.
- Permanent certificate SHA-256 fingerprint:
  `34:47:8F:B9:8A:55:73:45:EA:7F:22:1A:C1:98:33:4F:28:7F:9F:A1:94:BC:B6:94:75:27:1C:F8:5D:E9:56:23`
- Certificate serial: `961d392186486e7a`.
- Keystore/private password material is NOT stored in repository.
- Debug CI and user-facing signed release channels are separated.
- Automatic CI artifacts are DEBUG / NOT UPGRADE-SAFE.
- Manual Signed Release uses `:app:assembleRelease` and fails closed without permanent signing secrets.
- Required GitHub Actions secrets: `AM_STUDIO_KEYSTORE_B64`, `AM_STUDIO_KEYSTORE_PASSWORD`, `AM_STUDIO_KEY_ALIAS`, `AM_STUDIO_KEY_PASSWORD`.
- Signed releases emit APK SHA-256 + certificate receipt.
- First successful signed release becomes the permanent upgrade baseline.
- Signing authority: `SIGNING.md`.
- GitHub Actions secret provisioning: PENDING, therefore no APK is yet claimed UPGRADE-SAFE.

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

## Provider boundary
- First technical target: LabelGrid Engine API
- Adapter is SERVER-ONLY; provider token cannot enter Android client
- Sandbox/production base URL separation retained
- Adapter includes current catalog/distribution/QC/delivery/statement/royalty surfaces needed by the masterplan
- Track presigned upload URL now requires validated filename
- Delivery-status endpoint supported
- Canonical DSP destination mapper consumes provider `/distro-outlets` dynamically
- Spotify / Apple Music / TikTok / YouTube Music / Instagram+Facebook / Amazon Music / Deezer / TIDAL canonical mappings fail closed on missing or ambiguous provider outlets
- Provider IDs are NOT hard-coded into canonical releases
- Provider registry remains fail-closed without credentials
- Commercial status: NOT CONTRACTED / NO SANDBOX TOKEN
- LabelGrid sandbox delivery evidence: NOT TESTED

## Royalty ledger foundation
- Append-only journal implemented and persisted in sandbox state
- Monetary values use signed integer `amountMinor`; floating-point authoritative money is rejected
- Currency is explicit 3-letter code
- Buckets: `PENDING`, `AVAILABLE`, `HELD`, `PAID`
- Raw provider statement lines ingest into PENDING
- Provider + statement + line reference forms an idempotency identity to prevent duplicate statement rows
- Reconciliation moves value append-only from PENDING -> AVAILABLE using paired debit/credit entries
- Wallet is derived from journal entries; old entries are never edited into a new balance
- `/v1/royalties/ledger` IMPLEMENTED
- `/v1/wallet` IMPLEMENTED
- `/v1/admin/royalties/ingest` IMPLEMENTED for sandbox/admin
- `/v1/admin/royalties/reconcile` IMPLEMENTED for sandbox/admin
- No AM STUDIO commission percentage or artist split is hard-coded into ledger foundation
- Fee/split/tax/payout logic remains a separate future engine that must append explicit entries

## Runtime evidence status
- Android v0.5 development/debug CI compile/package: PASS
- Backend/provider/ledger automated tests: PASS
- Permanent signed-release build: BLOCKED only by Actions secret provisioning
- Physical signed Android baseline install: PENDING
- Launcher/icon visual QC on signed channel: PENDING
- Audio picker real-device QC: PENDING
- Artwork picker real-device QC: PENDING
- Local draft persistence real-device QC: PENDING
- Account HTTPS connection real-device QC: PENDING
- Wallet/ledger real-device backend refresh: PENDING
- Android -> AM STUDIO backend real file upload E2E: NOT TESTED because no public HTTPS sandbox host is provisioned yet
- LabelGrid sandbox delivery: NOT TESTED because commercial/API onboarding and sandbox token are not active

## Explicitly NOT production-ready
- GitHub Actions permanent signing secrets / first signed upgrade baseline
- Public HTTPS AM STUDIO sandbox host
- Production identity/login/token refresh
- Production DB and object storage
- KYC/KYB
- Active white-label provider credentials
- Final canonical provider entity/payload mapping from live sandbox schemas
- Real DSP delivery
- ISRC/UPC production workflow
- Production statement ingestion automation
- Split/commission/tax engine
- Payout provider
- Fraud/takedown/admin production operations

## Next implementation order
1. Provision the four permanent Android signing values as GitHub Actions secrets and run the FIRST v0.5 Signed Release.
2. Verify emitted signing fingerprint exactly equals the permanent fingerprint above.
3. Install that signed baseline once; uninstall old debug APK only if Android requires migration.
4. Provision a public HTTPS sandbox host and deploy backend with provider disabled.
5. Test Account -> `/v1/me`, `/v1/wallet`, `/v1/royalties/ledger` from physical Android.
6. Run Android -> backend real release upload E2E with WAV/FLAC + artwork.
7. Replace DEV persistence/auth/storage with production adapters while preserving contracts.
8. Complete LabelGrid commercial sandbox onboarding + token/IP allowlist.
9. Resolve live provider artist/label/track/release schemas and produce canonical -> provider payload mapping without guessed fields.
10. Run provider sandbox assets -> QC -> distribution -> delivery-status evidence.
11. KYC/admin moderation -> automated royalty ingestion -> splits/fees/tax -> payout -> controlled beta -> multi-provider -> direct DSP/DDEX evolution.

## Safety lock
Do not call a release LIVE, monetized, royalty-bearing, production-distributed, payout-eligible, or UPGRADE-SAFE unless corresponding provider/DSP/ledger/signing evidence exists.

Do not put provider API secrets or Android signing private keys into the APK or repository. Production provider integrations live behind AM STUDIO backend adapters; signing keys live only in secure secret storage/offline backup.
