# Pokémon Living World | G3.0 Autonomous 1v1 Utility Combat v0.5.0

**Checkpoint:** `PLW_G30_UTILITY_1V1_CANDIDATE_v050_20261017`

**Status:** Python reference/offline **163/163 PASS**. **REAL GODOT 4.7.2 HEADLESS + Surface visual: PENDING.** Not a formal G3 completion.

## Why this phase

The original Roadmap's next work item is **PLW-006 G3 autonomous combat**. G2.3 was user-accepted for now; no more cadence changes requested. The original G2 roadmap still lists terrain collisions and fully validated G2 lifecycle, so G3.0 runs in a **separate lab** and does not imply G2 complete.

## Owner boundaries

- **Battle authority:** `scripts/battle/g30_combat_core.gd`: fixed `DT=0.1`, deterministic seed/reset, Utility decision, movement, scheduled hit tick (not sprite frame), damage, guard, evasions, KO/timeout. A 60-second maximum tick horizon prevents endless play.
- **Perception:** current 1v1 local enemy distance, telegraph, cooldown and HP. No claims about obstacles or multi-unit perception.
- **Presentation:** `scripts/battle/g30_combat_lab.gd`: PMD direction rows, native shadow alignment and movement/attack visuals. Render sprites do **not** own hit, damage or KO timing.
- **Diagnostics:** `scripts/battle/g30_combat_diagnostics.gd` saves all battle `DECISION`, `WHY`, `WINDUP`, `HIT`, `MISS`, `RESULT` and per-second `HEARTBEAT`, `UNIT` lines to `reports/PLW_G30_RUNTIME_LAST.log` (when project folder writable), otherwise `user://` as printed.
- **User test launcher:** `RUN_G30_DIRECT_SCENE_WINDOWS.bat` invokes `tools/g30_direct_launch.py`.

## Current toy battle tuning (not canonical Pokémon rules)

Two locally imported PMDCollab sprites #025 Pikachu and #094 Gengar, with prototype HP, speed, attack, hit range and cooldown. No type advantage, abilities, move learnsets, PP, critical damage, Pokémon canonical combat stats, items, obstacles or physical collision resolution. All results are for this 1v1 engine scaffold only.

Player's supported trainer posture commands (press 1/2/3/4):
1. `FREE`: autonomous base utility.
2. `AGGRESSIVE`: prioritize strikes, two ticks shorter attack cooldown, avoids guarding.
3. `KEEP_DISTANCE`: react to opponent windup with extra evasive priority.
4. `DEFENSIVE`: prefer guard when opponent telegraphs, mitigate damage, still pursue a conclusion.

Key **5 PROTECT_ALLY** is explicitly **UNSUPPORTED** in 1v1 and creates `ORDER_REJECTED`; needs at least 2v2 with actual teammate before activation. Press Space to pause, R to replay same seed/order, N for a different seed, D for diagnostic display.

## Authority + replay conditions

1. Godot SceneTree `--headless --script res://tests/g30_godot_engine_gate.gd` runs **12 actual GDScript battles** (3 seeds × 4 orders) **twice**; checks terminal result, hit count, and same-seed same result/tick/HP/digest. This gate is automatically executed before graphical launch.
2. Only after the native Godot gate prints `G30_GATE RESULT samples=12 failures=0` may launcher open `res://scenes/g30_combat_lab.tscn`. If compiler or replay gate fails, ZIP is still produced containing `PLW_G30_GODOT_ENGINE_GATE_LAST.log` and the failure report, no false animation pass.
3. Closing game after 20-70 seconds produces `reports/PLW_G30_DIRECT_DIAGNOSTICS_TO_SHARE.zip`, including headless parser/replay log, boot log, console log, and runtime battle trace. This evidence ZIP deliberately excludes raw Pokémon art.
4. Same seed + order should produce the same combat tick/HP/hit/digest. Different seeds perturb spawn Y coordinates and should change digest. Actual reproducibility must be measured in **Godot** rather than assumed from Python.
5. Fully automated **win/loss/draw on timeout**, with visible result UI and no user input required. Combat decision events explain why `APPROACH`, `ATTACK`, `GUARD`, `DODGE` or `CIRCLE` were selected.

## Windows Surface acceptance

- Close current Godot/editor game window; GitHub Desktop isolated planning branch Fetch/Pull (or use complete ZIP without overwriting local sprite data).
- Double-click `RUN_G30_DIRECT_SCENE_WINDOWS.bat` from the project root. Same cached Godot 4.7.2 exe as G22/G23; select if asked.
- Launcher first prints `G3.0 GODOT HEADLESS CORE GATE`. **If fails, upload ZIP without doing anything else.** If passes, the graphical battle scene opens directly.
- Do **nothing** and watch Pikachu/Gengar approach, attack telegraphs, HP bars and result within at most 60 simulated seconds. Let battle finish and then try R, N and orders 1/2/3/4 if desired. Close only the **game** window and wait for `DIAGNOSTIC ZIP READY`.
- Upload `reports/PLW_G30_DIRECT_DIAGNOSTICS_TO_SHARE.zip` and screenshot showing fight/result. If assets fail, check existing private `data/raw/pmdcollab/0025` and `0094` remain untouched. Do not re-download 151 sprites.

## QA boundaries

Offline reference tests are **not** a GDScript runtime substitute. Headless audit script is shipped but not executed in the assistant container, where Godot is unavailable. G1–G2.3 accepted source stays byte-exact. `project.godot` main F5 scene unchanged. No PMD original artwork and no user Surface logs in public repository or release ZIP.

**Next gate after Surface result:** first reliable end-to-end battle with source-side seeded decisions and native Godot replay, then expand typed move/collision/perception and trainer's fifth real `PROTECT_ALLY` only in a genuine multi-unit context.
