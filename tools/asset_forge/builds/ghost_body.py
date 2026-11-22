# The dungeon ghosts' bodies, hand-built round the dwarf's own skeleton (Claude, Nov 22, 2026; MODEL-RULES Rule 1).
#
#   blender --background --factory-startup --python tools/asset_forge/builds/ghost_body.py -- <a|b|c> <out.glb> [review=<pic.png>]
#
# Owner, Nov 22: a ghost that moves with the dwarf's skeleton and his mace moves (not the pack skeleton's moves).
# Reference: docs/art/creatures/ghost_concepts_v1.png (three ChatGPT pictures; the owner: "you do one, you copy, and
# then you adjust some details"). One body, three small changes:
#   a  (left picture)   a round hood, calm and plain.
#   b  (middle picture) a tall pointed hood and a short shoulder cape: the angry one.
#   c  (right picture)  a misty beard out of the hood and a ragged hem with hanging tatters (the boss wears this one too).
#
# The shape: a loose hood with a dark hollow for the face and two glowing eyes in it, broad shoulders, thick sleeves,
# chunky fists, and no legs: the robe narrows into a misty tail that curls back behind it (no feet, so no sliding feet,
# F577). It is sculpted as one clay shape on a grid (like the armor), with a little hand-made wobble.
#
# How it moves: the dwarf's body (assets/characters/dwarf/dwarf_body.glb) is loaded for its skeleton and its rest pose
# (arms out). Every ghost point copies the bones of the body point nearest to it (sleeves bend with his arms, the chest
# with his spine), the hood follows his head, the fists his hands, and the tail only his hips (his legs still walk under
# it in the game, hidden; the tail must not kick along). The game wears it like the armor (Ghost.build_model).
#
# Colours are only a guide here: the game paints it with its ghost shader (src/art/ghost.gdshader). The points carry a
# colour the shader reads: red = how lit (the face hollow is dark), green = how far down the misty tail (fades out).
import math
import random
import sys
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector, kdtree

HERE = Path(__file__).resolve()
sys.path.insert(0, str(HERE.parents[1]))
sys.path.insert(0, str(HERE.parent))
import creature_kit as ck  # noqa: E402
import creature_sculpt as cs  # noqa: E402
import dwarf_head as dh  # noqa: E402
import kit  # noqa: E402

ROOT = HERE.parents[3]
ARGS = sys.argv[sys.argv.index("--") + 1:]
LOOK, OUT = ARGS[0], ARGS[1]
REVIEW = next((a[7:] for a in ARGS[2:] if a.startswith("review=")), None)
BODY = ROOT / "assets" / "characters" / "dwarf" / "dwarf_body.glb"
NAME = "ghost_" + LOOK  # ghost_a, ghost_b, ghost_c
R = random.Random({"a": 11, "b": 12, "c": 13}[LOOK])

# ---------------------------------------------------------------- the dwarf's skeleton (Blender: x = his left, -y = front, z up)
ck.reset()
for o in list(bpy.data.objects):
	bpy.data.objects.remove(o, do_unlink=True)
bpy.ops.import_scene.gltf(filepath=str(BODY))
ARM = next(o for o in bpy.context.scene.objects if o.type == "ARMATURE")
BODYM = {o.name: o for o in bpy.context.scene.objects if o.type == "MESH" and o.name.startswith("body_")}
for o in [o for o in bpy.context.scene.objects if o.type == "MESH" and not o.name.startswith("body_")]:
	bpy.data.objects.remove(o, do_unlink=True)


def world_verts(o):
	co = np.empty(len(o.data.vertices) * 3)
	o.data.vertices.foreach_get("co", co)
	co = co.reshape(-1, 3)
	m = np.array(o.matrix_world)
	return co @ m[:3, :3].T + m[:3, 3]


# ---------------------------------------------------------------- clay on a grid (distances: negative inside)
H = 0.009
LO = np.array((-0.97, -0.5, 0.0))
HI = np.array((0.97, 0.62, 1.5))
N = np.ceil((HI - LO) / H).astype(int) + 1
AX = [(LO[i] + H * np.arange(N[i])).astype(np.float32) for i in range(3)]
X, Y, Z = np.meshgrid(*AX, indexing="ij")


