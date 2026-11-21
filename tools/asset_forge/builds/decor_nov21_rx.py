# Decor set RX (Nov 21): decor for two RUINS the player can rebuild.
#   BREWHALL (rb_): a dwarf brewery and drinking hall in clay brick (Hearthbrick style: brick, ochre brick, clay,
#                   one warm wood, copper, iron).
#   LANTERN SPIRE (rs_): a tall cut-stone beacon tower (Stonehold style: greystone, worn brass, iron, glass, dark wood).
#   blender --background --factory-startup --python builds/decor_nov21_rx.py -- [id ...]   (none = all)
# Output: assets/models/decor/<id>.glb (origin bottom-centre, front faces -Y in Blender = +Z in Godot).
# Wall pieces have a flat back at +Y and stand on the floor (a foot), so they never float.
#
# The 24 objects:
#  rb_mash_tun            a big staved mash tun on a brick plinth: slotted false bottom, mash rake leaning in it,
#                         half lid of planks, long copper tap over a bucket, a brick step
#  rb_brew_kettle         the brewing kettle: arched brick hearth (cold and empty: sooty floor, bare iron grate), riveted copper kettle with a lid
#                         set ajar, an iron swing crane with a chained ladle, split firewood stacked beside
#  rb_fermenting_vats     three tall fermenting vats on a timber stillage: hoops, spigots, tally tags with notches
#                         cut in; the middle vat's lid leans against it
#  rb_vat_burst           (story) a fermenting vat burst: staves splayed out like petals, some fallen flat, hoops
#                         sprung onto the floor, the lid split in two, a mallet and the spigot dropped
#  rb_drying_rack         (wall) a real drying rack: two side frames with runners, four slatted trays (one pulled out,
#                         one empty), mushroom slices and hop cones laid in rows, hop bundles tied under the top rails
#  rb_grain_quern         a grain quern on a brick stand: two millstones (dressing grooves cut in, iron rynd, handle),
#                         a wooden chute into a flour bin, scoop and brush
#  rb_cask_bay            (wall) a brick arch cellar bay with casks stacked on a cradle: copper taps, brand marks cut
#                         into the heads, one top place empty with its chock
#  rb_cooper_bench        the cooper's shaving horse with a stave clamped, drawknife, mallet; a barrel being raised
#                         (staves splayed in its raising hoops), spare hoops and rough staves
#  rb_horn_wall           (wall) a plank board of hollow drinking horns (9 cm apart) on fitted peg pairs, copper rims and tips, runes cut
#                         in the top rail; one place empty, its horn fallen onto the foot
#  rb_feast_table_broken  (story) a long feast table snapped in the middle: one half still set with tankards and
#                         trenchers, the other half sloping to the floor, a bench tipped over, a tankard rolled away
#  rb_recipe_board        (wall) the brewmaster's recipe tablet: clay set in a brick pier, kettle, mushroom and grain
#                         pictures and rune rows with tallies CUT in; copper measures on a shelf below
#  rb_cask_rolled         (story) a cask rolled off its cradle: one stave burst out, a hoop slipped off, tap and bung
#                         on the floor, a chock kicked away
#  rs_oil_jar_stand       a cut-stone stand with three lamp-oil jars sunk in round holes, the middle one open and hollow with a brass
#                         dipper, a brass funnel, a flame sign and runes cut into the front
#  rs_lens_workbench      the keeper's wick and lens workbench: stone trestles, lens clamped in a polishing stand with
#                         a cranked lap, glass blanks, wick bobbins, calipers, grit pot
#  rs_great_lens_cradle   the great lens in its brass ring, swung in a brass yoke on a turning ring with a toothed
#                         crank, all on a stepped carved stone plinth
#  rs_reflector_plates    (wall) a stone panel with three polished brass reflector dishes on iron brackets, a sun sign
#                         cut in, a polishing stone on a ledge
#  rs_signal_shutters     (wall) a stone frame with wooden signal shutters SHUT on a tie bar, an iron lever with
#                         a chain to a floor ring, dark behind (lamp out)
#  rs_keeper_log_desk     the keeper's standing log desk: stone pedestal, sloped top with an open log, sand-glass,
#                         inkwell and quill, oil gauge stick; old logs stacked in the pedestal shelf
#  rs_oil_hoist           (wall) a stone pilaster with an iron jib, a spoked pulley, rope down to an oil jar in a
#                         rope cradle, the other end made fast round a cleat
#  rs_chimney_rack        (wall) a stone block of carved cubbies holding glass lamp chimneys and brass lens rings,
#                         brass label plates; one chimney lies cracked
#  rs_wick_board          (wall) a stone wick board: iron spindles of wick bobbins, wick tails through brass guides,
#                         shears and a trimming knife on hooks, cut wicks laid in a tray
#  rs_lantern_cage_fallen (story) the great lantern's iron cage fallen on its side: bars bent, the roof cone knocked
#                         off, glass shards around, a cracked chunk of its stone seat
#  rs_lens_shattered      (story) the great lens fallen: brass ring bent open, the glass broken in big curved pieces,
#                         the yoke tipped over, a pivot pin on the floor
#  rs_keeper_last_watch   (story) the keeper's last watch: stone ledge with a burnt-out lamp, stool knocked over, the
#                         log fallen open on the floor, oil can tipped, hand bell dropped
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from night_stations import B, GAME, J, T, kit, log, mesh, rng  # noqa: E402
from night_materials import C, sphere, _cm  # noqa: E402
from decor_nov21_a import bar, chain, circ, floor_cut, low_z, prism, rod, shift, slim, tube, turn  # noqa: E402
from decor_nov21_a import carve as carve_all  # noqa: E402
from decor_nov21_th import S, GROOVE, IRON, CU, carve, cy, gline, runes, group, foot, candle, flat_back  # noqa: E402
from decor_nov21_f import glass, lathe as cup, toothed_gear  # noqa: E402

W = lambda v=None: T("wood", v)  # noqa: E731  (the one wood family)
BRK = lambda v=None: T("brick", v)  # noqa: E731
OCH = lambda v=None: T("brickochre", v)  # noqa: E731
CLAYT = lambda v=None: T("clay", v)  # noqa: E731
QS = lambda v=None: T("warmstone", v)  # noqa: E731  (millstones)
DRIED = lambda s=0.0: C((0.36 + s, 0.25 + s, 0.15 + s), 0.9)  # noqa: E731  dried mushroom
GILL = lambda: C((0.5, 0.42, 0.3), 0.9)  # noqa: E731
HOP = lambda s=0.0: C((0.38 + s, 0.4 + s, 0.17), 0.85)  # noqa: E731  dried hop cone
CORD = lambda: kit.tex_mat("rope", "a")  # noqa: E731
DARK = lambda: C((0.03, 0.025, 0.02), 0.95)  # noqa: E731  (inside of a mouth/hole)
WAX = lambda: C((0.55, 0.47, 0.32), 0.85)  # noqa: E731
PAPER = lambda: C((0.7, 0.62, 0.46), 0.95)  # noqa: E731
INK = lambda: C((0.03, 0.025, 0.03), 0.3)  # noqa: E731
SOOT = lambda: C((0.05, 0.045, 0.04), 0.9)  # noqa: E731
GLOWL = lambda: C((1.0, 0.62, 0.25), 0.4, glow=1.6)  # noqa: E731  (lamp light behind shutters)


def BRASS(v="a"):
	"""Warm worn brass: the silver painting multiplied by a warm yellow (same recipe as decor_nov21_bv)."""
	key = ("brass", v)
	if key in kit._mats:
		return kit._mats[key]
	m = kit.tex_mat("silver", v).copy()
	m.name = f"brass_{v}"
	nt, b = m.node_tree, m.node_tree.nodes["Principled BSDF"]
	src = b.inputs["Base Color"].links[0].from_node.outputs["Color"]
	mix = nt.nodes.new("ShaderNodeMix")
	mix.data_type, mix.blend_type = "RGBA", "MULTIPLY"
	mix.inputs["Factor"].default_value = 1.0
	nt.links.new(src, mix.inputs[6])
	mix.inputs[7].default_value = (0.95, 0.68, 0.3, 1)
	nt.links.new(mix.outputs[2], b.inputs["Base Color"])
	b.inputs["Metallic"].default_value = 0.65
	b.inputs["Roughness"].default_value = 0.42
	kit._mats[key] = m
	return m


# ================= helpers =================
def new_since(before):
	return [o for o in bpy.data.objects if o not in before]


def along(build, p0, p1):
	"""Build a part along +Z from the origin (build gets the length), then aim it from p0 to p1."""
	a, b = Vector(p0), Vector(p1)
	d = b - a
	before = set(bpy.data.objects[:])
	build(d.length)
	bpy.context.view_layer.update()
	M = Matrix.Translation(a) @ d.to_track_quat("Z", "Y").to_matrix().to_4x4()
	new = new_since(before)
	for o in new:
		o.matrix_world = M @ o.matrix_world
	return new


def drop(parts, z=0.0):
	bpy.context.view_layer.update()
	shift(parts, (0, 0, z - low_z(parts)))
	return parts


def ring_mesh(c, prof, m, seg=24):
	"""A closed ring: a closed (r, z) outline spun round the vertical axis at c (no end caps)."""
	x0, y0, z0 = c
	v = [(x0 + math.cos(2 * math.pi * k / seg) * r, y0 + math.sin(2 * math.pi * k / seg) * r, z0 + z) for r, z in prof for k in range(seg)]
	n = len(prof)
	f = [(i * seg + k, i * seg + (k + 1) % seg, ((i + 1) % n) * seg + (k + 1) % seg, ((i + 1) % n) * seg + k) for i in range(n) for k in range(seg)]
	return mesh(v, f, m)


def hoop(c, r, w=0.035, t=0.012, m=None, seg=28, rivets=0):
	"""A flat iron hoop band round a vessel of radius r at height c[2] (pressed 5 mm into the staves)."""
	o = ring_mesh(c, [(r - 0.005, -w / 2), (r + t, -w / 2), (r + t, w / 2), (r - 0.005, w / 2)], m or IRON("dark"), seg)
	for k in range(rivets):
		a = 2 * math.pi * (k + 0.5) / rivets
		kit.rivet((c[0] + math.cos(a) * (r + t), c[1] + math.sin(a) * (r + t), c[2]), IRON("a"), r=0.008)
	return o


def rat(prof, z):
	"""Outer radius of a stave profile at height z."""
	for (r0, z0), (r1, z1) in zip(prof, prof[1:]):
		if z0 <= z <= z1:
			return r0 + (r1 - r0) * (z - z0) / (z1 - z0)
	return prof[0][0] if z < prof[0][1] else prof[-1][0]


def staves(prof, n, t, c=(0, 0, 0), gap=0.004, skip=(), mats=None):
	"""Wooden staves round the vertical axis following an outer profile [(r, z)...]. Each stave is its own part
	with a 4 mm gap to its neighbours; stave["ang"] = its middle angle."""
	cx, cy_, cz = c
	mats = mats or [W("a"), W("b"), W("c"), W("dark")]
	rmax = max(r for r, _ in prof)
	out = []
	for i in range(n):
		if i in skip:
			continue
		da = gap / rmax / 2
		a0, a1 = 2 * math.pi * i / n + da, 2 * math.pi * (i + 1) / n - da
		v = []
		for r, z in prof:
			for rr, a in ((r, a0), (r, a1), (r - t, a1), (r - t, a0)):
				v.append((cx + math.cos(a) * rr, cy_ + math.sin(a) * rr, cz + z))
		m_ = len(prof)
		f = [(k * 4 + j, k * 4 + (j + 1) % 4, (k + 1) * 4 + (j + 1) % 4, (k + 1) * 4 + j) for k in range(m_ - 1) for j in range(4)]
		f += [(3, 2, 1, 0), tuple(range((m_ - 1) * 4, m_ * 4))]
		o = mesh(v, f, mats[(i * 7) % len(mats)])
		o["ang"] = (a0 + a1) / 2
		out.append(o)
	return out


def head_boards(R, z0, z1, m=None, c=(0, 0, 0)):
	"""A round barrel head made of three boards (3 mm gaps), lying flat between z0 and z1."""
	out = []
	for i in range(3):
		x0, x1 = -R + 2 * R * i / 3 + 0.002, -R + 2 * R * (i + 1) / 3 - 0.002
		xs = [x0 + (x1 - x0) * k / 5 for k in range(6)]
		hy = lambda xx: math.sqrt(max(0.0, R * R - xx * xx))  # noqa: E731
		pts = [(c[0] + xx, c[1] - hy(xx)) for xx in xs] + [(c[0] + xx, c[1] + hy(xx)) for xx in reversed(xs)]
		out.append(prism(pts, c[2] + z0, c[2] + z1, m or W(("c", "dark", "b")[i]), axis="z"))
	return out


def cask(L=0.55, re=0.2, rm=0.235, n=16, hoops_at=(0.46, 0.27, -0.27, -0.46), skip=(), tap=False):
	"""A bellied cask standing upright round the origin (z = -L/2..L/2). The +Z head is the front one.
	Returns the front head boards (for brand marks)."""
	prof = [(re + (rm - re) * (1 - (2 * z / L) ** 2), z) for z in [-L / 2 + L * k / 8 for k in range(9)]]
	staves(prof, n, 0.028, skip=skip)
	R = re - 0.028 + 0.006
	front = head_boards(R, L / 2 - 0.05, L / 2 - 0.02)
	head_boards(R, -L / 2 + 0.02, -L / 2 + 0.05)
	for h in hoops_at:
		hoop((0, 0, h * L), rat(prof, h * L), w=0.03, t=0.01)
	if tap:  # copper tap low on the front head (low = -Y before the cask is laid down)
		kit.cylinder(0.022, 0.12, (0, -R * 0.55, L / 2 + 0.02), CU("b"), verts=10)
		kit.cylinder(0.016, 0.07, (0, -R * 0.55 - 0.03, L / 2 + 0.07), CU("b"), rot=(90, 0, 0), verts=8)
		kit.cylinder(0.008, 0.05, (0, -R * 0.55 + 0.02, L / 2 + 0.05), CU("dark"), rot=(90, 0, 0), verts=6)
		B((0.06, 0.012, 0.016), (0, -R * 0.55 + 0.045, L / 2 + 0.05), CU("dark"), bevel=0.003)
	return front


def tankard(x, y, z, s=1.0):
	"""A small staved tankard with two iron hoops and a handle on +X, standing at (x, y, z)."""
	prof = [(0.045 * s, 0), (0.041 * s, 0.13 * s)]
	staves(prof, 10, 0.009 * s, c=(x, y, z), gap=0.003)
	kit.cylinder(0.04 * s, 0.014, (x, y, z + 0.012), W("dark"), verts=12, bevel=0.002)
	for h in (0.025, 0.105):
		hoop((x, y, z + h * s), rat(prof, h * s), w=0.012 * s, t=0.004, m=IRON("dark"), seg=14)
	tube([(x + 0.04 * s, y, z + 0.11 * s), (x + 0.075 * s, y, z + 0.1 * s), (x + 0.08 * s, y, z + 0.055 * s), (x + 0.07 * s, y, z + 0.03 * s),
		(x + 0.041 * s, y, z + 0.028 * s)], 0.009 * s, 0.009 * s, W("dark"), seg=6)


