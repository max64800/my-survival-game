# Decor for THE HAMMERFALL WORKS (Nov 21): a big clay-brick dungeon, the hold's heavy works, driven by a great water
# wheel: trip hammers on cam shafts, wooden gear trains, line shafts, plate stacks, rail carts. Hearthbrick style:
# brick / brickochre / clay, one wood family ("wood"), iron, copper, a little ember glow. Only real medieval machinery.
#   blender --background --factory-startup --python builds/decor_nov21_hw.py -- [id ...]   (none = all)
# Output: assets/models/decor/<id>.glb (origin bottom-centre, front faces -Y). Wall pieces have a flat back at +Y.
#
# The 30 objects:
#   WALL PIECES
#   hw_gear_wall          wall board of spare gears: a big cog wheel and a small one on pegs, a lantern pinion, spare cogs on a shelf
#   hw_parts_rack         millwright's repair-parts rack: bearing blocks, cam tappets, iron collars, wedges, bolts, in tidy rows
#   hw_hammer_head_rack   two heavy wall beams on iron brackets holding three spare trip-hammer heads, helve hoops, wedges
#   hw_tool_board         millwright's tool board: adze, mallet, T-auger, chisels, dividers, square, drift, rope coil
#   hw_belt_pulley_wall   iron wall brackets carrying a stub shaft with a belt drum; the rope belt loops down to a tension weight
#   hw_chain_hook_wall    a hook rail: three lifting hooks on short chains, two hanging chain coils, shackles, a pulley block
#   hw_signal_lever_wall  three signal levers in an iron slot frame, pull wires up to three bells; lever numbers cut into a board
#   hw_shift_board        hammer-shift board: clay tally tablets with cut tally marks, copper hammer tokens on hooks, an hourglass
#   hw_grease_shelf       bearing-grease shelf: clay grease pots with paddles, tallow blocks, a copper oil can, a brush, a pail
#   MACHINES AND WORKS
#   hw_trip_hammer        the great tail-helve trip hammer: sills, hurst posts, helve, iron head over the anvil, cam shaft and cog
#   hw_plate_anvil        plate-beating anvil: banded stump, swage block with dished hollows, a half-beaten plate, two hammers
#   hw_gear_train         a right-angle drive on brick footings: big face-cog wheel driving a lantern pinion on an upright shaft
#   hw_line_shaft         a line shaft on two brick piers in bearing blocks, two belt drums, rope belts down to a floor pulley
#   hw_wheel_trough       a water wheel standing in its dry wooden race on a brick base, axle in bearing posts
#   hw_sluice_gate        a sluice: flume channel, grooved posts, gate board lifted by a pegged rack bar and a windlass
#   hw_flume_trough       a dry wooden flume on a trestle over a long empty brick trough, a copper dipper hooked on its wall
#   hw_plate_stack        three stacks of iron plate on timber skids with spacer sticks, a strap band and a lifting clamp
#   hw_rivet_brazier      rivet-heating brazier: brick pedestal, iron basket of black coal with glowing rivets, tongs, rivet pail
#   hw_chain_hoist        a timber gantry with an iron pulley block; the chain and hook hold an iron plate off the floor
#   hw_ingot_cart         an ingot cart on a rail section: banded plank box on four iron wheels, bronze ingots stacked criss-cross
#   hw_ingot_stack        a pallet of bronze ingots in criss-cross layers, chocks, a tally stick and a crowbar leaning on it
#   hw_overseer_platform  the overseer's raised platform on brick piers: plank deck, railing, steps, a standing desk with ledger
#   hw_signal_whistle     the shift whistle: a wind box on a post with three copper pipes and a lever bellows underneath
#   hw_spare_shaft        a spare cam shaft on two trestles, half its tappets fitted, the rest on the floor, drawknife and mallet
#   hw_plate_shears       lever shears for plate on a heavy timber block, a long lever, cut strips and offcuts at its foot
#   STORY SCENES
#   hw_jammed_hammer      a trip hammer jammed: a crowbar wedged in the cam, a snapped tappet on the floor, mallet and wedges dropped
#   hw_derailed_cart      an empty ingot cart off its rails lying on its side, one wheel rolled away
#   hw_snapped_chain      a hoist chain snapped: the plate fell and cracked the floor bricks, the hook and broken links beside it
#   hw_broken_cog         a cog wheel with broken teeth leans on a trestle; the broken cogs below, a new cog half cut on a block
#   hw_burst_sluice       a sluice gate burst: half the gate board hangs in its grooves, the rest lies in the dry channel, a bucket tipped
# Owner round 2 (Nov 22): no water anywhere (wheel race, sluices, flume are dry).
# LOOTABLE (each also builds <id>_empty, same model with the loot gone; looting code comes later):
#   hw_ingot_cart  -> 3 bronze ingots      hw_ingot_stack -> 3 bronze ingots
import math
import random
import sys
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from night_stations import B, GAME, J, T, disc, kit, log, mesh, rivet, rng  # noqa: E402
from night_materials import C, sphere, _cm  # noqa: E402
from night_decor import CU, IRON  # noqa: E402
from decor_nov21_f import glass, group  # noqa: E402
from decor_nov21_a import slim, carve, chain, groove, low_z, objs, shift, tube  # noqa: E402


# ================= materials: one wood family ("wood"), one ceramic family (brick / brickochre / clay) =================
def W(v=None):
	return T("wood", v)


WD = lambda: kit.tex_mat("wood", "dark")  # noqa: E731
BRK = lambda v=None: T("brick", v)  # noqa: E731
OCH = lambda v=None: T("brickochre", v)  # noqa: E731
CLAY = lambda v=None: T("clay", v)  # noqa: E731
MORTAR = lambda: C((0.16, 0.12, 0.09), 0.95)  # noqa: E731
GROOVE = lambda: C((0.04, 0.025, 0.018), 0.95)  # noqa: E731
COAL = lambda: C((0.028, 0.027, 0.03), 0.22, metal=0.25)  # noqa: E731
EMBER = lambda: C((1.0, 0.32, 0.06), 0.4, glow=2.6)  # noqa: E731
HOT = lambda: C((0.85, 0.24, 0.04), 0.4, glow=1.6)  # noqa: E731
GREASE = lambda: C((0.13, 0.1, 0.05), 0.25)  # noqa: E731
TALLOW = lambda: C((0.62, 0.55, 0.38), 0.7)  # noqa: E731
ROPE = lambda: kit.tex_mat("rope", "a")  # noqa: E731
LEATHER = lambda: kit.tex_mat("leather", "a")  # noqa: E731
BRONZE = lambda k=0: C(((0.34, 0.18, 0.06), (0.3, 0.16, 0.05), (0.38, 0.21, 0.08))[k % 3], 0.4, metal=0.8)  # noqa: E731
SAND = lambda: C((0.55, 0.42, 0.24), 0.95)  # noqa: E731
GLASS = lambda: glass((0.78, 0.86, 0.82), 0.3)  # noqa: E731


# ================= helpers =================
def rod(p0, p1, r, m=None, seg=6):
	"""A straight round bar; long ones get extra vertex rings so the checker sees what they rest on."""
	n = max(1, int((Vector(p1) - Vector(p0)).length / 0.08))
	return log(p0, p1, r, m or IRON("dark"), seg=seg, rings=n, ends=False, bend=0)


def beam(p0, p1, w, h=None, m=None, bevel=0.012):
	"""A squared timber (or iron bar) from p0 to p1, w wide, h high."""
	p0, p1 = Vector(p0), Vector(p1)
	d = p1 - p0
	yaw = math.degrees(math.atan2(d.y, d.x))
	pitch = math.degrees(math.atan2(d.z, math.hypot(d.x, d.y)))
	return B((d.length, w, h or w), tuple((p0 + p1) / 2), m or W(), bevel=bevel, rot=(0, -pitch, yaw))


def lathe(prof, c, m, seg=12, loop=False):
	"""A turned shape: prof = [(radius, z)] bottom to top. loop=True: a closed outline (hollow pots, bells)."""
	x0, y0, z0 = c
	v = []
	for r, z in prof:
		for k in range(seg):
			a = 2 * math.pi * k / seg
			v.append((x0 + math.cos(a) * r, y0 + math.sin(a) * r, z0 + z))
	n = len(prof)
	f = []
	for i in range(n if loop else n - 1):
		j = (i + 1) % n
		for k in range(seg):
			f.append((i * seg + k, i * seg + (k + 1) % seg, j * seg + (k + 1) % seg, j * seg + k))
	if not loop:
		f.append(tuple(reversed(range(seg))))
		f.append(tuple(range((n - 1) * seg, n * seg)))
	return mesh(v, f, m)


def pot(c, r, h, m, t=0.008, seg=14, flare=1.05, rim=True):
	"""A hollow clay pot / pail shell with a real floor and a rolled rim."""
	o = lathe([(0.003, 0), (r * 0.9, 0), (r, t * 2), (r * 1.08, h * 0.5), (r * flare, h - t), (r * flare + t * 0.6, h),
		(r * flare - t, h), (r * 1.08 - t, h * 0.5), (r - t, t + 0.005), (0.003, t + 0.005)], c, m, seg=seg, loop=True)
	if rim:
		kit.ring(r * flare + t * 0.2, t * 0.9, (c[0], c[1], c[2] + h - t * 0.3), m, seg=seg + 4)
	return o


def sector(ro, ri, z0, z1, a0, a1, m, seg=6):
	"""A solid ring piece (a felloe) around the z axis between angles a0 and a1."""
	v = []
	for i in range(seg + 1):
		a = a0 + (a1 - a0) * i / seg
		ca, sa = math.cos(a), math.sin(a)
		v += [(ca * ro, sa * ro, z0), (ca * ri, sa * ri, z0), (ca * ri, sa * ri, z1), (ca * ro, sa * ro, z1)]
	f = [(0, 1, 2, 3), tuple(reversed(range(seg * 4, seg * 4 + 4)))]
	for i in range(seg):
		a, b = i * 4, i * 4 + 4
		for k in range(4):
			f.append((a + k, b + k, b + (k + 1) % 4, a + (k + 1) % 4))
	return mesh(v, f, m)


def cog_wheel(c, r, t, n=16, rot=(0, 0, 0), face=False, arms=2, broken=(), felloes=6):
	"""A millwright's wooden cog wheel (built round the z axis, then turned by rot): pegged felloes with iron joint
	plates, crossing arms, an iron hub, wooden cogs on the rim (face=True: cogs stand out of the front face)."""
	def build():
		ri = r * 0.78
		g = 0.004 / r
		for k in range(felloes):
			a0, a1 = 2 * math.pi * k / felloes + g, 2 * math.pi * (k + 1) / felloes - g
			sector(r, ri, -t / 2, t / 2, a0, a1, W("abc"[k % 3]))
			a = 2 * math.pi * k / felloes
			jx, jy = math.cos(a) * (r + ri) / 2, math.sin(a) * (r + ri) / 2
			B((r * 0.09, (r - ri) * 0.8, 0.012), (jx, jy, t / 2 + 0.002), IRON("dark"), bevel=0.003, rot=(0, 0, math.degrees(a)))
			for s_ in (-1, 1):
				rivet((jx + math.cos(a) * s_ * (r - ri) * 0.25, jy + math.sin(a) * s_ * (r - ri) * 0.25, t / 2 + 0.008), IRON("a"), r=0.009)
		for k in range(arms):
			a = math.pi * k / arms + math.pi / felloes / 2
			B((2 * (ri + 0.02), r * 0.13, t * (0.82 - 0.06 * k)), (0, 0, 0), W("abc"[(k + 1) % 3]), bevel=0.008, rot=(0, 0, math.degrees(a)))
		kit.cylinder(r * 0.17, t * 1.25, (0, 0, 0), IRON("dark"), verts=12, bevel=0.004)
		for k in range(4):
			a = math.pi / 2 * k + math.pi / 4
			rivet((math.cos(a) * r * 0.12, math.sin(a) * r * 0.12, t * 0.63), IRON("a"), r=0.01)
		cw = 2 * math.pi * r / n * 0.42
		for k in range(n):
			a = 2 * math.pi * k / n
			stub = k in broken
			if face:
				h = r * (0.05 if stub else 0.14)
				B((r - ri - 0.03, cw, h + 0.03), (math.cos(a) * (r + ri) / 2, math.sin(a) * (r + ri) / 2, t / 2 + h / 2 - 0.01),
					WD() if k % 2 else W("c"), bevel=0.008 if not stub else 0.002, rot=(0, 0, math.degrees(a)))
			else:
				ln = r * (0.06 if stub else 0.17)
				B((ln + 0.03, cw, t * 0.78), (math.cos(a) * (r + ln / 2 - 0.012), math.sin(a) * (r + ln / 2 - 0.012), 0),
					WD() if k % 2 else W("c"), bevel=0.008 if not stub else 0.002, rot=(0, 0, math.degrees(a)))
	group(build, c, rot)


def pinion(c, r, ln, n=8, rot=(0, 0, 0)):
	"""A lantern pinion (built round the z axis): two banded discs joined by round staves."""
	def build():
		for s_ in (-1, 1):
			kit.cylinder(r * 1.3, 0.05, (0, 0, s_ * (ln / 2 + 0.02)), W("b"), verts=16, bevel=0.006)
			kit.ring(r * 1.3, 0.008, (0, 0, s_ * (ln / 2 + 0.02)), IRON("dark"), seg=20)
		for k in range(n):
			a = 2 * math.pi * k / n
			kit.cylinder(r * 0.13, ln + 0.06, (math.cos(a) * r, math.sin(a) * r, 0), W("c") if k % 2 else WD(), verts=8, bevel=0.003)
		kit.cylinder(r * 0.35, ln + 0.14, (0, 0, 0), IRON("dark"), verts=10, bevel=0.004)
	group(build, c, rot)


def shaft(p0, p1, r, bands=()):
	"""An eight-sided wooden shaft with iron bands at the given fractions along it."""
	log(p0, p1, r, W(), seg=8, rings=3, bend=0.004, end_m=W("c"))
	a, b = Vector(p0), Vector(p1)
	for f in bands:
		c = a + (b - a) * f
		d = (b - a).normalized() * 0.025
		rod(tuple(c - d), tuple(c + d), r * 1.16, IRON("dark"), seg=10)


def bearing(c, ax, r, w=0.2, h=None):
	"""A wooden bearing block under a shaft along axis 'x' or 'y' at centre c, with an iron cap strap and bolts."""
	x, y, z = c
	h = h or r * 1.4
	along = (0.12, w) if ax == "y" else (w, 0.12)
	B((along[0] if ax == "y" else 0.14, along[1] if ax == "y" else 0.14, h), (x, y, z - r * 0.4 - h / 2 + 0.03), W("b"), bevel=0.01)
	rot = (90, 0, 0) if ax == "y" else (0, 90, 0)
	kit.cylinder(r * 1.25, 0.05, c, IRON("dark"), rot=rot, verts=14, bevel=0.004)
	for s_ in (-1, 1):
		off = (s_ * r * 1.3, 0, 0) if ax == "y" else (0, s_ * r * 1.3, 0)
		kit.cylinder(0.014, h * 0.7 + r, (x + off[0], y + off[1], z - h * 0.35), IRON("dark"), verts=6, bevel=0.002)
		kit.cylinder(0.024, 0.02, (x + off[0], y + off[1], z + r * 0.15), IRON("a"), verts=6, bevel=0.002)


