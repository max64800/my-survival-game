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
if LOOK == "b":  # a tall pointed hood, its tip flopping forward (the angry one)
	hood = smin(hood, tube((0, 0.05, 1.18), (0, 0.10, 1.42), 0.15, 0.022), 0.06)
	hood = smin(hood, tube((0, 0.10, 1.41), (0, 0.05, 1.465), 0.022, 0.013), 0.015)
else:  # a soft fold hanging down the back of the hood
	hood = smin(hood, tube((0, 0.12, 1.16), (0, 0.27, 1.08), 0.11, 0.03), 0.05)
hood = smin(hood, ell((0, 0.04, 0.86), (0.25, 0.25, 0.11)), 0.06)  # it falls onto the shoulders
face = ell(FACE_C, (0.155, 0.15, 0.165))
TRI_TOP, TRI_BASE, TRI_W = 1.215, 0.925, 0.168  # the Drifting Shade's pointed face opening (owner, Nov 22: "a triangle hood")


def tri(x, z, grow=0.0):
	"""Distance (front view) to the Drifting Shade's face opening: a tall triangle, point up, its corners rounded
	and its bottom edge sagging a little. Negative inside."""
	a, b = TRI_TOP - TRI_BASE, TRI_W
	n = math.hypot(a, b)
	side = (a * (np.abs(x) - TRI_W) + b * (z - TRI_BASE)) / n
	bottom = TRI_BASE - 0.025 * (1 - (x / TRI_W) ** 2) - z
	return smax(side, bottom, 0.035) - grow


if LOOK == "a":  # a pocket behind the triangle, rounded at the back (the eyes sit on its back wall)
	face = smax(tri(X, Z), ell((0.0, -0.235, 1.05), (0.2, 0.15, 0.25)), 0.02)


def brow(x):
	"""The Wrathful Shade's frown: the top of his face opening dips to a V in the middle."""
	return 1.085 + 0.45 * np.abs(x)


if LOOK == "b":
	face = smax(face, Z - brow(X), 0.02)
hood_whole = hood  # (before the face is cut: the rim's line is laid on its surface)
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


def face_rim(D, top=None, r=0.026, out=0.012, grow=0.016):
	"""A rolled rim round the round face opening (the Wrathful and Bearded Shades), just outside its edge."""
	pts = []
	for i in range(41):
		t = -math.pi / 2 + i / 40.0 * math.tau
		x, z = (0.155 + grow) * math.cos(t), FACE_C[2] + (0.165 + grow) * math.sin(t)
		if top is not None:
			z = min(z, float(top(x)) + grow)
		pts.append((x, hit(hood_whole, (x, 0.04, z), (0, -1, 0))[1] + out, z))
	for i in range(40):
		D = smin(D, tube(pts[i], pts[i + 1], r + 0.004 * math.sin(i * 1.9), r + 0.004 * math.sin((i + 1) * 1.9)), 0.012)
	return D, pts


def patch(D, start, d, half, turn, seed):
	"""A sewn-on patch, a little crooked, big chunky stitches across its four edges (d: the way out of the cloth)."""
	p = np.array(hit(D, start, d)) - np.array(d) * 0.024
	D = smin(D, rbox(tuple(p), half, 0.008, turn) + wobble(0.007, seed), 0.006)
	ct, st = math.cos(turn), math.sin(turn)
	fy = p[1] + d[1] * 0.033
	for ex, ez, ax in ((1, 0, "x"), (-1, 0, "x"), (0, 1, "z"), (0, -1, "z")):
		for u in (-0.5, 0.5):
			lx = ex * half[0] if ax == "x" else u * half[0] * 1.2
			lz = ez * half[2] if ax == "z" else u * half[2] * 1.2
			c = np.array((p[0] + lx * ct + lz * st, fy, p[2] - lx * st + lz * ct))
			dd = np.array((ct, 0, -st)) if ax == "x" else np.array((st, 0, ct))
			D = smin(D, tube(tuple(c - dd * 0.014), tuple(c + dd * 0.014), 0.0065, 0.0065), 0.003)
	return D


def scratch_marks(D, spots, seed, claw, bad):
	"""Clean slashes with pointed ends, some alone, some in claw sets of three (painted pitch black by the guide).
	spots: (centre, x range, y range, z range) to aim from the centre; bad(p): a place to keep clear of."""
	rs = random.Random(seed)
	for c0, rx, ry, rz in spots:
		for _ in range(20):
			n = np.array((rs.uniform(*rx), rs.uniform(*ry), rs.uniform(*rz)))
			n /= np.linalg.norm(n)
			p0 = np.array(hit(D, tuple(c0), n))
			if bad(p0) or abs(p0[0]) > HAND_X - 0.06:
				continue
			break
		else:
			continue
		big = rs.random() < 0.4
		L = rs.uniform(0.11, 0.18) if big else rs.uniform(0.06, 0.1)
		r = 0.0085 if big else 0.007
		tdir = np.cross(n, (rs.uniform(-1, 1), rs.uniform(-1, 1), rs.uniform(-1, 1)))
		tdir /= np.linalg.norm(tdir)
		gap = np.cross(n, tdir)
		count = 3 if rs.random() < claw else 1
		for j in range(count):
			c = p0 + gap * (j - (count - 1) / 2) * 0.026
			c = np.array(hit(D, tuple(np.array(c0) + (c - np.array(c0)) * 0.7), c - np.array(c0)))
			Lj = L * (1.0 - 0.18 * abs(j - (count - 1) / 2))
			a, m, b = c - tdir * Lj + n * 0.004, c - n * 0.007, c + tdir * Lj + n * 0.004
			SCRATCH.append((a, m, b, r))
			D = smax(D, -tube(tuple(a), tuple(m), 0.003, r), 0.004)
			D = smax(D, -tube(tuple(m), tuple(b), r, 0.003), 0.004)
	return D


def lumpy(D, zmin):
	"""A fine hand-pressed unevenness in the cloth above zmin (finer than the whole body's wobble)."""
	rr = random.Random(44)
	lump = np.zeros_like(X)
	for _ in range(5):
		kk = [rr.uniform(32, 48) for _ in range(3)]
		ph = [rr.uniform(0, 6.3) for _ in range(3)]
		lump += np.sin(kk[0] * X + ph[0]) * np.sin(kk[1] * Y + ph[1]) * np.sin(kk[2] * Z + ph[2])
	return D + 0.0022 * lump * np.clip((Z - zmin) / 0.06, 0, 1)


def tail_strips(D, n, seed, r1):
	"""Torn strips of robe flowing down the tail, their tips lifting off it into the mist."""
	rr = random.Random(seed)
	for k in range(n):
		a = k / n * math.tau + 0.35 + rr.uniform(-0.15, 0.15)
		t_end = rr.uniform(0.55, 0.8)
		pts = []
		for j in range(6):
			t = 0.04 + (t_end - 0.04) * j / 5
			c, rt = tail_at(t)
			off = rt + 0.01 + 0.08 * (j / 5) ** 2
			pts.append((c[0] + math.sin(a) * 1.12 * off, c[1] + math.cos(a) * off, c[2]))
		D = rope(D, pts, 0.036, r1, 0.014)
	return D


