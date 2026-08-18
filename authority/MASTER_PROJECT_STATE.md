# MASTER_PROJECT_STATE — PMD AutoChess Proto

Last Updated: 2026-08-18 21:37 +08:00

## Persistent Authority
- Google Drive = Binary / Asset Authority.
- GitHub `showpei1203/PMD-AutoChess-Proto` = Source / Spec / Validator / diagnostic-text Authority.
- Linear Team `Showpei` / Project `PMD AutoChess Proto` = Development Authority.
- ChatGPT = development workspace only.

## Current Formal Baseline
**v1.06.58 — VXRD Water-Bottom Autotile Pair Authority I — FORMAL PASS.**
Formal Baseline ZIP Drive ID `1bpvrm1OQBDPMwU8ac06Q-zmZSvTOTHIQ`.

Canonical Formal Script tail:
- 642 / ID 1065700 / v1.06.57
- 643 / ID 1065800 / v1.06.58
- 644 / ID 250 / Main
- 645 / ID 251 / terminator
Total = 646 Scripts, indices 0..645.
`main` remains Formal v1.06.58. `develop` may contain TEST-only diagnostics/specs and is not automatically promotable.

## Accepted / Sealed Gate 2 chain
- v1.06.54 Single-Prop Landmark semantic/presence/collision PASS.
- v1.06.55 Route Safety PASS / SEALED; broader stress 840/840 production-like + 11 adversarial, failures 0, unsafe hard-Landmark removals 10, topology rewrite 0.
- v1.06.56 real Battle-style Random Hunt Loading overlay PASS / SEALED.
- v1.06.57 H02/H03/H06/H07/H16 vegetation Landmark expansion Windows visual PASS.
- v1.06.58 H02/H07/H12/H17 visible-bottom water Windows visual PASS.

Accepted water mapping:
- H02 = A1 base 2048.
- H07/H12/H17 = A1 base 2240.
- old active base 2096 revoked.
- native A1 animated/autotile, A2 shoreline, rectangle-only, blocked water, no rivers/bridges.

## Active Script Test Suite — v1.06.60 TEST-ONLY
Current script-focused work is consolidated into:
`PMD_AutoChess_v1_06_60_TEST_SUITE_MAP091_A1_MATRIX_20260818.zip`
Drive Test Build ID `1KAk9KBZmZXWOmiL2tCGQ64aJHhM56Azl`.
ZIP SHA256 `5f256363aafedd7458fb5b31828ad58a5637c1374c987810d8527b4f65e93d08`.
Scripts.rvdata SHA256 `6430d0f7b65923396a1676f968b6c381a3721542a881f8daa174efbdeb48bd3c`.

Diagnostic binary = 648 Scripts:
- 0..643 Formal v1.06.58 preserved byte-exact.
- 644 / ID 1065910 = A1 Interactive Matrix Probe.
- 645 / ID 1066000 = Map091 Full Acceptance Harness.
- 646 Main.
- 647 terminator.
This layout is TEST-only and must not be promoted directly.

### SHO-41 Water Semantic Refinement II
User-authoritative target = clear water with gravel/pebble bed, visually two editor palette cells right of accepted H07/H12/H17 water.
Old single-candidate H07=2336 probe is deprecated.
Current method: H07 + **plain F5** opens real RGSS2 Tilemap matrix, four pages / 16 A1 bases. Formal H07 remains 2240 and Map090 is not mutated.
Output: `PMD_VXRD_A1MatrixProbe_LATEST.log`.

### SHO-21 Map091 Full Acceptance
Now In Progress.
Independent offline audit of Formal `Data/Map091.rvdata` already PASS:
- source events 49/49;
- source pages 49;
- page graphics/lists/triggers 49/49;
- deep Marshal clones 49/49;
- Map091 Marshal roundtrip PASS;
- role distribution: Entrance 1, Exit 1, Retreat 1, Treasure 1, Recovery 1, Info 4, Encounter 24, Rare 8, Elite 8;
- H01–H21 × Floors 1–6 = 126/126, BAD=0.

Windows/RMVX remaining acceptance: any active Random Hunt floor + **SHIFT+F5**. Harness checks parser semantics, FIXED/CONTROL/SHARED synthetic contract, current materialized events/source metadata, runtime plan alignment, non-destructive `$game_map` Marshal roundtrip and Hunt-session Marshal roundtrip.
Output: `PMD_VXRD_Map091Acceptance_LATEST.log` plus temporary PASS/FAIL overlay.

## Landmark / Asset state
Accepted Landmark Hunts: H01/H02/H03/H04/H06/H07/H09/H14/H16/H19.
Dedicated-art deferred: H05/H08/H10/H11/H12/H13/H15/H17/H18/H20/H21.
SHO-42 asset production pipeline is prepared, but **current user direction is to prioritize script/runtime progression**. Do not switch into image generation unless explicitly requested.

## Immutable / no-regression rules
- no automatic B/C/D/E scatter/stamping;
- v1.06.44 Landmark runtime IDs remain revoked;
- Map090 = Random Hunt Runtime Map;
- Map091 = H01–H21 shared Event Template Library;
- Gate 1 structure / accepted Battle Presentation remain SEALED / issue-driven only;
- no Battle AI, damage, attack speed, Focus/C2, rewards, progression, or spatial-endpoint changes for Gate 2 diagnostic work.

## Immediate Next Development
1. Run/close SHO-21 Windows Map091 acceptance using SHIFT+F5.
2. Identify exact gravel-bottom A1 base through H07 plain-F5 matrix and then create a production semantic mapping candidate only after visual confirmation.
3. Continue script/runtime Gate 2 work before returning to art production.

## Editor / Documentation Rule
Any delivery updating `Data/Scripts.rvdata`, `Data/Map091.rvdata`, or another Data file requires: completely close RPG Maker VX before overwrite, then reopen RMVX. Every functional delivery must include synchronized Traditional Chinese tutorial/usage documentation.
