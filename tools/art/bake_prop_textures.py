"""Bakes the "detail" textures for props, monsters and the dwarf (src/art/prop.gdshader).

Each layer is a grey, hand-painted-looking surface grain (stone, wood, fungus skin, cloth,
leather, metal, bark). Grey means: it only adds light and dark detail; the object's own
colour stays the colour the code asks for. Mid-grey (128) = "no change".

Layers (keep in sync with Look.SURFACES in src/art/look.gd):
  0 stone, 1 wood, 2 fungus, 3 cloth, 4 leather, 5 metal, 6 bark, 7 smooth

Usage:  python tools/art/bake_prop_textures.py <cache_folder>
"""
import os
import sys

import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from bake_terrain_textures import fetch, load, kuwahara  # noqa: E402

SIZE = 512
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "textures", "props")

# layer: (source, contrast, paint radius, bump strength)
RECIPES = [
    ("Rock030", 1.6, 6, 1.3),     # 0 stone
    ("Wood049", 1.5, 3, 1.0),     # 1 wood
    ("Plaster001", 2.2, 6, 0.8),  # 2 fungus skin (soft blotches)
    ("Fabric030", 2.0, 2, 0.7),   # 3 cloth
    ("Leather026", 1.8, 3, 0.9),  # 4 leather
    ("Metal032", 1.6, 6, 0.5),    # 5 metal (hammered, soft)
    ("Bark007", 1.5, 4, 1.3),     # 6 bark / roots / stems
    ("Plaster001", 0.6, 8, 0.2),  # 7 smooth (crystals, skin)
]


def bake(asset_id, contrast, radius, bump, cache):
    folder = fetch(asset_id, cache)
    col = load(folder, asset_id, "Color")
    ao = load(folder, asset_id, "AmbientOcclusion") if os.path.exists(
        os.path.join(folder, "%s_1K-PNG_AmbientOcclusion.png" % asset_id)) else None
    nrm = load(folder, asset_id, "NormalGL")
    painted = kuwahara(col, radius)
    lum = painted @ np.array([0.299, 0.587, 0.114], dtype=np.float32)
    if ao is not None:
        lum = lum * (0.5 + 0.5 * ao)
    lum = lum / max(lum.mean(), 1e-4)            # 1.0 = average brightness
    lum = 1.0 + (lum - 1.0) * contrast           # stronger light/dark detail
    grey = np.clip(lum * 0.5, 0.0, 1.0)          # 0.5 = "no change"
    n = gaussian_filter(nrm, (1.5, 1.5, 0), mode="wrap") * 2.0 - 1.0
    n[..., 0:2] *= bump
    n /= np.linalg.norm(n, axis=2, keepdims=True) + 1e-6
    g = Image.fromarray((grey * 255).astype(np.uint8), "L").resize((SIZE, SIZE), Image.LANCZOS)
    b = Image.fromarray(((n * 0.5 + 0.5) * 255).astype(np.uint8), "RGB").resize((SIZE, SIZE), Image.LANCZOS)
    return g.convert("RGB"), b


def main():
    cache = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "_cache")
    os.makedirs(OUT_DIR, exist_ok=True)
    n = len(RECIPES)
    detail = Image.new("RGB", (SIZE, SIZE * n))
    normal = Image.new("RGB", (SIZE, SIZE * n))
    for i, r in enumerate(RECIPES):
        print("layer", i, r[0])
        a, b = bake(*r, cache)
        detail.paste(a, (0, i * SIZE))
        normal.paste(b, (0, i * SIZE))
    detail.save(os.path.join(OUT_DIR, "prop_detail.png"), optimize=True)
    normal.save(os.path.join(OUT_DIR, "prop_normal.png"), optimize=True)
    print("done")


if __name__ == "__main__":
    main()
