# Rock Snail, rebuilt the Rock Beetle way (Claude, Nov 17, 2026; docs/art/CREATURE-RECIPE.md, F68/F31).
# Matches assets/concepts/creatures/rock_snail.png and its turnaround (rock_snail_turnaround.png); paint tiles from
# rock_snail_textures.png (assets/textures/creatures/snail_*_tile.png).
#
#   blender --background --factory-startup --python tools/asset_forge/builds/monster_rock_snail.py -- <out.glb> [<preview.png>] [look=mossy] [grey]
#
# The shell: ONE spiral tube (a log spiral, coiled side-on) melted into one skin, then raised into chunky stone
# cushions (nearest-seed patches) that press together with only a V-canyon between them, moss in the canyons.
# grey = stop after the shape (plain colours, light mesh) for the outline check (creature_fit.py).
# Parts for the game (src/combat/monster_model.gd): body (shell, moss, crystals), soft_body (foot, neck, head,
# moustache: shrinks into the shell when it hides), soft_stalk_l / soft_stalk_r (eye stalks, they sway),
# peek (two small eyes in the shell's mouth, shown only while hiding). glow_* materials hum (the crystals).
import math
import random
import sys
import time
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector, kdtree, noise

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import creature_sculpt as cs  # noqa: E402

ARGS = sys.argv[sys.argv.index("--") + 1:]
OUT = Path(ARGS[0])
PREVIEW = ARGS[1] if len(ARGS) > 1 and ARGS[1].endswith(".png") else None
LOOK = next((a[5:] for a in ARGS if a.startswith("look=")), "mossy")
GREY = "grey" in ARGS
TEX = Path(__file__).resolve().parents[3] / "assets" / "textures" / "creatures"
rnd = random.Random(7)
t0 = time.time()

# Colours picked by eye from the approved picture (sRGB): (base, dark, light)
PALETTE = {
	"mossy": dict(stone=((0.56, 0.5, 0.47), (0.32, 0.27, 0.26), (0.8, 0.74, 0.69)), moss=((0.5, 0.5, 0.12), (0.24, 0.26, 0.05), (0.72, 0.7, 0.24)),
		skin=((0.52, 0.52, 0.22), (0.3, 0.31, 0.11), (0.7, 0.68, 0.38)), tache=((0.4, 0.45, 0.14), (0.2, 0.24, 0.06), (0.62, 0.66, 0.28)),  # (round 4's moustache: the owner preferred it to the bushy round 5)
		crystal=((1.0, 0.9, 0.82), (0.84, 0.58, 0.48)), iris=((0.28, 0.15, 0.07), (0.55, 0.33, 0.15), (0.1, 0.05, 0.02))),
	# The other looks (approved rock_snail_variants.png; one body, only the paint and the add-ons change, recipe Part 3).
	"frost": dict(stone=((0.3, 0.34, 0.43), (0.12, 0.14, 0.2), (0.5, 0.56, 0.67)), moss=((0.88, 0.92, 0.98), (0.62, 0.7, 0.82), (1.0, 1.0, 1.0)),
		skin=((0.6, 0.65, 0.7), (0.36, 0.41, 0.48), (0.8, 0.84, 0.88)), tache=((0.86, 0.88, 0.9), (0.6, 0.63, 0.68), (0.98, 0.98, 1.0)),
		crystal=((0.82, 0.96, 1.0), (0.3, 0.62, 0.92)), iris=((0.28, 0.15, 0.07), (0.55, 0.33, 0.15), (0.1, 0.05, 0.02)),
		cap=((0.93, 0.96, 1.0), 0.6), crack_glow=0.0, crack_h=0.02),  # snow on the stones' tops and in the cracks, ice crystals
	"ember": dict(stone=((0.36, 0.25, 0.22), (0.15, 0.1, 0.09), (0.55, 0.4, 0.34)), moss=((1.0, 0.5, 0.1), (0.72, 0.16, 0.0), (1.0, 0.84, 0.42)),
		skin=((0.72, 0.62, 0.42), (0.46, 0.37, 0.23), (0.88, 0.8, 0.6)), tache=((0.74, 0.42, 0.14), (0.42, 0.2, 0.05), (0.94, 0.62, 0.3)),
		crystal=((1.0, 0.58, 0.12), (0.82, 0.26, 0.0)), iris=((0.28, 0.15, 0.07), (0.55, 0.33, 0.15), (0.1, 0.05, 0.02)),
		cap=None, crack_glow=0.9, crack_h=0.008),  # basalt with glowing lava in the cracks, orange crystals
	"spore": dict(stone=((0.36, 0.26, 0.41), (0.15, 0.1, 0.2), (0.56, 0.43, 0.62)), moss=((0.72, 0.36, 0.92), (0.4, 0.12, 0.56), (0.92, 0.66, 1.0)),
		skin=((0.6, 0.48, 0.56), (0.37, 0.27, 0.35), (0.78, 0.66, 0.73)), tache=((0.56, 0.31, 0.64), (0.3, 0.12, 0.37), (0.8, 0.54, 0.88)),
		crystal=((0.86, 0.6, 1.0), (0.5, 0.18, 0.74)), iris=((0.28, 0.15, 0.07), (0.55, 0.33, 0.15), (0.1, 0.05, 0.02)),
		cap=None, crack_glow=0.5, crack_h=0.02, mushrooms=True),  # glowing purple fungus in the cracks, glowing mushrooms
}
P = PALETTE[LOOK]

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene


