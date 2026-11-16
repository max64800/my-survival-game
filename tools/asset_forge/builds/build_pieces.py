# Building pieces (folder: build), hand-built from the kit, in every material family.
#   blender --background --factory-startup --python builds/build_pieces.py -- [piece__family ...]
# Output: assets/models/build/<piece>__<family>.glb, matching src/build/piece_mesh.gd EXACTLY:
#   piece-space origin = bottom-centre of the piece's size box; sizes/orientations as in Pieces.LIST.
# Everything below is written in GODOT coordinates (x right, y up, z toward the viewer) and converted
# to Blender at the edge (G / GS), so it mirrors Claude 1's code line by line. Visual only (no collision).
import math
import random
import shutil
import sys
from pathlib import Path

import bpy
from mathutils import Matrix

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kit  # noqa: E402

GAME = Path(__file__).resolve().parents[3]
OUT = GAME / "assets" / "models" / "build"
JOUR = GAME / "journey" / "3d" / "v2_hand_built" / "build"

# family -> (style, main texture, trim texture)
FAM = {
	"plank_root": ("wood", "wood", "iron"), "plank_mushroom": ("wood", "mushwood", "silver"),
	"cut_stone": ("stone", "stone", "copper"), "cut_marble": ("stone", "marble", "copper"),
	"basalt": ("stone", "basalt", "iron"), "brown_rock": ("stone", "brownrock", "copper"),
	"sporestone_block": ("stone", "sporestone", "silver"), "amber_block": ("stone", "amberrock", "copper"),
	"clay_brick": ("brick", "brick", "wood"), "mushroom_brick": ("brick", "mushwood", "wood"),
	"ancient_brick": ("brick", "brick", "stone"), "copper_ingot": ("metal", "copper", "iron"),
	"silver_ingot": ("metal", "silver", "iron"),
}
ROOF_TEX = {"wood": "shingle", "stone": "slate", "brick": "rooftile", "metal": None}

rng = random.Random(7)
STYLE, TEX, TRIM = "wood", "wood", "iron"


# ---------- Godot -> Blender ----------
def G(p):
	return (p[0], -p[2], p[1])


def GS(s):
	return (s[0], s[2], s[1])


def tm(kind=None, variant=None):
	return kit.tex_mat(kind or TEX, variant)


def gbox(c, s, mat, bevel=0.012, wobble=0.003, roty=0.0, rotz=0.0, rotx=0.0):
	"""A box in Godot space; roty = turn around up, rotz = tilt in the wall plane, rotx = tilt toward the viewer."""
	# No wobble on building pieces: they're placed by the hundred, and wobble multiplies triangles by 4.
	return kit.box(GS(s), G(c), mat, bevel=bevel, wobble=0, rot=(rotx, -rotz, roty))


def gcyl(c, r, h, mat, verts=12, axis="y", bevel=0.006):
	rot = {"y": (0, 0, 0), "x": (0, 90, 0), "z": (90, 0, 0)}[axis]
	return kit.cylinder(r, h, G(c), mat, rot=rot, verts=verts, bevel=bevel)


def gmesh(verts, faces, mat, smooth=False):
	return kit._mesh_obj("piece", [G(v) for v in verts], faces, mat, smooth=smooth)


def gprism_x(profile, x0, x1, mat):
	"""Extrude a (z, y) profile along x from x0 to x1 (roofs, ridges)."""
	n = len(profile)
	v = [(x0, y, z) for (z, y) in profile] + [(x1, y, z) for (z, y) in profile]
	f = [tuple(reversed(range(n))), tuple(range(n, 2 * n))]
	for i in range(n):
		j = (i + 1) % n
		f.append((i, j, j + n, i + n))
	return gmesh(v, f, mat)


def gprism_y(tri, y0, y1, mat):
	n = len(tri)
	v = [(x, y0, z) for (x, z) in tri] + [(x, y1, z) for (x, z) in tri]
	f = [tuple(range(n)), tuple(reversed(range(n, 2 * n)))]
	for i in range(n):
		j = (i + 1) % n
		f.append((j, i, i + n, j + n))
	return gmesh(v, f, mat)


def gprism_z(profile, z0, z1, mat):
	"""Extrude an (x, y) profile along z (gables)."""
	n = len(profile)
	v = [(x, y, z0) for (x, y) in profile] + [(x, y, z1) for (x, y) in profile]
	f = [tuple(reversed(range(n))), tuple(range(n, 2 * n))]
	for i in range(n):
		j = (i + 1) % n
		f.append((i, j, j + n, i + n))
	return gmesh(v, f, mat)


# ---------- surfaces (the material's look) ----------
def wall_fill(x0, x1, y0, y1, d, z=0.0, mask=None):
	"""Fill a rectangle of wall (x0..x1, y0..y1, thickness d) in the family's look."""
	w, h = x1 - x0, y1 - y0
	if w < 0.02 or h < 0.02:
		return
	cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
	if STYLE == "wood":
		n = max(1, round(w / 0.24))
		pw = w / n
		for i in range(n):
			gbox((x0 + pw * (i + 0.5), cy, z), (pw - 0.014, h, d * 0.72), tm(None, "abc"[i % 3]), bevel=0.01, wobble=0.004)
		for yy in (y0 + 0.18, y1 - 0.18) if h > 0.8 else ():
			for side in (-1, 1):
				gbox((cx, yy, z + side * d * 0.38), (w, 0.1, 0.05), tm(None, "dark"), bevel=0.008, wobble=0.002)
				for xx in (x0 + 0.12, x1 - 0.12):
					kit.rivet(G((xx, yy, z + side * (d * 0.38 + 0.03))), kit.tex_mat(TRIM), r=0.014)
	elif STYLE in ("stone", "brick"):
		rh, bl = (0.33, 0.5) if STYLE == "stone" else (0.15, 0.32)
		if not mask:
			gbox((cx, cy, z), (w - 0.02, h - 0.02, d * 0.8), kit.mat("charcoal", 1.6), bevel=0, wobble=0)
		rows = max(1, round(h / rh))
		rhh = h / rows
		for r in range(rows):
			y = y0 + rhh * (r + 0.5)
			off = (r % 2) * bl * 0.5
			xx = x0 - off
			while xx < x1 - 0.01:
				ln = bl * (rng.uniform(0.8, 1.2) if STYLE == "stone" else 1.0)
				a, b = max(xx, x0), min(xx + ln, x1)
				if b - a > 0.05 and not (mask and mask((a + b) / 2, y, (b - a) / 2, rhh / 2)):
					o = gbox(((a + b) / 2, y, z), (b - a - 0.02, rhh - 0.02, d), tm(None, rng.choice("abc")),
						bevel=0.02 if STYLE == "stone" else 0.0, wobble=0.004 if STYLE == "stone" else 0.0)
				xx += ln
	else:  # metal: a backing sheet, raised plates with rivets, a frame
		gbox((cx, cy, z), (w, h, d * 0.6), tm(None, "dark"), bevel=0.004, wobble=0)
		nx, ny = max(1, round(w / 0.5)), max(1, round(h / 0.5))
		pw, ph = w / nx, h / ny
		for i in range(nx):
			for j in range(ny):
				px, py = x0 + pw * (i + 0.5), y0 + ph * (j + 0.5)
				gbox((px, py, z), (pw - 0.03, ph - 0.03, d * 0.8), tm(None, "abc"[(i + j) % 3]), bevel=0.008, wobble=0)
				for (dx, dy) in ((-1, 1), (1, -1)):
					kit.rivet(G((px + dx * (pw / 2 - 0.05), py + dy * (ph / 2 - 0.05), z + d * 0.42)), kit.tex_mat("iron"), r=0.014)


