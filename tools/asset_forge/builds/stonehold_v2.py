# Stonehold, version 2 (owner, Nov 17): set 1 rebuilt to match the turnaround sheet
# assets/concepts/building-kit/stonehold_turnaround_4pieces.png (front / side / back / top views) and the kit sheet
# stonehold_kit_sheet_v2.png. Chunky chisel-cut blocks (flat facets, chamfered edges, every stone different),
# interlocking corner quoins, flagstone tops, dark timber with riveted copper bands, a round doorway ringed by
# wedge stones with a rune keystone.
#   blender --background --factory-startup --python builds/stonehold_v2.py -- [grey] [out=<folder>] [piece ...]
# Pieces: foundation, wall, doorway, door, flat_roof, battlement. "grey" = one plain white material (shape check).
# Default output folder: journey/stonehold_v2/glb (the game's files are only replaced after the owner's OK).
import math
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kit  # noqa: E402
import kit_zone1 as K  # noqa: E402

K.S = "stone"
J, blk = K.J, K.blk
E = 0.006          # every outer face stays this far inside the piece box (Rule 2)
DOOR_R, DOOR_CY = 0.78, 0.70   # the round door (Rule 5)
OUT_DEFAULT = K.GAME / "journey" / "stonehold_v2" / "glb"
K.SIZE.update({"gateway": (4, 4, 0.3), "gate_leaf": (1.6, 3.6, 0.15), "gate_broken": (1.7, 0.3, 3.7),
	"straw_dummy": (1.0, 1.9, 1.0), "archery_target": (1.2, 1.7, 1.6), "spear_rack": (1.6, 2.0, 0.4),
	"door_broken": (2.0, 0.3, 1.8), "ruin_wall_worn": (2, 2, 0.3), "ruin_wall_collapsed": (2, 2, 0.3), "ruin_rubble": (1.6, 0.7, 1.6),
	"wall_narrow": (1, 2, 0.3), "window_wide": (2, 2, 0.3), "floor_half": (2, 0.25, 1), "small_floor": (1, 0.25, 1),
	"ramp": (2, 1, 2), "stairs_corner": (2, 2, 2), "stairs_spiral": (4, 3, 4), "stairs_spiral_stacked": (4, 3, 4), "railing_stairs": (2, 3, 0.15)})   # outline checks for pieces kit_zone1 doesn't list


def stone_m():
	return K.T("greystone")


def mortar_m():
	return kit.tex_mat("greystone", "dark")


def timber_m():
	return kit.tex_mat("wood", "dark")


def copper_m():
	return kit.tex_mat("copper", "b")


def _tag(objs, role):
	for o in objs:
		o["role"] = role
	return objs


def _new_since(before):
	return [o for o in bpy.data.objects if o not in before]


def chisel(o, cut=0.03, dent=0.022, seed_cuts=1, axes=(0, 1, 2)):
	"""Make a plain box look hand-cut: split each face once, push the new points a little INWARD only (so the
	stone never grows past its box), then chamfer the edges flat (one segment = a chisel cut, not a soft round).
	axes = which local axes may be dented: faces that press against a neighbour stone stay flat, so stones sit
	tight on and beside each other (owner, Nov 17: no gaps or holes between stones)."""
	me = o.data
	bm = bmesh.new()
	bm.from_mesh(me)
	if seed_cuts:
		bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=seed_cuts, use_grid_fill=True)
	half = Vector((max(abs(v.co.x) for v in bm.verts), max(abs(v.co.y) for v in bm.verts), max(abs(v.co.z) for v in bm.verts)))
	for v in bm.verts:
		for k in axes:
			c = v.co[k]
			if abs(c) > half[k] * 0.99:  # an outer face point: dent it in a little
				v.co[k] = c - math.copysign(K.rng.uniform(0.0, dent), c)
			else:  # a middle point: wobble along the face, stays inside
				v.co[k] = c + K.rng.uniform(-dent, dent) * 0.5
	bm.to_mesh(me)
	bm.free()
	for m_ in list(o.modifiers):
		o.modifiers.remove(m_)
	b = o.modifiers.new("chisel", "BEVEL")
	b.width = cut * K.rng.uniform(0.75, 1.25)
	b.segments = 1
	b.limit_method = "ANGLE"
	b.angle_limit = math.radians(35)
	for p in me.polygons:
		p.use_smooth = False
	return o


GODOT_AXIS = {"x": 0, "y": 2, "z": 1}   # Godot axis -> the box's own (Blender) axis


def block(c, s, m=None, cut=0.03, tilt=0.12, dent=0.02, free="xyz"):
	"""One chunky cut stone: centre c, size s (Godot space), a hair of tilt, chisel-cut. `free` = the Godot
	axes whose faces are open to the air (they get dents); the others touch a neighbour and stay flat."""
	o = blk(c, s, m or stone_m(), bevel=0, rz=J(tilt), rx=J(tilt * 0.4))
	chisel(o, cut=cut, dent=dent, axes=tuple(GODOT_AXIS[a] for a in free))
	o["role"] = "stone"
	return o


def _inset(pts, c):
	"""The outline pulled `c` inward at every corner (mitred, capped at 3c so sharp corners don't fly off)."""
	n = len(pts)
	area2 = sum(pts[i][0] * pts[(i + 1) % n][1] - pts[(i + 1) % n][0] * pts[i][1] for i in range(n))
	sgn = 1.0 if area2 > 0 else -1.0   # counter-clockwise outlines: inside is to the left of each edge
	out = []
	for i in range(n):
		p, v, q = Vector(pts[i - 1]), Vector(pts[i]), Vector(pts[(i + 1) % n])
		e1, e2 = (v - p), (q - v)
		if e1.length < 1e-6 or e2.length < 1e-6:
			out.append(tuple(v))
			continue
		e1.normalize()
		e2.normalize()
		n1, n2 = Vector((-e1.y, e1.x)) * sgn, Vector((-e2.y, e2.x)) * sgn
		k = 1.0 + n1.dot(n2)
		m = (n1 + n2) * (c / k) if k > 0.15 else (n1 + n2).normalized() * c * 3.0
		if m.length > 3 * c:
			m = m.normalized() * 3 * c
		out.append(tuple(v + m))
	return out


def prism(fr, pts, z, d, m=None, cut=0.03, role="stone"):
	"""A stone with any outline (wedge stones, stones cut to the doorway's curve), chisel-cut like every other
	stone (owner, Nov 17: they looked like flat bricks): the front and back faces are the outline pulled in by
	`cut`, joined to the full outline by slanted chisel faces. Built by hand (Blender's automatic edge cut
	misbehaved on curved outlines and poked out of the wall), so it never reaches past its outline."""
	c = cut * K.rng.uniform(0.75, 1.1)
	inner = _inset(pts, c)
	n = len(pts)
	h = d / 2
	rings = [(inner, -h), (pts, -(h - c)), (pts, h - c), (inner, h)]
	verts = []
	for (ring, zz) in rings:
		for (x, y) in ring:
			verts.append(fr.p(x, y, z + zz))
	faces = []
	for r in range(3):
		for i in range(n):
			a, b = r * n + i, r * n + (i + 1) % n
			faces.append((a, b, b + n, a + n))
	faces.append(tuple(reversed(range(n))))
	faces.append(tuple(range(3 * n, 4 * n)))
	o = K.mesh(verts, faces, m or stone_m(), smooth=False)
	o["role"] = role
	return o


def backing(fr, x0, x1, y0, y1, d, hole=None):
	"""Layer 1: ONE solid dark sheet inside the wall behind all the stones, so no joint between stones is ever
	see-through (owner, Nov 17). It stays 1 cm inside the wall's outline. hole = (cy, r): a round opening
	(the sheet is then made of a left and a right half, each cut round it)."""
	before = set(bpy.data.objects)
	x0, x1, y0, y1 = x0 + 0.01, x1 - 0.01, y0 + 0.004, y1 - 0.01
	dd = d * 0.62
	if hole and len(hole) == 4:  # a rectangular opening (hl, hr, hb, ht): four pieces round it
		hl, hr, hb, ht = hole
		for (a, b, c, e) in ((x0, x1, y0, hb), (x0, x1, ht, y1), (x0, hl, hb, ht), (hr, x1, hb, ht)):
			if b - a > 0.01 and e - c > 0.01:
				fr.box(((a + b) / 2, (c + e) / 2, 0.0), (b - a, e - c, dd), mortar_m(), bevel=0)
	elif hole:
		cy, r = hole
		for (a, b) in ((x0, 0.0), (0.0, x1)):
			pts = _cut_by_circle(a, b, y0, y1, cy, r)
			if pts:
				K.slab_poly(fr, pts, 0.0, dd, mortar_m())
	else:
		fr.box(((x0 + x1) / 2, (y0 + y1) / 2, 0.0), (x1 - x0, y1 - y0, dd), mortar_m(), bevel=0)
	_tag(_new_since(before), "mortar")


def rivet(p, r=0.02):
	kit.rivet(K.G(p), kit.tex_mat("copper", "dark"), r=r)


def copper_band(x0, x1, y, h, z, face, rivets=None):
	"""A hammered copper band lying on a face (face = +1 front, -1 back), with round rivet heads."""
	before = set(bpy.data.objects)
	z = z - face * 0.01  # sunk 1 cm so the rivet heads stay inside the piece's outline
	blk(((x0 + x1) / 2, y, z), (x1 - x0, h, 0.012), copper_m(), bevel=0.003)
	r = min(0.018, h * 0.28)
	for x in (rivets if rivets is not None else (x0 + 0.06, x1 - 0.06)):
		rivet((x, y, z + face * (0.006 + 0.008 - r)), r=r)  # a dome 8 mm proud of the band
	_tag(_new_since(before), "copper")


# ---------------- walls: courses of chunky blocks with corner quoins ----------------
ROW_H = (0.22, 0.27)
BLOCK_L = (0.34, 0.56)
QUOIN = (0.44, 0.26)   # long / short corner stones, alternating row to row (the joins picture)


def _cut_by_circle(a, b, ya, yb, cy, R, n=24):
	"""The exact outline of the rectangle [a,b] x [ya,yb] with the round opening (centre (0, cy), radius R)
	taken out: walk round the rectangle; where it dips into the opening, follow the circle instead (an arc
	from where it went in to where it came out). Returns [] when almost nothing is left."""
	def ins(p):
		return p[0] * p[0] + (p[1] - cy) ** 2 < R * R

	corners = [(a, ya), (b, ya), (b, yb), (a, yb)]
	samples = []
	for k in range(4):
		p, q = corners[k], corners[(k + 1) % 4]
		for t in range(n):
			samples.append((p[0] + (q[0] - p[0]) * t / n, p[1] + (q[1] - p[1]) * t / n))
	if all(ins(p) for p in samples):
		return []
	start = next(i for i, p in enumerate(samples) if not ins(p))
	samples = samples[start:] + samples[:start]

	def cross(p, q):  # the point between p (outside) and q (inside) that lies on the circle
		lo, hi = 0.0, 1.0
		for _ in range(30):
			m = (lo + hi) / 2
			r = (p[0] + (q[0] - p[0]) * m, p[1] + (q[1] - p[1]) * m)
			if ins(r) == ins(p):
				lo = m
			else:
				hi = m
		return (p[0] + (q[0] - p[0]) * lo, p[1] + (q[1] - p[1]) * lo)

	out, entry = [], None
	m_ = len(samples)
	for i in range(m_):
		p, q = samples[i], samples[(i + 1) % m_]
		if not ins(p):
			out.append(p)
			if ins(q):
				entry = cross(p, q)
				out.append(entry)
		elif not ins(q):
			ex = cross(q, p)
			t0 = math.atan2(entry[1] - cy, entry[0])
			t1 = math.atan2(ex[1] - cy, ex[0])
			while t1 > t0:  # the outline goes round the opening clockwise
				t1 -= math.tau
			steps = max(2, int((t0 - t1) / 0.08))
			for k in range(1, steps):
				t = t0 + (t1 - t0) * k / steps
				out.append((math.cos(t) * R, cy + math.sin(t) * R))
			out.append(ex)
	clean = []
	for pt in out:
		if not clean or abs(clean[-1][0] - pt[0]) + abs(clean[-1][1] - pt[1]) > 0.003:
			clean.append(pt)
	if len(clean) < 3 or K.area(clean) < 0.006:
		return []
	return clean


