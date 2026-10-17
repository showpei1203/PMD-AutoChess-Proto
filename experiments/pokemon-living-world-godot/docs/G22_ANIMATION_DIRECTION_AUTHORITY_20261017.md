# G2.2 | Direction-aware PMD animation director v0.4.1 | 2026-10-17

**Status:** candidate, **122/122 Python offline PASS**, Godot 4.7.2 Surface F6 **PENDING**.  G2.1 movement accepted from user-provided live log, appearance shortcomings remain.

## User request and true baseline
- In actual G21, native PMD `Idle` looping on Snorlax looks like endless bouncing and breaks the lazy personality; Pikachu should normally hold the ordinary Walk stance and occasionally play a brief Idle hop.
- Every moving Pokémon currently faces forward (raw row 0), so player cannot see heading. Must match native PMD row to actual movement vector and frame's ground point.
- User-provided G21 runtime ZIP SHA256 = `a450cf80889287a00cdc8f275507dfc0efa83479f9fc9dc38870ca1951c51fe1`, valid archive with 95 text lines / 33 heartbeats / 2 keyboard events. Godot 4.7.2 G2.1 ran 33s, tick ~323. Gyar? No: G21 agents were #025/#094/#143.
- #143 Snorlax spontaneously entered ROAM around [19077ms], reached 41.6px traveled, then after user's keyboard 3 (focus) + M (forced movement) reached 80px; #025 ~785px and #094 ~441px at end. So bounded 18s policy and manual force are observed PASS. Full 151 visual/directional behavior is NOT observed.

## Grounding in previous user's Gen1 Recomp work
Old **CG PMD Species Personality / Rich Ambient Authority v2.8.5b** (Google Drive file `290_CG_PMD_Species_Personality_Rich_Ambient_Authority_v2.8.5b.rb`) used one-shot `Float`/`Pose`/`Nod` after dwell, cooldown and preemption by movement/action, with strict animation metadata and position-delta safety. This is design reference, not identical baseline to be copied blindly. We adopt *one-shot ambient ownership + preemption*, while user requested **Walk frame0 base pose + occasional native Idle** for Godot; do not assume old project's exact behavior is automatically portable.

PMD directions native sheet mapping S=0, SE=1, E=2, NE=3, N=4, NW=5, W=6, SW=7, referenced by https://github.com/netraular/PMDSpriteManager and PMD Sprite Format https://wiki.pmdo.pmdcollab.org/PMD_Sprite_Format. Godot screen axes Y positive down. Direction map from 45-degree quantization: 
- down→0; down-right→1; right→2; up-right→3; up→4; up-left→5; left→6; down-left→7.
- Stop preserves last facing; no unnecessary return to front. 
- Each direction change loads/caches row-specific `SpriteFrames` and obtains `get_frame_alignment(motion, row, sprite.frame)`, so art and native shadow/feet reference always use same row. If non-directional assets lack a row, fallback to valid row 0 and align accordingly. Distinct cached render rows retained.

## Source files / design
- New **independent** `scenes/ecology_animation_lab.tscn` and `scripts/lab/ecology_animation_lab.gd`: clones accepted G21 policy, no change to previous G2.0.2/G21 scenes.
- `scripts/lab/pmd_visual_policy.gd`: 8-direction quantizer and species-specific animation rates + ambient interval. Native `AnimData.xml` duration tick timings retained in SpriteFrames.
- Stationary pose: `Walk` animation frame0, paused, not animated walk-on-spot.
- One-shot ambient: non-looping `Idle` animation started only after species-specific dwell. Expected approximate intervals: #025 3.5–6 sec, #094 7–12 sec, #143 12–19 sec of stationary screen time. Actual Idle duration derived from native per-frame durations / 60 / speed_scale.
- On move/return state, immediately interrupt any ongoing ambient. Direction frames dynamically match movement vector; playback movement speeds #025 1.32x, #094 1.0x, #143 0.58x; ambient speeds 0.90/0.85/0.72x respectively. **These are proposed tuning points, NOT a claim of Gen1 Recomp exact numeric values.**
- `scripts/lab/ecology_animation_diagnostics.gd`: distinct G22 `reports/PLW_G22_RUNTIME_LAST.log`, records facing row, visual mode, idle micro-event count alongside G21 movement counters.
- New `RUN_G22_COLLECT_LOG_WINDOWS.bat`, `tools/g22_collect_logs.py`, `RUN_G22_TESTS_WINDOWS.bat`, `tests/test_g22_visual_director.py`.

## Surface test: 30–60 seconds
1. Close Godot editor, Fetch/Pull isolated `planning/pokemon-living-world-godot` branch; raw 151 species remain local. Double-click `scenes/ecology_animation_lab.tscn`, confirm Scene tree `EcologyAnimationLab > Diagnostics`, press **F6**.
2. Observe #143 standing on Walk first frame while not moving. Over ~12–19 stationary seconds, a short *nonlooping* Idle event may happen, then returns to Walk first frame; should not bounce continuously.
3. Check #025 can hop occasionally when stationary; while ROAM it plays Walk frames at quicker cadence. #094 medium, #143 slower.
4. Observe row text, debug velocity arrow and sprite visual direction as each walks: moving right must use row2, left row6, up row4, down row0 (diagonals similarly).
5. Check direction changes cause neither foot-anchor upshift nor giant Pokémon clipping. For full roster acceptance, separate 151-species directions test remains needed.
6. Stop; run `RUN_G22_COLLECT_LOG_WINDOWS.bat`; attach `reports/PLW_G22_DIAGNOSTICS_TO_SHARE.zip` + screenshot with facing while moving.

## Validation and gates
- Build workspace Python static/mathematical/synthetic 122/122 tests PASS (108 prior + 14 new). **No Godot executable available here.** Not an engine parse/animation playback pass.
- Existing G0 G1 G1.1 G1.2 G2.0.2 G2.1 scenes preserved untouched. Main `project.godot` remains G1 default.
- Native PMD art never copied into public repo or ZIP. Source and credit files stay locally at `data/raw/pmdcollab/`.
- Failure interpretation: if scene parser errors, send screenshot with first red error, avoid claiming G22 pass; if G22 log missing, confirm F6 correct active scene. Runtime directions are **candidate map** pending visual seal.
