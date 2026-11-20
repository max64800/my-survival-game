# Lampwick Drift's creatures (dungeon 2, owner Nov 20, 2026: "download them and try to adjust them a little bit"):
# old dwarf miners who never left, made from the free CC0 "KayKit Character Pack: Skeletons" by Kay Lousberg
# (tools/asset_forge/packs/kaykit_skeletons/, MODEL-RULES rule 1 for free packs). The pack's skeleton, skin and
# moves are kept; the body is reshaped (pose baked into the rest pose: stoop, broad chest, dwarf size), every
# surface repainted with our own hand-painted kit pictures (aged bone, miner's wool, rusty iron, old leather), and
# each gets our own mining gear (sheet: docs/art/dungeon-model-sheets/junk_small_mine.jpg): a ragged beard, a
# miner's helmet, a pickaxe or shovel. The gear is skinned to one bone each, so it moves with the pack's moves.
#
#   blender --background --factory-startup --python builds/kaykit_miners.py -- <out_dir> [only=lost_miner,...]
#
# Models (Godot: front +Z, feet on y = 0; parts = separate meshes):
#   tunnel_rat_<grime|soot|rust>  (Skeleton_Minion) small fast pest, 0.95 m: hunched, scruffy beard, cap, little shovel
#   lost_miner_<frost|rime|ghost> (Skeleton_Rogue) old frosty ghost miner, 1.4 m: icy pale bone, long beard, helmet with a dead
#                lamp, a pickaxe
#   foreman      (Skeleton_Warrior) the end boss, 1.85 m: broad, iron foreman's helmet with a lit lamp and a badge,
#                a thick beard, a heavy two-handed pick
# Parts: body meshes keep the pack's names (..._Head, _Jaw, _ArmLeft ...), plus "beard", "helmet", "lamp_glow",
# "tool" (the game can drop the tool on death). Animations: the KEEP list below (the pack's names).
import colorsys
import math
import random
import sys
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Euler, Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kit  # noqa: E402
import glb_jpeg_clean  # noqa: E402  (Godot can't read Blender's JPEGs with their extra info blocks)

ROOT = Path(__file__).resolve().parents[3]
PACK = Path(__file__).resolve().parents[1] / "packs" / "kaykit_skeletons"
ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = Path(next((a for a in ARGS if "=" not in a), str(ROOT / "assets" / "models" / "creatures")))
ONLY = next((a.split("=", 1)[1].split(",") for a in ARGS if a.startswith("only=")), None)
rng = random.Random(3)

# The pack's moves the dungeon needs (the rest are dropped: smaller files).
KEEP = ["Idle", "Idle_Combat", "Walking_A", "Walking_D_Skeletons", "Running_A", "Running_B", "1H_Melee_Attack_Chop",
	"1H_Melee_Attack_Stab", "2H_Melee_Attack_Chop", "2H_Melee_Attack_Spin", "2H_Melee_Idle", "Hit_A", "Hit_B",
	"Death_A", "Death_C_Skeletons", "Skeletons_Awaken_Floor", "Skeletons_Inactive_Floor_Pose", "Spawn_Ground_Skeletons",
	"Taunt", "Block", "Dodge_Backward", "Unarmed_Melee_Attack_Punch_A", "Cheer", "Interact"]

