"""Builds the owner's pose file for the great axe (F389, Nov 20: "I'll pose the dwarf by hand in Blender").

The game dwarf (his real skeleton, body and the great axe, recorded by tools/asset_forge/great_pose_blender_export.gd)
with big easy controls, all in Object Mode (click, G = move, R = turn):
  AXE (orange stick along the handle): moves and turns the axe; it turns round the left fist (the handle's end).
  LEFT HAND (blue ball), RIGHT HAND (yellow ball): slide along the handle only (they can't leave it).
  HIPS (green ring): G moves the hips (down = the knees bend; the feet stay planted), R turns them.
  CHEST (red ring): R twists and leans his upper body (shared over the 3 spine bones, most in the low one).
The arms reach the hand balls by themselves (IK = the computer bends the elbow so the wrist lands on the ball).
Key poses on frames 1, 11, 21, 31, 41 (ready, wind-up top, middle, hit, recovery), pre-placed from chat 8's numbers.
Auto-keying is on: whatever the owner moves on a key frame is saved into that pose.

  blender -b --python tools/blender_poses/make_pose_file.py -- <dwarf_keys.glb> <dwarf_keys.json> <out.blend>
Then tools/blender_poses/view_setup.py (opens Blender with its window once: sets the view, takes guide pictures).
By the dwarf-animations Claude, chat 9, Nov 20, 2026.
"""
import bpy
import bmesh
import json
import math
import sys
from mathutils import Matrix, Vector, Quaternion

