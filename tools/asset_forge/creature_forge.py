# Turns a forged creature (one solid statue from forge.py) into a game creature (by Claude 3).
#
#   blender --background --factory-startup --python tools/asset_forge/creature_forge.py -- \
#       <forged.glb> <picture_cut.png> <snail|bat|beetle> <out.glb> [preview_prefix] [size_m]
#
# 1. Lines up a camera with the ChatGPT picture (tries many angles until the model's outline matches
#    the picture's outline), then PAINTS the picture's real colours onto every surface that camera sees.
#    Hidden surfaces get the colours of their neighbours (spread out), with the forge's own shading.
# 2. Turns the creature so it faces forward (found from its painted eyes) and sizes it.
# 3. Splits it into the moving parts the game looks for (see docs/design/creature-craft.md):
#      snail: body (shell), soft_body, soft_stalk_l / soft_stalk_r, peek (eyes shown while hiding)
#      bat:   body, wing_l, wing_r
#      beetle: body, leg_l0..2, leg_r0..2
#    plus materials "eye" (flashes before an attack) and "glow" (lava cracks, amber backs, glowing spots).
# Front faces -Y in Blender (= +Z in Godot), origin at the bottom centre, metres.
import math
import sys
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

sys.path.insert(0, str(Path(__file__).resolve().parent))
import glb_jpeg_fix  # noqa: E402

A = sys.argv[sys.argv.index("--") + 1:]
SRC, CUT, KIND, OUT = A[0], A[1], A[2], A[3]
PREVIEW = A[4] if len(A) > 4 and A[4] else None
SIZE = float(A[5]) if len(A) > 5 else {"snail": 1.5, "bat": 1.6, "beetle": 1.3}[KIND]
TEX = 1024


def log(*a):
	print("CF", *a, flush=True)


# ---------------------------------------------------------------- load
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
for o in bpy.context.scene.objects:
	o.select_set(o.type == "MESH")
bpy.context.view_layer.objects.active = meshes[0]
if len(meshes) > 1:
	bpy.ops.object.join()
obj = bpy.context.view_layer.objects.active
bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
me = obj.data
me.calc_loop_triangles()

V = np.array([v.co[:] for v in me.vertices])
N = np.array([v.normal[:] for v in me.vertices])
nv = len(V)

# the forge's own colours, per vertex (for shading on the hidden side)
old_img = None
for n in obj.active_material.node_tree.nodes:
	if n.type == "TEX_IMAGE":
		old_img = n.image
ow, oh = old_img.size
opx = np.array(old_img.pixels[:]).reshape(oh, ow, 4)[:, :, :3]
uvl = me.uv_layers.active.data
old_col = np.zeros((nv, 3))
cnt = np.zeros(nv)
for l in me.loops:
	u, v = uvl[l.index].uv
	old_col[l.vertex_index] += opx[int(min(oh - 1, max(0, v * oh))), int(min(ow - 1, max(0, u * ow)))]
	cnt[l.vertex_index] += 1
old_col /= np.maximum(cnt, 1)[:, None]

# the picture (Blender stores rows bottom-up)
pic = bpy.data.images.load(CUT)
pw, ph = pic.size
P = np.array(pic.pixels[:]).reshape(ph, pw, 4)[::-1]
alpha = P[:, :, 3]
rgb = P[:, :, :3]
ys, xs = np.where(alpha > 0.5)
bx0, bx1, by0, by1 = xs.min(), xs.max(), ys.min(), ys.max()
log("picture", pw, ph, "creature box", bx0, bx1, by0, by1)


# ---------------------------------------------------------------- 1. line up the camera
def basis(az, el):
	d = np.array([math.sin(az) * math.cos(el), -math.cos(az) * math.cos(el), math.sin(el)])  # towards the camera
	f = -d
	r = np.cross(f, [0, 0, 1.0])
	r /= np.linalg.norm(r)
	u = np.cross(r, f)
	return d, r, u


G = 96
mask_small = None