# Paint: kit picture -> tinted copy. (picture, tint rgb, keep contrast 0..1, glow)
PAINT = {
	"bone": ("limestone_b", (0.80, 0.73, 0.58), 0.55, 0.0),
	"bone_ghost": ("limestone_b", (0.62, 0.74, 0.66), 0.55, 0.0),
	"bone_grime": ("limestone_c", (0.64, 0.60, 0.50), 0.55, 0.0),
	"wool": ("sack_b", (0.46, 0.40, 0.30), 1.0, 0.0),
	"wool_ghost": ("sack_b", (0.36, 0.42, 0.37), 1.0, 0.0),
	"wool_dark": ("sack_b", (0.30, 0.27, 0.24), 0.9, 0.0),
	"iron": ("iron_b", (0.46, 0.43, 0.40), 0.6, 0.0),
	"leather": ("leather_dark", (0.50, 0.37, 0.26), 0.7, 0.0),
	"beard": ("ropev_a", (0.62, 0.60, 0.56), 1.0, 0.0),
	"beard_ghost": ("ropev_a", (0.66, 0.78, 0.72), 1.0, 0.0),
	"beard_red": ("ropev_a", (0.55, 0.30, 0.17), 1.0, 0.0),
	"wood": ("wood_b", (0.62, 0.46, 0.32), 1.0, 0.0),
	# looks (owner, Nov 20: colour variety for the Rat and the Lost Miner; the Lost Miner gives you frost)
	"bone_soot": ("limestone_c", (0.47, 0.44, 0.41), 0.6, 0.0),
	"wool_soot": ("sack_b", (0.22, 0.21, 0.20), 0.9, 0.0),
	"beard_soot": ("ropev_a", (0.38, 0.37, 0.36), 1.0, 0.0),
	"bone_rust": ("limestone_c", (0.70, 0.55, 0.41), 0.6, 0.0),
	"wool_rust": ("sack_b", (0.50, 0.28, 0.17), 0.9, 0.0),
	"beard_brown": ("ropev_a", (0.47, 0.34, 0.22), 1.0, 0.0),
	"bone_frost": ("limestone_b", (0.62, 0.72, 0.84), 0.55, 0.0),
	"wool_frost": ("sack_b", (0.28, 0.34, 0.45), 0.9, 0.0),
	"beard_frost": ("ropev_a", (0.76, 0.86, 0.96), 1.0, 0.0),
	"bone_rime": ("limestone_b", (0.84, 0.86, 0.88), 0.55, 0.0),
	"wool_rime": ("sack_b", (0.40, 0.43, 0.47), 0.9, 0.0),
	"beard_rime": ("ropev_a", (0.93, 0.95, 0.97), 1.0, 0.0),
	"copper": ("copper_b", (0.85, 0.62, 0.45), 1.0, 0.0),
}
TILE = {"bone": 0.7, "bone_ghost": 0.7, "bone_grime": 0.7, "wool": 0.6, "wool_ghost": 0.6, "wool_dark": 0.6,
	"iron": 0.45, "leather": 0.5, "beard": 0.25, "beard_ghost": 0.25, "beard_red": 0.25, "wood": 0.5, "copper": 0.4}
for _k in PAINT:
	TILE.setdefault(_k, 0.25 if _k.startswith("beard") else 0.6 if _k.startswith("wool") else 0.7)

# body: which paint each of the pack's colour kinds gets
CREATURES = {
	"tunnel_rat": dict(src="Skeleton_Minion", height=0.95, drop=[],
		paint={"bone": "bone_grime", "cloth": "wool", "metal": "iron", "leather": "leather"},
		eyes=(1.0, 0.72, 0.2), eye_glow=2.2, beard="beard", beard_len=0.36, beard_w=0.40,
		pose={"spine": (22, 0, 0), "chest": (10, 0, 0), "head": (-24, 0, 0)}, chest_scale=(1.05, 1.0, 1.0),
		helmet="cap", tool="shovel",
		looks={"grime": {}, "soot": dict(paint={"bone": "bone_soot", "cloth": "wool_soot"}, beard="beard_soot", eyes=(1.0, 0.42, 0.12)),
			"rust": dict(paint={"bone": "bone_rust", "cloth": "wool_rust"}, beard="beard_brown", eyes=(0.85, 1.0, 0.3))}),
	"lost_miner": dict(src="Skeleton_Rogue", height=1.4, drop=["Skeleton_Rogue_Hood"],
		paint={"bone": "bone_ghost", "cloth": "wool_ghost", "metal": "iron", "leather": "leather"},
		eyes=(0.45, 1.0, 0.75), eye_glow=2.6, beard="beard_ghost", beard_len=0.70, beard_w=0.50, ghost=0.12,
		pose={"spine": (10, 0, 0), "chest": (6, 0, 0), "head": (-12, 0, 0)}, chest_scale=(1.15, 1.0, 1.1),
		helmet="miner", tool="pickaxe",
		looks={"frost": dict(paint={"bone": "bone_frost", "cloth": "wool_frost"}, beard="beard_frost", eyes=(0.5, 0.82, 1.0)),
			"rime": dict(paint={"bone": "bone_rime", "cloth": "wool_rime"}, beard="beard_rime", eyes=(0.35, 0.95, 1.0)),
			"ghost": dict(eyes=(0.55, 0.9, 1.0))}),
	"foreman": dict(src="Skeleton_Warrior", height=1.85, drop=["Skeleton_Warrior_Helmet"],
		paint={"bone": "bone", "cloth": "wool_dark", "metal": "iron", "leather": "leather"},
		eyes=(1.0, 0.45, 0.12), eye_glow=3.0, beard="beard_red", beard_len=0.62, beard_w=0.62,
		pose={"spine": (0, 0, 0), "chest": (-4, 0, 0), "head": (4, 0, 0)}, chest_scale=(1.32, 1.12, 1.25),
		helmet="foreman", tool="big_pick", looks={"": {}}),
}

