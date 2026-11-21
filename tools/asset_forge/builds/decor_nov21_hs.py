# Decor set HS (Nov 21): HALL OF THE SHIELDBEARERS, a medium cut-stone dungeon (Stonehold greystone) where an old
# order of dwarf shield-guards lived. One stone family (greystone), one wood family (wood), iron/copper/leather fittings.
#   blender --background --factory-startup --python builds/decor_nov21_hs.py -- [id ...]   (none = all)
# Output: assets/models/decor/<id>.glb (origin bottom-centre, front faces -Y in Blender = +Z in Godot).
# Wall pieces have a flat back at +Y and stand on the floor (stone foot post or full-height slab).
#
# ---- the 30 models ----
# WALL PIECES (14)
#   hs_shield_wall        carved stone panel hung with 5 painted shields (anvil, tower, mountain, rays, pale) + crossed spears
#   hs_spear_rack         wall spear rack: butt trough with sockets, iron loops, 5 spears + 1 empty slot, squad badges on top
#   hs_axe_rack           plank board on a stone foot: 3 bearded axes on iron hooks, shelf with whetstones and oil flask
#   hs_helm_shelf         stone shelf unit with carved zigzags: 8 helmets of different kinds on turned wooden stands
#   hs_order_crest        big shield-shaped stone plaque, order crest CUT IN (crossed spears, shield, anvil), iron clamps
#   hs_roll_of_honour     tall stone tablet: carved rune rows of the fallen, iron shield tags on pegs, candle ledge
#   hs_split_shield_trophy round plaque: a shield split by the axe still stuck in it, copper name plate
#   hs_buckler_rail       iron rail with 6 small bucklers (dome, spike, ring, rivet bosses) on leather loops
#   hs_boss_shelf         repairer's spare-parts board: shield bosses on pegs, rim strips, trays of sorted rivets
#   hs_tool_wall          shield-maker's tool board with painted outlines: hammer, tongs, mallet, drawknife... one missing
#   hs_order_banner       the order's banner: swallowtail cloth, shield appliqué with anvil, gold bands, tassels
#   hs_squad_pennants     carved stone header with 5 squad pennants on iron arms, squad names cut below
#   hs_strap_rack         rack of leather shield straps with iron buckles, shelf with buckle box and round knife
#   hs_duty_roster        stone-framed peg board: rows of iron duty tags, carved day marks, empty pegs
# FLOOR PIECES AND STORY SCENES (16)
#   hs_repair_bench       story: bench with a half-repainted shield clamped down, rivet dish, hammer, paint pot
#   hs_shieldbearer_stand armour stand: dwarf-shaped form, scale shirt all round, pauldrons, gorget, helm, shield on a peg post
#   hs_muster_table       stone muster table, map grid cut into the top, iron shield tokens in formation, roll book, candle
#   hs_oath_stone         oath stone: hand-print cut into the top, carved shield, copper oath cup on the ground, kneeling step
#   hs_guard_bunk         bare two-tier guard bunk, iron brackets, ladder rungs, footlocker, shield on the post
#   hs_shield_pell        training pell: carved stone base, hacked post, padded arms, battered shield nailed on
#   hs_captains_chair     captain's chair on a stone dais, shield-shaped painted back, copper-capped arms
#   hs_fallen_shield_wall story: the last shield wall toppled like dominoes, broken spears, a helmet, a dropped axe
#   hs_last_stand_cairn   story: rubble cairn with the captain's axe planted in it, helmet on the haft, shield leaning
#   hs_paint_rack         story: drying rack of freshly painted shields, stool with paint pots, emblem stencil
#   hs_rim_jig            story: round bending jig with an iron shield rim half bent around its pegs, tools, a done hoop
#   hs_tower_shields_chained story: tall tower shields stacked against a stone ledge (no chain, owner Nov 22)
#   hs_war_horn_stand     carved stone stand with the order's great war horn in iron cradles, copper bands
#   hs_helm_trophy_pole   war trophy pole: captured helmets on chains, split enemy shield nailed on, lashed spear
#   hs_watch_brazier      guard brazier: carved pedestal, iron bowl with shield plates, black coal and embers, poker
#   hs_practice_trough    stone trough of practice weapons (padded spears, wooden axes and sword) in an iron rail
import math
import sys
from pathlib import Path

import bpy
from mathutils import Euler, Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from night_stations import B, GAME, J, T, kit, log, mesh, rivet, rng  # noqa: E402
from night_materials import C, lump, sphere, _cm  # noqa: E402
from decor_nov21_a import (slim as lighter, GROOVE_M, bar, carve, chain, chip, groove, groove_path, groove_ring, low_z, prism, rest,  # noqa: E402
	rod, rubble_heap, rune_row, shift, spin, tube)
from decor_nov21_f import group, lathe  # noqa: E402
from decor_nov21_vo import body_pts, body_ring, hollow_horn, jaw_helm, lame_row, mannequin, pauldron, ring_r  # noqa: E402

S = lambda v=None: T("greystone", v)  # noqa: E731
W = lambda v=None: T("wood", v)  # noqa: E731
IRON = lambda v="a": kit.tex_mat("iron", v)  # noqa: E731
CU = lambda v="b": kit.tex_mat("copper", v)  # noqa: E731
LEA = lambda v="dark": kit.tex_mat("leather", v)  # noqa: E731
WAX = lambda: C((0.75, 0.68, 0.5), 0.85)  # noqa: E731
FLAME = lambda: C((1.0, 0.55, 0.15), 0.3, glow=2.0)  # noqa: E731
PAPER = lambda: C((0.7, 0.63, 0.48), 0.95)  # noqa: E731
INK = lambda: C((0.12, 0.08, 0.06), 0.95)  # noqa: E731
PAINT = {"red": (0.3, 0.05, 0.04), "blue": (0.05, 0.1, 0.24), "ochre": (0.45, 0.29, 0.07), "bone": (0.5, 0.45, 0.35),
	"black": (0.06, 0.05, 0.045), "rust": (0.33, 0.14, 0.06)}
P = lambda k: C(PAINT[k], 0.9)  # noqa: E731
BACK = 0.075  # flat back plane of every wall piece
RIMS = []  # every shield rim made, so cuts can treat rims apart (two parts cut by one cutter = doubled walls = shimmer)


# ================= helpers =================
def made(fn):
	before = set(bpy.data.objects[:])
	fn()
	return [o for o in bpy.data.objects[:] if o not in before]


def place(fn, at=(0, 0, 0), rot=(0, 0, 0), floor=None):
	"""Build fn around the origin, turn by rot (degrees), move to at; floor=z drops it so its lowest point sits there."""
	obs = made(lambda: group(fn, at, rot))
	if floor is not None:
		bpy.context.view_layer.update()
		shift(obs, (0, 0, floor - low_z(obs)))
	return obs


def xf(p, at=(0, 0, 0), rot=(0, 0, 0)):
	"""Where a local point of a placed group ends up (same maths as group())."""
	return Vector(at) + Euler([math.radians(a) for a in rot]).to_matrix() @ Vector(p)


def put_frame(fn, X, Y, Z, local, target):
	"""Build fn, then move it so local axes become X, Y, Z (world vectors) and the local point lands on target."""
	R = Matrix((X, Y, Z)).transposed().to_4x4()
	M = Matrix.Translation(Vector(target)) @ R @ Matrix.Translation(-Vector(local))
	obs = made(fn)
	bpy.context.view_layer.update()
	for o in obs:
		o.matrix_world = M @ o.matrix_world
	return obs


def orient(o, d):
	"""Turn a part made along +Z so it points along d."""
	o.rotation_mode = "QUATERNION"
	o.rotation_quaternion = Vector(d).to_track_quat("Z", "Y")
	return o


def tgroove(p0, p1, z, w=0.012, depth=0.01):
	"""A carved stroke cutter on a TOP face at height z (x, y points)."""
	(x0, y0), (x1, y1) = p0, p1
	ang = math.degrees(math.atan2(y1 - y0, x1 - x0))
	return [B((math.hypot(x1 - x0, y1 - y0) + w * 0.9, w, depth + 0.03), ((x0 + x1) / 2, (y0 + y1) / 2, z - depth + (depth + 0.03) / 2),
		GROOVE_M(), bevel=0, rot=(0, 0, ang))]


def tgroove_path(pts, z, w=0.012, depth=0.01, closed=False):
	out = []
	for a, b in zip(pts, pts[1:] + (pts[:1] if closed else [])):
		out += tgroove(a, b, z, w, depth)
	return out


def band_path(pts, w, h, m):
	"""A flat metal strip (w across, h tall) following points in a level plane: a shield rim being bent."""
	pts = [Vector(p) for p in pts]
	n = len(pts)
	v = []
	for i, p in enumerate(pts):
		d = (pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]).normalized()
		side = d.cross(Vector((0, 0, 1))).normalized()
		for a, b in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
			v.append(tuple(p + side * a * w / 2 + Vector((0, 0, b * h / 2))))
	f = [(i * 4 + k, i * 4 + (k + 1) % 4, (i + 1) * 4 + (k + 1) % 4, (i + 1) * 4 + k) for i in range(n - 1) for k in range(4)]
	f += [(3, 2, 1, 0), tuple((n - 1) * 4 + k for k in range(4))]
	return mesh(v, f, m)


def foot(top, x=0.0):
	"""Stone foot post under a wall piece (the piece never floats when placed in the open)."""
	B((0.34, 0.17, 0.07), (x, BACK - 0.085, 0.035), S("c"), bevel=0.015)
	B((0.13, 0.035, top - 0.03), (x, BACK - 0.0225, (top + 0.03) / 2), S("b"), bevel=0.008)


def board(w, h, zc, d=0.05):
	"""Upright planks with a flat back at BACK, two riveted iron straps across the front."""
	n = max(2, round(w / 0.2))
	pw = w / n
	for i in range(n):
		B((pw - 0.005, d, h + J(0.012)), (-w / 2 + pw * (i + 0.5), BACK - d / 2, zc), W("abcb"[i % 4]), bevel=0.008)
	fy = BACK - d
	for z in (zc - h / 2 + 0.07, zc + h / 2 - 0.07):
		B((w + 0.02, 0.008, 0.035), (0, fy - 0.002, z), IRON("dark"), bevel=0.002)
		for i in range(n + 1):
			rivet((-w / 2 + 0.03 + (w - 0.06) * i / n, fy - 0.006, z), IRON("dark"), r=0.008)
	return fy


def dedupe(pts):
	out = []
	for p in pts:
		if not out or (abs(p[0] - out[-1][0]) > 1e-4 or abs(p[1] - out[-1][1]) > 1e-4):
			out.append(p)
	return out


# ----- shield emblems: outlines in a unit box, painted on as thin raised pieces -----
def _star(n=8, r0=1.0, r1=0.42):
	return [(math.cos(math.pi / 2 + k * math.pi / n) * (r0 if k % 2 == 0 else r1),
		math.sin(math.pi / 2 + k * math.pi / n) * (r0 if k % 2 == 0 else r1)) for k in range(2 * n)]


def _rays():
	out = []
	for k in range(8):
		a = k * math.pi / 4 + math.pi / 8
		out.append([(math.cos(a - 0.17) * 0.5, math.sin(a - 0.17) * 0.5), (math.cos(a - 0.1) * 1.0, math.sin(a - 0.1) * 1.0),
			(math.cos(a + 0.1) * 1.0, math.sin(a + 0.1) * 1.0), (math.cos(a + 0.17) * 0.5, math.sin(a + 0.17) * 0.5)])
	return out


EMB = {
	"anvil": [[(-1.0, 0.45), (-0.55, 0.55), (0.6, 0.55), (0.6, 0.3), (0.25, 0.15), (0.3, -0.35), (0.6, -0.6), (-0.6, -0.6),
		(-0.3, -0.35), (-0.25, 0.15), (-0.55, 0.3)]],
	"mountain": [[(-1.0, -0.6), (-0.45, 0.4), (-0.2, 0.05), (0.25, 0.75), (1.0, -0.6)]],
	"tower": [[(-0.6, -0.8), (0.6, -0.8), (0.6, 0.5), (0.75, 0.5), (0.75, 0.85), (0.45, 0.85), (0.45, 0.68), (0.15, 0.68),
		(0.15, 0.85), (-0.15, 0.85), (-0.15, 0.68), (-0.45, 0.68), (-0.45, 0.85), (-0.75, 0.85), (-0.75, 0.5), (-0.6, 0.5)]],
	"chevron": [[(-0.95, -0.35), (0.0, 0.45), (0.95, -0.35), (0.95, -0.72), (0.0, 0.08), (-0.95, -0.72)]],
	"hammer": [[(-0.6, 0.35), (0.6, 0.35), (0.6, 0.78), (-0.6, 0.78)], [(-0.13, -0.9), (0.13, -0.9), (0.13, 0.4), (-0.13, 0.4)]],
	"axe": [[(-0.09, -0.9), (0.09, -0.9), (0.09, 0.85), (-0.09, 0.85)], [(0.05, 0.62), (0.7, 0.95), (0.55, 0.35), (0.72, -0.2), (0.05, 0.18)]],
	"saltire": [bar((-0.8, -0.8), (0.8, 0.8), 0.3), bar((-0.8, 0.8), (0.8, -0.8), 0.3)],
	"cross": [bar((0.0, -1.0), (0.0, 1.0), 0.32), bar((-1.0, 0.15), (1.0, 0.15), 0.32)],
	"star": [_star()],
	"rays": _rays(),
	"pale": [[(-0.28, -1.2), (0.28, -1.2), (0.28, 1.2), (-0.28, 1.2)]],
}


def emblem(name, cx, cz, e, yf, m):
	"""Paint pieces on a face whose front is at yf (front = -Y), pressed into it; overlapping pieces at different depths."""
	for i, poly in enumerate(EMB[name]):
		prism([(cx + x * e, cz + z * e) for x, z in poly], yf - 0.004 - 0.003 * (i % 2), yf + 0.006, m)


HEATER = [(-1, 0.9), (0, 0.94), (1, 0.9), (0.97, 0.15), (0.84, -0.38), (0.55, -0.78), (0, -1.1), (-0.55, -0.78), (-0.84, -0.38), (-0.97, 0.15)]


def heater_pts(s, cx=0.0, cz=0.0):
	return [(cx + x * 0.22 * s, cz + z * 0.25 * s) for x, z in HEATER]


def heater(s=1.0, field="red", fig="ochre", emb="anvil", t=0.03, paint=1.0):
	"""A heater shield (flat top, pointed foot) centred at the origin: back at y=0, front -Y. Planks, painted field,
	emblem, iron rim and rivets. paint<1 = only the left part painted (a repair in progress)."""
	out = heater_pts(s)
	prism(out, -t, 0, W("b"))
	inner = [(x * 0.9, z * 0.9) for x, z in out]
	if paint < 1:
		lim = -0.2 * s + 0.4 * s * paint
		inner = dedupe([(min(x, lim), z) for x, z in inner])
	prism(inner, -t - 0.006, -t + 0.004, P(field))
	if emb and paint >= 1:
		emblem(emb, 0, 0.02 * s, 0.1 * s, -t - 0.006, P(fig))
	RIMS.append(tube([(x, -t / 2, z) for x, z in out + out[:1]], t / 2 + 0.004, t / 2 + 0.004, IRON("dark"), seg=6))
	for x, z in out:
		if paint >= 1 or x * 0.86 < -0.2 * s + 0.4 * s * paint:
			rivet((x * 0.86, -t - 0.006, z * 0.86), IRON("dark"), r=0.009 * max(0.6, min(s, 1.4)))


