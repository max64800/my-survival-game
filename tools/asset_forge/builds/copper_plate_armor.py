# The copper armour's helmet and chest, HAND-BUILT as hard plates (F914 round 6, Claude, Nov 26, 2026).
# Owner chose this Nov 26: learn from the picture-made test (armor_picture3d.py, can't ship: Hunyuan licence), build it
# by hand to match the GPT pictures (C:/Users/<you>/ai3d/armor3d/chest + /helm). Owner on that test: "grey padding still
# shows under the armpits and at the neck; the shoulders, helmet and back need a way better texture".
#
#   blender --background --factory-startup --python tools/asset_forge/builds/copper_plate_armor.py -- <out.glb>
#       [review=<pic.png>] [angle=55]
#
# How it is built (no clay/voxel shapes: rounds 1-4 of the old way looked "like Play-Doh"):
#   * every plate is a thin sheet laid on him like a stiff sheet of metal: rays from inside him find his surface,
#     the sheet rests on the highest bumps (smoothed, never dipping in), then gets real thickness (solidify) and a
#     small polished bevel on every edge. Straight clean edges, no dents in the shape.
#   * every plate has a raised polished border (a step up near its edge), the middle carries the hammered-copper
#     picture (tools/art/make_hammered_copper.py) at its real size, each plate at its own spot of the picture.
#   * rivets: domed heads on the borders. Layers overlap like roof tiles (the upper plate always outside).
#   * the leather undercoat is a copy of his shirt (same bones), pushed 4 mm out and painted dark quilted leather;
#     the game hides the shirt while it's worn, so nothing grey or white can show at the neck or under the arms.
#   * helmet: one shell turned round his head (mirrored by construction), pointed top, flared neck guard, face open
#     below the eye plate so the beard comes out, two eye holes, a nasal bar, a riveted ridge band over the top and a
#     riveted brow band. On the Head bone, with the hat-hair head from the hand-built set.
#   * the chest is built with his arms bent down (angle), like the pictures, then bent back to arms-out (the game
#     binds there); each point copies the bones of the body points under it (skirt plates follow the hips and hem).
# Legs, boots and gauntlets stay from the hand-built set (armor_copper.glb, dwarf_armor.py; owner liked them).
import math
import sys
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector, kdtree
from mathutils.bvhtree import BVHTree

HERE = Path(__file__).resolve()
sys.path.insert(0, str(HERE.parents[1]))
ROOT = HERE.parents[3]
import creature_sculpt as cs  # noqa: E402

ARGS = sys.argv[sys.argv.index("--") + 1:]
OUT = ARGS[0]
OPT = dict(a.split("=", 1) for a in ARGS[1:] if "=" in a)
ANGLE = float(OPT.get("angle", 55))
BODY = ROOT / "assets" / "characters" / "dwarf" / "dwarf_body.glb"
TEXD = ROOT / "assets" / "textures" / "armor"
TILE = 0.32  # metres of armour one hammered picture covers (its real size: ~1.6 cm dents)
rng = np.random.default_rng(914)


def log(*a):
	print("PLATE", *a, flush=True)


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
		polys = [tuple(p.vertices) for p in o.data.polygons]
	m = np.array(o.matrix_world)
	return co @ m[:3, :3].T + m[:3, 3], polys


# ---------------------------------------------------------------- the body
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(BODY))
ARM = next(o for o in bpy.context.scene.objects if o.type == "ARMATURE")
BODYM = {o.name: o for o in bpy.context.scene.objects if o.type == "MESH" and o.name.startswith("body_")}
for o in [o for o in bpy.context.scene.objects if o.type == "MESH" and not o.name.startswith("body_")]:
	bpy.data.objects.remove(o, do_unlink=True)
for o in BODYM.values():
	if not any(m.type == "ARMATURE" for m in o.modifiers):
		o.modifiers.new("skeleton", "ARMATURE").object = ARM
ARMBONES = ("upperarm", "lowerarm", "hand", "index", "middle", "ring", "pinky", "thumb")


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


def arm_weight(o):
	"""How much of each point moves with his arms (0 = body, 1 = arm)."""
	gn = {vg.index: vg.name for vg in o.vertex_groups}
	w = np.zeros(len(o.data.vertices))
	for v in o.data.vertices:
		for g in v.groups:
			if gn[g.group].startswith(ARMBONES):
				w[v.index] += g.weight
	return w


pose_arms(ANGLE)
DG = bpy.context.evaluated_depsgraph_get()
POSED = {n: verts(o, DG) for n, o in BODYM.items()}
AW = {n: arm_weight(BODYM[n]) for n in ("body_shirt", "body_torso", "body_shorts", "body_pants")}


def bvh_of(names, keep=None):
	"""One ray target from body parts (posed); keep(name, face points, face arm weight) picks faces."""
	P, F, off = [], [], 0
	for n in names:
		co, polys = POSED[n]
		for f in polys:
			if keep is None or keep(n, co[list(f)], AW[n][list(f)].mean() if n in AW else 0.0):
				F.append(tuple(i + off for i in f))
		P.append(co)
		off += len(co)
	return BVHTree.FromPolygons([Vector(p) for p in np.vstack(P)], F)


TORSO = bvh_of(["body_shirt", "body_torso", "body_shorts", "body_pants"], lambda n, q, aw: aw < 0.35)
ARMS = bvh_of(["body_shirt", "body_torso"], lambda n, q, aw: True)
log("body posed, arms down", ANGLE)

# his middle line (y) at each height: the round shapes are laid out round it
shirt = np.vstack([POSED[n][0] for n in ("body_shirt", "body_shorts", "body_torso")])
ZS = np.linspace(0.25, 1.0, 76)
AY = np.array([(s[:, 1].min() + s[:, 1].max()) / 2 if len(s) > 4 else np.nan for s in  # (halfway front-back)
	(shirt[(np.abs(shirt[:, 2] - z) < 0.02) & (np.abs(shirt[:, 0]) < 0.12)] for z in ZS)])
AY = np.interp(ZS, ZS[~np.isnan(AY)], AY[~np.isnan(AY)])


def axis_y(z):
	return np.interp(np.asarray(z, float), ZS, AY)


# ---------------------------------------------------------------- materials
def image(name, path, colour=True):
	img = bpy.data.images.load(str(path))
	img.name = name
	if not colour:
		img.colorspace_settings.name = "Non-Color"
	return img


