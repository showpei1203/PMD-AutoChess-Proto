"""G2.2 source + math reference checks. Godot runtime remains Surface-only."""
from __future__ import annotations
import math
import random
import tempfile
import unittest
from pathlib import Path
from importlib.util import module_from_spec,spec_from_file_location
from zipfile import ZipFile

ROOT=Path(__file__).resolve().parents[1]
SCENE=(ROOT/'scenes/ecology_animation_lab.tscn').read_text('utf8')
CODE=(ROOT/'scripts/lab/ecology_animation_lab.gd').read_text('utf8')
POLICY=(ROOT/'scripts/lab/pmd_visual_policy.gd').read_text('utf8')
DIAG=(ROOT/'scripts/lab/ecology_animation_diagnostics.gd').read_text('utf8')

class G22SourceContracts(unittest.TestCase):
 def test_standalone_scene_and_g21_is_unchanged(self):
  self.assertIn('res://scripts/lab/ecology_animation_lab.gd',SCENE)
  self.assertIn('res://scripts/lab/ecology_animation_diagnostics.gd',SCENE)
  self.assertIn('run/main_scene="res://scenes/animation_lab.tscn"',(ROOT/'project.godot').read_text('utf8'))
  self.assertIn('SLOW_STROLL_DEADLINE: float = 18.0',(ROOT/'scripts/lab/ecology_behavior_lab.gd').read_text('utf8'))
 def test_walk_as_stationary_pose_not_infinite_walk(self):
  self.assertIn('sprite.play("Walk")',CODE)
  self.assertIn('sprite.set_frame_and_progress(0, 0.0)',CODE)
  self.assertIn('sprite.pause()',CODE)
  self.assertIn('mode == "STANCE"',CODE)
 def test_idle_is_optional_one_shot_and_cooldown(self):
  self.assertIn('data.set_animation_loop("Idle", false)',CODE)
  self.assertIn('entry["pose_wait"] = VisualPolicy.next_pose_delay',CODE)
  self.assertIn('get_frame_duration("Idle", k)',CODE)
  self.assertIn('entry["pose_remaining"]',CODE)
  self.assertIn('"pose_count": 0',CODE)
  self.assertIn('"MICRO_IDLE"',CODE)
 def test_movement_preempts_ambient(self):
  self.assertIn('if state in ["ROAM", "RETURN"]:',CODE)
  self.assertIn('entry["pose_remaining"] = 0.0',CODE)
  self.assertIn('_apply_visual_mode(index, "MOVE")',CODE)
  self.assertNotIn('_set_animation(index, "Walk" if state',CODE)
 def test_direction_updates_from_travel_and_uses_real_anchors(self):
  self.assertIn('entry["raw_facing_row"] = VisualPolicy.direction_row(travel)',CODE)
  self.assertIn('entry["source"].get_frame_alignment(motion, row, sprite.frame)',CODE)
  self.assertIn('"%s:%d:%d" % [motion, row, sprite.frame]',CODE)
  self.assertIn('var facing: int = int(entry["raw_facing_row"])',CODE)
  self.assertNotIn('get_frame_alignment(motion, 0, sprite.frame)',CODE)
 def test_row_cache_retains_real_render_row_on_cache_hit(self):
  self.assertIn('entry["render_row"] = int(existing_rows.get(row, row))',CODE)
  self.assertIn('render_rows[row] = entry["render_row"]',CODE)
  self.assertIn('entry["render_row_map"] = render_rows',CODE)
 def test_native_directions_declared_and_facing_formula(self):
  for k in ['["S", "SE", "E", "NE", "N", "NW", "W", "SW"]','posmod(2 - sector, 8)','rad_to_deg(travel.angle()) / 45.0']:
   self.assertIn(k,POLICY)
 def test_all_eight_direction_math(self):
  expected={'S':(0,1,0),'SE':(1,1,1),'E':(1,0,2),'NE':(1,-1,3),'N':(0,-1,4),'NW':(-1,-1,5),'W':(-1,0,6),'SW':(-1,1,7)}
  for name,(x,y,row) in expected.items():
   angle=math.degrees(math.atan2(y,x))
   sector=math.floor(angle/45.0+0.5) if angle>=0 else math.ceil(angle/45.0-0.5)
   self.assertEqual((2-sector)%8,row,name)
 def test_stationary_direction_preserves_previous_row(self):
  self.assertIn('if travel.length_squared() > 0.0001:',CODE)
  self.assertIn('entry["raw_facing_row"] = VisualPolicy.direction_row(travel)',CODE)
 def test_species_specific_cadence(self):
  self.assertIn('25:',POLICY); self.assertIn('94:',POLICY);self.assertIn('143:',POLICY)
  self.assertIn('1.32 if mode == "MOVE"',POLICY)
  self.assertIn('0.58 if mode == "MOVE"',POLICY)
  self.assertIn('rng.randf_range(12.0, 19.0)',POLICY)
  self.assertIn('rng.randf_range(3.5, 6.0)',POLICY)
  self.assertIn('sprite.speed_scale = VisualPolicy.playback_speed',CODE)
 def test_g22_separate_log_and_scene_info(self):
  self.assertIn('PLW_G22_RUNTIME_LAST.log',DIAG)
  self.assertIn('G2.2-v0.4.1',DIAG)
  self.assertIn('facing=%s pose=%s events=%s',DIAG)
  self.assertIn('LOGGER_READY',DIAG)
  self.assertNotIn('PLW_G21_RUNTIME_LAST.log',DIAG)
 def test_no_new_copyrighted_assets(self):
  self.assertTrue((ROOT/'scripts/lab/pmd_visual_policy.gd').is_file())
  self.assertFalse((ROOT/'data/raw/pmdcollab/0025/Idle-Anim.png').exists())
 def test_collector_includes_only_g22_text(self):
  path=ROOT/'tools/g22_collect_logs.py';spec=spec_from_file_location('g22collect',path);mod=module_from_spec(spec);spec.loader.exec_module(mod)
  with tempfile.TemporaryDirectory() as tmp:
   d=Path(tmp)/'reports';d.mkdir();(d/'PLW_G22_RUNTIME_LAST.log').write_text('LOGGER_READY\nAGENT facing=0 pose=STANCE\n')
   (d/'pokemon.png').write_bytes(b'not sprites')
   out=mod.collect(Path(tmp))
   with ZipFile(out) as zipf:
    self.assertEqual(set(zipf.namelist()),{'PLW_G22_RUNTIME_LAST.log','HOW_TO_READ.txt'})
 def test_legacy_g21_files_intact(self):
  for name in ['scenes/ecology_behavior_lab.tscn','scripts/lab/ecology_behavior_lab.gd','scripts/lab/ecology_behavior_diagnostics.gd','RUN_G21_COLLECT_LOG_WINDOWS.bat']:
   self.assertTrue((ROOT/name).is_file())

if __name__=='__main__':unittest.main()
