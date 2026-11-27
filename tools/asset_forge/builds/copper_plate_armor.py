# The copper armour's helmet and chest, HAND-BUILT as hard plates (F914 round 6, Claude, Nov 26, 2026).
# Owner chose this Nov 26: learn from the picture-made test (armor_picture3d.py, can't ship: Hunyuan licence), build it
# by hand to match the GPT pictures (C:/Users/<you>/ai3d/armor3d/chest + /helm). Owner on that test: "grey padding still
# shows under the armpits and at the neck; the shoulders, helmet and back need a way better texture".
#
#   blender --background --factory-startup --python tools/asset_forge/builds/copper_plate_armor.py -- <out.glb>
#       [review=<pic.png>] [angle=55] [metal=copper|bronze] [trim=black|gold]
#
# ONE recipe for every plate set (F914): metal=bronze (Nov 27, owner's picks) builds the SAME shapes with smooth
# bronze (tools/art/make_bronze_plate.py: finer, half-deep dents, more shine), dark green patina edges, bands and
# rivets, and engravings: a chain-of-diamonds band just inside every big plate's raised edge, round the collar, the
# helmet's brow band, the forearm bands and the helmet's skirt (ENGRAVE below). Out: armor_bronze_plate.glb.
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
#   * gauntlets (Nov 27): three flared riveted forearm bands, an elbow cop, back-of-hand + knuckle plates and a small
#     plate on every finger joint, over a leather glove + sleeve (copies of the hand and forearm skin pushed out).
#     Built in rest pose after the helmet so the helmet and chest stay exactly as OK'd.
# Legs and boots stay from the hand-built set (armor_copper.glb, dwarf_armor.py; owner liked them).
import math
import sys
import tempfile
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
METAL = OPT.get("metal", "copper")
BRONZE = METAL == "bronze"
ENGRAVE = BRONZE  # (engraved bands: bronze only; copper stays exactly as OK'd)
ENG_W, ENG_GAP = 0.026, 0.004  # carved band width, gap inside the raised edge (metres; round 3: 2.2 -> 2.6 cm, bolder)
ENG_BAND_MAX = 0.034  # (the tallest engraved strip on a band: collar, brow band, forearm bands)
BODY = ROOT / "assets" / "characters" / "dwarf" / "dwarf_body.glb"
TEXD = ROOT / "assets" / "textures" / "armor"
TILE = 0.22  # metres of armour one hammered picture covers (~1.1 cm dents; round 14, owner picked "fine dents"
# like the picture: 0.32 = 1.6 cm dents read as snake scales)
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


HAM_COL = image(f"{METAL}_hammered_col", TEXD / f"{METAL}_hammered_col.png")  # (bronze round 3, owner: "way too
# smooth": copper's deep dents in bronze colours, tools/art/make_bronze_plate.py)
DARK = 0.8 if not BRONZE else 1.0  # (round 12, owner: "make the entire texture a little bit darker")
_px = np.empty(len(HAM_COL.pixels), np.float32)
HAM_COL.pixels.foreach_get(_px)
_px = _px.reshape(-1, 4)
_px[:, :3] *= DARK
# (round 14, owner picked: a few green patina specks in the deepest dents, like the picture)
_lum = _px[:, :3].mean(1)
_pat = (_lum < np.percentile(_lum, 5)) & (np.random.default_rng(14).random(len(_lum)) < (0.3 if BRONZE else 0.55))
_px[_pat, :3] = _px[_pat, :3] * 0.45 + np.array([0.09, 0.2, 0.14]) * 0.55
HAM_COL.pixels.foreach_set(_px.ravel())
HAM_COL.filepath_raw = str(Path(tempfile.gettempdir()) / f"{METAL}_hammered_col.png")
HAM_COL.file_format = "PNG"
HAM_COL.save()
HAM_NRM = image(f"{METAL}_hammered_nrm", TEXD / f"{METAL}_hammered_nrm.png", False)


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


M_HAM = (material("bronze_hammered", (0.86, 0.62, 0.32), 0.72, 0.24, HAM_COL, HAM_NRM, 0.55) if BRONZE else  # (bronze
	# round 3: hammered like the copper; round 2's smooth 0.45 was "way too smooth")
	material("copper_hammered", (0.75, 0.38, 0.2), 0.72, 0.24, HAM_COL, HAM_NRM, 0.55))  # (round 14, owner: the picture
# "definitely has a shine": smoother (rough 0.36 -> 0.24), shallower dents (normal 0.9 -> 0.55); metal 0.72 keeps the
# copper colour: at 0.85 + rough 0.2 it mirrored the dark room and turned grey)
TRIM, TRIM_MET, TRIM_ROUGH = {"black": ((0.035, 0.022, 0.015), 0.35, 0.8),
	"gold": ((0.5, 0.33, 0.06), 0.6, 0.5),
	"patina": ((0.012, 0.034, 0.022), 0.2, 0.85)}[OPT.get("trim", "patina" if BRONZE else "black")]  # (bronze, Nov 27,
# owner picked "dark green patina" for the edges, bands and rivets)  # (round 17: trim=black|gold for the page;
# owner picked black. Gold round 2: (0.17, 0.085, 0.016) fully matte was "too brown", so yellower with a soft sheen)
M_POL = material(f"{METAL}_trim_dark", TRIM, TRIM_MET, TRIM_ROUGH)  # (the raised borders, edges and bands; round 16,
# owner: "make them darker, not as shiny, matte, maybe even black": near-black matte; was rubbed-bright copper)
# (round 6 had (0.86, 0.47, 0.27), metal 0.9: in the game it mirrored the grey room and showed silver; the picture's are copper)
M_RIV = (material("bronze_rivet", (0.02, 0.055, 0.036), 0.3, 0.7) if BRONZE else  # (patina, a little lighter + shinier
	# than the edges so the domes still catch the light)
	material("copper_rivet", (0.7, 0.3, 0.13), 0.72, 0.2))
# the carved bands (bronze round 3, owner: "it needs engravings like dwarven ruins", like the Nov 26 picture): REAL
# raised metal, a three-strand plait standing up to 5.7 mm off the plate with dark patina deep in the cuts, laid as its
# own strip just inside every big plate's raised edge and along the collar, brow, helmet skirt and forearm bands; and
# two knot medallions on the breastplate (beside the beard, owner's pick) + one on the back plate. The shapes come
# from the height pictures in tools/art/heights (make_bronze_plate.py), the paint from the matching colour pictures.
ENG = 3
M_ENG = (material("bronze_knot", (0.86, 0.62, 0.32), 0.7, 0.3, image("bronze_knot_col", TEXD / "bronze_knot_col.png"),
	image("bronze_knot_nrm", TEXD / "bronze_knot_nrm.png", False), 1.0) if ENGRAVE else None)
M_MED = (material("bronze_medal", (0.86, 0.62, 0.32), 0.7, 0.3, image("bronze_medal_col", TEXD / "bronze_medal_col.png"),
	image("bronze_medal_nrm", TEXD / "bronze_medal_nrm.png", False), 1.0) if ENGRAVE else None)


def height_map(name):
	img = image(name, ROOT / "tools" / "art" / "heights" / f"{name}.png", False)
	a = np.empty(len(img.pixels), np.float32)
	img.pixels.foreach_get(a)
	return a.reshape(img.size[1], img.size[0], 4)[::-1, :, 0].copy()  # (row 0 = top of the picture)


KNOT_H = height_map("bronze_knot_height") if ENGRAVE else None
MEDAL_H = height_map("bronze_medal_height") if ENGRAVE else None
KNOT_LIFT, KNOT_DEPTH, KNOT_THICK = 0.0012, 0.0045, 0.0038  # (cuts 1.2 mm off the plate, strand tops 5.7 mm; the
# strip's underside 2.6 mm inside the plate: no two surfaces in one place)
MED_LIFT, MED_DEPTH = 0.0015, 0.006


def sample(Hm, u, v, wrap_u=True):
	"""Bilinear height at picture coords u (0..1 across, repeats if wrap_u), v (0..1, 0 = top row)."""
	h, w = Hm.shape
	x = (u % 1.0 if wrap_u else np.clip(u, 0, 1)) * w - 0.5
	y = np.clip(v, 0, 1) * (h - 1)
	x0 = np.floor(x).astype(int)
	y0 = np.clip(np.floor(y).astype(int), 0, h - 2)
	fx, fy = x - x0, y - y0
	x1 = (x0 + 1) % w if wrap_u else np.clip(x0 + 1, 0, w - 1)
	x0 = x0 % w if wrap_u else np.clip(x0, 0, w - 1)
	a = Hm[y0, x0] * (1 - fx) + Hm[y0, x1] * fx
	b = Hm[y0 + 1, x0] * (1 - fx) + Hm[y0 + 1, x1] * fx
	return a * (1 - fy) + b * fy


NOPRESS = []  # (sheet points of plates the beard never presses: the shoulder caps + arm lames)
RELIEF = {}  # object group -> list of (points R x C x 3, corner uvs R x (C+1) x 2, closed, material 0 knot / 1 medal)


