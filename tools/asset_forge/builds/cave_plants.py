# Cave plants and crystals, hand-built, sculpted and painted the Rock Beetle way (Claude 2, Nov 16, 2026; owner: "roots,
# mushrooms, crystals by hand to match the beetle complexity", then "paint them, wear and tear, chipped parts; crystals in
# packs of 5-6 in a node; roots wide-ish, sticking out of the ground, not from the ceiling"). MODEL-RULES Rule 1: every
# shape comes from this script.
#
#   blender --background --factory-startup --python builds/cave_plants.py -- <out_dir> [only=root,glowcap,...] [grey=1]
#
# Writes <out_dir>/<name>.glb (the light game copy with its baked paint) and <out_dir>/<name>_a.png / _b.png (pictures).
# grey=1 skips the paint (fast shape check).
#
# How (docs/art/CREATURE-RECIPE.md): pieces are melted into one skin (creature_sculpt.melt), carved (bark furrows, chips,
# cracks), then a light game copy gets the dense sculpt's paint and detail baked onto it as pictures (colour + normal map).
#
# The models (Blender: +Z up, origin on the ground where it grows):
#   root      a big root breaking out of the floor (rootwood): a thick twisted root arching out of the ground and diving
#             back in, a second one standing up with a broken, splintered top, knots, rootlets, soil heaped where they
#             come out, pebbles. Bark: cracked plates, chipped patches, scratches, a little moss.
#   glowcap   five mushrooms on a mound of soil and mycelium: bulbous feet, curved stems with rings, domed caps with a
#             curled lip, gills underneath, warts on top, bites out of the rims, bruises. The cap is painted pale so
#             the game can tint it (glowcap, bellcap, firecap... all share it).
#   crystal   a node of six crystals packed together on a chunk of rock: six-sided prisms with faceted points, chipped
#             corners and broken tips; painted pale so the game tints it (blue, green, amber).
#   giant     a giant mushroom (~4 m, Fungal Jungle wood): a ribbed stalk with root buttresses and a ragged skirt, a wide
#             wavy purple cap with warts, gills and bites out of its rim.
#
# Parts / materials: <part>_<model>; anything that glows starts with glow_ (the game lights it up and tints it).
import math
import random
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector, noise

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import creature_kit as ck  # noqa: E402
import creature_sculpt as cs  # noqa: E402
import glb_jpeg_fix  # noqa: E402  (Blender's JPEGs carry an EXIF block Godot can't read: the model turns white)
import kit  # noqa: E402

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = Path(ARGS[0]) if ARGS else Path(".")
OPTS = dict(a.split("=", 1) for a in ARGS[1:] if "=" in a)
ONLY = OPTS.get("only", "").split(",") if OPTS.get("only") else None
GREY = OPTS.get("grey") == "1"


def grey():
	return ck.color("grey", (0.62, 0.6, 0.57), rough=0.9)


def tube(name, pts, radii, sides=10, wobble=0.04, seed=1, twist=0.0, up=Vector((1, 0, 0))):
	"""A round loft through pts with matching radii (a branch, a strand, a stem)."""
	rings = [(p, r, r, twist * i / max(1, len(pts) - 1)) for i, (p, r) in enumerate(zip(pts, radii))]
	return ck.loft(name, rings, grey(), sides=sides, subsurf=0, wobble=wobble, seed=seed, up=up)


def smooth_path(pts, n):
	"""n points along a Catmull-Rom curve through pts (gnarled, but no kinks)."""
	pts = [Vector(p) for p in pts]
	ext = [pts[0] * 2 - pts[1]] + pts + [pts[-1] * 2 - pts[-2]]
	out = []
	for i in range(n):
		t = i / (n - 1) * (len(pts) - 1)
		k = min(int(t), len(pts) - 2)
		u = t - k
		p0, p1, p2, p3 = ext[k], ext[k + 1], ext[k + 2], ext[k + 3]
		out.append(0.5 * ((2 * p1) + (-p0 + p2) * u + (2 * p0 - 5 * p1 + 4 * p2 - p3) * u * u + (-p0 + 3 * p1 - 3 * p2 + p3) * u ** 3))
	return out


def lump(name, loc, size, seed, jitter=0.25, detail=3):
	"""A soft lumpy blob: a coarse jittered ball, smoothed (a fine one with jitter turns spiky and shreds)."""
	o = ck.blob(loc, size, grey(), seed=seed, subsurf=2, jitter=jitter, detail=1 if detail < 3 else 2)
	o.name = name
	return o


def carve(o, fn, soften=1):
	cs._displace(o, fn)
	if soften:
		s = o.modifiers.new("soften", "SMOOTH")
		s.iterations = soften
		s.factor = 0.5
		cs._apply_all(o)


def join(objs, name):
	for o in objs:  # apply first: _apply_all selects only its own object
		cs._apply_all(o)
	bpy.ops.object.select_all(action="DESELECT")
	for o in objs:
		o.select_set(True)
	bpy.context.view_layer.objects.active = objs[0]
	if len(objs) > 1:
		bpy.ops.object.join()
	o = bpy.context.view_layer.objects.active
	o.name = name
	return o


def bite(o, bites):
	"""Chunks missing from a rim (nibbled, broken): vertices near a bite are pushed in toward the middle."""
	for v in o.data.vertices:
		for c, toward, rad in bites:
			d = (v.co - c).length
			if d < rad:
				flat = toward - v.co
				flat.z *= 0.3
				v.co += flat.normalized() * (rad - d) * 0.9