def courses(w, h, d, hole=None, y0=E, y1=None, circle=None, back_hole=None, dark_base=True, back=True, zc=0.0, limit=None,
		row_h=None, block_l=None, tight=False, missing=0.0):
	"""Rows of blocks across a wall w wide (centred on x=0), from y0 to y1, full wall thickness d,
	with a dark mortar backing set well inside; hole(ya, yb) -> (hl, hr) cuts an opening.
	circle = (cy, R, kw, ktop): a round opening; the stones beside and above it are cut exactly to it, and the
	rows above it leave a straight-sided gap |x| < kw for the keystone. Returns (blocks, the keystone's top)."""
	y1 = y1 if y1 is not None else h - E
	x0, x1 = -w / 2 + E, w / 2 - E
	if circle:
		cy, R, kw, ktop = circle

		def hole(ya, yb):  # rows beside the opening stop where it is narrowest; the cut follows the circle
			if yb >= cy + R - 0.02:
				return (-kw, kw) if ya < ktop else None  # the keystone's column
			hw = min(math.sqrt(max(0.0, R * R - (y - cy) ** 2)) for y in (ya, yb))
			return (-hw, hw) if hw > 0.02 else None
	blocks, mortar = K.layout(x0, x1, y0, y1, row_h or ROW_H, block_l or BLOCK_L, limit=limit, hole=hole, quoin=QUOIN)
	fr = K.Frame(oz=zc)
	if back and limit:  # a stepped wall: the dark sheet follows the steps (never shows above them)
		rows = {}
		for (a, b, ya, yb, r, end) in blocks:
			lo, hi_, top = rows.get(r, (9.0, -9.0, yb))
			rows[r] = (min(lo, a), max(hi_, b), yb)
		rws = [rows[k] + (k,) for k in sorted(rows)]
		pts = [(x1 - 0.01, y0 + 0.004)]
		pts.append((x1 - 0.01, rws[-1][2] - 0.03))
		for k in range(len(rws) - 1, -1, -1):   # the steps stay 3 cm under the stones' tops (no shimmer, Nov 21)
			lo, hi_, yb, r = rws[k]
			ya = rws[k - 1][2] if k > 0 else y0
			pts += [(lo + 0.03, yb - 0.03), (lo + 0.03, ya - 0.03)]
		pts[-1] = (pts[-1][0], y0 + 0.004)
		before = set(bpy.data.objects)
		K.slab_poly(fr, pts, 0.0, d * 0.62, mortar_m())
		_tag(_new_since(before), "mortar")
	elif back:
		backing(fr, x0, x1, y0, y1, d, hole=back_hole)
	g = 0.003  # stones sit tight; only the chamfered edges show the joints
	for (a, b, ya, yb, r, end) in blocks:
		if missing and r > 0 and K.rng.random() < missing:
			continue   # a ruin: this stone fell out
		m = stone_m()
		if r == 0 and dark_base:  # the dark base row (turnaround sheet)
			m = kit.tex_mat("greystone", "dark")
		dd = d - 2 * E - K.rng.uniform(0.004, 0.012)
		if tight:  # slices that press against each other (stairs): full depth, flat faces, so no gaps between them
			dd = d - 0.001
		if circle:
			g2 = g / 2
			pts = _cut_by_circle(a + g2, b - g2, ya + g2, yb - g2, cy, R + g2)
			full = [(a + g2, ya + g2), (b - g2, ya + g2), (b - g2, yb - g2), (a + g2, yb - g2)]
			if not pts:
				continue
			if K.area(pts) < K.area(full) - 0.001:  # touched by the opening: a stone cut to the curve
				prism(fr, pts, 0.0, dd, m, cut=0.022)
				continue
		block(((a + b) / 2, (ya + yb) / 2, zc), (b - a - g, yb - ya - g, dd), m, cut=K.rng.uniform(0.025, 0.04), dent=0.012,
			free="" if tight else "z")
	if circle:  # the keystone reaches up to the top of the last row that left room for it
		tops = [yb for (a, b, ya, yb, r, end) in blocks if ya < ktop and yb >= cy + R - 0.02]
		return blocks, (max(tops) if tops else ktop)
	return blocks


def wall(w=2.0, h=2.0, d=0.3):
	courses(w, h, d)


def ring_stones(cy, r_in, r_out, d, n=13, key_h=0.2, a0=None):
	"""Wedge stones round a circle cut flat at the floor, alternating light and dark, with a bigger carved
	keystone at the top (its rune is painted on later)."""
	fr = K.Frame()
	a0 = math.asin(max(-1.0, -cy / r_out)) if a0 is None else a0
	a1 = math.pi - a0
	span = (a1 - a0)
	g = 0.003
	for i in range(n):
		t0, t1 = a0 + span * i / n, a0 + span * (i + 1) / n
		mid = (t0 + t1) / 2
		key = i == n // 2
		ro = r_out + (key_h if key else 0.0)  # an even outer edge, so the wall stones sit tight against it
		ri = r_in
		dt = g / ri
		pts = []
		for k in range(4):  # inner arc
			t = t0 + dt + (t1 - t0 - 2 * dt) * k / 3
			pts.append((math.cos(t) * ri, cy + math.sin(t) * ri))
		dto = g / ro
		if key:  # the keystone: wedge sides out to the ring's edge, then straight up (the turnaround picture)
			xr, yr = math.cos(t0 + dto) * r_out, cy + math.sin(t0 + dto) * r_out
			xl, yl = math.cos(t1 - dto) * r_out, cy + math.sin(t1 - dto) * r_out
			pts += [(xl, yl), (xl, cy + ro), (xr, cy + ro), (xr, yr)]  # the inner arc ended on the left
		else:
			for k in range(4):  # outer arc, back the other way
				t = t1 - dto - (t1 - t0 - 2 * dto) * k / 3
				pts.append((math.cos(t) * ro, cy + math.sin(t) * ro))
		pts = [(x, max(E, y)) for (x, y) in pts]
		m = kit.tex_mat("greystone", "dark") if i % 2 else stone_m()
		if key:
			m = kit.tex_mat("greystone", "c")
		prism(fr, pts, 0.0, d - 2 * E - (0.006 if key else K.rng.uniform(0.006, 0.014)), m, cut=0.03, role="keystone" if key else "stone")


def doorway(w=2.0, h=2.0, d=0.3):
	"""Round doorway wall: block courses cut round a ring of wedge stones and a carved keystone on top."""
	r_in = DOOR_R + 0.01
	r_out = r_in + 0.15
	key_h = 0.16

	half_key = (math.pi - 2 * math.asin(max(-1.0, -DOOR_CY / r_out))) / 13 / 2   # ring_stones: 13 wedges
	kx = r_out * math.sin(half_key)   # the keystone's straight sides
	_, key_top = courses(w, h, d, circle=(DOOR_CY, r_out + 0.002, kx + 0.002, DOOR_CY + r_out + key_h),
		back_hole=(DOOR_CY, r_in + 0.04))   # the dark sheet runs behind the ring stones too
	ring_stones(DOOR_CY, r_in, r_out, d, key_h=key_top - DOOR_CY - r_out - 0.0015)
	# (no copper bands beside the ring: owner, Nov 17)


def half_wall(w=2.0, h=1.0, d=0.3):
	courses(w, h, d)


def wall_narrow(w=1.0, h=2.0, d=0.3):
	courses(w, h, d)


def iron_m():
	return kit.tex_mat("iron", "dark")


def window_wall(w=2.0, h=2.0, d=0.3, ow=0.8, oh=0.7, ob=0.75, bars=3):
	"""Stone window wall (the kit sheet): a square opening with an iron grille, a heavy dark timber lintel with
	copper end plates over it, and a long sill stone under it. Stone rows below, beside and above, all tight."""
	ot = ob + oh
	lh = 0.17                       # lintel height
	lw = ow + 0.36                  # the lintel rests 18 cm into the wall on each side
	x0, x1 = -w / 2 + E, w / 2 - E
	fr = K.Frame()
	backing(fr, x0, x1, E, h - E, d, hole=(-ow / 2 - 0.015, ow / 2 + 0.015, ob - 0.015, ot + 0.015))
	sill_h = 0.1
	courses(w, h, d, y0=E, y1=ob - sill_h, back=False)                                    # below the sill
	courses(w, h, d, y0=ob - sill_h, y1=ob, hole=lambda ya, yb: (-ow / 2 - 0.12, ow / 2 + 0.12), dark_base=False, back=False)
	block((0, ob - sill_h / 2, 0.0), (ow + 0.24 - 0.003, sill_h - 0.003, d - 2 * E - 0.004), kit.tex_mat("greystone", "c"), cut=0.03, tilt=0.0, free="z")
	courses(w, h, d, y0=ob, y1=ot, hole=lambda ya, yb: (-ow / 2, ow / 2), dark_base=False, back=False)    # beside the opening
	courses(w, h, d, y0=ot, y1=ot + lh, hole=lambda ya, yb: (-lw / 2, lw / 2), dark_base=False, back=False)  # beside the lintel
	before = set(bpy.data.objects)
	blk((0, ot + lh / 2, 0), (lw - 0.004, lh - 0.004, d - 2 * E - 0.006), timber_m(), bevel=0.012)
	_tag(_new_since(before), "timber")
	for sx in (-1, 1):  # copper end plates on the lintel's face (front and back), sunk level with the stones
		for face in (1, -1):
			copper_band(sx * (lw / 2 - 0.13) - 0.06, sx * (lw / 2 - 0.13) + 0.06, ot + lh / 2, lh - 0.05, face * (d / 2 - E - 0.004), face,
				rivets=(sx * (lw / 2 - 0.13),))
	if ot + lh < h - E - 0.05:
		courses(w, h, d, y0=ot + lh, y1=h - E, dark_base=False, back=False)               # above the lintel
	before = set(bpy.data.objects)  # the iron grille: upright bars and two cross bars, ends touching the stone
	for i in range(bars):
		x = -ow / 2 + ow * (i + 1) / (bars + 1)
		kit.cylinder(0.018, oh - 0.004, K.G((x, ob + oh / 2, 0.0)), iron_m(), verts=8, bevel=0.002)
	for y in (ob + oh * 0.33, ob + oh * 0.67):
		blk((0, y, 0.0), (ow - 0.004, 0.03, 0.026), iron_m(), bevel=0.004)
	_tag(_new_since(before), "iron")


def window_wide(w=2.0, h=2.0, d=0.3):
	window_wall(w, h, d, ow=1.3, oh=0.75, ob=0.75, bars=5)


