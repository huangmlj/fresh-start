#!/usr/bin/env python3
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


SIZE = 1024
BLUE = (19, 143, 227, 255)
BLUE_DARK = (18, 101, 198, 255)
CYAN = (53, 190, 238, 255)
INK = (55, 66, 82, 255)
GRAY = (143, 153, 166, 255)


def rr(draw: ImageDraw.ImageDraw, box, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def base_icon(border_color=BLUE) -> Image.Image:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    rr(sd, (56, 68, 968, 980), 205, (28, 74, 130, 70))
    shadow = shadow.filter(ImageFilter.GaussianBlur(24))
    img.alpha_composite(shadow)

    bg = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    pix = []
    for y in range(SIZE):
        for x in range(SIZE):
            t = (x + y) / (2 * SIZE)
            r = int(255 * (1 - t) + 229 * t)
            g = int(255 * (1 - t) + 244 * t)
            b = int(255 * (1 - t) + 253 * t)
            pix.append((r, g, b, 255))
    bg.putdata(pix)

    mask = Image.new("L", (SIZE, SIZE), 0)
    md = ImageDraw.Draw(mask)
    rr(md, (42, 42, 982, 982), 202, 255)
    img.alpha_composite(Image.composite(bg, Image.new("RGBA", (SIZE, SIZE)), mask))

    draw = ImageDraw.Draw(img)
    rr(draw, (54, 54, 970, 970), 190, None, border_color, 24)
    rr(draw, (80, 80, 944, 944), 164, None, (255, 255, 255, 140), 5)
    return img


def draw_window(draw: ImageDraw.ImageDraw, box, alpha=255, front=False):
    x1, y1, x2, y2 = box
    fill = (250, 253, 255, alpha)
    outline = (115, 128, 144, min(alpha, 210))
    header = (138, 150, 164, min(alpha, 230))
    rr(draw, box, 28, fill, outline, 6)
    draw.rounded_rectangle((x1, y1, x2, y1 + 74), radius=28, fill=header)
    draw.rectangle((x1, y1 + 45, x2, y1 + 78), fill=header)
    dot = (255, 255, 255, min(alpha, 235))
    for i in range(3):
        draw.ellipse((x1 + 28 + i * 42, y1 + 25, x1 + 48 + i * 42, y1 + 45), fill=dot)
    if front:
        draw.line((x1 + 76, y1 + 160, x2 - 76, y1 + 160), fill=(200, 213, 226, 180), width=4)


def draw_window_stack(draw: ImageDraw.ImageDraw, origin=(210, 220), front_offset=(120, 112)):
    x, y = origin
    draw_window(draw, (x, y, x + 430, y + 330), 165)
    draw_window(draw, (x + 64, y + 58, x + 494, y + 388), 205)
    fx, fy = x + front_offset[0], y + front_offset[1]
    draw_window(draw, (fx, fy, fx + 500, fy + 356), 255, True)


def broom_polygon(center=(560, 650), scale=1.0, angle=-24):
    cx, cy = center
    pts = [(-150, -10), (-68, -86), (70, -78), (150, -14), (95, 90), (22, 58), (-10, 112), (-52, 62), (-88, 108), (-112, 48)]
    rad = math.radians(angle)
    out = []
    for x, y in pts:
        x *= scale
        y *= scale
        out.append((round(cx + x * math.cos(rad) - y * math.sin(rad)), round(cy + x * math.sin(rad) + y * math.cos(rad))))
    return out


def draw_broom(draw: ImageDraw.ImageDraw, handle_start, handle_end, head_center, color=BLUE):
    draw.line((handle_start, handle_end), fill=(42, 172, 231, 255), width=54)
    draw.line((handle_start, handle_end), fill=(20, 118, 211, 255), width=18)
    draw.rounded_rectangle((handle_end[0] - 94, handle_end[1] - 38, handle_end[0] + 94, handle_end[1] + 46), radius=24, fill=(52, 186, 232, 255), outline=BLUE_DARK, width=9)
    head = broom_polygon(head_center, 1.18, -14)
    draw.polygon(head, fill=(86, 204, 244, 255), outline=BLUE_DARK)
    draw.line(head + [head[0]], fill=BLUE_DARK, width=8)
    for dx in [-92, -36, 26, 82]:
        draw.line((head_center[0] + dx, head_center[1] + 40, head_center[0] + dx + 18, head_center[1] + 120), fill=BLUE_DARK, width=6)


def sparkle(draw, cx, cy, size, color=(82, 211, 229, 255)):
    draw.polygon([(cx, cy - size), (cx + size // 4, cy - size // 4), (cx + size, cy), (cx + size // 4, cy + size // 4), (cx, cy + size), (cx - size // 4, cy + size // 4), (cx - size, cy), (cx - size // 4, cy - size // 4)], fill=color)


def option_a() -> Image.Image:
    img = base_icon(BLUE)
    draw = ImageDraw.Draw(img)
    draw_window_stack(draw, (178, 194), (116, 112))
    broom_shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    sd = ImageDraw.Draw(broom_shadow)
    draw_broom(sd, (688, 176), (548, 566), (480, 692))
    broom_shadow = broom_shadow.filter(ImageFilter.GaussianBlur(16))
    img.alpha_composite(Image.eval(broom_shadow, lambda p: int(p * 0.35)))
    draw = ImageDraw.Draw(img)
    draw_broom(draw, (694, 160), (554, 548), (486, 674))
    sparkle(draw, 768, 246, 46)
    return img


def option_b() -> Image.Image:
    img = base_icon((27, 155, 217, 255))
    draw = ImageDraw.Draw(img)
    draw_window_stack(draw, (205, 238), (76, 92))
    arc = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    ad = ImageDraw.Draw(arc)
    bbox = (170, 160, 854, 844)
    ad.arc(bbox, start=118, end=405, fill=(23, 139, 222, 245), width=54)
    ad.polygon([(790, 790), (878, 770), (826, 700)], fill=(23, 139, 222, 245))
    img.alpha_composite(arc)
    draw = ImageDraw.Draw(img)
    draw_broom(draw, (650, 262), (540, 570), (492, 690))
    sparkle(draw, 744, 296, 38, (67, 207, 232, 245))
    return img


def option_c() -> Image.Image:
    img = base_icon((18, 135, 210, 255))
    draw = ImageDraw.Draw(img)
    draw_window_stack(draw, (160, 210), (132, 106))
    sweep = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    sd = ImageDraw.Draw(sweep)
    sd.arc((130, 304, 900, 912), start=28, end=155, fill=(39, 188, 223, 230), width=64)
    sd.arc((198, 374, 840, 884), start=34, end=150, fill=(23, 129, 216, 230), width=22)
    img.alpha_composite(sweep)
    draw = ImageDraw.Draw(img)
    draw_broom(draw, (714, 202), (570, 560), (520, 690), color=(28, 155, 222, 255))
    for xy in [(732, 244, 42), (812, 430, 28), (260, 720, 30)]:
        sparkle(draw, *xy)
    return img


def save_all(out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    icons = [option_a(), option_b(), option_c()]
    names = ["AppIconOptionA.png", "AppIconOptionB.png", "AppIconOptionC.png"]
    for icon, name in zip(icons, names):
        icon.save(out_dir / name)

    thumb = 360
    gap = 42
    label_h = 70
    sheet = Image.new("RGBA", (thumb * 3 + gap * 4, thumb + label_h + 36), (246, 248, 251, 255))
    draw = ImageDraw.Draw(sheet)
    for i, (icon, label) in enumerate(zip(icons, ["A", "B", "C"])):
        x = gap + i * (thumb + gap)
        y = 24
        sheet.alpha_composite(icon.resize((thumb, thumb), Image.Resampling.LANCZOS), (x, y))
        draw.text((x + thumb // 2 - 8, y + thumb + 22), label, fill=(51, 58, 72, 255))
    sheet.save(out_dir / "AppIconOptionsPreview.png")


if __name__ == "__main__":
    save_all(Path("assets/icon-options"))

