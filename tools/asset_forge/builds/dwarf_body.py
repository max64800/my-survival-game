# The player dwarf's body, hand-built around the game's real skeleton (Claude 3, Nov 16, 2026; MODEL-RULES Rule 1).
#
#   blender --background --factory-startup --python tools/asset_forge/builds/dwarf_body.py -- <skeleton.json> <out.glb> [preview.png]
#
# <skeleton.json> comes from tools/asset_forge/dwarf_skeleton_dump.gd: every bone of the game dwarf, shaped by
# DwarfProportions and standing in its rest pose (a T-pose), in the player's look space (metres, feet at y=0, facing -Z).
# Every part below is placed from those bones, so it fits the skeleton exactly; the game binds it to the same pose
# (DwarfRig.dwarf_rest_poses), so it stands exactly as built and every animation bends it along.
#
# What the approved picture shows (assets/concepts/dwarf/dwarf_happy_apose.png, dwarf_turnaround.png):
# - ~4.8 heads tall (without the beard); a very wide barrel body; short thick legs; thick hairy forearms; big hands.
# - A big round head, bald on top, a ring of thick red-brown hair from the temples round the back; bushy brows; a big
#   round nose; rosy cheeks; ears showing; a wide grin under a curling moustache.
# - A huge beard from the cheeks to the belly in THREE braids: the side braids to the chest, the middle one to the belly,
#   each with a copper ring.
# - An off-white linen shirt with short rolled sleeves, hem at the hips; baggy brown knee shorts with rolled cuffs; cloth
#   wraps from mid-calf over the feet.
#
# Round 1 = the grey (plain-colour) shape, for the owner's OK before it is sculpted, painted and baked.
import json
import math
import random
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import creature_kit as ck  # noqa: E402

ARGS = sys.argv[sys.argv.index("--") + 1:]
SKEL, OUT = ARGS[0], ARGS[1]
PREVIEW = ARGS[2] if len(ARGS) > 2 and ARGS[2] else None
ck.reset()
R = random.Random(11)

DATA = json.load(open(SKEL, encoding="utf-8"))["bones"]


def L2B(p):
	"""Look space (Godot: y up, facing -Z) -> Blender (z up, facing -Y; the .glb then faces +Z, the game turns it)."""
	return Vector((-p[0], p[2], p[1]))


BONE = {b["name"]: L2B(b["origin"]) for b in DATA}


def B(name):
	return BONE[name].copy()


def P(x, y, z):
	"""A point given in look space (x = the dwarf's left is -x, y up, z back) -> Blender."""
	return L2B((x, y, z))


# ---------------------------------------------------------------- plain colours (grey stage)
skin = ck.color("skin", (0.86, 0.6, 0.48), rough=0.7)
shirt = ck.color("shirt", (0.86, 0.8, 0.68), rough=0.9)
shorts = ck.color("shorts", (0.46, 0.31, 0.2), rough=0.9)
wraps = ck.color("wraps", (0.8, 0.72, 0.58), rough=0.9)
hair = ck.color("hair", (0.72, 0.33, 0.14), rough=0.8)
copper = ck.color("copper", (0.78, 0.46, 0.26), rough=0.4, metal=0.6)
eye_white = ck.color("eye", (0.95, 0.92, 0.86), rough=0.3)
pupil = ck.color("pupil", (0.08, 0.05, 0.04), rough=0.3)

UP = Vector((0, 0, 1))
FWD = Vector((0, -1, 0))  # Blender: the dwarf faces -Y


def ring_loft(name, rings, material, sides=20, subsurf=1):
	"""Rings stacked up the body: (height y, half-width, front depth, back depth) in look space -> a smooth tube."""
	out = []
	for y, hw, front, back in rings:
		cz = (back - front) / 2.0  # look z of the centre (+ = towards the back)
		out.append((P(0, y, cz), hw, (front + back) / 2.0))
	return ck.loft(name, out, material, sides=sides, subsurf=subsurf, up=Vector((0, 1, 0)))


