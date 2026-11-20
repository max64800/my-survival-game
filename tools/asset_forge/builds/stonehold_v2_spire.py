# The Lantern Spire (owner, Nov 20: ruin 4 of Zone 1, a tall thin round Stonehold beacon tower): its fire bowl, and
# the wreckage of its top half. Every stone comes from the real Stonehold parts (builds/stonehold_v2.py: walls,
# window walls, pillars, floors, railings, battlements), placed on the watchtower's 12-sided ring, then broken.
#   beacon_bowl         the fire bowl on the roof: a square plinth, a chunky stone pedestal, an iron bowl with
#                       riveted copper bands, full of coals and charred logs (the game plays its fire on fire_spot)
#   beacon_bowl_fallen  the same bowl knocked off the top: plinth and pedestal stump standing, the top stones
#                       lying about, the bowl on its side, cold coals spilled out of it
#   spire_top_fallen    the top of the tower lying on its side in two pieces: the third floor's walls (a window
#                       in them), then the open lantern gallery (pillars, railings) and the battlement crown; the
#                       upper half of the ring broke away, so it lies like a giant broken pipe, open on top
#   spire_wall_chunk    a curved piece of three walls (and the two pillars between them) lying on the floor
# Ruins place the wreckage as building pieces, cleared when the Spire is rebuilt (src/build/builder.gd RUIN_DEBRIS).
#   blender --background --factory-startup --python builds/stonehold_v2_spire.py -- [grey] [out=<folder>] [install=1] [piece ...]
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

E = SV.E
EDGE, CORNER, APO = 3.7320508, 3.8637033, 1.7320508   # the 12-sided ring (src/build/blueprint_library.gd)
OUT_DEFAULT = K.GAME / "journey" / "stonehold_v2" / "glb"
K.SIZE.update({"beacon_bowl": (2.0, 1.8, 2.0), "beacon_bowl_fallen": (3.4, 2.0, 3.6),
	"spire_top_fallen": (8.4, 4.4, 6.8), "spire_wall_chunk": (5.8, 1.6, 2.4)})


def meshes():
	return [o for o in bpy.data.objects if o.type == "MESH"]


def since(before):
	return [o for o in bpy.data.objects if o not in before]


def bake(objs, m):
	"""Move these objects' points by matrix m (Blender space), keeping each object's own placement baked in."""
	for o in objs:
		if o.type != "MESH":
			o.matrix_world = m @ o.matrix_world
			continue
		o.data.transform(o.matrix_world)
		o.matrix_world = Matrix.Identity(4)
		o.data.transform(m)


def at(gx, gy, gz, yaw_deg=0.0):
	"""Godot spot + turn about up -> Blender matrix (Godot (x, y, z) = Blender (x, -z, y))."""
	return Matrix.Translation((gx, -gz, gy)) @ Matrix.Rotation(math.radians(yaw_deg), 4, "Z")


def piece(fn, gx, gy, gz, yaw_deg, *a, **kw):
	"""Build one Stonehold part with its own code and put it at its spot. Returns its objects."""
	before = set(bpy.data.objects)
	fn(*a, **kw)
	objs = since(before)
	bake(objs, at(gx, gy, gz, yaw_deg))
	return objs


def ring_dir(steps):
	a = steps * math.pi / 6.0
	return Vector((math.sin(a), 0.0, math.cos(a)))


def godot(p):
	return Vector((p.x, p.z, -p.y))


def centre(o):
	ps = [o.matrix_world @ Vector(c) for c in o.bound_box]
	return godot(sum(ps, Vector()) / 8.0), [godot(p) for p in ps]


def settle():
	"""Nothing below the floor; centred on its spot like every piece."""
	ps = [o.matrix_world @ v.co for o in meshes() for v in o.data.vertices]
	zmin = min(p.z for p in ps)
	cx = (min(p.x for p in ps) + max(p.x for p in ps)) / 2
	cy = (min(p.y for p in ps) + max(p.y for p in ps)) / 2
	bake(list(bpy.data.objects), Matrix.Translation((-cx, -cy, E + 0.002 - zmin)))


