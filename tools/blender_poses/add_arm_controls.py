"""Adds shoulder and elbow balls to the owner's pose file, keeping every pose he has made (owner, Nov 20: "can you
give me more bubbles: the shoulder, the elbow, where the hand is placed").
  LEFT/RIGHT SHOULDER (purple): G pulls the shoulder up, down, forward or back (the collarbone points at it).
  LEFT/RIGHT ELBOW (pink): G pulls where the elbow points (the arm's bend turns toward it).
  The hand balls get bigger (easier to grab).
The new balls ride on the chest (they turn with him) and get a key on every pose frame, so moving one on a pose
only changes that pose.
  blender -b tools/blender_poses/great_axe_poses.blend --python tools/blender_poses/add_arm_controls.py
By the dwarf-animations Claude, chat 9, Nov 20, 2026.
"""
import math
import bpy
from mathutils import Matrix

import bmesh


def shape(name, kind, size, rgb, alpha, parent, mw):
    """A see-through ball control, like make_pose_file.py's (drawn in front of his body)."""
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=10, radius=size)
    bm.to_mesh(me)
    bm.free()
    m = bpy.data.materials["LEFT HAND_paint"].copy()  # (same see-through paint, own colour)
    m.name = name + "_paint"
    m.diffuse_color = (*rgb, alpha)
    for n in m.node_tree.nodes:
        if n.type == "EMISSION":
            n.inputs["Color"].default_value = (*rgb, 1)
    me.materials.append(m)
    o = bpy.data.objects.new(name, me)
    bpy.data.collections["CONTROLS"].objects.link(o)
    o.show_in_front = True
    o.color = (*rgb, 1)
    o.parent = parent
    bpy.context.view_layer.update()
    o.matrix_world = mw
    bpy.context.view_layer.update()
    return o

sc = bpy.context.scene
arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
chest_turn = bpy.data.objects["turn_spine_03"]
KEY_FRAMES = [1, 11, 21, 31, 41]
sc.frame_set(1)
bpy.context.view_layer.update()
AW = arm.matrix_world
added = []
for side, word in (("_l", "LEFT"), ("_r", "RIGHT")):
    if (word + " ELBOW") in bpy.data.objects:
        continue
    ik = next(c for c in arm.pose.bones["lowerarm" + side].constraints if c.type == "IK")
    s_ = AW @ arm.pose.bones["upperarm" + side].head
    e_ = AW @ arm.pose.bones["lowerarm" + side].head
    w_ = AW @ arm.pose.bones["lowerarm" + side].tail
    line = (w_ - s_).normalized()
    bend = ((e_ - s_) - line * (e_ - s_).dot(line)).normalized()
    # the shoulder: the collarbone points at its ball (the arm's reach no longer moves it)
    sh = shape(word + " SHOULDER", "ball", 0.045, (0.6, 0.25, 0.95), 0.45, chest_turn, Matrix.Translation(s_))
    # (Blender's collarbone doesn't point exactly at the shoulder joint: it aims at a hidden spot riding on the ball,
    # put where it points now, so nothing jumps; moving the ball moves the spot the same way)
    cb = arm.pose.bones["clavicle" + side]
    y = (AW.to_3x3() @ (cb.matrix.to_3x3() @ Matrix.Identity(3).col[1])).normalized()
    aim_at = (AW @ cb.head) + y * ((s_ - (AW @ cb.head)).length)
    spot = bpy.data.objects.new("shoulder" + side + "_spot", None)
    bpy.data.collections["helpers (hidden)"].objects.link(spot)
    spot.parent = sh
    bpy.context.view_layer.update()
    spot.matrix_world = Matrix.Translation(aim_at)
    spot.hide_set(True)
    spot.hide_select = True
    dt = cb.constraints.new("DAMPED_TRACK")
    dt.target = spot
    dt.track_axis = "TRACK_Y"
    ik.chain_count = 2
    # the elbow: a ball just outside the elbow; the arm's bend turns toward it
    before = e_.copy()
    el = shape(word + " ELBOW", "ball", 0.045, (1.0, 0.35, 0.7), 0.45, chest_turn, Matrix.Translation(e_ + bend * 0.12))
    ik.pole_target = el
    best = (1e9, 0.0)
    for a in range(-180, 180, 2):
        ik.pole_angle = math.radians(a)
        bpy.context.view_layer.update()
        best = min(best, (((AW @ arm.pose.bones["lowerarm" + side].head) - before).length, a))
    ik.pole_angle = math.radians(best[1])
    print("ELBOW %s: pole angle %d, elbow moved %.1f cm" % (side, best[1], best[0] * 100))
    old = bpy.data.objects.get("lowerarm" + side + "_aim")
    if old:
        bpy.data.objects.remove(old)
    added += [sh, el]
for o in added:
    o.lock_rotation = (True, True, True)
    o.lock_rotation_w = True
    for f in KEY_FRAMES:
        o.keyframe_insert("location", frame=f)
for name in ("LEFT HAND", "RIGHT HAND"):  # (bigger, easier to grab: the mesh grows, the ball's place stays)
    me = bpy.data.objects[name].data
    if me.get("grown") is None:
        me.transform(Matrix.Scale(1.5, 4))
        me["grown"] = 1
sc.frame_set(1)
bpy.ops.wm.save_mainfile(compress=True)
print("ADDED", [o.name for o in added])
