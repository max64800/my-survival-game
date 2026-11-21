# Decor set TH (Nov 21): the Tomb of Hald Ironbrow, a MEDIUM dungeon in cut stone (Stonehold style).
# Hald Ironbrow was a great dwarf lord famed for his iron brow-helm. Every carving is CUT INTO the stone
# (boolean difference, dark groove walls). One stone family per model (greystone), bronze/iron/gold metal.
#   blender --background --factory-startup --python builds/decor_nov21_th.py -- [id ...]   (none = all)
# Output: assets/models/decor/<id>.glb (origin bottom-centre, front faces -Y in Blender = +Z in Godot).
# Wall pieces have a flat back at +Y and stand on the floor (a stone backing or post), so they never float.
#
# The 30 objects:
#  th_hald_tomb           Hald's grand tomb chest: carved panels and pilasters, the lid slab carved with a border, his helm sign and runes
#  th_brow_helm_plinth    the real iron brow-helm on a stone stand on a tall carved plinth, bronze corner finials
#  th_armour_stand        his armour (the game's own dwarf armour in iron and bronze) wrapped round an iron stand, helmet on a wooden head, boots
#  th_hammer_rest         his war hammer lying in two cut stone cradles on a carved block, bronze name plate
#  th_drinking_horn       his silver-banded drinking horn in a bronze holder on a carved pedestal, a silver cup beside
#  th_honour_guard        a stone honour-guard statue (the game's dwarf, armoured) with round shield and spear on a stepped, carved plinth
#  th_guard_snapped       (story) the same guard, his stone spear snapped: the top lies across the plinth, chips on the floor
#  th_brazier_grand       a ceremonial stone brazier: carved pedestal, bronze bowl on four claws, glossy coals, fire spot
#  th_brazier_toppled     (story) an iron tripod brazier knocked over, its deep hollow bowl on its rim, coals spilled across the floor
#  th_mourning_banner     (wall) a dark mourning banner with the helm emblem, swallowtail, gold border, on a carved backing stone
#  th_mourning_bell       a bronze mourning bell hung in a cut-stone frame, a striker hammer resting on a hook
#  th_relief_battle       (wall) carved panel: Hald with raised hammer and his guard against a great deep-worm
#  th_relief_forge        (wall) carved panel: Hald forging his brow-helm at the anvil, a bellows-dwarf, fire
#  th_name_plaque         (wall) a framed stone plaque on a stone post: helm emblem and six lines of runes cut in, bronze bolts
#  th_niche_coins         (wall) an arched offering niche cut into a block, full of coins, cups, a ring and gold bars
#  th_niche_candles       (wall) an offering niche with lit candles on a wax pool and a small stone helm idol
#  th_niche_looted        (story, wall) a niche pried open: cracked sill, broken corner on the floor, pry bar jammed in
#  th_urn_shelf           (wall) a two-level stone shelf: a row of bronze ash urns and small lidded stone ash boxes
#  th_sealed_door         (wall) the round sealed tomb door: carved stone disc, iron bands, a chain and the great lock
#  th_door_fallen         (story) the round tomb door broken in two on the floor, bent bands, pry bars, chips
#  th_chest_looted        (story) a stone grave-goods chest, its lid shoved off and lying flat on the floor, empty, a pry bar
#  th_weapon_rack         a carved stone rack holding his guard's axes, hammers and a spear, bronze tags
#  th_shield_wall         (wall) three round shields of his fallen guards on a stone rail; one split
#  th_ash_urn             a grand bronze urn on a carved pedestal, lid topped with a little iron brow-helm
#  th_kneeling_mourner    a stone mourner (the game's dwarf, armoured) on one knee, head bowed, fist on heart, hand on an axe set head-down
#  th_robber_pinned       (story) a fallen carved lintel pinning a tomb robber: skull and arm bones, his satchel, coins
#  th_pillar_fallen       (story) a carved column broken into drums lying on the floor, the stump still on its base
#  th_mourning_bench      a long stone bench for mourners: carved legs with the helm emblem, a silver cup left on it
#  th_offering_table      a stone table with grave goods laid out in neat rows: cups, coin stacks, ring dish, dagger, hammer
#  th_wall_lamp           (wall) a carved stone lamp stele: corbel, iron hook, a chained bronze oil lamp, lit
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from night_stations import B, GAME, J, T, kit, log, mesh, rng, stone  # noqa: E402
from night_materials import C, lump, sphere, _cm  # noqa: E402
from decor_nov21_a import bar, chain, circ, low_z, objs, prism, rod, shift, turn  # noqa: E402
from decor_nov21_b import bone, coin, skull  # noqa: E402
from decor_nov21_d import tube  # noqa: E402

S = lambda v=None: T("greystone", v)  # noqa: E731  (the one stone family)
GROOVE = lambda: C((0.018, 0.016, 0.014), 1.0)  # noqa: E731  (dark walls of every cut)
IRON = lambda v="a": kit.tex_mat("iron", v)  # noqa: E731
CU = lambda v="b": kit.tex_mat("copper", v)  # noqa: E731
SILV = lambda v="a": kit.tex_mat("silver", v)  # noqa: E731
LEA = lambda v="dark": kit.tex_mat("leather", v)  # noqa: E731
GOLD = lambda s=0.0: C((0.6 + s, 0.45 + s, 0.15), 0.45, metal=0.6)  # noqa: E731
BONE = lambda s=0.0: kit.mat("bone", s, rough=0.9)  # noqa: E731
COAL = lambda: C((0.012, 0.011, 0.011), 0.3)  # noqa: E731  (near-black, glossy)
EMBER = lambda: kit.glow("ember", 1.2)  # noqa: E731
WAX = lambda: C((0.55, 0.47, 0.32), 0.85)  # noqa: E731
FLAME = lambda: C((1.0, 0.7, 0.3), 0.3, glow=2.0)  # noqa: E731
CLOTH = lambda: C((0.025, 0.03, 0.055), 0.95)  # noqa: E731  (mourning blue-black)
WOOD = lambda: T("wood", "dark")  # noqa: E731


# ================= helpers =================
def foot(size, loc, tone=None, bevel=0.02):
	"""A slightly uneven, level foot stone (night_stations.stone tilts and would dip under the floor)."""
	return B((size[0] * (1 + J(0.04)), size[1] * (1 + J(0.04)), size[2]), loc, tone or S(), bevel=bevel, rot=(0, 0, J(2)))


def new_since(before):
	return [o for o in bpy.data.objects if o not in before]


def apply_mods(o):
	bpy.ops.object.select_all(action="DESELECT")
	o.select_set(True)
	bpy.context.view_layer.objects.active = o
	for m in list(o.modifiers):
		bpy.ops.object.modifier_apply(modifier=m.name)


def carve(target, cutters):
	"""Cut every cutter shape INTO the target (boolean difference). The cut walls take the cutters' dark material."""
	cutters = [c for c in cutters if c is not None]
	if not cutters:
		return target
	for c in cutters:
		apply_mods(c)
	bpy.ops.object.select_all(action="DESELECT")
	for c in cutters:
		c.select_set(True)
	bpy.context.view_layer.objects.active = cutters[0]
	if len(cutters) > 1:
		bpy.ops.object.join()
	cut = bpy.context.view_layer.objects.active
	apply_mods(target)
	m = target.modifiers.new("carve", "BOOLEAN")
	m.operation, m.object, m.solver = "DIFFERENCE", cut, "EXACT"
	m.use_self = True
	m.material_mode = "TRANSFER"
	bpy.ops.object.modifier_apply(modifier=m.name)
	bpy.data.objects.remove(cut, do_unlink=True)
	return target


def cy(pts, yf, depth=0.012):
	"""A cutter for a front face at y = yf: outline in (x, z), cuts `depth` into the stone."""
	return prism(pts, yf - 0.03, yf + depth, GROOVE())


def gline(pts, w, yf, depth=0.01):
	"""A groove along a polyline (x, z) on a front face at y = yf."""
	out = [cy(bar(a, b, w), yf, depth) for a, b in zip(pts, pts[1:])]
	out += [cy(circ(x, z, w * 0.55, n=6, wob=0), yf, depth) for x, z in pts[1:-1]]
	return out


GLYPHS = (((0, 0.5), (0.42, 0.15)), ((0, 0.5), (0.4, 0.22), (0, 0.05)), ((-0.35, 0.3), (0.35, -0.1)),
	((0, 0.15), (0.38, 0.45)), ((0, -0.1), (0.36, 0.25), (0, 0.5)), ((0, 0.4), (0.35, 0.5)))


def runes(x0, x1, z, yf, h=0.07, w=0.012, gap=0.055, depth=0.008, under=True):
	"""A row of dwarf runes cut into a front face: a stem and one or two branches each, an underline."""
	cuts = []
	n = max(1, int((x1 - x0) / gap))
	pad = (x1 - x0 - n * gap) / 2
	for i in range(n):
		x = x0 + pad + gap * (i + 0.5)
		cuts.append(cy(bar((x, z - h / 2), (x, z + h / 2), w), yf, depth))
		g = GLYPHS[rng.randint(0, len(GLYPHS) - 1)]
		pts = [(x + a * h, z + b * h) for a, b in g]
		cuts += gline(pts, w * 0.85, yf, depth)
	if under:
		cuts.append(cy(bar((x0, z - h / 2 - 0.022), (x1, z - h / 2 - 0.022), w * 0.8), yf, depth * 0.8))
	return cuts


def helm_emblem(cx, cz, s, yf, w=0.016, depth=0.012):
	"""Hald's sign, cut in: the brow-helm seen from the front (dome, rim, the heavy brow, nasal, cheek guards)."""
	cuts = gline([(cx + math.cos(a) * s, cz + math.sin(a) * s) for a in [math.pi * k / 10 for k in range(11)]], w, yf, depth)
	cuts += gline([(cx - s * 1.08, cz), (cx + s * 1.08, cz)], w * 1.2, yf, depth)
	cuts.append(cy([(cx - s * 0.95, cz - 0.02 * s), (cx, cz - 0.3 * s), (cx + s * 0.95, cz - 0.02 * s), (cx + s * 0.95, cz - 0.2 * s),
		(cx, cz - 0.48 * s), (cx - s * 0.95, cz - 0.2 * s)], yf, depth * 1.2))  # the famous iron brow
	cuts.append(cy(bar((cx, cz - 0.45 * s), (cx, cz - 0.95 * s), w * 1.3, w * 0.9), yf, depth))  # nasal
	for k in (-1, 1):
		cuts += gline([(cx + k * s * 0.98, cz - 0.15 * s), (cx + k * s * 0.9, cz - 0.85 * s), (cx + k * s * 0.6, cz - 1.0 * s)], w, yf, depth)
	cuts += gline([(cx, cz + s), (cx, cz + s * 0.3)], w * 0.8, yf, depth * 0.8)  # crest line
	return cuts


def lathe(prof, c, m, seg=16, smooth=True):
	"""A turned shape: profile [(radius, z)...] spun around the vertical axis at c (x, y, z0)."""
	x0, y0, z0 = c
	v = []
	for r, z in prof:
		for k in range(seg):
			a = 2 * math.pi * k / seg
			v.append((x0 + math.cos(a) * r, y0 + math.sin(a) * r, z0 + z))
	n = len(prof)
	f = [(i * seg + k, i * seg + (k + 1) % seg, (i + 1) * seg + (k + 1) % seg, (i + 1) * seg + k) for i in range(n - 1) for k in range(seg)]
	f += [tuple(reversed(range(seg))), tuple(range((n - 1) * seg, n * seg))]
	return mesh(v, f, m, smooth=smooth)


def group(build, at=(0, 0, 0), rot=(0, 0, 0), scale=1.0):
	"""Build parts around the origin, then scale, turn (degrees X, Y, Z) and move them to `at`."""
	before = set(bpy.data.objects[:])
	build()
	bpy.context.view_layer.update()
	from mathutils import Euler
	M = Matrix.Translation(Vector(at)) @ Euler([math.radians(a) for a in rot]).to_matrix().to_4x4() @ Matrix.Scale(scale, 4)
	new = [o for o in bpy.data.objects[:] if o not in before]
	for o in new:
		o.matrix_world = M @ o.matrix_world
	return new


def rotp(p, axis, deg, pivot):
	pv = Vector(pivot)
	return tuple(Matrix.Rotation(math.radians(deg), 3, axis) @ (Vector(p) - pv) + pv)


def plinth(w, d, h, z0=0.0, y=0.0):
	"""A stepped cut-stone base: wide foot, body, a thinner moulded top. Returns (body, top z)."""
	foot((w + 0.1, d + 0.1, 0.08), (0, y, z0 + 0.04), tone=S("c"), bevel=0.02)
	body = B((w, d, h - 0.13), (0, y, z0 + 0.075 + (h - 0.13) / 2), S("b"), bevel=0.02)
	B((w + 0.06, d + 0.06, 0.06), (0, y, z0 + h - 0.035), S("a"), bevel=0.015)
	return body, z0 + h - 0.005


def frame_band(w, h, yf, x=0.0, z0=0.0, t=0.07, m=None):
	"""A moulded stone frame (4 bars) pressed 5 mm into a front face at y = yf."""
	m = m or S("a")
	for zz in (z0 + t / 2, z0 + h - t / 2):
		B((w, 0.045, t), (x, yf - 0.018, zz), m, bevel=0.012)
	for s_ in (-1, 1):
		B((t, 0.04, h - 2 * t + 0.01), (x + s_ * (w / 2 - t / 2), yf - 0.016, z0 + h / 2), m, bevel=0.012)


