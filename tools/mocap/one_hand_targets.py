"""Step 2 for the owner's one-handed videos (F389 chat 13): his tracked moves -> bone DIRECTIONS for the dwarf.
Copies directions, angles, twist, lean and timing; never his distances (the dwarf's arm is 27 cm, his ~55 cm).
Axes out (the dwarf's skeleton space): x = his LEFT, y = up, z = his FRONT. The camera faces him (front view).
Per frame of each clip:
  arm_r / fore_r: right upper arm and forearm directions, bend_r: the elbow's hinge (square to both);
  arm_l / fore_l / bend_l: the shield arm, his own guard pose (the median over the combo, measured from his chest,
    so it turns with him; the tracker often lost this fist behind the body);
  thigh/calf _l/_r + knee_l/_r (hinge), foot_l/_r (heel -> toes, flat), chest (x, y axes), hips (x, y axes),
  hip_move (side, up: in leg lengths, from the clip's first frame), handle (the stick's direction), edge (the way the
  stick's tip moves, square to the handle).
  python one_hand_targets.py <scratch dir> <out.json>
  (expects <scratch>/v4428 = sword, <scratch>/v4429 = mace, each with scan.json from one_hand_scan.py)
By the dwarf-animations Claude, chat 13, Nov 20, 2026."""
import json, math, sys
from pathlib import Path
import numpy as np

FPS = 30.0
# owner's videos: [video, first frame, strikes (hit 1, 2, 3), where hit 2 and hit 3 start, last frame]
# (picked from the picture sheets: each hit ends once its follow-through has slowed down). The strike (where the game's
# hit lands) is where the weapon is stretched out furthest, not the fastest moment: owner, Nov 20, on the hit-1 sheet
# ("picture 5 is the hit, not picture 4": frame 745); the others measured the same way (stick tip furthest from his shoulder).
COMBOS = {
    "Sword": ["v4428", 686, [745, 836, 896], [765, 848], 915],
    "Mace": ["v4429", 828, [863, 928, 990], [884, 945], 1008],
}


def unit(v):
    n = np.linalg.norm(v, axis=-1, keepdims=True)
    return v / np.maximum(n, 1e-9)


def smooth(a, s=1.5):
    r = int(3 * s) + 1
    k = np.exp(-0.5 * (np.arange(-r, r + 1) / s) ** 2); k /= k.sum()
    pad = np.pad(a, [(r, r)] + [(0, 0)] * (a.ndim - 1), mode="edge")
    return sum(k[i] * pad[i:i + len(a)] for i in range(2 * r + 1))


def load(d):
    sc = json.load(open(d / "scan.json"))
    w = np.array(sc["w"]); px = np.array(sc["px"])
    D = np.stack([w[:, :, 0], -w[:, :, 1], -w[:, :, 2]], 2)  # MediaPipe (x right in picture, y down, z away) -> ours
    return sc, D, px


def seg(D, a, b, L, px=None, scale=None):
    """Direction a->b with its depth rebuilt from the bone's known length L (the tracker's depth is the weak part):
    the picture-plane part is kept (from the picture's own pixels when given: the tracker's 3D guess pulled his
    raised elbow 20 cm low), the depth is what the length leaves, its sign from the tracker."""
    v = D[:, b] - D[:, a]
    if px is not None:
        p = px[:, b] - px[:, a]
        v = np.stack([p[:, 0] * scale, -p[:, 1] * scale, v[:, 2]], 1)
    xy = np.linalg.norm(v[:, :2], axis=1)
    dz = np.sqrt(np.maximum(L * L - xy * xy, 0.0))
    wz = np.clip((np.abs(v[:, 2]) - 0.02) / 0.06, 0, 1)  # trust the length only where the tracker is sure of the sign
    z = wz * np.sign(v[:, 2]) * dz + (1 - wz) * v[:, 2]
    return unit(smooth(unit(np.stack([v[:, 0], v[:, 1], z], 1))))


def hinge(a, b, fallback):
    """The joint's hinge axis (square to both bones); nearly straight: the last good one (or `fallback`)."""
    out = np.zeros_like(a); prev = None
    for i in range(len(a)):
        c = np.cross(a[i], b[i]); s = np.linalg.norm(c)
        f = prev if prev is not None else fallback[i]
        f = unit(f - np.dot(f, a[i]) * a[i])
        k = min(1.0, s / 0.35)
        h = unit(k * (c / max(s, 1e-9)) + (1 - k) * f)
        out[i] = h; prev = h
    return out


