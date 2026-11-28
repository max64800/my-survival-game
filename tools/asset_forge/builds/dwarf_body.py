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
FAST_GLB = "glb" in ARGS[2:]  # fast glb: the grey, unpainted dwarf, weighted and saved (for shape pages; F916, Nov 26)
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
def etube(cl, a, b, r0, r1, sv, sw):
	"""A tube with an oval cross-section: sv times as wide up-down and sw times front-back (for an arm held out in the
	rest pose, up-down is its width seen from the front once it hangs, front-back is its depth seen from the side)."""
	a, b = np.array(a, np.float32), np.array(b, np.float32)
	ba = b - a
	pu, pv, pw = cl.U - a[0], cl.V - a[1], cl.W - a[2]
	t = np.clip((pu * ba[0] + pv * ba[1] + pw * ba[2]) / float(ba @ ba), 0.0, 1.0)
	r = r0 + (r1 - r0) * t
	return (np.sqrt((pu - ba[0] * t) ** 2 + ((pv - ba[1] * t) / sv) ** 2 + ((pw - ba[2] * t) / sw) ** 2) - r) * min(sv, sw)


WRIST_END = 0.045   # the forearm (torso clay) ends this far up from the wrist; its round end stays inside the stub
WRIST_STUB = 0.085  # the hand's wrist piece runs this far up the forearm, a hair thinner there, so it fades into it


def forearm_r(el, wr, at):
	"""The forearm's round radius at a point between the elbow and the wrist (the torso's tube: 6 cm -> 3.9 cm)."""
	t = min(max((at - el).length / max((wr - el).length, 1e-6), 0.0), 1.0)
	return 0.06 + (0.039 - 0.06) * t


for side in ("l", "r"):
	wr = B(f"hand_{side}")
	el_ = B(f"lowerarm_{side}")
	stub = wr + (el_ - wr).normalized() * WRIST_STUB
	chains = {f: [B(f"{f}_0{k}_{side}") for k in (1, 2, 3)] + [B(f"{f}_04_leaf_{side}")] for f in ("index", "middle", "ring", "pinky", "thumb")}
	# two fat fingers and a thumb, like a cartoon turtle's (owner, Nov 18): one along the index and middle bones, one along
	# the ring and little-finger bones, so each bends with both
	fingers = [[a.lerp(b, 0.5) for a, b in zip(chains["index"], chains["middle"])],
		[a.lerp(b, 0.5) for a, b in zip(chains["ring"], chains["pinky"])]]
	mids = [a.lerp(b, 0.5) for a, b in zip(fingers[0], fingers[1])]
	# (Nov 21, F549, owner: "hands too big, very wide fingers"): slimmer fingers and palm, same length (fists still close
	# round the tools); was spread 1.1, fingers 0.029, palm 0.032 thick and 0.03 past the knuckles
	fingers = [[Vector((p.x, m.y + (p.y - m.y) * 1.05, p.z)) for p, m in zip(f, mids)] for f in fingers]  # (chunky fists)
	pts = [p for c in chains.values() for p in c] + [wr, stub] + [p for f in fingers for p in f]
	lo = Vector([min(p[i] for p in pts) - 0.06 for i in range(3)])
	hi = Vector([max(p[i] for p in pts) + 0.06 for i in range(3)])
	cl = clay((lo.x, lo.z, lo.y), (hi.x, hi.z, hi.y), 0.0025)
	knuck = [f[0] for f in fingers]
	mid = (knuck[0] + knuck[1]) / 2
	along = (mid - wr).length
	cl.add(cl.ell(QV(wr.lerp(mid, 0.55)), (along * 0.57, 0.027, (knuck[1] - knuck[0]).length / 2 + 0.02)), 0.012)  # the palm (flatter: Nov 18)
	cl.add(cl.ell(QV(wr.lerp(mid, 0.1)), (0.032, 0.026, 0.033)), 0.02)                                          # the wrist end
	# (F943) the wrist: a piece of forearm in the hand's own skin, from inside the forearm (1.5 mm thinner than it, so the
	# two surfaces meet at a shallow angle, like the ankle) down to a slim wrist, joined to the palm with a wide fillet
	# (two pieces: up the forearm it grows from 1.5 mm inside to 1.5 mm over the forearm's round end, which it covers,
	# then it narrows to the wrist)
	we_ = wr + (el_ - wr).normalized() * WRIST_END
	r_we = forearm_r(el_, wr, we_) + 0.0015
	cl.add(etube(cl, QV(stub), QV(we_), forearm_r(el_, wr, stub) - 0.0015, r_we, 0.9, 1.05), 0.01)
	cl.add(etube(cl, QV(we_), QV(wr), r_we, 0.036, 0.9, 1.05), 0.022)
	cl.add(cl.ell(QV(wr + (el_ - wr).normalized() * 0.012 + Vector((0, 0.03, 0.0))), (0.012, 0.01, 0.011)), 0.008)  # the wrist bone's knob
	for k, f in enumerate(fingers):
		r0 = 0.022
		f = [f[0].lerp(wr, 0.25)] + f[1:]  # (from inside the palm)
		for j in range(len(f) - 1):
			cl.add(cl.tube(QV(f[j]), QV(f[j + 1]), r0 * (1 - 0.06 * j), r0 * (1 - 0.06 * (j + 1))), 0.004)
		cl.add(cl.ell(QV(f[-1]), (0.019, 0.018, 0.019)), 0.005)                       # a round fingertip
		cl.add(cl.ell(QV(f[1] + Vector((0, 0, 0.008))), (0.019, 0.012, 0.019)), 0.005)  # the knuckle on top
	th = chains["thumb"]
	th = [th[0].lerp(mid, 0.15)] + th[1:]
	for j in range(len(th) - 1):
		cl.add(cl.tube(QV(th[j]), QV(th[j + 1]), 0.022 * (1 - 0.07 * j), 0.022 * (1 - 0.07 * (j + 1))), 0.005)
	cl.add(cl.ell(QV(th[-1]), (0.02, 0.02, 0.02)), 0.005)
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


