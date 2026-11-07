# PMD AutoChess Proto — Asset Generation Precheck

> **P0 GLOBAL HARD RULES 001 (2026-11-07)**：本文件任何生成、測試與背景執行都必須先遵守 [跨專案最高儲存規範](https://docs.google.com/document/d/1NftePmIsggrhnfPcZTZS2G6YBka2yBy_fdw-NBT5D8Y/edit)。工程、PNG、測試 LOG、模型中間檔與 ZIP 永久只寫入 Google Drive/GitHub；使用者 PC 只允許必要安裝。若確實必須本機產生臨時檔，事先說明並取得**使用者授權**，完成雲端回讀 SHA 驗證才清理。舊 local/evidence workspace 不再當新路徑。PMD v2.5 雙層生成/原生 RGSS2/SEALED QA 不改；背景視窗執行 != 授權本機儲存。

**Mandatory before every image generation or image edit.**

1. Read Google Drive shared `SHARED_GAME_ASSET_GENERATION_AUTHORITY`.
2. Read Drive `PMD_AutoChess/00_Project_Authority/ASSET_GENERATION_PRECHECK_PMD`.
3. Apply latest PMD visual/battle/landmark authority.
4. For layered map/parallax/environment work, read `MAP_DUAL_OUTPUT_AUTHORITY_V2_5.md`.

## Current layered-map mode — v2.5
`GROUND-FIRST + PLACEMENT ANCHORS + SOURCE-ASSET/EXTRACTION + DETERMINISTIC ASSEMBLY + PAR PURITY + PIXEL-CRISP`

- Ground = base terrain/floor/road/plaza tiles + grass + flowers + water surfaces.
- PAR = everything else.
- Occlusion is not PAR membership authority.
- Ground is accepted first; major structures then receive unique anchor/footprint contracts.
- Image generation is source-art authority only, not final canvas / exact workcell / coordinate authority.
- Prefer extraction from existing approved/reference art when exact source pixels already exist.
- Final placement uses deterministic integer coordinates on the unchanged Ground canvas.
- Default source-to-target viability profile is `0.75–1.25`; outside is Source Scale FAIL unless explicitly approved.
- Pixel-art resizing uses Nearest Neighbor only.
- Structural alpha normally prefers `0/255`; broad feather/partial-alpha/AA haze is DRAFT/FAIL evidence.
- Validate each object/group before advancing.
- Primary map completeness authority remains `MASTER ≈ GROUND + COMPLETE PAR`.

## PMD inheritance
- 32×32 is world-scale reference, not total map-canvas limit and not a monster size cap.
- Monsters/evolutions/bosses may exceed 32×32 according to species and battle framing.
- Generic generation rules must not overwrite sealed PMD battle orientation/presentation.

## SAM2
SAM2 / Guided SAM2 is QA/omission evidence only; never raw Ground/PAR/Collision/Landmark authority. Do not use a universal whole-mask overlap percentage as a formal Gate.

## Required read order
`Shared Authority -> PMD Drive Precheck -> MAP_DUAL_OUTPUT_AUTHORITY_V2_5 -> latest PMD visual/asset benchmark -> Ground -> Ground QA -> anchors -> source/extraction -> deterministic assembly -> per-object QA -> recomposition/witness QA`

Version: 2026-08-20 v2.5