args = sys.argv[sys.argv.index("--") + 1:]
GLB, JS, OUT = args[0], args[1], args[2]
KEY_FRAMES = [1, 11, 21, 31, 41]
KEY_NAMES = ["1 READY", "2 WIND-UP TOP", "3 MIDDLE", "4 HIT", "5 RECOVERY"]
GLB_FPS_FRAMES = 24  # (the importer puts pose i, at i seconds, on frame 24 * i)
# Godot / glTF (y up) -> Blender (z up)
C = Matrix(((1, 0, 0, 0), (0, 0, -1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))
# bones Godot moves by code after the fists (head twins, hair, beard braids, kilt hem): they ride on these bones here
FOLLOW = {"neck_01_even": "spine_03", "Head_even": "spine_03", "hair_": "spine_03", "cloth_hem_": "pelvis"}
SPINE_SHARE = {"spine_01": 0.5, "spine_02": 0.8, "spine_03": 1.0}  # (running total of DwarfFist.SPINE)


def gm(a):  # Godot transform list -> 4x4 (Godot space)
    m = Matrix.Identity(4)
    for c in range(3):
        m.col[c] = (a[c * 3], a[c * 3 + 1], a[c * 3 + 2], 0.0)
    m.col[3] = (a[9], a[10], a[11], 1.0)
    return m


def gv(v):  # Godot point (export space) -> Blender world
    return (C @ Vector((v[0], v[1], v[2], 1.0))).xyz


def gd(v):
    return (C.to_3x3() @ Vector(v)).normalized()


def rigid(m):  # rotation + position only (no size, no skew)
    loc, rot, _ = m.decompose()
    return Matrix.Translation(loc) @ rot.to_matrix().to_4x4()


def as_list(m):
    return [list(r) for r in m]


bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
bpy.ops.import_scene.gltf(filepath=GLB, bone_heuristic="TEMPERANCE")
data = json.load(open(JS))
arm = bpy.data.objects["turn"]
axe = bpy.data.objects["axe"]
arm.name = "DWARF (don't click)"
# a smaller file (56 MB -> ~10): no bump pictures, colour pictures at most 1024 (this copy only; the game is untouched)
for mat in bpy.data.materials:
    if mat.node_tree:
        for n in list(mat.node_tree.nodes):
            if n.type == "NORMAL_MAP" or (n.type == "TEX_IMAGE" and n.image and n.image.name.endswith("_nrm")):
                mat.node_tree.nodes.remove(n)
for im in list(bpy.data.images):
    if im.name.endswith("_nrm"):
        bpy.data.images.remove(im)
    elif im.size[0] > 1024:
        im.scale(1024, 1024)
        im.pack()

# 1. every pose as the game made it (armature space + world), then the animation is removed
caps = []
for i in range(len(data["poses"])):
    sc.frame_set(GLB_FPS_FRAMES * i)
    caps.append({"M": {pb.name: pb.matrix.copy() for pb in arm.pose.bones},
                 "basis": {pb.name: pb.matrix_basis.copy() for pb in arm.pose.bones},
                 "axe": axe.matrix_world.copy(), "arm": arm.matrix_world.copy()})
for o in list(bpy.data.objects):
    if o.name in ("neck_01", "Head") or o.name.startswith("_PhysicalBone"):
        bpy.data.objects.remove(o)
for o in bpy.data.objects:
    o.animation_data_clear()
for a in list(bpy.data.actions):
    bpy.data.actions.remove(a)
ref = caps[0]
for pb in arm.pose.bones:
    pb.rotation_mode = "QUATERNION"
    pb.matrix_basis = ref["basis"][pb.name]
arm.matrix_world = ref["arm"]
axe.matrix_world = ref["axe"]
bpy.context.view_layer.update()
# The game stretches some bones (DwarfProportions): Blender's IK can't handle stretched bones (the wrists missed by
# 4-11 cm). So this stance becomes his rest shape here: the body is baked into it and every bone starts unstretched.
# (Only Blender's picture changes; the reader works on changes from this pose, so the game's numbers stay exact.)
meshes = [o for o in bpy.data.objects if o.type == "MESH" and any(m.type == "ARMATURE" for m in o.modifiers)]
for o in meshes:
    for m in [m for m in o.modifiers if m.type == "ARMATURE"]:
        with bpy.context.temp_override(object=o, active_object=o, selected_objects=[o]):
            bpy.ops.object.modifier_apply(modifier=m.name)
bpy.context.view_layer.objects.active = arm
with bpy.context.temp_override(object=arm, active_object=arm, selected_objects=[arm]):
    bpy.ops.object.mode_set(mode="POSE")
    bpy.ops.pose.armature_apply(selected=False)
    bpy.ops.object.mode_set(mode="OBJECT")
for o in meshes:
    o.modifiers.new("Armature", "ARMATURE").object = arm
# (he's a bit wider than tall in the game: baked in too, else every turn copied onto a bone came out skewed)
with bpy.context.temp_override(selected_editable_objects=[arm] + meshes, selected_objects=[arm] + meshes,
                               active_object=arm, object=arm):
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
bpy.context.view_layer.update()
ref["M"] = {pb.name: pb.matrix.copy() for pb in arm.pose.bones}
ref["arm"] = arm.matrix_world.copy()  # (the stance's bones, measured again after the baking)
AW = arm.matrix_world.copy()


def bone_world(cap, name):
    return cap["arm"] @ cap["M"][name]


coll = bpy.data.collections.new("CONTROLS")
sc.collection.children.link(coll)
helpers = bpy.data.collections.new("helpers (hidden)")
sc.collection.children.link(helpers)


def empty(name, parent, mw, where=helpers, size=0.03):
    o = bpy.data.objects.new(name, None)
    where.objects.link(o)
    o.empty_display_size = size
    o.rotation_mode = "QUATERNION"
    if parent:
        o.parent = parent
    bpy.context.view_layer.update()
    o.matrix_world = mw
    bpy.context.view_layer.update()
    return o


def material(name, rgb, alpha):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    em = nt.nodes.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = (*rgb, 1)
    em.inputs["Strength"].default_value = 1.0
    tr = nt.nodes.new("ShaderNodeBsdfTransparent")
    mix = nt.nodes.new("ShaderNodeMixShader")
    mix.inputs[0].default_value = alpha
    nt.links.new(tr.outputs[0], mix.inputs[1])
    nt.links.new(em.outputs[0], mix.inputs[2])
    nt.links.new(mix.outputs[0], out.inputs[0])
    m.diffuse_color = (*rgb, alpha)
    try:
        m.surface_render_method = "BLENDED"
    except AttributeError:
        m.blend_method = "BLEND"
    m.use_backface_culling = False
    return m


def shape(name, kind, size, rgb, alpha, parent, mw, length=0.0):
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    if kind == "ball":
        bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=10, radius=size)
    elif kind == "ring":  # flat ring (in the shape's XY plane)
        bmesh.ops.create_circle(bm, cap_ends=False, segments=40, radius=size)
        ring = [v for v in bm.verts]
        bmesh.ops.create_circle(bm, cap_ends=False, segments=40, radius=size * 0.86)
        inner = [v for v in bm.verts if v not in ring]
        for k in range(40):
            bm.faces.new((ring[k], ring[(k + 1) % 40], inner[(k + 1) % 40], inner[k]))
    elif kind == "stick":  # along the shape's Y, from 0 to length
        bmesh.ops.create_cone(bm, cap_ends=True, segments=12, radius1=size, radius2=size, depth=length)
        bmesh.ops.rotate(bm, verts=bm.verts, matrix=Matrix.Rotation(math.radians(-90), 3, "X"))
        bmesh.ops.translate(bm, verts=bm.verts, vec=(0, length / 2, 0))
    bm.to_mesh(me)
    bm.free()
    me.materials.append(material(name + "_paint", rgb, alpha))
    o = bpy.data.objects.new(name, me)
    coll.objects.link(o)
    o.rotation_mode = "QUATERNION"
    o.show_in_front = True
    o.color = (*rgb, 1)
    if parent:
        o.parent = parent
    bpy.context.view_layer.update()
    o.matrix_world = mw
    bpy.context.view_layer.update()
    return o


