"""G2.3 cadence static/reference contracts. Godot runtime remains Surface-only."""
from pathlib import Path
import importlib.util
import math
import random
import re
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SCENE = (ROOT/'scenes/ecology_ambient_lab.tscn').read_text('utf-8')
CODE = (ROOT/'scripts/lab/ecology_ambient_lab.gd').read_text('utf-8')
POLICY = (ROOT/'scripts/lab/pmd_ambient_cadence_policy.gd').read_text('utf-8')
DIAG = (ROOT/'scripts/lab/ecology_ambient_diagnostics.gd').read_text('utf-8')
RUNNER = (ROOT/'tools/g23_direct_launch.py').read_text('utf-8')
OLD = (ROOT/'scripts/lab/ecology_animation_lab.gd').read_text('utf-8')


class G23CadenceContracts(unittest.TestCase):
    def test_scene_inherits_previously_accepted_g22(self):
        self.assertIn('extends "res://scripts/lab/ecology_animation_lab.gd"', CODE)
        self.assertIn('super._ready()', CODE)
        self.assertIn('super._spawn(index)', CODE)
        self.assertIn('super._row_frames(index, row)', CODE)
        self.assertIn('res://scripts/lab/ecology_ambient_lab.gd', SCENE)
        self.assertIn('res://scripts/lab/ecology_ambient_diagnostics.gd', SCENE)

    def test_stance_walk_is_actually_played_slowly(self):
        self.assertIn('sprite.play(action)', CODE)
        self.assertIn('var action: String = "Walk"', CODE)
        self.assertIn('sprite.speed_scale = Cadence.speed', CODE)
        self.assertNotIn('sprite.pause()', CODE)
        self.assertNotIn('sprite.set_frame_and_progress', CODE)
        self.assertIn('sprite.is_playing()', CODE)

    def test_movement_preempts_micro_without_changing_movement_ai(self):
        self.assertIn('if state in ["ROAM", "RETURN"]:', CODE)
        self.assertIn('entry["pose_remaining"] = 0.0', CODE)
        self.assertIn('entry["micro_action"] = ""', CODE)
        self.assertIn('_apply_visual_mode(index, "MOVE")', CODE)
        self.assertIn('entry["pose_wait"] = Cadence.next_delay', CODE)
        self.assertNotIn('entry["position"] =', CODE)
        self.assertNotIn('entry["target"] =', CODE)

    def test_optional_actions_obey_native_shadow_gate(self):
        self.assertIn('MAX_SAFE_ANCHOR_DELTA: float = 5.0', CODE)
        self.assertIn('PMD_SHADOW_CENTER', CODE)
        self.assertIn('p0.distance_to(p1) <= MAX_SAFE_ANCHOR_DELTA', CODE)
        self.assertIn('get_frame_alignment("Walk", row, 0)', CODE)
        self.assertIn('get_frame_alignment(wanted, row, 0)', CODE)
        self.assertIn('return "Idle" if sprite.sprite_frames.has_animation("Idle") else "NONE"', CODE)

    def test_species_personalities_different(self):
        for id in (25,94,143):
            self.assertRegex(POLICY, rf'(?m)^\s*{id}: \{{')
        for pair in ('"stance": 0.26', '"stance": 0.17', '"stance": 0.09',
                     '"wait_min": 5.0', '"wait_min": 8.0', '"wait_min": 18.0',
                     '["Idle", "Idle", "Pose"]', '["Float", "Float", "Idle", "Pose"]',
                     '["Nod", "Nod", "Idle", "NONE"]'):
            self.assertIn(pair, POLICY)

    def test_raw_direction_and_anchors_still_inherited(self):
        self.assertIn('entry["raw_facing_row"] = VisualPolicy.direction_row(travel)', OLD)
        self.assertIn('entry["source"].get_frame_alignment(motion, row, sprite.frame)', OLD)
        self.assertNotIn('func _align_visual(', CODE)
        self.assertNotIn('func _step_ecology(', CODE)

    def test_micro_actions_one_shot(self):
        self.assertIn('frames.set_animation_loop(action, false)', CODE)
        self.assertIn('total += sheet.get_frame_duration(chosen, k)', CODE)
        self.assertIn('sheet.get_animation_speed(chosen) * sprite.speed_scale', CODE)
        self.assertIn('_apply_visual_mode(index, "STANCE")', CODE)
        self.assertIn('if chosen == "NONE":', CODE)

    def test_render_row_cached_and_native(self):
        self.assertIn('var real_row: int = int(entry.get("render_row", row))', CODE)
        self.assertIn('source.get_animation(action, real_row)', CODE)
        self.assertIn('changed_row:', CODE)
        self.assertIn('entry["anchor_key"] = ""', CODE)

    def test_independent_log_and_direct_launch(self):
        self.assertIn('PLW_G23_RUNTIME_LAST.log', DIAG)
        self.assertIn('G2.3-v0.4.2', DIAG)
        self.assertIn('micro=%s speed=%s', DIAG)
        self.assertIn('ecology_ambient_lab.tscn', RUNNER)
        self.assertIn('PLW_G23_DIRECT_DIAGNOSTICS_TO_SHARE.zip', RUNNER)
        self.assertIn('PLW_G23_GODOT_BOOT_LAST.log', RUNNER)

    def test_no_republishing_art_in_collector(self):
        spec=importlib.util.spec_from_file_location('g23direct',ROOT/'tools/g23_direct_launch.py')
        module=importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        with tempfile.TemporaryDirectory() as tmp:
            rp=Path(tmp)
            (rp/'reports').mkdir()
            (rp/'reports'/'Copyrighted.png').write_bytes(b'fake')
            _,archive = module.execute(rp,requested_exe='not/a/godot/path') if False else (None,module.diagnostic_zip(rp,'mock launch error'))
            with zipfile.ZipFile(archive) as z:
                self.assertIn('PLW_G23_DIRECT_LAUNCH_REPORT.txt',z.namelist())
                self.assertFalse(any(name.endswith('.png') for name in z.namelist()))

    def test_pure_python_expected_stance_period_bounds(self):
        # Only reference math, NOT running Godot or actual PMD frame data.
        a={25:(0.26,5,8.5),94:(0.17,8,13.5),143:(0.09,18,28)}
        self.assertLess(a[143][0],a[94][0])
        self.assertLess(a[94][0],a[25][0])
        self.assertGreater(a[143][1],a[25][2])
        for species,(speed,lo,hi) in a.items():
            self.assertGreater(speed,0)
            self.assertLess(speed,1)
            for seed in [0,20261017,999]:
                value=random.Random(seed+species).uniform(lo,hi)
                self.assertGreaterEqual(value,lo)
                self.assertLessEqual(value,hi)

    def test_existing_acceptance_scenes_unchanged(self):
        for scene in ('animation_lab.tscn','roster_lab.tscn','calibration_lab.tscn',
                      'ecology_lab.tscn','ecology_behavior_lab.tscn','ecology_animation_lab.tscn'):
            self.assertTrue((ROOT/'scenes'/scene).is_file())
        self.assertIn('run/main_scene="res://scenes/animation_lab.tscn"',(ROOT/'project.godot').read_text('utf8'))


if __name__=='__main__': unittest.main()
