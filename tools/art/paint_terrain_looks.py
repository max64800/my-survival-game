"""Cuts the ChatGPT hand-painted rock sheets into game textures, several "looks" per material (F213).

What it does, in plain words:
  1. Reads one sheet per material from assets/concepts/terrain/<name>_sheet.png (a 2 x 2 grid of square
     paintings on a light-grey background, see docs/design/rock-textures-plan.md for the ChatGPT prompt).
  2. Cuts out the 4 paintings, makes each one repeat without a seam (shift by half + blend the edges),
     and nudges its colours toward the material's colour today, so the cave keeps its palette.
  3. Makes a bump picture (normal map) from the painting: light = high, dark = low.
  4. Puts look 1 of each material in that material's own slice of terrain_albedo.png / terrain_normal.png,
     and looks 2-4 in extra slices after slice 16. Materials with no sheet yet keep their old slice.
  5. Writes src/world/rock_looks.gd (where each material's looks start and how many there are) for the shader,
     and fixes the slice count in the two .import files so Godot cuts the tall picture right.

Run again any time a sheet changes; it always rebuilds from the 16 base slices.
Usage:  python tools/art/paint_terrain_looks.py [--out <folder>] [--sheets <folder>]   (both for testing)
Needs:  Python 3 with numpy, scipy, pillow.
"""
import json
import os
import re
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter

ROOT = Path(__file__).resolve().parents[2]
SHEETS = ROOT / "assets/concepts/terrain"
SIZE = 512  # matches the old slices; ChatGPT tiles in a 2x2 sheet are ~500 px, so bigger would only be blurrier
BASE_LAYERS = 16
# Material number (src/world/mat.gd) for each sheet name. Batch 1 (owner): stone, dirt, clay, moss.
MATERIALS = {"moss": 0, "stone": 1, "dirt": 2, "clay": 5}
COLOUR_MATCH = 0.6  # 0 = keep ChatGPT's colours, 1 = exactly today's average colour and contrast
BUMP = 3.0  # how strongly the painting's light/dark turns into bumps


def spans(frac, min_len):
	"""Runs of rows/columns that are NOT mostly light-grey gap."""
	out, start = [], None
	for i, f in enumerate(frac):
		if f < 0.6 and start is None:
			start = i
		if f >= 0.6 and start is not None:
			if i - start > min_len:
				out.append((start, i))
			start = None
	if start is not None and len(frac) - start > min_len:
		out.append((start, len(frac)))
	return out