def floor_fill(x0, x1, z0, z1, y0, t):
	w, dd = x1 - x0, z1 - z0
	cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
	if STYLE == "wood":
		n = max(1, round(dd / 0.25))
		pd = dd / n
		for i in range(n):
			gbox((cx, y0 + t * 0.6, z0 + pd * (i + 0.5)), (w, t * 0.4, pd - 0.012), tm(None, "abc"[i % 3]), bevel=0.008, wobble=0.003)
		for xx in (x0 + 0.15, x1 - 0.15):
			gbox((xx, y0 + t * 0.2, cz), (0.14, t * 0.4, dd), tm(None, "dark"), bevel=0.01, wobble=0.002)
	elif STYLE in ("stone", "brick"):
		gbox((cx, y0 + t / 2, cz), (w - 0.01, t * 0.9, dd - 0.01), kit.mat("charcoal", 1.6), bevel=0, wobble=0)
		tile = 0.5 if STYLE == "stone" else 0.25
		nx, nz = max(1, round(w / tile)), max(1, round(dd / (tile * (1 if STYLE == "stone" else 0.5))))
		pw, pd = w / nx, dd / nz
		for i in range(nx):
			for j in range(nz):
				off = (j % 2) * pw * 0.5 if STYLE == "brick" else 0
				px = x0 + pw * (i + 0.5) + off
				if px > x1 - 0.02:
					continue
				gbox((px, y0 + t / 2 + 0.005, z0 + pd * (j + 0.5)), (pw - 0.025, t, pd - 0.025), tm(None, rng.choice("abc")),
					bevel=0.018 if STYLE == "stone" else 0.0, wobble=0.003 if STYLE == "stone" else 0.0)
	else:
		wall_fill_floor_metal(x0, x1, z0, z1, y0, t)


def wall_fill_floor_metal(x0, x1, z0, z1, y0, t):
	gbox(((x0 + x1) / 2, y0 + t / 2, (z0 + z1) / 2), (x1 - x0, t, z1 - z0), tm(None, "b"), bevel=0.006, wobble=0)
	for i in range(int((x1 - x0) / 0.5) + 1):
		gbox((x0 + i * 0.5, y0 + t + 0.005, (z0 + z1) / 2), (0.04, 0.01, z1 - z0), tm(None, "dark"), bevel=0, wobble=0)


def timber(c, s, axis="x"):
	"""A beam or post in the family's look (wood timber with iron straps; stone blocks; metal girder)."""
	if STYLE == "wood":
		gbox(c, s, tm(None, "b"), bevel=0.02, wobble=0.004)
		L = max(s)
		for e in (-1, 1):
			off = [0, 0, 0]
			k = {"x": 0, "y": 1, "z": 2}[axis]
			off[k] = e * (L / 2 - 0.12)
			band = [s[0] + 0.02, s[1] + 0.02, s[2] + 0.02]
			band[k] = 0.05
			gbox((c[0] + off[0], c[1] + off[1], c[2] + off[2]), band, kit.tex_mat(TRIM), bevel=0.004, wobble=0)
	elif STYLE in ("stone", "brick"):
		k = {"x": 0, "y": 1, "z": 2}[axis]
		L = s[k]
		n = max(1, round(L / (0.45 if STYLE == "stone" else 0.25)))
		for i in range(n):
			p = list(c)
			p[k] = c[k] - L / 2 + L / n * (i + 0.5)
			ss = list(s)
			ss[k] = L / n - 0.02
			gbox(p, ss, tm(None, rng.choice("abc")), bevel=0.02, wobble=0.004)
	else:
		gbox(c, s, tm(None, "b"), bevel=0.01, wobble=0)
		k = {"x": 0, "y": 1, "z": 2}[axis]
		for e in (-1, 0, 1):
			p = list(c)
			p[k] += e * (s[k] / 2 - 0.08) if e else 0
			fl = [s[0] + 0.04, s[1] + 0.04, s[2] + 0.04]
			fl[k] = 0.04
			gbox(p, fl, tm(None, "dark"), bevel=0.004, wobble=0)