def wall_back(w, h, d=0.05, battens=None, z0=0.0):
	"""Vertical boards with a flat back at y = d, iron-riveted cross battens on the front."""
	n = max(2, round(w / 0.24))
	for i in range(n):
		B((w / n - 0.008, d, h + J(0.015)), (-w / 2 + w / n * (i + 0.5), d / 2, z0 + h / 2), W(), bevel=0.01)
	for z in (battens if battens is not None else (z0 + 0.07, z0 + h - 0.07)):
		B((w + 0.02, 0.03, 0.07), (0, -0.012, z), WD(), bevel=0.008)
		for x in (-w / 2 + 0.05, w / 2 - 0.05):
			rivet((x, -0.028, z), IRON("a"), r=0.011)


def peg(x, z, ln=0.1, r=0.014):
	"""A wooden wall peg sticking out toward -Y, rising a little, with a domed tip."""
	rod((x, 0.012, z), (x, -ln, z + 0.012), r, WD(), seg=7)
	sphere((x, -ln, z + 0.012), r * 1.3, WD(), seg=8, rings=5)


def shelf(w, z, depth=0.22, lip=True):
	"""A shelf board on two iron brackets against the wall front (y = 0). Returns the top height."""
	B((w, depth, 0.035), (0, -depth / 2, z), W(), bevel=0.01)
	for x in (-w / 2 + 0.09, w / 2 - 0.09):
		B((0.03, depth * 0.8, 0.012), (x, -depth * 0.4 + 0.003, z - 0.022), IRON("dark"), bevel=0.003)
		B((0.03, 0.012, 0.14), (x, -0.004, z - 0.085), IRON("dark"), bevel=0.003)
		beam((x, -0.01, z - 0.13), (x, -depth * 0.7, z - 0.025), 0.022, 0.01, IRON("dark"), bevel=0.002)
		for zz in (z - 0.05, z - 0.12):
			rivet((x, -0.012, zz), IRON("a"), r=0.009)
	if lip:
		B((w - 0.04, 0.016, 0.03), (0, -depth + 0.01, z + 0.03), WD(), bevel=0.004)
	return z + 0.0175


def bricks_face(a0, a1, fixed, z0, h, axis="x", t=0.06, stagger=0, sgn=-1):
	"""One face of brick courses: bricks run along `axis` from a0 to a1, their outer face at `fixed` (sgn = outward)."""
	rows = max(1, round(h / 0.1))
	rh = h / rows
	for r in range(rows):
		z = z0 + rh * (r + 0.5)
		x = a0 - (0.12 if (r + stagger) % 2 else 0.0)
		while x < a1:
			xa, xb = max(x, a0), min(x + 0.24, a1)
			if xb - xa > 0.05:
				m = OCH() if rng.random() < 0.13 else BRK()
				c = (xa + xb) / 2
				off = fixed - sgn * t / 2
				loc = (c, off, z) if axis == "x" else (off, c, z)
				size = (xb - xa - 0.01, t, rh - 0.012) if axis == "x" else (t, xb - xa - 0.01, rh - 0.012)
				B(size, loc, m, bevel=0.006)
			x += 0.24


def brick_pier(cx, cy, w, d, h, z0=0.0, cap=True):
	"""A brick pier: dark mortar core, brick courses on all four faces, a clay cap slab."""
	B((w - 0.05, d - 0.05, h - 0.004), (cx, cy, z0 + h / 2), MORTAR(), bevel=0)
	bricks_face(cx - w / 2 + 0.065, cx + w / 2 - 0.065, cy - d / 2, z0, h, "x", sgn=-1)
	bricks_face(cx - w / 2 + 0.065, cx + w / 2 - 0.065, cy + d / 2, z0, h, "x", sgn=1, stagger=1)
	bricks_face(cy - d / 2, cy + d / 2, cx - w / 2, z0, h, "y", sgn=-1, stagger=1)
	bricks_face(cy - d / 2, cy + d / 2, cx + w / 2, z0, h, "y", sgn=1)
	if cap:
		B((w + 0.05, d + 0.05, 0.06), (cx, cy, z0 + h + 0.025), CLAY(), bevel=0.012)
	return z0 + h + 0.055


def hammer_head(c, s=1.0, rot=(0, 0, 0)):
	"""A trip-hammer head: an iron block narrowing to its striking face, a helve eye with wedges, rivets."""
	def build():
		kit.taper(0.14 * s, 0.13 * s, 0.17 * s, 0.16 * s, 0.07 * s, (0, 0, 0), IRON("dark"), bevel=0.006)
		B((0.17 * s, 0.16 * s, 0.15 * s), (0, 0, 0.14 * s), IRON("dark"), bevel=0.01)
		B((0.1 * s, 0.17 * s, 0.035 * s), (0, 0, 0.215 * s), IRON("a"), bevel=0.005)
		B((0.16 * s, 0.13 * s, 0.025 * s), (0, 0, 0.012 * s - 0.004), IRON("a"), bevel=0.004)
		for x in (-0.06 * s, 0.06 * s):
			for y in (-0.081 * s, 0.081 * s):
				rivet((x, y, 0.17 * s), IRON("a"), r=0.012 * s)
	group(build, c, rot)


def open_box(cx, cy, z, w, d, h, m=None):
	"""An open wooden box: a floor board and four sides (the long sides overlap the short ones' ends)."""
	B((w - 0.012, d - 0.012, 0.02), (cx, cy, z + 0.01), WD(), bevel=0.004)
	for s_ in (-1, 1):
		B((w, 0.016, h), (cx, cy + s_ * (d / 2 - 0.008), z + h / 2 + 0.003), m or W("b"), bevel=0.004)
		B((0.016, d - 0.036, h - 0.006), (cx + s_ * (w / 2 - 0.008), cy, z + h / 2 + 0.003), m or W("b"), bevel=0.004)


def ingot(c, rotz=0.0, m=None, tilt=(0, 0)):
	"""A pig of iron (or copper): a narrow-topped bar with a cast lip."""
	def build():
		kit.taper(0.3, 0.12, 0.25, 0.085, 0.07, (0, 0, 0), m or IRON("a"), bevel=0.008)
	group(build, c, (tilt[0], tilt[1], rotz))


def splinters(p, ax, n=4, r=0.03):
	ax = Vector(ax).normalized()
	u = ax.orthogonal().normalized()
	v = ax.cross(u)
	for k in range(n):
		a = 2 * math.pi * k / n + J(0.4)
		c = Vector(p) + (u * math.cos(a) + v * math.sin(a)) * r * 0.5
		tip = c + ax * (0.05 + J(0.02)) + (u * math.cos(a) + v * math.sin(a)) * 0.006
		log(tuple(c - ax * 0.02), tuple(tip), 0.011, W("c"), seg=4, rings=1, ends=False, bend=0, r1=0.0015)


def mallet(c, rotz=0.0, lying=True):
	"""A millwright's wooden mallet with iron-ringed head, lying on its side (or standing on its head)."""
	def build():
		if lying:
			kit.cylinder(0.06, 0.17, (0, 0, 0.06), W("c"), rot=(0, 90, 0), verts=10, bevel=0.008)
			for s_ in (-1, 1):
				kit.ring(0.06, 0.006, (s_ * 0.07, 0, 0.06), IRON("dark"), rot=(0, 90, 0), seg=14)
			rod((0, -0.05, 0.06), (0, -0.36, 0.03), 0.017, WD(), seg=7)
		else:
			kit.cylinder(0.06, 0.17, (0, 0, 0.085), W("c"), verts=10, bevel=0.008)
			rod((0, 0, 0.16), (0, 0, 0.45), 0.017, WD(), seg=7)
	group(build, c, (0, 0, rotz))


def wedge(c, s=1.0, rot=(0, 0, 0), m=None):
	def build():
		kit.taper(0.04 * s, 0.05 * s, 0.006 * s, 0.05 * s, 0.11 * s, (0, 0, 0), m or IRON("a"), bevel=0.003)
	group(build, c, rot)


def tappet(c, rot=(0, 0, 0), s=1.0):
	"""A cam tappet: an oak block with an iron shoe on its tip and two pegs."""
	def build():
		B((0.08 * s, 0.07 * s, 0.22 * s), (0, 0, 0.11 * s), W("c"), bevel=0.008)
		B((0.09 * s, 0.08 * s, 0.035 * s), (0, 0, 0.21 * s), IRON("dark"), bevel=0.004)
		for z in (0.05 * s, 0.11 * s):
			sphere((0, -0.035 * s, z), 0.011 * s, WD(), scale=(1, 0.7, 1), seg=8, rings=5)
	group(build, c, rot)


def bucket(c, r=0.13, h=0.22, rot=(0, 0, 0)):
	"""A wooden pail of staves (one hollow shell) with two iron hoops and a bail handle."""
	def build():
		pot((0, 0, 0), r, h, W("b"), t=0.012, seg=16, flare=1.08, rim=False)
		for z in (0.04, h - 0.05):
			kit.ring(r * (1.0 + 0.08 * z / h) + 0.006, 0.007, (0, 0, z), IRON("dark"), seg=18)
		for k in range(8):
			a = 2 * math.pi * k / 8
			B((0.004, 0.006, h - 0.02), (math.cos(a) * (r + 0.006 * (1 + 0.5 * 0.5)), math.sin(a) * (r + 0.006), h / 2),
				GROOVE(), bevel=0, rot=(0, 0, math.degrees(a)))
		tube([(-r * 1.08, 0, h - 0.04), (-r * 0.7, 0, h + 0.1), (0, 0, h + 0.15), (r * 0.7, 0, h + 0.1), (r * 1.08, 0, h - 0.04)], 0.006, 0.006, IRON("dark"))
	group(build, c, rot)


def plate(c, w, d, t=0.012, rot=(0, 0, 0), m=None):
	return B((w, d, t), c, m or IRON(rng.choice(("a", "b", "c"))), bevel=0.003, rot=rot)


def coal_bed(cx, cy, z, r, n=30, hot=0.2, seed=1):
	"""Near-black glossy angular coal lumps, settled in a low mound, a few glowing."""
	rr = random.Random(seed)
	disc(r * 0.95, z - 0.03, z + 0.012, (cx, cy), COAL(), seg=16, wob=0.08)
	for k in range(n):
		a, d = rr.uniform(0, 6.28), r * math.sqrt(rr.uniform(0, 1))
		s = rr.uniform(0.025, 0.05)
		hz = z + 0.014 + (1 - d / r) * r * 0.3
		kit.gem((cx + math.cos(a) * d, cy + math.sin(a) * d, hz), (s, s * 0.85, s * 0.65), EMBER() if rr.random() < hot else COAL(), seed=k + seed)


def rail(p0, p1, z):
	"""An iron rail (foot, web, head) from p0 to p1 (x, y), foot bottom at z. Returns the rail top."""
	a, b = Vector((p0[0], p0[1], 0)), Vector((p1[0], p1[1], 0))
	for (w, h, zc, m) in ((0.06, 0.014, 0.007, IRON("dark")), (0.016, 0.04, 0.03, IRON("dark")), (0.036, 0.022, 0.058, IRON("a"))):
		beam(tuple(a + Vector((0, 0, z + zc))), tuple(b + Vector((0, 0, z + zc))), w, h, m, bevel=0.002)
	return z + 0.069


def track(x0, x1, gauge=0.5, n=5):
	"""A rail section along X: sleepers, two rails, iron spikes. Returns the rail top height."""
	for k in range(n):
		x = x0 + (x1 - x0) * (k + 0.5) / n
		B((0.14, gauge + 0.3, 0.07), (x + J(0.01), 0, 0.035), W() if k % 2 else WD(), bevel=0.01, rot=(0, 0, J(2)))
		for s_ in (-1, 1):
			for e in (-1, 1):
				kit.cylinder(0.011, 0.012, (x, s_ * gauge / 2 + e * 0.04, 0.072), IRON("dark"), verts=6, bevel=0.002)
	top = 0
	for s_ in (-1, 1):
		top = rail((x0, s_ * gauge / 2), (x1, s_ * gauge / 2), 0.066)
	return top


def wheel(c, r=0.11, axis="y", flip=False):
	"""A cast iron cart wheel with a flange (on the +Y side, or -Y when flip), spokes cast in, and a hub cap."""
	rot = ((-90 if flip else 90), 0, 0) if axis == "y" else (0, 90, 0)

	def build():
		kit.cylinder(r, 0.045, (0, 0, 0), IRON("dark"), verts=18, bevel=0.005)
		kit.cylinder(r * 1.15, 0.012, (0, 0, -0.02), IRON("dark"), verts=18, bevel=0.002)
		kit.cylinder(r * 0.35, 0.075, (0, 0, 0.0075), IRON("a"), verts=10, bevel=0.004)
		for k in range(6):
			a = 2 * math.pi * k / 6
			B((r * 0.55, 0.02, 0.012), (math.cos(a) * r * 0.55, math.sin(a) * r * 0.55, 0.026), IRON("a"), bevel=0.002, rot=(0, 0, math.degrees(a)))
	group(build, c, rot)


def lift_hook(c, s=1.0, rotz=0.0):
	"""A forged lifting hook with its eye at c (hook drawn in the XZ plane, opening to +X)."""
	def build():
		kit.ring(0.032 * s, 0.01 * s, (0, 0, 0.022 * s), IRON("dark"), rot=(90, 0, 0), seg=12)
		tube([(0, 0, -0.008 * s), (0, 0, -0.1 * s), (0.015 * s, 0, -0.18 * s), (0.06 * s, 0, -0.215 * s), (0.1 * s, 0, -0.19 * s),
			(0.115 * s, 0, -0.13 * s), (0.1 * s, 0, -0.1 * s)], 0.02 * s, 0.009 * s, IRON("dark"), seg=8)
	group(build, c, (0, 0, rotz))


def bell(c, s=1.0, m=None):
	"""A hollow cast bell (open mouth) with a crown loop and a clapper inside; c = mouth centre."""
	x, y, z = c
	outer = [(0.09, 0), (0.088, 0.012), (0.065, 0.04), (0.052, 0.09), (0.05, 0.13), (0.035, 0.155), (0.012, 0.165)]
	inner = [(0.006, 0.15), (0.03, 0.14), (0.042, 0.12), (0.045, 0.09), (0.057, 0.04), (0.078, 0.012), (0.082, 0.003)]
	lathe([(r * s, h * s) for r, h in outer + inner], (x, y, z), m or CU("dark"), seg=16, loop=True)
	kit.ring(0.02 * s, 0.006 * s, (x, y, z + 0.18 * s), IRON("dark"), rot=(90, 0, 0), seg=10)
	rod((x, y, z + 0.155 * s), (x, y, z + 0.035 * s), 0.005 * s, IRON("dark"), seg=5)
	sphere((x, y, z + 0.03 * s), 0.018 * s, IRON("dark"), seg=8, rings=6)


def hang_ring(x, y, pz, major, minor, m, pr=0.014):
	"""A ring hanging on a peg whose centre is at height pz (the ring's inner top rests on the peg)."""
	kit.ring(major, minor, (x, y, pz + pr - major + minor + 0.004), m, rot=(90, 0, 0), seg=18)


