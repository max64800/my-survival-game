# The dungeon ghosts' bodies, hand-built round the dwarf's own skeleton (Claude, Nov 22, 2026; MODEL-RULES Rule 1).
#
#   blender --background --factory-startup --python tools/asset_forge/builds/ghost_body.py -- <a|b|c> <out.glb> [review=<pic.png>]
#
# Owner, Nov 22: a ghost that moves with the dwarf's skeleton and his mace moves (not the pack skeleton's moves).
# Reference: docs/art/creatures/ghost_concepts_v1.png (three ChatGPT pictures; the owner: "you do one, you copy, and
# then you adjust some details"). One body, three small changes:
#   a  (left picture)   a round hood, calm and plain.
#   b  (middle picture) a tall pointed hood and a short shoulder cape: the angry one.
#   c  (right picture)  a misty beard out of the hood and a ragged hem with hanging tatters (the boss wears this one too).
#
# The shape: a loose hood with a dark hollow for the face and two glowing eyes in it, broad shoulders, thick sleeves,
# chunky fists, and no legs: the robe narrows into a misty tail that curls back behind it (no feet, so no sliding feet,
# F577). It is sculpted as one clay shape on a grid (like the armor), with a little hand-made wobble.
#
# How it moves: the dwarf's body (assets/characters/dwarf/dwarf_body.glb) is loaded for its skeleton and its rest pose
# (arms out). Every ghost point copies the bones of the body point nearest to it (sleeves bend with his arms, the chest
# with his spine), the hood follows his head, the fists his hands, and the tail only his hips (his legs still walk under
# it in the game, hidden; the tail must not kick along). The game wears it like the armor (Ghost.build_model).
#
# Colours are only a guide here: the game paints it with its ghost shader (src/art/ghost.gdshader). The points carry a
# colour the shader reads: red = how lit (the face hollow is dark), green = how far down the misty tail (fades out).
import math
import random
import sys
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector, kdtree

HERE = Path(__file__).resolve()
sys.path.insert(0, str(HERE.parents[1]))
sys.path.insert(0, str(HERE.parent))
import creature_kit as ck  # noqa: E402
import creature_sculpt as cs  # noqa: E402
import dwarf_head as dh  # noqa: E402
import kit  # noqa: E402

ROOT = HERE.parents[3]
ARGS = sys.argv[sys.argv.index("--") + 1:]
LOOK, OUT = ARGS[0], ARGS[1]
REVIEW = next((a[7:] for a in ARGS[2:] if a.startswith("review=")), None)
BODY = ROOT / "assets" / "characters" / "dwarf" / "dwarf_body.glb"
NAME = "ghost_" + LOOK  # ghost_a, ghost_b, ghost_c
R = random.Random({"a": 11, "b": 12, "c": 13}[LOOK])

# ---------------------------------------------------------------- the dwarf's skeleton (Blender: x = his left, -y = front, z up)
ck.reset()
for o in list(bpy.data.objects):
	bpy.data.objects.remove(o, do_unlink=True)
bpy.ops.import_scene.gltf(filepath=str(BODY))
ARM = next(o for o in bpy.context.scene.objects if o.type == "ARMATURE")
BODYM = {o.name: o for o in bpy.context.scene.objects if o.type == "MESH" and o.name.startswith("body_")}
for o in [o for o in bpy.context.scene.objects if o.type == "MESH" and not o.name.startswith("body_")]:
	bpy.data.objects.remove(o, do_unlink=True)


def world_verts(o):
	co = np.empty(len(o.data.vertices) * 3)
	o.data.vertices.foreach_get("co", co)
	co = co.reshape(-1, 3)
	m = np.array(o.matrix_world)
	return co @ m[:3, :3].T + m[:3, 3]


# ---------------------------------------------------------------- clay on a grid (distances: negative inside)
H = 0.009
LO = np.array((-0.97, -0.5, 0.0))
HI = np.array((0.97, 0.62, 1.5))
N = np.ceil((HI - LO) / H).astype(int) + 1
AX = [(LO[i] + H * np.arange(N[i])).astype(np.float32) for i in range(3)]
X, Y, Z = np.meshgrid(*AX, indexing="ij")


def smin(a, b, k):
	return dh._smin(a, b, k)


