# Decor set QB (Nov 21): THE QUIET BARROWS, a MEDIUM dungeon in cut stone (Stonehold style): the long, low burial
# passages of ordinary dwarf families. Humble and old, not a lord's tomb. One stone family (limestone), clay urns,
# one wood family, plain iron and a little copper. Every carving is CUT INTO the stone (boolean, dark groove walls).
#   blender --background --factory-startup --python builds/decor_nov21_qb.py -- [id ...]   (none = all)
# Output: assets/models/decor/<id>.glb (origin bottom-centre, front faces -Y). Wall pieces: flat back at +Y, they
# stand on the floor on their own plinth.
#
# The 30 objects:
#  qb_loculus_wall      (wall) six burial niches in a cut-stone wall, each sealed with a carved name-stone, little offerings on the sills
#  qb_loculus_open      (story, wall) a family niche opened for a new burial: its name-stone leans below, mortar tub and trowel ready
#  qb_loculus_collapsed (story, wall) a name-stone fell and broke on the floor; a crack runs down the wall; old bones show in the niche
#  qb_urn_shelves       (wall) three stone shelves on corbels, full of lidded clay family urns with cords and bone name-tags
#  qb_crest_hammers     (wall) a family crest stele: shield plaque with two crossed hammers cut in, names below, a candle ledge
#  qb_crest_mountain    (wall) a family crest stele: round plaque with the mountain sign, cord moulding, two clay lamps on chains hanging straight off iron hooks
#  qb_lamp_alcove       (wall) an arched lamp alcove cut into a wall block: lit clay oil lamp, oil jug, tinder box on the sill
#  qb_candle_ledge      (wall) a long stone ledge on three corbels with a row of candles of every height, wax runs down the edge
#  qb_ossuary_wall      (wall) bone-ordered ossuary wall: bands of stacked long bones (ends out) and rows of skulls in a stone frame
#  qb_family_shrine     (wall) a small family shrine: pedestal, columned niche with a carved ancestor bust, cups and candles
#  qb_name_roll         (story, wall) a family name tablet: rows of names cut in, the newest only half cut, chisels and mallet left
#  qb_digger_tool_wall  (wall) the gravedigger's rack on a stone wall: spade, pick, rope coil, lantern on pegs; a broom leaning
#  qb_sealed_passage    (wall) an arched passage walled up: voussoirs, rough infill, carved seal plaque, chain and padlock
#  qb_vault_gate        (wall) a round family-vault opening, pitch-black beyond, with an iron grille gate, hinges, hasp and padlock, crest keystone
#  qb_mourners_bench    a plain stone mourners' bench with a kneeling step (knee hollows), a lit lantern, cup and walking stick
#  qb_floor_slab        a floor grave: carved slab in a kerb of six stones, lift ring, candle stubs in iron cups at the head
#  qb_cairn_grave       a humble barrow grave of stepped cut stones with a carved headstone, a cup and token stones on top
#  qb_headstone_row     three family headstones of different ages on one kerb: one cracked, one leaning, tokens and a lamp
#  qb_urn_pedestal      a turned stone pedestal holding one big lidded family urn, a copper cup and tokens
#  qb_urn_cart          (story) a two-wheeled hand cart that brought urns down: urns in their slots, one already set on the floor
#  qb_digger_rest       (story) the gravedigger's corner: stool, barrel table with lantern, mug and tally slate, spade, pick, rope
#  qb_mason_bench       (story) the name-cutter's bench: a name-stone half carved, chisels, mallet, square, blank stones waiting
#  qb_kneeler_stele     a small prayer stele with a crest roundel, candle ledge and a worn kneeling step
#  qb_bier_trestles     the families' wooden bier (poles, slats, rope loops) resting empty on two carved stone trestles
#  qb_bone_chest        a stone ossuary chest, lid slid aside: long bones laid in rows and two skulls inside, carved front
#  qb_waymarker         a passage marker post with row runes cut in, iron arm and a hanging lit lantern
#  qb_token_pillar      a short octagonal pillar where visitors leave small cut stones: tokens in its dish and on its step
#  qb_incense_stand     a stone stand with a copper incense bowl and pierced lid, tongs and a little box of incense cakes
#  qb_wash_basin        the mourners' hand basin (empty) on a turned pedestal, a clay jug beside it
#  qb_ancestor_bust     a family founder's carved bust (the game's dwarf, cap and braided beard) on a tall plinth with crest and names, tokens and a candle
import math
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from night_stations import B, GAME, J, T, kit, log, rng  # noqa: E402
from night_materials import C, sphere, _cm  # noqa: E402
from decor_nov21_a import bar, chain, circ, low_z, prism, rod, shift, slim  # noqa: E402
from decor_nov21_b import bone, skull, coin  # noqa: E402
from decor_nov21_d import tube  # noqa: E402
from decor_nov21_f import glass, lathe as hlathe  # noqa: E402
from decor_nov21_th import (BONE, CU, FLAME, GROOVE, IRON, WAX, beard, candle, carve, cy, face, flat_back, gline,  # noqa: E402
	group, lathe, real_dwarf, ring_at, runes)

S = lambda v=None: T("limestone", v or rng.choice("abc"))  # noqa: E731  (the one stone family)
CLAY = lambda v=None: T("clay", v or rng.choice("abc"))  # noqa: E731
WD = lambda v=None: T("wood", v or rng.choice("abc"))  # noqa: E731  (the one wood family)
ROPE = lambda: kit.tex_mat("rope", "a")  # noqa: E731
MORT = lambda: C((0.03, 0.026, 0.022), 1.0)  # noqa: E731  (dark joints and backing)
MORTAR = lambda: C((0.3, 0.28, 0.25), 0.95)  # noqa: E731  (wet grey mortar in a tub)
_BONE = BONE
BONE = lambda s=0.0: _BONE(s - 0.22)  # noqa: E731  (old bones: darker than the pale limestone)
VOID = lambda: C((0.0, 0.0, 0.0), 1.0)  # noqa: E731  (the black of an unlit vault)
YF = -0.12  # front face of every wall's blocks; backing y 0..0.1, back flat at y = 0.1


# ================= helpers =================
def sb(size, loc, v=None, bevel=0.012, rot=(0, 0, 0)):
	return B(size, loc, S(v), bevel=bevel, rot=rot)


def drop(objs_, z=0.0):
	"""Move a group so its lowest point rests at z."""
	shift(objs_, (0, 0, z - low_z(objs_)))
	return objs_


def ashlar(x0, x1, rows, holes=(), yf=YF, gap=0.014):
	"""Cut-stone blocks in courses (z boundaries `rows`), half-bond, pressed into the backing. holes = (xa, xb, za, zb)."""
	out = []
	for i, (za, zb) in enumerate(zip(rows, rows[1:])):
		cuts = sorted((xa, xb) for xa, xb, ha, hb in holes if ha < zb - 1e-3 and hb > za + 1e-3)
		spans, x = [], x0
		for xa, xb in cuts:
			if xa > x + 0.02:
				spans.append((x, xa))
			x = max(x, xb)
		if x < x1 - 0.02:
			spans.append((x, x1))
		for sa, sb_ in spans:
			L = sb_ - sa
			n = max(1, round(L / 0.42))
			if i % 2 and L > 0.6:
				edges = [sa] + [sa + L * (k + 0.5) / n + J(0.03) for k in range(n)] + [sb_]
			else:
				edges = [sa] + [sa + L * k / n + J(0.03) for k in range(1, n)] + [sb_]
			for a, b in zip(edges, edges[1:]):
				f = yf + J(0.005)
				out.append(sb((b - a - gap, 0.005 - f, zb - za - gap), ((a + b) / 2, (f + 0.005) / 2, (za + zb) / 2)))
	return out


def wall_kit(w, h, holes=(), rows=None, flutes=True):
	"""A cut-stone wall piece: dark backing, ashlar courses, plinth, end pilasters, cornice. Returns a dict of parts."""
	B((w - 0.01, 0.1, h - 0.2), (0, 0.05, 0.125 + (h - 0.2) / 2), MORT(), bevel=0.004)
	plinth = sb((w + 0.08, 0.265, 0.13), (0, -0.0375, 0.065), "c", bevel=0.015)
	cornice = sb((w + 0.08, 0.265, 0.09), (0, -0.0375, h - 0.045), "a", bevel=0.015)
	sb((w + 0.02, 0.06, 0.035), (0, -0.19, h - 0.1), "b", bevel=0.008)  # thin moulding under the cornice
	pil = []
	for s_ in (-1, 1):
		p = sb((0.14, 0.255, h - 0.21), (s_ * (w / 2 - 0.02), -0.0325, 0.125 + (h - 0.21) / 2), "b", bevel=0.014)
		if flutes:
			carve(p, [cy(bar((s_ * (w / 2 - 0.02), 0.2), (s_ * (w / 2 - 0.02), h - 0.2), 0.022), -0.16, 0.01)])
		pil.append(p)
	rows = rows or [0.13 + k * (h - 0.22) / round((h - 0.22) / 0.24) for k in range(round((h - 0.22) / 0.24) + 1)]
	blocks = ashlar(-w / 2 + 0.05, w / 2 - 0.05, rows, holes)
	return {"plinth": plinth, "cornice": cornice, "pil": pil, "blocks": blocks}


def crest(kind, cx, cz, s, yf, w=0.012, d=0.008):
	"""A family sign, cut in: hammers / mountain / anvil / axe / pick."""
	cuts = []
	if kind == "hammers":
		sh = [(cx - s * 0.8, cz + s * 0.9), (cx + s * 0.8, cz + s * 0.9), (cx + s * 0.8, cz - s * 0.1), (cx, cz - s), (cx - s * 0.8, cz - s * 0.1)]
		cuts += gline(sh + [sh[0]], w, yf, d)
		for k in (-1, 1):
			a, b = Vector((cx + k * s * 0.45, cz - s * 0.55)), Vector((cx - k * s * 0.4, cz + s * 0.5))
			n = Vector((-(b - a).y, (b - a).x)).normalized()
			cuts.append(cy(bar(tuple(a), tuple(b), w * 1.1), yf, d))
			cuts.append(cy(bar(tuple(b - n * s * 0.2), tuple(b + n * s * 0.2), s * 0.16), yf, d))
	elif kind == "mountain":
		cuts += gline([(cx + math.cos(a) * s, cz + math.sin(a) * s) for a in [2 * math.pi * k / 18 for k in range(19)]], w, yf, d)
		cuts += gline([(cx - s * 0.75, cz - s * 0.45), (cx - s * 0.3, cz + s * 0.35), (cx - s * 0.05, cz), (cx + s * 0.3, cz + s * 0.6),
			(cx + s * 0.75, cz - s * 0.45), (cx - s * 0.75, cz - s * 0.45)], w, yf, d)
		cuts.append(cy(circ(cx + s * 0.3, cz - s * 0.3, s * 0.12, n=8, wob=0) , yf, d))  # the mine door
	elif kind == "anvil":
		cuts.append(cy([(cx - s * 0.85, cz + s * 0.35), (cx + s * 0.6, cz + s * 0.35), (cx + s * 0.9, cz + s * 0.15), (cx + s * 0.3, cz + s * 0.05),
			(cx + s * 0.2, cz - s * 0.35), (cx + s * 0.45, cz - s * 0.6), (cx - s * 0.45, cz - s * 0.6), (cx - s * 0.2, cz - s * 0.35),
			(cx - s * 0.3, cz + s * 0.05), (cx - s * 0.85, cz + s * 0.15)], yf, d))
		cuts += gline([(cx - s * 0.2, cz + s * 0.6), (cx, cz + s * 0.85)], w * 0.8, yf, d)  # sparks
		cuts += gline([(cx + s * 0.25, cz + s * 0.58), (cx + s * 0.45, cz + s * 0.8)], w * 0.8, yf, d)
	elif kind == "axe":
		cuts.append(cy(bar((cx, cz - s), (cx, cz + s * 0.85), w * 1.2), yf, d))
		cuts.append(cy([(cx, cz + s * 0.8), (cx + s * 0.3, cz + s * 0.95), (cx + s * 0.6, cz + s * 1.0), (cx + s * 0.7, cz + s * 0.6),
			(cx + s * 0.62, cz + s * 0.1), (cx + s * 0.35, cz + s * 0.25), (cx, cz + s * 0.4)], yf, d))
		cuts += gline([(cx - s * 0.12, cz + s * 0.95), (cx, cz + s * 0.85), (cx - s * 0.12, cz + s * 0.3)], w * 0.8, yf, d)
		cuts += gline([(cx - s * 0.2, cz - s * 0.6), (cx + s * 0.2, cz - s * 0.6)], w, yf, d)
	else:  # pick
		cuts.append(cy(bar((cx, cz - s), (cx, cz + s * 0.6), w * 1.2), yf, d))
		cuts += gline([(cx - s * 0.8, cz + s * 0.35), (cx - s * 0.4, cz + s * 0.65), (cx, cz + s * 0.72), (cx + s * 0.4, cz + s * 0.65),
			(cx + s * 0.8, cz + s * 0.35)], w * 1.3, yf, d)
	return cuts


