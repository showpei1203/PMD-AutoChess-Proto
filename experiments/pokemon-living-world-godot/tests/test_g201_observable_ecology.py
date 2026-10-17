"""G2.0.1 source invariants; Godot 4.7.2 runtime remains Surface acceptance."""
import re
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
CODE=(ROOT/'scripts/lab/ecology_lab.gd').read_text(encoding='utf-8')


class EcologyObservabilityContracts(unittest.TestCase):
    def test_d_enables_overlay_on_first_press(self):
        self.assertIn('var show_debug: bool = false',CODE)
        self.assertIn('KEY_D:',CODE)
        self.assertIn('show_debug = not show_debug',CODE)
        self.assertIn('"ON" if show_debug else "OFF"',CODE)

    def test_motion_target_visible_and_force_key(self):
        self.assertIn('KEY_M:',CODE)
        self.assertIn('_begin_roam(focus, "MANUAL DIAGNOSTIC: force new target")',CODE)
        self.assertIn('draw_line(center, target',CODE)
        self.assertIn('debug_panel.visible = show_debug',CODE)

    def test_tick_and_distance_probes(self):
        self.assertIn('"distance_moved": 0.0',CODE)
        self.assertIn('pos.distance_to(next_position)',CODE)
        self.assertIn('tick %d',CODE)
        self.assertIn('distance_moved',CODE)

    def test_n_initial_target_differs_by_seed(self):
        self.assertIn('KEY_N: _reset_simulation(seed + SEED_JUMP)',CODE)
        self.assertIn('rng.seed = seed + id * 1009',CODE)
        self.assertIn('_begin_roam(index, "spawn: curious scout")',CODE)
        self.assertIn('KEY_R: _reset_simulation(seed)',CODE)

    def test_roles_not_all_idling_at_spawn(self):
        for token in ('_begin_roam(index, "spawn: curious scout")',
                      '_set_state(index, "OBSERVE", "spawn: survey territory")',
                      '_set_state(index, "REST", "spawn: conserve energy")'):
            self.assertIn(token,CODE)
        self.assertIn('_begin_roam(i, "prowl: scouting after survey")',CODE)

    def test_legacy_scenes_unchanged(self):
        for f in ('animation_lab.tscn','roster_lab.tscn','calibration_lab.tscn'):
            self.assertTrue((ROOT/'scenes'/f).exists())
        self.assertIn('run/main_scene="res://scenes/animation_lab.tscn"',
                      (ROOT/'project.godot').read_text(encoding='utf-8'))

    def test_no_combat_ai_claim(self):
        self.assertNotIn('"Attack"',CODE)
        self.assertIn('無攻擊 AI',CODE)

    def test_trace_prefix_for_decisions(self):
        self.assertIn('[PLW-G2] reset seed=',CODE)
        self.assertIn('[PLW-G2] #%03d -> %s',CODE)


if __name__=='__main__': unittest.main()
