# The dwarf's armor sets, hand-built OVER the finished dwarf body (Claude, Nov 18, 2026; F55, MODEL-RULES Rule 1).
#
#   blender --background --factory-startup --python tools/asset_forge/builds/dwarf_armor.py -- <set> <out.glb> [fast] [review=<pic.png>]
#
# <set>: hide, copper or bronze (the SETS recipe below; docs/design/armor.md).
#
# ONE recipe for every metal set (F914, owner Nov 26: "we cannot do armor one by one"): a metal set is the hide set
# with metal plates riveted on top of the leather (plate_shell: plates follow the leather, with gaps between them, a
# rim and a slight dome), about 1 cm bulkier, shoulder guards a third bigger, fatter fleece. A new metal set = a new
# SETS entry (plate colours, plate picture, rivet colours); every shape comes from the hide pieces.
# fast: plain colours, no painting (shape checks). review=<pic.png>: photos of the dwarf wearing the set (arms down).
#
# How it fits him: the finished body (assets/characters/dwarf/dwarf_body.glb, with its skeleton) is loaded, and each
# piece is sculpted as a shell a set distance off his real surface (like a mould taken from him): the helmet over the
# head and hair, the jerkin over the shirt, the boots over the foot wraps. Every armor point then copies the bones of
# the body point under it (the jerkin moves exactly like the shirt under it, swinging hem included), so it bends with
# him in every animation. The game puts it on the same skeleton (DwarfRig._wear_armor).
#
# Parts are separate meshes per material, named armor_<head|chest|feet>_<material>: leather, fleece, brass, cord
# (metal sets: plate and rivet instead of brass).
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

# ================================================================ THE SET RECIPE (F914, owner Nov 26: "take how [the leather]
# looks and expand it to make it bulkier and more metal-wise ... we cannot do armor one by one")
# Every metal set is the Hide set's own shapes (the same moulds of his body, so it always fits) with metal PLATES laid
# over the leather panels: each panel of the cap, the jerkin and the boots becomes a thick plate with a raised rim and
# rivets in its corners, the leather showing dark in the gaps between them; the shoulder guards turn to metal and grow.
# Belt, cross-strap, laces and fleece stay (owner's picks, Nov 26: plates on leather, keep the fleece, medium bulk,
# 3 pieces). A new set = one more entry here, nothing else:
#   plate: the metal's paint (base/dark/light) and its hand-painted tile [file under assets/, repeats per metre]
#   rivet: the rivet heads' paint and tile;  bulk: how thick the plates stand off the leather (metres)
#   pads: how much bigger the shoulder guards get;  rim: the raised plate rims' height (metres)
#   amount: how strongly the tile shows;  metal/rough: the shine the game shows (metal 0-1, rough 0 = mirror)
#   hard: HARD PLATE armour (round 2, owner on round 1: "doesn't look like metal, it looks like a recolor leather";
#     concept assets/concepts/dwarf/dwarf_copper_plate.png): stiff plates that don't follow the leather's lumps, sharp
#     sides with a bevelled, polished edge (bevel, polish), lames that overlap like roof tiles (flare), a closed helmet
#     with a face guard (eye slits, a nose plate, only the beard out), gauntlets over his hands and full plate boots;
#     no fleece, no laces, no cross strap. The Hide set keeps its own way (hard off).
SETS = {
	"hide": dict(plates=False),
	"copper": dict(plates=True, hard=True, bulk=0.011, pads=1.35, rim=0.0, bevel=0.0045, flare=0.006,
		rimw=0.0085, rimh=0.0024,  # (round 3: a raised rim round every plate, owner: "you can see the rims around each plate")
		# (round 1 looked like dark blotchy leather; round 2: darker hammered faces, bright polished edges, more shine)
		# (round 4, owner: brighter, redder copper like the picture, bigger hammer dents that show)
		plate=dict(base=(0.8, 0.36, 0.16), dark=(0.33, 0.11, 0.04), light=(1.0, 0.66, 0.42), strokes=0.05,
			picture=["textures/kit/copper_a.png", 7.0], amount=0.22, metal=0.8, rough=0.27,
			polish=(1.75, 1.32, 1.05), face=0.92),
		rivet=dict(base=(0.84, 0.46, 0.24), dark=(0.3, 0.12, 0.05), light=(1.0, 0.78, 0.55), strokes=0.05,
			picture=["textures/kit/copper_a.png", 18.0], amount=0.3, metal=0.8, rough=0.27),
		# (round 4: the cloth and leather under the plates dark, so the gaps between plates read as deep shadow)
		under=dict(base=(0.2, 0.12, 0.08), dark=(0.08, 0.045, 0.03), light=(0.3, 0.19, 0.12), strokes=0.1)),
}
# bronze (F914, Nov 27): the copper set's shapes, gold-brown bronze, finer hammering, dark green patina edges
# (owner's picks; the helmet + chest + gauntlets come from copper_plate_armor.py metal=bronze, this file gives the legs
# and boots). polish is a multiplier on the plate colour: ~patina / bronze.
SETS["bronze"] = dict(SETS["copper"],
	plate=dict(base=(0.85, 0.62, 0.32), dark=(0.4, 0.27, 0.11), light=(0.98, 0.82, 0.55), strokes=0.04,
		picture=["textures/kit/bronze_a.png", 10.0], amount=0.15, metal=0.78, rough=0.22,
		polish=(0.08, 0.22, 0.22), face=0.95),
	rivet=dict(base=(0.06, 0.15, 0.1), dark=(0.03, 0.07, 0.05), light=(0.12, 0.25, 0.18), strokes=0.05,
		picture=["textures/kit/bronze_a.png", 18.0], amount=0.2, metal=0.4, rough=0.55))
if SET not in SETS:
	raise SystemExit(f"ARMOR: no '{SET}' set (sets: {', '.join(SETS)})")
RC = SETS[SET]
HARD = bool(RC.get("hard"))
RIVET = "rivet" if RC["plates"] else "brass"  # (the Hide set's brass rivets keep their old part name)
if RC["plates"]:
	MAT["plate"] = plain("plate", RC["plate"]["base"])
	MAT["rivet"] = plain("rivet", RC["rivet"]["base"])
	for k in ("plate", "rivet"):
		PAINT[k] = {q: RC[k][q] for q in ("base", "dark", "light", "strokes")}
		PICTURE[(k, None)] = RC[k]["picture"]
if RC.get("under"):
	PAINT["leather"] = RC["under"]


def plate_shell(surf, cell, reg, gap=0.0045, k=0.003, bulk=None):
	"""Metal plates over a leather surface (surf: its distance field, negative inside). cell = how far each point is
	inside its plate's outline (metres, positive inside). Each plate: from 3 mm inside the leather out to `bulk`, a
	bevelled edge `gap` in from the outline (the leather shows between plates), a raised rim round its edge and a slight
	dome; never past the leather's own edge (reg) less 1.2 cm, so a leather border shows at every edge."""
	bulk, rim = (RC["bulk"] if bulk is None else bulk), RC["rim"]
	dome = 0.0018 * np.clip((cell - gap) / 0.03, 0, 1)
	top = surf - bulk - dome
	ridge = np.exp(-(((cell - gap) - 0.0055) / 0.0028) ** 2) * rim
	top = top - ridge
	p = np.maximum(top, -surf - 0.003)
	p = smax(p, gap - cell, k)
	return smax(p, reg + 0.012, k)


def plate_tint(cell_id):
	"""Each plate its own shade (Rule 6, medium variety: one a little redder, one darker, one more worn)."""
	def tint(co):
		ids = cell_id(co[:, 0], co[:, 1], co[:, 2]).astype(int)
		r = np.random.default_rng(7)
		shades = r.uniform(0.86, 1.12, 64)
		warm = r.uniform(-0.05, 0.05, 64)
		s, w = shades[ids % 64], warm[ids % 64]
		return np.stack([s * (1 + w), s, s * (1 - w)], 1)
	return tint


DENT = 30.0  # hammer dents per metre (about 3 cm each; round 4, owner: bigger dents that show, like the picture's)


def hammer_dents(co):
	"""0 on the ridges between hammer dents, 1 in a dent's middle (co: points, n x 3)."""
	out = np.empty(len(co), np.float32)
	for i, p in enumerate(co):
		d = noise.voronoi(Vector(p) * DENT, distance_metric="DISTANCE")[0]
		out[i] = d[1] - d[0]
	return np.clip(out / 0.55, 0.0, 1.0)


def plate_disp(q, n):
	"""Hammered metal: shallow dents from the smith's hammer, and a little grain."""
	if HARD:
		d = noise.voronoi(q * DENT, distance_metric="DISTANCE")[0]
		return -0.0016 * min((d[1] - d[0]) / 0.55, 1.0) ** 0.7 + 0.00015 * noise.noise(q * 400)
	return 0.0006 * noise.noise(q * 70) - 0.0005 * abs(noise.noise(q * 140)) + 0.0002 * noise.noise(q * 400)


