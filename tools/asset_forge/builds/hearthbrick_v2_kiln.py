# The Old Kiln (owner, Nov 21: ruin 5 of Zone 1, F479): the kiln-master's brick kiln, its crown and its wreckage.
# Every brick comes from the real Hearthbrick parts (builds/hearthbrick_v2.py walls, hearthbrick_v2_round.py
# pillars, hearthbrick_v2_roofs.py tile slopes), placed on the watchtower's 12-sided ring.
#   kiln_crown           (owner, Nov 21: "roofs all round, still a hole in the middle, fences on top") the kiln's
#                        top: twelve thin tile slopes (rafters, underlay, curved tiles, a limestone eave) rising from
#                        the walls toward the middle, hollow hips capped with round tiles, dark timber wall plates on
#                        the wall tops, and a limestone lip round a six-sided hole (the smoke hole, right over the
#                        gallery's open middle). The lip's top is 1.0 m up: railings stand on it. Origin = the
#                        ring's middle at the walls' top (it reaches 9 cm below that outside the walls, at the eave).
#   kiln_crown_broken    the same with its right side (edges 1-5) fallen in: those slopes, hips, plates and lip
#                        stones gone, tiles knocked off the rest
#   kiln_wall_fallen     a curved piece of the kiln's upper wall that fell off: three walls of the ring and the two
#                        pillars between, lying on their outside face, bricks knocked out
#   brick_stack_toppled  the kiln's last load of fired bricks: a criss-cross stack, its lower half still standing,
#                        the upper half toppled over to one side and spilled across the floor (a few burnt dark)
# Ruins place the wall chunk and the broken crown as building pieces (cleared when the kiln is rebuilt) and the brick stack as rubble you
# hit to clear (src/world/ruin_tower.gd). Saved in journey/ until the owner's OK; install=1 puts them in the game.
#   blender --background --factory-startup --python builds/hearthbrick_v2_kiln.py -- [grey] [out=<folder>] [install=1] [piece ...]
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
import hearthbrick_v2_round as HBR  # noqa: E402
import hearthbrick_v2_ruin as HR  # noqa: E402

E = HB.E
EDGE, CORNER = 3.7320508, 3.8637033   # the 12-sided ring (src/build/blueprint_library.gd)
K.SIZE.update({"kiln_wall_fallen": (6.0, 1.7, 3.4), "brick_stack_toppled": (2.6, 1.3, 2.6)})
import hearthbrick_v2_roofs as HRF  # noqa: E402
import bmesh  # noqa: E402


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


def ring_dir(steps):
	a = steps * math.pi / 6.0
	return Vector((math.sin(a), 0.0, math.cos(a)))


def settle():
	"""Nothing below the floor; centred on its spot like every piece."""
	ps = [o.matrix_world @ v.co for o in meshes() for v in o.data.vertices]
	zmin = min(p.z for p in ps)
	cx = (min(p.x for p in ps) + max(p.x for p in ps)) / 2
	cy = (min(p.y for p in ps) + max(p.y for p in ps)) / 2
	bake(list(bpy.data.objects), Matrix.Translation((-cx, -cy, E + 0.002 - zmin)))


def knocked(fn, missing, keep=None):
	"""Build one Hearthbrick wall part at the origin, knock some bricks out (a dark plate behind each hole, like the
	ruin walls), drop the bricks `keep(cx, cy)` says are gone (jagged broken end). Returns its objects."""
	before = set(bpy.data.objects)
	fn()
	objs = since(before)
	holes, kept = [], []
	for o in objs:
		if o.type != "MESH" or o.get("role") == "mortar":
			continue
		x0, x1, y0, y1 = HR.box_of(o)
		cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
		if keep is not None and not keep(cx, cy):
			bpy.data.objects.remove(o)
			continue
		if o.get("role") == "brick" and 0.25 < cy and K.rng.random() < missing:
			holes.append((x0, x1, y0, y1))
			bpy.data.objects.remove(o)
			continue
		kept.append(o)
	if keep is not None:   # the mortar sheet follows what is left (never bare above broken bricks)
		xs = [HR.box_of(o) for o in kept]
		HR.sheet_after(kept, min(b[0] for b in xs) + 0.01, max(b[1] for b in xs) - 0.01)
	HR.hole_backs(holes)
	return since(before)


# ---------------- the crown ----------------
R_OUT, R_IN = 4.1, 2.1          # the slopes: eave 0.37 m past the walls' outside, top at the lip
LIP_OUT, HOLE = 2.17, 1.6       # the lip: from the slopes' top in to the six-sided hole (its flat sides 1.6 m out)
T15 = math.tan(math.radians(15))
WALL_IN, WALL_OUT = EDGE - 0.15, EDGE + 0.15


def prism(pts, y0, y1, m, role):
	"""An upright block with outline pts [(x, z)...] (Godot, seen from above) from y0 to y1."""
	n = len(pts)
	vs = [(x, y0, z) for x, z in pts] + [(x, y1, z) for x, z in pts]
	f = [tuple(range(n))[::-1], tuple(range(n, 2 * n))] + [(i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n)]
	o = K.mesh(vs, f, m)
	bm = bmesh.new()
	bm.from_mesh(o.data)
	bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
	bm.to_mesh(o.data)
	bm.free()
	HB.tag([o], role)
	return o


