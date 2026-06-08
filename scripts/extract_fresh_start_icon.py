#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw


SOURCE = Path("assets/FreshStartSource.png")
OUTPUT = Path("assets/AppIcon.png")
SIZE = 1024


def rounded_mask(size: int, radius: int) -> Image.Image:
    scale = 4
    large = Image.new("L", (size * scale, size * scale), 0)
    draw = ImageDraw.Draw(large)
    draw.rounded_rectangle(
        (0, 0, size * scale - 1, size * scale - 1),
        radius=radius * scale,
        fill=255,
    )
    return large.resize((size, size), Image.Resampling.LANCZOS)


def main() -> int:
    source = Image.open(SOURCE).convert("RGBA")

    # Tight crop around the middle Fresh Start icon. The blue rounded border is
    # intentionally close to the final canvas edge, so it becomes the app border.
    crop_box = (1068, 411, 1748, 1091)
    icon = source.crop(crop_box).resize((SIZE, SIZE), Image.Resampling.LANCZOS)

    alpha = rounded_mask(SIZE, 178)
    existing_alpha = icon.getchannel("A")
    icon.putalpha(Image.composite(existing_alpha, Image.new("L", (SIZE, SIZE), 0), alpha))

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    icon.save(OUTPUT)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

