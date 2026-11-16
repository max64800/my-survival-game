# Cave plants and crystals, hand-built and sculpted the Rock Beetle way (Claude 2, Nov 16, 2026; owner: "roots,
# mushrooms, crystals by hand to match the beetle complexity"). MODEL-RULES Rule 1: every shape comes from this script.
#
#   blender --background --factory-startup --python builds/cave_plants.py -- <out_dir> [only=root,glowcap,...] [grey=1]
#
# Writes <out_dir>/<name>.glb (a light game copy) and <out_dir>/<name>_a.png / _b.png (grey pictures).
#
# The models (Blender: +Z up, origin where it grows from):
#   root      a hanging root (F91): a soil clump against the ceiling, a gnarled trunk of twisted strands that fuse and
#             thin out, knots, side roots forking and curling down, hair roots, a faintly glowing tip. Hangs DOWN
#             from the origin (z 0 to -1.6 m).
#   glowcap   a cluster of glowing mushrooms (4 sizes) on a mound of soil and mycelium: bulbous feet, curved stems,
#             domed caps with a curled lip, gills underneath, warts on top.
#   crystal   a crystal cluster on a chunk of rock: six-sided prisms with real faceted points (some chipped),
#             fanning out, small shards round the foot.
#   giant     a giant mushroom (~4 m, Fungal Jungle wood): a fibrous stalk with root buttresses and a ragged skirt,
#             a wide wavy cap with warts on top and gills underneath.
#
# Parts are named by what they will be painted as: bark, soil, rock, stem, gills, and glow_* for anything that glows.
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
import kit  # noqa: E402

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = Path(ARGS[0]) if ARGS else Path(".")
OPTS = dict(a.split("=", 1) for a in ARGS[1:] if "=" in a)
ONLY = OPTS.get("only", "").split(",") if OPTS.get("only") else None


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


def thin(o, tris):
	"""The light game copy: about `tris` triangles."""
	now = sum(len(p.vertices) - 2 for p in o.data.polygons)
	if now > tris:
		d = o.modifiers.new("decimate", "DECIMATE")
		d.ratio = tris / now
		cs._apply_all(o)
	for p in o.data.polygons:
		p.use_smooth = True
	return o


def join(objs, name):
	bpy.ops.object.select_all(action="DESELECT")
	for o in objs:
		cs._apply_all(o)
		o.select_set(True)
	bpy.context.view_layer.objects.active = objs[0]
	if len(objs) > 1:
		bpy.ops.object.join()
	o = bpy.context.view_layer.objects.active
	o.name = name
	return o


