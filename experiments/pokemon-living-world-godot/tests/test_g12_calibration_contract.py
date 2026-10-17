"""Offline source contracts. They do not constitute a Godot 4.7 runtime pass."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
SCRIPT=(ROOT/'scripts/lab/calibration_lab.gd').read_text('utf-8')
SCENE=(ROOT/'scenes/calibration_lab.tscn').read_text('utf-8')

class CalibrationContracts(unittest.TestCase):
    def test_standalone_scene(self):
        self.assertIn('res://scripts/lab/calibration_lab.gd',SCENE)
        self.assertEqual((ROOT/'project.godot').read_text('utf-8').count('run/main_scene="res://scenes/animation_lab.tscn"'),1)
    def test_lazy_single_species(self):
        self.assertIn('source.load_species(species_id)',SCRIPT)
        self.assertIn('sprite.sprite_frames = null',SCRIPT)
        self.assertIn('frames_for_row.clear()',SCRIPT)
        self.assertIn('var species_id: int = 25',SCRIPT)
    def test_animations_source(self):
        self.assertIn('source.make_frames(direction_row, ACTIONS)',SCRIPT)
        self.assertIn('sprite.sprite_frames.get_frame_texture(sprite.animation, safe_frame)',SCRIPT)
        self.assertIn('frame_height * visual_scale * 0.5',SCRIPT)
    def test_manual_controls(self):
        for token in ('KEY_Q','KEY_E','KEY_Z','KEY_X','KEY_UP','KEY_DOWN','KEY_J','KEY_L','KEY_B','KEY_R','KEY_S'):
            with self.subTest(token=token): self.assertIn(token,SCRIPT)
    def test_no_false_verified_direction(self):
        self.assertIn('"direction_mapping_verified": false',SCRIPT)
        self.assertIn('"accepted_as_physical_collisions": false',SCRIPT)
        self.assertIn('"shadow_kind": "debug_ellipse_only"',SCRIPT)
    def test_non_art_local_output(self):
        self.assertIn('user://plw_g12_%04d.json',SCRIPT)
        self.assertNotIn('FileAccess.open("res://data/raw',SCRIPT)
        self.assertIn('JSON.stringify(payload',SCRIPT)
    def test_existing_scenes_present(self):
        self.assertTrue((ROOT/'scenes/animation_lab.tscn').is_file())
        self.assertTrue((ROOT/'scenes/roster_lab.tscn').is_file())

if __name__=='__main__':unittest.main()