HAM_COL = image("copper_hammered_col", TEXD / "copper_hammered_col.png")
HAM_NRM = image("copper_hammered_nrm", TEXD / "copper_hammered_nrm.png", False)


def material(name, rgb, metal, rough, col_img=None, nrm_img=None, nrm=1.0):
	m = bpy.data.materials.new(name)
	m.use_nodes = True
	nt = m.node_tree
	b = nt.nodes["Principled BSDF"]
	b.inputs["Base Color"].default_value = (*rgb, 1)
	b.inputs["Metallic"].default_value = metal
	b.inputs["Roughness"].default_value = rough
	if col_img:
		t = nt.nodes.new("ShaderNodeTexImage")
		t.image = col_img
		nt.links.new(t.outputs["Color"], b.inputs["Base Color"])
		nt.nodes.active = t
	if nrm_img:
		t = nt.nodes.new("ShaderNodeTexImage")
		t.image = nrm_img
		nm = nt.nodes.new("ShaderNodeNormalMap")
		nm.inputs["Strength"].default_value = nrm
		nt.links.new(t.outputs["Color"], nm.inputs["Color"])
		nt.links.new(nm.outputs["Normal"], b.inputs["Normal"])
	return m


M_HAM = material("copper_hammered", (0.75, 0.38, 0.2), 0.8, 0.36, HAM_COL, HAM_NRM, 0.9)
M_POL = material("copper_polished", (0.8, 0.33, 0.14), 0.78, 0.3)  # (the raised borders and edges, rubbed bright)
# (round 6 had (0.86, 0.47, 0.27), metal 0.9: in the game it mirrored the grey room and showed silver; the picture's are copper)
M_RIV = material("copper_rivet", (0.7, 0.3, 0.13), 0.8, 0.3)
QUILT = TEXD / "hide2_quilted.png"
M_LEA = material("leather_dark", (0.03, 0.018, 0.011), 0.0, 1.0)  # (linear colour: 0.17 showed light grey-brown)  # (plain: his shirt's picture layout made blotches)
BELT = TEXD / "hide2_belt.png"
M_BELT = material("leather_belt", (0.33, 0.2, 0.12), 0.0, 0.7, image("hide2_belt", BELT) if BELT.exists() else None)
# (leather pictures darkened: the undercoat reads as deep shadow between the plates, like the picture)
for m, k in ((M_LEA, 0.45), (M_BELT, 0.75)):
	nt = m.node_tree
	t = next((n for n in nt.nodes if n.type == "TEX_IMAGE"), None)
	if t:
		mix = nt.nodes.new("ShaderNodeMix")
		mix.data_type = "RGBA"
		mix.blend_type = "MULTIPLY"
		mix.inputs["Factor"].default_value = 1.0
		mix.inputs[7].default_value = (k, k * 0.8, k * 0.7, 1)
		nt.links.new(t.outputs["Color"], mix.inputs[6])
		nt.links.new(mix.outputs[2], nt.nodes["Principled BSDF"].inputs["Base Color"])


# ---------------------------------------------------------------- shapes
PARTS = {}  # object name -> list of (points, faces, uvs, material per face)
RIVETS = {}  # object name -> list of (point, outward)


def add(group, P, F, UV, MI):
	PARTS.setdefault(group, []).append((np.asarray(P, float), F, np.asarray(UV, float), MI))


def lay(origins, dirs, target, off, far=0.45, fill=None):
	"""Where rays from far out along dirs, coming back towards origins, first meet target (distance from origin)."""
	sh = origins.shape[:-1]
	o2, d2 = origins.reshape(-1, 3), dirs.reshape(-1, 3)
	out = np.full(len(o2), np.nan)
	for i, (o, d) in enumerate(zip(o2, d2)):
		hit = target.ray_cast(Vector(o + d * far), Vector(-d), far)
		if hit[0] is not None:
			out[i] = (Vector(hit[0]) - Vector(o)).dot(Vector(d))
	out = out.reshape(sh)
	if np.all(np.isnan(out)):
		out[:] = fill if fill is not None else 0.1
	return np.where(np.isnan(out), np.nanmax(out), out)


def stiffen(D, ring=True, passes=(3, 8), lift=0.0015):
	"""A stiff sheet: rests on the highest bumps under it, then smoothed, never below the surface (+ lift)."""
	d0 = D.copy()

	def up(A):
		return np.vstack([A[1:], A[-1:]])

	def dn(A):
		return np.vstack([A[:1], A[:-1]])

	for _ in range(passes[0]):
		D = np.maximum.reduce([D, np.roll(D, 1, 1), np.roll(D, -1, 1), up(D), dn(D)])
	for _ in range(passes[1]):
		D = np.maximum((D * 2 + np.roll(D, 1, 1) + np.roll(D, -1, 1) + up(D) + dn(D)) / 6, d0 + lift)
	return D