def smax(a, b, k):
	return -dh._smin(-a, -b, k)


def ell(c, r):
	"""A squashed ball (close enough to a true distance near its surface)."""
	x, y, z = (X - c[0]) / r[0], (Y - c[1]) / r[1], (Z - c[2]) / r[2]
	return (np.sqrt(x * x + y * y + z * z) - 1.0) * min(r)


def tube(a, b, r0, r1, sx=1.0):
	"""A tapered rod from a to b (radius r0 to r1); sx > 1 makes it wider side to side."""
	a, b = np.array(a, np.float32), np.array(b, np.float32)
	ba = b - a
	px, py, pz = (X - a[0]) / sx, Y - a[1], Z - a[2]
	bx = ba[0] / sx
	t = np.clip((px * bx + py * ba[1] + pz * ba[2]) / float(bx * bx + ba[1] ** 2 + ba[2] ** 2), 0.0, 1.0)
	d = np.sqrt((px - bx * t) ** 2 + (py - ba[1] * t) ** 2 + (pz - ba[2] * t) ** 2)
	return d - (r0 + (r1 - r0) * t)


def wobble(amp, seed):
	"""A hand-made unevenness (a few slow waves): no part is perfectly even."""
	r = random.Random(seed)
	w = np.zeros_like(X)
	for _ in range(4):
		k = [r.uniform(8, 20) for _ in range(3)]
		ph = [r.uniform(0, 6.3) for _ in range(3)]
		w += np.sin(k[0] * X + ph[0]) * np.sin(k[1] * Y + ph[1]) * np.sin(k[2] * Z + ph[2])
	return (amp / 2.0) * w


def to_mesh(name, D, mat, min_island=40):
	D = D.copy()
	for ax in range(3):  # closed off where it reaches the grid's edge
		sl = [slice(None)] * 3
		for end in (0, -1):
			sl[ax] = end
			D[tuple(sl)] = np.maximum(D[tuple(sl)], H)
	v, q = dh.surface_nets(D, LO, H)
	o = kit._mesh_obj(name, v.tolist(), q.tolist(), mat)
	ck._fix_normals(o)
	small = [i for isl in cs.islands(o) if len(isl) < min_island for i in isl]
	if small:
		bm = bmesh.new()
		bm.from_mesh(o.data)
		bm.verts.ensure_lookup_table()
		bmesh.ops.delete(bm, geom=[bm.verts[i] for i in small], context="VERTS")
		bm.to_mesh(o.data)
		bm.free()
	return o


HEAD_C = (0.0, 0.04, 1.06)   # the hood's middle (his head is inside it)
FACE_C = (0.0, -0.235, 1.03)  # the hollow where his face would be
SHOULDER_Z = 0.78
HAND_X = 0.66  # where his sleeves end (wrist)

# The hood: a big soft egg round his head, the face hollow cut into its front.
hood = ell(HEAD_C, (0.265, 0.285, 0.25))
if LOOK == "b":  # a tall pointed hood, leaning forward a little (the angry one)
	hood = smin(hood, tube((0, 0.05, 1.18), (0, 0.10, 1.43), 0.15, 0.018), 0.06)
else:  # a soft fold hanging down the back of the hood
	hood = smin(hood, tube((0, 0.12, 1.16), (0, 0.27, 1.08), 0.11, 0.03), 0.05)
hood = smin(hood, ell((0, 0.04, 0.86), (0.25, 0.25, 0.11)), 0.06)  # it falls onto the shoulders
face = ell(FACE_C, (0.155, 0.15, 0.165))
hood = smax(hood, -face, 0.025)

# The chest and the broad shoulders: a chunky barrel, wider than the dwarf.
chest = ell((0, 0.03, 0.66), (0.34, 0.26, 0.22))
for s in (-1, 1):
	chest = smin(chest, ell((s * 0.29, 0.035, SHOULDER_Z), (0.16, 0.15, 0.14)), 0.06)
if LOOK == "b":  # a short shoulder cape
	chest = smin(chest, ell((0, 0.04, 0.80), (0.46, 0.33, 0.085)), 0.04)
body = smin(hood, chest, 0.07)

