# Gear and armor (folder: items), hand-built from the kit, many models in one run.
#   blender --background --factory-startup --python builds/items_gear.py -- [item_id ...]
# Items lie/stand as they would when dropped on the ground; origin bottom-centre; front faces -Y.
import math
import shutil
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kit  # noqa: E402

GAME = Path(__file__).resolve().parents[3]
OUT = GAME / "assets" / "models" / "items"
JOUR = GAME / "journey" / "3d" / "v2_hand_built" / "items"


def dome(loc, r, h, material, open_bottom=True, segs=16):
	"""Half a ball (helmets, caps, shoulder pads)."""
	bpy.ops.mesh.primitive_uv_sphere_add(segments=segs, ring_count=8, radius=1, location=loc)
	o = bpy.context.object
	for v in o.data.vertices:
		if v.co.z < 0:
			v.co.z = 0
	o.scale = (r, r * 1.08, h)
	bpy.ops.object.transform_apply(scale=True)
	kit._finish(o, material, 0, 0)
	for p in o.data.polygons:
		p.use_smooth = True
	return o


def mat_of(set_):
	return {"leather": kit.tex_mat("leather"), "copper": kit.tex_mat("copper"), "bronze": kit.tex_mat("bronze"), "shell": kit.tex_mat("stone", "c")}[set_]


def shell_spiral(loc, r, rot=(0, 0, 0)):
	"""A snail-shell spiral boss: shrinking rings stacked into a cone."""
	for k in range(4):
		kit.ring(r * (1 - k * 0.22), r * 0.16, (loc[0], loc[1], loc[2] + k * r * 0.18), kit.tex_mat("stone", "b"), rot=rot, seg=16)


def helm(set_):
	m = mat_of(set_)
	dome((0, 0, 0.04), 0.14, 0.15, m)
	kit.ring(0.145, 0.022, (0, 0, 0.045), kit.tex_mat("leather", "dark") if set_ == "leather" else m, seg=20)
	if set_ == "leather":
		for k in range(6):
			a = 2 * math.pi * k / 6
			kit.box((0.006, 0.006, 0.12), (math.cos(a) * 0.1, math.sin(a) * 0.1, 0.11), kit.mat("rope"), bevel=0, wobble=0,
				rot=(math.sin(a) * 40, -math.cos(a) * 40, 0))
		kit.tbox("leather", (0.12, 0.05, 0.015), (0, -0.14, 0.06), variant="dark", rot=(-25, 0, 0))
	else:
		kit.box((0.035, 0.03, 0.12), (0, -0.15, 0.06), m, bevel=0.008, wobble=0)
		kit.box((0.02, 0.29, 0.03), (0, 0, 0.18), m, bevel=0.006, wobble=0)
		for k in range(8):
			a = 2 * math.pi * k / 8
			kit.rivet((math.cos(a) * 0.15, math.sin(a) * 0.155, 0.06), r=0.012)
		if set_ == "shell":
			for s in (-1, 1):
				shell_spiral((s * 0.13, 0, 0.12), 0.05, rot=(0, s * 70, 0))


def chest_armor(set_):
	m = mat_of(set_)
	kit.taper(0.34, 0.2, 0.42, 0.22, 0.4, (0, 0, 0.0), m, bevel=0.03)
	kit.tbox("leather", (0.36, 0.23, 0.05), (0, 0, 0.12), variant="dark", bevel=0.01)
	kit.tbox("iron", (0.06, 0.02, 0.05), (0, -0.12, 0.12), bevel=0.005)
	if set_ in ("copper", "bronze"):
		for z in (0.2, 0.27, 0.34):
			kit.box((0.4, 0.23, 0.012), (0, 0, z), kit.tex_mat(set_, "dark"), bevel=0.003, wobble=0)
	for s in (-1, 1):
		dome((s * 0.17, 0, 0.36), 0.085, 0.07, m)
	if set_ == "shell":
		shell_spiral((0, -0.11, 0.24), 0.08, rot=(90, 0, 0))
	if set_ == "leather":
		for z in (0.22, 0.32):
			kit.box((0.3, 0.006, 0.006), (0, -0.114, z), kit.mat("rope"), bevel=0, wobble=0)