def helm(c, s=1.0, mi=None, mt=None, ms=None):
	"""Hald's brow-helm, dome centre c at the rim height, facing -Y. mi = shell, mt = trim, ms = rivets."""
	mi, mt = mi or IRON("dark"), mt or CU("b")
	ms = ms or CU("dark")
	x, y, z = c
	r = 0.2 * s
	sphere((x, y, z), r, mi, scale=(1, 1.05, 0.95), seg=24, rings=12, cut=0.0)
	kit.ring(r * 1.0, 0.018 * s, (x, y, z + 0.012 * s), mt, seg=22).scale = (1, 1.05, 1)
	for k in range(12):
		a = math.pi * 2 * k / 12
		kit.rivet((x + math.cos(a) * r * 1.07, y + math.sin(a) * r * 1.12, z + 0.014 * s), ms, r=0.011 * s)
	# the heavy iron brow: two thick arches over the eyes meeting in a peak above the nose
	for k in (-1, 1):
		pts = []
		for i in range(6):
			t = i / 5
			a = -math.pi / 2 + k * (0.05 + t * 0.95)
			pts.append((x + math.cos(a) * r * 1.03, y + math.sin(a) * r * 1.08, z + s * (0.035 + 0.035 * math.sin(t * math.pi) - 0.03 * t)))
		tube(pts, 0.03 * s, 0.018 * s, mi, seg=7)
	kit.cone(0.026 * s, 0.012 * s, 0.05 * s, (x, y - r * 1.07, z + 0.06 * s), mi, verts=6)  # the peak
	B((0.036 * s, 0.028 * s, 0.15 * s), (x, y - r * 1.06, z - 0.05 * s), mi, bevel=0.006 * s)  # nasal
	for k in (-1, 1):  # cheek guards
		B((0.03 * s, 0.13 * s, 0.14 * s), (x + k * r * 0.9, y - 0.06 * s, z - 0.065 * s), mi, bevel=0.01 * s, rot=(0, -k * 6, -k * 18))
		kit.rivet((x + k * r * 0.99, y - 0.1 * s, z - 0.05 * s), ms, r=0.011 * s)
	tube([(x, y - r * 0.95, z + 0.06 * s), (x, y - r * 0.6, z + r * 0.8), (x, y, z + r * 0.97), (x, y + r * 0.6, z + r * 0.8), (x, y + r * 0.98, z + 0.05 * s)],
		0.016 * s, 0.016 * s, mt, seg=6)  # crest strap


def hammer(L=0.9, s=1.0, mh=None, mono=None):
	"""Hald's war hammer along +Z from the origin (butt) to the head; head across X. mono = all one stone."""
	mh = mono or mh or IRON("dark")
	wd, le, br, bd = (mono,) * 4 if mono else (WOOD(), LEA(), CU("b"), CU("dark"))
	log((0, 0, 0.02), (0, 0, L), 0.025 * s, wd, seg=8, rings=3, bend=0.01, ends=False)
	kit.cylinder(0.032 * s, 0.04 * s, (0, 0, 0.02), mh, verts=8)  # pommel
	for k in range(5):  # leather grip wraps
		kit.ring(0.026 * s, 0.007 * s, (0, 0, 0.08 + k * 0.03), le, seg=10)
	hz = L + 0.045 * s
	B((0.26 * s, 0.09 * s, 0.1 * s), (0, 0, hz), mh, bevel=0.012 * s)
	for k in (-1, 1):
		kit.cylinder(0.058 * s, 0.035 * s, (k * 0.14 * s, 0, hz), mh, rot=(0, 90, 0), verts=10, bevel=0.006)
		kit.ring(0.057 * s, 0.008 * s, (k * 0.125 * s, 0, hz), br, rot=(0, 90, 0), seg=12)
	B((0.05 * s, 0.1 * s, 0.112 * s), (0, 0, hz), br, bevel=0.006)  # bronze collar
	for k in (-1, 1):
		kit.rivet((k * 0.035 * s, -0.056 * s, hz), bd, r=0.01 * s)
	kit.cone(0.03 * s, 0.004, 0.08 * s, (0, 0, hz + 0.09 * s), mh, verts=6)  # top spike
	for k in (-1, 1):  # langets down the haft
		B((0.012 * s, 0.07 * s, 0.16 * s), (0, 0, L - 0.07 * s), mh, bevel=0.003, rot=(0, 0, 90 * (k > 0)))


def rough_chips(pts, m_tone="c", flat=True):
	"""Small angular stone chips lying on the floor (each rests on z = 0)."""
	for k, (x, y, sz) in enumerate(pts):
		o = kit.gem((x, y, 0), (sz * 1.3, sz, sz * 0.6), S(m_tone if k % 2 else "b"), seed=k + 3)
		o.location.z = -min(v.co.z for v in o.data.vertices) - 0.002


def coal_heap(cx, cy_, z, r, n, hot=4, seed=0):
	"""Near-black glossy angular coal lumps, a few glowing, settled overlapping on a surface at z."""
	for k in range(n):
		a, d = rng.uniform(0, 6.28), r * math.sqrt(rng.random())
		sz = rng.uniform(0.025, 0.05)
		h = (1 - d / r) * r * 0.25
		kit.gem((cx + math.cos(a) * d, cy_ + math.sin(a) * d, z + h + sz * 0.3), (sz * 1.2, sz, sz * 0.75), EMBER() if k < hot else COAL(), seed=seed + k)


def goblet(x, y, z, s=1.0, m=None):
	m = m or SILV("a")
	lathe([(0.03 * s, 0), (0.032 * s, 0.006 * s), (0.01 * s, 0.015 * s), (0.008 * s, 0.05 * s), (0.014 * s, 0.06 * s),
		(0.035 * s, 0.075 * s), (0.04 * s, 0.11 * s), (0.034 * s, 0.112 * s), (0.03 * s, 0.08 * s)], (x, y, z), m, seg=12)
	kit.ring(0.039 * s, 0.004 * s, (x, y, z + 0.1 * s), GOLD(), seg=12)


def candle(x, y, z, r, h, lit=True):
	kit.cylinder(r * 1.6, 0.01, (x, y, z + 0.004), WAX(), verts=10, bevel=0.003)
	kit.cylinder(r, h, (x, y, z + h / 2 + 0.005), WAX(), verts=10, bevel=0.006)
	sphere((x + r * 0.9, y - r * 0.2, z + h * 0.7), r * 0.35, WAX(), scale=(0.8, 0.8, 2.2), seg=8, rings=5)
	B((0.005, 0.005, 0.022), (x, y, z + h + 0.012), kit.mat("charcoal"), bevel=0)
	if lit:
		kit.flame((x, y, z + h + 0.018), 0.014, 0.05, FLAME(), twist=h * 30)


def pry_bar(p0, p1, r=0.012):
	"""An iron pry bar from p0 (the flat claw end) to p1 (the hooked end)."""
	a, b = Vector(p0), Vector(p1)
	rod(p0, p1, r, IRON("dark"), seg=6)
	d = (b - a).normalized()
	B((r * 4, r * 1.2, r * 2), tuple(a - d * r), IRON("dark"), bevel=0.003)
	tube([tuple(b - d * 0.01), tuple(b + d * 0.04 + Vector((0, 0, 0.03))), tuple(b + d * 0.03 + Vector((0, 0, 0.07)))], r, r * 0.6, IRON("dark"), seg=6)


def round_shield(c, r, split=False):
	"""A round wooden shield facing -Y: planks, iron rim, bronze boss, rivets."""
	x, y, z = c
	n = 5
	for i in range(n):
		if split and i == 3:
			continue
		R = r - 0.008  # plank ends sit in the middle of the iron rim tube
		x0, x1 = -R + 2 * R * i / n + 0.003, -R + 2 * R * (i + 1) / n - 0.003
		xs = [x0 + (x1 - x0) * t / 4 for t in range(5)]
		hz = lambda xx: math.sqrt(max(0.0, R * R - xx * xx))  # noqa: E731  (plank ends follow the round rim)
		pts = [(x + xx, z - hz(xx)) for xx in xs] + [(x + xx, z + hz(xx)) for xx in reversed(xs)]
		prism(pts, y - 0.0175, y + 0.0175, T("wood", ("dark", "c", "dark", "c", "dark")[i]))
	kit.ring(r - 0.008, 0.016, (x, y, z), IRON("dark"), rot=(90, 0, 0), seg=26)
	sphere((x, y - 0.012, z), r * 0.22, CU("b"), scale=(1, 0.7, 1), seg=12, rings=7)
	kit.ring(r * 0.23, 0.01, (x, y - 0.016, z), CU("dark"), rot=(90, 0, 0), seg=14)
	for k in range(10):
		a = 2 * math.pi * k / 10
		rx = math.cos(a) * r * 0.75
		if split and r * 0.2 - 0.01 < rx < r * 0.6 + 0.01:
			continue
		kit.rivet((x + rx, y - 0.016, z + math.sin(a) * r * 0.75), CU("dark"), r=0.011)
	B((r * 1.7, 0.016, 0.05), (x, y + 0.022, z + r * 0.35), IRON("a"), bevel=0.003)  # back strap


def niche_block(w=0.95, h=1.25, d=0.42, nw=0.56, nh=0.62, nz=0.36, nd=0.28, sill=True):
	"""A cut-stone wall block (flat back at y = +d/2... back at y = 0.21) with an arched niche cut into its front."""
	body = B((w, d, h - 0.1), (0, 0, 0.1 + (h - 0.1) / 2), S("b"), bevel=0.02)
	foot((w + 0.08, d + 0.06, 0.1), (0, -0.03, 0.05), tone=S("c"), bevel=0.02)
	yf = -d / 2
	arch = [(-nw / 2, nz), (nw / 2, nz)] + [(math.cos(a) * nw / 2, nz + nh - nw / 2 + math.sin(a) * nw / 2) for a in [math.pi * k / 12 for k in range(13)]]
	cuts = [prism(arch, yf - 0.03, yf + nd, GROOVE())]
	cuts += runes(-w / 2 + 0.12, w / 2 - 0.12, nz + nh + 0.13, yf, h=0.06, gap=0.05)
	carve(body, cuts)
	# moulded surround: sill, two jambs, a keystone, a cornice
	if sill:
		B((nw + 0.14, 0.06, 0.06), (0, yf - 0.02, nz - 0.03), S("a"), bevel=0.012)
	for s_ in (-1, 1):
		B((0.06, 0.04, nh - nw / 2), (s_ * (nw / 2 + 0.04), yf - 0.015, nz + (nh - nw / 2) / 2), S("a"), bevel=0.01)
	prism([(-0.05, nz + nh - 0.02), (0.05, nz + nh - 0.02), (0.065, nz + nh + 0.07), (-0.065, nz + nh + 0.07)], yf + 0.005, yf - 0.035, S("a"))
	B((w + 0.06, d + 0.04, 0.07), (0, -0.01, h + 0.03), S("a"), bevel=0.015)
	return yf, nz, nd, body


def panel_wall(w=1.6, h=1.3, d=0.16):
	"""A carved panel standing on a foot stone, flat back at y = +d/2. Returns (panel object, front y)."""
	foot((w + 0.12, d + 0.14, 0.1), (0, -0.04, 0.05), tone=S("c"), bevel=0.02)
	p = B((w, d, h), (0, 0, 0.095 + h / 2), S("b"), bevel=0.015)
	B((w + 0.08, d + 0.05, 0.08), (0, -0.015, 0.095 + h + 0.035), S("a"), bevel=0.015)  # cornice
	return p, -d / 2


def flat_back(back):
	"""Cut every vertex flat at the wall: y <= back."""
	for o in bpy.data.objects:
		if o.type != "MESH":
			continue
		mw = o.matrix_world.copy()
		inv = mw.inverted()
		for v in o.data.vertices:
			w = mw @ v.co
			if w.y > back:
				w.y = back
				v.co = inv @ w


def flat_hammer(cx, cz, ang, L, y0, y1, m):
	"""A flat hammer shape (cloth appliqué or a sunk carving outline), centred at (cx, cz), turned `ang` degrees."""
	ca, sa = math.cos(math.radians(ang)), math.sin(math.radians(ang))
	r = lambda x, z: (cx + x * ca - z * sa, cz + x * sa + z * ca)  # noqa: E731
	prism([r(-0.012, -L / 2), r(0.012, -L / 2), r(0.012, L / 2 - 0.03), r(-0.012, L / 2 - 0.03)], y0, y1, m)
	prism([r(-0.08, L / 2 - 0.05), r(0.08, L / 2 - 0.05), r(0.08, L / 2 + 0.03), r(-0.08, L / 2 + 0.03)], y0 + 0.003, y1 - 0.003, m)


def bounds(group):
	vs = [o.matrix_world @ v.co for o in group if o.type == "MESH" for v in o.data.vertices]
	return Vector((min(v.x for v in vs), min(v.y for v in vs), min(v.z for v in vs))), Vector((max(v.x for v in vs), max(v.y for v in vs), max(v.z for v in vs)))


def ring_at(p, d, r, minor, m, seg=14):
	"""A band (torus) at point p, its hole pointing along direction d."""
	o = kit.ring(r, minor, tuple(p), m, seg=seg)
	o.rotation_mode = "QUATERNION"
	o.rotation_quaternion = Vector(d).normalized().to_track_quat("Z", "Y")
	return o


def face(m, z, y=-0.01, r=0.135, eyes_shut=False):
	"""A stone dwarf head: skull, nose, eyes under the brow, moustache."""
	sphere((0, y, z), r, m, scale=(1, 0.95, 1.0), seg=12, rings=8)
	sphere((0, y - r * 1.0, z - 0.02), 0.032, m, scale=(1, 1, 1.35), seg=8, rings=5)  # nose
	for s_ in (-1, 1):
		if eyes_shut:
			B((0.04, 0.012, 0.01), (s_ * 0.05, y - r * 0.9, z + 0.005), GROOVE(), bevel=0.002)
		else:
			sphere((s_ * 0.05, y - r * 0.9, z + 0.005), 0.017, GROOVE(), seg=6, rings=4)
		tube([(0, y - r * 1.02, z - 0.05), (s_ * 0.05, y - r * 0.98, z - 0.055), (s_ * 0.09, y - r * 0.85, z - 0.09)], 0.018, 0.008, m, seg=6)  # moustache