KINDS = ("hammers", "mountain", "anvil", "axe", "pick")


def name_stone(x, z0, w, h, kind, yf=-0.105, pins=True, v=None):
	"""A loculus name-stone: slab pressed into the backing, family sign and two rows of names cut in, iron pins."""
	sl = sb((w, 0.11, h), (x, yf + 0.055, z0 + h / 2), v, bevel=0.01)
	cuts = crest(kind, x - w * 0.33, z0 + h / 2, min(h, w) * 0.3, yf, w=0.01, d=0.007)
	cuts += gline([(x - w * 0.16, z0 + 0.04), (x - w * 0.16, z0 + h - 0.04)], 0.008, yf, 0.006)
	for k, zz in enumerate((0.66, 0.36)):
		cuts += runes(x - w * 0.1, x + w * 0.44 - k * 0.08, z0 + h * zz, yf, h=0.05, w=0.009, gap=0.045, depth=0.006, under=False)
	carve(sl, cuts)
	if pins:
		for sx in (-1, 1):
			for sz in (-1, 1):
				kit.rivet((x + sx * (w / 2 - 0.035), yf, z0 + h / 2 + sz * (h / 2 - 0.035)), IRON("dark"), r=0.011)
	return sl


def niche_trim(xa, xb, z0, z1, lintel_runes=True):
	"""Sill and lintel stones round a wall opening, pressed into the blocks."""
	x = (xa + xb) / 2
	sb((xb - xa + 0.07, 0.1, 0.05), (x, YF - 0.03, z0 - 0.02), "a", bevel=0.01)
	li = sb((xb - xa + 0.07, 0.05, 0.07), (x, YF - 0.01, z1 + 0.03), "a", bevel=0.01)
	if lintel_runes:
		carve(li, runes(x - (xb - xa) * 0.35, x + (xb - xa) * 0.35, z1 + 0.03, YF - 0.035, h=0.035, w=0.008, gap=0.04, depth=0.006, under=False))
	return li


URNS = (((0.05, 0), (0.07, 0.01), (0.1, 0.06), (0.11, 0.12), (0.09, 0.18), (0.05, 0.21), (0.055, 0.23)),
	((0.045, 0), (0.06, 0.01), (0.075, 0.08), (0.085, 0.17), (0.07, 0.22), (0.048, 0.24), (0.053, 0.26)),
	((0.06, 0), (0.08, 0.01), (0.11, 0.05), (0.112, 0.1), (0.085, 0.13), (0.065, 0.145), (0.07, 0.155)))


def r_at(prof, z):
	for (r0, z0), (r1, z1) in zip(prof, prof[1:]):
		if z0 <= z <= z1:
			return r0 + (r1 - r0) * (z - z0) / max(1e-6, z1 - z0)
	return prof[-1][0]


def urn(x, y, z, s=1.0, kind=0, v=None, lid=True, tag=True):
	"""A clay family urn: turned body, darker belly band, lid with knob, a cord at the neck with a bone name-tag."""
	prof = URNS[kind]
	m = CLAY(v)
	lathe([(r * s, h * s) for r, h in prof], (x, y, z), m, seg=16)
	rmax, zmax = max(prof)
	kit.ring(rmax * s, 0.0045 * s, (x, y, z + zmax * s), CLAY("dark"), seg=20)
	kit.ring(r_at(prof, zmax * 0.45) * s, 0.0035 * s, (x, y, z + zmax * 0.45 * s), CLAY("dark"), seg=18)
	tr, tz = prof[-1]
	if lid:
		lathe([(tr * s * 1.12, 0), (tr * s * 1.1, 0.012 * s), (tr * s * 0.7, 0.028 * s), (0.014 * s, 0.038 * s)], (x, y, z + tz * s - 0.003), CLAY("dark"), seg=16)
		sphere((x, y, z + tz * s + 0.042 * s), 0.015 * s, CLAY("dark"), seg=8, rings=5)
	nr, nz = prof[-2]
	kit.ring(nr * s + 0.002, 0.005 * s, (x, y, z + nz * s), ROPE(), seg=14)
	if tag:
		tzc = nz * s - 0.03 * s
		B((0.03 * s, 0.008, 0.04 * s), (x, y - r_at(prof, tzc / s) * s - 0.001, z + tzc), BONE(0.0), bevel=0.003)
		rod((x, y - nr * s - 0.004, z + nz * s), (x, y - r_at(prof, tzc / s) * s - 0.004, z + tzc + 0.018 * s), 0.003, ROPE())


def corbel(x, z_top, depth=0.2, w=0.12, h=0.2, y0=YF):
	"""A carved bracket under a shelf: stepped profile, pressed 1 cm into the wall."""
	return prism([(y0 + 0.01, z_top), (y0 - depth, z_top), (y0 - depth, z_top - 0.05), (y0 - depth + 0.06, z_top - 0.09),
		(y0 - depth * 0.35, z_top - h * 0.8), (y0 + 0.01, z_top - h)], x - w / 2, x + w / 2, S("a"), axis="x")


def oil_lamp(x, y, z, s=1.0, lit=True, rotz=0.0):
	"""A small clay oil lamp: round body, nozzle, ring handle, flame."""
	def build():
		m = CLAY("b")
		lathe([(0.025 * s, 0), (0.04 * s, 0.008 * s), (0.045 * s, 0.02 * s), (0.035 * s, 0.03 * s), (0.012 * s, 0.034 * s)], (0, 0, 0), m, seg=14)
		B((0.045 * s, 0.024 * s, 0.016 * s), (0.045 * s, 0, 0.02 * s), m, bevel=0.006 * s)
		kit.ring(0.013 * s, 0.0045 * s, (-0.047 * s, 0, 0.024 * s), m, rot=(90, 0, 0), seg=10)
		if lit:
			kit.flame((0.06 * s, 0, 0.026 * s), 0.01 * s, 0.04 * s, FLAME(), twist=10)
	return group(build, at=(x, y, z), rot=(0, 0, rotz))


def lantern(x, y, z, s=1.0, lit=True):
	"""An iron lantern: base, four posts, horn panes, candle, cap, ring. z = bottom."""
	m = IRON("dark")
	kit.cylinder(0.06 * s, 0.02 * s, (x, y, z + 0.01 * s), m, verts=8)
	for k in range(4):
		a = math.pi / 4 + k * math.pi / 2
		rod((x + math.cos(a) * 0.05 * s, y + math.sin(a) * 0.05 * s, z + 0.015 * s), (x + math.cos(a) * 0.05 * s, y + math.sin(a) * 0.05 * s, z + 0.17 * s), 0.006 * s, m, seg=5)
	B((0.075 * s, 0.075 * s, 0.14 * s), (x, y, z + 0.09 * s), glass((0.95, 0.75, 0.4), 0.45, 0.6 if lit else 0.0), bevel=0.003)
	kit.cylinder(0.014 * s, 0.05 * s, (x, y, z + 0.045 * s), WAX(), verts=8)
	if lit:
		kit.flame((x, y, z + 0.07 * s), 0.01 * s, 0.035 * s, FLAME(), twist=12)
	kit.cylinder(0.062 * s, 0.015 * s, (x, y, z + 0.17 * s), m, verts=8)
	kit.cone(0.055 * s, 0.015 * s, 0.05 * s, (x, y, z + 0.2 * s), m, verts=8)
	kit.ring(0.025 * s, 0.005 * s, (x, y, z + 0.245 * s), m, rot=(90, 0, 0), seg=10)


def chips(pts, z=0.0):
	"""Small angular limestone chips settled on a surface at z."""
	for k, (x, y, sz) in enumerate(pts):
		o = kit.gem((x, y, 0), (sz * 1.3, sz, sz * 0.6), S("abc"[k % 3]), seed=k + 7)
		o.location.z = z - min(v.co.z for v in o.data.vertices) - 0.002


def tokens(pts, z=0.0):
	"""Visitors' tokens: small cut stones, each a bevelled block, settled on a surface at z."""
	for k, (x, y, sz) in enumerate(pts):
		B((sz * (1.2 + J(0.2)), sz * (0.9 + J(0.15)), sz * 0.7), (x, y, z + sz * 0.33), S("abc"[k % 3]), bevel=sz * 0.2, rot=(0, 0, rng.uniform(0, 90)))


def spade(L=1.0):
	prism([(0, 0), (-0.085, 0.03), (-0.095, 0.24), (0.095, 0.24), (0.085, 0.03)], -0.006, 0.006, IRON("a"))
	B((0.2, 0.022, 0.025), (0, 0, 0.245), IRON("dark"), bevel=0.004)
	kit.cylinder(0.024, 0.09, (0, 0, 0.3), IRON("dark"), verts=8)
	for k in (-1, 1):
		kit.rivet((0, k * 0.02, 0.31), IRON("dark"), r=0.008)
	rod((0, 0, 0.27), (0, 0, L - 0.09), 0.019, WD("b"))
	B((0.13, 0.03, 0.03), (0, 0, L), WD("b"), bevel=0.008)
	for k in (-1, 1):
		rod((k * 0.012, 0, L - 0.11), (k * 0.055, 0, L - 0.005), 0.012, WD("b"))
	kit.ring(0.022, 0.005, (0, 0, L - 0.11), IRON("dark"), seg=10)


def pickaxe(L=0.85):
	rod((0, 0, 0), (0, 0, L + 0.04), 0.02, WD("b"))
	kit.cylinder(0.032, 0.07, (0, 0, L), IRON("dark"), verts=8)
	for k in (-1, 1):
		tube([(0, 0, L), (k * 0.14, 0, L + 0.01), (k * 0.28, 0, L - 0.05)], 0.026, 0.006, IRON("a"), seg=6)
	for k in range(3):
		kit.ring(0.021, 0.004, (0, 0, 0.06 + k * 0.03), kit.tex_mat("leather", "dark"), seg=10)


def mallet(L=0.3):
	rod((0, 0, 0), (0, 0, L), 0.014, WD("b"))
	kit.cylinder(0.05, 0.15, (0, 0, L + 0.04), WD("dark"), rot=(0, 90, 0), verts=12, bevel=0.008)
	for k in (-1, 1):
		kit.ring(0.049, 0.006, (k * 0.065, 0, L + 0.04), IRON("dark"), rot=(0, 90, 0), seg=14)


def chisel(L=0.22):
	kit.cylinder(0.009, L * 0.75, (0, 0, L * 0.25 + L * 0.375), IRON("a"), verts=8)
	prism([(-0.009, L * 0.26), (0.009, L * 0.26), (0.012, 0.0), (-0.012, 0.0)], -0.003, 0.003, IRON("a"))
	kit.cylinder(0.012, 0.012, (0, 0, L + 0.004), IRON("dark"), verts=8)


