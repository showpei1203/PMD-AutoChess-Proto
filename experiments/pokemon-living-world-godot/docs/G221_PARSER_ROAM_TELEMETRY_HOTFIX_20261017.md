# G2.2.1 v0.4.1.1 | Godot Surface parser hotfix | 2026-10-17

## Reproducible user evidence
- Surface screenshot Godot 4.7.2: `ecology_animation_diagnostics.gd:104` raises `Identifier "roams" not declared in the current scope` and `Identifier "since_roam" not declared in the current scope`. Script loading fails; G2.2 v0.4.1 is **FAIL** in Surface runtime.
- In same screenshot, active scene is `ecology_lab.tscn` with `EcologyLab > Diagnostics`. `ecology_animation_lab.tscn` was merely highlighted in Godot FileSystem, not opened. Opening the correct G2.2 scene by **double click**, then pressing F6 is required. Old scene and parser error are distinct issues.
- Yellow `.uid` warnings are not the root cause of these undeclared locals.

## Minimal repair
- `scripts/lab/ecology_animation_diagnostics.gd`: declare `var roams: String = str(agent.get("roam_count", "?"))` and `var since_roam: String = str(agent.get("time_since_roam", "?"))` before log string formatting; include `roams` in state-change telemetry key; change GUI text to G2.2.1 and build identifier to `G2.2-v0.4.1.1`.
- `tests/test_g221_runtime_parser_regression.py`: add three offline source contract checks to ensure both variables are defined before use and interpolation field count is consistent.
- Previous G1 / G2.1 scenes, their script logic, source art and Godot project main scene untouched.

## Tests and acceptance
- 125/125 Python offline tests PASS (122 previous plus 3 new). **This is not Godot 4.7.2 parser execution**; Godot is unavailable in build environment.
- G2.2.1 Surface compile, character facing and micro Idle animation: **PENDING F6 retest**.
- Full source/tests/log/Handoff SHA manifest ZIP (137 files) is stored on Drive: https://drive.google.com/file/d/1RnSscBaWJtnrUKEQjpdk05M0Byx0WUKv/view (see handoff for actual finalized URL). ZIP SHA-256: `60553d0c99e80f0ab7138d7ea6daeba2063338637f3cec051d582fd098f5e49a`.

## User re-test steps
1. Close Godot. GitHub Desktop branch `planning/pokemon-living-world-godot`: Fetch origin → Pull origin; stash local edits if necessary (never restore outdated scripts over this fix).
2. In Godot FileSystem **double-click** `scenes/ecology_animation_lab.tscn`; verify top tab `ecology_animation_lab` and left tree `EcologyAnimationLab > Diagnostics`.
3. Press **F6**, not F5. Confirm no parser errors, `G2.2.1 LOGGER ACTIVE` appears and tick increases. Let run 30 seconds: stationary Walk frame 0, occasional one-shot Idle, correct sprite direction E2/W6/N4/S0 and stable ground anchors.
4. Stop F6. Execute `RUN_G22_COLLECT_LOG_WINDOWS.bat`, upload `reports/PLW_G22_DIAGNOSTICS_TO_SHARE.zip` and one screenshot. If red errors persist, send first red line with script path and line number.
