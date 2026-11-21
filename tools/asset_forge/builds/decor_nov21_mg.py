# Decor for MOSSGATE HOLD (Nov 21): the old gatehouse-hold of the first diggers, a small root-wood dungeon
# (Delver's Shack logs, split boards, wooden pegs) with iron and copper fittings. Abandoned long ago. No moss.
#   blender --background --factory-startup --python builds/decor_nov21_mg.py -- [id ...]   (none = all)
# Output: assets/models/decor/<id>.glb (origin bottom-centre, front faces -Y in Blender = +Z in Godot).
# Wall pieces have a flat back at +Y; raised ones stand on two short floor posts so they never float.
#
# --- Wall pieces ---
#   mg_key_board          gatekeeper's key board: plank board, iron hooks, six big keys, a key ring, one empty hook
#   mg_shield_wall        three round guard shields (split planks, iron rim and boss) on pegs; the middle one lost a plank
#   mg_crossbow_rack      two crossbows on peg pairs (third pair empty) over a box shelf full of bolts
#   mg_helmet_pegs        hewn peg rail: two iron guard helmets, one empty peg, a belt with a copper buckle and pouch
#   mg_bowl_shelf         mess-hall shelf: plates on edge, a row of mugs, stacks of wooden bowls, ladles on hooks
#   mg_rope_wall          gate spares: coils of rope on pegs, an iron grapnel, a pulley block with its rope
#   mg_ledger_shelf       gatekeeper's pigeonhole cabinet: ledgers, rolled scrolls, tally-stick bundle, inkpot
#   mg_gate_windlass      the gate's wall winch: log drum with iron hoops, spoked crank wheel, ratchet, chain going up
# --- Story scenes ---
#   mg_last_watch         guard table with a half-played peg game, tankards (one tipped), lantern on the floor, stool knocked over
#   mg_barricade          boards nailed across two posts, braced by a log on a wedge stone; one board torn; hammer and nails
#   mg_gate_bar_snapped   the huge gate bar snapped in two on the floor, iron bracket still on it, the other one torn off
#   mg_crate_pried_open   a supply crate pried open: crowbar still under a lid board, another board on the floor, empty
#   mg_sawhorse_left      a sawhorse with a half-sawn log, the saw still stuck in the cut; offcut, axe in a chopping log
#   mg_strongbox_forced   the iron-banded strongbox broken open and empty: lid torn off, padlock and crowbar beside it
#   mg_spear_rack_fallen  a guard spear rack knocked onto its back, spears spilled across the floor
#   mg_collapsed_shelf    a storeroom shelf whose leg snapped: shelves slant down, crates and a keg slid onto the floor
# --- Furniture and props ---
#   mg_gatekeeper_chair   high-backed log armchair with iron studs, corner plates and a copper plate
#   mg_gatekeeper_desk    slanted writing desk: open ledger, inkpot and quill, candle stub, seal, cash box, scroll shelf
#   mg_armour_stand       short log armour stand, iron cuirass all the way round, shoulder guards, helmet; a shield beside it
#   mg_alarm_bell         gate alarm bell: log frame, copper bell on an iron hanger, pull rope tied to a cleat
#   mg_water_butt         big stave water barrel on a log cradle, closed with a round plank lid
#   mg_supply_shelf       tall storeroom shelf full of small kegs, crates, copper pots, coiled rope and a lantern
#   mg_wheelbarrow        plank wheelbarrow with an iron-rimmed spoked wheel and hewn handles
#   mg_cookpot_tripod     cold cooking spot: ring of stones, iron tripod, chain, hollow black-inside pot, burnt log stubs, log seat
#   mg_guard_cot          bare log cot with rope lacing and a closed footlocker at its foot
#   mg_mess_trestle       mess-hall trestle table with a bench: empty bowls, spoons, mugs, bread board and knife
#   mg_lantern_post       gate lantern post: hewn post, braced cross foot, iron arm with a hanging lantern
#   mg_grain_bin          plank grain bin, lid propped open on a stick, wooden scoop on the rim, iron corners
#   mg_tool_chest         open carpenter's chest: chisels in a till, saw clipped in the lid; mallet and plane beside it
#   mg_toll_table         gate toll table: copper balance scale, row of weights, locked coin box, coin stacks, ledger
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from night_stations import B, GAME, J, T, kit, log, mesh, rivet, rng  # noqa: E402
from night_materials import C, sphere, _cm  # noqa: E402
from decor_nov21_a import chain, floor_cut, low_z, prism, turn  # noqa: E402
from decor_nov21_f import group  # noqa: E402
from decor_nov21_d import tube  # noqa: E402
from decor_nov21_vo import hollow_lathe  # noqa: E402

BARK = lambda: T("shackbark")  # noqa: E731
PL = lambda: T("shackplank")  # noqa: E731
DK = lambda: T("shackdark")  # noqa: E731
END = lambda: T("shacklogend")  # noqa: E731
STONE = lambda: T("shackstone")  # noqa: E731
IRON = lambda v="a": kit.tex_mat("iron", v)  # noqa: E731
CU = lambda v="b": kit.tex_mat("copper", v)  # noqa: E731
ROPE = lambda: kit.tex_mat("rope")  # noqa: E731
LEATHER = lambda: kit.tex_mat("leather", "dark")  # noqa: E731
LEATHER2 = lambda: kit.tex_mat("leather", "b")  # noqa: E731
PAPER = lambda: C((0.6, 0.52, 0.38), 0.95)  # noqa: E731
INK = lambda: C((0.08, 0.06, 0.05), 0.4)  # noqa: E731
WAX = lambda: C((0.8, 0.72, 0.52), 0.85)  # noqa: E731
CHAR = lambda: kit.mat("charcoal", 0.0, rough=1.0)  # noqa: E731
GLASS = lambda: C((0.55, 0.4, 0.2), 0.3)  # noqa: E731
QUILL = lambda: C((0.7, 0.67, 0.6), 0.8)  # noqa: E731


# ================= helpers =================
def new_since(before):
	return [o for o in bpy.data.objects if o not in before]


def lay(build, xy, rot, floor=0.0):
	"""Build parts, turn them by rot (degrees), then drop them so their lowest point rests at `floor`."""
	before = set(bpy.data.objects)
	group(build, at=(xy[0], xy[1], 0.5), rot=rot)
	objs = new_since(before)
	bpy.context.view_layer.update()
	dz = low_z(objs) - floor
	for o in objs:
		o.location.z -= dz
	return objs


def hlog(p0, p1, r, **kw):
	"""A hewn root-wood log (Shack bark, chopped pale ends)."""
	kw.setdefault("seg", 8)
	kw.setdefault("rings", 2)
	return log(p0, p1, r, BARK(), end_m=END(), **kw)


def rod(p0, p1, r, m, seg=6):
	return log(p0, p1, r, m, seg=seg, rings=1, ends=False, bend=0)


def beam(p0, p1, w, h, m, bevel=0.006):
	"""A square-cut bar from p0 to p1 (w across, h the other way)."""
	p0, p1 = Vector(p0), Vector(p1)
	d = p1 - p0
	o = B((w, h, d.length), (0, 0, 0), m, bevel=bevel)
	o.matrix_world = Matrix.Translation((p0 + p1) / 2) @ d.to_track_quat("Z", "Y").to_matrix().to_4x4()
	return o


def board(size, loc, rot=(0, 0, 0), m=None):
	return B((size[0] * (1 + J(0.015)), size[1], size[2]), loc, m or PL(), bevel=0.01, rot=rot)


def peg(x, y, z, face="-y", r=0.013):
	"""A wooden peg with a domed head, pressed 1 cm into the face it sits on (face -y = front, +z = top)."""
	if face == "-y":
		kit.cylinder(r, 0.03, (x, y - 0.005, z), DK(), rot=(90, 0, 0), verts=8, bevel=0.002)
		sphere((x, y - 0.02, z), r * 1.35, DK(), scale=(1, 0.55, 1), seg=10, rings=6)
	else:
		kit.cylinder(r, 0.03, (x, y, z - 0.005), DK(), verts=8, bevel=0.002)
		sphere((x, y, z + 0.01), r * 1.35, DK(), scale=(1, 1, 0.55), seg=10, rings=6)


def nail(x, y, z, face="-y"):
	if face == "-y":
		kit.cylinder(0.009, 0.006, (x, y - 0.001, z), IRON("dark"), rot=(90, 0, 0), verts=8, bevel=0.001)
	else:
		kit.cylinder(0.009, 0.006, (x, y, z + 0.001), IRON("dark"), verts=8, bevel=0.001)


def arc(major, minor, loc, m, rotz=0.0, seg=20):
	"""The upper half of a ring standing upright (helmet crest, pot bail)."""
	bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=seg, minor_segments=6, location=loc)
	o = bpy.context.object
	for v in o.data.vertices:
		v.co.y = max(v.co.y, 0.0)
	o.rotation_euler = (math.pi / 2, 0, math.radians(rotz))
	return kit._finish(o, m, 0, 0)


def panel(w, h, z0=0.0, d=0.045, battens=None):
	"""Wall backing: vertical split boards (flat back at y = d), pegged battens, two floor posts if raised."""
	n = max(2, round(w / 0.2))
	for i in range(n):
		B((w / n - 0.007, d, h + J(0.01)), (-w / 2 + w / n * (i + 0.5), d / 2, z0 + h / 2), PL(), bevel=0.008)
	for bz in (battens if battens is not None else (0.12, h - 0.12)):
		B((w - 0.05, 0.03, 0.07), (0, -0.012, z0 + bz), DK(), bevel=0.006)
		for i in range(n):
			peg(-w / 2 + w / n * (i + 0.5), -0.027, z0 + bz, r=0.01)
	if z0 > 0.05:
		for x in (-w / 2 + 0.12, w / 2 - 0.12):
			B((0.07, 0.042, z0 + 0.05), (x, -0.019, (z0 + 0.06) / 2 + 0.005), DK(), bevel=0.008)
			B((0.16, 0.12, 0.035), (x, -0.04, 0.0175), DK(), bevel=0.006)


def shelf(w, z, depth=0.2, lip=True):
	"""A plank shelf pressed into the panel front (y = 0) on two braces. Returns the top height."""
	board((w, depth, 0.035), (0, -depth / 2 + 0.004, z))
	for x in (-w / 2 + 0.07, w / 2 - 0.07):
		beam((x, 0.004, max(z - 0.15, 0.015)), (x, -depth * 0.75, z - 0.012), 0.035, 0.035, DK())
	if lip:
		B((w - 0.04, 0.016, 0.03), (0, -depth + 0.012, z + 0.03), DK(), bevel=0.004)
	return z + 0.0175


def corner_irons(w, z0, h, y=0.0):
	"""L-shaped iron corner plates with rivets on a board front."""
	for sx in (-1, 1):
		for sz in (-1, 1):
			x, z = sx * (w / 2 - 0.05), z0 + h / 2 + sz * (h / 2 - 0.05)
			B((0.09, 0.012, 0.025), (x, y - 0.004, z + sz * 0.033), IRON("dark"), bevel=0.003)
			B((0.025, 0.012, 0.09), (x + sx * 0.033, y - 0.004, z), IRON("dark"), bevel=0.003)
			rivet((x + sx * 0.033, y - 0.01, z + sz * 0.033), IRON("dark"), r=0.009)


def cband(size, loc, rivets=3, m=None):
	"""An iron strap on a front face, copper rivets along it."""
	B(size, loc, m or IRON("dark"), bevel=0.003)
	for i in range(rivets):
		x = loc[0] + (i - (rivets - 1) / 2) * (size[0] - 0.06) / max(1, rivets - 1)
		rivet((x, loc[1] - size[1] / 2, loc[2]), CU("dark"), r=0.009)


def barrel(r=0.22, h=0.6, n=12, bulge=1.1, hoops=(0.12, 0.38, 0.62, 0.88), lid=True):
	"""A stave barrel standing at the origin: separate staves (each its own painting), heads, iron hoops."""
	rm, t = r * bulge, 0.022
	gap = 0.0025 / r
	levels = ((0.0, r), (h / 2, rm), (h, r))
	for i in range(n):
		a0, a1 = 2 * math.pi * i / n + gap, 2 * math.pi * (i + 1) / n - gap
		v = []
		for z, R in levels:
			for a in (a0, a1):
				v += [(math.cos(a) * R, math.sin(a) * R, z), (math.cos(a) * (R - t), math.sin(a) * (R - t), z)]
		f = []
		for L in range(2):
			b, c = L * 4, L * 4 + 4
			f += [(b, b + 2, c + 2, c), (b + 1, c + 1, c + 3, b + 3), (b, c, c + 1, b + 1), (b + 2, b + 3, c + 3, c + 2)]
		f += [(0, 1, 3, 2), (8, 10, 11, 9)]
		mesh(v, f, PL())
	kit.cylinder(r - t * 0.4, 0.025, (0, 0, 0.05), DK(), verts=n, bevel=0.003)
	if lid:
		kit.cylinder(r - t * 0.4, 0.025, (0, 0, h - 0.04), PL(), verts=n, bevel=0.003)
	for f_ in hoops:
		z = h * f_
		R = r + (rm - r) * (1 - abs(z - h / 2) / (h / 2))
		kit.ring(R + 0.003, 0.009, (0, 0, z), IRON("dark"), seg=n * 2)


def keg_lying(x, y, z, r=0.13, h=0.32):
	"""A small keg lying along x, centred at (x, y), its belly resting at height z."""
	group(lambda: barrel(r, h, n=10, hoops=(0.15, 0.85)), at=(x - h / 2, y, z + r * 1.1), rot=(0, 90, 0))
	kit.cylinder(0.018, 0.04, (x, y - r * 1.1 - 0.008, z + r * 1.1), DK(), rot=(90, 0, 0), verts=8, bevel=0.003)  # bung


def crate(w, d, h, loc, lid=True, rope=False):
	"""A slatted supply crate: bottom, two slats per side, corner posts, lid boards, iron corner caps."""
	x, y, z = loc
	B((w - 0.04, d - 0.04, 0.03), (x, y, z + 0.02), DK(), bevel=0.006)
	for s_ in (-1, 1):
		for k in range(2):
			zz = z + h * (0.27 + 0.48 * k)
			B((w, 0.025, h * 0.44), (x, y + s_ * (d / 2 - 0.0125), zz), PL(), bevel=0.008)
			B((0.025, d - 0.05, h * 0.44), (x + s_ * (w / 2 - 0.0125), y, zz), PL(), bevel=0.008)
	for cx in (-1, 1):
		for cy in (-1, 1):
			B((0.05, 0.05, h), (x + cx * (w / 2 - 0.015), y + cy * (d / 2 - 0.015), z + h / 2), DK(), bevel=0.008)
			B((0.06, 0.06, 0.03), (x + cx * (w / 2 - 0.016), y + cy * (d / 2 - 0.016), z + h - 0.008), IRON("dark"), bevel=0.004)
	if lid:
		nb = 3
		for i in range(nb):
			B((w - 0.075, d / nb - 0.008, 0.025), (x, y - d / 2 + d / nb * (i + 0.5), z + h - 0.0155), PL(), bevel=0.006)
	if rope:
		for s_ in (-1, 1):
			kit.ring(0.045, 0.011, (x + s_ * (w / 2 + 0.005), y, z + h * 0.62), ROPE(), rot=(0, 90, 0), seg=10)