def beard(m, z_chin, z_end, y0=-0.08, y1=-0.2, w=0.12):
	"""A big carved beard wedge with grooves cut in and two braids with rings."""
	o = prism([(-w, z_chin), (w, z_chin), (w * 0.9, (z_chin + z_end) / 2), (w * 0.4, z_end + 0.03), (0, z_end), (-w * 0.4, z_end + 0.03),
		(-w * 0.9, (z_chin + z_end) / 2)], y0, y1, m)
	cuts = []
	for x in (-0.07, -0.025, 0.025, 0.07):
		cuts += gline([(x * w / 0.12, z_chin - 0.02), (x * w / 0.12 * 0.85 + J(0.01), (z_chin + z_end) / 2), (x * w / 0.12 * 0.4, z_end + 0.04)], 0.01, y1, 0.008)
	carve(o, cuts)
	for s_ in (-1, 1):
		tube([(s_ * w * 0.85, y1 + 0.03, (z_chin + z_end) / 2 + 0.02), (s_ * w * 0.8, y1 + 0.02, z_end + 0.02), (s_ * w * 0.75, y1 + 0.02, z_end - 0.08)], 0.022, 0.016, m, seg=7)
		kit.ring(0.02, 0.008, (s_ * w * 0.75, y1 + 0.02, z_end - 0.06), m, seg=10)
		kit.cone(0.016, 0.004, 0.04, (s_ * w * 0.75, y1 + 0.02, z_end - 0.1), m, verts=6)


DWARF_DIR = GAME / "assets" / "characters" / "dwarf"
ARMOUR = ("armor_hide.glb", ("fleece",))  # the game's armour on the same skeleton (fur left out)


def real_dwarf(pose=(), m=None, ratio=0.25, files=(("dwarf_body.glb", ("eye",)),), min_verts=3000):
	"""The game's own dwarf (owner round 2: no box figures), posed and repainted as a carved statue.
	pose = [(bone, axis 'X'/'Y'/'Z', degrees), ...]: each bone turns about a world axis through its own joint, in order.
	files = [(glb in assets/characters/dwarf, words of parts to leave out)]: every file shares the skeleton and pose
	(add ARMOUR to dress him). Feet on z = 0, faces -Y, ~1.24 m tall. m = a material or a function part-name -> material.
	Returns (meshes, joints): joints[bone] = (head, tail) after posing, in the same space."""
	meshes, joints = [], {}
	for fname, drop in files:
		before = set(bpy.data.objects[:])
		bpy.ops.import_scene.gltf(filepath=str(DWARF_DIR / fname))
		bpy.context.view_layer.update()
		new = [o for o in bpy.data.objects if o not in before]
		arm = next(o for o in new if o.type == "ARMATURE")
		for b, ax, deg in pose:
			pb = arm.pose.bones[b]
			h = pb.head.copy()
			pb.matrix = Matrix.Translation(h) @ Matrix.Rotation(math.radians(deg), 4, ax) @ Matrix.Translation(-h) @ pb.matrix
			bpy.context.view_layer.update()
		joints = {pb.name: (arm.matrix_world @ pb.head, arm.matrix_world @ pb.tail) for pb in arm.pose.bones}
		keep = [o for o in new if o.type == "MESH" and "icosphere" not in o.name.lower() and not any(d in o.name for d in drop)]
		for o in keep:
			bpy.ops.object.select_all(action="DESELECT")
			o.select_set(True)
			bpy.context.view_layer.objects.active = o
			for md in list(o.modifiers):
				bpy.ops.object.modifier_apply(modifier=md.name)
			mw = o.matrix_world.copy()
			o.parent = None
			o.matrix_world = mw
			o.vertex_groups.clear()
			for a in list(o.data.color_attributes):  # unused vertex colours: half the file size (Nov 21 slim-down)
				o.data.color_attributes.remove(a)
			if ratio < 1 and len(o.data.vertices) > min_verts:  # the game mesh is far too fine for a decor prop
				d = o.modifiers.new("dec", "DECIMATE")
				d.ratio = ratio * (1.4 if "head" in o.name else 1.0)
				bpy.ops.object.modifier_apply(modifier=d.name)
		for o in new:
			if o not in keep:
				bpy.data.objects.remove(o, do_unlink=True)
		meshes += keep
	for o in meshes:
		mat = m(o.name) if callable(m) else (m or S("b"))
		o.data.materials.clear()
		o.data.materials.append(mat)
		if "tile" in mat:
			kit._uv_box(o, mat["tile"])
	return meshes, joints


def curl(side, deg=60, axis="Z"):
	"""Close a hand into a fist (finger joints turn in order, knuckle first)."""
	k = -1 if side == "l" else 1
	return [(f"{f}_{n:02d}_{side}", axis, k * deg) for f in ("index", "middle", "ring", "pinky") for n in (1, 2, 3)] + [(f"thumb_02_{side}", axis, k * 35)]


def palm(j, side):
	"""The middle of a (closed) hand: where a grip goes."""
	return (j[f"hand_{side}"][0] + j[f"middle_01_{side}"][0]) / 2


STONE_DWARF = lambda n: S("a") if "brass" in n or "rings" in n else S("b")  # noqa: E731  (metal bits a lighter stone)
HEADLESS = ("dwarf_body.glb", ("eye", "body_head", "foot", "shirt"))  # under the armour: its own helmet head, boots, coat


def guard_figure(spear="whole"):
	"""A stone honour guard: the game's dwarf in his armour, spear upright in the right fist, round shield on the left arm."""
	m, ma = S("b"), S("a")
	_, j = real_dwarf([("upperarm_r", "Y", -74), ("lowerarm_r", "X", -82), ("upperarm_l", "Y", 70), ("lowerarm_l", "X", -78)] + curl("r") + curl("l"),
		m=STONE_DWARF, files=(HEADLESS, ARMOUR), ratio=0.12, min_verts=1200)  # ratio/min_verts: files under 2 MB
	g = palm(j, "r")
	x, y = g.x, g.y
	if spear == "whole":
		log((x, y, 0.0), (x, y, 1.62), 0.022, ma, seg=8, rings=3, bend=0.0, ends=False)
		kit.cone(0.038, 0.024, 0.08, (x, y, 1.64), ma, verts=8)
		kit.ring(0.03, 0.008, (x, y, 1.6), m, seg=10)
		blade = prism([(x, 1.66), (x + 0.06, 1.74), (x + 0.045, 1.86), (x, 1.96), (x - 0.045, 1.86), (x - 0.06, 1.74)], y - 0.014, y + 0.014, ma)
		carve(blade, gline([(x, 1.7), (x, 1.9)], 0.01, y - 0.014, 0.005))
	else:
		log((x, y, 0.0), (x, y, 0.95), 0.022, ma, seg=8, rings=3, bend=0.0, ends=False)
		kit.gem((x, y, 0.965), (0.024, 0.024, 0.04), ma, seed=5)  # jagged break
	kit.cylinder(0.04, 0.03, (x, y, 0.015), m, verts=8)  # butt cap on the plinth
	for k in (-1, 1):  # grip wraps just above and below the fist
		kit.ring(0.026, 0.007, (x, y, g.z + k * 0.07), m, seg=10)
	# round shield strapped to the left forearm, Hald's helm cut into it
	c = (j["lowerarm_l"][0] + j["hand_l"][0]) / 2
	sx, sy, sz = c.x + 0.03, c.y - 0.12, c.z - 0.02
	sh = kit.cylinder(0.27, 0.045, (sx, sy, sz), m, rot=(90, 0, 0), verts=28, bevel=0.008)
	carve(sh, helm_emblem(sx, sz + 0.03, 0.09, sy - 0.0225, w=0.012, depth=0.008))
	kit.ring(0.265, 0.016, (sx, sy - 0.02, sz), ma, rot=(90, 0, 0), seg=28)
	for k in range(8):
		a = 2 * math.pi * k / 8 + 0.2
		kit.rivet((sx + math.cos(a) * 0.22, sy - 0.022, sz + math.sin(a) * 0.22), ma, r=0.012)
	B((0.06, 0.12, 0.05), (sx - 0.02, (sy + c.y) / 2 + 0.01, sz + 0.02), ma, bevel=0.01)  # the arm strap block joins shield to arm


# ================= models =================
def th_hald_tomb():
	L, W, H = 2.1, 1.0, 0.62
	foot((L + 0.3, W + 0.3, 0.1), (0, 0, 0.05), tone=S("c"), bevel=0.02)
	B((L + 0.16, W + 0.16, 0.1), (0, 0, 0.145), S("a"), bevel=0.02)
	z0 = 0.19
	body = B((L, W, H), (0, 0, z0 + H / 2), S("b"), bevel=0.02)
	yf = -W / 2
	cuts = []
	for i, x in enumerate((-0.68, 0.0, 0.68)):
		pw, ph, pz = 0.5, 0.42, z0 + 0.09
		cuts += gline([(x - pw / 2, pz), (x + pw / 2, pz), (x + pw / 2, pz + ph), (x - pw / 2, pz + ph), (x - pw / 2, pz)], 0.018, yf)
		if i == 1:
			cuts += helm_emblem(x, pz + 0.24, 0.13, yf)
		else:
			for r in range(3):
				cuts += runes(x - 0.2, x + 0.2, pz + 0.33 - r * 0.11, yf, h=0.06, gap=0.05, under=False)
	carve(body, cuts)
	for sy in (-1, 1):
		for x in (-L / 2 + 0.06, -0.34, 0.34, L / 2 - 0.06):
			B((0.09, 0.05, H - 0.04), (x, sy * (W / 2 + 0.015), z0 + H / 2), S("a"), bevel=0.01)
			for zz in (z0 + 0.05, z0 + H - 0.05):
				B((0.13, 0.07, 0.06), (x, sy * (W / 2 + 0.022), zz), S("c"), bevel=0.01)
	zt = z0 + H
	lid = B((L + 0.12, W + 0.12, 0.09), (0, 0, zt + 0.04), S("a"), bevel=0.015)
	carve(lid, runes(-L / 2 + 0.1, L / 2 - 0.1, zt + 0.042, -(W + 0.12) / 2, h=0.045, w=0.01, gap=0.045, under=False))
	slab = B((L - 0.04, W - 0.1, 0.07), (0, 0, zt + 0.11), S("c"), bevel=0.02)
	for sx in (-1, 1):
		for sy in (-1, 1):
			B((0.12, 0.12, 0.022), (sx * (L / 2 + 0.02), sy * (W / 2 + 0.02), zt + 0.088), CU("b"), bevel=0.004)
			kit.rivet((sx * (L / 2 + 0.02), sy * (W / 2 + 0.02), zt + 0.1), CU("dark"), r=0.014)
	ztop = zt + 0.145
	# round 3 (owner: "remove the dwarf from the top"): no effigy, the lid slab is carved instead. The cuts are drawn
	# as on a front face (x, "z" = lid y), then turned to face up and dropped onto the lid top.
	cuts = []
	for ix, iy, w in ((0.96, 0.37, 0.022), (0.9, 0.31, 0.012)):  # double border
		cuts += gline([(-ix, -iy), (ix, -iy), (ix, iy), (-ix, iy), (-ix, -iy)], w, 0.0)
	cuts += helm_emblem(0, 0.04, 0.14, 0.0)  # Hald's helm sign in the middle
	cuts += gline([(math.cos(a) * 0.22, 0.04 + math.sin(a) * 0.22) for a in [2 * math.pi * k / 16 for k in range(17)]], 0.014, 0.0)
	for sx in (-1, 1):
		x0, x1 = (0.34, 0.84) if sx > 0 else (-0.84, -0.34)
		for yy in (0.1, -0.1):  # two rune rows each side
			cuts += runes(x0, x1, yy, 0.0, h=0.07, gap=0.06, under=False)
		for cy_ in (-0.23, 0.23):  # diamond knots near the corners
			x0 = sx * 0.78
			cuts += gline([(x0, cy_ - 0.05), (x0 + 0.05, cy_), (x0, cy_ + 0.05), (x0 - 0.05, cy_), (x0, cy_ - 0.05)], 0.012, 0.0)
	turn(cuts, "X", -90, (0, 0, 0))
	shift(cuts, (0, 0, ztop))
	carve(slab, cuts)


def th_brow_helm_plinth():
	body, top = plinth(0.6, 0.55, 1.0)
	yf = -0.275
	carve(body, helm_emblem(0, 0.66, 0.12, yf) + runes(-0.22, 0.22, 0.36, yf, h=0.06, gap=0.05) + runes(-0.22, 0.22, 0.2, yf, h=0.06, gap=0.05, under=False))
	for sx in (-1, 1):
		for sy in (-1, 1):
			lathe([(0.035, 0), (0.04, 0.02), (0.022, 0.04), (0.03, 0.07), (0.012, 0.1), (0.003, 0.115)], (sx * 0.28, sy * 0.255, top - 0.004), CU("b"), seg=10)
	lathe([(0.12, 0), (0.12, 0.03), (0.06, 0.06), (0.045, 0.18), (0.07, 0.23), (0.085, 0.27), (0.06, 0.29)], (0, 0, top - 0.005), S("a"), seg=14)
	kit.ring(0.05, 0.01, (0, 0, top + 0.12), CU("b"), seg=12)
	helm((0, 0, top + 0.25), s=1.0)


