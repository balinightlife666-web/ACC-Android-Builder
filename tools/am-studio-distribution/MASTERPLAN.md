# AM STUDIO MUSIC DISTRIBUTION — MASTERPLAN v1.0

Status: ACTIVE FOUNDATION
Owner / Final Authority: Arda
Project brand: AM STUDIO
Android package: `com.amstudio.distribution`

## 1. North Star

Build AM STUDIO into an Indonesian-first music distribution platform where artists and labels can upload a release once, pass rights/metadata QC, distribute to multiple DSPs, track release status and royalties, and receive payouts.

The system must start with a white-label/API distribution provider but be architected so the distribution engine can later be replaced by direct DSP relationships and DDEX without rebuilding the Android app or core database.

## 2. Non-negotiable architecture rule

The Android app NEVER talks directly to a DSP or white-label provider with secret credentials.

Android -> AM STUDIO API -> Distribution Gateway -> Provider adapter -> DSPs

Provider-specific IDs and payloads are isolated inside adapters. Internal AM STUDIO IDs remain canonical.

## 3. End-state product

### Artist / Label app
- Account + KYC/KYB state
- Artist profiles and label profiles
- New release wizard
- Audio upload (WAV/FLAC validation)
- Artwork upload and validation
- Metadata, contributors, writers, producers, publishers
- Rights declaration, sample/remix declarations
- Territories and release dates
- DSP/store selection
- Preflight validation
- Submit / review / rejection repair
- Release status by DSP
- ISRC / UPC handling
- Takedown and metadata update requests
- Analytics
- Royalty statements
- Splits
- Wallet / payout requests
- Tax/payment profile
- Support / disputes

### Admin / Operations
- User/KYC review
- Catalog moderation
- Audio/artwork/metadata QC
- Rights risk flags
- Duplicate/fingerprint checks
- Fraud/artificial-streaming risk
- Provider delivery status
- DSP rejection repair
- Royalty import and reconciliation
- Split calculation
- Platform fees / commission
- Payout approval
- Takedown / infringement queue
- Audit log

## 4. Business model layers

The engine supports all three without database redesign:
1. Subscription + distribution fee.
2. Royalty share / commission.
3. Hybrid plans by artist/label.

Every royalty ledger entry stores gross amount, provider deductions, AM STUDIO fee, split allocation, taxes/withholding where applicable, and payable balance. Financial history is append-only; corrections use adjustment entries, never destructive edits.

## 5. Distribution evolution

### Phase A — Foundation / Sandbox
Build Android shell, canonical domain model, release state machine, provider-neutral API contract, audit fields, CI build.

### Phase B — White-label MVP
Integrate one provider through AM STUDIO backend. Provider candidate must support API/sandbox, release creation, asset upload, delivery status, analytics/royalty export or API, and takedowns.

### Phase C — Commercial Beta
KYC, real catalog QC, plans/billing, royalty ledger, payout workflow, support, infringement process, operational dashboards.

### Phase D — Scale
Multi-provider routing, redundancy, provider migration tooling, catalog transfer, fraud controls, automated metadata QC, reconciliation, label accounts, team permissions.

### Phase E — Direct Aggregator
Add direct DSP contracts progressively. Implement DDEX ERN delivery and required reporting/reconciliation flows behind the existing DistributionGateway boundary. White-label provider can remain as fallback for unsupported DSPs.

## 6. Canonical release lifecycle

DRAFT -> PREFLIGHT_REQUIRED -> READY_FOR_REVIEW -> IN_REVIEW -> APPROVED -> SCHEDULED -> DELIVERING -> PARTIALLY_LIVE / LIVE

Repair branches:
- NEEDS_CHANGES
- PROVIDER_REJECTED
- DSP_REJECTED
- RIGHTS_HOLD
- FRAUD_HOLD

Terminal / administrative:
- TAKEDOWN_REQUESTED -> TAKING_DOWN -> TAKEN_DOWN
- CANCELLED

The client cannot arbitrarily jump states. State transitions are validated server-side and written to an audit log.

## 7. Canonical data domains