def plate(group, ray, hw, hh, *, off=0.016, border=0.009, step=0.0022, dome=0.002, pexp=5.0, point=0.0,
		target=None, flat=None, rivets=(45, 135, 225, 315), riv_size=0.0055, hole=0.0, keep_min=None, stiff=(3, 8), rigid=False):
	"""One plate: a rounded rectangle hw x hh (half sizes, metres) laid on target along ray(U, V) -> (origin, dir).
	point: how far its bottom edge dips in the middle (a pointed lower edge, like the picture's breastplate and skirt).
	flat: (z_top, flare) for skirt plates: one straight cone (doesn't follow his legs), flaring out going down.
	Returns the plate's top-surface points function for extra parts."""
	ts = 1.0 - border / min(hw, hh)
	T = sorted(set([0.0, 0.18, 0.34, 0.48, 0.6, 0.7, 0.78, ts - 0.05, ts - 0.004, ts + 0.004, (ts + 1) / 2, 1.0]))
	T = np.array([t for t in T if t >= hole])
	NSP = 64
	psi = np.linspace(0, 2 * np.pi, NSP, endpoint=False)
	rb = 1 / ((np.abs(np.cos(psi)) / hw) ** pexp + (np.abs(np.sin(psi)) / hh) ** pexp) ** (1 / pexp)
	U = T[:, None] * rb * np.cos(psi)
	V = T[:, None] * rb * np.sin(psi)
	if point:
		V = V - point * np.clip(1 - np.abs(U) / hw, 0, 1) * np.clip(-V / hh, 0, 1)
	O, Dr = ray(U, V)
	D = lay(O, Dr, target or TORSO, off)
	if flat:
		D = np.full_like(D, np.percentile(D, 85)) + flat[1] * np.clip(flat[0] - O[..., 2], 0, None)
	elif rigid:
		# (round 8: one smooth curved sheet resting on his highest points; following his muscles left dents, owner)
		B = np.stack([np.ones_like(U), U, V, U * U, U * V, V * V], -1).reshape(-1, 6)
		c, *_ = np.linalg.lstsq(B, D.ravel(), rcond=None)
		fit = (B @ c).reshape(D.shape)
		D = fit + np.percentile(D - fit, 99.5)
	else:
		D = stiffen(D, passes=stiff)
	if keep_min is not None:
		D = np.maximum(D, keep_min)
	t = T[:, None] * np.ones((1, NSP))
	h = dome * (1 - t * t) + np.where(t >= ts, step, 0.0)
	P = O + Dr * (D + off + h)[..., None]
	uo = rng.uniform(0, TILE, 2)
	UVs = np.stack([(U + uo[0]) / TILE, (V + uo[1]) / TILE], -1)
	F, MI = [], []
	start = 0
	if T[0] == 0.0:
		F += [(0, NSP + (j + 1) % NSP, NSP + j) for j in range(NSP)]
		MI += [0] * NSP
		start = 1
	for i in range(start, len(T) - 1):
		pol = 1 if T[i] >= ts - 0.005 else 0
		F += [(i * NSP + j, i * NSP + (j + 1) % NSP, (i + 1) * NSP + (j + 1) % NSP, (i + 1) * NSP + j) for j in range(NSP)]
		MI += [pol] * NSP
	add(group, P.reshape(-1, 3), F, UVs.reshape(-1, 2), MI)
	if rivets:
		tr = 1.0 - border * 0.5 / min(hw, hh)
		for a in rivets:
			a = math.radians(a)
			r_ = 1 / ((abs(math.cos(a)) / hw) ** pexp + (abs(math.sin(a)) / hh) ** pexp) ** (1 / pexp) * tr
			u, v = np.array([[r_ * math.cos(a)]]), np.array([[r_ * math.sin(a)]])
			if point:
				v = v - point * np.clip(1 - np.abs(u) / hw, 0, 1) * np.clip(-v / hh, 0, 1)
			o, d = ray(u, v)
			dd = lay(o, d, target or TORSO, off)
			if flat:
				dd = np.full_like(dd, np.percentile(D - flat[1] * np.clip(flat[0] - O[..., 2], 0, None), 50))
				dd = dd + flat[1] * np.clip(flat[0] - o[..., 2], 0, None)
			else:
				dd = np.full_like(dd, D[np.unravel_index(np.argmin(np.abs(U - u[0, 0]) + np.abs(V - v[0, 0])), U.shape)])
			RIVETS.setdefault(group, []).append((o[0, 0] + d[0, 0] * (dd[0, 0] + off + step + 0.002), d[0, 0], riv_size))
	return P


def band(group, ray, length, hh, *, n=120, off=0.016, border=0.007, step=0.002, target=None, mat_mid=0, rivet_every=0.0,
		riv_size=0.0055, fixed=None, closed=True):
	"""A strip all round something (belt, collar, helmet bands): ray(S, V) with S = 0..length along it."""
	ts = 1.0 - border / hh
	T = np.array(sorted(set([-1.0, -(ts + 1) / 2, -ts - 0.004, -ts + 0.004, -0.5, 0.0, 0.5, ts - 0.004, ts + 0.004, (ts + 1) / 2, 1.0])))
	S = np.linspace(0, length, n, endpoint=not closed)
	Sg, Tg = np.meshgrid(S, T)
	V = Tg * hh
	O, Dr = ray(Sg, V)
	D = fixed if fixed is not None else stiffen(lay(O, Dr, target or TORSO, off), passes=(2, 6))
	h = np.where(np.abs(Tg) >= ts, step, 0.0)
	P = O + Dr * (D + off + h)[..., None]
	uo = rng.uniform(0, TILE, 2)
	UVs = np.stack([(Sg + uo[0]) / TILE, (V + uo[1]) / TILE], -1)
	F, MI = [], []
	m = n if closed else n - 1
	for i in range(len(T) - 1):
		pol = 1 if (abs(T[i]) >= ts - 0.005 and abs(T[i + 1]) >= ts - 0.005) or mat_mid == 1 else mat_mid
		pol = 1 if abs(T[i]) >= ts - 0.005 or abs(T[i + 1]) >= ts + 0.003 else mat_mid
		F += [(i * n + j, i * n + (j + 1) % n, (i + 1) * n + (j + 1) % n, (i + 1) * n + j) for j in range(m)]
		MI += [pol] * m
	add(group, P.reshape(-1, 3), F, UVs.reshape(-1, 2), MI)
	if rivet_every:
		mid = list(T).index(0.0)
		k = max(3, int(length / rivet_every))
		for j in np.linspace(0, n - 1, k, endpoint=not closed).astype(int):
			RIVETS.setdefault(group, []).append((P[mid, j] + Dr[mid, j] * 0.0015, Dr[mid, j], riv_size))
	return P


def torso_ray(phic, zc, ref):
	"""Rays out from his middle line: U = metres round him (phi 0 = his back, +x his left), V = metres up."""
	def ray(U, V):
		phi = phic + U / ref
		z = zc + V
		d = np.stack([np.sin(phi), np.cos(phi), np.zeros_like(phi)], -1)
		o = np.stack([np.zeros_like(phi), axis_y(z), z], -1)
		return o, d
	return ray


def ref_at(phi, z):
	o, d = torso_ray(phi, z, 0.2)(np.zeros((1, 1)), np.zeros((1, 1)))
	return float(lay(o, d, TORSO, 0)[0, 0])


# ================================================================ THE CHEST (arms bent down)
FRONT, BACK, LEFT = math.pi, 0.0, math.pi / 2
# cuirass: breastplate (pointed bottom, under the beard), backplate, side plates under the arms (tucked under both)
# (the back in two layers like the picture: a lower plate, and an upper plate over the shoulder blades outside it)
for phic, zc, hw, hh, pt, off, dm in ((FRONT, 0.735, 0.31, 0.172, 0.03, 0.018, 0.016),  # (round 7: wider, no leather beside it)
		(BACK, 0.75, 0.27, 0.185, 0.012, 0.018, 0.012)):  # (round 8: one back plate; two left a dent line, owner)
	ref = ref_at(phic, zc) + off
	plate("chest_plate", torso_ray(phic, zc, ref), hw, hh, off=off, point=pt, pexp=6, dome=dm, rigid=True,  # (round 7: domed like the picture's chest)
		rivets=(20, 160, 200, 340, 270, 90))