def screen(az, el):
	"""Vertex positions in picture pixels (orthographic, scaled to the picture's creature height)."""
	d, r, u = basis(az, el)
	sx, sy = V @ r, V @ u
	s = (by1 - by0) / max(1e-6, sy.max() - sy.min())
	px = (sx - (sx.max() + sx.min()) / 2) * s + (bx0 + bx1) / 2
	py = (by0 + by1) / 2 - (sy - (sy.max() + sy.min()) / 2) * s
	return px, py, d


# the picture's outline on a small grid, framed around the creature
fx0, fx1 = bx0 - 0.1 * (bx1 - bx0), bx1 + 0.1 * (bx1 - bx0)
fy0, fy1 = by0 - 0.1 * (by1 - by0), by1 + 0.1 * (by1 - by0)
gy, gx = np.mgrid[0:G, 0:G]
smp_x = np.clip((fx0 + (gx + 0.5) / G * (fx1 - fx0)).astype(int), 0, pw - 1)
smp_y = np.clip((fy0 + (gy + 0.5) / G * (fy1 - fy0)).astype(int), 0, ph - 1)
mask_small = alpha[smp_y, smp_x] > 0.5


def score(az, el):
	px, py, _ = screen(az, el)
	cx = ((px - fx0) / (fx1 - fx0) * G).astype(int)
	cy = ((py - fy0) / (fy1 - fy0) * G).astype(int)
	ok = (cx >= 0) & (cx < G) & (cy >= 0) & (cy < G)
	occ = np.zeros((G, G), bool)
	occ[cy[ok], cx[ok]] = True
	occ = occ | np.roll(occ, 1, 0) | np.roll(occ, -1, 0) | np.roll(occ, 1, 1) | np.roll(occ, -1, 1)
	inter = (occ & mask_small).sum()
	return inter / max(1, (occ | mask_small).sum())


best = (-1, 0, 0)
for el in range(0, 50, 5):
	for az in range(40, 141, 4):  # the forge rebuilds the picture as seen from +X (azimuth 90)
		s = score(math.radians(az), math.radians(el))
		if s > best[0]:
			best = (s, az, el)
_, az0, el0 = best
for el in np.arange(max(0, el0 - 5), el0 + 6, 1.0):
	for az in np.arange(az0 - 6, az0 + 7, 1.5):
		s = score(math.radians(az), math.radians(el))
		if s > best[0]:
			best = (s, az, el)
fit, AZ, EL = best[0], math.radians(best[1]), math.radians(best[2])
log("camera fit", round(fit, 3), "azimuth", round(best[1], 1), "elevation", round(best[2], 1))

# ---------------------------------------------------------------- 2. paint the picture on
px, py, D = screen(AZ, EL)
ix = np.clip(px.astype(int), 0, pw - 1)
iy = np.clip(py.astype(int), 0, ph - 1)
proj = rgb[iy, ix]
inside = alpha[iy, ix] > 0.5
FLIPPED = np.mean(np.sum(N * (V - V.mean(0)), 1)) < 0
if FLIPPED:
	N = -N  # the forge made the surface point inward: flip so 'facing the camera' works
	log("flipped inward-pointing surface directions")
facing = N @ D
bvh = BVHTree.FromObject(obj, bpy.context.evaluated_depsgraph_get())
dvec = Vector(D)
seen = np.zeros(nv, bool)
for i in range(nv):
	if facing[i] < 0.05 or not inside[i]:
		continue
	hit = bvh.ray_cast(Vector(V[i]) + dvec * 0.004, dvec, 10.0)
	seen[i] = hit[0] is None
w = np.clip((facing - 0.05) / 0.3, 0, 1) * seen

# Hidden side: the forge's own colours, corrected to the picture's palette. Where the camera saw a spot
# we know both the forge's colour and the picture's, so we learn how to turn one into the other.
known = w > 0.6
fill = old_col.copy()
if known.sum() > 200:
	for ch in range(3):
		a, b = np.polyfit(old_col[known, ch], proj[known, ch], 1)
		fill[:, ch] = a * old_col[:, ch] + b
	fill = np.clip(fill, 0, 1)
	log("forge colours corrected to the picture's palette")