def twisted(name, path, radius, strands, turns, spread, seed, up_ref):
	"""Strands twisting round each other along a path (an old root), as separate tubes the melt fuses into one."""
	out = []
	n = len(path)
	for s in range(strands):
		pts, rad = [], []
		for i, p in enumerate(path):
			u = i / (n - 1)
			t = (path[min(i + 1, n - 1)] - path[max(i - 1, 0)]).normalized()
			side = t.cross(up_ref).normalized()
			nrm = side.cross(t)
			a = s * 2 * math.pi / strands + turns * 2 * math.pi * u
			pts.append(p + (side * math.cos(a) + nrm * math.sin(a)) * spread(u))
			rad.append(radius(u) * (1 + 0.08 * math.sin(i * 1.7 + s * 2)))
		out.append(tube(f"{name}{s}", pts, rad, sides=10, seed=seed + s, up=up_ref))
	return out


# ---------------------------------------------------------------- the roots breaking out of the floor
def arch_path(a, b, height, n=30, wander=0.06, seed=0):
	"""A root path out of the ground at a, up to `height`, and back into the ground at b (both just below the floor)."""
	r = random.Random(seed)
	a, b = Vector(a), Vector(b)
	pts = []
	for t in (0.0, 0.12, 0.33, 0.62, 0.86, 1.0):
		p = a.lerp(b, t)
		lift = math.sin(math.pi * t) ** 0.8 * height
		side = Vector((-(b - a).y, (b - a).x, 0)).normalized()
		pts.append(p + Vector((0, 0, lift)) + side * r.uniform(-wander, wander))
	return smooth_path(pts, n)