# ---------- pieces ----------
def wall(w=2.0, h=2.0, d=0.3, opening=None, arch=False):
	if not opening:
		wall_fill(-w / 2, w / 2, 0, h, d)
		edge_trim(w, h, d)
		return
	ow, oh, ob = opening
	wall_fill(-w / 2, -ow / 2, 0, h, d)
	wall_fill(ow / 2, w / 2, 0, h, d)
	if ob > 0.01:
		wall_fill(-ow / 2, ow / 2, 0, ob, d)
	if arch:
		r = ow / 2
		spring = oh - r
		wall_fill(-ow / 2, ow / 2, spring, h, d, mask=lambda x, y, hw, hh: math.hypot(x, y - spring) < r + 0.24 + max(hw, hh) * 0.6)
		for i in range(7):
			a = math.pi * (i + 0.5) / 7
			p = (-math.cos(a) * (r + 0.12), spring + math.sin(a) * (r + 0.12), 0)
			gbox(p, (math.pi * r / 7 - 0.02, 0.26, d + 0.04), tm(None, rng.choice("abc")), bevel=0.02, wobble=0.004, rotz=math.degrees(a - math.pi / 2))
		gbox((0, spring + r + 0.18, 0), (0.22, 0.3, d + 0.08), tm(None, "c"), bevel=0.02, wobble=0.004)  # keystone
		return
	wall_fill(-ow / 2, ow / 2, ob + oh, h, d)
	# Frame around the opening: jambs, lintel, sill.
	fm = kit.tex_mat("wood", "dark") if STYLE in ("wood", "brick") else tm(None, "c")
	for s_ in (-1, 1):
		gbox((s_ * (ow / 2 + 0.06), ob + oh / 2, 0), (0.12, oh + 0.02, d + 0.06), fm, bevel=0.012, wobble=0.003)
	gbox((0, ob + oh + 0.08, 0), (ow + 0.36, 0.16, d + 0.08), fm, bevel=0.015, wobble=0.003)
	if ob > 0.01:
		gbox((0, ob - 0.04, 0), (ow + 0.28, 0.08, d + 0.14), fm, bevel=0.01, wobble=0.003)
		# Window: crossbars and a hint of glass.
		gbox((0, ob + oh / 2, 0), (ow, 0.05, 0.05), kit.tex_mat("iron"), bevel=0.004, wobble=0)
		gbox((0, ob + oh / 2, 0), (0.05, oh, 0.05), kit.tex_mat("iron"), bevel=0.004, wobble=0)
	if STYLE == "metal":
		for s_ in (-1, 1):
			for yy in (0.3, oh - 0.3):
				gbox((s_ * (ow / 2 + 0.02), ob + yy, d / 2 + 0.03), (0.1, 0.06, 0.03), kit.tex_mat("iron"), bevel=0.003, wobble=0)


def edge_trim(w, h, d):
	"""Corner posts / quoins and a top cap so walls read as built, not cut from one block."""
	if STYLE == "wood":
		for s_ in (-1, 1):
			gbox((s_ * (w / 2 - 0.07), h / 2, 0), (0.14, h, d + 0.04), tm(None, "dark"), bevel=0.02, wobble=0.004)
		gbox((0, h - 0.06, 0), (w, 0.12, d + 0.06), tm(None, "dark"), bevel=0.02, wobble=0.003)
		gbox((0, 0.06, 0), (w, 0.12, d + 0.06), tm(None, "dark"), bevel=0.02, wobble=0.003)
	elif STYLE == "stone":
		gbox((0, h - 0.05, 0), (w, 0.1, d + 0.06), tm(None, "c"), bevel=0.02, wobble=0.003)


def floor(w=2.0, t=0.25, dd=2.0, triangle=False):
	if triangle:
		hx, hz = w / 2, dd / 2
		gprism_y([(-hx, -hz), (hx, hz), (-hx, hz)], 0, t * 0.9, tm(None, "b"))
		gprism_y([(-hx + 0.06, -hz + 0.2), (hx - 0.2, hz - 0.06), (-hx + 0.06, hz - 0.06)], t * 0.9, t + 0.02, tm(None, "c"))
		return
	floor_fill(-w / 2, w / 2, -dd / 2, dd / 2, 0, t)


def foundation(w=2.0, h=1.0, dd=2.0, triangle=False, steps=False):
	if triangle:
		hx, hz = w / 2, dd / 2
		gprism_y([(-hx, -hz), (hx, hz), (-hx, hz)], 0, h - 0.1, tm(None, "dark"))
		gprism_y([(-hx + 0.04, -hz + 0.12), (hx - 0.12, hz - 0.04), (-hx + 0.04, hz - 0.04)], h - 0.1, h, tm(None, "c"))
		return
	if steps:
		for i in range(4):
			hh = (i + 1) * h / 4
			gbox((0, hh / 2, dd / 2 - (i + 0.5) * dd / 4), (w, hh, dd / 4 - 0.01), tm(None, rng.choice("abc")), bevel=0.02)
		return
	# Heavy footing blocks all around, a stepped plinth, then the floor on top.
	sty = STYLE
	gbox((0, (h - 0.1) / 2, 0), (w - 0.02, h - 0.1, dd - 0.02), kit.mat("charcoal", 1.6), bevel=0, wobble=0)
	for side in range(4):
		for k in range(2):
			for r in range(3):
				y = 0.15 + r * 0.3
				t = (k - 0.5) * w / 2 + (r % 2) * 0.25
				t = max(-w / 2 + w / 4, min(w / 2 - w / 4, t))
				if side < 2:
					c, s = (t, y, (dd / 2 - 0.1) * (1 if side else -1)), (w / 2 - 0.02, 0.28, 0.24)
				else:
					c, s = ((w / 2 - 0.1) * (1 if side == 3 else -1), y, t), (0.24, 0.28, dd / 2 - 0.02)
				gbox(c, s, kit.tex_mat("stone" if sty in ("wood", "metal") else TEX, rng.choice("abc")), bevel=0.025, wobble=0.006)
	gbox((0, h - 0.05, 0), (w + 0.04, 0.1, dd + 0.04), kit.tex_mat("stone" if sty in ("wood", "metal") else TEX, "c"), bevel=0.02, wobble=0.003)


def roof(w=2.0, rise=1.0, dd=2.0):
	hx, hz = w / 2, dd / 2
	t = 0.15
	rt = ROOF_TEX[STYLE]
	base = kit.tex_mat(rt) if rt else tm(None, "b")
	gprism_x([(hz, 0), (hz, t), (-hz, rise), (-hz, 0)], -hx, hx, base)
	# Shingle rows: overlapping strips stepping up the slope.
	L = math.hypot(dd, rise - t)
	ang = math.degrees(math.atan2(rise - t, dd))
	rows = max(3, round(L / 0.4))
	for i in range(rows):
		f = (i + 0.5) / rows
		z = hz - f * dd
		y = t + f * (rise - t) + 0.035
		mat = base if rt else tm(None, "abc"[i % 3])
		gbox((0, y, z), (w + 0.06, 0.035, L / rows + 0.04), mat, bevel=0.008, wobble=0.004, rotx=-ang)
	gbox((0, t / 2, hz + 0.02), (w + 0.06, t + 0.04, 0.06), kit.tex_mat("wood", "dark") if STYLE != "metal" else tm(None, "dark"), bevel=0.01)


