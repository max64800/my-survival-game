"""Reads the owner's great axe poses out of his Blender file and writes them for the game (F389, Nov 20).

For each key frame (1, 11, 21, 31, 41): every body bone's turn, in the game's own numbers (Godot skeleton space).
How: Blender keeps the game's pose from the day the file was made (the text block "godot_ref.json": the game's bone
poses, and Blender's). A bone's change since then (Blender) is the same change in the game:
    game_now = C^-1 * blender_now * blender_ref^-1 * C * game_ref      (C = Godot y-up -> Blender z-up)
Then each bone's turn relative to its parent bone is what the game sets (DwarfFist plays them).
  blender -b tools/blender_poses/great_axe_poses.blend --python tools/blender_poses/read_poses.py -- <out.json> [Chop]
By the dwarf-animations Claude, chat 9, Nov 20, 2026.
"""
import json
import sys
from mathutils import Matrix

C = Matrix(((1, 0, 0, 0), (0, 0, -1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))
CI = C.inverted()
## the bones the owner's controls move (the fingers close by code; the head, hair and hem follow by code)
USED = ["pelvis", "spine_01", "spine_02", "spine_03", "clavicle_l", "upperarm_l", "lowerarm_l", "hand_l",
        "clavicle_r", "upperarm_r", "lowerarm_r", "hand_r", "thigh_l", "calf_l", "foot_l", "thigh_r", "calf_r", "foot_r"]


def gm(a):
    m = Matrix.Identity(4)
    for c in range(3):
        m.col[c] = (a[c * 3], a[c * 3 + 1], a[c * 3 + 2], 0.0)
    m.col[3] = (a[9], a[10], a[11], 1.0)
    return m


def pose_at(sc, arm, ref):
    """The pose on the current frame: {bone: [x, y, z, w] turn relative to its parent (Godot)}, + "pelvis_pos"."""
    names, parents = ref["bones"], ref["parents"]
    G = {}
    for i, n in enumerate(names):
        pb = arm.pose.bones.get(n)
        if pb is None:
            continue
        m_ref = Matrix(ref["M_ref"][n])
        G[n] = CI @ pb.matrix @ m_ref.inverted() @ C @ gm(ref["G_ref"][i])
    out = {}
    for n in USED:
        i = names.index(n)
        par = names[parents[i]] if parents[i] >= 0 else None
        local = (G[par].inverted() @ G[n]) if par else G[n]
        _, q, _ = local.decompose()
        out[n] = [q.x, q.y, q.z, q.w]
        if n == "pelvis":
            out["pelvis_pos"] = list(local.translation)
    return out


def compare(got, ref, k):
    """The biggest difference (degrees) between `got` and the game's key pose k (the check when the file is made)."""
    from mathutils import Quaternion
    worst = (0.0, "")
    for n in USED:
        g = ref["locals_keys"][k][ref["bones"].index(n)]
        a = Quaternion((g[3], g[0], g[1], g[2]))
        b = Quaternion((got[n][3], got[n][0], got[n][1], got[n][2]))
        d = abs((a.inverted() @ b).angle)
        d = min(d, 6.283185 - d) * 57.2958
        if d > worst[0]:
            worst = (d, n)
    return "%.1f deg (%s)" % worst


if __name__ == "__main__":
    import bpy
    args = sys.argv[sys.argv.index("--") + 1:]
    out_path = args[0]
    move = args[1] if len(args) > 1 else "Chop"
    sc = bpy.context.scene
    ref = json.loads(bpy.data.texts["godot_ref.json"].as_string())
    arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    keys = []
    for name, fr in zip(ref["key_names"], ref["key_frames"]):
        sc.frame_set(fr)
        p = pose_at(sc, arm, ref)
        # the axe as he holds it (in his own frame, the game's: it turns with him) and how far up the handle the left fist sits (the handle's end is that far below it)
        rb = gm(ref["rig_basis"]).to_3x3()
        axe = (rb.inverted() @ CI.to_3x3() @ bpy.data.objects["axe"].matrix_world.to_3x3().normalized())
        keys.append({"name": name, "frame": fr, "pelvis_pos": p.pop("pelvis_pos"), "bones": p,
                     "axe": [axe[r][c] for c in range(3) for r in range(3)],
                     "left_slide": bpy.data.objects["LEFT HAND"].location.y})
    try:
        everything = json.load(open(out_path))
    except (OSError, ValueError):
        everything = {}
    everything[move] = keys
    everything["_note"] = ("The owner's great axe poses, made in Blender (tools/blender_poses/great_axe_poses.blend) and "
                           "read by tools/blender_poses/read_poses.py: per key pose, each bone's turn relative to its "
                           "parent [x, y, z, w] and the hips' position (Godot skeleton numbers). Played by DwarfFist.")
    with open(out_path, "w") as f:
        json.dump(everything, f, indent=1)
    print("WROTE", out_path, move, len(keys), "poses")
