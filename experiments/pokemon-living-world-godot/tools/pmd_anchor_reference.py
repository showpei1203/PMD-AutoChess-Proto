"""Dependency-free algorithm reference for the G1.2.1 PMD alignment formulas.

Used solely for offline synthetic tests, not to render or ship copyrighted art.
Native PMD Shadow.png white = official shadow center; alpha fallback is visual
and may not preserve flight/jump height. See PMD Sprite Format docs.
"""
from __future__ import annotations
from dataclasses import dataclass

Color = tuple[int, int, int, int]

@dataclass(frozen=True)
class AnchorResult:
    point: tuple[float, float]
    source: str
    bounds: tuple[int, int, int, int] | None


def detect_alpha_bounds(rgba: list[list[Color]], threshold: int = 26) -> tuple[int, int, int, int] | None:
    """Return (x,y,width,height) of visible pixels. Threshold matches >0.10 alpha."""
    hits = [(x, y) for y, row in enumerate(rgba) for x, pixel in enumerate(row) if pixel[3] > threshold]
    if not hits:
        return None
    xs, ys = zip(*hits)
    return min(xs), min(ys), max(xs) - min(xs) + 1, max(ys) - min(ys) + 1


def detect_shadow_center(shadow: list[list[Color]]) -> tuple[float, float] | None:
    """Only genuinely white shadow marker pixels; reject green/red/blue components."""
    pts = [(float(x) + .5, float(y) + .5)
           for y, row in enumerate(shadow) for x, p in enumerate(row)
           if p[3] > 128 and min(p[:3]) > 239]
    if not 1 <= len(pts) <= 16:
        return None
    return (sum(p[0] for p in pts)/len(pts), sum(p[1] for p in pts)/len(pts))


def find_reference(sprite: list[list[Color]], shadow: list[list[Color]] | None = None) -> AnchorResult:
    if not sprite or not sprite[0]:
        raise ValueError('sprite cannot be empty')
    h, w = len(sprite), len(sprite[0])
    bounds = detect_alpha_bounds(sprite)
    alpha_y = float(bounds[1] + bounds[3]) if bounds else float(h)
    center = detect_shadow_center(shadow) if shadow else None
    if center is not None:
        return AnchorResult(center, 'PMD_SHADOW_CENTER', bounds)
    return AnchorResult((w/2, alpha_y), 'ALPHA_BOTTOM_FALLBACK' if bounds else 'EMPTY_FRAME_FALLBACK', bounds)


def godot_position(target: tuple[float, float], frame_size: tuple[float, float],
                   reference: tuple[float, float], scale: float) -> tuple[float, float]:
    """Godot centered AnimatedSprite2D: pixel(ref) must appear at screen target."""
    return (target[0] + (frame_size[0]/2 - reference[0])*scale,
            target[1] + (frame_size[1]/2 - reference[1])*scale)
