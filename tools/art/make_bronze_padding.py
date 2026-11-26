"""Quilted padding under the bronze armour (F697 step 7, hand-built mail/greaves/boots, Nov 26).

The bronze armour sheet (tools/art/sheets/bronze_armour_sheet_nov26.png) shows dark red-brown quilted padding
under the plates. This paints it from our own leather paintings: tinted to the sheet's brown, with sunken
diamond stitching (4 diamonds per tile, so it repeats without a seam) and a light puff in each diamond.
Writes assets/textures/kit/bronzepad_a/b/dark/plain.png (512 x 512).
  python3 tools/art/make_bronze_padding.py
"""
from pathlib import Path

import numpy as np
from PIL import Image

KIT = Path(__file__).resolve().parents[2] / "assets" / "textures" / "kit"
N = 512
CELLS = 4  # diamonds across one tile

for variant, src, tint in (("a", "leather_dark", (0.62, 0.36, 0.24)), ("b", "leather_b", (0.5, 0.3, 0.2)),
		("dark", "leather_dark", (0.42, 0.24, 0.16)), ("plain", "leather_dark", (0.4, 0.24, 0.17))):
	base = np.asarray(Image.open(KIT / f"{src}.png").convert("RGB").resize((N, N)), dtype=np.float32) / 255.0
	grey = base.mean(axis=2, keepdims=True)
	img = (0.55 * grey + 0.45 * base) * np.array(tint) * 1.6
	y, x = np.mgrid[0:N, 0:N] / N * CELLS
	u, v = (x + y) % 1.0, (x - y) % 1.0  # two diagonal stitch directions
	d = np.minimum(np.minimum(u, 1 - u), np.minimum(v, 1 - v))  # 0 on a stitch line, 0.5 in a diamond's middle
	puff = 0.72 + 0.5 * np.clip(d / 0.5, 0, 1) ** 0.6  # dark seams, lighter puffy middles
	seam = np.where(d < 0.035, 0.55, 1.0)  # the sunken stitch itself
	if variant != "plain":  # plain = the same dark leather without stitching (straps, soles)
		img = img * (puff * seam)[..., None]
	img = np.clip(img, 0, 1)
	Image.fromarray((img * 255).astype(np.uint8)).save(KIT / f"bronzepad_{variant}.png")
	print("wrote", f"bronzepad_{variant}.png")
