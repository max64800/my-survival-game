"""Owner, Nov 20 (screenshot): one ball on the fist (on the handle), one on the wrist, one on the elbow, one on the
shoulder: "I want to move the wrist here and I cannot". Keeps every pose he has made.
  - LEFT/RIGHT HAND (blue/yellow): drawn on the fist again; slides along the handle.
  - LEFT/RIGHT WRIST (cyan, new): on the wrist, rides on the hand ball; G moves the wrist freely: the forearm follows
    and the hand turns so the fist keeps gripping the handle.
  - SHOULDER (purple) and ELBOW (pink) balls: bigger, strong colours.
  blender -b tools/blender_poses/great_axe_poses.blend --python tools/blender_poses/add_wrist_balls.py
By the dwarf-animations Claude, chat 9, Nov 20, 2026.
"""
import bpy
import bmesh
from mathutils import Matrix

sc = bpy.context.scene
arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
KEY_FRAMES = [1, 11, 21, 31, 41]
CYAN, PURPLE, PINK = (0.0, 0.85, 0.95), (0.55, 0.15, 1.0), (1.0, 0.2, 0.6)
sc.frame_set(1)
bpy.context.view_layer.update()
# where each hand points now, measured before anything changes (measured later, after the wrist spot moved to its
# new ball, it came out wrong and every hand turned 6 cm off the handle: the owner's "he's not holding the axe")
TAIL = {s: (arm.matrix_world @ arm.pose.bones["hand" + s].tail).copy() for s in ("_l", "_r")}


def paint(o, rgb, alpha=0.7):
    m = o.active_material.copy() if o.active_material else bpy.data.materials["LEFT HAND_paint"].copy()
    m.name = o.name + "_paint"
    m.diffuse_color = (*rgb, alpha)
    for n in m.node_tree.nodes:
        if n.type == "EMISSION":
            n.inputs["Color"].default_value = (*rgb, 1)
            n.inputs["Strength"].default_value = 1.0
        if n.type == "MIX_SHADER":
            n.inputs[0].default_value = alpha
    o.data.materials.clear()
    o.data.materials.append(m)
    o.color = (*rgb, 1)


def ball(name, radius, rgb, parent, world_at):
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=10, radius=radius)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    bpy.data.collections["CONTROLS"].objects.link(o)
    o.show_in_front = True
    o.parent = parent
    bpy.context.view_layer.update()
    o.matrix_world = Matrix.Translation(world_at)
    bpy.context.view_layer.update()
    paint(o, rgb)
    o.lock_rotation = (True, True, True)
    o.lock_rotation_w = True
    return o


for side, word in (("_l", "LEFT"), ("_r", "RIGHT")):
    hand = bpy.data.objects[word + " HAND"]
    wrist_spot = bpy.data.objects["wrist" + side]
    if hand.data.get("on_wrist"):  # (back on the fist)
        hand.data.transform(Matrix.Translation(-wrist_spot.matrix_local.translation))
        del hand.data["on_wrist"]
    if (word + " WRIST") in bpy.data.objects:
        continue
    # the wrist ball, on the wrist; the arm's reach target rides on it
    w = ball(word + " WRIST", 0.04, CYAN, hand, wrist_spot.matrix_world.translation.copy())
    keep = wrist_spot.matrix_world.copy()
    wrist_spot.parent = w
    wrist_spot.matrix_parent_inverse = Matrix.Identity(4)
    bpy.context.view_layer.update()
    wrist_spot.matrix_world = keep
    # the hand turns so the fist keeps pointing at its grip on the handle (a hidden spot on the hand ball, put where
    # the hand points now, so nothing jumps)
    hb = arm.pose.bones["hand" + side]
    grip = bpy.data.objects.new("grip" + side + "_spot", None)
    bpy.data.collections["helpers (hidden)"].objects.link(grip)
    grip.parent = hand
    bpy.context.view_layer.update()
    grip.matrix_world = Matrix.Translation(TAIL[side])
    grip.hide_set(True)
    grip.hide_select = True
    dt = hb.constraints.new("DAMPED_TRACK")
    dt.target = grip
    dt.track_axis = "TRACK_Y"
    # the wrist only swings round the fist (it can't pull the fist off the handle: owner, "he's not holding the axe")
    ld = w.constraints.new("LIMIT_DISTANCE")
    ld.target = hand
    ld.distance = (w.matrix_world.translation - hand.matrix_world.translation).length
    ld.limit_mode = "LIMITDIST_ONSURFACE"
    for f in KEY_FRAMES:
        w.keyframe_insert("location", frame=f)
    print("WRIST", side, "added")

# shoulder and elbow balls: bigger and strong colours (the owner couldn't see them)
for word in ("LEFT", "RIGHT"):
    for name, rgb in ((word + " SHOULDER", PURPLE), (word + " ELBOW", PINK)):
        o = bpy.data.objects[name]
        if o.data.get("bigger") is None:
            o.data.transform(Matrix.Scale(1.35, 4))
            o.data["bigger"] = 1
        paint(o, rgb)
sc.frame_set(1)
bpy.ops.wm.save_mainfile(compress=True)
print("DONE")
