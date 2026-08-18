# MASTER_PROJECT_STATE — PMD AutoChess Proto

Last Updated: 2026-08-18 19:02 +08:00

## Persistent Authority
- Google Drive = Binary Authority.
- GitHub `showpei1203/PMD-AutoChess-Proto` = text Source Authority.
- Linear Team `Showpei` / Project `PMD AutoChess Proto` = Development Authority.
- ChatGPT = development workspace only.

## Current Formal Baseline
**v1.06.58 — VXRD Water-Bottom Autotile Pair Authority I — FORMAL PASS.**

Windows/RMVX acceptance on 2026-08-18:
- v1.06.57 H02/H03/H06/H07/H16 Landmark expansion: visual PASS.
- v1.06.58 H07/H12/H17 clear-bottom water: user explicitly reported OK.
- H02 current v1.06.58 clear-bottom water is also accepted; no forced rework.
- v1.06.56 Battle-style real Loading overlay remains accepted.
- SHO-22 Route Safety remains Done / SEALED.

## GitHub Source Authority
`main` and `develop` are aligned to the sealed v1.06.58 Source tree after canonical Source repair.
Canonical Script tail:
- 642 / ID 1065700 / v1.06.57 / `0642__id_1065700.rb`
- 643 / ID 1065800 / v1.06.58 / `0643__id_1065800.rb`
- 644 / ID 250 / Main / `0644__id_250.rb`
- 645 / ID 251 / terminator / `0645__id_251.rb`
Total = 646 Scripts, indices 0..645.

Exact hashes:
- v1.06.57 source SHA256 `be91725e395e87bb79553d11d0bb125f913d7e8f2aabf164609e688e4e820ede`.
- v1.06.58 source SHA256 `aae49d6c64fbacbba1b077a42992a5f4e954a75876ce6ba155f58b1a1c2ff7b1`.
- Main SHA256 `8fdfe50524b8d32a91901e636c6100dba33a42baa6ff09a8153f31786a585558`.
- terminator SHA256 `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`.

PR #2 exact finalizer succeeded and regenerated canonical `SCRIPT_INDEX.tsv` / `SCRIPT_ORDER.md`; staging was removed. A stale duplicate terminator was subsequently removed after compare audit.

## Drive Binary Authority
Formal Baseline:
`01_Current_Baseline/PMD_AutoChess_v1_06_58_FORMAL_PASS_BASELINE_WATER_BOTTOM_AUTOTILE_PAIR_AUTHORITY_I_20260818.zip`
Drive ID `1bpvrm1OQBDPMwU8ac06Q-zmZSvTOTHIQ`.

Accepted v1.06.58 candidate archive:
- Current Development Drive ID `14VmbnX9nCx-CPusUhceWkcvlkwuO0EST`.
- Test Build Drive ID `1rYcztk1tMcL7Se5XeMz1RtJ6tXeC2FtF`.

Binary validation:
- 646 Scripts, indices 0..645.
- Static validation 28/28 PASS.
- Ruby syntax PASS.
- `Data/Scripts.rvdata` SHA256 `001f94df75298b079f2dcccc097dbb174b1f200acd2ed9eb934cb2af39059ac0`.
- ZIP SHA256 `e99a3dcd96a0f37bc05266c36233a9c2367da695a55a075bea411d8f32eeeb07`.
- Map091 unchanged.
- Traditional Chinese tutorial synchronized.

## Accepted Water Authority v1.06.58
- Water-enabled Hunts remain H02/H07/H12/H17 only.
- H02 -> A1 base 2048, accepted for current natural/wetland presentation.
- H07/H12/H17 -> A1 base 2240, accepted clear-bottom presentation.
- old active Random Hunt A1 base 2096 is revoked.
- native A1 animation/autotile joining, A2 shoreline, rectangle-only, non-walkable water remain preserved.
- no river / bridge feature expansion.

## Water Semantic Refinement Follow-up
User clarified that the intended **gravel/stone-bottom clear water** is NOT the accepted H07/H12/H17 water. It is the clear-bottom water located **two editor palette cells to the right of the current H07/H12/H17 water**, with a gravel/pebble bottom.
- Exact runtime base ID is NOT yet formally verified.
- Do not guess or apply an ID until editor/runtime mapping evidence confirms it.
- H02 does not need rollback; its current v1.06.58 water is accepted.

## Landmark / Hunt Visual State
Accepted Landmark coverage:
- H01/H04/H09/H14/H19 original single-prop semantic set.
- H02/H03/H06/H07/H16 vegetation/wetland expansion.

Deferred dedicated-art Landmark Hunts:
H05/H08/H10/H11/H12/H13/H15/H17/H18/H20/H21.
Do not fake biome identity with unrelated forest/rock/crystal props.

## Sealed Infrastructure / Regression Rules
- SHO-22 Route Safety: Done / SEALED. Evidence: 840 production-like + 11 adversarial cases, failures 0, unsafe hard-Landmark removals 10, topology rewrite 0.
- SHO-35 Random Hunt real Loading overlay: Done / SEALED.
- Automatic B/C/D/E scatter/stamping remains prohibited.
- v1.06.44 Landmark runtime IDs remain revoked.
- Map090 remains Random Hunt Runtime Map.
- Map091 remains H01–H21 shared Event Template Library.
- Gate 1 structure / accepted Battle Presentation remain SEALED / issue-driven only.
- Do not alter Battle AI, damage, attack speed, Focus/C2, rewards, progression, or spatial endpoints for Hunt visual work.

## Immediate Next Development
1. Formalize gravel-bottom clear-water editor/runtime mapping evidence without changing accepted v1.06.58 behavior.
2. Continue Gate 2 remaining-Hunt dedicated visual asset planning/production and semantic integration.
3. Preserve route safety, Loading, Map091 event semantics, and all no-regression rules.

## Editor / Documentation Rule
Any functional delivery that updates `Data/Scripts.rvdata`, `Data/Map091.rvdata`, or another Data file requires: completely close RPG Maker VX before overwrite, then reopen RMVX. Every functional update must include synchronized Traditional Chinese tutorial/usage documentation.
