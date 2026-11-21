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
	"buttress": (0.8, 2.85, 1.24), "bartizan": (3.34, 3.0, 3.34),
	"battlement_narrow": (1.0, 0.9, 0.4)}
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
# (owner, Nov 21 page review: "bigger, walk-in") A round turret about 2.7 m across, its middle on the tower's corner,
# so its back quarter is the tower's own corner and you walk straight in from the deck. Built in the tower corner's
# frame: the corner at (0, 0), the tower at -x, -z, its walls on the lines x = 0 and z = 0 (0.3 thick), the deck's
# floor reaching those lines, top level with the turret floor. Below the floor the turret's stones run back into the
# walls' middles (x = 0 / z = 0), so it grows out of the walls; above it a parapet runs round the outside and, along
# both deck edges, on to where the deck's next battlements start (2 m from the corner). The piece is centred in its
# box: the corner sits at (+SH, +SH).
TR = 1.344                  # the turret's outside radius
TI = TR - 0.28              # the parapet's inside radius
BAND = 0.194                # the parapet along the deck edges: as deep as a battlement (both sides of the line)
REACH = 1.984               # ...and as far along them (the next battlement starts at 2 m)
SH = (REACH - TR) / 2       # the corner's offset from the piece's middle
YF = 1.75                   # the turret floor's top (level with the deck)


def arc(r, a0, a1, n):
	return [(r * math.cos(math.radians(a0 + (a1 - a0) * i / n)), r * math.sin(math.radians(a0 + (a1 - a0) * i / n)))
		for i in range(n + 1)]


def moved(pts):
	return [(x + SH, z + SH) for (x, z) in pts]


def open_stones(outer, inner, y0, y1, groups, mat=None):
	"""Stones between two open outlines with the same points (no closing stone): `groups` = lists of segment
	indices, one stone each."""
	g = 0.0025
	for grp in groups:
		ids = list(grp) + [grp[-1] + 1]
		pts = [outer[i] for i in ids] + [inner[i] for i in reversed(ids)]
		for (i0, i1, j0, j1) in ((0, 1, -1, -2), (len(ids) - 1, len(ids) - 2, len(ids), len(ids) + 1)):
			d = Vector(pts[i1]) - Vector(pts[i0])
			d2 = Vector(pts[j1]) - Vector(pts[j0])
			pts[i0] = tuple(Vector(pts[i0]) + d.normalized() * g)
			pts[j0] = tuple(Vector(pts[j0]) + d2.normalized() * g)
		SV.slab_xz(moved(pts), y0, y1, mat or (kit.tex_mat("greystone", "dark") if K.rng.random() < 0.12 else SV.stone_m()), c=0.018)


def runs(n, per, shift=0):
	"""Segment indices 0..n-1 split into runs of about `per` (the first one `shift` shorter)."""
	out, cur = [], []
	first = per - shift if 0 < shift < per else per
	for i in range(n):
		cur.append(i)
		if len(cur) == (first if not out else per):
			out.append(cur)
			cur = []
	if cur:
		out.append(cur)
	return out


def bartizan():
	n = 24
	# the corbelled body under the floor: three-quarter rings stepping out course by course; each ring's two ends
	# lie in the walls' middle planes (x = 0, z = 0), so it reads as grown out of the corner; a dark heart inside
	courses = [(0.42, 0.004, 0.3), (0.64, 0.3, 0.58), (0.85, 0.58, 0.86), (1.04, 0.86, 1.14), (1.2, 1.14, 1.42), (TR, 1.42, YF - 0.25)]
	for i, (r, y0, y1) in enumerate(courses):
		ri = max(r - 0.24, r * 0.45)
		k = max(6, int(round(n * r / TR)))
		out, inn = arc(r, -90, 180, k), arc(ri, -90, 180, k)
		open_stones(out, inn, y0 + 0.002, y1 - 0.002, runs(k, 2 if r < 0.9 else 3, i % 2))
		heart = arc(ri - 0.004, -90, 180, k) + [(0.0, 0.0)]
		SV.slab_xz(moved(heart), y0 + 0.01, y1 - 0.01, SV.mortar_m(), c=0.005, role="mortar")
	# the rim course under the parapet, the flagstone floor inside it (level with the deck, 1 cm off the deck's edge)
	out, inn = arc(TR, -90, 180, n), arc(TR - 0.24, -90, 180, n)
	open_stones(out, inn, YF - 0.25 + 0.002, YF - 0.004, runs(n, 3, 1))
	fr = TR - 0.24 - 0.004
	flo = [(0.005, -math.sqrt(fr * fr - 0.005 ** 2))] + arc(fr, -89.7, 179.7, n)[1:-1] + [(-math.sqrt(fr * fr - 0.005 ** 2), 0.005), (0.005, 0.005)]
	SV.slab_xz(moved(flo), YF - 0.25 + 0.004, YF - 0.004, kit.tex_mat("greystone", "dark"), c=0.012)
	# the parapet: along one deck edge, round the outside, back along the other edge
	def rim(off, reach=REACH):
		"""The parapet's outside line pulled in by `off`: edge run, round, edge run."""
		r, bd = TR - off, BAND - off
		a0 = math.degrees(math.atan2(-math.sqrt(r * r - bd * bd), bd))
		return [(bd, -reach)] + arc(r, a0, 90 - a0, n) + [(-reach, bd)]
	outer = rim(0.0)
	ai0 = math.degrees(math.atan2(-math.sqrt(TI * TI - BAND * BAND), -BAND))
	inner = [(-BAND, -REACH)] + arc(TI, ai0, 90 - ai0, n) + [(-REACH, -BAND)]
	segs = len(outer) - 1                            # 0: the first edge's run, 1..n the round, n+1 the other edge
	band_y = YF + 0.62
	for k, (y0, y1) in enumerate([(YF, YF + 0.32), (YF + 0.32, band_y - 0.002)]):
		grp = [[0]] + [[i + 1 for i in g] for g in runs(n, 3, k + 1)] + [[segs - 1]]
		open_stones(outer, inner, y0 + 0.002, y1, grp)
	# a cap course set back 1.9 cm with the copper band lying in front of it (as on the battlements), then merlons
	open_stones(rim(0.019), inner, band_y, band_y + 0.075, runs(segs, 4, 2))
	ring = rim(0.012, REACH - 0.006)
	for i in range(len(ring) - 1):
		a, b = Vector(ring[i]), Vector(ring[i + 1])
		mid = (a + b) / 2 + Vector((SH, SH))
		before = set(bpy.data.objects)
		K.blk((mid.x, band_y + 0.037, mid.y), ((b - a).length + 0.004, 0.06, 0.012), SV.copper_m(), bevel=0.002,
			ry=math.degrees(math.atan2(-(b - a).y, (b - a).x)))
		SV._tag(SV._new_since(before), "copper")
	m_top = band_y + 0.077
	for grp in ([0], [2, 3], [7, 8], [12, 13], [17, 18], [22, 23], [segs - 1]):   # (one on each edge run, five round)
		open_stones(outer, inner, m_top, 3.0 - E, [grp])


def battlement_narrow():
	"""A 1 m battlement (owner, Nov 21: closes the two 1 m ends of each barracks wing's roof): the same courses,
	copper band and sill stones as the 2 m one, one merlon in its middle."""
	SV.battlement(w=1.0, merlons=(0.0,), rivets=(-0.3, 0.0, 0.3))


PIECES = {"corbel": corbel, "cornice": cornice, "cornice_corner": cornice_corner, "buttress": buttress,
	"bartizan": bartizan, "battlement_narrow": battlement_narrow}


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
