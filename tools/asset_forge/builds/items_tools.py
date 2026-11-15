# Tools and weapons (folder: items), hand-built from the kit, many models in one run.
#   blender --background --factory-startup --python builds/items_tools.py -- [item_id ...]
# Every tool stands straight up: grip end at the origin, handle along +Z (Godot +Y), flat side facing -Y (Godot +Z).
# Writes assets/models/items/<id>.glb and a journey copy + preview in journey/3d/v2_hand_built/items/.
# Owner's 2nd review: shaped handles (taper, leather grip, end knob, metal langets), rough knapped stone heads
# with crossed lashing, real arrow fletching, a crossbow with a trigger, a shield with a back handle.
import math
import random
import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kit  # noqa: E402

GAME = Path(__file__).resolve().parents[3]
OUT = GAME / "assets" / "models" / "items"
JOUR = GAME / "journey" / "3d" / "v2_hand_built" / "items"


def hm(m, variant=None):
	return kit.tex_mat({"stone": "stone", "copper": "copper", "silver": "silver"}[m], variant)


def fr(axis, a0, a1, c0, c1, s0, s1, material, bevel=0.005):
	"""A block that changes size along one axis (blades, spikes, bow arms).
	axis "x": from x=a0 to x=a1; c = (y, z) centre; s = (thickness y, height z).
	axis "z": from z=a0 to z=a1; c = (x, y) centre; s = (width x, thickness y)."""
	def ring(a, c, s):
		u, v = s[0] / 2, s[1] / 2
		if axis == "x":
			return [(a, c[0] - u, c[1] - v), (a, c[0] + u, c[1] - v), (a, c[0] + u, c[1] + v), (a, c[0] - u, c[1] + v)]
		return [(c[0] - u, c[1] - v, a), (c[0] + u, c[1] - v, a), (c[0] + u, c[1] + v, a), (c[0] - u, c[1] + v, a)]
	v = ring(a0, c0, s0) + ring(a1, c1, s1)
	f = [(0, 1, 2, 3), (7, 6, 5, 4), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)]
	if axis == "x" and a1 < a0:
		f = [tuple(reversed(x)) for x in f]
	o = kit._mesh_obj("part", v, f, material, smooth=False)
	if bevel:
		mod = o.modifiers.new("bevel", "BEVEL")
		mod.width, mod.segments = bevel, 1
	return o


def stoneify(o, seed):
	"""Make a stone part look knapped: chipped, uneven faces."""
	kit.roughen(o, amount=0.013, cuts=2, seed=seed)  # F54: chipped, not perfect
	for m in list(o.modifiers):
		o.modifiers.remove(m)
	return o


def handle(length, r=0.024, cap="iron", grip=(0.03, 0.2), langet=None):
	"""A shaped haft: slightly tapered, leather-wrapped grip, end knob, optional metal strips (langets) under the head."""
	kit.cone(r, r * 0.85, length, (0, 0, length / 2), kit.tex_mat("wood", "b"), verts=10, bevel=0.004)
	kit.rope_wrap((0, 0, 0), r + 0.003, grip[0], grip[1], 8, thick=0.008, material=kit.tex_mat("leather", "dark"))
	kit.ring(r + 0.004, 0.007, (0, 0, grip[1] + 0.01), kit.tex_mat("iron"), seg=10)
	knob = kit.tex_mat(cap) if cap != "wood" else kit.tex_mat("wood", "dark")
	kit.cylinder(r + 0.008, 0.035, (0, 0, 0.018), knob, verts=10, bevel=0.006)
	kit.gem((0, 0, 0.0), (r + 0.004, r + 0.004, 0.012), knob, seed=3)
	if langet:
		z1, mat = langet
		for s in (-1, 1):
			kit.box((0.016, 0.006, 0.16), (0, s * (r * 0.85 + 0.003), z1 - 0.08), mat, bevel=0.002, wobble=0)
			kit.rivet((0, s * (r * 0.85 + 0.008), z1 - 0.13), r=0.007)


