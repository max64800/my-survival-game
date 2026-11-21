# Decor for the dungeon MOSSPROP WORKINGS (Nov 21): a small, abandoned, timber-propped working mine. Root wood
# like the Delver's Shack (shack bark / plank / dark / log-end paintings) + iron and rope. No moss anywhere.
#   blender --background --factory-startup --python builds/decor_nov21_mp.py -- [id ...]   (none = all)
# Output: assets/models/decor/<id>.glb (origin bottom-centre, front faces -Y in Blender = +Z in Godot).
# Wall pieces have a flat back at +Y so they sit flush on a wall.
#
# Wall pieces
#   mp_wedge_rack       two plank shelves packed with hardwood wedges of every size, a mallet lying on top
#   mp_saw_wall         a board with a two-man crosscut saw resting on pegs, a bow saw, an axe, a whetstone ledge
#   mp_tag_board        the shift board: rows of iron hooks with wooden miners' tags; five hooks empty, one tag fallen
#   mp_lamp_shelf       a shelf of iron frog lamps (one tipped), an oil keg, three more lamps hanging from pegs below
#   mp_rope_rack        a heavy wall beam with big pegs: two rope coils, a pulley block and a hanging chain
#   mp_auger_rack       T-handled augers standing in a holder bar, a drawknife and a pry bar on pegs
#   mp_bucket_hooks     a beam of iron hooks with two bailing buckets and a long dipper; one hook empty
#   mp_lagging_burst    (story) a propped wall whose lagging boards snapped and bowed out, rock spilling to the floor
# Story scenes
#   mp_saw_bench_cut    a log on a sawbuck with the crosscut saw stuck half way, one handle gone, rounds and chips
#   mp_prop_cracked     a prop kinked and split under the roof's weight, lashed and clamped, a second prop braced on it
#   mp_collapsed_set    a timber set that gave way: snapped leg, the cap fallen on a slant, rubble, a dropped lamp
#   mp_rest_corner      the timber-men's break spot left in a hurry: bench, crate table, dice, mugs, stool knocked over
#   mp_bucket_line      the bailing line dropped: buckets upright, tipped and upside down, a yoke, a small puddle
#   mp_hewing_log       a log dogged down on bearers, half hewn flat, scoring notches, the broad axe stuck in it, chips
#   mp_foreman_desk     a slanted lectern desk: open ledger, ink pot and quill, burnt-down candle, a measuring rod
# Intact props
#   mp_prop_crib        a crib (chock) of square timbers in crossed pairs, wedged and dogged, roof support
#   mp_prop_and_cap     one standing pit prop on a sill with its cap board, wedges, iron dog and a lamp on a spike
#   mp_door_set         a three-piece timber set (two legs and a cap) with wedges and lagging boards over it
#   mp_shaft_windlass   a hand windlass over a small shaft collar: drum, cranks, rope down to a bucket
#   mp_hoist_tripod     three poles lashed at the top, a chain and hook with a rope sling round a prop on the ground
#   mp_sorting_table    an ore sorting table: a heap of rock, three trays of sorted ore, a spalling hammer, a tub below
#   mp_tool_shed        a small open lean-to shed with shovels, a pick and a bar leaning inside, a shelf, a lamp
#   mp_bailing_tub      a big staved bailing tub (empty) with a dipper leaning in it and two buckets stacked beside
#   mp_bell_frame       the collapse-warning bell: a braced timber frame, iron bell, clapper and a pull rope
#   mp_wedge_crate      an open crate of wedges standing in rows, a few on the floor, a maul leaning on it
#   mp_prop_trolley     a low four-wheel trolley loaded with props bound by rope, a pull rope
#   mp_lagging_stack    split lagging boards stacked on bearers with stickers between layers, a stone weight, a hatchet
#   mp_prop_rack        a lean-to rack with eight props stood up against its rail
#   mp_tool_barrel      a cut-down barrel holding shovels, a pick, a pry bar and a maul
#   mp_nail_keg         a nail keg tipped over, iron spikes and timber dogs spilled, its lid and a claw hammer
import math
import random
import sys
from pathlib import Path

import bpy
from mathutils import Euler, Matrix, Vector
from mathutils.bvhtree import BVHTree

sys.path.insert(0, str(Path(__file__).resolve().parent))
from night_stations import B, GAME, J, disc, kit, log, mesh, rivet, rng  # noqa: E402
from night_materials import C, lump, sphere, _cm  # noqa: E402
from decor_nov21_c import chain, slab_xz, tube  # noqa: E402


def BARK():
	return kit.tex_mat("shackbark", f"v{rng.randrange(4)}")


def PLK():
	return kit.tex_mat("shackplank", f"v{rng.randrange(8)}")


def DARK():
	return kit.tex_mat("shackdark", rng.choice("abc"))


def END():
	return kit.tex_mat("shacklogend", f"v{rng.randrange(4)}")


def ROCK():
	return kit.tex_mat("shackstone", rng.choice("abc"))


def IRON(v=None):
	return kit.tex_mat("iron", v or rng.choice(("a", "dark", "dark")))


ROPE = lambda: kit.tex_mat("rope", rng.choice("ab"))  # noqa: E731
PARCH = lambda: C((0.6, 0.5, 0.34), 0.95)  # noqa: E731
INK = lambda: C((0.12, 0.09, 0.07), 0.6)  # noqa: E731
WAX = lambda: C((0.72, 0.64, 0.46), 0.85)  # noqa: E731
BONE = lambda: C((0.7, 0.64, 0.5), 0.8)  # noqa: E731
HOLE = lambda: C((0.03, 0.03, 0.03), 0.95)  # noqa: E731


# ================= helpers =================
def place(build, at=(0, 0, 0), rot=(0, 0, 0), d=None, basis=None):
	"""Build parts around the origin, turn them (euler degrees, or so +Z points along d) and move them to `at`."""
	before = set(bpy.data.objects[:])
	build()
	bpy.context.view_layer.update()
	if basis is not None:  # (X, Y, Z): where the parts' own axes point
		R = Matrix([basis[0], basis[1], basis[2]]).transposed().to_4x4()
	elif d is not None:
		R = Vector((0, 0, 1)).rotation_difference(Vector(d).normalized()).to_matrix().to_4x4()
	else:
		R = Euler([math.radians(a) for a in rot]).to_matrix().to_4x4()
	M = Matrix.Translation(Vector(at)) @ R
	new = [o for o in bpy.data.objects if o not in before]
	for o in new:
		o.matrix_world = M @ o.matrix_world
	return new


def low_z(objs):
	bpy.context.view_layer.update()
	return min((o.matrix_world @ v.co).z for o in objs if o.type == "MESH" for v in o.data.vertices)


def drop(objs, z=0.0):
	"""Move a group so its lowest point rests at height z."""
	dz = z - low_z(objs)
	for o in objs:
		o.matrix_world = Matrix.Translation((0, 0, dz)) @ o.matrix_world
	return objs


def grain_uv(o, long_axis):
	"""Re-wrap a part's painting so its grain (which runs up the picture) follows the part's long axis (0/1/2)."""
	me, tile = o.data, o.active_material["tile"] if o.active_material and "tile" in o.active_material else 1.0
	uv = me.uv_layers.active.data
	du, dv = rng.random(), rng.random()
	for p in me.polygons:
		ax = max(range(3), key=lambda k: abs(p.normal[k]))
		a, b = [k for k in range(3) if k != ax]
		if a == long_axis:
			a, b = b, a
		for li in p.loop_indices:
			co = me.vertices[me.loops[li].vertex_index].co
			uv[li].uv = (co[a] / tile + du, co[b] / tile + dv)
	return o


def G(size, loc, m, bevel=0.012, rot=(0, 0, 0)):
	"""A wooden box whose painted grain runs along its longest side."""
	return grain_uv(B(size, loc, m, bevel=bevel, rot=rot), max(range(3), key=lambda k: size[k]))


def bvh(o):
	bpy.context.view_layer.update()
	M = o.matrix_world
	return BVHTree.FromPolygons([M @ v.co for v in o.data.vertices], [tuple(p.vertices) for p in o.data.polygons])


def rest(o, z):
	return drop([o], z)[0]


def post(p0, p1, r, m=None):
	"""A round pit prop / log with chopped ends. If its end cap would sink below the floor, it is lifted to rest on it."""
	before = set(bpy.data.objects[:])
	o = log(p0, p1, r, m or BARK(), seg=9, rings=3, bend=0.04, end_m=END())
	grain_uv(o, max(range(3), key=lambda k: abs(p1[k] - p0[k])))
	new = [ob for ob in bpy.data.objects if ob not in before]
	if low_z(new) < 0:
		drop(new, 0.0)
	return o


def hewn(size, loc, rot=(0, 0, 0), m=None):
	"""A squared (axe-hewn) timber."""
	return G((size[0] * (1 + J(0.02)), size[1] * (1 + J(0.03)), size[2]), loc, m or PLK(), bevel=0.014,
		rot=(rot[0] + J(1), rot[1] + J(1), rot[2] + J(1.5)))


def peg(loc, axis="y", r=0.015):
	"""A short domed wooden peg head, its middle at loc (press it ~5 mm into the part)."""
	rot = {"y": (90, 0, 0), "z": (0, 0, 0), "x": (0, 90, 0)}[axis]
	kit.cylinder(r, 0.022, loc, DARK(), rot=rot, verts=8, bevel=0.007)


def hpeg(x, z, ln=0.1, r=0.016, y0=0.0):
	"""A long wall peg sticking out of a board front (y0) toward -Y, rising a little."""
	log((x, y0 + 0.012, z), (x, y0 - ln, z + 0.012), r, PLK(), seg=7, rings=1, ends=False, bend=0)


def board(w, h, z0=0.0, d=0.045):
	"""A wall board: vertical planks with a flat back at y = d, two dark battens with pegs on the front."""
	n = max(2, round(w / 0.22))
	for i in range(n):
		G((w / n - 0.008, d, h + J(0.015)), (-w / 2 + w / n * (i + 0.5), d / 2, z0 + h / 2), PLK(), bevel=0.01)
	for z in (z0 + 0.06, z0 + h - 0.06):
		G((w + 0.02, 0.03, 0.07), (0, -0.012, z), DARK(), bevel=0.008)
		for i in range(n):
			peg((-w / 2 + w / n * (i + 0.5), -0.031, z))


def shelf(w, z, dep=0.2):
	"""A plank shelf on two brackets against a board front (y = 0). Returns the top height."""
	G((w, dep, 0.035), (0, -dep / 2 + 0.004, z), PLK(), bevel=0.01)
	for x in (-w / 2 + 0.07, w / 2 - 0.07):
		G((0.04, dep * 0.7, 0.1), (x, -dep * 0.35 + 0.003, z - 0.065), DARK(), bevel=0.008)
		peg((x, -dep * 0.7 - 0.004, z - 0.075))
	G((w - 0.04, 0.02, 0.035), (0, -dep + 0.014, z + 0.024), DARK(), bevel=0.005)
	return z + 0.0175


