# PMD AutoChess — VXRD Dedicated Landmark Asset Production Spec

Authority date: 2026-08-18
Formal runtime baseline: **v1.06.58 FORMAL PASS**

## Runtime contract
All new Random Hunt Landmark art must reuse the accepted v1.06.54+ PNG-atlas renderer and v1.06.55 Route Safety.

- Master PNG canvas: **64×64 px**, transparent RGBA.
- Atlas layout: **2×2 cells**, each cell exactly **32×32 px**.
- Every 32×32 cell must be a complete standalone prop. Never split one large object across cells.
- Runtime draws only one 32×32 cell at a time.
- Hard props must use blocking semantic; soft ground-cover/vegetation may be passable.
- Hard props must not visually read like flowers/grass; soft props must not visually read like solid boulders.
- Prefer compact silhouettes readable at native 1× scale.
- No building fragments, half trees, cropped architecture, or giant TileB/C/D/E-looking chunks.
- Transparent padding is allowed inside a cell, but the visible object must remain centered and legible.
- No automatic B/C/D/E map-table scatter/stamping.
- Approved PNG only enters runtime after visual QA and manifest status becomes `APPROVED`.

## Existing accepted atlases
- `forest_green_a.png` — soft/passable vegetation.
- `forest_flower_a.png` — soft/passable flowers.
- `dry_rock_a.png` — hard/blocking dry rocks.
- `cave_crystal_a.png` — hard/blocking cave crystals.
- `mine_ore_a.png` — hard/blocking ore/mineral chunks.
- `volcanic_ore_a.png` — hard/blocking volcanic ore/rock.

## Batch A — dedicated biome identity

### H05 月影古徑 / Relic
Target atlas: `relic_moonstone_a.png`
Semantic: **hard / blocking**
Visual brief: four small ancient path stones / weathered moon-marked relic stones. Low, old, moss-worn or moon-pale stone. No altar, wall, pillar fragment, building corner, or oversized monument. The silhouette must read as a complete 32×32 object.

### H08 雷羽石道 / Storm
Target atlas: `storm_charged_rock_a.png`
Semantic: **hard / blocking**
Visual brief: four compact storm-weathered stones with subtle pale/electric mineral veins or scorched edges. Avoid literal lightning-bolt icons, modern machinery, poles, or large props. It should still read as a physical rock first.

### H10 夢霧碑地 / Mystic
Target atlas: `mystic_rune_stone_a.png`
Semantic: **hard / blocking**
Visual brief: four complete small rune stones / mist-worn marker stones. Mysterious but restrained. No full shrine, tall obelisk, or cropped monument. Rune/glow accents must not dominate the stone silhouette.

### H11 古木根域 / Ancient Root
Target atlas: `ancient_root_a.png`
Semantic: **hard / blocking**
Visual brief: four compact exposed-root / old stump-root clusters. Must read as natural ancient roots, not four forest-green shrubs recycled from earlier Hunts. No half tree trunk extending beyond the 32×32 cell.

### H12 霜湖雪原 / Ice Lake
Target atlas: `ice_shard_a.png`
Semantic: **hard / blocking**
Visual brief: four low ice shards / compact frozen crystal-rock formations suitable beside snow and clear-bottom frozen water. Avoid giant icebergs, tall spires, or fragments cut by the cell boundary.

## Batch B — deferred after Batch A benchmark
- H13 暴風裂谷 / Canyon → wind-eroded canyon rock family.
- H15 幽光祭地 / Ritual → small ritual/rune stone family, complete object only.
- H17 深潮冰灣 / Deep Ice → deeper/frost-dark ice-rock family distinct from H12.
- H18 龍風峽谷 / Dragon Canyon → dragon-canyon rock/mineral family; avoid literal monster remains unless separately approved.
- H20 星痕高地 / Astral → compact meteor/star-mineral family.
- H21 裂隙聖域 / Sanctuary → sacred stone / luminous natural family; avoid building/shrine fragments.

## Water semantic follow-up
Current v1.06.58 water remains accepted. The user-authoritative gravel/pebble clear-water tile is located **two editor palette cells to the right of the currently accepted H07/H12/H17 water**. Exact runtime base remains unverified and is tracked separately in SHO-41. Do not change water IDs as part of Landmark Batch A.

## Acceptance gate per atlas
1. PNG is exactly 64×64 RGBA.
2. Four 32×32 cells each contain one complete prop.
3. No visible cell-boundary clipping.
4. Native 1× readability is acceptable.
5. Prop semantic matches passability/blocking.
6. No unrelated-biome reuse merely to increase coverage.
7. In-game single-cell rendering, scrolling anchor, Route Safety, Loading overlay and Map091 semantics remain unchanged.
8. Only after Windows/RMVX visual PASS may the atlas move to Drive `12_Approved` and enter runtime delivery.
