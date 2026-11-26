# Picture-to-3D armour TEST (owner OK'd a one-time exception to MODEL-RULES rule 1, Nov 26; docs/art/PICTURE-TO-3D-RULES.md).
# Takes one armour piece made by Hunyuan3D 2.1 from a flat-lit GPT picture and fits it on the dwarf:
#   1. bend his arms down to the armour's sleeve angle (the generated armour hangs like arms down; he is built arms out)
#   2. scale the armour round his posed body, push every point at least GAP off his skin
#   3. copy the bones of the nearest body point (the skirt follows his hips/thighs, the shoulder plates his arms)
#   4. bend it back to his arms-out pose (inverse of the skinning), so the game's skeleton puts it on exactly
#   5. photos: arms down like the game, front / side / back / 3-4
#
#   blender --background --factory-startup --python tools/asset_forge/builds/armor_picture3d.py -- <piece> <high.glb> <out.glb>
#       [review=<pic.png>] [sheet=<2x2 picture>] [angle=40] [faces=200000]
# The generated models and pictures stay OUTSIDE the repo (C:/Users/<you>/ai3d/armor3d/), never committed.
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix, Vector, kdtree
from mathutils.bvhtree import BVHTree

HERE = Path(__file__).resolve()
ROOT = HERE.parents[3]
ARGS = sys.argv[sys.argv.index("--") + 1:]
PIECE, HIGH, OUT = ARGS[0], ARGS[1], ARGS[2]
OPT = dict(a.split("=", 1) for a in ARGS[3:] if "=" in a)
ANGLE = float(OPT.get("angle", 40))
FACES = int(OPT.get("faces", 200000))
GAP = 0.012
BODY = ROOT / "assets" / "characters" / "dwarf" / "dwarf_body.glb"
# where each piece sits on him (Blender: x = his left, -y = front, z up): top and bottom height of the armour
# chest round 2: waist = where the skirt starts narrowing, skirt_low = fully narrowed from there down (x sides, y depth)
FIT = {"chest": dict(top=0.965, bottom=0.31, src=["body_shirt", "body_torso", "body_shorts"], belly=(0.45, 0.72),
		waist=float(OPT.get("waist", 0.61)), skirt_low=float(OPT.get("skirt_low", 0.45)),
		skirt_x=float(OPT.get("skirt_x", 0.8)), skirt_y=float(OPT.get("skirt_y", 0.86)),
		# back plates (built bottom up): (angle round him, 0 = middle of his back; height; half width; half height)
		back_plates=[(0.0, 0.70, 0.13, 0.052), (-0.4, 0.82, 0.075, 0.085), (0.4, 0.82, 0.075, 0.085)],
		leather_low=0.55, leather_poke=0.03, leather_cover=float(OPT.get("leather_cover", 0.035))),
	# helm: eye = slit height in the picture (0 top .. 1 bottom), eye_z = his eyes, wall = helmet side past his head
	"helm": dict(eye=0.54, eye_z=1.083, brow_z=1.15, wall=0.068, back=0.0, src=[])}[PIECE]


def log(*a):
	print("PIC3D", *a, flush=True)


def verts(o, depsgraph=None):
	if depsgraph:
		ev = o.evaluated_get(depsgraph)
		me = ev.to_mesh()
		co = np.array([v.co[:] for v in me.vertices])
		polys = [tuple(p.vertices) for p in me.polygons]
		ev.to_mesh_clear()
	else:
		co = np.empty(len(o.data.vertices) * 3)
		o.data.vertices.foreach_get("co", co)
		co = co.reshape(-1, 3)
		polys = None
	m = np.array(o.matrix_world)
	return co @ m[:3, :3].T + m[:3, 3], polys


# ---------------------------------------------------------------- the body, arms bent down like the armour
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(BODY))
ARM = next(o for o in bpy.context.scene.objects if o.type == "ARMATURE")
BODYM = {o.name: o for o in bpy.context.scene.objects if o.type == "MESH" and o.name.startswith("body_")}
for o in [o for o in bpy.context.scene.objects if o.type == "MESH" and not o.name.startswith("body_")]:
	bpy.data.objects.remove(o, do_unlink=True)
for o in BODYM.values():
	if not any(m.type == "ARMATURE" for m in o.modifiers):
		o.modifiers.new("skeleton", "ARMATURE").object = ARM


def pose_arms(deg):
	bpy.context.view_layer.objects.active = ARM
	bpy.ops.object.mode_set(mode="POSE")
	for pb in ARM.pose.bones:
		pb.matrix_basis = Matrix()
	bpy.context.view_layer.update()
	for side in ("l", "r"):
		pb = ARM.pose.bones[f"upperarm_{side}"]
		h = pb.head.copy()
		rot = Matrix.Translation(h) @ Matrix.Rotation(math.radians(deg) * (1 if pb.head.x > 0 else -1), 4, "Y") @ Matrix.Translation(-h)
		pb.matrix = rot @ pb.matrix
		bpy.context.view_layer.update()
	bpy.ops.object.mode_set(mode="OBJECT")
	bpy.context.view_layer.update()


pose_arms(ANGLE)
DG = bpy.context.evaluated_depsgraph_get()
POSED = {n: verts(o, DG) for n, o in BODYM.items()}
log("body posed, arms down", ANGLE)

# ---------------------------------------------------------------- the generated armour: fewer faces, scaled round him
bpy.ops.import_scene.gltf(filepath=HIGH)
A = next(o for o in bpy.context.selected_objects if o.type == "MESH")
A.name = f"armor_{PIECE}_plate"
bpy.context.view_layer.objects.active = A
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
A.parent = None
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
n0 = len(A.data.polygons)
if n0 > FACES:
	d = A.modifiers.new("fewer", "DECIMATE")
	d.ratio = FACES / n0
	bpy.ops.object.modifier_apply(modifier="fewer")
log("armour faces", n0, "->", len(A.data.polygons))
co, _ = verts(A)