def roundsh(r=0.25, field="blue", fig="ochre", emb="rays", t=0.03, boss="dome"):
	"""A round shield centred at the origin, back at y=0, front -Y: planks, paint, emblem, boss, iron rim, rivets."""
	kit.cylinder(r, t, (0, -t / 2, 0), W("b"), rot=(90, 0, 0), verts=28, bevel=0.004)
	if field:
		kit.cylinder(r * 0.88, 0.01, (0, -t - 0.001, 0), P(field), rot=(90, 0, 0), verts=28, bevel=0)
	if emb:
		emblem(emb, 0, 0, r * (0.8 if emb == "rays" else 0.6), -t - 0.006, P(fig))
	RIMS.append(kit.ring(r, t / 2 + 0.005, (0, -t / 2, 0), IRON("dark"), rot=(90, 0, 0), seg=28))
	rr = r - t / 2 - 0.03
	for k in range(12):
		a = 2 * math.pi * k / 12 + 0.26
		rivet((math.cos(a) * rr, -t - 0.006, math.sin(a) * rr), IRON("dark"), r=0.008)
	if not boss:
		return
	bz = r * 0.3
	kit.cylinder(bz, 0.016, (0, -t - 0.012, 0), IRON("dark"), rot=(90, 0, 0), verts=16, bevel=0.003)
	yf = -t - 0.02
	if boss == "dome":
		sphere((0, yf, 0), bz * 0.72, IRON("a"), scale=(1, 0.7, 1))
	elif boss == "spike":
		sphere((0, yf, 0), bz * 0.6, IRON("a"), scale=(1, 0.5, 1))
		kit.cone(bz * 0.4, 0.003, bz * 1.3, (0, yf - bz * 0.6, 0), IRON("a"), rot=(90, 0, 0), verts=8, bevel=0)
	elif boss == "ring":
		sphere((0, yf, 0), bz * 0.45, IRON("a"), scale=(1, 0.6, 1))
		kit.ring(bz * 0.72, 0.007, (0, yf - 0.002, 0), CU(), rot=(90, 0, 0), seg=16)
	else:
		sphere((0, yf, 0), bz * 0.4, CU(), scale=(1, 0.6, 1))
	for k in range(6):
		a = 2 * math.pi * k / 6
		rivet((math.cos(a) * bz * 0.85, yf, math.sin(a) * bz * 0.85), CU("dark"), r=0.007)


def helm(kind="ridge", s=1.0, m=None):
	"""A dwarf helmet, rim at z=0, face to -Y: dome, riveted brow band, nasal; kinds add ridge, spike, cheek guards,
	kettle brim, copper crest or spectacle guard."""
	m = m or IRON("a")
	dk = IRON("dark")
	r = 0.12 * s
	sphere((0, 0, 0), r, m, scale=(1, 1.1, 1.12), seg=18, rings=10, cut=0.0)
	b = kit.ring(r * 1.01, 0.011 * s, (0, 0, 0.012 * s), dk, seg=22)
	b.scale = (1, 1.1, 1)
	for k in range(12):
		a = 2 * math.pi * k / 12
		rivet((math.cos(a) * r * 1.07, math.sin(a) * r * 1.17, 0.012 * s), CU("dark"), r=0.006 * s)
	if kind != "brim":
		B((0.026 * s, 0.014 * s, 0.12 * s), (0, -r * 1.1 - 0.006 * s, -0.035 * s), m, bevel=0.003)
	if kind in ("ridge", "cheeks", "mask"):
		pts = [(0, -r * 1.1 * math.cos(t), r * 1.12 * math.sin(t)) for t in (0.35, 0.8, 1.2, 1.57, 1.95, 2.4, 2.8)]
		tube(pts, 0.012 * s, 0.012 * s, dk, seg=6)
	if kind == "spike":
		kit.cone(0.03 * s, 0.003, 0.1 * s, (0, 0, r * 1.12 + 0.04 * s), m, verts=8, bevel=0)
		kit.ring(0.028 * s, 0.007 * s, (0, 0, r * 1.08), CU(), seg=12)
	if kind == "cheeks":
		for s_ in (-1, 1):
			B((0.012 * s, 0.09 * s, 0.11 * s), (s_ * r * 1.0, -0.015 * s, -0.045 * s), m, bevel=0.003, rot=(0, -s_ * 6, 0))
			rivet((s_ * r * 1.06, -0.04 * s, -0.01 * s), CU("dark"), r=0.006 * s)
	if kind == "brim":
		o = kit.cylinder(r * 1.5, 0.012 * s, (0, 0, 0.004 * s), m, verts=22, bevel=0.003)
		o.scale = (1, 1.08, 1)
	if kind == "crest":
		prism([(-r * 0.95, r * 0.55), (-r * 0.5, r * 1.3), (r * 0.5, r * 1.35), (r * 1.05, r * 0.7), (r * 0.6, r * 0.9), (-r * 0.4, r * 0.85)],
			-0.008 * s, 0.008 * s, CU(), axis="x")
	if kind == "mask":
		for s_ in (-1, 1):
			kit.ring(0.03 * s, 0.007 * s, (s_ * 0.038 * s, -r * 1.06, -0.012 * s), m, rot=(90, 0, 0), seg=12)


def helm_stand(x, y, z0, h=0.12):
	lathe([(0, z0), (0.055, z0), (0.058, z0 + 0.012), (0.03, z0 + 0.03), (0.022, z0 + h - 0.02), (0.04, z0 + h), (0.0, z0 + h + 0.012)],
		(x, y), W("dark"), seg=12)


def spear(L=1.7, head="leaf", butt=True):
	"""A spear along +Z from z=0: iron butt cap (or a snapped, splintered end), shaft, leather grip, socket and a
	leaf/long/winged head."""
	top = L - 0.26
	log((0, 0, 0.012), (0, 0, top + 0.05), 0.016, W("c"), seg=7, rings=2, bend=0.004)
	if butt:
		kit.cylinder(0.02, 0.07, (0, 0, 0.035), IRON("dark"), verts=8, bevel=0.003)
	else:
		for k in range(4):
			kit.cone(0.008, 0.001, 0.05 + 0.02 * (k % 2), (math.cos(k * 1.7) * 0.007, math.sin(k * 1.7) * 0.007, -0.01), W("a"), rot=(180, 0, 0), verts=4, bevel=0)
	kit.cone(0.023, 0.017, 0.12, (0, 0, top + 0.03), IRON("a"), verts=8, bevel=0.002)
	kit.ring(0.022, 0.004, (0, 0, top - 0.02), IRON("dark"), seg=10)
	if head == "long":
		pts = [(0, top + 0.06), (0.022, top + 0.1), (0.018, L - 0.04), (0, L), (-0.018, L - 0.04), (-0.022, top + 0.1)]
	else:
		pts = [(0, top + 0.06), (0.04, top + 0.13), (0.032, L - 0.07), (0, L), (-0.032, L - 0.07), (-0.04, top + 0.13)]
	prism(pts, -0.007, 0.007, IRON("a"))
	B((0.008, 0.02, L - top - 0.13), (0, 0, (top + 0.1 + L - 0.03) / 2), IRON("dark"), bevel=0.002)
	if head == "wing":
		B((0.13, 0.016, 0.022), (0, 0, top + 0.085), IRON("dark"), bevel=0.004)
	gz = L * 0.42
	kit.cylinder(0.02, 0.22, (0, 0, gz), LEA(), verts=8, bevel=0.003)
	for z in (gz - 0.11, gz + 0.11):
		kit.ring(0.02, 0.004, (0, 0, z), CU("dark"), seg=10)


def broken_spear(L=0.9):
	"""The lower half of a snapped spear: butt cap, shaft, grip, splintered end."""
	log((0, 0, 0.012), (0, 0, L), 0.016, W("c"), seg=7, rings=2, bend=0.004)
	kit.cylinder(0.02, 0.07, (0, 0, 0.035), IRON("dark"), verts=8, bevel=0.003)
	kit.cylinder(0.02, 0.2, (0, 0, L * 0.5), LEA(), verts=8, bevel=0.003)
	for k in range(4):
		a = k * 1.7
		kit.cone(0.008, 0.001, 0.05 + 0.02 * (k % 2), (math.cos(a) * 0.007, math.sin(a) * 0.007, L + 0.02), W("a"), verts=4, bevel=0)


def axe(L=0.8, s=1.0, grip=True):
	"""A bearded axe along +Z from z=0, blade to +X in the xz plane."""
	log((0, 0, 0.02), (0, 0, L - 0.03), 0.019, W("c"), seg=7, rings=2, bend=0.006)
	kit.cylinder(0.025, 0.04, (0, 0, 0.02), IRON("dark"), verts=8, bevel=0.003)
	hz = L - 0.07
	B((0.06 * s, 0.044 * s, 0.1 * s), (0, 0, hz), IRON("dark"), bevel=0.006)
	q = 0.004 * s
	prism([(0.025 * s, hz + 0.04 * s), (0.1 * s, hz + 0.07 * s), (0.175 * s - q, hz + 0.11 * s - q), (0.2 * s - q, hz + 0.03 * s),
		(0.19 * s - q, hz - 0.08 * s), (0.15 * s - q, hz - 0.17 * s + q), (0.11 * s, hz - 0.15 * s), (0.08 * s, hz - 0.06 * s),
		(0.025 * s, hz - 0.035 * s)], -0.009 * s, 0.009 * s, IRON("a"))
	prism([(0.165 * s, hz + 0.1 * s), (0.2 * s, hz + 0.03 * s), (0.19 * s, hz - 0.08 * s), (0.15 * s, hz - 0.17 * s), (0.135 * s, hz - 0.15 * s),
		(0.17 * s, hz - 0.07 * s), (0.178 * s, hz + 0.03 * s), (0.152 * s, hz + 0.085 * s)], -0.011 * s, 0.011 * s, kit.tex_mat("silver", "a"))
	B((0.04 * s, 0.038 * s, 0.065 * s), (-0.045 * s, 0, hz), IRON("dark"), bevel=0.005)
	rivet((0, -0.022 * s, hz + 0.02 * s), CU("dark"), r=0.008)
	if grip:
		kit.cylinder(0.022, 0.16, (0, 0, 0.16), LEA(), verts=8, bevel=0.003)
		for z in (0.08, 0.24):
			kit.ring(0.022, 0.004, (0, 0, z), CU("dark"), seg=10)


def hammer(L=0.36, s=1.0):
	"""A cross-pein hammer along +Z from z=0, head across x."""
	log((0, 0, 0.0), (0, 0, L), 0.013 * s, W("c"), seg=7, rings=1, bend=0.004)
	B((0.12 * s, 0.034 * s, 0.036 * s), (0.01 * s, 0, L - 0.004), IRON("a"), bevel=0.004)
	kit.cylinder(0.022 * s, 0.022 * s, (0.08 * s, 0, L - 0.004), IRON("dark"), rot=(0, 90, 0), verts=10, bevel=0.003)
	prism([(-0.05 * s, L - 0.022 * s), (-0.085 * s, L - 0.006 * s), (-0.085 * s, L - 0.0), (-0.05 * s, L + 0.014 * s)], -0.018 * s, 0.018 * s, IRON("dark"))
	B((0.012 * s, 0.03 * s, 0.01 * s), (0.0, 0, L + 0.016 * s), IRON("dark"), bevel=0.002)


def tongs(L=0.45):
	for s_ in (-1, 1):
		pts = [(s_ * 0.014, 0.0), (s_ * 0.026, L * 0.55), (s_ * 0.008, L * 0.75), (s_ * 0.026, L * 0.9), (s_ * 0.012, L)]
		tube([(x, s_ * 0.004, z) for x, z in pts], 0.008, 0.007, IRON("dark"), seg=6)
	rivet((0, -0.01, L * 0.75), IRON("a"), r=0.012)


def hang(x, ztop, yb, fy=BACK - 0.07):
	"""An iron hook from the wall and a leather V strap down to a shield's top edge (shield back at yb)."""
	rod((x, fy + 0.03, ztop + 0.08), (x, yb - 0.05, ztop + 0.1), 0.008, IRON("dark"))
	sphere((x, yb - 0.05, ztop + 0.1), 0.013, IRON("dark"))
	for s_ in (-1, 1):
		tube([(x, yb - 0.045, ztop + 0.095), (x + s_ * 0.05, yb - 0.03, ztop + 0.045), (x + s_ * 0.09, yb - 0.02, ztop - 0.004)], 0.007, 0.007, LEA(), seg=5)


def candle(x, y, z, h=0.12):
	kit.cylinder(0.035, 0.012, (x, y, z + 0.004), IRON("dark"), verts=10, bevel=0.002)
	kit.cylinder(0.02, h, (x, y, z + 0.008 + h / 2), WAX(), verts=10, bevel=0.003)
	kit.cylinder(0.002, 0.02, (x, y, z + 0.008 + h + 0.006), INK(), verts=4, bevel=0)
	kit.cone(0.011, 0.0, 0.04, (x, y, z + 0.008 + h + 0.032), FLAME(), verts=8, bevel=0)


# ================= wall pieces =================
def hs_shield_wall():
	"""A carved stone panel of the order hung with five painted shields on hooks and V straps, crossed spears behind the
	middle one, names cut in rune rows under each shield."""
	Wd, H, z0 = 2.0, 1.72, 0.115
	B((Wd + 0.12, 0.2, 0.12), (0, BACK - 0.1, 0.06), S("c"), bevel=0.02)
	panel = B((Wd, 0.065, H), (0, 0.0375, z0 + H / 2), S("b"), bevel=0.012)
	cap = B((Wd + 0.12, 0.16, 0.12), (0, BACK - 0.08, z0 + H + 0.05), S("c"), bevel=0.02)
	fy = 0.005
	cut = groove_path([(-Wd / 2 + 0.07, z0 + 0.07), (Wd / 2 - 0.07, z0 + 0.07), (Wd / 2 - 0.07, z0 + H - 0.07), (-Wd / 2 + 0.07, z0 + H - 0.07)], fy, 0.016, 0.012, closed=True)
	for i, x in enumerate((-0.62, 0.0, 0.62)):
		cut += rune_row(x - 0.17, x + 0.17, 1.02, fy, h=0.06, seed=11 + i)
	for i, x in enumerate((-0.62, 0.62)):
		cut += rune_row(x - 0.15, x + 0.15, 0.33, fy, h=0.055, seed=21 + i)
	carve(panel, cut)
	carve(cap, [chip((-Wd / 2 - 0.06, BACK - 0.16, z0 + H + 0.1), (0.06, 0.05, 0.05), seed=3), chip((Wd / 2 + 0.05, BACK - 0.16, z0 + H + 0.0), (0.05, 0.04, 0.04), seed=4)])
	for s_ in (-1, 1):  # crossed spears behind the middle shield
		rot = (0, s_ * 35, 0)
		L = 1.1
		c = xf((0, 0, L / 2), (0, 0, 0), rot)
		place(lambda: spear(L, "leaf" if s_ < 0 else "long"), at=(-c.x, -0.012, 0.66 - c.z), rot=rot)
	B((0.07, 0.03, 0.05), (0, -0.015, 0.66), IRON("dark"), bevel=0.004)
	tops = [(-0.62, 1.42, 1.2, "red", "ochre", "anvil"), (0.0, 1.42, 1.3, "blue", "bone", "tower"), (0.62, 1.42, 1.2, "ochre", "black", "mountain")]
	for x, z, s, f, g, e in tops:
		place(lambda: heater(s, f, g, e), at=(x, fy, z))
		hang(x, z + 0.94 * 0.25 * s, fy)
	place(lambda: heater(1.0, "bone", "red", "chevron"), at=(0, -0.03, 0.68))
	hang(0, 0.68 + 0.235, -0.03)
	for x, f, g, e, b in ((-0.62, "red", "bone", "rays", "dome"), (0.62, "blue", "ochre", "pale", "spike")):
		place(lambda: roundsh(0.25, f, g, e, boss=b), at=(x, fy, 0.72))
		hang(x, 0.72 + 0.25, fy)


