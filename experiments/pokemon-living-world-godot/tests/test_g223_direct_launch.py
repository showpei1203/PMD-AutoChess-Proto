"""G2.2.3 direct-launch evidence tests. No Godot executable required here."""
from __future__ import annotations
from importlib.util import spec_from_file_location, module_from_spec
from pathlib import Path
import tempfile
import unittest
import zipfile
import os

BASE = Path(__file__).resolve().parents[1]
spec = spec_from_file_location('g22_direct', BASE/'tools/g22_direct_launch.py')
mod = module_from_spec(spec)
spec.loader.exec_module(mod)


class TestDirectG22Launcher(unittest.TestCase):
    def test_scene_identifier_and_windows_bat(self):
        self.assertEqual(mod.SCENE, 'res://scenes/ecology_animation_lab.tscn')
        bat=(BASE/'RUN_G22_DIRECT_SCENE_WINDOWS.bat').read_text(encoding='utf-8')
        self.assertIn('g22_direct_launch.py', bat)
        self.assertNotIn('F6 to run', bat)

    def test_scene_missing_still_bundles_diagnostics(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp)
            rc,zpath=mod.execute(root, '')
            self.assertEqual(rc,2)
            with zipfile.ZipFile(zpath) as z:
                self.assertIn(mod.REPORT,z.namelist())
                self.assertIn('scene file missing',z.read(mod.REPORT).decode())

    def test_missing_executable_still_bundles_diagnostics(self):
        from unittest.mock import patch
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);(root/'scenes').mkdir()
            (root/'scenes/ecology_animation_lab.tscn').write_text('[gd_scene]')
            with patch.object(mod,'identify_godot',return_value=None), patch.object(mod,'request_godot',return_value=None):
                rc,zpath=mod.execute(root,'')
            self.assertEqual(rc,3)
            with zipfile.ZipFile(zpath) as z:
                self.assertIn('no Godot executable',z.read(mod.REPORT).decode())

    @unittest.skipIf(os.name == 'nt', 'Mock Unix script only')
    def test_injected_fake_godot_launch_writes_real_capture(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);(root/'scenes').mkdir()
            (root/'scenes/ecology_animation_lab.tscn').write_text('[gd_scene]')
            exe=root/'fakegodot.sh'
            exe.write_text('#!/bin/sh\necho GODOT_FAKE_PARSE_ERROR\nexit 6\n')
            exe.chmod(0o755)
            rc,zpath=mod.execute(root,str(exe))
            self.assertEqual(rc,5)
            with zipfile.ZipFile(zpath) as z:
                self.assertIn(mod.CONSOLE,z.namelist())
                self.assertIn('GODOT_FAKE_PARSE_ERROR',z.read(mod.CONSOLE).decode())
                self.assertIn('g22_runtime_log_created=False',z.read(mod.REPORT).decode())

    def test_no_art_in_bundle_even_if_present(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);r=root/'reports';r.mkdir()
            (r/'Pokemon.png').write_bytes(b'private')
            zpath=mod.diagnostic_zip(root, 'Test')
            with zipfile.ZipFile(zpath) as z:
                self.assertFalse(any(s.endswith('.png') for s in z.namelist()))

if __name__ == '__main__':unittest.main()