# ---------------------------------------------------------------- paint: the 4 flat-lit views projected on (like a slide
# projector from the front, back and both sides, each point takes the views that face it most)
def project_colours(co, nrm, sheet_dir):
	def load(path):  # (Blender's Python has no PIL: its own image loader, rows bottom-up)
		img = bpy.data.images.load(path)
		w, h = img.size
		px = np.empty(w * h * 4, dtype=np.float32)
		img.pixels.foreach_get(px)
		return px.reshape(h, w, 4)[::-1, :, :3].astype(float)

	lo, hi = co.min(0), co.max(0)
	views = {  # picture: (which way it looks at him, horizontal axis, flip it)
		"front": (np.array([0, -1, 0]), 0, False), "back": (np.array([0, 1, 0]), 0, True),
		"left": (np.array([1, 0, 0]), 1, False), "right": (np.array([-1, 0, 0]), 1, True)}
	col = np.zeros((len(co), 3))
	wsum = np.zeros(len(co)) + 1e-6
	uvs, wts = {}, {}
	for name, (d, ax, flip) in views.items():
		im = load(f"{sheet_dir}/{name}.png")
		PICS[name] = f"{sheet_dir}/{name}.png"
		bg = im[2, 2]
		fg = np.abs(im - bg).sum(2) > 0.12
		ys, xs = np.nonzero(fg)
		x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
		u = (co[:, ax] - lo[ax]) / (hi[ax] - lo[ax])
		if flip:
			u = 1 - u
		v = (hi[2] - co[:, 2]) / (hi[2] - lo[2])
		px = np.clip((x0 + u * (x1 - x0)).astype(int), 0, im.shape[1] - 1)
		py = np.clip((y0 + v * (y1 - y0)).astype(int), 0, im.shape[0] - 1)
		w = np.clip(nrm @ d, 0, 1) ** 4  # (d points from him to the camera: faces turned that way get it)
		col += im[py, px] * w[:, None]
		wsum += w
		# (the same spot as picture coordinates, 0..1, for the sharp bake: Blender's pictures count rows bottom-up)
		uvs[name] = np.stack([(x0 + u * (x1 - x0) + 0.5) / im.shape[1], 1 - (y0 + v * (y1 - y0) + 0.5) / im.shape[0]], 1)
		wts[name] = w
	tot = sum(wts.values()) + 1e-6
	return col / wsum[:, None], uvs, {k: w / tot for k, w in wts.items()}


VIEWS = ("front", "back", "left", "right")
PICS = {}  # view -> picture file (for the sharp bake)
SHEET = OPT.get("sheet")
if SHEET:
	nrm = np.empty(len(A.data.vertices) * 3)
	A.data.vertices.foreach_get("normal", nrm)
	rgb, uvs, wts = project_colours(co, nrm.reshape(-1, 3), SHEET)
	ca = A.data.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
	ca.data.foreach_set("color", np.hstack([rgb, np.ones((len(rgb), 1))]).ravel())  # (Blender's pixels are linear)
	# Round 2 (owner: "blurry"): the pictures are only 627 px, and one colour per point (~3-4 mm apart) blurred them
	# more. Each point also keeps WHERE it sits in each picture (a picture map per view) and how much each view counts
	# (PW): the game copy's bake reads the pictures themselves through those, sharp to the picture's own pixel.
	li = np.empty(len(A.data.loops), dtype=int)
	A.data.loops.foreach_get("vertex_index", li)
	for name in VIEWS:
		uv = A.data.uv_layers.new(name=f"pv_{name}")
		uv.data.foreach_set("uv", uvs[name][li].ravel())
	pw = A.data.color_attributes.new("PW", "FLOAT_COLOR", "POINT")
	pw.data.foreach_set("color", np.stack([wts[n] for n in VIEWS], 1).ravel())
	log("painted from the pictures in", SHEET)
def drop_crumbs(o, keep=0.02):
	"""The generator leaves tiny loose bits floating round the piece: keep only parts with >= keep of the points."""
	import bmesh
	bm = bmesh.new()
	bm.from_mesh(o.data)
	bm.verts.ensure_lookup_table()
	seen, kill = set(), []
	for v in bm.verts:
		if v.index in seen:
			continue
		part, todo = [], [v]
		seen.add(v.index)
		while todo:
			x = todo.pop()
			part.append(x)
			for e in x.link_edges:
				y = e.other_vert(x)
				if y.index not in seen:
					seen.add(y.index)
					todo.append(y)
		if len(part) < keep * len(bm.verts):
			kill += part
	bmesh.ops.delete(bm, geom=kill, context="VERTS")
	bm.to_mesh(o.data)
	bm.free()
	log("loose crumbs dropped", len(kill), "points")


EXTRA = []  # (chest round 2: the rivets and the trimmed leather undercoat, exported with the plate)
LEGS = None
HAIR = None  # the hat-hair head the game shows under a helmet (taken from the hand-built copper set)


