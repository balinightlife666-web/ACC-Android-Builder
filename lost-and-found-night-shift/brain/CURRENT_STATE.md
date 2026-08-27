# LOST & FOUND: NIGHT SHIFT — CURRENT STATE

Updated: 2026-08-27

## Identity
- Universe ID: `10745354451`
- Place ID: `93699016600671`
- Genre: Simulation
- Subgenre: None

## Infrastructure
- Temporary repo/build home: `balinightlife666-web/ACC-Android-Builder/lost-and-found-night-shift`
- Publish workflow is trigger-file/manual only.
- Deployment authority is `deploy-status/lost-and-found-m0.json`; never claim LIVE from source changes alone.

## M0 — FIRST SUITCASE
**COMPLETE / ACCEPTED.**

Core mobile loop is proven:
`spawn → incoming item → SCAN → CHECK TAG → OPEN → DECIDE → grade/reward → next case`

Movement/camera safety, compact CASE FILE UI, Credits display, and four operational decisions remain active.

## M0.1 — FEEL PASS
**COMPLETE / ACCEPTED.**

Locked feel values:
- conveyor travel: 2.8s;
- case advance delay: 3.2s;
- interaction distance: 7 studs baseline;
- prompt hold: 0.08s;
- claimant arrival delay: 0.45s;
- lightweight feedback audio retained.

## M1 — PREMIUM ROOM
**COMPLETE / RUNTIME-APPROVED FOR CONTINUATION.**

Visual authority remains `brain/M1_VISUAL_LOCK.md`:
- premium stylized airport Lost & Found back-office;
- charcoal / graphite architecture;
- brushed dark metal equipment;
- warm amber operational lighting;
- cyan scanner/evidence accents;
- restrained red quarantine/security accents;
- no neon-arcade floor language.

### M1-A approved room modules
- premium service/intake counter;
- premium conveyor;
- scanner arch / evidence equipment;
- inspection desk;
- claimant zone;
- operational decision consoles;
- storage dressing;
- quarantine access;
- industrial lighting pass.

### M1-B approved base item models
1. `hardcase_suitcase`
2. `vintage_suitcase`
3. `backpack`
4. `cardboard_box`
5. `teddy_bear`

Mobile runtime exercised the active sequence through the M1 case loop without reported welded-model/conveyor failure. v14 additionally fixed inspection ergonomics by providing floor-accessible interaction anchors with TAG on the left and OPEN on the right.

Registry authority:
- `registry/ITEM_REGISTRY.json`: five production-approved base types;
- `registry/ASSET_REGISTRY.json`: `baseItemMeshesApproved = 5`, `m1Complete = true`.

## Active milestone
**M2 — COLLECTION FOUNDATION**

### M2-A implemented
Initial collection size: **5 approved base item types**.

Rarity seed:
- Hardcase Suitcase — COMMON
- Vintage Suitcase — UNCOMMON
- Travel Backpack — COMMON
- Cardboard Parcel — UNCOMMON
- Teddy Bear — RARE

Collection behavior:
- resolving a case registers that base item type for the deciding player;
- duplicate resolutions do not increase unique discovery count;
- server owns the session discovery state;
- client receives `CollectionUpdate` sync/discovery events;
- top-right `INDEX x/5` button sits below Credits;
- INDEX popup shows discovered item names + rarity and hides undiscovered entries;
- first discovery produces a short `NEW DISCOVERY` toast.

Important limits for M2-A:
- collection is **SESSION-ONLY**;
- no DataStore persistence yet;
- no trading;
- no Evidence Tokens;
- do not expand to 30–40 items in one uncontrolled batch.

## M2-A publish receipt
Run: `33034725816`
Source commit: `75b30a3d5ef864af34459f3feb8da821a27fae7d`
Rojo: `7.7.0`
Static QC: **PASS**
Rojo build: **PASS**
Roblox publish: **PASS**
Roblox version: `15`
RBXL bytes: `32006`
RBXL SHA256: `3dc04933f291b50bf87684816a649ebedaacf59a2753a15bd67ad30966c89ccf`
Deploy receipt: `deploy-status/lost-and-found-m0.json`

## LIVE authority
**LIVE_PUBLISHED — v15 BUILD/DEPLOY VERIFIED.**
M2-A collection UI/runtime still requires mobile acceptance.

## Next gate
**M2-A-RUNTIME:** verify on mobile:
1. movement and existing case UI remain normal;
2. `INDEX 0/5` appears below Credits without blocking controls;
3. resolving the first unique item updates Index to `1/5`;
4. `NEW DISCOVERY` toast is readable but not intrusive;
5. INDEX popup opens/closes cleanly;
6. discovered row reveals correct name + rarity;
7. duplicate item type does not increase unique count;
8. case loop remains stable.

After M2-A runtime acceptance, proceed to M2-B: first controlled item-variant expansion + simple physical showcase/display. Persistence should be added only after the collection rules/UI are accepted.