def bucket(x, y, z=0.0, r=0.1, h=0.24):
	prof = [(r, 0), (r * 1.14, h)]
	staves(prof, 12, 0.014, c=(x, y, z))
	kit.cylinder(r - 0.008, 0.02, (x, y, z + 0.025), W("dark"), verts=14, bevel=0.002)
	for hh in (0.04, h - 0.04):
		hoop((x, y, z + hh), rat(prof, hh), w=0.022, t=0.006, seg=18)
	for s_ in (-1, 1):  # ears and a rope handle lying down to one side
		B((0.03, 0.03, 0.05), (x + s_ * (r * 1.14 + 0.008), y, z + h - 0.03), W("dark"), bevel=0.004)
	tube([(x - r * 1.14 - 0.02, y, z + h - 0.02), (x - r * 0.6, y - r * 0.9, z + h + 0.01), (x + r * 0.6, y - r * 0.9, z + h + 0.01),
		(x + r * 1.14 + 0.02, y, z + h - 0.02)], 0.009, 0.009, CORD(), seg=6)


def mallet(c, rz=0.0, s=1.0):
	"""A wooden mallet lying on a surface at c (x, y, z)."""
	def build():
		kit.cylinder(0.055 * s, 0.16 * s, (0, 0, 0.055 * s), W("dark"), rot=(0, 90, 0), verts=10)
		for k in (-1, 1):
			kit.ring(0.056 * s, 0.006, (k * 0.062 * s, 0, 0.055 * s), IRON("dark"), rot=(0, 90, 0), seg=14)
		rod((0, 0, 0.055 * s), (0, -0.3 * s, 0.03 * s), 0.016 * s, W("b"))
	return group(build, at=c, rot=(0, 0, rz))


def turned_hoop(c, r, rot, w=0.035, t=0.012):
	"""A loose hoop (lying or leaning): built flat at the origin, then turned and moved."""
	return group(lambda: hoop((0, 0, 0), r, w=w, t=t), at=c, rot=rot)


def lie_stave(L, w, t, c, rz, bend=0.02, m=None):
	"""A loose stave lying flat on the floor: a slightly bent board (thick in the middle) along X."""
	def build():
		pts = [(-L / 2, 0), (-L / 4, bend * 0.75), (0, bend), (L / 4, bend * 0.75), (L / 2, 0)]
		v = [(x, -w / 2, z) for x, z in pts] + [(x, w / 2, z) for x, z in pts] + [(x, w / 2, z + t) for x, z in pts] + [(x, -w / 2, z + t) for x, z in pts]
		n = len(pts)
		f = []
		for a, b_ in ((0, 1), (1, 2), (2, 3), (3, 0)):
			f += [(a * n + i, a * n + i + 1, b_ * n + i + 1, b_ * n + i) for i in range(n - 1)]
		f += [(0, n, 2 * n, 3 * n), (n - 1, 4 * n - 1, 3 * n - 1, 2 * n - 1)]
		mesh(v, f, m or W(rng.choice("abc")))
	g = group(build, at=c, rot=(0, 0, rz))
	drop(g, 0.0)
	return g


# ================= BREWHALL =================
def rb_mash_tun():
	B((1.24, 1.24, 0.3), (0, 0, 0.15), BRK(), bevel=0.02)
	B((1.32, 1.32, 0.07), (0, 0, 0.33), OCH(), bevel=0.015)
	B((0.34, 0.7, 0.2), (0.78, 0.05, 0.1), BRK("b"), bevel=0.02)  # step
	B((0.38, 0.74, 0.05), (0.79, 0.05, 0.215), OCH("b"), bevel=0.012)
	z0 = 0.36
	prof = [(0.5, z0), (0.515, z0 + 0.3), (0.53, z0 + 0.62)]
	staves(prof, 24, 0.045)
	kit.cylinder(0.47, 0.04, (0, 0, z0 + 0.02), W("dark"), verts=24)
	for i in range(7):  # slotted false bottom
		x = -0.36 + i * 0.12
		L = 2 * math.sqrt(0.462 ** 2 - x ** 2)
		B((0.1, L, 0.025), (x, 0, z0 + 0.054), W(("a", "c")[i % 2]), bevel=0.004)
	for h in (0.08, 0.32, 0.56):
		hoop((0, 0, z0 + h), rat(prof, z0 + h), w=0.045, t=0.014, rivets=10)
	# half lid of planks over the back half, two battens and an iron ring
	for k, yc in enumerate((0.09, 0.2, 0.31, 0.42)):
		L = 2 * math.sqrt(0.545 ** 2 - (yc + 0.05) ** 2)
		B((L, 0.105, 0.035), (0, yc, z0 + 0.633), W(("b", "c", "a", "dark")[k]), bevel=0.006)
	for x in (-0.2, 0.2):
		B((0.06, 0.44, 0.03), (x, 0.25, z0 + 0.662), W("dark"), bevel=0.006)
	kit.ring(0.035, 0.007, (0, 0.12, z0 + 0.654), IRON("dark"), seg=14)
	kit.rivet((0, 0.16, z0 + 0.656), IRON("a"), r=0.012)

	def rake(L):  # mash rake: long shaft, a slotted blade at the bottom, a cross grip at the top
		rod((0, 0, 0.2), (0, 0, L), 0.022, W("b"))
		blade = B((0.16, 0.03, 0.3), (0, 0, 0.15), W("c"), bevel=0.006)
		carve(blade, [B((0.025, 0.08, 0.2), (x, 0, 0.15), GROOVE(), bevel=0) for x in (-0.045, 0, 0.045)])
		B((0.16, 0.035, 0.035), (0, 0, L - 0.02), W("dark"), bevel=0.006)
	along(rake, (0.1, 0.05, z0 + 0.07), (0.646, -0.81, 1.585))
	# long copper tap over a bucket
	kit.cylinder(0.028, 0.3, (0, -0.6, z0 + 0.1), CU("b"), rot=(90, 0, 0), verts=12)
	kit.ring(0.032, 0.008, (0, -0.52, z0 + 0.1), CU("dark"), rot=(90, 0, 0), seg=14)
	kit.cylinder(0.02, 0.07, (0, -0.735, z0 + 0.07), CU("b"), verts=10)
	kit.cylinder(0.007, 0.07, (0, -0.68, z0 + 0.145), CU("dark"), verts=6)
	B((0.1, 0.016, 0.018), (0, -0.68, z0 + 0.18), CU("dark"), bevel=0.003)
	bucket(0, -0.82)
	floor_cut()


def rb_brew_kettle():
	W_, D_, H_ = 1.3, 1.0, 0.68
	body = B((W_, D_, H_), (0, 0, H_ / 2), BRK(), bevel=0.02)
	B((W_ + 0.06, D_ + 0.06, 0.08), (0, 0, 0.04), OCH("c"), bevel=0.015)
	B((W_ + 0.08, D_ + 0.08, 0.07), (0, 0, H_ + 0.025), OCH("b"), bevel=0.015)
	R, zs = 0.26, 0.3
	arch = [(-R, 0.11), (R, 0.11)] + [(math.cos(math.pi * k / 12) * R, zs + math.sin(math.pi * k / 12) * R) for k in range(13)]
	carve(body, [cy(arch, -D_ / 2, 0.6)])
	for k in range(9):  # ochre voussoirs round the firebox arch
		a = math.pi * k / 8
		ln = 0.16 if k == 4 else 0.13
		B((0.075, 0.06, ln), (math.cos(a) * (R + 0.005 + ln / 2), -D_ / 2 - 0.012, zs + math.sin(a) * (R + 0.005 + ln / 2)),
			OCH(("a", "b", "c")[k % 3]), bevel=0.008, rot=(0, 90 - math.degrees(a), 0))
	for s_ in (-1, 1):
		for z in (0.15, 0.25):
			B((0.11, 0.06, 0.09), (s_ * (R + 0.075), -D_ / 2 - 0.006, z), OCH(("b", "c")[z > 0.2]), bevel=0.008)
	# cold, empty firebox (owner round 2: no fire): soot-black floor and back, an empty iron fire grate
	B((0.5, 0.56, 0.012), (0, -0.21, 0.113), SOOT(), bevel=0.003)
	B((0.46, 0.012, 0.4), (0, 0.096, 0.315), SOOT(), bevel=0)
	for s_ in (-1, 1):  # grate side rails on four short legs
		rod((s_ * 0.17, -0.42, 0.16), (s_ * 0.17, -0.06, 0.16), 0.013, IRON("dark"))
		for y in (-0.38, -0.1):
			B((0.03, 0.03, 0.05), (s_ * 0.17, y, 0.137), IRON("dark"), bevel=0.004)
	for k in range(6):  # cross bars resting on the rails
		rod((-0.19, -0.39 + k * 0.055, 0.176), (0.19, -0.39 + k * 0.055, 0.176), 0.009, IRON("a" if k % 2 else "dark"))
	# riveted copper kettle sunk into the hearth top
	cx, cy_ = 0.0, 0.04
	cup([(0.3, 0.62), (0.4, 0.73), (0.46, 0.88), (0.46, 1.02), (0.41, 1.14), (0.43, 1.165), (0.43, 1.19), (0.38, 1.19),
		(0.37, 1.13), (0.4, 1.01), (0.39, 0.88), (0.3, 0.8), (0, 0.78)], (cx, cy_), CU("b"), seg=28)
	hoop((cx, cy_, 0.95), 0.46, w=0.045, t=0.01, m=CU("dark"), rivets=14)
	for k in range(8):  # vertical seam straps
		a = 2 * math.pi * k / 8 + 0.2
		B((0.035, 0.012, 0.16), (cx + math.cos(a) * 0.445, cy_ + math.sin(a) * 0.445, 0.83), CU("dark"), bevel=0.003, rot=(0, 0, math.degrees(a) + 90))
	for s_ in (-1, 1):
		kit.ring(0.055, 0.012, (cx + s_ * 0.47, cy_, 1.08), IRON("dark"), rot=(90, 0, 0), seg=14)
	lx = cx + 0.12  # lid set ajar on the rim
	cup([(0, 1.29), (0.15, 1.275), (0.3, 1.24), (0.42, 1.2), (0.44, 1.185), (0.44, 1.172), (0.41, 1.18), (0.3, 1.225),
		(0.15, 1.26), (0, 1.272)], (lx, cy_), CU("a"), seg=24)
	kit.cylinder(0.02, 0.05, (lx, cy_, 1.305), IRON("dark"), verts=8)
	sphere((lx, cy_, 1.335), 0.03, IRON("dark"), seg=10, rings=6)
	# iron swing crane with a chained copper ladle
	px, py = -0.56, 0.42
	B((0.16, 0.16, 0.03), (px, py, H_ + 0.07), IRON("a"), bevel=0.004)
	rod((px, py, H_ + 0.06), (px, py, 1.9), 0.028, IRON("dark"))
	for z in (0.95, 1.6):
		kit.ring(0.04, 0.01, (px, py, z), IRON("a"), seg=12)
	rod((px, py, 1.84), (cx + 0.02, cy_ + 0.02, 1.84), 0.022, IRON("dark"))
	rod((px, py, 1.45), (px + (cx + 0.02 - px) * 0.45, py + (cy_ + 0.02 - py) * 0.45, 1.84), 0.016, IRON("dark"))
	hx, hy = cx + 0.02, cy_ + 0.02
	chain((hx, hy, 1.82), (hx, hy, 1.56))
	tube([(hx, hy, 1.565), (hx, hy, 1.52), (hx + 0.03, hy, 1.5), (hx + 0.04, hy, 1.53)], 0.008, 0.008, IRON("dark"), seg=6)
	rod((hx + 0.035, hy, 1.52), (hx + 0.035, hy, 1.33), 0.012, CU("dark"))
	cup([(0, 1.24), (0.04, 1.245), (0.07, 1.27), (0.08, 1.33), (0.072, 1.33), (0.062, 1.275), (0.04, 1.255), (0, 1.25)], (hx + 0.035, hy), CU("b"), seg=14)
	for i, (x, z) in enumerate(((0.86, 0.075), (1.02, 0.075), (0.94, 0.2))):  # split firewood stacked beside
		log((x, -0.32, z), (x + J(0.02), 0.3, z), 0.075, W("dark") if i == 2 else None, seg=7, rings=2, bend=0.02)
	floor_cut()


def rb_fermenting_vats():
	for x in (-1.05, 0, 1.05):
		B((0.3, 0.7, 0.1), (x, 0, 0.05), BRK(), bevel=0.015)
	for y in (-0.2, 0.2):
		B((2.6, 0.14, 0.12), (0, y, 0.155), W("dark"), bevel=0.01)
	z0 = 0.21
	for i, x in enumerate((-0.85, 0, 0.85)):
		prof = [(0.36, z0), (0.345, z0 + 0.5), (0.33, z0 + 1.05)]
		staves(prof, 20, 0.04, c=(x, 0, 0))
		kit.cylinder(0.33, 0.04, (x, 0, z0 + 0.04), W("dark"), verts=20)
		for h in (0.09, 0.5, 0.95):
			hoop((x, 0, z0 + h), rat(prof, z0 + h), w=0.04, t=0.012, rivets=8)
		if i != 1:  # spigots (the middle vat's lid leans where its spigot would be)
			kit.cylinder(0.026, 0.12, (x, -0.38, z0 + 0.15), W("c"), rot=(90, 0, 0), verts=10)
			kit.cylinder(0.014, 0.06, (x, -0.43, z0 + 0.12), W("dark"), verts=8)
			B((0.05, 0.014, 0.014), (x, -0.42, z0 + 0.185), W("dark"), bevel=0.003)
		rf = rat(prof, 0.93)  # tally tag on a nail, notches cut in
		tag = B((0.13, 0.016, 0.085), (x, -rf - 0.004, 0.93), W("c"), bevel=0.004)
		yf = -rf - 0.012
		cuts = [cy(bar((x - 0.045 + k * 0.022, 0.9), (x - 0.045 + k * 0.022, 0.955), 0.007), yf, 0.005) for k in range(4 + i)]
		cuts.append(cy(bar((x - 0.055, 0.905), (x + 0.03, 0.95), 0.006), yf, 0.005))
		carve(tag, cuts)
		kit.rivet((x, yf, 0.965), IRON("a"), r=0.009)
		if i != 1:  # lids with a batten and a handle
			head_boards(0.345, z0 + 1.045, z0 + 1.08, c=(x, 0, 0))
			B((0.06, 0.6, 0.03), (x, 0, z0 + 1.09), W("dark"), bevel=0.005)
			B((0.14, 0.04, 0.05), (x, 0, z0 + 1.12), W("b"), bevel=0.006)

	def lid():
		head_boards(0.34, 0, 0.035)
		for xx in (-0.15, 0.15):
			B((0.05, 0.56, 0.03), (xx, 0, 0.047), W("dark"), bevel=0.005)
	group(lid, at=(0, -0.4, 0.345), rot=(80, 0, 0))
	floor_cut()