def build_root(seed=11, variant="a"):
	"""Three looks (owner, Nov 16: "different variations of roots"): a = one big arch and a broken standing root;
	b = a broken-off stump with thick roots spreading out into the ground all round; c = a tangle of three arches."""
	r = random.Random(seed)
	Y = Vector((0, 1, 0))
	parts, arches, stands = [], [], []
	if variant == "a":
		arches.append((smooth_path([(-0.8, 0.05, -0.2), (-0.62, 0.0, 0.28), (-0.25, 0.06, 0.66), (0.22, -0.04, 0.62), (0.58, 0.02, 0.24), (0.78, 0.08, -0.2)], 30), 0.105, 2))
		stands.append((smooth_path([(-0.3, -0.38, -0.2), (-0.26, -0.33, 0.35), (-0.14, -0.36, 0.75), (-0.18, -0.3, 1.02)], 18), 0.085, 3))
	elif variant == "b":
		stands.append((smooth_path([(0.0, 0.0, -0.2), (0.03, -0.02, 0.3), (-0.04, 0.03, 0.6), (0.02, 0.0, 0.82)], 18), 0.15, 4))
		for k in range(5):  # thick roots spreading out from the stump's foot and diving into the ground
			a = k * 2 * math.pi / 5 + r.uniform(-0.25, 0.25)
			o = Vector((math.cos(a), math.sin(a), 0))
			ln = r.uniform(0.7, 0.95)
			path = smooth_path([o * 0.05 + Vector((0, 0, 0.42)), o * 0.25 + Vector((0, 0, 0.3)), o * ln * 0.6 + Vector((0, 0, 0.14)), o * ln + Vector((0, 0, -0.2))], 18)
			arches.append((path, 0.085 - 0.01 * (k % 2), 2))
	else:
		arches.append((arch_path((-0.85, -0.1, -0.2), (0.75, 0.2, -0.2), 0.62, seed=seed), 0.1, 2))
		arches.append((arch_path((-0.35, 0.65, -0.2), (0.3, -0.7, -0.2), 0.45, seed=seed + 1), 0.08, 2))
		arches.append((arch_path((0.25, 0.45, -0.2), (0.85, -0.25, -0.2), 0.3, n=22, seed=seed + 2), 0.065, 2))
		stands.append((smooth_path([(-0.55, -0.45, -0.2), (-0.52, -0.42, 0.2), (-0.47, -0.45, 0.48)], 12), 0.07, 2))
	for k, (path, r0, strands) in enumerate(arches):
		parts += twisted(f"arch{k}_", path, lambda u, r0=r0: r0 * (1 - 0.33 * u), strands, 1.4, lambda u, r0=r0: r0 * 0.67 * (1 - 0.3 * u), seed + 10 * k, Y if variant != "b" else Vector((0, 0, 1)))
	for k, (path, r0, strands) in enumerate(stands):
		parts += twisted(f"stand{k}_", path, lambda u, r0=r0: r0 * (1 - 0.24 * u), strands, 0.9, lambda u, r0=r0: r0 * 0.65 * (1 - 0.27 * u), seed + 5 + 10 * k, Vector((1, 0, 0)))
		top, rr = path[-1], r0 * 0.9
		for j in range(7):  # splinters round the broken top, different heights
			a = j * 2 * math.pi / 7 + r.uniform(-0.3, 0.3)
			o = Vector((math.cos(a), math.sin(a), 0))
			base = top + o * rr * r.uniform(0.35, 0.8) - Vector((0, 0, 0.05))
			tip = base + o * r.uniform(0.0, 0.03) + Vector((0, 0, r.uniform(0.05, 0.16) * (1 + rr * 3)))
			parts.append(tube(f"splinter{k}_{j}", [base, (base + tip) / 2, tip], [rr * 0.33, rr * 0.24, 0.006], sides=5, wobble=0.15, seed=seed + 40 + j))
	# Knots (burls) where old side roots broke off.
	for k in range(4):
		path, r0, _ = (arches + stands)[k % len(arches + stands)]
		p = path[int(len(path) * (0.28 + 0.17 * k)) % len(path)]
		w = r0 * 0.7
		a = r.uniform(0, 2 * math.pi)
		parts.append(lump(f"knot{k}", tuple(p + Vector((math.cos(a), 0.6 * math.sin(a), 0.5)) * w), (w, w, w * 0.8), seed + 20 + k, jitter=0.3, detail=2))
	# Rootlets: thinner roots leaving the arches and diving into the ground.
	fine = []
	for k in range(4):
		path, r0, _ = arches[k % len(arches)]
		p = path[int(len(path) * (0.2 + 0.2 * k)) % len(path)]
		if p.z < 0.12:
			continue
		side = 1 if k % 2 else -1
		ln = r.uniform(0.3, 0.5)
		t = (path[min(len(path) - 1, 1 + int(len(path) * (0.2 + 0.2 * k)) % len(path))] - p).normalized()
		o = t.cross(Vector((0, 0, 1))).normalized() * side
		ctrl = [p, p + o * 0.18 + Vector((0, 0, -0.08)), p + o * ln * 0.7 + Vector((0, 0, -p.z * 0.6)), p + o * ln + Vector((0, 0, -p.z - 0.12))]
		parts.append(tube(f"rootlet{k}", smooth_path(ctrl, 10), [r0 * 0.4 * (1 - j / 9) + 0.012 for j in range(10)], sides=8, seed=seed + 30 + k))
	ends = [a[0][0] for a in arches] + [a[0][-1] for a in arches if a[0][-1].z < 0] + [s_[0][0] for s_ in stands]
	# Hair roots poking out of the soil.
	for k in range(12):
		a = r.uniform(0, 2 * math.pi)
		o = Vector((math.cos(a), math.sin(a), 0))
		end = ends[k % len(ends)]
		base = Vector((end.x, end.y, 0.0)) + o * r.uniform(0.15, 0.3)
		ctrl = [base - Vector((0, 0, 0.03)), base + o * 0.05 + Vector((0, 0, 0.05)), base + o * 0.12 + Vector((0, 0, r.uniform(0.02, 0.07)))]
		fine.append(tube(f"hair{k}", smooth_path(ctrl, 6), [0.007 - 0.0008 * j for j in range(6)], sides=5, seed=seed + 80 + k))
	# Soil heaped where the roots come out of the ground, broken clods round it.
	soil = []
	for k, end in enumerate(ends):
		c = Vector((end.x, end.y, -0.07))
		big = 1.5 if variant == "b" and k == len(ends) - 1 else 1.0  # the stump's foot gets a wide heap
		soil.append(lump(f"heap{k}", tuple(c), (0.3 * big, 0.26 * big, 0.13), seed + 50 + k, jitter=0.22, detail=4))
		for j in range(3):
			a = r.uniform(0, 2 * math.pi)
			soil.append(lump(f"clod{k}{j}", tuple(c + Vector((math.cos(a) * 0.3 * big, math.sin(a) * 0.26 * big, 0.0))), (r.uniform(0.05, 0.08),) * 2 + (0.04,),
				seed + 60 + 3 * k + j, jitter=0.3, detail=2))
	pebbles = [lump(f"pebble{k}", tuple(Vector((ends[k % len(ends)].x, ends[k % len(ends)].y, 0.02)) + Vector((math.cos(k * 2.3), math.sin(k * 2.3), 0)) * 0.24),
		(0.035 + 0.006 * (k % 3), 0.03, 0.026), seed + 70 + k, jitter=0.12, detail=2) for k in range(6)]

	bark = cs.melt(parts, voxel=0.005, smooth=4, name="bark")

	def bark_fn(p, n):  # cracked bark plates, chipped patches (bark knocked off), fine grain
		q = p * 26 + Vector((seed, 0, 0))
		plates = -0.006 * (1 - abs(noise.noise(q)) ** 0.5)
		chip = noise.noise(p * 6 + Vector((3, seed, 1)))
		chipped = -0.006 if chip > 0.42 else 0.0
		return plates + chipped + 0.0012 * noise.fractal(p * 90, 0.5, 2.0, 3)
	carve(bark, bark_fn, soften=1)
	earth = cs.melt(soil, voxel=0.007, smooth=3, name="soil")
	carve(earth, lambda p, n: 0.008 * noise.fractal(p * 22, 0.6, 2.2, 4) - 0.007 * max(0.0, noise.noise(p * 10) - 0.3), soften=1)
	stones = join(pebbles, "rock")
	cs.carve_stone(stones, seed=seed, grain=0.0015, crack=0.002, chips=0.006, soften=1)
	hairs = join(fine, "rootlets")
	B = ((0.38, 0.26, 0.17), (0.15, 0.1, 0.06), (0.62, 0.48, 0.33))
	return [
		(bark, 5500, 1024, lambda n: cs.paint_material(n, *B, moss=(0.36, 0.42, 0.2), moss_amount=0.3, strokes=0.15, edge=0.55, scratches=0.8, grime=0.35, seed=1.0)),
		(earth, 1600, 512, lambda n: cs.paint_material(n, (0.34, 0.26, 0.19), (0.14, 0.1, 0.07), (0.52, 0.42, 0.31), moss=(0.33, 0.4, 0.18), moss_amount=0.15, grime=0.3, seed=2.0)),
		(stones, 400, 256, lambda n: cs.paint_material(n, (0.47, 0.45, 0.42), (0.2, 0.19, 0.18), (0.68, 0.65, 0.6), scratches=0.8, grime=0.3, edge=0.5, seed=3.0)),
		(hairs, 800, 256, lambda n: cs.paint_material(n, *B, grime=0.2, seed=4.0)),
	]


