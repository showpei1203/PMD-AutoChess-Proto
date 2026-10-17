# Pokémon Living World — G3.1 v0.5.1 (2026-10-17)

## Latest state
- **G3.0 Surface native Godot trainer order PASS** based on user-uploaded actual LOG (1–4 input, distinct action scores, guarded damage, 12 native engine scenarios). Source code unchanged.
- **G3.1 isolated tactical spacing candidate**: distinct `scenes/g31_combat_lab.tscn` + own core/UI/logger/Godot headless replay gate. `KEEP_DISTANCE` pursues a genuine 118–160px band with RETREAT/STRAFE and a prototype weak ranged attack; DEFENSIVE/Gengar GUARD incurs 25-tick recharge to prevent repeatedly free blocking. Actual strike range and power are SNAPSHOTTED at windup, so mid-fight switching trainer posture does not alter an already-committed strike. Correct facing/feet remains visual-only.
- **Offline Python 176/176 tests PASS**; independent offline 32 seeds x 4 postures x 2 deterministic trials (128 paired scenarios), however the seeds only vary starting positions; **not Godot runtime, not strategic balance acceptance**. Current offline KEEP_DISTANCE can retreat/strafe/ranged attack but loses in this limited prototype. Maintain known issue: corner trapping and small arena mean practical kiting is still incomplete.
- **Native Godot gate** `tests/g31_godot_engine_gate.gd` called by launcher before scene start: 8 seeds x 4 postures x 2 replays (32 scenario pairs), must print `G31_GATE RESULT samples=32 failures=0` with nonzero zoning metrics. If Godot parser/runtime fails, ZIP still collects gate error, game not launched.
- **No G1–G3.0 file modified except external handoff context**. Raw PMDCollab sprite directories remain local private, never distributed or Git-committed.
- New package is a **candidate**, G3.1 Surface / rendering / strategy acceptance PENDING. Do not claim full G3 or official Pokémon skill mechanics.

## Run on Surface (NO F5/F6)
1. GitHub Desktop on `planning/pokemon-living-world-godot` -> Fetch/Pull, preserve local PMDCollab data under `data/raw/pmdcollab/`.
2. Double-click `RUN_G31_DIRECT_SCENE_WINDOWS.bat` in Godot project root, select Godot 4.7.2 executable if asked.
3. Wait for native gate `G31_GATE RESULT samples=32 failures=0`. Then game opens. Press `3` (KEEP_DISTANCE), then `R` (same seed restart); see `RETREAT` at close distances, `STRAFE` and `ZONE` attacks in band; press `4` then `R` to compare guard recharges. `1` and `2` also work, `N` switches seed. Keep the game open until result, close normally.
4. Upload `reports/PLW_G31_DIRECT_DIAGNOSTICS_TO_SHARE.zip` and optional result screenshot. Launcher still emits ZIP even if native gate fails. The diagnostic ZIP contains only text logs, no artwork.

## Archived stable baselines
The original G3.0 lab and the G2.3 ecological animations are preserved byte-for-byte; F5 still launches G1 animation lab. G3.1 changes apply ONLY in the new scene.

---

# CURRENT: G3.0 autonomous 1v1 lab v0.5.0 (2026-10-17)

**Next milestone: autonomous combat vertical slice, not formal G3 completion.**
This is a standalone scene. G2.3 species cadence stays accepted and unchanged.

- **Run**: `RUN_G30_DIRECT_SCENE_WINDOWS.bat`. It executes 12 real Godot headless replay simulations *before* launching the standalone 1v1 scene. Godot 4.7.2 is requested once if needed.
- **Controls**: 1 Free, 2 Aggressive, 3 Keep Distance, 4 Defensive; 5 Protect Ally is explicitly unsupported in 1v1; Space pause, R replay same seed, N new seed, D debug.
- **Upload evidence**: `reports/PLW_G30_DIRECT_DIAGNOSTICS_TO_SHARE.zip` after closing game window. It contains Godot engine gate, boot, console and battle decision trace; even failure yields a ZIP.
- **Run Python contracts**: `RUN_G30_TESTS_WINDOWS.bat`. Offline tests do not imply Godot real-time acceptance.
- **Architecture**: `docs/G30_UTILITY_COMBAT_VERTICAL_SLICE_20261017.md`; no original Pokémon art included; keep local `data/raw/pmdcollab` private.

---

# Pokémon Living World — G0 Asset Audit Candidate v0.1

**Built:** 2026-10-17. **Python 3.10+**, standard library only.

This deliverable has **no copyrighted Pokémon/PMD PNG assets**. It contains scripts, a Windows quick test, synthetic tests, evidence, and the honest G0 report from the Drive source snapshot. Run inside an isolated folder.