def rb_vat_burst():
	B((1.0, 1.0, 0.12), (0, 0, 0.06), BRK(), bevel=0.015)
	B((1.06, 1.06, 0.04), (0, 0, 0.13), OCH(), bevel=0.01)
	z0 = 0.15
	prof = [(0.4, z0), (0.385, z0 + 0.45), (0.37, z0 + 0.9)]
	kit.cylinder(0.37, 0.05, (0, 0, z0 + 0.025), W("dark"), verts=20)
	gone = (3, 4, 10, 14)
	sts = staves(prof, 18, 0.04, skip=gone)
	for o in sts:
		a = o["ang"]
		turn([o], Vector((-math.sin(a), math.cos(a), 0)), rng.uniform(8, 24), (math.cos(a) * 0.4, math.sin(a) * 0.4, z0))
	hoop((0, 0, z0 + 0.04), 0.405, w=0.04, t=0.012, rivets=8)
	hoop((0, 0, z0 + 0.25), 0.47, w=0.04, t=0.012)  # slipped down, jammed on the splayed staves
	for k, i in enumerate(gone):  # fallen staves lying out on the floor
		a = 2 * math.pi * (i + 0.5) / 18
		d = 0.95 + 0.1 * k
		lie_stave(0.9, 0.13, 0.035, (math.cos(a) * d, math.sin(a) * d, 0), math.degrees(a) + J(25))
	turned_hoop((-1.15, -0.05, 0.0165), 0.39, (0, 0, 0))
	turned_hoop((0.98, 0.55, 0.0165), 0.38, (0, 0, 20))

	def half_lid(k):
		def build():
			for i in range(2):
				R = 0.37
				x0, x1 = -R + 2 * R * i / 3 + 0.002, -R + 2 * R * (i + 1) / 3 - 0.002
				xs = [x0 + (x1 - x0) * j / 5 for j in range(6)]
				pts = [(xx, -math.sqrt(R * R - xx * xx)) for xx in xs] + [(xx, math.sqrt(R * R - xx * xx)) for xx in reversed(xs)]
				prism(pts, 0, 0.035, W(("c", "dark")[i]), axis="z")
			B((0.45, 0.06, 0.03), (-0.13, 0, 0.045), W("dark"), bevel=0.005, rot=(0, 0, 90))
		return build
	group(half_lid(0), at=(0.95, -0.35, 0.0), rot=(0, 0, 30))
	group(half_lid(1), at=(-0.6, 0.95, 0.0), rot=(0, 0, 200))
	kit.cylinder(0.026, 0.12, (-0.1, -0.75, 0.026), W("c"), rot=(90, 0, 40), verts=10)  # spigot knocked out
	mallet((-0.6, -0.95, 0.0), rz=-25)
	floor_cut()


def slat_tray(w, d, c, m_fr=None):
	"""A slatted drying tray lying flat: a frame of four rails and thin slats across with 1 cm gaps; top of slats at c[2] + 0.04."""
	x, y, z = c
	m_fr = m_fr or W("dark")
	for s_ in (-1, 1):
		B((w, 0.035, 0.035), (x, y + s_ * (d / 2 - 0.0175), z + 0.0175), m_fr, bevel=0.005)
		B((0.035, d - 0.07, 0.035), (x + s_ * (w / 2 - 0.0175), y, z + 0.0175), m_fr, bevel=0.005)
	n = int((w - 0.07) / 0.06)
	sw = (w - 0.07) / n
	for k in range(n):
		B((sw - 0.012, d - 0.06, 0.012), (x - w / 2 + 0.035 + sw * (k + 0.5), y, z + 0.034), W(("a", "c", "b")[k % 3]), bevel=0.002)
	return z + 0.04


def rb_drying_rack():
	"""(wall) A real wooden drying rack: two ladder-like side frames, five pairs of runners, four slatted trays
	(one pulled half out, one empty), mushroom slices and hop cones laid in rows, hop bundles hung from the top pole."""
	back = 0.08
	W_, D_, H_ = 1.5, 0.46, 1.62
	yf, yb = -D_ + 0.06, 0.02  # front and back posts
	for x in (-W_ / 2, W_ / 2):
		for y in (yf, yb):
			foot((0.13, 0.13, 0.06), (x, y, 0.03), tone=BRK("b"))
			B((0.08, 0.08, H_), (x, y, 0.06 + H_ / 2), W("dark"), bevel=0.01)
		B((0.06, yb - yf, 0.07), (x, (yf + yb) / 2, H_), W("b"), bevel=0.008)  # top tie
		B((0.05, yb - yf, 0.06), (x, (yf + yb) / 2, 0.2), W("b"), bevel=0.008)  # bottom tie
		for y in (yf, yb):  # peg heads where the ties meet the posts
			kit.cylinder(0.012, 0.012, (x + (0.044 if x > 0 else -0.044), y, H_), W("c"), rot=(0, 90, 0), verts=8, bevel=0.002)
	for y in (yf, yb):
		B((W_ + 0.04, 0.07, 0.07), (0, y, H_ + 0.09), W("c"), bevel=0.01)  # top rails front and back (5 mm into the posts)
	levels = (0.3, 0.62, 0.94, 1.26)
	tw, td = W_ - 0.1, yb - yf - 0.02
	for i, z in enumerate(levels):
		for s_ in (-1, 1):  # runners fixed to the inside of the side frames
			B((0.04, yb - yf + 0.06, 0.035), (s_ * (W_ / 2 - 0.058), (yf + yb) / 2, z - 0.0175), W("c"), bevel=0.004)
		pull = -0.16 if i == 1 else 0.0
		ty = (yf + yb) / 2 + pull
		top = slat_tray(tw - 0.04, td, (0, ty, z - 0.003), W(("dark", "b")[i % 2]))
		kit.cylinder(0.014, 0.05, (0, ty - td / 2 - 0.02, z + 0.02), W("c"), rot=(90, 0, 0), verts=8, bevel=0.003)
		if i == 0:
			continue  # the bottom tray is empty
		rows = 3
		for r_ in range(rows):
			yy = ty - td / 2 + 0.07 + r_ * (td - 0.14) / (rows - 1)
			for k in range(11):
				xx = -tw / 2 + 0.11 + k * (tw - 0.22) / 10 + J(0.008)
				if i == 2:  # hop cones laid on their side: three stacked six-sided tiers
					s = 1 + J(0.1)
					def hop(s=s):
						kit.cone(0.03 * s, 0.012, 0.03, (0, 0, 0.015), HOP(J(0.04)), verts=6, bevel=0.001)
						kit.cone(0.024 * s, 0.006, 0.026, (0, 0, 0.038), HOP(0.03), rot=(0, 0, 30), verts=6, bevel=0.001)
						kit.cone(0.013 * s, 0.002, 0.02, (0, 0, 0.058), HOP(0.01), verts=6, bevel=0.001)
						kit.cylinder(0.003, 0.02, (0, 0, -0.006), W("dark"), verts=5, bevel=0)
					group(hop, at=(xx, yy, top + 0.026 * s), rot=(90, 0, 25 + J(25)))
				else:  # dried mushroom slices, cap edge and gills showing
					m_ = DRIED(J(0.05) - (0.05 if i == 3 else 0))
					rz = J(40)
					kit.cylinder(0.042 - 0.004 * (k % 3), 0.01, (xx, yy, top + 0.004), m_, verts=10, bevel=0.002, rot=(0, 0, rz))
					kit.cylinder(0.026, 0.006, (xx, yy, top + 0.011), GILL(), verts=9, bevel=0, rot=(0, 0, rz))
					B((0.012, 0.03, 0.005), (xx, yy, top + 0.0145), DRIED(0.06), bevel=0, rot=(0, 0, rz))  # stem cut
	# hop bundles tied to the top pole, hanging straight down
	pz = H_ + 0.055
	for k in range(5):
		x = -0.56 + k * 0.28
		y = (yf + yb) / 2
		B((0.03, yb - yf + 0.04, 0.03), (x, y, pz - 0.012), W("b"), bevel=0.004)  # cross pole between the rails
		rod((x, y, pz - 0.03), (x, y, pz - 0.12), 0.004, CORD(), seg=5)
		kit.ring(0.02, 0.005, (x, y, pz - 0.13), CORD(), seg=10)
		for j in range(6):
			a = 2 * math.pi * j / 6 + k
			ex, ey = x + math.cos(a) * 0.035, y + math.sin(a) * 0.035
			rod((x + math.cos(a) * 0.008, y + math.sin(a) * 0.008, pz - 0.12), (ex, ey, pz - 0.25), 0.004, HOP(-0.12), seg=5)
			kit.cone(0.022, 0.004, 0.04, (ex, ey, pz - 0.268), HOP(J(0.04)), verts=6, rot=(180, 0, 0), bevel=0.001)
	slim(small=0.07, fine=0.005)  # under 2 MB
	floor_cut()
	flat_back(back)


def rb_grain_quern():
	B((0.8, 0.8, 0.5), (0, 0, 0.25), BRK(), bevel=0.02)
	B((0.86, 0.86, 0.06), (0, 0, 0.52), OCH(), bevel=0.015)
	for s_ in (-1, 1):
		B((0.06, 0.82, 0.47), (s_ * 0.385, 0, 0.245), OCH("c"), bevel=0.01)  # ochre corner courses
	kit.cylinder(0.32, 0.1, (0, 0, 0.595), QS("b"), verts=22, bevel=0.01)
	top = kit.cylinder(0.31, 0.11, (0, 0, 0.696), QS("a"), verts=22, bevel=0.012)
	cuts = [kit.cylinder(0.06, 0.2, (0, 0, 0.72), GROOVE(), verts=12, bevel=0)]
	for k in range(10):  # dressing grooves cut into the top
		a = 2 * math.pi * k / 10
		cuts.append(B((0.17, 0.014, 0.04), (math.cos(a) * 0.19, math.sin(a) * 0.19, 0.755), GROOVE(), bevel=0, rot=(0, 0, math.degrees(a) + 12)))
	carve(top, cuts)
	B((0.15, 0.028, 0.02), (0, 0, 0.735), IRON("dark"), bevel=0.003)  # rynd across the eye
	hx, hy = math.cos(0.5) * 0.24, math.sin(0.5) * 0.24
	kit.cylinder(0.025, 0.28, (hx, hy, 0.86), W("b"), verts=8)
	kit.ring(0.028, 0.007, (hx, hy, 0.755), IRON("dark"), seg=10)
	sphere((hx, hy, 1.0), 0.03, W("dark"), seg=8, rings=5)

	def chute():
		B((0.12, 0.44, 0.015), (0, 0, 0), W("c"), bevel=0.003)
		for s_ in (-1, 1):
			B((0.015, 0.44, 0.05), (s_ * 0.065, 0, 0.02), W("dark"), bevel=0.003)
	group(chute, at=(0, -0.5, 0.52), rot=(30, 0, 0))
	bx, by = 0, -0.74  # flour bin: an open box with corner posts
	B((0.44, 0.34, 0.025), (bx, by, 0.0125), W("dark"), bevel=0.004)
	for s_ in (-1, 1):
		B((0.44, 0.025, 0.3), (bx, by + s_ * 0.16, 0.16), W(("a", "c")[s_ > 0]), bevel=0.004)
		B((0.025, 0.3, 0.3), (bx + s_ * 0.21, by, 0.16), W("b"), bevel=0.004)
		for t in (-1, 1):
			B((0.04, 0.04, 0.33), (bx + s_ * 0.215, by + t * 0.165, 0.165), W("dark"), bevel=0.004)
	cup([(0, 0.022), (0.045, 0.026), (0.06, 0.06), (0.06, 0.09), (0.052, 0.09), (0.052, 0.065), (0.04, 0.04), (0, 0.04)], (bx + 0.06, by), W("b"), seg=12)
	rod((bx + 0.06, by - 0.06, 0.08), (bx + 0.06, by - 0.18, 0.13), 0.012, W("b"))
	# brush and a copper scoop on the stand top
	B((0.2, 0.05, 0.035), (-0.27, -0.3, 0.565), W("dark"), bevel=0.005, rot=(0, 0, 25))
	for k in range(6):
		B((0.026, 0.05, 0.03), (-0.34 + k * 0.026, -0.32 + k * 0.012, 0.545), T("straw", "a"), bevel=0.002, rot=(0, 0, 25))
	cup([(0, 0.552), (0.05, 0.555), (0.065, 0.59), (0.065, 0.62), (0.057, 0.62), (0.057, 0.595), (0.045, 0.563), (0, 0.56)], (0.3, -0.28), CU("b"), seg=14)
	rod((0.36, -0.28, 0.6), (0.42, -0.3, 0.6), 0.008, CU("dark"))
	floor_cut()