# ---------------------------------------------------------------- the glowing mushroom cluster
CAP_PROF = [(-0.02, 0.3), (-0.08, 0.62), (-0.15, 0.86), (-0.17, 0.96), (-0.1, 1.04), (0.05, 1.04), (0.22, 0.93), (0.4, 0.72), (0.53, 0.44), (0.6, 0.14)]


def mushroom(name, foot, n, height, cr, seed, bend=0.15):
	"""One mushroom: a bulbous foot, a curved stem, a cap with a curled lip, gills underneath, warts on top, and
	1-2 bites out of the rim (returned, cut after the melt)."""
	r = random.Random(seed)
	n = Vector(n).normalized()
	side = n.cross(Vector((0, 0, 1)) if abs(n.z) < 0.95 else Vector((1, 0, 0))).normalized()
	top = foot + n * height + side * height * bend * r.uniform(-1, 1)
	mid = (foot + top) / 2 + side * height * bend * 0.8
	path = smooth_path([foot - n * 0.02, mid, top], 12)
	sr = cr * 0.24
	rad = [sr * (1.55 - 0.65 * min(1, i / 4)) * (1 + 0.04 * math.sin(i * 1.9)) for i in range(12)]
	stem = [tube(f"{name}_stem", path, rad, sides=12, seed=seed)]
	if cr > 0.09:  # a ring (skirt) under the cap on the bigger ones
		p = path[8]
		stem.append(ck.loft(f"{name}_ring", [(p + n * 0.01, sr * 0.9, sr * 0.9), (p, sr * 1.25, sr * 1.25), (p - n * 0.025, sr * 1.55, sr * 1.55),
			(p - n * 0.035, sr * 1.0, sr * 1.0)], grey(), sides=14, subsurf=0, wobble=0.08, seed=seed + 1))
	capdir = (n * 0.8 + (top - mid).normalized() * 0.2).normalized()
	s2 = capdir.cross(side)
	cap = [ck.loft(f"{name}_cap", [(top + capdir * cr * h, cr * w, cr * w) for h, w in CAP_PROF], grey(), sides=28, subsurf=1, wobble=0.035, seed=seed + 2, up=side)]
	for k in range(int(5 + cr * 40)):  # warts on top
		a, b = r.uniform(0, 2 * math.pi), r.uniform(0.15, 0.85)
		d = (capdir * math.cos(b * 1.2) + (side * math.cos(a) + s2 * math.sin(a)) * math.sin(b * 1.2)).normalized()
		p = top + capdir * cr * (0.61 * math.cos(b * 1.4) - 0.02) + (d - capdir * d.dot(capdir)).normalized() * cr * min(1.0, 1.05 * math.sin(b * 1.45))
		w = cr * r.uniform(0.07, 0.12)
		cap.append(lump(f"{name}_wart{k}", tuple(p), (w, w, w * 0.6), seed + 10 + k, jitter=0.25, detail=2))
	gills = []
	count = int(26 + cr * 120)
	for k in range(count):
		a = 2 * math.pi * k / count
		o = side * math.cos(a) + s2 * math.sin(a)

		def under(f):  # a point just inside the hollow underside, f = 0 (stem) .. 1 (lip)
			return top + capdir * cr * (-0.01 - 0.12 * f) + o * cr * (0.3 + 0.52 * f)
		gills.append(ck.loft(f"{name}_gill{k}", [(under(0.0 if k % 2 == 0 else 0.3), 0.0028, cr * 0.04), (under(0.55), 0.0028, cr * 0.06),
			(under(0.92), 0.0025, cr * 0.03)], grey(), sides=4, subsurf=0, up=capdir, caps=(True, True)))
	bites = []
	for k in range(1 if cr < 0.08 else 2):
		a = r.uniform(0, 2 * math.pi)
		o = side * math.cos(a) + s2 * math.sin(a)
		bites.append((top + capdir * cr * (-0.02) + o * cr * 1.05, top, cr * r.uniform(0.16, 0.24)))
	return stem, cap, gills, bites


