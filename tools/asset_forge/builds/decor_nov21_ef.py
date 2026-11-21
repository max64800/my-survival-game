# Decor set EF (Nov 21): EMBERDEEP FORGE, a BIG dungeon in clay brick and fire (Hearthbrick style): the great
# smithy of the deep, where master smiths made weapons. Abandoned long ago: everything is cold except the forge hearth.
# Materials: brick / brickochre bricks in pale lime mortar, limestone trim (cut carvings), one wood family ("wood"),
# iron, copper, leather; coal is near-black, glossy and angular. Owner round 3: nothing glows, the forge hearth is cold too.
# LOOTABLE (each also builds <id>_empty, same model with the loot gone; looting code comes later):
#   ef_coal_scuttle  -> 3 coal          ef_cooling_rack -> 1 stone sword (empty: the blades are gone)
#   ef_ingot_wall    -> amount not set by the owner yet (suggest 3 iron ingots)
#   blender --background --factory-startup --python builds/decor_nov21_ef.py -- [id ...]   (none = all)
# Output: assets/models/decor/<id>.glb (origin bottom-centre, front faces -Y in Blender = +Z in Godot).
# Wall pieces have a flat back at +Y (y = 0) so they sit flush on a wall.
#
# The 30 objects:
#  ef_tong_rack          (wall) brick panel, forged iron rail on two arms, seven tongs of different jaws hanging, ledge below
#  ef_hammer_rack        (wall) two wooden rail pairs on brackets, hammers hanging by their heads, biggest on top
#  ef_blade_rack         (wall) finished swords standing point-down in a slotted sill, held between iron pegs, copper tags
#  ef_master_display     (wall) the master's wall: crossed great swords behind a round shield, hammer and axe, a shelf
#                        with helm, gold cup and dagger, carved limestone lintel with his mark
#  ef_smiths_lintel      (wall) a long limestone lintel on brick corbels, eight smiths' marks cut into it, a rune row
#  ef_file_board         (wall) a plank tool board: files and rasps in a leather strap, punches and drifts in a drilled block
#  ef_mould_shelf        (wall) two shelves of clay casting moulds (ingot and sword cavities), crucibles, a hanging ladle
#  ef_chimney_hood       (wall) a riveted copper forge hood on iron straps, a brick flue above, a hook rail with tools
#  ef_ingot_wall         (wall) a wooden cubby rack, nine cells of crossed ingot stacks (iron, copper, a little gold)
#  ef_commission_board   (wall) a board of clay order tablets hung on copper pegs, each with a sketch cut into it
#  ef_blade_on_anvil     (story) a bare anvil on its banded stump, the hammer dropped beside it, an empty slack bucket
#  ef_cracked_quench     (story) a quench tub, a sword snapped in two: hilt half across the rim, the tip on the floor
#  ef_bent_blade_vise    (story) an apprentice's bench vise clamping a sword bent crooked, his split hammer below
#  ef_axe_progression    (story) a bench showing an axe being made in six steps, bar to finished axe, numbered tags
#  ef_fallen_hood        (story) a copper hood torn down, crumpled on its side among broken flue bricks and straps
#  ef_burst_crucible     (story) a cracked crucible in two halves, clay shards, dropped tongs, the empty mould it never filled
#  ef_broken_grindstone  (story) a grinding wheel snapped: half still on the axle, the other half fallen against the frame
#  ef_forge_hearth       a brick forge hearth: limestone rim, iron fire pot, a grate with cold coal (no fire), tuyere pipe, tool rail
#  ef_quench_trough      a brick quench trough with dark water, limestone rim, iron corner straps, a dipper on the rim
#  ef_grinding_wheel     a treadle grinding wheel: stone wheel on an iron axle, wooden frame, crank, copper drip pot
#  ef_swage_block        a heavy iron swage block with holes and edge grooves on a banded wooden stand, punches on top
#  ef_coal_bunker        a brick coal bunker heaped with angular black coal, a shovel stuck in it
#  ef_ember_pan          an iron ember pan on three legs, cold coals, a poker resting across the rim
#  ef_bar_stock_rack     a cantilever rack of long iron bars and copper rods, a bin of short bars at its foot
#  ef_apprentice_bench   a tidy apprentice bench: stake anvil, a row of half-made knives, nail header, tools in order
#  ef_cooling_rack       an iron cooling rack on brick feet, finished blades laid across (cold)
#  ef_whetstone_table    a sharpening table: whetstones in grit order, an oil flask, a leather strop, a blade
#  ef_scrap_bin          an iron-banded bin full of broken blades, offcuts and bent bars
#  ef_coal_scuttle       a copper coal scuttle heaped with coal and a small shovel, an iron fire shovel leaning on it
#  ef_ring_mandrel       a cone mandrel on a banded stump with finished rings slid down it, a small hammer on top
import math
import sys
from pathlib import Path

import bpy
from mathutils import Euler, Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from night_stations import B, GAME, J, T, kit, log, mesh, rng  # noqa: E402
from night_materials import C, sphere, _cm  # noqa: E402
from decor_nov21_a import slim, bar, carve, circ, groove, groove_path, low_z, prism, rest, rubble_heap, rune_row, spin, turn  # noqa: E402

WOOD = lambda v=None: T("wood", v)  # noqa: E731  (the one wood family)
IRON = lambda v="a": kit.tex_mat("iron", v)  # noqa: E731
STEEL = lambda: kit.tex_mat("silver", "b")  # noqa: E731
CU = lambda v="b": kit.tex_mat("copper", v)  # noqa: E731
LEA = lambda v="dark": kit.tex_mat("leather", v)  # noqa: E731
LIME = lambda v=None: T("limestone", v)  # noqa: E731
MORT = lambda: kit.tex_mat("limestone", "a")  # noqa: E731  (pale lime mortar)
CLAY = lambda v=None: T("clay", v)  # noqa: E731
GOLD = lambda: C((0.55, 0.4, 0.12), 0.4, metal=0.7)  # noqa: E731
COAL = lambda s=0.0: C((0.014 + s, 0.013 + s, 0.013 + s), 0.28)  # noqa: E731  (near-black, glossy)
GLINT = lambda: C((0.045, 0.047, 0.055), 0.1, metal=0.5)  # noqa: E731  (coal facets catching the light)
COALDUST = lambda: C((0.028, 0.025, 0.023), 0.95)  # noqa: E731
EMBER = lambda: kit.glow("ember", 1.4)  # noqa: E731
HOT = lambda: C((1.0, 0.42, 0.08), 0.4, glow=2.2)  # noqa: E731  (hot metal)
BED = lambda: C((0.45, 0.08, 0.02), 0.6, glow=1.0)  # noqa: E731  (the glowing coal bed under the forge fire)
WARM = lambda: C((0.55, 0.12, 0.03), 0.5, glow=0.8)  # noqa: E731  (cooling, dull red)
GROOVE = lambda: C((0.025, 0.02, 0.018), 1.0)  # noqa: E731  (dark walls of every cut)
WATER = lambda: C((0.04, 0.065, 0.07), 0.05)  # noqa: E731
DEEP = lambda: C((0.008, 0.017, 0.02), 0.02, metal=0.15)  # noqa: E731  (still, deep water: dark mirror)
MENISCUS = lambda: C((0.05, 0.085, 0.09), 0.03)  # noqa: E731
WETWOOD = lambda: C((0.035, 0.025, 0.018), 0.35)  # noqa: E731
GAP = 0.012  # mortar joint


# ================= helpers =================
def new_since(before):
	return [o for o in bpy.data.objects if o not in before]


def group(build, at=(0, 0, 0), rot=(0, 0, 0)):
	"""Build parts around the origin, then turn them (degrees, X then Y then Z) and move them to `at`."""
	before = set(bpy.data.objects[:])
	build()
	bpy.context.view_layer.update()
	M = Matrix.Translation(Vector(at)) @ Euler([math.radians(a) for a in rot]).to_matrix().to_4x4()
	new = new_since(before)
	for o in new:
		o.matrix_world = M @ o.matrix_world
	return new


def settle(objs_, z=0.0):
	"""Drop a group so its lowest point rests at z."""
	bpy.context.view_layer.update()
	dz = z - low_z(objs_)
	for o in objs_:
		o.location.z += dz
	return objs_


def rod(p0, p1, r, m, seg=8):
	return log(p0, p1, r, m, seg=seg, rings=1, ends=False, bend=0)


def cut(target, cutters):
	"""Cut each cutter INTO the target one at a time (joined overlapping cutters can wipe a part)."""
	for c in cutters:
		carve([target], [c])
	return target


def brick_m():
	r = rng.random()
	return T("brickochre") if r < 0.12 else (T("brick", "dark") if r < 0.2 else T("brick"))


def brick_row(a, b, z, ch, plane, axis="x", depth=0.055, sign=-1, off=0.0, bl=0.25):
	"""One course of bricks from a to b along an axis, outer face on `plane` (sign = the outward direction)."""
	edges, x = [], a - off * bl
	while x < b - 0.05:
		if x > a + 0.05:
			edges.append(x)
		x += bl * (1 + J(0.07))
	edges = [a] + edges + [b]
	for x0, x1 in zip(edges, edges[1:]):
		L = x1 - x0 - GAP
		if L < 0.04:
			continue
		c = (x0 + x1) / 2
		ctr = plane - sign * depth / 2 + sign * rng.uniform(-0.003, 0.004)
		size = (L, depth, ch - GAP) if axis == "x" else (depth, L, ch - GAP)
		loc = (c, ctr, z + J(0.002)) if axis == "x" else (ctr, c, z + J(0.002))
		B(size, loc, brick_m(), bevel=0.011)


def brick_box(w, d, h, at=(0, 0, 0), sides="fblr", ch=0.095):
	"""A solid brick mass: a mortar core with bricks laid in courses on the chosen sides (f b l r)."""
	x0, y0, z0 = at
	core = B((w - 0.07, d - 0.07, h - 0.004), (x0, y0, z0 + (h - 0.004) / 2), MORT(), bevel=0.004)
	n = max(1, round(h / ch))
	chh = h / n
	ya = y0 - d / 2 + (0.06 if "f" in sides else 0.035)
	yb = y0 + d / 2 - (0.06 if "b" in sides else 0.035)
	for i in range(n):
		z, off = z0 + chh * (i + 0.5), 0.5 * (i % 2)
		if "f" in sides:
			brick_row(x0 - w / 2, x0 + w / 2, z, chh, y0 - d / 2, "x", sign=-1, off=off)
		if "b" in sides:
			brick_row(x0 - w / 2, x0 + w / 2, z, chh, y0 + d / 2, "x", sign=1, off=off)
		if "l" in sides:
			brick_row(ya, yb, z, chh, x0 - w / 2, "y", sign=-1, off=0.5 - off)
		if "r" in sides:
			brick_row(ya, yb, z, chh, x0 + w / 2, "y", sign=1, off=0.5 - off)
	return core


def brick_wall(W, H, z0=0.0, x=0.0):
	"""A wall-piece backing: mortar core with its flat back at y = 0, bricks on the front. Returns the brick front y."""
	B((W - 0.03, 0.06, H - 0.01), (x, -0.03, z0 + (H - 0.01) / 2), MORT(), bevel=0.004)
	n = max(1, round(H / 0.095))
	ch = (H - 0.01) / n
	for i in range(n):
		brick_row(x - W / 2, x + W / 2, z0 + ch * (i + 0.5), ch, -0.1, "x", depth=0.05, sign=-1, off=0.5 * (i % 2))
	return -0.1


def lime_cap(W, H, d=0.14, h=0.08, x=0.0):
	"""A limestone cap on top of a wall backing (kept 3 mm off the wall plane)."""
	return B((W + 0.05, d, h), (x, -0.003 - d / 2, H + h / 2 - 0.012), LIME("a"), bevel=0.012)


MARKS = {
	"hammer": [[(-0.45, 0.25), (0.45, 0.25), (0.45, 0.55), (-0.45, 0.55), (-0.45, 0.25)], [(0, 0.25), (0, -0.6)]],
	"anvil": [[(-0.6, 0.3), (0.45, 0.3), (0.45, 0.08), (0.2, 0.0), (0.3, -0.45), (-0.3, -0.45), (-0.2, 0.0), (-0.3, 0.1), (-0.6, 0.3)]],
	"tongs": [[(-0.4, 0.6), (0.25, -0.5), (0.42, -0.32)], [(0.4, 0.6), (-0.25, -0.5), (-0.42, -0.32)]],
	"flame": [[(-0.45, -0.5), (-0.25, 0.05), (-0.05, -0.2), (0.05, 0.6), (0.22, 0.0), (0.45, -0.5), (-0.45, -0.5)]],
	"ring": [[(math.cos(a) * 0.3, 0.25 + math.sin(a) * 0.3) for a in [2 * math.pi * k / 10 for k in range(11)]], [(0, -0.05), (0, -0.6)], [(-0.25, -0.35), (0.25, -0.35)]],
	"peaks": [[(-0.6, -0.4), (-0.3, 0.35), (0, -0.1), (0.28, 0.55), (0.6, -0.4)], [(-0.6, -0.55), (0.6, -0.55)]],
	"xhammers": [[(-0.45, -0.55), (0.35, 0.4)], [(0.45, -0.55), (-0.35, 0.4)], [(0.15, 0.6), (0.55, 0.2)], [(-0.15, 0.6), (-0.55, 0.2)]],
	"eye": [[(-0.55, 0), (0, 0.38), (0.55, 0), (0, -0.38), (-0.55, 0)], [(-0.12, 0), (0, 0.12), (0.12, 0), (0, -0.12), (-0.12, 0)]],
}


def mark(kind, cx, cz, s, yf, w=0.013, depth=0.01, box=False):
	"""Cutters for one smith's mark (and an optional square cartouche) on a front face at y = yf."""
	out = []
	for line in MARKS[kind]:
		out += groove_path([(cx + x * s, cz + z * s) for x, z in line], yf, w, depth)
	if box:
		k = 0.82 * s
		out += groove_path([(cx - k, cz - k), (cx + k, cz - k), (cx + k, cz + k), (cx - k, cz + k), (cx - k, cz - k)], yf, w * 0.8, depth * 0.8)
	return out


