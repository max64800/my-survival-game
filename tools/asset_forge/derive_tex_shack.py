# Cut the Delver's Shack texture sheet (ChatGPT, same chat as the Shack kit pictures) into kit textures:
#   shackbark, shackplank, shackshingle, shacklogend, shackstone, shackdark  (_a, _b, _c: small brightness changes)
# python tools/asset_forge/derive_tex_shack.py
from pathlib import Path
import numpy as np
from PIL import Image, ImageEnhance
ROOT = Path(__file__).resolve().parents[2]
SHEET = ROOT / "assets/concepts/building-kit/shack_texture_sheet.png"
OUT = ROOT / "assets/textures/kit"
im = Image.open(SHEET).convert("RGB")
a = np.asarray(im).astype(float)
grey = (np.abs(a[..., 0] - a[..., 1]) < 10) & (np.abs(a[..., 1] - a[..., 2]) < 10) & (a.mean(axis=2) > 200)


def spans(frac):
	"""Runs of rows/columns that are NOT mostly light-grey gap."""
	out, start = [], None
	for i, f in enumerate(frac):
		if f < 0.6 and start is None:
			start = i
		if f >= 0.6 and start is not None:
			if i - start > 100:
				out.append((start, i))
			start = None
	if start is not None and len(frac) - start > 100:
		out.append((start, len(frac)))
	return out


cols = spans(grey.mean(axis=0))
rows = spans(grey.mean(axis=1))
assert len(cols) == 3 and len(rows) == 2, (cols, rows)
names = ["shackbark", "shackplank", "shackshingle", "shacklogend", "shackstone", "shackdark"]


def seamless(t):
	"""Blend the tile with itself shifted by half, so its edges match (for textures that repeat)."""
	x = np.asarray(t).astype(float)
	h, w = x.shape[:2]
	s = np.roll(np.roll(x, h // 2, 0), w // 2, 1)
	yy, xx = np.mgrid[0:h, 0:w]
	m = np.minimum(np.minimum(xx, w - 1 - xx) / (w * 0.25), np.minimum(yy, h - 1 - yy) / (h * 0.25)).clip(0, 1)[..., None]
	return Image.fromarray((x * m + s * (1 - m)).astype(np.uint8))


def seamless_v(t):
	"""Blend top and bottom so the picture repeats along the grain without a seam (planks keep their side edges)."""
	x = np.asarray(t).astype(float)
	h = x.shape[0]
	s = np.roll(x, h // 2, 0)
	yy = np.mgrid[0:h][:, None, None]
	m = (np.minimum(yy, h - 1 - yy) / (h * 0.25)).clip(0, 1)
	return Image.fromarray((x * m + s * (1 - m)).astype(np.uint8))


k = 0
for (y0, y1) in rows:
	for (x0, x1) in cols:
		t = im.crop((x0 + 4, y0 + 4, x1 - 4, y1 - 4)).resize((512, 512), Image.LANCZOS)
		n = names[k]
		if n in ("shackbark", "shackstone"):
			t = seamless(t)
		elif n in ("shackplank", "shackdark"):
			t = seamless_v(t)
		t = ImageEnhance.Contrast(t).enhance(1.12)
		for v, br in (("a", 0.9), ("b", 0.78), ("c", 0.98)):  # a bit darker and richer, like the picture
			ImageEnhance.Brightness(t).enhance(br).save(OUT / f"{n}_{v}.png")
		print("made", n)
		k += 1

# The variant sheet (Rule 6): 8 planks, 4 barks, 4 chopped log ends -> shackplank_v0..v7, shackbark_v0..v3, shacklogend_v0..v3
VAR = ROOT / "assets/concepts/building-kit/shack_texture_variants.png"
if VAR.exists():
	im = Image.open(VAR).convert("RGB")
	a = np.asarray(im).astype(float)
	grey = (np.abs(a[..., 0] - a[..., 1]) < 10) & (np.abs(a[..., 1] - a[..., 2]) < 10) & (a.mean(axis=2) > 200)
	cols, rows = spans(grey.mean(axis=0)), spans(grey.mean(axis=1))
	assert len(cols) == 4 and len(rows) == 4, (cols, rows)
	for r, (y0, y1) in enumerate(rows):
		for c, (x0, x1) in enumerate(cols):
			t = im.crop((x0 + 3, y0 + 3, x1 - 3, y1 - 3)).resize((512, 512), Image.LANCZOS)
			if r < 2:
				name, t = f"shackplank_v{r * 4 + c}", seamless_v(t)
			elif r == 2:
				name, t = f"shackbark_v{c}", seamless(t)
			else:
				name = f"shacklogend_v{c}"
			t.save(OUT / f"{name}.png")
	print("made 16 variants")

# Medium-variety shades of each bark (Rule 6): darker (d) and redder (r) copies -> 12 different bark paintings.
for i in range(4):
	src = OUT / f"shackbark_v{i}.png"
	if src.exists():
		b = Image.open(src).convert("RGB")
		ImageEnhance.Brightness(b).enhance(0.8).save(OUT / f"shackbark_v{i}d.png")
		x = np.asarray(b).astype(float)
		x[..., 0] *= 1.1
		x[..., 2] *= 0.85
		ImageEnhance.Brightness(Image.fromarray(x.clip(0, 255).astype(np.uint8))).enhance(0.92).save(OUT / f"shackbark_v{i}r.png")
print("made bark shades")

# The shingle variant sheet (Rule 6): 8 different shingles -> shackshingle_v0..v7 (dark butt edge at the bottom).
SH = ROOT / "assets/concepts/building-kit/shack_shingle_variants.png"
if SH.exists():
	im = Image.open(SH).convert("RGB")
	a = np.asarray(im).astype(float)
	grey = (np.abs(a[..., 0] - a[..., 1]) < 10) & (np.abs(a[..., 1] - a[..., 2]) < 10) & (a.mean(axis=2) > 200)
	cols, rows = spans(grey.mean(axis=0)), spans(grey.mean(axis=1))
	assert len(cols) == 4 and len(rows) == 2, (cols, rows)
	for r, (y0, y1) in enumerate(rows):
		for c, (x0, x1) in enumerate(cols):
			im.crop((x0 + 3, y0 + 3, x1 - 3, y1 - 3)).resize((512, 512), Image.LANCZOS).save(OUT / f"shackshingle_v{r * 4 + c}.png")
	print("made 8 shingles")
