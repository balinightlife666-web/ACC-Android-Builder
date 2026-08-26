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
**ACCEPTED FOR CONTINUATION.**

Runtime proven on mobile:
- player joins and can move;
- case arrives on conveyor;
- enforced sequence is `SCAN → CHECK TAG → OPEN → DECIDE`;
- claimant data appears;
- RETURN / STORE / QUARANTINE / SECURITY work;
- grading and rewards work;
- Credits amount displays live in the top HUD;
- next case starts automatically;
- compact case card + on-demand CASE FILE popup work on mobile.

## M0.1 — FEEL PASS
**ACCEPTED FOR CONTINUATION INTO M1.**

Implemented and published in Roblox v11:
- conveyor travel 2.8s;
- case advance 3.2s;
- interaction distance 7 studs;
- prompt hold 0.08s;
- short claimant staging delay;
- lightweight built-in audio feedback;
- mobile movement/camera safety retained;
- Credits display retained.

## Active milestone
**M1 — PREMIUM ROOM**

Visual authority:
- `brain/M1_VISUAL_LOCK.md`
- premium stylized airport Lost & Found back-office;
- charcoal / graphite architecture;
- brushed dark metal equipment;
- warm amber service/task light;
- cyan scanner/evidence accents;
- restrained red quarantine/security accents;
- operational workplace first, mystery second;
- no neon arcade floor look.

## M1-A — PREMIUM ROOM SHELL + EQUIPMENT
Implemented in source:
- premium room shell with wall panels, trims, floor guides, and hidden spawn pad;
- premium service counter with layered fascia, wood top, amber task lighting, and operations monitor;
- premium conveyor with layered base, belt slats, rails, and restrained under-lighting;
- scanner rebuilt as an arch with cyan inner scan lines and evidence display;
- inspection desk upgraded with dedicated tag reader, open tray, and evidence screen;
- claimant waiting zone separated from staff work area;
- four decision pads replaced by raised operational consoles;
- storage racks / stored-property dressing added;
- quarantine access rebuilt with restricted frame and red warning lamp;
- procedure board rebuilt for clearer room hierarchy;
- lighting upgraded with six industrial ceiling fixtures plus subtle color correction/bloom;
- core gameplay refs and sequence preserved.

Asset registry:
- five procedural room modules are registered as `SOURCE_APPROVED_PENDING_RUNTIME_QC`;
- external item asset dependency remains false;
- M1-B still requires minimum 5 production-approved base item meshes;
- M1 is NOT complete yet.

## M1-A publish receipt
Run: `33006053394`
Source commit: `6e92e32682c6313aaedd4c13ebec3a0f7d762967`
Rojo: `7.7.0`
Roblox publish: **PASS**
Roblox version: `12`
RBXL bytes: `24768`
RBXL SHA256: `3460afb39cf78ebd9c4569ab6ea454b948650daea44fefc248956a62b01b766c`
Deploy receipt: `deploy-status/lost-and-found-m0.json`

## LIVE authority
**LIVE_PUBLISHED — v12 BUILD/DEPLOY VERIFIED.**
M1-A room/equipment visual acceptance still requires mobile runtime inspection.

## Next gate
**M1-A-RUNTIME:** verify on mobile:
1. movement/camera remain normal;
2. room clearly reads as premium Lost & Found operations rather than placeholder blocks;
3. scanner/conveyor/counter are visually stronger without blocking movement;
4. SCAN / TAG / OPEN prompts remain reachable and obvious;
5. decision consoles remain easy to use;
6. lighting is readable and not over-bright;
7. full case loop still completes.

If M1-A passes, proceed to **M1-B — BASE ITEM ASSET PACK** with minimum 5 approved item meshes. Do not claim M1 complete before that gate passes.