def build_glowcap(seed=21):
	r = random.Random(seed)
	mound = [lump("mound", (0, 0, -0.035), (0.21, 0.17, 0.07), seed, jitter=0.2, detail=4)]
	for k in range(5):
		a = k * 1.3
		mound.append(lump(f"lump{k}", (math.cos(a) * 0.15, math.sin(a) * 0.12, -0.01), (0.06, 0.05, 0.035), seed + 1 + k, jitter=0.3, detail=2))
	stems, caps, gills, bites = [], [], [], []
	for k, (x, y, lean, h, cr) in enumerate(((0.0, 0.0, (0.05, 0.0), 0.36, 0.15), (0.12, 0.05, (0.45, 0.2), 0.25, 0.11),
			(-0.1, 0.07, (-0.4, 0.3), 0.17, 0.08), (0.05, -0.11, (0.15, -0.5), 0.1, 0.05), (-0.13, -0.06, (-0.5, -0.3), 0.07, 0.035))):
		s, c, g, b = mushroom(f"m{k}", Vector((x, y, 0.0)), (lean[0], lean[1], 1.0), h, cr, seed + 10 * k)
		stems += s
		caps += c
		gills += g
		bites += b
	for k in range(6):  # mycelium threads over the mound, joining the feet
		a = r.uniform(0, 2 * math.pi)
		p0 = Vector((math.cos(a) * 0.04, math.sin(a) * 0.04, 0.005))
		p1 = Vector((math.cos(a + 0.4) * 0.17, math.sin(a + 0.4) * 0.14, -0.015))
		mound.append(tube(f"thread{k}", smooth_path([p0, (p0 + p1) / 2 + Vector((0, 0, 0.012)), p1], 7), [0.008] * 7, sides=6, seed=seed + 40 + k))
	soil = cs.melt(mound, voxel=0.004, smooth=3, name="soil")
	carve(soil, lambda p, n: 0.004 * noise.fractal(p * 30, 0.6, 2.2, 4) - 0.004 * max(0.0, noise.noise(p * 14) - 0.3))
	stem = cs.melt(stems, voxel=0.0035, smooth=4, name="stem")
	carve(stem, lambda p, n: -0.0015 * abs(noise.noise(Vector((p.x * 120, p.y * 120, p.z * 12)))) + 0.0008 * noise.noise(p * 80), soften=1)
	cap = cs.melt(caps, voxel=0.003, smooth=3, name="glow_cap")
	bite(cap, bites)
	carve(cap, lambda p, n: 0.0015 * noise.fractal(p * 40, 0.5, 2.0, 3) - 0.0012 * max(0.0, noise.noise(p * 25) - 0.4), soften=1)
	gl = join(gills, "gills")
	bite(gl, bites)
	return [
		(soil, 700, 256, lambda n: cs.paint_material(n, (0.33, 0.25, 0.18), (0.13, 0.09, 0.06), (0.52, 0.43, 0.32), moss=(0.85, 0.82, 0.72), moss_amount=0.25, grime=0.3, seed=5.0)),
		(stem, 1100, 512, lambda n: cs.paint_material(n, (0.82, 0.78, 0.7), (0.42, 0.37, 0.3), (0.95, 0.93, 0.87), strokes=0.1, grime=0.35, scratches=0.3, edge=0.3, seed=6.0)),
		(cap, 1900, 512, lambda n: cs.paint_material(n, (0.8, 0.82, 0.86), (0.3, 0.32, 0.4), (1.0, 1.0, 1.0), strokes=0.2, grime=0.5, scratches=0.5, scratch_width=1.4, edge=0.7, key=0.3, seed=7.0)),
		(gl, 900, 256, lambda n: cs.paint_material(n, (0.72, 0.66, 0.6), (0.3, 0.26, 0.22), (0.86, 0.8, 0.74), grime=0.2, key=0.15, seed=8.0)),
	]


# ---------------------------------------------------------------- the crystal node
def prism(name, base, d, L, rad, seed, broken=False, chips=2):
	"""A six-sided crystal: a straight prism with a faceted point (its six tip faces a little uneven), flat facets,
	corners chipped off, and on some the tip broken away."""
	r = random.Random(seed)
	d = d.normalized()
	side = d.cross(Vector((0, 0, 1)) if abs(d.z) < 0.95 else Vector((1, 0, 0))).normalized()
	s2 = d.cross(side)
	spin = r.uniform(0, 1)
	bm = bmesh.new()
	pts, shoulders = [], []
	shoulder = L * r.uniform(0.68, 0.78)
	for k in range(6):
		a = 2 * math.pi * (k + spin) / 6
		rr = rad * r.uniform(0.9, 1.1)
		o = side * math.cos(a) + s2 * math.sin(a)
		pts.append(base + o * rr * 0.92)  # a little narrower at the foot (sunk in the rock)
		sh = base + d * shoulder * r.uniform(0.97, 1.03) + o * rr
		pts.append(sh)
		shoulders.append((sh, o))
	pts.append(base + d * L + (side * r.uniform(-1, 1) + s2 * r.uniform(-1, 1)) * rad * 0.18)
	for p in pts:
		bm.verts.new(p)
	bmesh.ops.convex_hull(bm, input=bm.verts)

	def cut(co, no):
		geom = bm.verts[:] + bm.edges[:] + bm.faces[:]
		res = bmesh.ops.bisect_plane(bm, geom=geom, plane_co=co, plane_no=no, clear_outer=True)
		edges = [e for e in res["geom_cut"] if isinstance(e, bmesh.types.BMEdge)]
		if edges:
			bmesh.ops.holes_fill(bm, edges=edges)
	if broken:  # the tip snapped off at an angle
		cut(base + d * (shoulder + (L - shoulder) * r.uniform(0.15, 0.45)), (d + side * r.uniform(0.3, 0.7)).normalized())
	for k in r.sample(range(6), chips):  # chipped corners: a flat bite off a shoulder or an edge further down
		sh, o = shoulders[k]
		down = r.uniform(0.0, 0.5)
		p = sh - d * shoulder * down
		no = (o * 1.0 + d * r.uniform(-0.4, 0.6) + side * r.uniform(-0.3, 0.3)).normalized()
		cut(p - o * rad * r.uniform(0.35, 0.55), no)
	me = bpy.data.meshes.new(name)
	bm.to_mesh(me)
	bm.free()
	o = bpy.data.objects.new(name, me)
	bpy.context.scene.collection.objects.link(o)
	o.data.materials.append(grey())
	bv = o.modifiers.new("bevel", "BEVEL")  # a narrow flat cut along every edge: catches the light as a hard bright line
	bv.width = min(0.007, rad * 0.09)
	bv.segments = 1
	cs._apply_all(o)
	return o