import os
PAINT = os.environ.get("CF_PAINT", "face")
# "face" (default): the forge's own colours, matched to the picture's colour spread, and the picture
# itself painted only around the face (eyes with pupils, mustache, fangs). Projecting the whole picture
# smears, because the forged shape never lines up exactly with the painting.
W_SEEN = w.copy()
if PAINT in ("face", "raw"):
	ref = rgb[alpha > 0.5]
	# Match brightness and colour separately (YCbCr, like a TV signal) to the picture's, 70% of the way:
	# the forge's colours come out pale; this pulls them toward the painting without smudging them.
	M = np.array([[0.299, 0.587, 0.114], [-0.1687, -0.3313, 0.5], [0.5, -0.4187, -0.0813]])
	src_y, ref_y = old_col @ M.T, ref @ M.T
	out_y = (src_y - src_y.mean(0)) / (src_y.std(0) + 1e-5) * ref_y.std(0) + ref_y.mean(0)
	out_y = src_y + (out_y - src_y) * 0.7
	fill = np.clip(out_y @ np.linalg.inv(M).T, 0, 1)
	w = np.zeros(nv)
col = w[:, None] * proj + (1 - w[:, None]) * fill
log("painted", int(seen.sum()), "of", nv, "corners from the picture")

# A second UV map that projects the picture itself (full sharpness) from the lined-up camera.
proj_uv = me.uv_layers.new(name="proj")
for l in me.loops:
	proj_uv.data[l.index].uv = (px[l.vertex_index] / pw, 1.0 - py[l.vertex_index] / ph)
me.uv_layers.active = me.uv_layers[0]

# ---------------------------------------------------------------- 3. face forward and size
V0 = V.copy()
_dd, _rr, _uu = basis(AZ, EL)
_sx0, _sy0 = V0 @ _rr, V0 @ _uu
_sc = (by1 - by0) / max(1e-6, _sy0.max() - _sy0.min())


def project(pts):
	"""Any points (in the forge's original layout) -> picture pixels, the same way as the fitted camera."""
	qx, qy = pts @ _rr, pts @ _uu
	return ((qx - (_sx0.max() + _sx0.min()) / 2) * _sc + (bx0 + bx1) / 2,
		(by0 + by1) / 2 - (qy - (_sy0.max() + _sy0.min()) / 2) * _sc)


Rz = np.eye(3)
hsv_v = col.max(1)
hsv_s = (col.max(1) - col.min(1)) / np.maximum(col.max(1), 1e-4)
z = V[:, 2]
H0 = z.max() - z.min()
_, r_, u_ = basis(AZ, EL)
sxs = V @ r_
pv = proj.max(1)
ps = (proj.max(1) - proj.min(1)) / np.maximum(pv, 1e-4)
eye = (pv > 0.72) & (ps < 0.42) & (W_SEEN > 0.5) & (z > z.min() + 0.2 * H0)  # pale eyes (white or a little yellow)
if KIND in ("snail", "beetle") and eye.sum() > 10:
	eye &= sxs > np.median(sxs)  # the head is on the picture's right-hand side
if True:
	# The pictures all use one pose: the snail looks to the picture's right, the beetle right and a bit
	# towards us, the bat straight at us. Turn that way to -Y (front).
	dh = np.array([_dd[0], _dd[1], 0.0])
	dh /= max(1e-6, np.linalg.norm(dh))
	rh = np.array([_rr[0], _rr[1], 0.0])
	rh /= max(1e-6, np.linalg.norm(rh))
	toward = {"snail": 0.25, "beetle": 0.5, "bat": 1.5707}[KIND]
	fwd = rh * math.cos(toward) + dh * math.sin(toward)
	ang = -math.pi / 2 - math.atan2(fwd[1], fwd[0])  # turn so it faces -Y
	Rz = np.array([[math.cos(ang), -math.sin(ang), 0], [math.sin(ang), math.cos(ang), 0], [0, 0, 1]])
	V = V @ Rz.T
	N = N @ Rz.T
	log("turned", round(math.degrees(ang)), "degrees to face forward;", int(eye.sum()), "eye corners")
	if PAINT == "face" and eye.sum() > 5:
		ec = V0[eye].mean(0)
		span = (V0.max(0) - V0.min(0)).max()
		dist = np.linalg.norm(V0 - ec, axis=1)
		near = np.clip((0.26 * span - dist) / (0.1 * span), 0, 1)  # 1 around the face, fading out
		w = W_SEEN * near
		col = w[:, None] * proj + (1 - w[:, None]) * fill
		log("painted the face from the picture:", int((w > 0.5).sum()), "corners")
