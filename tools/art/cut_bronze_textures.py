"""Cut the painted bronze texture sheet into kit textures (F697 step 7: bronze gets its own look).

Sheet: tools/art/sheets/bronze_textures_sheet_nov26.png (ChatGPT, 1254 x 1254):
  top three rows = knot bands (strips), bottom left = knot medallion, bottom right = hammered bronze plate.
Writes into assets/textures/kit/:
  bronzeknot_a/b/c.png  1024 x 256 strips, ends blended so they wrap round a rim without a seam
  bronzemedal_a.png     512 x 512 round knot medallion (with its corner rivets)
  bronzeplate_a/b/c/dark.png 512 x 512 hammered plate, tiles both ways
Usage: python tools/art/cut_bronze_textures.py
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageEnhance

ROOT = Path(__file__).resolve().parents[2]
SHEET = ROOT / "tools/art/sheets/bronze_textures_sheet_nov26.png"
OUT = ROOT / "assets/textures/kit"

STRIPS = {"a": (4, 228), "b": (232, 418), "c": (424, 612)}  # y ranges on the sheet
MEDAL = (0, 624, 620, 1254)
PLATE = (628, 624, 1254, 1254)


def wrap_x(a, blend):
	"""Fade the right end into the left end so the picture repeats sideways without a seam."""
	w = a.shape[1] - blend
	out = a[:, :w].copy()
	t = np.linspace(0, 1, blend)[None, :, None]
	out[:, :blend] = a[:, w:] * (1 - t) + a[:, :blend] * t
	return out


def wrap_xy(a, blend):
	a = wrap_x(a, blend)
	return wrap_x(a.transpose(1, 0, 2), blend).transpose(1, 0, 2)


def save(arr, name, size):
	Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8)).resize(size, Image.LANCZOS).save(OUT / name)
	print("wrote", name)


def main():
	sheet = Image.open(SHEET).convert("RGB")
	src = np.asarray(sheet).astype(float)
	for v, (y0, y1) in STRIPS.items():
		save(wrap_x(src[y0:y1], 90), f"bronzeknot_{v}.png", (1024, 256))
	save(src[MEDAL[1]:MEDAL[3], MEDAL[0]:MEDAL[2]], "bronzemedal_a.png", (512, 512))
	plate = wrap_xy(src[PLATE[1]:PLATE[3], PLATE[0]:PLATE[2]], 110)
	save(plate, "bronzeplate_a.png", (512, 512))
	save(np.rot90(plate, 1), "bronzeplate_b.png", (512, 512))
	save(plate[::-1, ::-1], "bronzeplate_c.png", (512, 512))
	dark = np.asarray(ImageEnhance.Brightness(Image.fromarray(plate.astype(np.uint8))).enhance(0.55)).astype(float)
	save(dark[:, ::-1], "bronzeplate_dark.png", (512, 512))


if __name__ == "__main__":
	main()