def cross_lash(z, w, r=0.03, thick=0.009):
	"""Rope tying a stone head to the haft: wraps below and above, and an X across front and back."""
	kit.rope_wrap((0, 0, 0), r, z - 0.07, z - 0.03, 4, thick=thick)
	kit.rope_wrap((0, 0, 0), r, z + 0.03, z + 0.06, 3, thick=thick)
	for y in (-1, 1):
		yy = y * (r + 0.012)
		kit.rope((-w, yy, z - 0.035), (w, yy, z + 0.04), r=thick)
		kit.rope((w, yy, z - 0.035), (-w, yy, z + 0.04), r=thick)


# ---------- the shapes ----------

def pickaxe(m):
	z = 0.66
	stone = m == "stone"
	handle(0.72, langet=None if stone else (z - 0.06, hm(m, "dark")))
	if stone:
		for s in (-1, 1):
			stoneify(fr("x", s * 0.02, s * 0.27, (0, z), (0, z - 0.07), (0.075, 0.09), (0.02, 0.022), hm(m)), 4 + s)
		cross_lash(z, 0.05)
	else:
		kit.tbox(m, (0.1, 0.075, 0.11), (0, 0, z), bevel=0.014)
		for s in (-1, 1):
			fr("x", s * 0.045, s * 0.3, (0, z), (0, z - 0.06), (0.065, 0.085), (0.016, 0.018), hm(m))
		kit.ring(0.034, 0.012, (0, 0, z - 0.065), hm(m, "dark"), seg=12)
		kit.ring(0.034, 0.012, (0, 0, z + 0.065), hm(m, "dark"), seg=12)


def axe(m):
	z = 0.62
	stone = m == "stone"
	handle(0.72, langet=None if stone else (z - 0.07, hm(m, "dark")))
	if stone:
		stoneify(fr("x", 0.0, 0.2, (0, z), (0, z - 0.01), (0.06, 0.12), (0.016, 0.21), hm(m)), 7)
		stoneify(fr("x", 0.0, -0.06, (0, z), (0, z), (0.06, 0.1), (0.05, 0.07), hm(m)), 8)
		cross_lash(z, 0.04)
	else:
		kit.tbox(m, (0.07, 0.05, 0.13), (0, 0, z), bevel=0.012)
		fr("x", 0.03, 0.19, (0, z), (0, z - 0.01), (0.045, 0.1), (0.008, 0.22), hm(m))
		fr("x", -0.03, -0.08, (0, z), (0, z), (0.045, 0.07), (0.04, 0.05), hm(m))


def great_axe(m):
	z = 1.2
	stone = m == "stone"
	handle(1.35, r=0.034, grip=(0.03, 0.4), langet=None if stone else (z - 0.08, hm(m, "dark")))
	kit.rope_wrap((0, 0, 0), 0.036, 0.62, 0.7, 4, thick=0.008, material=kit.tex_mat("leather", "dark"))
	if stone:
		for s in (-1, 1):
			stoneify(fr("x", s * 0.02, s * 0.28, (0, z), (0, z - 0.02), (0.07, 0.15), (0.016, 0.34), hm(m)), 9 + s)
		cross_lash(z, 0.05, r=0.04)
	else:
		kit.tbox(m, (0.1, 0.07, 0.18), (0, 0, z), bevel=0.014)
		for s in (-1, 1):
			fr("x", s * 0.045, s * 0.28, (0, z), (0, z - 0.02), (0.055, 0.14), (0.008, 0.36), hm(m))
			fr("x", s * 0.24, s * 0.285, (0, z - 0.02), (0, z - 0.02), (0.012, 0.36), (0.006, 0.34), hm(m, "c"), bevel=0.002)
		kit.cone(0.035, 0.0, 0.12, (0, 0, z + 0.15), hm(m), verts=6)
		kit.ring(0.042, 0.014, (0, 0, z - 0.1), hm(m, "dark"), seg=12)


