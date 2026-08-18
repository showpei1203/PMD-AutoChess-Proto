# PMD AutoChess v1.06.53
# VX / RGSS2 Tile Drawing Research & Landmark PNG Authority

## 1. Research result

### RPG Maker VX official material specification
- Every map tile is 32×32.
- Tileset A is the lower-layer family; A1/A2/A3/A4 are largely autotile based.
- A2 is general terrain authority.
- A3 is mainly building exterior.
- A4 is mainly wall/dungeon wall.
- A5 is a fixed 8×16 tile sheet.
- TileB–TileE are upper-layer sheets, each 16×16 cells / 512×512 pixels.
- TileB top-left cell is required to be blank to represent no upper tile.

### VX base-script upper tile drawing logic
The project’s exported VX base script proves Sprite_Character uses:
- sheet = tile_id / 256
- 0=B, 1=C, 2=D, 3=E
- sx = (tile_id / 128 % 2 * 8 + tile_id % 8) * 32
- sy = (tile_id % 256 / 8 % 16) * 32

Therefore a 16-column PNG atlas index cannot be copied directly into an RMVX runtime upper-tile ID. The runtime uses two 8-column banks.

Atlas→runtime local conversion:
- x = atlas_index % 16
- y = atlas_index / 16
- local_id = y*8 + (x % 8) + (x >= 8 ? 128 : 0)
- sheet base: B=0, C=256, D=512, E=768

This confirms the v1.06.44 failure mode and confirms the v1.06.45 coordinate authority.

## 2. Why correct Tile ID is still not enough

Correct ID mapping solves only coordinate addressing. It does not solve semantic footprint. TileB/TileD contain many cells that are pieces of a larger object. Randomly choosing a visually plausible cell can still produce half a structure or a map fragment.

Therefore v1.06.53 does NOT resume B/C/D/E map-table stamping.

## 3. Forest Symphony precedent

FS_RandomDungeon separates logical collision data from visual rendering. Its generated map can build a collision Table while a dedicated Bitmap renderer draws image assets and VX autotile quarter pieces. That architecture proves we do not need to force all generated visuals through native upper-layer tile IDs.

The current PMD approach adopts the same separation principle, not a byte-for-byte copy of FS.

## 4. v1.06.53 architecture

Native Tilemap stays responsible for:
- A1 water/environment
- A2 floor
- A4 wall/cliff
- A5 deliberate fixed floor material

Dedicated PNG Sprite layer is responsible for Landmark visuals:
- Graphics/VXRD_Landmarks/forest_green_a.png
- Graphics/VXRD_Landmarks/forest_flower_a.png
- Graphics/VXRD_Landmarks/dry_rock_a.png
- Graphics/VXRD_Landmarks/cave_crystal_a.png
- Graphics/VXRD_Landmarks/mine_ore_a.png
- Graphics/VXRD_Landmarks/volcanic_ore_a.png

The PNGs are curated 2×2 / 64×64 composites cropped from the user-approved TileB/TileD source sheets. Runtime rendering uses Cache + Sprite and never converts those source atlas cells into B/C/D/E map tile IDs.

## 5. First acceptance scope

Only five Hunts are enabled in this foundation pass:
- H01 Forest
- H04 Dry Rock
- H09 Cave Crystal
- H14 Mine Ore
- H19 Volcanic Ore

Landmark count: max 2 per floor profile.
Placement: normal-room corners only, central route safety, entrance/exit/water/fixed-position avoidance, footprint reservation before Map091 runtime event relocation.

Collision: intentionally deferred until visual acceptance.

## 6. Safety invariant

- Native upper tile ID landmark stamping = 0
- B/C/D/E random map scatter = 0
- v1.06.45 final purge remains active
- Battle / AI / Damage / Reward / Progression changes = 0

## 7. Acceptance rule

If these five Hunts still show a wrong large object, the remaining cause should no longer be atlas-index↔runtime-ID confusion because landmark rendering bypasses that path completely. Diagnose the PNG asset/placement or another visual source directly.