def tube(name, pts, radii, material, sides=14, subsurf=1, flat=1.0):
	return ck.loft(name, [(p, r, r * flat) for p, r in zip(pts, radii)], material, sides=sides, subsurf=subsurf)


# ---------------------------------------------------------------- the shirt: a barrel body (belly out front, back deep
# enough to wrap the shoulder joints, which sit ~18 cm behind the spine in the shaped skeleton)
# Sizes measured on the picture against the dwarf's real height (1.13 m): body ~0.5 m across, hem at ~0.4 m.
ring_loft("shirt_body", [
	(0.38, 0.23, 0.22, 0.17), (0.45, 0.25, 0.27, 0.18), (0.55, 0.26, 0.3, 0.19), (0.66, 0.26, 0.28, 0.2),
	(0.76, 0.26, 0.22, 0.22), (0.84, 0.25, 0.17, 0.22), (0.89, 0.21, 0.12, 0.19), (0.92, 0.12, 0.07, 0.11)], shirt, sides=24)
for s in (-1, 1):
	side = "l" if s < 0 else "r"
	sh, el = B(f"upperarm_{side}"), B(f"lowerarm_{side}")
	ck.blob(tuple(sh + Vector((0, 0, 0.0))), (0.13, 0.13, 0.12), shirt, seed=3 + s, jitter=0.03)  # shoulder
	d = (el - sh)
	tube(f"sleeve_{side}", [sh - d * 0.05, sh + d * 0.3, sh + d * 0.55], [0.12, 0.118, 0.112], shirt)
	ck.loft(f"cuff_{side}", [(sh + d * 0.48, 0.112, 0.112), (sh + d * 0.56, 0.134, 0.134), (sh + d * 0.64, 0.128, 0.128), (sh + d * 0.68, 0.1, 0.1)],
		shirt, sides=16, caps=(False, False))  # a rolled cuff (open ends: no flat discs)

# ---------------------------------------------------------------- arms and hands (skin)
for s in (-1, 1):
	side = "l" if s < 0 else "r"
	sh, el, wr = B(f"upperarm_{side}"), B(f"lowerarm_{side}"), B(f"hand_{side}")
	tube(f"upperarm_{side}", [sh + (el - sh) * 0.4, el], [0.085, 0.082], skin)
	tube(f"forearm_{side}", [el - (wr - el) * 0.08, el + (wr - el) * 0.45, wr], [0.083, 0.088, 0.07], skin)  # thick forearms
	mid = B(f"middle_01_{side}")
	palm_c = wr + (mid - wr) * 0.5
	ck.blob(tuple(palm_c), (0.15, 0.1, 0.055), skin, seed=7 + s, jitter=0.02)  # a big palm overlapping the wrist and the finger roots
	for f in ("index", "middle", "ring", "pinky", "thumb"):
		chain = [f"{f}_01_{side}", f"{f}_02_{side}", f"{f}_03_{side}"] + ([] if f == "thumb" else [f"{f}_04_leaf_{side}"])  # a short thumb
		pts = [B(c) for c in chain if c in BONE]
		pts[0] = pts[0].lerp(palm_c, 0.35)  # each finger starts inside the palm
		if len(pts) < 2:
			continue
		r0 = 0.03 if f == "thumb" else 0.026
		tube(f"{f}_{side}", pts, [r0 * (1 - 0.12 * k) for k in range(len(pts))], skin, sides=10)