def mat(name, rgb):
	m = bpy.data.materials.new(name)
	m.use_nodes = True
	m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (*cs.lin(rgb), 1)
	m.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.85
	return m


M = {k: mat(k, c) for k, c in {"stone_plate": P["stone"][0], "crack": P["moss"][0], "glow_crystal": P["crystal"][0],
	"skin": P["skin"][0], "moustache": P["tache"][0], "eye": (0.92, 0.88, 0.8)}.items()}


def mesh_obj(name, verts, faces, m):
	me = bpy.data.meshes.new(name)
	me.from_pydata([tuple(v) for v in verts], [], faces)
	me.update()
	o = bpy.data.objects.new(name, me)
	scene.collection.objects.link(o)
	o.data.materials.append(m)
	return o


def ell(name, loc, size, m, seg=32):
	"""An ellipsoid with its shape applied (so melting works in metres)."""
	bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=seg // 2, radius=1, location=loc)
	o = bpy.context.object
	o.name = name
	o.scale = size
	# (location too: the points must be in metres from the ground, or "z >= 0" is measured from the sphere's middle.
	# That bug cut the body off 23 cm above the ground: a gap over the foot, owner Nov 17)
	bpy.ops.object.transform_apply(location=True, rotation=False, scale=True)
	o.data.materials.append(m)
	return o


def tube(name, rings, m, up=Vector((0, -1, 0)), sides=16):
	"""A closed tube through rings (centre, width, depth): width runs along t x up, depth along up."""
	verts, faces = [], []
	pts = [Vector(r[0]) for r in rings]
	for i, (c, w, d) in enumerate(rings):
		t = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]).normalized()
		a = t.cross(up).normalized()
		b = a.cross(t).normalized()
		for k in range(sides):
			q = 2 * math.pi * k / sides
			verts.append(pts[i] + a * math.cos(q) * w + b * math.sin(q) * d)
	for i in range(len(rings) - 1):
		for k in range(sides):
			faces.append((i * sides + k, i * sides + (k + 1) % sides, (i + 1) * sides + (k + 1) % sides, (i + 1) * sides + k))
	for end, sgn in ((0, -1), (len(rings) - 1, 1)):
		verts.append(pts[end] + (pts[end] - pts[end - sgn if 0 <= end - sgn < len(pts) else end]).normalized() * 0.0)
		ci = len(verts) - 1
		for k in range(sides):
			f = (ci, end * sides + k, end * sides + (k + 1) % sides)
			faces.append(f if sgn > 0 else f[::-1])
	o = mesh_obj(name, verts, faces, m)
	_recalc(o)
	return o


def _recalc(o):
	bm = bmesh.new()
	bm.from_mesh(o.data)
	bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
	bm.to_mesh(o.data)
	bm.free()


def apply_scale(o):
	cs._select_only(o)
	bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)


# ================================================================== the shell
# Measured on the turnaround (463 px per metre, ground at z = 0, front = -Y): an egg 76 cm wide, from 33 cm in front of
# the middle to 62 cm behind it, 20 cm to 109 cm up. Its sides bulge out a little in the middle (a bun), and a spiral
# seam is cut into each side (centre 17 cm behind the middle, 56 cm up). The bands between the seams are cut into big
# blocks (about 8 a turn), the outer band across the top into 3 columns: like the picture's coiled stone blocks.
EC = Vector((0, 0.145, 0.645))     # the egg's centre
ER = Vector((0.38, 0.475, 0.445))  # its half-sizes
YC, ZC = 0.17, 0.56                # the spiral's centre
GROW = 2.6                         # the coil grows this much each turn (about 2.5 turns show, broad bands)
B = math.log(GROW) / (2 * math.pi)
A0 = 0.29                          # a seam's distance from the centre straight back (phi = 0)
XCUT = 0.13                        # the outer band's column cuts (front view: 3 stones across the top)


def spow(v, e):
	return math.copysign(abs(v) ** e, v)


def egg(nx, ny, nz):
	"""A point on the shell for a unit direction: a rounded superellipsoid, narrower at the top (egg), sides bulging."""
	e = 2 / 2.3
	p = Vector((spow(nx, e) * ER.x, spow(ny, e) * ER.y, spow(nz, e) * ER.z))
	t = max(0.0, nz)
	p.x *= (1 - 0.22 * t) * (1 + 0.07 * (1 - ny * ny - nz * nz))
	return EC + p


bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=6, radius=1)
shell = bpy.context.object
shell.name = "shell"
for v in shell.data.vertices:
	n = v.co.normalized()
	v.co = egg(n.x, n.y, n.z)
	v.co.z = max(v.co.z, 0.2 + 0.03 * (v.co.z - 0.2))  # a flatter bottom (it sits on the body)