# side plates right up into the armpits (owner: no grey there; plate, not just dark)
for side in (1, -1):
	ref = ref_at(side * LEFT, 0.7) + 0.006  # (1.2 cm inside the front and back plates where they overlap)
	plate("chest_plate", torso_ray(side * LEFT, 0.7, ref), 0.13, 0.13, off=0.006, pexp=6, rivets=(90, 270), rigid=True)
# (Nov 26 try: a plate over each shoulder top stuck out like wings; the dark leather shows there instead)
log("cuirass")
# belt: dark leather with a copper buckle in front, riveted
ref = ref_at(BACK, 0.56)
band("chest_belt", lambda S, V: torso_ray(0.0, 0.56, 1.0)(S / 1.0 * 1.0, V), 2 * math.pi, 0.036, off=0.03, border=0.004,
	step=0.0012, mat_mid=2, rivet_every=0.6)
# (the ray above takes S as an angle: length 2 pi = all the way round)
bk = ref_at(FRONT, 0.56)
plate("chest_plate", torso_ray(FRONT, 0.56, bk + 0.04), 0.04, 0.034, off=0.04, border=0.012, step=0.0, pexp=4, hole=0.55,
	rivets=())
log("belt + buckle")
# skirt: three rows of tablets round his hips, each row outside the one below (roof tiles), flaring out
ROWS = [(0.535, 0.075), (0.475, 0.075), (0.415, 0.075)]  # (top of the row, height)
for k, (ztop, hgt) in enumerate(ROWS):
	zc = ztop - hgt / 2
	for j in range(6):
		phic = math.pi + j * math.pi / 3
		ref = ref_at(phic, ztop) + 0.02
		plate("chest_plate", torso_ray(phic, zc, ref), 0.135 * (1 + 0.04 * k), hgt / 2, off=0.022 + 0.01 * (j % 2),  # (wide: each overlaps its neighbours, 1 cm apart)
			
			point=0.012, pexp=6, flat=(ztop, 0.18), rivets=(150, 30), stiff=(2, 4))
log("skirt rows", len(ROWS))
# collar: a copper band round the base of his neck (over the leather undercoat's collar)
NECK = (0.875, 0.042)  # (round 7: the picture's thick collar)


def neck_ray(S, V):
	z = NECK[0] + V
	phi = S
	d = np.stack([np.sin(phi), np.cos(phi), np.full_like(phi, 0.25)], -1)
	d /= np.linalg.norm(d, axis=-1)[..., None]
	o = np.stack([np.zeros_like(phi), axis_y(z) + 0.02, z], -1)
	return o, d


band("chest_plate", neck_ray, 2 * math.pi, NECK[1], off=0.012, border=0.008, rivet_every=0.9)
log("collar")
# shoulders: a big cap over each shoulder, three lames down the upper arm (the upper always outside)
for side in (1, -1):
	S0 = np.array(ARM.matrix_world @ ARM.data.bones[f"upperarm_{'l' if side > 0 else 'r'}"].head_local)
	a = math.radians(ANGLE)
	Dv = np.array([side * math.cos(a), 0.0, -math.sin(a)])  # down the arm
	Up = np.array([side * math.sin(a), 0.0, math.cos(a)])   # up and out of the arm
	Fw = np.array([0.0, -1.0, 0.0])

	def arm_ray(along, Dv=Dv, Up=Up, S0=S0, rr=0.08):
		def ray(U, V):
			ang = U / rr
			o = S0 + Dv * (along - V)[..., None]
			d = np.cos(ang)[..., None] * Up + np.sin(ang)[..., None] * Fw * side
			return o, d
		return ray

	for k in range(3):
		along = 0.055 + 0.045 * k  # (round 8b: up under the roof's edge)
		plate("chest_plate", arm_ray(along), 0.12 - 0.008 * k, 0.034, target=ARMS, off=0.024 - 0.005 * k, pexp=6,
			point=0.0, dome=0.004, rivets=(160, 20), rigid=True)  # (round 8: stiff rings round the arm, stepping down)

	def cap_ray(U, V, S0=S0):
		# (round 8: the picture's shoulder plate: a curved roof over the shoulder, from the collar out over the arm;
		# U = front to back, V = round the roof from the neck side to the arm side. Round 7's dome had dents.)
		th = 0.52 + V / 0.12  # (round 8b: smaller, ends over the arm, not out like a wing)
		d = np.stack([side * np.sin(th), np.zeros_like(th), np.cos(th)], -1)
		o = np.stack([np.full_like(U, S0[0] - side * 0.03), S0[1] - U, np.full_like(U, S0[2] - 0.02)], -1)
		return o, d

	plate("chest_plate", cap_ray, 0.125, 0.1, target=ARMS, off=0.014, pexp=4, dome=0.008, rigid=True,
		rivets=(25, 155, 205, 335, 90))
log("shoulders")

# ---------------------------------------------------------------- beard over the plates: press the front back under it
hv, hf = POSED["body_head"]
HB = BVHTree.FromPolygons([Vector(p) for p in hv], hf)
SHIRT_BVH = bvh_of(["body_shirt", "body_torso"])


def beard_back(p):
	o = Vector((p[0], -1.0, p[2]))
	enter = HB.ray_cast(o, Vector((0, 1, 0)), 2.0)
	if enter[0] is None or enter[0].y > p[1] + 0.10:
		return None
	leave = HB.ray_cast(enter[0] + Vector((0, 1e-4, 0)), Vector((0, 1, 0)), 0.03)
	return enter[0].y + 0.03 if leave[0] is None else leave[0].y


def press_under_beard(P):
	moved = 0
	for i, p in enumerate(P):
		if p[2] > 0.95 or p[1] > 0.0 or p[2] < 0.5:
			continue
		by = beard_back(p)
		if by is not None and p[1] < by + 0.006:
			P[i, 1] = by + 0.006
			hit = SHIRT_BVH.find_nearest(Vector(P[i]))
			if hit[0] is not None and (Vector(P[i]) - hit[0]).dot(hit[1]) < 0.006:
				P[i] = np.array(hit[0] + hit[1] * 0.006)
			moved += 1
	return moved