# ---------------------------------------------------------------- the hanging root
def build_root(seed=11, L=1.6):
	r = random.Random(seed)
	# The trunk: three strands twisting round each other (like an old vine), fused into one gnarled trunk by the melt,
	# getting thinner as they go down, then one tapering tail.
	strands = []
	for s in range(3):
		ph = s * 2 * math.pi / 3
		pts, rad = [], []
		for i in range(26):
			t = i / 25
			z = 0.04 - L * 0.62 * t
			spin = ph + t * 2.6 * math.pi  # a bit more than one full turn
			wr = 0.07 * (1 - 0.7 * t)
			drift = Vector((0.05 * math.sin(t * 5.0 + seed), 0.04 * math.cos(t * 4.0 + seed), 0))
			pts.append(Vector((math.cos(spin) * wr, math.sin(spin) * wr, z)) + drift)
			rad.append(0.085 * (1 - 0.5 * t) + 0.01 * math.sin(i * 1.7 + s))
		strands.append(tube(f"strand{s}", pts, rad, sides=10, seed=seed + s, up=Vector((1, 0, 0))))
	# The tail below the twist: one root thinning to a point, wandering a little.
	z0 = 0.04 - L * 0.62
	end = Vector((0.05 * math.sin(5.0 + seed), 0.04 * math.cos(4.0 + seed), z0))
	tail_ctrl = [end + Vector((0, 0, 0.06)), end, end + Vector((0.05, -0.03, -L * 0.12)), end + Vector((-0.02, 0.04, -L * 0.26)),
		end + Vector((0.03, 0.02, -L * 0.36))]
	tail = smooth_path(tail_ctrl, 18)
	trad = [0.065 * (1 - i / 17) ** 0.9 + 0.008 for i in range(18)]
	parts = strands + [tube("tail", tail[:-3], trad[:-3], sides=10, seed=seed + 7)]
	tip_pts, tip_rad = tail[-5:], trad[-5:]
	# Knots (burls): lumps where old side roots broke off.
	for k, t in enumerate((0.18, 0.37, 0.55)):
		z = 0.04 - L * 0.62 * t
		a = r.uniform(0, 2 * math.pi)
		w = 0.07 * (1 - 0.7 * t) + 0.035
		parts.append(lump(f"knot{k}", (math.cos(a) * w, math.sin(a) * w, z), (0.04, 0.04, 0.07), seed + 20 + k, jitter=0.3, detail=2))
	# Side roots: fork off, reach out, then curl down (each with a smaller fork of its own).
	fine = []
	for k, (t, ln, rr) in enumerate(((0.16, 0.6, 0.045), (0.38, 0.5, 0.038), (0.58, 0.4, 0.03), (0.27, 0.34, 0.026))):
		z = 0.04 - L * 0.62 * t
		a = r.uniform(0, 2 * math.pi) if k else 0.6
		out = Vector((math.cos(a), math.sin(a), 0))
		start = out * 0.03 + Vector((0, 0, z))
		# real side roots leave at a shallow angle and hang down along the trunk (sticking out sideways they read as arms)
		ctrl = [start, start + out * ln * 0.2 + Vector((0, 0, -ln * 0.2)), start + out * ln * 0.32 + Vector((0, 0, -ln * 0.55)),
			start + out * ln * 0.3 + Vector((0.03, 0.02, -ln))]
		p = smooth_path(ctrl, 12)
		rad = [rr * (1 - i / 11) ** 0.8 + 0.006 for i in range(12)]
		parts.append(tube(f"side{k}", p, rad, sides=8, seed=seed + 30 + k))
		# a smaller fork from its middle
		m = p[5]
		side = out.cross(Vector((0, 0, 1)))
		ctrl2 = [m, m + side * 0.08 * (1 if k % 2 else -1) + Vector((0, 0, -0.04)), m + side * 0.12 * (1 if k % 2 else -1) + Vector((0, 0, -0.18))]
		fine.append(tube(f"fork{k}", smooth_path(ctrl2, 8), [rr * 0.5 * (1 - i / 7) + 0.004 for i in range(8)], sides=6, seed=seed + 40 + k))
	# The soil clump it hangs from: lumpy earth pressed against the ceiling, pebbles stuck in it.
	soil = [lump("clump", (0, 0, 0.0), (0.2, 0.18, 0.11), seed + 50, jitter=0.22, detail=4),
		lump("clump_drip", (0.02, -0.01, -0.09), (0.12, 0.11, 0.1), seed + 51, jitter=0.25, detail=4)]
	for k in range(4):
		soil.append(lump(f"clod{k}", (r.uniform(-0.15, 0.15), r.uniform(-0.13, 0.13), r.uniform(-0.03, 0.0)),
			(r.uniform(0.05, 0.08),) * 2 + (0.05,), seed + 60 + k, jitter=0.3, detail=2))
	pebbles = [lump(f"pebble{k}", (math.cos(k * 2.1) * 0.15, math.sin(k * 2.1) * 0.13, -0.03 + 0.01 * k),
		(0.03 + 0.008 * k, 0.026, 0.022), seed + 70 + k, jitter=0.12, detail=2) for k in range(4)]
	# Hair roots: thin strands from the clump and the tail (too thin to melt: kept as they are).
	for k in range(9):
		a = k * 0.7 + r.uniform(0, 0.4)
		o = Vector((math.cos(a), math.sin(a), 0))
		base = o * r.uniform(0.1, 0.17) + Vector((0, 0, -0.03))
		ctrl = [base, base + o * 0.05 + Vector((0, 0, -0.06)), base + o * 0.07 + Vector((r.uniform(-.03, .03), r.uniform(-.03, .03), -r.uniform(0.12, 0.22)))]
		fine.append(tube(f"hair{k}", smooth_path(ctrl, 7), [0.006 - 0.0006 * i for i in range(7)], sides=5, seed=seed + 80 + k))

	bark = cs.melt(parts, voxel=0.0045, smooth=5, name="bark")

	def bark_fn(p, n):  # bark: long furrows running down the root, a little cross-cracking, fine grain
		q = Vector((p.x * 38 + seed, p.y * 38, p.z * 5))
		furrow = abs(noise.noise(q)) ** 0.6
		cross = max(0.0, noise.noise(Vector((p.x * 9, p.y * 9, p.z * 30))) - 0.45)
		return -0.0045 * (1 - furrow) - 0.004 * cross + 0.0012 * noise.fractal(p * 90, 0.5, 2.0, 3)
	carve(bark, bark_fn, soften=1)
	earth = cs.melt(soil, voxel=0.006, smooth=3, name="soil")
	carve(earth, lambda p, n: 0.007 * noise.fractal(p * 25, 0.6, 2.2, 4) - 0.006 * max(0.0, noise.noise(p * 11) - 0.3), soften=1)
	stones = join(pebbles, "rock")
	carve(stones, lambda p, n: 0.002 * noise.noise(p * 60), soften=0)
	hairs = join(fine, "bark_fine")
	tip = tube("glow_tip", [tip_pts[0] + (tip_pts[0] - tip_pts[1]) * 0.6] + tip_pts, [tip_rad[0] * 1.02] + [x * 1.02 for x in tip_rad], sides=8, wobble=0.02, seed=seed + 90)
	return [thin(bark, 9000), thin(earth, 2500), thin(stones, 500), thin(hairs, 2500), thin(join([tip], "glow_tip"), 300)]