# The sleeves: thick, a little flared at the wrist.
for s in (-1, 1):
	sl = tube((s * 0.3, 0.035, SHOULDER_Z), (s * (HAND_X - 0.04), 0.035, 0.778), 0.12, 0.098)
	sl = smin(sl, tube((s * (HAND_X - 0.1), 0.035, 0.778), (s * HAND_X, 0.035, 0.778), 0.1, 0.128), 0.03)
	body = smin(body, sl, 0.04)

# The misty tail: from the waist it narrows and curls back behind (no legs), a few twists of mist along it.
tail_pts = []
for i in range(13):
	t = i / 12.0
	tail_pts.append((0.03 * math.sin(t * 5.0), 0.03 + 0.48 * t ** 2.2, 0.50 - 0.46 * t ** 0.8 + 0.10 * t ** 4))
for i in range(12):
	r0 = 0.27 * (1.0 - i / 12.0) ** 1.25 + 0.01
	r1 = 0.27 * (1.0 - (i + 1) / 12.0) ** 1.25 + 0.01
	body = smin(body, tube(tail_pts[i], tail_pts[i + 1], r0, r1, sx=1.12), 0.05)
# twists of mist round the tail: shallow grooves winding down it
twist = np.sin(np.arctan2(X, Y - 0.1) * 3.0 + Z * 16.0)
body = body + np.where(Z < 0.5, 0.006 * twist * np.clip((0.5 - Z) / 0.15, 0, 1), 0.0)


def ring(c, axis, ra, rb, r):
	"""A ring (torus) round `axis` ("x", "y" or "z"): ra, rb its two radii across, r how thick."""
	p = {"x": (Y - c[1], Z - c[2], X - c[0]), "y": (X - c[0], Z - c[2], Y - c[1]), "z": (X - c[0], Y - c[1], Z - c[2])}[axis]
	q = (np.sqrt((p[0] / ra) ** 2 + (p[1] / rb) ** 2) - 1.0) * min(ra, rb)
	return np.sqrt(q * q + p[2] * p[2]) - r


def rbox(c, half, rr, turn=0.0):
	"""A box with soft corners, turned `turn` radians round the front-back line."""
	ct, st = math.cos(turn), math.sin(turn)
	lx, lz = (X - c[0]) * ct - (Z - c[2]) * st, (X - c[0]) * st + (Z - c[2]) * ct
	qx, qy, qz = np.abs(lx) - half[0], np.abs(Y - c[1]) - half[1], np.abs(lz) - half[2]
	out = np.sqrt(np.maximum(qx, 0) ** 2 + np.maximum(qy, 0) ** 2 + np.maximum(qz, 0) ** 2)
	return out + np.minimum(np.maximum(np.maximum(qx, qy), qz), 0.0) - rr


def at(D, p):
	i = np.clip(np.round((np.array(p) - LO) / H).astype(int), 0, N - 1)
	return float(D[tuple(i)])


def hit(D, start, d):
	"""Where a line from inside the clay (start, going d) comes out of it: for setting details right on the surface."""
	p, d = np.array(start, float), np.array(d, float)
	d /= np.linalg.norm(d)
	for _ in range(600):
		if at(D, p) >= 0.0:
			return tuple(p)
		p += d * H * 0.5
	return tuple(p)


def rope(D, pts, r0, r1, k=0.012):
	for i in range(len(pts) - 1):
		t0, t1 = i / (len(pts) - 1), (i + 1) / (len(pts) - 1)
		D = smin(D, tube(pts[i], pts[i + 1], r0 + (r1 - r0) * t0, r0 + (r1 - r0) * t1), k)
	return D


def tail_at(t):
	"""The tail's middle and its radius, t = 0 at the waist .. 1 at its tip."""
	i = min(int(t * 12), 11)
	f = t * 12 - i
	c = tuple(tail_pts[i][j] * (1 - f) + tail_pts[i + 1][j] * f for j in range(3))
	return c, 0.27 * (1.0 - t) ** 1.25 + 0.01


