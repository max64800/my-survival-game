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
FIT = {"chest": dict(top=0.965, bottom=0.31, src=["body_shirt", "body_torso", "body_shorts"], belly=(0.45, 0.72))}[PIECE]


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

mat = bpy.data.materials.new(f"armor_{PIECE}_plate")
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
	for tag, loc in (("front", (0, -4, 0.62)), ("side", (-4, 0, 0.62)), ("back", (0, 4, 0.62)), ("q34", (2.8, -2.8, 0.9))):
		cam.location = Vector(loc)
		cam.data.ortho_scale = 1.34
		cam.rotation_euler = (Vector((0, 0, 0.62)) - cam.location).to_track_quat("-Z", "Y").to_euler()
		path = str(Path(REVIEW).with_name(Path(REVIEW).stem + f"_{tag}.png"))
		sc.render.filepath = path
		bpy.ops.render.render(write_still=True)
		shots.append(path)
	log("REVIEW", shots)
	pose_arms(0)

# ---------------------------------------------------------------- export: skeleton + armour only
for o in list(BODYM.values()):
	bpy.data.objects.remove(o, do_unlink=True)
bpy.ops.object.select_all(action="DESELECT")
ARM.select_set(True)
A.select_set(True)
if not A.data.uv_layers:
	A.data.uv_layers.new(name="UVMap")
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_yup=True, export_skins=True,
	export_animations=False, export_apply=False)
log("DONE", OUT, len(A.data.polygons), "faces")