def build_crystal(seed=31):
	r = random.Random(seed)
	rock = [lump("matrix", (0, 0, -0.01), (0.22, 0.18, 0.1), seed, jitter=0.28, detail=4)]
	for k in range(4):
		a = k * 1.6 + 0.3
		rock.append(lump(f"chunk{k}", (math.cos(a) * 0.15, math.sin(a) * 0.12, 0.0), (0.08, 0.07, 0.06), seed + 1 + k, jitter=0.3, detail=3))
	crystals = []
	# a node: six crystals packed together, feet close, fanning out a little
	spec = [(0.0, 0.0, (0.05, 0.02, 1), 0.72, 0.085, False, 3), (0.075, 0.04, (0.45, 0.25, 1), 0.52, 0.068, False, 2),
		(-0.07, 0.035, (-0.5, 0.2, 1), 0.46, 0.064, True, 2), (0.02, -0.075, (0.12, -0.55, 1), 0.42, 0.06, False, 2),
		(-0.055, -0.05, (-0.4, -0.45, 1), 0.33, 0.052, True, 1), (0.08, -0.04, (0.7, -0.3, 1), 0.28, 0.048, False, 2)]
	for k, (x, y, d, L, rad, broken, chips) in enumerate(spec):
		crystals.append(prism(f"crystal{k}", Vector((x, y, 0.02)), Vector(d), L, rad, seed + 10 + k, broken, chips))
	for k in range(3):  # a few small shards beside the node
		a = r.uniform(0, 2 * math.pi)
		p = Vector((math.cos(a) * 0.16, math.sin(a) * 0.13, 0.0))
		dd = Vector((math.cos(a), math.sin(a), 0)) * r.uniform(0.6, 1.0) + Vector((0, 0, 1))
		crystals.append(prism(f"shard{k}", p, dd, r.uniform(0.08, 0.12), r.uniform(0.016, 0.022), seed + 30 + k, chips=1))
	stone = cs.melt(rock, voxel=0.004, smooth=3, name="rock")
	cs.carve_stone(stone, seed=seed, grain=0.002, crack=0.004, chips=0.012)
	glow = join(crystals, "glow_crystal")
	return [
		(stone, 2500, 512, lambda n: cs.paint_material(n, (0.45, 0.43, 0.4), (0.18, 0.17, 0.16), (0.68, 0.65, 0.6), moss=(0.36, 0.43, 0.2), moss_amount=0.2,
			scratches=1.0, scratch_width=1.6, grime=0.35, edge=0.55, seed=9.0)),
		(glow, None, 512, lambda n: cs.glow_paint(n, (0.97, 0.99, 1.0), (0.42, 0.46, 0.52), lines=0.4, cells=9.0, facets=0.45, cloud=0.45, bubbles=0.6, creases=0.8,
			speck=(1.0, 1.0, 1.0), crease_col=(1.0, 1.0, 1.0))),
	]


