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
CLOTHES = "clothes" in ARGS[2:]  # (Nov 18: the bare dwarf in linen underpants first; the clothes go on later as layers)
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


# ---------------------------------------------------------------- round 3 (Nov 17): the body as clay, like the head
# Owner (F183): round 1 was "sausages and balls", needs much more detail; the feet are far too long. Each part is now
# blended clay (dwarf_head.Clay: shapes joined with soft fillets, grooves cut in) with the picture's details: folds,
# stitched side seams, a thick uneven hem, rolled sleeves and cuffs, cloth wraps in bands, short wrapped feet.
# Sizes measured on dwarf_turnaround.png (tools/asset_forge/dwarf_turnaround_measure.py; crown at 1.19 m):
# torso ~0.50 m across at the hem (0.43 m) narrowing to ~0.43 m at the chest, ~0.45 m deep, belly out most at
# 0.60-0.65 m; shorts legs ~0.23 m wide, cuffs at ~0.20 m, crotch ~0.36 m; wraps up to ~0.18 m; shoulders ~0.85 m.
# Feet: about 0.24 m long (round 1: 0.35 m; the picture's ~0.28 m, shorter on purpose: "far too long").
# Plain colours until the owner's OK on the shape; then sculpt and bake like the head.
import numpy as np  # noqa: E402

HC = dh.C


def Q(x, up, back):
	"""Body coordinates (Blender x sideways, up, back = Blender +y) -> the clay's head space (u, v, w)."""
	return (x - HC.x, up - HC.z, HC.y - back)


def QV(v):
	return Q(v.x, v.z, v.y)


def QD(a, b):
	"""The direction from bone point a to b, in head space."""
	pa, pb = QV(a), QV(b)
	return tuple(pb[i] - pa[i] for i in range(3))


def clay(lo, hi, h=0.005):
	"""A clay block covering the box lo..hi (body coordinates: (x, up, back))."""
	a, b = Q(*lo), Q(*hi)
	return dh.Clay(tuple(min(p, q) for p, q in zip(a, b)), tuple(max(p, q) for p, q in zip(a, b)), h)


def torus(cl, c, axis, R, r):
	"""A ring (doughnut) round `axis` through c: for rolled cuffs, wrap bands."""
	a = np.array(axis, np.float32)
	a /= np.linalg.norm(a)
	pu, pv, pw = cl.U - c[0], cl.V - c[1], cl.W - c[2]
	t = pu * a[0] + pv * a[1] + pw * a[2]
	rad = np.sqrt(np.maximum(pu * pu + pv * pv + pw * pw - t * t, 0.0))
	return np.sqrt((rad - R) ** 2 + t * t) - r


def ering(cl, up, back_c, a, b, r):
	"""A level ring round the body, oval (a sideways, b front-back), centred `back_c` behind the spine line."""
	c = Q(0, up, back_c)
	x, z = (cl.U - c[0]) / a, (cl.W - c[2]) / b
	e = (np.sqrt(x * x + z * z) - 1.0) * min(a, b)
	return np.sqrt(e * e + (cl.V - c[1]) ** 2) - r


def finish(o, faces):
	"""Fewer faces for the game (the clay grid is fine), smooth shading."""
	bpy.context.view_layer.objects.active = o
	n = len(o.data.polygons)
	if n > faces:
		m = o.modifiers.new("fewer", "DECIMATE")
		m.ratio = faces / n
		bpy.ops.object.modifier_apply(modifier="fewer")
	# (the face cutting leaves a few zero-size slivers, two corners on one spot: they have no real facing, so they shade
	# as specks and fooled the clip check into "19 cm inside the body", Nov 18)
	bm = bmesh.new()
	bm.from_mesh(o.data)
	bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0004)
	bmesh.ops.dissolve_degenerate(bm, edges=bm.edges, dist=0.0004)
	bm.to_mesh(o.data)
	bm.free()
	for poly in o.data.polygons:
		poly.use_smooth = True
	return o


PARTS = []
# the torso's outline: (height, half-width, front, back), front/back measured from the spine line. A barrel that is
# widest at the flared hem and the belly and narrows toward the chest (draft 2 had the same width all the way up: "a can").
# (Picture, body only: +-0.25 at 0.45-0.5 m, +-0.23 at 0.55, +-0.215 at 0.6-0.675.)
TORSO = [(0.36, 0.262, 0.235, 0.185), (0.43, 0.25, 0.26, 0.18), (0.5, 0.242, 0.29, 0.19), (0.58, 0.228, 0.3, 0.2),
	(0.66, 0.216, 0.27, 0.21), (0.74, 0.214, 0.21, 0.22), (0.82, 0.21, 0.16, 0.22), (0.88, 0.19, 0.11, 0.2), (0.92, 0.12, 0.07, 0.11)]


def torso_at(up):
	"""(half-width, front, back) at a height, between the outline's rings."""
	for (h0, w0, f0, b0), (h1, w1, f1, b1) in zip(TORSO[:-1], TORSO[1:]):
		if h0 <= up <= h1:
			t = (up - h0) / (h1 - h0)
			return w0 + (w1 - w0) * t, f0 + (f1 - f0) * t, b0 + (b1 - b0) * t
	return TORSO[0][1:] if up < TORSO[0][0] else TORSO[-1][1:]


def loft(cl, rings, cap=True):
	"""One smooth body through level oval rings (height, half-width, front, back): at every height the oval is
	interpolated from the rings, so the surface has no ridges (round 3's first try stacked ovals: it looked ribbed).
	cap=False: open at the top and bottom (the distance to the side wall only)."""
	hs = [r[0] for r in rings]
	up = cl.V + HC.z
	x = cl.U + HC.x
	back = HC.y - cl.W
	hw = np.interp(up, hs, [r[1] for r in rings])
	f = np.interp(up, hs, [r[2] for r in rings])
	b = np.interp(up, hs, [r[3] for r in rings])
	c, d = (b - f) / 2, (f + b) / 2
	e = (np.sqrt((x / hw) ** 2 + ((back - c) / d) ** 2) - 1.0) * np.minimum(hw, d)
	return np.maximum(e, np.maximum(hs[0] - up, up - hs[-1])) if cap else e


