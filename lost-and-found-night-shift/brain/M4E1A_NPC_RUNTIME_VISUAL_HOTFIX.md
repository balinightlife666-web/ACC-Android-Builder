# LOST & FOUND: NIGHT SHIFT — M4-E.1A NPC RUNTIME VISUAL HOTFIX

Status: SOURCE PASS / RUNTIME SCREENSHOT QC REQUIRED
Date: 2026-08-28

## Trigger

Runtime screenshot QC after M4-E.1 v38 showed a claimant still reading visually as the legacy head + torso block mannequin. Deployment was valid, but the NPC visual result was not acceptable.

## Scope

This is a narrow claimant visual/runtime-hook hotfix only.

- Harden `ActiveClaimant` visual attachment against creation-order races.
- Retry late-created Torso/Head children.
- Reconcile unpolished claimant models once per second.
- Stamp `NpcVisualVersion=M4E1A_NPC_V2` only after successful construction.
- Replace legacy cuboid silhouette with a lighter humanized in-engine build:
  - reshaped head using built-in Roblox head mesh;
  - narrower torso;
  - shoulders, upper arms, forearms and hands;
  - legs and shoes;
  - layered clothing;
  - seven hair constructions;
  - face detail;
  - optional glasses/accessories;
  - deterministic skin/outfit/hair variation by claimant name.
- Roblox geometry only; no generated images or external NPC assets.

## Hard Locks

Do not change:
- M4-E.1 routine evidence archetypes or difficulty weighting;
- Credits or XP;
- collectible drop rates;
- Collection Index / inventory pair mapping;
- trading;
- global serial/provenance rules;
- station ownership/isolation;
- Season 1 mystery canon/outcomes.

## Runtime Acceptance

1. Claimant no longer appears as head + torso only.
2. Hair/face/outfit/limbs are visible on every spawned claimant.
3. Consecutive claimants visibly vary.
4. Next-case claimant replacement receives the same visual pass.
5. No duplicate geometry accumulates after replacement/reconciliation.
6. Station loop SCAN/TAG/OPEN/DECIDE remains unchanged.
7. Mobile camera remains readable and claimant geometry does not block interaction prompts.
8. Exact-source deploy receipt must be verified before calling the hotfix LIVE.
