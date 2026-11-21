# Shared helpers for the batch-2 new pieces (docs/design/new-pieces-plan.md), used by all three kits
# (stonehold_v2.py, shack_v2.py, hearthbrick_v2_new.py): turning a sloped wall upside down, cutting a round hatch
# hole through a floor, a diagonal lattice of laths, and a pyramid roof cap.
# Coordinates are game coordinates (y up, front +z) unless a name says Blender.
import math

import bpy
from mathutils import Matrix, Vector

import kit_zone1 as K

R2 = math.sqrt(2.0)


def _since(before):
	return [o for o in bpy.data.objects if o not in before]


def tag(objs, role):
	for o in objs:
		o["role"] = role
	return objs


def flip_down(h):
	"""Turn everything built so far half a turn round the front-back axis and lift it by h: a sloped wall that is
	high at +x becomes one that is full along the top and slants down to x = -w/2 (the 'upside-down' sloped wall)."""
	M = Matrix.Translation((0.0, 0.0, h)) @ Matrix.Rotation(math.pi, 4, "Y")   # Blender y = -game z
	for o in bpy.data.objects:
		if o.parent is None:
			o.matrix_world = M @ o.matrix_world


def bevel(o, w=0.012, seg=1):
	b = o.modifiers.new("chisel", "BEVEL")
	b.width, b.segments, b.limit_method, b.angle_limit = w, seg, "ANGLE", math.radians(35)
	return o


# ---------------- lattice ----------------
def lattice(x0, x1, y0, y1, z, step, bw, bd, m_fn, role, fr=None):
	"""A diagonal lattice of laths filling the opening x0..x1, y0..y1 (wall space, centred at depth z): one layer
	leaning one way in front, one leaning the other way behind it, the two layers sunk into each other a little
	(no faces in the same place). Each lath is bw wide, bd deep, cut to the opening. Returns the crossing points."""
	fr = fr or K.Frame()
	hw = bw / 2 * R2   # half width measured along x
	big = [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]
	cx = (x0 + x1) / 2
	cy = (y0 + y1) / 2
	span = (x1 - x0) + (y1 - y0)
	n = int(span / step) + 2
	for sgn, dz in ((1, bd * 0.32), (-1, -bd * 0.32)):
		for k in range(-n, n + 1):
			c = k * step   # lath centre line: sgn*(x - cx) - (y - cy) = c
			planes = [(sgn, -1.0, c + hw + sgn * cx - cy), (-sgn, 1.0, -(c - hw) - sgn * cx + cy)]
			poly = K.clip_poly(big, planes)
			if not poly or K.area(poly) < 0.002:
				continue
			before = set(bpy.data.objects)
			o = K.slab_poly(fr, poly, z + dz, bd, m_fn())
			bevel(o, min(0.008, bw * 0.2))
			tag(_since(before), role)
	pts = []
	for i in range(-n, n + 1):
		for j in range(-n, n + 1):
			# crossing of x - y = i*step and -(x) - y = j*step (relative to the centre)
			u, v = i * step, j * step
			x, y = cx + (u - v) / 2, cy + (-u - v) / 2
			if x0 + bw < x < x1 - bw and y0 + bw < y < y1 - bw:
				pts.append((x, y))
	return pts


# ---------------- round hatch hole ----------------
def cut_round_hole(cx, cz, r, deeper=()):
	"""Cut a round hole straight down through every part (a boolean per part). Parts whose role is in `deeper`
	(the hidden backing) are cut 1.5 cm wider, so their cut faces never sit on the visible parts' cut faces."""
	cutters = {}

	def cutter(rr):
		if rr not in cutters:
			bpy.ops.mesh.primitive_cylinder_add(vertices=40, radius=rr, depth=4.0, location=K.G((cx, 0.0, cz)))
			c = bpy.context.active_object
			c.name = f"cutter_{rr:.3f}"
			cutters[rr] = c
		return cutters[rr]
	parts = [o for o in bpy.data.objects if o.type == "MESH"]
	dg = bpy.context.evaluated_depsgraph_get()
	for o in parts:
		x, _, z = (o.matrix_world @ Vector(o.bound_box[0]))[:]
		rr = r + (0.015 if o.get("role") in deeper else 0.0)
		# skip parts far from the hole (their bounding box misses the circle)
		bb = [o.matrix_world @ Vector(c) for c in o.bound_box]
		gx = [p.x for p in bb]
		gz = [-p.y for p in bb]
		nx = min(max(cx, min(gx)), max(gx))
		nz = min(max(cz, min(gz)), max(gz))
		if math.hypot(nx - cx, nz - cz) > rr:
			continue
		far = max(math.hypot(px - cx, pz - cz) for px in (min(gx), max(gx)) for pz in (min(gz), max(gz)))
		if far < rr:   # wholly inside the hole
			bpy.data.objects.remove(o)
			continue
		me = bpy.data.meshes.new_from_object(o.evaluated_get(dg))
		o.modifiers.clear()
		o.data = me
		mod = o.modifiers.new("hole", "BOOLEAN")
		mod.operation, mod.solver, mod.object = "DIFFERENCE", "EXACT", cutter(rr)
		bpy.context.view_layer.objects.active = o
		bpy.ops.object.modifier_apply(modifier=mod.name)
		if not o.data.polygons:
			bpy.data.objects.remove(o)
	for c in cutters.values():
		bpy.data.objects.remove(c)


