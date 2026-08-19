# MASTER_PROJECT_STATE — PMD AutoChess Proto

Last Updated: 2026-08-19 19:05 +08:00

## Persistent Authority
- Google Drive = Binary / Asset Authority.
- GitHub `showpei1203/PMD-AutoChess-Proto` = Source / Spec / Validator / diagnostic-text Authority.
- Linear Team `Showpei` / Project `PMD AutoChess Proto` = Development Authority.
- ChatGPT = development workspace only.

## Current Formal Baseline
**v1.06.61 — VXRD A1 Liquid Surface Semantic Authority II + ProjectState Convergence — FORMAL PASS.**

Formal Binary Baseline:
`01_Current_Baseline/PMD_AutoChess_v1_06_61_FORMAL_PASS_BASELINE_A1_LIQUID_SURFACE_SEMANTIC_AUTHORITY_II_20260819.zip`
Drive ID `1VBidko6cYYcOAwTONmDe1p1lK_hTN3VU`.
Formal `Data/Scripts.rvdata` SHA256 `eb5be92748d998bdf90540cba80bd6c3a280493fa874d5bba15fca127ab8ad00`.

GitHub `main` canonical Formal tail = 647 Scripts, indices 0..646:
- 642 / ID 1065700 / v1.06.57
- 643 / ID 1065800 / v1.06.58
- 644 / ID 1066100 / v1.06.61
- 645 / ID 250 / Main
- 646 / ID 251 / terminator
v1.06.61 source SHA256 `a07d64dafa83d30958edd6045281f820c9e08831ea56757d0e977e8b58461d7d`.
Formal main promotion merge commit `49f966b548b8e2e4d485cf55839bd03c1c7598cb`.

## v1.06.61 Accepted A1 Liquid Semantic Authority
User-confirmed native VX semantics:
- kind4 / base2240 = natural grass-ground visible-bottom water.
- kind6 / base2336 = castle / stone artificial-floor visible-bottom water.
- kind8 / base2432 = rough dirt / cave-ground visible-bottom water.
- kind10 / base2528 = other artificial / non-natural-floor visible-bottom water.
- kind14 / base2720 = lava.

Formal Hunt mapping:
- H02 = kind4 / 2240.
- H07 = kind8 / 2432; Windows visual PASS on 2026-08-19 (`h07水正常`).
- H12 = kind4 / 2240.
- H17 = kind4 / 2240.
Water scope stays H02/H07/H12/H17; native A1, rectangle-only, blocked, A2 shoreline, no rivers/bridges. kind14 is registered as lava only; no automatic H19 lava expansion.

## Map091 — FORMAL PASS / SEALED
SHO-21 Done on Windows/RMVX 2026-08-19.
Accepted evidence: source/page/graphics/trigger/list 49/49, semantic deep clones 49/49, parser 12/12, FIXED/CONTROL/SHARED PASS, Hunt/Floor matrix 126/126, H07 runtime events/plan 9/9, Game_Map Marshal PASS, Hunt-session Marshal PASS, Map090/Map091 mutation 0.
Legacy v1.06.49 missing Encounter/Rare/Elite/Info audit is historical expected-nonblocking after v1.06.52 Hunt filtering.
Future Map091 changes are issue-driven only.

## Gate 2 Script Runtime Seal
SHO-41 Water Semantic Refinement II = Done.
SHO-46 Gate 2 Script Seal = Done by composite Windows evidence.
v1.06.61b aggregate FAIL was TEST-only and caused solely by `map091_harness_missing`; all Production-facing gates passed. Corrected v1.06.61c changes no Production byte and requires no user rerun.

## Sealed Runtime
- Gate 1 structural Random Hunt SEALED.
- Battle Presentation SEALED / issue-driven only.
- v1.06.54 Landmark single-prop semantic/collision PASS.
- v1.06.55 Route Safety SEALED.
- v1.06.56 real map Loading overlay SEALED.
- v1.06.57 vegetation expansion Windows visual PASS.
- v1.06.58 visible-bottom water PASS.
- v1.06.61 A1 liquid semantic + ProjectState convergence FORMAL PASS.
- Map091 shared Event Template Library FORMAL PASS / SEALED.

## Gate 2 Remaining Work
Gate 2 overall remains In Progress only for dedicated visual/content asset coverage. Script/runtime Gate 2 work is sealed. Current user direction is to prioritize scripts; do not drift into image generation unless explicitly requested.

## Active Script Phase — Gate 3 Hunt Risk / Reward Curve
Linear SHO-50 `Gate 3 — Hunt Risk / Reward Curve Baseline Audit I` is In Progress.
Roadmap authority from archived v1.06.30 handoff:
1. tune deeper-floor rarity and Elite frequency;
2. tune completion bonus versus retreat value;
3. provide clear run accounting/summary for battles, treasures, recruits, Rare/Elite, loot and floors cleared;
4. avoid junk materials without a real economic sink.

Phase I is audit only. Do not rebalance values until current formulas and session accounting are measured and proven. TEST-only instrumentation may be added; no Production balance change yet.

## Known Metadata Debt
SHO-47: Windows title bar still says `PMD AutoChess Proto v1.05.40` because captured `Game.ini` hardcodes that title. Metadata/UI only; low priority.

## Immutable Rules
- No automatic B/C/D/E scatter/stamping.
- v1.06.44 Landmark runtime IDs remain revoked.
- Map090 = Random Hunt runtime map; Map091 = shared H01–H21 Event Template Library.
- Deterministic Hunt generation must remain stable unless a future issue explicitly changes it.
- Gate 3 Audit I must not modify Battle AI, damage, attack speed, Focus-C2, spatial endpoints, or species acquisition.

## Editor / Documentation Rule
Any functional delivery changing `Data/Scripts.rvdata`, `Data/Map091.rvdata`, or another Data file requires completely closing RPG Maker VX before overwrite, then reopening RMVX. Every functional delivery requires synchronized Traditional Chinese tutorial/usage documentation.