def sword(m):
	stone = m == "stone"
	kit.cone(0.022, 0.02, 0.17, (0, 0, 0.1), kit.tex_mat("wood", "b"), verts=8)
	grip = kit.tex_mat("rope") if m == "copper" else kit.tex_mat("leather", "dark")
	kit.rope_wrap((0, 0, 0), 0.025, 0.03, 0.175, 10, thick=0.0085, material=grip)  # F53: tight, the whole handle
	kit.gem((0, 0, 0.02), (0.035, 0.035, 0.03), kit.tex_mat("iron" if stone else m), seed=2)
	if stone:
		guard = stoneify(kit.tbox("stone", (0.2, 0.06, 0.045), (0, 0, 0.19), variant="dark", bevel=0), 3)
		r = random.Random(5)
		verts, faces = [], []
		levels = 9
		for i in range(levels):
			t = i / (levels - 1)
			z = 0.21 + t * 0.52
			half = (0.05 * (1 - t) + 0.006) * r.uniform(0.75, 1.15)
			off = r.uniform(-0.008, 0.008)
			th = 0.032 * (1 - 0.5 * t)
			verts += [(off - half, -th / 2, z), (off + half, -th / 2, z), (off + half * 0.4, th / 2, z), (off - half * 0.4, th / 2, z)]
		for i in range(levels - 1):
			for k in range(4):
				a, b = i * 4 + k, i * 4 + (k + 1) % 4
				faces.append((a, b, b + 4, a + 4))
		faces.append((3, 2, 1, 0))
		faces.append(tuple(range((levels - 1) * 4, levels * 4)))
		kit.roughen(kit._mesh_obj("blade", verts, faces, kit.tex_mat("stone", "c"), smooth=False), amount=0.004, cuts=1, seed=14)
		return
	kit.tbox(m, (0.22, 0.05, 0.035), (0, 0, 0.19), bevel=0.01)
	for s in (-1, 1):
		kit.gem((s * 0.11, 0, 0.19), (0.02, 0.02, 0.02), kit.tex_mat(m, "dark"), seed=4)
	fr("z", 0.205, 0.64, (0, 0), (0, 0), (0.08, 0.02), (0.06, 0.012), hm(m))
	fr("z", 0.64, 0.75, (0, 0), (0, 0), (0.06, 0.012), (0.006, 0.004), hm(m))
	fr("z", 0.21, 0.6, (0, -0.01), (0, -0.006), (0.012, 0.004), (0.012, 0.004), kit.tex_mat(m, "dark"), bevel=0)


def mace(m):
	z = 0.56
	handle(0.6, langet=None if m == "stone" else (z - 0.08, hm(m, "dark")))
	if m == "stone":
		stoneify(kit.gem((0, 0, z), (0.08, 0.08, 0.09), kit.tex_mat("stone"), seed=5), 5)
		cross_lash(z - 0.04, 0.04)
		for k in range(5):
			a = 2 * math.pi * k / 5
			kit.cone(0.02, 0.0, 0.07, (math.cos(a) * 0.08, math.sin(a) * 0.08, z), kit.tex_mat("stone", "dark"),
				rot=(-math.sin(a) * 90, math.cos(a) * 90, 0), verts=5)
	else:
		kit.tcyl(m, 0.05, 0.16, (0, 0, z), verts=10)
		for k in range(6):
			a = 2 * math.pi * k / 6
			kit.box((0.06, 0.016, 0.15), (math.cos(a) * 0.06, math.sin(a) * 0.06, z), hm(m), bevel=0.004, wobble=0,
				rot=(0, 0, math.degrees(a)))
		kit.cone(0.03, 0.0, 0.07, (0, 0, z + 0.11), hm(m), verts=8)


