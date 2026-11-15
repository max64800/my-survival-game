"""Makes the creatures' skin textures from the kit's hand-painted ones (Claude 2's, see CREDITS.md):
softer contrast (no cow spots) and tinted to each creature's colors.

    python tools/asset_forge/creature_textures.py
Writes assets/textures/creatures/<name>.png (used by tools/asset_forge/builds/monster_*.py).
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
KIT = ROOT / "assets" / "textures" / "kit"
OUT = ROOT / "assets" / "textures" / "creatures"

# name: (source, keep contrast 0..1, tint rgb 0..1, brightness, blur radius of the big blotches removed)
RECIPES = {
	"snail_skin": ("leather_dark", 0.45, (0.50, 0.44, 0.36), 1.05, 24),
	"snail_sole": ("leather_a", 0.3, (0.62, 0.55, 0.45), 1.0, 24),
	"bat_fur": ("cloth_dark", 0.9, (0.30, 0.25, 0.24), 1.1, 0),
	"bat_wing": ("leather_dark", 0.5, (0.30, 0.22, 0.22), 1.0, 24),
	"bat_skin": ("leather_a", 0.4, (0.55, 0.40, 0.38), 1.0, 24),
	"chitin": ("leather_dark", 0.6, (0.20, 0.18, 0.16), 1.0, 24),
	"beetle_soft": ("leather_a", 0.35, (0.84, 0.72, 0.54), 1.0, 24),
	"shell_rock": ("stone_c", 0.7, (0.56, 0.52, 0.47), 1.0, 0),
	"shell_rock_dark": ("stone_dark", 0.7, (0.40, 0.37, 0.34), 1.0, 0),
}


def make(src, keep, tint, bright, blur):
	im = Image.open(KIT / f"{src}.png").convert("RGB")
	if src.startswith("stone"):
		im = im.filter(ImageFilter.MedianFilter(9))  # melt the cobblestone joints into rough rock
	a = np.asarray(im).astype(float) / 255.0
	lum = a.mean(axis=2, keepdims=True)
	if blur:
		big = np.asarray(Image.fromarray((lum[..., 0] * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(blur))).astype(float)[..., None] / 255.0
		lum = lum - big + big.mean()  # remove the big blotches, keep the fine grain
	m = lum.mean()
	lum = m + (lum - m) * keep
	out = np.clip(lum / max(m, 1e-3) * np.array(tint) * bright, 0, 1)
	return Image.fromarray((out * 255).astype(np.uint8))


def _cells(size, n, seed):
	"""Distance to the nearest and second-nearest of n random points, wrapping at the edges (tiles)."""
	from scipy.spatial import cKDTree
	r = np.random.default_rng(seed)
	pts = r.random((n, 2)) * size
	tree = cKDTree(pts, boxsize=size)
	yy, xx = np.mgrid[0:size, 0:size]
	d, _ = tree.query(np.stack([xx.ravel() + 0.5, yy.ravel() + 0.5], 1), k=2)
	return d[:, 0].reshape(size, size), d[:, 1].reshape(size, size)


def _noise(size, scale, seed):
	"""Soft blotchy noise that tiles (blurred random, wrapped)."""
	r = np.random.default_rng(seed)
	small = r.random((max(2, size // scale), max(2, size // scale)))
	im = Image.fromarray((small * 255).astype(np.uint8)).resize((size, size), Image.BICUBIC)
	a = np.asarray(im).astype(float) / 255.0
	return (a - a.min()) / (np.ptp(a) + 1e-6)


def snail_skin(size=512):
	"""Real snail skin: little raised bumps (tubercles) with dark grooves between, mottled."""
	f1, f2 = _cells(size, 420, 3)
	groove = np.clip((f2 - f1) / 5.0, 0, 1)          # 0 in the grooves, 1 on the bumps
	dome = 1 - np.clip(f1 / (f2 + 1e-6), 0, 1) * 0.6  # each bump a bit lighter in its middle
	mott = _noise(size, 48, 4)
	base = np.array([0.40, 0.37, 0.35]) * (0.75 + 0.5 * mott[..., None])  # slate grey-brown, mottled
	warm = np.array([0.52, 0.42, 0.30])
	col = base * (1 - 0.35 * mott[..., None]) + warm * 0.35 * mott[..., None]
	col = col * (0.68 + 0.32 * groove[..., None]) * (0.85 + 0.25 * dome[..., None])
	return Image.fromarray((np.clip(col, 0, 1) * 255).astype(np.uint8))


def knobbly_rock(size=512, tint=(0.66, 0.62, 0.56), seed=7, bumps=260):
	"""Ironclad-beetle armor: rounded stony knobs with dark pits between, speckled like granite."""
	f1, f2 = _cells(size, bumps, seed)
	knob = np.clip(1 - f1 / (f2 + 1e-6), 0, 1) ** 0.6
	pit = np.clip((f2 - f1) / 6.0, 0, 1)
	speck = np.random.default_rng(seed + 1).random((size, size))
	speck = np.where(speck > 0.985, 0.6, np.where(speck < 0.02, 1.25, 1.0))
	mott = _noise(size, 64, seed + 2)
	lum = (0.7 + 0.35 * knob) * (0.62 + 0.38 * pit) * (0.85 + 0.3 * mott) * speck
	col = np.array(tint)[None, None, :] * lum[..., None]
	return Image.fromarray((np.clip(col, 0, 1) * 255).astype(np.uint8))


def beetle_wax(size=512, seed=12):
	"""Ironclad-beetle shell skin: matte dark wax with black 'spilled paint' drops and pale specks."""
	r = np.random.default_rng(seed)
	mott = _noise(size, 40, seed)
	col = np.array([0.47, 0.44, 0.39])[None, None, :] * (0.8 + 0.35 * mott[..., None])  # stone grey-brown (darker read as black in game light)
	yy, xx = np.mgrid[0:size, 0:size]
	for _ in range(70):  # black drops, wrapping at the edges so the picture tiles
		cx, cy, rad = r.uniform(0, size), r.uniform(0, size), r.uniform(4, 16)
		dx = np.minimum(np.abs(xx - cx), size - np.abs(xx - cx))
		dy = np.minimum(np.abs(yy - cy), size - np.abs(yy - cy))
		drop = np.clip(1.2 - np.sqrt(dx ** 2 + dy ** 2) / rad, 0, 1)
		col = col * (1 - 0.7 * drop[..., None])
	speck = r.random((size, size)) > 0.993
	col[speck] = col[speck] * 0.4 + 0.45
	return Image.fromarray((np.clip(col, 0, 1) * 255).astype(np.uint8))


def pebble(size=512, tint=(0.62, 0.6, 0.56), seed=21):
	"""A smooth river pebble: soft, low-contrast stone with faint bands."""
	mott = _noise(size, 90, seed)
	fine = _noise(size, 8, seed + 1)
	yy = np.mgrid[0:size, 0:size][0]
	bands = 0.5 + 0.5 * np.sin(yy / size * 2 * np.pi * 3 + mott * 4)
	lum = 0.82 + 0.12 * mott + 0.05 * fine + 0.06 * bands
	return Image.fromarray((np.clip(np.array(tint)[None, None, :] * lum[..., None], 0, 1) * 255).astype(np.uint8))


def mossy_rock(size=512, seed=31):
	"""Rock with patches of moss growing over it."""
	rock = np.asarray(knobbly_rock(size, (0.58, 0.55, 0.5), seed, 200)).astype(float) / 255
	m = _noise(size, 70, seed + 3)
	moss = np.clip((m - 0.45) * 5, 0, 1)[..., None]
	fine = _noise(size, 6, seed + 4)[..., None]
	green = np.array([0.26, 0.34, 0.11]) * (0.75 + 0.5 * fine)
	return Image.fromarray((np.clip(rock * (1 - moss) + green * moss, 0, 1) * 255).astype(np.uint8))


def recolor(src, mult, desat=0.0):
	"""A color version of one of our textures: tint each channel, optionally greyer."""
	a = np.asarray(Image.open(OUT / f"{src}.png").convert("RGB")).astype(float) / 255
	if desat:
		g = a.mean(axis=2, keepdims=True)
		a = a * (1 - desat) + g * desat
	return Image.fromarray((np.clip(a * np.array(mult), 0, 1) * 255).astype(np.uint8))


# Color versions (the game picks one per creature, see MonsterModel.build).
BAT_COLORS = {1: ((1.15, 1.15, 1.25), 0.85), 2: ((1.32, 0.98, 0.84), 0.15), 3: ((1.75, 1.55, 1.25), 0.3)}   # ash grey, rust, sandy
SNAIL_COLORS = {1: ((0.95, 1.05, 0.78), 0.0), 2: ((1.2, 0.92, 0.72), 0.0)}                               # olive, rusty
SHELL_COLORS = {1: ((1.12, 1.03, 0.85), 0.0), 2: ((0.72, 0.75, 0.82), 0.2)}                              # sandy, dark slate


def main():
	OUT.mkdir(parents=True, exist_ok=True)
	for name, r in RECIPES.items():
		make(*r).save(OUT / f"{name}.png")
		print("made", name)
	snail_skin().save(OUT / "snail_skin2.png")
	knobbly_rock().save(OUT / "beetle_rock.png")
	knobbly_rock(tint=(0.45, 0.42, 0.39), seed=9).save(OUT / "beetle_rock_dark.png")
	print("made snail_skin2, beetle_rock, beetle_rock_dark")
	beetle_wax().save(OUT / "beetle_wax.png")
	pebble().save(OUT / "pebble_light.png")
	pebble(tint=(0.6, 0.5, 0.4), seed=22).save(OUT / "pebble_warm.png")
	pebble(tint=(0.34, 0.33, 0.32), seed=23).save(OUT / "pebble_dark.png")
	mossy_rock().save(OUT / "mossy_rock.png")
	for v, (mult, d) in BAT_COLORS.items():
		for t in ("bat_fur", "bat_wing", "bat_skin"):
			recolor(t, mult, d).save(OUT / f"{t}_v{v}.png")
	for v, (mult, d) in SNAIL_COLORS.items():
		recolor("snail_skin2", mult, d).save(OUT / f"snail_skin2_v{v}.png")
	for v, (mult, d) in SHELL_COLORS.items():
		for t in ("shell_rock", "shell_rock_dark"):
			recolor(t, mult, d).save(OUT / f"{t}_v{v}.png")
	print("made wax, pebbles, mossy rock and the color versions")


if __name__ == "__main__":
	main()
