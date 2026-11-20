"""Copies the owner's filmed swing onto the dwarf by moving the pose file's controls (F389, chat 10, Nov 20, 2026).

The owner doesn't move the Blender controls himself any more: he films the swing (front view), Claude picks the key
frames with him (ready, wind-up top, middle, hit, recovery), and this script poses the dwarf from them.

What it copies (docs/art/ANIMATION-RULES.md 4: directions, angles, twist, lean and timing; never his distances):
  - each fist's direction from its shoulder, as a share of the arm's length (his long arms -> the dwarf's 34 cm ones)
  - the elbows' bend direction (mixed with "elbows out to the sides", rules 1)
  - the hips' turn, the chest's twist, lean and side tilt, and how far the hips drop (knees bend)
The camera's depth guess is rough, so the fists' left-right and up-down count fully, their depth only a little: his
own body decides the rest. For each pose a small search places the axe through both fists so that:
  both wrists are within reach of their shoulders, the handle stays 3.5 cm off his body (belly, beard, chest, legs)
  and the axe head 10 cm off, and the fists land as near as possible to the filmed spots.
Then every control gets a key on that pose's frame (AXE, LEFT/RIGHT HAND slide, LEFT/RIGHT WRIST, ELBOW, SHOULDER,
HIPS, CHEST), so read_poses.py and the game see it exactly like a hand-made pose.

  blender -b tools/blender_poses/great_axe_poses.blend --python tools/blender_poses/pose_from_video.py -- \
      <video_targets.json> <Move> [first_frame] [--edit <tweaks.json>] [--save]
<video_targets.json>: from the video (tools/mocap): per move 5 keys with lw/rw/le/re (wrist/elbow from shoulder, in
arm lengths, Blender axes: x = his left, y = his back, z = up), hip_yaw, sh_yaw, lean, side, hip_drop.
<tweaks.json>: Claude's per-pose corrections after looking at the pictures ({Move: {key: {...}}}, see TWEAKS below).
"""
import json
import math
import sys

import bpy
from mathutils import Euler, Matrix, Quaternion, Vector
from mathutils.kdtree import KDTree

args = sys.argv[sys.argv.index("--") + 1:]
TARGETS, MOVE = args[0], args[1]
FIRST = int(args[2]) if len(args) > 2 and args[2].isdigit() else 1
EDIT = args[args.index("--edit") + 1] if "--edit" in args else None
SAVE = "--save" in args
FRAMES = [FIRST + 10 * k for k in range(5)]
ARM_REACH = 0.33          # shoulder -> wrist the IK can reach comfortably (bones 0.159 + 0.177, a little bend left)
HANDLE_CLEAR, HEAD_CLEAR = 0.035, 0.10
BODY = ("body_torso", "body_shirt", "body_head", "body_pants", "body_shorts")
ARM_BONES = ("clavicle", "upperarm", "lowerarm", "hand", "thumb", "index", "middle", "ring", "pinky")
# Which way the blade's edge faces at each key (his own frame: x = his left, -y = his front, z = up): the way the
# head moves next. (A hint: it is turned to be square to the handle.)
EDGE = {
    "Chop": {"ready": (0.0, -1.0, 0.2), "windup": (0.2, -1.0, -0.2), "middle": (0.5, -0.6, -0.7),
             "hit": (0.4, -0.4, -0.8), "recovery": (0.3, -0.7, -0.6)},
    "Stab": {"ready": (0.3, -0.7, -0.6), "windup": (0.0, -0.3, -1.0), "middle": (0.0, -0.3, -1.0),
             "hit": (0.0, -0.3, -1.0), "recovery": (0.0, -0.5, -0.8)},
    "Overhead": {"ready": (0.0, -0.5, -0.8), "windup": (0.0, -1.0, 0.0), "middle": (0.0, -0.6, -0.8),
                 "hit": (0.0, -0.2, -1.0), "recovery": (0.0, -1.0, 0.2)},
}

sc = bpy.context.scene
arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
AW = arm.matrix_world.copy()
O = bpy.data.objects
axe_ctrl, hips, chest = O["AXE"], O["HIPS"], O["CHEST"]
data = json.load(open(TARGETS))[MOVE]
tweaks = (json.load(open(EDIT)).get(MOVE, {}) if EDIT else {})


def upd():
    bpy.context.view_layer.update()


def head(b):
    return AW @ arm.pose.bones[b].head


