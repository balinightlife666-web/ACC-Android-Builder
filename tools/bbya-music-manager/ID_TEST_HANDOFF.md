# BBYA Music Manager — ID Test Handoff

Status: ACTIVE / DEVICE TEST REQUIRED
Date: 2026-08-29

## Safety lock

This test targets **BBYA Music UI Test only**.

- Test universe: `10762005984`
- Test place: `124607344716828`
- Messaging topic: `BBYA_MUSIC_UNDERGROUND_V1`
- Production BBYA Social Hub universe `8116636513` is out of scope.
- Do not merge the test-map branch wholesale into production.

## Canonical Android test build

Use **BBYA Music Manager v0.3.17-ID-Test-UIMap**.

- Android `versionCode`: `18`
- OAuth scope: `openid universe-messaging-service:publish`
- `profile`, `asset:read`, and `asset:write` are intentionally absent.
- Target universe: `10762005984`.
- Underground catalog is isolated to the 25 screenshot Roblox Audio Asset IDs.
- Roblox metadata audit: **25/25 valid Audio assets, 24 Approved, 1 Rejected**.
- Rejected ID `102227106442067` is retained for traceability but `enabled=false`, so it is not playable by the Underground mirror.
- No source audio upload is required in this test.

Build workflow: `.github/workflows/bbya-music-id-test-build.yml`

Verified successful run: `33261029136`

Artifact: `BBYA-Music-Manager-v0.3.17-ID-Test-UIMap`

Workflow artifact digest: `sha256:ddda60561d5e9b0119cd1feca6e3886ed1aaf444f7f8730e0c4f79ef030d2168`

Downloaded APK SHA-256: `f185d9c4e147b9bc7478f8cc601b4b183a8f1af3c5bd5e592db50d279cdccbb6`

### Binary verification

The actual built APK was unpacked and its DEX inspected.

Present:
- `10762005984`
- `openid universe-messaging-service:publish`
- `BBYA_MUSIC_UNDERGROUND_V1`
- `24_APPROVED_1_REJECTED_DISABLED`
- `ROBLOX_REJECTED`
- `DJ LUKA NEGARA VERSI JEPANG V2`
- all 25 seeded Asset IDs

Absent:
- production universe `8116636513`
- `asset:read`
- `asset:write`
- `openid profile`

## Roblox metadata audit

Audit workflow run: `33260916786`

Result:
- 25/25 HTTP 200
- 25/25 `Audio`
- 24/25 moderation `Approved`
- 1/25 moderation `Rejected`: `102227106442067` — `Dj We Found Love MINIONS AUDIO`

Resolved screenshot title #1:
- `86006580589828` — `DJ LUKA NEGARA VERSI JEPANG V2`

Metadata approval does **not** prove the audio is permitted for playback in the test universe. Runtime experience authorization still has to be tested in Roblox.

## Test-map receiver

Runtime file: `maps/bbya-social-hub/85-basement-autodj.server.lua`

Receiver contract:
1. Subscribe to `BBYA_MUSIC_UNDERGROUND_V1` using `MessagingService`.
2. Validate `v=1`, `z=underground`, Asset ID, track ID, revision, and message size.
3. Accept `upsert`, `delete`, `clear`, and `fallback` operations.
4. Persist mirror state in DataStore `BBYAMusicCatalogV1`, key `zone:underground`.
5. Feed the existing Underground Deck A/B AutoDJ and player-facing music state.
6. Filter out tracks with `enabled=false` from the playable mirror playlist.

Verified isolated test-map publish:
- Source commit: `8765be9d484b09e044a6997b74f42e41de555346`
- Status: `PUBLISHED`
- Roblox test version: `14`
- Universe: `10762005984`
- Place: `124607344716828`

## Device test procedure

1. Install v0.3.17 over the older BBYA Music Manager test build.
2. Start **BBYA Music UI Test** in Roblox and keep the test server open.
3. Open BBYA Music Manager.
4. Open Underground and verify the isolated screenshot catalog is present; rejected `DJ We Found Love MINIONS AUDIO` should be disabled.
5. Tap `LOGIN ROBLOX`.
6. Complete OAuth consent. Expected capabilities: identity (`openid`) + universe Messaging Service publish only.
7. Return to the APK and tap `SYNC UNDERGROUND` once.
8. Return to BBYA Music UI Test, enter Underground, open the music UI, and verify received catalog/playback.
9. Record which of the 24 Approved Asset IDs actually load in universe `10762005984`.

## Known previous failure

v0.3.14 requested `profile`; Roblox rejected it with:

`Scope not allowed for this application: profile`

v0.3.17 removes that scope and all asset upload/read scopes because the test publishes pre-existing Asset IDs only.

## Pass criteria

- OAuth completes without a scope error.
- `SYNC UNDERGROUND` reports successful publishing.
- Test-map receiver receives the deltas.
- Underground UI exposes the mirrored catalog.
- At least one of the 24 moderation-approved Asset IDs loads and plays.
- Rejected ID remains non-playable.
- Production BBYA Social Hub remains untouched.

Do not promote the test route to production until those checks pass on-device.