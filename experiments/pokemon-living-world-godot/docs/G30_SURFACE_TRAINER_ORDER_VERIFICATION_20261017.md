# G3.0 Trainer Order Verification | Surface Godot 4.7.2 | 2026-10-17

**Checkpoint**: `PLW_G30_SURFACE_ORDER_INPUT_POLICY_PASS_DESIGN_GAPS_20261017`  
**Evidence**: User-uploaded `PLW_G30_DIRECT_DIAGNOSTICS_TO_SHARE.zip`, ZIP CRC PASS, SHA-256 `2a63159ba9e0e5324984f37a8022063d7853e8978bbcf11a2ec157094afe0ab6`.  
**Privacy**: Only summary and cryptographic digest committed to public GitHub. Original Surface logs, absolute user paths and Pokémon images not redistributed.

## Verified runtime
- Godot `4.7.2.stable.official`; directly launched `res://scenes/g30_combat_lab.tscn`; `godot_headless_gate_exit=0`, `godot_headless_gate_result_seen=True`, `godot_exit_code=0`; startup runtime `LOGGER_READY build=G3.0-v0.5.0`; engine boot and console contain 0 ERROR/WARNING keywords. ZIP contains headless gate, boot, console, 533-line runtime log, launcher report.
- Native Godot gate: `G30_GATE RESULT samples=12 failures=0`, with 3 seeds × 4 fixed strategy trials, each replayed twice; this shows deterministic core results within this limited seed set. No visual battle acceptance or full G3 feature gate is implied.
- Actual in-scene keyboard events: keycode 49=1 once, 50=2 three times, 51=3 three times, 52=4 once, 82=R, 78=N. Runtime ORDER transitions at t10.7 KEEP_DISTANCE, t13.0 AGGRESSIVE, after R t2.5 KEEP_DISTANCE / t5.7 DEFENSIVE / t8.9 AGGRESSIVE; after N t2.6 KEEP_DISTANCE / t6.2 AGGRESSIVE / t9.0 FREE. UI order and battle core are connected.
- Concrete **player Pikachu (unit0)** decision effects: `KEEP_DISTANCE` tick122 / tick44 chooses DODGE with utility 119. `DEFENSIVE` tick67 and tick80 chooses GUARD with utility 123; Gengar hits at ticks 70 and 83 register `guard=true damage=5` versus unguarded base power 11. `AGGRESSIVE` tick95/tick104 chooses ATTACK with utility 125. Wild Gengar (unit1) always follows `order=WILD`, not player's trainer order.
- Native core policy code: AGGRESSIVE boosts player ATTACK +15 when ready, disables GUARD and shortens cooldown ticks from 11 to 9; KEEP_DISTANCE raises APPROACH score to at least 92 at long range and increases DODGE to 119 when enemy telegraphs; DEFENSIVE raises GUARD to 123 when eligible. Changes are conditional, not instantaneous universal behaviors.

## Same-seed native Godot gate (fixed strategy from tick 0; does not mix mid-fight orders)
| Seed | FREE | AGGRESSIVE | KEEP_DISTANCE | DEFENSIVE |
| --- | --- | --- | --- | --- |
| 20261017 | Gengar win, t135, Pikachu0 Gengar22 | Gengar win, t135, P0 G4 | Gengar win, t135, P0 G22 | Pikachu win, t193, P25 G0 |
| 20365746 | Gengar win, t135, P0 G22 | Gengar win, t135, P0 G4 | Gengar win, t137, P0 G28 | Pikachu win, t193, P25 G0 |
| 31415926 | Gengar win, t135, P0 G22 | Gengar win, t135, P0 G4 | Gengar win, t137, P0 G28 | Pikachu win, t193, P25 G0 |

## Gate, limitations and next
- **G3.0 order-input + actual conditional Utility score / decisions + guard damage mitigation: REAL SURFACE PASS**; replay test: Godot native 12/12 scenarios, 0 failures.
- **KEEP_DISTANCE semantics incomplete**: still approaches the target aggressively; it does not maintain a long range or kite. Same-seed results match FREE for 20261017 in win/tick/HP, even though digest changes. Rename/rework before treating as fulfilled order.
- **Small-sample strategy balance poor**: DEFENSIVE wins all 3 tested seeds and other styles lose. This is design/testing data, not proof it dominates for 151 species or broader seed distributions. Actual user mid-fight mixed commands cannot be used as an isolated power comparison.
- **Fifth PROTECT_ALLY intentionally unsupported** in 1v1; G3 named attacks, 2v2 ally protection, terrain collision, type/PP/stats and full strategic design remain pending.
- No code changes or new build in this verification turn; use previous v0.5.0 full ZIP: https://drive.google.com/file/d/14Q4TmCg8CLi-ST977MG2sqLJpWra6Bbw/view . Existing Python 163/163 remains historical; not re-run in this evidence-only update.