def pillar(w=0.4, h=2.0, d=0.4):
	"""Stone pillar (the kit sheet): a wide base stone, a shaft of stacked stones with a riveted copper band in
	the middle, and a wide cap stone. A dark core runs up the middle so no joint is see-through."""
	bh, ch = 0.26, 0.22
	sw = w - 0.08
	before = set(bpy.data.objects)
	blk((0, h / 2, 0), (sw - 0.07, h - 0.1, sw - 0.07), mortar_m(), bevel=0)
	_tag(_new_since(before), "mortar")
	block((0, E + 0.002 + (bh - E - 0.004) / 2, 0), (w - 2 * E - 0.004, bh - E - 0.004, w - 2 * E - 0.004), kit.tex_mat("greystone", "dark"), cut=0.04, tilt=0.0, free="xz")
	top = h - E - ch
	n = 5
	ys = [bh + (top - bh) * i / n for i in range(n + 1)]
	for i in range(n):
		block((J(0.004), ys[i] + (ys[i + 1] - ys[i]) / 2, J(0.004)), (sw - K.rng.uniform(0.0, 0.02), ys[i + 1] - ys[i] - 0.003, sw - K.rng.uniform(0.0, 0.02)),
			stone_m(), cut=0.035, tilt=0.0, free="xz")
	block((0, top + 0.0015 + (ch - 0.004) / 2, 0), (w - 2 * E - 0.004, ch - 0.004, w - 2 * E - 0.004), stone_m(), cut=0.04, tilt=0.0, free="xz")
	yb = (bh + top) / 2   # the copper band wraps the shaft (its 4 faces), flush with the stone
	before = set(bpy.data.objects)
	for k in range(4):
		fr = K.Frame(yaw=90 * k)
		fr.box((0, yb, sw / 2 - 0.004), (sw - 0.012, 0.09, 0.012), copper_m(), bevel=0.003)
		for xx in (-sw / 3, 0.0, sw / 3):
			kit.rivet(K.G(fr.p(xx, yb, sw / 2 + 0.002)), kit.tex_mat("copper", "dark"), r=0.014)
	_tag(_new_since(before), "copper")


def beam(w=2.0, h=0.3, d=0.3):
	"""Dark timber beam (the kit sheet): a chunky hewn timber with copper caps wrapping both ends, riveted."""
	before = set(bpy.data.objects)
	o = blk((0, h / 2, 0), (w - 2 * E - 0.004, h - 2 * E - 0.024, d - 2 * E - 0.024), timber_m(), bevel=0)
	chisel(o, cut=0.022, dent=0.01)
	_tag(_new_since(before), "timber")
	cap = 0.12
	for sx in (-1, 1):
		before = set(bpy.data.objects)
		xc = sx * (w / 2 - E - 0.002 - cap / 2)
		for k, (dy, dz, sy, sz) in enumerate(((h / 2 - E - 0.007, 0, 0.012, d - 2 * E - 0.004), (-(h / 2 - E - 0.007), 0, 0.012, d - 2 * E - 0.004),
				(0, d / 2 - E - 0.007, h - 2 * E - 0.04, 0.012), (0, -(d / 2 - E - 0.007), h - 2 * E - 0.04, 0.012))):
			blk((xc, h / 2 + dy, dz), (cap, sy, sz), copper_m(), bevel=0.003)
		for zz in (d / 2 - E - 0.004, -(d / 2 - E - 0.004)):
			rivet((xc, h / 2, zz - math.copysign(0.012, zz)), r=0.014)
		_tag(_new_since(before), "copper")


def beam_half():
	beam(1.0)


def door(d=0.12):
	"""Round door: dark upright planks cut to the circle, two riveted copper straps across, a copper ring
	handle; a back batten on the inside. Stays inside the doorway ring."""
	r, cy = DOOR_R - 0.012, DOOR_CY
	fr = K.Frame()
	widths = [0.27, 0.31, 0.25, 0.3, 0.26]
	widths.append(2 * r - sum(widths))
	x = -r
	for i, bw in enumerate(widths):
		a, b = x + K.rng.uniform(0.003, 0.008), x + bw - K.rng.uniform(0.003, 0.008)
		lo = lambda xx: max(E, cy - math.sqrt(max(0.0, r * r - xx * xx)))
		hi = lambda xx: cy + math.sqrt(max(0.0, r * r - xx * xx)) - abs(J(0.01))
		before = set(bpy.data.objects)
		K.plank_shape(fr, a, b, lo, hi, -0.008 + J(0.003), 0.07 * K.rng.uniform(0.92, 1.0), timber_m(), k=8)
		_tag(_new_since(before), "board")
		x += bw
	for y in (cy - 0.36, cy + 0.36):
		hw = math.sqrt(max(0.0, (r - 0.03) ** 2 - (y - cy) ** 2))
		copper_band(-hw, hw, y, 0.085, 0.034, 1, rivets=[-hw + 0.07 + (2 * hw - 0.14) * k / 4 for k in range(5)])
	before = set(bpy.data.objects)
	kit.ring(0.075, 0.014, K.G((0.32, cy - 0.04, 0.04)), copper_m(), rot=(90, 0, 0), seg=16)  # ring handle
	kit.cylinder(0.03, 0.024, K.G((0.32, cy + 0.04, 0.036)), copper_m(), rot=(90, 0, 0), verts=10, bevel=0.003)
	_tag(_new_since(before), "copper")
	for y in (cy - 0.3, cy + 0.3):  # back battens
		hw = math.sqrt(max(0.0, (r - 0.1) ** 2 - (y - cy) ** 2))
		before = set(bpy.data.objects)
		blk((J(0.02), y, -0.041), (2 * hw - 0.04, 0.11, 0.022), timber_m(), bevel=0.006)
		_tag(_new_since(before), "board")


# ---------------- flat things: flagstones ----------------
def flagstones(x0, x1, z0, z1, y0, y1, nx=3, nz=3):
	"""Irregular flagstones over a rectangle (seen from above): a jittered grid, every stone a different
	size, chisel-cut, with a dark mortar bed underneath."""
	before = set(bpy.data.objects)
	blk(((x0 + x1) / 2, y0 + 0.02 + (y1 - y0) * 0.3, (z0 + z1) / 2), (x1 - x0 - 0.1, (y1 - y0) * 0.6, z1 - z0 - 0.1), mortar_m(), bevel=0)
	_tag(_new_since(before), "mortar")
	# Split the area again and again at random places (always across its longer side), so the stones come out
	# in many sizes and the joints never line up into a grid (the turnaround sheet's top views).
	rects, todo = [], [(x0, x1, z0, z1)]
	while todo:
		a, b, c, e = todo.pop()
		wx, wz = b - a, e - c
		if max(wx, wz) < K.rng.uniform(0.5, 0.85) or (wx * wz < 0.42 and K.rng.random() < 0.55):
			rects.append((a, b, c, e))
			continue
		t = K.rng.uniform(0.33, 0.67)
		if wx >= wz:
			m_ = a + wx * t
			todo += [(a, m_, c, e), (m_, b, c, e)]
		else:
			m_ = c + wz * t
			todo += [(a, b, c, m_), (a, b, m_, e)]
	g = 0.004
	for (a, b, c, e) in rects:
		th = (y1 - y0) - K.rng.uniform(0.004, 0.01)
		block(((a + b) / 2, y1 - th / 2 - 0.003, (c + e) / 2), (b - a - g, th, e - c - g), stone_m(), cut=K.rng.uniform(0.03, 0.045), tilt=0.0, dent=0.014, free="y")


def foundation(w=2.0, h=1.0, dd=2.0):
	"""Stone foundation: 4 thick stacked-stone corner piers, a dark timber frame on them with riveted copper
	bands, and a chunky flagstone top flush with the piece's top."""
	top0 = 0.72          # timber frame top = flagstones' bottom
	beam_h, beam_d = 0.17, 0.17
	py = top0 - beam_h   # pier top
	pw = 0.46
	for sx in (-1, 1):
		for sz in (-1, 1):
			cx, cz = sx * (w / 2 - E - pw / 2), sz * (dd / 2 - E - pw / 2)
			hl = py * K.rng.uniform(0.5, 0.58)
			before = set(bpy.data.objects)   # a dark core through the pier, so its joint is never see-through
			blk((cx, (py - 0.04) / 2 + 0.03, cz), (pw - 0.12, py - 0.04, pw - 0.12), mortar_m(), bevel=0)
			_tag(_new_since(before), "mortar")
			block((cx, E + 0.004 + (hl - E - 0.004) / 2, cz), (pw - 0.02, hl - E - 0.004, pw - 0.02), kit.tex_mat("greystone", "dark"), cut=0.04, tilt=0.0, free="xz")
			block((cx + J(0.006), hl + 0.0015 + (py - hl - 0.003) / 2, cz + J(0.006)), (pw - 0.04, py - hl - 0.003, pw - 0.04), stone_m(), cut=0.04, tilt=0.0, free="xz")
	# timber frame: front/back beams full length, side beams fit between them (nothing passes through)
	bz = dd / 2 - E - 0.012 - beam_d / 2
	bx = w / 2 - E - 0.012 - beam_d / 2
	yb = py + beam_h / 2 + 0.002
	for s_ in (-1, 1):
		before = set(bpy.data.objects)
		blk((0, yb, s_ * bz), (w - 2 * E - 0.03, beam_h, beam_d), timber_m(), bevel=0.012)
		blk((s_ * bx, yb, 0), (beam_d, beam_h, dd - 2 * E - 0.03 - 2 * beam_d - 0.004), timber_m(), bevel=0.012)
		_tag(_new_since(before), "timber")
	# copper bands on the beams' outer faces, near each pier (front, back, left, right)
	fr_y = yb
	for s_ in (-1, 1):
		zf = s_ * (bz + beam_d / 2 + 0.006)
		for x0 in (-w / 2 + 0.2, w / 2 - 0.52):
			copper_band(x0, x0 + 0.32, fr_y, beam_h * 0.62, zf, s_)
		fr = K.Frame(ox=s_ * (bx + beam_d / 2 + 0.006), yaw=90 * s_)
		for x0 in ((-dd / 2 + 0.2 + beam_d, dd / 2 - 0.52 - beam_d) if dd > 1.5 else (-0.16,)):  # a short side: one band
			before = set(bpy.data.objects)
			fr.box((x0 + 0.16, fr_y, 0), (0.32, beam_h * 0.62, 0.012), copper_m(), bevel=0.003)
			for xx in (x0 + 0.06, x0 + 0.26):
				kit.rivet(K.G(fr.p(xx, fr_y, -0.008)), kit.tex_mat("copper", "dark"), r=0.014)
			_tag(_new_since(before), "copper")
	flagstones(-w / 2 + E, w / 2 - E, -dd / 2 + E, dd / 2 - E, top0, h - E)


WAIST = 0.18   # F169: how thick the stairs' slanted underside is (straight down), under each step's inner corner


def stairs(w=2.0, h=2.0, dd=2.0, n=5, open_under=True):
	"""Stone stairs (the kit sheet): one row of big stones per step, every row exactly one step tall, so the rows
	line up from step to step (owner, Nov 17). F169 (owner, Nov 22: "we just need the actual stairs, not the entire
	block under it"): the steps rest on a thin slanted underside of wedge stones (WAIST thick), open below, so you can
	walk under the high end or put a chest there. open_under=False: the old solid slices (the low foundation steps)."""
	dz = (dd - 2 * E) / n
	rise = (h - E) / n
	for i in range(n):
		zf = dd / 2 - E - i * dz
		top = E + (i + 1) * rise - (0.0 if i < n - 1 else E)
		y0 = E + i * rise if open_under else E
		courses(w, top, dz - 0.002, y0=y0, y1=top, zc=zf - dz / 2, dark_base=(i == 0), row_h=rise, block_l=(0.5, 0.8), tight=True)
		if open_under and i > 0:
			stair_waist(w, zf, dz, y0, rise, i)


