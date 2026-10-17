#!/usr/bin/env python3
"""Pokémon Living World: conservative PMD file inventory & staging utility.

No binary Pokémon assets are distributed. This utility audits privately supplied
PMD folders/ZIPs against source inventory, and may stage *verified* local PNGs.
Standard-library only; Python 3.10+; does not mutate the original archive.
"""
from __future__ import annotations
import argparse
from collections import Counter, defaultdict
from dataclasses import asdict, dataclass
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import struct
import sys
import zipfile
import zlib

SOURCE_MARKER = "pmd_idle_battle_sprites/"
EXPECTED_ID_SET = set(range(1, 152))
PNG_SIG = b"\x89PNG\r\n\x1a\n"
MAX_SINGLE_FILE = 256 * 1024 * 1024
ACTION_RE = re.compile(r"^(motion|shadow)/(\d{3})_(player|enemy)_([a-z0-9_]+)\.png$", re.I)
SPRITE_RE = re.compile(r"^(sprites|static)/(\d{3})_(player|enemy)\.png$", re.I)
DEX_RE = re.compile(r"^(dex|dex70)/(\d{3})\.png$", re.I)


def sha256_bytes(blob: bytes) -> str:
    return hashlib.sha256(blob).hexdigest()


def normalize_asset_path(path: str) -> str:
    path = path.replace("\\", "/").strip()
    if not path or "\x00" in path:
        raise ValueError("empty or NUL path")
    # Original FILE_LIST contains absolute Android paths, so only take the
    # scoped subpath following the known MOD folder marker.
    marker_idx = path.lower().find(SOURCE_MARKER)
    if marker_idx >= 0:
        path = path[marker_idx + len(SOURCE_MARKER):]
    elif path.startswith("/") or re.match(r"^[a-zA-Z]:/", path):
        raise ValueError("unexpected absolute path")
    path = path.removeprefix("./")
    pp = PurePosixPath(path)
    if not pp.parts or any(part in ("", ".", "..") for part in path.split("/")):
        raise ValueError("unsafe path")
    if pp.is_absolute() or ":" in pp.parts[0]:
        raise ValueError("unsafe absolute path")
    return str(pp)


def parse_reference_paths(raw: str) -> tuple[list[str], list[str]]:
    candidates, errors, seen = [], [], set()
    for line_number, line in enumerate(raw.splitlines(), 1):
        if not line.strip():
            continue
        try:
            rel = normalize_asset_path(line)
            key = rel.casefold()
            if key in seen:
                errors.append(f"line {line_number}: duplicate case-folded path: {rel}")
            else:
                seen.add(key)
                candidates.append(rel)
        except ValueError as exc:
            errors.append(f"line {line_number}: {exc}")
    return candidates, errors


def check_png(blob: bytes) -> tuple[int, int]:
    """Validate signature, IHDR and all PNG chunk CRCs, reject truncated files.
    This verifies container integrity but does not equal full raster decoding.
    """
    if len(blob) < 45 or blob[:8] != PNG_SIG:
        raise ValueError("PNG signature/length invalid")
    pos = 8
    width = height = 0
    count = 0
    found_end = False
    found_image_data = False
    while pos + 12 <= len(blob):
        length = struct.unpack(">I", blob[pos:pos + 4])[0]
        if length > MAX_SINGLE_FILE or pos + 12 + length > len(blob):
            raise ValueError("invalid or truncated PNG chunk")
        chunk_type = blob[pos + 4:pos + 8]
        chunk_data = blob[pos + 8:pos + 8 + length]
        checksum = struct.unpack(">I", blob[pos + 8 + length:pos + 12 + length])[0]
        actual = zlib.crc32(chunk_type + chunk_data) & 0xFFFFFFFF
        if checksum != actual:
            raise ValueError("PNG chunk CRC mismatch")
        if count == 0:
            if chunk_type != b"IHDR" or length != 13:
                raise ValueError("invalid PNG IHDR")
            width, height = struct.unpack(">II", chunk_data[:8])
            if not (0 < width <= 32768 and 0 < height <= 32768):
                raise ValueError("invalid PNG dimensions")
        if chunk_type == b"IDAT":
            found_image_data = True
        if chunk_type == b"IEND":
            found_end = True
            if pos + 12 + length != len(blob):
                raise ValueError("trailing data after PNG IEND")
            break
        pos += 12 + length
        count += 1
    if not found_end:
        raise ValueError("PNG has no IEND")
    if not found_image_data:
        raise ValueError("PNG has no IDAT")
    return width, height