def hood_seam(D, a0, a1, stitches=True):
	"""A raised seam over the top of the hood from front (a0, degrees up from straight ahead) to back, with cross-stitches."""
	seam = [tuple(np.array(hit(hood_whole, HEAD_C, (0, -math.cos(a), math.sin(a)))) - np.array((0, -math.cos(a), math.sin(a))) * 0.004)
		for a in np.linspace(math.radians(a0), math.radians(a1), 11)]
	D = rope(D, seam, 0.014, 0.012, 0.008)
	if stitches:
		for i in range(1, len(seam) - 1):
			c = np.array(seam[i])
			n = c - np.array(HEAD_C)
			n /= np.linalg.norm(n)
			D = smin(D, tube(tuple(c - np.array((0.022, 0, 0)) - n * 0.004), tuple(c + np.array((0.022, 0, 0)) - n * 0.004), 0.0065, 0.0065), 0.003)
	return D


def near_face(p, pad):
	"""Close to the round face opening (keep scratches and dents off the rim)."""
	return p[1] < -0.1 and ((p[0] / (0.155 + pad)) ** 2 + ((p[2] - FACE_C[2]) / (0.165 + pad)) ** 2) < 1.0


SCRATCH = []  # the Drifting Shade's scratch marks (a, middle, b, width): they glow a little (the guide's blue)
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
	# (it runs round the pointed opening, laid on the hood's cloth: a rope of points just outside the triangle's edge)
	corners = [(0.0, TRI_TOP + 0.01), (-TRI_W - 0.014, TRI_BASE - 0.012), (TRI_W + 0.014, TRI_BASE - 0.012)]
	outline = []
	for i in range(3):
		(x0, z0), (x1, z1) = corners[i], corners[(i + 1) % 3]
		for j in range(10):
			u = j / 10
			x, z = x0 + (x1 - x0) * u, z0 + (z1 - z0) * u
			if i == 1:  # (the bottom edge sags like the opening)
				z -= 0.025 * (1 - (x / TRI_W) ** 2)
			y = hit(hood_whole, (x, 0.04, z), (0, -1, 0))[1] + 0.012
			outline.append((x, y, z))
	outline.append(outline[0])
	for i in range(len(outline) - 1):
		r = 0.027 + 0.004 * math.sin(i * 1.9)
		body = smin(body, tube(outline[i], outline[i + 1], r, 0.027 + 0.004 * math.sin((i + 1) * 1.9)), 0.012)
	# a raised seam from the opening's point over the top of the hood and down its back
	seam = [tuple(np.array(hit(hood_whole, HEAD_C, (0, -math.cos(a), math.sin(a)))) - np.array((0, -math.cos(a), math.sin(a))) * 0.004)
		for a in np.linspace(math.radians(58), math.radians(170), 9)]
	body = rope(body, seam, 0.014, 0.012, 0.008)
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
	for start, d, half in (((0.05, 0.03, 0.41), (0, -1, 0), (0.042, 0.03, 0.036)), ((0.26, 0.03, 0.75), (0, 1, 0), (0.05, 0.03, 0.045))):
		p = np.array(hit(body, start, d)) - np.array(d) * 0.024
		body = smin(body, rbox(tuple(p), half, 0.008, 0.18) + wobble(0.007, 5), 0.006)  # (sewn on a little crooked)
		# big chunky stitches across its edges (on the cloth side: front patches face -y, back ones +y)
		ct, st = math.cos(0.18), math.sin(0.18)
		fy = p[1] + d[1] * 0.033
		for ex, ez, ax in ((1, 0, "x"), (-1, 0, "x"), (0, 1, "z"), (0, -1, "z")):
			for u in (-0.5, 0.5):
				lx = ex * half[0] if ax == "x" else u * half[0] * 1.2
				lz = ez * half[2] if ax == "z" else u * half[2] * 1.2
				c = np.array((p[0] + lx * ct + lz * st, fy, p[2] - lx * st + lz * ct))
				dd = np.array((ct, 0, -st)) if ax == "x" else np.array((st, 0, ct))
				body = smin(body, tube(tuple(c - dd * 0.014), tuple(c + dd * 0.014), 0.0065, 0.0065), 0.003)
	# his lucky stone: a little rune stone on a cord round his neck, hanging below the hood on his chest
	stone = np.array(hit(body, (0, 0.03, 0.75), (0, -1, 0))) + np.array((0, -0.012, 0))
	body = smin(body, rbox(tuple(stone), (0.028, 0.012, 0.034), 0.012, 0.12) + wobble(0.004, 9), 0.006)
	body = smax(body, -tube(tuple(stone + (-0.012, -0.026, 0.018)), tuple(stone + (0.01, -0.026, -0.02)), 0.0075, 0.0075), 0.003)  # its rune
	for s in (-1, 1):
		cord = [tuple(stone + (s * 0.012, 0.004, 0.044))]
		for x, z in ((0.04, 0.8), (0.075, 0.86)):
			cord.append(tuple(np.array(hit(body, (s * x, 0.03, z), (0, -1, 0))) + (0, -0.004, 0)))
		body = rope(body, cord, 0.0085, 0.0085, 0.006)
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
	# a leather pouch hanging from the belt behind his right hip: a fat bag, its flap folded over and a toggle on it
	out = np.array((-0.4, 0.92, 0.0)) / math.hypot(0.4, 0.92)
	pc = np.array((-0.13, 0.29, 0.44)) + out * 0.03
	body = smin(body, ell(tuple(pc), (0.062, 0.04, 0.058)) + wobble(0.005, 21), 0.012)
	flap = pc + out * 0.012 + (0, 0, 0.022)
	body = smin(body, smax(ell(tuple(flap), (0.066, 0.042, 0.045)), (0.012 + pc[2]) - Z, 0.008), 0.004)
	body = smin(body, ell(tuple(pc + out * 0.05 + (0, 0, 0.005)), (0.014, 0.012, 0.012)), 0.004)
	# his old pick tucked in the back of the belt, its head up on his back just under the cape's edge
	h0 = np.array(hit(body, (0.18, 0.03, 0.34), (0, 1, 0))) + (0, 0.014, 0)
	h1 = np.array(hit(body, (0.03, 0.03, 0.6), (0, 1, 0))) + (0, 0.02, 0)
	body = rope(body, [tuple(h0), tuple((h0 + h1) / 2 + (0, 0.004, 0)), tuple(h1)], 0.021, 0.019, 0.008)
	hd = h1 - h0
	hd /= np.linalg.norm(hd)
	across = np.array((hd[2], 0, -hd[0]))  # (across the handle, flat on his back)
	for s, ln in ((1, 0.15), (-1, 0.11)):  # a long point and a shorter one, both curving down a little
		mid = h1 + across * s * ln * 0.55 - hd * 0.012
		tip = h1 + across * s * ln - hd * 0.035
		mid[1] = hit(body, (mid[0], 0.03, mid[2]), (0, 1, 0))[1] + 0.016  # (both lie on his curved back)
		tip[1] = hit(body, (tip[0], 0.03, tip[2]), (0, 1, 0))[1] + 0.004
		body = rope(body, [tuple(h1 + hd * 0.006), tuple(mid), tuple(tip)], 0.03, 0.009, 0.006)
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
	# worn cloth (owner, Nov 22: "more dents and stuff, like the mace"): the hood and the cape are old and knocked about.
	# Long folds running down the cape from the shoulders to its torn edge: soft grooves laid on its surface.
	for k in range(14):
		a = k / 14.0 * math.tau + R.uniform(-0.12, 0.12)
		d = np.array((math.sin(a), math.cos(a), 0.0))
		pts = []
		for z in (0.84, 0.76, 0.68):
			pts.append(tuple(np.array(hit(body, (0.0, 0.035, z), d)) + d * 0.013))
		r = R.uniform(0.013, 0.019)
		for i in range(2):
			body = smax(body, -tube(pts[i], pts[i + 1], r * 0.6, r), 0.01)
	# more creases fanning back from the hood opening's corners and point over the cloth
	for (sx, sz), fan in (((1, -1), (0.2, 0.55, 0.9)), ((-1, -1), (0.2, 0.55, 0.9)), ((0, 1), (-0.5, 0.5))):
		for f in fan:
			pts = []
			for u in (0.0, 0.5, 1.0):
				if sx == 0:  # (from the point: back over the top, fanning out a little)
					n = np.array((f * u * 0.5, -0.6 + 1.1 * u, 0.8 + 0.2 * u))
				else:  # (from a bottom corner: back round the side of the head)
					n = np.array((sx * (0.55 + 0.4 * u), -0.75 + 0.95 * u, -0.05 + f * 0.6 * u))
				n /= np.linalg.norm(n)
				pts.append(tuple(np.array(hit(hood_whole, HEAD_C, n)) + n * 0.016))
			for i in range(2):
				body = smax(body, -tube(pts[i], pts[i + 1], 0.012, 0.018), 0.012)
	# dents and dings knocked into the hood and the cape, a few big, most small
	for k in range(70):
		if k < 30:  # the hood
			c0 = np.array(HEAD_C)
			n = np.array((R.uniform(-1, 1), R.uniform(-0.2, 1), R.uniform(-0.3, 1)))
		else:  # the cape round his shoulders
			c0 = np.array((0.0, 0.035, R.uniform(0.7, 0.8)))
			n = np.array((R.uniform(-1, 1), R.uniform(-1, 1), R.uniform(-0.1, 0.5)))
		n /= np.linalg.norm(n)
		p = np.array(hit(body, tuple(c0), n))
		if tri(p[0], p[2], 0.05) < 0 and p[1] < -0.1:
			continue  # (none on the rim round his face)
		r = R.uniform(0.016, 0.03) if k % 5 else R.uniform(0.035, 0.045)
		body = smax(body, -ell(tuple(p + n * r * 0.78), (r * 1.15, r * 1.15, r * 0.85)), 0.01)  # (shallow: dings, not holes)
	# a fine lumpy hand-pressed unevenness in the cloth (finer than the whole body's wobble)
	rr = random.Random(44)
	lump = np.zeros_like(X)
	for _ in range(5):
		kk = [rr.uniform(32, 48) for _ in range(3)]
		ph = [rr.uniform(0, 6.3) for _ in range(3)]
		lump += np.sin(kk[0] * X + ph[0]) * np.sin(kk[1] * Y + ph[1]) * np.sin(kk[2] * Z + ph[2])
	body = body + 0.0022 * lump * np.clip((Z - 0.6) / 0.06, 0, 1)
	# loose threads hanging from the cape's three tears
	for a0 in (0.9, -2.2, 2.7):
		for j, da in enumerate((-0.05, 0.04)):
			a = a0 + da
			d = np.array((math.sin(a), math.cos(a), 0.0))
			top = np.array(hit(body, (0.0, 0.035, 0.72), d)) - d * 0.006
			low = top + d * 0.012 + (0.0, 0.0, -0.05 - 0.02 * j)
			body = rope(body, [tuple(top), tuple(top + d * 0.01 + (0, 0, -0.025)), tuple(low)], 0.0085, 0.006, 0.004)
	# chunky cross-stitches along the seam over the hood
	for i in range(1, len(seam) - 1, 1):
		c = np.array(seam[i])
		n = c - np.array(HEAD_C)
		n /= np.linalg.norm(n)
		body = smin(body, tube(tuple(c - np.array((0.022, 0, 0)) - n * 0.004), tuple(c + np.array((0.022, 0, 0)) - n * 0.004), 0.0065, 0.0065), 0.003)
	# Made-by-hand details, not more damage (owner, Nov 22: the deep dents made him look "like a crunched soda can"):
	# tidy things a dwarf sewed and wrapped, like the mace's careful bands and studs.
	def edge_at(a):
		e = 0.655 + 0.03 * math.cos(a) + 0.014 * math.sin(a * 9 + 0.5) + 0.008 * math.sin(a * 4 + 2.0)
		for a0 in (0.9, -2.2, 2.7):
			e += 0.05 * math.exp(-((math.atan2(math.sin(a - a0), math.cos(a - a0))) / 0.1) ** 2)
		return e
	def on_cape(a, dz):
		d = np.array((math.sin(a), math.cos(a), 0.0))
		return np.array(hit(body, (0.0, 0.035, edge_at(a) + dz), d)), d
	# a rolled hem along the cape's lower edge (not over the torn bits), with running stitches across it
	tears = (0.9, -2.2, 2.7)
	hem = None
	run = []
	for i in range(73):
		a = -math.pi + i / 72.0 * math.tau
		sp = tuple(np.sin(np.array([a - t for t in tears])))
		torn = min(abs(math.atan2(math.sin(a - t), math.cos(a - t))) for t in tears) < 0.16
		if torn or abs(math.sin(a)) > 0.93:  # (gaps at the tears and where the sleeves come out)
			if len(run) > 1:
				body = rope(body, run, 0.011, 0.011, 0.005)
			run = []
			continue
		p0, d = on_cape(a, 0.016)
		run.append(tuple(p0 - d * 0.003))
		if i % 3 == 0:
			body = smin(body, tube(tuple(p0 + (0, 0, -0.016) + d * 0.006), tuple(p0 + (0, 0, 0.016) + d * 0.006), 0.0055, 0.0055), 0.003)
	if len(run) > 1:
		body = rope(body, run, 0.011, 0.011, 0.005)
	# a band of little stitched runes above the hem, front and back (simple marks, each two or three strokes)
	glyphs = (((0, -1), (0, 1)), ((0, -1), (0, 1), (0, 0.2), (0.8, 0.8)), ((-0.6, -1), (0, 1), (0.6, -1)),
		((0, -1), (0, 1), (0, 1), (0.7, 0.3)), ((-0.6, 1), (0.6, -1), (-0.6, -1), (0.6, 1)))
	for k in range(16):
		a = -math.pi + (k + 0.5) / 16.0 * math.tau
		if abs(math.sin(a)) > 0.85 or min(abs(math.atan2(math.sin(a - t), math.cos(a - t))) for t in tears) < 0.25:
			continue
		c, d = on_cape(a, 0.058)
		side = np.array((math.cos(a), -math.sin(a), 0.0))
		g = glyphs[k % len(glyphs)]
		for j in range(0, len(g) - 1, 2 if len(g) % 2 == 0 else 1):
			u, v = g[j], g[j + 1]
			pa = c + side * u[0] * 0.02 + np.array((0, 0, u[1] * 0.026)) + d * 0.003
			pb = c + side * v[0] * 0.02 + np.array((0, 0, v[1] * 0.026)) + d * 0.003
			body = smin(body, tube(tuple(pa), tuple(pb), 0.0085, 0.0085), 0.003)
	# cloth strips wrapped round each forearm: a flat band spiralling three times, its two ends tucked
	for s in (-1, 1):
		pts = []
		for i in range(37):
			u = i / 36.0
			x = s * (0.43 + 0.15 * u)
			ph = u * 3 * math.tau
			rr = 0.112 - 0.004 * u
			pts.append((x, 0.035 + rr * math.cos(ph), 0.778 + rr * math.sin(ph)))
		pts = [tuple(np.array(hit(body, (q[0], 0.035, 0.778), (0, q[1] - 0.035, q[2] - 0.778))) + np.array((0, q[1] - 0.035, q[2] - 0.778)) / 0.11 * 0.003) for q in pts]
		body = rope(body, pts, 0.017, 0.017, 0.004)
	# round studs hammered into the rope belt at the back and sides
	for k in range(9):
		a = math.pi * (0.25 + 0.5 * k / 8.0) * 2 - math.pi * 0.5
		d = np.array((math.sin(a), math.cos(a), 0.0))
		p0 = np.array(hit(body, (0.0, 0.03, bz), d))
		body = smin(body, ell(tuple(p0 + d * 0.006), (0.019, 0.019, 0.019)), 0.004)
	# scratch marks, big and small, all round him (owner, Nov 22): clean slashes with pointed ends, some alone and some in
	# claw-like sets of three, smooth cloth left between them (not dents everywhere: that was the "crunched soda can")
	rs = random.Random(91)
	SCRATCH.clear()
	# (owner, 2nd look: most of them on his front, the side you face: -y is his front)
	spots = [(HEAD_C, (-1, 1), (-1, -0.25), (-0.1, 1))] * 8 + [(HEAD_C, (-1, 1), (-0.2, 1), (-0.1, 1))] * 2 \
		+ [((0.0, 0.035, 0.7), (-1, 1), (-1, -0.2), (-0.2, 0.6))] * 11 + [((0.0, 0.035, 0.7), (-1, 1), (0.2, 1), (-0.2, 0.6))] * 3 \
		+ [((0.0, 0.05, 0.42), (-1, 1), (-1, -0.2), (-0.3, 0.2))] * 9 + [((0.0, 0.05, 0.42), (-1, 1), (0.2, 1), (-0.3, 0.2))] * 2
	for s0 in (-1, 1):
		spots += [((s0 * 0.48, 0.035, 0.778), (-0.15, 0.15), (-1, 0.3), (-1, 1))] * 3
	# (owner, 3rd look: more on the shoulders, the arms and low down; added last, so the first ones stay where they were)
	for s0 in (-1, 1):
		sx = (0.3, 1) if s0 > 0 else (-1, -0.3)
		spots += [((s0 * 0.22, 0.03, 0.78), sx, (-1, 0.3), (0.1, 1))] * 4 + [((s0 * 0.4, 0.035, 0.778), (-0.15, 0.15), (-1, 0.3), (-1, 1))] * 4
	spots += [((0.0, 0.05, 0.3), (-1, 1), (-1, -0.1), (-0.4, 0.1))] * 7 + [((0.0, 0.05, 0.42), (-1, 1), (-1, 0.2), (-0.3, 0.2))] * 4
	for c0, rx, ry, rz in spots:
		for _ in range(20):  # (find a spot clear of the face, the lantern and the fists)
			n = np.array((rs.uniform(*rx), rs.uniform(*ry), rs.uniform(*rz)))
			n /= np.linalg.norm(n)
			p0 = np.array(hit(body, tuple(c0), n))
			if (tri(p0[0], p0[2], 0.06) < 0 and p0[1] < -0.1) or np.linalg.norm(p0 - np.array(LANTERN)) < 0.12 					or abs(p0[0]) > HAND_X - 0.06:
				continue
			break
		else:
			continue
		big = rs.random() < 0.4
		L = rs.uniform(0.11, 0.18) if big else rs.uniform(0.06, 0.1)  # (owner, 2nd look: long and thin, pitch black)
		r = 0.0085 if big else 0.007
		tdir = np.cross(n, (rs.uniform(-1, 1), rs.uniform(-1, 1), rs.uniform(-1, 1)))
		tdir /= np.linalg.norm(tdir)
		gap = np.cross(n, tdir)
		count = 3 if rs.random() < 0.35 else 1
		for j in range(count):
			c = p0 + gap * (j - (count - 1) / 2) * 0.026
			c = np.array(hit(body, tuple(np.array(c0) + (c - np.array(c0)) * 0.7), c - np.array(c0)))
			Lj = L * (1.0 - 0.18 * abs(j - (count - 1) / 2))
			a, m, b = c - tdir * Lj + n * 0.004, c - n * 0.007, c + tdir * Lj + n * 0.004
			SCRATCH.append((a, m, b, r))
			body = smax(body, -tube(tuple(a), tuple(m), 0.003, r), 0.004)
			body = smax(body, -tube(tuple(m), tuple(b), r, 0.003), 0.004)
	body = smax(body, -face, 0.02)  # (the face hollow stays open)