def plate_items(target, pts, size=0.0062):
	"""Rivets on a plate: pts = [(outside point, inward direction)], each shot onto the plate."""
	items = []
	tb = bvh_of(target)
	for o, d in pts:
		hit = ray_to(tb, Vector(o), Vector(d))
		if hit and (hit[0] - Vector(o)).length < 0.52:  # (not the far side's inside)
			items.append((hit[0] - hit[1] * 0.0012, hit[1], None, "rivet", size))
	return items


def stitch_band(dist_in, phase, inset=0.009, width=0.0026, dash=0.007):
	"""Light dashed stitches `inset` in from an edge (dist_in: how far inside the edge, metres; phase: distance along)."""
	on = np.abs(dist_in - inset) < width / 2
	return on & (np.sin(phase * 2 * math.pi / dash) > -0.1)


# ================================================================ HARD plates (F914 round 2: real metal, not painted leather)
GAP = 0.004  # half the dark line between two hard plates (metres)


def sstep(x):
	c = np.clip(x, 0.0, 1.0)
	return c * c * (3 - 2 * c)


def sample(g, F, co, nearest=False):
	"""A grid's values at points co (n x 3): blended from the 8 grid points round each (nearest: the closest one).
	Points outside the grid get inf."""
	f = (co - g.lo) / g.h
	n = np.array(F.shape)
	out_ = np.any((f < 0) | (f > n - 1), axis=1)
	if nearest:
		i = np.clip(np.rint(f).astype(int), 0, n - 1)
		v = F[i[:, 0], i[:, 1], i[:, 2]].astype(np.float64)
	else:
		i0 = np.clip(np.floor(f).astype(int), 0, n - 2)
		t = np.clip(f - i0, 0, 1)
		v = np.zeros(len(co))
		for dx in (0, 1):
			for dy in (0, 1):
				for dz in (0, 1):
					w = (t[:, 0] if dx else 1 - t[:, 0]) * (t[:, 1] if dy else 1 - t[:, 1]) * (t[:, 2] if dz else 1 - t[:, 2])
					v += w * F[i0[:, 0] + dx, i0[:, 1] + dy, i0[:, 2] + dz]
	v[out_] = np.inf
	return v


def field_part(g, name, lo, hi, far=0.03):
	"""Distance (unsigned) to a body part, worked out only inside the box lo..hi of grid g (`far` elsewhere)."""
	i0 = np.clip(np.floor((np.array(lo) - g.lo) / g.h).astype(int), 0, None)
	i1 = np.minimum(np.ceil((np.array(hi) - g.lo) / g.h).astype(int) + 1, g.D.shape)
	out = np.full(g.D.shape, far, np.float32)
	sl = tuple(slice(a, b) for a, b in zip(i0, i1))
	pts = np.stack([g.X[sl].ravel(), g.Y[sl].ravel(), g.Z[sl].ravel()], 1)
	t = BVH[name]
	vals = np.full(len(pts), far, np.float32)
	for i, p in enumerate(pts):
		hit = t.find_nearest(Vector(p), far)
		if hit[0] is not None:
			vals[i] = hit[3]
	out[sl] = vals.reshape(g.X[sl].shape)
	return out


def hard_rim(inner, rimw=None):
	"""How far the raised rolled rim round a hard plate's edge stands up (metres) at each point (inner = distance in from
	the plate's edge). Owner, Nov 26, on the picture: "you can see the rims around each plate ... the bolts ... the
	shadows under the plates"; round 2's plates were flat to their bevel and read as one smooth lump."""
	rimw = RC.get("rimw", 0.0) if rimw is None else rimw
	if rimw <= 0:
		return 0.0
	return RC.get("rimh", 0.0) * (1.0 - sstep((inner - rimw) / 0.002))


def hard_plate(surf, inner, bulk=None, lift=0.0, k=0.0012, rimw=None):
	"""Stiff metal plates over a surface (surf: its distance field, negative inside): each from 3 mm inside it out to
	`bulk` (+ lift) as one smooth face, with sharp sides and a 45-degree bevel all round its edge. inner = how far each
	point is inside its plate's outline (metres, the gap already taken off). Round 1's plates followed the leather with a
	dome and a raised rim and left a leather border: owner, "it looks like a recolor leather"."""
	bulk = RC["bulk"] if bulk is None else bulk
	top = surf - bulk - lift - hard_rim(inner, rimw)
	p = np.maximum(top, -surf - 0.003)
	p = smax(p, -inner, k)
	return np.maximum(p, top + RC["bevel"] - inner)


def union_parts(parts):
	"""Plates joined [(shape, edge distance, plate id)]: the shape is the nearest one, and every point keeps the edge
	distance and the id of the plate it is on (for the paint)."""
	P, E, I = parts[0]
	P, E, I = P.copy(), np.array(E, np.float32), np.broadcast_to(np.float32(I) if np.isscalar(I) else I, P.shape).astype(np.float32)
	for p, e, i in parts[1:]:
		w = p < P
		P, E, I = np.where(w, p, P), np.where(w, e, E), np.where(w, i, I)
	return P, E, I


def hard_tint(parts, norim=(), rimw=None):
	"""The plates' paint from the grids they were shaped on (parts = [(grid, shape, edge distance, plate id)]; each point
	takes the part whose surface it lies on): a bright polished bevel round every plate, a dark line where plates meet,
	darker hammered faces, every plate its own shade (Rule 6, medium variety)."""
	pc = RC["plate"]
	r = np.random.default_rng(7)
	shades, warm = r.uniform(0.88, 1.1, 64), r.uniform(-0.04, 0.04, 64)

	def tint(co):
		best = np.full(len(co), np.inf)
		e = np.full(len(co), 0.02)
		ids = np.zeros(len(co), int)
		for g, P, E, I in parts:
			a = np.abs(sample(g, P, co))
			w = a < best
			if w.any():
				best[w] = a[w]
				e[w] = sample(g, E, co[w])
				ids[w] = sample(g, I, co[w], nearest=True).astype(int)
		s, wm = shades[ids % 64], warm[ids % 64]
		rgb = np.stack([s * (1 + wm), s, s * (1 - wm)], 1) * pc["face"]
		rw = RC.get("rimw", 0.0) if rimw is None else rimw
		rimmed = ~np.isin(ids, list(norim))  # (fingers, the crest, the nose plate: no rim)
		pol = (1.0 - sstep(e / (RC["bevel"] * 1.4)))
		if rw > 0:  # the raised rim: bright, polished; a dark line where it steps down to the face (its shadow)
			pol = np.where(rimmed, np.maximum(pol, 0.55 * (1.0 - sstep((e - rw) / 0.0015))), pol)
		pol = pol[:, None]
		rgb = rgb * (1 - pol) + np.array(pc["polish"]) * pol
		if rw > 0:
			rgb[rimmed & (e > rw + 0.0004) & (e < rw + 0.0032)] *= 0.62
			dm = hammer_dents(co)  # each hammer dent darker in its middle, light on its ridges (like the picture)
			face = ((e > rw + 0.0032) | ~rimmed & (e > RC["bevel"] * 1.4))[:, None]
			rgb = np.where(face, rgb * (1.2 - 0.45 * dm[:, None]), rgb)
		rgb[e < 0.0006] *= 0.42
		return rgb
	return tint


def hard_helm_region(X, Y, Z):
	"""The closed helmet's bottom edge (negative inside): above the moustache at the front (only the beard shows), down
	over the cheeks to the jaw, the nape at the back."""
	th = np.arctan2(X, -(Y - HC.y))
	S = np.abs(th) * 0.14
	# (round 3, owner: "the helmet can be lower": the face guard down to the moustache, the cheek guards 3 cm lower;
	# round 4: the bell-shaped guard comes down over the nape too)
	bottom = 1.006 - 0.044 * sstep((S - 0.095) / 0.06) + 0.036 * sstep((S - 0.27) / 0.05)
	return bottom - Z, S


def pointed_dome(X, Y, Z, fit):
	"""The closed helmet's outside (round 4, owner: "the helmet is too round"; the picture: a tall dome rising to a
	point, a bell-shaped guard flaring out over the cheeks and the nape). fit = (side, front and back radius at the
	brow, brow height, point height), measured round the hat hair. Above the brow its radius shrinks as (1 - u^2.5) to
	a soft point; below the brow it goes straight down and flares out at the sides and back (not the face)."""
	rx, rf, rb, zb, zt = fit
	yc = DOME_C.y
	ry = np.where(Y < yc, rf, rb)
	rho = np.sqrt((X / rx) ** 2 + ((Y - yc) / ry) ** 2)  # (1 on the brow's oval)
	rl = np.sqrt(X ** 2 + (Y - yc) ** 2) / np.maximum(rho, 1e-4)  # (the oval's radius this way round, metres)
	u = np.clip((Z - zb) / (zt - zb), 0.0, 1.0)
	k = np.where(Z > zb, 1.0 - u ** 2.5, 1.0)
	slope = np.where(Z > zb, 2.5 * u ** 1.5 * rl / (zt - zb), 0.0)
	S = np.abs(np.arctan2(X, -(Y - HC.y))) * 0.14
	flare = 0.026 * sstep((1.075 - Z) / 0.09) * sstep((S - 0.1) / 0.07)
	dist = (rho * rl - (k * rl + flare)) / np.sqrt(1.0 + slope ** 2)
	return np.where(Z > zt, np.sqrt(X ** 2 + (Y - yc) ** 2 + (Z - zt) ** 2), dist)


