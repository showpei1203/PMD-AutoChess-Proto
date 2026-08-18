# MASTER_PROJECT_STATE — PMD AutoChess Proto

Last Updated: 2026-08-18 14:39 +08:00

## Persistent Authority
- Google Drive = Binary Authority.
- GitHub `showpei1203/PMD-AutoChess-Proto` = text Source Authority.
- Linear Team `Showpei` / Project `PMD AutoChess Proto` = Development Authority.
- ChatGPT = development workspace only.

## Version State
- Current Formal Baseline: **v1.06.54 — VXRD Landmark Single-Prop Semantic / Presence / Collision Fix I**.
- Windows / RPG Maker VX real-machine acceptance: **PASS on 2026-08-18**.
- Previous formal Baseline: v1.06.35.
- v1.06.53 Landmark PNG Authority Foundation I: **REAL-MACHINE VISUAL FAIL — never promote**.
- Next Development Gate: **SHO-22 — Landmark II: Collision / Route Audit**.

## v1.06.54 Acceptance Authority
Real-machine acceptance on H01 / H04 / H09 / H14 / H19 confirmed:
- every acceptance Hunt shows at least one Landmark;
- one Landmark = one 32×32 atlas cell, not the full 64×64 2×2 atlas;
- placement / spacing visually accepted;
- H01 foliage / flowers are passable;
- H04 dry rock, H09 cave crystal/rock, H14 mine ore, H19 volcanic rock/ore are impassable;
- scrolling and Hunt/floor refresh are normal;
- no giant TileB/TileD fragment returned;
- no automatic B/C/D/E map stamping returned;
- no observed Gate 1 structural/battle regression.

Static validation: PASS 23/23.
Source-level acceptance precheck verified normal player walking collision chaining, Landmark reservation before Map091 semantic relocation, stale sprite disposal/refresh, and continued B/C/D/E stamping prohibition.

## GitHub Branch Authority
### main
- **v1.06.54 formal PASS source**.
- 642 scripts, indices `0..641`.
- v1.06.54 Script index `639`, ID `1065400`.
- Main index `640`; terminator index `641`.
- Script Index / ID / Name / exact decompressed Content / execution order remain preserved.

### develop
- Continuation branch based on current formal PASS.
- Next unpassed candidate will implement SHO-22 Landmark collision / route audit.
- Do not promote future develop candidates without Windows/RMVX acceptance appropriate to the defect class.

## Drive Binary Authority
- Current Formal Baseline: accepted v1.06.54 package copied to `01_Current_Baseline` as formal PASS Binary Authority.
- Accepted source package originated from `02_Current_Development/PMD_AutoChess_v1_06_54_CUMULATIVE_OVERWRITE_LANDMARK_SINGLE_PROP_SEMANTIC_PRESENCE_COLLISION_I_20260818.zip`, Drive ID `1B3flf23qcLhGqLjNSlwKZnCULjGcYLC0`.
- Windows live snapshot remains NEEDS_REVIEW for internal version alignment and is not authority merely by upload date.

## Gate 2 Current State
Completed / accepted:
- Hunt visual/style contentization foundation.
- RMVX A1/A2/A4/A5 semantic reset.
- native water / bank autotile rules.
- Random Hunt minimap foundation.
- upper-tile B/C/D runtime-ID root-cause correction.
- Map091 H01–H21 FS-style Event Template Library and Hunt/Floor contentization.
- Landmark separate-PNG atlas authority.
- v1.06.54 single-prop rendering, minimum presence, and local hard/soft collision semantics.

In Progress:
- SHO-22 Landmark II — collision / route audit.

## SHO-22 Route-Audit Authority
Required:
1. Entrance → Exit must remain reachable after hard Landmark placement.
2. Required semantic event destinations must remain reachable where applicable.
3. Hard Landmark cells must not occupy entrance/exit/keypoint/fixed positions/water/event-reserved cells.
4. Hard Landmark placement must not seal a doorway, corridor throat, or unique room connection.
5. Soft H01 decoration must not participate as a blocker.
6. Audit multiple deterministic seeds for H01/H04/H09/H14/H19 before expanding Landmark coverage.
7. If a hard Landmark breaks a required route, reject/relocate that Landmark; do not modify sealed Gate 1 room topology.

## No-Regression Rules
- Automatic B/C/D/E tile scatter/stamping remains prohibited.
- v1.06.44 Landmark runtime IDs remain revoked.
- Map090 remains Random Hunt Runtime Map.
- Map091 remains the H01–H21 Event Template Library.
- Gate 1 Random Hunt structural runtime and accepted Battle Presentation remain SEALED / issue-driven only.
- Do not alter Battle AI, damage, attack speed, Focus/C2, rewards or spatial endpoints during Landmark route work.
- Do not reorder Scripts.rvdata entries for repository aesthetics.

## Editor / Documentation Rule
Any functional delivery that updates `Data/Scripts.rvdata`, `Data/Map091.rvdata`, or other Data files requires: close RPG Maker VX before overwrite, then reopen RMVX. Every functional update must also update the Traditional Chinese tutorial/usage documentation.
