# CURRENT_HANDOFF — PMD AutoChess Proto

Last Updated: 2026-08-18 18:30 +08:00

## Persistent Authority
Migration is complete. Do not rebuild or roll it back unless a persistent source is genuinely inaccessible.
- Drive = Binary Authority
- GitHub = Source Authority
- Linear = Development Authority
- ChatGPT = workspace only

## Current Formal Baseline
**v1.06.56 — VXRD Random Hunt Real Loading Overlay I — FORMAL PASS.**
Drive baseline ID `1JuKQu89h6GEOs6YoxiMFafVBYLTHM_fT`.
SHO-35 Done. SHO-22 Route Safety Done / SEALED.

## v1.06.57 Status
**Windows Visual PASS / Source seal pending.**
User reported H02/H03/H06/H07/H16 vegetation/wetland expansion `看起來ok`.
- Current Development Drive ID `1OSHRyT1WCaYzWwT011Lqjm3y76kR5Ik0`.
- Test Build Drive ID `1LyFebyMWoMiojgHGAnYwVJIB-zTMOlYM`.
- v1.06.57 = Binary index 642 / ID 1065700.
- Exact Source SHA256 `be91725e395e87bb79553d11d0bb125f913d7e8f2aabf164609e688e4e820ede`.
- SHO-36 stays In Progress only for GitHub canonical manifest convergence.

## Active Candidate
**v1.06.58 — VXRD Water-Bottom Autotile Pair Authority I — UNPASSED.**

User requested the two visible-bottom native VX A1 water autotiles beside the ice/iceberg decoration group:
- left/natural-bottom family -> base `2048`;
- right/stone-bottom family -> base `2240`.

Current mapping:
- H02 -> `2048` natural/grass-earth bottom.
- H07 -> `2240` stone/hard bottom.
- H12 -> `2240` hard/ice bottom.
- H17 -> `2240` hard/ice bottom.
- old deep/opaque base `2096` revoked from current Random Hunt water use.

Validation:
- 646 Scripts, indices 0..645.
- v1.06.58 = index 643 / ID 1065800.
- Main 644; terminator 645.
- Static 28/28 PASS; Ruby syntax PASS.
- v1.06.58 exact Source SHA256 `aae49d6c64fbacbba1b077a42992a5f4e954a75876ce6ba155f58b1a1c2ff7b1`.
- `Data/Scripts.rvdata` SHA256 `001f94df75298b079f2dcccc097dbb174b1f200acd2ed9eb934cb2af39059ac0`.
- Traditional Chinese tutorial updated.

Binary Authority:
- Current Development Drive ID `14VmbnX9nCx-CPusUhceWkcvlkwuO0EST`.
- Test Build Drive ID `1rYcztk1tMcL7Se5XeMz1RtJ6tXeC2FtF`.

GitHub Source:
- exact source staged at `.v10658_import/0643__id_1065800.rb` on `develop`;
- canonical `SCRIPT_INDEX.tsv / SCRIPT_ORDER.md` still have the earlier v1.06.57 tail blocker;
- do not promote v1.06.57/v1.06.58 until manifests converge.

Linear:
- SHO-36 = Windows Visual PASS / Source seal pending.
- SHO-40 = v1.06.58 Water-Bottom Autotile Pair Acceptance, In Progress.

## Immediate Windows Test
Completely close RPG Maker VX, overwrite v1.06.58, reopen RMVX, then:
1. H02: natural/grass-earth visible-bottom water.
2. H07: stone/hard visible-bottom water.
3. H12/H17: hard-bottom version, no obvious grassy bottom.
4. confirm water animation, autotile edges/shoreline, non-walkability.
5. confirm Loading Overlay / Landmark / Route Safety still normal.

Audit log: `PMD_VXRD_WaterBottom_Audit_LATEST.log`.
Screenshots only needed if water type, shoreline or tile joining looks wrong.

## Immutable Rules
- No automatic B/C/D/E scatter/stamping.
- v1.06.44 upper-tile Landmark IDs remain revoked.
- Map090 = Random Hunt runtime map; Map091 = H01–H21 shared Event Template Library.
- No unrelated Battle AI / Damage / Attack Speed / Focus-C2 / Reward / Progression change.
- Every functional update includes Traditional Chinese tutorial/usage documentation.
