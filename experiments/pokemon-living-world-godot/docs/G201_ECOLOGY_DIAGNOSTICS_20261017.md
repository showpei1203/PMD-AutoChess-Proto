# G2.0.1 v0.3.8 — Surface autonomy / visibility diagnostic (2026-10-17)

## User-reported failure (not a PASS)
- Three sprites appeared largely idle/immobile in Surface's `scenes/ecology_lab.tscn`.
- `N` changing the RNG seed produced no visible effect.
- Pressing `D` did not reveal the promised range/target.
- This means G2.0 v0.3.7 failed its behaviour + controls acceptance despite the previous 83/83 offline source/synthetic tests.

## Verified source defect
- `show_debug` was `true` by default and `D` **toggles** it: pressing D once actually hid the circles and targets. Previous overlays were also low-opacity.
- All 3 agents were initially forced into IDLE for random durations, which obscured early species-specific behaviour; random differences only appeared later and were not displayed clearly.
- An actual reason for long-term immobility **cannot be confirmed without Surface tick/position evidence**, so do not claim the Godot simulation root cause is resolved yet.

## Candidate changes (isolated G2 scene only)
- Start with visible distinct states: #025 Pikachu directly ROAM, #094 Gengar OBSERVE then ROAM, #143 Snorlax REST. Natural weighted transitions still operate afterward.
- Start `show_debug=false`, so **first D press enables** bright home-range circles, centre-to-target path, and gold target markers. UI explicitly says `Debug ON`/`OFF`.
- Show always-visible `Seed`, `tick`, `RUNNING/PAUSED`, focus and accumulated distance. When D is enabled, show state/position/target/distance/reason for all 3.
- `N` changes seed by a distinct prime step and Pikachu receives a seeded target at reset; `R` repeats original target with identical seed.
- `M` immediately gives currently selected species a NEW ROAM target and turns debugging ON: a **manual diagnostic stimulus**, not evidence of natural AI.
- Movement is accounted in cumulative distances, and G2 state transitions are printed to Godot Output tagged `[PLW-G2]`.
- All G1/G1.1/G1.2 scenes and source asset caches remain untouched. G2.1 obstacles/relationships and battles have **not** been implemented.

## Reproducible Surface F6 acceptance, NOT yet executed
1. GitHub Desktop update `planning/pokemon-living-world-godot`, keeping local `data/raw/pmdcollab` intact; re-open `scenes/ecology_lab.tscn`, F6.
2. Within 1–3 seconds, `tick` **must** increase; `distance` for Pikachu should become non-zero, Gengar should eventually move, Snorlax should REST more.
3. Press `D` once. Status **must** read `Debug ON`; bright cyan range circles, yellow target lines/dots and per-species coordinate details must appear.
4. Focus Pikachu `1`, press `M`: `ROAM`, new target and increasing cumulative distance must be visible. If tick increases but distance stays zero after `M`, mark **MOTION FAIL** and capture Godot Output.
5. Press `R`: initial Pikachu target repeats with same Seed; `N`: Seed changes and newly seeded target should differ. Compare numeric targets rather than just appearance.
6. `Space` pauses tick/distance; resume and verify. Watch at least 30s. Record any parser/runtime errors/warnings and unexpected anchor jumps.
7. Preserve `[PLW-G2]` log and screenshot of HUD; no G2 acceptance claim until results observed.

## Deliverables
- Corrected `scripts/lab/ecology_lab.gd` in isolated branch.
- Additional tests `tests/test_g201_observable_ecology.py`, plus updated seed assertion in existing G2 tests.
- Full ZIP, SHA256 manifest, Python offline test log and Windows quick test BAT; no proprietary PMD PNGs.
