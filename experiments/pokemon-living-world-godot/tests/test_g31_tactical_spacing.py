"""G3.1 contract and offline reference suite; real Godot gate only on Surface."""
from __future__ import annotations
import importlib.util
from pathlib import Path
import sys
import unittest

ROOT=Path(__file__).resolve().parents[1]
CORE=(ROOT/'scripts/battle/g31_combat_core.gd').read_text(encoding='utf-8')
VISUAL=(ROOT/'scripts/battle/g31_combat_lab.gd').read_text(encoding='utf-8')
DIAG=(ROOT/'scripts/battle/g31_combat_diagnostics.gd').read_text(encoding='utf-8')
SCENE=(ROOT/'scenes/g31_combat_lab.tscn').read_text(encoding='utf-8')
GATE=(ROOT/'tests/g31_godot_engine_gate.gd').read_text(encoding='utf-8')
LAUNCHER=(ROOT/'tools/g31_direct_launch.py').read_text(encoding='utf-8')
BAT=(ROOT/'RUN_G31_DIRECT_SCENE_WINDOWS.bat').read_text(encoding='utf-8')
REFERENCE=ROOT/'tools/g31_reference_sim.py'
spec=importlib.util.spec_from_file_location('g31_reference',REFERENCE)
reference=importlib.util.module_from_spec(spec)
sys.modules[spec.name]=reference
spec.loader.exec_module(reference)

class TacticalSpacingContracts(unittest.TestCase):
    def test_isolated_old_core_not_rewritten(self):
        prev=(ROOT/'scripts/battle/g30_combat_core.gd').read_text(encoding='utf-8')
        self.assertIn('G3.0 deterministic',prev)
        self.assertNotIn('ZONE_MIN',prev)
        self.assertIn('ZONE_MIN',CORE)

    def test_distance_band_actual_retreat_and_strafe(self):
        self.assertIn('if dist < ZONE_MIN:',CORE)
        self.assertIn('elif dist > ZONE_MAX:',CORE)
        self.assertIn('scores["RETREAT"]',CORE)
        self.assertIn('scores["STRAFE"]',CORE)
        self.assertIn('"RETREAT":',CORE)
        self.assertIn('"STRAFE":',CORE)

    def test_non_melee_range_style_has_tradeoffs(self):
        self.assertIn('const ZONE_POWER: int = 8',CORE)
        self.assertIn('const ZONE_COOLDOWN: int = 17',CORE)
        self.assertIn('const ZONE_WINDUP: int = 5',CORE)
        self.assertIn('me["strike_mode"] = "ZONE" if is_zone else "CLOSE"',CORE)

    def test_strike_snapshot_when_switching_order_mid_windup(self):
        self.assertIn('me["strike_range"] = ZONE_REACH if is_zone else float(me["range"])',CORE)
        self.assertIn('me["strike_power"] = ZONE_POWER if is_zone else int(me["power"])',CORE)
        self.assertIn('var in_range: bool = dist <= float(me["strike_range"]) + 12.0',CORE)

    def test_guard_recharge_and_recovery(self):
        self.assertIn('const GUARD_RECHARGE: int = 25',CORE)
        self.assertIn('tick_number >= int(me["guard_ready_at"])',CORE)
        self.assertIn('me["guard_ready_at"] = tick_number + GUARD_RECHARGE',CORE)

    def test_animation_never_owns_damage(self):
        self.assertIn('func _resolve_hits()',CORE)
        self.assertIn('_resolve_hits()',CORE)
        self.assertNotIn('get_frame_count(',CORE)
        self.assertIn('res://scripts/battle/g31_combat_core.gd',VISUAL)

    def test_scene_and_logger_are_version_isolated(self):
        self.assertIn('g31_combat_lab.gd',SCENE)
        self.assertIn('g31_combat_diagnostics.gd',SCENE)
        self.assertIn('PLW_G31_RUNTIME_LAST.log',DIAG)
        self.assertIn('G3.1-v0.5.1',DIAG)
        self.assertIn('SPACE unit=',DIAG)

    def test_native_gate_32_trials_two_replays(self):
        self.assertIn('const SEEDS = [20261017, 20365746, 31415926, 42, 777, 2025, 99991, 8008135]',GATE)
        self.assertIn('G31_GATE RESULT samples=%d failures=%d',GATE)
        self.assertIn('keep_retreat',GATE)
        self.assertIn('keep_strafe',GATE)
        self.assertIn('keep_projectile',GATE)

    def test_direct_launcher_runs_native_gate_first(self):
        self.assertIn('res://tests/g31_godot_engine_gate.gd',LAUNCHER)
        self.assertIn('G31_GATE RESULT samples=32 failures=0',LAUNCHER)
        self.assertIn('g31_combat_lab.tscn',LAUNCHER)
        self.assertIn('tools\\g31_direct_launch.py',BAT)

    def test_seed_replay_deterministic_offline(self):
        for order in reference.ORDERS:
            a=reference.simulate(20261017,order)
            b=reference.simulate(20261017,order)
            self.assertEqual(a,b)
            self.assertGreater(a['hits'],0)
            self.assertNotEqual(a['winner'],-1)

    def test_kiter_uses_retreat_strafe_and_zoning_attacks(self):
        for seed in reference.SEEDS:
            a=reference.simulate(seed,'KEEP_DISTANCE')
            self.assertGreater(a['retreat'],0)
            self.assertGreater(a['strafe'],0)
            self.assertGreater(a['ranged'],0)
            self.assertLessEqual(a['tick'],reference.LIMIT)

    def test_other_orders_are_not_zoning(self):
        for order in ('FREE','AGGRESSIVE','DEFENSIVE'):
            a=reference.simulate(20365746,order)
            self.assertEqual(0,a['ranged'])
            self.assertEqual(0,a['retreat'])
            self.assertEqual(0,a['strafe'])

    def test_headless_benchmark_identifies_balance_not_sealed(self):
        outcomes={order:[reference.simulate(seed,order)['winner'] for seed in reference.SEEDS]
                  for order in reference.ORDERS}
        self.assertEqual(set(outcomes),set(reference.ORDERS))
        self.assertTrue(any(outcomes[o]!=outcomes['FREE'] for o in reference.ORDERS[1:]))

if __name__=='__main__':unittest.main()