# ---------------------------------------------------------------- the glowing mushroom cluster
def cap_rings(top, n, cr, seed, lobes=5, wave=0.06, flat=1.0):
	"""Rings for a domed cap with a lip curling under, its rim a little wavy."""
	prof = [(-0.02, 0.3), (-0.08, 0.62), (-0.15, 0.86), (-0.17, 0.96), (-0.1, 1.04), (0.05, 1.04), (0.22, 0.93), (0.4, 0.72), (0.53, 0.44), (0.6, 0.14)]
	r = random.Random(seed)
	return [(top + n * cr * h * flat, cr * w, cr * w) for h, w in prof], r


def mushroom(name, foot, n, height, cr, seed, bend=0.15):
	"""One mushroom: a bulbous foot, a curved stem, a cap with a curled lip, gills underneath, warts on top."""
	r = random.Random(seed)
	n = Vector(n).normalized()
	side = n.cross(Vector((0, 0, 1)) if abs(n.z) < 0.95 else Vector((1, 0, 0))).normalized()
	top = foot + n * height + side * height * bend * r.uniform(-1, 1)
	mid = (foot + top) / 2 + side * height * bend * 0.8
	path = smooth_path([foot - n * 0.02, mid, top], 12)
	sr = cr * 0.24
	rad = [sr * (1.55 - 0.65 * min(1, i / 4)) * (1 + 0.04 * math.sin(i * 1.9)) for i in range(12)]
	stem = [tube(f"{name}_stem", path, rad, sides=12, seed=seed)]
	# a ring (skirt) under the cap on the bigger ones
	if cr > 0.09:
		p = path[8]
		stem.append(ck.loft(f"{name}_ring", [(p + n * 0.01, sr * 0.9, sr * 0.9), (p, sr * 1.25, sr * 1.25), (p - n * 0.025, sr * 1.55, sr * 1.55),
			(p - n * 0.035, sr * 1.0, sr * 1.0)], grey(), sides=14, subsurf=0, wobble=0.08, seed=seed + 1))
	capdir = (n * 0.8 + (top - mid).normalized() * 0.2).normalized()
	rings, _ = cap_rings(top, capdir, cr, seed)
	cap = [ck.loft(f"{name}_cap", rings, grey(), sides=28, subsurf=1, wobble=0.035, seed=seed + 2, up=side)]
	# warts on top (pale spots in the paint later)
	for k in range(int(5 + cr * 40)):
		a, b = r.uniform(0, 2 * math.pi), r.uniform(0.15, 0.85)
		s2 = capdir.cross(side)
		d = (capdir * math.cos(b * 1.2) + (side * math.cos(a) + s2 * math.sin(a)) * math.sin(b * 1.2)).normalized()
		# a point on the dome: the profile's height and width at this angle, roughly
		p = top + capdir * cr * (0.61 * math.cos(b * 1.4) - 0.02) + (d - capdir * d.dot(capdir)).normalized() * cr * min(1.0, 1.05 * math.sin(b * 1.45))
		w = cr * r.uniform(0.07, 0.12)
		cap.append(lump(f"{name}_wart{k}", tuple(p), (w, w, w * 0.6), seed + 10 + k, jitter=0.25, detail=2))
	# gills: thin radial fins under the cap, from the stem to the lip
	gills = []
	s2 = capdir.cross(side)
	count = int(26 + cr * 120)
	for k in range(count):
		a = 2 * math.pi * k / count
		o = side * math.cos(a) + s2 * math.sin(a)
		inner = sr * 1.0 if k % 2 == 0 else cr * 0.45
		def under(f):  # a point just inside the hollow underside, f = 0 (stem) .. 1 (lip)
			return top + capdir * cr * (-0.01 - 0.12 * f) + o * cr * (0.3 + 0.52 * f)
		gills.append(ck.loft(f"{name}_gill{k}", [(under(0.0 if inner < cr * 0.3 else 0.3), 0.0028, cr * 0.04), (under(0.55), 0.0028, cr * 0.06),
			(under(0.92), 0.0025, cr * 0.03)], grey(), sides=4, subsurf=0, up=capdir, caps=(True, True)))
	return stem, cap, gills


