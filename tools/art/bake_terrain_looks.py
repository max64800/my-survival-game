"""Gives every cave material 4 different looks (owner F213: "many paintings, not one").

What it does, in plain words:
  1. Starts from the base look of each of the 16 materials (assets/textures/terrain/base/,
     made by bake_terrain_textures.py).
  2. For materials that have a hand-painted ChatGPT sheet in assets/concepts/terrain/
     (<name>_sheet.png, 2x2 tiles with dark gaps), cuts the 4 tiles, makes each one repeat
     without a seam, nudges its colour toward the material's usual colour, and makes a bump
     (normal) map from the painting's light and dark.
  3. Materials without a sheet get their base look mirrored 4 ways (still 4 looks).
     Tin ore (6, F697) is the painted stone with chunky grey-silver flecks painted on top (fleck_looks).
  4. Writes assets/textures/terrain/terrain_albedo.png / terrain_normal.png: 64 slices,
     slice = material number * 4 + look. The terrain shader picks the look per spot.

Usage:  python3 tools/art/bake_terrain_looks.py [preview.png]
Needs:  Python 3 with numpy and pillow.
"""
import math
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
TEX = os.path.join(ROOT, "assets", "textures", "terrain")
SHEETS = os.path.join(ROOT, "assets", "concepts", "terrain")
SIZE = 512
MATS = 16
LOOKS = 4
SHEET_FOR = {0: "moss", 1: "stone", 2: "dirt", 5: "clay"}  # Mat number -> sheet name
FLECKS_ON = {6: 1}  # Mat number -> the material whose looks it paints flecks on (tin on stone)
TIN = (165, 171, 178)  # grey-silver, a little cool
COLOUR_MATCH = 0.8  # how far each painted tile's average colour moves to the material's usual colour
BUMP = 5.0


def spans(dark, n):
    """Runs of rows/columns that are not dark gap, longer than a fifth of the picture."""
    out, start = [], None
    for i, d in enumerate(list(dark) + [True]):
        if not d and start is None:
            start = i
        elif d and start is not None:
            if i - start > n // 5:
                out.append((start, i))
            start = None
    return out