def turned(prof, c, m, seg=18, a0=0.0, a1=360.0, smooth=False):
	"""A turned solid from a CLOSED profile loop [(r, z)...] (outer up, inner down), spun around z at c = (x, y, z).
	A partial turn (a1 - a0 < 360) is closed with the profile shape at both cut ends (a broken pot)."""
	full = a1 - a0 >= 359.9
	ns = seg if full else seg + 1
	x0, y0, z0 = c
	v = []
	for k in range(ns):
		a = math.radians(a0 + (a1 - a0) * k / seg)
		v += [(x0 + math.cos(a) * r, y0 + math.sin(a) * r, z0 + z) for r, z in prof]
	n = len(prof)
	f = [(k * n + i, k * n + (i + 1) % n, ((k + 1) % ns) * n + (i + 1) % n, ((k + 1) % ns) * n + i) for k in range(seg) for i in range(n)]
	if not full:
		f += [tuple(range(n)), tuple(range(seg * n, seg * n + n))]
	return mesh(v, f, m, smooth=smooth)


def coal_heap(cx, cy, z, rx, ry, H, n=60, embers=0, seed=1, smax=0.09, smin=0.025, fines=0, dirt=None):
	"""A settled heap of angular black coal (every `embers`-th lump glows), plus `fines` small glossy chips and
	flat slivers scattered over its surface (owner: more detail on the coal)."""
	tones = [COAL(0.0), COAL(0.008), COAL(-0.004), COAL(0.014), COAL(0.004), GLINT()]
	if embers:
		tones = tones[:embers - 1] + [EMBER()]

	def build():
		h = rubble_heap(0, 0, rx, ry, H, tones, n=n, smax=smax, smin=smin, dirt=dirt or COALDUST(), seed=seed)
		r = __import__("random").Random(seed + 77)
		for i in range(fines):
			a, d = r.uniform(0, 2 * math.pi), math.sqrt(r.uniform(0, 1)) * 0.9
			x, y = math.cos(a) * rx * d, math.sin(a) * ry * d
			s = r.uniform(0.01, 0.036)
			flat = r.random() < 0.3
			o = kit.gem((0, 0, 0), (s * r.uniform(0.9, 1.4), s * r.uniform(0.6, 1.0), s * (0.22 if flat else 0.55)),
				tones[(i * 7) % len(tones)], seed=seed * 300 + i)
			spin(o, r.uniform(-30, 30), r.uniform(-30, 30), r.uniform(0, 360))
			o.location = (x, y, h(x, y) * 0.9 + s * 0.2)
	return group(build, at=(cx, cy, z))


def coal_bits(pts, z, s=0.03, seed=1):
	"""Loose coal lumps resting on a surface at height z."""
	for i, (x, y) in enumerate(pts):
		o = kit.gem((x, y, z + s * 0.3), (s * (0.8 + 0.4 * rng.random()), s * (0.7 + 0.3 * rng.random()), s * 0.55), COAL(0.006 * (i % 3)), seed=seed + i)
		spin(o, J(20), J(20), J(180))
		rest(o, z - 0.002 if z > 0 else 0.0)


# ---------------- tools (built around the origin) ----------------
def tongs(L=0.5, jaw="flat", hook=True, m=None):
	"""Smith's tongs in the x-z plane: jaws at the bottom (z ~ 0), pivot, reins up to z = L (ring loop on top)."""
	m = m or IRON("dark")
	pz = 0.13
	top = L - (0.035 if hook else 0.0)
	for s in (-1, 1):
		rod((s * 0.01, s * 0.004, pz), (s * (0.009 if hook else 0.03), s * 0.004, top), 0.0075, m, seg=6)
		rod((s * 0.01, s * 0.004, pz), (-s * 0.016, s * 0.004, 0.03), 0.009, m, seg=6)
		if jaw == "flat":
			B((0.012, 0.027, 0.055), (-s * 0.013, s * 0.004, 0.03), m, bevel=0.003)
		elif jaw == "bolt":
			kit.ring(0.014, 0.0055, (-s * 0.022, s * 0.004, 0.03), m, rot=(90, 0, 0), seg=10)
		elif jaw == "ring":
			kit.ring(0.03, 0.006, (-s * 0.03, s * 0.004, 0.035), m, rot=(90, 0, 0), seg=14)
		else:
			kit.cone(0.009, 0.002, 0.05, (-s * 0.012, s * 0.004, 0.012), m, verts=6, bevel=0.001)
		if not hook:
			sphere((s * 0.03, s * 0.004, top), 0.011, m)
	kit.cylinder(0.018, 0.032, (0, 0, pz), m, rot=(90, 0, 0), verts=10, bevel=0.003)
	for s in (-1, 1):
		sphere((0, s * 0.016, pz), 0.009, IRON("a"))
	if hook:
		kit.ring(0.028, 0.007, (0, 0, L - 0.004), m, rot=(0, 90, 0), seg=12)


def hammer(hl=0.3, hw=0.13, hs=0.045, kind="cross"):
	"""A hammer with its handle along +z from z = 0 and the head (along x) on top."""
	B((0.028, 0.024, hl), (0, 0, hl / 2), WOOD("b"), bevel=0.006)
	for k in range(3):
		kit.ring(0.019, 0.0045, (0, 0, 0.03 + k * 0.025), LEA(), seg=10)
	zc = hl + hs / 2 - 0.012
	B((hw, hs, hs), (0, 0, zc), IRON("dark"), bevel=0.007)
	kit.cylinder(hs * 0.6, 0.022, (-hw / 2 - 0.007, 0, zc), IRON("a"), rot=(0, 90, 0), verts=10, bevel=0.004)
	if kind == "cross":
		B((0.034, hs * 1.02, hs * 0.32), (hw / 2 + 0.01, 0, zc), IRON("a"), bevel=0.006)
	elif kind == "ball":
		sphere((hw / 2 + 0.014, 0, zc), hs * 0.56, IRON("a"))
	else:
		kit.cylinder(hs * 0.6, 0.022, (hw / 2 + 0.007, 0, zc), IRON("a"), rot=(0, 90, 0), verts=10, bevel=0.004)
	B((0.006, 0.026, 0.008), (0, 0, zc + hs / 2 + 0.001), WOOD("dark"), bevel=0.001)


def fine(pts, step=0.04):
	"""Extra points along each edge of an outline (so it can be bent smoothly)."""
	out = []
	for a, b in zip(pts, pts[1:] + pts[:1]):
		n = max(1, int(math.hypot(b[0] - a[0], b[1] - a[1]) / step))
		out += [(a[0] + (b[0] - a[0]) * k / n, a[1] + (b[1] - a[1]) * k / n) for k in range(n)]
	return out


def sword(L=0.85, w=0.055, guard=0.18, pommel="disc", blade_m=None, grip=True, cut_at=None, ridge=True, smooth=False):
	"""A sword in the x-z plane, grip bottom at z = 0, point up. cut_at = a z where the blade is snapped off."""
	bm = blade_m or STEEL()
	if grip:
		kit.cylinder(0.017, 0.13, (0, 0, 0.065), LEA(), verts=8, bevel=0.004)
		for k in range(4):
			kit.ring(0.0185, 0.0035, (0, 0, 0.022 + k * 0.03), LEA("b"), seg=10)
		if pommel == "disc":
			kit.cylinder(0.034, 0.026, (0, 0, -0.008), IRON("dark"), rot=(90, 0, 0), verts=12, bevel=0.005)
		else:
			sphere((0, 0, -0.012), 0.03, IRON("dark"), scale=(1, 0.8, 1))
		B((guard, 0.036, 0.03), (0, 0, 0.14), IRON("dark"), bevel=0.008)
		for s in (-1, 1):
			sphere((s * guard / 2, 0, 0.14), 0.02, IRON("dark"))
	if cut_at is None:
		pts = [(-w / 2, 0.15), (w / 2, 0.15), (w * 0.42, L - 0.13), (0, L), (-w * 0.42, L - 0.13)]
	else:
		pts = [(-w / 2, 0.15), (w / 2, 0.15), (w / 2 * 0.95, cut_at + 0.012), (w * 0.15, cut_at - 0.01), (-w * 0.1, cut_at + 0.02),
			(-w / 2 * 0.95, cut_at - 0.006)]
	ff = fine if smooth else (lambda p: p)
	prism(ff(pts), -0.006, 0.006, bm)
	if ridge:
		z1 = (L - 0.18) if cut_at is None else cut_at - 0.03
		prism(ff([(-0.006, 0.17), (0.006, 0.17), (0.006, z1), (-0.006, z1)]), -0.0085, 0.0085, IRON("dark") if blade_m is None else bm)


def sword_tip(L0, L=0.85, w=0.055, bm=None):
	"""The snapped-off upper part of a sword blade (from the break at z = L0 to the point)."""
	bm = bm or STEEL()
	prism([(-w / 2 * 0.95, L0 - 0.006), (-w * 0.1, L0 + 0.02), (w * 0.15, L0 - 0.01), (w / 2 * 0.95, L0 + 0.012), (w * 0.42, L - 0.13), (0, L),
		(-w * 0.42, L - 0.13)], -0.006, 0.006, bm)
	prism([(-0.006, L0 + 0.03), (0.006, L0 + 0.03), (0.006, L - 0.18), (-0.006, L - 0.18)], -0.0085, 0.0085, IRON("dark"))


def axe(hl=0.6, m=None):
	"""A bearded axe, handle along +z from z = 0, blade toward +x."""
	m = m or IRON("dark")
	B((0.034, 0.03, hl), (0, 0, hl / 2), WOOD("b"), bevel=0.008)
	for k in range(4):
		kit.ring(0.023, 0.005, (0, 0, 0.04 + k * 0.03), LEA(), seg=10)
	B((0.062, 0.05, 0.1), (0, 0, hl - 0.05), m, bevel=0.01)
	prism([(0.025, hl - 0.085), (0.15, hl - 0.18), (0.19, hl - 0.07), (0.17, hl + 0.05), (0.025, hl - 0.015)], -0.012, 0.012, m)
	prism([(0.1528, hl - 0.181), (0.1935, hl - 0.0705), (0.173, hl + 0.0505), (0.158, hl + 0.03), (0.175, hl - 0.07), (0.142, hl - 0.155)], -0.0145, 0.0145, STEEL())
	B((0.045, 0.046, 0.055), (-0.045, 0, hl - 0.05), m, bevel=0.008)
	B((0.008, 0.032, 0.008), (0, 0, hl + 0.001), WOOD("dark"), bevel=0.001)


def file_tool(L=0.25, w=0.022):
	"""A file: wooden handle at the bottom (z 0..0.08), copper ferrule, toothed iron blade up to z = L + 0.08."""
	kit.cylinder(0.016, 0.085, (0, 0, 0.0425), WOOD("b"), verts=8, bevel=0.004)
	kit.cylinder(0.018, 0.016, (0, 0, 0.085), CU(), verts=8, bevel=0.002)
	B((w, 0.008, L), (0, 0, 0.09 + L / 2), IRON("a"), bevel=0.002)
	for k in range(int(L / 0.022)):
		B((w + 0.005, 0.013, 0.004), (0, 0, 0.11 + k * 0.022), IRON("dark"), bevel=0.0)


def punch(L=0.18, r=0.012, tip="point"):
	"""A punch or drift standing up: the struck head is mushroomed from use."""
	kit.cylinder(r, L, (0, 0, L / 2), IRON("dark"), verts=8, bevel=0.002)
	kit.cylinder(r * 1.35, 0.012, (0, 0, L - 0.002), IRON("a"), verts=8, bevel=0.004)
	if tip == "point":
		kit.cone(r, r * 0.25, 0.04, (0, 0, -0.018), IRON("a"), rot=(180, 0, 0), verts=8, bevel=0.001)


def shield(R=0.3, t=0.03):
	"""A round shield in the x-z plane (front -Y): planks, iron rim, boss, cross band, rivets."""
	n = 5
	for i in range(n):
		x0, x1 = -R + 2 * R * i / n + 0.004, -R + 2 * R * (i + 1) / n - 0.004
		xs = [x0 + (x1 - x0) * k / 4 for k in range(5)]
		lo = [(x, -math.sqrt(max(R * R - x * x, 0.0004)) * 0.97) for x in xs]
		hi = [(x, math.sqrt(max(R * R - x * x, 0.0004)) * 0.97) for x in reversed(xs)]
		prism(lo + hi, -t / 2, t / 2, WOOD(), axis="y")
	kit.ring(R, 0.02, (0, 0, 0), IRON("dark"), rot=(90, 0, 0), seg=32)
	B((2 * R - 0.05, 0.008, 0.045), (0, -t / 2 - 0.002, 0), IRON("dark"), bevel=0.003)
	kit.cylinder(0.1, 0.012, (0, -t / 2 - 0.004, 0), IRON("dark"), rot=(90, 0, 0), verts=16, bevel=0.003)
	sphere((0, -t / 2 - 0.012, 0), 0.07, IRON("a"), scale=(1, 0.6, 1))
	for k in range(12):
		a = 2 * math.pi * k / 12
		kit.rivet((math.cos(a) * (R - 0.035), -t / 2 - 0.001, math.sin(a) * (R - 0.035)), CU("dark"), r=0.011)


def anvil(s=1.0):
	"""A smith's anvil standing on z = 0, horn to -x. Returns the face top height."""
	kit.taper(0.34 * s, 0.26 * s, 0.22 * s, 0.15 * s, 0.07 * s, (0, 0, 0), IRON("dark"))
	kit.taper(0.22 * s, 0.15 * s, 0.16 * s, 0.11 * s, 0.15 * s, (0, 0, 0.065 * s), IRON("dark"))
	kit.taper(0.16 * s, 0.11 * s, 0.36 * s, 0.15 * s, 0.08 * s, (0.01 * s, 0, 0.21 * s), IRON("dark"))
	B((0.42 * s, 0.15 * s, 0.07 * s), (0.02 * s, 0, 0.32 * s), IRON("dark"), bevel=0.01)
	face = B((0.4 * s, 0.136 * s, 0.022 * s), (0.02 * s, 0, 0.36 * s), IRON("b"), bevel=0.005)
	kit.cone(0.06 * s, 0.008 * s, 0.26 * s, (-0.3 * s, 0, 0.33 * s), IRON("dark"), rot=(0, -90, 0), verts=12)
	B((0.07 * s, 0.11 * s, 0.05 * s), (0.255 * s, 0, 0.335 * s), IRON("dark"), bevel=0.008)
	cut(face, [B((0.024 * s, 0.024 * s, 0.05), (0.16 * s, 0, 0.37 * s), GROOVE(), bevel=0),
		kit.cylinder(0.008 * s, 0.05, (0.1 * s, 0, 0.37 * s), GROOVE(), verts=8, bevel=0)])
	for x in (-1, 1):
		for y in (-1, 1):
			B((0.06 * s, 0.05 * s, 0.03 * s), (x * 0.15 * s, y * 0.11 * s, 0.018 * s), IRON("dark"), bevel=0.005)
	return 0.371 * s