def wedge(o, L, W, H, rot=(0, 0, 0), m=None):
	"""A timber wedge: thick end (H) at local x = 0, thin end at x = L, flat bottom at local z = 0."""
	hw, t = W / 2, 0.01
	v = [(0, -hw, 0), (L, -hw, 0), (L, hw, 0), (0, hw, 0), (0, -hw, H), (L, -hw, t), (L, hw, t), (0, hw, H)]
	f = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
	R = Euler([math.radians(a) for a in rot]).to_matrix()
	return mesh([tuple(Vector(o) + R @ Vector(p)) for p in v], f, m or PLK())


def lathe(prof, c, m, seg=16):
	"""A turned shape: profile (r, z) points revolved around a vertical axis at c."""
	x0, y0, z0 = c
	n = len(prof)
	v = [(x0 + math.cos(2 * math.pi * k / seg) * r, y0 + math.sin(2 * math.pi * k / seg) * r, z0 + z) for r, z in prof for k in range(seg)]
	f = [(i * seg + k, i * seg + (k + 1) % seg, (i + 1) * seg + (k + 1) % seg, (i + 1) * seg + k) for i in range(n - 1) for k in range(seg)]
	f += [tuple(reversed(range(seg))), tuple(range((n - 1) * seg, n * seg))]
	return mesh(v, f, m, smooth=True)


def splinters(p, ax, n=4, r=0.05):
	"""Pale splinters sticking out of a snapped end at p, pointing along ax."""
	ax = Vector(ax).normalized()
	q = Vector((0, 0, 1)).rotation_difference(ax)
	u = ax.orthogonal().normalized()
	v = ax.cross(u)
	for k in range(n):
		a = 2 * math.pi * k / n + J(0.4)
		c = Vector(p) + (u * math.cos(a) + v * math.sin(a)) * r * 0.5 + ax * 0.02
		o = kit.cone(0.016, 0.0, 0.07 + J(0.025), tuple(c), END(), verts=4, bevel=0)
		o.rotation_euler = q.to_euler()


def staves(c, r, h, n=12, bottom=True, thick=0.024, bands=(0.05, -0.05), m_band=None):
	"""An open staved vessel (bucket, tub, keg) standing at c; bands at heights (negative = from the top)."""
	x, y, z = c
	if bottom:
		kit.cylinder(r - 0.01, 0.025, (x, y, z + 0.035), DARK(), verts=n + 4, bevel=0.004)
	sw = 2 * math.pi * r / n * 1.05
	for k in range(n):
		a = 2 * math.pi * k / n
		hh = h * (1 + J(0.025))
		G((sw, thick, hh), (x + math.cos(a) * (r - thick / 2), y + math.sin(a) * (r - thick / 2), z + hh / 2), PLK(), bevel=0.005,
			rot=(0, 0, math.degrees(a) + 90))
	for b in bands:
		zb = z + (b if b > 0 else h + b)
		kit.ring(r + 0.002, 0.008, (x, y, zb), m_band or IRON("dark"), seg=2 * n)


def bucket(c, r=0.12, h=0.22, handle=True):
	x, y, z = c
	staves(c, r, h, n=11)
	if handle:
		ze = z + h - 0.03
		for s_ in (-1, 1):
			B((0.025, 0.035, 0.06), (x + s_ * (r + 0.004), y, ze), IRON("dark"), bevel=0.004)
		pts = [(x + math.cos(t) * (r + 0.012), y, ze + math.sin(t) * r * 0.9) for t in [math.pi * i / 10 for i in range(11)]]
		tube(pts, [0.007] * 11, IRON("dark"), seg=6)
	return z + h - 0.03 + r * 0.9 + 0.007  # top of the handle


def mug(c):
	x, y, z = c
	kit.cylinder(0.045, 0.11, (x, y, z + 0.055), PLK(), verts=10, bevel=0.006)
	kit.ring(0.04, 0.007, (x, y, z + 0.11), DARK(), seg=12)
	kit.ring(0.047, 0.006, (x, y, z + 0.03), IRON("dark"), seg=12)
	kit.ring(0.03, 0.009, (x + 0.055, y, z + 0.06), PLK(), rot=(90, 0, 0), seg=10)


def lamp(c, hook=True):
	"""An iron frog lamp standing at c (pan, rim, spout and wick, a hook rising at the back). Returns the hook top."""
	x, y, z = c
	kit.cylinder(0.045, 0.035, (x, y, z + 0.0175), IRON("dark"), verts=12, bevel=0.006)
	kit.ring(0.044, 0.006, (x, y, z + 0.034), IRON("a"), seg=12)
	kit.cone(0.02, 0.01, 0.06, (x, y - 0.06, z + 0.03), IRON("dark"), rot=(75, 0, 0), verts=8, bevel=0.003)
	kit.cylinder(0.006, 0.02, (x, y - 0.088, z + 0.042), C((0.08, 0.07, 0.06), 0.9), verts=6, bevel=0.002)
	if hook:
		pts = [(x, y + 0.04, z + 0.025), (x, y + 0.05, z + 0.1), (x, y + 0.045, z + 0.16), (x, y + 0.02, z + 0.185),
			(x, y - 0.005, z + 0.175), (x, y - 0.012, z + 0.155)]
		tube(pts, [0.006] * 6, IRON("dark"), seg=6, up=(1, 0, 0))
	return (x, y + 0.02, z + 0.191)


def hung_lamp(top):
	"""A lamp hanging so its hook top sits at `top` (a peg's underside)."""
	lamp((top[0], top[1] - 0.02, top[2] - 0.191))


def coil(top, R=0.14, n=5):
	"""A coil of rope hanging from a peg: its top at `top`, coils stacked toward -Y."""
	x, y, z = top
	for k in range(n):
		kit.ring(R * (1 + J(0.03)), 0.013, (x + J(0.006), y - k * 0.017, z - R), ROPE(), rot=(90, 0, 0), seg=22)
	ym = y - (n - 1) * 0.0085
	for s_ in (-1, 1):
		kit.ring(0.05, 0.01, (x + s_ * R, ym, z - R), ROPE(), seg=10)
	log((x + R * 0.7, ym, z - R - R * 0.7), (x + R * 0.8, ym - 0.02, z - 2 * R - 0.12), 0.012, ROPE(), seg=6, rings=2, ends=False, bend=0.2)


def rubble(cx, cy, w, d, n, top, seed, z0=0.0):
	"""A settled pile of angular rocks of many sizes: big ones first, each new rock rests on the rocks under it
	(or on the floor), so every rock touches. Returns [(x, y, bottom z, top z, radius)] of the rocks."""
	r = random.Random(seed)
	rocks, trees = [], []
	for k in range(n * 3):
		if len(rocks) >= n:
			break
		u, v = r.uniform(-1, 1), r.uniform(-1, 1)
		if u * u + v * v > 1:
			continue
		f = 1 - (u * u + v * v)
		s = (0.14 - 0.08 * len(rocks) / n) * r.uniform(0.6, 1.0)
		size = (s * r.uniform(0.9, 1.3), s * r.uniform(0.8, 1.1), s * r.uniform(0.55, 0.8))
		x, y = cx + u * w / 2, cy + v * d / 2
		base = z0
		for (a, b, zb, zt, rad) in rocks:
			q = math.hypot(x - a, y - b) / (rad + size[0])
			if q < 1:
				base = max(base, zt - (zt - zb) * q * q - size[2] * 0.5)
		if base - z0 > top * (0.35 + 0.65 * f):
			continue
		o = lump((x, y, 0.5), size, ROCK(), seed=seed * 100 + k, rough=0.008)
		rest(o, base + 0.03)
		near = [t for t in trees if (Vector((x, y)) - t[0]).length < t[1] + size[0] * 1.3]
		while low_z([o]) > z0 + 0.002:  # let it drop until it touches a rock under it (or the floor)
			bt = bvh(o)
			if any(bt.overlap(t[2]) for t in near):
				break
			o.matrix_world = Matrix.Translation((0, 0, -0.004)) @ o.matrix_world
		if low_z([o]) < z0:
			rest(o, z0)
		trees.append((Vector((x, y)), size[0] * 1.2, bvh(o)))
		lo = low_z([o])
		rocks.append((x, y, lo, lo + 1.8 * size[2], size[0]))
	return rocks


def chips(cx, cy, w, d, n, seed):
	"""Flat wood chips lying on the floor, never on top of each other (no shimmer)."""
	r = random.Random(seed)
	done = []
	for _ in range(n * 6):
		if len(done) >= n:
			break
		x, y = cx + r.uniform(-w / 2, w / 2), cy + r.uniform(-d / 2, d / 2)
		if all(math.hypot(x - a, y - b) > 0.07 for a, b in done):
			done.append((x, y))
			o = G((r.uniform(0.04, 0.08), r.uniform(0.025, 0.04), 0.008), (x, y, 0.004), PLK() if k_even(len(done)) else END(),
				bevel=0.002, rot=(r.uniform(-3, 3), r.uniform(-3, 3), r.uniform(0, 180)))
			rest(o, 0.0)


def k_even(k):
	return k % 2 == 0


# ---------------- tools, built upright along +Z from the origin ----------------
def t_axe(L=0.75, broad=False):
	log((0, 0, 0), (0, 0, L), 0.019, PLK(), seg=7, rings=2, ends=False, bend=0.02)
	b = 0.21 if broad else 0.16
	low = 0.17 if broad else 0.13
	pts = [(0.045, L + 0.015), (0.045, L - 0.075), (-0.025, L - 0.07), (-b + 0.03, L - low + 0.02), (-b, L - low),
		(-b - 0.012, L - 0.04), (-b + 0.01, L + 0.03), (-0.03, L + 0.012)]
	slab_xz(pts, -0.014, 0.014, IRON("dark"))
	edge = [(-b - 0.001, L - low + 0.004), (-b - 0.022, L - 0.04), (-b - 0.002, L + 0.028), (-b + 0.012, L + 0.02),
		(-b - 0.004, L - 0.04), (-b + 0.014, L - low + 0.02)]
	slab_xz(edge, -0.007, 0.007, IRON("a"))
	G((0.025, 0.032, 0.012), (0.005, 0, L + 0.018), PLK(), bevel=0.003)


def t_maul(L=0.75, r=0.06):
	log((0, 0, 0), (0, 0, L - 0.03), 0.02, PLK(), seg=7, rings=2, ends=False, bend=0.02)
	log((-0.11, 0, L), (0.11, 0, L), r, BARK(), seg=10, rings=1, bend=0, end_m=END())
	for s_ in (-1, 1):
		kit.ring(r + 0.002, 0.009, (s_ * 0.085, 0, L), IRON("dark"), rot=(0, 90, 0), seg=14)
	peg((0, 0, L + r - 0.004), "z", r=0.012)