## Quick test
Windows: double click `RUN_TESTS_WINDOWS.bat` after Python is installed.

PowerShell equivalent:
```powershell
py -3 -m unittest discover -s tests -v
```

Other systems:
```bash
python3 -m unittest discover -s tests -v
```

Expected result: `Ran 10 tests ... OK`. These tests deliberately use **generated one-pixel PNG images**, not extracted game sprites.

## Actual private source audit
Obtain the complete PMD mod folder or ZIP from the originating device; the Drive Source Snapshot ZIP is only a **source list + Lua + manifest**, not the art.

```powershell
py -3 tools\pmd_asset_audit.py --source "D:\private\pmd_assets.zip" --reference "D:\private\FILE_LIST.txt" --out ".\reports-new" --require-complete
```

- If actual ZIP has `FILE_LIST.txt` internally, omit `--reference`.
- `--source` can also be the **extracted MOD directory**. For directory sources, pass the original source `FILE_LIST.txt` if not in root.
- Reports: `audit_summary.json` and `asset_matrix.csv`.
- Exit `0` with `--require-complete` requires every PNG listed in the reference to be present and structurally valid. Exit `2` means a missing/corrupt source or reference inconsistency, so **do not promote G0**.
- Optional `--stage-private <directory>` copies verified PNG files into a private target for later Godot import. Do not commit or upload these images to a public GitHub repo.
- This tool validates PNG container signature, dimensions, chunk CRC and IEND. Pixel decoding, native action timing, anchor points and true eight-direction animations require future gates.

## Existing snapshot findings
The official Drive ZIP `GEN1RECOMP_PMD_EXACT_SOURCE_20260819_185548.zip` (124,458 bytes) SHA256:
`a9cb2426e661b9cbe9c439a84696badbc139f855f93b19b9c1741120fd468b81`.
It has exactly **4** archive entries: `FILE_LIST.txt`, `main.lua`, `manifest.json`, `SHA256.txt`.
File list references **11,477** PNG files across 151 dex IDs, but the archive contains **zero PNGs**. These are not 11,477 "corrupt" images; these are **not supplied** in this snapshot. The 11,477 rows therefore report `MISSING`, not `PRESENT`.

Check the first G0 report under `reports/audit_summary.json` and `reports/asset_matrix.csv`.

## Original device source hint
The snapshot's original Android paths include:
`/storage/emulated/0/Android/data/io.github.averageconsumer.gen1recomp.androidtest/files/save/pokemon-love2d/mods/pmd_idle_battle_sprites/`
Use this as a hint only; the mod may have moved since the snapshot. Look for the folder with `motion/`, `shadow/`, `sprites/`, `static/`, `dex/` rather than just `main.lua`.

## Baseline policy
Do not modify old Gen1recomp formal baselines. The PLW project lives on GitHub branch `planning/pokemon-living-world-godot` and its Drive project folder. See https://github.com/showpei1203/PMD-AutoChess-Proto/issues/15.

## Update 2026-10-17: upstream download, no need to manually supply original art
The previous source-only Drive snapshot omitted PNGs. This is no longer a request for the user to manually copy files from AYN THOR: official community data is published at https://github.com/PMDCollab/SpriteCollab and https://sprites.pmdcollab.org/.
- Run `RUN_FETCH_3_WINDOWS.bat` to fetch and audit Pikachu, Gengar, Snorlax into ignored `data/raw/pmdcollab/`.
- After preview success, run `RUN_FETCH_151_WINDOWS.bat` to attempt all Kanto species from public `spriteserver.pmdcollab.org` ZIP endpoints.
- Source action format includes `AnimData.xml` and per-action `*-Anim/Offsets/Shadow.png`. Godot visual importer remains a next gate.
- `docs/G0_UPSTREAM_PMD_COLLAB_RECOVERY_20261017.md` explains verified sources, rights, tests and remaining gates.
- 22 offline tests pass, but the live server downloads and 151 actual art are not yet runtime-verified on the Surface.


## v0.2.1 Hotfix — #0148 Dragonair `Idle → CopyOf Walk`
The upstream animation definition may reference another animation rather than a physical `Idle-Anim.png`. The validator now resolves `CopyOf` chains, detects cycles and missing targets, and prints a summary of passes/failures. Synthetic tests **27/27 OK**. The user's previously failed #148 must be revalidated on Surface after `Pull origin`: rerun `RUN_FETCH_151_WINDOWS.bat` (cached successes are reused). Details: `docs/G0_0148_COPYOF_HOTFIX_20261017.md`.