BEARD = None  # the Bearded Shade's beard (it follows his head)
GEMS = []  # glowing bits that go in the eyes' mesh (the Bearded Shade's brooch stone)
if LOOK == "b":
	# The Wrathful Shade (F642): a dwarf warrior's spirit still furious. A tall pointed hood with a deep frown over his
	# face, a short cape torn into jagged points, leather straps crossed over his chest, a broad war belt with a big
	# buckle, broken shackles on both wrists and his grudges stitched on his sleeve as tally marks. Claw marks all over.
	ang = np.arctan2(X, Y - 0.035)
	# the frown: a heavy brow ridge along the V of the opening's top, then a rolled rim round the rest of it
	body, rim = face_rim(body, top=brow, r=0.025)
	bpts = []
	for x in np.linspace(-0.15, 0.15, 13):
		z = float(brow(x)) + 0.03
		bpts.append((x, hit(hood_whole, (x, 0.04, z), (0, -1, 0))[1] + 0.022, z))
	for i in range(len(bpts) - 1):
		k0, k1 = abs(bpts[i][0]) / 0.15, abs(bpts[i + 1][0]) / 0.15
		body = smin(body, tube(bpts[i], bpts[i + 1], 0.04 - 0.012 * k0, 0.04 - 0.012 * k1), 0.02)
	# the seam up the front of the pointed hood, over its tip and down the back, cross-stitched
	body = hood_seam(body, 62, 172)
	# creases winding round the point (as if it was twisted)
	for a0 in (0.9, 2.6, 4.3):
		pts = []
		for z in np.linspace(1.2, 1.37, 5):
			c = (0.0, 0.05 + 0.2 * (z - 1.18), z)
			a = a0 + 2.2 * (z - 1.2) / 0.17
			d = np.array((math.sin(a), math.cos(a), 0.0))
			pts.append(tuple(np.array(hit(hood_whole, c, d)) + d * 0.012))
		for i in range(len(pts) - 1):
			body = smax(body, -tube(pts[i], pts[i + 1], 0.01, 0.014), 0.01)
	# the short cape torn into jagged points hanging all round (not over the sleeves)
	for k in range(26):
		a = -math.pi + (k + 0.5) / 26.0 * math.tau + R.uniform(-0.05, 0.05)
		if abs(math.sin(a)) > 0.62:
			continue
		d = np.array((math.sin(a), math.cos(a), 0.0))
		p0 = np.array((0.44 * d[0], 0.04 + 0.31 * d[1], 0.775))
		zl = 0.775 - R.uniform(0.07, 0.13)
		p1 = np.array(hit(body, (0.0, 0.035, zl), d)) + d * 0.008
		mid = (p0 + p1) / 2 + d * 0.012
		body = rope(body, [tuple(p0), tuple(mid), tuple(p1)], 0.042, 0.006, 0.012)
	# soft folds radiating over the cape from the neck to its edge
	for k in range(16):
		a = k / 16.0 * math.tau + R.uniform(-0.1, 0.1)
		if abs(math.sin(a)) > 0.8:
			continue
		pts = []
		for e in (50, 28, 8):
			d = np.array((math.sin(a) * math.cos(math.radians(e)), math.cos(a) * math.cos(math.radians(e)), math.sin(math.radians(e))))
			pts.append(tuple(np.array(hit(body, (0.0, 0.035, 0.8), d)) + d * 0.012))
		for i in range(2):
			body = smax(body, -tube(pts[i], pts[i + 1], 0.01, 0.015), 0.01)
	# a zigzag of big stitches all round the cape just above its edge, and a ring of studs on its top
	zig = []
	for i in range(60):
		a = -math.pi + i / 60.0 * math.tau
		if abs(math.sin(a)) > 0.6:
			if len(zig) > 1:
				for j in range(len(zig) - 1):
					body = smin(body, tube(zig[j], zig[j + 1], 0.0065, 0.0065), 0.003)
			zig = []
			continue
		d = np.array((math.sin(a), math.cos(a), 0.0))
		zig.append(tuple(np.array(hit(body, (0.0, 0.035, 0.80 + (0.028 if i % 2 else 0.0)), d)) - d * 0.002))
	if len(zig) > 1:
		for j in range(len(zig) - 1):
			body = smin(body, tube(zig[j], zig[j + 1], 0.0065, 0.0065), 0.003)
	for k in range(14):
		a = -math.pi + (k + 0.5) / 14.0 * math.tau
		if abs(math.sin(a)) > 0.75:
			continue
		e = math.radians(38)
		d = np.array((math.sin(a) * math.cos(e), math.cos(a) * math.cos(e), math.sin(e)))
		body = smin(body, ell(tuple(np.array(hit(body, (0.0, 0.035, 0.79), d)) + d * 0.004), (0.016, 0.016, 0.016)), 0.004)
	# two leather straps crossed over his chest (from under the cape to the belt), a round boss where they cross
	for s in (-1, 1):
		pts = []
		for u in np.linspace(0.0, 1.0, 7):
			x, z = s * 0.23 * (1 - 2 * u), 0.725 - 0.2 * u
			pts.append(np.array(hit(body, (x, 0.03, z), (0, -1, 0))) + (0, -0.004, 0))
		dd = pts[-1] - pts[0]
		side = np.array((-dd[2], 0, dd[0])) / math.hypot(dd[0], dd[2])
		for off in (-0.011, 0.011):
			body = rope(body, [tuple(p + side * off) for p in pts], 0.013, 0.013, 0.006)
	bc = np.array(hit(body, (0.0, 0.03, 0.625), (0, -1, 0)))
	body = smin(body, ell(tuple(bc + (0, -0.004, 0)), (0.045, 0.022, 0.045)), 0.006)
	body = smin(body, ring(tuple(bc + (0, -0.018, 0)), "y", 0.032, 0.032, 0.007), 0.004)
	for k in range(4):
		a = k * math.pi / 2 + math.pi / 4
		body = smin(body, ell(tuple(bc + (0.03 * math.cos(a), -0.02, 0.03 * math.sin(a))), (0.011, 0.011, 0.011)), 0.003)
	# the broad war belt: a flat leather band, studs all round and a big square buckle at the front
	bz = 0.5
	e2 = (np.sqrt((X / 0.30) ** 2 + ((Y - 0.03) / 0.276) ** 2) - 1.0) * 0.276
	band = smax(np.abs(e2 - 0.012) - 0.014, np.abs(Z - bz) - 0.034, 0.008)
	body = smin(body, band, 0.006)
	bk = np.array(hit(body, (0.0, 0.03, bz), (0, -1, 0)))
	frame = smax(rbox(tuple(bk + (0, -0.002, 0)), (0.056, 0.011, 0.048), 0.008), -rbox(tuple(bk + (0, -0.002, 0)), (0.03, 0.05, 0.024), 0.006), 0.004)
	body = smin(body, frame, 0.004)
	body = smin(body, tube(tuple(bk + (-0.03, -0.008, 0)), tuple(bk + (0.016, -0.01, 0.002)), 0.0075, 0.0065), 0.003)  # its prong
	for k in range(14):
		a = -math.pi + (k + 0.5) / 14.0 * math.tau
		if abs(math.atan2(math.sin(a - math.pi), math.cos(a - math.pi))) < 0.4:
			continue  # (not on the buckle)
		d = np.array((math.sin(a), math.cos(a), 0.0))
		body = smin(body, ell(tuple(np.array(hit(body, (0.0, 0.03, bz), d)) + d * 0.002), (0.015, 0.015, 0.015)), 0.004)
	# broken shackles on both wrists: a thick iron band with rivets, a short chain hanging from it, its last link snapped
	for s in (-1, 1):
		rr_ = np.sqrt((Y - 0.035) ** 2 + (Z - 0.778) ** 2)
		body = smin(body, smax(np.abs(rr_ - 0.126) - 0.014, np.abs(X - s * 0.585) - 0.024, 0.006), 0.006)
		for k in range(5):
			a = k / 5.0 * math.tau + 0.4
			body = smin(body, ell((s * 0.585, 0.035 + 0.14 * math.cos(a), 0.778 + 0.14 * math.sin(a)), (0.012, 0.012, 0.012)), 0.003)
		for k in range(3):
			cz = 0.778 - 0.14 - 0.022 - k * 0.042
			link = ring((s * 0.585, 0.035, cz), "y" if k % 2 == 0 else "x", 0.022, 0.031, 0.0105)
			if k == 2:
				link = smax(link, -ell((s * 0.585, 0.035, cz - 0.03), (0.03, 0.03, 0.014)), 0.004)
			body = smin(body, link, 0.004)
	# his grudges: four tally strokes and a slash stitched on the front of his left sleeve
	for k in range(4):
		x = 0.39 + k * 0.028
		pa = np.array(hit(body, (x, 0.035, 0.81), (0, -1, 0))) + (0, -0.002, 0)
		pb = np.array(hit(body, (x + 0.006, 0.035, 0.745), (0, -1, 0))) + (0, -0.002, 0)
		body = smin(body, tube(tuple(pa), tuple(pb), 0.0075, 0.0075), 0.003)
	pa = np.array(hit(body, (0.375, 0.035, 0.75), (0, -1, 0))) + (0, -0.006, 0)
	pb = np.array(hit(body, (0.49, 0.035, 0.805), (0, -1, 0))) + (0, -0.006, 0)
	body = smin(body, tube(tuple(pa), tuple(pb), 0.0075, 0.0075), 0.003)
	# deep folds in the robe below the belt, torn strips down the tail and two flame-like wisps off its tip
	body = body + np.where(Z < 0.46, 0.011 * np.sin(ang * 6 + 1.3) * np.clip((0.46 - Z) / 0.08, 0, 1) * np.clip((Z - 0.12) / 0.12, 0, 1), 0.0)
	body = tail_strips(body, 6, 512, 0.007)
	tip, _ = tail_at(0.97)
	for k, ph in enumerate((0.6, 3.6)):
		pts = [tip]
		for j in range(1, 8):
			u = j / 7
			pts.append((tip[0] + 0.1 * u * math.sin(u * 5.0 + ph), tip[1] + 0.03 + 0.1 * u, tip[2] + 0.17 * u + 0.03 * k))
		body = rope(body, pts, 0.03, 0.008, 0.012)
	# a few small dings in the hood and cape (not many: the owner disliked the "crunched soda can")
	for k in range(18):
		c0 = np.array(HEAD_C) if k < 9 else np.array((0.0, 0.035, 0.8))
		n = np.array((R.uniform(-1, 1), R.uniform(-0.3, 1), R.uniform(0.1, 1)))
		n /= np.linalg.norm(n)
		p = np.array(hit(body, tuple(c0), n))
		if near_face(p, 0.07):
			continue
		r = R.uniform(0.014, 0.024)
		body = smax(body, -ell(tuple(p + n * r * 0.8), (r * 1.15, r * 1.15, r * 0.85)), 0.01)
	body = lumpy(body, 0.6)
	# claw marks, mostly on his front, more of them in sets of three (something big fought him)
	spots = [(HEAD_C, (-1, 1), (-1, -0.25), (-0.1, 1))] * 7 + [(HEAD_C, (-1, 1), (-0.2, 1), (-0.1, 1))] * 2 \
		+ [((0.0, 0.035, 0.66), (-1, 1), (-1, -0.2), (-0.3, 0.4))] * 10 + [((0.0, 0.035, 0.66), (-1, 1), (0.2, 1), (-0.3, 0.4))] * 4 \
		+ [((0.0, 0.05, 0.4), (-1, 1), (-1, -0.1), (-0.4, 0.1))] * 9 + [((0.0, 0.05, 0.4), (-1, 1), (0.2, 1), (-0.4, 0.1))] * 3
	for s0 in (-1, 1):
		spots += [((s0 * 0.42, 0.035, 0.778), (-0.15, 0.15), (-1, 0.3), (-1, 1))] * 4
	body = scratch_marks(body, spots, 92, 0.6, lambda p: near_face(p, 0.07) or abs(p[2] - 0.5) < 0.045)

