"""G3.0 deterministic offline 1v1 reference and Godot wiring contracts.

IMPORTANT: Python sim is a reference, not a Godot headless runtime execution.
"""
import importlib.util
from pathlib import Path
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
CORE = (ROOT/'scripts/battle/g30_combat_core.gd').read_text('utf-8')
VISUAL = (ROOT/'scripts/battle/g30_combat_lab.gd').read_text('utf-8')
LOGGER = (ROOT/'scripts/battle/g30_combat_diagnostics.gd').read_text('utf-8')
SCENE = (ROOT/'scenes/g30_combat_lab.tscn').read_text('utf-8')
LAUNCHER = (ROOT/'tools/g30_direct_launch.py').read_text('utf-8')
RUNNER = (ROOT/'RUN_G30_DIRECT_SCENE_WINDOWS.bat').read_text('utf-8')
REFERENCE_PATH = ROOT/'tools/g30_reference_sim.py'
spec = importlib.util.spec_from_file_location('g30_reference_sim', REFERENCE_PATH)
reference = importlib.util.module_from_spec(spec)
import sys
sys.modules[spec.name] = reference
spec.loader.exec_module(reference)

class G30CombatReference(unittest.TestCase):
    def test_all_orders_terminate_with_real_hits(self):
        for seed in (0, 1, 20261017, 20365746, 31415926):
            for order in reference.ORDERS:
                with self.subTest(seed=seed, order=order):
                    result = reference.simulate(seed, order)
                    self.assertIn(result['winner'], (0, 1, 2))
                    self.assertLessEqual(result['tick'], reference.TICK_LIMIT)
                    self.assertGreater(result['hits'], 0)
                    self.assertEqual(result['reason'], 'KO')

    def test_same_seed_same_result_and_digest(self):
        for seed in (0, 20261017, 20365746, 42):
            self.assertEqual(reference.simulate(seed), reference.simulate(seed))

    def test_new_seed_changes_spawn_and_replay_digest(self):
        a = reference.simulate(20261017)
        b = reference.simulate(20261017 + reference.SEED_JUMP)
        self.assertNotEqual(a['start_y'], b['start_y'])
        self.assertNotEqual(a['digest'], b['digest'])

    def test_commands_affect_real_behaviour(self):
        base = reference.simulate(20261017, 'FREE')
        aggro = reference.simulate(20261017, 'AGGRESSIVE')
        kite = reference.simulate(20261017, 'KEEP_DISTANCE')
        defend = reference.simulate(20261017, 'DEFENSIVE')
        self.assertGreater(aggro['hits'], base['hits'])
        self.assertGreater(kite['actions']['DODGE'], base['actions']['DODGE'])
        self.assertGreater(defend['actions']['GUARD'], base['actions']['GUARD'])
        self.assertNotEqual(base['digest'], aggro['digest'])
        self.assertNotEqual(base['digest'], kite['digest'])
        self.assertNotEqual(base['winner'], defend['winner'])

    def test_damage_monotonic_and_no_negative_hp(self):
        for order in reference.ORDERS:
            s = reference.simulate(42, order)
            self.assertTrue(all(hp >= 0 for hp in s['hp']))
            self.assertTrue(any(e[0] == 'WINDUP' for e in s['events']))
            self.assertTrue(any(e[0] == 'HIT' for e in s['events']))

    def test_reject_protect_ally_until_teammate_exists(self):
        with self.assertRaises(ValueError):
            reference.simulate(20261017, 'PROTECT_ALLY')
        self.assertIn('PROTECT_ALLY requires 2v2', CORE)
        self.assertIn('KEY_5: core.set_order("PROTECT_ALLY")', VISUAL)

