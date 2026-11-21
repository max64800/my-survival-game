# The Old Kiln (owner, Nov 21: ruin 5 of Zone 1, F479): the wreckage of the kiln-master's brick kiln. Every brick
# comes from the real Hearthbrick parts (builds/hearthbrick_v2.py walls, hearthbrick_v2_walls.py half walls,
# hearthbrick_v2_round.py pillars), placed on the watchtower's 12-sided ring, then broken.
#   kiln_rim_fallen      a curved piece of the kiln's top that fell off: three walls of the ring, the half-wall rim
#                        on them and the two pillars between, lying on their outside face, bricks knocked out, the
#                        rim broken off jagged at one end
#   brick_stack_toppled  the kiln's last load of fired bricks: a criss-cross stack, its lower half still standing,
#                        the upper half toppled over to one side and spilled across the floor (a few burnt dark)
# Ruins place the rim chunk as a building piece (cleared when the kiln is rebuilt) and the brick stack as rubble you
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
K.SIZE.update({"kiln_rim_fallen": (6.0, 1.7, 3.4), "brick_stack_toppled": (2.6, 1.3, 2.6)})


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


# ---------------- the fallen piece of rim ----------------
def kiln_rim_fallen():
	"""Walls on ring edges 11, 0, 1 with the half-wall rim on top and the two pillars between them, lying on their
	outside face (edge 0 down). The rim over edge 1 broke off jagged; bricks knocked out here and there."""
	parts = []
	for j in (11, 0, 1):
		c = ring_dir(j) * EDGE
		objs = knocked(lambda: HB.wall_body(diamond=(j == 0)), 0.07)
		bake(objs, at(c.x, 0.0, c.z, j * 30.0))
		parts += objs
		if j == 1:   # its rim snapped off: only the left part stays, broken in a jagged slope
			rim = knocked(HBW.half_wall, 0.05, keep=lambda cx, cy: cx < -0.2 - cy * 0.9 + K.rng.uniform(-0.12, 0.12))
		else:
			rim = knocked(HBW.half_wall, 0.05)
		bake(rim, at(c.x, 2.0, c.z, j * 30.0))
		parts += rim
	for j in (11, 0):
		p = ring_dir(j + 0.5) * (CORNER - 0.05)
		before = set(bpy.data.objects)
		HBR.pillar()
		objs = since(before)
		bake(objs, at(p.x, 0.0, p.z, (j + 0.5) * 30.0))
		parts += objs
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


PIECES = {"kiln_rim_fallen": kiln_rim_fallen, "brick_stack_toppled": brick_stack_toppled}


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
