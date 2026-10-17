# PLW G2.3 v0.4.2 | Real Surface Runtime Evidence | 2026-10-17

Checkpoint: `PLW_G23_SURFACE_RUNTIME_PASS_VISUAL_FEEL_PENDING_20261017`
Evidence: user-uploaded `PLW_G23_DIRECT_DIAGNOSTICS_TO_SHARE.zip`
Evidence SHA-256: `8b22e798ba4c2a63551d124c9ca320b2be801aca5bebe7edb5e5cc634b4c835d`.
**Do not publish raw Surface LOG or copyrighted Pokémon images to public GitHub.**

## Integrity and startup
ZIP CRC PASS, five files (launch report, Godot boot, console, runtime log, HOW_TO_SHARE).
- Direct launcher target: `res://scenes/ecology_ambient_lab.tscn`
- `godot_exit_code=0`, real `LOGGER_READY build=G2.3-v0.4.2 scene=res://scenes/ecology_ambient_lab.tscn`
- ~60 seconds, runtime log 173 lines: 59 heartbeat, 110 agent reports, session start, first physics, session end.
- Last heartbeat `tick=583 ui=3484 physics=3502`; `SESSION_END` at 60032ms, visual=3528 physics=3546.
- No ERROR/WARNING signatures in Godot boot or console. No keyboard/button activity measured.

## Actual observed actions
Console contains 64 `[PLW-G23] PRESENTATION` events.
- Pikachu #025: 21 MOVE Walk, 12 STANCE Walk (0.26x), 1 MICRO_IDLE Idle; last distance ~1134.65px and 11 roam episodes; logged direction rows 0/1/3/4/6/7.
- Gengar #094: 10 MOVE Walk, 8 STANCE Walk (0.17x), 1 MICRO_IDLE Idle, 1 MICRO_FLOAT Float; last distance ~423.68px, 5 roam episodes; rows 0/1/2/3/5/7.
- Snorlax #143: 6 MOVE Walk, 4 STANCE Walk (0.09x), zero micro-actions in this ~60s sample; last distance ~160px, 3 roam episodes; rows 0/2/3/7.
- No ambient fallbacks observed in console.

## Acceptance classification
- **Godot startup + actual G2.3 timer/logging and mode transitions: Surface RUN PASS.**
- **Species-based slow stance speeds and intermittent event dispatch: OBSERVED for #025 and #094.**
- **#143 micro movement NOT OBSERVED**, consistent with long intervals / frequent movement resets but not yet proven root cause. 60-second run is insufficient to approve #143 occasional expressiveness.
- Visual quality of slow-Walk stances, native facing/feet alignment and 151-species generalization remain **PENDING USER VISUAL FEEDBACK**. Do not equate log events with visually natural appearance.
- G2.3 functional implementation unchanged in this evidence-only checkpoint. Prior offline Python 146/146 PASS is historical (not rerun). G2.3 v0.4.2 current complete ZIP unchanged.

## Next development check
Before changing behavior, gather user impressions of Pikachu/Gengar/Snorlax rhythm. Candidate focus: #143 pose timer reset on MOVE, 18–28-second dwell and weighted NONE/Nod; instrument reset reason and consider natural subtle gestures, preserving movement > ambient and G2.2 8-direction/floor alignment.

See GitHub CURRENT_HANDOFF_PLW.md, HANDOFF_HISTORY_PLW.md, Issue #15 and Drive master roadmap.
