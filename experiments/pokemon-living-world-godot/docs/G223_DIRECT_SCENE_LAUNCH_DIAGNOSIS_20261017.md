# G2.2.3 | Direct Scene Launcher and Captured Godot Boot Errors | 2026-10-17

**Checkpoint:** `PLW_G223_DIRECT_SCENE_AND_BOOT_CAPTURE_CANDIDATE_v0.4.1.3_20261017`

## Grounded current evidence
- User feedback: no improvement to G2.2 idle/facing and no actual G22 LOG after G2.2.2.
- User-uploaded `PLW_G22_DIAGNOSTICS_TO_SHARE.zip` was read in full. It has only two plaintext files: `G22_MISSING_LOG_DIAGNOSIS.txt` and `HOW_TO_READ.txt`, with **NO G22 runtime log**. The report names exact expected location `D:\PMD-AutoChess-Proto\experiments\pokemon-living-world-godot\reports\PLW_G22_RUNTIME_LAST.log`. It detects old `G21-v0.4.0` and old `G2.0.2-v0.3.9` logs. These old logs do NOT prove that the latest attempt used the wrong scene. They also do NOT prove the G22 animation scripts fail. The launch stage has no independent evidence yet.
- Previous screenshot showed G2.2 v0.4.1 `ecology_animation_diagnostics.gd:104` undeclared `roams`/`since_roam`; fixed in v0.4.1.1. Real G22 parser success following that fix has NOT been demonstrated.

## Change scope (diagnostic, no actual animation tuning yet)
- Added `RUN_G22_DIRECT_SCENE_WINDOWS.bat`: Windows double-click starts a dedicated launch of **exactly** `res://scenes/ecology_animation_lab.tscn`, without relying on Godot editor active scene / F5 vs F6.
- Added `tools/g22_direct_launch.py` using Python stdlib. Locate Godot via optional `GODOT_EXE` environment variable, prior selected path, PATH, or small nearby-directory scan; otherwise Windows file selection dialog for the Godot executable (one-time). Prefers console build when available.
- Runs Godot with `--path <project> --verbose --log-file <G22_BOOT_LAST.log> res://scenes/ecology_animation_lab.tscn`. Standard output/error captured in `reports/PLW_G22_GODOT_CONSOLE_LAST.log` (GUI EXE may not forward console, Godot `--log-file` supplies additional data).
- **After GAME window is closed**, always writes `reports/PLW_G22_DIRECT_DIAGNOSTICS_TO_SHARE.zip`. Includes `PLW_G22_DIRECT_LAUNCH_REPORT.txt`, Godot engine log, console log, and G22 runtime log **when present**. Source PMD sprites, screenshots and private files are never included. On startup/parser error, report remains available even without runtime logger.
- Previous G22 runtime log is copied to `PLW_G22_RUNTIME_PREVIOUS.log` and removed before launch to distinguish fresh evidence. User's already-downloaded art unaffected.
- Added 5 tests `tests/test_g223_direct_launch.py`: script/scene ID, missing scene ZIP, missing exe ZIP, fake failed Godot execution capture, ZIP excludes PNG files. Existing 129 tests unaffected.

## Verification and acceptance
- **134/134 Python offline tests PASS**. No Godot executable in the development environment; actual Surface Godot 4.7.2 scene launch **PENDING**.
- G22 Idle / eight-direction features remain **UNVERIFIED / USER-REPORTED NO IMPROVEMENT**. Do not promote G2.2 visual acceptance based on Python tests.

## User instructions
1. On Surface close Godot game windows; GitHub Desktop choose `planning/pokemon-living-world-godot`, Fetch/Pull (stash local source edits if blocked).
2. Double-click `RUN_G22_DIRECT_SCENE_WINDOWS.bat` in the Godot project root. On first run, if asked, select the same Godot 4.7.2 `.exe` used for editor. The choice is cached in `reports/PLW_G22_GODOT_EXECUTABLE.txt` (local only).
3. The launcher starts **only G2.2**; run it for ~30 seconds to view resting Snorlax and directional sprites, then **close the GAME WINDOW**. Leave CMD open until it says `DIAGNOSTIC ZIP READY`.
4. Upload `reports/PLW_G22_DIRECT_DIAGNOSTICS_TO_SHARE.zip` regardless of on-screen success or failure. If chooser cannot work, set `GODOT_EXE` in CMD or pass `--godot <exe>` to the Python tool.
5. Determine from the launch report and Godot boot logs whether the first failure is launcher, scene parse, logger, or actual sprite direction logic. Only then adjust GDScript presentation logic.

## Persistence
- Keep G0–G2.1 accepted baselines untouched, no art in GitHub, no changes to default F5 scene.
- Update GitHub/Drive CURRENT_HANDOFF, HISTORY, Master Roadmap, and Issue #15 with each candidate, including fail evidence, tests, ZIP and SHA.