def stump(r=0.24, h=0.5, bands=(0.08, 0.4)):
	"""A wooden block stump with iron bands (flat bottom, so it never sinks)."""
	kit.cylinder(r, h, (0, 0, h / 2), WOOD("c"), verts=14, bevel=0.01)
	kit.cylinder(r * 0.86, 0.012, (0, 0, h + 0.001), WOOD("b"), verts=14, bevel=0.003)
	for z in bands:
		kit.ring(r + 0.004, 0.011, (0, 0, z), IRON("dark"), seg=24)
		for k in range(4):
			a = 2 * math.pi * (k + 0.5) / 4
			kit.rivet((math.cos(a) * (r + 0.014), math.sin(a) * (r + 0.014), z), IRON("a"), r=0.009)


def bench(W=1.1, D=0.42, H=0.7, shelf=True):
	"""A heavy wooden bench: plank top, four square legs, stretchers, an optional low shelf. Returns the top height."""
	for x in (-W / 2 + 0.07, W / 2 - 0.07):
		for y in (-D / 2 + 0.06, D / 2 - 0.06):
			B((0.07, 0.07, H - 0.05), (x, y, (H - 0.05) / 2), WOOD("dark"), bevel=0.008)
		B((0.05, D - 0.1, 0.06), (x, 0, 0.16), WOOD("dark"), bevel=0.006)
	n = 3
	for i in range(n):
		B((W, D / n - 0.008, 0.055), (0, -D / 2 + D / n * (i + 0.5), H - 0.0275), WOOD(), bevel=0.008)
	for y in (-D / 2 + 0.06, D / 2 - 0.06):
		B((W - 0.18, 0.04, 0.07), (0, y, H - 0.085), WOOD("dark"), bevel=0.006)
	if shelf:
		for i in range(2):
			B((W - 0.2, (D - 0.14) / 2 - 0.006, 0.03), (0, -(D - 0.14) / 4 + (D - 0.14) / 2 * i, 0.205), WOOD(), bevel=0.006)
	for x in (-W / 2 + 0.07, W / 2 - 0.07):
		for y in (-D / 2 + 0.06, D / 2 - 0.06):
			kit.rivet((x, y, H + 0.001), IRON("dark"), r=0.011)
	return H


def ingot(m, L=0.14, w=0.055, h=0.034):
	"""A cast ingot (wide at the bottom, sloping sides), standing on z = 0."""
	kit.taper(L, w, L - 0.025, w - 0.018, h, (0, 0, 0), m, bevel=0.004)


def hood_shell(w0, d0, w1, d1, h, t, m, z0=0.0, yb=0.0):
	"""An open hood: a hollow frustum from a w0 x d0 mouth (z0) to a w1 x d1 neck, its back side flat at y = yb."""
	def rect(w, d, z, k):
		return [(-w / 2 + k, yb - d + k, z), (w / 2 - k, yb - d + k, z), (w / 2 - k, yb - k, z), (-w / 2 + k, yb - k, z)]
	v = rect(w0, d0, z0, 0) + rect(w1, d1, z0 + h, 0) + rect(w0, d0, z0, t) + rect(w1, d1, z0 + h, t)
	f = []
	for i in range(4):
		j = (i + 1) % 4
		f += [(i, j, 4 + j, 4 + i), (8 + i, 12 + i, 12 + j, 8 + j), (i, 8 + i, 8 + j, j), (4 + i, 4 + j, 12 + j, 12 + i)]
	return mesh(v, f, m)


def tag_plate(x, y, z, w=0.07, h=0.045, m=None):
	"""A small riveted copper tag on a front face at y."""
	B((w, 0.008, h), (x, y - 0.002, z), m or CU(), bevel=0.003)
	for s in (-1, 1):
		kit.rivet((x + s * (w / 2 - 0.012), y - 0.006, z), CU("dark"), r=0.006)


# ================= wall pieces =================
def ef_tong_rack():
	W, H = 1.2, 1.25
	yf = brick_wall(W, H)
	cap = lime_cap(W, H)
	cut(cap, mark("tongs", 0, H + 0.028, 0.042, -0.143, w=0.015))
	zr = 1.0
	for x in (-0.5, 0.5):
		B((0.06, 0.012, 0.18), (x, yf - 0.002, zr - 0.04), IRON("dark"), bevel=0.003)
		for z in (zr - 0.1, zr + 0.03):
			kit.rivet((x, yf - 0.008, z), IRON("a"), r=0.01)
		rod((x, yf - 0.005, zr), (x, yf - 0.13, zr), 0.013, IRON("dark"))
		rod((x, yf - 0.005, zr - 0.11), (x, yf - 0.1, zr - 0.01), 0.009, IRON("dark"))
	rod((-0.56, yf - 0.11, zr), (0.56, yf - 0.11, zr), 0.015, IRON("dark"))
	for s in (-1, 1):
		kit.cone(0.024, 0.004, 0.05, (s * 0.58, yf - 0.11, zr), IRON("a"), rot=(0, s * 90, 0), verts=8, bevel=0.002)
	jaws = ["flat", "bolt", "pick", "ring", "flat", "bolt", "pick"]
	for i in range(7):
		x = -0.42 + 0.14 * i
		L = 0.46 + 0.14 * ((i * 3) % 4) / 3
		group(lambda L=L, j=jaws[i]: tongs(L, j), at=(x, yf - 0.11, zr - 0.012 - L), rot=(0, 0, J(3)))
	# low limestone ledge on two brick corbels: a copper oil pot, spare tong rings, a wire brush
	B((0.9, 0.17, 0.05), (0, yf - 0.083, 0.3), LIME("b"), bevel=0.01)
	for x in (-0.36, 0.36):
		B((0.13, 0.12, 0.07), (x, yf - 0.058, 0.243), brick_m(), bevel=0.01)
		B((0.13, 0.07, 0.07), (x, yf - 0.033, 0.17), brick_m(), bevel=0.01)
	turned([(0.05, 0.0), (0.062, 0.05), (0.055, 0.1), (0.06, 0.11), (0.048, 0.112), (0.044, 0.02), (0.004, 0.02), (0.004, 0.0)], (-0.22, yf - 0.085, 0.323), CU())
	kit.cylinder(0.044, 0.012, (-0.22, yf - 0.085, 0.4), COAL(0.03), verts=12, bevel=0)
	for k in range(3):
		kit.ring(0.03, 0.007, (0.02 + k * 0.075, yf - 0.09, 0.332), IRON("dark"), seg=12)
	B((0.16, 0.035, 0.03), (0.32, yf - 0.09, 0.34), WOOD("b"), bevel=0.006)
	for k in range(7):
		B((0.012, 0.03, 0.022), (0.27 + k * 0.016, yf - 0.09, 0.362), IRON("a"), bevel=0)


def ef_hammer_rack():
	W, H = 1.1, 1.3
	yf = brick_wall(W, H)
	cap = lime_cap(W, H)
	cut(cap, mark("hammer", 0, H + 0.028, 0.042, -0.143, w=0.015))

	def rails(z, w):
		for x in (-w / 2, w / 2):
			prism([(yf + 0.005, z + 0.02), (yf - 0.175, z + 0.02), (yf - 0.175, z - 0.02), (yf + 0.005, z - 0.2)], x - 0.022, x + 0.022, WOOD("dark"), axis="x")
			kit.rivet((x, yf - 0.16, z), IRON("dark"), r=0.01)
		for y in (yf - 0.035, yf - 0.15):
			B((w + 0.04, 0.035, 0.045), (0, y, z), WOOD(), bevel=0.007)
		return z + 0.0225

	top = rails(0.98, 0.98)
	kinds = ["sledge", "cross", "ball", "cross", "sledge", "ball"]
	for i in range(6):
		x = -0.4 + 0.16 * i
		hl, hw, hs = 0.32 + 0.03 * (i % 3), 0.15 - 0.006 * (i % 3), 0.05 - 0.004 * (i % 2)
		group(lambda hl=hl, hw=hw, hs=hs, k=kinds[i]: hammer(hl, hw, hs, k), at=(x, yf - 0.0925, top - (hl - 0.012 - 0.004)), rot=(0, 0, 90))
	top = rails(0.52, 0.78)
	for i in range(5):
		x = -0.32 + 0.16 * i
		hl = 0.22 + 0.02 * (i % 2)
		group(lambda hl=hl, k=("ball", "cross")[i % 2]: hammer(hl, 0.125, 0.036, k), at=(x, yf - 0.0925, top - (hl - 0.012 - 0.004)), rot=(0, 0, 90))
	for x in (-0.28, 0.28):
		tag_plate(x, yf - 0.1675, 0.98)


def ef_blade_rack():
	W, H = 1.3, 1.5
	yf = brick_wall(W, H)
	cap = lime_cap(W, H)
	cut(cap, mark("xhammers", 0, H + 0.028, 0.042, -0.143, w=0.015))
	for x in (-0.52, 0.52):
		B((0.13, 0.17, 0.18), (x, yf - 0.08, 0.09), LIME("c"), bevel=0.012)
	sill = B((W - 0.06, 0.16, 0.09), (0, yf - 0.083, 0.222), WOOD("dark"), bevel=0.01)
	xs = [-0.5 + 0.2 * i for i in range(6)]
	cut(sill, [B((0.07, 0.022, 0.06), (x, yf - 0.083, 0.267), GROOVE(), bevel=0) for x in xs])
	B((W - 0.1, 0.05, 0.06), (0, yf - 0.024, 0.86), WOOD(), bevel=0.008)
	for x in (-0.6, 0.6):
		kit.rivet((x * 0.95, yf - 0.05, 0.86), IRON("dark"), r=0.012)
	styles = [(0.86, 0.056, 0.2, "disc"), (0.94, 0.062, 0.22, "ball"), (0.78, 0.05, 0.17, "disc"), (0.9, 0.06, 0.24, "ball"),
		(0.82, 0.054, 0.19, "disc"), (0.72, 0.046, 0.15, "ball")]
	for x, (L, w, g, p) in zip(xs, styles):
		group(lambda L=L, w=w, g=g, p=p: sword(L, w, g, p), at=(x, yf - 0.083, 0.267 - 0.035 + L), rot=(0, 180, 0))
		for s in (-1, 1):
			rod((x + s * (w / 2 + 0.011), yf - 0.05, 0.86), (x + s * (w / 2 + 0.011), yf - 0.125, 0.865), 0.01, WOOD("dark"), seg=6)
			sphere((x + s * (w / 2 + 0.011), yf - 0.127, 0.865), 0.014, WOOD("dark"))
		tag_plate(x, yf - 0.163, 0.215, w=0.06, h=0.04)


def ef_master_display():
	W, H = 1.6, 1.8
	yf = brick_wall(W, H)
	for s in (-1, 1):
		B((0.14, 0.06, H - 0.03), (s * (W / 2 - 0.08), yf - 0.025, (H - 0.03) / 2 + 0.01), LIME("b"), bevel=0.012)
		B((0.18, 0.08, 0.1), (s * (W / 2 - 0.08), yf - 0.042, 0.05), LIME("c"), bevel=0.012)
	lin = B((W + 0.08, 0.17, 0.22), (0, -0.088, H + 0.098), LIME("a"), bevel=0.014)
	cuts = mark("anvil", 0, H + 0.1, 0.07, -0.173, w=0.016, depth=0.012, box=True)
	cuts += rune_row(-0.68, -0.14, H + 0.1, -0.173, h=0.07, seed=7) + rune_row(0.14, 0.68, H + 0.1, -0.173, h=0.07, seed=8)
	cut(lin, cuts)
	# crossed great swords behind the round shield
	cz = 1.08
	for th, ys in ((38, 0.02), (-38, 0.038)):
		L = 1.1
		mid = 0.52
		at = (-mid * math.sin(math.radians(th)), yf - ys, cz - mid * math.cos(math.radians(th)))
		group(lambda L=L: sword(L, 0.07, 0.26, "ball"), at=at, rot=(0, th, 0))
	group(lambda: shield(0.3, 0.03), at=(0, yf - 0.066, cz))
	for s in (-1, 1):  # iron hooks under the pommels
		x = s * 0.33
		B((0.03, 0.05, 0.03), (x, yf - 0.02, 0.62), IRON("dark"), bevel=0.004)
	# war hammer (left) and axe (right) hung on pegs
	group(lambda: hammer(0.82, 0.2, 0.07, "sledge"), at=(-0.6, yf - 0.035, 0.42))
	group(lambda: axe(0.8), at=(0.6, yf - 0.035, 0.42), rot=(0, 0, 180))
	for x in (-0.6, 0.6):
		for z in (0.62, 1.05):
			rod((x - 0.03, yf + 0.005, z), (x - 0.03, yf - 0.075, z), 0.011, WOOD("dark"), seg=6)
			rod((x + 0.03, yf + 0.005, z), (x + 0.03, yf - 0.075, z), 0.011, WOOD("dark"), seg=6)
	# limestone shelf on corbels: dagger on its stand, a helm, a gold cup
	z = 0.5
	B((0.9, 0.22, 0.06), (0, yf - 0.105, z), LIME("a"), bevel=0.012)
	for x in (-0.36, 0.36):
		prism([(yf + 0.005, z - 0.03), (yf - 0.16, z - 0.03), (yf + 0.005, z - 0.2)], x - 0.05, x + 0.05, LIME("c"), axis="x")
	plate = B((0.42, 0.012, 0.06), (0, yf - 0.219, z), CU("b"), bevel=0.003)
	cut(plate, rune_row(-0.18, 0.18, z, yf - 0.225, h=0.04, w=0.008, depth=0.004, seed=11))
	zt = z + 0.03
	for x in (-0.36, -0.22):
		prism([(yf - 0.1 + y, zt - 0.003 + z) for y, z in ((-0.03, 0), (0.03, 0), (0.03, 0.06), (0.01, 0.045), (-0.01, 0.045), (-0.03, 0.06))],
			x - 0.02, x + 0.02, WOOD("dark"), axis="x")
	group(lambda: sword(0.36, 0.034, 0.1, "ball"), at=(-0.45, yf - 0.1, zt + 0.042), rot=(0, 90, 0))
	# helm
	hx = 0.02
	turned([(0.12, 0.0), (0.122, 0.07), (0.1, 0.14), (0.055, 0.175), (0.004, 0.185), (0.004, 0.17), (0.05, 0.16), (0.09, 0.13), (0.11, 0.07), (0.108, 0.0)],
		(hx, yf - 0.1, zt), IRON("b"), seg=20, smooth=True)
	kit.ring(0.122, 0.012, (hx, yf - 0.1, zt + 0.03), IRON("dark"), seg=20)
	B((0.03, 0.02, 0.1), (hx, yf - 0.222, zt + 0.06), IRON("dark"), bevel=0.006)
	B((0.012, 0.21, 0.035), (hx, yf - 0.1, zt + 0.165), IRON("dark"), bevel=0.004, rot=(0, 0, 0))
	for k in range(8):
		a = 2 * math.pi * k / 8
		kit.rivet((hx + math.cos(a) * 0.126, yf - 0.1 + math.sin(a) * 0.126, zt + 0.03), CU("dark"), r=0.008)
	# gold cup
	turned([(0.04, 0.0), (0.042, 0.008), (0.014, 0.02), (0.011, 0.07), (0.04, 0.09), (0.05, 0.15), (0.044, 0.15), (0.036, 0.096), (0.004, 0.092),
		(0.004, 0.0)], (0.3, yf - 0.1, zt - 0.002), GOLD(), seg=16, smooth=True)
	kit.ring(0.049, 0.005, (0.3, yf - 0.1, zt + 0.13), GOLD(), seg=16)
	slim(small=0.03, fine=0.012, few=0.02)  # lighter file (under 2 MB), same look