def body_ring(cl, rings, up, grow, r):
	"""A ring lying on the loft's surface at a height (grown outward by `grow`): a hem lip, a collar, a waistband."""
	hs = [q[0] for q in rings]
	hw = float(np.interp(up, hs, [q[1] for q in rings])) + grow
	f = float(np.interp(up, hs, [q[2] for q in rings])) + grow
	b = float(np.interp(up, hs, [q[3] for q in rings])) + grow
	return ering(cl, up, (b - f) / 2, hw, (f + b) / 2, r)


def on_torso(x, up, front=True, inset=0.0):
	"""A point on the shirt's surface at sideways x and height up (front or back), pushed in by `inset`."""
	hw, f, b = torso_at(up)
	c, d = (b - f) / 2, (f + b) / 2
	k = math.sqrt(max(1.0 - (x / hw) ** 2, 0.0))
	return Q(x, up, c - d * k + inset if front else c + d * k - inset)


def hem_up(th):
	"""The hem's height all round (th: the angle round the body, 0 = the middle of the front): it hangs lower over the
	belly and a little at the back, waves unevenly, and has a short slit at each side (like the picture's)."""
	f = np.cos(th)
	return (0.405 - 0.018 * np.clip(f, 0, None) ** 2 - 0.007 * np.clip(-f, 0, None) ** 2 + 0.006 * np.sin(3 * th + 0.8)
		+ 0.004 * np.sin(7 * th + 2.1) + 0.032 * np.exp(-((np.abs(th) - np.pi / 2) / 0.06) ** 2))


def chaikin(pts, n=3):
	"""A smooth curve through a few points (corner cutting), so a crease bends softly instead of in straight pieces."""
	pts = [tuple(p) for p in pts]
	for _ in range(n):
		out = [pts[0]]
		for a, b in zip(pts[:-1], pts[1:]):
			out += [tuple(0.75 * a[i] + 0.25 * b[i] for i in range(2)), tuple(0.25 * a[i] + 0.75 * b[i] for i in range(2))]
		pts = out + [pts[-1]]
	return pts


def press(cl, segs, depth, width):
	"""Press a soft dip (depth > 0) or a soft rise (depth < 0) into the clay along line segments [(a, b, share)]: a bell
	curve `width` wide, `share` of `depth` deep at each segment. (Draft 3 cut and added tubes with 2 cm soft joins round
	3 mm folds: every soft join itself dug ~5 mm, so each fold read as a strap with steps. A press has no join.)"""
	f = np.zeros_like(cl.D)
	for a, b, share in segs:
		d = cl.tube(a, b, 0.0, 0.0)
		f = np.maximum(f, share * np.exp(-(d / width) ** 2))
	cl.D += (depth * f).astype(np.float32)


def crease(cl, pts, front, depth=0.0035, width=0.016, ridge=0.002):
	"""A long soft fold in the cloth along (x, up) points on the shirt: a shallow valley, deepest in the middle and fading
	out at both ends, with a lower soft ridge beside it (draft 2's folds were short narrow dents)."""
	P = chaikin(pts)
	n = len(P) - 1
	prof = [math.sin(math.pi * (i + 1) / (n + 1)) ** 0.8 for i in range(n)]
	press(cl, [(on_torso(*P[i], front), on_torso(*P[i + 1], front), prof[i]) for i in range(n)], depth, width)
	if ridge > 0:
		segs = []
		for i in range(n):
			a, b = P[i], P[i + 1]
			dx, du = b[0] - a[0], b[1] - a[1]
			ln = math.hypot(dx, du) or 1.0
			ox, ou = -du / ln * 0.034, dx / ln * 0.034
			segs.append((on_torso(a[0] + ox, a[1] + ou, front), on_torso(b[0] + ox, b[1] + ou, front), prof[i]))
		press(cl, segs, -ridge, width * 1.2)


