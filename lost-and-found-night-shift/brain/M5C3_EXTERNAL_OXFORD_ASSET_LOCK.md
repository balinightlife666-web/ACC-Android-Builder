# LOST & FOUND: NIGHT SHIFT — M5-C.3 External Oxford Asset Lock

Status: IMPLEMENTATION / REQUIRES EXACT DEPLOY RECEIPT + RUNTIME VISUAL QC

## Scope
Replace only the showcase geometry for `daniel_formal_shoe` with the user-selected Oxford shoe model while preserving the stable M5-C.1.3 five-slot showcase lifecycle.

## Source asset
- Title: Oxford style leather shoe for men
- Creator: assetfactory
- Source platform: Sketchfab
- Source license shown on source page: Free Standard
- Source model: 13.6k triangles / about 6.9k source vertices
- Selected by Arda for LOST & FOUND
- Source URL is recorded in `src/shared/ExternalCollectibleAssets.lua`

## Roblox optimization
- User-provided GLB was validated locally.
- Mesh silhouette retained.
- High-resolution embedded PBR textures were removed from the upload derivative to keep the Roblox model payload small and deterministic.
- Upload derivative: 449,448 bytes
- SHA256: `82ed5b004820e77f95599e7da1254f322b0ebe446eeafab2083cc519dcbd83ef`
- Asset payload in repo is gzip + base64 transport only; workflow reconstructs exact GLB before upload.

## Upload authority
Use the existing Roblox Open Cloud asset key only after key introspection confirms:
- `asset` read + write
- `asset-permissions` write

Upload type: `Model`
Target use permission: LOST & FOUND Universe `10745354451`.

The returned Roblox Asset ID must be written by workflow into `ExternalCollectibleAssets.lua`; never invent or manually guess it.

## Runtime integration
`M5C3ExternalCollectibleAssets.server.lua`:
- loads the approved model through `InsertService`;
- only targets collection `daniel_formal_shoe`;
- preserves the existing M5-C.1.3 slot Model instance and immutable showcase attributes;
- swaps geometry once, not on a timer;
- performs fitting before exposing replacement geometry;
- preserves nameplate, rarity, serial, slot choice, ownership and persistence;
- falls back to the existing procedural shoe if the external model cannot load.

## Hard locks unchanged
Do not change:
- Credits / XP
- collectible drop rates or mystery candidate chance
- Collection Index semantics
- immutable instance ID / serial / provenance
- trading rules
- personal station ownership / isolation
- decision logic or grades
- Season 1 mystery canon
- localization authority
- five-slot stable showcase lifecycle

## Acceptance
1. Open Cloud model upload returns a real Roblox Asset ID.
2. LOST & FOUND Universe receives Use permission for that Asset ID.
3. Exact Asset ID is recorded in source registry.
4. Normal LOST & FOUND publish receipt sourceCommit equals the source containing that ID.
5. Rejoin: Daniel's Formal Shoe renders as the Oxford shoe, not the procedural boat-like silhouette.
6. No flicker during 60-second rack observation.
7. Duplicate serialized shoes may still appear in separate slots if the player deliberately owns/displays multiple instances; serial semantics remain unchanged.
8. If InsertService load fails, procedural fallback appears without breaking the rack.
