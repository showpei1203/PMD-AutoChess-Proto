# CURRENT_HANDOFF — PMD AutoChess Proto

Last Updated: 2026-08-18 15:20 +08:00

## Persistent Authority
Migration is complete. Do not rebuild or roll it back unless a persistent Authority source is genuinely inaccessible.
- Drive = Binary Authority
- GitHub = Source Authority
- Linear = Development Authority
- ChatGPT = workspace only

## Formal Baseline
**v1.06.55 — VXRD Landmark Route Safety Audit I — FORMAL PASS for H01/H04/H09/H14/H19 Phase-I scope.**

Real-machine HISTORY supplied by user on 2026-08-18:
- all recorded H01/H04/H09/H14/H19 runs `RESULT=PASS`;
- every run `EXIT_REACHABLE=1`;
- every `BAD=` is empty;
- H04/H09/H14/H19 include active hard blocked cells without breaking routes;
- H14 duplicate entry is the same run recorded twice, not a failure.

Static validation PASS 31/31. Offline deterministic regression PASS 40/40.

## GitHub
- `main` = v1.06.55 formal PASS source after promotion, 643 scripts, indices 0..642.
- v1.06.55 = Script index 640 / ID 1065500.
- Main index 641; terminator 642.
- `develop` continues from the v1.06.55 PASS point.
- Script Index / ID / Name / exact decompressed Content / execution order must remain preserved.

## SHO-22 Remaining
SHO-22 stays In Progress beyond this Phase-I seal:
1. broader remaining-Hunt / multi-seed route stress;
2. intentionally exercise unsafe Landmark rejection (`REMOVED>0`) where possible;
3. preserve Map091 semantic reachability and sealed Gate 1 topology;
4. only then expand Landmark visual coverage across remaining Hunts.

## New User UX Direction — SHO-35
Random Hunt map generation currently spends time behind a black screen. Add a **real LOADING progress bar** there.

User explicitly wants the Random Hunt Loading UI to reference the existing battle Loading bar.

Reuse authority:
- Script 0415 `Window_PMDBattleResourceLoadingV1029` visual style: centered title + percent, blue bar, stage/detail text.
- Script 0395 `Sprite_PMDLoadingPokemonV1007`: running Pokémon mascot.
- Script 0439 Loading UI refresh throttle: stage-change immediate refresh; same-stage roughly 3% steps or max 180 ms silence.

Map progress must represent real work, not a timer. Intended checkpoints:
1. Hunt request / black overlay;
2. Map090 layout + terrain;
3. Landmark + collision mask;
4. Map091 materialize + semantic relocation;
5. route-safety audit;
6. sprites/map refresh;
7. 100% only when the completed map can reveal immediately.

No artificial delay may be added merely to make the bar animation longer. Loading input passthrough remains disabled. Error cleanup must not leave a permanent black screen.

## Immutable Rules
- No automatic B/C/D/E scatter/stamping.
- v1.06.44 Landmark runtime IDs remain revoked.
- Map090 = Random Hunt runtime map.
- Map091 = H01–H21 shared Event Template Library.
- Gate 1 structure / accepted Battle Presentation remain SEALED / issue-driven only.
- Do not alter Battle AI, damage, attack speed, Focus/C2, rewards or spatial endpoints for Loading work.

## Editor / Documentation Rule
If a candidate updates `Data/Scripts.rvdata`, `Data/Map091.rvdata`, or any other Data file, completely close RPG Maker VX before overwrite and reopen RMVX afterward. Every functional update must include synchronized Traditional Chinese tutorial / usage documentation.
