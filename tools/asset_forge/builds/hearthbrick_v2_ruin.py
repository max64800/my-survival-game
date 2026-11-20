# Hearthbrick ruin pieces (owner, Nov 20, F479: the Brewhall, the third ruin): the clay-brick versions of the
# Stonehold ruin pieces (builds/stonehold_v2.py ruin_*), plus the Brewhall's own wreckage.
#   ruin_wall_worn       the approved Hearthbrick wall with about 1 brick in 10 fallen out (a dark hole behind) and
#                        the top (rune band, upright bricks, a course or two) broken off at one end
#   ruin_wall_collapsed  full height at the right end, broken down in a jagged slope to knee height at the left
#   ruin_rubble          a heap of fallen bricks (whole and halves) and a few limestone chunks
#   chimney_fallen       the Brewhall's tall chimney (a 2 x 1.3 m brick stack) toppled: two 2 m sections lying end
#                        to end along +z, a little apart and turned, the far end broken off jagged, loose bricks
#   barrel_smashed       a brewing barrel burst open: half its staves still standing, broken off jagged, the rest
#                        splayed on the floor, a hoop lying flat, the bottom still in place (origin bottom centre)
# Ruins place all of them as building pieces (worn and collapsed walls, the fallen chimney) or as rubble you hit to
# clear (rubble, the smashed barrel): src/world/ruin_tower.gd. install=1 puts them in assets/models/build.
#   blender --background --factory-startup --python builds/hearthbrick_v2_ruin.py -- [grey] [out=<folder>] [install=1] [piece ...]
# Every piece is made from the real Hearthbrick parts (wall_body / wall_narrow), then broken: nothing new to approve
# in the bricks themselves. The inner mortar sheet is cut again to follow what is left (never standing up bare).
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kit  # noqa: E402
import kit_zone1 as K  # noqa: E402
import stonehold_v2 as SV  # noqa: E402
import hearthbrick_v2 as HB  # noqa: E402
import hearthbrick_v2_walls as HBW  # noqa: E402

E = HB.E
W, H, D = 2.0, 2.0, 0.3
SHEET = D * 1.13 * 0.62     # the inner mortar sheet's thickness (SV.backing)


def meshes():
	return [o for o in bpy.data.objects if o.type == "MESH"]


def box_of(o):
	"""Godot-space bounds of an object: (x0, x1, y0, y1)."""
	ps = [o.matrix_world @ Vector(c) for c in o.bound_box]
	xs, ys = [p.x for p in ps], [p.z for p in ps]
	return min(xs), max(xs), min(ys), max(ys)


def sheet_after(kept, x0, x1, d=D, step=0.02):
	"""The inner mortar sheet again, its top following the highest brick or stone left at each spot (8 mm under it),
	so no bare sheet stands above the broken bricks and no joint left in the wall is see-through."""
	for o in meshes():
		if o.get("role") == "mortar":
			bpy.data.objects.remove(o)
	bx = [box_of(o) for o in kept]
	pts = [(x0, E + 0.004), (x1, E + 0.004)]
	n = int((x1 - x0) / step)
	for i in range(n, -1, -1):
		x = x0 + (x1 - x0) * i / n
		tops = [b[3] for b in bx if b[0] - 0.004 <= x <= b[1] + 0.004]
		pts.append((x, max(E + 0.06, (max(tops) if tops else E + 0.06) - 0.008)))
	before = set(bpy.data.objects)
	K.slab_poly(K.Frame(), HB.simplify(pts), 0.0, d * 1.13 * 0.62, HB.m_mortar())
	HB.tag(HB.since(before), "mortar")


def hole_backs(holes):
	"""Behind each brick that fell out: a dark burnt-brick plate 2 mm in front of the mortar sheet on both faces,
	so the hole reads as a hole (deep shadow), not as a pale patch."""
	for (a, b, ya, yb) in holes:
		for side in (-1, 1):
			before = set(bpy.data.objects)
			K.blk(((a + b) / 2, (ya + yb) / 2, side * (SHEET / 2 + 0.007)), (b - a - 0.01, yb - ya - 0.01, 0.01),
				SV.mortar_m(), bevel=0)
			for o in HB.since(before):
				o["role"] = "hole"