def stair_waist(w, zf, dz, y_top, rise, i):
	"""The slanted underside below one step (seen from the side: x = -z): from the step's bottom down to a line
	WAIST below the steps' inner corners, cut off at the floor. Split across into 2-3 wedge stones."""
	xa, xb = -zf + 0.0015, -zf + dz - 0.0015
	ya, yb = y_top - rise - WAIST, y_top - WAIST
	if ya < E:   # it reaches the floor: cut it off there
		xg = xa + (E - ya) / (yb - ya) * (xb - xa)
		pts = [(xg, E), (xb, yb), (xb, y_top - 0.002), (xa, y_top - 0.002), (xa, E)]
		if xg - xa < 0.004:
			pts = pts[:-1]
	else:
		pts = [(xa, ya), (xb, yb), (xb, y_top - 0.002), (xa, y_top - 0.002)]
	cuts = [-w / 2 + E] + sorted(K.rng.uniform(-0.35, 0.35) + c for c in ((-0.33, 0.33) if i % 2 else (0.0,))) + [w / 2 - E]
	for a, b in zip(cuts, cuts[1:]):
		m = kit.tex_mat("greystone", "dark") if K.rng.random() < 0.15 else stone_m()
		prism(K.Frame(ox=(a + b) / 2, yaw=90), pts, 0.0, b - a - 0.003, m, cut=K.rng.uniform(0.02, 0.03))


def foundation_steps():
	stairs(2.0, 1.0, 2.0, n=3, open_under=False)


def ramp(w=2.0, h=1.0, dd=2.0, strips=8):
	"""Stone ramp: strips of stone across the slope, each stone cut to the slope on top, so the walking surface
	is one even slope of stone and the sides are stone too (no gaps)."""
	dz = (dd - 2 * E) / strips

	def slope(z):  # rises toward the back (-z)
		return E + (h - 2 * E) * (dd / 2 - E - z) / (dd - 2 * E)
	for i in range(strips):
		za, zb = dd / 2 - E - i * dz, dd / 2 - E - (i + 1) * dz
		ya, yb = slope(za), slope(zb)
		if i % 2:
			xs = [-w / 2 + E, -w / 2 + E + w * K.rng.uniform(0.3, 0.45), w / 2 - E - w * K.rng.uniform(0.25, 0.4), w / 2 - E]
		else:
			xs = [-w / 2 + E, -w / 2 + E + w * K.rng.uniform(0.45, 0.6), w / 2 - E]
		for k in range(len(xs) - 1):
			x0_, x1_ = xs[k] + 0.0015, xs[k + 1] - 0.0015
			# the stone's side-view outline (frame x = -z): from the ground up to the slope
			pts = [(-za + 0.0015, E), (-zb - 0.0015, E), (-zb - 0.0015, yb - 0.002), (-za + 0.0015, ya - 0.002)]
			if ya - E < 0.03:
				pts = [(-za + 0.0015, E), (-zb - 0.0015, E), (-zb - 0.0015, yb - 0.002)]
			m = kit.tex_mat("greystone", "dark") if K.rng.random() < 0.2 else stone_m()
			o = K.slab_poly(K.Frame(ox=(x0_ + x1_) / 2, yaw=90), pts, 0.0, x1_ - x0_, m)
			b = o.modifiers.new("chisel", "BEVEL")
			b.width, b.segments, b.limit_method, b.angle_limit = 0.025, 1, "ANGLE", math.radians(35)
			for pp in o.data.polygons:
				pp.use_smooth = False
			o["role"] = "stone"


def baluster(x, y0, y1, m=None, rmax=0.066, sides=12):
	"""A turned wooden baluster, a little column: square foot, narrow neck, fat vase belly,
	narrow neck again, square cap. Turned shape built ring by ring."""
	m = m or timber_m()   # turned dark wood (owner, Nov 17: "make the pillars on the railings from wood")
	start = set(bpy.data.objects)
	h = y1 - y0
	foot, cap = 0.13 * h, 0.1 * h
	sq = 0.128
	block((x, y0 + foot / 2, 0.0), (sq, foot - 0.002, sq), m, cut=0.018, tilt=0.0, free="")
	block((x, y1 - cap / 2, 0.0), (sq, cap - 0.002, sq), m, cut=0.018, tilt=0.0, free="")
	a, b = y0 + foot, y1 - cap
	prof = [(0.0, 0.055), (0.07, 0.046), (0.2, 0.05), (0.42, rmax), (0.58, rmax * 0.96), (0.76, 0.05), (0.88, 0.043), (1.0, 0.056)]
	verts, faces = [], []
	for t, r in prof:
		y = a + (b - a) * t
		for k in range(sides):
			ang = math.tau * k / sides
			verts.append((x + math.cos(ang) * r, y, math.sin(ang) * r))
	n = len(prof)
	for i in range(n - 1):
		for k in range(sides):
			p0, p1 = i * sides + k, i * sides + (k + 1) % sides
			faces.append((p0, p1, p1 + sides, p0 + sides))
	faces.append(tuple(reversed(range(sides))))
	faces.append(tuple(range((n - 1) * sides, n * sides)))
	before = set(bpy.data.objects)
	o = K.mesh(verts, faces, m, smooth=True)
	_tag(_new_since(start), "timber")   # wood: the painter keeps it wood
	return o


def railing(w=2.0, h=1.0, d=0.15):
	"""Stone balustrade (the kit sheet): two stone end posts, a bottom rail and a top rail of long stones, and
	three turned balusters (little vase-shaped columns) standing between them."""
	pw = 0.24
	bh, th = 0.2, 0.19
	dd = d - 2 * E - 0.004
	for sx in (-1, 1):
		block((sx * (w / 2 - E - pw / 2), h / 2, 0), (pw - 0.004, h - 2 * E - 0.004, dd), stone_m(), cut=0.03, tilt=0.0, free="z")
	inner = w - 2 * E - 2 * pw
	block((0, E + 0.002 + bh / 2, 0), (inner - 0.004, bh - 0.004, dd - 0.01), kit.tex_mat("greystone", "dark"), cut=0.025, tilt=0.0, free="z")
	block((0, h - E - th / 2 - 0.002, 0), (inner - 0.004, th - 0.004, dd), stone_m(), cut=0.03, tilt=0.0, free="yz")
	y0, y1 = E + bh + 0.001, h - E - th - 0.003
	n = 3
	for k in range(n):
		baluster(-inner / 2 + inner * (k + 1) / (n + 1), y0, y1)


# ---------------- new stair pieces (owner, Nov 21: docs/design/new-pieces-plan.md) ----------------
def _post_stones(cx, cz, pw, y0, y1, n=5):
	"""A square stone newel post of stacked chisel-cut stones, the bottom one dark."""
	ys = [y0 + (y1 - y0) * i / n for i in range(n + 1)]
	for i in range(n):
		m = kit.tex_mat("greystone", "dark") if i == 0 else stone_m()
		block((cx, (ys[i] + ys[i + 1]) / 2, cz), (pw - 0.004, ys[i + 1] - ys[i] - 0.003, pw - 0.004), m, cut=0.035, tilt=0.0, dent=0.012, free="")


CORNER_UNDER = 0.2   # F169: how far each corner step reaches below the step before it (the game's shape: same)


def stairs_corner(w=2.0, h=2.0, dd=2.0, n=8):
	"""Corner stairs: 8 steps fan a quarter turn round a stone newel post in the front-left corner, 2 m up in one
	cell. Each step is a stack of stone rows cut exactly to its wedge (the rows line up from step to step, like
	the straight stairs); every row is split into an inner and an outer stone, the joint moving row to row."""
	cx, cz = -w / 2 + E, dd / 2 - E          # the corner the steps turn round
	X1, Z0 = w / 2 - E, -dd / 2 + E          # the far sides
	pw = 0.3
	rise = (h - E) / n
	g = 0.0015

	def ray(a):
		return math.cos(a), -math.sin(a)

	def far(a):
		dx, dz = ray(a)
		return min((X1 - cx) / dx if dx > 1e-6 else 9, (Z0 - cz) / dz if dz < -1e-6 else 9)

	def near(a):   # where the ray leaves the post's square
		dx, dz = ray(a)
		return min(pw / dx if dx > 1e-6 else 9, pw / -dz if dz < -1e-6 else 9) + 0.004

	def pt(a, t):
		dx, dz = ray(a)
		return (cx + dx * t, cz + dz * t)
	_post_stones(cx + pw / 2, cz - pw / 2, pw, E, h - E)
	ca = math.atan2(-(Z0 - cz), X1 - cx)     # the far corner's angle
	for i in range(n):
		a0, a1 = math.radians(90 * i / n), math.radians(90 * (i + 1) / n)
		top = E + (i + 1) * rise - (E if i == n - 1 else 0.0)
		# F169: each step is its own row plus a thin row under it (CORNER_UNDER), open below; together their
		# undersides step up round the turn like a thin twisting slab
		rows = [(E + i * rise, top)]
		if i > 0:
			rows.insert(0, (max(E, E + i * rise - CORNER_UNDER), E + i * rise))
		for k, (ra, rb) in enumerate(rows):
			y0, y1 = ra + g, rb - g
			s = (0.42 if (i + k) % 2 else 0.58) + J(0.06)
			m0, m1 = near(a0) + s * (far(a0) - near(a0)), near(a1) + s * (far(a1) - near(a1))
			inner = [pt(a0, near(a0)), pt(a0, m0), pt(a1, m1), pt(a1, near(a1))]
			outer = [pt(a0, m0), pt(a0, far(a0))] + ([(X1, Z0)] if a0 < ca < a1 else []) + [pt(a1, far(a1)), pt(a1, m1)]
			for poly in (inner, outer):
				m = kit.tex_mat("greystone", "dark") if (k == 0 or K.rng.random() < 0.12) else stone_m()
				slab_xz(_inset(poly, g), y0, y1, m, c=K.rng.uniform(0.022, 0.032))


def stone_drums(r, y0, y1, n_cuts=6, sides=16, cap=0.0):
	"""A round post of stacked stone drums (the bottom one dark), each turned a little; cap = a wider top drum."""
	ring = [(r * math.cos(math.tau * (k + 0.5) / sides), r * math.sin(math.tau * (k + 0.5) / sides)) for k in range(sides)]
	cuts = [y0] + sorted(K.rng.uniform(0.1, 0.9) * (y1 - y0) + y0 for _ in range(n_cuts)) + [y1]
	for i in range(len(cuts) - 1):
		rot = K.rng.uniform(0, math.tau)
		pts = [(x * math.cos(rot) - z * math.sin(rot), x * math.sin(rot) + z * math.cos(rot)) for (x, z) in ring]
		slab_xz(pts, cuts[i] + 0.0015, cuts[i + 1] - 0.0015, kit.tex_mat("greystone", "dark") if i == 0 else stone_m(), c=0.02)
	if cap:
		ring = [(x * (r + cap) / r, z * (r + cap) / r) for (x, z) in ring]
		slab_xz(ring, y1 + 0.0015, y1 + 0.06, stone_m(), c=0.022)


def spiral_rail(p0, t0, p1, t1, m, bar=0.14, d=0.12):
	"""A straight slanted rail bar from (x, z) p0 to p1, its top t0 / t1, chisel-cut."""
	L = math.hypot(p1[0] - p0[0], p1[1] - p0[1])
	yaw = math.degrees(math.atan2(-(p1[1] - p0[1]), p1[0] - p0[0]))
	o = K.slab_poly(K.Frame(p0[0], p0[1], yaw), [(0, t0 - bar), (L, t1 - bar), (L, t1), (0, t0)], 0.0, d, m)
	b = o.modifiers.new("chisel", "BEVEL")
	b.width, b.segments, b.limit_method, b.angle_limit = 0.02, 2, "ANGLE", math.radians(35)
	return o