def ef_smiths_lintel():
	L = 1.7
	for s in (-1, 1):
		x = s * (L / 2 - 0.16)
		for k in range(3):
			B((0.27, 0.07 + 0.045 * k, 0.075), (x, -0.007 - (0.07 + 0.045 * k) / 2, 0.04 + 0.08 * k), brick_m(), bevel=0.01)
	lin = B((L, 0.2, 0.34), (0, -0.103, 0.234 + 0.17), LIME("b"), bevel=0.016)
	yf = -0.203
	kinds = ["hammer", "anvil", "tongs", "flame", "ring", "peaks", "xhammers", "eye"]
	cuts = []
	for i, k in enumerate(kinds):
		cuts += mark(k, -0.7 + 0.2 * i, 0.47, 0.055, yf, w=0.012, depth=0.011, box=True)
	cuts += rune_row(-0.74, 0.74, 0.31, yf, h=0.055, w=0.011, seed=21)
	cuts += groove_path([(-0.8, 0.37), (0.8, 0.37)], yf, 0.01, 0.008) + groove_path([(-0.8, 0.565), (0.8, 0.565)], yf, 0.01, 0.008)
	cuts += [kit.gem((0.84, -0.2, 0.57), (0.05, 0.05, 0.04), LIME("a"), seed=3), kit.gem((-0.84, -0.2, 0.25), (0.04, 0.05, 0.05), LIME("a"), seed=4)]
	cut(lin, cuts)


def ef_file_board():
	W, H = 1.0, 0.82
	n = 5
	for i in range(n):
		B((W / n - 0.008, 0.04, H + J(0.02)), (-W / 2 + W / n * (i + 0.5), -0.02, H / 2), WOOD(), bevel=0.008)
	for z in (0.04, H - 0.04):
		B((W + 0.03, 0.012, 0.05), (0, -0.044, z), IRON("dark"), bevel=0.003)
		for x in (-0.45, -0.15, 0.15, 0.45):
			kit.rivet((x, -0.05, z), IRON("a"), r=0.009)
	plate = B((0.16, 0.01, 0.07), (0, -0.047, H - 0.1), CU(), bevel=0.003)
	cut(plate, mark("flame", 0, H - 0.1, 0.025, -0.052, w=0.007, depth=0.004))
	# files and rasps in a leather strap
	zs = 0.5
	B((W - 0.12, 0.01, 0.04), (0, -0.057, zs), LEA(), bevel=0.003)
	for i in range(8):
		x = -0.38 + 0.108 * i
		L = 0.3 - 0.018 * i
		group(lambda L=L, w=0.024 - 0.0015 * (i % 3): file_tool(L, w), at=(x, -0.047, zs + 0.17), rot=(0, 180, 0))
		B((0.034, 0.012, 0.046), (x, -0.062, zs), LEA("b"), bevel=0.004)
		for s in (-1, 1):
			kit.rivet((x + s * 0.024, -0.063, zs), CU("dark"), r=0.006)
	# drilled block of punches and drifts on two brackets
	zb = 0.13
	for x in (-0.38, 0.38):
		prism([(-0.04, zb + 0.03), (-0.13, zb + 0.03), (-0.04, zb - 0.09)], x - 0.02, x + 0.02, WOOD("dark"), axis="x")
	blk = B((W - 0.14, 0.1, 0.06), (0, -0.09, zb + 0.06), WOOD("b"), bevel=0.008)
	xs = [-0.36 + 0.09 * i for i in range(9)]
	cut(blk, [kit.cylinder(0.016, 0.06, (x, -0.09, zb + 0.09), GROOVE(), verts=10, bevel=0) for x in xs])
	for i, x in enumerate(xs):
		L = 0.12 + 0.03 * ((i * 5) % 4)
		group(lambda L=L, r=0.009 + 0.002 * (i % 3), t=("point", "flat")[i % 2]: punch(L, r, t), at=(x, -0.09, zb + 0.07))


def ef_mould_shelf():
	W, H = 1.2, 1.25
	yf = brick_wall(W, H)
	lime_cap(W, H)

	def shelf(z):
		B((W - 0.08, 0.26, 0.04), (0, yf - 0.13, z), WOOD(), bevel=0.008)
		B((W - 0.12, 0.02, 0.03), (0, yf - 0.25, z + 0.03), WOOD("dark"), bevel=0.004)
		for x in (-0.48, 0.48):
			prism([(yf + 0.004, z - 0.02), (yf - 0.2, z - 0.02), (yf - 0.2, z - 0.045), (yf + 0.004, z - 0.22)], x - 0.012, x + 0.012, IRON("dark"), axis="x")
			kit.rivet((x, yf - 0.006, z - 0.15), IRON("a"), r=0.01)
		return z + 0.02

	z = shelf(0.42)
	for k, x in enumerate((-0.38, -0.1)):
		m_ = B((0.24, 0.17, 0.07), (x, yf - 0.13, z + 0.035 - 0.002), LIME(), bevel=0.012)
		cut(m_, [kit.taper(0.11, 0.04, 0.135, 0.055, 0.045, (x + dx, yf - 0.13, z + 0.035), GROOVE(), bevel=0) for dx in (-0.055, 0.055)])
	for k in range(2):
		B((0.22, 0.15, 0.06), (0.18, yf - 0.13, z + 0.029 + 0.062 * k), LIME("c" if k else "b"), bevel=0.01)
	m_ = B((0.2, 0.15, 0.055), (0.18, yf - 0.13, z + 0.153), LIME("a"), bevel=0.01)
	cut(m_, [kit.taper(0.06, 0.03, 0.08, 0.045, 0.04, (0.18 + dx, yf - 0.13, z + 0.155), GROOVE(), bevel=0) for dx in (-0.045, 0.045)])
	for k in range(3):
		group(lambda: ingot(IRON("dark"), 0.1, 0.04, 0.026), at=(0.43, yf - 0.13 + (k - 1) * 0.05, z - 0.002))
	z = shelf(0.92)
	sm = B((0.5, 0.18, 0.06), (-0.27, yf - 0.13, z + 0.03 - 0.002), LIME(), bevel=0.01)
	cut(sm, [prism([(x, yf - 0.13 + y) for x, y in [(-0.49, -0.006), (-0.44, -0.006), (-0.44, -0.035), (-0.42, -0.035), (-0.42, -0.016),
		(-0.1, -0.012), (-0.05, 0), (-0.1, 0.012), (-0.42, 0.016), (-0.42, 0.035), (-0.44, 0.035), (-0.44, 0.006), (-0.49, 0.006)]],
		z + 0.042, z + 0.08, GROOVE(), axis="z")])
	for k, x in enumerate((0.08, 0.24, 0.4)):
		r = 0.06 - 0.008 * k
		turned([(r * 0.7, 0), (r, 0.03), (r * 1.05, r * 1.9), (r * 0.9, r * 1.95), (r * 0.85, r * 1.9), (r * 0.82, 0.03), (0.004, 0.025), (0.004, 0)],
			(x, yf - 0.13, z - 0.002), CLAY("dark"), seg=16)
		kit.ring(r * 0.97, 0.006, (x, yf - 0.13, z + r * 1.93), COALDUST(), seg=16)
	# a long-handled ladle hanging from two hooks under the top shelf
	for x in (-0.25, 0.15):
		rod((x, yf - 0.22, 0.9), (x, yf - 0.22, 0.85), 0.006, IRON("dark"), seg=6)
		kit.ring(0.018, 0.005, (x, yf - 0.22, 0.835), IRON("dark"), rot=(90, 0, 0), seg=10)
	rod((-0.3, yf - 0.22, 0.818), (0.22, yf - 0.22, 0.818), 0.009, IRON("dark"))
	turned([(0.07, 0.07), (0.072, 0.075), (0.05, 0.02), (0.004, 0.0), (0.004, 0.008), (0.046, 0.026), (0.064, 0.07)], (0.29, yf - 0.22, 0.75), IRON("a"), seg=16)
	sphere((-0.3, yf - 0.22, 0.818), 0.014, IRON("dark"))


def ef_chimney_hood():
	z0, h = 1.2, 0.6
	hood_shell(1.2, 0.72, 0.5, 0.36, h, 0.012, CU("b"), z0=z0, yb=-0.004)
	# iron band round the mouth and up the corners, rivets
	dz = 0.036
	yc, zc_ = -0.724 + 0.6 * dz - 0.8575 * 0.011, z0 + dz + 0.5145 * 0.011
	B((1.16, 0.016, 0.06), (0, yc, zc_), IRON("dark"), bevel=0.003, rot=(-30.96, 0, 0))
	for k in range(9):
		kit.rivet((-0.52 + 0.13 * k, yc - 0.8575 * 0.009, zc_ + 0.5145 * 0.009), CU("dark"), r=0.009)
	for s in (-1, 1):
		xc, zs_ = s * (0.6 - 0.583 * dz + 0.8638 * 0.011), z0 + dz + 0.5039 * 0.011
		B((0.016, 0.69, 0.06), (xc, -0.356, zs_), IRON("dark"), bevel=0.003, rot=(0, s * -30.26, 0))
	for s in (-1, 1):
		p0, p1 = Vector((s * 0.6, -0.724, z0 + 0.06)), Vector((s * 0.25, -0.364, z0 + h))
		d = p1 - p0
		for t in (0.15, 0.4, 0.65, 0.9):
			p = p0 + d * t
			kit.rivet((p.x, p.y - 0.004, p.z), CU("dark"), r=0.008)
		rod(tuple(p0 + Vector((0, -0.006, 0))), tuple(p1 + Vector((0, -0.006, 0))), 0.012, IRON("dark"), seg=6)
	# brick flue up the wall
	brick_box(0.62, 0.42, 0.7, at=(0, -0.214, z0 + h - 0.02), sides="flr")
	B((0.7, 0.46, 0.06), (0, -0.234, z0 + h + 0.69), LIME("a"), bevel=0.01)
	# iron wall straps holding the hood, and two brick corbels under its back corners
	for s in (-1, 1):
		B((0.04, 0.012, 0.3), (s * 0.5, -0.025, z0 + 0.15), IRON("dark"), bevel=0.003)
		rod((s * 0.5, -0.018, z0 + 0.26), (s * 0.5, -0.4, z0 + 0.26), 0.01, IRON("dark"), seg=6)
		for k in range(3):
			B((0.24, 0.08 + 0.04 * k, 0.08), (s * 0.48, -0.006 - (0.08 + 0.04 * k) / 2, z0 - 0.214 + 0.085 * k), brick_m(), bevel=0.01)
	# hook rail along the mouth with a poker, small tongs and a fire rake
	rod((-0.5, -0.75, z0 + 0.01), (0.5, -0.75, z0 + 0.01), 0.01, IRON("dark"), seg=6)
	for x in (-0.5, 0.5):
		rod((x, -0.75, z0 + 0.01), (x, -0.735, z0 + 0.03), 0.008, IRON("dark"), seg=6)
	for x, kind in ((-0.3, "poker"), (0.0, "tongs"), (0.3, "rake")):
		kit.ring(0.02, 0.005, (x, -0.75, z0 - 0.012), IRON("dark"), rot=(0, 90, 0), seg=10)
		if kind == "tongs":
			group(lambda: tongs(0.4, "flat"), at=(x, -0.75, z0 - 0.42 - 0.03))
		else:
			rod((x, -0.75, z0 - 0.03), (x, -0.75, z0 - 0.5), 0.009, IRON("dark"), seg=6)
			if kind == "poker":
				kit.cone(0.009, 0.002, 0.06, (x, -0.75, z0 - 0.525), IRON("a"), rot=(180, 0, 0), verts=6)
			else:
				B((0.12, 0.012, 0.04), (x, -0.75, z0 - 0.51), IRON("dark"), bevel=0.003)
				for k in range(5):
					kit.cone(0.006, 0.002, 0.04, (x - 0.05 + k * 0.025, -0.75, z0 - 0.545), IRON("a"), rot=(180, 0, 0), verts=5, bevel=0)


def ef_ingot_wall(empty=False):
	W, H, D = 1.08, 1.3, 0.3
	n = 4
	for i in range(n):
		B((W / n - 0.008, 0.03, H - 0.05), (-W / 2 + W / n * (i + 0.5), -0.015, 0.05 + (H - 0.05) / 2), WOOD("dark"), bevel=0.006)
	for x in (-W / 2 + 0.025, -W / 6, W / 6, W / 2 - 0.025):
		B((0.05, D - 0.03, H), (x, -0.03 - (D - 0.03) / 2, H / 2), WOOD(), bevel=0.008)
	zs = [0.12, 0.5, 0.88, 1.26]
	for z in zs:
		B((W - 0.03, D - 0.02, 0.045), (0, -0.033 - (D - 0.02) / 2, z), WOOD(), bevel=0.008)
	for x in (-W / 2 + 0.025, W / 2 - 0.025):
		for z in (0.06, H - 0.06):
			B((0.07, 0.012, 0.12), (x, -D - 0.008, z), IRON("dark"), bevel=0.003)
			kit.rivet((x, -D - 0.015, z), IRON("a"), r=0.009)
	cells = [("iron", 4), ("copper", 3), ("iron", 3), ("copper", 4), ("iron", 2), ("iron", 4), ("gold", 2), ("copper", 2), ("iron", 3)]
	ci = 0
	for r in range(3):
		zb = zs[r] + 0.0225
		for c in range(3):
			kind, layers = cells[ci]
			ci += 1
			cx = -W / 3 + W / 3 * c
			m = {"iron": IRON("dark"), "copper": CU("b"), "gold": GOLD()}[kind]
			yc = -0.18
			for lay in range(0 if empty else layers):
				z = zb + lay * 0.033 - 0.001
				if lay % 2 == 0:
					for x in (-0.075, 0.075):
						for y in (-0.07, 0.0, 0.07):
							group(lambda m=m: ingot(m), at=(cx + x + J(0.004), yc + y, z), rot=(0, 0, J(2)))
				else:
					for x in (-0.105, -0.035, 0.035, 0.105):
						group(lambda m=m: ingot(m), at=(cx + x, yc, z), rot=(0, 0, 90 + J(2)))
			tag_plate(cx, -0.033 - (D - 0.02), zs[r] - 0.005, w=0.08, h=0.035)