def cut_sheet(path):
	"""The 4 paintings of a 2 x 2 sheet, left-to-right, top-to-bottom."""
	im = Image.open(path).convert("RGB")
	a = np.asarray(im).astype(float)
	grey = (np.abs(a[..., 0] - a[..., 1]) < 12) & (np.abs(a[..., 1] - a[..., 2]) < 12) & (a.mean(axis=2) > 190)
	min_len = min(im.size) // 5
	cols = spans(grey.mean(axis=0), min_len)
	rows = spans(grey.mean(axis=1), min_len)
	if len(cols) != 2 or len(rows) != 2:
		# No clear grey gaps: split the picture into even quarters.
		w, h = im.size
		cols = [(0, w // 2), (w // 2, w)]
		rows = [(0, h // 2), (h // 2, h)]
		print("  %s: no grey gaps found, cutting into even quarters" % path.name)
	tiles = []
	for (y0, y1) in rows:
		for (x0, x1) in cols:
			s = min(x1 - x0, y1 - y0) - 12  # square, a little inside the edge (painted borders, shadows)
			cx, cy = (x0 + x1) // 2, (y0 + y1) // 2
			t = im.crop((cx - s // 2, cy - s // 2, cx - s // 2 + s, cy - s // 2 + s))
			tiles.append(np.asarray(t.resize((SIZE, SIZE), Image.LANCZOS)).astype(np.float32) / 255.0)
	return tiles


def seamless(x):
	"""Blend the tile with itself shifted by half, so its edges match when it repeats."""
	h, w = x.shape[:2]
	s = np.roll(np.roll(x, h // 2, 0), w // 2, 1)
	yy, xx = np.mgrid[0:h, 0:w]
	m = np.minimum(np.minimum(xx, w - 1 - xx), np.minimum(yy, h - 1 - yy)) / (min(w, h) * 0.25)
	m = m.clip(0, 1)[..., None]
	return x * m + s * (1 - m)


def match_colour(x, ref, amount):
	"""Move the tile's average colour and contrast toward today's slice for this material."""
	mx, sx = x.reshape(-1, 3).mean(0), x.reshape(-1, 3).std(0) + 1e-4
	mr, sr = ref.reshape(-1, 3).mean(0), ref.reshape(-1, 3).std(0) + 1e-4
	y = (x - mx) * (sr / sx) + mr
	return np.clip(x * (1 - amount) + y * amount, 0, 1)


def normal_from_paint(x):
	"""Bump picture from the painting: bright = sticks out, dark cracks = dips. Wraps, so it stays seamless."""
	lum = x @ np.array([0.299, 0.587, 0.114], dtype=np.float32)
	hgt = gaussian_filter(lum, 1.2, mode="wrap") * 0.7 + gaussian_filter(lum, 5.0, mode="wrap") * 0.3
	dx = (np.roll(hgt, -1, 1) - np.roll(hgt, 1, 1)) * 0.5 * BUMP * SIZE / 64
	dy = (np.roll(hgt, -1, 0) - np.roll(hgt, 1, 0)) * 0.5 * BUMP * SIZE / 64
	n = np.dstack([-dx, dy, np.ones_like(hgt)])  # OpenGL style (green = up), like the old ambientCG normals
	n /= np.linalg.norm(n, axis=2, keepdims=True)
	return n * 0.5 + 0.5


def set_slices(import_path, count):
	if not import_path.exists():
		return
	txt = import_path.read_text(encoding="utf-8")
	import_path.write_text(re.sub(r"slices/vertical=\d+", "slices/vertical=%d" % count, txt), encoding="utf-8", newline="\n")


def main():
	out_dir = ROOT / "assets/textures/terrain"
	if "--out" in sys.argv:
		out_dir = Path(sys.argv[sys.argv.index("--out") + 1])
		out_dir.mkdir(parents=True, exist_ok=True)
	sheets = Path(sys.argv[sys.argv.index("--sheets") + 1]) if "--sheets" in sys.argv else SHEETS
	src_dir = ROOT / "assets/textures/terrain"
	alb_old = np.asarray(Image.open(src_dir / "terrain_albedo.png").convert("RGBA")).astype(np.float32) / 255.0
	nrm_old = np.asarray(Image.open(src_dir / "terrain_normal.png").convert("RGB")).astype(np.float32) / 255.0
	old = alb_old.shape[1]
	if old != SIZE:
		sys.exit("old slices are %d px, this script makes %d px" % (old, SIZE))
	albedo = [alb_old[i * SIZE:(i + 1) * SIZE] for i in range(BASE_LAYERS)]
	normal = [nrm_old[i * SIZE:(i + 1) * SIZE] for i in range(BASE_LAYERS)]
	# The base slices of painted materials are overwritten each run, so keep the photo colour reference
	# in a small file the first time (the colour match always aims at the old look, not at the last run).
	ref_path = src_dir / "photo_reference.json"
	refs = json.loads(ref_path.read_text()) if ref_path.exists() else {}
	start = list(range(BASE_LAYERS))
	count = [1] * BASE_LAYERS
	tiles_dir = out_dir / "painted"
	for name, mat in MATERIALS.items():
		sheet = sheets / ("%s_sheet.png" % name)
		if not sheet.exists():
			continue
		print("material", mat, name)
		if name not in refs:
			rgb = albedo[mat][..., :3]
			refs[name] = {"mean": rgb.reshape(-1, 3).mean(0).tolist(), "std": rgb.reshape(-1, 3).std(0).tolist()}
		r = refs[name]
		looks = []
		for k, t in enumerate(cut_sheet(sheet)):
			# A tiny stand-in picture with the reference mean/contrast, for match_colour.
			ref = np.array(r["mean"], np.float32) + np.array(r["std"], np.float32) * np.array([[[-1.0]], [[1.0]]], np.float32)
			t = seamless(match_colour(t, ref, COLOUR_MATCH))
			a = np.dstack([t, np.zeros(t.shape[:2], np.float32)])  # no glowing veins in these materials
			looks.append((a, normal_from_paint(t)))
			tiles_dir.mkdir(parents=True, exist_ok=True)
			Image.fromarray((t * 255).astype(np.uint8)).save(tiles_dir / ("%s_%d.png" % (name, k + 1)))
		albedo[mat], normal[mat] = looks[0]
		start[mat] = len(albedo) if len(looks) > 1 else mat
		count[mat] = len(looks)
		# Looks 2-4 sit next to each other after slice 16; look 1 stays in the material's own slice.
		# The shader uses: look 0 -> slice mat, look k>0 -> slice start + k - 1.
		for a, n in looks[1:]:
			albedo.append(a)
			normal.append(n)
	if not ref_path.exists() or out_dir == src_dir:
		ref_path.write_text(json.dumps(refs, indent=1) + "\n", encoding="utf-8", newline="\n")
	total = len(albedo)
	big_a = np.concatenate(albedo, 0)
	big_n = np.concatenate(normal, 0)
	Image.fromarray((big_a * 255 + 0.5).astype(np.uint8), "RGBA").save(out_dir / "terrain_albedo.png", optimize=True)
	Image.fromarray((big_n * 255 + 0.5).astype(np.uint8), "RGB").save(out_dir / "terrain_normal.png", optimize=True)
	looks_gd = (ROOT / "src/world/rock_looks.gd") if out_dir == src_dir else (out_dir / "rock_looks.gd")
	looks_gd.write_text(
		"# Made by tools/art/paint_terrain_looks.py, do not edit by hand.\n"
		"# Where each rock material's extra paintings (\"looks\") sit in terrain_albedo.png (F213).\n"
		"class_name RockLooks\n\n"
		"const START: Array[int] = %s\n" % start
		+ "const COUNT: Array[int] = %s\n" % count, encoding="utf-8", newline="\n")
	set_slices(out_dir / "terrain_albedo.png.import", total)
	set_slices(out_dir / "terrain_normal.png.import", total)
	print("done:", total, "slices; looks per material:", count)


if __name__ == "__main__":
	main()
