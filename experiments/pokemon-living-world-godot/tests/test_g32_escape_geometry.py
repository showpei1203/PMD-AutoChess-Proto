"""G3.2 deterministic geometry contracts and independent corner calculations.

NOT a substitute for real Godot 4.7.2 GDScript parser/runtime tests.
"""
from pathlib import Path
import importlib.util
import math
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
CORE = (ROOT/'scripts/battle/g32_combat_core.gd').read_text('utf-8')
LAB = (ROOT/'scripts/battle/g32_combat_lab.gd').read_text('utf-8')
DIAG = (ROOT/'scripts/battle/g32_combat_diagnostics.gd').read_text('utf-8')
SCENE = (ROOT/'scenes/g32_combat_lab.tscn').read_text('utf-8')
GATE = (ROOT/'tests/g32_godot_engine_gate.gd').read_text('utf-8')
LAUNCHER = (ROOT/'tools/g32_direct_launch.py').read_text('utf-8')
BAT = (ROOT/'RUN_G32_DIRECT_SCENE_WINDOWS.bat').read_text('utf-8')
REF = ROOT/'tools/g32_escape_reference.py'
spec = importlib.util.spec_from_file_location('g32_ref', REF)
ref = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = ref
spec.loader.exec_module(ref)

class EscapeGeometryContracts(unittest.TestCase):
    def test_new_scene_is_isolated_from_g31(self):
        self.assertIn('g32_combat_lab.gd',SCENE)
        self.assertIn('g32_combat_diagnostics.gd',SCENE)
        self.assertIn('extends "res://scripts/battle/g31_combat_lab.gd"',LAB)
        self.assertIn('extends "res://scripts/battle/g31_combat_core.gd"',CORE)
        self.assertNotIn('ESCAPE_LOOKAHEAD_TICKS', (ROOT/'scripts/battle/g31_combat_core.gd').read_text())

    def test_wall_lookahead_is_actual_geometric_projection(self):
        self.assertIn('func _retreat_wall_risk(i: int)', CORE)
        self.assertIn('_clamp(forward)',CORE)
        self.assertIn('ESCAPE_LOOKAHEAD_TICKS: int = 9',CORE)
        self.assertIn('func _wall_clearance(point: Vector2)',CORE)
        self.assertIn('func _escape_score(i: int, heading: Vector2)',CORE)
        self.assertIn('var predicted_foe: Vector2',CORE)

    def test_not_just_raising_retreat_utility(self):
        self.assertIn('result["action"] = "ESCAPE"', CORE)
        self.assertIn('if str(intent["action"]) != "ESCAPE":', CORE)
        self.assertIn('super._apply_intent(i, intent)', CORE)
        self.assertIn('var chosen: Vector2',CORE)
        self.assertIn('for candidate in ESCAPE_DIRS:',CORE)

    def test_hysteresis_and_replanning_and_wall_contacts(self):
        self.assertIn('ESCAPE_LOCK_TICKS: int = 18', CORE)
        self.assertIn('escape_lock_until', CORE)
        self.assertIn('escape_replans', CORE)
        self.assertIn('wall_contacts', CORE)
        self.assertIn('next.distance_to(pos) < steps * 0.70', CORE)
        self.assertIn('ESCAPE_PLAN unit=%d',CORE)

    def test_only_ranged_player_can_escape_when_retreating(self):
        self.assertIn('if i != 0 or order != "KEEP_DISTANCE":',CORE)
        self.assertIn('if str(result["action"]) == "RETREAT"',CORE)
        self.assertIn('super.reset(new_seed, new_order)', CORE)

    def test_real_motion_still_uses_animated_walk_not_slow_stance(self):
        self.assertIn('action in ["RETREAT", "STRAFE", "ESCAPE"]',LAB)
        self.assertIn('Visual.playback_speed',LAB)
        self.assertIn('super._physics_process(delta)',LAB)

    def test_runtime_logger_includes_escaping_metrics(self):
        self.assertIn('PLW_G32_RUNTIME_LAST.log',DIAG)
        self.assertIn('G3.2-v0.5.2',DIAG)
        self.assertIn('escape=%d plans=%d replans=%d wall_contacts=%d',DIAG)

    def test_realtime_gate_has_four_corners_and_replays(self):
        self.assertIn('const CORNERS:', GATE)
        self.assertIn('G32_GATE RESULT samples=%d failures=%d',GATE)
        self.assertIn('a["signature"] != b["signature"]',GATE)
        self.assertIn('corner_success != CORNERS.size()',GATE)
        self.assertIn('total_escape == 0',GATE)
        self.assertIn('Core.MAX_TICKS',GATE)

    def test_direct_launcher_engine_gate_precedes_scene(self):
        self.assertIn('g32_godot_engine_gate.gd',LAUNCHER)
        self.assertIn('G32_GATE RESULT samples=36 failures=0',LAUNCHER)
        self.assertIn('g32_combat_lab.tscn',LAUNCHER)
        self.assertIn('g32_direct_launch.py',BAT)
        self.assertIn('PLW_G32_DIRECT_DIAGNOSTICS_TO_SHARE.zip',LAUNCHER)

    def test_corner_risk_probes_detect_wall_in_all_quadrants(self):
        for i,p in enumerate(ref.CORNERS):
            foe = (p[0]+(80 if p[0]<480 else -80),p[1]+(80 if p[1]<260 else -80))
            with self.subTest(corner=i):
                self.assertTrue(ref.is_wall_risk(p,foe))

    def test_predicted_route_can_leave_four_corner_points(self):
        for i in range(4):
            with self.subTest(corner=i):
                r=ref.probe_corner(i)
                self.assertGreater(r['traveled'],50)
                self.assertGreaterEqual(r['wall_clearance'],0)
                self.assertTrue(ref.WEST<=r['end'][0]<=ref.EAST)
                self.assertTrue(ref.NORTH<=r['end'][1]<=ref.SOUTH)

    def test_corner_determinism_and_mirror_symmetry(self):
        runs=[ref.probe_corner(i) for i in range(4)]
        for i in range(4): self.assertEqual(runs[i],ref.probe_corner(i))
        self.assertAlmostEqual(runs[0]['traveled'],runs[1]['traveled'])
        self.assertAlmostEqual(runs[2]['traveled'],runs[3]['traveled'])

    def test_lateral_routes_not_truncated_in_open_space(self):
        p=(480.,260.);f=(510.,300.)
        heading=ref.choose(p,f)
        next=ref.step(p,f,heading)
        self.assertGreater(math.hypot(next[0]-p[0],next[1]-p[1]),1.)
        self.assertLessEqual(math.hypot(*heading),1.01)

if __name__=='__main__': unittest.main()
