# PLW v0.3 — G1 Animation Lab

This ZIP is a complete candidate for the **separate** Godot project root and includes all G0 tooling, G1 scripts/scenes, test code, preflight BAT scripts, docs and reports. No copyrighted PMD art is bundled.

You should normally **Fetch origin → Pull origin on the PLW planning branch** rather than unpacking this ZIP over a working folder.

Surface quick actions:
1. Confirm `data/raw/pmdcollab/0025/AnimData.xml`, `0094`, and `0143` exist locally after the 151-source downloads.
2. Run `RUN_G1_PREFLIGHT_WINDOWS.bat`; inspect `reports/pmd_g1_preflight.json`. Optional: `RUN_G1_ALL151_PREFLIGHT_WINDOWS.bat`.
3. Restart Godot after Pull, open `project.godot`, hit **F5** and take a screenshot.
4. `1/2/3`: focus, `I/W/A`: action, arrows left/right: facing row, `Space`: auto demo.

Verified in build workspace: Python synthetic tests **37/37 PASS**. Godot runtime **NOT run** in build workspace; real animation result depends on your Surface. See `docs/G1_ANIMATION_LAB_20261017.md`.

Complete test: `RUN_G1_TESTS_WINDOWS.bat` (37 current tests); output/log `reports/G1_CHECKPOINT_20261017.log`.
