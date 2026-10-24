#!/usr/bin/env python3
"""Generate the Material 3 PhotoTag icon.

A deep teal tonal surface with a white location pin whose lens reads as a
camera. Rendered at 4x and downsampled for clean edges.

Usage:
    python3 tool/make_icon.py
Outputs:
    assets/icon/icon.png        1024x1024 legacy / iOS icon
    assets/icon/foreground.png  1024x1024 adaptive-icon foreground
    docs/icon.png               web / store icon
"""
from __future__ import annotations

import math
import shutil
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
SIZE = 1024
SS = 4  # supersampling factor
BG = (0, 105, 109)  # Material teal
BG_LIGHT = (10, 127, 130)
WHITE = (255, 255, 255)
MINT = (204, 251, 241)
DARK = (0, 80, 84)


def _radial_background(size: int) -> Image.Image:
    # Cheap radial highlight: blend the light tone over the base tone.
    mask = Image.radial_gradient("L").resize((size, size), Image.Resampling.BICUBIC)
    base = Image.new("RGB", (size, size), BG)
    light = Image.new("RGB", (size, size), BG_LIGHT)
    return Image.composite(light, base, mask)


def _transform(x: float, y: float, size: int, scale: float) -> tuple[float, float]:
    s = size / 1024 * scale
    return (size / 2 + (x - 512) * s, size / 2 + (y - 512) * s)


def _rad(size: int, value: float, scale: float) -> float:
    return value * size / 1024 * scale


def _pin_mask(size: int, scale: float = 1.0) -> Image.Image:
    """White pin silhouette on a transparent canvas."""
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)

    cx, cy = _transform(512, 420, size, scale)
    r = _rad(size, 200, scale)
    tip_y = _transform(512, 820, size, scale)[1]

    # Circle + tangent triangle = a smooth location pin.
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=255)
    d = tip_y - cy
    angle = math.acos(max(-1.0, min(1.0, r / d)))
    for sign in (-1, 1):
        tx = cx + sign * r * math.cos(angle)
        ty = cy + r * math.sin(angle)
        draw.polygon(
            [(cx, tip_y), (tx, ty), (cx - sign * r * math.cos(angle), ty)],
            fill=255,
        )
    return mask


def _draw_lens(draw: ImageDraw.ImageDraw, size: int, scale: float) -> None:
    cx, cy = _transform(512, 420, size, scale)
    # Camera-lens aperture inside the pin.
    r = _rad(size, 92, scale)
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=BG)
    r = _rad(size, 74, scale)
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=MINT)
    r = _rad(size, 46, scale)
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=DARK)
    r = _rad(size, 26, scale)
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=MINT)
    r = _rad(size, 12, scale)
    hx, hy = _transform(482, 390, size, scale)
    draw.ellipse((hx - r, hy - r, hx + r, hy + r), fill=WHITE)


def _glyph(size: int, scale: float = 1.0) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    mask = _pin_mask(size, scale)
    canvas.paste(Image.new("RGBA", (size, size), WHITE + (255,)), (0, 0), mask)
    _draw_lens(ImageDraw.Draw(canvas), size, scale)
    return canvas


def main() -> None:
    big = SIZE * SS

    # Opaque launcher icon.
    bg = _radial_background(big).convert("RGBA")
    bg.alpha_composite(_glyph(big, 1.0))
    icon = bg.resize((SIZE, SIZE), Image.Resampling.LANCZOS)

    # Adaptive foreground stays transparent; the launcher supplies the color.
    # Scale it up so the 16% adaptive-icon inset leaves the same visual size
    # as the legacy/iOS icon.
    foreground = _glyph(big, 1.47).resize((SIZE, SIZE), Image.Resampling.LANCZOS)

    (ROOT / "assets" / "icon").mkdir(parents=True, exist_ok=True)
    icon.save(ROOT / "assets" / "icon" / "icon.png", "PNG", optimize=True)
    foreground.save(ROOT / "assets" / "icon" / "foreground.png", "PNG", optimize=True)
    shutil.copyfile(ROOT / "assets" / "icon" / "icon.png", ROOT / "docs" / "icon.png")
    print("Wrote assets/icon/icon.png, assets/icon/foreground.png, docs/icon.png")


if __name__ == "__main__":
    main()