def hs_spear_rack():
	"""A wooden wall rack: a butt trough with sockets cut in, two rails with iron loops, five spears and one empty slot,
	a top beam with the six squads' painted badges."""
	for s_ in (-1, 1):
		B((0.08, 0.065, 2.0), (s_ * 0.66, BACK - 0.0375, 1.0), W("dark"), bevel=0.01)
	tr = B((1.36, 0.22, 0.1), (0, BACK - 0.11, 0.05), W("b"), bevel=0.01)
	xs = [-0.5 + 0.2 * i for i in range(6)]
	carve(tr, [kit.cylinder(0.026, 0.08, (x, -0.04, 0.09), GROOVE_M(), verts=12, bevel=0) for x in xs])
	for z in (0.95, 1.5):
		B((1.3, 0.07, 0.08), (0, BACK - 0.045, z), W("c"), bevel=0.008)
		for s_ in (-1, 1):
			B((0.12, 0.008, 0.03), (s_ * 0.58, -0.006, z), IRON("dark"), bevel=0.002)
			for dx in (-0.04, 0.04):
				rivet((s_ * 0.58 + dx, -0.01, z), IRON("dark"), r=0.007)
		for x in xs:
			kit.ring(0.03, 0.006, (x, -0.035, z), IRON("dark"), seg=14)
	B((1.44, 0.09, 0.1), (0, BACK - 0.045, 1.97), W("b"), bevel=0.01)
	heads = ("leaf", "wing", "long", None, "leaf", "long")
	cols = ("red", "blue", "ochre", "bone", "black", "rust")
	for i, x in enumerate(xs):
		if heads[i]:
			place(lambda: spear(1.74 + 0.04 * (i % 2), heads[i]), at=(x, -0.04, 0.054))
		prism(heater_pts(0.24, x, 1.97), -0.022, -0.008, IRON("dark"))
		prism(heater_pts(0.19, x, 1.972), -0.026, -0.018, P(cols[i]))
		rivet((x, -0.026, 1.985), CU("dark"), r=0.007)


def hs_axe_rack():
	"""A plank board on a stone foot: three bearded axes of different sizes on iron hooks, heads to alternate sides,
	and a little shelf with two whetstones, a copper oil flask and a leather edge guard."""
	foot(0.95)
	fy = board(1.15, 0.8, 1.28)
	rows = ((1.57, 0.65, 0.9, (0, 90, 0)), (1.34, 0.78, 1.05, (0, 90, 180)), (1.1, 0.92, 1.25, (0, 90, 0)))
	for z, L, s, rot in rows:
		y = -0.045
		c = xf((0, 0, L / 2), (0, 0, 0), rot)
		place(lambda: axe(L, s), at=(-c.x, y, z - c.z), rot=rot)
		for x in (-0.24, 0.24):
			rod((x, fy + 0.02, z - 0.03), (x, y - 0.03, z - 0.03), 0.007, IRON("dark"))
			rod((x, y - 0.03, z - 0.034), (x, y - 0.03, z + 0.015), 0.007, IRON("dark"))
	sz = 0.9
	B((1.1, 0.17, 0.035), (0, fy - 0.08, sz), W("c"), bevel=0.006)
	for x in (-0.45, 0.45):
		prism([(fy + 0.005, sz - 0.017), (fy - 0.15, sz - 0.017), (fy + 0.005, sz - 0.13)], x - 0.015, x + 0.015, W("dark"), axis="x")
	top = sz + 0.0175
	for i, x in enumerate((-0.38, -0.24)):
		o = B((0.13, 0.045, 0.03), (x, fy - 0.08, top + 0.013), S("b" if i else "c"), bevel=0.008, rot=(0, 0, 8 - 14 * i))
	lathe([(0, top - 0.003), (0.035, top - 0.003), (0.045, top + 0.05), (0.03, top + 0.1), (0.012, top + 0.12), (0.012, top + 0.15),
		(0, top + 0.15)], (0.05, fy - 0.08), CU(), seg=14)
	kit.cylinder(0.014, 0.02, (0.05, fy - 0.08, top + 0.155), W("dark"), verts=8, bevel=0.002)
	B((0.2, 0.05, 0.012), (0.3, fy - 0.085, top + 0.003), LEA("b"), bevel=0.003, rot=(0, 0, -6))
	for x in (0.22, 0.38):
		rivet((x, fy - 0.085, top + 0.01), CU("dark"), r=0.006)


def hs_helm_shelf():
	"""A stone shelf unit with zigzags and runes cut into it: eight helmets of different kinds on turned stands."""
	sides = [B((0.1, 0.32, 1.42), (s_ * 0.6, BACK - 0.16, 0.71), S("b"), bevel=0.012) for s_ in (-1, 1)]
	B((1.12, 0.05, 1.36), (0, BACK - 0.03, 0.71), S("c"), bevel=0.008)
	shelves = [B((1.14, 0.27, 0.06), (0, BACK - 0.18, z), S("a" if z > 0.3 else "c"), bevel=0.012) for z in (0.05, 0.55, 1.03)]
	cap = B((1.36, 0.36, 0.08), (0, BACK - 0.16, 1.44), S("c"), bevel=0.015)
	fy = BACK - 0.32
	cut = []
	for s_ in (-1, 1):
		pts = [(s_ * 0.6 + (0.025 if k % 2 else -0.025), 0.12 + k * 0.1) for k in range(13)]
		cut += groove_path(pts, fy, 0.012, 0.01)
	for z in (0.05, 0.55, 1.03):
		cut += groove((-0.5, z), (0.5, z), BACK - 0.315, 0.01, 0.008)
	cut += rune_row(-0.55, 0.55, 1.44, BACK - 0.34, h=0.05, seed=7)
	carve(sides + shelves + [cap], cut)
	kinds = (("brim", "cheeks", "mask"), ("spike", "ridge", "crest"), ("ridge", "cheeks", "plain"))
	for row, zt in enumerate((0.08, 0.58, 1.06)):
		for j, x in enumerate((-0.33, 0.0, 0.33)):
			if row == 0 and j == 2:
				continue
			helm_stand(x, -0.11, zt - 0.004)
			k = kinds[row][j]
			place(lambda: helm(k, 1.0, IRON("a" if (row + j) % 2 else "b")), at=(x, -0.11, zt + 0.106))
	# a helmet left lying on the bottom shelf, turned on its side
	place(lambda: helm("mask"), at=(0.33, -0.12, 0), rot=(0, 75, -30), floor=0.078)


def hs_order_crest():
	"""The order's crest: a big shield-shaped stone plaque on a stone post, crossed spears, a shield and an anvil CUT IN,
	a rune band on top, iron edge clamps, a hanging ring and a copper name plate with cut runes."""
	foot(1.0)
	cz = 1.35
	slab = prism(heater_pts(2.4, 0, cz), 0.0, BACK, S("b"))
	fy = 0.0
	cut = groove_path(heater_pts(2.4 * 0.92, 0, cz + 0.01), fy, 0.018, 0.014, closed=True)
	cut += groove_path(heater_pts(2.4 * 0.86, 0, cz + 0.015), fy, 0.008, 0.01, closed=True)
	cut += groove_path(heater_pts(0.95, 0, cz - 0.03), fy, 0.02, 0.016, closed=True)
	cut += groove_path([(x * 0.11, cz - 0.03 + z * 0.11) for x, z in EMB["anvil"][0]], fy, 0.012, 0.012, closed=True)
	for s_ in (-1, 1):
		cut += groove((s_ * -0.36, 0.98), (s_ * -0.2, 1.15), fy, 0.022, 0.014)
		cut += groove((s_ * 0.19, 1.55), (s_ * 0.3, 1.67), fy, 0.022, 0.014)
		tip = (s_ * 0.33, 1.7)
		cut += groove_path([(tip[0] - s_ * 0.05, tip[1] - 0.01), (tip[0] + s_ * 0.02, tip[1] + 0.04), (tip[0], tip[1] - 0.04)], fy, 0.012, 0.012, closed=True)
	cut += rune_row(-0.3, 0.3, 1.8, fy, h=0.055, seed=31)
	carve(slab, cut)
	for x, z, a in ((-0.535, 1.6, 0), (0.535, 1.6, 0), (-0.46, 1.1, 0), (0.46, 1.1, 0)):
		B((0.07, 0.082, 0.045), (x, 0.029, z), IRON("dark"), bevel=0.005)
		rivet((x, -0.012, z), CU("dark"), r=0.009)
	kit.ring(0.05, 0.01, (0, 0.035, 1.96), IRON("dark"), rot=(90, 0, 0), seg=16)
	plate = B((0.3, 0.012, 0.07), (0, -0.004, 0.86), CU(), bevel=0.003)
	carve(plate, rune_row(-0.12, 0.12, 0.86, -0.01, h=0.04, w=0.008, depth=0.004, seed=32))
	for x in (-0.135, 0.135):
		rivet((x, -0.01, 0.86), CU("dark"), r=0.007)


def hs_roll_of_honour():
	"""A tall stone tablet of the fallen: a carved shield and anvil at the top, seven rows of names cut in with ruling
	lines, iron shield tags hung on pegs beside five rows, and a ledge with candles and a copper bowl."""
	B((1.1, 0.3, 0.12), (0, BACK - 0.15, 0.06), S("c"), bevel=0.02)
	slab = B((0.95, 0.095, 1.45), (0, BACK - 0.0525, 0.115 + 0.725), S("b"), bevel=0.012)
	cap = B((1.04, 0.15, 0.12), (0, BACK - 0.08, 1.6), S("c"), bevel=0.02)
	fy = BACK - 0.1
	cut = groove_path(heater_pts(0.9, 0, 1.36), fy, 0.016, 0.014, closed=True)
	cut += groove_path([(x * 0.075, 1.365 + z * 0.075) for x, z in EMB["anvil"][0]], fy, 0.01, 0.01, closed=True)
	cut += groove_path([(-0.42, 0.47), (0.42, 0.47), (0.42, 1.52), (-0.42, 1.52)], fy, 0.012, 0.01, closed=True)
	rows = [1.14 - 0.095 * i for i in range(7)]
	for i, z in enumerate(rows):
		cut += rune_row(-0.36, 0.22, z, fy, h=0.05, w=0.01, seed=40 + i)
		cut += groove((-0.38, z - 0.04), (0.38, z - 0.04), fy, 0.005, 0.005)
	carve(slab, cut)
	carve(cap, rune_row(-0.4, 0.4, 1.6, BACK - 0.155, h=0.05, seed=48))
	for i, z in enumerate(rows):
		if i in (2, 5):
			continue
		rod((0.32, fy + 0.02, z + 0.02), (0.32, fy - 0.04, z + 0.02), 0.006, IRON("dark"))
		prism(heater_pts(0.16, 0.32, z - 0.025), fy - 0.03, fy - 0.022, IRON("a" if i % 2 else "b"))
		rivet((0.32, fy - 0.031, z - 0.025), CU("dark"), r=0.006)
	B((0.86, 0.16, 0.05), (0, fy - 0.075, 0.38), S("a"), bevel=0.01)
	for s_ in (-1, 1):
		B((0.08, 0.12, 0.12), (s_ * 0.33, fy - 0.055, 0.3), S("c"), bevel=0.01)
	for x, h in ((-0.3, 0.14), (-0.18, 0.09), (0.25, 0.12)):
		candle(x, fy - 0.075, 0.402, h)
	lathe([(0, 0.402), (0.05, 0.402), (0.075, 0.44), (0.068, 0.44), (0.045, 0.412), (0, 0.412)], (0.03, fy - 0.075), CU(), seg=16)


def hs_split_shield_trophy():
	"""A round wooden plaque that hangs on the wall (flat back, no stand): a shield split from the top edge by an axe that is still stuck in it, two
	more gouges in the paint, and a copper plate with runes cut in."""
	kit.cylinder(0.42, 0.05, (0, 0.05, 1.3), W("b"), rot=(90, 0, 0), verts=24, bevel=0.01)
	kit.ring(0.42, 0.02, (0, 0.045, 1.3), CU(), rot=(90, 0, 0), seg=28)
	for k in range(8):
		a = 2 * math.pi * k / 8 + 0.4
		rivet((math.cos(a) * 0.37, 0.022, 1.3 + math.sin(a) * 0.37), CU("dark"), r=0.009)
	sy, sz = 0.027, 1.33
	parts = place(lambda: heater(1.3, "blue", "bone", "tower"), at=(0, sy, sz))
	fr = sy - 0.036
	cut = [prism([(0.042, 1.7), (0.098, 1.7), (0.08, 1.35), (0.066, 1.35)], -0.1, 0.03, GROOVE_M())]
	cut += groove((-0.2, 1.25), (-0.05, 1.08), fr, 0.012, 0.012) + groove((0.12, 1.12), (0.2, 1.22), fr, 0.01, 0.01)
	carve(parts, cut)
	h = Vector((0.45, -0.55, -0.7)).normalized()
	b0 = Vector((0, 1, 0))
	b = (b0 - h * b0.dot(h)).normalized()
	s = 1.2
	L = 0.85
	Z = -h  # the head end of the haft is local +Z, so the haft runs back out along h
	put_frame(lambda: axe(L, s), b, Z.cross(b), Z, (0.19 * s, 0, L - 0.07 - 0.02 * s), tuple(Vector((0.068, 0.0, 1.4)) + b * 0.06))  # blade sunk deep (owner Nov 22)
	plate = B((0.22, 0.012, 0.06), (0, 0.022, 0.95), CU(), bevel=0.003)
	carve(plate, rune_row(-0.08, 0.08, 0.95, 0.016, h=0.035, w=0.007, depth=0.004, seed=51))