def frame(origin, y_dir, x_hint):  # a world matrix at `origin`, its Y along y_dir
    y = y_dir.normalized()
    x = (x_hint - y * x_hint.dot(y)).normalized()
    z = x.cross(y)
    m = Matrix.Identity(4)
    m.col[0] = (*x, 0)
    m.col[1] = (*y, 0)
    m.col[2] = (*z, 0)
    m.col[3] = (*origin, 1)
    return m


P0 = data["poses"][0]
end0, dir0 = gv(P0["end"]), gd(P0["dir"])

# 2. the axe: an orange stick along the handle, turning round the handle's end (the left fist)
axe_ctrl = shape("AXE", "stick", 0.028, (1.0, 0.45, 0.05), 0.35, None, frame(end0, dir0, Vector((0, 0, 1))),
                 length=0.85)
axe.parent = axe_ctrl
axe.matrix_parent_inverse = axe_ctrl.matrix_world.inverted()
for o in [axe] + list(axe.children_recursive):
    o.hide_select = True


def slide(p, key):  # how far up the handle (m) a fist sits in pose p
    return (gv(p[key]) - gv(p["end"])).dot(gd(p["dir"]))


hand_ctrl = {}
for side, key, rgb, label in [("_l", "left", (0.1, 0.4, 1.0), "LEFT HAND"), ("_r", "right", (1.0, 0.85, 0.05), "RIGHT HAND")]:
    s = slide(P0, key)
    o = shape(label, "ball", 0.065, rgb, 0.35, axe_ctrl, axe_ctrl.matrix_world @ Matrix.Translation((0, s, 0)))
    o.lock_location = (True, False, True)  # (only along the handle)
    o.lock_rotation = (True, True, True)
    o.lock_rotation_w = True
    hand_ctrl[side] = o
    # the wrist's spot, riding on the ball (where the hand bone starts, turned like the hand)
    wrist = empty("wrist" + side, o, rigid(bone_world(ref, "hand" + side)))
    lo = arm.pose.bones["lowerarm" + side]
    ik = lo.constraints.new("IK")
    ik.target = wrist
    ik.chain_count = 3  # (forearm, upper arm and a little of the collarbone: his arms are short)
    ik.use_tail = True
    cl = arm.pose.bones["clavicle" + side]
    cl.ik_stiffness_x = cl.ik_stiffness_y = cl.ik_stiffness_z = 0.7
    cl.lock_ik_y = True
    lo.lock_ik_y = True  # (the forearm doesn't twist round itself: the hand's turn does that)
    arm.pose.bones["upperarm" + side].lock_ik_y = True
    hb = arm.pose.bones["hand" + side]
    cr = hb.constraints.new("COPY_ROTATION")
    cr.target = wrist