def legs(set_):
	m = mat_of(set_)
	kit.tbox("leather", (0.34, 0.16, 0.08), (0, 0, 0.36), variant="dark", bevel=0.015)
	for s in (-1, 1):
		kit.cone(0.08, 0.065, 0.34, (s * 0.085, 0, 0.17), m, verts=12, bevel=0.01)
		if set_ != "leather":
			plate = kit.cone(0.075, 0.062, 0.28, (s * 0.085, -0.03, 0.17), m, verts=12, bevel=0.008)
			plate.scale = (1, 0.7, 1)
			for z in (0.08, 0.26):
				kit.ring(0.078, 0.012, (s * 0.085, 0, z), kit.tex_mat("leather", "dark"), seg=14)
		if set_ == "shell":
			shell_spiral((s * 0.085, -0.075, 0.2), 0.035, rot=(90, 0, 0))


def boots(set_):
	m = mat_of(set_) if set_ != "shell" else kit.tex_mat("leather")
	for s in (-1, 1):
		x = s * 0.056  # the pair stands together, soles touching (nothing floats apart)
		y = s * 0.04  # one boot a little ahead, so the two top rings don't cut into each other (no shimmer)
		kit.tbox("leather", (0.1, 0.22, 0.07), (x, y - 0.04, 0.035), variant="b", bevel=0.03)
		kit.tcyl("leather", 0.055, 0.16, (x, y + 0.02, 0.15), verts=12)
		kit.ring(0.058, 0.014, (x, y + 0.02, 0.22), kit.tex_mat("leather", "dark"), seg=14)
		kit.tbox("leather", (0.105, 0.225, 0.02), (x, y - 0.04, 0.01), variant="dark", bevel=0.006)
		if set_ in ("copper", "bronze"):
			kit.tbox(set_, (0.105, 0.07, 0.06), (x, y - 0.13, 0.04), bevel=0.015)
			kit.ring(0.06, 0.012, (x, y + 0.02, 0.12), kit.tex_mat(set_), seg=14)
		if set_ == "shell":
			shell_spiral((x, y - 0.09, 0.07), 0.035, rot=(70, 0, 0))
			kit.ring(0.06, 0.016, (x, y + 0.02, 0.12), kit.tex_mat("stone", "c"), seg=14)


# ---- Bronze: its own look (F697 step 7, owner picked Option B: assets/concepts/dwarf/dwarf_wearing_bronze_b.png) ----
# Warm gold hammered plate, bold knot bands only on the rims, ONE big knot medallion on the chest.
# Textures cut from a painted sheet by tools/art/cut_bronze_textures.py.
kit.TILE.update({"bronzeplate": 0.2, "bronzeknot": 1.0, "bronzemedal": 1.0})


def bz(variant=None):
	return kit.tex_mat("bronzeplate", variant, metal=0.6, rough=0.42)


def ellipse_loop(cx, cy, rx, ry, n=28):
	return [(cx + rx * math.cos(2 * math.pi * i / n), cy + ry * math.sin(2 * math.pi * i / n)) for i in range(n)]


def rrect_loop(cx, cy, hx, hy, rc, steps=5):
	"""A rounded rectangle, counter-clockwise seen from above."""
	pts = []
	for k, (sx, sy) in enumerate(((1, -1), (1, 1), (-1, 1), (-1, -1))):
		ox, oy = cx + sx * (hx - rc), cy + sy * (hy - rc)
		for j in range(steps):
			a = math.radians(-90 + 90 * k + 90 * j / (steps - 1))
			pts.append((ox + rc * math.cos(a), oy + rc * math.sin(a)))
	return pts


