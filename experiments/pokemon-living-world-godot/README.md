# Pokémon Living World — G0 Asset Audit Candidate v0.1

**Built:** 2026-10-17. **Python 3.10+**, standard library only.

This deliverable has **no copyrighted Pokémon/PMD PNG assets**. It contains scripts, a Windows quick test, synthetic tests, evidence, and the honest G0 report from the Drive source snapshot. Run inside an isolated folder.

## Quick test
Windows: double click `RUN_TESTS_WINDOWS.bat` after Python is installed.

PowerShell equivalent:
```powershell
py -3 -m unittest discover -s tests -v
```

Other systems:
```bash
python3 -m unittest discover -s tests -v
```

Expected result: `Ran 10 tests ... OK`. These tests deliberately use **generated one-pixel PNG images**, not extracted game sprites.

## Actual private source audit
Obtain the complete PMD mod folder or ZIP from the originating device; the Drive Source Snapshot ZIP is only a **source list + Lua + manifest**, not the art.

```powershell
py -3 tools\pmd_asset_audit.py --source "D:\private\pmd_assets.zip" --reference "D:\private\FILE_LIST.txt" --out ".\reports-new" --require-complete
```

- If actual ZIP has `FILE_LIST.txt` internally, omit `--reference`.
- `--source` can also be the **extracted MOD directory**. For directory sources, pass the original source `FILE_LIST.txt` if not in root.
- Reports: `audit_summary.json` and `asset_matrix.csv`.
- Exit `0` with `--require-complete` requires every PNG listed in the reference to be present and structurally valid. Exit `2` means a missing/corrupt source or reference inconsistency, so **do not promote G0**.
- Optional `--stage-private <directory>` copies verified PNG files into a private target for later Godot import. Do not commit or upload these images to a public GitHub repo.
- This tool validates PNG container signature, dimensions, chunk CRC and IEND. Pixel decoding, native action timing, anchor points and true eight-direction animations require future gates.

## Existing snapshot findings
The official Drive ZIP `GEN1RECOMP_PMD_EXACT_SOURCE_20260819_185548.zip` (124,458 bytes) SHA256:
`a9cb2426e661b9cbe9c439a84696badbc139f855f93b19b9c1741120fd468b81`.
It has exactly **4** archive entries: `FILE_LIST.txt`, `main.lua`, `manifest.json`, `SHA256.txt`.
File list references **11,477** PNG files across 151 dex IDs, but the archive contains **zero PNGs**. These are not 11,477 "corrupt" images; these are **not supplied** in this snapshot. The 11,477 rows therefore report `MISSING`, not `PRESENT`.

Check the first G0 report under `reports/audit_summary.json` and `reports/asset_matrix.csv`.

## Original device source hint
The snapshot's original Android paths include:
`/storage/emulated/0/Android/data/io.github.averageconsumer.gen1recomp.androidtest/files/save/pokemon-love2d/mods/pmd_idle_battle_sprites/`
Use this as a hint only; the mod may have moved since the snapshot. Look for the folder with `motion/`, `shadow/`, `sprites/`, `static/`, `dex/` rather than just `main.lua`.

## Baseline policy
Do not modify old Gen1recomp formal baselines. The PLW project lives on GitHub branch `planning/pokemon-living-world-godot` and its Drive project folder. See https://github.com/showpei1203/PMD-AutoChess-Proto/issues/15.

## Update 2026-10-17: upstream download, no need to manually supply original art
The previous source-only Drive snapshot omitted PNGs. This is no longer a request for the user to manually copy files from AYN THOR: official community data is published at https://github.com/PMDCollab/SpriteCollab and https://sprites.pmdcollab.org/.
- Run `RUN_FETCH_3_WINDOWS.bat` to fetch and audit Pikachu, Gengar, Snorlax into ignored `data/raw/pmdcollab/`.
- After preview success, run `RUN_FETCH_151_WINDOWS.bat` to attempt all Kanto species from public `spriteserver.pmdcollab.org` ZIP endpoints.
- Source action format includes `AnimData.xml` and per-action `*-Anim/Offsets/Shadow.png`. Godot visual importer remains a next gate.
- `docs/G0_UPSTREAM_PMD_COLLAB_RECOVERY_20261017.md` explains verified sources, rights, tests and remaining gates.
- 22 offline tests pass, but the live server downloads and 151 actual art are not yet runtime-verified on the Surface.


## v0.2.1 Hotfix — #0148 Dragonair `Idle → CopyOf Walk`
The upstream animation definition may reference another animation rather than a physical `Idle-Anim.png`. The validator now resolves `CopyOf` chains, detects cycles and missing targets, and prints a summary of passes/failures. Synthetic tests **27/27 OK**. The user's previously failed #148 must be revalidated on Surface after `Pull origin`: rerun `RUN_FETCH_151_WINDOWS.bat` (cached successes are reused). Details: `docs/G0_0148_COPYOF_HOTFIX_20261017.md`.

## G1 v0.3.3 (2026-10-17)
Addresses #094 Gengar XML streaming `XML tag mismatch: AnimData` and six Image.load() export warnings. Source parsed per `<Anim>` and PNG resources loaded as Godot Texture2D. Offline Python tests 45/45 PASS. Godot F5 re-test on Surface PENDING; source sprites not included.

## G1.1 | 151-species lazy-loaded gallery v0.3.4
Independent Godot scene `scenes/roster_lab.tscn` (run by opening scene + F6) for browsing dex 001..151 in 3-species pages using `Q/E`. `T` restores accepted benchmark #025/#094/#143; `I/W/A` and facing-row controls remain. The accepted G1 default main scene is intentionally unchanged. `RUN_G11_ROSTER_PREFLIGHT_WINDOWS.bat` produces JSON + CSV with source animation and CopyOf readiness; **no original art included in GitHub**. Pending actual Surface runtime and human visual validation. See `docs/G11_KANTO_GALLERY_20261017.md`.

## G1.2 (v0.3.5, 2026-10-17): manual species calibration candidate

G1.1 Surface gallery operation: **user-reported PASS**, not a per-species directional/offset sign-off. Existing `scenes/animation_lab.tscn`, `scenes/roster_lab.tscn`, and `project.godot` stay unchanged. Open `res://scenes/calibration_lab.tscn` with F6 for a **separate** 1-species manual ground/scale/facing inspector. Controls and draft JSON semantics: `docs/G12_CALIBRATION_LAB_20261017.md`. All 61 local offline tests PASS; real Surface F6 pending. No downloaded copyrighted art included.

## v0.3.6 | PMD native shadow/ink-aware sprite anchor
Fixes a proven bug in G1.2 calibration: placing full frame bottom on ground caused visibly raised characters whenever the transparent frame bottom extended below sprite pixels. New calibration prefers PMD Shadow.png white center, falling back to alpha-ink bottom (with warnings around flying/jumping). The F6 lab supports N-key A/B/C comparison; an optional stdlib-only `RUN_G12_ANCHOR_AUDIT_WINDOWS.bat` emits numeric first-frame 151 species anchor reports. 74/74 offline tests PASS; Surface F6 and actual local 151 PNG audit remain PENDING. No previously accepted gameplay scene changed. See `docs/G12_AUTO_ANCHOR_20261017.md`.
