#!/usr/bin/env python3
"""Zip local G2 diagnostic text files only; never include sprite content."""
from __future__ import annotations
import argparse
from pathlib import Path
import zipfile

NAME = 'PLW_G22_RUNTIME_LAST.log'
OUTPUT = 'PLW_G22_DIAGNOSTICS_TO_SHARE.zip'

def collect(root: Path) -> Path:
    reports = root / 'reports'
    log = reports / NAME
    if not log.is_file():
        raise FileNotFoundError(f'No G2 runtime log at {log}; run scenes/ecology_animation_lab.tscn using F6')
    destination = reports / OUTPUT
    with zipfile.ZipFile(destination, 'w', compression=zipfile.ZIP_DEFLATED) as archive:
        archive.write(log, arcname=NAME)
        archive.writestr('HOW_TO_READ.txt', 'G2.2 runtime diagnostic log (user Surface). Upload this zip to ChatGPT. No Pokémon sprite files included.\n')
    return destination

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Package local G2 runtime log (no art)')
    parser.add_argument('--root', type=Path, default=Path('.'))
    args = parser.parse_args()
    try:
        out = collect(args.root.resolve())
        print(f'G2 LOG ZIP READY: {out}')
    except (FileNotFoundError, OSError) as exc:
        print(f'G2 LOG NOT FOUND: {exc}')
        raise SystemExit(2)