def spiral_baluster(x, z, y0, y1, m, sq=0.1, rmax=0.045, sides=12, role="stone"):
	"""A turned baluster at (x, z): a square foot, a vase body, a square top block flat under the rail (its low
	side just touches the slanted rail)."""
	start = set(bpy.data.objects)
	foot, top = 0.08, 0.07
	block((x, y0 + foot / 2, z), (sq, foot - 0.002, sq), m, cut=0.014, tilt=0.0, free="")
	block((x, y1 - 0.009 - top / 2, z), (sq, top - 0.002, sq), m, cut=0.014, tilt=0.0, free="")
	a, bb = y0 + foot + 0.001, y1 - 0.009 - top - 0.001
	prof = [(0.0, 0.04), (0.08, 0.032), (0.25, 0.036), (0.45, rmax), (0.6, rmax * 0.95), (0.78, 0.036), (0.9, 0.03), (1.0, 0.04)]
	verts, faces = [], []
	for t, r in prof:
		for k in range(sides):
			ang = math.tau * k / sides
			verts.append((x + math.cos(ang) * r, a + (bb - a) * t, z + math.sin(ang) * r))
	np_ = len(prof)
	for i in range(np_ - 1):
		for k in range(sides):
			p0, p1 = i * sides + k, i * sides + (k + 1) % sides
			faces.append((p0, p1, p1 + sides, p0 + sides))
	faces.append(tuple(reversed(range(sides))))
	faces.append(tuple(range((np_ - 1) * sides, np_ * sides)))
	K.mesh(verts, faces, m, smooth=True)
	_tag(_new_since(start), role)


def stone_pier(cx, cz, w, y0, y1):
	"""A square pillar of stacked chisel-cut stones (the bottom one dark, the foot and cap a little wider)."""
	y0 = max(y0, E)
	n = max(2, round((y1 - y0) / 0.32))
	ys = [y0 + 0.002 + (y1 - y0 - 0.002) * i / n for i in range(n + 1)]
	for i in range(n):
		m = kit.tex_mat("greystone", "dark") if i == 0 and y0 < 0.01 else stone_m()
		end = i in (0, n - 1)
		ww = w if end else w - 0.03
		block((cx, (ys[i] + ys[i + 1]) / 2, cz), (ww, ys[i + 1] - ys[i] - 0.003, ww), m, cut=0.024, tilt=0.0, dent=0.01, free="")


def stairs_spiral(stacked=False):
	"""F716 spiral stairs (owner, Nov 22: hard to climb, the top ends in empty space): 4 × 4 m. Nine wide stone
	treads (each an inner and an outer stone) climb 3/4 of a turn round a thick post of stacked drums, then a
	landing of 9 flagstones fills the last quarter at the top, over the way in. A stone rail with turned
	balusters runs round the outside on corner pillars, and along the landing's drop. Layout: spiral_layout.py."""
	import spiral_layout as SL

	def tread(poly, top, inner):
		m = kit.tex_mat("greystone", "dark") if K.rng.random() < 0.12 else stone_m()
		slab_xz(_inset(poly, 0.003), top - SL.H * 0.09, top, m, c=K.rng.uniform(0.022, 0.032))

	def flag(poly, y0, y1):
		slab_xz(_inset(poly, 0.002), y0, y1, stone_m(), c=K.rng.uniform(0.022, 0.03))

	SL.build(post=lambda y1: stone_drums(SL.POST, E, y1, cap=0.03),
		tread=tread, flag=flag, pier=stone_pier,
		rail=lambda p0, t0, p1, t1: spiral_rail(p0, t0, p1, t1, stone_m(), bar=SL.BAR),
		baluster=lambda x, z, y0, y1: spiral_baluster(x, z, y0, y1, stone_m()),
		rng=K.rng, post_top=2.93, stacked=stacked)


def stairs_spiral_stacked():
	"""F780: the same spiral stairs with another flight on top (no landing rail, the post stops under the next one)."""
	stairs_spiral(stacked=True)


STAIR_STEPS = 8   # F711 (owner, Nov 22: "the first and second steps are far too tall"): 8 steps of 25 cm, not 5 of 40 cm


def _stair_tread_tops(h=2.0, dd=2.0, n=STAIR_STEPS):
	"""The straight stairs' steps seen from the side, as (x from, x to, top) with x = -z (rising toward +x)."""
	dz, rise = (dd - 2 * E) / n, (h - E) / n
	return [(-(dd / 2 - E) + i * dz, -(dd / 2 - E) + (i + 1) * dz, E + (i + 1) * rise - (E if i == n - 1 else 0.0)) for i in range(n)]


def stair_baluster(x, y0, rail_bot, m=None, sq=0.11, rmax=0.05, sides=12):
	"""A turned dark-wood baluster for a slanted hand rail: square foot, turned vase body, and a square top
	block cut on the slant so it sits flat under the rail (rail_bot(x) = the rail's underside)."""
	m = m or timber_m()
	start = set(bpy.data.objects)
	foot = 0.09
	block((x, y0 + 0.002 + foot / 2, 0.0), (sq, foot - 0.002, sq), m, cut=0.016, tilt=0.0, free="")
	lo, hi = rail_bot(x - sq / 2) - 0.002, rail_bot(x + sq / 2) - 0.002
	cb = lo - 0.07
	o = K.slab_poly(K.Frame(), [(x - sq / 2, cb), (x + sq / 2, cb), (x + sq / 2, hi), (x - sq / 2, lo)], 0.0, sq, m)
	b = o.modifiers.new("chisel", "BEVEL")
	b.width, b.segments, b.limit_method, b.angle_limit = 0.014, 1, "ANGLE", math.radians(35)
	a, bb = y0 + foot + 0.002, cb - 0.002
	prof = [(0.0, 0.045), (0.08, 0.036), (0.25, 0.04), (0.45, rmax), (0.6, rmax * 0.95), (0.78, 0.04), (0.9, 0.034), (1.0, 0.045)]
	verts, faces = [], []
	for t, r in prof:
		y = a + (bb - a) * t
		for k in range(sides):
			ang = math.tau * k / sides
			verts.append((x + math.cos(ang) * r, y, math.sin(ang) * r))
	np_ = len(prof)
	for i in range(np_ - 1):
		for k in range(sides):
			p0, p1 = i * sides + k, i * sides + (k + 1) % sides
			faces.append((p0, p1, p1 + sides, p0 + sides))
	faces.append(tuple(reversed(range(sides))))
	faces.append(tuple(range((np_ - 1) * sides, np_ * sides)))
	K.mesh(verts, faces, m, smooth=True)
	_tag(_new_since(start), "timber")


def railing_stairs(w=2.0, h=3.0, d=0.15):
	"""Stair railing: it runs along the side of the straight stairs (2 m run, 2 m rise; here along x, rising toward
	+x: turned a quarter it rises toward -z like the stairs). F712 (owner, Nov 22: stone stairs with a wooden railing
	"doesn't look that good"): all stone, like the stone railing beside it: two chunky newel posts of stacked
	chisel-cut stones (the bottom one dark, a wider foot and cap), a thick slanted stone hand rail, and a turned stone
	baluster on every step. The rail's top meets the plain railing's top (1 m above the floor) at
	both ends."""
	steps = _stair_tread_tops()
	dmax = d - 2 * E - 0.002

	def rail_top(x):
		return (h - 1.0) + x - 0.008   # 1 m at the bottom floor's edge, 3 m at the top floor's edge
	rh = 0.15
	pw = 0.22    # the posts' foot and cap stones (along the rail); the stones between are a little narrower

	def newel(xc, y0, y1):
		n = max(2, round((y1 - y0) / 0.32))
		ys = [y0 + 0.002 + (y1 - y0 - 0.002) * i / n for i in range(n + 1)]
		for i in range(n):
			m = kit.tex_mat("greystone", "dark") if i == 0 else stone_m()
			end = i in (0, n - 1)
			sz = (pw if end else pw - 0.03, ys[i + 1] - ys[i] - 0.003, dmax if end else dmax - 0.016)
			block((xc, (ys[i] + ys[i + 1]) / 2, 0), sz, m, cut=0.024, tilt=0.0, dent=0.01, free="")
	x0 = steps[0][0] + pw / 2 + 0.002
	x1 = steps[-1][1] - pw / 2 - 0.002
	newel(x0, steps[0][2], rail_top(x0 + pw / 2) + 0.16)
	newel(x1, steps[-1][2], h - E)
	ra, rb = x0 + pw / 2 + 0.002, x1 - pw / 2 - 0.002
	o = K.slab_poly(K.Frame(), [(ra, rail_top(ra) - rh), (rb, rail_top(rb) - rh), (rb, rail_top(rb)), (ra, rail_top(ra))], 0.0, dmax - 0.02, stone_m())
	b = o.modifiers.new("chisel", "BEVEL")
	b.width, b.segments, b.limit_method, b.angle_limit = 0.022, 2, "ANGLE", math.radians(35)
	for i, (sa, sb, top) in enumerate(steps):
		xs = [sa + (sb - sa) * 0.5]
		for x in xs:
			if ra + 0.06 < x < rb - 0.06:
				stair_baluster(x, top, lambda xx: rail_top(xx) - rh, m=stone_m(), sq=0.1, rmax=0.045)


def floor(w=2.0, h=0.25, dd=2.0):
	"""Stone floor (the ceiling seen from below): chunky flagstones on dark timber joists with copper brackets."""
	flat_roof(w, h, dd)


def floor_half():
	floor(2.0, 0.25, 1.0)


def small_floor():
	floor(1.0, 0.25, 1.0)


def ceiling_panel():
	floor(2.0, 0.25, 2.0)


def _tri_flagstones(y0, y1, inset=E):
	"""Flagstones over the triangle (seen from above), cut exactly to its three edges, on a dark bed."""
	planes = K.tri_planes(1.0, inset)
	pts = K.tri_pts(1.0)
	x0, x1 = min(p[0] for p in pts), max(p[0] for p in pts)
	z0, z1 = min(p[1] for p in pts), max(p[1] for p in pts)
	before = set(bpy.data.objects)
	bed = K.clip_poly([(x0, z0), (x1, z0), (x1, z1), (x0, z1)], K.tri_planes(1.0, inset + 0.03))
	K.floor_poly(bed, y0 + 0.02, y0 + 0.02 + (y1 - y0) * 0.6, mortar_m())
	_tag(_new_since(before), "mortar")
	rects, todo = [], [(x0, x1, z0, z1)]
	while todo:
		a, b, c, e = todo.pop()
		wx, wz = b - a, e - c
		if max(wx, wz) < K.rng.uniform(0.5, 0.8):
			rects.append((a, b, c, e))
			continue
		t = K.rng.uniform(0.35, 0.65)
		if wx >= wz:
			m_ = a + wx * t
			todo += [(a, m_, c, e), (m_, b, c, e)]
		else:
			m_ = c + wz * t
			todo += [(a, b, c, m_), (a, b, m_, e)]
	g = 0.002
	for (a, b, c, e) in rects:
		poly = K.clip_poly([(a + g, c + g), (b - g, c + g), (b - g, e - g), (a + g, e - g)], planes)
		if not poly or K.area(poly) < 0.004:
			continue
		th = (y1 - y0) - K.rng.uniform(0.004, 0.014)
		before = set(bpy.data.objects)
		o = K.floor_poly(poly, y1 - th - 0.003, y1 - 0.003, stone_m())
		b_ = o.modifiers.new("chisel", "BEVEL")
		b_.width, b_.segments, b_.limit_method, b_.angle_limit = 0.03, 1, "ANGLE", math.radians(35)
		for pp in o.data.polygons:
			pp.use_smooth = False
		_tag(_new_since(before), "stone")