# ---------------- the fire bowl ----------------
def _bowl(m_iron, coals_hot):
	"""The iron bowl alone, standing with its foot at the origin (Blender space): 0.46 m tall, 0.9 m across the rim."""
	h = 0.46
	kit.cone(0.42, 0.9, h, (0, 0, h / 2), m_iron, verts=12, bevel=0.012)
	kit.ring(0.9, 0.035, (0, 0, h + 0.005), SV.copper_m(), seg=12)                       # the rolled rim
	kit.ring(0.66, 0.028, (0, 0, h * 0.45), SV.copper_m(), seg=12)                       # a band round its middle
	for k in range(12):                                                                   # rivets on the middle band
		a = 2 * math.pi * (k + 0.5) / 12
		r = 0.66 + 0.022
		kit.rivet((math.cos(a) * r, math.sin(a) * r, h * 0.45), kit.tex_mat("copper", "dark"), r=0.02)
	for k in range(4):                                                                    # four iron straps down its side
		a = 2 * math.pi * k / 4 + math.pi / 4
		r = (0.42 + 0.9) / 2 + 0.012
		o = K.blk((0, 0, 0), (0.08, h * 1.02, 0.02), m_iron, bevel=0.004)
		tilt = math.degrees(math.atan2(0.9 - 0.42, h))
		o.matrix_world = (Matrix.Translation((math.cos(a) * r, math.sin(a) * r, h / 2))
			@ Matrix.Rotation(a - math.pi / 2, 4, "Z") @ Matrix.Rotation(math.radians(-tilt), 4, "X"))
	# the coal bed: a low mound of lumps on the bowl's top, two charred logs crossed on it
	for k in range(22):
		a, d = K.rng.uniform(0, math.tau), 0.78 * math.sqrt(K.rng.random())
		hot = coals_hot and k % 3 == 0
		kit.gem((math.cos(a) * d, math.sin(a) * d, h + 0.03 + 0.06 * (1 - d / 0.8)), (0.09, 0.08, 0.05),
			kit.glow("ember", 1.0) if hot else kit.mat("charcoal", K.rng.uniform(-0.65, -0.4)), seed=k + 31)
	for (a, z) in ((0.4, 0.09), (2.1, 0.15)):
		kit.cylinder(0.07, 1.1, (0, 0, h + z), kit.tex_mat("wood", "dark"), rot=(90, 0, math.degrees(a) + 90), verts=7, bevel=0.01)
	return h


def _plinth_and_pedestal(courses=3, keep=None):
	"""A square plinth (four dark stones, 1.5 m) and a chunky 0.8 m pedestal of stones laid in crossing courses, a
	wide cap stone on top. keep(i, j) -> False drops stone j of course i (the fallen bowl's broken pedestal).
	Returns the cap's top (Godot y)."""
	before = set(bpy.data.objects)
	for sx in (-1, 1):
		for sz in (-1, 1):
			SV.block((sx * 0.375, E + 0.116, sz * 0.375), (0.74, 0.21, 0.74), kit.tex_mat("greystone", "dark"), cut=0.04, tilt=0.0, free="y")
	y = E + 0.22
	SV.blk((0, y + courses * 0.2 / 2, 0), (0.6, courses * 0.2 - 0.02, 0.6), SV.mortar_m(), bevel=0)   # a dark core
	for o in since(before):
		if o.get("role") is None:
			o["role"] = "mortar"
	for i in range(courses):
		cy = y + 0.1 + i * 0.2
		for j, s in enumerate((-1, 1)):
			if keep and not keep(i, j):
				continue
			if i % 2 == 0:
				SV.block((s * 0.2, cy, 0), (0.395, 0.197, 0.8), SV.stone_m(), cut=0.035, tilt=0.0, free="y")
			else:
				SV.block((0, cy, s * 0.2), (0.8, 0.197, 0.395), SV.stone_m(), cut=0.035, tilt=0.0, free="y")
	return y + courses * 0.2


def beacon_bowl():
	top = _plinth_and_pedestal()
	SV.block((0, top + 0.07, 0), (1.0, 0.14, 1.0), SV.stone_m(), cut=0.04, tilt=0.0, free="y")       # the cap stone
	before = set(bpy.data.objects)
	h = _bowl(kit.tex_mat("iron", "dark"), True)
	bake(since(before), Matrix.Translation((0, 0, top + 0.14 + 0.002)))
	kit.fire_spot((0, 0, top + 0.14 + h + 0.12), 1.4)


