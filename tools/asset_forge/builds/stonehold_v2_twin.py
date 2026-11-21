# The Twin Gate (owner, Nov 21: ruin 6 of Zone 1, the first showpiece, docs/design/GRAND-RUIN-RECIPE.md): the new
# Stonehold pieces a grand building needs. Every stone is a real chisel-cut Stonehold stone (builds/stonehold_v2.py:
# block, prism, slab_xz, the copper band), painted with the same stone set. Pieces are centred in their box like
# every piece; front (outward) is +z.
#   corbel          a bracket under a floor that juts 1 m out past the wall below: three stones stepping out, the
#                   lowest rounded, the top one reaching the jutting floor's edge. Its back 1 cm off the wall's face.
#   cornice         a trim band at a floor line (2 m), on a wall's outside face: four stepped courses of stones, the
#                   top course widest, covering the seam where the floor meets the walls.
#   cornice_corner  the band's outer corner block (fills the corner where two bands meet at a right angle)
#   buttress        a stone pier against a wall on a foundation (2.85 m): a wide footing against the foundation, a
#                   stage with a sloped weathering, a narrower upper stage with a sloped cap; it stops under the band.
#   bartizan        a little round corner turret hanging off a square tower's corner at its deck: a corbelled cone of
#                   stepping stone courses wedged into the corner, a round parapet with arrow loops and a copper band,
#                   four merlons on top, a flagstone floor level with the deck. The tower is at -x, -z.
# Saved in journey/ until the owner's OK (not game pieces yet); install=1 puts them in the game.
#   blender --background --factory-startup --python builds/stonehold_v2_twin.py -- [grey] [out=<folder>] [install=1] [piece ...]
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kit  # noqa: E402
import kit_zone1 as K  # noqa: E402
import stonehold_v2 as SV  # noqa: E402

E = SV.E
OUT_DEFAULT = SV.OUT_DEFAULT
SIZES = {"corbel": (0.5, 1.0, 0.82), "cornice": (2.0, 0.4, 0.17), "cornice_corner": (0.32, 0.4, 0.32),
	"buttress": (0.8, 2.85, 1.24), "bartizan": (1.5, 3.0, 1.5)}
K.SIZE.update(SIZES)


def meshes():
	return [o for o in bpy.data.objects if o.type == "MESH"]


def side(x_off=0.0):
	"""A frame whose wall-plane x runs along the piece's z (out) and whose depth runs along the piece's x:
	prism outlines drawn as (z, y), extruded across the piece's width."""
	return K.Frame(ox=x_off, yaw=-90)


def clip_y(pts, y0, y1):
	"""The outline [(z, y)...] cut to the band y0..y1 (both lines)."""
	def cut(poly, yy, keep_above):
		out = []
		n = len(poly)
		for i in range(n):
			a, b = poly[i], poly[(i + 1) % n]
			ina = (a[1] >= yy) if keep_above else (a[1] <= yy)
			inb = (b[1] >= yy) if keep_above else (b[1] <= yy)
			if ina:
				out.append(a)
			if ina != inb:
				t = (yy - a[1]) / (b[1] - a[1])
				out.append((a[0] + (b[0] - a[0]) * t, yy))
		return out
	return cut(cut(pts, y0, True), y1, False)


# ---------------- the corbel ----------------
def corbel():
	"""Three stones, each a little deeper than the one under it; the bottom one's face curves up and out."""
	b = -0.41 + E                     # its back, 1 cm off the wall (it is placed 1.6 cm from the wall's line + face)
	f = 0.41 - E
	low = [(b, E), (b + 0.2, E)] + [(b + 0.2 + 0.2 * math.sin(math.radians(a)), E + 0.39 * (1 - math.cos(math.radians(a))))
		for a in (20, 40, 60, 80)] + [(b + 0.4, 0.398), (b, 0.398)]
	mid = [(b, 0.402), (b + 0.47, 0.402), (b + 0.56, 0.47), (b + 0.6, 0.698), (b, 0.698)]
	top = [(b, 0.702), (f - 0.04, 0.702), (f, 0.74), (f, 1.0 - E), (b, 1.0 - E)]
	for pts, w in ((low, 0.4), (mid, 0.45), (top, 0.5 - 2 * E - 0.002)):
		SV.prism(side(), pts, 0.0, w, cut=0.022)


# ---------------- the cornice and its corner ----------------
BANDS = [(E, 0.07, 0.05), (0.07, 0.15, 0.085), (0.15, 0.25, 0.12), (0.25, 0.4 - E, 0.158)]   # (y0, y1, how far out)


