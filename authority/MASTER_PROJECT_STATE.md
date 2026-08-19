# MASTER_PROJECT_STATE — PMD AutoChess Proto

Last Updated: 2026-08-19 22:40 +08:00

## Persistent Authority
- Google Drive = Binary / Asset Authority.
- GitHub `showpei1203/PMD-AutoChess-Proto` = Source / Spec / Validator / diagnostic-text Authority.
- Linear Team `Showpei` / Project `PMD AutoChess Proto` = Development Authority.
- ChatGPT = development workspace only.

## User Direction
Prioritize script/runtime progression. Gate 2 dedicated-art work remains parallel/secondary unless explicitly requested.

## Current Formal Baseline
**v1.06.63 — Gate 3 Completion Incentive + Retreat Clarity I — FORMAL WINDOWS PASS.**

Formal Binary Baseline:
`01_Current_Baseline/PMD_AutoChess_v1_06_63_FORMAL_PASS_BASELINE_GATE3_COMPLETION_INCENTIVE_RETREAT_CLARITY_I_20260819.zip`
Drive ID `1ge_N7CxmLjLoMqfVz66yVNnF40w9kJFD`.
Formal `Data/Scripts.rvdata` SHA256 `c78066713e8a96822c7f89ec200a8d1f341d3c1edb452dc4932a86ac5d481205`.

Windows acceptance evidence `PMD_GATE3_CompletionIncentive_LATEST.log`:
- RESULT=PASS.
- completion curve = 2/2/3/4/5.
- normal loot policy unchanged.
- retreat / defeat / partial-clear completion bonus = 0.
- ProjectState schema44 / version1.06.63 PASS.
- RNG_CALLS=0 / REWARD_GRANT=0 / MAP_REGEN=0 / SESSION_MUTATION=0.

Linear SHO-52 = Done / SEALED.

## GitHub Formal Source
Actual canonical script files on `main` are 649 Scripts, indices 0..648:
- 644 / ID1066100 / v1.06.61.
- 645 / ID1066200 / v1.06.62.
- 646 / ID1066300 / v1.06.63.
- 647 / ID250 / Main.
- 648 / ID251 / terminator.

v1.06.63 source SHA256 `bf3ed879de7ab6f6a435040311c32a418c155a28ea03e307643e63dee5a78aa8`.
Formal source promotion commit `435b758f4b7cb4024e7c87b9bcc0ba5d22446fbe`.
Formal promotion evidence `tests/FORMAL_PROMOTION_v1.06.63.log` = PASS.

### Known source metadata debt
`exported_scripts/SCRIPT_INDEX.tsv` and `SCRIPT_ORDER.md` still describe the pre-promotion v1.06.62 tail because repository Actions did not execute the attempted self-refresh workflow. The actual canonical script files above and Formal Binary are correct. The inactive refresh workflow/trigger were removed. Refresh both manifests before or together with the next Formal source promotion; do not treat the stale tail rows as Runtime rollback.

Concurrent map-generation Authority work on `main` has advanced independently (v2.5 line) and must be preserved. Do not reset `main` to an older Runtime-only tree.

## Accepted Gate 3 Runtime
### v1.06.62 — Floor-Depth Risk Curve
- deeper floors progressively raise Rare/Elite effective rates.
- deepest-floor Rare bonus +12 pp; Elite +15 pp; cap85.
- deterministic hash promotion; no extra RNG calls.
- settlement exposes existing battle/recruit/treasure/recovery/Rare/Elite/loot fields.

### v1.06.63 — Completion Incentive
- full-clear completion rolls by Tier = 2 / 2 / 3 / 4 / 5.
- only Tier5 changed from 4 to 5.
- normal Battle/Treasure/Rare/Elite loot max policy unchanged.
- retreat/defeat/partial-clear completion bonus remains 0.
- already-granted immediate results remain retained.
- no new items/materials/currencies.