def t_pick(L=0.85):
	log((0, 0, 0), (0, 0, L + 0.01), 0.019, PLK(), seg=7, rings=2, ends=False, bend=0.02)
	pts = [(-0.3, 0, L - 0.09), (-0.16, 0, L - 0.02), (0, 0, L + 0.01), (0.16, 0, L - 0.02), (0.3, 0, L - 0.09)]
	tube(pts, [0.005, 0.02, 0.03, 0.02, 0.005], IRON("dark"), seg=7)
	B((0.07, 0.05, 0.06), (0, 0, L - 0.005), IRON("dark"), bevel=0.008)


def t_shovel(L=1.0):
	log((0, 0, 0.27), (0, 0, L), 0.018, PLK(), seg=7, rings=2, ends=False, bend=0.02)
	G((0.16, 0.035, 0.03), (0, 0, L - 0.01), PLK(), bevel=0.006)
	G((0.22, 0.024, 0.26), (0, 0, 0.16), PLK(), bevel=0.006)
	B((0.236, 0.032, 0.05), (0, 0, 0.035), IRON("dark"), bevel=0.006)
	kit.cone(0.03, 0.02, 0.08, (0, 0, 0.3), IRON("dark"), verts=8, bevel=0.003)
	for x in (-0.05, 0.05):
		B((0.02, 0.03, 0.2), (x, 0, 0.17), IRON("dark"), bevel=0.003)
		rivet((x, -0.016, 0.22), IRON("a"), r=0.008)


def t_bar(L=1.1):
	log((0, 0, 0.04), (0, 0, L), 0.017, IRON("dark"), seg=6, rings=2, ends=False, bend=0.01)
	B((0.034, 0.012, 0.07), (0, 0, 0.04), IRON("dark"), bevel=0.004)
	tube([(0, 0, L - 0.02), (0, 0, L + 0.03), (0.03, 0, L + 0.06), (0.07, 0, L + 0.055)], [0.017, 0.016, 0.013, 0.008], IRON("dark"), seg=6)


def t_hammer(L=0.32):
	log((0, 0, 0), (0, 0, L), 0.014, PLK(), seg=6, rings=1, ends=False, bend=0)
	B((0.11, 0.03, 0.032), (0.0, 0, L), IRON("dark"), bevel=0.006)
	kit.cylinder(0.02, 0.03, (0.06, 0, L), IRON("a"), rot=(0, 90, 0), verts=8, bevel=0.003)
	kit.cone(0.014, 0.004, 0.06, (-0.08, 0, L - 0.01), IRON("dark"), rot=(0, -105, 0), verts=6, bevel=0.002)


def t_crosscut(L=1.2, handles=(True, True)):
	"""A two-man crosscut saw in the XZ plane: straight back at z = 0, toothed belly, handles at the ends."""
	n = 40
	pts = [(-L / 2, 0.0), (L / 2, 0.0), (L / 2, -0.05)]
	for i in range(n + 1):
		x = L / 2 - L * i / n
		zb = -0.05 - 0.07 * (1 - (2 * x / L) ** 2)
		pts.append((x, zb - (0.016 if i % 2 else 0.0)))
	pts.append((-L / 2, -0.05))
	slab_xz(pts, -0.0015, 0.0015, IRON("a"))
	for s_, on in ((-1, handles[0]), (1, handles[1])):
		x = s_ * (L / 2 - 0.004)
		if on:
			kit.cylinder(0.022, 0.18, (x, 0, -0.02), PLK(), verts=8, bevel=0.006)
		kit.ring(0.022, 0.006, (x, 0, -0.02 + (0.05 if on else 0.0)), IRON("dark"), seg=10) if on else \
			B((0.03, 0.012, 0.06), (x, 0, -0.025), IRON("dark"), bevel=0.003)


def crate(w, d, h, loc, open_top=True):
	"""An open slatted crate (bottom, two slats per side, corner posts, iron corner straps)."""
	x, y, z = loc
	G((w - 0.04, d - 0.04, 0.03), (x, y, z + 0.02), DARK(), bevel=0.006)
	for s_ in (-1, 1):
		for k in range(2):
			zz = z + h * (0.27 + 0.48 * k)
			G((w, 0.025, h * 0.44), (x, y + s_ * (d / 2 - 0.0125), zz), PLK(), bevel=0.008)
			G((0.025, d - 0.05, h * 0.44), (x + s_ * (w / 2 - 0.0125), y, zz), PLK(), bevel=0.008)
	for cx in (-1, 1):
		for cy in (-1, 1):
			G((0.05, 0.05, h), (x + cx * (w / 2 - 0.015), y + cy * (d / 2 - 0.015), z + h / 2), DARK(), bevel=0.008)
			B((0.056, 0.056, 0.03), (x + cx * (w / 2 - 0.015), y + cy * (d / 2 - 0.015), z + h - 0.03), IRON("dark"), bevel=0.003)


# ================= wall pieces =================
def mp_wedge_rack():
	W = 1.1
	board(W, 0.76)
	for row, z in enumerate((0.1, 0.44)):
		top = shelf(W - 0.06, z, dep=0.17)
		x, k = -W / 2 + 0.12, 0
		xmax = 0.16 if row else W / 2 - 0.12
		hmax = 0.21 if row == 0 else 0.26
		while x < xmax:
			H = 0.035 + 0.012 * ((k + row) % 3)
			L = hmax - 0.04 * ((k * 2 + row) % 3)
			wedge((x + H, -0.075, top - 0.003), L, 0.085 + 0.01 * (k % 2), H, rot=(0, -90 + J(3), 0))
			x += H + 0.014
			k += 1
	# a mallet lying on the top shelf beside the wedges
	top = 0.44 + 0.0175
	log((0.3, -0.13, top + 0.048), (0.3, -0.02, top + 0.048), 0.05, BARK(), seg=10, rings=1, bend=0, end_m=END())
	for yy in (-0.115, -0.035):
		kit.ring(0.052, 0.007, (0.3, yy, top + 0.048), IRON("dark"), rot=(90, 0, 0), seg=12)
	log((0.33, -0.075, top + 0.016), (0.5, -0.09, top + 0.016), 0.016, PLK(), seg=7, rings=1, ends=False, bend=0)
	for x in (-0.4, 0.4):
		rivet((x, -0.004, 0.7), IRON("dark"))


def mp_saw_wall():
	W = 1.4
	board(W, 0.92)
	# crosscut saw resting its teeth on two pegs near the top
	for x in (-0.45, 0.45):
		hpeg(x, 0.66, ln=0.08)
	zb = -0.05 - 0.07 * (1 - (0.9) ** 2) - 0.016
	place(t_crosscut, at=(0, -0.045, 0.66 + 0.028 - zb))

	# a bow saw hanging by its stretcher on a peg (lower left)
	def bowsaw():
		for s_ in (-1, 1):
			G((0.03, 0.024, 0.46), (s_ * 0.2, 0, 0.23), PLK(), bevel=0.006, rot=(0, s_ * 4, 0))
		G((0.4, 0.02, 0.032), (0, 0, 0.22), PLK(), bevel=0.005)
		n = 24
		pts = [(-0.22, 0.05), (0.22, 0.05), (0.22, 0.03)]
		for i in range(n + 1):
			pts.append((0.22 - 0.44 * i / n, 0.03 - (0.012 if i % 2 else 0.0)))
		pts.append((-0.22, 0.03))
		slab_xz(pts, -0.0015, 0.0015, IRON("a"))
		for s_ in (-1, 1):
			log((s_ * 0.215, 0, 0.43), (0, 0, 0.42), 0.007, ROPE(), seg=5, rings=2, ends=False, bend=0)
			log((s_ * 0.2, -0.008, 0.42), (s_ * 0.002, -0.008, 0.415), 0.007, ROPE(), seg=5, rings=1, ends=False, bend=0)
		G((0.02, 0.016, 0.2), (0.0, -0.012, 0.335), PLK(), bevel=0.004)
	hpeg(-0.38, 0.33, ln=0.08)
	place(bowsaw, at=(-0.38, -0.045, 0.33 + 0.028 - 0.204))

	# a felling axe hanging by its head on two pegs (right)
	for dx in (-0.05, 0.045):
		hpeg(0.38 + dx, 0.5, ln=0.08)
	place(lambda: t_axe(0.62), at=(0.38, -0.045, 0.5 + 0.028 - 0.62 + 0.075))
	# a whetstone and a saw-set lying on a low ledge
	G((0.5, 0.12, 0.035), (0.0, -0.056, 0.14), PLK(), bevel=0.008)
	for x in (-0.2, 0.2):
		G((0.035, 0.09, 0.08), (x, -0.045, 0.085), DARK(), bevel=0.006)
	B((0.2, 0.05, 0.035), (-0.08, -0.06, 0.174), ROCK(), bevel=0.01)
	B((0.1, 0.035, 0.02), (0.12, -0.06, 0.167), IRON("dark"), bevel=0.004)
	log((0.17, -0.06, 0.167), (0.27, -0.06, 0.167), 0.01, PLK(), seg=6, rings=1, ends=False, bend=0)


def mp_tag_board():
	W = 0.92
	board(W, 0.86)
	# header plank with iron corner straps
	G((W + 0.04, 0.035, 0.12), (0, -0.035, 0.77), DARK(), bevel=0.01)
	for s_ in (-1, 1):
		B((0.08, 0.012, 0.13), (s_ * (W / 2 - 0.02), -0.056, 0.77), IRON("dark"), bevel=0.003)
		rivet((s_ * (W / 2 - 0.02), -0.062, 0.8), IRON("a"), r=0.01)
		rivet((s_ * (W / 2 - 0.02), -0.062, 0.74), IRON("a"), r=0.01)
	empty = {(0, 4), (1, 1), (1, 5), (2, 2), (2, 3)}
	for r_, z in enumerate((0.6, 0.43, 0.26)):
		for c_ in range(6):
			x = -0.33 + c_ * 0.132
			tube([(x, 0.005, z), (x, -0.04, z), (x, -0.052, z + 0.012), (x, -0.052, z + 0.03)], [0.0055] * 4, IRON("dark"), seg=6, up=(1, 0, 0))
			kit.cylinder(0.014, 0.008, (x, -0.0, z), IRON("dark"), rot=(90, 0, 0), verts=8, bevel=0.002)
			if (r_, c_) in empty:
				continue
			kit.ring(0.015, 0.004, (x, -0.04, z - 0.0185), IRON("a"), rot=(0, 90, 0), seg=10)
			G((0.07, 0.014, 0.09), (x + J(0.003), -0.04, z - 0.077), PLK(), bevel=0.006, rot=(0, J(4), 0))
	shelf_top = shelf(W - 0.06, 0.13, dep=0.12)
	# the fallen tag on the ledge, a tally stick and a candle stub in an iron dish
	G((0.09, 0.07, 0.014), (-0.2, -0.06, shelf_top + 0.006), PLK(), bevel=0.005, rot=(0, 0, 18))
	log((-0.05, -0.05, shelf_top + 0.014), (0.18, -0.07, shelf_top + 0.014), 0.014, PLK(), seg=6, rings=1, ends=False, bend=0)
	kit.cylinder(0.04, 0.012, (0.3, -0.06, shelf_top + 0.005), IRON("dark"), verts=10, bevel=0.003)
	kit.cylinder(0.018, 0.035, (0.3, -0.06, shelf_top + 0.026), WAX(), verts=8, bevel=0.004)
	kit.gem((0.316, -0.065, shelf_top + 0.02), (0.008, 0.008, 0.016), WAX(), seed=3)


