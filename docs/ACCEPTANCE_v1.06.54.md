# PMD AutoChess Proto v1.06.54 Windows / RPG Maker VX Acceptance

Date: 2026-08-18
Result: **PASS**

## Accepted version
**v1.06.54 — VXRD Landmark Single-Prop Semantic / Presence / Collision Fix I**

## Real-machine scope
H01 / H04 / H09 / H14 / H19.

User confirmed on Windows / RPG Maker VX:
- every acceptance Hunt shows at least one Landmark;
- each Landmark renders as one 32×32 prop rather than the full 64×64 2×2 atlas;
- placement is visually acceptable and not tightly piled;
- H01 foliage / flower decoration is passable;
- H04 dry rock, H09 cave crystal/rock, H14 mine ore, H19 volcanic rock/ore are impassable;
- scrolling and Hunt/floor refresh are normal;
- no giant TileB/TileD fragment returned;
- no automatic B/C/D/E map stamping returned;
- no observed Gate 1 structural/battle regression.

Static validation: PASS 23/23.
Source-level acceptance precheck also verified player walking collision chaining, Landmark reservation before Map091 semantic relocation, stale sprite disposal/refresh, and continued B/C/D/E stamping prohibition.

## Promotion
v1.06.54 is approved as the new formal PASS Baseline. GitHub `main` may advance from v1.06.35 to this source state. Google Drive Binary Authority must retain the accepted v1.06.54 package as the current formal Baseline.

## Next development gate
SHO-22 — Landmark II: Collision / Route Audit.

The next candidate must prove entrance→exit and required-event reachability with hard Landmark blockers without changing Gate 1 topology. If a hard Landmark would break a required route, reject or relocate the Landmark instead of modifying room topology.

Automatic B/C/D/E tile scatter/stamping remains prohibited. v1.06.44 Landmark runtime IDs remain revoked.