def floor_triangle(t=0.25):
	"""Triangle floor (every side 2 m): two timber joists, a stone band round the three edges (no joist shows
	from outside), flagstones cut to its edges."""
	jh, jw, rd = 0.11, 0.14, 0.16
	outer = _inset(K.tri_pts(1.0), E)
	floor_rim(outer, _inset(K.tri_pts(1.0), E + rd), E, E + jh, per_side=3)
	for x in (-0.25, 0.25):
		zs = [z for z in [i * 0.01 - 1.2 for i in range(240)] if z < K.TRI_IN - E - rd - 0.01 and K.tri_half(z) - E - rd - 0.01 > abs(x) + jw / 2]
		if not zs:
			continue
		before = set(bpy.data.objects)
		blk((x, E + jh / 2, (min(zs) + max(zs)) / 2), (jw, jh, max(zs) - min(zs)), timber_m(), bevel=0.01)
		_tag(_new_since(before), "timber")
	_tri_flagstones(E + jh + 0.004, t - E)


def foundation_half():
	foundation(2.0, 1.0, 1.0)


def foundation_triangle(h=1.0):
	"""Triangle foundation: a stacked-stone pier at each corner, dark timber beams between them along the three
	edges, and a flagstone top cut to the triangle."""
	pts = K.tri_pts(1.0)
	top0, beam_h = 0.72, 0.17
	py = top0 - beam_h
	piers = []
	for (px, pz) in pts:  # pull each corner in toward the middle so the square pier stays inside the triangle
		v = Vector((-px, -pz)).normalized()
		q = (px + v.x * 0.4, pz + v.y * 0.4)
		piers.append(q)
		before = set(bpy.data.objects)
		blk((q[0], (py - 0.04) / 2 + 0.03, q[1]), (0.18, py - 0.04, 0.18), mortar_m(), bevel=0)
		_tag(_new_since(before), "mortar")
		hl = py * K.rng.uniform(0.5, 0.58)
		block((q[0], E + 0.004 + (hl - E - 0.004) / 2, q[1]), (0.28, hl - E - 0.004, 0.28), kit.tex_mat("greystone", "dark"), cut=0.035, tilt=0.0, free="xz")
		block((q[0], hl + 0.0015 + (py - hl - 0.003) / 2, q[1]), (0.26, py - hl - 0.003, 0.26), stone_m(), cut=0.035, tilt=0.0, free="xz")
	for k in range(3):  # beams between the piers along each edge
		a, b = Vector(piers[k]), Vector(piers[(k + 1) % 3])
		mid = (a + b) / 2
		L = (b - a).length
		ang = math.degrees(math.atan2(-(b - a).y, (b - a).x))
		before = set(bpy.data.objects)
		blk((mid.x, py + beam_h / 2 + 0.002, mid.y), (L, beam_h, 0.14), timber_m(), bevel=0.012, ry=ang)
		_tag(_new_since(before), "timber")
	_tri_flagstones(top0, h - E)


def sloped_wall(w=2.0, h=2.0, d=0.3):
	"""Sloped wall (the kit sheet): stepped blocks rising from the low end to the high end; every row stops at
	the slope line, so nothing pokes above the roof it sits under."""
	rise = h

	def lim(ya, yb):
		if yb > rise - 0.02:
			return None
		return (-w / 2 + yb / rise * w, w / 2)
	courses(w, h, d, limit=lim)


def slab_xz(pts, y0, y1, m, c=0.025, role="stone"):
	"""A flat stone seen from above with any outline pts [(x, z)...], from y0 to y1, its top and bottom edges
	chisel-cut by hand (never past its outline)."""
	inner = [(x, z) for (x, z) in _inset(pts, c)]
	rings = [(inner, y0), (pts, y0 + c), (pts, y1 - c), (inner, y1)]
	n = len(pts)
	verts = [(x, y, z) for (ring, y) in rings for (x, z) in ring]
	faces = []
	for r in range(3):
		for i in range(n):
			a, b = r * n + i, r * n + (i + 1) % n
			faces.append((a, b, b + n, a + n))
	faces.append(tuple(reversed(range(n))))
	faces.append(tuple(range(3 * n, 4 * n)))
	o = K.mesh(verts, faces, m, smooth=False)
	o["role"] = role
	return o


def floor_rim(outer, inner, y0, y1, per_side=3):
	"""Owner, Nov 17 ("the tower has lines on it"): a floor's edge showed its dark joists from outside between
	the walls. Now a band of stone runs round every floor's edge, so outside you see one stone course. `outer`
	and `inner` are the floor's outline and the same outline pulled in by the band's depth (same order); each
	side's band is cut into a few stones, the end ones mitred into the corners."""
	n = len(outer)
	g = 0.0025
	for i in range(n):
		o0, o1 = Vector(outer[i]), Vector(outer[(i + 1) % n])
		i0, i1 = Vector(inner[i]), Vector(inner[(i + 1) % n])
		cuts = [0.0] + [k / per_side + K.rng.uniform(-0.08, 0.08) for k in range(1, per_side)] + [1.0]
		for k in range(per_side):
			a, b = cuts[k], cuts[k + 1]
			oa, ob = o0.lerp(o1, a), o0.lerp(o1, b)
			ia, ib = i0.lerp(i1, a), i0.lerp(i1, b)
			d = (o1 - o0).normalized() * g
			pts = [tuple(oa + (d if k else Vector((0, 0)))), tuple(ob - (d if k < per_side - 1 else Vector((0, 0)))),
				tuple(ib - (d if k < per_side - 1 else Vector((0, 0)))), tuple(ia + (d if k else Vector((0, 0))))]
			slab_xz(pts, y0, y1, kit.tex_mat("greystone", "dark") if K.rng.random() < 0.15 else stone_m(), c=0.022)


def flat_roof(w=2.0, h=0.3, dd=2.0):
	"""Flat roof / floor slab: chunky flagstones on dark timber joists (the ceiling seen from below), with a
	band of stone round the edge so no joist shows from outside."""
	jh, jw, rd = 0.13, 0.15, 0.16
	x0, x1, z0, z1 = -w / 2 + E, w / 2 - E, -dd / 2 + E, dd / 2 - E
	outer = [(x0, z1), (x1, z1), (x1, z0), (x0, z0)]
	inner = [(x0 + rd, z1 - rd), (x1 - rd, z1 - rd), (x1 - rd, z0 + rd), (x0 + rd, z0 + rd)]
	floor_rim(outer, inner, E, E + jh, per_side=max(2, round(max(w, dd) / 0.6)))
	for x in (-w / 3, 0.0, w / 3):
		before = set(bpy.data.objects)
		blk((x + J(0.01), E + jh / 2 + 0.003, 0), (jw, jh - 0.006, dd - 2 * E - 2 * rd - 0.006), timber_m(), bevel=0.01)
		_tag(_new_since(before), "timber")
	flagstones(x0, x1, z0, z1, E + jh + 0.004, h - E)


def battlement(w=2.0, h=0.9, d=0.4, merlons=None, rivets=(-0.8, -0.4, 0.0, 0.4, 0.8)):
	"""Battlement edge: two courses of blocks, a riveted copper band along the front at their top, then three
	square merlons (ends and middle) with low sill stones in the gaps. `merlons`: other merlon middles (x)."""
	base = 0.44
	bh = 0.075   # the copper band's own course: a long cap stone set back, the band lying in front of it,
	courses(w, base - bh, d, y0=E, y1=base - bh, dark_base=False)   # so the band's face is level with the stones below (owner)
	g = 0.003
	before = set(bpy.data.objects)
	blk((0, base - bh / 2, -0.008), (w - 2 * E - 0.004, bh - g, d - 2 * E - 0.018), stone_m(), bevel=0.01)
	_tag(_new_since(before), "stone")
	z = d / 2 - E - 0.012 + 0.01   # copper_band sinks it 1 cm: front face ends ~1.2 cm inside the outline
	copper_band(-w / 2 + E + 0.004, w / 2 - E - 0.004, base - bh / 2, bh - 0.012, z, 1, rivets=rivets)
	mw = 0.44
	fr = K.Frame()
	mx = merlons if merlons is not None else (-w / 2 + E + mw / 2, 0.0, w / 2 - E - mw / 2)
	for x in mx:  # a dark core deep inside each merlon (never seen from outside)
		before = set(bpy.data.objects)
		blk((x, (base + h - E - 0.06) / 2, 0.0), (mw - 0.12, h - E - 0.06 - base, d * 0.5), mortar_m(), bevel=0)
		_tag(_new_since(before), "mortar")
	before = set(bpy.data.objects)   # and one behind the band row and the low sill stones, below their tops
	blk((0, base + 0.01, 0.0), (w - 2 * E - 0.08, 0.14, d * 0.5), mortar_m(), bevel=0)
	_tag(_new_since(before), "mortar")
	for x in mx:
		top = h - E - 0.004
		hl = (top - base) * K.rng.uniform(0.48, 0.55)
		block((x, base + 0.0015 + (hl - 0.003) / 2, 0.0), (mw - g, hl - 0.003, d - 2 * E - 0.008), stone_m(), cut=0.035, tilt=0.0, free="xz")
		block((x, base + hl + 0.0015 + (top - base - hl - 0.003) / 2, 0.0), (mw - g - 0.02, top - base - hl - 0.003, d - 2 * E - 0.016), stone_m(), cut=0.04, tilt=0.0, free="xz")
	edges = [-w / 2 + E] + [e for x in sorted(mx) for e in (x - mw / 2, x + mw / 2)] + [w / 2 - E]
	gaps = [(edges[i], edges[i + 1]) for i in range(0, len(edges), 2) if edges[i + 1] - edges[i] > 0.01]
	for x0, x1 in gaps:  # sill stones in the gaps, tight on the band course
		block(((x0 + x1) / 2, base + 0.0015 + 0.05, 0.0), (x1 - x0 - g, 0.1, d - 2 * E - 0.02), stone_m(), cut=0.03, tilt=0.0, free="z")


def door_broken():
	"""For ruins (owner, Nov 17): the round door torn off its hinges, lying on the floor near the doorway, split
	in two where a plank broke out; straps and back battens snapped there too; one half slid away a little."""
	door()

	def xr(o):  # an object's left/right edge (Blender x = Godot x)
		xs = [(o.matrix_world @ Vector(c)).x for c in o.bound_box]
		return min(xs), max(xs)

	def mid(o):
		a_, b_ = xr(o)
		return (a_ + b_) / 2

	objs = [o for o in bpy.data.objects if o.type == "MESH"]
	planks = [o for o in objs if o.get("role") == "board" and xr(o)[1] - xr(o)[0] < 0.4]
	gone = min(planks, key=lambda o: abs(mid(o) - 0.12))   # a plank just right of the middle broke out
	g0, g1 = xr(gone)
	bpy.data.objects.remove(gone)
	# Anything that ran across the broken plank (copper straps, back battens, rivets) snapped there.
	for o in [o for o in bpy.data.objects if o.type == "MESH" and o not in planks]:
		a_, b_ = xr(o)
		if b_ < g0 + 0.005 or a_ > g1 - 0.005:
			continue
		role = o.get("role")
		zs = [(o.matrix_world @ Vector(c)).z for c in o.bound_box]
		ys = [(o.matrix_world @ Vector(c)).y for c in o.bound_box]
		long = b_ - a_ > 0.4
		bpy.data.objects.remove(o)
		if not long:
			continue
		y = (min(zs) + max(zs)) / 2
		for (p0, p1) in ((a_ + 0.004, g0 - 0.035), (g1 + 0.035, b_ - 0.004)):
			if p1 - p0 < 0.12:
				continue
			if role == "copper":
				copper_band(p0, p1, y, 0.085, 0.034, 1, rivets=(p0 + 0.05, p1 - 0.05))
			else:  # a back batten stub
				before = set(bpy.data.objects)
				blk(((p0 + p1) / 2, y, -(min(ys) + max(ys)) / 2), (p1 - p0, max(zs) - min(zs) - 0.004, max(ys) - min(ys)), timber_m(), bevel=0.006)
				_tag(_new_since(before), "board")
	objs = [o for o in bpy.data.objects if o.type == "MESH"]
	for o in objs:  # bake every part's own placement into its points, so the whole door can be turned
		o.data.transform(o.matrix_world)
		o.matrix_world = o.matrix_world.Identity(4)
	lie = Matrix.Rotation(math.radians(-90), 4, "X")            # face up, on its back
	split = (g0 + g1) / 2
	for o in objs:
		vs = o.data.vertices
		cx = sum((v.co.x for v in vs)) / max(1, len(vs))
		m = lie
		if cx < split:  # the left half slid 10 cm further away and turned 7 degrees
			m = Matrix.Translation((-0.1, 0.04, 0)) @ Matrix.Rotation(math.radians(7), 4, "Z") @ lie
		o.data.transform(m)
	zmin = min((v.co.z for o in objs for v in o.data.vertices))
	xs = [v.co.x for o in objs for v in o.data.vertices]
	ys = [v.co.y for o in objs for v in o.data.vertices]
	cx, cy = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2   # centred on its spot, flat on the floor
	for o in objs:
		o.data.transform(Matrix.Translation((-cx, -cy, E + 0.002 - zmin)))


