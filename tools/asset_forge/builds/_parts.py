# Bigger shared parts built from the kit (chests, furnace domes, fire pits, chains).
import math
import random

import kit


def chest(body="wood", bands="iron", w=0.9, d=0.6, h=0.42):
	"""A chest: plank box, rounded lid, metal straps that wrap the lid, flush corner brackets and a lock plate."""
	# The body is built from stacked planks, like the lid: no plain block anywhere.
	rows = 4
	ph = h / rows
	for k in range(rows):
		z = ph * (k + 0.5)
		for y in (-d / 2 + 0.025, d / 2 - 0.025):
			kit.plank((w, 0.05, ph - 0.006), (0, y, z), dark=(k % 2 == 1))
		for x in (-w / 2 + 0.025, w / 2 - 0.025):
			kit.plank((0.05, d - 0.1, ph - 0.006), (x, 0, z), dark=(k % 2 == 0))
	kit.plank((w - 0.1, d - 0.1, 0.04), (0, 0, 0.02), dark=True)
	kit.plank((w - 0.1, d - 0.1, 0.02), (0, 0, h - 0.01), dark=True)
	r = d / 2
	o = kit.cylinder(r, w - 0.02, (0, 0, h), kit.tex_mat("wood", "c"), rot=(0, 90, 0), verts=16, bevel=0.012)
	o.scale = (1, 1, 0.75)
	strap = kit.tex_mat(bands)
	for x in (-w / 2 + 0.12, w / 2 - 0.12):
		kit.box((0.09, d + 0.03, h - 0.14), (x, 0, 0.08 + (h - 0.14) / 2), strap, bevel=0.008, wobble=0.002)
		kit.ring(r + 0.005, 0.025, (x, 0, h), strap, rot=(0, 90, 0), seg=20).scale = (1, 1, 0.78)
		for z in (0.14, h - 0.08):
			kit.rivet((x, -d / 2 - 0.02, z), r=0.02)
	# Flush corner brackets on the upper part of the vertical edges only.
	for x in (-w / 2, w / 2):
		for y in (-d / 2, d / 2):
			kit.box((0.05, 0.05, h * 0.45), (x * 0.99, y * 0.985, h * 0.72), strap, bevel=0.006, wobble=0.001)
	kit.box((0.16, 0.04, 0.18), (0, -d / 2 - 0.02, h - 0.02), strap, bevel=0.012, wobble=0.002)
	kit.box((0.03, 0.02, 0.06), (0, -d / 2 - 0.045, h - 0.04), kit.mat("charcoal"), bevel=0.004, wobble=0)


def chain(p_top, p_bottom, link=0.05):
	"""A hanging iron chain of alternating links."""
	iron = kit.tex_mat("iron")
	# Each link is an upright oval; neighbours turn 90 degrees and overlap so they hook into each other.
	step = link * 0.95
	n = max(2, int((p_top[2] - p_bottom[2]) / step) + 1)
	for i in range(n):
		z = p_top[2] - i * step
		o = kit.ring(link * 0.42, link * 0.12, (0, 0, 0), iron, rot=(0, 0, 0), seg=10)
		for v in o.data.vertices:
			x, y, zz = v.co.x, v.co.y, v.co.z
			v.co = (x * 0.75, zz, y * 1.45) if i % 2 else (zz, x * 0.75, y * 1.45)
		o.location = (p_top[0], p_top[1], z)


def coals(cx, cy, z, r, n=9, seed=4):
	"""A bed of dark charcoal lumps with glowing cracks."""
	rr = random.Random(seed)
	for k in range(n):
		a, d = rr.uniform(0, 6.28), rr.uniform(0, r)
		hot = k % 3 == 0
		kit.gem((cx + math.cos(a) * d, cy + math.sin(a) * d, z + 0.02), (0.05, 0.045, 0.03),
			kit.glow("ember", 1.2) if hot else kit.mat("charcoal", rr.uniform(-0.2, 0.3)), seed=k + seed)


def dome(cx, cy, r=0.62, h=0.95, kind="smelter"):
	"""A furnace: one solid stone dome, big blocks round its foot, and an arched mouth at the front (-Y)
	with real flames (smelter: a glowing crucible of molten ore; kiln: burning charcoal). Returns the top."""
	kit.cone(r, r * 0.42, h, (cx, cy, h / 2), kit.tex_mat("stone"), verts=16, bevel=0.03)
	n = 12
	for k in range(n):
		a = 2 * math.pi * k / n
		if abs(math.atan2(math.sin(a + math.pi / 2), math.cos(a + math.pi / 2))) < 0.5:
			continue
		kit.stone((2 * (r + 0.04) * math.sin(math.pi / n) * 1.05, 0.2, 0.24),
			(cx + math.cos(a) * (r - 0.02), cy + math.sin(a) * (r - 0.02), 0.12), rot_z=math.degrees(a) + 90)
	mouth_y = cy - r + 0.12
	kit.box((0.4, 0.26, 0.34), (cx, mouth_y, 0.2), kit.mat("charcoal", -0.4), bevel=0.02, wobble=0)
	coals(cx, mouth_y - 0.06, 0.04, 0.12, n=7)
	kit.fire_spot((cx, mouth_y - 0.06, 0.08), 0.45)  # the game's animated flames play here
	for ang in (-80, -45, 0, 45, 80):
		a = math.radians(ang)
		kit.stone((0.15, 0.2, 0.13), (cx + math.sin(a) * 0.27, mouth_y - 0.1, 0.22 + math.cos(a) * 0.2))
	kit.stone((0.6, 0.26, 0.07), (cx, mouth_y - 0.16, 0.035), dark=True)
	return h


def chimney(cx, cy, z, r=0.2, h=0.36, copper=True):
	kit.tcyl("stone", r, h, (cx, cy, z + h / 2), verts=12, variant="b")
	band = kit.tex_mat("copper") if copper else kit.tex_mat("iron")
	kit.ring(r + 0.01, 0.035, (cx, cy, z + h - 0.02), band)
	kit.ring(r + 0.005, 0.03, (cx, cy, z + 0.06), band)
	kit.cylinder(r - 0.05, 0.02, (cx, cy, z + h + 0.001), kit.mat("charcoal"), verts=12, bevel=0)


def fire_pit(cx, cy, r=0.42, stones=9, logs=True, flames=1.0):
	for k in range(stones):
		a = 2 * math.pi * k / stones
		kit.stone((0.2, 0.17, 0.15), (cx + math.cos(a) * r, cy + math.sin(a) * r, 0.075), rot_z=math.degrees(a))
	coals(cx, cy, 0.0, r - 0.15, n=11)
	if logs:
		# A little teepee of straight logs leaning into the middle.
		for k in range(5):
			a = 2 * math.pi * k / 5 + 0.3
			kit.tcyl("wood", 0.045, 0.42, (cx + math.cos(a) * 0.1, cy + math.sin(a) * 0.1, 0.16),
				rot=(math.sin(a) * 32, -math.cos(a) * 32, 0), verts=8, variant="dark" if k % 2 else "b")
	if flames:
		kit.fire_spot((cx, cy, 0.1), flames)  # the game's animated flames play here


def log_pile(cx, cy, n_bottom=3, length=0.6):
	"""Split logs stacked in a little pyramid (fuel for the kiln)."""
	for row in range(n_bottom):
		for k in range(n_bottom - row):
			x = cx + (k - (n_bottom - row - 1) / 2) * 0.13
			kit.tcyl("wood", 0.06, length, (x, cy, 0.06 + row * 0.11), rot=(90, 0, 0), verts=8,
				variant="dark" if (row + k) % 2 else "b")