def ef_commission_board():
	W, H = 1.0, 0.8
	n = 5
	for i in range(n):
		B((W / n - 0.008, 0.04, H + J(0.02)), (-W / 2 + W / n * (i + 0.5), -0.02, H / 2), WOOD(), bevel=0.008)
	for z in (0.05, H - 0.05):
		B((W + 0.03, 0.025, 0.06), (0, -0.052, z), WOOD("dark"), bevel=0.006)
		for x in (-0.46, 0.46):
			kit.rivet((x, -0.066, z), IRON("dark"), r=0.01)
	sketches = ["sword", "axe", "hammer", "ring", "tally", "runes"]
	for i, kind in enumerate(sketches):
		cx, cz = -0.3 + 0.3 * (i % 3), 0.55 if i < 3 else 0.22
		rod((cx, -0.04, cz + 0.14), (cx, -0.09, cz + 0.145), 0.008, CU(), seg=6)
		sphere((cx, -0.092, cz + 0.145), 0.013, CU("dark"))
		for s in (-1, 1):
			rod((cx, -0.07, cz + 0.135), (cx + s * 0.07, -0.072, cz + 0.08), 0.004, kit.tex_mat("rope", "b"), seg=5)
		tab = B((0.2, 0.025, 0.15), (cx, -0.072, cz), LIME(("a", "b", "c")[i % 3]), bevel=0.01, rot=(0, J(3), 0))
		yf = -0.0845
		if kind == "sword":
			cuts = groove_path([(cx - 0.07, cz), (cx + 0.06, cz)], yf, 0.008, 0.005) + groove_path([(cx - 0.04, cz - 0.03), (cx - 0.04, cz + 0.03)], yf, 0.008, 0.005)
			cuts += groove_path([(cx + 0.06, cz + 0.012), (cx + 0.085, cz), (cx + 0.06, cz - 0.012)], yf, 0.006, 0.005)
		elif kind == "axe":
			cuts = groove_path([(cx - 0.06, cz - 0.05), (cx + 0.02, cz + 0.05)], yf, 0.008, 0.005) + groove_path([(cx + 0.0, cz + 0.02), (cx + 0.05, cz - 0.01),
				(cx + 0.07, cz + 0.04), (cx + 0.04, cz + 0.06)], yf, 0.008, 0.005)
		elif kind == "tally":
			cuts = []
			for g in range(2):
				for k in range(4):
					x = cx - 0.07 + g * 0.08 + k * 0.014
					cuts += groove((x, cz - 0.035), (x, cz + 0.035), yf, 0.006, 0.005)
				cuts += groove((cx - 0.075 + g * 0.08, cz - 0.03), (cx - 0.02 + g * 0.08, cz + 0.03), yf, 0.006, 0.005)
		elif kind == "runes":
			cuts = rune_row(cx - 0.08, cx + 0.08, cz + 0.03, yf, h=0.04, w=0.007, depth=0.005, seed=31) + rune_row(cx - 0.08, cx + 0.08, cz - 0.03, yf, h=0.04, w=0.007, depth=0.005, seed=32)
		else:
			cuts = mark(kind, cx, cz, 0.06, yf, w=0.008, depth=0.005)
		cut(tab, cuts)
	# a tally stick on two pegs along the bottom
	st = B((0.7, 0.03, 0.04), (0, -0.075, 0.1), WOOD("b"), bevel=0.006)
	cut(st, [B((0.008, 0.02, 0.05), (-0.3 + 0.035 * k, -0.092, 0.1), GROOVE(), bevel=0) for k in range(14)])


# ================= story pieces =================
def ef_blade_on_anvil():
	group(lambda: stump(0.24, 0.5))
	face = [0]
	group(lambda: face.__setitem__(0, anvil()), at=(0, 0, 0.497))
	# the hammer, dropped beside the stump
	hm = group(lambda: hammer(0.34, 0.15, 0.05, "cross"), at=(-0.1, -0.42, 0.0), rot=(90, 0, 70))
	settle(hm)
	# scale flakes on the floor
	coal_bits([(0.3, -0.3), (-0.35, 0.25), (0.42, 0.18)], 0.0, s=0.016, seed=9)
	# a slack bucket beside it
	bx, by = 0.42, 0.34
	turned([(0.13, 0.0), (0.15, 0.3), (0.135, 0.3), (0.117, 0.03), (0.004, 0.03), (0.004, 0.0)], (bx, by, 0), WOOD("b"), seg=18)
	for zz in (0.06, 0.24):
		kit.ring(0.124 + zz * 0.067 + 0.004, 0.008, (bx, by, zz), IRON("dark"), seg=20)


def ef_cracked_quench():
	R = 0.32
	kit.cylinder(R - 0.01, 0.04, (0, 0, 0.03), WOOD("dark"), verts=18, bevel=0.004)
	n = 20
	for k in range(n):
		a = 2 * math.pi * k / n
		B((2 * math.pi * R / n - 0.006, 0.035, 0.46 + J(0.01)), (math.cos(a) * R, math.sin(a) * R, 0.23), WOOD(), bevel=0.006, rot=(0, 0, math.degrees(a) + 90))
	for z in (0.07, 0.37):
		kit.ring(R + 0.019, 0.01, (0, 0, z), IRON("dark"), seg=32)
	# still water: a near-black glossy surface pressed into the staves, a lighter wet rim where it meets the wood,
	# a dark wet band on the staves just above it, and two faint rings where the broken blade dips in
	kit.cylinder(R - 0.012, 0.3, (0, 0, 0.21), DEEP(), verts=32, bevel=0)
	kit.ring(R - 0.02, 0.007, (0, 0, 0.36), MENISCUS(), seg=40)
	kit.ring(R - 0.016, 0.012, (0, 0, 0.385), WETWOOD(), seg=40)
	# hilt half lying across the rim, its broken blade dipping toward the water
	group(lambda: sword(0.86, 0.058, 0.2, "disc", cut_at=0.5), at=(R + 0.25, -0.05, 0.6), rot=(0, -112, 15))
	# the snapped tip on the floor
	group(lambda: sword_tip(0.5, 0.86, 0.058), at=(-0.29, -0.11, 0.0065), rot=(90, 0, 60))
	# tongs leaning on the tub, a few metal chips on the floor
	group(lambda: tongs(0.6, "flat", hook=False), at=(-R - 0.24, -0.05, 0.003), rot=(0, 27, 0))
	coal_bits([(0.2, -0.45), (0.12, -0.6), (-0.1, -0.5)], 0.0, s=0.012, seed=3)


def ef_bent_blade_vise():
	top = bench(0.95, 0.42, 0.72)
	x0 = -0.4
	yv = -0.21
	# leg vise: iron leg down the bench leg, spring, screw box, screw and handle, jaws
	B((0.06, 0.04, 0.84), (x0, yv - 0.045, 0.42), IRON("dark"), bevel=0.006)
	B((0.08, 0.05, 0.09), (x0, yv - 0.045, 0.79), IRON("dark"), bevel=0.006)
	B((0.08, 0.04, 0.09), (x0, yv + 0.0, 0.79), IRON("dark"), bevel=0.006)
	kit.cylinder(0.014, 0.25, (x0, yv - 0.03, 0.7), IRON("a"), rot=(90, 0, 0), verts=8)
	kit.cylinder(0.035, 0.04, (x0, yv - 0.085, 0.7), IRON("dark"), rot=(90, 0, 0), verts=10)
	rod((x0 - 0.16, yv - 0.115, 0.7), (x0 + 0.16, yv - 0.115, 0.7), 0.009, IRON("dark"), seg=6)
	for s in (-1, 1):
		sphere((x0 + s * 0.165, yv - 0.115, 0.7), 0.017, IRON("dark"))
	B((0.04, 0.02, 0.22), (x0, yv - 0.02, 0.48), IRON("a"), bevel=0.003, rot=(15, 0, 0))
	B((0.08, 0.06, 0.03), (x0, yv - 0.04, 0.1), IRON("dark"), bevel=0.004)
	# the sword clamped between the jaws, bent crooked above them
	before = set(bpy.data.objects[:])
	group(lambda: sword(0.9, 0.056, 0.2, "ball", smooth=True), at=(x0, yv - 0.0225, 0.58), rot=(0, 0, 90))
	parts = new_since(before)
	bend_z = 0.58 + 0.45
	upper = [o for o in parts if o.type == "MESH" and max((o.matrix_world @ v.co).z for v in o.data.vertices) > bend_z]
	for o in upper:
		mw = o.matrix_world.copy()
		inv = mw.inverted()
		for v in o.data.vertices:
			w = mw @ v.co
			if w.z > bend_z:
				t = w.z - bend_z
				ang = math.radians(32) * min(1.0, t / 0.12)
				w.x += t * math.sin(ang) * 0.9
				w.z = bend_z + t * math.cos(ang)
			v.co = inv @ w
	# straightening tools and bent nails on the bench, the split hammer below
	for k in range(4):
		x, y = 0.1 + k * 0.06, -0.05 + J(0.04)
		rod((x, y, top + 0.006), (x + 0.03, y + 0.02, top + 0.006), 0.004, IRON("dark"), seg=5)
		rod((x + 0.03, y + 0.02, top + 0.006), (x + 0.04, y + 0.06, top + 0.02), 0.004, IRON("dark"), seg=5)
	group(lambda: hammer(0.3, 0.13, 0.045, "cross"), at=(0.05, 0.08, top + 0.0245), rot=(90, 0, 100))
	B((0.26, 0.03, 0.03), (0.15, -0.38, 0.015), WOOD("b"), bevel=0.005, rot=(0, 0, 20))
	B((0.14, 0.03, 0.03), (-0.04, -0.47, 0.015), WOOD("b"), bevel=0.005, rot=(0, 0, -35))
	group(lambda: [B((0.14, 0.045, 0.045), (0, 0, 0.0225), IRON("dark"), bevel=0.007), kit.cylinder(0.026, 0.02, (-0.077, 0, 0.0225), IRON("a"), rot=(0, 90, 0), verts=10)],
		at=(-0.13, -0.5, 0.0), rot=(0, 0, 25))


def ef_axe_progression():
	top = bench(1.6, 0.42, 0.6, shelf=False)
	z = top
	xs = [-0.6 + 0.2 * i for i in range(6)]
	# 1 the bar
	B((0.2, 0.05, 0.026), (xs[0], -0.04, z + 0.012), IRON("dark"), bevel=0.004)
	# 2 the bar with the eye slot punched
	b2 = B((0.2, 0.06, 0.026), (xs[1], -0.04, z + 0.012), IRON("dark"), bevel=0.004)
	cut(b2, [B((0.05, 0.012, 0.06), (xs[1], -0.04, z + 0.012), GROOVE(), bevel=0)])
	# 3 slot opened round on a drift
	x = xs[2]
	kit.ring(0.03, 0.013, (x - 0.04, -0.04, z + 0.013), IRON("dark"), seg=14)
	prism([(x - 0.012, -0.065), (x + 0.1, -0.05), (x + 0.1, -0.03), (x - 0.012, -0.015)], z, z + 0.026, IRON("dark"), axis="z")
	# 4 cheeks drawn out, eye drifted
	x = xs[3]
	kit.ring(0.032, 0.012, (x - 0.05, -0.04, z + 0.012), IRON("b"), seg=14)
	prism([(x - 0.02, -0.07), (x + 0.09, -0.085), (x + 0.1, 0.0), (x - 0.02, -0.01)], z, z + 0.024, IRON("b"), axis="z")
	# 5 the shaped head
	x = xs[4]
	kit.ring(0.03, 0.013, (x - 0.06, -0.04, z + 0.013), IRON("dark"), seg=14)
	prism([(x - 0.035, -0.06), (x + 0.06, -0.1), (x + 0.09, -0.03), (x + 0.07, 0.04), (x - 0.035, -0.02)], z, z + 0.022, IRON("dark"), axis="z")
	# 6 the finished axe, hafted, lying on the bench
	group(lambda: axe(0.36), at=(xs[5] - 0.02, -0.17, z + 0.0145), rot=(-90, 0, 0))
	# numbered copper tags along the front edge (tally strokes cut in)
	for i, x in enumerate(xs):
		t = B((0.07, 0.008, 0.04), (x, -0.215, top - 0.03), CU(), bevel=0.002)
		cut(t, [B((0.005, 0.02, 0.024), (x - 0.0105 * i + 0.0105 * 2.5 - 0.0105 * 2.5 + (k - i / 2) * 0.0105, -0.222, top - 0.03), GROOVE(), bevel=0)
			for k in range(i + 1)])
	# tools at the end: drift, slot punch, hammer
	group(lambda: punch(0.18, 0.016, "point"), at=(0.56, -0.12, z + 0.016), rot=(0, 90, 0))
	group(lambda: punch(0.15, 0.012, "flat"), at=(0.56, -0.05, z + 0.012), rot=(0, 90, 0))
	group(lambda: hammer(0.3, 0.13, 0.045, "cross"), at=(-0.74, 0.12, z + 0.0245), rot=(90, 0, 90))