def hs_buckler_rail():
	"""An iron rail on a plank board with six small bucklers hung on leather loops: dome, spike, ring and rivet bosses."""
	for x in (-0.55, 0.55):
		foot(1.12, x)
	fy = board(1.5, 0.42, 1.25)
	rz, ry = 1.38, -0.03
	rod((-0.72, ry, rz), (0.72, ry, rz), 0.012, IRON("dark"))
	for x in (-0.72, 0.72):
		sphere((x, ry, rz), 0.02, IRON("a"))
	for x in (-0.68, 0.0, 0.68):
		B((0.035, 0.06, 0.05), (x, 0.0, rz), IRON("dark"), bevel=0.004)
	bosses = ("dome", "spike", "ring", "rivets", "dome", "spike")
	fields = (("red", "bone", "pale"), ("blue", "ochre", "rays"), ("ochre", "black", None), ("black", "ochre", "cross"),
		("bone", "red", "rays"), ("rust", "bone", None))
	for i in range(6):
		x = -0.6 + 0.24 * i
		f, g, e = fields[i]
		place(lambda: roundsh(0.11, f, g, e, t=0.025, boss=bosses[i]), at=(x, fy - 0.003, rz - 0.145))
		tube([(x, ry - 0.016, rz + 0.004), (x, ry - 0.006, rz + 0.02), (x, ry + 0.014, rz + 0.016), (x, fy - 0.012, rz - 0.02),
			(x, fy - 0.014, rz - 0.04)], 0.006, 0.006, LEA(), seg=5)