shell.data.materials.append(M["stone_plate"])
shell = cs.melt([shell], voxel=0.008 if GREY else 0.0045, smooth=2, name="shell_base")


def seam(phi, n):
	return A0 * math.exp(B * (phi + 2 * math.pi * n))


# Over the top, front and back (the outer band seen from above): big uneven stones, nearest-seed patches like the
# beetle's. On the two sides: the spiral bands.
PSEEDS = []
_r = random.Random(5)
for _ in range(4000):
	d = Vector((_r.uniform(-1, 1), _r.uniform(-1, 1), _r.uniform(-1, 1)))
	if d.length > 1 or d.length < 0.2:
		continue
	d.normalize()
	if abs(d.x) > 0.8:
		continue
	q = egg(d.x, d.y, d.z)
	if q.z < 0.25:
		continue
	if all((q - o).length > 0.2 for o in PSEEDS):
		PSEEDS.append(q)
pkd = kdtree.KDTree(len(PSEEDS))
for i, q in enumerate(PSEEDS):
	pkd.insert(q, i)
pkd.balance()
SIDE_AT = 0.7   # how far out to the side (0 middle, 1 widest) the spiral face starts


def stone_of(p):
	"""Which stone a point is in, how far it is from that stone's edge (m), and where it sits inside it (u, v)."""
	ax = abs(p.x) / ER.x
	if ax < SIDE_AT:
		(s1, i1, d1), (s2, i2, d2) = pkd.find_n(p, 2)
		edge = (d2 * d2 - d1 * d1) / max(1e-6, 2 * (s2 - s1).length)
		edge = min(edge, (SIDE_AT - ax) * ER.x * 1.6)
		loc = p - s1
		return ("top", i1), edge, 0.5 + loc.y / 0.22, 0.5 + (loc.z + loc.x) / 0.22
	side = 1 if p.x > 0 else -1
	y, z = p.y - YC, p.z - ZC
	r = math.hypot(y, z)
	phi = math.atan2(z, y)
	if r < 0.045:
		return ("apex", side), 0.05, 0.5, 0.5
	n = math.floor(math.log(max(r, 1e-6) / A0) / (B * 2 * math.pi) - phi / (2 * math.pi))
	lo, hi = seam(phi, n), seam(phi, n + 1)
	band = hi - lo
	u = (r - lo) / band
	edge = min(r - lo, hi - r, (ax - SIDE_AT) * ER.x * 1.6)
	k = n * 2 + (side > 0)
	off = random.Random(k * 7 + 3).uniform(0, 1)
	turn = phi + 2 * math.pi * n          # the angle unwrapped along the whole coil
	step = band * random.Random(k).uniform(1.1, 1.4) / ((lo + hi) / 2)  # (the band's middle: cuts go straight across it)
	q = turn / step + off
	seg = math.floor(q)
	v = q - seg
	edge = min(edge, min(v, 1 - v) * step * r)
	return ("side", side, n, seg), edge, u, v


bm = bmesh.new()
bm.from_mesh(shell.data)
bm.normal_update()
CELLS = {}
cell_of = []
moves = []
base_copy = None
for v in bm.verts:
	p = v.co.copy()
	key, edge, u, w = stone_of(p)
	if key not in CELLS:
		r = random.Random(hash(key) & 0xFFFFFF)
		side_ = key[0] == "side"
		CELLS[key] = dict(id=len(CELLS), thick=r.uniform(0.06, 0.08) if side_ else r.uniform(0.05, 0.068), round=r.uniform(0.045, 0.06), top=r.uniform(0.85, 1.0),
			cuts=[(r.uniform(0.25, 0.75), r.uniform(0.25, 0.75), r.uniform(0.5, 1.1)) for _ in range(3)])
	c = CELLS[key]
	x = min(1.0, edge / c["round"])
	h = c["thick"] * (1 - (1 - x) ** 2.2)                     # cushion: rounded down into the canyon
	for cu, cv, slope in c["cuts"]:                           # chisel cuts: flat facets on top
		h = min(h, c["thick"] * (1.25 - slope * (abs(u - cu) + abs(w - cv))))
	h = min(h, c["thick"] * c["top"])
	h += 0.003 * noise.noise(p * 14)
	moves.append((v, max(0.0, h)))
	cell_of.append(c["id"])
if not GREY:  # the moss layer starts from the bare shell, just above it (it shows only in the canyons)
	cs._select_only(shell)
	bpy.ops.object.duplicate()
	base_copy = bpy.context.view_layer.objects.active
	base_copy.name = "moss_base"
for v, h in moves:
	v.co += v.normal * h
bm.to_mesh(shell.data)
bm.free()
shell.name = "stone_high"
cid = shell.data.attributes.new("cell", "INT", "POINT")
for i, c in enumerate(cell_of):
	cid.data[i].value = c
print("stones:", len(CELLS))

