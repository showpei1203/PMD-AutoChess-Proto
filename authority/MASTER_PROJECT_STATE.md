# MASTER_PROJECT_STATE — PMD AutoChess Proto

Last Updated: 2026-08-18 13:12 +08:00

## Project Identity
- Project Name: PMD AutoChess Proto
- Engine: RPG Maker VX / RGSS2
- Google Drive Project Folder: `PMD_AutoChess` (`1bOgj_4F-O6mxxxXmNT-akHsudWl-dIUK`)
- GitHub Repository: `showpei1203/PMD-AutoChess-Proto` — **ACTIVE / WRITE VERIFIED**
- Linear Project: `PMD AutoChess Proto` (`824907af-a00d-47f8-ab86-d834a8142bd9`)
- Linear Team: `Showpei`

## Authority Model
- Binary Authority: Google Drive / `01_Current_Baseline` + `02_Current_Development`
- Source Authority: GitHub
  - `main` = latest formal Windows/RPG Maker VX PASS source
  - `develop` = current unpassed Candidate source
- Development Authority: Linear / Project `PMD AutoChess Proto`
- ChatGPT: development workspace only; never sole permanent Authority

## Version State
- Current Baseline: **v1.06.35 — VXRD Acceptance Non-Combat Fixture**
- Current Candidate: **v1.06.53 — VXRD Landmark PNG Authority Foundation I**
- Latest formal PASS: **Gate 1 Windows Final Acceptance — all PASS**, evidenced by v1.06.36 release notes; Random Hunt structural runtime SEALED / issue-driven only.
- v1.06.53 status: **UNPASSED / PENDING USER REAL-MACHINE VISUAL ACCEPTANCE**. Static validation is evidence only.

## GitHub Source Authority — ACTIVE
### main
- Version: **v1.06.35 formal PASS Source Authority**
- Final import commit: `7fa9e9f9adf16f7c68bbd1596b55a125e732ff74`
- Scripts.rvdata export: **623 entries**, indices `0..622`
- `SCRIPT_INDEX.tsv` and `SCRIPT_ORDER.md` preserved.

### develop
- Version: **v1.06.53 unpassed Candidate Source Authority**
- Final import commit: `ba7802d749d58b6a2e1dd9f7c4d18eb842b36cb8`
- Scripts.rvdata export: **641 entries**, indices `0..640`
- `SCRIPT_INDEX.tsv` and `SCRIPT_ORDER.md` preserved.

### Source Integrity Rules
- Numeric Script Index / Script ID / Script Name / decompressed Script Content / execution order are preserved.
- Large generated script `0114__id_114.rb` was byte-exact checked via Git blob SHA `6e668c1826471cd694f8978c766ca9856e2f0fce` against the prepared Drive source seed.
- `develop` is based on `main`; it is ahead but is **not** promoted to PASS.
- GitHub contains text Source / Ruby / RGSS / Tools / Tests / Docs / Authority only.
- Complete ZIP, `.rvdata`, Graphics, Audio, Build and runtime/test-log archives remain Google Drive Authority.

## Binary Authority
### Formal Baseline
`01_Current_Baseline/PMD_AutoChess_v1_06_35_CUMULATIVE_OVERWRITE_VXRD_ACCEPTANCE_NONCOMBAT_20260817.zip`

### Current Candidate
`02_Current_Development/PMD_AutoChess_v1_06_53_CUMULATIVE_OVERWRITE_VXRD_LANDMARK_PNG_AUTHORITY_FOUNDATION_I_20260818.zip`

### Windows Live Project Snapshot
`02_Current_Development/PMD_AutoChess_WINDOWS_LIVE_FULL_PROJECT_SNAPSHOT_NEEDS_REVIEW_20260818.zip`
- Drive ID: `1Aqn2pCP9zdl6BXWyCQTE3nLIK4gbA8Oz`
- Size: 254,617,103 bytes
- Actual captured Windows live project snapshot; internal version alignment still requires review and is not an automatic Baseline promotion.

## Completed / Sealed
- PMD Runtime Assets: 468/468 generated runtime assets complete in prior authority.
- Species Authority: 494/494.
- Random Hunt structural runtime: Gate 1 Windows acceptance PASS; SEALED / issue-driven only.
- Battle Presentation: accepted and SEALED / issue-driven only at v1.06.33 chain.
- Core Battle AI / damage / attack speed / spatial endpoints / Focus-C2 architecture are outside current Hunt visual work.