def ridge(w=2.0, rise=0.5, dd=2.0):
	hx, hz = w / 2, dd / 2
	rt = ROOF_TEX[STYLE]
	gprism_x([(hz, 0), (hz, 0.12), (0, rise), (-hz, 0.12), (-hz, 0)], -hx, hx, kit.tex_mat(rt) if rt else tm(None, "b"))
	for s_ in (-1, 1):
		L = math.hypot(hz, rise - 0.12)
		ang = math.degrees(math.atan2(rise - 0.12, hz))
		for i in range(3):
			f = (i + 0.5) / 3
			gbox((0, 0.12 + f * (rise - 0.12) + 0.035, s_ * hz * (1 - f)), (w + 0.06, 0.05, L / 3 + 0.05),
				kit.tex_mat(rt) if rt else tm(None, "abc"[i]), bevel=0.01, wobble=0.003, rotx=s_ * ang)
	gbox((0, rise + 0.05, 0), (w + 0.06, 0.12, 0.3), kit.tex_mat("wood", "dark") if STYLE != "metal" else tm(None, "dark"), bevel=0.02)


def roof_corner(w, rise, dd, inner=False):
	hx, hz = w / 2, dd / 2
	rt = ROOF_TEX[STYLE]
	m = kit.tex_mat(rt) if rt else tm(None, "b")
	if not inner:
		v = [(-hx, 0, -hz), (hx, 0, -hz), (hx, 0, hz), (-hx, 0, hz), (-hx, rise, -hz)]
		f = [(0, 1, 2, 3), (0, 4, 1), (0, 3, 4), (1, 4, 2), (2, 4, 3)]
		gmesh(v, f, m)
		tip, low = (-hx, rise, -hz), (hx, 0, hz)
	else:
		v = [(-hx, 0, -hz), (hx, 0, -hz), (hx, 0, hz), (-hx, 0, hz), (-hx, rise, -hz), (hx, rise, -hz), (-hx, rise, hz)]
		f = [(0, 3, 2, 1), (2, 5, 4), (2, 4, 6), (0, 1, 5, 4), (0, 4, 6, 3), (3, 6, 2), (2, 1, 5)]
		gmesh(v, f, m)
		tip, low = (-hx, rise, -hz), (hx, 0, hz)
	# A hip/valley beam along the diagonal.
	mid = tuple((a + b) / 2 for a, b in zip(tip, low))
	L = math.dist(tip, low)
	o = gbox(mid, (0.12, 0.1, L), kit.tex_mat("wood", "dark"), bevel=0.01, wobble=0)
	o.rotation_mode = "QUATERNION"
	from mathutils import Vector
	d = Vector(G(low)) - Vector(G(tip))
	o.rotation_quaternion = d.to_track_quat("Y", "Z")


def gable(w=2.0, rise=1.0, d=0.3):
	hx = w / 2
	gprism_z([(-hx, 0), (hx, 0), (hx, rise)], -d * 0.38, d * 0.38, kit.mat("charcoal", 0.8))
	# Fill in the family's look, stepping up under the slope.
	n = 6
	for i in range(n):
		x0, x1 = -hx + w * i / n, -hx + w * (i + 1) / n
		top = rise * (i + 0.5) / n
		if top > 0.05:
			wall_fill(x0 + 0.005, x1 - 0.005, 0, top, d)
	seg = math.hypot(w, rise)
	gbox((0, rise / 2 + 0.06, 0), (seg, 0.12, d + 0.06), kit.tex_mat("wood", "dark"), bevel=0.012, wobble=0.003,
		rotz=math.degrees(math.atan2(rise, w)))


def pillar(w=0.4, h=2.0):
	timber((0, h / 2, 0), (w, h, w), axis="y")
	cap = kit.tex_mat("stone" if STYLE == "wood" else TEX, "c") if STYLE != "metal" else tm(None, "dark")
	gbox((0, 0.075, 0), (w + 0.15, 0.15, w + 0.15), cap, bevel=0.02, wobble=0.003)
	gbox((0, h - 0.075, 0), (w + 0.15, 0.15, w + 0.15), cap, bevel=0.02, wobble=0.003)


def column_parts(w=0.8, h=2.0, part="all"):
	"""Carved column: plinth + torus base, fluted shaft with bands, flared capital + abacus."""
	stone = kit.tex_mat(TEX if STYLE == "stone" else "marble")
	dark = kit.tex_mat(TEX if STYLE == "stone" else "marble", "b")
	y = 0.0
	if part in ("all", "base"):
		gbox((0, 0.1, 0), (w, 0.2, w), stone, bevel=0.025)
		o = kit.ring(w * 0.4, 0.06, G((0, 0.26, 0)), dark, seg=24)
		gcyl((0, 0.4, 0), w * 0.42, 0.2, stone, verts=20)
		y = 0.35 if part == "all" else 0.0
	if part in ("all", "shaft"):
		y0 = y if part == "all" else 0.0
		hh = (h - 0.65) if part == "all" else 1.0
		gcyl((0, y0 + hh / 2, 0), w * 0.36, hh, stone, verts=16, bevel=0)
		for k in range(12):
			a = 2 * math.pi * k / 12
			gbox((math.cos(a) * w * 0.355, y0 + hh / 2, math.sin(a) * w * 0.355), (0.04, hh * 0.92, 0.04), dark, bevel=0.012, wobble=0, roty=-math.degrees(a))
		for f in ((0.33, 0.66) if part == "all" else (0.5,)):
			kit.ring(w * 0.37, 0.035, G((0, y0 + hh * f, 0)), dark, seg=20)
	if part in ("all", "capital"):
		y0 = (h - 0.3) if part == "all" else 0.0
		if part == "capital":
			gcyl((0, 0.08, 0), w * 0.37, 0.16, stone, verts=20)
			y0 = 0.14
		kit.cone(w * 0.37, w * 0.5, 0.18, G((0, y0 + 0.09, 0)), stone, verts=20, bevel=0.01)
		for k in range(8):
			a = 2 * math.pi * k / 8
			kit.gem(G((math.cos(a) * w * 0.42, y0 + 0.14, math.sin(a) * w * 0.42)), (0.06, 0.06, 0.05), dark, seed=k)
		gbox((0, y0 + 0.24 if part == "all" else 0.4, 0), (w, 0.12 if part == "all" else 0.17, w), stone, bevel=0.025)