def set_world_loc(o, p):
    """Moves object o so its origin lands on world point p (keeps its turn)."""
    pm = (o.parent.matrix_world @ o.matrix_parent_inverse) if o.parent else Matrix.Identity(4)
    o.location = (pm.inverted() @ Vector(p))


def key(o):
    o.keyframe_insert("location", frame=sc.frame_current)
    if o.rotation_mode == "QUATERNION":
        o.keyframe_insert("rotation_quaternion", frame=sc.frame_current)


# ---- the axe's own shape, in the AXE control's frame (Y = along the handle from its end) ----
sc.frame_set(FRAMES[0])
upd()
model = O["model"]
inv = axe_ctrl.matrix_world.inverted()
pts = [inv @ (model.matrix_world @ v.co) for v in model.data.vertices]
TIP = max(p.y for p in pts)
head_pts = [p for p in pts if p.y > TIP - 0.28]
cx = sum(p.x for p in head_pts) / len(head_pts)
cz = sum(p.z for p in head_pts) / len(head_pts)
far = max(head_pts, key=lambda p: math.hypot(p.x, p.z))
BLADE = Vector((far.x, 0, far.z)).normalized()  # (the edge: the farthest point of the head from the handle)
HEAD_FROM = TIP - 0.28
print("AXE: tip %.2f m up the handle, head centre (%.2f, %.2f), edge toward (%.2f, %.2f) in its frame"
      % (TIP, cx, cz, BLADE.x, BLADE.z))

# ---- rest: hips and chest straight, shoulder balls on the joints of the stance ----
HIPS_REST = AW @ arm.data.bones["pelvis"].head_local
# stiffer collarbones (owner, round 2: reaching across pulled his right shoulder up to his nose)
for s_ in ("_l", "_r"):
    cb_ = arm.pose.bones["clavicle" + s_]
    cb_.ik_stiffness_x = cb_.ik_stiffness_y = cb_.ik_stiffness_z = 0.9


# Level shoulders (armature rest space). The file's rest shape is the old game stance, where the collarbones had
# pulled the left shoulder 14 cm forward and the right one 15 cm back and 6 cm up to make the arms reach; every
# pose started crooked from that (owner, chat 10 round 1: "doesn't look good", arms drawn wrong). Both shoulders
# now start level and alike: the middle of the two, mirrored.
NEUTRAL = {"_l": Vector((0.24, -0.03, 0.68)), "_r": Vector((-0.25, -0.03, 0.68))}


def shoulder_rest_spots():
    """Where each SHOULDER ball must sit so the collarbone turns the shoulder joint onto its level spot."""
    out = {}
    for s, word in (("_l", "LEFT"), ("_r", "RIGHT")):
        ball, spot = O[word + " SHOULDER"], O["shoulder" + s + "_spot"]
        b = arm.data.bones["clavicle" + s]
        c_head = AW @ b.head_local
        now = AW @ arm.data.bones["upperarm" + s].head_local - c_head
        turn = now.rotation_difference(AW @ NEUTRAL[s] - c_head)
        y_rest = (AW.to_3x3() @ b.matrix_local.to_3x3().col[1]).normalized()
        delta = spot.matrix_world.translation - ball.matrix_world.translation
        reach = (spot.matrix_world.translation - c_head).length
        out[word] = (c_head + (turn @ y_rest) * reach) - delta
    return out


def body_tree():
    """Every body point that isn't on his arms (world), in a KD-tree for distance checks."""
    dg = bpy.context.evaluated_depsgraph_get()
    pts = []
    global BODY_NAMES
    BODY_NAMES = []
    for name in BODY:
        o = O.get(name)
        if o is None:
            continue
        groups = {g.index: g.name for g in o.vertex_groups}
        ev = o.evaluated_get(dg)
        me = ev.to_mesh()
        for v_orig, v in zip(o.data.vertices, me.vertices):
            best = max(v_orig.groups, key=lambda g: g.weight, default=None)
            if best is not None and groups.get(best.group, "").startswith(ARM_BONES):
                continue
            pts.append(ev.matrix_world @ v.co)
            BODY_NAMES.append(name + ":" + (groups.get(best.group, "?") if best else "?"))
        ev.to_mesh_clear()
    kd = KDTree(len(pts))
    for i, p in enumerate(pts):
        kd.insert(p, i)
    kd.balance()
    return kd


