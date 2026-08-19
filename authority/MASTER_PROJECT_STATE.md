# MASTER_PROJECT_STATE — PMD AutoChess Proto

Last Updated: 2026-08-20 06:00 +08:00

## Persistent Authority
- Google Drive = Binary / Asset Authority.
- GitHub `showpei1203/PMD-AutoChess-Proto` = Source / Spec / Validator / diagnostic-text Authority.
- Linear Team `Showpei` / Project `PMD AutoChess Proto` = Development Authority.
- ChatGPT = development workspace only.

## User Direction
Prioritize script/runtime progression. Gate 2 dedicated-art work remains parallel/secondary unless explicitly requested.

## Current Formal Baseline
**v1.06.64 — Gate 3 Run Accounting Semantic / Persistence I — FORMAL WINDOWS PASS / SEALED.**

Formal Binary Baseline:
`01_Current_Baseline/PMD_AutoChess_v1_06_64_FORMAL_PASS_BASELINE_GATE3_RUN_ACCOUNTING_SEMANTIC_PERSISTENCE_I_20260820.zip`
Drive ID `1xmWQZwWBrpRBNWYY_s1WuuJ_cernsp0X`.
Formal ZIP SHA256 `274e0d348942c089a399c6fcc4f1496160557f03ed69f1fc3085c88ed1d02a8b`.
Formal `Data/Scripts.rvdata` SHA256 `d1abb3249c54b55703fc05991a11da10090db625f9ca3176e60cb4dfda82fda8`.

Windows acceptance evidence `PMD_GATE3_RunAccounting_LATEST.log`:
- RESULT=PASS.
- legacy fixture 9 = 7 immediate + 2 completion.
- new fixture 9 = 7 immediate + 2 completion.
- Marshal persistence PASS.
- live H02 legacy migration PASS.
- ProjectState schema45 / version1.06.64 PASS.
- RNG_CALLS=0 / REWARD_GRANT=0 / MAP_REGEN=0 / SESSION_MUTATION=0.

Linear SHO-53 = Done / SEALED.

## GitHub Formal Source
Actual canonical script files on `main` are 650 Scripts, indices 0..649:
- 644 / ID1066100 / v1.06.61.
- 645 / ID1066200 / v1.06.62.
- 646 / ID1066300 / v1.06.63.
- 647 / ID1066400 / v1.06.64.
- 648 / ID250 / Main.
- 649 / ID251 / terminator.

v1.06.64 source SHA256 `a17f14791cfb50296caefc829931f66d0f6c8fb6ec7e9072d09dfa0629d288ed`.
Formal source promotion commit `579ba711e6c8f2326291f0a69fcecc10c0de5ee0`.
Formal promotion evidence `tests/FORMAL_PROMOTION_v1.06.64.log` = PASS.
Inactive one-shot manifest workflow was removed by commit `d4c70f7647edd072ce427b97383e0c03933f4562`.

### Known source metadata debt
`exported_scripts/SCRIPT_INDEX.tsv` and `SCRIPT_ORDER.md` still describe the pre-promotion v1.06.62 tail because repository GitHub Actions did not execute attempted refresh workflows. Actual canonical script files and Formal Binary are correct. Treat stale tail rows as metadata debt, not Runtime rollback. Refresh no later than a future Formal source maintenance pass.

Concurrent map-generation Authority on `main` is Shared Map Layered Generation Authority v2.5 and must be preserved. Do not reset `main` to an older Runtime-only tree.

## Accepted Gate 3 Runtime
### v1.06.62 — Floor-Depth Risk Curve
- deepest-floor Rare bonus +12 pp; Elite +15 pp; cap85.
- Tier endpoints: T1 R18→30/E0→0; T2 R28→40/E30→45; T3 R40→52/E42→57; T4 R52→64/E55→70; T5 R65→77/E70→85.
- deterministic seed-derived promotion; no extra RNG.

### v1.06.63 — Completion Incentive
- full-clear completion rolls by Tier = 2 / 2 / 3 / 4 / 5.
- retreat / defeat / partial-clear Completion Bonus = 0.
- normal loot policy unchanged.

### v1.06.64 — Run Accounting
- `loot_results` = legacy-compatible total.
- `immediate_loot_results` = in-run results excluding Completion Bonus.
- `completion_bonus_results` = Completion-only actual results.
- active legacy migration and completed-result fallback SEALED.
- Marshal persistence SEALED.

## Current Production Candidate — v1.06.65
Linear SHO-54 `v1.06.65 — Gate 3 Integrated Run Summary / Risk-Reward Seal I` = In Progress.

Purpose: integrate v1.06.62 + v1.06.63 + v1.06.64 into one read-only Gate 3 Run Summary Authority, then formally seal Gate 3 Risk / Reward if Windows PASS.

Production Candidate:
`02_Current_Development/PMD_AutoChess_v1_06_65_CUMULATIVE_OVERWRITE_GATE3_INTEGRATED_RUN_SUMMARY_RISK_REWARD_SEAL_I_20260820.zip`
Drive ID `1ibVoQ5OM-BzJ1ut7iALmcXrXX4pmUgpG`.
ZIP SHA256 `65fb786aaf3d67bae5498ac3fd964cadefa99292018ea840943be71fb7b18374`.
Scripts SHA256 `b71c05300d6003cc0e03cca3be1dd2a3b27d282643fc17c3d3fbf966fa61cab5`.
Production source SHA256 `c4cb4fc5caa123a43353a1170e43f70da5363402de934efdb552e63cb0d9344c`.
651 Scripts: Formal v1.06.64 indices0..647 byte-exact preserved; v1.06.65 index648/ID1066500; Main649; terminator650.

Windows Test Build:
`03_Test_Builds/PMD_AutoChess_v1_06_65a_TEST_BUILD_GATE3_INTEGRATED_SEAL_ACCEPTANCE_20260820.zip`
Drive ID `1Elimfw7jGarxFlWTyytstjmKkoixIo-W`.
ZIP SHA256 `7f4528c22322397f41005fb9a52478047bb51562557f0dfca639f9f9b0f5ba7f`.
Test Scripts SHA256 `a614bb0547a4f60b5930cfbb0d3144d4631b2044d7abe2d8939c8eeec6139b4c`.
652 Scripts; TEST index649/ID1066510; Main650; terminator651.

Static acceptance PASS:
- v1.06.62 / .63 / .64 sub-audits PASS.
- risk monotonic + exact endpoints PASS.
- completion curve 2/2/3/4/5 PASS.
- complete / retreat / defeat / legacy completed fixtures PASS.
- Marshal persistence PASS.
- summary input mutation0.
- Reward/RNG/Map change0.

Windows plain-F5 acceptance remains pending. Expected log: `PMD_GATE3_IntegratedSeal_LATEST.log`.

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
- v1.06.64 run accounting SEALED.
- No automatic B/C/D/E scatter/stamping.
- v1.06.44 Landmark runtime IDs remain revoked.
- Map090 = Random Hunt Runtime; Map091 = shared Event Template Library.

## Editor / Documentation Rule
Any functional delivery changing `Data/Scripts.rvdata`, `Data/Map091.rvdata`, or another Data file requires completely closing RPG Maker VX before overwrite, then reopening RMVX. Every functional delivery requires synchronized Traditional Chinese tutorial/usage documentation.
