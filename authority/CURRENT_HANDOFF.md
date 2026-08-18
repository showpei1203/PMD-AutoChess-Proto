# CURRENT_HANDOFF — PMD AutoChess Proto

Last Updated: 2026-08-18 19:51 +08:00

## Persistent Authority
Migration is complete. Do not rebuild or roll it back unless a persistent Authority source is genuinely inaccessible.
- Drive = Binary / Asset Authority
- GitHub = Source / Spec / Validator Authority
- Linear = Development Authority
- ChatGPT = workspace only

## Current Formal Baseline
**v1.06.58 — VXRD Water-Bottom Autotile Pair Authority I — FORMAL PASS.**

Formal Baseline ZIP:
`01_Current_Baseline/PMD_AutoChess_v1_06_58_FORMAL_PASS_BASELINE_WATER_BOTTOM_AUTOTILE_PAIR_AUTHORITY_I_20260818.zip`
Drive ID `1bpvrm1OQBDPMwU8ac06Q-zmZSvTOTHIQ`.

Canonical Formal GitHub Script tail:
- 642 / 1065700 / v1.06.57
- 643 / 1065800 / v1.06.58
- 644 / 250 / Main
- 645 / 251 / terminator
Total 646 Scripts, indices 0..645.

`main` remains the accepted v1.06.58 Formal Source. `develop` is ahead only with post-baseline diagnostics and asset-pipeline work.

## Accepted v1.06.57 / v1.06.58 Results
- v1.06.57 H02/H03/H06/H07/H16 vegetation Landmark expansion: Windows visual PASS.
- v1.06.58 H07/H12/H17 water: user explicitly reported OK.
- H02 current water also accepted.
- v1.06.56 real Loading overlay remains accepted.
- SHO-22 Route Safety remains Done / SEALED.

## Accepted Water Mapping
- H02 -> A1 base 2048.
- H07 -> A1 base 2240.
- H12 -> A1 base 2240.
- H17 -> A1 base 2240.
- old active Random Hunt base 2096 revoked.
- Water remains native A1 animated/autotile, rectangle-only, non-walkable, with A2 shoreline; no rivers/bridges.

## Active SHO-41 — v1.06.59 TEST-ONLY Gravel-Water Probe
User-authoritative locator: desired gravel/pebble clear-bottom water is **two editor palette cells to the right of the accepted H07/H12/H17 water**.

New evidence:
- Windows live full-project snapshot contains no project-embedded `Graphics/System/TileA1.*`.
- Therefore identification is constrained to the standard VX/RTP A1 family unless another runtime override is separately proven.
- Existing Formal runtime proof: A1 starts at 2048 and each autotile kind advances by 48 IDs.
- 2240 = kind 4; diagnostic candidate 2336 = kind 6.
- **Do not equate “two editor palette cells right” with “kind +2” without proving palette-cell ordering.** Candidate 2336 remains diagnostic only.

Evidence files:
- `tests/VXRD_LIVE_A1_SOURCE_AUDIT_20260818.log`
- `docs/VXRD_A1_SOURCE_AND_PALETTE_MAPPING_EVIDENCE_20260818.md`

Diagnostic ZIP:
`PMD_AutoChess_v1_06_59_TEST_ONLY_GRAVEL_BOTTOM_WATER_PALETTE_PROBE_20260818.zip`
Drive ID `1XNSDuk8OEfVJWvwSWv5vaxtJ5hSy--2-`.
ZIP SHA256 `e5903b3fa73bd7cdb7c999ae0be56bf3393274cdc4708735161270f6595c5b5c`.

Probe behavior:
- RMVX `$TEST`: H07 = 2336 candidate.
- H02 = 2048 unchanged.
- H12/H17 = 2240 unchanged.
- non-Test Play = v1.06.58 unchanged.

User action when convenient: completely close RMVX, overwrite probe package, reopen RMVX, Test Play, enter H07, then confirm whether the pool is the requested gravel/pebble-bottom clear water. One screenshot is enough if rejected.

## Active SHO-42 — Dedicated Landmark Asset Batch A
Batch A targets:
- H05 -> `relic_moonstone_a.png`
- H08 -> `storm_charged_rock_a.png`
- H10 -> `mystic_rune_stone_a.png`
- H11 -> `ancient_root_a.png`
- H12 -> `ice_shard_a.png`

### Production Pack READY
`PMD_VXRD_LANDMARK_BATCH_A_PRODUCTION_PACK_20260818.zip`
Drive ID `1CwOft6CQ0nHUcnJcZP-JKRBPmo0OMfLX`.
SHA256 `8da9d582d928fb29b319fd6bd51781603863e9d9a9dda97b0f741192e84244ab`.

Pack contents:
- accepted v1.06.58 Landmark style-reference contact sheet;
- blank 64×64 transparent atlas template;
- 5× visual cell guide;
- Traditional Chinese Batch A production briefs;
- machine-readable asset-jobs JSON;
- README.

Separate Drive Authority:
- `01_References/PMD_VXRD_Landmark_Style_Reference_v1.06.58.png` — ID `1YG0-igmHuUTqIX8DgjTQZctdKJyqbeNA`.
- `00_Style_Authority/VXRD_BATCH_A_PRODUCTION_BRIEFS_繁中.md` — ID `1PWQugYgxMIL8i4EZCK246IFrvFonSN07`.

### GitHub asset gate READY
- `assets/VXRD_LANDMARK_ASSET_PRODUCTION_SPEC.md`
- `assets/ASSET_MANIFEST.csv`
- `tools/asset_validator/validate_vxrd_landmark_atlas.py`
- `tests/ASSET_VALIDATOR_ACCEPTED_SIX_v1.06.58.log`
- `asset_staging/VXRD_Landmarks/README.md`
- `.github/workflows/vxrd_landmark_asset_validator.yml`

Existing accepted six Landmark atlases = validator regression **6/6 PASS**.
Any new candidate staged under `asset_staging/VXRD_Landmarks/` is automatically checked for 64×64 RGBA, four 32×32 cells, visibility/transparency sanity, seam risk and SHA256. CI PASS is structural only; Windows/RMVX visual QA is still required before `12_Approved` or Runtime integration.

New art contract: 64×64 RGBA atlas, 2×2 of four independent complete 32×32 standalone props. No object spans cells. Approved only enters runtime.

## Landmark Coverage
Accepted: H01/H02/H03/H04/H06/H07/H09/H14/H16/H19.
Deferred dedicated-art Hunts: H05/H08/H10/H11/H12/H13/H15/H17/H18/H20/H21.
Do not fill deferred biomes with semantically unrelated props merely to claim coverage.

## Immediate Next Work
1. Produce Batch A draft art from the Production Pack.
2. Run GitHub asset validator / CI on each candidate.
3. Perform Windows/RMVX visual QA before runtime integration.
4. Keep SHO-41 water probe independent from Landmark art work.

## Immutable Rules
- No automatic B/C/D/E scatter/stamping.
- v1.06.44 Landmark runtime IDs remain revoked.
- Map090 = Random Hunt runtime map.
- Map091 = H01–H21 shared Event Template Library.
- Gate 1 structure / Battle Presentation SEALED / issue-driven only.
- No Battle AI, damage, attack speed, Focus/C2, rewards, progression, or spatial-endpoint changes for this work.

## Editor / Documentation Rule
If a future functional candidate changes `Data/Scripts.rvdata`, `Data/Map091.rvdata`, or another Data file, completely close RPG Maker VX before overwrite and reopen afterward. Every functional delivery must include synchronized Traditional Chinese tutorial/usage documentation.