LANTERN = (0.2, -0.235, 0.355)  # the Drifting Shade's lantern at his left hip (its glass glows, in the eyes' mesh)
if LOOK == "a":
	# The Drifting Shade (owner, Nov 22: "way too simplistic... a lot more details"): an old miner's spirit in a hooded
	# robe with a short torn cowl, a rope belt with a knot, a little ghost lantern and a broken chain at his hips,
	# wide sleeves with ragged flaps, a patched robe, torn strips flowing down into the mist and wisps curling off the tail.
	# All one clay shape: nothing sits on top of anything else (no shimmer through the see-through body).
	ang = np.arctan2(X, Y - 0.035)
	# the cowl: a short cape round the shoulders, its lower edge wavy and torn upwards in three places
	# (a layer 2.5 cm thick laid over his shoulders and chest: it follows the body, ends on his upper arms)
	edge = 0.655 + 0.03 * np.cos(ang) + 0.014 * np.sin(ang * 9 + 0.5) + 0.008 * np.sin(ang * 4 + 2.0)
	for a0 in (0.9, -2.2, 2.7):
		edge = edge + 0.05 * np.exp(-((np.angle(np.exp(1j * (ang - a0)))) / 0.1) ** 2)
	cowl = smax(smax(body - 0.025, edge - Z, 0.006), np.abs(X) - 0.47 + 0.02 * np.sin(Z * 60), 0.01)
	cowl = smax(cowl, Z - 0.9, 0.03)  # (the hood itself stays as it is)
	body = smin(body, cowl, 0.006)
	# the hood's rolled rim round the face, a little uneven, and its long point drooping down his back
	rim = ring((0, -0.198, 1.035), "y", 0.168, 0.182, 0.029) + 0.004 * np.sin(np.arctan2(Z - 1.035, X) * 13)
	body = smin(body, rim, 0.012)
	body = rope(body, [(0, 0.2, 1.19), (0, 0.31, 1.1), (0.02, 0.35, 0.98), (0.05, 0.34, 0.9)], 0.085, 0.022, 0.03)
	# creases in the hood cloth: two soft grooves each side
	for s in (-1, 1):
		for d0, d1, d2 in (((0.35, -0.45, 0.8), (0.75, 0.0, 0.62), (0.7, 0.55, 0.1)),
				((0.5, -0.6, 0.35), (0.9, -0.05, 0.1), (0.75, 0.5, -0.35))):
			pts = []
			for d in (d0, d1, d2):
				n = np.array((s * d[0], d[1], d[2])) / np.linalg.norm(d)
				pts.append(tuple(np.array(hit(body, HEAD_C, n)) + n * 0.022))  # (a wide shallow dip: 8 mm deep)
			for i in range(2):
				body = smax(body, -tube(pts[i], pts[i + 1], 0.03, 0.03), 0.02)
	# the robe wrapped across his chest: one raised fold from his right shoulder down to the belt
	f0 = hit(body, (-0.1, 0.03, 0.69), (0.0, -1, 0.0))
	f1 = hit(body, (0.05, 0.03, 0.6), (0.0, -1, 0.0))
	f2 = hit(body, (0.11, 0.03, 0.52), (0.0, -1, 0.0))
	body = rope(body, [f0, f1, f2], 0.017, 0.015, 0.01)
	# two sewn-on patches: on his chest and on his back
	for start, d, half in (((0.05, 0.03, 0.41), (0, -1, 0), (0.042, 0.03, 0.036)), ((0.1, 0.03, 0.64), (0, 1, 0), (0.065, 0.03, 0.055))):
		p = np.array(hit(body, start, d)) - np.array(d) * 0.024
		body = smin(body, rbox(tuple(p), half, 0.008, 0.18) + wobble(0.007, 5), 0.006)  # (sewn on a little crooked)
	# the rope belt: twisted, round his waist, a knot at the front and two frayed ends hanging down
	bz = 0.505
	belt = ring((0, 0.03, bz), "z", 0.312, 0.288, 0.03)
	theta = np.arctan2(Y - 0.03, X)
	plane = np.sqrt((X / 0.312) ** 2 + ((Y - 0.03) / 0.288) ** 2) * 0.3 - 0.3
	belt = belt + 0.006 * np.sin(theta * 34 + np.arctan2(Z - bz, plane) * 2)
	belt = smin(belt, ell((-0.09, -0.262, 0.5), (0.05, 0.036, 0.042)), 0.012)
	for end, sway in (((-0.06, -0.285, 0.33), 0.0), ((-0.13, -0.275, 0.37), 0.02)):
		belt = rope(belt, [(-0.09, -0.27, 0.48), ((end[0] - 0.09) / 2 + sway, end[1] - 0.01, (end[2] + 0.48) / 2), end], 0.022, 0.017, 0.008)
		for fx in (-0.009, 0.0, 0.009):  # the frayed end
			belt = smin(belt, tube(end, (end[0] + fx, end[1] - 0.004 * (fx != 0), end[2] - 0.05 + abs(fx)), 0.012, 0.008), 0.006)
	body = smin(body, belt, 0.012)
	# the lantern hanging from the belt at his left hip: a ring, a cap, four posts and a foot (the glass is in the eyes)
	lx, ly, lz = LANTERN
	lan = ring((lx, ly + 0.02, 0.475), "x", 0.026, 0.034, 0.011)
	lan = smin(lan, ell((lx, ly, lz + 0.066), (0.05, 0.05, 0.02)), 0.008)
	lan = smin(lan, tube((lx, ly, lz + 0.08), (lx, ly, lz + 0.105), 0.022, 0.008), 0.008)
	lan = smin(lan, ell((lx, ly, lz - 0.064), (0.048, 0.048, 0.017)), 0.008)
	for px in (-0.034, 0.034):
		for py in (-0.034, 0.034):
			lan = smin(lan, tube((lx + px, ly + py, lz - 0.065), (lx + px, ly + py, lz + 0.066), 0.011, 0.011), 0.006)
	body = smin(body, lan, 0.008)
	# a broken chain hanging from the belt at his right hip, round links each turned a quarter, the last one snapped
	cx, cy = -0.262, 0.15
	ctop = 0.5
	for k in range(5):
		cz = ctop - 0.03 - k * 0.04
		link = ring((cx, cy, cz), "y" if k % 2 == 0 else "x", 0.024, 0.033, 0.0115)
		if k == 4:
			link = smax(link, -ell((cx, cy, cz - 0.03), (0.03, 0.03, 0.014)), 0.004)
		body = smin(body, link, 0.004)
	# the sleeves: a band at the cuff, the cuff opened up (the fist sits in it, 1.5 cm clear), a ragged flap hanging down
	for s in (-1, 1):
		body = smin(body, ring((s * (HAND_X - 0.035), 0.035, 0.778), "x", 0.122, 0.122, 0.02), 0.01)
		body = smax(body, -tube((s * (HAND_X - 0.09), 0.035, 0.778), (s * (HAND_X + 0.06), 0.035, 0.778), 0.095, 0.095), 0.01)
		for x0, x1, zb in ((0.44, 0.5, 0.6), (0.53, 0.6, 0.63)):
			body = rope(body, [(s * x0, 0.05, 0.71), (s * (x0 + x1) / 2, 0.06, (0.71 + zb) / 2 - 0.01), (s * x1, 0.075, zb)], 0.06, 0.02, 0.03)
	# deeper folds hanging in the robe below the belt
	body = body + np.where(Z < 0.48, 0.011 * np.sin(ang * 7 + 0.7) * np.clip((0.48 - Z) / 0.08, 0, 1) * np.clip((Z - 0.12) / 0.12, 0, 1), 0.0)
	# torn strips of robe flowing down the tail, their tips lifting off it into the mist
	for k in range(7):
		a = k / 7.0 * math.tau + 0.35 + R.uniform(-0.15, 0.15)
		t_end = R.uniform(0.55, 0.8)
		pts = []
		for j in range(6):
			t = 0.04 + (t_end - 0.04) * j / 5
			c, rt = tail_at(t)
			off = rt + 0.01 + 0.08 * (j / 5) ** 2
			pts.append((c[0] + math.sin(a) * 1.12 * off, c[1] + math.cos(a) * off, c[2]))
		body = rope(body, pts, 0.036, 0.014, 0.014)
	# wisps of mist curling off the tail's tip
	tip, _ = tail_at(0.97)
	for k, ph in enumerate((0.0, 2.1, 4.2)):
		pts = [tip]
		for j in range(1, 8):
			u = j / 7
			pts.append((tip[0] + 0.12 * u * math.sin(u * 4.5 + ph), tip[1] + 0.03 + 0.12 * u + 0.05 * math.cos(u * 4.5 + ph),
				tip[2] + 0.14 * u + 0.025 * k))
		body = rope(body, pts, 0.03, 0.013, 0.012)
	body = smax(body, -face, 0.02)  # (the face hollow stays open)

