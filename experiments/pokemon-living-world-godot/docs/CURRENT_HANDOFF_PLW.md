# CURRENT HANDOFF | Pokémon Living World (Godot 4.7.2)

**Updated:** 2026-10-17 (Asia/Taipei)  
**Checkpoint:** `PLW_G202_LOG_CAPTURE_CANDIDATE_v0.3.9_20261017`  
**Branch:** `planning/pokemon-living-world-godot`  
**G2 status:** **USER-REPORTED FAIL / DIAGNOSIS PENDING**; offline tests pass, new G2.0.2 candidate requires real Surface F6 verification.

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

## G2.0.2 delivery completion after connection interruption
- **GitHub:** source code, G2.0.2 diagnostics scene, one-click runtime LOG collector, tests and this handoff were committed to the isolated branch. Re-read verification completed.
- **Drive complete v0.3.9 ZIP:** https://drive.google.com/file/d/1X5ZbpBvCPVTZqYrWzNFrtxBA1BADI6f7/view. 107 files, archive CRC tested. SHA-256: `42aa22571846afb0b733c31ddcde05523579fe3cbd56b2bee03f62fbf35ac522`.
- **Offline tests:** 98/98 PASS (does not establish Godot run). **Surface F6:** PENDING. User's prior tick/D/M/N failure stays **FAIL** until evidence shows it is fixed.
- **Next evidence:** `reports/PLW_G2_DIAGNOSTICS_TO_SHARE.zip` collected **after** an actual G2 F6 run, as described below; do not upload Pokémon art.
- **GitHub tracker:** https://github.com/showpei1203/PMD-AutoChess-Proto/issues/15.

## Surface log-collection triage — 2026-10-17 (screenshot evidence)
- User launched `RUN_G2_COLLECT_LOG_WINDOWS.bat` and got `G2 LOG NOT FOUND`, exit code 2, with no `PLW_G2_RUNTIME_LAST.log` in the project reports folder.
- Crucial screenshot evidence: **Godot's active scene tab was `calibration_lab.tscn`; the scene tree root was `CalibrationLab`. `ecology_lab.tscn` was only highlighted in the FileSystem pane, not opened as active scene. The debugger process was stopped.**
- Diagnosis: G2 diagnostic scene was **not verified to have run**. Selecting a .tscn in FileSystem does **not** activate it; F6 runs the active/open scene. Log collector's message means file absent, but **does not prove logger failure** in this case.
- Correct Surface retest: Double-click `scenes/ecology_lab.tscn` in FileSystem; verify top active tab reads `ecology_lab` and left scene tree shows `EcologyLab > Diagnostics`; press **F6**. Confirm `G2.0.2 LOGGER ACTIVE`, wait 10 sec, click M/D/N buttons and type keys, stop game; run `RUN_G2_COLLECT_LOG_WINDOWS.bat`.
- Expected log `D:\PMD-AutoChess-Proto\experiments\pokemon-living-world-godot\reports\PLW_G2_RUNTIME_LAST.log`; uploaded evidence `reports/PLW_G2_DIAGNOSTICS_TO_SHARE.zip`. If still absent, capture Godot Output/errors and the active Scene tree.
- Status: **G2 runtime still PENDING/UNVERIFIED**; cannot conclude locomotion tick or logger broken until actual G2 scene executes. No code changes or new offline test results in this triage-only iteration; v0.3.9 ZIP remains the deliverable.

## REQUIRED every subsequent change
Before coding, read this CURRENT_HANDOFF. After EACH iteration update both this file and append dated entry to `docs/HANDOFF_HISTORY_PLW.md`, then mirror into the Drive living Handoff and master roadmap. Include observed evidence, version/commit SHA, specific changed files, offline vs runtime PASS/FAIL, full ZIP, test scripts + LOG + hashes, remaining blockers and next user steps. Never claim Godot acceptance from Python-only tests; preserve sealed G1 and source baselines. No raw Pokémon/PMD art in GitHub or candidate ZIP.