def smin(a, b, k):
	return dh._smin(a, b, k)


def smax(a, b, k):
	return -dh._smin(-a, -b, k)


def ell(c, r):
	"""A squashed ball (close enough to a true distance near its surface)."""
	x, y, z = (X - c[0]) / r[0], (Y - c[1]) / r[1], (Z - c[2]) / r[2]
	return (np.sqrt(x * x + y * y + z * z) - 1.0) * min(r)


def tube(a, b, r0, r1, sx=1.0):
	"""A tapered rod from a to b (radius r0 to r1); sx > 1 makes it wider side to side."""
	a, b = np.array(a, np.float32), np.array(b, np.float32)
	ba = b - a
	px, py, pz = (X - a[0]) / sx, Y - a[1], Z - a[2]
	bx = ba[0] / sx
	t = np.clip((px * bx + py * ba[1] + pz * ba[2]) / float(bx * bx + ba[1] ** 2 + ba[2] ** 2), 0.0, 1.0)
	d = np.sqrt((px - bx * t) ** 2 + (py - ba[1] * t) ** 2 + (pz - ba[2] * t) ** 2)
	return d - (r0 + (r1 - r0) * t)


def wobble(amp, seed):
	"""A hand-made unevenness (a few slow waves): no part is perfectly even."""
	r = random.Random(seed)
	w = np.zeros_like(X)
	for _ in range(4):
		k = [r.uniform(8, 20) for _ in range(3)]
		ph = [r.uniform(0, 6.3) for _ in range(3)]
		w += np.sin(k[0] * X + ph[0]) * np.sin(k[1] * Y + ph[1]) * np.sin(k[2] * Z + ph[2])
	return (amp / 2.0) * w


def to_mesh(name, D, mat, min_island=40):
	D = D.copy()
	for ax in range(3):  # closed off where it reaches the grid's edge
		sl = [slice(None)] * 3
		for end in (0, -1):
			sl[ax] = end
			D[tuple(sl)] = np.maximum(D[tuple(sl)], H)
	v, q = dh.surface_nets(D, LO, H)
	o = kit._mesh_obj(name, v.tolist(), q.tolist(), mat)
	ck._fix_normals(o)
	small = [i for isl in cs.islands(o) if len(isl) < min_island for i in isl]
	if small:
		bm = bmesh.new()
		bm.from_mesh(o.data)
		bm.verts.ensure_lookup_table()
		bmesh.ops.delete(bm, geom=[bm.verts[i] for i in small], context="VERTS")
		bm.to_mesh(o.data)
		bm.free()
	return o


HEAD_C = (0.0, 0.04, 1.06)   # the hood's middle (his head is inside it)
FACE_C = (0.0, -0.235, 1.03)  # the hollow where his face would be
SHOULDER_Z = 0.78
HAND_X = 0.66  # where his sleeves end (wrist)

# The hood: a big soft egg round his head, the face hollow cut into its front.
hood = ell(HEAD_C, (0.265, 0.285, 0.25))
if LOOK == "b":  # a tall pointed hood, leaning forward a little (the angry one)
	hood = smin(hood, tube((0, 0.05, 1.18), (0, 0.10, 1.43), 0.15, 0.018), 0.06)
else:  # a soft fold hanging down the back of the hood
	hood = smin(hood, tube((0, 0.12, 1.16), (0, 0.27, 1.08), 0.11, 0.03), 0.05)
hood = smin(hood, ell((0, 0.04, 0.86), (0.25, 0.25, 0.11)), 0.06)  # it falls onto the shoulders
face = ell(FACE_C, (0.155, 0.15, 0.165))
hood = smax(hood, -face, 0.025)

# The chest and the broad shoulders: a chunky barrel, wider than the dwarf.
chest = ell((0, 0.03, 0.66), (0.34, 0.26, 0.22))
for s in (-1, 1):
	chest = smin(chest, ell((s * 0.29, 0.035, SHOULDER_Z), (0.16, 0.15, 0.14)), 0.06)
if LOOK == "b":  # a short shoulder cape
	chest = smin(chest, ell((0, 0.04, 0.80), (0.46, 0.33, 0.085)), 0.04)
body = smin(hood, chest, 0.07)

