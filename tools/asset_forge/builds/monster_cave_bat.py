# Cave Bat, rebuilt the Rock Beetle way (Claude, Nov 18, 2026; docs/art/CREATURE-RECIPE.md).
# Matches assets/concepts/creatures/cave_bat.png and its turnaround (cave_bat_turnaround.png); paint tiles from
# cave_bat_textures.png (assets/textures/creatures/batv2_*_tile.png).
#
#   blender --background --factory-startup --python tools/asset_forge/builds/monster_cave_bat.py -- <out.glb> [look=mossy] [grey]
#
# Upright like the picture (a fluffy ball, wings spread to the sides, swept back, feet hanging). Measured on the
# turnaround at 443 px per metre (1.5 m from wing tip to wing tip); front = -Y, up = +Z.
# Parts for the game (src/combat/monster_model.gd): body; wing_l / wing_r (flap, hinged at the shoulder);
# fold_l / fold_r (the wings wrapped round him while he hangs asleep, hidden in flight); an empty "upright" marker
# (he hangs upside down by his feet, not tipped on his face like the old lying-down bat). Eyes: material "eye*".
import math
import random
import sys
import time
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector, noise

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import creature_sculpt as cs  # noqa: E402

ARGS = sys.argv[sys.argv.index("--") + 1:]
OUT = Path(ARGS[0])
LOOK = next((a[5:] for a in ARGS if a.startswith("look=")), "mossy")
GREY = "grey" in ARGS
NOFOLD = "nofold" in ARGS  # (leave the folded wings out: for the outline check)
TEX = Path(__file__).resolve().parents[3] / "assets" / "textures" / "creatures"
rnd = random.Random(9)
t0 = time.time()

# Colours picked by eye from the approved picture (sRGB): (base, dark, light)
PALETTE = {
	"mossy": dict(fur=((0.56, 0.29, 0.12), (0.33, 0.15, 0.06), (0.76, 0.47, 0.23)), belly=((0.8, 0.63, 0.45), (0.56, 0.4, 0.26), (0.93, 0.8, 0.62)),
		membrane=((0.62, 0.31, 0.25), (0.42, 0.18, 0.14), (0.8, 0.5, 0.4)), bone=((0.45, 0.24, 0.16), (0.26, 0.12, 0.07), (0.64, 0.4, 0.29)),
		ear_in=((0.86, 0.46, 0.46), (0.6, 0.26, 0.28), (0.97, 0.66, 0.62)), snout=((0.82, 0.44, 0.44), (0.5, 0.22, 0.24), (0.96, 0.64, 0.6)),
		claw=((0.9, 0.8, 0.62), (0.62, 0.5, 0.36), (1.0, 0.95, 0.84)), foot=((0.34, 0.17, 0.12), (0.17, 0.08, 0.05), (0.52, 0.3, 0.22)),
		iris=((0.24, 0.13, 0.06), (0.5, 0.3, 0.14), (0.08, 0.04, 0.02))),
	# The other looks (owner, Nov 18; approved cave_bat_variants.png; recipe Part 3: one body, only paint and add-ons change)
	"frost": dict(fur=((0.6, 0.62, 0.66), (0.36, 0.38, 0.44), (0.93, 0.95, 0.98)), belly=((0.82, 0.84, 0.86), (0.6, 0.62, 0.66), (0.96, 0.97, 0.98)),
		membrane=((0.33, 0.43, 0.6), (0.18, 0.25, 0.4), (0.74, 0.84, 0.95)), bone=((0.35, 0.41, 0.53), (0.2, 0.24, 0.33), (0.82, 0.88, 0.95)),
		ear_in=((0.46, 0.67, 0.86), (0.28, 0.45, 0.66), (0.76, 0.89, 0.98)), snout=((0.78, 0.46, 0.48), (0.5, 0.25, 0.28), (0.92, 0.66, 0.66)),
		claw=((0.9, 0.82, 0.68), (0.62, 0.52, 0.4), (1.0, 0.96, 0.88)), foot=((0.32, 0.34, 0.4), (0.17, 0.18, 0.22), (0.52, 0.55, 0.62)),
		iris=((0.24, 0.13, 0.06), (0.5, 0.3, 0.14), (0.08, 0.04, 0.02))),  # grey-white fur, blue wings with frosty edges
	"ember": dict(fur=((0.21, 0.13, 0.11), (0.09, 0.05, 0.04), (1.0, 0.48, 0.12)), belly=((0.85, 0.46, 0.16), (0.55, 0.26, 0.08), (1.0, 0.7, 0.36)),
		membrane=((0.3, 0.14, 0.1), (0.15, 0.06, 0.04), (0.55, 0.26, 0.15)), bone=((0.3, 0.17, 0.12), (0.15, 0.07, 0.04), (0.52, 0.31, 0.2)),
		ear_in=((0.95, 0.46, 0.16), (0.7, 0.26, 0.06), (1.0, 0.7, 0.4)), snout=((0.8, 0.42, 0.4), (0.5, 0.22, 0.22), (0.94, 0.62, 0.56)),
		claw=((0.9, 0.78, 0.6), (0.62, 0.48, 0.34), (1.0, 0.94, 0.82)), foot=((0.24, 0.13, 0.1), (0.12, 0.06, 0.04), (0.42, 0.24, 0.17)),
		iris=((0.24, 0.13, 0.06), (0.5, 0.3, 0.14), (0.08, 0.04, 0.02)),
		glow=("lava", (1.0, 0.46, 0.08))),  # charcoal fur with orange tips, dark wings with glowing lava veins
	"spore": dict(fur=((0.5, 0.28, 0.52), (0.3, 0.14, 0.32), (0.76, 0.5, 0.77)), belly=((0.68, 0.48, 0.68), (0.45, 0.3, 0.46), (0.86, 0.68, 0.86)),
		membrane=((0.52, 0.2, 0.55), (0.32, 0.1, 0.36), (0.76, 0.42, 0.79)), bone=((0.4, 0.2, 0.42), (0.22, 0.1, 0.25), (0.62, 0.38, 0.64)),
		ear_in=((0.83, 0.5, 0.83), (0.6, 0.3, 0.62), (0.96, 0.72, 0.96)), snout=((0.8, 0.46, 0.56), (0.5, 0.24, 0.32), (0.94, 0.66, 0.72)),
		claw=((0.9, 0.8, 0.66), (0.62, 0.5, 0.38), (1.0, 0.95, 0.86)), foot=((0.3, 0.16, 0.3), (0.15, 0.07, 0.15), (0.5, 0.3, 0.5)),
		iris=((0.24, 0.13, 0.06), (0.5, 0.3, 0.14), (0.08, 0.04, 0.02)),
		glow=("spore", (0.86, 0.46, 1.0))),  # purple fur, purple wings with glowing violet spots
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


M = {k: mat(k, P[k][0]) for k in ("fur", "membrane", "bone", "ear_in", "snout", "claw", "foot")}
M["eye"] = mat("eye", (0.95, 0.9, 0.82))


def _recalc(o):
	bm = bmesh.new()
	bm.from_mesh(o.data)
	bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
	bm.to_mesh(o.data)
	bm.free()


def mesh_obj(name, verts, faces, m, smooth=True):
	me = bpy.data.meshes.new(name)
	me.from_pydata([tuple(v) for v in verts], [], faces)
	me.update()
	o = bpy.data.objects.new(name, me)
	scene.collection.objects.link(o)
	o.data.materials.append(m)
	for p in o.data.polygons:
		p.use_smooth = smooth
	_recalc(o)
	return o


def ell(name, loc, size, m, seg=32):
	"""An ellipsoid, its shape and place applied (points in metres from the ground)."""
	bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=seg // 2, radius=1, location=loc)
	o = bpy.context.object
	o.name = name
	o.scale = size
	bpy.ops.object.transform_apply(location=True, rotation=False, scale=True)
	o.data.materials.append(m)
	for p in o.data.polygons:
		p.use_smooth = True
	return o


def tube(name, rings, m, up=Vector((0, 0, 1)), sides=8, smooth=True, caps=True):
	"""A closed tube through rings (centre, width, depth): width runs along t x up, depth along up."""
	pts = [Vector(r[0]) for r in rings]
	verts, faces = [], []
	for i, (c, w, d) in enumerate(rings):
		t = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]).normalized()
		a = t.cross(up)
		if a.length < 1e-6:
			a = t.cross(Vector((1, 0, 0)))
		a.normalize()
		b = a.cross(t).normalized()
		for k in range(sides):
			q = 2 * math.pi * k / sides
			verts.append(pts[i] + a * math.cos(q) * w + b * math.sin(q) * d)
	n = len(rings)
	for i in range(n - 1):
		for k in range(sides):
			faces.append((i * sides + k, i * sides + (k + 1) % sides, (i + 1) * sides + (k + 1) % sides, (i + 1) * sides + k))
	if caps:
		for end, sgn in ((0, -1), (n - 1, 1)):
			verts.append(pts[end])
			ci = len(verts) - 1
			for k in range(sides):
				f = (ci, end * sides + k, end * sides + (k + 1) % sides)
				faces.append(f if sgn > 0 else f[::-1])
	return mesh_obj(name, verts, faces, m, smooth)