if CLOTHES:  # (the clothes of round 3, kept for when they go on over the bare body: owner, Nov 18)
	# ---- the shirt: barrel, shoulders, short rolled sleeves, collar, hem, folds, seams
	cl = clay((-0.47, 0.31, -0.36), (0.47, 0.98, 0.33))
	cl.add(loft(cl, TORSO), 0.01)
	for side in ("l", "r"):
		sh, el = B(f"upperarm_{side}"), B(f"lowerarm_{side}")
		d = el - sh
		inward = -1 if sh.x > 0 else 1
		ax = QD(sh, el)
		# the shoulder: a low, wide cap flowing into the sleeve with a big fillet (draft 2: a ball on a can, boxy)
		cl.add(cl.ell(QV(sh + Vector((inward * 0.05, 0, -0.035))), (0.13, 0.115, 0.1)), 0.08)
		cl.add(cl.tube(QV(sh + Vector((inward * 0.04, 0, 0))), QV(sh + d * 0.5), 0.112, 0.104), 0.05)  # the sleeve
		cl.add(torus(cl, QV(sh + d * 0.53), ax, 0.106, 0.021), 0.012)                                    # rolled cuff
		cl.add(torus(cl, QV(sh + d * 0.6), ax, 0.098, 0.017), 0.01)
		for t, tl in ((0.2, 0.25), (0.36, -0.2)):                                                        # soft sleeve folds
			tor = torus(cl, QV(sh + d * t), (ax[0], ax[1] + tl, ax[2]), 0.112, 0.0)
			cl.D += (0.003 * np.exp(-(tor / 0.012) ** 2)).astype(np.float32)
			del tor
	# the hem: cut along an uneven line (hanging lower over the belly, side slits), then a rolled lip along that line
	th = np.arctan2(cl.U + HC.x, -(HC.y - cl.W))
	hu = hem_up(th)
	cl.keep(hu - (cl.V + HC.z), 0.004)
	e = loft(cl, TORSO, cap=False) + 0.006  # (the lip's middle 6 mm in: it stands out ~6 mm)
	cl.add(np.sqrt(e * e + ((cl.V + HC.z) - (hu + 0.009)) ** 2) - 0.012, 0.012)
	del th, hu, e
	# the collar: a soft rolled band round the neck, with a laced slit at the front
	cl.add(body_ring(cl, TORSO, 0.9, 0.0, 0.017), 0.015)
	cl.cut(cl.tube(on_torso(0, 0.9, True, -0.01), on_torso(0, 0.8, True, -0.01), 0.008, 0.004), 0.006)
	# long soft folds (not dents): pulled from the armpits toward the belly, one hanging from the belly to the hem each
	# side, and on the back from the shoulder blades down
	for s_ in (-1, 1):
		crease(cl, [(s_ * 0.2, 0.8), (s_ * 0.15, 0.7), (s_ * 0.07, 0.6)], True)
		crease(cl, [(s_ * 0.21, 0.68), (s_ * 0.16, 0.59), (s_ * 0.1, 0.52)], True, depth=0.0025, ridge=0.0)
		crease(cl, [(s_ * 0.19, 0.84), (s_ * 0.11, 0.72), (s_ * 0.06, 0.6)], False)
	crease(cl, [(-0.12, 0.5), (-0.135, 0.44), (-0.125, 0.38)], True, depth=0.0025, ridge=0.0)
	crease(cl, [(0.15, 0.49), (0.16, 0.39)], True, depth=0.0025, ridge=0.0)
	crease(cl, [(0.08, 0.57), (0.095, 0.49), (0.1, 0.4)], False, depth=0.0025, ridge=0.0)
	# side seams with stitches
	for s in (-1, 1):
		for up in np.arange(0.44, 0.8, 0.035):
			hw, f, b = torso_at(up)
			cl.add(cl.ell(Q(s * (hw - 0.001), up, (b - f) / 2), (0.004, 0.008, 0.004)), 0.003)
	finish(cl.mesh("shirt_body", shirt, PARTS), 7000)
	del cl

	# ---- arms (skin): upper arm in the sleeve, elbow, thick forearm, wrist
	for side in ("l", "r"):
		sh, el, wr = B(f"upperarm_{side}"), B(f"lowerarm_{side}"), B(f"hand_{side}")
		cl = clay((min(sh.x, wr.x) - 0.15, sh.z - 0.15, sh.y - 0.15), (max(sh.x, wr.x) + 0.15, sh.z + 0.15, sh.y + 0.15), 0.004)
		d = wr - el
		cl.add(cl.tube(QV(sh + (el - sh) * 0.3), QV(el), 0.07, 0.064), 0.02)
		cl.add(cl.ell(QV(el), (0.056, 0.056, 0.056)), 0.03)                                      # elbow
		cl.add(cl.ell(QV(el + d * 0.35 + Vector((0, 0, 0.008))), (0.085, 0.056, 0.058)), 0.04)  # the forearm muscle (slimmer: owner Nov 18 "massive")
		cl.add(cl.tube(QV(el), QV(wr), 0.056, 0.045), 0.03)
		cl.add(cl.ell(QV(wr), (0.034, 0.042, 0.046)), 0.02)                                    # wrist
		finish(cl.mesh(f"arm_{side}", skin, PARTS), 2500)
		del cl
# ---- hands (clay): a thick palm, three chunky fingers and a thumb (owner, F183: "3 chunky fingers plus a thumb, like a
# cartoon turtle, is fine"), each finger along its bones (the third along the middle of the ring and little-finger bones,
# so it bends with both), knuckles on the back of the hand
for side in ("l", "r"):
	wr = B(f"hand_{side}")
	chains = {f: [B(f"{f}_0{k}_{side}") for k in (1, 2, 3)] + [B(f"{f}_04_leaf_{side}")] for f in ("index", "middle", "ring", "pinky", "thumb")}
	# two fat fingers and a thumb, like a cartoon turtle's (owner, Nov 18): one along the index and middle bones, one along
	# the ring and little-finger bones, so each bends with both
	fingers = [[a.lerp(b, 0.5) for a, b in zip(chains["index"], chains["middle"])],
		[a.lerp(b, 0.5) for a, b in zip(chains["ring"], chains["pinky"])]]
	mids = [a.lerp(b, 0.5) for a, b in zip(fingers[0], fingers[1])]
	fingers = [[Vector((p.x, m.y + (p.y - m.y) * 1.25, p.z)) for p, m in zip(f, mids)] for f in fingers]
	pts = [p for c in chains.values() for p in c] + [wr] + [p for f in fingers for p in f]
	lo = Vector([min(p[i] for p in pts) - 0.06 for i in range(3)])
	hi = Vector([max(p[i] for p in pts) + 0.06 for i in range(3)])
	cl = clay((lo.x, lo.z, lo.y), (hi.x, hi.z, hi.y), 0.0025)
	knuck = [f[0] for f in fingers]
	mid = (knuck[0] + knuck[1]) / 2
	along = (mid - wr).length
	cl.add(cl.ell(QV(wr.lerp(mid, 0.55)), (along * 0.6, 0.027, (knuck[1] - knuck[0]).length / 2 + 0.032)), 0.014)  # the palm (flatter: Nov 18)
	cl.add(cl.ell(QV(wr.lerp(mid, 0.1)), (0.036, 0.03, 0.044)), 0.02)                                          # the wrist end
	for k, f in enumerate(fingers):
		r0 = 0.026
		f = [f[0].lerp(wr, 0.25)] + f[1:]  # (from inside the palm)
		for j in range(len(f) - 1):
			cl.add(cl.tube(QV(f[j]), QV(f[j + 1]), r0 * (1 - 0.06 * j), r0 * (1 - 0.06 * (j + 1))), 0.004)
		cl.add(cl.ell(QV(f[-1]), (0.022, 0.02, 0.022)), 0.006)                       # a round fingertip
		cl.add(cl.ell(QV(f[1] + Vector((0, 0, 0.01))), (0.022, 0.013, 0.022)), 0.006)  # the knuckle on top
	th = chains["thumb"]
	th = [th[0].lerp(mid, 0.15)] + th[1:]
	for j in range(len(th) - 1):
		cl.add(cl.tube(QV(th[j]), QV(th[j + 1]), 0.026 * (1 - 0.07 * j), 0.026 * (1 - 0.07 * (j + 1))), 0.006)
	cl.add(cl.ell(QV(th[-1]), (0.021, 0.021, 0.021)), 0.006)
	finish(cl.mesh(f"hand_{side}", skin, PARTS), 4000)
	del cl

