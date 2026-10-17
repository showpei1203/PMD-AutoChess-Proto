#!/usr/bin/env python3
"""Offline PMDCollab G1 animation sheet preflight; never uploads pixel art.

Usage: py -3 tools/pmd_g1_preflight.py --out . --ids 25,94,143
or:    py -3 tools/pmd_g1_preflight.py --out . --all151
"""
from __future__ import annotations
import argparse
import json
from pathlib import Path
import struct
import sys
import xml.etree.ElementTree as ET

PNG_SIGNATURE = b'\x89PNG\r\n\x1a\n'


def png_dimensions(path: Path) -> tuple[int, int]:
    with path.open('rb') as file:
        header = file.read(24)
    if len(header) < 24 or not header.startswith(PNG_SIGNATURE) or header[12:16] != b'IHDR':
        raise ValueError(f'Invalid PNG header: {path}')
    width, height = struct.unpack('>II', header[16:24])
    if min(width, height) <= 0:
        raise ValueError(f'Invalid PNG dimensions: {path}')
    return width, height


def parse_xml(xml_path: Path) -> dict[str, dict]:
    root = ET.parse(xml_path).getroot()
    if root.tag != 'AnimData':
        raise ValueError('Incorrect AnimData root')
    result = {}
    for element in root.findall('./Anims/Anim'):
        name = (element.findtext('Name') or '').strip()
        if not name or name in result:
            raise ValueError('Duplicate / invalid action: ' + name)
        durations = [int((d.text or '0').strip()) for d in element.findall('./Durations/Duration')]
        result[name] = {'copy_of': (element.findtext('CopyOf') or '').strip(),
                        'width': int(element.findtext('FrameWidth') or 0),
                        'height': int(element.findtext('FrameHeight') or 0),
                        'durations': durations}
    if not result:
        raise ValueError('Empty animation definitions')
    return result


def follow_alias(data: dict[str, dict], action: str) -> str:
    seen: set[str] = set()
    while True:
        if action in seen:
            raise ValueError('CopyOf cycle: ' + action)
        seen.add(action)
        if action not in data:
            raise ValueError('Missing CopyOf target: ' + action)
        dest = data[action]['copy_of']
        if not dest:
            return action
        action = dest


def examine_species(root: Path, pokemon: int) -> dict:
    code = f'{pokemon:04d}'
    source = root / 'data' / 'raw' / 'pmdcollab' / code
    record = {'species': pokemon, 'folder': str(source), 'status': 'PASS',
              'animations': {}, 'issues': [], 'credits': False}
    try:
        path = source / 'AnimData.xml'
        if not path.is_file():
            raise FileNotFoundError(f'Missing AnimData.xml for #{pokemon}')
        defs = parse_xml(path)
        record['credits'] = (source / 'credits_upstream.txt').is_file()
        if not record['credits']:
            record['issues'].append('No downloaded credits_upstream.txt')
        for action in ('Idle','Walk','Attack'):
            if action not in defs:
                record['animations'][action] = {'status': 'UNSUPPORTED'}
                if action in ('Idle','Walk'):
                    raise ValueError('Missing critical definition: ' + action)
                continue
            resolved = follow_alias(defs,action)
            meta = defs[resolved]
            frame_width, frame_height = meta['width'],meta['height']
            if min(frame_width,frame_height) <= 0 or not meta['durations']:
                raise ValueError(f'Invalid frame dimensions or durations: {action} -> {resolved}')
            p = source / f'{resolved}-Anim.png'
            if not p.is_file():
                raise FileNotFoundError(f'Missing sprite sheet: {p}')
            width,height = png_dimensions(p)
            if width%frame_width or height%frame_height:
                raise ValueError(f'{action} sheet is not a multiple of declared tile dimensions')
            columns, rows = width//frame_width,height//frame_height
            if columns < len(meta['durations']) or rows < 8:
                raise ValueError(f'{action} needs {len(meta["durations"])} frames and 8 facing rows; has {columns}x{rows}')
            record['animations'][action] = {'status': 'READY', 'source_action': resolved,
                'alias': (action != resolved), 'columns': columns, 'rows': rows,
                'declared_frames': len(meta['durations']), 'frame_size': [frame_width, frame_height]}
        if not record['credits']:
            record['status'] = 'WARN'
    except (ET.ParseError, ValueError, FileNotFoundError, OSError) as error:
        record['status'] = 'FAIL'
        record['issues'].append(str(error))
    return record


def run(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description='PMD G1 animation preflight (local art only)')
    parser.add_argument('--out', default='.', help='Godot project root')
    parser.add_argument('--ids', default='25,94,143')
    parser.add_argument('--all151', action='store_true')
    args = parser.parse_args(argv)
    if args.all151:
        ids = range(1,152)
    else:
        try:
            ids = sorted(set(int(x.strip()) for x in args.ids.split(',')))
        except ValueError:
            parser.error('--ids must be comma-separated integer species IDs')
        if not ids or min(ids)<1 or max(ids)>151:
            parser.error('--ids must be within 1..151')
    base = Path(args.out).resolve()
    results = [examine_species(base,species) for species in ids]
    tally = {s:sum(x['status']==s for x in results) for s in ('PASS','WARN','FAIL')}
    report = {'scope':'G1 PMD sheet/alias preflight (NOT Godot render acceptance)',
              'counts':tally,'checked':len(results),'species':results}
    folder = base/'reports'
    folder.mkdir(parents=True,exist_ok=True)
    (folder/'pmd_g1_preflight.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    for rec in results:
        issues = '; '.join(rec['issues'])
        print(f'#{rec["species"]:03d} {rec["status"]} {issues}')
    print(f'G1 PREFLIGHT PASS={tally["PASS"]} WARN={tally["WARN"]} FAIL={tally["FAIL"]} / {len(results)}')
    return 0 if tally['FAIL']==0 else 2

if __name__ == '__main__':
    sys.exit(run())