if LOOK == "c":
	# A misty beard flowing out of the hood, down over the chest.
	beard = tube((0, -0.17, 0.92), (0, -0.25, 0.66), 0.10, 0.045, sx=1.7)
	beard = smin(beard, tube((0, -0.25, 0.66), (0, -0.23, 0.55), 0.045, 0.015, sx=1.4), 0.03)
	beard = beard + 0.006 * np.sin(X * 90.0 + Z * 12.0)  # combed strands
	body = smin(body, beard, 0.035)
	# Ragged tatters hanging from the waist and the wrists, and notches torn out of the robe's edge.
	for k in range(8):
		a = k / 8.0 * math.tau + R.uniform(-0.2, 0.2)
		top = (math.sin(a) * 0.31, 0.03 + math.cos(a) * 0.25, 0.47)
		bot = (math.sin(a) * 0.33, 0.05 + math.cos(a) * 0.27, 0.47 - R.uniform(0.13, 0.2))
		body = smin(body, tube(top, bot, 0.06, 0.028, sx=1.0), 0.04)
	for s in (-1, 1):
		for dz in (0.0, 0.05):
			body = smin(body, tube((s * (HAND_X - 0.04), 0.06 + dz, 0.70), (s * (HAND_X - 0.06), 0.08 + dz, 0.61), 0.04, 0.02), 0.025)

