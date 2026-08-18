# VXRD Landmark Route Safety Audit I — v1.06.55

## Baseline
v1.06.54 received Windows/RMVX Visual + Semantic PASS on H01/H04/H09/H14/H19. It is the formal input baseline.

## Safety model
v1.06.55 adds a two-stage route gate around the accepted Landmark system.

1. **Pre-event gate** runs after v1.06.54 Landmark placement and verifies generated entrance → exit connectivity with the current hard-Landmark block mask.
2. **Post-event gate** runs after Map091 event materialization / semantic relocation and verifies reachability of required semantic destinations.
3. If a hard Landmark breaks a required route, the gate rejects later hard placements first and rebuilds Landmark reservation/block masks.
4. Gate 1 room/corridor topology is never rewritten as a decoration repair.

## Required semantic targets
`EXIT, RETREAT, INFO, TREASURE, RECOVERY, RARE, ELITE, ENCOUNTER` when present.

A target is accepted when its cell or an adjacent walkable interaction cell is reachable from the generated entrance.

## Evidence
- Pure route algorithm static tests: 4/4 PASS.
- Offline multi-seed regression: H01/H04/H09/H14/H19 × 8 deterministic seeds = 40/40 PASS.
- Runtime writes `PMD_VXRD_LandmarkRoute_Audit_LATEST.log` and appends each completed floor to `PMD_VXRD_LandmarkRoute_Audit_HISTORY.log`.

## No-regression invariants
- H01 soft decoration is not route-blocking.
- No automatic B/C/D/E map-table stamping.
- v1.06.44 runtime Landmark IDs remain revoked.
- Map090 stays the runtime map; Map091 remains the H01–H21 Event Template Library and is unchanged in this candidate.
- No Battle AI / damage / attack-speed / Focus-C2 / reward / progression change.