# ---------------- ruin walls ----------------
def ruin_wall_worn():
	HB.wall_body(diamond=True)
	x_break = -W / 2 + K.rng.uniform(0.8, 1.15)
	holes, kept = [], []
	for o in meshes():
		if o.get("role") == "mortar":
			continue
		x0, x1, y0, y1 = box_of(o)
		cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
		top_gone = cy > H - 0.2 - (x_break - cx) * 0.55 + K.rng.uniform(-0.05, 0.05) and cx < x_break   # the top broken off at the left end
		if top_gone:
			bpy.data.objects.remove(o)
			continue
		if o.get("role") == "brick" and not o.get("dark") and 0.3 < cy < H - 0.45 and K.rng.random() < 0.12:
			holes.append((x0, x1, y0, y1))
			bpy.data.objects.remove(o)
			continue
		kept.append(o)
	sheet_after(kept, -W / 2 + E + 0.01, W / 2 - E - 0.01)
	hole_backs(holes)


def ruin_wall_collapsed():
	HB.wall_body(diamond=False)
	low = 0.5
	kept = []
	for o in meshes():
		if o.get("role") == "mortar":
			continue
		x0, x1, y0, y1 = box_of(o)
		cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
		lo = -W / 2 + max(0.0, cy - low) / (H - low) * W * 0.98 + K.rng.uniform(-0.14, 0.14)
		if cy > low and cx < lo:
			bpy.data.objects.remove(o)
			continue
		kept.append(o)
	holes = []
	for o in list(kept):   # a few more fallen out low down
		x0, x1, y0, y1 = box_of(o)
		if o.get("role") == "brick" and 0.3 < (y0 + y1) / 2 < 1.0 and K.rng.random() < 0.05:
			holes.append((x0, x1, y0, y1))
			kept.remove(o)
			bpy.data.objects.remove(o)
	sheet_after(kept, -W / 2 + E + 0.01, W / 2 - E - 0.01)
	hole_backs(holes)


# ---------------- rubble ----------------
def ruin_rubble(w=1.6, h=0.7, dd=1.6, n=26):
	"""A heap of fallen bricks: whole bricks and halves tumbled into a low pile (big limestone chunks underneath),
	each resting on what is under it."""
	placed = []
	for i in range(n):
		lime = i < 4
		if lime:
			sz = Vector((K.rng.uniform(0.3, 0.42), K.rng.uniform(0.16, 0.22), K.rng.uniform(0.22, 0.3)))
		else:
			ln = K.rng.choice((0.3, 0.33, 0.17, 0.19))   # whole bricks and halves
			sz = Vector((ln, 0.105, 0.14)) * K.rng.uniform(0.95, 1.05)
		r = (w / 2 - 0.25) * math.sqrt(K.rng.random()) * (1.0 - 0.35 * i / n)
		a = K.rng.uniform(0, math.tau)
		x, z = r * math.cos(a), r * math.sin(a)
		base = 0.0
		for (px, pz, top, ps) in placed:
			if abs(px - x) < (ps.x + sz.x) * 0.4 and abs(pz - z) < (ps.z + sz.z) * 0.4:
				base = max(base, top - 0.025)
		y = E + 0.06 + base + sz.y / 2
		if y + sz.y / 2 > h - E - 0.03:
			continue
		before = set(bpy.data.objects)
		o = K.blk((x, y, z), tuple(sz), HB.m_lime() if lime else HB.m_brick(), bevel=0,
			rz=K.J(10.0), rx=K.J(8.0), ry=K.rng.uniform(0, 180))
		SV.chisel(o, cut=0.03 if lime else 0.012, dent=0.02 if lime else 0.012, axes=(0, 1, 2))
		HB.tag(HB.since(before), "lime" if lime else "brick")
		o["dark"] = (not lime) and K.rng.random() < 0.12
		placed.append((x, z, y + sz.y / 2, sz))


# ---------------- the fallen chimney ----------------
CH_W, CH_D = 2.0, 1.3      # the chimney stack from outside: 2 m wide (x), 1.3 m deep (z)


def bake(objs, m):
	"""Move these objects' points by matrix m (Blender space), keeping each object's own placement baked in."""
	for o in objs:
		o.data.transform(o.matrix_world)
		o.matrix_world = Matrix.Identity(4)
		o.data.transform(m)


