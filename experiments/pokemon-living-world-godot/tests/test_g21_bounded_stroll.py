"""G2.1 offline design/compatibility checks; real GDScript acceptance needs Godot F6.

The reference policy below verifies the intended deterministic bounded-walk
invariant, NOT Godot RNG equivalence or runtime rendering.
"""
from __future__ import annotations
import random
import re
import tempfile
from pathlib import Path
import unittest
import zipfile
from importlib.util import spec_from_file_location, module_from_spec

ROOT = Path(__file__).resolve().parents[1]
CODE = (ROOT / 'scripts/lab/ecology_behavior_lab.gd').read_text('utf-8')
DIAG = (ROOT / 'scripts/lab/ecology_behavior_diagnostics.gd').read_text('utf-8')
SCENE = (ROOT / 'scenes/ecology_behavior_lab.tscn').read_text('utf-8')
STABLE = (ROOT / 'scripts/lab/ecology_lab.gd').read_text('utf-8')


class G21SourceContracts(unittest.TestCase):
    def test_new_scene_is_isolated(self):
        self.assertIn('res://scripts/lab/ecology_behavior_lab.gd', SCENE)
        self.assertIn('res://scripts/lab/ecology_behavior_diagnostics.gd', SCENE)
        self.assertEqual(STABLE.count('G2.0.2 自主生態＋執行LOG'), 1)
        self.assertIn('run/main_scene="res://scenes/animation_lab.tscn"', (ROOT/'project.godot').read_text('utf-8'))

    def test_bounded_natural_stroll_for_snorlax(self):
        self.assertIn('SLOW_STROLL_DEADLINE: float = 18.0', CODE)
        self.assertIn('state in ["IDLE", "REST", "OBSERVE"]', CODE)
        self.assertIn('float(entry["time_since_roam"]) >= float(entry["profile"]["stroll_deadline"])', CODE)
        self.assertIn('_begin_roam(i, "bounded wake-up: short leisurely stroll")', CODE)
        self.assertIn('"stroll_deadline": SLOW_STROLL_DEADLINE', CODE)
        self.assertIn('entry["time_since_roam"] = float(entry["time_since_roam"]) + dt', CODE)

    def test_roam_reset_on_actual_new_trip_only(self):
        self.assertEqual(CODE.count('entry["time_since_roam"] = 0.0'), 1)
        self.assertIn('entry["roam_count"] = int(entry["roam_count"]) + 1', CODE)
        self.assertIn('"roam_count": 0', CODE)
        self.assertIn('"time_since_roam": 0.0', CODE)

    def test_movement_vector_is_observed_not_assumed_direction(self):
        self.assertIn('entry["heading"] = travel.normalized()', CODE)
        self.assertIn('travel.length_squared() > 0.0001', CODE)
        self.assertIn('draw_line(center, tip, arrow_color', CODE)
        self.assertIn('DO NOT assign speculative PMD facing', CODE)
        self.assertIn('get_frame_alignment(motion, 0, sprite.frame)', CODE)
        self.assertNotIn('sprite.flip_h', CODE)
        self.assertNotIn('"Attack"', CODE)

    def test_existing_profiles_still_distinct(self):
        for tag in ('CURIOUS', 'PROWL', 'ANCHOR'):
            self.assertIn(tag, CODE)
        for token in ('"speed": 50.0', '"speed": 35.0', '"speed": 16.0', '"roam": 0.13'):
            self.assertIn(token, CODE)

    def test_g21_logger_separate_and_verifiable(self):
        self.assertIn('const LOG_NAME: String = "PLW_G21_RUNTIME_LAST.log"', DIAG)
        self.assertIn('G2.1-v0.4.0', DIAG)
        self.assertIn('HEARTBEAT tick=', DIAG)
        self.assertIn('LOGGER_READY', DIAG)
        self.assertIn('KEYBOARD keycode=', DIAG)
        self.assertIn('roams=%s since_roam=%s', DIAG)
        self.assertNotIn('PLW_G2_RUNTIME_LAST.log', DIAG)

    def test_keyboard_controls_preserved(self):
        for name in ('KEY_3:', 'KEY_M:', 'KEY_D:', 'KEY_N:', 'KEY_R:', 'KEY_SPACE:'):
            self.assertIn(name, CODE)
        self.assertIn('_begin_roam(focus, "MANUAL DIAGNOSTIC: force new target")', CODE)

    def test_prior_scene_files_still_present(self):
        for scene in ('animation_lab.tscn', 'roster_lab.tscn', 'calibration_lab.tscn', 'ecology_lab.tscn'):
            self.assertTrue((ROOT/'scenes'/scene).exists())

    def test_pure_python_bounded_reference(self):
        deadline=18.0
        for seed in (0,1,20261017,20365746,9999):
            rng = random.Random(seed)
            time_since=0.0
            state='REST'
            walked=False
            # Adversarial model always chooses more rest / observation,
            # so the watchdog must guarantee an eventual ROAM.
            for tick in range(1,220):
                time_since+=0.1
                if time_since>=deadline and state in ('REST','OBSERVE','IDLE'):
                    state='ROAM'; time_since=0.0; walked=True; break
                state=rng.choice(('REST','OBSERVE','IDLE'))
            self.assertTrue(walked, f'seed {seed} failed to roam')
            self.assertLessEqual(tick, 181)

    def test_g21_log_collector_only_zips_text(self):
        module_path=ROOT/'tools/g21_collect_logs.py'
        spec=spec_from_file_location('g21_collect_logs', module_path)
        module=module_from_spec(spec)
        spec.loader.exec_module(module)
        with tempfile.TemporaryDirectory() as tmp:
            base=Path(tmp)
            reports=base/'reports'; reports.mkdir()
            (reports/'PLW_G21_RUNTIME_LAST.log').write_text('LOGGER_READY\nHEARTBEAT tick=1\n',encoding='utf-8')
            (reports/'COPYRIGHTED.png').write_bytes(b'not art')
            result=module.collect(base)
            with zipfile.ZipFile(result) as arc:
                self.assertEqual(set(arc.namelist()), {'PLW_G21_RUNTIME_LAST.log','HOW_TO_READ.txt'})
                self.assertIn('HEARTBEAT', arc.read('PLW_G21_RUNTIME_LAST.log').decode())

if __name__ == '__main__': unittest.main()
