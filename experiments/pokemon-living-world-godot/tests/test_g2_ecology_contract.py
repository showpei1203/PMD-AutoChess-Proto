"""G2 static/scope contracts. The real Godot 4.7.2 run must be verified on Surface."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
SCRIPT=(ROOT/'scripts/lab/ecology_lab.gd').read_text('utf-8')

class EcologyContracts(unittest.TestCase):
    def test_isolated_scene_and_preserved_main(self):
        self.assertIn('res://scripts/lab/ecology_lab.gd',(ROOT/'scenes/ecology_lab.tscn').read_text('utf-8'))
        self.assertIn('run/main_scene="res://scenes/animation_lab.tscn"',(ROOT/'project.godot').read_text('utf-8'))
    def test_three_species(self):
        self.assertIn('const IDS = [25, 94, 143]',SCRIPT)
        for label in ('CURIOUS','PROWL','ANCHOR'):
            self.assertIn(label,SCRIPT)
    def test_ecology_states(self):
        for state in ['IDLE','ROAM','OBSERVE','RETURN','REST']:
            self.assertIn('"'+state+'"',SCRIPT)
        self.assertIn('func _step_ecology(dt: float) -> void:',SCRIPT)
    def test_bounded_decision_work(self):
        self.assertIn('MAX_STEPS_PER_TICK: int = 4',SCRIPT)
        self.assertIn('clock_accum = 0.0 # bounded catch-up',SCRIPT)
    def test_rng_deterministic_and_reseedable(self):
        self.assertIn('rng.seed = seed + id * 1009',SCRIPT)
        self.assertIn('KEY_R: _reset_simulation(seed)',SCRIPT)
        self.assertIn('KEY_N: _reset_simulation(seed + SEED_JUMP)',SCRIPT)
    def test_perception_uses_snapshot(self):
        self.assertIn('var snapshots: Array[Vector2] = []',SCRIPT)
        self.assertIn('snapshots[i].distance_to(snapshots[j])',SCRIPT)
    def test_native_shadow_anchor_not_frame_bottom(self):
        self.assertIn('get_frame_alignment(motion, 0, sprite.frame)',SCRIPT)
        self.assertIn('align.get("ground_point"',SCRIPT)
        self.assertNotIn('frame_height * scale',SCRIPT)
    def test_no_battle_claim(self):
        self.assertNotIn('"Attack"',SCRIPT)
        self.assertIn('無攻擊 AI',SCRIPT)
    def test_controls_and_local_art(self):
        for k in ('KEY_SPACE','KEY_R','KEY_N','KEY_1','KEY_2','KEY_3','KEY_D'):
            self.assertIn(k,SCRIPT)
        self.assertIn('res://scripts/lab/pmd_sprite_source.gd',SCRIPT)

if __name__=='__main__': unittest.main()