# ================================================================ object making
def make(name, group, mats, thick=0.0038, bevel=0.0011, beard=False):
	P, F, UV, MI, off = [], [], [], [], 0
	for p, f, uv, mi in PARTS[group]:
		P.append(p)
		UV.append(uv)
		F += [tuple(i + off for i in q) for q in f]
		MI += mi
		off += len(p)
	P, UV = np.vstack(P), np.vstack(UV)
	me = bpy.data.meshes.new(name)
	me.from_pydata([tuple(p) for p in P], [], F)
	uvl = me.uv_layers.new(name="UVMap")
	loops = np.empty(len(me.loops), int)
	me.loops.foreach_get("vertex_index", loops)
	uvl.data.foreach_set("uv", UV[loops].ravel())
	for m in mats:
		me.materials.append(m)
	me.polygons.foreach_set("material_index", MI)
	o = bpy.data.objects.new(name, me)
	bpy.context.scene.collection.objects.link(o)
	bm = bmesh.new()
	bm.from_mesh(me)
	bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
	bm.to_mesh(me)
	bm.free()
	# (every sheet was laid out with its faces looking outward: solidify grows it inward)
	if thick:
		s = o.modifiers.new("thick", "SOLIDIFY")
		s.thickness, s.offset, s.use_even_offset, s.use_rim = thick, -1.0, True, True
		s.material_offset_rim = 1 if len(mats) > 1 else 0
		b = o.modifiers.new("edge", "BEVEL")
		b.width, b.segments, b.limit_method, b.angle_limit = bevel, 2, "ANGLE", math.radians(35)
		b.harden_normals = False
		cs._apply_all(o)
	if beard:
		co = np.empty(len(o.data.vertices) * 3)
		o.data.vertices.foreach_get("co", co)
		co = co.reshape(-1, 3)
		log(name, "points pressed under the beard", press_under_beard(co))
		o.data.vertices.foreach_set("co", co.ravel())
		o.data.update()
	for p in o.data.polygons:
		p.use_smooth = True
	return o


def rivets(name, items):
	rv, rf = [], []
	RINGS = [(1.0, -0.25), (1.0, 0.05), (0.85, 0.35), (0.55, 0.55), (0.12, 0.62)]
	for p, o_, r in items:
		o_ = np.asarray(o_, float)
		o_ = o_ / np.linalg.norm(o_)
		t = np.cross(o_, (0, 0, 1.0))
		t = t / np.linalg.norm(t) if np.linalg.norm(t) > 1e-6 else np.array([1.0, 0, 0])
		b = np.cross(o_, t)
		r = r * rng.uniform(0.9, 1.08)
		base = len(rv)
		for rad, up in RINGS:
			for k in range(10):
				a_ = 2 * np.pi * k / 10
				rv.append(p + o_ * (up * r - 0.0015) + r * rad * (np.cos(a_) * t + np.sin(a_) * b))
		for i in range(len(RINGS) - 1):
			rf += [(base + i * 10 + k, base + i * 10 + (k + 1) % 10, base + (i + 1) * 10 + (k + 1) % 10,
				base + (i + 1) * 10 + k) for k in range(10)]
		rf.append(tuple(base + (len(RINGS) - 1) * 10 + k for k in reversed(range(10))))
	me = bpy.data.meshes.new(name)
	me.from_pydata([tuple(v) for v in rv], [], rf)
	me.materials.append(M_RIV)
	o = bpy.data.objects.new(name, me)
	bpy.context.scene.collection.objects.link(o)
	for p in me.polygons:
		p.use_smooth = True
	return o


def fix_normals(o):
	"""Outward: each face's normal points away from his middle (mostly; solidify keeps the shell's own sides right)."""
	bm = bmesh.new()
	bm.from_mesh(o.data)
	bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
	bm.to_mesh(o.data)
	bm.free()