def ring_mesh(cx, cz, r_in, r_out, y0, y1, m, n=32, a0=0.0, a1=math.tau):
	"""A flat ring (or a part of one) seen from above: a hatch rim or a lid band."""
	full = abs(a1 - a0 - math.tau) < 1e-6
	k = n if full else n + 1
	pts_o = [(cx + r_out * math.cos(a0 + (a1 - a0) * i / n), cz - r_out * math.sin(a0 + (a1 - a0) * i / n)) for i in range(k)]
	pts_i = [(cx + r_in * math.cos(a0 + (a1 - a0) * i / n), cz - r_in * math.sin(a0 + (a1 - a0) * i / n)) for i in range(k)]
	verts = [(x, y0, z) for x, z in pts_o] + [(x, y1, z) for x, z in pts_o] + [(x, y0, z) for x, z in pts_i] + [(x, y1, z) for x, z in pts_i]
	faces = []
	L = k
	rng = range(n) if full else range(n)
	for i in rng:
		j = (i + 1) % L
		faces.append((i, j, L + j, L + i))                    # outer side
		faces.append((2 * L + j, 2 * L + i, 3 * L + i, 3 * L + j))  # inner side
		faces.append((L + i, L + j, 3 * L + j, 3 * L + i))      # top
		faces.append((j, i, 2 * L + i, 2 * L + j))              # bottom
	if not full:
		faces.append((0, L, 3 * L, 2 * L))
		faces.append((L - 1, 2 * L + L - 1, 3 * L + L - 1, L + L - 1))
	return K.mesh(verts, faces, m)


def disc_poly(cx, cz, r, n=28):
	return [(cx + r * math.cos(math.tau * i / n), cz - r * math.sin(math.tau * i / n)) for i in range(n)]


# ---------------- pyramid roof cap ----------------
def face_slab(pts, t, m, normal):
	"""A thin slab whose outer face is the 3D outline pts (game space), t thick inward (against `normal`)."""
	nv = Vector(normal).normalized()
	outer = [Vector(p) for p in pts]
	inner = [p - nv * t for p in outer]
	n = len(pts)
	verts = [tuple(p) for p in outer] + [tuple(p) for p in inner]
	faces = [tuple(range(n)), tuple(reversed(range(n, 2 * n)))] + [(i, i + n, (i + 1) % n + n, (i + 1) % n) for i in range(n)]
	o = K.mesh(verts, faces, m)
	_fix_normals(o)
	return o


def _fix_normals(o):
	import bmesh
	bm = bmesh.new()
	bm.from_mesh(o.data)
	bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
	bm.to_mesh(o.data)
	bm.free()