if LOOK == "c":
	# The Bearded Shade (F642; the Grey Warden wears him too): an old dwarf keeper. A long braided beard and a drooping
	# moustache, a mantle with a thick fur trim, a glowing stone brooch, a knotted cloth sash, the warden's iron key ring
	# at his hip, a scroll case on his back, patches, and the ragged hem of an old robe.
	ang = np.arctan2(X, Y - 0.035)
	body, rim = face_rim(body, r=0.03)
	for i in range(0, 40, 3):  # big stitches across the rim
		c = np.array(rim[i])
		n = c - np.array(FACE_C)
		n[1] = 0.0
		n /= np.linalg.norm(n)
		body = smin(body, tube(tuple(c - n * 0.03 + (0, -0.022, 0)), tuple(c + n * 0.03 + (0, -0.022, 0)), 0.0065, 0.0065), 0.003)
	body = hood_seam(body, 58, 165)
	# the mantle: a short cape over his shoulders (laid on the body, 2.2 cm thick), its edge trimmed with chunky fur
	def m_edge(a):
		return 0.69 + 0.025 * math.cos(a) + 0.012 * math.sin(a * 7 + 1.1)
	edge = 0.69 + 0.025 * np.cos(ang) + 0.012 * np.sin(ang * 7 + 1.1)
	cowl = smax(smax(body - 0.022, edge - Z, 0.006), np.abs(X) - 0.47 + 0.015 * np.sin(Z * 50), 0.01)
	body = smin(body, smax(cowl, Z - 0.9, 0.03), 0.006)
	for i in range(54):
		a = -math.pi + (i + 0.5) / 54.0 * math.tau
		if abs(math.sin(a)) > 0.7:
			continue
		d = np.array((math.sin(a), math.cos(a), 0.0))
		p = np.array(hit(body, (0.0, 0.035, m_edge(a) + 0.01), d)) - d * 0.004
		r = R.uniform(0.026, 0.034)
		body = smin(body, ell(tuple(p + (0, 0, R.uniform(-0.008, 0.004))), (r, r, r * 1.2)), 0.008)
	# soft folds down the mantle
	for k in range(14):
		a = k / 14.0 * math.tau + R.uniform(-0.12, 0.12)
		if abs(math.sin(a)) > 0.75:
			continue
		d = np.array((math.sin(a), math.cos(a), 0.0))
		pts = [tuple(np.array(hit(body, (0.0, 0.035, z), d)) + d * 0.013) for z in (0.84, 0.78, 0.73)]
		for i in range(2):
			body = smax(body, -tube(pts[i], pts[i + 1], 0.01, 0.016), 0.01)
	# a round brooch pinning the mantle on his right shoulder (its stone glows: it is in the eyes' mesh)
	bp = np.array(hit(body, (-0.25, 0.03, 0.765), (0, -1, 0)))
	body = smin(body, ell(tuple(bp + (0, -0.004, 0)), (0.04, 0.016, 0.04)), 0.006)
	body = smin(body, ring(tuple(bp + (0, -0.017, 0)), "y", 0.036, 0.036, 0.008), 0.004)
	for k in range(6):
		a = k / 6.0 * math.tau
		body = smin(body, ell(tuple(bp + (0.036 * math.cos(a), -0.022, 0.036 * math.sin(a))), (0.009, 0.009, 0.009)), 0.003)
	GEMS.append(ell(tuple(bp + (0, -0.022, 0)), (0.018, 0.014, 0.018)))
	# creases fanning back over the hood from the sides of his face
	for s in (-1, 1):
		for f in (0.25, 0.65):
			pts = []
			for u in (0.0, 0.5, 1.0):
				n = np.array((s * (0.6 + 0.35 * u), -0.7 + 0.95 * u, 0.05 + f * 0.6 * u))
				n /= np.linalg.norm(n)
				pts.append(tuple(np.array(hit(hood_whole, HEAD_C, n)) + n * 0.016))
			for i in range(2):
				body = smax(body, -tube(pts[i], pts[i + 1], 0.012, 0.018), 0.012)
	# the knotted cloth sash round his waist, a fat knot at his left hip and its two ends hanging with fringes
	bz = 0.49
	theta = np.arctan2(Y - 0.03, X)
	e2 = (np.sqrt((X / 0.30) ** 2 + ((Y - 0.03) / 0.276) ** 2) - 1.0) * 0.276
	band = smax(np.abs(e2 - 0.01) - 0.015, np.abs(Z - bz - 0.006 * np.sin(theta * 5)) - 0.036, 0.01)
	band = band + 0.004 * np.sin(theta * 26 + (Z - bz) * 40)  # (cloth wrinkles)
	body = smin(body, band, 0.006)
	ka = math.radians(150)  # (his left hip, at the front)
	kd = np.array((math.sin(ka), math.cos(ka), 0.0))
	kc = np.array(hit(body, (0.0, 0.03, bz), kd)) + kd * 0.012
	body = smin(body, ell(tuple(kc), (0.046, 0.034, 0.04)) + wobble(0.006, 31), 0.01)
	for j, (dx, zl) in enumerate(((0.025, 0.31), (-0.02, 0.35))):
		pts = []
		for u in (0.0, 0.5, 1.0):
			z = bz - 0.03 - (bz - 0.03 - zl) * u
			p = np.array(hit(body, (kc[0] * 0.6 + dx * u, 0.03, z), kd)) + kd * 0.012
			pts.append(tuple(p if u > 0 else kc))
		for off in (-0.012, 0.012):
			body = rope(body, [(q[0] + off * kd[1], q[1] - off * kd[0], q[2]) for q in pts], 0.014, 0.012, 0.008)
		end = np.array(pts[-1])
		for fx in (-0.016, 0.0, 0.016):
			body = smin(body, tube(tuple(end + (fx * kd[1], -fx * kd[0], 0)), tuple(end + (fx * kd[1] * 1.3, -fx * kd[0] * 1.3, -0.045)), 0.008, 0.006), 0.004)
	# the warden's iron key ring at his right hip: a big ring hanging from the sash, three old keys on it
	rd = np.array((-0.93, -0.37, 0.0)) / math.hypot(0.93, 0.37)
	rc = np.array(hit(body, (0.0, 0.03, 0.43), rd)) + rd * 0.02
	body = smin(body, ring(tuple(rc), "x", 0.045, 0.045, 0.01), 0.004)
	for k, phi in enumerate((-0.55, 0.0, 0.5)):
		top = rc + np.array((0.0, math.sin(phi) * 0.045, -math.cos(phi) * 0.045))
		bow = top + np.array((0.0, math.sin(phi) * 0.02, -math.cos(phi) * 0.02))
		body = smin(body, ring(tuple(bow), "x", 0.019, 0.019, 0.0075), 0.003)
		ln = (0.085, 0.1, 0.075)[k]
		s0 = bow + np.array((0.0, math.sin(phi) * 0.018, -math.cos(phi) * 0.018))
		s1 = s0 + np.array((0.012, math.sin(phi) * ln * 0.3, -ln))
		body = smin(body, tube(tuple(s0), tuple(s1), 0.009, 0.008), 0.003)
		body = smin(body, rbox(tuple(s1 + (0.0, 0.016, 0.012)), (0.008, 0.012, 0.014), 0.004), 0.003)  # its bit
	# a leather scroll case on his back, hanging from the sash, its two caps and a band round the middle
	sp = [np.array(hit(body, (x, 0.03, z), (0, 1, 0))) + (0, 0.04, 0) for x, z in ((0.2, 0.66), (0.05, 0.54), (-0.1, 0.42))]
	body = rope(body, [tuple(p) for p in sp], 0.046, 0.046, 0.01)
	axis = (sp[2] - sp[0]) / np.linalg.norm(sp[2] - sp[0])
	for p, w in ((sp[0], 0.03), (sp[2], 0.03), (sp[1], 0.012)):
		body = smin(body, tube(tuple(p - axis * w / 2), tuple(p + axis * w / 2), 0.05, 0.05), 0.006)
	# two patches: low on his back and on his left sleeve
	body = patch(body, (0.12, 0.05, 0.36), (0, 1, 0), (0.05, 0.03, 0.04), -0.15, 7)
	body = patch(body, (0.45, 0.035, 0.79), (0, -1, 0), (0.035, 0.03, 0.03), 0.2, 8)
	# turned-back cuffs on his wide sleeves, ragged tatters hanging under them and round his waist
	for s in (-1, 1):
		body = smin(body, ring((s * (HAND_X - 0.03), 0.035, 0.778), "x", 0.128, 0.128, 0.022), 0.01)
		for dz in (0.0, 0.05):
			body = smin(body, tube((s * (HAND_X - 0.04), 0.06 + dz, 0.70), (s * (HAND_X - 0.06), 0.08 + dz, 0.61), 0.04, 0.012), 0.025)
	for k in range(8):  # (torn flaps lying flat on the robe under the sash, at his sides and back: not dripping off it)
		a = -0.4 * math.pi + k / 7.0 * 0.8 * math.pi + R.uniform(-0.12, 0.12)
		d = np.array((math.sin(a), math.cos(a), 0.0))
		side = np.array((math.cos(a), -math.sin(a), 0.0))
		zl = 0.45 - R.uniform(0.1, 0.16)
		pts = [np.array(hit(body, (0.0, 0.03, z), d)) + d * 0.004 for z in (0.455, (0.455 + zl) / 2, zl)]
		for off in (-0.014, 0.014):
			body = rope(body, [tuple(q + side * off * (1 - 0.6 * j / 2)) for j, q in enumerate(pts)], 0.016, 0.008, 0.008)
	body = body + np.where(Z < 0.45, 0.01 * np.sin(ang * 8 + 0.3) * np.clip((0.45 - Z) / 0.08, 0, 1) * np.clip((Z - 0.12) / 0.12, 0, 1), 0.0)
	body = tail_strips(body, 7, 613, 0.012)
	tip, _ = tail_at(0.97)
	for k, ph in enumerate((0.3, 2.4, 4.5)):
		pts = [tip]
		for j in range(1, 8):
			u = j / 7
			pts.append((tip[0] + 0.12 * u * math.sin(u * 4.0 + ph), tip[1] + 0.03 + 0.12 * u + 0.05 * math.cos(u * 4.0 + ph), tip[2] + 0.13 * u + 0.025 * k))
		body = rope(body, pts, 0.03, 0.013, 0.012)
	body = lumpy(body, 0.6)
	# scratches (fewer claw sets: worn by years more than fights)
	spots = [(HEAD_C, (-1, 1), (-1, -0.2), (-0.1, 1))] * 7 + [(HEAD_C, (-1, 1), (-0.2, 1), (-0.1, 1))] * 3 \
		+ [((0.0, 0.035, 0.7), (-1, 1), (-1, -0.2), (-0.2, 0.6))] * 8 + [((0.0, 0.035, 0.7), (-1, 1), (0.2, 1), (-0.2, 0.6))] * 3 \
		+ [((0.0, 0.05, 0.4), (-1, 1), (-1, -0.1), (-0.4, 0.1))] * 8 + [((0.0, 0.05, 0.4), (-1, 1), (0.2, 1), (-0.4, 0.1))] * 2
	for s0 in (-1, 1):
		spots += [((s0 * 0.42, 0.035, 0.778), (-0.15, 0.15), (-1, 0.3), (-1, 1))] * 3
	body = scratch_marks(body, spots, 93, 0.25, lambda p: near_face(p, 0.07) or (abs(p[0]) < 0.2 and p[1] < -0.1 and p[2] > 0.5)
		or np.linalg.norm(p - bp) < 0.07 or np.linalg.norm(p - rc) < 0.15 or abs(p[2] - bz) < 0.05)
	# the beard (laid on last: it comes out of the face hollow): a broad mass with combed strands, a drooping
	# moustache, and it ends in three braids, each with an iron band and a tuft
	beard = tube((0, -0.175, 0.93), (0, -0.265, 0.7), 0.1, 0.05, sx=1.45)
	beard = smin(beard, ell((0, -0.235, 0.83), (0.13, 0.06, 0.09)), 0.04)  # (fuller up by his cheeks)
	beard = beard + 0.007 * np.sin(X * 75.0 + 0.9 * np.sin(Z * 22.0) + Z * 10.0)  # (combed strands, not ruler-straight)
	for s in (-1, 1):
		beard = rope(beard, [(s * 0.02, -0.215, 0.965), (s * 0.08, -0.25, 0.945), (s * 0.13, -0.275, 0.9), (s * 0.15, -0.28, 0.83)], 0.03, 0.014, 0.015)
	for bx, zl in ((-0.07, 0.5), (0.0, 0.4), (0.07, 0.5)):
		p0 = np.array((bx * 0.7, -0.27, 0.74))
		p1 = np.array((bx, -0.3, zl))
		nl = 8
		for j in range(nl):
			u = (j + 0.5) / nl
			c = p0 + (p1 - p0) * u + np.array(((0.011 if j % 2 else -0.011), 0, 0))
			rr_ = 0.038 - 0.012 * u
			beard = smin(beard, ell(tuple(c), (rr_, rr_ * 0.8, rr_ * 0.9)), 0.006)
		beard = smin(beard, ring(tuple(p0 + (p1 - p0) * 0.7), "z", 0.032, 0.026, 0.009), 0.004)
		beard = smin(beard, tube(tuple(p1), tuple(p1 + (0, -0.006, -0.06)), 0.026, 0.007), 0.008)
	BEARD = beard
	body = smin(body, beard, 0.02)