if CLOTHES:
	# ---- shorts: a baggy seat and legs, folds, rolled cuffs
	cl = clay((-0.34, 0.17, -0.33), (0.34, 0.47, 0.27))
	# (the top stays >= 1 cm inside the shirt: draft 2's waistband poked out under the hem and showed as a bar on the back)
	SEAT = [(0.28, 0.23, 0.19, 0.15), (0.35, 0.248, 0.225, 0.168), (0.44, 0.23, 0.21, 0.158)]
	cl.add(loft(cl, SEAT), 0.01)
	for side in ("l", "r"):
		hip, knee = B(f"thigh_{side}"), B(f"calf_{side}")
		out = 1 if knee.x > 0 else -1
		top, cuff = hip + Vector((out * 0.02, 0, 0)), Vector((knee.x + out * 0.025, knee.y, 0.215))
		cl.add(cl.tube(QV(top), QV(cuff), 0.118, 0.11), 0.05)
		cl.add(torus(cl, QV(cuff + UP * 0.005), (0, 1, 0), 0.108, 0.021), 0.012)            # rolled cuff
		cl.add(torus(cl, QV(cuff - UP * 0.025), (0, 1, 0), 0.102, 0.018), 0.01)
		cl.cut(cl.tube(QV(cuff - UP * 0.06), QV(cuff - UP * 0.02), 0.084, 0.084), 0.01)    # open below (the calf comes out)
		for a0, a1, u0, u1 in ((0.3, -0.5, 0.36, 0.27), (-0.9, -0.3, 0.33, 0.25), (1.2, 0.6, 0.34, 0.26)):   # leg folds
			p0 = Vector((knee.x + out * math.sin(a0) * 0.13, knee.y - math.cos(a0) * 0.13, u0))
			p1 = Vector((knee.x + out * math.sin(a1) * 0.128, knee.y - math.cos(a1) * 0.128, u1))
			cl.cut(cl.tube(QV(p0), QV(p1), 0.006, 0.004), 0.007)
	cl.cut(cl.tube(Q(0, 0.37, -0.255), Q(0.0, 0.3, -0.25), 0.007, 0.005), 0.006)          # the front seam
	# above the hem the shorts stay 1 cm inside the shirt everywhere (draft 4: the seat's corners poked out through the
	# shirt at the back, so only the middle of the hem hung over them, like a tab)
	inside = loft(cl, TORSO, cap=False) + 0.01
	below = (cl.V + HC.z) - hem_up(np.arctan2(cl.U + HC.x, -(HC.y - cl.W))) + 0.01
	cl.keep(np.minimum(inside, below), 0.003)
	del inside, below
	finish(cl.mesh("shorts_seat", shorts, PARTS), 5000)
	del cl

	# ---- calves, cloth wraps in flat strips, short wrapped feet
	def strip(F, plane, half, lift=0.0045):
		"""A flat cloth strip lying on the shape F (a distance field): a shell up to `lift` thick where |plane| < half.
		Joined with a tiny fillet, so each strip shows its edges (draft 2's wraps were round rings: a round boot)."""
		return np.maximum(np.abs(F - lift / 2 + 0.002) - (lift / 2 + 0.002), np.abs(plane) - half)


	def plane_d(cl, c, n):
		n = np.array(n, np.float32)
		n /= np.linalg.norm(n)
		return (cl.U - c[0]) * n[0] + (cl.V - c[1]) * n[1] + (cl.W - c[2]) * n[2]


	for side in ("l", "r"):
		knee, ank = B(f"calf_{side}"), B(f"foot_{side}")
		out = 1 if knee.x > 0 else -1
		cl = clay((knee.x - 0.13, 0.15, ank.y - 0.15), (knee.x + 0.13, 0.33, ank.y + 0.15), 0.004)
		cl.add(cl.tube(QV(knee), Q(ank.x, 0.17, ank.y), 0.078, 0.07), 0.03)                   # the calf (under the cuff)
		cl.add(cl.ell(Q(ank.x, 0.235, ank.y + 0.012), (0.074, 0.05, 0.07)), 0.03)             # (its muscle, at the back)
		finish(cl.mesh(f"calf_{side}", skin, PARTS), 1500)
		del cl
		cl = clay((knee.x - 0.13, -0.01, ank.y - 0.2), (knee.x + 0.13, 0.24, ank.y + 0.13), 0.003)
		top = 0.19
		# the foot (picture: flat and wrapped, ~0.24 m long: heel 7.5 cm behind the ankle, toes 16.5 cm in front; ~0.17 wide;
		# ~6 cm high at the toes), then the leg's wrapping (~0.145 m across, draft 2's 0.18 read as a boot)
		F = cl.tube(Q(ank.x, 0.06, ank.y), Q(ank.x, top, ank.y - 0.004), 0.07, 0.068)
		F = dh._smin(F, cl.ell(Q(ank.x + out * 0.006, 0.032, ank.y - 0.045), (0.088, 0.044, 0.12)), 0.04)  # the foot
		F = dh._smin(F, cl.ell(Q(ank.x, 0.042, ank.y + 0.035), (0.066, 0.046, 0.042)), 0.03)              # heel
		F = dh._smin(F, cl.ell(Q(ank.x + out * 0.012, 0.022, ank.y - 0.115), (0.094, 0.028, 0.055)), 0.03)  # flat, wide toes
		cl.add(F, 0.004)
		R3 = random.Random(9 + out)
		# up the leg: strips wound round it, each tilted its own way and overlapping the one below
		lc = Q(ank.x, 0, ank.y)
		on_leg = np.sqrt((cl.U - lc[0]) ** 2 + (cl.W - lc[2]) ** 2) - 0.1  # (only round the leg, not across the toes)
		for k, up in enumerate(np.arange(0.075, top - 0.01, 0.022)):
			n = (R3.uniform(-0.3, 0.3), 1.0, R3.uniform(-0.25, 0.25))
			cl.add(np.maximum(strip(F, plane_d(cl, Q(ank.x, up, ank.y), n), 0.014), on_leg), 0.0012)
		cl.add(torus(cl, Q(ank.x, top + 0.004, ank.y - 0.004), (0.08, 1.0, 0.0), 0.07, 0.012), 0.006)  # the top, folded over
		# over the foot: strips crossing the instep and round the arch, and one round the heel
		for c_, n in (((0, 0.05, -0.13), (0.15, 0.35, 1.0)), ((0, 0.055, -0.085), (-0.25, 0.4, 1.0)), ((0, 0.06, -0.04), (0.2, 0.6, 1.0)),
				((0, 0.05, 0.03), (0.0, 1.0, -0.6))):
			cl.add(strip(F, plane_d(cl, Q(ank.x + c_[0], c_[1], ank.y + c_[2]), (n[0], n[1], n[2])), 0.016), 0.0012)  # (c_: x, up, back)
		cl.keep((0.0 - HC.z) - cl.V, 0.004)  # (the sole flat on the floor)
		finish(cl.mesh(f"wrap_{side}", wraps, PARTS), 5000)
		del cl, F, on_leg

