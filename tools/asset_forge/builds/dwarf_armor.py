# The dwarf's armor sets, hand-built OVER the finished dwarf body (Claude, Nov 18, 2026; F55, MODEL-RULES Rule 1).
#
#   blender --background --factory-startup --python tools/asset_forge/builds/dwarf_armor.py -- <set> <out.glb> [fast] [review=<pic.png>]
#
# <set>: hide (more sets follow, one at a time: copper, husk, silver, ironshell; docs/design/armor.md).
# fast: plain colours, no painting (shape checks). review=<pic.png>: photos of the dwarf wearing the set (arms down).
#
# How it fits him: the finished body (assets/characters/dwarf/dwarf_body.glb, with its skeleton) is loaded, and each
# piece is sculpted as a shell a set distance off his real surface (like a mould taken from him): the helmet over the
# head and hair, the jerkin over the shirt, the boots over the foot wraps. Every armor point then copies the bones of
# the body point under it (the jerkin moves exactly like the shirt under it, swinging hem included), so it bends with
# him in every animation. The game puts it on the same skeleton (DwarfRig._wear_armor).
#
# Parts are separate meshes per material, named armor_<head|chest|feet>_<material>: leather, fleece, brass, cord.
# Every part touches its piece (rivets sunk into the leather, fleece rolled over the edge). Nothing lies exactly on
# another surface (MODEL-RULES Rule 2): shells keep 3-4 mm clear of the body inside and 7+ mm outside.
#
# Hide set, from assets/concepts/dwarf/dwarf_wearing_leather.png: a padded leather cap with a stitched ridge down the
# middle, brass rivets, fleece round the face and big ear flaps, a strap round the back; a leather jerkin over the shirt
# (the beard falls over it) with two-layer shoulder guards, a strap across the body with a brass buckle, a split hem
# with a rolled edge, stitched seams and a patch; boots with a thick dark sole, a toe cap, crossed laces through brass
# eyelets and a fleece cuff.
import math
import random
import sys
import time
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector, kdtree, noise
from mathutils.bvhtree import BVHTree

HERE = Path(__file__).resolve()
sys.path.insert(0, str(HERE.parents[1]))
sys.path.insert(0, str(HERE.parent))
import creature_kit as ck  # noqa: E402
import creature_sculpt as cs  # noqa: E402
import dwarf_head as dh  # noqa: E402
import kit  # noqa: E402

ROOT = HERE.parents[3]
ARGS = sys.argv[sys.argv.index("--") + 1:]
SET, OUT = ARGS[0], ARGS[1]
FAST = "fast" in ARGS[2:]
REVIEW = next((a[7:] for a in ARGS[2:] if a.startswith("review=")), None)
BODY = ROOT / "assets" / "characters" / "dwarf" / "dwarf_body.glb"
R = random.Random(23)
T0 = time.time()


def log(*a):
	print(f"ARMOR [{time.time() - T0:5.0f}s]", *a, flush=True)


# ---------------------------------------------------------------- the body to fit (Blender: x = his left, -y = front, z up)
ck.reset()
for o in list(bpy.data.objects):
	bpy.data.objects.remove(o, do_unlink=True)
bpy.ops.import_scene.gltf(filepath=str(BODY))
ARM = next(o for o in bpy.context.scene.objects if o.type == "ARMATURE")
BODYM = {o.name: o for o in bpy.context.scene.objects if o.type == "MESH" and o.name.startswith("body_")}
for o in [o for o in bpy.context.scene.objects if o.type == "MESH" and not o.name.startswith("body_")]:
	bpy.data.objects.remove(o, do_unlink=True)  # (the importer's bone-shape ball)


def world_verts(o):
	co = np.empty(len(o.data.vertices) * 3)
	o.data.vertices.foreach_get("co", co)
	co = co.reshape(-1, 3)
	m = np.array(o.matrix_world)
	return co @ m[:3, :3].T + m[:3, 3]


def bvh_of(o):
	vs = [Vector(p) for p in world_verts(o)]
	return BVHTree.FromPolygons(vs, [tuple(p.vertices) for p in o.data.polygons])


BVH = {n: bvh_of(o) for n, o in BODYM.items()}
log("body loaded:", sorted(BODYM))


# ---------------------------------------------------------------- sculpting on a grid (signed distance: negative inside)
def smin(a, b, k):
	return dh._smin(a, b, k)


def smax(a, b, k):
	return -dh._smin(-a, -b, k)


def blur(D, r, passes=2):
	"""A soft copy of a distance grid (box blur, r cells): a shell over the soft copy doesn't copy every lump of the hair
	or every fold of the shirt, like stiff leather laid over them."""
	D = D.astype(np.float64)
	for _ in range(passes):
		for ax in range(3):
			pad = [(0, 0)] * 3
			pad[ax] = (r + 1, r)
			c = np.cumsum(np.pad(D, pad, mode="edge"), axis=ax)
			n = D.shape[ax]
			D = (np.take(c, np.arange(2 * r + 1, 2 * r + 1 + n), axis=ax) - np.take(c, np.arange(n), axis=ax)) / (2 * r + 1)
	return D.astype(np.float32)