def beam(w=2.0, s=0.3):
	timber((0, s / 2, 0), (w, s, s), axis="x")


def brace(w=2.0, h=2.0, d=0.25):
	seg = math.hypot(w, h)
	ang = math.degrees(math.atan2(h, w))
	o = gbox((0, h / 2, 0), (seg - 0.1, 0.22, d), tm(None, "b") if STYLE != "stone" else tm(None, "c"), bevel=0.02, wobble=0.004, rotz=ang)
	for e in (-1, 1):
		gbox((e * (w / 2 - 0.12), h / 2 + e * (h / 2 - 0.12), 0), (0.2, 0.2, d + 0.04), kit.tex_mat(TRIM), bevel=0.01, wobble=0)


def arch(w=2.0, h=1.0, d=0.4):
	hx = w / 2
	for s_ in (-1, 1):
		timber((s_ * (hx - 0.15), h / 2, 0), (0.3, h, d), axis="y")
	timber((0, h - 0.12, 0), (w, 0.24, d), axis="x")
	r = 0.7
	c = (0, h - 0.24 - 0.7, 0)
	for i in range(7):
		a = math.pi * (i + 0.5) / 7
		p = (c[0] - math.cos(a) * (r + 0.12), c[1] + math.sin(a) * (r + 0.12), 0)
		if p[1] > 0.02:
			gbox(p, (math.pi * r / 7 - 0.02, 0.26, d), tm(None, rng.choice("abc")), bevel=0.02, wobble=0.004, rotz=math.degrees(a - math.pi / 2))


def stairs(w=2.0, h=2.0, dd=2.0, count=4):
	for i in range(count):
		hh = (i + 1) * h / count
		dz = dd / count
		z = dd / 2 - (i + 0.5) * dz
		if STYLE == "wood":
			gbox((0, hh - 0.04, z), (w - 0.2, 0.08, dz + 0.02), tm(None, "abc"[i % 3]), bevel=0.01, wobble=0.003)
			gbox((0, hh - 0.18, z + dz / 2 - 0.04), (w - 0.2, 0.2, 0.06), tm(None, "dark"), bevel=0.01, wobble=0.003)
		else:
			gbox((0, hh / 2, z), (w, hh, dz - 0.01), tm(None, rng.choice("abc")), bevel=0.02, wobble=0.004)
	if STYLE == "wood":
		for s_ in (-1, 1):
			seg = math.hypot(dd, h)
			gbox((s_ * (w / 2 - 0.06), h / 2, 0), (0.12, 0.3, seg), tm(None, "dark"), bevel=0.02, wobble=0.003, rotx=math.degrees(math.atan2(h, dd)))


def ramp(w=2.0, h=1.0, dd=2.0):
	"""Solid wedge: low edge at +z (y = 0), full height at -z, same way as the stairs. Slabs up the slope, 4 cleats across."""
	hx, hz = w / 2, dd / 2
	t = 0.07
	gprism_x([(hz, 0), (hz, 0.02), (-hz, h - t), (-hz, 0)], -hx, hx, tm(None, "dark"))
	L = math.hypot(dd, h - t - 0.02)
	ang = math.degrees(math.atan2(h - t - 0.02, dd))
	rows = 5
	for i in range(rows):
		f = (i + 0.5) / rows
		gbox((0, 0.02 + f * (h - t - 0.02) + t / 2 - 0.01, hz - f * dd), (w - 0.03, t, L / rows - 0.015),
			tm(None, rng.choice("abc")), bevel=0.015, rotx=ang)
	cleat = kit.tex_mat("wood", "dark") if STYLE != "metal" else tm(None, "dark")
	for i in range(4):
		f = (i + 0.5) / 4
		gbox((0, 0.02 + f * (h - t - 0.02) + t + 0.012, hz - f * dd), (w - 0.25, 0.045, 0.07), cleat, bevel=0.01, rotx=ang)
	# Side edging along the slope and a sill at the low edge.
	for s_ in (-1, 1):
		gbox((s_ * (hx - 0.04), (h - t) / 2 + 0.02, 0), (0.08, 0.1, L), cleat, bevel=0.012, rotx=ang)
	gbox((0, 0.025, hz - 0.03), (w + 0.02, 0.05, 0.07), cleat, bevel=0.01)


def ladder(w=1.0, h=2.0):
	m = tm(None, "b") if STYLE == "wood" else tm(None, "c")
	for x in (-w * 0.4, w * 0.4):
		gbox((x, h / 2, 0), (0.08, h, 0.08), m, bevel=0.012, wobble=0.003)
	for i in range(int(h / 0.3)):
		gbox((0, 0.2 + i * 0.3, 0), (w * 0.86, 0.05, 0.06), m, bevel=0.01, wobble=0.003)
		for x in (-w * 0.4, w * 0.4):
			kit.rivet(G((x, 0.2 + i * 0.3, 0.05)), kit.tex_mat("iron"), r=0.012)


def railing(w=2.0, h=1.0, d=0.15):
	m = tm(None, "b")
	for x in (-w / 2 + 0.06, 0.0, w / 2 - 0.06):
		gbox((x, h / 2, 0), (0.1, h, 0.1), m, bevel=0.015, wobble=0.003)
		gbox((x, h + 0.02, 0), (0.13, 0.05, 0.13), tm(None, "dark"), bevel=0.01, wobble=0)
	gbox((0, h - 0.05, 0), (w, 0.1, 0.14), tm(None, "c"), bevel=0.015, wobble=0.003)
	gbox((0, h * 0.45, 0), (w, 0.06, 0.06), m, bevel=0.01, wobble=0.003)
	for i in range(8):
		x = -w / 2 + 0.2 + i * (w - 0.4) / 7
		gbox((x, h * 0.25, 0), (0.035, h * 0.4, 0.035), m, bevel=0.006, wobble=0.002)


