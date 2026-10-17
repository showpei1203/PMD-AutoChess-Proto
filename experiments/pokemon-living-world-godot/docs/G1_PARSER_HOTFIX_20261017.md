# G1 parser hotfix v0.3.1 — 2026-10-17

## Surface evidence / blocker
User screenshot in Godot Engine 4.7.2, Scripts tab:
- `res://scripts/lab/pmd_sprite_source.gd`, line 72, `func resolve_action(action: String) -> Dictionary`
- Godot parser: `Not all code paths return a value.`
- Bottom debugger showed 1 error, 2 warnings, so **G1 animation playback is NOT PASS**.

## Root cause
Original `resolve_action()` uses a `while true` loop to follow PMDCollab `CopyOf` aliases and return a `Dictionary` from its branches, but Godot's typed-return analyzer needs an explicit return on a possible loop exit path.

## Fix
- Replace unbounded loop statement `while true:` with `while not requested.is_empty():`.
- At function end append error for unexpected empty request and explicitly `return {}`.
- Preserve circular `CopyOf` rejection, unavailable source detection, and valid resolved animation returned as `Dictionary`.
- Add a Python static-regression assertion for the required final return path; this does NOT replace the real Godot parser.

## Validation
- Build workspace: Python unittest suite **38/38 PASS** (37 prior tests + 1 source-contract test).
- Godot Engine 4.7.2 compile / run: **PENDING Surface retest**; this environment does not have the Godot editor binary.
- Source art: user's screenshot already showed `verified=151/151 failed=0`; this correction does not change the downloader or the locally cached PNG files.
- Original PMD-AutoChess main branch untouched.

## Next Surface steps
1. Stop running scene / close Godot project temporarily.
2. GitHub Desktop on `planning/pokemon-living-world-godot`: **Fetch origin → Pull origin**.
3. Open `project.godot` again, run `RUN_G1_TESTS_WINDOWS.bat` (expect 38 tests), optionally run `RUN_G1_PREFLIGHT_WINDOWS.bat`.
4. Press F5. Confirm no red parser error and that Pikachu / Gengar / Snorlax animation preview appears.
5. If another error occurs, screenshot the top error AND bottom debugger panel. Do not mark G1 complete before checking animation timing/directions.

## Art boundaries
No PNG copied to public GitHub or ZIP. Existing `data/raw/pmdcollab` under the user's Surface stays in place.
