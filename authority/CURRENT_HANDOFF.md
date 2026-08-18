# CURRENT_HANDOFF — PMD AutoChess Proto

Last Updated: 2026-08-18 16:10 +08:00

## Persistent Authority
Migration is complete. Do not rebuild or roll it back unless a persistent Authority source is genuinely inaccessible.
- Drive = Binary Authority
- GitHub = Source Authority
- Linear = Development Authority
- ChatGPT = workspace only

## Current Formal Baseline
**v1.06.56 — VXRD Random Hunt Real Loading Overlay I — FORMAL PASS.**

Windows/RPG Maker VX acceptance on 2026-08-18:
- supplied screenshot visually confirms Battle-style Random Hunt Loading UI during H01 Floor 1;
- `PMD_VXRD_MapLoading_LATEST.log` reports `RESULT=PASS`;
- `FINAL_PERCENT=100`;
- `REAL_CHECKPOINTS=1`;
- `FAKE_TIMER=0`;
- `INPUT_PASSTHROUGH=0`;
- observed load 4353 ms, Loading UI total 151 ms, max UI refresh 23 ms.

## GitHub
- `main` = v1.06.56 formal PASS source after promotion.
- 644 scripts, indices `0..643`.
- v1.06.55 = index 640 / ID 1065500.
- v1.06.56 = index 641 / ID 1065600.
- Main = 642; terminator = 643.
- v1.06.56 exact new source SHA256 `029c0a557ac44677d24110f8ca7be2933aa0c9296f5dc440e989f551d64f7d28`.
- Script Index / ID / Name / exact Content / execution order remain preserved.

## Binary Authority
Formal Baseline:
`01_Current_Baseline/PMD_AutoChess_v1_06_56_FORMAL_PASS_BASELINE_RANDOM_HUNT_REAL_LOADING_OVERLAY_I_20260818.zip`
Drive ID `1JuKQu89h6GEOs6YoxiMFafVBYLTHM_fT`.

Accepted candidate archive remains Drive ID `1dts6xH3ozPwVTfjIUOfIawPulOY8qYQh`.

## SHO-35 Result
**DONE / PASS.**
Random Hunt black-screen loading now uses the Battle Loading visual family with real progress checkpoints, no fake timer and no input passthrough.

## Immediate Development Target
Return to **SHO-22 — Landmark II: Collision / Route Audit**.
Next work is broader automated route stress rather than more manual walking:
1. expand deterministic seed coverage;
2. intentionally exercise unsafe hard-Landmark rejection so `REMOVED>0` is proven;
3. include unique corridor throat and semantic-event branch adversarial cases;
4. preserve Gate 1 topology and Map091 semantic reachability;
5. after broad route confidence, enable Landmark visuals for additional Hunts.

## Immutable Rules
- No automatic B/C/D/E scatter/stamping.
- v1.06.44 Landmark runtime IDs remain revoked.
- Map090 = Random Hunt runtime map.
- Map091 = H01–H21 shared Event Template Library.
- Gate 1 structure / accepted Battle Presentation remain SEALED / issue-driven only.
- Do not alter Battle AI, damage, attack speed, Focus/C2, rewards or spatial endpoints for route stress.

## Editor / Documentation Rule
If a future functional candidate updates `Data/Scripts.rvdata`, `Data/Map091.rvdata`, or another Data file, completely close RPG Maker VX before overwrite and reopen RMVX afterward. Every functional delivery must update the Traditional Chinese tutorial/usage documentation.
