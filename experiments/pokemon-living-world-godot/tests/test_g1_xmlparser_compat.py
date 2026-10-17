"""Godot 4 XMLParser API regression contracts (not a Godot runtime test)."""
from pathlib import Path
import unittest

SOURCE = Path(__file__).resolve().parents[1] / "scripts/lab/pmd_sprite_source.gd"

class GodotXmlCompatibility(unittest.TestCase):
    def test_godot_xmlparser_open_path(self):
        code = SOURCE.read_text(encoding="utf-8")
        self.assertIn("parser.open(xml_path)", code)
        self.assertNotIn("parser.open_file(", code)

    def test_frame_division_is_not_int_division(self):
        code = SOURCE.read_text(encoding="utf-8")
        self.assertIn("int(float(texture.get_width()) / float(frame_width))", code)
        self.assertIn("int(float(texture.get_height()) / float(frame_height))", code)
        self.assertNotIn("int(texture.get_width() / frame_width)", code)
        self.assertNotIn("int(texture.get_height() / frame_height)", code)

    def test_xml_parser_contract_has_error_exit(self):
        code = SOURCE.read_text(encoding="utf-8")
        self.assertIn("if err != OK:", code)
        self.assertIn("if state == ERR_FILE_EOF:", code)
        self.assertIn("var parser := XMLParser.new()", code)

if __name__ == "__main__":
    unittest.main()