class G:
	"""A box of grid points in Blender space (metres) holding a shape as distances (negative inside)."""

	def __init__(self, lo, hi, h):
		self.h, self.lo = h, np.array(lo, float)
		n = np.ceil((np.array(hi, float) - self.lo) / h).astype(int) + 1
		ax = [(self.lo[i] + h * np.arange(n[i])).astype(np.float32) for i in range(3)]
		self.X, self.Y, self.Z = np.meshgrid(*ax, indexing="ij")
		self.D = np.full(tuple(n), 1.0, np.float32)

	def field(self, names, band=0.05, far=None):
		"""Signed distance to the union of body parts: exact within `band` of the surface; further out from a coarse
		grid (every 4th point, exact), or simply `far` when given (only the nearby values matter)."""
		pts = np.stack([self.X.ravel(), self.Y.ravel(), self.Z.ravel()], 1)
		out = np.full(len(pts), np.inf if far is None else far, np.float32)
		coarse = None
		if far is None:
			cs_ = self.X[::4, ::4, ::4].shape
			cp = np.stack([self.X[::4, ::4, ::4].ravel(), self.Y[::4, ::4, ::4].ravel(), self.Z[::4, ::4, ::4].ravel()], 1)
			cv = np.full(len(cp), np.inf, np.float32)
			for n in names:
				t = BVH[n]
				for i, p in enumerate(cp):
					loc, nrm, _, d = t.find_nearest(Vector(p))
					s = d if (Vector(p) - loc).dot(nrm) >= 0 else -d
					cv[i] = min(cv[i], s)
			coarse = cv.reshape(cs_)
		for n in names:
			t = BVH[n]
			for i, p in enumerate(pts):
				v = Vector(p)
				hit = t.find_nearest(v, band)
				if hit[0] is None:
					continue
				d = hit[3] if (v - hit[0]).dot(hit[1]) >= 0 else -hit[3]
				if d < out[i]:
					out[i] = d
		out = out.reshape(self.X.shape)
		if coarse is not None:
			idx = [np.minimum(np.arange(s) // 4, coarse.shape[k] - 1) for k, s in enumerate(self.X.shape)]
			up = coarse[np.ix_(*idx)]
			miss = ~np.isfinite(out)
			out[miss] = np.where(up[miss] < 0, np.minimum(up[miss], -band), np.maximum(up[miss], band))
		return out

	def tube(self, a, b, r0, r1):
		a, b = np.array(a, np.float32), np.array(b, np.float32)
		ba = b - a
		px, py, pz = self.X - a[0], self.Y - a[1], self.Z - a[2]
		t = np.clip((px * ba[0] + py * ba[1] + pz * ba[2]) / float(ba @ ba), 0.0, 1.0)
		d = np.sqrt((px - ba[0] * t) ** 2 + (py - ba[1] * t) ** 2 + (pz - ba[2] * t) ** 2)
		return d - (r0 + (r1 - r0) * t)

	def mesh(self, name, mat, D=None, min_island=60):
		D = (self.D if D is None else D).copy()
		for ax in range(3):  # closed off where it reaches the grid's edge
			sl = [slice(None)] * 3
			for end in (0, -1):
				sl[ax] = end
				D[tuple(sl)] = np.maximum(D[tuple(sl)], self.h)
		v, q = dh.surface_nets(D, self.lo, self.h)
		o = kit._mesh_obj(name, v.tolist(), q.tolist(), mat)
		ck._fix_normals(o)
		drop_crumbs(o, min_island)
		return o


def drop_inside(o, names, gap=0.0058):
	"""Remove the shell's inside surface (the faces lying against the body, hidden under it). Round 4: on the jerkin it
	took half the painted picture, so the outside came out blurry, and it made the copy too big to smooth."""
	bm = bmesh.new()
	bm.from_mesh(o.data)
	mw = o.matrix_world
	gone = []
	for f in bm.faces:
		c = mw @ f.calc_center_median()
		near = min(BVH[n].find_nearest(c, gap)[3] or 9.0 for n in names)
		if near < gap:
			gone.append(f)
	bmesh.ops.delete(bm, geom=gone, context="FACES")
	bm.to_mesh(o.data)
	bm.free()
	drop_crumbs(o, 60)
	log("inside faces removed:", len(gone), "left:", len(o.data.polygons))


def drop_crumbs(o, n):
	"""Remove tiny loose bits (a few grid cells the shape only just touched): every part must be a real part."""
	small = [i for isl in cs.islands(o) if len(isl) < n for i in isl]
	if small:
		bm = bmesh.new()
		bm.from_mesh(o.data)
		bm.verts.ensure_lookup_table()
		bmesh.ops.delete(bm, geom=[bm.verts[i] for i in small], context="VERTS")
		bm.to_mesh(o.data)
		bm.free()


def wobble(g, amp, seed):
	"""A hand-made unevenness (a few slow waves): no part is perfectly even."""
	r = random.Random(seed)
	w = np.zeros_like(g.D)
	for _ in range(4):
		k = [r.uniform(8, 22) for _ in range(3)]
		ph = [r.uniform(0, 6.3) for _ in range(3)]
		w += np.sin(k[0] * g.X + ph[0]) * np.sin(k[1] * g.Y + ph[1]) * np.sin(k[2] * g.Z + ph[2])
	return (amp / 2.0) * w


def lumps(g, amp, per, seed):
	"""Small round lumps (fleece curls)."""
	r = random.Random(seed)
	w = np.zeros_like(g.D)
	for _ in range(3):
		a = [r.uniform(0, 6.3) for _ in range(3)]
		k = 2 * math.pi / per * r.uniform(0.8, 1.25)
		w += np.sin(k * g.X + a[0]) * np.sin(k * g.Y + a[1]) * np.sin(k * g.Z + a[2])
	return amp * w / 3.0


# ---------------------------------------------------------------- small hard pieces (rivets, buckles, eyelets)
def ray_to(target_bvh, origin, direction):
	"""Where a ray from `origin` hits the piece: (point, outward normal) or None."""
	hit = target_bvh.ray_cast(Vector(origin), Vector(direction).normalized())
	if hit[0] is None:
		return None
	n = hit[1] if hit[1].dot(Vector(direction)) < 0 else -hit[1]
	return hit[0], n


def frame_at(n, along=None):
	n = Vector(n).normalized()
	t = (Vector(along) if along is not None else Vector((0, 0, 1))).normalized()
	t = (t - n * t.dot(n))
	if t.length < 1e-4:
		t = Vector((1, 0, 0)) - n * n.x
	t.normalize()
	return t, n.cross(t), n


def small_piece(name, mat, items, h=0.0011):
	"""Hard little parts, each a clay shape on its own small grid around it: items = [(centre, normal, along, kind, size)].
	kind: 'rivet' (a domed head), 'ring' (an eyelet), 'buckle' (a chunky frame with its pin). Joined into one mesh."""
	parts = []
	if not items:
		return None
	for c, n, along, kind, size in items:
		t, b, n = frame_at(n, along)
		ext = size * 1.6 + 0.004
		g = G((-ext, -ext, -ext * 0.7), (ext, ext, ext * 0.9), h)
		U, V, W = g.X, g.Y, g.Z  # local: u along, v across, w out of the surface
		j = R.uniform(0.9, 1.1)
		if kind == "rivet":
			x, y, z = U / (size * j), V / (size * R.uniform(0.9, 1.1)), (W + size * 0.25) / (size * 0.75)
			g.D = (np.sqrt(x * x + y * y + z * z) - 1.0) * size * 0.7
		elif kind == "ring":
			rad = np.sqrt(U * U + V * V)
			g.D = np.sqrt((rad - size * 0.7) ** 2 + (W * 1.3) ** 2) - size * 0.32
		elif kind == "buckle":
			hw, hh, r = size, size * 0.72, size * 0.2  # a rounded rectangle frame, a bar across the middle
			qx, qy = np.abs(U) - hw, np.abs(V) - hh
			box = np.sqrt(np.maximum(qx, 0) ** 2 + np.maximum(qy, 0) ** 2) + np.minimum(np.maximum(qx, qy), 0)
			frame = np.sqrt(np.abs(box + r * 0.6) ** 2 + (W - r * 0.3) ** 2) - r
			bar = np.sqrt(U * U + (W - r * 0.4) ** 2) - r * 0.75
			bar = np.maximum(bar, np.abs(V) - hh)
			pin = np.sqrt((V + hh * 0.05) ** 2 + (W - r * 1.1) ** 2) - r * 0.45
			pin = np.maximum(pin, np.maximum(-U, U - hw * 1.05))
			g.D = np.minimum(np.minimum(frame, bar), pin)
		g.D = g.D + wobble(g, size * 0.04, R.randint(0, 999))
		o = g.mesh(f"_{name}_{len(parts)}", mat, min_island=8)
		m = Matrix(((t.x, b.x, n.x, c[0]), (t.y, b.y, n.y, c[1]), (t.z, b.z, n.z, c[2]), (0, 0, 0, 1)))
		o.data.transform(m)
		parts.append(o)
	bpy.ops.object.select_all(action="DESELECT")
	for o in parts:
		o.select_set(True)
	bpy.context.view_layer.objects.active = parts[0]
	if len(parts) > 1:
		bpy.ops.object.join()
	o = bpy.context.view_layer.objects.active
	o.name = name
	ck._fix_normals(o)
	return o


# ---------------------------------------------------------------- the colours (plain while shaping, painted after)
def plain(name, rgb):
	"""A plain colour that also shows in the textured photos (a tiny one-colour picture)."""
	m = ck.color(name, rgb)
	img = bpy.data.images.new(f"plain_{name}", 4, 4)
	img.pixels[:] = [*rgb, 1.0] * 16
	nt = m.node_tree
	tn = nt.nodes.new("ShaderNodeTexImage")
	tn.image = img
	bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
	nt.links.new(tn.outputs["Color"], bsdf.inputs["Base Color"])
	nt.nodes.active = tn
	return m


MAT = {k: plain(k, c) for k, c in {
	"leather": (0.45, 0.28, 0.16), "fleece": (0.86, 0.77, 0.6), "brass": (0.8, 0.6, 0.26), "cord": (0.74, 0.62, 0.44)}.items()}
PAINT = {
	"leather": dict(base=(0.47, 0.29, 0.16), dark=(0.2, 0.11, 0.05), light=(0.6, 0.4, 0.24), strokes=0.1),  # (round 4: the pale edge colour washed the shoulders pink)
	"fleece": dict(base=(0.86, 0.77, 0.6), dark=(0.48, 0.38, 0.26), light=(0.98, 0.93, 0.8), strokes=0.08),
	"brass": dict(base=(0.8, 0.59, 0.25), dark=(0.33, 0.2, 0.06), light=(1.0, 0.92, 0.62), strokes=0.06),
	"cord": dict(base=(0.74, 0.62, 0.44), dark=(0.4, 0.3, 0.18), light=(0.92, 0.84, 0.66), strokes=0.06),
}
# hand-painted tiles from the set's ChatGPT sheet (assets/concepts/outfits/armor_<set>_sheet.png, cut by
# tools/art/cut_armor_tiles.py; owner, round 2: "better texture, like the rock"): [tile, repeats per metre]
TEX = ROOT / "assets" / "textures" / "armor"
PICTURE = {
	("leather", "head"): ["leather", 5.0], ("leather", "chest"): ["hide2_worn", 6.0], ("leather", "feet"): ["leather_red", 6.0],
	("fleece", None): ["fleece", 11.0], ("brass", None): ["brass", 18.0],
}
PIECES = []  # (object, piece "head"/"chest"/"feet", material, tint function or None, displacement function or None)


def stitch_band(dist_in, phase, inset=0.009, width=0.0026, dash=0.007):
	"""Light dashed stitches `inset` in from an edge (dist_in: how far inside the edge, metres; phase: distance along)."""
	on = np.abs(dist_in - inset) < width / 2
	return on & (np.sin(phase * 2 * math.pi / dash) > -0.1)


# ================================================================ HIDE set
HC = Vector((0.0, 0.02, 1.08))  # the skull's middle at eye level (dwarf_head.C)


def helm_region(X, Y, Z):
	"""Where the cap is, as a distance on the head's surface map (s = metres round the head from the front, z = height;
	negative inside): the top above the brows, big flaps over the ears down to the jaw, the back down to the nape."""
	th = np.arctan2(X, -(Y - HC.y))
	S = np.abs(th) * 0.14
	top = 1.152 - 0.55 * S ** 2 + 0.003 * np.cos(th * 5) - Z  # an arch over the brows (round 1: a straight line)
	back = np.maximum(0.30 - S, 1.03 - Z)
	qx, qz = np.abs(S - 0.222) - 0.016, np.abs(Z - 1.07) - 0.026  # round-ended ear flaps
	flap = np.sqrt(np.maximum(qx, 0) ** 2 + np.maximum(qz, 0) ** 2) + np.minimum(np.maximum(qx, qz), 0) - 0.058
	return smin(smin(top, back, 0.02), flap, 0.04), S


def panel_seam(X, Y):
	"""How far (metres) from the nearest of the six seams running up the cap from the edge to the crown."""
	th = np.arctan2(X, -(Y - HC.y))
	ang = np.abs(((th + math.pi) % (math.pi / 3)) - math.pi / 6)
	return (math.pi / 6 - ang) * np.sqrt(X ** 2 + (Y - HC.y) ** 2)


DOME_C = Vector((0.0, 0.035, 1.07))
DOME = {}
SKULL_C, SKULL_R = np.array((0.0, 0.026, 1.075)), np.array((0.119, 0.11, 0.117))  # (dwarf_head.SKULL, as one egg)


def capped_head():
	"""Hat hair: a copy of the head whose hair under the cap is pressed in close to the skull (his wild ring of locks is
	45 cm across: a cap holding all of it was a 45 cm box). Hair further than 1.8 cm off the skull is squeezed into
	that space, fully under the cap and fading out over 4 cm past its edge (the hair below puffs out as before). The
	face, brows and beard stay as they are. The game shows this head instead of the normal one while a helmet is on;
	same points, same bones, same painted pictures (DwarfRig._wear_armor)."""
	src = BODYM["body_head"]
	o = src.copy()
	o.data = src.data.copy()
	o.name = "armor_head_hair"
	bpy.context.scene.collection.objects.link(o)
	co = world_verts(o)
	v = co - SKULL_C
	r = np.linalg.norm(v, axis=1)
	dn = v / np.maximum(r, 1e-9)[:, None]
	rs = 1.0 / np.sqrt(((dn / SKULL_R) ** 2).sum(1))
	e = r - rs
	reg, S = helm_region(co[:, 0], co[:, 1], co[:, 2])
	w = 1.0 - np.clip((reg + 0.01) / 0.05, 0, 1) ** 2 * (3 - 2 * np.clip((reg + 0.01) / 0.05, 0, 1))
	face = (S < 0.17) & (co[:, 2] < 1.16)  # the brows and the face below the cap's front edge never move
	w[face] *= np.clip((co[:, 2][face] - 1.13) / 0.03, 0, 1)
	w[co[:, 2] < 0.95] = 0.0
	emax = 0.018
	e2 = np.where(e > 0, emax * (1 - np.exp(-np.maximum(e, 0) / emax)), e)
	r2 = rs + e + w * (e2 - e)
	new = SKULL_C + dn * r2[:, None]
	m = np.array(o.matrix_world.inverted())
	loc = new @ m[:3, :3].T + m[:3, 3]
	o.data.vertices.foreach_set("co", loc.ravel())
	o.data.update()
	BODYM["armor_head_hair"] = o  # (measured like a body part: the cap fits over it)
	BVH["armor_head_hair"] = bvh_of(o)
	log("hat hair: points moved", int((np.abs(r2 - r) > 0.002).sum()), "of", len(r), "; most", round(float(np.max(r - r2)), 3), "m")
	return o


def dome_reach():
	"""The head's reach (metres from DOME_C) on a grid of directions (round the head x from the crown down)."""
	v = world_verts(BODYM["armor_head_hair"])
	v = v[v[:, 2] > 1.0] - np.array(DOME_C)  # (only what the cap covers: the long beard made it a tall box)
	r = np.linalg.norm(v, axis=1)
	az = np.arctan2(v[:, 0], -v[:, 1])
	pol = np.arccos(np.clip(v[:, 2] / np.maximum(r, 1e-9), -1, 1))
	na, npol = 48, 24
	ia = ((az + math.pi) / (2 * math.pi) * na).astype(int) % na
	ip = np.minimum((pol / math.pi * npol).astype(int), npol - 1)
	reach = np.zeros((na, npol))
	np.maximum.at(reach, (ia, ip), r)
	for _ in range(2):  # the biggest reach nearby (conservative), then smoothed
		reach = np.maximum.reduce([np.roll(reach, k, 0) for k in (-1, 0, 1)])
		reach[:, 1:-1] = np.maximum(reach[:, 1:-1], np.maximum(reach[:, :-2], reach[:, 2:]))  # (no wrapping top to bottom)
	for _ in range(3):
		reach = (np.roll(reach, 1, 0) + np.roll(reach, -1, 0) + 2 * reach) / 4
		reach[:, 1:-1] = (reach[:, :-2] + reach[:, 2:] + 2 * reach[:, 1:-1]) / 4
	reach[:, 0] = reach[:, 0].max()  # one value at the very top
	DOME["reach"], DOME["na"], DOME["np"] = reach, na, npol


def dome_dist(X, Y, Z):
	vx, vy, vz = X - DOME_C.x, Y - DOME_C.y, Z - DOME_C.z
	r = np.sqrt(vx * vx + vy * vy + vz * vz)
	az = (np.arctan2(vx, -vy) + math.pi) / (2 * math.pi) * DOME["na"] - 0.5
	pol = np.arccos(np.clip(vz / np.maximum(r, 1e-9), -1, 1)) / math.pi * DOME["np"] - 0.5
	a0 = np.floor(az).astype(int)
	p0 = np.clip(np.floor(pol).astype(int), 0, DOME["np"] - 2)
	fa, fp = az - np.floor(az), np.clip(pol - p0, 0, 1)
	re = DOME["reach"]
	na = DOME["na"]
	val = ((re[a0 % na, p0] * (1 - fa) + re[(a0 + 1) % na, p0] * fa) * (1 - fp)
		+ (re[a0 % na, p0 + 1] * (1 - fa) + re[(a0 + 1) % na, p0 + 1] * fa) * fp)
	return r - (val + 0.013)


def build_helmet():
	log("helmet: measuring the head")
	hair = capped_head()
	dome_reach()
	g = G((-0.215, -0.19, 0.95), (0.215, 0.235, 1.29), 0.004)
	# (how close the head is, not inside/outside: the hair locks' surfaces fooled the inside test into spikes and lumps)
	d = np.abs(g.field(["armor_head_hair"], band=0.05, far=0.05))
	reg, S = helm_region(g.X, g.Y, g.Z)
	# A padded dome just outside the hair: how far the head reaches in every direction from the skull's middle, the
	# biggest nearby reach taken and smoothed, plus 1.3 cm. (Round 1 followed every lump of the hair ring: a flat-topped
	# box; round 2's plain egg let the hair ring poke through as lumps at the back.)
	outer = np.minimum(dome_dist(g.X, g.Y, g.Z), d - 0.009) + wobble(g, 0.002, 1)
	leather = np.maximum(outer, reg)
	# the stitched ridge over the top, front to back, and the strap round the back of the head
	ridge = np.maximum(np.maximum(np.abs(g.X) - 0.019, outer - 0.006), reg)
	strap = np.maximum(np.maximum(np.abs(g.Z - 1.062) - 0.015, outer - 0.005), np.maximum(reg, 0.29 - S))
	leather = smin(smin(leather, ridge, 0.003), strap, 0.003)
	# fleece rolled over every edge (the face, the flaps, the nape), kept off the skin
	fleece = np.sqrt(reg ** 2 + (outer + 0.006) ** 2) - 0.0135 + lumps(g, 0.0025, 0.016, 2)
	fleece = np.maximum(fleece, 0.004 - d)
	lo = g.mesh("armor_head_leather", MAT["leather"], leather)
	fl = g.mesh("armor_head_fleece", MAT["fleece"], fleece)
	# brass rivets down the ridge and along the back strap
	tb = bvh_of(lo)
	items = []
	for a in np.linspace(0.45, 2.75, 9):
		dirn = Vector((0, -math.cos(a), math.sin(a)))
		hit = ray_to(tb, HC + dirn * 0.4, -dirn)
		if hit:
			items.append((hit[0] - hit[1] * 0.0012, hit[1], Vector((0, math.sin(a), math.cos(a))), "rivet", 0.0062))
	for th in (2.25, 2.62, -2.25, -2.62):
		dirn = Vector((math.sin(th), -math.cos(th), 0))
		hit = ray_to(tb, Vector((HC.x, HC.y, 1.062)) + dirn * 0.4, -dirn)
		if hit:
			items.append((hit[0] - hit[1] * 0.0012, hit[1], Vector((0, 0, 1)), "rivet", 0.0068))
	br = small_piece("armor_head_brass", MAT["brass"], items)

	def tint(co):
		th = np.arctan2(co[:, 0], -(co[:, 1] - HC.y))
		reg_, S_ = helm_region(co[:, 0], co[:, 1], co[:, 2])
		panel = np.floor((th + math.pi) / (math.pi / 3)).astype(int) % 6  # six panels round the cap
		shade = np.array([1.0, 0.86, 1.08, 0.93, 1.04, 0.9])[panel]
		rgb = np.stack([shade, shade * 0.98, shade * 0.95], 1)
		seam = panel_seam(co[:, 0], co[:, 1]) < 0.0022
		st = stitch_band(-reg_, S_ + co[:, 2]) | (stitch_band(0.019 - np.abs(co[:, 0]), co[:, 1], inset=0.004) & (reg_ < -0.01))
		rgb[seam] *= 0.6
		rgb[st] = np.array([1.55, 1.42, 1.2])
		return rgb

	def disp(q, n):
		seam = float(panel_seam(np.array([q.x]), np.array([q.y]))[0])
		return 0.00045 * noise.fractal(q * 160, 0.6, 2.0, 3) + 0.0012 * noise.noise(q * 22) - 0.0011 * math.exp(-(seam / 0.002) ** 2)

	PIECES.extend([(lo, "head", "leather", tint, disp), (fl, "head", "fleece", None, None), (br, "head", "brass", None, None)])


def jerkin_region(X, Y, Z):
	th = np.arctan2(X, -(Y - 0.0))
	# (round 2, owner: "the white shirt is sticking out": the hem now comes down past the shirt's, and short leather
	# sleeves cover the shirt's sleeves; round 1 stopped at the shoulders and above the shirt's hem, with slits)
	hem = 0.388 - 0.022 * np.clip(np.cos(th), 0, None) ** 2 + 0.004 * np.sin(5 * th + 1.0)
	reg = np.maximum(hem - Z, Z - 0.905)
	neck = np.maximum(np.sqrt(X ** 2 + (Y - 0.025) ** 2 * 1.15) - 0.13, 0.84 - Z)
	reg = np.maximum(reg, np.abs(X) - (0.405 + 0.004 * np.sin(Z * 60)))  # the sleeve ends, past the shirt's (0.39)
	reg = np.maximum(reg, -neck)
	return reg, th, hem


SEAMS = (0.62, -0.62, 1.75, -1.75, 2.6, -2.6)  # the jerkin's panel seams (angle round the body, 0 = front)
YOKE, BELT = 0.752, 0.478  # heights: the seam across the chest and back, the belt's middle


def jerkin_seams(X, Y, Z):
	"""How far (metres) from the nearest panel seam: up the body between panels, and across under the shoulders."""
	th = np.arctan2(X, -Y)
	d = np.full(np.shape(X), 1.0)
	for a in SEAMS:
		d = np.minimum(d, np.abs(((th - a + math.pi) % (2 * math.pi)) - math.pi) * 0.24)
	d = np.where(Z > YOKE + 0.004, np.minimum(d, 1.0), d)  # (the vertical seams stop at the yoke)
	d = np.where(Z > YOKE, 1.0, d)
	return np.minimum(d, np.abs(Z - YOKE) + np.where(np.abs(X) > 0.3, 1.0, 0.0))


STRAP = (Vector((-0.215, 0.0, 0.885)), Vector((0.235, 0.0, 0.47)))  # across the body: his right shoulder to his left hip


def strap_dist(X, Z):
	a, b = STRAP
	dx, dz = b.x - a.x, b.z - a.z
	ln = math.hypot(dx, dz)
	return ((X - a.x) * dz - (Z - a.z) * dx) / ln


POUCH = []


def pad_zone(X, Z):
	"""The shoulder pads (round 6, owner: on the shoulders the diamonds stretched into lines, "you don't see the squares"):
	a different kind of leather there, overlapping strips going down the arm."""
	return (np.abs(X) > 0.235) & (Z > 0.7)


def pad_strips(X, Y, Z):
	"""Where on its strip each point is (0 at a strip's inner edge, 1 at its outer edge): bands 3.2 cm wide running across
	the arm, front to back over the shoulder, one after another from the neck out toward the elbow, each overlapping
	the next (owner, round 7, drew the lines on a picture; round 6's rings round the shoulder top were wrong)."""
	return ((np.abs(X) - 0.235) / 0.032) % 1.0


QUILT = 0.075  # the quilted diamonds' size (metres; 5 cm looked small and busy on him)


def quilt(X, Y, Z):
	"""Diamond quilting (owner, round 5: a picture of quilted leather armor; "we're going around in circles"): how far
	(metres) each point is from the nearest stitched groove, and the puff (0 at a groove, 1 in a diamond's middle).
	Diamonds run round the body (arc length) and up it, so they stay the same size everywhere."""
	s_ = np.arctan2(X, -Y) * 0.25
	u, v = (s_ + Z) / QUILT, (s_ - Z) / QUILT
	fu, fv = np.abs(u - np.round(u)), np.abs(v - np.round(v))
	gd = np.minimum(fu, fv) * QUILT / math.sqrt(2)
	puff = np.sqrt(np.clip(np.minimum(fu, fv) * 2, 0, 1))
	plain = (np.abs(Z - BELT) < 0.03) | (Z < 0.405) | pad_zone(X, Z)  # (the belt, the rolled hem and the shoulder pads)
	return np.where(plain, 1.0, gd), np.where(plain, 1.0, puff)


def build_jerkin():
	log("jerkin: measuring the shirt")
	g = G((-0.475, -0.36, 0.33), (0.475, 0.32, 0.965), 0.004)
	# the shirt and the shorts' top; the bare skin only out on the arms past the shirt's sleeves (round 2 used the skin
	# everywhere: its inside/outside test failed in places and cut round holes in the jerkin, showing the shirt)
	d = g.field(["body_shirt", "body_shorts"])
	arms = np.abs(g.X) > 0.36
	if arms.any():
		d[arms] = np.minimum(d[arms], g.field(["body_torso"], band=0.05, far=0.05)[arms])
	dbeard = g.field(["body_head"], band=0.03, far=0.03)
	soft = blur(d, 3)
	reg, th, hem = jerkin_region(g.X, g.Y, g.Z)
	t_ = 0.017 + wobble(g, 0.0015, 3)  # (round 3: thicker, owner: "is this like a leather armor?")
	outer = np.minimum(soft - t_, d - 0.008)
	jerk = np.maximum(np.maximum(outer, 0.003 - d), reg)
	lip = np.sqrt((g.Z - hem) ** 2 + (soft - t_ + 0.002) ** 2) - 0.0075  # a rolled bottom edge
	lip = np.maximum(np.maximum(lip, reg - 0.008), 0.003 - d)
	jerk = smin(jerk, lip, 0.004)
	# Round 3 (owner: the tunic is "just blurry", "is this like a leather armor?"; picked "stitched jerkin"): thick panels
	# with deep grooves between them, a raised stitched welt along each side of every groove, a wide belt and a pouch.
	sea = jerkin_seams(g.X, g.Y, g.Z)
	surf = soft - t_
	groove = smax(sea - 0.005, -0.007 - surf, 0.002)
	jerk = smax(jerk, -groove, 0.0025)
	welt = np.maximum(np.maximum(np.abs(sea - 0.0095) - 0.0032, surf - 0.0022), np.maximum(reg, 0.003 - d))
	jerk = smin(jerk, welt, 0.0015)
	belt = np.maximum(np.maximum(np.abs(g.Z - BELT) - 0.026, surf - 0.008), np.maximum(reg, 0.003 - d))
	jerk = smin(jerk, belt, 0.002)
	hit = BVH["body_shirt"].ray_cast(Vector((0.17, -0.6, 0.425)), Vector((0, 1, 0)))
	if hit[0] is not None:  # a pouch hanging from the belt on his left hip
		pc, pn = hit[0], (hit[1] if hit[1].y < 0 else -hit[1])
		t1, b1, n1 = frame_at(pn, (0, 0, 1))
		c = pc + n1 * 0.028
		qx = np.abs((g.X - c.x) * b1.x + (g.Y - c.y) * b1.y + (g.Z - c.z) * b1.z) - 0.042
		qy = np.abs((g.X - c.x) * t1.x + (g.Y - c.y) * t1.y + (g.Z - c.z) * t1.z) - 0.036
		qz = np.abs((g.X - c.x) * n1.x + (g.Y - c.y) * n1.y + (g.Z - c.z) * n1.z) - 0.014
		pouch = np.sqrt(np.maximum(qx, 0) ** 2 + np.maximum(qy, 0) ** 2 + np.maximum(qz, 0) ** 2) + np.minimum(np.maximum(np.maximum(qx, qy), qz), 0) - 0.012
		jerk = smin(jerk, pouch + wobble(g, 0.002, 9), 0.006)
		POUCH[:] = [c + n1 * 0.026 + t1 * 0.02, n1]
	# the shoulder guards: a big top plate and a lower one further down the arm, under it
	for sx in (1, -1):
		# (round 1 reached down round the whole sleeve: they only cap the top of the shoulder)
		for c, r, zmin, o_in, o_out in (((0.365 * sx, 0.035, 0.79), 0.085, 0.765, 0.010, 0.023), ((0.295 * sx, 0.035, 0.81), 0.105, 0.775, 0.010, 0.031)):
			rr = np.sqrt((g.X - c[0]) ** 2 + (g.Y - c[1]) ** 2 * 0.9 + (g.Z - c[2]) ** 2) - r
			plate = np.maximum(np.maximum(soft - o_out, o_in - d), smax(rr, zmin - g.Z + 0.03 * (np.abs(g.X) - 0.3), 0.01))
			jerk = np.minimum(jerk, plate)
			rim = np.maximum(np.maximum(np.abs(rr + 0.01) - 0.0035, soft - o_out - 0.0025), np.maximum(o_in - d, zmin - g.Z))
			jerk = smin(jerk, rim, 0.0015)  # (round 4: a raised rim round each plate, owner: "the shoulders have nothing")
	# the strap across the body (front and back), raised over the leather
	sd = strap_dist(g.X, g.Z)
	band = np.maximum(np.maximum(np.abs(sd) - 0.023, soft - t_ - 0.006), np.maximum(reg - 0.0, 0.003 - d))
	jerk = smin(jerk, band, 0.002)
	jerk = np.maximum(jerk, 0.0035 - dbeard)  # under the beard and the back hair (they lie on top: the beard falls over it)
	lo = g.mesh("armor_chest_leather", MAT["leather"], jerk)
	drop_inside(lo, ["body_shirt", "body_shorts"] + (["body_torso"]))
	tb = bvh_of(lo)
	items = []
	a, b = STRAP
	for f, frontside in ((0.74, True), (0.3, False)):  # a buckle on the strap, front and back
		p = a.lerp(b, f)
		y0 = -0.5 if frontside else 0.5
		hit = ray_to(tb, (p.x, y0, p.z), (0, -y0, 0))
		if hit:
			items.append((hit[0] - hit[1] * 0.002, hit[1], (b - a), "buckle", 0.021))
	hit = ray_to(tb, (0.07, -0.6, BELT), (0, 1, 0))
	if hit:  # the belt's buckle
		items.append((hit[0] - hit[1] * 0.002, hit[1], (1, 0, 0), "buckle", 0.026))
	if POUCH:
		items.append((POUCH[0], POUCH[1], None, "rivet", 0.007))
	for k in range(14):  # rivets along the belt
		a = -2.9 + k * 0.42
		dirn = Vector((math.sin(a), -math.cos(a), 0))
		hit = ray_to(tb, Vector((0, 0.0, BELT)) + dirn * 0.6, -dirn)
		if hit and abs(a - 0.25) > 0.25:
			items.append((hit[0] - hit[1] * 0.0012, hit[1], None, "rivet", 0.0055))
	for sx in (1, -1):  # rivets round the top plate's edge and on the lower plate
		for ang, rad, cz in ((-0.9, 0.105, 0.80), (0.0, 0.11, 0.80), (0.9, 0.105, 0.80), (-0.6, 0.085, 0.77), (0.6, 0.085, 0.77)):
			c = Vector((0.31 * sx if rad > 0.09 else 0.39 * sx, 0.035, cz))
			dirn = Vector((math.sin(0.5) * sx * 0.6, -math.sin(ang), math.cos(ang))).normalized()
			hit = ray_to(tb, c + dirn * 0.4, -dirn)
			if hit:
				items.append((hit[0] - hit[1] * 0.0012, hit[1], None, "rivet", 0.0065))
	br = small_piece("armor_chest_brass", MAT["brass"], items)

	def tint(co):
		X, Y, Z = co[:, 0], co[:, 1], co[:, 2]
		reg_, th_, hem_ = jerkin_region(X, Y, Z)
		sector = np.digitize(th_, [-2.45, -0.62, 0.62, 2.45])  # back-right, right side, front, left side, back-left
		shade = np.array([0.92, 1.05, 0.95, 1.08, 0.9])[sector]
		rgb = np.stack([shade, shade * 0.97, shade * 0.93], 1)
		ang = [abs(((th_ - a + math.pi) % (2 * math.pi)) - math.pi) * 0.25 for a in (0.62, -0.62, 2.45, -2.45)]
		seam = np.min(ang, 0)
		st = stitch_band(-reg_, Z * 0.7 + th_ * 0.25, inset=0.008) | (np.abs(seam - 0.009) < 0.0013) & (np.sin(Z * 2 * math.pi / 0.007) > 0)
		rgb[seam < 0.0016] *= 0.62
		gd_, puff_ = quilt(X, Y, Z)
		quilted = gd_ < 1.0
		rgb[quilted] *= (0.78 + 0.32 * puff_[quilted])[:, None]  # light on each puffed diamond, darker toward its edges
		rgb[gd_ < 0.0024] *= 0.42  # the grooves
		pz = pad_zone(X, Z)
		f_ = pad_strips(X, Y, Z)
		rgb[pz] *= (0.8 + 0.35 * f_[pz])[:, None]
		rgb[pz & (f_ < 0.08)] *= 0.45  # the shadow under each strip's edge
		st |= pz & (np.abs(f_ - 0.82) < 0.035) & (np.sin((X + Y + Z) * 2 * math.pi / 0.0075) > 0)
		st |= (np.abs(gd_ - 0.0042) < 0.001) & (np.sin((X + Y - Z) * 2 * math.pi / 0.0065) > 0.1)  # stitches beside them
		sea_ = jerkin_seams(X, Y, Z)
		rgb[sea_ < 0.005] *= 0.5  # (the grooves between panels: dark)
		st |= (np.abs(sea_ - 0.0095) < 0.0011) & (np.sin((X + Y + Z) * 2 * math.pi / 0.0075) > 0)  # stitches on the welts
		beltm = np.abs(Z - BELT) < 0.026
		rgb[beltm] *= np.array([0.62, 0.58, 0.55])
		st |= beltm & (np.abs(np.abs(Z - BELT) - 0.02) < 0.0011) & (np.sin((X + Y) * 2 * math.pi / 0.007) > 0)
		sd_ = strap_dist(X, Z)
		rgb[np.abs(sd_) < 0.023] *= np.array([0.78, 0.74, 0.7])  # the strap: darker, with stitches along both edges
		st |= (np.abs(np.abs(sd_) - 0.017) < 0.0012) & (np.sin((X + Z) * 2 * math.pi / 0.008) > 0)
		for px, pz, w, h, front, col in ((-0.12, 0.53, 0.05, 0.04, True, (1.18, 1.12, 1.0)), (0.1, 0.64, 0.045, 0.035, False, (0.82, 0.86, 0.9))):
			side = (Y < 0) if front else (Y > 0)
			bx = np.maximum(np.abs(X - px) - w, np.abs(Z - pz) - h)
			inside = side & (bx < 0)
			rgb[inside] *= np.array(col)
			st |= inside & (bx > -0.005) & (np.sin((X + Z) * 2 * math.pi / 0.008) > 0)
		rgb[st] = np.array([1.5, 1.38, 1.15])
		return rgb

	def disp(q, n):
		h = 0.00045 * noise.fractal(q * 150, 0.6, 2.0, 3) + 0.0008 * noise.noise(q * 18)
		gd, puff = quilt(np.array([q.x]), np.array([q.y]), np.array([q.z]))
		gd, puff = float(gd[0]), float(puff[0])
		if pad_zone(np.array([q.x]), np.array([q.z]))[0]:  # overlapping strips: each one thicker at its lower edge
			f = float(pad_strips(np.array([q.x]), np.array([q.y]), np.array([q.z]))[0])
			h += 0.0035 * f - 0.002 * math.exp(-((1.0 - f) / 0.06) ** 2)
		elif gd < 1.0:  # puffed diamonds, a deep stitched groove between them
			h += 0.0042 * puff - 0.0034 * math.exp(-(gd / 0.0028) ** 2)
		for px, pz, w, hh, front in ((-0.12, 0.53, 0.05, 0.04, True), (0.1, 0.64, 0.045, 0.035, False)):
			if (q.y < 0) == front and abs(q.x - px) < w and abs(q.z - pz) < hh:
				h += 0.0013  # the patch stands on the leather
		return h

	PIECES.extend([(lo, "chest", "leather", tint, disp), (br, "chest", "brass", None, None)])


def build_boots():
	parts = {"leather": [], "fleece": [], "cord": [], "brass": []}
	for side in ("l", "r"):
		log("boot", side)
		fo = BODYM[f"body_foot_{side}"]
		fv = world_verts(fo)
		lo_b, hi_b = fv.min(0), fv.max(0)
		g = G((lo_b[0] - 0.04, lo_b[1] - 0.045, -0.016), (hi_b[0] + 0.04, hi_b[1] + 0.04, 0.255), 0.004)
		d = g.field([f"body_foot_{side}", "body_torso"])
		soft = blur(d, 2)
		top = 0.188 + 0.006 * np.sin(np.arctan2(g.X - fv[:, 0].mean(), -(g.Y - fv[:, 1].mean())) * 2 + 0.5)
		t_ = 0.011 + wobble(g, 0.0012, 5 if side == "l" else 6)
		outer = np.minimum(soft - t_, d - 0.0075)
		boot = np.maximum(np.maximum(outer, 0.003 - d), g.Z - top)
		sole = np.maximum(np.maximum(soft - 0.02, g.Z - 0.03), -0.011 - g.Z)
		toe = np.maximum(np.maximum(soft - t_ - 0.004, g.Y - (lo_b[1] + 0.07)), g.Z - 0.075)
		heel = np.maximum(np.maximum(soft - 0.022, g.Z - 0.045), np.maximum(-0.011 - g.Z, (hi_b[1] - 0.07) - g.Y))
		boot = smin(np.minimum(boot, toe), np.minimum(sole, heel), 0.004)
		boot = np.maximum(boot, 0.003 - d)
		fleece = np.sqrt((g.Z - top) ** 2 + (soft - t_ * 0.6) ** 2) - 0.0165 + lumps(g, 0.0028, 0.016, 7)
		fleece = np.maximum(fleece, 0.004 - d)
		bo = g.mesh(f"_boot_{side}", MAT["leather"], boot)
		fl = g.mesh(f"_cuff_{side}", MAT["fleece"], fleece)
		# crossed laces up the front through brass eyelets
		tb = bvh_of(bo)
		shin = fv[(fv[:, 2] > 0.09) & (fv[:, 2] < 0.18)]
		cx = float(shin[:, 0].mean())
		holes = []
		for z in (0.085, 0.112, 0.139, 0.166):
			row = []
			for dx in (-0.021, 0.021):
				hit = ray_to(tb, (cx + dx, -0.5, z), (0, 1, 0))
				if hit:
					row.append(hit)
			if len(row) == 2:
				holes.append(row)
		hp = np.array([list(p) for row in holes for p, _ in row]) if holes else np.array([[cx, -0.05, 0.1]])
		lg = G(hp.min(0) - np.array([0.012, 0.012, 0.034]), hp.max(0) + 0.012, 0.0012)
		cord = np.full_like(lg.D, 1.0)
		for k in range(len(holes) - 1):
			for i in (0, 1):
				p0, n0 = holes[k][i]
				p1, n1 = holes[k + 1][1 - i]
				cord = smin(cord, lg.tube(p0 + n0 * 0.003, p1 + n1 * 0.003, 0.0034, 0.0034), 0.002)
		if holes:  # a short tie at the top
			(pl, nl), (pr, nr) = holes[-1]
			cord = smin(cord, lg.tube(pl + nl * 0.003, pr + nr * 0.003, 0.0034, 0.0034), 0.002)
			mid = (pl + pr) / 2 + (nl + nr).normalized() * 0.006
			for dz, dx in ((-0.022, -0.01), (-0.026, 0.012)):
				cord = smin(cord, lg.tube(mid, mid + Vector((dx, -0.004, dz)), 0.0032, 0.0026), 0.002)
		cord = np.maximum(cord, 0.0 - lg.field([f"body_foot_{side}"], band=0.02, far=0.02) + 0.0)
		co = lg.mesh(f"_laces_{side}", MAT["cord"], cord, min_island=20)
		items = [(p - n * 0.0005, n, (0, 0, 1), "ring", 0.0045) for row in holes for p, n in row]
		br = small_piece(f"_eyelets_{side}", MAT["brass"], items) if items else None
		parts["leather"].append(bo)
		parts["fleece"].append(fl)
		parts["cord"].append(co)
		if br:
			parts["brass"].append(br)
	for mname, objs in parts.items():
		if not objs:
			continue
		bpy.ops.object.select_all(action="DESELECT")
		for o in objs:
			o.select_set(True)
		bpy.context.view_layer.objects.active = objs[0]
		bpy.ops.object.join()
		o = bpy.context.view_layer.objects.active
		o.name = f"armor_feet_{mname}"

		def tint(co_, m=mname):
			Z = co_[:, 2]
			shade = np.where(co_[:, 0] > 0, 1.0, 0.94)
			rgb = np.stack([shade, shade * 0.97, shade * 0.94], 1)
			sole = Z < 0.031
			rgb[sole] *= np.array([0.45, 0.42, 0.4])
			welt = (np.abs(Z - 0.037) < 0.0016) & (np.sin((co_[:, 0] + co_[:, 1]) * 2 * math.pi / 0.007) > 0)
			rgb[welt] = np.array([1.45, 1.32, 1.1])
			cap = (co_[:, 2] < 0.075) & (co_[:, 2] > 0.033)
			rgb[cap & (co_[:, 1] < -0.1)] *= 0.86
			return rgb

		def disp(q, n):
			h = 0.0004 * noise.fractal(q * 150, 0.6, 2.0, 3) + 0.0012 * noise.noise(q * 20)
			if q.z < 0.03:  # tread notches round the sole's edge
				h -= 0.0016 * max(0.0, math.sin((q.x + q.y) * 2 * math.pi / 0.014)) * (1.0 - min(abs(q.z - 0.008) / 0.012, 1.0))
			return h

		PIECES.append((o, "feet", mname, tint if mname == "leather" else None, disp if mname == "leather" else None))


log("building the", SET, "set")
if SET != "hide":
	raise SystemExit(f"ARMOR: no '{SET}' set yet (hide only, so far)")
build_helmet()
HAIR = BODYM.pop("armor_head_hair")
build_jerkin()
build_boots()
log("shapes done:", [(o.name, len(o.data.polygons)) for o, *_ in PIECES])

# ---------------------------------------------------------------- the light game copies, painted and baked
FACES = {"leather": {"head": 7000, "chest": 16000, "feet": 9000}, "fleece": 3500, "brass": 2500, "cord": 2500}
SIZES = {"leather": {"head": 1024, "chest": 2048, "feet": 1024}, "fleece": 512, "brass": 256, "cord": 256}


def pick(tbl, mat, piece):
	v = tbl[mat]
	return v[piece] if isinstance(v, dict) else v


for o, piece, mname, tint, disp in PIECES:
	raw = o
	bpy.context.view_layer.objects.active = raw
	hi = None
	if not FAST:
		cs._select_only(raw)
		bpy.ops.object.duplicate()
		hi = bpy.context.view_layer.objects.active
		hi.name = raw.name + "_high"
		# (smoothed into a finer copy; not the jerkin: 343k faces already, and smoothing it ran Blender out of memory
		# twice in round 2; its painted leather picture carries the fine detail)
		if len(hi.data.polygons) < 260000:
			m = hi.modifiers.new("smooth", "SUBSURF")
			m.levels = m.render_levels = 2 if len(hi.data.polygons) < 60000 else 1
			cs._apply_all(hi)
		if disp:
			cs._displace(hi, disp)
		elif mname == "fleece":
			cs._displace(hi, lambda q, n: 0.0011 * noise.noise(q * 260) + 0.0008 * noise.noise(q * 90))
		else:
			cs._displace(hi, lambda q, n: 0.00025 * noise.noise(q * 300))
		tint_name = None
		if tint:
			co = np.empty(len(hi.data.vertices) * 3)
			hi.data.vertices.foreach_get("co", co)
			rgb = tint(co.reshape(-1, 3))
			at = hi.data.color_attributes.new("tint", "FLOAT_COLOR", "POINT")
			at.data.foreach_set("color", np.concatenate([rgb, np.ones((len(rgb), 1))], 1).ravel())
			tint_name = "tint"
		pp = PAINT[mname]
		pic = PICTURE.get((mname, piece)) or PICTURE.get((mname, None))
		pname = pic[0] if pic and pic[0].startswith(SET) else (f"{SET}_{pic[0]}" if pic else "")
		pic_path = str(TEX / f"{pname}.png") if pic and (TEX / f"{pname}.png").exists() else None  # (round 5: the bold sheet, hide2)
		hi.data.materials.clear()
		hi.data.materials.append(cs.paint_material(f"paint_{raw.name}", base=pp["base"], dark=pp["dark"], light=pp["light"],
			strokes=pp["strokes"], top_light=0.12, edge=0.3 if mname != "fleece" else 0.15, key=0.28, seed=5, tint_attr=tint_name,
			scratches=(1.0 if piece == "chest" else 0.4) if mname == "leather" else 0.0, scratch_width=0.5,
			# (round 1's cap had a black patch: the shading counted his head inside it; now only the piece itself)
			ao_local=True, picture=pic_path, picture_scale=pic[1] if pic else 6.0))
	# the light copy: fewer faces
	n = len(raw.data.polygons)
	want = pick(FACES, mname, piece)
	if n > want:
		md = raw.modifiers.new("fewer", "DECIMATE")
		md.ratio = want / n
		cs._apply_all(raw)
	bm = bmesh.new()
	bm.from_mesh(raw.data)
	bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0003)
	bmesh.ops.dissolve_degenerate(bm, edges=bm.edges, dist=0.0003)
	bm.to_mesh(raw.data)
	bm.free()
	for p in raw.data.polygons:
		p.use_smooth = True
	if not FAST:
		cs.uv_only(raw)
		cs.bake(hi, raw, pick(SIZES, mname, piece), f"{raw.name.replace('armor_', 'armor_' + SET + '_')}_baked", ext=0.006)
		bpy.data.objects.remove(hi, do_unlink=True)
		nt = raw.data.materials[0].node_tree  # (the photos show the active picture: the paint, not the bump map)
		nt.nodes.active = next(n for n in nt.nodes if n.type == "TEX_IMAGE" and n.image.name.endswith("_col"))
	log("made", raw.name, len(raw.data.polygons), "faces")

# ---------------------------------------------------------------- which bones move each point: the body's under it
SRC = {"head": None, "chest": ["body_shirt"], "feet": ["body_foot_l", "body_foot_r", "body_torso"]}


def source_points(names):
	pts, ws = [], []
	for n in names:
		o = BODYM[n]
		gn = {vg.index: vg.name for vg in o.vertex_groups}
		wv = world_verts(o)
		for v, p in zip(o.data.vertices, wv):
			if n == "body_torso" and p[2] > 0.3:
				continue  # (only the legs: the boots never follow the arms or the belly)
			pts.append(p)
			ws.append({gn[g.group]: g.weight for g in v.groups if g.weight > 0.0})
	kd = kdtree.KDTree(len(pts))
	for i, p in enumerate(pts):
		kd.insert(Vector(p), i)
	kd.balance()
	return kd, ws


KD = {k: source_points(v) for k, v in SRC.items() if v}
for o, piece, mname, *_ in PIECES:
	for vg in list(o.vertex_groups):
		o.vertex_groups.remove(vg)
	groups = {}
	wv = world_verts(o)
	for i, p in enumerate(wv):
		if piece == "head":
			ws = {"Head": 1.0}  # the helmet is one hard piece on the head
		else:
			kd, sw = KD[piece]
			ws = sw[kd.find(Vector(p))[1]]
		top = sorted(ws.items(), key=lambda kv: -kv[1])[:4]
		tot = sum(w for _, w in top) or 1.0
		for name, w in top:
			if name not in groups:
				groups[name] = o.vertex_groups.new(name=name)
			groups[name].add([i], w / tot, "REPLACE")
	o.parent = ARM
	o.parent_type = "OBJECT"
	o.matrix_parent_inverse = ARM.matrix_world.inverted()
	o.modifiers.new("skeleton", "ARMATURE").object = ARM
log("weights copied from the body")
for o, *_ in PIECES:
	if not o.data.uv_layers:
		o.data.uv_layers.new(name="UVMap")  # (the plain colours show in the textured photos only with a picture map)

# ---------------------------------------------------------------- photos: the dwarf wearing it, arms down like the game
if REVIEW:
	scene = bpy.context.scene
	bpy.context.view_layer.objects.active = ARM
	bpy.ops.object.mode_set(mode="POSE")
	for side in ("l", "r"):
		pb = ARM.pose.bones[f"upperarm_{side}"]
		h = pb.head.copy()
		rot = Matrix.Translation(h) @ Matrix.Rotation(math.radians(65) * (1 if pb.head.x > 0 else -1), 4, "Y") @ Matrix.Translation(-h)
		pb.matrix = rot @ pb.matrix
	bpy.ops.object.mode_set(mode="OBJECT")
	bpy.context.view_layer.update()
	for o in BODYM.values():
		if not o.modifiers:
			o.modifiers.new("skeleton", "ARMATURE").object = ARM
	BODYM["body_head"].hide_render = True  # (the hat-hair head is worn instead)
	scene.render.engine = "BLENDER_WORKBENCH"
	scene.display.shading.light = "STUDIO"
	scene.display.shading.color_type = "TEXTURE"
	scene.render.resolution_x, scene.render.resolution_y = 520, 620
	cam = bpy.data.objects.new("rcam", bpy.data.cameras.new("rcam"))
	cam.data.type = "ORTHO"
	scene.collection.objects.link(cam)
	scene.camera = cam
	shots = []
	for tag, loc, aim, scale in (("front", (0, -4, 0.62), 0.62, 1.34), ("side", (-4, 0, 0.62), 0.62, 1.34), ("back", (0, 4, 0.62), 0.62, 1.34),
			("head", (1.2, -3.2, 1.12), 1.08, 0.5), ("boots", (1.6, -3.0, 0.45), 0.12, 0.52)):
		cam.location = Vector(loc)
		cam.data.ortho_scale = scale
		cam.rotation_euler = (Vector((0, 0, aim)) - cam.location).to_track_quat("-Z", "Y").to_euler()
		if tag == "boots":
			cam.rotation_euler = (Vector((0, 0, 0.12)) - cam.location).to_track_quat("-Z", "Y").to_euler()
		path = str(Path(REVIEW).with_name(Path(REVIEW).stem + f"_{tag}.png"))
		scene.render.filepath = path
		bpy.ops.render.render(write_still=True)
		shots.append(path)
	log("REVIEW", shots)
	for pb in ARM.pose.bones:
		pb.matrix_basis = Matrix()
	bpy.context.view_layer.update()

# ---------------------------------------------------------------- export: the skeleton and the armor only
for o in list(BODYM.values()):
	bpy.data.objects.remove(o, do_unlink=True)
bpy.ops.object.select_all(action="DESELECT")
ARM.select_set(True)
for o, *_ in PIECES:
	o.select_set(True)
# the hat-hair head: its points, bones and picture map only (the game paints it with the normal head's pictures)
HAIR.data.materials.clear()
HAIR.data.materials.append(ck.color("body_head_paint", (0.6, 0.35, 0.2)))
HAIR.select_set(True)
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_yup=True, export_skins=True,
	export_animations=False, export_apply=False, export_image_format="JPEG", export_image_quality=88)
import glb_jpeg_fix  # noqa: E402  (Godot shows Blender's JPEG pictures white without it: F164)
glb_jpeg_fix.fix(OUT)
log("ARMOR_DONE", OUT, [(o.name, len(o.data.polygons)) for o, *_ in PIECES])