else:
	log("no eyes found, kept the forge's facing")
lo, hi = V.min(0), V.max(0)
shift = np.array([(lo[0] + hi[0]) / 2, (lo[1] + hi[1]) / 2, lo[2]])
V -= shift
ext = V.max(0) - V.min(0)
scale = SIZE / max(ext[0], ext[1])
V *= scale

# Mirrored projection: these creatures are the same on the left and right, so the side the camera
# didn't see gets the picture too, taken from the matching spot on the seen side.
M0 = ((V * np.array([-1.0, 1.0, 1.0])) / scale + shift) @ Rz  # mirror, then back to the forge's layout
wm = np.zeros(nv)
mpx, mpy = project(M0)
for i in range(nv):
	if w[i] > 0.5:
		continue
	loc, nrm, _, dist = bvh.find_nearest(Vector(M0[i]))
	if loc is None or dist > 0.03:
		continue
	nrm = Vector(nrm) * (-1.0 if FLIPPED else 1.0)
	f = nrm.dot(dvec)
	if f < 0.05:
		continue
	ix_, iy_ = int(min(pw - 1, max(0, mpx[i]))), int(min(ph - 1, max(0, mpy[i])))
	if alpha[iy_, ix_] < 0.5:
		continue
	if bvh.ray_cast(loc + dvec * 0.004, dvec, 10.0)[0] is None:
		wm[i] = min(1.0, (f - 0.05) / 0.3)
if PAINT in ("face", "raw"):
	wm *= (w > 0.0) | True
	wm *= 0.0 if PAINT == "raw" else 1.0
	if PAINT == "face":  # only mirror the face (the other eye), not the whole side
		mf = np.zeros(nv)
		if eye.sum() > 5:
			ecm = ((V0[eye].mean(0) - shift) @ Rz.T) * scale if False else None
		wm *= np.clip(1.0 - np.abs(V[:, 1] - V[:, 1].min()) / (0.35 * (V[:, 1].max() - V[:, 1].min())), 0, 1)
log("mirrored the picture onto", int((wm > 0.5).sum()), "more corners")
mirror_uv = me.uv_layers.new(name="proj_m")
for l in me.loops:
	mirror_uv.data[l.index].uv = (mpx[l.vertex_index] / pw, 1.0 - mpy[l.vertex_index] / ph)
me.uv_layers.active = me.uv_layers[0]
for i, v in enumerate(me.vertices):
	v.co = V[i]
me.update()
lo, hi = V.min(0), V.max(0)
W_, L_, H_ = hi[0] - lo[0], hi[1] - lo[1], hi[2] - lo[2]
log("size", round(W_, 2), "x", round(L_, 2), "x", round(H_, 2), "m")

# ---------------------------------------------------------------- 4. sort faces into parts
tris = np.array([t.vertices[:] for t in me.polygons])
FC = V[tris].mean(1)
fcol = col[tris].mean(1)
fv = fcol.max(1)
fs = (fcol.max(1) - fcol.min(1)) / np.maximum(fv, 1e-4)
fh = np.zeros(len(tris))
mx, mn = fcol.max(1), fcol.min(1)
for k in range(len(tris)):
	r, g, b = fcol[k]
	if mx[k] - mn[k] < 1e-5:
		continue
	if mx[k] == r:
		fh[k] = ((g - b) / (mx[k] - mn[k])) % 6
	elif mx[k] == g:
		fh[k] = (b - r) / (mx[k] - mn[k]) + 2
	else:
		fh[k] = (r - g) / (mx[k] - mn[k]) + 4
fh /= 6.0
f_eye = eye[tris].mean(1) > 0.34
f_eye &= fv > 0.6
# glowing bits: saturated, bright orange (lava, amber) / cyan (ice) / violet-pink (spores)
f_glow = (fs > 0.6) & (fv > 0.8) & (((fh > 0.02) & (fh < 0.1)) | ((fh > 0.47) & (fh < 0.56)) | ((fh > 0.74) & (fh < 0.9)))
part = np.zeros(len(tris), int)  # 0 = body
names = ["body"]
hinges = [Vector((0, 0, 0))]


