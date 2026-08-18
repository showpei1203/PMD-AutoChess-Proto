# MASTER_PROJECT_STATE — PMD AutoChess Proto

Last Updated: 2026-08-18 18:30 +08:00

## Persistent Authority
- Google Drive = Binary Authority.
- GitHub `showpei1203/PMD-AutoChess-Proto` = text Source Authority.
- Linear Team `Showpei` / Project `PMD AutoChess Proto` = Development Authority.
- ChatGPT = development workspace only.

## Formal Baseline
**v1.06.56 — VXRD Random Hunt Real Loading Overlay I — FORMAL PASS.**
- Windows/RMVX Loading acceptance PASS.
- SHO-35 Done / sealed.
- Drive formal baseline ID: `1JuKQu89h6GEOs6YoxiMFafVBYLTHM_fT`.
- GitHub `main` remains the formal PASS Source authority until later candidates complete both Windows acceptance and canonical Source-manifest convergence.

## Route Safety
**v1.06.55 Route Safety is SEALED.**
- SHO-22 Done.
- 840 production-like cases = 21 Hunts × 40 deterministic seeds, failures 0.
- 11 adversarial repair cases, 10 unsafe hard Landmarks actually removed.
- `TOPOLOGY_REWRITE=0`.
- `MAP_TABLE_BCDE_STAMPING=0`.

## v1.06.57 Candidate State
**Landmark Vegetation / Wetland Coverage Expansion I — WINDOWS VISUAL PASS / SOURCE SEAL PENDING.**
- User reported H02/H03/H06/H07/H16 `看起來ok`.
- Soft/passable vegetation coverage accepted visually on Windows/RMVX.
- Binary: 645 Scripts, v1.06.57 index 642 / ID 1065700.
- Current Development Drive ID: `1OSHRyT1WCaYzWwT011Lqjm3y76kR5Ik0`.
- Test Build Drive ID: `1LyFebyMWoMiojgHGAnYwVJIB-zTMOlYM`.
- Linear SHO-36 remains In Progress only because canonical GitHub manifests have not yet absorbed the v1.06.57 tail.
- Exact v1.06.57 Source SHA256: `be91725e395e87bb79553d11d0bb125f913d7e8f2aabf164609e688e4e820ede`.

## Active Candidate
**v1.06.58 — VXRD Water-Bottom Autotile Pair Authority I — UNPASSED.**

Water mapping:
- H02 -> A1 base `2048`: visible natural/grass-earth bottom water.
- H07 -> A1 base `2240`: visible stone/hard-bottom water.
- H12 -> A1 base `2240`: hard/ice-bottom water.
- H17 -> A1 base `2240`: hard/ice-bottom water.
- Old deep/opaque Random Hunt water base `2096` is revoked from active water profiles.

Preserved rules:
- water Hunts remain H02/H07/H12/H17 only;
- native VX A1 animation and autotile joining preserved;
- A2 shoreline authority preserved;
- rectangle-only water; no river / bridge;
- water remains non-walkable;
- no automatic B/C/D/E scatter/stamping;
- Map090 / Map091, Landmark, Route Safety, Loading Overlay, Battle AI, Damage, Attack Speed, Focus-C2, Reward and Progression unchanged.

v1.06.58 validation:
- Binary Scripts = 646, indices `0..645`.
- v1.06.57 = index 642.
- v1.06.58 = index 643 / ID 1065800.
- Main = 644; terminator = 645.
- v1.06.58 Source SHA256 `aae49d6c64fbacbba1b077a42992a5f4e954a75876ce6ba155f58b1a1c2ff7b1`.
- `Data/Scripts.rvdata` SHA256 `001f94df75298b079f2dcccc097dbb174b1f200acd2ed9eb934cb2af39059ac0`.
- Static validation 28/28 PASS; Ruby syntax PASS.
- Traditional Chinese tutorial synchronized.

Binary Authority:
- Current Development Drive ID `14VmbnX9nCx-CPusUhceWkcvlkwuO0EST`.
- Test Build Drive ID `1rYcztk1tMcL7Se5XeMz1RtJ6tXeC2FtF`.
- Both ZIP SHA256 `e99a3dcd96a0f37bc05266c36233a9c2367da695a55a075bea411d8f32eeeb07`.

GitHub Source:
- exact v1.06.58 source staged on `develop` at `.v10658_import/0643__id_1065800.rb`;
- staged Git blob is byte-exact to validated Binary source;
- canonical `SCRIPT_INDEX.tsv / SCRIPT_ORDER.md` still inherit the v1.06.57 tail blocker;
- do not promote v1.06.57 or v1.06.58 Formal until canonical manifests converge.

## Current Development Authority
- SHO-36: v1.06.57 Windows Visual PASS / Source seal pending.
- SHO-40: v1.06.58 Water-Bottom Autotile Pair Acceptance — In Progress.
- Gate 2 remains In Progress.

## v1.06.58 Windows Acceptance
Primary: H02 and H07. Quick check: H12 and H17.
- H02 must visibly show natural/grass-earth bottom water.
- H07 must visibly show stone/hard-bottom water.
- H12/H17 must not visibly expose grassy water bottom.
- native animation, autotile edges and shoreline must remain correct.
- water must remain non-walkable.
- Loading Overlay, Landmark and Route Safety must not regress.

## Immutable Rules
- No automatic B/C/D/E scatter/stamping.
- v1.06.44 upper-tile Landmark runtime IDs remain revoked.
- Map090 = Random Hunt runtime map.
- Map091 = H01–H21 shared Event Template Library.
- Gate 1 and accepted Battle Presentation remain SEALED / issue-driven only.
- No unrelated Battle AI / Damage / Attack Speed / Focus-C2 / Reward / Progression changes.

## Editor / Documentation Rule
For any delivery that updates `Data/Scripts.rvdata`, `Data/Map091.rvdata`, or other editor-cached Data: completely close RPG Maker VX before overwrite, then reopen RMVX. Every functional delivery must include synchronized Traditional Chinese tutorial/usage documentation.
