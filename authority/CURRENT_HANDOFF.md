# CURRENT_HANDOFF — PMD AutoChess Proto

Last Updated: 2026-08-18 19:18 +08:00

## Persistent Authority
Migration is complete. Do not rebuild or roll it back unless a persistent Authority source is genuinely inaccessible.
- Drive = Binary Authority
- GitHub = Source Authority
- Linear = Development Authority
- ChatGPT = workspace only

## Current Formal Baseline
**v1.06.58 — VXRD Water-Bottom Autotile Pair Authority I — FORMAL PASS.**

Formal Baseline ZIP:
`01_Current_Baseline/PMD_AutoChess_v1_06_58_FORMAL_PASS_BASELINE_WATER_BOTTOM_AUTOTILE_PAIR_AUTHORITY_I_20260818.zip`
Drive ID `1bpvrm1OQBDPMwU8ac06Q-zmZSvTOTHIQ`.

## Accepted v1.06.57 / v1.06.58 Results
- v1.06.57 H02/H03/H06/H07/H16 vegetation Landmark expansion: Windows visual PASS.
- v1.06.58 H07/H12/H17 water: user explicitly reported OK.
- H02 current water is also accepted; no forced rework.
- v1.06.56 real Loading overlay remains accepted.
- SHO-22 Route Safety remains Done / SEALED.

## GitHub Source Authority
Former Source-tail blocker is resolved.
PR #2 exact finalizer succeeded, canonical manifests were regenerated, staging was removed, and the stale duplicate terminator was removed after compare audit.

Canonical Formal tail:
- 642 / 1065700 / v1.06.57
- 643 / 1065800 / v1.06.58
- 644 / 250 / Main
- 645 / 251 / terminator
Total 646 Scripts, indices 0..645.

`main` is v1.06.58 Formal Source. `develop` is now ahead only with post-baseline asset/diagnostic work.

## Accepted Water Mapping
- H02 -> A1 base 2048.
- H07 -> A1 base 2240.
- H12 -> A1 base 2240.
- H17 -> A1 base 2240.
- active Random Hunt base 2096 revoked.
- Water remains native A1 animated/autotile, rectangle-only, non-walkable, with A2 shoreline; no rivers/bridges.

## Active SHO-41 — v1.06.59 TEST-ONLY Water Probe
User clarified that the desired gravel/stone-bottom clear water is **two editor palette cells to the right of the accepted H07/H12/H17 water** and visibly uses gravel/pebbles.

A TEST-only diagnostic is ready to falsify candidate base **2336** without changing Formal Authority:
- H07 only changes to 2336 while `$TEST == true`.
- H02 remains 2048.
- H12/H17 remain 2240.
- non-Test Play remains v1.06.58.

Diagnostic ZIP:
`PMD_AutoChess_v1_06_59_TEST_ONLY_GRAVEL_BOTTOM_WATER_PALETTE_PROBE_20260818.zip`
Drive ID `1XNSDuk8OEfVJWvwSWv5vaxtJ5hSy--2-`.
ZIP SHA256 `e5903b3fa73bd7cdb7c999ae0be56bf3393274cdc4708735161270f6595c5b5c`.

Diagnostic binary only = 647 Scripts: v1.06.57 642, v1.06.58 643, probe 644 / ID 1065900, Main 645, terminator 646. Exact probe source is stored under GitHub `diagnostics/`, not canonical `exported_scripts`.

User action: completely close RMVX, overwrite probe package, reopen RMVX, use Test Play, enter H07, then answer whether the water is the intended gravel/pebble-bottom clear water. If not, one H07 screenshot is enough.

## Active SHO-42 — Dedicated Landmark Asset Batch A
PMD `08_Assets` now follows the shared three-project Asset Pipeline folder structure. Dedicated Hunt root:
`08_Assets/11_Biomes/VXRD_Random_Hunt` Drive ID `11wDAZwrVFxvFyAyvwrUd1Qg84xatwux1`.

Batch A:
- H05 -> `relic_moonstone_a.png`
- H08 -> `storm_charged_rock_a.png`
- H10 -> `mystic_rune_stone_a.png`
- H11 -> `ancient_root_a.png`
- H12 -> `ice_shard_a.png`

GitHub:
- `assets/VXRD_LANDMARK_ASSET_PRODUCTION_SPEC.md`
- `assets/ASSET_MANIFEST.csv`
- `tools/asset_validator/validate_vxrd_landmark_atlas.py`
- `tests/ASSET_VALIDATOR_ACCEPTED_SIX_v1.06.58.log`

Validator regression against all six accepted Landmark atlases = **6/6 PASS**.
New art contract: 64×64 RGBA atlas, 2×2 of four independent complete 32×32 props; Approved only enters runtime.

## Landmark Coverage
Accepted: H01/H02/H03/H04/H06/H07/H09/H14/H16/H19.
Deferred dedicated-art Hunts: H05/H08/H10/H11/H12/H13/H15/H17/H18/H20/H21.
Do not fill deferred biomes with semantically unrelated props just to claim coverage.

## Immutable Rules
- No automatic B/C/D/E scatter/stamping.
- v1.06.44 Landmark runtime IDs remain revoked.
- Map090 = Random Hunt runtime map.
- Map091 = H01–H21 shared Event Template Library.
- Gate 1 structure / Battle Presentation SEALED / issue-driven only.
- No Battle AI, damage, attack speed, Focus/C2, rewards, progression, or spatial-endpoint changes for this work.

## Editor / Documentation Rule
If a future functional candidate changes `Data/Scripts.rvdata`, `Data/Map091.rvdata`, or another Data file, completely close RPG Maker VX before overwrite and reopen afterward. Every functional delivery must include synchronized Traditional Chinese tutorial/usage documentation.