def turned_line(D, px, W, a, b):
    """A left-right body line (shoulders or hips) with its turn toward the camera made steadier: the tracker's depth
    guess wanders (his shoulders looked 30 degrees turned while he faced the camera square), so the turn is the middle
    of the tracker's and the one the picture shows (the line looks shorter the more he turns), the side from the tracker
    (chat 10's way)."""
    v = D[:, a] - D[:, b]
    w = np.linalg.norm(px[:, a] - px[:, b], axis=1)
    ref = np.percentile(w[W], 95)
    xy = np.linalg.norm(v[:, :2], axis=1)
    yaw_mp = np.arctan2(v[:, 2], xy)
    yaw_px = np.arccos(np.clip(w / ref, 0, 1)) * np.sign(v[:, 2])
    yaw = 0.5 * (yaw_mp + yaw_px)
    d = v[:, :2] / np.maximum(xy, 1e-9)[:, None]
    return np.stack([d[:, 0] * np.cos(yaw), d[:, 1] * np.cos(yaw), np.sin(yaw)], 1)


def frame_of(x, y):
    """Axes from a left-right line x and an up line y (made square)."""
    x = unit(x); y = unit(y - (y * x).sum(1, keepdims=True) * x); z = np.cross(x, y)
    return x, y, z


def build(scratch, name):
    vid, first, strikes, gaps, last = COMBOS[name]
    sc, D, px = load(scratch / vid)
    N = len(D)
    # measure only round the combo (the first seconds, him walking into place, were tracked wildly)
    W = np.arange(max(0, first - 150), min(N, last + 150))
    # metres per pixel (the body's height in the picture against the tracker's 3D body), and each bone's full length
    # as the picture shows it (the tracker's own 3D lengths wander: its calf came out 43 cm, the picture's 32)
    mid_w = lambda A: np.linalg.norm(((A[:, 11] + A[:, 12]) - (A[:, 27] + A[:, 28]))[:, :2] / 2, axis=1)
    scale = np.median(mid_w(D)[W] / np.maximum(mid_w(px)[W], 1))
    pct = lambda a, b: np.percentile(np.linalg.norm(px[W, b] - px[W, a], axis=1), 95) * scale
    Lu, Lf, Lt, Lc = pct(12, 14), pct(14, 16), pct(24, 26), pct(26, 28)
    out = {}
    up = np.tile([0.0, 1.0, 0.0], (N, 1))
    sh_x = smooth(turned_line(D, px, W, 11, 12), 2.0); hip_x = smooth(turned_line(D, px, W, 23, 24), 2.0)
    spine = smooth((D[:, 11] + D[:, 12]) / 2 - (D[:, 23] + D[:, 24]) / 2, 2.0)
    cx, cy, cz = frame_of(sh_x, spine)
    hx, hy, hz = frame_of(hip_x, 0.6 * up + 0.4 * unit(spine))
    arm_r = seg(D, 12, 14, Lu, px, scale); fore_r = seg(D, 14, 16, Lf, px, scale)
    arm_l = seg(D, 11, 13, Lu, px, scale); fore_l = seg(D, 13, 15, Lf, px, scale)
    # elbow hinge at rest (T pose, the forearm folding forward): right = +y, left = -y (cross(arm, front))
    bend_r = hinge(arm_r, fore_r, np.cross(arm_r, cz))
    legs = {}
    for s, (h, k, a, heel, toe) in {"l": (23, 25, 27, 29, 31), "r": (24, 26, 28, 30, 32)}.items():
        th = seg(D, h, k, Lt, px, scale); ca = seg(D, k, a, Lc, px, scale)
        kn = hinge(th, ca, hx)  # (knee bending forward: hinge = +x, the hips' left-right line)
        ft = D[:, toe] - D[:, heel]; ft[:, 1] = 0.0
        legs[s] = (th, ca, kn, unit(smooth(ft, 3.0)))
    # the shield arm: his median guard, measured in the chest's axes over the whole combo
    rng = np.arange(first - 1, last)
    C = np.stack([cx, cy, cz], 2)  # columns = axes; world = C @ local
    loc_a = np.einsum("nji,nj->ni", C[rng], arm_l[rng]); loc_f = np.einsum("nji,nj->ni", C[rng], fore_l[rng])
    ga = unit(np.median(loc_a, 0)); gf = unit(np.median(loc_f, 0))
    print(name, "guard (chest axes) upper arm", np.round(ga, 2), "forearm", np.round(gf, 2),
          "lengths arm %.2f fore %.2f thigh %.2f calf %.2f" % (Lu, Lf, Lt, Lc))
    g_arm = np.einsum("nij,j->ni", C, ga); g_fore = np.einsum("nij,j->ni", C, gf)
    bend_l = hinge(g_arm, g_fore, np.cross(g_arm, cz))
    # hips' move in the picture: middle of the hips against the middle of the feet, in leg lengths
    hip_px = (px[:, 23] + px[:, 24]) / 2; feet_px = (px[:, 27] + px[:, 28]) / 2
    leg_px = np.median(np.linalg.norm(px[:, 23] - px[:, 27], axis=1))
    hip_rel = smooth((hip_px - feet_px) / leg_px, 2.0)
    # the stick: picture angle -> 3D (depth from how short it looks; its sign: the one nearer square to the forearm)
    rows = sc["rows"]
    # (a weak reading that jumps far from the last good one is the door frame, not the stick: keep the last good one;
    # sword hit 3's end read "straight up" while his stick pointed down; chat 14)
    # (and a weak reading pointing back up his forearm is the arm against his white shirt: sword hit 3's end, mace hit 2)
    rows = [dict(r) for r in rows]; good_r = None
    for k, r in enumerate(rows):
        s = r["stick"]
        el = px[k, 14, :2] - px[k, 16, :2]  # wrist -> elbow in the picture (y down)
        arm_ang = np.degrees(np.arctan2(-el[1], el[0]))
        along_arm = abs((s["angle"] - arm_ang + 180) % 360 - 180) < 35
        if good_r is not None and s["score"] < 1500:  # (strong readings stay: in hit 1 the wind-up sword really hangs
            # down behind his shoulder, in line with his forearm)
            jump = abs((s["angle"] - good_r["angle"] + 180) % 360 - 180)
            if along_arm or jump > 60:
                r["stick"] = dict(good_r)
                continue
        if s["score"] >= 1500:
            good_r = s
    ang = np.radians([r["stick"]["angle"] for r in rows])
    s2 = np.stack([np.cos(ang), np.sin(ang)], 1)  # (picture: x right = his left, y up)
    lens = np.array([r["stick"]["length"] for r in rows]); Lref = np.percentile(lens, 95)
    ratio = np.clip(lens / Lref, 0.35, 1.0)
    # (only a clearly short stick points toward or away from the camera: its tip often hides in the floor's glare, and
    # reading that as depth stood the sword upright at the hit; owner, Nov 20: "my sword is so much further out")
    r2 = np.clip((ratio - 0.35) / 0.4, 0, 1) * 0.65 + 0.35
    dz = np.where(ratio > 0.75, 0.0, np.sqrt(1 - r2 ** 2) / r2)
    fist_up = (Lu * arm_r + Lf * fore_r)[:, 1]  # (the fist above (+) or below his shoulder)
    handle = np.zeros((N, 3))
    for i in range(N):
        best = None
        for sg in (1.0, -1.0):
            h = unit(np.array([s2[i, 0], s2[i, 1], sg * min(dz[i], 1.2)]))
            score = abs(np.dot(h, fore_r[i]) - 0.15)  # (nearly square to the forearm, a little along it)
            if s2[i, 1] > 0.3 and fist_up[i] > 0.0 and sg > 0:  # (a raised stick that looks short, the fist above his
                # shoulder: it leans BACK, behind his head; owner, Nov 20)
                score += 10.0
            if s2[i, 1] < -0.3 and sg < 0:  # (a lowered stick that looks short points down IN FRONT: behind, it went
                # through his legs at sword hit 3's chop; chat 14)
                score += 10.0
            if best is None or score < best[0]:
                best = (score, h)
        handle[i] = best[1]
    for i in range(1, N):  # no sudden flips of the depth guess (toward / away from the camera)
        if np.dot(handle[i], handle[i - 1]) < -0.2:
            alt = handle[i] * np.array([1.0, 1.0, -1.0])
            if np.dot(alt, handle[i - 1]) >= -0.2:
                handle[i] = alt
            # (else the picture really shows the stick swung across: believe it. Keeping the last frame's direction
            # got stuck for 27 frames in sword hit 2's fast backhand: the sword hung down while his stick pointed up;
            # chat 14)
    handle = unit(smooth(handle, 1.5))
    # where the stick's tip is against his body, from the middle of his shoulders, in shoulder widths (x his left,
    # z front) and shoulder heights (y up): the dwarf's short arm can't carry his fist as far out, so the game turns the sword until its tip points
    # at the same spot measured in the dwarf's own shoulder widths (owner, Nov 20, drawing on the hit-1 sheet: "my sword
    # is so much further out ... at the very end in the corner"; copying the shoulder -> tip line alone made it worse)
    Ls = np.percentile([r["stick"]["length"] for r in rows], 95) * scale
    sw = np.percentile(np.linalg.norm(px[W, 11] - px[W, 12], axis=1), 95) * scale
    r_sh = -0.5 * sh_x * sw  # (the right shoulder from the middle: half a shoulder width along the turned line)
    # (up and down as a share of his shoulder height instead: the dwarf is short and wide, so 4 shoulder widths down went
    # below his floor)
    sh_h = np.median((((px[:, 27] + px[:, 28]) - (px[:, 11] + px[:, 12])) / 2)[W, 1]) * scale
    tip_at = (r_sh + Lu * arm_r + Lf * fore_r + Ls * handle) / np.array([sw, sh_h, sw])
    hand = D[:, 16]
    tip = hand + handle * 0.8
    v = np.gradient(smooth(tip, 1.5), axis=0) * FPS
    # the sharp edge: the way the tip moves, square to the handle. Before each hit it faces the way the blade is ABOUT to
    # swing (walked backward in time from the strike), after it the way it just swung (owner, Nov 20: "turn the sword
    # so the blade" leads, at the top and at the end; read from slow moments it showed the flat side)
    def walk(order):
        out = {}; e = None
        for i in order:
            vp = v[i] - np.dot(v[i], handle[i]) * handle[i]; s = np.linalg.norm(vp)
            if e is None:
                e = vp / max(s, 1e-9)
            e = e - np.dot(e, handle[i]) * handle[i]
            k = min(1.0, s / 3.0)  # (fast: the way it moves; slow: keeps the last way)
            e = unit(unit(e) * (1 - k) + (vp / max(s, 1e-9)) * k)
            out[i] = e
        return out
    edge = np.zeros((N, 3))
    bounds = [first] + list(gaps) + [last]
    for h in range(3):
        a, st, b = bounds[h] - 1, strikes[h] - 1, bounds[h + 1] - 1
        before = walk(range(st, a - 1, -1)); after = walk(range(st, b + 1))
        for i, e in list(before.items()) + list(after.items()):
            edge[i] = e
    cuts = [first] + list(gaps) + [last]
    r3 = lambda a: [round(float(x), 4) for x in a]
    for h in range(3):
        a, b = cuts[h], cuts[h + 1]
        frames = []
        for f in range(a, b + 1):
            i = f - 1
            fr = {"arm_r": r3(arm_r[i]), "fore_r": r3(fore_r[i]), "bend_r": r3(bend_r[i]),
                  "arm_l": r3(g_arm[i]), "fore_l": r3(g_fore[i]), "bend_l": r3(bend_l[i]),
                  "chest_x": r3(cx[i]), "chest_y": r3(cy[i]), "hips_x": r3(hx[i]), "hips_y": r3(hy[i]),
                  "hip_move": r3([hip_rel[i, 0] - hip_rel[a - 1, 0], -(hip_rel[i, 1] - hip_rel[a - 1, 1])]),
                  "handle": r3(handle[i]), "edge": r3(edge[i]), "tip": r3(tip_at[i])}
            for s in "lr":
                th, ca, kn, ft = legs[s]
                fr["thigh_" + s] = r3(th[i]); fr["calf_" + s] = r3(ca[i]); fr["knee_" + s] = r3(kn[i]); fr["foot_" + s] = r3(ft[i])
            frames.append(fr)
        out["%sHit%d" % (name, h + 1)] = {"video": vid, "from_frame": a, "to_frame": b, "length": (b - a) / FPS,
                                          "strike": (strikes[h] - a) / FPS, "frames": frames}
        print("  %sHit%d: frames %d-%d (%.2f s), strike at %.2f s" % (name, h + 1, a, b, (b - a) / FPS, (strikes[h] - a) / FPS))
    return out


if __name__ == "__main__":
    scratch = Path(sys.argv[1])
    allc = {"fps": FPS}
    for n in COMBOS:
        allc.update(build(scratch, n))
    json.dump(allc, open(sys.argv[2], "w"))
    print("saved", sys.argv[2])
