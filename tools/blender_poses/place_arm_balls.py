"""Puts the arm balls right ON the joints (owner, Nov 20: "the bubbles actually in the wrist, elbow and shoulder,
not beside it"), keeping every pose he has made:
  - LEFT/RIGHT HAND: drawn on the wrist (the ball still slides along the handle: the wrist goes up and down the hilt).
  - LEFT/RIGHT SHOULDER, LEFT/RIGHT ELBOW: on each pose frame the ball is moved onto the joint (the arm doesn't move:
    the elbow ball is the arm's aim and lies in the arm's bend, the shoulder ball moves its aim spot along).
    A frame where the owner already moved that ball is left alone.
  blender -b tools/blender_poses/great_axe_poses.blend --python tools/blender_poses/place_arm_balls.py
By the dwarf-animations Claude, chat 9, Nov 20, 2026.
"""
import bpy
from mathutils import Matrix, Vector

sc = bpy.context.scene
arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
KEY_FRAMES = [1, 11, 21, 31, 41]

# 1. the hand balls drawn on the wrist (the mesh moves inside the ball; the ball's place on the handle stays)
for side, word in (("_l", "LEFT"), ("_r", "RIGHT")):
    ball = bpy.data.objects[word + " HAND"]
    if ball.data.get("on_wrist") is None:
        off = bpy.data.objects["wrist" + side].matrix_local.translation.copy()
        ball.data.transform(Matrix.Translation(off))
        ball.data["on_wrist"] = 1


def keyed(o, frame):
    """The ball's keyed place on a frame (its location F-curves)."""
    act = o.animation_data.action if o.animation_data else None
    if not act:
        return tuple(o.location)
    vals = []
    for i in range(3):
        fc = None
        for f in getattr(act, "fcurves", []):
            if f.data_path == "location" and f.array_index == i:
                fc = f
        if fc is None:  # (Blender 5: channels live in the action's layers)
            for layer in act.layers:
                for strip in layer.strips:
                    for bag in strip.channelbags:
                        for f in bag.fcurves:
                            if f.data_path == "location" and f.array_index == i:
                                fc = f
        vals.append(round(fc.evaluate(frame), 5) if fc else round(o.location[i], 5))
    return tuple(vals)


# 2. shoulder and elbow balls onto their joints, pose by pose (a few rounds: each move changes the arm a hair)
for side, word in (("_l", "LEFT"), ("_r", "RIGHT")):
    for ball_name, joint in ((word + " SHOULDER", "upperarm"), (word + " ELBOW", "lowerarm")):
        ball = bpy.data.objects[ball_name]
        at = [keyed(ball, f) for f in KEY_FRAMES]
        common = max(set(at), key=at.count)  # (the place it was made with; another value = the owner moved it there)
        for f, was in zip(KEY_FRAMES, at):
            if was != common:
                print("KEPT", ball_name, "frame", f, "(the owner moved it)")
                continue
            sc.frame_set(f)
            for _ in range(4):
                bpy.context.view_layer.update()
                j = arm.matrix_world @ arm.pose.bones[joint + side].head
                ball.location = ball.parent.matrix_world.inverted() @ j if ball.matrix_parent_inverse == Matrix.Identity(4) \
                    else (ball.parent.matrix_world @ ball.matrix_parent_inverse).inverted() @ j
                ball.keyframe_insert("location", frame=f)
                sc.frame_set(f)
            bpy.context.view_layer.update()
            miss = ((arm.matrix_world @ arm.pose.bones[joint + side].head) - ball.matrix_world.translation).length
            print("ON JOINT %s frame %d: %.1f cm off" % (ball_name, f, miss * 100))
sc.frame_set(1)
bpy.ops.wm.save_mainfile(compress=True)
print("DONE")
