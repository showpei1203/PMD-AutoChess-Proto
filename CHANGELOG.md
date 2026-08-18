# CHANGELOG

## v1.06.54 — Formal PASS Baseline
- Windows / RPG Maker VX real-machine Visual + Semantic Acceptance PASS on 2026-08-18.
- H01/H04/H09/H14/H19 each show at least one Landmark.
- One Landmark renders as one 32x32 atlas cell rather than the full 64x64 2x2 collage.
- H01 foliage/flowers are passable; H04/H09/H14/H19 hard rock/crystal/ore props are blocking.
- Placement, scrolling and Hunt/floor refresh accepted.
- No giant TileB/TileD fragments or automatic B/C/D/E map stamping returned.
- Static validation PASS 23/23.
- Promoted from Candidate to formal PASS Baseline.
- Next development gate: SHO-22 Landmark collision + route audit.

## v1.06.53 — Real-machine Visual FAIL
- H01/H04/H09/H14 showed no Landmark.
- H19 displayed a full 64x64 atlas as four unrelated objects in one 2x2 block.
- Hard rock/ore visuals were pass-through.
- Never promote v1.06.53.

## Previous Baseline
- v1.06.35 was the formal Gate 1 PASS baseline before v1.06.54 promotion.