# ---------------------------------------------------------------- shorts, legs, wraps, feet
for s in (-1, 1):
	side = "l" if s < 0 else "r"
	hip, knee, ank = B(f"thigh_{side}"), B(f"calf_{side}"), B(f"foot_{side}")
	d = knee - hip
	tube(f"shorts_leg_{side}", [hip + UP * 0.03, hip + d * 0.5, knee - UP * 0.03], [0.14, 0.15, 0.145], shorts)
	ck.loft(f"shorts_cuff_{side}", [(knee - UP * 0.0, 0.14, 0.14), (knee - UP * 0.03, 0.158, 0.158), (knee - UP * 0.055, 0.15, 0.15), (knee - UP * 0.065, 0.12, 0.12)],
		shorts, sides=18, caps=(False, False))
	tube(f"calf_{side}", [knee, knee + (ank - knee) * 0.5, ank], [0.085, 0.09, 0.075], skin)
	tube(f"wrap_{side}", [knee + (ank - knee) * 0.4, ank - UP * 0.02], [0.098, 0.09], wraps, sides=16)
	ball = B(f"ball_{side}")
	toe = B(f"ball_leaf_{side}") if f"ball_leaf_{side}" in BONE else ball + FWD * 0.06
	# a chunky wrapped foot, its sole on the floor, its top reaching up into the leg wrap (no gap at the ankle)
	ck.loft(f"foot_{side}", [(Vector((ank.x, ank.y + 0.075, 0.065)), 0.065, 0.06), (Vector((ank.x, ank.y, 0.085)), 0.088, 0.085),
		(Vector((ball.x, ball.y, 0.055)), 0.088, 0.055), (Vector((toe.x, toe.y - 0.02, 0.04)), 0.07, 0.038)], wraps, sides=16, up=UP)
ring_loft("shorts_seat", [(0.3, 0.27, 0.2, 0.15), (0.38, 0.29, 0.25, 0.18), (0.44, 0.29, 0.27, 0.18)], shorts, sides=24)

# ---------------------------------------------------------------- the head
head = B("Head")
skull_c = head + Vector((0, -0.03, 0.18))  # the round head sits high: the shoulders are above the head bone
ck.blob(tuple(skull_c), (0.15, 0.15, 0.16), skin, seed=21, jitter=0.02)               # the round head, bald on top
ck.blob(tuple(skull_c + Vector((0, -0.13, -0.05))), (0.058, 0.055, 0.05), skin, seed=22, jitter=0.03)  # the big round nose
for s in (-1, 1):
	ck.blob(tuple(skull_c + Vector((s * 0.085, -0.115, -0.05))), (0.045, 0.035, 0.04), skin, seed=23 + s, jitter=0.03)  # cheeks
	ck.blob(tuple(skull_c + Vector((s * 0.152, 0.0, -0.01))), (0.025, 0.035, 0.05), skin, seed=25 + s, jitter=0.03)    # ears
	e = skull_c + Vector((s * 0.055, -0.13, 0.02))
	ck.blob(tuple(e), (0.024, 0.02, 0.024), eye_white, seed=27, jitter=0.0)
	ck.blob(tuple(e + Vector((0, -0.017, 0))), (0.012, 0.008, 0.012), pupil, seed=28, jitter=0.0)
	ck.loft(f"brow_{s}", [(skull_c + Vector((s * 0.02, -0.14, 0.06)), 0.02, 0.016), (skull_c + Vector((s * 0.06, -0.142, 0.065)), 0.03, 0.02),
		(skull_c + Vector((s * 0.1, -0.12, 0.055)), 0.02, 0.015)], hair, sides=10)                                      # bushy brows
# the ring of hair: from the temples round the back, thick and lumpy, the top stays bald
for k in range(13):
	a = math.radians(-115 + k * (230 / 12))  # 0 = the back of the head
	c = skull_c + Vector((math.sin(a) * 0.14, math.cos(a) * 0.13, 0.02 + 0.02 * math.cos(a)))
	ck.blob(tuple(c), (0.06, 0.06, 0.075), hair, seed=40 + k, jitter=0.12)

