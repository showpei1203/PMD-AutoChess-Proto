"""G2.2.1 regression: Surface Godot parser error at line 104, undefined locals.

Static contracts do NOT replace running Godot 4.7.2 F6.
"""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = (ROOT/'scripts/lab/ecology_animation_diagnostics.gd').read_text('utf-8')
SCENE = (ROOT/'scenes/ecology_animation_lab.tscn').read_text('utf-8')

class G221RuntimeParserRegression(unittest.TestCase):
    def test_roams_is_bound_before_first_use(self):
        local = 'var roams: String = str(agent.get("roam_count", "?"))'
        usage = '_log("AGENT #%03d state=%s'
        self.assertIn(local, SRC)
        self.assertLess(SRC.index(local), SRC.index(usage))

    def test_since_roam_is_bound_before_first_use(self):
        local = 'var since_roam: String = str(agent.get("time_since_roam", "?"))'
        usage = '_log("AGENT #%03d state=%s'
        self.assertIn(local, SRC)
        self.assertLess(SRC.index(local), SRC.index(usage))

    def test_telemetry_template_has_matching_arguments(self):
        m = re.search(r'_log\("(AGENT #%03d[^"\n]+)" % \[([^\]\n]+)\]\)', SRC)
        self.assertIsNotNone(m)
        self.assertEqual(m.group(1).count('%s') + m.group(1).count('%03d'), len(m.group(2).split(',')))
        self.assertIn('roams', [x.strip() for x in m.group(2).split(',')])
        self.assertIn('since_roam', m.group(2))
        self.assertIn('G2.2.1 | tick=', SRC)
        self.assertIn('res://scripts/lab/ecology_animation_diagnostics.gd', SCENE)

if __name__ == '__main__': unittest.main()