def add_part(name, sel, hinge):
	names.append(name)
	hinges.append(Vector(hinge))
	part[sel & (part == 0)] = len(names) - 1


eyes_xyz = V[eye] if eye.sum() > 5 else np.zeros((0, 3))
if KIND == "snail":
	stalk_any = np.zeros(len(tris), bool)
	if len(eyes_xyz):
		for side in (-1, 1):
			ex = eyes_xyz[(eyes_xyz[:, 0] * side) > 0]
			if len(ex) < 3:
				continue
			e = ex.mean(0)
			near = np.hypot(FC[:, 0] - e[0], FC[:, 1] - e[1]) < 0.11 * L_
			sel = near & (FC[:, 2] > 0.45 * H_)
			stalk_any |= sel
			add_part("soft_stalk_" + ("l" if side < 0 else "r"), sel, (e[0], e[1], 0.5 * H_))
	head = (FC[:, 1] < lo[1] + 0.38 * L_) | (FC[:, 2] < 0.17 * H_)
	add_part("soft_body", head & ~stalk_any, (0, lo[1] + 0.6 * L_, 0.32 * H_))
elif KIND == "bat":
	wx = 0.21 * W_
	for side in (-1, 1):
		sel = (FC[:, 0] * side) > wx
		root = sel & (np.abs(FC[:, 0]) < wx + 0.06 * W_)
		hz = FC[root, 2].mean() if root.any() else 0.55 * H_
		hy = FC[root, 1].mean() if root.any() else 0.0
		add_part("wing_" + ("l" if side < 0 else "r"), sel, (side * wx, hy, hz))
elif KIND == "beetle":
	zc = lo[2] + 0.3 * H_
	low = FC[:, 2] < zc
	# group the low faces into connected pieces (each leg is its own piece once cut below the body)
	idx = np.where(low)[0]
	where = {f: i for i, f in enumerate(idx)}
	parent = list(range(len(idx)))

	def find(x):
		while parent[x] != x:
			parent[x] = parent[parent[x]]
			x = parent[x]
		return x
	vmap = {}
	for i, f in enumerate(idx):
		for vtx in tris[f]:
			if vtx in vmap:
				ra, rb = find(i), find(vmap[vtx])
				if ra != rb:
					parent[ra] = rb
			else:
				vmap[vtx] = i
	groups = {}
	for i, f in enumerate(idx):
		groups.setdefault(find(i), []).append(f)
	cands = []
	for g in groups.values():
		g = np.array(g)
		c = FC[g].mean(0)
		if len(g) < 25 or abs(c[0]) < 0.12 * W_:
			continue  # too small, or in the middle (mandibles, belly)
		cands.append((len(g), c, g))
	cands.sort(key=lambda t: -t[0])
	legs = sorted(cands[:6], key=lambda t: t[1][0])  # left to right
	half = len(legs) // 2
	for side in (-1, 1):
		mine = sorted(legs[:half] if side < 0 else legs[half:], key=lambda t: t[1][1])  # front to back
		for k, (_, c, g) in enumerate(mine[:3]):
			sel = np.zeros(len(tris), bool)
			sel[g] = True
			top = V[tris[g]].reshape(-1, 3)
			hz = top[:, 2].max()
			hv = top[top[:, 2] > hz - 0.03].mean(0)
			add_part(f"leg_{'l' if side < 0 else 'r'}{k}", sel, (hv[0], hv[1], hz))
	log("legs found", len(legs))
log("parts", {n: int((part == i).sum()) for i, n in enumerate(names)})

# ---------------------------------------------------------------- 5. paint into a texture
mat_main = bpy.data.materials.new("skin")
mat_main.use_nodes = True
for m in list(me.materials):
	pass
me.materials.clear()
mat_eye = bpy.data.materials.new("eye")
mat_glow = bpy.data.materials.new("glow")
for m in (mat_eye, mat_glow):
	m.use_nodes = True
me.materials.append(mat_main)
me.materials.append(mat_eye)
me.materials.append(mat_glow)
for k, p in enumerate(me.polygons):
	p.material_index = 1 if f_eye[k] else (2 if f_glow[k] else 0)

