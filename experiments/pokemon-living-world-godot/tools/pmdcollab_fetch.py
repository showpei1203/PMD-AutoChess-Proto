#!/usr/bin/env python3
"""Fetch official-community PMDCollab sprite ZIPs into a LOCAL, ignored asset tree.

No artwork is checked into source control. Uses only Python 3.10+ standard library.
The PMDCollab art repo publishes CC BY-NC 4.0 and per-species credits.
The official PMD/Nintendo portions have independent third-party rights.
This is a non-commercial fan-game research downloader, not a redistribution grant.
"""
from __future__ import annotations
import argparse
from datetime import datetime, timezone
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import re
import sys
import time
import urllib.error
import urllib.request
import xml.etree.ElementTree as ET
import zipfile

try:
    from pmd_asset_audit import check_png
except ModuleNotFoundError:
    from tools.pmd_asset_audit import check_png

SPRITE_SERVER = 'https://spriteserver.pmdcollab.org/assets/{id}/sprites.zip'
CREDITS_SERVER = 'https://raw.githubusercontent.com/PMDCollab/SpriteCollab/master/sprite/{id}/credits.txt'
UPSTREAM = 'https://github.com/PMDCollab/SpriteCollab'
LICENSE = 'https://github.com/PMDCollab/SpriteCollab/blob/master/LICENSE.md'
MAX_DOWNLOAD_BYTES = 64 * 1024 * 1024
MAX_EXPANDED_BYTES = 128 * 1024 * 1024
MAX_FILES = 350
MAX_FILE_BYTES = 24 * 1024 * 1024
USER_AGENT = 'PokémonLivingWorld-AssetAudit/0.2 (+https://github.com/PMDCollab/SpriteCollab)'


def fetch_url(url: str, timeout: int = 60, retries: int = 2) -> bytes:
    error = None
    for attempt in range(retries + 1):
        try:
            req = urllib.request.Request(url, headers={'User-Agent': USER_AGENT})
            with urllib.request.urlopen(req, timeout=timeout) as response:
                data = response.read(MAX_DOWNLOAD_BYTES + 1)
            if len(data) > MAX_DOWNLOAD_BYTES:
                raise ValueError('HTTP response exceeds 64 MiB limit')
            return data
        except (OSError, urllib.error.URLError) as exc:
            error = exc
            if attempt < retries:
                time.sleep(min(2**attempt, 4))
    raise RuntimeError(f'Download failed for {url}: {error}')


def validate_member_path(name: str) -> str:
    if '\\' in name or '\x00' in name or name.startswith('/') or re.match(r'^[a-zA-Z]:', name):
        raise ValueError(f'Unsafe archive member name: {name!r}')
    pure = PurePosixPath(name)
    if not pure.parts or any(x in ('', '.', '..') for x in name.split('/')):
        raise ValueError(f'Unsafe archive path: {name!r}')
    return pure.as_posix()


def parse_animations(xml_content: bytes) -> list[dict]:
    root = ET.fromstring(xml_content)
    if root.tag != 'AnimData':
        raise ValueError(f'Invalid PMD XML root: {root.tag}')
    animations: list[dict] = []
    names: set[str] = set()
    for el in root.findall('./Anims/Anim'):
        name = (el.findtext('Name') or '').strip()
        if not name or name.casefold() in names:
            raise ValueError(f'Invalid/duplicated animation name: {name!r}')
        names.add(name.casefold())
        def number(tag: str) -> int | None:
            s = el.findtext(tag)
            return int(s) if s not in (None, '') else None
        durations = [int((e.text or '').strip()) for e in el.findall('./Durations/Duration')]
        if durations and (min(durations) < 1 or len(durations) > 128):
            raise ValueError(f'Invalid PMD frame durations: {name}')
        animations.append({'name': name, 'copy_of': el.findtext('CopyOf'),
                           'frame_width': number('FrameWidth'), 'frame_height': number('FrameHeight'),
                           'durations': durations, 'hit_frame': number('HitFrame'),
                           'return_frame': number('ReturnFrame'), 'rush_frame': number('RushFrame')})
    if not animations:
        raise ValueError('AnimData.xml has no animation definitions')
    return animations


def inspect_zip(blob: bytes) -> tuple[list[tuple[str, bytes]], list[dict]]:
    members: list[tuple[str, bytes]] = []
    names: set[str] = set()
    total = 0
    with zipfile.ZipFile(io.BytesIO(blob)) as zf:
        entries = [entry for entry in zf.infolist() if not entry.is_dir()]
        if len(entries) > MAX_FILES:
            raise ValueError('Too many source ZIP files')
        for entry in entries:
            name = validate_member_path(entry.filename)
            if name.casefold() in names:
                raise ValueError(f'Casefold duplicate: {name}')
            names.add(name.casefold())
            unix_type = (entry.external_attr >> 16) & 0o170000
            if unix_type == 0o120000:
                raise ValueError(f'Archive symlink rejected: {name}')
            if entry.file_size > MAX_FILE_BYTES:
                raise ValueError(f'Oversized file: {name}')
            total += entry.file_size
            if total > MAX_EXPANDED_BYTES:
                raise ValueError('Expanded archive exceeds limit')
            data = zf.read(entry)
            if len(data) != entry.file_size:
                raise ValueError(f'ZIP file length mismatch: {name}')
            if name.lower().endswith('.png'):
                check_png(data)
            members.append((name, data))
    xmls = [(n, b) for n,b in members if PurePosixPath(n).name == 'AnimData.xml']
    if len(xmls) != 1:
        raise ValueError(f'Expected exactly one AnimData.xml, found {len(xmls)}')
    animation_list = parse_animations(xmls[0][1])
    name_set = {PurePosixPath(n).name.casefold() for n,_ in members}
    if not ({'idle-anim.png', 'walk-anim.png'} <= name_set):
        raise ValueError('Missing mandatory Idle/Walk animation images')
    return members, animation_list