# ---- crystals: three pale pink-cream points on the top of the shell, sunk into a stone, a moss clump round them
def crystal(name, base, r, h, tilt, m, sides=6):
	up = tilt.normalized()
	a = up.cross(Vector((1, 0, 0)) if abs(up.x) < 0.9 else Vector((0, 1, 0))).normalized()
	b = up.cross(a)
	verts = []
	rr = random.Random(len(name))
	for k in range(sides):
		q = 2 * math.pi * k / sides
		j = rr.uniform(0.85, 1.12)
		verts.append(base + (a * math.cos(q) + b * math.sin(q)) * r * j)
	for k in range(sides):
		q = 2 * math.pi * k / sides
		j = rr.uniform(0.9, 1.08)
		verts.append(base + up * h * 0.72 + (a * math.cos(q) + b * math.sin(q)) * r * j)
	verts.append(base + up * h + a * r * 0.12)
	faces = [(k, (k + 1) % sides, sides + (k + 1) % sides, sides + k) for k in range(sides)]
	faces += [(sides + k, sides + (k + 1) % sides, 2 * sides) for k in range(sides)]
	faces.append(tuple(range(sides))[::-1])
	o = mesh_obj(name, verts, faces, m)
	_recalc(o)
	for p in o.data.polygons:
		p.use_smooth = False
	return o


def shell_top(y):
	"""The highest stone point above (0, y)."""
	best = 0.0
	for v in shell.data.vertices:
		if abs(v.co.x) < 0.02 and abs(v.co.y - y) < 0.02:
			best = max(best, v.co.z)
	return best


CRYS = [(Vector((-0.02, 0.21, 0)), 0.055, 0.2, Vector((0.05, 0.05, 1))), (Vector((-0.1, 0.13, 0)), 0.04, 0.12, Vector((-0.3, -0.25, 1))),
	(Vector((0.07, 0.3, 0)), 0.037, 0.1, Vector((0.35, 0.2, 1)))]
crystals = []
mushstems = []
if P.get("mushrooms"):  # spore: glowing mushrooms grow out of the stones on top instead of crystals (feet sunk into a stone)
	for k, (x, y, hgt, rad, lean) in enumerate(((0.0, 0.2, 0.19, 0.095, 0.0), (-0.11, 0.1, 0.14, 0.07, -0.3), (0.1, 0.31, 0.12, 0.062, 0.35),
			(-0.07, 0.35, 0.09, 0.05, -0.2), (0.13, 0.08, 0.09, 0.048, 0.4))):  # (big enough to see from a few metres, recipe)
		base = Vector((x, y, shell_top(y) - 0.03))
		up = Vector((lean, 0, 1)).normalized()
		top = base + up * hgt
		mushstems.append(tube(f"stem{k}", [(base, rad * 0.32, rad * 0.32), (base.lerp(top, 0.5), rad * 0.26, rad * 0.26), (top, rad * 0.24, rad * 0.24)], mat("mushstem", (0.86, 0.8, 0.84)), up=Vector((0, 1, 0)), sides=10))
		cap_ = ell(f"cap{k}", tuple(top + up * rad * 0.15), (rad, rad, rad * 0.55), M["glow_crystal"], seg=20)
		for v in cap_.data.vertices:  # a dome: the underside pulled up flat
			if v.co.z < top.z + up.z * rad * 0.1:
				v.co.z = top.z + up.z * rad * 0.1 + (v.co.z - top.z - up.z * rad * 0.1) * 0.25
		crystals.append(cap_)
else:
	for k, (p, r, h, tilt) in enumerate(CRYS):
		p.z = shell_top(p.y) - 0.05
		crystals.append(crystal(f"crystal{k}", p, r, h + 0.05, tilt, M["glow_crystal"]))
clump = ell("moss_clump", (0, 0.21, shell_top(0.21) - 0.05), (0.12, 0.15, 0.05), M["crack"])

# ================================================================== the soft body: the foot, and the body above it
# The foot is its own part (soft_foot) so the game can gather it in and splat it out when he hops (owner, Nov 17).
SK = M["skin"]
body_parts = []
# The creeping foot: an oval sheet, flat underneath, round all the way round (the skirt), a little longer in front.
foot = ell("foot", (0, -0.02, 0.07), (0.47, 0.66, 0.1), SK, seg=48)  # (taller: the body always sits in it, owner)
for v in foot.data.vertices:
	v.co.z = max(0.0, v.co.z)
	if v.co.y < 0:
		v.co.z *= 1.0 + 0.6 * min(1.0, -v.co.y / 0.6) * max(0.0, 1 - abs(v.co.x) / 0.3)  # thicker under the chin
# The hump under the shell (fills up into the shell: no see-through between the body and the stones).
body_parts.append(ell("hump", (0, 0.12, 0.2), (0.3, 0.42, 0.17), SK))
# The neck rises at the front into the head (a chain of soft lumps, melted smooth).
NECK = [(Vector((0, -0.16, 0.12)), 0.3, 0.12), (Vector((0, -0.3, 0.17)), 0.26, 0.16), (Vector((0, -0.42, 0.26)), 0.21, 0.17),
	(Vector((0, -0.49, 0.39)), 0.18, 0.155), (Vector((0, -0.51, 0.52)), 0.165, 0.14), (Vector((0, -0.51, 0.6)), 0.15, 0.12)]
