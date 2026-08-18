# PMD AutoChess Proto — Asset Generation Precheck

**Mandatory before every image generation or image edit.**

1. Read the shared Google Drive authority: `SHARED_GAME_ASSET_GENERATION_AUTHORITY` (Drive file ID `1TF4wGLqwiALO-IJ_1R-5m9J7fGS-47tKmNi5yH_LMdc`).
2. Read the PMD Drive authority file `ASSET_GENERATION_PRECHECK_PMD` in `PMD_AutoChess/00_Project_Authority`.
3. Identify asset mode: battle/map/landmark/sprite/icon/reusable prop.
4. Apply latest PMD visual, battle and landmark authority before generating.

## Inherited rules
- Runtime isolated assets: prefer chroma-key `#FF00FF` or `#00FF00`.
- Runtime pixel assets: `flat colors`, `no anti-aliasing`, `crisp edges`, approved limited palette.
- Environment readability uses a 32x32 player/tile reference.
- **Monsters/evolutions/bosses are not limited to 32x32 pixels.** Size follows species silhouette, battle role and framing.
- Generic asset rules must not overwrite sealed PMD battle presentation/orientation decisions.

## Required read order
`Shared Authority -> PMD Precheck -> latest PMD visual/asset benchmark -> generate/edit image`

Version: 2026-08-19