def build_glowcap(seed=21):
	r = random.Random(seed)
	mound = [lump("mound", (0, 0, -0.035), (0.21, 0.17, 0.07), seed, jitter=0.2, detail=4)]
	for k in range(5):
		a = k * 1.3
		mound.append(lump(f"lump{k}", (math.cos(a) * 0.15, math.sin(a) * 0.12, -0.01), (0.06, 0.05, 0.035), seed + 1 + k, jitter=0.3, detail=2))
	stems, caps, gills = [], [], []
	for k, (x, y, lean, h, cr) in enumerate(((0.0, 0.0, (0.05, 0.0), 0.36, 0.15), (0.12, 0.05, (0.45, 0.2), 0.25, 0.11),
			(-0.1, 0.07, (-0.4, 0.3), 0.17, 0.08), (0.05, -0.11, (0.15, -0.5), 0.1, 0.05), (-0.13, -0.06, (-0.5, -0.3), 0.07, 0.035))):
		s, c, g = mushroom(f"m{k}", Vector((x, y, 0.0)), (lean[0], lean[1], 1.0), h, cr, seed + 10 * k)
		stems += s
		caps += c
		gills += g
	# mycelium threads over the mound, joining the feet
	for k in range(6):
		a = r.uniform(0, 2 * math.pi)
		p0 = Vector((math.cos(a) * 0.04, math.sin(a) * 0.04, 0.005))
		p1 = Vector((math.cos(a + 0.4) * 0.17, math.sin(a + 0.4) * 0.14, -0.015))
		mound.append(tube(f"thread{k}", smooth_path([p0, (p0 + p1) / 2 + Vector((0, 0, 0.012)), p1], 7), [0.008] * 7, sides=6, seed=seed + 40 + k))
	soil = cs.melt(mound, voxel=0.004, smooth=3, name="soil")
	carve(soil, lambda p, n: 0.004 * noise.fractal(p * 30, 0.6, 2.2, 4) - 0.004 * max(0.0, noise.noise(p * 14) - 0.3))
	stem = cs.melt(stems, voxel=0.0035, smooth=4, name="stem")
	carve(stem, lambda p, n: -0.0015 * abs(noise.noise(Vector((p.x * 120, p.y * 120, p.z * 12)))) + 0.0008 * noise.noise(p * 80), soften=1)
	cap = cs.melt(caps, voxel=0.003, smooth=3, name="glow_cap")
	carve(cap, lambda p, n: 0.0015 * noise.fractal(p * 40, 0.5, 2.0, 3), soften=1)
	return [thin(soil, 2500), thin(stem, 3500), thin(cap, 6000), thin(join(gills, "gills"), 4000)]