# The sleeves: thick, a little flared at the wrist.
for s in (-1, 1):
	sl = tube((s * 0.3, 0.035, SHOULDER_Z), (s * (HAND_X - 0.04), 0.035, 0.778), 0.12, 0.098)
	sl = smin(sl, tube((s * (HAND_X - 0.1), 0.035, 0.778), (s * HAND_X, 0.035, 0.778), 0.1, 0.128), 0.03)
	body = smin(body, sl, 0.04)

# The misty tail: from the waist it narrows and curls back behind (no legs), a few twists of mist along it.
tail_pts = []
for i in range(13):
	t = i / 12.0
	tail_pts.append((0.03 * math.sin(t * 5.0), 0.03 + 0.48 * t ** 2.2, 0.50 - 0.46 * t ** 0.8 + 0.10 * t ** 4))
for i in range(12):
	r0 = 0.27 * (1.0 - i / 12.0) ** 1.25 + 0.01
	r1 = 0.27 * (1.0 - (i + 1) / 12.0) ** 1.25 + 0.01
	body = smin(body, tube(tail_pts[i], tail_pts[i + 1], r0, r1, sx=1.12), 0.05)
# twists of mist round the tail: shallow grooves winding down it
twist = np.sin(np.arctan2(X, Y - 0.1) * 3.0 + Z * 16.0)
body = body + np.where(Z < 0.5, 0.006 * twist * np.clip((0.5 - Z) / 0.15, 0, 1), 0.0)

if LOOK == "c":
	# A misty beard flowing out of the hood, down over the chest.
	beard = tube((0, -0.17, 0.92), (0, -0.25, 0.66), 0.10, 0.045, sx=1.7)
	beard = smin(beard, tube((0, -0.25, 0.66), (0, -0.23, 0.55), 0.045, 0.015, sx=1.4), 0.03)
	beard = beard + 0.006 * np.sin(X * 90.0 + Z * 12.0)  # combed strands
	body = smin(body, beard, 0.035)
	# Ragged tatters hanging from the waist and the wrists, and notches torn out of the robe's edge.
	for k in range(8):
		a = k / 8.0 * math.tau + R.uniform(-0.2, 0.2)
		top = (math.sin(a) * 0.31, 0.03 + math.cos(a) * 0.25, 0.47)
		bot = (math.sin(a) * 0.33, 0.05 + math.cos(a) * 0.27, 0.47 - R.uniform(0.13, 0.2))
		body = smin(body, tube(top, bot, 0.06, 0.028, sx=1.0), 0.04)
	for s in (-1, 1):
		for dz in (0.0, 0.05):
			body = smin(body, tube((s * (HAND_X - 0.04), 0.06 + dz, 0.70), (s * (HAND_X - 0.06), 0.08 + dz, 0.61), 0.04, 0.02), 0.025)

body = body + wobble(0.007, R.randint(0, 999))
MAT_BODY = ck.color(NAME + "_body", (0.55, 0.85, 0.8) if LOOK != "b" else (0.6, 0.75, 0.95))
o_body = to_mesh(NAME + "_body", body, MAT_BODY)

# The eyes: two glowing lumps set into the back of the face hollow (they sink into the hood: they touch it).
eyes = np.minimum(ell((-0.062, -0.087 - 0.0, 1.045), (0.034, 0.02, 0.022)), ell((0.062, -0.087, 1.045), (0.034, 0.02, 0.022)))
if LOOK == "b":  # angry: slanted, narrower
	eyes = np.minimum(ell((-0.062, -0.087, 1.04), (0.036, 0.02, 0.016)), ell((0.062, -0.087, 1.04), (0.036, 0.02, 0.016)))
o_eyes = to_mesh(NAME + "_eyes", eyes, ck.color(NAME + "_eyes", (1.0, 1.0, 0.85)), min_island=8)

# The fists: chunky, closed (the mace handle goes through the right one), a ridge of knuckles on top.
fists = None
for s in (-1, 1):
	f = ell((s * (HAND_X + 0.08), 0.005, 0.766), (0.09, 0.085, 0.078))
	f = smin(f, tube((s * (HAND_X + 0.04), -0.06, 0.80), (s * (HAND_X + 0.12), -0.06, 0.80), 0.03, 0.028), 0.03)
	f = smin(f, tube((s * (HAND_X + 0.02), 0.02, 0.775), (s * (HAND_X + 0.05), 0.02, 0.775), 0.075, 0.08), 0.02)  # wrist into the cuff
	fists = f if fists is None else np.minimum(fists, f)
