# Rock shelves on cave walls (F232, owner Nov 17, 2026; picture: assets/concepts/cave-decor/rock_shelves_sheet.png).
# Hand-built and painted the Rock Beetle way, like cave_plants.py (MODEL-RULES Rule 1).
#
#   blender --background --factory-startup --python builds/cave_shelves.py -- <out_dir> [only=shelf_a,...] [grey=1]
#
# Blender axes: +Z up, the wall's face is the plane y = 0 with the wall rock behind it (y > 0) and the shelf sticking
# out toward -Y (in Godot: out along +Z, so the game turns +Z to face out of the wall). Rock only: the game puts its own
# moss, mushrooms and crystals on the shelf tops (owner, round 3: "the moss looks like snot... use our existing
# mushrooms... existing crystals, maybe a different colour"); the top spots are SHELF_TOPS in src/art/clutter.gd.
#   shelf_a   a long ledge                       top at z = 0
#   shelf_b   a thick chunky shelf (moss on top)  top at z = 0
#   shelf_c   a stepped double shelf (mushrooms)  tops at z = 0.24 and z = -0.22
#   shelf_d   a short wedge shelf (crystals)      top at z = 0
# Owner, round 3: thicker (not flat plates), fewer scratches, the wall behind made of rocks of different sizes and
# shapes (not squares), stronger light and shade like the picture.
import math
import random
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Euler, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import cave_plants as cp  # noqa: E402
import creature_kit as ck  # noqa: E402
import creature_sculpt as cs  # noqa: E402
import kit  # noqa: E402

ROCK = ((0.56, 0.47, 0.39), (0.32, 0.27, 0.23), (0.78, 0.68, 0.57))  # the cave's stone, a touch warmer; neutral (not red) shade


def chunk(name, center, half, seed, n=18, jitter=0.2, turn=0.35):
	"""A chisel-cut rock: the skin wrapped round points scattered in a turned, squashed ball (flat facets, no blob,
	no box)."""
	r = random.Random(seed)
	c, h = Vector(center), Vector(half)
	rot = Euler((r.uniform(-turn, turn), r.uniform(-turn, turn), r.uniform(-turn, turn))).to_matrix()
	bm = bmesh.new()
	for k in range(n):
		u = Vector((r.gauss(0, 1), r.gauss(0, 1), r.gauss(0, 1))).normalized()
		u = Vector((math.copysign(abs(u.x) ** 0.7, u.x), math.copysign(abs(u.y) ** 0.7, u.y), math.copysign(abs(u.z) ** 0.7, u.z)))
		p = Vector((u.x * h.x, u.y * h.y, u.z * h.z)) * (1 - jitter * r.random())
		bm.verts.new(c + rot @ p)
	bmesh.ops.convex_hull(bm, input=bm.verts)
	me = bpy.data.meshes.new(name)
	bm.to_mesh(me)
	bm.free()
	o = bpy.data.objects.new(name, me)
	bpy.context.scene.collection.objects.link(o)
	o.data.materials.append(cp.grey())
	return o


def wall(seed, w, h):
	"""The wall rock behind the shelf, face at y = 0: one solid mass with an uneven edge. A big main rock, and rocks of
	different sizes pressed into its edge and face (all overlapping it: nothing floats)."""
	r = random.Random(seed)
	parts = [chunk("wall", (0, 0.12, 0), (w * 0.85, 0.13, h * 0.85), seed, n=26, turn=0.15)]
	for k in range(12):
		a = k * 2 * math.pi / 12 + r.uniform(-0.2, 0.2)
		reach = r.uniform(0.45, 0.8)  # their middles stay inside the main rock
		size = r.uniform(0.2, 0.42)
		parts.append(chunk(f"wk{k}", (math.cos(a) * w * reach, 0.06 + r.uniform(0.0, 0.05), math.sin(a) * h * reach),
			(w * size * r.uniform(0.75, 1.25), r.uniform(0.08, 0.13), h * size * r.uniform(0.75, 1.25)), seed + 10 + k, n=14, turn=0.4))
	return parts


def slab(name, top, depth, width, thick, seed):
	"""A thick layered shelf: plates stacked under each other, each set back a little and turned a little, an uneven
	front; the top plate's top at z = top."""
	r = random.Random(seed)
	parts = []
	z = top
	for k in range(3):
		t = thick * r.uniform(0.28, 0.42)
		d = depth * (1.0 - 0.18 * k) * r.uniform(0.9, 1.05)
		parts.append(chunk(f"{name}{k}", (r.uniform(-0.04, 0.04), -d * 0.5 + 0.04, z - t * 0.5), (width * r.uniform(0.85, 1.0), d * 0.55, t * 0.55),
			seed + k, n=22, jitter=0.08, turn=0.04))
		z -= t * 0.85
	for k in range(4):  # broken lumps along the front edge, half inside the shelf
		x = r.uniform(-width, width) * 0.6
		parts.append(chunk(f"{name}lump{k}", (x, -depth * r.uniform(0.6, 0.8), top - thick * r.uniform(0.35, 0.6)),
			(r.uniform(0.06, 0.1), r.uniform(0.06, 0.09), r.uniform(0.06, 0.1)), seed + 30 + k, n=12, turn=0.5))
	return parts


def rock_part(parts, seed):
	stone = cs.melt(parts, voxel=0.006, smooth=1, name="rock")
	cs.carve_stone(stone, seed=seed, grain=0.0012, crack=0.0012, chips=0.01, soften=0)  # (few cracks: owner)
	return [(stone, 3200, 1024, lambda nm: cs.paint_material(nm, *ROCK, scratches=0.05, scratch_width=1.0, grime=0.08, edge=0.7,
		top_light=0.45, key=0.5, strokes=0.1, seed=3.0))]  # (round 5: clean paint, owner)


def build_a(seed=91):
	return rock_part(wall(seed, 0.55, 0.4) + slab("ledge", 0.0, 0.34, 0.52, 0.2, seed), seed)


def build_b(seed=101):
	return rock_part(wall(seed, 0.45, 0.48) + slab("shelf", 0.0, 0.38, 0.44, 0.32, seed), seed)


def build_c(seed=111):
	return rock_part(wall(seed, 0.45, 0.6) + slab("upper", 0.24, 0.26, 0.36, 0.16, seed) + slab("lower", -0.22, 0.38, 0.44, 0.22, seed + 5), seed)


def build_d(seed=121):
	wedge = []  # wide at the wall, narrowing to a point, thick
	for k in range(3):
		wedge.append(chunk(f"wedge{k}", (0, -0.07 - 0.1 * k, -0.06 - 0.02 * k), (0.3 - 0.08 * k, 0.1, 0.07 - 0.01 * k), seed + k, n=16, turn=0.1))
	return rock_part(wall(seed, 0.4, 0.42) + wedge, seed)


BUILDS = {"shelf_a": build_a, "shelf_b": build_b, "shelf_c": build_c, "shelf_d": build_d}

if __name__ == "__main__":
	for name, fn in BUILDS.items():
		if cp.ONLY and name not in cp.ONLY:
			continue
		kit.reset()
		ck.reset()
		objs = cp.finish(name, fn())
		cp.export(name, objs)
		cp.pictures(name, objs)