# Sewn-on square patches over old holes (owner, Nov 18): (piece, x, height, front?, half-width, half-height, tilt (rad),
# colour against the cloth). Raised ~3 mm with crisp edges; painted another shade with dashed stitches round the edge.
# (owner, Nov 18: brown patches of different sizes round the shirt too, one on the chest where he drew it)
PATCHES = [("shirt", 0.05, 0.63, True, 0.027, 0.024, 0.12, (0.62, 0.46, 0.32)), ("shirt", -0.14, 0.5, True, 0.042, 0.036, -0.08, (0.55, 0.4, 0.28)),
	("shirt", 0.15, 0.76, True, 0.017, 0.015, -0.2, (0.5, 0.37, 0.26)), ("shirt", 0.1, 0.7, False, 0.04, 0.034, -0.1, (0.6, 0.45, 0.31)),
	("shirt", -0.13, 0.53, False, 0.023, 0.02, 0.2, (0.52, 0.38, 0.27)),
	("shorts", 0.16, 0.335, True, 0.03, 0.028, -0.18, (0.78, 0.82, 0.9)), ("shorts", -0.13, 0.39, False, 0.034, 0.03, 0.1, (1.15, 1.0, 0.8))]


def patch_box(px, py, front, p):
	"""How far outside a patch's square a point is (x, height), on its side of the body; < 0 inside."""
	_, cx, cy, fr, hw, hh, tilt, _c = p
	dx, dy = px - cx, py - cy
	c_, s_ = math.cos(tilt), math.sin(tilt)
	u, v = dx * c_ + dy * s_, -dx * s_ + dy * c_
	side = np.where(front == fr, -1.0, 1.0)  # (was 0.0 on its own side: then nothing was ever "inside", no patch showed, Nov 18)
	return np.maximum(np.maximum(np.abs(u) - hw, np.abs(v) - hh), side)


