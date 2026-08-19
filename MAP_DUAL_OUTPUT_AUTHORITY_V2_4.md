# Shared Map Layered Generation Authority v2.4

Effective: 2026-08-19
Scope: Forest Symphony / PMD AutoChess Proto / CG Pet Battle Prototype

This document extends v2.3 and is mandatory for AI-generated layered maps/parallax environments intended for runtime authoring.

## 1. Ground-first remains mandatory
Generate `GROUND` first. Validate its road/path/water/plaza/plot geometry before PAR generation. Ground is the base geometry authority.

## 2. Ground-first alone is NOT enough
A PAR object being in the correct quadrant or approximately near the intended area is not acceptable. Major structures must be bound to explicit Ground anchors before PAR generation.

## 3. Placement Anchor Contract is mandatory
After Ground is accepted and before generating PAR, define a Placement Anchor Contract / footprint manifest for every major PAR structure.

Each anchor should include as applicable:
- unique object/plot ID;
- target bbox/polygon or center/footprint region on Ground;
- object type/owner (`PAR`);
- required nearby path/road relation;
- required water/crossing relation;
- entrance/front-facing relation where meaningful;
- allowed tolerance / acceptance note.

At minimum anchor every major building/landmark, central structure, bridge, gate/arch, market cluster, treehouse, and any object constrained by a Ground plot/water feature/crossing/road. Similar plots require unique IDs; objects may not silently exchange plots.

## 4. Footprint / relationship rules
- A house/building must materially occupy its assigned Ground plot/clearing and must not jump to another plot.
- A building entrance should connect/f face the intended local path when the layout implies one.
- A bridge must span its declared crossing corridor, not another part of the river/stream.
- Fountain/shrine stone structures must register around their declared Ground water/pad anchor, not recreate the water/pad elsewhere.
- Central structures must preserve the declared plaza/axis relationship.

## 5. PAR generation contract
Generate `COMPLETE PAR` only after Ground + Placement Anchor Contract are accepted. Use both as references/constraints. Do not rely on prose like “align closely” as the sole placement instruction.

If a single full-scene generation cannot maintain all anchors, prefer regional/object-group PAR generation tied to locked anchor regions, then assemble on the unchanged Ground canvas. Never solve drift by moving/rescaling Ground.

## 6. Placement QA Gate
After PAR generation, composite `GROUND + PAR` and inspect every declared anchor individually. A major structure on the wrong plot/path/crossing is FAIL even if the whole scene looks attractive.

## 7. Object ownership
`GROUND = true base terrain + floor/road/plaza tiles + grass + flowers + water.`
`PAR = EVERYTHING ELSE.`
Object/content ownership is exclusive by visible structure, not raw alpha occupancy. Ground may reconstruct base material underneath PAR objects but must not duplicate their visible structure.

Bridge structure = PAR-only; under-bridge water/terrain/bank = Ground-only. Fountain stone structure = PAR; fountain water = Ground.

## 8. PAR Purity / Alpha Integrity
PAR may contain only PAR-owned visible objects/structures. It must not include broad semi-transparent copies of Ground-class grass, roads, flowers, riverbank base or water merely to make compositing look smoother.
For normal pixel-art structures prefer alpha 0 or 255; no broad partial-alpha haze, feather halo, anti-alias blur, or sub-pixel drift. Broad partial-alpha coverage is warning/fail evidence unless explicitly approved for a true visual effect.

## 9. Pixel-crisp gate
Runtime pixel layers require hard pixel edges, no blur/soft smoothing, no painterly reconstruction, and Nearest Neighbor for pixel-art resizing/downsampling. Inspect at 100%, 200% or 400%.

## 10. Required workflow v2.4
`Shared Authority -> Project Precheck -> generate Ground only -> Ground geometry QA -> create Placement Anchor Contract / unique plot IDs -> generate PAR from accepted Ground + anchor contract -> per-anchor placement QA -> PAR purity + pixel-crisp QA -> recomposition/witness QA -> Runtime approval`

## 11. Promotion rule
A candidate remains DRAFT if any major anchor is wrong, even when overall registration looks close or the image is attractive. Placement, ownership, alpha purity and pixel crispness are independent gates.