## Gate 2 Current Development
Candidate chain v1.06.36–v1.06.53 covers Hunt contentization and visual authority:
- Hunt visual/style contentization foundation
- RMVX tileset semantic reset
- native A1/A2/A4/A5 autotile rules
- Minimap foundation
- upper-tile B/C/D runtime-ID root-cause correction
- FS-style Map091 universal Event Template Library
- Map091 Hunt/Floor contentization
- Landmark PNG Authority Foundation I

v1.06.53 deliberately uses separate `Graphics/VXRD_Landmarks/` PNGs for landmarks and performs **zero automatic B/C/D/E map tile stamping**.

## Immutable / No-Regression Rules
- Do not promote any Candidate without Windows / RPG Maker VX real-machine PASS.
- Do not alter SEALED Gate 1 structural runtime except issue-driven regression repair.
- Do not alter Battle AI, damage formula, attack speed, Focus/C2 architecture, or spatial endpoints during current Hunt visual work.
- Do not reorder Scripts.rvdata entries for GitHub convenience.
- Map090 remains Random Hunt Runtime Map.
- Map091 is the universal H01–H21 Event Template Library.
- Unknown or obsolete-looking files are archived, not deleted.
- Automatic B/C/D/E scatter remains prohibited.
- v1.06.44 Landmark runtime IDs are revoked and must never be reused as Landmark authority.

## Tileset / Rendering Authority
- RMVX tile cell: 32×32.
- A1: animated/environmental autotiles; water uses native autotile drawing.
- A2: terrain autotiles. Valid base-ground starts: 0, 3, 8, 11, 16, 19, 24, 27.
- A4: wall / dungeon-wall autotiles.
- A5: fixed floor/material tiles; no random one-cell accent scattering.
- A2 floor adjacent to A1 water draws terrain boundary/bank via autotile connectivity.
- A2 floor adjacent to A4 wall does not create a fake A2 border; ground continues beneath the wall.
- B/C/D/E runtime IDs are banked, not direct PNG 16-column row-major indices.
- Current Landmark path: separate PNG assets under `Graphics/VXRD_Landmarks/`.

## Event Authority
- Map090: actual Random Hunt runtime map.
- Map091: universal Event Template Library for H01–H21.
- Event pages / graphics / triggers / conditions live in Map091 and are cloned as `RPG::Event` objects.
- Supported semantic tags include ENTRANCE, EXIT, ENCOUNTER, RARE, ELITE, TREASURE, RECOVERY, RETREAT, INFO; WEIGHT/MAX/UNIQUE/NO_REPEAT; FLOOR/FLOORS; HUNT/HUNTS; FIXED/CONTROL/SHARED/DISABLED.
- Whenever `Data/Map091.rvdata` or other Data files are updated for delivery: **close RPG Maker VX before overwrite, then reopen RMVX after overwrite**.
- Every functional update must also update the Traditional Chinese tutorial / usage documentation.

## Migration Audit
Status: **COMPLETE — no active infrastructure blocker**.
- Google Drive Binary Authority: PASS.
- GitHub Source Authority: PASS / write verified / both branches active.
- Linear Development Authority: PASS.
- Formal PASS v1.06.35 remains separated from unpassed v1.06.53.
- One-time public transport copies used only for GitHub Actions import were deleted after successful import.
- No GitHub binary/build upload was retained.
- SHO-23 GitHub blocker: DONE.
- Remaining `NEEDS_REVIEW` is content/version alignment of the captured Windows live-project snapshot, not an infrastructure blocker.

## Current Development Target
**Resume feature development.**
1. Real-machine visual acceptance of v1.06.53 on **H01 / H04 / H09 / H14 / H19 only**.
2. Primary evidence: screenshots / actual display. Battle LOG is not required unless Runtime or battle behavior itself fails.
3. Only after Visual PASS: start Landmark collision + route audit.
4. Then expand Landmark/contentization to remaining H01–H21 and final event polish.

## Test Authority
- Formal PASS requires Windows / RPG Maker VX real-machine acceptance.
- Static validation is evidence, not promotion authority.
- FAIL requires evidence appropriate to the defect class.
- Visual Hunt defects primarily use screenshots; Battle LOG only when battle/runtime behavior is implicated.

## Naming / Folder Rules
- Runtime script database filename remains `Scripts.rvdata`.
- Version/Phase information belongs in package/docs names, not in the runtime rvdata filename.
- Drive folders follow 00–09 Authority structure.
- Linear uses shared Team `Showpei`, Project `PMD AutoChess Proto`, and only actionable / acceptance-sized current or future issues.