CLOTH_CHAINS = {}  # springy cloth bones: name -> ([joints], angle round the body)
if not CLOTHES:
	# the body's outline (height, half-width, front, back). F916 (owner, Nov 26: "buff, not fat"; dwarf_buff_target.png):
	# a broad, deep barrel chest that is the widest part, a firm flat stomach (no hanging belly: plate armour poked
	# through it), a slight taper to the waist, hips a little narrower than the chest. (Before: a round belly, F25.)
	# (the back only gently curved: owner Nov 18, a deeper upper back looked "like he is gonna grow wings")
	TORSO = [(0.3, 0.06, 0.05, 0.05), (0.35, 0.16, 0.13, 0.13), (0.4, 0.205, 0.16, 0.152),  # (a narrow rounded crotch, not a flat plate: Nov 18)
		 (0.47, 0.192, 0.172, 0.148), (0.55, 0.19, 0.18, 0.152),
		(0.62, 0.222, 0.187, 0.168), (0.69, 0.265, 0.193, 0.184), (0.76, 0.285, 0.198, 0.19), (0.82, 0.278, 0.192, 0.184),
		(0.87, 0.228, 0.145, 0.158), (0.93, 0.095, 0.07, 0.09)]
	# (round 4, owner Nov 26 "still has woman boobs": the side view bulged out at the chest and curved back in under it.
	# Now the front runs nearly straight from the collar down to the stomach, so the chest is deep but has no underside.)
	cl = clay((-0.72, 0.09, -0.36), (0.72, 1.0, 0.33))
	cl.add(loft(cl, TORSO), 0.012)
	# the neck's base (F943): a short, thick column from the chest up into the head's neck (dwarf_head: 7 cm round, from
	# 0.88 m), wider at the bottom, so bare skin shows round the neck between the collar and the beard
	cl.add(cl.tube(Q(0.0, 0.85, 0.025), Q(0.0, 0.97, 0.025), 0.088, 0.071), 0.045)
	# (no stomach lump either: its round edge made a ball low on the front. The front is one flat slab, like a breastplate.)
	for s in (-1, 1):
		cl.add(cl.ell(Q(s * 0.088, 0.36, 0.11), (0.1, 0.098, 0.098)), 0.04)                # buttock (round, sticking out: Nov 18)
		cl.add(cl.ell(Q(s * 0.19, 0.69, 0.035), (0.07, 0.12, 0.11)), 0.06)                 # the back's wings (lats): a V to the waist
		cl.add(cl.ell(Q(s * 0.1, 0.77, 0.15), (0.1, 0.08, 0.045)), 0.05)                   # shoulder blades' muscle (a broad back)
	for side in ("l", "r"):
		sh, el, wr = B(f"upperarm_{side}"), B(f"lowerarm_{side}"), B(f"hand_{side}")
		s = 1 if sh.x > 0 else -1
		inward = -s
		d, f_ = el - sh, wr - el
		# the slope from the neck to the shoulder (trapezius) and the round shoulder muscle
		# (F943, owner Nov 28: "fix his neck muscles, what is this?": it started by the neck at 0.925 m, so its round top
		# stood up as a bump behind the neck, in the new neck hole. Now it starts lower and beside the neck, and a thick
		# neck base flares into it: one smooth curve from the neck down to the shoulder)
		cl.add(cl.tube(Q(s * 0.065, 0.885, 0.03), QV(sh + Vector((inward * 0.07, 0.04, 0.04))), 0.068, 0.08), 0.05)  # (F916: bigger)
		cl.add(cl.ell(QV(sh + Vector((inward * 0.0, 0.016, 0.01))), (0.124, 0.116 * 0.8, 0.108 * 1.15)), 0.045)  # (owner: even bigger)  # (F916: big shoulders)  # (round; narrow from the front, deeper from the side: Nov 18)
		# upper arm with the biceps in front and the triceps behind, the elbow
		cl.add(etube(cl, QV(sh), QV(el), 0.086, 0.068, 0.9, 1.05), 0.025)  # (F916: thick strong arms)  # (owner Nov 18: 20% narrower from the front, 15% deeper from the side)
		cl.add(cl.ell(QV(sh + d * 0.5 + Vector((0, -0.022, 0.01))), (0.088, 0.066 * 0.9, 0.068 * 1.05)), 0.025)
		cl.add(cl.ell(QV(sh + d * 0.42 + Vector((0, 0.026, 0.0))), (0.09, 0.064 * 0.9, 0.064 * 1.05)), 0.025)
		cl.add(cl.ell(QV(el + Vector((0, 0.012, 0))), (0.052, 0.058 * 0.9, 0.056 * 1.05)), 0.02)
		# the forearm: thick by the elbow, tapering to a clear wrist (owner Nov 18: "the forearms are still too large")
		# (F943, owner Nov 28: "make the transition to his wrist smoother": the forearm's round end stood thicker than the
		# hand and left a step. Now it ends inside the hand's wrist piece, which carries on up the forearm: WRIST_STUB)
		we = wr + (el - wr).normalized() * WRIST_END
		cl.add(etube(cl, QV(el), QV(we), 0.06, forearm_r(el, wr, we), 0.9, 1.05), 0.02)
		cl.add(cl.ell(QV(el + f_ * 0.3 + Vector((0, 0, 0.004))), (0.076, 0.056 * 0.9, 0.056 * 1.05)), 0.025)
		# hip, thigh, knee and kneecap, shin and calf muscle
		th, kn, an = B(f"thigh_{side}"), B(f"calf_{side}"), B(f"foot_{side}")
		cl.add(cl.tube(QV(th + Vector((s * 0.012, 0, 0))), QV(kn + Vector((0, 0, 0.03))), 0.106, 0.066), 0.05)  # (F916: thick legs)  # (tapers into the knee)
		cl.add(cl.ell(QV(kn), (0.054, 0.05, 0.05)), 0.02)                                 # the knee
		cl.add(cl.ell(QV(kn + Vector((0, -0.05, 0.008))), (0.034, 0.036, 0.022)), 0.01)   # kneecap
		cl.add(cl.tube(QV(kn + Vector((0, 0, -0.02))), Q(an.x, 0.105, an.y), 0.054, 0.036), 0.03)  # shin (into the foot, no step)
		cl.add(cl.ell(QV(kn + (an - kn) * 0.32 + Vector((0, 0.026, 0))), (0.062, 0.072, 0.054)), 0.035)
	# soft lines: under the chest, the breastbone, the spine, the cleft, the navel, the belly's fold over the pants
	# (F916: no line under the chest at all: any groove there read as the underside of breasts)
	# (F916: no breastbone line down the chest: it read as a cleavage)
	groove(cl, [(0.0, 0.87), (0.0, 0.7), (0.0, 0.5)], False, 0.003, 0.012)
	groove(cl, [(0.0, 0.43), (0.0, 0.32)], False, 0.006, 0.01)
	for s in (-1, 1):  # the crease under each buttock, where it meets the thigh
		groove(cl, [(s * 0.02, 0.29), (s * 0.08, 0.275), (s * 0.15, 0.29)], False, 0.006, 0.01)
	for side in ("l", "r"):  # the hollow behind each knee
		kn = B(f"calf_{side}")
		press(cl, [(QV(kn + Vector((-0.02, 0.05, 0.0))), QV(kn + Vector((0.02, 0.05, 0.0))), 1.0)], 0.006, 0.012)
	cl.cut(cl.ell(on_surf(cl, 0.0, 0.53, True, -0.004), (0.011, 0.014, 0.012)), 0.005)
	# (F916: no belly, so no fold over the pants)
	for s in (-1, 1):
		groove(cl, [(s * 0.03, 0.88), (s * 0.1, 0.875), (s * 0.18, 0.86)], True, -0.004, 0.009)  # collarbone (a ridge)
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
	# ---- simple clothes as their own layers over the bare body (owner, Nov 18: "simplistic, but I want it to bounce a
	# little when running"): each is a shell lying a little off the skin (made from the skin's own distance field, so
	# it fits every bulge), with rolled edges. They copy the skin's bending (see the weights) and the shirt's hem gets
	# springy bones (CLOTH_CHAINS) that the game swings like the hair.
	def shell_of(c, off, inner=0.004):
		"""The space between `inner` under the skin and `off` above it."""
		return np.abs(F - (off - inner) / 2) - (off + inner) / 2

	def lip(c, off, along, r):
		"""A rolled edge where the cloth (at `off` from the skin) meets the cut `along` = 0."""
		return np.sqrt((F - off + r * 0.4) ** 2 + along ** 2) - r

	sl = {}
	for side in ("l", "r"):
		sh_, el_ = B(f"upperarm_{side}"), B(f"lowerarm_{side}")
		sl[side] = sh_.x + (el_.x - sh_.x) * 0.5  # the sleeve ends halfway down the upper arm
	# the shirt
	sc = clay((-0.72, 0.09, -0.36), (0.72, 1.0, 0.33))
	up_ = sc.V + HC.z
	x_ = sc.U + HC.x
	th_ = np.arctan2(x_, -(HC.y - sc.W))
	hem = 0.415 - 0.02 * np.clip(np.cos(th_), 0, None) + 0.005 * np.sin(3 * th_ + 0.6)  # (a little lower over the belly)
	# (lower down the shirt stands well off the shorts: Nov 18 the shorts' top showed through the shirt above the hem)
	off = 0.016 + 0.014 * np.clip((0.52 - up_) / 0.1, 0, 1)  # (F916: less flare, so the waist shows; was 0.026)
	off = off + 0.002 * np.clip((np.abs(x_) - 0.22) / 0.05, 0, 1)
	arms = np.maximum(x_ - sl["l"], sl["r"] - x_) if sl["l"] > 0 else np.maximum(x_ - sl["r"], sl["l"] - x_)
	# the neck hole (F943, owner Nov 28: "his shoulders near the neck are not covered by the t-shirt"): the shirt used to
	# stop at one height (0.915 m), so the shoulder slopes rising to the neck stuck out bare. Now only an oval round the
	# neck is cut out (> 0 = cut away), and the shirt runs up the shoulder slopes to it.
	nb = (HC.y - sc.W) - 0.01  # (front/back from the neck's middle)
	neck = np.minimum(0.09 * (1.0 - np.sqrt((x_ / 0.12) ** 2 + (nb / 0.105) ** 2)), up_ - 0.845)  # (a bit of neck skin shows)
	sc.D = np.maximum(np.maximum(shell_of(sc, off), hem - up_), np.maximum(arms, np.maximum(neck, up_ - 1.0))).astype(np.float32)
	sc.add(np.maximum(lip(sc, off, up_ - hem - 0.006, 0.009), arms), 0.005)                     # the hem
	sc.add(np.maximum(lip(sc, off, arms + 0.004, 0.006), hem - up_), 0.004)                     # the sleeve ends (thin: Nov 18)
	sc.add(np.maximum(lip(sc, off, neck + 0.006, 0.009), np.maximum(arms, up_ - 1.0)), 0.005)  # the collar, round the neck hole
	del nb, neck
	for pt in PATCHES:  # sewn-on patches: a raised square of cloth 3 mm over the shirt
		if pt[0] == "shirt":
			box = patch_box(x_, up_, (HC.y - sc.W) < 0, pt)
			sc.add(np.maximum(box, F - off - 0.003), 0.0015)
	del th_, off, arms
	for s_ in (-1, 1):  # a few soft folds: from the armpits toward the belly, and hanging over the belly
		groove(sc, [(s_ * 0.2, 0.74), (s_ * 0.13, 0.64), (s_ * 0.07, 0.58)], True, 0.003, 0.012)
		groove(sc, [(s_ * 0.15, 0.5), (s_ * 0.16, 0.43)], True, 0.003, 0.012)
		groove(sc, [(s_ * 0.17, 0.78), (s_ * 0.08, 0.64)], False, 0.003, 0.012)
	groove(sc, [(0.0, 0.9), (0.0, 0.8)], True, 0.004, 0.006)                                    # the neck slit
	# the hem's springy bones: six strips round the bottom edge, each 2 bones from 9 cm above the edge to the edge
	for k in range(6):
		a_ = k * math.pi / 3  # (front, front-sides, back-sides, back: not at the sides, where the hands hang)
		joints = []
		for dz in (0.09, 0.045, 0.0):  # (not 'dh': that's the head builder)
			h0 = 0.415 - 0.02 * max(math.cos(a_), 0) + 0.005 * math.sin(3 * a_ + 0.6) + dz
			best = None
			for rr in np.arange(0.4, 0.05, -0.003):  # from outside in, to the shirt's surface
				px, pb = math.sin(a_) * rr, -math.cos(a_) * rr
				i = int(round((px - HC.x - sc.lo[0]) / sc.h))
				j = int(round((h0 - HC.z - sc.lo[1]) / sc.h))
				kk = int(round((HC.y - pb - sc.lo[2]) / sc.h))
				if not (0 <= i < sc.D.shape[0] and 0 <= j < sc.D.shape[1] and 0 <= kk < sc.D.shape[2]):
					continue
				if sc.D[i, j, kk] < 0:
					best = Vector((px, pb, h0))
					break
			joints.append(best if best is not None else Vector((math.sin(a_) * 0.25, -math.cos(a_) * 0.25, h0)))
		CLOTH_CHAINS[f"cloth_hem_{k}"] = (joints, a_)
	finish(sc.mesh("shirt", shirt, PARTS), 9000)
	del sc
	# the shorts: baggy, from under the shirt to just above the knee, rolled cuffs
	oc = clay((-0.72, 0.09, -0.36), (0.72, 1.0, 0.33))  # (the body's grid: F fits it)
	up_ = oc.V + HC.z
	x_ = oc.U + HC.x
	cuff = 0.232  # (lower: the bottom peeked out under them, Nov 18)
	off = 0.024 + 0.006 * np.clip((0.4 - up_) / 0.1, 0, 1)  # (baggy: solid cloth this close looked like tight pants)
	off = off - 0.012 * np.clip((up_ - 0.425) / 0.03, 0, 1)  # (thin where the shirt covers it, so it never shows through)
	# (solid cloth over the skin, not a thin hollow layer: from below the hollow showed cut edges and the underpants)
	oc.D = np.maximum(np.maximum(F - off, up_ - 0.47), np.maximum(cuff - up_, np.abs(x_) - 0.33)).astype(np.float32)
	oc.add(np.maximum(lip(oc, off, up_ - cuff - 0.005, 0.007), np.abs(x_) - 0.33), 0.004)       # rolled cuffs (thin)
	# (two legs, not a skirt: with the narrow crotch the two legs of the cloth stay apart by themselves)
	for pt in PATCHES:
		if pt[0] == "shorts":
			box = patch_box(x_, up_, (HC.y - oc.W) < 0, pt)
			oc.add(np.maximum(box, F - off - 0.003), 0.0015)
	for s_ in (-1, 1):
		groove(oc, [(s_ * 0.2, 0.4), (s_ * 0.17, 0.32)], True, 0.003, 0.01)
		groove(oc, [(s_ * 0.06, 0.38), (s_ * 0.1, 0.31)], True, 0.003, 0.01)
	finish(oc.mesh("shorts", shorts, PARTS), 6000)
	del oc, up_, x_, off, hem
	del cl, pc, F, body_D
	# ---- bare feet (finer clay): ankle and its bones, heel, arch, the ball of the foot and four chunky toes
	for side in ("l", "r"):
		an = B(f"foot_{side}")
		out = 1 if an.x > 0 else -1
		fc = clay((an.x - 0.1, -0.01, an.y - 0.21), (an.x + 0.1, 0.2, an.y + 0.12), 0.0025)
		# (Nov 18, owner: the heel stuck out "like a toe on the back", the top of the foot too steep: the leg now runs
		# straight down into a small heel blended in with a big fillet, and the top of the foot slopes gently)
		fc.add(fc.tube(Q(an.x, 0.2, an.y), Q(an.x, 0.07, an.y + 0.004), 0.031, 0.038), 0.02)              # the ankle
		for s2 in (-1, 1):
			fc.add(fc.ell(Q(an.x + s2 * 0.031, 0.118, an.y + 0.002), (0.01, 0.013, 0.01)), 0.006)          # ankle bones
		fc.add(fc.ell(Q(an.x, 0.03, an.y + 0.004), (0.036, 0.03, 0.03)), 0.03)                           # heel (small)
		fc.add(fc.ell(Q(an.x + out * 0.004, 0.026, an.y - 0.065), (0.055, 0.03, 0.09)), 0.03)            # the foot (flat)
		fc.add(fc.tube(Q(an.x, 0.085, an.y - 0.004), Q(an.x + out * 0.004, 0.04, an.y - 0.115), 0.034, 0.024), 0.03)  # instep
		fc.add(fc.ell(Q(an.x + out * 0.006, 0.025, an.y - 0.112), (0.06, 0.025, 0.04)), 0.025)            # ball of the foot
		for tx, tz, r in ((-0.021, -0.162, 0.027), (0.023, -0.152, 0.025)):  # two chunky toes, a bit like a lizard's (owner, Nov 18)
			# (F943, owner Nov 28: "the transition to his toes smoother": they were stuck on with a 4 mm fillet, a sharp
			# crease; now a wide one, and the split between the toes is cut back in at the front below)
			fc.add(fc.ell(Q(an.x + out * tx, 0.02, an.y + tz), (r * 0.9, r * 0.8, r * 1.45)), 0.014)
		fc.cut(fc.ell(Q(an.x + out * 0.001, 0.024, an.y - 0.19), (0.0035, 0.03, 0.045)), 0.005)          # between the toes
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
# ---- the paint (Nov 18, owner: "a nice paint job"): the same hand-painted look as the face, baked into pictures. The
# skin matches the face's; the shirt and the underpants are linen, the shorts brown wool, each with a fine weave pressed
# into a detailed copy (it shows in the light through the baked bumps). Plain colours in the quick (fast) builds.
PAINT = {
	# (skin: scaled so its baked colour matches the face's, measured: the first try baked 180,135,113 vs the face 157,108,87)
	"skin": dict(base=(0.75, 0.5, 0.385), dark=(0.435, 0.25, 0.19), light=(0.85, 0.66, 0.56), weave=0.0, per=1.0, size=2048),
	"shirt": dict(base=(0.86, 0.8, 0.66), dark=(0.48, 0.41, 0.3), light=(0.98, 0.95, 0.86), weave=0.0011, per=0.008, size=2048, checks=0.0, threads=0.4),
	"shorts": dict(base=(0.5, 0.33, 0.2), dark=(0.22, 0.13, 0.07), light=(0.68, 0.5, 0.33), weave=0.0011, per=0.008, size=2048, checks=0.045),
	"wraps": dict(base=(0.84, 0.79, 0.67), dark=(0.48, 0.42, 0.32), light=(0.97, 0.94, 0.86), weave=0.0007, per=0.006, size=1024, checks=0.0),
}