def eye_slits(X, Y, Z):
	"""The eye slit through the face guard, one long slit across both eyes (owner, round 3: "one continuous line on the
	eyes"; round 2 had two slits with a bar between) (negative inside it)."""
	return np.maximum(np.abs(Z - 1.084) - 0.0085, np.maximum(np.abs(X) - 0.074, Y + 0.03))


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
	fit = None
	top = 1.29
	if HARD:  # (round 4: the pointed dome's size from the hat hair: its widest at the brow, its top + 6 cm)
		hv = world_verts(hair)
		yc = DOME_C.y
		band = hv[(hv[:, 2] > 1.12) & (hv[:, 2] < 1.22)]
		fr = hv[(hv[:, 2] > 1.14) & (hv[:, 1] < yc)]
		fit = (float(np.percentile(np.abs(band[:, 0]), 99.5)) + 0.016, float(np.percentile(yc - fr[:, 1], 99.5)) + 0.016,
			float(np.percentile(band[:, 1] - yc, 99.5)) + 0.016, 1.12, float(hv[:, 2].max()) + 0.06)
		top = fit[4] + 0.02
		log("helmet fit (side, front, back, brow, point):", [round(f, 3) for f in fit])
	g = G((-0.215, -0.19, 0.95), (0.215, 0.235, top), 0.004)
	# (how close the head is, not inside/outside: the hair locks' surfaces fooled the inside test into spikes and lumps)
	d = np.abs(g.field(["armor_head_hair"], band=0.05, far=0.05))
	reg, S = helm_region(g.X, g.Y, g.Z)
	if HARD:  # (a closed helmet: down over the face, only the beard out)
		reg, S = hard_helm_region(g.X, g.Y, g.Z)
	# A padded dome just outside the hair: how far the head reaches in every direction from the skull's middle, the
	# biggest nearby reach taken and smoothed, plus 1.3 cm. (Round 1 followed every lump of the hair ring: a flat-topped
	# box; round 2's plain egg let the hair ring poke through as lumps at the back.)
	outer = np.minimum(dome_dist(g.X, g.Y, g.Z), d - 0.009) + wobble(g, 0.002 if not HARD else 0.001, 1)
	leather = np.maximum(outer, reg)
	if HARD:
		# Round 4: the pointed dome and bell guard (one piece, the eye slit through it; hollow under the guard), and
		# on it, each its own piece standing out with a thick edge: a riveted brow band all round, a band over the top
		# from front to back, a nose plate under the eye slit.
		S0 = smin(pointed_dome(g.X, g.Y, g.Z, fit), outer, 0.012)
		slit = eye_slits(g.X, g.Y, g.Z)
		lo = g.mesh("armor_head_leather", MAT["leather"], np.maximum(np.maximum(np.maximum(S0 + 0.01, reg + 0.004), 0.001 - slit), 0.006 - d))
		e0 = np.minimum(-reg, slit) - 0.001
		top0 = S0 - 0.006 - hard_rim(e0)
		P0 = np.maximum(top0, -e0)
		P0 = np.maximum(P0, top0 + RC["bevel"] - e0)
		P0 = np.where(g.Z < 1.1, np.maximum(P0, -(S0 + 0.005)), P0)  # (the guard a shell: his neck and beard inside)
		e1 = np.minimum.reduce([g.Z - 1.1, 1.138 - g.Z, -reg]) - 0.001
		e2 = np.minimum(0.016 - np.abs(g.X), g.Z - 1.146)
		e3 = np.where(g.Y < HC.y - 0.06, np.minimum.reduce([0.014 - np.abs(g.X), g.Z - 0.995, 1.07 - g.Z]), -0.02)
		parts = [(P0, e0, 0, None)]
		for e_, out_, pid, rw in ((e1, 0.012, 2, None), (e2, 0.014, 10, 0.0), (e3, 0.013, 11, 0.0)):
			tp = S0 - out_ - hard_rim(e_, rw)
			p_ = smax(np.maximum(tp, 0.002 - S0), -e_, 0.0012)
			parts.append((np.maximum(p_, tp + RC["bevel"] - e_), e_, pid, rw))
		objs, tparts = [], []
		# (kept off the face and beard; not cut round the hair at the sides and back: try 1 cut a big arch out of
		# the neck guard where his back hair passes under it)
		keep = np.where((g.Z < 1.1) & (S > 0.12), -1.0, 0.004 - d)
		for k, (P, E, pid, _) in enumerate(parts):
			P = np.maximum(P, keep)
			objs.append(g.mesh(f"_helm_{k}", MAT["plate"], P))
			tparts.append((g, P, E, np.full(P.shape, pid, np.float32)))
		bpy.ops.object.select_all(action="DESELECT")
		for o in objs:
			o.select_set(True)
		bpy.context.view_layer.objects.active = objs[0]
		bpy.ops.object.join()
		po = bpy.context.view_layer.objects.active
		po.name = "armor_head_plate"
		ptint = hard_tint(tparts, norim=(10, 11))
		tb = bvh_of(po)
		items = []
		for a in np.linspace(0.3, 2.85, 11):  # rivets up the band over the top
			dirn = Vector((0, -math.cos(a), math.sin(a)))
			hit = ray_to(tb, HC + dirn * 0.4, -dirn)
			if hit:
				items.append((hit[0] - hit[1] * 0.0012, hit[1], Vector((0, math.sin(a), math.cos(a))), "rivet", 0.0068))
		pts = []
		for th in (0.5, 0.95, 1.4, 1.85, 2.3, 2.75, -0.5, -0.95, -1.4, -1.85, -2.3, -2.75, math.pi):  # round the brow band
			dirn = Vector((math.sin(th), -math.cos(th), 0))
			pts.append((Vector((HC.x, HC.y, 1.119)) + dirn * 0.4, -dirn))
		for sx in (1, -1):  # round the bell guard, near its lower edge
			for th, z in ((1.15, 1.0), (1.6, 1.0), (2.1, 1.03), (0.62, 1.03)):
				dirn = Vector((math.sin(th * sx), -math.cos(th), 0))
				pts.append((Vector((HC.x, HC.y, z)) + dirn * 0.4, -dirn))
		items += plate_items(po, pts, 0.0076)
		br = small_piece(f"armor_head_{RIVET}", MAT[RIVET], items)
		PIECES.extend([(lo, "head", "leather", None, None), (br, "head", RIVET, None, None), (po, "head", "plate", ptint, plate_disp)])
		return
	# the stitched ridge over the top, front to back, and the strap round the back of the head
	ridge = np.maximum(np.maximum(np.abs(g.X) - 0.019, outer - 0.006), reg)
	lift = (RC["bulk"] + RC["rim"] + 0.001) if RC["plates"] else 0.0  # (on a metal set the strap lies over the plates)
	strap = np.maximum(np.maximum(np.abs(g.Z - 1.062) - 0.015, outer - 0.005 - lift), np.maximum(reg, 0.29 - S))
	leather = smin(leather if RC["plates"] else smin(leather, ridge, 0.003), strap, 0.003)
	# fleece rolled over every edge (the face, the flaps, the nape), kept off the skin (thicker on a metal set: it has
	# to roll out past the plates' edges)
	fat = RC["bulk"] * 0.45 if RC["plates"] else 0.0
	fleece = np.sqrt(reg ** 2 + (outer + 0.006 - fat) ** 2) - 0.0135 - fat + lumps(g, 0.0025, 0.016, 2)
	fleece = np.maximum(fleece, 0.004 - d)
	lo = g.mesh("armor_head_leather", MAT["leather"], leather)
	fl = g.mesh("armor_head_fleece", MAT["fleece"], fleece)
	if RC["plates"]:
		# six plates up to the crown (a crest over the middle seam, front to back), a brow band round the bottom
		# split into front, ear flaps and back
		up = np.minimum(panel_seam(g.X, g.Y), g.Z - 1.118)
		low = np.minimum.reduce([1.112 - g.Z, np.abs(S - 0.17), np.abs(S - 0.29)])
		cell = np.maximum(up, low)
		plate = plate_shell(outer, cell, reg)
		crest = np.maximum(np.maximum(np.abs(g.X) - 0.013, outer - RC["bulk"] - 0.009), np.maximum(reg + 0.012, 1.118 - g.Z))
		plate = smin(plate, np.maximum(crest, -outer - 0.003), 0.003)
		plate = np.maximum(plate, 0.004 - d)
		po = g.mesh("armor_head_plate", MAT["plate"], plate)
	# brass rivets down the ridge and along the back strap
	tb = bvh_of(po if RC["plates"] else lo)
	items = []
	for a in np.linspace(0.45, 2.75, 9):
		dirn = Vector((0, -math.cos(a), math.sin(a)))
		hit = ray_to(tb, HC + dirn * 0.4, -dirn)
		if hit:
			items.append((hit[0] - hit[1] * 0.0012, hit[1], Vector((0, math.sin(a), math.cos(a))), "rivet", 0.0062))
	tb = bvh_of(lo)
	for th in (2.25, 2.62, -2.25, -2.62):
		dirn = Vector((math.sin(th), -math.cos(th), 0))
		hit = ray_to(tb, Vector((HC.x, HC.y, 1.062)) + dirn * 0.4, -dirn)
		if hit:
			items.append((hit[0] - hit[1] * 0.0012, hit[1], Vector((0, 0, 1)), "rivet", 0.0068))
	if RC["plates"]:  # a rivet each side of every seam at the plates' feet, and along the brow band
		pts = []
		for k in range(6):
			for off in (-0.13, 0.13):
				th = k * math.pi / 3 + off
				dirn = Vector((math.sin(th), -math.cos(th), 0.25)).normalized()
				pts.append((Vector((HC.x, HC.y, 1.132)) + dirn * 0.4, -dirn))
		for th in (1.45, 1.72, -1.45, -1.72, 2.35, 2.75, -2.35, -2.75):  # (the ear flaps and the back: the front has no band)
			dirn = Vector((math.sin(th), -math.cos(th), 0))
			pts.append((Vector((HC.x, HC.y, 1.096)) + dirn * 0.4, -dirn))
		items += plate_items(po, pts, 0.0058)
	br = small_piece(f"armor_head_{RIVET}", MAT[RIVET], items)

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

	PIECES.extend([(lo, "head", "leather", tint, disp), (fl, "head", "fleece", None, None), (br, "head", RIVET, None, None)])
	if RC["plates"]:
		PIECES.append((po, "head", "plate", plate_tint(lambda X, Y, Z: np.floor((np.arctan2(X, -(Y - HC.y)) + math.pi) / (math.pi / 3)) + 6 * (Z < 1.115)), plate_disp))


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