def fit_helm():
	"""Helmet: one hard piece on the Head bone, sized round his hat-hair head, eye slits at his eyes."""
	global co, HAIR
	drop_crumbs(A)
	co, _ = verts(A)
	before = set(bpy.context.scene.objects)
	bpy.ops.import_scene.gltf(filepath=str(ROOT / "assets" / "characters" / "dwarf" / "armor_copper.glb"))
	for o in set(bpy.context.scene.objects) - before:
		if o.type == "MESH" and o.name.startswith("armor_head_hair") and HAIR is None:
			HAIR = o
	hco, _ = verts(HAIR)
	for o in set(bpy.context.scene.objects) - before - {HAIR}:
		bpy.data.objects.remove(o, do_unlink=True)
	HAIR.parent = None
	HAIR.matrix_world = Matrix()
	HAIR.data.vertices.foreach_set("co", hco.ravel())
	HAIR.data.update()
	HAIR.name = "armor_head_hair"
	for m in list(HAIR.modifiers):
		HAIR.modifiers.remove(m)
	z0, z1 = co[:, 2].min(), co[:, 2].max()
	eye = FIT["eye"]  # (slit height in the picture, from the top)
	# width at the slits vs his head there + wall
	ze = z1 - eye * (z1 - z0)
	sl = co[np.abs(co[:, 2] - ze) < 0.02 * (z1 - z0)]
	hs = hco[(np.abs(hco[:, 2] - FIT["eye_z"]) < 0.03) & (hco[:, 1] < 0.12)]
	s = (np.abs(hs[:, 0]).max() + FIT["wall"]) / np.abs(sl[:, 0] - (sl[:, 0].max() + sl[:, 0].min()) / 2).max()
	cx = (co[:, 0].max() + co[:, 0].min()) / 2
	co[:, 0] = (co[:, 0] - cx) * s
	co[:, 1] *= s
	co[:, 2] = (co[:, 2] - ze) * s + FIT["eye_z"]
	sl = co[np.abs(co[:, 2] - FIT["brow_z"]) < 0.02]
	hb = hco[np.abs(hco[:, 2] - FIT["brow_z"]) < 0.02]
	dy = (hb[:, 1].max() + hb[:, 1].min()) / 2 - (sl[:, 1].max() + sl[:, 1].min()) / 2 + FIT["back"]
	co[:, 1] += dy
	log("helm scale", round(s, 3), "shift y", round(dy, 3), "top", round(co[:, 2].max(), 3), "bottom", round(co[:, 2].min(), 3))
	# nothing of the head (face, hat hair) closer than GAP to the helmet's inside
	hv, hf = verts(HAIR)[0], [tuple(p.vertices) for p in HAIR.data.polygons]
	# (round 3: the beard hangs out over the rim like on the chest, so the fit ignores it: no face below his nose
	# in front, no braid below the rim's back)
	hf = [f for f in hf if not (hv[list(f), 2].mean() < FIT["eye_z"] - 0.06 and hv[list(f), 1].mean() < 0.02)
		and hv[list(f), 2].mean() > co[:, 2].min() + 0.03]
	bvh = BVHTree.FromPolygons([Vector(p) for p in hv], hf)
	# (rounds 2-4: tests against his hair mesh made lumps and spikes, the hair locks' surfaces fool any inside test, as
	# in dwarf_armor.py. Now: his skull as one egg (dwarf_armor.SKULL_C/R), the hat hair lies within 1.8 cm of it; the
	# helmet stays CLEAR + GAP outside, pressed out from the egg's middle, inside and outside face of the wall together)
	SC, SR = np.array((0.0, 0.026, 1.075)), np.array((0.119, 0.11, 0.117))
	CLEAR = 0.018 + GAP
	R = 0.04
	total = 0
	for k in range(4):
		v = co - SC
		r = np.linalg.norm(v, axis=1)
		dn = v / np.maximum(r, 1e-9)[:, None]
		rs = 1.0 / np.sqrt(((dn / SR) ** 2).sum(1))  # (the egg's radius in this direction)
		face = (co[:, 2] < SC[2] - 0.01) & (co[:, 1] < SC[1] - 0.04)  # (below his brows in front: the face is open)
		need = np.where(face, 0.0, rs + CLEAR - r)
		ids = np.nonzero(need > 0.0005)[0]
		if not len(ids):
			break
		total += len(ids)
		pk = kdtree.KDTree(len(ids))
		for j, i in enumerate(ids):
			pk.insert(Vector(co[i]), j)
		pk.balance()
		amt = np.zeros(len(co))
		for i, p in enumerate(co):
			for _, j, d in pk.find_range(Vector(p), R):
				f = 1 - d / R
				amt[i] = max(amt[i], need[ids[j]] * f * f * (3 - 2 * f))
		co += dn * amt[:, None]
		log("press-out pass", k, "spots", len(ids), "max cm", round(float(amt.max()) * 100, 1))
	log("points pressed out round his head", total)
	A.vertex_groups.new(name="Head").add(list(range(len(co))), 1.0, "REPLACE")
	A.data.vertices.foreach_set("co", co.ravel())
	A.data.update()
	pose_arms(0)
	for o in (A, HAIR):
		o.parent = ARM
		o.parent_type = "OBJECT"
		o.matrix_parent_inverse = ARM.matrix_world.inverted()
		o.modifiers.new("skeleton", "ARMATURE").object = ARM
	A.name = "armor_head_plate"
	log("helmet on the Head bone, with the hat-hair head")


if PIECE == "helm":
	fit_helm()
