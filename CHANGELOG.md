# CHANGELOG

## v1.06.55 — Formal PASS Baseline (Phase-I Route Scope)
- SHO-22 Landmark II: Collision / Route Audit I.
- Adds a two-stage route-safety gate around the accepted v1.06.54 Landmark system.
- Pre-event gate verifies entrance → exit connectivity with current hard Landmark blockers.
- Post-event gate verifies required Map091 semantic destinations after event materialization / relocation.
- Unsafe hard Landmark placement is rejected; sealed Gate 1 room/corridor topology is never rewritten.
- Runtime writes LATEST + HISTORY route-audit logs.
- Static validation PASS 31/31.
- Offline deterministic regression: H01/H04/H09/H14/H19 × 8 seeds = 40/40 PASS.
- Windows/RMVX real-machine Phase-I acceptance PASS on 2026-08-18: every sampled run `RESULT=PASS`, `EXIT_REACHABLE=1`, `BAD=` empty.
- Scope note: SHO-22 remains In Progress for broader Hunt / multi-seed stress before Landmark coverage expands.

## v1.06.54 — Formal PASS Baseline
- Windows / RPG Maker VX real-machine Visual + Semantic Acceptance PASS on 2026-08-18.
- H01/H04/H09/H14/H19 Landmark presence, single 32x32 prop rendering, hard/soft collision, scrolling and refresh accepted.
- No giant TileB/TileD fragments or automatic B/C/D/E map stamping returned.
- Static validation PASS 23/23.

## v1.06.53 — Real-machine Visual FAIL
- H01/H04/H09/H14 showed no Landmark.
- H19 displayed a full 64x64 atlas as four unrelated objects in one 2x2 block.
- Hard rock/ore visuals were pass-through.
- Never promote v1.06.53.
