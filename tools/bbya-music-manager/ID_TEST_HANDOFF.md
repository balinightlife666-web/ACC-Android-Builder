# BBYA Music Manager — ID Test Handoff

Status: ACTIVE / DEVICE TEST REQUIRED
Date: 2026-08-29

## Safety lock

This test must target **BBYA Music UI Test only**.

- Test universe: `10762005984`
- Test place: `124607344716828`
- Messaging topic: `BBYA_MUSIC_UNDERGROUND_V1`
- Do not target BBYA Social Hub production universe `8116636513` during this test.
- Do not merge the test-map branch into production solely to run this test.

## Canonical Android test build

Use **BBYA Music Manager v0.3.16-ID-Test-UIMap**.

Build-time test contract:

- Android `versionCode`: `17`
- OAuth scope: `openid universe-messaging-service:publish`
- `profile`, `asset:read`, and `asset:write` are intentionally not requested.
- Target universe is patched to `10762005984`.
- Underground catalog is isolated to exactly the 25 screenshot Roblox Asset IDs.
- No source audio upload is required for these seeded tracks.

Build workflow: `.github/workflows/bbya-music-id-test-build.yml`

Verified successful run: `33260480124`

Artifact: `BBYA-Music-Manager-v0.3.16-ID-Test-UIMap`

Artifact digest: `sha256:06773cba8aed68e908fd03517ff187a61b006e151549812f58470e4fde50ea88`

## Test-map receiver

The isolated Roblox test map contains the Underground APK mirror receiver in:

`maps/bbya-social-hub/85-basement-autodj.server.lua`

Receiver contract:

1. Subscribe to `BBYA_MUSIC_UNDERGROUND_V1` using `MessagingService`.
2. Validate `v=1`, `z=underground`, Asset ID, track ID, revision, and message size.
3. Accept `upsert`, `delete`, `clear`, and `fallback` operations.
4. Persist mirror state in DataStore `BBYAMusicCatalogV1`, key `zone:underground`.
5. Apply the mirror catalog to the existing Underground Deck A/B AutoDJ and player-facing music state.

Test-map source commit: `8765be9d484b09e044a6997b74f42e41de555346`

Verified isolated publish:

- Status: `PUBLISHED`
- Roblox test version: `14`
- Universe: `10762005984`
- Place: `124607344716828`

## Device test procedure

1. Install v0.3.16 over the older BBYA Music Manager test build.
2. Start **BBYA Music UI Test** in Roblox and keep the test server open.
3. Open BBYA Music Manager.
4. Verify Underground contains 25 seeded tracks.
5. Tap `LOGIN ROBLOX`.
6. Complete OAuth consent. The expected requested capabilities are identity (`openid`) and universe Messaging Service publish only.
7. Return to the APK and tap `SYNC UNDERGROUND` once.
8. Return to BBYA Music UI Test, enter Underground, open the music UI, and verify the received library / playback.
9. Record any Asset IDs that fail because of privacy, ownership, moderation, authorization, or invalid transcription.

## Seeded screenshot Asset IDs

1. `86006580589828` — title obscured in screenshot; verify later.
2. `125820152354579` — DJ Paradise X Velocity Baby Don't Go feat IMA Audio
3. `133947654553749` — DJ TJAP Morgan V4
4. `95691778643767` — DJ Ayang Ayang
5. `130313438027284` — Funk Do Bounce
6. `75712054983357` — Hadroh Ya Thoybha | Ar Production
7. `88943191512256` — DJ Banteng Lestari
8. `91809948844354` — DJ Gangsta MP
9. `108578144206183` — DJ Kandas HKS
10. `89763491889927` — DJ Battle HKS
11. `96924419000406` — DJ Trap Love Of War
12. `132460784559824` — DJ Cinta Yang Sempurna
13. `122720606049274` — DJ Bocah Bocah Cilik Sholawat
14. `70777592375726` — DJ Mahabarata
15. `98308711398889` — DJ Bila Nanti
16. `95839337053281` — DJ Punk Rock Jalanan
17. `135587255285184` — DJ TJAP Morgan Trompet - By Klepon Remix
18. `104136707299013` — DJ Gedhang Klutuk by DJ Tanti
19. `131597067752690` — Garam Cina
20. `73502975968958` — DJ Sin Pijama by Alvin Revolution
21. `101289385838814` — DJ Trompet Brazil
22. `102043858565172` — DJ Viral Tik Tok Pal Pal Di Kepas
23. `79235704240751` — DJ Twenty One Pilots Nova - Tambal Elang
24. `103710801320668` — DJ Prank Karnaval Viral Booyah
25. `102227106442067` — DJ We Found Love; screenshot ID not yet 100% verified.

## Known previous failure

v0.3.14 requested OAuth scope `profile` and Roblox rejected authorization with:

`Scope not allowed for this application: profile`

The current v0.3.16 test build removes that scope and also removes asset scopes because this test sends pre-existing Asset IDs rather than uploading source audio.

## Pass criteria

The test passes when:

- Roblox OAuth completes without a scope error.
- `SYNC UNDERGROUND` reports successful publishing of the seeded playlist.
- The test-map receiver receives the deltas.
- The Underground music UI exposes the seeded catalog.
- At least one authorized Asset ID loads and plays through the test-map Underground audio authority.
- No production BBYA Social Hub universe is modified.

Do not promote this test route to production until those checks are verified on-device.