body_parts.append(tube("neck", NECK, SK, up=Vector((1, 0, 0)), sides=24))   # (width runs front-back, depth sideways)
body_parts.append(ell("crown", (0, -0.51, 0.61), (0.15, 0.12, 0.08), SK))      # the rounded top of the head
body_parts.append(ell("lip", (0, -0.635, 0.4), (0.085, 0.035, 0.03), SK))        # the pouting lower lip (the frown)
skin = cs.melt(body_parts, voxel=0.008 if GREY else 0.005, smooth=8, name="skin_high")
for v in skin.data.vertices:
	v.co.z = max(0.03, v.co.z)  # the body's bottom stays 3 cm inside the foot (never on the ground with it: no shimmer)
footskin = cs.melt([foot], voxel=0.008 if GREY else 0.005, smooth=3, name="foot_high")
bm = bmesh.new()  # the skirt's edge ripples (wavy, like the picture), the sole stays on the ground
bm.from_mesh(footskin.data)
for v in bm.verts:
	ang = math.atan2(v.co.y / 0.66, v.co.x / 0.47)
	edge = math.hypot(v.co.x / 0.47, v.co.y / 0.66)
	if edge > 0.75:
		v.co.z += 0.016 * math.sin(ang * 11) * min(1.0, (edge - 0.75) / 0.2) * min(1.0, v.co.z / 0.04)
	v.co.z = max(0.0, v.co.z)
bm.to_mesh(footskin.data)
bm.free()

# The moss moustache: two fat lobes from the middle of the lip, out and curling up at the tips.
def catmull(pts, n):
	pts = [Vector(p) for p in pts]
	ext = [pts[0] * 2 - pts[1]] + pts + [pts[-1] * 2 - pts[-2]]
	outp = []
	for i in range(1, len(ext) - 2):
		p0, p1, p2, p3 = ext[i - 1], ext[i], ext[i + 1], ext[i + 2]
		for k in range(n):
			t = k / n
			outp.append(0.5 * (2 * p1 + (p3 - p0) * 0 + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t + (-p0 + 3 * p1 - 3 * p2 + p3) * t ** 3))
	outp.append(pts[-1])
	return outp


tache = []
TP = [(0.01, -0.665, 0.5), (0.08, -0.675, 0.47), (0.16, -0.67, 0.45), (0.225, -0.66, 0.455), (0.27, -0.65, 0.485), (0.282, -0.645, 0.525),
	(0.262, -0.64, 0.552), (0.236, -0.635, 0.54)]
# ONE continuous piece from the left curled tip, under the nose, to the right one (owner, Nov 18: two lobes meeting
# left a notch, and a knot filling it looked like a nose; "just connect them seamlessly").
ctrl = [(-x, y, z) for x, y, z in reversed(TP[1:])] + [(0.0, -0.667, 0.495)] + [(x, y, z) for x, y, z in TP[1:]]
path = catmull(ctrl, 4)
mid = len(path) // 2
rings = []
for i, q in enumerate(path):
	t = abs(i - mid) / mid                       # 0 in the middle, 1 at each tip
	w = 0.088 + 0.012 * math.sin(math.pi * min(1.0, t * 1.6)) - 0.09 * max(0.0, t - 0.45) / 0.55  # full in the middle, thin curled tips
	rings.append((q, max(0.008, w), max(0.007, w * 0.85)))
tache.append(tube("tache", rings, M["moustache"], sides=16))
tache = cs.melt(tache, voxel=0.004 if GREY else 0.0025, smooth=3, name="tache_high")

