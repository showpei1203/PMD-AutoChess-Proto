# MASTER_PROJECT_STATE — PMD AutoChess Proto

Last Updated: 2026-08-18 15:20 +08:00

## Persistent Authority
- Google Drive = Binary Authority.
- GitHub `showpei1203/PMD-AutoChess-Proto` = text Source Authority.
- Linear Team `Showpei` / Project `PMD AutoChess Proto` = Development Authority.
- ChatGPT = development workspace only.

## Version State
- Current Formal Baseline: **v1.06.55 — VXRD Landmark Route Safety Audit I — PASS for five-Hunt Phase-I scope**.
- Windows/RPG Maker VX acceptance: H01/H04/H09/H14/H19 route HISTORY PASS on 2026-08-18.
- Static validation PASS 31/31; offline deterministic regression PASS 40/40.
- SHO-22 remains In Progress for broader Hunt / multi-seed route stress before Landmark coverage expands.
- SHO-35 records the next isolated UX direction: Random Hunt black-screen LOADING overlay using existing battle Loading UI authority and real generation checkpoints.

## v1.06.55 Acceptance Authority
- H01: PASS, WALKABLE 719, REACHABLE 719, BLOCKED 0, EXIT_REACHABLE=1, BAD empty.
- H04: PASS, 749 / 747, BLOCKED 2, EXIT_REACHABLE=1, BAD empty.
- H09: PASS, 855 / 854, BLOCKED 1, EXIT_REACHABLE=1, BAD empty.
- H14: PASS, 631 / 630, BLOCKED 1, EXIT_REACHABLE=1, BAD empty; duplicate run record only.
- H19: PASS, 820 / 818, BLOCKED 2, EXIT_REACHABLE=1, BAD empty.
- All real-machine samples REMOVED=0.

## GitHub Branch Authority
### main
- **v1.06.55 formal PASS source**.
- 643 scripts, indices `0..642`.
- v1.06.55 Script index `640`, ID `1065500`.
- Main index `641`; terminator index `642`.
- Script Index / ID / Name / exact decompressed Content / execution order remain preserved.

### develop
- Continues from v1.06.55 PASS for SHO-22 broader stress and SHO-35 Loading UI work.
- Do not promote future candidates without defect-class-appropriate Windows/RMVX acceptance.

## Gate 2 / SHO-22
- v1.06.54 single-prop rendering + semantic collision remains accepted.
- v1.06.55 two-stage route-safety gate is accepted for H01/H04/H09/H14/H19.
- Remaining work: broader remaining-Hunt / multi-seed stress and unsafe-placement rejection coverage before Landmark visual expansion.

## SHO-35 Loading UI Authority
- Reuse Script 0415 battle loading window visual language.
- Reuse Script 0395 running Pokémon mascot.
- Follow Script 0439 refresh-throttle policy.
- Progress must map to real work: Hunt init → Map090 layout/terrain → Landmark/collision → Map091 event materialization/relocation → route audit → sprites/map refresh → immediate 100% reveal.
- Do not add fake timer delay.

## No-Regression Rules
- Automatic B/C/D/E tile scatter/stamping remains prohibited.
- v1.06.44 Landmark runtime IDs remain revoked.
- Map090 remains Random Hunt Runtime Map.
- Map091 remains H01–H21 Event Template Library.
- Gate 1 structural runtime and accepted Battle Presentation remain SEALED / issue-driven only.
- Do not alter Battle AI, damage, attack speed, Focus/C2, rewards or spatial endpoints for Loading UI work.
- Do not reorder Scripts.rvdata entries for repository aesthetics.

## Editor / Documentation Rule
Any functional delivery that updates `Data/Scripts.rvdata`, `Data/Map091.rvdata`, or other Data files requires: close RPG Maker VX before overwrite, then reopen RMVX. Every functional update must also update the Traditional Chinese tutorial/usage documentation.
