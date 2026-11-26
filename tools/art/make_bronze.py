"""Bronze paint (F697 step 4): bronze is copper repainted a darker gold-brown, so bronze is playable fast.

    python3 tools/art/make_bronze.py textures   -> assets/textures/kit/bronze_<a|b|c|dark>.png (from copper_*)
    python3 tools/art/make_bronze.py icons      -> assets/icons/<id>_bronze.png + bronze_ingot.png (from the copper icons)
    python3 tools/art/make_bronze.py tin        -> assets/textures/kit/tin_<a|b|c|dark>.png + assets/icons/tin_ingot.png
                                                   (F894: silver made duller, darker and a little blue-grey)

The Blender builds (items_tools.py, items_gear.py, items_materials.py) then paint "bronze" parts with the new textures.
Plan step 7 (Nov 26): the 4 armour pieces have their own models now (items_gear.py helm_bronze etc.); the rest still come from here.
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

GAME = Path(__file__).resolve().parents[2]
KIT = GAME / "assets" / "textures" / "kit"
ICONS = GAME / "assets" / "icons"

HUE_SHIFT = 12.0 / 360.0   # copper orange (~20 deg) -> bronze gold-brown (~32 deg; 15 looked olive)
SAT = 0.95
VAL = 0.9                  # a little darker than copper
# copper icon -> bronze icon (same picture, the metal repainted)
# (helm, mail, greaves, boots have their own painted icons now: tools/art/cut_bronze_armour_icons.py, F697 step 7)
ICON_IDS = ["shield", "crossbow", "spear", "axe", "sword", "mace",
	"axe_2h", "mace_2h", "pickaxe"]


def _hsv(rgb):
	"""rgb (h, w, 3) floats 0..1 -> h, s, v arrays."""
	r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
	mx, mn = rgb.max(-1), rgb.min(-1)
	d = mx - mn
	h = np.zeros_like(mx)
	nz = d > 1e-6
	rm = nz & (mx == r)
	gm = nz & (mx == g) & ~rm
	bm = nz & ~rm & ~gm
	h[rm] = ((g - b)[rm] / d[rm]) % 6
	h[gm] = (b - r)[gm] / d[gm] + 2
	h[bm] = (r - g)[bm] / d[bm] + 4
	h = h / 6.0
	s = np.where(mx > 1e-6, d / np.maximum(mx, 1e-6), 0)
	return h, s, mx


def _rgb(h, s, v):
	i = np.floor(h * 6).astype(int) % 6
	f = h * 6 - np.floor(h * 6)
	p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
	out = np.zeros(h.shape + (3,))
	for k, (a, b, c) in enumerate(((v, t, p), (q, v, p), (p, v, t), (p, q, v), (t, p, v), (v, p, q))):
		m = i == k
		out[m] = np.stack([a[m], b[m], c[m]], -1)
	return out


def bronze(rgb, weight=None):
	"""Repaint copper as bronze. weight (h, w) 0..1 says how much of each pixel is copper (icons); None = all."""
	h, s, v = _hsv(rgb)
	nb = _rgb((h + HUE_SHIFT) % 1.0, np.clip(s * SAT, 0, 1), np.clip(v * VAL, 0, 1))
	if weight is None:
		return nb
	w = weight[..., None]
	return rgb * (1 - w) + nb * w


def copper_weight(rgb):
	"""How copper-coloured each icon pixel is: bright, saturated orange. Wood and leather are darker or duller."""
	h, s, v = _hsv(rgb)
	deg = h * 360.0
	hue_ok = np.clip(1 - np.abs(deg - 22.0) / 18.0, 0, 1)
	return hue_ok * np.clip((s - 0.35) / 0.2, 0, 1) * np.clip((v - 0.38) / 0.15, 0, 1)


def textures():
	for v in ("a", "b", "c", "dark"):
		im = Image.open(KIT / f"copper_{v}.png").convert("RGBA")
		a = np.asarray(im).astype(float) / 255
		a[..., :3] = bronze(a[..., :3])
		Image.fromarray((a * 255).round().astype(np.uint8)).save(KIT / f"bronze_{v}.png")
		print("wrote", f"bronze_{v}.png")


def icons():
	pairs = [(f"{i}_copper", f"{i}_bronze") for i in ICON_IDS] + [("copper_ingot", "bronze_ingot")]
	for src, dst in pairs:
		im = Image.open(ICONS / f"{src}.png").convert("RGBA")
		a = np.asarray(im).astype(float) / 255
		w = None if src == "copper_ingot" else copper_weight(a[..., :3])
		a[..., :3] = bronze(a[..., :3], w)
		Image.fromarray((a * 255).round().astype(np.uint8)).save(ICONS / f"{dst}.png")
		print("wrote", f"{dst}.png")


def tin_paint(rgb):
	"""Silver -> tin: much less shine and colour, a bit darker, a cool blue-grey tint."""
	grey = rgb.mean(-1, keepdims=True)
	out = grey + (rgb - grey) * 0.4             # less colour
	out = 0.5 + (out - 0.5) * 0.75              # flatter: tin is dull, not mirror-bright
	out = (out * 1.08 + 0.04) * np.array([0.96, 0.99, 1.04])
	return np.clip(out, 0, 1)


def tin():
	for v in ("a", "b", "c", "dark"):
		a = np.asarray(Image.open(KIT / f"silver_{v}.png").convert("RGBA")).astype(float) / 255
		a[..., :3] = tin_paint(a[..., :3])
		Image.fromarray((a * 255).round().astype(np.uint8)).save(KIT / f"tin_{v}.png")
		print("wrote", f"tin_{v}.png")
	a = np.asarray(Image.open(ICONS / "silver_ingot.png").convert("RGBA")).astype(float) / 255
	a[..., :3] = tin_paint(a[..., :3])
	Image.fromarray((a * 255).round().astype(np.uint8)).save(ICONS / "tin_ingot.png")
	print("wrote tin_ingot.png")


if __name__ == "__main__":
	what = sys.argv[1] if len(sys.argv) > 1 else "all"
	if what in ("textures", "all"):
		textures()
	if what in ("icons", "all"):
		icons()
	if what in ("tin", "all"):
		tin()