def claw(name, root, direction, length, r0, m=None, curl=Vector((0, 0, -1))):
	"""A curved pointed claw: from root along direction, bending toward curl, ending in a point."""
	d = direction.normalized()
	pts = [root + d * length * t + curl.normalized() * length * 0.35 * t * t for t in (0.0, 0.3, 0.6, 0.85, 1.0)]
	rs = [r0, r0 * 0.85, r0 * 0.6, r0 * 0.33, 0.002]
	up = d.cross(curl).normalized() if d.cross(curl).length > 1e-4 else Vector((1, 0, 0))
	return tube(name, [(p, r, r) for p, r in zip(pts, rs)], m or M["claw"], up=up, sides=8)


# ================================================================== the body: a fluffy ball of leaf-shaped fur tufts
BC = Vector((0, 0.02, 0.57))      # the ball's middle
BR = Vector((0.27, 0.22, 0.3))    # its half-sizes (a little fuller than the turnaround: the approved picture's ball is bigger)


def on_ball(d, out=0.0):
	"""The ball's surface point for a unit direction d, and its outward normal."""
	p = BC + Vector((d.x * BR.x, d.y * BR.y, d.z * BR.z))
	n = Vector((d.x / BR.x, d.y / BR.y, d.z / BR.z)).normalized()
	return p + n * out, n


def in_face(d):
	"""The face patch (eyes, snout, mouth): no tufts there, only short smooth fur."""
	return d.y < -0.55 and -0.32 < d.z < 0.5 and abs(d.x) < 0.62


# The fur (round 6): leaf-shaped tufts CARVED into the ball's own skin, not stuck on (tufts stuck on looked like
# flakes on a bare ball). Each leaf rises toward its pointed tip and laps over the leaf below like a roof shingle;
# the height is the highest leaf at each point, so the steps between leaves are the leaf outlines. Rows of leaves,
# each row offset half a leaf, all pointing down; none on the face.
ball = ell("ball", BC, BR, M["fur"], seg=64)
ball = cs.melt([ball], voxel=0.007 if GREY else 0.0035, smooth=0, name="ball")
LEAVES = []
ROWS = 11
for k in range(ROWS):
	th = math.pi * (0.04 + 0.9 * k / (ROWS - 1))
	n_row = max(4, round(2 * math.pi * math.sin(th) * 0.27 / 0.085))
	for j in range(n_row):
		ph = 2 * math.pi * (j + 0.5 * (k % 2) + rnd.uniform(-0.15, 0.15)) / n_row
		tj = th + rnd.uniform(-0.04, 0.04)
		d = Vector((math.sin(tj) * math.cos(ph), math.sin(tj) * math.sin(ph), math.cos(tj)))
		if in_face(d):
			continue
		p, n = on_ball(d)
		down = Vector((0, 0, -1)) - n * n.z
		if down.length < 0.25:
			down = Vector((math.cos(ph), math.sin(ph), 0)) - n * n.dot(Vector((math.cos(ph), math.sin(ph), 0)))  # (the crown: out from the top)
		down.normalize()
		LEAVES.append(dict(p=p, down=down, side=n.cross(down).normalized(), L=0.12 * rnd.uniform(0.85, 1.15) * (0.8 if d.z < -0.5 else 1.0),
			W=0.105 * rnd.uniform(0.85, 1.15), H=rnd.uniform(0.034, 0.046), sk=rnd.uniform(-0.15, 0.15)))  # (round 7: deeper H, they read from afar)
