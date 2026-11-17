# The player dwarf's body, hand-built around the game's real skeleton (Claude 3, Nov 16, 2026; MODEL-RULES Rule 1).
#
#   blender --background --factory-startup --python tools/asset_forge/builds/dwarf_body.py -- <skeleton.json> <out.glb> [fast] [review=<pic.png>]
#
# fast: build the head, hair and beard without the light copy and the bake, and stop (shape checks, ~1 min).
# review=<pic.png>: also photograph the head front and side next to the approved head picture.
# Round 2 (Nov 16): the head, hair and beard come from dwarf_head.py (melted into one sculpted skin, laid on the body).
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
sys.path.insert(0, str(Path(__file__).resolve().parent))
import creature_kit as ck  # noqa: E402
import dwarf_head as dh  # noqa: E402

ARGS = sys.argv[sys.argv.index("--") + 1:]
SKEL, OUT = ARGS[0], ARGS[1]
FAST = "fast" in ARGS[2:]
REVIEW = next((a[7:] for a in ARGS[2:] if a.startswith("review=")), None)
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

# ---------------------------------------------------------------- the head, hair and beard (round 2: dwarf_head.py)
# One melted, sculpted skin built around the body (the beard and hair lie ON it with a 1.2 cm gap), separate eyes and
# copper rings. Placed from the picture: crown at 1.19 m, the skull's middle above the body's middle.
head = B("Head")
BODY_PARTS = [o for o in bpy.context.scene.objects if o.type == "MESH"]
HEAD = dh.build(BODY_PARTS, fast=FAST)
if REVIEW:
	dh.review(REVIEW)
if FAST:
	print("DWARF_FAST_DONE")
	sys.exit(0)
HEAD_OBJS = [HEAD["head"], HEAD["eyes"], HEAD["rings"]]

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
# Swing bones (owner, F192: the braids and the back hair were glued to the body): a chain down each braid, from under
# the chin to the tuft's tip, hanging from the chest; and one down the back hair, hanging from the head. The game adds
# them to its skeleton and lets them swing (DwarfRig: spring bones).
CHAINS = {}  # chain name -> [(bone name, head, tail)]


def chain_along(pts, fracs):
	d = [0.0]
	for p, q in zip(pts[:-1], pts[1:]):
		d.append(d[-1] + (q - p).length)

	def at(f):
		s = f * d[-1]
		for k in range(len(pts) - 1):
			if d[k + 1] >= s:
				return pts[k].lerp(pts[k + 1], (s - d[k]) / max(d[k + 1] - d[k], 1e-9))
		return pts[-1].copy()
	return [at(f) for f in fracs]


def path_s(pts, p):
	"""How far along the polyline the point nearest to p is."""
	best, s0 = (1e9, 0.0), 0.0
	for a, b in zip(pts[:-1], pts[1:]):
		ab = b - a
		t = min(max((p - a).dot(ab) / max(ab.length_squared, 1e-12), 0.0), 1.0)
		d = (a + ab * t - p).length
		if d < best[0]:
			best = (d, s0 + t * ab.length)
		s0 += ab.length
	return best[1], s0


# Real hair chains (owner, round 2b: "the 3 braids need a lot of skeleton points where it bends"): 7 bones down each
# whole braid, from under the chin to the tuft's tip, and 4 down each of three strands of back hair, all hanging from
# the head. The game swings them and keeps them out of the body with collision balls (HairSwing).
for bd, tag in zip(dh.BRAIDS, ("m", "a", "b")):
	joints = chain_along(bd["path"], [k / 7 for k in range(8)])
	CHAINS[f"hair_braid_{tag}"] = (bd, joints, "Head")
for k, pts in enumerate(dh.BACKS):
	CHAINS[f"hair_back_{'lmr'[k] if len(dh.BACKS) == 3 else k}"] = (None, list(pts), "Head")  # (a bone per point: 7 / 5)
for cname, (bd, joints, parent) in CHAINS.items():
	prev = arm_data.edit_bones[parent]
	for k in range(len(joints) - 1):
		eb = arm_data.edit_bones.new(f"{cname}_{k + 1}")
		eb.head, eb.tail = joints[k], joints[k + 1]
		eb.parent = prev
		eb.use_deform = False  # (off while Blender weighs the body: the shirt must not follow the hair)
		prev = eb
bpy.ops.object.mode_set(mode="OBJECT")

bpy.ops.object.select_all(action="DESELECT")
for o in meshes:
	if o not in HEAD_OBJS:
		o.select_set(True)