fists = fists + wobble(0.004, 77)
o_fists = to_mesh(NAME + "_fists", fists, ck.color(NAME + "_fists", (0.6, 0.9, 0.85)), min_island=8)

# ---------------------------------------------------------------- the shader's guide colours (red = lit, green = mist)
for o in (o_body, o_eyes, o_fists):
	co = world_verts(o)
	fx = (co[:, 0] - FACE_C[0]) / 0.155
	fy = (co[:, 1] - FACE_C[1]) / 0.15
	fz = (co[:, 2] - FACE_C[2]) / 0.165
	in_face = np.sqrt(fx * fx + fy * fy + fz * fz)
	lit = np.clip((in_face - 1.0) / 0.12, 0.0, 1.0) if o is o_body else np.ones(len(co))
	lit = 0.08 + 0.92 * lit
	mist = np.clip((0.5 - co[:, 2]) / 0.44, 0.0, 1.0) if o is o_body else np.zeros(len(co))
	if o is o_eyes:
		mist[:] = 0.0
	rgb = np.stack([lit, mist, np.full(len(co), 1.0 if o is o_eyes else 0.0)], 1)
	at = o.data.color_attributes.new("guide", "FLOAT_COLOR", "POINT")
	at.data.foreach_set("color", np.concatenate([rgb, np.ones((len(rgb), 1))], 1).ravel())
	o.data.color_attributes.active_color = at
	o.data.uv_layers.new(name="UVMap")
	for p in o.data.polygons:
		p.use_smooth = True
	# fewer faces: the game's light copy
	n = len(o.data.polygons)
	want = {o_body: 7000, o_eyes: 300, o_fists: 900}[o]
	if n > want:
		md = o.modifiers.new("fewer", "DECIMATE")
		md.ratio = want / n
		cs._apply_all(o)
	print("GHOST made", o.name, len(o.data.polygons), "faces", flush=True)

# ---------------------------------------------------------------- which bones move each point
SKIP = ("hair_", "cloth_")
LEGS = ("thigh_", "calf_", "foot_", "ball_")  # his legs: their pull goes to the hips (the tail must not walk)
FINGERS = ("thumb_", "index_", "middle_", "ring_", "pinky_")  # the cuffs follow the wrist, not the fingers
pts, ws = [], []
for n in ("body_torso", "body_shirt", "body_hand_l", "body_hand_r"):
	ob = BODYM[n]
	gn = {vg.index: vg.name for vg in ob.vertex_groups}
	for v, p in zip(ob.data.vertices, world_verts(ob)):
		w = {}
		for g in v.groups:
			k = gn[g.group]
			if g.weight <= 0.0 or k.startswith(SKIP):
				continue
			if k.startswith(LEGS):
				k = "pelvis"
			elif k.startswith(FINGERS):
				k = "hand_" + k[-1]
			w[k] = w.get(k, 0.0) + g.weight
		if w:
			pts.append(p)
			ws.append(w)
KD = kdtree.KDTree(len(pts))
for i, p in enumerate(pts):
	KD.insert(Vector(p), i)
KD.balance()


def mix(a, b, t):
	out = {k: v * (1.0 - t) for k, v in a.items()}
	for k, v in b.items():
		out[k] = out.get(k, 0.0) + v * t
	return out


def weights_for(o, p):
	x, y, z = p
	if o is o_eyes:
		return {"Head": 1.0}
	if o is o_fists:
		return {"hand_l" if x > 0 else "hand_r": 1.0}
	near = ws[KD.find(Vector(p))[1]]
	dh_ = math.dist(p, HEAD_C)
	if (z > 0.9 and abs(x) < 0.32) or (LOOK == "c" and abs(x) < 0.16 and y < -0.12 and z > 0.5):  # the hood (and the beard) follow his head
		return {"Head": 1.0}
	if z > 0.83 and abs(x) < 0.27:  # hood falling onto the shoulders: half head, half spine
		return mix(near, {"Head": 1.0}, float(np.clip((z - 0.83) / 0.07, 0, 1)) * (1.0 if dh_ < 0.4 else 0.5))
	if z < 0.56 and abs(x) < 0.45:  # the tail: only the hips (his walking legs are hidden under it)
		t = float(np.clip((0.56 - z) / 0.1, 0, 1))
		return mix(near, {"pelvis": 1.0}, t)
	return near


