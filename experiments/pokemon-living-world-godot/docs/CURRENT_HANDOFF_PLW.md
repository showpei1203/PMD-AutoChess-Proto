# CURRENT HANDOFF | Pokémon Living World (Godot 4.7.2)

**Updated:** 2026-10-17 (Asia/Taipei)  
**Checkpoint:** `PLW_G22_SPECIES_VISUAL_DIRECTOR_CANDIDATE_v041_20261017`  
**Branch:** `planning/pokemon-living-world-godot`  
**G2 status:** G2.0.2 real Surface diagnostics PASS, autonomous mobility PARTIAL (2/3); G2.1 candidate 108/108 offline PASS, Godot Surface F6 PENDING.

## Last user report
After G2.0.1, the Surface G2 scene appeared idle, `tick` did not increase, and D/M/N keys had no observable effect. Root cause **not proven**. Possibilities include wrong scene (F5 launches G1, G2 requires F6), stopped debugger, paused physics, input focus, or AI clock. Existing G1 (three-species animation), G1.1 (roster) and G1.2 (anchor) remain accepted at their previously stated scope.

## This update (G2.0.2 v0.3.9)
- `scenes/ecology_lab.tscn`: standalone Diagnostics CanvasLayer child; no changes to G1/G1.1/G1.2 scenes or project.godot.
- `scripts/lab/ecology_diagnostics.gd`: independent logging for SESSION_START, LOGGER_READY, UI/physics heartbeat, root AI tick, scene identifier, pause state, agents' states/positions/targets, keyboard input and manual clickable M/D/N actions. Flushes each line.
- `scripts/lab/ecology_lab.gd`: early `_input` key handling instead of `_unhandled_key_input` and visible G2.0.2 identifier; the core AI decision/movement policy is otherwise unchanged.
- `RUN_G2_OPEN_LOG_WINDOWS.bat`, `RUN_G2_COLLECT_LOG_WINDOWS.bat`, `tools/g2_collect_logs.py`: one-click Notepad and ZIP export of the diagnostic log. No copyrighted sprite images in log/ZIP.
- `tests/test_g202_runtime_logs.py`: 7 new tests. Offline Python suite **98/98 PASS**; Surface Godot 4.7.2 runtime **PENDING**.

## Exact LOG location and procedure
**Godot editor output:** `<GitHub clone>/experiments/pokemon-living-world-godot/reports/PLW_G2_RUNTIME_LAST.log`. The absolute path prints at startup as `[PLW-G2-LOG] FILE ...`. Fallback for read-only exports is `user://PLW_G2_RUNTIME_LAST.log` (also prints absolute path).
**Upload this ZIP:** `<Godot project>/reports/PLW_G2_DIAGNOSTICS_TO_SHARE.zip`, generated after running `RUN_G2_COLLECT_LOG_WINDOWS.bat`.
1. Close Godot, GitHub Desktop Fetch/Pull the isolated planning branch; stash local `.uid` edits before pull if necessary. Never overwrite user sprite data.
2. Open `scenes/ecology_lab.tscn` and press **F6**. **Do NOT use F5: that launches the accepted G1 scene**. See `G2.0.2 LOGGER ACTIVE` text, wait 10 seconds.
3. Click in-game test buttons M, D, N. Also press keyboard M, D, N; let run for 5 more seconds.
4. Stop game; run `RUN_G2_OPEN_LOG_WINDOWS.bat` then `RUN_G2_COLLECT_LOG_WINDOWS.bat`. Share ZIP and screenshot of any first red Godot debugger error.
5. If no log exists, collect Godot Output and scene screenshot to establish whether Diagnostics even loaded. A rerun overwrites LAST log.

## How to interpret
- No SESSION_START/LOGGER_READY: wrong scene, code not updated or parse/runtime failure.
- LOGGER_READY but no HEARTBEAT: render callback stalled / debugger paused; inspect tree state.
- ui increases, physics stays 0: physics not called; check pause root_physics.
- physics increases, tick stays 0: ecology parent update/counter error.
- tick increases, movement stays 0: inspect ROAM state, target/position, button M event.
- keys absent but buttons logged: keyboard focus/event propagation issue.
- positions change while sprites don't: presentation/anchor/animation bug.


## Latest accepted G2.0.2 evidence (2026-10-17)
User uploaded actual Surface G2.0.2 LOG (171 lines, ~60sec): physics and UI callback HEARTBEAT ticks grow 4→333; keyboard M/D/N and reseeding verified. #025 ~673px and #094 ~367px; #143 0px with IDLE/OBSERVE/REST and no ROAM. Diagnose complete; current G2 ecology gate PARTIAL, not fully accepted. See `docs/G202_SURFACE_RUNTIME_ACCEPTANCE_20261017.md` (GitHub). Mouse button controls not verified.

## G2.1 v0.4.0 (new isolated scene)
See `docs/G21_BOUNDED_BEHAVIOUR_20261017.md`. Added a deterministic max 18sec non-roaming interval to Snorlax (#143) while keeping small radius, speed 16px/s and rest-heavy role. Tracks per species roam count, direction-vector debugging but deliberately does not guess PMD direction rows. Logs to `reports/PLW_G21_RUNTIME_LAST.log`, collect by `RUN_G21_COLLECT_LOG_WINDOWS.bat` to `reports/PLW_G21_DIAGNOSTICS_TO_SHARE.zip`. **108/108 offline tests PASS**, **Godot Surface F6 remains PENDING**. Old G2 scene/G1/G1.1/G1.2/project.godot unchanged. Last G2.0.2 LOG is private, no raw user log uploaded to GitHub.

**Next user test:** GitHub Fetch/Pull on isolated branch → double-click `scenes/ecology_behavior_lab.tscn` (confirm EcologyBehaviorLab > Diagnostics) → F6 → wait ≥30 sec for #143 to ROAM and accumulate distance → try `3` then `M`, `R`, `N`, `D` → stop and share `reports/PLW_G21_DIAGNOSTICS_TO_SHARE.zip` plus a game screenshot. Formal gate remains pending until LOG inspected.

## REQUIRED every subsequent change
Before coding, read this CURRENT_HANDOFF. After EACH iteration update both this file and append dated entry to `docs/HANDOFF_HISTORY_PLW.md`, then mirror into the Drive living Handoff and master roadmap. Include observed evidence, version/commit SHA, specific changed files, offline vs runtime PASS/FAIL, full ZIP, test scripts + LOG + hashes, remaining blockers and next user steps. Never claim Godot acceptance from Python-only tests; preserve sealed G1 and source baselines. No raw Pokémon/PMD art in GitHub or candidate ZIP.
