"""Bakes the dig-anywhere rock textures from CC0 photo textures (ambientCG).

What it does, in plain words:
  1. Downloads the source textures from ambientCG (CC0) into a cache folder.
  2. Makes each one look hand-painted (a "Kuwahara" paint filter), pushes its colors
     toward our earthy palette, and darkens the cracks (baked ambient occlusion).
  3. Finds the veins in ore / border rock and stores them in the alpha channel,
     so the shader can make them glow.
  4. Stacks all 16 layers (one per rock material number, see src/world/mat.gd) into
     two tall pictures: terrain_albedo.png and terrain_normal.png.
     Godot imports each as a Texture2DArray (16 slices, top to bottom).

Usage:  python tools/art/bake_terrain_textures.py <cache_folder>
Needs:  Python 3 with numpy, scipy, pillow.
"""
import io
import os
import sys
import urllib.request
import zipfile

import numpy as np
from PIL import Image
from scipy.ndimage import uniform_filter, gaussian_filter

SIZE = 512
LAYERS = 16
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "textures", "terrain")

# layer index (= Mat number): source texture, tint color, how much tint, contrast, glow rule
STONE_TINT = (0.50, 0.44, 0.38)
SPORE_TINT = (0.38, 0.30, 0.44)
RECIPES = {
    0: ("Ground068", (0.30, 0.42, 0.16), 0.35, 1.1, None),         # moss
    1: ("Rock022", STONE_TINT, 0.65, 1.25, None),                 # stone
    2: ("Ground048", (0.40, 0.27, 0.17), 0.35, 1.1, None),         # dirt
    3: ("Rock058", STONE_TINT, 0.7, 1.2, ("veins", (0.92, 0.50, 0.20))),   # copper ore
    4: ("Rock035", (0.17, 0.13, 0.24), 0.7, 1.3, ("bright", None)),        # border rock
    5: ("Ground054", (0.80, 0.43, 0.22), 0.75, 1.4, None),         # orange clay
    8: ("Ground037", (0.84, 0.80, 0.72), 0.85, 1.5, None),         # mycelium
    9: ("Rock058", SPORE_TINT, 0.7, 1.2, ("veins", (0.86, 0.90, 0.98))),   # silver ore
    11: ("Rock051", (0.86, 0.60, 0.24), 0.7, 1.2, None),           # amberrock
    13: ("Rock028", SPORE_TINT, 0.7, 1.25, ("specks", None)),      # sporestone
    15: ("Rock035", (0.10, 0.08, 0.12), 0.85, 1.2, None),          # world's edge
}
FILLER = 1  # unused material numbers look like stone


def fetch(asset_id: str, cache: str) -> str:
    folder = os.path.join(cache, asset_id)
    if not os.path.isdir(folder):
        url = "https://ambientcg.com/get?file=%s_1K-PNG.zip" % asset_id
        print("downloading", url)
        data = urllib.request.urlopen(url).read()
        with zipfile.ZipFile(io.BytesIO(data)) as z:
            for name in z.namelist():
                if name.endswith((".png",)) and "/" not in name:
                    z.extract(name, folder)
    return folder


def load(folder: str, asset_id: str, kind: str) -> np.ndarray:
    path = os.path.join(folder, "%s_1K-PNG_%s.png" % (asset_id, kind))
    im = Image.open(path)
    im = im.convert("RGB") if kind != "AmbientOcclusion" else im.convert("L")
    return np.asarray(im, dtype=np.float32) / 255.0


def kuwahara(img: np.ndarray, r: int) -> np.ndarray:
    """Paint filter: each pixel takes the average of the calmest of its 4 neighbour squares."""
    lum = img @ np.array([0.299, 0.587, 0.114], dtype=np.float32)
    k = r + 1
    mean = uniform_filter(img, size=(k, k, 1), mode="wrap")
    lmean = uniform_filter(lum, size=k, mode="wrap")
    lvar = uniform_filter(lum * lum, size=k, mode="wrap") - lmean * lmean
    h = r // 2 + 0  # offset from pixel to each quadrant centre
    shifts = [(-h, -h), (-h, h), (h, -h), (h, h)]
    best_var = None
    out = np.zeros_like(img)
    for dy, dx in shifts:
        v = np.roll(lvar, (dy, dx), axis=(0, 1))
        m = np.roll(mean, (dy, dx), axis=(0, 1))
        if best_var is None:
            best_var, out = v, m
        else:
            take = v < best_var
            best_var = np.where(take, v, best_var)
            out = np.where(take[..., None], m, out)
    return out