# ---------------------------------------------------------------- the giant mushroom
def build_giant(seed=41, H=4.0):
	r = random.Random(seed)
	path = smooth_path([(0, 0, -0.1), (0.12, 0.05, H * 0.35), (-0.05, -0.04, H * 0.7), (0.06, 0.02, H)], 22)
	rad = [0.33 * (1.0 + 0.55 * max(0.0, 1 - i / 4) ** 2) * (1 - 0.22 * i / 21) * (1 + 0.03 * math.sin(i * 2.1)) for i in range(22)]
	stalk = [tube("stalk", path, rad, sides=20, seed=seed, wobble=0.03)]
	for k in range(6):  # root buttresses spreading over the ground
		a = k * 2 * math.pi / 6 + r.uniform(-0.3, 0.3)
		o = Vector((math.cos(a), math.sin(a), 0))
		ln = r.uniform(0.7, 1.1)
		ctrl = [o * 0.15 + Vector((0, 0, 0.8)), o * 0.42 + Vector((0, 0, 0.25)), o * ln * 0.8 + Vector((0, 0, 0.0)), o * (ln + 0.15) + Vector((0, 0, -0.06))]
		p = smooth_path(ctrl, 10)
		stalk.append(ck.loft(f"buttress{k}", [(q, 0.17 * (1 - i / 9) ** 0.8 + 0.035, 0.26 * (1 - i / 9) ** 0.8 + 0.03) for i, q in enumerate(p)],
			grey(), sides=10, subsurf=0, wobble=0.05, seed=seed + k, up=Vector((0, 0, 1))))
	ps = path[16]  # a ragged skirt hanging from the stalk under the cap
	stalk.append(ck.loft("skirt", [(ps + Vector((0, 0, 0.04)), 0.27, 0.27), (ps, 0.42, 0.42), (ps - Vector((0, 0, 0.16)), 0.52, 0.52),
		(ps - Vector((0, 0, 0.22)), 0.47, 0.47), (ps - Vector((0, 0, 0.12)), 0.3, 0.3)], grey(), sides=26, subsurf=1, wobble=0.1, seed=seed + 9))
	top = path[-1]
	cr = 1.55
	tilt = Vector((0.12, -0.06, 1)).normalized()
	side = tilt.cross(Vector((1, 0, 0))).normalized()
	s2 = tilt.cross(side)
	prof = [(-0.08, 0.2), (-0.13, 0.55), (-0.2, 0.86), (-0.22, 0.97), (-0.15, 1.03), (-0.04, 1.02), (0.1, 0.92), (0.24, 0.74), (0.36, 0.48), (0.43, 0.2), (0.45, 0.04)]
	cap = ck.loft("cap", [(top + tilt * cr * h, cr * w, cr * w) for h, w in prof], grey(), sides=56, subsurf=1, wobble=0.0, seed=seed, up=side)
	cs._apply_all(cap)
	for v in cap.data.vertices:  # wavy rim: 7 lobes up and down
		rel = v.co - top
		hz = rel.dot(tilt)
		flat = rel - tilt * hz
		ang = math.atan2(flat.dot(s2), flat.dot(side))
		edge = min(1.0, flat.length / cr) ** 1.6
		v.co += tilt * cr * 0.09 * edge * math.sin(7 * ang + seed) + flat.normalized() * cr * 0.03 * edge * math.sin(3 * ang)
	caps = [cap]
	for k in range(70):  # warts / scales on top, bigger in the middle, small ones toward the rim
		a, b = r.uniform(0, 2 * math.pi), r.uniform(0.0, 0.85) ** 0.8
		p = top + tilt * cr * (0.41 - 0.42 * b * b) + (side * math.cos(a) + s2 * math.sin(a)) * cr * b * 0.95
		w = r.uniform(0.05, 0.13) * (1.2 - 0.6 * b)
		caps.append(lump(f"wart{k}", tuple(p), (w, w * 0.9, w * 0.45), seed + 20 + k, jitter=0.3, detail=2))
	gills = []
	for k in range(90):
		a = 2 * math.pi * k / 90
		o = side * math.cos(a) + s2 * math.sin(a)

		def under(f):
			return top + tilt * cr * (-0.06 - 0.14 * f) + o * cr * (0.22 + 0.62 * f)
		gills.append(ck.loft(f"gill{k}", [(under(0.0 if k % 3 == 0 else 0.3), 0.012, 0.08), (under(0.55), 0.012, 0.13),
			(under(0.93), 0.01, 0.05)], grey(), sides=4, subsurf=0, up=tilt))
	bites = []
	for k in range(3):
		a = r.uniform(0, 2 * math.pi)
		o = side * math.cos(a) + s2 * math.sin(a)
		bites.append((top - tilt * cr * 0.1 + o * cr * 1.04, top, r.uniform(0.2, 0.32)))
	stem = cs.melt(stalk, voxel=0.018, smooth=4, name="stem")
	def stalk_fn(p, n):  # long fibres up the stalk (big ridges, fine streaks), flaky patches, grain (owner: "a bit of texture")
		ridges = -0.018 * abs(noise.noise(Vector((p.x * 18 + seed, p.y * 18, p.z * 1.2)))) ** 0.6
		streaks = -0.005 * abs(noise.noise(Vector((p.x * 75, p.y * 75, p.z * 4))))
		flakes = -0.007 if noise.noise(p * 5 + Vector((seed, 2, 7))) > 0.45 else 0.0
		return ridges + streaks + flakes + 0.003 * noise.fractal(p * 30, 0.5, 2.0, 3)
	carve(stem, stalk_fn, soften=1)
	capm = cs.melt(caps, voxel=0.018, smooth=3, name="glow_cap")
	bite(capm, bites)
	def cap_fn(p, n):  # the cap's skin cracked into patches (like an old mushroom), lumps, pits and fine grain
		cracks = -0.014 * cs._crack(p, 2.4) * (1.0 if n.z > -0.2 else 0.0)  # cracks on top only, not in the gills
		pits = -0.006 * max(0.0, noise.noise(p * 9 + Vector((seed, 0, 0))) - 0.4)
		return 0.008 * noise.fractal(p * 6, 0.5, 2.0, 3) + 0.003 * noise.fractal(p * 40, 0.5, 2.0, 3) + cracks + pits
	carve(capm, cap_fn, soften=1)
	gl = join(gills, "gills")
	bite(gl, bites)
	return [
		(stem, 6000, 2048, lambda n: cs.paint_material(n, (0.8, 0.75, 0.66), (0.36, 0.3, 0.24), (0.95, 0.92, 0.85), strokes=0.22, grime=0.55, scratches=0.6, scratch_width=2.0, edge=0.5,
			moss=(0.5, 0.36, 0.55), moss_amount=0.25, seed=10.0)),
		(capm, 6000, 2048, lambda n: cs.paint_material(n, (0.5, 0.3, 0.58), (0.16, 0.07, 0.22), (0.86, 0.66, 0.94), strokes=0.25, grime=0.5, scratches=0.6, scratch_width=2.0, edge=0.7,
			moss=(0.88, 0.8, 0.9), moss_amount=0.3, top_light=0.25, seed=11.0)),
		(gl, 1500, 512, lambda n: cs.paint_material(n, (0.7, 0.58, 0.68), (0.28, 0.2, 0.27), (0.86, 0.76, 0.84), grime=0.2, key=0.15, seed=12.0)),
	]


