# PMD AutoChess Proto — Background Execution Authority

> **P0 GLOBAL HARD RULES 001 (2026-11-07)**：本文件任何生成、測試與背景執行都必須先遵守 [跨專案最高儲存規範](https://docs.google.com/document/d/1NftePmIsggrhnfPcZTZS2G6YBka2yBy_fdw-NBT5D8Y/edit)。工程、PNG、測試 LOG、模型中間檔與 ZIP 永久只寫入 Google Drive/GitHub；使用者 PC 只允許必要安裝。若確實必須本機產生臨時檔，事先說明並取得**使用者授權**，完成雲端回讀 SHA 驗證才清理。舊 local/evidence workspace 不再當新路徑。PMD v2.5 雙層生成/原生 RGSS2/SEALED QA 不改；背景視窗執行 != 授權本機儲存。

Version: 2026-08-19

This repository inherits the shared Google Drive authority `SHARED_BACKGROUND_EXECUTION_AUTHORITY` (Drive file ID `1OMLXIcw9MU0Vi3RW4THN0nHQ7ZiDt16LjpODMjq5V7M`).

## Permanent rule
- Runtime, Random Hunt generation, Map091 acceptance, battle simulations, validators, generators/compilers and long-running diagnostics must be background-capable: losing foreground focus must not unnecessarily stop progression.
- Hotkeys may start a diagnostic, but automated progression should continue without foreground keyboard focus and should emit LOG/status evidence.
- Foreground-only work is allowed only for explicitly visual/manual acceptance.
- Background execution does **not** authorize unsafe thread-based mutation of RMVX game-state/UI.
- Prefer normal-loop state machines, staged jobs, detached/offline validators and external tooling.
- Accepted Battle Presentation and SEALED runtime are not reopened merely by this policy; new/touched infrastructure must comply without regression.

## Acceptance
A new infrastructure/harness path is not acceptance-complete if it unnecessarily stops just because another application becomes active.