def great_maul(m):
	z = 1.22
	stone = m == "stone"
	handle(1.3, r=0.032, grip=(0.03, 0.4), langet=None if stone else (z - 0.09, hm(m, "dark")))
	kit.rope_wrap((0, 0, 0), 0.034, 0.6, 0.68, 4, thick=0.008, material=kit.tex_mat("leather", "dark"))
	if stone:
		stoneify(kit.tbox("stone", (0.36, 0.18, 0.17), (0, 0, z), bevel=0), 6)
		cross_lash(z, 0.06, r=0.04)
	else:
		fr("x", -0.18, 0.18, (0, z), (0, z), (0.16, 0.16), (0.16, 0.16), hm(m), bevel=0.02)
		for s in (-1, 1):
			fr("x", s * 0.17, s * 0.21, (0, z), (0, z), (0.18, 0.18), (0.13, 0.13), hm(m, "dark"), bevel=0.01)
			kit.ring(0.11, 0.014, (s * 0.12, 0, z), hm(m, "dark"), rot=(0, 90, 0), seg=4).rotation_euler.x = math.radians(45)
		for y in (-1, 1):
			kit.cone(0.03, 0.0, 0.06, (0, y * 0.1, z), hm(m), rot=(-y * 90, 0, 0), verts=6)
		kit.cone(0.03, 0.0, 0.08, (0, 0, z + 0.12), hm(m), verts=6)


def spear(m):
	stone = m == "stone"
	kit.cone(0.024, 0.019, 1.26, (0, 0, 0.63), kit.tex_mat("wood", "b"), verts=10)
	kit.rope_wrap((0, 0, 0), 0.026, 0.45, 0.68, 15, thick=0.0085, material=kit.tex_mat("rope") if m == "copper" else kit.tex_mat("leather", "dark"))
	if m == "copper":  # F52: tight binding under the head too
		kit.rope_wrap((0, 0, 0), 0.025, 1.12, 1.2, 6, thick=0.0075, material=kit.tex_mat("rope"))
	kit.cone(0.02, 0.0, 0.07, (0, 0, -0.01), kit.tex_mat("iron"), rot=(180, 0, 0), verts=6)
	kit.ring(0.026, 0.008, (0, 0, 0.04), kit.tex_mat("iron"), seg=10)
	if stone:
		stoneify(fr("z", 1.22, 1.3, (0, 0), (0, 0), (0.03, 0.024), (0.08, 0.026), hm(m)), 11)
		stoneify(fr("z", 1.3, 1.43, (0, 0), (0, 0), (0.08, 0.026), (0.008, 0.008), hm(m)), 12)
		cross_lash(1.25, 0.03, r=0.026)
		return
	kit.cone(0.026, 0.02, 0.1, (0, 0, 1.2), hm(m, "dark"), verts=8)
	for s in (-1, 1):
		fr("x", s * 0.02, s * 0.06, (0, 1.2), (0, 1.19), (0.014, 0.025), (0.01, 0.012), hm(m, "dark"), bevel=0.002)
	fr("z", 1.25, 1.31, (0, 0), (0, 0), (0.026, 0.02), (0.085, 0.018), hm(m))
	fr("z", 1.31, 1.45, (0, 0), (0, 0), (0.085, 0.018), (0.004, 0.004), hm(m))
	fr("z", 1.26, 1.42, (0, -0.009), (0, -0.003), (0.01, 0.004), (0.006, 0.003), hm(m, "dark"), bevel=0)


def build_hammer():
	"""F49: a builder's mallet: wooden head with iron plates on both striking faces and an iron band, no spikes."""
	handle(0.7, cap="wood", langet=(0.6, kit.tex_mat("iron")))
	z = 0.64
	fr("x", -0.13, 0.13, (0, z), (0, z), (0.13, 0.13), (0.13, 0.13), kit.tex_mat("wood", "c"), bevel=0.02)
	for s in (-1, 1):
		fr("x", s * 0.13, s * 0.15, (0, z), (0, z), (0.135, 0.135), (0.125, 0.125), kit.tex_mat("iron", "dark"), bevel=0.008)
		for (dy, dz) in ((-0.04, -0.04), (0.04, -0.04), (-0.04, 0.04), (0.04, 0.04)):
			kit.rivet((s * 0.152, dy, z + dz), kit.tex_mat("iron"), r=0.009)
		kit.box((0.03, 0.14, 0.14), (s * 0.08, 0, z), kit.tex_mat("iron"), bevel=0.004, wobble=0)
	kit.box((0.04, 0.012, 0.11), (0, -0.068, z), kit.tex_mat("iron"), bevel=0.003, wobble=0)
	kit.box((0.04, 0.012, 0.11), (0, 0.068, z), kit.tex_mat("iron"), bevel=0.003, wobble=0)