def door(w=1.0, h=1.8, d=0.12):
	n = 4
	for i in range(n):
		gbox((-w / 2 + w / n * (i + 0.5), h / 2, 0), (w / n - 0.01, h, d), tm(None, "abc"[i % 3]), bevel=0.01, wobble=0.003)
	band = kit.tex_mat("iron")
	for y in (0.35, h - 0.35):
		gbox((0, y, 0), (w - 0.04, 0.08, d + 0.03), band, bevel=0.006, wobble=0)
		for x in (-w * 0.35, 0, w * 0.35):
			for s_ in (-1, 1):
				kit.rivet(G((x, y, s_ * (d / 2 + 0.02))), band, r=0.014)
	gbox((0, h / 2, -d / 2 - 0.02), (0.08, h * 0.8, 0.03), band, bevel=0.004, wobble=0, rotz=35)
	kit.ring(0.05, 0.012, G((w * 0.33, h * 0.5, d / 2 + 0.05)), band, rot=(0, 0, 0), seg=12)
	gbox((w * 0.33, h * 0.5 + 0.06, d / 2 + 0.02), (0.06, 0.06, 0.03), band, bevel=0.004, wobble=0)


def ceiling_panel(w=2.0, t=0.25, dd=2.0):
	floor(w, t, dd)
	for x in (-w / 2 + 0.15, w / 2 - 0.15):
		gbox((x, t + 0.02, 0), (0.12, 0.06, dd), kit.tex_mat(TRIM), bevel=0.004, wobble=0)


def mine_prop(w=2.0, h=3.0, d=0.4):
	for x in (-0.8, 0.8):
		gbox((x, (h - 0.3) / 2, 0), (0.3, h - 0.3, 0.3), kit.tex_mat("wood", "b"), bevel=0.02, wobble=0.005)
		gbox((x, 0.06, 0), (0.42, 0.12, 0.42), kit.tex_mat("stone", "dark"), bevel=0.02, wobble=0.005)
	gbox((0, h - 0.15, 0), (w, 0.3, d), kit.tex_mat("wood", "dark"), bevel=0.02, wobble=0.004)
	for x in (-0.8, 0.8):
		gbox((x, h - 0.3 - 0.25, 0.18), (0.32, 0.06, 0.03), kit.tex_mat("iron"), bevel=0.004, wobble=0, rotz=45 if x < 0 else -45)


def diagonal(kind="wall", h=2.0):
	"""Diagonal pieces stand on the line (-1,-1)->(1,1); build straight along x, then turn -45 deg about up."""
	before = set(bpy.data.objects)
	seg = math.hypot(2, 2)
	if kind == "railing":
		railing(seg, h, 0.15)
	elif kind == "window":
		wall(seg, h, 0.3, opening=(1.0, 0.8, 0.6))
	else:
		wall(seg, h, 0.3)
	turn = Matrix.Rotation(math.radians(-45), 4, "Z")
	for o in set(bpy.data.objects) - before:
		o.matrix_world = turn @ o.matrix_world


# ---------- decor (Claude 1's Decor tab; size boxes agreed: x, y, z, origin bottom-centre, front +Z) ----------
def wood_or(kind="b"):
	return kit.tex_mat("wood" if TEX not in ("mushwood",) else "mushwood", kind) if STYLE == "wood" else tm(None, kind)


def table():
	top = wood_or("c")
	gbox((0, 0.84, 0), (2.0, 0.12, 1.0), top, bevel=0.025)
	for x in (-0.85, 0.85):
		for z in (-0.38, 0.38):
			gbox((x, 0.39, z), (0.14, 0.78, 0.14), wood_or("b"), bevel=0.02)
		gbox((x, 0.18, 0), (0.1, 0.1, 0.7), wood_or("dark"), bevel=0.015)
	gbox((0, 0.18, 0), (1.6, 0.1, 0.1), wood_or("dark"), bevel=0.015)
	kit.tcyl("wood", 0.07, 0.12, G((0.4, 0.96, 0.1)), verts=10, variant="c")
	kit.tcyl("iron", 0.09, 0.03, G((-0.5, 0.915, -0.15)), verts=12)


def bench():
	gbox((0, 0.44, 0), (2.0, 0.08, 0.45), wood_or("c"), bevel=0.02)
	for x in (-0.75, 0.75):
		gbox((x, 0.2, 0), (0.12, 0.4, 0.38), wood_or("b"), bevel=0.02)
	gbox((0, 0.16, 0), (1.5, 0.08, 0.08), wood_or("dark"), bevel=0.012)


def chair():
	gbox((0, 0.46, 0.02), (0.56, 0.07, 0.52), wood_or("c"), bevel=0.018)
	for x in (-0.24, 0.24):
		for z in (-0.2, 0.22):
			gbox((x, 0.23, z), (0.07, 0.46, 0.07), wood_or("b"), bevel=0.012)
	for x in (-0.24, 0.24):
		gbox((x, 0.78, -0.22), (0.08, 0.64, 0.08), wood_or("b"), bevel=0.012)
	for y in (0.7, 0.9, 1.06):
		gbox((0, y, -0.22), (0.5, 0.08, 0.05), wood_or("dark"), bevel=0.01)


def shelf():
	for x in (-0.76, 0.76):
		gbox((x, 0.9, 0), (0.08, 1.8, 0.38), wood_or("b"), bevel=0.015)
	for y in (0.06, 0.6, 1.15, 1.72):
		gbox((0, y, 0), (1.5, 0.05, 0.36), wood_or("c"), bevel=0.012)
	gbox((0, 0.9, -0.18), (1.5, 1.8, 0.03), wood_or("dark"), bevel=0.005)
	for (x, y) in ((-0.5, 0.63), (-0.3, 0.63), (0.4, 1.18)):
		kit.tcyl("clay", 0.07, 0.18, G((x, y + 0.09, 0)), verts=10, variant="b")
	kit.tbox("leather", GS((0.3, 0.1, 0.22)), G((0.2, 0.68, 0)), variant="dark", bevel=0.01)
	kit.tcyl("wood", 0.09, 0.14, G((-0.4, 1.25, 0)), verts=10, variant="c")