def clearance(kd, end, d, why=False):
    """Smallest gap from the handle (and from the head, with its own margin) to his body; < 0 = too close."""
    worst, at = 9.0, None
    n = int(TIP / 0.02) + 1
    for i in range(n):
        t = i * TIP / (n - 1)
        p = end + d * t
        _, idx, dist = kd.find(p)
        need = HEAD_CLEAR if t > HEAD_FROM else HANDLE_CLEAR
        if dist - need < worst:
            worst, at = dist - need, (t, BODY_NAMES[idx])
    return (worst, at) if why else worst


def nelder_mead(f, x0, step, iters=400):
    n = len(x0)
    pts = [list(x0)] + [[x0[j] + (step[j] if j == i else 0.0) for j in range(n)] for i in range(n)]
    vals = [f(p) for p in pts]
    for _ in range(iters):
        order = sorted(range(n + 1), key=lambda i: vals[i])
        pts, vals = [pts[i] for i in order], [vals[i] for i in order]
        c = [sum(p[j] for p in pts[:-1]) / n for j in range(n)]
        r = [c[j] + (c[j] - pts[-1][j]) for j in range(n)]
        fr = f(r)
        if fr < vals[0]:
            e = [c[j] + 2 * (c[j] - pts[-1][j]) for j in range(n)]
            fe = f(e)
            pts[-1], vals[-1] = (e, fe) if fe < fr else (r, fr)
        elif fr < vals[-2]:
            pts[-1], vals[-1] = r, fr
        else:
            k = [c[j] + 0.5 * (pts[-1][j] - c[j]) for j in range(n)]
            fk = f(k)
            if fk < vals[-1]:
                pts[-1], vals[-1] = k, fk
            else:
                pts = [pts[0]] + [[pts[0][j] + 0.5 * (p[j] - pts[0][j]) for j in range(n)] for p in pts[1:]]
                vals = [vals[0]] + [f(p) for p in pts[1:]]
    i = min(range(n + 1), key=lambda i: vals[i])
    return pts[i], vals[i]


def dir_from(yaw, pitch):
    return Vector((math.cos(pitch) * math.cos(yaw), math.cos(pitch) * math.sin(yaw), math.sin(pitch)))