# =====================================================================================================
# WALL PIECES
# =====================================================================================================
def hw_gear_wall():
	wall_back(1.5, 1.4, battens=(0.12, 0.75, 1.32))
	peg(-0.38, 0.86, ln=0.17, r=0.02)
	cog_wheel((-0.38, -0.095, 0.86), 0.36, 0.08, n=14, rot=(90, 0, 0))
	peg(0.42, 1.0, ln=0.14, r=0.018)
	cog_wheel((0.42, -0.07, 1.0), 0.2, 0.06, n=10, rot=(90, 0, 0), felloes=4)
	top = shelf(1.36, 0.33, depth=0.26)
	pinion((0.3, -0.13, top + 0.125), 0.07, 0.16, n=8)
	for k in range(6):  # spare cogs laid out in a neat row
		x = -0.62 + k * 0.085
		B((0.06, 0.14, 0.045), (x, -0.12, top + 0.02), W("c") if k % 2 else WD(), bevel=0.008)
		sphere((x, -0.19, top + 0.02), 0.013, WD(), scale=(1, 0.6, 1), seg=8, rings=5)
	# an open box of iron wedges
	bx, by = 0.56, -0.12
	open_box(bx, by, top - 0.002, 0.18, 0.16, 0.08)
	for k in range(6):
		wedge((bx - 0.05 + (k % 3) * 0.05, by - 0.035 + (k // 3) * 0.07, top + 0.016), 0.9, rot=(J(8), J(8), 90 + J(15)))
	# iron collars hanging on a low peg, a coil of iron strap on another
	peg(-0.42, 0.24, ln=0.14)
	for k, (mj, yy) in enumerate(((0.09, -0.05), (0.075, -0.08), (0.065, -0.11))):
		hang_ring(-0.42, yy, 0.24 + 0.012 * (abs(yy) / 0.14), mj, 0.014, IRON("dark" if k % 2 else "a"))
	peg(0.05, 0.24, ln=0.12)
	for k in range(3):
		hang_ring(0.05 + J(0.004), -0.05 - k * 0.022, 0.248, 0.1 - k * 0.006, 0.008, IRON("a"))


def hw_parts_rack():
	Wd, H = 1.3, 1.6
	wall_back(Wd, H, battens=())
	for x in (-Wd / 2 + 0.03, Wd / 2 - 0.03):
		B((0.06, 0.355, H), (x, -0.1325, H / 2), WD(), bevel=0.01)
	B((Wd + 0.08, 0.4, 0.05), (0, -0.14, H + 0.02), W("b"), bevel=0.012)
	tops = []
	for z in (0.06, 0.5, 0.95, 1.38):
		B((Wd - 0.08, 0.33, 0.035), (0, -0.13, z), W(), bevel=0.008)
		B((Wd - 0.1, 0.018, 0.035), (0, -0.29, z + 0.03), WD(), bevel=0.004)
		for x in (-Wd / 2 + 0.03, Wd / 2 - 0.03):
			rivet((x, -0.31, z), IRON("a"), r=0.012)
		tops.append(z + 0.0175)
	# floor shelf: a spare shaft length on chocks, iron bands next to it
	t0 = tops[0]
	for x in (-0.4, 0.05):
		B((0.08, 0.2, 0.05), (x, -0.13, t0 + 0.022), WD(), bevel=0.006)
	shaft((-0.55, -0.13, t0 + 0.12), (0.2, -0.13, t0 + 0.12), 0.075, bands=(0.1, 0.9))
	for k in range(3):
		kit.ring(0.09 - k * 0.012, 0.012, (0.42, -0.14, t0 + 0.012 + k * 0.024), IRON("dark" if k % 2 else "a"), seg=18)
	# second shelf: a row of cam tappets, stacks of collars
	t1 = tops[1]
	for k in range(6):
		tappet((-0.52 + k * 0.09, -0.13, t1 - 0.003), rot=(0, 0, J(4)), s=0.85)
	for x in (0.18, 0.4):
		for k in range(3):
			kit.ring(0.07, 0.016, (x, -0.13, t1 + 0.012 + k * 0.03), IRON("a" if k % 2 else "dark"), seg=16)
	# third shelf: two spare bearing blocks and a row of wedges
	t2 = tops[2]
	for x in (-0.38, -0.08):
		B((0.24, 0.13, 0.1), (x, -0.13, t2 + 0.048), W("b"), bevel=0.01)
		kit.cylinder(0.055, 0.14, (x, -0.13, t2 + 0.1), IRON("dark"), rot=(90, 0, 0), verts=12, bevel=0.004)
		B((0.16, 0.12, 0.03), (x, -0.13, t2 + 0.1), MORTAR(), bevel=0)
		for s_ in (-1, 1):
			kit.cylinder(0.022, 0.03, (x + s_ * 0.09, -0.13, t2 + 0.108), IRON("a"), verts=6, bevel=0.002)
	for k in range(7):
		wedge((0.14 + k * 0.06, -0.13, t2 - 0.002), 1.0, rot=(0, 0, 90))
	# top shelf: a box of bolts, a bundle of flat iron straps, a small pinion
	t3 = tops[3]
	bx = -0.38
	open_box(bx, -0.13, t3 - 0.002, 0.26, 0.2, 0.09, W("c"))
	for k in range(12):
		x, y = bx - 0.09 + (k % 4) * 0.06, -0.19 + (k // 4) * 0.06
		kit.cylinder(0.018, 0.016, (x, y, t3 + 0.075), IRON("a"), verts=6, bevel=0.002)
		kit.cylinder(0.008, 0.06, (x, y, t3 + 0.045), IRON("dark"), verts=6, bevel=0)
	for k in range(5):
		B((0.42, 0.05, 0.012), (0.05, -0.13, t3 + 0.005 + k * 0.0125), IRON("abc"[k % 3]), bevel=0.002, rot=(0, 0, J(3)))
	for s_ in (-1, 1):
		B((0.03, 0.065, 0.075), (0.05 + s_ * 0.15, -0.13, t3 + 0.035), ROPE(), bevel=0.006)
	pinion((0.42, -0.13, t3 + 0.115), 0.055, 0.12, n=7)


def hw_hammer_head_rack():
	wall_back(1.4, 1.1, battens=(0.07, 1.03))
	for z in (0.35, 0.8):
		B((1.4, 0.14, 0.16), (0, -0.065, z), W("b") if z < 0.5 else W("a"), bevel=0.014)
		for x in (-0.6, 0.0, 0.6):
			B((0.04, 0.012, 0.2), (x, -0.139, z - 0.02), IRON("dark"), bevel=0.003)
			B((0.04, 0.14, 0.012), (x, -0.07, z - 0.085), IRON("dark"), bevel=0.003)
			for zz in (z + 0.04, z - 0.07):
				rivet((x, -0.147, zz), IRON("a"), r=0.01)
	hammer_head((-0.35, -0.07, 0.426), 1.0)
	hammer_head((0.22, -0.07, 0.426), 0.88)
	hammer_head((-0.3, -0.07, 0.876), 1.12)
	for k in range(6):
		wedge((0.1 + k * 0.075, -0.07, 0.876), 1.1, rot=(0, 0, 90))
	# helve hoops on a peg at the end of the top beam
	rod((0.6, -0.135, 0.8), (0.6, -0.25, 0.81), 0.016, WD(), seg=7)
	for k, (mj, y) in enumerate(((0.1, -0.165), (0.085, -0.2))):
		kit.ring(mj, 0.012, (0.6, y, 0.8 + 0.016 - mj + 0.012 + 0.004), IRON("a" if k else "dark"), rot=(90, 0, 0), seg=18)
	# a long iron pry bar resting on two pegs under the low beam
	for x in (-0.45, 0.45):
		peg(x, 0.16, ln=0.1)
	rod((-0.62, -0.06, 0.198), (0.6, -0.06, 0.198), 0.016, IRON("dark"), seg=8)
	tube([(0.6, -0.06, 0.198), (0.66, -0.06, 0.2), (0.7, -0.06, 0.23)], 0.016, 0.006, IRON("dark"))


def hw_tool_board():
	wall_back(1.2, 1.0, battens=(0.07, 0.93))
	# adze hanging from a peg by its head
	peg(-0.42, 0.8)
	rod((-0.42, -0.06, 0.83), (-0.43, -0.06, 0.36), 0.017, W("c"), seg=7)
	B((0.06, 0.04, 0.06), (-0.42, -0.06, 0.84), IRON("dark"), bevel=0.005)
	beam((-0.39, -0.06, 0.84), (-0.27, -0.06, 0.79), 0.05, 0.012, IRON("a"), bevel=0.003)
	# mallet hanging head-down between two pegs
	for dx in (-0.06, 0.06):
		peg(-0.15 + dx, 0.5)
	kit.cylinder(0.06, 0.2, (-0.15, -0.06, 0.585), W("c"), rot=(0, 90, 0), verts=10, bevel=0.008)
	for s_ in (-1, 1):
		kit.ring(0.06, 0.006, (-0.15 + s_ * 0.085, -0.06, 0.585), IRON("dark"), rot=(0, 90, 0), seg=14)
	rod((-0.15, -0.06, 0.64), (-0.15, -0.06, 0.88), 0.017, WD(), seg=7)
	# T-auger on two pegs: wooden cross handle, iron shank with a spiral, pointed tip
	for dx in (-0.09, 0.09):
		peg(0.17 + dx, 0.78)
	rod((0.0, -0.06, 0.815), (0.34, -0.06, 0.815), 0.02, W("b"), seg=8)
	rod((0.17, -0.06, 0.8), (0.17, -0.06, 0.3), 0.011, IRON("dark"), seg=6)
	for k in range(9):
		kit.ring(0.017, 0.005, (0.17, -0.06, 0.32 + k * 0.022), IRON("a"), rot=(18, 0, k * 40), seg=10)
	kit.cone(0.012, 0.0, 0.04, (0.17, -0.06, 0.29), IRON("a"), rot=(180, 0, 0), verts=6, bevel=0)
	# a chisel strip with three chisels
	B((0.3, 0.075, 0.04), (0.42, -0.035, 0.68), W("a"), bevel=0.006)
	for k, ln in enumerate((0.16, 0.13, 0.15)):
		x = 0.33 + k * 0.09
		B((0.022 - k * 0.004, 0.01, ln), (x, -0.045, 0.66 - ln / 2 + 0.03), IRON("a"), bevel=0.002)
		kit.cylinder(0.017, 0.1, (x, -0.045, 0.75), W("c") if k % 2 else WD(), verts=8, bevel=0.004)
		kit.cylinder(0.019, 0.012, (x, -0.045, 0.705), IRON("dark"), verts=8, bevel=0.002)
	# iron dividers hanging on a peg
	peg(0.43, 0.46)
	kit.cylinder(0.028, 0.02, (0.43, -0.07, 0.448), IRON("a"), rot=(90, 0, 0), verts=10, bevel=0.003)
	for s_ in (-1, 1):
		tube([(0.43, -0.07, 0.44), (0.43 + s_ * 0.04, -0.07, 0.3), (0.43 + s_ * 0.06, -0.07, 0.19)], 0.008, 0.002, IRON("dark"))
	# a wooden try square on a peg
	peg(-0.12, 0.3)
	B((0.03, 0.022, 0.3), (-0.12, -0.06, 0.2), W("b"), bevel=0.004)
	B((0.2, 0.01, 0.025), (-0.03, -0.06, 0.07 + 0.0125 + 0.02), IRON("a"), bevel=0.002)
	for z in (0.11, 0.24):
		rivet((-0.12, -0.072, z), CU("dark"), r=0.007)
	# a coil of rope on a peg at the bottom left
	peg(-0.42, 0.3)
	for k in range(4):
		hang_ring(-0.42 + J(0.006), -0.045 - k * 0.022, 0.3, 0.11 + J(0.006), 0.014, ROPE())
	# an iron drift and a spanner-like key on pegs at the bottom right
	peg(0.2, 0.2)
	tube([(0.2, -0.06, 0.225), (0.2, -0.06, 0.17), (0.2, -0.06, 0.1)], 0.014, 0.008, IRON("dark"))
	kit.ring(0.022, 0.008, (0.2, -0.06, 0.235), IRON("dark"), rot=(90, 0, 0), seg=10)
	peg(0.0, 0.2)
	beam((0.0, -0.06, 0.205), (0.0, -0.06, 0.08), 0.03, 0.012, IRON("dark"), bevel=0.003)
	kit.ring(0.032, 0.01, (0.0, -0.06, 0.065), IRON("dark"), rot=(90, 0, 0), seg=10)


def hw_belt_pulley_wall():
	wall_back(0.82, 1.6, battens=(0.1, 0.9, 1.5))
	for x in (-0.22, 0.22):
		B((0.05, 0.014, 0.42), (x, -0.004, 1.08), IRON("dark"), bevel=0.003)
		beam((x, -0.005, 1.25), (x, -0.35, 1.25), 0.05, 0.03, IRON("dark"), bevel=0.003)
		beam((x, -0.01, 0.91), (x, -0.3, 1.24), 0.04, 0.025, IRON("dark"), bevel=0.003)
		for z in (0.92, 1.05, 1.22):
			rivet((x, -0.013, z), IRON("a"), r=0.011)
		kit.cylinder(0.05, 0.04, (x, -0.3, 1.3), IRON("dark"), rot=(0, 90, 0), verts=14, bevel=0.004)
	rod((-0.29, -0.3, 1.3), (0.29, -0.3, 1.3), 0.03, IRON("a"), seg=10)
	kit.cylinder(0.16, 0.28, (0, -0.3, 1.3), W("b"), rot=(0, 90, 0), verts=20, bevel=0.01)
	for s_ in (-1, 1):
		kit.cylinder(0.168, 0.016, (s_ * 0.145, -0.3, 1.3), IRON("dark"), rot=(0, 90, 0), verts=20, bevel=0.003)
		for k in range(4):
			a = math.pi / 2 * k + 0.4
			rivet((s_ * 0.155, -0.3 + math.cos(a) * 0.12, 1.3 + math.sin(a) * 0.12), IRON("a"), r=0.01)
	# the rope belt: over the drum, down round the weighted pulley, back up
	R1, R2, yc, z1, z2 = 0.175, 0.095, -0.3, 1.3, 0.5
	pts = [(0, yc + R1 * math.cos(math.radians(a)), z1 + R1 * math.sin(math.radians(a))) for a in range(0, 181, 15)]
	pts += [(0, yc + R2 * math.cos(math.radians(a)), z2 + R2 * math.sin(math.radians(a))) for a in range(180, 361, 15)]
	pts.append(pts[0])
	tube(pts, 0.014, 0.014, ROPE(), seg=8)
	# the tension pulley in an iron fork with the clay weight below
	kit.cylinder(0.08, 0.05, (0, yc, z2), W("c"), rot=(0, 90, 0), verts=16, bevel=0.006)
	for s_ in (-1, 1):
		B((0.012, 0.05, 0.2), (s_ * 0.037, yc, z2 - 0.06), IRON("dark"), bevel=0.003)
	rod((-0.05, yc, z2), (0.05, yc, z2), 0.012, IRON("a"), seg=6)
	B((0.086, 0.05, 0.02), (0, yc, z2 - 0.155), IRON("dark"), bevel=0.003)
	kit.ring(0.03, 0.009, (0, yc, z2 - 0.19), IRON("dark"), rot=(90, 0, 0), seg=12)
	kit.taper(0.2, 0.16, 0.13, 0.11, 0.18, (0, yc, z2 - 0.4), CLAY(), bevel=0.012)
	kit.ring(0.03, 0.009, (0, yc, z2 - 0.215), IRON("dark"), rot=(0, 0, 0), seg=12)
	rod((0, yc, z2 - 0.24), (0, yc, z2 - 0.215), 0.01, IRON("dark"))
	B((0.21, 0.17, 0.03), (0, yc, z2 - 0.4), IRON("dark"), bevel=0.004)
	# spare rope and a leather strap coil on pegs
	for x, m, mj in ((0.28, ROPE(), 0.1), (-0.28, LEATHER(), 0.085)):
		peg(x, 0.75, ln=0.12)
		for k in range(3):
			hang_ring(x + J(0.006), -0.045 - k * 0.022, 0.75, mj + J(0.006), 0.013, m)


def hw_chain_hook_wall():
	wall_back(1.3, 1.2, battens=(0.07, 0.6))
	B((1.26, 0.1, 0.12), (0, -0.045, 1.0), W("b"), bevel=0.012)
	for x in (-0.55, 0.55):
		B((0.04, 0.012, 0.16), (x, -0.099, 1.0), IRON("dark"), bevel=0.003)
		rivet((x, -0.107, 1.03), IRON("a"), r=0.01)

	def rail_hook(x):
		B((0.05, 0.05, 0.02), (x, -0.06, 0.936), IRON("dark"), bevel=0.003)
		tube([(x, -0.06, 0.94), (x, -0.06, 0.88), (x, -0.075, 0.855), (x, -0.11, 0.855), (x, -0.13, 0.88)], 0.012, 0.008, IRON("dark"))
		return (x, -0.08, 0.862)

	# a short chain down to a big lifting hook
	hx, hy, hz = rail_hook(-0.5)
	chain((hx, hy, hz - 0.01), (hx, hy, 0.62), link=0.035, wire=0.009)
	lift_hook((hx, hy, 0.58), 1.4)
	# hanging chain loops
	hx, hy, hz = rail_hook(-0.2)
	for k, (dz, dx) in enumerate(((0.55, 0.06), (0.42, 0.045), (0.3, 0.03))):
		yy = hy - k * 0.024
		chain((hx - 0.012, yy, hz - 0.01), (hx - dx, yy, hz - dz), link=0.03, wire=0.008)
		chain((hx + 0.012, yy, hz - 0.01), (hx + dx, yy, hz - dz), link=0.03, wire=0.008)
		chain((hx - dx + 0.035, yy, hz - dz - 0.045), (hx + dx - 0.035, yy, hz - dz - 0.045), link=0.03, wire=0.008)
	# a pulley block: iron cheeks, a wooden sheave, a hook below
	hx, hy, hz = rail_hook(0.12)
	kit.ring(0.03, 0.009, (hx, hy, hz - 0.012), IRON("dark"), rot=(90, 0, 0), seg=12)
	for s_ in (-1, 1):
		B((0.13, 0.012, 0.2), (hx, hy + s_ * 0.03, hz - 0.14), IRON("dark"), bevel=0.004)
	kit.cylinder(0.055, 0.04, (hx, hy, hz - 0.14), W("c"), rot=(90, 0, 0), verts=14, bevel=0.005)
	rod((hx, hy - 0.045, hz - 0.14), (hx, hy + 0.045, hz - 0.14), 0.012, IRON("a"))
	B((0.05, 0.072, 0.02), (hx, hy, hz - 0.045), IRON("dark"), bevel=0.003)
	B((0.05, 0.072, 0.02), (hx, hy, hz - 0.235), IRON("dark"), bevel=0.003)
	lift_hook((hx, hy, hz - 0.27), 0.9)
	# shackles on a hook
	hx, hy, hz = rail_hook(0.38)
	for k in range(3):
		x = hx + (k - 1) * 0.025
		y = hy - 0.012 * k
		tube([(x - 0.03, y, hz + 0.0), (x - 0.03, y, hz - 0.08), (x - 0.015, y, hz - 0.11), (x + 0.015, y, hz - 0.11), (x + 0.03, y, hz - 0.08),
			(x + 0.03, y, hz + 0.0)], 0.009, 0.009, IRON("dark" if k % 2 else "a"))
		rod((x - 0.045, y, hz + 0.004), (x + 0.045, y, hz + 0.004), 0.009, IRON("a"))
	# a second, lighter chain and hook
	hx, hy, hz = rail_hook(0.58)
	chain((hx, hy, hz - 0.01), (hx, hy, 0.5), link=0.028, wire=0.007)
	lift_hook((hx, hy, 0.465), 1.0, rotz=180)


def hw_signal_lever_wall():
	wall_back(1.2, 1.5, battens=(0.07, 0.72))
	B((1.12, 0.2, 0.1), (0, -0.095, 1.38), W("b"), bevel=0.012)
	for x in (-0.5, 0.5):
		B((0.04, 0.012, 0.24), (x, -0.004, 1.22), IRON("dark"), bevel=0.003)
		beam((x, -0.01, 1.12), (x, -0.17, 1.335), 0.035, 0.02, IRON("dark"), bevel=0.003)
		for z in (1.15, 1.25):
			rivet((x, -0.012, z), IRON("a"), r=0.01)
	# the lever block with iron slot plates
	B((0.9, 0.24, 0.16), (0, -0.115, 0.42), W("a"), bevel=0.012)
	for x in (-0.4, 0.4):
		B((0.05, 0.012, 0.2), (x, -0.237, 0.42), IRON("dark"), bevel=0.003)
		rivet((x, -0.245, 0.46), IRON("a"), r=0.011)
	for i, (x, a) in enumerate(((-0.3, -8), (0.0, -6), (0.3, 34))):
		for s_ in (-1, 1):
			B((0.012, 0.2, 0.13), (x + s_ * 0.03, -0.12, 0.555), IRON("dark"), bevel=0.003)
		rod((x - 0.045, -0.12, 0.56), (x + 0.045, -0.12, 0.56), 0.011, IRON("a"))
		L = 0.5
		ar = math.radians(a)
		d = Vector((0, -math.sin(ar), math.cos(ar)))
		p0 = Vector((x, -0.12, 0.56))
		rod(tuple(p0 - d * 0.04), tuple(p0 + d * L), 0.013, IRON("dark"), seg=8)
		rod(tuple(p0 + d * (L - 0.12)), tuple(p0 + d * (L + 0.03)), 0.022, W("c"), seg=8)
		B((0.03, 0.03, 0.04), tuple(p0 + d * 0.2), IRON("a"), bevel=0.004, rot=(-a, 0, 0))
		# the pull wire up to a bell crank under the beam, and on to the bell
		wp = p0 + d * 0.33
		cx = x
		B((0.07, 0.012, 0.07), (cx, -0.16, 1.3), IRON("dark"), bevel=0.003, rot=(0, 45, 0))
		B((0.02, 0.05, 0.03), (cx, -0.155, 1.33), IRON("dark"), bevel=0.003)
		rivet((cx, -0.168, 1.3), IRON("a"), r=0.009)
		rod(tuple(wp + Vector((0, 0, 0.0))), (cx - 0.02, -0.16, 1.275), 0.004, IRON("dark"), seg=5)
		s = 0.95 - 0.1 * i
		bx = x + 0.13
		B((0.03, 0.012, 0.07), (bx, -0.12, 1.3), IRON("dark"), bevel=0.003)
		bell((bx, -0.12, 1.275 - 0.2 * s), s)
		rod((cx + 0.025, -0.16, 1.305), (bx - 0.02, -0.13, 1.27), 0.004, IRON("dark"), seg=5)
	# the lever numbers, cut into a board: one, two and three notches
	nb = B((0.9, 0.03, 0.12), (0, -0.013, 0.98), W("b"), bevel=0.008)
	cut_ = []
	for i, x in enumerate((-0.3, 0.0, 0.3)):
		for k in range(i + 1):
			xa = x + (k - i / 2) * 0.035
			cut_ += groove((xa, 0.94), (xa, 1.02), -0.028, w=0.013, depth=0.01)
	carve(nb, cut_)
	for x in (-0.42, 0.42):
		rivet((x, -0.029, 0.98), CU("dark"), r=0.01)


def tally(tab, x0, z0, n, y, per_row=3):
	"""Cut n tally marks (groups of four strokes and a slash) into a tablet's front face at y."""
	ups, slashes = [], []
	for k in range(n):
		g, j = divmod(k, 5)
		gx = x0 + (g % per_row) * 0.075
		gz = z0 - (g // per_row) * 0.075
		if j < 4:
			ups += groove((gx + j * 0.014, gz - 0.025), (gx + j * 0.014, gz + 0.025), y, w=0.007, depth=0.007)
		else:
			slashes += groove((gx - 0.01, gz - 0.02), (gx + 0.052, gz + 0.02), y, w=0.007, depth=0.007)
	carve(tab, ups)
	if slashes:
		carve(tab, slashes)


def hw_shift_board():
	wall_back(1.1, 1.0, battens=(0.05, 0.95))
	for i, (x, n) in enumerate(((-0.34, 13), (0.0, 7), (0.34, 19))):
		tab = B((0.26, 0.035, 0.3), (x, -0.016, 0.68), CLAY(), bevel=0.01)
		tally(tab, x - 0.09, 0.71, n, -0.0335)
		carve(tab, groove((x - 0.03, 0.8), (x + 0.03, 0.8), -0.0335, w=0.012, depth=0.008))  # a hammer mark: the head
		carve(tab, groove((x, 0.795), (x, 0.755), -0.0335, w=0.009, depth=0.008))  # and its handle
		for s_ in (-1, 1):
			rivet((x + s_ * 0.11, -0.034, 0.81), CU("dark"), r=0.01)
	# the hammer-token rail: copper tokens on iron hooks, two hooks empty
	B((0.68, 0.05, 0.05), (-0.16, -0.022, 0.32), WD(), bevel=0.006)
	for k in range(6):
		x = -0.44 + k * 0.112
		tube([(x, -0.04, 0.31), (x, -0.075, 0.302), (x, -0.09, 0.318)], 0.006, 0.005, IRON("dark"))
		if k in (2, 5):
			continue
		kit.ring(0.011, 0.003, (x, -0.075, 0.293), CU("dark"), rot=(0, 90, 0), seg=10)
		tok = kit.cylinder(0.034, 0.009, (x, -0.075, 0.25), CU("b" if k % 2 else "a"), rot=(90, 0, 0), verts=14, bevel=0.002)
		carve(tok, groove((x - 0.012 * (k % 3), 0.25), (x + 0.012, 0.25), -0.0795, w=0.006, depth=0.003))
	# a small shelf with the shift hourglass
	B((0.28, 0.15, 0.03), (0.38, -0.075, 0.35), W("b"), bevel=0.006)
	for x in (0.29, 0.47):
		B((0.025, 0.11, 0.06), (x, -0.055, 0.31), IRON("dark"), bevel=0.003)
	hx, hy, hz = 0.38, -0.08, 0.365
	for z in (hz + 0.009, hz + 0.16):
		kit.cylinder(0.055, 0.018, (hx, hy, z), W("c"), verts=12, bevel=0.004)
	for k in range(3):
		a = 2 * math.pi * k / 3 + 0.3
		rod((hx + math.cos(a) * 0.045, hy + math.sin(a) * 0.045, hz + 0.012), (hx + math.cos(a) * 0.045, hy + math.sin(a) * 0.045, hz + 0.158), 0.006, WD())
	lathe([(0.03, 0.0), (0.036, 0.03), (0.006, 0.07), (0.036, 0.11), (0.03, 0.142)], (hx, hy, hz + 0.009), GLASS(), seg=12)
	lathe([(0.028, 0.003), (0.031, 0.022), (0.016, 0.035), (0.002, 0.042)], (hx, hy, hz + 0.009), SAND(), seg=10)
	lathe([(0.006, 0.07), (0.022, 0.09), (0.02, 0.1), (0.002, 0.103)], (hx, hy, hz + 0.009), SAND(), seg=10)


def hw_grease_shelf():
	wall_back(1.1, 1.0, battens=(0.05, 0.95))
	t1 = shelf(1.0, 0.32)
	t2 = shelf(1.0, 0.68)
	for i, (x, r, h) in enumerate(((-0.36, 0.08, 0.17), (-0.14, 0.07, 0.14), (0.07, 0.085, 0.15))):
		y = -0.11
		pot((x, y, t2 - 0.002), r, h, CLAY(), t=0.009, seg=14)
		disc(r * 1.0, t2 + h * 0.62 - 0.01, t2 + h * 0.62, (x, y), GREASE(), seg=14, wob=0.02)
		rod((x - 0.01, y + 0.01, t2 + h * 0.5), (x + 0.04, y - 0.03, t2 + h + 0.13), 0.009, W("c"), seg=6)
		B((0.04, 0.008, 0.06), (x - 0.008, y + 0.012, t2 + h * 0.62 - 0.005), W("c"), bevel=0.002)
	for k in range(3):
		B((0.12, 0.08, 0.05), (0.33 + J(0.01), -0.11, t2 + 0.023 + k * 0.05), TALLOW(), bevel=0.012, rot=(0, 0, J(8) + k * 9))
	# lower shelf: copper oil can, grease brush, a pail of grease
	S = 1.0
	x, y, z = -0.36, -0.11, t1 - 0.002
	lathe([(0.05, 0), (0.056, 0.008), (0.056, 0.07), (0.04, 0.095), (0.014, 0.11), (0.014, 0.125)], (x, y, z), CU(), seg=12)
	kit.ring(0.056, 0.004, (x, y, z + 0.035), CU("dark"), seg=14)
	rod((x + 0.04, y, z + 0.04), (x + 0.12, y, z + 0.13), 0.007, CU("dark"), seg=6)
	kit.ring(0.03, 0.006, (x - 0.05, y, z + 0.065), CU("dark"), rot=(90, 0, 0), seg=12)
	kit.cylinder(0.017, 0.014, (x, y, z + 0.128), WD(), verts=8, bevel=0.002)
	rod((-0.2, -0.1, t1 + 0.015), (0.0, -0.14, t1 + 0.015), 0.013, W("b"), seg=7)
	B((0.07, 0.06, 0.04), (0.03, -0.146, t1 + 0.022), WD(), bevel=0.006, rot=(0, 0, -11))
	for k in range(10):
		B((0.008, 0.008, 0.028), (0.01 + (k % 5) * 0.012, -0.165 + (k // 5) * 0.03, t1 + 0.004), C((0.1, 0.07, 0.04), 0.9), bevel=0, rot=(0, 0, -11))
	bucket((0.28, -0.11, t1 - 0.002), 0.09, 0.15)
	disc(0.095, t1 + 0.1, t1 + 0.108, (0.28, -0.11), GREASE(), seg=16, wob=0.02)
	# under the shelf: a long-handled grease ladle and a scraper on pegs
	peg(-0.3, 0.24)
	tube([(-0.3, -0.06, 0.29), (-0.3, -0.09, 0.27), (-0.3, -0.07, 0.24), (-0.3, -0.06, 0.08)], 0.007, 0.007, IRON("dark"))
	pot((-0.3, -0.06, 0.03), 0.045, 0.05, CU("dark"), t=0.005, seg=12, rim=False)
	peg(0.2, 0.24)
	kit.ring(0.018, 0.005, (0.2, -0.06, 0.25), IRON("dark"), rot=(90, 0, 0), seg=10)
	rod((0.2, -0.06, 0.235), (0.2, -0.06, 0.12), 0.016, W("b"), seg=7)
	B((0.09, 0.012, 0.07), (0.2, -0.06, 0.09), IRON("a"), bevel=0.003)



# =====================================================================================================
# MACHINES AND WORKS
# =====================================================================================================
def stump(cx, cy, h, r, bands=(0.12, 0.8)):
	"""A standing log block (anvil stock): flat on the floor, a chopped end cap on top, iron bands."""
	log((cx, cy, 0.0), (cx, cy, h), r, W(), seg=12, rings=3, ends=False, bend=0.02, r1=r * 0.95)
	log((cx, cy, h - 0.006), (cx, cy, h + 0.008), r * 0.85, W("c"), seg=12, rings=1, ends=False, bend=0)
	for f in bands:
		rr = r + (r * 0.95 - r) * f
		rod((cx, cy, h * f - 0.022), (cx, cy, h * f + 0.022), rr * 1.1, IRON("dark"), seg=14)
	return h + 0.008


def trip_hammer(jammed=False):
	X0, X1 = -1.15, 1.42
	for y in (-0.32, 0.32):  # sills
		B((X1 - X0, 0.16, 0.16), ((X0 + X1) / 2, y, 0.08), W("b"), bevel=0.014)
	for x in (-1.08, 0.3, 1.22):  # cross ties, through-tenoned with pegs
		B((0.16, 0.86, 0.12), (x, 0, 0.07), W("a"), bevel=0.012)
		for y in (-0.41, 0.41):
			sphere((x, y, 0.1), 0.014, WD(), seg=8, rings=5)
	# the anvil on its banded stock
	top = stump(-0.85, 0.0, 0.45, 0.22)
	B((0.32, 0.25, 0.16), (-0.85, 0.0, top + 0.075), IRON("dark"), bevel=0.012)
	B((0.34, 0.27, 0.03), (-0.85, 0.0, top + 0.01), IRON("dark"), bevel=0.006)
	for x in (-0.97, -0.73):
		for y in (-0.13, 0.13):
			kit.cylinder(0.014, 0.08, (x, y, top + 0.01), IRON("a"), verts=6, bevel=0.002)
	at = top + 0.155
	if not jammed:
		plate((-0.85, 0.0, at + 0.004), 0.24, 0.2, 0.01, rot=(0, 0, 8))
	# the hurst: two posts, cap beam, braces, iron trunnion
	PX, PZ = 0.3, 0.82
	for y in (-0.2, 0.2):
		B((0.16, 0.16, 1.1), (PX, y, 0.13 + 0.55), W(), bevel=0.014)
		for dx in (-1, 1):
			beam((PX + dx * 0.5, y * 1.35, 0.15), (PX + dx * 0.06, y * 1.1, 0.62), 0.1, 0.09, W("c"))
		B((0.17, 0.012, 0.06), (PX, y - 0.081 if y < 0 else y + 0.081, PZ), IRON("dark"), bevel=0.003)
	B((0.22, 0.62, 0.14), (PX, 0, 1.25), W("b"), bevel=0.014)
	for y in (-0.2, 0.2):
		for x in (PX - 0.05, PX + 0.05):
			sphere((x, y, 1.322), 0.014, WD(), seg=8, rings=5)
	rod((PX, -0.33, PZ), (PX, 0.33, PZ), 0.035, IRON("a"), seg=10)
	for y in (-0.31, 0.31):
		kit.cylinder(0.06, 0.03, (PX, y, PZ), IRON("dark"), rot=(90, 0, 0), verts=8, bevel=0.003)
	# the helve and head (turned about the trunnion: a jam leaves the head up)
	ang = 6.0 if jammed else 0.0

	def helve():
		beam((-1.28, 0, 0.02), (0.78, 0, -0.04), 0.15, 0.17, W("a"))
		for x in (-1.0, -0.77, -0.45, -0.15, 0.15, 0.45):
			B((0.045, 0.17, 0.19), (x, 0, 0.02 - 0.06 * (x + 1.28) / 2.06), IRON("dark"), bevel=0.004)
			rivet((x, -0.087, 0.03 - 0.06 * (x + 1.28) / 2.06), IRON("a"), r=0.01)
		kit.cylinder(0.075, 0.18, (0, 0, 0), IRON("dark"), rot=(90, 0, 0), verts=12, bevel=0.004)
		hammer_head((-1.15, 0, 0.0 - 0.06 * 0.13 / 2.06 - 0.245), 1.12)
		for y in (-0.1, 0.1):
			wedge((-1.15, y, 0.1), 0.8, rot=(0, 0, 0))
	group(helve, at=(PX, 0, PZ), rot=(0, ang, 0))
	# tail top end in the world (for the cam): helve end at x' = 0.74, top = +0.085
	a = math.radians(ang)
	lx, lz = 0.72, -0.04 + 0.085
	tx, tz = PX + lx * math.cos(a) + lz * math.sin(a), PZ - lx * math.sin(a) + lz * math.cos(a)
	# the cam shaft in bearing posts, with a banded collar and four tappets
	CX, CZ = 1.24, 0.6
	for y in (-0.32, 0.32):
		B((0.16, 0.16, 0.34), (CX, y, 0.15 + 0.17), W(), bevel=0.012)
		bearing((CX, y, CZ), "y", 0.1, w=0.2)
	shaft((CX, -0.55, CZ), (CX, 0.95, CZ), 0.1, bands=(0.1, 0.38, 0.56, 0.9))
	kit.cylinder(0.15, 0.2, (CX, 0.0, CZ), W("c"), rot=(90, 0, 0), verts=16, bevel=0.01)
	for y in (-0.075, 0.075):
		kit.cylinder(0.158, 0.03, (CX, y, CZ), IRON("dark"), rot=(90, 0, 0), verts=16, bevel=0.003)
	dx, dz = tx - CX, tz - CZ
	th = math.degrees(math.atan2(dx, dz))
	dist = math.hypot(dx, dz)
	ts = (dist - 0.13) / 0.2275 + 0.01
	for k in range(4):
		tt = th + 90 * k
		if jammed and k == 2:
			B((0.08, 0.07, 0.03), (CX + math.sin(math.radians(tt)) * 0.15, 0.0, CZ + math.cos(math.radians(tt)) * 0.15), W("c"), bevel=0.003, rot=(0, tt, 0))
			continue
		tr = math.radians(tt)
		tappet((CX + math.sin(tr) * 0.13, 0.035, CZ + math.cos(tr) * 0.13), rot=(0, tt, 0), s=ts)
	# the drive cog at the back end of the shaft
	cog_wheel((CX, 0.72, CZ), 0.46, 0.1, n=18, rot=(90, 0, 0))
	return tx, tz, at


def hw_trip_hammer():
	trip_hammer(False)
	for k in range(3):  # finished plates stacked by the anvil
		plate((-0.95 + J(0.01), -0.62, 0.006 + k * 0.0125), 0.3, 0.26, 0.012, rot=(0, 0, k * 7 - 5))
	group(lambda: (rod((0, 0, 0.014), (0.42, 0, 0.014), 0.012, IRON("dark")), rod((0, 0.02, 0.014), (0.42, 0.04, 0.014), 0.012, IRON("dark")),
		rivet((0.32, 0.02, 0.022), IRON("a"), r=0.014)), at=(-0.5, -0.62, 0.0), rot=(0, 0, 20))
	bucket((-1.0, 0.55, 0.0), 0.12, 0.22)


def hw_jammed_hammer():
	tx, tz, at = trip_hammer(True)
	# the crowbar jammed into the cam collar, its foot on the floor
	rod((1.18, -0.05, 0.64), (1.82, -0.55, 0.02), 0.018, IRON("dark"), seg=8)
	tube([(1.82, -0.55, 0.02), (1.87, -0.58, 0.019), (1.9, -0.6, 0.035)], 0.018, 0.008, IRON("dark"))
	# the snapped tappet lying on the floor in two pieces, splinters at the break
	group(lambda: tappet((0, 0, 0), rot=(0, 90, 0), s=0.7), at=(1.45, -0.62, 0.0285), rot=(0, 0, 30))
	B((0.08, 0.07, 0.07), (1.78, -0.25, 0.035), W("c"), bevel=0.006, rot=(0, 0, 50))
	splinters((1.78, -0.25, 0.07), (0, 0, 1), n=4, r=0.05)
	# the plate slid off the anvil and leans on the stock; a mallet and wedges dropped
	plate((-0.85, -0.3, 0.17), 0.26, 0.22, 0.01, rot=(70, 0, 5))
	mallet((-0.3, -0.62, 0.0), rotz=60)
	for k in range(3):
		wedge((0.6 + k * 0.1, -0.6 - J(0.03), 0.026), 1.0, rot=(90, 0, 20 + k * 30))



def hand_hammer(head, top, m=None):
	"""A hand hammer leaning with its head on the floor and its handle end against something at `top`."""
	hx, hy = head
	d = Vector((top[0] - hx, top[1] - hy, 0)).normalized()
	ang = math.degrees(math.atan2(d.y, d.x))
	B((0.13, 0.045, 0.045), (hx, hy, 0.0225), m or IRON("dark"), bevel=0.006, rot=(0, 0, ang + 90))
	kit.cylinder(0.027, 0.03, (hx - d.y * 0.07, hy + d.x * 0.07, 0.027), IRON("a"), rot=(90, 0, ang + 90), verts=10, bevel=0.004)
	rod((hx, hy, 0.03), top, 0.015, W("c"), seg=7)


def hw_plate_anvil():
	top = stump(0, 0, 0.5, 0.26, bands=(0.1, 0.5, 0.85))
	sw = B((0.42, 0.34, 0.15), (0, 0, top + 0.07), IRON("dark"), bevel=0.012)
	hol = []
	for (x, y, r) in ((-0.1, -0.05, 0.07), (0.1, 0.06, 0.055), (0.12, -0.09, 0.035)):
		hol.append(sphere((x, y, top + 0.145 + r * 0.55), r, GROOVE(), seg=16, rings=10))
	carve(sw, hol)
	carve(sw, [kit.cylinder(0.022, 0.5, (0, -0.17, top + 0.145), GROOVE(), rot=(0, 90, 0), verts=12, bevel=0)])
	for x in (-0.15, 0.15):
		kit.cylinder(0.016, 0.06, (x, 0.16, top + 0.01), IRON("a"), verts=6, bevel=0.002)
	# a plate half beaten into the big hollow
	lathe([(0.002, 0.045), (0.06, 0.036), (0.1, 0.018), (0.125, 0.004), (0.12, 0.0), (0.095, 0.012), (0.057, 0.028), (0.002, 0.037)],
		(-0.1, -0.05, top + 0.105), IRON("a"), seg=16, loop=True)
	# two planishing hammers leaning on the stump
	hand_hammer((0.42, -0.2), (0.25, -0.1, 0.4))
	hand_hammer((-0.36, -0.3), (-0.2, -0.17, 0.36))
	# finished domed plates stacked on a board
	B((0.36, 0.36, 0.03), (0.15, 0.48, 0.015), W("b"), bevel=0.008, rot=(0, 0, 12))
	for k in range(4):
		lathe([(0.002, 0.05), (0.07, 0.04), (0.12, 0.018), (0.14, 0.002), (0.133, 0.0), (0.112, 0.014), (0.066, 0.033), (0.002, 0.042)],
			(0.15 + J(0.006), 0.48 + J(0.006), 0.029 + k * 0.013), IRON("abc"[k % 3]), seg=16, loop=True)
	# flat blanks waiting on the floor
	for k in range(3):
		plate((-0.45 + k * 0.004, 0.35, 0.006 + k * 0.0125), 0.26, 0.26, 0.012, rot=(0, 0, k * 2))


def hw_gear_train():
	group(_gear_train, rot=(0, 0, -90))  # turned so the big wheel's cogged face looks to the front


def _gear_train():
	ZC, R = 0.85, 0.6
	# horizontal shaft on two brick piers, the big face-cog wheel on its end
	for x in (-0.85, -0.3):
		ptop = brick_pier(x, 0, 0.3, 0.36, ZC - 0.17)
		bearing((x, 0, ZC), "x", 0.075, w=0.22)
	shaft((-1.05, 0, ZC), (0.1, 0, ZC), 0.075, bands=(0.1, 0.5, 0.93))
	cog_wheel((0.0, 0, ZC), R, 0.12, n=17, rot=(0, 90, 0), face=True, arms=2, felloes=6)
	# upright shaft: iron footstep on a brick block, a top beam on two posts, the lantern pinion
	XP = 0.06 + 0.04 + 0.12
	fz = brick_pier(XP, 0, 0.3, 0.3, 0.2)
	B((0.16, 0.16, 0.03), (XP, 0, fz + 0.01), IRON("dark"), bevel=0.004)
	shaft((XP, 0, fz + 0.02), (XP, 0, 2.02), 0.065, bands=(0.06, 0.6, 0.95))
	for y in (-0.5, 0.5):
		B((0.16, 0.16, 2.1), (XP, y, 1.05), W(), bevel=0.014)
		for dy in (-1, 1):
			if dy * y < 0:
				continue
			beam((XP, y + dy * 0.45, 0.0 + 0.06), (XP, y + dy * 0.05, 0.6), 0.1, 0.09, W("c"))
	for y in (-0.5, 0.5):
		B((0.3, 0.22, 0.04), (XP, y + (0.12 if y > 0 else -0.12), 0.02), W("b"), bevel=0.008)
	B((0.2, 1.2, 0.16), (XP, 0, 1.98), W("b"), bevel=0.014)
	bearing((XP, 0, 1.98), "y", 0.065, w=0.2, h=0.001) if False else kit.cylinder(0.09, 0.18, (XP, 0, 1.98), IRON("dark"), verts=12, bevel=0.004)
	pinion((XP, 0, ZC + 0.89 * R), 0.12, 0.2, n=8, rot=(0, 0, 22.5))
	# the next stage: a small spur cog on the upright shaft
	cog_wheel((XP, 0, 1.68), 0.28, 0.08, n=12, rot=(0, 0, 0), felloes=4)
	for y in (-0.5, 0.5):
		for z in (0.4, 1.4):
			B((0.17, 0.012, 0.05), (XP, y - 0.081 if y < 0 else y + 0.081, z), IRON("dark"), bevel=0.003)


def belt_loop(x, c1, r1, c2, r2, rb=0.014, m=None):
	"""A closed rope belt round two pulleys (centres (y, z)) in the plane x."""
	dy, dz = c2[0] - c1[0], c2[1] - c1[1]
	L = math.hypot(dy, dz)
	ny, nz = -dz / L, dy / L
	t0 = math.atan2(nz, ny)
	pts = []
	for k in range(13):
		a = t0 + math.pi * k / 12
		pts.append((x, c1[0] + math.cos(a) * (r1 + rb), c1[1] + math.sin(a) * (r1 + rb)))
	for k in range(13):
		a = t0 + math.pi + math.pi * k / 12
		pts.append((x, c2[0] + math.cos(a) * (r2 + rb), c2[1] + math.sin(a) * (r2 + rb)))
	pts.append(pts[0])
	tube(pts, rb, rb, m or ROPE(), seg=8)


def drum(c, r, w, axis="x"):
	rot = (0, 90, 0) if axis == "x" else (90, 0, 0)
	kit.cylinder(r, w, c, W("b"), rot=rot, verts=20, bevel=0.01)
	ax = Vector((1, 0, 0)) if axis == "x" else Vector((0, 1, 0))
	for s_ in (-1, 1):
		p = Vector(c) + ax * s_ * (w / 2 - 0.006)
		kit.cylinder(r + 0.008, 0.016, tuple(p), IRON("dark"), rot=rot, verts=20, bevel=0.003)
		for k in range(4):
			a = math.pi / 2 * k + 0.4
			off = Vector((0, math.cos(a), math.sin(a))) if axis == "x" else Vector((math.cos(a), 0, math.sin(a)))
			rivet(tuple(p + ax * s_ * 0.01 + off * r * 0.7), IRON("a"), r=0.01)


def hw_line_shaft():
	ZC, r = 1.464, 0.08
	for x in (-0.9, 0.9):
		brick_pier(x, 0, 0.36, 0.36, 1.3)
		bearing((x, 0, ZC), "x", r, w=0.24)
		lathe([(0.012, 0), (0.025, 0.02), (0.03, 0.05), (0.02, 0.06)], (x, 0, ZC + r * 1.2), CU("dark"), seg=10)  # oil cup
	shaft((-1.15, 0, ZC), (1.15, 0, ZC), r, bands=(0.05, 0.3, 0.62, 0.95))
	for (x, R, w, yl, zl, rl) in ((-0.35, 0.22, 0.2, -0.65, 0.34, 0.11), (0.4, 0.16, 0.16, -0.6, 0.3, 0.09)):
		drum((x, 0, ZC), R, w)
		# a floor stand with the lower pulley
		B((0.34, 0.3, 0.08), (x, yl, 0.04), W("a"), bevel=0.01)
		for s_ in (-1, 1):
			B((0.05, 0.14, zl + rl * 0.4), (x + s_ * (w / 2 + 0.03), yl, (zl + rl * 0.4) / 2 + 0.06), W("c"), bevel=0.008)
			beam((x + s_ * (w / 2 + 0.03), yl + 0.14, 0.08), (x + s_ * (w / 2 + 0.03), yl + 0.03, zl - 0.02), 0.04, 0.04, W("b"))
		rod((x - w / 2 - 0.07, yl, zl), (x + w / 2 + 0.07, yl, zl), 0.018, IRON("a"))
		drum((x, yl, zl), rl, w * 0.8)
		belt_loop(x, (0, ZC), R, (yl, zl), rl)
	for x in (-0.9, 0.9):
		B((0.04, 0.012, 0.3), (x, -0.186, 1.12), IRON("dark"), bevel=0.003)
		rivet((x, -0.194, 1.2), IRON("a"), r=0.011)
	slim(small=0.03, fine=0.012, few=0.02)  # lighter file (under 2 MB), same look


def hw_wheel_trough():
	ZC = 1.15
	# the race: brick walls, a plank floor (dry: owner, no water)
	for y in (-0.42, 0.42):
		brick_pier(0, y, 2.6, 0.22, 0.35)
	for k in range(9):
		B((0.29, 0.62, 0.05), (-1.16 + k * 0.29, 0, 0.025), W(), bevel=0.008)
	# the wheel: two rims of felloes, arms, paddles, all round an axle along Y

	def wheel_():
		ro, ri = 1.0, 0.86
		for zs in (-0.24, 0.24):
			for k in range(8):
				g = 0.004
				a0, a1 = 2 * math.pi * k / 8 + g, 2 * math.pi * (k + 1) / 8 - g
				sector(ro - 0.06, ri - 0.06, zs - 0.03, zs + 0.03, a0, a1, W("abc"[k % 3]))
				a = 2 * math.pi * k / 8
				B((0.1, 0.11, 0.012), (math.cos(a) * 0.87, math.sin(a) * 0.87, zs + (0.035 if zs > 0 else -0.035)), IRON("dark"), bevel=0.003,
					rot=(0, 0, math.degrees(a) + 90))
			for k in range(4):
				a = math.pi * k / 4 + math.pi / 8
				B((2 * (ri - 0.04), 0.09, (0.088, 0.074, 0.05, 0.042)[k]), (0, 0, zs), W("abc"[(k + 1) % 3]), bevel=0.008, rot=(0, 0, math.degrees(a)))
		for k in range(16):
			a = 2 * math.pi * k / 16 + math.pi / 16
			B((0.22, 0.04, 0.56), (math.cos(a) * 0.88, math.sin(a) * 0.88, 0), W("abc"[k % 3]) if k % 4 else WD(), bevel=0.008,
				rot=(0, 0, math.degrees(a)))
		for zs in (-0.24, 0.24):
			kit.cylinder(0.2, 0.1, (0, 0, zs), IRON("dark"), verts=14, bevel=0.006)
			for k in range(6):
				a = 2 * math.pi * k / 6
				rivet((math.cos(a) * 0.15, math.sin(a) * 0.15, zs + (0.052 if zs > 0 else -0.052)), IRON("a"), r=0.012)
	group(wheel_, at=(0, 0, ZC), rot=(90, 0, 0))
	shaft((0, -0.85, ZC), (0, 0.85, ZC), 0.12, bands=(0.06, 0.94))
	for y in (-0.7, 0.7):
		B((0.2, 0.2, ZC - 0.1), (0, y, (ZC - 0.1) / 2), W(), bevel=0.014)
		bearing((0, y, ZC), "y", 0.12, w=0.26)
		for dx in (-1, 1):
			beam((dx * 0.5, y, 0.0), (dx * 0.06, y, 0.75), 0.1, 0.09, W("c"))



def on_floor(build, at=(0, 0, 0), rot=(0, 0, 0), z=0.0):
	"""Build something, turn it, then set its lowest point down on the floor (or at height z)."""
	before = objs()
	group(build, at, rot)
	g = [o for o in objs() - before if o.type == "MESH"]
	bpy.context.view_layer.update()
	shift(g, (0, 0, z - low_z(g)))
	return g


def sluice(broken=False):
	L = 1.6
	for k in range(6):
		B((0.84, L / 6 - 0.008, 0.06), (0, -L / 2 + L / 6 * (k + 0.5), 0.03), W(), bevel=0.008)
	for sx in (-1, 1):
		x = sx * 0.42
		for ys in (-1, 1):
			yc = ys * (L / 4 + 0.04)
			for z in (0.16, 0.37):
				B((0.05, L / 2 - 0.08 + 0.01, 0.19), (x, yc, z), W(), bevel=0.008)
			B((0.1, 0.1, 0.52), (sx * 0.49, ys * 0.7, 0.26), WD(), bevel=0.01)
		post = B((0.14, 0.16, 1.55), (sx * 0.47, 0, 0.775), W("b"), bevel=0.014)
		carve(post, [B((0.07, 0.06, 1.0), (sx * 0.4, 0, 1.0), GROOVE(), bevel=0)])
		for z in (0.3, 1.2):
			B((0.15, 0.012, 0.05), (sx * 0.47, -0.081, z), IRON("dark"), bevel=0.003)
			rivet((sx * 0.47, -0.089, z), IRON("a"), r=0.011)
	B((1.14, 0.2, 0.14), (0, 0, 1.5), W("a"), bevel=0.014)
	# the gate boards (iron-strapped); broken: only the top board is left, hanging crooked
	gz = 0.14

	def gate_board(z, m):
		B((0.86, 0.05, 0.19), (0, 0, z), m, bevel=0.008)
		for x in (-0.25, 0.25):
			B((0.05, 0.012, 0.2), (x, -0.028, z), IRON("dark"), bevel=0.003)
			rivet((x, -0.035, z), IRON("a"), r=0.01)
	if broken:
		group(lambda: gate_board(0, W("c")), at=(0.02, 0, gz + 0.5 - 0.06), rot=(0, 12, 0))
	else:
		for k in range(3):
			gate_board(gz + 0.1 + k * 0.2, W("abc"[k]))
	# the rack bar through the beam, pinned every 10 cm, and the windlass that lifts it
	top_board = gz + 0.6 if not broken else gz + 0.5
	B((0.08, 0.06, 1.74 - top_board + 0.02), (0, 0, (top_board - 0.02 + 1.74) / 2), WD(), bevel=0.006)
	for k in range(9):
		rod((0, -0.05, top_board + 0.06 + k * 0.1), (0, 0.05, top_board + 0.06 + k * 0.1), 0.01, IRON("a"))
	kit.ring(0.025, 0.008, (0, 0, 1.76), IRON("dark"), rot=(90, 0, 0), seg=10)
	for x in (-0.2, 0.2):
		B((0.05, 0.14, 0.42), (x, 0.06, 1.715), W("b"), bevel=0.008)
	kit.cylinder(0.06, 0.36, (0, 0.06, 1.86), W("c"), rot=(0, 90, 0), verts=14, bevel=0.006)
	kit.rope_wrap((0.06, 1.86), 0.062, -0.08, 0.08, 4, thick=0.012, axis="x")
	kit.rope((0, 0.0, 1.77), (0, 0.04, 1.81), 0.011)
	rod((0.17, 0.06, 1.86), (0.34, 0.06, 1.86), 0.014, IRON("dark"))
	rod((0.34, 0.06, 1.86), (0.34, 0.06, 1.7), 0.014, IRON("dark"))
	rod((0.34, 0.06, 1.7), (0.44, 0.06, 1.7), 0.02, W("c"))
	kit.cylinder(0.09, 0.03, (-0.24, 0.06, 1.86), IRON("dark"), rot=(0, 90, 0), verts=12, bevel=0.003)
	beam((-0.24, 0.06, 1.75), (-0.24, 0.0, 1.8), 0.03, 0.015, IRON("dark"), bevel=0.002)
	return L


def hw_sluice_gate():
	sluice(False)  # dry channel (owner: no water)


def hw_burst_sluice():
	sluice(True)  # dry channel, no puddles (owner: no water)
	# the two lower gate boards: one snapped on the channel floor, one slid out over the end onto the floor
	B((0.5, 0.04, 0.19), (-0.15, -0.45, 0.077), W("a"), bevel=0.008, rot=(90, 0, 8))  # pressed 3 mm into the floor boards
	splinters((0.1, -0.41, 0.08), (1, 0.14, 0), n=5, r=0.06)
	B((0.3, 0.05, 0.19), (0.55, -0.98, 0.025), W("b"), bevel=0.008, rot=(90, 0, -20))
	splinters((0.41, -1.03, 0.03), (-1, -0.35, 0), n=4, r=0.05)
	on_floor(lambda: bucket((0, 0, 0), 0.12, 0.22), at=(-0.6, -1.15, 0.2), rot=(90, 0, 30))


def hw_flume_trough():
	# a brick trough: two long walls and two short ends, clay floor, dry (owner: no water)
	for y in (-0.2, 0.2):
		brick_pier(0, y, 1.6, 0.12, 0.48)
	for x in (-0.73, 0.73):
		brick_pier(x, 0, 0.12, 0.28, 0.46)
	B((1.36, 0.27, 0.06), (0, 0, 0.03), CLAY(), bevel=0.006)
	# the flume on a trestle, sloping down to pour into the trough
	p0, p1 = Vector((0.2, 1.15, 1.1)), Vector((0.2, 0.05, 0.92))
	beam(tuple(p0), tuple(p1), 0.2, 0.03, W("b"))
	for s_ in (-1, 1):
		beam(tuple(p0 + Vector((s_ * 0.11, 0, 0.06))), tuple(p1 + Vector((s_ * 0.11, 0, 0.06))), 0.025, 0.15, W())
	for f in (0.15, 0.55, 0.9):
		q = p0 + (p1 - p0) * f
		B((0.28, 0.04, 0.03), tuple(q + Vector((0, 0, 0.13))), WD(), bevel=0.004)
		for s_ in (-1, 1):
			B((0.03, 0.04, 0.18), tuple(q + Vector((s_ * 0.13, 0, 0.05))), WD(), bevel=0.004)
	ty = 0.7
	q = p0 + (p1 - p0) * ((p0.y - ty) / (p0.y - p1.y))
	for sx in (-1, 1):
		beam((0.2 + sx * 0.35, ty, 0.0), (0.2 + sx * 0.06, ty, q.z - 0.01), 0.08, 0.08, W("c"))
	beam((0.2 - 0.26, ty, 0.25), (0.2 + 0.26, ty, 0.25), 0.06, 0.06, W("b"))
	B((0.3, 0.1, 0.06), (0.2, ty, q.z - 0.04), W("a"), bevel=0.008)
	# a copper dipper hooked over the trough wall
	pot((-0.45, -0.1, 0.36), 0.06, 0.08, CU("b"), t=0.006, seg=12, rim=False)
	tube([(-0.45, -0.165, 0.43), (-0.45, -0.2, 0.5), (-0.45, -0.235, 0.53), (-0.45, -0.27, 0.5)], 0.008, 0.007, CU("dark"))


def hw_plate_stack():
	for y in (-0.2, 0.2):
		B((2.0, 0.12, 0.1), (0, y, 0.05), W("b") if y < 0 else W("a"), bevel=0.012)
		for x in (-0.9, 0.9):
			sphere((x, y - 0.062, 0.05), 0.013, WD(), seg=8, rings=5)
	tops = []
	for (xc, n) in ((-0.64, 8), (0.0, 13), (0.64, 5)):
		z = 0.1
		for k in range(n):
			if k and k % 5 == 0:
				for x in (xc - 0.17, xc + 0.17):
					B((0.05, 0.5, 0.02), (x, 0, z + 0.008), W("c"), bevel=0.004)
				z += 0.017
			plate((xc + J(0.004), J(0.004), z + 0.0055), 0.56, 0.48, 0.012, rot=(0, 0, J(0.6)))
			z += 0.0125
		tops.append((xc, z))
	# the middle stack is strapped with an iron band
	xc, zt = tops[1]
	B((0.04, 0.5, 0.006), (xc, 0, zt + 0.002), IRON("dark"), bevel=0.001)
	for s_ in (-1, 1):
		B((0.04, 0.006, zt - 0.1 + 0.004), (xc, s_ * 0.25, (zt + 0.1) / 2), IRON("dark"), bevel=0.001)
	B((0.06, 0.02, 0.04), (xc, -0.25, zt - 0.06), IRON("a"), bevel=0.003)
	# a scissor lifting clamp lying on the left stack
	xc, zt = tops[0]
	cz = zt + 0.008
	beam((xc - 0.2, -0.12, cz), (xc + 0.16, 0.12, cz), 0.04, 0.014, IRON("dark"), bevel=0.003)
	beam((xc - 0.2, 0.12, cz + 0.014), (xc + 0.16, -0.12, cz + 0.014), 0.04, 0.014, IRON("dark"), bevel=0.003)
	kit.cylinder(0.018, 0.04, (xc - 0.02, 0, cz + 0.008), IRON("a"), verts=8, bevel=0.002)
	for y in (-0.12, 0.12):
		B((0.05, 0.035, 0.03), (xc + 0.18, y, cz + 0.008), IRON("dark"), bevel=0.003)
	tube([(xc - 0.2, -0.12, cz), (xc - 0.28, -0.07, cz), (xc - 0.3, 0.0, cz), (xc - 0.28, 0.07, cz + 0.014), (xc - 0.2, 0.12, cz + 0.014)], 0.01, 0.01, IRON("dark"))


def hw_rivet_brazier():
	top = brick_pier(0, 0, 0.5, 0.5, 0.55)
	pot((0, 0, top - 0.004), 0.2, 0.12, IRON("dark"), t=0.012, seg=16, flare=1.12)
	kit.ring(0.235, 0.012, (0, 0, top + 0.25), IRON("dark"), seg=22)
	for k in range(12):
		a = 2 * math.pi * k / 12
		rod((math.cos(a) * 0.226, math.sin(a) * 0.226, top + 0.11), (math.cos(a) * 0.235, math.sin(a) * 0.235, top + 0.255), 0.009, IRON("dark"))
	for s_ in (-1, 1):
		kit.ring(0.04, 0.009, (s_ * 0.255, 0, top + 0.17), IRON("a"), rot=(90, 0, 0), seg=10)
	coal_bed(0, 0, top + 0.04, 0.2, n=38, hot=0.25, seed=5)
	for k in range(8):  # rivets heating in the coals
		a = 2 * math.pi * k / 8 + 0.3
		x, y = math.cos(a) * 0.1, math.sin(a) * 0.1
		zz = top + 0.1 - 0.03 * (0.1 / 0.2)
		kit.cylinder(0.008, 0.04, (x, y, zz), HOT(), rot=(70, 0, math.degrees(a)), verts=6, bevel=0)
		sphere((x - math.sin(a) * 0.0, y, zz + 0.02), 0.013, HOT(), seg=8, rings=5)
	# rivet tongs resting across the rim
	for s_ in (-1, 1):
		beam((0.05, s_ * 0.012, top + 0.26), (0.62, s_ * 0.04, top - 0.2), 0.016, 0.01, IRON("dark"), bevel=0.002)
	kit.cylinder(0.014, 0.05, (0.2, 0, top + 0.155), IRON("a"), rot=(90, 0, 0), verts=8, bevel=0.002)
	rod((0.62, -0.06, top - 0.2), (0.62, 0.06, top - 0.2), 0.008, IRON("dark"))
	# a pail of cold rivets and a box of coal on the floor
	bucket((-0.45, -0.35, 0.0), 0.11, 0.18)
	for k in range(14):
		a, d = k * 2.4, 0.02 + (k % 5) * 0.017
		x, y = -0.45 + math.cos(a) * d, -0.35 + math.sin(a) * d
		sphere((x, y, 0.15 + 0.004 * (k % 3)), 0.012, IRON("a"), seg=8, rings=5)
		kit.cylinder(0.007, 0.03, (x, y, 0.14), IRON("dark"), rot=(J(30), J(30), 0), verts=6, bevel=0)
	disc(0.115, 0.13, 0.14, (-0.45, -0.35), IRON("dark"), seg=14, wob=0.02)
	open_box(0.45, -0.4, 0.0, 0.34, 0.26, 0.14)
	coal_bed(0.45, -0.4, 0.06, 0.095, n=30, hot=0.0, seed=9)
	B((0.1, 0.1, 0.12), (-0.38, 0.38, 0.06), IRON("dark"), bevel=0.01)  # a holding-up dolly
	kit.cylinder(0.04, 0.03, (-0.38, 0.38, 0.13), IRON("a"), verts=10, bevel=0.004)


def hw_chain_hoist():
	H = 2.15
	for x in (-0.85, 0.85):
		for y in (-0.55, 0.55):
			B((0.2, 0.26, 0.06), (x, y, 0.03), W("b"), bevel=0.01)
			beam((x, y * 0.97, 0.05), (x, y * 0.06, H - 0.02), 0.12, 0.12, W())
		beam((x, -0.4, 0.6), (x, 0.4, 0.6), 0.1, 0.1, W("c"))
		for y in (-0.38, 0.38):
			sphere((x - 0.065, y, 0.6), 0.013, WD(), seg=8, rings=5)
	B((2.0, 0.16, 0.18), (0, 0, H + 0.07), W("a"), bevel=0.014)
	for x in (-0.85, 0.85):
		beam((x, 0, 1.6), (x - math.copysign(0.45, x), 0, H - 0.02), 0.08, 0.08, W("c"))
		B((0.04, 0.18, 0.012), (x, 0, H + 0.165), IRON("dark"), bevel=0.003)
	# the pulley block hanging from an iron strap round the beam
	for s_ in (-1, 1):
		B((0.05, 0.012, 0.32), (0, s_ * 0.086, H + 0.0), IRON("dark"), bevel=0.003)
	B((0.05, 0.19, 0.012), (0, 0, H + 0.167), IRON("dark"), bevel=0.003)
	B((0.05, 0.19, 0.02), (0, 0, H - 0.15), IRON("dark"), bevel=0.003)
	bz = H - 0.32
	kit.ring(0.03, 0.01, (0, 0, H - 0.17), IRON("dark"), rot=(90, 0, 0), seg=12)
	for s_ in (-1, 1):
		B((0.26, 0.014, 0.24), (0, s_ * 0.035, bz), IRON("dark"), bevel=0.005)
	kit.cylinder(0.1, 0.05, (0, 0, bz), W("c"), rot=(90, 0, 0), verts=16, bevel=0.006)
	rod((0, -0.055, bz), (0, 0.055, bz), 0.016, IRON("a"))
	B((0.06, 0.08, 0.03), (0, 0, bz + 0.12), IRON("dark"), bevel=0.003)
	# the load chain down to the hook; the hand chain hanging in a loop
	chain((-0.1, 0, bz + 0.02), (-0.105, 0, 1.15), link=0.035, wire=0.009)
	lift_hook((-0.105, 0, 1.115), 1.4)
	for x in (0.105, 0.135):
		chain((x - 0.01, 0, bz + 0.01), (x, 0, 0.97), link=0.026, wire=0.006)
	chain((0.105, 0, 0.95), (0.135, 0, 0.95), link=0.026, wire=0.006)
	# the plate hanging in a two-leg sling from the hook
	hx, hz = -0.105 + 0.06 * 1.4, 1.115 - 0.215 * 1.4
	pz, ph = 0.15, 0.45
	plate((hx, 0, pz + ph / 2), 0.6, 0.012, ph)
	for s_ in (-1, 1):
		px = hx + s_ * 0.24
		for dy in (-1, 1):
			B((0.05, 0.012, 0.07), (px, dy * 0.02, pz + ph - 0.02), IRON("dark"), bevel=0.003)
		rod((px, -0.03, pz + ph - 0.035), (px, 0.03, pz + ph - 0.035), 0.008, IRON("a"))
		kit.ring(0.02, 0.006, (px, 0, pz + ph + 0.03), IRON("dark"), rot=(90, 0, 0), seg=10)
		chain((px * 0.97 + hx * 0.03, 0, pz + ph + 0.06), (hx + s_ * 0.02, 0, hz + 0.02), link=0.022, wire=0.006)


def hw_snapped_chain():
	# a patch of brick floor; the bricks under the plate cracked and broken
	cracked = []
	for r in range(10):
		y = -0.6 + r * 0.125
		x = -0.8 - (0.12 if r % 2 else 0.0)
		while x < 0.8:
			xa, xb = max(x, -0.8), min(x + 0.24, 0.8)
			cx = (xa + xb) / 2
			hit = abs(cx - 0.05) < 0.35 and abs(y - 0.0) < 0.3
			if xb - xa > 0.06:
				if hit and rng.random() < 0.45:
					for k in range(3):
						kit.gem((cx + (k - 1) * 0.07, y + J(0.02), 0.012), (0.04, 0.04, 0.014), BRK(), seed=r * 9 + k)
				else:
					b = B((xb - xa - 0.012, 0.113, 0.04), (cx, y, 0.02 + (0.012 if hit else 0)), OCH() if rng.random() < 0.12 else BRK(), bevel=0.005,
						rot=(J(3) if hit else 0, J(3) if hit else 0, 0))
					if hit:
						cracked.append((b, cx, y))
			x += 0.24
	B((1.6, 1.25, 0.012), (0, -0.0, 0.009), MORTAR(), bevel=0)
	for k, (b, cx, y) in enumerate(cracked[:6]):
		carve(b, [B((0.16, 0.012, 0.05), (cx, y, 0.045), GROOVE(), bevel=0, rot=(0, 0, 30 + k * 40))])
	# the fallen plate, bent where it struck, one edge dug into the broken bricks
	def bent():
		B((0.34, 0.5, 0.012), (-0.17, 0, 0.006), IRON("a"), bevel=0.003)
		B((0.3, 0.5, 0.012), (0.145, 0, 0.006), IRON("b"), bevel=0.003, rot=(0, -8, 0))
		for s_ in (-1, 1):
			kit.ring(0.02, 0.006, (-0.3, s_ * 0.2, 0.014), IRON("dark"), seg=10)
	on_floor(bent, at=(0.05, 0.0, 0.03), rot=(6, -5, 18), z=0.035)
	# the hook with a few links, the snapped link, loose links
	on_floor(lambda: lift_hook((0, 0, 0), 1.4), at=(-0.45, -0.45, 0.2), rot=(90, 0, 0), z=0.04)
	for k in range(4):
		kit.ring(0.035, 0.009, (-0.45 + 0.065 * k, -0.43 + 0.012 * k, 0.05 + 0.002 * (k % 2)), IRON("dark"), rot=(0 if k % 2 else 75, 0, 10), seg=10)
	a0 = math.radians(40)
	tube([(0.5 + math.cos(a0 + t * 0.5) * 0.04, 0.45 + math.sin(a0 + t * 0.5) * 0.06, 0.049) for t in range(10)], 0.009, 0.009, IRON("dark"))
	for k, (x, y) in enumerate(((0.62, 0.3), (0.35, 0.52), (0.7, -0.4))):
		kit.ring(0.035, 0.009, (x, y, 0.05), IRON("dark"), rot=(0, 0, k * 50), seg=10)
	kit.ring(0.035, 0.009, (0.45, 0.55, 0.05), IRON("dark"), rot=(0, 0, 80), seg=10)


def hw_broken_cog():
	# a work trestle; the damaged wheel leans against it
	TY, TH = 0.3, 0.75
	for x in (-0.55, 0.55):
		for dy in (-1, 1):
			beam((x, TY + dy * 0.28, 0.0), (x, TY + dy * 0.02, TH - 0.04), 0.08, 0.08, W("c"))
		beam((x, TY - 0.2, 0.25), (x, TY + 0.2, 0.25), 0.06, 0.06, W("b"))
	B((1.4, 0.14, 0.12), (0, TY, TH), W("a"), bevel=0.012)
	on_floor(lambda: cog_wheel((0, 0, 0), 0.55, 0.09, n=16, rot=(0, 0, 0), broken=(3, 4, 9)), at=(0, TY - 0.07 - 0.62 * 0.27, 0.62),
		rot=(74, 0, 0), z=0.0)
	# the broken cogs on the floor
	for k, (x, y, a) in enumerate(((-0.35, -0.45, 20), (-0.15, -0.55, 80), (0.3, -0.5, -30))):
		B((0.1, 0.06, 0.07), (x, y, 0.035), W("c") if k % 2 else WD(), bevel=0.006, rot=(0, 0, a))
		splinters((x + math.cos(math.radians(a)) * 0.05, y + math.sin(math.radians(a)) * 0.05, 0.035), (math.cos(math.radians(a)), math.sin(math.radians(a)), 0), n=3, r=0.04)
	# a new cog being cut on a block: the blank, a chisel, the mallet, chips
	top = stump(0.85, -0.25, 0.42, 0.2)
	B((0.22, 0.09, 0.08), (0.85, -0.25, top + 0.038), W("c"), bevel=0.006)
	kit.taper(0.08, 0.075, 0.05, 0.055, 0.06, (0.85 + 0.15, -0.25, top - 0.002), W("c"), bevel=0.005)
	B((0.022, 0.01, 0.12), (0.8, -0.33, top + 0.006), IRON("a"), bevel=0.002, rot=(90, 0, 20))
	kit.cylinder(0.017, 0.1, (0.78, -0.43, top + 0.016), WD(), rot=(90, 0, 20), verts=8, bevel=0.004)
	mallet((0.6, -0.55, 0.0), rotz=-40)
	for k in range(10):
		a, d = k * 2.3, 0.25 + (k % 4) * 0.05
		B((0.03, 0.015, 0.004), (0.85 + math.cos(a) * d, -0.25 + math.sin(a) * d, 0.002), W("c"), bevel=0, rot=(0, 0, k * 37))



def cart(ingots=True, wheels=(0, 1, 2, 3), z0=0.0):  # ingots are bronze (the loot)
	"""The ingot cart: banded plank box on a frame, axle boxes, four flanged iron wheels, a push bar.
	Built with the wheel bottoms at z0 + 0.135 - 0.11 (resting on rails whose top is z0 + 0.135)."""
	R, ZA = 0.11, z0 + 0.135 + 0.11
	L, Wd, H = 0.82, 0.52, 0.3
	zf = ZA + 0.05
	for y in (-0.2, 0.2):
		B((L + 0.04, 0.08, 0.08), (0, y, zf + 0.0), W("b"), bevel=0.01)
	for k in range(5):
		B((L / 5 - 0.008, Wd - 0.014, 0.04), (-L / 2 + L / 5 * (k + 0.5), 0, zf + 0.06), W(), bevel=0.006)
	for s_ in (-1, 1):
		for j, zz in enumerate((0.09, 0.235)):
			B((L, 0.04, 0.14), (0, s_ * (Wd / 2 - 0.02), zf + 0.04 + zz), W(), bevel=0.008)
			B((0.04, Wd - 0.085, 0.14), (s_ * (L / 2 - 0.02), 0, zf + 0.04 + zz), W(), bevel=0.008)
		for x in (-L / 2 + 0.01, L / 2 - 0.01):
			B((0.06, 0.012, H + 0.02), (x - math.copysign(0.02, x), s_ * (Wd / 2 + 0.002), zf + 0.04 + H / 2 + 0.01), IRON("dark"), bevel=0.003)
			for zz in (0.08, 0.2, 0.3):
				rivet((x - math.copysign(0.02, x), s_ * (Wd / 2 + 0.009), zf + 0.04 + zz), IRON("a"), r=0.009)
		B((L - 0.08, 0.012, 0.04), (0, s_ * (Wd / 2 + 0.006), zf + 0.04 + H - 0.01), IRON("dark"), bevel=0.003)
	for x in (-0.26, 0.26):
		rod((x, -0.31, ZA), (x, 0.31, ZA), 0.022, IRON("a"))
		for y in (-0.2, 0.2):
			B((0.1, 0.09, 0.08), (x, y, ZA + 0.01), IRON("dark"), bevel=0.006)
	for k, (x, y) in enumerate(((-0.26, -0.262), (0.26, -0.262), (-0.26, 0.262), (0.26, 0.262))):
		if k in wheels:
			wheel((x, y, ZA), R, flip=y > 0)
	for y in (-0.16, 0.16):
		beam((L / 2 - 0.02, y, zf + 0.25), (L / 2 + 0.28, y, zf + 0.42), 0.035, 0.035, IRON("dark"), bevel=0.004)
	rod((L / 2 + 0.28, -0.22, zf + 0.42), (L / 2 + 0.28, 0.22, zf + 0.42), 0.025, W("c"), seg=8)
	if ingots:
		zi = zf + 0.08
		for layer in range(3):
			if layer % 2 == 0:
				for i in range(2):
					for j in range(3):
						ingot((-0.18 + i * 0.36, -0.14 + j * 0.14, zi + layer * 0.07), 0, BRONZE(i + j + layer))
			else:
				for i in range(5):
					ingot((-0.28 + i * 0.14, 0, zi + layer * 0.07), 90, BRONZE(i + layer))
	return zf


def hw_ingot_cart(empty=False):
	track(-0.85, 0.85, gauge=0.5, n=6)
	cart(not empty)


def hw_ingot_cart_empty():
	hw_ingot_cart(True)


def hw_derailed_cart():
	track(-0.9, 0.9, gauge=0.5, n=6)
	on_floor(lambda: cart(False, wheels=(0, 2, 3)), at=(0.25, -0.75, 0.5), rot=(-90, 0, 8))  # empty (owner: no ingots)
	# the wheel that came off rolled away and fell flat
	wheel((-0.75, -0.95, 0.0225 + 0.006), 0.11, axis="z") if False else on_floor(lambda: wheel((0, 0, 0), 0.11), at=(-0.75, -0.95, 0.2), rot=(90, 0, 30))


def hw_ingot_stack(empty=False):
	for y in (-0.3, 0.0, 0.3):
		B((1.0, 0.1, 0.1), (0, y, 0.05), W("b"), bevel=0.012)
	for k in range(6):
		B((0.16, 0.8, 0.04), (-0.42 + k * 0.168, 0, 0.12), W("abc"[k % 3]), bevel=0.006)
		for y in (-0.3, 0.0, 0.3):
			sphere((-0.42 + k * 0.168, y, 0.14), 0.011, WD(), seg=8, rings=5)
	z = 0.14
	for layer in range(0 if empty else 6):
		if layer % 2 == 0:
			for i in range(3):
				for j in range(5):
					ingot((-0.31 + i * 0.31, -0.28 + j * 0.14, z), 0, BRONZE(i + j + layer))
		else:
			for i in range(6):
				for j in range(2):
					ingot((-0.35 + i * 0.14, -0.155 + j * 0.31, z), 90, BRONZE(i + j + layer))
		z += 0.07
	# a tally stick with cut notches lying on top (empty: on the bare pallet, between the peg rows), a crowbar leaning on it
	ys = -0.15 if empty else -0.05
	zs = z + (0.009 if empty else 0.012)
	st = B((0.5, 0.035, 0.025), (0.0, ys, zs), W("c"), bevel=0.004, rot=(0, 0, 10))
	cuts = []
	for k in range(9):
		x = -0.18 + k * 0.045
		cuts.append(B((0.008, 0.06, 0.03), (x * math.cos(0.1745), ys + x * math.sin(0.1745), zs + 0.018), GROOVE(), bevel=0, rot=(0, 0, 10)))
	carve(st, cuts)
	rod((0.62, -0.42, 0.018), (0.48, -0.3, z - 0.02 if not empty else z + 0.012), 0.016, IRON("dark"), seg=8)
	tube([(0.62, -0.42, 0.018), (0.66, -0.45, 0.016), (0.7, -0.47, 0.03)], 0.016, 0.007, IRON("dark"))
	for (x, y, a) in ((-0.62, 0.2, 90), (-0.62, -0.2, 90)):
		wedge((x, y, 0.0), 1.2, rot=(0, 0, a))


def hw_ingot_stack_empty():
	hw_ingot_stack(True)


def hw_overseer_platform():
	DZ = 1.0
	for x in (-0.7, 0.7):
		for y in (-0.45, 0.45):
			brick_pier(x, y, 0.3, 0.3, DZ - 0.06)
	top = DZ - 0.06 + 0.055
	for y in (-0.45, 0.45):
		B((1.7, 0.14, 0.14), (0, y, top + 0.065), W("b"), bevel=0.012)
	zd = top + 0.13
	for k in range(9):
		B((1.8 / 9 - 0.01, 1.2, 0.05), (-0.9 + 1.8 / 9 * (k + 0.5), 0, zd + 0.025), W(), bevel=0.008)
		for y in (-0.45, 0.45):
			sphere((-0.9 + 1.8 / 9 * (k + 0.5), y, zd + 0.05), 0.011, WD(), seg=8, rings=5)
	zt = zd + 0.05
	# railing on three sides
	posts = [(-0.85, -0.55), (0.0, -0.55), (-0.85, 0.55), (0.0, 0.55), (0.85, 0.55), (-0.85, 0.0)]
	for (x, y) in posts:
		B((0.08, 0.08, 0.97), (x, y, zt + 0.485 - 0.04), W("c"), bevel=0.01)
	B((0.95, 0.07, 0.06), (-0.425, -0.55, zt + 0.88), W("b"), bevel=0.008)
	B((1.76, 0.07, 0.06), (0.0, 0.55, zt + 0.88), W("b"), bevel=0.008)
	B((0.07, 1.04, 0.055), (-0.85, 0.0, zt + 0.875), W("a"), bevel=0.008)
	for y in (-0.55, 0.55):
		B((0.9 if y < 0 else 1.7, 0.05, 0.05), (-0.425 if y < 0 else 0.0, y, zt + 0.45), W("a"), bevel=0.006)
	B((0.05, 1.04, 0.05), (-0.85, 0.0, zt + 0.45), W("b"), bevel=0.006)
	# steps up on the right front
	for s_ in (-1, 1):
		y = -0.2 + s_ * 0.27
		beam((1.55, y, 0.05), (0.85, y, zt - 0.02), 0.06, 0.18, W("b"))
	for k in range(5):
		f = (k + 0.7) / 6
		B((0.22, 0.56, 0.04), (1.55 - 0.7 * f + 0.03, -0.2, 0.05 + (zt - 0.05) * f + 0.02), W(), bevel=0.006)
	B((0.2, 0.62, 0.05), (1.6, -0.2, 0.025), W("c"), bevel=0.008)
	# the overseer's standing desk: open ledger, ink pot and quill, a hand bell
	dx, dy = -0.35, 0.25
	tn = math.tan(math.radians(12))
	surf = lambda y: zt + 1.01 + (y - dy) * tn + 0.02 / math.cos(math.radians(12))  # noqa: E731
	for x in (dx - 0.25, dx + 0.25):
		for y in (dy - 0.15, dy + 0.15):
			hh = surf(y) - 0.02 - zt
			B((0.06, 0.06, hh), (x, y, zt + hh / 2), W("b"), bevel=0.008)
	B((0.5, 0.05, 0.05), (dx, dy - 0.15, zt + 0.25), W("c"), bevel=0.006)
	B((0.66, 0.44, 0.04), (dx, dy, zt + 1.01), W("a"), bevel=0.008, rot=(12, 0, 0))
	B((0.66, 0.03, 0.05), (dx, dy - 0.225, surf(dy - 0.215) - 0.005), WD(), bevel=0.005)
	B((0.44, 0.3, 0.012), (dx, dy + 0.01, surf(dy + 0.01) + 0.005), LEATHER(), bevel=0.003, rot=(12, 0, 0))
	for s_ in (-1, 1):
		B((0.2, 0.28, 0.012), (dx + s_ * 0.105, dy + 0.01, surf(dy + 0.01) + 0.016), C((0.62, 0.55, 0.4), 0.95), bevel=0.002, rot=(12, 0, 0))
		for k in range(5):
			y = dy - 0.08 + k * 0.04
			B((0.14, 0.004, 0.003), (dx + s_ * 0.105, y, surf(y) + 0.0225), C((0.12, 0.09, 0.07), 0.9), bevel=0, rot=(12, 0, 0))
	py = dy + 0.16
	B((0.66, 0.08, 0.03), (dx, py + 0.02, surf(py + 0.02) + 0.01), W("b"), bevel=0.005)  # the level back ledge
	lz = surf(py + 0.02) + 0.025
	pot((dx + 0.27, py + 0.02, lz - 0.003), 0.025, 0.04, CLAY(), t=0.005, seg=10, rim=False)
	rod((dx + 0.27, py + 0.02, lz + 0.01), (dx + 0.3, py + 0.05, lz + 0.13), 0.004, C((0.78, 0.72, 0.6), 0.9))
	bell((dx - 0.25, py + 0.02, lz - 0.002), 0.45, CU("b"))
	rod((dx - 0.25, py + 0.02, lz + 0.075), (dx - 0.25, py + 0.02, lz + 0.14), 0.008, W("c"))
	slim(small=0.03, fine=0.012, few=0.02)  # lighter file (under 2 MB), same look


def hw_signal_whistle():
	top = brick_pier(0, 0, 0.42, 0.42, 0.3)
	B((0.16, 0.16, 1.5 - top), (0, 0, (1.5 + top) / 2), W(), bevel=0.014)
	for dx in (-1, 1):
		beam((dx * 0.2, 0, top), (dx * 0.05, 0, top + 0.35), 0.08, 0.08, W("c"))
	# the wind box on two iron brackets, three copper whistle pipes on top
	B((0.5, 0.26, 0.2), (0, -0.04, 1.6), W("b"), bevel=0.012)
	for s_ in (-1, 1):
		B((0.5, 0.012, 0.03), (0, -0.04 + s_ * 0.134, 1.66), IRON("dark"), bevel=0.003)
		beam((s_ * 0.06, 0.0, 1.3), (s_ * 0.2, -0.04, 1.495), 0.03, 0.02, IRON("dark"), bevel=0.003)
	for k, (x, hp, r) in enumerate(((-0.15, 0.5, 0.04), (0.0, 0.4, 0.035), (0.15, 0.3, 0.03))):
		z0 = 1.7 - 0.004
		lathe([(r * 0.4, 0), (r, 0.06), (r, hp), (r * 0.7, hp + 0.004)], (x, -0.04, z0), CU("ab"[k % 2]), seg=14)
		kit.ring(r + 0.003, 0.004, (x, -0.04, z0 + hp - 0.01), CU("dark"), seg=14)
		pipe = kit.cylinder(r * 0.98, 0.001, (x, -0.04, z0 + 0.03), CU("dark"), verts=6, bevel=0) if False else None
		mouth = [B((r * 1.1, 0.04, 0.03), (x, -0.04 - r, z0 + 0.1), GROOVE(), bevel=0)]
		p_obj = [o for o in bpy.context.scene.objects if o.type == "MESH"]
		carve([o for o in p_obj if o.name.startswith("part") and abs(o.matrix_world.translation.x) < 1][-1:], mouth) if False else None
		B((r * 1.2, 0.012, 0.025), (x, -0.04 - r - 0.004, z0 + 0.1), GROOVE(), bevel=0)
		B((r * 1.2, 0.02, 0.012), (x, -0.04 - r - 0.004, z0 + 0.084), CU("dark"), bevel=0.002)
	# the bellows on the post: two boards, leather sides, a wind trunk up to the box
	by, bz = -0.22, 1.08
	B((0.36, 0.3, 0.03), (0, by, bz), W("a"), bevel=0.006)
	B((0.36, 0.3, 0.03), (0, by, bz + 0.16), W("c"), bevel=0.006, rot=(12, 0, 0))
	mesh([(-0.17, by - 0.14, bz + 0.012), (0.17, by - 0.14, bz + 0.012), (0.17, by + 0.14, bz + 0.012), (-0.17, by + 0.14, bz + 0.012),
		(-0.17, by - 0.14, bz + 0.17), (0.17, by - 0.14, bz + 0.17), (0.17, by + 0.14, bz + 0.12), (-0.17, by + 0.14, bz + 0.12)],
		[(0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)], LEATHER())
	B((0.08, 0.14, 0.06), (0, by + 0.15, bz + 0.03), W("b"), bevel=0.006)
	rod((0, by + 0.2, bz + 0.03), (0, -0.09, bz + 0.03), 0.03, CU("dark"), seg=10)
	rod((0, -0.13, bz + 0.03), (0, -0.13, 1.5), 0.03, CU("dark"), seg=10)
	kit.ring(0.034, 0.006, (0, -0.13, 1.2), CU("dark"), seg=12)
	B((0.06, 0.06, 0.06), (0, -0.13, bz + 0.03), CU("dark"), bevel=0.006)
	# the pull lever above the bellows and its chain with a handle ring
	B((0.06, 0.05, 0.12), (0.1, -0.1, 1.38), IRON("dark"), bevel=0.004)
	beam((0.12, -0.1, 1.42), (0.12, -0.55, 1.36), 0.05, 0.05, W("b"))
	rod((0.12, -0.32, 1.385), (0.08, -0.25, bz + 0.2), 0.008, IRON("dark"))
	chain((0.12, -0.53, 1.33), (0.12, -0.53, 1.0), link=0.022, wire=0.006)
	kit.ring(0.04, 0.01, (0.12, -0.53, 0.955), IRON("a"), rot=(90, 0, 0), seg=12)


def hw_spare_shaft():
	for x in (-0.65, 0.65):
		for dy in (-1, 1):
			beam((x, dy * 0.32, 0.03), (x, dy * 0.03, 0.62), 0.08, 0.08, W("c"))
		beam((x, -0.22, 0.22), (x, 0.22, 0.22), 0.06, 0.06, W("b"))
		B((0.12, 0.3, 0.1), (x, 0, 0.64), W("b"), bevel=0.01)
	sh = log((-1.05, 0, 0.81), (1.05, 0, 0.81), 0.12, W(), seg=8, rings=6, bend=0.004, end_m=W("c"))
	carve(sh, [B((0.085, 0.075, 0.12), (x, 0, 0.92), GROOVE(), bevel=0) for x in (0.2, 0.42)])
	carve(sh, [B((0.085, 0.12, 0.075), (x, -0.12, 0.81), GROOVE(), bevel=0) for x in (0.31,)])
	for x in (-1.0, -0.88, 0.88, 1.0):
		rod((x - 0.025, 0, 0.81), (x + 0.025, 0, 0.81), 0.138, IRON("dark"), seg=10)
	for x in (-0.45, -0.22, 0.0):
		tappet((x, 0, 0.88), rot=(0, 0, 0), s=0.9)
	tappet((-0.33, -0.07, 0.81), rot=(90, 0, 0), s=0.9)
	# loose tappets on the floor, a drawknife on the shaft, a mallet and shavings
	for k, (x, y, a) in enumerate(((0.3, -0.5, 10), (0.55, -0.45, 70), (-0.2, -0.55, -20))):
		group(lambda: tappet((0, 0, 0), rot=(0, 90, 0), s=0.9), at=(x, y, 0.036), rot=(0, 0, a))
	B((0.26, 0.012, 0.035), (0.62, -0.02, 0.935), IRON("a"), bevel=0.002, rot=(80, 0, 0))
	for s_ in (-1, 1):
		rod((0.62 + s_ * 0.13, -0.02, 0.935), (0.62 + s_ * 0.2, -0.08, 0.93), 0.014, W("c"), seg=7)
	mallet((-0.6, -0.5, 0.0), rotz=30)
	for k in range(12):
		a, d = k * 2.1, 0.15 + (k % 4) * 0.07
		B((0.035, 0.015, 0.004), (0.3 + math.cos(a) * d, -0.15 + math.sin(a) * d * 0.6, 0.002), W("c"), bevel=0, rot=(0, 0, k * 41))


def hw_plate_shears():
	# the shear block: a heavy squared timber bound with iron
	B((1.0, 0.36, 0.46), (0, 0, 0.23), W("b"), bevel=0.016)
	for x in (-0.4, 0.0, 0.4):
		B((0.05, 0.38, 0.012), (x, 0, 0.462), IRON("dark"), bevel=0.003) if False else None
		B((0.05, 0.012, 0.47), (x, -0.181, 0.235), IRON("dark"), bevel=0.003)
		for z in (0.1, 0.36):
			rivet((x, -0.189, z), IRON("a"), r=0.011)
	# the fixed lower blade along the front top edge, and the iron hinge cheeks at the left end
	B((0.84, 0.04, 0.06), (0.02, -0.16, 0.47), IRON("a"), bevel=0.003)
	for y in (-0.21, -0.09):
		B((0.14, 0.02, 0.3), (-0.42, y, 0.56), IRON("dark"), bevel=0.004)
	rod((-0.42, -0.24, 0.62), (-0.42, -0.06, 0.62), 0.022, IRON("a"))
	# the upper blade on its long lever, raised
	def lever():
		B((0.8, 0.035, 0.08), (0.4, 0, -0.03), IRON("a"), bevel=0.003)
		beam((0.0, 0, 0.0), (1.5, 0, 0.04), 0.07, 0.08, W("a"))
		for x in (0.2, 0.5, 0.8):
			B((0.05, 0.08, 0.1), (x, 0, 0.0), IRON("dark"), bevel=0.003)
		rod((1.25, 0, 0.04), (1.55, 0, 0.05), 0.035, W("c"), seg=8)
	group(lever, at=(-0.42, -0.15, 0.62), rot=(0, -16, 0))
	# a plate half cut on the block, the strip curling down; offcuts at its foot
	plate((0.05, -0.02, 0.506), 0.5, 0.3, 0.01)
	B((0.3, 0.01, 0.09), (0.2, -0.18, 0.46), IRON("b"), bevel=0.002, rot=(0, 0, 0)) if False else None
	B((0.25, 0.008, 0.05), (0.15, -0.2, 0.47), IRON("b"), bevel=0.002, rot=(-70, 0, 0))
	for k, (x, y, a) in enumerate(((0.2, -0.45, 10), (0.45, -0.5, 50), (-0.1, -0.42, -20), (0.32, -0.62, 80))):
		B((0.3 - k * 0.04, 0.05, 0.008), (x, y, 0.004 + (0.009 if k == 3 else 0)), IRON("abc"[k % 3]), bevel=0.002, rot=(0, 0, a))
	pot((0.75, -0.42, 0.0), 0.1, 0.12, W("b"), t=0.01, seg=14, rim=False)


MODELS = {name: fn for name, fn in globals().items() if name.startswith("hw_") and callable(fn)}

if __name__ == "__main__":
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	outdir = GAME / "assets" / "models" / "decor"
	jdir = GAME / "journey" / "3d" / "v2_hand_built" / "decor"
	outdir.mkdir(parents=True, exist_ok=True)
	jdir.mkdir(parents=True, exist_ok=True)
	for name in args or list(MODELS):
		rng.seed(sum(map(ord, name.removesuffix("_empty"))))  # an _empty twin gets the same wobble
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