arm.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.object.parent_set(type="ARMATURE_AUTO")  # Blender works out the bone weights from the shape
for bone in arm_data.bones:
	bone.use_deform = True
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
# Nothing on the body follows the neck or the head either: in this skeleton the Head bone sits INSIDE the upper chest
# (0.85 m, below the shoulders), so the automatic weighting gave it the shirt's chest, which then swung up into the
# face and beard whenever the head nodded (round 2's clipping check). Their share goes to the upper chest (spine_03).
for o in meshes:
	if o in HEAD_OBJS:
		continue
	cg = o.vertex_groups.get("spine_03") or o.vertex_groups.new(name="spine_03")
	for bone in ("Head", "neck_01"):
		g = o.vertex_groups.get(bone)
		if g is None:
			continue
		for v in o.data.vertices:
			for x in v.groups:
				if x.group == g.index and x.weight > 0.0:
					cur = next((y.weight for y in v.groups if y.group == cg.index), 0.0)
					cg.add([v.index], cur + x.weight, "REPLACE")
		o.vertex_groups.remove(g)
# The head, hair and beard: the face and the top of the head ride on the Head bone. Lower down, the beard and the hair on
# the back follow the shirt they lie on (its bones, copied from the nearest shirt point), blended in over 10 cm under the
# chin. (Owner, F183: all on the head bone, the long beard swung through the belly when the head moved: the Head bone
# turns at shoulder height, 40 cm above the beard's tip.)
from mathutils import kdtree  # noqa: E402
LOW, HIGH = 0.865, 0.96  # metres: below LOW only the shirt's bones, above HIGH only the head
sp, sw = [], []
for o in meshes:
	if o in HEAD_OBJS or not o.data.materials or o.data.materials[0].name != "shirt":
		continue
	names = {vg.index: vg.name for vg in o.vertex_groups}
	for v in o.data.vertices:
		sp.append(o.matrix_world @ v.co)
		sw.append({names[g.group]: g.weight for g in v.groups if g.weight > 0.0})
skd = kdtree.KDTree(len(sp))
for i, p in enumerate(sp):
	skd.insert(p, i)
skd.balance()


def head_share(z):
	x = min(max((z - LOW) / (HIGH - LOW), 0.0), 1.0)
	return x * x * (3 - 2 * x)


def set_weights(o, per_vertex):
	o.parent = arm
	o.parent_type = "OBJECT"
	groups = {}
	for i, ws in enumerate(per_vertex):
		for name, w in ws.items():
			if name not in groups:
				groups[name] = o.vertex_groups.new(name=name)
			groups[name].add([i], w, "REPLACE")
	o.modifiers.new("skeleton", "ARMATURE").object = arm


head_w = []
for v in HEAD["head"].data.vertices:
	p = HEAD["head"].matrix_world @ v.co
	t = head_share(p.z)
	ws = {"Head": t} if t > 0 else {}
	if t < 1:
		for name, w in sw[skd.find(p)[1]].items():
			ws[name] = ws.get(name, 0.0) + (1 - t) * w
	head_w.append(ws)


def along(pts, p):
	"""(distance along the polyline, distance from it) of point p."""
	best, s0 = (1e9, 0.0), 0.0
	for a, b in zip(pts[:-1], pts[1:]):
		ab = b - a
		t = min(max((p - a).dot(ab) / max(ab.length_squared, 1e-12), 0.0), 1.0)
		d = (a + ab * t - p).length
		if d < best[0]:
			best = (d, s0 + t * ab.length)
		s0 += ab.length
	return best[1], best[0], s0


def smooth01(x):
	x = min(max(x, 0.0), 1.0)
	return x * x * (3 - 2 * x)


# the braids and the back hair follow their swing bones (blended in below the chin, so the beard stays joined to the face)
# Each point follows ONE strand: its nearest braid, or its nearest ponytail strand (owner, Nov 17: a point between two
# braids followed both and stretched into a spike when they swung apart; back hair half on the chain and half on the
# shirt tore into a flat slab).
back_owner = {}   # head point -> its nearest back-hair strand
braid_owner = {}  # head point -> its nearest braid
backs = {c: j for c, (bd, j, _) in CHAINS.items() if bd is None}
braids = {c: j for c, (bd, j, _) in CHAINS.items() if bd is not None}
for vi, v in enumerate(HEAD["head"].data.vertices):
	p = HEAD["head"].matrix_world @ v.co
	if backs and dh.C.y - p.y <= -0.05:
		back_owner[vi] = min(backs, key=lambda c: along(backs[c], p)[1])
	if braids:
		braid_owner[vi] = min(braids, key=lambda c: along(braids[c], p)[1])