def rb_cask_bay():
	back = 0.35
	B((2.0, 0.6, 0.08), (0, 0.05, 0.04), OCH("c"), bevel=0.012)
	panel = B((1.94, 0.2, 1.94), (0, 0.25, 0.07 + 0.97), BRK(), bevel=0.02)
	B((2.02, 0.3, 0.08), (0, 0.23, 2.05), OCH("b"), bevel=0.015)
	R, zc, yf = 0.86, 1.0, 0.15
	for k in range(17):  # ochre voussoirs and pilasters framing the bay
		a = math.pi * k / 16
		ln = 0.2 if k == 8 else 0.15
		B((0.15, 0.05, ln), (math.cos(a) * (R + ln / 2), yf - 0.015, zc + math.sin(a) * (R + ln / 2)), OCH(("a", "b", "c")[k % 3]),
			bevel=0.008, rot=(0, 90 - math.degrees(a), 0))
	for s_ in (-1, 1):
		for j in range(5):
			B((0.15 if j % 2 else 0.2, 0.05, 0.17), (s_ * (R + 0.075 + (0 if j % 2 else 0.02)), yf - 0.01, 0.16 + j * 0.178), OCH(("b", "c", "a")[j % 3]), bevel=0.008)
	carve(panel, runes(-0.3, 0.3, 1.78, yf, h=0.07, gap=0.06))
	L, yc = 0.55, -0.155
	for y in (yc - 0.17, yc + 0.17):  # cradle beams with chocks
		B((1.86, 0.1, 0.08), (0, y, 0.06), W("dark"), bevel=0.01)
		for x in (-0.78, -0.26, 0.26, 0.78):
			prism([(x - 0.06, 0.098), (x + 0.06, 0.098), (x, 0.16)], y - 0.045, y + 0.045, W("c"), axis="y")
	zb = 0.1 + 0.2 + 0.035 * (1 - (0.34 / L) ** 2) - 0.005
	heads = []
	for x in (-0.52, 0.0, 0.52):
		heads.append(group(lambda: cask(L, tap=True), at=(x, yc, zb), rot=(90, 0, 0)))
	zt = zb + math.sqrt(0.47 ** 2 - 0.26 ** 2) - 0.008
	heads.append(group(lambda: cask(L), at=(-0.26, yc + 0.025, zt), rot=(90, 0, 0)))  # 2.5 cm back: hoops never share a plane
	prism([(0.12, zb + 0.19), (0.40, zb + 0.19), (0.26, zb + 0.27)], yc - 0.2, yc - 0.1, W("dark"), axis="y")  # the empty place's chock
	for g, (x, z, yh) in zip(heads, ((-0.52, zb, yc), (0.0, zb, yc), (0.52, zb, yc), (-0.26, zt, yc + 0.025))):  # brand marks cut in
		yh -= L / 2 - 0.02
		boards = [o for o in g if o.type == "MESH" and o.data.materials and o.data.materials[0].name.startswith("wood") and
			abs(min((o.matrix_world @ v.co).y for v in o.data.vertices) - yh) < 0.004]
		zz = z + 0.06
		cuts = gline([(x + math.cos(2 * math.pi * k / 10) * 0.06, zz + math.sin(2 * math.pi * k / 10) * 0.06) for k in range(11)], 0.01, yh, 0.006)
		cuts += gline([(x - 0.03, zz - 0.03), (x, zz + 0.035), (x + 0.03, zz - 0.03)], 0.01, yh, 0.006)
		if boards:
			carve_all(boards, cuts)
		else:
			for c_ in cuts:
				bpy.data.objects.remove(c_, do_unlink=True)
	floor_cut()
	flat_back(back)


def rb_cooper_bench():
	B((1.3, 0.3, 0.07), (0, 0, 0.5), W("b"), bevel=0.01)
	for x in (-0.55, 0.55):
		for y in (-0.1, 0.1):
			rod((x, y, 0.5), (x * 1.12, y * 2.2, 0.0), 0.032, W("dark"), seg=7)
	B((0.42, 0.24, 0.04), (0.28, 0, 0.6), W("c"), bevel=0.006, rot=(0, -18, 0))  # sloped work rest
	B((0.12, 0.2, 0.08), (0.12, 0, 0.56), W("dark"), bevel=0.006)
	for y in (-0.11, 0.11):  # clamp frame through the seat
		B((0.04, 0.04, 0.62), (0.5, y, 0.52), W("dark"), bevel=0.005)
	B((0.11, 0.3, 0.1), (0.5, 0, 0.82), W("a"), bevel=0.01)
	B((0.06, 0.42, 0.05), (0.5, 0, 0.24), W("b"), bevel=0.006)
	kit.cylinder(0.012, 0.3, (0.5, 0, 0.66), IRON("dark"), rot=(90, 0, 0), verts=8)  # pivot pin
	B((0.6, 0.1, 0.022), (0.33, 0, 0.645), W("c"), bevel=0.004, rot=(0, -18, 0))  # stave clamped on the rest
	# drawknife on the seat
	B((0.28, 0.045, 0.012), (-0.25, -0.03, 0.535), IRON("a"), bevel=0.002)
	for s_ in (-1, 1):
		rod((-0.25 + s_ * 0.14, -0.03, 0.54), (-0.25 + s_ * 0.2, -0.09, 0.545), 0.006, IRON("dark"))
		kit.cylinder(0.016, 0.1, (-0.25 + s_ * 0.2, -0.13, 0.55), W("dark"), rot=(90, 0, 0), verts=8)
	mallet((-0.48, 0.06, 0.533), rz=70, s=0.8)
	# a barrel being raised: staves splayed at the foot, gathered in two raising hoops at the top
	bx, by = -1.05, 0.15
	prof = [(0.23, 0.0), (0.26, 0.35), (0.235, 0.7)]
	sts = staves(prof, 16, 0.026, c=(bx, by, 0), skip=(5,))
	for o in sts:
		a = o["ang"]
		turn([o], Vector((-math.sin(a), math.cos(a), 0)), -rng.uniform(8, 12), (bx + math.cos(a) * 0.235, by + math.sin(a) * 0.235, 0.7))
	drop(sts, 0.0)
	bpy.context.view_layer.update()
	ztop = max((o.matrix_world @ v.co).z for o in sts for v in o.data.vertices)
	hoop((bx, by, ztop - 0.04), 0.237, w=0.04, t=0.012, rivets=6)
	hoop((bx, by, ztop - 0.2), 0.262, w=0.04, t=0.012)
	lie_stave(0.7, 0.1, 0.026, (bx + 0.1, by - 0.5, 0), 70)
	lie_stave(0.7, 0.1, 0.026, (0.25, -0.45, 0), 5)
	lie_stave(0.68, 0.11, 0.026, (0.0, -0.64, 0.0), -10)
	# spare hoops leaning on the bench end
	turned_hoop((0.722, -0.06, 0.28), 0.29, (0, 72, 0), w=0.035, t=0.012)
	turned_hoop((1.0, 0.35, 0.0165), 0.26, (0, 0, 0), w=0.035, t=0.012)
	# adze leaning on the far leg
	along(lambda L: (rod((0, 0, 0), (0, 0, L), 0.017, W("b")), B((0.044, 0.14, 0.05), (0, -0.05, L - 0.02), IRON("dark"), bevel=0.004)),
		(-0.4, -0.55, 0.0), (-0.4, -0.1, 0.6))
	floor_cut()


def hollow_tube(pts, rs, m, inner_m=None, wall=0.007, depth=4, seg=12):
	"""A bendy tube with a really hollow mouth at pts[0]: outer skin, a lip, and an inner skin (dark) running
	`depth` points in to a dark floor. The far end (pts[-1]) is closed."""
	pts = [Vector(p) for p in pts]
	n = len(pts)
	frames = []
	for i, p in enumerate(pts):
		d = (pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]).normalized()
		up = Vector((0, 0, 1)) if abs(d.z) < 0.9 else Vector((1, 0, 0))
		u = d.cross(up).normalized()
		frames.append((u, d.cross(u)))
	v = []
	for i, p in enumerate(pts):
		u, w = frames[i]
		v += [tuple(p + (u * math.cos(2 * math.pi * k / seg) + w * math.sin(2 * math.pi * k / seg)) * rs[i]) for k in range(seg)]
	base = len(v)
	for j in range(depth):
		u, w = frames[j]
		ri = rs[j] - wall
		v += [tuple(pts[j] + (u * math.cos(2 * math.pi * k / seg) + w * math.sin(2 * math.pi * k / seg)) * ri) for k in range(seg)]
	q = lambda a, b, k: (a + k, a + (k + 1) % seg, b + (k + 1) % seg, b + k)  # noqa: E731
	f = [q(i * seg, (i + 1) * seg, k) for i in range(n - 1) for k in range(seg)]
	f.append(tuple(range((n - 1) * seg, n * seg)))  # closed tip
	f += [tuple(reversed(q(0, base, k))) for k in range(seg)]  # lip
	nin = len(f)
	f += [tuple(reversed(q(base + j * seg, base + (j + 1) * seg, k))) for j in range(depth - 1) for k in range(seg)]
	f.append(tuple(reversed(range(base + (depth - 1) * seg, base + depth * seg))))  # dark floor inside
	o = mesh(v, f, m, smooth=True)
	o.data.materials.append(inner_m or DARK())
	for poly in o.data.polygons[nin:]:
		poly.material_index = 1
	return o


def horn(c, L=0.34, r0=0.046, curl=0.1, flip=1):
	"""A drinking horn lying along X (mouth at -X when flip=1), curving up: really hollow mouth (dark inside),
	copper mouth rim, band and a tip cap that stays inside the horn's length."""
	x0, y0, z0 = c
	n = 9
	pts, rs = [], []
	for i in range(n):
		t = i / (n - 1)
		x = (-L / 2 + L * t * 0.9) * flip  # the tip cap fills the last 10 %
		z = curl * (2 * t - 1) ** 2 + 0.05 * t ** 3
		pts.append((x0 + x, y0, z0 + z))
		rs.append(r0 * (1 - t) + 0.009 * t)
	hollow_tube(pts, rs, BONE_HORN(), wall=0.006, depth=4, seg=14)
	d = Vector(pts[1]) - Vector(pts[0])
	ang = math.degrees(math.atan2(d.x, d.z))
	kit.ring(r0 - 0.001, 0.007, pts[0], CU("b"), rot=(0, ang, 0), seg=18)
	d2 = Vector(pts[4]) - Vector(pts[3])
	kit.ring(rs[4] + 0.001, 0.006, pts[4], CU("dark"), rot=(0, math.degrees(math.atan2(d2.x, d2.z)), 0), seg=14)
	d3 = (Vector(pts[-1]) - Vector(pts[-2])).normalized()
	kit.cone(0.011, 0.003, 0.034, tuple(Vector(pts[-1]) + d3 * 0.012), CU("b"), rot=(0, math.degrees(math.atan2(d3.x, d3.z)), 0), verts=8)
	return pts, rs


BONE_HORN = lambda: C((0.48, 0.38, 0.24), 0.55)  # noqa: E731  (polished horn)


def horn_bottom(x, c, L, r0, curl, flip=1):
	"""Lowest point of the horn tube at board x (for resting it on pegs)."""
	t = ((x - c[0]) / flip + L / 2) / (L * 0.9)
	z = curl * (2 * t - 1) ** 2 + 0.05 * t ** 3
	return c[2] + z - (r0 * (1 - t) + 0.009 * t)


def rb_horn_wall():
	back = 0.06
	B((1.46, 0.28, 0.12), (0, -0.05, 0.06), BRK(), bevel=0.015)
	B((1.5, 0.3, 0.035), (0, -0.05, 0.13), OCH(), bevel=0.008)
	for k in range(6):
		B((0.222, 0.05, 1.5), (-0.555 + k * 0.222, 0.03, 0.87), W(("a", "c", "b", "dark", "c", "a")[k]), bevel=0.006)
	B((1.38, 0.04, 0.08), (0, -0.012, 0.3), W("dark"), bevel=0.008)
	rail = B((1.38, 0.04, 0.11), (0, -0.012, 1.5), W("dark"), bevel=0.008)
	carve(rail, runes(-0.5, 0.5, 1.5, -0.032, h=0.06, gap=0.055, under=False))
	B((1.48, 0.12, 0.07), (0, 0.0, 1.645), W("b"), bevel=0.01)
	for x in (-0.66, 0.66):
		for z in (0.3, 1.5):
			kit.rivet((x, -0.033, z), IRON("a"), r=0.014)
	L, r0, curl = 0.34, 0.046, 0.1  # 0.43 apart: 9 cm clear between neighbouring horns
	for zr, row in ((1.12, 0), (0.7, 1)):
		for j, x in enumerate((-0.43, 0.0, 0.43)):
			pz = zr
			empty = row == 1 and j == 2
			c = (x, -0.065, 0)
			hz = pz + 0.015 - 0.004 - horn_bottom(x - 0.1, c, L, r0, curl)  # horn rests on the mouth-side peg
			for px in (x - 0.1, x + 0.1):  # the tip-side peg sits higher, right under the horn (pegs fitted to each horn)
				z = pz if empty or px < x else horn_bottom(px, (x, -0.065, hz), L, r0, curl) - 0.015 + 0.004
				kit.cylinder(0.015, 0.11, (px, -0.045, z), W("c"), rot=(90, 0, 0), verts=8)
				sphere((px, -0.1, z + 0.004), 0.019, W("c"), seg=8, rings=5)
			if empty:
				continue
			horn((x, -0.065, hz), L, r0, curl)
	# the fallen horn on the foot below the empty pegs
	drop(group(lambda: horn((0, 0, 0), L, r0, curl, -1), at=(0.4, -0.1, 0.0), rot=(0, 0, 10)), 0.1475 - 0.004)
	floor_cut()
	flat_back(back)


def rb_feast_table_broken():
	zt = 0.655
	for k, y in enumerate((-0.25, 0.0, 0.25)):  # standing half
		B((1.16, 0.24, 0.07), (-0.62, y, zt), W(("b", "c", "a")[k]), bevel=0.008)
		for j, (ya, yb, dz) in enumerate(((-0.09, -0.05, -0.012), (0.03, 0.08, 0.008))):  # splinters at the break
			prism([(-0.05, zt - 0.02 + dz), (0.03 + 0.03 * ((k + j) % 2), zt + dz), (-0.05, zt + 0.02 + dz)], y + ya, y + yb, W("c"), axis="y")
	for x in (-0.95, -0.2):  # trestles under the standing half
		B((0.1, 0.72, 0.07), (x, 0, zt - 0.07), W("dark"), bevel=0.008)
		for s_ in (-1, 1):
			B((0.08, 0.08, 0.6), (x, s_ * 0.24, 0.3), W("dark"), bevel=0.008, rot=(s_ * 8, 0, 0))
		B((0.1, 0.64, 0.07), (x, 0, 0.035), W("b"), bevel=0.008)
	before = set(bpy.data.objects[:])
	for k, y in enumerate((-0.25, 0.0, 0.25)):  # the snapped half, sloping to the floor
		B((1.2, 0.24, 0.07), (0.62, y, zt), W(("a", "b", "c")[k]), bevel=0.008)
		prism([(0.03, zt - 0.03), (-0.05 + 0.02 * k, zt), (0.03, zt + 0.03)], y - 0.03, y + 0.015, W("c"), axis="y")
	B((0.1, 0.72, 0.07), (0.95, 0, zt - 0.07), W("dark"), bevel=0.008)
	turn(new_since(before), "Y", 31, (0.0, 0, zt + 0.03))
	for s_, (x, y, rz) in ((-1, (0.6, -0.55, 75)), (1, (0.75, 0.55, 105))):  # its trestle legs lying on the floor
		group(lambda: B((0.6, 0.08, 0.08), (0, 0, 0.04), W("dark"), bevel=0.008), at=(x, y, 0), rot=(0, 0, rz))
	group(lambda: B((0.64, 0.1, 0.07), (0, 0, 0.035), W("b"), bevel=0.008), at=(1.45, 0.1, 0), rot=(0, 0, 80))
	# back bench intact, front bench tipped on its side
	B((2.3, 0.28, 0.06), (0, 0.62, 0.38), W("b"), bevel=0.008)
	for x in (-1.0, 0.0, 1.0):
		for s_ in (-1, 1):
			B((0.06, 0.06, 0.37), (x, 0.62 + s_ * 0.09, 0.18), W("dark"), bevel=0.006, rot=(s_ * 10, 0, 0))
	B((1.5, 0.06, 0.28), (-0.45, -0.78, 0.14), W("c"), bevel=0.008)
	for x in (-1.05, 0.15):
		for z in (0.05, 0.23):
			B((0.06, 0.34, 0.06), (x, -0.59, z), W("dark"), bevel=0.006)
	# on the standing half: tankards, trenchers, a knife, an iron candlestick
	top = zt + 0.035 - 0.003
	tankard(-0.95, -0.15, top)
	tankard(-0.55, 0.2, top, 0.95)
	group(lambda: tankard(0, 0, 0), at=(-0.33, -0.17, top + 0.044), rot=(0, -90, 35))
	for x, y in ((-1.0, 0.16), (-0.7, -0.12), (-0.4, 0.12)):
		cup([(0, top), (0.09, top + 0.002), (0.105, top + 0.018), (0.095, top + 0.02), (0.08, top + 0.008), (0, top + 0.008)], (x, y), W("c"), seg=16)
	B((0.16, 0.022, 0.006), (-0.66, -0.2, top + 0.004), IRON("a"), bevel=0.001, rot=(0, 0, 20))
	B((0.08, 0.026, 0.02), (-0.77, -0.24, top + 0.01), W("dark"), bevel=0.003, rot=(0, 0, 20))
	kit.cylinder(0.045, 0.015, (-0.78, 0.0, top + 0.007), IRON("dark"), verts=10)
	kit.cylinder(0.012, 0.12, (-0.78, 0.0, top + 0.07), IRON("dark"), verts=8)
	kit.cylinder(0.03, 0.012, (-0.78, 0.0, top + 0.13), IRON("dark"), verts=10)
	kit.cylinder(0.018, 0.05, (-0.78, 0.0, top + 0.16), WAX(), verts=10)
	# a tankard and a copper jug rolled away on the floor
	group(lambda: tankard(0, 0, 0), at=(0.35, -0.5, 0.044), rot=(0, -90, -60))
	group(lambda: cup([(0, 0), (0.06, 0.005), (0.08, 0.06), (0.07, 0.15), (0.045, 0.19), (0.05, 0.22), (0.042, 0.22), (0.038, 0.19),
		(0.062, 0.15), (0.072, 0.06), (0.054, 0.012), (0, 0.01)], (0, 0), CU("b"), seg=16), at=(0.95, -0.55, 0.079), rot=(0, 90, 20))
	floor_cut()


