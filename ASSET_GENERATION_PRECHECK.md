# PMD AutoChess Proto — Asset Generation Precheck

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