from mathutils import kdtree  # noqa: E402
lkd = kdtree.KDTree(len(LEAVES))
for i, lf in enumerate(LEAVES):
	lkd.insert(lf["p"], i)
lkd.balance()
bm = bmesh.new()
bm.from_mesh(ball.data)
bm.normal_update()
moves = []
for v in bm.verts:
	best = 0.0
	for _, i, _ in lkd.find_range(v.co, 0.16):
		lf = LEAVES[i]
		q = v.co - lf["p"]
		u = q.dot(lf["down"]) / lf["L"]            # -0.35 at the root .. 0.75 at the tip
		w = q.dot(lf["side"]) / (lf["W"] * 0.5) - lf["sk"] * (u + 0.35)  # (a slight lean, like brushed fur)
		t = (u + 0.35) / 1.1
		if not 0.0 <= t <= 1.0:
			continue
		hw = math.sin(math.pi * t ** 0.65)        # widest a third of the way, a pointed tip
		if abs(w) >= hw:
			continue
		h = lf["H"] * t ** 1.7 * (1 - (w / hw) ** 2) ** 0.4
		h -= 0.0016 * abs(math.sin(w * 6.0)) * t  # strands along the leaf
		best = max(best, h)
	moves.append((v, best))
for v, h in moves:
	v.co += v.normal * h
bm.to_mesh(ball.data)
bm.free()
fur_parts = [ball]
# A spiky crown tuft on top of the head, between the ears (the picture's fluffy top).
for k in range(7):
	a = -0.55 + 1.1 * k / 6
	root = BC + Vector((math.sin(a) * 0.09, -0.06 + abs(a) * 0.05, BR.z - 0.03))
	dirn = Vector((math.sin(a) * 0.6, -0.25, 1)).normalized()
	ln = 0.07 + 0.03 * (1 - abs(a) / 0.55)
	fur_parts.append(tube(f"crown{k}", [(root, 0.022, 0.012), (root + dirn * ln * 0.5, 0.018, 0.01), (root + dirn * ln, 0.003, 0.003)],
		M["fur"], up=Vector((0, -1, 0.2)), sides=6))
# Cheek fluff: tufts sticking out sideways at the sides of the face (the picture's fluffy outline), melted in.
for s in (-1, 1):
	for k in range(4):
		zc = 0.56 + 0.06 * k
		dz = (zc - BC.z) / BR.z
		root = Vector((s * BR.x * math.sqrt(max(0.0, 1 - dz * dz)) * 0.93, BC.y - 0.08 + 0.02 * k, zc))  # (zc is already a height)
		dirn = Vector((s * 1.0, -0.25, -0.35 + 0.15 * k)).normalized()
		ln = 0.07 - 0.008 * abs(k - 1.5)
		fur_parts.append(tube(f"cheek{s}_{k}", [(root - dirn * 0.02, 0.03, 0.016), (root + dirn * ln * 0.5, 0.024, 0.013), (root + dirn * ln, 0.003, 0.003)],
			M["fur"], up=Vector((0, -1, 0)), sides=6))
# Brows: thick fur ridges in a V over the eyes (lower on the nose side: grumpy), and the cheeks round the face.
EYE_R = 0.056
EYES = []
for s in (-1, 1):
	ec = Vector((s * 0.115, -0.172, 0.70))  # (on the bigger face: they bulge a little, like the picture)
	EYES.append((s, ec))
	for k in range(5):  # a brow is a row of short tufts pointing out and up
		t = k / 4
		bp = ec + Vector((s * (-0.045 + 0.1 * t), -0.04 + 0.01 * t, 0.045 + 0.035 * t))
		dirn = Vector((s * 0.9, 0.1, 0.45)).normalized()
		fur_parts.append(tube(f"brow{s}_{k}", [(bp - dirn * 0.02, 0.024, 0.014), (bp + dirn * 0.02, 0.02, 0.012), (bp + dirn * 0.05, 0.004, 0.003)],
			M["fur"], up=Vector((0, -1, 0.3)), sides=6))
	# a cup of fur round the back and sides of the eye, so only its front shows (round 2, owner: the sides showed)
	look = Vector((s * 0.1, -1, 0.02)).normalized()
	fur_parts.append(ell(f"cup{s}", tuple(ec - look * 0.02), (EYE_R * 1.18, EYE_R * 1.18, EYE_R * 1.18), M["fur"], seg=24))
	# a socket rim round the eye (the fur folds round it) and a heavy lid shell over its top
	bpy.ops.mesh.primitive_torus_add(major_radius=EYE_R * 0.95, minor_radius=0.012, major_segments=32, minor_segments=10,
		location=ec + Vector((0, -0.016, 0)), rotation=(math.pi / 2, 0, 0))
	rim = bpy.context.object
	rim.data.materials.append(M["fur"])
	bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
	fur_parts.append(rim)
	bpy.ops.mesh.primitive_uv_sphere_add(segments=40, ring_count=20, radius=EYE_R * 1.12, location=ec)
	lid = bpy.context.object
	lb = bmesh.new()
	lb.from_mesh(lid.data)
	bmesh.ops.bisect_plane(lb, geom=lb.verts[:] + lb.edges[:] + lb.faces[:], plane_co=Vector((0, 0, 0.022)),
		plane_no=Vector((-s * 0.35, -0.12, 1)).normalized(), clear_inner=True)
	lb.to_mesh(lid.data)
	lb.free()
	lid.data.materials.append(M["fur"])
	sol = lid.modifiers.new("t", "SOLIDIFY")
	sol.thickness = 0.016
	sol.offset = -1
	cs._apply_all(lid)
	bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
	fur_parts.append(lid)