def turn_objs(objs, steps):
	bake(objs, Matrix.Rotation(math.radians(steps * 30.0), 4, "Z"))   # (Godot yaw = Blender turn about Z)


def crown_slope(j):
	"""Edge j's slope, built for edge 0 (low side out at +z) and turned round to its edge."""
	before = set(bpy.data.objects)
	sl = K.Slope("z", R_OUT, R_IN, 1.0, HRF.TOP_V, vlo=-1.2, vhi=1.2)
	sl.y0 -= sl.k * (R_OUT - WALL_OUT) + sl.y0     # the underside meets the walls' outer top edge (y 0 at r 3.88)
	g = 0.006
	HRF.slope_panel(sl, extra=[(-T15, 1.0, -g), (-T15, -1.0, -g)], rafters=(-0.55, 0.0, 0.55))
	objs = since(before)
	turn_objs(objs, j)
	return sl, objs


def under(sl, r):
	"""The slopes' underside height r m out (along an edge's middle line, or across a hip at that apothem)."""
	return sl.y0 + sl.k * (R_OUT - r)


def crown(skip=(), knock=0.0):
	sl = None
	for j in range(12):
		if j in skip:
			continue
		sl, objs = crown_slope(j)
		for o in objs:
			if o.get("role") == "tile" and knock and K.rng.random() < knock:
				bpy.data.objects.remove(o)
	cs = math.cos(sl.ang)
	tile_top = HRF.N_TOP / cs
	# the hips: round tiles in a row from the eave up to the lip, on each line where two slopes meet
	for j in range(12):
		if j in skip or (j + 1) % 12 in skip:
			continue
		a = math.radians((j + 0.5) * 30)
		d = Vector((math.sin(a), 0, math.cos(a)))
		s0, s1 = (R_OUT - 0.02) / math.cos(math.radians(15)), (LIP_OUT - 0.02) / math.cos(math.radians(15))
		n = 7
		for i in range(n):
			sa = s0 + (s1 - s0) * i / n
			sb = s0 + (s1 - s0) * (i + 1.12) / n if i < n - 1 else s1
			pa, pb = d * sa, d * sb
			ya = under(sl, sa * math.cos(math.radians(15))) + tile_top - 0.035 + 0.012 * i / n
			yb = under(sl, sb * math.cos(math.radians(15))) + tile_top - 0.035
			side = Vector((math.cos(a), 0, -math.sin(a)))
			before = set(bpy.data.objects)
			K.half_tube((pa.x, ya, pa.z), (pb.x, yb, pb.z), 0.115, 0.1, side, HB.m_brick())
			HB.tag(since(before), "tile")
	# dark timber wall plates on the walls' tops (the slopes rest on them), mitred at the corners
	for j in range(12):
		if j in skip and j not in (1, 5):
			continue
		n_ = ring_dir(j)
		t = ring_dir(j + 3)
		top = under(sl, WALL_IN) - 0.006
		pts = []
		for r, sgn in ((WALL_IN, -1), (WALL_IN, 1), (WALL_OUT, 1), (WALL_OUT, -1)):
			p = n_ * r + t * (sgn * (r * T15 - 0.003))
			pts.append((p.x, p.z))
		prism(pts, 0.002, top, kit.tex_mat("wood", "dark"), "timber")
	# the limestone lip round the six-sided hole: a stone per edge, 4 mm joints between them, top at 1.0
	lip_bot = under(sl, LIP_OUT) - 0.05
	for j in range(12):
		if j in skip:
			continue
		a0, a1 = (j - 0.5) * 30 + 0.08, (j + 0.5) * 30 - 0.08
		pts = []
		for ang in (a0, a1):
			r = LIP_OUT / math.cos(math.radians(15))
			pts.append((math.sin(math.radians(ang)) * r, math.cos(math.radians(ang)) * r))
		inner = [a1] + ([j * 30] if j % 2 else []) + [a0]
		for ang in inner:
			near_even = round(ang / 60) * 60
			r = HOLE / math.cos(math.radians(ang - near_even))
			pts.append((math.sin(math.radians(ang)) * r, math.cos(math.radians(ang)) * r))
		o = prism(pts, lip_bot, 1.0, HB.m_lime(), "lime")
		b = o.modifiers.new("chisel", "BEVEL")
		b.width, b.segments, b.limit_method, b.angle_limit = 0.012, 1, "ANGLE", math.radians(35)
	print("CROWN tiles top at the lip %.3f, lip bottom %.3f, eave underside %.3f" % (under(sl, R_IN) + tile_top, lip_bot, under(sl, R_OUT)))


def kiln_crown():
	crown()


def kiln_crown_broken():
	crown(skip=(1, 2, 3, 4, 5), knock=0.12)


