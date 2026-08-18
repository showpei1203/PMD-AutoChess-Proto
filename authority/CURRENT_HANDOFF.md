# CURRENT_HANDOFF — PMD AutoChess Proto

Last Updated: 2026-08-18 14:39 +08:00

## Persistent Authority
Migration is complete. Do not rebuild or roll it back unless a persistent Authority source is genuinely inaccessible.
- Google Drive = Binary Authority
- GitHub = Source Authority
- Linear = Development Authority
- ChatGPT = development workspace only

## Current Formal Baseline
**v1.06.54 — VXRD Landmark Single-Prop Semantic / Presence / Collision Fix I — FORMAL PASS**.

Windows / RPG Maker VX real-machine acceptance PASS on 2026-08-18.
Accepted H01 / H04 / H09 / H14 / H19:
- Landmark presence PASS;
- single 32×32 prop rendering PASS;
- visual spacing / placement PASS;
- H01 soft vegetation passability PASS;
- H04/H09/H14/H19 hard object blocking PASS;
- scrolling and Hunt/floor refresh PASS;
- no giant TileB/TileD fragment or automatic B/C/D/E stamping regression.

Static validation PASS 23/23.

## GitHub
- `main` = **v1.06.54 formal PASS source**, 642 scripts, indices 0..641.
- v1.06.54 Script index 639 / ID 1065400.
- Main index 640; terminator index 641.
- `develop` = continuation from the v1.06.54 PASS point for the next SHO-22 candidate.
- Script Index / ID / Name / exact decompressed Content / execution order must remain preserved.

## Binary Authority
Accepted v1.06.54 package is promoted to Google Drive `01_Current_Baseline` as the current formal Binary Authority.
Original accepted candidate package:
`02_Current_Development/PMD_AutoChess_v1_06_54_CUMULATIVE_OVERWRITE_LANDMARK_SINGLE_PROP_SEMANTIC_PRESENCE_COLLISION_I_20260818.zip`
Drive ID `1B3flf23qcLhGqLjNSlwKZnCULjGcYLC0`.

## Previous Failure
v1.06.53 is a permanent real-machine Visual FAIL record:
- H01/H04/H09/H14 no visible Landmark;
- H19 full 64×64 atlas rendered as four unrelated props;
- hard rock/ore visuals pass-through.
Do not promote or reuse v1.06.53 as Landmark behavior authority.

## Immediate Development Target
**SHO-22 — Landmark II: Collision / Route Audit — In Progress.**

Implement a deterministic route-safety audit around current hard Landmark blockers.
Acceptance intent:
1. Entrance → Exit remains reachable.
2. Required Map091 semantic events remain reachable where applicable.
3. Hard Landmark cells never occupy entrance/exit/keypoint/fixed/water/event-reserved cells.
4. Landmark placement cannot seal a doorway, corridor throat, or unique room connection.
5. Soft H01 decoration does not block route calculations.
6. Audit multiple deterministic seeds for H01/H04/H09/H14/H19 before expanding to the remaining Hunts.
7. If a proposed hard Landmark breaks a required route, reject or relocate the Landmark. Do not alter sealed Gate 1 topology.

## Immutable Rules
- No automatic B/C/D/E tile scatter/stamping.
- v1.06.44 Landmark runtime IDs remain revoked.
- Map090 = Random Hunt runtime map.
- Map091 = H01–H21 shared Event Template Library.
- Gate 1 structural runtime / Battle Presentation remain SEALED / issue-driven only.
- Do not alter Battle AI, damage, attack speed, Focus/C2, rewards or spatial endpoints for this work.

## Editor / Documentation Rule
If the next candidate updates `Data/Scripts.rvdata`, `Data/Map091.rvdata`, or any other Data file, completely close RPG Maker VX before overwrite and reopen RMVX afterward. Every functional update must include synchronized Traditional Chinese tutorial / usage documentation.