HARD_COLS = (-2.5, -1.25, 1.25, 2.5)  # hard sets: one big breastplate and wide lames round the front, sides, back
SKIRT_COL = math.pi / 4               # hard sets: eight skirt plates round the hips (a split at the front and back)
# Round 4 (owner on round 3: "it looks like it's glued together"): every plate is its own stiff shell with a thick
# edge, laid over a very smooth copy of the body (not its lumps), and each band's lower edge stands out over the next
# band down like roof tiles, with a real gap (and shadow) under it. LIFT: how far a band's lower edge stands out more
# than its top (the plate's thickness + its rim + a 8 mm air gap over the band below); OV: how far it reaches down
# over that band.
SHELL_T = 0.008
LIFT = SHELL_T + 0.0024 + 0.008
OV = 0.014
SKIRT_LOW = 0.348  # where the lowest skirt band starts (its lower edge reaches OV further down)
# the shoulder guards: a domed cap and three bands stepping down the arm (metres out from his middle, from, to), each
# band's outer edge over the next (round 3's three plates were cut from one smooth lump and read as one)
PAULDRON = ((-9.0, 0.34), (0.34, 0.385), (0.385, 0.43), (0.43, 0.478))


def chest_v(th):
	"""How much higher the breastplate's and the belly lame's lower edges are at this angle round him: they point down
	in the middle of the front and of the back, like the picture's (round 3; round 2's were flat bands)."""
	a = np.minimum(np.abs(th), math.pi - np.abs(th))
	return 0.05 * np.clip(a / 1.1, 0.0, 1.0)


def sub_grid(g, lo, hi):
	"""The part of grid g inside the box lo..hi (views, no copies): each plate band is meshed on its own small grid."""
	i0 = np.clip(np.floor((np.array(lo) - g.lo) / g.h).astype(int), 0, None)
	i1 = np.minimum(np.ceil((np.array(hi) - g.lo) / g.h).astype(int) + 1, g.X.shape)
	sl = tuple(slice(a_, b_) for a_, b_ in zip(i0, i1))
	s_ = G.__new__(G)
	s_.h, s_.lo = g.h, g.lo + i0 * g.h
	s_.X, s_.Y, s_.Z, s_.D = g.X[sl], g.Y[sl], g.Z[sl], g.D[sl]
	return s_, sl


def stiff_shell(base, off, inner, rimw=None):
	"""One stiff plate: a shell SHELL_T thick whose inside lies `off` out from `base` (a smooth distance field), cut to
	its outline (inner = how far inside the outline, metres) with a bevelled edge and a raised rim round it."""
	outer = base - off - SHELL_T - hard_rim(inner, rimw)
	p = np.maximum(outer, off - base)
	p = smax(p, -inner, 0.0012)
	return np.maximum(p, outer + RC["bevel"] - inner)


def lame_lift(dz, h, ov, lift):
	"""How far a band stands out more at this point (dz = how far below its top): nothing at the top (it tucks under
	the band above), rising to `lift` at its lower edge over the last 5 cm."""
	ramp = np.minimum(h + ov, 0.05)
	return lift * np.clip((dz - (h + ov - ramp)) / ramp, 0.0, 1.0)


CHEST_COLS = (-2.6, -1.75, -0.62, 0.62, 1.75, 2.6)  # the plates' sides follow the leather's panel seams (SEAMS)
TOP_COLS = (-2.6, -0.62, 0.62, 2.6)                 # above the yoke: a chest plate, a back plate and the sides
BELT_GAP = 0.034                                    # the belt's half height plus a little: no plates under it


def jerkin_cells(X, Y, Z):
	"""The metal set's chest plates: how far each point is inside its plate's outline (metres, negative = between
	plates) and which plate it is. Rows: the skirt below the belt (narrow plates, like tassets), two rows on the belly,
	one on the chest and back above the yoke. Columns follow the leather's panel seams."""
	th = np.arctan2(X, -Y)

	def to_cols(cols):
		d = np.full(np.shape(X), 9.0)
		for a in cols:
			d = np.minimum(d, np.abs(((th - a + math.pi) % (2 * math.pi)) - math.pi) * 0.24)
		return d

	skirt_c = np.abs(((th + math.pi) % 0.52) - 0.26) * 0.24
	skirt_c = 0.26 * 0.24 - skirt_c
	lo_, hi_ = BELT - BELT_GAP, BELT + BELT_GAP
	rows = [
		(Z < lo_, np.minimum(lo_ - Z, skirt_c), 0),
		((Z > hi_) & (Z < 0.615), np.minimum(np.minimum(Z - hi_, 0.615 - Z), to_cols(CHEST_COLS)), 1),
		((Z >= 0.615) & (Z < YOKE), np.minimum(np.minimum(Z - 0.615, YOKE - Z), to_cols(CHEST_COLS)), 2),
		(Z >= YOKE, np.minimum(Z - YOKE, to_cols(TOP_COLS)), 3),
	]
	cell = np.full(np.shape(X), -0.01)
	rid = np.zeros(np.shape(X))
	for m, c, r in rows:
		cell = np.where(m, c, cell)
		rid = np.where(m, r, rid)
	cell = np.minimum(cell, 0.272 - np.abs(X))  # (not down the arms)
	cell = np.where(Z > 0.7, np.minimum(cell, 0.25 - np.abs(X)), cell)  # (the shoulder guards cover the shoulders)
	col = np.where(rid == 0, np.floor((th + math.pi) / 0.52), np.digitize(th, CHEST_COLS))
	return cell, rid * 16 + col