body = body + wobble(0.007, R.randint(0, 999))
MAT_BODY = ck.color(NAME + "_body", (0.55, 0.85, 0.8) if LOOK != "b" else (0.6, 0.75, 0.95))
o_body = to_mesh(NAME + "_body", body, MAT_BODY)

# The eyes: two glowing lumps set into the back of the face hollow (they sink into the hood: they touch it).
eyes = np.minimum(ell((-0.062, -0.087 - 0.0, 1.045), (0.034, 0.02, 0.022)), ell((0.062, -0.087, 1.045), (0.034, 0.02, 0.022)))
if LOOK == "b":  # angry: slanted down to the middle, under the frown
	eyes = np.minimum(tube((-0.03, -0.087, 1.03), (-0.088, -0.087, 1.055), 0.017, 0.012),
		tube((0.03, -0.087, 1.03), (0.088, -0.087, 1.055), 0.017, 0.012))
for g in GEMS:  # (the Bearded Shade's brooch stone)
	eyes = np.minimum(eyes, g)
if LOOK == "a":  # smaller eyes, lower in the pointed opening (owner, Nov 22), and the lantern's glass: it touches
	# the cap and the foot, inside the four posts (clear of them)
	eyes = np.minimum(ell((-0.05, -0.09, 1.0), (0.023, 0.02, 0.016)), ell((0.05, -0.09, 1.0), (0.023, 0.02, 0.016)))
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
	if LOOK == "a" and o is o_body:  # dark only inside the pointed opening, behind its rim (the rolled rim is lit)
		e = tri(co[:, 0], co[:, 2], 0.012)
		lit = np.maximum(np.clip(e / 0.025, 0.0, 1.0), np.clip((-0.19 - co[:, 1]) / 0.03, 0.0, 1.0))
		lit = np.where(co[:, 2] < 0.85, 1.0, lit)
	if LOOK == "b" and o is o_body:  # the brow over the frown is lit
		lit = np.maximum(lit, np.clip((co[:, 2] - brow(co[:, 0]) + 0.005) / 0.02, 0.0, 1.0))
	if LOOK == "c" and o is o_body:  # the moustache and the beard where they come out of the hollow are lit
		lit = np.maximum(lit, np.where(co[:, 2] < 0.99, np.clip((-0.205 - co[:, 1]) / 0.03, 0.0, 1.0), 0.0))
	lit = 0.08 + 0.92 * lit
	mist = np.clip((0.5 - co[:, 2]) / 0.44, 0.0, 1.0) if o is o_body else np.zeros(len(co))
	if o is o_eyes:
		mist[:] = 0.0
	glow = np.full(len(co), 1.0 if o is o_eyes else 0.0)
	if o is o_body and SCRATCH:  # (inside a scratch: 0.35, painted pitch black; the eyes are 1, anything over 0.5)
		near = np.full(len(co), 9.0)
		for a, m, b, r in SCRATCH:
			for p0, p1, r0, r1 in ((a, m, 0.003, r), (m, b, r, 0.003)):
				ab = np.array(p1) - np.array(p0)
				t = np.clip(((co - p0) @ ab) / (ab @ ab), 0, 1)
				dd = np.linalg.norm(co - (np.array(p0) + t[:, None] * ab), axis=1) / (r0 + (r1 - r0) * t + 0.003)
				near = np.minimum(near, dd)
		glow = 0.35 * np.clip((1.15 - near) / 0.3, 0.0, 1.0)
	rgb = np.stack([lit, mist, glow], 1)
	ga = o.data.color_attributes.new("guide", "FLOAT_COLOR", "POINT")
	ga.data.foreach_set("color", np.concatenate([rgb, np.ones((len(rgb), 1))], 1).ravel())
	o.data.color_attributes.active_color = ga
	o.data.uv_layers.new(name="UVMap")
	for p in o.data.polygons:
		p.use_smooth = True
	# fewer faces: the game's light copy
	n = len(o.data.polygons)
	want = {o_body: 70000 if LOOK == "a" else 50000, o_eyes: 500 if LOOK != "c" else 800, o_fists: 900}[o]
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
	near = ws[KD.find(Vector(p))[1]]
	if o is o_eyes:  # (the lantern's glass hangs from the belt; the brooch's stone rides on his chest)
		return {"Head": 1.0} if z > 0.9 else ({"pelvis": 1.0} if LOOK == "a" else near)
	if o is o_fists:
		return {"hand_l" if x > 0 else "hand_r": 1.0}
	dh_ = math.dist(p, HEAD_C)
	if (z > 0.9 and abs(x) < 0.32) or (BEARD is not None and at(BEARD, p) < 0.012):  # the hood (and the beard) follow his head
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