# 3. hips (green ring at the waist) and chest (red ring), the feet planted
pel_w = rigid(bone_world(ref, "pelvis"))
hips = shape("HIPS", "ring", 0.30, (0.15, 0.85, 0.2), 0.7, None, Matrix.Translation(pel_w.translation))
pel_o = empty("pelvis_spot", hips, pel_w)
pb = arm.pose.bones["pelvis"]
pb.constraints.new("COPY_LOCATION").target = pel_o
pb.constraints.new("COPY_ROTATION").target = pel_o
s3_w = rigid(bone_world(ref, "spine_03"))
chest = shape("CHEST", "ring", 0.30, (0.95, 0.15, 0.15), 0.7, hips, Matrix.Translation(s3_w.translation))
chest.lock_location = (True, True, True)
for bname, share in SPINE_SHARE.items():
    bw = rigid(bone_world(ref, bname))
    h = empty("turn_" + bname, hips, Matrix.Translation(bw.translation))
    c = h.constraints.new("COPY_ROTATION")
    c.target = chest
    c.owner_space = c.target_space = "LOCAL"
    c.influence = share
    o = empty(bname + "_spot", h, bw)
    arm.pose.bones[bname].constraints.new("COPY_ROTATION").target = o
for side in ("_l", "_r"):
    foot = empty("foot" + side, None, rigid(bone_world(ref, "foot" + side)))
    ik = arm.pose.bones["calf" + side].constraints.new("IK")
    ik.target = foot
    ik.chain_count = 2
    arm.pose.bones["foot" + side].constraints.new("COPY_ROTATION").target = foot
# elbows out to his sides (rules 1) and knees forward: a hidden aim spot for each, the bend lined up with the stance
for side in ("_l", "_r"):
    for top, mid, on, parent in (("upperarm", "lowerarm", "lowerarm", "turn_spine_03"), ("thigh", "calf", "calf", None)):
        s_ = bone_world(ref, top + side).translation
        e_ = bone_world(ref, mid + side).translation
        w_ = (AW @ arm.pose.bones[mid + side].tail)
        line = (w_ - s_).normalized()
        bend = (e_ - s_) - line * (e_ - s_).dot(line)
        aim = empty(mid + side + "_aim", bpy.data.objects[parent] if parent else None,
                    Matrix.Translation(e_ + bend.normalized() * 0.4))
        ik = next(c for c in arm.pose.bones[on + side].constraints if c.type == "IK")
        ik.pole_target = aim
        best = (1e9, 0.0)
        for a in range(-180, 180, 2):
            ik.pole_angle = math.radians(a)
            bpy.context.view_layer.update()
            miss = ((AW @ arm.pose.bones[mid + side].head) - e_).length
            best = min(best, (miss, a))
        ik.pole_angle = math.radians(best[1])
        print("AIM %s%s: pole angle %d, elbow/knee off %.1f cm" % (mid, side, best[1], best[0] * 100))
# the head, hair, beard braids and kilt hem ride along (the game moves them by code after the swing)
for pb in arm.pose.bones:
    for start, on in FOLLOW.items():
        if pb.name.startswith(start) and (pb.parent is None or pb.parent.name == "root"):
            c = pb.constraints.new("CHILD_OF")
            c.target = arm
            c.subtarget = on
            c.inverse_matrix = (AW @ ref["M"][on]).inverted()
            break

