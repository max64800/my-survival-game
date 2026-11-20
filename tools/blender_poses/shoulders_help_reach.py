"""The shoulders help the arms reach again (owner, Nov 20: "he's not actually holding the axe"): with the shoulder
balls added (add_arm_controls.py), the collarbones had left the arms' reach, so his short arms (34 cm) fell 12 cm short
in the wind-up. Now the shoulder ball sets where the shoulder starts and the arm pulls it further only when it must
(stiffness 0.7). Keeps every pose.
  blender -b tools/blender_poses/great_axe_poses.blend --python tools/blender_poses/shoulders_help_reach.py
By the dwarf-animations Claude, chat 9, Nov 20, 2026.
"""
import bpy

arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
for s in ("_l", "_r"):
    ik = next(c for c in arm.pose.bones["lowerarm" + s].constraints if c.type == "IK")
    ik.chain_count = 3
    cb = arm.pose.bones["clavicle" + s]
    cb.ik_stiffness_x = cb.ik_stiffness_y = cb.ik_stiffness_z = 0.7
    cb.lock_ik_y = True
bpy.ops.wm.save_mainfile(compress=True)
print("DONE")