# ---------------------------------------------------------------- the beard, moustache and three braids
jaw = skull_c + Vector((0, -0.1, -0.12))
ck.blob(tuple(jaw), (0.16, 0.09, 0.09), hair, seed=60, jitter=0.1)                             # the beard round the jaw
ck.blob(tuple(P(0, 0.83, -0.18)), (0.16, 0.08, 0.1), hair, seed=61, jitter=0.1)                # down over the chest, in front of it
ck.blob(tuple(P(0, 0.73, -0.27)), (0.13, 0.07, 0.08), hair, seed=62, jitter=0.1)
for s in (-1, 1):
	m0 = skull_c + Vector((0, -0.17, -0.085))
	ck.loft(f"moustache_{s}", [(m0, 0.035, 0.025), (m0 + Vector((s * 0.06, 0.0, -0.01)), 0.035, 0.025),
		(m0 + Vector((s * 0.11, 0.03, 0.0)), 0.025, 0.02), (m0 + Vector((s * 0.14, 0.04, 0.025)), 0.012, 0.012)], hair, sides=10)


def braid(name, top, bottom, r):
	"""A braid: plump bumps along it (the plaits), a copper ring two-thirds down, a little tuft at the end."""
	pts, radii = [], []
	n = 9
	for k in range(n):
		t = k / (n - 1)
		pts.append(top.lerp(bottom, t))
		radii.append(r * (1.0 - 0.25 * t) * (1.0 + 0.12 * math.cos(k * math.pi)))
	tube(name, pts, radii, hair, sides=12)
	ringp = top.lerp(bottom, 0.66)
	d = (bottom - top).normalized()
	ck.loft(name + "_ring", [(ringp - d * 0.025, r * 0.95, r * 0.95), (ringp, r * 1.12, r * 1.12), (ringp + d * 0.025, r * 0.95, r * 0.95)],
		copper, sides=16, subsurf=0)
	ck.blob(tuple(bottom + d * 0.025), (r * 0.8, r * 0.8, r * 1.1), hair, seed=hash(name) % 97, jitter=0.15)


belly_front = 0.36  # look z (front = -z): the braids hang just in front of the shirt
braid("braid_mid", P(0, 0.7, -0.3), P(0, 0.5, -belly_front), 0.045)
for s in (-1, 1):
	braid(f"braid_{'l' if s < 0 else 'r'}", P(-s * 0.1, 0.8, -0.24), P(-s * 0.13, 0.62, -0.33), 0.038)

# ---------------------------------------------------------------- the skeleton, and which bones move which part
meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
for o in meshes:
	o.name = "body_" + o.name  # never the same name as a bone (Godot would rename the bone: "calf_l_2")
for o in meshes:
	bpy.context.view_layer.objects.active = o
	for m in list(o.modifiers):
		o.select_set(True)
		bpy.ops.object.modifier_apply(modifier=m.name)
		o.select_set(False)

arm_data = bpy.data.armatures.new("dwarf_skeleton")
arm = bpy.data.objects.new("dwarf_skeleton", arm_data)
bpy.context.scene.collection.objects.link(arm)
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode="EDIT")
children = {}
for i, b in enumerate(DATA):
	children.setdefault(b["parent"], []).append(i)
ebones = {}
for i, b in enumerate(DATA):
	eb = arm_data.edit_bones.new(b["name"])
	h = BONE[b["name"]]
	kids = [DATA[c]["name"] for c in children.get(i, [])]
	# along the bone: towards its main child (the spine/arm/leg chain), else along its own y axis
	main = next((k for k in kids if not k.startswith(("thigh", "clavicle", "neck")) or b["name"].startswith(("clavicle", "spine_03")) and k.startswith(("upperarm", "neck"))), kids[0] if kids else None)
	tail = BONE[main] if main and (BONE[main] - h).length > 0.01 else None
	if tail is None:
		m = b["basis"]
		yax = L2B((m[3], m[4], m[5])).normalized()
		tail = h + yax * 0.04
	eb.head, eb.tail = h, tail
	ebones[i] = eb
for i, b in enumerate(DATA):
	if b["parent"] >= 0:
		ebones[i].parent = ebones[b["parent"]]
bpy.ops.object.mode_set(mode="OBJECT")