def cut(sheet):
    """The 4 tiles of a 2x2 sheet (reading order), 512 px each."""
    a = np.asarray(sheet.convert("RGB")).astype(np.float32)
    lum = a.mean(axis=2)
    h, w = lum.shape
    rows = spans((lum < 40).mean(axis=1) > 0.5, h)
    cols = spans((lum < 40).mean(axis=0) > 0.5, w)
    if len(rows) != 2 or len(cols) != 2:  # no clear gaps: split in halves
        rows, cols = [(0, h // 2), (h // 2, h)], [(0, w // 2), (w // 2, w)]
    m = max(6, h // 100)  # stay clear of the gap's soft edge
    return [sheet.convert("RGB").crop((x0 + m, y0 + m, x1 - m, y1 - m)).resize((SIZE, SIZE), Image.LANCZOS)
            for (y0, y1) in rows for (x0, x1) in cols]


def seamless(x):
    """Blend the tile with itself shifted by half, so its edges match (same idea as derive_tex_shack.py)."""
    h, w = x.shape[:2]
    s = np.roll(np.roll(x, h // 2, 0), w // 2, 1)
    yy, xx = np.mgrid[0:h, 0:w]
    m = np.minimum(np.minimum(xx, w - 1 - xx) / (w * 0.25), np.minimum(yy, h - 1 - yy) / (h * 0.25)).clip(0, 1)
    return x * m[..., None] + s * (1 - m[..., None])


def blur_wrap(x, r):
    """Gaussian blur that wraps around the edges (the tile repeats)."""
    k = np.exp(-0.5 * (np.arange(-int(3 * r), int(3 * r) + 1) / r) ** 2)
    k /= k.sum()
    for axis in (0, 1):
        x = sum(wt * np.roll(x, i - len(k) // 2, axis) for i, wt in enumerate(k))
    return x


def normal_from(rgb):
    """Bumps from the painting: light = raised, dark cracks = low (OpenGL style, green up)."""
    lum = rgb @ np.array([0.299, 0.587, 0.114], dtype=np.float32) / 255.0
    hgt = blur_wrap(lum - blur_wrap(lum, 24), 1.2)  # keep small and medium bumps only
    nx = -(np.roll(hgt, -1, 1) - np.roll(hgt, 1, 1)) * BUMP
    ny = (np.roll(hgt, -1, 0) - np.roll(hgt, 1, 0)) * BUMP
    n = np.dstack([nx, ny, np.ones_like(nx)])
    n /= np.linalg.norm(n, axis=2, keepdims=True)
    return Image.fromarray(((n * 0.5 + 0.5) * 255).astype(np.uint8))


def painted_looks(name, base_rgb):
    target = base_rgb.reshape(-1, 3).mean(axis=0)
    out = []
    for t in cut(Image.open(os.path.join(SHEETS, name + "_sheet.png"))):
        x = seamless(np.asarray(t).astype(np.float32))
        gain = target / np.maximum(x.reshape(-1, 3).mean(axis=0), 1.0)
        x = np.clip(x * (1 - COLOUR_MATCH + COLOUR_MATCH * gain), 0, 255)
        alb = Image.fromarray(x.astype(np.uint8)).convert("RGBA")
        alb.putalpha(0)  # no glowing veins
        out.append((alb, normal_from(x)))
    return out


def mirrored_looks(alb, nrm):
    """4 looks from one: as is, mirrored left-right, top-bottom, both (bump directions flipped to match)."""
    out = []
    for fx, fy in ((0, 0), (1, 0), (0, 1), (1, 1)):
        a = np.asarray(alb).copy()
        n = np.asarray(nrm).astype(np.int16)
        if fx:
            a, n = a[:, ::-1], n[:, ::-1]
            n[..., 0] = 255 - n[..., 0]
        if fy:
            a, n = a[::-1], n[::-1]
            n[..., 1] = 255 - n[..., 1]
        out.append((Image.fromarray(np.ascontiguousarray(a)),
                    Image.fromarray(np.ascontiguousarray(n.astype(np.uint8)))))
    return out


def fleck_looks(looks, seed):
    """Tin (F697): each stone look with clusters of chunky flecks. Every fleck is a lopsided 5-7 sided chip (never a
    perfect circle), a light worn rim on its upper-left, a dark gap around it. Drawn wrapped so the tile still repeats.
    The flecks also go in the alpha channel: the shader gives them a soft metal glint."""
    from PIL import ImageDraw
    rng = np.random.default_rng(seed)
    out = []
    for k, (alb, _) in enumerate(looks):
        mask = Image.new("L", (SIZE, SIZE), 0)
        rim = Image.new("L", (SIZE, SIZE), 0)
        dm, dr = ImageDraw.Draw(mask), ImageDraw.Draw(rim)
        for _c in range(int(rng.integers(7, 10))):
            cx, cy = rng.uniform(0, SIZE, 2)
            for _f in range(int(rng.integers(5, 11))):
                fx, fy = cx + rng.normal(0, 34), cy + rng.normal(0, 34)
                r = rng.uniform(6, 17)
                sides = int(rng.integers(5, 8))
                turn = rng.uniform(0, 6.28)
                pts = [(math.cos(turn + 6.283 * i / sides) * r * rng.uniform(0.6, 1.15),
                        math.sin(turn + 6.283 * i / sides) * r * rng.uniform(0.5, 1.0)) for i in range(sides)]
                for ox in (-SIZE, 0, SIZE):
                    for oy in (-SIZE, 0, SIZE):
                        dm.polygon([(fx + x + ox, fy + y + oy) for x, y in pts], fill=255)
                        dr.polygon([(fx + x * 0.7 - r * 0.2 + ox, fy + y * 0.7 - r * 0.2 + oy) for x, y in pts], fill=255)
        m = np.asarray(mask).astype(np.float32) / 255.0
        hi = np.asarray(rim).astype(np.float32) / 255.0 * m
        gap = np.clip(blur_wrap(m, 2.5) * 1.6 - m, 0, 1)  # a dark ring just outside each fleck
        x = np.asarray(alb.convert("RGB")).astype(np.float32)
        lum = (x @ np.array([0.299, 0.587, 0.114], dtype=np.float32))[..., None] / 120.0
        metal = np.array(TIN, dtype=np.float32) * (0.7 + 0.3 * lum) * (0.82 + 0.3 * hi[..., None])
        x = x * (1 - 0.55 * gap[..., None])
        x = x * (1 - m[..., None]) + metal * m[..., None]
        x = np.clip(x, 0, 255)
        a = Image.fromarray(x.astype(np.uint8)).convert("RGBA")
        a.putalpha(Image.fromarray((np.clip(m * 0.9, 0, 1) * 255).astype(np.uint8)))
        out.append((a, normal_from(x)))
    return out


def main():
    base_a = Image.open(os.path.join(TEX, "base", "terrain_albedo_16.png")).convert("RGBA")
    base_n = Image.open(os.path.join(TEX, "base", "terrain_normal_16.png")).convert("RGB")
    albedo = Image.new("RGBA", (SIZE, SIZE * MATS * LOOKS))
    normal = Image.new("RGB", (SIZE, SIZE * MATS * LOOKS))
    painted = {}
    all_looks = {}
    for m in range(MATS):
        box = (0, m * SIZE, SIZE, (m + 1) * SIZE)
        a, n = base_a.crop(box), base_n.crop(box)
        name = SHEET_FOR.get(m)
        if name and os.path.exists(os.path.join(SHEETS, name + "_sheet.png")):
            looks = painted[m] = painted_looks(name, np.asarray(a.convert("RGB")).astype(np.float32))
        elif m in FLECKS_ON:
            looks = painted[m] = fleck_looks(all_looks[FLECKS_ON[m]], seed=m)
        else:
            looks = mirrored_looks(a, n)
        all_looks[m] = looks
        for k, (la, ln) in enumerate(looks):
            albedo.paste(la, (0, (m * LOOKS + k) * SIZE))
            normal.paste(ln, (0, (m * LOOKS + k) * SIZE))
    albedo.save(os.path.join(TEX, "terrain_albedo.png"), optimize=True)
    normal.save(os.path.join(TEX, "terrain_normal.png"), optimize=True)
    print("painted:", sorted(SHEET_FOR.get(m, "flecks%d" % m) for m in painted) or "none")
    if len(sys.argv) > 1 and painted:  # preview for people: each tile repeated 2x2 so seams would show
        prev = Image.new("RGB", (LOOKS * 512, len(painted) * 512))
        for r, m in enumerate(sorted(painted)):
            for k, (la, _) in enumerate(painted[m]):
                t = la.convert("RGB").resize((256, 256))
                for dx in (0, 256):
                    for dy in (0, 256):
                        prev.paste(t, (k * 512 + dx, r * 512 + dy))
        prev.save(sys.argv[1])
        print("preview:", sys.argv[1])


if __name__ == "__main__":
    main()