class AssetSource:
    def __init__(self, path: Path):
        self.path = path
        self._zip: zipfile.ZipFile | None = None
        self.entries: dict[str, str | Path] = {}
        known_paths: set[str] = set()
        self.errors: list[str] = []
        if path.is_file() and zipfile.is_zipfile(path):
            self._zip = zipfile.ZipFile(path)
            for item in self._zip.infolist():
                if item.is_dir():
                    continue
                try:
                    rel = normalize_asset_path(item.filename)
                    if item.file_size > MAX_SINGLE_FILE:
                        raise ValueError("file exceeds per-entry limit")
                except ValueError as exc:
                    self.errors.append(f"source ZIP {item.filename}: {exc}")
                    continue
                if rel.casefold() in known_paths:
                    self.errors.append(f"duplicate ZIP asset path: {rel}")
                else:
                    self.entries[rel] = item.filename
                    known_paths.add(rel.casefold())
        elif path.is_dir():
            for item in path.rglob("*"):
                if not item.is_file():
                    continue
                try:
                    rel = normalize_asset_path(item.relative_to(path).as_posix())
                    if item.stat().st_size > MAX_SINGLE_FILE:
                        raise ValueError("file exceeds per-entry limit")
                except ValueError as exc:
                    self.errors.append(f"source folder {item}: {exc}")
                    continue
                if rel.casefold() in known_paths:
                    self.errors.append(f"duplicate asset path: {rel}")
                else:
                    self.entries[rel] = item
                    known_paths.add(rel.casefold())
        else:
            raise ValueError("--source must be an existing directory or ZIP")

    def read(self, rel: str) -> bytes:
        obj = self.entries[rel]
        if isinstance(obj, Path):
            if obj.stat().st_size > MAX_SINGLE_FILE:
                raise ValueError("file exceeds size limit")
            return obj.read_bytes()
        assert self._zip is not None
        return self._zip.read(obj)

    def close(self) -> None:
        if self._zip is not None:
            self._zip.close()


@dataclass
class AssetRow:
    path: str
    category: str
    species_id: int | None
    orientation: str
    action: str
    status: str
    width: int | None = None
    height: int | None = None
    sha256: str | None = None
    reason: str = ""


def categorize(rel: str) -> tuple[str, int | None, str, str]:
    m = ACTION_RE.fullmatch(rel)
    if m:
        return (m.group(1).lower(), int(m.group(2)), m.group(3).lower(), m.group(4).lower())
    m = SPRITE_RE.fullmatch(rel)
    if m:
        return (m.group(1).lower(), int(m.group(2)), m.group(3).lower(), "base")
    m = DEX_RE.fullmatch(rel)
    if m:
        return (m.group(1).lower(), int(m.group(2)), "none", "index")
    return (rel.split("/")[0], None, "none", "unknown")