def th_armour_stand():
	"""Hald's armour (the game's own dwarf armour, repainted iron and bronze) hung on an iron stand at dwarf height:
	the coat wraps all the way round, helmet on the post's knob, boots standing on the base."""
	foot((0.8, 0.6, 0.1), (0, 0, 0.05), tone=S("c"), bevel=0.02)
	B((0.66, 0.48, 0.08), (0, 0, 0.135), S("a"), bevel=0.015)
	z0 = 0.17
	paint = lambda n: CU("b") if "brass" in n else (IRON("dark") if "cord" in n else IRON("a"))  # noqa: E731
	ms, j = real_dwarf([("upperarm_r", "Y", -72), ("upperarm_l", "Y", 72), ("lowerarm_r", "X", -12), ("lowerarm_l", "X", -12)],
		m=paint, files=(("armor_hide.glb", ("fleece", "armor_head_hair")),))
	shift(ms, (0, 0, z0 - 0.005))
	hx, hy = j["Head"][0].x, j["Head"][0].y
	kz = j["Head"][0].z + z0 + 0.14  # inside the helmet
	log((hx, hy, z0 - 0.01), (hx, hy, kz), 0.03, IRON("dark"), seg=8, rings=2, bend=0, ends=False)  # the post
	hb = [o for o in ms if "head" in o.name]
	lo, hi = bounds(hb)
	hc = (lo + hi) / 2
	sphere((hc.x, hc.y, lo.z + 0.07), 0.15, WOOD(), scale=(1, 1.05, 0.75), seg=16, rings=9)  # a wooden head form filling the helmet
	kz = lo.z - 0.02
	lathe([(0.11, 0), (0.1, 0.04), (0.085, 0.07), (0.075, 0.09)], (hx, hy, kz - 0.06), IRON("b"), seg=16)  # gorget between coat and helmet
	sh = j["upperarm_l"][0].z + z0 - 0.02
	log((-0.27, hy, sh), (0.27, hy, sh), 0.025, IRON("dark"), seg=8, rings=1, bend=0, ends=False)  # shoulder bar inside the coat
	for s_ in (-1, 1):
		sphere((s_ * 0.27, hy, sh), 0.032, IRON("dark"), seg=8, rings=5)
	wz = 0.57  # an iron hoop holds the coat's hem out round the post
	kit.ring(0.2, 0.012, (0, -0.01, wz), IRON("dark"), seg=24).scale = (1, 0.85, 1)
	for ang in (0, 90):
		r = 0.2 if ang == 0 else 0.17
		log((-r * (ang == 0), -0.01 - r * (ang == 90), wz), (r * (ang == 0), -0.01 + r * (ang == 90), wz), 0.01, IRON("dark"), seg=6, rings=1, bend=0, ends=False)
	lathe([(0.1, 0), (0.1, 0.03), (0.06, 0.05), (0.04, 0.07)], (hx, hy, z0 - 0.012), IRON("dark"), seg=12)  # foot of the post
	for k in range(4):
		a = math.pi / 4 + k * math.pi / 2
		kit.rivet((hx + math.cos(a) * 0.08, hy + math.sin(a) * 0.08, z0 + 0.03), CU("dark"), r=0.012)


def th_hammer_rest():
	foot((1.25, 0.62, 0.1), (0, 0, 0.05), tone=S("c"), bevel=0.02)
	body = B((1.1, 0.5, 0.48), (0, 0, 0.335), S("b"), bevel=0.02)
	yf = -0.25
	cuts = runes(-0.45, 0.45, 0.47, yf, h=0.06, gap=0.05)
	cuts += gline([(-0.5, 0.13), (0.5, 0.13), (0.5, 0.39), (-0.5, 0.39), (-0.5, 0.13)], 0.016, yf)  # panel border
	cuts += gline([(-0.12, 0.26), (0.3, 0.26)], 0.02, yf)  # the hammer cut in, lying
	cuts.append(cy([(0.29, 0.19), (0.37, 0.19), (0.37, 0.33), (0.29, 0.33)], yf, 0.014))
	carve(body, cuts)
	top = 0.575
	B((1.16, 0.56, 0.05), (0, 0, top - 0.01), S("a"), bevel=0.012)
	top += 0.015
	pl = B((0.26, 0.012, 0.09), (-0.33, yf - 0.003, 0.26), CU("b"), bevel=0.004)
	carve(pl, runes(-0.43, -0.23, 0.26, yf - 0.009, h=0.04, w=0.008, gap=0.035, depth=0.004, under=False))
	for x in (-0.445, -0.215):
		kit.rivet((x, yf - 0.01, 0.26), CU("dark"), r=0.009)
	zc = top + 0.07
	for x in (-0.3, 0.25):
		cr = B((0.1, 0.2, 0.1), (x, 0, top + 0.045), S("a"), bevel=0.01)
		carve(cr, [prism(circ(0, zc - 0.004, 0.031, n=14, wob=0), x - 0.08, x + 0.08, GROOVE(), axis="x")])
	group(lambda: hammer(0.95), at=(-0.5, 0, zc), rot=(90, 0, 90))


def th_drinking_horn():
	body, top = plinth(0.46, 0.42, 0.95)
	yf = -0.21
	carve(body, runes(-0.16, 0.16, 0.7, yf, h=0.06, gap=0.05) + runes(-0.16, 0.16, 0.55, yf, h=0.06, gap=0.05, under=False)
		+ gline([(-0.12, 0.35), (-0.05, 0.26), (0.05, 0.26), (0.13, 0.36)], 0.02, yf))
	kit.cylinder(0.15, 0.02, (-0.04, 0.0, top + 0.006), CU("b"), verts=16, bevel=0.004)
	HORN = C((0.1, 0.06, 0.03), 0.45)
	pts = [Vector((-0.2, 0, top + 0.34)), Vector((-0.17, 0, top + 0.22)), Vector((-0.08, 0, top + 0.13)), Vector((0.05, 0, top + 0.12)),
		Vector((0.15, 0, top + 0.17)), Vector((0.2, 0, top + 0.25))]
	tube([tuple(p) for p in pts], 0.06, 0.012, HORN, seg=12)
	n = len(pts)
	for i in (0, 2, 4):
		d = pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]
		r = 0.06 + (0.012 - 0.06) * i / (n - 1)
		ring_at(pts[i], d, r * 1.02, 0.009, SILV("a"))
	ring_at(pts[0], pts[1] - pts[0], 0.06, 0.012, SILV("b"))
	kit.cone(0.015, 0.004, 0.04, tuple(pts[-1] + Vector((0.01, 0, 0.02))), SILV("a"), verts=8, rot=(0, 25, 0))
	for i in (1, 3):  # bronze holder: a ring around the horn on a post
		p = pts[i]
		r = 0.06 + (0.012 - 0.06) * i / (n - 1)
		ring_at(p, pts[i + 1] - pts[i - 1], r + 0.008, 0.01, CU("b"))
		log((p.x, 0, top + 0.01), (p.x, 0, p.z - r - 0.01), 0.012, CU("b"), seg=6, rings=1, ends=False, bend=0)
	goblet(0.13, -0.08, top + 0.004, s=0.9)


def th_honour_guard():
	body, top = plinth(1.3, 0.8, 0.5)
	carve(body, runes(-0.5, 0.5, 0.27, -0.4, h=0.07, gap=0.06))
	group(guard_figure, at=(0, 0.02, top - 0.01), scale=1.15)


def th_guard_snapped():
	body, top = plinth(1.3, 0.8, 0.5)
	carve(body, runes(-0.5, 0.5, 0.27, -0.4, h=0.07, gap=0.06) + gline([(0.3, 0.42), (0.36, 0.33), (0.33, 0.24), (0.4, 0.14)], 0.014, -0.4, 0.012))
	group(lambda: guard_figure("snapped"), at=(0, 0.02, top - 0.01), scale=1.15)
	# the top of the spear fell and lies on the floor in front, its head still on
	m = S("a")
	y0 = -0.7
	log((-0.55, y0, 0.032), (0.4, y0 + 0.08, 0.032), 0.032, m, seg=8, rings=3, bend=0.0, ends=False)
	kit.gem((0.42, y0 + 0.082, 0.034), (0.034, 0.034, 0.03), m, seed=8)
	kit.cone(0.05, 0.035, 0.1, (-0.6, y0 - 0.004, 0.052), m, rot=(0, -90, 4), verts=8)
	head = prism([(-0.65, -0.04), (-0.74, 0.04), (-0.88, 0.03), (-0.98, 0.0), (-0.88, -0.03), (-0.74, -0.04)], 0.0, 0.03, m, axis="z")
	shift([head], (0, y0 + 0.004, 0.025))
	rough_chips([(0.62, -0.62, 0.05), (0.75, -0.5, 0.035), (0.5, -0.85, 0.03), (0.2, -0.95, 0.025), (0.88, -0.75, 0.03)])


def th_brazier_grand():
	body, top = plinth(0.55, 0.55, 0.72)
	carve(body, helm_emblem(0, 0.45, 0.1, -0.275) + runes(-0.2, 0.2, 0.2, -0.275, h=0.055, gap=0.05, under=False))
	bz = top + 0.08
	lathe([(0.1, 0), (0.22, 0.05), (0.33, 0.13), (0.37, 0.21), (0.395, 0.235), (0.35, 0.245), (0.32, 0.17)], (0, 0, bz), CU("b"), seg=22)
	kit.ring(0.375, 0.014, (0, 0, bz + 0.2), CU("dark"), seg=24)
	for k in range(4):
		a = math.pi / 4 + k * math.pi / 2
		ca, sa = math.cos(a), math.sin(a)
		tube([(ca * 0.22, sa * 0.22, top - 0.01), (ca * 0.27, sa * 0.27, top + 0.04), (ca * 0.27, sa * 0.27, bz + 0.07), (ca * 0.3, sa * 0.3, bz + 0.12)], 0.028, 0.02, CU("dark"), seg=7)
		for f in (-1, 0, 1):  # claw toes on the plinth
			kit.cone(0.014, 0.005, 0.06, (ca * 0.22 + math.cos(a + f * 0.6) * 0.03, sa * 0.22 + math.sin(a + f * 0.6) * 0.03, top + 0.005), CU("dark"), rot=(0, 90, math.degrees(a + f * 0.6)), verts=6)
	for k in range(12):
		a = 2 * math.pi * k / 12
		kit.rivet((math.cos(a) * 0.36, math.sin(a) * 0.36, bz + 0.17), CU("dark"), r=0.012)
	for s_ in (-1, 1):
		ring_at((s_ * 0.41, 0, bz + 0.15), (0, 1, 0), 0.05, 0.011, CU("dark"))
	coal_heap(0, 0, bz + 0.15, 0.28, 34, hot=8)
	kit.fire_spot((0, 0, bz + 0.25), 0.7)


def th_brazier_toppled():
	def tripod():
		lathe([(0.06, 0), (0.18, 0.04), (0.27, 0.12), (0.3, 0.19), (0.286, 0.205), (0.262, 0.135), (0.17, 0.06), (0.04, 0.03)], (0, 0, 0.55), IRON("dark"), seg=22)  # a deep, thin-walled bowl
		kit.ring(0.29, 0.012, (0, 0, 0.73), IRON("a"), seg=20)
		for k in range(3):
			a = 2 * math.pi * k / 3
			ca, sa = math.cos(a), math.sin(a)
			tube([(ca * 0.15, sa * 0.15, 0.6), (ca * 0.24, sa * 0.24, 0.4), (ca * 0.3, sa * 0.3, 0.03)], 0.02, 0.016, IRON("dark"), seg=6)
			kit.cone(0.03, 0.012, 0.05, (ca * 0.3, sa * 0.3, 0.02), IRON("dark"), verts=6)
		kit.ring(0.235, 0.01, (0, 0, 0.32), IRON("a"), seg=18)
	fig = group(tripod, rot=(0, 90, 0))
	lo, _ = bounds(fig)
	shift(fig, (-0.2, 0, -lo.z))
	for k in range(26):  # cold coals spilled out of the bowl mouth (+X), lying on the floor
		d = 0.1 + rng.random() ** 1.5 * 0.7
		y = J(0.08 + d * 0.35)
		sz = rng.uniform(0.022, 0.045)
		o = kit.gem((0.12 + d, y, 0), (sz * 1.2, sz, sz * 0.7), COAL(), seed=k + 40)
		o.location.z = -min(v.co.z for v in o.data.vertices)


