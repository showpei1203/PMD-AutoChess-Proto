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
- Static validation: PASS 31/31.
- Offline deterministic regression: PASS 40/40 (five Hunts × 8 seeds).
- SHO-22 remains In Progress for broader remaining-Hunt / multi-seed route stress before Landmark coverage expands.
- Next isolated UX candidate: **SHO-35 — Random Hunt Map Loading Overlay — Real Progress Bar**, reusing battle Loading UI authority.

## GitHub Branch Authority
### main
- v1.06.55 formal PASS source after promotion.
- 643 scripts, indices `0..642`.
- v1.06.54 Script index `639`, ID `1065400`.
- v1.06.55 Script index `640`, ID `1065500`.
- Main index `641`; terminator index `642`.

### develop
- Continuation branch from the v1.06.55 PASS point.
- Preserve Script Index / ID / Name / exact decompressed Content / execution order.
- Future v1.06.56 work may implement SHO-35 without altering route topology/battle logic.

## v1.06.55 Windows Route Acceptance
User-supplied `PMD_VXRD_LandmarkRoute_Audit_HISTORY.log`:
- H01: PASS, WALKABLE 719, REACHABLE 719, BLOCKED 0, EXIT_REACHABLE=1, BAD empty.
- H04: PASS, 749 / 747, BLOCKED 2, EXIT_REACHABLE=1, BAD empty.
- H09: PASS, 855 / 854, BLOCKED 1, EXIT_REACHABLE=1, BAD empty.
- H14: PASS, 631 / 630, BLOCKED 1, EXIT_REACHABLE=1, BAD empty. Same run recorded twice; duplicate only.
- H19: PASS, 820 / 818, BLOCKED 2, EXIT_REACHABLE=1, BAD empty.
- All sampled runs REMOVED=0; no unsafe Landmark needed rejection in these real-machine seeds.

## SHO-22 Remaining Work
- Expand deterministic route stress beyond the five accepted Hunts / seeds.
- Exercise unsafe hard-Landmark rejection (`REMOVED>0`) where reproducible.
- Preserve Map091 semantic reachability and sealed Gate 1 topology.
- Only after broader route confidence may Landmark visual coverage expand through remaining H01–H21 Hunts.

## SHO-35 Loading UI Authority
Random Hunt black-screen loading should reuse the battle Loading visual language:
- Script 0415 `Window_PMDBattleResourceLoadingV1029`: centered title/percent, blue progress bar, stage + detail.
- Script 0395 `Sprite_PMDLoadingPokemonV1007`: running Pokémon mascot.
- Script 0439 refresh-throttle policy: stage changes immediate; same stage around 3% steps or max ~180 ms silence; retain 0% and 100%.
- Map percentage must be driven by real checkpoints, not elapsed-time animation: Hunt init → Map090 layout/terrain → Landmark/collision → Map091 materialize/relocate → route audit → sprites/map refresh → 100% reveal.
- Do not lengthen load merely to animate the UI.

## No-Regression Rules
- Automatic B/C/D/E tile scatter/stamping remains prohibited.
- v1.06.44 Landmark runtime IDs remain revoked.
- Map090 remains Random Hunt Runtime Map.
- Map091 remains H01–H21 shared Event Template Library.
- Gate 1 Random Hunt structural runtime / accepted Battle Presentation remain SEALED / issue-driven only.
- Do not alter Battle AI, damage, attack speed, Focus/C2, rewards or spatial endpoints for Loading UI work.
- Do not reorder Scripts.rvdata entries for repository aesthetics.

## Editor / Documentation Rule
Any functional delivery that updates `Data/Scripts.rvdata`, `Data/Map091.rvdata`, or other Data files requires: completely close RPG Maker VX before overwrite, then reopen RMVX. Every functional update must include synchronized Traditional Chinese tutorial/usage documentation.
