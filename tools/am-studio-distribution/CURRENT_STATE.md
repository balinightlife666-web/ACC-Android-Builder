# AM STUDIO MUSIC DISTRIBUTION — CURRENT STATE

Date: 2026-09-09
Authority: MASTERPLAN v1.0
Phase: A — MEDIA PREFLIGHT SANDBOX + BACKEND FOUNDATION / PHYSICAL RUNTIME QC NEXT

## Source
- Repository: `balinightlife666-web/ACC-Android-Builder`
- Branch: `feat/am-studio-distribution-foundation`
- Pull request: #92 (DRAFT / UNMERGED)
- Android package: `com.amstudio.distribution`
- App version: `0.2.0-media-preflight` / versionCode 2
- Verified APK source commit: `b9f2671c58a35271e5064c168ef570e4c204bf70`
- Verified APK CI run: `34338410385` — PASS
- Verified APK SHA-256: `36b1ffe015bc3928306f58f12f30b8c1c91d4623873658aff1c59e345ca64415`
- Backend foundation test run: `34338868865` — PASS

## Android implemented and CI-verified
- Dedicated project isolated at `tools/am-studio-distribution`
- Provider-neutral canonical release model and lifecycle
- `DistributionGateway` abstraction + `SandboxDistributionGateway`
- Local canonical release draft persistence
- Home / Releases / New Release / Earnings / Account screens
- Real Android document picker for master audio and cover artwork
- Persistable read URI permission for selected files
- Local media inspection: audio duration, name, MIME, size; artwork dimensions, MIME, size
- Release metadata: title, artist, label, genre, release date, songwriter, composer, copyright owner, explicit flag
- Rights declaration gate
- DSP destination selection
- Sandbox preflight requires WAV/FLAC, cover 1:1 >= 3000x3000, metadata, rights, and destinations
- Sandbox submission state without claiming production delivery
- Official AM STUDIO vector app mark applied to header and launcher
- GitHub Actions APK build + checksum artifact

## Backend foundation implemented and test-verified
- Isolated backend at `tools/am-studio-distribution/backend`
- Node 22 zero-dependency DEV_SANDBOX service
- Canonical server-side release lifecycle and edit-state lock
- Release create/list/read/patch operations
- Upload-session registry for AUDIO_MASTER / ARTWORK metadata
- Checksum completion/verification gate
- Server-side release preflight using verified asset references
- READY_FOR_REVIEW -> IN_REVIEW transition gate
- Immutable-style audit event stream for sensitive state changes
- Stable coded error boundary
- REST endpoints under `/v1`
- Automated lifecycle/preflight/checksum/edit-lock/audit tests — PASS
- Separate backend CI pipeline
- Android CI trigger narrowed so backend-only work does not rebuild APK

## Runtime evidence status
- Android CI compile/package: PASS
- Backend automated tests: PASS
- Physical Android install: PENDING for v0.2
- Launcher/icon visual QC: PENDING
- Audio picker runtime QC: PENDING
- Artwork picker/runtime dimension QC: PENDING
- Draft persistence after app restart: PENDING
- Preflight PASS/FAIL behavior on real files: PENDING
- Sandbox submission runtime QC: PENDING

## Explicitly NOT production-ready
- Production authentication/session service
- Secure object storage / signed upload targets
- Persistent production database
- Real KYC/KYB
- White-label provider credentials/integration
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
1. Physical Android v0.2 runtime QC.
2. Fix any runtime evidence failures without changing architecture.
3. Replace dev in-memory backend with production persistence + auth + secure upload storage.
4. Connect Android to AM STUDIO backend using environment-safe API client.
5. Select/contract first white-label provider and implement provider sandbox adapter.
6. End-to-end provider sandbox release delivery.
7. KYC/rights/admin moderation.
8. Royalty raw-ingest + normalized ledger + splits.
9. Payout workflow.
10. Controlled beta, multi-provider routing, then direct DSP/DDEX evolution.

## Safety lock
Do not call a release LIVE, monetized, royalty-bearing, production-distributed, or payout-eligible unless corresponding provider/DSP/ledger evidence exists.

Do not put provider API secrets into the APK. All production provider integrations live behind AM STUDIO backend adapters.