def mp_lamp_shelf():
	W = 1.0
	board(W, 0.74)
	top = shelf(W - 0.04, 0.42, dep=0.19)
	for i, x in enumerate((-0.36, -0.2, -0.04)):
		lamp((x, -0.1, top - 0.002))
	place(lambda: lamp((0, 0, 0)), at=(0.1, -0.11, top + 0.044), rot=(0, 72, 20))
	# a small oil keg with a lid and a wooden tap
	staves((0.32, -0.095, top - 0.002), 0.07, 0.17, n=9, bands=(0.035, -0.035))
	kit.cylinder(0.064, 0.02, (0.32, -0.095, top - 0.002 + 0.172), DARK(), verts=12, bevel=0.004)
	kit.cylinder(0.012, 0.03, (0.32, -0.095, top + 0.19), PLK(), verts=6, bevel=0.003)
	kit.cylinder(0.012, 0.05, (0.32, -0.17, top + 0.04), PLK(), rot=(90, 0, 0), verts=6, bevel=0.003)
	# three lamps hanging from pegs under the shelf
	for x in (-0.3, 0.0, 0.3):
		hpeg(x, 0.23, ln=0.09)
		hung_lamp((x, -0.06, 0.23 - 0.014))


def mp_rope_rack():
	for x in (-0.55, 0.55):
		G((0.14, 0.045, 0.9), (x, 0.0225, 0.45), PLK(), bevel=0.01)
		for z in (0.15, 0.4):
			peg((x, -0.004, z))
	hewn((1.3, 0.12, 0.14), (0, -0.058, 0.78))
	for x in (-0.5, -0.1, 0.25, 0.52):
		log((x, -0.11, 0.76), (x, -0.27, 0.78), 0.022, DARK(), seg=7, rings=1, ends=False, bend=0)
	for x in (-0.6, 0.6):
		peg((x, -0.12, 0.78))
	coil((-0.5, -0.14, 0.738), R=0.17, n=5)
	coil((-0.1, -0.14, 0.738), R=0.13, n=4)
	# pulley block: two cheeks, an iron sheave, straps and a hook over the peg
	z = 0.55
	for s_ in (-1, 1):
		G((0.11, 0.025, 0.2), (0.25, -0.17 + s_ * 0.03, z), DARK(), bevel=0.01)
	kit.cylinder(0.05, 0.035, (0.25, -0.17, z - 0.02), IRON("dark"), rot=(90, 0, 0), verts=14, bevel=0.004)
	kit.cylinder(0.012, 0.09, (0.25, -0.17, z - 0.02), IRON("a"), rot=(90, 0, 0), verts=8, bevel=0.002)
	for s_ in (-1, 1):
		B((0.115, 0.012, 0.03), (0.25, -0.17 + s_ * 0.048, z + 0.07), IRON("dark"), bevel=0.003)
	tube([(0.25, -0.17, z + 0.1), (0.25, -0.17, z + 0.17), (0.25, -0.2, z + 0.205), (0.25, -0.215, z + 0.19)], [0.009] * 4, IRON("dark"), seg=6, up=(1, 0, 0))
	B((0.05, 0.08, 0.035), (0.25, -0.17, z + 0.1), IRON("dark"), bevel=0.004)
	log((0.27, -0.17, z - 0.07), (0.3, -0.17, z - 0.32), 0.012, ROPE(), seg=6, rings=2, ends=False, bend=0.1)
	# a loop of chain hanging from the last peg, with a hook
	chain((0.52, -0.2, 0.75), (0.47, -0.2, 0.42))
	chain((0.52, -0.2, 0.75), (0.57, -0.2, 0.47), first=False)
	tube([(0.57, -0.2, 0.46), (0.57, -0.2, 0.39), (0.6, -0.2, 0.36), (0.63, -0.2, 0.39)], [0.01, 0.01, 0.009, 0.006], IRON("dark"), seg=6)


def mp_auger_rack():
	W = 0.94
	board(W, 0.92)
	top = shelf(W - 0.06, 0.13, dep=0.13)
	G((0.6, 0.03, 0.05), (-0.17, -0.065, 0.62), PLK(), bevel=0.008)
	for x in (-0.46, -0.335, -0.205, -0.075, 0.12):
		G((0.045, 0.06, 0.05), (x + 0.0, -0.025, 0.62), DARK(), bevel=0.006)
	for i, x in enumerate((-0.4, -0.27, -0.14, -0.01)):
		ln = 0.58 - 0.04 * (i % 2)
		kit.cone(0.012, 0.002, 0.03, (x, -0.04, top + 0.014), IRON("dark"), rot=(180, 0, 0), verts=6, bevel=0)
		log((x, -0.04, top + 0.028), (x, -0.04, top + ln), 0.01, IRON("dark"), seg=6, rings=1, ends=False, bend=0)
		for k in range(7):  # the twisted bit: little blades turned a bit more each step
			B((0.034 - 0.0015 * k, 0.006, 0.014), (x, -0.04, top + 0.035 + k * 0.018), IRON("a"), bevel=0.002, rot=(0, 0, k * 26))
		log((x - 0.11, -0.04, top + ln + 0.015), (x + 0.11, -0.04, top + ln + 0.015), 0.019, PLK(), seg=7, rings=1, ends=False, bend=0)
		kit.ring(0.02, 0.006, (x, -0.04, top + ln - 0.012), IRON("dark"), seg=10)
		B((0.025, 0.025, 0.03), (x, -0.04, top + ln), IRON("dark"), bevel=0.003)
	# drawknife on two pegs (top right) and a pry bar on two pegs (lower right)
	for x in (0.21, 0.39):
		hpeg(x, 0.72, ln=0.08)
	B((0.3, 0.006, 0.045), (0.3, -0.05, 0.72 + 0.016 + 0.0225), IRON("a"), bevel=0.002)
	for s_ in (-1, 1):
		log((0.3 + s_ * 0.15, -0.05, 0.76), (0.3 + s_ * 0.2, -0.05, 0.64), 0.016, PLK(), seg=7, rings=1, ends=False, bend=0)
	for x in (0.2, 0.4):
		hpeg(x, 0.4, ln=0.08)
	place(lambda: t_bar(0.4), at=(0.12, -0.05, 0.4 + 0.033), rot=(0, 90, 0))


def mp_bucket_hooks():
	for x in (-0.6, 0.6):
		G((0.14, 0.045, 1.0), (x, 0.0225, 0.5), PLK(), bevel=0.01)
		peg((x, -0.004, 0.2))
	hewn((1.4, 0.1, 0.12), (0, -0.048, 0.9))
	for x in (-0.6, 0.6):
		peg((x, -0.1, 0.9))
	xs = (-0.42, -0.14, 0.14, 0.42)
	for i, x in enumerate(xs):
		tube([(x, -0.07, 0.85), (x, -0.13, 0.84), (x, -0.16, 0.78), (x, -0.162, 0.745), (x, -0.175, 0.727), (x, -0.195, 0.727),
			(x, -0.208, 0.745), (x, -0.21, 0.772)],
			[0.009, 0.009, 0.008, 0.008, 0.007, 0.007, 0.007, 0.006], IRON("dark"), seg=7, up=(1, 0, 0))
		if i == 1:  # an empty hook between the two buckets, so they don't touch
			continue
		if i == 3:  # the long dipper hangs by the ring at its handle end
			# the ring hangs round the hook's bottom bend: its top wire rests on the hook wire
			kit.ring(0.02, 0.006, (x, -0.185, 0.727 + 0.007 + 0.006 - 0.001 - 0.02), IRON("a"), rot=(90, 0, 0), seg=10)
			log((x, -0.185, 0.7), (x, -0.185, 0.21), 0.014, PLK(), seg=6, rings=2, ends=False, bend=0)
			lathe([(0.012, 0.0), (0.055, 0.006), (0.065, 0.05), (0.06, 0.09), (0.05, 0.088), (0.052, 0.012), (0.012, 0.008)][::-1],
				(x - 0.055, -0.185, 0.17), PLK(), seg=12)
			continue
		h, r = 0.22, 0.12
		# the bail's top wire rests on the hook's bottom bend (hook top surface at 0.727 + 0.007)
		zb = 0.727 + 0.007 + 0.006 - (h - 0.03 + r * 0.9)
		bucket((x, -0.185, zb), r, h)


def mp_lagging_burst():
	W, H = 1.6, 1.86
	B((W - 0.06, 0.08, H), (0, 0.095, H / 2), ROCK(), bevel=0.02)
	for x in (-0.7, 0.7):
		post((x, -0.1, 0.0), (x + J(0.01), -0.1, H - 0.1), 0.1)
	hewn((W, 0.22, 0.18), (0, -0.1, H - 0.02))
	for x in (-0.7, 0.7):
		wedge((x - 0.06, -0.21, H - 0.115), 0.12, 0.06, 0.03, rot=(0, 0, 90))
	rows = 10
	rh = (H - 0.12) / rows
	burst = (4, 5)
	for k in range(rows):
		z = rh * (k + 0.5)
		if k in burst:
			continue
		G((W - 0.08, 0.045, rh - 0.012), (J(0.01), 0.026, z), PLK(), bevel=0.008)
	# the two burst boards: each half snapped in the middle and swung out from its prop
	for k in burst:
		z = rh * (k + 0.5)
		for s_ in (-1, 1):
			before = set(bpy.data.objects[:])
			o = G((0.72, 0.045, rh - 0.012), (s_ * 0.38, 0.026, z), PLK(), bevel=0.008)
			splinters((s_ * 0.02, 0.026, z), (-s_, 0, 0), n=3, r=0.04)
			new = [ob for ob in bpy.data.objects if ob not in before]
			ang = (22 if k == 4 else 14) * (1 if s_ > 0 else -1)
			piv = Matrix.Translation((s_ * 0.66, 0.04, z)) @ Matrix.Rotation(math.radians(ang), 4, "Z") @ Matrix.Translation((-s_ * 0.66, -0.04, -z))
			for ob in new:
				ob.matrix_world = piv @ ob.matrix_world
	# rock spilling out of the hole and down to a heap on the floor
	r = random.Random(7)
	for k in range(14):
		t = k / 13
		x, y, z = 0.12 * math.sin(k * 1.3) + J(0.02), 0.03 - 0.3 * t, 1.0 - 0.75 * t
		s = r.uniform(0.08, 0.11)
		lump((x, y, z), (s * 1.2, s, s * 0.8), ROCK(), seed=50 + k, rough=0.008)
	rubble(0.0, -0.32, 0.9, 0.5, 34, 0.38, seed=11)