fur = cs.melt(fur_parts, voxel=0.007 if GREY else 0.0035, smooth=1, name="fur_high")
# The belly (tan) and the rest (rusty): a colour per point, soft border (the paint multiplies it)
belly_ratio = [cs.lin(P["belly"][0])[i] / cs.lin(P["fur"][0])[i] for i in range(3)]
at = fur.data.color_attributes.new("tint", "FLOAT_COLOR", "POINT")
for v in fur.data.vertices:
	d = Vector(((v.co.x - BC.x) / BR.x, (v.co.y - BC.y) / BR.y, (v.co.z - BC.z) / BR.z)).normalized()
	k = min(1.0, max(0.0, (-d.y - 0.1) / 0.3)) * min(1.0, max(0.0, (0.05 - d.z) / 0.25)) * min(1.0, max(0.0, (0.8 - abs(d.x)) / 0.25))
	k *= 1.0 + 0.15 * noise.noise(v.co * 18)
	k = min(1.0, max(0.0, k))
	at.data[v.index].color = tuple(1 + (belly_ratio[i] - 1) * k for i in range(3)) + (1.0,)

# ---- the eyes: balls painted with a brown iris (the lid and socket are part of the fur above)
eyeballs = []
for s, ec in EYES:
	bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, radius=EYE_R, location=ec)
	e = bpy.context.object
	e.name = f"eyeball{s}"
	e.data.materials.append(M["eye"])
	bpy.ops.object.transform_apply(location=True)
	for p_ in e.data.polygons:
		p_.use_smooth = True
	eyeballs.append(e)

# ---- the pig snout with two nostril holes, the fangs
snout = ell("snout", (0, -0.212, 0.655), (0.062, 0.042, 0.044), M["snout"], seg=24)
for s in (-1, 1):
	hole = ell(f"nostril{s}", (s * 0.022, -0.256, 0.657), (0.012, 0.02, 0.016), M["snout"], seg=12)
	bo = snout.modifiers.new("hole", "BOOLEAN")
	bo.operation = "DIFFERENCE"
	bo.object = hole
	cs._apply_all(snout)
	bpy.data.objects.remove(hole)
fangs = []
for s in (-1, 1):
	fangs.append(claw(f"fang{s}", Vector((s * 0.036, -0.2, 0.62)), Vector((0, -0.3, -1)), 0.055, 0.012, curl=Vector((0, 1, 0))))

# ---- the ears: chiselled slabs, cupped in front, pink inside, leaning out and back
ear_shells, ear_ins = [], []
for s in (-1, 1):
	base = Vector((s * 0.12, 0.03, 0.76))
	upv = Vector((s * 0.42, 0.25, 1)).normalized()
	side = Vector((1, 0, 0)) - upv * upv.x
	side.normalize()
	fwd = side.cross(upv).normalized()
	if fwd.y > 0:
		fwd = -fwd
	H, Wd = 0.31, 0.125  # (wider, rounder tips, a thicker rim: like the picture)
	nu, nv = 6, 9
	vs, fs = [], []
	for face_k, off in ((0, 1), (1, -1)):  # front (cupped) and back surfaces
		for j in range(nv + 1):
			v = j / nv
			hw = Wd * (1.0 - v ** 2.6) ** 0.8 * (0.75 + 0.45 * math.sin(math.pi * min(1.0, v * 1.4)))
			for i in range(nu + 1):
				u = -1 + 2 * i / nu
				dish = 0.022 * (1 - u * u) * math.sin(math.pi * v) if off > 0 else -0.012 * (1 - u * u)
				vs.append(base + upv * H * v + side * hw * u + fwd * (off * 0.02 - dish))
	row = nu + 1
	half = row * (nv + 1)
	for j in range(nv):
		for i in range(nu):
			a = j * row + i
			fs.append((a, a + 1, a + row + 1, a + row))
			fs.append((half + a, half + a + row, half + a + row + 1, half + a + 1))
	for j in range(nv):  # the rim between the two surfaces
		for i in (0, nu):
			a = j * row + i
			fs.append((a, a + row, half + a + row, half + a) if i == 0 else (a, half + a, half + a + row, a + row))
	for i in range(nu):
		fs.append((i, half + i, half + i + 1, i + 1))
	ear_shells.append(mesh_obj(f"ear{s}", vs, fs, M["bone"], smooth=False))  # (flat facets: chiselled, like the picture)
	# the pink inside: a smaller leaf lying in the cup, 3 mm in front of it
	vs2, fs2 = [], []
	for j in range(nv + 1):
		v = 0.06 + 0.8 * j / nv
		hw = 0.72 * Wd * (1.0 - v ** 2.6) ** 0.8 * (0.75 + 0.45 * math.sin(math.pi * min(1.0, v * 1.4)))
		for i in range(nu + 1):
			u = -1 + 2 * i / nu
			dish = 0.022 * (1 - u * u) * math.sin(math.pi * v)
			vs2.append(base + upv * H * v + side * hw * u + fwd * (0.02 - dish + 0.003))
	for j in range(nv):
		for i in range(nu):
			a = j * row + i
			fs2.append((a, a + 1, a + row + 1, a + row))
	inner = mesh_obj(f"earin{s}", vs2, fs2, M["ear_in"], smooth=False)
	sol = inner.modifiers.new("t", "SOLIDIFY")
	sol.thickness = 0.004
	cs._apply_all(inner)
	ear_ins.append(inner)

# ---- the legs (round 2, owner: "4 bubbles"): a thigh out of the fur, a knee, a shin, a padded foot and three jointed
# toes, each ending in a cream claw. Faceted, like the wing bones.
feet, foot_claws = [], []
for s in (-1, 1):
	hip, knee, ankle = Vector((s * 0.1, 0.0, 0.37)), Vector((s * 0.135, -0.035, 0.29)), Vector((s * 0.125, -0.03, 0.235))
	feet.append(tube(f"thigh{s}", [(hip, 0.034, 0.034), (knee, 0.027, 0.027)], M["foot"], up=Vector((0, -1, 0)), sides=6, smooth=False))
	feet.append(tube(f"shin{s}", [(knee, 0.025, 0.025), (ankle, 0.02, 0.02)], M["foot"], up=Vector((0, -1, 0)), sides=6, smooth=False))
	kn = ell(f"knee{s}", knee, (0.03, 0.03, 0.03), M["foot"], seg=8)
	for f_ in kn.data.polygons:
		f_.use_smooth = False
	feet.append(kn)
	pad = ell(f"pad{s}", ankle + Vector((0, -0.012, -0.008)), (0.034, 0.03, 0.022), M["foot"], seg=10)
	for f_ in pad.data.polygons:
		f_.use_smooth = False
	feet.append(pad)
	for k, ang in enumerate((-0.45, 0.0, 0.45)):
		dirn = Vector((math.sin(ang) * 0.7, -math.cos(ang), -0.55)).normalized()
		t0_ = ankle + Vector((0, -0.02, -0.012))
		t1_ = t0_ + dirn * 0.03
		t2_ = t1_ + (dirn + Vector((0, 0, -0.5))).normalized() * 0.024
		feet.append(tube(f"toe{s}{k}", [(t0_, 0.012, 0.011), (t1_, 0.011, 0.01), (t2_, 0.009, 0.008)], M["foot"], up=Vector((0, 0, 1)), sides=6, smooth=False))
		foot_claws.append(claw(f"toeclaw{s}{k}", t2_, (dirn + Vector((0, 0, -1.2))).normalized(), 0.04, 0.009, curl=Vector((0, 1, 0))))
