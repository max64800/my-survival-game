# Rough SKETCHES of 7 proposed building pieces (owner, Nov 21: the piece KINDS a big survival builder has that we
# lack; names and looks are our own). Plain sand colour on purpose: these only show size and shape for the owner's
# yes/no. Approved pieces get real models later (docs/art/MODEL-RULES.md), never these sketches.
#   blender --background --factory-startup --python builds/new_pieces_sketch.py -- out=<folder>
# Coordinates below are the game's (y up, front = +z); each piece's origin is its bottom centre.
import math
import sys
from pathlib import Path

import bpy

SAND = (0.80, 0.68, 0.50, 1)
DARK = (0.48, 0.38, 0.27, 1)
_mats = {}


def mat(rgba):
	if rgba not in _mats:
		m = bpy.data.materials.new("sketch_%d" % len(_mats))
		m.use_nodes = True
		b = m.node_tree.nodes["Principled BSDF"]
		b.inputs["Base Color"].default_value = rgba
		b.inputs["Roughness"].default_value = 0.9
		_mats[rgba] = m
	return _mats[rgba]


def g2b(p):
	"""game (x, y, z) -> Blender (x, -z, y)"""
	return (p[0], -p[2], p[1])


def mesh(verts, faces, col=SAND, bevel=0.015):
	me = bpy.data.meshes.new("m")
	me.from_pydata([g2b(v) for v in verts], [], faces)
	me.update()
	o = bpy.data.objects.new("o", me)
	bpy.context.collection.objects.link(o)
	o.data.materials.append(mat(col))
	if bevel:
		md = o.modifiers.new("b", "BEVEL")
		md.width = bevel
		md.segments = 1
	return o


def prism_xz(poly, y0, y1, col=SAND, bevel=0.015):
	"""a flat shape in the floor plane (x, z points, counter-clockwise seen from above) from y0 up to y1"""
	n = len(poly)
	v = [(x, y0, z) for x, z in poly] + [(x, y1, z) for x, z in poly]
	f = [list(range(n))[::-1], list(range(n, 2 * n))] + [[i, (i + 1) % n, n + (i + 1) % n, n + i] for i in range(n)]
	o = mesh(v, f, col, bevel)
	fix_normals(o)
	return o


def prism_xy(poly, z0, z1, col=SAND, bevel=0.015):
	"""a flat shape in the wall plane (x, y points) from z0 to z1"""
	n = len(poly)
	v = [(x, y, z0) for x, y in poly] + [(x, y, z1) for x, y in poly]
	f = [list(range(n)), list(range(n, 2 * n))] + [[i, (i + 1) % n, n + (i + 1) % n, n + i] for i in range(n)]
	o = mesh(v, f, col, bevel)
	fix_normals(o)
	return o


def prism_zy(poly, x0, x1, col=SAND, bevel=0.015):
	"""a flat shape in the side plane (z, y points) from x0 to x1"""
	n = len(poly)
	v = [(x0, y, z) for z, y in poly] + [(x1, y, z) for z, y in poly]
	f = [list(range(n)), list(range(n, 2 * n))] + [[i, (i + 1) % n, n + (i + 1) % n, n + i] for i in range(n)]
	o = mesh(v, f, col, bevel)
	fix_normals(o)
	return o


def fix_normals(o):
	bpy.context.view_layer.objects.active = o
	o.select_set(True)
	bpy.ops.object.mode_set(mode="EDIT")
	bpy.ops.mesh.select_all(action="SELECT")
	bpy.ops.mesh.normals_make_consistent(inside=False)
	bpy.ops.object.mode_set(mode="OBJECT")
	o.select_set(False)


def box(c, s, col=SAND, bevel=0.015):
	x, y, z = c
	a, b, d = s[0] / 2, s[1] / 2, s[2] / 2
	return prism_xz([(x - a, z + d), (x + a, z + d), (x + a, z - d), (x - a, z - d)], y - b, y + b, col, bevel)


def cyl(c, r, h, col=SAND, n=20, bevel=0.01):
	return prism_xz([(c[0] + r * math.cos(2 * math.pi * i / n), c[2] - r * math.sin(2 * math.pi * i / n)) for i in range(n)],
		c[1], c[1] + h, col, bevel)


def boolean(target, cutter, op="DIFFERENCE"):
	md = target.modifiers.new("x", "BOOLEAN")
	md.operation = op
	md.object = cutter
	bpy.context.view_layer.objects.active = target
	bpy.ops.object.modifier_apply(modifier="x")
	bpy.data.objects.remove(cutter)


# ---------------- 1a corner stairs: 8 steps fanning a quarter turn round the front-left corner, 2 m up ----------
def stairs_corner():
	px, pz = -1.0, 1.0                     # the corner they turn round
	n = 8
	def edge(a):                            # where a ray from the corner at angle a meets the square's far sides
		dx, dz = math.cos(a), -math.sin(a)
		t = min(2 / dx if dx > 1e-6 else 9, 2 / -dz if dz < -1e-6 else 9)
		return (px + dx * t, pz + dz * t)
	for i in range(n):
		a0, a1 = math.radians(90 * i / n), math.radians(90 * (i + 1) / n)
		pts = [(px, pz), edge(a0)]
		if a0 < math.radians(45) < a1:
			pts.append((1.0, -1.0))
		pts.append(edge(a1))
		top = 0.25 * (i + 1)
		prism_xz(pts, 0.0, top, SAND if i % 2 == 0 else DARK)
	cyl((px + 0.12, 0, pz - 0.12), 0.12, 2.0, DARK)   # a newel post at the turn