## G1 v0.3.3 (2026-10-17)
Addresses #094 Gengar XML streaming `XML tag mismatch: AnimData` and six Image.load() export warnings. Source parsed per `<Anim>` and PNG resources loaded as Godot Texture2D. Offline Python tests 45/45 PASS. Godot F5 re-test on Surface PENDING; source sprites not included.

## G1.1 | 151-species lazy-loaded gallery v0.3.4
Independent Godot scene `scenes/roster_lab.tscn` (run by opening scene + F6) for browsing dex 001..151 in 3-species pages using `Q/E`. `T` restores accepted benchmark #025/#094/#143; `I/W/A` and facing-row controls remain. The accepted G1 default main scene is intentionally unchanged. `RUN_G11_ROSTER_PREFLIGHT_WINDOWS.bat` produces JSON + CSV with source animation and CopyOf readiness; **no original art included in GitHub**. Pending actual Surface runtime and human visual validation. See `docs/G11_KANTO_GALLERY_20261017.md`.

## G1.2 (v0.3.5, 2026-10-17): manual species calibration candidate

G1.1 Surface gallery operation: **user-reported PASS**, not a per-species directional/offset sign-off. Existing `scenes/animation_lab.tscn`, `scenes/roster_lab.tscn`, and `project.godot` stay unchanged. Open `res://scenes/calibration_lab.tscn` with F6 for a **separate** 1-species manual ground/scale/facing inspector. Controls and draft JSON semantics: `docs/G12_CALIBRATION_LAB_20261017.md`. All 61 local offline tests PASS; real Surface F6 pending. No downloaded copyrighted art included.

## v0.3.6 | PMD native shadow/ink-aware sprite anchor
Fixes a proven bug in G1.2 calibration: placing full frame bottom on ground caused visibly raised characters whenever the transparent frame bottom extended below sprite pixels. New calibration prefers PMD Shadow.png white center, falling back to alpha-ink bottom (with warnings around flying/jumping). The F6 lab supports N-key A/B/C comparison; an optional stdlib-only `RUN_G12_ANCHOR_AUDIT_WINDOWS.bat` emits numeric first-frame 151 species anchor reports. 74/74 offline tests PASS; Surface F6 and actual local 151 PNG audit remain PENDING. No previously accepted gameplay scene changed. See `docs/G12_AUTO_ANCHOR_20261017.md`.

## G2.0 v0.3.7 Ecology prototype (2026-10-17)

An **isolated** scene at `scenes/ecology_lab.tscn` now prototypes Pikachu (CURIOUS), Gengar (PROWL), Snorlax (ANCHOR), five autonomous ecology states and a 10 Hz deterministic decision clock. Open the scene and press **F6** in Godot on Surface; this project still launches the previously accepted G1 animation lab with F5. No Pokémon art binaries are included. Run `RUN_G20_TESTS_WINDOWS.bat` for the full offline Python regression suite (83/83 pass locally). This is **not combat AI** or 151 completed species AI. The G1.2.1 user-accepted anchor audit is recorded without inventing per-species CSV metrics. See `docs/G20_ECOLOGY_PILOT_20261017.md` and `reports/G20_CHECKPOINT_20261017.log`.

## G2.0.1 v0.3.8 ecology observability hotfix
Previous Surface G2.0 behaviour acceptance failed (no perceptible locomotion, seed differentiation or debug overlay). The initial D key **hid** debug because overlay started ON; it now starts OFF, with a bright overlay on first D. Initial states and targets differ by species, `M` forces the focused species into a diagnostic ROAM, and tick/distance/seed/target tracing distinguishes broken AI updates from small sprites. **Surface Godot F6 re-test is required**: do not mark G2 PASS based on Python tests. See `docs/G201_ECOLOGY_DIAGNOSTICS_20261017.md`. The accepted G1 baseline remains untouched.

## G2.0.2 v0.3.9 | Runtime diagnostics and Handoff
Surface G2 tick/input failures are still unverified root cause. Open `scenes/ecology_lab.tscn` with F6 (F5 starts old G1). Observe `G2.0.2 LOGGER ACTIVE`, use on-screen M/D/N. Runtime LOG: `reports/PLW_G2_RUNTIME_LAST.log`. ZIP collector: `RUN_G2_COLLECT_LOG_WINDOWS.bat` -> `reports/PLW_G2_DIAGNOSTICS_TO_SHARE.zip`. All subsequent changes must update `docs/CURRENT_HANDOFF_PLW.md` and append `docs/HANDOFF_HISTORY_PLW.md`, then mirror to Google Drive.