def knot_band(loop, z0, z1, thick=0.02, variant="a"):
	"""A rim band with the knot pattern running round it (the strip repeats a whole number of times, so no seam)."""
	m = kit.tex_mat("bronzeknot", variant, metal=0.6, rough=0.42)
	n = len(loop)
	inner = []
	for i, (x, y) in enumerate(loop):
		(xa, ya), (xb, yb) = loop[i - 1], loop[(i + 1) % n]
		tx, ty = xb - xa, yb - ya
		ln = math.hypot(tx, ty)
		inner.append((x - ty / ln * thick, y + tx / ln * thick))
	seg = [math.dist(loop[i], loop[(i + 1) % n]) for i in range(n)]
	reps = max(1, round(sum(seg) / ((z1 - z0) * 4)))  # the strip picture is 4x wider than tall
	us = [0.0]
	for s in seg:
		us.append(us[-1] + s / sum(seg) * reps)
	bm = bmesh.new()
	ob = [bm.verts.new((x, y, z0)) for x, y in loop]
	ot = [bm.verts.new((x, y, z1)) for x, y in loop]
	ib = [bm.verts.new((x, y, z0)) for x, y in inner]
	it = [bm.verts.new((x, y, z1)) for x, y in inner]
	uv = bm.loops.layers.uv.new("UVMap")
	for i in range(n):
		j = (i + 1) % n
		u0, u1 = us[i], us[i + 1]
		for vs, uvs in (
			((ob[i], ob[j], ot[j], ot[i]), ((u0, 0), (u1, 0), (u1, 1), (u0, 1))),  # outside: the knots
			((ib[j], ib[i], it[i], it[j]), ((u1, 0.03), (u0, 0.03), (u0, 0.0), (u1, 0.0))),  # inside: plain rim
			((ot[i], ot[j], it[j], it[i]), ((u0, 0.99), (u1, 0.99), (u1, 0.97), (u0, 0.97))),  # top edge
			((ib[i], ib[j], ob[j], ob[i]), ((u0, 0.03), (u1, 0.03), (u1, 0.01), (u0, 0.01))),  # bottom edge
		):
			f = bm.faces.new(vs)
			for lp, c in zip(f.loops, uvs):
				lp[uv].uv = c
	me = bpy.data.meshes.new("knot_band")
	bm.to_mesh(me)
	bm.free()
	o = bpy.data.objects.new("knot_band", me)
	bpy.context.scene.collection.objects.link(o)
	me.materials.append(m)
	for p in me.polygons:
		p.use_smooth = True
	return o


def medallion(loc, r, depth):
	"""The big round knot medallion, facing front (-Y); its back sinks into the plate behind it."""
	m = kit.tex_mat("bronzemedal", "a", metal=0.6, rough=0.4)
	x, y, z = loc
	n = 32
	bm = bmesh.new()
	ring = [(math.cos(2 * math.pi * i / n), math.sin(2 * math.pi * i / n)) for i in range(n)]
	fr = [bm.verts.new((x + r * c, y, z + r * s)) for c, s in ring]
	bk = [bm.verts.new((x + r * c, y + depth, z + r * s)) for c, s in ring]
	fc, bc = bm.verts.new((x, y - depth * 0.15, z)), bm.verts.new((x, y + depth, z))  # front bulges a little
	uv = bm.loops.layers.uv.new("UVMap")
	tuv = [(0.5 + 0.47 * c, 0.5 + 0.47 * s) for c, s in ring]
	for i in range(n):
		j = (i + 1) % n
		for vs, uvs in (((fc, fr[j], fr[i]), ((0.5, 0.5), tuv[j], tuv[i])),
				((bc, bk[i], bk[j]), ((0.5, 0.5), tuv[i], tuv[j])),
				((fr[i], fr[j], bk[j], bk[i]), (tuv[i], tuv[j], tuv[j], tuv[i]))):
			f = bm.faces.new(vs)
			for lp, c in zip(f.loops, uvs):
				lp[uv].uv = c
	bm.normal_update()
	me = bpy.data.meshes.new("medallion")
	bm.to_mesh(me)
	bm.free()
	o = bpy.data.objects.new("medallion", me)
	bpy.context.scene.collection.objects.link(o)
	me.materials.append(m)
	return o