def chimney_section():
	"""One 2 m tall section of the chimney, standing, as the blueprint builds it: two walls (2 m) on its long sides
	(z = +-0.5) and two narrow walls (1 m) across its ends (x = +-0.83). Returns its parts."""
	parts = []
	for sz in (-0.5, 0.5):
		before = set(bpy.data.objects)
		HB.wall_body(diamond=False)
		o = HB.since(before)
		bake(o, Matrix.Translation((0, -sz, 0)))
		parts += o
	for sx in (-0.83, 0.83):
		before = set(bpy.data.objects)
		HBW.wall_narrow()
		o = HB.since(before)
		bake(o, Matrix.Translation((sx, 0, 0)) @ Matrix.Rotation(math.radians(90), 4, "Z"))
		parts += o
	return parts


def chimney_fallen():
	"""Two sections lying on their long face (the top pointing +z): the first from z 0 to 2, the second a hand's
	width further on, turned 6 degrees and slid 12 cm sideways, its far end broken off; loose bricks past it."""
	lie = Matrix.Rotation(math.radians(90), 4, "X")   # Blender up (Godot y) -> Godot +z
	lift = CH_D / 2 + E + 0.004
	for k in range(2):
		parts = chimney_section()
		bake(parts, lie)                                 # now lying from Godot z 0 to 2, x +-1, y -0.65..0.65
		if k == 1:
			for o in list(parts):                        # the far end broke off jagged
				ps = [o.matrix_world @ Vector(c) for c in o.bound_box]
				gz = max(-p.y for p in ps)
				cut = 2.0 - 0.25 - 0.35 * abs(math.sin(sum(p.x for p in ps) * 3.1 + sum(p.z for p in ps) * 2.3))
				if gz > cut and o.get("role") != "mortar":
					bpy.data.objects.remove(o)
					parts.remove(o)
			for o in list(parts):                        # the mortar sheets: trimmed back with the bricks
				if o.get("role") == "mortar":
					ps = [o.matrix_world @ Vector(c) for c in o.bound_box]
					if max(-p.y for p in ps) > 1.4:
						bmesh_trim(o, 1.42)
		m = Matrix.Translation((0, 0, lift))
		if k == 1:
			m = Matrix.Translation((0.12, -2.08, lift)) @ Matrix.Rotation(math.radians(6), 4, "Z")
		bake(parts, m)
	for i in range(7):                                   # loose bricks past the broken end
		x, z = K.rng.uniform(-0.9, 0.9), 4.15 + K.rng.uniform(0.0, 0.5)
		before = set(bpy.data.objects)
		o = K.blk((x, E + 0.06 + 0.01 * i, z), (0.3, 0.1, 0.14), HB.m_brick(), bevel=0, ry=K.rng.uniform(0, 180), rz=K.J(5), rx=K.J(5))
		SV.chisel(o, cut=0.012, dent=0.012, axes=(0, 1, 2))
		HB.tag(HB.since(before), "brick")
	# (nothing in the model reaches below the floor)
	zmin = min((o.matrix_world @ v.co).z for o in meshes() for v in o.data.vertices)
	if zmin < E:
		bake(meshes(), Matrix.Translation((0, 0, E - zmin)))
	# centred on its spot like every piece (the ruin plan places its middle; printed for make_brewhall_ruin.py)
	ps = [o.matrix_world @ v.co for o in meshes() for v in o.data.vertices]
	cx = (min(p.x for p in ps) + max(p.x for p in ps)) / 2
	cy = (min(p.y for p in ps) + max(p.y for p in ps)) / 2
	bake(meshes(), Matrix.Translation((-cx, -cy, 0)))
	print("CHIMNEY_CENTRE godot x %.3f z %.3f" % (cx, -cy))


def bmesh_trim(o, gz_max):
	"""Pull the points of a flat mortar sheet that lie past Godot z = gz_max back onto it (a straight cut end)."""
	o.data.transform(o.matrix_world)
	o.matrix_world = Matrix.Identity(4)
	for v in o.data.vertices:
		if -v.co.y > gz_max:
			v.co.y = -gz_max