body = body + wobble(0.007, R.randint(0, 999))
MAT_BODY = ck.color(NAME + "_body", (0.55, 0.85, 0.8) if LOOK != "b" else (0.6, 0.75, 0.95))
o_body = to_mesh(NAME + "_body", body, MAT_BODY)

# The eyes: two glowing lumps set into the back of the face hollow (they sink into the hood: they touch it).
eyes = np.minimum(ell((-0.062, -0.087 - 0.0, 1.045), (0.034, 0.02, 0.022)), ell((0.062, -0.087, 1.045), (0.034, 0.02, 0.022)))
if LOOK == "b":  # angry: slanted, narrower
	eyes = np.minimum(ell((-0.062, -0.087, 1.04), (0.036, 0.02, 0.016)), ell((0.062, -0.087, 1.04), (0.036, 0.02, 0.016)))
if LOOK == "a":  # the lantern's glass: it touches the cap and the foot, inside the four posts (clear of them)
	eyes = np.minimum(eyes, ell(LANTERN, (0.026, 0.026, 0.056)))
o_eyes = to_mesh(NAME + "_eyes", eyes, ck.color(NAME + "_eyes", (1.0, 1.0, 0.85)), min_island=8)

# The fists: chunky, closed (the mace handle goes through the right one), a ridge of knuckles on top.
fists = None
for s in (-1, 1):
	f = ell((s * (HAND_X + 0.08), 0.005, 0.766), (0.09, 0.085, 0.078))
	f = smin(f, tube((s * (HAND_X + 0.04), -0.06, 0.80), (s * (HAND_X + 0.12), -0.06, 0.80), 0.03, 0.028), 0.03)
	f = smin(f, tube((s * (HAND_X + 0.02), 0.02, 0.775), (s * (HAND_X + 0.05), 0.02, 0.775), 0.075, 0.08), 0.02)  # wrist into the cuff
	if LOOK == "a":  # mittens wrapped in rags (no fingers): the wrist reaches into the opened cuff, 1.5 cm clear of it
		f = smin(f, tube((s * (HAND_X - 0.07), 0.03, 0.778), (s * (HAND_X + 0.03), 0.025, 0.776), 0.07, 0.075), 0.02)
		f = f + 0.005 * np.sin(np.arctan2(Z - 0.77, Y - 0.01) + X * s * 70.0)
	fists = f if fists is None else np.minimum(fists, f)
fists = fists + wobble(0.004, 77)
o_fists = to_mesh(NAME + "_fists", fists, ck.color(NAME + "_fists", (0.6, 0.9, 0.85)), min_island=8)

