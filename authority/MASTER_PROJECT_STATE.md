# MASTER_PROJECT_STATE — PMD AutoChess Proto

Last Updated: 2026-08-18 16:03 +08:00

## Persistent Authority
- Google Drive = Binary Authority.
- GitHub `showpei1203/PMD-AutoChess-Proto` = text Source Authority.
- Linear Team `Showpei` / Project `PMD AutoChess Proto` = Development Authority.
- ChatGPT = development workspace only.

## Version State
- Current Formal Baseline: **v1.06.55 — VXRD Landmark Route Safety Audit I — PASS for H01/H04/H09/H14/H19 Phase-I scope**.
- Current Candidate: **v1.06.56 — VXRD Random Hunt Real Loading Overlay I — UNPASSED**.
- v1.06.56 Ruby syntax: PASS.
- v1.06.56 static validation: **26/26 PASS**.
- SHO-22 remains In Progress for broader remaining-Hunt / multi-seed route stress.
- SHO-35 is the active isolated UX candidate and must not alter route topology or battle logic.

## GitHub Branch Authority
### main
- v1.06.55 formal PASS source.
- 643 scripts, indices `0..642`.
- v1.06.55 Script index `640`, ID `1065500`.
- Main index `641`; terminator `642`.

### develop
- v1.06.56 unpassed Candidate source.
- 644 scripts, indices `0..643`.
- v1.06.56 Script index `641`, ID `1065600`.
- v1.06.56 exact source SHA256 `029c0a557ac44677d24110f8ca7be2933aa0c9296f5dc440e989f551d64f7d28`.
- Main index `642`; terminator `643`.
- Script Index / ID / Name / exact Content / execution order are preserved.

## Drive Binary Authority
- Formal Baseline remains v1.06.55 in `01_Current_Baseline`.
- Current Candidate: `02_Current_Development/PMD_AutoChess_v1_06_56_CUMULATIVE_OVERWRITE_RANDOM_HUNT_REAL_LOADING_OVERLAY_I_20260818.zip`, Drive ID `1dts6xH3ozPwVTfjIUOfIawPulOY8qYQh`.
- Test Build: `03_Test_Builds/PMD_AutoChess_v1_06_56_TEST_BUILD_UNPASSED_20260818.zip`, Drive ID `1LUuIRCYZBszUEOBkZYd8esJpzyWkOZ1s`.
- v1.06.56 updates `Data/Scripts.rvdata`; `Data/Map091.rvdata` is unchanged.

## v1.06.56 Loading Authority
Random Hunt black-screen loading reuses accepted Battle Loading presentation:
- centered title + percent / blue progress bar / stage + detail hierarchy from battle loading;
- running Pokémon mascot from `Sprite_PMDLoadingPokemonV1007`;
- refresh-throttle principle: stage changes immediately; same stage around 3% or max 180 ms silence.

Progress is tied to real work, not elapsed-time animation:
0% open loading overlay → Map090 layout/terrain → Landmark/collision → pre-event route audit → Map091 materialize/semantic relocation → post-event route audit → floor finalize → map/spriteset ready → 100% immediate reveal.

## Immediate Acceptance
Install v1.06.56 with RPG Maker VX completely closed, then reopen RMVX and test:
1. first Random Hunt entry from Hunt Selector;
2. next-floor generation;
3. leave and enter another Hunt.

Confirm Battle-style Loading is visible, percentage never goes backward, stage/detail changes, mascot moves, 100% reveals immediately, and there is no white flash / stale old-map residue / premature map reveal / input passthrough.
Primary evidence: one Loading screenshot plus `PMD_VXRD_MapLoading_LATEST.log`.

## No-Regression Rules
- Automatic B/C/D/E tile scatter/stamping remains prohibited.
- v1.06.44 Landmark runtime IDs remain revoked.
- Map090 remains Random Hunt Runtime Map.
- Map091 remains H01–H21 shared Event Template Library.
- Gate 1 Random Hunt structure / accepted Battle Presentation remain SEALED / issue-driven only.
- Do not alter Battle AI, damage, attack speed, Focus/C2, rewards or spatial endpoints for Loading work.

## Documentation Rule
Every functional update must include synchronized Traditional Chinese tutorial/usage documentation.