print("body", round(time.time() - t0), "s")


# ---- blink lids (owner, round 2): a thin fur lid per eye, built CLOSED over the ball and turned up into the cup out
# of sight; the game turns it down to blink, shut when he is hit and while he sleeps (MonsterModel._blinks).
BLINK_OPEN = -2.6
BLINKS = []
for s, ec in EYES:
	look = Vector((s * 0.1, -1, 0.02)).normalized()
	bpy.ops.mesh.primitive_uv_sphere_add(segments=40, ring_count=20, radius=EYE_R * 1.04, location=ec)
	bl = bpy.context.object
	bl.name = f"blink_{'l' if s < 0 else 'r'}"
	bb = bmesh.new()
	bb.from_mesh(bl.data)
	bmesh.ops.bisect_plane(bb, geom=bb.verts[:] + bb.edges[:] + bb.faces[:], plane_co=-look * EYE_R * 0.15, plane_no=look, clear_inner=True)
	bb.to_mesh(bl.data)
	bb.free()
	bl.data.materials.append(mat("fur_lid", P["fur"][0]))
	sol = bl.modifiers.new("t", "SOLIDIFY")
	sol.thickness = 0.004
	sol.offset = 1
	cs._apply_all(bl)
	for p_ in bl.data.polygons:
		p_.use_smooth = True
	scene.cursor.location = ec
	cs._select_only(bl)
	bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
	bl.rotation_euler.x = BLINK_OPEN
	BLINKS.append(bl)


# ================================================================== the wings (moving parts) and the folded wings
def W(s, x, z):
	"""A point on the wing for (distance out from the middle, height in the picture's front view). Round 2 (owner):
	the wings lie level with the ground when he flies, so the picture's height becomes front-to-back: the top edge
	(arm and wrist) leads in front, the claws trail behind, the outer part sweeps back and tilts up a little."""
	out = min(1.0, max(0.0, (x - 0.24) / 0.16))
	out = out * out * (3 - 2 * out)
	y = 0.03 - 0.8 * (z - 0.62) + 0.12 * max(0.0, x - 0.22) * out
	h = 0.66 + (0.1 * max(0.0, x - 0.22) - 0.05 * max(0.0, x - 0.62)) * out
	return Vector((s * x, y, h))


def wing_normal(s, x, z):
	e = 0.01
	return (W(s, x + e, z) - W(s, x, z)).cross(W(s, x, z + e) - W(s, x, z)).normalized() * -s


def bone(name, pts, r0, r1, s):
	"""A chunky faceted bone through points (in wing coordinates), with knuckles at its ends."""
	ps = [W(s, x, z) for x, z in pts]
	n = wing_normal(s, *pts[0])
	rings = [(p, r0 + (r1 - r0) * i / (len(ps) - 1), r0 + (r1 - r0) * i / (len(ps) - 1)) for i, p in enumerate(ps)]
	objs = [tube(name, rings, M["bone"], up=n, sides=6, smooth=False)]
	for k, p in enumerate((ps[0], ps[-1])):
		r = (r0 if k == 0 else r1) * 1.35
		kn = ell(f"{name}_knuckle{k}", p, (r, r, r), M["bone"], seg=8)
		for f in kn.data.polygons:
			f.use_smooth = False
		objs.append(kn)
	return objs


def bez(a, c, b, n=6):
	return [((1 - t) ** 2 * a[0] + 2 * (1 - t) * t * c[0] + t * t * b[0], (1 - t) ** 2 * a[1] + 2 * (1 - t) * t * c[1] + t * t * b[1])
		for t in (i / n for i in range(1, n + 1))]


# (round 8: 12% bigger than the turnaround: the approved picture's wings are bigger next to its fuller body)
SHOULDER, ELBOW, WRIST = (0.22, 0.63), (0.36, 0.82), (0.47, 0.94)
TIP_OUT, TIP_MID, TIP_LOW, FLANK = (0.84, 0.6), (0.7, 0.46), (0.55, 0.39), (0.22, 0.42)


def membrane(s, name, outline2d, m, thick=0.01, rings=7):
	"""The wing skin: the outline (wing coordinates) filled from its middle in rings, given a little thickness
	along the wing's normal and a soft billow (it bellies back between the bones)."""
	c = (sum(p[0] for p in outline2d) / len(outline2d), sum(p[1] for p in outline2d) / len(outline2d))
	n_o = len(outline2d)
	vs, fs = [], []
	for layer, off in enumerate((thick / 2, -thick / 2)):
		vs.append(W(s, *c) + wing_normal(s, *c) * (off + 0.02))
		for r in range(1, rings + 1):
			k = r / rings
			for (x, z) in outline2d:
				px, pz = c[0] + (x - c[0]) * k, c[1] + (z - c[1]) * k
				billow = 0.02 * math.sin(math.pi * k) * (1 - k * 0.3)
				vs.append(W(s, px, pz) + wing_normal(s, px, pz) * (off + billow))
	per = 1 + rings * n_o
	for layer in (0, 1):
		o = layer * per
		for i in range(n_o):
			j = (i + 1) % n_o
			f = (o, o + 1 + i, o + 1 + j)
			fs.append(f if layer == 0 else f[::-1])
			for r in range(rings - 1):
				a, b = o + 1 + r * n_o + i, o + 1 + r * n_o + j
				q = (a, b, b + n_o, a + n_o)
				fs.append(q if layer == 0 else q[::-1])
	outer0, outer1 = 1 + (rings - 1) * n_o, per + 1 + (rings - 1) * n_o
	for i in range(n_o):
		j = (i + 1) % n_o
		fs.append((outer0 + i, outer1 + i, outer1 + j, outer0 + j))
	return mesh_obj(name, vs, fs, m)