def crest(cz, ry, rz, w=0.03, up=0.028):
	"""A thick ridge running front to back over a helmet dome (follows the dome, ends sink into it)."""
	verts, faces, k = [], [], 14
	for i in range(k + 1):
		t = 0.25 + (math.pi - 0.5) * i / k
		y, z = -ry * math.cos(t), cz + rz * math.sin(t)
		ny, nz = y / ry ** 2, (z - cz) / rz ** 2
		ln = math.hypot(ny, nz)
		ny, nz = ny / ln, nz / ln
		for sx in (-1, 1):
			for d in (-0.012, up):
				verts.append((sx * w / 2, y + ny * d, z + nz * d))
	for i in range(k):
		a, b = 4 * i, 4 * (i + 1)
		faces += [(a + 1, a + 3, b + 3, b + 1), (a, b, b + 2, a + 2), (a + 2, b + 2, b + 3, a + 3), (a, a + 1, b + 1, b)]
	faces += [(0, 2, 3, 1), (4 * k, 4 * k + 1, 4 * k + 3, 4 * k + 2)]
	o = kit._mesh_obj("crest", verts, faces, bz("a"), smooth=False)
	bpy.context.view_layer.objects.active = o
	o.select_set(True)
	bpy.ops.object.mode_set(mode="EDIT")
	bpy.ops.mesh.select_all(action="SELECT")
	bpy.ops.mesh.normals_make_consistent(inside=False)
	bpy.ops.object.mode_set(mode="OBJECT")
	return o


def front_dome(loc, r, h, material):
	"""A dome bulging forward (-Y): knee cups, toe caps. (dome() bakes its spot into the mesh, so turn it about loc.)"""
	o = dome(loc, r, h, material)
	t = Matrix.Translation(loc)
	o.data.transform(t @ Matrix.Rotation(math.radians(90), 4, "X") @ t.inverted())
	return o


def shell_arc(rx, ry, a0, a1, z0, z1, thick, material, n=8):
	"""A curved plate that follows a round rim (cheek and nose guards); a0..a1 in degrees, -90 = front."""
	verts, faces = [], []
	for i in range(n + 1):
		a = math.radians(a0 + (a1 - a0) * i / n)
		c, s_ = math.cos(a), math.sin(a)
		for d in (0, thick):
			verts += [((rx + d) * c, (ry + d) * s_, z0), ((rx + d) * c, (ry + d) * s_, z1)]
	for i in range(n):
		a, b = 4 * i, 4 * (i + 1)
		faces += [(a + 2, b + 2, b + 3, a + 3), (a, a + 1, b + 1, b), (a + 1, a + 3, b + 3, b + 1), (a, b, b + 2, a + 2)]
	faces += [(0, 2, 3, 1), (4 * n, 4 * n + 1, 4 * n + 3, 4 * n + 2)]
	o = kit._mesh_obj("guard", verts, faces, material, smooth=True)
	bpy.context.view_layer.objects.active = o
	o.select_set(True)
	bpy.ops.object.mode_set(mode="EDIT")
	bpy.ops.mesh.select_all(action="SELECT")
	bpy.ops.mesh.normals_make_consistent(inside=False)
	bpy.ops.object.mode_set(mode="OBJECT")
	o.select_set(False)
	return o


