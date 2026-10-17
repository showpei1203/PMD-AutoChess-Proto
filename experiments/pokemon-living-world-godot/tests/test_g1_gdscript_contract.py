"""Static regression: Godot engine parse must still be verified on Surface."""
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]


class TestGodotSourceContracts(unittest.TestCase):
    def test_resolve_action_exits_with_typed_fallback(self):
        data = (ROOT / 'scripts/lab/pmd_sprite_source.gd').read_text('utf-8')
        start = data.index('func resolve_action(')
        end = data.index('\nfunc get_animation(', start)
        body = data[start:end]
        self.assertIn('func resolve_action(action: String) -> Dictionary:', body)
        self.assertIn('while not requested.is_empty():', body)
        self.assertIn('errors.append("CopyOf loop: "', body)
        self.assertIn('errors.append("Action unavailable: "', body)
        self.assertRegex(body, r'(?m)^    return \{\}\s*$')


if __name__ == '__main__':
    unittest.main()