def build_jerkin():
	log("jerkin: measuring the shirt")
	wx = 0.515 if HARD else 0.475  # (the hard set's third shoulder plate reaches further down the arm)
	g = G((-wx, -0.36, 0.31 if HARD else 0.33), (wx, 0.32, 0.965), 0.004)  # (hard sets: the skirt hangs lower)
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
	lift = (RC["bulk"] + RC["rim"] + 0.002) if RC["plates"] else 0.0  # (on a metal set belt and strap lie over the plates)
	belt = np.maximum(np.maximum(np.abs(g.Z - BELT) - 0.026, surf - 0.008 - lift * 0.6), np.maximum(reg, 0.003 - d))
	jerk = smin(jerk, belt, 0.002)
	hit = BVH["body_shirt"].ray_cast(Vector((0.17, -0.6, 0.425)), Vector((0, 1, 0)))
	if hit[0] is not None and not HARD:  # a pouch hanging from the belt on his left hip
		pc, pn = hit[0], (hit[1] if hit[1].y < 0 else -hit[1])
		t1, b1, n1 = frame_at(pn, (0, 0, 1))
		c = pc + n1 * 0.028
		qx = np.abs((g.X - c.x) * b1.x + (g.Y - c.y) * b1.y + (g.Z - c.z) * b1.z) - 0.042
		qy = np.abs((g.X - c.x) * t1.x + (g.Y - c.y) * t1.y + (g.Z - c.z) * t1.z) - 0.036
		qz = np.abs((g.X - c.x) * n1.x + (g.Y - c.y) * n1.y + (g.Z - c.z) * n1.z) - 0.014
		pouch = np.sqrt(np.maximum(qx, 0) ** 2 + np.maximum(qy, 0) ** 2 + np.maximum(qz, 0) ** 2) + np.minimum(np.maximum(np.maximum(qx, qy), qz), 0) - 0.012
		jerk = smin(jerk, pouch + wobble(g, 0.002, 9), 0.006)
		POUCH[:] = [c + n1 * 0.026 + t1 * 0.02, n1]
	# the shoulder guards: a big top plate and a lower one further down the arm, under it (on a metal set: metal,
	# bigger by `pads`, standing out past the chest plates)
	guards = np.full_like(jerk, 1.0)
	gr, go = (RC["pads"], RC["bulk"] + 0.008) if RC["plates"] else (1.0, 0.0)
	for sx in ((1, -1) if not HARD else ()):
		# (round 1 reached down round the whole sleeve: they only cap the top of the shoulder)
		for c, r, zmin, o_in, o_out in (((0.365 * sx, 0.035, 0.79), 0.085, 0.765, 0.010, 0.023), ((0.295 * sx, 0.035, 0.81), 0.105, 0.775, 0.010, 0.031)):
			r, o_out = r * gr, o_out + go
			rr = np.sqrt((g.X - c[0]) ** 2 + (g.Y - c[1]) ** 2 * 0.9 + (g.Z - c[2]) ** 2) - r
			plate = np.maximum(np.maximum(soft - o_out, o_in - d), smax(rr, zmin - g.Z + 0.03 * (np.abs(g.X) - 0.3), 0.01))
			rim = np.maximum(np.maximum(np.abs(rr + 0.01) - 0.0035, soft - o_out - 0.0025), np.maximum(o_in - d, zmin - g.Z))
			# (round 4: a raised rim round each plate, owner: "the shoulders have nothing")
			guards = smin(np.minimum(guards, plate), rim, 0.0015)
	if not RC["plates"]:
		jerk = np.minimum(jerk, guards)
	# the strap across the body (front and back), raised over the leather
	sd = strap_dist(g.X, g.Z)
	band = np.maximum(np.maximum(np.abs(sd) - 0.023, soft - t_ - 0.006 - lift), np.maximum(reg - 0.0, 0.003 - d))
	if not HARD:  # (plate armour: no strap across the breastplate)
		jerk = smin(jerk, band, 0.002)
	jerk = np.maximum(jerk, 0.0035 - dbeard)  # under the beard and the back hair (they lie on top: the beard falls over it)
	lo = g.mesh("armor_chest_leather", MAT["leather"], jerk)
	drop_inside(lo, ["body_shirt", "body_shorts"] + (["body_torso"]))
	po = None
	ptint = None
	if HARD:
		# Round 4: separate stiff plates (see LIFT), each band meshed on its own grid, then joined into one piece.
		# (a very smooth body pushed 4 mm out, so the plates don't follow his lumps; never closer than the shirt's own
		# soft copy: try 1 let them sink into the leather where he is round, and the leather poked through as dark tears)
		base = np.minimum(blur(d, 7) - 0.004, soft)
		# (only the beard's main mass dents the plates, with a smooth edge: try 1 cut round every thin strand and
		# left the breastplate full of little holes and copper crumbs under his beard)
		dbeard_s = blur(dbeard, 6)
		smooth = blur(soft, 5)
		o0 = t_ - 0.003  # (each band's top starts just inside the leather)
		th = np.arctan2(g.X, -g.Y)
		v = chest_v(th)
		cd = np.full(np.shape(g.X), 9.0, np.float32)
		for a_ in HARD_COLS:
			cd = np.minimum(cd, np.abs(((th - a_ + math.pi) % (2 * math.pi)) - math.pi) * 0.24)
		sc = (SKIRT_COL / 2 - np.abs(((th + math.pi) % SKIRT_COL) - SKIRT_COL / 2)) * 0.24
		bcol, scol = np.digitize(th, HARD_COLS), np.floor((th + math.pi) / SKIRT_COL)
		top_ = BELT - BELT_GAP
		hs = (top_ - SKIRT_LOW) / 3
		# (from, to, columns, which column, reach down over the next band, lift, row): three skirt bands under the
		# belt, two belly lames, the breastplate (the lower belly lame has the belt under its edge: no reach)
		rows = ((SKIRT_LOW, SKIRT_LOW + hs, sc, scol, OV, 0.010, 0), (SKIRT_LOW + hs, SKIRT_LOW + 2 * hs, sc, scol, OV, LIFT, 1),
			(SKIRT_LOW + 2 * hs, top_, sc, scol, OV, LIFT, 2), (BELT + BELT_GAP, 0.562 + v * 0.6, cd, bcol, 0.0, 0.008, 3),
			(0.562 + v * 0.6, 0.612 + v, cd, bcol, OV, LIFT, 4), (0.612 + v, 9.0, cd, bcol, OV, LIFT, 5))
		objs, tparts = [], []
		for zlo, zhi, col_in, col_id, ov, lift, r in rows:
			z0 = float(np.min(zlo)) - ov - 0.012
			z1 = min(float(np.max(zhi)) + 0.012, 0.965)
			sg, sl = sub_grid(g, (-wx, -0.36, z0), (wx, 0.32, z1))
			Z = sg.Z
			zl = zlo[sl] if np.ndim(zlo) else zlo
			zh = zhi[sl] if np.ndim(zhi) else zhi
			inner = np.minimum.reduce([Z - (zl - ov), zh - Z, col_in[sl]]) - GAP
			inner = np.minimum(inner, 0.272 - np.abs(sg.X))  # (not down the arms)
			inner = np.where(Z > 0.7, np.minimum(inner, 0.25 - np.abs(sg.X)), inner)  # (the shoulder guards cover the shoulders)
			if r >= 3:  # (the skirt hangs below the leather's hem; the rest stays inside the leather's edges)
				inner = np.minimum(inner, -reg[sl])
			off = o0[sl] + lame_lift(zh - Z, zh - zl, ov, lift)
			P = stiff_shell(base[sl], off, inner)
			P = np.maximum(np.maximum(P, 0.003 - d[sl]), 0.002 - dbeard_s[sl])
			objs.append(sg.mesh(f"_chest_row{r}", MAT["plate"], P, min_island=400))
			tparts.append((sg, P, inner, (r * 16 + col_id[sl]).astype(np.float32)))
		for sx in (1, -1):  # the shoulder guards: a domed cap and three bands down the arm, each over the next
			sg, sl = sub_grid(g, (min(0.16 * sx, wx * sx), -0.36, 0.66), (max(0.16 * sx, wx * sx), 0.32, 0.965))
			ax = sg.X * sx
			rr = np.sqrt((ax - 0.33) ** 2 * 0.8 + (sg.Y - 0.035) ** 2 * 0.9 + (sg.Z - 0.80) ** 2) - 0.115 * RC["pads"]
			cap = np.minimum.reduce([-rr, sg.Z - 0.768 + 0.05 * (ax - 0.3), ax - 0.2])  # (try 1: a fin up the neck)
			for k, (a_, b_) in enumerate(PAULDRON):
				last = k == len(PAULDRON) - 1
				ov = 0.0 if last else 0.013
				inner = np.minimum.reduce([cap, ax - a_, b_ + ov - ax]) - GAP * 0.5
				h = (b_ - 0.2) if k == 0 else (b_ - a_)
				off = 0.03 - 0.004 * k + lame_lift(ax - (b_ - h), h, ov, 0.008 if last else LIFT)
				P = stiff_shell(smooth[sl], off, inner)
				P = np.maximum(P, 0.010 - d[sl])
				objs.append(sg.mesh(f"_pauldron_{k}_{sx}", MAT["plate"], P, min_island=400))
				tparts.append((sg, P, inner, np.full(P.shape, 40 + k + 4 * (sx > 0), np.float32)))
		bpy.ops.object.select_all(action="DESELECT")
		for o in objs:
			o.select_set(True)
		bpy.context.view_layer.objects.active = objs[0]
		bpy.ops.object.join()
		po = bpy.context.view_layer.objects.active
		po.name = "armor_chest_plate"
		ptint = hard_tint(tparts)
	elif RC["plates"]:
		cell, _ = jerkin_cells(g.X, g.Y, g.Z)
		plate = plate_shell(surf, cell, reg)
		plate = np.minimum(plate, guards)
		plate = np.maximum(np.maximum(plate, 0.003 - d), 0.004 - dbeard)
		po = g.mesh("armor_chest_plate", MAT["plate"], plate)
	tb = bvh_of(lo)
	items = []
	a, b = STRAP
	for f, frontside in (((0.74, True), (0.3, False)) if not HARD else ()):  # a buckle on the strap, front and back
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
	if po:
		tb = bvh_of(po)
	for sx in (1, -1):  # rivets round the top plate's edge and on the lower plate
		for ang, rad, cz in ((-0.9, 0.105, 0.80), (0.0, 0.11, 0.80), (0.9, 0.105, 0.80), (-0.6, 0.085, 0.77), (0.6, 0.085, 0.77)):
			c = Vector((0.31 * sx if rad > 0.09 else 0.39 * sx, 0.035, cz))
			dirn = Vector((math.sin(0.5) * sx * 0.6, -math.sin(ang), math.cos(ang))).normalized()
			hit = ray_to(tb, c + dirn * 0.4, -dirn)
			if hit:
				items.append((hit[0] - hit[1] * 0.0012, hit[1], None, "rivet", 0.0065))
	if po:  # a rivet in both top corners of every chest plate, one at the top of every skirt plate
		pts = []
		rows_ = ((0.615 - 0.019, CHEST_COLS), (YOKE - 0.019, CHEST_COLS), (YOKE + 0.03, TOP_COLS))
		if HARD:
			rows_ = ((BELT + BELT_GAP + 0.016, HARD_COLS, 0.0), (0.562 + 0.016, HARD_COLS, 0.6), (0.612 + 0.018, HARD_COLS, 1.0))
		else:
			rows_ = tuple((z, c, 0.0) for z, c in rows_)
		for zr, cols, vk in rows_:
			for k, a in enumerate(cols):
				b = cols[(k + 1) % len(cols)] + (2 * math.pi if k == len(cols) - 1 else 0.0)
				for ang in (a + 0.09, b - 0.09):
					dirn = Vector((math.sin(ang), -math.cos(ang), 0))
					ang_ = ((ang + math.pi) % (2 * math.pi)) - math.pi
					pts.append((Vector((0, 0, zr + vk * float(chest_v(ang_)))) + dirn * 0.6, -dirn))
		if HARD:  # one in the middle of every skirt plate, near its lower edge
			hs = (BELT - BELT_GAP - SKIRT_LOW) / 3
			skirt_r = [(SKIRT_LOW + j * hs + 0.004, -math.pi + SKIRT_COL / 2 + k * SKIRT_COL) for j in range(3) for k in range(8)]
		else:
			skirt_r = [(BELT - BELT_GAP - 0.016, -math.pi + 0.26 + k * 0.52) for k in range(12)]
		for zr, ang in skirt_r:
			dirn = Vector((math.sin(ang), -math.cos(ang), 0))
			pts.append((Vector((0, 0, zr)) + dirn * 0.6, -dirn))
		items += plate_items(po, pts, 0.0072 if HARD else 0.006)
	br = small_piece(f"armor_chest_{RIVET}", MAT[RIVET], items)

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

	PIECES.extend([(lo, "chest", "leather", tint, disp), (br, "chest", RIVET, None, None)])
	if po:
		PIECES.append((po, "chest", "plate", ptint or plate_tint(lambda X, Y, Z: jerkin_cells(X, Y, Z)[1] + 40 * (np.abs(X) > 0.25) * (Z > 0.7)), plate_disp))


