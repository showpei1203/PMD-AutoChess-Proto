#!/usr/bin/env python3
"""Standard-library-only real-PNG anchor audit for PMDCollab 001..151.

No network access, no art repackaging. Uses real alpha pixels and official PMD
Shadow.png white point; writes numerical CSV/JSON only. Raises explicit ERROR
on unsupported/interlaced/invalid PNG rather than silently reporting PASS.
"""
from __future__ import annotations
import argparse
import csv
import json
import struct
import sys
import xml.etree.ElementTree as ET
import zlib
from pathlib import Path

from pmd_anchor_reference import detect_alpha_bounds, detect_shadow_center

SIGNATURE = b'\x89PNG\r\n\x1a\n'
CHANNELS = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}


def _paeth(a:int,b:int,c:int)->int:
    p=a+b-c
    ab,bb,cb=abs(p-a),abs(p-b),abs(p-c)
    return a if ab<=bb and ab<=cb else b if bb<=cb else c


def decode_png(path: Path) -> list[list[tuple[int,int,int,int]]]:
    raw = path.read_bytes()
    if not raw.startswith(SIGNATURE):
        raise ValueError('PNG signature invalid')
    off=8; w=h=bit=ct=interlace=0; chunks=[]; palette=b''; alpha=b''
    while off+12 <= len(raw):
        length=struct.unpack_from('>I',raw,off)[0]
        if length>100_000_000 or off+12+length>len(raw):raise ValueError('Truncated/oversized chunk')
        name=raw[off+4:off+8]; data=raw[off+8:off+8+length]
        crc=struct.unpack_from('>I',raw,off+8+length)[0]
        if zlib.crc32(name+data)&0xffffffff != crc:raise ValueError('PNG chunk CRC mismatch')
        off += 12+length
        if name==b'IHDR':
            w,h,bit,ct,comp,flt,interlace=struct.unpack('>IIBBBBB',data)
            if comp or flt or interlace:raise ValueError('Unsupported compressed/filter/interlaced PNG')
        elif name==b'PLTE':palette=data
        elif name==b'tRNS':alpha=data
        elif name==b'IDAT':chunks.append(data)
        elif name==b'IEND':break
    if not (w and h and w<=16384 and h<=16384 and ct in CHANNELS and bit in (1,2,4,8,16)):
        raise ValueError(f'Unsupported PNG geometry / mode {w}x{h}, type {ct}, depth {bit}')
    if ct not in (0,3) and bit not in (8,16):raise ValueError('Unsupported packed PNG color mode')
    channels=CHANNELS[ct]
    bytes_per_pixel=max(1,(channels*bit+7)//8)
    stride=(w*channels*bit+7)//8
    expected=h*(stride+1)
    decomp=zlib.decompressobj()
    packed=decomp.decompress(b''.join(chunks), expected+1)
    packed += decomp.flush()
    if len(packed)!=expected:raise ValueError(f'Decompressed scanlines length mismatch: {len(packed)} != {expected}')
    result=[];prev=bytearray(stride); cursor=0
    for _ in range(h):
        filter_kind=packed[cursor];cursor+=1
        scan=bytearray(packed[cursor:cursor+stride]);cursor+=stride
        for i in range(stride):
            a=scan[i-bytes_per_pixel] if i>=bytes_per_pixel else 0
            b=prev[i]
            c=prev[i-bytes_per_pixel] if i>=bytes_per_pixel else 0
            if filter_kind==0:bonus=0
            elif filter_kind==1:bonus=a
            elif filter_kind==2:bonus=b
            elif filter_kind==3:bonus=(a+b)//2
            elif filter_kind==4:bonus=_paeth(a,b,c)
            else:raise ValueError('Unsupported PNG filter')
            scan[i]=(scan[i]+bonus)&255
        prev=scan
        pixels=[]
        for x in range(w):
            if bit in (1,2,4):
                sample_mask=(1<<bit)-1
                byte=scan[x*bit//8]
                shift=8-bit-(x*bit%8)
                sample=(byte>>shift)&sample_mask
                if ct==3:
                    j=sample*3
                    if j+2>=len(palette):raise ValueError('Palette index outside PLTE')
                    p=(palette[j],palette[j+1],palette[j+2],alpha[sample] if sample<len(alpha) else 255)
                else:
                    gray=round(sample*255/sample_mask)
                    p=(gray,gray,gray,255)
            else:
                pos=x*channels*bit//8
                step=2 if bit==16 else 1
                values=[scan[pos+i*step] for i in range(channels)]
                if ct==6:p=(*values,)
                elif ct==2:
                    transparency=tuple(alpha[i] for i in (0,2,4)) if len(alpha)>=6 else None
                    p=(*values,0 if transparency and tuple(values)==transparency else 255)
                elif ct==4:p=(values[0],values[0],values[0],values[1])
                elif ct==0:p=(values[0],values[0],values[0],255)
                elif ct==3:
                    k=values[0];j=k*3
                    if j+2>=len(palette):raise ValueError('Palette index outside PLTE')
                    p=(palette[j],palette[j+1],palette[j+2],alpha[k] if k<len(alpha) else 255)
                else:raise ValueError('PNG color type not implemented')
            pixels.append(p)
        result.append(pixels)
    return result


def resolve_action(root:ET.Element, action:str) -> tuple[str,int,int] | None:
    animations={item.findtext('Name'):item for item in root.findall('./Anims/Anim')}
    seen=set(); current=action
    while current and current not in seen:
        seen.add(current)
        item=animations.get(current)
        if item is None:return None
        copy=item.findtext('CopyOf')
        if copy:current=copy.strip();continue
        fw=item.findtext('FrameWidth');fh=item.findtext('FrameHeight')
        return (current,int(fw),int(fh)) if fw and fh else None
    return None


def region(img:list[list[tuple[int,int,int,int]]], fw:int, fh:int, col:int=0, row:int=0):
    x=fw*col;y=fh*row
    if y+fh>len(img) or x+fw>len(img[0]):
        raise ValueError('PNG too small for XML frame dimensions')
    return [line[x:x+fw] for line in img[y:y+fh]]


def examine(root:Path, dex:int, action:str) -> dict:
    rec={'species':f'{dex:03}', 'action':action,'status':'ERROR','frame_height':'', 'alpha_bottom':'', 'native_shadow_y':'', 'chosen_y':'', 'delta_vs_frame_bottom':'', 'method':'','reason':''}
    folder=root/'data'/'raw'/'pmdcollab'/f'{dex:04}'
    try:
        xml=ET.parse(folder/'AnimData.xml').getroot()
        resolved=resolve_action(xml,action)
        if not resolved:
            rec.update(status='UNAVAILABLE',reason='No action or CopyOf target')
            return rec
        actual,fw,fh=resolved
        anim=region(decode_png(folder/f'{actual}-Anim.png'),fw,fh)
        bounds=detect_alpha_bounds(anim)
        rec['frame_height']=fh
        rec['alpha_bottom']=bounds[1]+bounds[3] if bounds else ''
        shadow_file=folder/f'{actual}-Shadow.png'
        native=None
        if shadow_file.exists():
            shadow=region(decode_png(shadow_file),fw,fh)
            native=detect_shadow_center(shadow)
        anchor_y=native[1] if native else (float(bounds[1]+bounds[3]) if bounds else float(fh))
        rec['native_shadow_y']=round(native[1],2) if native else ''
        rec['chosen_y']=round(anchor_y,2)
        rec['delta_vs_frame_bottom']=round(float(fh)-anchor_y,2)
        rec['method']='PMD_SHADOW_CENTER' if native else ('ALPHA_BOTTOM_FALLBACK' if bounds else 'EMPTY_FRAME_FALLBACK')
        rec['status']='PASS' if native else 'REVIEW'
        rec['reason']='' if native else 'Native shadow marker unavailable; verify vertical moves/flight'
    except (OSError,ValueError,ET.ParseError,IndexError,OverflowError) as err:
        rec['reason']=str(err)[:200]
    return rec


def run(args=None):
    parser=argparse.ArgumentParser(description='Audit actual PMD frame bottom versus shadow/alpha anchor; no external libraries')
    parser.add_argument('--root',default='.')
    parser.add_argument('--first',type=int,default=1)
    parser.add_argument('--last',type=int,default=151)
    opts=parser.parse_args(args)
    if not (1<=opts.first<=opts.last<=151):parser.error('species range must be 1..151')
    base=Path(opts.root).resolve()
    records=[examine(base,s,a) for s in range(opts.first,opts.last+1) for a in ('Idle','Walk','Attack')]
    out=base/'reports';out.mkdir(exist_ok=True)
    records.sort(key=lambda r:(float(r['delta_vs_frame_bottom']) if isinstance(r['delta_vs_frame_bottom'],(int,float)) else -1),reverse=True)
    fields=list(records[0])
    with (out/'pmd_anchor_audit.csv').open('w',newline='',encoding='utf-8-sig') as fp:
        writer=csv.DictWriter(fp,fieldnames=fields);writer.writeheader();writer.writerows(records)
    counts={k:sum(r['status']==k for r in records) for k in ('PASS','REVIEW','UNAVAILABLE','ERROR')}
    (out/'pmd_anchor_audit.json').write_text(json.dumps({'counts':counts,'records':records,'scope':f'{opts.first}..{opts.last}','note':'Only raw row0 frame0; not gameplay review. No art bytes.'},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    for r in records[:18]:
        print(f"#{r['species']} {r['action']}: frameBottom={r['frame_height']} anchorY={r['chosen_y']} delta={r['delta_vs_frame_bottom']} {r['method']} {r['status']}")
    print(f'ANCHOR AUDIT rows={len(records)} PASS={counts["PASS"]} REVIEW={counts["REVIEW"]} UNAVAILABLE={counts["UNAVAILABLE"]} ERROR={counts["ERROR"]}')
    print('reports/pmd_anchor_audit.csv | reports/pmd_anchor_audit.json')
    return 2 if counts['ERROR'] else 0

if __name__=='__main__':sys.exit(run())
