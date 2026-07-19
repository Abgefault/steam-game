#!/usr/bin/env python3
"""Generates original procedural sprite/decal textures:
- assets/textures/plant/leaf.png  — stylized 7-finger leaf with alpha
- assets/textures/hazard/color.jpg — yellow/black hazard stripes
Run: python3 tools/generate_sprites.py  (requires pillow)"""
import math
import os
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.join(os.path.dirname(__file__), "..")


def leaf():
    size = 512
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = size // 2, int(size * 0.86)

    def finger(angle_deg, length, width):
        """One serrated leaflet as a polygon pointing up from (cx, cy)."""
        a = math.radians(angle_deg)
        ux, uy = math.sin(a), -math.cos(a)          # along the finger
        px, py = -uy, ux                             # perpendicular
        pts_left, pts_right = [], []
        teeth = 9
        for i in range(teeth + 1):
            t = i / teeth
            # Leaflet outline: widest ~35% along, tapering to a point.
            w = width * math.sin(min(1.0, t * 1.6) * math.pi * 0.62) * (1.0 - 0.15 * t)
            # Serration: pull every other sample inward.
            if 0 < i < teeth:
                w *= 0.72 if i % 2 == 0 else 1.0
            lx = cx + ux * length * t + px * w
            ly = cy + uy * length * t + py * w
            rx = cx + ux * length * t - px * w
            ry = cy + uy * length * t - py * w
            pts_left.append((lx, ly))
            pts_right.append((rx, ry))
        d.polygon(pts_left + pts_right[::-1], fill=(46, 116, 58, 255))

    lengths = [0.94, 0.86, 0.70, 0.48, 0.28]
    widths = [0.075, 0.070, 0.062, 0.050, 0.038]
    for k in range(5):
        L = lengths[k] * (cy - 10)
        W = widths[k] * size
        if k == 0:
            finger(0, L, W)
        else:
            finger(+k * 26, L, W)
            finger(-k * 26, L, W)
    # Stem.
    d.line([(cx, cy + 30), (cx, cy - 14)], fill=(52, 100, 50, 255), width=10)
    # Central vein shading: brighten middle of each finger.
    veins = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    dv = ImageDraw.Draw(veins)
    for k in range(5):
        L = lengths[k] * (cy - 10)
        for sgn in ([0] if k == 0 else [+1, -1]):
            a = math.radians(sgn * k * 26)
            ex = cx + math.sin(a) * L
            ey = cy - math.cos(a) * L
            dv.line([(cx, cy), (ex, ey)], fill=(96, 168, 92, 200), width=5)
    img = Image.alpha_composite(img, veins.filter(ImageFilter.GaussianBlur(1.5)))
    out = os.path.join(ROOT, "assets", "textures", "plant")
    os.makedirs(out, exist_ok=True)
    img.save(os.path.join(out, "leaf.png"))
    print("wrote plant/leaf.png")


def hazard():
    size = 256
    img = Image.new("RGB", (size, size), (240, 200, 30))
    d = ImageDraw.Draw(img)
    stripe = 42
    for x in range(-size, size * 2, stripe * 2):
        d.polygon([(x, size), (x + stripe, size), (x + size + stripe, 0),
                   (x + size, 0)], fill=(28, 28, 30))
    out = os.path.join(ROOT, "assets", "textures", "hazard")
    os.makedirs(out, exist_ok=True)
    img.save(os.path.join(out, "color.jpg"), quality=90)
    print("wrote hazard/color.jpg")


leaf()
hazard()
print("done")
