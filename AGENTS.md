# Repository Agent Rules

> **[GLOBAL HARD RULES 001](https://docs.google.com/document/d/1NftePmIsggrhnfPcZTZS2G6YBka2yBy_fdw-NBT5D8Y/edit)（2026-11-07）**：新開發的 Git worktree、PMDCollab 來源 ZIP／PNG、Godot 工程、reports、log、截圖、回歸證據與正式版本只能永久保存到 Drive/GitHub。**不得沿用下面 2026-10 的 Surface GitHub Desktop / local reports 工作路徑作新工作輸出。**確實需在使用者 PC 建立暫存、Native Godot 測試資料時，必須事先說明、取得使用者明確授權，驗證 Drive 回存後清除。App/Android 使用者裝置執行與安裝資料屬正常產品/runtime 需求，不受此條誤禁；不影響歷史 G3.1 / G3.2 Gate。第三方 PMD／Pokémon 素材不得放公開 GitHub。

For any image generation, image editing, game-art asset production, map/landmark visual generation, sprite generation, icon generation, or visual-asset prompt work in this repository, **read `ASSET_GENERATION_PRECHECK.md` before generating or editing any image**. Follow its required read order and the linked shared Google Drive authority.

For any runtime, Random Hunt/Map091 tooling, battle simulation, validator, generator/compiler, long-running diagnostic, automation, or test-harness design/change, **read `BACKGROUND_EXECUTION_AUTHORITY.md` before implementation**. Background-capable execution is a permanent project requirement; losing foreground focus must not unnecessarily stop automated progress. Do not use unsafe thread-based game-state/UI mutation as a shortcut, and preserve accepted/SEALED runtime authorities.

Pure documentation work that changes neither visual assets nor executable/runtime/test/tool behavior does not add extra preflight beyond the existing project authority.