# ================================================================== eye stalks (moving parts) and the peeking eyes
# The eye, like the picture (round 4, owner: "work on the eyes"): a BIG ball held in a cup of skin, a thick rim
# wrapping all the way round it, and a heavy lid fold over the top (lower on the nose side: the grumpy V). Stalk,
# cup, rim and lid are one melted skin; only the ball is separate (one moving piece with it).
EYE_R = 0.068
STALKS = {}
STALK_LINE = {}  # side -> (base, top): the stalk's bone line (it bends halfway along it: split_stalk)
for s, side in ((-1, "l"), (1, "r")):
	ec = Vector((s * 0.165, -0.6, 0.8))                       # the eyeball's middle
	look = Vector((s * 0.15, -1, -0.04)).normalized()         # where it looks: forward, a little outward
	base = Vector((s * 0.07, -0.5, 0.6))
	top = ec - look * 0.045 + Vector((0, 0, -0.035))           # the stalk ends in the back of the cup
	mid = base.lerp(top, 0.5) + Vector((0, 0.015, 0))
	STALK_LINE[side] = (base, top)
	pieces = [tube(f"stalk_{side}", [(base, 0.046, 0.046), (mid, 0.038, 0.038), (top, 0.04, 0.04)], SK, up=Vector((1, 0, 0)), sides=14)]
	cup = ell(f"cup_{side}", tuple(ec - look * 0.022), (0.08, 0.077, 0.08), SK)  # the ball sits in it; its front shows
	pieces.append(cup)
	# the rim: round the opening, where the ball comes out of the cup
	bpy.ops.mesh.primitive_torus_add(major_radius=0.063, minor_radius=0.013, major_segments=40, minor_segments=12,
		location=ec + look * 0.022, rotation=look.to_track_quat("Z", "Y").to_euler())
	rim = bpy.context.object
	rim.name = f"rim_{side}"
	rim.data.materials.append(SK)
	apply_scale(rim)
	pieces.append(rim)
	# the heavy lid fold: a thick shell over the top of the ball, cut by one tilted plane
	bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=24, radius=EYE_R * 1.13, location=ec)
	lid = bpy.context.object
	lid.name = f"lid_{side}"
	lb = bmesh.new()
	lb.from_mesh(lid.data)
	n = Vector((-s * 0.3, -0.12, 1)).normalized()  # (round 4b: higher, so it only covers the top of the iris)
	bmesh.ops.bisect_plane(lb, geom=lb.verts[:] + lb.edges[:] + lb.faces[:], plane_co=Vector((0, 0, 0.034)), plane_no=n, clear_inner=True)
	lb.to_mesh(lid.data)
	lb.free()
	lid.data.materials.append(SK)
	sol = lid.modifiers.new("thick", "SOLIDIFY")
	sol.thickness = 0.022
	sol.offset = -1
	cs._apply_all(lid)
	apply_scale(lid)
	pieces.append(lid)
	stalk_skin = cs.melt(pieces, voxel=0.0025, smooth=1, name=f"stalkskin_{side}")
	# Chiselled (round 5, owner): cut into flat hand-carved planes like the picture, not a smooth ball.
	dec = stalk_skin.modifiers.new("chisel", "DECIMATE")
	dec.ratio = min(1.0, 1400 / max(1, len(stalk_skin.data.polygons)))
	cs._apply_all(stalk_skin)
	for p_ in stalk_skin.data.polygons:
		p_.use_smooth = False
	bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, radius=EYE_R, location=ec)
	eye = bpy.context.object
	eye.name = f"eyeball_{side}"
	eye.data.materials.append(M["eye"])
	apply_scale(eye)
	for p in eye.data.polygons:
		p.use_smooth = True
	STALKS[side] = (stalk_skin, eye, base)
# Blinking (owner, Nov 18): a thin skin lid per eye, built CLOSED over the front of the ball and turned up about
# the eye's middle (its own X axis) into the cup and the heavy lid, out of sight. The game turns it down to blink
# (MonsterModel._snail: every few seconds, and when he is hit). It is a child of the stalk, so it moves with it.
BLINK_OPEN = -2.6  # radians about X: up and back, tucked away under the heavy lid (-1.75 left its edge showing)
lidmat = mat("skin_lid", tuple(c * 0.85 for c in P["skin"][0]))  # (a little darker than the base: matches the painted bulb)
BLINKS = {}
for s, side in ((-1, "l"), (1, "r")):
	ec = Vector((s * 0.165, -0.6, 0.8))
	look = Vector((s * 0.15, -1, -0.04)).normalized()
	bpy.ops.mesh.primitive_uv_sphere_add(segments=40, ring_count=20, radius=EYE_R * 1.035, location=ec)
	bl = bpy.context.object
	bl.name = f"blink_{side}"
	bb = bmesh.new()
	bb.from_mesh(bl.data)
	bmesh.ops.bisect_plane(bb, geom=bb.verts[:] + bb.edges[:] + bb.faces[:], plane_co=-look * EYE_R * 0.15, plane_no=look, clear_inner=True)
	bb.to_mesh(bl.data)
	bb.free()
	bl.data.materials.append(lidmat)
	sol = bl.modifiers.new("thick", "SOLIDIFY")
	sol.thickness = 0.005
	sol.offset = 1
	cs._apply_all(bl)
	for p_ in bl.data.polygons:
		p_.use_smooth = True
	scene.cursor.location = ec  # (its turning point: the eye's middle)
	cs._select_only(bl)
	bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
	bl.rotation_euler.x = BLINK_OPEN
	BLINKS[side] = bl
PEEK = []
for s in (-1, 1):  # hiding: two small eyes look out of the shell's mouth
	pc = Vector((s * 0.07, -0.2, 0.25))
	cap = ell(f"peekcap{s}", tuple(pc + Vector((0, 0.01, 0.008))), (0.036, 0.032, 0.034), SK, seg=20)
	bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, radius=0.026, location=pc + Vector((0, -0.015, 0)))
	pe = bpy.context.object
	pe.data.materials.append(M["eye"])
	PEEK += [cap, pe]
print("shape", round(time.time() - t0), "s")

# ================================================================== paint + bake (the beetle way)
moss = None
if GREY:
	parts_body = [shell, clump] + crystals + mushstems
	parts_soft = [skin, tache]
	parts_foot = [footskin]