_mats = {}


def paint_mat(kind, glow=None):
	"""Our hand-painted kit picture, tinted for this creature (a copy made here with numpy)."""
	key = (kind, glow)
	if key in _mats:
		return _mats[key]
	pic, tint, keep, _ = PAINT[kind]
	src = bpy.data.images.load(str(kit.TEX / f"{pic}.png"), check_existing=True)
	w, h = src.size
	px = np.array(src.pixels[:], dtype=np.float32).reshape(h, w, 4)
	lum = px[..., :3] @ np.array([0.3, 0.59, 0.11], dtype=np.float32)
	l = 1.0 + keep * (lum / max(1e-4, float(lum.mean())) - 1.0)
	out = np.empty_like(px)
	out[..., :3] = np.clip(l[..., None] * np.array(tint, dtype=np.float32), 0, 1)
	out[..., 3] = 1.0
	img = bpy.data.images.new(f"miner_{kind}", w, h)
	img.pixels[:] = out.ravel()
	img.filepath_raw = str(OUT / "_tex" / f"miner_{kind}.png")
	img.file_format = "PNG"
	img.save()
	m = bpy.data.materials.new(f"miner_{kind}")
	m.use_nodes = True
	b = m.node_tree.nodes["Principled BSDF"]
	t = m.node_tree.nodes.new("ShaderNodeTexImage")
	t.image = img
	m.node_tree.links.new(t.outputs["Color"], b.inputs["Base Color"])
	metal = kind in ("iron", "copper")
	b.inputs["Metallic"].default_value = 0.5 if metal else 0.0
	b.inputs["Roughness"].default_value = 0.5 if metal else 0.9
	if glow:
		b.inputs["Emission Color"].default_value = (*tint, 1)
		b.inputs["Emission Strength"].default_value = glow
	m["tile"] = TILE[kind]
	_mats[key] = m
	return m


def glow_mat(name, rgb, strength):
	m = bpy.data.materials.new(name)
	m.use_nodes = True
	b = m.node_tree.nodes["Principled BSDF"]
	b.inputs["Base Color"].default_value = (*rgb, 1)
	b.inputs["Emission Color"].default_value = (*rgb, 1)
	b.inputs["Emission Strength"].default_value = strength
	return m


def classify(rgb):
	"""The pack paints by colour cells: light warm = bone, strong red = cloth, grey = metal, the rest = leather."""
	h, s, v = colorsys.rgb_to_hsv(*rgb)
	if s < 0.1 and v < 0.85:
		return "metal"
	if s > 0.25 and (h > 0.85 or h < 0.02):
		return "cloth"
	if v > 0.62 and s < 0.4 and 0.02 <= h <= 0.2:
		return "bone"
	if v > 0.55 and s < 0.25:
		return "bone"
	return "leather"


def uv_box(o, tile):
	"""Like kit._uv_box, one material at a time (each its own picture size)."""
	bpy.ops.object.select_all(action="DESELECT")
	o.select_set(True)
	bpy.context.view_layer.objects.active = o
	for i, slot in enumerate(o.material_slots):
		t = slot.material.get("tile") if slot.material else None
		if not t:
			continue
		bpy.ops.object.mode_set(mode="EDIT")
		bpy.ops.mesh.select_all(action="DESELECT")
		o.active_material_index = i
		bpy.ops.object.material_slot_select()
		bpy.ops.uv.cube_project(cube_size=t, scale_to_bounds=False)
		bpy.ops.object.mode_set(mode="OBJECT")
	uv = o.data.uv_layers.active.data
	du, dv = rng.random(), rng.random()
	for d in uv:
		d.uv = (d.uv[0] + du, d.uv[1] + dv)


