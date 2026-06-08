#!/usr/bin/env python3
from __future__ import annotations

import math
import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


SIZE = 1024


def rounded_mask(size: int, radius: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size, size), radius=radius, fill=255)
    return mask


def gradient_square() -> Image.Image:
    image = Image.new("RGBA", (SIZE, SIZE))
    pixels = []
    top = (250, 253, 255)
    lower = (222, 214, 255)
    glow = (150, 238, 220)

    for y in range(SIZE):
        for x in range(SIZE):
            t = (x + y) / (2 * (SIZE - 1))
            cx = (x - 210) / SIZE
            cy = (y - 820) / SIZE
            g = max(0.0, 1.0 - math.sqrt(cx * cx + cy * cy) * 2.2)
            r = int(top[0] * (1 - t) + lower[0] * t + glow[0] * g * 0.12)
            gg = int(top[1] * (1 - t) + lower[1] * t + glow[1] * g * 0.14)
            b = int(top[2] * (1 - t) + lower[2] * t + glow[2] * g * 0.10)
            pixels.append((r, gg, b, 255))

    image.putdata(pixels)
    return image


def draw_check(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], color: tuple[int, int, int, int], width: int) -> None:
    x1, y1, x2, y2 = box
    points = [
        (x1 + int((x2 - x1) * 0.25), y1 + int((y2 - y1) * 0.53)),
        (x1 + int((x2 - x1) * 0.44), y1 + int((y2 - y1) * 0.70)),
        (x1 + int((x2 - x1) * 0.76), y1 + int((y2 - y1) * 0.30)),
    ]
    draw.line(points, fill=color, width=width, joint="curve")


def arc_points(center: tuple[int, int], radius: int, start: float, end: float, steps: int = 160) -> list[tuple[int, int]]:
    points = []
    for i in range(steps + 1):
        t = start + (end - start) * i / steps
        rad = math.radians(t)
        points.append((round(center[0] + radius * math.cos(rad)), round(center[1] + radius * math.sin(rad))))
    return points


def draw_arrowhead(draw: ImageDraw.ImageDraw, tip: tuple[int, int], angle_degrees: float, color: tuple[int, int, int, int]) -> None:
    angle = math.radians(angle_degrees)
    back = (math.cos(angle), math.sin(angle))
    normal = (-back[1], back[0])
    length = 92
    width = 76
    p1 = (tip[0], tip[1])
    p2 = (round(tip[0] - back[0] * length + normal[0] * width / 2), round(tip[1] - back[1] * length + normal[1] * width / 2))
    p3 = (round(tip[0] - back[0] * length - normal[0] * width / 2), round(tip[1] - back[1] * length - normal[1] * width / 2))
    draw.polygon([p1, p2, p3], fill=color)


def create_icon() -> Image.Image:
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))

    shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle((66, 78, 958, 970), radius=215, fill=(50, 37, 92, 70))
    shadow = shadow.filter(ImageFilter.GaussianBlur(28))
    canvas.alpha_composite(shadow)

    base = gradient_square()
    mask = rounded_mask(SIZE, 210)
    base_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    base_layer.alpha_composite(base)
    canvas.alpha_composite(Image.composite(base_layer, Image.new("RGBA", (SIZE, SIZE)), mask))

    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle((66, 66, 958, 958), radius=210, outline=(255, 255, 255, 170), width=5)
    draw.rounded_rectangle((90, 90, 934, 934), radius=188, outline=(112, 82, 190, 28), width=3)

    arc_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    arc_draw = ImageDraw.Draw(arc_layer)
    purple = (113, 59, 216, 235)
    teal = (35, 195, 165, 225)
    arc_draw.line(arc_points((512, 530), 345, 138, 410), fill=purple, width=68, joint="curve")
    arc_draw.line(arc_points((512, 530), 345, 138, 230), fill=teal, width=68, joint="curve")
    end_angle = 410
    end = arc_points((512, 530), 345, end_angle, end_angle, 1)[0]
    draw_arrowhead(arc_draw, end, end_angle + 90, purple)
    canvas.alpha_composite(arc_layer)

    panel_shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    panel_shadow_draw = ImageDraw.Draw(panel_shadow)
    panel_shadow_draw.rounded_rectangle((206, 282, 818, 714), radius=94, fill=(69, 48, 116, 85))
    panel_shadow = panel_shadow.filter(ImageFilter.GaussianBlur(22))
    canvas.alpha_composite(panel_shadow)

    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle((204, 250, 820, 690), radius=92, fill=(255, 255, 255, 242), outline=(255, 255, 255, 245), width=4)

    row_ys = [344, 472, 600]
    row_colors = [(113, 59, 216, 255), (113, 59, 216, 255), (196, 205, 216, 255)]
    line_colors = [(47, 55, 77, 180), (47, 55, 77, 142), (47, 55, 77, 110)]
    for index, y in enumerate(row_ys):
        draw.rounded_rectangle((282, y - 34, 352, y + 36), radius=18, fill=row_colors[index])
        if index < 2:
            draw_check(draw, (288, y - 28, 346, y + 28), (255, 255, 255, 255), 10)
        else:
            draw.rounded_rectangle((296, y - 20, 338, y + 22), radius=9, outline=(255, 255, 255, 180), width=6)

        draw.rounded_rectangle((394, y - 22, 704, y - 2), radius=10, fill=line_colors[index])
        draw.rounded_rectangle((394, y + 15, 628, y + 31), radius=8, fill=(132, 142, 164, 82))

    badge_shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    badge_shadow_draw = ImageDraw.Draw(badge_shadow)
    badge_shadow_draw.ellipse((650, 590, 838, 778), fill=(63, 39, 112, 90))
    badge_shadow = badge_shadow.filter(ImageFilter.GaussianBlur(18))
    canvas.alpha_composite(badge_shadow)

    moon_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    moon_draw = ImageDraw.Draw(moon_layer)
    moon_draw.ellipse((642, 574, 826, 758), fill=(113, 59, 216, 248))
    moon_draw.ellipse((706, 618, 786, 698), fill=(255, 255, 255, 248))
    moon_draw.ellipse((736, 594, 816, 674), fill=(113, 59, 216, 248))
    canvas.alpha_composite(moon_layer)

    sparkle = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    sparkle_draw = ImageDraw.Draw(sparkle)
    sparkle_draw.polygon([(748, 250), (770, 300), (820, 322), (770, 344), (748, 394), (726, 344), (676, 322), (726, 300)], fill=(255, 255, 255, 225))
    sparkle_draw.polygon([(780, 292), (792, 322), (822, 334), (792, 346), (780, 376), (768, 346), (738, 334), (768, 322)], fill=(77, 214, 184, 210))
    canvas.alpha_composite(sparkle)

    return canvas


def save_iconset(source: Image.Image, out_dir: Path) -> None:
    iconset = out_dir / "AppIcon.iconset"
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
        resized = source.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(iconset / name)

    subprocess.run(["/usr/bin/iconutil", "-c", "icns", str(iconset), "-o", str(out_dir / "AppIcon.icns")], check=True)


def main() -> int:
    out_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("assets")
    out_dir.mkdir(parents=True, exist_ok=True)
    source = create_icon()
    source.save(out_dir / "AppIcon.png")
    save_iconset(source, out_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