# ---------------- 1b spiral stairs: round a post, one full turn up 2 m, in one 2 x 2 cell -----------------------
def stairs_spiral():
	n, R = 12, 0.95
	cyl((0, 0, 0), 0.16, 2.15, DARK)
	for i in range(n):
		a0, a1 = 2 * math.pi * i / n, 2 * math.pi * (i + 1) / n + 0.04
		pts = [(0.1 * math.cos(a0), -0.1 * math.sin(a0))]
		for k in range(4):
			a = a0 + (a1 - a0) * k / 3
			pts.append((R * math.cos(a), -R * math.sin(a)))
		pts.append((0.1 * math.cos(a1), -0.1 * math.sin(a1)))
		top = 2.0 * (i + 1) / n
		prism_xz(pts, top - 0.12, top, SAND)


# ---------------- 2 stair railing: slants with the stairs (2 m run, 2 m rise, rising toward -z) -------------------
def railing_stairs():
	t = 0.12
	for z in (0.92, 0.0, -0.92):           # three posts standing on the steps
		base = 1.0 - z                       # the step line under it
		box((0, base / 2 + 0.45, z), (t, base + 0.9, t), DARK)
	for h, th in ((0.9, 0.1), (0.45, 0.06)):   # the hand rail and a lower rail, both slanted 45 degrees
		prism_zy([(1.0, h), (1.0, h + th), (-1.0, 2.0 + h + th), (-1.0, 2.0 + h)], -t / 2, t / 2, SAND)


# ---------------- 3 upside-down slanted wall: full along the top, slanting down to one side ---------------------
def sloped_wall_down():
	prism_xy([(-1, 2), (-1, 0), (1, 2)], -0.15, 0.15, SAND)


# ---------------- 4 thin edge strip: a narrow lip along a floor's edge -------------------------------------------
def edge_strip():
	box((0, 0.15, 0), (2.0, 0.3, 0.07), SAND)
	box((0, 0.325, 0.02), (2.0, 0.05, 0.11), DARK)   # a little rounded lip on top that sticks out


# ---------------- 5 roof peak cap: closes the tip where 4 slanted roofs meet ---------------------------------------
def roof_cap():
	s, h = 0.55, 0.5
	v = [(-s, 0, -s), (s, 0, -s), (s, 0, s), (-s, 0, s), (0, h, 0)]
	o = mesh(v, [[0, 1, 2, 3], [0, 4, 1], [1, 4, 2], [2, 4, 3], [3, 4, 0]], SAND)
	fix_normals(o)
	cyl((0, h - 0.08, 0), 0.08, 0.28, DARK)
	cyl((0, h + 0.2, 0), 0.13, 0.12, DARK)    # a little knob on top


# ---------------- 6 round floor hatch: a floor with a round hole and a lid hinged open -------------------------
def floor_hatch():
	slab = box((0, -0.125, 0), (2, 0.25, 2), SAND, bevel=0)
	boolean(slab, cyl((0, -0.4, 0), 0.55, 0.8, SAND, n=24, bevel=0))
	ring = cyl((0, -0.02, 0), 0.66, 0.06, DARK, n=24, bevel=0)
	boolean(ring, cyl((0, -0.2, 0), 0.55, 0.5, SAND, n=24, bevel=0))
	lid = cyl((0, 0, 0), 0.54, 0.08, DARK, n=24)           # the lid, swung up about its back hinge
	lid.select_set(True)
	bpy.context.view_layer.objects.active = lid
	bpy.context.scene.cursor.location = g2b((0, 0, -0.54))
	bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
	lid.rotation_euler[0] = math.radians(-70)
	lid.select_set(False)
	box((0, 0.1, -0.5), (0.18, 0.06, 0.06), (0.3, 0.3, 0.3, 1))   # hinge


# ---------------- 7 open lattice wall: a see-through screen of crossing bars in a frame ------------------------
def lattice_wall():
	f, d = 0.16, 0.3
	box((0, 0.08, 0), (2, f, d), DARK)
	box((0, 2 - 0.08, 0), (2, f, d), DARK)
	box((-1 + 0.08, 1, 0), (f, 2 - 2 * f, d), DARK)
	box((1 - 0.08, 1, 0), (f, 2 - 2 * f, d), DARK)
	panel = box((0, 1, 0), (2 - 2 * f + 0.02, 2 - 2 * f + 0.02, 0.1), SAND, bevel=0)
	step, r = 0.42, 0.15                    # diamond holes cut through it
	k = 0
	for i in range(-4, 5):
		for j in range(-4, 5):
			x, y = i * step / 2, 1 + j * step / 2
			if (i + j) % 2 or abs(x) > 0.9 or abs(y - 1) > 0.9:
				continue
			cut = prism_xy([(x, y - r), (x + r, y), (x, y + r), (x - r, y)], -0.3, 0.3, SAND, bevel=0)
			boolean(panel, cut)
			k += 1


PIECES = {"stairs_corner": stairs_corner, "stairs_spiral": stairs_spiral, "railing_stairs": railing_stairs,
	"sloped_wall_down": sloped_wall_down, "edge_strip": edge_strip, "roof_cap": roof_cap, "floor_hatch": floor_hatch,
	"lattice_wall": lattice_wall}

if __name__ == "__main__":
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	out = Path(next(a[4:] for a in args if a.startswith("out=")))
	out.mkdir(parents=True, exist_ok=True)
	for name, fn in PIECES.items():
		bpy.ops.wm.read_factory_settings(use_empty=True)
		_mats.clear()
		fn()
		bpy.ops.export_scene.gltf(filepath=str(out / f"{name}__sketch.glb"), export_format="GLB", export_apply=True)
		print("SKETCH_OK", name)