for o in (o_body, o_eyes, o_fists):
	for vg in list(o.vertex_groups):
		o.vertex_groups.remove(vg)
	groups = {}
	for i, p in enumerate(world_verts(o)):
		w = weights_for(o, tuple(p))
		top = sorted(w.items(), key=lambda kv: -kv[1])[:4]
		tot = sum(v for _, v in top) or 1.0
		for name, v in top:
			if name not in groups:
				groups[name] = o.vertex_groups.new(name=name)
			groups[name].add([i], v / tot, "REPLACE")
	o.parent = ARM
	o.parent_type = "OBJECT"
	o.matrix_parent_inverse = ARM.matrix_world.inverted()
	o.modifiers.new("skeleton", "ARMATURE").object = ARM
print("GHOST weights copied from the body", flush=True)

# ---------------------------------------------------------------- photos: arms down like the game (review only)
if REVIEW:
	scene = bpy.context.scene
	for ob in scene.objects:
		ob.hide_render = ob not in (o_body, o_eyes, o_fists)
	for ob in (o_body, o_eyes, o_fists):
		m = ob.active_material
		bsdf = next((n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None) if m.use_nodes else None
		if bsdf:
			m.diffuse_color = tuple(bsdf.inputs["Base Color"].default_value)
	bpy.context.view_layer.objects.active = ARM
	bpy.ops.object.mode_set(mode="POSE")
	for side in ("l", "r"):
		pb = ARM.pose.bones[f"upperarm_{side}"]
		h = pb.head.copy()
		rot = Matrix.Translation(h) @ Matrix.Rotation(math.radians(60) * (1 if pb.head.x > 0 else -1), 4, "Y") @ Matrix.Translation(-h)
		pb.matrix = rot @ pb.matrix
	bpy.ops.object.mode_set(mode="OBJECT")
	bpy.context.view_layer.update()
	scene.render.engine = "BLENDER_WORKBENCH"
	scene.display.shading.light = "STUDIO"
	scene.display.shading.color_type = "MATERIAL"
	scene.render.resolution_x, scene.render.resolution_y = 520, 620
	cam = bpy.data.objects.new("rcam", bpy.data.cameras.new("rcam"))
	cam.data.type = "ORTHO"
	scene.collection.objects.link(cam)
	scene.camera = cam
	for tag, loc in (("front", (0, -4, 0.72)), ("side", (-4, 0, 0.72)), ("back", (2.8, 2.8, 0.9))):
		cam.location = Vector(loc)
		cam.data.ortho_scale = 1.65
		cam.rotation_euler = (Vector((0, 0, 0.72)) - cam.location).to_track_quat("-Z", "Y").to_euler()
		scene.render.filepath = str(Path(REVIEW).with_name(Path(REVIEW).stem + f"_{tag}.png"))
		bpy.ops.render.render(write_still=True)
	for pb in ARM.pose.bones:
		pb.matrix_basis = Matrix()
	bpy.context.view_layer.update()
	print("GHOST REVIEW", REVIEW, flush=True)

# ---------------------------------------------------------------- export: the skeleton and the ghost only
for ob in list(BODYM.values()):
	bpy.data.objects.remove(ob, do_unlink=True)
for ob in [ob for ob in bpy.data.objects if ob.type == "MESH" and ob not in (o_body, o_eyes, o_fists)]:
	bpy.data.objects.remove(ob, do_unlink=True)  # the importer's bone shapes
bpy.ops.object.select_all(action="DESELECT")
ARM.select_set(True)
for o in (o_body, o_eyes, o_fists):
	o.select_set(True)
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_yup=True, export_skins=True,
	export_animations=False, export_apply=False, export_vertex_color="ACTIVE")
print("GHOST_DONE", OUT, flush=True)
