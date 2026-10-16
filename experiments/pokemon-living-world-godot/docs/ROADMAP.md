# Roadmap / Sprint Gates — Pokémon Living World
Decision date: 2026-10-17 (Asia/Taipei).
**Estimates are proposals, NOT automatic/background execution promises.**

## Definition of Done for first vertical slice
One 2D environment contains three visibly different species behaviours, autonomous movement, continuous 1v1 combat, at least three trainer orders, readable action intent, replayable deterministically by seed, and tested native Windows build. Android follows as a separate gate. Whole 151 asset coverage is audited independently of behaviour readiness.

## Phases and target weeks
| Gate | Candidate window | Work | Exit evidence |
| --- | --- | --- | --- |
| G0 Source Seal | W0 10/17–10/18 | Locate exact 151 asset ZIP, record hashes and rights, freeze scope, GitHub/Drive authority | Full manifest and gap report; **not yet complete** |
| G1 Bootstrap/Importer | W1 10/19–10/25 | Godot base, asset converter, atlas slicing, frame/anchor schema | 151 IDs indexed; missing sequences enumerated; 3 selected species preview; no silently filled gaps |
| G2 Life Loop | W2–3 10/26–11/08 | 2D collisions, body/foot anchors, 8-direction animation checks, ecology states and locomotion | Three species visibly different; no impossible sprite frame; deterministic idle/home/roam |
| G3 Autonomous Duel | W4–5 11/09–11/22 | Threat perception, Utility AI, action executor, contact/projectile rules, trainer order priorities | Reproducible 1v1 fights, 3 commands effect outcomes, no deadlock, intervention telemetry |
| G4 Species Scale | W6–7 11/23–12/06 | Profiles for #001–151, fallback family templates, performance/regression suite, debug overlays | 151 species loadable with honest capability labels; 15 representative combat fixtures stable |
| G5 THOR Candidate | W8 12/07–12/13 | Windows packaged build + Android APK on AYN THOR, input/resolution/profiling | Explicit human device PASS / FAIL, logs, complete candidate ZIP and rollback; do not infer from Windows PASS |

These week ranges are sequencing targets only; unfinished gates block promotion regardless of calendar date.

## First sprint backlog (ordered)
- PLW-001: Establish exact asset provenance and baseline SHA (Gen1recomp PMD bundle, action data, existing Rich Ambient).
- PLW-002: Audit 151 species x animation presence/quality and source rights; distinguish inventory records from on-device bytes.
- PLW-003: Create deterministic Python asset-manifest / importer specification from existing filename patterns, not regenerate graphics.
- PLW-004: Implement Godot species registry `species_id + motion_family + physical_size + compatible_actions`.
- PLW-005: Render #025, #094, #143 in 8 directions; transparent key/anchor/crop/hurt checks.
- PLW-006: Implement ecological `IDLE → ROAM → OBSERVE → HOME → REST` loop with interrupt safety.
- PLW-007: Implement deterministic battle clock, sensory snapshot and local navigation.
- PLW-008: Implement utility-based `approach/evade/attack/defend/reposition` behaviour.
- PLW-009: Implement `FREE/AGGRESSIVE/KEEP_DISTANCE/DEFEND/PROTECT` orders as *intent modifiers*, not direct puppeteering.
- PLW-010: Replay fixtures, logs, regression test and Windows / AYN THOR release gates.

## RACI / advancement protocol
- Canonical design: GitHub docs + Drive mirrored planning record.
- Code+diff: GitHub. Large source art and candidate ZIP: Drive (restricted/private); no public Git asset payload.
- Every merged/tested candidate requires `CHANGELOG`, deterministic scenario seed, environment, expected-vs-observed results, artifacts/logs, SHA and explicit PASS/FAIL.
- Source projects' accepted baselines may only be consumed as references, not modified by these experiments.
- Open problems flagged P0 must be resolved before feature promotion; optional QoL stays P1/P2.
