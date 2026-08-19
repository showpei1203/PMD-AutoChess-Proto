# MASTER_PROJECT_STATE — PMD AutoChess Proto

Last Updated: 2026-08-19 22:20 +08:00

## Persistent Authority
- Google Drive = Binary / Asset Authority.
- GitHub `showpei1203/PMD-AutoChess-Proto` = Source / Spec / Validator / diagnostic-text Authority.
- Linear Team `Showpei` / Project `PMD AutoChess Proto` = Development Authority.
- ChatGPT = development workspace only.

## User Direction
Prioritize script/runtime progression. Gate 2 dedicated-art work remains parallel/secondary unless explicitly requested.

## Current Formal Baseline
**v1.06.62 — Gate 3 Floor-Depth Risk Curve + Settlement Visibility I — FORMAL PASS.**

Formal Binary Baseline:
`01_Current_Baseline/PMD_AutoChess_v1_06_62_FORMAL_PASS_BASELINE_GATE3_FLOOR_DEPTH_RISK_SETTLEMENT_I_20260819.zip`
Drive ID `1BIccvXgLp2Deu_RPYfT_dmEm43S5NXCW`.
Formal `Data/Scripts.rvdata` SHA256 `61030225160f7ba2e1c12390183c841bcf038644c7b49fc2eb5069217129f190`.

GitHub `main` canonical Formal tail = **648 Scripts**, indices 0..647:
- 642 / ID1065700 / v1.06.57
- 643 / ID1065800 / v1.06.58
- 644 / ID1066100 / v1.06.61
- 645 / ID1066200 / v1.06.62
- 646 / ID250 / Main
- 647 / ID251 / terminator
v1.06.62 source SHA256 `bed1c3410378944656ff5f4a6b62615942bc02e27e74ef39bae8e4c42a1ee980`.
Formal source promotion preserved the parallel v2.4 map placement authority on `main`; stale duplicate terminator was removed. `develop` contains current `main` as an ancestor (`behind_by=0`) while retaining diagnostics/assets.

## v1.06.62 Accepted Gate 3 Floor-Depth Curve
Windows/RMVX v1.06.62b acceptance = PASS.
- Rare final-depth bonus +12 percentage points.
- Elite final-depth bonus +15 percentage points; Tier1 remains Elite=0.
- Effective special-room cap 85%.
- Existing RNG call order/count preserved; depth promotion uses deterministic seed-derived hash.
- Settlement exposes existing battle/win/loss/escape/recruit/treasure/recovery/Rare/Elite/loot accounting.
- Completion Bonus remains 2/2/3/4/4 in v1.06.62.
- SHO-51 Done / sealed.

Accepted curves:
- T1: Rare 18→24→30 / Elite 0.
- T2: Rare 28→32→36→40 / Elite 30→35→40→45.
- T3: Rare 40→43→46→49→52 / Elite 42→46→50→53→57.
- T4: Rare 52→55→58→61→64 / Elite 55→59→63→66→70.
- T5: Rare 65→67→70→72→75→77 / Elite 70→73→76→79→82→85.

## Active Production Candidate — v1.06.63
**v1.06.63 — Gate 3 Completion Incentive + Retreat Clarity I — UNPASSED.**
Linear SHO-52 In Progress.

Drive Current Development:
`PMD_AutoChess_v1_06_63_CUMULATIVE_OVERWRITE_GATE3_COMPLETION_INCENTIVE_RETREAT_CLARITY_I_20260819.zip`
Drive ID `1rcFIdAHDQnnl8CcgsPX_8AcgHfpFkJVt`.
ZIP SHA256 `d68dc37c9f2977ef9c4892e13afff1fcbc2a6460659da8dd7f1324b58ddcdb3c`.
Scripts.rvdata SHA256 `c78066713e8a96822c7f89ec200a8d1f341d3c1edb452dc4932a86ac5d481205`.
Production source SHA256 `bf3ed879de7ab6f6a435040311c32a418c155a28ea03e307643e63dee5a78aa8`.

Production layout = 649 Scripts:
- Formal v1.06.62 0..645 byte-exact preserved.
- 646 / ID1066300 / v1.06.63 Production.
- 647 Main; 648 terminator.

### v1.06.63 Completion Authority Candidate
- Target full-clear Completion rolls: **T1=2, T2=2, T3=3, T4=4, T5=5**.
- Only Tier5 changes from 4 to 5.
- Completion remains full-clear only.
- Retreat / defeat completion bonus remains 0.
- Immediate recruit/loot/treasure results remain retained on retreat/defeat.
- No partial-clear bonus and no new items/materials/currencies.
- Normal Battle/Treasure/Rare/Elite loot policy remains delegated unchanged; 5-roll override is gated only by v1.06.63 completion context marker.
- Settlement wording explicitly distinguishes Complete / Retreat / Defeat completion eligibility.

## Current Windows Test Build
**v1.06.63a TEST-only**
Drive ID `1vHRvjamHZhp9pqY43j1OZqmuBW5HzhD5`.
ZIP SHA256 `06f72f1018c5bfd0b0f13f98d9734101ae6d0770d484787c344d60c799a62f28`.
650 Scripts; TEST index647 / ID1066310; Main648; terminator649.
Read-only F5 acceptance; RNG calls 0, reward grant 0, map regeneration 0, session mutation 0.
Expected log `PMD_GATE3_CompletionIncentive_LATEST.log`.

## Previously Sealed Runtime
- Gate1 structural Random Hunt SEALED.
- Battle Presentation SEALED / issue-driven only.
- v1.06.54 Landmark single-prop semantic/collision PASS.
- v1.06.55 Route Safety SEALED.
- v1.06.56 real Loading overlay SEALED.
- v1.06.57 vegetation expansion visual PASS.
- v1.06.61 A1 water semantics / ProjectState convergence PASS.
- Map091 shared Event Template Library FORMAL PASS / SEALED.
- SHO-50 Gate3 Risk/Reward Baseline Audit I PASS / SEALED.
- SHO-51 v1.06.62 Floor-Depth Risk Curve PASS / SEALED.

## Parallel Map/Asset Authority
Latest v2.4 map placement/layer authority on `main` is preserved. Do not regress or remove it while advancing Runtime scripts. Gate2 dedicated-art SHO-42 remains separate from Gate3 script work.

## Known Metadata Debt
SHO-47 Low: `Game.ini` title still displays `PMD AutoChess Proto v1.05.40`. UI metadata only; not Runtime rollback.

## Immutable Rules
- No automatic B/C/D/E scatter/stamping.
- v1.06.44 Landmark runtime IDs revoked.
- Map090 = Random Hunt runtime map; Map091 = shared H01–H21 Event Template Library.
- v1.06.62 floor-depth curve sealed unless a regression issue proves otherwise.
- No Battle AI, damage, attack speed, Focus-C2, spatial endpoint, or species-acquisition change under SHO-52.

## Editor / Documentation Rule
Any functional delivery changing `Data/Scripts.rvdata`, `Data/Map091.rvdata`, or another Data file requires completely closing RPG Maker VX before overwrite, then reopening RMVX. Every functional delivery requires synchronized Traditional Chinese tutorial/usage documentation.