def repaint(o, cfg):
	"""Read each face's colour off the pack's picture, then give it our painted material of that kind."""
	me = o.data
	if o.name.endswith("_Eyes"):
		me.materials.clear()
		me.materials.append(glow_mat("eyes_glow", cfg["eyes"], cfg["eye_glow"]))
		return
	src = me.materials[0]
	img = next(n.image for n in src.node_tree.nodes if n.type == "TEX_IMAGE")
	w, h = img.size
	px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)
	uv = me.uv_layers.active.data
	kinds = list(cfg["paint"])
	slots = {}
	me.materials.clear()
	for k in kinds:
		slots[k] = len(me.materials)
		me.materials.append(paint_mat(cfg["paint"][k], glow=cfg.get("ghost") if k in ("bone",) else None))
	for f in me.polygons:
		u = sum(uv[l].uv[0] for l in f.loop_indices) / f.loop_total
		v = sum(uv[l].uv[1] for l in f.loop_indices) / f.loop_total
		c = px[min(h - 1, int((v % 1) * h)), min(w - 1, int((u % 1) * w)), :3]
		f.material_index = slots[classify(tuple(float(x) for x in c))]
	uv_box(o, None)


def skin_to(o, arm, bone):
	"""Make a loose part move with one bone (weight 1), like the rest of the body."""
	vg = o.vertex_groups.get(bone) or o.vertex_groups.new(name=bone)
	vg.add(range(len(o.data.vertices)), 1.0, "REPLACE")
	if not any(m.type == "ARMATURE" for m in o.modifiers):
		m = o.modifiers.new("Armature", "ARMATURE")
		m.object = arm
	o.parent = arm
	o.matrix_parent_inverse = arm.matrix_world.inverted()


def unparent_bone(o, arm):
	"""Bone-parented parts (the cape) become skinned parts: same place, weight 1 to that bone."""
	bone = o.parent_bone
	mw = o.matrix_world.copy()
	o.parent = None
	o.data.transform(mw)
	o.matrix_world = Matrix.Identity(4)
	skin_to(o, arm, bone)


def apply_mods(o, keep_armature=False):
	bpy.ops.object.select_all(action="DESELECT")
	o.select_set(True)
	bpy.context.view_layer.objects.active = o
	for m in list(o.modifiers):
		if keep_armature and m.type == "ARMATURE":
			continue
		bpy.ops.object.modifier_apply(modifier=m.name)


def reshape(arm, meshes, cfg):
	"""Stoop, broad chest: pose the bones, bake that into the skin and the rest pose (the moves then keep it)."""
	arm.animation_data.action = None
	for pb in arm.pose.bones:
		pb.rotation_mode = "QUATERNION"
		pb.location = (0, 0, 0)
		pb.rotation_quaternion = (1, 0, 0, 0)
		pb.scale = (1, 1, 1)
	for b, deg in cfg["pose"].items():
		arm.pose.bones[b].rotation_quaternion = Euler([math.radians(a) for a in deg]).to_quaternion()
	arm.pose.bones["chest"].scale = cfg["chest_scale"]
	inv = tuple(1.0 / s for s in cfg["chest_scale"])  # the head keeps its own size
	arm.pose.bones["head"].scale = (inv[0], inv[1], inv[2])
	bpy.context.view_layer.update()
	for o in meshes:
		apply_mods(o)
	bpy.ops.object.select_all(action="DESELECT")
	bpy.context.view_layer.objects.active = arm
	arm.select_set(True)
	bpy.ops.object.mode_set(mode="POSE")
	bpy.ops.pose.select_all(action="SELECT")
	bpy.ops.pose.armature_apply(selected=False)
	bpy.ops.object.mode_set(mode="OBJECT")
	for o in meshes:
		m = o.modifiers.new("Armature", "ARMATURE")
		m.object = arm


def bounds(objs):
	vs = [o.matrix_world @ v.co for o in objs for v in o.data.vertices]
	return Vector([min(v[i] for v in vs) for i in range(3)]), Vector([max(v[i] for v in vs) for i in range(3)])


def group(objs, name):
	"""Join the gear's kit parts (modifiers applied) into one object."""
	for o in objs:
		apply_mods(o)
	bpy.ops.object.select_all(action="DESELECT")
	for o in objs:
		o.select_set(True)
	bpy.context.view_layer.objects.active = objs[0]
	bpy.ops.object.join()
	o = bpy.context.object
	o.name = name
	return o


