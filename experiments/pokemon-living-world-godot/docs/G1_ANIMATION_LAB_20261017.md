# Pokémon Living World — G1 Animated Specimen Lab (candidate v0.3)
**Date:** 2026-10-17. **Engine:** Godot 4.7.2 / GDScript / Compatibility. **Branch:** `planning/pokemon-living-world-godot`.

## Verifiable status
- **G0 SOURCE ACQUISITION: OBSERVED PASS** from user Surface screenshot: `SUMMARY verified=151/151 failed=0` and `Exit code: 0`. This verifies source ZIPs and download script results; it does not mean 151 Godot animations are playable.
- **G1 Python OFFLINE TESTS: 37/37 PASS** in a sandbox: 27 G0 + 10 G1 synthetic tests. No real PMD image data is distributed with this candidate.
- **G1 GODOT RUNTIME ANIMATION: PENDING Surface test.** Godot engine executable/PMD PNG bytes not available to this build workspace. New Godot scene has been written and statically inspected but not runtime proven.

## What this changes
- `project.godot` runs `scenes/animation_lab.tscn` with F5 by default. Old `scenes/main.tscn` remains as bootstrap fallback.
- `scripts/lab/pmd_sprite_source.gd`: load per-species `AnimData.xml`, follow `CopyOf` alias chains (e.g. #148 `Idle -> Walk`), slice real `*-Anim.png` horizontal frames × vertical row IDs, apply per-frame `Duration` data at a provisional 60 ticks per second. Uses Godot native `Image.load`, `ImageTexture`, `AtlasTexture`, `SpriteFrames`, `AnimatedSprite2D`.
- `scripts/lab/animation_lab.gd`: three animated characters on a diagnostic stage (Pikachu #025, Gengar #094, Snorlax #143); action auto-loop and keyboard selection/row switching. No damage, battle AI, pathfinding, offsets, shadows or tactical decision system yet.
- `tools/pmd_g1_preflight.py`: checks downloaded local XML, resolves animation aliases, validates PNG dimensions, 8+ directional rows and frame counts; writes local `reports/pmd_g1_preflight.json`.

## On Surface: how to run
1. Close running game; in GitHub Desktop make sure current branch is `planning/pokemon-living-world-godot`, **Fetch origin → Pull origin**. Keep source art under `data/raw/pmdcollab/` untracked, not manually moved or committed.
2. From the **same Godot project root**, double-click `RUN_G1_PREFLIGHT_WINDOWS.bat`. Expect three PASS results or inspect the JSON report for real missing sheets. `RUN_G1_ALL151_PREFLIGHT_WINDOWS.bat` checks all 151 and may flag species-specific limitations requiring fallback, without deleting art.
3. Open `project.godot` in Godot 4.7.2. Restart the editor after changing `project.godot` externally if still showing old main-scene setting. Press F5 (**not F6** with the old `main.tscn` tab selected). A 960×540 dark blue diagnostic arena with three PMD characters should appear if the data paths are correct.
4. `1/2/3` selects highlight, `I` Idle, `W` Walk, `A` Attack, `← / →` cycles **raw facing row 0..7**; `Space` toggles auto-loop. Watch for clipping, strange scales, missing frames, direction mismatch, attack not returning to Idle, variable sizing and sprites floating. Animation direction index mapping and offset alignment are *unverified*.
5. In Godot bottom `Output`, capture `[PLW-G1] ready=3/3...` and debugger error/warning counts. Screenshot the running animation arena and `reports/pmd_g1_preflight.json`. Only mark G1 preview PASS after human visual acceptance.

## Guardrails / known limitations
- Source sprite art is deliberately never committed to public GitHub; `.gitignore` ignores `data/raw/`.
- PNG preflight checks header/dimensions. The upstream download verifier separately checks ZIP integrity/PNG CRC; G1 does not re-run complete PNG decompression unless explicitly invoked.
- PMDCollab eight row directions are displayed by raw index and need orientation validation. Frame positions use rectangular tiles; *per-frame PMD `*-Offsets.png` and `*-Shadow.png` are not yet integrated*.
- Source clips may have 8 row orientations; very tall sheets or species-specific special cases must be logged, not stretched or guessed. No hardcoded assumption that all 151 have every action.
- The 60 tick/sec PMD duration interpretation is a **candidate** needing side-by-side approval against upstream reference.
- Godot packaging for Windows/Android will need legal and resource-path review; running the editor locally does not grant redistribution permission for art.

## Exit criteria for G1 preview
- 3/3 species render recognizable moving sprites in Godot F5, 0 script errors, Idle / Walk / Attack actually animate, each of 8 rows switches without crash, details and alpha edges reviewed.
- Selected 151 basic XML/PNG sheet metadata summarized (PASS/WARN/FAIL), without claiming 151 art/AI complete.
- Correction of row mapping/foot-anchor offset before starting ecology G2.

## Rollback
- GitHub Desktop: reselect previous PLW commit on isolated branch or temporarily use old `scenes/main.tscn` as project main scene (restore prior `project.godot`).
- Never touch `PMD-AutoChess-Proto/main` or existing Gen1Recomp baselines.
