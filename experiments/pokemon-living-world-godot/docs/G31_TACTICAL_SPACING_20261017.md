# G3.1 v0.5.1 | Real spacing posture + guard recharge | 2026-10-17

## Trigger and scope
User requested continuing development after real G3.0 order verification. G3.0 demonstrated keys 1–4 and conditional actions, yet KEEP_DISTANCE still pursued melee, and DEFENSIVE beat all 3 original test seeds. New standalone lab separates this new behavior from accepted G3.0 and earlier versions.

## Implemented
- `KEEP_DISTANCE` = **target band 118..160 px**: if distance too large, APPROACH; if too small, RETREAT at 1.05x speed with side-step on wall; in band, STRAFE during attack cooldown; when ready, prototype **ZONE** ranged pressure with range 169px, power 8, windup 5 ticks and cooldown 17 ticks. Accuracy computed only by 0.1-second battle clock, never sprite frames.
- Player attack `strike_range`, `strike_power`, `strike_mode` captured when WINDUP begins, not retroactively modified by order change.
- GUARD now has a 25-tick readiness cooldown after activation for both fighters; against enemy telegraph still reduces current hit while active. This is a **candidate** guard-cost policy, not proven balanced.
- UI adds distance, retreat, strafe, zoning-shot and guard counters. Logger adds `SPACE` line and style annotations in `HIT/MISS`; new G31 logs isolated from existing G30.
- Native Godot GDScript gate runs 8 seeds x 4 orders twice (32 scenarios, 64 executions), catches parser errors/determinism and checks the zoning path exists. One-click Windows launcher creates diagnostics ZIP on success or startup failure.

## Regression evidence
- **176/176** Python offline tests pass, including **13 new G3.1** source and reference contracts. The 32-seed/128-match offline matrix is attached in `reports/G31_OFFLINE_POLICY_MATRIX_20261017.json`, **not actual Godot**.
- Offline results: 
  - FREE: Pikachu 3/32 win, Gengar 29/32 win; mean retreat 0, strafe 0, zoning 0, guard 0.
  - AGGRESSIVE: Pikachu 32/32 win, Gengar 0/32 win; mean retreat 0, strafe 0, zoning 0, guard 0.
  - KEEP_DISTANCE: Pikachu 0/32 win, Gengar 32/32 win; mean retreat 159.9, strafe 4.4, zoning 5.0, guard 0.
  - DEFENSIVE: Pikachu 32/32 win, Gengar 0/32 win; mean retreat 0, strafe 0, zoning 0, guard 4.1.

**Limitations:** All tested seeds mostly vary starting Y. KEEP_DISTANCE gains meaningful retreat/strafe but may lose after reaching world boundaries; no evidence of balanced strategies or terrain collision. This iteration addresses the definition of the order, not battle polish or full G3 acceptance.

## Surface instructions
Fetch/Pull isolated GitHub branch, double-click `RUN_G31_DIRECT_SCENE_WINDOWS.bat` without manually selecting scene. Wait for `G31_GATE RESULT samples=32 failures=0`, then 1v1 scene; press `3` followed by `R` for same-seed true distance, `4` followed by `R` for guard recharge. Close game and upload `reports/PLW_G31_DIRECT_DIAGNOSTICS_TO_SHARE.zip`; also screenshot first red engine error if test fails.

No local Pokémon PNG, RAW logs or original source art in public GitHub/ZIP.
