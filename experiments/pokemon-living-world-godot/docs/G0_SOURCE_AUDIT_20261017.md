# G0 Source Seal Investigation | 2026-10-17

## User's Surface Pro 7 boot acceptance
- Observed Godot 4.7.2.stable in editor and real F5 bootstrap window screenshot.
- Godot output `[PLW] bootstrap ready; G0 asset/source verification PENDING`.
- The output bar shows **0 errors and 0 warnings** in the provided screenshot; game process stopped normally.
- `EDITOR OPEN` = OBSERVED PASS; `F5 BOOT` = OBSERVED PASS; `G0 ORIGINAL ASSETS` = NOT PASSED.

## Source archive verified
- Google Drive Source Snapshot folder: https://drive.google.com/drive/folders/1m-L1WvQk7aoCz3qLswIBOZBaONyJs6nn
- ZIP: `GEN1RECOMP_PMD_EXACT_SOURCE_20260819_185548.zip`, 124,458 bytes.
- ZIP SHA256: `a9cb2426e661b9cbe9c439a84696badbc139f855f93b19b9c1741120fd468b81`.
- Valid ZIP test: no corruption detected by Python `zipfile.testzip()`.
- ZIP entries: FILE_LIST.txt, main.lua, manifest.json, SHA256.txt. No source PNG bytes.
- FILE_LIST references 11,477 PNG paths: motion 5,134, shadow 5,436, sprites 302, static 302, dex 151, dex70 151, assets 1.
- All 151 dex IDs are recorded as **reference IDs** but **not yet verified as binary images**.
- 11,477 MISSING (compared with this ZIP), 0 PRESENT, 0 INVALID.
- G0 gate remains OPEN. Eight-direction semantics require examining genuine PMD sheets: `_player` and `_enemy` are not proof of 8 facings.

## Toolchain deliverables
- `tools/pmd_asset_audit.py`: inspect references, ZIP/folder contents, PNG structural integrity, IDs, optional private staging; return strict exit 2 if incomplete.
- `tests/test_pmd_asset_audit.py`: 10 deterministic stdlib tests with synthetic test PNGs; PASS on container Python.
- `RUN_TESTS_WINDOWS.bat`: quick tests on Surface Pro 7 after Python installation.
- `RUN_AUDIT_WINDOWS.bat`: drag-and-drop actual complete PMD ZIP, produce coverage matrix.
- `reports/audit_summary.json` + 11,477-row `asset_matrix.csv`: precise actual-source-gap evidence.

## Next action/blocker
Find the actual source folder named `pmd_idle_battle_sprites` from Android Gen1recomp saved mod path, or a complete binary backup. Avoid pushing copyrighted PNG art to public GitHub.
Only after its SHA and PNG matrix are verified may G0 be marked PASS and the Godot importer implement per-sprite slicing/anchors/action timing.