BOOT_C = {}  # each boot's shin middle (the metal plates are laid out round it)
BOOTPARTS = []  # hard sets: each boot's plate grids, for the paint


def boot_phi(X, Y, c):
	"""Angle round the ankle (0 = the front, the laces) and the line in front of which the toe cap starts."""
	return np.arctan2(X - c[0], -(Y - c[1])), c[1] - 0.045


def boot_plate_id(X, Y, Z):
	side = np.where(X > 0, 1, 0)
	out = np.zeros(np.shape(X))
	for k, s in enumerate(("l", "r")):
		if s not in BOOT_C:
			continue
		phi, tl = boot_phi(X, Y, BOOT_C[s])
		seg = np.where(Y < tl, 0, np.digitize(phi, (-2.45, 0.0, 2.45)) + 1)
		m = side == (1 if BOOT_C[s][0] > 0 else 0)
		out = np.where(m, seg + 8 * k, out)
	return out


def build_boots():
	parts = {"leather": [], "fleece": [], "cord": [], RIVET: [], "plate": []}
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
		fat = RC["bulk"] * 0.4 if RC["plates"] else 0.0
		fleece = np.sqrt((g.Z - top) ** 2 + (soft - t_ * 0.6 - fat) ** 2) - 0.0165 - fat + lumps(g, 0.0028, 0.016, 7)
		fleece = np.maximum(fleece, 0.004 - d)
		bo = g.mesh(f"_boot_{side}", MAT["leather"], boot)
		fl = g.mesh(f"_cuff_{side}", MAT["fleece"], fleece) if not HARD else None
		shin_c = fv[(fv[:, 2] > 0.1) & (fv[:, 2] < 0.17)].mean(0)
		if HARD:
			# plate boots: overlapping plates across the top of the foot from the ankle to the toe (each one's toe-side
			# edge over the next), two rings of plates round the ankle and shin (front and back halves), the dark sole
			phi, toe_line = boot_phi(g.X, g.Y, shin_c)
			ang = lambda a_: np.abs(((phi - a_ + math.pi) % (2 * math.pi)) - math.pi) * 0.05
			u = toe_line - g.Y
			fu = u - np.floor(u / 0.03) * 0.03
			foot = np.minimum(np.minimum(fu, 0.03 - fu), g.Z - 0.042)
			lift = np.where(u > 0, RC["flare"] * fu / 0.03, 0.0)
			rings, rid = np.full_like(g.D, -0.01), np.zeros_like(g.D)
			for k, (zlo, zhi) in enumerate(((0.042, 0.105), (0.105, 9.0))):
				m = (g.Z >= zlo) & (g.Z < zhi)
				rings = np.where(m, np.minimum.reduce([g.Z - zlo, zhi - g.Z, ang(1.6), ang(-1.6)]), rings)
				rid = np.where(m, 1 + 2 * k + (np.abs(phi) > 1.6), rid)
				lift = np.where(m & (u <= 0), RC["flare"] * np.clip((min(zhi, 0.19) - g.Z) / (min(zhi, 0.19) - zlo), 0, 1), lift)
			cell = np.minimum(np.where(u > 0, foot, rings), top - g.Z) - GAP
			rid = np.where(u > 0, 6 + np.floor(u / 0.03), rid) + 12 * (side == "r")
			bp = np.maximum(hard_plate(outer, cell, bulk=RC["bulk"] * 0.8, lift=lift, rimw=0.006), 0.003 - d)
			po = g.mesh(f"_plate_{side}", MAT["plate"], bp)
			parts["plate"].append(po)
			BOOTPARTS.append((g, bp, cell, rid))
			pts = []
			for a_ in (1.2, 2.0, -1.2, -2.0):  # rivets at the top corners of the ring plates
				dirn = Vector((math.sin(a_), -math.cos(a_), 0))
				for z in (0.092, 0.172):
					pts.append((Vector((shin_c[0], shin_c[1], z)) + dirn * 0.3, -dirn))
			br = small_piece(f"_eyelets_{side}", MAT[RIVET], plate_items(po, pts, 0.0052))
			parts["leather"].append(bo)
			if br:
				parts[RIVET].append(br)
			continue
		if RC["plates"]:
			# a toe cap, two ankle plates (inside and outside) and a heel plate; the laces stay in the open front
			phi, toe_line = boot_phi(g.X, g.Y, shin_c)
			ang = lambda a_: np.abs(((phi - a_ + math.pi) % (2 * math.pi)) - math.pi) * 0.05  # (about 5 cm round the ankle)
			toe = np.minimum.reduce([0.088 - g.Z, g.Z - 0.044, toe_line - g.Y])
			angd = np.where(np.abs(phi) < 0.6, -0.01, np.minimum.reduce([ang(0.6), ang(-0.6), ang(2.45), ang(-2.45)]))
			upper = np.minimum.reduce([g.Z - np.where(np.abs(phi) > 2.45, 0.044, 0.062), top - g.Z, angd, g.Y - toe_line])
			cell = np.where(g.Y < toe_line, toe, upper)
			bp = plate_shell(outer, cell, g.Z - top, bulk=RC["bulk"] * 0.8)
			bp = np.maximum(bp, 0.003 - d)
			po = g.mesh(f"_plate_{side}", MAT["plate"], bp)
			parts["plate"].append(po)
			BOOT_C[side] = shin_c
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
		if RC["plates"]:  # rivets along the toe cap's top, at the top of the ankle plates and on the heel
			pts = [(Vector((shin_c[0] + dx, shin_c[1] - 0.5, 0.074)), Vector((0, 1, 0))) for dx in (-0.024, 0.0, 0.024)]
			for a_ in (0.9, 2.1, -0.9, -2.1, math.pi):
				dirn = Vector((math.sin(a_), -math.cos(a_), 0))
				pts.append((Vector((shin_c[0], shin_c[1], 0.164 if abs(a_) < 3 else 0.06)) + dirn * 0.3, -dirn))
			items += plate_items(po, pts, 0.0052)
		br = small_piece(f"_eyelets_{side}", MAT[RIVET], items) if items else None
		parts["leather"].append(bo)
		parts["fleece"].append(fl)
		parts["cord"].append(co)
		if br:
			parts[RIVET].append(br)
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

		if mname == "plate":
			PIECES.append((o, "feet", mname, hard_tint(BOOTPARTS, rimw=0.006) if HARD else plate_tint(boot_plate_id), plate_disp))
		else:
			PIECES.append((o, "feet", mname, tint if mname == "leather" else None, disp if mname == "leather" else None))