def audit(source: Path, output: Path, reference_file: Path | None = None,
          stage_dir: Path | None = None) -> dict:
    asset_source = AssetSource(source)
    try:
        if reference_file:
            raw = reference_file.read_text(encoding="utf-8-sig")
        elif "FILE_LIST.txt" in asset_source.entries:
            raw = asset_source.read("FILE_LIST.txt").decode("utf-8-sig")
        else:
            raise ValueError("No FILE_LIST.txt found: pass --reference explicitly")
        references, ref_errors = parse_reference_paths(raw)
        actual_paths = set(asset_source.entries)
        rows: list[AssetRow] = []
        for rel in references:
            if not rel.lower().endswith(".png"):
                continue
            category, number, orientation, action = categorize(rel)
            row = AssetRow(path=rel, category=category, species_id=number,
                           orientation=orientation, action=action,
                           status="MISSING")
            if rel in actual_paths:
                try:
                    b = asset_source.read(rel)
                    row.sha256 = sha256_bytes(b)
                    row.width, row.height = check_png(b)
                    row.status = "PRESENT"
                    if stage_dir:
                        dest = stage_dir.joinpath(*PurePosixPath(rel).parts)
                        dest.parent.mkdir(parents=True, exist_ok=True)
                        dest.write_bytes(b)
                except (ValueError, OSError, zipfile.BadZipFile) as exc:
                    row.status = "INVALID"
                    row.reason = str(exc)
            rows.append(row)
        output.mkdir(parents=True, exist_ok=True)
        counts = Counter(row.status for row in rows)
        categories = Counter(row.category for row in rows)
        ids = sorted({row.species_id for row in rows if row.species_id in EXPECTED_ID_SET})
        verified_ids = sorted({row.species_id for row in rows if row.species_id in EXPECTED_ID_SET and row.status == "PRESENT"})
        observed = {row.species_id for row in rows if row.category == "sprites" and row.status == "PRESENT"}
        verified_renderable = sorted(x for x in EXPECTED_ID_SET if x in observed)
        report = {
            "schema_version": 1,
            "source": source.name,
            "source_archive_sha256": sha256_bytes(source.read_bytes()) if source.is_file() else None,
            "source_file_count": len(asset_source.entries),
            "source_errors": asset_source.errors + ref_errors,
            "referenced_png_count": len(rows),
            "png_status_counts": dict(counts),
            "png_categories": dict(categories),
            "species_ids_in_reference": ids,
            "species_ids_with_some_verified_png": verified_ids,
            "species_ids_with_verified_battle_sprite": verified_renderable,
            "g0_binary_assets_complete": len(ids) == 151 and counts.get("MISSING", 0) == 0 and counts.get("INVALID", 0) == 0 and not asset_source.errors and not ref_errors,
            "pixel_decode_verified": False,
            "eight_direction_animation_verified": False,
            "note": "PNG structural integrity check (signature, IHDR, chunk CRC, IEND) only. PMD player/enemy is not a verified direction count.",
        }
        import csv
        with (output / "asset_matrix.csv").open("w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(f, fieldnames=list(AssetRow.__dataclass_fields__))
            w.writeheader()
            w.writerows(asdict(row) for row in rows)
        (output / "audit_summary.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        return report
    finally:
        asset_source.close()


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--source", required=True, type=Path, help="Private PMD asset directory or ZIP")
    ap.add_argument("--reference", type=Path, help="Original FILE_LIST.txt when not in ZIP")
    ap.add_argument("--out", required=True, type=Path, help="Output report directory")
    ap.add_argument("--stage-private", type=Path, help="Optional private staged PNG location (never commit)")
    ap.add_argument("--require-complete", action="store_true", help="exit 2 until all PNGs present/valid")
    args = ap.parse_args()
    try:
        report = audit(args.source, args.out, args.reference, args.stage_private)
    except (ValueError, OSError, zipfile.BadZipFile) as exc:
        print(f"AUDIT FAILED: {exc}", file=sys.stderr)
        return 1
    print(json.dumps({k: v for k, v in report.items() if k not in ("species_ids_in_reference", "species_ids_with_some_verified_png", "species_ids_with_verified_battle_sprite")}, ensure_ascii=False, indent=2))
    if report["source_errors"]:
        return 2
    if args.require_complete and not report["g0_binary_assets_complete"]:
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())