def pyramid_cap(s, y_base, h, rows, t, tile_m, tile_role, ridge_m, ridge_role, tile_w=0.22, gap=0.006, rng=None):
	"""A four-sided pyramid cap, open underneath: on each face rows of tiles/shingles from the eave up to the tip
	(every other row a little sunk so rows overlap like real ones, never two faces in one place), and a ridge
	along each of the four hip lines. s = half the base width (outer surface), apex at y_base + h."""
	rng = rng or K.rng
	apex = Vector((0.0, y_base + h, 0.0))
	corners = [Vector((s, y_base, s)), Vector((s, y_base, -s)), Vector((-s, y_base, -s)), Vector((-s, y_base, s))]
	for f in range(4):
		A, B = corners[f], corners[(f + 1) % 4]
		mid = (A + B) / 2
		nrm = (B - A).cross(apex - A).normalized()
		if nrm.dot(Vector((mid.x, 0, mid.z))) < 0:
			nrm = -nrm
		for k in range(rows):
			v0 = k / rows
			v1 = min(1.0, (k + 1) / rows + 0.35 / rows)
			if v0 > 0.93:
				break
			sink = (0.0 if k % 2 == 0 else t * 0.55)
			a0, b0 = A.lerp(apex, v0), B.lerp(apex, v0)
			a1, b1 = A.lerp(apex, v1), B.lerp(apex, v1)
			L0 = (b0 - a0).length
			nt = max(1, round(L0 / tile_w))
			cuts = [0.0] + [(i + rng.uniform(-0.2, 0.2) + (0.5 if k % 2 else 0.0)) / nt for i in range(1, nt)] + [1.0]
			cuts = sorted(min(1.0, max(0.0, c)) for c in cuts)
			for i in range(len(cuts) - 1):
				u0, u1 = cuts[i], cuts[i + 1]
				if u1 - u0 < 0.06:
					continue
				g0 = gap / max(L0, 0.05) / 2
				# the tiles stop 3 cm short of each hip (under the ridge), so two faces' tiles never meet there
				hip = 0.03 / max(L0, 0.05)
				u0, u1 = max(u0, hip), min(u1, 1.0 - hip)
				if u1 - u0 < 0.04:
					continue
				p0, p1 = a0.lerp(b0, u0 + g0), a0.lerp(b0, u1 - g0)
				q0, q1 = a1.lerp(b1, u0 + g0 * L0 / max((b1 - a1).length, 0.03)), a1.lerp(b1, u1 - g0 * L0 / max((b1 - a1).length, 0.03))
				pts = [p - nrm * sink for p in (p0, p1, q1, q0)]
				o = face_slab([tuple(p) for p in pts], t * rng.uniform(0.85, 1.0), tile_m(), nrm)
				o["role"] = tile_role
				o["dark"] = rng.random() < 0.08
	# hip ridges: a chunky strip over each hip line, on top of the tiles (the tiles stop under it)
	for f in range(4):
		C = corners[f]
		d = (apex - C).normalized()
		out = Vector((C.x, 0, C.z)).normalized()
		up = d.cross(out.cross(d)).normalized()
		side = d.cross(up).normalized()
		rw, rh = 0.07, 0.04
		nseg = 3
		for k in range(nseg):
			c0 = C.lerp(apex, k / nseg + (0.004 if k else 0.05))
			c1 = C.lerp(apex, (k + 1) / nseg - 0.004)
			pts = []
			for p in (c0, c1):
				pts.append(p + side * rw)
			pts += [c1 - side * rw, c0 - side * rw]
			o = face_slab([tuple(p + up * (rh - 0.012)) for p in pts], rh, ridge_m(), up)   # mostly proud of the tiles
			bevel(o, 0.01)
			o["role"] = ridge_role


def clip_to_disc(rect, cx, cz, r, n=28):
	"""A convex outline [(x, z)...] cut to the round disc (centre cx, cz, radius r)."""
	disc = disc_poly(cx, cz, r, n)
	planes = []
	for i in range(n):
		(ax, az), (bx, bz) = disc[i], disc[(i + 1) % n]
		nx, nz = bz - az, -(bx - ax)
		if nx * (cx - ax) + nz * (cz - az) > 0:
			nx, nz = -nx, -nz
		planes.append((nx, nz, nx * ax + nz * az))
	return K.clip_poly(rect, planes)


def lid_boards(cx, cz, r, y0, y1, n_boards, m_fn, role, gap=0.008):
	"""A round lid of n boards side by side (running along z), cut to the circle; returns the boards."""
	out = []
	bw = 2 * r / n_boards
	for i in range(n_boards):
		xa, xb = cx - r + i * bw + gap / 2, cx - r + (i + 1) * bw - gap / 2
		poly = clip_to_disc([(xa, cz - r - 0.1), (xb, cz - r - 0.1), (xb, cz + r + 0.1), (xa, cz + r + 0.1)], cx, cz, r)
		if poly and K.area(poly) > 0.003:
			before = set(bpy.data.objects)
			o = K.floor_poly(poly, y0, y1 - K.rng.uniform(0, 0.006), m_fn())
			bevel(o, 0.008)
			tag(_since(before), role)
			out.append(o)
	return out