# ---------------------------------------------------------------- paint, bake, export, pictures
def finish(model, parts):
	"""Each part: a light game copy (or the part itself, if it's already light, like the flat crystals), its paint
	baked from the dense sculpt as a colour + normal picture. Returns the game objects."""
	lows = []
	for high, tris, tex, paint in parts:
		part = high.name
		mname = f"{part}_{model}"
		if tris is None:  # already light (flat facets): keep it, a copy is the paint source
			cs.uv_only(high)
			cs._select_only(high)
			bpy.ops.object.duplicate()
			src = bpy.context.view_layer.objects.active
			low = high
			for p in low.data.polygons:
				p.use_smooth = False
		else:
			src = high
			low = cs.game_copy(high, tris, part + "_low")
		if GREY:
			if src is not low:
				bpy.data.objects.remove(src)
			low.name = part
			lows.append(low)
			continue
		src.data.materials.clear()
		src.data.materials.append(paint(mname + "_paint"))
		cs.bake(src, low, tex_size=tex, name=mname)
		bpy.data.objects.remove(src)
		low.name = part
		lows.append(low)
	return lows


def pictures(name, objs):
	scene = bpy.context.scene
	engines = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
	scene.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in engines else "BLENDER_EEVEE"
	scene.render.resolution_x = scene.render.resolution_y = 720
	scene.view_settings.view_transform = "Standard"
	w = bpy.data.worlds.new("w")
	w.use_nodes = True
	w.node_tree.nodes["Background"].inputs[0].default_value = (0.2, 0.19, 0.18, 1)
	w.node_tree.nodes["Background"].inputs[1].default_value = 1.0
	scene.world = w
	sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
	sun.data.energy = 3.5
	sun.rotation_euler = (math.radians(45), math.radians(15), math.radians(40))
	scene.collection.objects.link(sun)
	cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
	cam.data.lens = 60
	scene.collection.objects.link(cam)
	scene.camera = cam
	vs = [o.matrix_world @ v.co for o in objs for v in o.data.vertices]
	lo = Vector((min(v.x for v in vs), min(v.y for v in vs), min(v.z for v in vs)))
	hi = Vector((max(v.x for v in vs), max(v.y for v in vs), max(v.z for v in vs)))
	c, size = (lo + hi) / 2, max(hi - lo)
	for o in objs:  # the pictures show glowing parts tinted and lit, as the game does (the .glb keeps them pale)
		for m in o.data.materials:
			if m and m.name.startswith("glow_") and name in TINT:
				nt = m.node_tree
				b = nt.nodes["Principled BSDF"]
				tex = b.inputs["Base Color"].links[0].from_node
				mul = nt.nodes.new("ShaderNodeMix")
				mul.data_type, mul.blend_type = "RGBA", "MULTIPLY"
				mul.inputs[0].default_value = 1.0
				mul.inputs[7].default_value = (*cs.lin(TINT[name]), 1)
				nt.links.new(tex.outputs["Color"], mul.inputs[6])
				nt.links.new(mul.outputs[2], b.inputs["Base Color"])
				nt.links.new(mul.outputs[2], b.inputs["Emission Color"])
				b.inputs["Emission Strength"].default_value = 0.3
	for tag, off in (("a", Vector((0.9, -1.7, 0.55))), ("b", Vector((-1.2, -0.9, 0.9)))):
		cam.location = c + off.normalized() * size * 1.9
		cam.rotation_euler = (c - cam.location).to_track_quat("-Z", "Y").to_euler()
		scene.render.filepath = str(OUT / f"{name}_{tag}.png")
		bpy.ops.render.render(write_still=True)


TINT = {"crystal": (0.35, 0.75, 1.0), "glowcap": (0.25, 0.95, 0.85), "giant": (1.0, 1.0, 1.0)}  # the game's colours (glow_placer KINDS)
BUILDS = {"root": build_root, "root_b": lambda: build_root(12, "b"), "root_c": lambda: build_root(13, "c"), "glowcap": build_glowcap, "crystal": build_crystal, "giant": build_giant}

def export(name, objs):
	"""Writes <name>.glb (pictures fixed for Godot) and returns its triangle count."""
	tris = sum(len(p.vertices) - 2 for o in objs for p in o.data.polygons)
	bpy.ops.object.select_all(action="DESELECT")
	for o in objs:
		o.select_set(True)
	OUT.mkdir(parents=True, exist_ok=True)
	path = str(OUT / f"{name}.glb")
	bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_yup=True,
		export_image_format="JPEG", export_image_quality=88)
	fixed = glb_jpeg_fix.fix(path)
	print(f"PLANT_DONE {name} {tris} triangles, parts {[o.name for o in objs]}, {fixed} pictures fixed for Godot")
	return tris


if __name__ == "__main__":  # (cave_cover.py imports the helpers above without building these)
	for name, fn in BUILDS.items():
		if ONLY and name not in ONLY:
			continue
		kit.reset()
		ck.reset()
		objs = finish(name, fn())
		export(name, objs)
		pictures(name, objs)