def th_mourning_banner():
	foot((0.98, 0.26, 0.1), (0, -0.04, 0.05), tone=S("c"), bevel=0.02)
	back = B((0.86, 0.12, 2.05), (0, 0.03, 0.1 + 1.025), S("b"), bevel=0.015)
	carve(back, runes(-0.32, 0.32, 0.25, -0.03, h=0.06, gap=0.05))
	B((0.94, 0.17, 0.08), (0, 0.01, 2.17), S("a"), bevel=0.015)
	zr = 1.98
	for s_ in (-1, 1):
		prism([(-0.02, zr - 0.1), (-0.02, zr + 0.08), (-0.16, zr + 0.08), (-0.16, zr + 0.02), (-0.08, zr - 0.04)], s_ * 0.38 - 0.045, s_ * 0.38 + 0.045, S("a"), axis="x")
	rod((-0.44, -0.12, zr), (0.44, -0.12, zr), 0.016, IRON("dark"), seg=8)
	for s_ in (-1, 1):
		lathe([(0.022, 0), (0.03, 0.02), (0.012, 0.05), (0.002, 0.07)], (0, 0, 0), IRON("dark"), seg=8)
		o = bpy.data.objects[-1]
		o.rotation_euler = (0, math.radians(s_ * 90), 0)
		o.location = (s_ * 0.44, -0.12, zr)
	y = -0.13
	W, top, bot = 0.62, zr - 0.04, 0.55
	outline = [(-W / 2, top), (W / 2, top), (W / 2, bot), (W / 4, bot + 0.18), (0, bot - 0.02), (-W / 4, bot + 0.18), (-W / 2, bot)]
	prism(outline, y + 0.006, y - 0.006, CLOTH())
	for i in range(5):  # iron rings over the rod
		x = -W / 2 + 0.04 + i * (W - 0.08) / 4
		ring_at((x, -0.12, zr), (1, 0, 0), 0.03, 0.006, IRON("a"), seg=10)
	g = GOLD(-0.05)
	yb = y - 0.009
	for k, (a, b) in enumerate(zip(outline, outline[1:] + outline[:1])):  # gold border band (alternate depths: no shimmer at corners)
		ax, az = a
		bx, bz = b
		dk = 0.0025 * (k % 2)
		prism(bar((ax + (0 - ax) * 0.06, az + ((top + bot) / 2 - az) * 0.04), (bx + (0 - bx) * 0.06, bz + ((top + bot) / 2 - bz) * 0.04), 0.022), yb + 0.004 - dk, yb - 0.003 - dk, g)
	for x, z in ((W / 2, bot), (0, bot - 0.02), (-W / 2, bot)):  # tassels
		kit.cone(0.02, 0.008, 0.07, (x * 0.9, y, z - 0.03), g, verts=8)
		sphere((x * 0.9, y, z + 0.008), 0.016, g, seg=8, rings=5)
	pale = C((0.55, 0.56, 0.58), 0.9, metal=0.2)
	cz, s = 1.42, 0.17  # the helm emblem sewn on in silver cloth
	ye0, ye1 = y - 0.004, y - 0.012
	prism([(math.cos(a) * s, cz + math.sin(a) * s) for a in [math.pi * k / 12 for k in range(13)]], ye0, ye1, pale)
	prism([(-s * 1.05, cz - 0.0), (0, cz - 0.07), (s * 1.05, cz), (s * 1.05, cz - 0.05), (0, cz - 0.12), (-s * 1.05, cz - 0.05)], ye0 - 0.006, ye1 - 0.006, pale)
	prism(bar((0, cz - 0.1), (0, cz - 0.2), 0.035), ye0, ye1, pale)
	for k in (-1, 1):
		prism(bar((k * s * 0.95, cz - 0.04), (k * s * 0.75, cz - 0.2), 0.04), ye0, ye1, pale)
		flat_hammer(k * 0.1, 0.9, k * 32, 0.42, ye0 + 0.002 + (k > 0) * -0.009, ye1 - 0.002 + (k > 0) * -0.009, pale)
	for k in (-1, 1):  # black mourning ribbon tied on the rod
		tube([(k * 0.02, -0.14, zr), (k * 0.08, -0.15, zr - 0.12), (k * 0.06, -0.155, zr - 0.28)], 0.012, 0.008, C((0.03, 0.03, 0.035), 0.9), seg=6)
	kit.ring(0.026, 0.01, (0, -0.12, zr), C((0.03, 0.03, 0.035), 0.9), rot=(0, 90, 0), seg=10)
	flat_back(0.09)


def th_mourning_bell():
	foot((1.55, 0.62, 0.1), (0, 0, 0.05), tone=S("c"), bevel=0.02)
	for s_ in (-1, 1):
		post = B((0.22, 0.26, 1.72), (s_ * 0.55, 0, 0.1 + 0.86), S("b"), bevel=0.015)
		if s_ < 0:
			carve(post, helm_emblem(-0.55, 1.25, 0.065, -0.13, w=0.012) + runes(-0.62, -0.48, 0.9, -0.13, h=0.05, gap=0.045, under=False)
				+ runes(-0.62, -0.48, 0.8, -0.13, h=0.05, gap=0.045, under=False))
		B((0.3, 0.33, 0.08), (s_ * 0.55, 0, 0.14), S("a"), bevel=0.012)
		B((0.28, 0.31, 0.07), (s_ * 0.55, 0, 1.79), S("a"), bevel=0.012)
	lint = B((1.5, 0.32, 0.22), (0, 0, 1.93), S("a"), bevel=0.015)
	carve(lint, runes(-0.6, 0.6, 1.94, -0.16, h=0.07, gap=0.06, under=False))
	B((1.6, 0.37, 0.06), (0, 0, 2.065), S("c"), bevel=0.012)
	B((0.4, 0.12, 0.06), (0, 0, 1.795), IRON("dark"), bevel=0.006)  # yoke under the lintel
	for x in (-0.16, 0.16):
		kit.rivet((x, -0.062, 1.795), IRON("a"), r=0.013)
	for x in (-0.05, 0.05):
		B((0.03, 0.08, 0.16), (x, 0, 1.7), IRON("dark"), bevel=0.004)
	kit.ring(0.06, 0.018, (0, 0, 1.66), CU("dark"), rot=(90, 0, 0), seg=14)  # crown loop
	z0 = 1.06
	lathe([(0.2, 0.08), (0.3, 0.0), (0.325, 0.03), (0.3, 0.07), (0.25, 0.18), (0.21, 0.34), (0.19, 0.46), (0.13, 0.53), (0.04, 0.56)], (0, 0, z0), CU("b"), seg=24)
	kit.ring(0.3, 0.012, (0, 0, z0 + 0.075), CU("dark"), seg=24)
	kit.ring(0.198, 0.01, (0, 0, z0 + 0.44), CU("dark"), seg=22)
	kit.ring(0.226, 0.008, (0, 0, z0 + 0.27), CU("dark"), seg=22)
	for k in range(8):  # cast bosses around the waist
		a = 2 * math.pi * k / 8
		sphere((math.cos(a) * 0.232, math.sin(a) * 0.232, z0 + 0.2), 0.018, CU("dark"), seg=8, rings=5)
	rod((0, 0, z0 + 0.1), (0, 0, z0 + 0.02), 0.012, IRON("dark"))
	sphere((0, 0, z0 + 0.015), 0.04, IRON("dark"), seg=10, rings=6)  # clapper
	# the striker mallet hangs on an iron hook on the right post
	B((0.04, 0.08, 0.03), (0.55, -0.16, 1.26), IRON("dark"), bevel=0.004)
	kit.cone(0.012, 0.004, 0.04, (0.55, -0.19, 1.285), IRON("dark"), verts=6)
	kit.ring(0.024, 0.007, (0.55, -0.19, 1.25), LEA(), rot=(0, 90, 0), seg=10)
	log((0.55, -0.19, 1.232), (0.55, -0.19, 0.9), 0.016, WOOD(), seg=7, rings=2, bend=0.01, ends=False)
	kit.cylinder(0.055, 0.17, (0.55, -0.19, 0.86), LEA("b"), rot=(0, 90, 0), verts=12, bevel=0.01)
	for x in (0.49, 0.61):
		kit.ring(0.056, 0.007, (x, -0.19, 0.86), CU("dark"), rot=(0, 90, 0), seg=12)


def fig_cuts(x, z, s, f, pose, yf, depth=0.014, hald=False):
	"""A carved dwarf in profile (facing +x when f = 1), as sunk shapes cut into a panel at y = yf."""
	P = []
	for dx in (-0.035, 0.035):
		P.append(bar((x + dx * s, z), (x + dx * s * 0.8 + f * 0.01 * s, z + 0.13 * s), 0.055 * s))
		P.append([(x + dx * s - 0.035 * s, z), (x + dx * s + f * 0.06 * s, z), (x + dx * s + f * 0.05 * s, z + 0.035 * s), (x + dx * s - 0.03 * s, z + 0.035 * s)])  # boot
	P.append([(x - 0.09 * s, z + 0.11 * s), (x + 0.09 * s, z + 0.11 * s), (x + 0.075 * s, z + 0.3 * s), (x - 0.075 * s, z + 0.3 * s)])
	P.append(circ(x, z + 0.35 * s, 0.065 * s, n=12, wob=0))
	P.append([(x - 0.08 * s, z + 0.36 * s), (x + 0.08 * s, z + 0.36 * s), (x + 0.06 * s, z + 0.42 * s), (x, z + 0.445 * s), (x - 0.06 * s, z + 0.42 * s)])
	P.append([(x, z + 0.33 * s), (x + f * 0.085 * s, z + 0.31 * s), (x + f * 0.06 * s, z + 0.16 * s), (x + f * 0.02 * s, z + 0.12 * s)])
	if hald:  # his heavy brow juts out over the face
		P.append(bar((x, z + 0.375 * s), (x + f * 0.1 * s, z + 0.355 * s), 0.035 * s, 0.02 * s))
	sx, sz = x + f * 0.03 * s, z + 0.27 * s
	if pose in ("hammer", "anvil"):
		hx, hz = x + f * 0.1 * s, z + 0.52 * s
		P.append(bar((sx, sz), (hx, hz), 0.04 * s))
		tx, tz = x + f * (0.02 if pose == "hammer" else 0.16) * s, z + 0.72 * s
		P.append(bar((hx, hz), (tx, tz), 0.022 * s))
		P.append(bar((tx - 0.075 * s, tz + f * 0.01 * s), (tx + 0.075 * s, tz - f * 0.01 * s), 0.065 * s))
	elif pose == "spear":
		P.append(bar((sx, sz), (x + f * 0.14 * s, z + 0.3 * s), 0.04 * s))
		P.append(bar((x - f * 0.12 * s, z + 0.17 * s), (x + f * 0.42 * s, z + 0.45 * s), 0.02 * s))
		tipx, tipz = x + f * 0.42 * s, z + 0.45 * s
		P.append([(tipx - f * 0.02 * s, tipz - 0.03 * s), (tipx + f * 0.09 * s, tipz + 0.05 * s), (tipx - f * 0.01 * s, tipz + 0.03 * s)])
		P.append(circ(x + f * 0.07 * s, z + 0.2 * s, 0.085 * s, n=14, wob=0))  # shield
	elif pose == "bellows":
		P.append(bar((sx, sz), (x + f * 0.16 * s, z + 0.2 * s), 0.04 * s))
	return [cy(p, yf, depth) for p in P]


def th_relief_battle():
	p, yf = panel_wall(1.6, 1.3)
	cuts = gline([(-0.74, 0.16), (0.74, 0.16), (0.74, 1.34), (-0.74, 1.34), (-0.74, 0.16)], 0.02, yf)
	cuts += gline([(-0.7, 0.3), (-0.2, 0.31), (0.3, 0.29), (0.7, 0.31)], 0.016, yf)  # ground
	cuts += runes(-0.62, 0.62, 0.23, yf, h=0.06, gap=0.055, under=False)
	cuts += fig_cuts(-0.18, 0.31, 1.25, 1, "hammer", yf, depth=0.016, hald=True)
	cuts += fig_cuts(-0.45, 0.31, 1.0, 1, "spear", yf)
	cuts += fig_cuts(-0.63, 0.31, 0.95, 1, "spear", yf)
	# the great deep-worm rising from a crack in the ground, jaws open
	body = [(0.66, 0.3), (0.62, 0.55), (0.5, 0.78), (0.42, 0.98), (0.3, 1.08)]
	wid = [0.16, 0.15, 0.13, 0.12, 0.11]
	for (a, b), w0, w1 in zip(zip(body, body[1:]), wid, wid[1:]):
		cuts.append(cy(bar(a, b, w0 * 0.8, w1 * 0.8), yf, 0.016))
		for t in (0.0, 0.33, 0.66):  # ring segments make the worm's bumpy outline
			cuts.append(cy(circ(a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, (w0 + (w1 - w0) * t) * (0.5 if t else 0.6), n=14, wob=0), yf, 0.016))
	hx, hz = 0.3, 1.08
	cuts.append(cy([(hx + 0.05, hz + 0.05), (hx - 0.2, hz + 0.1), (hx - 0.24, hz + 0.05), (hx - 0.05, hz - 0.0)], yf, 0.016))  # upper jaw
	cuts.append(cy([(hx + 0.05, hz - 0.04), (hx - 0.2, hz - 0.12), (hx - 0.22, hz - 0.08), (hx - 0.04, hz - 0.0)], yf, 0.016))  # lower jaw
	cuts += gline([(0.5, 0.3), (0.58, 0.27), (0.66, 0.29), (0.76, 0.26)], 0.014, yf, 0.01)
	for k in range(5):  # stalactites hanging from the top border
		x = -0.6 + k * 0.28 + J(0.04)
		cuts.append(cy([(x - 0.04, 1.33), (x + 0.04, 1.33), (x + J(0.01), 1.33 - rng.uniform(0.08, 0.15))], yf, 0.012))
	carve(p, cuts)
	frame_band(1.6, 1.3, yf, z0=0.095, t=0.05)
	for x in (-0.74, 0.74):
		for z in (0.15, 1.34):
			kit.rivet((x, yf - 0.04, z), CU("dark"), r=0.016)


