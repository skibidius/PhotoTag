#!/usr/bin/env python3
"""Build 16:9 store screenshots from the portrait app screenshots.

RuStore asks for 16:9 (1920x1080) or 9:16 screenshots. The real app is
portrait-only, so we compose a Material You marketing frame around the actual
UI screenshots instead of cropping them.

Usage:
    python3 tool/make_store_screenshots.py
Output:
    docs/screenshots/{ru,en}/16x9/*.png
"""
from __future__ import annotations

import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
W, H = 1920, 1080
PHONE_H = 880
BEZEL = 14
RADIUS = 54
ACCENT = (13, 148, 136)
DARK = (15, 61, 58)
MUTED = (63, 95, 90)
BG_TOP = (243, 251, 249)
BG_BOTTOM = (209, 240, 234)

RU = [
    (
        "camera",
        "Снимайте с координатами",
        "Координаты, направление, высота и время — сразу на фото. Без ручной обработки.",
    ),
    (
        "watermark",
        "Вотермарка под ваш стиль",
        "Координаты, адрес, заметка, автор и номер снимка. Три стиля на выбор.",
    ),
    (
        "projects",
        "Проекты и экспорт",
        "Группируйте снимки по объектам и заказчикам. Экспорт в ZIP в один тап.",
    ),
    (
        "gallery",
        "Галерея как в Google Photos",
        "Свайпы, плавный зум, свайп вверх — вся информация о снимке.",
    ),
    (
        "settings",
        "Гибкая настройка",
        "Стиль, поля вотермарки, качество съёмки и отдельный счётчик для каждого проекта.",
    ),
]

EN = [
    (
        "camera",
        "Shoot with coordinates",
        "Coordinates, bearing, altitude and time — baked right into the photo.",
    ),
    (
        "watermark",
        "A watermark in your style",
        "Coordinates, address, note, author and photo number. Three styles.",
    ),
    (
        "projects",
        "Projects and export",
        "Group shots by site or client. One-tap ZIP export.",
    ),
    (
        "gallery",
        "A Google Photos-style gallery",
        "Swipe to browse, pinch to zoom, swipe up for details.",
    ),
    (
        "settings",
        "Make it yours",
        "Watermark fields, capture quality and a separate counter per project.",
    ),
]


def font(name: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(ROOT / "assets" / "fonts" / name), size)


def gradient() -> Image.Image:
    strip = Image.new("RGB", (1, H))
    px = strip.load()
    for y in range(H):
        t = y / (H - 1)
        px[0, y] = tuple(
            round(BG_TOP[i] * (1 - t) + BG_BOTTOM[i] * t) for i in range(3)
        )
    return strip.resize((W, H), Image.Resampling.BILINEAR)


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255
    )
    return mask


def draw_wrapped(
    draw: ImageDraw.ImageDraw,
    text: str,
    fnt: ImageFont.FreeTypeFont,
    x: int,
    y: int,
    max_width: int,
    fill: tuple[int, int, int],
    line_gap: int,
) -> int:
    words = text.split()
    lines: list[str] = []
    current = ""
    for word in words:
        candidate = f"{current} {word}".strip()
        if draw.textlength(candidate, font=fnt) <= max_width:
            current = candidate
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)

    line_h = fnt.size + line_gap
    for line in lines:
        draw.text((x, y), line, font=fnt, fill=fill)
        y += line_h
    return y


def build(locale: str, name: str, headline: str, subtitle: str) -> Path:
    source = ROOT / "docs" / "screenshots" / locale / f"{name}.png"
    shot = Image.open(source).convert("RGB")

    shot_h = PHONE_H
    shot_w = round(shot.width * shot_h / shot.height)
    shot = shot.resize((shot_w, shot_h), Image.Resampling.LANCZOS)

    frame_w = shot_w + BEZEL * 2
    frame_h = shot_h + BEZEL * 2
    frame_x = W - 120 - frame_w
    frame_y = (H - frame_h) // 2

    canvas = gradient().convert("RGBA")

    # Soft Material You blobs.
    blobs = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    blob = ImageDraw.Draw(blobs)
    blob.ellipse((frame_x - 120, -260, frame_x + 640, 500), fill=ACCENT + (26,))
    blob.ellipse((-220, 760, 380, 1360), fill=ACCENT + (18,))
    blob.ellipse((frame_x + 260, 820, frame_x + 620, 1180), fill=(255, 255, 255, 150))
    canvas = Image.alpha_composite(canvas, blobs)

    # Phone shadow.
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        (
            frame_x + 12,
            frame_y + 28,
            frame_x + frame_w + 12,
            frame_y + frame_h + 28,
        ),
        radius=RADIUS,
        fill=(15, 23, 42, 70),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(28))
    canvas = Image.alpha_composite(canvas, shadow)

    draw = ImageDraw.Draw(canvas)

    # App icon + wordmark.
    icon = Image.open(ROOT / "docs" / "icon.png").convert("RGBA").resize((64, 64))
    icon.putalpha(rounded_mask((64, 64), 16))
    canvas.alpha_composite(icon, (120, 88))
    draw.text((200, 99), "PhotoTag", font=font("GoogleSans-Bold.ttf", 34), fill=DARK)
    draw.text(
        (200, 138),
        "GPS-камера" if locale == "ru" else "GPS camera",
        font=font("GoogleSans-Regular.ttf", 19),
        fill=MUTED,
    )

    # Headline.
    headline_font = font("GoogleSans-Bold.ttf", 68)
    y = draw_wrapped(draw, headline, headline_font, 120, 232, 760, DARK, 10)

    # Subtitle.
    subtitle_font = font("GoogleSans-Regular.ttf", 30)
    y = draw_wrapped(draw, subtitle, subtitle_font, 120, y + 30, 730, MUTED, 10)

    # Bottom badge.
    badge = "Android · Бесплатно" if locale == "ru" else "Android · Free"
    badge_font = font("GoogleSans-Medium.ttf", 22)
    bw = int(draw.textlength(badge, font=badge_font)) + 44
    draw.rounded_rectangle(
        (120, H - 126, 120 + bw, H - 74), radius=26, fill=(255, 255, 255, 190)
    )
    draw.text((142, H - 115), badge, font=badge_font, fill=ACCENT)

    # Phone body.
    draw.rounded_rectangle(
        (frame_x, frame_y, frame_x + frame_w, frame_y + frame_h),
        radius=RADIUS,
        fill=(15, 23, 42, 255),
    )
    draw.rounded_rectangle(
        (frame_x + 5, frame_y + 5, frame_x + frame_w - 5, frame_y + frame_h - 5),
        radius=RADIUS - 5,
        outline=(51, 65, 85, 255),
        width=2,
    )

    # Screenshot with rounded corners.
    screen = shot.convert("RGBA")
    screen.putalpha(rounded_mask((shot_w, shot_h), RADIUS - BEZEL - 4))
    canvas.alpha_composite(screen, (frame_x + BEZEL, frame_y + BEZEL))

    out_dir = ROOT / "docs" / "screenshots" / locale / "16x9"
    out_dir.mkdir(parents=True, exist_ok=True)
    out = out_dir / f"{name}.png"
    canvas.convert("RGB").save(out, "PNG", optimize=True)
    size_kb = out.stat().st_size / 1024
    print(f"{out.relative_to(ROOT)}  {size_kb:.0f} KB")
    return out


def main() -> None:
    for locale, items in (("ru", RU), ("en", EN)):
        for name, headline, subtitle in items:
            build(locale, name, headline, subtitle)


if __name__ == "__main__":
    main()