# ---------------------------------------------------------------- the shader's guide colours (red = lit, green = mist)
for o in (o_body, o_eyes, o_fists):
	co = world_verts(o)
	fx = (co[:, 0] - FACE_C[0]) / 0.155
	fy = (co[:, 1] - FACE_C[1]) / 0.15
	fz = (co[:, 2] - FACE_C[2]) / 0.165
	in_face = np.sqrt(fx * fx + fy * fy + fz * fz)
	lit = np.clip((in_face - 1.0) / 0.12, 0.0, 1.0) if o is o_body else np.ones(len(co))
	if LOOK == "a" and o is o_body:  # dark only behind the hood's rim (its rolled rim is lit)
		e = np.sqrt((co[:, 0] / 0.13) ** 2 + ((co[:, 2] - FACE_C[2]) / 0.145) ** 2)
		lit = np.maximum(np.clip((e - 1.0) / 0.15, 0.0, 1.0), np.clip((-0.2 - co[:, 1]) / 0.03, 0.0, 1.0))
	lit = 0.08 + 0.92 * lit
	mist = np.clip((0.5 - co[:, 2]) / 0.44, 0.0, 1.0) if o is o_body else np.zeros(len(co))
	if o is o_eyes:
		mist[:] = 0.0
	rgb = np.stack([lit, mist, np.full(len(co), 1.0 if o is o_eyes else 0.0)], 1)
	at = o.data.color_attributes.new("guide", "FLOAT_COLOR", "POINT")
	at.data.foreach_set("color", np.concatenate([rgb, np.ones((len(rgb), 1))], 1).ravel())
	o.data.color_attributes.active_color = at
	o.data.uv_layers.new(name="UVMap")
	for p in o.data.polygons:
		p.use_smooth = True
	# fewer faces: the game's light copy
	n = len(o.data.polygons)
	want = {o_body: 16000 if LOOK == "a" else 7000, o_eyes: 500, o_fists: 900}[o]
	if n > want:
		md = o.modifiers.new("fewer", "DECIMATE")
		md.ratio = want / n
		cs._apply_all(o)
	print("GHOST made", o.name, len(o.data.polygons), "faces", flush=True)

# ---------------------------------------------------------------- which bones move each point
SKIP = ("hair_", "cloth_")
LEGS = ("thigh_", "calf_", "foot_", "ball_")  # his legs: their pull goes to the hips (the tail must not walk)
FINGERS = ("thumb_", "index_", "middle_", "ring_", "pinky_")  # the cuffs follow the wrist, not the fingers
pts, ws = [], []
for n in ("body_torso", "body_shirt", "body_hand_l", "body_hand_r"):
	ob = BODYM[n]
	gn = {vg.index: vg.name for vg in ob.vertex_groups}
	for v, p in zip(ob.data.vertices, world_verts(ob)):
		w = {}
		for g in v.groups:
			k = gn[g.group]
			if g.weight <= 0.0 or k.startswith(SKIP):
				continue
			if k.startswith(LEGS):
				k = "pelvis"
			elif k.startswith(FINGERS):
				k = "hand_" + k[-1]
			w[k] = w.get(k, 0.0) + g.weight
		if w:
			pts.append(p)
			ws.append(w)
KD = kdtree.KDTree(len(pts))
for i, p in enumerate(pts):
	KD.insert(Vector(p), i)
KD.balance()


def mix(a, b, t):
	out = {k: v * (1.0 - t) for k, v in a.items()}
	for k, v in b.items():
		out[k] = out.get(k, 0.0) + v * t
	return out


def weights_for(o, p):
	x, y, z = p
	if o is o_eyes:
		return {"Head": 1.0} if z > 0.8 else {"pelvis": 1.0}  # (the lantern's glass hangs from the belt)
	if o is o_fists:
		return {"hand_l" if x > 0 else "hand_r": 1.0}
	near = ws[KD.find(Vector(p))[1]]
	dh_ = math.dist(p, HEAD_C)
	if (z > 0.9 and abs(x) < 0.32) or (LOOK == "c" and abs(x) < 0.16 and y < -0.12 and z > 0.5):  # the hood (and the beard) follow his head
		return {"Head": 1.0}
	if z > 0.83 and abs(x) < 0.27:  # hood falling onto the shoulders: half head, half spine
		return mix(near, {"Head": 1.0}, float(np.clip((z - 0.83) / 0.07, 0, 1)) * (1.0 if dh_ < 0.4 else 0.5))
	if z < 0.56 and abs(x) < 0.45:  # the tail: only the hips (his walking legs are hidden under it)
		t = float(np.clip((0.56 - z) / 0.1, 0, 1))
		return mix(near, {"pelvis": 1.0}, t)
	return near