def beacon_bowl_fallen():
	"""Knocked off the top: the plinth and the lowest course of the pedestal still stand; two of its stones and the
	cap lie beside it; the bowl lies on its side further on, its cold coals spilled out in front of it."""
	top = _plinth_and_pedestal(courses=3, keep=lambda i, j: i == 0 or (i == 1 and j == 0))
	for (x, z, ry, sy, size) in ((1.15, -0.35, 25, 0.11, (0.8, 0.197, 0.395)), (-1.15, 0.2, 70, 0.11, (0.8, 0.197, 0.395)),
			(1.25, 0.85, -18, 0.075, (1.0, 0.14, 1.0))):     # two pedestal stones and the cap stone, lying about
		o = SV.block((0, 0, 0), size, SV.stone_m(), cut=0.035, tilt=0.0, free="xyz")
		o.matrix_world = Matrix.Translation((x, -z, E + sy + 0.004)) @ Matrix.Rotation(math.radians(ry), 4, "Z")
	before = set(bpy.data.objects)
	h = _bowl(kit.tex_mat("iron", "dark"), False)
	bowl = since(before)
	coals = [o for o in bowl if o.type == "MESH" and o.data.materials and o.data.materials[0].name.startswith(("charcoal", "wood"))]
	bowl = [o for o in bowl if o not in coals]
	for o in coals:      # the coals poured out: they lie on the floor in a fan in front of the bowl's mouth
		bpy.data.objects.remove(o)
	# on its side: the rim facing +z (Godot), resting on the floor, then slid out to the front left
	bx, by = -0.15, -1.35     # (Blender: Godot z +1.35, in front of the plinth)
	bake(bowl, Matrix.Translation((bx, by, 0.0)) @ Matrix.Rotation(math.radians(-14), 4, "Z")
		@ Matrix.Rotation(math.radians(102), 4, "X") @ Matrix.Translation((0, 0, -h / 2)))
	zmin = min((o.matrix_world @ v.co).z for o in bowl if o.type == "MESH" for v in o.data.vertices)
	bake(bowl, Matrix.Translation((0, 0, E + 0.004 - zmin)))
	for k in range(26):
		a = math.radians(K.rng.uniform(-50, 50)) - math.radians(14)
		d = K.rng.uniform(0.1, 0.9)
		kit.gem((bx + math.sin(a) * d, by - 0.3 - math.cos(a) * d * 0.9, E + 0.035), (0.09, 0.08, 0.04),
			kit.mat("charcoal", K.rng.uniform(-0.65, -0.4)), seed=k + 71)
	for (dx, dz, yaw) in ((-0.35, -0.75, 20), (0.45, -1.05, 105)):     # the charred logs rolled out with them
		kit.cylinder(0.07, 1.1, (bx + dx, by + dz, E + 0.075), kit.tex_mat("wood", "dark"), rot=(90, 0, yaw), verts=7, bevel=0.01)
	settle()


# ---------------- the fallen top of the tower ----------------
def lie():
	"""Tower up (Godot +y) -> lying along Godot +z, edge 0 (the front, Godot +z) at the bottom."""
	return Matrix.Rotation(math.radians(90), 4, "X")


def hrel(g):
	"""How high a point (Godot, before lying down) ends up above the ring's middle line once it lies down."""
	return -g.z


def broken_wall(j, y, cut, flip, missing=0.06):
	"""Wall on ring edge j at height y, broken along the line where it rises above `cut` once lying (jagged, row by
	row; the stepped dark backing follows, SV.courses). flip: built turned round so its kept end is its right end."""
	yaw = j * 30.0 + (180.0 if flip else 0.0)
	a = math.radians(yaw)
	c = ring_dir(j) * EDGE
	tz = -math.sin(a)                      # its local +x, Godot z part

	def lim(ya, yb):
		# h(x) = -(c.z + tz x) <= cut  ->  x >= (-cut - c.z) / tz  (tz > 0: both broken walls keep their right end)
		x0 = (-cut - c.z) / tz if abs(tz) > 1e-6 else -1.0
		x0 += K.rng.uniform(-0.16, 0.16)
		if x0 > 1.0 - 0.3:
			return None
		return (max(-1.0, x0), 1.0)
	return piece(SV.courses, c.x, y, c.z, yaw, 2.0, 2.0, 0.3, limit=lim, missing=missing)


