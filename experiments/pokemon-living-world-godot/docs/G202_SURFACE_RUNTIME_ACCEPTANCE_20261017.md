# G2.0.2 v0.3.9 | Surface runtime evidence acceptance | 2026-10-17

**Checkpoint:** `PLW_G202_SURFACE_DIAGNOSTICS_PASS_G2_PARTIAL_20261017`  
**Evidence:** user Surface game screenshot and attached `PLW_G2_DIAGNOSTICS_TO_SHARE.zip`, containing `PLW_G2_RUNTIME_LAST.log`.  
**User log ZIP SHA-256:** `f63900f4a76bdef98724818044aa355e4508c6b6ed654b47ae00a6a6b7ae9ba6`.  
**Privacy/asset handling:** summary and SHA only in public GitHub; no local device log, screenshots or copyrighted PNG republished.

## Verified observations
- Godot runtime `4.7.2-stable (official)`; `LOGGER_READY build=G2.0.2-v0.3.9 scene=res://scenes/ecology_lab.tscn`.
- Log: 171 lines, approx 60 sec runtime, 58 `HEARTBEAT` entries, 103 `AGENT` changes, 6 `KEYBOARD` entries, one `PHYSICS_FIRST_CALL` and `SESSION_END`. **No explicit ERROR event inside this logger** (engine debugger separately not asserted clean).
- First heartbeat: `tick=4 ui=13 physics=28 paused=false tree_paused=false root_physics=true`.
- Late heartbeat: `tick=333 ui=3434 physics=3452 paused=false tree_paused=false root_physics=true`. Tick reliably advances, independent render and physics callbacks work.
- `M` keycode 77, `D` keycode 68, `N` keycode 78 all captured while active scene is `EcologyLab`; N causes `seed=20261017` to become `seed=20365746` and a new target. No `BUTTON` entry in attached log, so **mouse button callbacks unverified**.
- `#025` Pikachu: logged `ROAM`, `OBSERVE`, `IDLE`, cumulative moved ~673 px in last new-seed heartbeat; user screenshot confirms ~673 px. Demonstrates autonomous navigation and visible target/territory debug.
- `#094` Gengar: logged `ROAM`, `OBSERVE`, `IDLE`, `REST`, cumulative moved ~367 px. Demonstrates independent locomotion and distinct transitions.
- `#143` Snorlax: `REST`, `IDLE`, `OBSERVE` only, **moved=0 px across this entire ~60-second run**; no observed `ROAM`. Might be probabilistic (current `roam=0.13` with substantial rest); insufficient evidence for a mechanical fault, but diversity / liveliness acceptance remains open.
- Godot screenshot: cyan radius circles, target markers, status counters, `Debug ON`, `RUNNING`, correct G2 active UI.

## Acceptance status
- **G2.0.2 logger, input capture, time step, target and debug visualization: SURFACE PASS.**
- **G2.0 ecology pilot: PARTIAL PASS**, observed movement and state transitions for 2/3 agents.
- **G2 full ecology gate NOT ACCEPTED**: Snorlax needs observable roaming in longer or forced simulation; assess foot anchoring across movement, terrain/obstacle/sensing/long-term behavior in future phases.
- G1 / G1.1 / G1.2 baselines remain untouched; no new code, no new tests, no new ZIP necessary for this *evidence-only* checkpoint. v0.3.9 existing full ZIP remains versioned reference.
- Prior `G2 LOG NOT FOUND` was explained by opening `calibration_lab.tscn` rather than running actual `ecology_lab.tscn`. Actual G2 run now verified.

## Next gate proposal
- Add distinct visible energy and personality trajectories: low-probability but bounded Snorlax roam (without making every species hyperactive), and action/facing change corresponding to velocity.
- Record 60-120 second seeded deterministic behavior checks for each species, including forced M test on all 3; on-screen target and per-agent movement counters must agree with LOG.
- When implementation changes, commit code + tests + logs + hashes + complete ZIP and **update GitHub/Drive CURRENT_HANDOFF and HANDOFF_HISTORY**. No active background work.