- User
- Organization / Label
- Artist
- Release
- Track / Recording
- Contributor
- Composition / Publishing info
- Asset
- RightsDeclaration
- TerritoryDeal
- DistributionDestination
- Delivery
- Identifier (AM internal / ISRC / UPC-EAN / provider IDs)
- QCCheck
- ModerationCase
- AnalyticsMetric
- RoyaltyStatement
- RoyaltyLine
- SplitContract
- LedgerEntry
- Wallet
- Payout
- TaxProfile
- SupportCase
- AuditEvent

Provider IDs are secondary mappings, never primary business identifiers.

## 8. Security and compliance baseline

- No provider/DSP secret in APK.
- Signed authenticated API requests.
- Encryption in transit and at rest for sensitive data.
- Least-privilege service accounts.
- Immutable audit events for financial and moderation actions.
- KYC/KYB before payouts and where required before distribution.
- Rights declaration and evidence workflow.
- Copyright/takedown process.
- Duplicate/fraud monitoring.
- Role-based admin access.
- No payout balance derived only from UI values; ledger is server-authoritative.

## 9. File/media pipeline

1. Client requests upload session.
2. Backend returns short-lived upload target.
3. Client uploads audio/artwork directly to object storage.
4. Backend verifies checksum, MIME, duration, sample rate/bit depth policy, image dimensions/color mode.
5. Media is immutable by version; replacement creates a new asset version.
6. Provider adapter receives approved canonical assets only.

## 10. Provider abstraction

Core interface:
- validateRelease
- createRelease
- uploadAssets / mapAssets
- submitRelease
- fetchDeliveryStatus
- requestMetadataUpdate
- requestTakedown
- fetchAnalytics
- fetchRoyaltyStatements

Adapters:
- SandboxMockAdapter (now)
- WhiteLabelAdapter (first commercial provider)
- FutureProviderAdapter
- DirectDdexAdapter

## 11. Revenue integrity

Royalty flow:
Provider/DSP statement -> raw statement archive -> normalized royalty lines -> reconciliation -> ledger -> split engine -> AM STUDIO fee -> artist/label payable wallet -> payout.

Raw source statements are never overwritten.

## 12. Release quality gates

Before submit:
- valid master audio
- artwork policy pass
- title/version formatting
- primary artist and contributors complete
- songwriter/composer data complete
- explicit flag
- language/genre
- release date lead time
- territories
- rights declaration
- sample/remix disclosure
- duplicate check
- required identifiers

## 13. Android information architecture

Bottom navigation target:
HOME | RELEASES | + | EARNINGS | ACCOUNT

Release wizard:
1. Release basics
2. Tracks
3. Credits & rights
4. Artwork
5. Stores & territories
6. Schedule
7. Preflight
8. Review & submit

## 14. Backend target architecture

- API Gateway / Auth
- Identity + KYC service
- Catalog service
- Media service
- QC/Moderation service
- Distribution orchestrator
- Provider adapters
- Analytics ingestion
- Royalty ingestion/reconciliation
- Ledger + split engine
- Payout service
- Notification service
- Admin console
- Audit/event store

Use asynchronous jobs for provider delivery and statement ingestion; user-facing actions return durable job IDs and state.

## 15. Database migration rule

Schema migrations are versioned. Never repurpose an existing field for a different meaning. Provider-specific data lives in mapping/config tables or JSON payload archives, while canonical fields remain provider-neutral.

## 16. Current implementation target — v0.1 FOUNDATION

Deliverables:
- Dedicated branch
- Masterplan and architecture locks
- Buildable native Android project
- AM STUDIO identity/icon baseline
- Home dashboard
- Releases screen
- New Release draft flow
- Provider-neutral DistributionGateway
- Sandbox mock adapter
- Domain/status model
- GitHub Actions APK build

No claim of real DSP delivery or monetization is allowed until an actual provider/backend integration and commercial account are verified.

## 17. Definition of commercial MVP

MVP is NOT complete merely because the APK installs.

Commercial MVP requires:
- authenticated backend
- real object storage
- provider sandbox pass
- real provider production account
- release create/upload/submit/status end-to-end
- KYC/rights controls
- royalty ingestion test
- ledger/split correctness tests
- payout workflow test
- operational takedown path
- legal documents and support process

## 18. Long-term success metric

AM STUDIO can move a catalog from Provider A to Provider B or Direct DDEX while Android clients keep the same internal release IDs, release history, royalties, and user workflow. If provider migration requires rewriting the app/domain model, the architecture has failed.