def trowel():
	"""A mason's trowel lying flat: diamond blade, cranked tang, wooden handle (origin under the blade)."""
	prism([(0, -0.1), (0.05, 0.0), (0, 0.06), (-0.05, 0.0)], 0.0, 0.004, IRON("a"), axis="z")
	tube([(0, 0.055, 0.003), (0, 0.075, 0.035), (0, 0.095, 0.04)], 0.005, 0.005, IRON("dark"), seg=5)
	rod((0, 0.09, 0.04), (0, 0.2, 0.045), 0.012, WD("b"))


def tub(x, y, r, h, fill=None, z=0.0):
	"""A hollow wooden tub (staves look) with two iron hoops; optional flat fill at fraction `fill` of h."""
	_hl = hlathe([(0, 0), (r * 0.88, 0), (r, h), (r - 0.014, h), (r * 0.88 - 0.014, 0.014), (0, 0.014)], (x, y), WD("b"), seg=18)
	_hl.location.z += z
	for t in (0.25, 0.8):
		kit.ring(r * 0.88 + r * 0.12 * t + 0.003, 0.006, (x, y, z + h * t), IRON("dark"), seg=20)
	if fill:
		rf = r * 0.88 - 0.014 + (r * 0.12) * fill + 0.003
		kit.cylinder(rf, 0.01, (x, y, z + h * fill), MORTAR(), verts=18, bevel=0.002)


def barrel(x, y, r=0.24, h=0.62):
	prof = [(r * 0.85, 0), (r * 0.95, h * 0.2), (r, h * 0.5), (r * 0.95, h * 0.8), (r * 0.85, h)]
	lathe(prof, (x, y, 0), WD("b"), seg=18)
	for t in (0.08, 0.3, 0.7, 0.92):
		kit.ring(r_at(prof, h * t) + 0.003, 0.008, (x, y, h * t), IRON("dark"), seg=20)
	for k in range(3):  # lid planks
		B((0.12, r * 1.55 - abs(k - 1) * 0.08, 0.02), (x - 0.125 + k * 0.125, y, h + 0.006), WD("abc"[k]), bevel=0.004)


def hammers_slab(x, z0, w, h, kind, yf, half=False):
	"""A lying-flat name-stone builder helper: carved standing at the origin; returns nothing (use in group)."""
	sl = sb((w, 0.07, h), (0, yf + 0.035, h / 2), bevel=0.01)
	cuts = crest(kind, -w * 0.3, h / 2, h * 0.3, yf)
	if half:
		cuts += runes(-w * 0.08, w * 0.12, h * 0.66, yf, h=0.05, w=0.009, gap=0.045, depth=0.006, under=False)
		for zz in (0.66, 0.36):  # scribed guide lines, not yet cut
			cuts += gline([(-w * 0.1, h * zz - 0.03), (w * 0.44, h * zz - 0.03)], 0.004, yf, 0.002)
			cuts += gline([(-w * 0.1, h * zz + 0.03), (w * 0.44, h * zz + 0.03)], 0.004, yf, 0.002)
	else:
		for k, zz in enumerate((0.66, 0.36)):
			cuts += runes(-w * 0.08, w * 0.42 - k * 0.08, h * zz, yf, h=0.05, w=0.009, gap=0.045, depth=0.006, under=False)
	carve(sl, cuts)


def lay_flat(build, at, rotz=0.0):
	"""Build something standing (front -Y), then lay it on its back so the front faces up, on the floor at `at`."""
	g = group(build, at=at, rot=(-90, 0, rotz))
	return drop(g, at[2])


# ================= wall pieces =================
def qb_loculus_wall():
	w, h = 1.8, 1.95
	nz = ((0.32, 0.66), (0.82, 1.16), (1.32, 1.66))
	nx = ((-0.76, -0.1), (0.1, 0.76))
	holes = [(xa, xb, za, zb) for za, zb in nz for xa, xb in nx]
	wall_kit(w, h, holes, rows=[0.13, 0.32, 0.66, 0.82, 1.16, 1.32, 1.66, 1.85])
	for i, (z0, z1) in enumerate(nz):
		for j, (xa, xb) in enumerate(nx):
			x = (xa + xb) / 2
			niche_trim(xa, xb, z0, z1)
			name_stone(x, z0 + 0.012, xb - xa - 0.03, z1 - z0 - 0.024, KINDS[(i * 2 + j) % 5])
	sill = lambda z0: z0 + 0.005  # noqa: E731
	oil_lamp(-0.62, -0.17, sill(0.32), lit=True)
	tokens([(-0.25, -0.17, 0.03), (-0.2, -0.165, 0.025)], sill(0.32))
	coin((0.55, -0.17, sill(0.32) + 0.004))
	candle(0.24, -0.17, sill(0.82), 0.018, 0.07, lit=False)
	oil_lamp(-0.35, -0.17, sill(1.32), lit=False, rotz=20)
	tokens([(0.62, -0.17, 0.028)], sill(1.32))
	flat_back(0.1)


def qb_loculus_open():
	w, h = 1.4, 1.65
	wall_kit(w, h, [(-0.34, 0.34, 0.42, 0.78), (-0.34, 0.34, 1.0, 1.34)], rows=[0.13, 0.42, 0.78, 1.0, 1.34, 1.56])
	niche_trim(-0.34, 0.34, 0.42, 0.78)
	niche_trim(-0.34, 0.34, 1.0, 1.34)
	name_stone(0, 1.012, 0.65, 0.316, "anvil")
	sb((0.66, 0.11, 0.02), (0, -0.05, 0.43), "c", bevel=0.004)  # the open niche's floor, dark behind
	oil_lamp(0.27, -0.17, 0.425, lit=True, rotz=180)
	# its own name-stone, carved and waiting, leans against the wall below
	lay = lambda: hammers_slab(0, 0, 0.62, 0.33, "anvil", -0.07)  # noqa: E731
	group(lambda: lay(), at=(0.0, -0.205 + 0.07, 0.003), rot=(-15, 0, 0))
	# the mason's mortar tub, trowel across its rim, spare pins
	tub(-0.5, -0.5, 0.17, 0.2, fill=0.65)
	group(trowel, at=(-0.5, -0.52, 0.136), rot=(0, 0, 70))
	for k in range(3):
		rod((0.42 + k * 0.035, -0.42, 0.006), (0.45 + k * 0.035, -0.5, 0.006), 0.006, IRON("dark"))
	group(lambda: chisel(0.2), at=(0.55, -0.32, 0.012), rot=(90, 0, 100))
	chips([(0.2, -0.36, 0.02), (-0.2, -0.33, 0.015)])
	flat_back(0.1)


def qb_loculus_collapsed():
	w, h = 1.45, 1.4
	wk = wall_kit(w, h, [(-0.62, -0.04, 0.5, 0.84), (0.04, 0.62, 0.5, 0.84)], rows=[0.13, 0.3, 0.5, 0.84, 1.07, 1.31])
	niche_trim(-0.62, -0.04, 0.5, 0.84)
	li = niche_trim(0.04, 0.62, 0.5, 0.84, lintel_runes=False)
	name_stone(-0.33, 0.512, 0.55, 0.316, "mountain")
	crack = [(0.42, 1.3), (0.36, 1.18), (0.4, 1.08), (0.31, 0.95), (0.35, 0.86)]
	for b in wk["blocks"] + [li]:
		bb = [b.matrix_world @ Vector(c) for c in b.bound_box]
		if min(v.z for v in bb) < 1.3 and max(v.z for v in bb) > 0.86 and min(v.x for v in bb) < 0.45 and max(v.x for v in bb) > 0.3:
			carve(b, gline(crack, 0.014, YF - (0.035 if b is li else 0), 0.016))
	sb((0.56, 0.11, 0.02), (0.33, -0.05, 0.51), "c", bevel=0.004)  # niche floor
	skull((0.22, -0.04, 0.52 + 0.11), 0.95, BONE(-0.05), face=(0.4, -1, 0))
	bone((0.34, -0.03, 0.535), (0.58, 0.02, 0.535), 0.016, BONE(-0.08))
	bone((0.36, -0.07, 0.535), (0.56, -0.04, 0.57), 0.015, BONE(0.0))
	# the fallen name-stone, broken in three, its names still readable
	L1, L2 = [(0.22, 0), (0.18, 0.14), (0.26, 0.32)], [(0.42, 0), (0.36, 0.17), (0.44, 0.32)]
	parts = ([(0, 0)] + L1 + [(0, 0.32)], [(0.22, 0), (0.42, 0), (0.36, 0.17), (0.44, 0.32), (0.26, 0.32), (0.18, 0.14)],
		[(0.42, 0), (0.56, 0), (0.56, 0.32), (0.44, 0.32), (0.36, 0.17)])

	def piece(pts, k):
		def build():
			cx = sum(p[0] for p in pts) / len(pts)
			o = B((0.56, 0.07, 0.32), (0.28 - cx, -0.035, 0.16), S("b"), bevel=0.0)
			carve(o, runes(0.2 - cx, 0.52 - cx, 0.21, -0.07, h=0.05, w=0.009, gap=0.045, depth=0.006, under=False)
				+ runes(0.2 - cx, 0.45 - cx, 0.11, -0.07, h=0.05, w=0.009, gap=0.045, depth=0.006, under=False)
				+ crest("hammers", 0.09 - cx, 0.16, 0.08, -0.07, w=0.01))
			keep = prism([(px - cx, pz) for px, pz in pts], -0.1, 0.03, S("b"))
			m = o.modifiers.new("keep", "BOOLEAN")
			m.operation, m.object, m.solver = "INTERSECT", keep, "EXACT"
			bpy.context.view_layer.objects.active = o
			bpy.ops.object.modifier_apply(modifier=m.name)
			bpy.data.objects.remove(keep, do_unlink=True)
		return build
	for k, (pts, at, rz) in enumerate(zip(parts, ((-0.02, -0.56, 0), (0.3, -0.52, 0), (0.64, -0.47, 0)), (8, -10, 20))):
		lay_flat(piece(pts, k), at, rotz=rz)
	chips([(0.15, -0.3, 0.03), (0.45, -0.28, 0.022), (0.7, -0.35, 0.018), (-0.1, -0.38, 0.015)])
	flat_back(0.1)


def qb_urn_shelves():
	w, h = 1.5, 1.85
	wall_kit(w, h)
	for i, z in enumerate((0.5, 0.95, 1.4)):
		sh = sb((1.3, 0.25, 0.06), (0, YF - 0.115, z), "a", bevel=0.012)
		carve(sh, runes(-0.5, 0.5, z, YF - 0.24, h=0.03, w=0.007, gap=0.05, depth=0.005, under=False))
		for x in (-0.55, 0.0, 0.55):
			corbel(x, z - 0.03, depth=0.2, h=0.18)
		x = -0.6
		k = 0
		while True:
			kind, s = (k + i) % 3, 0.85 + ((k * 7 + i * 3) % 4) * 0.09
			rw = max(r for r, _ in URNS[kind]) * s
			if x + rw * 2 > 0.62:
				break
			urn(x + rw, YF - 0.12 + J(0.015), z + 0.03, s=s, kind=kind)
			x += rw * 2 + 0.035
			k += 1
	flat_back(0.1)