def rb_recipe_board():
	back = 0.1
	B((1.4, 0.32, 0.1), (0, -0.03, 0.05), OCH("c"), bevel=0.015)
	B((1.3, 0.2, 1.55), (0, 0.0, 0.085 + 0.775), BRK(), bevel=0.02)
	B((1.4, 0.26, 0.08), (0, -0.01, 1.67), OCH("b"), bevel=0.015)
	yf = -0.14
	tab = B((0.95, 0.05, 0.85), (0, -0.115, 1.05), CLAYT("b"), bevel=0.008)
	for zz in (0.6, 1.5):  # wooden frame
		B((1.05, 0.05, 0.06), (0, -0.13, zz), W("dark"), bevel=0.008)
	for s_ in (-1, 1):
		B((0.06, 0.05, 0.84), (s_ * 0.495, -0.13, 1.05), W("dark"), bevel=0.008)
		for zz in (0.6, 1.5):
			B((0.09, 0.012, 0.09), (s_ * 0.49, -0.158, zz), CU("b"), bevel=0.003)
			kit.rivet((s_ * 0.49, -0.165, zz), CU("dark"), r=0.01)
	cuts = []
	kx, kz = -0.3, 1.32  # kettle picture: pot, rim, handle, three flames under it
	cuts += gline([(kx - 0.08 + 0.16 * k / 8, kz - 0.06 * math.sin(math.pi * k / 8)) for k in range(9)], 0.012, yf)
	cuts += gline([(kx - 0.1, kz + 0.005), (kx + 0.1, kz + 0.005)], 0.012, yf)
	cuts += gline([(kx - 0.06, kz + 0.01), (kx - 0.04, kz + 0.07), (kx + 0.04, kz + 0.07), (kx + 0.06, kz + 0.01)], 0.009, yf)
	for f_ in (-0.05, 0, 0.05):
		cuts += gline([(kx + f_ - 0.012, kz - 0.14), (kx + f_ + 0.01, kz - 0.11), (kx + f_ - 0.005, kz - 0.08)], 0.009, yf)
	mx, mz = 0.0, 1.3  # mushroom picture: cap, gills, stem
	cuts += gline([(mx - 0.09 + 0.18 * k / 8, mz + 0.07 * math.sin(math.pi * k / 8)) for k in range(9)], 0.012, yf)
	cuts += gline([(mx - 0.09, mz), (mx + 0.09, mz)], 0.01, yf)
	for g_ in (-0.05, 0, 0.05):
		cuts += gline([(mx + g_, mz + 0.01), (mx + g_ * 0.6, mz + 0.045)], 0.006, yf)
	cuts += gline([(mx - 0.02, mz - 0.005), (mx - 0.025, mz - 0.12), (mx + 0.025, mz - 0.12), (mx + 0.02, mz - 0.005)], 0.01, yf)
	gx, gz = 0.3, 1.24  # grain ear: stalk and chevrons
	cuts += gline([(gx, gz - 0.06), (gx, gz + 0.16)], 0.01, yf)
	for j in range(4):
		zz = gz + j * 0.04
		cuts += gline([(gx - 0.04, zz - 0.005), (gx, zz + 0.025), (gx + 0.04, zz - 0.005)], 0.009, yf)
	cuts.append(cy(bar((-0.42, 1.19), (0.42, 1.19), 0.01), yf, 0.008))
	for i, z in enumerate((1.1, 0.98, 0.86, 0.74)):  # recipe rows: runes then a tally of measures
		cuts += runes(-0.42, 0.18, z, yf, h=0.06, gap=0.05, under=False)
		for k in range(2 + (i * 3) % 5):
			cuts.append(cy(bar((0.26 + k * 0.025, z - 0.03), (0.26 + k * 0.025, z + 0.03), 0.008), yf, 0.008))
	carve(tab, cuts)
	B((1.0, 0.16, 0.04), (0, -0.17, 0.5), W("b"), bevel=0.006)  # shelf with corbels
	for s_ in (-1, 1):
		prism([(-0.24, 0.485), (-0.09, 0.485), (-0.09, 0.34)], s_ * 0.38 - 0.025, s_ * 0.38 + 0.025, W("dark"), axis="x")
	for k, (x, r, h) in enumerate(((-0.35, 0.07, 0.1), (-0.15, 0.055, 0.08), (0.02, 0.04, 0.06), (0.15, 0.03, 0.045))):
		cup([(0, 0.517), (r, 0.519), (r, 0.52 + h), (r - 0.007, 0.52 + h), (r - 0.007, 0.53), (0, 0.53)], (x, -0.18), CU("b"), seg=16)
		kit.ring(r + 0.001, 0.005, (x, -0.18, 0.52 + h - 0.01), CU("dark"), seg=16)
	B((0.2, 0.025, 0.025), (0.34, -0.18, 0.532), W("c"), bevel=0.004, rot=(0, 0, 8))  # tally stick
	floor_cut()
	flat_back(back)


def rb_cask_rolled():
	cx = -0.75  # the empty cradle
	for x in (cx - 0.17, cx + 0.17):
		B((0.1, 0.7, 0.08), (x, 0, 0.04), W("dark"), bevel=0.01)
	for y in (-0.24, 0.24):
		B((0.44, 0.1, 0.05), (cx, y, 0.1), W("b"), bevel=0.008)
		prism([(cx - 0.21, 0.124), (cx - 0.1, 0.124), (cx - 0.21, 0.2)], y - 0.045, y + 0.045, W("c"), axis="y")
		if y < 0:
			prism([(cx + 0.21, 0.124), (cx + 0.1, 0.124), (cx + 0.21, 0.2)], y - 0.045, y + 0.045, W("c"), axis="y")
	group(lambda: prism([(-0.055, 0), (0.055, 0), (-0.055, 0.076)], -0.045, 0.045, W("c"), axis="y"), at=(cx + 0.5, -0.6, 0.0), rot=(0, 0, 40))
	L, rm = 0.6, 0.255
	group(lambda: cask(L, re=0.215, rm=rm, hoops_at=(0.46, 0.27, -0.27), skip=(4,)), at=(0.35, -0.05, rm - 0.004), rot=(90, 0, 25))
	turned_hoop((0.95, 0.45, 0.014), 0.22, (0, 0, 0), w=0.03, t=0.01)
	lie_stave(0.36, 0.09, 0.028, (0.55, -0.62, 0), 20)  # the burst stave in two pieces
	lie_stave(0.26, 0.09, 0.028, (0.88, -0.45, 0), -35)
	kit.cylinder(0.022, 0.12, (-0.15, -0.55, 0.022), CU("b"), rot=(90, 0, 70), verts=10)  # tap snapped off
	kit.cylinder(0.016, 0.06, (-0.2, -0.53, 0.016), CU("dark"), rot=(0, 90, 0), verts=8)
	kit.cylinder(0.03, 0.05, (0.1, 0.45, 0.03), W("c"), rot=(90, 0, 15), verts=10)  # bung
	mallet((-0.3, 0.5, 0.0), rz=110)
	floor_cut()


# ================= LANTERN SPIRE =================
from decor_nov21_th import lathe as solid_lathe, panel_wall  # noqa: E402

GLASS = lambda: glass((0.72, 0.86, 0.88), 0.32)  # noqa: E731
SOOTGLASS = lambda: glass((0.12, 0.1, 0.08), 0.75)  # noqa: E731
LINEN = lambda s=0.0: C((0.55 + s, 0.5 + s, 0.38 + s), 0.95)  # noqa: E731
SAND = lambda: C((0.62, 0.5, 0.3), 0.95)  # noqa: E731
WD = lambda: T("wood", "dark")  # noqa: E731


def lens_disc(R, th, m=None):
	"""A thick biconvex lens lying flat round the origin."""
	return solid_lathe([(0.002, -th), (R * 0.5, -th * 0.75), (R * 0.85, -th * 0.35), (R, -0.006), (R, 0.006), (R * 0.85, th * 0.35),
		(R * 0.5, th * 0.75), (0.002, th)], (0, 0, 0), m or GLASS(), seg=28)


def oil_jar(x, y, z, s=1.0, open_=False, m=None):
	"""A clay lamp-oil jar: round belly, neck, two lug handles; sealed with a wooden stopper, wax and cord."""
	m = m or CLAYT("c")
	inner = [(0, z + 0.33 * s)] if not open_ else [(0.05 * s, z + 0.3 * s), (0.1 * s, z + 0.24 * s), (0.11 * s, z + 0.16 * s),
		(0.09 * s, z + 0.06 * s), (0, z + 0.045 * s)]  # open jar: hollowed all the way down
	nk = 0.044 if not open_ else 0.056
	cup([(0, z), (0.09 * s, z + 0.004), (0.13 * s, z + 0.08 * s), (0.14 * s, z + 0.18 * s), (0.12 * s, z + 0.27 * s), (0.066 * s, z + 0.32 * s),
		(0.064 * s, z + 0.36 * s), (0.074 * s, z + 0.372 * s), (0.074 * s, z + 0.385 * s), (nk * s, z + 0.385 * s), (nk * s, z + 0.34 * s)] + inner,
		(x, y), m, seg=16 if not open_ else 20)
	if open_:  # dark dregs ring low inside, so the hollow reads
		kit.cylinder(0.097 * s, 0.012, (x, y, z + 0.075 * s), DARK(), verts=16, bevel=0)
	for k in (-1, 1):
		tube([(x + k * 0.055 * s, y, z + 0.345 * s), (x + k * 0.1 * s, y, z + 0.34 * s), (x + k * 0.11 * s, y, z + 0.29 * s), (x + k * 0.1 * s, y, z + 0.26 * s)],
			0.012 * s, 0.012 * s, m, seg=6)
	if not open_:
		kit.cylinder(0.048 * s, 0.05 * s, (x, y, z + 0.385 * s), WD(), verts=10, bevel=0.003)
		kit.cylinder(0.05 * s, 0.012, (x, y, z + 0.414 * s), C((0.4, 0.09, 0.06), 0.6), verts=12, bevel=0.003)
		kit.ring(0.066 * s, 0.005, (x, y, z + 0.35 * s), CORD(), seg=12)


def open_book(w, d, lines=8, cover=None):
	"""An open log book lying flat at the origin: cover board, two page blocks, ruled ink lines."""
	cover = cover or kit.tex_mat("leather", "dark")
	B((2 * w + 0.03, d + 0.02, 0.008), (0, 0, 0.004), cover, bevel=0.002)
	for s_ in (-1, 1):
		B((w, d, 0.022), (s_ * (w / 2 + 0.003), 0, 0.017), PAPER(), bevel=0.004, rot=(0, -s_ * 3, 0))
		for i in range(lines):
			L = w * (0.7 if i % 3 else 0.45)
			B((L, 0.004, 0.004), (s_ * (w / 2 + 0.003) - w * 0.1 + (w * 0.7 - L) / 2, -d / 2 + 0.03 + i * (d - 0.06) / (lines - 1),
				0.0285 + s_ * 0.0 + (w / 2 - abs(s_ * (w * 0.1))) * 0.0), INK(), bevel=0)


def bobbin(c, r=0.035, h=0.08, axis="z"):
	"""A wooden wick bobbin: two flanges and a core wound with linen wick."""
	def build():
		for zz in (0.006, h - 0.006):
			kit.cylinder(r, 0.012, (0, 0, zz), WD(), verts=12, bevel=0.002)
		kit.cylinder(r * 0.4, h, (0, 0, h / 2), WD(), verts=10, bevel=0)
		kit.cylinder(r * 0.78, h - 0.024, (0, 0, h / 2), LINEN(J(0.04)), verts=14, bevel=0.002)
		for k in range(3):
			kit.ring(r * 0.78, 0.003, (0, 0, 0.022 + k * (h - 0.044) / 2), LINEN(-0.08), seg=14)
	return group(build, at=c, rot=(90, 0, 0) if axis == "y" else (0, 0, 0))


