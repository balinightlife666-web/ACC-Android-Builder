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

### M1 approved base item models
1. `hardcase_suitcase`
2. `vintage_suitcase`
3. `backpack`
4. `cardboard_box`
5. `teddy_bear`

v14 fixed inspection ergonomics with floor-accessible TAG-left / OPEN-right interaction anchors.

Registry authority:
- `registry/ITEM_REGISTRY.json`: five production-approved base types;
- `registry/ASSET_REGISTRY.json`: `baseItemMeshesApproved = 5`, `m1Complete = true`.

## Active milestone
**M2 — COLLECTION FOUNDATION**

### M2-A collection behavior
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
- top-right `INDEX x/5` button sits below Credits;
- first discovery produces a short `NEW DISCOVERY` toast.

### M2-A visual collection upgrade — v16
The text-only INDEX list was replaced by collectible **3D ViewportFrame cards**.

Visual rules:
- each of the five item types has an in-UI 3D preview built from the existing item visual language;
- discovered cards display the full-color item, item name, and rarity;
- undiscovered cards display a dark 3D silhouette with `? / LOCKED` rather than a plain text row;
- popup title is `LOST PROPERTY COLLECTION`;
- no generated images are used for collection cards;
- preview source: `src/shared/CollectionPreviewFactory.lua`;
- collection UI source: `src/client/Collection.client.lua`.

Important limits:
- collection remains **SESSION-ONLY**;
- no DataStore persistence yet;
- no trading;
- no Evidence Tokens;
- do not expand to 30–40 items in one uncontrolled batch.

## Latest publish receipt
Run: `33038345674`
Source commit: `60f96622b3ae46f9dbaad6a6f008ddc0860ad8b6`
Rojo: `7.7.0`
Static QC: **PASS**
Rojo build: **PASS**
Roblox publish: **PASS**
Roblox version: `16`
RBXL bytes: `34284`
RBXL SHA256: `da358f5768388940ada8b74c49b5097735f905e7d46353d72a0a6fd73d48cec7`
Deploy receipt: `deploy-status/lost-and-found-m0.json`

## LIVE authority
**LIVE_PUBLISHED — v16 BUILD/DEPLOY VERIFIED.**
3D collection-card visual/runtime acceptance still requires mobile inspection.

## Next gate
**M2-A-RUNTIME:** verify on mobile:
1. INDEX popup opens/closes without blocking movement after close;
2. five collection cards fit cleanly on landscape mobile;
3. locked cards visibly read as item silhouettes rather than blank rows;
4. resolving a unique item changes the corresponding card to full color with correct name + rarity;
5. `INDEX x/5` increments correctly;
6. duplicate base item does not increment unique count;
7. case loop remains stable.

After M2-A visual runtime acceptance, proceed to M2-B: controlled item-variant expansion + simple physical showcase/display. Persistence should be added only after the collection rules/UI are accepted.