def stele(w, h, d=0.14):
	"""A standing slab on a foot stone with a moulded frame and a cap. Returns (slab, front y)."""
	sb((w + 0.14, d + 0.2, 0.1), (0, -0.07, 0.05), "c", bevel=0.015)
	sl = sb((w, d, h), (0, 0, 0.095 + h / 2), "b", bevel=0.012)
	yf = -d / 2
	for zz in (0.13, 0.095 + h - 0.04):
		sb((w, 0.03, 0.05), (0, yf - 0.01, zz), "a", bevel=0.008)
	for s_ in (-1, 1):
		sb((0.05, 0.03, h - 0.12), (s_ * (w / 2 - 0.025), yf - 0.01, 0.095 + h / 2), "a", bevel=0.008)
	sb((w + 0.08, d + 0.06, 0.07), (0, -0.01, 0.095 + h + 0.03), "a", bevel=0.014)
	return sl, yf


def qb_crest_hammers():
	sl, yf = stele(0.72, 1.3)
	carve(sl, runes(-0.24, 0.24, 0.48, yf, h=0.05, gap=0.05) + runes(-0.2, 0.2, 0.37, yf, h=0.05, gap=0.05, under=False))
	sh = [(-0.24, 1.25), (0.24, 1.25), (0.24, 0.92), (0, 0.66), (-0.24, 0.92)]
	pl = prism(sh, yf - 0.05, yf + 0.005, S("a"))
	carve(pl, crest("hammers", 0, 0.98, 0.22, yf - 0.05, w=0.016, d=0.012))
	for x, z in ((-0.2, 1.21), (0.2, 1.21), (0, 0.72)):
		kit.rivet((x, yf - 0.05, z), IRON("dark"), r=0.013)
	# a small candle ledge on a corbel under the names
	sb((0.34, 0.14, 0.04), (0, yf - 0.06, 0.25), "a", bevel=0.008)
	corbel(0, 0.23, depth=0.1, w=0.1, h=0.1, y0=yf)
	candle(-0.08, yf - 0.07, 0.27, 0.02, 0.08, lit=True)
	candle(0.08, yf - 0.06, 0.27, 0.017, 0.05, lit=False)
	flat_back(0.07)


def qb_crest_mountain():
	sl, yf = stele(0.8, 1.2)
	carve(sl, runes(-0.28, 0.28, 0.4, yf, h=0.05, gap=0.05) + runes(-0.22, 0.22, 0.29, yf, h=0.05, gap=0.05, under=False))
	disc = kit.cylinder(0.27, 0.06, (0, yf - 0.025, 0.86), S("a"), rot=(90, 0, 0), verts=28, bevel=0.01)
	carve(disc, crest("mountain", 0, 0.86, 0.2, yf - 0.055, w=0.015, d=0.012))
	kit.ring(0.285, 0.024, (0, yf - 0.03, 0.86), S("a"), rot=(90, 0, 0), seg=40)  # cord moulding round the plaque
	kit.ring(0.205, 0.008, (0, yf - 0.056, 0.86), S("c"), rot=(90, 0, 0), seg=32)
	for s_ in (-1, 1):  # iron lamp brackets: riveted wall plate, arm, a down-turned hook; the chain hangs straight off it
		x, ya = s_ * 0.33, yf - 0.13
		B((0.05, 0.016, 0.12), (x, yf - 0.006, 1.1), IRON("dark"), bevel=0.004)
		for zz in (1.06, 1.14):
			kit.rivet((x, yf - 0.015, zz), IRON("dark"), r=0.009)
		tube([(x, yf - 0.01, 1.12), (x, ya + 0.04, 1.125), (x, ya, 1.1), (x, ya, 1.075)], 0.012, 0.01, IRON("dark"), seg=7)  # arm and hook
		tube([(x, yf - 0.01, 1.06), (x, ya + 0.05, 1.115)], 0.008, 0.008, IRON("dark"), seg=6)  # brace
		ring_at((x, ya, 1.062), (1, 0, 0), 0.016, 0.005, IRON("dark"))  # top link on the hook
		chain((x, ya, 1.032), (x, ya, 0.86), link=0.022, wire=0.005)
		for k in range(3):
			a = 2 * math.pi * k / 3
			rod((s_ * 0.33, yf - 0.13, 0.85), (s_ * 0.33 + math.cos(a) * 0.035, yf - 0.13 + math.sin(a) * 0.035, 0.79), 0.0045, IRON("dark"), seg=5)
		oil_lamp(s_ * 0.33, yf - 0.13, 0.765, s=0.9, lit=s_ < 0)
	flat_back(0.07)


def qb_lamp_alcove():
	sb((0.92, 0.46, 0.1), (0, -0.04, 0.05), "c", bevel=0.015)
	body = sb((0.8, 0.36, 1.15), (0, 0, 0.095 + 0.575), "b", bevel=0.015)
	yf, nz, nw, nh = -0.18, 0.55, 0.4, 0.45
	arch = [(-nw / 2, nz), (nw / 2, nz)] + [(math.cos(a) * nw / 2, nz + nh - nw / 2 + math.sin(a) * nw / 2) for a in [math.pi * k / 12 for k in range(13)]]
	cuts = [prism(arch, yf - 0.03, yf + 0.22, GROOVE())]
	cuts += runes(-0.3, 0.3, 1.1, yf, h=0.05, gap=0.05) + crest("axe", 0, 0.3, 0.09, yf)
	carve(body, cuts)
	sb((nw + 0.16, 0.08, 0.05), (0, yf - 0.025, nz - 0.022), "a", bevel=0.01)  # sill
	for s_ in (-1, 1):
		sb((0.06, 0.04, nh - nw / 2), (s_ * (nw / 2 + 0.04), yf - 0.015, nz + (nh - nw / 2) / 2), "a", bevel=0.01)
	prism([(-0.05, nz + nh - 0.02), (0.05, nz + nh - 0.02), (0.065, nz + nh + 0.07), (-0.065, nz + nh + 0.07)], yf + 0.005, yf - 0.035, S("a"))
	sb((0.88, 0.42, 0.07), (0, -0.01, 1.28), "a", bevel=0.015)
	oil_lamp(-0.04, -0.03, nz + 0.001, lit=True, rotz=-90)
	lathe([(0.03, 0), (0.045, 0.02), (0.05, 0.06), (0.03, 0.1), (0.018, 0.12), (0.022, 0.135)], (0.12, -0.02, nz), CLAY("b"), seg=14)  # oil jug
	kit.ring(0.03, 0.006, (0.155, -0.02, nz + 0.095), CLAY("b"), rot=(90, 0, 0), seg=10)
	B((0.1, 0.06, 0.04), (-0.17, yf - 0.035, nz + 0.024), WD("b"), bevel=0.005)  # tinder box on the sill
	B((0.104, 0.064, 0.008), (-0.17, yf - 0.035, nz + 0.046), WD("dark"), bevel=0.002)
	B((0.012, 0.066, 0.042), (-0.17, yf - 0.035, nz + 0.024), IRON("dark"), bevel=0.002)
	flat_back(0.18)


def qb_candle_ledge():
	w, h = 1.5, 1.35
	wall_kit(w, h)
	z = 0.95
	led = sb((1.36, 0.2, 0.07), (0, YF - 0.09, z), "a", bevel=0.012)
	carve(led, gline([(-0.66, z - 0.018), (0.66, z - 0.018)], 0.008, YF - 0.19, 0.006) + runes(-0.25, 0.25, z + 0.012, YF - 0.19, h=0.026, w=0.006, gap=0.04, depth=0.004, under=False))
	for x in (-0.55, 0.0, 0.55):
		corbel(x, z - 0.035, depth=0.18, h=0.2)
	top = z + 0.035
	rows = [(-0.6, -0.16, 0.022, 0.12), (-0.48, -0.25, 0.026, 0.06), (-0.37, -0.15, 0.018, 0.16), (-0.25, -0.24, 0.028, 0.09),
		(-0.12, -0.17, 0.02, 0.05), (0.02, -0.24, 0.03, 0.14), (0.15, -0.15, 0.019, 0.08), (0.27, -0.23, 0.024, 0.11),
		(0.39, -0.16, 0.02, 0.045), (0.5, -0.24, 0.026, 0.13), (0.62, -0.16, 0.018, 0.07)]
	for k, (x, y, r, hh) in enumerate(rows):
		candle(x, y, top, r, hh, lit=k not in (4, 8))
	for x in (-0.48, -0.25, 0.02, 0.27, 0.5):  # wax runs down the front edge
		sphere((x + J(0.02), YF - 0.19, z - 0.005), 0.011, WAX(), scale=(1, 0.7, 2.6), seg=8, rings=5)
	tube([(0.42, -0.27, top + 0.004), (0.56, -0.29, top + 0.006)], 0.004, 0.004, IRON("dark"), seg=5)  # snuffer
	kit.cone(0.016, 0.004, 0.03, (0.4, -0.27, top + 0.015), IRON("dark"), rot=(0, 90, 0), verts=8)
	flat_back(0.1)


def qb_ossuary_wall():
	w, h = 1.6, 1.36
	wk = wall_kit(w, h, holes=[(-1, 1, 0, 2)])
	carve(wk["cornice"], runes(-0.4, 0.4, h - 0.045, -0.17, h=0.04, w=0.009, gap=0.05, depth=0.006, under=False))
	x0, x1 = -w / 2 + 0.1, w / 2 - 0.1
	z = 0.13
	for band in "BSBSBS":
		if band == "B":
			for layer in range(2):
				zz = z + 0.03 + layer * 0.05
				n = int((x1 - x0) / 0.058)
				for i in range(n - layer):
					x = x0 + 0.03 + i * (x1 - x0 - 0.06) / (n - 1) + (0.029 if layer else 0)
					m = BONE(-0.06 + 0.05 * ((i + layer) % 3) / 2)
					rod((x, 0.005, zz), (x, -0.19 + J(0.01), zz), 0.02, m, seg=6)
					for s_ in (-1, 1):
						sphere((x + s_ * 0.013, -0.19, zz), 0.022, m, seg=5, rings=4)  # few sides: 300 knobs, file under 2 MB
			z += 0.115
		else:
			n = 7
			for i in range(n):
				x = x0 + 0.08 + i * (x1 - x0 - 0.16) / (n - 1)
				skull((x, -0.09, z + 0.115 * 0.9), 0.9, BONE(-0.04 + 0.03 * (i % 3)))
			z += 0.24 * 0.9 + 0.02
	slim(small=0.03, fine=0.005, bare=0.015)  # under 2 MB
	flat_back(0.1)


def real_bust(z_cut=0.6):
	"""The family founder, carved in limestone from the game's own dwarf (owner round 2: no box figures): head and beard
	in his banded cap, shoulders, cut off flat across the chest. Stands on z = 0, faces -Y, ~0.64 m tall, ~0.75 m wide."""
	ms, _ = real_dwarf([("upperarm_r", "Y", -80), ("upperarm_l", "Y", 80)], m=lambda n: S("b") if "rings" in n or "brass" in n else S("a"), ratio=0.27,
		files=(("dwarf_body.glb", ("eye", "body_head", "hand", "foot", "pants", "shorts")), ("armor_hide.glb", ("fleece", "chest", "feet"))))
	for o in ms:
		bm = bmesh.new()
		bm.from_mesh(o.data)
		bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], plane_co=(0, 0, z_cut), plane_no=(0, 0, 1), clear_inner=True)
		bm.to_mesh(o.data)
		bm.free()
	empty = [o for o in ms if not o.data.vertices]
	shift([o for o in ms if o not in empty], (0, 0, -z_cut))
	for o in empty:
		bpy.data.objects.remove(o, do_unlink=True)


def bust():
	"""The family founder, carved in limestone (full scale; scaled down where used). Stands on z = 0, faces -Y."""
	m = S("a")
	kit.taper(0.56, 0.3, 0.46, 0.27, 0.2, (0, 0, 0), m, bevel=0.012)
	sphere((0, 0, 0.24), 0.21, m, scale=(1.35, 0.75, 0.5), seg=14, rings=8)
	face(m, 0.43, y=-0.01, r=0.135)
	beard(m, 0.37, 0.14, y0=-0.08, y1=-0.19, w=0.12)
	kit.ring(0.128, 0.02, (0, -0.005, 0.5), m, seg=16)  # cap band
	sphere((0, -0.005, 0.5), 0.13, m, scale=(1, 1, 0.75), seg=12, rings=7, cut=0.0)
	kit.cone(0.02, 0.004, 0.06, (0, -0.005, 0.6), m, verts=6)