FINGERS = ("thumb", "index", "middle", "ring", "pinky")


def part_mesh(src, keep, name):
	"""A copy of a body mesh with only the points `keep` (and the faces between them), measured like a body part."""
	o = src.copy()
	o.data = src.data.copy()
	o.name = name
	bpy.context.scene.collection.objects.link(o)
	bm = bmesh.new()
	bm.from_mesh(o.data)
	bm.verts.ensure_lookup_table()
	bmesh.ops.delete(bm, geom=[bm.verts[i] for i in np.nonzero(~keep)[0]], context="VERTS")
	bm.to_mesh(o.data)
	bm.free()
	BVH[name] = bvh_of(o)
	return o


def build_gauntlets():
	"""Hard sets: metal gloves (owner on round 1: "we can cover his hands and feet"). Each finger a plated shell with a
	groove at every joint (they bend with his finger bones), a raised plate over the back of the hand, the thumb its own
	shell, and a cuff flaring out over the wrist. One mesh, armor_chest_gauntlets: the game wears every armor_chest_*
	mesh with the chest piece, and hides the bare hands under it (DwarfRig._wear_built_armor)."""
	objs, tparts, items = [], [], []
	for side in ("l", "r"):
		log("gauntlet", side)
		hand = BODYM[f"body_hand_{side}"]
		gn = {vg.index: vg.name for vg in hand.vertex_groups}
		wv = world_verts(hand)
		owner = []
		for v in hand.data.vertices:
			nm = gn[max(v.groups, key=lambda q: q.weight).group] if v.groups else "hand"
			f = nm.split("_")[0]
			owner.append("palm" if f not in FINGERS or nm.startswith("thumb_01") else f)
		owner = np.array(owner)
		sx = 1.0 if wv[:, 0].mean() > 0 else -1.0
		zc = float(wv[owner == "palm"][:, 2].mean())
		lo_h, hi_h = wv.min(0) - 0.016, wv.max(0) + 0.016
		subs = {f: part_mesh(hand, owner == f, f"_g_{f}_{side}") for f in ("palm",) + FINGERS}
		bones = {b.name: b for b in ARM.data.bones}

		def finger_shell(g, f, off):
			vs = wv[owner == f]
			dd = field_part(g, subs[f].name, vs.min(0) - 0.016, vs.max(0) + 0.016)
			sh = dd - off
			edge = np.full_like(sh, 0.02)
			for seg in ("02", "03", "04_leaf"):  # a groove round every joint
				b = bones.get(f"{f}_{seg}_{side}")
				if b is None:
					continue
				j = ARM.matrix_world @ b.head_local
				t = (ARM.matrix_world.to_3x3() @ (b.tail_local - b.head_local)).normalized()
				along = np.abs((g.X - j.x) * t.x + (g.Y - j.y) * t.y + (g.Z - j.z) * t.z)
				sh = np.maximum(sh, -np.maximum(along - 0.0016, (off - 0.0025) - dd))
				edge = np.minimum(edge, along - 0.0016)
			return sh, edge

		# the hand and four fingers (one shape: they curl together), the back plate over the knuckles' line
		g = G(lo_h, hi_h, 0.002)
		dp = field_part(g, subs["palm"].name, wv[owner == "palm"].min(0) - 0.016, wv[owner == "palm"].max(0) + 0.016)
		ax = g.X * sx
		back_in = np.minimum.reduce([g.Z - (zc + 0.006), ax - 0.70, 0.778 - ax]) - GAP
		parts = [(dp - 0.005, np.full_like(dp, 0.02), 0), (hard_plate(dp - 0.005, back_in, bulk=0.0035, rimw=0), back_in, 1)]
		for k, f in enumerate(FINGERS[1:]):
			sh, edge = finger_shell(g, f, 0.005)
			parts.append((sh, edge, 2 + k))
		P, E, I = union_parts(parts)
		I = I + 16 * (side == "r")
		o = g.mesh(f"_gaunt_{side}", MAT["plate"], P)
		objs.append(o)
		tparts.append((g, P, E, I))
		# the thumb: its own shell, a little further out (never in the same place as the hand's)
		vs = wv[owner == "thumb"]
		gt = G(vs.min(0) - 0.016, vs.max(0) + 0.016, 0.002)
		sh, edge = finger_shell(gt, "thumb", 0.0068)
		objs.append(gt.mesh(f"_gthumb_{side}", MAT["plate"], sh))
		tparts.append((gt, sh, edge, np.full_like(sh, 6 + 16 * (side == "r"))))
		# The arm from the sleeve's end to the wrist (owner, round 3: "the armor around the elbows is still open"; round 2
		# left bare skin from the leather sleeve, x 0.405, to the cuff, 0.522): three lames round the arm, each one
		# hollow and each one's lower edge standing out over the next like roof tiles: the upper-arm plate, the elbow
		# plate with a round cop over the point of the elbow (the back, +y), and the cuff flaring out over the wrist.
		gc = G((min(0.396 * sx, 0.73 * sx), 0.031 - 0.1, 0.778 - 0.1), (max(0.396 * sx, 0.73 * sx), 0.031 + 0.1, 0.778 + 0.1), 0.0025)
		axc = gc.X * sx
		da = np.minimum(gc.field(["body_torso"], band=0.04, far=0.04), field_part(gc, hand.name, lo_h, hi_h))
		cop = 0.009 * sstep(1.0 - np.sqrt(((axc - 0.483) / 0.032) ** 2 + ((gc.Z - 0.778) / 0.04) ** 2)) * sstep((gc.Y - 0.031) / 0.025)
		lames = (  # (from, to, stand-off at its top, extra at its lower edge, plate id)
			(0.4, 0.448, 0.0085, 0.003, 7),
			(0.448, 0.524, 0.0125, 0.002, 8),
			(0.524, 0.712, 0.008, 0.012, 9))
		lparts = []
		for a_, b_, o_, fl_, pid in lames:
			l_in = np.minimum(axc - a_, b_ - axc) - GAP * 0.5
			off = o_ + fl_ * sstep((axc - a_) / (b_ - a_)) + hard_rim(l_in) + (cop if pid == 8 else 0.0)
			sh = np.maximum(np.maximum(da - off, 0.0025 - da), -l_in)
			sh = np.maximum(sh, (da - off) + RC["bevel"] - l_in)
			lparts.append((sh, l_in, np.full_like(sh, pid + 16 * (side == "r"))))
		cuff, c_in, c_id = union_parts(lparts)
		co = gc.mesh(f"_gcuff_{side}", MAT["plate"], cuff)
		objs.append(co)
		tparts.append((gc, cuff, c_in, c_id))
		pts = []
		for x in (0.41, 0.437, 0.46, 0.506, 0.537, 0.7):  # two rivets near the ends of every lame, top and front
			for y, z, dv in ((0.031, 0.95, (0, 0, -1)), (-0.15, 0.778, (0, 1, 0))):
				pts.append((Vector((sx * x, y, z)), Vector(dv)))
		pts.append((Vector((sx * 0.483, 0.25, 0.778)), Vector((0, -1, 0))))  # (the elbow cop's middle)
		items += plate_items(co, pts, 0.0064)
		for s_ in subs.values():
			bpy.data.objects.remove(s_, do_unlink=True)
	bpy.ops.object.select_all(action="DESELECT")
	for o in objs:
		o.select_set(True)
	bpy.context.view_layer.objects.active = objs[0]
	bpy.ops.object.join()
	o = bpy.context.view_layer.objects.active
	o.name = "armor_chest_gauntlets"
	PIECES.append((o, "hands", "plate", hard_tint(tparts, norim=tuple(range(7)) + tuple(range(16, 23))), plate_disp))
	br = small_piece("armor_chest_gauntlet_rivet", MAT[RIVET], items)
	if br:
		PIECES.append((br, "hands", RIVET, None, None))