# ---------------- the smashed barrel ----------------
def barrel_smashed(r=0.33, n=14, t=0.03):
	"""A brewing barrel burst open: staves on one side still standing, snapped off at jagged heights, the rest
	thrown out flat on the floor; a copper hoop lying on the floor, a short piece of hoop still round the
	standing staves, the bottom in place."""
	wood = lambda: kit.tex_mat("wood", K.rng.choice("bc"))   # noqa: E731
	sw = 2 * math.pi * (r - t / 2) / n - 0.008
	k = 0
	for i in range(n):
		a = 2 * math.pi * i / n
		if i < 7:   # standing, snapped off
			fr = K.Frame(ox=math.sin(a) * (r - t / 2), oz=math.cos(a) * (r - t / 2), yaw=math.degrees(a))
			h0, h1 = K.rng.uniform(0.32, 0.8), K.rng.uniform(0.32, 0.8)
			hm = min(h0, h1) - K.rng.uniform(0.02, 0.08)
			pts = [(-sw / 2, E), (sw / 2, E), (sw / 2, h1), (sw * 0.1, hm), (-sw / 2, h0)]
			before = set(bpy.data.objects)
			K.slab_poly(fr, pts, 0.0, t, wood())
			HB.tag(HB.since(before), "timber")
		else:       # thrown out flat
			ln = K.rng.uniform(0.45, 0.85)
			rr = r + 0.12 + ln / 2 + K.rng.uniform(0.0, 0.25)
			yaw = math.degrees(a) + K.rng.uniform(-25, 25)
			before = set(bpy.data.objects)
			K.blk((math.sin(a) * rr, E + 0.016 + 0.011 * k, math.cos(a) * rr), (sw, t * 0.9, ln), wood(), bevel=0.004,
				ry=yaw, rz=K.J(2), rx=K.J(2))
			HB.tag(HB.since(before), "timber")
			k += 1
	before = set(bpy.data.objects)
	kit.cylinder(r - t - 0.014, 0.03, K.G((0, E + 0.016, 0)), kit.tex_mat("wood", "c"), verts=14, bevel=0.003)
	HB.tag(HB.since(before), "timber")
	# a piece of hoop still round the standing staves (just outside them), and one lying on the floor
	segs = 6
	for j in range(segs):
		a0 = (2 * math.pi * 7 / n - 0.15) * j / segs + 0.07
		a1 = (2 * math.pi * 7 / n - 0.15) * (j + 1) / segs + 0.07
		am = (a0 + a1) / 2
		ln = 2 * (r + 0.008) * math.sin((a1 - a0) / 2) + 0.004
		before = set(bpy.data.objects)
		K.blk((math.sin(am) * (r + 0.008), 0.16, math.cos(am) * (r + 0.008)), (ln, 0.06, 0.012), kit.tex_mat("copper", "b"),
			bevel=0.002, ry=math.degrees(am))
		HB.tag(HB.since(before), "copper")
	before = set(bpy.data.objects)
	kit.ring(r + 0.02, 0.014, K.G((-0.15, E + 0.016, -0.55)), kit.tex_mat("copper", "b"), seg=20)
	HB.tag(HB.since(before), "copper")


PIECES = {"ruin_wall_worn": ruin_wall_worn, "ruin_wall_collapsed": ruin_wall_collapsed, "ruin_rubble": ruin_rubble,
	"chimney_fallen": chimney_fallen, "barrel_smashed": barrel_smashed}
FAMILY = {"barrel_smashed": "plank_root"}   # (a wooden thing: placed by ruins as hit-to-clear rubble)


if __name__ == "__main__":
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	grey = "grey" in args
	out_dir = next((Path(a[4:]) for a in args if a.startswith("out=")), HB.OUT_DEFAULT)
	names = [a for a in args if a in PIECES] or list(PIECES)
	install = "install=1" in args
	if install:
		out_dir = K.OUT
	out_dir.mkdir(parents=True, exist_ok=True)
	for name in names:
		K.rng.seed(sum(map(ord, name + "hearthbrick_ruin")))
		kit.reset()
		PIECES[name]()
		HB.split_big_faces()
		K.fit_check(name)
		if grey:
			SV.make_grey()
		else:
			HBW.paint()
		file = f"{name}__{FAMILY.get(name, 'clay_brick')}.glb"
		png = str((K.JOUR if install else out_dir) / file.replace(".glb", ".png"))
		kit.save(str(out_dir / file), png, recenter=False, tex_size=512)
		print("PIECE_OK", name)
