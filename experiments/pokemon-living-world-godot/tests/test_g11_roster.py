"""G1.1 planning/test tools are offline; NOT Godot binary execution."""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from pmd_roster_report import roster_page, report_rows


class TestRosterPaging(unittest.TestCase):
    def test_first_page(self):
        self.assertEqual(roster_page(0), [1, 2, 3])

    def test_middle_page(self):
        self.assertEqual(roster_page(31), [94, 95, 96])

    def test_last_page_has_one_slot(self):
        self.assertEqual(roster_page(50), [151])

    def test_out_of_range_rejected(self):
        for i in (-1, 51):
            with self.assertRaises(ValueError):
                roster_page(i)

    def test_row_mapping_includes_alias(self):
        rows = report_rows([{
            'species': 148, 'status': 'PASS', 'credits': True, 'issues': [],
            'animations': {
                'Idle': {'status': 'READY', 'source_action': 'Walk', 'alias': True},
                'Walk': {'status': 'READY', 'source_action': 'Walk', 'alias': False},
                'Attack': {'status': 'READY', 'source_action': 'Attack', 'alias': False},
            },
        }])
        self.assertEqual(rows[0]['dex'], '148')
        self.assertEqual(rows[0]['idle_from'], 'Walk')
        self.assertTrue(rows[0]['credits_available'])

    def test_failure_reasons_kept(self):
        rows = report_rows([{'species': 20, 'status': 'FAIL', 'credits': False,
                             'issues': ['missing XML'], 'animations': {}}])
        self.assertEqual(rows[0]['idle'], 'UNVALIDATED')
        self.assertEqual(rows[0]['issues'], 'missing XML')


class TestGodotGallerySource(unittest.TestCase):
    def test_separate_scene_no_main_scene_regression(self):
        original = (ROOT / 'project.godot').read_text(encoding='utf-8')
        self.assertIn('run/main_scene="res://scenes/animation_lab.tscn"', original)
        gallery_scene = (ROOT / 'scenes/roster_lab.tscn').read_text(encoding='utf-8')
        self.assertIn('res://scripts/lab/roster_lab.gd', gallery_scene)

    def test_lazily_loads_three_slots(self):
        code = (ROOT / 'scripts/lab/roster_lab.gd').read_text(encoding='utf-8')
        self.assertIn('const PAGE_SIZE: int = 3', code)
        self.assertIn('const TOTAL_SPECIES: int = 151', code)
        self.assertIn('page_index * PAGE_SIZE + i + 1', code)
        self.assertIn('slot["cache"] = {}', code)
        self.assertIn('_load_slot(i, SHOWCASE_IDS[i])', code)
        self.assertNotIn('for i in range(TOTAL_SPECIES)', code)

    def test_g11_uses_G1_approved_source_not_new_parser(self):
        code = (ROOT / 'scripts/lab/roster_lab.gd').read_text(encoding='utf-8')
        self.assertIn('const Source = preload("res://scripts/lab/pmd_sprite_source.gd")', code)
        self.assertIn('source.make_frames(row, ACTIONS)', code)
        self.assertIn('source.load_species(species_id)', code)
        self.assertIn('KEY_E, KEY_PAGEDOWN', code)
        self.assertIn('KEY_T: _show_benchmark()', code)


if __name__ == '__main__':
    unittest.main()