## G2.1 v0.4.0 — Species behaviour / Snorlax bounded walk (2026-10-17)
- **NEW separate scene**: `scenes/ecology_behavior_lab.tscn` (open scene, **F6**). Original G2.0.2 `scenes/ecology_lab.tscn` and G1/G1.1/G1.2 scenes unchanged.
- #025 Pikachu still begins ROAM; #094 Gengar begins OBSERVE then ROAM; #143 Snorlax starts REST, with a **max 18-second non-roaming window** that triggers a short seeded stroll while retaining low speed and radius. The deadline resets upon starting an actual trip, not each IDLE/REST/OBSERVE.
- Debug shows per-species total walking distance, roam count and Snorlax wake-up countdown. Orange debug-only heading arrow indicates movement vector, not an unverified PMD facing-row mapping.
- **NEW log** `reports/PLW_G21_RUNTIME_LAST.log` and shareable `reports/PLW_G21_DIAGNOSTICS_TO_SHARE.zip` via `RUN_G21_COLLECT_LOG_WINDOWS.bat`; original G2 log remains separate.
- `RUN_G21_TESTS_WINDOWS.bat`: **108/108 offline tests PASS**, including 10 new bounded-behaviour, isolated-scene, and text-only ZIP contracts; **Surface Godot runtime verification PENDING**.
- Windows workflow: Fetch/Pull `planning/pokemon-living-world-godot`, double-click `scenes/ecology_behavior_lab.tscn`, confirm `EcologyBehaviorLab > Diagnostics`, press **F6**, wait **at least 30 seconds**. Watch #143 move spontaneously (and after `3`, `M`), observe orange heading, then stop and upload new G21 diagnostics ZIP. `R` repeats same seed; `N` seeds a new route, `D` toggles visible debug circles, `Space` pauses simulation. No need to redownload artwork.
- This candidate does **not** claim Godot runtime pass, PMD 8-way directions, obstacle navigation or battle AI. Official source art stays ignored (`data/raw`).

## G2.2 v0.4.1 optional animation-direction laboratory (not F5)
`scenes/ecology_animation_lab.tscn` -> F6. Walking sprite now changes its native PMD direction row from movement velocity. Standing uses frozen Walk frame0 with occasional 1-shot native Idle action at species-dependent intervals; movement immediately preempts Idle. Local LOG is `reports/PLW_G22_RUNTIME_LAST.log`, collected via `RUN_G22_COLLECT_LOG_WINDOWS.bat`. 122 Python offline tests PASS; Surface Godot test PENDING. Full methods and evidence in `docs/G22_ANIMATION_DIRECTION_AUTHORITY_20261017.md`. G0/G1/G2.1 accepted scenes unchanged.

## G2.2.1 v0.4.1.1 Surface Godot parser hotfix (2026-10-17)
Previous G2.2 v0.4.1 had undefined locals `roams` and `since_roam` in `ecology_animation_diagnostics.gd:104`, preventing GDScript parsing. Fixed both locals, corrected diagnostic UI version and added 3 offline regression tests (125/125 PASS). **Godot 4.7.2 runtime still PENDING.** Double-click `scenes/ecology_animation_lab.tscn` so the active tab/tree says `EcologyAnimationLab > Diagnostics`, then F6. Stop and collect `reports/PLW_G22_DIAGNOSTICS_TO_SHARE.zip` with `RUN_G22_COLLECT_LOG_WINDOWS.bat`. See `docs/G221_PARSER_ROAM_TELEMETRY_HOTFIX_20261017.md`.

### G2.2.3 direct-boot diagnostic (2026-10-17)
New `RUN_G22_DIRECT_SCENE_WINDOWS.bat` starts `scenes/ecology_animation_lab.tscn` directly, without editor active-tab/F6 ambiguity, and bundles boot/console/runtime logs at `reports/PLW_G22_DIRECT_DIAGNOSTICS_TO_SHARE.zip` **after closing game window**. If asked, select Godot 4.7.2 executable once. This is a diagnostic candidate; G22 visual facing/idle remains unverified. Offline 134/134 PASS; real Surface Godot runtime pending.


## G2.3 v0.4.2｜Species cadence lab (Surface candidate)
- Scene: `scenes/ecology_ambient_lab.tscn` (independent, inherits accepted G2.2 AI/facing).
- Run `RUN_G23_DIRECT_SCENE_WINDOWS.bat` (direct Godot launch, avoids F5/F6 confusion).
- Stationary PMD `Walk` animates *slowly* per species, with occasional one-shot Idle / safe Float/Nod/Pose, genuine roaming always preempts idle performance.
- Runtime evidence `reports/PLW_G23_DIRECT_DIAGNOSTICS_TO_SHARE.zip` created by launcher, even on startup failure.
- Python offline tests 146/146 PASS; Surface visual/runtime test **PENDING**. No PMD image data in source ZIP.