def rs_oil_jar_stand():
	foot((1.36, 0.72, 0.08), (0, 0, 0.04), tone=S("c"))
	body = B((1.3, 0.62, 0.45), (0, 0, 0.075 + 0.225), S("b"), bevel=0.018)
	top = 0.075 + 0.45
	for x in (-0.4, 0.0, 0.4):
		carve(body, [kit.cylinder(0.15, 0.3, (x, 0.07, top), GROOVE(), verts=18, bevel=0)])
	yf = -0.31
	fx, fz = 0.0, 0.3  # flame sign cut in: a teardrop with an inner tongue
	cuts = gline([(fx + 0.07 * math.sin(a) * (1 - 0.6 * (a / math.pi - 0.5) ** 2 * 0 if a < math.pi else 1), fz + 0.0) for a in ()] or
		[(fx, fz + 0.13), (fx + 0.04, fz + 0.06), (fx + 0.06, fz - 0.0), (fx + 0.045, fz - 0.05), (fx, fz - 0.07), (fx - 0.045, fz - 0.05),
		(fx - 0.06, fz), (fx - 0.04, fz + 0.06), (fx, fz + 0.13)], 0.014, yf, 0.012)
	cuts += gline([(fx, fz + 0.05), (fx + 0.02, fz - 0.01), (fx, fz - 0.04), (fx - 0.02, fz - 0.01), (fx, fz + 0.05)], 0.01, yf, 0.01)
	cuts += runes(-0.58, -0.12, 0.3, yf, h=0.07, gap=0.06)
	cuts += runes(0.12, 0.58, 0.3, yf, h=0.07, gap=0.06)
	cuts.append(cy(bar((-0.62, 0.46), (0.62, 0.46), 0.012), yf, 0.008))
	carve(body, cuts)
	for i, x in enumerate((-0.4, 0.0, 0.4)):
		oil_jar(x, 0.07, top - 0.148, 1.0, open_=(i == 1), m=CLAYT(("c", "b", "c")[i]))
	jz = top - 0.148
	along(lambda L: (rod((0, 0, 0), (0, 0, L), 0.008, BRASS("b")), tube([(0, 0, L), (0, -0.03, L + 0.02), (0, -0.05, L)], 0.007, 0.007, BRASS("b"), seg=6)),
		(0.0, 0.07, jz + 0.09), (0.05, 0.05, jz + 0.62))  # dipper handle standing in the open jar
	# brass funnel (wide end down) and a small brass pitcher on the front strip
	cup([(0, top - 0.004), (0.075, top - 0.004), (0.075, top + 0.01), (0.02, top + 0.07), (0.013, top + 0.13), (0.008, top + 0.13), (0.014, top + 0.07),
		(0.068, top + 0.008), (0, top + 0.008)], (0.2, -0.2), BRASS("a"), seg=16)
	cup([(0, top - 0.004), (0.045, top - 0.002), (0.055, top + 0.05), (0.04, top + 0.11), (0.045, top + 0.13), (0.038, top + 0.13), (0.033, top + 0.1),
		(0.045, top + 0.05), (0, top + 0.01)], (-0.22, -0.2), BRASS("b"), seg=14)
	tube([(-0.18, -0.2, top + 0.11), (-0.14, -0.2, top + 0.1), (-0.14, -0.2, top + 0.04), (-0.175, -0.2, top + 0.03)], 0.007, 0.007, BRASS("dark"), seg=6)
	kit.cone(0.012, 0.005, 0.05, (-0.27, -0.2, top + 0.115), BRASS("b"), rot=(0, -60, 0), verts=8)
	floor_cut()


def rs_lens_workbench():
	for x in (-0.62, 0.62):
		foot((0.3, 0.7, 0.08), (x, 0, 0.04), tone=S("c"))
		B((0.2, 0.6, 0.6), (x, 0, 0.375), S("b"), bevel=0.015)
		B((0.26, 0.66, 0.06), (x, 0, 0.69), S("a"), bevel=0.012)
	for k, y in enumerate((-0.255, -0.085, 0.085, 0.255)):
		B((1.62, 0.165, 0.07), (0, y, 0.75), T("wood", ("dark", "c", "dark", "b")[k]), bevel=0.008)
	B((1.04, 0.5, 0.04), (0, 0, 0.22), WD(), bevel=0.006)  # low shelf between the trestles
	tz = 0.785 - 0.003
	# polishing stand: stone block, brass ring, the lens clamped in it
	px, py = -0.4, 0.1
	B((0.24, 0.2, 0.1), (px, py, tz + 0.05), S("a"), bevel=0.01)
	for s_ in (-1, 1):
		B((0.03, 0.06, 0.2), (px + s_ * 0.11, py, tz + 0.18), BRASS("dark"), bevel=0.004)
	rz = tz + 0.24
	group(lambda: lens_disc(0.1, 0.022), at=(px, py, rz), rot=(90, 0, 0))
	kit.ring(0.103, 0.012, (px, py, rz), BRASS("b"), rot=(90, 0, 0), seg=22)
	for s_ in (-1, 1):
		kit.cylinder(0.01, 0.05, (px + s_ * 0.105, py, rz), IRON("dark"), rot=(0, 90, 0), verts=8)
		kit.cylinder(0.018, 0.012, (px + s_ * 0.13, py, rz), IRON("a"), rot=(0, 90, 0), verts=8)
	# the polishing lap: wooden disc on an iron spindle, cranked
	lx, ly = 0.05, 0.1
	kit.cylinder(0.05, 0.04, (lx, ly, tz + 0.02), IRON("dark"), verts=10)
	kit.cylinder(0.012, 0.12, (lx, ly, tz + 0.08), IRON("dark"), verts=8)
	kit.cylinder(0.16, 0.035, (lx, ly, tz + 0.11), WD(), verts=20, bevel=0.004)
	kit.cylinder(0.13, 0.004, (lx, ly, tz + 0.1295), C((0.45, 0.2, 0.15), 0.9), verts=20, bevel=0)  # rouge on the lap face
	B((0.17, 0.03, 0.02), (lx + 0.085, ly, tz + 0.145), IRON("dark"), bevel=0.003)
	kit.cylinder(0.014, 0.08, (lx + 0.16, ly, tz + 0.19), WD(), verts=8)
	# glass blanks stacked, wick bobbins, calipers, grit pot
	for k in range(4):
		kit.cylinder(0.06, 0.015, (0.45 + J(0.004), -0.17 + J(0.004), tz + 0.0075 + k * 0.012), GLASS(), verts=16, bevel=0.003)
	for k, (x, y) in enumerate(((0.42, 0.15), (0.52, 0.2), (0.62, 0.12))):
		bobbin((x, y, tz))
	for a in (-12, 14):
		B((0.2, 0.012, 0.006), (-0.05, -0.2, tz + 0.003 + (a > 0) * 0.005), BRASS("b"), bevel=0.001, rot=(0, 0, a))
	kit.cylinder(0.012, 0.01, (-0.145, -0.2, tz + 0.01), BRASS("dark"), verts=8)
	cup([(0, tz), (0.045, tz + 0.002), (0.055, tz + 0.04), (0.05, tz + 0.045), (0.044, tz + 0.012), (0, tz + 0.01)], (-0.6, -0.15), CLAYT("b"), seg=14)
	kit.cylinder(0.042, 0.006, (-0.6, -0.15, tz + 0.032), C((0.45, 0.2, 0.15), 0.95), verts=14, bevel=0)
	# on the shelf: a brass lens ring and two bobbins
	kit.ring(0.11, 0.014, (0.2, 0.0, 0.254), BRASS("b"), seg=22)
	bobbin((-0.25, 0.05, 0.24))
	bobbin((-0.35, -0.08, 0.24))
	floor_cut()


def rs_great_lens_cradle():
	ap = math.cos(math.pi / 8)
	kit.cylinder(0.58, 0.12, (0, 0, 0.06), S("c"), verts=8, bevel=0.015).rotation_euler.z = math.pi / 8
	body = kit.cylinder(0.5, 0.36, (0, 0, 0.115 + 0.18), S("b"), verts=8, bevel=0.015)
	body.rotation_euler.z = math.pi / 8
	kit.cylinder(0.54, 0.06, (0, 0, 0.5), S("a"), verts=8, bevel=0.012).rotation_euler.z = math.pi / 8
	bpy.context.view_layer.update()
	yf = -0.5 * ap
	cuts = runes(-0.15, 0.15, 0.3, yf, h=0.07, gap=0.055)
	cuts += gline([(math.cos(2 * math.pi * k / 12) * 0.05 - 0.0, 0.3 + math.sin(2 * math.pi * k / 12) * 0.05) for k in range(13)], 0.01, yf - 0.0, 0.006)[:0]
	carve(body, cuts)
	top = 0.53
	disc = kit.cylinder(0.42, 0.05, (0, 0, top + 0.02), BRASS("b"), verts=28, bevel=0.004)
	for k in range(28):  # teeth round the turning disc
		a = 2 * math.pi * (k + 0.5) / 28
		B((0.03, 0.025, 0.04), (math.cos(a) * 0.43, math.sin(a) * 0.43, top + 0.02), BRASS("dark"), bevel=0.002, rot=(0, 0, math.degrees(a)))
	B((1.14, 0.14, 0.06), (0, 0, top + 0.072), BRASS("a"), bevel=0.006)
	for s_ in (-1, 1):  # the yoke
		B((0.16, 0.2, 0.05), (s_ * 0.53, 0, top + 0.12), BRASS("dark"), bevel=0.006)
		B((0.07, 0.11, 0.62), (s_ * 0.53, 0, top + 0.43), BRASS("a"), bevel=0.008)
		B((0.11, 0.15, 0.1), (s_ * 0.53, 0, top + 0.6), BRASS("dark"), bevel=0.008)
		kit.cylinder(0.03, 0.08, (s_ * 0.475, 0, top + 0.6), IRON("dark"), rot=(0, 90, 0), verts=10)
		kit.cylinder(0.045, 0.02, (s_ * 0.594, 0, top + 0.6), IRON("a"), rot=(0, 90, 0), verts=10)
	lz = top + 0.6

	def lens():
		lens_disc(0.43, 0.05)
		ring_mesh((0, 0, 0), [(0.425, -0.035), (0.46, -0.035), (0.46, 0.035), (0.425, 0.035)], BRASS("b"), seg=32)
		for k in range(16):
			a = 2 * math.pi * k / 16
			kit.rivet((math.cos(a) * 0.445, math.sin(a) * 0.445, -0.037), BRASS("dark"), r=0.009)
	group(lens, at=(0, 0, lz), rot=(80, 0, 0))
	# crank: a small gear meshing with the disc teeth, a shaft and handle, on a bracket off the plinth
	gx, gy = 0.0, -0.53
	B((0.14, 0.12, 0.04), (gx, gy + 0.05, top - 0.02), IRON("dark"), bevel=0.004)
	toothed_gear((gx, gy, top + 0.02), 0.075, 0.035, BRASS("dark"), n=10, spokes=4)
	kit.cylinder(0.014, 0.3, (gx, gy, top + 0.17), IRON("dark"), verts=8)
	B((0.16, 0.03, 0.025), (gx + 0.07, gy, top + 0.31), IRON("dark"), bevel=0.003)
	kit.cylinder(0.016, 0.09, (gx + 0.14, gy, top + 0.36), WD(), verts=8)
	floor_cut()


def rs_reflector_plates():
	p, yf = panel_wall(1.5, 1.4, 0.16)
	cuts = runes(-0.6, 0.6, 1.36, yf, h=0.06, gap=0.055)
	sx, sz = -0.4, 0.42  # sun sign: ring and rays
	cuts += gline([(sx + math.cos(2 * math.pi * k / 14) * 0.07, sz + math.sin(2 * math.pi * k / 14) * 0.07) for k in range(15)], 0.012, yf)
	for k in range(8):
		a = 2 * math.pi * k / 8
		cuts.append(cy(bar((sx + math.cos(a) * 0.1, sz + math.sin(a) * 0.1), (sx + math.cos(a) * 0.15, sz + math.sin(a) * 0.15), 0.012), yf, 0.01))
	carve(p, cuts)

	def dish(R):
		cup([(0, 0.0), (R * 0.4, R * 0.02), (R * 0.8, R * 0.09), (R, R * 0.17), (R * 1.02, R * 0.19), (R * 0.97, R * 0.19), (R * 0.78, R * 0.11),
			(R * 0.4, R * 0.045), (0, R * 0.03)], (0, 0), BRASS("a"), seg=28)
		kit.ring(R * 1.0, 0.012, (0, 0, R * 0.18), BRASS("dark"), seg=28)
		kit.cylinder(0.05, 0.04, (0, 0, -0.018), BRASS("dark"), verts=12)
		for k in range(8):
			a = 2 * math.pi * k / 8
			kit.rivet((math.cos(a) * R * 0.95, math.sin(a) * R * 0.95, R * 0.2), BRASS("dark"), r=0.008)
	for R, x, z in ((0.3, -0.33, 0.95), (0.21, 0.38, 1.05), (0.15, 0.4, 0.55)):
		dy = yf - 0.13
		group(lambda R=R: dish(R), at=(x, dy, z), rot=(90, 0, 0))
		kit.cylinder(0.022, 0.15, (x, yf - 0.07, z), IRON("dark"), rot=(90, 0, 0), verts=8)  # bracket arm into the stone
		B((0.12, 0.02, 0.12), (x, yf - 0.006, z), IRON("a"), bevel=0.004)
		for k in (-1, 1):
			kit.rivet((x + k * 0.04, yf - 0.017, z + 0.04), IRON("dark"), r=0.01)
			kit.rivet((x + k * 0.04, yf - 0.017, z - 0.04), IRON("dark"), r=0.01)
	# a ledge with a polishing stone and a rouge tin
	B((0.36, 0.16, 0.05), (0.25, yf - 0.075, 0.28), S("a"), bevel=0.008)
	prism([(yf - 0.13, 0.255), (yf + 0.005, 0.255), (yf + 0.005, 0.15)], 0.13, 0.17, S("c"), axis="x")
	prism([(yf - 0.13, 0.255), (yf + 0.005, 0.255), (yf + 0.005, 0.15)], 0.33, 0.37, S("c"), axis="x")
	B((0.14, 0.06, 0.04), (0.2, yf - 0.08, 0.322), T("warmstone", "a"), bevel=0.008, rot=(0, 0, 8))
	kit.cylinder(0.035, 0.03, (0.34, yf - 0.08, 0.318), BRASS("b"), verts=12)
	kit.cylinder(0.037, 0.008, (0.34, yf - 0.08, 0.336), BRASS("dark"), verts=12)
	floor_cut()
	flat_back(0.08)