def keep_below(objs, cut, mortar_slack=0.08):
	"""Drop every stone of these parts that would stand above `cut` once lying (and dark sheets reaching past it)."""
	kept = []
	for o in list(objs):
		if o.type == "MESH":
			c, ps = centre(o)
			top = max(hrel(p) for p in ps)
			gone = top > cut + mortar_slack if o.get("role") == "mortar" else hrel(c) > cut + K.rng.uniform(-0.1, 0.1)
			if gone:
				bpy.data.objects.remove(o)
				continue
		kept.append(o)
	return kept


def spire_top_fallen():
	cut = -0.45
	sec1, sec2 = [], []
	# the third floor's walls (a window in edge 10), the two ends of the arc broken
	for j in (10, 11, 0, 1, 2):
		c = ring_dir(j) * EDGE
		if j == 10:
			sec1 += piece(SV.window_wall, c.x, 0.0, c.z, j * 30.0)
		else:
			sec1 += piece(SV.courses, c.x, 0.0, c.z, j * 30.0, 2.0, 2.0, 0.3, missing=0.05)
	sec1 += broken_wall(9, 0.0, cut, False)
	sec1 += broken_wall(3, 0.0, cut, True)
	for j in (9, 10, 11, 0, 1, 2):
		a = (j + 0.5) * 30.0
		p = ring_dir(j + 0.5) * (CORNER - 0.05)
		sec1 += piece(SV.pillar, p.x, 0.0, p.z, a)
	# the snapped end (where it broke off the stump): stones of the lowest course knocked out
	for o in list(sec1):
		if o.type == "MESH" and o.get("role") == "stone":
			c, _ = centre(o)
			if c.y < 0.2 and K.rng.random() < 0.35:
				bpy.data.objects.remove(o)
				sec1.remove(o)
	# the lantern gallery's floor (only its outer squares and gap triangles, the middle fell out), its pillars and
	# railings, the roof slab and the battlements
	for (y, kind) in ((2.0, "floor"), (4.25, "roof")):
		for k in (5, 0, 1):
			n = ring_dir(2 * k)
			p = n * (APO + 1.0)
			sec2 += piece(SV.floor, p.x, y, p.z, 2 * k * 30.0)
		for k in (5, 0):
			u = ring_dir(2 * k + 1)
			p = u * (2.0 + 2.0 / math.sqrt(3.0))
			sec2 += piece(SV.floor_triangle, p.x, y, p.z, (2 * k + 1) * 30.0)
	for j in (9, 10, 11, 0, 1, 2):
		a = (j + 0.5) * 30.0
		p = ring_dir(j + 0.5) * (CORNER - 0.05)
		sec2 += piece(SV.pillar, p.x, 2.25, p.z, a)
	for j in (10, 11, 0, 1, 2):
		c = ring_dir(j) * EDGE
		sec2 += piece(SV.railing, c.x, 2.25, c.z, j * 30.0)
		sec2 += piece(SV.battlement, c.x, 4.5, c.z, j * 30.0)
	sec2 = keep_below(sec2, cut + 0.2)
	bake(sec2, Matrix.Translation((0, 0, 0.55)))           # (Blender z = Godot y: a hand's width apart)
	bake(sec1 + sec2, lie())
	# the far piece: turned a little and slid sideways as it landed
	bake(sec2, Matrix.Translation((0.3, -2.6, 0)) @ Matrix.Rotation(math.radians(7), 4, "Z") @ Matrix.Translation((0, 2.6, 0))
		@ Matrix.Rotation(math.radians(5), 4, "Y"))
	settle()


def spire_wall_chunk():
	"""Three walls of the ring and the two pillars between them, lying on their outside face (the middle wall flat on
	the floor, the side ones rising 30 degrees), stones knocked out here and there."""
	for j in (11, 0, 1):
		c = ring_dir(j) * EDGE
		piece(SV.courses, c.x, 0.0, c.z, j * 30.0, 2.0, 2.0, 0.3, missing=0.08)
	for j in (11, 0):
		p = ring_dir(j + 0.5) * (CORNER - 0.05)
		piece(SV.pillar, p.x, 0.0, p.z, (j + 0.5) * 30.0)
	bake(list(bpy.data.objects), lie())   # lying on its outside face (edge 0 down)
	settle()


PIECES = {"beacon_bowl": beacon_bowl, "beacon_bowl_fallen": beacon_bowl_fallen, "spire_top_fallen": spire_top_fallen,
	"spire_wall_chunk": spire_wall_chunk}


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
		K.rng.seed(sum(map(ord, name + "spire")))
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
