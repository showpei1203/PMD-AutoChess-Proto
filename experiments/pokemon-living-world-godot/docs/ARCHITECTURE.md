# Technical Architecture / Godot 4.7.2
Scope: top-down 2D, offline-first, GDScript; no LLM inference required at runtime.

## Runtime layering
```
WorldClock + BattleScheduler (fixed-step deterministic state)
  → SpatialPerceptionSnapshot (sensor ranges, line-of-sight, danger, terrain)
  → TrainerOrders (strategic intent modifiers)
  → SpeciesProfile × IndividualTraits × LearningMemory
  → UtilityDecision (bounded candidate scoring)
  → ActionExecutor (steering, range, interrupt/cooldown, attack/hit validation)
  → PMDAnimationAdapter (frame sheets, anchors, facing, hurt and idle)
  → UI/IntentOverlay + ReplayTelemetry
```
Rendering/VFX never owns damage, hit time or AI decision; simulation owns those authoritative events.

## Data boundaries
- `species_profiles.json`: species id, categories, size class, locomotion, combat role bias, allowed animation keys, collision footprint (authoring initial values must be verified).
- `instances.json`: individual temperament, trust, training affinity, persistent experiences; deliberately independent of species.
- `asset_manifest.json`: source path, hash, dimensions, frame count, directions, import transform, missing-asset/fallback status.
- `actions.json`: allowed actions, hit windows, ranges, startup/recovery, interrupt rules.
- `replay.json`: deterministic seed, snapshots/checkpoints, commands and resultant action events.

## Control & local AI
- Player orders initially FREE, AGGRESSIVE, KEEP_DISTANCE, DEFEND, PROTECT, each altering scoring weights, not forcing a specific sprite or exact path.
- Perception and utility scores use **bounded neighbouring entities**, not scans of the entire roster for every entity. One immutable start-of-tick snapshot prevents unit iteration-order advantage.
- Suggested prototype rates to measure: 60Hz physical simulation, 5–10Hz decision reevaluation, event-based emergency interrupts; not final promises.
- Strategy selects a goal; low-level executor decides movement and legal actions. Attack authority remains in the simulation even if PMD graphics miss a frame.
- Every prolonged wait has a reason and a guaranteed exit condition to prevent deadlock.

## Animation contract
Reuse reviewed conventions from Gen1recomp PMD sources: Idle, Walk, Hop, Attack, Charge, Shoot, Hurt, KO, Return where present. Never assume each species has every animation. The 151-source filenames have two visual orientations (player/enemy) distinct from true eight-direction action sheets: validate actual frame layouts before assigning directions.

## Initial behavioural roles (hypotheses to test)
- #025 Pikachu: fast reposition / evade / ranged electric pressure.
- #094 Gengar: bait attacks, preserve distance and punish recovery.
- #143 Snorlax: territorial hold, slow approach, block/counter.
No 'randomly ignore valid player orders' behaviour. Individual temperaments influence *how* an instruction is fulfilled.

## AI and save safety
- Deterministic utility scoring + seeded stochastic tie-breaking; no network API required.
- Debug decision overlay exposes perception, options, weights, reasons for target/action selection.
- Pause/restart/safe resume and format versioning are required before long-term learning.
- Trust/experience only alters bounded behaviour biases; prevent permanent negative feedback spirals.

## Implementation layout
```
project.godot
scenes/main.tscn
scripts/main.gd
data/             # generated manifests in later gate
scripts/ai/       # decision, sensing, orders
scripts/entities/ # species and body/animation
scripts/combat/   # authoritative actions/collisions
tools/            # asset validation and conversion
tests/            # seed-based fixtures
docs/             # spec, logs, gates
```