def qb_family_shrine():
	sb((0.82, 0.5, 0.08), (0, -0.04, 0.04), "c", bevel=0.015)
	ped = sb((0.7, 0.4, 0.75), (0, 0, 0.075 + 0.375), "b", bevel=0.015)
	carve(ped, crest("hammers", 0, 0.5, 0.12, -0.2) + runes(-0.25, 0.25, 0.25, -0.2, h=0.05, gap=0.05))
	sb((0.8, 0.46, 0.06), (0, -0.01, 0.855), "a", bevel=0.012)
	back = sb((0.62, 0.24, 0.62), (0, 0.08, 0.885 + 0.31), "b", bevel=0.012)
	nw, nz, nh = 0.36, 0.95, 0.46
	arch = [(-nw / 2, nz), (nw / 2, nz)] + [(math.cos(a) * nw / 2, nz + nh - nw / 2 + math.sin(a) * nw / 2) for a in [math.pi * k / 12 for k in range(13)]]
	carve(back, [prism(arch, -0.07, 0.12, GROOVE())])
	for s_ in (-1, 1):
		kit.cylinder(0.035, 0.5, (s_ * 0.26, -0.07, 0.885 + 0.04 + 0.25), S("a"), verts=12, bevel=0.006)
		sb((0.09, 0.09, 0.04), (s_ * 0.26, -0.07, 0.905), "a", bevel=0.008)
		sb((0.09, 0.09, 0.04), (s_ * 0.26, -0.07, 1.43), "a", bevel=0.008)
	cor = sb((0.78, 0.34, 0.08), (0, 0.04, 1.49), "a", bevel=0.014)
	carve(cor, runes(-0.3, 0.3, 1.49, -0.13, h=0.04, w=0.008, gap=0.045, depth=0.006, under=False))
	group(bust, at=(0, 0.04, nz), scale=0.48)
	for s_ in (-1, 1):
		candle(s_ * 0.3, -0.16, 0.885, 0.02, 0.07 + 0.03 * (s_ > 0), lit=True)
		lathe([(0.018, 0), (0.024, 0.004), (0.01, 0.012), (0.008, 0.03), (0.025, 0.045), (0.028, 0.06), (0.022, 0.06)], (s_ * 0.12, -0.15, 0.884), CU("b"), seg=12)
	coin((0.0, -0.17, 0.89))
	flat_back(0.2)


def qb_name_roll():
	sb((1.5, 0.4, 0.12), (0, -0.08, 0.06), "c", bevel=0.015)
	tab = sb((1.3, 0.16, 1.15), (0, 0.0, 0.115 + 0.575), "b", bevel=0.014)
	yf = -0.08
	cuts = crest("pick", 0, 1.13, 0.08, yf)
	for k in range(7):
		zz = 0.97 - k * 0.1
		cuts += runes(-0.52, 0.02 + 0.04 * (k % 3), zz, yf, h=0.05, w=0.009, gap=0.045, depth=0.006, under=False)
		cuts.append(cy(circ(0.14, zz, 0.008, n=6, wob=0), yf, 0.006))
		cuts += runes(0.22, 0.5, zz, yf, h=0.05, w=0.009, gap=0.045, depth=0.006, under=False)
	zz = 0.97 - 7 * 0.1  # the newest name: three runes cut, the rest only scribed
	cuts += runes(-0.52, -0.38, zz, yf, h=0.05, w=0.009, gap=0.045, depth=0.006, under=False)
	for dz in (-0.03, 0.03):
		cuts += gline([(-0.36, zz + dz), (0.5, zz + dz)], 0.0035, yf, 0.0015)
	carve(tab, cuts)
	for zz in (0.17, 1.22):
		sb((1.3, 0.03, 0.05), (0, yf - 0.01, zz), "a", bevel=0.008)
	for s_ in (-1, 1):
		sb((0.05, 0.03, 1.0), (s_ * 0.625, yf - 0.01, 0.695), "a", bevel=0.008)
	sb((1.38, 0.22, 0.07), (0, -0.01, 1.3), "a", bevel=0.014)
	ledge = 0.12
	for k, (x, L) in enumerate(((-0.34, 0.24), (-0.28, 0.2), (-0.22, 0.17))):
		group(lambda L=L: chisel(L), at=(x, -0.2, ledge + 0.012), rot=(90, 0, 180 + 4 * k))
	drop(group(lambda: mallet(0.26), at=(0.3, -0.2, 0.3), rot=(90, 0, 75)), ledge)
	candle(0.6, -0.19, ledge, 0.022, 0.07, lit=True)
	chips([(-0.35, -0.15, 0.012), (-0.3, -0.13, 0.01), (-0.42, -0.16, 0.01)], z=ledge)
	chips([(-0.4, -0.38, 0.015), (-0.2, -0.4, 0.012)])
	flat_back(0.08)


def qb_digger_tool_wall():
	w, h = 1.4, 1.7
	wall_kit(w, h)
	zb = 1.32
	B((1.3, 0.08, 0.1), (0, YF - 0.035, zb), WD("b"), bevel=0.01)
	for x in (-0.6, 0.6):
		B((0.04, 0.09, 0.14), (x, YF - 0.04, zb), IRON("dark"), bevel=0.004)
		kit.rivet((x, YF - 0.085, zb + 0.04), IRON("dark"), r=0.01)
		kit.rivet((x, YF - 0.085, zb - 0.04), IRON("dark"), r=0.01)
	pegs = (-0.45, -0.12, 0.18, 0.46)
	for x in pegs:
		kit.cylinder(0.018, 0.13, (x, YF - 0.13, zb), WD("dark"), rot=(90, 0, 0), verts=8)
		sphere((x, YF - 0.195, zb), 0.024, WD("dark"), seg=8, rings=5)
	group(lambda: spade(1.0), at=(pegs[0], YF - 0.15, zb + 0.03 - 1.0))
	group(lambda: pickaxe(0.8), at=(pegs[1] + 0.04, YF - 0.16, zb + 0.04 - 0.8))
	for k in range(4):  # rope coil over a peg
		kit.ring(0.13 - k * 0.006, 0.014, (pegs[2] + J(0.01), YF - 0.1 - k * 0.027, zb - 0.11), ROPE(), rot=(90, J(4), J(4)), seg=22)
	kit.ring(0.03, 0.006, (pegs[3], YF - 0.15, zb - 0.008), IRON("dark"), rot=(90, 0, 0), seg=10)
	chain((pegs[3], YF - 0.15, zb - 0.035), (pegs[3], YF - 0.15, zb - 0.16), link=0.02, wire=0.005)
	lantern(pegs[3], YF - 0.15, zb - 0.43)
	# a broom leaning by the wall, a bucket at its foot
	rod((0.6, -0.36, 0.2), (0.62, YF - 0.025, 1.1), 0.016, WD("b"))
	g = group(lambda: (kit.taper(0.08, 0.05, 0.2, 0.06, 0.24, (0, 0, 0), T("straw", "b"), bevel=0.01),
		[kit.ring(0.045, 0.006, (0, 0, 0.2 - k * 0.04), ROPE(), seg=10) for k in range(2)]), at=(0.6, -0.36, 0.0), rot=(180 - 6, 0, 0))
	drop(g)
	tub(0.25, -0.4, 0.13, 0.24)
	tube([(0.13, -0.4, 0.22), (0.18, -0.4, 0.33), (0.25, -0.4, 0.36), (0.32, -0.4, 0.33), (0.37, -0.4, 0.22)], 0.006, 0.006, IRON("dark"), seg=5)
	flat_back(0.1)


def spandrel(cx, cz, R, x0, z0, z1, side):
	"""Fill the corner between a round arch (radius R) and the rectangle edge x0 on one side."""
	a1 = math.asin(max(-1, min(1, (z0 - cz) / R)))
	angs = [math.pi / 2 + (math.pi - a1 - math.pi / 2) * k / 10 for k in range(11)] if side < 0 else \
		[math.pi / 2 - (math.pi / 2 - a1) * k / 10 for k in range(11)]
	pts = [(x0, z0), (x0, z1), (cx, z1)] + [(cx + math.cos(a) * R, cz + math.sin(a) * R) for a in angs]
	if side > 0:
		pts = list(reversed(pts))
	return prism(pts, YF + J(0.004), 0.005, S("b"))


def voussoirs(cx, cz, ri, ro, a0, a1, n, yf, key=None, zmin=0.135):
	out = []
	for k in range(n):
		b0, b1 = a0 + (a1 - a0) * k / n + 0.012, a0 + (a1 - a0) * (k + 1) / n - 0.012
		r2 = ro + (0.06 if key == k else 0)
		pts = [(cx + math.cos(b) * r, max(zmin, cz + math.sin(b) * r)) for r, b in ((ri, b0), (r2, b0), (r2, b1), (ri, b1))]
		out.append(prism(pts, yf, 0.005, S("a" if k % 2 else "b")))
	return out


def qb_sealed_passage():
	w, h, cx, cz, R = 1.7, 2.0, 0.0, 1.0, 0.5
	wk = wall_kit(w, h, holes=[(-0.72, 0.72, 1.0, 1.74), (-0.5, 0.5, 0.13, 1.0)], rows=[0.13, 0.35, 0.57, 0.79, 1.0, 1.74, 1.91])
	for s_ in (-1, 1):
		spandrel(cx, cz, 0.72, s_ * 0.72, 1.0, 1.74, s_)
		sb((0.14, 0.17, 0.87), (s_ * 0.57, YF + 0.04 - 0.04 - 0.045 + 0.04, 0.13 + 0.435), "a", bevel=0.012)  # jambs
	vs = voussoirs(cx, cz, R, 0.72, 0, math.pi, 9, YF - 0.04, key=4)
	carve(vs[4], crest("pick", 0, 1.62, 0.06, YF - 0.04, w=0.01))
	# the rough infill, set back 4 cm
	z = 0.135
	k = 0
	while z < cz + R - 0.05:
		hh = 0.13 + J(0.02)
		zt = min(z + hh, cz + R)
		half = R + 0.03 if zt <= cz else math.sqrt(max(0.0, (R + 0.03) ** 2 - (zt - cz) ** 2))
		x = -half
		while x < half - 0.05:
			bw = min(rng.uniform(0.17, 0.3), half - x)
			sb((bw - 0.016, 0.085, zt - z - 0.016), (x + bw / 2, -0.0375, (z + zt) / 2), "c" if k % 3 else "b", bevel=0.014)
			x += bw
			k += 1
		z = zt
	pl = sb((0.36, 0.05, 0.42), (0, -0.1, 0.96), "a", bevel=0.01)
	carve(pl, crest("anvil", 0, 1.06, 0.09, -0.125) + runes(-0.14, 0.14, 0.86, -0.125, h=0.04, w=0.008, gap=0.045, depth=0.006))
	for x, zz in ((-0.15, 0.78), (0.15, 0.78), (-0.15, 1.14), (0.15, 1.14)):
		kit.rivet((x, -0.125, zz), IRON("dark"), r=0.01)
	for s_ in (-1, 1):  # iron staples in the jambs, a chain across, a padlock
		kit.ring(0.03, 0.008, (s_ * 0.57, -0.255, 0.62), IRON("dark"), rot=(0, 90, 0), seg=12)
		chain((s_ * 0.55, -0.26, 0.6), (s_ * 0.05, -0.26, 0.48), link=0.03, wire=0.008)
	kit.ring(0.035, 0.008, (0, -0.26, 0.47), IRON("dark"), rot=(90, 0, 0), seg=12)
	B((0.08, 0.04, 0.09), (0, -0.26, 0.41), IRON("dark"), bevel=0.01)
	B((0.012, 0.042, 0.03), (0, -0.262, 0.4), MORT(), bevel=0.002)
	flat_back(0.1)


