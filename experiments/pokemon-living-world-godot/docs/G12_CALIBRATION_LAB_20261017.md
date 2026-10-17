# G1.2 | Species ground anchor + scale + raw facing calibration

Status: CANDIDATE, Surface F6 visual acceptance **PENDING**.

User confirmed G1.1 151-species roaming gallery works on Surface. This is **user-reported functional operation**, not independent inspection of all 151 frame/action variations. The previously accepted scenes `animation_lab.tscn`, `roster_lab.tscn`, and `project.godot` are not modified by G1.2.

## Technical rationale
- PMDCollab PNG animation frame rectangles vary in dimensions by species and action, and their transparent regions do not necessarily end on the actual foot pixel.
- The initial sprite is vertically aligned such that its current frame rectangle bottom touches the world ground reference, then allow manual pixel offsets.
- Facing shows raw source direction **row 0..7**. Direction-to-world-compass semantic mapping is unknown and cannot be asserted until confirmed visually.
- Dark elliptical ground shadow is **debug-only**, not a PMD `*-Shadow.png` nor a source-grounded per-frame offset. Shadows, offsets, individual body silhouettes and combat contact masks remain pending.

## How to try on Surface
1. Close Godot; Github Desktop on `planning/pokemon-living-world-godot` -> Fetch origin -> Pull origin. If blocked, stash uncommitted Godot-created `.uid` or project settings without restoring stale scripts over the update.
2. Open Godot project, select `res://scenes/calibration_lab.tscn`, press **F6**. The default F5 3-Pokémon stage and G1.1 gallery stay exactly as before.
3. `1/2/3` benchmark 025/094/143. `Q/E` previous/next Kanto species. `I/W/A` Idle/Walk/Attack; left/right arrows for raw PMD direction row. `Z/X` scale -/+0.1 (0.5–4x). Up/down changes foot baseline Y; J/L changes X. `B` debug shadow on/off. `R` reset scale and foot offsets. `S` stores draft JSON at `user://plw_g12_NNNN.json`.
4. Compare Pikachu, Gengar, Snorlax at Idle/Walk/Attack at row 0, then 2,4,6. Check whether projected foot cross stays at an acceptable place after action switches, and note which raw row points which way. Optionally check bigger species #003/#006/#143 to see how frame-box height differs from natural size.
5. Inspect Godot Output / Debugger for `[PLW-G12]` and errors. G1.2 is not PASS until a real Surface run shows functioning controls, no missing sprites and no errors.

## Local metadata schema
`{schema, species_id, scale, shift_x, shift_y, raw_direction_row, direction_mapping_verified:false, shadow_kind:'debug_ellipse_only', accepted_as_physical_collisions:false}`.

The saved JSON is a **local operator draft**. Do not implicitly apply it to 151 species, derive collision radius from display scale, or consider it authoritative physical body/feet geometry. Source art stays ignored and outside public GitHub. Future stage will use `*-Offsets.png` and `AnimData.xml` to produce deterministic per-frame foot/anchor offsets and handle body-size classes.

## Verification
Prior G1.1 offline suite: 54/54 PASS as recorded in v0.3.4. G1.2 adds synthetic/static contract tests; see current test log. No Godot binary installed in authoring workspace, so Surface F6 is **PENDING**.
