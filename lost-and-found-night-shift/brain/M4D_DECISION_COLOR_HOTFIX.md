# LOST & FOUND: NIGHT SHIFT — M4-D.1 DECISION COLOR HOTFIX

Status: SOURCE READY / PUBLISH PENDING
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

## QC gate
After publish, verify on mobile that all four decision consoles are simultaneously readable with the locked green / cyan / amber / red distinction while the v35 readability improvements remain intact.