for cname, (bd, joints, parent) in CHAINS.items():
	nb = len(joints) - 1
	jd = [0.0]
	for p, q in zip(joints[:-1], joints[1:]):
		jd.append(jd[-1] + (q - p).length)
	for vi, v in enumerate(HEAD["head"].data.vertices):
		p = HEAD["head"].matrix_world @ v.co
		s, d, total = along(joints, p)
		if bd is not None:  # the whole braid (blended in over its top 3 cm, under the chin)
			if braid_owner.get(vi) != cname:
				continue
			m = smooth01(s / 0.03) * (1.0 - smooth01((d - bd["reach"]) / (bd["reach"] * 0.6)))
		else:  # the back hair: ALL of it behind the skull, from the crown's back down, goes with its nearest strand
			v_, w_ = p.z - dh.C.z, dh.C.y - p.y
			if back_owner.get(vi) != cname:
				continue
			# (the hair right against the neck stays with the head: swinging it stretched the neck out, owner Nov 17)
			r_neck = math.hypot(p.x - dh.C.x, p.y - dh.C.y)
			m = smooth01((0.07 - v_) / 0.05) * smooth01((-w_ - 0.05) / 0.03) * smooth01((r_neck - 0.1) / 0.05)
		if m <= 0.0:
			continue
		c = 0.0  # where along the chain, in bones (bone k's middle = k)
		for k in range(nb):
			if s <= jd[k + 1] or k == nb - 1:
				c = k + min(max((s - jd[k]) / max(jd[k + 1] - jd[k], 1e-9), 0.0), 1.0) - 0.5
				break
		ws = {name: w * (1 - m) for name, w in head_w[vi].items()}
		for k in range(nb):
			wk = max(0.0, 1.0 - abs(min(max(c, 0.0), nb - 1) - k))
			if wk > 0:
				ws[f"{cname}_{k + 1}"] = ws.get(f"{cname}_{k + 1}", 0.0) + m * wk
		head_w[vi] = ws
print("DWARF swing bones:", {k: len(j) - 1 for k, (_, j, _) in CHAINS.items()})
# The check for the owner's "sheets between the braids": no mesh edge may join two different braids' swinging parts
# (where braids touched, melting glued them, and the glue stretched into a sheet when they swung apart).
def main_chain(ws):
	best = max(ws.items(), key=lambda kv: kv[1]) if ws else ("", 0.0)
	return best[0].rsplit("_", 1)[0] if best[0].startswith("hair_braid") and best[1] > 0.3 else None
ev = [(e.vertices[0], e.vertices[1]) for e in HEAD["head"].data.edges]
glued = [(a, b) for a, b in ev if (ca := main_chain(head_w[a])) and (cb := main_chain(head_w[b])) and ca != cb]
print(f"DWARF edges gluing two braids together: {len(glued)} (must be 0)",
	[tuple(round(x, 3) for x in HEAD["head"].matrix_world @ HEAD["head"].data.vertices[a].co) for a, _ in glued[:3]])
set_weights(HEAD["head"], head_w)
set_weights(HEAD["eyes"], [{"Head": 1.0}] * len(HEAD["eyes"].data.vertices))
hkd = kdtree.KDTree(len(head_w))
for v in HEAD["head"].data.vertices:
	hkd.insert(HEAD["head"].matrix_world @ v.co, v.index)
hkd.balance()
ring_w = [None] * len(HEAD["rings"].data.vertices)
for isl in dh.cs.islands(HEAD["rings"]):  # each ring moves as one piece, with the braid it's on
	c = sum((HEAD["rings"].matrix_world @ HEAD["rings"].data.vertices[i].co for i in isl), Vector()) / len(isl)
	ws = head_w[hkd.find(c)[1]]
	for i in isl:
		ring_w[i] = ws
set_weights(HEAD["rings"], ring_w)
print("DWARF head weights: head share at the chin", round(head_share(0.944), 2), "; shirt points", len(sp))
# Points the automatic weighting couldn't reach (e.g. a cap's middle between the legs) get the bones of their nearest
# weighted neighbour: a point with no bone at all is pulled to the floor's middle by most engines (a long spike).
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
bad = [o.name for o in meshes if not any(len(vg.name) for vg in o.vertex_groups)]
print("DWARF auto-weights missing on:", bad)

bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_yup=True, export_skins=True,
	export_animations=False, export_apply=False, export_image_format="JPEG", export_image_quality=88)
import glb_jpeg_fix  # noqa: E402  every Blender export with JPEG pictures needs this, or Godot shows it white (F164)
glb_jpeg_fix.fix(OUT)
lo = Vector([min(min((o.matrix_world @ Vector(v))[k] for v in o.bound_box) for o in meshes) for k in range(3)])
hi = Vector([max(max((o.matrix_world @ Vector(v))[k] for v in o.bound_box) for o in meshes) for k in range(3)])
print(f"DWARF_DONE {OUT} size {hi.x - lo.x:.2f} x {hi.y - lo.y:.2f} x {hi.z - lo.z:.2f} m, {len(meshes)} parts")