# ---------------------------------------------------------------- the crystal cluster
def prism(name, base, d, L, rad, seed, chip=False):
	"""A six-sided crystal: a straight prism with a faceted point (its six tip faces a little uneven), flat facets."""
	r = random.Random(seed)
	d = d.normalized()
	side = d.cross(Vector((0, 0, 1)) if abs(d.z) < 0.95 else Vector((1, 0, 0))).normalized()
	s2 = d.cross(side)
	spin = r.uniform(0, 1)
	bm = bmesh.new()
	pts = []
	shoulder = L * r.uniform(0.68, 0.78)
	for k in range(6):
		a = 2 * math.pi * (k + spin) / 6
		rr = rad * r.uniform(0.9, 1.1)
		o = side * math.cos(a) + s2 * math.sin(a)
		pts.append(base + o * rr * 0.92)  # a little narrower at the foot (sunk in the rock)
		pts.append(base + d * shoulder * r.uniform(0.97, 1.03) + o * rr)
	apex = base + d * L + (side * r.uniform(-1, 1) + s2 * r.uniform(-1, 1)) * rad * 0.18
	pts.append(apex)
	for p in pts:
		bm.verts.new(p)
	bmesh.ops.convex_hull(bm, input=bm.verts)
	if chip:  # a broken tip: cut flat at an angle
		cut = base + d * (shoulder + (L - shoulder) * 0.35)
		nrm = (d + side * 0.5).normalized()
		geom = bm.verts[:] + bm.edges[:] + bm.faces[:]
		res = bmesh.ops.bisect_plane(bm, geom=geom, plane_co=cut, plane_no=nrm, clear_outer=True)
		edges = [e for e in res["geom_cut"] if isinstance(e, bmesh.types.BMEdge)]
		bmesh.ops.holes_fill(bm, edges=edges)
	me = bpy.data.meshes.new(name)
	bm.to_mesh(me)
	bm.free()
	o = bpy.data.objects.new(name, me)
	bpy.context.scene.collection.objects.link(o)
	o.data.materials.append(grey())
	bv = o.modifiers.new("bevel", "BEVEL")  # a hair of bevel: the edges catch the light
	bv.width = min(0.004, rad * 0.06)
	bv.segments = 1
	cs._apply_all(o)
	return o