def barrel():
	"""F61: wide copper bands that hug the bulging staves (sized to the barrel at their height), a lid with
	a handle, and a copper tap."""
	o = kit.cylinder(0.33, 0.9, G((0, 0.45, 0)), tm(None, "b") if STYLE == "wood" else kit.tex_mat("wood", "b"), verts=16, bevel=0.02)
	for v in o.data.vertices:
		t = v.co.z / 0.45
		k = 1.0 + 0.1 * (1 - t * t)
		v.co.x *= k
		v.co.y *= k
	band = kit.tex_mat("copper", "b")
	for y in (0.12, 0.32, 0.58, 0.78):
		t = (y - 0.45) / 0.45
		r = 0.33 * (1.0 + 0.1 * (1 - t * t)) * math.cos(math.pi / 16) + 0.006
		kit.cylinder(r, 0.07, G((0, y, 0)), band, verts=16, bevel=0.004)
		for k in range(4):
			a = 2 * math.pi * k / 4 + 0.4
			kit.rivet(G((math.cos(a) * (r + 0.004), y, math.sin(a) * (r + 0.004))), kit.tex_mat("copper", "dark"), r=0.012)
	kit.cylinder(0.31, 0.03, G((0, 0.905, 0)), kit.tex_mat("wood", "c"), verts=16, bevel=0.004)
	gbox((0, 0.94, 0), (0.22, 0.04, 0.05), kit.tex_mat("copper", "b"), bevel=0.008)
	for x in (-0.1, 0.1):
		gbox((x, 0.925, 0), (0.04, 0.04, 0.05), kit.tex_mat("copper", "b"), bevel=0.006)
	kit.cylinder(0.025, 0.1, G((0, 0.25, 0.37)), kit.tex_mat("copper", "b"), rot=(90, 0, 0), verts=8, bevel=0.004)
	gbox((0, 0.22, 0.41), (0.03, 0.06, 0.03), kit.tex_mat("copper", "b"), bevel=0.004)


def crate():
	m = wood_or("b")
	for y in (0.06, 0.74):
		gbox((0, y, 0), (0.9, 0.12, 0.9), wood_or("dark"), bevel=0.012)
	for k in range(4):
		gbox((-0.33 + k * 0.22, 0.4, 0.43), (0.2, 0.56, 0.04), m, bevel=0.008)
		gbox((-0.33 + k * 0.22, 0.4, -0.43), (0.2, 0.56, 0.04), m, bevel=0.008)
		gbox((0.43, 0.4, -0.33 + k * 0.22), (0.04, 0.56, 0.2), m, bevel=0.008)
		gbox((-0.43, 0.4, -0.33 + k * 0.22), (0.04, 0.56, 0.2), m, bevel=0.008)
	gbox((0, 0.4, 0.46), (0.95, 0.08, 0.03), wood_or("dark"), bevel=0.006, rotz=34)
	for (x, z) in ((-0.45, -0.45), (0.45, -0.45), (0.45, 0.45), (-0.45, 0.45)):
		gbox((x, 0.4, z), (0.06, 0.8, 0.06), kit.tex_mat("iron"), bevel=0.006)


def rug():
	gbox((0, 0.012, 0), (2.0, 0.024, 1.4), kit.tex_mat("rugcloth"), bevel=0.006)
	gbox((0, 0.026, 0), (1.6, 0.006, 1.0), kit.tex_mat("rugcloth", "dark"), bevel=0, wobble=0)
	gbox((0, 0.03, 0), (1.2, 0.004, 0.6), kit.tex_mat("rugcloth", "c"), bevel=0, wobble=0)
	for x in (-1.02, 1.02):
		for k in range(12):
			gbox((x, 0.01, -0.62 + k * 0.113), (0.06, 0.012, 0.02), kit.tex_mat("rope"), bevel=0, wobble=0)


def banner():
	pole = kit.tex_mat("copper") if STYLE == "metal" else kit.tex_mat("wood", "dark")
	gcyl((0, 1.95, -0.02), 0.035, 1.0, pole, verts=8, axis="x")
	for x in (-0.52, 0.52):
		kit.gem(G((x, 1.95, -0.02)), (0.045, 0.045, 0.045), kit.tex_mat("copper"), seed=2)
	cloth = kit.tex_mat("bannercloth")
	verts, faces = [], []
	cols, rows = 6, 10
	for j in range(rows + 1):
		y = 1.9 - j * 0.17
		for i in range(cols + 1):
			x = -0.42 + i * 0.84 / cols
			tail = 0.0
			if j == rows:
				tail = -0.18 * (1 - abs(x) / 0.42)
			z = -0.02 + 0.015 * math.sin(i * 1.4 + j * 0.6)
			verts.append((x, y + tail, z))
	for j in range(rows):
		for i in range(cols):
			a = j * (cols + 1) + i
			faces.append((a, a + 1, a + cols + 2, a + cols + 1))
	n = len(verts)
	verts += [(x, y, z - 0.012) for (x, y, z) in verts]
	faces += [tuple(reversed([v + n for v in f])) for f in faces]
	gmesh(verts, faces, cloth, smooth=True)
	gbox((0, 1.25, 0.0), (0.4, 0.4, 0.01), kit.tex_mat("copper"), bevel=0.004, wobble=0, roty=0)
	kit.gem(G((0, 1.25, 0.02)), (0.12, 0.03, 0.12), kit.tex_mat("copper", "c"), seed=5)


def wall_shield():
	r = 0.33
	gcyl((0, 0.35, -0.03), r, 0.06, kit.tex_mat("wood", "b"), verts=20, axis="z")
	rim = kit.tex_mat("copper") if STYLE == "metal" else kit.tex_mat("iron")
	kit.ring(r, 0.022, G((0, 0.35, -0.0)), rim, rot=(90, 0, 0), seg=24)
	kit.cylinder(0.08, 0.04, G((0, 0.35, 0.02)), kit.tex_mat("copper"), rot=(90, 0, 0), verts=12, bevel=0.01)
	for a in (35, -35):
		gbox((0, 0.35, 0.03), (0.06, 0.9, 0.04), kit.tex_mat("iron", "c"), bevel=0.006, wobble=0, rotz=a)
	for k in range(8):
		ang = 2 * math.pi * k / 8
		kit.rivet(G((math.cos(ang) * (r - 0.05), 0.35 + math.sin(ang) * (r - 0.05), 0.01)), kit.tex_mat("iron"), r=0.012)


