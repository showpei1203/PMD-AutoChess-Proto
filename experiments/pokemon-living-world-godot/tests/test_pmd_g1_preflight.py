"""Offline synthetic unit tests for the G1 sheet preflight; no PMDCollab images."""
from pathlib import Path
import sys
import unittest
import tempfile
import struct
import zlib
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
from pmd_g1_preflight import png_dimensions, parse_xml, follow_alias, examine_species


def fake_png(width=16, height=128):
    def block(kind, data):
        return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(kind+data)&0xffffffff)
    sig=b'\x89PNG\r\n\x1a\n'
    ihdr=struct.pack('>IIBBBBB',width,height,8,6,0,0,0)
    return sig+block(b'IHDR',ihdr)+block(b'IEND',b'')


def fixtures(root:Path, species:int=148, idle_alias=True, missing_walk=False):
    path=root/'data/raw/pmdcollab'/f'{species:04d}'
    path.mkdir(parents=True,exist_ok=True)
    alias='<CopyOf>Walk</CopyOf>' if idle_alias else '<FrameWidth>16</FrameWidth><FrameHeight>16</FrameHeight><Durations><Duration>5</Duration></Durations>'
    xml=f'<AnimData><Anims><Anim><Name>Idle</Name>{alias}</Anim><Anim><Name>Walk</Name><FrameWidth>16</FrameWidth><FrameHeight>16</FrameHeight><Durations><Duration>3</Duration></Durations></Anim><Anim><Name>Attack</Name><FrameWidth>16</FrameWidth><FrameHeight>16</FrameHeight><Durations><Duration>4</Duration></Durations></Anim></Anims></AnimData>'
    (path/'AnimData.xml').write_text(xml,encoding='utf-8')
    (path/'credits_upstream.txt').write_text('mock credit',encoding='utf-8')
    if not missing_walk:(path/'Walk-Anim.png').write_bytes(fake_png())
    (path/'Attack-Anim.png').write_bytes(fake_png())
    if not idle_alias:(path/'Idle-Anim.png').write_bytes(fake_png())
    return path


class G1PreflightTests(unittest.TestCase):
    def test_png_header(self):
        with tempfile.TemporaryDirectory() as d:
            file=Path(d)/'test.png';file.write_bytes(fake_png())
            self.assertEqual(png_dimensions(file),(16,128))
    def test_png_invalid(self):
        with tempfile.TemporaryDirectory() as d:
            file=Path(d)/'test.png';file.write_bytes(b'bad')
            with self.assertRaises(ValueError):png_dimensions(file)
    def test_dragonair_idle_alias(self):
        with tempfile.TemporaryDirectory() as d:
            path=fixtures(Path(d))
            parsed=parse_xml(path/'AnimData.xml')
            self.assertEqual(follow_alias(parsed,'Idle'),'Walk')
            report=examine_species(Path(d),148)
            self.assertEqual(report['status'],'PASS')
            self.assertEqual(report['animations']['Idle']['source_action'],'Walk')
    def test_missing_walk_fails(self):
        with tempfile.TemporaryDirectory() as d:
            fixtures(Path(d),missing_walk=True)
            self.assertEqual(examine_species(Path(d),148)['status'],'FAIL')
    def test_missing_art_fails(self):
        with tempfile.TemporaryDirectory() as d:
            self.assertEqual(examine_species(Path(d),25)['status'],'FAIL')
    def test_alias_cycle(self):
        defs={'Idle':{'copy_of':'Walk'},'Walk':{'copy_of':'Idle'}}
        with self.assertRaisesRegex(ValueError,'cycle'):follow_alias(defs,'Idle')
    def test_alias_missing_target(self):
        defs={'Idle':{'copy_of':'DoesNotExist'}}
        with self.assertRaisesRegex(ValueError,'Missing'):follow_alias(defs,'Idle')
    def test_wrong_sheet_ratio_fails(self):
        with tempfile.TemporaryDirectory() as d:
            path=fixtures(Path(d))
            (path/'Walk-Anim.png').write_bytes(fake_png(width=22))
            self.assertEqual(examine_species(Path(d),148)['status'],'FAIL')
    def test_missing_credits_warn(self):
        with tempfile.TemporaryDirectory() as d:
            path=fixtures(Path(d));(path/'credits_upstream.txt').unlink()
            self.assertEqual(examine_species(Path(d),148)['status'],'WARN')
    def test_attack_missing_allowed(self):
        with tempfile.TemporaryDirectory() as d:
            path=fixtures(Path(d));(path/'AnimData.xml').write_text('<AnimData><Anims><Anim><Name>Walk</Name><FrameWidth>16</FrameWidth><FrameHeight>16</FrameHeight><Durations><Duration>3</Duration></Durations></Anim><Anim><Name>Idle</Name><CopyOf>Walk</CopyOf></Anim></Anims></AnimData>',encoding='utf-8')
            report=examine_species(Path(d),148)
            self.assertEqual(report['status'],'PASS')
            self.assertEqual(report['animations']['Attack']['status'],'UNSUPPORTED')

if __name__=='__main__':unittest.main()