def orient_sheets(group, centre_of):
	"""Before thickness: flip any sheet whose faces look inward (towards centre_of(point))."""
	out = []
	for p, f, uv, mi in PARTS[group]:
		q = p[list(f[len(f) // 2])]
		n = np.cross(q[1] - q[0], q[2] - q[0])
		c = q.mean(0)
		if np.dot(n, c - centre_of(c)) < 0:
			f = [tuple(reversed(x)) for x in f]
		out.append((p, f, uv, mi))
	PARTS[group] = out


def torso_centre(c):
	return np.array([0.0, float(axis_y(c[2])), c[2]])


orient_sheets("chest_plate", torso_centre)
orient_sheets("chest_belt", torso_centre)
CP = make("armor_chest_plate", "chest_plate", [M_HAM, M_POL], beard=True)
CB = make("armor_chest_belt", "chest_belt", [M_BELT, M_POL, M_BELT], thick=0.006, beard=True)
CR = rivets("armor_chest_rivet", RIVETS.get("chest_plate", []) + RIVETS.get("chest_belt", []))
co = verts(CR)[0]
log("chest rivets", len(RIVETS.get("chest_plate", [])), "under beard", press_under_beard(co))
CR.data.vertices.foreach_set("co", co.ravel())
CR.data.update()

# ---------------------------------------------------------------- bones: copy the body points' under each point, bend back
pts, ws = [], []
for n in ("body_shirt", "body_torso", "body_shorts"):
	o = BODYM[n]
	gn = {vg.index: vg.name for vg in o.vertex_groups}
	for v, p in zip(o.data.vertices, POSED[n][0]):
		pts.append(p)
		ws.append({gn[g.group]: g.weight for g in v.groups if g.weight > 0.0})
KD = kdtree.KDTree(len(pts))
for i, p in enumerate(pts):
	KD.insert(Vector(p), i)
KD.balance()
W = ARM.matrix_world
SKIN = {pb.name: W @ pb.matrix @ ARM.data.bones[pb.name].matrix_local.inverted() @ W.inverted() for pb in ARM.pose.bones}


def bind(o, nn=8, soft=0.01):
	"""Copy the nearest body points' bones (many, softly blended: a stiff plate bends smoothly) and bend it back to rest."""
	pco = verts(o)[0]
	groups = {}
	rest = np.empty_like(pco)
	for i, p in enumerate(pco):
		acc = {}
		for _, j, dist in KD.find_n(Vector(p), nn):
			for b, w in ws[j].items():
				acc[b] = acc.get(b, 0.0) + w / (dist + soft)
		top = sorted(acc.items(), key=lambda kv: -kv[1])[:4]
		tot = sum(w for _, w in top) or 1.0
		M = Matrix(((0, 0, 0, 0),) * 4)
		for b, w in top:
			if b not in groups:
				groups[b] = o.vertex_groups.new(name=b)
			groups[b].add([i], w / tot, "REPLACE")
			M = M + SKIN[b] * (w / tot)
		rest[i] = np.array(M.inverted() @ Vector(p))
	o.data.vertices.foreach_set("co", rest.ravel())
	o.data.update()


for o in (CP, CB, CR):
	bind(o)
log("chest bones copied")
pose_arms(0)

# the leather undercoat: his own shirt (same points, same bones), 4 mm out, dark quilted leather
src = BODYM["body_shirt"]
LE = src.copy()
LE.data = src.data.copy()
LE.name = LE.data.name = "armor_chest_leather"
bpy.context.scene.collection.objects.link(LE)
for m in list(LE.modifiers):
	LE.modifiers.remove(m)
bm = bmesh.new()
bm.from_mesh(LE.data)
bm.normal_update()
for v in bm.verts:
	v.co += v.normal * 0.004
bm.to_mesh(LE.data)
bm.free()
for a in list(LE.data.color_attributes):  # (his shirt's colours made it grey and shiny in the game)
	LE.data.color_attributes.remove(a)
LE.data.materials.clear()
LE.data.materials.append(M_LEA)
log("leather undercoat from the shirt")

# ================================================================ THE HELMET (rest pose, Head bone)
before = set(bpy.context.scene.objects)
bpy.ops.import_scene.gltf(filepath=str(ROOT / "assets" / "characters" / "dwarf" / "armor_copper.glb"))
HAIR = None
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

SC, SR = np.array((0.0, 0.026, 1.075)), np.array((0.119, 0.11, 0.117))  # his skull as an egg (dwarf_armor.py)
CLEAR = 0.03  # (the hat hair lies within ~1.8 cm of the egg; the helmet's inside 1.2 cm off that)
# Round 7: the SIZES of the picture-made helmet (measured from armor_copper_picture3d.glb, its mesh is not used):
# a big round bell, ~20.5 cm out from the middle at the brow, top at 1.327 m, flaring ~4 cm to the bottom edge;
# the sides end at 0.945 m, the neck guard at the back dips to 0.875 m. (Round 6's was 15 cm and 1.252 m: too small.)
# Round 8 (owner: "looks like a ball, not a helmet"): a lower round dome on top of the brow band, then a bell skirt that
# drops straight and flares OUT at the bottom, a raised face guard round the eyes, and the back edge UP at 0.985 m so his
# hair comes out under it (round 7's neck guard down at 0.875 m cut through the hair).
H = dict(top=1.31, eq=1.125, bot=0.965, back_bot=0.985, flare=0.048, waist=0.012, guard=0.03, guard_phi=0.85,
	eye=(1.05, 1.09), eye_phi=(0.14, 0.6), face_top=1.035, face_phi=0.98, nasal=0.2, nasal_low=0.975, brow=(1.1, 1.15),
	cheek=0.016, cheek_phi=1.45, cheek_top=1.085, eye_deep=0.012)  # (round 10: cheek guards, deeper eyes, shorter edge)
RX, RY = 0.2, 0.198


def bot_at(phi):
	"""Where the bottom edge is at angle phi (0 = back): cheek guards low at the sides, the back edge higher (hair)."""
	return H["bot"] + (H["back_bot"] - H["bot"]) * np.clip(np.cos(phi), 0, None) ** 2


def real_z(phi, z):
	"""The grid's height lines (made for a level edge at H['bot']) stretched down to the neck guard behind."""
	return np.where(z >= H["eq"], z, H["eq"] - (H["eq"] - z) * (H["eq"] - bot_at(phi)) / (H["eq"] - H["bot"]))


def helm_r(phi, z):
	"""The helmet's outer surface: distance out from its middle line at angle phi (0 = back), grid height z."""
	ex = 1.0 / np.sqrt((np.sin(phi) / RX) ** 2 + (np.cos(phi) / RY) ** 2)
	s = np.clip((z - H["eq"]) / (H["top"] - H["eq"]), 0, 1)
	up = ex * np.sqrt(np.clip(1 - s ** 2, 0, 1))
	low = np.clip((H["eq"] - z) / (H["eq"] - H["bot"]), 0, 1)
	pf = np.abs(((phi - math.pi + np.pi) % (2 * np.pi)) - np.pi)  # (angle from his front)
	eyes = (pf > H["eye_phi"][0] - 1e-6) & (pf < H["eye_phi"][1] + 1e-6) & (z > H["eye"][0] - 1e-6) & (z < H["eye"][1] + 1e-6)
	guard = H["guard"] * (((pf < H["guard_phi"] + 1e-6) & (z < H["eq"] - 0.004) & (z > H["face_top"] - 1e-6) |
		(pf < H["nasal"] / 2 + 1e-6) & (z > H["nasal_low"] - 1e-6) & (z < H["eq"])) & ~eyes)  # (eyes sit deep in it)
	cheek = H["cheek"] * ((pf > H["guard_phi"] - 1e-6) & (pf < H["cheek_phi"] + 1e-6) & (z < H["cheek_top"] + 1e-6))
	guard = guard + cheek - H["eye_deep"] * eyes
	waist = H["waist"] * np.sin(np.pi * np.clip(low / 0.75, 0, 1))  # (the skirt pulls in under the band, then flares)
	return np.where(z >= H["eq"], up, ex + H["flare"] * low ** 2.4 - waist + guard)


def helm_point(phi, z, extra=0.0):
	r = helm_r(phi, z) + extra
	return np.stack([np.sin(phi) * r, SC[1] + np.cos(phi) * r, real_z(phi, z)], -1)


# grid lines on every cut edge, so the openings come out with straight clean edges
fp = H["face_phi"]
phis = sorted(set(list(np.linspace(-np.pi, np.pi, 97)[:-1]) +
	[math.pi + s * a for s in (1, -1) for a in (H["nasal"] / 2, H["eye_phi"][0], H["eye_phi"][1], fp, H["guard_phi"], H["cheek_phi"])]))
phis = np.array([((p + np.pi) % (2 * np.pi)) - np.pi for p in phis])
phis = np.unique(np.round(phis, 6))
zs = np.unique(np.round(np.concatenate([np.linspace(H["bot"], H["top"], 70), [H["eye"][0], H["eye"][1], H["face_top"],
	H["nasal_low"], H["brow"][0], H["brow"][1], H["eq"] - 0.004, H["cheek_top"]]]), 6))
zs = zs[zs < H["top"] - 0.002]
PH, ZZ = np.meshgrid(phis, zs)
HP = helm_point(PH, ZZ)
n_p, n_z = len(phis), len(zs)
F, MI = [], []
for i in range(n_z - 1):
	for j in range(n_p):
		pc = ((phis[j] + phis[(j + 1) % n_p] + (2 * np.pi if j == n_p - 1 else 0)) / 2)
		pf = abs(((pc - math.pi + np.pi) % (2 * np.pi)) - np.pi)  # (angle from his front)
		zc = (zs[i] + zs[i + 1]) / 2
		if pf < fp and zc < H["face_top"] and not (pf < H["nasal"] / 2 and zc > H["nasal_low"]):
			continue  # the face opening (the nasal bar stays)
		eye = H["eye_phi"][0] < pf < H["eye_phi"][1] and H["eye"][0] < zc < H["eye"][1]
		F.append((i * n_p + j, i * n_p + (j + 1) % n_p, (i + 1) * n_p + (j + 1) % n_p, (i + 1) * n_p + j))
		guard = (pf < H["guard_phi"] and H["face_top"] < zc < H["eq"] - 0.004) or (pf < H["nasal"] / 2 and zc > H["nasal_low"])
		cheek = H["guard_phi"] < pf < H["cheek_phi"] and zc < H["cheek_top"]
		MI.append(2 if eye else 1 if (guard or cheek) and zc < H["eq"] else 0)  # (round 8b: the face guard polished, its own plate)  # (round 7: dark eye slits like the picture's; open ones showed his skin, bright)
top_i = len(HP.reshape(-1, 3))
PTS = np.vstack([HP.reshape(-1, 3), [[0, SC[1], H["top"]]]])
F += [((n_z - 1) * n_p + j, (n_z - 1) * n_p + (j + 1) % n_p, top_i) for j in range(n_p)]
MI += [0] * n_p
UVH = np.stack([PH * 0.15 / TILE, ZZ / TILE], -1).reshape(-1, 2)
UVH = np.vstack([UVH, [[0, H["top"] / TILE]]])
add("helm", PTS, F, UVH, MI)
orient_sheets("helm", lambda c: np.array([0, SC[1], min(c[2], SC[2])]))
M_SLIT = material("helm_slit_dark", (0.012, 0.008, 0.006), 0.0, 0.9)
HM = make("armor_head_plate", "helm", [M_HAM, M_POL, M_SLIT], thick=0.005, bevel=0.0013)
HBV = BVHTree.FromObject(HM, bpy.context.evaluated_depsgraph_get())
log("helmet shell", len(HM.data.polygons))


def round_ray(z0):
	def ray(S, V):
		z = z0 + V
		return np.stack([np.zeros_like(S), np.full_like(S, SC[1]), z], -1), np.stack([np.sin(S), np.cos(S), np.zeros_like(S)], -1)
	return ray


# brow band all the way round, riveted; a band round the bottom edge
bz = (H["brow"][0] + H["brow"][1]) / 2
band("helm_band", round_ray(bz), 2 * math.pi, (H["brow"][1] - H["brow"][0]) / 2 + 0.006, off=0.008, border=0.008,
	step=0.004, target=HBV, rivet_every=0.45, riv_size=0.011)  # (round 7: the picture's thick brow band, big rivets)


def bottom_ray(S, V):
	z = real_z(S, np.full_like(S, H["bot"] + 0.024)) + V  # (high enough that no ray passes under the shell's edge)
	return np.stack([np.zeros_like(S), np.full_like(S, SC[1]), z], -1), np.stack([np.sin(S), np.cos(S), np.zeros_like(S)], -1)


# (the bottom rim stops at the face opening: two arcs, each from the cheek round the back)
def back_arc(S, V):
	return bottom_ray(S * (2 * np.pi - 2 * fp - 0.05) / (2 * np.pi - 2 * fp - 0.05) - (np.pi - fp - 0.025), V)


band("helm_band", lambda S, V: bottom_ray(S - (np.pi - fp - 0.025), V), 2 * np.pi - 2 * fp - 0.05, 0.012, n=90, off=0.0,
	border=0.005, target=HBV, closed=False)


# ridge over the top: front brow to the back, riveted (the picture's big round rivets)
def ridge_ray(U, V):
	th = V / 0.2 + 0.28  # (angle over the top from straight up; + toward the back: brow in front, low down the back)
	d = np.stack([U / 0.2, np.sin(th), np.cos(th)], -1)
	d = d / np.linalg.norm(d, axis=-1)[..., None]
	return np.broadcast_to(np.array([0, SC[1], SC[2]]), d.shape).copy(), d


# (front end stops on the brow band: further down, over the eye holes, round 7's first try hung out like a visor)
plate("helm_band", ridge_ray, 0.04, 0.29, target=HBV, off=0.002, border=0.006, pexp=8, rivets=(), stiff=(1, 3))
# (the row of big rivets down the middle is put on the finished strip below: on the shell they sank under it)


# eye plate: a raised plate round the eyes and down the nasal bar
def face_ray(U, V):
	phi = math.pi + U / 0.14
	z = 1.085 + V
	return np.stack([np.zeros_like(phi), np.full_like(phi, SC[1]), z], -1), np.stack([np.sin(phi), np.cos(phi), np.zeros_like(phi)], -1)


log("helmet bands")
orient_sheets("helm_band", lambda c: np.array([0, SC[1], min(c[2], SC[2])]))
HBD = make("armor_head_band", "helm_band", [M_POL, M_POL], thick=0.004)
BBV = BVHTree.FromObject(HBD, bpy.context.evaluated_depsgraph_get())
for th in np.linspace(-1.08, 1.7, 7):  # (the picture's row of big rivets down the middle, sitting ON the strip)
	d = np.array([0, math.sin(th), math.cos(th)])
	hit = BBV.ray_cast(Vector(SC + d * 0.5), Vector(-d), 0.5)
	if hit[0] is not None:
		RIVETS["helm_band"].append((np.array(hit[0]) + d * 0.002, d, 0.012))
HR = rivets("armor_head_rivet", RIVETS["helm_band"])
# (round 8, owner: "hair clipping through": every hair point under the shell is tucked in 1.2 cm inside it;
# below the edge it hangs out free, as on the picture's helmet)
hc = np.empty(len(HAIR.data.vertices) * 3)
HAIR.data.vertices.foreach_get("co", hc)
hc = hc.reshape(-1, 3)
dx, dy = hc[:, 0], hc[:, 1] - SC[1]
hphi, hr = np.arctan2(dx, dy), np.hypot(dx, dy)
hz = hc[:, 2]
hb = bot_at(hphi)
zg = np.where(hz >= H["eq"], hz, H["eq"] - (H["eq"] - hz) * (H["eq"] - H["bot"]) / (H["eq"] - hb))
hpf = np.abs(((hphi - math.pi + np.pi) % (2 * np.pi)) - np.pi)
r_in = helm_r(hphi, zg) - 0.005 - 0.012
under = (hz > hb) & (hz < H["top"]) & ~((hpf < fp + 0.06) & (hz < H["face_top"] + 0.01)) & (hr > r_in)
k = np.where(under, r_in / np.maximum(hr, 1e-6), 1.0)
hc[:, 0], hc[:, 1] = dx * k, SC[1] + dy * k
HAIR.data.vertices.foreach_set("co", hc.ravel())
HAIR.data.update()
log("hair points tucked under the helmet", int(under.sum()))
# (round 8, owner: the beard went through the breastplate: the helmet head's beard is bigger than his plain head's,
# which the plate was pressed under. Now the beard is moved forward to lie ON the plate, 1.2 cm off it, in one piece.)
cpv = np.empty(len(CP.data.vertices) * 3)
CP.data.vertices.foreach_get("co", cpv)
CPB = BVHTree.FromPolygons([Vector(p) for p in cpv.reshape(-1, 3)], [tuple(f.vertices) for f in CP.data.polygons])
need = np.zeros(len(hc))
for i in np.nonzero((hc[:, 2] < 0.95) & (hc[:, 1] < -0.06))[0]:
	p = hc[i]
	hit = CPB.ray_cast(Vector((p[0], -1.0, p[2])), Vector((0, 1, 0)), 2.0)
	if hit[0] is not None and hit[0].y - 0.012 < p[1] < hit[0].y + 0.05:
		need[i] = p[1] - (hit[0].y - 0.012)
GS = 0.015
gx = np.floor((hc[:, 0] + 0.4) / GS).astype(int)
gz = np.floor((hc[:, 2] - 0.4) / GS).astype(int)
G = np.zeros((int(0.8 / GS) + 2, int(0.8 / GS) + 2))
ok = (gx >= 0) & (gx < G.shape[0]) & (gz >= 0) & (gz < G.shape[1])
np.maximum.at(G, (gx[ok], gz[ok]), need[ok])
G0 = G.copy()
for _ in range(4):  # (spread out so the beard moves in one piece, never less than it needs)
	G = np.maximum((G * 4 + np.roll(G, 1, 0) + np.roll(G, -1, 0) + np.roll(G, 1, 1) + np.roll(G, -1, 1)) / 8, G0)
	G = np.maximum(G, np.maximum.reduce([np.roll(G0, 1, 0), np.roll(G0, -1, 0), np.roll(G0, 1, 1), np.roll(G0, -1, 1)]))
taper = np.clip((1.02 - hc[:, 2]) / 0.07, 0, 1)
mv = np.where(ok & (hc[:, 1] < -0.06), G[np.clip(gx, 0, G.shape[0] - 1), np.clip(gz, 0, G.shape[1] - 1)], 0.0) * taper
hc[:, 1] -= mv
HAIR.data.vertices.foreach_set("co", hc.ravel())
HAIR.data.update()
log("beard moved out over the breastplate: points", int((mv > 0).sum()), "most", round(float(mv.max()), 3))
for o in (HM, HBD, HR, HAIR):
	for vg in list(o.vertex_groups):
		o.vertex_groups.remove(vg)
	o.vertex_groups.new(name="Head").add(list(range(len(o.data.vertices))), 1.0, "REPLACE")
log("helmet on the Head bone")

ALL = [CP, CB, CR, LE, HM, HBD, HR, HAIR]
for o in ALL:
	o.parent = ARM
	o.parent_type = "OBJECT"
	o.matrix_parent_inverse = ARM.matrix_world.inverted()
	if not any(m.type == "ARMATURE" for m in o.modifiers):
		o.modifiers.new("skeleton", "ARMATURE").object = ARM

# ---------------------------------------------------------------- photos (review=<pic.png>): arms down like the game
REVIEW = OPT.get("review")
if REVIEW:
	pose_arms(65)
	scene = bpy.context.scene
	BODYM["body_head"].hide_render = True
	BODYM["body_shirt"].hide_render = True
	scene.render.engine = "BLENDER_WORKBENCH"
	scene.display.shading.light = "STUDIO"
	scene.display.shading.color_type = "TEXTURE"
	scene.render.resolution_x, scene.render.resolution_y = 560, 640
	cam = bpy.data.objects.new("rcam", bpy.data.cameras.new("rcam"))
	cam.data.type = "ORTHO"
	scene.collection.objects.link(cam)
	scene.camera = cam
	shots = []
	for tag, loc, aim, scale in (("front", (0, -4, 0.66), 0.66, 1.0), ("side", (-4, 0, 0.66), 0.66, 1.0),
			("back", (0, 4, 0.66), 0.66, 1.0), ("head", (1.4, -3.0, 1.12), 1.1, 0.62)):
		cam.location = Vector(loc)
		cam.data.ortho_scale = scale
		cam.rotation_euler = (Vector((0, 0, aim)) - cam.location).to_track_quat("-Z", "Y").to_euler()
		path = str(Path(REVIEW).with_name(Path(REVIEW).stem + f"_{tag}.png"))
		scene.render.filepath = path
		bpy.ops.render.render(write_still=True)
		shots.append(path)
	log("REVIEW", shots)
	pose_arms(0)

# ---------------------------------------------------------------- export: skeleton + these pieces only
for o in list(BODYM.values()):
	bpy.data.objects.remove(o, do_unlink=True)
HAIR.data.materials.clear()
HAIR.data.materials.append(material("body_head_paint", (0.6, 0.35, 0.2), 0, 0.8))
bpy.ops.object.select_all(action="DESELECT")
ARM.select_set(True)
for o in ALL:
	o.data.validate(clean_customdata=False)
	o.select_set(True)
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_yup=True, export_skins=True,
	export_animations=False, export_apply=False, export_image_format="JPEG", export_image_quality=90)
import glb_jpeg_fix  # noqa: E402  (Godot shows Blender's JPEG pictures white without it: F164)
glb_jpeg_fix.fix(OUT)
log("DONE", OUT, [(o.name, len(o.data.polygons)) for o in ALL])
