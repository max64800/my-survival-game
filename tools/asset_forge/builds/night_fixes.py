# Stations remade from the night "fix" pictures (FEEDBACK F34-F65), one object per picture.
#   blender --background --factory-startup --python builds/night_fixes.py -- [name ...]   (none = all)
# Uses the helpers in night_stations.py. Blender coords: x right, y back (front = -Y), z up.
import math
import sys
from pathlib import Path

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
from night_stations import (B, GAME, J, T, cband, disc, ember_bed, kit, log, mesh, plank, rivet, rng,  # noqa: E402
	stone, stream, water_disc)


def _pear(z, t, m, sc=1.0):
	pts = []
	for i in range(24):
		a = 2 * math.pi * i / 24
		rx = (0.36 if math.cos(a) > 0 else 0.22) * sc
		pts.append((0.05 + math.cos(a) * rx * (1 + J(0.015)), math.sin(a) * 0.2 * sc * (1 - 0.35 * max(0, -math.cos(a)))))
	v = [(x, y, z) for x, y in pts] + [(x, y, z + t) for x, y in pts]
	n = len(pts)
	f = [tuple(range(n)), tuple(range(n, 2 * n))] + [(i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n)]
	return mesh(v, f, m)


def bellows():
	"""F34: one hinged piece: two pear-shaped boards with handle loops, pleated leather between them,
	a copper nozzle and hinge strap, on a small stand."""
	_pear(0.16, 0.05, T("wood", "b"))
	_pear(0.41, 0.05, T("wood", "c"))
	for k in range(4):
		_pear(0.21 + k * 0.05, 0.05, kit.tex_mat("leather", "dark" if k % 2 else "a"), sc=0.9 if k % 2 else 0.97)
	for k in range(10):
		a = 2 * math.pi * k / 10
		rx = 0.36 if math.cos(a) > 0 else 0.22
		rivet((0.05 + math.cos(a) * rx * 0.9, math.sin(a) * 0.17, 0.46), r=0.013)
	for z in (0.185, 0.435):
		kit.ring(0.07, 0.022, (0.5, 0, z), T("wood", "b"), seg=14)
		B((0.1, 0.06, 0.04), (0.42, 0, z), T("wood", "b"), bevel=0.008)
	cband((0.05, 0.12, 0.32), (-0.16, 0, 0.3), rivets=2, axis="z", face=-1)
	B((0.06, 0.16, 0.2), (-0.17, 0, 0.29), kit.tex_mat("leather", "dark"), bevel=0.01)
	kit.cone(0.06, 0.025, 0.2, (-0.28, 0, 0.29), kit.tex_mat("copper", "b"), rot=(0, -90, 0), verts=12, bevel=0.004)
	for x in (-0.12, 0.28):
		B((0.07, 0.34, 0.07), (x, 0, 0.125), T("wood", "dark"), bevel=0.01)
		for y in (-0.14, 0.14):
			B((0.07, 0.07, 0.12), (x, y, 0.06), T("wood", "dark"), bevel=0.01)
	for y in (-0.14, 0.14):
		B((0.44, 0.06, 0.06), (0.08, y, 0.05), T("wood", "dark"), bevel=0.008)


def campfire():
	"""F35: a ring of rough stones sitting in a dirt patch, crossed logs resting on embers (flames = game effect)."""
	disc(0.58, 0.0, 0.025, (0, 0), T("soil"), seg=22, wob=0.08)
	for k in range(10):
		a = 2 * math.pi * k / 10 + J(0.1)
		stone((0.2, 0.17, 0.17), (math.cos(a) * 0.4, math.sin(a) * 0.4, 0.09), rotz=math.degrees(a))
	ember_bed(0, 0, 0.02, 0.2, n=12)
	for k in range(4):
		a = k * math.pi / 4 + 0.2
		dx, dy = math.cos(a) * 0.3, math.sin(a) * 0.3
		log((-dx, -dy, 0.07 + 0.035 * (k % 2)), (dx, dy, 0.07 + 0.035 * (k % 2)), 0.045, T("bark"), seg=7, rings=2, bend=0.05)
	kit.fire_spot((0, 0, 0.08), 1.0)


