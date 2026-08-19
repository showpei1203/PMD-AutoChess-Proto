# PMD AutoChess Proto — Asset Generation Precheck

**Mandatory before every image generation or image edit.**

1. Read the shared Google Drive authority: `SHARED_GAME_ASSET_GENERATION_AUTHORITY` (Drive file ID `1TF4wGLqwiALO-IJ_1R-5m9J7fGS-47tKmNi5yH_LMdc`).
2. Read the PMD Drive authority file `ASSET_GENERATION_PRECHECK_PMD` in `PMD_AutoChess/00_Project_Authority`.
3. Identify asset mode: battle/map/landmark/sprite/icon/reusable prop.
4. Apply latest PMD visual, battle and landmark authority before generating.
5. **If the request is any layered map/parallax/environment generation or edit, read `MAP_DUAL_OUTPUT_AUTHORITY_V2_2.md` before generating and explicitly use `COUPLED DUAL OUTPUT + OBJECT OWNERSHIP` mode.**

## Inherited rules
- Runtime isolated assets: prefer chroma-key `#FF00FF` or `#00FF00`.
- Runtime pixel assets: `flat colors`, `no anti-aliasing`, `crisp edges`, approved limited palette.
- **32x32 is the player/tile WORLD-SCALE reference, not a total map-canvas limit and not a monster size cap.** `544x416` is only a viewport reference; large Hunt/parallax/map authoring canvases may exceed it while preserving 32px scale consistency.
- **Monsters/evolutions/bosses are not limited to 32x32 pixels.** Size follows species silhouette, battle role and framing.
- Generic asset rules must not overwrite sealed PMD battle presentation/orientation decisions.
- For map/parallax authoring, preserve `Master + Ground + complete PAR` at identical canvas registration.
- **Ground** contains only true ground/terrain surfaces, floor/terrain tiles, flowers and grass.
- **PAR = everything else.** Buildings, landmarks, statues/fountains, walls, gates, towers, roofs, trees/trunks/canopies, bushes, rocks, fences, signs, stalls, bridges, structural stairs/steps and every environmental prop belong in PAR.
- Occlusion is not the criterion for PAR membership; an actor-covering subset may be derived later by human/tool authority.
- Map split delivery must pass the shared Layer-Split Quality Gate, with `MASTER ≈ GROUND + COMPLETE PAR` as the completeness test.

## Coupled dual-output map generation — v2.2
- Do not generate a complete Master first and later ask a generation model to independently redraw a PAR interpretation.
- For new layered maps, Ground and Complete PAR must be sibling outputs from one shared layout/geometry authority and one object-ownership plan.
- Object ownership is exclusive by **visible structure**, not by raw alpha coordinates. Ground may contain reconstructed water/terrain/floor beneath a PAR object, but must not visibly duplicate that object.
- Bridge structure = PAR-only; under-bridge water/terrain/bank = Ground-only.
- Fountain stone structure = PAR; fountain water = Ground.
- Ambiguous/discrete placed objects default to PAR.
- Candidate remains DRAFT until registration, duplicate-structure, recomposition and normal PMD visual/map QA pass.

## Grounded SAM2 semantic audit authority
- Grounded SAM2 is a **semantic QA / missing-object / candidate-mask assistant**, not final PMD map/layer authority. Never use a raw union mask as Ground / PAR / Collision / Landmark truth.
- Prefer category batches and alias fallback rather than one large mixed prompt, especially for Random Hunt and landmark maps.
- Apply oversized-bbox sanity filtering before unioning masks. Normally localized classes with implausibly large canvas coverage must be flagged/excluded unless human or benchmark review accepts them.
- Use class-specific threshold profiles rather than one global value; small props normally require stricter box thresholds than large architecture, while small landmarks may need lower recall thresholds.
- Compare SAM2 detections and per-class masks against PMD Master/landmark authoring and the complete PAR set to find probable omissions or false positives.
- A SAM2 miss does not authorize deleting a formal object; a SAM2 hit does not override sealed PMD presentation or runtime data.
- SAM2-assisted outputs remain **DRAFT** until normal PMD visual/map validation passes.
- SAM2 workers must comply with Background Execution Authority and should release VRAM after each job on constrained local GPUs.
- **Dense-map refinement:** add post-SAM mask-canvas coverage sanity checks in addition to bbox filtering. When local landmarks/buildings/gates/towers/props are too small in a full scene, use overlapping tiled detection, remap boxes to master coordinates, and de-duplicate with concept-level NMS before SAM2.

## Binary split override
This supersedes older wording that treated PAR as only actor-occluding material:
`GROUND = true ground/terrain surfaces + floor/terrain tiles + flowers + grass`
`PAR = EVERYTHING ELSE`
No non-Ground object may be omitted from PAR because of height, collision, occlusion, importance, or SAM2 classification.

## Required read order
`Shared Authority -> PMD Precheck -> MAP_DUAL_OUTPUT_AUTHORITY_V2_2 when mapping -> latest PMD visual/asset benchmark -> confirm scale/canvas/layer mode -> generate/edit -> optional SAM2 semantic audit -> Layer-Split Quality Gate when mapping`

Version: 2026-08-19 v2.2