def th_relief_forge():
	p, yf = panel_wall(1.6, 1.3)
	cuts = gline([(-0.74, 0.16), (0.74, 0.16), (0.74, 1.34), (-0.74, 1.34), (-0.74, 0.16)], 0.02, yf)
	cuts += gline([(-0.7, 0.3), (0.7, 0.3)], 0.016, yf)
	cuts += runes(-0.62, 0.62, 0.23, yf, h=0.06, gap=0.055, under=False)
	cuts += fig_cuts(-0.32, 0.31, 1.25, 1, "anvil", yf, depth=0.016, hald=True)
	ax, az = 0.0, 0.31  # the anvil, the brow-helm on it, sparks
	cuts.append(cy([(ax - 0.08, az), (ax + 0.08, az), (ax + 0.05, az + 0.06), (ax + 0.04, az + 0.17), (ax - 0.04, az + 0.17), (ax - 0.05, az + 0.06)], yf, 0.016))
	cuts.append(cy([(ax - 0.16, az + 0.17), (ax + 0.12, az + 0.17), (ax + 0.12, az + 0.24), (ax - 0.08, az + 0.24), (ax - 0.2, az + 0.22)], yf, 0.016))
	cuts += gline([(ax - 0.07 + math.cos(a) * 0.07, az + 0.26 + math.sin(a) * 0.07) for a in [math.pi * k / 8 for k in range(9)]], 0.014, yf)
	cuts += gline([(ax - 0.15, az + 0.25), (ax + 0.01, az + 0.25)], 0.014, yf)
	for k in range(7):
		a = 0.4 + k * 0.35
		cuts.append(cy(circ(ax - 0.07 + math.cos(a) * rng.uniform(0.14, 0.24), az + 0.3 + math.sin(a) * rng.uniform(0.12, 0.22), 0.012, n=6, wob=0), yf, 0.01))
	# the forge on the right: an arched hearth with flames, a chimney, a bellows worked by a second dwarf
	fx = 0.42
	cuts += gline([(fx - 0.17, 0.3), (fx - 0.17, 0.62)] + [(fx + math.cos(a) * 0.17, 0.62 + math.sin(a) * 0.12) for a in [math.pi - math.pi * k / 8 for k in range(9)]] + [(fx + 0.17, 0.3)], 0.02, yf)
	cuts += gline([(fx - 0.08, 0.74), (fx - 0.08, 1.3)], 0.02, yf) + gline([(fx + 0.08, 0.74), (fx + 0.08, 1.3)], 0.02, yf)
	for k, (dx, h) in enumerate(((-0.08, 0.2), (0.0, 0.27), (0.08, 0.18))):
		cuts.append(cy([(fx + dx - 0.045, 0.32), (fx + dx + 0.045, 0.32), (fx + dx + 0.02, 0.32 + h * 0.6), (fx + dx + 0.01 * (k - 1), 0.32 + h), (fx + dx - 0.025, 0.32 + h * 0.55)], yf, 0.016))
	cuts += fig_cuts(0.68, 0.31, 0.9, -1, "bellows", yf)
	cuts.append(cy([(0.6, 0.42), (0.62, 0.55), (0.62, 0.42 + 0.02)], yf, 0.014))
	cuts.append(cy([(0.53, 0.43), (0.62, 0.36), (0.63, 0.54), (0.55, 0.5)], yf, 0.016))  # bellows
	cuts.append(cy(bar((0.54, 0.45), (fx + 0.17, 0.4), 0.02), yf, 0.014))
	carve(p, cuts)
	frame_band(1.6, 1.3, yf, z0=0.095, t=0.05)
	for x in (-0.74, 0.74):
		for z in (0.15, 1.34):
			kit.rivet((x, yf - 0.04, z), CU("dark"), r=0.016)


def th_name_plaque():
	foot((0.42, 0.3, 0.08), (0, -0.06, 0.04), tone=S("c"), bevel=0.015)
	B((0.18, 0.12, 0.98), (0, 0.0, 0.07 + 0.49), S("b"), bevel=0.012)  # the post
	kit.taper(0.18, 0.12, 0.5, 0.14, 0.14, (0, -0.005, 0.92), S("a"), bevel=0.012)  # corbel
	pl = B((0.82, 0.12, 0.66), (0, -0.005, 1.38), S("b"), bevel=0.015)
	yf = -0.065
	cuts = helm_emblem(0, 1.575, 0.07, yf, w=0.012)
	for r in range(6):
		cuts += runes(-0.3, 0.3, 1.43 - r * 0.068, yf, h=0.045, w=0.01, gap=0.042, depth=0.007, under=False)
	carve(pl, cuts)
	frame_band(0.82, 0.66, yf, z0=1.05, t=0.055)
	prism([(-0.36, 1.705), (0.36, 1.705), (0.0, 1.85)], 0.055, -0.08, S("a"))  # pediment
	for x in (-0.36, 0.36):
		for z in (1.08, 1.68):
			kit.cylinder(0.022, 0.012, (x, yf - 0.045, z), CU("b"), rot=(90, 0, 0), verts=10, bevel=0.003)
			kit.rivet((x, yf - 0.05, z), CU("dark"), r=0.01)
	flat_back(0.06)


def coin_pile(cx, cy_, z, rx, ry, n, h):
	for k in range(n):
		a, d = rng.uniform(0, 6.28), math.sqrt(rng.random())
		x, y = cx + math.cos(a) * d * rx, cy_ + math.sin(a) * d * ry
		zz = z + (1 - d) * h + 0.004
		coin((x, y, zz), GOLD(J(0.05)), tilt=(J(28), J(28), rng.uniform(0, 90)))


def th_niche_coins():
	yf, nz, nd, _ = niche_block()
	yc = yf + nd * 0.5
	coin_pile(0, yc, nz, 0.17, 0.09, 60, 0.07)
	for x in (-0.2, 0.2):
		goblet(x, yc + 0.03, nz - 0.002, s=1.1, m=GOLD() if x < 0 else SILV("a"))
	for k, (x, y) in enumerate(((-0.12, yc + 0.08), (0.12, yc + 0.085))):  # neat coin stacks behind
		h = 0.05 + k * 0.02
		kit.cylinder(0.026, h, (x, y, nz + h / 2 - 0.002), GOLD(-0.04), verts=12, bevel=0.002)
		for j in range(int(h / 0.012)):
			kit.ring(0.026, 0.0025, (x, y, nz + 0.006 + j * 0.012), GOLD(0.02), seg=12)
	for k, (x, z, r) in enumerate(((0.05, nz + 0.004, 0), (0.05, nz + 0.024, 90))):  # two small gold bars crossed
		B((0.1, 0.04, 0.024), (x, yf + 0.06, z + 0.012 - 0.003 * k), GOLD(0.04), bevel=0.006, rot=(0, 0, r + 10))
	o = kit.ring(0.022, 0.006, (-0.06, yf + 0.045, nz + 0.005), GOLD(), seg=14)
	sphere((-0.06 + 0.024, yf + 0.045, nz + 0.012), 0.01, C((0.5, 0.02, 0.04), 0.2), seg=8, rings=5)
	kit.cylinder(0.31, 0.012, (0, yf - 0.03, nz + 0.003), CU("b"), verts=4, bevel=0.002).scale = (1, 0.12, 1)  # bronze lip


def th_niche_candles():
	yf, nz, nd, _ = niche_block()
	yc = yf + nd * 0.5
	kit.cylinder(0.22, 0.01, (0, yc, nz + 0.002), WAX(), verts=18, bevel=0.003).scale = (1, 0.5, 1)  # wax pool
	B((0.12, 0.09, 0.06), (0, yf + nd - 0.07, nz + 0.03), S("a"), bevel=0.008)  # idol base
	helm((0, yf + nd - 0.07, nz + 0.12), s=0.3, mi=S("a"), mt=S("b"), ms=S("b"))
	kit.cylinder(0.035, 0.07, (0, yf + nd - 0.07, nz + 0.09), S("b"), verts=10)
	for x, y, r, h in ((-0.2, yc + 0.02, 0.022, 0.16), (-0.12, yc - 0.03, 0.02, 0.09), (0.11, yc - 0.035, 0.024, 0.12), (0.2, yc + 0.03, 0.02, 0.2), (0.0, yc - 0.06, 0.018, 0.05)):
		candle(x, y, nz + 0.006, r, h)
	for x in (-0.15, -0.02, 0.13):  # wax run over the sill
		sphere((x, yf - 0.05, nz - 0.03), 0.014, WAX(), scale=(1, 0.7, 2.6), seg=8, rings=5)
		sphere((x, yf - 0.035, nz - 0.0), 0.016, WAX(), scale=(1.4, 1.2, 0.6), seg=8, rings=5)


def th_niche_looted():
	yf, nz, nd, body = niche_block(sill=False)
	cuts = gline([(0.15, nz + 0.0), (0.21, nz - 0.1), (0.19, nz - 0.2), (0.26, nz - 0.3)], 0.014, yf, 0.016)
	cuts += gline([(-0.28, nz + 0.4), (-0.36, nz + 0.5), (-0.34, nz + 0.62), (-0.42, nz + 0.75)], 0.012, yf, 0.014)
	cuts.append(prism([(0.12, nz + 0.05), (0.36, nz + 0.05), (0.4, nz - 0.08), (0.3, nz - 0.12), (0.2, nz - 0.05)], yf - 0.05, yf + 0.09, GROOVE()))  # the broken-off corner
	for k in range(4):  # pry scratches round the niche mouth
		cuts.append(cy(bar((-0.27 + J(0.01), nz + 0.15 + k * 0.05), (-0.31, nz + 0.19 + k * 0.05), 0.008), yf, 0.006))
	carve(body, cuts)
	B((0.2, 0.06, 0.06), (-0.17, yf - 0.02, nz - 0.03), S("a"), bevel=0.012)  # what is left of the sill
	o = kit.gem((0.32, yf - 0.32, 0), (0.12, 0.08, 0.06), S("b"), seed=21)  # the broken corner on the floor
	o.location.z = -min(v.co.z for v in o.data.vertices)
	rough_chips([(0.1, yf - 0.25, 0.03), (0.45, yf - 0.15, 0.025), (0.22, yf - 0.45, 0.02)])
	pry_bar((0.2, yf + 0.03, nz - 0.03), (0.42, yf - 0.32, nz + 0.12))
	yc = yf + nd * 0.55
	coin((0.08, yc, nz + 0.0035), GOLD())
	g = group(lambda: goblet(0, 0, 0, s=1.1), rot=(0, 90, 20))
	lo, hi = bounds(g)
	shift(g, (-0.1 - (lo.x + hi.x) / 2, yc - (lo.y + hi.y) / 2, nz - lo.z - 0.002))


def urn(x, y, z, h, m=None):
	m = m or CU("b")
	s = h / 0.3
	lathe([(0.05 * s, 0), (0.055 * s, 0.012 * s), (0.04 * s, 0.03 * s), (0.08 * s, 0.11 * s), (0.09 * s, 0.17 * s), (0.07 * s, 0.24 * s),
		(0.045 * s, 0.27 * s), (0.05 * s, 0.285 * s), (0.04 * s, 0.29 * s)], (x, y, z), m, seg=14)
	lathe([(0.052 * s, 0), (0.05 * s, 0.015 * s), (0.03 * s, 0.035 * s), (0.012 * s, 0.045 * s), (0.016 * s, 0.06 * s), (0.002, 0.07 * s)], (x, y, z + 0.283 * s), CU("dark"), seg=12)
	kit.ring(0.089 * s, 0.006 * s, (x, y, z + 0.15 * s), CU("dark"), seg=14)


def th_urn_shelf():
	foot((1.3, 0.46, 0.1), (0, -0.14, 0.05), tone=S("c"), bevel=0.02)
	B((1.2, 0.1, 1.62), (0, 0.03, 0.1 + 0.81), S("b"), bevel=0.015)  # back slab
	B((1.28, 0.42, 0.07), (0, -0.13, 1.755), S("a"), bevel=0.015)  # top cornice-shelf
	for k, z in enumerate((0.5, 1.08)):
		sh = B((1.2, 0.34, 0.07), (0, -0.15, z), S("a"), bevel=0.012)
		carve(sh, runes(-0.5, 0.5, z, -0.32, h=0.04, w=0.009, gap=0.04, depth=0.006, under=False))
		for x in (-0.48, 0.0, 0.48):
			kit.taper(0.12, 0.26, 0.12, 0.3, 0.2, (x, -0.11, z - 0.235), S("c"), bevel=0.012)  # corbels
	for k, (x, h) in enumerate(((-0.46, 0.3), (-0.23, 0.34), (0.0, 0.38), (0.23, 0.34), (0.46, 0.3))):
		urn(x, -0.16, 1.112, h)
	for k, x in enumerate((-0.42, -0.14, 0.14, 0.42)):  # small lidded stone ash boxes below
		bx = B((0.2, 0.18, 0.15), (x, -0.16, 0.535 + 0.075 - 0.002), S("b" if k % 2 else "c"), bevel=0.012)
		carve(bx, helm_emblem(x, 0.6, 0.035, -0.25, w=0.008, depth=0.006))
		B((0.22, 0.2, 0.035), (x, -0.16, 0.7), S("a"), bevel=0.01)
		kit.cylinder(0.025, 0.02, (x, -0.16, 0.725), S("a"), verts=8, bevel=0.004)
		B((0.08, 0.01, 0.03), (x, -0.255, 0.56), CU("b"), bevel=0.002)
	flat_back(0.08)


