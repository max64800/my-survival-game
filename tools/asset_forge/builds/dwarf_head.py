# The Happy dwarf's head, hair and beard, round 2 (Claude, Nov 16, 2026), built the Rock Beetle way
# (docs/art/CREATURE-RECIPE.md, MODEL-RULES Rule 1): hand-built pieces matched to the approved pictures
# (assets/concepts/dwarf/dwarf_happy_head.png, dwarf_turnaround.png), MELTED into one skin (face, ears, lids, hair,
# brows, moustache, beard and braids), sculpted (forehead wrinkles, crow's feet, smile bags, mouth, nostrils, a groove
# down every hair lock), laid onto the body so nothing goes through it, then a light game copy with the sculpt baked on
# as pictures (colour + normal map). The eyes and the copper rings are their own hard pieces (like the beetle's eyes).
#
# Used by dwarf_body.py:  parts = dwarf_head.build(body_objects, fast=False)  ->  {"head", "eyes", "rings"}
#
# Measured on dwarf_happy_head.png (1 px = 0.725 mm, the head 24 cm from crown to chin; crown at 1.19 m in the game):
# - a big round head as wide as it is tall (23.6 cm at the temples), bald on top, 3 wavy forehead wrinkles;
# - eyes 4.6 cm either side of the middle, set deep under huge bushy brows; smiling: round cheeks push the lower lids up;
# - a big round nose (7 cm ball, its tip 11 cm in front of the eyes) with nostril wings;
# - big ears sticking out at nose height; a wild ring of flame-shaped locks from temple to temple round the back,
#   hanging down onto the upper back, a little curl on top;
# - a curling handlebar moustache 29 cm tip to tip over a closed smile;
# - the beard 43 cm wide at the jaw, in three braids: the side ones to the chest (copper ring 36 cm below the crown,
#   tufts to 48 cm), the middle one to the belly (ring 46 cm, tuft to 60 cm).
import math
import os
import random
import sys
import time
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector, noise
from mathutils.bvhtree import BVHTree

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import creature_kit as ck  # noqa: E402
import creature_sculpt as cs  # noqa: E402
import kit  # noqa: E402

ROOT = Path(__file__).resolve().parents[3]
PIC = ROOT / "assets" / "concepts" / "dwarf" / "dwarf_happy_head.png"
PX_PER_M = 1380.0  # the head picture's scale (crown y=35 px .. middle tuft y=870 px = 0.6 m)

C = Vector((0.0, 0.02, 1.08))  # the skull's middle at eye level (Blender: x sideways, -y = front, z up)
VOX = 0.0022                   # melt resolution (m): fine enough to keep the grooves on the hair locks
GAP = 0.012                    # beard and hair stay this far off the body (MODEL-RULES Rule 2: 1 cm)
EYE_R = 0.025  # (bigger, friendlier eyes: owner Nov 17 "his eyes are small and not nice"; again Nov 17 evening:
#   "his eyes can be bigger, compared to the pictures": 21 -> 25 mm)
R = random.Random(7)
SKIN, LIDS, HAIR = [], [], []
BVH = {}
MS = MH = None

# ---------------------------------------------------------------- the faces to choose from (F737, owner Nov 28 night: "3 new
# faces, black hair, different face, hair, more warrior like, a few scars, more grumpy"; picture
# assets/concepts/dwarf/dwarf_faces_grumpy_v1.png, owner picked it). Face 1 ("happy") is the first, approved head: every
# setting left out of a face keeps face 1's look. dwarf_body.py picks one with face=<name> (one .glb per face).
FACES = {
	"happy": {},
	# the picture's top row: jet-black hair swept back over the whole head into a topknot with a copper ring, a scar from
	# the forehead down through his squinting left eye, a crooked nose, a heavier jaw, low frowning brows, a drooping
	# moustache, a square beard coming to a point in the middle and two braids (no middle braid)
	"topknot": dict(
		pic="dwarf_face_topknot_head.png",
		hair_rgb=(0.2, 0.14, 0.11), skin_rgb=(0.84, 0.55, 0.42),
		jaw=(0.1, 0.066, 0.09), brow_ridge=(0.09, 0.024, 0.034), nose_u=0.007, nose_r=(0.036, 0.032, 0.034),
		# (upper, lower lid opening in degrees: narrowed eyes; round 4, owner: "his left eye where the scar is, closed")
		lids={-1: (34, 17), 1: (3, 2)},
		scar_gap=(0.046, 0.012),  # (round 4, owner: "I don't see the scar above the eye": the brow parts where it crosses)
		frown=True, short_back=True, back_braid=True, ring_reach=0.035, moustache="droop", cap="topknot", beard_point=True,
		braids=[("braid_-1", -0.128), ("braid_1", 0.128)],
		# scars in face coordinates (u sideways, v up from the eye level; + u = his left), drawn as raised pale lines
		scars=[[(0.02, 0.135), (0.025, 0.112), (0.03, 0.09), (0.038, 0.066), (0.046, 0.042), (0.052, 0.024), (0.053, 0.016), (0.054, 0.008), (0.055, 0.0), (0.056, -0.008), (0.058, -0.016),  # (round 5: dots across the shut lid, owner: "the scar doesn't go over the eye")
			 (0.064, -0.038), (0.071, -0.06)],
			[(-0.016, -0.084), (-0.009, -0.1)]],
	),
	# face 3 (owner Nov 28: "white hair because he's old ... sneaky ... very smart"; picture
	# assets/concepts/dwarf/dwarf_faces_old_sly_v1.png, owner picked row A): an old trickster. Both sides of the head shaved,
	# a white crest on top running back into one long braid down his back, soot paint round the eyes, narrow knowing eyes
	# (one brow up), a crooked half-smile, a thinner bony face, deep old wrinkles, a middle beard braid with a copper ring
	"oldsly": dict(
		pic="dwarf_face_oldsly_head.png",
		hair_rgb=(0.8, 0.76, 0.7), skin_rgb=(0.86, 0.6, 0.5), ink=0.3,
		jaw=(0.086, 0.058, 0.084), cheek_r=(0.039, 0.037, 0.035),
		lids={-1: (20, 14), 1: (26, 16)},  # (narrow; his left eye, under the raised brow, a little more open)
		cap="mohawk", short_back=True, back_braid=True, ring_reach=0.035, moustache="sly", brows="sly", smirk=True, old=True,
		eye_paint=True, braids=[("braid_mid", 0.0)], beard_flare=0.4, crease_dark=0.4, ear_full=True, stubble=True,
	),
}
FACE_NAME = "happy"
FACE = FACES["happy"]
SCARS3D = []  # each scar's line on the melted head (for the paint)


def set_face(name):
	"""Pick which face the next build() makes."""
	global FACE_NAME, FACE, SKIN_RGB, HAIR_RGB, PIC
	FACE_NAME, FACE = name, FACES[name]
	SKIN_RGB = FACE.get("skin_rgb", SKIN_RGB_1)
	HAIR_RGB = FACE.get("hair_rgb", HAIR_RGB_1)
	PIC = ROOT / "assets" / "concepts" / "dwarf" / FACE.get("pic", "dwarf_happy_head.png")


def Hd(u, v, w):
	"""Head space (u sideways, v up from the eye level, w forward from the skull's middle) -> Blender."""
	return C + Vector((u, -w, v))


def Dv(u, v, w):
	"""A head-space direction -> Blender."""
	return Vector((u, -w, v))


UP, DN, FWD, BACK = Vector((0, 0, 1)), Vector((0, 0, -1)), Vector((0, -1, 0)), Vector((0, 1, 0))


# ---------------------------------------------------------------- small builders
def bvh_of(objs):
	"""One ray/nearest-point tree over these objects as they look now (modifiers included)."""
	dg = bpy.context.evaluated_depsgraph_get()
	verts, polys = [], []
	for o in objs:
		e = o.evaluated_get(dg)
		me = e.to_mesh()
		mw = o.matrix_world
		base = len(verts)
		verts.extend(mw @ v.co for v in me.vertices)
		polys.extend([base + i for i in p.vertices] for p in me.polygons)
		e.to_mesh_clear()
	return BVHTree.FromPolygons(verts, polys)


def hit_front(tree, u, v):
	"""The surface seen straight from the front at (u, v): (point, normal) or (None, None)."""
	loc, nrm, _, _ = BVH[tree].ray_cast(Hd(u, v, 0.9), BACK, 2.0)
	return loc, nrm


def hit_round(tree, phi, el):
	"""The surface seen from outside along the direction phi (degrees round the head, 0 = the back, 90 = the side,
	180 = the face) and el (degrees above the eye level), looking at the skull's middle."""
	p, e = math.radians(phi), math.radians(el)
	d = Dv(math.sin(p) * math.cos(e), math.sin(e), -math.cos(p) * math.cos(e))
	loc, nrm, _, _ = BVH[tree].ray_cast(C + d * 0.7, -d, 1.4)
	return loc, nrm


def w_of(p):
	return C.y - p.y


def shirt_front(u, v):
	"""How far forward (w) the body's front is at (u, v), or None above the shirt."""
	loc, _ = hit_front("body", u, v)
	return w_of(loc) if loc else None


def sblob(u, v, w, ru, rv, rw, seed=1, m=None, lst=None, jitter=0.02):
	o = ck.blob(tuple(Hd(u, v, w)), (ru, rw, rv), m or MS, seed=seed, jitter=jitter)
	(SKIN if lst is None else lst).append(o)
	return o


def ell(ctr, ax, rad, m, lst, seg=24, rings=12):
	"""An ellipsoid with its own axes (for parts that sit at an angle, like the ears)."""
	bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=rings, radius=1.0, location=ctr)
	o = bpy.context.object
	m3 = Matrix((ax[0] * rad[0], ax[1] * rad[1], ax[2] * rad[2])).transposed()
	o.matrix_world = Matrix.Translation(ctr) @ m3.to_4x4()
	bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
	o.data.materials.append(m)
	for p in o.data.polygons:
		p.use_smooth = True
	lst.append(o)
	return o


def tube(name, pts, radii, m, lst, sides=16, up=None):
	o = ck.loft(name, [(p, r, r) for p, r in zip(pts, radii)], m, sides=sides, subsurf=1, up=up or UP)
	lst.append(o)
	return o


def _spline(pts, n=96):
	"""A smooth curve through every point (Catmull-Rom)."""
	P = [pts[0] * 2 - pts[1]] + list(pts) + [pts[-1] * 2 - pts[-2]]
	segs = len(pts) - 1
	out = []
	for i in range(n):
		t = i / (n - 1) * segs
		k = min(int(t), segs - 1)
		f = t - k
		p0, p1, p2, p3 = P[k], P[k + 1], P[k + 2], P[k + 3]
		out.append(0.5 * (2 * p1 + (p2 - p0) * f + (2 * p0 - 5 * p1 + 4 * p2 - p3) * f * f + (3 * p1 - p0 - 3 * p2 + p3) * f ** 3))
	return out


def _resample(pts, n):
	"""n points spread evenly along a polyline."""
	d = [0.0]
	for a, b in zip(pts[:-1], pts[1:]):
		d.append(d[-1] + (b - a).length)
	total = d[-1] or 1e-9
	out, j = [], 0
	for i in range(n):
		s = total * i / (n - 1)
		while j < len(d) - 2 and d[j + 1] < s:
			j += 1
		f = (s - d[j]) / max(d[j + 1] - d[j], 1e-9)
		out.append(pts[j].lerp(pts[j + 1], min(max(f, 0.0), 1.0)))
	return out


def lock(pts, width, thick, hint, lst=None, n=14, sides=20, grooves=2, rd=0.2, twist=0.0, m=None, name="lock", leaf=False):
	"""One hair lock, the flame-shaped clump the picture is painted with: a flat tube through `pts` that swells, then
	tapers to a point, with `grooves` grooves along its outer face (the strands). hint = the way its flat face looks.
	Its frames are carried along the curve without turning (no twisted 'droplets' where the curve points down).
	Every point after the root keeps GAP + its own thickness off the body (built outside it, not pushed out later)."""
	pts = [Vector(p) for p in pts]
	need = GAP + 0.4 * max(width, thick)
	for i in range(1, len(pts)):
		loc, nrm, _, _ = BVH["body"].find_nearest(pts[i], 0.3)
		if loc is not None:
			sd = (pts[i] - loc).dot(nrm)
			if sd < need:
				pts[i] = pts[i] + nrm * (need - sd)
	P = _resample(_spline(pts), n)
	T = [(P[min(i + 1, n - 1)] - P[max(i - 1, 0)]).normalized() for i in range(n)]
	h = Vector(hint)
	N = h - T[0] * h.dot(T[0])
	N = N.normalized() if N.length > 1e-6 else T[0].orthogonal().normalized()
	frames = [N]
	for i in range(1, n):
		Nn = T[i - 1].rotation_difference(T[i]) @ frames[-1]
		frames.append((Nn - T[i] * Nn.dot(T[i])).normalized())
	verts, faces = [], []
	for i in range(n - 1):
		t = i / (n - 1)
		prof = (math.sin(math.pi * (0.06 + 0.94 * t)) ** 0.7) if leaf else math.sin(math.pi * (0.25 + 0.75 * t)) ** 0.8
		w, th = width * prof, thick * prof ** 1.1
		S = T[i].cross(frames[i])
		for k in range(sides):
			b = 2 * math.pi * k / sides
			a = b + twist * t
			r = 1.0 + rd * math.cos(2 * grooves * b)
			verts.append(tuple(P[i] + S * (w * math.cos(a) * r) + frames[i] * (th * math.sin(a) * r)))
	tip = len(verts)
	verts.append(tuple(P[-1]))
	root = len(verts)
	verts.append(tuple(P[0] - T[0] * thick * 0.3))
	for i in range(n - 2):
		for k in range(sides):
			a, b = i * sides + k, i * sides + (k + 1) % sides
			faces.append((a, b, b + sides, a + sides))
	last = (n - 2) * sides
	for k in range(sides):
		faces.append((last + k, last + (k + 1) % sides, tip))
		faces.append((root, (k + 1) % sides, k))
	o = kit._mesh_obj(name, verts, faces, m or MH)
	ck._fix_normals(o)
	# for the hard lines: which lock each point belongs to, and where its grooves are (-1 = deepest in a groove)
	LOCK_ID[0] += 1
	ids = o.data.attributes.new("lock_id", "INT", "POINT")
	gr = o.data.attributes.new("groove", "FLOAT", "POINT")
	ids.data.foreach_set("value", [LOCK_ID[0]] * len(verts))
	gv = [math.cos(2 * grooves * 2 * math.pi * k / sides) for _ in range(n - 1) for k in range(sides)] + [0.0, 0.0]
	gr.data.foreach_set("value", gv)
	(HAIR if lst is None else lst).append(o)
	return o


LOCK_ID = [0]


def jit(a=1.0):
	return R.uniform(-a, a)