def helm_bronze():
	cz, r, h = 0.05, 0.14, 0.19  # a taller dome than the copper helm
	dome((0, 0, cz), r, h, bz("a"))
	knot_band(ellipse_loop(0, 0, r + 0.008, r * 1.08 + 0.008), 0.03, 0.085, variant="a")
	crest(cz, r * 1.08, h)
	rx, ry = r + 0.004, r * 1.08 + 0.004  # guards bite 4 mm into the rim band (touching, never floating)
	shell_arc(rx, ry, -97, -83, 0.0, 0.135, 0.02, bz("c"), n=3)  # nose guard
	for s in (-1, 1):
		mid = -90 + s * 55
		shell_arc(rx, ry, mid - 17, mid + 17, 0.0, 0.1, 0.018, bz("b"))  # cheek guards
		a = math.radians(mid)
		kit.rivet(((rx + 0.02) * math.cos(a), (ry + 0.02) * math.sin(a), 0.05), bz("dark"), r=0.011)
	for k in range(10):
		a = 2 * math.pi * (k + 0.5) / 10
		kit.rivet((math.cos(a) * 0.136, math.sin(a) * 0.147, 0.1), bz("dark"), r=0.01)


def mail_bronze():
	kit.taper(0.34, 0.2, 0.42, 0.22, 0.4, (0, 0, 0.0), bz("a"), bevel=0.03)
	knot_band(rrect_loop(0, 0, 0.178, 0.108, 0.04), 0.0, 0.06, variant="b")  # bottom rim
	knot_band(rrect_loop(0, 0, 0.213, 0.118, 0.04), 0.345, 0.395, variant="b")  # neck rim
	kit.tbox("leather", (0.36, 0.23, 0.045), (0, 0, 0.115), variant="dark", bevel=0.01)  # belt
	kit.box((0.05, 0.02, 0.045), (0, -0.12, 0.115), bz("dark"), bevel=0.006, wobble=0)  # buckle
	medallion((0, -0.128, 0.25), 0.082, 0.03)
	for s in (-1, 1):
		dome((s * 0.19, 0, 0.38), 0.11, 0.09, bz("c"))  # big domed shoulder plates
		knot_band(ellipse_loop(s * 0.19, 0, 0.113, 0.11 * 1.08 + 0.003, n=24), 0.37, 0.405, thick=0.015, variant="c")
		for dy in (-0.05, 0.05):
			kit.rivet((s * 0.19, dy, 0.462), bz("dark"), r=0.011)


def greaves_bronze():
	kit.tbox("leather", (0.34, 0.16, 0.08), (0, 0, 0.36), variant="dark", bevel=0.015)
	knot_band(rrect_loop(0, 0, 0.176, 0.086, 0.03), 0.335, 0.385, variant="a")  # knot band round the top
	for s in (-1, 1):
		x = s * 0.085
		kit.cone(0.08, 0.065, 0.34, (x, 0, 0.17), kit.tex_mat("leather", "b"), verts=12, bevel=0.01)  # padded leg
		knot_band(ellipse_loop(x, 0, 0.085, 0.085, n=20), 0.0, 0.04, thick=0.015, variant="a")  # ankle rim
		shin = kit.cone(0.076, 0.07, 0.15, (x, -0.02, 0.115), bz("a"), verts=12, bevel=0.008)
		shin.scale = (1, 0.7, 1)
		thigh = kit.cone(0.072, 0.067, 0.07, (x, -0.02, 0.29), bz("b"), verts=12, bevel=0.008)
		thigh.scale = (1, 0.7, 1)
		front_dome((x, -0.062, 0.215), 0.05, 0.024, bz("c"))  # round knee cup
		for sx in (-1, 1):
			kit.rivet((x + sx * 0.03, -0.074, 0.15), bz("dark"), r=0.009)


