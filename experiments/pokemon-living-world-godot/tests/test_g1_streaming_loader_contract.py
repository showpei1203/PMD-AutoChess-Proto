"""G1 streaming reader code-contract tests; Godot runtime test requires a Surface run."""
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'scripts/lab/pmd_sprite_source.gd'
LAB = ROOT / 'scripts/lab/animation_lab.gd'


class TestG1StreamingLoader(unittest.TestCase):
    def test_anim_xml_is_record_scoped(self):
        source = SOURCE.read_text(encoding='utf-8')
        self.assertIn('elif kind == XMLParser.NODE_ELEMENT_END:', source)
        self.assertIn('if close == "Anim" and not current.is_empty():', source)
        self.assertIn('parsed[action] = current.duplicate(true)', source)
        self.assertNotIn('XML tag mismatch:', source)
        self.assertNotIn('var tags: Array[String]', source)

    def test_gengar_crlf_input_valid_example(self):
        # Gengar's upstream AnimData.xml uses CRLF. This is a synthetic
        # representative (NOT the full PMDCollab file, and NOT a Godot test).
        template = '<AnimData>\r\n<Anims>\r\n' + ''.join(
            f'<Anim>\r\n<Name>Action{i}</Name>\r\n<FrameWidth>32</FrameWidth>\r\n<FrameHeight>40</FrameHeight>\r\n<Durations><Duration>8</Duration></Durations>\r\n</Anim>\r\n'
            for i in range(36)) + '</Anims>\r\n</AnimData>\r\n'
        root = ET.fromstring(template)
        self.assertEqual(root.tag, 'AnimData')
        self.assertEqual(len(root.findall('./Anims/Anim')), 36)
        source = SOURCE.read_text(encoding='utf-8')
        self.assertIn('parser.get_node_name().strip_edges()', source)
        self.assertIn('XMLParser.NODE_TEXT', source)

    def test_texture_uses_imported_resource(self):
        code = SOURCE.read_text(encoding='utf-8')
        self.assertIn('ResourceLoader.load(sheet_path, "Texture2D")', code)
        self.assertNotIn('image.load(sheet_path)', code)
        self.assertNotIn('ImageTexture.create_from_image(image)', code)
        self.assertIn('imported_texture is Texture2D', code)

    def test_lab_reports_real_loader_error(self):
        code = LAB.read_text(encoding='utf-8')
        self.assertIn('LOAD ERROR (see Output)', code)
        self.assertIn('已成功解析並載入', code)
        self.assertIn('[PLW-G1] %s failed: %s', code)
        self.assertNotIn('Missing local art', code)


if __name__ == '__main__':
    unittest.main()