def cornice(w=2.0):
	back = -0.085 + E
	for i, (y0, y1, f) in enumerate(BANDS):
		n = 3 if i == 3 else 4
		off = 0.5 if i % 2 else 0.0
		ps = [w * (k + off) / n for k in range(n + 1)]
		cuts = [-w / 2 + E] + [-w / 2 + p + K.J(0.05) for p in ps if 0.15 < p < w - 0.15] + [w / 2 - E]
		g = 0.003
		for a, c in zip(cuts, cuts[1:]):
			m = kit.tex_mat("greystone", "dark") if i == 0 else SV.stone_m()
			SV.block(((a + c) / 2, (y0 + y1) / 2, back + f / 2), (c - a - g, y1 - y0 - g, f - 0.002), m,
				cut=0.012, tilt=0.0, dent=0.006, free="yz")


def cornice_corner():
	"""A corner block for two bands meeting at an outer corner: the same four steps, on its +x and +z faces."""
	lo = -0.16 + E
	for i, (y0, y1, f) in enumerate(BANDS):
		hi = f - 0.006 - 0.002
		m = kit.tex_mat("greystone", "dark") if i == 0 else SV.stone_m()
		SV.block(((lo + hi) / 2, (y0 + y1) / 2, (lo + hi) / 2), (hi - lo, y1 - y0 - 0.003, hi - lo), m,
			cut=0.012, tilt=0.0, dent=0.006, free="xyz")


# ---------------- the buttress ----------------
def buttress():
	"""Courses of stones following the side outline: a footing against the foundation (to 1 m), the wall face
	above it (15 cm further out), a lower stage, a sloped weathering, a narrower upper stage, a sloped cap."""
	B, F = -0.62 + E, 0.62 - E
	wall_face = B + 0.15                       # the wall's face above the foundation (1 cm gap kept)
	outline = [(B, E), (F, E), (F, 1.35), (0.3, 1.62), (0.3, 2.3), (wall_face + 0.04, 2.85 - E), (wall_face, 2.85 - E),
		(wall_face, 0.98), (B, 0.98)]
	ys = [E, 0.3, 0.6, 0.98, 1.27, 1.54, 1.82, 2.08, 2.34, 2.6, 2.85 - E]
	for i, (y0, y1) in enumerate(zip(ys, ys[1:])):
		pts = clip_y(outline, y0 + 0.0015, y1 - 0.0015)
		if len(pts) < 3:
			continue
		w = 0.8 - 2 * E if y1 <= 1.62 else 0.66
		if i % 2 == 0 and y1 <= 1.62:          # the lower stage: two stones side by side in every other course
			for sx in (-1, 1):
				SV.prism(side(sx * w / 4), pts, 0.0, w / 2 - 0.003, cut=0.022)
		else:
			SV.prism(side(), pts, 0.0, w, cut=0.022)


# ---------------- the bartizan ----------------
BK = -0.75 + E + 0.002      # its two back faces (against the tower's faces, 1 cm off)


def tear(r, n=18):
	"""The outline seen from above: a circle of radius r tucked into the corner (touching both back faces), the
	corner behind it filled: [(x, z)...] counter-clockwise."""
	c = BK + r
	pts = [(BK, BK)]
	for i in range(n + 1):
		a = math.radians(-90 + 270 * i / n)
		pts.append((c + r * math.cos(a), c + r * math.sin(a)))
	return pts


def ring_stones(outer, inner, y0, y1, per=3, shift=0, slits=()):
	"""Stones round a ring between two outlines with the same points: `per` segments each; `slits` = segment
	indices left open (arrow loops)."""
	n = len(outer)
	segs = list(range(n))
	groups, cur = [], []
	for k in range(n):
		i = (k + shift) % n
		cur.append(i)
		if len(cur) == per or i in (0, n - 1):
			groups.append(cur)
			cur = []
	if cur:
		groups.append(cur)
	g = 0.0025
	split = []
	for grp in groups:
		if any(i in slits for i in grp):
			split += [[i] for i in grp if i not in slits]
		else:
			split.append(grp)
	for grp in split:
		a, b = grp[0], (grp[-1] + 1) % n
		ids = grp + [b]
		pts = [outer[i] for i in ids] + [inner[i] for i in reversed(ids)]
		o0, o1 = Vector(outer[a]), Vector(outer[b])
		d = (o1 - o0).normalized() * g if (o1 - o0).length > 1e-6 else Vector((0, 0))
		pts[0] = tuple(Vector(pts[0]) + d)
		pts[len(ids) - 1] = tuple(Vector(pts[len(ids) - 1]) - d)
		pts[len(ids)] = tuple(Vector(pts[len(ids)]) - d)
		pts[-1] = tuple(Vector(pts[-1]) + d)
		SV.slab_xz(pts, y0, y1, kit.tex_mat("greystone", "dark") if K.rng.random() < 0.12 else SV.stone_m(), c=0.018)