def mug(x, y, z, m=None, r=0.045, h=0.11):
	m = m or PL()
	kit.cylinder(r, h, (x, y, z + h / 2), m, verts=10, bevel=0.006)
	for t in (0.02, h - 0.02):
		kit.ring(r + 0.002, 0.007, (x, y, z + t), IRON("dark"), seg=12)
	kit.ring(0.03, 0.009, (x + r + 0.012, y, z + h * 0.55), m, rot=(90, 0, 0), seg=10)
	kit.cylinder(r * 0.78, 0.006, (x, y, z + h + 0.001), INK(), verts=10, bevel=0)  # dark inside


def bowl(x, y, z, r=0.08, m=None):
	bpy.ops.mesh.primitive_uv_sphere_add(segments=14, ring_count=7, radius=r, location=(0, 0, 0))
	o = bpy.context.object
	for v in o.data.vertices:
		v.co.z = min(v.co.z, 0.0)
	o.scale = (1, 1, 0.55)
	bpy.ops.object.transform_apply(scale=True)
	o.location = (x, y, z + r * 0.55)
	kit._finish(o, m or PL(), 0, 0)
	kit.ring(r - 0.004, 0.006, (x, y, z + r * 0.55), m or PL(), seg=16)
	kit.cylinder(r * 0.8, 0.004, (x, y, z + r * 0.55 + 0.003), INK(), verts=14, bevel=0)


def spoon(x, y, z, ang=0.0, m=None):
	a = math.radians(ang)
	ux, uy = math.cos(a), math.sin(a)
	beam((x - ux * 0.07, y - uy * 0.07, z + 0.006), (x + ux * 0.05, y + uy * 0.05, z + 0.006), 0.014, 0.008, m or PL(), bevel=0.002)
	sphere((x + ux * 0.075, y + uy * 0.075, z + 0.012), 0.025, m or PL(), scale=(1.2, 0.85, 0.45), seg=10, rings=6)


def smooth(o):
	for p in o.data.polygons:
		p.use_smooth = True
	return o


def loft(levels, m, n=18, flat=0.3):
	"""A smooth shell through elliptical rings (z, rx, ry) around (0, cy): the back half is flattened by `flat`."""
	v = []
	for z, rx, ry, cy in levels:
		for k in range(n):
			a = 2 * math.pi * k / n
			sy = math.sin(a)
			v.append((rx * math.cos(a), cy + ry * sy * (1 if sy < 0 else flat), z))
	f = [(i * n + k, i * n + (k + 1) % n, (i + 1) * n + (k + 1) % n, (i + 1) * n + k) for i in range(len(levels) - 1) for k in range(n)]
	f += [tuple(reversed(range(n))), tuple(range((len(levels) - 1) * n, len(levels) * n))]
	return mesh(v, f, m, smooth=True)


def helmet(x, y, z, s=1.0, m=None):
	"""An iron guard helmet with its rim at height z: tall dome, copper band, crest strap, nasal guard, rivets."""
	m = m or IRON("a")
	smooth(sphere((x, y, z), 0.11 * s, m, scale=(1, 1.08, 1.25), cut=0.0, seg=18, rings=10))
	o = kit.ring(0.111 * s, 0.013 * s, (x, y, z + 0.016 * s), CU("b"), seg=22)
	o.scale = (1, 1.08, 1)
	o = arc(0.112 * s, 0.01 * s, (x, y, z), IRON("dark"), rotz=90)
	o.scale = (1.07, 1.24, 1)
	beam((x, y - 0.119 * s, z + 0.03 * s), (x, y - 0.123 * s, z - 0.085 * s), 0.028 * s, 0.012 * s, IRON("dark"), bevel=0.003)
	for k in range(10):
		a = 2 * math.pi * k / 10 + 0.15
		rivet((x + math.cos(a) * 0.123 * s, y + math.sin(a) * 0.133 * s, z + 0.016 * s), IRON("dark"), r=0.008 * s)


def shield(cx, cz, yb, r=0.24, missing=None, rim=True):
	"""A round plank shield, back face at y = yb: plank strips cut to the circle, straps, boss, rivets, rim."""
	t, n = 0.035, 5
	for i in range(n):
		if i == missing:
			continue
		xa, xb = -r + 2 * r / n * i + 0.002, -r + 2 * r / n * (i + 1) - 0.002
		pts = []
		for k in range(5):
			xx = xa + (xb - xa) * k / 4
			pts.append((cx + xx, cz - math.sqrt(max(0.0, r * r - xx * xx))))
		for k in range(5):
			xx = xb - (xb - xa) * k / 4
			pts.append((cx + xx, cz + math.sqrt(max(0.0, r * r - xx * xx))))
		prism(pts, yb - t, yb, PL())
	yf = yb - t
	for dz in (-0.12, 0.12):
		half = math.sqrt(r * r - dz * dz) - 0.02
		if missing is not None and dz > 0:
			B((half * 0.9, 0.009, 0.03), (cx - half * 0.55, yf - 0.003, cz + dz), IRON("dark"), bevel=0.003)
		else:
			B((half * 2, 0.009, 0.03), (cx, yf - 0.003, cz + dz), IRON("dark"), bevel=0.003)
	kit.cylinder(0.085 * r / 0.24, 0.01, (cx, yf - 0.003, cz), IRON("dark"), rot=(90, 0, 0), verts=16, bevel=0.002)
	sphere((cx, yf - 0.006, cz), 0.06 * r / 0.24, IRON("a"), scale=(1, 0.65, 1), seg=14, rings=8)
	for k in range(10):
		a = 2 * math.pi * k / 10 + 0.3
		ox = math.cos(a) * r * 0.82
		if missing is not None and int((ox + r) // (2 * r / n)) == missing:
			continue
		rivet((cx + ox, yf + 0.002, cz + math.sin(a) * r * 0.82), CU("dark"), r=0.011)
	if rim:
		kit.ring(r - 0.004, 0.013, (cx, yb - t / 2, cz), IRON("dark"), rot=(90, 0, 0), seg=28)


def lantern(c, glow=False):
	"""An iron lantern standing at c: base, four corner posts, glass, roof cone, ring."""
	x, y, z = c
	kit.cylinder(0.075, 0.025, (x, y, z + 0.0125), IRON("dark"), verts=8, bevel=0.004)
	for k in range(4):
		a = math.pi / 4 + k * math.pi / 2
		B((0.016, 0.016, 0.17), (x + math.cos(a) * 0.058, y + math.sin(a) * 0.058, z + 0.11), IRON("dark"), bevel=0.003)
	kit.cylinder(0.05, 0.15, (x, y, z + 0.1), C((0.95, 0.7, 0.35), 0.3, glow=1.0) if glow else GLASS(), verts=8, bevel=0)
	kit.cone(0.08, 0.02, 0.07, (x, y, z + 0.225), IRON("a"), verts=8, bevel=0.004)
	kit.ring(0.022, 0.006, (x, y, z + 0.275), IRON("dark"), rot=(90, 0, 0), seg=10)


def crowbar(p0, p1):
	"""An iron pry bar from p0 (claw end) to p1 (straight end), with a hooked claw."""
	p0, p1 = Vector(p0), Vector(p1)
	rod(tuple(p0), tuple(p1), 0.012, IRON("dark"), seg=6)
	d = (p1 - p0).normalized()
	up = Vector((0, 0, 1))
	claw = p0 - d * 0.05 + up * 0.03
	rod(tuple(p0 + d * 0.005), tuple(claw), 0.011, IRON("dark"), seg=6)
	kit.cone(0.011, 0.004, 0.03, tuple(claw - d * 0.012 + up * 0.004), IRON("dark"), verts=6, bevel=0)


def hammer(x, y, ang=0.0):
	"""A claw hammer lying on the floor at (x, y)."""
	a = math.radians(ang)
	ux, uy = math.cos(a), math.sin(a)
	beam((x - ux * 0.13, y - uy * 0.13, 0.016), (x + ux * 0.11, y + uy * 0.11, 0.016), 0.03, 0.026, PL(), bevel=0.004)
	B((0.035, 0.12, 0.035), (x + ux * 0.12, y + uy * 0.12, 0.0215), IRON("a"), bevel=0.004, rot=(0, 0, ang))
	kit.cone(0.018, 0.006, 0.06, (x + ux * 0.12 + uy * 0.07, y + uy * 0.12 - ux * 0.07, 0.0215), IRON("a"), rot=(90, 0, ang), verts=8, bevel=0.002)


def splinters(p, ax, n=4, r=0.03):
	"""Jagged splinters sticking out of a snapped end at p, pointing along ax."""
	ax = Vector(ax).normalized()
	q = Vector((0, 0, 1)).rotation_difference(ax)
	u = ax.orthogonal().normalized()
	v = ax.cross(u)
	for k in range(n):
		a = 2 * math.pi * k / n + J(0.4)
		c = Vector(p) + (u * math.cos(a) + v * math.sin(a)) * r * 0.5 + ax * 0.02
		o = kit.cone(0.014, 0.0, 0.05 + J(0.02), tuple(c), END(), verts=4, bevel=0)
		o.rotation_euler = q.to_euler()


def carve(target, size, loc, rot=(0, 0, 0), cyl=None):
	"""Cut a groove/hole INTO a part (boolean difference), so marks are real cuts, never sticks on top."""
	if cyl:
		bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=cyl[0], depth=cyl[1], location=loc, rotation=[math.radians(a) for a in rot])
	else:
		bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=[math.radians(a) for a in rot])
		bpy.context.object.scale = size
	cut = bpy.context.object
	m = target.modifiers.new("cut", "BOOLEAN")
	m.operation = "DIFFERENCE"
	m.object = cut
	m.solver = "EXACT"
	bpy.ops.object.select_all(action="DESELECT")
	target.select_set(True)
	bpy.context.view_layer.objects.active = target
	bpy.ops.object.modifier_apply(modifier=m.name)
	bpy.data.objects.remove(cut, do_unlink=True)


def legs_log(w, d, h, r=0.045, inset=0.06):
	for x in (-w / 2 + inset, w / 2 - inset):
		for y in (-d / 2 + inset, d / 2 - inset):
			hlog((x, y, 0), (x + J(0.008), y + J(0.008), h), r, seg=7)


def top_boards(w, d, z, t=0.045, n=4):
	for i in range(n):
		board((w, d / n - 0.008, t), (0, -d / 2 + d / n * (i + 0.5), z))


def stool_logs():
	"""A three-legged log stool standing upright at the origin (seat top at 0.42)."""
	hlog((0, 0, 0.36), (0, 0, 0.42), 0.17, seg=12, rings=1)
	for k in range(3):
		a = 2 * math.pi * k / 3
		hlog((math.cos(a) * 0.08, math.sin(a) * 0.08, 0.37), (math.cos(a) * 0.15, math.sin(a) * 0.15, 0.0), 0.035, seg=6)
	kit.ring(0.115, 0.012, (0, 0, 0.18), ROPE(), seg=14)


def strongbox_body(w, d, h):
	"""An open plank box with iron bands and corner irons, empty (dark floor)."""
	t = 0.035
	B((w - 2 * t + 0.01, d - 2 * t + 0.01, t), (0, 0, t / 2 + 0.003), PL(), bevel=0.006)
	for s_ in (-1, 1):
		B((w, t, h), (0, s_ * (d / 2 - t / 2), h / 2), PL(), bevel=0.006)
		B((t, d - 2 * t + 0.004, h - 0.01), (s_ * (w / 2 - t / 2), 0, h / 2 + 0.002), PL(), bevel=0.006)
	B((w - 2 * t, d - 2 * t, 0.006), (0, 0, t + 0.006), INK(), bevel=0)
	for x in (-w / 2 + 0.08, w / 2 - 0.08):
		for s_ in (-1, 1):
			B((0.05, 0.012, h - 0.01), (x, s_ * (d / 2 + 0.004), h / 2 + 0.004), IRON("dark"), bevel=0.003)
			for z in (0.07, h - 0.06):
				rivet((x, s_ * (d / 2 + 0.011), z), CU("dark"), r=0.01)
	for cx in (-1, 1):
		for cy in (-1, 1):
			B((0.04, 0.04, h + 0.006), (cx * (w / 2 - 0.006), cy * (d / 2 - 0.006), h / 2 + 0.006), IRON("a"), bevel=0.004)


# ================= Wall pieces =================
def key_part(L, s=1.0, m=None, bits=2):
	"""A big key hanging from the origin (top of its bow at z = 0), shaft down, bits to +x."""
	m = m or IRON("dark")
	br = 0.024 * s
	kit.ring(br, 0.006 * s + 0.001, (0, 0, -br), m, rot=(90, 0, 0), seg=14)
	top = -br * 2 + 0.004
	B((0.013 * s, 0.013 * s, L), (0, 0, top - L / 2 + 0.006), m, bevel=0.002)
	B((0.022 * s, 0.019 * s, 0.012 * s), (0, 0, top - 0.004), m, bevel=0.002)
	zb = top - L + 0.006
	for k in range(bits):
		B((0.03 * s - 0.006 * k, 0.01 * s, 0.013 * s), (0.017 * s, 0, zb + 0.008 + k * 0.022 * s), m, bevel=0.002)