else:
	z0, z1 = co[:, 2].min(), co[:, 2].max()
	sz = (FIT["top"] - FIT["bottom"]) / (z1 - z0)
	co[:, 2] = (co[:, 2] - z0) * sz + FIT["bottom"]
	co[:, 0] *= sz
	co[:, 1] *= sz  # (first the same scale every way; then width and depth fitted to his belly)
	bcol = np.vstack([POSED[n][0] for n in ("body_shirt",)])
	sx, sy, oy = 1.0, 1.0, 0.0
	best = []
	for z in np.linspace(*FIT["belly"], 8):
		b = bcol[(np.abs(bcol[:, 2] - z) < 0.01) & (np.abs(bcol[:, 0]) < 0.3)]
		a = co[(np.abs(co[:, 2] - z) < 0.01)]
		ac = a[np.abs(a[:, 0]) < 0.08]
		bc = b[np.abs(b[:, 0]) < 0.08]
		if len(b) < 5 or len(a) < 5 or len(ac) < 3 or len(bc) < 3:
			continue
		best.append(((np.abs(b[:, 0]).max() + GAP * 1.5) / np.abs(a[:, 0]).max(),
			(bc[:, 1].max() - bc[:, 1].min() + 3 * GAP) / (ac[:, 1].max() - ac[:, 1].min()),
			(bc[:, 1].max() + bc[:, 1].min()) / 2, (ac[:, 1].max() + ac[:, 1].min()) / 2))
	best = np.array(best)
	sx, sy = best[:, 0].max(), best[:, 1].max()
	i = int(np.argmax(best[:, 1]))
	oy = best[i, 2] - best[i, 3] * sy
	co[:, 0] *= sx
	co[:, 1] = co[:, 1] * sy + oy
	log("fit scale", round(sz, 3), "width x", round(sx, 3), "depth x", round(sy, 3), "shift y", round(oy, 3))

	# ---------------------------------------------------------------- round 2 (owner: "the skirt is too wide"): below his
	# waist the sides and the front-to-back are squeezed in, fully from SKIRT_LOW down (the push-out below keeps it off
	# his legs and the plated legs piece, which it now hangs over)
	ZW, ZL = FIT["waist"], FIT["skirt_low"]
	t = np.clip((ZW - co[:, 2]) / (ZW - ZL), 0, 1)
	t = t * t * (3 - 2 * t)
	mid_y = np.median(co[(co[:, 2] < ZW) & (co[:, 2] > ZL), 1])
	co[:, 0] *= 1 - t * (1 - FIT["skirt_x"])
	co[:, 1] = mid_y + (co[:, 1] - mid_y) * (1 - t * (1 - FIT["skirt_y"]))
	log("skirt squeezed to", FIT["skirt_x"], FIT["skirt_y"], "below", ZW)

	# ---------------------------------------------------------------- nothing inside him: push points out to GAP
	# (round 2: nor inside the hand-built plated legs, worn with it: thigh plates the skirt hangs over)
	LEGS = LEATHER = None
	before = set(bpy.context.scene.objects)
	bpy.ops.import_scene.gltf(filepath=str(ROOT / "assets" / "characters" / "dwarf" / "armor_copper.glb"))
	for o in set(bpy.context.scene.objects) - before:
		if o.type == "MESH" and o.name.startswith("armor_legs_plate"):
			LEGS = o
		elif o.type == "MESH" and o.name.startswith("armor_chest_leather"):
			LEATHER = o
	for o in (LEGS, LEATHER):
		w = verts(o)[0]
		o.parent = None
		o.matrix_world = Matrix()
		o.data.vertices.foreach_set("co", w.ravel())
		o.data.update()
		for m in list(o.modifiers):
			o.modifiers.remove(m)
		o.modifiers.new("skeleton", "ARMATURE").object = ARM
	for o in set(bpy.context.scene.objects) - before - {LEGS, LEATHER}:
		bpy.data.objects.remove(o, do_unlink=True)
	LEGS.name, LEATHER.name = "legs_check", "armor_chest_leather"
	bodyv, bodyf, off = [], [], 0
	bpy.context.view_layer.update()
	for v, f in [POSED[n] for n in FIT["src"] + ["body_pants"]] + ([] if OPT.get("nolegs") else [verts(LEGS, bpy.context.evaluated_depsgraph_get())]):
		bodyv.append(v)
		bodyf += [tuple(i + off for i in p) for p in f]
		off += len(v)
	bodyv = np.vstack(bodyv)
	BVH = BVHTree.FromPolygons([Vector(p) for p in bodyv], bodyf)
	moved = 0
	for k in range(3):
		for i, p in enumerate(co):
			hit = BVH.find_nearest(Vector(p))
			if hit[0] is None:
				continue
			q, nrm = hit[0], hit[1]
			dv = Vector(p) - q
			s = dv.dot(nrm)
			if s < GAP:
				co[i] = np.array(q + nrm * GAP)
				moved += 1
	log("points pushed out of his body", moved)

	# ---------------------------------------------------------------- the beard hangs OVER the armour: press the front back
	# under it (each point inside a braid goes behind the braid + 1 cm, its neighbours follow softly so there's no dent)
	hv, hf = POSED["body_head"]
	HB = BVHTree.FromPolygons([Vector(p) for p in hv], hf)
	FWD, BACK = Vector((0, -1, 0)), Vector((0, 1, 0))


	def beard_back(p):
		"""The beard's back surface in front of/around point p (a ray from in front of him going back), or None."""
		o = Vector((p[0], -1.0, p[2]))
		enter = HB.ray_cast(o, BACK, 2.0)
		if enter[0] is None or enter[0].y > p[1] + 0.10:
			return None  # (no beard here, or far behind: the plate is a thick shell, its front face is up to ~4 cm out)
		leave = HB.ray_cast(enter[0] + BACK * 1e-4, BACK, 0.03)
		return enter[0].y + 0.03 if leave[0] is None else leave[0].y  # (where it joins his chin there's no back: 3 cm in)


	push = {}
	for i, p in enumerate(co):
		if p[2] > 0.96 or p[1] > 0.0:
			continue
		by = beard_back(p)
		if by is not None and p[1] < by + 0.008:
			push[i] = min(by + 0.008 - p[1], 0.16)
	if push:
		ids = list(push)
		pk = kdtree.KDTree(len(ids))
		for j, i in enumerate(ids):
			pk.insert(Vector(co[i]), j)
		pk.balance()
		R = 0.03
		dy = np.zeros(len(co))
		for i, p in enumerate(co):
			if p[2] > 0.99 or p[1] > 0.05:
				continue
			for _, j, d in pk.find_range(Vector(p), R):
				f = 1 - (d / R)
				f = f * f * (3 - 2 * f)
				dy[i] = max(dy[i], push[ids[j]] * f)
		co[:, 1] += dy  # (no skin check after: the dent may touch his shirt, the beard hides it, like dwarf_armor.py)
		# ...but never into his shirt (the shirt showed white through the plate at his throat): back out to 4 mm
		back_out = 0
		for i in np.nonzero(dy)[0]:
			hit = BVH.find_nearest(Vector(co[i]))
			if hit[0] is not None and (Vector(co[i]) - hit[0]).dot(hit[1]) < 0.004:
				co[i] = np.array(hit[0] + hit[1] * 0.004)
				back_out += 1
		log("pressed points kept out of his shirt", back_out)
	log("points pressed back under the beard", len(push))

	# ---------------------------------------------------------------- round 2 (owner: "more detail and polish, blurry and
	# low-poly, worst from behind: the back is plain"): hand-built copper laid ON the picture's plate, like the hand-built
	# set: stiff back plates with a raised rim, a rolled rim round the skirt's hem and the back of the neck, and rivets.
	# Built in the same arms-down pose as the fitted plate, then joined into it (the game copy bakes them with it); the
	# rivets are their own small mesh. Every built part sinks 3 mm into the plate at its edge: joined, no shimmer.
	import bmesh
	A.data.vertices.foreach_set("co", co.ravel())
	A.data.update()
	APOLY = [tuple(p.vertices) for p in A.data.polygons]
	ACOL = np.empty(len(co) * 4)
	A.data.color_attributes["Col"].data.foreach_get("color", ACOL)
	ACOL = ACOL.reshape(-1, 4)[:, :3]
	AKD = kdtree.KDTree(len(co))
	for i, p in enumerate(co):
		AKD.insert(Vector(p), i)
	AKD.balance()
	rng = np.random.default_rng(int(OPT.get("seed", 7)))
	shirt = POSED["body_shirt"][0]
	ZS = np.linspace(0.25, 1.05, 81)
	AY = np.array([np.median(s[:, 1]) if len(s) > 4 else np.nan for s in
		(shirt[(np.abs(shirt[:, 2] - z) < 0.02) & (np.abs(shirt[:, 0]) < 0.12)] for z in ZS)])
	AY = np.interp(ZS, ZS[~np.isnan(AY)], AY[~np.isnan(AY)])

	def axis(z):
		"""His body's middle line (x, y) at height z (the armour's round shapes are laid out round it)."""
		z = np.asarray(z, dtype=float)
		return np.stack([np.zeros_like(z), np.interp(z, ZS, AY)], -1)

	BUILT = []  # (points, faces, colours): joined into the plate
	RIV = []    # (point, outward): one rivet each

	def surface():
		vv, ff, off = [co], list(APOLY), len(co)
		for v, f, _ in BUILT:
			vv.append(v)
			ff += [tuple(i + off for i in p) for p in f]
			off += len(v)
		return BVHTree.FromPolygons([Vector(p) for p in np.vstack(vv)], ff)

	def out_dir(phi):
		phi = np.asarray(phi, dtype=float)
		return np.stack([np.sin(phi), np.cos(phi), np.zeros_like(phi)], -1)  # (phi 0 = his back, +x his left)

	def radial_hit(bv, phi, z):
		"""How far out from his middle line a level ray from outside first meets the armour (None: it misses)."""
		a, d = axis(z), out_dir(phi)
		hit = bv.ray_cast(Vector((a[0] + d[0] * 0.8, a[1] + d[1] * 0.8, z)), Vector(-d), 0.8)
		return None if hit[0] is None else float(np.hypot(hit[0].x - a[0], hit[0].y - a[1]))

	def near_col(P):
		return np.array([ACOL[AKD.find(Vector(p))[1]] for p in P.reshape(-1, 3)])

	def smooth_ring(a, n=2):
		for _ in range(n):
			a = (np.roll(a, 1, 0) + a * 2 + np.roll(a, -1, 0)) / 4
		return a

	S = np.array([0.0, 0.2, 0.38, 0.52, 0.64, 0.73, 0.79, 0.83, 0.865, 0.9, 0.925, 0.945, 0.962, 0.978, 0.99, 1.0])
	NSP = 72

	def panel(phi_c, z_c, hw, hh, thick=0.0065, rim=0.0028, rivet_gap=0.05):
		"""One stiff hand-cut plate on his back: a rounded rectangle hw x hh (half width along the body, half height,
		metres), resting on the highest bumps under it, a raised rim round its edge, rivets just inside the rim."""
		bv = surface()
		ref = radial_hit(bv, phi_c, z_c) or 0.17
		psi = np.linspace(0, 2 * np.pi, NSP, endpoint=False)
		ph = rng.uniform(0, 2 * np.pi, 3)
		rb = 1 / ((np.abs(np.cos(psi)) / hw) ** 5 + (np.abs(np.sin(psi)) / hh) ** 5) ** 0.2
		rb *= 1 + 0.03 * np.sin(2 * psi + ph[0]) + 0.02 * np.sin(5 * psi + ph[1])  # (hand-cut: no perfect corners)
		U, V = S[:, None] * rb * np.cos(psi), S[:, None] * rb * np.sin(psi)
		PHI, Z = phi_c - U / ref, z_c + V  # (minus: seen from behind his left is on the right)
		d0 = np.array([[radial_hit(bv, PHI[i, j], Z[i, j]) or np.nan for j in range(NSP)] for i in range(len(S))])
		mid = np.nanmedian(d0[:8])  # (rays near its top can hit the shoulder pads far out: a plate never reaches for those)
		d0 = np.where(np.isnan(d0) | (d0 > mid + 0.03), np.nan, d0)
		d0 = np.where(np.isnan(d0), np.minimum(np.nanmax(d0), mid + 0.03), d0)

		def up(D):
			return np.vstack([D[1:], D[-1:]])

		def dn(D):
			return np.vstack([D[:1], D[:-1]])

		D = d0.copy()
		for _ in range(3):  # (stiff: on the highest bumps, then smoothed; never below the surface under it)
			D = np.maximum.reduce([D, np.roll(D, 1, 1), np.roll(D, -1, 1), up(D), dn(D)])
		for _ in range(8):
			D = np.maximum((D * 2 + np.roll(D, 1, 1) + np.roll(D, -1, 1) + up(D) + dn(D)) / 6, d0 + 0.0015)
		s = S[:, None] * np.ones((1, NSP))
		h = thick + rim * np.sin(np.pi * np.clip((s - 0.79) / 0.135, 0, 1))
		h += np.where(s < 0.75, 0.0009 * np.sin(PHI * 41 + ph[2]) * np.sin(Z * 37 + ph[0]), 0)  # (hammer dents)
		f = np.clip((s - 0.925) / 0.075, 0, 1)
		f = f * f * (3 - 2 * f)
		R = (D + h) * (1 - f) + (d0 - 0.003) * f  # (the edge goes down and sinks 3 mm into the plate under it)
		a = axis(Z)
		P = np.stack([a[..., 0] + np.sin(PHI) * R, a[..., 1] + np.cos(PHI) * R, Z], -1)
		faces = [(0, NSP + j, NSP + (j + 1) % NSP) for j in range(NSP)]
		for i in range(1, len(S) - 1):
			faces += [(i * NSP + j, (i + 1) * NSP + j, (i + 1) * NSP + (j + 1) % NSP, i * NSP + (j + 1) % NSP)
				for j in range(NSP)]
		col = near_col(P)
		col = col * 0.45 + np.median(col, 0) * 0.55  # (the picture's back is blurry: a calmer, even copper)
		shade = np.where(s > 0.94, 0.5, np.where((s > 0.8) & (s < 0.905), 1.22, 1.0)) * rng.uniform(0.92, 1.06)
		BUILT.append((P.reshape(-1, 3), faces, col * shade.reshape(-1, 1)))
		ring = int(np.searchsorted(S, 0.7))
		arc = np.concatenate([[0], np.cumsum(np.linalg.norm(np.diff(P[ring], axis=0), axis=1))])
		n = max(4, int(arc[-1] / rivet_gap))
		for k in range(n):
			j = min(int(np.searchsorted(arc, k * arc[-1] / n)), NSP - 1)
			RIV.append((P[ring, j], out_dir(PHI[ring, j])))

	def tube(C, OUT, r, closed=True, shade=0.85):
		"""A rolled rim: a tube of radius r through the centres C (N x 3), its seam turned towards OUT."""
		K = 8
		T = (np.roll(C, -1, 0) - np.roll(C, 1, 0)) if closed else np.gradient(C, axis=0)
		T /= np.linalg.norm(T, axis=1)[:, None]
		B = np.cross(T, OUT)
		B /= np.linalg.norm(B, axis=1)[:, None]
		N = np.cross(B, T)
		ang = np.linspace(0, 2 * np.pi, K, endpoint=False)
		P = C[:, None] + r * (np.cos(ang)[None, :, None] * N[:, None] + np.sin(ang)[None, :, None] * B[:, None])
		n = len(C)
		faces = [(i * K + k, i * K + (k + 1) % K, ((i + 1) % n) * K + (k + 1) % K, ((i + 1) % n) * K + k)
			for i in range(n if closed else n - 1) for k in range(K)]
		P = P.reshape(-1, 3)
		if not closed:  # (end caps)
			for e in (0, n - 1):
				P = np.vstack([P, C[e]])
				faces += [(len(P) - 1, e * K + k, e * K + (k + 1) % K) for k in range(K)]
		col = np.median(near_col(C), 0) * shade
		BUILT.append((P, faces, np.tile(col, (len(P), 1)) * (1 + 0.05 * rng.standard_normal((len(P), 1)))))

	# the back: a plate band across the small of his back, two shoulder-blade plates over it (built bottom up: each
	# rests on the ones under it)
	for phi_c, z_c, hw, hh in ([] if OPT.get("noback") else FIT["back_plates"]):
		panel(phi_c, z_c, hw, hh)
	log("back plates", len(FIT["back_plates"]))
	# the skirt's hem: a rolled rim round its lowest edge, rivets above it
	bv = surface()
	phis = np.linspace(-np.pi, np.pi, 120, endpoint=False)
	hz = []
	for phi in phis:
		hz.append(next((z for z in np.arange(FIT["bottom"] - 0.02, FIT["bottom"] + 0.14, 0.002) if radial_hit(bv, phi, z)),
			np.nan))
	hz = np.array(hz)
	hz = smooth_ring(np.where(np.isnan(hz), np.nanmedian(hz), hz), 3) + 0.004
	hr = np.array([radial_hit(bv, p, z) or np.nan for p, z in zip(phis, hz)])
	hr = smooth_ring(np.where(np.isnan(hr), np.nanmedian(hr), hr), 2)
	a = axis(hz)
	C = np.stack([a[:, 0] + np.sin(phis) * (hr + 0.001), a[:, 1] + np.cos(phis) * (hr + 0.001), hz], -1)
	tube(C, out_dir(phis), 0.0055)
	bv = surface()
	for p, z in zip(phis[::3], hz[::3] + 0.024):
		r = radial_hit(bv, p, z)
		if r:
			RIV.append((np.array([*(axis(z) + out_dir(p)[:2] * r), z]), out_dir(p)))
	log("hem rim at", round(float(np.median(hz)), 3))
	# the back of the neck: the plate's top edge, found from above, from his left shoulder round to his right
	nphi = np.linspace(-1.9, 1.9, 48)
	NC = []
	for phi in nphi:
		a, d = axis(0.93), out_dir(phi)
		for rr in np.arange(0.05, 0.22, 0.003):
			hit = bv.ray_cast(Vector((a[0] + d[0] * rr, a[1] + d[1] * rr, 1.15)), Vector((0, 0, -1)), 0.35)
			if hit[0] is not None and hit[0].z > 0.8:
				NC.append(np.array(hit[0]) + d * 0.002)
				break
	NC = np.array(NC)
	for _ in range(2):
		NC[1:-1] = (NC[:-2] + NC[1:-1] * 2 + NC[2:]) / 4
	nout = np.array([out_dir(np.arctan2(c[0], c[1] - axis(c[2])[1])) for c in NC])
	tube(NC, nout, 0.006, closed=False)
	for c, o in zip(NC[2:-2:3], nout[2:-2:3]):
		RIV.append((c - np.array([0, 0, 0.018]), o))
	log("neck rim points", len(NC), "rivets", len(RIV))

	TP, TF, TC, off = [], [], [], 0
	for v, f, c in BUILT:
		TF += [tuple(i + off for i in p) for p in f]
		off += len(v)
		TP.append(v)
		TC.append(c)
	TP, TC = np.vstack(TP), np.clip(np.vstack(TC), 0, 1)
	tm = bpy.data.meshes.new("trim")
	tm.from_pydata([tuple(p) for p in TP], [], TF)
	tc = tm.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
	tc.data.foreach_set("color", np.hstack([TC, np.ones((len(TC), 1))]).ravel())
	# (all 0: not from the pictures; set by hand, a new colour layer starts white = "all 4 pictures count fully")
	tm.color_attributes.new("PW", "FLOAT_COLOR", "POINT").data.foreach_set("color", np.zeros(len(TP) * 4))
	for name in VIEWS:
		tm.uv_layers.new(name=f"pv_{name}")
	bm = bmesh.new()
	bm.from_mesh(tm)
	bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
	bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
	bm.to_mesh(tm)
	bm.free()
	TO = bpy.data.objects.new("trim", tm)
	bpy.context.scene.collection.objects.link(TO)
	bpy.ops.object.select_all(action="DESELECT")
	TO.select_set(True)
	A.select_set(True)
	bpy.context.view_layer.objects.active = A
	bpy.ops.object.join()
	co, _ = verts(A)
	log("built copper joined into the plate:", len(TP), "points")

	# rivets: domed heads, each on its own spot, their foot 1.5 mm into the plate
	rv, rf = [], []
	RINGS = [(1.0, -0.25), (1.0, 0.05), (0.85, 0.35), (0.55, 0.55), (0.12, 0.62)]
	for p, o in RIV:
		o = np.asarray(o, dtype=float)
		t = np.cross(o, (0, 0, 1.0))
		t = t / np.linalg.norm(t) if np.linalg.norm(t) > 1e-6 else np.array([1.0, 0, 0])
		b = np.cross(o, t)
		r = 0.0058 * rng.uniform(0.85, 1.1)
		base = len(rv)
		for rad, up in RINGS:
			for k in range(10):
				a_ = 2 * np.pi * k / 10
				rv.append(p + o * (up * r - 0.0015) + r * rad * (np.cos(a_) * t + np.sin(a_) * b) * rng.uniform(0.96, 1.04))
		for i in range(len(RINGS) - 1):
			rf += [(base + i * 10 + k, base + i * 10 + (k + 1) % 10, base + (i + 1) * 10 + (k + 1) % 10,
				base + (i + 1) * 10 + k) for k in range(10)]
		rf.append(tuple(base + (len(RINGS) - 1) * 10 + k for k in range(10)))  # (the top)
	rmesh = bpy.data.meshes.new("armor_chest_rivet")
	rmesh.from_pydata([tuple(v) for v in rv], [], rf)
	bm = bmesh.new()
	bm.from_mesh(rmesh)
	bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
	bm.to_mesh(rmesh)
	bm.free()
	RIVO = bpy.data.objects.new("armor_chest_rivet", rmesh)
	bpy.context.scene.collection.objects.link(RIVO)
	rmat = bpy.data.materials.new("armor_picture3d_rivet")
	rmat.use_nodes = True
	rb_ = rmat.node_tree.nodes["Principled BSDF"]
	rb_.inputs["Base Color"].default_value = (0.36, 0.17, 0.08, 1)  # (darker than the plate, like the hand-built rivets)
	rb_.inputs["Metallic"].default_value = 0.7
	rb_.inputs["Roughness"].default_value = 0.38
	rmesh.materials.append(rmat)
	for p in rmesh.polygons:
		p.use_smooth = True
	log("rivets", len(RIV))

	# ---------------------------------------------------------------- round 2 (owner: "no shirt showing anywhere"): the
	# hand-built set's leather undercoat (its collar fills the throat, its sides the gaps under his arms), but ONLY where
	# the plate doesn't cover it: every leather face that has plate in front of it, or that pokes out just over the
	# plate (round 1 showed it through the middle), goes; and nothing below his waist (the skirt is narrower now)
	bpy.context.view_layer.update()
	lv, lf = verts(LEATHER, bpy.context.evaluated_depsgraph_get())
	bv = BVHTree.FromPolygons([Vector(p) for p in co], [tuple(p.vertices) for p in A.data.polygons])
	kill = []
	for fi, f in enumerate(lf):
		q = lv[list(f)]
		c = q.mean(0)
		n = np.cross(q[1] - q[0], q[2] - q[0])
		n = Vector(n / (np.linalg.norm(n) + 1e-12))
		cv = Vector(c)
		# (only plate lying close over it hides it: under his arms the shoulder plate hangs 5+ cm out and the shirt
		# showed through that gap when the leather there went too)
		covered = bv.ray_cast(cv + n * 0.002, n, FIT["leather_cover"])[0] is not None
		poking = bv.ray_cast(cv - n * 0.001, -n, FIT["leather_poke"])[0] is not None
		if c[2] < FIT["leather_low"] or covered or poking:
			kill.append(fi)
	bm = bmesh.new()
	bm.from_mesh(LEATHER.data)
	bm.faces.ensure_lookup_table()
	bmesh.ops.delete(bm, geom=[bm.faces[i] for i in kill], context="FACES")
	bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
	bm.to_mesh(LEATHER.data)
	bm.free()
	drop_crumbs(LEATHER, 0.01)
	log("leather undercoat kept", len(lf) - len(kill), "of", len(lf), "faces")

	# ---------------------------------------------------------------- bones: the nearest body point's (posed)
	pts, ws = [], []
	for n in FIT["src"]:
		o = BODYM[n]
		gn = {vg.index: vg.name for vg in o.vertex_groups}
		for v, p in zip(o.data.vertices, POSED[n][0]):
			pts.append(p)
			ws.append({gn[g.group]: g.weight for g in v.groups if g.weight > 0.0})
	kd = kdtree.KDTree(len(pts))
	for i, p in enumerate(pts):
		kd.insert(Vector(p), i)
	kd.balance()
	W = ARM.matrix_world
	SKIN = {pb.name: W @ pb.matrix @ ARM.data.bones[pb.name].matrix_local.inverted() @ W.inverted() for pb in ARM.pose.bones}

	def bind(o, pco):
		"""Copy the nearest body points' bones onto o (points pco, posed); returns its points bent back to rest."""
		groups = {vg.name: vg for vg in o.vertex_groups}
		rest = np.empty_like(pco)
		for i, p in enumerate(pco):
			acc = {}
			for _, j, dist in kd.find_n(Vector(p), 6):
				for b, w in ws[j].items():
					acc[b] = acc.get(b, 0.0) + w / (dist + 0.004)
			top = sorted(acc.items(), key=lambda kv: -kv[1])[:4]
			tot = sum(w for _, w in top) or 1.0
			M = Matrix(((0, 0, 0, 0),) * 4)
			for b, w in top:
				if b not in groups:
					groups[b] = o.vertex_groups.new(name=b)
				groups[b].add([i], w / tot, "REPLACE")
				M = M + SKIN[b] * (w / tot)
			rest[i] = np.array(M.inverted() @ Vector(p))
		return rest

	rest = bind(A, co)
	rrest = bind(RIVO, verts(RIVO)[0])
	# back to his arms-out pose (the game binds the armour there)
	A.data.vertices.foreach_set("co", rest.ravel())
	A.data.update()
	RIVO.data.vertices.foreach_set("co", rrest.ravel())
	RIVO.data.update()
	pose_arms(0)
	for o in (A, RIVO, LEATHER):
		o.parent = ARM
		o.parent_type = "OBJECT"
		o.matrix_parent_inverse = ARM.matrix_world.inverted()
		if not any(m.type == "ARMATURE" for m in o.modifiers):
			o.modifiers.new("skeleton", "ARMATURE").object = ARM
	EXTRA = [RIVO, LEATHER]
	log("bones copied, bent back to arms out")