else:
	base_copy.name = "moss_high"
	cs._displace(base_copy, lambda p, n: 0.004)
	cs.carve_moss(base_copy, height=P.get("crack_h", 0.024), cover=0.05, seed=4)  # in the canyons, a bit thicker (round 5, owner)
	moss = cs.melt([base_copy, clump], voxel=0.006, smooth=1, name="moss_high")
	cs.carve_stone(shell, seed=3, chips=0.006)
	# each stone its own shade (a clearly visible mix, rule 8)
	at = shell.data.color_attributes.new("tint", "FLOAT_COLOR", "POINT")
	cells = shell.data.attributes["cell"]
	shade = {}
	for i in range(len(CELLS)):
		r = random.Random(3000 + i)
		v = 1.0 + r.uniform(-0.2, 0.12)
		warm = r.choice((-1, 0, 1, 1, 1)) * r.uniform(0.03, 0.08)  # mostly warm grey (blue-grey looked purple)
		shade[i] = (v * (1 + warm), v * (1 + warm * 0.3), v * (1 - warm), 1.0)
	for i, c in enumerate(cells.data):
		at.data[i].color = shade[c.value]
	cs.carve_chitin(skin, dents=0.004, grain=0.0012, seed=7, grooves=0.0015, groove_scale=6.0)  # soft, chunky, a little damp-wrinkled
	cs.carve_chitin(footskin, dents=0.004, grain=0.0012, seed=8, grooves=0.0015, groove_scale=6.0)

	cs.carve_chitin(tache, dents=0.002, grain=0.0015, seed=9)  # (strand grooves by height made stripes: the tile gives the strands)
	stone_tile, moss_tile = str(TEX / "snail_stone_tile.png"), str(TEX / "snail_moss_tile.png")
	skin_tile, tache_tile = str(TEX / "snail_skin_tile.png"), str(TEX / "snail_moustache_tile.png")
	MOSSY = LOOK == "mossy"  # (the ChatGPT tiles are the mossy snail's colours: the other looks use only a little of them)
	shell.data.materials.clear()
	shell.data.materials.append(cs.paint_material("paint_stone", *P["stone"], moss=P["moss"][0], moss_amount=0.55, strokes=0.16,
		edge=0.55, seed=1, tint_attr="tint", scratches=1.0, grime=0.35, scratch_width=2.2, picture=stone_tile, picture_scale=2.2,
		picture_amount=0.35 if MOSSY else 0.12, cap=P.get("cap")))
	moss.data.materials.clear()
	moss.data.materials.append(cs.paint_material("paint_moss", *P["moss"], strokes=0.16, top_light=0.25, edge=0.3, seed=4,
		picture=moss_tile if MOSSY else None, picture_scale=5.0, picture_amount=0.6))
	skin.data.materials.clear()
	skin.data.materials.append(cs.paint_material("paint_skin", *P["skin"], strokes=0.14, top_light=0.25, edge=0.45, seed=5, key=0.35,
		grime=0.2, picture=skin_tile, picture_scale=2.0, picture_amount=0.6 if MOSSY else 0.15))
	footskin.data.materials.clear()
	footskin.data.materials.append(skin.data.materials[0])
	tache.data.materials.clear()
	tache.data.materials.append(cs.paint_material("paint_tache", *P["tache"], strokes=0.1, top_light=0.3, edge=0.4, seed=6,
		picture=tache_tile, picture_scale=7.0, picture_amount=0.7 if MOSSY else 0.15))
	cjobs = []
	for c in crystals:
		hi = cs.detail_copy(c, 2, c.name + "_high")
		hi.data.materials.clear()
		hi.data.materials.append(cs.glow_paint("paint_crystal", core=P["crystal"][0], rim=P["crystal"][1], lines=0.3, cells=4.0,
			facets=0.45, cloud=0.35, bubbles=0.5, creases=0.4))
		cs.uv_only(c)
		cjobs.append((hi, c))
	ejobs = []
	for side, (sk, eye, base) in STALKS.items():
		hi = cs.detail_copy(eye, 2, eye.name + "_high")
		cs.eye_attrs(hi, lambda sd: (sd * 0.15, -1, -0.04))
		hi.data.materials.clear()
		hi.data.materials.append(cs.paint_eye("paint_eye", iris_out=P["iris"][0], iris_in=P["iris"][1], ring=P["iris"][2],
			iris_deg=40.0, pupil_deg=21.0, shine_deg=8.0))  # (big iris and pupil, like the picture)
		cs.uv_only(eye)
		sk.data.materials.clear()
		sk.data.materials.append(skin.data.materials[0])
		sk_hi = cs.detail_copy(sk, 1, sk.name + "_high")  # (keeps the flat planes; the light game copy is the chiselled skin itself)
		cs.carve_chitin(sk_hi, dents=0.0012, grain=0.0006, seed=12)
		sk_lo = cs.uv_only(sk)
		ejobs.append((side, hi, eye, sk_hi, sk_lo))
	print("sculpt", round(time.time() - t0), "s")
	low_shell = cs.game_copy(shell, 12000, "shell_low")
	low_moss = cs.game_copy(moss, 4000, "moss_low")
	low_skin = cs.game_copy(skin, 6000, "skin_low")
	low_foot = cs.game_copy(footskin, 3000, "foot_low")
	low_tache = cs.game_copy(tache, 2000, "tache_low")
	cs.bake(shell, low_shell, 2048, "stone_baked")
	glow = P.get("crack_glow", 0.0)  # (ember: lava, spore: fungus glow in the cracks; the game hums glow_* materials)
	cs.bake(moss, low_moss, 1024, ("glow_lava_baked" if LOOK == "ember" else "glow_spore_baked") if glow else "moss_baked", emissive=glow)
	cs.bake(skin, low_skin, 1024, "skin_baked")
	cs.bake(footskin, low_foot, 1024, "foot_baked")
	cs.bake(tache, low_tache, 512, "moustache_baked", ext=0.015)
	for k, (hi, lo) in enumerate(cjobs):
		nm = "glow_mushroom_baked" if P.get("mushrooms") else "glow_crystal_baked"
		cs.bake(hi, lo, 256, f"{nm}{k}" if k else nm, normal=False, emissive=0.45)
	for side, hi, eye, sk_hi, sk_lo in ejobs:
		cs.bake(hi, eye, 256, f"eye_baked_{side}", normal=False)
		eye.data.materials[0].node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.2  # wet shine
		cs.bake(sk_hi, sk_lo, 512, f"stalk_baked_{side}", ext=0.01)
		STALKS[side] = (sk_lo, eye, STALKS[side][2])
	for o in [shell, moss, skin, footskin, tache] + [j[0] for j in cjobs] + [j[1] for j in ejobs] + [j[3] for j in ejobs]:
		o.hide_set(True)
		o.hide_render = True
	parts_body = [low_shell, low_moss] + crystals + mushstems
	parts_soft = [low_skin, low_tache]
	parts_foot = [low_foot]
	print("bake", round(time.time() - t0), "s")