# ---------------------------------------------------------------- round 3b (Nov 18): the bare dwarf in linen underpants
# Owner (Nov 18): "build him in the underpants first", as detailed as the head; the clothes go on later as layers over this
# body (so outfits can change, the clothes can swing on their own, and they copy the body's bending). One seamless clay
# skin from the neck to the ankles (arms included, so the shoulders flow into the arms), bare feet and the hands apart,
# and a linen wrap lying on the skin. Sizes: the turnaround picture minus the clothes' thickness.
def on_surf(cl, x, up, front=True, inset=0.0):
	"""The clay's real surface (not the outline's) at sideways x and height up, front or back, pushed in by inset."""
	u, v = x - HC.x, up - HC.z
	i = min(max(int(round((u - cl.lo[0]) / cl.h)), 0), cl.D.shape[0] - 1)
	j = min(max(int(round((v - cl.lo[1]) / cl.h)), 0), cl.D.shape[1] - 1)
	col = cl.D[i, j, :]
	ins = np.nonzero(col < 0)[0]
	if not len(ins):
		return on_torso(x, up, front, inset)
	k = int(ins[-1] if front else ins[0])
	k2 = min(max(k + (1 if front else -1), 0), len(col) - 1)
	t = float(col[k] / (col[k] - col[k2])) if col[k] != col[k2] else 0.0
	w = cl.lo[2] + cl.h * (k + t * (k2 - k))
	return (u, v, w - inset if front else w + inset)


def groove(cl, pts, front, depth=0.003, width=0.01, n=2):
	"""A soft line pressed into the skin along (x, up) points on its real surface (a fold, a crease, a dent);
	a negative depth raises a soft ridge instead (a collarbone)."""
	P = chaikin(pts, n)
	m = len(P) - 1
	prof = [math.sin(math.pi * (i + 1) / (m + 1)) ** 0.6 for i in range(m)]
	press(cl, [(on_surf(cl, *P[i], front), on_surf(cl, *P[i + 1], front), prof[i]) for i in range(m)], depth, width)