def qb_vault_gate():
	w, h, cz, R = 1.8, 1.75, 0.6, 0.55
	wk = wall_kit(w, h, holes=[(-0.77, 0.77, 0.13, 1.37)], rows=[0.13, 0.35, 0.57, 0.79, 1.01, 1.37, 1.66])
	for s_ in (-1, 1):
		spandrel(0, cz, 0.77, s_ * 0.77, cz, 1.37, s_)
		pts = [(s_ * 0.77, 0.13), (s_ * 0.77, cz)] + [(s_ * math.cos(a) * 0.77, cz + math.sin(a) * 0.77) for a in [-k * 0.13 for k in range(1, 6)]] + [(s_ * 0.32, 0.13)]
		pts = [(x, max(0.135, z)) for x, z in pts]
		prism(pts if s_ < 0 else list(reversed(pts)), YF, 0.005, S("b"))
	a0 = math.asin((0.135 - cz) / R)
	vs = voussoirs(0, cz, R, 0.75, a0, math.pi - a0, 13, YF - 0.05, key=6)
	carve(vs[6], crest("mountain", 0, cz + 0.68, 0.07, YF - 0.05, w=0.01))
	# the dark beyond the gate: a pitch-black plate 1 cm in front of the backing, filling the arch
	prism([(-0.77, 0.13)] + [(math.cos(a) * 0.77, cz + math.sin(a) * 0.77) for a in [math.pi * k / 24 for k in range(24, -1, -1)]][::-1] + [(0.77, 0.13)],
		-0.012, 0.004, VOID())
	# the iron grille gate
	yg, ri = -0.07, R - 0.01
	kit.ring(ri, 0.016, (0, yg, cz), IRON("dark"), rot=(90, 0, 0), seg=40)
	for k in range(-4, 5):
		x = k * 0.1
		zt = cz + math.sqrt(ri * ri - x * x)
		rod((x, yg, 0.13), (x, yg, zt), 0.011, IRON("a"), seg=6)
		sphere((x, yg, 0.14), 0.016, IRON("dark"), seg=6, rings=4)
	for zz in (0.42, 0.82):
		hw = math.sqrt(ri * ri - (zz - cz) ** 2)
		B((hw * 2, 0.02, 0.035), (0, yg - 0.012, zz), IRON("dark"), bevel=0.004)
		for k in range(-4, 5):
			kit.rivet((k * 0.1, yg - 0.022, zz), IRON("dark"), r=0.008)
	for zz in (0.36, 0.86):  # hinges at the left
		B((0.16, 0.022, 0.04), (-0.46, yg - 0.028, zz), IRON("dark"), bevel=0.004)
		kit.cylinder(0.018, 0.07, (-0.54, yg - 0.03, zz), IRON("dark"), verts=8)
	B((0.1, 0.022, 0.05), (0.42, yg - 0.02, 0.6), IRON("dark"), bevel=0.004)  # hasp
	kit.ring(0.026, 0.007, (0.42, yg - 0.036, 0.57), IRON("dark"), rot=(90, 0, 0), seg=12)
	B((0.06, 0.035, 0.07), (0.42, yg - 0.036, 0.525), IRON("dark"), bevel=0.008)
	carve(wk["cornice"], runes(-0.4, 0.4, h - 0.045, -0.17, h=0.04, w=0.009, gap=0.05, depth=0.006, under=False))
	flat_back(0.1)


# ================= floor pieces =================
def qb_mourners_bench():
	for s_ in (-1, 1):
		leg = sb((0.2, 0.36, 0.36), (s_ * 0.55, 0, 0.18), "b", bevel=0.015)
		carve(leg, crest(KINDS[(s_ > 0) * 2], s_ * 0.55, 0.2, 0.06, -0.18, w=0.009))
	seat = sb((1.4, 0.42, 0.09), (0, 0, 0.405), "a", bevel=0.015)
	carve(seat, gline([(-0.66, 0.405), (0.66, 0.405)], 0.008, -0.21, 0.006))
	step = sb((1.3, 0.24, 0.1), (0, -0.36, 0.05), "c", bevel=0.015)
	carve(step, [sphere((x, -0.36, 0.105), 0.075, S("c"), scale=(1, 0.75, 0.35), seg=12, rings=6) for x in (-0.12, 0.12)])
	lantern(-0.42, 0.02, 0.45)
	_hl = hlathe([(0, 0), (0.03, 0), (0.038, 0.07), (0.032, 0.07), (0.025, 0.008), (0, 0.008)], (0.12, 0.05), CLAY("b"), seg=14)
	_hl.location.z += 0.449
	rod((0.86, -0.08, 0.0), (0.705, -0.06, 0.4), 0.014, WD("b"))  # a walking stick leaning on the seat end
	sphere((0.7, -0.06, 0.415), 0.022, WD("dark"), seg=8, rings=5)
	kit.cylinder(0.016, 0.03, (0.86, -0.08, 0.015), IRON("dark"), verts=8)


def qb_floor_slab():
	W, Lg = 0.72, 1.42
	def slab():
		sl = sb((W, 0.08, Lg), (0, 0.04, Lg / 2), "b", bevel=0.012)
		cuts = gline([(-W / 2 + 0.05, 0.05), (W / 2 - 0.05, 0.05), (W / 2 - 0.05, Lg - 0.05), (-W / 2 + 0.05, Lg - 0.05), (-W / 2 + 0.05, 0.05)], 0.01, 0, 0.006)
		cuts += crest("mountain", 0, Lg - 0.24, 0.13, 0)
		for k in range(3):
			cuts += runes(-0.24, 0.24, Lg - 0.5 - k * 0.11, 0, h=0.05, w=0.009, gap=0.05, depth=0.006, under=k == 0)
		cuts.append(cy(circ(0, 0.22, 0.05, n=14, wob=0), 0, 0.012))
		carve(sl, cuts)
	lay_flat(slab, (0, -Lg / 2, 0.002))  # top at z ~ 0.08, head (+Y) end at y = +0.71
	for s_ in (-1, 1):  # kerb: two stones each long side, one each end
		for k in (-1, 1):
			sb((0.12, Lg / 2 - 0.02, 0.1), (s_ * (W / 2 + 0.055), k * Lg / 4, 0.05), "bc"[(k + s_) % 2], bevel=0.014)
		sb((W + 0.22, 0.12, 0.1), (0, s_ * (Lg / 2 + 0.055), 0.05), "a", bevel=0.014)
	kit.ring(0.04, 0.007, (0, -Lg / 2 + 0.22, 0.072), IRON("dark"), seg=14)  # lift ring in its cut seat
	B((0.03, 0.012, 0.012), (0, -Lg / 2 + 0.22 + 0.04, 0.074), IRON("dark"), bevel=0.002)
	for s_ in (-1, 1):  # candle stubs in iron cups at the head
		x, y = s_ * (W / 2 + 0.055), Lg / 2 + 0.055
		_hl = hlathe([(0, 0), (0.04, 0), (0.045, 0.03), (0.04, 0.03), (0.034, 0.006), (0, 0.006)], (x, y), IRON("dark"), seg=12)
		_hl.location.z += 0.099
		candle(x, y, 0.105, 0.022, 0.03 + 0.02 * (s_ > 0), lit=s_ > 0)
	tokens([(0.18, 0.2, 0.03), (0.22, 0.25, 0.025), (-0.2, -0.3, 0.028)], 0.08)


def qb_cairn_grave():
	def course(w, d, z0, hh, n, v):
		for i in range(n):
			for j in range(2):
				bw, bd = w / n, d / 2
				sb((bw - 0.012, bd - 0.012, hh), (-w / 2 + bw * (i + 0.5), -d / 2 + bd * (j + 0.5), z0 + hh / 2), "abc"[(i + j + v) % 3], bevel=0.02)
	course(0.75, 1.35, 0.0, 0.16, 2, 0)
	for k in range(5):  # little kerb stones along both long sides
		for s_ in (-1, 1):
			sb((0.07, 0.2, 0.11 + J(0.02)), (s_ * 0.405, -0.54 + k * 0.27, 0.068), "abc"[k % 3], bevel=0.02, rot=(0, s_ * 6, J(4)))
	course(0.55, 1.05, 0.155, 0.14, 2, 1)
	ridge = sb((0.34, 0.8, 0.1), (0, 0, 0.34), "a", bevel=0.02)
	carve(ridge, gline([(-0.12, 0.34), (0.12, 0.34)], 0.01, -0.4, 0.008))
	sb((0.62, 0.22, 0.1), (0, 0.8, 0.05), "c", bevel=0.015)
	hs = sb((0.5, 0.1, 0.62), (0, 0.8, 0.095 + 0.31), "b", bevel=0.014)
	carve(hs, crest("axe", -0.03, 0.47, 0.11, 0.75) + runes(-0.18, 0.18, 0.3, 0.75, h=0.045, w=0.009, gap=0.045, depth=0.006)
		+ runes(-0.14, 0.14, 0.2, 0.75, h=0.045, w=0.009, gap=0.045, depth=0.006, under=False))
	sb((0.56, 0.14, 0.05), (0, 0.8, 0.735), "a", bevel=0.01)
	_hl = hlathe([(0, 0), (0.026, 0), (0.034, 0.06), (0.029, 0.06), (0.021, 0.007), (0, 0.007)], (0.05, 0.1), CU("b"), seg=12)
	_hl.location.z += 0.389
	tokens([(-0.06, -0.15, 0.03), (-0.04, -0.22, 0.025), (0.06, -0.25, 0.022)], 0.39)
	oil_lamp(0.0, -0.82, 0.0, lit=True, rotz=-90)


def headstone(kind, w, h, d=0.1):
	"""A headstone standing at the origin (bottom 3 cm sunk), front -Y: round / flat / gable top."""
	if kind == "round":
		pts = [(-w / 2, -0.03), (w / 2, -0.03), (w / 2, h - w / 2)] + [(math.cos(a) * w / 2, h - w / 2 + math.sin(a) * w / 2) for a in [math.pi * k / 12 for k in range(1, 12)]] + [(-w / 2, h - w / 2)]
	elif kind == "gable":
		pts = [(-w / 2, -0.03), (w / 2, -0.03), (w / 2, h - 0.12), (0, h), (-w / 2, h - 0.12)]
	else:
		pts = [(-w / 2, -0.03), (w / 2, -0.03), (w / 2, h), (-w / 2, h)]
	o = prism(pts, -d / 2, d / 2, S("b"))
	return o


def qb_headstone_row():
	kerb = sb((1.9, 0.42, 0.1), (0, 0, 0.05), "c", bevel=0.015)
	carve(kerb, gline([(-0.9, 0.05), (0.9, 0.05)], 0.008, -0.21, 0.006))
	specs = (("round", -0.62, 0.48, 0.7, "hammers", 0), ("flat", 0.0, 0.5, 0.62, "anvil", 0), ("gable", 0.62, 0.46, 0.74, "pick", -8))
	for kind, x, w, h, cr, lean in specs:
		def build(kind=kind, w=w, h=h, cr=cr):
			o = headstone(kind, w, h)
			cuts = crest(cr, 0, h * 0.68, 0.08, -0.05) + runes(-w * 0.32, w * 0.32, h * 0.38, -0.05, h=0.045, w=0.009, gap=0.045, depth=0.006)
			cuts += runes(-w * 0.26, w * 0.26, h * 0.24, -0.05, h=0.045, w=0.009, gap=0.045, depth=0.006, under=False)
			if kind == "round":
				cuts += gline([(0.05, h - 0.02), (0.1, h * 0.85), (0.07, h * 0.7), (0.14, h * 0.55)], 0.012, -0.05, 0.02)  # old crack
			carve(o, cuts)
			if kind == "flat":
				sb((w + 0.06, 0.14, 0.05), (0, 0, h + 0.02), "a", bevel=0.01)
		group(build, at=(x, 0.04, 0.1), rot=(-lean, 0, 0))
	chips([(-0.48, -0.32, 0.03), (-0.55, -0.28, 0.02)])
	tokens([(-0.05, -0.16, 0.025), (0.06, -0.15, 0.03)], 0.1)
	oil_lamp(0.62, -0.15, 0.1, lit=True, rotz=-90)
	candle(-0.2, -0.15, 0.1, 0.02, 0.05, lit=False)