def bartizan():
	R = 0.742
	deck = 1.6
	# the corbelled cone: courses stepping out from a small pendant stone tucked in the corner, a full-size course
	# under the floor
	SV.block((BK + 0.16, E + 0.21, BK + 0.16), (0.2, 0.4, 0.2), SV.stone_m(), cut=0.03, tilt=0.0, free="xyz")   # the pendant
	courses = [(0.16, 0.42, 0.68), (0.27, 0.68, 0.92), (0.38, 0.92, 1.12), (0.49, 1.12, 1.3), (0.6, 1.3, 1.44), (R, 1.44, deck)]
	for i, (r, y0, y1) in enumerate(courses):
		out = tear(r, 12 if r < R else 18)
		inn = SV._inset(out, min(0.2, r * 0.55))
		ring_stones(out, inn, y0 + 0.002, y1 - 0.002, per=2 if r < R else 3, shift=i)
		if r < R:
			SV.slab_xz(inn, y0 + 0.01, y1 - 0.01, SV.mortar_m(), c=0.005, role="mortar")   # its heart (never seen)
	# the floor (level with the deck) and the parapet
	out = tear(R, 18)
	inn = SV._inset(out, 0.2)
	flo = SV._inset(inn, 0.004)
	SV.slab_xz(flo, deck - 0.156, deck - 0.004, kit.tex_mat("greystone", "dark"), c=0.012)
	band_y = 2.32
	for k, (y0, y1) in enumerate([(deck, 1.85), (1.85, 2.1), (2.1, band_y - 0.002)]):
		ring_stones(out, inn, y0 + 0.002, y1, per=3, shift=k, slits=(4, 10, 16) if k > 0 else ())
	# the copper band round the parapet's top course, then merlons
	cap_in = SV._inset(out, 0.012)
	SV.slab_xz(SV._inset(out, 0.019), band_y, band_y + 0.075, SV.stone_m(), c=0.008)
	for i in range(1, len(cap_in) - 1):
		a, b = Vector(cap_in[i]), Vector(cap_in[i + 1])
		mid = (a + b) / 2
		before = set(bpy.data.objects)
		o = K.blk((mid.x, band_y + 0.037, mid.y), ((b - a).length + 0.004, 0.06, 0.012), SV.copper_m(), bevel=0.002,
			ry=math.degrees(math.atan2(-(b - a).y, (b - a).x)))
		SV._tag(SV._new_since(before), "copper")
	m_top = band_y + 0.077
	for (i0, i1) in ((1, 4), (7, 10), (13, 16)):   # three merlons round the front, a fourth on the back corner
		pts = [out[i] for i in range(i0, i1 + 1)] + [inn[i] for i in range(i1, i0 - 1, -1)]
		SV.slab_xz(pts, m_top, 3.0 - E, SV.stone_m(), c=0.02)
	SV.slab_xz([out[0], out[1], inn[1], inn[0]], m_top, 3.0 - E, SV.stone_m(), c=0.02)
	SV.slab_xz([out[-1], out[0], inn[0], inn[-1]], m_top, 3.0 - E, SV.stone_m(), c=0.02)


PIECES = {"corbel": corbel, "cornice": cornice, "cornice_corner": cornice_corner, "buttress": buttress,
	"bartizan": bartizan}


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
		K.rng.seed(sum(map(ord, name + "twin_gate")))
		kit.reset()
		PIECES[name]()
		ps = [o.matrix_world @ v.co for o in meshes() for v in o.data.vertices]
		print("SIZE %s x %.2f y %.2f z %.2f" % (name, max(p.x for p in ps) - min(p.x for p in ps),
			max(p.z for p in ps) - min(p.z for p in ps), max(p.y for p in ps) - min(p.y for p in ps)))
		K.fit_check(name)
		if grey:
			SV.make_grey()
		else:
			SV.paint()
		file = f"{name}__cut_stone.glb"
		png = str((K.JOUR if install else out_dir) / file.replace(".glb", ".png"))
		kit.save(str(out_dir / file), png, recenter=False, tex_size=512)
		print("PIECE_OK", name)
