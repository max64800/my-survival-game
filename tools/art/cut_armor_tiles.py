"""Cuts an armor set's hand-painted ChatGPT sheet into 4 tiles that repeat without a seam (Claude, Nov 18, 2026).

What it does, in plain words:
  1. Opens assets/concepts/outfits/armor_<set>_sheet.png (2 x 2 paintings with thin dark gaps between them).
  2. Cuts each painting out, a little inside the gaps.
  3. Makes it repeat without a seam: the middle stays as painted, and toward the edges it fades into a copy of itself
     shifted by half (whose edges match the opposite edges).
  4. Writes assets/textures/armor/<set>_<name>.png (512 px), used by tools/asset_forge/builds/dwarf_armor.py.

Usage:  python tools/art/cut_armor_tiles.py <set> <name top-left> <top-right> <bottom-left> <bottom-right>
        e.g. python tools/art/cut_armor_tiles.py hide leather leather_red fleece brass
Needs:  Python 3 with numpy and pillow.
"""
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
SIZE = 512


def seamless(t):
	h, w, _ = t.shape
	shifted = np.roll(np.roll(t, h // 2, 0), w // 2, 1)
	y = np.minimum(np.arange(h), h - 1 - np.arange(h)) / (h / 2)
	x = np.minimum(np.arange(w), w - 1 - np.arange(w)) / (w / 2)
	m = np.clip(np.minimum.outer(y, x) / 0.35, 0, 1)
	m = (m * m * (3 - 2 * m))[:, :, None]
	return t * m + shifted * (1 - m)


def main():
	name, tiles = sys.argv[1], sys.argv[2:6]
	sheet = np.asarray(Image.open(os.path.join(ROOT, "assets", "concepts", "outfits", f"armor_{name}_sheet.png")).convert("RGB"), float)
	h, w, _ = sheet.shape
	out = os.path.join(ROOT, "assets", "textures", "armor")
	os.makedirs(out, exist_ok=True)
	m = int(w * 0.025)  # (inside the dark gaps and the sheet's border)
	for k, tname in enumerate(tiles):
		r, c = divmod(k, 2)
		t = sheet[r * h // 2 + m:(r + 1) * h // 2 - m, c * w // 2 + m:(c + 1) * w // 2 - m]
		img = Image.fromarray(np.clip(seamless(t), 0, 255).astype(np.uint8)).resize((SIZE, SIZE), Image.LANCZOS)
		path = os.path.join(out, f"{name}_{tname}.png")
		img.save(path)
		print("made", os.path.normpath(path))


main()
