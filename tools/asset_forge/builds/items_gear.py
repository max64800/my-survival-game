# Gear and armor (folder: items), hand-built from the kit, many models in one run.
#   blender --background --factory-startup --python builds/items_gear.py -- [item_id ...]
# Items lie/stand as they would when dropped on the ground; origin bottom-centre; front faces -Y.
import math
import shutil
import sys
from pathlib import Path

import bpy

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
	return {"leather": kit.tex_mat("leather"), "copper": kit.tex_mat("copper"), "shell": kit.tex_mat("stone", "c")}[set_]


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
	if set_ == "copper":
		for z in (0.2, 0.27, 0.34):
			kit.box((0.4, 0.23, 0.012), (0, 0, z), kit.tex_mat("copper", "dark"), bevel=0.003, wobble=0)
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
		kit.tbox("leather", (0.1, 0.22, 0.07), (x, -0.04, 0.035), variant="b", bevel=0.03)
		kit.tcyl("leather", 0.055, 0.16, (x, 0.02, 0.15), verts=12)
		kit.ring(0.058, 0.014, (x, 0.02, 0.22), kit.tex_mat("leather", "dark"), seg=14)
		kit.tbox("leather", (0.105, 0.225, 0.02), (x, -0.04, 0.01), variant="dark", bevel=0.006)
		if set_ == "copper":
			kit.tbox("copper", (0.105, 0.07, 0.06), (x, -0.13, 0.04), bevel=0.015)
			kit.ring(0.06, 0.012, (x, 0.02, 0.12), kit.tex_mat("copper"), seg=14)
		if set_ == "shell":
			shell_spiral((x, -0.09, 0.07), 0.035, rot=(70, 0, 0))
			kit.ring(0.06, 0.016, (x, 0.02, 0.12), kit.tex_mat("stone", "c"), seg=14)


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
	Built to sit on lantern()'s carry ring (top of the ring's tube line at z=0.37): an iron S-hook (lower ring
	through the carry ring, a short shank, upper ring) and a folded leather belt loop through the upper ring.
	Alone it is "lantern_hip_hook" (the game hangs it above the code-built lantern); with lantern() it is the item."""
	iron = kit.tex_mat("iron")
	r, tube = 0.022, 0.008
	low = 0.37 - 0.009 - tube + r  # the lower ring rests on the carry ring (its bottom inside the carry ring's hole)
	kit.ring(r, tube, (0, 0, low), iron, rot=(0, 90, 0), seg=12)
	kit.box((0.014, 0.014, 0.04), (0, 0, low + r + 0.016), iron, bevel=0.003, wobble=0)
	up = low + r + 0.036 + r - tube
	kit.ring(r, tube, (0, 0, up), iron, rot=(90, 0, 0), seg=12)
	# The belt loop: a leather strap through the upper ring, folded up both sides (the belt goes through the fold).
	top = up + r - tube
	kit.tbox("leather", (0.034, 0.08, 0.012), (0, 0, top - 0.006), variant="dark", bevel=0.003)
	for y in (-0.034, 0.034):
		kit.tbox("leather", (0.034, 0.012, 0.094), (0, y, top + 0.035), variant="dark", bevel=0.003)
	kit.tbox("leather", (0.034, 0.08, 0.012), (0, 0, top + 0.076), variant="dark", bevel=0.003)
	kit.cylinder(0.008, 0.008, (0, -0.043, top + 0.05), kit.tex_mat("copper"), rot=(90, 0, 0), verts=8, bevel=0)  # a rivet


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
