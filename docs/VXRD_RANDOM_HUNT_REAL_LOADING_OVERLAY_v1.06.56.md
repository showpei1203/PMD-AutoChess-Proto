# VXRD Random Hunt Real Loading Overlay I — v1.06.56

## Visual Authority
Reuses the accepted battle-loading language:
- `Window_PMDBattleResourceLoadingV1029` layout/style reference.
- `Sprite_PMDLoadingPokemonV1007` running mascot.
- v1.02.33 refresh-throttle policy reference.

## Real progress checkpoints
0 → Hunt loading open
12 → Map090 layout / terrain
45 → Landmark start
60 → Landmark / collision complete
62–66 → pre-event entrance/exit audit
68–82 → Map091 materialize + semantic relocation
84–90 → post-event required-target route audit
93 → Hunt floor data finalize
96 → map/spriteset preparation
100 → immediately ready to reveal

No elapsed-time fake progress is used. No artificial loading delay is added.

## Safety
- Map090 transfer only for Scene_Map transfer override.
- Same-map floor generation uses the shared generation wrapper.
- Input passthrough remains disabled while overlay is active.
- Error/failed generation closes overlay and does not falsely report 100% PASS.
- v1.06.55 route authority is unchanged.