## Current Production Candidate — v1.06.64
Linear SHO-53 `v1.06.64 — Gate 3 Run Accounting Semantic / Persistence I` = In Progress.

Confirmed accounting ambiguity: legacy v1.06.08 `loot_results` counts all matching Hunt loot-pool results, including Completion Bonus, because Completion resolves before final stats snapshot. Grant is not duplicated, but immediate loot and completion-only loot are semantically conflated.

v1.06.64 candidate semantics:
- `loot_results` remains legacy-compatible total.
- `immediate_loot_results` = in-run loot excluding Completion Bonus.
- `completion_bonus_results` = Completion-only actual results.
- classification uses existing completion context marker.
- new runs initialize split counters.
- active legacy v1.06.63 run safely migrates total -> immediate, completion=0.
- legacy completed result derives completion count from `completion_bonus[:results]` and immediate = total-completion.
- settlement remains four lines and distinguishes `途中掉落` from `通關 Bonus`.
- reward / RNG / Battle / Map / Item content unchanged.

Production Candidate:
`02_Current_Development/PMD_AutoChess_v1_06_64_CUMULATIVE_OVERWRITE_GATE3_RUN_ACCOUNTING_SEMANTIC_PERSISTENCE_I_20260819.zip`
Drive ID `1ew90l2THkDqtURm3gDv6gkyelUhbwCUF`.
ZIP SHA256 `274e0d348942c089a399c6fcc4f1496160557f03ed69f1fc3085c88ed1d02a8b`.
Scripts.rvdata SHA256 `d1abb3249c54b55703fc05991a11da10090db625f9ca3176e60cb4dfda82fda8`.
Production source SHA256 `a17f14791cfb50296caefc829931f66d0f6c8fb6ec7e9072d09dfa0629d288ed`.
650 Scripts: Formal v1.06.63 indices0..646 preserved; v1.06.64 index647/ID1066400; Main648; terminator649.

Windows Test Build:
`03_Test_Builds/PMD_AutoChess_v1_06_64a_TEST_BUILD_GATE3_RUN_ACCOUNTING_ACCEPTANCE_20260819.zip`
Drive ID `1dSaI1hH2ZTGzAl1tWPL-OXoSzaD05EMl`.
ZIP SHA256 `2f4eda23db0b38b5557738208b472c0538e46adb24bf2795a9f591468fac183b`.
Test Scripts SHA256 `a41e0ac0a89c0a5cbe2a2f5d061d16712e65d9cd28e34b0317bdb8d6ae8f2340`.
651 Scripts; TEST index648/ID1066410.

Static acceptance already PASS: Ruby syntax, semantic split fixtures, legacy active migration, first-post-upgrade count, Marshal persistence, 12 legacy fields preserved. Windows plain-F5 evidence remains pending.

## Sealed Runtime / No Regression
- Gate 1 structural Random Hunt SEALED.
- Battle Presentation SEALED / issue-driven only.
- Map091 H01–H21 Event Template Library FORMAL PASS / SEALED.
- v1.06.54 Landmark semantic/collision PASS.
- v1.06.55 Route Safety SEALED.
- v1.06.56 Loading overlay SEALED.
- v1.06.57 vegetation visual PASS.
- v1.06.58 visible-bottom water PASS.
- v1.06.61 A1 liquid semantic PASS.
- v1.06.62 floor-depth risk curve SEALED.
- v1.06.63 completion curve SEALED.
- No automatic B/C/D/E scatter/stamping.
- v1.06.44 Landmark runtime IDs remain revoked.
- Map090 = Random Hunt Runtime; Map091 = shared Event Template Library.

## Editor / Documentation Rule
Any functional delivery changing `Data/Scripts.rvdata`, `Data/Map091.rvdata`, or another Data file requires completely closing RPG Maker VX before overwrite, then reopening RMVX. Every functional delivery requires synchronized Traditional Chinese tutorial/usage documentation.