mat = bpy.data.materials.new(A.name)
mat.use_nodes = True
bsdf = mat.node_tree.nodes["Principled BSDF"]
bsdf.inputs["Base Color"].default_value = (0.62, 0.3, 0.16, 1)
if A.data.color_attributes:
	cn = mat.node_tree.nodes.new("ShaderNodeVertexColor")
	cn.layer_name = "Col"
	mat.node_tree.links.new(cn.outputs["Color"], bsdf.inputs["Base Color"])
bsdf.inputs["Metallic"].default_value = 0.6
bsdf.inputs["Roughness"].default_value = 0.45
A.data.materials.clear()
A.data.materials.append(mat)
for p in A.data.polygons:
	p.use_smooth = True

# ---------------------------------------------------------------- photos, arms down like the game
REVIEW = OPT.get("review")
if REVIEW:
	pose_arms(float(OPT.get("review_angle", 65)))
	if HAIR:  # (the game hides his own head under a helmet and shows the hat-hair one)
		BODYM["body_head"].hide_render = True
	sc = bpy.context.scene
	sc.render.engine = "BLENDER_WORKBENCH"
	sc.display.shading.light = "STUDIO"
	sc.display.shading.color_type = "VERTEX" if A.data.color_attributes else "MATERIAL"
	if "Col" in A.data.color_attributes:
		A.data.color_attributes.active_color_name = "Col"
	sc.render.resolution_x, sc.render.resolution_y = 520, 620
	cam = bpy.data.objects.new("rcam", bpy.data.cameras.new("rcam"))
	cam.data.type = "ORTHO"
	sc.collection.objects.link(cam)
	sc.camera = cam
	shots = []
	cz, osc = (1.0, 0.75) if HAIR else (0.62, 1.34)
	for tag, loc in (("front", (0, -4, cz)), ("side", (-4, 0, cz)), ("back", (0, 4, cz)), ("q34", (2.8, -2.8, cz + 0.28))):
		cam.location = Vector(loc)
		cam.data.ortho_scale = osc
		cam.rotation_euler = (Vector((0, 0, cz)) - cam.location).to_track_quat("-Z", "Y").to_euler()
		path = str(Path(REVIEW).with_name(Path(REVIEW).stem + f"_{tag}.png"))
		sc.render.filepath = path
		bpy.ops.render.render(write_still=True)
		shots.append(path)
	log("REVIEW", shots)
	pose_arms(0)

