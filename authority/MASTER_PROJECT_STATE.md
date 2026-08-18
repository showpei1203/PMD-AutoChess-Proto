# MASTER_PROJECT_STATE — PMD AutoChess Proto

Last Updated: 2026-08-18 08:20 +08:00

## Project Identity
- Project Name: PMD AutoChess Proto
- Engine: RPG Maker VX / RGSS2
- Google Drive Project Folder: PMD_AutoChess (`1bOgj_4F-O6mxxxXmNT-akHsudWl-dIUK`)
- GitHub Repository: **BLOCKED — connected GitHub account has zero accessible repositories and the installed connector exposes no repository-creation action. Source seed prepared; do not invent a repository.**
- Linear Project: PMD AutoChess Proto (`824907af-a00d-47f8-ab86-d834a8142bd9`)
- Linear Team: Showpei

## Authority Model
- Binary Authority: Google Drive / `01_Current_Baseline`
- Source Authority: GitHub / `main` (pending repository creation)
- Development Authority: Linear / PMD AutoChess Proto
- ChatGPT: development workspace only; never sole permanent Authority

## Version State
- Current Version / Candidate: **v1.06.53 — VXRD Landmark PNG Authority Foundation I**
- Current Baseline: **v1.06.35 — VXRD Acceptance Non-Combat Fixture**
- Latest PASS: **Gate 1 Windows Final Acceptance — all PASS**, evidenced by v1.06.36 release note which explicitly records user Windows Final Acceptance all PASS and seals Random Hunt structural runtime.
- Latest Test Result for v1.06.53: **PENDING USER REAL-MACHINE TEST**. Static validation only; not a Baseline.

## Completed / Sealed
- PMD Runtime Assets: 468/468 generated runtime assets complete in prior authority.
- Species Authority: 494/494.
- Random Hunt structural runtime: Gate 1 Windows acceptance PASS; SEALED / issue-driven only.
- Battle Presentation: accepted and SEALED / issue-driven only at v1.06.33 chain.
- Core battle AI / damage / attack speed / spatial endpoints must not be changed by Hunt contentization or migration.

## Gate 2 Current Development
Candidate chain v1.06.36–v1.06.53 covers Hunt contentization and visual authority:
- Hunt visual/style contentization foundation
- RMVX tileset semantic reset
- native A1/A2/A4/A5 autotile rules
- Minimap foundation
- upper-tile B/C/D runtime ID root-cause correction
- FS-style Map091 universal Event Template Library
- Map091 Hunt/Floor contentization
- Landmark PNG Authority Foundation I

Current candidate v1.06.53 deliberately uses separate `Graphics/VXRD_Landmarks/` PNGs for landmarks and performs **zero automatic B/C/D/E map tile stamping**.

## Immutable / No-Regression Rules
- Do not promote any Candidate without Windows / RPG Maker VX real-machine PASS.
- Do not alter SEALED Gate 1 structural runtime except issue-driven regression repair.
- Do not alter Battle AI, damage formula, attack speed, Focus/C2 architecture, or spatial endpoints during current Hunt visual work.
- Do not reorder Scripts.rvdata entries for GitHub convenience.
- Map090 remains Random Hunt Runtime Map.
- Map091 is the universal H01–H21 Event Template Library.
- Unknown or obsolete-looking files are archived, not deleted.

## Tileset / Rendering Authority
- RMVX tile cell: 32×32.
- A1: animated/environmental autotiles; water uses native autotile drawing.
- A2: terrain autotiles. Valid base-ground starts: 0, 3, 8, 11, 16, 19, 24, 27.
- A4: wall / dungeon-wall autotiles.
- A5: fixed floor/material tiles; no random one-cell accent scattering.
- A2 floor adjacent to A1 water draws terrain boundary/bank via autotile connectivity.
- A2 floor adjacent to A4 wall does not create a fake A2 border; ground is treated as continuing beneath the wall.
- B/C/D/E runtime IDs are banked, not direct PNG 16-column row-major indices. Previous v1.06.44 Landmark stamping was invalid and revoked.
- Automatic B/C/D scattering remains prohibited.
- Current Landmark path: separate PNG assets under `Graphics/VXRD_Landmarks/`.

## Event Authority
- Map090: actual Random Hunt runtime map.
- Map091: universal Event Template Library for H01–H21.
- Event pages / graphics / triggers / conditions live in Map091 and are cloned as RPG::Event objects.
- Supported semantic tags include ENTRANCE, EXIT, ENCOUNTER, RARE, ELITE, TREASURE, RECOVERY, RETREAT, INFO; plus WEIGHT/MAX/UNIQUE/NO_REPEAT, FLOOR/FLOORS, HUNT/HUNTS, FIXED/CONTROL/SHARED/DISABLED.

## Known Issues / Pending
- v1.06.53 visual Landmark PNG candidate has not yet been user real-machine accepted.
- Landmark collision + route audit intentionally deferred until visual acceptance.
- Remaining H01–H21 final visual identity / contentization remains pending.
- Current Drive lacks a verified copy of the user's **current Windows live full project**; accessible full-project handoff v1.06.30 is reconstructible reference only and must not replace the live project. Marked NEEDS_REVIEW.
- GitHub repository creation is blocked by connector capability / no accessible repo. Source exports are prepared but Source Authority is not yet live.

## Current Development Target
**Infrastructure Migration Audit first. Feature development is paused.**
After migration integrity is complete: real-machine acceptance of v1.06.53 on H01/H04/H09/H14/H19, then Landmark collision/route audit only after visual PASS.

## Test Authority
- Formal PASS requires Windows / RPG Maker VX real-machine acceptance.
- Static validation is evidence, not promotion authority.
- FAIL requires log/screenshot evidence appropriate to defect class.
- Visual Hunt issues primarily use screenshots; Battle LOG is not required unless battle/runtime behavior is implicated.

## Naming / Folder Rules
- Runtime script database filename remains `Scripts.rvdata`.
- Version/Phase information belongs in package/docs names, not in the runtime rvdata filename.
- Drive folders follow 00–09 Authority structure.
- GitHub stores text/source only; large binaries remain in Drive.