# ================= story scenes =================
def sawbuck(x):
	for s_ in (-1, 1):
		post((x + s_ * 0.035, -0.32 * s_, 0.0), (x + s_ * 0.035, 0.32 * s_, 0.82), 0.05)
	kit.ring(0.07, 0.019, (x, 0, 0.41), ROPE(), rot=(0, 90, 0), seg=12)
	return x


def mp_saw_bench_cut():
	for x in (-0.5, 0.45):
		sawbuck(x)
	post((-0.5, 0, 0.41), (0.45, 0, 0.41), 0.04)
	zc = 0.41 + 0.15 * math.sqrt(2) - 0.01
	post((-0.85, 0, zc), (0.8, 0, zc), 0.15)
	# the saw stuck in its cut, one handle gone
	zb = -0.05 - 0.07 - 0.016
	place(lambda: t_crosscut(1.3, handles=(True, False)), at=(0.15, 0, zc + 0.15 - 0.07 - zb), rot=(0, 0, 90))
	# the lost handle on the floor
	log((-0.15, -0.62, 0.022), (0.02, -0.66, 0.022), 0.022, PLK(), seg=8, rings=1, ends=False, bend=0)
	kit.ring(0.022, 0.006, (-0.11, -0.63, 0.022), IRON("dark"), rot=(0, 90, -10), seg=10)
	# sawn-off rounds: one flat, one standing on its edge
	post((1.0, -0.35, 0.0), (1.0, -0.35, 0.13), 0.15)
	post((1.05, 0.1, 0.15), (1.05, 0.25, 0.15), 0.15)
	chips(0.15, -0.05, 0.6, 0.7, 14, seed=4)


def mp_prop_cracked():
	hewn((0.5, 0.36, 0.08), (0, 0, 0.04))
	mid = (0.05, 0.0, 0.98)
	post((0, 0, 0.07), mid, 0.105)
	post(mid, (0, 0, 1.9), 0.105)
	splinters((0.1, 0.0, 0.96), (1, 0, 0.2), n=4, r=0.06)
	splinters((0.08, -0.05, 1.0), (0.4, -1, 0.1), n=3, r=0.05)
	# the crack: a dark split up the front of the prop
	B((0.012, 0.03, 0.42), (0.04, -0.095, 1.05), C((0.08, 0.06, 0.05), 0.95), bevel=0.003, rot=(0, -4, 0))
	for z in (0.78, 1.18):
		kit.ring(0.112, 0.012, (0.03, 0, z), IRON("dark"), seg=16)
	kit.rope_wrap((0.05, 0.0), 0.11, 0.9, 1.06, 4, thick=0.014, material=ROPE())
	hewn((0.7, 0.3, 0.1), (0, 0, 1.94))
	for s_ in (-1, 1):
		wedge((0.0, s_ * 0.16, 1.875), 0.16, 0.07, 0.04, rot=(0, 0, -90 * s_))
	# a second prop braced against the kink, a wedge at its foot
	post((0.62, -0.12, 0.0), (0.13, -0.03, 1.02), 0.075)
	wedge((0.74, -0.12, 0.0), 0.15, 0.08, 0.05, rot=(0, 0, 180))
	B((0.06, 0.06, 0.16), (0.11, -0.02, 1.0), IRON("dark"), bevel=0.004, rot=(0, -30, 0))


def mp_collapsed_set():
	# the leg that still stands, leaning
	hewn((0.34, 0.3, 0.08), (-0.6, 0, 0.04))
	post((-0.62, 0, 0.07), (-0.45, 0, 1.22), 0.1)
	# the cap beam, one end on the leaning leg, the other on the floor
	p0, p1 = Vector((-0.45, 0, 1.3)), Vector((0.78, 0, 0.09))
	d = p1 - p0
	ang = math.degrees(math.atan2(-d.z, d.x))
	hewn((d.length + 0.1, 0.2, 0.18), tuple((p0 + p1) / 2), rot=(0, ang, 0))
	# the other leg, snapped: a stump behind and its top half lying in front
	post((0.55, 0.4, 0.0), (0.56, 0.4, 0.55), 0.1)
	splinters((0.56, 0.4, 0.56), (0, 0, 1), n=5, r=0.08)
	post((0.0, -0.55, 0.1), (0.93, -0.42, 0.1), 0.1)
	splinters((0.952, -0.42, 0.1), (1, 0.1, 0.05), n=4, r=0.08)
	# lagging boards that came down, and the rock that followed
	for (x, y, a) in ((-0.2, 0.45, 12), (-0.95, -0.35, 70)):
		G((0.9, 0.18, 0.035), (x, y, 0.018), PLK(), bevel=0.008, rot=(0, 0, a))
	rubble(0.45, 0.05, 0.9, 0.6, 32, 0.34, seed=21)
	lp = place(lambda: lamp((0, 0, 0)), at=(-0.75, 0.25, 0.0), rot=(0, 80, 140))
	drop(lp)


def mp_rest_corner():
	# a bench: a thick split plank on two log rounds
	for x in (-0.45, 0.45):
		post((x, 0.3, 0.0), (x, 0.3, 0.36), 0.13)
	hewn((1.3, 0.32, 0.07), (0, 0.3, 0.39))
	for x in (-0.45, 0.45):
		peg((x, 0.3, 0.427), "z")
	# an upturned crate used as a table
	crate(0.52, 0.42, 0.44, (0.1, -0.3, 0.0))
	G((0.6, 0.48, 0.03), (0.1, -0.3, 0.455), PLK(), bevel=0.008)
	t = 0.47
	mug((0.28, -0.22, t))
	mp = place(lambda: mug((0, 0, 0)), at=(-0.04, -0.4, t + 0.045), rot=(90, 0, 35))
	kit.cylinder(0.05, 0.12, (0.0, -0.18, t + 0.06), kit.tex_mat("leather", "b"), verts=10, bevel=0.006)
	kit.ring(0.05, 0.007, (0.0, -0.18, t + 0.118), kit.tex_mat("leather", "dark"), seg=12)
	for k, (x, y) in enumerate(((0.12, -0.42), (0.18, -0.36))):
		B((0.03, 0.03, 0.03), (x, y, t + 0.015), BONE(), bevel=0.006, rot=(0, 0, 20 + k * 37))
	lamp((0.3, -0.42, t))
	# the stool knocked over as they ran
	def stool():
		kit.cylinder(0.15, 0.06, (0, 0, 0.42), PLK(), verts=12, bevel=0.01)
		for k in range(3):
			a = 2 * math.pi * k / 3
			log((math.cos(a) * 0.08, math.sin(a) * 0.08, 0.4), (math.cos(a) * 0.15, math.sin(a) * 0.15, 0.0), 0.028, BARK(), seg=6, rings=2, ends=False)
		kit.ring(0.11, 0.012, (0, 0, 0.18), ROPE(), seg=14)
	drop(place(stool, at=(0.75, -0.25, 0.3), rot=(100, 0, 60)))


def mp_bucket_line():
	bucket((-0.65, 0.05, 0.0))
	bucket((-0.3, -0.05, 0.0))
	drop(place(lambda: bucket((0, 0, 0), handle=False), at=(0.12, -0.1, 0.3), rot=(90, 0, 30)))
	disc(0.2, 0.002, 0.008, (0.12, -0.38), C((0.07, 0.08, 0.09), 0.15), seg=18, wob=0.15)
	drop(place(lambda: bucket((0, 0, 0), handle=False), at=(0.6, 0.08, 0.5), rot=(180, 0, 10)))
	# the yoke dropped in front of them, rope drops and hooks lying on the floor
	pts = [(-0.75, -0.42, 0.03), (-0.35, -0.47, 0.035), (0.0, -0.49, 0.04), (0.35, -0.47, 0.035), (0.75, -0.42, 0.03)]
	tube(pts, [0.024, 0.03, 0.035, 0.03, 0.024], PLK(), seg=8, up=(0, 0, 1))
	for s_ in (-1, 1):
		kit.ring(0.03, 0.008, (s_ * 0.72, -0.42, 0.03), IRON("dark"), rot=(90, 0, 90), seg=10)
		log((s_ * 0.72, -0.44, 0.012), (s_ * 0.6, -0.62, 0.012), 0.011, ROPE(), seg=6, rings=2, ends=False, bend=0.1)
		tube([(s_ * 0.6, -0.62, 0.012), (s_ * 0.58, -0.68, 0.012), (s_ * 0.61, -0.71, 0.012)], [0.008] * 3, IRON("dark"), seg=6, up=(0, 0, 1))


def mp_hewing_log():
	for x in (-0.6, 0.6):
		post((x, -0.38, 0.1), (x, 0.38, 0.1), 0.1)
	zc = 0.2 + 0.2 - 0.02
	big = post((-0.95, 0, zc), (0.95, 0, zc), 0.2)
	# hew the top flat over most of its length, and cut three scoring notches in the rest
	cut_m = END()
	for (size, loc, rot) in (((1.1, 0.6, 0.2), (-0.35, 0, zc + 0.12 + 0.1), (0, 0, 0)),
			((0.09, 0.6, 0.09), (0.45, 0, zc + 0.2), (0, 45, 0)), ((0.09, 0.6, 0.09), (0.62, 0, zc + 0.2), (0, 45, 0)),
			((0.09, 0.6, 0.09), (0.78, 0, zc + 0.2), (0, 45, 0))):
		bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=[math.radians(a) for a in rot])
		cut = bpy.context.object
		cut.scale = size
		cut.data.materials.append(cut_m)
		md = big.modifiers.new("hew", "BOOLEAN")
		md.operation, md.object, md.solver = "DIFFERENCE", cut, "EXACT"
		md.material_mode = "TRANSFER"
		bpy.context.view_layer.objects.active = big
		bpy.ops.object.modifier_apply(modifier=md.name)
		bpy.data.objects.remove(cut, do_unlink=True)
	# log dogs: iron staples holding the log to each bearer
	for x in (-0.6, 0.6):
		for s_ in (-1, 1):
			tube([(x + 0.06, s_ * 0.13, 0.19), (x + 0.06, s_ * 0.2, 0.25), (x + 0.06, s_ * 0.17, 0.33)], [0.012] * 3, IRON("dark"), seg=6, up=(1, 0, 0))
	# the broad axe stuck in the log, handle up
	place(lambda: t_axe(0.75, broad=True), at=(0.407, 0.0, 1.224), basis=((0.819, 0, 0.574), (0, -1, 0), (0.574, 0, -0.819)))
	chips(0.0, -0.55, 1.6, 0.4, 16, seed=9)


