# G3.2 v0.5.2 | Geometry-aware corner escape | 2026-10-17

## Ground truth and motivation
The user's last G3.1 real Surface Godot 4.7.2 LOG passed native 32/32 samples, 
actual RETREAT/STRAFE/ZONE and guarded mitigation. KEEP_DISTANCE nevertheless lost all
8 fixed-start native engine scenarios. Geometry-agnostic G3.1 retreat hits the arena walls.
G3.1 baseline remains sealed. The user asked to continue development.

## Isolated implementation
- New scene `scenes/g32_combat_lab.tscn`, inherits the unchanged G3.1 visual layer
  and injects `scripts/battle/g32_combat_core.gd`.
- New `ESCAPE` intent is introduced only for player unit 0 under KEEP_DISTANCE when
  G3.1 would RETREAT and a **9-tick forward projection** detects future wall clipping
  or under 45 pixels of wall clearance.
- Compare eight candidate movement headings using projected accessible endpoint,
  remaining wall clearance, approximate pursuing enemy displacement, future gap,
  blocked-motion penalty, and small continuity bonus. Choose deterministic maximum,
  maintain heading for at most 18 ticks, replan earlier on blocked motion.
- Record `ESCAPE_PLAN`, `escape_steps`, `escape_plans`, `escape_replans` and
  `wall_contacts`; escape/retreat/strafe visual Walk uses actual MOVE playback speed.
- Fallback remains G3.1 for FREE, AGGRESSIVE, DEFENSIVE and for unaffected
  KEEP_DISTANCE decisions. **Fixed combat clock and attack snapshot authority unchanged**.
- User-visible G3.2 diagnostics: `PLW_G32_RUNTIME_LAST.log`; launcher packages
  `reports/PLW_G32_DIRECT_DIAGNOSTICS_TO_SHARE.zip` even on Godot parser/boot error.

## Offline evidence
- Full Python regression `189/189 PASS` (176 previous + 13 additional tests).
- Corner-only independent geometry reference probes: four corners at (92/868,152/366),
  each moves approximately 86.18px over 14 steps with directional lock,
  without stepping outside the arena. These are **synthetic points, not actual Godot data**.
- The 18-tick directional lock avoids immediate 7-tick reverse/oscillation in those probes.
- Original **G3.1 v0.5.1 ZIP** SHA-256 `4bada00cb47273e141dada74379e14f60224a19cdf3571d32892f29291c0a7e8`;
  all 31 previous scene/script source files in the new working tree are byte-exact.
- Godot 4.7.2 native G3.2 runtime **PENDING** because the build environment lacks Godot.

## Real-engine Surface gate / next test
- Run `RUN_G32_DIRECT_SCENE_WINDOWS.bat` after GitHub Fetch/Pull on
  `planning/pokemon-living-world-godot`. No F5/F6 required.
- The launcher first executes `tests/g32_godot_engine_gate.gd` in Godot --headless,
  checking **8 seeds × 4 trainer postures × two identical replays + four explicit
  corner probes × two replays**, and verifies bounds, terminal result, and that
  the new ESCAPE policy was exercised. Expect `G32_GATE RESULT samples=36 failures=0`.
- If the native gate passes, gameplay opens; press `3` then `R` to run KEEP_DISTANCE
  under the same seed. Observe `ESCAPE` decision/escape count at the world boundary,
  then `4` then `R` to contrast defensive policy. Close game and upload
  `reports/PLW_G32_DIRECT_DIAGNOSTICS_TO_SHARE.zip` and a screenshot if possible.
- **Design limit**: 8 headings and heuristic prediction are not obstacle pathfinding,
  do not guarantee survival or improve 1v1 balance; 151 species, canonical moves,
  collision and team protect-ally remain outside this slice.

## Rollback and rights
Reopen accepted G3.1 scene `scenes/g31_combat_lab.tscn` or use previous v0.5.1.
No original PMDCollab Pokémon images or private user runtime logs are packaged
or pushed to GitHub. Surface local files under `data/raw/pmdcollab` are left intact.