def weave(q, n, amp, per):
	"""A woven cloth's little bumps: two sets of threads crossing."""
	k = 2 * math.pi / per
	return amp * 0.5 * (math.sin(k * (q.x + q.z)) * math.cos(k * 0.5 * (q.y - q.z)) + math.sin(k * (q.y - q.z)) * math.cos(k * 0.5 * (q.x + q.z)))


if not FAST:
	for o in [o for o in BODY_PARTS if o.type == "MESH" and o.data.materials]:
		mname = o.data.materials[0].name.split(".")[0]
		pp = PAINT.get(mname)
		if pp is None:
			continue
		cloth = pp["weave"] > 0
		hi = dh.cs.detail_copy(o, 3 if cloth else (2 if len(o.data.polygons) < 9000 else 1), o.name + "_high")
		tint = None
		if cloth:
			dh.cs._displace(hi, lambda q, n, a=pp["weave"], w=pp["per"]: weave(q, n, a, w))
			# painted threads (owner, Nov 18: "more texture, I don't see a lot of change"): light and dark lines both ways,
			# and on the shorts darker checks every few centimetres like the picture's
			co = np.empty(len(hi.data.vertices) * 3)
			hi.data.vertices.foreach_get("co", co)
			co = co.reshape(-1, 3)
			k = 2 * math.pi / pp["per"]
			f = 0.5 * (np.abs(np.sin(k * 0.5 * (co[:, 0] + co[:, 1]))) + np.abs(np.sin(k * 0.5 * co[:, 2])))
			mult = (1.0 - pp.get("threads", 0.28) / 2) + pp.get("threads", 0.28) * f  # (stronger threads on the shirt: Nov 18)
			if pp["checks"] > 0:
				kc = 2 * math.pi / pp["checks"]
				band = np.maximum(np.clip((np.sin(kc * co[:, 2]) - 0.75) / 0.15, 0, 1), np.clip((np.sin(kc * (co[:, 0] + co[:, 1])) - 0.75) / 0.15, 0, 1))
				mult = mult * (1.0 - 0.3 * band)
			rgb = np.stack([mult, mult, mult], 1)
			for pt in PATCHES:  # the patches: another shade, with dashed stitches just inside the edge
				if pt[0] != o.name.replace("body_", ""):
					continue
				box = patch_box(co[:, 0], co[:, 2], co[:, 1] < 0, pt)
				inside = box < 0.0
				rgb[inside] *= np.array(pt[7])
				edge = inside & (box > -0.005) & (np.sin((co[:, 0] + co[:, 2]) * 2 * math.pi / 0.008) > 0.0)
				rgb[edge] *= 0.55
			at = hi.data.color_attributes.new("tint", "FLOAT_COLOR", "POINT")
			at.data.foreach_set("color", np.concatenate([rgb, np.ones((len(rgb), 1))], 1).ravel())
			tint = "tint"
		hi.data.materials.clear()
		hi.data.materials.append(dh.cs.paint_material(f"paint_{o.name}", base=pp["base"], dark=pp["dark"], light=pp["light"],
			strokes=0.09 if cloth else 0.05, top_light=0.12, edge=0.25, key=0.28, seed=3, tint_attr=tint))
		dh.cs.uv_only(o)
		dh.cs.bake(hi, o, pp["size"], f"{o.name}_baked", ext=0.01)
		bpy.data.objects.remove(hi, do_unlink=True)
		print("DWARF painted", o.name, mname)
