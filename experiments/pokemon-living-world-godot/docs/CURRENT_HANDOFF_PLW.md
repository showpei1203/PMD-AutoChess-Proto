# CURRENT HANDOFF | Pokémon Living World (Godot 4.7.2)

**Updated:** 2026-10-17 (Asia/Taipei)  
**Checkpoint:** `PLW_G23_SPECIES_CADENCE_CANDIDATE_v0.4.2_20261017`
**Branch:** `planning/pokemon-living-world-godot`  
**G2 status:** G2.2 correct direction / idle baseline Surface PASS (direct launch confirmed); G2.3 slow species-specific stance/micro actions 146/146 offline PASS, Surface Godot runtime PENDING.


## CURRENT DELIVERY — G2.3 v0.4.2 (2026-10-17)
- **Full 161-file ZIP**: https://drive.google.com/file/d/1VYom0ipsFG0i3KCuA3jxCrv0andzO5pd/view ; SHA256 `9a21d6afa67f5cfc9030071d509f7fad23df480cc426d3074e231360fb74ecc0` (CRC PASS). Earlier G22 artifacts remain archived.
- 146/146 offline Python tests PASS (run again 2026-10-17); Godot runtime of new scene PENDING.
- G2.2 direct-launch Surface accepted (48-second G22 run and user's visual confirmation). G2.3 isolated `scenes/ecology_ambient_lab.tscn`; prior G1/G2.1/G2.2 scenes unmodified.
- Surface: GitHub Desktop Fetch/Pull `planning/pokemon-living-world-godot`, run `RUN_G23_DIRECT_SCENE_WINDOWS.bat`, watch 60–90sec, close the game window and upload `reports/PLW_G23_DIRECT_DIAGNOSTICS_TO_SHARE.zip` with any visual feedback.
- New standby Walk speed scales Pikachu 0.26, Gengar 0.17, Snorlax 0.09; native micro actions considered only if safe PMD anchor. Retain G2.2 facing and movement priority. Status is candidate, not accepted until the Surface run.

## G2.2.3 latest Surface evidence and direct-launch candidate (2026-10-17)
- User uploaded G22 diagnostics ZIP and reports **no improvement**. ZIP has `G22_MISSING_LOG_DIAGNOSIS.txt` but NO G22 runtime log; only prior G21 and G2.0.2 logs detected. **Latest scene startup not established**. Cannot equate missing runtime log with wrong-scene selection or animation logic failure.
- New exact-scene Windows launcher `RUN_G22_DIRECT_SCENE_WINDOWS.bat` invokes `tools/g22_direct_launch.py`, bypasses the Godot editor's scene-tab confusion, and captures both Godot engine `--log-file` and console, even before G22 runtime logger starts. After game exits creates `reports/PLW_G22_DIRECT_DIAGNOSTICS_TO_SHARE.zip` with boot + console + runtime evidence or launch failure reason.
- This is diagnostic instrumentation only: **G22 visual Idle/facing still UNVERIFIED**. G2.1 mobility remains accepted; no GDScript animation or AI files changed.
- Python offline tests **134/134 PASS** including 5 new launch failure simulations. Surface Godot 4.7.2 DIRECT LAUNCH PENDING. More context: `docs/G223_DIRECT_SCENE_LAUNCH_DIAGNOSIS_20261017.md`.
- Next user action: Fetch/Pull, double-click `RUN_G22_DIRECT_SCENE_WINDOWS.bat`, select 4.7.2 Godot executable once if prompted, observe game ~30 seconds, CLOSE GAME WINDOW, wait for `DIAGNOSTIC ZIP READY`, upload `reports/PLW_G22_DIRECT_DIAGNOSTICS_TO_SHARE.zip`. Do not run G22 old collector for this specific test.
- Complete v0.4.1.3 candidate ZIP is archived in Pokémon Living World Drive project folder; authoritative download URL is recorded in GitHub Issue #15 and Drive master roadmap. Preserve all source, tests, logs, and SHA manifest.

## LATEST G2.2.1 diagnostic parser hotfix (2026-10-17)
- User screenshot Godot 4.7.2 shows `ecology_animation_diagnostics.gd:104` parser errors **Identifier `roams` not declared**, **Identifier `since_roam` not declared**, script loading failure. These are coding errors in v0.4.1, not missing PMD art. A few `Missing .uid` warnings were also visible, not the main execution blocker.
- Screenshot active scene top tab: `ecology_lab.tscn` and left tree `EcologyLab > Diagnostics`, while `ecology_animation_lab.tscn` was merely selected in FileSystem. New G2.2 scene must be **DOUBLE-CLICKED** to activate, then F6 (F5 launches G1). Fix both parser and scene selection.
- Hotfix `scripts/lab/ecology_animation_diagnostics.gd` binds `var roams` from `roam_count` and `var since_roam` from `time_since_roam` before telemetry interpolation; active label now reads `G2.2.1`, and log diff key includes roam count. Add 3 new regression tests `tests/test_g221_runtime_parser_regression.py`.
- `RUN_G22_TESTS_WINDOWS.bat` runs **125/125 Python offline PASS**, **not Godot compilation PASS**. G2.2 visual gate remains FAIL/PENDING Surface re-test. G1 and G2.1 source/scene files unchanged.
- Surface actions: Close Godot, Pull isolated planning branch; double-click `scenes/ecology_animation_lab.tscn`; verify left tree `EcologyAnimationLab > Diagnostics`; F6; check **no parser errors**, `G2.2.1 LOGGER ACTIVE` and `tick` increasing; observe 30s, cardinal directions and card #143 stance; stop F6, execute `RUN_G22_COLLECT_LOG_WINDOWS.bat` and upload `reports/PLW_G22_DIAGNOSTICS_TO_SHARE.zip` with screenshot.
- Log path: `<Godot project>/reports/PLW_G22_RUNTIME_LAST.log`. Missing log before successfully opening/running new scene does not prove logger malfunction.
- Complete hotfix ZIP contains source, G1/G2 baseline, BAT shortcuts, offline test log, Handoff, release notes and SHA manifest, *no copyrighted images*. SHA-256 and Drive URL are supplied in external Issue/Drive Handoff after upload, avoiding self-referential hashes.
- Mandatory every iteration: update GitHub & Drive Current/History Handoff, Issue #15, roadmap; distinguish offline PASS from Surface F6 PASS.

## CURRENT G2.2 v0.4.1 source of truth (supersedes historical sections below)
- Verified user G2.1 33-second runtime ZIP: 95 text lines, 33 heartbeats, SHA256 `a450cf80889287a00cdc8f275507dfc0efa83479f9fc9dc38870ca1951c51fe1`. #143 Snorlax walked autonomously after 19 sec (~41.6px), then user keys 3+M forced further motion to 80px. #025 ~785px and #094 ~441px. G2.1 movement confirmed, animation visual direction not accepted.
- User reports continuous native `Idle` hopping and all characters displaying front-row sprite while moving. Prior Gen1recomp `290_CG_PMD_Species_Personality_Rich_Ambient_Authority_v2.8.5b.rb` demonstrates one-shot ambient with cooldown / movement preemption, borrowed as a design principle, not copied exact action speeds.
- **New independent scene** `scenes/ecology_animation_lab.tscn` + `scripts/lab/ecology_animation_lab.gd` + `scripts/lab/pmd_visual_policy.gd`, using paused first frame of `Walk` as stationary body pose and occasional *one-shot* native `Idle` at different species intervals, interrupted by motion. Distinct visual speed scales #025 MOVE1.32x, #094 MOVE1.0x, #143 MOVE0.58x; native XML frame durations preserved. G2.1 source frozen unchanged.
- **Direction** PMD sheet rows S0/SE1/E2/NE3/N4/NW5/W6/SW7; movement vector selects row, previous row retained at standstill. Native Shadow/alpha ground-point alignment uses same render row, including cached-row switches. Source: PMDSpriteManager PMD sheet convention, visual verification on Surface still necessary.
- Tests: **122/122 Python offline PASS**, build workspace has no Godot Engine executable, **G2.2 Surface F6 NOT VERIFIED**. Old G1/G2.1 scene files retained; no copyrighted art in GitHub/ZIP.
- GitHub main candidate commit `2d1c6d26b4c8c649a27c4326f158bc79cf09c72b`; detailed spec `docs/G22_ANIMATION_DIRECTION_AUTHORITY_20261017.md`, tracking Issue #15.
- New full candidate ZIP: `PLW_G22_PMD_Animation_Director_v0.4.1_HandoffFixed_20261017.zip` uploaded into PLW Drive folder (latest release); includes complete source, shortcuts, Handoff, tests, LOG and SHA manifest.
- **Surface test:** GitHub Desktop Fetch/Pull isolated branch. **DOUBLE-CLICK** `scenes/ecology_animation_lab.tscn`, confirm `EcologyAnimationLab > Diagnostics`, then F6 (F5 remains G1). Watch #143 stationary normally stable Walk frame0, rare one-shot Idle; #025 hops occasionally; when sprites travel left/right/up/down actual PMD facing must change. Monitor feet/shadow when turning.
- **LOG:** `reports/PLW_G22_RUNTIME_LAST.log`; stop F6 and run `RUN_G22_COLLECT_LOG_WINDOWS.bat` to generate `reports/PLW_G22_DIAGNOSTICS_TO_SHARE.zip`. User upload this ZIP + screen image. G22 visual gate PENDING, 151 species audit future.
- **Mandatory every iteration:** update GitHub/Drive Current Handoff, append Handoff History, update Roadmap/Issue, maintain full ZIP+quick tests+LOG+SHA, and preserve user raw art only in `data/raw/pmdcollab`.

## Historical context (do not treat older pending statuses as current)
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


## G2.3 v0.4.2 NEW CURRENT CHECKPOINT (2026-10-17)
- **User confirmed G2.2 works** and supplied direct-launch ZIP with real G2.2 LOG: `LOGGER_READY G2.2-v0.4.1.1` in correct `ecology_animation_lab.tscn`, Godot exit=0, ~48sec and tick up to 472. Final cumulative motion ~975 px Pikachu, ~790 px Gengar, ~46 px Snorlax. Existing G2.2 scene and G2.1 remain approved at their demonstrated scope.
- **User request**: idle should not be frozen; play Walk slower and design each Pokémon's rhythm / safe action combinations. New independent scene `ecology_ambient_lab.tscn` inheriting G2.2 and new `pmd_ambient_cadence_policy.gd` meets this as a candidate; `EcologyAmbientLab > Diagnostics` new root.
- STANCE loop Walk speed per species: Pikachu 0.26, Gengar 0.17, Snorlax 0.09; micro actions wait 5-8.5 / 8-13.5 / 18-28 sec stationary. Extra Float/Pose/Nod *only* if native shadow-point within 5px of Walk; fallback Idle if unavailable. AI, navigation, original G2.2 facing and anchors untouched.
- **Offline Python tests 146/146 PASS**, no Godot binary in build environment; **G2.3 Surface F6/runtime PENDING**. Never claim completed G2.3 visual acceptance before user's next run. Direct launcher generates `reports/PLW_G23_DIRECT_DIAGNOSTICS_TO_SHARE.zip` with BOOT, CONSOLE, RUNTIME text; reuses G22 Godot path.
- Read `docs/G23_SPECIES_CADENCE_20261017.md`. Next user action: Fetch/Pull; double click `RUN_G23_DIRECT_SCENE_WINDOWS.bat`; observe 60-90s; close game; upload G23 direct log ZIP and visual feedback.
- New code in independent stage; previously accepted `scripts/lab/ecology_animation_lab.gd`, `ecology_behavior_lab.gd` and corresponding scenes remain untouched. Preserve complete ZIP, tests, hash, Handoff history and Issue #15.

## Latest accepted G2.0.2 evidence (2026-10-17)
User uploaded actual Surface G2.0.2 LOG (171 lines, ~60sec): physics and UI callback HEARTBEAT ticks grow 4→333; keyboard M/D/N and reseeding verified. #025 ~673px and #094 ~367px; #143 0px with IDLE/OBSERVE/REST and no ROAM. Diagnose complete; current G2 ecology gate PARTIAL, not fully accepted. See `docs/G202_SURFACE_RUNTIME_ACCEPTANCE_20261017.md` (GitHub). Mouse button controls not verified.

## G2.1 v0.4.0 (new isolated scene)
See `docs/G21_BOUNDED_BEHAVIOUR_20261017.md`. Added a deterministic max 18sec non-roaming interval to Snorlax (#143) while keeping small radius, speed 16px/s and rest-heavy role. Tracks per species roam count, direction-vector debugging but deliberately does not guess PMD direction rows. Logs to `reports/PLW_G21_RUNTIME_LAST.log`, collect by `RUN_G21_COLLECT_LOG_WINDOWS.bat` to `reports/PLW_G21_DIAGNOSTICS_TO_SHARE.zip`. **108/108 offline tests PASS**, **Godot Surface F6 remains PENDING**. Old G2 scene/G1/G1.1/G1.2/project.godot unchanged. Last G2.0.2 LOG is private, no raw user log uploaded to GitHub.

**Next user test:** GitHub Fetch/Pull on isolated branch → double-click `scenes/ecology_behavior_lab.tscn` (confirm EcologyBehaviorLab > Diagnostics) → F6 → wait ≥30 sec for #143 to ROAM and accumulate distance → try `3` then `M`, `R`, `N`, `D` → stop and share `reports/PLW_G21_DIAGNOSTICS_TO_SHARE.zip` plus a game screenshot. Formal gate remains pending until LOG inspected.

## REQUIRED every subsequent change
Before coding, read this CURRENT_HANDOFF. After EACH iteration update both this file and append dated entry to `docs/HANDOFF_HISTORY_PLW.md`, then mirror into the Drive living Handoff and master roadmap. Include observed evidence, version/commit SHA, specific changed files, offline vs runtime PASS/FAIL, full ZIP, test scripts + LOG + hashes, remaining blockers and next user steps. Never claim Godot acceptance from Python-only tests; preserve sealed G1 and source baselines. No raw Pokémon/PMD art in GitHub or candidate ZIP.
