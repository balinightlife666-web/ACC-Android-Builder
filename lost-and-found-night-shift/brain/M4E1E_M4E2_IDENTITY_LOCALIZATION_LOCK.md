# LOST & FOUND: NIGHT SHIFT — M4-E.1E + M4-E.2 IDENTITY / LOCALIZATION LOCK

Status: SOURCE PASS / RUNTIME QC REQUIRED
Date: 2026-08-28

## Runtime findings that triggered this pass

1. M4-E.1D v42 passed claimant hook, facing, grounding, variation and anti-repeat direction, but a fictional claimant such as `Alya Putri` could still receive a silhouette that visually conflicted with the authored identity of that character.
2. The deduction loop depends on reading operational evidence. English-only specialist wording such as routing records, claim tags, quarantine and security escalation creates an unnecessary barrier for younger/non-English players and limits the reachable Roblox market.

## M4-E.1E — Claimant identity coherence

- Keep M4-E.1C body construction and M4-E.1D outfit/glasses polish.
- After those passes complete, apply authored presentation metadata to the game's fictional claimant-name pool.
- Presentation classes: `FEMININE`, `MASCULINE`, `NEUTRAL`, `CHILD`.
- Rebuild only claimant hair/cap silhouette from bounded Roblox primitives.
- Do not infer anything about real players or Roblox users; this metadata applies only to fictional NPC names authored inside LOST & FOUND.
- Stamp `NpcIdentityVersion=M4E1E_IDENTITY_V1` and `NpcPresentationTag` to prevent duplicate work.
- No external NPC assets and no image generation.

## M4-E.2 — Player language + accessible terminology foundation

### Locale authority

- Source/fallback language remains English.
- First authored translation: Bahasa Indonesia.
- Client resolves Roblox language using `LocalizationService.RobloxLocaleId` with `Player.LocaleId` fallback.
- Optional future/manual override hook is reserved through player attribute `LostFoundLocaleOverride`.
- Do not use physical/geographic location to choose language.

### Indonesian terminology lock

Use simple operational language rather than literal technical translation:

- SCAN -> PINDAI
- CHECK TAG -> CEK TAG
- OPEN / INSPECT -> BUKA / PERIKSA
- RETURN -> KEMBALIKAN
- STORE -> SIMPAN
- QUARANTINE -> ISOLASI
- SECURITY -> KEAMANAN
- Property Review -> Pemeriksaan Barang
- claimant -> pengambil
- owner -> pemilik
- claim tag -> tag pengambilan
- routing / operational status should be rewritten as plain understandable Indonesian, not word-for-word machine translation.

### Localized surfaces in this foundation

- compact case HUD;
- case-file popup;
- evidence labels and common operational evidence text;
- inspection instructions;
- result grade / decision / credit wording;
- station scanner/tag/open prompts;
- decision prompts and station decision labels;
- common Index / Archive / Trade / Collection labels when encountered in PlayerGui;
- station/VACANT/claimant world labels where exact source text is recognized.

### Architecture

- `src/shared/Localization.lua` is the source terminology table and reusable localization helper.
- `src/client/M4E2Localization.client.lua` performs player-local presentation translation only.
- Server decision IDs remain English canonical (`RETURN`, `STORE`, `QUARANTINE`, `SECURITY`) so localization cannot change gameplay validation.
- Unknown/untranslated strings fall back to English rather than blocking the player.

## Market expansion rule

The localization structure must remain extensible. Future languages can be added without changing case logic. Candidate expansion can include Portuguese, Spanish, Thai, Vietnamese, Japanese and Korean after EN/ID runtime QC, but no additional language is considered shipped until authored terminology and gameplay text are checked in-game.

## HARD LOCKS

Do not change:

- 26 M4-E.1 routine evidence archetypes;
- EASY / MEDIUM / HARD weighting;
- mystery candidate chance;
- Season 1 mystery canon/outcomes;
- Credits or XP;
- collectible drop rates;
- Collection Index / inventory identity;
- trading;
- serial/provenance rules;
- station ownership/isolation;
- SCAN / TAG / OPEN / DECIDE server validation;
- hard-locked decision colors.

## Runtime acceptance

### Identity
1. Alya Putri presents with a coherent feminine NPC silhouette rather than the v42 mismatch.
2. Consecutive fictional claimants still visibly vary.
3. Child claimant remains child-coded and is not forced into adult presentation pools.
4. No duplicated hair geometry accumulates on retry/next case.
5. Grounding, head connection, facing and outfit details remain intact.

### Bahasa Indonesia
6. With Roblox locale set to Indonesian, the main case HUD uses Indonesian terminology.
7. Case File evidence labels read PINDAI / TAG / BUKA and pemilik / penerbangan / berat / pengambil / isi / catatan.
8. RETURN / STORE / QUARANTINE / SECURITY are shown to the Indonesian player as KEMBALIKAN / SIMPAN / ISOLASI / KEAMANAN while server decision IDs remain unchanged.
9. Scanner, tag and open proximity prompts are localized for the Indonesian player.
10. Common routine scan/anomaly wording is understandable Indonesian rather than raw specialist English.
11. Mystery names/outcomes remain canonically identical in meaning.
12. English Roblox locale remains unchanged and fully functional.
13. Credits/XP/Index/Archive/serialized inventory remain intact.
14. Exact-source deploy receipt must match the merged source before claiming LIVE.

## Close condition

After one Indonesian-locale screenshot pass plus one English fallback pass and normal case-loop QC, M4-E.2 foundation may be marked STABLE. Additional languages are a market-expansion milestone, not a prerequisite for EN/ID stability.