HEAD_PARTS = ("brow", "moustache", "braid", "Blob")
bpy.ops.object.select_all(action="DESELECT")
rigid_head = []
for o in meshes:
	c = sum((Vector(v) for v in o.bound_box), Vector()) / 8
	if o.data.materials and o.data.materials[0].name in ("hair", "eye", "pupil", "copper") or (c.z > head.z - 0.02 and abs(c.x) < 0.2):
		rigid_head.append(o)  # head, face, hair, beard, braids and their rings ride on the head bone
for o in meshes:
	if o in rigid_head:
		o.parent = arm
		o.parent_type = "OBJECT"
		vg = o.vertex_groups.new(name="Head")
		vg.add(list(range(len(o.data.vertices))), 1.0, "REPLACE")
		mod = o.modifiers.new("skeleton", "ARMATURE")
		mod.object = arm
	else:
		o.select_set(True)
arm.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.object.parent_set(type="ARMATURE_AUTO")  # Blender works out the bone weights from the shape
# Nothing follows the "root" bone (the skeleton's anchor on the floor between the feet: it runs up through the crotch,
# so the automatic weighting gives it the seat of the shorts). Its share goes to the hips (pelvis).
for o in meshes:
	rg = o.vertex_groups.get("root")
	if rg is None:
		continue
	pg = o.vertex_groups.get("pelvis") or o.vertex_groups.new(name="pelvis")
	for v in o.data.vertices:
		for g in v.groups:
			if g.group == rg.index and g.weight > 0.0:
				cur = next((x.weight for x in v.groups if x.group == pg.index), 0.0)
				pg.add([v.index], cur + g.weight, "REPLACE")
	o.vertex_groups.remove(rg)
# Points the automatic weighting couldn't reach (e.g. a cap's middle between the legs) get the bones of their nearest
# weighted neighbour: a point with no bone at all is pulled to the floor's middle by most engines (a long spike).
from mathutils import kdtree  # noqa: E402
unweighted_total = 0
for o in meshes:
	vs = o.data.vertices
	have = [v.index for v in vs if any(g.weight > 0.0 for g in v.groups)]
	lost = [v.index for v in vs if not any(g.weight > 0.0 for g in v.groups)]
	if not lost or not have:
		continue
	kd = kdtree.KDTree(len(have))
	for i in have:
		kd.insert(vs[i].co, i)
	kd.balance()
	names = {vg.index: vg.name for vg in o.vertex_groups}
	for i in lost:
		src = vs[kd.find(vs[i].co)[1]]
		for g in src.groups:
			o.vertex_groups[names[g.group]].add([i], g.weight, "REPLACE")
	unweighted_total += len(lost)
print("DWARF points without bones, fixed:", unweighted_total)
# At most 4 bones per point (the dwarf plan; game engines and web pages only use 4): keep the 4 strongest, rescale.
for o in meshes:
	names = {vg.index: vg.name for vg in o.vertex_groups}
	for v in o.data.vertices:
		ws = sorted(((g.weight, g.group) for g in v.groups if g.weight > 0.0), reverse=True)
		keep, drop = ws[:4], ws[4:]
		total = sum(w for w, _ in keep) or 1.0
		for w, gi in drop:
			o.vertex_groups[names[gi]].remove([v.index])
		for w, gi in keep:
			o.vertex_groups[names[gi]].add([v.index], w / total, "REPLACE")
bad = [o.name for o in meshes if o not in rigid_head and not any(len(vg.name) for vg in o.vertex_groups)]
print("DWARF auto-weights missing on:", bad)

bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_yup=True, export_skins=True,
	export_animations=False, export_apply=False)
lo = Vector([min(min((o.matrix_world @ Vector(v))[k] for v in o.bound_box) for o in meshes) for k in range(3)])
hi = Vector([max(max((o.matrix_world @ Vector(v))[k] for v in o.bound_box) for o in meshes) for k in range(3)])
print(f"DWARF_DONE {OUT} size {hi.x - lo.x:.2f} x {hi.y - lo.y:.2f} x {hi.z - lo.z:.2f} m, {len(meshes)} parts, {len(rigid_head)} on the head bone")
