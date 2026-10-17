"""Unit tests use synthetic PNG bytes only, never Nintendo or PMD art."""
from __future__ import annotations
import io
from pathlib import Path
import struct
import sys
import tempfile
import unittest
import zipfile
import zlib

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from pmd_asset_audit import (AssetSource, audit, check_png,
                             normalize_asset_path, parse_reference_paths)


def fake_png() -> bytes:
    def chunk(name: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + name + data + struct.pack(">I", zlib.crc32(name + data) & 0xffffffff)
    rgba = b"\x00" + bytes([128, 222, 1, 255])
    return (b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(rgba))
            + chunk(b"IEND", b""))


class PathTests(unittest.TestCase):
    def test_android_path(self):
        self.assertEqual(normalize_asset_path("/storage/emulated/0/foo/pmd_idle_battle_sprites/motion/025_player_attack.png"), "motion/025_player_attack.png")

    def test_relative_path(self):
        self.assertEqual(normalize_asset_path("sprites/094_enemy.png"), "sprites/094_enemy.png")

    def test_traversal_refusal(self):
        for path in ("../private/a.png", "motion/../a.png", "/tmp/no_marker.png", "C:\\Windows\\a.png"):
            with self.subTest(path=path), self.assertRaises(ValueError):
                normalize_asset_path(path)

    def test_reference_duplicate(self):
        _, errors = parse_reference_paths("motion/025_player_attack.png\nMOTION/025_player_attack.png\n")
        self.assertEqual(len(errors), 1)


class PngTests(unittest.TestCase):
    def test_good_png(self):
        self.assertEqual(check_png(fake_png()), (1, 1))

    def test_bad_checksum(self):
        b = bytearray(fake_png())
        b[-5] ^= 1
        with self.assertRaises(ValueError):
            check_png(bytes(b))

    def test_missing_iend(self):
        with self.assertRaises(ValueError):
            check_png(fake_png()[:-12])


class AuditTests(unittest.TestCase):
    def test_zip_audit_counts_and_private_staging(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            archive = root / "source.zip"
            with zipfile.ZipFile(archive, "w") as z:
                z.writestr("FILE_LIST.txt", "\n".join([
                    "pmd_idle_battle_sprites/sprites/025_player.png",
                    "pmd_idle_battle_sprites/sprites/094_enemy.png",
                    "pmd_idle_battle_sprites/sprites/143_player.png",
                    "pmd_idle_battle_sprites/motion/025_player_attack.png",
                ]))
                z.writestr("pmd_idle_battle_sprites/sprites/025_player.png", fake_png())
                z.writestr("pmd_idle_battle_sprites/motion/025_player_attack.png", fake_png())
            data = audit(archive, root / "out", stage_dir=root / "private")
            self.assertEqual(data["png_status_counts"], {"PRESENT": 2, "MISSING": 2})
            self.assertEqual(data["species_ids_with_verified_battle_sprite"], [25])
            self.assertTrue((root / "private/sprites/025_player.png").exists())
            self.assertFalse(data["g0_binary_assets_complete"])

    def test_corrupt_png_flagged(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            a = root / "archive.zip"
            with zipfile.ZipFile(a, "w") as z:
                z.writestr("FILE_LIST.txt", "sprites/025_player.png\n")
                z.writestr("sprites/025_player.png", b"garbage")
            data = audit(a, root / "out")
            self.assertEqual(data["png_status_counts"], {"INVALID": 1})

    def test_duplicate_entry_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            a = root / "archive.zip"
            with zipfile.ZipFile(a, "w") as z:
                z.writestr("FILE_LIST.txt", "sprites/025_player.png")
                z.writestr("sprites/025_player.png", fake_png())
                z.writestr("sprites/025_player.png", fake_png())
            data = audit(a, root / "out")
            self.assertTrue(data["source_errors"])
            self.assertFalse(data["g0_binary_assets_complete"])

if __name__ == "__main__":
    unittest.main()