def build_crystal(seed=31):
	r = random.Random(seed)
	rock = [lump("matrix", (0, 0, 0.0), (0.26, 0.2, 0.1), seed, jitter=0.28, detail=4)]
	for k in range(4):
		a = k * 1.6 + 0.3
		rock.append(lump(f"chunk{k}", (math.cos(a) * 0.18, math.sin(a) * 0.14, 0.01), (0.09, 0.08, 0.06), seed + 1 + k, jitter=0.3, detail=3))
	crystals = []
	spec = [(0.0, 0.0, (0.05, 0.02, 1), 0.78, 0.085, False), (0.08, 0.06, (0.5, 0.3, 1), 0.52, 0.062, False),
		(-0.09, 0.03, (-0.55, 0.2, 1), 0.46, 0.058, True), (0.03, -0.09, (0.15, -0.6, 1), 0.4, 0.05, False),
		(-0.05, -0.07, (-0.4, -0.5, 1), 0.3, 0.04, False), (0.14, -0.03, (0.9, -0.1, 1), 0.26, 0.036, True),
		(-0.15, -0.02, (-1.0, -0.2, 0.9), 0.2, 0.03, False), (0.1, 0.12, (0.5, 0.9, 1), 0.18, 0.028, False)]
	for k, (x, y, d, L, rad, chip) in enumerate(spec):
		crystals.append(prism(f"crystal{k}", Vector((x, y, 0.02)), Vector(d), L, rad, seed + 10 + k, chip))
	for k in range(7):  # little shards growing out of the rock round the foot
		a = r.uniform(0, 2 * math.pi)
		p = Vector((math.cos(a) * r.uniform(0.15, 0.24), math.sin(a) * r.uniform(0.12, 0.19), 0.0))
		d = Vector((math.cos(a), math.sin(a), 0)) * r.uniform(0.6, 1.2) + Vector((0, 0, 1))
		crystals.append(prism(f"shard{k}", p, d, r.uniform(0.07, 0.13), r.uniform(0.012, 0.02), seed + 30 + k))
	stone = cs.melt(rock, voxel=0.004, smooth=3, name="rock")
	cs.carve_stone(stone, seed=seed, grain=0.002, crack=0.004, chips=0.012)
	return [thin(stone, 5000), join(crystals, "glow_crystal")]


# ---------------------------------------------------------------- the giant mushroom
def build_giant(seed=41, H=4.0):
	r = random.Random(seed)
	path = smooth_path([(0, 0, -0.1), (0.12, 0.05, H * 0.35), (-0.05, -0.04, H * 0.7), (0.06, 0.02, H)], 22)
	rad = [0.33 * (1.0 + 0.55 * max(0.0, 1 - i / 4) ** 2) * (1 - 0.22 * i / 21) * (1 + 0.03 * math.sin(i * 2.1)) for i in range(22)]
	stalk = [tube("stalk", path, rad, sides=20, seed=seed, wobble=0.03)]
	# root buttresses spreading over the ground
	for k in range(6):
		a = k * 2 * math.pi / 6 + r.uniform(-0.3, 0.3)
		o = Vector((math.cos(a), math.sin(a), 0))
		ln = r.uniform(0.7, 1.1)
		ctrl = [o * 0.15 + Vector((0, 0, 0.8)), o * 0.42 + Vector((0, 0, 0.25)), o * ln * 0.8 + Vector((0, 0, 0.0)), o * (ln + 0.15) + Vector((0, 0, -0.06))]
		p = smooth_path(ctrl, 10)
		stalk.append(ck.loft(f"buttress{k}", [(q, 0.17 * (1 - i / 9) ** 0.8 + 0.035, 0.26 * (1 - i / 9) ** 0.8 + 0.03) for i, q in enumerate(p)],
			grey(), sides=10, subsurf=0, wobble=0.05, seed=seed + k, up=Vector((0, 0, 1))))
	# a ragged skirt hanging from the stalk under the cap
	ps = path[16]
	stalk.append(ck.loft("skirt", [(ps + Vector((0, 0, 0.04)), 0.27, 0.27), (ps, 0.42, 0.42), (ps - Vector((0, 0, 0.16)), 0.52, 0.52),
		(ps - Vector((0, 0, 0.22)), 0.47, 0.47), (ps - Vector((0, 0, 0.12)), 0.3, 0.3)], grey(), sides=26, subsurf=1, wobble=0.1, seed=seed + 9))
	# the cap: wide, a little tilted, its rim wavy (7 lobes), the lip curling under
	top = path[-1]
	cr = 1.55
	tilt = Vector((0.12, -0.06, 1)).normalized()
	side = tilt.cross(Vector((1, 0, 0))).normalized()
	prof = [(-0.08, 0.2), (-0.13, 0.55), (-0.2, 0.86), (-0.22, 0.97), (-0.15, 1.03), (-0.04, 1.02), (0.1, 0.92), (0.24, 0.74), (0.36, 0.48), (0.43, 0.2), (0.45, 0.04)]
	rings = []
	for h, w in prof:
		rings.append((top + tilt * cr * h, cr * w, cr * w))
	cap = ck.loft("cap", rings, grey(), sides=56, subsurf=1, wobble=0.0, seed=seed, up=side)
	cs._apply_all(cap)
	for v in cap.data.vertices:  # wavy rim: the outer rings go up and down in 7 lobes
		rel = v.co - top
		hz = rel.dot(tilt)
		flat = rel - tilt * hz
		ang = math.atan2(flat.dot(tilt.cross(side)), flat.dot(side))
		edge = min(1.0, flat.length / cr) ** 1.6
		v.co += tilt * cr * 0.09 * edge * math.sin(7 * ang + seed) + flat.normalized() * cr * 0.03 * edge * math.sin(3 * ang)
	caps = [cap]
	s2 = tilt.cross(side)
	for k in range(26):  # warts / scales on top
		a, b = r.uniform(0, 2 * math.pi), r.uniform(0.0, 0.8)
		p = top + tilt * cr * (0.41 - 0.42 * b * b) + (side * math.cos(a) + s2 * math.sin(a)) * cr * b * 0.95
		w = r.uniform(0.07, 0.15)
		caps.append(lump(f"wart{k}", tuple(p), (w, w * 0.9, w * 0.45), seed + 20 + k, jitter=0.3, detail=2))
	gills = []
	for k in range(90):
		a = 2 * math.pi * k / 90
		o = side * math.cos(a) + s2 * math.sin(a)
		inner = 0.36 if k % 3 == 0 else (0.7 if k % 3 == 1 else 1.0)
		def under(f):
			return top + tilt * cr * (-0.06 - 0.14 * f) + o * cr * (0.22 + 0.62 * f)
		gills.append(ck.loft(f"gill{k}", [(under(0.0 if k % 3 == 0 else 0.3), 0.012, 0.08), (under(0.55), 0.012, 0.13),
			(under(0.93), 0.01, 0.05)], grey(), sides=4, subsurf=0, up=tilt))
	stem = cs.melt(stalk, voxel=0.018, smooth=4, name="stem")
	carve(stem, lambda p, n: -0.012 * abs(noise.noise(Vector((p.x * 14 + seed, p.y * 14, p.z * 1.6)))) ** 0.7 + 0.004 * noise.fractal(p * 20, 0.5, 2.0, 3), soften=1)
	capm = cs.melt(caps, voxel=0.018, smooth=3, name="glow_cap")
	carve(capm, lambda p, n: 0.008 * noise.fractal(p * 6, 0.5, 2.0, 3) + 0.003 * noise.noise(p * 30), soften=1)
	return [thin(stem, 9000), thin(capm, 9000), thin(join(gills, "gills"), 4000)]


