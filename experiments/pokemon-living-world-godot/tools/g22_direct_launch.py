#!/usr/bin/env python3
"""Start EXACTLY the G2.2 Godot scene and bundle console/engine/runtime logs.

Godot Windows portable builds may not be on PATH, so optionally select .exe
once. Run errors still produce a diagnostic ZIP with the expected scene path.
No downloaded PMD files are placed in the evidence archive.
"""
from __future__ import annotations
import argparse
import datetime as dt
import os
from pathlib import Path
import shutil
import subprocess
import sys
import zipfile

SCENE = 'res://scenes/ecology_animation_lab.tscn'
NAME = 'PLW_G22_RUNTIME_LAST.log'
BOOT = 'PLW_G22_GODOT_BOOT_LAST.log'
CONSOLE = 'PLW_G22_GODOT_CONSOLE_LAST.log'
REPORT = 'PLW_G22_DIRECT_LAUNCH_REPORT.txt'
PACKAGE = 'PLW_G22_DIRECT_DIAGNOSTICS_TO_SHARE.zip'
CACHE = 'PLW_G22_GODOT_EXECUTABLE.txt'


def identify_godot(root: Path, explicit: str = '') -> Path | None:
    reports = root / 'reports'
    entries: list[str] = []
    if explicit:
        entries.append(explicit)
    env = os.environ.get('GODOT_EXE', '')
    if env:
        entries.append(env)
    cache = reports / CACHE
    if cache.is_file():
        entries.append(cache.read_text(encoding='utf-8-sig').strip())
    for command in ('godot', 'godot4'):
        value = shutil.which(command)
        if value:
            entries.append(value)
    for base in [root, *list(root.parents)[:4]]:
        if base == base.parent:
            break  # never scan entire drive recursively
        entries.extend(str(p) for p in sorted(base.glob('Godot*.exe'))[:12])
        entries.extend(str(p) for p in sorted(base.glob('Godot*/*.exe'))[:12])
    for entry in entries:
        path = Path(entry.strip(' \"'))
        if path.is_file() and (path.suffix.lower() == '.exe' or os.name != 'nt'):
            # Prefer console EXE if present: Windows graphical EXE often
            # does not forward stdout/stderr to a terminal.
            stem = path.stem
            alternative = path.with_name(stem + '_console.exe')
            if alternative.is_file() and not stem.endswith('_console'):
                return alternative
            return path
    return None


def request_godot() -> Path | None:
    try:
        import tkinter as tk
        from tkinter import filedialog
        window = tk.Tk()
        window.withdraw()
        selected = filedialog.askopenfilename(
            title='Select your Godot 4.7.2 executable (once only)',
            filetypes=[('Godot executable', '*.exe'), ('All files', '*.*')],
        )
        window.destroy()
        return Path(selected) if selected else None
    except Exception as ex:
        print('File picker unavailable:', ex)
        if sys.stdin.isatty():
            value = input('Full path to Godot 4.7.2 executable: ').strip().strip('"')
            return Path(value) if value else None
        return None


def diagnostic_zip(root: Path, notes: str) -> Path:
    reports = root / 'reports'
    reports.mkdir(parents=True, exist_ok=True)
    (reports / REPORT).write_text(notes, encoding='utf-8')
    package = reports / PACKAGE
    with zipfile.ZipFile(package, 'w', compression=zipfile.ZIP_DEFLATED) as z:
        for filename in (REPORT, BOOT, CONSOLE, NAME):
            path = reports / filename
            if path.is_file():
                z.write(path, arcname=filename)
        z.writestr('HOW_TO_SHARE.txt',
            'This package contains only Godot startup/console/runtime TEXT logs, ' 
            'not Pokémon sprites. Attach the ZIP to the ChatGPT project.\n')
    return package


def execute(root: Path, requested_exe: str = '') -> tuple[int, Path]:
    reports = root / 'reports'
    reports.mkdir(parents=True, exist_ok=True)
    scene_file = root / 'scenes' / 'ecology_animation_lab.tscn'
    facts = ['PLW G2.2 DIRECT LAUNCH', 'timestamp=' + dt.datetime.now().isoformat(),
             'project=' + str(root), 'scene=' + SCENE]
    if not scene_file.is_file():
        facts.append('ERROR: G2.2 .tscn scene file missing. Fetch/Pull branch.')
        return 2, diagnostic_zip(root, '\n'.join(facts)+'\n')
    exe = identify_godot(root, requested_exe)
    if exe is None:
        print('Godot not automatically found. Please select the same Godot exe as your editor.')
        exe = request_godot()
    if exe is not None and exe.is_file() and exe.suffix.lower() == ".exe" and not exe.stem.endswith("_console"):
        console_build = exe.with_name(exe.stem + "_console.exe")
        if console_build.is_file():
            exe = console_build
    if exe is None or not exe.is_file():
        facts.append('ERROR: no Godot executable selected or found.')
        return 3, diagnostic_zip(root, '\n'.join(facts)+'\n')
    (reports / CACHE).write_text(str(exe), encoding='utf-8')
    facts.append('godot_exe=' + str(exe))
    runtime = reports / NAME
    if runtime.is_file():
        # Do not mistake a previous run for successful initialization now.
        old = reports / 'PLW_G22_RUNTIME_PREVIOUS.log'
        shutil.copy2(runtime, old)
        runtime.unlink()
        facts.append('previous_runtime_log_backed_up=' + str(old))
    for file in (BOOT, CONSOLE):
        (reports / file).write_text('', encoding='utf-8')
    args = [str(exe), '--path', str(root), '--verbose', '--log-file',
            str(reports / BOOT), SCENE]
    facts.append('argv=' + repr(args))
    print('Launching Godot EXACT G2.2 scene:', SCENE)
    print('Leave this CMD open, play for ~30 seconds, then close the GAME window.')
    print('Engine log:', reports / BOOT)
    code: int
    try:
        with (reports / CONSOLE).open('w', encoding='utf-8', errors='replace') as console:
            process = subprocess.Popen(args, cwd=root, stdout=console,
                                       stderr=subprocess.STDOUT)
            code = process.wait()
        facts.append('godot_exit_code=' + str(code))
    except OSError as exc:
        code = 4
        facts.append('ERROR launching Godot: ' + str(exc))
    facts.append('g22_runtime_log_created=' + str(runtime.is_file()))
    if runtime.is_file():
        header = runtime.read_text(encoding='utf-8', errors='replace').splitlines()[:15]
        facts.extend('runtime_header=' + line for line in header if 'LOGGER_READY' in line)
    else:
        facts.append('G22 runtime logger was NEVER initialized. Inspect BOOT/CONSOLE for parser or scene errors.')
    report_zip = diagnostic_zip(root, '\n'.join(facts) + '\n')
    print('DIAGNOSTIC ZIP READY:', report_zip)
    return (0 if runtime.is_file() and code == 0 else 5), report_zip


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    p.add_argument('--godot', default='')
    a = p.parse_args()
    rc, _ = execute(a.root.resolve(), a.godot)
    return rc


if __name__ == '__main__':
    sys.exit(main())
