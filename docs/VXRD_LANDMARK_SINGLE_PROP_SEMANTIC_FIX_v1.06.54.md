# VXRD Landmark Single-Prop Semantic / Presence / Collision Fix v1.06.54

## v1.06.53 failure
- H01/H04/H09/H14: no visible Landmark.
- H19: full 64x64 source atlas rendered as four unrelated 32x32 props in one 2x2 block.
- Hard rock/ore/crystal visuals were pass-through.

## v1.06.54
- Render one 32x32 atlas cell via `Sprite#src_rect`.
- Logical footprint 1x1.
- Minimum presence for H01/H04/H09/H14/H19, with safe non-entrance/non-exit fallback rooms.
- H01 is soft/passable; H04/H09/H14/H19 are hard/blocking.
- Event reservation remains active.
- Full route audit is still deferred.

## Invariants
- No B/C/D/E map table stamping.
- No revoked v1.06.44 runtime upper-tile IDs.
- No battle/reward/progression change.
