# CURRENT_HANDOFF — PMD AutoChess Proto

Last Updated: 2026-08-18 14:50 +08:00

## Persistent Authority
Migration is complete. Do not rebuild or roll it back unless a persistent Authority source is genuinely inaccessible.
- Drive = Binary Authority
- GitHub = Source Authority
- Linear = Development Authority
- ChatGPT = development workspace only

## Formal Baseline
**v1.06.54 — VXRD Landmark Single-Prop Semantic / Presence / Collision Fix I — FORMAL PASS**.
Drive Baseline ID: `1ilVIw9RnY5e9DmhJl8QdTyMDhrR3t0xK`.
GitHub `main` remains v1.06.54 formal PASS source.

## Current Candidate
**v1.06.55 — VXRD Landmark Route Safety Audit I — UNPASSED**.
- 643 Scripts, indices 0..642.
- New Script index 640 / ID 1065500.
- Main index 641; terminator 642.
- Static validation PASS 31/31.
- Offline deterministic regression H01/H04/H09/H14/H19 × 8 seeds = 40/40 PASS.
- Real-machine route-audit acceptance pending.

Drive Candidate:
`02_Current_Development/PMD_AutoChess_v1_06_55_CUMULATIVE_OVERWRITE_LANDMARK_ROUTE_SAFETY_AUDIT_I_20260818.zip`
Drive ID `1gP6fdpPOVpGdZdjXuc65rbV8RQLEvexO`.

Test Build:
`03_Test_Builds/PMD_AutoChess_v1_06_55_TEST_BUILD_UNPASSED_20260818.zip`
Drive ID `1IcFb735xTSXpOaw8BleEKAeeop-Lu_hL`.

## SHO-22 Implementation
- Pre-event route gate: entrance → exit with hard Landmark blocker mask.
- Post-event route gate: required Map091 semantic destinations after materialization/relocation.
- Required tags when present: EXIT / RETREAT / INFO / TREASURE / RECOVERY / RARE / ELITE / ENCOUNTER.
- Unsafe hard Landmark placement is rejected and masks rebuilt.
- Gate 1 room/corridor topology is not rewritten.
- H01 soft decoration remains passable / non-blocking.
- Runtime writes LATEST + HISTORY route-audit logs.
- Map091 and six accepted Landmark PNG atlas files are unchanged from v1.06.54.

## Immediate Real-Machine Test
1. **Completely close RPG Maker VX before installing v1.06.55**, because `Data/Scripts.rvdata` changes.
2. Overwrite the project, then reopen RMVX.
3. In one session, enter H01 / H04 / H09 / H14 / H19 and generate at least one floor each.
4. Normal walking is enough; Battle LOG is not required unless Runtime/battle fails.
5. Afterward collect `PMD_VXRD_LandmarkRoute_Audit_HISTORY.log` from the game root.
6. Every completed RUN should show `RESULT=PASS` and `EXIT_REACHABLE=1`.
7. `REMOVED=0` means the original Landmark layout was already safe; `REMOVED>0` means the gate correctly rejected an unsafe hard Landmark. Both may PASS.
8. Screenshot only if a visual abnormality appears.

Do not expand Landmark coverage to the remaining Hunts until SHO-22 receives real-machine PASS.

## Immutable Rules
- No automatic B/C/D/E scatter/stamping.
- v1.06.44 Landmark runtime IDs remain revoked.
- Map090 = Random Hunt runtime map.
- Map091 = H01–H21 Event Template Library.
- Gate 1 structure / Battle Presentation remain SEALED / issue-driven only.
- Do not alter Battle AI, damage, attack speed, Focus/C2, rewards or spatial endpoints during SHO-22.

## Documentation Rule
Every functional update must update the Traditional Chinese tutorial/usage document. v1.06.55 includes `教學_v1.06.55.txt`.