# 4. the key poses (chat 8's numbers as a start)
sc.frame_start, sc.frame_end = 1, 41
sc.render.fps = 24
CTRLS = [axe_ctrl, hand_ctrl["_l"], hand_ctrl["_r"], hips, chest]
hips_ref, chest_ref = hips.matrix_world.copy(), chest.matrix_basis.copy()
axe_ref_ctrl = axe_ctrl.matrix_world.copy()
for k, fr in enumerate(KEY_FRAMES):
    cap, p = caps[k + 1], data["poses"][k + 1]
    axe_ctrl.matrix_world = cap["axe"] @ ref["axe"].inverted() @ axe_ref_ctrl
    bpy.context.view_layer.update()
    for side, key in (("_l", "left"), ("_r", "right")):
        hand_ctrl[side].location = (0, slide(p, key), 0)
    dp = rigid(bone_world(cap, "pelvis")) @ pel_w.inverted()
    hips.matrix_world = dp @ hips_ref
    bpy.context.view_layer.update()
    hr = hips.matrix_world.to_quaternion()
    r = hr.inverted() @ rigid(bone_world(cap, "spine_03")).to_quaternion() @ s3_w.to_quaternion().inverted() \
        @ hips_ref.to_quaternion()
    chest.rotation_quaternion = r
    for o in CTRLS:
        o.keyframe_insert("location", frame=fr)
        o.keyframe_insert("rotation_quaternion", frame=fr)
    sc.timeline_markers.new(KEY_NAMES[k], frame=fr)

# a big label over his head on each key frame
for k, fr in enumerate(KEY_FRAMES):
    cu = bpy.data.curves.new("label%d" % k, "FONT")
    cu.body = "POSE " + KEY_NAMES[k]
    cu.size = 0.12
    cu.align_x = "CENTER"
    t = bpy.data.objects.new("label " + KEY_NAMES[k], cu)
    sc.collection.objects.link(t)
    t.location = (0, 0, 1.45)
    t.rotation_euler = (math.radians(90), 0, math.radians(180))  # (readable from behind him, the game camera)
    t.data.materials.append(material("label_paint%d" % k, (1, 1, 1), 1.0))
    t.hide_select = True
    for f in KEY_FRAMES:  # (keys only on the pose frames: the arrow keys jump from pose to pose)
        t.hide_viewport = t.hide_render = f != fr
        t.keyframe_insert("hide_viewport", frame=f)
        t.keyframe_insert("hide_render", frame=f)

# 5. tidy: only the controls can be clicked; bones hidden; auto-keying on; the game's numbers kept for the reader
for o in bpy.data.objects:
    if o not in CTRLS:
        o.hide_select = True
for o in helpers.objects:
    o.hide_set(True)
for bc in list(arm.data.collections):
    bc.is_visible = False
body = arm.data.collections.new("body")
for b in arm.data.bones:
    body.assign(b)
body.is_visible = False
sc.tool_settings.use_keyframe_insert_auto = True
sc.frame_set(1)
txt = bpy.data.texts.new("godot_ref.json")
txt.write(json.dumps({"bones": data["bones"], "parents": data["parents"],
                      "G_ref": data["poses"][0]["globals"], "G_keys": [p["globals"] for p in data["poses"]],
                      "locals_keys": [p["locals"] for p in data["poses"]],
                      "M_ref": {n: as_list(m) for n, m in ref["M"].items()}, "key_frames": KEY_FRAMES, "rig_basis": data["rig_basis"],
                      "key_names": [p["name"] for p in data["poses"][1:]]}))

# 6. check: does each pre-placed pose match the game's? (fists on their balls, bones turned like the game's)
sys.path.insert(0, __import__("os").path.dirname(__file__))
import read_poses  # noqa: E402
for k, fr in enumerate(KEY_FRAMES):
    sc.frame_set(fr)
    got = read_poses.pose_at(sc, arm, json.loads(txt.as_string()))
    worst = read_poses.compare(got, json.loads(txt.as_string()), k + 1)
    miss = [((arm.matrix_world @ arm.pose.bones["hand" + s].head) - bpy.data.objects["wrist" + s].matrix_world.translation).length
            for s in ("_l", "_r")]
    print("CHECK %s: wrist miss L %.3f R %.3f m; biggest bone turn difference: %s" % (KEY_NAMES[k], miss[0], miss[1], worst))
sc.frame_set(1)
bpy.ops.wm.save_as_mainfile(filepath=OUT)
print("SAVED", OUT)