if not CLOTHES:
	# the body's outline (height, half-width, front, back): a round belly that hangs low, a barrel chest, broad but
	# sloping shoulders (the arms are added below), a thick neck under the beard
	# (the back only gently curved: owner Nov 18, a deeper upper back looked "like he is gonna grow wings")
	TORSO = [(0.33, 0.2, 0.15, 0.15), (0.4, 0.222, 0.19, 0.165), (0.47, 0.23, 0.24, 0.17), (0.55, 0.224, 0.265, 0.172),
		(0.62, 0.216, 0.255, 0.175), (0.69, 0.21, 0.222, 0.177), (0.76, 0.21, 0.19, 0.177), (0.82, 0.198, 0.15, 0.17),
		(0.87, 0.162, 0.11, 0.145), (0.93, 0.085, 0.07, 0.09)]
	cl = clay((-0.72, 0.09, -0.36), (0.72, 1.0, 0.33))
	cl.add(loft(cl, TORSO), 0.012)
	cl.add(cl.ell(Q(0, 0.535, -0.125), (0.2, 0.175, 0.155)), 0.06)                       # the round belly, hanging a little
	cl.add(cl.ell(Q(0, 0.43, -0.09), (0.17, 0.07, 0.12)), 0.05)                           # (its underside, over the pants)
	for s in (-1, 1):
		cl.add(cl.ell(Q(s * 0.085, 0.765, -0.152), (0.088, 0.056, 0.042)), 0.035)          # chest
		cl.add(cl.ell(Q(s * 0.082, 0.375, 0.095), (0.098, 0.088, 0.078)), 0.045)           # buttock
		cl.add(cl.ell(Q(s * 0.19, 0.5, 0.0), (0.05, 0.1, 0.12)), 0.06)                     # the soft sides
	for side in ("l", "r"):
		sh, el, wr = B(f"upperarm_{side}"), B(f"lowerarm_{side}"), B(f"hand_{side}")
		s = 1 if sh.x > 0 else -1
		inward = -s
		d, f_ = el - sh, wr - el
		# the slope from the neck to the shoulder (trapezius) and the round shoulder muscle
		cl.add(cl.tube(Q(s * 0.05, 0.925, 0.035), QV(sh + Vector((inward * 0.07, 0.035, 0.05))), 0.05, 0.056), 0.05)
		cl.add(cl.ell(QV(sh + Vector((inward * 0.01, 0.0, 0.016))), (0.1, 0.092, 0.095)), 0.05)  # (round, broad)
		# upper arm with the biceps in front and the triceps behind, the elbow
		cl.add(cl.tube(QV(sh), QV(el), 0.076, 0.062), 0.03)  # (sturdy dwarf arms)
		cl.add(cl.ell(QV(sh + d * 0.5 + Vector((0, -0.02, 0.008))), (0.078, 0.054, 0.056)), 0.03)
		cl.add(cl.ell(QV(sh + d * 0.42 + Vector((0, 0.022, 0.0))), (0.085, 0.052, 0.05)), 0.03)
		cl.add(cl.ell(QV(el + Vector((0, 0.014, 0))), (0.05, 0.052, 0.053)), 0.03)
		# the forearm: thick by the elbow, tapering to a clear wrist (owner Nov 18: "the forearms are still too large")
		cl.add(cl.tube(QV(el), QV(wr), 0.052, 0.036), 0.025)
		cl.add(cl.ell(QV(el + f_ * 0.3 + Vector((0, 0, 0.006))), (0.068, 0.043, 0.045)), 0.03)
		cl.add(cl.ell(QV(wr), (0.024, 0.031, 0.036)), 0.015)
		cl.add(cl.ell(QV(wr + Vector((0, 0.022, 0.0))), (0.012, 0.011, 0.011)), 0.006)  # the wrist bone's knob
		# hip, thigh, knee and kneecap, shin and calf muscle
		th, kn, an = B(f"thigh_{side}"), B(f"calf_{side}"), B(f"foot_{side}")
		cl.add(cl.tube(QV(th + Vector((s * 0.012, 0, 0))), QV(kn + Vector((0, 0, 0.03))), 0.098, 0.06), 0.05)  # (tapers into the knee)
		cl.add(cl.ell(QV(kn), (0.054, 0.05, 0.05)), 0.02)                                 # the knee
		cl.add(cl.ell(QV(kn + Vector((0, -0.05, 0.008))), (0.034, 0.036, 0.022)), 0.01)   # kneecap
		cl.add(cl.tube(QV(kn + Vector((0, 0, -0.02))), Q(an.x, 0.15, an.y), 0.054, 0.038), 0.03)  # shin
		cl.add(cl.ell(QV(kn + (an - kn) * 0.32 + Vector((0, 0.024, 0))), (0.056, 0.07, 0.048)), 0.035)
	# soft lines: under the chest, the breastbone, the spine, the cleft, the navel, the belly's fold over the pants
	groove(cl, [(-0.16, 0.718), (-0.08, 0.705), (-0.02, 0.712)], True, 0.0025, 0.009)
	groove(cl, [(0.02, 0.712), (0.08, 0.705), (0.16, 0.718)], True, 0.0025, 0.009)
	groove(cl, [(0.0, 0.82), (0.0, 0.73)], True, 0.0025, 0.01)
	groove(cl, [(0.0, 0.87), (0.0, 0.7), (0.0, 0.5)], False, 0.003, 0.012)
	groove(cl, [(0.0, 0.43), (0.0, 0.32)], False, 0.006, 0.01)
	for side in ("l", "r"):  # the hollow behind each knee
		kn = B(f"calf_{side}")
		press(cl, [(QV(kn + Vector((-0.02, 0.05, 0.0))), QV(kn + Vector((0.02, 0.05, 0.0))), 1.0)], 0.006, 0.012)
	cl.cut(cl.ell(on_surf(cl, 0.0, 0.53, True, -0.004), (0.011, 0.014, 0.012)), 0.005)
	groove(cl, [(-0.17, 0.42), (-0.08, 0.385), (0.0, 0.378), (0.08, 0.385), (0.17, 0.42)], True, 0.004, 0.01)
	for s in (-1, 1):
		groove(cl, [(s * 0.03, 0.88), (s * 0.1, 0.875), (s * 0.18, 0.86)], True, -0.004, 0.009)  # collarbone (a ridge)
		cl.add(cl.ell(on_surf(cl, s * 0.088, 0.75, True, 0.002), (0.007, 0.007, 0.005)), 0.004)  # nipple
	body_D = cl.D.copy()
	finish(cl.mesh("torso", skin, PARTS), 16000)
	# ---- the underpants: a linen wrap lying on the skin (its inside 4 mm under the skin, 8 mm thick), cut along the
	# waist and the legs, with rolled edges, a knot in front and a few folds
	pc = clay((-0.72, 0.09, -0.36), (0.72, 1.0, 0.33))
	F = body_D
	up_ = pc.V + HC.z
	x_ = pc.U + HC.x
	th_ = np.arctan2(x_, -(HC.y - pc.W))
	top = 0.442 - 0.032 * np.clip(np.cos(th_), 0, None) + 0.02 * np.clip(-np.cos(th_), 0, None)
	bot = 0.3 + 0.15 * np.clip(np.abs(x_) - 0.03, 0, None)  # (low on the legs: a linen wrap, not modern briefs)
	pc.D = np.maximum(np.maximum(np.abs(F - 0.002) - 0.006, up_ - top), np.maximum(bot - up_, np.abs(x_) - 0.3)).astype(np.float32)
	pc.add(np.maximum(np.sqrt((F - 0.006) ** 2 + (up_ - top + 0.004) ** 2) - 0.009, np.abs(x_) - 0.3), 0.004)  # rolled waist
	pc.add(np.maximum(np.sqrt((F - 0.005) ** 2 + (up_ - bot - 0.004) ** 2) - 0.007, np.abs(x_) - 0.3), 0.004)  # leg edges
	del up_, x_, th_, top, bot
	for s in (-1, 1):
		groove(pc, [(s * 0.2, 0.42), (s * 0.13, 0.37), (s * 0.07, 0.33)], True, 0.003, 0.008)
		groove(pc, [(s * 0.19, 0.44), (s * 0.12, 0.4)], False, 0.003, 0.008)
	k = on_surf(pc, 0.075, 0.418, True, -0.004)
	pc.add(pc.ell(k, (0.02, 0.017, 0.015)), 0.006)                                                     # the knot
	for dx, ln in ((-0.012, 0.06), (0.014, 0.045)):                                                    # its hanging ends
		a = (k[0] + dx, k[1] - 0.01, k[2])
		b = (k[0] + dx * 1.6, k[1] - ln, k[2] - 0.004)
		pc.add(pc.tube(a, b, 0.009, 0.006), 0.004)
	finish(pc.mesh("pants", wraps, PARTS), 6000)
	del cl, pc, F, body_D
	# ---- bare feet (finer clay): ankle and its bones, heel, arch, the ball of the foot and four chunky toes
	for side in ("l", "r"):
		an = B(f"foot_{side}")
		out = 1 if an.x > 0 else -1
		fc = clay((an.x - 0.1, -0.01, an.y - 0.21), (an.x + 0.1, 0.2, an.y + 0.12), 0.0025)
		fc.add(fc.ell(Q(an.x, 0.13, an.y), (0.043, 0.05, 0.046)), 0.02)                                  # ankle
		for s2 in (-1, 1):
			fc.add(fc.ell(Q(an.x + s2 * 0.036, 0.122, an.y + 0.004), (0.015, 0.017, 0.015)), 0.008)        # ankle bones
		fc.add(fc.ell(Q(an.x, 0.045, an.y + 0.02), (0.046, 0.044, 0.042)), 0.03)                          # heel (not sticking out: Nov 18)
		fc.add(fc.ell(Q(an.x + out * 0.004, 0.04, an.y - 0.05), (0.057, 0.04, 0.1)), 0.035)              # the foot
		fc.add(fc.tube(Q(an.x, 0.11, an.y - 0.01), Q(an.x + out * 0.004, 0.05, an.y - 0.115), 0.042, 0.03), 0.03)  # instep
		fc.add(fc.ell(Q(an.x + out * 0.006, 0.03, an.y - 0.112), (0.062, 0.03, 0.042)), 0.025)            # ball of the foot
		for tx, tz, r in ((-0.03, -0.165, 0.021), (-0.002, -0.16, 0.016), (0.02, -0.153, 0.015), (0.039, -0.142, 0.014)):
			fc.add(fc.ell(Q(an.x + out * tx, 0.022, an.y + tz), (r, r * 0.95, r * 1.35)), 0.004)            # toes
		fc.cut(fc.ell(Q(an.x - out * 0.05, 0.0, an.y - 0.05), (0.026, 0.02, 0.05)), 0.012)               # the arch
		fc.keep((0.0 - HC.z) - fc.V, 0.003)  # (the sole flat on the floor)
		finish(fc.mesh(f"foot_{side}", skin, PARTS), 5000)
		del fc