def new_objs(before):
	return [o for o in bpy.data.objects if o not in before and o.type == "MESH"]


# ---------------------------------------------------------------- gear (built in the rest pose, armature space)

def beard(jaw_lo, jaw_hi, chest_front, cfg):
	"""A chunky dwarf beard over the chest: a solid pad under the jaw, flat thick locks fanned below it (longest in
	the middle), each lock a 4-sided wedge with a chopped tip; a moustache round the mouth. Every lock overlaps the pad."""
	before = set(bpy.data.objects)
	m = paint_mat(cfg["beard"])
	length, width = cfg["beard_len"], cfg["beard_w"]
	front = min(jaw_lo.y + 0.06, chest_front - 0.02)  # in front of the ribs, not inside them
	top = jaw_lo.z + 0.14
	kit.box((width, 0.16, 0.2), (0, jaw_lo.y + 0.1, top - 0.06), m, bevel=0.04, wobble=0.015)  # the pad
	n = 5
	for i in range(n):
		t = i / (n - 1) - 0.5
		ln = length * (1.0 - 0.7 * abs(t)) * rng.uniform(0.92, 1.04)
		w = width / n * 1.45
		bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=w * 0.2, radius2=w, depth=ln, location=(0, 0, 0),
			rotation=(0, 0, math.radians(45)))
		o = bpy.context.object
		o.scale = (1.0, 0.45, 1.0)
		bpy.ops.object.transform_apply(scale=True, rotation=True)
		o.location = (t * width * 0.86, front - w * 0.2 + 0.03 * abs(t) + 0.022 * (i % 2), top - 0.08 - ln / 2)  # neighbours at their own depth: no flicker
		o.rotation_euler = (math.radians(-8), math.radians(-t * 26), 0)
		o.data.materials.append(m)
		kit.roughen(o, amount=0.014, cuts=1, seed=i)
	for s in (-1, 1):  # moustache
		o = kit.cone(0.06, 0.02, 0.24, (s * 0.12, front - 0.03, jaw_hi.z - 0.1), m, rot=(0, s * 60, 0), verts=5, bevel=0.0)
		o.scale = (1.0, 0.6, 1.0)
	objs = new_objs(before)
	for o in objs:
		uv_box(o, None)
	return group(objs, "beard")


