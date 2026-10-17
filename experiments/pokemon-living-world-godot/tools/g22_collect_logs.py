#!/usr/bin/env python3
"""G2.2 log collector: always create an actionable ZIP; never include sprite art."""
from __future__ import annotations
import argparse
from pathlib import Path
import sys
import zipfile

NAME = 'PLW_G22_RUNTIME_LAST.log'
OUTPUT = 'PLW_G22_DIAGNOSTICS_TO_SHARE.zip'
DIAG_NAME = 'G22_MISSING_LOG_DIAGNOSIS.txt'
PRIOR_NAMES = ('PLW_G21_RUNTIME_LAST.log', 'PLW_G2_RUNTIME_LAST.log')


def diagnosis(root: Path) -> str:
    report_dir = root / 'reports'
    lines = [
        'RESULT: G2.2 runtime log is NOT FOUND.',
        'EXPECTED: ' + str(report_dir / NAME), '',
        'This is not enough evidence to conclude that G2.2 rendering code is broken.',
        'The runner might have started G2.1/G2.0; alternatively the G2.2 scene',
        'may have failed before its logger initialized.', '',
    ]
    for prior in PRIOR_NAMES:
        path = report_dir / prior
        if path.is_file():
            try:
                with path.open('r', encoding='utf-8', errors='replace') as fh:
                    head = ''.join([fh.readline() for _ in range(12)])
                tags = [row.strip() for row in head.splitlines() if 'LOGGER_READY' in row]
            except OSError as exc:
                tags = ['unable to read: ' + str(exc)]
            lines += [
                'OLD LOG FOUND: ' + str(path),
                'OLD BUILD: ' + ('; '.join(tags) if tags else 'No LOGGER_READY in first lines'),
                'NOTE: Old logs do not establish what scene ran this time.', '',
            ]
    lines += [
        'HOW TO REPRODUCE CORRECTLY:',
        '1. Close old game windows. In Godot FileSystem DOUBLE-CLICK',
        '   scenes/ecology_animation_lab.tscn (a single-click only selects).',
        '2. Confirm top active tab ecology_animation_lab and Scene tree root',
        '   EcologyAnimationLab with Diagnostics child. Then press F6, NOT F5.',
        '3. Confirm G2.2.1 or later version marker, tick counter increasing,',
        '   and Godot Output line [PLW-G2-LOG] FILE <actual absolute log path>.',
        '4. Wait 20-30 sec, stop game and run RUN_G22_COLLECT_LOG_WINDOWS.bat again.',
        '5. If it still fails, send this diagnostic ZIP plus screenshot of the',
        '   first red Godot parser/runtime error and Output FILE line.',
        '6. If the Output FILE path starts with Godot user:// (AppData),',
        '   attach that exact .log as displayed by Godot; reports fallback',
        '   is used only if writing inside the project failed.', '',
        'This diagnostic package never contains Pokémon image assets.',
    ]
    return '\n'.join(lines) + '\n'


def collect(root: Path) -> Path:
    reports = root / 'reports'
    reports.mkdir(parents=True, exist_ok=True)
    log = reports / NAME
    destination = reports / OUTPUT
    with zipfile.ZipFile(destination, 'w', compression=zipfile.ZIP_DEFLATED) as archive:
        if log.is_file():
            archive.write(log, arcname=NAME)
            archive.writestr('HOW_TO_READ.txt',
                'G2.2 runtime diagnostic log (Surface). Share with ChatGPT. '
                'No copyrighted sprite files included.\n')
        else:
            archive.writestr(DIAG_NAME, diagnosis(root))
            archive.writestr('HOW_TO_READ.txt',
                'G2.2 runtime log NOT FOUND. Share G22_MISSING_LOG_DIAGNOSIS.txt '
                'and an active-scene screenshot with ChatGPT.\n')
    return destination


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Package G2.2 runtime log or missing-log report (no art)')
    parser.add_argument('--root', type=Path, default=Path('.'))
    args = parser.parse_args()
    try:
        project = args.root.resolve()
        out = collect(project)
        print('G22 DIAGNOSTIC ZIP READY: ' + str(out))
        if not (project / 'reports' / NAME).is_file():
            print('G2.2 LOG NOT FOUND: ZIP contains detailed troubleshooting steps instead.')
            sys.exit(2)
        print('G22 LOG FOUND: ZIP contains runtime evidence.')
    except OSError as exc:
        print('G22 COLLECT FAILED: ' + str(exc))
        sys.exit(3)