def poly(pts, n=4):
	"""Points along a bone's path (its straight pieces), without the first point."""
	out = []
	for a, b in zip(pts, pts[1:]):
		out += [(a[0] + (b[0] - a[0]) * k / n, a[1] + (b[1] - a[1]) * k / n) for k in range(1, n + 1)]
	return out


def bez_part(a, c, b, t0, t1, n):
	"""Part of a curve (from t0 to t1), without its first point."""
	pts = []
	for i in range(1, n + 1):
		t = t0 + (t1 - t0) * i / n
		pts.append(((1 - t) ** 2 * a[0] + 2 * (1 - t) * t * c[0] + t * t * b[0], (1 - t) ** 2 * a[1] + 2 * (1 - t) * t * c[1] + t * t * b[1]))
	return pts


def tag(objs, sec):
	"""Which section of the wing each face belongs to (0 arm, 1 middle web, 2 outer web): kept through the joins and the
	bake, used at the end to cut the wing into its three moving parts."""
	for o in objs:
		a = o.data.attributes.new("wsec", "INT", "FACE")
		for i in range(len(o.data.polygons)):
			a.data[i].value = sec
	return objs


# Owner (Nov 18): "add 2 or 3 more bones" so the wing bends, not one stiff paddle. Three sections, like a real bat's:
# the ARM (upper arm, forearm, the new 4th finger along its outer edge, the thumb, the skin to the body), the MIDDLE web
# (between the 4th and 3rd fingers) and the OUTER web (fingers 1-3' tips). Middle and outer both turn at the wrist.
F3_PATH = [WRIST, (0.51, 0.63), TIP_LOW]
F4 = (0.458, 0.433)                 # where the new 4th finger meets the trailing edge
F4_PATH = [WRIST, (0.47, 0.68), F4]
TRAIL = (TIP_LOW, (0.36, 0.5), FLANK)  # the trailing edge, outer to inner (F4 sits at t = 0.25 on it)
def _on_skin(s, outline, k, t, face):
	"""A point on a section's wing skin, the way membrane() builds it: `k` 0 (its middle) .. 1 (its edge), `t` along its
	outline (0 .. len), `face` +1 top / -1 under; lifted 3 mm off the skin. Returns (point, the skin's normal there)."""
	c = (sum(p[0] for p in outline) / len(outline), sum(p[1] for p in outline) / len(outline))
	n = len(outline)
	i = int(math.floor(t)) % n
	f = t - math.floor(t)
	a, b = outline[i], outline[(i + 1) % n]
	ox, oz = a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f
	px, pz = c[0] + (ox - c[0]) * k, c[1] + (oz - c[1]) * k
	billow = 0.02 * math.sin(math.pi * k) * (1 - k * 0.3)
	nrm = wing_normal(s, px, pz)
	return W(s, px, pz) + nrm * (face * (0.005 + 0.003) + billow), nrm


def wing_glow(s, name, outline, kind, rgb):
	"""Glowing add-ons on one wing section (both faces): "lava" = branching veins running in from its edges (the ember
	bat), "spore" = round glowing spots (the spore bat). One material named glow_* so the game makes it glow."""
	g = bpy.data.materials.get("glow_" + kind) or mat("glow_" + kind, rgb)
	g.node_tree.nodes["Principled BSDF"].inputs["Emission Color"].default_value = (*cs.lin(rgb), 1)
	g.node_tree.nodes["Principled BSDF"].inputs["Emission Strength"].default_value = 1.5
	r = random.Random(sum(ord(ch) * (i + 1) for i, ch in enumerate(name)))  # (the same every build)
	n = len(outline)
	out = []
	for face in (1, -1):
		if kind == "lava":
			for v in range(4):
				t0 = r.uniform(0, n)
				for br in range(2):  # a vein and a branch off it
					k0 = 0.96 if br == 0 else r.uniform(0.6, 0.8)
					t1 = t0 + (r.uniform(-0.6, 0.6) if br else 0.0)
					k1 = r.uniform(0.25, 0.5)
					steps = 9
					rings = []
					for j in range(steps):
						u = j / (steps - 1)
						k = k0 + (k1 - k0) * u
						t = t1 + 0.35 * math.sin(u * 5.0 + v) * (0.4 + u)
						p, nrm = _on_skin(s, outline, k, t, face)
						wid = 0.0055 * (1.0 - 0.6 * u)
						rings.append((p, wid, 0.0022))
					out.append(tube(f"vein_{name}_{face}_{v}{br}", rings, g, up=wing_normal(s, *outline[0]), sides=6, smooth=True))
		else:
			for v in range(7):
				k, t = r.uniform(0.3, 0.88), r.uniform(0, n)
				p, nrm = _on_skin(s, outline, k, t, face)
				rad = r.uniform(0.011, 0.022)
				side = nrm.cross(Vector((0, 0, 1)))
				side = side if side.length > 1e-4 else Vector((1, 0, 0))
				out.append(tube(f"spot_{name}_{face}_{v}", [(p - nrm * 0.0012, rad, rad), (p + nrm * 0.0012, rad, rad)], g,
					up=side.normalized(), sides=10, smooth=True))
	return out