def helmet(head_lo, head_hi, kind):
	"""A miner's helmet like the sheet's: a chunky dome, a brim, an iron band with rivets; a lamp in front."""
	before = set(bpy.data.objects)
	cx, cy = (head_lo.x + head_hi.x) / 2, (head_lo.y + head_hi.y) / 2 - 0.02
	rx = (head_hi.x - head_lo.x) / 2 * 1.2
	ry = (head_hi.y - head_lo.y) / 2 * 1.2
	z0 = head_hi.z - (0.42 if kind != "cap" else 0.36)
	tall = head_hi.z + (0.07 if kind != "foreman" else 0.12) - z0  # the dome's top clears the skull
	shell = paint_mat("iron" if kind != "cap" else "leather")
	band = paint_mat("iron")
	# dome: a squashed low-poly half ball, a bit dented
	bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=6, radius=1.0, location=(cx, cy, z0))
	d = bpy.context.object
	bm = bmesh.new()
	bm.from_mesh(d.data)
	bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.z < -0.01], context="VERTS")
	for v in bm.verts:
		v.co.x *= rx
		v.co.y *= ry
		v.co.z *= tall + rng.uniform(-0.015, 0.015)
		v.co += Vector((rng.uniform(-1, 1), rng.uniform(-1, 1), rng.uniform(-1, 1))) * 0.012
	bmesh.ops.solidify(bm, geom=bm.faces[:], thickness=0.035)
	bm.to_mesh(d.data)
	bm.free()
	d.data.materials.append(shell)
	for p in d.data.polygons:
		p.use_smooth = False
	# brim: a flat ring all round (wider at the back on the foreman's)
	bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=1.0, depth=0.04, location=(cx, cy, z0 + 0.0))
	b = bpy.context.object
	b.scale = (rx * 1.2, ry * 1.2, 1)
	bpy.ops.object.transform_apply(scale=True)
	kit.roughen(b, amount=0.01, cuts=1, seed=5)
	b.data.materials.append(shell)
	# band with rivets
	bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=1.0, depth=0.075, location=(cx, cy, z0 + 0.065))
	r = bpy.context.object
	r.scale = (rx * 1.02, ry * 1.02, 1)
	bpy.ops.object.transform_apply(scale=True)
	r.data.materials.append(band)
	for k in range(8):
		a = 2 * math.pi * k / 8 + 0.2
		kit.rivet((cx + math.cos(a) * rx * 1.04, cy + math.sin(a) * ry * 1.04, z0 + 0.065), band, r=0.02)
	if kind != "cap":  # the ridge over the top (the sheet's strap)
		bpy.ops.mesh.primitive_torus_add(major_radius=1.0, minor_radius=0.035, major_segments=16, minor_segments=4,
			location=(cx, cy, z0), rotation=(0, math.radians(90), 0))
		st = bpy.context.object  # the strap over the top, following the dome
		st.scale = (tall + 0.02, ry + 0.02, tall + 0.02)
		bpy.ops.object.transform_apply(scale=True, rotation=True)
		bm = bmesh.new()
		bm.from_mesh(st.data)
		bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.z < z0 + 0.04 - st.location.z], context="VERTS")
		bm.to_mesh(st.data)
		bm.free()
		st.data.materials.append(band)
		uv_box(st, None)
	for o in (d, b, r):
		uv_box(o, None)
	parts = new_objs(before)
	front = (cx, cy - ry * 1.04, z0 + 0.12)
	glow = None
	if kind in ("miner", "foreman"):  # lamp: a copper cup on a bracket, glass broken on the Lost Miner's
		cop = paint_mat("copper")
		kit.box((0.12, 0.05, 0.12), (front[0], front[1] - 0.005, front[2]), band, bevel=0.012, wobble=0.004)
		kit.cylinder(0.075, 0.09, (front[0], front[1] - 0.07, front[2] + 0.01), cop, rot=(90, 0, 0), verts=10, bevel=0.008)
		kit.ring(0.075, 0.014, (front[0], front[1] - 0.115, front[2] + 0.01), band, rot=(90, 0, 0), seg=12)
		parts = new_objs(before)
		before2 = set(bpy.data.objects)
		if kind == "foreman":
			kit.cylinder(0.062, 0.012, (front[0], front[1] - 0.112, front[2] + 0.01), glow_mat("lamp_glow", (1.0, 0.72, 0.3), 4.0), rot=(90, 0, 0), verts=10, bevel=0.0)
			glow = new_objs(before2)[0]
			glow.name = "lamp_glow"
		else:
			kit.cylinder(0.062, 0.012, (front[0], front[1] - 0.112, front[2] + 0.01), kit.mat("charcoal"), rot=(90, 0, 0), verts=10, bevel=0.0)
			parts += new_objs(before2)
		if kind == "foreman":  # the badge on the band's side (the sheet's octagon with a peak)
			pass
	return group([p for p in parts if p is not glow], "helmet"), glow


def tool(kind):
	"""The gear in the hand, built along +Y (the hand slot's axis, like KayKit's own weapons), grip at 0."""
	before = set(bpy.data.objects)
	wood, ir = paint_mat("wood"), paint_mat("iron")
	if kind in ("pickaxe", "big_pick"):
		L = 1.0 if kind == "pickaxe" else 1.35
		r = 0.04 if kind == "pickaxe" else 0.055
		kit.cylinder(r, L, (0, L / 2 - 0.2, 0), wood, rot=(90, 0, 0), verts=7, bevel=0.006)
		hy = L - 0.25
		kit.box((r * 3.1, r * 3.6, r * 3.1), (0, hy, 0), ir, bevel=0.012, wobble=0.006)  # the socket (well clear of the points: no flicker)
		span = 0.42 if kind == "pickaxe" else 0.62
		for s in (-1, 1):  # two curved points (each a bent tapering wedge)
			for k in range(3):
				if k == 0 and s > 0:
					continue  # the middle piece is one block across both sides (two would overlap: flicker)
				t0 = k / 3
				zc = 0.0 if k == 0 else s * span * (t0 + 1 / 6) / 2
				w = r * (2.3 - 1.6 * t0)
				kit.box((w, w * 1.2, (span / 3 * 0.6 + 0.02) * (1.8 if k == 0 else 1.0)), (0, hy - 0.07 * t0 * t0 * 3, zc), ir, bevel=0.01, wobble=0.006,
					rot=(s * 22 * t0, 0, 0))
		for k in range(2):
			kit.ring(r * 1.15, 0.012, (0, hy - 0.12 - k * 0.06, 0), ir, rot=(90, 0, 0), seg=10)
	elif kind == "shovel":
		kit.cylinder(0.03, 0.75, (0, 0.2, 0), wood, rot=(90, 0, 0), verts=7, bevel=0.005)
		kit.box((0.2, 0.05, 0.035), (0, -0.19, 0), wood, bevel=0.01, wobble=0.004)  # the D-grip's bar
		kit.box((0.06, 0.24, 0.17), (0, 0.67, 0), ir, bevel=0.01, wobble=0.006)  # socket
		kit.box((0.28, 0.32, 0.035), (0, 0.92, 0.02), ir, bevel=0.02, wobble=0.012)  # the dented blade
	o = group(new_objs(before), "tool")
	if kind in ("pickaxe", "big_pick"):  # owner, Nov 20 (F465): the point leads the swing (it hit with the flat side)
		o.data.transform(Matrix.Rotation(math.radians(90), 4, "Y"))
	return o


