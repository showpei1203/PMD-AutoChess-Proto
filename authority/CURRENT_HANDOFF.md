# CURRENT_HANDOFF — PMD AutoChess Proto

Last Updated: 2026-08-18 08:20 +08:00

## Read Order for a New Development Chat
1. `00_Project_Authority/MASTER_PROJECT_STATE.md`
2. this `05_Handoff/CURRENT_HANDOFF.md`
3. Google Drive `01_Current_Baseline`
4. GitHub `main` and `develop` once repository is active
5. Linear Project `PMD AutoChess Proto` open issues

## Formal Baseline
- **v1.06.35 — VXRD Acceptance Non-Combat Fixture**
- v1.06.36 release notes explicitly state user Windows Final Acceptance all PASS and seal Random Hunt structural runtime. Therefore v1.06.36 starts Gate 2 and is not itself the Gate 1 baseline.
- v1.06.33 also records Battle Presentation Windows visual acceptance and seals that presentation layer issue-driven only.

## Current Candidate
- **v1.06.53 — VXRD Landmark PNG Authority Foundation I**
- Scripts.rvdata entries: 641.
- Candidate contains Data/Scripts.rvdata, Data/Map091.rvdata, six `Graphics/VXRD_Landmarks/*.png`, validation/authority/tutorial files.
- Static validation passed locally; **real-machine acceptance pending**.

## Recent Work
- Corrected H14 invalid floor-autotile interpretation and H19 style selection.
- Re-established RMVX A1/A2/A4/A5 semantics and water/bank connectivity logic.
- Identified v1.06.44 upper-tile Landmark root cause: B/C/D/E runtime tile IDs are two 8-column banks, not direct PNG 16-column row-major indices.
- Revoked v1.06.44 Landmark stamping and hard-disabled automatic B/C/D/E scattering.
- Added Random Hunt minimap foundation.
- Migrated event content to FS-style Map091 universal Event Template Library.
- Map091 contentized to Hunt/Family/Floor filters.
- v1.06.53 moved landmarks to separate PNG sprites under `Graphics/VXRD_Landmarks/` to avoid repeating upper-tile ID mistakes.

## Latest PASS / FAIL
- Latest formal PASS: Gate 1 Windows Final Acceptance all PASS before v1.06.36 Gate 2.
- Latest historical visual FAIL class: Landmark / upper-tile semantic mapping. v1.06.44 H02 displayed large-map fragments because incorrect runtime IDs mapped to TileB atlas 73/74/108/141. Root cause fixed architecturally; v1.06.44 is invalid for Landmark authority.
- Current v1.06.53: no real-machine PASS/FAIL yet.

## Next Step After Migration
1. Finish Migration Audit and close infrastructure blockers.
2. Test v1.06.53 only after Authority is established.
3. Visual acceptance scope: H01, H04, H09, H14, H19.
4. If visual PASS: add Landmark collision + route audit.
5. Then expand Landmark/contentization to remaining Hunts and final event polish.

## Do Not Regress
- Gate 1 Random Hunt structural runtime SEALED / issue-driven only.
- Battle Presentation SEALED / issue-driven only.
- Do not alter AI, damage, attack speed, spatial endpoints, Focus/C2, Hunt reward semantics while doing visual contentization.
- Water Hunts remain H02/H07/H12/H17; no river, no bridge.
- Do not restore global B/C/D single-tile/random scattering.
- Do not use v1.06.44 Landmark runtime IDs as source material.
- Map090 is runtime; Map091 is universal event source template map.

## Known Traps
- Higher version number does not mean PASS.
- Old `PMD_ProjectState_LATEST.log` may say Windows acceptance pending because it predates the later user PASS; cross-check release notes and user acceptance history.
- Reconstructible full project in v1.06.30 handoff is reference/recovery material, not the user's official Windows live project.
- When Data/Map091.rvdata is updated, close RMVX before overwrite and reopen RMVX afterward so the editor does not retain stale cached map data.
- GitHub source export must preserve numeric script index and exact content; never reorder runtime scripts to make a prettier repository.

## User-confirmed Design Decisions
- Google Drive = Binary Authority.
- GitHub = Source Authority.
- Linear = Development Authority.
- ChatGPT is not the permanent source of truth.
- Map091 is shared by all H01–H21 Random Hunts.
- Tutorials/usage docs must be updated whenever functionality changes.