# ---------------------------------------------------------------- the head, hair and beard (round 2: dwarf_head.py)
# One melted, sculpted skin built around the body (the beard and hair lie ON it with a 1.2 cm gap), separate eyes and
# copper rings. Placed from the picture: crown at 1.19 m, the skull's middle above the body's middle.
head = B("Head")
BODY_PARTS = [o for o in bpy.context.scene.objects if o.type == "MESH"]
HEAD = dh.build(BODY_PARTS, fast=FAST)
if REVIEW:
	dh.review(REVIEW)
BODYREV = next((a[5:] for a in ARGS[2:] if a.startswith("body=")), None)
if FAST and not BODYREV:
	print("DWARF_FAST_DONE")
	sys.exit(0)
if FAST:  # (the body pictures need the weights: the unbaked head is thinned like the game's copy first, or weighing it takes ages)
	hh = HEAD["head"]
	bpy.context.view_layer.objects.active = hh
	m = hh.modifiers.new("fewer", "DECIMATE")
	m.ratio = 44000 / len(hh.data.polygons)
	bpy.ops.object.modifier_apply(modifier="fewer")
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
	CHAINS[f"hair_back_{'lmr'[k] if len(dh.BACKS) == 3 else ('m' if len(dh.BACKS) == 1 else k)}"] = (None, list(pts), "Head")  # (a bone per point)
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
	if o in HEAD_OBJS or not ("shirt_body" in o.name or "torso" in o.name):  # (the shirt, or the bare torso)
		continue
	names = {vg.index: vg.name for vg in o.vertex_groups}
	for v in o.data.vertices:
		sp.append(o.matrix_world @ v.co)
		ws = {}
		for g in v.groups:
			if g.weight <= 0.0:
				continue
			# the beard and hair never follow the arms (near the shoulders the shirt does: raising the arms tore the
			# beard beside the braids, owner Nov 17): the arms' share goes to the chest
			name = names[g.group]
			if name.startswith(("clavicle", "upperarm", "lowerarm", "hand", "thumb", "index", "middle", "ring", "pinky")):
				name = "spine_03"
			ws[name] = ws.get(name, 0.0) + g.weight
		sw.append(ws)
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