def build_legs():
	"""Hard sets: plate leg armour (owner, round 3: "we do need better pants"; the picture: plates down the front of the
	thigh, a knee cop with a six-sided plate, greaves round the shin down into the boots, dark trousers between).
	Each leg: a thigh plate over the front and outside (the back and inside stay cloth), a knee lame round the knee with
	a raised six-sided cop on the front, and a greave in two halves (front and back) round the shin; each lame's lower
	edge stands out over the next one down. One mesh, armor_legs_plate: the game wears it as the legs piece."""
	objs, tparts, items = [], [], []
	for side, sx in (("l", 1.0), ("r", -1.0)):
		log("legs", side)
		g = G((min(0.004 * sx, 0.29 * sx), -0.16, 0.172), (max(0.004 * sx, 0.29 * sx), 0.2, 0.405), 0.003)
		ax = g.X * sx
		d = g.field(["body_shorts", "body_pants", "body_torso"], band=0.05, far=0.05)
		soft = blur(d, 2)
		surf = soft - 0.004
		phi = np.arctan2(ax - 0.129, -(g.Y - 0.03))  # round the leg: 0 = front, + = his outside
		r_ = 0.085  # (the leg's rough radius: angle to metres)
		ring = lambda a0, a1: np.minimum((phi - a0) * r_, (a1 - phi) * r_)
		u, w = phi * r_, g.Z - 0.268
		hexd = np.maximum(np.abs(u) * 0.866 + np.abs(w) * 0.5, np.abs(w))  # (a six-sided outline, flat top and bottom)
		cop_in = 0.056 - hexd - GAP  # (round 4: bigger and standing out more, owner: "the knee cop clearer"; F914 round 14,
		# owner picked bigger six-sided knee plates like the picture: 4.7 -> 5.6 cm)
		lames = (  # (how far inside the plate, extra stand-off at its lower edge, from z, plate id)
			(np.minimum.reduce([g.Z - 0.292, 0.395 - g.Z, ring(-0.9, 2.4)]), 0.006, 0.292, 0.395, 0),
			(np.minimum.reduce([g.Z - 0.24, 0.302 - g.Z, ring(-2.3, 2.3)]), 0.004, 0.24, 0.302, 1),
			# (round 4: the greaves taller, from inside the boot's top up under the knee)
			(np.minimum.reduce([g.Z - 0.174, 0.248 - g.Z, ring(-1.6, 1.6)]), 0.003, 0.174, 0.248, 2),
			(np.minimum.reduce([g.Z - 0.174, 0.248 - g.Z, np.minimum(ring(1.6, 4.6), ring(-4.6, -1.6))]), 0.003, 0.174, 0.248, 3))
		parts = []
		for inn, fl_, zlo, zhi, pid in lames:
			inn = inn - GAP
			lift = fl_ * np.clip((zhi - g.Z) / (zhi - zlo), 0, 1)
			parts.append((hard_plate(surf, inn, bulk=0.0075, lift=lift), inn, pid + 16 * (side == "r")))
		parts.append((hard_plate(surf, cop_in, bulk=0.0075, lift=0.02), cop_in, 4 + 16 * (side == "r")))
		P, E, I = union_parts(parts)
		P = np.maximum(P, 0.003 - d)
		o = g.mesh(f"_legs_{side}", MAT["plate"], P)
		objs.append(o)
		tparts.append((g, P, E, I))
		pts = []
		for a_, z in ((-0.7, 0.375), (2.2, 0.375), (1.0, 0.383), (-2.05, 0.288), (2.05, 0.288),
				(-1.35, 0.236), (1.35, 0.236), (1.85, 0.236), (-1.85, 0.236)):  # rivets at the plates' top corners
			dirn = Vector((sx * math.sin(a_), -math.cos(a_), 0))
			pts.append((Vector((sx * 0.129, 0.03, z)) + dirn * 0.25, -dirn))
		for a_, z in ((-0.4, 0.268), (0.4, 0.268), (0.0, 0.302), (0.0, 0.234)):  # round the knee cop
			dirn = Vector((sx * math.sin(a_), -math.cos(a_), 0))
			pts.append((Vector((sx * 0.129, 0.03, z)) + dirn * 0.25, -dirn))
		items += plate_items(o, pts, 0.0064)
	bpy.ops.object.select_all(action="DESELECT")
	for o in objs:
		o.select_set(True)
	bpy.context.view_layer.objects.active = objs[0]
	bpy.ops.object.join()
	o = bpy.context.view_layer.objects.active
	o.name = "armor_legs_plate"
	PIECES.append((o, "legs", "plate", hard_tint(tparts), plate_disp))
	br = small_piece(f"armor_legs_{RIVET}", MAT[RIVET], items)
	if br:
		PIECES.append((br, "legs", RIVET, None, None))


log("building the", SET, "set")
build_helmet()
HAIR = BODYM.pop("armor_head_hair")
build_jerkin()
build_boots()
if HARD:
	build_gauntlets()
	build_legs()
log("shapes done:", [(o.name, len(o.data.polygons)) for o, *_ in PIECES])

# ---------------------------------------------------------------- the light game copies, painted and baked
FACES = {"leather": {"head": 7000, "chest": 16000, "feet": 9000}, "fleece": 3500, "brass": 2500, "cord": 2500,
	"plate": {"head": 8000, "chest": 18000, "feet": 8000, "hands": 12000, "legs": 9000}, "rivet": 4000}
SIZES = {"leather": {"head": 1024, "chest": 2048, "feet": 1024}, "fleece": 512, "brass": 256, "cord": 256,
	"plate": {"head": 1024, "chest": 2048, "feet": 1024, "hands": 1024, "legs": 1024}, "rivet": 256}


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
		if len(hi.data.polygons) < 150000:  # (round 3: 202k-face jerkin smoothing ran out of memory too)
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
		if pic and "/" in pic[0]:  # (a set recipe's own tile, a path under assets/)
			pic_path = str(ROOT / "assets" / pic[0])
		else:
			pname = pic[0] if pic and pic[0].startswith(SET) else (f"{SET}_{pic[0]}" if pic else "")
			pic_path = str(TEX / f"{pname}.png") if pic and (TEX / f"{pname}.png").exists() else None  # (round 5: the bold sheet, hide2)
		hi.data.materials.clear()
		hi.data.materials.append(cs.paint_material(f"paint_{raw.name}", base=pp["base"], dark=pp["dark"], light=pp["light"],
			strokes=pp["strokes"], top_light=0.12, edge=(0.45 if mname == "plate" else 0.3) if mname != "fleece" else 0.15, key=0.28, seed=5, tint_attr=tint_name,
			scratches=(1.0 if piece == "chest" else 0.4) if mname == "leather" else (0.6 if mname == "plate" else 0.0), scratch_width=0.5,
			# (round 1's cap had a black patch: the shading counted his head inside it; now only the piece itself)
			ao_local=True, picture=pic_path, picture_scale=pic[1] if pic else 6.0,
			picture_amount=RC[mname]["amount"] if mname in ("plate", "rivet") else 0.85))
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
		if mname in ("plate", "rivet"):  # (metal shines: the baked material is matt like leather otherwise)
			b = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
			b.inputs["Metallic"].default_value = RC[mname]["metal"]
			b.inputs["Roughness"].default_value = RC[mname]["rough"]
	log("made", raw.name, len(raw.data.polygons), "faces")

# ---------------------------------------------------------------- which bones move each point: the body's under it
SRC = {"head": None, "chest": ["body_shirt"], "feet": ["body_foot_l", "body_foot_r", "body_torso"],
	"hands": ["body_hand_l", "body_hand_r", "body_torso"], "legs": ["body_shorts", "body_torso"]}
# (which of the body's own points each piece copies: the boots only the legs, the gauntlets only the forearms)
KEEP = {"feet": lambda p: p[2] <= 0.3, "hands": lambda p: abs(p[0]) > 0.37, "legs": lambda p: 0.16 < p[2] < 0.47 and abs(p[0]) < 0.3}


def source_points(names, keep=None):
	pts, ws = [], []
	for n in names:
		o = BODYM[n]
		gn = {vg.index: vg.name for vg in o.vertex_groups}
		wv = world_verts(o)
		for v, p in zip(o.data.vertices, wv):
			if n == "body_torso" and keep and not keep(p):
				continue  # (the boots never follow the arms or the belly)
			pts.append(p)
			ws.append({gn[g.group]: g.weight for g in v.groups if g.weight > 0.0})
	kd = kdtree.KDTree(len(pts))
	for i, p in enumerate(pts):
		kd.insert(Vector(p), i)
	kd.balance()
	return kd, ws


KD = {k: source_points(v, KEEP.get(k)) for k, v in SRC.items() if v and (k not in ("hands", "legs") or HARD)}
for o, piece, mname, *_ in PIECES:
	for vg in list(o.vertex_groups):
		o.vertex_groups.remove(vg)
	groups = {}
	wv = world_verts(o)
	# (round 4 tried each chest plate moving as one stiff piece: standing, his belly bent forward and poked through
	# the breastplate. The plates' shapes are stiff; their weights follow the body like the leather under them.)
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
	o.data.validate(clean_customdata=False)  # (joined plate parts can leave a broken face: "Mesh is not valid" on export)
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