def place(obj, mat):
	obj.data.transform(mat)


# ---------------------------------------------------------------- build

def build(name, look):
	cfg = dict(CREATURES[name])
	over = cfg["looks"][look]
	for k, v in over.items():
		cfg[k] = {**cfg[k], **v} if isinstance(v, dict) else v
	rng.seed(sum(map(ord, name)))  # every look gets the same beard and helmet shape
	kit.reset()
	_mats.clear()
	bpy.ops.import_scene.gltf(filepath=str(PACK / f"{cfg['src']}.glb"))
	for o in list(bpy.data.objects):
		if o.name.startswith("Icosphere") or o.name in cfg["drop"]:
			bpy.data.objects.remove(o)
	arm = bpy.data.objects["Rig"]
	arm.data.pose_position = "POSE"
	meshes = [o for o in bpy.data.objects if o.type == "MESH"]
	for o in meshes:
		if o.parent_type == "BONE":
			unparent_bone(o, arm)
	reshape(arm, meshes, cfg)
	for o in meshes:
		repaint(o, cfg)
	head = next(o for o in meshes if o.name.endswith("_Head"))
	jaw = next(o for o in meshes if o.name.endswith("_Jaw"))
	hlo, hhi = bounds([head])
	jlo, jhi = bounds([jaw])
	body = next(o for o in meshes if o.name.endswith("_Body"))
	b = beard(jlo, jhi, bounds([body])[0].y, cfg)
	skin_to(b, arm, "head")
	hm, glow = helmet(hlo, hhi, cfg["helmet"])
	skin_to(hm, arm, "head")
	if glow:
		skin_to(glow, arm, "head")
	t = tool(cfg["tool"])
	slot = arm.data.bones["handslot.r"]
	place(t, arm.matrix_world @ slot.matrix_local)
	skin_to(t, arm, "handslot.r")
	# dwarf size: the whole rig scaled (moves keep working: the scale sits on the rig, not in the bones)
	lo, hi = bounds([o for o in bpy.data.objects if o.type == "MESH" and o.name != "tool"])
	s = cfg["height"] / (hi.z - lo.z)
	arm.scale = (s, s, s)
	# keep only the moves we use
	for a in list(bpy.data.actions):
		if a.name not in KEEP:
			bpy.data.actions.remove(a)
	arm.animation_data.action = bpy.data.actions.get("Idle")
	OUT.mkdir(parents=True, exist_ok=True)
	bpy.ops.object.select_all(action="SELECT")
	out = OUT / (f"{name}_{look}.glb" if look else f"{name}.glb")
	bpy.ops.export_scene.gltf(filepath=str(out), export_format="GLB", use_selection=True, export_yup=True,
		export_animation_mode="ACTIONS", export_image_format="JPEG", export_image_quality=85, export_apply=False)
	glb_jpeg_clean.clean(str(out))  # (else the game shows them plain white: Nov 20)
	print("SAVED", out, "scale", round(s, 3), "actions", len(bpy.data.actions))


if __name__ == "__main__":
	(OUT / "_tex").mkdir(parents=True, exist_ok=True)
	for n in CREATURES:
		if ONLY and n not in ONLY:
			continue
		for look in CREATURES[n]["looks"]:
			build(n, look)