for o in (o_body, o_eyes, o_fists):
	for vg in list(o.vertex_groups):
		o.vertex_groups.remove(vg)
	groups = {}
	for i, p in enumerate(world_verts(o)):
		w = weights_for(o, tuple(p))
		top = sorted(w.items(), key=lambda kv: -kv[1])[:4]
		tot = sum(v for _, v in top) or 1.0
		for name, v in top:
			if name not in groups:
				groups[name] = o.vertex_groups.new(name=name)
			groups[name].add([i], v / tot, "REPLACE")
	o.parent = ARM
	o.parent_type = "OBJECT"
	o.matrix_parent_inverse = ARM.matrix_world.inverted()
	o.modifiers.new("skeleton", "ARMATURE").object = ARM
print("GHOST weights copied from the body", flush=True)

# ---------------------------------------------------------------- photos: arms down like the game (review only)
if REVIEW:
	scene = bpy.context.scene
	for ob in scene.objects:
		ob.hide_render = ob not in (o_body, o_eyes, o_fists)
	for ob in (o_body, o_eyes, o_fists):
		m = ob.active_material
		bsdf = next((n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None) if m.use_nodes else None
		if bsdf:
			m.diffuse_color = tuple(bsdf.inputs["Base Color"].default_value)
	bpy.context.view_layer.objects.active = ARM
	bpy.ops.object.mode_set(mode="POSE")
	for side in ("l", "r"):
		pb = ARM.pose.bones[f"upperarm_{side}"]
		h = pb.head.copy()
		rot = Matrix.Translation(h) @ Matrix.Rotation(math.radians(60) * (1 if pb.head.x > 0 else -1), 4, "Y") @ Matrix.Translation(-h)
		pb.matrix = rot @ pb.matrix
	bpy.ops.object.mode_set(mode="OBJECT")
	bpy.context.view_layer.update()
	scene.render.engine = "BLENDER_WORKBENCH"
	scene.display.shading.light = "STUDIO"
	scene.display.shading.color_type = "MATERIAL"
	scene.render.resolution_x, scene.render.resolution_y = 520, 620
	cam = bpy.data.objects.new("rcam", bpy.data.cameras.new("rcam"))
	cam.data.type = "ORTHO"
	scene.collection.objects.link(cam)
	scene.camera = cam
	for tag, loc in (("front", (0, -4, 0.72)), ("side", (-4, 0, 0.72)), ("back", (2.8, 2.8, 0.9))):
		cam.location = Vector(loc)
		cam.data.ortho_scale = 1.65
		cam.rotation_euler = (Vector((0, 0, 0.72)) - cam.location).to_track_quat("-Z", "Y").to_euler()
		scene.render.filepath = str(Path(REVIEW).with_name(Path(REVIEW).stem + f"_{tag}.png"))
		bpy.ops.render.render(write_still=True)
	for pb in ARM.pose.bones:
		pb.matrix_basis = Matrix()
	bpy.context.view_layer.update()
	print("GHOST REVIEW", REVIEW, flush=True)

# ---------------------------------------------------------------- export: the skeleton and the ghost only
for ob in list(BODYM.values()):
	bpy.data.objects.remove(ob, do_unlink=True)
for ob in [ob for ob in bpy.data.objects if ob.type == "MESH" and ob not in (o_body, o_eyes, o_fists)]:
	bpy.data.objects.remove(ob, do_unlink=True)  # the importer's bone shapes
bpy.ops.object.select_all(action="DESELECT")
ARM.select_set(True)
for o in (o_body, o_eyes, o_fists):
	o.select_set(True)
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_yup=True, export_skins=True,
	export_animations=False, export_apply=False, export_vertex_color="ACTIVE")
print("GHOST_DONE", OUT, flush=True)
