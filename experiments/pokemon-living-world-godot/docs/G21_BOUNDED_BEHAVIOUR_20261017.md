# G2.1 v0.4.0 | bounded Snorlax stroll and behaviour observability | 2026-10-17

**Checkpoint:** `PLW_G21_BOUNDED_BEHAVIOUR_CANDIDATE_v040_20261017`  
**Status:** Offline **108/108 PASS**, actual Godot 4.7.2 Surface F6 **PENDING**.  
**Basis:** Prior real G2.0.2 Surface log showed `tick 4→333`, Pikachu ~673px, Gengar ~367px, Snorlax **0px** for ~60 sec, and real keyboard M/D/N/seed. This observation motivates a bounded idle gap; it does not prove Snorlax's movement mechanics broken.

## Change set
- `scenes/ecology_behavior_lab.tscn`: new isolated optional behaviour scene, separate from accepted `ecology_lab.tscn` baseline.
- `scripts/lab/ecology_behavior_lab.gd`: shared utility/FSM preserved with an **18 sec max non-roaming interval for #143**. As soon as the countdown reaches the bound while IDLE/REST/OBSERVE, it calls existing `_begin_roam` with a seeded *short* target and adds to roam counter; this is not an artificial teleport. Slow walking speed 16px/s and 49px radius remain unchanged. A longer scene run should guarantee at least one natural walk (assuming physics callbacks run).
- `scripts/lab/ecology_behavior_diagnostics.gd`: logs to *G21 separate file* (`reports/PLW_G21_RUNTIME_LAST.log`), preserving original G202 log; records heartbeat, keyboard events, state transitions, targets, `roams` and elapsed time since roam.
- `tools/g21_collect_logs.py`, `RUN_G21_COLLECT_LOG_WINDOWS.bat`: package only runtime text + instructions into `reports/PLW_G21_DIAGNOSTICS_TO_SHARE.zip`, no sprite art.
- `tests/test_g21_bounded_stroll.py`: 10 new offline static/reference checks; total 108 Python unit tests passed. Model guarantee uses Python pseudo-random test, does NOT claim a Godot PRNG-identical replay.
- `RUN_G21_TESTS_WINDOWS.bat`: one-click Windows regression with test log.
- Debug displays `探索次數`, Snorlax countdown and orange heading vector. **Direction vector is only a debug arrow**; sprite raw row0 remains until PMD compass mapping is verified.

## Acceptance gates
1. Godot opened `scenes/ecology_behavior_lab.tscn` (not just selected in FileSystem) and shows `EcologyBehaviorLab > Diagnostics`; F6 displays `G2.1 LOGGER ACTIVE`.
2. With no user input for at least 30 sec, tick grows; #143 eventually reaches `ROAM` and `distance_moved > 0`. Assert that `AGENT #143 ... roams=1` and its position/target differ in `reports/PLW_G21_RUNTIME_LAST.log`.
3. #025 and #094 continue to roam, seed R repeats initial behavior, N changes route. D shows debug and `3`+`M` forces Snorlax to move; screenshot confirms circle and orange heading arrow when moving.
4. Zero new GDScript parser/runtime errors; check both game and Godot debugger. Record if frame anchoring appears to jump.
5. Stop F6 scene, click `RUN_G21_COLLECT_LOG_WINDOWS.bat`, upload `reports/PLW_G21_DIAGNOSTICS_TO_SHARE.zip` and screenshot. Update CURRENT_HANDOFF, history and Issue #15 after review.

## Risks and scope
- This is a small, transparent watchdog for visibly diverse behaviour, not learned intent, living ecology or conservation of biological energy.
- User's earlier forced Snorlax `3→M` test is still not independently reported; new scene asks to check it explicitly.
- Existing G0/G1/G1.1/G1.2 and G2.0.2 files were not modified, and `project.godot` main scene is unchanged.
- No Pokémon/PMDCollab raw sprite art is included in GitHub or ZIP.