ref_hip_yaw = data[0]["hip_yaw"] if MOVE == "Chop" else json.load(open(TARGETS))["Chop"][0]["hip_yaw"]
ref_side = json.load(open(TARGETS))["Chop"][0]["side"]
SH_REST = None
report = []
for k, fr in zip(data, FRAMES):
    tw = tweaks.get(k["name"], {})
    sc.frame_set(fr)
    # 1. hips and chest (hips lead: the hips take their own filmed turn, the chest the rest)
    hip_yaw = k["hip_yaw"] - ref_hip_yaw + tw.get("hip_yaw", 0.0)
    chest_yaw = k.get("chest_yaw", k["sh_yaw"]) - ref_hip_yaw + tw.get("chest_yaw", 0.0)
    lean = k["lean"] + tw.get("lean", 0.0)
    side = 0.5 * (k["side"] - ref_side) + tw.get("side", 0.0)
    drop = max(0.0, k["hip_drop"]) * 0.25 + (0.03 if k["name"] == "hit" else 0.01) + tw.get("drop", 0.0)
    hips.location = HIPS_REST + Vector((0, 0, -drop)) + Vector(tw.get("hips_move", (0, 0, 0)))
    hips.rotation_quaternion = (Euler((math.radians(0.3 * lean), 0, math.radians(hip_yaw)), "ZXY")).to_quaternion()
    chest.rotation_quaternion = (Euler((math.radians(0.7 * lean), math.radians(side), math.radians(chest_yaw - hip_yaw)),
                                       "ZXY")).to_quaternion()
    upd()
    # 2. shoulder balls back on the stance's joints (chat 8's start poses had the right one 30 cm too high)
    if SH_REST is None:
        keep = chest.rotation_quaternion.copy(), hips.location.copy(), hips.rotation_quaternion.copy()
        chest.rotation_quaternion = Quaternion()
        hips.location, hips.rotation_quaternion = HIPS_REST, Quaternion()
        upd()
        SH_REST = {}
        for w, p in shoulder_rest_spots().items():
            set_world_loc(O[w + " SHOULDER"], p)
            SH_REST[w] = O[w + " SHOULDER"].location.copy()
        chest.rotation_quaternion, hips.location, hips.rotation_quaternion = keep
        upd()
    for w in ("LEFT", "RIGHT"):
        O[w + " SHOULDER"].location = SH_REST[w]  # (rides on the chest: same spot on every pose)
    upd()
    # 3. where his fists and elbows should go (the filmed directions on his own arms)
    yaw_m = Matrix.Rotation(math.radians(chest_yaw), 3, "Z")
    # (the shoulders as the chest carries them, not where the arm last pulled them: the same answer every run)
    ch = arm.pose.bones["spine_03"].matrix @ arm.data.bones["spine_03"].matrix_local.inverted()
    sh = {s: AW @ ch @ NEUTRAL[s] for s in ("_l", "_r")}
    want = {"_l": sh["_l"] + Vector(k["lw"]) * ARM_REACH + Vector(tw.get("left_move", (0, 0, 0))),
            "_r": sh["_r"] + Vector(k["rw"]) * ARM_REACH + Vector(tw.get("right_move", (0, 0, 0)))}
    d_vid = (want["_r"] - want["_l"]).normalized()
    ext = {"_l": min(1.0, Vector(k["lw"]).length) * ARM_REACH, "_r": min(1.0, Vector(k["rw"]).length) * ARM_REACH}
    if "dir_cam" in tw:  # (read from the picture: [angle in the picture, tilt toward the camera])
        th, ph = math.radians(tw["dir_cam"][0]), math.radians(tw["dir_cam"][1])
        d_vid = Vector((math.cos(ph) * math.cos(th), -math.sin(ph), math.cos(ph) * math.sin(th))).normalized()
    kd = body_tree()
    slide_l = O["LEFT HAND"].location.y
    r_wr = {s: O[w + " WRIST"].constraints["Limit Distance"].distance for s, w in (("_l", "LEFT"), ("_r", "RIGHT"))}
    gap_min = 0.14 if MOVE == "Overhead" and k["name"] in ("hit", "recovery") else 0.30
    gap_want = tw.get("gap", None)

    def wrist_of(fist, d, s):
        u = sh[s] - fist
        u = (u - d * u.dot(d))
        return fist + u.normalized() * r_wr[s] if u.length > 1e-6 else fist

    def place(x):
        d = dir_from(x[3], x[4])
        c = Vector(x[0:3])
        gap = x[5]
        return c - d * gap / 2, c + d * gap / 2, d, gap

    def cost(x, parts=None):
        fl, frr, d, gap = place(x)
        e = 0.0
        for fist, s in ((fl, "_l"), (frr, "_r")):
            dv = fist - want[s]
            e += 4 * (dv.x ** 2 + dv.z ** 2) + 0.05 * dv.y ** 2  # (the camera's depth guess is rough)
            # how straight the arm is, as filmed (owner round 1: his arms hang nearly straight; a folded arm read wrong)
            reach = (wrist_of(fist, d, s) - sh[s]).length
            e += 6 * (reach - ext[s]) ** 2
            over = reach - ARM_REACH
            if over > 0:
                e += 400 * over ** 2
        e += 3.0 * (1 - d.dot(d_vid))  # (the handle's slant matters most: it is what the eye reads)
        if gap < gap_min:
            e += 50 * (gap_min - gap) ** 2
        if gap_want is not None:
            e += 5 * (gap - gap_want) ** 2
        e_arms = e
        cl = clearance(kd, fl - d * slide_l, d)
        if cl < 0:
            e += 600 * cl ** 2
        if parts is not None:
            parts.update(arms_and_slant=round(e_arms, 4), body=round(e - e_arms, 4), total=round(e, 4))
        return e

    c0 = (want["_l"] + want["_r"]) / 2
    yaw0, pitch0 = math.atan2(d_vid.y, d_vid.x), math.asin(max(-1, min(1, d_vid.z)))
    best = None
    starts = [(push, g) for push in (0.0, 0.08, 0.16) for g in (0.30, 0.45, 0.60)]
    if "start" in tw:  # (a hand-picked start: [centre between the fists (his frame, from the chest)], tried too)
        starts.append(("probe", tw.get("gap", 0.35)))
    for push, g in starts:  # (starts a bit further out in front too: the belly is big)
        front = yaw_m @ Vector((0, -1, 0))
        x0 = [*(c0 + front * push), yaw0, pitch0, max(gap_min, g)] if push != "probe" else             [*(head("spine_03") + yaw_m @ Vector(tw["start"])), yaw0, pitch0, g]
        if "--debug" in args:
            pp = {}
            cost(x0, pp)
            print("   DBG start", push, g, pp)
        x, v = nelder_mead(cost, x0, [0.05, 0.05, 0.05, 0.3, 0.3, 0.08])
        x, v = nelder_mead(cost, x, [0.02, 0.02, 0.02, 0.1, 0.1, 0.03])
        if "--debug" in args:
            pp = {}
            cost(x, pp)
            print("   DBG  -> end", pp, "centre", tuple(round(c, 2) for c in x[:3]))
        if best is None or v < best[1]:
            best = (x, v)
    fl, frr, d, gap = place(best[0])
    end = fl - d * slide_l
    # 4. set the controls
    edge = yaw_m @ Vector(tw.get("edge", EDGE[MOVE][k["name"]]))
    x_axis = (edge - d * edge.dot(d)).normalized()  # the edge, square to the handle
    # the AXE frame: Y along the handle, the blade's own direction (BLADE, in its XZ) turned onto the edge
    zb = x_axis.cross(d)
    blade_ang = math.atan2(BLADE.z, BLADE.x)
    xa = x_axis * math.cos(-blade_ang) + zb * math.sin(-blade_ang)
    za = xa.cross(d)
    m = Matrix.Identity(4)
    m.col[0], m.col[1], m.col[2], m.col[3] = (*xa, 0), (*d, 0), (*za, 0), (*end, 1)
    axe_ctrl.matrix_world = m
    O["LEFT HAND"].location.y = slide_l
    O["RIGHT HAND"].location.y = slide_l + gap
    upd()
    for s, w in (("_l", "LEFT"), ("_r", "RIGHT")):
        fist = fl if s == "_l" else frr
        set_world_loc(O[w + " WRIST"], wrist_of(fist, d, s))
        # elbow: the filmed bend, kept low and close to his body (owner, chat 10 round 1: his elbows hang down and
        # tucked in; "elbows out to the sides" was wrong for this combo)
        e_vid = sh[s] + Vector(k["le" if s == "_l" else "re"]) * ARM_REACH
        wr = wrist_of(fist, d, s)
        line = (wr - sh[s]).normalized()
        bend = (e_vid - sh[s]) - line * (e_vid - sh[s]).dot(line)
        out = yaw_m @ Vector((0.25 if s == "_l" else -0.25, 0.15, -1.0))
        b = (bend.normalized() * 0.7 + out.normalized() * 0.3) if bend.length > 1e-4 else out
        if "elbow_" + s in tw:
            b = yaw_m @ Vector(tw["elbow_" + s])
        set_world_loc(O[w + " ELBOW"], (sh[s] + wr) / 2 + b.normalized() * 0.18)
    upd()
    for o in [axe_ctrl, O["LEFT HAND"], O["RIGHT HAND"], hips, chest] + \
            [O[w + p] for w in ("LEFT", "RIGHT") for p in (" WRIST", " ELBOW", " SHOULDER")]:
        key(o)
    upd()
    miss = {s: (head("hand" + s) - O["wrist" + s].matrix_world.translation).length for s in ("_l", "_r")}
    cl, at = clearance(body_tree(), end, d, True)
    line = ("POSE %-8s %-9s frame %2d: gap %.2f m, wrists miss L %.1f R %.1f cm, handle clear by %+.1f cm (after the "
            "margin; closest %.2f m up the handle, at %s), fists off the filmed spot L %.0f R %.0f cm, hips turn %+.0f, chest %+.0f, lean %+.0f, drop %.0f cm"
            % (MOVE, k["name"], fr, gap, miss["_l"] * 100, miss["_r"] * 100, cl * 100, at[0], at[1], (fl - want["_l"]).length * 100,
               (frr - want["_r"]).length * 100, hip_yaw, chest_yaw, lean, drop * 100))
    print(line)
    if "--debug" in args:
        for s_ in ("_l", "_r"):
            print("   DBG %s shoulder %s want %s (body gap %.2f) fist %s elbow %s" % (s_, tuple(round(v, 2) for v in sh[s_]),
                  tuple(round(v, 2) for v in want[s_]), kd.find(want[s_])[2], tuple(round(v, 2) for v in (fl if s_ == "_l" else frr)),
                  tuple(round(v, 2) for v in head("lowerarm" + s_))))
    report.append(line)
sc.frame_set(FRAMES[0])
if SAVE:
    bpy.ops.wm.save_mainfile(compress=True)
    print("SAVED")