def boots_bronze():
	for s in (-1, 1):
		x, y = s * 0.056, s * 0.04  # pair stands together, one a little ahead (as the other boots)
		kit.tbox("leather", (0.11, 0.232, 0.032), (x, y - 0.04, 0.016), variant="dark", bevel=0.008)  # thick sole
		for k in range(4):  # tread ridges on the sole's sides
			kit.tbox("leather", (0.116, 0.012, 0.014), (x, y - 0.13 + k * 0.06, 0.012), variant="dark", bevel=0.003)
		kit.tbox("leather", (0.1, 0.22, 0.065), (x, y - 0.04, 0.062), variant="b", bevel=0.03)
		kit.tcyl("leather", 0.055, 0.16, (x, y + 0.02, 0.17), verts=12)
		kit.ring(0.058, 0.014, (x, y + 0.02, 0.25), kit.tex_mat("leather", "dark"), seg=14)
		knot_band(ellipse_loop(x, y + 0.02, 0.059, 0.059, n=18), 0.1, 0.145, thick=0.012, variant="c")  # ankle band
		front_dome((x, y - 0.13, 0.058), 0.054, 0.03, bz("b"))  # thick toe cap
		kit.rivet((x, y - 0.158, 0.075), bz("dark"), r=0.01)


def satchel():
	kit.tbox("leather", (0.3, 0.14, 0.26), (0, 0, 0.13), bevel=0.03, wobble=0.006)
	kit.tbox("leather", (0.31, 0.03, 0.17), (0, -0.075, 0.18), variant="dark", rot=(-6, 0, 0), bevel=0.02)
	kit.tbox("iron", (0.05, 0.015, 0.04), (0, -0.095, 0.11), bevel=0.004)
	kit.tbox("leather", (0.1, 0.06, 0.12), (0.17, 0, 0.1), variant="b", bevel=0.015)
	strap = kit.ring(0.14, 0.012, (0, 0.05, 0.26), kit.tex_mat("leather", "dark"), rot=(90, 0, 0), seg=20)
	strap.scale = (1.1, 1, 0.7)


def lantern(big=False):
	s = 1.3 if big else 1.0
	iron = kit.tex_mat("iron")
	kit.tcyl("iron", 0.09 * s, 0.03 * s, (0, 0, 0.015 * s), verts=8)
	for k in range(4):
		a = math.pi / 4 + k * math.pi / 2
		kit.box((0.018 * s, 0.018 * s, 0.2 * s), (math.cos(a) * 0.075 * s, math.sin(a) * 0.075 * s, 0.13 * s), iron, bevel=0.003, wobble=0)
	kit.cylinder(0.065 * s, 0.17 * s, (0, 0, 0.12 * s), kit.mat("water_light", -0.4, rough=0.1, glow=0.05), verts=8, bevel=0)
	kit.crystal_cluster((0, 0, 0.04 * s), 0.45 * s, kit.glow("crystal_amber", 0.8), seed=2, n=4)
	kit.cone(0.1 * s, 0.03 * s, 0.07 * s, (0, 0, 0.265 * s), iron, verts=8)
	kit.ring(0.04 * s, 0.009 * s, (0, 0, 0.33 * s), iron, rot=(90, 0, 0), seg=12)
	if big:
		for x in (-0.06, 0.06):
			kit.tbox("leather", (0.03, 0.015, 0.3), (x, 0.11, 0.17), variant="dark", bevel=0.004)