def hs_boss_shelf():
	"""The repairer's spare-parts board: four shield bosses on pegs, three iron rim strips on pegs, and a ledge of five
	small trays of sorted rivets with paper labels."""
	foot(0.9)
	fy = board(1.1, 0.82, 1.27)
	for i, x in enumerate((-0.36, -0.12, 0.12, 0.36)):
		z = 1.5
		rod((x, fy + 0.02, z), (x, fy - 0.03, z), 0.008, IRON("dark"))
		kit.cylinder(0.07, 0.012, (x, fy - 0.034, z), IRON("dark"), rot=(90, 0, 0), verts=16, bevel=0.003)
		if i == 1:
			sphere((x, fy - 0.04, z), 0.045, IRON("a"), scale=(1, 0.5, 1))
			kit.cone(0.02, 0.002, 0.06, (x, fy - 0.08, z), IRON("a"), rot=(90, 0, 0), verts=8, bevel=0)
		else:
			sphere((x, fy - 0.04, z), 0.052, IRON("a" if i % 2 else "b"), scale=(1, 0.7, 1))
		if i == 2:
			kit.ring(0.04, 0.006, (x, fy - 0.07, z), CU(), rot=(90, 0, 0), seg=14)
		for k in range(6):
			a = 2 * math.pi * k / 6 + 0.3
			rivet((x + math.cos(a) * 0.06, fy - 0.04, z + math.sin(a) * 0.06), CU("dark"), r=0.006)
	R = 0.28
	for cx in (-0.33, 0.0, 0.33):
		cz = 1.24
		pts = [(cx + R * math.sin(math.radians(a)), fy - 0.03, cz + 0.06 - R * (1 - math.cos(math.radians(a)))) for a in range(-48, 49, 12)]
		tube(pts, 0.01, 0.01, IRON("dark"), seg=4)
		for a in (-28, 28):
			px = cx + R * math.sin(math.radians(a))
			pz = cz + 0.06 - R * (1 - math.cos(math.radians(a))) - 0.016
			rod((px, fy + 0.02, pz), (px, fy - 0.05, pz), 0.006, W("dark"))
	lz = 0.98
	B((1.06, 0.17, 0.03), (0, fy - 0.08, lz), W("c"), bevel=0.006)
	for x in (-0.48, 0.48):
		prism([(fy + 0.005, lz - 0.015), (fy - 0.14, lz - 0.015), (fy + 0.005, lz - 0.12)], x - 0.012, x + 0.012, IRON("dark"), axis="x")
	top = lz + 0.015
	for i in range(5):
		x = -0.4 + 0.2 * i
		y0, w, d, h = fy - 0.085, 0.17, 0.13, 0.045
		B((w - 0.02, d - 0.02, 0.012), (x, y0, top + 0.004), W("dark"), bevel=0.002)
		for s_ in (-1, 1):
			B((w, 0.01, h), (x, y0 + s_ * (d / 2 - 0.005), top - 0.002 + h / 2), W("b"), bevel=0.002)
			B((0.01, d - 0.02, h), (x + s_ * (w / 2 - 0.005), y0, top - 0.002 + h / 2), W("b"), bevel=0.002)
		r_ = 0.007 + 0.002 * (i % 3)
		m = CU("dark") if i % 2 else IRON("dark")
		for k in range(7 + i):
			rivet((x - 0.055 + (k % 5) * 0.027 + J(0.004), y0 - 0.035 + (k // 5) * 0.03 + J(0.004), top + 0.012), m, r=r_)
		B((0.08, 0.006, 0.03), (x, y0 - d / 2 - 0.002, top + 0.024), PAPER(), bevel=0.001)
		B((0.05, 0.004, 0.005), (x, y0 - d / 2 - 0.005, top + 0.026), INK(), bevel=0)


def hs_tool_wall():
	"""The shield-maker's tool board: each tool hangs on iron pegs over its painted outline; one outline is empty."""
	foot(0.85)
	fy = board(1.25, 0.8, 1.2)
	ol = C((0.08, 0.06, 0.05), 0.95)

	def outline(rects):
		for x0, z0, x1, z1 in rects:
			prism([(x0, z0), (x1, z0), (x1, z1), (x0, z1)], fy - 0.005, fy + 0.006, ol)

	def peg(x, z):
		rod((x, fy + 0.02, z), (x, fy - 0.05, z), 0.007, IRON("dark"))
		sphere((x, fy - 0.05, z), 0.01, IRON("dark"))

	for x, present in ((-0.5, True), (-0.33, False)):  # hammer and the outline of the missing one
		outline([(x - 0.022, 1.1, x + 0.022, 1.405), (x - 0.072, 1.405, x + 0.092, 1.465)])
		peg(x - 0.04, 1.39)
		peg(x + 0.045, 1.39)
		if present:
			place(lambda: hammer(0.34), at=(x, fy - 0.03, 1.1))
	place(lambda: tongs(0.42), at=(-0.15, fy - 0.025, 1.06))
	peg(-0.15, 1.375)
	outline([(0.03, 1.1, 0.06, 1.33), (-0.01, 1.33, 0.1, 1.46)])  # mallet
	log((0.045, fy - 0.03, 1.1), (0.045, fy - 0.03, 1.36), 0.014, W("c"), seg=7, rings=1, bend=0)
	kit.cylinder(0.04, 0.12, (0.045, fy - 0.035, 1.395), W("a"), rot=(0, 90, 0), verts=12, bevel=0.006)
	for dx in (-0.045, 0.045):
		kit.ring(0.04, 0.005, (0.045 + dx, fy - 0.035, 1.395), IRON("dark"), rot=(0, 90, 0), seg=14)
	peg(0.0, 1.34)
	peg(0.09, 1.34)
	kit.ring(0.018, 0.005, (0.26, fy - 0.03, 1.44), IRON("a"), rot=(90, 0, 0), seg=12)  # dividers
	for s_ in (-1, 1):
		rod((0.26, fy - 0.03, 1.43), (0.26 + s_ * 0.06, fy - 0.03, 1.12), 0.007, IRON("a"))
	peg(0.26, 1.465)
	for s_ in (-1, 1):  # snips
		tube([(0.45 + s_ * 0.01, fy - 0.025 - s_ * 0.004, 1.44), (0.45 - s_ * 0.008, fy - 0.025 - s_ * 0.004, 1.33),
			(0.45 + s_ * 0.03, fy - 0.025 - s_ * 0.004, 1.16)], 0.008, 0.006, IRON("dark"), seg=6)
	rivet((0.45, fy - 0.035, 1.33), IRON("a"), r=0.012)
	peg(0.45, 1.3)
	outline([(-0.47, 0.955, -0.03, 1.015)])  # drawknife on two pegs
	B((0.36, 0.008, 0.045), (-0.25, fy - 0.03, 0.985), IRON("a"), bevel=0.003)
	B((0.36, 0.012, 0.012), (-0.25, fy - 0.03, 0.966), kit.tex_mat("silver", "a"), bevel=0.002)
	for s_ in (-1, 1):
		log((-0.25 + s_ * 0.18, fy - 0.03, 0.99), (-0.25 + s_ * 0.24, fy - 0.08, 1.02), 0.014, W("c"), seg=7, rings=1, bend=0)
		peg(-0.25 + s_ * 0.12, 0.95)
	B((0.2, 0.08, 0.08), (0.3, fy - 0.04, 0.99), W("dark"), bevel=0.008)  # punch block
	for i, x in enumerate((0.24, 0.3, 0.36)):
		kit.cylinder(0.011, 0.16, (x, fy - 0.04, 1.03 + 0.01 * i), IRON("a"), verts=8, bevel=0.002)
		kit.cylinder(0.015, 0.012, (x, fy - 0.04, 1.11 + 0.01 * i), IRON("dark"), verts=8, bevel=0.002)
	for x in (0.22, 0.38):
		B((0.03, 0.012, 0.1), (x, fy - 0.001, 0.99), IRON("dark"), bevel=0.002)


def hs_order_banner():
	"""The order's banner on a stone post: an iron rod with copper finials, a deep blue swallowtail cloth with gold
	side bands, a pale shield patch with a red anvil, and copper-capped tassels."""
	foot(2.0)
	B((0.2, 0.1, 0.06), (0, BACK - 0.05, 2.02), S("c"), bevel=0.012)
	ry, rz = -0.07, 1.9
	rod((-0.46, ry, rz), (0.46, ry, rz), 0.014, IRON("dark"))
	for s_ in (-1, 1):
		sphere((s_ * 0.47, ry, rz), 0.024, CU())
		kit.cone(0.016, 0.0, 0.05, (s_ * 0.51, ry, rz), CU(), rot=(0, s_ * 90, 0), verts=8, bevel=0)
		tube([(s_ * 0.44, ry, rz + 0.012), (s_ * 0.22, ry + 0.04, rz + 0.09), (0, BACK - 0.06, 2.05)], 0.006, 0.006, kit.tex_mat("rope", "b"), seg=5)
	B((0.05, 0.11, 0.04), (0, -0.01, rz), IRON("dark"), bevel=0.004)
	cloth = C((0.06, 0.1, 0.24), 0.95)
	kit.cylinder(0.026, 0.84, (0, ry, rz), cloth, rot=(0, 90, 0), verts=12, bevel=0)
	w, h, n, rows = 0.82, 1.12, 14, 8
	top = rz - 0.01
	verts = []
	for j in range(rows + 1):
		for i in range(n + 1):
			x = -w / 2 + w * i / n
			zb = top - h + 0.25 * (1 - abs(2 * x / w))
			z = top + (zb - top) * j / rows
			verts.append((x, ry + 0.007 * math.sin(i * 1.1 + j * 0.3), z))
	faces = [(j * (n + 1) + i, j * (n + 1) + i + 1, (j + 1) * (n + 1) + i + 1, (j + 1) * (n + 1) + i) for j in range(rows) for i in range(n)]
	o = mesh(verts, faces, cloth)
	sol = o.modifiers.new("t", "SOLIDIFY")
	sol.thickness, sol.offset = 0.01, 0.0
	gold = C((0.5, 0.34, 0.08), 0.9)
	for s_ in (-1, 1):
		B((0.045, 0.012, 0.86), (s_ * 0.34, ry - 0.024, top - 0.53), gold, bevel=0.002)
	B((0.72, 0.012, 0.05), (0, ry - 0.016, top - 0.06), gold, bevel=0.002)
	pf = ry - 0.03
	prism(heater_pts(1.35, 0, 1.42), pf, pf + 0.02, P("bone"))
	emblem("anvil", 0, 1.43, 0.13, pf, P("red"))
	tube([(x, pf - 0.004, z) for x, z in heater_pts(1.35, 0, 1.42) + heater_pts(1.35, 0, 1.42)[:1]], 0.006, 0.006, gold, seg=5)
	for s_ in (-1, 1):
		zb = top - h
		kit.cone(0.018, 0.008, 0.04, (s_ * w / 2, ry, zb - 0.01), CU(), verts=8, bevel=0)
		kit.cylinder(0.014, 0.09, (s_ * w / 2, ry, zb - 0.075), gold, verts=8, bevel=0.002)


def hs_squad_pennants():
	"""A carved stone header on two posts: five iron arms, each with a squad pennant on a dowel (own colour and
	emblem), the squad's name cut into the stone below it."""
	for x in (-0.5, 0.5):
		foot(1.25, x)
	slab = B((1.5, BACK, 0.72), (0, BACK / 2, 1.56), S("b"), bevel=0.012)
	cut = groove_path([(-0.7, 1.24), (0.7, 1.24), (0.7, 1.88), (-0.7, 1.88)], 0.0, 0.014, 0.012, closed=True)
	sq = (("red", "ochre", "hammer"), ("blue", "bone", "star"), ("black", "ochre", "mountain"), ("ochre", "red", "chevron"), ("bone", "blue", "axe"))
	for i, (f, g, e) in enumerate(sq):
		x = -0.56 + 0.28 * i
		cut += rune_row(x - 0.09, x + 0.09, 1.29, 0.0, h=0.045, w=0.009, seed=60 + i)
		rod((x, 0.03, 1.82), (x, -0.14, 1.82), 0.009, IRON("dark"))
		sphere((x, -0.14, 1.82), 0.014, IRON("dark"))
		log((x - 0.125, -0.12, 1.745), (x + 0.125, -0.12, 1.745), 0.011, W("c"), seg=6, rings=1, bend=0)
		for s_ in (-1, 1):
			tube([(x, -0.14, 1.815), (x + s_ * 0.06, -0.132, 1.78), (x + s_ * 0.11, -0.122, 1.752)], 0.004, 0.004, kit.tex_mat("rope", "b"), seg=5)
			sphere((x + s_ * 0.135, -0.12, 1.745), 0.014, CU())
		prism([(x - 0.11, 1.745), (x + 0.11, 1.745), (x + 0.11, 1.5), (x, 1.36), (x - 0.11, 1.5)], -0.125, -0.115, P(f))
		emblem(e, x, 1.6, 0.06, -0.125, P(g))
		tube([(x - 0.1, -0.127, 1.73), (x + 0.1, -0.127, 1.73)], 0.004, 0.004, C(PAINT[g], 0.9), seg=5)
	carve(slab, cut)


def hs_strap_rack():
	"""A board of leather shield straps hanging on wooden pegs, each with an iron buckle; below, a shelf with a box of
	spare buckles and a leather-worker's round knife."""
	foot(0.9)
	fy = board(1.0, 0.72, 1.22)
	pz = 1.42
	for i in range(5):
		x = -0.36 + 0.18 * i
		kit.cylinder(0.011, 0.09, (x, fy - 0.025, pz), W("dark"), rot=(90, 0, 0), verts=8, bevel=0.002)
		sphere((x, fy - 0.07, pz), 0.015, W("dark"))
		Ls = 0.2 + 0.04 * ((i * 3) % 4)
		lm = LEA("dark") if i % 2 else LEA("c")
		zt = pz - 0.016
		B((0.035, 0.008, Ls), (x, fy - 0.048, zt - Ls / 2), lm, bevel=0.002)
		tube([(x, fy - 0.048, zt - 0.005), (x, fy - 0.045, pz + 0.014), (x, fy - 0.03, pz + 0.018), (x, fy - 0.012, pz + 0.006)], 0.005, 0.005, lm, seg=5)
		bz = zt - Ls + 0.07
		for s_ in (-1, 1):
			B((0.006, 0.012, 0.042), (x + s_ * 0.025, fy - 0.054, bz), IRON("dark"), bevel=0.001)
			B((0.056, 0.012, 0.006), (x, fy - 0.054, bz + s_ * 0.019), IRON("dark"), bevel=0.001)
		B((0.004, 0.006, 0.04), (x, fy - 0.058, bz + 0.004), IRON("a"), bevel=0)
	for gx in (-0.2, 0.2):  # two shield grips (wooden bar, leather wrap, riveted iron end straps) on peg pairs
		gz = 1.03
		log((gx - 0.16, fy - 0.04, gz), (gx + 0.16, fy - 0.04, gz), 0.017, W("c"), seg=7, rings=1, bend=0)
		kit.cylinder(0.021, 0.14, (gx, fy - 0.04, gz), LEA(), rot=(0, 90, 0), verts=8, bevel=0.003)
		for s_ in (-1, 1):
			B((0.03, 0.01, 0.09), (gx + s_ * 0.15, fy - 0.06, gz), IRON("dark"), bevel=0.002)
			for dz in (-0.03, 0.03):
				rivet((gx + s_ * 0.15, fy - 0.065, gz + dz), CU("dark"), r=0.006)
			rod((gx + s_ * 0.09, fy + 0.02, gz - 0.026), (gx + s_ * 0.09, fy - 0.07, gz - 0.026), 0.007, W("dark"))
	sz = 0.95
	B((0.96, 0.16, 0.03), (0, fy - 0.075, sz), W("c"), bevel=0.006)
	for x in (-0.43, 0.43):
		prism([(fy + 0.005, sz - 0.015), (fy - 0.14, sz - 0.015), (fy + 0.005, sz - 0.12)], x - 0.012, x + 0.012, W("dark"), axis="x")
	top = sz + 0.015
	bx, by = -0.2, fy - 0.08
	B((0.2, 0.11, 0.012), (bx, by, top + 0.004), W("dark"), bevel=0.002)
	for s_ in (-1, 1):
		B((0.22, 0.01, 0.06), (bx, by + s_ * 0.06, top - 0.002 + 0.03), W("b"), bevel=0.002)
		B((0.01, 0.11, 0.06), (bx + s_ * 0.105, by, top - 0.002 + 0.03), W("b"), bevel=0.002)
	for k in range(5):
		B((0.04, 0.03, 0.006), (bx - 0.06 + 0.03 * k, by - 0.02 + 0.012 * (k % 2), top + 0.013 + 0.003 * (k % 2)), IRON("dark"), bevel=0.001, rot=(0, 0, k * 25))
	prism([(0.12, top + 0.004), (0.26, top + 0.004), (0.24, top + 0.05), (0.19, top + 0.065), (0.14, top + 0.05)], by - 0.004, by + 0.004, IRON("a"))
	log((0.19, by, top + 0.06), (0.19, by, top + 0.15), 0.012, W("c"), seg=6, rings=1, bend=0)


def hs_duty_roster():
	"""A stone-framed peg board of the watch: four rows of iron duty tags in squad colours, carved day marks above,
	carved row marks beside, and a few empty pegs (someone is off duty, or never came back)."""
	foot(0.9)
	slab = B((1.2, BACK, 0.92), (0, BACK / 2, 1.3), S("b"), bevel=0.012)
	cut = rune_row(-0.45, 0.45, 1.68, 0.0, h=0.05, seed=71)
	cut += groove_path([(-0.57, 0.87), (0.57, 0.87), (0.57, 1.73), (-0.57, 1.73)], 0.0, 0.012, 0.01, closed=True)
	rows = (1.5, 1.35, 1.2, 1.05)
	for j, z in enumerate(rows):
		cut += groove((-0.54, z - 0.02), (-0.54, z + 0.02), 0.0, 0.01, 0.01)
		for k in range(j):
			cut += groove((-0.525 + 0.012 * k, z - 0.02), (-0.525 + 0.012 * k, z + 0.02), 0.0, 0.008, 0.008)
	carve(slab, cut)
	for i in range(4):
		B((0.245, 0.03, 0.66), (-0.3675 + 0.245 * i, -0.008, 1.27), W("abcb"[i]), bevel=0.006)
	cols = ("red", "blue", "ochre", "black")
	empty = {(0, 4), (1, 1), (2, 3), (2, 5), (3, 0)}
	for j, z in enumerate(rows):
		for i in range(6):
			x = -0.4 + 0.16 * i
			kit.cylinder(0.007, 0.04, (x, -0.04, z), IRON("dark"), rot=(90, 0, 0), verts=8, bevel=0.001)
			if (j, i) in empty:
				continue
			prism(heater_pts(0.2, x, z - 0.045), -0.048, -0.04, IRON("a" if (i + j) % 2 else "b"))
			prism(heater_pts(0.14, x, z - 0.047), -0.052, -0.046, P(cols[j]))
			rivet((x, -0.052, z - 0.03), CU("dark"), r=0.005)


# ================= floor pieces and story scenes =================
def hs_repair_bench():
	"""Story: the shield-repairer stopped mid-job. A heavy bench with a shield clamped face up, only its left half
	repainted; a copper dish of rivets, a hammer, a paint pot with the brush in it, a spare plank against the end,
	spare bosses and shield boards on the shelf below."""
	for i, y in enumerate((-0.2, 0.0, 0.2)):
		B((1.5, 0.196, 0.07), (0, y, 0.79), W("abc"[i]), bevel=0.008)
	for sx in (-1, 1):
		for sy in (-1, 1):
			B((0.09, 0.09, 0.76), (sx * 0.68, sy * 0.25, 0.38), W("dark"), bevel=0.01)
		B((0.06, 0.44, 0.06), (sx * 0.68, 0, 0.18), W("dark"), bevel=0.006)
		B((0.12, 0.006, 0.06), (sx * 0.69, -0.3, 0.79), IRON("dark"), bevel=0.002)
		for dx in (-0.035, 0.035):
			rivet((sx * 0.69 + dx, -0.304, 0.79), IRON("dark"), r=0.007)
	for sy in (-1, 1):
		B((1.3, 0.06, 0.06), (0, sy * 0.25, 0.18), W("dark"), bevel=0.006)
		B((1.26, 0.235, 0.03), (0, sy * 0.12, 0.222), W("c"), bevel=0.005)
	top = 0.825
	place(lambda: heater(1.2, "red", "ochre", None, paint=0.55), at=(-0.1, 0.02, top - 0.002), rot=(-90, 0, 12))
	for x in (-0.16, 0.02):  # two screw clamps over the front edge
		B((0.04, 0.035, 0.24), (x, -0.335, 0.79), IRON("dark"), bevel=0.004)
		B((0.034, 0.17, 0.035), (x, -0.26, 0.895), IRON("dark"), bevel=0.004)
		B((0.034, 0.1, 0.035), (x, -0.29, 0.74), IRON("dark"), bevel=0.004)
		rod((x, -0.2, 0.86), (x, -0.2, 0.96), 0.009, IRON("a"))
		rod((x - 0.05, -0.2, 0.955), (x + 0.05, -0.2, 0.955), 0.006, IRON("a"))
		kit.cylinder(0.022, 0.012, (x, -0.2, 0.865), IRON("a"), verts=10, bevel=0.002)
	dx, dy = 0.5, -0.13
	lathe([(0, top - 0.001), (0.08, top - 0.001), (0.095, top + 0.022), (0.088, top + 0.024), (0.072, top + 0.009), (0, top + 0.009)], (dx, dy), CU(), seg=18)
	for k in range(10):
		a = k * 2.4
		rivet((dx + math.cos(a) * 0.045 * (k % 3) / 2, dy + math.sin(a) * 0.045 * (k % 3) / 2, top + 0.016), IRON("dark" if k % 2 else "a"), r=0.009)
	place(lambda: hammer(0.34), at=(0.42, 0.17, 0), rot=(90, 0, 115), floor=top - 0.002)
	px, py = 0.6, 0.18
	lathe([(0, top - 0.002), (0.06, top - 0.002), (0.07, top + 0.03), (0.066, top + 0.1), (0.073, top + 0.11), (0.06, top + 0.112),
		(0.056, top + 0.03), (0, top + 0.03)], (px, py), C((0.36, 0.24, 0.15), 0.8), seg=16)
	kit.cylinder(0.057, 0.01, (px, py, top + 0.078), P("red"), verts=16, bevel=0)
	log((px - 0.012, py, top + 0.07), (px + 0.11, py - 0.05, top + 0.23), 0.007, W("c"), seg=6, rings=1, bend=0)
	o = B((0.025, 0.18, 0.7), (0.8, 0.0, 0.34), W("c"), bevel=0.006, rot=(0, -15, 0))
	rest(o, 0.001)
	for x in (-0.35, -0.15):  # spare bosses on the shelf
		kit.cylinder(0.07, 0.012, (x, -0.1, 0.24), IRON("dark"), verts=16, bevel=0.003)
		sphere((x, -0.1, 0.245), 0.05, IRON("a"), scale=(1, 1, 0.7), cut=0.0)
	for k in range(3):
		B((0.5, 0.09, 0.02), (0.3 + 0.01 * k, 0.1 - 0.012 * k, 0.246 + 0.02 * k), W("abc"[k]), bevel=0.003, rot=(0, 0, 4 * k - 4))


def slim(objs, sx, sy):
	"""Squeeze a body in x/y around its own middle (world space), keeping its height."""
	pts = body_pts(objs)
	cx, cy = (min(p.x for p in pts) + max(p.x for p in pts)) / 2, (min(p.y for p in pts) + max(p.y for p in pts)) / 2
	for o in objs:
		mw, inv = o.matrix_world, o.matrix_world.inverted()
		for v in o.data.vertices:
			w = mw @ v.co
			v.co = inv @ Vector((cx + (w.x - cx) * sx, cy + (w.y - cy) * sy, w.z))


def hs_shieldbearer_stand():
	"""An armour stand on a carved stone base: a dwarf-shaped wooden form (the game's real dwarf, cut at hips and
	shoulders) in a shirt of curved iron scales all the way round, riveted belt, layered pauldrons, gorget and helm; the
	bearer's shield hangs by its strap from a peg post at its side."""
	base = B((0.56, 0.56, 0.12), (0, 0, 0.06), S("b"), bevel=0.015)
	cut = groove_path([(-0.23, 0.03), (0.23, 0.03), (0.23, 0.09), (-0.23, 0.09)], -0.28, 0.01, 0.008, closed=True)
	cut += [chip((0.28, -0.28, 0.12), (0.05, 0.05, 0.04), seed=2), chip((-0.28, 0.28, 0.12), (0.04, 0.05, 0.04), seed=5)]
	carve(base, cut)
	form = mannequin(W("dark"), ratio=0.15)  # hidden under the scale shirt: fewer faces (file under 2 MB)
	slim(form, 0.72, 0.68)  # owner round 3: "too fat", a normal dwarf, not a barrel
	pts = body_pts(form)
	hip = body_ring(pts, 0.49)
	log((hip[0], hip[1], 0.1), (hip[0], hip[1], 0.5), 0.045, W("dark"), seg=8, rings=2, bend=0.005)
	kit.ring(0.05, 0.012, (hip[0], hip[1], 0.125), IRON("dark"), seg=12)
	for row in range(14):  # the scale shirt: small round-footed scales, each row over the one below, to mid-thigh
		zt = 0.87 - row * 0.032
		top = body_ring(pts, max(zt, 0.49))
		lame_row(top, body_ring(pts, max(zt - 0.042, 0.49)), zt, zt - 0.042, 44, (IRON("a"), IRON("b")), off_t=0.01,
			off_b=0.02, t=0.006, gap=0.08, phase=0.5 * (row % 2), seg=3, round_bot=0.008)
	zb = 0.6  # riveted belt all round
	ring = body_ring(pts, zb)
	lame_row(ring, body_ring(pts, zb - 0.045), zb, zb - 0.045, 1, (LEA(),), off_t=0.034, off_b=0.036, t=0.014, gap=0.0, seg=40)
	fy = ring[1] - ring_r(ring[2], -math.pi / 2) - 0.036
	B((0.07, 0.016, 0.06), (ring[0], fy - 0.004, zb - 0.0225), CU(), bevel=0.004)
	B((0.008, 0.008, 0.05), (ring[0], fy - 0.013, zb - 0.0225), CU("dark"), bevel=0)
	for k in range(12):
		a = -math.pi / 2 + 0.26 + k * 0.5
		r = ring_r(ring[2], a) + 0.036
		rivet((ring[0] + math.cos(a) * r, ring[1] + math.sin(a) * r, zb - 0.0225), CU("dark"), r=0.007)
	for s_ in (-1, 1):
		pauldron(s_, (s_ * 0.155, hip[1] + 0.02, 0.8), (IRON("a"), IRON("dark")), CU("dark"), n=4, r=0.118)
	neck = body_ring(pts, 0.9)
	lathe([(0, 0.855), (0.14, 0.855), (0.13, 0.89), (0.1, 0.925), (0.085, 0.935), (0, 0.935)], (neck[0], neck[1]), IRON("b"), seg=20)  # gorget
	kit.ring(0.135, 0.01, (neck[0], neck[1], 0.857), CU(), seg=24)
	sphere((neck[0], neck[1], 0.98), 0.088, W("b"), scale=(1, 1.05, 1.0))  # the form's head knob (inside the helm)
	jaw_helm((neck[0], neck[1], 1.0), s=0.55, mi=IRON("a"), mt=IRON("dark"), mr=CU("dark"), ml=(IRON("dark"), IRON("a")), jaw=False)
	# the peg post at its side, on its own stone foot, with the bearer's shield hung by the strap
	px, py = -0.68, 0.12
	B((0.2, 0.2, 0.1), (px + 0.02, py, 0.05), S("c"), bevel=0.012)
	log((px, py, 0.08), (px, py, 1.05), 0.032, W("dark"), seg=7, rings=3, bend=0.006)
	kit.cylinder(0.012, 0.1, (px, py - 0.07, 0.98), W("c"), rot=(90, 0, 0), verts=8, bevel=0.002)  # the peg
	sphere((px, py - 0.12, 0.98), 0.016, W("c"), seg=8, rings=5)
	sx, sz = px, 0.6
	place(lambda: heater(1.3, "blue", "ochre", "tower"), at=(sx, py - 0.07, sz))
	for s_ in (-1, 1):  # the strap: from the shield's top corners up over the peg
		tube([(sx + s_ * 0.12, py - 0.085, 0.902), (sx + s_ * 0.06, py - 0.09, 0.95), (sx + s_ * 0.012, py - 0.09, 0.992)], 0.007, 0.007, LEA(), seg=5)
	lighter(small=0.03, fine=0.012, few=0.02)  # lighter file (under 2 MB), same look

def token(field, m=None):
	"""A muster token: a little iron shield on a round foot, painted in the squad's colour."""
	kit.cylinder(0.022, 0.014, (0, 0, 0.007), IRON("dark"), verts=12, bevel=0.002)
	zc = 0.0485
	prism(heater_pts(0.14, 0, zc), -0.004, 0.004, m or IRON("a"))
	prism(heater_pts(0.105, 0, zc + 0.002), -0.007, -0.002, P(field))


def book():
	B((0.24, 0.17, 0.008), (0, 0, 0.004), LEA(), bevel=0.002)
	B((0.226, 0.158, 0.03), (0.004, 0, 0.022), PAPER(), bevel=0.002)
	B((0.24, 0.17, 0.008), (0, 0, 0.04), LEA(), bevel=0.002)
	B((0.012, 0.17, 0.046), (-0.118, 0, 0.022), LEA(), bevel=0.003)
	for sx in (-1, 1):
		for sy in (-1, 1):
			B((0.03, 0.03, 0.01), (sx * 0.108, sy * 0.073, 0.043), CU(), bevel=0.002)
	B((0.05, 0.004, 0.012), (0.12, -0.04, 0.03), CU("dark"), bevel=0)


def hs_muster_table():
	"""The muster table: a stone top with a map grid and a gate CUT INTO it, carved zigzag legs, iron shield tokens of
	the order lined up against three black ones (one knocked over), a captain's copper token, a roll book, a candle,
	dividers and a pointer stick."""
	legs = [B((0.16, 0.62, 0.6), (s_ * 0.55, 0, 0.3), S("b"), bevel=0.015) for s_ in (-1, 1)]
	st = B((0.96, 0.12, 0.12), (0, 0, 0.14), S("c"), bevel=0.01)
	top = B((1.5, 0.9, 0.1), (0, 0, 0.645), S("b"), bevel=0.015)
	zt = 0.695
	cut = tgroove_path([(-0.68, -0.38), (0.68, -0.38), (0.68, 0.38), (-0.68, 0.38)], zt, 0.014, 0.01, closed=True)
	for i in range(5):
		cut += tgroove((-0.5 + 0.25 * i, -0.3), (-0.5 + 0.25 * i, 0.3), zt, 0.007, 0.006)
	for j in range(4):
		cut += tgroove((-0.5, -0.3 + 0.2 * j), (0.5, -0.3 + 0.2 * j), zt, 0.007, 0.006)
	cut += tgroove_path([(0.6 - 0.07 * math.sin(math.radians(a)), 0.07 * math.cos(math.radians(a))) for a in range(0, 181, 30)], zt, 0.01, 0.008)
	for k in range(8):
		a = k * math.pi / 4
		cut += tgroove((-0.6 + math.cos(a) * 0.015, 0.3 + math.sin(a) * 0.015), (-0.6 + math.cos(a) * 0.055, 0.3 + math.sin(a) * 0.055), zt, 0.008, 0.006)
	for s_ in (-1, 1):
		cut += groove_path([(s_ * 0.55 + (0.03 if k % 2 else -0.03), 0.06 + k * 0.07) for k in range(8)], -0.31, 0.012, 0.01)
	cut += rune_row(-0.36, 0.36, 0.14, -0.06, h=0.05, seed=121)
	carve(legs + [st, top], cut)
	for x, y in ((-0.375, -0.1), (-0.25, -0.1), (-0.125, -0.1), (0.0, -0.1), (-0.31, -0.2), (-0.06, -0.2)):
		place(lambda: token("blue"), at=(x, y, zt - 0.002), rot=(0, 0, J(8)))
	place(lambda: token("ochre", CU()), at=(-0.19, -0.2, zt - 0.002), rot=(0, 0, 5))
	for x, y in ((0.25, 0.15), (0.375, 0.15)):
		place(lambda: token("black"), at=(x, y, zt - 0.002), rot=(0, 0, 180 + J(8)))
	place(lambda: token("black"), at=(0.31, 0.24, 0), rot=(90, 0, 140), floor=zt - 0.001)
	place(book, at=(0.5, -0.25, zt - 0.002), rot=(0, 0, 12))
	candle(-0.6, 0.12, zt - 0.002, 0.13)
	log((-0.2, 0.31, zt + 0.007), (0.3, 0.27, zt + 0.007), 0.009, W("c"), seg=6, rings=1, bend=0)
	kit.ring(0.012, 0.004, (0.15, -0.3, zt + 0.006), IRON("a"), seg=10)
	for p in ((0.3, -0.33), (0.29, -0.24)):
		rod((0.15, -0.3, zt + 0.005), (p[0], p[1], zt + 0.005), 0.005, IRON("a"))


def hs_oath_stone():
	"""The oath stone: a hand-print and a ring of marks CUT INTO its top, a shield with an anvil and an oath line cut
	into the front, an iron ring hanging on its side, a copper oath cup standing on the floor, a kneeling step worn hollow."""
	B((1.2, 1.0, 0.1), (0, 0, 0.05), S("c"), bevel=0.02)
	kneel = B((0.6, 0.28, 0.14), (0, -0.33, 0.165), S("a"), bevel=0.02)
	carve(kneel, [sphere((s_ * 0.13, -0.34, 0.31), 0.1, S("a"), scale=(1, 0.8, 1)) for s_ in (-1, 1)])
	block = kit.taper(0.72, 0.52, 0.6, 0.42, 0.9, (0, 0.1, 0.095), S("b"), bevel=0.02)
	slab = B((0.66, 0.48, 0.06), (0, 0.1, 1.02), S("c"), bevel=0.015)
	zt = 1.05
	cut = [B((0.1, 0.11, 0.05), (0, 0.05, zt - 0.012 + 0.025), GROOVE_M(), bevel=0.015)]
	for dx, ln, ang in ((-0.036, 0.075, 8), (-0.012, 0.09, 3), (0.012, 0.095, -2), (0.036, 0.08, -7)):
		cut.append(kit.cylinder(0.013, ln, (dx, 0.1 + ln / 2, zt - 0.008), GROOVE_M(), rot=(90, 0, ang), verts=10, bevel=0))
	cut.append(kit.cylinder(0.014, 0.07, (0.07, 0.03, zt - 0.008), GROOVE_M(), rot=(90, 0, -55), verts=10, bevel=0))
	cut += tgroove_path([(math.cos(2 * math.pi * k / 20) * 0.17, 0.08 + math.sin(2 * math.pi * k / 20) * 0.17) for k in range(20)], zt, 0.012, 0.01, closed=True)
	for k in range(12):
		a = 2 * math.pi * k / 12
		cut += tgroove((math.cos(a) * 0.19, 0.08 + math.sin(a) * 0.19), (math.cos(a) * 0.215, 0.08 + math.sin(a) * 0.215), zt, 0.01, 0.008)
	carve(slab, cut)
	fy = lambda z: 0.1 - (0.52 - 0.1 * (z - 0.095) / 0.9) / 2  # noqa: E731
	cut = groove_path(heater_pts(1.2, 0, 0.6), fy, 0.016, 0.014, closed=True)
	cut += groove_path([(x * 0.1, 0.62 + z * 0.1) for x, z in EMB["anvil"][0]], fy, 0.012, 0.012, closed=True)
	cut += rune_row(-0.25, 0.25, 0.2, fy, h=0.05, seed=131)
	carve(block, cut)
	B((0.014, 0.12, 0.12), (0.32, 0.1, 0.75), IRON("dark"), bevel=0.003, rot=(0, -3.8, 0))
	for dy in (-0.04, 0.04):
		for dz in (-0.04, 0.04):
			rivet((0.328, 0.1 + dy, 0.75 + dz), CU("dark"), r=0.007)
	rod((0.322, 0.1, 0.73), (0.37, 0.1, 0.73), 0.008, IRON("dark"))
	kit.ring(0.045, 0.008, (0.37, 0.1, 0.685), IRON("dark"), rot=(90, 0, 0), seg=16)
	cx, cy = 0.45, -0.28  # the oath cup stands on the stone floor by the step (no chain, owner Nov 22)
	lathe([(0, 0.098), (0.045, 0.098), (0.045, 0.11), (0.012, 0.12), (0.01, 0.17), (0.04, 0.18), (0.055, 0.26), (0.05, 0.262),
		(0.035, 0.19), (0, 0.19)], (cx, cy), CU(), seg=16)


def hs_guard_bunk():
	"""A bare two-tier guard bunk: slatted boards, iron corner brackets, copper name plates with runes, ladder rungs at
	the foot end, a closed iron-banded footlocker underneath and a round shield hung on the foot post."""
	for sx in (-1, 1):
		for sy in (-1, 1):
			B((0.09, 0.09, 1.62), (sx * 0.95, sy * 0.38, 0.81), W("dark"), bevel=0.01)
	plates = []
	for z in (0.32, 1.02):
		for sy in (-1, 1):
			B((1.84, 0.06, 0.12), (0, sy * 0.38, z), W("c"), bevel=0.008)
		for sx in (-1, 1):
			B((0.06, 0.7, 0.12), (sx * 0.95, 0, z), W("c"), bevel=0.008)
			B((0.14, 0.006, 0.1), (sx * 0.85, -0.412, z), IRON("dark"), bevel=0.002)
			for dx in (-0.045, 0.0, 0.045):
				rivet((sx * 0.85 + dx, -0.416, z), IRON("dark"), r=0.007)
		for i in range(8):
			B((0.2, 0.72, 0.03), (-0.79 + i * 0.226, 0, z + 0.072), W("abcb"[i % 4]), bevel=0.006)
		plates.append(B((0.16, 0.006, 0.05), (-0.5, -0.412, z), CU(), bevel=0.002))
	cut = []
	for z in (0.32, 1.02):
		cut += rune_row(-0.565, -0.435, z, -0.415, h=0.03, w=0.006, depth=0.003, seed=int(z * 100))
	carve(plates, cut)
	for z in (0.55, 0.7, 0.85):
		log((0.95, -0.34, z), (0.95, 0.34, z), 0.018, W("c"), seg=7, rings=1, bend=0)
	place(lambda: roundsh(0.2, "red", "ochre", "star", boss="dome"), at=(0.95, -0.428, 1.3))
	rod((0.95, -0.4, 1.53), (0.95, -0.48, 1.54), 0.007, IRON("dark"))
	for s_ in (-1, 1):
		tube([(0.95, -0.475, 1.536), (0.95 + s_ * 0.05, -0.46, 1.51), (0.95 + s_ * 0.08, -0.445, 1.484)], 0.006, 0.006, LEA(), seg=5)
	lx = -0.35
	B((0.6, 0.38, 0.17), (lx, 0, 0.088), W("b"), bevel=0.008)
	B((0.62, 0.4, 0.05), (lx, 0, 0.195), W("c"), bevel=0.008)
	for dx in (-0.2, 0.2):
		B((0.03, 0.39, 0.175), (lx + dx, 0, 0.0875), IRON("dark"), bevel=0.002)
		B((0.03, 0.41, 0.055), (lx + dx, 0, 0.195), IRON("dark"), bevel=0.002)
	B((0.04, 0.012, 0.07), (lx, -0.205, 0.165), IRON("dark"), bevel=0.002)
	B((0.05, 0.02, 0.05), (lx, -0.2, 0.115), IRON("a"), bevel=0.004)
	kit.ring(0.014, 0.004, (lx, -0.212, 0.145), IRON("a"), rot=(90, 0, 0), seg=10)


def hs_shield_pell():
	"""A training pell: a carved stone base, a thick post hacked all over (cuts INTO the wood), iron bands, two padded
	arms, a battered round shield nailed to the front with gouges and a chunk knocked off, wood chips on the floor."""
	base = B((0.6, 0.6, 0.26), (0, 0, 0.13), S("b"), bevel=0.02)
	cut = groove_path([(-0.25, 0.04), (0.25, 0.04), (0.25, 0.22), (-0.25, 0.22)], -0.3, 0.012, 0.01, closed=True)
	cut += rune_row(-0.18, 0.18, 0.13, -0.3, h=0.06, seed=141)
	cut += [chip((0.3, -0.3, 0.26), (0.06, 0.05, 0.05), seed=4), chip((-0.3, 0.3, 0.26), (0.05, 0.05, 0.04), seed=6)]
	carve(base, cut)
	kit.ring(0.108, 0.02, (0, 0, 0.265), IRON("dark"), seg=18)
	post = log((0, 0, 0.2), (0, 0, 1.55), 0.1, W("dark"), seg=10, rings=4, bend=0.01)
	cut = []
	for k in range(16):
		a = rng.uniform(-math.pi, math.pi)
		z = rng.uniform(1.16, 1.5) if k % 2 else rng.uniform(0.32, 0.56)
		cut.append(B((0.09, 0.03, 0.012), (math.cos(a) * 0.1, math.sin(a) * 0.1, z), W("a"), bevel=0, rot=(0, rng.uniform(-35, 35), math.degrees(a) + 90)))
	carve(post, cut)
	for z in (0.45, 1.47):
		kit.ring(0.106, 0.012, (0, 0, z), IRON("dark"), seg=18)
	kit.cone(0.11, 0.03, 0.08, (0, 0, 1.575), IRON("dark"), verts=10, bevel=0.004)
	rivet((0, 0, 1.615), IRON("a"), r=0.02)
	B((0.86, 0.07, 0.07), (0, 0, 1.25), W("c"), bevel=0.008)
	for s_ in (-1, 1):
		kit.cylinder(0.05, 0.12, (s_ * 0.39, 0, 1.25), LEA("b"), rot=(0, 90, 0), verts=10, bevel=0.008)
		for dx in (-0.06, 0.06):
			kit.ring(0.05, 0.008, (s_ * 0.39 + dx, 0, 1.25), kit.tex_mat("rope", "b"), rot=(0, 90, 0), seg=12)
		kit.cylinder(0.012, 0.03, (s_ * 0.13, -0.035, 1.25), W("dark"), rot=(90, 0, 0), verts=8, bevel=0.002)
	parts = place(lambda: roundsh(0.28, "rust", "bone", "cross", boss="dome"), at=(0, -0.095, 0.85))
	fr = -0.095 - 0.036
	cut = groove((-0.2, 0.95), (-0.06, 0.8), fr, 0.012, 0.012) + groove((0.05, 0.66), (0.19, 0.74), fr, 0.01, 0.01) + groove((-0.16, 0.7), (-0.06, 0.64), fr, 0.01, 0.01)
	cut.append(chip((0.2, -0.11, 1.05), (0.07, 0.06, 0.06), seed=9, m=W("a")))
	carve([o for o in parts if o not in RIMS], cut)
	carve([o for o in parts if o in RIMS], [chip((0.204, -0.11, 1.054), (0.07, 0.06, 0.06), seed=9, m=IRON("a"))])
	for x, z in ((-0.13, 1.02), (0.12, 1.0), (-0.12, 0.68), (0.13, 0.7)):
		rivet((x, fr - 0.002, z), IRON("dark"), r=0.013)
	for k in range(12):
		a = k * 0.53 + 0.2
		d = 0.36 + 0.06 * (k % 3)
		o = B((0.04 + 0.02 * (k % 2), 0.015, 0.006), (math.cos(a) * d, math.sin(a) * d, 0.01), W("a"), bevel=0.001, rot=(0, 0, k * 47))
		rest(o, 0.001)


def hs_captains_chair():
	"""The captain's chair on a two-step stone dais with runes cut in: a heavy wooden chair whose back is the order's
	painted shield set between the uprights, copper-capped arms with iron straps, copper studs, finials."""
	d1 = B((1.2, 1.0, 0.12), (0, 0, 0.06), S("c"), bevel=0.02)
	d2 = B((0.95, 0.8, 0.12), (0, 0.04, 0.175), S("b"), bevel=0.02)
	cut = groove_path([(-0.55, 0.025), (0.55, 0.025), (0.55, 0.095), (-0.55, 0.095)], -0.5, 0.01, 0.008, closed=True)
	cut += rune_row(-0.35, 0.35, 0.175, -0.36, h=0.06, seed=151)
	carve([d1, d2], cut)
	z0 = 0.235
	for sx in (-1, 1):
		for sy in (-1, 1):
			B((0.09, 0.09, 0.43), (sx * 0.28, sy * 0.2, z0 + 0.21), W("dark"), bevel=0.01)
		B((0.1, 0.09, 1.0), (sx * 0.3, 0.21, 1.205), W("dark"), bevel=0.01)
		sphere((sx * 0.3, 0.21, 1.74), 0.055, W("c"))
		kit.cone(0.04, 0.0, 0.06, (sx * 0.3, 0.21, 1.8), CU(), verts=10, bevel=0)
		B((0.07, 0.5, 0.05), (sx * 0.34, -0.03, 0.9), W("c"), bevel=0.008)
		B((0.06, 0.06, 0.2), (sx * 0.34, -0.22, 0.8), W("dark"), bevel=0.006)
		kit.cylinder(0.038, 0.05, (sx * 0.34, -0.29, 0.9), CU(), rot=(90, 0, 0), verts=12, bevel=0.005)
		B((0.075, 0.3, 0.006), (sx * 0.34, -0.03, 0.926), IRON("dark"), bevel=0.002)
		for dy in (-0.12, 0.0, 0.12):
			rivet((sx * 0.34, -0.03 + dy, 0.93), CU("dark"), r=0.007)
	for sy in (-1, 1):
		B((0.5, 0.04, 0.04), (0, sy * 0.2, 0.33), W("c"), bevel=0.005)
	B((0.66, 0.5, 0.07), (0, 0, 0.68), W("b"), bevel=0.01)
	B((0.6, 0.03, 0.08), (0, -0.245, 0.61), W("c"), bevel=0.006)
	for k in range(7):
		rivet((-0.27 + 0.09 * k, -0.262, 0.61), CU("dark"), r=0.008)
	B((0.52, 0.06, 0.08), (0, 0.21, 1.62), W("c"), bevel=0.008)
	B((0.52, 0.05, 0.06), (0, 0.21, 0.8), W("c"), bevel=0.006)
	place(lambda: heater(1.3, "blue", "ochre", "anvil"), at=(0, 0.2, 1.23))


def hs_fallen_shield_wall():
	"""Story: the last shield wall fell where it stood, shields toppled onto each other like dominoes, a snapped spear
	and its head half, a whole spear, a helmet on its side, a dropped axe and chunks of fallen masonry."""
	row = [("h", -0.95, 0.12, -9, 14, ("red", "ochre", "anvil")), ("r", -0.5, 0.02, -8, 0, ("blue", "bone", "rays")),
		("h", -0.05, 0.1, -10, -8, ("bone", "red", "chevron")), ("r", 0.4, 0.0, -7, 0, ("black", "ochre", "cross")),
		("h", 0.84, 0.08, -4, 20, ("ochre", "black", "mountain"))]
	for k, x, y, tilt, yaw, (f, g, e) in row:
		if k == "h":
			place(lambda: heater(1.15, f, g, e), at=(x, y, 0), rot=(-90, tilt, yaw), floor=0.0)
		else:
			place(lambda: roundsh(0.26, f, g, e, boss="dome"), at=(x, y, 0), rot=(-90, tilt, yaw), floor=0.0)
	place(lambda: broken_spear(0.85), at=(-0.6, -0.42, 0), rot=(90, 0, 70), floor=0.0)
	place(lambda: spear(0.75, "wing", butt=False), at=(-0.05, -0.55, 0), rot=(90, 0, 110), floor=0.0)
	place(lambda: spear(1.6, "leaf"), at=(0.1, 0.5, 0), rot=(90, 0, -84), floor=0.0)
	place(lambda: helm("ridge"), at=(0.3, -0.42, 0), rot=(0, 100, 40), floor=0.0)
	place(lambda: axe(0.8, 1.1), at=(1.15, -0.38, 0), rot=(90, 0, -30), floor=0.0)
	for i, (x, y, sz) in enumerate(((1.3, 0.25, 0.16), (1.18, 0.4, 0.1), (1.42, 0.05, 0.08), (-1.35, -0.2, 0.11))):
		o = kit.gem((x, y, 0.1), (sz, sz * 0.8, sz * 0.6), S("abc"[i % 3]), seed=i + 3)
		rest(o, 0.0)


def plaque_stone():
	B((0.3, 0.14, 0.22), (0, 0, 0.11), S("b"), bevel=0.015)
	plate = B((0.2, 0.012, 0.08), (0, -0.074, 0.13), CU(), bevel=0.003)
	carve(plate, rune_row(-0.08, 0.08, 0.13, -0.08, h=0.04, w=0.007, depth=0.004, seed=161))
	for x in (-0.09, 0.09):
		rivet((x, -0.08, 0.13), CU("dark"), r=0.007)


def hs_last_stand_cairn():
	"""Story: where the captain fell, the order raised a cairn of broken stone. His great axe is planted head-down in
	it with his crested helmet on the haft, a spear is driven in beside it, his shield leans against the stones and a
	small stone with a copper plate names him."""
	rubble_heap(0, 0.05, 0.6, 0.48, 0.42, [S("a"), S("b"), S("c"), S("b")], n=60, smax=0.22, smin=0.05, dirt=S("dark"), seed=3)
	place(lambda: axe(1.1, 1.4), at=(0.04, 0.05, 1.38), rot=(0, 180, 0))
	place(lambda: helm("crest", 1.0), at=(0.04, 0.05, 1.33))
	place(lambda: roundsh(0.28, "red", "bone", "rays", boss="spike"), at=(-0.28, -0.43, 0), rot=(-62, 0, 10), floor=0.0)
	place(lambda: spear(1.6, "long"), at=(0.38, 0.22, 0.08), rot=(14, -12, 0))
	place(plaque_stone, at=(0.5, -0.5, 0), rot=(0, 0, -12))


def bare_shield(r):
	"""An unpainted round shield with the emblem scratched into the bare wood, waiting for paint."""
	parts = made(lambda: roundsh(r, None, None, None, boss="dome"))
	carve(parts, groove_path([(x * r * 0.55, z * r * 0.55) for x, z in _star(6, 1.0, 0.5)], -0.03, 0.006, 0.004, closed=True, m=C((0.62, 0.55, 0.42), 0.9)))


def stencil():
	plate = B((0.26, 0.006, 0.3), (0, 0, 0.15), CU("dark"), bevel=0.002)
	carve(plate, [prism([(x * 0.09, 0.15 + z * 0.09) for x, z in EMB["tower"][0]], -0.05, 0.05, GROOVE_M())])
	B((0.26, 0.012, 0.02), (0, 0, 0.29), CU(), bevel=0.002)


def hs_paint_rack():
	"""Story: shields drying after painting, stood in slots in a wooden rack and leaning on its top rail: one finished,
	one with only the field painted, one bare with the design scratched on. A stool with three paint pots and a
	brush, and a copper emblem stencil leaning against it."""
	for sx in (-1, 1):
		B((0.08, 0.5, 0.06), (sx * 0.8, 0.0, 0.03), W("dark"), bevel=0.008)
		B((0.06, 0.06, 0.6), (sx * 0.8, 0.15, 0.355), W("dark"), bevel=0.008)
	beam = B((1.64, 0.16, 0.08), (0, -0.03, 0.098), W("b"), bevel=0.008)
	B((1.62, 0.05, 0.05), (0, 0.15, 0.6), W("c"), bevel=0.006)
	xs = (-0.5, 0.0, 0.5)
	carve(beam, [B((0.27, 0.05, 0.08), (x, -0.02, 0.138), GROOVE_M(), bevel=0) for x in xs])
	r = 0.24
	for i, x in enumerate(xs):
		if i == 0:
			fn = lambda: roundsh(r, "blue", "ochre", "rays", boss="dome")  # noqa: E731
		elif i == 1:
			fn = lambda: roundsh(r, "red", None, None, boss="ring")  # noqa: E731
		else:
			fn = lambda: bare_shield(r)  # noqa: E731
		place(fn, at=(x, 0.05, 0.35), rot=(-16, 0, 0), floor=0.1)
	tx, ty = 1.15, -0.05
	kit.cylinder(0.17, 0.05, (tx, ty, 0.45), W("b"), verts=16, bevel=0.008)
	for k in range(3):
		a = 2 * math.pi * k / 3 + 0.3
		log((tx + math.cos(a) * 0.1, ty + math.sin(a) * 0.1, 0.43), (tx + math.cos(a) * 0.15, ty + math.sin(a) * 0.15, 0.0), 0.022, W("dark"), seg=7, rings=1, bend=0)
	zt = 0.475
	for k, col in enumerate(("blue", "ochre", "bone")):
		a = 2 * math.pi * k / 3 + 1.2
		px, py = tx + math.cos(a) * 0.085, ty + math.sin(a) * 0.085
		lathe([(0, zt - 0.002), (0.04, zt - 0.002), (0.047, zt + 0.02), (0.044, zt + 0.075), (0.05, zt + 0.082), (0.04, zt + 0.084),
			(0.037, zt + 0.02), (0, zt + 0.02)], (px, py), C((0.36, 0.24, 0.15), 0.8), seg=14)
		kit.cylinder(0.038, 0.008, (px, py, zt + 0.06), P(col), verts=14, bevel=0)
		if k == 0:
			log((px - 0.05, py, zt + 0.088), (px + 0.07, py + 0.02, zt + 0.088), 0.006, W("c"), seg=6, rings=1, bend=0)
			kit.cylinder(0.009, 0.03, (px + 0.08, py + 0.02, zt + 0.088), C((0.15, 0.1, 0.06), 0.95), rot=(0, 90, 0), verts=8, bevel=0.002)
	place(stencil, at=(0.97, -0.3, 0), rot=(-15, 0, 12), floor=0.0)


def hs_rim_jig():
	"""Story: a smith was bending a new iron shield rim. A round wooden jig table with a ring of iron pegs; the rim
	strip is bent most of the way round and clamped with iron dogs, its straight end still sticking out past the
	edge; a hammer and tongs on the table, a finished rim leaning on the floor."""
	kit.cylinder(0.48, 0.1, (0, 0, 0.72), W("b"), verts=24, bevel=0.012)
	kit.ring(0.482, 0.014, (0, 0, 0.72), IRON("dark"), seg=28)
	for k in range(3):
		a = 2 * math.pi * k / 3 + 0.5
		B((0.1, 0.1, 0.68), (math.cos(a) * 0.3, math.sin(a) * 0.3, 0.34), W("dark"), bevel=0.01, rot=(0, 0, math.degrees(a)))
		B((0.05, 0.3, 0.05), (math.cos(a) * 0.15, math.sin(a) * 0.15, 0.2), W("c"), bevel=0.006, rot=(0, 0, math.degrees(a) + 90))
	kit.cylinder(0.07, 0.08, (0, 0, 0.2), W("dark"), verts=10, bevel=0.008)
	R = 0.3
	for k in range(12):
		a = 2 * math.pi * k / 12
		kit.cylinder(0.018, 0.11, (math.cos(a) * R, math.sin(a) * R, 0.805), IRON("dark"), verts=8, bevel=0.003)
	Rb = R + 0.024
	pts = [(Rb * math.cos(math.radians(a)), Rb * math.sin(math.radians(a)), 0.8) for a in range(300, 29, -10)]
	a0 = math.radians(30)
	d = (math.sin(a0), -math.cos(a0))
	p0 = pts[-1]
	pts += [(p0[0] + d[0] * t, p0[1] + d[1] * t, 0.8) for t in (0.08, 0.2, 0.35, 0.5)]
	band_path(pts, 0.008, 0.05, IRON("a"))
	for deg in (120, 210, 280):
		a = math.radians(deg)
		B((0.05, 0.02, 0.025), (math.cos(a) * 0.312, math.sin(a) * 0.312, 0.82), IRON("dark"), bevel=0.003, rot=(0, 0, deg))
	place(lambda: hammer(0.42, 1.3), at=(-0.05, 0.02, 0), rot=(90, 0, 35), floor=0.769)
	place(lambda: tongs(0.45), at=(0.1, -0.08, 0), rot=(90, 0, -70), floor=0.769)
	circ = [(0.3 * math.cos(2 * math.pi * k / 28), 0.3 * math.sin(2 * math.pi * k / 28), 0) for k in range(29)]
	place(lambda: band_path(circ, 0.008, 0.05, IRON("dark")), at=(0.6, -0.42, 0), floor=0.0)  # a finished rim lying on the floor


TOWER = [(-0.26, -0.56), (0.26, -0.56), (0.28, 0.42), (0.16, 0.53), (0.0, 0.56), (-0.16, 0.53), (-0.28, 0.42)]


def tower(field, fig, emb, t=0.035):
	"""A tall tower shield, back at y=0: planks, paint, emblem, iron rim, two riveted straps and a chain loop."""
	prism(TOWER, -t, 0, W("b"))
	prism([(x * 0.9, z * 0.94) for x, z in TOWER], -t - 0.006, -t + 0.004, P(field))
	emblem(emb, 0, 0.14, 0.13, -t - 0.006, P(fig))
	tube([(x, -t / 2, z) for x, z in TOWER + TOWER[:1]], t / 2 + 0.005, t / 2 + 0.005, IRON("dark"), seg=6)
	for s_ in (-1, 1):
		B((0.03, 0.01, 0.95), (s_ * 0.17, -t - 0.008, -0.03), IRON("dark"), bevel=0.002)
		for k in range(5):
			rivet((s_ * 0.17, -t - 0.013, -0.45 + 0.22 * k), CU("dark"), r=0.007)
	kit.cylinder(0.05, 0.016, (0, -t - 0.012, -0.12), IRON("dark"), rot=(90, 0, 0), verts=14, bevel=0.003)
	kit.ring(0.03, 0.007, (0, -t - 0.045, -0.12), IRON("a"), rot=(0, 90, 0), seg=12)


def hs_tower_shields_chained():
	"""Story: the order's tall tower shields stacked against a carved stone ledge, leaning one in front of the other,
	each painted with its squad's sign (owner Nov 22: no chain)."""
	ledge = B((1.5, 0.4, 0.45), (0, 0.15, 0.225), S("b"), bevel=0.015)
	cut = groove_path([(-0.7, 0.04), (0.7, 0.04), (0.7, 0.41), (-0.7, 0.41)], -0.05, 0.012, 0.01, closed=True)
	cut += rune_row(-0.5, 0.5, 0.38, -0.05, h=0.05, seed=171)
	carve(ledge, cut)
	sh = (("blue", "bone", "tower"), ("red", "ochre", "anvil"), ("ochre", "black", "hammer"), ("black", "ochre", "star"))
	rot = (-15, 0, 0)
	for i, x in enumerate((-0.5, -0.17, 0.16, 0.49)):
		f, g, e = sh[i]
		place(lambda: tower(f, g, e), at=(x, -0.025 - 0.055 * i, 0.565), rot=rot)


HORN = lambda: C((0.42, 0.33, 0.22), 0.6)  # noqa: E731


def hs_war_horn_stand():
	"""The order's great war horn resting in two iron cradles on a carved stone stand: a curved horn with three copper
	bands, a copper mouthpiece and a flared copper bell, a leather carrying strap hanging below."""
	B((0.6, 0.45, 0.1), (0, 0, 0.05), S("c"), bevel=0.02)
	col = kit.taper(0.4, 0.3, 0.34, 0.26, 0.75, (0, 0, 0.095), S("b"), bevel=0.015)
	cap = B((0.5, 0.38, 0.08), (0, 0, 0.88), S("c"), bevel=0.015)
	fy = lambda z: -(0.3 - 0.04 * (z - 0.095) / 0.75) / 2  # noqa: E731
	cut = groove_path(heater_pts(0.75, 0, 0.55), fy, 0.014, 0.012, closed=True)
	cut += groove_path([(-0.08, 0.6), (-0.03, 0.55), (0.03, 0.54), (0.08, 0.58)], fy, 0.016, 0.012)
	cut += rune_row(-0.12, 0.12, 0.25, fy, h=0.05, seed=181)
	carve(col, cut)
	carve(cap, rune_row(-0.2, 0.2, 0.88, -0.19, h=0.045, seed=182))
	pts = [Vector(p) for p in ((-0.38, 0, 1.2), (-0.26, 0, 1.14), (-0.12, 0, 1.115), (0.02, 0, 1.12), (0.16, 0, 1.15), (0.28, 0, 1.21), (0.37, 0, 1.3), (0.42, 0, 1.41))]
	rad = lambda i: 0.02 + 0.05 * i / 7  # noqa: E731
	dz = (pts[7] - pts[6]).normalized()
	flare = [(0.03, 0.082), (0.06, 0.098), (0.085, 0.118), (0.1, 0.132), (0.108, 0.138), (0.114, 0.134)]  # bell flare, rolled lip
	# one closed piece: the horn runs straight into its copper bell (owner Nov 22: the end was loose), open and dark inside
	hollow_horn([tuple(p) for p in pts] + [tuple(pts[7] + dz * d) for d, _ in flare], [rad(i) for i in range(8)] + [r for _, r in flare],
		HORN(), C((0.018, 0.016, 0.014), 1.0), CU(), bell_from=7, wall=0.007, back=7, seg=18)
	orient(kit.ring(rad(7) + 0.006, 0.01, tuple(pts[7]), CU("dark"), seg=18), dz)
	for i in (2, 4):
		fx, hz, hr = pts[i].x, pts[i].z, rad(i)
		rod((fx, 0, 0.915), (fx, 0, hz - hr - 0.012), 0.012, IRON("dark"))
		cr = hr + 0.008
		tube([(fx, cr * math.cos(math.radians(a)), hz - cr * math.sin(math.radians(a))) for a in range(0, 181, 30)], 0.007, 0.007, IRON("dark"), seg=6)
	for i in (1, 3, 5):
		orient(kit.ring(rad(i) + 0.004, 0.008, tuple(pts[i]), CU(), seg=16), pts[i + 1] - pts[i - 1])
	d0 = (pts[0] - pts[1]).normalized()
	orient(kit.cone(0.016, 0.026, 0.05, tuple(pts[0] + d0 * 0.015), CU(), verts=12, bevel=0), d0)
	tube([(-0.26, 0.0, 1.11), (-0.2, -0.02, 1.02), (0.02, -0.03, 0.97), (0.2, -0.02, 1.02), (0.28, 0.0, 1.155)], 0.008, 0.008, LEA(), seg=6)


def hs_helm_trophy_pole():
	"""A war trophy: a carved stone socket with a pole and rope-lashed crossbar; two dented captured helmets hang from
	the bar on chains, a third sits on top, a split enemy shield is nailed on and an enemy spear is lashed behind."""
	blk = B((0.46, 0.46, 0.32), (0, 0, 0.16), S("b"), bevel=0.02)
	cut = groove_path([(-0.19, 0.04), (0.19, 0.04), (0.19, 0.28), (-0.19, 0.28)], -0.23, 0.012, 0.01, closed=True)
	cut += rune_row(-0.14, 0.14, 0.16, -0.23, h=0.06, seed=191)
	cut += [chip((0.23, -0.23, 0.32), (0.05, 0.05, 0.04), seed=8)]
	carve(blk, cut)
	kit.ring(0.06, 0.014, (0, 0, 0.33), IRON("dark"), seg=14)
	log((0, 0, 0.25), (0, 0, 2.05), 0.05, W("dark"), seg=8, rings=4, bend=0.008)
	log((-0.5, 0, 1.65), (0.5, 0, 1.65), 0.035, W("dark"), seg=7, rings=2, bend=0.005)
	rope = kit.tex_mat("rope", "b")
	for a in (45, -45):
		kit.ring(0.068, 0.01, (0, 0, 1.65), rope, rot=(0, a, 0), seg=14)
	for s_, kind in ((-1, "ridge"), (1, "brim")):
		x = s_ * 0.42
		chain((x, 0, 1.615), (x, 0, 1.47))
		parts = place(lambda: helm(kind, 0.95, IRON("dark")), at=(x, 0, 1.47 - 0.127))
		carve(parts, [sphere((x + s_ * 0.07, -0.09, 1.43), 0.035, IRON("dark")), sphere((x - s_ * 0.05, -0.06, 1.46), 0.03, IRON("dark"))])
	place(lambda: helm("cheeks"), at=(0, 0, 1.95))
	parts = place(lambda: roundsh(0.26, "black", "rust", "saltire", boss="spike"), at=(0, -0.048, 1.05))
	carve([o for o in parts if o not in RIMS], [prism([(0.04, 1.33), (0.3, 1.33), (0.3, 1.0)], -0.2, 0.05, GROOVE_M())])
	carve([o for o in parts if o in RIMS], [prism([(0.044, 1.334), (0.304, 1.334), (0.304, 1.004)], -0.2, 0.05, IRON("a"))])
	for x, z in ((-0.1, 1.15), (-0.12, 0.92), (0.1, 0.92)):
		rivet((x, -0.09, z), IRON("dark"), r=0.012)
	place(lambda: spear(1.7, "wing"), at=(-0.42, 0.07, 0.34), rot=(0, 22, 0))
	kit.ring(0.075, 0.01, (0, 0.03, 1.38), rope, rot=(90, 0, 20), seg=14)


def hs_watch_brazier():
	"""The guards' brazier: a carved stone pedestal, an iron bowl with four shield-shaped plates and iron straps, filled
	with glossy black coal and glowing embers under low flames; an iron poker leans against it."""
	B((0.5, 0.5, 0.1), (0, 0, 0.05), S("c"), bevel=0.02)
	col = kit.taper(0.3, 0.3, 0.24, 0.24, 0.6, (0, 0, 0.095), S("b"), bevel=0.012)
	B((0.4, 0.4, 0.07), (0, 0, 0.73), S("c"), bevel=0.015)
	fy = lambda z: -(0.3 - 0.06 * (z - 0.095) / 0.6) / 2  # noqa: E731
	cut = groove_path(heater_pts(0.5, 0, 0.47), fy, 0.012, 0.01, closed=True)
	cut += groove_path([(x * 0.05, 0.475 + z * 0.05) for x, z in EMB["anvil"][0]], fy, 0.009, 0.008, closed=True)
	cut += rune_row(-0.1, 0.1, 0.2, fy, h=0.045, seed=201)
	carve(col, cut)
	lathe([(0, 0.76), (0.12, 0.76), (0.25, 0.86), (0.3, 0.97), (0.28, 0.975), (0.23, 0.87), (0.11, 0.785), (0, 0.785)], (0, 0), IRON("dark"), seg=20)
	kit.ring(0.295, 0.016, (0, 0, 0.97), IRON("a"), seg=24)
	for k in range(4):
		a = k * math.pi / 2 + math.pi / 4
		tube([(math.cos(a) * r, math.sin(a) * r, z) for r, z in ((0.14, 0.775), (0.21, 0.83), (0.265, 0.89), (0.305, 0.965))], 0.009, 0.009, IRON("a"), seg=6)
		b = a + math.pi / 4
		place(lambda: (prism(heater_pts(0.26), -0.01, 0.006, IRON("a")), rivet((0, -0.012, 0.0), CU("dark"), r=0.008)),
			at=(math.cos(b) * 0.283, math.sin(b) * 0.283, 0.915), rot=(24, 0, math.degrees(b) + 90))
	lathe([(0, 0.784), (0.12, 0.784), (0.22, 0.86), (0.24, 0.885), (0, 0.91)], (0, 0), C((0.03, 0.028, 0.03), 0.9), seg=16)
	r_ = __import__("random").Random(7)
	coal = C((0.035, 0.033, 0.035), 0.25)
	ember = C((0.9, 0.32, 0.08), 0.5, glow=1.5)
	for i in range(46):
		rr = math.sqrt(r_.uniform(0, 1)) * 0.22
		a = r_.uniform(0, 2 * math.pi)
		sz = r_.uniform(0.025, 0.05)
		z = 0.91 - 0.1 * (rr / 0.24) + sz * 0.2
		o = kit.gem((0, 0, 0), (sz, sz * 0.85, sz * 0.7), ember if i % 6 == 0 else coal, seed=i + 11)
		spin(o, r_.uniform(-30, 30), r_.uniform(-30, 30), r_.uniform(0, 360))
		o.location = (math.cos(a) * rr, math.sin(a) * rr, z)
	kit.fire(0, 0, 0.92, 0.45, seed=3, tongues=5)
	rod((0.32, -0.3, 0.012), (0.17, -0.205, 0.78), 0.009, IRON("dark"))
	kit.ring(0.03, 0.007, (0.163, -0.2, 0.81), IRON("dark"), rot=(90, 0, 0), seg=12)
	tube([(0.32, -0.3, 0.012), (0.36, -0.325, 0.02), (0.375, -0.335, 0.05)], 0.009, 0.006, IRON("dark"), seg=6)


def practice_spear(x, h=1.5):
	log((x, 0, 0.085), (x, 0, h - 0.08), 0.02, W("c"), seg=7, rings=2, bend=0.004)
	kit.cylinder(0.045, 0.16, (x, 0, h - 0.04), LEA("b"), verts=10, bevel=0.012)
	sphere((x, 0, h + 0.04), 0.04, LEA("b"), scale=(1, 1, 0.7))
	for z in (h - 0.11, h + 0.03):
		kit.ring(0.045, 0.008, (x, 0, z), kit.tex_mat("rope", "b"), seg=12)


def practice_axe(x, h=1.3):
	log((x, 0, 0.085), (x, 0, h), 0.02, W("c"), seg=7, rings=2, bend=0.004)
	hz = h - 0.08
	prism([(x + 0.015, hz + 0.05), (x + 0.15, hz + 0.09), (x + 0.17, hz - 0.08), (x + 0.12, hz - 0.12), (x + 0.015, hz - 0.04)], -0.02, 0.02, W("a"))
	B((0.03, 0.046, 0.18), (x + 0.165, 0, hz), LEA("b"), bevel=0.008)
	kit.ring(0.026, 0.006, (x, 0, hz - 0.07), IRON("dark"), seg=10)
	kit.ring(0.026, 0.006, (x, 0, hz + 0.07), IRON("dark"), seg=10)


def practice_sword(x):
	prism([(x - 0.028, 0.95), (x + 0.028, 0.95), (x + 0.024, 0.18), (x, 0.09), (x - 0.024, 0.18)], -0.012, 0.012, W("a"))
	B((0.18, 0.04, 0.035), (x, 0, 0.96), W("dark"), bevel=0.006)
	kit.cylinder(0.018, 0.18, (x, 0, 1.07), LEA(), verts=8, bevel=0.003)
	sphere((x, 0, 1.18), 0.03, W("dark"))
	for z in (0.99, 1.15):
		kit.ring(0.018, 0.004, (x, 0, z), IRON("dark"), seg=10)


def hs_practice_trough():
	"""A carved stone trough of practice weapons held upright by an iron rail with loops: leather-padded spears,
	blunt wooden axes with leather edges and a wooden sword."""
	B((1.34, 0.44, 0.08), (0, 0, 0.04), S("c"), bevel=0.012)
	front = B((1.3, 0.07, 0.36), (0, -0.165, 0.25), S("b"), bevel=0.012)
	B((1.3, 0.07, 0.36), (0, 0.165, 0.25), S("b"), bevel=0.012)
	for sx in (-1, 1):
		B((0.07, 0.26, 0.36), (sx * 0.615, 0, 0.25), S("a"), bevel=0.012)
	cut = groove_path([(-0.6, 0.11), (0.6, 0.11), (0.6, 0.39), (-0.6, 0.39)], -0.2, 0.012, 0.01, closed=True)
	cut += rune_row(-0.45, 0.15, 0.25, -0.2, h=0.06, seed=211)
	for s_ in (-1, 1):
		cut += groove((0.32 + s_ * 0.08, 0.16), (0.32 - s_ * 0.08, 0.34), -0.2, 0.014, 0.012)
	carve(front, cut)
	for sx in (-1, 1):
		rod((sx * 0.615, 0, 0.42), (sx * 0.615, 0, 1.075), 0.014, IRON("dark"))
		sphere((sx * 0.615, 0, 1.08), 0.022, IRON("a"))
	rod((-0.615, 0, 1.06), (0.615, 0, 1.06), 0.012, IRON("dark"))
	kinds = ("spear", "axe", "sword", "spear", "axe", "spear")
	for i, x in enumerate((-0.45, -0.27, -0.09, 0.09, 0.27, 0.45)):
		kit.ring(0.032, 0.006, (x, 0, 1.06), IRON("a"), seg=12)
		if kinds[i] == "spear":
			practice_spear(x, 1.45 + 0.05 * (i % 2))
		elif kinds[i] == "axe":
			practice_axe(x, 1.25 + 0.05 * (i % 2))
		else:
			practice_sword(x)


MODELS = {f.__name__: f for f in (
	hs_shield_wall, hs_spear_rack, hs_axe_rack, hs_helm_shelf, hs_order_crest, hs_roll_of_honour, hs_split_shield_trophy,
	hs_buckler_rail, hs_boss_shelf, hs_tool_wall, hs_order_banner, hs_squad_pennants, hs_strap_rack, hs_duty_roster,
	hs_repair_bench, hs_shieldbearer_stand, hs_muster_table, hs_oath_stone, hs_guard_bunk, hs_shield_pell, hs_captains_chair, hs_fallen_shield_wall,
	hs_last_stand_cairn, hs_paint_rack, hs_rim_jig, hs_tower_shields_chained, hs_war_horn_stand, hs_helm_trophy_pole, hs_watch_brazier, hs_practice_trough,
)}

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
		RIMS.clear()
		try:
			MODELS[name]()
			kit.save(str(outdir / f"{name}.glb"), str(jdir / f"{name}.png"), tex_size=256)
			print(f"MODEL_OK {name}")
		except Exception as e:
			import traceback
			traceback.print_exc()
			print(f"MODEL_FAILED {name}: {e!r}")