def stage_species(species_id: int, out: Path, fetcher=fetch_url,
                  sprite_url=SPRITE_SERVER, credits_url=CREDITS_SERVER,
                  replace: bool = False) -> dict:
    if not 1 <= species_id <= 151:
        raise ValueError('Species ID must be in 1..151')
    code = f'{species_id:04d}'
    dest = out / 'data' / 'raw' / 'pmdcollab' / code
    report_path = dest / 'provenance.json'
    if report_path.exists() and not replace:
        info = json.loads(report_path.read_text('utf-8'))
        if info.get('status') == 'SOURCE_VERIFIED':
            return {**info, 'cached': True}
    zipurl = sprite_url.format(id=code)
    raw_zip = fetcher(zipurl)
    members, animations = inspect_zip(raw_zip)
    crediturl = credits_url.format(id=code)
    try:
        credits = fetcher(crediturl).decode('utf-8-sig')
        credit_status = 'AVAILABLE'
    except (RuntimeError, OSError, UnicodeError) as exc:
        credits, credit_status = '', f'UNRESOLVED: {exc}'
    dest.mkdir(parents=True, exist_ok=True)
    for name, blob in members:
        filepath = dest.joinpath(*PurePosixPath(name).parts)
        filepath.parent.mkdir(parents=True, exist_ok=True)
        filepath.write_bytes(blob)
    if credits:
        (dest / 'credits_upstream.txt').write_text(credits, encoding='utf-8')
    entry = {
        'species_id': species_id, 'source': UPSTREAM,
        'sprite_url': zipurl, 'credits_url': crediturl, 'license_url': LICENSE,
        'fetched_utc': datetime.now(timezone.utc).isoformat(),
        'status': 'SOURCE_VERIFIED', 'credits_status': credit_status,
        'zip_sha256': hashlib.sha256(raw_zip).hexdigest(),
        'files': len(members), 'png_files': sum(n.lower().endswith('.png') for n,_ in members),
        'animations': animations,
        'file_hashes': {n: hashlib.sha256(b).hexdigest() for n,b in members},
    }
    report_path.write_text(json.dumps(entry, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    return entry


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description='Download PMDCollab non-commercial sprites with credit and integrity checks')
    ap.add_argument('--ids', help='Comma separated Pokédex species IDs, e.g. 25,94,143')
    ap.add_argument('--all151', action='store_true', help='Get every Kanto species 001..151')
    ap.add_argument('--out', default='.', help='Godot project root. Writes ignored data/raw/pmdcollab/')
    ap.add_argument('--replace', action='store_true', help='Redownload cached species')
    ap.add_argument('--plan', action='store_true', help='Print URLs only; no network, no files')
    ap.add_argument('--quiet', action='store_true')
    args = ap.parse_args(argv)
    if args.ids and args.all151:
        ap.error('Choose either --ids or --all151')
    try:
        ids = list(range(1,152)) if args.all151 else ([int(t.strip()) for t in args.ids.split(',')] if args.ids else [25,94,143])
    except ValueError:
        ap.error('--ids must be integers')
    if not ids or any(not (1 <= n <= 151) for n in ids):
        ap.error('IDs must be in range 1..151')
    ids = sorted(set(ids))
    if args.plan:
        for n in ids:
            print(f'{n:03d} {SPRITE_SERVER.format(id=f"{n:04d}")}')
        return 0
    output = Path(args.out).resolve()
    result = {'source': UPSTREAM, 'license': LICENSE, 'selected': ids, 'successful': [], 'failed': []}
    for i, species_id in enumerate(ids, 1):
        try:
            record = stage_species(species_id, output, replace=args.replace)
            result['successful'].append({'id': species_id, 'png_files': record['png_files'],
                                         'animations': len(record['animations']), 'credits': record['credits_status']})
            if not args.quiet:
                print(f'[{i}/{len(ids)}] #{species_id:03d} OK: {record["png_files"]} png, {len(record["animations"])} animations, credits={record["credits_status"]}')
        except (ValueError, OSError, RuntimeError, zipfile.BadZipFile, ET.ParseError) as exc:
            result['failed'].append({'id':species_id, 'error':str(exc)})
            print(f'[{i}/{len(ids)}] #{species_id:03d} FAIL: {exc}', file=sys.stderr)
        # Deliberately avoid hammering the community asset server.
        if i < len(ids):
            time.sleep(0.2)
    reports = output / 'reports'
    reports.mkdir(parents=True, exist_ok=True)
    (reports / 'pmdcollab_download_report.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    return 0 if not result['failed'] else 2

if __name__ == '__main__':
    sys.exit(main())