def hip_hook():
	"""F562 (owner, Nov 21): the belt hook that hangs the lantern on the dwarf's hip, so both hands are free.
	Built to sit on lantern()'s carry ring (top of the ring's tube line at z=0.37): one iron ring through the carry
	ring and a short folded leather belt loop through that ring (the belt runs front to back through the fold).
	Owner, Nov 22: the first one (an S-hook, 20 cm) hung the lantern down by his ankles; this one is ~10 cm.
	Alone it is "lantern_hip_hook" (the game hangs it above the code-built lantern); with lantern() it is the item."""
	iron = kit.tex_mat("iron")
	r, tube = 0.022, 0.008
	low = 0.37 - 0.009 - tube + r  # the ring rests on the carry ring (its bottom inside the carry ring's hole)
	kit.ring(r, tube, (0, 0, low), iron, rot=(0, 90, 0), seg=12)  # its hole faces sideways (x)
	# The belt loop: a leather strap through the ring (along x), folded up both sides of the belt.
	top = low + r - tube
	kit.tbox("leather", (0.08, 0.034, 0.012), (0, 0, top - 0.006), variant="dark", bevel=0.003)
	for x in (-0.034, 0.034):
		kit.tbox("leather", (0.012, 0.034, 0.07), (x, 0, top + 0.029), variant="dark", bevel=0.003)
	kit.tbox("leather", (0.08, 0.034, 0.012), (0, 0, top + 0.064), variant="dark", bevel=0.003)
	kit.cylinder(0.008, 0.008, (0.044, 0, top + 0.04), kit.tex_mat("copper"), rot=(0, 90, 0), verts=8, bevel=0)  # a rivet


def spore_mask():
	face = kit.gem((0, 0, 0.09), (0.12, 0.06, 0.1), kit.tex_mat("leather"), seed=4)
	kit.soft(face, 1)
	for s in (-1, 1):
		kit.tcyl("iron", 0.045, 0.06, (s * 0.06, -0.08, 0.07), rot=(90, 0, 0), verts=12)
		kit.cylinder(0.035, 0.01, (s * 0.06, -0.112, 0.07), kit.mat("charcoal", 0.3), rot=(90, 0, 0), verts=12, bevel=0)
	for s in (-1, 1):
		kit.cylinder(0.025, 0.012, (s * 0.05, -0.05, 0.14), kit.mat("water_light", -0.3, rough=0.1), rot=(90, 0, 0), verts=12, bevel=0)
	kit.ring(0.13, 0.01, (0, 0.03, 0.1), kit.tex_mat("leather", "dark"), rot=(0, 0, 0), seg=18)


def prospectors_lens():
	kit.ring(0.08, 0.016, (0, 0, 0.1), kit.tex_mat("copper"), rot=(90, 0, 0), seg=20)
	kit.cylinder(0.075, 0.008, (0, 0, 0.1), kit.mat("water_light", rough=0.05, glow=0.08), rot=(90, 0, 0), verts=20, bevel=0)
	kit.tcyl("wood", 0.016, 0.14, (0, 0, -0.03), verts=8)
	kit.cylinder(0.022, 0.03, (0, 0, 0.03), kit.tex_mat("copper"), verts=8, bevel=0.004)


def war_horn():
	verts, faces = [], []
	rings, sides = 12, 12
	for i in range(rings):
		t = i / (rings - 1)
		rad = 0.012 + 0.06 * t ** 1.5
		a = t * 2.2
		cx, cz = math.sin(a) * 0.17 - 0.05, 0.03 + (1 - math.cos(a)) * 0.1
		nx, nz = math.cos(a), math.sin(a)
		for k in range(sides):
			b = 2 * math.pi * k / sides
			verts.append((cx - nz * math.cos(b) * rad * 0, cx * 0 + math.sin(b) * rad, 0))
			verts[-1] = (cx + math.cos(b) * rad * nz, math.sin(b) * rad, cz - math.cos(b) * rad * nx + rad)
	for i in range(rings - 1):
		for k in range(sides):
			p, q = i * sides + k, i * sides + (k + 1) % sides
			faces.append((p, q, q + sides, p + sides))
	kit._mesh_obj("horn", verts, faces, kit.mat("bone", -0.05), smooth=True)
	for t in (0.35, 0.75):
		i = int(t * (rings - 1))
		cx = sum(v[0] for v in verts[i * sides:(i + 1) * sides]) / sides
		cz = sum(v[2] for v in verts[i * sides:(i + 1) * sides]) / sides
		rad = 0.012 + 0.06 * (i / (rings - 1)) ** 1.5
		kit.ring(rad + 0.004, 0.008, (cx, 0, cz), kit.tex_mat("iron"), rot=(0, 90 - math.degrees(t * 2.2), 0), seg=14)