# ---------------- ruins (owner, Nov 17: the watchtower worn and broken, stones and pieces missing) ----------------
def ruin_wall_worn(w=2.0, h=2.0, d=0.3):
	"""A worn wall for ruins: about 1 stone in 9 fallen out (the dark filler shows behind), and the top row
	broken at one end."""
	def lim(ya, yb):
		if yb > h - 0.3:
			return (-w / 2 + K.rng.uniform(0.4, 0.9), w / 2)
		return (-w / 2, w / 2)
	courses(w, h, d, limit=lim, missing=0.11)


def ruin_wall_collapsed(w=2.0, h=2.0, d=0.3):
	"""A half-collapsed wall for ruins: full height at the right end, broken down in a jagged slope to about
	knee height at the left end; a few stones missing."""
	low = 0.55

	def lim(ya, yb):
		if yb <= low:
			return (-w / 2, w / 2)
		lo = -w / 2 + (yb - low) / (h - low) * w * 0.95 + K.rng.uniform(-0.12, 0.12)
		if lo > w / 2 - 0.3:
			return None
		return (max(-w / 2, lo), w / 2)
	courses(w, h, d, limit=lim, missing=0.06)


def ruin_rubble(w=1.6, h=0.7, dd=1.6, n=16):
	"""A pile of fallen stones: chunky cut blocks tumbled into a low heap, the big ones underneath."""
	placed = []
	for i in range(n):
		sz = Vector((K.rng.uniform(0.18, 0.42), K.rng.uniform(0.12, 0.24), K.rng.uniform(0.16, 0.3))) * (1.0 - 0.4 * i / n)
		r = (w / 2 - 0.25) * math.sqrt(K.rng.random()) * (1.0 - 0.3 * i / n)
		a = K.rng.uniform(0, math.tau)
		x, z = r * math.cos(a), r * math.sin(a)
		base = 0.0
		for (px, pz, top, ps) in placed:   # rest on whatever stone is under it
			if abs(px - x) < (ps.x + sz.x) * 0.35 and abs(pz - z) < (ps.z + sz.z) * 0.35:
				base = max(base, top - 0.03)
		y = E + 0.035 + base + sz.y / 2   # tilted stones need room below
		if y + sz.y / 2 > h - E:
			continue
		block((x, y, z), tuple(sz), kit.tex_mat("greystone", "dark") if K.rng.random() < 0.25 else stone_m(), cut=0.03, tilt=9.0, dent=0.015)
		placed.append((x, z, y + sz.y / 2, sz))


# ---------------- the outpost's gate and training yard (owner, Nov 17) ----------------
GATE_W, GATE_SPRING, GATE_R = 3.2, 2.0, 1.6   # the gateway's opening: 3.2 m wide, straight sides to 2 m, a round top


def gateway(w=4.0, h=4.0, d=0.3):
	"""A big stone gateway (4 x 4 m, the curtain wall's thickness): straight jambs to 2 m, then a round arch of wedge
	stones with a keystone; the stone rows are cut tight round the opening, a dark layer inside like every wall."""
	r_in = GATE_R + 0.01
	r_out = r_in + 0.2
	half = GATE_W / 2
	courses(w, h, d, y0=E + 0.006, y1=GATE_SPRING, hole=lambda ya, yb: (-half - 0.004, half + 0.004),
		back_hole=(-half - 0.015, half + 0.015, 0.02, GATE_SPRING + 0.01), dark_base=True)
	_, key_top = courses(w, h, d, y0=GATE_SPRING, y1=h - E, circle=(GATE_SPRING, r_out + 0.002, 0.2, GATE_SPRING + r_out + 0.25),
		back_hole=(GATE_SPRING, r_in + 0.04), dark_base=False)
	ring_stones(GATE_SPRING, r_in, r_out, d, n=11, key_h=max(0.05, key_top - GATE_SPRING - r_out - 0.0015), a0=0.0)


def gate_leaf(w=1.6, d=0.15):
	"""One leaf of the big double gate (hinged on its left edge; the right leaf is the same turned round): thick dark
	upright planks whose tops follow the gateway's round arch, three riveted copper bands, a ring handle by the
	middle, back battens."""
	ww = w - 0.02
	x0, x1 = -ww / 2, ww / 2
	cx = w / 2              # the arch's centre is at the gate's middle = this leaf's right edge
	R = GATE_R - 0.015

	def top(x):
		dx = x - cx
		return GATE_SPRING + math.sqrt(max(0.0, R * R - dx * dx)) - 0.01
	fr = K.Frame()
	n = 5
	edges = [x0 + (x1 - x0) * i / n + (K.rng.uniform(-0.03, 0.03) if 0 < i < n else 0.0) for i in range(n + 1)]
	for i in range(n):
		a, b = edges[i] + 0.004, edges[i + 1] - 0.004
		before = set(bpy.data.objects)
		K.plank_shape(fr, a, b, lambda xx: E, top, -0.01 + J(0.004), 0.085 * K.rng.uniform(0.92, 1.0), timber_m(), k=8)
		_tag(_new_since(before), "board")
	for y in (0.45, 1.35, 2.25):
		hw_r = min(x1, cx + math.sqrt(max(0.0, R * R - (y - GATE_SPRING) ** 2)) - 0.05) if y > GATE_SPRING else x1
		copper_band(x0 + 0.02, hw_r - 0.02, y, 0.11, 0.045, 1, rivets=[x0 + 0.1 + (hw_r - x0 - 0.2) * k / 4 for k in range(5)])
	before = set(bpy.data.objects)
	kit.ring(0.09, 0.016, K.G((x1 - 0.18, 1.15, 0.052)), copper_m(), rot=(90, 0, 0), seg=16)
	kit.cylinder(0.035, 0.03, K.G((x1 - 0.18, 1.24, 0.045)), copper_m(), rot=(90, 0, 0), verts=10, bevel=0.003)
	_tag(_new_since(before), "copper")
	for y in (0.6, 1.8):
		before = set(bpy.data.objects)
		blk((0, y, -0.052), (ww - 0.1, 0.14, 0.024), timber_m(), bevel=0.006)
		_tag(_new_since(before), "board")


def gate_broken():
	"""For the outpost ruin: one leaf of the double gate, torn off and lying flat on its back on the ground (owner:
	the two leaves lie apart, one on each side of the gateway). Centred on its spot."""
	gate_leaf()
	objs = [o for o in bpy.data.objects if o.type == "MESH"]
	for o in objs:
		o.data.transform(o.matrix_world)
		o.matrix_world = o.matrix_world.Identity(4)
		o.data.transform(Matrix.Rotation(math.radians(-90), 4, "X"))            # flat on its back
	zmin = min(v.co.z for o in objs for v in o.data.vertices)
	xs = [v.co.x for o in objs for v in o.data.vertices]
	ys = [v.co.y for o in objs for v in o.data.vertices]
	cx, cy = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2
	for o in objs:
		o.data.transform(Matrix.Translation((-cx, -cy, E + 0.002 - zmin)))


def _straw_m():
	return kit.tex_mat("straw", K.rng.choice("abc"))


def straw_dummy():
	"""A straw practice dummy: a hewn post on a cross of feet, a crossbar for arms with straw bundles, a straw-stuffed
	sack body tied with rope, a sack head."""
	wm = timber_m()
	before = set(bpy.data.objects)
	blk((0, 0.95, 0), (0.12, 1.85, 0.12), wm, bevel=0.012)                       # the post
	blk((0, 0.07, 0), (0.9, 0.12, 0.14), wm, bevel=0.01)                         # its feet, a cross
	blk((0, 0.07, 0), (0.14, 0.11, 0.9), wm, bevel=0.01)
	blk((0, 1.42, 0.0), (0.95, 0.1, 0.1), wm, bevel=0.01)                        # the arms' crossbar
	_tag(_new_since(before), "timber")
	before = set(bpy.data.objects)
	boulder((0, 1.15, 0), 0.24, 0.42, 0.2, kit.tex_mat("sack", "a"), floor=0.7)    # the body
	boulder((0, 1.72, 0), 0.15, 0.15, 0.14, kit.tex_mat("sack", "b"), floor=1.58)  # the head
	for sx in (-1, 1):
		boulder((sx * 0.38, 1.42, 0), 0.12, 0.08, 0.08, _straw_m(), floor=1.3)    # straw arms
	for y in (0.95, 1.32):
		kit.ring(0.21, 0.014, K.G((0, y, 0)), kit.tex_mat("rope"), seg=14)
	_tag(_new_since(before), "straw")


def archery_target():
	"""An archery target: a round straw boss (1 m), painted rings, on a leaning wooden A-frame."""
	before = set(bpy.data.objects)
	kit.cylinder(0.5, 0.18, K.G((0, 1.05, 0.05)), _straw_m(), rot=(90, 0, 0), verts=20, bevel=0.03)
	for (r, c) in ((0.38, "b"), (0.24, "dark"), (0.1, "b")):
		kit.cylinder(r, 0.012, K.G((0, 1.05, 0.145)), kit.tex_mat("cloth", c), rot=(90, 0, 0), verts=20, bevel=0.002)
	_tag(_new_since(before), "straw")
	before = set(bpy.data.objects)
	for sx in (-1, 1):
		blk((sx * 0.32, 0.77, -0.08), (0.09, 1.5, 0.09), timber_m(), bevel=0.01, rx=-12)
	blk((0, 0.12, -0.3), (0.8, 0.08, 0.08), timber_m(), bevel=0.008)
	blk((0, 0.8, -0.42), (0.08, 1.36, 0.08), timber_m(), bevel=0.01, rx=28)      # the back leg
	_tag(_new_since(before), "timber")
	# Centred on its spot (the back leg pushed it 31 cm off: the game refused the model and showed a plain box).
	objs = [o for o in bpy.data.objects if o.type == "MESH"]
	for o in objs:
		o.data.transform(o.matrix_world)
		o.matrix_world = o.matrix_world.Identity(4)
	xs = [v.co.x for o in objs for v in o.data.vertices]
	ys = [v.co.y for o in objs for v in o.data.vertices]
	for o in objs:
		o.data.transform(Matrix.Translation((-(min(xs) + max(xs)) / 2, -(min(ys) + max(ys)) / 2, 0)))