def rs_signal_shutters():
	back = 0.12
	foot((1.44, 0.34, 0.1), (0, -0.02, 0.05), tone=S("c"))
	for s_ in (-1, 1):
		B((0.16, 0.24, 1.5), (s_ * 0.55, 0, 0.095 + 0.75), S("b"), bevel=0.015)
	lint = B((1.36, 0.26, 0.18), (0, -0.005, 1.68), S("a"), bevel=0.015)
	B((1.3, 0.28, 0.12), (0, -0.01, 0.15), S("a"), bevel=0.012)
	carve(lint, runes(-0.45, 0.45, 1.68, -0.135, h=0.07, gap=0.06))
	B((0.96, 0.02, 1.4), (0, 0.105, 0.9), DARK(), bevel=0)  # dark behind (the lamp is out)
	for k in range(8):  # slats on pivot pins, all SHUT: each overlaps the next like a closed louvre
		z = 0.32 + k * 0.165
		B((0.95, 0.025, 0.17), (0, 0.0, z), T("wood", ("dark", "c")[k % 2]), bevel=0.004, rot=(8, 0, 0))
		for s_ in (-1, 1):
			kit.cylinder(0.012, 0.04, (s_ * 0.47, 0.0, z), IRON("dark"), rot=(0, 90, 0), verts=8)
		B((0.05, 0.06, 0.02), (0.3, -0.04, z + 0.03), IRON("dark"), bevel=0.003)  # staple to the tie bar
	B((0.045, 0.03, 1.3), (0.3, -0.07, 0.95), WD(), bevel=0.005)  # tie bar
	# iron lever on the jamb, linked to the tie bar, a chain down to a floor ring
	pv = (0.55, -0.135, 0.95)
	kit.cylinder(0.03, 0.03, pv, IRON("a"), rot=(90, 0, 0), verts=10)
	rod(pv, (0.31, -0.1, 1.05), 0.014, IRON("dark"))
	rod(pv, (0.62, -0.14, 0.62), 0.016, IRON("dark"))
	kit.cylinder(0.022, 0.1, (0.62, -0.14, 0.58), WD(), verts=8)
	chain((0.62, -0.14, 0.52), (0.62, -0.15, 0.13))
	kit.ring(0.04, 0.01, (0.62, -0.15, 0.106), IRON("dark"), rot=(90, 0, 0), seg=12)
	B((0.06, 0.06, 0.02), (0.62, -0.15, 0.1), IRON("a"), bevel=0.004)
	for s_ in (-1, 1):  # iron corner plates on the lintel
		B((0.12, 0.012, 0.12), (s_ * 0.6, -0.14, 1.66), IRON("a"), bevel=0.003)
		kit.rivet((s_ * 0.6, -0.147, 1.66), IRON("dark"), r=0.012)
	floor_cut()
	flat_back(back)


def rs_keeper_log_desk():
	foot((0.72, 0.56, 0.08), (0, 0, 0.04), tone=S("c"))
	body = B((0.52, 0.42, 0.86), (0, 0.02, 0.075 + 0.43), S("b"), bevel=0.015)
	carve(body, [B((0.38, 0.3, 0.3), (0, -0.07, 0.42), GROOVE(), bevel=0)])
	carve(body, runes(-0.18, 0.18, 0.72, -0.19, h=0.06, gap=0.05))
	for k, h in enumerate((0.05, 0.045, 0.06)):  # old logs stacked in the shelf
		B((0.3 - 0.02 * k, (0.22, 0.2, 0.21)[k], h), (J(0.01), -0.05, 0.266 + sum((0.05, 0.045, 0.06)[:k]) + h / 2 - 0.004 * k), kit.tex_mat("leather", ("dark", "a", "dark")[k]), bevel=0.006)
	B((0.08, 0.19, 0.18), (0.13, -0.075, 0.36), kit.tex_mat("leather", "a"), bevel=0.006, rot=(0, -12, 0))
	group(lambda: (B((0.78, 0.52, 0.05), (0, 0, 0), WD(), bevel=0.008), B((0.78, 0.03, 0.04), (0, -0.25, 0.035), BRASS("b"), bevel=0.004)),
		at=(0, -0.02, 0.975), rot=(15, 0, 0))
	group(lambda: open_book(0.2, 0.28, lines=8), at=(0, -0.04, 1.0), rot=(15, 0, 0))
	B((0.78, 0.13, 0.04), (0, 0.27, 1.08), S("a"), bevel=0.008)  # flat back ledge
	lt = 1.1
	# sand-glass
	gx = -0.24
	for zz in (lt + 0.006, lt + 0.17):
		kit.cylinder(0.05, 0.012, (gx, 0.27, zz), BRASS("b"), verts=12)
	for k in range(3):
		a = 2 * math.pi * k / 3
		rod((gx + math.cos(a) * 0.04, 0.27 + math.sin(a) * 0.04, lt + 0.01), (gx + math.cos(a) * 0.04, 0.27 + math.sin(a) * 0.04, lt + 0.168), 0.005, BRASS("dark"))
	solid_lathe([(0.004, 0.0), (0.03, 0.02), (0.033, 0.05), (0.008, 0.08), (0.008, 0.085), (0.03, 0.11), (0.033, 0.14), (0.004, 0.155)], (gx, 0.27, lt + 0.008), GLASS(), seg=12)
	kit.cone(0.026, 0.004, 0.03, (gx, 0.27, lt + 0.03), SAND(), verts=12)
	# inkwell and quill, candle stub, oil gauge stick
	cup([(0, lt), (0.03, lt + 0.002), (0.035, lt + 0.03), (0.016, lt + 0.045), (0.012, lt + 0.045), (0.01, lt + 0.035), (0, lt + 0.034)], (0.18, 0.27), INK(), seg=12)
	tube([(0.18, 0.27, lt + 0.03), (0.2, 0.26, lt + 0.12), (0.23, 0.25, lt + 0.22)], 0.003, 0.002, C((0.8, 0.76, 0.66), 0.8), seg=5)
	prism([(0.2, lt + 0.11), (0.215, lt + 0.11), (0.235, lt + 0.22), (0.228, lt + 0.23)], 0.25, 0.258, C((0.8, 0.76, 0.66), 0.8), axis="y")
	candle(0.3, 0.27, lt, 0.018, 0.05, lit=False)
	kit.cylinder(0.008, 0.4, (0.28, 0.25, lt + 0.004), BRASS("b"), rot=(0, 90, 15), verts=8)
	floor_cut()


def rs_oil_hoist():
	back = 0.2
	foot((0.56, 0.5, 0.1), (0, -0.02, 0.05), tone=S("c"))
	pil = B((0.42, 0.3, 1.95), (0, 0.05, 0.095 + 0.975), S("b"), bevel=0.015)
	carve(pil, runes(-0.12, 0.12, 1.55, -0.1, h=0.06, gap=0.05))
	B((0.38, 0.24, 0.12), (0, -0.16, 1.86), S("a"), bevel=0.012)
	B((0.3, 0.14, 0.1), (0, -0.13, 1.76), S("c"), bevel=0.012)
	B((0.46, 0.34, 0.08), (0, 0.0, 2.05), S("a"), bevel=0.012)
	# iron jib, brace and the spoked pulley in its fork
	rod((0, -0.25, 1.88), (0, -0.62, 1.88), 0.022, IRON("dark"))
	rod((0, -0.1, 1.45), (0, -0.45, 1.87), 0.016, IRON("dark"))
	B((0.1, 0.02, 0.12), (0, -0.1, 1.45), IRON("a"), bevel=0.003)
	wx, wy, wz = 0, -0.6, 1.72
	for s_ in (-1, 1):
		B((0.012, 0.05, 0.2), (s_ * 0.035, wy, 1.79), IRON("dark"), bevel=0.003)
	kit.cylinder(0.01, 0.1, (wx, wy, wz), IRON("a"), rot=(0, 90, 0), verts=8)
	kit.ring(0.1, 0.018, (wx, wy, wz), WD(), rot=(0, 90, 0), seg=20)
	kit.cylinder(0.03, 0.05, (wx, wy, wz), WD(), rot=(0, 90, 0), verts=10)
	for k in range(6):
		a = 2 * math.pi * k / 6
		rod((wx, wy + math.cos(a) * 0.02, wz + math.sin(a) * 0.02), (wx, wy + math.cos(a) * 0.09, wz + math.sin(a) * 0.09), 0.008, WD())
	# rope: over the wheel, down to the jar cradle in front, back down to the cleat
	tube([(0, wy - 0.115 * math.cos(a), wz + 0.115 * math.sin(a)) for a in [math.pi * k / 8 for k in range(9)]], 0.012, 0.012, CORD(), seg=6)
	jz = 0.5
	rod((0, wy - 0.115, wz), (0, wy - 0.115, jz + 0.55), 0.012, CORD())
	hk = (0, wy - 0.115, jz + 0.55)
	kit.ring(0.025, 0.006, (hk[0], hk[1], hk[2] - 0.02), IRON("dark"), rot=(0, 90, 0), seg=10)
	oil_jar(0, wy - 0.115, jz, 1.0)
	for k in range(4):  # rope cradle round the jar
		a = 2 * math.pi * k / 4 + 0.4
		rod((hk[0], hk[1], hk[2] - 0.04), (math.cos(a) * 0.12, wy - 0.115 + math.sin(a) * 0.12, jz + 0.27), 0.006, CORD())
		rod((math.cos(a) * 0.12, wy - 0.115 + math.sin(a) * 0.12, jz + 0.27), (math.cos(a) * 0.12, wy - 0.115 + math.sin(a) * 0.12, jz + 0.12), 0.006, CORD())
	kit.ring(0.128, 0.008, (0, wy - 0.115, jz + 0.2), CORD(), seg=18)
	rod((0, wy + 0.115, wz), (0, -0.13, 0.95), 0.012, CORD())
	B((0.26, 0.05, 0.04), (0, -0.125, 0.93), IRON("dark"), bevel=0.005)  # cleat
	for s_ in (-1, 1):
		B((0.04, 0.05, 0.06), (s_ * 0.08, -0.115, 0.93), IRON("dark"), bevel=0.004)
	for k in range(3):  # the made-fast end hanging in coils
		kit.ring(0.07 + 0.01 * k, 0.011, (0.04 * k - 0.04, -0.17, 0.86 - 0.02 * k), CORD(), rot=(90, 0, 10 * k), seg=16)
	floor_cut()
	flat_back(back)


def chimney(x, y, z, s=1.0, m=None):
	"""A glass lamp chimney: a waisted tube with a bulge, standing open-ended."""
	return cup([(0.035 * s, z), (0.04 * s, z + 0.01 * s), (0.06 * s, z + 0.07 * s), (0.055 * s, z + 0.12 * s), (0.032 * s, z + 0.17 * s), (0.034 * s, z + 0.24 * s),
		(0.028 * s, z + 0.24 * s), (0.026 * s, z + 0.17 * s), (0.049 * s, z + 0.12 * s), (0.054 * s, z + 0.07 * s), (0.034 * s, z + 0.012 * s), (0.029 * s, z + 0.004)],
		(x, y), m or GLASS(), seg=16)


def rs_chimney_rack():
	back = 0.18
	foot((1.32, 0.48, 0.1), (0, -0.04, 0.05), tone=S("c"))
	blk = B((1.24, 0.36, 1.3), (0, 0.0, 0.095 + 0.65), S("b"), bevel=0.015)
	B((1.32, 0.42, 0.08), (0, -0.01, 1.42), S("a"), bevel=0.012)
	yf = -0.18
	cells = [(x, z) for z in (0.3, 0.82) for x in (-0.39, 0.0, 0.39)]
	for x, z in cells:  # cubbies cut one at a time
		carve(blk, [B((0.32, 0.3, 0.38), (x, yf + 0.12, z + 0.19), GROOVE(), bevel=0)])
	carve(blk, runes(-0.5, 0.5, 1.29, yf, h=0.06, gap=0.055))
	for i, (x, z) in enumerate(cells):
		B((0.16, 0.012, 0.05), (x, yf - 0.004, z - 0.05), BRASS("b"), bevel=0.003)  # label plate
		for k in (-1, 1):
			kit.rivet((x + k * 0.065, yf - 0.011, z - 0.05), BRASS("dark"), r=0.006)
		fz = z - 0.003
		if i in (0, 2, 4):
			chimney(x - 0.07, -0.08, fz)
			chimney(x + 0.07, -0.08, fz, 0.92)
		elif i == 1:
			kit.ring(0.12, 0.016, (x, -0.0, fz + 0.125), BRASS("b"), rot=(80, 0, 0), seg=22)
			kit.ring(0.09, 0.014, (x, -0.06, fz + 0.093), BRASS("a"), rot=(82, 0, 0), seg=20)
		elif i == 3:
			kit.ring(0.12, 0.016, (x, -0.0, fz + 0.125), BRASS("a"), rot=(80, 0, 0), seg=22)
			chimney(x + 0.1, -0.08, fz, 0.8)
		else:  # the cracked chimney lying in two pieces with shards
			group(lambda: chimney(0, 0, 0), at=(x - 0.04, -0.06, fz + 0.06), rot=(0, 90, 15))
			for k in range(4):
				prism([(0, 0), (0.03 + 0.01 * k, 0.005), (0.012, 0.025)], fz + 0.002, fz + 0.008, GLASS(), axis="z").location = (x + 0.06 + k * 0.025, -0.1 + J(0.02), 0)
	floor_cut()
	flat_back(back)


def rs_wick_board():
	p, yf = panel_wall(1.3, 1.3, 0.16)
	carve(p, runes(-0.5, 0.5, 1.28, yf, h=0.06, gap=0.055))
	for k, x in enumerate((-0.42, -0.14, 0.14, 0.42)):  # iron spindles, bobbins, wick tails through brass guides
		kit.cylinder(0.009, 0.16, (x, yf - 0.075, 1.06), IRON("dark"), rot=(90, 0, 0), verts=8)
		B((0.06, 0.012, 0.06), (x, yf - 0.003, 1.06), IRON("a"), bevel=0.003)
		bobbin((x, yf - 0.03, 1.06), r=0.05, h=0.09, axis="y")
		B((0.022, 0.004, 0.1), (x, yf - 0.075, 0.97), LINEN(J(0.03)), bevel=0)
		kit.ring(0.022, 0.006, (x, yf - 0.075, 0.9), BRASS("b"), rot=(90, 0, 0), seg=12)
		kit.cylinder(0.005, 0.07, (x, yf - 0.04, 0.9 - 0.022), BRASS("dark"), rot=(90, 0, 0), verts=6)
		B((0.022, 0.004, 0.18 + 0.03 * k), (x, yf - 0.075, 0.86 - (0.18 + 0.03 * k) / 2 + 0.03), LINEN(J(0.03)), bevel=0)
	for x in (-0.35, 0.0, 0.35):  # hook row
		kit.cylinder(0.008, 0.07, (x, yf - 0.035, 0.55), IRON("dark"), rot=(90, 0, 0), verts=6)
		kit.cylinder(0.008, 0.03, (x, yf - 0.07, 0.565), IRON("dark"), verts=6)
	# shears: two crossed blades and bow loops, hanging from the left hook
	for s_ in (-1, 1):
		B((0.016, 0.006, 0.16), (-0.35 + s_ * 0.012, yf - 0.06 - (s_ > 0) * 0.008, 0.43), IRON("a"), bevel=0.002, rot=(0, s_ * 8, 0))
		kit.ring(0.022, 0.005, (-0.35 + s_ * 0.022, yf - 0.06, 0.53), IRON("dark"), rot=(90, 0, 0), seg=10)
	# trimming knife hanging by a leather loop
	kit.ring(0.02, 0.004, (0.0, yf - 0.07, 0.535), kit.tex_mat("leather", "a"), rot=(90, 0, 0), seg=10)
	B((0.024, 0.02, 0.09), (0.0, yf - 0.07, 0.47), WD(), bevel=0.004)
	prism([(-0.012, 0.425), (0.012, 0.425), (0.006, 0.33), (-0.012, 0.35)], yf - 0.073, yf - 0.067, IRON("a"), axis="y")
	# brass snuffer: cone on a rod
	rod((0.35, yf - 0.07, 0.56), (0.35, yf - 0.07, 0.36), 0.005, BRASS("dark"))
	kit.cone(0.03, 0.008, 0.05, (0.35, yf - 0.07, 0.355), BRASS("b"), rot=(180, 0, 0), verts=10)
	# shelf with a tray of cut wicks laid side by side
	B((0.8, 0.16, 0.04), (0, yf - 0.075, 0.28), S("a"), bevel=0.008)
	for s_ in (-0.3, 0.3):
		prism([(yf - 0.15, 0.262), (yf + 0.005, 0.262), (yf + 0.005, 0.16)], s_ - 0.02, s_ + 0.02, S("c"), axis="x")
	tz = 0.3 - 0.003
	B((0.42, 0.12, 0.012), (0.05, yf - 0.08, tz + 0.006), WD(), bevel=0.002)
	for s_ in (-1, 1):
		B((0.42, 0.012, 0.03), (0.05, yf - 0.08 + s_ * 0.055, tz + 0.015), WD(), bevel=0.002)
		B((0.012, 0.12, 0.03), (0.05 + s_ * 0.205, yf - 0.08, tz + 0.015), WD(), bevel=0.002)
	for k in range(10):
		B((0.03, 0.09, 0.004), (-0.12 + k * 0.038, yf - 0.08, tz + 0.013), LINEN(J(0.04)), bevel=0)
	floor_cut()
	flat_back(0.08)


