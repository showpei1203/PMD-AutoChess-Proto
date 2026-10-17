# PLW v0.3.3 — G1 Animation Lab (Gengar XML + texture loader hotfix)

This ZIP is a complete candidate for the **separate** Godot project root and includes all G0 tooling, G1 scripts/scenes, test code, preflight BAT scripts, docs and reports. No copyrighted PMD art is bundled.

You should normally **Fetch origin → Pull origin on the PLW planning branch** rather than unpacking this ZIP over a working folder.

Surface quick actions:
1. Confirm `data/raw/pmdcollab/0025/AnimData.xml`, `0094`, and `0143` exist locally after the 151-source downloads.
2. Run `RUN_G1_PREFLIGHT_WINDOWS.bat`; inspect `reports/pmd_g1_preflight.json`. Optional: `RUN_G1_ALL151_PREFLIGHT_WINDOWS.bat`.
3. Restart Godot after Pull, open `project.godot`, hit **F5** and take a screenshot.
4. `1/2/3`: focus, `I/W/A`: action, arrows left/right: facing row, `Space`: auto demo.

Verified in build workspace: Python synthetic and static regression tests **45/45 PASS**. Godot runtime **NOT run** in build workspace; real animation result depends on your Surface. See `docs/G1_ANIMATION_LAB_20261017.md`.

Complete test: `RUN_G1_TESTS_WINDOWS.bat` (45 current tests); output/log `reports/G1_CHECKPOINT_20261017.log`.

## G1 4.7.2 parser hotfix (2026-10-17)
The first Surface screenshot reported `pmd_sprite_source.gd:72 Not all code paths return a value`. The CopyOf resolver now has an explicit typed `return {}` fallback. Pull the new branch before pressing F5. The original 151 downloaded sprite files are **not modified** and do not need another download. Godot runtime re-test remains pending. See `docs/G1_PARSER_HOTFIX_20261017.md`.

## v0.3.2 Godot XMLParser API compatibility fix (2026-10-17)
Surface error `Nonexistent function 'open_file' in base 'XMLParser'` is fixed with documented `XMLParser.open(xml_path)`. Two integer-division warnings fixed using explicit float calculations. Three static regression tests added; **41/41 offline PASS**. Your locally downloaded 151 species do not need redownloading. Godot run still requires Surface F5 confirmation; see `docs/G1_XMLPARSER_API_HOTFIX_20261017.md`.

## v0.3.3: Gengar #094 XML + PNG warning fixes (2026-10-17)
Surface Output identified `#094 XML tag mismatch: AnimData` despite 102 PNG / 36 animations being downloaded and verified. The XML reader now parses each `<Anim>` record independently. PNG images now load via imported Godot `Texture2D` resources instead of direct `Image.load()`. The on-screen failure text now points at the real Output message. **45/45 offline Python tests PASS**, but **Surface Godot F5 is PENDING**. Original downloaded 151 species remain unchanged. See `docs/G1_GENGAR_XML_AND_TEXTURE_HOTFIX_20261017.md`.