if REVIEW:
	dh.review(REVIEW)
BODYREV = next((a[5:] for a in ARGS[2:] if a.startswith("body=")), None)
if FAST and not BODYREV and not FAST_GLB:
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
for cname, (joints, _a) in CLOTH_CHAINS.items():  # the shirt hem's springy bones (the game swings them like hair)
	prev = arm_data.edit_bones["pelvis"]
	for k in range(len(joints) - 1):
		eb = arm_data.edit_bones.new(f"{cname}_{k + 1}")
		eb.head, eb.tail = joints[k], joints[k + 1]
		eb.parent = prev
		eb.use_deform = False
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
# Clothes copy the skin's bending: each point of the underpants follows exactly the bones of the skin point under it
# (Nov 18: weighed on their own, the skin poked through the pants when he ran). The clothes will do the same (F245).
torso_o = next((o for o in meshes if "torso" in o.name), None)
if torso_o is not None:
	from mathutils import kdtree as _kd
	tv = torso_o.data.vertices
	tkd = _kd.KDTree(len(tv))
	for v in tv:
		tkd.insert(torso_o.matrix_world @ v.co, v.index)
	tkd.balance()
	tnames = {vg.index: vg.name for vg in torso_o.vertex_groups}
	for o in meshes:
		if not ("pants" in o.name or o.name in ("body_shirt", "body_shorts")):
			continue
		for vg in list(o.vertex_groups):
			o.vertex_groups.remove(vg)
		for v in o.data.vertices:
			src = tv[tkd.find(o.matrix_world @ v.co)[1]]
			for g in src.groups:
				if g.weight > 0.0:
					gg = o.vertex_groups.get(tnames[g.group]) or o.vertex_groups.new(name=tnames[g.group])
					gg.add([v.index], g.weight, "REPLACE")
		print("DWARF clothes copy the skin's bones:", o.name)
	# the shirt's bottom edge: up to 9 cm above it follows the hem's springy strips (each point its two nearest strips
	# round the body, blended), so the edge sways and bounces when he runs; higher up only the skin's bones
	shirt_o = next((o for o in meshes if o.name == "body_shirt"), None)
	if shirt_o is not None and CLOTH_CHAINS:
		names_s = {vg.index: vg.name for vg in shirt_o.vertex_groups}
		angs = {c: a_ for c, (_j, a_) in CLOTH_CHAINS.items()}
		for v in shirt_o.data.vertices:
			p = shirt_o.matrix_world @ v.co
			th = math.atan2(p.x, -p.y)
			hem_v = 0.415 - 0.02 * max(math.cos(th), 0) + 0.005 * math.sin(3 * th + 0.6)
			h = p.z - hem_v
			q = min(max(h / 0.09, 0.0), 1.0)
			m = 1.0 - q * q * (3 - 2 * q)
			if m <= 0.0:
				continue
			share = {}
			for c, a_ in angs.items():
				d = abs((th - a_ + math.pi) % (2 * math.pi) - math.pi)
				w = max(0.0, 1.0 - d / (math.pi / 3))
				if w > 0:
					share[c] = w
			tot = sum(share.values()) or 1.0
			t = min(max(1.0 - h / 0.09, 0.0), 1.0)  # 0 at the top of the strip, 1 at the edge
			ws = {names_s[g.group]: g.weight * (1 - m) for g in v.groups if g.weight > 0}
			for c, w in share.items():
				ws[f"{c}_1"] = ws.get(f"{c}_1", 0.0) + m * w / tot * (1.0 - t)
				ws[f"{c}_2"] = ws.get(f"{c}_2", 0.0) + m * w / tot * t
			for g in list(v.groups):
				shirt_o.vertex_groups[names_s[g.group]].remove([v.index])
			for n_, w in ws.items():
				if w <= 0:
					continue
				gg = shirt_o.vertex_groups.get(n_) or shirt_o.vertex_groups.new(name=n_)
				gg.add([v.index], w, "REPLACE")
				names_s[gg.index] = gg.name
		print("DWARF shirt hem on its springy strips:", len(CLOTH_CHAINS))
	# (F943) the hand's wrist piece up the forearm bends exactly like the forearm skin it lies on (the torso point
	# nearest each of its points), blended in over the first 2.5 cm above the wrist, so no gap opens when the hand turns
	for o in meshes:
		if not o.name.startswith("body_hand_"):
			continue
		side = o.name[len("body_hand_")]
		wr, el_ = B(f"hand_{side}"), B(f"lowerarm_{side}")
		up_arm = (el_ - wr).normalized()
		names_h = {vg.index: vg.name for vg in o.vertex_groups}
		n_copied = 0
		# (and it shades like the forearm skin too: its facing is the nearest torso point's, blended in the same way, so
		# no light-dark line shows where the two skins cross, Nov 28 render)
		to_h = o.matrix_world.to_3x3().inverted()
		t_rot = torso_o.matrix_world.to_3x3()
		nors = []
		for v in o.data.vertices:
			p = o.matrix_world @ v.co
			q = min(max((p - wr).dot(up_arm) / 0.025, 0.0), 1.0)
			m = q * q * (3 - 2 * q)
			nt = Vector((0.0, 0.0, 0.0))
			for _c, i_, d_ in tkd.find_n(p, 8):  # (the nearest few, or the coarse torso's facings show as blotches)
				nt += tv[i_].normal / max(d_, 0.002)
			nt = to_h @ (t_rot @ nt.normalized())
			nors.append(tuple(v.normal.lerp(nt, m).normalized()))
		o.data.normals_split_custom_set_from_vertices(nors)
		for v in o.data.vertices:
			p = o.matrix_world @ v.co
			q = min(max((p - wr).dot(up_arm) / 0.025, 0.0), 1.0)
			m = q * q * (3 - 2 * q)
			if m <= 0.0:
				continue
			ws = {names_h[g.group]: g.weight * (1 - m) for g in v.groups if g.weight > 0}
			for g in tv[tkd.find(p)[1]].groups:
				if g.weight > 0:
					ws[tnames[g.group]] = ws.get(tnames[g.group], 0.0) + g.weight * m
			for g in list(v.groups):
				o.vertex_groups[names_h[g.group]].remove([v.index])
			for n_, w in ws.items():
				gg = o.vertex_groups.get(n_) or o.vertex_groups.new(name=n_)
				gg.add([v.index], w, "REPLACE")
				names_h[gg.index] = gg.name
			n_copied += 1
		print("DWARF wrist piece follows the forearm:", o.name, n_copied)
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
	for tag, loc, aim in (("front", Vector((0, -4, 0.6)), 0.6), ("side", Vector((-4, 0, 0.6)), 0.6), ("back", Vector((0, 4, 0.6)), 0.6),
			("under", Vector((0.0, -2.2, -3.4)), 0.35)):  # (from below and in front: the crotch, owner Nov 18)
		cam.location = loc
		cam.rotation_euler = (Vector((0, 0, aim)) - loc).to_track_quat("-Z", "Y").to_euler()
		path = str(Path(BODYREV).with_name(Path(BODYREV).stem + f"_{tag}.png"))
		scene.render.filepath = path
		bpy.ops.render.render(write_still=True)
		shots.append(path)
	# close-ups (F943): the collar from above the shoulder, a wrist and a foot
	wr_w = arm.matrix_world @ arm.pose.bones["hand_l"].head
	ft_w = arm.matrix_world @ arm.pose.bones["foot_l"].head
	for tag, aim, off, scale in (("neck", Vector((0, 0.0, 0.93)), Vector((1.4, -3.0, 2.4)), 0.5),
			("wrist", wr_w, Vector((-1.0, -3.0, 0.4)), 0.26), ("foot", ft_w + Vector((0, -0.08, 0)), Vector((-1.6, -3.0, 1.6)), 0.3)):
		cam.data.ortho_scale = scale
		cam.location = aim + off
		cam.rotation_euler = (aim - cam.location).to_track_quat("-Z", "Y").to_euler()
		path = str(Path(BODYREV).with_name(Path(BODYREV).stem + f"_{tag}.png"))
		scene.render.filepath = path
		bpy.ops.render.render(write_still=True)
		shots.append(path)
	cam.data.ortho_scale = 1.32
	print("BODY_REVIEW", shots)
	if FAST and not FAST_GLB:
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