def th_sealed_door():
	D, R, CZ = 0.3, 0.78, 0.7
	wall = B((2.1, D, 1.85), (0, 0, 0.925), S("b"), bevel=0.015)
	yf = -D / 2
	ring = [(math.cos(a) * (R + 0.01), CZ + math.sin(a) * (R + 0.01)) for a in [math.radians(-64 + k * 308 / 40) for k in range(41)]]
	carve(wall, [prism(ring, yf - 0.05, yf + 0.12, GROOVE())] + runes(-0.9, -0.62, 1.62, yf, h=0.05, gap=0.045) + runes(0.62, 0.9, 1.62, yf, h=0.05, gap=0.045))
	# voussoir stones around the round opening
	n = 13
	for k in range(n):
		a0 = math.radians(-60 + k * 300 / n + 1.2)
		a1 = math.radians(-60 + (k + 1) * 300 / n - 1.2)
		pts = [(math.cos(a) * r, CZ + math.sin(a) * r) for r, a in ((R + 0.02, a0), (R + 0.2 + 0.03 * (k % 2), a0), (R + 0.2 + 0.03 * (k % 2), a1), (R + 0.02, a1))]
		pts = [(x, max(z, 0.0)) for x, z in pts]
		prism(pts, yf + 0.006, yf - 0.04, S("a" if k % 2 else "c"))
	door = kit.cylinder(R - 0.01, 0.1, (0, yf + 0.06, CZ), S("c"), rot=(90, 0, 0), verts=40, bevel=0.0)
	dy = yf + 0.01
	cuts = [B((2, 1, 0.5), (0, 0, -0.25 + 0.004), S("c"), bevel=0)]  # flat at the floor
	cuts += gline([(math.cos(a) * 0.62, CZ + math.sin(a) * 0.62) for a in [math.radians(-50 + k * 280 / 24) for k in range(25)]], 0.016, dy)
	cuts += helm_emblem(0, 1.02, 0.16, dy)
	for k in range(9):
		a = math.radians(-40 + k * 260 / 8)
		cuts += gline([(math.cos(a) * 0.64, CZ + math.sin(a) * 0.64), (math.cos(a) * 0.74, CZ + math.sin(a) * 0.74)], 0.014, dy)
	carve(door, cuts)
	for z in (0.32, 0.62):  # iron bands
		w = 2 * math.sqrt(max(0.0, (R - 0.02) ** 2 - (z - CZ) ** 2)) * 0.96
		B((w, 0.02, 0.07), (0, dy - 0.006, z), IRON("dark"), bevel=0.004)
		for x in (-w / 2 + 0.05, -w / 4, w / 4, w / 2 - 0.05):
			kit.rivet((x, dy - 0.017, z), IRON("a"), r=0.014)
	# the great lock: two staples on the frame, a sagging chain, the padlock on the lower band
	for s_ in (-1, 1):
		B((0.06, 0.04, 0.12), (s_ * 1.0, yf - 0.012, 0.62), IRON("dark"), bevel=0.005)
		kit.ring(0.04, 0.011, (s_ * 1.0, yf - 0.04, 0.62), IRON("a"), rot=(0, 90, 0), seg=12)
		chain((s_ * 1.0, yf - 0.05, 0.6), (s_ * 0.09, yf - 0.07, 0.52), link=0.03, wire=0.009)
	B((0.16, 0.05, 0.14), (0, yf - 0.07, 0.45), IRON("b"), bevel=0.012)
	kit.ring(0.06, 0.013, (0, yf - 0.07, 0.53), IRON("a"), rot=(90, 0, 0), seg=14)
	B((0.02, 0.012, 0.05), (0, yf - 0.1, 0.44), C((0.02, 0.02, 0.02), 1.0), bevel=0.002)  # keyhole
	B((0.2, 0.024, 0.12), (0, dy - 0.006, 0.45), IRON("dark"), bevel=0.006)  # lock plate behind
	flat_back(0.145)


def th_door_fallen():
	R = 0.76

	def door():
		d = kit.cylinder(R, 0.12, (0, 0, 0), S("c"), rot=(90, 0, 0), verts=40, bevel=0.0)
		cuts = [B((2, 1, 0.5), (0, 0, -0.7 - 0.25), S("c"), bevel=0)]
		cuts += gline([(math.cos(a) * 0.6, math.sin(a) * 0.6) for a in [math.radians(-50 + k * 280 / 24) for k in range(25)]], 0.016, -0.06)
		cuts += helm_emblem(0, 0.3, 0.16, -0.06)
		carve(d, cuts)
		for z in (-0.38, -0.08):
			w = 2 * math.sqrt(max(0.0, (R - 0.02) ** 2 - z * z)) * 0.96
			B((w, 0.02, 0.07), (0, -0.065, z), IRON("dark"), bevel=0.004)
			for x in (-w / 2 + 0.05, -w / 4, w / 4, w / 2 - 0.05):
				kit.rivet((x, -0.076, z), IRON("a"), r=0.014)
	g = group(door, rot=(-90, 0, 0))
	lo, _ = bounds(g)
	shift(g, (0, 0, -lo.z))
	disc = [o for o in g if o.data.materials and o.dimensions.x > 1.4 and "greystone" in o.data.materials[0].name][0]
	zig = [(-0.06, -0.9), (0.04, -0.5), (-0.05, -0.15), (0.06, 0.2), (-0.03, 0.55), (0.05, 0.9)]
	cut = prism([(x - 0.022, y) for x, y in zig] + [(x + 0.022, y) for x, y in reversed(zig)], -0.1, 0.5, GROOVE(), axis="z")
	carve(disc, [cut])
	right = [o for o in g if o is not disc and o.matrix_world.translation.x > 0.05]
	bands = [o for o in g if o is not disc and o not in right and abs(o.matrix_world.translation.x) <= 0.05]
	for o in bands:  # bands break with the door: cut them too
		carve(o, [prism([(x - 0.022, y) for x, y in zig] + [(x + 0.022, y) for x, y in reversed(zig)], -0.1, 0.5, GROOVE(), axis="z")])

	def zx(y):
		for (x0, y0), (x1, y1) in zip(zig, zig[1:]):
			if y0 <= y <= y1:
				return x0 + (x1 - x0) * (y - y0) / (y1 - y0)
		return 0.0
	off = Matrix.Translation((0.14, 0.05, 0)) @ Matrix.Rotation(math.radians(-7), 4, "Z")
	for o in [disc] + bands:  # the right half slid away from the left
		mw = o.matrix_world.copy()
		inv = mw.inverted()
		for v in o.data.vertices:
			w = mw @ v.co
			if w.x > zx(w.y):
				v.co = inv @ (off @ w)
	for o in right:
		o.matrix_world = off @ o.matrix_world
	pry_bar((-0.95, -0.35, 0.012), (-0.35, -0.75, 0.012))
	pry_bar((0.9, 0.5, 0.012), (1.05, -0.2, 0.012))
	rough_chips([(0.0, -0.85, 0.04), (0.1, 0.88, 0.035), (-0.12, 0.95, 0.025), (0.02, -1.0, 0.03)])


def th_chest_looted():
	L, W, H = 0.95, 0.58, 0.52
	foot((L + 0.1, W + 0.1, 0.06), (0, 0, 0.03), tone=S("c"), bevel=0.015)
	body = B((L, W, H), (0, 0, 0.055 + H / 2), S("b"), bevel=0.015)
	yf = -W / 2
	cuts = [B((L - 0.14, W - 0.14, H), (0, 0, 0.055 + 0.08 + H / 2), GROOVE(), bevel=0)]  # hollow inside
	cuts += helm_emblem(0, 0.36, 0.09, yf) + runes(-0.4, -0.18, 0.3, yf, h=0.05, gap=0.045, under=False) + runes(0.18, 0.4, 0.3, yf, h=0.05, gap=0.045, under=False)
	cuts += gline([(0.36, 0.56), (0.4, 0.45), (0.37, 0.35), (0.44, 0.24)], 0.012, yf, 0.014)  # crack
	carve(body, cuts)
	for sx in (-1, 1):
		for sy in (-1, 1):
			B((0.05, 0.05, H - 0.02), (sx * (L / 2 - 0.0), sy * (W / 2 - 0.0), 0.055 + H / 2), CU("b"), bevel=0.006)
			for z in (0.15, 0.45):
				kit.rivet((sx * L / 2 + sx * 0.02, sy * W / 2 + sy * 0.004, z), CU("dark"), r=0.011)

	def lid():
		B((0.64, 1.03, 0.1), (0, 0, 0), S("a"), bevel=0.015)
		top = B((0.5, 0.88, 0.04), (0, 0, 0.065), S("c"), bevel=0.01)
		crack = [(0.25, -0.44), (0.1, -0.2), (0.04, 0.05), (-0.1, 0.2), (-0.25, 0.44)]
		carve(top, [prism(bar(a, b, 0.014), 0.072, 0.12, GROOVE(), axis="z") for a, b in zip(crack, crack[1:])])
	g = group(lid, rot=(0, 0, 9))  # shoved off: it lies flat on the floor beside the chest
	lo, hi = bounds(g)
	shift(g, (L / 2 + 0.09 - lo.x, 0.04 - (lo.y + hi.y) / 2, -lo.z))
	pry_bar((-0.2, -0.55, 0.012), (-0.7, -0.35, 0.012))
	coin((0.1, -0.48, 0.0035), GOLD())
	rough_chips([(-0.66, -0.45, 0.025), (-0.6, 0.48, 0.02)])


def axe(L=0.95):
	"""A long-hafted dwarf axe along +Z from the origin; blade toward -X... +X, flat in the X/Z plane."""
	log((0, 0, 0.02), (0, 0, L), 0.022, WOOD(), seg=8, rings=3, bend=0.01, ends=False)
	kit.cylinder(0.028, 0.035, (0, 0, 0.02), IRON("dark"), verts=8)
	for k in range(4):
		kit.ring(0.023, 0.006, (0, 0, 0.08 + k * 0.028), LEA(), seg=10)
	z = L - 0.12
	prism([(0.0, z - 0.04), (0.06, z - 0.05), (0.16, z - 0.12), (0.2, z + 0.02), (0.17, z + 0.16), (0.07, z + 0.07), (0.0, z + 0.07)], -0.012, 0.012, IRON("a"))
	B((0.05, 0.05, 0.13), (0, 0, z + 0.01), IRON("dark"), bevel=0.006)
	prism([(0.0, z - 0.02), (-0.08, z - 0.0), (-0.1, z + 0.03), (0.0, z + 0.05)], -0.01, 0.01, IRON("dark"))  # back spike
	kit.ring(0.026, 0.007, (0, 0, z - 0.07), CU("b"), seg=10)


def th_weapon_rack():
	foot((1.5, 0.5, 0.08), (0, 0, 0.04), tone=S("c"), bevel=0.015)
	for s_ in (-1, 1):
		B((0.14, 0.24, 1.28), (s_ * 0.62, 0.02, 0.08 + 0.64), S("b"), bevel=0.012)
	xs = (-0.4, -0.2, 0.0, 0.2, 0.4)
	top = B((1.4, 0.24, 0.13), (0, 0.02, 1.4), S("a"), bevel=0.012)
	carve(top, runes(-0.55, 0.55, 1.4, -0.1, h=0.06, gap=0.05, under=False) + [kit.cylinder(0.034, 0.4, (x, -0.1, 1.4), GROOVE(), verts=12, bevel=0) for x in xs])
	low = B((1.26, 0.2, 0.1), (0, 0.0, 0.3), S("a"), bevel=0.012)
	carve(low, [kit.cylinder(0.034, 0.4, (x, -0.02, 0.3), GROOVE(), verts=12, bevel=0) for x in xs])
	for x in xs:
		B((0.08, 0.01, 0.035), (x, -0.104, 0.27), CU("b"), bevel=0.002)
	group(lambda: axe(1.62), at=(-0.4, -0.02, 0.08))
	group(lambda: hammer(1.45, s=0.9), at=(-0.2, -0.02, 0.08))
	group(lambda: (log((0, 0, 0.02), (0, 0, 1.6), 0.02, WOOD(), seg=8, rings=3, bend=0.01, ends=False),
		kit.cone(0.03, 0.02, 0.07, (0, 0, 1.63), IRON("dark"), verts=8),
		prism([(0, 1.66), (0.045, 1.74), (0.03, 1.84), (0, 1.92), (-0.03, 1.84), (-0.045, 1.74)], -0.01, 0.01, IRON("a")),
		kit.cylinder(0.026, 0.04, (0, 0, 0.02), IRON("dark"), verts=8)), at=(0.0, -0.02, 0.08))
	group(lambda: hammer(1.45, s=0.9), at=(0.2, -0.02, 0.08), rot=(0, 0, 90))
	group(lambda: axe(1.62), at=(0.4, -0.02, 0.08), rot=(0, 0, 180))


def th_shield_wall():
	foot((1.8, 0.3, 0.08), (0, -0.05, 0.04), tone=S("c"), bevel=0.015)
	back = B((1.7, 0.1, 1.45), (0, 0.03, 0.08 + 0.725), S("b"), bevel=0.012)
	cuts = []
	for x in (-0.55, 0.0, 0.55):
		cuts += runes(x - 0.2, x + 0.2, 0.45, -0.02, h=0.05, gap=0.045)
	carve(back, cuts)
	B((1.78, 0.16, 0.07), (0, 0.0, 1.56), S("a"), bevel=0.012)
	for i, x in enumerate((-0.55, 0.0, 0.55)):
		B((0.05, 0.08, 0.05), (x, -0.05, 1.345), IRON("dark"), bevel=0.005)  # peg
		round_shield((x, -0.075, 1.05), 0.26, split=(i == 1))
		B((0.22, 0.012, 0.06), (x, -0.024, 0.32), CU("b"), bevel=0.003)
	flat_back(0.08)


def th_ash_urn():
	body, top = plinth(0.52, 0.52, 0.8)
	carve(body, helm_emblem(0, 0.5, 0.1, -0.26) + runes(-0.18, 0.18, 0.22, -0.26, h=0.05, gap=0.045, under=False))
	z0 = top - 0.004
	lathe([(0.11, 0), (0.13, 0.02), (0.08, 0.05), (0.1, 0.08), (0.19, 0.17), (0.235, 0.29), (0.22, 0.41), (0.14, 0.5), (0.115, 0.55), (0.15, 0.57), (0.15, 0.6)], (0, 0, z0), CU("b"), seg=22)
	lathe([(0.158, 0), (0.16, 0.02), (0.12, 0.06), (0.05, 0.1), (0.04, 0.11)], (0, 0, z0 + 0.595), CU("dark"), seg=20)
	for z, r in ((0.17, 0.192), (0.3, 0.237), (0.41, 0.222)):
		kit.ring(r, 0.009, (0, 0, z0 + z), CU("dark"), seg=22)
	for s_ in (-1, 1):
		ring_at((s_ * 0.24, 0, z0 + 0.36), (0, 1, 0), 0.055, 0.012, CU("dark"))
	for k in range(10):
		a = 2 * math.pi * k / 10
		sphere((math.cos(a) * 0.231, math.sin(a) * 0.231, z0 + 0.24), 0.014, GOLD(), seg=8, rings=5)
	helm((0, 0, z0 + 0.7), s=0.28)


