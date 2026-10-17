# G1 v0.3.3 | Gengar XML streaming + imported texture fix | 2026-10-17

## User evidence
- Surface F5 screenshot: Pikachu (#025) and Snorlax (#143) visible, Gengar (#094) generic `Missing local art` and `ready=2/3`.
- Surface Output: `[PLW-G1] #094 耿鬼 failed: XML tag mismatch: AnimData`.
- Six warnings: `Image.load(res://data/raw/pmdcollab/...-Anim.png)` produces a warning about exported builds.
- Earlier downloader: Gengar 102 PNG / 36 animations, credits AVAILABLE; 151/151 source ZIPs verified. **No need to download again**.

## Fix
- `scripts/lab/pmd_sprite_source.gd` now reads XMLParser events scoped to each `<Anim>` instead of maintaining an extra strict full-document tag stack. Preserves `Name`, `CopyOf`, `FrameWidth`, `FrameHeight`, `Duration`, with root/duplicate/empty checks.
- `ResourceLoader.load(sheet_path, "Texture2D")` uses Godot-imported project PNG resources rather than `Image.load()`, which warns about exported-project compatibility.
- `scripts/lab/animation_lab.gd` now shows `LOAD ERROR (see Output)` and correctly labels the count as successfully parsed/loaded, avoiding a misleading missing-art claim.
- 4 new synthetic/static contracts, including upstream-representative CRLF XML containing 36 Anim records.

## Verification
- 45/45 offline Python tests PASS; not a Godot runtime pass.
- **Surface Godot F5 retest PENDING** to observe `已成功解析並載入：3 / 3 種`, Gengar visible and warning count gone.
- Real eight-direction semantics, offsets/size and animation cadence are separate G1 acceptance gates. No copyrighted sprites in repo or bundle.

## Re-test
Close Godot; GitHub Desktop on `planning/pokemon-living-world-godot` -> Fetch origin -> Pull origin (stash local Godot-generated edits if blocked, do not restore old modifications over the fix); reopen Godot; allow import to finish; optionally run `RUN_G1_TESTS_WINDOWS.bat`; F5. If new errors, screenshot Output and Debugger. No asset redownload.

Original upstream: https://github.com/PMDCollab/SpriteCollab/tree/master/sprite/0094