def crossbow(m):
	stone = m == "stone"
	wood, dark = kit.tex_mat("wood", "b"), kit.tex_mat("wood", "dark")
	metal = kit.tex_mat("iron") if stone else hm(m)
	# Stock: a shaped butt that narrows into the tiller, with a groove rail on top.
	fr("z", 0.0, 0.2, (0, 0.01), (0, 0.0), (0.09, 0.09), (0.06, 0.06), dark, bevel=0.012)
	fr("z", 0.2, 0.64, (0, 0.0), (0, 0.0), (0.06, 0.06), (0.05, 0.05), wood, bevel=0.01)
	kit.box((0.012, 0.012, 0.42), (0, -0.031, 0.42), kit.mat("charcoal", 0.2), bevel=0, wobble=0)
	kit.box((0.064, 0.02, 0.14), (0, 0, 0.62), metal, bevel=0.004, wobble=0)
	# Trigger lever under the stock and the nut that holds the string.
	fr("z", 0.15, 0.36, (0, 0.04), (0, 0.035), (0.014, 0.014), (0.012, 0.012), metal, bevel=0.003)
	kit.ring(0.03, 0.006, (0, 0.04, 0.33), metal, rot=(90, 0, 90), seg=10)
	kit.cylinder(0.02, 0.07, (0, -0.03, 0.4), kit.mat("bone"), rot=(0, 90, 0), verts=10, bevel=0.003)
	# Bow: thick in the middle, thinner and curving back at the tips; metal plates bind it to the stock.
	arm = kit.tex_mat("wood", "c") if stone else hm(m)
	for s in (-1, 1):
		fr("x", s * 0.03, s * 0.2, (0, 0.62), (0.0, 0.58), (0.05, 0.05), (0.035, 0.035), arm)
		fr("x", s * 0.2, s * 0.33, (0, 0.58), (0.03, 0.52), (0.035, 0.035), (0.02, 0.02), arm)
		fr("x", s * 0.33, s * 0.37, (0.03, 0.52), (0.0, 0.53), (0.02, 0.02), (0.015, 0.015), arm)
	kit.rope_wrap((0, 0.62), 0.045, -0.06, 0.06, 4, thick=0.009, axis="x")
	for s in (-1, 1):  # F50: a tight string, tip to nut, in straight lines
		kit.rope((s * 0.365, 0.0, 0.53), (0, -0.03, 0.415), r=0.0055)
		kit.ring(0.014, 0.004, (s * 0.355, 0.0, 0.53), kit.tex_mat("rope"), rot=(0, 90, 0), seg=8)
	# Stirrup at the front for cocking with a foot.
	kit.ring(0.06, 0.011, (0, 0, 0.71), metal, rot=(90, 0, 0), seg=14)
	if not stone:
		for s in (-1, 1):
			kit.rivet((s * 0.05, -0.03, 0.62), r=0.01)


def shield(m):
	r, z = 0.34, 0.345
	kit.tcyl("wood", r - 0.02, 0.05, (0, 0, z), rot=(90, 0, 0), verts=24)
	rim = kit.tex_mat("wood", "dark") if m == "stone" else hm(m)
	kit.ring(r - 0.01, 0.025, (0, 0, z), rim, rot=(90, 0, 0), seg=28)
	boss = kit.tex_mat("iron") if m == "stone" else hm(m)
	kit.cylinder(0.08, 0.03, (0, -0.035, z), boss, rot=(90, 0, 0), verts=14, bevel=0.01)
	kit.gem((0, -0.06, z), (0.055, 0.03, 0.055), boss, seed=7)
	for k in range(10):
		a = 2 * math.pi * k / 10
		kit.rivet((math.cos(a) * (r - 0.05), -0.03, z + math.sin(a) * (r - 0.05)), r=0.012)
	if m == "stone":
		for dz in (0.12, -0.12):
			kit.box((0.6, 0.012, 0.05), (0, -0.026, z + dz), kit.tex_mat("iron"), bevel=0.004, wobble=0)
	shield_back(r, z, hm(m) if m != "stone" else kit.tex_mat("iron"))


