# CURRENT_HANDOFF — PMD AutoChess Proto

Last Updated: 2026-08-18 21:37 +08:00

## Persistent Authority
Migration is complete. Do not rebuild or roll it back unless a persistent Authority source is genuinely inaccessible.
- Drive = Binary / Asset Authority
- GitHub = Source / Spec / Validator / diagnostic-text Authority
- Linear = Development Authority
- ChatGPT = workspace only

## Current Formal Baseline
**v1.06.58 — VXRD Water-Bottom Autotile Pair Authority I — FORMAL PASS.**
Formal Baseline ZIP Drive ID `1bpvrm1OQBDPMwU8ac06Q-zmZSvTOTHIQ`.

Canonical Formal GitHub tail:
- 642 / 1065700 / v1.06.57
- 643 / 1065800 / v1.06.58
- 644 / 250 / Main
- 645 / 251 / terminator
Total 646 Scripts. `main` remains v1.06.58 Formal.

## User Direction
**Prioritize script/runtime progression.** SHO-42 art pipeline may remain prepared, but do not drift into image generation unless the user explicitly requests art work.

## Current Script Test Build — v1.06.60 TEST SUITE
Use:
`PMD_AutoChess_v1_06_60_TEST_SUITE_MAP091_A1_MATRIX_20260818.zip`
Drive Test Build ID `1KAk9KBZmZXWOmiL2tCGQ64aJHhM56Azl`.
ZIP SHA256 `5f256363aafedd7458fb5b31828ad58a5637c1374c987810d8527b4f65e93d08`.
Scripts.rvdata SHA256 `6430d0f7b65923396a1676f968b6c381a3721542a881f8daa174efbdeb48bd3c`.

648 Scripts:
- 0..643 = Formal v1.06.58 byte-exact preserved
- 644 / ID 1065910 = A1 Interactive Matrix Probe v1.06.59a
- 645 / ID 1066000 = Map091 Full Acceptance Harness v1.06.60
- 646 = Main
- 647 = terminator

This is TEST-only. Do not promote this script ordering directly to Formal Source.

## Test 1 — SHO-41 A1 Gravel-Water Identification
Old one-candidate v1.06.59 H07=2336 probe is deprecated.

Context: RMVX Test Play, H07 / Map090.
Control: **plain F5** only. The combined binary excludes Shift/Ctrl/Alt from the water shortcut.

Pages:
1. 2240 / 2288 / 2336 / 2384
2. 2048 / 2096 / 2144 / 2192
3. 2432 / 2480 / 2528 / 2576
4. 2624 / 2672 / 2720 / 2768

Panels use real RGSS2 `Tilemap` rendering. Formal H07 remains base 2240; Map090 and Hunt mapping are not changed.
User only needs to report the `base` whose panel shows the requested clear water with gravel/pebble bed. If none matches, one screenshot is enough.
Output: `PMD_VXRD_A1MatrixProbe_LATEST.log`.

## Test 2 — SHO-21 Map091 Full Acceptance
SHO-21 is now In Progress.
Context: any active Random Hunt floor on Map090.
Control: **SHIFT+F5**.

Independent offline Formal Map091 audit already PASS:
- source events 49/49
- source pages 49
- graphics/lists/triggers 49/49
- deep Marshal clones 49/49
- whole Map091 Marshal roundtrip PASS
- H01–H21 × Floors 1–6 = 126/126, BAD=0
- role distribution: Entrance 1, Exit 1, Retreat 1, Treasure 1, Recovery 1, Info 4, Encounter 24, Rare 8, Elite 8.

Runtime harness additionally checks:
- v1.06.49 Template Authority audit
- HUNT/FLOOR/WEIGHT/MAX/UNIQUE/NO_REPEAT semantics
- synthetic FIXED/CONTROL/SHARED + runtime-ID semantics
- current materialized Map090 template events/source metadata
- runtime plan count alignment
- non-destructive `Marshal.dump/load($game_map)` preservation
- Hunt-session Marshal roundtrip

Output: `PMD_VXRD_Map091Acceptance_LATEST.log` plus PASS/FAIL overlay.
No Map090/Map091 mutation.

## Accepted / Sealed Gate 2 State
- v1.06.54 single-prop Landmark semantic/presence/collision PASS
- v1.06.55 Route Safety SEALED
- v1.06.56 real Loading overlay SEALED
- v1.06.57 vegetation expansion visual PASS
- v1.06.58 visible-bottom water PASS

Accepted water mapping:
- H02 = 2048
- H07/H12/H17 = 2240
- 2096 revoked
- native A1, rectangle-only, blocked, A2 shoreline, no rivers/bridges

Accepted Landmark Hunts: H01/H02/H03/H04/H06/H07/H09/H14/H16/H19.
Dedicated-art deferred: H05/H08/H10/H11/H12/H13/H15/H17/H18/H20/H21.

## Immutable Rules
- No automatic B/C/D/E scatter/stamping.
- v1.06.44 Landmark runtime IDs remain revoked.
- Map090 = Random Hunt runtime map.
- Map091 = H01–H21 shared Event Template Library.
- Gate 1 structure / Battle Presentation SEALED / issue-driven only.
- No Battle AI, damage, attack speed, Focus/C2, rewards, progression, or spatial-endpoint changes for this work.

## Immediate Next
1. Windows run v1.06.60 SHIFT+F5 and seal SHO-21 if PASS.
2. H07 plain-F5 matrix identifies gravel-bottom base; only then create production water semantic candidate.
3. Continue Gate 2 script/runtime work before returning to art.

## Installation / Documentation Rule
v1.06.60 changes `Data/Scripts.rvdata`. **Completely close RPG Maker VX before overwrite, then reopen RMVX.** `Data/Map091.rvdata` is unchanged. Every functional delivery requires synchronized Traditional Chinese tutorial/usage documentation.