def mp_foreman_desk():
	H0, H1 = 0.86, 1.0
	for x in (-0.36, 0.36):
		post((x, -0.22, 0.0), (x, -0.22, H0), 0.04)
		post((x, 0.22, 0.0), (x, 0.22, H1), 0.04)
		post((x, -0.22, 0.3), (x, 0.22, 0.3), 0.03)
	hewn((0.8, 0.5, 0.03), (0, 0, 0.3 + 0.04))
	staves((0.15, 0.05, 0.355), 0.09, 0.14, n=9, bands=(0.03, -0.03))
	ang = math.degrees(math.atan2(H1 - H0, 0.44))

	def top():
		for i in range(4):
			G((0.84, 0.13, 0.035), (0, -0.2 + i * 0.133, 0.0), PLK(), bevel=0.008)
		G((0.84, 0.03, 0.05), (0, -0.28, 0.025), DARK(), bevel=0.006)
		for x in (-0.36, 0.36):
			peg((x, -0.13, 0.019), "z")
		# the open ledger: leather covers, two page blocks
		B((0.5, 0.33, 0.012), (-0.08, 0.0, 0.022), kit.tex_mat("leather", "dark"), bevel=0.004)
		for s_ in (-1, 1):
			B((0.235, 0.31, 0.025), (-0.08 + s_ * 0.122, 0.0, 0.04), PARCH(), bevel=0.006, rot=(0, -s_ * 3, 0))
		# ink pot, quill and a candle burnt to a stub
		kit.cylinder(0.035, 0.06, (0.27, 0.08, 0.047), IRON("dark"), verts=10, bevel=0.006)
		kit.cylinder(0.024, 0.006, (0.27, 0.08, 0.078), INK(), verts=10, bevel=0.001)
		kit.cone(0.008, 0.001, 0.26, (0.26, 0.11, 0.16), C((0.62, 0.58, 0.5), 0.8), rot=(-20, 14, 0), verts=5, bevel=0)
		kit.cylinder(0.05, 0.012, (0.27, -0.12, 0.024), IRON("dark"), verts=12, bevel=0.003)
		kit.cylinder(0.022, 0.04, (0.27, -0.12, 0.05), WAX(), verts=8, bevel=0.005)
		for k in range(3):
			a = 2.1 * k
			kit.gem((0.27 + math.cos(a) * 0.022, -0.12 + math.sin(a) * 0.022, 0.04), (0.008, 0.008, 0.016), WAX(), seed=k)
		kit.ring(0.018, 0.005, (0.32, -0.12, 0.024), IRON("dark"), rot=(90, 0, 0), seg=8)
	place(top, at=(0, 0, (H0 + H1) / 2 + 0.03), rot=(ang, 0, 0))
	# the measuring rod leaning on the desk's side
	post((0.62, -0.1, 0.0), (0.4, -0.08, 0.95), 0.016, PLK())
	for z in (0.012, 0.93):
		kit.ring(0.017, 0.005, (0.62 + (0.4 - 0.62) * z / 0.95, -0.1 + 0.02 * z / 0.95, z), IRON("dark"), rot=(0, -13, 0), seg=8)


# ================= intact props =================
def mp_prop_crib():
	t, L = 0.16, 0.9
	n = 6
	for k in range(n):
		z = t / 2 + k * (t - 0.006)
		for s_ in (-1, 1):
			if k % 2 == 0:
				hewn((L, t, t), (0, s_ * 0.33, z))
			else:
				hewn((t, L, t), (s_ * 0.33, 0, z))
	zt = t + (n - 1) * (t - 0.006)
	for i in range(4):
		G((0.95, 0.2, 0.04), (0, -0.32 + i * 0.213, zt + 0.014), PLK(), bevel=0.008)
	for s_ in (-1, 1):
		wedge((s_ * 0.2, -0.25, zt + 0.032), 0.18, 0.07, 0.04, rot=(0, 0, 0 if s_ < 0 else 180))
	# iron dogs bridging the layers at the front corners
	for x in (-0.33, 0.33):
		for k in (0, 2, 4):
			z = t / 2 + k * (t - 0.006) + (t - 0.006) / 2
			B((0.03, 0.02, 0.2), (x, -0.33 - t / 2 - 0.004, z), IRON("dark"), bevel=0.004)
			for dz in (-0.07, 0.07):
				rivet((x, -0.33 - t / 2 - 0.016, z + dz), IRON("a"), r=0.01)


def mp_prop_and_cap():
	hewn((0.5, 0.36, 0.08), (0, 0, 0.04))
	post((0, 0, 0.07), (0, 0, 1.86), 0.11)
	hewn((0.95, 0.26, 0.12), (0, 0, 1.92))
	for s_ in (-1, 1):
		wedge((s_ * 0.0, s_ * 0.15, 1.849), 0.13, 0.07, 0.03, rot=(0, 0, -90 * s_))
	B((0.04, 0.02, 0.26), (0, -0.112, 1.82), IRON("dark"), bevel=0.004)
	for z in (1.72, 1.92):
		rivet((0, -0.124, z), IRON("a"), r=0.012)
	wedge((0.32, 0.0, 0.08), 0.14, 0.08, 0.035, rot=(0, 0, 180))
	# an iron spike with a lamp hanging on it
	log((0, -0.1, 1.4), (0, -0.2, 1.42), 0.01, IRON("dark"), seg=6, rings=1, ends=False, bend=0)
	hung_lamp((0, -0.17, 1.414 - 0.01))
	kit.rope_wrap((0.0, 0.0), 0.112, 0.5, 0.58, 3, thick=0.012, material=ROPE())


def mp_door_set():
	for s_ in (-1, 1):
		hewn((0.32, 0.3, 0.08), (s_ * 0.66, 0, 0.04))
		post((s_ * 0.66, 0, 0.07), (s_ * 0.57, 0, 1.76), 0.1)
		wedge((s_ * 0.57, -0.12, 1.75), 0.14, 0.06, 0.03, rot=(0, 0, 90))
		B((0.035, 0.02, 0.24), (s_ * 0.575, -0.103, 1.6), IRON("dark"), bevel=0.004)
		rivet((s_ * 0.575, -0.115, 1.54), IRON("a"), r=0.011)
	hewn((1.55, 0.24, 0.2), (0, 0, 1.85))
	for i in range(6):
		G((0.19, 0.95, 0.04), (-0.55 + i * 0.22, J(0.03), 1.965), PLK(), bevel=0.008, rot=(0, 0, J(2)))
	log((-0.57, -0.1, 1.3), (-0.57, -0.2, 1.32), 0.01, IRON("dark"), seg=6, rings=1, ends=False, bend=0)
	hung_lamp((-0.57, -0.17, 1.314 - 0.01))


def mp_shaft_windlass():
	# the collar: three layers of hewn timbers (a crib) round a really hollow shaft (owner: make the shaft hollow)
	for k in range(3):
		z = 0.07 + k * 0.13
		for s_ in (-1, 1):
			if k % 2 == 0:
				hewn((1.15, 0.14, 0.14), (0, s_ * 0.5, z))
			else:
				hewn((0.14, 1.15, 0.14), (s_ * 0.5, 0, z))
	ztop = 0.07 + 2 * 0.13 + 0.07
	# the shaft lining: split boards on the four inner faces, dark near the top, black lower down (it goes deep)
	n, Wi = 4, 0.86
	for s_ in (-1, 1):
		for i in range(n):
			u = -Wi / 2 + Wi / n * (i + 0.5)
			for (z0, z1, m) in ((0.012, ztop * 0.55, HOLE), (ztop * 0.55 + 0.004, ztop - 0.03, DARK)):
				hz = z1 - z0
				G((Wi / n - 0.012, 0.03, hz), (u, s_ * (0.43 - 0.011), z0 + hz / 2), m(), bevel=0.006)
				G((0.03, Wi / n - 0.012, hz), (s_ * (0.43 - 0.011), u, z0 + hz / 2), m(), bevel=0.006)
	B((0.8, 0.8, 0.012), (0, 0, 0.006), HOLE(), bevel=0)
	for s_ in (-1, 1):
		post((s_ * 0.5, 0, ztop - 0.01), (s_ * 0.5, 0, 1.05), 0.06)
		for t in (-1, 1):
			post((s_ * 0.5, t * 0.42, ztop - 0.005), (s_ * 0.5, t * 0.04, 0.85), 0.035)
		hewn((0.14, 0.16, 0.12), (s_ * 0.5, 0, 1.1))
		B((0.02, 0.03, 0.2), (s_ * 0.59, 0, 1.01), IRON("dark"), bevel=0.003)
	# the drum on its iron axle, the crank on the right
	kit.cylinder(0.022, 1.28, (0, 0, 1.1), IRON("a"), rot=(0, 90, 0), verts=8, bevel=0.003)
	post((-0.41, 0, 1.1), (0.41, 0, 1.1), 0.09)
	for s_ in (-1, 1):
		B((0.025, 0.04, 0.24), (s_ * 0.63, 0, 1.0), IRON("dark"), bevel=0.004)
		log((s_ * 0.62, 0, 0.9), (s_ * 0.78, 0, 0.9), 0.02, PLK(), seg=7, rings=1, ends=False, bend=0)
	for k in range(7):
		kit.ring(0.094, 0.013, (-0.16 + k * 0.024, 0, 1.1), ROPE(), rot=(0, 90, 0), seg=16)
	# the bucket is let down into the shaft: its handle just below the rim
	zb = 0.12
	hb = bucket((0.0, -0.1, zb), 0.13, 0.22)
	log((0.0, -0.1, 1.1 - 0.01), (0.0, -0.1, hb - 0.004), 0.012, ROPE(), seg=6, rings=2, ends=False, bend=0.0)


