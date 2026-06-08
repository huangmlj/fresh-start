#!/usr/bin/env python3
from __future__ import annotations

import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw


SIZE = 1024
DEFAULT_SOURCE = Path.home() / "Downloads" / "Misc" / "FreshStart_Centered.icns"
OUTPUT_PNG = Path("assets/AppIcon.png")
OUTPUT_ICNS = Path("assets/AppIcon.icns")


def rounded_mask(size: int, radius: int) -> Image.Image:
    scale = 4
    mask = Image.new("L", (size * scale, size * scale), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle(
        (0, 0, size * scale - 1, size * scale - 1),
        radius=radius * scale,
        fill=255,
    )
    return mask.resize((size, size), Image.Resampling.LANCZOS)


def blue_border_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    pixels = image.convert("RGBA").load()
    xs: list[int] = []
    ys: list[int] = []

    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            if a > 80 and b > 145 and g > 95 and r < 80 and (b - r) > 110:
                xs.append(x)
                ys.append(y)

    if not xs:
        raise RuntimeError("Could not find the blue icon border.")

    left = min(xs)
    top = min(ys)
    right = max(xs) + 1
    bottom = max(ys) + 1

    # Keep antialiasing on the outside edge, but no visible white field.
    pad = 2
    return (
        max(0, left - pad),
        max(0, top - pad),
        min(image.width, right + pad),
        min(image.height, bottom + pad),
    )


def crop_to_blue_border(source: Image.Image) -> Image.Image:
    left, top, right, bottom = blue_border_bbox(source)
    cropped = source.crop((left, top, right, bottom))

    side = max(cropped.width, cropped.height)
    square = Image.new("RGBA", (side, side), (255, 255, 255, 0))
    square.alpha_composite(cropped, ((side - cropped.width) // 2, (side - cropped.height) // 2))

    icon = square.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    existing_alpha = icon.getchannel("A")
    radius = 174
    icon.putalpha(Image.composite(existing_alpha, Image.new("L", (SIZE, SIZE), 0), rounded_mask(SIZE, radius)))
    return icon


def write_iconset(icon: Image.Image, iconset: Path) -> None:
    if iconset.exists():
        shutil.rmtree(iconset)
    iconset.mkdir(parents=True, exist_ok=True)

    sizes = [
        (16, "icon_16x16.png"),
        (32, "icon_16x16@2x.png"),
        (32, "icon_32x32.png"),
        (64, "icon_32x32@2x.png"),
        (128, "icon_128x128.png"),
        (256, "icon_128x128@2x.png"),
        (256, "icon_256x256.png"),
        (512, "icon_256x256@2x.png"),
        (512, "icon_512x512.png"),
        (1024, "icon_512x512@2x.png"),
    ]

    for size, name in sizes:
        icon.resize((size, size), Image.Resampling.LANCZOS).save(iconset / name)


def main() -> int:
    source_icns = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_SOURCE

    with tempfile.TemporaryDirectory() as temp_dir:
        temp = Path(temp_dir)
        source_iconset = temp / "source.iconset"
        subprocess.run(["/usr/bin/iconutil", "-c", "iconset", str(source_icns), "-o", str(source_iconset)], check=True)
        source_png = source_iconset / "icon_512x512@2x.png"
        icon = crop_to_blue_border(Image.open(source_png).convert("RGBA"))

        OUTPUT_PNG.parent.mkdir(parents=True, exist_ok=True)
        icon.save(OUTPUT_PNG)

        output_iconset = temp / "AppIcon.iconset"
        write_iconset(icon, output_iconset)
        subprocess.run(["/usr/bin/iconutil", "-c", "icns", str(output_iconset), "-o", str(OUTPUT_ICNS)], check=True)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