def mg_key_board():
	W, H, Z0 = 0.74, 0.62, 0.92
	panel(W, H, Z0, battens=(0.2, 0.47))
	B((W + 0.08, 0.1, 0.05), (0, -0.01, Z0 + H + 0.012), DK(), bevel=0.01)
	B((W + 0.06, 0.08, 0.04), (0, -0.005, Z0 - 0.005), DK(), bevel=0.01)
	corner_irons(W - 0.02, Z0 + 0.03, H - 0.06)
	B((0.16, 0.012, 0.06), (0, -0.006, Z0 + H - 0.06), CU("b"), bevel=0.003)  # copper plate
	for x in (-0.065, 0.065):
		rivet((x, -0.012, Z0 + H - 0.06), CU("dark"), r=0.008)
	rows = ((Z0 + 0.47, ((-0.26, 0.17, 2), (-0.09, 0.13, 3), (0.09, 0.19, 2), (0.26, 0.12, 1))),
		(Z0 + 0.2, ((-0.26, 0.13, 2), (-0.09, None, 0), (0.09, "ring", 0), (0.26, 0.15, 3))))
	for z, keys in rows:
		for x, L, bits in keys:
			B((0.014, 0.055, 0.014), (x, -0.05, z), IRON("dark"), bevel=0.003)  # hook arm out of the batten
			B((0.014, 0.014, 0.034), (x, -0.071, z + 0.012), IRON("dark"), bevel=0.003)  # hook tip turned up
			if L is None:
				continue  # an empty hook: one key is missing
			if L == "ring":
				kit.ring(0.04, 0.006, (x, -0.055, z - 0.035), IRON("a"), rot=(90, 0, 0), seg=18)
				for k, dx in enumerate((-0.025, 0.0, 0.025)):
					zt = z - 0.035 - math.sqrt(0.04 ** 2 - dx * dx) + 0.008
					group(lambda: key_part(0.07 + 0.01 * k, 0.6, CU("dark") if k == 1 else IRON("dark"), 1), at=(x + dx, -0.055, zt), rot=(0, 0, 90))
				continue
			group(lambda: key_part(L, 1.0, CU("dark") if bits == 3 else IRON("dark"), bits), at=(x, -0.055, z + 0.007))


def mg_shield_wall():
	W, H, Z0 = 1.56, 0.62, 0.72
	panel(W, H, Z0, battens=())
	hlog((-W / 2 - 0.03, -0.035, Z0 + H + 0.01), (W / 2 + 0.03, -0.035, Z0 + H + 0.01), 0.05, bend=0.02)
	for x in (-0.6, 0.6):
		peg(x, -0.08, Z0 + H + 0.02, r=0.012)
	cz = Z0 + 0.33
	for i, cx in enumerate((-0.5, 0.0, 0.5)):
		miss = 3 if i == 1 else None
		shield(cx, cz, -0.012, 0.24, missing=miss, rim=miss is None)
		peg(cx - 0.12, 0.0, cz + 0.17, r=0.014)
		peg(cx + 0.12 if miss is None else cx - 0.04, 0.0, cz - 0.17, r=0.014)
	top = shelf(W - 0.1, Z0, depth=0.14)
	# the lost plank of the middle shield lies on the ledge
	B((0.3, 0.085, 0.03), (0.12, -0.07, top + 0.013), PL(), bevel=0.008, rot=(0, 0, 4))


def crossbow(cx, cz, yb):
	"""A crossbow hung upright (stirrup up) with its back at y = yb."""
	y = yb - 0.025
	B((0.05, 0.045, 0.5), (cx, y, cz - 0.08), PL(), bevel=0.008)  # stock
	B((0.07, 0.05, 0.12), (cx, y - 0.002, cz - 0.3), PL(), bevel=0.01)  # butt
	B((0.06, 0.012, 0.07), (cx, y - 0.025, cz - 0.04), IRON("dark"), bevel=0.003)  # nut plate
	beam((cx, y + 0.01, cz - 0.07), (cx, y + 0.045, cz - 0.2), 0.012, 0.01, IRON("dark"), bevel=0.002)  # trigger lever
	for s_ in (-1, 1):  # the bow arms, bending back a little
		beam((cx, y - 0.005, cz + 0.13), (cx + s_ * 0.17, y + 0.005, cz + 0.11), 0.03, 0.022, IRON("a"), bevel=0.004)
		beam((cx + s_ * 0.165, y + 0.005, cz + 0.11), (cx + s_ * 0.28, y + 0.02, cz + 0.075), 0.024, 0.018, IRON("a"), bevel=0.004)
		rod((cx + s_ * 0.27, y + 0.02, cz + 0.07), (cx + s_ * 0.004, y - 0.008, cz - 0.04), 0.004, ROPE(), seg=5)  # string
	kit.ring(0.045, 0.009, (cx, y, cz + 0.2), IRON("dark"), rot=(90, 0, 0), seg=14)  # stirrup
	B((0.06, 0.05, 0.04), (cx, y, cz + 0.135), IRON("dark"), bevel=0.004)  # bow clamp
	for z in (cz + 0.03, cz - 0.2):
		kit.ring(0.032, 0.006, (cx, y, z), IRON("dark"), seg=12).scale = (0.85, 0.9, 1)