def mourner():
	"""A stone mourner (the game's dwarf in armour) on one knee, head bowed, fist on his heart, the other hand on the pommel of an axe set head-down."""
	ma = S("a")
	pose = [("thigh_l", "X", -85), ("calf_l", "X", 85), ("thigh_r", "X", 15), ("calf_r", "X", 80), ("foot_r", "X", 40),
		("spine_01", "X", 14), ("neck_01", "X", 18), ("Head", "X", 14),
		("upperarm_r", "Y", -74), ("lowerarm_r", "X", -82),  # right fist on the axe's pommel at his side
		("upperarm_l", "Y", 70), ("upperarm_l", "X", -50), ("lowerarm_l", "X", -60), ("lowerarm_l", "Z", -60)] + curl("r") + curl("l")  # left fist on his heart
	# shorts left out: hidden under his coat, and the thinned coat would lie on them (shimmer); ratio/min_verts: file under 2 MB
	ms, j = real_dwarf(pose, m=STONE_DWARF, files=((HEADLESS[0], HEADLESS[1] + ("shorts",)), ARMOUR), ratio=0.12, min_verts=1200)
	lo, _ = bounds(ms)
	shift(ms, (0, 0, -lo.z))
	g = palm(j, "r")
	x, y, top = g.x, g.y, g.z - lo.z + 0.05
	log((x, y, 0.16), (x, y, top), 0.022, ma, seg=8, rings=2, bend=0, ends=False)
	kit.cylinder(0.035, 0.04, (x, y, top), ma, verts=8)  # pommel above the hands
	for k in range(3):
		kit.ring(0.025, 0.007, (x, y, 0.3 + k * 0.05), ma, seg=10)
	for s_ in (-1, 1):  # the two-sided axe head, its edge on the floor
		blade = prism([(x, 0.2), (x + s_ * 0.08, 0.22), (x + s_ * 0.18, 0.02), (x + s_ * 0.16, 0.0), (x + s_ * 0.06, 0.06), (x, 0.08)], y - 0.016, y + 0.016, ma)
		carve(blade, gline([(x + s_ * 0.05, 0.16), (x + s_ * 0.12, 0.05)], 0.008, y - 0.016, 0.005))
	B((0.06, 0.05, 0.14), (x, y, 0.13), ma, bevel=0.008)


def th_kneeling_mourner():
	body, top = plinth(1.15, 0.9, 0.35)
	carve(body, runes(-0.44, 0.44, 0.18, -0.45, h=0.05, gap=0.05, under=False))
	group(mourner, at=(0, 0.06, top - 0.005), scale=1.15)


def th_robber_pinned():
	for x, y in ((-0.6, 0.02), (0.55, -0.05)):  # rubble the lintel landed on
		o = kit.gem((x, y, 0), (0.16, 0.15, 0.08), S("c"), seed=int(x * 10) + 30)
		o.location.z = -min(v.co.z for v in o.data.vertices)
	lint = B((1.7, 0.42, 0.3), (0, 0, 0.12 + 0.15), S("b"), bevel=0.02, rot=(0, 2, 0))
	carve(lint, runes(-0.65, 0.65, 0.29, -0.2, h=0.07, gap=0.06) + gline([(0.2, 0.42), (0.26, 0.3), (0.22, 0.2), (0.3, 0.12)], 0.016, -0.2, 0.02))
	bn = BONE(-0.08)
	skull((-0.1, -0.33, 0.09), 0.75, bn, face=(0.5, -1, 0))
	bone((0.08, -0.28, 0.022), (0.3, -0.52, 0.022), 0.018, bn)  # upper arm reaching out
	bone((0.3, -0.52, 0.02), (0.52, -0.62, 0.02), 0.016, BONE(-0.12))
	for k in range(4):  # finger bones toward the pry bar
		a = -0.5 + k * 0.3
		rod((0.53 + k * 0.008, -0.615 - k * 0.006, 0.012), (0.54 + math.cos(a) * 0.07, -0.62 - math.sin(a) * 0.05 - 0.03, 0.01), 0.007, bn, seg=5)
	for k in range(4):  # ribs poking out under the edge
		tube([(-0.32 + k * 0.07, -0.18, 0.012), (-0.33 + k * 0.07, -0.26, 0.04), (-0.34 + k * 0.07, -0.3, 0.012)], 0.01, 0.008, bn, seg=5)
	pry_bar((0.75, -0.62, 0.012), (0.95, -0.25, 0.012))
	# his leather satchel, spilled
	B((0.26, 0.12, 0.16), (-0.6, -0.48, 0.08), LEA("b"), bevel=0.03, rot=(0, 0, 20))
	B((0.24, 0.13, 0.03), (-0.6, -0.47, 0.17), LEA(), bevel=0.01, rot=(18, 0, 20))
	kit.ring(0.012, 0.005, (-0.58, -0.56, 0.12), CU("b"), seg=8)
	for k, (x, y) in enumerate(((-0.36, -0.58), (-0.3, -0.66), (-0.42, -0.7), (-0.22, -0.6), (-0.5, -0.72))):
		coin((x, y, 0.0035), GOLD(J(0.05)))
	goblet(-0.78, -0.3, 0.0, s=1.0, m=GOLD())
	rough_chips([(0.85, 0.3, 0.035), (-0.9, -0.1, 0.03), (0.2, 0.35, 0.025)])


def drum(L, r, m):
	"""A fluted column drum lying along X, centred on the origin."""
	d = kit.cylinder(r, L, (0, 0, 0), m, rot=(0, 90, 0), verts=24, bevel=0.0)
	cuts = []
	for k in range(12):
		a = 2 * math.pi * k / 12
		cuts.append(B((L + 0.1, 0.035, 0.035), (0, math.cos(a) * r, math.sin(a) * r), S("c"), bevel=0, rot=(math.degrees(a) + 45, 0, 0)))
	carve(d, cuts)
	return d


def th_pillar_fallen():
	m = S("b")
	foot((0.7, 0.7, 0.1), (-0.7, 0.2, 0.05), tone=S("c"), bevel=0.02)
	B((0.6, 0.6, 0.12), (-0.7, 0.2, 0.15), S("a"), bevel=0.015)
	stump = group(lambda: drum(0.55, 0.22, m), at=(-0.7, 0.2, 0.2 + 0.275), rot=(0, 90, 0))
	for k in range(7):  # broken top of the stump
		a = 2 * math.pi * k / 7
		kit.gem((-0.7 + math.cos(a) * 0.13, 0.2 + math.sin(a) * 0.13, 0.75 + J(0.02)), (0.09, 0.08, 0.05 + 0.04 * (k % 2)), m, seed=k + 60)
	for i, (x, y, L, rz) in enumerate(((0.05, -0.05, 0.55, 8), (0.75, -0.2, 0.5, -6))):
		g = group(lambda L=L: drum(L, 0.22, S("b" if i else "c")), at=(x, y, 0.22), rot=(0, 0, rz))
		for e in (-1, 1):
			c = Vector((x, y, 0.22)) + Matrix.Rotation(math.radians(rz), 3, "Z") @ Vector((e * L / 2, 0, 0))
			if (i, e) in ((0, -1), (1, 1)):
				kit.gem(tuple(c), (0.04, 0.15, 0.15), m, seed=i * 3 + e + 70)
	cap = B((0.17, 0.56, 0.56), (1.35, 0.4, 0.28), S("a"), bevel=0.02, rot=(0, 0, 12))  # the capital, fallen on its side
	rough_chips([(-0.25, -0.3, 0.05), (0.4, 0.25, 0.04), (1.1, -0.2, 0.035), (-0.3, 0.6, 0.03), (1.05, 0.05, 0.04)])


def th_mourning_bench():
	for s_ in (-1, 1):
		leg = B((0.24, 0.42, 0.38), (s_ * 0.6, 0, 0.19), S("b"), bevel=0.015)
		carve(leg, helm_emblem(s_ * 0.6, 0.23, 0.06, -0.21, w=0.01))
		B((0.3, 0.46, 0.05), (s_ * 0.6, 0, 0.025), S("c"), bevel=0.012)
	seat = B((1.65, 0.48, 0.1), (0, 0, 0.425), S("a"), bevel=0.015)
	carve(seat, runes(-0.4, 0.4, 0.425, -0.24, h=0.045, w=0.01, gap=0.045, depth=0.007, under=False))
	for s_ in (-1, 1):
		B((0.14, 0.46, 0.14), (s_ * 0.76, 0, 0.54), S("b"), bevel=0.02)
		kit.cylinder(0.075, 0.5, (s_ * 0.76, 0, 0.62), S("c"), rot=(90, 0, 0), verts=12, bevel=0.01)
	goblet(0.3, -0.04, 0.472, s=1.1)
	candle(-0.25, 0.08, 0.472, 0.025, 0.05, lit=False)


def dagger(L=0.32):
	prism([(0, 0.0), (0.02, 0.02), (0.018, L * 0.6), (0, L * 0.65 + 0.03), (-0.018, L * 0.6), (-0.02, 0.02)], -0.006, 0.006, SILV("a"), axis="y")
	B((0.1, 0.02, 0.018), (0, 0, -0.005), CU("b"), bevel=0.004)
	log((0, 0, -0.012), (0, 0, -0.1), 0.012, LEA(), seg=6, rings=1, ends=False, bend=0)
	sphere((0, 0, -0.108), 0.018, CU("b"), seg=8, rings=5)


def th_offering_table():
	for s_ in (-1, 1):
		leg = kit.taper(0.26, 0.6, 0.18, 0.5, 0.62, (s_ * 0.5, 0, 0.06), S("b"), bevel=0.0)
		carve(leg, helm_emblem(s_ * 0.5, 0.42, 0.05, -0.27, w=0.01, depth=0.02))
		B((0.32, 0.66, 0.06), (s_ * 0.5, 0, 0.03), S("c"), bevel=0.012)
	B((0.85, 0.12, 0.1), (0, 0, 0.3), S("c"), bevel=0.012)  # stretcher
	top = B((1.4, 0.7, 0.1), (0, 0, 0.725), S("a"), bevel=0.015)
	carve(top, runes(-0.55, 0.55, 0.725, -0.35, h=0.05, w=0.01, gap=0.05, depth=0.007, under=False))
	z = 0.775
	for x in (-0.4, 0.0, 0.4):  # back row: three cups
		goblet(x, 0.2, z - 0.002, s=1.15, m=GOLD() if x == 0 else SILV("a"))
	for k, x in enumerate((-0.45, -0.15, 0.15, 0.45)):  # middle row: coin stacks
		h = 0.03 + 0.012 * (k % 3)
		kit.cylinder(0.026, h, (x, 0.03, z + h / 2 - 0.002), GOLD(-0.04), verts=12, bevel=0.002)
		for j in range(int(h / 0.012)):
			kit.ring(0.026, 0.0025, (x, 0.03, z + 0.006 + j * 0.012), GOLD(0.02), seg=12)
	kit.cylinder(0.1, 0.014, (-0.38, -0.18, z + 0.005), CU("b"), verts=16, bevel=0.004)  # ring dish
	kit.ring(0.098, 0.006, (-0.38, -0.18, z + 0.012), CU("dark"), seg=16)
	kit.ring(0.03, 0.007, (-0.38, -0.18, z + 0.017), GOLD(), seg=14)
	sphere((-0.35, -0.18, z + 0.024), 0.012, C((0.06, 0.15, 0.5), 0.2), seg=8, rings=5)
	group(lambda: dagger(), at=(0.05, -0.18, z + 0.006), rot=(-90, 0, 80))
	group(lambda: hammer(0.32, s=0.4), at=(0.28, -0.17, z + 0.012), rot=(90, 0, 90))


def th_wall_lamp():
	foot((0.56, 0.3, 0.08), (0, -0.06, 0.04), tone=S("c"), bevel=0.015)
	st = B((0.46, 0.12, 1.75), (0, 0.0, 0.08 + 0.875), S("b"), bevel=0.012)
	carve(st, helm_emblem(0, 1.0, 0.09, -0.06) + runes(-0.15, 0.15, 0.7, -0.06, h=0.05, gap=0.045) + runes(-0.15, 0.15, 0.58, -0.06, h=0.05, gap=0.045, under=False))
	B((0.52, 0.16, 0.06), (0, -0.01, 1.85), S("a"), bevel=0.012)
	kit.taper(0.16, 0.08, 0.22, 0.26, 0.14, (0, -0.07, 1.46), S("a"), bevel=0.012)  # corbel
	B((0.03, 0.03, 0.1), (0, -0.17, 1.55), IRON("dark"), bevel=0.004)
	kit.ring(0.025, 0.007, (0, -0.17, 1.5), IRON("a"), rot=(0, 90, 0), seg=10)
	chain((0, -0.17, 1.47), (0, -0.17, 1.22), link=0.026, wire=0.007)
	z = 1.12
	kit.ring(0.03, 0.007, (0, -0.17, z + 0.085), IRON("a"), rot=(0, 90, 0), seg=10)
	for k in range(3):
		a = 2 * math.pi * k / 3 + 0.5
		rod((0, -0.17, z + 0.075), (math.cos(a) * 0.09, -0.17 + math.sin(a) * 0.09, z + 0.03), 0.005, IRON("dark"), seg=5)
	lathe([(0.02, 0), (0.07, 0.01), (0.1, 0.03), (0.105, 0.045), (0.09, 0.04)], (0, -0.17, z - 0.02), CU("b"), seg=16)
	prism([(0.08, -0.2), (0.16, -0.18), (0.16, -0.16), (0.08, -0.14)], z + 0.012, z + 0.024, CU("b"), axis="z")  # spout
	B((0.006, 0.006, 0.02), (0.15, -0.17, z + 0.03), kit.mat("charcoal"), bevel=0)
	kit.flame((0.15, -0.17, z + 0.038), 0.014, 0.06, FLAME(), twist=20)
	flat_back(0.06)


MODELS = {k: v for k, v in globals().items() if k.startswith("th_") and callable(v)}

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