# Paint: the picture itself where the camera saw the surface, the spread-out colours elsewhere,
# blended by how squarely each spot faced the camera. Cycles "bakes" that into one texture.
lin = np.where(fill <= 0.04045, fill / 12.92, ((fill + 0.055) / 1.055) ** 2.4)
attr = me.color_attributes.new("painted", "FLOAT_COLOR", "POINT")
wat = me.attributes.new("seen", "FLOAT", "POINT")
for i in range(nv):
	attr.data[i].color = (*lin[i], 1.0)
	wat.data[i].value = float(w[i])
wmat = me.attributes.new("seen_m", "FLOAT", "POINT")
for i in range(nv):
	wmat.data[i].value = float(wm[i] * (1.0 - w[i]))
img = bpy.data.images.new("painted", TEX, TEX)
for m in (mat_main, mat_eye, mat_glow):
	nt = m.node_tree
	for n in list(nt.nodes):
		if n.type not in ("OUTPUT_MATERIAL", "BSDF_PRINCIPLED"):
			nt.nodes.remove(n)
	ca = nt.nodes.new("ShaderNodeVertexColor")
	ca.layer_name = "painted"
	pt = nt.nodes.new("ShaderNodeTexImage")
	pt.image = pic
	pt.interpolation = "Cubic"
	pu = nt.nodes.new("ShaderNodeUVMap")
	pu.uv_map = "proj"
	nt.links.new(pu.outputs["UV"], pt.inputs["Vector"])
	wt = nt.nodes.new("ShaderNodeAttribute")
	wt.attribute_name = "seen"
	mix = nt.nodes.new("ShaderNodeMix")
	mix.data_type = "RGBA"
	nt.links.new(wt.outputs["Fac"], mix.inputs["Factor"])
	nt.links.new(ca.outputs["Color"], mix.inputs["A"])
	nt.links.new(pt.outputs["Color"], mix.inputs["B"])
	pt2 = nt.nodes.new("ShaderNodeTexImage")
	pt2.image = pic
	pt2.interpolation = "Cubic"
	pu2 = nt.nodes.new("ShaderNodeUVMap")
	pu2.uv_map = "proj_m"
	nt.links.new(pu2.outputs["UV"], pt2.inputs["Vector"])
	wt2 = nt.nodes.new("ShaderNodeAttribute")
	wt2.attribute_name = "seen_m"
	mix2 = nt.nodes.new("ShaderNodeMix")
	mix2.data_type = "RGBA"
	nt.links.new(wt2.outputs["Fac"], mix2.inputs["Factor"])
	nt.links.new(mix.outputs["Result"], mix2.inputs["A"])
	nt.links.new(pt2.outputs["Color"], mix2.inputs["B"])
	tex = nt.nodes.new("ShaderNodeTexImage")
	tex.image = img
	nt.nodes.active = tex
	em = nt.nodes.new("ShaderNodeEmission")
	nt.links.new(mix2.outputs["Result"], em.inputs["Color"])
	out = [n for n in nt.nodes if n.type == "OUTPUT_MATERIAL"][0]
	nt.links.new(em.outputs[0], out.inputs["Surface"])
scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.samples = 1
scene.render.bake.margin = 6
bpy.context.view_layer.objects.active = obj
obj.select_set(True)
bpy.ops.object.bake(type="EMIT")
log("baked the painted colours into a", TEX, "picture")
for m, glow in ((mat_main, 0.0), (mat_eye, 0.6), (mat_glow, 1.4)):
	nt = m.node_tree
	for n in list(nt.nodes):
		if n.type not in ("OUTPUT_MATERIAL", "BSDF_PRINCIPLED") and not (n.type == "TEX_IMAGE" and n.image == img):
			nt.nodes.remove(n)
	bsdf = [n for n in nt.nodes if n.type == "BSDF_PRINCIPLED"][0]
	tex = [n for n in nt.nodes if n.type == "TEX_IMAGE"][0]
	out = [n for n in nt.nodes if n.type == "OUTPUT_MATERIAL"][0]
	nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
	nt.links.new(bsdf.outputs[0], out.inputs["Surface"])
	bsdf.inputs["Roughness"].default_value = 0.35 if m is mat_eye else 0.8
	if glow:
		nt.links.new(tex.outputs["Color"], bsdf.inputs["Emission Color"])
		bsdf.inputs["Emission Strength"].default_value = glow