def carpenters_vise():
	"""F36: a carpenter's bench crowded with work (planks, saw, mallet, square, shavings, pegs), a vise on
	the front, a shelf below with planks and a tool box."""
	W, D, H = 1.3, 0.75, 0.82
	for x in (-W / 2 + 0.08, W / 2 - 0.08):
		for y in (-D / 2 + 0.08, D / 2 - 0.08):
			B((0.13, 0.13, H - 0.06), (x, y, (H - 0.06) / 2 + 0.02), T("wood", "b"), bevel=0.018)
			stone((0.17, 0.17, 0.05), (x, y, 0.025), tone=T("stone"), bevel=0.015)
	for y in (-D / 2 + 0.08, D / 2 - 0.08):
		B((W - 0.16, 0.07, 0.08), (0, y, 0.22), T("wood", "dark"), bevel=0.01)
	for i in range(4):
		plank((W - 0.2, (D - 0.16) / 4 - 0.01, 0.04), (0, -D / 2 + 0.08 + (D - 0.16) * (i + 0.5) / 4, 0.28))
	for i in range(5):
		plank((W + 0.08, D / 5 - 0.008, 0.08), (0, -D / 2 + D * (i + 0.5) / 5, H - 0.02))
	vx = -W / 2 + 0.2
	B((0.22, 0.06, 0.2), (vx, -D / 2 - 0.03, H - 0.12), T("wood", "dark"), bevel=0.012)
	for x in (vx - 0.08, vx + 0.08):
		B((0.04, 0.05, 0.18), (x, -D / 2 - 0.07, H - 0.12), kit.tex_mat("iron"), bevel=0.005)
	log((vx, -D / 2 - 0.01, H - 0.12), (vx, -D / 2 - 0.22, H - 0.12), 0.02, kit.tex_mat("iron"), seg=6, rings=1, ends=False, bend=0)
	log((vx - 0.12, -D / 2 - 0.22, H - 0.12), (vx + 0.12, -D / 2 - 0.22, H - 0.12), 0.018, T("wood", "c"), seg=6, rings=1, ends=False, bend=0)
	tz = H + 0.02
	for k in range(3):
		plank((0.6, 0.12, 0.04), (-0.25 + J(0.02), 0.18, tz + 0.02 + k * 0.04), m=T("wood", "c"))
	B((0.4, 0.12, 0.008), (0.22, -0.06, tz + 0.004), kit.tex_mat("iron", "a"), bevel=0.002, rot=(0, 0, 15))  # saw blade
	B((0.13, 0.08, 0.04), (0.45, 0.0, tz + 0.02), T("wood", "dark"), bevel=0.008, rot=(0, 0, 15))  # saw handle
	B((0.14, 0.1, 0.09), (-0.1, -0.16, tz + 0.045), T("wood", "dark"), bevel=0.012)  # mallet head
	log((-0.03, -0.16, tz + 0.03), (0.16, -0.22, tz + 0.02), 0.022, T("wood", "c"), seg=7, rings=1)
	B((0.22, 0.03, 0.012), (0.42, 0.2, tz + 0.006), kit.tex_mat("iron"), bevel=0.002)  # square
	B((0.03, 0.14, 0.012), (0.52, 0.27, tz + 0.006), kit.tex_mat("iron"), bevel=0.002)
	for k in range(3):
		kit.cylinder(0.014, 0.08, (0.15 + k * 0.04, 0.25, tz + 0.04), T("wood", "c"), verts=6, bevel=0)
	for k in range(5):
		kit.ring(0.025, 0.006, (-0.45 + k * 0.05, -0.22 + J(0.04), tz + 0.02), T("wood", "c"), rot=(70 + J(15), 0, J(60)), seg=10)
	B((0.32, 0.2, 0.14), (0.3, 0, 0.37), T("wood", "dark"), bevel=0.01)
	log((0.16, 0, 0.5), (0.44, 0, 0.5), 0.015, T("wood", "c"), seg=6, rings=1, ends=False, bend=0)
	for x in (0.16, 0.44):
		B((0.02, 0.02, 0.1), (x, 0, 0.45), T("wood", "c"), bevel=0.003)