def shield_back(r, z, metal):
	"""F51 (like a Spartan shield): two cross battens, a big leather forearm strap with a buckle in the middle,
	and an upright hand grip near the rim."""
	for dz in (0.11, -0.11):
		kit.box((0.56, 0.025, 0.06), (0, 0.036, z + dz), kit.tex_mat("wood", "dark"), bevel=0.006, wobble=0)
	kit.box((0.16, 0.035, 0.24), (-0.04, 0.05, z), kit.tex_mat("leather", "dark"), bevel=0.01, wobble=0)
	kit.box((0.2, 0.04, 0.06), (-0.04, 0.062, z), kit.tex_mat("leather", "a"), bevel=0.006, wobble=0)
	kit.ring(0.03, 0.007, (-0.04, 0.085, z), metal, rot=(90, 0, 0), seg=4)
	for dz in (-0.1, 0.1):
		kit.rivet((-0.11, 0.07, z + dz), metal, r=0.009)
		kit.rivet((0.03, 0.07, z + dz), metal, r=0.009)
	gx = r * 0.62
	for dz in (-0.1, 0.1):
		kit.box((0.04, 0.05, 0.04), (gx, 0.05, z + dz), metal, bevel=0.005, wobble=0)
	kit.cylinder(0.022, 0.24, (gx, 0.08, z), kit.tex_mat("wood", "b"), verts=8, bevel=0.003)
	kit.rope_wrap((gx, 0.08), 0.024, z - 0.08, z + 0.08, 9, thick=0.007, material=kit.tex_mat("leather", "dark"))


def bolt(tip):
	"""F48: a long shaft with rope bindings, three real feathers, a copper socket and a big crystal tip
	(stone grey, ember red, rime blue, blight green, glow amber)."""
	L = 0.46
	kit.cone(0.0095, 0.0085, L, (0, 0, L / 2), kit.tex_mat("wood", "c"), verts=8, bevel=0)
	kit.rope_wrap((0, 0, 0), 0.011, 0.14, 0.16, 3, thick=0.0035, material=kit.tex_mat("rope"))
	kit.rope_wrap((0, 0, 0), 0.011, 0.015, 0.035, 3, thick=0.0035, material=kit.tex_mat("rope"))
	feather = kit.mat("bone", 0.05, rough=0.9)
	quill = kit.mat("wood_dark", 0.1)
	for k in range(3):
		a = math.radians(k * 120 + 15)
		cx, cy = math.cos(a), math.sin(a)
		# a feather: a long leaf shape with a ragged edge, standing out from the shaft
		outline = [(0.0, 0.03), (0.012, 0.035), (0.03, 0.06), (0.038, 0.09), (0.034, 0.12), (0.022, 0.14), (0.0, 0.15)]
		r_ = random.Random(k + 3)
		verts = []
		for (rad, zz) in outline:
			rr = 0.009 + rad * (1 + r_.uniform(-0.12, 0.12))
			verts.append((cx * rr, cy * rr, zz))
		n = len(verts)
		faces = [tuple(range(n)), tuple(reversed(range(n)))]
		kit._mesh_obj("feather", verts, faces, feather, smooth=False)
		kit.box((0.003, 0.003, 0.12), (cx * 0.0105, cy * 0.0105, 0.09), quill, bevel=0, wobble=0)
	z = L - 0.01
	kit.cone(0.013, 0.016, 0.04, (0, 0, z + 0.015), kit.tex_mat("copper", "b"), verts=8, bevel=0.002)
	kit.ring(0.016, 0.004, (0, 0, z), kit.tex_mat("copper", "dark"), seg=10)
	if tip == "thumper":
		kit.tcyl("iron", 0.026, 0.04, (0, 0, z + 0.05), verts=10)
		kit.gem((0, 0, z + 0.08), (0.032, 0.032, 0.025), kit.tex_mat("iron"), seed=1)
		return
	if tip == "fang":
		bone_fang((0, 0, z + 0.035), 0.1, (0, 0, 0))
		return
	colours = {"ember": ("fire", 0.8), "rime": ("crystal_blue", 0.6), "blight": ("sprout", 0.7), "glow": ("crystal_amber", 0.7)}
	if tip in colours:
		g = kit.glow(*colours[tip])
		kit.crystal((0, 0, z + 0.03), 0.02, 0.09, g, sides=6)
		return
	head = kit.tex_mat("stone", "b") if tip == "stone" else kit.tex_mat("iron", "c")
	o = fr("z", z + 0.03, z + 0.06, (0, 0), (0, 0), (0.02, 0.012), (0.05, 0.014), head, bevel=0.002)
	o2 = fr("z", z + 0.06, z + 0.12, (0, 0), (0, 0), (0.05, 0.014), (0.004, 0.004), head, bevel=0.002)
	if tip == "stone":
		stoneify(o, 13)
		stoneify(o2, 15)