# ---------------------------------------------------------------- game copy (game=1): fewer faces, colours + bumps baked
# into pictures (like dwarf_armor.py: the dense model's paint and shape copied onto a light model's picture map)
# (round 2, owner: "blurry and low-poly": 4x the faces, 4x the picture, and the colour read from the pictures themselves)
GAME = OPT.get("game") == "1"
GFACES = {"chest": int(OPT.get("gfaces", 20000)), "helm": int(OPT.get("gfaces", 16000))}
GSIZE = {"chest": int(OPT.get("gsize", 4096)), "helm": int(OPT.get("gsize", 2048))}
WARM = (1.0, 0.78, 0.62)  # (the pictures' copper is pale and pink next to the hand-built pieces: deeper and warmer)


def sharp_paint():
	"""The dense model's glow for the colour bake: each of the 4 pictures read through its own picture map (pv_<view>),
	weighted by PW (how much that view faces the point); the built copper (PW = 0) glows its own colour (Col). Then the
	same warmer copper as before (colour ^ 1.25 x WARM)."""
	m = bpy.data.materials.new("bake_src")
	m.use_nodes = True
	nt = m.node_tree
	nt.nodes.remove(nt.nodes["Principled BSDF"])

	def node(kind, **kw):
		n = nt.nodes.new(kind)
		for k, v in kw.items():
			setattr(n, k, v)
		return n

	def vmath(op, a, b=None, scale=None):
		n = node("ShaderNodeVectorMath", operation=op)
		nt.links.new(a, n.inputs[0])
		if b is not None:
			nt.links.new(b, n.inputs[1])
		if scale is not None:
			nt.links.new(scale, n.inputs["Scale"])
		return n.outputs["Vector"]

	pw = node("ShaderNodeAttribute", attribute_name="PW")
	sep = node("ShaderNodeSeparateColor")
	nt.links.new(pw.outputs["Color"], sep.inputs["Color"])
	chans = [sep.outputs["Red"], sep.outputs["Green"], sep.outputs["Blue"], pw.outputs["Alpha"]]
	acc = wsum = None
	for name, ch in zip(VIEWS, chans):
		uv = node("ShaderNodeUVMap", uv_map=f"pv_{name}")
		tex = node("ShaderNodeTexImage", image=bpy.data.images.load(PICS[name]), extension="EXTEND")
		tex.image.colorspace_settings.name = "Non-Color"  # (as the old per-point paint read them: the raw values)
		nt.links.new(uv.outputs["UV"], tex.inputs["Vector"])
		part = vmath("SCALE", tex.outputs["Color"], scale=ch)
		acc = part if acc is None else vmath("ADD", acc, part)
		if wsum is None:
			wsum = ch
		else:
			add = node("ShaderNodeMath", operation="ADD")
			nt.links.new(wsum, add.inputs[0])
			nt.links.new(ch, add.inputs[1])
			wsum = add.outputs["Value"]
	rest = node("ShaderNodeMath", operation="SUBTRACT", use_clamp=True)
	rest.inputs[0].default_value = 1.0
	nt.links.new(wsum, rest.inputs[1])
	vc = node("ShaderNodeVertexColor", layer_name="Col")
	tot = vmath("ADD", acc, vmath("SCALE", vc.outputs["Color"], scale=rest.outputs["Value"]))
	gam = node("ShaderNodeGamma")
	nt.links.new(tot, gam.inputs["Color"])
	gam.inputs["Gamma"].default_value = 1.25
	warm = node("ShaderNodeVectorMath", operation="MULTIPLY")
	nt.links.new(gam.outputs["Color"], warm.inputs[0])
	warm.inputs[1].default_value = WARM
	emi = node("ShaderNodeEmission")
	nt.links.new(warm.outputs["Vector"], emi.inputs["Color"])
	nt.links.new(emi.outputs["Emission"], nt.nodes["Material Output"].inputs["Surface"])
	return m


