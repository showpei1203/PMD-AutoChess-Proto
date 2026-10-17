#!/usr/bin/env python3
"""Audit the locally downloaded 151 PMDCollab species for G1.1 gallery.

This report contains species IDs, readiness states, original credits availability,
and missing-action reasons ONLY. It never copies, publishes, or embeds sprite art.
"""
from __future__ import annotations
import argparse
import csv
import json
from pathlib import Path
import sys

from pmd_g1_preflight import examine_species

TOTAL = 151
PAGE_SIZE = 3


def roster_page(page: int, total: int = TOTAL, size: int = PAGE_SIZE) -> list[int]:
    """Zero-indexed page of Kanto Pokédex numbers, no phantom 152/153."""
    if total < 1 or size < 1 or not 0 <= page < (total + size - 1) // size:
        raise ValueError('Invalid roster page or size')
    start = page * size + 1
    return list(range(start, min(start + size, total + 1)))


def report_rows(records: list[dict]) -> list[dict]:
    result = []
    for item in records:
        animations = item['animations']
        result.append({
            'dex': f"{item['species']:03d}",
            'status': item['status'],
            'idle': animations.get('Idle', {}).get('status', 'UNVALIDATED'),
            'walk': animations.get('Walk', {}).get('status', 'UNVALIDATED'),
            'attack': animations.get('Attack', {}).get('status', 'UNVALIDATED'),
            'idle_from': animations.get('Idle', {}).get('source_action', ''),
            'walk_from': animations.get('Walk', {}).get('source_action', ''),
            'attack_from': animations.get('Attack', {}).get('source_action', ''),
            'credits_available': item['credits'],
            'issues': ' | '.join(item['issues']),
        })
    return result


def run(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description='151-species animation readiness matrix (no art exported)')
    ap.add_argument('--root', default='.', help='Godot project directory')
    ap.add_argument('--first', type=int, default=1)
    ap.add_argument('--last', type=int, default=151)
    args = ap.parse_args(argv)
    if not (1 <= args.first <= args.last <= TOTAL):
        ap.error('--first/--last must satisfy 1 <= first <= last <= 151')
    root = Path(args.root).resolve()
    records = [examine_species(root, dex) for dex in range(args.first, args.last + 1)]
    rows = report_rows(records)
    counts = {key: sum(item['status'] == key for item in records) for key in ('PASS', 'WARN', 'FAIL')}
    output = root / 'reports'
    output.mkdir(parents=True, exist_ok=True)
    payload = {
        'description': 'G1.1 PMD 151 roster preflight, not Godot animation playback acceptance',
        'first': args.first, 'last': args.last, 'count': len(records),
        'counts': counts, 'roster': rows,
    }
    (output / 'pmd_roster_report.json').write_text(json.dumps(payload, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    with (output / 'pmd_roster_report.csv').open('w', encoding='utf-8-sig', newline='') as file:
        writer = csv.DictWriter(file, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)
    for r in rows:
        if r['status'] != 'PASS':
            print(f"#{r['dex']} {r['status']} {r['issues']}")
    print(f"G1.1 ROSTER PRECHECK: PASS={counts['PASS']} WARN={counts['WARN']} FAIL={counts['FAIL']} / {len(rows)}")
    print(f"Reports: {output / 'pmd_roster_report.json'} and {output / 'pmd_roster_report.csv'}")
    return 0 if counts['FAIL'] == 0 else 2


if __name__ == '__main__':
    sys.exit(run())
