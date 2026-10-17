"""Real PNG byte decoding / fake 0130-like ground anchor integration tests."""
from pathlib import Path
import tempfile
import struct
import sys
import unittest
import zlib
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
from pmd_anchor_audit import decode_png, examine, run


def chunk(name,content):
    return struct.pack('>I',len(content))+name+content+struct.pack('>I',zlib.crc32(name+content)&0xffffffff)

def rgba_png(w,h,pixels):
    raw=b''.join(b'\0'+b''.join(bytes(pixel) for pixel in row) for row in pixels)
    return b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(raw))+chunk(b'IEND',b'')

CLEAR=(0,0,0,0);WHITE=(255,255,255,255);PIX=(20,50,90,255)

class AnchorAuditTests(unittest.TestCase):
    def test_decoder_transparent_rgba(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/'test.png'
            p.write_bytes(rgba_png(3,2,[[CLEAR,PIX,CLEAR],[CLEAR,CLEAR,WHITE]]))
            actual=decode_png(p)
            self.assertEqual(actual[0][1],PIX)
            self.assertEqual(actual[1][2],WHITE)
            self.assertEqual(actual[0][0][3],0)

    def test_integrated_large_frame_native_shadow(self):
        with tempfile.TemporaryDirectory() as d:
            folder=Path(d)/'data/raw/pmdcollab/0130';folder.mkdir(parents=True)
            w,h=20,80
            sprite=[[CLEAR for _ in range(w)] for _ in range(h)]
            shadow=[[CLEAR for _ in range(w)] for _ in range(h)]
            sprite[10][6]=PIX;sprite[33][8]=PIX;shadow[69][10]=WHITE
            (folder/'Idle-Anim.png').write_bytes(rgba_png(w,h,sprite))
            (folder/'Idle-Shadow.png').write_bytes(rgba_png(w,h,shadow))
            (folder/'AnimData.xml').write_text(f'<AnimData><Anims><Anim><Name>Idle</Name><FrameWidth>{w}</FrameWidth><FrameHeight>{h}</FrameHeight><Durations><Duration>10</Duration></Durations></Anim></Anims></AnimData>')
            row=examine(Path(d),130,'Idle')
            self.assertEqual(row['status'],'PASS')
            self.assertEqual(row['method'],'PMD_SHADOW_CENTER')
            self.assertEqual(row['alpha_bottom'],34)
            self.assertEqual(row['native_shadow_y'],69.5)
            self.assertEqual(row['delta_vs_frame_bottom'],10.5)

    def test_non_native_image_stays_review_not_pass(self):
        with tempfile.TemporaryDirectory() as d:
            folder=Path(d)/'data/raw/pmdcollab/0130';folder.mkdir(parents=True)
            s=[[CLEAR for _ in range(8)] for _ in range(40)];s[9][3]=PIX
            (folder/'Walk-Anim.png').write_bytes(rgba_png(8,40,s))
            (folder/'AnimData.xml').write_text('<AnimData><Anims><Anim><Name>Walk</Name><FrameWidth>8</FrameWidth><FrameHeight>40</FrameHeight><Durations><Duration>4</Duration></Durations></Anim></Anims></AnimData>')
            row=examine(Path(d),130,'Walk')
            self.assertEqual(row['status'],'REVIEW')
            self.assertEqual(row['delta_vs_frame_bottom'],30.0)

if __name__=='__main__':unittest.main()