# ---------------------------------------------------------------- export + grey pictures
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
	for tag, off in (("a", Vector((0.9, -1.7, 0.55))), ("b", Vector((-1.2, -0.9, -0.35 if name == "root" else 0.9)))):
		cam.location = c + off.normalized() * size * 2.0
		cam.rotation_euler = (c - cam.location).to_track_quat("-Z", "Y").to_euler()
		scene.render.filepath = str(OUT / f"{name}_{tag}.png")
		bpy.ops.render.render(write_still=True)


BUILDS = {"root": build_root, "glowcap": build_glowcap, "crystal": build_crystal, "giant": build_giant}

for name, fn in BUILDS.items():
	if ONLY and name not in ONLY:
		continue
	kit.reset()
	ck.reset()
	objs = fn()
	tris = sum(len(p.vertices) - 2 for o in objs for p in o.data.polygons)
	bpy.ops.object.select_all(action="DESELECT")
	for o in objs:
		o.select_set(True)
	OUT.mkdir(parents=True, exist_ok=True)
	bpy.ops.export_scene.gltf(filepath=str(OUT / f"{name}.glb"), export_format="GLB", use_selection=True, export_yup=True)
	print(f"PLANT_DONE {name} {tris} triangles, parts {[o.name for o in objs]}")
	pictures(name, objs)
