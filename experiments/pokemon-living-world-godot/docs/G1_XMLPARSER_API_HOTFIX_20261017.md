# G1 v0.3.2 | Godot 4 XMLParser API repair | 2026-10-17

## Surface observed error
User provided screenshot from Godot Engine 4.7.2 (Intel Surface) showing:
- `load_species: Invalid call. Nonexistent function 'open_file' in base 'XMLParser'`, at `scripts/lab/pmd_sprite_source.gd:19`.
- Two GDScript integer division warnings.

## Cause and fix
The documented Godot 4 XMLParser API is `open(file: String)` or `open_buffer(buffer: PackedByteArray)`; **no `open_file` method**. Reference: https://docs.godotengine.org/en/4.3/classes/class_xmlparser.html

- Changed `parser.open_file(xml_path)` to `parser.open(xml_path)`.
- Changed sheet width/height division to explicit float arithmetic before int cast. Previous modulo checks already guarantee exact positive multiples, so there is no functional rounding change.
- Created three offline source-contract tests, including a check that `parser.open_file` never resurfaces.
- Does not touch any downloaded PMD sprites or Nintendo copyrighted asset data.

## Acceptance
- Offline Python test suite **41/41 PASS** (previous 38 + 3 new).
- **Godot 4.7.2 real Surface run: PENDING**. Build environment lacks a Godot binary.
- 151 original PMDCollab source ZIPs already observed verified on Surface, `verified=151/151 failed=0`.
- Final G1 animation display, directions, offsets and hit timing are not yet accepted.

## Surface steps
1. Stop Godot, exit editor, and verify GitHub Desktop active branch is `planning/pokemon-living-world-godot`.
2. Fetch origin -> Pull origin. If blocked by local edits, back them up / stash; do not discard copyrighted local art.
3. Run `RUN_G1_TESTS_WINDOWS.bat` (41 tests expected), restart Godot with `project.godot`, F5.
4. Confirm screenshot has actual 3 sprites and Debugger 0 errors. If an error appears, send only first red error and relevant debugger panel.

## Bundle
Complete v0.3.2 bundle (source + bat + test + logs + full hash manifest) stored in Drive project folder. Public GitHub retains code, logs, docs only.