def qb_urn_pedestal():
	base = sb((0.44, 0.44, 0.1), (0, 0, 0.05), "c", bevel=0.015)
	carve(base, runes(-0.15, 0.15, 0.05, -0.22, h=0.045, w=0.008, gap=0.045, depth=0.006, under=False))
	lathe([(0.15, 0), (0.16, 0.03), (0.11, 0.08), (0.08, 0.2), (0.075, 0.35), (0.09, 0.47), (0.13, 0.52), (0.17, 0.56), (0.18, 0.6)], (0, 0, 0.098), S("b"), seg=20)
	top = sb((0.44, 0.44, 0.06), (0, 0, 0.72), "a", bevel=0.012)
	carve(top, gline([(-0.2, 0.72), (0.2, 0.72)], 0.008, -0.22, 0.006))
	urn(0, 0, 0.749, s=1.75, kind=0, v="b")
	_hl = hlathe([(0, 0), (0.024, 0), (0.03, 0.05), (0.026, 0.05), (0.019, 0.006), (0, 0.006)], (0.16, -0.15), CU("b"), seg=12)
	_hl.location.z += 0.749
	tokens([(-0.16, -0.15, 0.03), (-0.15, 0.15, 0.025)], 0.75)


def wheel(x, y, z, R=0.3):
	kit.ring(R - 0.02, 0.02, (x, y, z), IRON("dark"), rot=(90, 0, 0), seg=28)
	kit.ring(R - 0.05, 0.028, (x, y, z), WD("b"), rot=(90, 0, 0), seg=24)
	kit.cylinder(0.055, 0.09, (x, y, z), WD("dark"), rot=(90, 0, 0), verts=12, bevel=0.008)
	kit.cylinder(0.035, 0.1, (x, y, z), IRON("dark"), rot=(90, 0, 0), verts=8)
	for k in range(8):
		a = 2 * math.pi * k / 8 + 0.2
		rod((x + math.cos(a) * 0.05, y, z + math.sin(a) * 0.05), (x + math.cos(a) * (R - 0.06), y, z + math.sin(a) * (R - 0.06)), 0.013, WD("b"), seg=6)


def qb_urn_cart():
	zb = 0.32
	for k in range(4):  # floor planks
		B((0.9, 0.13, 0.03), (0, -0.2 + k * 0.135, zb + 0.015), WD("abc"[k % 3]), bevel=0.006)
	for s_ in (-1, 1):
		B((0.95, 0.03, 0.16), (0, s_ * 0.275, zb + 0.084), WD("b"), bevel=0.006)
		B((0.03, 0.55, 0.14), (s_ * 0.445, 0, zb + 0.085), WD("c"), bevel=0.006)
		for x in (-0.44, 0.44):
			B((0.06, 0.006, 0.14), (x - math.copysign(0.02, x), s_ * 0.292, zb + 0.08), IRON("dark"), bevel=0.002)
			kit.rivet((x - math.copysign(0.02, x), s_ * 0.295, zb + 0.1), IRON("dark"), r=0.008)
		B((0.03, 0.52, 0.12), (s_ * 0.15, 0, zb + 0.075), WD("dark"), bevel=0.004)  # slot dividers
		wheel(0.12, s_ * 0.35, 0.3)
		rod((-0.3, s_ * 0.24, zb - 0.01), (-0.98, s_ * 0.24, zb + 0.05), 0.022, WD("b"))  # handles
		for k in range(3):
			kit.ring(0.022, 0.005, (-0.88 + k * 0.03, s_ * 0.24, zb + 0.04), kit.tex_mat("leather", "dark"), rot=(0, 90, 0), seg=10)
		rod((-0.38, s_ * 0.24, zb - 0.01), (-0.42, s_ * 0.26, 0.0), 0.018, WD("b"))  # front legs
	rod((0.12, -0.38, 0.3), (0.12, 0.38, 0.3), 0.024, IRON("dark"))
	rod((-0.6, -0.24, zb + 0.02), (-0.6, 0.24, zb + 0.02), 0.016, WD("b"))  # handle stretcher
	for i, x in enumerate((-0.3, 0.0, 0.3)):
		urn(x, -0.12, zb + 0.03, s=1.0, kind=i % 2)
	urn(0.3, 0.12, zb + 0.03, s=0.9, kind=2)
	urn(0.0, 0.13, zb + 0.03, s=1.05, kind=1)
	urn(0.75, -0.5, 0.0, s=1.0, kind=0)  # one already lifted down
	chips([(0.6, -0.3, 0.015)])


def qb_digger_rest():
	barrel(0.3, 0.1)
	lantern(0.22, 0.05, 0.646)
	_hl = hlathe([(0, 0), (0.035, 0), (0.04, 0.09), (0.034, 0.09), (0.029, 0.008), (0, 0.008)], (0.38, 0.2), CLAY("b"), seg=14)
	_hl.location.z += 0.645
	kit.ring(0.028, 0.007, (0.425, 0.2, 0.69), CLAY("b"), rot=(90, 0, 0), seg=10)
	def slate():
		sl = sb((0.2, 0.025, 0.14), (0, 0.0125, 0.07), "b", bevel=0.005)
		carve(sl, [cy(bar((-0.07 + k * 0.018, 0.03), (-0.07 + k * 0.018, 0.11), 0.007), 0, 0.004) for k in range(7)]
			+ [cy(bar((-0.08, 0.04), (0.04, 0.1), 0.007), 0, 0.004)])
	lay_flat(slate, (0.3, -0.03, 0.645), rotz=12)
	# a three-legged stool
	kit.cylinder(0.17, 0.05, (-0.35, -0.05, 0.42), WD("b"), verts=14, bevel=0.01)
	for k in range(3):
		a = 2 * math.pi * k / 3 + 0.3
		rod((-0.35 + math.cos(a) * 0.1, -0.05 + math.sin(a) * 0.1, 0.42), (-0.35 + math.cos(a) * 0.17, -0.05 + math.sin(a) * 0.17, 0.0), 0.022, WD("b"))
		sphere((-0.35 + math.cos(a) * 0.1, -0.05 + math.sin(a) * 0.1, 0.445), 0.02, WD("dark"), seg=8, rings=5)
	g = group(lambda: spade(1.0), at=(0.0, -0.18, 0.0), rot=(0, 27, 0))
	drop(g)
	g = group(lambda: pickaxe(0.8), at=(-0.1, -0.55, 0.0), rot=(-90, 0, 75))
	drop(g)
	for k in range(5):  # rope coil on the floor
		kit.ring(0.14 - k * 0.012, 0.015, (0.62, -0.35, 0.015 + k * 0.022), ROPE(), seg=22)


def qb_mason_bench():
	zt = 0.62
	for k in range(3):
		B((1.3, 0.165, 0.07), (0, -0.165 + k * 0.165, zt - 0.035), WD("abc"[k]), bevel=0.008)
	for sx in (-0.55, 0.55):
		for sy in (-0.18, 0.18):
			B((0.08, 0.08, zt - 0.07), (sx, sy, (zt - 0.07) / 2), WD("b"), bevel=0.008)
			sphere((sx, sy, zt + 0.0), 0.02, WD("dark"), seg=8, rings=5)
		B((0.06, 0.32, 0.06), (sx, 0, 0.15), WD("c"), bevel=0.006)
	B((1.04, 0.06, 0.06), (0, 0, 0.15), WD("c"), bevel=0.006)
	for x in (-0.25, 0.15):  # chocks under the stone
		B((0.06, 0.3, 0.03), (x, -0.02, zt + 0.015), WD("dark"), bevel=0.004)
	lay_flat(lambda: hammers_slab(0, 0, 0.62, 0.34, "axe", -0.07, half=True), (-0.05, -0.19, zt + 0.03))
	drop(group(lambda: chisel(0.22), at=(0.06, -0.06, 0.9), rot=(90, 0, 200)), zt + 0.1)
	drop(group(lambda: mallet(0.28), at=(0.38, -0.12, 1.0), rot=(90, 0, -60)), zt)
	for k, L in enumerate((0.24, 0.2, 0.17)):
		group(lambda L=L: chisel(L), at=(0.42 + k * 0.05, 0.12, zt + 0.012), rot=(90, 0, 175))
	prism([(x - 0.55, y + 0.05) for x, y in ((0, 0), (0.2, 0), (0.2, 0.025), (0.025, 0.025), (0.025, 0.14), (0, 0.14))], zt, zt + 0.006, IRON("a"), axis="z")  # set square
	chips([(0.1, -0.22, 0.012), (0.2, -0.05, 0.01), (-0.42, 0.15, 0.01)], z=zt)
	chips([(0.1, -0.4, 0.02), (-0.3, -0.38, 0.015), (0.35, -0.3, 0.012)])
	for k in range(3):  # blank stones waiting by the bench
		sb((0.6, 0.34, 0.07), (0.95 + J(0.02), 0.0 + J(0.02), 0.035 + k * 0.072), "abc"[k], bevel=0.01, rot=(0, 0, 90 + J(5)))


def qb_kneeler_stele():
	sl, yf = stele(0.5, 0.9)
	disc = kit.cylinder(0.14, 0.02, (0, yf + 0.005, 0.72), S("b"), rot=(90, 0, 0), verts=24, bevel=0.0)
	carve(sl, [prism(circ(0, 0.72, 0.15, n=24, wob=0), yf - 0.03, yf + 0.025, GROOVE())] + runes(-0.17, 0.17, 0.42, yf, h=0.045, gap=0.045)
		+ runes(-0.14, 0.14, 0.32, yf, h=0.045, gap=0.045, under=False))
	disc.location.y += 0.01
	carve(disc, crest("anvil", 0, 0.72, 0.1, yf + 0.0, w=0.01))
	sb((0.3, 0.12, 0.035), (0, yf - 0.05, 0.56), "a", bevel=0.008)
	corbel(0, 0.545, depth=0.09, w=0.1, h=0.09, y0=yf)
	candle(0.06, yf - 0.06, 0.578, 0.02, 0.07, lit=True)
	step = sb((0.62, 0.3, 0.12), (0, -0.33, 0.06), "c", bevel=0.015)
	carve(step, [sphere((x, -0.36, 0.125), 0.07, S("c"), scale=(1, 0.8, 0.35), seg=12, rings=6) for x in (-0.12, 0.12)])
	oil_lamp(0.24, -0.4, 0.12, s=0.9, lit=False)