WINGS = {}
for s, side in ((-1, "l"), (1, "r")):
	arm = bone(f"upperarm_{side}", [SHOULDER, ((SHOULDER[0] + ELBOW[0]) / 2 + 0.01, (SHOULDER[1] + ELBOW[1]) / 2), ELBOW], 0.042, 0.037, s)
	arm += bone(f"forearm_{side}", [ELBOW, WRIST], 0.037, 0.034, s)
	arm += bone(f"finger4_{side}", F4_PATH, 0.026, 0.018, s)
	mid = bone(f"finger3_{side}", F3_PATH, 0.027, 0.02, s)
	tip = bone(f"finger1_{side}", [WRIST, (0.66, 0.78), TIP_OUT], 0.03, 0.022, s)
	tip += bone(f"finger2_{side}", [WRIST, (0.59, 0.68), TIP_MID], 0.027, 0.019, s)
	out_a = [SHOULDER, ELBOW, WRIST] + poly(F4_PATH) + bez_part(*TRAIL, 0.25, 1.0, 5) + bez(FLANK, (0.17, 0.52), SHOULDER, 3)[:-1]
	out_m = [WRIST] + poly(F3_PATH) + bez_part(*TRAIL, 0.0, 0.25, 2) + poly(F4_PATH[::-1])[:-1]
	out_t = [WRIST] + bez(WRIST, (0.66, 0.8), TIP_OUT, 5) + bez(TIP_OUT, (0.69, 0.6), TIP_MID, 5) + bez(TIP_MID, (0.58, 0.52), TIP_LOW, 4) 		+ poly(F3_PATH[::-1])[:-1]
	skins = [membrane(s, f"membrane_{side}{k}", o, M["membrane"]) for k, o in enumerate((out_a, out_m, out_t))]
	glows = []  # (ember: lava veins; spore: glowing spots), on both faces of each section's skin
	if "glow" in P:
		for k, o in enumerate((out_a, out_m, out_t)):
			glows += tag(wing_glow(s, f"{side}{k}", o, *P["glow"]), k)
	thumb = claw(f"thumb_{side}", W(s, *WRIST) + Vector((0, -0.02, 0.01)), Vector((-s * 0.25, -1, 0.35)), 0.075, 0.018, curl=Vector((-s, 0, -0.4)))
	c_out = claw(f"tipclaw_out_{side}", W(s, *TIP_OUT), Vector((s * 0.5, 0.7, -0.4)), 0.065, 0.015, curl=Vector((0, 0, -1)))
	c_low = claw(f"tipclaw_low_{side}", W(s, *TIP_LOW), Vector((s * 0.15, 1, -0.4)), 0.06, 0.014, curl=Vector((0, 0, -1)))
	for objs, sec in ((arm + [skins[0], thumb], 0), (mid + [skins[1], c_low], 1), (tip + [skins[2], c_out], 2)):
		tag(objs, sec)
	WINGS[side] = dict(bones=arm + mid + tip, skins=skins, claws=[thumb, c_low, c_out], hinge=W(s, *SHOULDER), wrist=W(s, *WRIST), glows=glows)

# The folded wings (asleep, hanging): a cloak of wing skin round each side of the body, the arm bone along its edge.
FOLDS = {}
for s, side in ((-1, "l"), (1, "r")):
	vs, fs = [], []
	zs = [0.3 + 0.62 * k / 8 for k in range(9)]
	angs = [-1.3 + 2.95 * j / 12 for j in range(13)]  # (round the front too: a wrapped bundle)
	for layer, off in enumerate((0.0, -0.012)):
		for z in zs:
			dz = (z - BC.z) / BR.z
			rr = math.sqrt(max(0.05, 1 - dz * dz))
			for a in angs:
				rx, ry = BR.x * rr * 1.18 + 0.06 + off, BR.y * rr * 1.18 + 0.06 + off  # (clear of the fur's leaf tips)
				vs.append(Vector((s * math.cos(a) * rx, BC.y + math.sin(a) * ry, z)))
	nc = len(angs)
	per = len(zs) * nc
	for i in range(len(zs) - 1):
		for j in range(nc - 1):
			a, b, c, d = i * nc + j, i * nc + j + 1, (i + 1) * nc + j + 1, (i + 1) * nc + j
			fs.append((a, b, c, d))
			fs.append((per + d, per + c, per + b, per + a))
	for i in range(len(zs) - 1):
		for j in (0, nc - 1):
			a, d = i * nc + j, (i + 1) * nc + j
			fs.append((a, d, per + d, per + a))
	for j in range(nc - 1):
		for i in (0, len(zs) - 1):
			a, b = i * nc + j, i * nc + j + 1
			fs.append((a, per + a, per + b, b))
	cloak = mesh_obj(f"cloak_{side}", vs, fs, M["membrane"])
	arm = tube(f"foldarm_{side}", [(Vector((s * 0.24, -0.12, 0.66)), 0.03, 0.03), (Vector((s * 0.29, -0.14, 0.8)), 0.028, 0.028),
		(Vector((s * 0.25, -0.12, 0.93)), 0.025, 0.025)], M["bone"], up=Vector((0, -1, 0)), sides=6, smooth=False)
	thumb = claw(f"foldthumb_{side}", Vector((s * 0.25, -0.12, 0.95)), Vector((-s * 0.3, -0.2, 1)), 0.06, 0.016, curl=Vector((-s, 0, 0)))
	FOLDS[side] = dict(pieces=[cloak, arm, thumb], hinge=W(s, *SHOULDER))
print("shape", round(time.time() - t0), "s")

# ================================================================== paint and bake (the beetle way)


def join_objs(objs, name):
	bpy.ops.object.select_all(action="DESELECT")
	for o in objs:
		o.select_set(True)
	bpy.context.view_layer.objects.active = objs[0]
	if len(objs) > 1:
		bpy.ops.object.join()
	o = bpy.context.view_layer.objects.active
	o.name = name
	return o


ears = join_objs(ear_shells, "ears")
earins = join_objs(ear_ins, "earins")
feet = join_objs(feet, "feet")
cream = join_objs(fangs + foot_claws, "cream")
eyes = join_objs(eyeballs, "eyes")
for side in WINGS:
	WINGS[side]["bones"] = join_objs(WINGS[side]["bones"], f"bones_{side}")
	WINGS[side]["claws"] = join_objs(WINGS[side]["claws"], f"wingclaws_{side}")
	WINGS[side]["skin"] = join_objs(WINGS[side]["skins"], f"membrane_{side}")
	WINGS[side]["glow"] = join_objs(WINGS[side]["glows"], f"wingglow_{side}") if WINGS[side]["glows"] else None  # (not baked: it glows)
	FOLDS[side]["bone"] = join_objs(FOLDS[side]["pieces"][1:], f"foldbone_{side}")
	FOLDS[side]["cloak"] = FOLDS[side]["pieces"][0]


def paint(o, name, key, tile=None, scale=3.0, amount=0.5, **kw):  # (amount: how much of the painted tile shows)
	o.data.materials.clear()
	o.data.materials.append(cs.paint_material(name, *P[key], picture=str(TEX / tile) if tile else None, picture_scale=scale,
		picture_amount=amount * (1.0 if LOOK == "mossy" else 0.35), **kw))


