# AM STUDIO MUSIC DISTRIBUTION — CURRENT STATE

Date: 2026-09-09
Authority: MASTERPLAN v1.0
Phase: A — MEDIA PREFLIGHT SANDBOX / PHYSICAL RUNTIME QC NEXT

## Source
- Repository: `balinightlife666-web/ACC-Android-Builder`
- Branch: `feat/am-studio-distribution-foundation`
- Pull request: #92 (DRAFT / UNMERGED)
- Android package: `com.amstudio.distribution`
- App version: `0.2.0-media-preflight` / versionCode 2
- Last verified source commit before this state receipt: `b9f2671c58a35271e5064c168ef570e4c204bf70`
- Verified CI run: `34338410385` — PASS
- Verified APK SHA-256: `36b1ffe015bc3928306f58f12f30b8c1c91d4623873658aff1c59e345ca64415`

## Implemented and CI-verified
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
- API contract / long-term white-label-to-direct-aggregator architecture retained
- GitHub Actions APK build + checksum artifact

## Runtime evidence status
- CI compile/package: PASS
- Physical Android install: PENDING for v0.2
- Launcher/icon visual QC: PENDING
- Audio picker runtime QC: PENDING
- Artwork picker/runtime dimension QC: PENDING
- Draft persistence after app restart: PENDING
- Preflight PASS/FAIL behavior on real files: PENDING
- Sandbox submission runtime QC: PENDING

## Explicitly NOT production-ready
- Authentication backend
- Secure object/media storage and upload sessions
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
3. Build AM STUDIO backend foundation: auth + catalog + media upload sessions.
4. Implement server-side preflight/state transition service.
5. Select/contract first white-label provider and integrate sandbox through adapter.
6. End-to-end provider sandbox release delivery.
7. KYC/rights/admin moderation.
8. Royalty raw-ingest + normalized ledger + splits.
9. Payout workflow.
10. Controlled beta, multi-provider routing, then direct DSP/DDEX evolution.

## Safety lock
Do not call a release LIVE, monetized, royalty-bearing, production-distributed, or payout-eligible unless corresponding provider/DSP/ledger evidence exists.

Do not put provider API secrets into the APK. All production provider integrations live behind AM STUDIO backend adapters.
