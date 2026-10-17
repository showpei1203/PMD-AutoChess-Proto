"""Large-frames, floating poses, PMD native center and fallback regression."""
from pathlib import Path
import sys
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from pmd_anchor_reference import detect_alpha_bounds, detect_shadow_center, find_reference, godot_position

ROOT = Path(__file__).resolve().parents[1]
CLEAR = (0,0,0,0)
INK = (20,80,220,255)
WHITE = (255,255,255,255)
RED = (255,0,0,255)
GREEN = (0,255,0,255)
BLUE = (0,0,255,255)

def grid(w,h):return [[CLEAR for _ in range(w)] for _ in range(h)]

class GroundAnchorReference(unittest.TestCase):
    def test_alpha_ignore_transparent_tail(self):
        img = grid(80,120)
        for y in range(18,51):
            for x in range(12,69): img[y][x]=INK
        self.assertEqual(detect_alpha_bounds(img), (12,18,57,33))
        self.assertEqual(find_reference(img).point,(40,51.0))

    def test_native_shadow_overrides_ink_bottom_for_hovering(self):
        sprite = grid(80,120); shadow=grid(80,120)
        sprite[18][15]=INK; sprite[51][52]=INK
        shadow[105][39]=WHITE
        marker=find_reference(sprite,shadow)
        self.assertEqual(marker.source,'PMD_SHADOW_CENTER')
        self.assertEqual(marker.point,(39.5,105.5))
        self.assertNotEqual(marker.point[1],find_reference(sprite).point[1])

    def test_animation_can_jump_without_shifting_ground(self):
        baseline=grid(80,120); leap=grid(80,120); shadow=grid(80,120)
        baseline[62][32]=INK; leap[19][32]=INK; shadow[105][39]=WHITE
        a=find_reference(baseline,shadow).point
        b=find_reference(leap,shadow).point
        self.assertEqual(a,b)
        self.assertLess(find_reference(leap).point[1],find_reference(baseline).point[1])

    def test_rbg_shadow_size_channels_are_not_white(self):
        shadow=grid(16,16);shadow[4][4]=RED;shadow[5][5]=GREEN;shadow[6][6]=BLUE
        self.assertIsNone(detect_shadow_center(shadow))

    def test_invalid_white_flood_falls_back(self):
        sprite=grid(20,20);sprite[9][9]=INK
        shadow=grid(20,20)
        for y in range(5):
            for x in range(5):shadow[y][x]=WHITE
        self.assertEqual(find_reference(sprite,shadow).source,'ALPHA_BOTTOM_FALLBACK')

    def test_empty_visible_sprite(self):
        self.assertEqual(find_reference(grid(24,80)).point,(12,80.0))

    def test_centered_texture_anchor_formula(self):
        p=godot_position((480,350),(80,120),(40,51),2)
        self.assertEqual(p,(480,368))
        self.assertEqual(p[1]+(51-60)*2,350)

    def test_source_native_priority_and_cache(self):
        src=(ROOT/'scripts/lab/pmd_sprite_source.gd').read_text('utf-8')
        self.assertIn('sheet + "-Shadow.png"',src)
        self.assertIn('"PMD_SHADOW_CENTER"',src)
        self.assertIn('"ALPHA_BOTTOM_FALLBACK"',src)
        self.assertIn('anchor_cache[key] = result',src)
        self.assertIn('"ink_bounds"',src)

    def test_calibration_modes_preserve_manual_option(self):
        s=(ROOT/'scripts/lab/calibration_lab.gd').read_text('utf-8')
        self.assertIn('KEY_N: anchor_mode = (anchor_mode + 1) % 3',s)
        self.assertIn('KEY_G: _load(130)',s)
        self.assertIn('"anchor_mode": anchor_mode',s)
        self.assertIn('(frame * 0.5 - point) * visual_scale',s)
        self.assertNotIn('frame_height * visual_scale * 0.5',s)

    def test_accepted_scenes_not_modified_by_new_lab(self):
        for p in ['scenes/animation_lab.tscn','scenes/roster_lab.tscn']:
            self.assertTrue((ROOT/p).exists())
        self.assertIn('run/main_scene="res://scenes/animation_lab.tscn"',(ROOT/'project.godot').read_text('utf-8'))

if __name__=='__main__':unittest.main()