def ef_fallen_hood():
	# the broken flue stump
	brick_box(0.6, 0.4, 0.3, at=(0.55, 0.35, 0))
	for x, y, L in ((0.38, 0.24, 0.2), (0.68, 0.25, 0.16), (0.45, 0.47, 0.13), (0.72, 0.46, 0.2)):
		B((L, 0.11, 0.083), (x, y, 0.34), brick_m(), bevel=0.011, rot=(J(3), J(3), J(8)))
	# the hood, torn down and crumpled on its side
	hd = group(lambda: hood_shell(1.0, 0.62, 0.42, 0.3, 0.52, 0.012, CU("b"), z0=-0.26, yb=0.31), rot=(-108, 0, 25))
	for o in hd:
		kit.roughen(o, 0.012, 2, seed=4)
	settle(hd, -0.004)
	shift_ = Vector((-0.25, -0.1, 0))
	for o in hd:
		o.location += shift_
	# a snapped iron band and strap
	rod((-0.2, -0.55, 0.012), (0.35, -0.42, 0.012), 0.011, IRON("dark"), seg=6)
	rod((0.35, -0.42, 0.012), (0.42, -0.3, 0.05), 0.011, IRON("dark"), seg=6)
	B((0.04, 0.3, 0.012), (0.75, -0.2, 0.006), IRON("dark"), bevel=0.003, rot=(0, 0, 30))
	# broken bricks on the floor (whole, halves, chips), resting
	spots, tries = [], 0
	while len(spots) < 12 and tries < 4000:
		tries += 1
		a = rng.uniform(0, 2 * math.pi)
		d = rng.uniform(0.2, 0.6)
		x, y = 0.45 + math.cos(a) * d * 0.8, -0.05 + math.sin(a) * d * 0.7
		if all(math.hypot(x - u, y - v) > 0.28 for u, v in spots) and not (0.2 < x < 0.9 and 0.1 < y < 0.6) and x > -0.05:
			spots.append((x, y))
	for k, (x, y) in enumerate(spots):
		L = rng.choice((0.24, 0.13, 0.1, 0.07))
		o = B((L, 0.11, 0.08), (x, y, 0.2), brick_m(), bevel=0.011, rot=(0, 0, rng.uniform(0, 180)))
		rest(o, 0.0)
	coal_bits([(0.2, 0.2), (-0.6, -0.4), (0.1, -0.6)], 0.0, s=0.02, seed=7)


def ef_burst_crucible():
	# the cracked crucible: one half tipped on its side, the other lying open
	prof = [(r * 1.5, z * 1.5) for r, z in [(0.07, 0.0), (0.1, 0.04), (0.115, 0.2), (0.105, 0.24), (0.092, 0.24), (0.1, 0.2), (0.085, 0.05), (0.004, 0.04), (0.004, 0.0)]]
	g1 = group(lambda: turned(prof, (0, 0, 0), CLAY("dark"), seg=12, a0=10, a1=190), at=(-0.2, 0.08, 0.0), rot=(0, 75, 20))
	settle(g1, 0.0)
	g2 = group(lambda: turned(prof, (0, 0, 0), CLAY("dark"), seg=10, a0=200, a1=345), at=(-0.45, 0.3, 0.0), rot=(-80, 0, -30))
	settle(g2, 0.0)
	# clay shards from the crack, lying on the floor (the spill is long gone: owner, no spills)
	for k, (x, y, s) in enumerate(((0.05, -0.05, 0.05), (0.22, 0.12, 0.035), (-0.02, 0.28, 0.04), (0.3, -0.3, 0.03), (-0.5, -0.05, 0.03))):
		o = kit.gem((x, y, 0.02), (s, s * 0.8, s * 0.3), CLAY("dark"), seed=20 + k)
		spin(o, J(10), J(10), rng.uniform(0, 180))
		rest(o, 0.0)
	# the crucible tongs, dropped
	group(lambda: tongs(0.62, "ring", hook=False), at=(-0.15, -0.2, 0.03), rot=(90, 0, -110))
	# the empty sword mould it should have filled
	mo = B((0.62, 0.2, 0.08), (0.2, 0.55, 0.04), LIME("b"), bevel=0.012)
	cut(mo, [prism([(x + 0.2, y + 0.55) for x, y in [(-0.28, -0.006), (-0.23, -0.006), (-0.23, -0.04), (-0.21, -0.04), (-0.21, -0.016), (0.2, -0.012),
		(0.26, 0), (0.2, 0.012), (-0.21, 0.016), (-0.21, 0.04), (-0.23, 0.04), (-0.23, 0.006), (-0.28, 0.006)]], 0.05, 0.1, GROOVE(), axis="z")])
	kit.cylinder(0.03, 0.03, (-0.08, 0.55, 0.075), LIME("a"), verts=10)


def grind_frame(R=0.32, zc=0.66):
	"""The wooden A-frame, sills and copper bearings of a grinding wheel (axle along x at height zc)."""
	for x in (-0.24, 0.24):
		for y in (-1, 1):
			rod((x, y * 0.24, 0.016), (x, y * 0.03, zc), 0.035, WOOD(), seg=8)
		B((0.07, 0.6, 0.07), (x, 0, 0.035), WOOD("dark"), bevel=0.008)
		B((0.07, 0.24, 0.06), (x, 0, 0.32), WOOD(), bevel=0.008)
		B((0.08, 0.1, 0.07), (x, 0, zc), CU("b"), bevel=0.008)
		kit.rivet((x, -0.052, zc), CU("dark"), r=0.009)
	for y in (-0.22, 0.22):
		B((0.55, 0.06, 0.06), (0, y, 0.03 + 0.065), WOOD("dark"), bevel=0.008)


def ef_broken_grindstone():
	R, zc = 0.32, 0.66
	grind_frame(R, zc)
	kit.cylinder(0.018, 0.68, (0.04, 0, zc), IRON("dark"), rot=(0, 90, 0), verts=8)
	rod((0.374, 0, zc - 0.02), (0.374, 0, zc - 0.18), 0.013, IRON("dark"), seg=6)
	kit.cylinder(0.018, 0.12, (0.43, 0, zc - 0.18), WOOD("b"), rot=(0, 90, 0), verts=8)
	kit.cylinder(0.034, 0.032, (0.374, 0, zc), IRON("a"), rot=(0, 90, 0), verts=12)
	# the half still on the axle (broken edge jagged)
	half = [(math.cos(a) * R, math.sin(a) * R) for a in [math.pi * k / 12 for k in range(13)]]
	half = [(y, z) for y, z in half]
	pts = [(-R, 0.0)] + [(math.cos(math.pi - math.pi * k / 12) * R, math.sin(math.pi - math.pi * k / 12) * R) for k in range(13)] + [(R * 0.6, -0.03), (R * 0.2, 0.02),
		(-R * 0.3, -0.04)]
	prism([(y, z + zc) for y, z in pts], -0.05, 0.05, T("warmstone", "b"), axis="x")
	kit.cylinder(0.05, 0.11, (0, 0, zc), IRON("a"), rot=(0, 90, 0), verts=10)
	# the fallen half leaning against the frame sill
	g = group(lambda: prism([(y, -z) for y, z in pts], -0.05, 0.05, T("warmstone", "c"), axis="x"), at=(-0.34, -0.1, 0.0), rot=(0, 84, 0))
	settle(g, 0.0)
	for k in range(6):
		o = kit.gem((0.2 + rng.uniform(-0.3, 0.2), -0.35 + rng.uniform(-0.12, 0.12), 0.03), (0.05, 0.04, 0.03), T("warmstone", "b"), seed=k)
		spin(o, J(30), J(30), J(90))
		rest(o, 0.0)
	# the trough under the wheel, dry
	for x in (-0.12, 0.12):
		B((0.06, 0.5, 0.03), (x, 0, 0.137), WOOD("dark"), bevel=0.005)
	for y in (-0.12, 0.12):
		B((0.36, 0.025, 0.12), (0, y, 0.21), WOOD(), bevel=0.005)
	for x in (-0.17, 0.17):
		B((0.025, 0.22, 0.12), (x, 0, 0.21), WOOD(), bevel=0.005)
	B((0.33, 0.22, 0.025), (0, 0, 0.162), WOOD("dark"), bevel=0.005)


def ef_forge_hearth():
	W, D, H = 1.4, 1.0, 0.68
	brick_box(W, D, H)
	for y in (-D / 2 + 0.11, D / 2 - 0.11):
		B((W + 0.06, 0.22, 0.07), (0, y, H + 0.023), LIME(), bevel=0.014)
	for x in (-W / 2 + 0.2, W / 2 - 0.2):
		B((0.4, D - 0.44 - 0.02, 0.07), (x, 0, H + 0.023), LIME(), bevel=0.014)
	# iron fire pot rim
	for y in (-0.28, 0.28):
		B((0.6, 0.03, 0.03), (0, y, H + 0.06), IRON("dark"), bevel=0.004)
	for x in (-0.3, 0.3):
		B((0.03, 0.59, 0.03), (x, 0, H + 0.06), IRON("dark"), bevel=0.004)
	for x in (-0.3, 0.3):
		for y in (-0.28, 0.28):
			kit.rivet((x, y, H + 0.077), IRON("a"), r=0.01)
	B((0.58, 0.54, 0.03), (0, 0, H + 0.03), COALDUST(), bevel=0.004)
	# cold hearth (owner round 3: "no fire"): an iron grate with a low heap of cold black coal, no flames, no glow
	for k in range(7):
		B((0.56, 0.022, 0.012), (0, -0.24 + 0.08 * k, H + 0.048), IRON("dark"), bevel=0.003)
	coal_heap(0, 0, H + 0.05, 0.19, 0.17, 0.1, n=80, seed=3, fines=50)
	# tuyere pipe into the right side
	rod((W / 2 + 0.32, 0, 0.42), (W / 2 - 0.02, 0, 0.42), 0.05, IRON("dark"), seg=12)
	kit.cylinder(0.075, 0.03, (W / 2 + 0.01, 0, 0.42), IRON("a"), rot=(0, 90, 0), verts=14)
	kit.cylinder(0.068, 0.04, (W / 2 + 0.33, 0, 0.42), CU("b"), rot=(0, 90, 0), verts=14)
	B((0.08, 0.12, 0.38), (W / 2 + 0.25, 0, 0.19), brick_m(), bevel=0.012)
	B((0.1, 0.14, 0.05), (W / 2 + 0.25, 0, 0.385), LIME(), bevel=0.01)
	for k in range(6):
		a = 2 * math.pi * k / 6
		kit.rivet((W / 2 - 0.004, math.cos(a) * 0.06, 0.42 + math.sin(a) * 0.06), IRON("a"), r=0.009)
	# tool rail on the front with a poker, a rake and a small coal shovel
	yr = -D / 2 - 0.09
	for x in (-0.55, 0.55):
		rod((x, -D / 2 + 0.005, 0.56), (x, yr, 0.56), 0.012, IRON("dark"), seg=6)
		B((0.05, 0.012, 0.12), (x, -D / 2 - 0.004, 0.56), IRON("dark"), bevel=0.003)
	rod((-0.6, yr, 0.56), (0.6, yr, 0.56), 0.012, IRON("dark"), seg=6)
	for x, kind in ((-0.3, "poker"), (0.0, "rake"), (0.3, "shovel")):
		kit.ring(0.022, 0.006, (x, yr, 0.545), IRON("dark"), rot=(0, 90, 0), seg=10)
		rod((x, yr, 0.525), (x, yr, 0.12), 0.009, IRON("dark"), seg=6)
		if kind == "poker":
			kit.cone(0.009, 0.002, 0.06, (x + 0.02, yr, 0.1), IRON("a"), rot=(0, 135, 0), verts=6)
		elif kind == "rake":
			B((0.12, 0.012, 0.04), (x, yr, 0.11), IRON("dark"), bevel=0.003)
			for k in range(5):
				kit.cone(0.006, 0.002, 0.04, (x - 0.05 + k * 0.025, yr, 0.075), IRON("a"), rot=(180, 0, 0), verts=5, bevel=0)
		else:
			prism([(x - 0.06, 0.12), (x + 0.06, 0.12), (x + 0.05, 0.0), (x - 0.05, 0.0)], yr - 0.004, yr + 0.004, IRON("dark"), axis="y")
	# iron corner angles with rivets
	for x in (-W / 2, W / 2):
		for y in (-D / 2, D / 2):
			B((0.05, 0.05, H - 0.04), (x - math.copysign(0.02, x) * -1 * 0, y, (H - 0.04) / 2 + 0.01), IRON("dark"), bevel=0.004)
			for z in (0.12, 0.34, 0.56):
				kit.rivet((x + math.copysign(0.026, x), y, z), IRON("a"), r=0.009)


def ef_quench_trough():
	W, D, H, t = 1.3, 0.56, 0.55, 0.13
	brick_box(W, t, H, at=(0, -D / 2 + t / 2, 0))
	brick_box(W, t, H, at=(0, D / 2 - t / 2, 0))
	for s in (-1, 1):
		brick_box(t, D - 2 * t + 0.03, H, at=(s * (W / 2 - t / 2), 0, 0), sides="lr")
	B((W - 2 * t + 0.02, D - 2 * t + 0.02, 0.1), (0, 0, 0.05), MORT(), bevel=0.004)
	kit.box((W - 2 * t + 0.012, D - 2 * t + 0.012, 0.012), (0, 0, 0.45), WATER(), bevel=0, wobble=0)
	for y in (-D / 2 + t / 2, D / 2 - t / 2):
		B((W + 0.04, t + 0.05, 0.06), (0, y, H + 0.018), LIME(), bevel=0.012)
	for x in (-W / 2 + t / 2, W / 2 - t / 2):
		B((t + 0.05, D - 2 * t - 0.012 - 0.04, 0.06), (x, 0, H + 0.018), LIME(), bevel=0.012)
	for x in (-W / 2 - 0.004, W / 2 + 0.004):
		for y in (-D / 2 - 0.004, D / 2 + 0.004):
			B((0.06, 0.06, H - 0.06), (x, y, H / 2), IRON("dark"), bevel=0.005)
			for z in (0.1, 0.3, 0.48):
				kit.rivet((x + math.copysign(0.03, x), y, z), IRON("a"), r=0.009)
	# tong rest bar across one end, a copper dipper on the rim
	rod((-W / 2 + 0.26, -D / 2 + 0.05, H + 0.06), (-W / 2 + 0.26, D / 2 - 0.05, H + 0.06), 0.014, IRON("dark"), seg=6)
	for y in (-D / 2 + 0.05, D / 2 - 0.05):
		B((0.05, 0.04, 0.03), (-W / 2 + 0.26, y, H + 0.055), IRON("dark"), bevel=0.004)
	turned([(0.06, 0.0), (0.075, 0.09), (0.068, 0.09), (0.054, 0.012), (0.004, 0.01), (0.004, 0.0)], (0.35, -D / 2 + t / 2, H + 0.047), CU(), seg=16)
	rod((0.425, -D / 2 + t / 2, H + 0.08), (0.65, -D / 2 + t / 2, H + 0.06), 0.012, WOOD("b"), seg=6)
	group(lambda: tongs(0.5, "bolt", hook=False), at=(-W / 2 + 0.26 - 0.01, -0.0, H + 0.045 + 0.02), rot=(0, 90, 90))