def rs_lantern_cage_fallen():
	def cage():
		R = 0.4
		for z in (0.0, 0.5, 1.0):
			ring_mesh((0, 0, z), [(R - 0.02, -0.025), (R + 0.015, -0.025), (R + 0.015, 0.025), (R - 0.02, 0.025)], IRON("dark"), seg=8)
		for k in range(8):
			a = 2 * math.pi * k / 8
			c, s = math.cos(a), math.sin(a)
			if k in (2, 3):  # bent bars, pushed in where it hit
				dent = 0.12 if k == 2 else 0.08
				tube([(c * R, s * R, 0.0), (c * R, s * R, 0.3), (c * (R - dent), s * (R - dent), 0.5), (c * (R - dent * 0.6), s * (R - dent * 0.6), 0.72), (c * R, s * R, 1.0)],
					0.016, 0.016, IRON("dark"), seg=6)
			elif k == 6:  # one bar snapped
				rod((c * R, s * R, 0.0), (c * R, s * R, 0.38), 0.016, IRON("dark"))
				rod((c * R, s * R, 1.0), (c * R * 1.1, s * R * 1.1, 0.74), 0.016, IRON("dark"))
			else:
				rod((c * R, s * R, 0.0), (c * R, s * R, 1.0), 0.016, IRON("dark"))
		kit.cylinder(R - 0.01, 0.03, (0, 0, -0.005), IRON("a"), verts=8, bevel=0.004)
		cup([(0, 0.004), (0.12, 0.008), (0.15, 0.06), (0.14, 0.09), (0.13, 0.09), (0.13, 0.065), (0.1, 0.03), (0, 0.025)], (0, 0), BRASS("dark"), seg=18)
		kit.cylinder(0.02, 0.05, (0, 0, 0.05), SOOT(), verts=8)
		a0, a1 = 2 * math.pi * 4 / 8, 2 * math.pi * 5 / 8  # one pane left, cracked
		pts = [(math.cos(a0) * (R - 0.003), math.sin(a0) * (R - 0.003)), (math.cos(a1) * (R - 0.003), math.sin(a1) * (R - 0.003))]
		v = [(pts[0][0], pts[0][1], 0.52), (pts[1][0], pts[1][1], 0.52), (pts[1][0], pts[1][1], 0.98), (pts[0][0] * 0.98 + pts[1][0] * 0.02, pts[0][1] * 0.98 + pts[1][1] * 0.02, 0.78)]
		mesh(v + [(x * 0.97, y * 0.97, z) for x, y, z in v], [(0, 1, 2, 3), (7, 6, 5, 4), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)], GLASS())
	g = group(cage, at=(0, 0, 0), rot=(0, 90, 0))
	turn(g, "Z", 20, (0, 0, 0))
	drop(g, -0.006)
	# the roof cone knocked off, lying tilted on the floor beside it
	def roof():
		kit.cone(0.46, 0.05, 0.36, (0, 0, 0.18), IRON("dark"), verts=8, bevel=0.006)
		ring_mesh((0, 0, 0.01), [(0.42, -0.02), (0.47, -0.02), (0.47, 0.02), (0.42, 0.02)], IRON("a"), seg=8)
		kit.cylinder(0.04, 0.08, (0, 0, 0.4), IRON("a"), verts=8)
		kit.ring(0.06, 0.015, (0, 0, 0.5), IRON("dark"), rot=(90, 0, 0), seg=12)
	drop(group(roof, at=(1.05, 0.45, 0.3), rot=(0, 28, 40)), -0.004)
	for k in range(14):  # glass shards
		a, d = rng.uniform(0, 6.28), rng.uniform(0.55, 1.0)
		x, y = math.cos(a) * d - 0.1, math.sin(a) * d * 0.8 - 0.4
		s = rng.uniform(0.04, 0.09)
		prism([(0, 0), (s, s * 0.2), (s * 0.4, s * 0.8)], 0.0, 0.01, GLASS(), axis="z").location = (x, y, 0)
	# a cracked chunk of its carved stone seat
	chunk = B((0.5, 0.32, 0.24), (-0.95, 0.35, 0.12), S("b"), bevel=0.02, rot=(0, 0, 25))
	bpy.context.view_layer.update()
	cuts = [B((0.6, 0.02, 0.05), (-0.95, 0.35, 0.24), GROOVE(), bevel=0, rot=(0, 0, 25 + 30))]
	carve(chunk, cuts)
	for k, (x, y, sz) in enumerate(((-0.6, 0.6, 0.06), (-0.7, 0.1, 0.05), (-1.25, 0.15, 0.07))):  # stone chips
		drop([kit.gem((x, y, 0.2), (sz * 1.3, sz, sz * 0.6), S(("b", "c")[k % 2]), seed=k + 3)], -0.002)
	floor_cut()


def rs_lens_shattered():
	def yoke():
		B((1.14, 0.14, 0.06), (0, 0, 0.03), BRASS("a"), bevel=0.006)
		for s_ in (-1, 1):
			B((0.07, 0.11, 0.6), (s_ * 0.53, 0, 0.33), BRASS("a"), bevel=0.008)
			B((0.11, 0.15, 0.1), (s_ * 0.53, 0, 0.6), BRASS("dark"), bevel=0.008)
			B((0.16, 0.2, 0.05), (s_ * 0.53, 0, 0.05), BRASS("dark"), bevel=0.006)
	drop(group(yoke, at=(-0.2, 0.55, 0.1), rot=(90, 0, 8)), -0.003)
	# the brass ring, bent open, lying on the floor
	pts = []
	for k in range(15):
		a = 0.5 + k * (2 * math.pi - 1.1) / 14
		r = 0.46 * (1 + 0.12 * math.sin(a * 2 + 0.6))
		pts.append((0.15 + math.cos(a) * r, -0.15 + math.sin(a) * r * 0.85, 0.035 + 0.02 * math.sin(a * 3)))
	tube(pts, 0.035, 0.035, BRASS("b"), seg=8)
	# the lens in big curved shards and small bits
	R = 0.43
	for k, (a0, a1, dx, dy, rz) in enumerate(((0, 1.4, 0.1, -0.1, 10), (1.4, 2.6, -0.15, 0.05, -20), (2.6, 3.9, 0.25, 0.12, 35), (3.9, 5.1, -0.05, -0.3, 5),
			(5.1, 6.28, 0.35, -0.2, -15))):
		def shard(a0=a0, a1=a1):
			o = lens_disc(R, 0.05)
			cut = []
			for a in (a0, a1):
				cut.append(B((1.2, 1.2, 0.3), (math.cos(a - math.pi / 2) * 0.6 + math.cos(a) * 0.0 + 0, math.sin(a - math.pi / 2) * 0.6, 0), GROOVE(), bevel=0,
					rot=(0, 0, math.degrees(a))))
			return o, cut
		before = set(bpy.data.objects[:])
		o = lens_disc(R, 0.05)
		mid = (a0 + a1) / 2
		keep = []
		for a, side in ((a0, -1), (a1, 1)):  # cut away everything outside the wedge, one cutter at a time
			c = B((1.4, 1.4, 0.4), (0, 0, 0), GROOVE(), bevel=0)
			c.location = (math.cos(a + side * math.pi / 2) * 0.7 + math.cos(a) * 0.0, math.sin(a + side * math.pi / 2) * 0.7, 0)
			c.rotation_euler.z = a
			carve(o, [c])
		g = new_since(before)
		for ob in g:
			ob.location.x -= math.cos(mid) * 0.12
			ob.location.y -= math.sin(mid) * 0.12
		bpy.context.view_layer.update()
		turn(g, "Z", rz, (0, 0, 0))
		shift(g, (0.15 + dx + math.cos(mid) * 0.18, -0.15 + dy + math.sin(mid) * 0.18, 0))
		drop(g, 0.0)
	for k in range(12):
		a, d = rng.uniform(0, 6.28), rng.uniform(0.7, 1.1)
		s = rng.uniform(0.03, 0.07)
		prism([(0, 0), (s, s * 0.25), (s * 0.35, s * 0.85)], 0.0, 0.012, GLASS(), axis="z").location = (0.15 + math.cos(a) * d, -0.15 + math.sin(a) * d * 0.8, 0)
	kit.cylinder(0.03, 0.09, (0.9, 0.35, 0.03), IRON("dark"), rot=(0, 90, 30), verts=10)  # a pivot pin
	kit.cylinder(0.045, 0.02, (0.86, 0.33, 0.045), IRON("a"), rot=(0, 90, 30), verts=10)
	floor_cut()


def rs_keeper_last_watch():
	for x in (-0.45, 0.45):
		foot((0.26, 0.42, 0.08), (x, 0.1, 0.04), tone=S("c"))
		B((0.2, 0.34, 0.62), (x, 0.1, 0.39), S("b"), bevel=0.015)
	ledge = B((1.2, 0.46, 0.08), (0, 0.1, 0.735), S("a"), bevel=0.012)
	carve(ledge, runes(-0.4, 0.4, 0.735, -0.13, h=0.05, gap=0.045, under=False))
	lt = 0.775 - 0.003
	# the burnt-out lamp: brass font, sooted chimney, a charred wick stub
	lx, ly = -0.2, 0.15
	cup([(0, lt), (0.07, lt + 0.003), (0.085, lt + 0.04), (0.075, lt + 0.08), (0.04, lt + 0.1), (0, lt + 0.1)], (lx, ly), BRASS("dark"), seg=16)
	kit.ring(0.042, 0.008, (lx, ly, lt + 0.1), BRASS("b"), seg=14)
	chimney(lx, ly, lt + 0.098, 0.9, m=SOOTGLASS())
	tube([(lx + 0.08, ly, lt + 0.05), (lx + 0.13, ly, lt + 0.06), (lx + 0.13, ly, lt + 0.02), (lx + 0.083, ly, lt + 0.02)], 0.007, 0.007, BRASS("dark"), seg=6)
	B((0.01, 0.006, 0.02), (lx, ly, lt + 0.11), SOOT(), bevel=0)
	# a closed log and an inkwell left on the ledge
	B((0.22, 0.3, 0.05), (0.25, 0.15, lt + 0.025), kit.tex_mat("leather", "dark"), bevel=0.006, rot=(0, 0, 8))
	cup([(0, lt), (0.03, lt + 0.002), (0.035, lt + 0.03), (0.016, lt + 0.045), (0.012, lt + 0.045), (0.01, lt + 0.035), (0, lt + 0.034)], (0.45, 0.0), INK(), seg=12)
	# the stool knocked over
	def stool():
		kit.cylinder(0.17, 0.05, (0, 0, 0.42), WD(), verts=14, bevel=0.006)
		for k in range(3):
			a = 2 * math.pi * k / 3
			rod((math.cos(a) * 0.1, math.sin(a) * 0.1, 0.41), (math.cos(a) * 0.17, math.sin(a) * 0.17, 0.0), 0.022, WD())
	drop(group(stool, at=(0.15, -0.65, 0.2), rot=(0, 84, 30)), -0.005)
	# the log fallen open on the floor, the oil can tipped, the hand bell dropped
	group(lambda: open_book(0.19, 0.27, lines=8), at=(-0.55, -0.6, 0.0), rot=(0, 0, -18))
	def can():
		cup([(0, 0), (0.07, 0.002), (0.075, 0.12), (0.05, 0.15), (0.02, 0.17), (0.02, 0.19), (0.014, 0.19), (0.014, 0.17), (0, 0.168)], (0, 0), BRASS("b"), seg=16)
		kit.cone(0.018, 0.006, 0.16, (0.08, 0, 0.16), BRASS("dark"), rot=(0, 55, 0), verts=8)
		tube([(-0.05, 0, 0.14), (-0.1, 0, 0.13), (-0.1, 0, 0.04), (-0.07, 0, 0.03)], 0.008, 0.008, BRASS("dark"), seg=6)
	drop(group(can, at=(-0.95, -0.3, 0.2), rot=(0, 95, 150)), -0.004)
	def bell():
		cup([(0, 0.11), (0.03, 0.105), (0.045, 0.06), (0.06, 0.01), (0.065, 0.0), (0.058, 0.0), (0.05, 0.012), (0.036, 0.06), (0.024, 0.1), (0, 0.102)], (0, 0), BRASS("a"), seg=16)
		kit.cylinder(0.014, 0.12, (0, 0, 0.17), WD(), verts=8)
		sphere((0, 0, 0.02), 0.012, IRON("dark"), seg=8, rings=5)
		rod((0, 0, 0.1), (0, 0, 0.03), 0.004, IRON("dark"))
	drop(group(bell, at=(0.75, -0.4, 0.2), rot=(0, 100, -40)), -0.004)
	floor_cut()


MODELS = {k: v for k, v in globals().items() if k.startswith(("rb_", "rs_")) and callable(v)}

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
			for o in bpy.data.objects:
				if o.type == "MESH" and not o.data.uv_layers:
					o.data.uv_layers.new()
			kit.save(str(outdir / f"{name}.glb"), str(jdir / f"{name}.png"), tex_size=256)
			print(f"MODEL_OK {name}")
		except Exception as e:
			import traceback
			traceback.print_exc()
			print(f"MODEL_FAILED {name}: {e!r}")
