# Breakable boulders (owner, Nov 18, 2026: "rocks like in Conan Exiles that you can break to get some stone, multiple
# shapes around the caves"). Hand-built (MODEL-RULES Rule 1): chisel-cut rocks (the skin wrapped round scattered points,
# flat facets, no blob, no box), cracks and chips carved in, painted with the hand-painted stone pictures so they sit
# with the cave rock. Real sizes in metres, standing on z = 0, every part pressed into its neighbours (nothing floats).
#
#   blender --background --factory-startup --python builds/cave_boulders.py -- <out_dir> [only=boulder_round,...]
#
#   boulder_round    one big rounded boulder with two small stones at its foot
#   boulder_tall     a leaning standing stone with rubble round its base
#   boulder_slabs    flat slabs stacked on each other, slightly slid
#   boulder_cluster  three or four rocks of different sizes pressed together
#   boulder_split    a big boulder split in two by a crack, the halves 2 cm apart
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

TEX = Path(__file__).resolve().parents[3] / "assets" / "textures" / "kit"
STONE = ((0.5, 0.46, 0.41), (0.28, 0.25, 0.22), (0.72, 0.67, 0.6))


def chunk(name, center, half, seed, n=22, jitter=0.22, turn=0.35):
	"""A chisel-cut rock: the skin wrapped round points scattered in a turned, squashed ball."""
	r = random.Random(seed)
	c, h = Vector(center), Vector(half)
	rot = Euler((r.uniform(-turn, turn), r.uniform(-turn, turn), r.uniform(0, math.tau))).to_matrix()
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


def finish(parts, seed, pic):
	stone = cs.melt(parts, voxel=0.012, smooth=1, name="rock")
	cs.carve_stone(stone, seed=seed, grain=0.004, crack=0.0015, chips=0.03, soften=0)  # (round 2: fewer scribbly cracks)
	return [(stone, 2600, 1024, lambda nm: cs.paint_material(nm, *STONE, scratches=0.0, grime=0.18, edge=0.55,
		top_light=0.3, key=0.45, strokes=0.1, seed=seed * 0.1, picture=str(TEX / pic), picture_scale=1.1, picture_amount=0.85))]


def boulder_round(seed=401, pic="greystone_a.png"):
	parts = [chunk("main", (0, 0, 0.5), (0.7, 0.62, 0.55), seed)]
	parts.append(chunk("s1", (0.5, 0.15, 0.14), (0.24, 0.22, 0.18), seed + 1, n=14))  # (pressed into the big one)
	parts.append(chunk("s2", (-0.34, -0.4, 0.12), (0.19, 0.17, 0.14), seed + 2, n=12))
	return finish(parts, seed, pic)


def boulder_tall(seed=411, pic="brownrock_a.png"):
	parts = [chunk("main", (0.08, 0, 0.8), (0.38, 0.34, 0.85), seed, turn=0.15)]
	r = random.Random(seed)
	for k in range(4):
		a = k * math.tau / 4 + r.uniform(-0.4, 0.4)
		parts.append(chunk(f"rub{k}", (math.cos(a) * 0.3, math.sin(a) * 0.3, 0.1), (0.17, 0.14, 0.12), seed + 10 + k, n=12))  # (touching its foot)
	return finish(parts, seed, pic)


def boulder_slabs(seed=421, pic="warmstone_b.png"):
	parts = []
	z = 0.14
	for k in range(3):
		w = 0.75 - k * 0.15
		parts.append(chunk(f"slab{k}", (0.06 * k, -0.05 * k, z), (w, w * 0.85, 0.16), seed + k, turn=0.08))
		z += 0.27
	return finish(parts, seed, pic)  # (round 2: limestone was too pale)


def boulder_cluster(seed=431, pic="greystone_b.png"):
	parts = [chunk("a", (0, 0, 0.42), (0.48, 0.44, 0.42), seed),
		chunk("b", (0.55, 0.25, 0.3), (0.34, 0.3, 0.3), seed + 1),
		chunk("c", (-0.35, 0.45, 0.24), (0.28, 0.26, 0.24), seed + 2),
		chunk("d", (0.15, -0.38, 0.18), (0.22, 0.2, 0.18), seed + 3, n=14)]
	return finish(parts, seed, pic)


def boulder_split(seed=441, pic="brownrock_b.png"):
	"""Two halves of one boulder with a crack between: built as one rock, then cut by a plane and pulled 2 cm apart."""
	whole = chunk("whole", (0, 0, 0.55), (0.75, 0.6, 0.55), seed)
	halves = []
	for side in (-1, 1):
		h = whole.copy()
		h.data = whole.data.copy()
		bpy.context.scene.collection.objects.link(h)
		bm = bmesh.new()
		bm.from_mesh(h.data)
		geom = bm.verts[:] + bm.edges[:] + bm.faces[:]
		res = bmesh.ops.bisect_plane(bm, geom=geom, plane_co=Vector((0.05, 0, 0)), plane_no=Vector((side, 0.25 * side, 0)),
			clear_inner=True)
		bmesh.ops.contextual_create(bm, geom=[e for e in res["geom_cut"] if isinstance(e, bmesh.types.BMEdge)])
		bm.to_mesh(h.data)
		bm.free()
		h.location.x += side * 0.012
		halves.append(h)
	bpy.data.objects.remove(whole)
	out = []
	for k, h in enumerate(halves):
		out += finish([h], seed + k, pic)
		out[-1][0].name = f"rock{k}"
	return out


BUILDS = {"boulder_round": boulder_round, "boulder_tall": boulder_tall, "boulder_slabs": boulder_slabs,
	"boulder_cluster": boulder_cluster, "boulder_split": boulder_split}
# Two more stone looks per shape (owner, Nov 18: "we need different styles in terms of textures"): _b and _c, each its
# own stone picture and its own seed (so the rock is cut differently too).
LOOKS = {"boulder_round": ["slate_a.png", "amberrock_a.png"], "boulder_tall": ["basalt_a.png", "greystone_c.png"],
	"boulder_slabs": ["slate_b.png", "limestone_b.png"], "boulder_cluster": ["warmstone_a.png", "basalt_b.png"],
	"boulder_split": ["amberrock_b.png", "greystone_a.png"]}
for _name, _fn in list(BUILDS.items()):
	for _k, _pic in enumerate(LOOKS[_name]):
		BUILDS[f"{_name}_{'bc'[_k]}"] = (lambda f=_fn, p=_pic, k=_k: f(seed=f.__defaults__[0] + 3 + k * 2, pic=p))

if __name__ == "__main__":
	for name, fn in BUILDS.items():
		if cp.ONLY and name not in cp.ONLY:
			continue
		kit.reset()
		ck.reset()
		objs = cp.finish(name, fn())
		cp.export(name, objs)
		cp.pictures(name, objs)
