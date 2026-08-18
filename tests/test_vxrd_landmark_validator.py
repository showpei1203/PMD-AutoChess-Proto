#!/usr/bin/env python3
from __future__ import annotations
import importlib.util
import tempfile
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
VALIDATOR = ROOT / 'tools' / 'asset_validator' / 'validate_vxrd_landmark_atlas.py'
spec = importlib.util.spec_from_file_location('vxrd_validator', VALIDATOR)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


def make_valid(path: Path):
    im = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for cy in range(2):
        for cx in range(2):
            x = cx * 32 + 8
            y = cy * 32 + 8
            d.rectangle((x, y, x + 15, y + 15), fill=(120, 120, 120, 255))
    im.save(path)


def require(cond, label):
    if not cond:
        raise AssertionError(label)


def main():
    with tempfile.TemporaryDirectory() as td:
        td = Path(td)

        good = td / 'good.png'
        make_valid(good)
        r = mod.validate(good)
        require(r['pass'], 'valid_rgba_64x64_should_pass')

        wrong_size = td / 'wrong_size.png'
        Image.new('RGBA', (32, 32), (0, 0, 0, 0)).save(wrong_size)
        r = mod.validate(wrong_size)
        require(not r['pass'], 'wrong_size_should_fail')

        wrong_mode = td / 'wrong_mode.png'
        Image.new('RGB', (64, 64), (255, 255, 255)).save(wrong_mode)
        r = mod.validate(wrong_mode)
        require(not r['pass'], 'non_rgba_should_fail')

        empty_cell = td / 'empty_cell.png'
        im = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        # only three populated cells
        for cx, cy in [(0, 0), (1, 0), (0, 1)]:
            x = cx * 32 + 8
            y = cy * 32 + 8
            d.rectangle((x, y, x + 15, y + 15), fill=(120, 120, 120, 255))
        im.save(empty_cell)
        r = mod.validate(empty_cell)
        require(not r['pass'], 'empty_cell_should_fail')

        print('RESULT=PASS')
        print('SYNTHETIC_CASES=4/4')
        print('BINARY_FIXTURES_COMMITTED=0')


if __name__ == '__main__':
    main()
