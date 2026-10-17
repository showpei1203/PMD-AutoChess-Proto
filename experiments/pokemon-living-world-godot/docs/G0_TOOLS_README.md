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

