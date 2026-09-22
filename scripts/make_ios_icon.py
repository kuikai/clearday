#!/usr/bin/env python3
"""Write opaque, full-bleed iOS icons so iOS does not show a black ring."""

from __future__ import annotations

from pathlib import Path

try:
    from PIL import Image, ImageDraw
except ImportError as error:
    raise SystemExit("Pillow is required: pip3 install pillow") from error

BG = (15, 61, 50)
RING = (78, 205, 196)
CHECK = (228, 241, 236)

OUT_DIR = Path("ios/Runner/Assets.xcassets/AppIcon.appiconset")

SIZES = {
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-50x50@1x.png": 50,
    "Icon-App-50x50@2x.png": 100,
    "Icon-App-57x57@1x.png": 57,
    "Icon-App-57x57@2x.png": 114,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-72x72@1x.png": 72,
    "Icon-App-72x72@2x.png": 144,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}


def make(size: int) -> Image.Image:
    image = Image.new("RGB", (size, size), BG)
    draw = ImageDraw.Draw(image)
    scale = size / 1024
    cx = size / 2
    cy = size / 2 + 12 * scale
    radius = 310 * scale
    width = max(8, int(52 * scale))
    draw.ellipse(
        [cx - radius, cy - radius, cx + radius, cy + radius],
        outline=RING,
        width=width,
    )
    p1 = (cx - 140 * scale, cy + 10 * scale)
    p2 = (cx - 30 * scale, cy + 130 * scale)
    p3 = (cx + 170 * scale, cy - 130 * scale)
    draw.line([p1, p2, p3], fill=CHECK, width=width, joint="curve")
    return image


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, size in SIZES.items():
        make(size).save(OUT_DIR / name, "PNG")
    print(f"Wrote {len(SIZES)} icons to {OUT_DIR}")


if __name__ == "__main__":
    main()