if GAME:
	sys.path.insert(0, str(ROOT / "tools" / "asset_forge"))
	import creature_sculpt as cs  # noqa: E402
	for o in (A,):  # (the bake looks at both at rest: no skeleton bending needed)
		for m in list(o.modifiers):
			o.modifiers.remove(m)
	bpy.ops.object.select_all(action="DESELECT")
	A.select_set(True)
	bpy.context.view_layer.objects.active = A
	bpy.ops.object.duplicate()
	low = bpy.context.view_layer.objects.active
	d = low.modifiers.new("fewer", "DECIMATE")
	d.ratio = GFACES[PIECE] / len(low.data.polygons)
	cs._apply_all(low)
	import bmesh
	bm = bmesh.new()
	bm.from_mesh(low.data)
	bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0003)
	bmesh.ops.dissolve_degenerate(bm, edges=bm.edges, dist=0.0003)
	bm.to_mesh(low.data)
	bm.free()
	for p in low.data.polygons:
		p.use_smooth = True
	# (the light copy keeps only its own new picture map: no picture maps per view, no point colours)
	for uv in list(low.data.uv_layers):
		low.data.uv_layers.remove(uv)
	for ca in list(low.data.color_attributes):
		low.data.color_attributes.remove(ca)
	low.data.uv_layers.new(name="UVMap")
	cs.uv_only(low)
	A.data.materials.clear()
	A.data.materials.append(sharp_paint())
	gm = cs.bake(A, low, GSIZE[PIECE], f"armor_picture3d_{PIECE}_baked", ext=0.008)
	b = next(n for n in gm.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
	b.inputs["Metallic"].default_value = 0.6  # (copper shines; the bake's material is matt otherwise)
	b.inputs["Roughness"].default_value = 0.45
	gm.node_tree.nodes.active = next(n for n in gm.node_tree.nodes if n.type == "TEX_IMAGE" and n.image.name.endswith("_col"))
	name = A.name
	bpy.data.objects.remove(A, do_unlink=True)
	A = low
	A.name = name
	A.parent = ARM
	A.matrix_parent_inverse = ARM.matrix_world.inverted()
	A.modifiers.new("skeleton", "ARMATURE").object = ARM
	log("game copy", len(A.data.polygons), "faces, pictures", GSIZE[PIECE])
	if HAIR:  # (the game paints the hat-hair head with the normal head's pictures: a stand-in material, as dwarf_armor.py)
		HAIR.data.materials.clear()
		hm = bpy.data.materials.new("body_head_paint")
		HAIR.data.materials.append(hm)

# ---------------------------------------------------------------- export: skeleton + armour only
for o in list(BODYM.values()) + ([LEGS] if LEGS else []):
	bpy.data.objects.remove(o, do_unlink=True)
if not GAME:  # (the fitted dense file: drop the picture maps per view, the importer would make them real maps)
	for uv in [u for u in A.data.uv_layers if u.name.startswith("pv_")]:
		A.data.uv_layers.remove(uv)
bpy.ops.object.select_all(action="DESELECT")
for o in [ARM, A, HAIR] + EXTRA:
	if o:
		o.select_set(True)
if not A.data.uv_layers:
	A.data.uv_layers.new(name="UVMap")
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_yup=True, export_skins=True,
	export_animations=False, export_apply=False, **({"export_image_format": "JPEG", "export_image_quality": 88} if GAME else {}))
if GAME:
	import glb_jpeg_fix  # noqa: E402  (Godot shows Blender's JPEG pictures white without it: F164)
	glb_jpeg_fix.fix(OUT)
log("DONE", OUT, len(A.data.polygons), "faces", [o.name for o in EXTRA])
