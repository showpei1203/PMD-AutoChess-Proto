# PMD AutoChess Proto — Asset Generation Precheck

**Mandatory before every image generation or image edit.**

1. Read the shared Google Drive authority: `SHARED_GAME_ASSET_GENERATION_AUTHORITY` (Drive file ID `1TF4wGLqwiALO-IJ_1R-5m9J7fGS-47tKmNi5yH_LMdc`).
2. Read the PMD Drive authority file `ASSET_GENERATION_PRECHECK_PMD` in `PMD_AutoChess/00_Project_Authority`.
3. Identify asset mode: battle/map/landmark/sprite/icon/reusable prop.
4. Apply latest PMD visual, battle and landmark authority before generating.

## Inherited rules
- Runtime isolated assets: prefer chroma-key `#FF00FF` or `#00FF00`.
- Runtime pixel assets: `flat colors`, `no anti-aliasing`, `crisp edges`, approved limited palette.
- **32x32 is the player/tile WORLD-SCALE reference, not a total map-canvas limit and not a monster size cap.** `544x416` is only a viewport reference; large Hunt/parallax/map authoring canvases may exceed it while preserving 32px scale consistency.
- **Monsters/evolutions/bosses are not limited to 32x32 pixels.** Size follows species silhouette, battle role and framing.
- Generic asset rules must not overwrite sealed PMD battle presentation/orientation decisions.
- For large map/parallax authoring, preserve `Master + Ground-Only + exhaustive All Non-Ground Objects` at identical canvas registration.
- All Non-Ground Objects must include landmarks, statues/fountains, buildings, walls, gates, trees, props and small environmental objects even when they are not expected to cover the actor.
- Occlusion/Par is derived later by human/tool authority and must not replace the complete Non-Ground layer.
- Map split delivery must pass the shared Layer-Split Quality Gate: exact registration, coherent Ground, exhaustive Non-Ground coverage, clean alpha/edges, no residue/broken holes, and recomposition against Master.

## Required read order
`Shared Authority -> PMD Precheck -> latest PMD visual/asset benchmark -> confirm scale/canvas/layer mode -> generate/edit -> Layer-Split Quality Gate when mapping`

Version: 2026-08-19