def mp_hoist_tripod():
	apex = Vector((0, 0, 2.2))
	for k in range(3):
		a = math.radians(90 + 120 * k)
		foot = (math.cos(a) * 0.95, math.sin(a) * 0.95, 0.0)
		post(foot, tuple(apex + Vector((math.cos(a), math.sin(a), 0.6)).normalized() * 0.12), 0.07)
		kit.cylinder(0.08, 0.05, (foot[0], foot[1], 0.025), IRON("dark"), verts=10, bevel=0.005)
	for z in (2.08, 2.14, 2.2):
		kit.ring(0.11, 0.016, (0, 0, z), ROPE(), seg=14)
	kit.cylinder(0.05, 0.2, (0, 0, 2.08), IRON("dark"), verts=10, bevel=0.008)
	chain((0, 0, 1.99), (0, 0, 1.1))
	tube([(0, 0, 1.11), (0, 0, 1.0), (0.04, 0, 0.94), (0.085, 0, 0.97), (0.09, 0, 1.01)], [0.016, 0.016, 0.014, 0.01, 0.006], IRON("dark"), seg=7)
	post((-0.6, 0.0, 0.1), (0.6, 0.0, 0.1), 0.1)
	for s_ in (-1, 1):
		kit.ring(0.105, 0.014, (s_ * 0.35, 0, 0.1), ROPE(), rot=(0, 90, 0), seg=14)
		log((s_ * 0.35, 0, 0.2), (0.03, 0, 0.955), 0.013, ROPE(), seg=6, rings=2, ends=False, bend=0.0)
	coil_floor = [(0.75, -0.55), ]
	for (x, y) in coil_floor:
		for k in range(4):
			kit.ring(0.17 - k * 0.012, 0.014, (x, y, 0.014 + k * 0.022), ROPE(), seg=20)


