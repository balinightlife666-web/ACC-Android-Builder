# LOST & FOUND: NIGHT SHIFT — M4-D.1 DECISION COLOR HOTFIX

Status: LIVE_PUBLISHED v36 / MOBILE QC PENDING
Updated: 2026-08-28

## Runtime finding
Roblox v35 improved station readability, but station-skin accent application recolored all four decision console tops/foot glows to the station accent color (amber/yellow). This reduced decision readability.

## Locked decision colors
Decision semantics must remain visually distinct and MUST NOT be overwritten by station skins:
- RETURN = green
- STORE = cyan/blue
- QUARANTINE = amber/yellow
- SECURITY = red

Station skins may change station body, panel, trim, lighting and general accent language, but may not replace the four functional decision colors.

## Implementation
`src/server/DecisionColorLock.server.lua`:
- marks decision `Top` and `FootGlow` as `decisionColor` rather than station `accent` at runtime;
- reapplies locked colors to RETURN / STORE / QUARANTINE / SECURITY;
- preserves decision-face text colors;
- no reward, drop, progression, trading, persistence, station allocation, or HUD behavior changes.

## Verified deployment
- source commit: `44e3b0c8046627375eb52e9d4d9ea18e5ca0e1c6`
- workflow run: `33105083714`
- Roblox version: `36`
- status: `LIVE_PUBLISHED`
- Rojo: `7.7.0`
- RBXL bytes: `85865`
- RBXL SHA256: `a8487f13d33e577c1caa8d42607bbd4771cfe09b2664f99e627735c92cfaec7e`

## QC gate
Verify on mobile that all four decision consoles are simultaneously readable with the locked green / cyan / amber / red distinction while the v35 readability improvements remain intact.