if not GREY:
	cs.carve_chitin(fur, dents=0.002, grain=0.0012, seed=3)
	paint(fur, "paint_fur", "fur", "batv2_fur_tile.png", 3.5, 0.15, strokes=0.16, top_light=0.25, seed=1, tint_attr="tint", grime=0.15,
		ao_local=True, edge=0.8)  # (only the fur shades itself: the wings beside it painted the sides black)
	jobs = []  # (high, low, bake name, size, normal?)

	def small(o, key, name, tile=None, size=512, levels=1, carve=0.0015, scale=3.0, **kw):
		hi = cs.detail_copy(o, levels, o.name + "_high")
		if carve:
			cs.carve_chitin(hi, dents=carve, grain=carve * 0.4, seed=len(jobs) + 5)
		paint(hi, "paint_" + name, key, tile, scale, kw.pop("amount", 0.45), **kw)
		cs.uv_only(o)
		jobs.append((hi, o, name, size, True))
	small(ears, "bone", "ears_baked", "batv2_bone_tile.png", 1024, carve=0.002, scale=4.0, strokes=0.14, edge=0.7, grime=0.25)
	small(earins, "ear_in", "earin_baked", None, 512, carve=0.001, strokes=0.14, edge=0.3)
	small(snout, "snout", "snout_baked", None, 512, levels=2, carve=0.0012, strokes=0.12, edge=0.5)
	small(feet, "foot", "feet_baked", None, 512, carve=0.0015, strokes=0.12, edge=0.6)
	small(cream, "claw", "claws_baked", None, 512, carve=0.0006, strokes=0.08, edge=0.5)
	for side in WINGS:
		w = WINGS[side]
		small(w["bones"], "bone", f"bones_baked_{side}", "batv2_bone_tile.png", 1024, carve=0.0025, scale=5.0, strokes=0.14, edge=0.8, grime=0.3)
		small(w["skin"], "membrane", f"membrane_baked_{side}", "batv2_membrane_tile.png", 1024, levels=1, carve=0.001, scale=2.5, strokes=0.12, edge=0.3,
			amount=0.22)
		small(w["claws"], "claw", f"wingclaws_baked_{side}", None, 256, carve=0.0006, strokes=0.08, edge=0.5)
		f = FOLDS[side]
		small(f["cloak"], "membrane", f"cloak_baked_{side}", "batv2_membrane_tile.png", 512, carve=0.001, scale=2.5, strokes=0.12, edge=0.3)
		small(f["bone"], "bone", f"foldbone_baked_{side}", "batv2_bone_tile.png", 512, carve=0.002, scale=5.0, strokes=0.14, edge=0.8)
	eh = cs.detail_copy(eyes, 2, "eyes_high")
	cs.eye_attrs(eh, lambda sd: (sd * 0.1, -1, 0.02))
	eh.data.materials.clear()
	eh.data.materials.append(cs.paint_eye("paint_eye", iris_out=P["iris"][0], iris_in=P["iris"][1], ring=P["iris"][2], iris_deg=34.0, pupil_deg=19.0, shine_deg=8.0))
	cs.uv_only(eyes)
	print("sculpt", round(time.time() - t0), "s")
	low_fur = cs.game_copy(fur, 14000, "fur_low")
	cs.bake(fur, low_fur, 2048, "fur_baked", ext=0.045)  # (the leaf tips stand 1.5 cm off; a short reach baked black sides)
	for hi, lo, name, size, nrm in jobs:
		cs.bake(hi, lo, size, name, normal=nrm, ext=0.012)
	cs.bake(eh, eyes, 256, "eye_baked", normal=False, ext=0.01)
	eyes.data.materials[0].node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.2  # wet shine
	for o in [fur, eh] + [j[0] for j in jobs]:
		o.hide_set(True)
		o.hide_render = True
	fur = low_fur
	print("bake", round(time.time() - t0), "s")


# ================================================================== the game model: parts at their hinges
def part(objs, name, hinge):
	o = join_objs(objs, name)
	o.data.name = name
	scene.cursor.location = hinge
	cs._select_only(o)
	bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
	return o


final = [part([fur, ears, earins, snout, feet, cream, eyes], "body", (0, 0, 0))]
for bl in BLINKS:  # children of the body: they move with it
	bl.parent = final[0]
	bl.matrix_parent_inverse = final[0].matrix_world.inverted()
	final.append(bl)
def section(o, sec, name):
	"""A copy of the whole wing with only one section's faces (see tag)."""
	import bmesh
	c = o.copy()
	c.data = o.data.copy()
	scene.collection.objects.link(c)
	c.name = name
	c.data.name = name
	b = bmesh.new()
	b.from_mesh(c.data)
	lay = b.faces.layers.int.get("wsec")
	bmesh.ops.delete(b, geom=[f for f in b.faces if f[lay] != sec], context="FACES")
	b.to_mesh(c.data)
	b.free()
	return c


for side in ("l", "r"):
	w = WINGS[side]
	whole = join_objs([w["bones"], w["skin"], w["claws"]] + ([w["glow"]] if w["glow"] else []), f"wholewing_{side}")
	arm_o, mid_o, tip_o = (section(whole, k, n) for k, n in enumerate((f"wing_{side}", f"web_mid_{side}", f"web_tip_{side}")))
	bpy.data.objects.remove(whole)
	arm_o = part([arm_o], f"wing_{side}", w["hinge"])
	mid_o = part([mid_o], f"web_mid_{side}", w["wrist"])  # (both webs turn at the wrist: the middle, then the outer on it)
	tip_o = part([tip_o], f"web_tip_{side}", w["wrist"])
	for child, par in ((mid_o, arm_o), (tip_o, mid_o)):
		child.parent = par
		child.matrix_parent_inverse = par.matrix_world.inverted()
	final += [arm_o, mid_o, tip_o]
	f = FOLDS[side]
	if NOFOLD:
		for o in (f["cloak"], f["bone"]):
			bpy.data.objects.remove(o)
	else:
		final.append(part([f["cloak"], f["bone"]], f"fold_{side}", f["hinge"]))
marker = bpy.data.objects.new("upright", None)  # (tells the game he hangs upside down by his feet, not on his face)
scene.collection.objects.link(marker)
bpy.ops.object.select_all(action="DESELECT")
for o in final + [marker]:
	o.hide_set(False)
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