def mp_sorting_table():
	W, D, H = 1.4, 0.72, 0.8
	for x in (-W / 2 + 0.09, W / 2 - 0.09):
		for y in (-D / 2 + 0.08, D / 2 - 0.08):
			post((x, y, 0), (x, y, H - 0.06), 0.05)
		post((x, -D / 2 + 0.08, 0.18), (x, D / 2 - 0.08, 0.18), 0.035)
	for i in range(4):
		G((W, D / 4 - 0.006, 0.05), (0, -D / 2 + D / 4 * (i + 0.5), H - 0.025), PLK(), bevel=0.008)
	G((W, 0.04, 0.12), (0, D / 2 - 0.02, H + 0.05), DARK(), bevel=0.008)
	for s_ in (-1, 1):
		G((0.04, D, 0.1), (s_ * (W / 2 - 0.02), 0, H + 0.04), DARK(), bevel=0.008)
	for x in (-0.55, 0.0, 0.55):
		peg((x, D / 2 - 0.042, H + 0.07))
	# under-shelf with a tub of waste rock
	for i in range(3):
		G((W - 0.24, 0.17, 0.03), (0, -0.2 + i * 0.2, 0.215), PLK(), bevel=0.006)
	staves((0.3, 0.0, 0.23), 0.17, 0.2, n=12, bands=(0.04, -0.04))
	rubble(0.3, 0.0, 0.26, 0.26, 9, 0.12, seed=5, z0=0.38)
	# the heap still to sort (left), with copper and iron bits showing
	heap = rubble(-0.42, 0.02, 0.45, 0.45, 22, 0.2, seed=31, z0=H)
	for k, (x, y, zb, zt, rad) in enumerate(heap[-7:]):
		kit.gem((x, y, zt - 0.01), (0.03, 0.025, 0.02), kit.tex_mat("copper", "b") if k % 2 else IRON("dark"), seed=k)
	# three trays of sorted ore
	for i, kind in enumerate(("copper", "iron", "waste")):
		x = 0.0 + i * 0.22 - 0.0
		y = -0.12
		crate(0.2, 0.3, 0.09, (x + 0.02, y, H))
		for k in range(6):
			o = lump((x + 0.02 + (k % 2 - 0.5) * 0.08, y - 0.09 + (k // 2) * 0.09, H + 0.06), (0.045, 0.04, 0.03), ROCK(), seed=i * 10 + k, rough=0.006)
			if kind != "waste":
				kit.gem((x + 0.02 + (k % 2 - 0.5) * 0.08, y - 0.09 + (k // 2) * 0.09, H + 0.085), (0.02, 0.018, 0.014),
					kit.tex_mat("copper", "b") if kind == "copper" else IRON("dark"), seed=k)
	# the spalling hammer lying on the right
	place(lambda: t_hammer(0.3), at=(0.5, 0.18, H + 0.016), rot=(90, 0, -70))


def mp_tool_shed():
	W, D = 1.3, 0.85
	Hf, Hb = 1.65, 1.35
	for s_ in (-1, 1):
		post((s_ * W / 2, -D / 2, 0), (s_ * W / 2, -D / 2, Hf), 0.06)
		post((s_ * W / 2, D / 2, 0), (s_ * W / 2, D / 2, Hb), 0.06)
	hewn((W + 0.2, 0.1, 0.1), (0, -D / 2, Hf + 0.03))
	hewn((W + 0.2, 0.1, 0.1), (0, D / 2, Hb + 0.03))
	slope = math.degrees(math.atan2(Hf - Hb, D))
	Lr = math.hypot(D + 0.3, Hf - Hb)
	for i in range(7):
		x = -W / 2 - 0.05 + i * (W + 0.1) / 6
		G((0.2, Lr, 0.03), (x, 0, (Hf + Hb) / 2 + 0.095), PLK(), bevel=0.006, rot=(-slope, 0, 0))
	# back wall of vertical planks, low side walls of boards
	for i in range(6):
		G((W / 6 - 0.008, 0.035, Hb - 0.02), (-W / 2 + W / 6 * (i + 0.5), D / 2 + 0.065, (Hb - 0.02) / 2), PLK(), bevel=0.008)
	for s_ in (-1, 1):
		for k in range(4):
			G((0.035, D - 0.06, 0.19), (s_ * (W / 2 + 0.065), 0, 0.1 + k * 0.2), PLK(), bevel=0.008)
	for z in (0.4, 1.1):
		hewn((W, 0.06, 0.08), (0, D / 2 + 0.017, z))
	# a shelf on the back wall with a small crate and a coil of rope
	G((0.6, 0.2, 0.03), (-0.25, D / 2 - 0.09, 1.0), PLK(), bevel=0.006)
	for x in (-0.5, 0.0):
		G((0.03, 0.15, 0.08), (x, D / 2 - 0.07, 0.95), DARK(), bevel=0.005)
	crate(0.22, 0.16, 0.14, (-0.4, D / 2 - 0.09, 1.015))
	for k in range(3):
		kit.ring(0.08, 0.013, (-0.12, D / 2 - 0.09, 1.028 + k * 0.022), ROPE(), seg=18)
	# tools leaning on the back wall
	yb = D / 2 + 0.047
	for (x, fn, ln) in ((-0.45, t_shovel, 1.0), (-0.17, t_shovel, 0.95), (0.1, t_pick, 0.85), (0.35, t_bar, 1.1)):
		reach = ln * 0.98
		dy = 0.22
		place(lambda fn=fn, ln=ln: fn(ln), at=(x, yb - dy - 0.03, 0.0), d=(0, dy, math.sqrt(reach * reach - dy * dy)))
	log((W / 2, -D / 2 - 0.06, 1.3), (W / 2, -D / 2 - 0.15, 1.32), 0.01, IRON("dark"), seg=6, rings=1, ends=False, bend=0)
	hung_lamp((W / 2, -D / 2 - 0.12, 1.314 - 0.01))


def mp_bailing_tub():
	R, Ht = 0.4, 0.46
	staves((0, 0, 0), R, Ht, n=22, thick=0.03, bands=(0.07, 0.23, -0.06))
	for s_ in (-1, 1):  # two lug staves with carrying holes
		G((0.1, 0.04, 0.16), (s_ * (R - 0.01), 0, Ht + 0.06), PLK(), bevel=0.008)
		kit.ring(0.03, 0.009, (s_ * (R - 0.01), -0.02, Ht + 0.08), IRON("dark"), rot=(90, 0, 0), seg=10)
	# the dipper standing in the empty tub, its handle on the rim
	lathe([(0.012, 0.0), (0.06, 0.006), (0.07, 0.06), (0.065, 0.1), (0.055, 0.098), (0.057, 0.012), (0.012, 0.008)][::-1], (0.12, -0.12, 0.047), PLK(), seg=12)
	log((0.15, -0.15, 0.13), (0.3, -0.44, Ht + 0.09), 0.015, PLK(), seg=6, rings=2, ends=False, bend=0.02)
	# two buckets stacked beside it
	bucket((0.65, -0.1, 0.0), 0.13, 0.22, handle=False)
	bucket((0.65, -0.1, 0.07), 0.142, 0.22)


def mp_bell_frame():
	for s_ in (-1, 1):
		hewn((0.12, 0.7, 0.1), (s_ * 0.45, 0, 0.05))
		post((s_ * 0.45, 0, 0.09), (s_ * 0.45, 0, 1.52), 0.06)
		for t in (-1, 1):
			post((s_ * 0.45, t * 0.3, 0.09), (s_ * 0.45, t * 0.04, 0.6), 0.035)
	hewn((1.15, 0.14, 0.13), (0, 0, 1.56))
	for s_ in (-1, 1):
		peg((s_ * 0.45, -0.07, 1.56))
		hewn((0.3, 0.06, 0.06), (s_ * 0.33, 0, 1.43), rot=(0, s_ * 40, 0))
	B((0.05, 0.05, 0.1), (0, 0, 1.47), IRON("dark"), bevel=0.006)
	kit.ring(0.035, 0.01, (0, 0, 1.415), IRON("dark"), rot=(90, 0, 0), seg=10)
	h = 0.3
	z0 = 1.39 - h
	lathe([(0.03, h), (0.085, h - 0.012), (0.11, h * 0.7), (0.135, h * 0.3), (0.165, 0.025), (0.172, 0.0),
		(0.15, 0.0), (0.142, 0.03), (0.115, h * 0.32), (0.09, h * 0.7), (0.03, h - 0.03)], (0, 0, z0), IRON("dark"), seg=18)
	kit.ring(0.172, 0.008, (0, 0, z0 + 0.03), IRON("a"), seg=18)
	log((0, 0, z0 + h - 0.03), (0, 0, z0 - 0.02), 0.01, IRON("dark"), seg=6, rings=1, ends=False, bend=0)
	kit.cylinder(0.035, 0.05, (0, 0, z0 - 0.03), IRON("dark"), verts=10, bevel=0.012)
	kit.ring(0.02, 0.006, (0, 0, z0 - 0.065), IRON("dark"), rot=(90, 0, 0), seg=8)
	log((0, 0, z0 - 0.08), (0.02, -0.02, 0.62), 0.011, ROPE(), seg=6, rings=3, ends=False, bend=0.05)
	G((0.12, 0.03, 0.03), (0.02, -0.02, 0.61), PLK(), bevel=0.008)


def mp_wedge_crate():
	w, d, h = 0.62, 0.46, 0.34
	crate(w, d, h, (0, 0, 0))
	for row in range(3):
		y = -0.13 + row * 0.13
		x, k = -w / 2 + 0.06, 0
		while x < w / 2 - 0.08:
			H = 0.035 + 0.01 * ((k + row) % 3)
			wedge((x + H, y, 0.035), 0.36 - 0.04 * ((k + 2 * row) % 3), 0.085, H, rot=(0, -90 + J(4), J(4)))
			x += H + 0.006
			k += 1
	for (x, y, a) in ((-0.2, -0.45, 20), (0.05, -0.5, -30), (-0.5, -0.1, 80)):
		wedge((x, y, 0.0), 0.22, 0.08, 0.045, rot=(0, 0, a))
	# a maul with its head on the floor and its handle against the crate
	log((0.52, -0.21, 0.065), (0.52, 0.01, 0.065), 0.065, BARK(), seg=10, rings=1, bend=0, end_m=END())
	for yy in (-0.18, -0.02):
		kit.ring(0.067, 0.009, (0.52, yy, 0.065), IRON("dark"), rot=(90, 0, 0), seg=14)
	log((0.52, -0.1, 0.065), (0.31, -0.1, 0.36), 0.02, PLK(), seg=7, rings=2, ends=False, bend=0)


def mp_prop_trolley():
	for s_ in (-1, 1):
		for x in (-0.45, 0.45):
			kit.cylinder(0.15, 0.06, (x, s_ * 0.34, 0.15), PLK(), rot=(90, 0, 0), verts=16, bevel=0.008)
			kit.ring(0.15, 0.012, (x, s_ * 0.34, 0.15), IRON("dark"), rot=(90, 0, 0), seg=18)
			kit.cylinder(0.035, 0.08, (x, s_ * 0.36, 0.15), IRON("dark"), rot=(90, 0, 0), verts=8, bevel=0.004)
			hewn((0.14, 0.12, 0.12), (x, s_ * 0.25, 0.2))
		hewn((1.45, 0.1, 0.1), (0, s_ * 0.25, 0.3))
	for x in (-0.45, 0.45):
		kit.cylinder(0.02, 0.76, (x, 0, 0.15), IRON("a"), rot=(90, 0, 0), verts=8, bevel=0.003)
	for x in (-0.55, 0.0, 0.55):
		hewn((0.12, 0.66, 0.08), (x, 0, 0.385))
		for s_ in (-1, 1):
			log((x, s_ * 0.3, 0.41), (x, s_ * 0.31, 0.68), 0.015, IRON("dark"), seg=6, rings=1, ends=False, bend=0)
	r = 0.08
	zb = 0.425 + r - 0.005
	for i, y in enumerate((-0.18, 0.0, 0.18)):
		post((-0.85 + J(0.04), y, zb), (0.85 + J(0.04), y, zb), r)
	for y in (-0.09, 0.09):
		post((-0.8, y, zb + 0.12), (0.82, y, zb + 0.12), r)
	# two lashings pulled tight round the bundle's outline (owner: ropes wrap tight), the ends under a knot on top
	cs = [(-0.18, zb), (0.0, zb), (0.18, zb), (-0.09, zb + 0.12), (0.09, zb + 0.12)]
	Rr = r + 0.014 - 0.004
	for x in (-0.3, 0.3):
		pts = []
		for k in range(41):
			a = math.pi / 2 + 0.12 + (2 * math.pi - 0.24) * k / 40
			n = (math.cos(a), math.sin(a))
			cy_, cz_ = max(cs, key=lambda c: c[0] * n[0] + c[1] * n[1])
			pts.append((x, cy_ + n[0] * Rr, cz_ + n[1] * Rr))
		tube(pts, [0.014] * len(pts), ROPE(), seg=7, up=(1, 0, 0))
		sphere((x, 0.0, zb + 0.12 + Rr + 0.004), 0.026, ROPE(), scale=(1.2, 1.0, 0.75), seg=10, rings=6)
		for s_ in (-1, 1):
			log((x + s_ * 0.012, s_ * 0.015, zb + 0.12 + Rr + 0.01), (x + s_ * 0.05, s_ * 0.07, zb + 0.12 + Rr - 0.02), 0.009, ROPE(), seg=6, rings=1, ends=False, bend=0)
	hewn((0.1, 0.56, 0.1), (0.66, 0, 0.3))
	kit.ring(0.045, 0.01, (0.75, 0, 0.3), IRON("dark"), rot=(90, 0, 0), seg=10)
	log((0.8, 0, 0.29), (1.1, -0.15, 0.012), 0.013, ROPE(), seg=6, rings=3, ends=False, bend=0.1)
	log((1.1, -0.15, 0.012), (1.25, -0.4, 0.012), 0.013, ROPE(), seg=6, rings=2, ends=False, bend=0.1)


def mp_lagging_stack():
	for x in (-0.38, 0.38):
		post((x, -0.45, 0.07), (x, 0.45, 0.07), 0.07)
	z = 0.135
	for layer in range(6):
		for i in range(4):
			G((1.15 + J(0.04), 0.18, 0.035), (J(0.02), -0.29 + i * 0.193, z + 0.0175), PLK(), bevel=0.007, rot=(0, 0, J(1.5)))
		z += 0.034
		if layer < 5:
			for x in (-0.38, 0.38):
				G((0.04, 0.8, 0.03), (x, 0, z + 0.014), DARK(), bevel=0.005)
			z += 0.026
	lump((-0.2, 0.05, z + 0.07), (0.16, 0.12, 0.09), ROCK(), seed=4, rough=0.01)
	rest(bpy.context.object, z - 0.005)
	place(lambda: t_axe(0.42), at=(0.18, -0.05, z + 0.019), rot=(90, 0, 70))
	for x in (-0.38, 0.38):
		B((0.03, 0.02, 0.14), (x, -0.46, 0.18), IRON("dark"), bevel=0.003)


def mp_prop_rack():
	W = 1.45
	hewn((W, 0.14, 0.1), (0, -0.32, 0.05))
	hewn((W, 0.14, 0.1), (0, 0.22, 0.05))
	for s_ in (-1, 1):
		hewn((0.12, 0.62, 0.08), (s_ * (W / 2 - 0.06), -0.05, 0.12))
		post((s_ * (W / 2 - 0.06), 0.22, 0.11), (s_ * (W / 2 - 0.06), 0.22, 1.45), 0.06)
		post((s_ * (W / 2 - 0.06), -0.25, 0.14), (s_ * (W / 2 - 0.06), 0.18, 0.75), 0.035)
	hewn((W + 0.1, 0.12, 0.12), (0, 0.22, 1.4))
	for s_ in (-1, 1):
		peg((s_ * (W / 2 - 0.06), 0.158, 1.4))
	for i in range(8):
		x = -0.56 + i * 0.16
		r = 0.055 + 0.02 * ((i * 3) % 3) / 2
		foot = Vector((x, -0.2, 0.0))
		d = Vector((0, 0.16 - r - (-0.2), 1.4)).normalized()
		post(tuple(foot), tuple(foot + d * (1.65 + 0.12 * ((i * 5) % 3))), r)


def mp_tool_barrel():
	R, H = 0.24, 0.6
	staves((0, 0, 0), R, H, n=14, bands=(0.06, 0.3, -0.06))
	# handles down on the barrel floor near the middle, each tool leaning out against the rim on its own side
	# (owner: tools lean on the rim, none standing in the middle, nothing through the staves)
	rin = R - 0.024  # inner face of the staves
	zf, zr = 0.046, H - 0.012
	tools = ((t_pick, 0.85, 20, "radial", False, 0.019), (t_shovel, 1.0, 110, "radial", True, 0.018),
		(t_bar, 1.1, 200, "radial", False, 0.017), (t_maul, 0.8, 290, "tangent", False, 0.02))
	for fn, ln, deg, orient, flip, hr in tools:
		a = math.radians(deg)
		u = Vector((math.cos(a), math.sin(a), 0))
		foot = u * 0.075 + Vector((0, 0, zf))
		rim = u * (rin - hr + 0.003) + Vector((0, 0, zr))
		d = (rim - foot).normalized()
		X = (u - d * u.dot(d)).normalized() if orient == "radial" else Vector((-math.sin(a), math.cos(a), 0))
		if flip:  # the shovel stands blade up: its grip end is the foot
			Z = -d
			X = -X
			at = foot + d * (ln - 0.01)
		else:
			Z, at = d, foot
		Y = Z.cross(X)
		place(lambda fn=fn, ln=ln: fn(ln), at=tuple(at), basis=(tuple(X), tuple(Y), tuple(Z)))


def mp_nail_keg():
	def keg():
		staves((0, 0, 0), 0.17, 0.36, n=12, bands=(0.05, 0.18, -0.05))
	drop(place(keg, at=(-0.3, 0.0, 0.3), rot=(90, 0, 70)))
	r = random.Random(13)
	for k in range(22):  # spilled spikes and timber dogs, fanning out of the open end
		a = r.uniform(-0.6, 0.6)
		dist = r.uniform(0.0, 0.42)
		x, y = 0.0 + math.cos(a + math.radians(-20)) * dist, -0.25 + math.sin(a + math.radians(-20)) * dist * 0.8 - 0.05
		if k % 3 == 0:
			o = tube([(x - 0.04, y, 0.03), (x - 0.04, y - 0.03, 0.012), (x + 0.04, y - 0.03, 0.012), (x + 0.04, y, 0.03)], [0.007] * 4, IRON("dark"), seg=5, up=(0, 0, 1))
		else:
			o = kit.cone(0.008, 0.001, 0.12, (x, y, 0.009), IRON("dark"), rot=(90, 0, r.uniform(0, 180)), verts=4, bevel=0)
		rest(o, 0.0 + 0.0005 * k)
	# the keg's lid lying on the floor, and a claw hammer
	for i in range(3):
		G((0.3, 0.1 - 0.004, 0.022), (0.35, 0.25 - 0.1 + i * 0.1, 0.011), PLK(), bevel=0.004)
	for x in (0.28, 0.42):
		G((0.04, 0.28, 0.02), (x, 0.25, 0.03), DARK(), bevel=0.004)
	drop(place(lambda: t_hammer(0.32), at=(0.4, -0.35, 0.2), rot=(90, 0, 120)))


MODELS = {name: fn for name, fn in globals().items() if name.startswith("mp_") and callable(fn)}

if __name__ == "__main__":
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	outdir = GAME / "assets" / "models" / "decor"
	jdir = GAME / "journey" / "3d" / "v2_hand_built" / "decor"
	outdir.mkdir(parents=True, exist_ok=True)
	jdir.mkdir(parents=True, exist_ok=True)
	for name in args or list(MODELS):
		rng.seed(sum(map(ord, name)))
		kit.reset()
		_cm.clear()
		try:
			MODELS[name]()
			kit.save(str(outdir / f"{name}.glb"), str(jdir / f"{name}.png"), tex_size=256)
			print(f"MODEL_OK {name}")
		except Exception as e:
			import traceback
			traceback.print_exc()
			print(f"MODEL_FAILED {name}: {e!r}")