# ================================================================== the game model: parts at their hinges
def join(objs, name, hinge):
	bpy.ops.object.select_all(action="DESELECT")
	for o in objs:
		o.hide_set(False)
		o.select_set(True)
	bpy.context.view_layer.objects.active = objs[0]
	if len(objs) > 1:
		bpy.ops.object.join()
	o = bpy.context.view_layer.objects.active
	o.name = name
	o.data.name = name
	scene.cursor.location = hinge
	bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
	return o


final = [join(parts_body, "body", (0, 0, 0)), join(parts_soft, "soft_body", (0, 0.1, 0.45)),
	join(parts_foot, "soft_foot", (0, 0, 0))]  # (the foot's hinge on the ground under the middle: it gathers and splats there)
def split_stalk(st, side):
	"""A joint halfway up the stalk (owner, Nov 18: "bones in the eye, so when he dies they also fall"): the upper half
	with the cup, lid and eye becomes "stalktip", a child of the stalk turning at the joint. Each face goes by how far
	along the stalk's line it sits."""
	b0, b1 = STALK_LINE[side]
	axis = b1 - b0
	joint = b0 + axis * 0.5
	tip = st.copy()
	tip.data = st.data.copy()
	scene.collection.objects.link(tip)
	tip.name = tip.data.name = f"stalktip_{side}"
	up_faces = {f.index for f in st.data.polygons if ((st.matrix_world @ f.center) - b0).dot(axis) / axis.length_squared > 0.5}
	for ob, keep_up in ((st, False), (tip, True)):
		b = bmesh.new()
		b.from_mesh(ob.data)
		b.faces.ensure_lookup_table()
		bmesh.ops.delete(b, geom=[f for f in b.faces if (f.index in up_faces) != keep_up], context="FACES")
		b.to_mesh(ob.data)
		b.free()
	scene.cursor.location = joint
	bpy.ops.object.select_all(action="DESELECT")
	tip.select_set(True)
	bpy.context.view_layer.objects.active = tip
	bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
	tip.parent = st
	tip.matrix_parent_inverse = st.matrix_world.inverted()
	return tip


for side, (sk, eye, base) in STALKS.items():
	st = join([sk, eye], f"soft_stalk_{side}", base)  # stalk, bulb, lid and eye: ONE moving piece
	tip = split_stalk(st, side)  # (with a joint halfway up: the upper half, cup, lid and eye hang on it)
	bl = BLINKS[side]
	bl.parent = tip
	bl.matrix_parent_inverse = tip.matrix_world.inverted()
	final += [st, tip, bl]
final.append(join(PEEK, "peek", (0, -0.2, 0.25)))
bpy.ops.object.select_all(action="DESELECT")
for o in final:
	o.select_set(True)
OUT.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.export_scene.gltf(filepath=str(OUT), export_format="GLB", use_selection=True, export_yup=True,
	export_image_format="JPEG", export_image_quality=88)
import glb_jpeg_fix  # noqa: E402  (F164: Godot shows Blender's JPEGs white without this)
glb_jpeg_fix.fix(str(OUT))
vs = [o.matrix_world @ v.co for o in final for v in o.data.vertices]
lo = Vector((min(v.x for v in vs), min(v.y for v in vs), min(v.z for v in vs)))
hi = Vector((max(v.x for v in vs), max(v.y for v in vs), max(v.z for v in vs)))
d = hi - lo
tris = sum(len(p.vertices) - 2 for o in final for p in o.data.polygons)
print(f"KIT_DONE {OUT} size {d.x:.2f} x {d.y:.2f} x {d.z:.2f} m, {tris} triangles, parts {[o.name for o in final]}, {round(time.time() - t0)} s")