# ---------------------------------------------------------------- clay: shapes that blend like clay smoothed by a thumb
def _smin(a, b, k):
	h = np.clip(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
	return b + (a - b) * h - k * h * (1.0 - h)


class Clay:
	"""A shape made like clay, in head space (metres): ellipsoids and tubes joined with soft fillets of a chosen size
	(k) or scooped out, measured on a fine grid (signed distance: negative inside), then turned into a mesh
	(surface nets). Unlike glued balls, every part flows into the next (round 2: the face was 'balls glued together')."""

	def __init__(self, lo, hi, h):
		self.h, self.lo = h, np.array(lo, float)
		n = np.ceil((np.array(hi, float) - self.lo) / h).astype(int) + 1
		ax = [(self.lo[i] + h * np.arange(n[i])).astype(np.float32) for i in range(3)]
		self.U, self.V, self.W = np.meshgrid(*ax, indexing="ij")
		self.D = np.full(tuple(n), 1.0, np.float32)

	def ell(self, c, r):
		x, y, z = (self.U - c[0]) / r[0], (self.V - c[1]) / r[1], (self.W - c[2]) / r[2]
		k0 = np.sqrt(x * x + y * y + z * z)
		k1 = np.sqrt((x / r[0]) ** 2 + (y / r[1]) ** 2 + (z / r[2]) ** 2)
		return k0 * (k0 - 1.0) / np.maximum(k1, 1e-6)

	def tube(self, a, b, r0, r1):
		a, b = np.array(a, np.float32), np.array(b, np.float32)
		ba = b - a
		pu, pv, pw = self.U - a[0], self.V - a[1], self.W - a[2]
		t = np.clip((pu * ba[0] + pv * ba[1] + pw * ba[2]) / float(ba @ ba), 0.0, 1.0)
		d = np.sqrt((pu - ba[0] * t) ** 2 + (pv - ba[1] * t) ** 2 + (pw - ba[2] * t) ** 2)
		return d - (r0 + (r1 - r0) * t)

	def add(self, d, k):
		self.D = _smin(self.D, d, k)

	def cut(self, d, k):
		self.D = -_smin(-self.D, d, k)

	def keep(self, d, k):
		"""Keep only where d < 0 (a soft cut along d's surface)."""
		self.D = -_smin(-self.D, -d, k)

	def mesh(self, name, m, lst):
		for ax in range(3):  # anything reaching the grid's edge is closed off there (an open hole breaks the melt)
			sl = [slice(None)] * 3
			for end in (0, -1):
				sl[ax] = end
				self.D[tuple(sl)] = np.maximum(self.D[tuple(sl)], self.h)
		v, q = surface_nets(self.D, self.lo, self.h)
		bl = np.empty_like(v)
		bl[:, 0], bl[:, 1], bl[:, 2] = C.x + v[:, 0], C.y - v[:, 2], C.z + v[:, 1]
		o = kit._mesh_obj(name, bl.tolist(), q.tolist(), m)
		ck._fix_normals(o)
		lst.append(o)
		return o


def surface_nets(D, lo, h):
	"""The surface where D = 0 as a quad mesh: one point per grid cell the surface passes through (the average of
	where it crosses the cell's edges), one quad per grid edge it crosses."""
	inside = D < 0
	nx, ny, nz = D.shape
	cs_ = np.array([(i, j, k) for i in (0, 1) for j in (0, 1) for k in (0, 1)])
	cnt = sum(inside[i:nx - 1 + i, j:ny - 1 + j, k:nz - 1 + k].astype(np.int8) for i, j, k in cs_)
	act = (cnt > 0) & (cnt < 8)
	cells = np.argwhere(act)
	idx = np.full(act.shape, -1, np.int64)
	idx[cells[:, 0], cells[:, 1], cells[:, 2]] = np.arange(len(cells))
	acc = np.zeros((len(cells), 3))
	num = np.zeros(len(cells))
	ci, cj, ck_ = cells[:, 0], cells[:, 1], cells[:, 2]
	for a in range(8):
		for b in range(a + 1, 8):
			if np.abs(cs_[a] - cs_[b]).sum() != 1:
				continue
			fa = D[ci + cs_[a][0], cj + cs_[a][1], ck_ + cs_[a][2]]
			fb = D[ci + cs_[b][0], cj + cs_[b][1], ck_ + cs_[b][2]]
			x = (fa < 0) != (fb < 0)
			t = fa[x] / (fa[x] - fb[x])
			acc[x] += cs_[a] + t[:, None] * (cs_[b] - cs_[a])
			num[x] += 1
	verts = lo + h * (cells + acc / np.maximum(num, 1)[:, None])
	quads = []
	for d in range(3):
		o1, o2 = [x for x in range(3) if x != d]
		s0, s1 = [slice(None)] * 3, [slice(None)] * 3
		s0[d], s1[d] = slice(0, D.shape[d] - 1), slice(1, D.shape[d])
		for o in (o1, o2):
			s0[o] = s1[o] = slice(1, D.shape[o] - 1)
		pts = np.argwhere(inside[tuple(s0)] != inside[tuple(s1)])
		pts[:, o1] += 1
		pts[:, o2] += 1
		start_in = inside[pts[:, 0], pts[:, 1], pts[:, 2]]

		def cell(d1, d2):
			c = pts.copy()
			c[:, o1] += d1
			c[:, o2] += d2
			return idx[c[:, 0], c[:, 1], c[:, 2]]
		q = np.stack([cell(-1, -1), cell(0, -1), cell(0, 0), cell(-1, 0)], 1)
		q[start_in] = q[start_in][:, ::-1]
		quads.append(q)
	return verts, np.concatenate(quads)


# ---------------------------------------------------------------- the face (skin)
# The skull: rings from the crown down to the jaw: (v, half-width, front, back), measured on the head picture.
# Deep-set eyes: the front dips at eye level (v ~ -0.01) between the brow ridge and the cheeks.
SKULL = [
	(0.104, 0.036, 0.032, 0.036), (0.096, 0.066, 0.062, 0.068), (0.080, 0.094, 0.088, 0.096),
	(0.056, 0.110, 0.100, 0.108), (0.030, 0.117, 0.101, 0.112), (0.008, 0.118, 0.086, 0.112),
	(-0.012, 0.117, 0.074, 0.110), (-0.036, 0.112, 0.080, 0.104), (-0.062, 0.102, 0.090, 0.094),
	(-0.090, 0.088, 0.094, 0.080), (-0.116, 0.068, 0.090, 0.064), (-0.136, 0.040, 0.066, 0.044)]


# (F943, owner Nov 28 night, picture: "his eyes look different ways" and "they are too deep now": each eye looked 8%
# outward; now both look at one spot about 1.5 m in front of him (3% inward), and they sit 6 mm further forward)
EYE_TOE = -0.03  # sideways part of each eye's look line (minus = toward the nose)
EYE_FWD = 0.066  # m: how far in front of the skull's middle the eyeballs sit (was 0.06)


def eye_centre(s):
	return Hd(s * 0.046, 0.003, EYE_FWD)


def eye_look(s):
	return Dv(s * EYE_TOE, -0.03, 1.0).normalized()


def build_face():
	"""The head and face as one piece of clay (head space: u sideways, v up from the eye level, w forward). Each part
	flows into the next with a fillet (the last number); the eye sockets are scooped out so the eyes sit deep under
	the brow ridge, like the picture's."""
	cl = Clay((-0.15, -0.3, -0.13), (0.15, 0.13, 0.215), 0.002)
	cl.add(cl.ell((0, 0.0, -0.006), (0.117, 0.11, 0.106)), 0.01)                  # the skull, bald on top
	cl.add(cl.ell((0, -0.068, 0.02), FACE.get("jaw", (0.092, 0.062, 0.086))), 0.03)               # jaw and lower face
	cl.add(cl.ell((0, 0.029, 0.078), FACE.get("brow_ridge", (0.086, 0.019, 0.03))), 0.022)               # brow ridge
	for s in (-1, 1):
		cl.add(cl.ell((s * 0.072, -0.022, 0.056), (0.03, 0.02, 0.03)), 0.03)  # cheekbone (soft: owner Nov 17, "sausages")
		# one big round cheek, pushing the lower lid up, touching the side of the nose and running down to the moustache
		# (owner, Nov 17 evening: "it should just be round, touching the nose on both sides, all the way to the moustache";
		# a cheek + a cheekbone + a filler read as sausages)
		cl.add(cl.ell((s * 0.058, -0.05, 0.09), FACE.get("cheek_r", (0.044, 0.041, 0.039))), 0.03)  # (a bit fatter: owner, Nov 17 night)
		if FACE.get("smirk") and s == 1:  # (F737 face 3: the half-smile pushes his left cheek up)
			cl.add(cl.ell((0.056, -0.066, 0.104), (0.024, 0.02, 0.022)), 0.02)
		# fill between the nose bridge, the round nose, the cheek and the eye's inner corner (owner, Nov 17 night: "there's
		# literally holes in there", "it's okay if it's not small")
		cl.add(cl.ell((s * 0.034, -0.024, 0.118), (0.02, 0.018, 0.02)), 0.022)  # (where the round nose meets the cheek)
		cl.add(cl.ell((s * 0.031, -0.054, 0.127), (0.017, 0.016, 0.018)), 0.014)  # nostril wing (a softer join: lumpy, Nov 17)
		# fill under the side of the nose: the pocket between the nostril wing, the cheek, the round nose's underside and
		# the moustache baked as a dark hole (owner, Nov 17 night; measured by nose_pockets(): 66% shut in at u 5, v -6, w 13)
		cl.add(cl.ell((s * 0.044, -0.06, 0.127), (0.02, 0.014, 0.02)), 0.02)
	nu = FACE.get("nose_u", 0.0)  # (a broken nose: bent to one side below the bridge)
	cl.add(cl.tube((0, 0.014, 0.088), (nu * 0.6, -0.02, 0.128), 0.013, 0.018), 0.012)   # nose bridge
	cl.add(cl.ell((nu, -0.042, 0.155), FACE.get("nose_r", (0.034, 0.031, 0.033))), 0.012)             # the big round nose
	cl.add(cl.ell((0, -0.083, 0.103), (0.054, 0.027, 0.04)), 0.02)               # upper lip (under the moustache)
	cl.add(cl.ell((0, -0.105, 0.121), (0.029, 0.011, 0.019)), 0.006)             # lower lip
	cl.add(cl.ell((0, -0.124, 0.097), (0.039, 0.025, 0.033)), 0.015)             # chin
	cl.add(cl.tube((0, -0.06, -0.005), (0, -0.2, 0.0), 0.07, 0.072), 0.02)       # neck (into the collar)
	for s in (-1, 1):
		cl.cut(cl.ell((s * 0.051, 0.002, 0.094), (0.026, 0.021, 0.021)), 0.008)   # eye socket (sized to the eye; its inner edge
		# where it was: grown toward the nose it left a dark hole by the bridge the lids don't cover, Nov 17) (filled by the lids; deeper = dark rings)
	cl.mesh("face", MS, SKIN)
	del cl
	for s in (-1, 1):
		bu, bl = FACE.get("lids", {}).get(s, (32, 22))
		build_lids(s, Bu=bu, Bl=bl)
		build_ear(s)


def build_lids(s, A=70, Bu=32, Bl=22, r_in=EYE_R - 0.0015, r_out=EYE_R + 0.0075, rho_max=105, J=48, M=12):
	"""Both lids of one eye as one shell round the eyeball with an almond opening (the upper lid 30 degrees above the
	look line, the lower lid only 14 below: a smiling eye). The shell sinks 1.5 mm into the ball, so the lid edge
	never leaves a gap (beetle lesson), and it melts into the brow and the cheek."""
	E, a = eye_centre(s), eye_look(s)
	b = (UP - a * a.dot(UP)).normalized()
	c = a.cross(b)
	A, Bu, Bl, rmax = (math.radians(x) for x in (A, Bu, Bl, rho_max))
	verts, faces = [], []
	for j in range(J):
		psi = 2 * math.pi * j / J
		B = Bu if math.sin(psi) >= 0 else Bl
		rb = 1 / math.sqrt((math.cos(psi) / A) ** 2 + (math.sin(psi) / B) ** 2)
		for m in range(M + 1):
			rho = rb + (rmax - rb) * (m / M) ** 1.6
			d = a * math.cos(rho) + (c * math.cos(psi) + b * math.sin(psi)) * math.sin(rho)
			verts.append(tuple(E + d * r_out))
			verts.append(tuple(E + d * r_in))

	def ix(j, m, k):
		return ((j % J) * (M + 1) + m) * 2 + k
	for j in range(J):
		for m in range(M):
			faces.append((ix(j, m, 0), ix(j + 1, m, 0), ix(j + 1, m + 1, 0), ix(j, m + 1, 0)))
			faces.append((ix(j, m + 1, 1), ix(j + 1, m + 1, 1), ix(j + 1, m, 1), ix(j, m, 1)))
		faces.append((ix(j, 0, 1), ix(j + 1, 0, 1), ix(j + 1, 0, 0), ix(j, 0, 0)))
		faces.append((ix(j, M, 0), ix(j + 1, M, 0), ix(j + 1, M, 1), ix(j, M, 1)))
	o = kit._mesh_obj(f"lids_{s}", verts, faces, MS)
	ck._fix_normals(o)
	LIDS.append(o)
	# the lids' rolled edges (owner, Nov 17: "there's no eyelids"): a plump upper lid rim and a thinner lower one along
	# the opening, so each lid reads as its own fold over the eye, like the picture's
	for upper in (True, False):
		B = Bu if upper else Bl
		pts, radii = [], []
		for k in range(15):
			psi = math.pi * k / 14 if upper else -math.pi * k / 14
			rb = 1 / math.sqrt((math.cos(psi) / A) ** 2 + (math.sin(psi) / B) ** 2)
			d = a * math.cos(rb) + (c * math.cos(psi) + b * math.sin(psi)) * math.sin(rb)
			pts.append(E + d * (EYE_R + 0.0012))
			taper = math.sin(math.pi * k / 14) ** 0.6
			radii.append((0.0046 if upper else 0.003) * (0.35 + 0.65 * taper))
		tube(f"lid_rim_{s}_{'up' if upper else 'lo'}", pts, radii, MS, LIDS, sides=10, up=a)


def build_ear(s):
	"""A big ear sticking out at nose height: a rolled rim (helix) round a hollow bowl, an inner ridge, a fleshy lobe,
	a little flap in front of the hole, all at an angle so its back edge stands off the head."""
	O = Hd(s * 0.13, -0.036, -0.034)
	n = Dv(s * 0.82, 0.0, 0.57).normalized()               # the ear faces out and a little forward
	if FACE.get("ear_full"):  # (face 3, round 2: lying closer to the head, so from behind it isn't a flat disc standing off)
		n = Dv(s * 0.93, 0.0, 0.37).normalized()
	up = Dv(0, 1, -0.18)
	up = (up - n * up.dot(n)).normalized()
	f = FWD - n * FWD.dot(n) - up * FWD.dot(up)
	f.normalize()                                          # toward the face, in the ear's plane
	a, b = 0.026, 0.041

	def pt(th, k=1.0, out=0.0):
		t = math.radians(th)
		return O + f * (a * k * math.cos(t)) + up * (b * k * math.sin(t)) + n * out
	rim = [pt(th, 1.0, 0.003) for th in (60, 90, 125, 160, 195, 230, 258)]
	tube(f"ear_rim_{s}", rim, [0.0055, 0.0068, 0.0068, 0.0065, 0.006, 0.0055, 0.0055], MS, SKIN, sides=12, up=n)
	tube(f"ear_ridge_{s}", [pt(th, 0.6, 0.0015) for th in (95, 130, 165, 205)], [0.0035, 0.004, 0.004, 0.0035], MS, SKIN, sides=10, up=n)
	ell(O - n * 0.004 + f * 0.002, (f, up, n), (a * 0.92, b * 0.92, 0.0055), MS, SKIN)        # the bowl
	ell(pt(262, 0.95) + up * 0.006, (f, up, n), (0.011, 0.012, 0.0065), MS, SKIN)          # the lobe
	ell(O + f * 0.022 - up * 0.008, (f, up, n), (0.006, 0.007, 0.006), MS, SKIN)           # the flap
	ell(O + f * 0.016 - n * 0.013, (f, up, n), (0.017, 0.03, 0.013), MS, SKIN)             # joins the head
	if FACE.get("ear_full"):
		# (F737 face 3, owner: "his ears look very weird": with the sides shaved the ear's back shows, and it read as a
		# flat disc on a stalk; a rounded back shell behind the bowl, thick at the root and thin at the rim, like a real ear)
		ell(O - n * 0.008 + f * 0.006, (f, up, n), (a * 0.82, b * 0.86, 0.008), MS, SKIN)
		ell(O - n * 0.015 + f * 0.012, (f, up, n), (a * 0.62, b * 0.7, 0.01), MS, SKIN)


# ---------------------------------------------------------------- the hair (one family of locks)
def hairline(phi):
	"""How high the hair starts (degrees above eye level) round the head: high at the back, low at the temples."""
	return 56 - 32 * (min(abs(phi), 112) / 112) ** 1.3


def scalp_lock(phi, el, shape, k=1.0, width=0.034, thick=0.017, grooves=2):
	R0, n = hit_round("skull", phi, el)
	if R0 is None:
		return
	p = math.radians(phi)
	rh = Dv(math.sin(p), 0, -math.cos(p))
	pts = [R0 - n * 0.007] + [R0 + (n * a + rh * b + UP * c + BACK * d) * k for a, b, c, d in shape]
	lock(pts, width * R.uniform(0.88, 1.12), thick, n, grooves=grooves, twist=jit(0.5), rd=0.2)


EAR_C = (0.137, -0.04, -0.026)
NECK_GAP = (((0.125, -0.075, -0.05), (0.135, -0.27, -0.08)), (0.042, 0.066))  # (head space: the hair-free slot under each ear)


def in_neck_gap(p, extra=0.008):
	"""Is a Blender point inside the hair-free slot under an ear (F943)?"""
	(g0, g1), (r0, r1) = NECK_GAP
	for s in (-1, 1):
		a, b = Hd(s * g0[0], g0[1], g0[2]), Hd(s * g1[0], g1[1], g1[2])
		ab = b - a
		t = min(max((p - a).dot(ab) / ab.dot(ab), 0.0), 1.0)
		if (p - (a + ab * t)).length < r0 + (r1 - r0) * t + extra:
			return True
	return False


def build_hair():
	"""The picture's hair: a thick, puffy mass from temple to temple round the back (below the bald dome, out to 21 cm
	at the sides, 16 cm behind the skull, hanging onto the upper back), covered in fat flame locks that lie on it like
	shingles, swept back and down, their tips lifting off and curling up and out."""
	cl = Clay((-0.25, -0.3, -0.32), (0.25, 0.14, 0.13), 0.0025)
	cl.add(cl.ell((0, -0.005, -0.02), (0.156, 0.125, 0.146)), 0.01)
	for s in (-1, 1):
		cl.add(cl.ell((s * 0.122, 0.045, -0.07), (0.055, 0.06, 0.064)), 0.035)    # the side puffs, above and behind the ears
	# down the back onto the upper back: three strands side by side, fanning out a little (owner, Nov 17 evening: one
	# round tube read as "a very big sausage"; three melt into a wider, flatter fall of hair)
	for x0, x1 in ((-0.035, -0.06), (0.0, 0.0), (0.035, 0.06)) if not FACE.get("short_back") else ():
		cl.add(cl.tube((x0, -0.05, -0.12), (x1, -0.22 + 0.02 * abs(x1) / 0.06, -0.225), 0.05, 0.04), 0.03)
	r = np.sqrt(cl.U ** 2 + cl.W ** 2)
	phi = np.degrees(np.arctan2(cl.U, -cl.W))
	el = np.degrees(np.arctan2(cl.V, r))
	if FACE.get("cap"):
		# (the whole scalp: no bald dome; in front the hair starts at the top of the forehead, 62 degrees up, and above
		# 38 degrees it may reach round past the temples; the front of the mass is squashed onto the skull, swept back)
		cl.keep(np.radians((62 - 150 * np.clip((150 - np.abs(phi)) / 40, 0, 1)) - el) * 0.12, 0.012)  # (above the forehead line)
		cl.keep(np.radians(np.abs(phi) - (117 - 30 * np.clip((10 - el) / 20, 0, 1) + 70 * np.clip((el - 38) / 16, 0, 1))) * 0.12, 0.012)
		cl.keep(cl.ell((0, -0.006, -0.006), (0.135, 0.13, 0.128)) - np.clip((0.02 - cl.W) / 0.06, 0, 1) * 0.2 - np.clip((-0.02 - cl.V) / 0.03, 0, 1) * 0.2, 0.01)
		if FACE.get("short_back"):
			# (round 2, owner: "a different haircut than the first dwarf ... remove all of his back hair"): cropped close
			# round the back of the head, ending at the nape; in front of the ears it still runs down into the beard
			cl.keep(cl.ell((0, -0.008, -0.012), (0.16, 0.13, 0.128)) - np.clip((cl.W - 0.0) / 0.04, 0, 1) * 0.3, 0.01)
			cl.keep((-0.095 - cl.V) - np.clip((cl.W + 0.01) / 0.03, 0, 1) * 0.3, 0.012)
		if FACE.get("cap") == "mohawk":
			# (F737 face 3: both sides shaved; only a strip over the top stays, a bit wider at the back where the braid starts)
			# (round 2: a pad stays in front of each ear, under the sideburn locks; shaved off, its locks showed holes)
			pad = np.minimum(*(cl.ell((s * 0.098, -0.06, 0.02), (0.034, 0.06, 0.036)) for s in (-1, 1)))
			cl.keep(np.minimum(np.abs(cl.U) - (0.042 + 0.012 * np.clip(-cl.W / 0.1, 0, 1)), pad), 0.01)
	else:
		cl.keep(np.radians(el - (56 - 32 * (np.minimum(np.abs(phi), 112) / 112) ** 1.3)) * 0.12, 0.012)  # below the hairline
		cl.keep(np.radians(np.abs(phi) - (117 - 30 * np.clip((10 - el) / 20, 0, 1))) * 0.12, 0.012)  # behind the temples; behind the ears lower down
	del r, phi, el
	for s in (-1, 1):
		cl.cut(cl.ell((s * (EAR_C[0] + 0.01), EAR_C[1], EAR_C[2] + 0.012), (0.06, 0.058, 0.054)), 0.012)  # a notch: the ears stay free
	# (F943, owner Nov 28: "there still should be some skin" at the side of the neck, then picked "gap under the ears"):
	# a slot under each ear where no hair grows, so a strip of neck runs down from the ear into the shoulder
	for s in (-1, 1):
		(g0, g1), (r0, r1) = NECK_GAP
		cl.cut(cl.tube((s * g0[0], g0[1], g0[2]), (s * g1[0], g1[1], g1[2]), r0, r1), 0.015)
	cl.mesh("hair_mass", MH, HAIR)
	del cl
	BVH["hairmass"] = bvh_of([HAIR[-1]])
	ears = [Hd(s * EAR_C[0], EAR_C[1], EAR_C[2]) for s in (-1, 1)]
	rows = [(-3, 12, 0.07), (-15, 13, 0.08), (-27, 14, 0.085), (-40, 14, 0.09), (-54, 13, 0.095), (-68, 11, 0.1), (-84, 9, 0.11), (-100, 7, 0.12)]
	for ri, (d_el, cnt, L) in enumerate(rows if "rows" not in DBG_SKIP and FACE.get("cap") != "mohawk" else []):
		for j in range(cnt):
			phi = -114 + 228 * (j + 0.5 * (ri % 2)) / cnt + jit(4)
			if abs(phi) > 116:
				continue
			el = hairline(phi) + d_el * (1.0 if abs(phi) < 60 else 0.75) + jit(3)
			R0, n = hit_round("hairmass", phi, el)
			if R0 is None or min((R0 - e).length for e in ears) < 0.055:
				continue
			if FACE.get("short_back") and abs(phi) < 80 and R0.z - C.z < -0.06:
				continue  # (the short back: nothing starts below the nape)
			p = math.radians(phi)
			rh = Dv(math.sin(p), 0, -math.cos(p))
			low = ri / (len(rows) - 1)
			want = BACK * (1.0 - 0.6 * low) + DN * (0.35 + 0.9 * low) + rh * 0.15
			t = want - n * want.dot(n)
			if t.length < 1e-4:
				continue
			t.normalize()
			k = L * R.uniform(0.85, 1.15)
			# the tips curl up and out on the upper rows; on the lowest rows they lie flat along the hair (owner, Nov 17:
			# the curled tips at the ponytail's end hooked into his body)
			flat = min(1.0, max(0.0, (low - 0.45) / 0.3))
			curl = (UP * (0.016 * (1 - low)) + n * (0.006 + 0.006 * low)) * (1 - flat)
			lift = 1.0 - 0.8 * flat
			pts = [R0 - n * 0.012 - t * 0.01, R0 + t * 0.33 * k + n * 0.003, R0 + t * 0.66 * k + n * 0.005 * lift,
				R0 + t * 0.9 * k + n * 0.011 * lift + curl * 0.5, R0 + t * k + n * 0.016 * lift + curl]
			if min((p - e).length for p in pts for e in ears) < 0.05 or any(in_neck_gap(p) for p in pts):
				continue  # (the ears stay uncovered, like the picture's; and the neck under them, F943)
			lock(pts, 0.036 * R.uniform(0.9, 1.1), 0.021, n, grooves=2, rd=0.22, twist=jit(0.4))
	# The hanging part (the "ponytail" down onto the upper back) gets its own rows of locks round its back and sides,
	# hanging down along it, tips lying flat (owner, Nov 17: the lower back hair was a bare smooth sheet: the rows above
	# are spread round the whole head, so only one or two narrow locks landed on it).
	A, Bt = Hd(0, -0.05, -0.12), Hd(0, -0.22, -0.23)  # (the clay tube "down the back" above)
	ax = (Bt - A).normalized()
	out = (BACK - ax * BACK.dot(ax)).normalized()  # the tube's back, square to its length
	across = ax.cross(out).normalized()
	RT = random.Random(23)  # (its own dice: the brows, beard and braids built after this keep their exact look)
	for ri, t in enumerate((0.3, 0.52, 0.74, 0.95) if not FACE.get("short_back") else ()):
		cnt = 7 if ri % 2 == 0 else (8 if ri == 3 else 6)
		for j in range(cnt):
			th = math.radians(-112 + 224 * (j + 0.5) / cnt + RT.uniform(-5, 5))
			radial = out * math.cos(th) + across * math.sin(th)
			c = A.lerp(Bt, t)
			R0, n, _, _ = BVH["hairmass"].ray_cast(c + radial * 0.3, -radial, 0.3)
			if R0 is None or min((R0 - e).length for e in ears) < 0.06:
				continue
			# along the hanging hair and on past its end (flat against the round end, the lowest ones stuck out
			# backward: a little visor of their own)
			want = ax * 0.5 + DN * 0.8 + across * (0.12 * math.sin(th))
			tdir = want - radial * want.dot(radial)
			if tdir.length < 1e-4:
				continue
			tdir.normalize()
			k = (0.09 + 0.02 * ri / 3) * RT.uniform(0.88, 1.12)
			if ri == 3:  # (the bottom row: uneven lengths, a ragged fringe of separate tips, not one round end)
				k = RT.uniform(0.08, 0.16)
			pts = [R0 - radial * 0.012 - tdir * 0.01, R0 + tdir * 0.33 * k + radial * 0.003, R0 + tdir * 0.66 * k + radial * 0.002,
				R0 + tdir * 0.9 * k + radial * 0.003, R0 + tdir * k + radial * 0.004]
			if any(in_neck_gap(p) for p in pts):
				continue  # (the neck under the ears stays bare, F943)
			lock(pts, 0.036 * RT.uniform(0.9, 1.1), 0.021, radial, grooves=2, rd=0.22, twist=RT.uniform(-0.4, 0.4))
	# the path of the back hair's swing chain (owner F215: "add the skeleton to the big ponytail that slides down the
	# back, similar to the braids"): one chain down the middle (three side by side swung apart and tore the hair between
	# them, Nov 17), from high on the back of the head, through the middle of the hair layer, to the lowest tips
	BACKS.clear()
	pts = []
	for el in (30, 15, 0, -15, -30, -42) if not FACE.get("short_back") else ():
		P, n = hit_round("hairmass", 0, el)
		if P is None:
			continue
		q = P - n * 0.022
		if pts and q.z > pts[-1].z - 0.01:
			# (Nov 17: lower rays passed under the hanging hair and hit its underside back up by the neck, so the chain
			# folded back up into the neck; the nape hair rode on its swinging end and lifted off: "the bare neck")
			break
		pts.append(q)
	if len(pts) >= 4:
		# ...and on to the lowest hair in the middle of the back (whichever lock reaches lowest), 1 cm up into it
		end = None
		for o in HAIR:
			mw = o.matrix_world
			for v in o.data.vertices:
				q = mw @ v.co
				if abs(q.x) < 0.04 and q.y > C.y + 0.15 and (end is None or q.z < end.z):
					end = q
		end = end + UP * 0.01 if end is not None else None
		print(f"DWARF back-hair chain: {len(pts)} points down the head to {pts[-1].z:.3f} m, the lowest hair at "
			f"{end.z if end else 0:.3f} m, {end.y - pts[-1].y if end else 0:+.3f} m further back")
		if end is None or end.z > pts[-1].z - 0.04:
			end = pts[-1] + ax * 0.1
		pts += [pts[-1].lerp(end, 0.5), end]  # (two even links to the end: the game puts the last tip in line)
		BACKS.append(pts)
	if FACE.get("cap") == "topknot":
		build_topknot()
		return
	if FACE.get("cap") == "mohawk":
		build_crest()
		return
	# the little curl on top of the bald head
	for k, phi in enumerate((-14, 0, 16)):
		scalp_lock(phi, 72 + jit(2), [(0.012, 0.0, 0.006, -0.004), (0.026, 0.0, 0.004, -0.012), (0.03, 0.0, -0.006, -0.02)],
			k=R.uniform(0.85, 1.1), width=0.016, thick=0.01, grooves=1)


DBG_SKIP = [a for a in os.environ.get("DWARF_SKIP", "").split(",") if a]  # (debug: leave parts out to see what covers what)
KNOTS = []  # copper rings that aren't on a braid (the topknot's): hair inside them is pinched in like a braid's


def build_topknot():
	"""(F737 face "topknot") All the hair on top combed back and up into a knot on the crown: a bun, a copper ring
	round it, and a tuft spilling out of the ring and falling back over the back of the head (the picture's top row)."""
	rk = random.Random(31)
	K = Hd(0, 0.138, -0.04)                     # the ring's middle, on top of the head a little behind the crown
	ax = Dv(0, 1.0, -0.45).normalized()         # the ring leans back
	r_in, r_out, ring_h = 0.026, 0.034, 0.03
	cl = Clay((-0.08, 0.05, -0.12), (0.08, 0.2, 0.04), 0.0025)
	cl.add(cl.ell((0, 0.112, -0.03), (0.05, 0.03, 0.055)), 0.01)   # the bun's foot, melting into the hair on top
	ku, kv, kw = 0.0, 0.138, -0.04
	cl.add(cl.tube((0, 0.105, -0.026), (ku + ax.x * 0.026, kv + ax.z * 0.026, kw - ax.y * 0.026), r_in - 0.002, r_in - 0.002), 0.008)  # through the ring
	cl.mesh("topknot_bun", MH, HAIR)
	del cl
	h = ring_h / 2
	prof = [(r_in, -h + 0.003), (r_in + 0.002, -h), (r_out + 0.0015, -h), (r_out + 0.0032, -h + 0.0042), (r_out + 0.0015, -h + 0.0085),
		(r_out, -h + 0.011), (r_out, h - 0.011), (r_out + 0.0015, h - 0.0085), (r_out + 0.0032, h - 0.0042), (r_out + 0.0015, h),
		(r_in + 0.002, h), (r_in, h - 0.003)]
	RINGS.append(lathe("topknot_ring", K, ax, prof, ck.color("h_copper", (0.78, 0.46, 0.26), rough=0.4, metal=0.6)))
	KNOTS.append({"ring": K.copy(), "axis": ax.copy(), "r_in": r_in, "h": ring_h})
	# the tuft: out of the ring, up, then back and down over the back of the head
	s1 = ax.cross(Vector((1, 0, 0))).normalized()   # (in the ring's plane: front-back)
	s2 = Vector((1, 0, 0))
	n_t = 9
	for j in range(n_t):
		a = 2 * math.pi * j / n_t + rk.uniform(-0.25, 0.25)
		rad = s1 * math.cos(a) + s2 * math.sin(a)
		L = rk.uniform(0.85, 1.1)
		side = s2 * (0.03 * math.sin(a))
		pts = [K - ax * 0.012 + rad * r_in * 0.3, K + ax * (h + 0.01) + rad * r_in * 0.85,
			K + (ax * 0.05 + BACK * 0.025 + rad * 0.026 + side) * L, K + (ax * 0.06 + BACK * 0.075 + rad * 0.02 + side * 1.6) * L,
			K + (ax * 0.035 + BACK * 0.12 + DN * 0.02 + rad * 0.012 + side * 2.0) * L]
		lock(pts, 0.034, 0.02, rad, n=16, grooves=2, rd=0.24, twist=rk.uniform(-0.4, 0.4), name=f"topknot_tuft{j}")
	# the hair on top, combed toward the knot, each lock lying on the hair (not standing off it)
	tree = BVH["hairmass"]
	foot = Hd(0, 0.112, -0.03)
	for ri, el in enumerate((42, 50, 58, 66, 74) if "caplocks" not in DBG_SKIP else ()):
		cnt = max(6, int(24 * math.cos(math.radians(el))))
		for j in range(cnt):
			phi = -180 + 360 * (j + 0.5 * (ri % 2)) / cnt + rk.uniform(-4, 4)
			if abs(phi) < 117 and el < hairline(phi) + 2:
				continue  # (the rows of locks round the sides and back already cover it)
			if el < 66 - 150 * min(1.0, max(0.0, (150 - abs(phi)) / 40)):
				continue  # (below the front hairline: bare forehead)
			P, n = hit_round("hairmass", phi, el + rk.uniform(-2, 2))
			if P is None or (P - foot).length < 0.045:
				continue
			L = min(0.075, (P - foot).length - 0.03) * rk.uniform(0.9, 1.1)
			pts = []
			for f in (-0.12, 0.33, 0.66, 1.0):
				Q = P + ((foot - P) - n * (foot - P).dot(n)).normalized() * (L * f)
				loc, nq, _, _ = tree.find_nearest(Q)
				pts.append(loc + nq * (-0.008 if f < 0 else 0.004 + 0.003 * (f > 0.5)))
			lock(pts, 0.034 * rk.uniform(0.9, 1.1), 0.017, n, grooves=2, rd=0.22, twist=rk.uniform(-0.3, 0.3))


def build_crest():
	"""(F737 face 3) The strip of hair left on top of the shaved head: rows of flame locks from the forehead over the
	crown and down the back of the head, each combed backward and lying on the hair, into the back braid."""
	rc = random.Random(37)
	tree = BVH["hairmass"]
	for ri, th in enumerate(range(60, 200, 12) if "caplocks" not in DBG_SKIP else ()):
		us = (-0.026, 0.0, 0.026) if ri % 2 == 0 else (-0.014, 0.014)
		t = math.radians(th)
		d = Dv(0, math.sin(t), math.cos(t))            # (th 0 = straight forward, 90 = up, 180 = back)
		tan = Dv(0, math.cos(t), -math.sin(t))          # (along the head toward the back)
		for u in us:
			u += rc.uniform(-0.004, 0.004)
			loc, n, _, _ = tree.ray_cast(C + Vector((u, 0, 0)) + d * 0.5, -d, 0.6)
			if loc is None:
				continue
			L = (0.08 if th < 160 else 0.065) * rc.uniform(0.88, 1.12)
			lift = 0.012 if th < 80 else 0.006  # (the front locks stand up a little, the picture's swept-up crest)
			pts = []
			for f in (-0.12, 0.33, 0.66, 1.0):
				q, nq, _, _ = tree.find_nearest(loc + tan * (L * f) + Vector((u * 0.15 * f, 0, 0)))
				pts.append(q + nq * (-0.008 if f < 0 else 0.004 + lift * f))
			lock(pts, 0.032 * rc.uniform(0.9, 1.1), 0.018, n, grooves=2, rd=0.22, twist=rc.uniform(-0.3, 0.3))


def build_brows():
	"""Huge bushy brows (the picture's): three layers of thin flame strands on the brow ridge, all sweeping out from the
	nose toward the temple, the outer ones curling up (round 2: two layers of wide locks melted into blocky slabs)."""
	for s in (-1, 1):
		for layer, (cnt, v0, dv, wid, th, lift) in enumerate(((7, 0.022, 0.02, 0.016, 0.008, 0.005), (6, 0.032, 0.017, 0.015, 0.008, 0.009),
				(4, 0.042, 0.011, 0.013, 0.007, 0.012))):
			for k in range(cnt + (2 if FACE.get("brows") == "sly" else 0)):
				f = (k + 0.33 * layer) / cnt
				# inner ends raised (a kind, happy arch, not a cross V: F193)
				u, v = s * (0.012 + 0.088 * f), v0 + dv * math.sin(math.pi * (0.1 + 0.8 * f)) + 0.008 * (1 - f) ** 2
				if FACE.get("frown"):
					# (F737 grumpy faces: the inner ends pulled down to the nose, a flatter arch, low over the eyes)
					# (round 2, owner: "he looks very sleepy, not angry": a straight bar slanting down to the nose, an angry V;
					# the brow runs right over the scar, owner: "I don't mind him to have the second brow, even over the scar")
					u, v = s * (0.01 + 0.084 * f), v0 - 0.006 + 0.026 * f + 0.004 * layer * f
				if FACE.get("brows") == "sly":
					# (F737 face 3: his left brow arched up high, the right one low and flat over the narrowed eye)
					# (round 2, owner: "not identical, at different levels": both the same now, low and flat, a little
					# lift at the outer end; more, wider strands lying flat, so it reads as one calm brow, not spikes)
					f = (k + 0.5 * layer) / (cnt + 2)
					u, v = s * (0.012 + 0.078 * f), v0 + 0.002 + 0.012 * f + 0.003 * layer * f  # (not past the temple: spiky ends)
				if (FACE.get("frown") or FACE.get("brows") == "sly") and layer == 2:
					continue
				if s == 1 and FACE.get("scar_gap") and abs(u - FACE["scar_gap"][0]) < FACE["scar_gap"][1]:
					continue  # (no brow hair grows on the scar)  # (two layers, not three: a thick straight bar, not face 1's huge bush)
				P, n = hit_front("face", u, v)
				if P is None:
					continue
				L = (0.026 + 0.016 * f) * R.uniform(0.85, 1.15)
				up = 0.004 + 0.022 * f ** 1.5
				if FACE.get("frown") or FACE.get("brows") == "sly":
					up, wid, th, lift, L =0.002 + 0.008 * f ** 1.5, wid * 0.9, th * 0.8, lift * 0.5, L * 0.8  # (flat brows lying close)
				if FACE.get("brows") == "sly":
					up, wid, L = 0.001 + 0.004 * f, wid * 1.05, L * 0.9
					lock([P - n * 0.004, P + n * lift + Dv(s * L * 0.35, 0.001, 0), P + n * lift + Dv(s * L * 0.7, 0.002 + up * 0.5, 0),
						P + n * lift * 0.4 + Dv(s * L, up, -0.004)], wid, th, n, grooves=1, rd=0.3, twist=jit(0.15))
					continue
				lock([P - n * 0.004, P + n * lift + Dv(s * L * 0.35, 0.002 + up * 0.2, 0), P + n * (lift + 0.002) + Dv(s * L * 0.7, 0.004 + up * 0.5, 0),
					P + n * lift + Dv(s * L, up, -0.004)], wid, th, n, grooves=2, rd=0.24, twist=jit(0.3))


def wface(u, v, lift):
	"""w just in front of the face at (u, v); beyond the face's edge it wraps back round the cheek."""
	P, _ = hit_front("face", u, v)
	if P is not None and abs(u) < 0.1:
		return w_of(P) + lift
	edge = math.copysign(0.098, u)
	P, _ = hit_front("face", edge, v)
	w0 = w_of(P) if P is not None else 0.08
	return w0 + lift - (abs(u) - 0.098) * 0.9


def build_moustache():
	"""A big curling handlebar: three locks a side growing out from UNDER the nose (the nose stays whole), out over the
	smile, the ends curling up and back; the lower lip shows in the middle."""
	if FACE.get("moustache") == "droop":
		# (F737 grumpy faces: out from under the nose and straight down past the corners of the mouth, no curl)
		for s in (-1, 1):
			for uv, wid, th, lift in (
				([(0.008, -0.08), (0.035, -0.088), (0.058, -0.1), (0.07, -0.122), (0.074, -0.148), (0.072, -0.17)], 0.032, 0.02, 0.008),
				([(0.014, -0.078), (0.042, -0.086), (0.064, -0.1), (0.078, -0.124), (0.084, -0.15)], 0.026, 0.016, 0.015),
				([(0.03, -0.083), (0.054, -0.094), (0.07, -0.112), (0.08, -0.138)], 0.022, 0.014, 0.013)):
				ws = [wface(s * u, v, lift) for u, v in uv]
				for i in range(1, len(ws)):
					ws[i] = max(ws[i], ws[i - 1] - 0.03)  # (the rays at the mouth's corner fall into it: the lock dived in, round 1)
				pts = [Hd(s * u, v, w) for (u, v), w in zip(uv, ws)]
				lock(pts, wid, th, FWD, n=18, grooves=3, rd=0.22)
		return
	if FACE.get("moustache") == "sly":
		# (F737 face 3: out from under the nose, over the mouth's corners and down past the chin, the tips flicking out;
		# on his left, the half-smile side, the whole side lifted a little)
		for s in (-1, 1):
			up = 0.008 if s == 1 else 0.0
			for uv, wid, th, lift in (
				([(0.008, -0.08), (0.036, -0.087), (0.06, -0.098), (0.074, -0.118), (0.082, -0.14), (0.094, -0.155)], 0.028, 0.018, 0.008),
				([(0.016, -0.078), (0.044, -0.084), (0.066, -0.097), (0.08, -0.116), (0.09, -0.134)], 0.022, 0.014, 0.015)):
				uv = [(u, v + up * min(1.0, u / 0.05)) for u, v in uv]
				ws = [wface(s * u, v, lift) for u, v in uv]
				for i in range(1, len(ws)):
					ws[i] = max(ws[i], ws[i - 1] - 0.03)
				lock([Hd(s * u, v, w) for (u, v), w in zip(uv, ws)], wid, th, FWD, n=18, grooves=1, rd=0.26)  # (round 2: 3 grooves showed as dark slits)
		return
	for s in (-1, 1):
		for uv, wid, th, lift in (
			([(0.008, -0.081), (0.04, -0.091), (0.08, -0.103), (0.113, -0.103), (0.136, -0.089), (0.14, -0.071), (0.128, -0.063)], 0.032, 0.02, 0.008),
			([(0.012, -0.078), (0.045, -0.086), (0.085, -0.096), (0.112, -0.096), (0.128, -0.085)], 0.024, 0.015, 0.015),
			([(0.032, -0.084), (0.07, -0.093), (0.105, -0.099), (0.13, -0.096), (0.142, -0.083)], 0.022, 0.014, 0.013)):
			pts = [Hd(s * u, v, wface(s * u, v, lift)) for u, v in uv]
			lock(pts, wid, th, FWD, n=18, grooves=3, rd=0.22)


def build_beard():
	"""Sideburns into a wide beard that flares out at the sides, locks between the braids, and a padded core round the
	jaw and down the front of the neck so nothing shows through."""
	for s in (-1, 1):
		side = 1 if s > 0 else -1
		# the core under the jaw (from below the ear to the chin), kept off the cheeks
		for phi in (100, 118, 136, 154, 172):
			for el in (-48, -60):
				P, n = hit_round("skull", side * phi, el)
				if P is not None:
					HAIR.append(ck.blob(tuple(P - n * 0.006), (0.024, 0.024, 0.024), MH, seed=int(phi + el), jitter=0.1))  # (tucked in)
		# fill between the cheek and the ear (round 2 left a dark gap there: "a hole behind his nose", F193)
		ear = Hd(s * EAR_C[0], EAR_C[1], EAR_C[2])
		for phi in (101, 110, 119):  # (as locks: round filler showed as balls; none closer to the ear: it covered it)
			for el in (-2, -16, -30, -44):
				P, n = hit_round("skull", side * phi, el + jit(3))
				if P is not None and (P - ear).length > 0.05:
					lock([P - n * 0.006, P + n * 0.01 + DN * 0.025, P + n * 0.014 + DN * 0.05 + FWD * 0.006,
						P + n * 0.016 + DN * 0.072 + FWD * 0.01], 0.032, 0.017, n, grooves=2, rd=0.22, twist=jit(0.3))
		# sideburns
		for k, el in enumerate((8, -6, -20)):
			P, n = hit_round("face", side * (107 + 4 * k), el)
			if P is not None:
				lock([P - n * 0.006, P + n * 0.012 + DN * 0.03, P + n * 0.018 + DN * 0.06 + FWD * 0.008, P + n * 0.024 + DN * 0.09 + FWD * 0.014],
					0.036, 0.018, n, grooves=2, twist=jit(0.3))
		# the outer beard: out and down from the jaw, the tips flaring out (the picture's wide beard)
		for k in range(5):
			P, n = hit_round("skull", side * (102 + 9 * k), -30 - 5 * k)
			if P is None:
				continue
			out = Vector((s, 0, 0)) * FACE.get("beard_flare", 1.0)  # (F737 face 3: 0.4, a narrower beard hanging down)
			L = R.uniform(0.9, 1.1)
			lock([P - n * 0.007, P + (n * 0.018 + DN * 0.03 + out * 0.01) * L, P + (n * 0.026 + DN * 0.062 + out * 0.036) * L,
				P + (n * 0.026 + DN * 0.08 + out * 0.062) * L, P + (DN * 0.07 + out * 0.085 + n * 0.02) * L],
				0.044, 0.025, n, grooves=3, twist=jit(0.4))
		# between the braids: one short lock straight down (round 2's two long slanting ones crossed into the braids)
		P, n = hit_round("skull", side * 152, -46)
		if P is not None and not FACE.get("beard_point"):  # (F737 round 2: it glued the braids to the beard's point)
			lock([P - n * 0.006, P + n * 0.016 + DN * 0.03 + FWD * 0.02, P + DN * 0.07 + FWD * 0.04],
				0.036, 0.02, n, grooves=3, twist=jit(0.3))
	# the chin (into the middle braid)
	for phi in (-12, 0, 12):
		P, n = hit_round("face", 180 + phi, -56)
		if P is not None:
			lock([P - n * 0.006, P + n * 0.012 + DN * 0.03 + FWD * 0.012, P + DN * 0.07 + FWD * 0.03], 0.036, 0.02, n, grooves=2)
	# the core under the chin, in front of the neck (only there: lower down these stood out in front of the braids)
	for s in (-1, 1):  # (between the braids: hanging locks; round filler there showed as two balls)
		P, n = hit_round("skull", s * 138, -52)
		if P is not None and "core" not in DBG_SKIP:
			for k in range(2 if not FACE.get("beard_point") else 1):
				off = Vector((s * 0.018 * k, 0, 0))
				lock([P - n * 0.006 + off, P + n * 0.012 + DN * 0.035 + FWD * 0.02 + off, P + DN * 0.075 + FWD * 0.035 + off * 1.3,
					P + DN * 0.105 + FWD * 0.04 + off * 1.5], 0.034, 0.02, n, grooves=3, twist=jit(0.3))
	if FACE.get("beard_point") and "point" not in DBG_SKIP:
		build_beard_point()
	for u in (0.0,) if not FACE.get("beard_point") and not FACE.get("braids") else ():  # (face 3: it showed as a white ball under the mouth)  # (F737 round 4: with the point it showed as a bulb under the mouth)
		for v in (-0.15,):
			sf = max([x for x in (shirt_front(u, v + dv) for dv in (0.03, 0.0, -0.036)) if x is not None] or [0.0])
			w = max(sf, 0.075) + GAP + 0.02  # (behind the beard locks: further out it showed as balls)
			HAIR.append(ck.blob(tuple(Hd(u, v, w)), (0.04, 0.032, 0.036), MH, seed=int(u * 100 + v * 1000), jitter=0.1))


# ---------------------------------------------------------------- braids, copper rings, tufts
RINGS = []
BRAIDS = []  # each braid's path (top to tuft tip), ring and size: for the swing bones and the ring check
POINTS = []  # (F737) a beard point with no ring: its own swing bones like a braid (no ring check)
BACKS = []   # the back hair's swing-chain paths (Blender points, nape to tips)
# the hair hanging down the back (the "ponytail"): its own swing bones, from the nape down onto the upper back
PONYTAIL = [(0.0, -0.03, -0.13), (0.0, -0.1, -0.18), (0.0, -0.17, -0.22), (0.0, -0.24, -0.25)]


def lathe(name, ctr, axis, profile, m, segs=40):
	"""A ring turned round `axis` from a closed (radius, height) outline."""
	ax = axis.normalized()
	s1 = ax.orthogonal().normalized()
	s2 = ax.cross(s1)
	verts, faces = [], []
	P = len(profile)
	for i in range(segs):
		a = 2 * math.pi * i / segs
		d = s1 * math.cos(a) + s2 * math.sin(a)
		for r, z in profile:
			verts.append(tuple(ctr + d * r + ax * z))
	for i in range(segs):
		for j in range(P):
			a, b = i * P + j, i * P + (j + 1) % P
			c, e = ((i + 1) % segs) * P + (j + 1) % P, ((i + 1) % segs) * P + j
			faces.append((a, b, c, e))
	o = kit._mesh_obj(name, verts, faces, m)
	ck._fix_normals(o)
	return o


def braid(name, u_top, v_top, v_ring, v_end, W0, W1, D0, D1, r_in, r_out, ring_h, w_top, tuft_n=7, seed=0, back=False):
	"""A three-strand braid lying on the body: plump lobes slanting in from each edge in turn (the picture's chevrons),
	its core pinched under a copper ring, then a tuft that swells and ends in points. back: hangs from the back of the
	head down the upper back instead (F737 round 4, owner: "we should have a braid at the back of his head still")."""
	rr = random.Random(seed)
	vs = np.linspace(v_top, v_end, 48)
	girth = []
	for v in vs:
		f = min(max((v_top - v) / (v_top - v_ring), 0.0), 1.0)
		girth.append(D0 + (D1 - D0) * f if v > v_ring else 2.2 * r_out)
	us = [u_top * (1.0 + 0.12 * min(max((v_top - v) / (v_top - v_end), 0), 1)) for v in vs]
	floor = []
	for u, v, g in zip(us, vs, girth):
		if back:  # (behind the body or the skull, whichever is further back; up on the head it sinks into the hair cap)
			hits = [w_of(loc) for tree in ("body", "skull") for loc in [BVH[tree].ray_cast(Hd(u, v, -0.9), FWD, 2.0)[0]] if loc]
			wb = min(hits) if hits else w_top
			on_head = min(max((v - (v_top - 0.07)) / 0.05, 0.0), 1.0)  # (1 high on the head, 0 from the nape down)
			floor.append(min(wb - GAP - g / 2 + on_head * (GAP + g * 0.6), w_top - g / 2 * (1 - on_head)))
		else:
			sf = shirt_front(u, v)
			floor.append(max((sf + GAP + g / 2) if sf is not None else -1.0, w_top + g / 2))
	ws = list(floor)
	for _ in range(6):  # smooth the path, but never closer to the body than the gap
		ws = [(min if back else max)(floor[i], (ws[max(i - 1, 0)] + ws[i] + ws[min(i + 1, len(ws) - 1)]) / 3) for i in range(len(ws))]
	B = _resample([Hd(u, v, w) for u, v, w in zip(us, vs, ws)], 80)
	arc = [0.0]
	for a, b in zip(B[:-1], B[1:]):
		arc.append(arc[-1] + (b - a).length)

	def at(s):
		s = min(max(s, 0.0), arc[-1])
		i = min(int(s / arc[-1] * 79), 78)
		while i < 78 and arc[i + 1] < s:
			i += 1
		while i > 0 and arc[i] > s:
			i -= 1
		f = (s - arc[i]) / max(arc[i + 1] - arc[i], 1e-9)
		p = B[i].lerp(B[i + 1], f)
		T = (B[i + 1] - B[i]).normalized()
		_, nb, _, _ = BVH["body"].find_nearest(p, 0.4)
		N = nb if nb is not None else FWD.copy()
		N = (N + (BACK if back else FWD) * 0.6)
		N = (N - T * N.dot(T)).normalized()
		return p, T, N, T.cross(N)
	s_ring = next(arc[i] for i, p in enumerate(B) if p.z <= Hd(0, v_ring, 0).z)

	def size(s):
		f = min(s / max(s_ring, 1e-6), 1.0)
		return W0 + (W1 - W0) * f, D0 + (D1 - D0) * f
	# the core: fills the braid; thin enough under the ring to pass through it
	core = []
	for i in range(0, 80, 2):
		s = arc[i]
		if s > s_ring + ring_h * 0.6:
			break
		Wd, Dd = size(s)
		# near the ring the core fills the ring's hole (owner, Nov 17: above the rings the braids were too thin and didn't
		# touch the rings: the core stayed thinner than the hole), easing back to its own size 2.5 cm away
		x = min(max((abs(s - s_ring) - ring_h * 0.5) / 0.025, 0.0), 1.0)
		near = 1.0 - x * x * (3 - 2 * x)
		rw = Wd * 0.3 + ((r_in - 0.002) - Wd * 0.3) * near
		rd_ = Dd * 0.3 + ((r_in - 0.002) - Dd * 0.3) * near
		core.append((B[i], max(rw, 0.008), max(rd_, 0.008)))
	HAIR.append(ck.loft(name + "_core", core, MH, sides=16, subsurf=1, up=FWD))
	# the lobes
	s, k = 0.0, 0
	stop = s_ring - ring_h * 0.5 + 0.004  # (the plaits run right into the ring: they stopped short of it)
	while True:
		Wd, Dd = size(s)
		step = 0.42 * Wd
		s += step if k else 0.3 * step
		if s > stop:
			break
		sig = 1 if k % 2 == 0 else -1
		pA, TA, NA, SA = at(s - 1.0 * step)
		pB, TB, NB, SB = at(s)
		pC, TC, NC, SC = at(min(s + 1.1 * step, stop + 0.006))
		lock([pA + SA * (sig * 0.4 * Wd) - NA * (0.1 * Dd), pB + SB * (sig * 0.1 * Wd) + NB * (0.24 * Dd),
			pC - SC * (sig * 0.3 * Wd) - NC * (0.16 * Dd)], 0.4 * Wd, 0.34 * Dd, NB, n=14, sides=18, grooves=2, rd=0.26,
			name=f"{name}_lobe{k}", leaf=True)
		k += 1
	# the copper ring
	pR, TR, NR, SR = at(s_ring)
	h = ring_h / 2
	prof = [(r_in, -h + 0.003), (r_in + 0.002, -h), (r_out + 0.0015, -h), (r_out + 0.0032, -h + 0.0042), (r_out + 0.0015, -h + 0.0085),
		(r_out, -h + 0.011), (r_out, h - 0.011), (r_out + 0.0015, h - 0.0085), (r_out + 0.0032, h - 0.0042), (r_out + 0.0015, h),
		(r_in + 0.002, h), (r_in, h - 0.003)]
	RINGS.append(lathe(name + "_ring", pR, TR, prof, ck.color("h_copper", (0.78, 0.46, 0.26), rough=0.4, metal=0.6)))
	BRAIDS.append({"name": name, "path": [p.copy() for p in B], "ring": pR.copy(), "axis": TR.copy(), "r_in": r_in, "h": ring_h,
		"reach": W0 * 0.75})
	# the tuft: swells out of the ring, then comes to points
	end = arc[-1]
	L = end - (s_ring + h)
	for j in range(tuft_n):
		a = 2 * math.pi * j / tuft_n + rr.uniform(-0.3, 0.3)

		def off(s_, r_):
			p, T, N, S = at(s_)
			rad = S * math.cos(a) + N * max(math.sin(a), -0.4)
			return p + rad * r_
		swirl = rr.uniform(-0.25, 0.25)
		lenf = rr.uniform(0.68, 1.0) if j else 1.0
		pts = [off(s_ring - h * 0.4, r_in * 0.3), off(s_ring + h + 0.01, r_in * 0.9), off(s_ring + h + 0.3 * L * lenf, r_out * 1.05),
			off(s_ring + h + 0.62 * L * lenf, r_out * 0.78), off(s_ring + h + L * lenf, r_out * rr.uniform(0.25, 0.5)) + at(end)[3] * (swirl * 0.05)]
		lock(pts, 0.03 * (W0 / 0.1) ** 0.3, 0.02, at(s_ring + h + 0.3 * L)[2], n=16, grooves=2, rd=0.26, twist=rr.uniform(-0.5, 0.5),
			name=f"{name}_tuft{j}")
	return pR


def build_beard_point():
	"""(F737, no middle braid) The middle of the beard: rows of locks from the chin down the chest, narrowing to one
	point between the two braids, each lying on the body (the shirt front) with the usual gap."""
	rp = random.Random(41)
	for ri, (v0, half, cnt) in enumerate(((-0.13, 0.036, 3), (-0.17, 0.032, 3), (-0.21, 0.024, 2), (-0.25, 0.014, 2), (-0.285, 0.0, 1))):
		if os.environ.get("DWARF_PROWS") and str(ri) not in os.environ["DWARF_PROWS"]:
			continue
		for j in range(cnt):
			u0 = 0.0 if cnt == 1 else -half + 2 * half * j / (cnt - 1)
			u0 += rp.uniform(-0.004, 0.004)
			L = 0.085 + 0.01 * ri
			pts = []
			for f in (0.0, 0.35, 0.7, 1.0):
				u, v = u0 * (1.0 - 0.55 * f), v0 - L * f
				sf = max([x for x in (shirt_front(u, v + dv) for dv in (0.02, 0.0)) if x is not None] or [0.075])
				pts.append(Hd(u, v, max(sf, 0.07) + GAP + 0.024 + 0.004 * (1 - f)))
			lock(pts, 0.036 - 0.004 * ri, 0.022, FWD, n=16, grooves=3, rd=0.24, twist=rp.uniform(-0.3, 0.3))  # (narrower, round 2: a gap to each braid)
	# (round 3, owner: "his middle braid is attached to his shirt": it lay on the shirt and followed the chest. Now it
	# stands 1 cm further off and gets its own swing bones down its middle, like the first face's middle braid.)
	path = []
	for v in np.linspace(-0.12, -0.405, 8):
		sf = max([x for x in (shirt_front(0.0, v + dv) for dv in (0.02, 0.0)) if x is not None] or [0.075])
		path.append(Hd(0.0, v, max(sf, 0.07) + GAP + 0.026))
	POINTS.append({"name": "braid_mid", "path": path, "reach": 0.03})  # (0.05 reached the side braids: 138 glued edges)


def build_braids():
	if FACE.get("braids"):
		for k, (name, u) in enumerate(FACE["braids"]):
			braid(name, u, -0.13, -0.29, -0.43, 0.088, 0.068, 0.054, 0.046, 0.034, 0.042, 0.046, w_top=0.075, tuft_n=8, seed=2 + k)
		if FACE.get("back_braid"):  # (a warrior's braid from the back of the head down between the shoulders)
			braid("braid_back", 0.0, -0.01, -0.25, -0.37, 0.084, 0.068, 0.06, 0.052, 0.033, 0.041, 0.042,  # (round 5, owner: "thicker")
				 w_top=-0.1, tuft_n=7, seed=7, back=True)
		return
	braid("braid_mid", 0.0, -0.14, -0.35, -0.49, 0.13, 0.09, 0.06, 0.05, 0.04, 0.048, 0.044, w_top=0.1, tuft_n=9, seed=1)  # (thicker: owner F214)
	for s in (-1, 1):  # (further out: at 11.5 cm their tops clashed with the middle braid, owner round 2b)
		# (at 14.5 cm the thicker braids touched the middle one and melted together: a sheet when they swung apart)
		braid(f"braid_{s}", s * 0.168, -0.13, -0.246, -0.37, 0.08, 0.064, 0.048, 0.042, 0.032, 0.039, 0.046, w_top=0.06, tuft_n=7, seed=2 + s)  # (thicker: F214)


# ---------------------------------------------------------------- melt, sculpt, lay on the body
def arrays(o):
	me = o.data
	n = len(me.vertices)
	co = np.empty(n * 3)
	me.vertices.foreach_get("co", co)
	no = np.empty(n * 3)
	me.vertex_normals.foreach_get("vector", no)
	return co.reshape(-1, 3), no.reshape(-1, 3)


def put(o, co):
	o.data.vertices.foreach_set("co", co.ravel())
	o.data.update()


def line_dist(co, pts):
	P = np.array([tuple(p) for p in pts])
	d = np.full(len(co), 1e9)
	for a, b in zip(P[:-1], P[1:]):
		ab = b - a
		t = np.clip(((co - a) @ ab) / max(ab @ ab, 1e-12), 0, 1)
		d = np.minimum(d, np.linalg.norm(co - (a + t[:, None] * ab), axis=1))
	return d


def on_face(uvs, tree="high"):
	out = []
	for u, v in uvs:
		P, _ = hit_front(tree, u, v)
		if P is not None:
			out.append(P)
	return out


STUBBLE = None  # (F737 face 3) how much stubble dot each point of the melted head has (set by sculpt_face)


def sculpt_face(high, skin):
	"""The face's sculpted detail (only where it's skin): wavy forehead wrinkles, crow's feet, smile bags under the
	eyes, the mouth line, nostrils, and a fine skin grain."""
	co, no = arrays(high)
	h = np.zeros(len(co))
	near = np.linalg.norm(co - np.array(tuple(C)), axis=1) < 0.3

	def groove(pts, depth, width, ridge=0.0):
		nonlocal h
		if len(pts) < 2:
			return
		d = line_dist(co[near], pts)
		g = -depth * np.exp(-(d / width) ** 2) + ridge * depth * np.exp(-((d - 2.2 * width) / width) ** 2)
		h[near] += g
	for k, vk in enumerate((0.058, 0.071, 0.085)):  # forehead wrinkles
		span = 0.072 - 0.012 * k
		groove(on_face([(u, vk + 0.003 * math.sin(u * 55 + 1.7 * k)) for u in np.linspace(-span, span, 15)]), 0.002, 0.002, 0.35)
	for s in (-1, 1):
		c0 = (s * 0.073, 0.003)
		for ang in (-28, 0, 26):  # crow's feet
			a = math.radians(ang)
			groove(on_face([(c0[0] + s * 0.004 * math.cos(a), c0[1] + 0.004 * math.sin(a)),
				(c0[0] + s * 0.019 * math.cos(a), c0[1] + 0.019 * math.sin(a))]), 0.0009, 0.0011)
		groove(on_face([(s * 0.028, -0.016), (s * 0.046, -0.021), (s * 0.064, -0.015)]), 0.0012, 0.0016, 0.3)  # smile bags
		groove(on_face([(s * 0.025, 0.01), (s * 0.035, 0.019), (s * 0.047, 0.023), (s * 0.06, 0.02), (s * 0.071, 0.011)]),
			0.0013, 0.0013, 0.4)  # the fold above each upper lid
	if FACE.get("smirk"):  # (F737 face 3: a crooked half-smile: flat on his right, curling up on his left, with a dimple)
		groove(on_face([(-0.032, -0.1), (-0.016, -0.101), (0.0, -0.1), (0.02, -0.096), (0.034, -0.087), (0.041, -0.079)]), 0.0025, 0.0014)
		groove(on_face([(0.046, -0.07), (0.05, -0.081), (0.049, -0.092)]), 0.0016, 0.0016, 0.3)
	else:
		groove(on_face([(-0.034, -0.093), (-0.02, -0.099), (0.0, -0.1), (0.02, -0.099), (0.034, -0.093)]), 0.0025, 0.0014)  # mouth
	if FACE.get("old"):  # (F737 face 3: an old face: deeper forehead lines, long crow's feet, bags and lines from the nose)
		for k, vk in enumerate((0.05, 0.064, 0.078, 0.093)):
			span = 0.075 - 0.01 * k
			groove(on_face([(u, vk + 0.004 * math.sin(u * 48 + 2.1 * k)) for u in np.linspace(-span, span, 15)]), 0.0026, 0.0019, 0.4)
		for s in (-1, 1):
			for ang in (-34, -12, 10, 30):
				a = math.radians(ang)
				groove(on_face([(s * 0.074 + s * 0.004 * math.cos(a), 0.003 + 0.004 * math.sin(a)),
					(s * 0.074 + s * 0.026 * math.cos(a), 0.003 + 0.026 * math.sin(a))]), 0.0013, 0.0012)
			groove(on_face([(s * 0.03, -0.024), (s * 0.048, -0.03), (s * 0.066, -0.022)]), 0.0015, 0.0016, 0.3)  # (a second bag)
			groove(on_face([(s * 0.038, -0.05), (s * 0.05, -0.07), (s * 0.058, -0.09)]), 0.0018, 0.0018, 0.3)
			groove(on_face([(s * 0.008, 0.014), (s * 0.01, 0.03)]), 0.0016, 0.0015, 0.3)
	if FACE.get("old"):  # (round 2, owner: "wrinkles on top of his forehead, but we need those in the face as well")
		for s in (-1, 1):
			for k in range(3):  # cheek lines: curving out and down under the eye bags
				groove(on_face([(s * (0.05 + 0.008 * k), -0.036 - 0.008 * k), (s * (0.066 + 0.008 * k), -0.046 - 0.009 * k),
					(s * (0.078 + 0.007 * k), -0.062 - 0.008 * k)]), 0.0019, 0.0013, 0.3)
			for k in range(3):  # fine lines under the lower lid
				groove(on_face([(s * 0.034, -0.012 - 0.0045 * k), (s * 0.05, -0.016 - 0.005 * k), (s * 0.066, -0.01 - 0.005 * k)]), 0.0014, 0.0011, 0.3)
			for k in range(2):  # lines down the outer cheek, in front of the ear
				groove(on_face([(s * (0.092 + 0.006 * k), -0.02), (s * (0.096 + 0.006 * k), -0.05), (s * (0.094 + 0.006 * k), -0.08)]), 0.0020, 0.0016, 0.3)
			groove(on_face([(s * 0.05, -0.092), (s * 0.054, -0.108), (s * 0.052, -0.124)]), 0.0024, 0.0018, 0.3)  # by the mouth's corner
			groove(on_face([(s * 0.088, 0.03), (s * 0.096, 0.012)]), 0.0017, 0.0014, 0.3)  # the temple
		for k in range(3):  # across the top of the nose
			groove(on_face([(-0.011, -0.002 - 0.006 * k), (0.0, -0.004 - 0.006 * k), (0.011, -0.002 - 0.006 * k)]), 0.0015, 0.0012, 0.3)
	for s in (-1, 1):  # nostrils, from below
		loc, _, _, _ = BVH["face"].ray_cast(Hd(s * 0.014, -0.2, 0.15), UP, 0.3)
		if loc is not None:
			d = np.linalg.norm(co - np.array(tuple(loc)), axis=1)
			h += -0.004 * np.exp(-(d / 0.0045) ** 2)
	# round the nose, the nostril wings and the cheeks by them the skin stays smooth (owner, Nov 17 night: "smooth, not
	# rocky"): the grain and bumps fade out there
	rel = co - np.array(tuple(C))
	calm = np.ones(len(co))
	for s in (-1, 1, 0):
		d = np.linalg.norm((rel - np.array([s * 0.04, -0.125, -0.055])) / np.array([0.045, 0.035, 0.035]), axis=1)
		calm = np.minimum(calm, np.clip(d - 0.6, 0.0, 1.0) * 0.8 + 0.2)
	for i in np.nonzero(near & (skin > 0.5))[0]:  # skin grain and a few soft bumps on the bald head
		p = Vector(co[i])
		h[i] += calm[i] * (0.00022 * noise.fractal(p * 320, 0.5, 2.0, 2) + 0.0005 * noise.noise(p * 30))
	if FACE.get("frown"):  # (F737 grumpy faces: two deep frown lines between the brows, and lines from the nose down)
		for s in (-1, 1):
			groove(on_face([(s * 0.008, 0.012), (s * 0.011, 0.03), (s * 0.012, 0.046)]), 0.0022, 0.0017, 0.4)
			groove(on_face([(s * 0.038, -0.05), (s * 0.05, -0.07), (s * 0.058, -0.09)]), 0.0016, 0.0018, 0.3)
	for sc in FACE.get("scars", []):  # old scars: a raised, puckered line with a little dip each side
		pts = on_face(sc, "face")  # (on the bare skin: on the melted head its top landed on brow hair, unpainted, round 4)
		if len(pts) >= 2:
			SCARS3D.append(pts)
			d = line_dist(co[near], pts)
			h[near] += 0.0032 * np.exp(-(d / 0.0034) ** 2) - 0.0009 * np.exp(-((d - 0.0048) / 0.0016) ** 2)
	if FACE.get("stubble"):  # (the dots are a little raised too, so the baked bumps catch the light)
		global STUBBLE
		ns = np.array([noise.noise(Vector(p) * 330) for p in co])
		STUBBLE = np.clip((ns - 0.18) / 0.14, 0, 1)
		h += 0.00025 * STUBBLE
	h *= skin
	put(high, co + no * h[:, None])


def sculpt_hair(high, hair):
	"""A little unevenness on every lock, so they look carved by hand, not machine-made."""
	co, no = arrays(high)
	h = np.zeros(len(co))
	for i in np.nonzero(hair > 0.5)[0]:
		p = Vector(co[i])
		h[i] = 0.0007 * noise.noise(p * 70) + 0.0012 * noise.noise(p * 18)
	put(high, co + no * h[:, None])


def lay_on_body(high, hair, rounds=3):
	"""Hair and beard rest ON the body: any point inside it or closer than GAP is pushed out along the body's surface
	(a soft limit, then smoothed), like a beard lying on a big belly. (Owner, F183: the beard went through the body.)"""
	me = high.data
	ev = np.empty(len(me.edges) * 2, dtype=np.int64)
	me.edges.foreach_get("vertices", ev)
	ev = ev.reshape(-1, 2)
	blend = 0.006
	moved_total = 0
	for rnd in range(rounds):
		co, _ = arrays(high)
		moved = np.zeros(len(co), bool)
		inside = []
		for i in np.nonzero(hair > 0.5)[0]:
			loc, nrm, _, d = BVH["body"].find_nearest(Vector(co[i]), 0.25)  # (deep inside too, not only near the skin)
			if loc is None:
				continue
			sd = (Vector(co[i]) - loc).dot(nrm)
			if sd < 0 and rnd == 0:
				inside.append((sd, co[i].copy()))
			if sd >= GAP + blend:
				continue
			x = sd - (GAP - blend)
			want = GAP if x <= 0 else GAP + x * x / (4 * blend)
			co[i] = np.array(tuple(loc + nrm * want))
			moved[i] = True
		if inside:
			pts = np.array([p for _, p in inside])
			print(f"HEAD hair inside the body before laying it on: {len(inside)} points, deepest {min(s for s, _ in inside) * 100:.1f} cm, "
				f"x {pts[:, 0].min():.2f}..{pts[:, 0].max():.2f} y {pts[:, 1].min():.2f}..{pts[:, 1].max():.2f} z {pts[:, 2].min():.2f}..{pts[:, 2].max():.2f}")
		# smooth what moved (and its neighbours) so the pushed patch has no crease (not after the last push: the gap holds)
		zone = moved.copy()
		zone[ev[moved[ev[:, 0]], 1]] = True
		zone[ev[moved[ev[:, 1]], 0]] = True
		for _ in range(3 if rnd < rounds - 1 else 0):
			acc = np.zeros_like(co)
			cnt = np.zeros(len(co))
			np.add.at(acc, ev[:, 0], co[ev[:, 1]])
			np.add.at(acc, ev[:, 1], co[ev[:, 0]])
			np.add.at(cnt, ev[:, 0], 1)
			np.add.at(cnt, ev[:, 1], 1)
			avg = acc / np.maximum(cnt, 1)[:, None]
			co[zone] = co[zone] * 0.5 + avg[zone] * 0.5
		put(high, co)
		moved_total = int(moved.sum())
	return moved_total


def pinch_rings(high, hair):
	"""Hair inside a copper ring stays 2.5 mm inside the ring's hole, so none pokes through the band (owner, F194);
	just above and below, it eases back out over 1.5 cm."""
	co, _ = arrays(high)
	moved = 0
	for b in BRAIDS + KNOTS:
		c, ax = np.array(tuple(b["ring"])), np.array(tuple(b["axis"].normalized()))
		rel = co - c
		t = rel @ ax
		radial = rel - t[:, None] * ax
		r = np.linalg.norm(radial, axis=1)
		half = b["h"] / 2 + 0.003
		ease = np.clip((np.abs(t) - half) / 0.015, 0.0, 1.0)  # 0 inside the band, 1 at 1.5 cm beyond it
		limit = (b["r_in"] - 0.0025) + ease * 0.05
		# (F737 round 4: 6 cm also caught the beard point's edge and stretched it into a spike toward the ring)
		sel = (hair > 0.5) & (np.abs(t) < half + 0.015) & (r > limit) & (r < b["r_in"] + FACE.get("ring_reach", 0.06))
		co[sel] = c + t[sel, None] * ax + radial[sel] / r[sel, None] * limit[sel, None]
		moved += int(sel.sum())
	put(high, co)
	return moved


def creases(high, iters=10):
	"""How deep each point sits in a crease (m): its distance below a smoothed copy of the surface. The gaps between
	locks and braid lobes come out deep, the tops of the locks shallow (for the dark shading in the creases, F191)."""
	co, no = arrays(high)
	me = high.data
	ev = np.empty(len(me.edges) * 2, dtype=np.int64)
	me.edges.foreach_get("vertices", ev)
	ev = ev.reshape(-1, 2)
	sm = co.copy()
	cnt = np.zeros(len(co))
	np.add.at(cnt, ev[:, 0], 1)
	np.add.at(cnt, ev[:, 1], 1)
	for _ in range(iters):
		acc = np.zeros_like(sm)
		np.add.at(acc, ev[:, 0], sm[ev[:, 1]])
		np.add.at(acc, ev[:, 1], sm[ev[:, 0]])
		sm = 0.5 * sm + 0.5 * acc / np.maximum(cnt, 1)[:, None]
	return np.maximum(((sm - co) * no).sum(1), 0.0)


def nose_pockets(high, mask, log=print, reach=0.02, rays=64):
	"""How shut-in the skin is round the nose and the cheeks (owner, Nov 17: "a dark hole under the nose, at the side"):
	for each skin point there, the share of rays (spread over the half-sphere it faces) that hit the head or the
	moustache within `reach`. Deep pockets bake dark; the worst ones are printed in head space (u, v, w, cm)."""
	co, no = arrays(high)
	tree = bvh_of([high])
	rel = co - np.array(tuple(C))
	u, v, w = rel[:, 0], rel[:, 2], -rel[:, 1]
	near_eye = np.zeros(len(co), bool)
	for s in (-1, 1):  # (behind the lids and the eyeball: never seen)
		near_eye |= np.linalg.norm(co - np.array(tuple(eye_centre(s))), axis=1) < EYE_R + 0.012
	pick = np.nonzero((mask < 0.5) & ~near_eye & (np.abs(u) > 0.008) & (np.abs(u) < 0.095) & (v > -0.1) & (v < -0.005) & (w > 0.06))[0]
	rr = random.Random(3)
	dirs = []
	while len(dirs) < rays:  # (even directions over a sphere; flipped onto each point's own side below)
		d = Vector((rr.gauss(0, 1), rr.gauss(0, 1), rr.gauss(0, 1)))
		if d.length > 1e-6:
			dirs.append(d.normalized())
	occ = np.zeros(len(pick))
	for j, i in enumerate(pick):
		n = Vector(no[i])
		p = Vector(co[i]) + n * 0.0006
		hit = 0
		for d in dirs:
			d2 = d if d.dot(n) > 0 else -d
			if tree.ray_cast(p, d2, reach)[0] is not None:
				hit += 1
		occ[j] = hit / rays
	seen = occ < 0.97  # (all rays blocked: covered by the moustache, can't be seen)
	occ = np.where(seen, occ, 0.0)
	log(f"HEAD nose pockets: {int(seen.sum())} visible skin points checked; shut in >50%: {int((occ > 0.5).sum())}, >65%: {int((occ > 0.65).sum())}")
	low_ = v[pick] < -0.03  # (under the nose; the lid creases above are listed apart)
	log(f"   under the nose: shut in >50%: {int((occ[low_] > 0.5).sum())}, >65%: {int((occ[low_] > 0.65).sum())}, worst {occ[low_].max() * 100:.0f}%")
	shown = []
	for j in np.argsort(-np.where(low_, occ, 0.0)):
		i = pick[j]
		if occ[j] < 0.5 or len(shown) >= 10:
			break
		if any(np.linalg.norm(co[i] - co[k]) < 0.006 for k in shown):
			continue
		shown.append(i)
		log(f"   {occ[j] * 100:.0f}% at u {u[i] * 100:+.1f} v {v[i] * 100:+.1f} w {w[i] * 100:+.1f} cm")
	return occ


PRE = []  # the hair points before melting: [positions, lock ids, groove values]


def hard_lines(high, pre):
	"""The owner's "hard lines on the beard": a crisp dark line wherever one lock meets the next (where the nearest
	points before melting come from two different locks, equally close) and down each lock's grooves. 0..1 per point."""
	from mathutils import kdtree
	pts, ids, grv = pre
	kd = kdtree.KDTree(len(pts))
	for i, p in enumerate(pts):
		kd.insert(p, i)
	kd.balance()
	co, _ = arrays(high)
	out = np.zeros(len(co))
	for vi, p in enumerate(co):
		near = kd.find_n(Vector(p), 10)
		if not near:
			continue
		_, i0, d0 = near[0]
		if d0 > 0.012:
			continue  # (skin, far from any hair piece)
		seam = 0.0
		for _, i1, d1 in near[1:]:
			if ids[i1] != ids[i0]:
				seam = max(0.0, 1.0 - (d1 - d0) / 0.0016)
				break
		groove = max(0.0, (-grv[i0] - 0.72) / 0.22) if ids[i0] > 0 else 0.0
		out[vi] = min(1.0, max(seam, 0.85 * groove))
	return smooth_values(high, out, 1)


def body_gap(high, hair):
	"""The closest any hair point comes to the body (m; negative = inside): the automatic clipping check at rest."""
	co, _ = arrays(high)
	worst = 1.0
	for i in np.nonzero(hair > 0.5)[0]:
		loc, nrm, _, d = BVH["body"].find_nearest(Vector(co[i]), 0.25)
		if loc is not None:
			worst = min(worst, (Vector(co[i]) - loc).dot(nrm))
	return worst


def hair_mask(high, skin_tree, hair_tree):
	"""1 where the melted skin is hair, 0 where it's skin: whichever family of pieces the point lies on."""
	co, _ = arrays(high)
	out = np.zeros(len(co))
	for i, p in enumerate(co):
		v = Vector(p)
		ds = skin_tree.find_nearest(v, 0.03)[3]
		dh = hair_tree.find_nearest(v, 0.03)[3]
		ds = 1.0 if ds is None else ds
		dh = 1.0 if dh is None else dh
		out[i] = 1.0 if dh < ds else 0.0
	return out


def smooth_values(o, vals, iters=4):
	"""Average a per-point value with its neighbours (a soft hairline instead of a jagged one)."""
	me = o.data
	ev = np.empty(len(me.edges) * 2, dtype=np.int64)
	me.edges.foreach_get("vertices", ev)
	ev = ev.reshape(-1, 2)
	x = vals.astype(float).copy()
	for _ in range(iters):
		acc = np.zeros(len(x))
		cnt = np.zeros(len(x))
		np.add.at(acc, ev[:, 0], x[ev[:, 1]])
		np.add.at(acc, ev[:, 1], x[ev[:, 0]])
		np.add.at(cnt, ev[:, 0], 1)
		np.add.at(cnt, ev[:, 1], 1)
		x = 0.5 * x + 0.5 * acc / np.maximum(cnt, 1)
	return x


def measure(high, mask, log=print):
	"""Numbers to compare with the picture before looking at any picture (cheap checks)."""
	co, _ = arrays(high)
	u, v, w = co[:, 0] - C.x, co[:, 2] - C.z, C.y - co[:, 1]
	hair, skin = mask > 0.5, mask <= 0.5
	out = {}
	out["crown (m, want 1.19)"] = co[skin, 2].max()
	nt, _ = hit_front("high", 0, -0.042)
	out["nose tip w (want 0.19)"] = w_of(nt) if nt is not None else None
	band = skin & (np.abs(u) < 0.01) & (np.abs(v + 0.042) < 0.01)
	out["nose tip w from the points (want 0.19)"] = w[band].max() if band.any() else None
	from mathutils import kdtree
	kd = kdtree.KDTree(len(co))
	for i, p in enumerate(co):
		kd.insert(p, i)
	kd.balance()

	def is_skin(p):
		return p is not None and mask[kd.find(p)[1]] <= 0.5
	out["nose tip is skin, not moustache"] = is_skin(nt)
	for s in (-1, 1):
		hits = [hit_round("high", s * a, e)[0] for a in (65, 75, 85) for e in (-5, -15, -25)]
		out[f"ear {s}: side rays landing on skin (of 9)"] = sum(is_skin(p) for p in hits)
		out[f"ear {s}: rays (az 65/75/85 x el -5/-15/-25), 1 = skin"] = "".join("1" if is_skin(p) else "0" for p in hits)
		front = [hit_front("high", s * uu, vv)[0] for uu in (0.135, 0.15) for vv in (-0.02, -0.04, -0.06)]
		out[f"ear {s} seen from the front: rays on skin (of 6)"] = sum(is_skin(p) for p in front)
	for s in (-1, 1):
		seen = 0
		for du, dv in ((0, 0), (0.007, 0), (-0.007, 0), (0, 0.004), (0, -0.003)):
			E = eye_centre(s)
			p, _ = hit_front("high", E.x - C.x + du, E.z - C.z + dv)
			front = w_of(E) + math.sqrt(max(EYE_R ** 2 - du * du - dv * dv, 0))
			seen += 1 if (p is None or w_of(p) < front - 0.0005) else 0
		out[f"eye {s} rays that reach the eye (of 5)"] = seen
	band = hair & (np.abs(v - 0.0) < 0.012)
	out["hair half-width at eye level (want 0.21)"] = np.abs(u[band]).max() if band.any() else None
	band = hair & (np.abs(v + 0.1) < 0.015)
	out["hair behind the skull's middle at v=-0.1 (want 0.27)"] = -w[band].min() if band.any() else None
	band = hair & (np.abs(v + 0.14) < 0.012) & (w > 0)
	out["beard half-width under the chin (want 0.21)"] = np.abs(u[band]).max() if band.any() else None
	band = skin & (np.abs(v - 0.0) < 0.01) & (w > 0)
	out["face skin half-width at eye level (want 0.118)"] = np.abs(u[band]).max() if band.any() else None
	for k, val in out.items():
		log(f"MEASURE {k}: {val if not isinstance(val, float) else round(val, 3)}")


def plain(name, rgb, rough=0.75, metal=0.0):
	m = bpy.data.materials.new(name)
	m.use_nodes = True
	b = m.node_tree.nodes["Principled BSDF"]
	b.inputs["Base Color"].default_value = (*cs.lin(rgb), 1)
	b.inputs["Roughness"].default_value = rough
	b.inputs["Metallic"].default_value = metal
	return m


SKIN_RGB_1, HAIR_RGB_1 = (0.86, 0.62, 0.5), (0.74, 0.36, 0.16)  # (face 1's; set_face() picks a face's own)
SKIN_RGB, HAIR_RGB = SKIN_RGB_1, HAIR_RGB_1


def build(body_objs, fast=False, log=print):
	"""Build the head, hair and beard around the body. fast: skip the light copy and the bake (shape checks only)."""
	global MS, MH
	t0 = time.time()
	MS = ck.color("h_skin", SKIN_RGB, rough=0.7)
	MH = ck.color("h_hair", HAIR_RGB, rough=0.8)
	SKIN.clear(), LIDS.clear(), HAIR.clear(), RINGS.clear(), BRAIDS.clear(), POINTS.clear(), KNOTS.clear(), SCARS3D.clear()
	BVH["body"] = bvh_of(body_objs)
	build_face()
	BVH["skull"] = bvh_of(SKIN[:1])
	BVH["face"] = bvh_of(SKIN + LIDS)
	build_hair()
	if "brows" not in DBG_SKIP:
		build_brows()
	if "moustache" not in DBG_SKIP:
		build_moustache()
	build_beard()
	build_braids()
	# eyes: one smooth ball each, painted later (iris, pupil, shine), never melted
	eyes = []
	for s in (-1, 1):
		bpy.ops.mesh.primitive_uv_sphere_add(segments=40, ring_count=20, radius=EYE_R, location=eye_centre(s))
		e = bpy.context.object
		e.data.materials.append(ck.color("h_eye", (0.95, 0.92, 0.86), rough=0.3))
		for p in e.data.polygons:
			p.use_smooth = True
		eyes.append(e)
	log(f"HEAD pieces: {len(SKIN)} skin, {len(LIDS)} lids, {len(HAIR)} hair, {len(RINGS)} rings ({time.time() - t0:.0f} s)")
	skin_tree, hair_tree = bvh_of(SKIN + LIDS), bvh_of(HAIR)
	for o in SKIN + LIDS + HAIR:  # (joining keeps only the first piece's smoothing: apply each piece's own first)
		cs._apply_all(o)
	# remember every hair point before melting: its lock and groove (for the hard lines)
	pre_pts, pre_id, pre_gr = [], [], []
	for k, o in enumerate(HAIR):
		me_ = o.data
		ia, ga = me_.attributes.get("lock_id"), me_.attributes.get("groove")
		for vi, v in enumerate(me_.vertices):
			pre_pts.append(o.matrix_world @ v.co)
			pre_id.append(ia.data[vi].value if ia else -1 - k)
			pre_gr.append(ga.data[vi].value if ga else 0.0)
	PRE[:] = [pre_pts, pre_id, pre_gr]
	high = cs.melt(SKIN + LIDS + HAIR, voxel=VOX, smooth=2, name="head_high")
	log(f"HEAD melted: {len(high.data.polygons)} faces ({time.time() - t0:.0f} s)")
	mask = (smooth_values(high, hair_mask(high, skin_tree, hair_tree), 4) > 0.5).astype(float)
	BVH["high"] = bvh_of([high])
	measure(high, mask, log)
	sculpt_face(high, 1.0 - mask)
	sculpt_hair(high, mask)
	moved = lay_on_body(high, mask)
	log(f"HEAD hair kept inside the copper rings: {pinch_rings(high, mask)} points")
	gap = body_gap(high, mask)
	log(f"HEAD laid on the body: {moved} points moved; closest hair to the body {gap * 100:.2f} cm ({time.time() - t0:.0f} s)")
	nose_pockets(high, mask, log)
	# which faces are hair (for painting)
	me = high.data
	pv = np.empty(len(me.loops), dtype=np.int64)
	me.loops.foreach_get("vertex_index", pv)
	starts = np.empty(len(me.polygons), dtype=np.int64)
	me.polygons.foreach_get("loop_start", starts)
	fm = np.add.reduceat(mask[pv], starts) / np.diff(np.append(starts, len(pv)))
	me.materials.clear()
	ring_obj = RINGS[0]
	if len(RINGS) > 1:
		bpy.ops.object.select_all(action="DESELECT")
		for r in RINGS:
			r.select_set(True)
		bpy.context.view_layer.objects.active = RINGS[0]
		bpy.ops.object.join()
		ring_obj = bpy.context.view_layer.objects.active
	ring_obj.name = "rings"
	bpy.ops.object.select_all(action="DESELECT")
	for e in eyes:
		e.select_set(True)
	bpy.context.view_layer.objects.active = eyes[0]
	bpy.ops.object.join()
	eye_obj = bpy.context.view_layer.objects.active
	eye_obj.name = "eyes"
	if fast:
		me.materials.append(plain("skin_plain", SKIN_RGB))
		me.materials.append(plain("hair_plain", HAIR_RGB, 0.8))
		me.polygons.foreach_set("material_index", (fm > 0.5).astype(np.int32))
		hi_eyes = eye_obj
		cs.eye_attrs(hi_eyes, lambda side: tuple(eye_look(side)))
		eye_obj.data.materials.clear()
		eye_obj.data.materials.append(cs.paint_eye("paint_eye", iris_out=(0.3, 0.17, 0.08), iris_in=(0.56, 0.34, 0.15), iris_deg=30.0, pupil_deg=13.0, shine_deg=7.5))
		high.name = "head"
		log(f"HEAD done (fast) {time.time() - t0:.0f} s")
		return {"head": high, "eyes": eye_obj, "rings": ring_obj, "mask": mask}
	# ---- paint (clay colours: the shape check before the real paint), light copies, bake
	# One paint for the whole skin; each point carries its own colour (skin or hair, blended over ~3 mm at the hairline,
	# so the border is soft, not a staircase of faces), the paint adds the shading (dark creases, light edges and tops).
	soft = np.clip((smooth_values(high, mask, 3) - 0.3) / 0.4, 0.0, 1.0)
	sk, hr = np.array(cs.lin(SKIN_RGB)) / 0.74, np.array(cs.lin(HAIR_RGB)) / 0.74
	cols = sk[None, :] * (1 - soft[:, None]) + hr[None, :] * soft[:, None]
	# dark hair in the creases: between the locks and round the braid lobes (like the back of the hair, F191)
	deep = smooth_values(high, np.clip(creases(high) / 0.0045, 0.0, 1.0), 2)
	shade = 1.0 - FACE.get("crease_dark", 0.72) * soft * deep ** 0.8  # (face 3, white hair: 0.72 showed as black slits in the moustache)
	cols = cols * shade[:, None]
	cols = cols * np.array([1.0, 0.92, 0.85])[None, :] ** (soft * deep)[:, None]  # (deeper red-brown, not grey)
	# hard lines (owner, round 2b: "I don't see shades, we need hard lines on the beard"): a narrow, sharp-edged dark
	# line in every groove and where one lock lies over the next, like the inked lines of the picture
	# the lash lines: a dark line along each lid's edge where it meets the eye (thicker on the upper lid), so the lids
	# read as lids (owner, Nov 17: "there's no eyelids")
	co_, _ = arrays(high)
	for s in (-1, 1):
		E = np.array(tuple(eye_centre(s)))
		dist = np.linalg.norm(co_ - E, axis=1)
		gap = dist - EYE_R
		above = (co_[:, 2] - E[2]) > 0
		# (only round the front of the eye, where the lids are: skin deep in the socket's outer corner, behind the lids,
		# also sat right against the eyeball and got the dark line: from the side it showed as "a hole behind his
		# nose", owner Nov 17, F193)
		front = np.clip(((E[1] - co_[:, 1]) / np.maximum(dist, 1e-6) - 0.45) / 0.15, 0.0, 1.0)
		lash = np.clip(1.0 - np.abs(gap - 0.0012) / np.where(above, 0.0016, 0.001), 0.0, 1.0) * (1 - soft) * front  # (only AT the lid edge: a ring all round looked like no lids)
		cols = cols * (1.0 - np.where(above, 0.82, 0.6) * lash)[:, None]
	# (round 2b's crease-depth lines were too faint to see once baked: now drawn from how the hair is built)
	ink = hard_lines(high, PRE) * soft
	cols = cols * (1.0 - FACE.get("ink", 0.8) * ink)[:, None]  # (F737 face 3: softer on white hair, 0.8 read as dirt)
	for pts in SCARS3D:  # (F737) the scars: pale pink in the middle, a darker red edge
		d = line_dist(co_, pts)
		mid = np.exp(-(d / 0.0036) ** 2) * (1 - soft)  # (round 5: wider, to show on the shut lid's shadow)
		rim = np.exp(-((d - 0.005) / 0.0018) ** 2) * (1 - soft)
		pale = np.array(cs.lin((0.97, 0.72, 0.66))) / 0.74
		cols = cols * (1 - mid[:, None]) + pale[None, :] * 1.1 * mid[:, None]
		cols = cols * (1.0 - 0.45 * rim[:, None] * np.array([0.35, 1.0, 1.0])[None, :])  # (round 1's thin faint line didn't show)
	rel = co_ - np.array(tuple(C))
	hu, hv, hw = rel[:, 0], rel[:, 2], -rel[:, 1]  # (head space)
	if FACE.get("eye_paint"):
		# (F737 face 3: soot painted round both eyes. Round 2, owner: "just black weird goo, not detailed": now charcoal
		# laid on in brush strokes: streaky sideways strokes (darker and lighter), a frayed edge where the strokes end,
		# a sweep out to the temple, and two thin drips running down each cheek)
		streak = np.array([noise.noise(Vector((x * 50, z * 420, y * 50))) for x, y, z in co_])
		ns = np.array([noise.noise(Vector(p) * 140) for p in co_])
		char = np.array(cs.lin((0.16, 0.15, 0.17))) / 0.74
		for s in (-1, 1):
			du = (hu - s * 0.06) * s  # (+ toward the temple)
			e = (du / np.where(du > 0, 0.05, 0.034)) ** 2 + ((hv + 0.003 - 0.1 * np.clip(du, 0, None)) / 0.024) ** 2
			edge = 1.3 - e + 0.45 * streak + 0.15 * ns
			soot = np.clip(edge / 0.25, 0.0, 1.0) * (hw > 0.04) * (1 - soft)
			soot = soot * (0.8 + 0.2 * np.clip(streak * 2.5 + 0.5, 0, 1))  # (the brush strokes: some darker, some thinner)
			for k, (u0, L) in enumerate(((0.046, 0.032), (0.068, 0.022))):
				pts = on_face([(s * u0, -0.02), (s * (u0 + 0.002), -0.02 - L * 0.5), (s * (u0 + 0.001), -0.02 - L)])
				if len(pts) >= 2:
					d = line_dist(co_, pts)
					t = np.clip((-0.02 - hv) / L, 0, 1)  # (thinner toward the drip's end)
					soot = np.maximum(soot, np.exp(-(d / (0.0028 * (1 - 0.6 * t) + 0.0004)) ** 4) * (hv < -0.012) * (1 - soft) * 0.85)
			cols = cols * (1 - soot[:, None]) + char[None, :] * soot[:, None]
	if FACE.get("stubble"):
		# (the shaved sides, round 2, owner: "little dots like he had hair there"): clear grey-white stubble dots on
		# the shaved scalp, round the ears and down the sideburns to the beard
		hr_ = np.array(cs.lin(HAIR_RGB)) / 0.74
		scalp = np.clip((hv + 0.07) / 0.03, 0, 1) * np.clip((0.06 - hw) / 0.03, 0, 1) * np.clip((np.abs(hu) - 0.03) / 0.02, 0, 1) * (1 - soft)
		cols = cols * (1 - 0.12 * scalp[:, None])  # (a faint grey shadow where the hair was shaved)
		cols = cols * (1 - 0.75 * STUBBLE[:, None] * scalp[:, None]) + hr_[None, :] * 0.9 * (0.75 * STUBBLE * scalp)[:, None]
	log(f"HEAD hard lines on {int((ink > 0.5).sum())} hair points; dark creases on {int((soft * deep > 0.5).sum())}")
	at = me.color_attributes.new("tint", "FLOAT_COLOR", "POINT")
	at.data.foreach_set("color", np.concatenate([cols, np.ones((len(cols), 1))], 1).ravel())
	me.materials.append(cs.paint_material("paint_clay", base=(0.95, 0.95, 0.95), dark=(0.42, 0.3, 0.26), light=(1.0, 0.97, 0.94),
		strokes=0.04, top_light=0.12, edge=0.28, key=0.28, seed=2, tint_attr="tint"))
	low = cs.game_copy(high, 44000, "head")
	cs.bake(high, low, 2048, "head_baked", ext=0.012)
	hi_eyes = cs.detail_copy(eye_obj, 2, "eyes_high")
	cs.eye_attrs(hi_eyes, lambda side: tuple(eye_look(side)))
	hi_eyes.data.materials.clear()
	hi_eyes.data.materials.append(cs.paint_eye("paint_eye", iris_out=(0.3, 0.17, 0.08), iris_in=(0.56, 0.34, 0.15), iris_deg=30.0, pupil_deg=13.0, shine_deg=7.5))
	cs.uv_only(eye_obj)
	cs.bake(hi_eyes, eye_obj, 512, "eye_baked", normal=False)
	eye_obj.data.materials[0].node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.2
	hi_rings = cs.detail_copy(ring_obj, 2, "rings_high")

	def hammered(p, n):  # hammer dents (round, ~4 mm)
		f = noise.voronoi(p * 220, distance_metric="DISTANCE")[0]
		return -0.0005 * max(0.0, 1.0 - f[0] / 0.45) ** 2
	cs._displace(hi_rings, hammered)
	hi_rings.data.materials.clear()
	hi_rings.data.materials.append(cs.paint_material("paint_copper", base=(0.78, 0.47, 0.27), dark=(0.38, 0.17, 0.08),
		light=(0.98, 0.74, 0.5), strokes=0.05, top_light=0.12, edge=0.6, key=0.3, seed=8))
	cs.uv_only(ring_obj)
	mat = cs.bake(hi_rings, ring_obj, 512, "copper_baked", ext=0.008)
	b = mat.node_tree.nodes["Principled BSDF"]
	b.inputs["Metallic"].default_value = 0.55
	b.inputs["Roughness"].default_value = 0.45
	for o in (high, hi_eyes, hi_rings):
		bpy.data.objects.remove(o, do_unlink=True)
	log(f"HEAD done: head {sum(len(p.vertices) - 2 for p in low.data.polygons)} triangles ({time.time() - t0:.0f} s)")
	return {"head": low, "eyes": eye_obj, "rings": ring_obj, "mask": None}


# ---------------------------------------------------------------- the review picture (the recipe: same angle as the picture)
def review(out_png, log=print):
	"""Front and side of the model next to the approved head picture, same scale: [picture | model] per row."""
	scene = bpy.context.scene
	engines = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
	scene.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in engines else "BLENDER_EEVEE"
	W, H = 680, 887
	scene.render.resolution_x, scene.render.resolution_y = W, H
	scene.view_settings.view_transform = "Standard"
	w = bpy.data.worlds.new("rw")
	w.use_nodes = True
	w.node_tree.nodes["Background"].inputs[0].default_value = (0.63, 0.63, 0.63, 1)
	w.node_tree.nodes["Background"].inputs[1].default_value = 1.0
	scene.world = w
	sun = bpy.data.objects.new("rsun", bpy.data.lights.new("rsun", "SUN"))
	sun.data.energy = 2.6
	sun.rotation_euler = (math.radians(50), math.radians(-20), math.radians(-30))
	scene.collection.objects.link(sun)
	cam = bpy.data.objects.new("rcam", bpy.data.cameras.new("rcam"))
	cam.data.type = "ORTHO"
	cam.data.sensor_fit = "VERTICAL"
	cam.data.ortho_scale = H / PX_PER_M
	scene.collection.objects.link(cam)
	scene.camera = cam
	zc = 1.19 + 35 / PX_PER_M - H / PX_PER_M / 2
	for o in scene.objects:  # the arms (held straight out, T-pose) would block the side view
		if o.type == "MESH" and o.name not in ("head", "eyes", "rings"):
			c = sum((o.matrix_world @ Vector(b) for b in o.bound_box), Vector()) / 8
			if abs(c.x) > 0.17:
				o.hide_render = True
	shots = []
	for tag, loc, look in (("front", Vector((0, -3, zc)), Vector((0, 1, 0))), ("side", Vector((3, 0.0, zc)), Vector((-1, 0, 0)))):
		cam.location = loc
		cam.rotation_euler = look.to_track_quat("-Z", "Y").to_euler()
		path = str(Path(out_png).with_name(Path(out_png).stem + f"_{tag}.png"))
		scene.render.filepath = path
		bpy.ops.render.render(write_still=True)
		shots.append(path)
	ref = bpy.data.images.load(str(PIC))
	rw, rh = ref.size
	rp = np.array(ref.pixels[:], dtype=np.float32).reshape(rh, rw, 4)
	rows = []
	for (x0, path) in ((157, shots[0]), (900, shots[1])):
		crop = rp[max(rh - H, 0):, x0:x0 + W]
		if crop.shape[0] < H:
			crop = np.concatenate([np.ones((H - crop.shape[0], W, 4), np.float32), crop], 0)
		mod = bpy.data.images.load(path)
		mp = np.array(mod.pixels[:], dtype=np.float32).reshape(H, W, 4)
		rows.append(np.concatenate([crop, mp], axis=1))
	canvas = np.concatenate([rows[1], rows[0]], axis=0)  # (Blender pictures start at the bottom row: front on top)
	small = canvas.reshape(canvas.shape[0] // 2, 2, canvas.shape[1] // 2, 2, 4).mean(axis=(1, 3)) if canvas.shape[0] % 2 == 0 else canvas
	for arr, p in ((canvas, out_png), (small, str(Path(out_png).with_name(Path(out_png).stem + "_small.png")))):
		img = bpy.data.images.new("cmp", arr.shape[1], arr.shape[0])
		img.pixels = arr.ravel()
		img.filepath_raw = p
		img.file_format = "PNG"
		img.save()
	# a close-up of the face from the front-left (eyes, lids, nose, moustache, mouth)
	scene.render.resolution_x = scene.render.resolution_y = 640
	cam.data.ortho_scale = 0.3
	tgt = Hd(0, -0.03, 0.08)
	az, el = math.radians(-62), math.radians(8)
	cam.location = tgt + Vector((-math.cos(az) * math.cos(el), math.sin(az) * math.cos(el), math.sin(el))) * 3
	cam.rotation_euler = (tgt - cam.location).to_track_quat("-Z", "Y").to_euler()
	scene.render.filepath = str(Path(out_png).with_name(Path(out_png).stem + "_face.png"))
	bpy.ops.render.render(write_still=True)
	# the side of the face, behind the nose and under the eye (owner, Nov 17: "a hole behind his nose", F193)
	tgt = Hd(0.07, -0.03, 0.05)
	cam.location = tgt + Vector((1.0, -0.4, 0.2)).normalized() * 3  # (from his left side, a little in front)
	cam.rotation_euler = (tgt - cam.location).to_track_quat("-Z", "Y").to_euler()
	scene.render.filepath = str(Path(out_png).with_name(Path(out_png).stem + "_cheek.png"))
	bpy.ops.render.render(write_still=True)
	# under the nose from the front-left and below: where the round nose, the nostril wing, the cheek and the moustache
	# meet (owner, Nov 17 night: "still one dark hole under the nose")
	cam.data.ortho_scale = 0.16
	tgt = Hd(0.03, -0.055, 0.12)
	cam.location = tgt + Vector((0.75, -1.0, -0.45)).normalized() * 3
	cam.rotation_euler = (tgt - cam.location).to_track_quat("-Z", "Y").to_euler()
	scene.render.filepath = str(Path(out_png).with_name(Path(out_png).stem + "_nose.png"))
	bpy.ops.render.render(write_still=True)
	cam.data.ortho_scale = 0.3
	# the hair hanging down the back, from behind and a little to the side (owner, Nov 17: "a bare sheet")
	cam.data.ortho_scale = 0.55
	tgt = Hd(0, -0.13, -0.14)
	az, el = math.radians(58), math.radians(10)
	cam.location = tgt + Vector((-math.cos(az) * math.cos(el), math.sin(az) * math.cos(el), math.sin(el))) * 3
	cam.rotation_euler = (tgt - cam.location).to_track_quat("-Z", "Y").to_euler()
	scene.render.filepath = str(Path(out_png).with_name(Path(out_png).stem + "_back.png"))
	bpy.ops.render.render(write_still=True)
	log(f"REVIEW {out_png}")