def qb_bier_trestles():
	for s_ in (-1, 1):
		t = kit.taper(0.24, 0.8, 0.2, 0.76, 0.46, (s_ * 0.6, 0, 0), S("b"), bevel=0.012)
		carve(t, crest(KINDS[1 + (s_ > 0)], s_ * 0.6, 0.26, 0.06, -0.39, w=0.009))
		sb((0.26, 0.8, 0.05), (s_ * 0.6, 0, 0.48), "a", bevel=0.01)
	for s_ in (-1, 1):
		log((-1.0, s_ * 0.28, 0.53), (1.0, s_ * 0.28, 0.53), 0.026, WD("b"), seg=8, rings=3, bend=0.0, ends=False)
		for e in (-1, 1):
			kit.cylinder(0.03, 0.05, (e * 0.98, s_ * 0.28, 0.53), IRON("dark"), rot=(0, 90, 0), verts=8)
			kit.ring(0.06, 0.012, (e * 0.88, s_ * 0.28, 0.48), ROPE(), rot=(0, 0, 0), seg=14).rotation_euler = (math.radians(90), 0, 0)
	for k in range(9):
		x = -0.6 + k * 0.15
		B((0.11, 0.62, 0.025), (x, 0, 0.565), WD("abc"[k % 3]), bevel=0.005)
		for s_ in (-1, 1):
			sphere((x, s_ * 0.28, 0.578), 0.01, WD("dark"), seg=6, rings=4)


def qb_bone_chest():
	W, D, H = 0.95, 0.52, 0.5
	sb((W, D, 0.06), (0, 0, 0.03), "c", bevel=0.01)
	front = sb((W, 0.07, H - 0.055), (0, -D / 2 + 0.035, 0.055 + (H - 0.055) / 2), "b", bevel=0.01)
	carve(front, crest("pick", -0.3, 0.29, 0.1, -D / 2) + runes(-0.15, 0.36, 0.33, -D / 2, h=0.05, gap=0.05)
		+ runes(-0.15, 0.3, 0.2, -D / 2, h=0.05, gap=0.05, under=False))
	sb((W, 0.07, H - 0.055), (0, D / 2 - 0.035, 0.055 + (H - 0.055) / 2), "b", bevel=0.01)
	for s_ in (-1, 1):
		sb((0.07, D - 0.13, H - 0.055), (s_ * (W / 2 - 0.035), 0, 0.055 + (H - 0.055) / 2), "a", bevel=0.01)
		kit.ring(0.045, 0.009, (s_ * (W / 2 + 0.01), 0, 0.36), IRON("dark"), rot=(0, 90, 0), seg=12)
		B((0.014, 0.04, 0.03), (s_ * (W / 2 + 0.004), 0, 0.4), IRON("dark"), bevel=0.003)
	for layer in range(5):  # long bones stacked in rows nearly to the brim, two skulls on top
		for j in range(5):
			y = -0.17 + j * 0.085
			bone((-0.12, y, 0.085 + layer * 0.05), (0.38, y + J(0.01), 0.085 + layer * 0.05), 0.019, BONE(-0.05 + 0.03 * ((j + layer) % 3)))
	for y in (-0.1, 0.1):
		skull((-0.22 + 0.36 * (y > 0), y, 0.32 + 0.1), 0.95, BONE(-0.03), face=(0.3, -1, 0))
	def lid():  # the lid, taken off and leaned against the chest's end (rests on its back-bottom edge)
		sb((0.07, D + 0.06, W + 0.06), (0.035, 0, (W + 0.06) / 2), "a", bevel=0.012)
		kit.ring(0.04, 0.009, (0.075, 0, W - 0.1), IRON("dark"), rot=(0, 90, 0), seg=12)
		B((0.012, 0.035, 0.03), (0.072, 0, W - 0.06), IRON("dark"), bevel=0.003)
	group(lid, at=(W / 2 + H * math.tan(math.radians(25)), 0, 0.0), rot=(0, -25, 0))


def qb_waymarker():
	sb((0.42, 0.42, 0.1), (0, 0, 0.05), "c", bevel=0.015)
	post = kit.taper(0.28, 0.28, 0.24, 0.24, 1.1, (0, 0, 0.095), S("b"), bevel=0.012)
	yf = -0.13
	carve(post, crest("hammers", 0, 0.98, 0.07, -0.125, w=0.01) + [cy(bar((-0.04, 0.72), (0.04, 0.72), 0.02), -0.13, 0.01)]
		+ [cy(bar((x, 0.62), (x, 0.82), 0.022), -0.13, 0.012) for x in (-0.05, 0.0, 0.05)] + runes(-0.08, 0.08, 0.45, -0.135, h=0.05, gap=0.05)
		+ runes(-0.08, 0.08, 0.35, -0.137, h=0.05, gap=0.05, under=False))
	sb((0.32, 0.32, 0.07), (0, 0, 1.225), "a", bevel=0.012)
	kit.cone(0.13, 0.05, 0.08, (0, 0, 1.3), S("a"), verts=4, rot=(0, 0, 45))
	B((0.05, 0.03, 0.1), (0, yf, 1.06), IRON("dark"), bevel=0.004)
	tube([(0, yf - 0.01, 1.08), (0, yf - 0.2, 1.08), (0, yf - 0.28, 1.1), (0, yf - 0.3, 1.14)], 0.012, 0.008, IRON("dark"), seg=6)
	rod((0, yf - 0.01, 0.98), (0, yf - 0.16, 1.08), 0.008, IRON("dark"))  # brace
	kit.ring(0.02, 0.005, (0, yf - 0.22, 1.065), IRON("dark"), rot=(0, 90, 0), seg=10)
	chain((0, yf - 0.22, 1.05), (0, yf - 0.22, 0.92), link=0.02, wire=0.005)
	lantern(0, yf - 0.22, 0.65)


def qb_token_pillar():
	sb((0.6, 0.6, 0.1), (0, 0, 0.05), "c", bevel=0.015)
	sb((0.46, 0.46, 0.08), (0, 0, 0.135), "b", bevel=0.012)
	col = kit.cylinder(0.16, 0.62, (0, 0, 0.17 + 0.31), S("b"), rot=(0, 0, 22.5), verts=8, bevel=0.01)
	yf = -0.16 * math.cos(math.radians(22.5))
	carve(col, runes(-0.05, 0.05, 0.6, yf, h=0.05, gap=0.045) + runes(-0.05, 0.05, 0.48, yf, h=0.05, gap=0.045, under=False)
		+ crest("mountain", 0, 0.72, 0.045, yf, w=0.008))
	_hl = hlathe([(0, 0), (0.2, 0), (0.24, 0.04), (0.25, 0.07), (0.21, 0.07), (0.16, 0.045), (0, 0.045)], (0, 0), S("a"), seg=20)
	_hl.location.z += 0.785
	pts = [(math.cos(a) * d, math.sin(a) * d, 0.035 + J(0.008)) for a, d in [(k * 1.3, 0.03 + (k % 4) * 0.035) for k in range(12)]]
	tokens(pts, 0.83)
	tokens([(math.cos(k * 2.1) * 0.04, math.sin(k * 2.1) * 0.04, 0.032) for k in range(3)], 0.85)
	for k in range(3):
		coin((0.06 * k - 0.05, -0.13 + 0.03 * k, 0.836), tilt=(J(6), J(6), 0))
	tokens([(-0.2, -0.17, 0.04), (0.19, -0.18, 0.036), (0.0, -0.2, 0.034), (0.2, 0.17, 0.04), (-0.19, 0.18, 0.035)], 0.175)


def qb_incense_stand():
	sb((0.4, 0.4, 0.08), (0, 0, 0.04), "c", bevel=0.014)
	lathe([(0.13, 0), (0.12, 0.03), (0.07, 0.08), (0.055, 0.35), (0.07, 0.5), (0.13, 0.55), (0.15, 0.58)], (0, 0, 0.078), S("b"), seg=18)
	z = 0.656
	_hl = hlathe([(0, 0), (0.06, 0), (0.12, 0.06), (0.13, 0.1), (0.12, 0.1), (0.11, 0.065), (0.055, 0.012), (0, 0.012)], (0, 0), CU("b"), seg=20)
	_hl.location.z += z - 0.002
	lid = lathe([(0.128, 0), (0.12, 0.03), (0.08, 0.07), (0.025, 0.09), (0.0001, 0.092)], (0, 0, z + 0.098), CU("b"), seg=20)
	carve(lid, [kit.cylinder(0.012, 0.2, (math.cos(a) * 0.08, math.sin(a) * 0.08, z + 0.16), GROOVE(), rot=(math.degrees(math.sin(a)) * 0.6, -math.degrees(math.cos(a)) * 0.6, 0), verts=6)
		for a in [2 * math.pi * k / 8 for k in range(8)]])
	sphere((0, 0, z + 0.2), 0.022, CU("dark"), seg=8, rings=5)
	for s_ in (-1, 1):
		kit.ring(0.03, 0.007, (s_ * 0.135, 0, z + 0.075), CU("dark"), rot=(90, 0, 0), seg=10)
	g = group(lambda: (rod((0, 0, 0), (0, 0.22, 0), 0.006, IRON("dark")), rod((0.012, 0, 0), (0.012, 0.22, 0), 0.006, IRON("dark")),
		kit.ring(0.012, 0.004, (0.006, 0.225, 0), IRON("dark"), seg=8)), at=(-0.08, -0.1, 0.087), rot=(0, 0, 30))
	B((0.14, 0.09, 0.05), (0.08, -0.06, 0.105), WD("b"), bevel=0.005)  # little box of incense cakes
	for k in range(4):
		B((0.025, 0.025, 0.02), (0.045 + (k % 2) * 0.035, -0.075 + (k // 2) * 0.035, 0.132), C((0.08, 0.05, 0.035), 0.9), bevel=0.004)


def qb_wash_basin():
	base = sb((0.42, 0.42, 0.1), (0, 0, 0.05), "c", bevel=0.015)
	carve(base, runes(-0.15, 0.15, 0.05, -0.21, h=0.045, w=0.008, gap=0.045, depth=0.006, under=False))
	lathe([(0.12, 0), (0.12, 0.03), (0.08, 0.07), (0.065, 0.42), (0.1, 0.47)], (0, 0, 0.098), S("b"), seg=18)
	_hl = hlathe([(0, 0), (0.12, 0), (0.24, 0.07), (0.27, 0.16), (0.24, 0.16), (0.22, 0.09), (0.11, 0.035), (0, 0.035)], (0, 0), S("a"), seg=24)
	_hl.location.z += 0.56
	kit.ring(0.255, 0.012, (0, 0, 0.72), S("a"), seg=28)
	lathe([(0.05, 0), (0.08, 0.04), (0.09, 0.14), (0.06, 0.22), (0.04, 0.26), (0.048, 0.28)], (-0.32, -0.18, 0), CLAY("b"), seg=16)
	kit.ring(0.045, 0.01, (-0.4, -0.18, 0.18), CLAY("b"), rot=(90, 0, 0), seg=10)


def qb_ancestor_bust():
	sb((0.56, 0.56, 0.1), (0, 0, 0.05), "c", bevel=0.015)
	sh = sb((0.42, 0.42, 0.8), (0, 0, 0.095 + 0.4), "b", bevel=0.015)
	carve(sh, crest("anvil", 0, 0.68, 0.09, -0.21) + runes(-0.15, 0.15, 0.48, -0.21, h=0.05, gap=0.05)
		+ runes(-0.13, 0.13, 0.37, -0.21, h=0.05, gap=0.05, under=False) + gline([(-0.16, 0.25), (0.16, 0.25)], 0.008, -0.21, 0.006))
	sb((0.5, 0.5, 0.07), (0, 0, 0.925), "a", bevel=0.014)
	lathe([(0.2, 0), (0.2, 0.025), (0.17, 0.04), (0.15, 0.06), (0.17, 0.075)], (0, 0, 0.955), S("b"), seg=24)  # round socle
	group(real_bust, at=(0, 0.0, 1.02), scale=0.62)  # its flat chest cut sunk 1 cm into the socle
	tokens([(-0.18, -0.19, 0.03), (0.17, -0.2, 0.025)], 0.96)
	candle(0.18, -0.235, 0.1, 0.022, 0.08, lit=True)
	tokens([(-0.2, -0.24, 0.03)], 0.1)
	slim(small=0.03, fine=0.005)  # under 2 MB


MODELS = {k: v for k, v in globals().items() if k.startswith("qb_") and callable(v)}

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
