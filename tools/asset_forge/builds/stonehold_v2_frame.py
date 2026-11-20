# Stonehold, version 2: the brace and the ladder (owner, Nov 20: Stonehold gets the same frame pieces as the Shack
# and Hearthbrick). Same look as the Stonehold kit: chunky grey cut stone, dark timber, dark iron with rivets.
#   blender --background --factory-startup --python builds/stonehold_v2_frame.py -- [grey] [out=<folder>] [install=1] [piece ...]
# Pieces: brace, ladder. Default output: journey/stonehold_v2/glb_frame (the game's files only with install=1).
import math
import sys
from pathlib import Path

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kit  # noqa: E402
import kit_zone1 as K  # noqa: E402
import stonehold_v2 as SV  # noqa: E402

E = SV.E
blk = K.blk
OUT_DEFAULT = K.GAME / "journey" / "stonehold_v2" / "glb_frame"
K.SIZE.update({"brace": (2, 2, 0.25), "ladder": (1, 2, 0.2)})


def tagged(role, fn, *a, **kw):
	"""Run one builder call and tag everything it made with `role`."""
	before = set(bpy.data.objects)
	o = fn(*a, **kw)
	SV._tag(SV._new_since(before), role)
	return o


def iron_rivet(c, r=0.012):
	tagged("iron", kit.rivet, K.G(c), kit.tex_mat("iron", "dark"), r=r)


def brace(w=2.0, h=2.0, d=0.25):
	"""A hewn dark timber strut from bottom left to top right, its ends set on chunky cut-stone pads, held by
	riveted dark iron straps near both ends (like the Stonehold door's iron)."""
	pad_h, pad_w = 0.26, 0.42
	x0, x1 = -w / 2 + E, w / 2 - E
	pd = d - 2 * E - 0.004
	for (xa, xb, ya, yb) in ((x0, x0 + pad_w, E, pad_h), (x1 - pad_w, x1, h - pad_h, h - E)):
		SV.block(((xa + xb) / 2, (ya + yb) / 2, 0), (xb - xa - 0.004, yb - ya - 0.004, pd), cut=0.035, tilt=0.0, dent=0.02, free="xz")
	hw = 0.17 * math.sqrt(2) / 2   # half the strut's width, measured sideways
	ya, yb = pad_h + 0.002, h - pad_h - 0.002
	ca = x0 + pad_w / 2 + 0.03     # the strut's centre line where it meets each pad
	cb = ca + (yb - ya)
	fr = K.Frame()
	pts = [(ca - hw, ya), (ca + hw, ya), (cb + hw, yb), (cb - hw, yb)]
	SV.prism(fr, pts, 0.0, 0.16, SV.timber_m(), cut=0.02, role="timber")
	ux, uy = 1 / math.sqrt(2), 1 / math.sqrt(2)
	nx, ny = -uy, ux
	for t in (0.28, 0.72):   # iron straps round the strut, front and back
		cx, cy = ca + (cb - ca) * t, ya + (yb - ya) * t
		for zs in (1, -1):
			q = [(cx + ux * s * 0.07 + nx * n * 0.07, cy + uy * s * 0.07 + ny * n * 0.07) for (s, n) in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
			tagged("iron", K.slab_poly, fr, q, zs * 0.0865, 0.011, SV.iron_m())
			for n in (-0.038, 0.038):
				iron_rivet((cx + nx * n, cy + ny * n, zs * 0.093), r=0.011)


def ladder(w=1.0, h=2.0, d=0.2):
	"""Two chunky dark timber rails with timber rungs, bound by riveted dark iron bands; the feet rest on small
	cut-stone blocks (Stonehold: stone wherever it touches the ground)."""
	rx, rw, rd = 0.38, 0.085, 0.095
	foot = 0.1
	for sx in (-1, 1):
		SV.block((sx * rx, E + foot / 2, 0), (rw + 0.05, foot - 0.002, rd + 0.05), cut=0.02, tilt=0.0, dent=0.012, free="xz")
		o = blk((sx * rx, (E + foot + h - E) / 2, 0), (rw, h - E - foot - E - 0.004, rd), SV.timber_m(), bevel=0)
		SV.chisel(o, cut=0.016, dent=0.008, axes=(0, 1))
		o["role"] = "timber"
		for y in (0.26, 1.04, h - E - 0.05):
			tagged("iron", blk, (sx * rx, y, 0), (rw + 0.016, 0.04, rd + 0.016), SV.iron_m(), bevel=0.004)
			iron_rivet((sx * rx, y, rd / 2 + 0.01), r=0.009)
	inner = rx - rw / 2 + 0.004
	y = 0.4
	while y < h - 0.15:
		o = blk((0, y + K.rng.uniform(-0.01, 0.01), 0), (2 * inner, 0.058, 0.064), SV.timber_m(), bevel=0)
		SV.chisel(o, cut=0.012, dent=0.008, axes=(1, 2))
		o["role"] = "timber"
		y += 0.3


PIECES = {"brace": brace, "ladder": ladder}


if __name__ == "__main__":
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	grey = "grey" in args
	out_dir = next((Path(a[4:]) for a in args if a.startswith("out=")), OUT_DEFAULT)
	names = [a for a in args if a in PIECES] or list(PIECES)
	install = "install=1" in args
	if install:
		out_dir = K.OUT
	out_dir.mkdir(parents=True, exist_ok=True)
	for name in names:
		K.rng.seed(sum(map(ord, name + "stonehold2")))
		kit.reset()
		PIECES[name]()
		K.fit_check(name)
		if grey:
			SV.make_grey()
		else:
			SV.paint()
		png = str(K.JOUR / f"{name}__cut_stone.png") if install else None
		kit.save(str(out_dir / f"{name}__cut_stone.glb"), png, recenter=False, tex_size=512)
		print("PIECE_OK", name)
