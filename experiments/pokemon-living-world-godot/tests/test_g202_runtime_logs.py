"""G2.0.2 source-contract and local log packaging checks.
Godot 4.7.2 runtime still must be verified on Surface.
"""
from pathlib import Path
import tempfile
import unittest
import zipfile
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from g2_collect_logs import collect, NAME

SCRIPT = (ROOT / 'scripts/lab/ecology_diagnostics.gd').read_text('utf-8')
AI = (ROOT / 'scripts/lab/ecology_lab.gd').read_text('utf-8')
SCENE = (ROOT / 'scenes/ecology_lab.tscn').read_text('utf-8')

class EcologyRuntimeLogContracts(unittest.TestCase):
    def test_debugger_is_independent_scene_child(self):
        self.assertIn('type="CanvasLayer" parent="."', SCENE)
        self.assertIn('res://scripts/lab/ecology_diagnostics.gd', SCENE)
        self.assertIn('PROCESS_MODE_ALWAYS', SCRIPT)

    def test_log_path_known_and_persistent(self):
        self.assertIn('PLW_G2_RUNTIME_LAST.log', SCRIPT)
        self.assertIn('res://reports', SCRIPT)
        self.assertIn('FileAccess.open(log_path, FileAccess.WRITE)', SCRIPT)
        self.assertIn('log_file.flush()', SCRIPT)
        self.assertIn('user://', SCRIPT)

    def test_heartbeat_differentiates_render_physics_ai(self):
        for token in ('HEARTBEAT tick=', 'visual_frames', 'physics_callbacks',
                      'tree_paused=', 'root_physics=', 'engine_frames=', 'AGENT #%03d'):
            with self.subTest(token=token):
                self.assertIn(token, SCRIPT)

    def test_keyboard_and_click_diagnostics(self):
        self.assertIn('KEYBOARD keycode=', SCRIPT)
        self.assertIn('BUTTON M press;', SCRIPT)
        self.assertIn('BUTTON D next_debug=', SCRIPT)
        self.assertIn('BUTTON N seed=', SCRIPT)
        self.assertIn('func _input(event: InputEvent)', AI)
        self.assertNotIn('func _unhandled_key_input(', AI)

    def test_approved_existing_scenes_unmodified(self):
        config = (ROOT/'project.godot').read_text('utf-8')
        self.assertIn('run/main_scene="res://scenes/animation_lab.tscn"', config)
        self.assertTrue((ROOT/'scenes/roster_lab.tscn').is_file())
        self.assertTrue((ROOT/'scenes/calibration_lab.tscn').is_file())

    def test_log_bundle_contains_only_text(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp)
            (root/'reports').mkdir()
            (root/'reports'/NAME).write_text('SESSION_START\nHEARTBEAT tick=0\n',encoding='utf8')
            dest=collect(root)
            with zipfile.ZipFile(dest) as z:
                self.assertEqual(sorted(z.namelist()), ['HOW_TO_READ.txt',NAME])
                self.assertIn('tick=0', z.read(NAME).decode())

    def test_missing_log_returns_clear_error(self):
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaisesRegex(FileNotFoundError, 'No G2 runtime log'):
                collect(Path(tmp))

if __name__ == '__main__':
    unittest.main()