def tint(img: np.ndarray, color, amount: float, contrast: float) -> np.ndarray:
    lum = img @ np.array([0.299, 0.587, 0.114], dtype=np.float32)
    rel = np.clip(lum / max(lum.mean(), 1e-4), 0.0, 3.0) ** contrast
    tinted = np.array(color, dtype=np.float32)[None, None, :] * rel[..., None]
    return img * (1.0 - amount) + tinted * amount


def glow_mask(src: np.ndarray, rule: str) -> np.ndarray:
    if rule == "veins":  # warm-coloured cracks in Rock058
        warm = src[..., 0] - src[..., 2]
        m = np.clip((warm - 0.02) * 9.0, 0.0, 1.0)
    elif rule == "bright":  # pale streaks in dark rock
        lum = src @ np.array([0.299, 0.587, 0.114], dtype=np.float32)
        m = np.clip((lum - np.percentile(lum, 93)) * 12.0, 0.0, 1.0)
    else:  # "specks": sparse dots
        rng = np.random.default_rng(13)
        dots = (rng.random(src.shape[:2]) > 0.99985).astype(np.float32)
        m = np.clip(gaussian_filter(dots, 1.6, mode="wrap") * 30.0, 0.0, 1.0)
    return gaussian_filter(m, 0.8, mode="wrap")


def bake_layer(asset_id, color, amount, contrast, glow, cache):
    folder = fetch(asset_id, cache)
    col = load(folder, asset_id, "Color")
    ao = load(folder, asset_id, "AmbientOcclusion")
    nrm = load(folder, asset_id, "NormalGL")
    painted = kuwahara(col, 6)
    out = tint(painted, color, amount, contrast)
    out *= (0.45 + 0.55 * ao)[..., None]  # dark cracks = painted shadows
    alpha = np.zeros(out.shape[:2], dtype=np.float32)
    if glow:
        rule, ore = glow
        alpha = glow_mask(col, rule)
        if ore is not None:  # recolour the veins to the ore's colour
            vein = np.clip(alpha * 1.4, 0, 1)[..., None]
            lum = (col @ np.array([0.299, 0.587, 0.114], dtype=np.float32))[..., None]
            out = out * (1 - vein) + np.array(ore, dtype=np.float32) * (0.6 + 0.8 * lum) * vein
    # Soften the photo normals a little so bumps read as "painted", then make them a bit stronger.
    n = gaussian_filter(nrm, (1.5, 1.5, 0), mode="wrap") * 2.0 - 1.0
    n[..., 0:2] *= 1.4
    n /= np.linalg.norm(n, axis=2, keepdims=True) + 1e-6
    # Resize colour and glow separately (resizing RGBA in one go would erase colour where alpha is 0).
    rgb = Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8), "RGB").resize((SIZE, SIZE), Image.LANCZOS)
    al = Image.fromarray((alpha * 255).astype(np.uint8), "L").resize((SIZE, SIZE), Image.LANCZOS)
    a = Image.merge("RGBA", (*rgb.split(), al))
    b = Image.fromarray(((n * 0.5 + 0.5) * 255).astype(np.uint8), "RGB").resize((SIZE, SIZE), Image.LANCZOS)
    return a, b


def main():
    cache = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "_cache")
    os.makedirs(OUT_DIR, exist_ok=True)
    baked = {}
    for idx, recipe in RECIPES.items():
        print("layer", idx, recipe[0])
        baked[idx] = bake_layer(*recipe, cache)
    albedo = Image.new("RGBA", (SIZE, SIZE * LAYERS))
    normal = Image.new("RGB", (SIZE, SIZE * LAYERS))
    for i in range(LAYERS):
        a, b = baked.get(i, baked[FILLER])
        albedo.paste(a, (0, i * SIZE))
        normal.paste(b, (0, i * SIZE))
    albedo.save(os.path.join(OUT_DIR, "terrain_albedo.png"), optimize=True)
    normal.save(os.path.join(OUT_DIR, "terrain_normal.png"), optimize=True)
    # A preview sheet for humans (not used by the game).
    prev = Image.new("RGB", (256 * 4, 256 * 4))
    for k, i in enumerate(sorted(baked)):
        prev.paste(baked[i][0].convert("RGB").resize((256, 256)), ((k % 4) * 256, (k // 4) * 256))
    prev.save(os.path.join(cache, "preview.png"))
    print("done")


if __name__ == "__main__":
    main()