def along_by_height(pts, z):
	"""How far down a chain that only goes down (the back hair) the height z is. (Nov 17: the nearest point on the
	chain jumps from one link to the next where the chain bends, so the hair beside the bend followed two different
	bones on either side of a line, and tore into a sheet there when the head moved against the back.)"""
	s = 0.0
	for a, b in zip(pts[:-1], pts[1:]):
		seg = (b - a).length
		if z >= a.z:
			return s
		if z >= b.z:
			return s + seg * (a.z - z) / max(a.z - b.z, 1e-9)
		s += seg
	return s


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
	if backs and dh.C.y - p.y <= -0.03:  # (shared softly between the near strands: a hard border between them tore too)
		ds = {c: max(along(backs[c], p)[1], 0.005) for c in backs}
		near = min(ds.values())
		share = {c: (near / d) ** 4 for c, d in ds.items()}
		tot = sum(share.values())
		back_owner[vi] = {c: x / tot for c, x in share.items() if x / tot > 0.02}
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
		if bd is not None:  # the whole braid (blended in over its top 7 cm: a 3 cm hand-over stretched 10x when swinging)
			if braid_owner.get(vi) != cname:
				continue
			m = smooth01(s / 0.07) * (1.0 - smooth01((d - bd["reach"]) / (bd["reach"] * 0.6)))
		else:  # the back hair: ALL of it behind the skull, from the crown's back down, goes with its nearest strand
			v_, w_ = p.z - dh.C.z, dh.C.y - p.y
			share = back_owner.get(vi, {}).get(cname, 0.0)
			if share <= 0.0:
				continue
			s = along_by_height(joints, p.z)  # (by height: no jumps where the chain bends)
			# a long, gradual hand-over from the head to the swinging bones over the first 10 cm down the strand (owner,
			# Nov 17: sharp borders here, by height or distance from the neck, stretched into a flat sheet when it swung)
			# (hair further to the sides follows the ponytail less and less, fading out gradually toward the ears)
			m = smooth01(s / 0.1) * smooth01((-w_ - 0.03) / 0.05) * share * (1.0 - smooth01((d - 0.08) / 0.14))
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

if BODYREV:
	# the whole dwarf, front / side / back, the arms lowered like the turnaround picture's (65 degrees down, bent by the
	# real weights: the shoulders and the shirt are judged as they'll look in the game, not in the T-pose)
	# (body round, Nov 17-18; compare with dwarf_turnaround.png)
	scene = bpy.context.scene
	bpy.context.view_layer.objects.active = arm
	bpy.ops.object.mode_set(mode="POSE")
	for side, sg in (("l", 1), ("r", -1)):
		pb = arm.pose.bones[f"upperarm_{side}"]
		h = pb.head.copy()
		rot = Matrix.Translation(h) @ Matrix.Rotation(math.radians(65) * (1 if pb.head.x > 0 else -1), 4, "Y") @ Matrix.Translation(-h)
		pb.matrix = rot @ pb.matrix
	bpy.ops.object.mode_set(mode="OBJECT")
	bpy.context.view_layer.update()
	scene.render.engine = "BLENDER_WORKBENCH"
	scene.display.shading.light = "STUDIO"
	scene.display.shading.color_type = "MATERIAL"
	scene.render.resolution_x, scene.render.resolution_y = 600, 700
	cam = bpy.data.objects.new("bcam", bpy.data.cameras.new("bcam"))
	cam.data.type = "ORTHO"
	cam.data.sensor_fit = "VERTICAL"
	cam.data.ortho_scale = 1.32
	scene.collection.objects.link(cam)
	scene.camera = cam
	shots = []
	for tag, loc in (("front", Vector((0, -4, 0.6))), ("side", Vector((-4, 0, 0.6))), ("back", Vector((0, 4, 0.6)))):
		cam.location = loc
		cam.rotation_euler = (Vector((0, 0, 0.6)) - loc).to_track_quat("-Z", "Y").to_euler()
		path = str(Path(BODYREV).with_name(Path(BODYREV).stem + f"_{tag}.png"))
		scene.render.filepath = path
		bpy.ops.render.render(write_still=True)
		shots.append(path)
	print("BODY_REVIEW", shots)
	if FAST:
		print("DWARF_FAST_DONE")
		sys.exit(0)
	for pb in arm.pose.bones:  # (back to the rest pose for the export)
		pb.matrix_basis = Matrix()
	bpy.context.view_layer.update()

bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_yup=True, export_skins=True,
	export_animations=False, export_apply=False, export_image_format="JPEG", export_image_quality=88)
import glb_jpeg_fix  # noqa: E402  every Blender export with JPEG pictures needs this, or Godot shows it white (F164)
glb_jpeg_fix.fix(OUT)
lo = Vector([min(min((o.matrix_world @ Vector(v))[k] for v in o.bound_box) for o in meshes) for k in range(3)])
hi = Vector([max(max((o.matrix_world @ Vector(v))[k] for v in o.bound_box) for o in meshes) for k in range(3)])
print(f"DWARF_DONE {OUT} size {hi.x - lo.x:.2f} x {hi.y - lo.y:.2f} x {hi.z - lo.z:.2f} m, {len(meshes)} parts")