def ef_grinding_wheel():
	R, zc = 0.32, 0.66
	grind_frame(R, zc)
	kit.cylinder(0.018, 0.68, (0.04, 0, zc), IRON("dark"), rot=(0, 90, 0), verts=8)
	kit.cylinder(R, 0.1, (0, 0, zc), T("warmstone", "b"), rot=(0, 90, 0), verts=28, bevel=0.012)
	for s in (-1, 1):
		kit.cylinder(0.08, 0.02, (s * 0.055, 0, zc), IRON("dark"), rot=(0, 90, 0), verts=12)
		for k in range(4):
			a = 2 * math.pi * k / 4 + 0.4
			kit.rivet((s * 0.066, math.cos(a) * 0.055, zc + math.sin(a) * 0.055), IRON("a"), r=0.008)
	# crank and treadle
	rod((0.374, 0, zc - 0.02), (0.374, 0, zc - 0.18), 0.013, IRON("dark"), seg=6)
	kit.cylinder(0.034, 0.032, (0.374, 0, zc), IRON("a"), rot=(0, 90, 0), verts=12)
	kit.cylinder(0.018, 0.12, (0.43, 0, zc - 0.18), WOOD("b"), rot=(0, 90, 0), verts=8)
	rod((0.37, 0, zc - 0.18), (0.37, -0.28, 0.12), 0.01, WOOD("b"), seg=6)
	B((0.12, 0.34, 0.03), (0.37, -0.24 + 0.0, 0.1), WOOD(), bevel=0.006, rot=(-12, 0, 0))
	rod((0.37, 0.12, 0.055), (0.37, 0.12, 0.1), 0.02, WOOD("dark"), seg=6)
	B((0.06, 0.06, 0.05), (0.37, 0.12, 0.03), WOOD("dark"), bevel=0.006)
	# water trough under the wheel
	for x in (-0.12, 0.12):
		B((0.06, 0.5, 0.03), (x, 0, 0.137), WOOD("dark"), bevel=0.005)
	for y in (-0.12, 0.12):
		B((0.36, 0.025, 0.12), (0, y, 0.21), WOOD(), bevel=0.005)
	for x in (-0.17, 0.17):
		B((0.025, 0.22, 0.12), (x, 0, 0.21), WOOD(), bevel=0.005)
	B((0.33, 0.22, 0.025), (0, 0, 0.162), WOOD("dark"), bevel=0.005)
	# copper drip pot on a post above the wheel
	dz = 0.08
	rod((-0.24, 0.03, zc), (-0.24, 0.03, zc + 0.48 + dz), 0.02, WOOD(), seg=6)
	rod((-0.24, 0.03, zc + 0.46 + dz), (-0.02, 0.03, zc + 0.46 + dz), 0.016, WOOD(), seg=6)
	turned([(0.05, 0.0), (0.07, 0.04), (0.065, 0.12), (0.058, 0.12), (0.062, 0.04), (0.045, 0.01), (0.004, 0.008), (0.004, 0.0)], (0.0, 0.03, zc + 0.31 + dz), CU(), seg=14)
	rod((0.0, 0.03, zc + 0.43 + dz), (0.0, 0.03, zc + 0.46 + dz), 0.005, IRON("dark"), seg=5)
	for s in (-1, 1):
		rod((s * 0.064, 0.03, zc + 0.42 + dz), (0, 0.03, zc + 0.47 + dz), 0.004, IRON("dark"), seg=5)
	kit.cone(0.01, 0.004, 0.04, (0, 0.03, zc + 0.3 + dz), CU("dark"), rot=(180, 0, 0), verts=8)


def ef_swage_block():
	# the stand: four legs, rails, iron bands
	for x in (-0.2, 0.2):
		for y in (-0.2, 0.2):
			B((0.08, 0.08, 0.5), (x, y, 0.25), WOOD("dark"), bevel=0.01)
	for z in (0.12, 0.46):
		for y in (-0.2, 0.2):
			B((0.36, 0.05, 0.06), (0, y, z), WOOD(), bevel=0.006)
		for x in (-0.2, 0.2):
			B((0.05, 0.36, 0.06), (x, 0, z), WOOD(), bevel=0.006)
	for x in (-0.2, 0.2):
		for y in (-0.2, 0.2):
			B((0.088, 0.088, 0.03), (x, y, 0.4), IRON("dark"), bevel=0.003)
	B((0.5, 0.5, 0.04), (0, 0, 0.51), WOOD(), bevel=0.008)
	# the swage block
	S, Hh = 0.42, 0.15
	blk = B((S, S, Hh), (0, 0, 0.53 + Hh / 2 - 0.003), IRON("b"), bevel=0.012)
	ztop = 0.53 + Hh - 0.003
	cuts = []
	for i, (x, y, r, sq) in enumerate([(-0.12, -0.12, 0.03, False), (0.0, -0.12, 0.022, True), (0.12, -0.12, 0.015, False), (-0.12, 0.0, 0.02, True),
		(0.0, 0.0, 0.045, False), (0.12, 0.0, 0.026, True), (-0.12, 0.12, 0.012, False), (0.0, 0.12, 0.03, True), (0.12, 0.12, 0.018, False)]):
		if sq:
			cuts.append(B((r * 2, r * 2, Hh + 0.04), (x, y, ztop - Hh / 2), GROOVE(), bevel=0))
		else:
			cuts.append(kit.cylinder(r, Hh + 0.04, (x, y, ztop - Hh / 2), GROOVE(), verts=12, bevel=0))
	for k, r in enumerate((0.04, 0.03, 0.022, 0.015)):  # half-round grooves on the front edge
		cuts.append(kit.cylinder(r, Hh + 0.04, (-0.15 + k * 0.1, -S / 2, ztop - Hh / 2), GROOVE(), verts=12, bevel=0))
	for k, w in enumerate((0.05, 0.035, 0.025)):  # V notches on the side edge
		cuts.append(B((w, w, Hh + 0.04), (S / 2, -0.12 + k * 0.12, ztop - Hh / 2), GROOVE(), bevel=0, rot=(0, 0, 45)))
	cut(blk, cuts)
	# fullers and punches resting on top, a hold-down
	group(lambda: punch(0.22, 0.014, "point"), at=(-0.05, 0.06, ztop + 0.014), rot=(0, 90, 20))
	group(lambda: punch(0.18, 0.012, "flat"), at=(0.06, 0.19, ztop + 0.012), rot=(0, 90, -5))
	kit.cylinder(0.03, 0.035, (0.13, -0.06, ztop + 0.015), IRON("a"), verts=10)
	rod((0.13, -0.06, ztop + 0.03), (0.13, -0.06, ztop + 0.2), 0.012, IRON("dark"), seg=6)
	B((0.09, 0.022, 0.012), (0.13, -0.06, ztop + 0.2), IRON("dark"), bevel=0.003)


def ef_coal_bunker():
	W, D, H = 1.2, 0.85, 0.62
	t = 0.13
	brick_box(W, t, H, at=(0, D / 2 - t / 2, 0))
	for s in (-1, 1):
		brick_box(t, D - t + 0.01, H, at=(s * (W / 2 - t / 2), -t / 2 + 0.005, 0), sides="lrf")
	brick_box(W - 2 * t + 0.02, t, 0.2, at=(0, -D / 2 + t / 2, 0), sides="fb")
	for y in (D / 2 - t / 2,):
		B((W + 0.04, t + 0.05, 0.06), (0, y, H + 0.018), LIME(), bevel=0.012)
	for x in (-W / 2 + t / 2, W / 2 - t / 2):
		B((t + 0.05, D - t - 0.03, 0.06), (x, -t / 2 - 0.01, H + 0.018), LIME(), bevel=0.012)
	B((W - 2 * t + 0.06, t + 0.04, 0.05), (0, -D / 2 + t / 2, 0.2 + 0.013), LIME(), bevel=0.01)
	B((W - 2 * t + 0.01, D - 2 * t + 0.01, 0.06), (0, 0, 0.03), COALDUST(), bevel=0.004)
	coal_heap(0, 0.02, 0.05, 0.42, 0.36, 0.5, n=230, seed=8, smax=0.13, smin=0.02, fines=210)
	# a few lumps spilled over the low front wall
	coal_bits([(-0.2, -0.53), (0.05, -0.57), (0.22, -0.52), (-0.33, -0.6), (0.4, -0.58)], 0.0, s=0.04, seed=12)
	coal_bits([(-0.12, -0.55), (0.14, -0.6), (0.3, -0.5), (-0.27, -0.66), (0.0, -0.66), (0.48, -0.53)], 0.0, s=0.018, seed=31)
	# shovel stuck in the coal
	group(lambda: [prism([(-0.075, 0.0), (0.075, 0.0), (0.085, 0.2), (-0.085, 0.2)], -0.005, 0.005, IRON("dark"), axis="y"),
		rod((0, 0, 0.19), (0, 0, 0.82), 0.016, WOOD("b"), seg=8), B((0.14, 0.03, 0.03), (0, 0, 0.83), WOOD("b"), bevel=0.006),
		kit.ring(0.02, 0.006, (0, 0, 0.22), IRON("dark"), seg=10)], at=(0.1, -0.05, 0.25), rot=(-20, 10, 0))
	slim(small=0.03, fine=0.012, few=0.02)  # lighter file (under 2 MB), same look


def ef_ember_pan():
	R = 0.32
	turned([(0.2, 0.0), (R, 0.11), (R + 0.02, 0.13), (R + 0.005, 0.13), (R - 0.012, 0.11), (0.19, 0.015), (0.004, 0.015), (0.004, 0.0)], (0, 0, 0.32), IRON("dark"), seg=24)
	kit.ring(R + 0.012, 0.012, (0, 0, 0.45), IRON("dark"), seg=28)
	for k in range(3):
		a = 2 * math.pi * k / 3 + 0.5
		rod((math.cos(a) * 0.16, math.sin(a) * 0.16, 0.33), (math.cos(a) * 0.34, math.sin(a) * 0.34, 0.0), 0.02, IRON("dark"), seg=6)
		B((0.07, 0.07, 0.02), (math.cos(a) * 0.34, math.sin(a) * 0.34, 0.01), IRON("dark"), bevel=0.004, rot=(0, 0, math.degrees(a)))
	for s in (-1, 1):
		kit.ring(0.04, 0.009, (s * (R + 0.05), 0, 0.44), IRON("dark"), rot=(90, 0, 0), seg=12)
	coal_heap(0, 0, 0.33, 0.24, 0.24, 0.12, n=55, seed=5, smax=0.07, fines=40)
	# a poker resting across the rim
	rod((-0.42, -0.08, 0.465), (0.44, 0.1, 0.465), 0.011, IRON("dark"), seg=6)
	kit.ring(0.03, 0.007, (-0.46, -0.09, 0.465), IRON("dark"), seg=10)
	kit.cone(0.011, 0.002, 0.06, (0.47, 0.107, 0.465), IRON("a"), rot=(0, 90, 12), verts=6)


def ef_bar_stock_rack():
	for x in (-0.55, 0.55):
		B((0.1, 0.5, 0.08), (x, 0, 0.04), WOOD("dark"), bevel=0.01)
		B((0.09, 0.1, 1.26), (x, 0.15, 0.67), WOOD(), bevel=0.01)
		prism([(0.1, 0.1), (0.1, 0.35), (-0.12, 0.08)], x - 0.04, x + 0.04, WOOD("dark"), axis="x")
		for z in (0.4, 0.75, 1.1):
			B((0.08, 0.3, 0.05), (x, 0.0, z), WOOD("dark"), bevel=0.008)
			B((0.08, 0.03, 0.06), (x, -0.135, z + 0.04), WOOD("dark"), bevel=0.006)
			kit.rivet((x - 0.04, 0.15, z), IRON("dark"), r=0.01)
	B((1.17, 0.06, 0.06), (0, 0.15, 1.24), WOOD("dark"), bevel=0.008)
	for zi, (z, kinds) in enumerate(((0.4, "iii c ii"), (0.75, "cc ii ic"), (1.1, "i c i c i"))):
		bars = [k for k in kinds if k != " "]
		for j, k in enumerate(bars):
			y = 0.08 - j * 0.032
			if k == "i":
				B((1.35 + J(0.08), 0.022, 0.022), (J(0.03), y, z + 0.034), IRON("dark"), bevel=0.003)
			else:
				kit.cylinder(0.011, 1.3 + J(0.08), (J(0.03), y, z + 0.034), CU("b"), rot=(0, 90, 0), verts=8, bevel=0.002)
	# a bin of short bars at the foot
	bx = 0.0
	for s in (-1, 1):
		B((0.5, 0.025, 0.22), (bx, -0.2 + s * 0.09, 0.11), WOOD(), bevel=0.005)
		B((0.025, 0.155, 0.22), (bx + s * 0.25, -0.2, 0.11), WOOD(), bevel=0.005)
	B((0.47, 0.155, 0.03), (bx, -0.2, 0.015), WOOD("dark"), bevel=0.005)
	for k in range(9):
		x = bx - 0.2 + 0.05 * k
		ang = J(8)
		if k % 3 == 2:
			kit.cylinder(0.01, 0.4, (x, -0.2 + J(0.04), 0.226), CU("b"), rot=(ang, 0, 0), verts=8, bevel=0.002)
		else:
			B((0.02, 0.02, 0.42), (x, -0.2 + J(0.04), 0.236), IRON("dark"), bevel=0.003, rot=(ang, 0, 0))


