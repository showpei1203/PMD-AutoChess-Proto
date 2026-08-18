#!/usr/bin/env python3
from __future__ import annotations
import argparse, hashlib, json
from pathlib import Path
from PIL import Image

W=H=64
CELL=32
MIN_VISIBLE=32
MAX_VISIBLE=972
MAX_SEAM_TOUCH=12

def sha256(path: Path) -> str:
    h=hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda:f.read(1024*1024),b''):
            h.update(chunk)
    return h.hexdigest()

def validate(path: Path):
    errors=[]; warnings=[]
    try:
        src=Image.open(path)
        mode=src.mode
        size=src.size
        if size!=(W,H): errors.append(f'size={size[0]}x{size[1]} expected=64x64')
        if mode!='RGBA': errors.append(f'mode={mode} expected=RGBA')
        im=src.convert('RGBA')
    except Exception as e:
        return {'file':path.name,'pass':False,'errors':[f'open_error={e.__class__.__name__}:{e}'],'warnings':[]}
    if im.size!=(W,H):
        return {'file':path.name,'pass':False,'errors':errors,'warnings':warnings,'sha256':sha256(path)}
    alpha=im.getchannel('A')
    ap=alpha.load()
    cells=[]
    for cy in range(2):
        for cx in range(2):
            aa=alpha.crop((cx*CELL,cy*CELL,(cx+1)*CELL,(cy+1)*CELL))
            vals=aa.tobytes()
            visible=sum(v>0 for v in vals)
            opaque=sum(v==255 for v in vals)
            idx=cy*2+cx
            if visible<MIN_VISIBLE: errors.append(f'cell{idx}_visible={visible} too_sparse')
            if visible>MAX_VISIBLE: errors.append(f'cell{idx}_visible={visible} insufficient_transparency')
            cells.append({'cell':idx,'visible':visible,'opaque':opaque,'coverage':round(visible/(CELL*CELL),4)})
    seam=0
    for y in range(H):
        if ap[31,y]>0 and ap[32,y]>0: seam+=1
    for x in range(W):
        if ap[x,31]>0 and ap[x,32]>0: seam+=1
    if seam>MAX_SEAM_TOUCH:
        warnings.append(f'seam_touch_pairs={seam}; review for cross-cell object continuity')
    result={'file':path.name,'pass':not errors,'size':[W,H],'mode':'RGBA','cell_size':CELL,
            'cells':cells,'seam_touch_pairs':seam,'sha256':sha256(path),'errors':errors,'warnings':warnings}
    return result

def main():
    ap=argparse.ArgumentParser(description='Validate PMD AutoChess VXRD 64x64 / 4x32x32 Landmark atlases.')
    ap.add_argument('paths',nargs='+')
    ap.add_argument('--json',action='store_true')
    args=ap.parse_args()
    files=[]
    for raw in args.paths:
        p=Path(raw)
        if p.is_dir(): files.extend(sorted(p.glob('*.png')))
        else: files.append(p)
    results=[validate(p) for p in files]
    if args.json:
        print(json.dumps({'pass':all(r['pass'] for r in results),'count':len(results),'results':results},ensure_ascii=False,indent=2))
    else:
        for r in results:
            print(('PASS' if r['pass'] else 'FAIL'),r['file'],r.get('sha256',''))
            for c in r.get('cells',[]): print(f"  cell{c['cell']}: visible={c['visible']} coverage={c['coverage']:.4f}")
            if r.get('seam_touch_pairs') is not None: print('  seam_touch_pairs=',r['seam_touch_pairs'])
            for w in r.get('warnings',[]): print('  WARN',w)
            for e in r.get('errors',[]): print('  ERROR',e)
    return 0 if all(r['pass'] for r in results) else 1
if __name__=='__main__': raise SystemExit(main())
