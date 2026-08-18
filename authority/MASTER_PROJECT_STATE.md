# MASTER_PROJECT_STATE — PMD AutoChess Proto

Last Updated: 2026-08-18 14:50 +08:00

## Persistent Authority
- Google Drive = Binary Authority.
- GitHub `showpei1203/PMD-AutoChess-Proto` = text Source Authority.
- Linear Team `Showpei` / Project `PMD AutoChess Proto` = Development Authority.
- ChatGPT = development workspace only.

## Version State
- Current Formal Baseline: **v1.06.54 — VXRD Landmark Single-Prop Semantic / Presence / Collision Fix I — PASS**.
- Current Candidate: **v1.06.55 — VXRD Landmark Route Safety Audit I — UNPASSED**.
- v1.06.55 static validation: **PASS 31/31**.
- v1.06.55 offline deterministic route regression: **40/40 PASS** (H01/H04/H09/H14/H19 × 8 seeds).
- Windows/RPG Maker VX real-machine acceptance for v1.06.55 is pending.

## GitHub Branch Authority
### main
- v1.06.54 formal PASS source.
- 642 scripts, indices `0..641`.

### develop
- v1.06.55 unpassed Candidate source.
- 643 scripts, indices `0..642`.
- v1.06.54 remains Script index `639`, ID `1065400`.
- v1.06.55 = Script index `640`, ID `1065500`.
- Main index `641`; terminator index `642`.
- Index / ID / Name / exact decompressed Content / execution order are preserved.

## Drive Binary Authority
- Formal Baseline: `01_Current_Baseline/PMD_AutoChess_v1_06_54_FORMAL_PASS_BASELINE_LANDMARK_SINGLE_PROP_SEMANTIC_PRESENCE_COLLISION_I_20260818.zip`, Drive ID `1ilVIw9RnY5e9DmhJl8QdTyMDhrR3t0xK`.
- Current Candidate: `02_Current_Development/PMD_AutoChess_v1_06_55_CUMULATIVE_OVERWRITE_LANDMARK_ROUTE_SAFETY_AUDIT_I_20260818.zip`, Drive ID `1gP6fdpPOVpGdZdjXuc65rbV8RQLEvexO`.
- Test Build: `03_Test_Builds/PMD_AutoChess_v1_06_55_TEST_BUILD_UNPASSED_20260818.zip`, Drive ID `1IcFb735xTSXpOaw8BleEKAeeop-Lu_hL`.
- v1.06.55 updates `Data/Scripts.rvdata`; `Data/Map091.rvdata` is unchanged.

## v1.06.55 Route Safety Authority
SHO-22 is In Progress.
- Pre-event gate audits generated entrance → exit reachability using the v1.06.54 hard-Landmark block mask.
- Post-event gate audits required semantic targets after Map091 materialization / relocation: EXIT, RETREAT, INFO, TREASURE, RECOVERY, RARE, ELITE, ENCOUNTER when present.
- Target cell or adjacent walkable interaction cell may satisfy reachability.
- If a hard Landmark breaks a required route, later hard placements are rejected first and Landmark masks are rebuilt.
- Sealed Gate 1 room/corridor topology is never rewritten as a decoration repair.
- H01 soft decoration does not enter the blocking mask.
- Runtime evidence: `PMD_VXRD_LandmarkRoute_Audit_LATEST.log` and `PMD_VXRD_LandmarkRoute_Audit_HISTORY.log`.

## No-Regression Rules
- Automatic B/C/D/E tile scatter/stamping remains prohibited.
- v1.06.44 Landmark runtime IDs remain revoked.
- Map090 remains Random Hunt Runtime Map.
- Map091 remains H01–H21 shared Event Template Library.
- Gate 1 Random Hunt structural runtime / accepted Battle Presentation remain SEALED / issue-driven only.
- Do not alter Battle AI, damage, attack speed, Focus/C2, rewards or spatial endpoints for SHO-22.
- Do not reorder Scripts.rvdata entries for repository aesthetics.

## Immediate Acceptance
Install v1.06.55 and generate at least one floor each in H01 / H04 / H09 / H14 / H19 in the same session. Then collect `PMD_VXRD_LandmarkRoute_Audit_HISTORY.log`.
Every completed RUN should report `RESULT=PASS` and `EXIT_REACHABLE=1`. `REMOVED=0` and `REMOVED>0` are both valid PASS outcomes.
Battle LOG is unnecessary unless Runtime/battle itself fails.

## Editor / Documentation Rule
Any functional delivery that updates `Data/Scripts.rvdata`, `Data/Map091.rvdata`, or other Data files requires: completely close RPG Maker VX before overwrite, then reopen RMVX. Every functional update must include synchronized Traditional Chinese tutorial/usage documentation.