def ef_apprentice_bench():
	top = bench(1.2, 0.5, 0.72)
	z = top
	# stake anvil on its block
	B((0.16, 0.16, 0.1), (-0.42, -0.04, z + 0.05 - 0.003), WOOD("dark"), bevel=0.01)
	kit.taper(0.08, 0.06, 0.12, 0.08, 0.08, (-0.42, -0.04, z + 0.095), IRON("dark"))
	B((0.16, 0.08, 0.025), (-0.42, -0.04, z + 0.185), IRON("b"), bevel=0.004)
	kit.cone(0.03, 0.006, 0.09, (-0.535, -0.04, z + 0.18), IRON("dark"), rot=(0, -90, 0), verts=10)
	# a row of half-made knives, rough to finished
	for i in range(5):
		x = -0.25 + 0.08 * i
		m = IRON("dark") if i < 4 else STEEL()
		prism([(x - 0.014, -0.18), (x + 0.014, -0.18), (x + 0.012 + 0.002 * i, 0.0), (x, 0.03 + 0.004 * i), (x - 0.01, 0.0)], z, z + 0.006, m, axis="z")
		if i >= 2:
			B((0.026, 0.1, 0.022), (x, -0.23 + 0.0, z + 0.011), WOOD("b") if i >= 3 else IRON("dark"), bevel=0.005)
		if i == 4:
			kit.ring(0.014, 0.004, (x, -0.178, z + 0.011), CU(), rot=(90, 0, 0), seg=8)
	# a nail header with nails standing in it, and a tray of nails
	B((0.22, 0.04, 0.012), (0.25, -0.15, z + 0.006), IRON("dark"), bevel=0.003)
	sphere((0.25, -0.15, z + 0.015), 0.025, IRON("dark"), scale=(1, 1, 0.5))
	for s in (-1, 1):
		sphere((0.25 + s * 0.1, -0.15, z + 0.012), 0.012, IRON("a"))
	for s in (-1, 1):
		B((0.15, 0.012, 0.035), (0.3, 0.04 + s * 0.05, z + 0.017), WOOD("dark"), bevel=0.003)
		B((0.012, 0.088, 0.035), (0.3 + s * 0.069, 0.04, z + 0.017), WOOD("dark"), bevel=0.003)
	B((0.13, 0.088, 0.01), (0.3, 0.04, z + 0.004), WOOD("dark"), bevel=0.002)
	for k in range(14):
		x, y = 0.25 + (k % 5) * 0.025, 0.01 + (k // 5) * 0.028
		rod((x, y, z + 0.012), (x + 0.03, y + J(0.01), z + 0.016 + 0.003 * (k % 2)), 0.003, IRON("dark"), seg=4)
		sphere((x, y, z + 0.012), 0.005, IRON("dark"))
	# file, small hammer, water cup in a neat row at the back
	group(lambda: file_tool(0.2, 0.02), at=(-0.3, 0.14, z + 0.017), rot=(90, 0, 90))
	group(lambda: hammer(0.24, 0.11, 0.036, "ball"), at=(-0.02, 0.16, z + 0.0195), rot=(90, 0, 90))
	turned([(0.04, 0.0), (0.046, 0.08), (0.04, 0.08), (0.035, 0.01), (0.004, 0.01), (0.004, 0.0)], (0.45, 0.14, z - 0.002), CLAY("b"), seg=14)
	# bar stock on the shelf
	for k in range(5):
		B((0.9, 0.02, 0.02), (0, -0.08 + k * 0.04, 0.2 + 0.024), IRON("dark"), bevel=0.003)


def ef_cooling_rack(empty=False):
	W, D = 1.3, 0.5
	for x in (-W / 2 + 0.1, W / 2 - 0.1):
		for y in (-D / 2 + 0.06, D / 2 - 0.06):
			B((0.18, 0.14, 0.1), (x, y, 0.05), brick_m(), bevel=0.012)
			B((0.04, 0.04, 0.6), (x, y, 0.4), IRON("dark"), bevel=0.004)
			B((0.06, 0.06, 0.02), (x, y, 0.1 + 0.008), IRON("dark"), bevel=0.003)
	for y in (-D / 2 + 0.06, D / 2 - 0.06):
		B((W - 0.16, 0.035, 0.035), (0, y, 0.68), IRON("dark"), bevel=0.004)
		B((W - 0.16, 0.025, 0.025), (0, y, 0.25), IRON("dark"), bevel=0.003)
	for k in range(6):
		x = -W / 2 + 0.16 + k * (W - 0.32) / 5
		B((0.03, D - 0.06, 0.03), (x, 0, 0.7), IRON("dark"), bevel=0.004)
	for x in (-W / 2 + 0.1, W / 2 - 0.1):
		for y in (-D / 2 + 0.06, D / 2 - 0.06):
			kit.rivet((x, y, 0.72), IRON("a"), r=0.011)
	zt = 0.715
	for i in range(0 if empty else 5):
		y = -0.17 + 0.085 * i
		bm = STEEL() if i % 2 == 0 else IRON("b")
		group(lambda bm=bm, L=0.8 + 0.04 * (i % 3): sword(L, 0.052, 0.16, ("disc", "ball")[i % 2], blade_m=bm, grip=(i % 2 == 0)),
			at=(-0.46, y, zt + 0.0065 + (0.012 if i % 2 == 0 else 0.0)), rot=(90, 0, 90))
	# a copper drip tray on the lower rails
	B((0.7, D - 0.1, 0.02), (0, 0, 0.27), CU("dark"), bevel=0.004)
	for s in (-1, 1):
		B((0.68, 0.012, 0.04), (0, s * 0.199, 0.29), CU("dark"), bevel=0.003)


def ef_whetstone_table():
	top = bench(1.0, 0.5, 0.75, shelf=True)
	z = top
	# a wooden holder with four whetstones in grit order (coarse ochre to fine pale)
	B((0.5, 0.14, 0.04), (-0.15, 0.12, z + 0.017), WOOD("dark"), bevel=0.006)
	for k, m in enumerate((T("brickochre", "dark"), T("brickochre", "a"), CLAY("b"), LIME("a"))):
		B((0.1, 0.07, 0.035 - 0.003 * k), (-0.33 + k * 0.12, 0.12, z + 0.045), m, bevel=0.008)
	# a big bench stone in its tray with a blade on it
	B((0.3, 0.12, 0.03), (0.2, -0.08, z + 0.012), WOOD("dark"), bevel=0.005)
	B((0.24, 0.08, 0.05), (0.2, -0.08, z + 0.045), T("brickochre", "b"), bevel=0.01)
	group(lambda: sword(0.7, 0.05, 0.15, "ball"), at=(-0.25, -0.08, z + 0.0755), rot=(90, 0, 90))
	# copper oil flask, leather strop, a cloth-free row of small slips
	turned([(0.035, 0.0), (0.045, 0.06), (0.03, 0.11), (0.012, 0.13), (0.012, 0.15), (0.006, 0.15), (0.006, 0.12), (0.004, 0.01), (0.004, 0.0)], (0.4, 0.15, z - 0.002), CU(), seg=14)
	kit.cylinder(0.014, 0.025, (0.4, 0.15, z + 0.155), WOOD("b"), verts=8)
	B((0.06, 0.5, 0.02), (-0.47, -0.02, z + 0.008), WOOD("b"), bevel=0.004)
	B((0.05, 0.4, 0.006), (-0.47, -0.04, z + 0.021), LEA("b"), bevel=0.001)
	for k in range(3):
		B((0.05, 0.02, 0.015), (0.25 + k * 0.06, 0.14, z + 0.0075), T("brickochre", "c"), bevel=0.003)


def ef_scrap_bin():
	W, D, H = 0.8, 0.55, 0.5
	for s in (-1, 1):
		B((W, 0.03, H), (0, s * (D / 2 - 0.015), H / 2 + 0.03), WOOD(), bevel=0.006)
		B((0.03, D - 0.06, H), (s * (W / 2 - 0.015), 0, H / 2 + 0.03), WOOD(), bevel=0.006)
	B((W - 0.04, D - 0.04, 0.03), (0, 0, 0.045), WOOD("dark"), bevel=0.005)
	for x in (-W / 2 + 0.07, W / 2 - 0.07):
		for y in (-D / 2 + 0.07, D / 2 - 0.07):
			B((0.08, 0.08, 0.03), (x, y, 0.015), WOOD("dark"), bevel=0.005)
	for z in (0.1, H - 0.02):
		for s in (-1, 1):
			B((W + 0.012, 0.008, 0.04), (0, s * (D / 2 + 0.002), z), IRON("dark"), bevel=0.002)
			B((0.008, D + 0.012, 0.04), (s * (W / 2 + 0.002), 0, z), IRON("dark"), bevel=0.002)
	for x in (-W / 2, W / 2):
		for y in (-D / 2, D / 2):
			B((0.03, 0.03, H + 0.02), (x, y, H / 2 + 0.04), IRON("dark"), bevel=0.004)
	# a heaped fill of offcuts (dark iron bits, angular)
	group(lambda: rubble_heap(0, 0, 0.34, 0.22, 0.45, [IRON("dark"), IRON("a"), CU("dark"), IRON("b")], n=55, smax=0.08, smin=0.03, dirt=IRON("dark"), seed=2), at=(0, 0, 0.06))
	def surf(x, y):  # the heap's surface height (same shape as rubble_heap)
		d = math.hypot(x / 0.34, y / 0.22)
		return 0.06 + 0.9 * 0.45 * max(0.0, 1 - d) ** 0.85
	# broken swords stuck blade-down in the heap, hilts up
	for (x, y), tilt, L0 in (((-0.2, -0.04), 18, 0.5), ((0.06, 0.06), -12, 0.45), ((0.2, -0.06), 24, 0.4)):
		group(lambda L0=L0: sword(0.85, 0.055, 0.18, "disc", cut_at=L0), at=(x, y, surf(x, y) + L0 - 0.15 - 0.1), rot=(0, 180 + tilt, J(40)))
	# snapped tips and offcut bars lying on (and into) the heap
	for k, (x, y) in enumerate(((-0.12, 0.1), (0.1, -0.12), (0.15, 0.09), (-0.15, -0.1))):
		a_ = math.radians(rng.uniform(70, 110))
		group(lambda: sword_tip(0.45, 0.8, 0.05), at=(x - 0.62 * math.sin(a_), y + 0.62 * math.cos(a_), surf(x, y) - 0.004), rot=(90, 0, math.degrees(a_)))
	for k in range(8):
		x, y = -0.24 + 0.065 * k, J(0.12)
		B((0.18 + 0.06 * (k % 3), 0.022, 0.022), (x, y, surf(x, y) + 0.002), IRON("dark") if k % 3 else CU("dark"), bevel=0.003, rot=(J(12), J(12), J(180)))


def ef_coal_scuttle(empty=False):
	# a tall copper scuttle: tapered body, rolled rim, a pouring lip, bail handle, foot ring
	turned([(0.16, 0.03), (0.2, 0.42), (0.215, 0.43), (0.2, 0.44), (0.188, 0.43), (0.15, 0.045), (0.004, 0.045), (0.004, 0.03)], (0, 0, 0), CU("b"), seg=22)
	kit.cylinder(0.165, 0.035, (0, 0, 0.0175), CU("dark"), verts=22, bevel=0.004)
	prism([(-0.11, -0.19), (0.11, -0.19), (0.07, -0.31), (-0.07, -0.31)], 0.4, 0.408, CU("b"), axis="z")
	for z in (0.1, 0.3):
		kit.ring(0.16 + 0.04 * (z - 0.03) / 0.4 + 0.006, 0.007, (0, 0, z), IRON("dark"), seg=24)
	for s in (-1, 1):
		B((0.02, 0.04, 0.06), (s * 0.205, 0, 0.38), IRON("dark"), bevel=0.003)
	pts = [(math.cos(math.pi * k / 10) * 0.215, 0.38 + math.sin(math.pi * k / 10) * 0.22) for k in range(11)]
	for a, b in zip(pts, pts[1:]):
		rod((a[0], 0, a[1]), (b[0], 0, b[1]), 0.008, IRON("dark"), seg=6)
	kit.cylinder(0.02, 0.1, (0, 0, 0.6), WOOD("b"), rot=(0, 90, 0), verts=8)
	if empty:  # looted: the inside floor shows, a little coal dust left
		kit.cylinder(0.148, 0.008, (0, 0, 0.051), COALDUST(), verts=22, bevel=0)
	else:
		coal_heap(0, 0, 0.38, 0.17, 0.17, 0.12, n=70, seed=6, smax=0.06, smin=0.015, fines=45)
	# a small hand shovel stuck in the coal (gone with the coal when looted)
	if not empty:
		group(lambda: [prism([(-0.05, 0.0), (0.05, 0.0), (0.055, 0.12), (-0.055, 0.12)], -0.004, 0.004, IRON("dark"), axis="y"),
			rod((0, 0, 0.11), (0, 0, 0.3), 0.012, WOOD("b"), seg=6)], at=(0.06, 0.04, 0.42), rot=(-25, 15, 0))
	# an iron fire shovel leaning on it
	group(lambda: [prism([(-0.08, 0.0), (0.08, 0.0), (0.07, 0.2), (-0.07, 0.2)], -0.004, 0.004, IRON("dark"), axis="y"),
		rod((0, 0, 0.19), (0, 0, 0.9), 0.012, IRON("dark"), seg=6), kit.ring(0.035, 0.008, (0, 0, 0.93), IRON("dark"), rot=(90, 0, 0), seg=12)],
		at=(0.36, -0.12, 0.03), rot=(0, -17, 0))
	settle([o for o in bpy.data.objects if o.type == "MESH"][-3:])
	if not empty:
		coal_bits([(-0.25, -0.15), (0.0, -0.3), (-0.2, 0.15)], 0.0, s=0.035, seed=4)


def ef_ring_mandrel():
	group(lambda: stump(0.2, 0.42, bands=(0.07, 0.34)))
	z = 0.432
	B((0.18, 0.18, 0.02), (0, 0, z + 0.008), IRON("dark"), bevel=0.004)
	for x in (-1, 1):
		for y in (-1, 1):
			kit.rivet((x * 0.07, y * 0.07, z + 0.02), IRON("a"), r=0.009)
	H, r0, r1 = 0.6, 0.075, 0.015
	kit.cone(r0, r1, H, (0, 0, z + 0.015 + H / 2), IRON("dark"), verts=16, bevel=0.003)
	sphere((0, 0, z + 0.015 + H), r1 * 1.1, IRON("a"))
	# finished rings slid down until they fit
	for k, (R, m) in enumerate(((0.06, IRON("a")), (0.05, CU("b")), (0.042, IRON("a")), (0.034, GOLD()), (0.027, IRON("a")), (0.022, CU("b")))):
		w = 0.008 + 0.002 * (k % 2)
		rr = R - w
		zz = z + 0.015 + (r0 - rr) / (r0 - r1) * H
		kit.ring(R - w / 2, w, (0, 0, zz), m, seg=20)
	# a small hammer and a few rings on the stump
	group(lambda: hammer(0.22, 0.1, 0.032, "ball"), at=(-0.12, -0.08, z + 0.0175), rot=(90, 0, 70))
	for k in range(3):
		kit.ring(0.03, 0.007, (-0.1 + 0.02 * k, 0.11 - 0.012 * k, z + 0.007 + 0.012 * k), IRON("a") if k != 1 else CU("b"), seg=16)


def ef_coal_scuttle_empty():
	ef_coal_scuttle(True)


def ef_cooling_rack_empty():
	ef_cooling_rack(True)


def ef_ingot_wall_empty():
	ef_ingot_wall(True)


MODELS = {k: v for k, v in globals().items() if k.startswith("ef_") and callable(v)}

if __name__ == "__main__":
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	outdir = GAME / "assets" / "models" / "decor"
	jdir = GAME / "journey" / "3d" / "v2_hand_built" / "decor"
	outdir.mkdir(parents=True, exist_ok=True)
	jdir.mkdir(parents=True, exist_ok=True)
	for name in args or list(MODELS):
		rng.seed(sum(map(ord, name.removesuffix("_empty"))))  # an _empty twin gets the same bricks and wobble
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