def knot_strip(group, rows, dirs, tv, closed, step=0.0038, nv=12):
	"""A raised knot strip over the rows of a sheet (rows K x C x 3 at across-positions tv, K >= 2; dirs = outward):
	fine points every ~4 mm along and nv across, pushed out by the knot height picture (one picture = 4 widths)."""
	rows, dirs = np.asarray(rows, float), np.asarray(dirs, float)
	dirs = dirs / np.linalg.norm(dirs, axis=-1)[..., None]
	tv = np.asarray(tv, float)
	K, C = rows.shape[:2]
	mid = rows[K // 2] if K > 2 else rows.mean(0)
	seg = np.linalg.norm(np.roll(mid, -1, 0) - mid, axis=-1) if closed else np.linalg.norm(mid[1:] - mid[:-1], axis=-1)
	sub = np.maximum(1, np.ceil(seg / step).astype(int))
	cols = np.concatenate([j + np.arange(m) / m for j, m in enumerate(sub)] + ([] if closed else [[C - 1.0]]))
	j0 = np.floor(cols).astype(int) % C
	j1 = (j0 + 1) % C if closed else np.minimum(j0 + 1, C - 1)
	f = (cols - np.floor(cols))[None, :, None]
	R_ = rows[:, j0] * (1 - f) + rows[:, j1] * f
	D_ = dirs[:, j0] * (1 - f) + dirs[:, j1] * f
	vs = np.linspace(tv[0], tv[-1], nv)
	ii = np.clip(np.searchsorted(tv, vs, side="right") - 1, 0, K - 2)
	w = ((vs - tv[ii]) / (tv[ii + 1] - tv[ii]))[:, None, None]
	Pf = R_[ii] * (1 - w) + R_[ii + 1] * w
	Df = D_[ii] * (1 - w) + D_[ii + 1] * w
	Df /= np.linalg.norm(Df, axis=-1)[..., None]
	width = float(np.median(np.linalg.norm(rows[-1] - rows[0], axis=-1)))
	m = Pf[nv // 2]
	L = np.concatenate([[0.0], np.cumsum(np.linalg.norm(np.diff(m, axis=0), axis=-1))])
	if closed:
		L = np.concatenate([L, [L[-1] + np.linalg.norm(m[0] - m[-1])]])
	k = max(1, round(L[-1] / (4 * max(width, 1e-4)))) if closed else L[-1] / (4 * max(width, 1e-4))
	u = L / max(L[-1], 1e-9) * k  # (in pictures; round a loop the last value closes it on a whole repeat)
	v = (vs - tv[0]) / (tv[-1] - tv[0])
	nc = len(cols)
	h = sample(KNOT_H, np.broadcast_to(u[None, :nc], (nv, nc)), np.broadcast_to(v[:, None], (nv, nc)))
	P = Pf + Df * (KNOT_LIFT + KNOT_DEPTH * h)[..., None]
	UV = np.stack(np.broadcast_arrays(u[None, :], 1 - v[:, None]), -1)
	RELIEF.setdefault(group, []).append((P, UV, closed, 0))


def medallion(group, ray, sheet, c, rad, nr=30, na=100):
	"""A round knot medallion of radius rad (metres) centred at c = (U, V) on a plate: laid on sheet (the plate's
	outer surface) along the plate's own rays, pushed out by the medallion height picture."""
	r = np.linspace(0.0, rad, nr + 1)[1:]
	a = np.linspace(0, 2 * np.pi, na, endpoint=False)
	Rg, Ag = np.meshgrid(r, a, indexing="ij")
	x, y = Rg * np.cos(Ag), Rg * np.sin(Ag)
	O, Dr = ray(c[0] + x, c[1] + y)
	D = lay(O, Dr, sheet, 0.0)
	h = sample(MEDAL_H, (x / rad + 1) / 2, (1 - y / rad) / 2, wrap_u=False)
	h = np.where(Rg > rad * 0.995, 0.0, h)
	P = O + Dr * (D + MED_LIFT + MED_DEPTH * h)[..., None]
	uv = np.stack([(x / rad + 1) / 2, (y / rad + 1) / 2], -1)
	UV = np.concatenate([uv, uv[:, :1]], 1)
	oc, dc = ray(np.array([[c[0]]]), np.array([[c[1]]]))
	h0 = float(sample(MEDAL_H, np.array(0.5), np.array(0.5), False))
	pc = oc[0, 0] + dc[0, 0] * (lay(oc, dc, sheet, 0.0)[0, 0] + MED_LIFT + MED_DEPTH * h0)
	RELIEF.setdefault(group, []).append((P, UV, True, 1, pc))


HORN_RING = (0.0115, 0.0275)  # (where the knot ring round a horn's base starts and ends, metres along it)


def horn_tube(group, ctrl, side, r0, CL, ridge_from=0.036):
	"""A horn along the cubic curve ctrl (4 points; the first sunk inside what it grows from): r0 thick at the base,
	tapering to a point, a slight wobble (not perfectly round), growth ridges from ridge_from on, a raised knot ring
	round the base (HORN_RING). Adds its centre line to CL (for the knot ring's outward side)."""
	t = np.linspace(0, 1, 400)[:, None]
	cur = sum(c_ * w_ for c_, w_ in zip(ctrl, ((1 - t) ** 3, 3 * (1 - t) ** 2 * t, 3 * (1 - t) * t ** 2, t ** 3)))
	L_ = np.concatenate([[0.0], np.cumsum(np.linalg.norm(np.diff(cur, axis=0), axis=-1))])
	S = np.unique(np.concatenate([np.linspace(0, L_[-1] - 0.002, 52), list(HORN_RING)]))
	Cn = np.stack([np.interp(S, L_, cur[:, k]) for k in range(3)], -1)
	T = np.gradient(Cn, axis=0)
	T /= np.linalg.norm(T, axis=-1)[:, None]
	u = np.array([0.0, 0.0, -1.0])  # (seam on the underside)
	us = []
	for k in range(len(S)):  # (parallel transport: no twist)
		u = u - T[k] * np.dot(u, T[k])
		u /= np.linalg.norm(u)
		us.append(u)
	U_ = np.array(us)
	V_ = np.cross(T, U_)
	NA = 20
	a = np.linspace(0, 2 * np.pi, NA + 1)  # (last column repeats the first: the picture's seam)
	f = S / S[-1]
	base_r = r0 * (1 - f) ** 0.8 + 0.0028 * f
	ridge = 0.045 * np.clip((S - ridge_from) / 0.015, 0, 1) * np.cos(2 * np.pi * S / 0.011) ** 2
	wob = 1 + 0.035 * np.cos(3 * a + side) + 0.02 * np.cos(2 * a + 1.0)
	R_ = base_r[:, None] * (1 + ridge[:, None]) * wob[None, :]
	X = Cn[:, None] + R_[..., None] * (np.cos(a)[None, :, None] * U_[:, None] + np.sin(a)[None, :, None] * V_[:, None])
	tip = Cn[-1] + T[-1] * 0.004
	N1 = NA + 1
	F = [(i * N1 + j, i * N1 + j + 1, (i + 1) * N1 + j + 1, (i + 1) * N1 + j) for i in range(len(S) - 1) for j in range(NA)]
	ti = len(S) * N1
	F += [((len(S) - 1) * N1 + j, (len(S) - 1) * N1 + j + 1, ti) for j in range(NA)]
	UVh = np.stack(np.broadcast_arrays((a / (2 * np.pi) * 0.12 / TILE)[None, :], (S / TILE)[:, None]), -1).reshape(-1, 2)
	add(group, np.vstack([X.reshape(-1, 3), [tip]]), F, np.vstack([UVh, [[0.06 / TILE, S[-1] / TILE]]]), [0] * len(F))
	i0, i1 = list(S).index(HORN_RING[0]), list(S).index(HORN_RING[1])
	rows = X[[i0, i1], :NA]
	knot_strip(group, rows, rows - Cn[[i0, i1], None], [0.0, 1.0], True)
	CL.append(Cn)


DIA_STEP = 0.0017  # (each step of the stepped diamonds stands 1.7 mm over the one round it)


def diamond(group, ray, sheet, c, rx, ry, steps=3, na=64):
	"""A stepped dwarf diamond (half sizes rx across, ry up) centred at c = (U, V) on a plate, laid on sheet along the
	plate's rays: steps flat terraces, each smaller one standing DIA_STEP higher, coloured dark trim / bronze in turn."""
	a = np.linspace(0, 2 * np.pi, na, endpoint=False)
	rd = 1 / (np.abs(np.cos(a)) / rx + np.abs(np.sin(a)) / ry)  # (distance to the diamond's edge at angle a)
	sr, lv = [], []
	for k in range(steps):  # (terrace k: from its inner riser out to the next; risers 1.2 % of the size wide)
		lo, hi = k / steps, (k + 1) / steps
		sr += [max(lo + 0.012, 0.04), (lo + hi) / 2, hi - 0.012]
		lv += [steps - k] * 3
	sr.append(1.0)
	lv.append(0)
	sr, lv = np.array(sr), np.array(lv, float)
	Sg, Ag = np.meshgrid(sr, a, indexing="ij")
	x, y = Sg * rd * np.cos(Ag), Sg * rd * np.sin(Ag)
	O, Dr = ray(c[0] + x, c[1] + y)
	D = lay(O, Dr, sheet, 0.0)
	P = O + Dr * (D + MED_LIFT + DIA_STEP * lv[:, None])[..., None]
	uv = np.stack([(x + c[0]) / TILE, (y + c[1]) / TILE], -1)
	UV = np.concatenate([uv, uv[:, :1]], 1)
	# (faces: quads row by row, then the middle fan; a terrace's own quads take its colour, risers the colour above)
	col = [3 if (steps - lv[i]) % 2 == 0 else 2 for i in range(len(sr) - 1)]
	mi = np.concatenate([np.full(na, m_) for m_ in col] + [np.full(na, 3)])
	oc, dc = ray(np.array([[c[0]]]), np.array([[c[1]]]))
	pc = oc[0, 0] + dc[0, 0] * (lay(oc, dc, sheet, 0.0)[0, 0] + MED_LIFT + DIA_STEP * steps)
	RELIEF.setdefault(group, []).append((P, UV, True, mi, pc))


def knot_panel(group, ray, sheet, c, hw, hh, w=0.013, gap=0.007, pexp=6.0, n=140):
	"""A raised knot frame (a rounded tall rectangle, half sizes hw x hh, strip w wide) round a stepped diamond."""
	a = np.linspace(0, 2 * np.pi, n, endpoint=False)

	def ring(A, B):
		r_ = 1 / ((np.abs(np.cos(a)) / A) ** pexp + (np.abs(np.sin(a)) / B) ** pexp) ** (1 / pexp)
		return c[0] + r_ * np.cos(a), c[1] + r_ * np.sin(a)

	ui, vi = ring(hw - w, hh - w)
	uo, vo = ring(hw, hh)
	O, Dr = ray(np.stack([ui, uo]), np.stack([vi, vo]))
	rows = O + Dr * lay(O, Dr, sheet, 0.0)[..., None]
	knot_strip(group, rows, Dr, [0.0, 1.0], True)
	diamond(group, ray, sheet, c, hw - w - gap, min(hh - w - gap, (hw - w - gap) * 1.9))  # (not too thin)


def sheet_bvh(P):
	"""BVH of a plate sheet (rings x points round, closed rings, as plate() builds them)."""
	K, C = P.shape[:2]
	F = [(i * C + j, i * C + (j + 1) % C, (i + 1) * C + (j + 1) % C, (i + 1) * C + j) for i in range(K - 1) for j in range(C)]
	return BVHTree.FromPolygons([Vector(p) for p in P.reshape(-1, 3)], F)


def relief_object(name, group, outward):
	"""The raised strips + medallions of a group as one mesh, faces looking outward (outward(point) -> a direction away
	from him there); its open edges get walls KNOT_THICK down into the plate (no underside: nobody can see it)."""
	V, F, UVL, MIs = [], [], [], []
	for item in RELIEF[group]:
		P, UV, closed, mi = item[:4]
		R, C = P.shape[:2]
		base = len(V)
		V += list(P.reshape(-1, 3))
		q = [base + (R // 2) * C + C // 2, base + (R // 2) * C + (C // 2 + 1) % C, base + (R // 2 + 1) * C + (C // 2 + 1) % C]
		nq = np.cross(V[q[1]] - V[q[0]], V[q[2]] - V[q[0]])
		flip = np.dot(nq, outward(V[q[0]])) < 0
		faces, uvs = [], []
		for i in range(R - 1):
			for j in range(C if closed else C - 1):
				jn = (j + 1) % C
				faces.append((base + i * C + j, base + i * C + jn, base + (i + 1) * C + jn, base + (i + 1) * C + j))
				uvs.append((UV[i, j], UV[i, j + 1], UV[i + 1, j + 1], UV[i + 1, j]))
		if len(item) > 4:  # (medallion: close its middle with a small fan)
			ci = len(V)
			V.append(item[4])
			for j in range(C):
				faces.append((ci, base + j, base + (j + 1) % C))
				uvs.append(((0.5, 0.5), UV[0, j], UV[0, j + 1]))
		if flip:
			faces = [tuple(reversed(f_)) for f_ in faces]
			uvs = [tuple(reversed(u_)) for u_ in uvs]
		F += faces
		UVL += uvs
		MIs += [mi] * len(faces) if np.isscalar(mi) else list(mi)  # (the stepped diamonds: a colour per step)
	V = np.asarray(V)
	me = bpy.data.meshes.new(name)
	me.from_pydata([tuple(p) for p in V], [], F)
	uvl = me.uv_layers.new(name="UVMap")
	uvl.data.foreach_set("uv", np.array([c for f in UVL for c in f], float).ravel())
	for m_ in (M_ENG, M_MED, M_HAM, M_POL):
		me.materials.append(m_)
	me.polygons.foreach_set("material_index", MIs)
	o = bpy.data.objects.new(name, me)
	bpy.context.scene.collection.objects.link(o)
	bm = bmesh.new()
	bm.from_mesh(me)
	bm.normal_update()
	rim = [e for e in bm.edges if e.is_boundary]
	down = {v: v.normal.copy() for e in rim for v in e.verts}
	new = bmesh.ops.extrude_edge_only(bm, edges=rim)["geom"]
	for v in new:
		if isinstance(v, bmesh.types.BMVert):
			e_ = next(x for x in v.link_edges if x.other_vert(v) in down)
			v.co -= down[e_.other_vert(v)] * KNOT_THICK
	bm.to_mesh(me)
	bm.free()
	return o


def mats(*ms):
	"""A mesh's materials, with the engraved one at index ENG (slots in between repeat the edge colour, so the
	solidify rims, which take the next slot, stay edge-coloured)."""
	ms = list(ms)
	if ENGRAVE:
		ms += [M_POL] * (ENG - len(ms)) + [M_ENG]
	return ms
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


def add(group, P, F, UV, MI, FUV=None):
	"""FUV: {face number: [uv per corner]} for faces whose picture runs its own way (the engraved strips)."""
	PARTS.setdefault(group, []).append((np.asarray(P, float), F, np.asarray(UV, float), MI, FUV or {}))


def strip_uv(P0, P1, closed, K=None):
	"""Corner UVs for a strip of quads between two rows of points (P0 inner/lower row, P1 outer/upper row, same
	length): u runs along it (one strip picture per 4 band widths, a whole number of repeats round a closed loop),
	v = 0 on row 0, 1 on row 1. Returns {j: 4 corner uvs} for the quad (j, j+1, j+1 on row 1, j on row 1)."""
	mid = (P0 + P1) / 2
	width = float(np.median(np.linalg.norm(P1 - P0, axis=-1)))
	seg = np.linalg.norm(np.roll(mid, -1, 0) - mid, axis=-1)
	if not closed:
		seg = seg[:-1]
	s_ = np.concatenate([[0.0], np.cumsum(seg)])
	L = s_[-1]
	rep = 4 * max(width, 1e-4)
	k = max(1, round(L / rep)) if closed else L / rep
	u = s_ / max(L, 1e-9) * k
	out = {}
	for j in range(len(P0) if closed else len(P0) - 1):
		a, b = u[j], u[j + 1]
		out[j] = [(a, 0.0), (b, 0.0), (b, 1.0), (a, 1.0)]
	return out


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


def plate(group, ray, hw, hh, *, off=0.016, border=0.011, step=0.0035, dome=0.002, pexp=5.0, point=0.0,
		target=None, flat=None, rivets=(45, 135, 225, 315), riv_size=0.0055, hole=0.0, keep_min=None, stiff=(3, 8), rigid=False, top_wide=0.0,
		nsp=64, engrave=True, medals=(), nopress=False, panels=()):
	"""One plate: a rounded rectangle hw x hh (half sizes, metres) laid on target along ray(U, V) -> (origin, dir).
	point: how far its bottom edge dips in the middle (a pointed lower edge, like the picture's breastplate and skirt).
	flat: (z_top, flare) for skirt plates: one straight cone (doesn't follow his legs), flaring out going down.
	top_wide: how much wider the top edge is than the middle (0.3 = 30%: the chest plates' corners up to the shoulders).
	Returns the plate's top-surface points function for extra parts."""
	ts = 1.0 - border / min(hw, hh)
	T = sorted(set([0.0, 0.18, 0.34, 0.48, 0.6, 0.7, 0.78, ts - 0.05, ts - 0.004, ts + 0.004, (ts + 1) / 2, 1.0]))
	if nsp < 32:  # (small plates (gauntlet fingers): fewer rings, same raised border)
		T = sorted(set([0.0, 0.45, 0.75, ts - 0.004, ts + 0.004, 1.0]))
	T = np.array([t for t in T if t >= hole])
	NSP = nsp  # (points round the edge; the gauntlets' small finger plates use fewer)
	psi =np.linspace(0, 2 * np.pi, NSP, endpoint=False)
	rb = 1 / ((np.abs(np.cos(psi)) / hw) ** pexp + (np.abs(np.sin(psi)) / hh) ** pexp) ** (1 / pexp)
	TM = T[:, None] * np.ones((1, NSP))  # (each ring's size, per point round it)
	eng_row = None
	if ENGRAVE and engrave and nsp >= 32 and not hole:
		# (bronze: an engraved band just inside the raised edge, the same width all the way round)
		ta = ts - 0.006 - ENG_GAP / rb
		tb = ta - ENG_W / rb
		if tb.min() > 0.35:
			low = [t for t in T if t < tb.min() - 0.03]
			high = [t for t in T if t >= ts - 0.005]
			TM = np.vstack([np.array(low)[:, None] * np.ones((1, NSP)), tb[None], ta[None],
				np.array(high)[:, None] * np.ones((1, NSP))])
			eng_row = len(low)
			T = TM.min(1)
	U = TM * rb * np.cos(psi)
	V = TM * rb * np.sin(psi)
	if point:
		V = V - point * np.clip(1 - np.abs(U) / hw, 0, 1) * np.clip(-V / hh, 0, 1)
	U = U * (1 + top_wide * np.clip(V / hh, 0, 1) ** 2)
	O, Dr = ray(U, V)
	D = lay(O, Dr, target or TORSO, off)
	if flat:
		D = np.full_like(D, np.percentile(D, 85)) + flat[1] * np.clip(flat[0] - O[..., 2], 0, None)
	elif rigid:
		# (round 8: one smooth curved sheet resting on his highest points; following his muscles left dents, owner)
		deg = 2 if rigid is True else int(rigid)  # (round 11: the back plate bends more (4): with 2 it floated 6.5 cm off his back, a hump)
		Un, Vn = U / max(hw, 1e-6), V / max(hh, 1e-6)
		B = np.stack([Un ** i * Vn ** j for i in range(deg + 1) for j in range(deg + 1 - i)], -1).reshape(-1, (deg + 1) * (deg + 2) // 2)
		c, *_ = np.linalg.lstsq(B, D.ravel(), rcond=None)
		fit = (B @ c).reshape(D.shape)
		r = D - fit
		if deg > 2:
			r = np.minimum(r, np.percentile(r, 97) + 0.01)  # (a braid-sized spike shouldn't lift the whole plate)
		log("rigid %s %.2fx%.2f lift %.3f max %.3f low %.3f" % (group, hw, hh, np.percentile(r, 99.5), r.max(), r.min()))
		D = fit + np.percentile(r, 99.5)
	else:
		D = stiffen(D, passes=stiff)
	if keep_min is not None:
		D = np.maximum(D, keep_min)
	t = TM
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
	FUV = {}
	for i in range(start, len(T) - 1):
		pol = 1 if T[i] >= ts - 0.005 else 0
		if i == eng_row:
			pol = 0  # (round 3: a raised knot strip stands on this row instead of a flat picture)
			knot_strip(group, P[i:i + 2], Dr[i:i + 2], [0.0, 1.0], True)
		F += [(i * NSP + j, i * NSP + (j + 1) % NSP, (i + 1) * NSP + (j + 1) % NSP, (i + 1) * NSP + j) for j in range(NSP)]
		MI += [pol] * NSP
	add(group, P.reshape(-1, 3), F, UVs.reshape(-1, 2), MI, FUV)
	if nopress:
		NOPRESS.append(P.reshape(-1, 3))
	if medals and ENGRAVE:
		sb = sheet_bvh(P)
		for c, rad in medals:
			medallion(group, ray, sb, c, rad)
		for c, phw, phh in panels:
			knot_panel(group, ray, sb, c, phw, phh)
	if rivets:
		tr = 1.0 - border * 0.5 / min(hw, hh)
		for a in rivets:
			a = math.radians(a)
			r_ = 1 / ((abs(math.cos(a)) / hw) ** pexp + (abs(math.sin(a)) / hh) ** pexp) ** (1 / pexp) * tr
			u, v = np.array([[r_ * math.cos(a)]]), np.array([[r_ * math.sin(a)]])
			if point:
				v = v - point * np.clip(1 - np.abs(u) / hw, 0, 1) * np.clip(-v / hh, 0, 1)
			u = u * (1 + top_wide * np.clip(v / hh, 0, 1) ** 2)
			o, d = ray(u, v)
			dd = lay(o, d, target or TORSO, off)
			if flat:
				dd = np.full_like(dd, np.percentile(D - flat[1] * np.clip(flat[0] - O[..., 2], 0, None), 50))
				dd = dd + flat[1] * np.clip(flat[0] - o[..., 2], 0, None)
			else:
				dd = np.full_like(dd, D[np.unravel_index(np.argmin(np.abs(U - u[0, 0]) + np.abs(V - v[0, 0])), U.shape)])
			RIVETS.setdefault(group, []).append((o[0, 0] + d[0, 0] * (dd[0, 0] + off + step + 0.002), d[0, 0], riv_size))
	return P


def band(group, ray, length, hh, *, n=120, off=0.016, border=0.008, step=0.003, target=None, mat_mid=0, rivet_every=0.0,
		riv_size=0.0055, fixed=None, closed=True, extra=None, roundness=0.0, engrave=False):
	"""A strip all round something (belt, collar, helmet bands): ray(S, V) with S = 0..length along it.
	roundness: 0..1 how much each ring is pushed out to its widest point (1 = a perfect ring, like a gauntlet's cuff);
	extra(S, V): more stand-off on top (a cuff's flare)."""
	ts = 1.0 - border / hh
	T = np.array(sorted(set([-1.0, -(ts + 1) / 2, -ts - 0.004, -ts + 0.004, -0.5, 0.0, 0.5, ts - 0.004, ts + 0.004, (ts + 1) / 2, 1.0])))
	e = ts - 0.004
	if ENGRAVE and engrave and 2 * hh * e > ENG_BAND_MAX:  # (a tall band: the engraved strip only in its middle,
		e = ENG_BAND_MAX / 2 / hh  # at most ENG_BAND_MAX high; round 1's 6 cm diamonds on the forearms were too big)
		T = np.array(sorted(set(list(T) + [-e, e])))
	S = np.linspace(0, length, n, endpoint=not closed)
	Sg, Tg = np.meshgrid(S, T)
	V = Tg * hh
	O, Dr = ray(Sg, V)
	D = fixed if fixed is not None else stiffen(lay(O, Dr, target or TORSO, off), passes=(2, 6))
	if roundness:
		D = D * (1 - roundness) + D.max(1, keepdims=True) * roundness
	if extra is not None:
		D = D + extra(Sg, V)
	h = np.where(np.abs(Tg) >= ts, step, 0.0)
	P = O + Dr * (D + off + h)[..., None]
	uo = rng.uniform(0, TILE, 2)
	UVs = np.stack([(Sg + uo[0]) / TILE, (V + uo[1]) / TILE], -1)
	F, MI, FUV = [], [], {}
	m = n if closed else n - 1
	eng = ENGRAVE and engrave
	if eng:  # (bronze: the band's middle is one engraved strip from its lower raised edge to its upper one)
		i0, i1 = list(T).index(-e), list(T).index(e)
		knot_strip(group, P[i0:i1 + 1], Dr[i0:i1 + 1], T[i0:i1 + 1], closed)
	for i in range(len(T) - 1):
		pol = 1 if (abs(T[i]) >= ts - 0.005 and abs(T[i + 1]) >= ts - 0.005) or mat_mid == 1 else mat_mid
		pol = 1 if abs(T[i]) >= ts - 0.005 or abs(T[i + 1]) >= ts + 0.003 else mat_mid
		if eng and i0 <= i < i1:
			pol = mat_mid  # (round 3: under the raised knot strip)
		F += [(i * n + j, i * n + (j + 1) % n, (i + 1) * n + (j + 1) % n, (i + 1) * n + j) for j in range(m)]
		MI += [pol] * m
	add(group, P.reshape(-1, 3), F, UVs.reshape(-1, 2), MI, FUV)
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
MED_U, MED_V, MED_R = 0.115, -0.045, 0.056  # (bronze round 3, owner's pick: two medallions on the breastplate, one each
# side of the beard's middle braid; the back plate gets one big one in the middle)
# cuirass: breastplate (pointed bottom, under the beard), backplate, side plates under the arms (tucked under both)
# (the back in two layers like the picture: a lower plate, and an upper plate over the shoulder blades outside it)
for phic, zc, hw, hh, pt, off, dm in ((FRONT, 0.735, 0.26, 0.172, 0.03, 0.018, 0.016),  # (round 7: wider, no leather beside it)
		(BACK, 0.75, 0.27, 0.185, 0.012, 0.018, 0.012)):  # (round 8: one back plate; two left a dent line, owner)
	ref = ref_at(phic, zc) + off
	plate("chest_plate", torso_ray(phic, zc, ref), hw, hh, off=off, point=pt, pexp=6, dome=dm, rigid=True if phic == FRONT else 4,  # (round 7: domed like the picture's chest)
		rivets=(20, 160, 200, 340, 270, 90), top_wide=0.3,
		medals=(((-MED_U, MED_V), MED_R), ((MED_U, MED_V), MED_R)) if phic == FRONT else (((0.0, -0.01), 0.085),),
		panels=() if phic == FRONT else tuple(((s_ * 0.155, -0.01), 0.046, 0.1) for s_ in (-1, 1)))  # (bronze round 4,
	# owner's pick: a raised knot frame with a stepped diamond inside, each side of the back medallion: "a lot of empty space")  # (round 13, owner chose: wider only at the top corners, to
	# cover the dark wedge under the arms; the waist stays narrow as round 12)
# (round 14, owner: "there's still a plate under the armpits, we can just remove it": the two side plates are gone.
# Round 13 tries before that (a plate over each shoulder top, bigger side plates) stuck out like flaps.)
# (Nov 26 try: a plate over each shoulder top stuck out like wings; the dark leather shows there instead)
log("cuirass")
# belt: dark leather with a copper buckle in front, riveted
ref = ref_at(BACK, 0.56)
band("chest_belt", lambda S, V: torso_ray(0.0, 0.56, 1.0)(S / 1.0 * 1.0, V), 2 * math.pi, 0.05, off=0.03, border=0.005,
	step=0.0012, mat_mid=2, rivet_every=0.6)
# (the ray above takes S as an angle: length 2 pi = all the way round)
bk = ref_at(FRONT, 0.56)
plate("chest_plate", torso_ray(FRONT, 0.56, bk + 0.04), 0.062, 0.056, off=0.04, border=0.014, step=0.0, pexp=8, hole=0.6,
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


band("chest_plate", neck_ray, 2 * math.pi, NECK[1], off=0.012, border=0.008, rivet_every=0.9, engrave=True)
log("collar")
# shoulders: a big cap over each shoulder, three lames down the upper arm (the upper always outside)
SPIKE_V, SPIKE_CL, SPIKE_AT = 0.0, [], []  # (bronze: where on the cap the spike stands; its centre lines; its bases)
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
		plate("chest_plate", arm_ray(along), 0.12 - 0.008 * k, 0.036, target=ARMS, off=0.017 - 0.004 * k, pexp=6,
			point=0.0, dome=0.006, rivets=(160, 20), rigid=True, nopress=True)  # (round 15, owner: the bigger ones "stick out so much",
		# 3.4 cm off; now 1.7 cm down to 0.9 cm)  # (round 14, owner picked "puffy layered shoulders":
		# bigger, rounder, each one standing further out than the one below, like roof tiles)  # (round 8: stiff rings round the arm, stepping down)

	def cap_ray(U, V, S0=S0):
		# (round 8: the picture's shoulder plate: a curved roof over the shoulder, from the collar out over the arm;
		# U = front to back, V = round the roof from the neck side to the arm side. Round 7's dome had dents.)
		th = 0.52 + V / 0.12  # (round 8b: smaller, ends over the arm, not out like a wing)
		d = np.stack([side * np.sin(th), np.zeros_like(th), np.cos(th)], -1)
		o = np.stack([np.full_like(U, S0[0] - side * 0.03), S0[1] - U, np.full_like(U, S0[2] - 0.02)], -1)
		return o, d

	CAP = plate("chest_plate", cap_ray, 0.125, 0.1, target=ARMS, off=0.016, pexp=4, dome=0.018, rigid=True,  # (round 14: rounder;
		# a bigger cap (0.14 x 0.115) stood 9 cm off like a wing)
		rivets=(25, 155, 205, 335, 90), nopress=True)
	if ENGRAVE:  # (bronze round 5, owner: "add similar spikes on the shoulders, a little bit thicker": a horn from the
		# cap's crown, out and curving up, 2.6 cm thick at the base (the helmet's are 1.9))
		o_, d_ = cap_ray(np.zeros((1, 1)), np.full((1, 1), SPIKE_V))
		n = d_[0, 0] / np.linalg.norm(d_[0, 0])
		B = o_[0, 0] + n * lay(o_, d_, sheet_bvh(CAP), 0.0)[0, 0]
		out = np.array([side, 0.0, 0.0])
		ctrl = [B - 0.009 * n, B + 0.04 * n, B + 0.03 * n + 0.08 * out, B + 0.025 * n + 0.09 * out + np.array([0, 0, 0.075])]
		horn_tube("chest_spike", ctrl, side, 0.026, SPIKE_CL)  # (out over the arm, then curling up like the helmet's)
		SPIKE_AT.append(B)
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
	"""Press the front back behind the beard (so it never pokes through). Round 4, owner: "blackishness on the
	shoulders": the side braids pressed steep pits up to 13 cm deep into the upper breastplate, which read as black
	smudges. Now: at most PRESS_SIDE deep beside the middle (|x| > PRESS_X), and every press fades out smoothly over
	~3 cm round it (a soft valley, not a pit). The shoulder caps and arm lames (NOPRESS) are never pressed."""
	keep = None
	if NOPRESS:
		pts = np.vstack(NOPRESS)
		keep = kdtree.KDTree(len(pts))
		for k, q in enumerate(pts):
			keep.insert(Vector(q), k)
		keep.balance()
	dy = np.zeros(len(P))
	for i, p in enumerate(P):
		if p[2] > 0.95 or p[1] > 0.0 or p[2] < 0.5:
			continue
		if keep is not None and keep.find(Vector(p))[2] < 0.012:
			continue
		by = beard_back(p)
		if by is not None and p[1] < by + 0.006:
			dy[i] = by + 0.006 - p[1]
			if abs(p[0]) > PRESS_X:
				dy[i] = min(dy[i], PRESS_SIDE)
	hot = np.nonzero(dy > 0)[0]
	if not len(hot):
		return 0
	kd = kdtree.KDTree(len(hot))
	for k, i in enumerate(hot):
		kd.insert(Vector(P[i]), int(i))
	kd.balance()
	out = dy.copy()
	for i, p in enumerate(P):  # (the soft edge: each point sinks at least as far as its pressed neighbours, less with distance)
		near = kd.find_range(Vector(p), PRESS_FADE)
		if near:
			out[i] = max(out[i], max(dy[j] * (1 - d / PRESS_FADE) ** 2 for _, j, d in near))
	moved = 0
	for i in np.nonzero(out > 0)[0]:
		P[i, 1] += out[i]
		if dy[i] > 0:
			hit = SHIRT_BVH.find_nearest(Vector(P[i]))
			if hit[0] is not None and (Vector(P[i]) - hit[0]).dot(hit[1]) < 0.006:
				P[i] = np.array(hit[0] + hit[1] * 0.006)
		moved += 1
	return moved


PRESS_X, PRESS_SIDE, PRESS_FADE = 0.06, 0.02, 0.04


# ================================================================ object making
def make(name, group, mats, thick=0.0038, bevel=0.0011, beard=False, outward=None):
	P, F, UV, MI, off = [], [], [], [], 0
	FUV = {}
	for p, f, uv, mi, fuv in PARTS[group]:
		P.append(p)
		UV.append(uv)
		FUV.update({k + len(F): v for k, v in fuv.items()})
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
	for fi, uvs in FUV.items():  # (the engraved strips' own picture layout)
		for li, uv in zip(me.polygons[fi].loop_indices, uvs):
			uvl.data[li].uv = uv
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
	if RELIEF.get(group):
		r = relief_object(name + "_knots", group, outward or (lambda c: c - torso_centre(c)))
		log(name, "carving points", len(r.data.vertices))
		bpy.ops.object.select_all(action="DESELECT")
		r.select_set(True)
		o.select_set(True)
		bpy.context.view_layer.objects.active = o
		bpy.ops.object.join()
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
	for p, f, uv, mi, fuv in PARTS[group]:
		q = p[list(f[len(f) // 2])]
		n = np.cross(q[1] - q[0], q[2] - q[0])
		c = q.mean(0)
		if np.dot(n, c - centre_of(c)) < 0:
			f = [tuple(reversed(x)) for x in f]
			fuv = {k: list(reversed(v)) for k, v in fuv.items()}
		out.append((p, f, uv, mi, fuv))
	PARTS[group] = out


def torso_centre(c):
	return np.array([0.0, float(axis_y(c[2])), c[2]])


orient_sheets("chest_plate", torso_centre)
orient_sheets("chest_belt", torso_centre)
CP = make("armor_chest_plate", "chest_plate", mats(M_HAM, M_POL), beard=True)
CS = None
if SPIKE_CL:
	_scl = np.vstack(SPIKE_CL)
	CS = make("armor_chest_spike", "chest_spike", [M_HAM, M_POL], thick=0,
		outward=lambda c: c - _scl[np.argmin(np.linalg.norm(_scl - c, axis=1))])
	log("shoulder spikes", len(CS.data.polygons))
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


def bind(o, nn=8, soft=0.01, blur=0.035):
	"""Copy the nearest body points' bones (many, softly blended: a stiff plate bends smoothly) and bend it back to rest.
	blur (round 4, owner: "blackishness on the shoulders"): each point then takes the average bones of the plate points
	within `blur` metres; before, a few points of the bulgy upper plates got another bone than their neighbours and sank
	into a dark dent when his arm moved."""
	pco = verts(o)[0]
	groups = {}
	rest = np.empty_like(pco)
	raw = []
	for i, p in enumerate(pco):
		acc = {}
		for _, j, dist in KD.find_n(Vector(p), nn):
			for b, w in ws[j].items():
				acc[b] = acc.get(b, 0.0) + w / (dist + soft)
		t_ = sum(acc.values()) or 1.0
		raw.append({b: w / t_ for b, w in acc.items()})
	stiff = None
	if blur:
		sub = rng.choice(len(pco), min(len(pco), 6000), replace=False)
		skd = kdtree.KDTree(len(sub))
		for k, i in enumerate(sub):
			skd.insert(Vector(pco[i]), k)
		skd.balance()
		if NOPRESS:  # (the stiff shoulder caps + arm lames: blended over 7 cm: 12 cm let the arm lames' rivets poke through, 3.5 cm left a dent)
			pts = np.vstack(NOPRESS)
			nkd = kdtree.KDTree(len(pts))
			for k, q in enumerate(pts):
				nkd.insert(Vector(q), k)
			nkd.balance()
			stiff = nkd
	for i, p in enumerate(pco):
		acc = dict(raw[i])
		if blur:
			r_ = blur
			if stiff is not None and stiff.find(Vector(p))[2] < 0.012:
				r_ = 0.07
			for _, k, d in skd.find_range(Vector(p), r_):
				f = 1.0 - d / r_
				for b, w in raw[sub[k]].items():
					acc[b] = acc.get(b, 0.0) + w * f
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


CP_POSED = verts(CP)[0].copy()
for o in (CP, CB, CR):
	bind(o)


def bind_like(o, src, src_posed, anchors):
	"""Every point of o takes the finished bones of src's point nearest its anchor (the nearest of anchors), so o
	moves as one stiff piece with that spot of src (the shoulder spikes with their cap)."""
	skd = kdtree.KDTree(len(src_posed))
	for k, q in enumerate(src_posed):
		skd.insert(Vector(q), k)
	skd.balance()
	names = {g.index: g.name for g in src.vertex_groups}
	pco = verts(o)[0]
	rest = np.empty_like(pco)
	groups = {}
	A = np.asarray(anchors)
	for i, p in enumerate(pco):
		j = skd.find(Vector(A[np.argmin(np.linalg.norm(A - p, axis=1))]))[1]
		M = Matrix(((0, 0, 0, 0),) * 4)
		for g in src.data.vertices[j].groups:
			b = names[g.group]
			if b not in groups:
				groups[b] = o.vertex_groups.new(name=b)
			groups[b].add([i], g.weight, "REPLACE")
			M = M + SKIN[b] * g.weight
		rest[i] = np.array(M.inverted() @ Vector(p))
	o.data.vertices.foreach_set("co", rest.ravel())
	o.data.update()


if CS is not None:
	bind_like(CS, CP, CP_POSED, SPIKE_AT)
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
# (round 13, owner chose a NECK GUARD: the hair squeezed out under the high back edge looked smeared, so the back edge
# comes down to 0.9 m, over the collar and the back plate's top, and the back hair is hidden inside.)
H = dict(top=1.275, eq=1.125, bot=0.965, back_bot=0.9, flare=0.034, waist=0.012, guard=0.014, guard_phi=0.85,
	eye=(1.06, 1.094), eye_phi=(0.12, 0.62), face_top=1.035, face_phi=0.98, nasal=0.26, nasal_low=0.95, nasal_out=0.016, frame_phi=0.74, brow=(1.1, 1.15),
	cheek=0.016, cheek_phi=1.45, cheek_top=1.085, eye_deep=0.003)  # (round 15, owner: "too plain, the entire thing blocked, so much dead space under the eyes",
# picture: a shaped eye frame: only a thin edge under the eyes (face_top back up to 1.035; at 1.047 his bare nose showed), the raised frame ends past
# the eyes (frame_phi) so the temples step back, and the nasal narrows to a point (NASAL_PT below))  # (round 14, owner picked "solid helmet face": the face plate reaches 3.5 cm further down
# (face_top 1.035 -> 1.0) so it is one plate with two eye holes, not bars; it stands 1.4 cm out instead of 3 so the
# brow band hugs the helmet instead of sticking out like a hat brim; bigger eye holes, a longer nasal)  # (round 10: cheek guards, shorter edge; round 13, owner: eye holes "too deep", was 1.2 cm; round 14: flat dark slits 3 mm into the guard)
RX, RY = 0.172, 0.17  # (round 11, owner: "the helmet is way too big"; was 0.2)


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
	guard = H["guard"] * (((pf < H["frame_phi"] + 1e-6) & (z < H["eq"] - 0.004) & (z > H["face_top"] - 1e-6) |
		(pf < H["nasal"] / 2 + 1e-6) & (z > H["nasal_low"] - 1e-6) & (z < H["eq"])))  # (round 14: the eyes sit IN
	# the raised guard, only eye_deep lower; before they dropped to the shell behind it, 3 cm deep, owner: "you can see they're deep")
	cheek = H["cheek"] * ((pf > H["guard_phi"] - 1e-6) & (pf < H["cheek_phi"] + 1e-6) & (z < H["cheek_top"] + 1e-6))
	nas = (pf < H["nasal"] / 2 + 1e-6) & (z < H["eye"][0] + 1e-6) & (z > H["nasal_low"] - 1e-6)
	guard = guard + cheek - H["eye_deep"] * eyes + H["nasal_out"] * nas  # (round 16, owner: "my nose is sticking out":
	# the nasal below the eyes stands 1.6 cm further out and is wider, over his nose)
	waist = H["waist"] * np.sin(np.pi * np.clip(low / 0.75, 0, 1))  # (the skirt pulls in under the band, then flares)
	return np.where(z >= H["eq"], up, ex + H["flare"] * low ** 2.4 - waist + guard)


def helm_point(phi, z, extra=0.0):
	r = helm_r(phi, z) + extra
	return np.stack([np.sin(phi) * r, SC[1] + np.cos(phi) * r, real_z(phi, z)], -1)


# grid lines on every cut edge, so the openings come out with straight clean edges
fp = H["face_phi"]
phis = sorted(set(list(np.linspace(-np.pi, np.pi, 97)[:-1]) +
	[math.pi + s * a for s in (1, -1) for a in (H["nasal"] / 2, H["eye_phi"][0], H["eye_phi"][1], fp, H["guard_phi"], H["cheek_phi"], H["frame_phi"])]))
phis = np.array([((p + np.pi) % (2 * np.pi)) - np.pi for p in phis])
phis = np.unique(np.round(phis, 6))
zs = np.unique(np.round(np.concatenate([np.linspace(H["bot"], H["top"], 70), [H["eye"][0], H["eye"][1], H["face_top"],
	H["nasal_low"], H["brow"][0], H["brow"][1], H["eq"] - 0.004, H["cheek_top"]]]), 6))
zs = zs[zs < H["top"] - 0.002]
SKIRT_ENG = (1.036, 1.066)  # (bronze: an engraved band round the helmet's skirt, cheek guard to cheek guard round the back)
if ENGRAVE:
	zs = np.unique(np.concatenate([zs[(zs < SKIRT_ENG[0] - 0.002) | (zs > SKIRT_ENG[1] + 0.002)], SKIRT_ENG]))
PH, ZZ = np.meshgrid(phis, zs)
# the nasal narrows to a point at its bottom, like the picture's: its points below the eye frame move in toward the
# middle (the faces are still picked on the straight grid, so the cut edges stay clean)
_off = ((PH - math.pi + np.pi) % (2 * np.pi)) - np.pi  # (signed angle from his front)
_nas = (np.abs(_off) < H["nasal"] / 2 + 1e-6) & (ZZ < H["face_top"] + 1e-6)
_tap = np.clip((ZZ - H["nasal_low"]) / (H["face_top"] - H["nasal_low"]), 0, 1) ** 0.8 * 0.85 + 0.15
PHM = np.where(_nas, math.pi + _off * _tap, PH)
HP = helm_point(PHM, ZZ)
n_p, n_z = len(phis), len(zs)
F, MI, FIDX = [], [], {}
for i in range(n_z - 1):
	for j in range(n_p):
		pc = ((phis[j] + phis[(j + 1) % n_p] + (2 * np.pi if j == n_p - 1 else 0)) / 2)
		pf = abs(((pc - math.pi + np.pi) % (2 * np.pi)) - np.pi)  # (angle from his front)
		zc = (zs[i] + zs[i + 1]) / 2
		if pf < fp and zc < H["face_top"] and not (pf < H["nasal"] / 2 and zc > H["nasal_low"]):
			continue  # the face opening (the nasal bar stays)
		eye = H["eye_phi"][0] < pf < H["eye_phi"][1] and H["eye"][0] < zc < H["eye"][1]
		FIDX[(i, j)] = len(F)
		F.append((i * n_p + j, i * n_p + (j + 1) % n_p, (i + 1) * n_p + (j + 1) % n_p, (i + 1) * n_p + j))
		guard = (pf < H["frame_phi"] and H["face_top"] < zc < H["eq"] - 0.004) or (pf < H["nasal"] / 2 and zc > H["nasal_low"])
		cheek = H["guard_phi"] < pf < H["cheek_phi"] and zc < H["cheek_top"]
		MI.append(2 if eye else 1 if (guard or cheek) and zc < H["eq"] else 0)  # (round 8b: the face guard polished, its own plate)  # (round 7: dark eye slits like the picture's; open ones showed his skin, bright)
top_i = len(HP.reshape(-1, 3))
PTS = np.vstack([HP.reshape(-1, 3), [[0, SC[1], H["top"]]]])
F += [((n_z - 1) * n_p + j, (n_z - 1) * n_p + (j + 1) % n_p, top_i) for j in range(n_p)]
MI += [0] * n_p
UVH = np.stack([PH * 0.15 / TILE, ZZ / TILE], -1).reshape(-1, 2)
UVH = np.vstack([UVH, [[0, H["top"] / TILE]]])
HFUV = {}
if ENGRAVE:
	ie = list(zs).index(SKIRT_ENG[0])
	pfs = np.abs(((phis - math.pi + np.pi) % (2 * np.pi)) - np.pi)
	js = [j for j in range(n_p - 1) if pfs[j] > H["cheek_phi"] + 0.05 and pfs[j + 1] > H["cheek_phi"] + 0.05]
	js = js + [js[-1] + 1]
	# (round 3: a raised knot strip from one cheek guard round the back to the other, standing on these two rows)
	sa = (phis + np.pi) % (2 * np.pi) - np.pi  # (signed angle from his back)
	js = sorted(js, key=lambda j: sa[j])
	rw = HP[ie:ie + 2][:, js]
	dw = rw - np.array([0.0, SC[1], 0.0])
	dw[..., 2] = 0.0
	knot_strip("helm", rw, dw, [0.0, 1.0], False)
add("helm", PTS, F, UVH, MI, HFUV)
orient_sheets("helm", lambda c: np.array([0, SC[1], min(c[2], SC[2])]))
M_SLIT = material("helm_slit_dark", (0.012, 0.008, 0.006), 0.0, 0.9)
# (round 17, owner: the face frame and cheek guards get the edges' matte colour too; round 16 kept them bright copper)
HELM_OUT = lambda c: c - np.array([0, SC[1], min(c[2], SC[2])])  # noqa: E731
HM = make("armor_head_plate", "helm", mats(M_HAM, M_POL, M_SLIT), thick=0.005, bevel=0.0013, outward=HELM_OUT)
HBV = BVHTree.FromObject(HM, bpy.context.evaluated_depsgraph_get())
log("helmet shell", len(HM.data.polygons))


def round_ray(z0):
	def ray(S, V):
		z = z0 + V
		return np.stack([np.zeros_like(S), np.full_like(S, SC[1]), z], -1), np.stack([np.sin(S), np.cos(S), np.zeros_like(S)], -1)
	return ray


# brow band all the way round, riveted; a band round the bottom edge
bz = (H["brow"][0] + H["brow"][1]) / 2
band("helm_band", round_ray(bz), 2 * math.pi, (H["brow"][1] - H["brow"][0]) / 2 + 0.006, off=0.003, border=0.008,
	step=0.003, target=HBV, rivet_every=0.45, riv_size=0.011, engrave=True)  # (round 7: the picture's thick brow band, big rivets)


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
CREST = plate("helm_band", ridge_ray, 0.04, 0.29, target=HBV, off=0.002, border=0.006, pexp=8, rivets=(), stiff=(1, 3), engrave=False)
BADGE_V, BADGE_R = -0.246, 0.03  # (bronze round 4, owner's pick "knot crest + front badge": a knot medallion on the
# crest's front end just over the brow band, and a raised knot strip from it over the top down the back)
if ENGRAVE:
	csb = sheet_bvh(CREST)
	medallion("helm_band", ridge_ray, csb, (0.0, BADGE_V), BADGE_R)
	cv = np.linspace(BADGE_V + BADGE_R - 0.004, 0.274, 150)
	O_, D_ = ridge_ray(np.stack([np.full_like(cv, -0.014), np.full_like(cv, 0.014)]), np.stack([cv, cv]))
	knot_strip("helm_band", O_ + D_ * (lay(O_, D_, csb, 0.0) + 0.002)[..., None], D_, [0.0, 1.0], False)  # (2 mm higher
	# than the plates' strips: it is the crest; its walls still reach 0.6 mm into the strip under it)
# (the row of big rivets down the middle is put on the finished strip below: on the shell they sank under it)


# eye plate: a raised plate round the eyes and down the nasal bar
def face_ray(U, V):
	phi = math.pi + U / 0.14
	z = 1.085 + V
	return np.stack([np.zeros_like(phi), np.full_like(phi, SC[1]), z], -1), np.stack([np.sin(phi), np.cos(phi), np.zeros_like(phi)], -1)


log("helmet bands")
orient_sheets("helm_band", lambda c: np.array([0, SC[1], min(c[2], SC[2])]))
HBD = make("armor_head_band", "helm_band", mats(M_POL, M_POL), thick=0.004, outward=HELM_OUT)
BBV = BVHTree.FromObject(HBD, bpy.context.evaluated_depsgraph_get())
for th in ([] if ENGRAVE else np.linspace(-1.08, 1.7, 7)):  # (the picture's row of big rivets down the middle, sitting
	# ON the strip; bronze has the knot crest there instead)
	d = np.array([0, math.sin(th), math.cos(th)])
	hit = BBV.ray_cast(Vector(SC + d * 0.5), Vector(-d), 0.5)
	if hit[0] is not None:
		RIVETS["helm_band"].append((np.array(hit[0]) + d * 0.002, d, 0.012))
HR = rivets("armor_head_rivet", RIVETS["helm_band"])
HORN_CL = []


def horn(side):
	"""Bronze round 4 (owner's pick "short curved horns"): a small horn from the upper side of the dome, out and curving
	up, a hand long, chunky (not round: a slight wobble, growth ridges), its base 9 mm sunk into the shell, a knot ring
	round the base where it leaves the dome."""
	phi = side * math.pi / 2
	B = helm_point(np.array(phi), np.array(1.195))
	n = np.cross(helm_point(np.array(phi), np.array(1.2)) - B, helm_point(np.array(phi + 0.01), np.array(1.195)) - B)
	n = n / np.linalg.norm(n)
	if n[0] * side < 0:
		n = -n
	ctrl = [B - 0.009 * n, B + 0.045 * n, B + np.array([side * 0.08, -0.012, 0.035]), B + np.array([side * 0.088, -0.022, 0.098])]
	horn_tube("helm_horn", ctrl, side, 0.019, HORN_CL)


HN = None
if ENGRAVE:
	horn(1)
	horn(-1)
	_hcl = np.vstack(HORN_CL)
	HN = make("armor_head_horn", "helm_horn", [M_HAM, M_POL], thick=0,
		outward=lambda c: c - _hcl[np.argmin(np.linalg.norm(_hcl - c, axis=1))])
	log("horns", len(HN.data.polygons))
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
def lay_over(sgn, zmax, ztaper):
	"""Hair points behind the plate (sgn -1: the beard in front, +1: the braids down his back) move out to lie
	1.2 cm over it, all in one piece (spread out, never less than a point needs)."""
	need = np.zeros(len(hc))
	for i in np.nonzero((hc[:, 2] < zmax) & (hc[:, 1] * sgn > 0.06))[0]:
		p = hc[i]
		hit = CPB.ray_cast(Vector((p[0], sgn * 1.0, p[2])), Vector((0, -sgn, 0)), 2.0)
		d = (hit[0].y + sgn * 0.012 - p[1]) * sgn if hit[0] is not None else 0.0
		if 0.0 < d < 0.062:  # (deeper points are inside him, hidden)
			need[i] = d
	GS = 0.015
	gx = np.floor((hc[:, 0] + 0.4) / GS).astype(int)
	gz = np.floor((hc[:, 2] - 0.4) / GS).astype(int)
	G = np.zeros((int(0.8 / GS) + 2, int(0.8 / GS) + 2))
	ok = (gx >= 0) & (gx < G.shape[0]) & (gz >= 0) & (gz < G.shape[1])
	np.maximum.at(G, (gx[ok], gz[ok]), need[ok])
	G0 = G.copy()
	for _ in range(4):
		G = np.maximum((G * 4 + np.roll(G, 1, 0) + np.roll(G, -1, 0) + np.roll(G, 1, 1) + np.roll(G, -1, 1)) / 8, G0)
		G = np.maximum(G, np.maximum.reduce([np.roll(G0, 1, 0), np.roll(G0, -1, 0), np.roll(G0, 1, 1), np.roll(G0, -1, 1)]))
	taper = np.clip((ztaper - hc[:, 2]) / 0.07, 0, 1)
	mv = np.where(ok & (hc[:, 1] * sgn > 0.06), G[np.clip(gx, 0, G.shape[0] - 1), np.clip(gz, 0, G.shape[1] - 1)], 0.0) * taper
	hc[:, 1] += sgn * mv
	return mv


mv = lay_over(-1, 0.95, 1.02)
HAIR.data.vertices.foreach_set("co", hc.ravel())
HAIR.data.update()
log("beard moved out over the breastplate: points", int((mv > 0).sum()), "most", round(float(mv.max()), 3))
# (round 11, owner: "the braids are still clipping out" at the back. Lifting them out over the plate (round 11)
# left them floating off his back (round 12, owner), so now they're tucked in UNDER the back plate, like hair
# tucked into a collar: every hair point behind the plate goes 1.2 cm inside it.)
tuck = 0
TUCKED = set()
# (round 13: also the hair between the neck guard's edge and the plate's top edge: it goes in under the plate's top
# edge, at the height of the plate's first point below it, so none puffs out behind the neck guard.)
below = hc[:, 2] < bot_at(np.arctan2(hc[:, 0], hc[:, 1] - SC[1])) + 0.005
for i in np.nonzero(below & (hc[:, 2] < 0.98) & (hc[:, 1] > 0.06))[0]:
	p = hc[i]
	for dz in np.arange(0.0, 0.1, 0.01):
		hit = CPB.ray_cast(Vector((p[0], 1.0, p[2] - dz)), Vector((0, -1, 0)), 2.0)
		if hit[0] is not None:
			break
	if hit[0] is not None and p[1] > hit[0].y - 0.012:
		hc[i, 1] = hit[0].y - 0.012
		tuck += 1
		TUCKED.add(int(i))
HAIR.data.vertices.foreach_set("co", hc.ravel())
HAIR.data.update()
log("braids tucked under the back plate: points", tuck)
# (round 13, owner: "his braids do not move, but the rings on the braids move": the hat hair was put fully on the Head
# bone, so the braids and back hair stood still while body_rings swung. Now it keeps its own bones (braids, back hair,
# beard on the chest); only the hair UNDER the helmet goes on the Head bone (so it can't swing out through the shell),
# fading back to its own bones over the 5 cm below the helmet's edge.)
hc = np.empty(len(HAIR.data.vertices) * 3)
HAIR.data.vertices.foreach_get("co", hc)
hc = hc.reshape(-1, 3)
hphi = np.arctan2(hc[:, 0], hc[:, 1] - SC[1])
head_w = np.clip((hc[:, 2] - (bot_at(hphi) - 0.05)) / 0.05, 0, 1)
gi_head = HAIR.vertex_groups["Head"].index if "Head" in HAIR.vertex_groups else HAIR.vertex_groups.new(name="Head").index
# (hair tucked under the back plate moves with his chest like the plate, so a swinging lock can't poke out through it)
gi_chest = HAIR.vertex_groups["spine_03"].index if "spine_03" in HAIR.vertex_groups else HAIR.vertex_groups.new(name="spine_03").index
for v in HAIR.data.vertices:
	t = float(head_w[v.index])
	if v.index in TUCKED:
		for g in v.groups:
			g.weight = 0.0
		HAIR.vertex_groups[gi_chest].add([v.index], 1.0 - t, "REPLACE")
	elif t <= 0.0:
		continue
	else:
		for g in v.groups:
			g.weight *= (1.0 - t)
	if t > 0.0:
		HAIR.vertex_groups[gi_head].add([v.index], t, "ADD")
log("hat hair keeps its swing bones; points fully on the Head bone", int((head_w >= 1).sum()))
for o in [o_ for o_ in (HM, HBD, HR, HN) if o_ is not None]:
	for vg in list(o.vertex_groups):
		o.vertex_groups.remove(vg)
	o.vertex_groups.new(name="Head").add(list(range(len(o.data.vertices))), 1.0, "REPLACE")
log("helmet on the Head bone")

# ================================================================ THE GAUNTLETS (rest pose: arms straight out)
# (F914, Nov 27: the owner OK'd the helmet + chest; the gauntlets are made the same way, like the picture: a riveted
# elbow cop, the forearm in lames each one's wrist edge flaring out over the next, ending in a bell cuff over the wrist,
# a domed plate over the back of the hand, a knuckle plate, and every finger joint its own little plate over a dark
# leather glove (a copy of his hand, 1.5 mm out: the game hides his bare hands under it, so the palm is leather).
# Each piece is on ONE bone (finger plates on their finger bone, so they curl with it); only the elbow pieces copy the
# arm's own blended bones so they bend at the elbow. Built after the helmet so the helmet's random picture spots stay.)
REST = {n: verts(BODYM[n], bpy.context.evaluated_depsgraph_get()) for n in ("body_hand_l", "body_hand_r", "body_torso")}
FINGERS5 = ("thumb", "index", "middle", "ring", "pinky")


def rest_bvh(n, keep):
	co, polys = REST[n]
	return BVHTree.FromPolygons([Vector(p) for p in co], [f for f in polys if keep(list(f))])


def owner_of(o):
	"""Each point's main bone's first word (thumb/index/.../hand/lowerarm)."""
	gn = {vg.index: vg.name for vg in o.vertex_groups}
	return np.array([gn[max(v.groups, key=lambda q: q.weight).group].split("_")[0] if v.groups else "" for v in o.data.vertices])


tco, tpolys = REST["body_torso"]
FOREARM = BVHTree.FromPolygons([Vector(p) for p in np.vstack([tco, REST["body_hand_l"][0], REST["body_hand_r"][0]])],
	[f for f in tpolys if np.abs(tco[list(f), 0]).min() > 0.45] +
	[tuple(i + len(tco) for i in f) for f in REST["body_hand_l"][1]] +
	[tuple(i + len(tco) + len(REST["body_hand_l"][0]) for i in f) for f in REST["body_hand_r"][1]])
HANDT, FINGT = {}, {}
for s in "lr":
	own = owner_of(BODYM[f"body_hand_{s}"])
	HANDT[s] = rest_bvh(f"body_hand_{s}", lambda f, own=own: (own[f] == "hand").mean() > 0.5)
	for fn in FINGERS5:  # (one target per finger: a ray must never land on the finger next to it)
		FINGT[s, fn] = rest_bvh(f"body_hand_{s}", lambda f, own=own, fn=fn: (own[f] == fn).mean() > 0.5)


def bone_pts(name):
	b = ARM.data.bones[name]
	return np.array(W @ b.head_local), np.array(W @ b.tail_local)


def unit(v):
	v = np.asarray(v, float)
	return v / np.linalg.norm(v)


def perp(v, ax):
	v = np.asarray(v, float)
	return unit(v - ax * np.dot(v, ax))


def line_ray(A, ax, e0, rr, v0=0.0, drop=0.0):
	"""Rays out from a line (A, along ax): U = metres round it (rr = radius it's measured at), V = metres along it from v0;
	U = 0 points along e0. drop: the line sits that far behind e0 (flatter fans, for the back of the hand)."""
	e1 = np.cross(ax, e0)

	def ray(U, V):
		ang = U / rr
		o = (A - e0 * drop) + ax * (v0 + V)[..., None]
		d = np.cos(ang)[..., None] * e0 + np.sin(ang)[..., None] * e1
		return o, d
	return ray


GB, GC = {}, {}  # gauntlet piece group -> bone ("elbow_<s>" = copies the arm's blended bones), centre line


def piece(bone, A, ax, drop_e0=None):
	g = "gt%d" % len(GB)
	GB[g] = bone
	A0 = A - drop_e0 if drop_e0 is not None else A
	GC[g] = lambda c, A0=A0, ax=ax: A0 + ax * np.dot(c - A0, ax)
	return g


for s in "lr":
	E, WR = bone_pts(f"lowerarm_{s}")
	AX = unit(WR - E)
	UP, BK = perp((0, 0, 1), AX), perp((0, 1, 0), AX)
	# forearm: three lames (elbow, forearm, bell cuff over the wrist), each one's top tucked 5+ mm inside the one above
	for a0, a1, o0, fl, bone in ((-0.03, 0.045, 0.011, 0.007, f"elbow_{s}"), (0.035, 0.125, 0.008, 0.014, f"lowerarm_{s}"),
			(0.112, 0.208, 0.01, 0.032, f"lowerarm_{s}")):
		ac, hh = (a0 + a1) / 2, (a1 - a0) / 2
		band(piece(bone, E, AX), line_ray(E, AX, UP, 0.05, ac), 2 * math.pi * 0.05, hh, n=72, off=o0, border=0.0075,
			step=0.0028, target=FOREARM, roundness=0.55, rivet_every=0.06, riv_size=0.0045, engrave=True,  # (S in metres round the arm:
			# in angles the copper picture came out stretched into stripes)
			extra=lambda S, V, hh=hh, fl=fl: fl * np.clip((V + hh) / (2 * hh), 0, 1) ** 1.6)
	# elbow cop: a round domed plate over the point of the elbow (his back, +y, with the arms out)
	plate(piece(f"elbow_{s}", E, AX), line_ray(E, AX, BK, 0.045, 0.004), 0.042, 0.042, off=0.032, target=FOREARM, pexp=2.3,
		dome=0.012, border=0.008, rivets=(0, 90, 180, 270), riv_size=0.0042, nsp=40)
	# the back of the hand: a domed plate from under the cuff to the knuckles, then a knuckle plate standing over its edge
	K = np.mean([bone_pts(f"{f}_01_{s}")[0] for f in FINGERS5[1:]], 0)
	HX, HL = unit(K - WR), float(np.linalg.norm(K - WR))
	HU = perp((0, 0, 1), HX)
	plate(piece(f"hand_{s}", WR, HX, HU * 0.03), line_ray(WR, HX, HU, 0.05, HL * 0.46, drop=0.03), 0.047, HL * 0.43,
		off=0.011, target=HANDT[s], pexp=4, dome=0.006, border=0.0075, step=0.003, rivets=(35, 145, 215, 325),
		riv_size=0.0038, nsp=40)
	plate(piece(f"hand_{s}", WR, HX, HU * 0.03), line_ray(WR, HX, HU, 0.05, HL + 0.002, drop=0.03), 0.052, 0.014,
		off=0.024, target=HANDT[s], pexp=5, dome=0.004, border=0.005, step=0.002, rivets=(0, 180), riv_size=0.0036, nsp=40)
	# fingers: a little plate over each joint (dark glove in the gaps, like the picture), the last one to the tip
	for fn in FINGERS5:
		for i, seg in enumerate(("01", "02", "03")):
			bn = f"{fn}_{seg}_{s}"
			h, t = bone_pts(bn)
			if seg == "03":
				t = bone_pts(f"{fn}_04_leaf_{s}")[1]
			fx, fl = unit(t - h), float(np.linalg.norm(t - h))
			if seg == "03":
				fl -= 0.006  # (stops short of the tip: the glove rounds it off)
			fu = perp((0, -0.75, 0.66) if fn == "thumb" else (0, 0, 1), fx)  # (the thumbnail faces forward and up)
			g0 = 0.004 if seg == "01" and fn != "thumb" else 0.0025  # (gap at each joint: room to bend)
			plate(piece(bn, h, fx), line_ray(h, fx, fu, 0.011, g0 + (fl - g0 - 0.0025) / 2), 0.019 if fn == "thumb" else 0.0175,
				(fl - g0 - 0.0025) / 2, off=0.0095, target=FINGT[s, fn], pexp=4, dome=0.003, border=0.004, step=0.0018,
				rivets=(), nsp=20, stiff=(2, 4))  # (round 2: chunkier, like the picture's big gloved hands)
log("gauntlet pieces", len(GB))

for g in GB:
	orient_sheets(g, GC[g])
# rest-pose arm skin points with their bones, for the elbow pieces (bend with the elbow like his arm does)
apts, aws = [], []
for n in ("body_torso",):
	o = BODYM[n]
	gn = {vg.index: vg.name for vg in o.vertex_groups}
	for v, p in zip(o.data.vertices, REST[n][0]):
		if abs(p[0]) > 0.42:
			apts.append(p)
			aws.append({gn[q.group]: q.weight for q in v.groups if q.weight > 0.0})
AKD = kdtree.KDTree(len(apts))
for i, p in enumerate(apts):
	AKD.insert(Vector(p), i)
AKD.balance()


def bind_gauntlet(o, bone):
	if not bone.startswith("elbow_"):
		o.vertex_groups.new(name=bone).add(list(range(len(o.data.vertices))), 1.0, "REPLACE")
		return
	groups = {}
	for i, p in enumerate(verts(o)[0]):
		acc = {}
		for _, j, dist in AKD.find_n(Vector(p), 10):
			for b, w in aws[j].items():
				acc[b] = acc.get(b, 0.0) + w / (dist + 0.01)
		top = sorted(acc.items(), key=lambda kv: -kv[1])[:3]
		tot = sum(w for _, w in top) or 1.0
		for b, w in top:
			if b not in groups:
				groups[b] = o.vertex_groups.new(name=b)
			groups[b].add([i], w / tot, "REPLACE")


def join(objs, name):
	bpy.ops.object.select_all(action="DESELECT")
	for o in objs:
		o.select_set(True)
	bpy.context.view_layer.objects.active = objs[0]
	bpy.ops.object.join()
	o = objs[0]
	o.name = o.data.name = name
	return o


gp, gr = [], []
for bone in sorted(set(GB.values())):
	gs = [g for g in GB if GB[g] == bone]
	key = "gb_" + bone
	PARTS[key] = [p for g in gs for p in PARTS[g]]
	if any(g in RELIEF for g in gs):
		RELIEF[key] = [r for g in gs for r in RELIEF.get(g, [])]
		_gc = GC[next(g for g in gs if g in RELIEF)]
	small = bone.split("_")[0] in FINGERS5
	o = make("_g_" + bone, key, mats(M_HAM, M_POL), thick=0.0022 if small else 0.0034, bevel=0.0007 if small else 0.001,
		outward=(lambda c, f=_gc: c - f(c)) if key in RELIEF else None)
	bind_gauntlet(o, bone)
	gp.append(o)
	rv = [r for g in gs for r in RIVETS.get(g, [])]
	if rv:
		r = rivets("_gr_" + bone, rv)
		bind_gauntlet(r, bone)
		gr.append(r)
GP = join(gp, "armor_chest_gauntlet_plate")
GR = join(gr, "armor_chest_gauntlet_rivet")
# the glove: his own hands (same points, same bones), 4 mm out (a puffy padded glove), dark leather; and a leather
# sleeve: his forearm skin from the shirt's sleeve to the wrist, 3 mm out (round 1 showed bare skin inside the elbow)
gl = []
for nm, push, keep in (("body_hand_l", 0.004, None), ("body_hand_r", 0.004, None),
		("body_torso", 0.003, lambda p: 0.405 < abs(p[0]) < 0.73)):
	src = BODYM[nm]
	o = src.copy()
	o.data = src.data.copy()
	bpy.context.scene.collection.objects.link(o)
	for m in list(o.modifiers):
		o.modifiers.remove(m)
	bm = bmesh.new()
	bm.from_mesh(o.data)
	if keep:
		mw = o.matrix_world
		bmesh.ops.delete(bm, geom=[v for v in bm.verts if not keep(mw @ v.co)], context="VERTS")
	bm.normal_update()
	for v in bm.verts:
		v.co += v.normal * push
	bm.to_mesh(o.data)
	bm.free()
	for a in list(o.data.color_attributes):
		o.data.color_attributes.remove(a)
	o.data.materials.clear()
	o.data.materials.append(M_LEA)
	gl.append(o)
GG = join(gl, "armor_chest_gauntlet_glove")
log("gauntlets", [(o.name, len(o.data.polygons)) for o in (GP, GR, GG)])

ALL = [o_ for o_ in (CP, CS, CB, CR, LE, HM, HBD, HR, HN, HAIR, GP, GR, GG) if o_ is not None]
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
	BODYM["body_hand_l"].hide_render = BODYM["body_hand_r"].hide_render = True  # (the game hides them under the gloves)
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
			("back", (0, 4, 0.66), 0.66, 1.0), ("head", (1.4, -3.0, 1.12), 1.1, 0.62),
			("hand", (2.2, -3.0, 0.5), (0.5, 0, 0.42), 0.42), ("handback", (2.4, 2.6, 0.6), (0.5, 0, 0.42), 0.42)):
		aim = Vector(aim) if isinstance(aim, tuple) else Vector((0, 0, aim))
		cam.location = Vector(loc) + (aim - Vector((0, 0, aim.z)))
		cam.data.ortho_scale = scale
		cam.rotation_euler = (aim - cam.location).to_track_quat("-Z", "Y").to_euler()
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
