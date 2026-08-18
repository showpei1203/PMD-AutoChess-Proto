# v1.06.56 Windows / RPG Maker VX Loading Acceptance

Date: 2026-08-18
Status: **PASS**
Scope: SHO-35 — Random Hunt Map Loading Overlay — Real Progress Bar

## User real-machine evidence

Screenshot visually confirmed the Random Hunt loading overlay is present during H01 Floor 1 generation and matches the established Battle Loading presentation:
- full black loading background;
- centered framed loading window;
- title + percentage (`探索地圖準備中 65%` in supplied screenshot);
- blue progress bar;
- stage text (`完成入口出口檢查` in supplied screenshot);
- Hunt/Floor detail (`H01 | Floor 1`);
- running Pokémon loading mascot;
- no premature map reveal visible in the supplied frame.

Runtime evidence from `PMD_VXRD_MapLoading_LATEST.log`:

```text
PMD AutoChess VXRD Map Loading v1.06.56
RESULT=PASS
CODE=H01
FLOOR=1
ELAPSED_MS=4353
UI_REQUESTS=34
UI_FLUSHES=19
UI_MS=151
UI_MAX_MS=23
FINAL_PERCENT=100
REAL_CHECKPOINTS=1
FAKE_TIMER=0
INPUT_PASSTHROUGH=0
```

## Acceptance conclusion

PASS criteria satisfied for the delivered v1.06.56 candidate:
- real checkpoint progress is active;
- final percentage reaches 100;
- no fake timer is used;
- loading input passthrough is disabled;
- UI refresh overhead is bounded in the observed run (151 ms total UI work, 23 ms max single UI refresh);
- Battle-style visual authority is visibly preserved.

No Battle LOG was required because no Runtime/battle failure was reported.

## Promotion authority

Promote **v1.06.56 — VXRD Random Hunt Real Loading Overlay I** to Formal PASS baseline.
SHO-35 may be closed Done.
SHO-22 remains independent and continues broader route-stress work after this promotion.