def waterskin(kind):
	tint = {"empty": 0.0, "dirty": -0.1, "clean": 0.05}[kind]
	body = kit.gem((0, 0, 0.09), (0.13, 0.08, 0.09 if kind != "empty" else 0.04), kit.tex_mat("leather", "b" if tint >= 0 else "dark"), seed=3)
	kit.soft(body, 2)
	kit.tcyl("leather", 0.025, 0.06, (0.13, 0, 0.12 if kind != "empty" else 0.06), rot=(0, -60, 0), verts=10, variant="dark")
	kit.cylinder(0.02, 0.03, (0.16, 0, 0.14 if kind != "empty" else 0.08), kit.tex_mat("wood", "c"), rot=(0, -60, 0), verts=8, bevel=0.003)
	kit.ring(0.1, 0.008, (0, 0, 0.1 if kind != "empty" else 0.05), kit.tex_mat("rope"), seg=18).scale = (1.3, 1, 1)
	if kind == "dirty":
		kit.gem((-0.05, -0.07, 0.07), (0.03, 0.01, 0.02), kit.mat("moss", -0.3), seed=8)


def water_bucket():
	kit.tcyl("wood", 0.15, 0.2, (0, 0, 0.1), verts=12)
	kit.ring(0.14, 0.02, (0, 0, 0.21), kit.tex_mat("wood", "c"), seg=20)
	for z in (0.04, 0.15):
		kit.ring(0.152, 0.012, (0, 0, z), kit.tex_mat("iron"), seg=20)
	kit.water((0, 0, 0.2), 0.135, ripples=1)
	kit.ring(0.15, 0.008, (0, 0, 0.22), kit.tex_mat("iron"), rot=(90, 0, 0), seg=16).scale = (1, 1, 0.6)


BUILD = {
	"lantern": lambda: lantern(False), "lantern_back": lambda: lantern(True), "satchel": satchel,
	"lantern_hip": lambda: (lantern(False), hip_hook()), "lantern_hip_hook": hip_hook,
	"spore_mask": spore_mask, "prospectors_lens": prospectors_lens, "war_horn": war_horn, "water_bucket": water_bucket,
	"waterskin_empty": lambda: waterskin("empty"), "waterskin_dirty": lambda: waterskin("dirty"),
	"waterskin_clean": lambda: waterskin("clean"),
	"cap_leather": lambda: helm("leather"), "helm_copper": lambda: helm("copper"), "helm_shell": lambda: helm("shell"),
	"tunic_leather": lambda: chest_armor("leather"), "mail_copper": lambda: chest_armor("copper"),
	"plate_shell": lambda: chest_armor("shell"),
	"trousers_leather": lambda: legs("leather"), "greaves_copper": lambda: legs("copper"), "greaves_shell": lambda: legs("shell"),
	"boots_leather": lambda: boots("leather"), "boots_copper": lambda: boots("copper"), "boots_shell": lambda: boots("shell"),
	# bronze has its own pieces (F697 step 7, Option B look). The helm is made the fountain way now
	# (builds/bronze_armour_trellis.py); mail, greaves, boots move there too once TRELLIS has made them.
	"mail_bronze": mail_bronze, "greaves_bronze": greaves_bronze, "boots_bronze": boots_bronze,
}

ids = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
ids = ids or list(BUILD)
OUT.mkdir(parents=True, exist_ok=True)
JOUR.mkdir(parents=True, exist_ok=True)
for item_id in ids:
	kit.reset()
	BUILD[item_id]()
	out = OUT / f"{item_id}.glb"
	kit.save(str(out), str(JOUR / f"{item_id}.png"))
	shutil.copy(out, JOUR / f"{item_id}.glb")