# ---------------- the fallen piece of wall ----------------
def kiln_wall_fallen():
	"""Walls on ring edges 11, 0, 1 and the two pillars between them, lying on their outside face (edge 0 down);
	bricks knocked out here and there, the wall on edge 1 broken off jagged at its top."""
	for j in (1, 11, 0):   # (the broken one first: re-cutting its mortar sheet clears every sheet built before it)
		c = ring_dir(j) * EDGE
		keep = (lambda cx, cy: cy < 1.2 + cx * 0.5 + K.rng.uniform(-0.12, 0.12)) if j == 1 else None
		objs = knocked(lambda: HB.wall_body(diamond=(j == 0)), 0.07, keep=keep)
		bake(objs, at(c.x, 0.0, c.z, j * 30.0))
	for j in (11, 0):
		p = ring_dir(j + 0.5) * (CORNER - 0.05)
		before = set(bpy.data.objects)
		HBR.pillar()
		objs = since(before)
		bake(objs, at(p.x, 0.0, p.z, (j + 0.5) * 30.0))
	bake(list(bpy.data.objects), Matrix.Rotation(math.radians(90), 4, "X"))   # lying on its outside face
	settle()


# ---------------- the toppled brick stack ----------------
BR = Vector((0.3, 0.1, 0.14))   # one fired brick (long x, tall y, deep z), like the walls' bricks


def brick(x, y, z, yaw, rx=0.0, rz=0.0, dark=False):
	before = set(bpy.data.objects)
	o = K.blk((x, y, z), tuple(BR * K.rng.uniform(0.97, 1.03)), HB.m_brick(), bevel=0, ry=yaw, rx=rx, rz=rz)
	SV.chisel(o, cut=0.012, dent=0.012, axes=(0, 1, 2))
	HB.tag(HB.since(before), "brick")
	o["dark"] = dark


def brick_stack_toppled():
	"""A kiln-loader's criss-cross stack (pairs of bricks laid across the course below, small gaps for the fire to
	pass), 7 courses still standing (about 0.8 m); the top courses toppled toward +x and lie spilled on the floor,
	the ones that fell first furthest out."""
	gap = 0.04
	n_row = 4                       # bricks across one course (each course 2 bricks deep, laid crosswise)
	span = n_row * (BR.z + gap) - gap
	for c in range(7):
		y = E + 0.004 + c * (BR.y + 0.006) + BR.y / 2
		across = c % 2 == 1
		for i in range(n_row):
			off = -span / 2 + BR.z / 2 + i * (BR.z + gap)
			for half in (-1, 1):
				if c >= 5 and half == 1 and i >= 2:
					continue            # the top two courses broke away at the toppled corner
				u = half * (BR.x / 2 + 0.01)
				x, z = (off, u) if across else (u, off)
				brick(x + K.J(0.006), y, z + K.J(0.006), (0 if across else 90) + 90 + K.J(2.0),
					dark=K.rng.random() < 0.1)
	# the toppled courses: bricks fanned out toward +x, lying flat or on edge, a few still in a leaning clump
	top = E + 0.004 + 7 * (BR.y + 0.006)
	for i in range(5):                          # a clump that slid off together, leaning on the stack's side
		brick(0.48 + i * 0.012, E + 0.06 + i * 0.105, -0.25 + K.J(0.03), 90 + K.J(4), rz=-18 + K.J(4))
	for i in range(34):
		r = 0.55 + 1.0 * math.sqrt(K.rng.random())
		a = math.radians(K.rng.uniform(-55, 55))
		x, z = math.cos(a) * r, math.sin(a) * r
		if abs(z) < 0.45 and x < 0.75:
			x += 0.3
		on_edge = K.rng.random() < 0.25
		brick(x, E + 0.004 + (BR.z / 2 if on_edge else BR.y / 2) + 0.004 * (i % 3), z, K.rng.uniform(0, 180),
			rx=90 if on_edge else K.J(3), dark=K.rng.random() < 0.15)
	settle()


PIECES = {"kiln_crown": kiln_crown, "kiln_crown_broken": kiln_crown_broken, "kiln_wall_fallen": kiln_wall_fallen,
	"brick_stack_toppled": brick_stack_toppled}


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
		K.rng.seed(sum(map(ord, name + "old_kiln")))
		kit.reset()
		PIECES[name]()
		ps = [o.matrix_world @ v.co for o in meshes() for v in o.data.vertices]
		print("SIZE %s x %.2f y %.2f z %.2f" % (name, max(p.x for p in ps) - min(p.x for p in ps),
			max(p.z for p in ps) - min(p.z for p in ps), max(p.y for p in ps) - min(p.y for p in ps)))
		HB.split_big_faces()
		K.fit_check(name)
		if grey:
			SV.make_grey()
		else:
			HBW.paint()
		file = f"{name}__clay_brick.glb"
		png = str((K.JOUR if install else out_dir) / file.replace(".glb", ".png"))
		kit.save(str(out_dir / file), png, recenter=False, tex_size=512)
		print("PIECE_OK", name)
