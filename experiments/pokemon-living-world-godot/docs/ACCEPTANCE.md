# Acceptance, telemetry and rollback
No milestone is formal PASS without recorded evidence. Unexecuted tests are PENDING, not PASS.

## Gates
G0: ZIP + SHA + source inventory; 151 IDs; hard-fail on missing/corrupt source image; provenance.
G1: Godot project boots on Windows; import script deterministic; 151 registry entries; preview #025/#094/#143 with frame/anchor audit.
G2: Ecology supports multiple distinct actions; all active entities remain bounded and able to return to home; stop/start transitions do not teleport.
G3: Two AI opponents can finish encounter without player input; five trainer orders change *strategic preference* measurably; action executor enforces cooldown & range; visual hit cannot create duplicate simulation damage.
G4: 151 profiles load with explicit fallback flags; 15 mixed-size/locomotion scenario fixtures; no unbounded scan per entity; deterministic seed replay stable.
G5: Windows native build + Android/AYN THOR separate results for performance, controls, resume and graphics; report measured numbers only.

## Required fixtures
- Pikachu vs Gengar (fast reposition vs feint/pressure)
- Snorlax vs Pikachu (hold vs kiting; no permanent futile pursuit)
- Pikachu vs Pikachu mirrored-seed (order-independent snapshot decisions)
- Large body vs small body near obstacles (feet/body anchor and clipping)
- Contact vs projectile, dodge at boundary, hit during state transition, KO and restart
- Two identical species with different individual traits + differing trainer orders
- Idle-to-combat-to-Idle, transition at exact hurt frame and KO terminal
- Multi-unit stress sampled after prototype, not assumed

## Candidate evidence
Bundle source commit/ref + complete candidate ZIP + hash manifest + run instructions + test seed + log + screenshot/video where visual claim applies + Windows version/Godot version + observed PASS/FAIL + rollback SHA. Android THOR test records Android model, OS and actual APK SHA.

## Performance targets (proposed, subject to profiler)
- Baseline reference: fixed physics 60 ticks/sec; logic 5–10 evaluations/sec per active entity.
- Initial local test at 960×540; target sustained 60 FPS with **6 agents** on reference desktop; measure rather than promise.
- No replay divergence for identical seed+commands across identical engine/build; save/load reload reproduces core state.
- No unexplained permanent idle; every action owns timeout, interrupt criteria and exit condition.
- Separate animation FPS from simulation tick; sprite visual pose cannot mutate authoritative damage.

## Status log
2026-10-17: Plan authored. Existing sources inventoried from path list. Godot runtime execution **PENDING**. 151 binary verification **PENDING**. First phase PENDING. Old-project baselines untouched.
