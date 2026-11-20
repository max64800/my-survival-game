# Cut the Hearthbrick texture sheet (ChatGPT, owner's chat "Generate Building Kit Sheet", Nov 20) into kit textures:
#   hbbrick_a.._f (six brick colours), hbbrick_ochre, hbbrick_dark (burnt), hblime_a.._d, hbmortar_a, hbrune_a,
#   hbtimber_a, hbcopper_a      (assets/textures/kit/, used by builds/hearthbrick_v2.py)
# python -I tools/asset_forge/derive_tex_hearthbrick.py
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SHEET = ROOT / "assets/concepts/building-kit/hearthbrick_texture_sheet.png"
OUT = ROOT / "assets/textures/kit"
NAMES = ["hbbrick_a", "hbbrick_b", "hbbrick_c", "hbbrick_d",
	"hbbrick_e", "hbbrick_f", "hbbrick_ochre", "hbbrick_dark",
	"hblime_a", "hblime_b", "hblime_c", "hblime_d",
	"hbmortar_a", "hbrune_a", "hbtimber_a", "hbcopper_a"]


def spans(frac, n):
	"""The n runs of rows/columns that are NOT mostly light-grey gap."""
	out, start = [], None
	for i, f in enumerate(frac):
		if f < 0.5 and start is None:
			start = i
		if f >= 0.5 and start is not None:
			if i - start > 60:
				out.append((start, i))
			start = None
	if start is not None and len(frac) - start > 60:
		out.append((start, len(frac)))
	assert len(out) == n, out
	return out


def seamless(t):
	"""Blend the tile with itself shifted by half, so its edges match when it repeats."""
	x = np.asarray(t).astype(float)
	h, w = x.shape[:2]
	s = np.roll(np.roll(x, h // 2, 0), w // 2, 1)
	yy, xx = np.mgrid[0:h, 0:w]
	m = np.minimum(np.minimum(xx, w - 1 - xx) / (w * 0.25), np.minimum(yy, h - 1 - yy) / (h * 0.25)).clip(0, 1)[..., None]
	return Image.fromarray((x * m + s * (1 - m)).astype(np.uint8))


im = Image.open(SHEET).convert("RGB")
a = np.asarray(im).astype(float)
grey = (np.abs(a[..., 0] - a[..., 1]) < 12) & (np.abs(a[..., 1] - a[..., 2]) < 12) & (a.mean(axis=2) > 170)
cols, rows = spans(grey.mean(axis=0), 4), spans(grey.mean(axis=1), 4)
k = 0
for (y0, y1) in rows:
	for (x0, x1) in cols:
		t = im.crop((x0 + 5, y0 + 5, x1 - 5, y1 - 5)).resize((512, 512), Image.LANCZOS)
		n = NAMES[k]
		if n != "hbrune_a":   # the rune band keeps its three rows exactly (it's mapped one row per band)
			t = seamless(t)
		t.save(OUT / f"{n}.png")
		print("made", n)
		k += 1
