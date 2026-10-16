# Pokémon Living World — Godot Planning & Bootstrap

**Decision:** Godot 4.7.2 Standard (GDScript), 2D top-down, offline-first Windows prototype; Android / AYN THOR acceptance later.

**Status (2026-10-17):** PLANNING + SOURCE PREFLIGHT. Not a playable Pokémon game. No 151 asset import, autonomous battle, or runtime benchmark has been verified in this branch.

> Vision: Pokémon possess their own ecology, dispositions, senses and decisions. The player acts as trainer and influences tactical intent rather than pressing an attack button every frame.

## Where this work lives
- GitHub **isolated branch** in `showpei1203/PMD-AutoChess-Proto`: `planning/pokemon-living-world-godot` under `experiments/pokemon-living-world-godot/`.
- Source PMD records remain unchanged in `Gen1recomp` Google Drive and existing PMD project.
- New project Google Drive folder: https://drive.google.com/drive/folders/1RbnQzZ3h94B0NBRiFlcK1DsuSKkesNLa
- Dedicated standalone GitHub repository is a **future migration task**: available connector cannot create repositories. Do not merge experimental Godot code into current PMD-AutoChess-Proto main as though it were the existing engine.

## First prototype scope
- 151-species asset inventory **before import**, then deterministic art importer.
- Validate 3 representative species: #025 Pikachu (agile/kiter), #094 Gengar (opportunist), #143 Snorlax (defender).
- World simulation: locomotion/idle/behaviour + 1v1 self-directed combat + trainer orders.
- Deterministic reproducibility, debug overlays, test logs and acceptance evidence.

## Docs
- `docs/ROADMAP.md`: proposed sprints, deliverables, strict gates.
- `docs/ARCHITECTURE.md`: agent hierarchy, AI utility policies, rendering and memory layers.
- `docs/ASSETS_AND_RIGHTS.md`: source provenance, verified list counts, missing access checks.
- `docs/ACCEPTANCE.md`: test plan and non-regression acceptance.
- Godot files under this directory are **bootstrap only**; they contain no extracted Pokémon assets or copyrighted content.

## Quick start (when using Godot 4.7.2)
Import `project.godot` in Godot Project Manager and run `scenes/main.tscn`. This bootstrap displays a development splash, not combat or art. Local editor/runtime run verification has not yet been completed.

## Do not bypass these gates
1. Existing Gen1 Recomp / PMD Formal Authorities remain byte-exact.
2. Never publish raw copyrighted Pokémon / PMD graphics into this public repository.
3. No claimed 151-complete import without per-species / per-animation audit.
4. No advancement from prototype to 151 AI without behaviour tests; never copy 151 bespoke AI trees.
5. Every candidate ships full ZIP, test script, logs, and a rollback/checkpoint record after development actually begins.