class G30SourceContracts(unittest.TestCase):
    def test_authoritative_fixed_time_and_timeout(self):
        for snippet in ('const DT: float = 0.1', 'const MAX_TICKS: int = 600',
                        'func _resolve_hits()', '_finish("KO")',
                        '_finish("TIMEOUT_HP_RATIO")', 'func _utility(i: int)',
                        'func _decide(i: int)'):
            self.assertIn(snippet, CORE)

    def test_simultaneous_hit_snapshot(self):
        self.assertIn('var planned: Array[Dictionary]', CORE)
        self.assertIn('for hit in planned:', CORE)
        self.assertLess(CORE.index('planned.append'), CORE.index('for hit in planned:'))
        self.assertIn('int(foe["guard_until"]) >= tick_number', CORE)
        self.assertIn('"HIT', CORE)

    def test_visual_does_not_apply_damage(self):
        self.assertIn('const CombatCore = preload(', VISUAL)
        self.assertIn('core.step()', VISUAL)
        self.assertIn('Visual.direction_row(facing)', VISUAL)
        self.assertIn('get_frame_alignment(animation, anchor_row, sprite.frame)', VISUAL)
        self.assertNotIn('"hp"] =', VISUAL)
        self.assertNotIn('apply_damage', VISUAL)
        self.assertIn('Refresh speed independently of animation name', VISUAL)

    def test_new_independent_scene_does_not_replace_g2(self):
        self.assertIn('res://scripts/battle/g30_combat_lab.gd', SCENE)
        self.assertIn('res://scripts/battle/g30_combat_diagnostics.gd', SCENE)
        self.assertIn('[node name="G30CombatLab"', SCENE)
        self.assertIn('run/main_scene="res://scenes/animation_lab.tscn"',
                      (ROOT/'project.godot').read_text('utf-8'))
        for old in ('ecology_ambient_lab.tscn','ecology_animation_lab.tscn',
                    'ecology_behavior_lab.tscn','ecology_lab.tscn'):
            self.assertTrue((ROOT/'scenes'/old).is_file())

    def test_direct_launch_and_failure_logs(self):
        self.assertIn("SCENE = 'res://scenes/g30_combat_lab.tscn'", LAUNCHER)
        self.assertIn('PLW_G30_GODOT_BOOT_LAST.log', LAUNCHER)
        self.assertIn('PLW_G30_RUNTIME_LAST.log', LAUNCHER)
        self.assertIn('PLW_G30_DIRECT_DIAGNOSTICS_TO_SHARE.zip', LAUNCHER)
        self.assertIn('g30_direct_launch.py', RUNNER)
        self.assertIn('diagnostic_zip(root', LAUNCHER)

    def test_logger_decision_trace_and_terminal_digest(self):
        for snippet in ('LOGGER_READY build=', 'HEARTBEAT tick=',
                        'UNIT id=', 'BATTLE ', 'PHYSICS_FIRST_CALL',
                        'SESSION_END'):
            self.assertIn(snippet, LOGGER)
        self.assertIn('digest=', CORE)
        self.assertIn('DECISION unit=', CORE)
        self.assertIn('WHY unit=', CORE)
        self.assertIn('HIT actor=', CORE)

    def test_no_unlicensed_sprite_bundling(self):
        self.assertIn('not Pokémon sprites', LAUNCHER)
        self.assertTrue((ROOT/'.gitignore').exists())
        self.assertIn('data/raw', (ROOT/'.gitignore').read_text('utf-8'))

    def test_g30_launcher_missing_executable_still_generates_zip(self):
        import os
        import unittest.mock as mock
        path = ROOT/'tools/g30_direct_launch.py'
        spec2=importlib.util.spec_from_file_location('g30_direct_launch', path)
        mod=importlib.util.module_from_spec(spec2)
        spec2.loader.exec_module(mod)
        with tempfile.TemporaryDirectory() as td:
            root=Path(td)
            (root/'scenes').mkdir()
            (root/'scenes'/'g30_combat_lab.tscn').write_text('scene',encoding='utf-8')
            with mock.patch.object(mod,'identify_godot',return_value=None), mock.patch.object(mod,'request_godot',return_value=None):
                rc,z=mod.execute(root)
            self.assertEqual(rc,3)
            with zipfile.ZipFile(z) as arc:
                self.assertIn(mod.REPORT,arc.namelist())
                self.assertIn('no Godot executable',arc.read(mod.REPORT).decode())
                self.assertNotIn('Pokemon.png',arc.namelist())

if __name__=='__main__': unittest.main()

class G30GodotHeadlessGateContracts(unittest.TestCase):
    def test_engine_gate_is_real_godot_script(self):
        path=ROOT/'tests/g30_godot_engine_gate.gd'
        gate=path.read_text('utf-8')
        self.assertIn('extends SceneTree',gate)
        self.assertIn('res://scripts/battle/g30_combat_core.gd',gate)
        self.assertIn('func _simulate(',gate)
        self.assertIn('Core.MAX_TICKS',gate)
        self.assertIn('G30_GATE RESULT samples=',gate)
        self.assertIn('quit(0 if failures == 0 else 2)',gate)

    def test_launcher_checks_parser_before_game_launch(self):
        self.assertIn("GATE_SCRIPT = 'res://tests/g30_godot_engine_gate.gd'",LAUNCHER)
        self.assertIn('subprocess.run([str(exe), \'--headless\'',LAUNCHER)
        self.assertIn('godot_headless_gate_exit=',LAUNCHER)
        self.assertIn('G30_GATE RESULT samples=12 failures=0',LAUNCHER)
        self.assertIn('PLW_G30_GODOT_ENGINE_GATE_LAST.log',LAUNCHER)
        self.assertLess(LAUNCHER.index('runtime.unlink()'),LAUNCHER.index('subprocess.run('))
        self.assertLess(LAUNCHER.index('subprocess.run('),LAUNCHER.index('subprocess.Popen('))

    def test_gate_failure_creates_diagnostics_no_game_start(self):
        import unittest.mock as mock
        path = ROOT/'tools/g30_direct_launch.py'
        spec2=importlib.util.spec_from_file_location('g30_launcher_gate', path)
        mod=importlib.util.module_from_spec(spec2)
        spec2.loader.exec_module(mod)
        with tempfile.TemporaryDirectory() as td:
            root=Path(td); (root/'scenes').mkdir()
            (root/'scenes'/'g30_combat_lab.tscn').write_text('scene')
            fake=root/'Godot.exe';fake.write_bytes(b'not an executable')
            prior=root/'reports';prior.mkdir()
            (prior/mod.NAME).write_text('STALE RUN SHOULD NOT APPEAR')
            with mock.patch.object(mod,'identify_godot',return_value=fake), \
                 mock.patch.object(mod.subprocess,'run',return_value=mock.Mock(returncode=2)), \
                 mock.patch.object(mod.subprocess,'Popen') as popen:
                rc,zip_path=mod.execute(root)
            self.assertEqual(rc,6)
            self.assertFalse(popen.called)
            with zipfile.ZipFile(zip_path) as z:
                self.assertIn(mod.REPORT,z.namelist())
                self.assertIn(mod.GATE_LOG,z.namelist())
                self.assertNotIn(mod.NAME,z.namelist())
                self.assertIn('HEADLESS GATE FAILED',z.read(mod.REPORT).decode())
                self.assertTrue((prior/'PLW_G30_RUNTIME_PREVIOUS.log').exists())