me.color_attributes.remove(attr)
me.attributes.remove(me.attributes["seen"])
me.attributes.remove(me.attributes["seen_m"])
me.uv_layers.remove(me.uv_layers["proj"])
me.uv_layers.remove(me.uv_layers["proj_m"])

# ---------------------------------------------------------------- 6. split into objects, hinges, save
bpy.ops.object.mode_set(mode="EDIT")
bm = bmesh.from_edit_mesh(me)
bm.faces.ensure_lookup_table()
pieces = {}
for pid in range(1, len(names)):
	for f in bm.faces:
		f.select = bool(part[f.index] == pid)
	bmesh.update_edit_mesh(me)
	if not any(part == pid):
		continue
	before = set(bpy.context.scene.objects)
	bpy.ops.mesh.separate(type="SELECTED")
	bm = bmesh.from_edit_mesh(me)
	bm.faces.ensure_lookup_table()
	new = [o for o in bpy.context.scene.objects if o not in before]
	if new:
		pieces[names[pid]] = new[0]
	# after separating, the remaining faces renumber: rebuild the list of part ids from what is left
	keep = [p for p in part if p != pid]
	part = np.array(keep)
bpy.ops.object.mode_set(mode="OBJECT")
obj.name = obj.data.name = "body"
for name, o in pieces.items():
	o.name = o.data.name = name
	h = hinges[names.index(name)]
	o.data.transform(Matrix.Translation(-h))
	o.location = h
if KIND == "snail":
	# The eyes peeking out of the shell's mouth while it hides: a copy of the eyes, small, at the shell's front.
	eyes_obj = [o for o in pieces.values() if o.name.startswith("soft_stalk")]
	if eyes_obj:
		mouth = Vector((0, lo[1] + 0.45 * L_, 0.3 * H_))
		for o in eyes_obj:
			c = o.copy()
			c.data = o.data.copy()
			bpy.context.scene.collection.objects.link(c)
			c.name = c.data.name = "peek_" + o.name[-1]
			c.scale = (0.55, 0.55, 0.55)
			c.location = mouth + Vector((0.08 * (1 if o.name.endswith("r") else -1), 0, -0.12 * H_))
bpy.ops.object.select_all(action="DESELECT")
for o in bpy.context.scene.objects:
	o.select_set(o.type == "MESH")
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_yup=True,
	export_image_format="JPEG", export_image_quality=88)
glb_jpeg_fix.fix(OUT)
log("DONE", OUT, "parts", sorted(o.name for o in bpy.context.scene.objects if o.type == "MESH"))

# ---------------------------------------------------------------- previews
if PREVIEW:
	scene.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items] else "BLENDER_EEVEE"
	scene.render.resolution_x = scene.render.resolution_y = 600
	scene.view_settings.view_transform = "Standard"
	wd = bpy.data.worlds.new("w")
	wd.use_nodes = True
	wd.node_tree.nodes["Background"].inputs[0].default_value = (0.16, 0.14, 0.12, 1)
	wd.node_tree.nodes["Background"].inputs[1].default_value = 1.3
	scene.world = wd
	sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
	sun.data.energy = 3.0
	sun.rotation_euler = (math.radians(50), math.radians(10), math.radians(35))
	scene.collection.objects.link(sun)
	cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
	scene.collection.objects.link(cam)
	scene.camera = cam
	d = max(W_, L_, H_) * 0.85
	t = Vector((0, 0, H_ * 0.45))
	for k, off in {"front": Vector((d * 0.9, -d * 1.8, d * 0.8)), "side": Vector((d * 2.0, 0, d * 0.4)),
			"back": Vector((-d * 1.1, d * 1.5, d * 1.1))}.items():
		cam.location = t + off
		cam.rotation_euler = (t - cam.location).to_track_quat("-Z", "Y").to_euler()
		scene.render.filepath = f"{PREVIEW}_{k}.png"
		bpy.ops.render.render(write_still=True)
