# G3.1 v0.5.1 | Surface combat-spacing acceptance | 2026-10-17

Checkpoint: `PLW_G31_SURFACE_TACTICAL_SEMANTICS_PASS_BALANCE_PENDING_20261017`
User evidence: uploaded `PLW_G31_DIRECT_DIAGNOSTICS_TO_SHARE.zip`, SHA-256 `1bd0ddb3bc9b206f067b1f22a8d03b85a963ba93fa5021f62cce5f4cf297e7d7`, ZIP CRC PASS. Original user runtime logs/absolute local paths are NOT published to GitHub.

## Engine and native gate
- Godot `4.7.2.stable.official` directly ran `res://scenes/g31_combat_lab.tscn`; `LOGGER_READY build=G3.1-v0.5.1`; headless gate exit 0, `G31_GATE RESULT samples=32 failures=0`. Game ended exit code 0.
- Engine gate evaluated **8 seeds × 4 fixed-order postures, each run twice**, 64 executions in 32 samples. `G31_GATE ZONE_SUMMARY retreat=1299 strafe=37 ranged=41` confirms the native GDScript engine exercised spatial policy, not merely the Python reference implementation.
- Startup/console/gate logs contain no explicit ERROR or WARNING indications (cannot certify every editor debugger category). In-scene log: 485 lines, 40 HEARTBEAT, 80 UNIT, 80 SPACE, 4 KEYBOARD, 2 TRACE_RESTART, 1 RESULT; runtime approx 40 sec.

## Actual Surface user interaction, same-seed tests
- Key `3` (51) at 3.537s -> `ORDER KEEP_DISTANCE` tick26, then `R` (82) at 3.986s resets the SAME seed 20261017 and starts new KEEP_DISTANCE battle. At 22.633s key `4` (52) switched to DEFENSIVE at tick186, then `R` (82) at 23.066s restarted the same seed with DEFENSIVE.
- KEEP_DISTANCE: tick32 `WINDUP style=ZONE range=169 power=8`, tick37 `HIT actor=0 target=1 damage=8`, 5 ZONE ranged attacks, 4 STRAFE events, 113 RETREAT decision steps in the observed KEEP_DISTANCE segment. Debug WHY at tick40 chooses RETREAT utility=116 for distance115.8px (target band118..160).
- DEFENSIVE: `GUARD_COOLDOWN unit=0 ready_at=69` at tick44; next guard at tick69 and again tick94 (25-tick recharge); guarded Gengar hits deal **5** vs normal **11** HP damage, with unguarded strikes between. The user's DEFENSIVE battle reached `RESULT winner=0 reason=KO hp=21/0 tick142`.
- The KEEP_DISTANCE battle was interrupted by the user switching posture at tick186; its **in-scene final winner is not observed**. Use native gate fixed-order results below for isolated comparisons.

## 8-seed fixed posture native Godot gate
| Trainer order | Pikachu wins | Gengar wins | Observed sample duration |
| --- | ---: | ---: | --- |
| FREE | 1/8 | 7/8 | tick 132–136 |
| AGGRESSIVE | 8/8 | 0/8 | tick 126 |
| KEEP_DISTANCE | 0/8 | 8/8 | tick 224–263 |
| DEFENSIVE | 8/8 | 0/8 | tick 142–152 |

## Gate classification
- **PASS (real Surface Godot):** scene launch, native fixed-seed replay 32/32, keyboard ORDER + same-seed restart, conditional movement/RETREAT/STRAFE, ranged style ZONE damage, GUARD 25-tick readiness and actual mitigated hits, autonomous 1v1 terminal result.
- **PENDING/INCOMPLETE:** KEEP_DISTANCE tactical viability (0/8 wins), arena edge/corner escape, policy balance (offense & defense win 8/8), actual visual/natural animation quality (no user screenshot this turn), terrain/obstacle collisions, canonical moves/types/PP, team/PROTECT_ALLY and full G3 seal. Eight seeds mainly vary opening vertical placement; not full scenario coverage.
- **Code:** evidence-only review, **no GDScript changes**. Earlier Python offline 176/176 remains historical, not rerun; latest full **190-file** v0.5.1 Drive ZIP unchanged: https://drive.google.com/file/d/1BtO8Us-r16meu4lnVqtGZVmvD8EpfLnh/view .
- Next work recommended: geometry-aware evasive route selection / corner escape before balance, preserve G30/G23 accepted baselines and same fixed-tick authoritative hit system.

See GitHub `docs/CURRENT_HANDOFF_PLW.md`, append-only `docs/HANDOFF_HISTORY_PLW.md` and Issue #15 plus Drive roadmap.