def bone_fang(base, length, tilt, s=1.0):
	"""A curved white fang pointing out from base."""
	o = kit.cone(0.022 * s, 0.002, length, base, kit.mat("bone"), rot=tilt, verts=8, bevel=0)
	kit.soft(o, 1)
	return o


def pickaxe_fang():
	z = 0.66
	handle(0.72)
	stoneify(kit.tbox("stone", (0.1, 0.075, 0.1), (0, 0, z), bevel=0), 21)
	for s_ in (-1, 1):
		bone_fang((s_ * 0.14, 0, z - 0.02), 0.26, (0, s_ * 100, 0), s=1.3)
	cross_lash(z, 0.05)


def shield_shell():
	r, z = 0.34, 0.345
	kit.tcyl("wood", r - 0.02, 0.05, (0, 0, z), rot=(90, 0, 0), verts=24, variant="dark")
	kit.ring(r - 0.01, 0.025, (0, 0, z), kit.tex_mat("leather", "dark"), rot=(90, 0, 0), seg=28)
	shell = kit.tex_mat("stone", "c")
	for k in range(6):
		a = 2 * math.pi * k / 6
		kit.ring(0.09, 0.03, (math.cos(a) * 0.18, -0.035, z + math.sin(a) * 0.18), shell, rot=(90, 0, 0), seg=14)
		kit.ring(0.05, 0.022, (math.cos(a) * 0.18, -0.05, z + math.sin(a) * 0.18), kit.tex_mat("stone", "b"), rot=(90, 0, 0), seg=12)
	for k in range(4):
		kit.ring(0.1 - k * 0.022, 0.028 - k * 0.004, (0, -0.04 - k * 0.018, z), shell, rot=(90, 0, 0), seg=16)
	shield_back(r, z, kit.tex_mat("iron"))


BUILD = {}
for m in ("stone", "copper", "silver"):
	BUILD[f"pickaxe_{m}"] = (lambda m=m: pickaxe(m))
	BUILD[f"axe_{m}"] = (lambda m=m: axe(m))
	BUILD[f"axe_2h_{m}"] = (lambda m=m: great_axe(m))
	BUILD[f"sword_{m}"] = (lambda m=m: sword(m))
	BUILD[f"mace_{m}"] = (lambda m=m: mace(m))
	BUILD[f"mace_2h_{m}"] = (lambda m=m: great_maul(m))
	BUILD[f"spear_{m}"] = (lambda m=m: spear(m))
	BUILD[f"crossbow_{m}"] = (lambda m=m: crossbow(m))
	BUILD[f"shield_{m}"] = (lambda m=m: shield(m))
BUILD["build_hammer"] = build_hammer
BUILD["pickaxe_fang"] = pickaxe_fang
BUILD["shield_shell"] = shield_shell
for t in ("stone", "metal", "thumper", "ember", "rime", "blight", "glow", "fang"):
	BUILD[f"bolt_{t}"] = (lambda t=t: bolt(t))

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