def mg_crossbow_rack():
	W, H, Z0 = 1.3, 0.8, 0.4
	panel(W, H, Z0, battens=(0.1, 0.72))
	B((W + 0.07, 0.09, 0.045), (0, -0.01, Z0 + H + 0.01), DK(), bevel=0.01)
	cz = Z0 + 0.5
	for i, cx in enumerate((-0.4, 0.0, 0.4)):
		for dx in (-0.15, 0.15):
			B((0.03, 0.08, 0.03), (cx + dx, -0.035, cz + 0.088), DK(), bevel=0.005)  # rest pegs under the bow arms
		if i != 2:
			crossbow(cx, cz, -0.022)
	# the bolt box on its own little shelf
	top = shelf(W - 0.15, Z0 + 0.16, depth=0.2, lip=False)
	bx, by, bw, bd, bh = 0.0, -0.1, 0.62, 0.15, 0.12
	B((bw - 0.03, bd - 0.03, 0.02), (bx, by, top + 0.016), DK(), bevel=0.004)
	for s_ in (-1, 1):
		B((bw, 0.02, bh), (bx, by + s_ * (bd / 2 - 0.01), top + bh / 2 + 0.003), PL(), bevel=0.005)
		B((0.02, bd - 0.04, bh), (bx + s_ * (bw / 2 - 0.01), by, top + bh / 2 + 0.003), PL(), bevel=0.005)
	for k in range(3):
		B((0.012, bd - 0.04, bh * 0.8), (bx - bw / 4 + k * bw / 4, by, top + bh * 0.42), DK(), bevel=0.003)
	cband((bw + 0.01, 0.012, 0.03), (bx, by - bd / 2 - 0.002, top + bh * 0.7), 3)
	for k in range(16):  # bolts point down, fletching up
		x = bx - bw / 2 + 0.05 + (k % 8) * (bw - 0.1) / 7 + J(0.006)
		y = by - 0.03 + 0.06 * (k // 8) + J(0.005)
		tx = x + math.sin(math.radians(J(6))) * 0.24
		rod((x, y, top + 0.03), (tx, y, top + 0.25), 0.0055, PL(), seg=5)
		for a in (0, 90):
			B((0.004, 0.035, 0.05), ((x + tx) / 2 + (tx - x) * 0.35, y, top + 0.21), LEATHER2(), bevel=0.001, rot=(0, 0, a))


def mg_helmet_pegs():
	W = 1.25
	panel(W, 0.36, 0.9, battens=())
	hlog((-W / 2, -0.04, 1.14), (W / 2, -0.04, 1.14), 0.055, bend=0.02)
	for x in (-0.6, 0.6):
		peg(x, -0.09, 1.16, r=0.012)
	B((W + 0.06, 0.08, 0.04), (0, 0.0, 1.27), DK(), bevel=0.01)
	for i, x in enumerate((-0.45, -0.15, 0.15, 0.45)):
		rod((x, -0.04, 1.09), (x, -0.27, 1.14), 0.016, DK(), seg=7)  # peg angled up out of the rail
		sphere((x, -0.272, 1.141), 0.022, DK(), seg=10, rings=6)
		if i == 2:  # a belt with a copper buckle and a pouch
			kit.ring(0.03, 0.007, (x, -0.2, 1.1), LEATHER(), rot=(90, 0, 0), seg=12)
			beam((x - 0.014, -0.2, 1.08), (x - 0.03, -0.18, 0.84), 0.04, 0.007, LEATHER(), bevel=0.001)
			beam((x + 0.014, -0.2, 1.08), (x + 0.03, -0.18, 0.9), 0.04, 0.007, LEATHER(), bevel=0.001)
			kit.ring(0.03, 0.007, (x + 0.03, -0.18, 0.885), CU("b"), rot=(90, 0, 0), seg=12)
			B((0.09, 0.03, 0.1), (x - 0.03, -0.18, 0.82), LEATHER2(), bevel=0.012)
			B((0.092, 0.034, 0.04), (x - 0.03, -0.18, 0.86), LEATHER(), bevel=0.006)
			rivet((x - 0.03, -0.2, 0.85), CU("dark"), r=0.009)
		elif i == 3:
			continue  # an empty peg
		else:
			helmet(x, -0.245, 1.1, s=1.1, m=IRON("a" if i == 0 else "b"))


def mg_bowl_shelf():
	W = 0.92
	panel(W, 1.25, 0.0, battens=(0.25, 1.15))
	B((W + 0.08, 0.1, 0.05), (0, -0.01, 1.26), DK(), bevel=0.01)
	# bottom: plates standing on edge against a rail
	top0 = shelf(W, 0.1, depth=0.22, lip=False)
	B((W - 0.06, 0.03, 0.05), (0, -0.175, top0 + 0.025), DK(), bevel=0.004)
	for k in range(6):
		px, py = -0.33 + k * 0.13, -0.12 - 0.02 * (k % 2)
		kit.cylinder(0.1, 0.018, (px, py, top0 + 0.1), PL(), rot=(72, 0, 0), verts=16, bevel=0.004)
		kit.ring(0.085, 0.006, (px, py - 0.009, top0 + 0.103), DK(), rot=(72, 0, 0), seg=16)
	# middle: a row of mugs
	top1 = shelf(W, 0.42, depth=0.2)
	for k in range(5):
		mug(-0.34 + k * 0.165, -0.1, top1, m=PL() if k != 2 else CU("b"))
	# upper: stacks of nested bowls
	top2 = shelf(W, 0.72, depth=0.22)
	for k, x in enumerate((-0.27, 0.0, 0.27)):
		for j in range(4 - (k == 1)):
			bowl(x, -0.11, top2 + j * 0.028, 0.09 - j * 0.004)
	# ladles and spoons on iron hooks along the top batten
	for k, x in enumerate((-0.3, -0.1, 0.1, 0.3)):
		B((0.012, 0.06, 0.012), (x, -0.05, 1.15), IRON("dark"), bevel=0.003)
		B((0.012, 0.012, 0.03), (x, -0.076, 1.163), IRON("dark"), bevel=0.003)
		kit.ring(0.014, 0.004, (x, -0.065, 1.138), IRON("dark"), rot=(0, 90, 0), seg=8)
		L = 0.2 if k % 2 == 0 else 0.15
		B((0.016, 0.01, L), (x, -0.065, 1.13 - L / 2), PL(), bevel=0.003)
		if k % 2 == 0:
			bowl(x, -0.065, 1.13 - L - 0.022, 0.045)
		else:
			sphere((x, -0.065, 1.13 - L - 0.015), 0.024, PL(), scale=(0.9, 0.5, 1.3), seg=10, rings=6)


def coil(x, y, z, r=0.14, n=5):
	"""A coil of rope hanging in the x-z plane, loops a little apart and touching, a binding wrap at the top."""
	for k in range(n):
		kit.ring(r - k * 0.006 + J(0.004), 0.016, (x + J(0.006), y - k * 0.022, z - k * 0.008), ROPE(), rot=(90, 0, J(4)), seg=22)
	for dx in (-0.03, 0.03):
		kit.ring(0.032 + 0.011 * n, 0.011, (x + dx, y - (n - 1) * 0.011, z + r - 0.02), ROPE(), rot=(0, 90, 0), seg=12).scale = (1, 1, 0.5)


def mg_rope_wall():
	W, H, Z0 = 1.2, 0.95, 0.3
	panel(W, H, Z0, battens=(0.12, 0.78))
	B((W + 0.08, 0.1, 0.05), (0, -0.01, Z0 + H + 0.012), DK(), bevel=0.01)
	zp = Z0 + 0.78
	for x in (-0.42, -0.13, 0.15, 0.42):
		rod((x, -0.025, zp), (x, -0.17, zp + 0.035), 0.02, DK(), seg=7)
		sphere((x, -0.172, zp + 0.036), 0.026, DK(), seg=10, rings=6)
	coil(-0.42, -0.065, zp - 0.13, r=0.15, n=4)
	coil(-0.13, -0.065, zp - 0.1, r=0.11, n=3)
	# grapnel hanging by its ring
	gx = 0.15
	kit.ring(0.03, 0.008, (gx, -0.12, zp - 0.012), IRON("dark"), rot=(90, 0, 0), seg=12)
	rod((gx, -0.12, zp - 0.04), (gx, -0.12, zp - 0.36), 0.013, IRON("dark"))
	for k in range(4):
		a = math.pi / 4 + k * math.pi / 2
		ux, uy = math.cos(a), math.sin(a) * 0.6
		p0 = Vector((gx, -0.12, zp - 0.35))
		p1 = p0 + Vector((ux * 0.08, uy * 0.08, -0.03))
		p2 = p1 + Vector((ux * 0.03, uy * 0.03, 0.07))
		rod(tuple(p0), tuple(p1), 0.011, IRON("dark"))
		rod(tuple(p1), tuple(p2), 0.01, IRON("dark"))
		kit.cone(0.012, 0.0, 0.035, tuple(p2 + Vector((0, 0, 0.012))), IRON("a"), verts=5, bevel=0)
	kit.ring(0.02, 0.007, (gx, -0.12, zp - 0.375), IRON("dark"), rot=(90, 0, 0), seg=10)
	rod((gx, -0.12, zp - 0.39), (gx + 0.02, -0.07, Z0 + 0.01), 0.012, ROPE())  # its rope trails down to the ledge
	# pulley block on the right peg
	px = 0.42
	kit.ring(0.026, 0.007, (px, -0.13, zp - 0.008), IRON("dark"), rot=(90, 0, 0), seg=10)
	B((0.012, 0.012, 0.06), (px, -0.13, zp - 0.055), IRON("dark"), bevel=0.002)
	B((0.1, 0.07, 0.16), (px, -0.13, zp - 0.16), PL(), bevel=0.015)
	kit.cylinder(0.055, 0.02, (px, -0.13, zp - 0.16), IRON("a"), rot=(90, 0, 0), verts=14, bevel=0.003)
	kit.cylinder(0.015, 0.09, (px, -0.13, zp - 0.16), IRON("dark"), rot=(90, 0, 0), verts=8, bevel=0.002)
	for s_ in (-1, 1):
		B((0.012, 0.075, 0.17), (px + s_ * 0.054, -0.13, zp - 0.16), IRON("dark"), bevel=0.002)
		rod((px + s_ * 0.06, -0.13, zp - 0.2), (px + s_ * 0.062, -0.12, Z0 + 0.12 + 0.15 * (s_ > 0)), 0.01, ROPE())
	kit.ring(0.032, 0.008, (px + 0.062, -0.12, Z0 + 0.24), IRON("dark"), rot=(90, 0, 0), seg=12)
	shelf(W - 0.1, Z0, depth=0.16)


def book(x, y, z, w, d, h, m, rot=(0, 0, 0)):
	"""A bound book standing on its bottom edge (or flat when h is small): cover, page block, copper corner caps."""
	def build():
		B((w, d, h), (0, 0, h / 2), m, bevel=0.004)
		B((w * 0.9, d - 0.014, h * 0.86), (w * 0.06 + 0.003, 0.004, h / 2), PAPER(), bevel=0.002)
		for zz in (0.012, h - 0.012):
			B((w + 0.004, d * 0.4, 0.012), (0, 0, zz), CU("dark"), bevel=0.002)
	group(build, at=(x, y, z), rot=rot)


def scroll(x, y, z, L, r=0.022, axis="y"):
	rot = (90, 0, 0) if axis == "y" else (0, 90, 0)
	kit.cylinder(r, L, (x, y, z + r), PAPER(), rot=rot, verts=10, bevel=0.003)
	kit.ring(r + 0.001, 0.005, (x, y, z + r), LEATHER2(), rot=rot, seg=10)


def mg_ledger_shelf():
	W, H, D = 0.94, 1.2, 0.3
	panel(W, H, 0.0, d=0.03, battens=())
	for s_ in (-1, 1):
		B((0.04, D, H), (s_ * (W / 2 - 0.02), -D / 2 + 0.005, H / 2), PL(), bevel=0.008)
	shelves = (0.05, 0.36, 0.66, 0.96, H - 0.02)
	for z in shelves:
		B((W - 0.075, D - 0.01, 0.03), (0, -D / 2 + 0.005, z), PL(), bevel=0.006)
	B((W + 0.06, D + 0.04, 0.05), (0, -D / 2 + 0.005, H + 0.02), DK(), bevel=0.01)
	for z0, z1 in zip(shelves[:-1], shelves[1:]):  # two dividers per row: three cubbies
		for x in (-W / 6, W / 6):
			B((0.025, D - 0.02, z1 - z0 - 0.03), (x, -D / 2 + 0.005, (z0 + z1) / 2), DK(), bevel=0.004)
	cw = (W - 0.08) / 3
	cx = (-cw, 0.0, cw)
	# row 1: tall ledgers
	z1 = shelves[0] + 0.015
	for c in range(3):
		for k in range(4 - c % 2):
			book(cx[c] - cw / 2 + 0.06 + k * 0.05, -0.15, z1, 0.04, 0.2, 0.24 - 0.02 * (k % 2), LEATHER() if k % 2 else LEATHER2())
	# row 2: scroll pyramids, two ledgers lying flat
	z2 = shelves[1] + 0.015
	for c in (0, 2):
		for row, nn in enumerate((3, 2, 1)):
			for k in range(nn):
				scroll(cx[c] - (nn - 1) * 0.024 + k * 0.048, -0.14, z2 + row * 0.04, 0.24)
	book(cx[1] - 0.01, -0.15, z2, 0.18, 0.2, 0.045, LEATHER())
	book(cx[1] - 0.0, -0.15, z2 + 0.045, 0.16, 0.18, 0.04, LEATHER2(), rot=(0, 0, 8))
	# row 3: a bundle of tally sticks, inkpot and quill, small books, scrolls
	z3 = shelves[2] + 0.015
	for k in range(7):
		zz = z3 + 0.01 + (k % 2) * 0.012
		rod((cx[0] - 0.12, -0.2 + k * 0.016, zz), (cx[0] + 0.12, -0.2 + k * 0.016, zz), 0.009, PL(), seg=6)
	for x in (-0.06, 0.06):
		kit.ring(0.048, 0.008, (cx[0] + x, -0.152, z3 + 0.022), ROPE(), rot=(0, 90, 0), seg=12).scale = (1, 1.12, 0.55)
	kit.cylinder(0.04, 0.06, (cx[1] - 0.05, -0.15, z3 + 0.03), CU("dark"), verts=10, bevel=0.006)
	kit.cylinder(0.018, 0.012, (cx[1] - 0.05, -0.15, z3 + 0.062), INK(), verts=8, bevel=0.002)
	rod((cx[1] - 0.05, -0.15, z3 + 0.055), (cx[1] - 0.0, -0.17, z3 + 0.24), 0.004, QUILL(), seg=5)
	kit.cone(0.018, 0.004, 0.11, (cx[1] - 0.007, -0.168, z3 + 0.2), QUILL(), rot=(0, 15, 0), verts=4, bevel=0)
	for k in range(3):
		book(cx[1] + 0.04 + k * 0.035, -0.15, z3, 0.03, 0.15, 0.17, LEATHER() if k != 1 else LEATHER2())
	for k in range(3):
		scroll(cx[2] - 0.06 + k * 0.05, -0.14, z3, 0.22)
	# row 4: a stack of ledgers, the seal box, books
	z4 = shelves[3] + 0.015
	for j in range(3):
		book(cx[0], -0.15, z4 + 0.036 * j, 0.18, 0.2, 0.035, LEATHER() if j % 2 else LEATHER2(), rot=(0, 0, 4 - 3 * j))
	B((0.16, 0.13, 0.11), (cx[1], -0.15, z4 + 0.055), PL(), bevel=0.008)
	cband((0.165, 0.012, 0.025), (cx[1], -0.219, z4 + 0.07), 2)
	for k in range(4):
		book(cx[2] - 0.08 + k * 0.042, -0.15, z4, 0.035, 0.19, 0.22 - 0.015 * k, LEATHER() if k % 2 else LEATHER2())


def mg_gate_windlass():
	W, H = 0.9, 1.5
	panel(W, H, 0.0, battens=(0.3, 1.3))
	B((W + 0.08, 0.12, 0.06), (0, -0.02, H + 0.015), DK(), bevel=0.01)
	zc, yc = 0.85, -0.26
	for s_ in (-1, 1):  # two heavy side cheeks holding the drum
		B((0.07, 0.3, 0.34), (s_ * 0.3, -0.13, zc - 0.02), PL(), bevel=0.012)
		B((0.08, 0.012, 0.36), (s_ * 0.3, -0.284, zc - 0.02), IRON("dark"), bevel=0.003)
		for z in (zc - 0.13, zc + 0.09):
			rivet((s_ * 0.3, -0.29, z), CU("dark"), r=0.01)
		beam((s_ * 0.3, -0.004, zc - 0.5), (s_ * 0.3, -0.2, zc - 0.18), 0.05, 0.05, DK())
	hlog((-0.34, yc, zc), (0.34, yc, zc), 0.1, seg=10, rings=2, bend=0.0)
	for x in (-0.2, 0.2):
		kit.ring(0.1, 0.012, (x, yc, zc), IRON("dark"), rot=(0, 90, 0), seg=20)
	# chain wound on the drum, then up through an iron eye under the top beam
	for k in range(6):
		kit.ring(0.108, 0.009, (-0.12 + k * 0.034, yc, zc), IRON("a"), rot=(0, 90, 0), seg=20)
	chain((0.06, yc, zc + 0.115), (0.06, -0.06, H - 0.05), link=0.03, wire=0.008, m=IRON("a"))
	kit.ring(0.04, 0.012, (0.06, -0.06, H - 0.03), IRON("dark"), seg=14)
	B((0.1, 0.05, 0.03), (0.06, -0.035, H - 0.015), IRON("dark"), bevel=0.003)
	# spoked crank wheel on the right end
	wx = 0.38
	rod((0.33, yc, zc), (wx + 0.04, yc, zc), 0.025, IRON("dark"))
	kit.ring(0.24, 0.022, (wx, yc, zc), PL(), rot=(0, 90, 0), seg=28)
	kit.ring(0.256, 0.011, (wx, yc, zc), IRON("dark"), rot=(0, 90, 0), seg=30)
	kit.cylinder(0.05, 0.07, (wx, yc, zc), DK(), rot=(0, 90, 0), verts=10, bevel=0.006)
	for k in range(6):
		a = 2 * math.pi * k / 6
		beam((wx, yc + math.cos(a) * 0.04, zc + math.sin(a) * 0.04), (wx, yc + math.cos(a) * 0.23, zc + math.sin(a) * 0.23), 0.03, 0.025, PL(), bevel=0.004)
		hy, hz = yc + math.cos(a) * 0.245, zc + math.sin(a) * 0.245
		rod((wx + 0.015, hy, hz), (wx + 0.1, hy, hz), 0.016, DK())  # hand grips
	# ratchet wheel and pawl on the left end
	rx = -0.37
	kit.cylinder(0.11, 0.03, (rx, yc, zc), IRON("dark"), rot=(0, 90, 0), verts=16, bevel=0.003)
	for k in range(12):
		a = 2 * math.pi * k / 12
		B((0.028, 0.035, 0.022), (rx, yc + math.cos(a) * 0.115, zc + math.sin(a) * 0.115), IRON("dark"), bevel=0.002, rot=(math.degrees(a) + 20, 0, 0))
	beam((rx, -0.1, zc + 0.24), (rx, yc + 0.02, zc + 0.125), 0.025, 0.02, IRON("a"), bevel=0.003)
	B((0.05, 0.12, 0.05), (rx, -0.06, zc + 0.24), DK(), bevel=0.006)
	rivet((rx - 0.027, -0.09, zc + 0.24), CU("dark"), r=0.012)


# ================= Story scenes =================
def mg_last_watch():
	"""A guard's table: peg game half played, tankards (one tipped), the lantern on the floor, the stool knocked over."""
	W, D, H = 0.7, 0.6, 0.66
	legs_log(W, D, H - 0.04, r=0.04)
	for y in (-D / 2 + 0.06, D / 2 - 0.06):
		hlog((-W / 2 + 0.06, y, 0.2), (W / 2 - 0.06, y, 0.2), 0.03, seg=6)
	top_boards(W + 0.06, D + 0.04, H - 0.02, n=3)
	zt = H + 0.0025
	for x in (-W / 2 + 0.06, W / 2 - 0.06):
		for y in (-0.2, 0.0, 0.2):
			peg(x, y, zt, face="+z", r=0.009)
	gb = B((0.3, 0.2, 0.03), (-0.08, -0.04, zt + 0.012), DK(), bevel=0.006)
	holes = [(-0.19 + i * 0.055, -0.09 + j * 0.05) for i in range(5) for j in range(3)]
	for x, y in holes:
		carve(gb, None, (x, y, zt + 0.03), cyl=(0.009, 0.03))
	for (i, j, bone) in ((0, 0, 0), (1, 0, 0), (3, 1, 0), (1, 2, 1), (2, 1, 1), (4, 2, 1)):
		m = kit.mat("bone", -0.05) if bone else CU("b")
		x, y = -0.19 + i * 0.055, -0.09 + j * 0.05
		kit.cylinder(0.008, 0.05, (x, y, zt + 0.032), m, verts=8, bevel=0.002)
		sphere((x, y, zt + 0.058), 0.012, m, seg=8, rings=5)
	for k, (x, y) in enumerate(((0.12, -0.1), (0.15, -0.03), (0.11, 0.03))):  # pegs already taken
		m = kit.mat("bone", -0.05) if k else CU("b")
		kit.cylinder(0.008, 0.05, (x, y, zt + 0.008), m, rot=(0, 90, 40 * k), verts=8, bevel=0.002)
	mug(0.2, 0.17, zt, m=CU("b"))
	group(lambda: mug(0, 0, 0), at=(-0.24, 0.17, zt + 0.045), rot=(90, 0, 120))  # knocked over
	kit.cylinder(0.11, 0.003, (-0.3, 0.06, zt + 0.0025), C((0.22, 0.14, 0.08), 0.25), verts=12, bevel=0)  # dried spill
	lay(stool_logs, (0.8, -0.05), (0, 76, 0))  # the stool, knocked onto its side
	lay(lambda: lantern((0, 0, 0)), (-0.5, -0.4), (0, 90, 30))  # the lantern on the floor
	kit.cylinder(0.02, 0.05, (-0.38, -0.55, 0.02), WAX(), rot=(0, 90, 20), verts=8, bevel=0.004)  # its candle rolled out


def mg_barricade():
	W, H = 1.5, 1.35
	hlog((-W / 2 - 0.05, 0.05, 0.075), (W / 2 + 0.05, 0.05, 0.075), 0.075, bend=0.02)  # sill log
	for s_ in (-1, 1):
		hlog((s_ * (W / 2 - 0.05), 0.05, 0.12), (s_ * (W / 2 - 0.05), 0.05, H), 0.07, bend=0.02)
	hlog((-W / 2 - 0.08, 0.05, H - 0.02), (W / 2 + 0.08, 0.05, H - 0.02), 0.065, bend=0.02)
	for i, (z, ang) in enumerate(((0.32, 4), (0.62, -3), (0.9, 6), (1.16, -2))):
		L = W + 0.05 - (0.25 if i == 3 else 0)
		bx = 0.0 if i != 3 else -0.125
		board((L, 0.035, 0.17), (bx, -0.035, z), rot=(0, ang, 0))
		for s_ in (-1, 1):
			x = bx + s_ * (L / 2 - 0.1)
			if i == 3 and s_ > 0:
				continue
			zz = z - (x - bx) * math.sin(math.radians(ang))
			for dz in (-0.04, 0.04):
				nail(x, -0.053, zz + dz)
	# the last board: torn half off, hanging down from one nail
	group(lambda: board((0.6, 0.035, 0.16), (0.3, 0, 0)), at=(0.66, -0.035, 1.17), rot=(0, 38, 0))
	nail(0.69, -0.053, 1.15)
	# a diagonal brace log jammed in front, its foot against a wedge stone
	hlog((0.1, -0.09, 1.0), (0.35, -0.85, 0.06), 0.06, bend=0.02)
	B((0.2, 0.16, 0.12), (0.42, -0.98, 0.06), STONE(), bevel=0.03, rot=(0, 0, 12))
	B((0.16, 0.08, 0.06), (0.4, -0.86, 0.03), PL(), bevel=0.006, rot=(0, 0, 30))  # wooden wedge
	hammer(-0.3, -0.45, 20)
	for k, (x, y) in enumerate(((-0.05, -0.55), (0.0, -0.42), (-0.12, -0.62), (0.07, -0.6))):
		rod((x, y, 0.006), (x + 0.06 * math.cos(k * 1.3), y + 0.06 * math.sin(k * 1.3), 0.006), 0.005, IRON("dark"), seg=5)
		kit.cylinder(0.009, 0.005, (x, y, 0.009), IRON("dark"), rot=(0, 90, math.degrees(k * 1.3)), verts=8, bevel=0.001)


def mg_gate_bar_snapped():
	S = 0.15
	a0, a1 = Vector((-1.0, 0.0, S / 2)), Vector((0.15, 0.08, S / 2))
	beam(tuple(a0), tuple(a1), S, S, PL(), bevel=0.012)
	splinters((0.135, 0.079, S / 2), (1, 0.07, 0), n=5, r=0.06)
	beam((0.32, -0.15, S / 2), (0.95, -0.55, S / 2), S, S, PL(), bevel=0.012)  # the short half, kicked aside
	splinters((0.337, -0.161, S / 2), (-1, 0.6, 0), n=5, r=0.06)
	rz = math.degrees(math.atan2(a1.y - a0.y, a1.x - a0.x))
	for f in (0.12, 0.7):  # iron bands on the bar
		group(lambda: (B((0.05, S + 0.014, S + 0.004), (0, 0, 0.005), IRON("dark"), bevel=0.003),
			[rivet((0, -S / 2 - 0.007, dz), CU("dark"), r=0.01) for dz in (-0.035, 0.045)]), at=tuple(a0.lerp(a1, f)), rot=(0, 0, rz))
	# the iron bracket still around the bar, torn out of the wall with its spikes
	def bracket():
		for s_ in (-1, 1):
			B((0.07, 0.02, S), (0, s_ * (S / 2 + 0.01), 0.01), IRON("a"), bevel=0.004)
			B((0.07, 0.07, 0.016), (0, s_ * (S / 2 + 0.05), -S / 2 + 0.017), IRON("a"), bevel=0.004)
			rod((0.0, s_ * (S / 2 + 0.06), -S / 2 + 0.02), (0.01, s_ * (S / 2 + 0.07), -S / 2 + 0.11), 0.006, IRON("dark"))
		B((0.07, S + 0.06, 0.02), (0, 0, S / 2 + 0.01), IRON("a"), bevel=0.004)
	group(bracket, at=tuple(a0.lerp(a1, 0.4)), rot=(0, 0, rz))
	# the other bracket lies loose on the floor, bent open
	bx, by = 0.0, 0.42
	B((0.25, 0.07, 0.02), (bx, by, 0.01), IRON("a"), bevel=0.004, rot=(0, 0, 15))
	beam((bx + 0.11, by + 0.03, 0.01), (bx + 0.18, by + 0.08, 0.13), 0.07, 0.02, IRON("a"), bevel=0.004)
	for k in range(3):
		rod((bx - 0.07 + 0.05 * k, by - 0.015 + 0.013 * k, 0.015), (bx - 0.06 + 0.05 * k, by - 0.025 + 0.013 * k, 0.1), 0.006, IRON("dark"))
	for k in range(3):  # wood chips from the break
		kit.gem((0.24 + 0.07 * k, 0.15 - 0.09 * k, 0.01), (0.03, 0.015, 0.01), END(), seed=k + 3)


def mg_crate_pried_open():
	w, d, h = 0.7, 0.5, 0.45
	crate(w, d, h, (0, 0, 0), lid=False)
	B((w - 0.075, d - 0.06, 0.006), (0, 0, 0.038), INK(), bevel=0)  # empty, dark bottom
	B((w - 0.075, d / 3 - 0.008, 0.025), (0, d / 3, h - 0.02), PL(), bevel=0.006)  # one lid board still nailed down
	for x in (-w / 2 + 0.05, w / 2 - 0.05):
		nail(x, d / 3, h - 0.0075, face="+z")
	# one board pried up: its left end still nailed, the crowbar wedged under its right end
	ang = -12
	group(lambda: (B((w - 0.075, d / 3 - 0.008, 0.025), (0, 0, 0), PL(), bevel=0.006),
		rod((-w / 2 + 0.08, 0.0, -0.01), (-w / 2 + 0.08, 0.0, -0.07), 0.005, IRON("dark"))),
		at=(0.0, 0.0, h - 0.02 + 0.3125 * math.sin(math.radians(-ang))), rot=(0, ang, 0))
	crowbar((0.27, -0.01, h + 0.075), (0.6, -0.12, h - 0.28))
	# the front board on the floor, bent nails sticking up
	group(lambda: (B((w - 0.075, d / 3 - 0.008, 0.025), (0, 0, 0.0125), PL(), bevel=0.006),
		[rod((x, 0.0, 0.02), (x + 0.012, 0.006, 0.075), 0.005, IRON("dark")) for x in (-0.27, 0.27)]),
		at=(-0.2, -0.55, 0.0), rot=(0, 0, 14))
	for k in range(4):
		kit.gem((-0.6 + 0.06 * k, -0.25 + 0.04 * (k % 2), 0.008), (0.02, 0.012, 0.008), END(), seed=k + 11)


def mg_sawhorse_left():
	L, H = 1.0, 0.62
	for x in (-L / 2 + 0.12, L / 2 - 0.12):
		for s_ in (-1, 1):
			hlog((x + s_ * 0.02, s_ * 0.24, 0.0), (x - s_ * 0.02, -s_ * 0.04, H + 0.02), 0.04, seg=7)
		hlog((x, -0.17, 0.2), (x, 0.17, 0.2), 0.025, seg=6)
		for k in (-1, 0, 1):
			kit.ring(0.058, 0.011, (x + k * 0.025, 0.0, H - 0.03), ROPE(), rot=(0, 90, 0), seg=12)
	hlog((-L / 2, 0.0, H - 0.03), (L / 2, 0.0, H - 0.03), 0.05, bend=0.02)
	# the log being cut, lying across the sawhorse, with the half-finished cut
	zl = H + 0.11
	lg = hlog((-0.75, 0.0, zl), (0.55, 0.0, zl), 0.13, seg=12, rings=2, bend=0.0)
	carve(lg, (0.008, 0.4, 0.17), (0.2, 0.0, zl + 0.09))
	# the frame saw left standing in the cut
	sx = 0.2
	B((0.003, 0.5, 0.05), (sx, -0.02, zl + 0.04), IRON("a"), bevel=0.0005)
	for y in (-0.29, 0.25):
		B((0.03, 0.03, 0.44), (sx, y, zl + 0.24), PL(), bevel=0.005)
	B((0.028, 0.56, 0.028), (sx, -0.02, zl + 0.26), PL(), bevel=0.005)
	rod((sx, -0.29, zl + 0.43), (sx, 0.25, zl + 0.43), 0.007, ROPE(), seg=5)
	B((0.012, 0.012, 0.11), (sx, -0.02, zl + 0.37), DK(), bevel=0.002, rot=(25, 0, 0))  # rope twist stick
	rod((sx, 0.25, zl + 0.03), (sx, 0.25, zl - 0.1), 0.016, DK())  # handle
	# the offcut on the floor, a chopping log with a hand axe in it
	hlog((0.7, -0.35, 0.12), (0.82, -0.5, 0.12), 0.12, seg=12, rings=1, bend=0.0)
	hlog((-0.85, -0.4, 0.0), (-0.85, -0.4, 0.35), 0.11, seg=10, rings=1, bend=0.0)
	group(lambda: (B((0.035, 0.035, 0.34), (0, 0, 0.17), PL(), bevel=0.006), B((0.14, 0.03, 0.07), (0.03, 0, 0.0), IRON("a"), bevel=0.004)),
		at=(-0.85, -0.4, 0.36), rot=(0, 30, 25))
	for k in range(4):
		kit.gem((0.15 + 0.06 * k, -0.25 - 0.03 * (k % 2), 0.008), (0.02, 0.015, 0.008), END(), seed=k + 21)


def mg_strongbox_forced():
	w, d, h = 0.6, 0.4, 0.32
	strongbox_body(w, d, h)
	lp = B((0.1, 0.014, 0.12), (0, -d / 2 - 0.006, h - 0.07), IRON("a"), bevel=0.003)  # lock plate
	carve(lp, (0.012, 0.05, 0.035), (0, -d / 2 - 0.01, h - 0.075))  # keyhole cut through
	B((0.04, 0.012, 0.05), (0.0, -d / 2 - 0.016, h - 0.005), IRON("dark"), bevel=0.003, rot=(0, 25, 0))  # the bent hasp
	for x in (-0.17, 0.17):  # torn hinge stubs at the back
		beam((x, d / 2 + 0.004, h - 0.05), (x + 0.02, d / 2 + 0.06, h + 0.05), 0.04, 0.008, IRON("dark"), bevel=0.002)
	def lid():  # the torn-off lid, lying beside it
		B((w + 0.02, d + 0.02, 0.05), (0, 0, 0.025), PL(), bevel=0.008)
		for x in (-w / 2 + 0.08, w / 2 - 0.08):
			B((0.05, d + 0.034, 0.012), (x, 0, 0.052), IRON("dark"), bevel=0.003)
			rivet((x, 0, 0.058), CU("dark"), r=0.01)
		for x in (-0.17, 0.17):
			beam((x, d / 2 + 0.01, 0.025), (x - 0.03, d / 2 + 0.09, 0.07), 0.04, 0.008, IRON("dark"), bevel=0.002)
	group(lid, at=(0.15, -0.7, 0.0), rot=(0, 0, 20))
	px, py = -0.5, -0.3  # the padlock, sawn open
	B((0.08, 0.04, 0.09), (px, py, 0.02), IRON("a"), bevel=0.008, rot=(90, 0, 30))
	kit.ring(0.03, 0.008, (px + 0.04, py - 0.02, 0.02), IRON("dark"), rot=(0, 0, 30), seg=12)
	crowbar((-w / 2 - 0.3, 0.05, 0.012), (-w / 2 + 0.035, -0.1, h + 0.04))


def spear(p0, p1, r=0.016):
	"""A spear from butt p0 to tip p1: shaft, iron butt cap, socket, flat leaf blade."""
	p0, p1 = Vector(p0), Vector(p1)
	d = (p1 - p0).normalized()
	rod(tuple(p0), tuple(p1 - d * 0.14), r, PL(), seg=7)
	rod(tuple(p0 - d * 0.005), tuple(p0 + d * 0.05), r + 0.003, IRON("dark"))
	rod(tuple(p1 - d * 0.22), tuple(p1 - d * 0.13), r + 0.004, IRON("dark"))
	o = kit.cone(0.032, 0.0, 0.16, (0, 0, 0), IRON("a"), verts=4, bevel=0)
	o.scale = (1, 0.3, 1)
	bpy.ops.object.transform_apply(scale=True)
	o.matrix_world = Matrix.Translation(p1 - d * 0.07) @ d.to_track_quat("Z", "Y").to_matrix().to_4x4()


def mg_spear_rack_fallen():
	"""The spear rack lies on its back; two spears still in it, three spilled across the floor."""
	before = set(bpy.data.objects)
	W = 1.2
	hlog((-W / 2, 0.0, 0.05), (W / 2, 0.0, 0.05), 0.05, bend=0.02)  # base sill
	for s_ in (-1, 1):
		hlog((s_ * (W / 2 - 0.08), 0.0, 0.08), (s_ * (W / 2 - 0.08), 0.0, 1.05), 0.045, bend=0.02)
		hlog((s_ * (W / 2 - 0.08), -0.32, 0.03), (s_ * (W / 2 - 0.08), 0.0, 0.3), 0.035, seg=6)  # foot struts
	rail = B((W, 0.08, 0.06), (0, -0.02, 0.85), PL(), bevel=0.01)
	for k in range(5):
		carve(rail, (0.05, 0.08, 0.08), (-0.4 + k * 0.2, -0.06, 0.85))  # notches the spears sat in
	B((W - 0.04, 0.12, 0.04), (0, -0.04, 0.12), DK(), bevel=0.006)  # butt tray
	for k in (1, 3):
		x = -0.4 + k * 0.2
		spear((x, -0.04, 0.14), (x + 0.02, -0.05, 1.75))
	rack = new_since(before)
	turn(rack, "X", -84, (0, 0.06, 0.0))
	bpy.context.view_layer.update()
	dz = low_z(rack)
	for o in rack:
		o.location.z -= dz
	spear((-0.7, -0.5, 0.016), (0.9, -0.65, 0.016))
	spear((0.2, -0.95, 0.016), (1.5, -0.85, 0.016))
	spear((-0.9, -1.15, 0.016), (0.4, -1.3, 0.016))


def mg_collapsed_shelf():
	"""A storeroom shelf whose right leg snapped: shelves slant down, crates and a keg slid onto the floor."""
	W, D = 1.3, 0.42
	xl, xr = -W / 2 + 0.04, W / 2 - 0.04
	for y in (-D / 2 + 0.04, D / 2 - 0.04):
		hlog((xl, y, 0.0), (xl, y, 1.5), 0.04, bend=0.02)
	hlog((xr, D / 2 - 0.04, 0.0), (xr, D / 2 - 0.04, 0.55), 0.04, bend=0.02)  # back right leg, snapped
	splinters((xr, D / 2 - 0.04, 0.55), (0, 0, 1), n=4, r=0.04)
	hlog((xr, -D / 2 + 0.04, 0.0), (xr, -D / 2 + 0.04, 0.2), 0.04, bend=0.02)  # front right leg stump
	splinters((xr, -D / 2 + 0.04, 0.2), (0, 0, 1), n=4, r=0.04)
	hlog((xr + 0.15, -D / 2 - 0.25, 0.04), (xr + 0.6, -D / 2 - 0.42, 0.04), 0.04, bend=0.02)  # the broken leg piece
	splinters((xr + 0.15, -D / 2 - 0.25, 0.04), (-1, 0.38, 0), n=3, r=0.04)
	for y in (-D / 2 + 0.04, D / 2 - 0.04):
		hlog((xl, y, 0.15), (xr, y, 0.15), 0.025, seg=6)  # lowest rail, still whole
	# shelves: still pegged to the left legs, right ends dropped onto the shelf below
	t, Lb, x0 = 0.032, W - 0.04, xl - 0.03
	prev = None
	for zl in (0.2, 0.62, 1.04, 1.42):
		th = 0.0
		if prev:
			for _ in range(25):
				xe = x0 + Lb * math.cos(th)
				th = math.asin(min(0.9, (zl - (prev(xe) + t / 2)) / Lb))
		cx, cz = x0 + Lb / 2 * math.cos(th), zl - Lb / 2 * math.sin(th)
		group(lambda: [board((Lb, D / 3 - 0.01, t), (0, -D / 2 + D / 3 * (i + 0.5), 0)) for i in range(3)], at=(cx, 0, cz), rot=(0, math.degrees(th), 0))
		for y in (-D / 2 + 0.04, D / 2 - 0.04):
			peg(xl + 0.04, y - 0.0, zl + t / 2 - 0.01, face="+z", r=0.009)
		prev = (lambda x, zl=zl, th=th: zl - (x - x0) * math.tan(th) + t / 2)
	crate(0.26, 0.26, 0.2, (-0.42, 0.0, 0.2 + t / 2), rope=True)  # left on the low shelf
	crate(0.4, 0.34, 0.3, (0.95, -0.3, 0.0), rope=True)  # slid onto the floor
	group(lambda: crate(0.36, 0.3, 0.26, (0, 0, 0)), at=(1.0, 0.25, 0.0), rot=(0, 0, 25))
	keg_lying(0.72, -0.8, 0.0, r=0.13, h=0.32)


# ================= Furniture and props =================
def mg_gatekeeper_chair():
	W, D, Hs = 0.62, 0.55, 0.44
	for x in (-W / 2 + 0.05, W / 2 - 0.05):
		hlog((x, -D / 2 + 0.05, 0.0), (x, -D / 2 + 0.05, 0.72), 0.045, bend=0.02)  # front posts carry the arms
		hlog((x, D / 2 - 0.05, 0.0), (x, D / 2 - 0.02, 1.32), 0.05, bend=0.02)  # tall back posts
		sphere((x, D / 2 - 0.02, 1.34), 0.055, DK(), seg=10, rings=7)  # knob tops
		kit.ring(0.05, 0.01, (x, D / 2 - 0.02, 1.3), IRON("dark"), seg=12)
		hlog((x, -D / 2 - 0.02, 0.72), (x, D / 2 - 0.03, 0.74), 0.035, seg=7)  # arm rests
		peg(x, -D / 2 + 0.05, 0.75, face="+z", r=0.012)
		hlog((x, -D / 2 + 0.05, 0.16), (x, D / 2 - 0.05, 0.16), 0.028, seg=6)  # side stretchers
	hlog((-W / 2 + 0.05, -D / 2 + 0.05, 0.12), (W / 2 - 0.05, -D / 2 + 0.05, 0.12), 0.028, seg=6)
	for i in range(4):
		board((W + 0.04, D / 4 - 0.008, 0.04), (0, -D / 2 + D / 4 * (i + 0.5), Hs))
	for x in (-W / 2 + 0.05, W / 2 - 0.05):
		for y in (-D / 2 + 0.07, D / 2 - 0.07):
			nail(x, y, Hs + 0.02, face="+z")
	# back: three split boards between two cross rails, iron studs along the top rail
	yb = D / 2 - 0.03
	for z in (0.62, 1.2):
		hlog((-W / 2 + 0.02, yb, z), (W / 2 - 0.02, yb, z), 0.04, seg=7, bend=0.0)
	for k in range(3):
		B((0.15, 0.03, 0.7), (-0.17 + k * 0.17, yb + 0.005, 0.91), PL(), bevel=0.008)
	for k in range(5):
		rivet((-0.24 + k * 0.12, yb - 0.04, 1.2), IRON("a"), r=0.014)
	for s_ in (-1, 1):
		B((0.09, 0.012, 0.09), (s_ * 0.2, yb - 0.014, 0.74), IRON("dark"), bevel=0.003, rot=(0, 45, 0))
	B((0.18, 0.012, 0.08), (0, yb - 0.014, 1.0), CU("b"), bevel=0.003)
	for x in (-0.07, 0.07):
		rivet((x, yb - 0.02, 1.0), CU("dark"), r=0.008)


def mg_gatekeeper_desk():
	W, D = 0.95, 0.6
	for x in (-W / 2 + 0.06, W / 2 - 0.06):
		hlog((x, -D / 2 + 0.06, 0.0), (x, -D / 2 + 0.06, 0.7), 0.042, seg=7)  # front legs
		hlog((x, D / 2 - 0.06, 0.0), (x, D / 2 - 0.06, 1.0), 0.042, seg=7)  # back legs carry the top shelf
		hlog((x, -D / 2 + 0.06, 0.18), (x, D / 2 - 0.06, 0.18), 0.028, seg=6)
	top_boards(W + 0.04, D, 0.25, t=0.035, n=4)  # low shelf
	for k in range(3):
		book(-0.35 + k * 0.045, 0.0, 0.2675, 0.04, 0.24, 0.22 - 0.02 * k, LEATHER() if k % 2 else LEATHER2())
	for row, nn in enumerate((3, 2)):
		for k in range(nn):
			scroll(0.15 - (nn - 1) * 0.024 + k * 0.048, 0.0, 0.2675 + row * 0.04, 0.4)
	# slanted writing top with an open ledger
	def top():
		for i in range(4):
			board((W + 0.06, 0.48 / 4 - 0.006, 0.04), (0, -0.24 + 0.12 * (i + 0.5), 0))
		B((W - 0.06, 0.03, 0.04), (0, -0.25, 0.035), DK(), bevel=0.005)  # lip so nothing slides off
		for s_ in (-1, 1):
			B((0.24, 0.32, 0.012), (s_ * 0.12, -0.02, 0.026), LEATHER(), bevel=0.003)
			B((0.22, 0.3, 0.026), (s_ * 0.112, -0.02, 0.044), PAPER(), bevel=0.003)
			for k in range(7 if s_ < 0 else 4):  # lines of ink on the pages
				B((0.16 if k != 6 else 0.08, 0.006, 0.002), (s_ * 0.115 - (0.04 if k == 6 else 0), 0.1 - k * 0.035, 0.0585), INK(), bevel=0)
		B((0.012, 0.3, 0.02), (0, -0.02, 0.045), LEATHER(), bevel=0.003)
	group(top, at=(0, -0.06, 0.745), rot=(10, 0, 0))
	# flat strip at the back: inkpot, quill, candle stub, seal, cash box
	board((W + 0.06, 0.14, 0.035), (0, 0.25, 0.8))
	zt, yt = 0.8175, 0.25
	kit.cylinder(0.035, 0.05, (-0.3, yt, zt + 0.025), CU("dark"), verts=10, bevel=0.006)
	kit.cylinder(0.014, 0.01, (-0.3, yt, zt + 0.051), INK(), verts=8, bevel=0.0)
	rod((-0.3, yt, zt + 0.04), (-0.24, yt - 0.03, zt + 0.22), 0.004, QUILL(), seg=5)
	kit.cone(0.02, 0.004, 0.12, (-0.253, yt - 0.023, zt + 0.18), QUILL(), rot=(-8, 18, 0), verts=4, bevel=0)
	kit.cylinder(0.05, 0.012, (-0.12, yt, zt + 0.006), CU("b"), verts=12, bevel=0.003)
	kit.cylinder(0.025, 0.04, (-0.12, yt, zt + 0.032), WAX(), verts=10, bevel=0.005)  # burnt-down candle
	kit.gem((-0.095, yt - 0.01, zt + 0.02), (0.012, 0.012, 0.018), WAX(), seed=4)
	B((0.006, 0.006, 0.015), (-0.12, yt, zt + 0.058), CHAR(), bevel=0)
	B((0.24, 0.12, 0.13), (0.24, yt, zt + 0.065), PL(), bevel=0.01)  # cash box
	for x in (0.17, 0.31):
		B((0.03, 0.132, 0.142), (x, yt, zt + 0.066), IRON("dark"), bevel=0.003)
	B((0.05, 0.012, 0.06), (0.24, yt - 0.064, zt + 0.08), IRON("a"), bevel=0.003)
	kit.cylinder(0.018, 0.06, (0.02, yt, zt + 0.03), CU("b"), verts=8, bevel=0.004)  # seal stamp
	sphere((0.02, yt, zt + 0.07), 0.022, PL(), seg=10, rings=6)
	# top shelf across the back legs, scrolls on it
	board((W + 0.06, 0.14, 0.035), (0, 0.25, 1.0))
	for k in range(5):
		scroll(-0.32 + k * 0.05, 0.25, 1.0175, 0.12)


def mg_armour_stand():
	"""A short log armour stand (dwarf height): an iron cuirass that goes all the way round the post, front and back
	ridges, leather shoulder straps and side buckles, riveted bands, shoulder guards, a helmet; a shield beside it."""
	hlog((-0.3, 0.0, 0.05), (0.3, 0.0, 0.05), 0.05, bend=0.0)
	hlog((0.0, -0.3, 0.1), (0.0, 0.3, 0.1), 0.05, bend=0.0)
	hlog((0.0, 0.0, 0.14), (0.0, 0.0, 1.0), 0.045, bend=0.01)
	for a in (0, 90, 180, 270):
		r = math.radians(a)
		beam((math.cos(r) * 0.22, math.sin(r) * 0.22, 0.1 + 0.04 * (a % 180 != 0)), (math.cos(r) * 0.03, math.sin(r) * 0.03, 0.36), 0.03, 0.03, DK())
	hlog((-0.25, 0.0, 0.85), (0.25, 0.0, 0.85), 0.04, seg=7, bend=0.0)  # shoulder bar
	# the cuirass: a full iron shell round the post, narrow at the waist, full at the chest
	body = ((0.47, 0.15, 0.125), (0.53, 0.145, 0.12), (0.64, 0.178, 0.148), (0.74, 0.188, 0.155), (0.81, 0.168, 0.14), (0.85, 0.118, 0.1))
	loft([(z, rx, ry, 0.0) for z, rx, ry in body], IRON("a"), flat=1.0)
	loft([(z, rx + 0.01, ry + 0.01, 0.0) for z, rx, ry in ((0.465, 0.15, 0.125), (0.495, 0.148, 0.123))], IRON("dark"), flat=1.0)  # bottom band
	loft([(z, rx + 0.008, ry + 0.008, 0.0) for z, rx, ry in ((0.825, 0.161, 0.134), (0.855, 0.112, 0.095))], IRON("dark"), flat=1.0)  # neck band
	loft([(z, rx + 0.012, ry + 0.012, 0.0) for z, rx, ry in ((0.52, 0.146, 0.121), (0.56, 0.149, 0.124))], LEATHER(), flat=1.0)  # belt
	B((0.05, 0.02, 0.05), (0, -0.14, 0.54), CU("b"), bevel=0.004)
	kit.ring(0.017, 0.005, (0, -0.151, 0.54), CU("dark"), rot=(90, 0, 0), seg=10)
	for sy in (-1, 1):  # centre ridges, front and back
		for p0, p1 in (((0, sy * 0.132, 0.57), (0, sy * 0.158, 0.69)), ((0, sy * 0.158, 0.69), (0, sy * 0.148, 0.8))):
			beam(p0, p1, 0.014, 0.012, IRON("dark"), bevel=0.003)
	for k in range(16):  # rivets all round the neck band and the bottom band
		a = 2 * math.pi * k / 16 + 0.1
		rivet((math.cos(a) * 0.168, math.sin(a) * 0.142, 0.83), CU("dark"), r=0.009)
		rivet((math.cos(a) * 0.161, math.sin(a) * 0.136, 0.48), CU("dark"), r=0.008)
	for sx in (-1, 1):
		tube([(sx * 0.1, -0.135, 0.8), (sx * 0.1, -0.09, 0.855), (sx * 0.1, 0.0, 0.875), (sx * 0.1, 0.09, 0.855), (sx * 0.1, 0.135, 0.8)],
			0.011, 0.011, LEATHER2(), seg=6)  # shoulder strap over the top, front to back
		B((0.03, 0.06, 0.04), (sx * 0.19, 0.0, 0.68), LEATHER2(), bevel=0.005)  # side strap and buckle joining front and back
		B((0.012, 0.03, 0.03), (sx * 0.204, 0.0, 0.68), CU("b"), bevel=0.003)
	for s_ in (-1, 1):  # shoulder guards: a dome and two overlapping lames
		smooth(sphere((s_ * 0.21, 0.0, 0.855), 0.095, IRON("b"), scale=(1.15, 1.0, 0.6), cut=-0.02, seg=16, rings=8))
		for k in range(2):
			o = kit.ring(0.095 - 0.012 * k, 0.009, (s_ * 0.21, 0.0, 0.85 + 0.022 * k), IRON("dark"), seg=18)
			o.scale = (1.15, 1.0, 1)
	helmet(0, 0.0, 0.99, s=1.0)
	group(lambda: shield(0, 0.24, 0.0, 0.24), at=(-0.5, -0.62, 0.0), rot=(-90, 0, 0))  # a shield dropped beside it


def mg_alarm_bell():
	W, H = 0.9, 1.75
	for s_ in (-1, 1):
		hlog((s_ * W / 2, -0.32, 0.05), (s_ * W / 2, 0.32, 0.05), 0.05, bend=0.0)  # feet
		hlog((s_ * W / 2, 0.0, 0.09), (s_ * W / 2, 0.0, H), 0.055, bend=0.02)
		for t in (-1, 1):
			beam((s_ * W / 2, t * 0.26, 0.09), (s_ * W / 2, t * 0.035, 0.5), 0.035, 0.035, DK())
		beam((s_ * W / 2, 0.0, H - 0.35), (s_ * (W / 2 - 0.22), 0.0, H - 0.03), 0.035, 0.035, DK())  # knee braces
	hlog((-W / 2 - 0.1, 0.0, H + 0.02), (W / 2 + 0.1, 0.0, H + 0.02), 0.06, bend=0.0)
	for s_ in (-1, 1):  # iron hanger straps
		B((0.012, 0.05, 0.14), (s_ * 0.065, 0.0, H - 0.07), IRON("dark"), bevel=0.003)
		rivet((s_ * 0.072, 0.0, H - 0.03), CU("dark"), r=0.01)
	B((0.16, 0.064, 0.03), (0, 0.0, H - 0.14), IRON("dark"), bevel=0.003)
	bz = H - 0.44
	kit.cone(0.2, 0.11, 0.25, (0, 0, bz + 0.125), CU("b"), verts=20, bevel=0.01)
	sphere((0, 0, bz + 0.25), 0.11, CU("b"), scale=(1, 1, 0.6), cut=0.0, seg=16, rings=8)
	kit.ring(0.2, 0.018, (0, 0, bz + 0.012), CU("dark"), seg=24)
	kit.ring(0.13, 0.01, (0, 0, bz + 0.205), CU("dark"), seg=18)
	kit.cylinder(0.17, 0.004, (0, 0, bz - 0.003), INK(), verts=20, bevel=0)  # dark mouth
	rod((0, 0, bz + 0.05), (0, 0, bz - 0.06), 0.008, IRON("dark"))  # clapper
	sphere((0, 0, bz - 0.065), 0.03, IRON("a"), seg=10, rings=6)
	kit.ring(0.015, 0.005, (0, 0, bz - 0.1), IRON("dark"), rot=(90, 0, 0), seg=8)
	# pull rope from the clapper down to a cleat on the left post
	rod((0, 0, bz - 0.11), (-W / 2 + 0.07, -0.045, 0.78), 0.011, ROPE(), seg=6)
	B((0.04, 0.03, 0.16), (-W / 2 + 0.055, -0.045, 0.72), DK(), bevel=0.006)
	for z in (0.68, 0.75):
		kit.ring(0.035, 0.01, (-W / 2 + 0.055, -0.045, z), ROPE(), rot=(0, 90, 0), seg=10).scale = (1, 0.8, 0.5)
	rod((-W / 2 + 0.07, -0.07, 0.67), (-W / 2 + 0.12, -0.1, 0.42), 0.011, ROPE(), seg=6)


def round_lid(R, z, m, gap=0.006, n=4):
	"""A round plank lid at height z: n planks cut to the circle, two cross battens, nails."""
	circle = [(math.cos(2 * math.pi * k / 40) * R, math.sin(2 * math.pi * k / 40) * R) for k in range(40)]
	w = 2 * R / n
	for i in range(n):
		x0, x1 = -R + i * w + gap / 2, -R + (i + 1) * w - gap / 2
		poly = circle
		for lim, keep in ((x0, lambda p: p[0] >= x0), (x1, lambda p: p[0] <= x1)):  # clip the circle to this plank
			out = []
			for a, b in zip(poly, poly[1:] + poly[:1]):
				if keep(a):
					out.append(a)
				if keep(a) != keep(b):
					t = (lim - a[0]) / (b[0] - a[0])
					out.append((lim, a[1] + (b[1] - a[1]) * t))
			poly = out
		prism(poly, z, z + 0.028, PL() if i % 2 else DK(), axis="z")
	for y in (-R * 0.45, R * 0.45):
		hw = math.sqrt(R * R - y * y) - 0.03
		B((hw * 2, 0.06, 0.03), (0, y, z + 0.04), DK(), bevel=0.006)
		for x in (-hw + 0.05, 0.0, hw - 0.05):
			nail(x, y, z + 0.056, face="+z")


def mg_water_butt():
	r, h, z0 = 0.3, 0.85, 0.1
	for y in (-0.16, 0.16):
		hlog((-0.38, y, 0.06), (0.38, y, 0.06), 0.06, bend=0.0)
	group(lambda: barrel(r, h, n=14, bulge=1.08, lid=False), at=(0, 0, z0))
	round_lid(r + 0.012, z0 + h - 0.004, PL())  # closed with a round plank lid that matches the barrel (owner Nov 22)
	kit.cylinder(0.02, 0.04, (0.0, -r * 1.06 - 0.012, z0 + 0.15), DK(), rot=(90, 0, 0), verts=8, bevel=0.003)  # bung


def mg_supply_shelf():
	W, D, H = 1.15, 0.42, 1.55
	for x in (-W / 2 + 0.04, W / 2 - 0.04):
		for y in (-D / 2 + 0.04, D / 2 - 0.04):
			hlog((x, y, 0.0), (x, y, H), 0.04, bend=0.015)
	for s_, dy in ((1, 0.0), (-1, 0.012)):  # crossed back braces
		beam((-s_ * (W / 2 - 0.04), D / 2 - 0.02 - dy, 0.1), (s_ * (W / 2 - 0.04), D / 2 - 0.02 - dy, H - 0.15), 0.035, 0.022, DK())
	zs = (0.12, 0.5, 0.88, 1.24, H - 0.02)
	for z in zs:
		for i in range(3):
			board((W + 0.04, D / 3 - 0.008, 0.032), (0, -D / 2 + D / 3 * (i + 0.5), z))
		for x in (-W / 2 + 0.04, W / 2 - 0.04):
			for y in (-D / 2 + 0.04, D / 2 - 0.04):
				peg(x, y, z + 0.016, face="+z", r=0.009)
	t = [z + 0.016 for z in zs]
	for k in range(3):  # bottom: kegs on their sides, on little cradles
		x = -0.36 + k * 0.36
		for cx in (x - 0.08, x + 0.08):
			B((0.03, 0.2, 0.03), (cx, 0.0, t[0] + 0.012), DK(), bevel=0.004)
		keg_lying(x, 0.0, t[0] + 0.004, r=0.12, h=0.3)
	crate(0.34, 0.32, 0.28, (-0.35, 0.0, t[1]), rope=True)  # second: crates
	crate(0.34, 0.32, 0.28, (0.05, 0.0, t[1]), rope=True)
	crate(0.2, 0.22, 0.18, (0.38, 0.0, t[1]))
	for k in range(3):  # third: copper pots
		x, rr = -0.38 + k * 0.38, 0.12 - 0.02 * k
		kit.cylinder(rr, 0.16, (x, 0.0, t[2] + 0.08), CU("b"), verts=16, bevel=0.008)
		kit.ring(rr, 0.01, (x, 0.0, t[2] + 0.16), CU("dark"), seg=18)
		kit.cylinder(rr * 0.82, 0.004, (x, 0.0, t[2] + 0.163), INK(), verts=14, bevel=0)
		for s_ in (-1, 1):
			kit.ring(0.025, 0.007, (x + s_ * (rr + 0.005), 0.0, t[2] + 0.13), IRON("dark"), rot=(90, 0, 0), seg=8)
	for x in (-0.33, 0.33):  # fourth: rope coils lying flat, a lantern between them
		for j in range(3):
			kit.ring(0.12 - 0.006 * j, 0.017, (x, 0.0, t[3] + 0.017 + j * 0.03), ROPE(), seg=20)
	lantern((0.0, 0.0, t[3]))


def mg_wheelbarrow():
	def body():
		for i in range(4):  # tray bottom and flared sides
			board((0.12 - 0.006, 0.7, 0.025), (-0.18 + i * 0.12, 0.0, 0.0))
		for s_ in (-1, 1):
			board((0.025, 0.72, 0.22), (s_ * 0.26, 0.0, 0.1), rot=(0, s_ * 15, 0))
			board((0.48, 0.025, 0.2), (0.0, s_ * 0.36, 0.09), rot=(-s_ * 15, 0, 0))
			for y in (-0.3, 0.3):
				B((0.015, 0.06, 0.24), (s_ * 0.276, y, 0.1), IRON("dark"), bevel=0.003, rot=(0, s_ * 15, 0))
		for s_ in (-1, 1):  # handles: hewn poles under the tray, out the back; two legs
			hlog((s_ * 0.2, -0.55, -0.04), (s_ * 0.25, 1.05, -0.04), 0.035, seg=7, bend=0.0)
			sphere((s_ * 0.25, 1.06, -0.04), 0.04, DK(), seg=10, rings=6)
			hlog((s_ * 0.24, 0.55, -0.05), (s_ * 0.25, 0.6, -0.52), 0.032, seg=6)
		hlog((-0.28, 0.577, -0.3), (0.28, 0.577, -0.3), 0.022, seg=6)
	group(body, at=(0, 0, 0.42), rot=(9, 0, 0))
	# wheel at the front: wooden rim, iron tyre, spokes, hub, axle in iron straps up to the handles
	wy, wz, R = -0.6, 0.214, 0.2
	kit.ring(R - 0.02, 0.03, (0, wy, wz), PL(), rot=(0, 90, 0), seg=28)
	kit.ring(R + 0.002, 0.014, (0, wy, wz), IRON("dark"), rot=(0, 90, 0), seg=28)
	kit.cylinder(0.05, 0.1, (0, wy, wz), DK(), rot=(0, 90, 0), verts=10, bevel=0.006)
	for k in range(6):
		a = 2 * math.pi * k / 6 + 0.2
		beam((0, wy + math.cos(a) * 0.04, wz + math.sin(a) * 0.04), (0, wy + math.cos(a) * (R - 0.03), wz + math.sin(a) * (R - 0.03)), 0.025, 0.025, PL(), bevel=0.004)
	rod((-0.22, wy, wz), (0.22, wy, wz), 0.014, IRON("dark"))
	hy = -0.55 * math.cos(math.radians(9)) + 0.04 * math.sin(math.radians(9))
	hz = 0.42 - 0.55 * math.sin(math.radians(9)) - 0.04 * math.cos(math.radians(9))
	for s_ in (-1, 1):
		beam((s_ * 0.2, wy, wz), (s_ * 0.2, hy + 0.03, hz), 0.03, 0.012, IRON("dark"), bevel=0.003)


def mg_cookpot_tripod():
	n = 9
	for k in range(n):
		a = 2 * math.pi * k / n + J(0.1)
		hh = 0.1 + J(0.02)
		B((0.17, 0.12, hh), (math.cos(a) * 0.36, math.sin(a) * 0.36, hh / 2), STONE(), bevel=0.025, rot=(0, 0, math.degrees(a) + 90 + J(8)))
	for k in range(3):  # burnt log stubs, no ash
		a = 2 * math.pi * k / 3 + 0.3
		log((math.cos(a) * 0.08, math.sin(a) * 0.08, 0.04), (math.cos(a) * 0.26, math.sin(a) * 0.26, 0.04 + 0.03 * (k == 1)), 0.04, BARK(), seg=7, rings=1, end_m=CHAR())
	top = Vector((0, 0, 1.15))
	for k in range(3):  # iron tripod
		a = 2 * math.pi * k / 3 + 1.0
		f = Vector((math.cos(a) * 0.58, math.sin(a) * 0.58, 0.0))
		rod(tuple(f + Vector((0, 0, 0.02))), tuple(top), 0.016, IRON("dark"))
		kit.cone(0.024, 0.016, 0.04, tuple(f + Vector((0, 0, 0.02))), IRON("dark"), verts=6, bevel=0.002)
	kit.ring(0.04, 0.012, (0, 0, 1.13), IRON("a"), seg=12)
	chain((0, 0, 1.11), (0, 0, 0.6), link=0.03, wire=0.008, m=IRON("a"))
	kit.ring(0.03, 0.008, (0, 0, 0.585), IRON("dark"), rot=(90, 0, 0), seg=10)
	R, cz, wall = 0.19, 0.42, 0.012  # the pot: really hollow and black inside (owner Nov 22)
	th = [0.25 + (math.acos(-0.62) - 0.25) * k / 8 for k in range(9)]
	hollow_lathe([(R * math.sin(a), -R * math.cos(a)) for a in th], [((R - wall) * math.sin(a), -(R - wall) * math.cos(a)) for a in reversed(th)],
		(0, 0, cz), IRON("dark"), C((0.02, 0.018, 0.016), 1.0), seg=22)
	rim, rr = cz + R * 0.62, R * math.sin(th[-1])
	kit.ring(rr - 0.005, 0.012, (0, 0, rim), IRON("a"), seg=22)
	for s_ in (-1, 1):  # lugs and the bail up to the chain
		kit.ring(0.02, 0.006, (s_ * (rr + 0.005), 0, rim - 0.015), IRON("dark"), rot=(90, 0, 0), seg=8)
		rod((s_ * (rr + 0.01), 0, rim - 0.005), (s_ * 0.07, 0, 0.53), 0.006, IRON("dark"))
		rod((s_ * 0.07, 0, 0.53), (0, 0, 0.562), 0.006, IRON("dark"))
	hlog((-0.62, 0.52, 0.0), (-0.62, 0.52, 0.38), 0.15, seg=12, rings=1, bend=0.0)  # a log seat beside it


def mg_guard_cot():
	L, W, H = 1.85, 0.8, 0.38
	for x in (-W / 2 + 0.05, W / 2 - 0.05):
		for y in (-L / 2 + 0.05, L / 2 - 0.05):
			hlog((x, y, 0.0), (x, y, H + (0.3 if y > 0 else 0.05)), 0.045, seg=7)
		hlog((x, -L / 2 - 0.02, H - 0.03), (x, L / 2 + 0.02, H - 0.03), 0.045, bend=0.02)
	for y in (-L / 2 + 0.05, L / 2 - 0.05):
		hlog((-W / 2 - 0.02, y, H - 0.08), (W / 2 + 0.02, y, H - 0.08), 0.04, bend=0.02)
	for k in range(7):  # rope lacing across and along
		y = -L / 2 + 0.2 + k * (L - 0.4) / 6
		rod((-W / 2 + 0.07, y, H - 0.02), (W / 2 - 0.07, y, H - 0.02), 0.01, ROPE(), seg=6)
	for k in range(3):
		x = -0.2 + k * 0.2
		rod((x, -L / 2 + 0.08, H - 0.04), (x, L / 2 - 0.08, H - 0.04), 0.01, ROPE(), seg=6)
	for i in range(3):  # headboard
		B((W / 3 - 0.01, 0.035, 0.24), (-W / 3 + W / 3 * i, L / 2 - 0.05, H + 0.15), PL(), bevel=0.006)
	hlog((-W / 2 + 0.02, L / 2 - 0.05, H + 0.28), (W / 2 - 0.02, L / 2 - 0.05, H + 0.28), 0.035, seg=7, bend=0.0)
	for x in (-W / 3, 0.0, W / 3):
		peg(x, L / 2 - 0.0675, H + 0.12, r=0.01)
	# a closed footlocker at the foot
	fy, w, d, h = -L / 2 - 0.3, 0.6, 0.36, 0.32
	group(lambda: strongbox_body(w, d, h), at=(0, fy, 0))
	B((w + 0.02, d + 0.02, 0.06), (0, fy, h + 0.035), PL(), bevel=0.008)
	for x in (-w / 2 + 0.08, w / 2 - 0.08):
		B((0.05, d + 0.034, 0.072), (x, fy, h + 0.035), IRON("dark"), bevel=0.003)
	B((0.05, 0.014, 0.08), (0, fy - d / 2 - 0.016, h), IRON("a"), bevel=0.003)
	kit.ring(0.02, 0.006, (0, fy - d / 2 - 0.03, h - 0.04), IRON("dark"), rot=(0, 90, 0), seg=8)


def mg_mess_trestle():
	L, D, H = 1.7, 0.7, 0.66
	for x in (-L / 2 + 0.25, L / 2 - 0.25):
		for s_ in (-1, 1):
			hlog((x, s_ * 0.3, 0.0), (x, s_ * 0.05, H - 0.05), 0.042, seg=7)
		hlog((x, -0.28, H - 0.06), (x, 0.28, H - 0.06), 0.035, seg=7, bend=0.0)
		hlog((x, -0.22, 0.2), (x, 0.22, 0.2), 0.03, seg=6, bend=0.0)
	hlog((-L / 2 + 0.18, 0.0, 0.26), (L / 2 - 0.18, 0.0, 0.26), 0.035, seg=7, bend=0.0)  # stretcher on the cross bars
	for x in (-L / 2 + 0.25, L / 2 - 0.25):
		B((0.03, 0.03, 0.12), (x + 0.05, 0.0, 0.26), DK(), bevel=0.004)  # wedges through the stretcher
	top_boards(L, D, H, t=0.045, n=4)
	zt = H + 0.0225
	for x in (-L / 2 + 0.25, L / 2 - 0.25):
		for y in (-0.26, -0.09, 0.09, 0.26):
			peg(x, y, zt, face="+z", r=0.009)
	for k, (x, y) in enumerate(((-0.6, -0.2), (-0.22, -0.22), (0.28, -0.2), (0.62, -0.2), (-0.45, 0.2), (0.4, 0.21))):
		bowl(x, y, zt, 0.08)
		spoon(x + 0.12, y + 0.03 * (1 if y < 0 else -1), zt, ang=80 + 30 * k)
	mug(-0.2, 0.2, zt)
	mug(0.66, 0.13, zt, m=CU("b"))
	board((0.36, 0.2, 0.03), (0.05, 0.02, zt + 0.015))  # bread board, empty
	beam((-0.04, 0.0, zt + 0.034), (0.1, 0.05, zt + 0.034), 0.03, 0.008, IRON("a"), bevel=0.002)
	beam((0.1, 0.05, zt + 0.04), (0.2, 0.085, zt + 0.04), 0.025, 0.02, DK(), bevel=0.004)
	by = -D / 2 - 0.35  # bench along the front
	for x in (-L / 2 + 0.2, L / 2 - 0.2):
		for s_ in (-1, 1):
			hlog((x, by + s_ * 0.1, 0.0), (x, by + s_ * 0.03, 0.4), 0.038, seg=6)
	for i in range(2):
		board((L - 0.1, 0.16, 0.04), (0, by - 0.08 + 0.16 * i, 0.42))
	for x in (-L / 2 + 0.2, L / 2 - 0.2):
		for y in (by - 0.08, by + 0.08):
			peg(x, y, 0.44, face="+z", r=0.009)


def mg_lantern_post():
	H = 2.0
	for k, a in enumerate((0, 90)):
		r = math.radians(a)
		hlog((-math.cos(r) * 0.35, -math.sin(r) * 0.35, 0.05 + 0.08 * k), (math.cos(r) * 0.35, math.sin(r) * 0.35, 0.05 + 0.08 * k), 0.05, bend=0.0)
	hlog((0, 0, 0.12), (0, 0, H), 0.06, bend=0.015)
	for a in (45, 135, 225, 315):
		r = math.radians(a)
		beam((math.cos(r) * 0.24, math.sin(r) * 0.24, 0.16), (math.cos(r) * 0.04, math.sin(r) * 0.04, 0.5), 0.035, 0.035, DK())
		B((0.08, 0.08, 0.03), (math.cos(r) * 0.24, math.sin(r) * 0.24, 0.13), DK(), bevel=0.006, rot=(0, 0, a))
	sphere((0, 0, H + 0.01), 0.07, DK(), scale=(1, 1, 0.6), seg=10, rings=6)
	az = H - 0.2  # iron arm with a brace and a scroll ring
	B((0.07, 0.04, 0.26), (0, -0.07, az - 0.05), IRON("dark"), bevel=0.003)
	for z in (az + 0.04, az - 0.14):
		rivet((0, -0.092, z), CU("dark"), r=0.011)
	beam((0, -0.07, az + 0.04), (0, -0.62, az + 0.04), 0.03, 0.025, IRON("dark"), bevel=0.003)
	beam((0, -0.08, az - 0.14), (0, -0.4, az + 0.03), 0.022, 0.02, IRON("dark"), bevel=0.003)
	kit.ring(0.06, 0.009, (0, -0.22, az - 0.01), IRON("dark"), rot=(0, 90, 0), seg=14)
	kit.cone(0.025, 0.0, 0.05, (0, -0.645, az + 0.04), IRON("a"), rot=(90, 0, 0), verts=6, bevel=0)
	kit.ring(0.02, 0.006, (0, -0.56, az + 0.02), IRON("dark"), rot=(90, 0, 0), seg=10)
	chain((0, -0.56, az + 0.0), (0, -0.56, az - 0.14), link=0.022, wire=0.006, m=IRON("dark"))
	lantern((0, -0.56, az - 0.43), glow=True)


def mg_grain_bin():
	w, d, h = 0.95, 0.6, 0.72
	for cx in (-1, 1):
		for cy in (-1, 1):
			B((0.06, 0.06, h + 0.08), (cx * (w / 2 - 0.03), cy * (d / 2 - 0.03), (h + 0.08) / 2), DK(), bevel=0.008)
	sh = (h - 0.1) / 4
	for s_ in (-1, 1):
		for k in range(4):
			z = 0.1 + k * sh + sh / 2
			B((w - 0.04, 0.03, sh - 0.008), (0, s_ * (d / 2 - 0.02), z), PL(), bevel=0.006)
			B((0.03, d - 0.1, sh - 0.008), (s_ * (w / 2 - 0.02), 0, z), PL(), bevel=0.006)
	B((w - 0.07, d - 0.07, 0.03), (0, 0, 0.12), DK(), bevel=0.004)
	B((w - 0.1, d - 0.1, 0.004), (0, 0, 0.137), INK(), bevel=0)
	for cx in (-1, 1):  # iron corner straps
		for z in (0.2, h - 0.06):
			B((0.13, 0.012, 0.05), (cx * (w / 2 - 0.06), -d / 2 - 0.006, z), IRON("dark"), bevel=0.003)
			for dx in (-0.04, 0.03):
				rivet((cx * (w / 2 - 0.06) + dx, -d / 2 - 0.012, z), CU("dark"), r=0.008)
	B((w, d / 2, 0.035), (0, d / 4, h + 0.0975), PL(), bevel=0.006)  # back lid board, fixed
	def lid():
		for i in range(2):
			B((w / 2 - 0.006, d / 2 + 0.02, 0.035), (-w / 4 + w / 2 * i, -d / 4, 0), PL(), bevel=0.006)
		B((w - 0.1, 0.05, 0.03), (0, -d / 2 + 0.03, 0.03), DK(), bevel=0.004)
	group(lid, at=(0, 0.0, h + 0.1), rot=(-55, 0, 0))  # front lid hinged open
	for x in (-0.3, 0.3):
		B((0.05, 0.08, 0.012), (x, 0.0, h + 0.12), IRON("dark"), bevel=0.003)
	rod((0.3, -d / 2 + 0.02, h - 0.01), (0.3, -0.165, h + 0.33), 0.014, PL())  # prop stick
	bowl(-0.2, -d / 2 + 0.1, h - 0.1, 0.06)  # wooden scoop hooked over the front edge
	beam((-0.2, -d / 2 + 0.1, h - 0.06), (-0.2, -d / 2 - 0.0, h + 0.03), 0.025, 0.018, PL(), bevel=0.003)
	beam((-0.2, -d / 2 - 0.0, h + 0.03), (-0.2, -d / 2 - 0.04, h - 0.03), 0.025, 0.018, PL(), bevel=0.003)


def mg_tool_chest():
	w, d, h = 0.85, 0.42, 0.36
	strongbox_body(w, d, h)
	def lid():  # inside of the lid faces the room once opened: a saw clipped to it
		B((w + 0.02, d + 0.02, 0.04), (0, -d / 2, 0.02), PL(), bevel=0.008)
		B((0.6, 0.18, 0.004), (-0.04, -d / 2, -0.002), IRON("a"), bevel=0.0)
		B((0.14, 0.15, 0.03), (0.32, -d / 2, -0.012), PL(), bevel=0.008)
		for x in (-0.25, 0.1):
			B((0.025, 0.2, 0.02), (x, -d / 2, -0.009), IRON("dark"), bevel=0.003)
		for k in range(12):  # saw teeth
			kit.cone(0.008, 0.0, 0.012, (-0.33 + k * 0.05, -d / 2 - 0.096, -0.002), IRON("a"), rot=(90, 0, 0), verts=3, bevel=0)
	group(lid, at=(0, d / 2 + 0.02, h + 0.01), rot=(-100, 0, 0))
	for x in (-w / 2 + 0.12, w / 2 - 0.12):  # hinges
		B((0.06, 0.03, 0.06), (x, d / 2 + 0.01, h + 0.0), IRON("dark"), bevel=0.003)
	tz = h - 0.09  # till tray on two cleats, chisels standing in a row
	for s_ in (-1, 1):
		B((w - 0.08, 0.015, 0.06), (0, s_ * 0.08 - 0.05, tz), PL(), bevel=0.003)
		B((0.03, 0.17, 0.02), (s_ * (w / 2 - 0.045), -0.05, tz - 0.04), DK(), bevel=0.003)
	B((w - 0.08, 0.17, 0.012), (0, -0.05, tz - 0.024), DK(), bevel=0.002)
	for k in range(8):
		group(lambda: (B((0.025, 0.025, 0.1), (0, 0, 0.05), PL(), bevel=0.004), kit.ring(0.014, 0.004, (0, 0, 0.1), IRON("dark"), seg=8),
			B((0.012 + 0.002 * k, 0.006, 0.07), (0, 0, -0.03), IRON("a"), bevel=0.001)), at=(-0.32 + k * 0.07, -0.05, tz - 0.012), rot=(12, 0, 0))
	# mallet and plane on the floor beside it
	beam((0.5, -0.3, 0.016), (0.74, -0.42, 0.016), 0.03, 0.03, PL(), bevel=0.004)
	group(lambda: B((0.1, 0.16, 0.1), (0, 0, 0.05), DK(), bevel=0.012), at=(0.79, -0.44, 0.0), rot=(0, 0, -27))
	B((0.24, 0.07, 0.06), (-0.2, -0.42, 0.03), PL(), bevel=0.01, rot=(0, 0, 10))
	B((0.035, 0.06, 0.03), (-0.21, -0.42, 0.07), IRON("a"), bevel=0.003, rot=(0, 20, 10))
	sphere((-0.12, -0.405, 0.07), 0.028, DK(), seg=8, rings=5)


def mg_toll_table():
	W, D, H = 0.95, 0.6, 0.7
	legs_log(W, D, H - 0.04, r=0.042)
	for y in (-D / 2 + 0.06, D / 2 - 0.06):
		hlog((-W / 2 + 0.06, y, 0.2), (W / 2 - 0.06, y, 0.2), 0.028, seg=6)
	top_boards(W + 0.06, D + 0.04, H - 0.02, n=4)
	zt = H + 0.0025
	# balance scale: post, tipped beam, two pans on cords; the left pan is heavier
	sx, sy = -0.18, 0.05
	B((0.16, 0.16, 0.04), (sx, sy, zt + 0.02), DK(), bevel=0.008)
	rod((sx, sy, zt + 0.04), (sx, sy, zt + 0.48), 0.012, CU("dark"))
	sphere((sx, sy, zt + 0.49), 0.02, CU("b"), seg=8, rings=5)
	beam((sx - 0.22, sy, zt + 0.425), (sx + 0.22, sy, zt + 0.455), 0.016, 0.012, CU("dark"), bevel=0.002)
	for s_, pz in ((-1, zt + 0.15), (1, zt + 0.21)):
		px = sx + s_ * 0.21
		ez = zt + 0.44 + s_ * 0.0143
		kit.ring(0.014, 0.004, (px, sy, ez - 0.012), CU("dark"), rot=(90, 0, 0), seg=8)
		for k in range(3):
			a = 2 * math.pi * k / 3 + 0.5
			rod((px, sy, ez - 0.022), (px + math.cos(a) * 0.08, sy + math.sin(a) * 0.08, pz + 0.025), 0.0035, ROPE(), seg=5)
		kit.cone(0.05, 0.09, 0.03, (px, sy, pz + 0.01), CU("b"), verts=16, bevel=0.003)
		kit.ring(0.088, 0.006, (px, sy, pz + 0.025), CU("dark"), seg=16)
	kit.cylinder(0.022, 0.03, (sx - 0.21, sy, zt + 0.15 + 0.04), IRON("a"), verts=10, bevel=0.003)  # a weight in the low pan
	board((0.36, 0.1, 0.025), (0.22, -0.18, zt + 0.0125))  # graduated weights in a row
	for k in range(5):
		r = 0.035 - 0.005 * k
		kit.cylinder(r, r * 1.5, (0.09 + k * 0.065, -0.18, zt + 0.025 + r * 0.75), IRON("a"), verts=10, bevel=0.003)
		sphere((0.09 + k * 0.065, -0.18, zt + 0.025 + r * 1.5), r * 0.35, IRON("dark"), seg=8, rings=5)
	cx, cy = 0.25, 0.12  # locked coin box with a slot cut in the lid
	cb = B((0.26, 0.18, 0.14), (cx, cy, zt + 0.07), PL(), bevel=0.01)
	carve(cb, (0.08, 0.012, 0.05), (cx, cy, zt + 0.14))
	for x in (cx - 0.09, cx + 0.09):
		B((0.03, 0.194, 0.154), (x, cy, zt + 0.071), IRON("dark"), bevel=0.003)
	B((0.05, 0.012, 0.06), (cx, cy - 0.096, zt + 0.08), IRON("a"), bevel=0.003)
	kit.ring(0.018, 0.005, (cx, cy - 0.104, zt + 0.04), IRON("dark"), rot=(90, 0, 0), seg=8)
	for (x, y, n) in ((-0.38, -0.2, 5), (-0.31, -0.22, 3), (-0.02, -0.22, 2)):  # coin stacks
		for i in range(n):
			kit.cylinder(0.022, 0.007, (x + J(0.002), y + J(0.002), zt + 0.0035 + i * 0.0068), CU("b"), verts=10, bevel=0.001)
	book(-0.36, 0.17, zt, 0.2, 0.15, 0.04, LEATHER())


MODELS = {f.__name__: f for f in (
	mg_key_board, mg_shield_wall, mg_crossbow_rack, mg_helmet_pegs, mg_bowl_shelf, mg_rope_wall, mg_ledger_shelf, mg_gate_windlass,
	mg_last_watch, mg_barricade, mg_gate_bar_snapped, mg_crate_pried_open, mg_sawhorse_left, mg_strongbox_forced,
	mg_spear_rack_fallen, mg_collapsed_shelf,
	mg_gatekeeper_chair, mg_gatekeeper_desk, mg_armour_stand, mg_alarm_bell, mg_water_butt, mg_supply_shelf, mg_wheelbarrow,
	mg_cookpot_tripod, mg_guard_cot, mg_mess_trestle, mg_lantern_post, mg_grain_bin, mg_tool_chest, mg_toll_table)}
assert len(MODELS) == 30

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
			floor_cut()  # log end caps and slanted legs dip below the floor: flatten them onto it
			kit.save(str(outdir / f"{name}.glb"), str(jdir / f"{name}.png"), tex_size=256)
			print(f"MODEL_OK {name}")
		except Exception as e:
			import traceback
			traceback.print_exc()
			print(f"MODEL_FAILED {name}: {e!r}")