def tanning_rack():
	"""F45: a log frame leaning back on two rear props (lashed), a hide laced on with rope, a scraper hanging."""
	Hh, Wd, lean = 1.55, 1.4, 0.35
	y0 = -0.18
	for s_ in (-1, 1):
		x = s_ * Wd / 2
		log((x, y0, 0), (x, y0 + lean, Hh), 0.055, T("bark"), seg=8, rings=3)
		log((x, y0 + lean - 0.02, Hh - 0.1), (x * 0.92, y0 + lean + 0.45, 0.0), 0.045, T("bark"), seg=7, rings=2)
		kit.ring(0.068, 0.016, (x, y0 + lean - 0.02, Hh - 0.1), kit.tex_mat("rope"), seg=12)
		stone((0.16, 0.14, 0.06), (x, y0, 0.03), tone=T("stone"))
		stone((0.16, 0.14, 0.06), (x * 0.92, y0 + lean + 0.45, 0.03), tone=T("stone"))
	for f in (0.08, 0.92):
		log((-Wd / 2 - 0.05, y0 + lean * f, Hh * f), (Wd / 2 + 0.05, y0 + lean * f, Hh * f), 0.05, T("bark"), seg=8, rings=3)
	ang = math.atan2(lean, Hh)
	o = kit.hide(Wd * 0.75, Hh * 0.66, (0, 0, 0), kit.tex_mat("leather"), thick=0.02, seed=5)
	o.rotation_euler = (-ang, 0, 0)
	o.location = (0, y0 + lean * 0.5, Hh * 0.5)
	bpy.context.view_layer.update()
	o.data.transform(o.matrix_world)
	o.matrix_world.identity()
	# lacing (F932, F82 said 3x): every rope starts ON the hide, just inside its real edge, and ends in a frame log.
	def at(t):
		return y0 + lean * t, Hh * t
	hw, hh = Wd * 0.75, Hh * 0.66
	slant = math.hypot(lean, Hh)
	outline = kit.hide_outline(hw, hh, seed=5)

	def on_hide(i, inset=0.035):
		x, z = outline[i % len(outline)]
		d = math.hypot(x, z)
		x, z = x * (d - inset) / d, z * (d - inset) / d
		t = 0.5 + z / slant  # how far up the frame this point sits
		yy, zz = at(t)
		return (x, yy, zz), t
	n = len(outline)
	for i in (n - 3, n - 1, 1, 3):  # right side, between the leg flaps (5 lie at 0/360, flaps at 45)
		for mirror in (False, True):
			j = (n // 2 - i) % n if mirror else i  # the same spot on the left side
			p, t = on_hide(j)
			side = -1 if mirror else 1
			log(p, (side * Wd / 2, p[1], p[2]), 0.011, kit.tex_mat("rope"), seg=5, rings=1, ends=False, bend=0)
	for i in (n // 4 - 2, n // 4, n // 4 + 2, 3 * n // 4 - 2, 3 * n // 4, 3 * n // 4 + 2):  # top and bottom edges
		p, t = on_hide(i)
		yb, zb = at(0.92 if t > 0.5 else 0.08)
		log(p, (p[0], yb, zb), 0.011, kit.tex_mat("rope"), seg=5, rings=1, ends=False, bend=0)
	for i in (n // 8, 3 * n // 8, 5 * n // 8, 7 * n // 8):  # the four leg flaps pull out to the frame corners
		p, t = on_hide(i, inset=0.03)
		yc, zc = at(0.92 if t > 0.5 else 0.08)
		log(p, (math.copysign(Wd / 2, p[0]), yc, zc), 0.011, kit.tex_mat("rope"), seg=5, rings=1, ends=False, bend=0)
	sy, sz = at(0.62)
	sx = Wd / 2 + 0.07
	log((Wd / 2, sy, sz), (sx, sy, sz - 0.07), 0.01, kit.tex_mat("rope"), seg=5, rings=1, ends=False, bend=0)
	B((0.03, 0.03, 0.14), (sx, sy, sz - 0.14), T("wood", "c"), bevel=0.005)
	B((0.1, 0.012, 0.06), (sx, sy, sz - 0.23), kit.tex_mat("iron", "a"), bevel=0.003)


def chest_small():
	"""F37: a plank chest with its base as wide as its lid, copper straps and corners, a lock plate, rope handles."""
	w, d, h = 0.9, 0.6, 0.42
	B((w, d, 0.04), (0, 0, 0.02), T("wood", "dark"), bevel=0.01)
	for k in range(4):
		z = 0.04 + (h - 0.04) / 4 * (k + 0.5)
		for y in (-d / 2 + 0.025, d / 2 - 0.025):
			plank((w, 0.05, (h - 0.04) / 4 - 0.008), (0, y, z), m=T("wood", "dark" if k % 2 else "b"))
		for x in (-w / 2 + 0.025, w / 2 - 0.025):
			plank((0.05, d - 0.1, (h - 0.04) / 4 - 0.008), (x, 0, z), m=T("wood", "b" if k % 2 else "dark"))
	lz = h
	for k in range(3):
		plank((w + 0.01, d / 3 - 0.006, 0.08), (0, -d / 2 + d / 3 * (k + 0.5), lz + 0.04 + (0.02 if k == 1 else 0)), m=T("wood", "c"))
	strap = kit.tex_mat("copper", "b")
	for x in (-w / 2 + 0.14, w / 2 - 0.14):
		B((0.08, d + 0.03, 0.03), (x, 0, lz + 0.095), strap, bevel=0.005)
		for y in (-d / 2 - 0.01, d / 2 + 0.01):
			B((0.08, 0.025, h + 0.09), (x, y, (h + 0.09) / 2 + 0.005), strap, bevel=0.005)
			rivet((x, y * 1.06, 0.15))
			rivet((x, y * 1.06, h - 0.05))
	for x in (-w / 2, w / 2):
		for y in (-d / 2, d / 2):
			B((0.06, 0.06, 0.1), (x * 0.985, y * 0.98, 0.07), strap, bevel=0.006)
			B((0.06, 0.06, 0.08), (x * 0.985, y * 0.98, lz + 0.04), strap, bevel=0.006)
	B((0.18, 0.03, 0.2), (0, -d / 2 - 0.02, h - 0.02), strap, bevel=0.012)
	B((0.03, 0.01, 0.06), (0, -d / 2 - 0.038, h - 0.05), kit.mat("charcoal"), bevel=0.003)
	for x in (-w / 2 - 0.015, w / 2 + 0.015):
		B((0.03, 0.12, 0.05), (x, 0, h * 0.62), strap, bevel=0.004)
		kit.ring(0.06, 0.014, (x + math.copysign(0.03, x), 0, h * 0.55), kit.tex_mat("rope"), rot=(0, 90, 0), seg=14)


def chopping_block():
	"""F38: a stump with flared roots and bark, an uneven top (no perfect rings), a real axe bitten into it,
	a few chips against the roots."""
	R = 0.3
	log((0, 0, 0.0), (0, 0, 0.55), R, T("bark"), seg=12, rings=3, bend=0.05, r1=R * 0.92, end_m=T("wood", "c"))
	for k in range(6):
		a = 2 * math.pi * k / 6 + J(0.3)
		log((math.cos(a) * (R - 0.06), math.sin(a) * (R - 0.06), 0.2), (math.cos(a) * (R + 0.16), math.sin(a) * (R + 0.16), 0.0), 0.075,
			T("bark"), seg=7, rings=2, bend=0.1, r1=0.03, ends=False)
	for rr in (0.07, 0.14, 0.2):
		for i in range(12):
			a = 2 * math.pi * i / 12
			r2 = rr * (1 + J(0.12))
			B((0.035, 0.008, 0.004), (math.cos(a) * r2, math.sin(a) * r2, 0.565), T("wood", "dark"), bevel=0, rot=(0, 0, math.degrees(a) + 90))
	# axe: wedge head bitten into the top, handle rising at an angle, leather grip
	B((0.045, 0.2, 0.13), (0.02, -0.05, 0.6), kit.tex_mat("iron", "a"), bevel=0.01, rot=(0, -25, 0))
	B((0.02, 0.22, 0.03), (-0.005, -0.05, 0.555), kit.tex_mat("iron", "c"), bevel=0.004, rot=(0, -25, 0))
	p0, p1 = (0.04, -0.05, 0.63), (0.38, -0.05, 1.0)
	log(p0, p1, 0.025, T("wood", "b"), seg=7, rings=2, end_m=T("wood", "c"))
	g0 = tuple(p0[i] + (p1[i] - p0[i]) * 0.6 for i in range(3))
	g1 = tuple(p0[i] + (p1[i] - p0[i]) * 0.92 for i in range(3))
	log(g0, g1, 0.031, kit.tex_mat("leather", "dark"), seg=8, rings=1, ends=False, bend=0)
	for k in range(4):
		a = k * 1.6 + 0.4
		B((0.07, 0.04, 0.015), (math.cos(a) * (R + 0.06), math.sin(a) * (R + 0.06), 0.012), T("wood", "c"), bevel=0.004, rot=(0, 0, J(90)))


def _chain(p_top, p_bottom, link=0.05):
	iron = kit.tex_mat("iron")
	step = link * 0.9
	n = max(2, int((p_top[2] - p_bottom[2]) / step) + 1)
	for i in range(n):
		z = p_top[2] - i * step
		o = kit.ring(link * 0.42, link * 0.12, (0, 0, 0), iron, rot=(0, 0, 0), seg=10)
		for v in o.data.vertices:
			x, y, zz = v.co.x, v.co.y, v.co.z
			v.co = (x * 0.75, zz, y * 1.45) if i % 2 else (zz, x * 0.75, y * 1.45)
		o.location = (p_top[0], p_top[1], z)


def cooking_pot():
	"""F39/F64: a 3-leg tripod lashed at the top, a chain down to a hammered pot of stew (two shades and
	chunks, not one flat colour), a ladle, over a stone fire ring with logs."""
	tz = 1.25
	for k in range(3):
		a = 2 * math.pi * k / 3 + math.pi / 2
		foot = (math.cos(a) * 0.62, math.sin(a) * 0.62, 0.0)
		log(foot, (-math.cos(a) * 0.05, -math.sin(a) * 0.05, tz + 0.12), 0.045, T("bark"), seg=8, rings=3)
		stone((0.18, 0.16, 0.08), (foot[0], foot[1], 0.04), tone=T("stone"))
	kit.rope_wrap((0, 0), 0.075, tz - 0.06, tz + 0.06, 3, thick=0.02, material=kit.tex_mat("rope"))
	pz = 0.55
	_chain((0, 0, tz - 0.06), (0, 0, pz + 0.3))
	bpy.ops.mesh.primitive_uv_sphere_add(segments=18, ring_count=10, radius=0.25, location=(0, 0, pz))
	o = bpy.context.object
	for v in o.data.vertices:
		if v.co.z > 0.12:
			v.co.z = 0.12
	bpy.ops.object.transform_apply(scale=True)
	kit._finish(o, kit.tex_mat("iron", "dark"), 0, 0)
	kit.roughen(o, 0.006, 1, seed=3)
	kit.ring(0.235, 0.022, (0, 0, pz + 0.12), kit.tex_mat("iron"), seg=20)
	for s_ in (-1, 1):
		kit.ring(0.035, 0.01, (s_ * 0.245, 0, pz + 0.1), kit.tex_mat("iron"), rot=(90, 0, 0), seg=10)
	pts = [(-0.245 + 0.49 * i / 10, 0, pz + 0.1 + math.sin(math.pi * i / 10) * 0.2) for i in range(11)]
	for p, q in zip(pts, pts[1:]):
		log(p, q, 0.009, kit.tex_mat("iron"), seg=5, rings=1, ends=False, bend=0)
	disc(0.225, pz + 0.12, pz + 0.135, (0, 0), kit.mat("wood_dark", -0.35, rough=0.4), seg=18)
	disc(0.15, pz + 0.134, pz + 0.14, (0.02, 0.01), kit.mat("mushroom_red", -0.35, rough=0.35), seg=14, wob=0.15)
	for k in range(8):
		a, r = rng.uniform(0, 6.28), rng.uniform(0.03, 0.17)
		col = ["mushroom_red", "gill", "wood_dark", "sprout"][k % 4]
		kit.gem((math.cos(a) * r, math.sin(a) * r, pz + 0.145), (0.03, 0.03, 0.02), kit.mat(col, 0.2 if col == "mushroom_red" else 0.05), seed=k + 30)
	log((0.05, -0.08, pz + 0.1), (0.2, -0.15, pz + 0.45), 0.012, T("wood", "c"), seg=6, rings=1, ends=False, bend=0)
	for k in range(9):
		a = 2 * math.pi * k / 9
		stone((0.17, 0.15, 0.13), (math.cos(a) * 0.3, math.sin(a) * 0.3, 0.065), rotz=math.degrees(a))
	ember_bed(0, 0, 0.0, 0.15, n=8)
	for k in range(3):
		a = k * math.pi / 3
		log((-math.cos(a) * 0.24, -math.sin(a) * 0.24, 0.06), (math.cos(a) * 0.24, math.sin(a) * 0.24, 0.06 + 0.02 * k), 0.035, T("bark"), seg=7, rings=1)
	kit.fire_spot((0, 0, 0.1), 0.7)


def grindstone():
	"""F41: a sandstone wheel between timber uprights with iron brackets, axle and crank, a stone water
	trough under it (water darker at the bottom), every part on one base."""
	B((0.75, 0.55, 0.1), (0, 0, 0.05), T("wood", "dark"), bevel=0.015)
	for x in (-0.22, 0.22):
		B((0.1, 0.16, 0.62), (x, 0, 0.1 + 0.31), T("wood", "b"), bevel=0.015)
		for y in (-0.15, 0.15):
			B((0.08, 0.14, 0.08), (x, y, 0.14), T("wood", "b"), bevel=0.01)
		cband((0.115, 0.17, 0.08), (x, 0, 0.62), rivets=1)
	B((0.54, 0.1, 0.08), (0, 0.12, 0.2), T("wood", "b"), bevel=0.01)
	B((0.34, 0.34, 0.14), (0, 0, 0.17), T("stone"), bevel=0.02)
	water_disc(0.12, 0.245, (0, 0), depth=0.03)
	kit.cylinder(0.27, 0.12, (0, 0, 0.55), T("stone", "c"), rot=(0, 90, 0), verts=22, bevel=0.012)
	log((-0.3, 0, 0.55), (0.36, 0, 0.55), 0.025, kit.tex_mat("iron"), seg=8, rings=1, ends=False, bend=0)
	log((0.36, 0, 0.55), (0.36, 0, 0.42), 0.02, kit.tex_mat("iron"), seg=6, rings=1, ends=False, bend=0)
	log((0.36, 0, 0.42), (0.5, 0, 0.42), 0.03, T("wood", "c"), seg=8, rings=1)
	stream((0, -0.24, 0.5), (0, -0.08, 0.245), r=0.008)


def stone_saw():
	"""F44/F65: a heavy sawhorse table, a stone block in two halves with a cut, a frame saw standing IN the
	cut, a clamp screw, cut bricks against a leg."""
	W, D, H = 0.7, 0.9, 0.62
	for x in (-W / 2 + 0.08, W / 2 - 0.08):
		for y in (-D / 2 + 0.1, D / 2 - 0.1):
			log((x * 1.2, y * 1.12, 0.06), (x, y, H - 0.04), 0.05, T("wood", "b"), seg=6, rings=1, ends=False, bend=0)
			B((0.12, 0.12, 0.07), (x * 1.2, y * 1.12, 0.035), kit.tex_mat("iron"), bevel=0.01)
		log((x * 1.1, -D / 2 + 0.08, 0.25), (x * 1.1, D / 2 - 0.08, 0.25), 0.035, T("wood", "dark"), seg=6, rings=1)
	for i in range(3):
		plank((W + 0.06, D / 3 - 0.01, 0.1), (0, -D / 2 + D / 3 * (i + 0.5), H))
	for y in (-0.25, 0.25):
		cband((W + 0.08, 0.06, 0.12), (0, y, H), rivets=2)
	bz = H + 0.05
	for y in (-0.13, 0.13):
		B((0.42, 0.24, 0.3), (0, y, bz + 0.15), T("stone", "c"), bevel=0.02, rot=(J(1), J(1), J(2)))
	B((0.42, 0.03, 0.02), (0, 0, bz + 0.01), kit.mat("charcoal", 0.6), bevel=0)
	blade_z = bz + 0.02
	B((0.62, 0.008, 0.16), (0, 0, blade_z + 0.08), kit.tex_mat("iron", "a"), bevel=0.002)
	for x in (-0.33, 0.33):
		B((0.05, 0.05, 0.46), (x, 0, blade_z + 0.23), T("wood", "b"), bevel=0.008)
	B((0.7, 0.04, 0.04), (0, 0, blade_z + 0.33), T("wood", "b"), bevel=0.006)
	log((-0.33, 0, blade_z + 0.44), (0.33, 0, blade_z + 0.44), 0.008, kit.tex_mat("rope"), seg=5, rings=1, ends=False, bend=0)
	log((0, -D / 2 + 0.05, H), (0, -D / 2 - 0.12, H), 0.02, kit.tex_mat("iron"), seg=6, rings=1, ends=False, bend=0)
	log((-0.09, -D / 2 - 0.12, H), (0.09, -D / 2 - 0.12, H), 0.016, kit.tex_mat("copper", "b"), seg=6, rings=1, ends=False, bend=0)
	for k in range(2):
		B((0.26, 0.12, 0.1), (-W / 2 - 0.1, -0.12 + k * 0.14, 0.05), T("stone", "c"), bevel=0.012, rot=(0, 0, 10 * k))


def tool_rack():
	"""F46: a board that hangs on a wall (flat back): copper corner plates, a pickaxe, hammer, saw and tongs
	on hooks, and a ledge with nails."""
	W, Hh, d = 1.0, 0.75, 0.06
	for i in range(4):
		plank((W, d, Hh / 4 - 0.008), (0, 0, Hh / 4 * (i + 0.5)), m=T("wood", "dark" if i % 2 else "b"))
	for x in (-W / 2 + 0.06, W / 2 - 0.06):
		B((0.08, d + 0.02, Hh), (x, 0, Hh / 2), T("wood", "dark"), bevel=0.012)
		for z in (0.06, Hh - 0.06):
			B((0.12, 0.012, 0.12), (x, -d / 2 - 0.011, z), kit.tex_mat("copper", "b"), bevel=0.004)
			rivet((x, -d / 2 - 0.018, z))
	B((W - 0.1, 0.1, 0.04), (0, -d / 2 - 0.05, 0.05), T("wood", "b"), bevel=0.008)
	for k in range(3):
		B((0.012, 0.05, 0.012), (-0.25 + k * 0.05, -0.08, 0.077), kit.tex_mat("iron"), bevel=0.002, rot=(0, 0, 20 * k))
	fy = -d / 2 - 0.035
	for x in (-0.32, -0.1, 0.12, 0.32):
		B((0.03, 0.07, 0.03), (x, -d / 2 - 0.03, Hh - 0.12), kit.tex_mat("copper", "b"), bevel=0.004)
	x = -0.32
	B((0.04, 0.03, 0.42), (x, fy, Hh - 0.34), T("wood", "b"), bevel=0.006)
	B((0.3, 0.035, 0.05), (x, fy, Hh - 0.15), kit.tex_mat("iron"), bevel=0.008)
	x = -0.1
	B((0.035, 0.03, 0.34), (x, fy, Hh - 0.3), T("wood", "b"), bevel=0.006)
	B((0.12, 0.05, 0.07), (x, fy, Hh - 0.15), kit.tex_mat("iron", "dark"), bevel=0.008)
	x = 0.12
	B((0.1, 0.008, 0.36), (x, fy, Hh - 0.36), kit.tex_mat("iron", "a"), bevel=0.002)
	B((0.1, 0.03, 0.08), (x, fy, Hh - 0.16), T("wood", "c"), bevel=0.008)
	x = 0.32
	for s_ in (-1, 1):
		B((0.015, 0.015, 0.36), (x + s_ * 0.02, fy, Hh - 0.32), kit.tex_mat("iron"), bevel=0.003, rot=(0, s_ * 3, 0))
	B((0.06, 0.015, 0.02), (x, fy, Hh - 0.14), kit.tex_mat("iron"), bevel=0.003)


def training_dummy():
	"""F47: a lumpy stitched sack head with a cross face, a burlap body tied with rope, straw arms on a cross
	pole, a straw skirt, on a post with a cross foot."""
	for a in (0, 90):
		B((0.7, 0.12, 0.1), (0, 0, 0.05), T("wood", "dark"), bevel=0.012, rot=(0, 0, a))
	B((0.14, 0.14, 0.12), (0, 0, 0.12), kit.tex_mat("copper", "b"), bevel=0.008)
	log((0, 0, 0.06), (0, 0, 1.5), 0.05, T("wood", "b"), seg=8, rings=2, bend=0.03)
	bpy.ops.mesh.primitive_uv_sphere_add(segments=14, ring_count=8, radius=0.2, location=(0, 0, 1.0))
	o = bpy.context.object
	o.scale = (1.0, 0.8, 1.45)
	bpy.ops.object.transform_apply(scale=True)
	kit._finish(o, kit.tex_mat("sack"), 0, 0)
	kit.roughen(o, 0.02, 1, seed=8)
	kit.ring(0.16, 0.02, (0, 0, 1.24), kit.tex_mat("rope"), seg=14)
	kit.ring(0.185, 0.02, (0, 0, 0.82), kit.tex_mat("rope"), seg=14)
	B((0.08, 0.02, 0.08), (0.06, -0.155, 1.05), kit.tex_mat("leather"), bevel=0.004, rot=(0, 10, 0))
	for k in range(14):
		a = 2 * math.pi * k / 14
		B((0.035, 0.012, 0.2), (math.cos(a) * 0.17, math.sin(a) * 0.14, 0.73), kit.tex_mat("straw"), bevel=0.002,
			rot=(math.sin(a) * 15, -math.cos(a) * 15, math.degrees(a) + 90))
	log((-0.42, 0, 1.18), (0.42, 0, 1.18), 0.03, T("wood", "b"), seg=6, rings=2)
	for s_ in (-1, 1):
		kit.ring(0.045, 0.015, (s_ * 0.3, 0, 1.18), kit.tex_mat("rope"), rot=(0, 90, 0), seg=10)
		for k in range(5):
			B((0.14, 0.012, 0.03), (s_ * 0.47, J(0.02), 1.18 + (k - 2) * 0.02), kit.tex_mat("straw"), bevel=0.002, rot=(J(10), J(15), (k - 2) * 12 * s_))
	bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 1.46))
	h = bpy.context.object
	h.scale = (0.28, 0.24, 0.26)
	bpy.ops.object.transform_apply(scale=True)
	sub = h.modifiers.new("s", "SUBSURF")
	sub.levels = 2
	bpy.context.view_layer.objects.active = h
	bpy.ops.object.modifier_apply(modifier="s")
	kit._finish(h, kit.tex_mat("sack"), 0, 0)
	kit.roughen(h, 0.015, 1, seed=12)
	for s_ in (-1, 1):
		kit.cone(0.05, 0.01, 0.08, (s_ * 0.1, 0, 1.6), kit.tex_mat("sack"), verts=6, bevel=0)
	kit.ring(0.06, 0.014, (0, 0, 1.33), kit.tex_mat("rope"), seg=10)
	dark = kit.mat("charcoal", 0.1)
	for s_ in (-1, 1):
		B((0.07, 0.02, 0.02), (s_ * 0.06, -0.115, 1.5), dark, bevel=0.002, rot=(0, s_ * 20, 0))
	B((0.1, 0.02, 0.018), (0, -0.115, 1.41), dark, bevel=0.002)
	for k in range(4):
		B((0.008, 0.02, 0.06), (0.1, -0.105, 1.39 + k * 0.035), dark, bevel=0)


LIDS = {"chest_small": 0.42}  # lid height: the lid is its own part that swings open (owner F345)

MODELS = {
	"bellows": bellows, "campfire": campfire, "carpenters_vise": carpenters_vise, "tanning_rack": tanning_rack,
	"chest_small": chest_small, "chopping_block": chopping_block, "cooking_pot": cooking_pot, "grindstone": grindstone,
	"stone_saw": stone_saw, "tool_rack": tool_rack, "training_dummy": training_dummy,
}

if __name__ == "__main__":
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	for name in args or list(MODELS):
		rng.seed(sum(map(ord, name)))
		kit.reset()
		try:
			MODELS[name]()
			out = GAME / "assets" / "models" / "stations" / f"{name}.glb"
			kit.save(str(out), str(GAME / "journey" / "3d" / "v2_hand_built" / "stations" / f"{name}.png"),
				lid=LIDS.get(name))
			print(f"MODEL_OK {name}")
		except Exception as e:
			import traceback
			traceback.print_exc()
			print(f"MODEL_FAILED {name}: {e!r}")
