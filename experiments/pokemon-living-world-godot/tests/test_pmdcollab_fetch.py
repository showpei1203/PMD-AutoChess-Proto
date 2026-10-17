"""Synthetic, offline tests; no copyrighted sprites and no real HTTP calls."""
from pathlib import Path
import sys
import unittest
import tempfile
import io
import zipfile
import struct
import zlib
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
from pmdcollab_fetch import validate_member_path, parse_animations, inspect_zip, stage_species, main


def tiny_png():
    sig=b'\x89PNG\r\n\x1a\n'
    def chunk(n,b):return struct.pack('>I',len(b))+n+b+struct.pack('>I',zlib.crc32(n+b)&0xffffffff)
    ihdr=struct.pack('>IIBBBBB',1,1,8,6,0,0,0)
    return sig+chunk(b'IHDR',ihdr)+chunk(b'IDAT',zlib.compress(b'\x00\xff\x00\x00\xff'))+chunk(b'IEND',b'')
XML=b'<AnimData><Anims><Anim><Name>Idle</Name><FrameWidth>24</FrameWidth><FrameHeight>24</FrameHeight><Durations><Duration>5</Duration><Duration>6</Duration></Durations></Anim><Anim><Name>Walk</Name><FrameWidth>24</FrameWidth><FrameHeight>24</FrameHeight><Durations><Duration>2</Duration></Durations></Anim><Anim><Name>Strike</Name><CopyOf>Attack</CopyOf></Anim></Anims></AnimData>'

def sprite_zip(entries=None):
    if entries is None: entries={'AnimData.xml':XML,'Idle-Anim.png':tiny_png(),'Walk-Anim.png':tiny_png()}
    b=io.BytesIO()
    with zipfile.ZipFile(b,'w') as z:
        for k,v in entries.items():z.writestr(k,v)
    return b.getvalue()

class TestFetch(unittest.TestCase):
    def test_path_good(self):self.assertEqual(validate_member_path('A/Idle-Anim.png'),'A/Idle-Anim.png')
    def test_path_parent(self):
        with self.assertRaises(ValueError):validate_member_path('../bad.png')
    def test_path_abs(self):
        with self.assertRaises(ValueError):validate_member_path('/bad.png')
    def test_path_backslash(self):
        with self.assertRaises(ValueError):validate_member_path('x\\y.png')
    def test_xml(self):
        a=parse_animations(XML)
        self.assertEqual(len(a),3)
        self.assertEqual(a[0]['durations'],[5,6])
        self.assertEqual(a[2]['copy_of'],'Attack')
    def test_no_xml(self):
        with self.assertRaises(ValueError):inspect_zip(sprite_zip({'Idle-Anim.png':tiny_png(),'Walk-Anim.png':tiny_png()}))
    def test_valid_zip(self):
        members,anims=inspect_zip(sprite_zip())
        self.assertEqual(len(members),3)
        self.assertEqual(len(anims),3)
    def test_missing_walk(self):
        with self.assertRaises(ValueError):inspect_zip(sprite_zip({'AnimData.xml':XML,'Idle-Anim.png':tiny_png()}))
    def test_idle_copyof_walk_dragonair_0148(self):
        xml = b'<AnimData><Anims><Anim><Name>Walk</Name><FrameWidth>48</FrameWidth><FrameHeight>56</FrameHeight><Durations><Duration>8</Duration></Durations></Anim><Anim><Name>Idle</Name><CopyOf>Walk</CopyOf></Anim></Anims></AnimData>'
        members, animations = inspect_zip(sprite_zip({
            'AnimData.xml': xml, 'Walk-Anim.png': tiny_png()}))
        self.assertEqual(len(members), 2)
        self.assertEqual(animations[1]['copy_of'], 'Walk')

    def test_idle_copyof_chain(self):
        xml = b'<AnimData><Anims><Anim><Name>Walk</Name><CopyOf>Roam</CopyOf></Anim><Anim><Name>Roam</Name><FrameWidth>24</FrameWidth><FrameHeight>24</FrameHeight><Durations><Duration>5</Duration></Durations></Anim><Anim><Name>Idle</Name><CopyOf>Walk</CopyOf></Anim></Anims></AnimData>'
        inspect_zip(sprite_zip({'AnimData.xml': xml, 'Roam-Anim.png': tiny_png()}))

    def test_idle_copyof_missing_target(self):
        xml = b'<AnimData><Anims><Anim><Name>Idle</Name><CopyOf>NotDefined</CopyOf></Anim><Anim><Name>Walk</Name><FrameWidth>24</FrameWidth><FrameHeight>24</FrameHeight><Durations><Duration>3</Duration></Durations></Anim></Anims></AnimData>'
        with self.assertRaisesRegex(ValueError, 'Missing animation definition'):
            inspect_zip(sprite_zip({'AnimData.xml': xml, 'Walk-Anim.png': tiny_png()}))

    def test_idle_copyof_cycle(self):
        xml = b'<AnimData><Anims><Anim><Name>Idle</Name><CopyOf>Walk</CopyOf></Anim><Anim><Name>Walk</Name><CopyOf>Idle</CopyOf></Anim></Anims></AnimData>'
        with self.assertRaisesRegex(ValueError, 'CopyOf cycle'):
            inspect_zip(sprite_zip({'AnimData.xml': xml}))

    def test_idle_copyof_missing_target_sheet(self):
        xml = b'<AnimData><Anims><Anim><Name>Idle</Name><CopyOf>Walk</CopyOf></Anim><Anim><Name>Walk</Name><FrameWidth>24</FrameWidth><FrameHeight>24</FrameHeight><Durations><Duration>3</Duration></Durations></Anim></Anims></AnimData>'
        with self.assertRaisesRegex(ValueError, 'Missing required animation image'):
            inspect_zip(sprite_zip({'AnimData.xml': xml}))

    def test_png_bad(self):
        with self.assertRaises(ValueError):inspect_zip(sprite_zip({'AnimData.xml':XML,'Idle-Anim.png':b'bad','Walk-Anim.png':tiny_png()}))
    def test_stage_mock_network_and_cache(self):
        counter=[]
        def fetch(url):
            counter.append(url)
            return b'test credits' if url.endswith('credits.txt') else sprite_zip()
        with tempfile.TemporaryDirectory() as d:
            x=stage_species(25,Path(d),fetcher=fetch)
            self.assertEqual(x['species_id'],25)
            self.assertEqual(x['credits_status'],'AVAILABLE')
            self.assertTrue((Path(d)/'data/raw/pmdcollab/0025/Idle-Anim.png').is_file())
            self.assertTrue((Path(d)/'data/raw/pmdcollab/0025/credits_upstream.txt').is_file())
            cached=stage_species(25,Path(d),fetcher=lambda u:self.fail('cache must avoid fetch'))
            self.assertTrue(cached['cached'])
    def test_plan(self):
        self.assertEqual(main(['--ids','25,94','--plan']),0)
    def test_ids_rejected(self):
        with self.assertRaises(SystemExit):main(['--ids','0','--plan'])

if __name__=='__main__':unittest.main()