def wall_sconce():
	back = tm(None, "b") if STYLE == "stone" else kit.tex_mat("iron", "dark")
	gbox((0, 0.3, -0.12), (0.22, 0.5, 0.06), back, bevel=0.012)
	arm = kit.tex_mat("copper") if STYLE == "metal" else kit.tex_mat("iron")
	gbox((0, 0.25, -0.03), (0.04, 0.04, 0.18), arm, bevel=0.004)
	kit.cone(0.1, 0.05, 0.08, G((0, 0.3, 0.06)), arm, verts=10)
	kit.ring(0.1, 0.012, G((0, 0.34, 0.06)), arm, seg=12)
	kit.COLORS.setdefault("glow_cyan", (0.3, 0.9, 0.95))
	kit.crystal_cluster(G((0, 0.33, 0.06)), 0.55, kit.glow("glow_cyan", 0.5), seed=3, n=5)


def weapon_rack():
	m = wood_or("b")
	for x in (-0.62, 0.62):
		gbox((x, 0.8, 0), (0.1, 1.6, 0.1), m, bevel=0.015)
		gbox((x, 0.04, 0), (0.12, 0.08, 0.48), wood_or("dark"), bevel=0.015)
	for y in (0.3, 1.25):
		gbox((0, y, 0.0), (1.34, 0.08, 0.1), wood_or("dark"), bevel=0.012)
	for k in range(5):
		gbox((-0.48 + k * 0.24, 1.32, 0.06), (0.04, 0.06, 0.06), wood_or("c"), bevel=0.006)
	# Two spears and an axe leaning in the rack.
	for (x, a) in ((-0.4, 4), (0.0, -3)):
		gbox((x, 0.75, 0.06), (0.04, 1.5, 0.04), kit.tex_mat("wood", "c"), bevel=0.006, wobble=0, rotz=a)
		kit.cone(0.04, 0.0, 0.18, G((x - math.sin(math.radians(a)) * 0.75, 1.58, 0.06)), kit.tex_mat("iron"), verts=4)
	gbox((0.38, 0.7, 0.06), (0.04, 1.2, 0.04), kit.tex_mat("wood", "c"), bevel=0.006, wobble=0)
	gbox((0.47, 1.2, 0.06), (0.16, 0.2, 0.025), kit.tex_mat("iron"), bevel=0.006, wobble=0)



P = {
	"foundation": lambda: foundation(), "foundation_half": lambda: foundation(2, 1, 1),
	"foundation_steps": lambda: foundation(steps=True), "foundation_triangle": lambda: foundation(triangle=True),
	"floor": lambda: floor(), "floor_half": lambda: floor(2, 0.25, 1), "small_floor": lambda: floor(1, 0.25, 1),
	"floor_triangle": lambda: floor(triangle=True),
	"wall": lambda: wall(), "wall_narrow": lambda: wall(1.0), "half_wall": lambda: wall(2.0, 1.0),
	"doorway": lambda: wall(opening=(1.0, 1.8, 0)), "arch_doorway": lambda: wall(opening=(1.2, 1.9, 0), arch=True),
	"window_wall": lambda: wall(opening=(1.0, 0.8, 0.6)), "window_wide": lambda: wall(opening=(1.6, 0.9, 0.6)),
	"gable_26": lambda: gable(2, 1.0), "gable_45": lambda: gable(2, 2.0), "door": lambda: door(),
	"roof_26": lambda: roof(2, 1.0), "roof_45": lambda: roof(2, 2.0),
	"roof_26_ridge": lambda: ridge(2, 0.5), "roof_45_ridge": lambda: ridge(2, 1.0),
	"roof_26_outer": lambda: roof_corner(2, 1.0, 2), "roof_26_inner": lambda: roof_corner(2, 1.0, 2, True),
	"roof_45_outer": lambda: roof_corner(2, 2.0, 2), "roof_45_inner": lambda: roof_corner(2, 2.0, 2, True),
	"beam": lambda: beam(), "beam_half": lambda: beam(1.0), "brace": lambda: brace(), "pillar": lambda: pillar(),
	"column": lambda: column_parts(), "column_base": lambda: column_parts(part="base"),
	"column_shaft": lambda: column_parts(part="shaft"), "column_capital": lambda: column_parts(part="capital"),
	"arch": lambda: arch(), "stairs": lambda: stairs(), "ramp": lambda: ramp(), "ladder": lambda: ladder(), "railing": lambda: railing(),
	"wall_diagonal": lambda: diagonal("wall"), "half_wall_diagonal": lambda: diagonal("wall", 1.0),
	"window_diagonal": lambda: diagonal("window"), "railing_diagonal": lambda: diagonal("railing", 1.0),
	"ceiling_panel": lambda: ceiling_panel(), "mine_prop": lambda: mine_prop(),
	"table": table, "bench": bench, "chair": chair, "shelf": shelf, "barrel": barrel, "crate": crate, "rug": rug,
	"banner": banner, "wall_shield": wall_shield, "wall_sconce": wall_sconce, "weapon_rack": weapon_rack,
}

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT.mkdir(parents=True, exist_ok=True)
JOUR.mkdir(parents=True, exist_ok=True)
SHACK_V2 = {f"{n}__plank_root" for n in ("ramp", "ladder", "brace", "mine_prop", "wall_narrow", "window_wide")}  # made by shack_v2.py now
for key in args:
	if key in SHACK_V2:
		print(f"SKIP {key}: built by builds/shack_v2.py")
		continue
	piece, family = key.split("__")
	STYLE, TEX, TRIM = FAM[family]
	if ROOF_TEX[STYLE] and not (kit.TEX / f"{ROOF_TEX[STYLE]}_a.png").exists():
		ROOF_TEX[STYLE] = None
	rng.seed(hash(key) & 0xFFFF)
	kit.reset()
	try:
		P[piece]()
		out = OUT / f"{key}.glb"
		kit.save(str(out), str(JOUR / f"{key}.png"), recenter=False, tex_size=256)
		shutil.copy(out, JOUR / f"{key}.glb")
	except Exception as e:
		import traceback
		traceback.print_exc()
		print(f"PIECE_FAILED {key}: {e!r}")
