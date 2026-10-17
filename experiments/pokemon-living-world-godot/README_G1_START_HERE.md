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

## v0.3.2 Godot XMLParser API fix (2026-10-17)
After Surface error `Nonexistent function open_file in base XMLParser`, use Godot 4 API `XMLParser.open(String)`; remove 2 integer-division warnings. Test suite now contains 3 extra API contracts. Re-pull the planning branch and restart Godot; existing downloaded 151 species art remains local and unchanged. G1 real sprite playback still requires Surface F5 confirmation.

## v0.3.3: Gengar #094 recovery (2026-10-17)
Surface Output identified `#094 XML tag mismatch: AnimData` despite the sprite archive previously verifying 102 PNG / 36 animations. The XML reader now accumulates each `<Anim>` record rather than requiring an additional strict tag stack. Six PNG warnings are addressed by using Godot-imported `Texture2D` resources instead of `Image.load()`. Lab now shows `LOAD ERROR (see Output)` rather than incorrectly saying the user lacks PNGs. **45/45 offline Python tests PASS**, but G1 **Surface 4.7.2 runtime still pending**. See `docs/G1_GENGAR_XML_AND_TEXTURE_HOTFIX_20261017.md`.

Do not re-download 151 species. Close Godot, Fetch/Pull isolated GitHub branch, reopen project, F5; expect `已成功解析並載入：3 / 3 種`. Keep local assets ignored and uncommitted.

## v0.3.4 ｜151 物種巡覽場（原 G1 不更動）
已建立 `scenes/roster_lab.tscn`；**請在 Godot 雙擊該場景再按 F6**。原 `project.godot` 主入口保持舊版 `scenes/animation_lab.tscn`，所以 F5 仍可驗收三隻已通過的動畫。

- 首次顯示 025 皮卡丘、094 耿鬼、143 卡比獸，`E/PageDown` 從 #001–003 開始每頁三隻，`Q/PageUp` 反向翻頁，`T` 返回三隻基準。
- `I/W/A` 動作、`←/→` 原始方向列、`Space` 自動輪播、`1/2/3` 選取。
- 在 Surface 先執行 `RUN_G11_ROSTER_PREFLIGHT_WINDOWS.bat`，產出 `reports/pmd_roster_report.csv` 與 `reports/pmd_roster_report.json`，顯示各種動作、CopyOf 來源及 Credits。
- 本版 Build workspace Python 測試 54/54 PASS，Godot Surface 新場景仍 **PENDING**。詳見 `docs/G11_KANTO_GALLERY_20261017.md`。

## G1.2 v0.3.5 (2026-10-17)
New **standalone**, optional `scenes/calibration_lab.tscn`: open in Godot and F6. Q/E changes species (001..151), 1/2/3 selects benchmark, I/W/A changes action, left/right changes raw facing row, Z/X changes scale, up/down/J/L moves frame-bottom ground anchor, B toggles **debug-only** shadow, R resets display scale/anchor, S saves local `user://` JSON draft. Does not modify G1/G1.1 accepted scenes or `project.godot`. Before testing, GitHub Desktop Fetch/Pull isolated planning branch. Run `RUN_G12_CALIBRATION_TESTS_WINDOWS.bat` (expect 61/61 offline PASS). **Surface Godot F6 PENDING**; see docs/G12_CALIBRATION_LAB_20261017.md.
