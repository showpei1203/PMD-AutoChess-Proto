"""G2.2.2 offline regression for old scene and missing-log diagnostics."""
from pathlib import Path
import tempfile
import unittest
import zipfile
from importlib.util import spec_from_file_location, module_from_spec

ROOT = Path(__file__).resolve().parents[1]
source = ROOT/'tools/g22_collect_logs.py'
spec = spec_from_file_location('g22_collect_missing', source)
module = module_from_spec(spec)
spec.loader.exec_module(module)


class G222MissingLogTest(unittest.TestCase):
    def test_no_g22_log_creates_zip(self):
        with tempfile.TemporaryDirectory() as tmp:
            target = module.collect(Path(tmp))
            self.assertTrue(target.exists())
            with zipfile.ZipFile(target) as z:
                self.assertEqual(set(z.namelist()), {module.DIAG_NAME, 'HOW_TO_READ.txt'})
                report = z.read(module.DIAG_NAME).decode('utf-8')
                self.assertIn('DOUBLE-CLICK', report)
                self.assertIn('EcologyAnimationLab', report)
                self.assertIn('F6, NOT F5', report)

    def test_g21_log_is_detected_not_reused(self):
        with tempfile.TemporaryDirectory() as tmp:
            reports = Path(tmp)/'reports'
            reports.mkdir()
            old = '[123ms] LOGGER_READY build=G2.1-v0.4.0 scene=res://scenes/ecology_behavior_lab.tscn\n'
            (reports/'PLW_G21_RUNTIME_LAST.log').write_text(old, encoding='utf-8')
            with zipfile.ZipFile(module.collect(Path(tmp))) as z:
                report = z.read(module.DIAG_NAME).decode('utf-8')
                self.assertIn('G2.1-v0.4.0', report)
                self.assertIn('Old logs do not establish', report)
                self.assertNotIn('PLW_G21_RUNTIME_LAST.log', z.namelist())

    def test_real_g22_log_remains_two_file_zip(self):
        with tempfile.TemporaryDirectory() as tmp:
            reports = Path(tmp)/'reports'
            reports.mkdir()
            text = '[5ms] LOGGER_READY build=G2.2-v0.4.1.1 scene=res://scenes/ecology_animation_lab.tscn\n'
            (reports/module.NAME).write_text(text, encoding='utf-8')
            with zipfile.ZipFile(module.collect(Path(tmp))) as z:
                self.assertEqual(set(z.namelist()), {module.NAME, 'HOW_TO_READ.txt'})
                self.assertEqual(z.read(module.NAME).decode('utf-8'), text)

    def test_no_sprite_art_included(self):
        with tempfile.TemporaryDirectory() as tmp:
            reports = Path(tmp)/'reports'
            reports.mkdir()
            (reports/'Pokemon.png').write_bytes(b'fake')
            with zipfile.ZipFile(module.collect(Path(tmp))) as z:
                self.assertFalse(any(name.endswith('.png') for name in z.namelist()))


if __name__ == '__main__':
    unittest.main()
