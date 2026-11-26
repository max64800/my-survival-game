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
FIT = {"chest": dict(top=0.965, bottom=0.31, src=["body_shirt", "body_torso", "body_shorts"], belly=(0.45, 0.72)),
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
	for name, (d, ax, flip) in views.items():
		im = load(f"{sheet_dir}/{name}.png")
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
	return col / wsum[:, None]


SHEET = OPT.get("sheet")
if SHEET:
	nrm = np.empty(len(A.data.vertices) * 3)
	A.data.vertices.foreach_get("normal", nrm)
	rgb = project_colours(co, nrm.reshape(-1, 3), SHEET)
	ca = A.data.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
	ca.data.foreach_set("color", np.hstack([rgb, np.ones((len(rgb), 1))]).ravel())  # (Blender's pixels are linear)
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

	# ---------------------------------------------------------------- nothing inside him: push points out to GAP
	bodyv, bodyf, off = [], [], 0
	for n in FIT["src"] + ["body_pants"]:
		v, f = POSED[n]
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
	groups = {}
	rest = np.empty_like(co)
	for i, p in enumerate(co):
		near = kd.find_n(Vector(p), 6)
		acc = {}
		for _, j, dist in near:
			for b, w in ws[j].items():
				acc[b] = acc.get(b, 0.0) + w / (dist + 0.004)
		top = sorted(acc.items(), key=lambda kv: -kv[1])[:4]
		tot = sum(w for _, w in top) or 1.0
		M = Matrix(((0, 0, 0, 0),) * 4)
		for b, w in top:
			if b not in groups:
				groups[b] = A.vertex_groups.new(name=b)
			groups[b].add([i], w / tot, "REPLACE")
			M = M + SKIN[b] * (w / tot)
		rest[i] = np.array(M.inverted() @ Vector(p))
	# back to his arms-out pose (the game binds the armour there)
	A.data.vertices.foreach_set("co", rest.ravel())
	A.data.update()
	pose_arms(0)
	A.parent = ARM
	A.parent_type = "OBJECT"
	A.matrix_parent_inverse = ARM.matrix_world.inverted()
	A.modifiers.new("skeleton", "ARMATURE").object = ARM
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
	pose_arms(65)
	if HAIR:  # (the game hides his own head under a helmet and shows the hat-hair one)
		BODYM["body_head"].hide_render = True
	sc = bpy.context.scene
	sc.render.engine = "BLENDER_WORKBENCH"
	sc.display.shading.light = "STUDIO"
	sc.display.shading.color_type = "VERTEX" if A.data.color_attributes else "MATERIAL"
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
GAME = OPT.get("game") == "1"
GFACES = {"chest": 5000, "helm": 4000}
GSIZE = {"chest": 2048, "helm": 1024}
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
	cs.uv_only(low)
	# the dense model glows its painted colour for the colour bake
	em = bpy.data.materials.new("bake_src")
	em.use_nodes = True
	ent = em.node_tree
	ent.nodes.remove(ent.nodes["Principled BSDF"])
	emi = ent.nodes.new("ShaderNodeEmission")
	vc = ent.nodes.new("ShaderNodeVertexColor")
	vc.layer_name = "Col"
	ent.links.new(vc.outputs["Color"], emi.inputs["Color"])
	ent.links.new(emi.outputs["Emission"], ent.nodes["Material Output"].inputs["Surface"])
	A.data.materials.clear()
	A.data.materials.append(em)
	# the pictures' copper is pale and pink next to the hand-built pieces: deeper and warmer (same for helmet + chest)
	ca = A.data.color_attributes["Col"]
	rgba = np.empty(len(ca.data) * 4)
	ca.data.foreach_get("color", rgba)
	rgba = rgba.reshape(-1, 4)
	rgba[:, :3] = np.clip(rgba[:, :3] ** 1.25 * np.array(OPT.get("warm", (1.0, 0.78, 0.62))), 0, 1)
	ca.data.foreach_set("color", rgba.ravel())
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
for o in list(BODYM.values()):
	bpy.data.objects.remove(o, do_unlink=True)
bpy.ops.object.select_all(action="DESELECT")
ARM.select_set(True)
A.select_set(True)
if HAIR:
	HAIR.select_set(True)
if not A.data.uv_layers:
	A.data.uv_layers.new(name="UVMap")
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_yup=True, export_skins=True,
	export_animations=False, export_apply=False, **({"export_image_format": "JPEG", "export_image_quality": 88} if GAME else {}))
if GAME:
	import glb_jpeg_fix  # noqa: E402  (Godot shows Blender's JPEG pictures white without it: F164)
	glb_jpeg_fix.fix(OUT)
log("DONE", OUT, len(A.data.polygons), "faces")