def spear_rack():
	"""A weapon rack: two posts, a low rail with holes and a top rail, three spears and a sword standing in it."""
	wm = timber_m()
	before = set(bpy.data.objects)
	for sx in (-1, 1):
		blk((sx * 0.7, 0.758, 0), (0.1, 1.5, 0.12), wm, bevel=0.01)
	blk((0, 0.35, 0), (1.5, 0.08, 0.22), wm, bevel=0.008)
	blk((0, 1.35, -0.02), (1.5, 0.08, 0.08), wm, bevel=0.008)
	_tag(_new_since(before), "timber")
	before = set(bpy.data.objects)
	for i, x in enumerate((-0.42, -0.14, 0.14)):
		kit.cylinder(0.022, 1.7, K.G((x, 0.88, 0.02)), kit.tex_mat("wood", "c"), verts=8, bevel=0.003)
		kit.cone(0.04, 0.0, 0.18, K.G((x, 1.82, 0.02)), kit.tex_mat("iron", "b"), verts=6)
	blk((0.42, 0.95, 0.02), (0.07, 1.0, 0.012), kit.tex_mat("iron", "b"), bevel=0.004)     # a sword blade
	blk((0.42, 1.48, 0.02), (0.22, 0.04, 0.04), kit.tex_mat("copper", "b"), bevel=0.004)   # its guard
	_tag(_new_since(before), "metal")


def boulder(c, sx, sy, sz, m, floor=0.0):
	"""A lumpy rounded lump (straw bundles, sack stuffing): a low-poly ball, never below `floor`."""
	bm = bmesh.new()
	bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0)
	verts = [(c[0] + v.co.x * sx * (1 + J(0.08)), max(floor, c[1] + v.co.z * sy * (1 + J(0.08))), c[2] + v.co.y * sz * (1 + J(0.08)))
		for v in bm.verts]
	faces = [tuple(vv.index for vv in f.verts) for f in bm.faces]
	bm.free()
	return K.mesh(verts, faces, m, smooth=True)


FAMILY = {"straw_dummy": "plank_root", "archery_target": "plank_root", "spear_rack": "plank_root"}


# ---------------- batch 2 new pieces (docs/design/new-pieces-plan.md) ----------------
import new_pieces_common as NC  # noqa: E402

K.SIZE.update({"sloped_wall_down": (2, 2, 0.3), "edge_strip": (2, 0.3, 0.07), "floor_hatch": (2, 0.31, 2),
	"lattice_wall": (2, 2, 0.3)})
HATCH = (0.0, 0.47, 0.42, 0.47)   # the hole's centre x, z, its open radius, the rim's outer radius


def sloped_wall_down(w=2.0, h=2.0, d=0.3):
	"""Upside-down sloped wall: full along the top, slanting down to the left (fills the space under stairs or a
	ramp). It is the sloped wall turned half a turn round its front-back line."""
	sloped_wall(w, h, d)
	NC.flip_down(h)


def edge_strip(w=2.0, h=0.3, d=0.07):
	"""A thin lip of stone along a floor's edge: a row of four chisel-cut stones, one now and then dark."""
	x = -w / 2 + E
	while x < w / 2 - E - 0.01:
		nx = min(w / 2 - E, x + K.rng.uniform(0.42, 0.6))
		if w / 2 - E - nx < 0.3:
			nx = w / 2 - E
		m = kit.tex_mat("greystone", "dark") if K.rng.random() < 0.2 else stone_m()
		block(((x + nx) / 2, h / 2, 0.0), (nx - x - 0.004, h - 2 * E - 0.004, d - 2 * E - 0.004), m, cut=0.014, tilt=0.0, dent=0.006, free="xy")
		x = nx


def _hatch_lid(h, role="timber", n=4, m_fn=None, strap_m=None, strap_role="copper"):
	"""The round dark-wood lid, swung open and lying flat on the floor behind the hole (its hinge on the hole's
	back edge), with two straps across its boards and hinge knuckles at the hinge line."""
	cx, cz, r_in, r_out = HATCH
	lr = r_out - 0.004
	lz = cz - 2 * lr - 0.006        # the lid's centre once it is folded back over its hinge
	y0 = h - E + 0.003
	boards = NC.lid_boards(cx, lz, lr, y0, y0 + 0.045, n, m_fn or timber_m, role)
	before = set(bpy.data.objects)
	for sx in (-0.2, 0.2):
		half = math.sqrt(lr * lr - sx * sx) - 0.03
		blk((cx + sx, y0 + 0.045 + 0.005, lz), (0.06, 0.012, 2 * half), (strap_m or copper_m)(), bevel=0.003)
		kit.cylinder(0.022, 0.09, K.G((cx + sx, y0 + 0.022, lz + lr + 0.004)), (strap_m or copper_m)(), rot=(0, 90, 0), verts=10, bevel=0.003)
	NC.tag(NC._since(before), strap_role)
	return boards


def floor_hatch(w=2.0, h=0.25, dd=2.0):
	"""Floor with a round hatch: the stone floor with a round hole near its front, lined with a dark timber ring
	under a copper band, and the round dark-wood lid swung open, lying on the floor behind it."""
	floor(w, h, dd)
	cx, cz, r_in, r_out = HATCH
	NC.cut_round_hole(cx, cz, r_in + 0.025, deeper=())
	before = set(bpy.data.objects)
	NC.ring_mesh(cx, cz, r_in, r_out - 0.006, E + 0.004, h - E - 0.024, timber_m(), n=36)
	_tag(_new_since(before), "timber")
	before = set(bpy.data.objects)
	NC.ring_mesh(cx, cz, r_in - 0.004, r_out, h - E - 0.022, h - E, copper_m(), n=36)
	_tag(_new_since(before), "copper")
	_hatch_lid(h)


def lattice_wall(w=2.0, h=2.0, d=0.3):
	"""Open lattice wall: a stone frame (two posts of stacked stones, a sill and a lintel) round a see-through
	lattice of dark timber laths crossing on the diagonal, a copper rivet at every crossing."""
	pw, sill, lint = 0.26, 0.2, 0.26
	dd = d - 2 * E - 0.004
	x0, x1 = -w / 2 + E, w / 2 - E
	for xa, xb in ((x0, x0 + pw), (x1 - pw, x1)):
		ys = [sill, sill + 0.5 + K.J(0.06), sill + 1.0 + K.J(0.06), h - E - lint]
		for i in range(3):
			block(((xa + xb) / 2, (ys[i] + ys[i + 1]) / 2, 0.0), (xb - xa - 0.004, ys[i + 1] - ys[i] - 0.004, dd), stone_m(), cut=0.028, tilt=0.0, dent=0.012, free="xz")
	for (ya, yb, dark) in ((E + 0.003, sill, True), (h - E - lint, h - E - 0.002, False)):
		xm = K.J(0.25)
		for (a, b) in ((x0, xm), (xm, x1)):
			m = kit.tex_mat("greystone", "dark") if dark else stone_m()
			block(((a + b) / 2, (ya + yb) / 2, 0.0), (b - a - 0.004, yb - ya - 0.004, dd), m, cut=0.03, tilt=0.0, dent=0.014, free="yz")
	ox0, ox1, oy0, oy1 = x0 + pw - 0.02, x1 - pw + 0.02, sill - 0.02, h - E - lint + 0.02
	pts = NC.lattice(ox0, ox1, oy0, oy1, 0.0, 0.34, 0.065, 0.075, timber_m, "timber")
	before = set(bpy.data.objects)
	for (x, y) in pts:
		kit.rivet(K.G((x, y, 0.075 * 0.82 + 0.002)), kit.tex_mat("copper", "dark"), r=0.013)
	_tag(_new_since(before), "copper")


PIECES = {"foundation": foundation, "wall": wall, "doorway": doorway, "door": door, "flat_roof": flat_roof,
	"battlement": battlement, "door_broken": door_broken, "half_wall": half_wall, "wall_narrow": wall_narrow,
	"window_wall": window_wall, "window_wide": window_wide, "pillar": pillar, "beam": beam, "beam_half": beam_half,
	"stairs": lambda: stairs(n=STAIR_STEPS), "foundation_steps": foundation_steps, "ramp": ramp, "railing": railing, "floor": floor,
	"floor_half": floor_half, "small_floor": small_floor, "ceiling_panel": ceiling_panel, "floor_triangle": floor_triangle,
	"foundation_half": foundation_half, "foundation_triangle": foundation_triangle, "sloped_wall": sloped_wall,
	"ruin_wall_worn": ruin_wall_worn, "ruin_wall_collapsed": ruin_wall_collapsed, "ruin_rubble": ruin_rubble,
	"gateway": gateway, "gate_leaf": gate_leaf, "gate_broken": gate_broken, "straw_dummy": straw_dummy,
	"archery_target": archery_target, "spear_rack": spear_rack, "stairs_corner": stairs_corner, "sloped_wall_down": sloped_wall_down, "edge_strip": edge_strip, "floor_hatch": floor_hatch, "lattice_wall": lattice_wall,
	"stairs_spiral": stairs_spiral, "stairs_spiral_stacked": stairs_spiral_stacked, "railing_stairs": railing_stairs}


def paint():
	"""First paint (owner, Nov 17: "paint them right away"): the game's own hand-painted textures, wrapped round
	each part at real size (never stretched) and shifted so no two neighbours show the same spot. Calm grey stone,
	about 3 stones in 10 a warm brownish one (the turnaround sheet), the dark base row and every other ring stone in
	dark stone, a pale keystone, dark timber, hammered copper. (Next: ChatGPT variant sheets, Rule 6.)"""
	greys = [kit.tex_mat("greystone", v) for v in "abc"]
	warms = [kit.tex_mat("warmstone", v) for v in "ab"]
	tile = {"greystone": 0.7, "warmstone": 0.7, "wood": 0.6, "copper": 0.4}
	for o in list(bpy.data.objects):
		if o.type != "MESH" or not o.data.materials:
			continue
		role = o.get("role")
		m = o.data.materials[0]
		if role == "stone" and not m.name.startswith("greystone_dark"):
			m = K.rng.choice(warms) if K.rng.random() < 0.3 else K.rng.choice(greys)
		elif role == "keystone":
			m = kit.tex_mat("greystone", "c")
		o.data.materials.clear()
		o.data.materials.append(m)
		kind = m.name.rsplit("_", 1)[0]
		kit._uv_box(o, tile.get(kind, 0.6))


def make_grey():
	g = bpy.data.materials.new("clay_white")
	g.use_nodes = True
	g.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.82, 0.8, 0.77, 1)
	g.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.8
	for o in bpy.data.objects:
		if o.type == "MESH":
			o.data.materials.clear()
			o.data.materials.append(g)


if __name__ == "__main__":
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	grey = "grey" in args
	out_dir = next((Path(a[4:]) for a in args if a.startswith("out=")), OUT_DEFAULT)
	names = [a for a in args if a in PIECES] or list(PIECES)
	install = "install=1" in args
	if install:
		out_dir = K.OUT
		names = list(names)   # ruin pieces too: the world places them (src/world/ruin_tower.gd), the build menu hides them
	out_dir.mkdir(parents=True, exist_ok=True)
	for name in names:
		K.rng.seed(sum(map(ord, name + "stonehold2")))
		kit.reset()
		PIECES[name]()
		K.fit_check(name)
		if grey:
			make_grey()
		else:
			paint()
		# install=1: into the game (assets/models/build) plus the preview picture make_piece_icons.py turns into
		# the build-menu icon (owner OK'd the shapes, Nov 17). The broken door is a ruin prop, not a game piece yet.
		fam = FAMILY.get(name, "cut_stone")
		png = str(K.JOUR / f"{name}__{fam}.png") if install else (str(out_dir / f"{name}.png") if "preview" in args else None)
		kit.save(str(out_dir / f"{name}__{fam}.glb"), png, recenter=False, tex_size=512)
		print("PIECE_OK", name)
