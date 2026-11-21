# Decor for LAMPWICK DRIFT (Nov 21): a small root-wood mine drift lit by oil lamps, with cart rails and an upper
# walkway. Lamp-makers and miners worked here; now it is abandoned. Root wood (shack paintings) + iron, copper, glass.
#   blender --background --factory-startup --python builds/decor_nov21_lw.py -- [id ...]   (none = all)
# Output: assets/models/decor/<id>.glb (origin bottom-centre, front faces -Y in Blender = +Z in Godot).
# Wall pieces have a flat back at +Y so they sit flush on a wall.
#
# The 30 objects:
#   lw_lamp_rack_wall       wall rack: two pegged rails of hanging oil lamps (one peg empty, one lamp cold), spare chimneys below
#   lw_wick_spool_shelf     wall shelf: wick spools on a dowel with loose ends, coiled wicks, wax pot, trimmer, cut-wick bundles
#   lw_oil_flask_shelf      wall shelf of stoppered glass oil flasks (different fill levels, one lying down), copper oil cans
#   lw_lamp_parts_board     wall board of lamp repair parts: glass chimneys on dowels, a shelf of burners, pliers, hammer, snips
#   lw_lamp_token_board     the miners' lamp-check board: copper tokens with cut number notches on hooks, some hooks empty
#   lw_signal_code_board    wall board with the bell code cut in (dots and dashes), a pulley bell-pull and a hand bell
#   lw_spare_rail_rack      wall frame with iron brackets holding spare rails and fishplates, a box of rail spikes below
#   lw_oil_barrel_tap       an oil barrel lying in a notched log cradle, copper tap, empty drip basin, upturned funnel
#   lw_lamp_workbench       the lamp-maker's bench: vise with a lamp in it, chimneys, burners, tools on a back rail, fonts below
#   lw_wick_twisting_wheel  a big hand wheel driving a twisting hook; three strands run from a spool rack to the hook
#   lw_ore_sorting_table    a sloped sorting table: rough ore heap at the back, four bins of sorted ore at the front, a rake
#   lw_ore_sieve_cradle     a rocking sieve: plank box with an iron grate on two rockers, a push pole, stones in it, a trough
#   lw_rail_switch_lever    a rail switch: main track, a branch, two switch blades and a weighted throw lever
#   lw_signal_lamp_post     a siding lamp post on a braced foot: crossarm with two lamps (one shuttered), a wick tin box
#   lw_walkway_ladder       a pegged root-wood ladder up to the walkway with iron top hooks, a rope rail and a hanging lamp
#   lw_rest_nook_bench      a miners' rest bench with a back, a shelf above with a cold lamp, a tin mug and a lunch tin
#   lw_lamp_barrow          the lamp-man's barrow: one wheel, a tray with dividers carrying six lamps
#   lw_oil_can_crate        an open crate of copper oil cans (one missing), its lid leaning on the side
#   lw_chimney_crate        a crate with a divider grid of glass chimneys (two gone, one broken), the lid on the floor
#   lw_bell_frame           a free-standing signal bell frame: braced posts, a strapped yoke, the bell and its pull handle
#   lw_ledger_desk          the lamp-man's standing desk: open ledger, ink pot, quill, a lamp and a tally of cut notches
#   lw_ore_bucket_hoist     a hand winch on an A-frame with a ratchet; the rope lowers a hooped bucket of ore
#   STORY:
#   lw_lamp_fallen_spill    a lamp stand knocked flat: the lamp on its side, broken chimney glass, a dark oil stain
#   lw_cart_jammed          a mine cart stuck on its rails under a fallen roof prop; the snapped prop stump beside it
#   lw_last_shift_stool     a tipped stool, a dropped pick, an empty open lunch tin and a lamp still burning low
#   lw_broken_lamp_rack     a wall lamp rack whose bracket snapped: the rail hangs to the floor, lamps fell and smashed
#   lw_leaking_oil_cask     an upright cask with a cracked stave, a wedge hammered in, a pan under the crack catching oil
#   lw_bell_fallen          the signal bell fallen and cracked, its snapped yoke and strap beside it, the rope lying loose
#   lw_collapsed_walkway    a walkway section broken down: back posts stand, the deck slants to the floor, front post snapped
import math
import random
import sys
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from night_stations import B, GAME, J, T, disc, kit, log, mesh, rivet, rng  # noqa: E402
from night_materials import C, lump, sphere, _cm  # noqa: E402
from night_decor import CU, IRON  # noqa: E402
from decor_nov21_f import group, gear  # noqa: E402
from decor_nov21_a import slim, low_z, objs, shift, turn  # noqa: E402
from decor_nov21_g import glass  # noqa: E402


# ================= materials (one wood family: the Shack's root wood) =================
def PL(v=None):
	return T("shackplank", v)


def BK():
	return T("shackbark")


def DK():
	return T("shackdark")


def END():
	return T("shacklogend")


OIL = lambda: C((0.12, 0.065, 0.02), 0.12)  # noqa: E731
STAIN = lambda: C((0.045, 0.03, 0.018), 0.2)  # noqa: E731
WICK = lambda: C((0.66, 0.6, 0.47), 0.95)  # noqa: E731
WAXWICK = lambda: C((0.66, 0.5, 0.26), 0.8)  # noqa: E731
GROOVE = lambda: C((0.045, 0.03, 0.02), 0.95)  # noqa: E731
PAPER = lambda: C((0.7, 0.62, 0.45), 0.95)  # noqa: E731
GLASS = lambda: glass((0.78, 0.88, 0.82), 0.3)  # noqa: E731
SOOT = lambda: kit.mat("charcoal", -0.2)  # noqa: E731
COAL = lambda: C((0.035, 0.035, 0.04), 0.25, metal=0.2)  # noqa: E731
FLAME = lambda: C((1.0, 0.7, 0.3), 0.3, glow=2.0)  # noqa: E731
FLAME_LOW = lambda: C((1.0, 0.55, 0.2), 0.3, glow=1.5)  # noqa: E731


# ================= helpers =================
def LOG(p0, p1, r, m=None, **k):
	k.setdefault("seg", 8)
	return log(p0, p1, r, m or BK(), end_m=END(), **k)


def rod(p0, p1, r, m=None, seg=6):
	return log(p0, p1, r, m or IRON("dark"), seg=seg, rings=1, ends=False, bend=0)


def board(size, loc, m=None, rot=(0, 0, 0), bevel=0.01):
	return B((size[0] * (1 + J(0.015)), size[1], size[2]), loc, m or PL(), bevel=bevel, rot=(rot[0] + J(0.6), rot[1] + J(0.6), rot[2] + J(0.6)))


def peghead(x, y, z, r=0.013):
	"""A domed wooden peg head, half sunk into the face it sits on."""
	sphere((x, y, z), r, DK(), scale=(1, 0.7, 1), seg=8, rings=5)


def peg(x, z, y0=0.0, ln=0.08, r=0.013):
	"""A wooden wall peg sticking out toward -Y, rising a little, with a domed tip."""
	rod((x, y0 + 0.012, z), (x, y0 - ln, z + 0.01), r, DK(), seg=7)
	sphere((x, y0 - ln, z + 0.01), r * 1.3, DK(), seg=8, rings=5)


def lathe(prof, c, m, seg=12, loop=False):
	"""A turned shape: prof = [(radius, z)] bottom to top. loop=True: a closed outline (hollow cups, bells)."""
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


def cup(c, r, h, m, t=0.006, seg=14, flare=1.06):
	"""A hollow cup / pan / bucket shell (open at the top, with a real floor)."""
	return lathe([(0.003, 0), (r * 0.94, 0), (r, t), (r * flare, h - t), (r * flare + t * 0.5, h), (r * flare - t, h),
		(r - t, t + 0.004), (0.003, t + 0.004)], c, m, seg=seg, loop=True)


def cut(target, size, loc, rot=(0, 0, 0), cyl=False):
	"""Cut a groove INTO a part (boolean difference); the groove walls get a dark paint."""
	if cyl:
		bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=size[0], depth=size[1], location=loc, rotation=[math.radians(a) for a in rot])
	else:
		bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=[math.radians(a) for a in rot])
		bpy.context.object.scale = size
		bpy.ops.object.transform_apply(scale=True)
	c = bpy.context.object
	c.data.materials.append(GROOVE())
	md = target.modifiers.new("cut", "BOOLEAN")
	md.operation = "DIFFERENCE"
	md.object = c
	try:
		md.solver = "EXACT"
	except TypeError:
		pass
	if hasattr(md, "material_mode"):
		md.material_mode = "TRANSFER"
	bpy.ops.object.select_all(action="DESELECT")
	bpy.context.view_layer.objects.active = target
	target.select_set(True)
	bpy.ops.object.modifier_apply(modifier=md.name)
	bpy.data.objects.remove(c, do_unlink=True)


def wall_back(w, h, d=0.05, battens=None):
	"""Vertical split boards with a flat back at y = d, pegged cross battens on the front."""
	n = max(2, round(w / 0.22))
	for i in range(n):
		B((w / n - 0.008, d, h + J(0.015)), (-w / 2 + w / n * (i + 0.5), d / 2, h / 2), PL(), bevel=0.01)
	for z in (battens if battens is not None else (0.06, h - 0.06)):
		B((w + 0.02, 0.03, 0.06), (0, -0.012, z), DK(), bevel=0.008)
		for x in (-w / 2 + 0.05, w / 2 - 0.05):
			peghead(x, -0.027, z)


def shelf(w, z, depth=0.2, lip=True):
	"""A shelf board on two pegged brackets, back against the wall boards (y = 0). Returns the top height."""
	board((w, depth, 0.035), (0, -depth / 2, z))
	for x in (-w / 2 + 0.08, w / 2 - 0.08):
		B((0.04, depth * 0.75, 0.1), (x, -depth * 0.375 + 0.003, z - 0.065), DK(), bevel=0.008)
		peghead(x, -depth * 0.75 + 0.003, z - 0.075, 0.011)
	if lip:
		B((w - 0.04, 0.015, 0.03), (0, -depth + 0.01, z + 0.03), DK(), bevel=0.004)
	return z + 0.0175


def lamp(c, s=1.0, lit=True, chimney=True, flame_m=None):
	"""The drift's oil lamp: copper font, iron burner, glass chimney in a wire guard, vented cap, bail ring.
	Height 0.242*s; the bail ring's centre is 0.21*s up."""
	x, y, z = c
	S = lambda v: v * s  # noqa: E731
	lathe([(S(0.04), 0), (S(0.055), S(0.008)), (S(0.058), S(0.03)), (S(0.045), S(0.045)), (S(0.03), S(0.052))], (x, y, z), CU(), seg=12)
	kit.ring(S(0.057), S(0.004), (x, y, z + S(0.02)), CU("dark"), seg=14)
	kit.cylinder(S(0.026), S(0.022), (x, y, z + S(0.056)), IRON("dark"), verts=10, bevel=0.002)
	kit.cylinder(S(0.006), S(0.016), (x + S(0.03), y, z + S(0.056)), IRON("dark"), rot=(0, 90, 0), verts=6, bevel=0)
	if chimney:
		lathe([(S(0.024), S(0.062)), (S(0.034), S(0.085)), (S(0.035), S(0.115)), (S(0.022), S(0.152))], (x, y, z), GLASS(), seg=12)
	for k in range(3):
		a = 2 * math.pi * k / 3 + 0.5
		rod((x + math.cos(a) * S(0.047), y + math.sin(a) * S(0.047), z + S(0.04)),
			(x + math.cos(a) * S(0.03), y + math.sin(a) * S(0.03), z + S(0.16)), max(0.003, S(0.0035)), CU("dark"), seg=5)
	kit.cone(S(0.042), S(0.016), S(0.035), (x, y, z + S(0.165)), CU(), verts=10, bevel=0.002)
	kit.cylinder(S(0.017), S(0.02), (x, y, z + S(0.19)), CU("dark"), verts=8, bevel=0.002)
	kit.ring(S(0.032), max(0.003, S(0.004)), (x, y, z + S(0.21)), IRON("dark"), rot=(90, 0, 0), seg=14)
	if lit:
		kit.flame((x, y, z + S(0.066)), S(0.011), S(0.045), flame_m or FLAME(), twist=x * 40 + y * 13)
	else:
		B((S(0.008), S(0.005), S(0.012)), (x, y, z + S(0.071)), SOOT(), bevel=0)


def hang_lamp(px, py, pz, s=0.85, **kw):
	"""A lamp hanging by its bail ring on a peg running along Y whose top is pz + 0.013."""
	cz = pz + 0.013 - 0.028 * s
	lamp((px, py, cz - 0.21 * s), s, **kw)


def chimney(x, y, z, s=1.0):
	lathe([(0.024 * s, 0), (0.034 * s, 0.025 * s), (0.035 * s, 0.055 * s), (0.022 * s, 0.09 * s)], (x, y, z), GLASS(), seg=12)
	kit.ring(0.025 * s, 0.003, (x, y, z + 0.004), CU("dark"), seg=12)


def broken_chimney(x, y, z, s=1.0):
	"""The lower half of a chimney with a jagged top."""
	lathe([(0.024 * s, 0), (0.034 * s, 0.025 * s), (0.035 * s, 0.04 * s)], (x, y, z), GLASS(), seg=12)
	for k in range(5):
		a = 2 * math.pi * k / 5 + 0.3
		kit.cone(0.012 * s, 0.0, 0.03 * s * (0.6 + 0.4 * (k % 2)), (x + math.cos(a) * 0.033 * s, y + math.sin(a) * 0.033 * s, z + 0.05 * s),
			GLASS(), verts=3, bevel=0)


def flask(x, y, z, r, h, fill=0.5):
	"""A stoppered glass oil flask, oil inside up to `fill` of the body, a paper label on its front."""
	lathe([(r * 0.85, 0), (r, r * 0.3), (r, h * 0.55), (r * 0.5, h * 0.72), (r * 0.32, h * 0.8), (r * 0.32, h * 0.95), (r * 0.4, h)],
		(x, y, z), GLASS(), seg=12)
	if fill > 0:
		top = max(r * 0.3 + 0.006, h * 0.52 * fill)
		lathe([(r * 0.78, 0.004), (r * 0.9, r * 0.3), (r * 0.9, top)], (x, y, z), OIL(), seg=12)
	kit.cylinder(r * 0.3, h * 0.12, (x, y, z + h + h * 0.02), DK(), verts=8, bevel=0.003)
	B((r * 1.1, 0.004, h * 0.2), (x, y - r + 0.0005, z + h * 0.32), PAPER(), bevel=0.001)


def oil_can(x, y, z, s=1.0):
	"""A copper oil can with a long spout, side handle and wooden stopper."""
	S = lambda v: v * s  # noqa: E731
	lathe([(S(0.05), 0), (S(0.056), S(0.008)), (S(0.056), S(0.07)), (S(0.04), S(0.095)), (S(0.014), S(0.11)), (S(0.014), S(0.125))], (x, y, z), CU(), seg=12)
	kit.ring(S(0.056), S(0.004), (x, y, z + S(0.035)), CU("dark"), seg=14)
	rod((x + S(0.04), y, z + S(0.04)), (x + S(0.12), y, z + S(0.13)), S(0.007), CU("dark"), seg=6)
	kit.ring(S(0.03), S(0.006), (x - S(0.05), y, z + S(0.065)), CU("dark"), rot=(90, 0, 0), seg=12)
	kit.cylinder(S(0.017), S(0.014), (x, y, z + S(0.128)), DK(), verts=8, bevel=0.002)


def funnel(x, y, z, s=1.0, up=False):
	p = [(0.07 * s, 0), (0.075 * s, 0.006 * s), (0.014 * s, 0.07 * s), (0.009 * s, 0.13 * s)]
	if up:
		p = [(0.009 * s, 0), (0.014 * s, 0.06 * s), (0.075 * s, 0.124 * s), (0.07 * s, 0.13 * s)]
	lathe(p, (x, y, z), CU("dark"), seg=12)


def spool(c, r, ln, axis, m):
	rot = {"x": (0, 90, 0), "y": (90, 0, 0), "z": (0, 0, 0)}[axis]
	ax = Vector({"x": (1, 0, 0), "y": (0, 1, 0), "z": (0, 0, 1)}[axis])
	cv = Vector(c)
	for s_ in (-1, 1):
		kit.cylinder(r * 1.25, 0.012, tuple(cv + ax * s_ * (ln / 2)), DK(), rot=rot, verts=12, bevel=0.003)
	kit.cylinder(r, ln - 0.004, c, m, rot=rot, verts=14, bevel=0.004)
	for k in range(3):
		kit.ring(r, 0.003, tuple(cv + ax * (k - 1) * ln * 0.3), m, rot=rot, seg=14)


def staves(prof, c, n=16, t=0.02, gap=0.004, core_to=None):
	"""A barrel/bucket wall of n separate staves (each its own plank painting) along prof [(outer r, z)], with a dark
	core inside so the gaps read dark. core_to = (z0, z1) of the core (None = no core). Returns the stave objects."""
	x0, y0, z0 = c
	out = []
	rm = sum(r for r, _ in prof) / len(prof)
	ga = gap / rm / 2
	for i in range(n):
		a0, a1 = 2 * math.pi * (i - 0.5) / n + ga, 2 * math.pi * (i + 0.5) / n - ga
		angs = (a0, (a0 + a1) / 2, a1)
		v = []
		for r, z in prof:
			ring = [(r, a) for a in angs] + [(r - t, a) for a in reversed(angs)]
			v += [(x0 + math.cos(a) * rr, y0 + math.sin(a) * rr, z0 + z) for rr, a in ring]
		m = 6
		f = [tuple(reversed(range(m))), tuple(range((len(prof) - 1) * m, len(prof) * m))]
		for j in range(len(prof) - 1):
			for k in range(m):
				f.append((j * m + k, j * m + (k + 1) % m, (j + 1) * m + (k + 1) % m, (j + 1) * m + k))
		out.append(mesh(v, f, PL("abc"[(i * 7) % 3]) if i % 4 else DK()))
	if core_to:
		za, zb = core_to
		cp = [(r - t * 0.6, z) for r, z in prof if za <= z <= zb]
		def r_at(zq):
			for (ra, za_), (rb, zb_) in zip(prof, prof[1:]):
				if za_ <= zq <= zb_:
					return ra + (rb - ra) * (zq - za_) / (zb_ - za_)
			return prof[-1][0]
		cp = [(r_at(za) - t * 0.6, za)] + [q for q in cp if za < q[1] < zb] + [(r_at(zb) - t * 0.6, zb)]
		lathe(cp, c, C((0.09, 0.06, 0.04), 0.95), seg=n * 2)
	return out


def bell(c, s=1.0, m=None):
	"""A hollow cast bell (open mouth) with a crown loop and a clapper inside."""
	x, y, z = c
	outer = [(0.09, 0), (0.088, 0.012), (0.065, 0.04), (0.052, 0.09), (0.05, 0.13), (0.035, 0.155), (0.012, 0.165)]
	inner = [(0.006, 0.15), (0.03, 0.14), (0.042, 0.12), (0.045, 0.09), (0.057, 0.04), (0.078, 0.012), (0.082, 0.003)]
	lathe([(r * s, h * s) for r, h in outer + inner], (x, y, z), m or CU("dark"), seg=16, loop=True)
	kit.ring(0.02 * s, 0.006 * s, (x, y, z + 0.18 * s), IRON("dark"), rot=(90, 0, 0), seg=10)
	rod((x, y, z + 0.155 * s), (x, y, z + 0.035 * s), 0.005 * s, IRON("dark"), seg=5)
	sphere((x, y, z + 0.03 * s), 0.018 * s, IRON("dark"), seg=8, rings=6)


def rail_seg(p0, p1, z, short=0.0):
	"""An iron rail (foot, web, head) from p0 to p1 (x, y) with its foot bottom at z. Returns the rail top."""
	dx, dy = p1[0] - p0[0], p1[1] - p0[1]
	L = math.hypot(dx, dy)
	ang = math.degrees(math.atan2(dy, dx)) - 90
	cx, cy = (p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2
	B((0.06, L, 0.014), (cx, cy, z + 0.007), IRON("dark"), bevel=0.002, rot=(0, 0, ang))
	B((0.016, L - 0.008, 0.04), (cx, cy, z + 0.032), IRON("dark"), bevel=0.002, rot=(0, 0, ang))
	B((0.036, L - 0.004, 0.022), (cx, cy, z + 0.059), IRON("a"), bevel=0.003, rot=(0, 0, ang))
	return z + 0.07


def sleepers(y0, y1, w, n):
	for k in range(n):
		y = y0 + (y1 - y0) * (k + 0.5) / n
		board((w, 0.14, 0.07), (J(0.01), y, 0.035), DK() if k % 2 else PL())
	return 0.066


def track(length, gauge=0.25, n=None):
	"""A short straight track along Y: sleepers, two rails, spike heads. Returns the rail top height."""
	n = n or max(2, round(length / 0.3))
	z = sleepers(-length / 2, length / 2, 2 * gauge + 0.3, n)
	for x in (-gauge, gauge):
		top = rail_seg((x, -length / 2 + 0.01), (x, length / 2 - 0.01), z)
		for k in range(n):
			y = -length / 2 + length * (k + 0.5) / n
			for s_ in (-1, 1):
				kit.cylinder(0.012, 0.012, (x + s_ * 0.04, y, z + 0.008), IRON("dark"), verts=6, bevel=0.002)
	return top


def crate(w, d, h, loc, slats=2):
	"""An open root-wood crate: bottom, slatted sides, corner posts, peg heads."""
	x, y, z = loc
	B((w - 0.04, d - 0.04, 0.025), (x, y, z + 0.018), DK(), bevel=0.005)
	for s_ in (-1, 1):
		for k in range(slats):
			zz = z + h * (k + 0.5) / slats
			hh = h / slats - 0.012
			B((w - 0.05, 0.022, hh), (x, y + s_ * (d / 2 - 0.011), zz), PL(), bevel=0.006)
			B((0.022, d - 0.05, hh), (x + s_ * (w / 2 - 0.011), y, zz), PL(), bevel=0.006)
			for cx in (-1, 1):
				peghead(x + cx * (w / 2 - 0.06), y + s_ * (d / 2), zz, 0.009)
	for cx in (-1, 1):
		for cy in (-1, 1):
			B((0.045, 0.045, h + 0.005), (x + cx * (w / 2 - 0.02), y + cy * (d / 2 - 0.02), z + h / 2 + 0.0025), DK(), bevel=0.008)


def ore_rock(i):
	k = i % 7
	if k in (0, 3):
		return COAL()
	if k == 1:
		return T("brownrock", "b")
	if k == 5:
		return C((0.42, 0.22, 0.12), 0.8)
	return T("stone", "abc"[i % 3])


def ore_pile(cx, cy, z, w, d, layers=3, seed=1, mats=None, smin=0.03, smax=0.065):
	"""Angular lumps of many sizes, each layer smaller and resting into the one below."""
	r = random.Random(seed)
	i = 0
	for L in range(layers):
		f = 1 - L * 0.3
		n = max(3, int(w * d * 260 * f * f))
		for _ in range(n):
			s = r.uniform(smin, smax) * (1 - L * 0.12)
			px = cx + r.uniform(-w / 2, w / 2) * f
			py = cy + r.uniform(-d / 2, d / 2) * f
			m = mats(i) if mats else ore_rock(i)
			lump((px, py, z + s * 0.45 + L * smax * 0.7), (s, s * r.uniform(0.7, 1.0), s * r.uniform(0.55, 0.85)), m, seed=seed * 31 + i, rough=0.006)
			if m is not COAL() and i % 4 == 2:
				kit.gem((px + s * 0.4, py - s * 0.3, z + s * 0.8 + L * smax * 0.7), (s * 0.3, s * 0.25, s * 0.2), CU("b") if i % 8 == 2 else C((0.5, 0.26, 0.12), 0.7), seed=i)
			i += 1


def shards(cx, cy, n, spread, seed):
	r = random.Random(seed)
	for k in range(n):
		a, d = r.uniform(0, 6.28), r.uniform(0.2, 1.0) * spread
		kit.gem((cx + math.cos(a) * d, cy + math.sin(a) * d * 0.8, 0.0035), (r.uniform(0.012, 0.028), r.uniform(0.008, 0.02), 0.004), GLASS(), seed=k + seed)


def stain(x, y, r, seed=3):
	"""Dried lamp oil on the floor: a dark uneven film plus a darker centre."""
	disc(r, 0.0, 0.003, (x, y), STAIN(), seg=22, wob=0.18)
	disc(r * 0.55, 0.0, 0.0055, (x + r * 0.15, y - r * 0.1), C((0.03, 0.02, 0.012), 0.12), seg=16, wob=0.2)


def splinters(p, ax, n=4, r=0.03):
	ax = Vector(ax).normalized()
	u = ax.orthogonal().normalized()
	v = ax.cross(u)
	for k in range(n):
		a = 2 * math.pi * k / n + J(0.4)
		c = Vector(p) + (u * math.cos(a) + v * math.sin(a)) * r * 0.5
		tip = c + ax * (0.05 + J(0.02)) + (u * math.cos(a) + v * math.sin(a)) * 0.006
		log(tuple(c - ax * 0.02), tuple(tip), 0.011, PL(), seg=4, rings=1, ends=False, bend=0, r1=0.0015)


def tipped(build, axis, deg, pivot=(0, 0, 0), at=(0, 0)):
	"""Build something upright, tip it over round `axis`, then set it down on the floor at (x, y)."""
	before = objs()
	build()
	g = [o for o in objs() - before]
	bpy.context.view_layer.update()
	turn(g, axis, deg, pivot)
	bpy.context.view_layer.update()
	shift(g, (at[0], at[1], -low_z(g)))


def tin_mug(x, y, z, s=1.0):
	cup((x, y, z), 0.035 * s, 0.08 * s, IRON("a"), t=0.004)
	kit.ring(0.025 * s, 0.005, (x + 0.042 * s, y, z + 0.045 * s), IRON("dark"), rot=(90, 0, 0), seg=10)


def lunch_tin(x, y, z, open_=False):
	"""A copper lunch tin with a riveted band; open = the lid lies beside it."""
	if open_:
		cup((x, y, z), 0.075, 0.07, CU("b"), t=0.005, seg=16, flare=1.0)
	else:
		kit.cylinder(0.075, 0.07, (x, y, z + 0.035), CU("b"), verts=16, bevel=0.004)
		kit.cylinder(0.079, 0.02, (x, y, z + 0.07), CU("dark"), verts=16, bevel=0.004)
	kit.ring(0.076, 0.004, (x, y, z + 0.03), CU("dark"), seg=16)
	if not open_:
		kit.ring(0.03, 0.005, (x, y, z + 0.085), IRON("dark"), rot=(90, 0, 0), seg=10)


def pickaxe(build_at=(0, 0, 0)):
	"""A pick lying flat-ish: built along X with the head at +X (used inside tipped/group)."""
	x, y, z = build_at
	LOG((x - 0.42, y, z), (x + 0.2, y, z), 0.018, PL("b"), seg=7, rings=2, bend=0.02)
	for s_ in (-1, 1):
		log((x + 0.2, y, z), (x + 0.2, y + s_ * 0.2, z - 0.035), 0.022, IRON("dark"), seg=6, rings=2, ends=False, bend=0.02, r1=0.006)
	B((0.06, 0.06, 0.05), (x + 0.2, y, z), IRON("dark"), bevel=0.006)


# ================= wall pieces =================
def lw_lamp_rack_wall():
	W = 1.0
	wall_back(W, 0.95, battens=(0.9,))
	xs = (-0.38, -0.19, 0.0, 0.19, 0.38)
	for row, z in enumerate((0.78, 0.44)):
		B((W + 0.04, 0.05, 0.07), (0, -0.02, z), DK(), bevel=0.01)
		for x in (-W / 2 + 0.01, W / 2 - 0.01):
			peghead(x, -0.046, z)
		for i, x in enumerate(xs):
			peg(x, z, y0=-0.045)
			if (row, i) == (0, 3):
				continue
			cold = (row, i) == (1, 1)
			hang_lamp(x, -0.1, z + 0.007, s=0.85, lit=not cold, chimney=not cold)
	top = shelf(W - 0.1, 0.14, depth=0.15)
	for x in (-0.285, -0.095, 0.095, 0.285):
		chimney(x, -0.07, top - 0.003)


def lw_wick_spool_shelf():
	W = 0.9
	wall_back(W, 0.82, battens=(0.78,))
	for x in (-0.41, 0.41):
		B((0.04, 0.16, 0.12), (x, -0.077, 0.6), DK(), bevel=0.008)
		peghead(x, -0.157, 0.6)
	rod((-0.42, -0.11, 0.62), (0.42, -0.11, 0.62), 0.012, DK())
	ms = (WICK(), WAXWICK(), WICK(), C((0.42, 0.32, 0.2), 0.9), WAXWICK())
	for i, x in enumerate((-0.3, -0.15, 0.0, 0.15, 0.3)):
		r = 0.045 - 0.008 * (i % 2)
		spool((x, -0.11, 0.62), r, 0.075, "x", ms[i])
		rod((x + 0.01, -0.11 - r * 0.55, 0.62 - r * 0.75), (x + 0.015 + J(0.01), -0.12 - r * 0.6, 0.47 + 0.02 * (i % 2)), 0.004, ms[i], seg=5)
	t = shelf(W, 0.38)
	for k in range(3):
		x = -0.32 + k * 0.1
		for j in range(4 - k % 2):
			kit.ring(0.04 - 0.003 * j, 0.008, (x, -0.1, t + 0.007 + j * 0.013), ms[k], seg=16)
	# wick trimmer lying open
	B((0.13, 0.012, 0.004), (0.02, -0.1, t + 0.002), IRON("a"), bevel=0.001, rot=(0, 0, 12))
	B((0.13, 0.012, 0.004), (0.02, -0.1, t + 0.0055), IRON("a"), bevel=0.001, rot=(0, 0, -12))
	for s_ in (-1, 1):
		kit.ring(0.016, 0.0035, (-0.065, -0.1 + s_ * 0.022, t + 0.004), IRON("dark"), seg=10)
	rivet((0.02, -0.1, t + 0.008), IRON("dark"), r=0.006)
	# wax pot with hardened wax
	cup((0.25, -0.1, t), 0.045, 0.07, CU("b"), t=0.005)
	disc(0.035, t + 0.012, t + 0.045, (0.25, -0.1), C((0.62, 0.5, 0.3), 0.7), seg=14, wob=0.02)
	rod((0.25, -0.09, t + 0.03), (0.29, -0.06, t + 0.12), 0.005, DK())
	t = shelf(W, 0.12)
	for b in range(3):
		xb = -0.3 + b * 0.22
		for j in range(6):
			yy, zz = -0.1 + (j % 3 - 1) * 0.011, t + 0.006 + (j // 3) * 0.01
			rod((xb - 0.1, yy, zz), (xb + 0.1, yy, zz), 0.0055, ms[b + 1], seg=5)
		for dx in (-0.06, 0.06):
			kit.ring(0.022, 0.004, (xb + dx, -0.1, t + 0.011), kit.tex_mat("rope", "a"), rot=(0, 90, 0), seg=10)
	stick = B((0.04, 0.03, 0.16), (0.34, -0.06, t + 0.08), PL("b"), bevel=0.004, rot=(0, 0, 0))
	for k in range(7):
		cut(stick, (0.022 if k % 2 else 0.032, 0.008, 0.004), (0.33 if k % 2 else 0.335, -0.075, t + 0.02 + k * 0.02))


def lw_oil_flask_shelf():
	W = 1.0
	wall_back(W, 0.95, battens=(0.9,))
	t1, t2, t3 = shelf(W, 0.14), shelf(W, 0.44), shelf(W, 0.72)
	for (x, r, h, f) in ((-0.36, 0.06, 0.2, 0.8), (-0.2, 0.055, 0.18, 0.3), (-0.05, 0.06, 0.2, 0.0), (0.12, 0.05, 0.16, 0.6), (0.3, 0.065, 0.21, 1.0)):
		flask(x, -0.1, t1 - 0.002, r, h, f)
	for k, x in enumerate((-0.38, -0.29, -0.2, -0.11)):
		flask(x, -0.1, t2 - 0.002, 0.034, 0.12, (0.9, 0.2, 0.6, 0.0)[k])
	group(lambda: flask(0, 0, 0, 0.034, 0.12, 0.4), at=(-0.02, -0.12, t2 + 0.032), rot=(0, 90, 18))
	funnel(0.17, -0.1, t2 - 0.002, 0.9)
	oil_can(0.32, -0.1, t2 - 0.002, 0.85)
	for k, x in enumerate((-0.36, -0.12, 0.12)):
		oil_can(x, -0.1, t3 - 0.002, (1.0, 0.85, 0.7)[k])
	for k in range(4):
		flask(0.26 + k * 0.055, -0.1, t3 - 0.002, 0.022, 0.08, 0.7 - 0.2 * k)


def lw_lamp_parts_board():
	W = 1.0
	wall_back(W, 0.86)
	# glass chimneys slid onto slanted dowels (one dowel empty)
	for i, x in enumerate((-0.33, -0.11, 0.11, 0.33)):
		rod((x, 0.01, 0.62), (x, -0.14, 0.652), 0.012, DK(), seg=7)
		if i != 2:
			group(lambda: chimney(0, 0, 0), at=(x, -0.02, 0.632), rot=(78, 0, 0))
	# a shelf of burners
	t = shelf(W - 0.06, 0.4, depth=0.14)
	for k in range(6):
		x = -0.36 + k * 0.13
		kit.cylinder(0.026, 0.024, (x, -0.075, t + 0.011), IRON("dark"), verts=10, bevel=0.002)
		kit.cylinder(0.038, 0.006, (x, -0.075, t + 0.024), CU("dark"), verts=12, bevel=0.002)
		B((0.022, 0.007, 0.03), (x, -0.075, t + 0.04), IRON("a"), bevel=0.001)
		kit.cylinder(0.006, 0.02, (x + 0.032, -0.075, t + 0.012), IRON("dark"), rot=(0, 90, 0), verts=6, bevel=0)
	# tools on peg pairs
	z = 0.27
	peg(-0.32, z, ln=0.07)  # pliers hang on a peg between the handles
	for s_ in (-1, 1):
		B((0.014, 0.012, 0.16), (-0.32 + s_ * 0.018, -0.045, z - 0.07), IRON("dark"), bevel=0.003, rot=(0, -s_ * 7, 0))
		B((0.012, 0.012, 0.06), (-0.32 + s_ * 0.005, -0.045, z - 0.17), IRON("dark"), bevel=0.003, rot=(0, s_ * 4, 0))
	rivet((-0.32, -0.053, z - 0.145), IRON("a"), r=0.009)
	for dx in (-0.045, 0.045):  # small hammer resting by its head on two pegs
		peg(-0.1 + dx, z, ln=0.07)
	B((0.15, 0.04, 0.04), (-0.1, -0.045, z + 0.032), IRON("dark"), bevel=0.006)
	B((0.026, 0.024, 0.2), (-0.1, -0.045, z - 0.085), PL("b"), bevel=0.005)
	peg(0.12, z, ln=0.07)  # tin snips hanging by their loop
	kit.ring(0.03, 0.005, (0.12, -0.045, z - 0.012), IRON("dark"), rot=(90, 0, 0), seg=12)
	for s_ in (-1, 1):
		B((0.014, 0.01, 0.16), (0.12 + s_ * 0.012, -0.045, z - 0.12), IRON("a"), bevel=0.002, rot=(0, s_ * 6, 0))
	rivet((0.12, -0.053, z - 0.14), IRON("dark"), r=0.008)
	peg(0.34, z, ln=0.07)  # soldering iron
	kit.ring(0.02, 0.004, (0.34, -0.045, z - 0.002), IRON("dark"), rot=(90, 0, 0), seg=10)
	log((0.34, -0.045, z - 0.025), (0.34, -0.045, z - 0.13), 0.016, PL("b"), seg=7, rings=1, ends=False, bend=0)
	rod((0.34, -0.045, z - 0.13), (0.34, -0.045, z - 0.2), 0.006, IRON("dark"))
	B((0.04, 0.03, 0.03), (0.34, -0.045, z - 0.215), CU("dark"), bevel=0.004)


def lw_lamp_token_board():
	W, H = 0.92, 0.95
	wall_back(W, H, battens=(0.06,))
	head = B((0.62, 0.03, 0.13), (0, -0.012, 0.85), PL("b"), bevel=0.01)
	for x in (-0.28, 0.28):
		peghead(x, -0.027, 0.85)
	# the lamp mark cut into the header: body, chimney, cap, flame
	y = -0.027
	cut(head, (0.07, 0.01, 0.03), (0, y, 0.8))
	cut(head, (0.035, 0.01, 0.045), (0, y, 0.84))
	cut(head, (0.06, 0.01, 0.012), (0, y, 0.868))
	cut(head, (0.018, 0.01, 0.018), (0, y, 0.892), rot=(0, 45, 0))
	for s_ in (-1, 1):
		for k in range(3):
			cut(head, (0.012, 0.01, 0.06), (s_ * (0.12 + k * 0.05), y, 0.85))
	r_ = random.Random(5)
	for row in range(4):
		hz = 0.68 - row * 0.155
		for i in range(6):
			x = -0.35 + i * 0.14
			rod((x, 0.012, hz), (x, -0.05, hz), 0.006, IRON("dark"), seg=5)
			rod((x, -0.05, hz - 0.002), (x, -0.052, hz + 0.022), 0.006, IRON("dark"), seg=5)
			if (row, i) in ((0, 2), (1, 4), (2, 0), (2, 3), (3, 5), (1, 1)):
				continue
			cz = hz - 0.003
			kit.ring(0.011, 0.0028, (x, -0.035, cz), CU("dark"), rot=(90, 0, 0), seg=10)
			tok = kit.cylinder(0.03, 0.006, (x, -0.035, cz - 0.037), CU("b" if (row + i) % 2 else "a"), rot=(90, 0, 0), verts=14, bevel=0.0015)
			n = r_.randint(1, 4)
			for k in range(n):
				cut(tok, (0.004, 0.006, 0.022), (x - (n - 1) * 0.0045 + k * 0.009, -0.039, cz - 0.037))
	for x in (-0.42, 0.42):
		B((0.06, 0.012, 0.06), (x, -0.004, H - 0.04), CU("dark"), bevel=0.003)


def lw_signal_code_board():
	W, H = 0.72, 0.92
	wall_back(W, H, battens=())
	for z in (0.03, H - 0.03):
		B((W + 0.02, 0.035, 0.05), (0, -0.014, z), DK(), bevel=0.008)
	for x in (-W / 2 + 0.015, W / 2 - 0.015):
		B((0.04, 0.035, H - 0.1), (x, -0.014, H / 2), DK(), bevel=0.008)
		for z in (0.03, H - 0.03):
			peghead(x, -0.032, z)
	face = B((0.5, 0.02, 0.72), (-0.06, -0.008, 0.46), PL("b"), bevel=0.006)
	y = -0.018
	# the bell mark: dome + skirt + lip
	cut(face, (0.035, 0.01, 0), (-0.06, y, 0.75), rot=(90, 0, 0), cyl=True)
	cut(face, (0.07, 0.01, 0.04), (-0.06, y, 0.72))
	cut(face, (0.1, 0.01, 0.014), (-0.06, y, 0.695))
	# the code: how many rings (cut dots) and what they mean (a cut dash of a different length)
	for row, (dots, dash) in enumerate(((1, 0.14), (2, 0.08), (3, 0.11), (4, 0.04), (5, 0.16))):
		z = 0.6 - row * 0.1
		for k in range(dots):
			cut(face, (0.02, 0.01, 0.02), (-0.27 + k * 0.032, y, z))
		cut(face, (dash, 0.01, 0.014), (dash / 2, y, z))
	# a cut border round the face and a line between the rings and their meanings
	for z in (0.125, 0.795):
		cut(face, (0.47, 0.01, 0.008), (-0.06, y, z))
	for x in (-0.295, 0.175):
		cut(face, (0.008, 0.01, 0.678), (x, y, 0.46))
	cut(face, (0.008, 0.01, 0.5), (-0.075, y, 0.41))
	for x in (-0.3, 0.18):
		for z in (0.115, 0.805):
			peghead(x + (0.005 if x < 0 else -0.005), -0.018, z, 0.009)
	# iron strap plates on the battens
	for x in (-0.27, 0.27):
		for z in (0.03, 0.89):
			B((0.07, 0.006, 0.042), (x, -0.033, z), IRON("dark"), bevel=0.002)
			for dx in (-0.022, 0.022):
				rivet((x + dx, -0.036, z), IRON("a"), r=0.006)
	# a little ledge under the face: the bell striker and two chalk sticks
	board((0.34, 0.07, 0.02), (-0.06, -0.032, 0.063), PL("c"), bevel=0.004)
	B((0.012, 0.06, 0.04), (-0.2, -0.03, 0.035), DK(), bevel=0.003)
	B((0.012, 0.06, 0.04), (0.08, -0.03, 0.035), DK(), bevel=0.003)
	kit.cylinder(0.018, 0.07, (0.04, -0.035, 0.09), PL("b"), rot=(0, 90, 0), verts=10, bevel=0.003)
	rod((0.004, -0.035, 0.089), (-0.13, -0.04, 0.081), 0.007, DK())
	for k in range(2):
		B((0.05, 0.011, 0.011), (-0.19 + k * 0.03, -0.03 - k * 0.012, 0.0785), PAPER(), bevel=0.002, rot=(0, 0, 12 - k * 20))
	# bell-pull: a pulley on a bracket, the rope down to a wooden handle
	B((0.05, 0.12, 0.05), (0.27, -0.06, 0.82), DK(), bevel=0.006)
	kit.cylinder(0.05, 0.025, (0.27, -0.1, 0.77), DK(), rot=(90, 0, 0), verts=14, bevel=0.004)
	kit.ring(0.05, 0.006, (0.27, -0.1, 0.77), kit.tex_mat("rope", "a"), rot=(90, 0, 0), seg=16)
	rod((0.27, -0.1, 0.82), (0.27, -0.1, 0.77), 0.008, IRON("dark"))
	kit.rope((0.32, -0.1, 0.77), (0.32, -0.1, 0.24), 0.008)
	kit.rope((0.32, -0.1, 0.77), (0.32, -0.1, 0.89), 0.008)
	LOG((0.26, -0.1, 0.22), (0.38, -0.1, 0.22), 0.02, PL("b"), seg=7, rings=1)
	kit.ring(0.014, 0.004, (0.32, -0.1, 0.24), kit.tex_mat("rope", "a"), rot=(0, 90, 0), seg=8)
	# a hand bell on a peg
	peg(0.27, 0.42, ln=0.08)
	kit.ring(0.02, 0.005, (0.27, -0.06, 0.41), kit.tex_mat("leather", "dark"), rot=(90, 0, 0), seg=10)
	log((0.27, -0.06, 0.39), (0.27, -0.06, 0.33), 0.012, PL("c"), seg=6, rings=1, ends=False, bend=0)
	bell((0.27, -0.06, 0.22), 0.65)


def rail_bar(c, length):
	"""A rail lying along X with its foot bottom at c[2]."""
	x, y, z = c
	B((length, 0.06, 0.014), (x, y, z + 0.007), IRON("dark"), bevel=0.002)
	B((length - 0.008, 0.016, 0.04), (x, y, z + 0.032), IRON("dark"), bevel=0.002)
	B((length - 0.004, 0.036, 0.022), (x, y, z + 0.059), IRON("a"), bevel=0.003)


def lw_spare_rail_rack():
	W, H = 1.3, 0.75
	for x in (-0.55, 0.55):
		B((0.08, 0.07, H), (x, -0.035, H / 2), DK(), bevel=0.01)
	board((W, 0.06, 0.09), (0, -0.035, H - 0.055), DK())
	board((W, 0.05, 0.06), (0, -0.035, 0.08))
	for x in (-0.55, 0.55):
		for z in (0.08, H - 0.055):
			peghead(x, -0.071, z)
	for z in (0.26, 0.46):
		for x in (-0.55, 0.55):
			B((0.05, 0.2, 0.02), (x, -0.165, z), IRON("dark"), bevel=0.003)
			B((0.044, 0.02, 0.05), (x, -0.255, z + 0.02), IRON("dark"), bevel=0.003)
			B((0.062, 0.012, 0.07), (x, -0.074, z - 0.02), IRON("dark"), bevel=0.002)
			rivet((x, -0.081, z - 0.03), IRON("a"), r=0.008)
	rail_bar((0, -0.2, 0.27), 1.26)
	rail_bar((0, -0.13, 0.27), 1.2)
	rail_bar((0.02, -0.19, 0.47), 1.24)
	for k, x in enumerate((-0.32, 0.0, 0.32)):  # fishplates hung by their top hole on pegs
		peg(x, 0.69, y0=-0.065, ln=0.06, r=0.01)
		pl = B((0.07, 0.012, 0.24), (x, -0.09, 0.59), IRON("dark"), bevel=0.002, rot=(0, (k - 1) * 4, 0))
		for j in range(4):
			cut(pl, (0.011 if j else 0.016, 0.03, 0), (x, -0.09, 0.69 - j * 0.062), rot=(90, 0, 0), cyl=True)
	# a box of rail spikes at the bottom
	crate(0.36, 0.22, 0.12, (0.0, -0.16, 0.0))
	for k in range(14):
		px, py = -0.13 + (k % 7) * 0.043, -0.2 + (k // 7) * 0.07
		lean = (k % 3 - 1) * 12
		group(lambda: (rod((0, 0, 0), (0, 0, 0.14), 0.007, IRON("dark")), B((0.03, 0.018, 0.014), (0.006, 0, 0.142), IRON("dark"), bevel=0.002)),
			at=(px, py, 0.03), rot=(lean, (k % 2) * 10 - 5, 0))


# ================= floor props =================
def lw_oil_barrel_tap():
	zc = 0.38
	for y in (0.17, -0.17):
		LOG((-0.34, y, 0.075), (0.34, y, 0.075), 0.075, seg=9, rings=2, bend=0.03)
		for s_ in (-1, 1):
			B((0.08, 0.1, 0.12), (s_ * 0.21, y, 0.17), DK(), bevel=0.01, rot=(0, -s_ * 30, 0))
	def barrel():
		prof = [(0.235, 0), (0.255, 0.06), (0.27, 0.12), (0.285, 0.24), (0.29, 0.35), (0.285, 0.46), (0.27, 0.58), (0.255, 0.64), (0.235, 0.7)]
		staves(prof, (0, 0, 0), n=18, t=0.022, core_to=(0.03, 0.67))
		for z, r in ((0.05, 0.252), (0.17, 0.278), (0.53, 0.278), (0.65, 0.252)):
			kit.ring(r, 0.01, (0, 0, z), IRON("dark"), seg=24)
			for k in range(6):
				a = 2 * math.pi * k / 6 + z * 3
				rivet((math.cos(a) * (r + 0.008), math.sin(a) * (r + 0.008), z), IRON("a"), r=0.007)
		for z in (0.02, 0.68):
			for k in range(4):  # head boards inside the chime
				w = 0.105
				x = -0.1575 + k * w
				half = math.sqrt(max(0.0, 0.214 ** 2 - (abs(x) + w / 2) ** 2))
				B((w - 0.006, 2 * half, 0.014), (x, 0, z), PL("abc"[k % 3]), bevel=0.003)
		B((0.3, 0.05, 0.016), (0, 0, 0.69), DK(), bevel=0.004)
		for x in (-0.12, 0.12):
			rivet((x, 0, 0.698), IRON("dark"), r=0.009)
	group(barrel, at=(0, 0.35, zc), rot=(90, 0, 0))
	kit.cylinder(0.03, 0.03, (0, 0.0, zc + 0.29), DK(), verts=8, bevel=0.004)  # the bung
	# tap on the front head
	tz = zc - 0.13
	rod((0, -0.33, tz), (0, -0.43, tz), 0.016, CU("b"), seg=8)
	rod((0, -0.43, tz + 0.005), (0, -0.44, tz - 0.07), 0.012, CU("b"), seg=8)
	B((0.07, 0.016, 0.016), (0, -0.4, tz + 0.03), CU("dark"), bevel=0.004)
	rod((0, -0.4, tz), (0, -0.4, tz + 0.03), 0.006, CU("dark"))
	kit.cylinder(0.028, 0.012, (0, -0.37, tz), CU("dark"), rot=(90, 0, 0), verts=10, bevel=0.002)
	# the empty drip basin on a block, the funnel upturned on the floor
	board((0.22, 0.2, 0.08), (0, -0.44, 0.04), DK())
	cup((0, -0.44, 0.077), 0.08, 0.05, CU("b"), t=0.005, flare=1.15)
	funnel(0.3, -0.36, 0.0, 1.0)
	stain(0.02, -0.5, 0.07, seed=4)


def lw_lamp_workbench():
	W, D, H = 1.2, 0.6, 0.8
	for x in (-W / 2 + 0.07, W / 2 - 0.07):
		for y in (-D / 2 + 0.07, D / 2 - 0.07):
			LOG((x, y, 0), (x + J(0.008), y, H - 0.04), 0.045, seg=7, rings=2, bend=0.03)
		LOG((x, -D / 2 + 0.07, 0.18), (x, D / 2 - 0.07, 0.18), 0.03, seg=7, rings=1)
	for k in range(5):
		board((W, D / 5 - 0.008, 0.045), (0, -D / 2 + D / 5 * (k + 0.5), H - 0.0225))
	for x in (-W / 2 + 0.07, W / 2 - 0.07):
		for y in (-D / 2 + 0.07, D / 2 - 0.07):
			peghead(x, y, H + 0.0005, 0.012)
	# lower shelf with spare fonts
	for k in range(3):
		board((W - 0.1, 0.15, 0.03), (0, -0.17 + k * 0.165, 0.21))
	for k in range(4):
		x = -0.4 + k * 0.17
		lathe([(0.04, 0), (0.055, 0.008), (0.058, 0.03), (0.045, 0.045), (0.03, 0.052)], (x, 0.0, 0.225), CU("b" if k % 2 else "a"), seg=12)
	# back rail with tools on pegs
	for x in (-W / 2 + 0.07, W / 2 - 0.07):
		B((0.05, 0.04, 0.32), (x, D / 2 - 0.03, H + 0.16), DK(), bevel=0.008)
	board((W - 0.06, 0.03, 0.12), (0, D / 2 - 0.045, H + 0.25), PL("b"))
	for k, x in enumerate((-0.35, -0.12, 0.12, 0.35)):
		rod((x, D / 2 - 0.06, H + 0.25), (x, D / 2 - 0.13, H + 0.26), 0.01, DK())
	B((0.012, 0.012, 0.16), (-0.35, D / 2 - 0.1, H + 0.18), IRON("dark"), bevel=0.002)  # file
	kit.cylinder(0.016, 0.07, (-0.35, D / 2 - 0.1, H + 0.075), PL("c"), verts=8, bevel=0.003)
	kit.ring(0.03, 0.005, (-0.12, D / 2 - 0.1, H + 0.245), IRON("dark"), rot=(90, 0, 0), seg=12)  # snips
	for s_ in (-1, 1):
		B((0.012, 0.01, 0.15), (-0.12 + s_ * 0.012, D / 2 - 0.1, H + 0.14), IRON("a"), bevel=0.002, rot=(0, s_ * 6, 0))
	B((0.1, 0.03, 0.03), (0.12, D / 2 - 0.1, H + 0.282), IRON("dark"), bevel=0.005)  # small hammer
	B((0.022, 0.02, 0.17), (0.12, D / 2 - 0.1, H + 0.185), PL("b"), bevel=0.004)
	kit.ring(0.02, 0.004, (0.35, D / 2 - 0.1, H + 0.248), IRON("dark"), rot=(90, 0, 0), seg=10)  # wick trimmer
	for s_ in (-1, 1):
		B((0.01, 0.008, 0.12), (0.35 + s_ * 0.008, D / 2 - 0.1, H + 0.17), IRON("a"), bevel=0.001, rot=(0, s_ * 5, 0))
	# vise at the right front with a lamp font clamped
	vx = 0.38
	B((0.16, 0.12, 0.05), (vx, -0.2, H + 0.025), IRON("dark"), bevel=0.006)
	for dy in (-0.04, 0.04):
		B((0.14, 0.03, 0.09), (vx, -0.2 + dy * 1.6, H + 0.09), IRON("dark"), bevel=0.006)
	rod((vx, -0.31, H + 0.07), (vx, -0.18, H + 0.07), 0.01, IRON("a"))
	rod((vx - 0.06, -0.31, H + 0.07), (vx + 0.06, -0.31, H + 0.07), 0.007, IRON("a"))
	lamp((vx, -0.2, H + 0.06), 0.8, lit=False, chimney=False)
	# chimneys at the back left, a tray of burners, copper offcuts, snips
	B((0.34, 0.09, 0.014), (-0.33, 0.16, H + 0.006), PL("c"), bevel=0.003)  # a tray the chimneys stand in
	for s_ in (-1, 1):
		B((0.36, 0.012, 0.03), (-0.33, 0.16 + s_ * 0.044, H + 0.016), DK(), bevel=0.003)
		B((0.012, 0.1, 0.03), (-0.33 + s_ * 0.174, 0.16, H + 0.016), DK(), bevel=0.003)
	for k in range(4):
		chimney(-0.45 + k * 0.08, 0.16, H + 0.01)
	B((0.26, 0.16, 0.02), (-0.15, -0.1, H + 0.008), CU("dark"), bevel=0.004)
	for s_ in (-1, 1):
		B((0.27, 0.012, 0.03), (-0.15, -0.1 + s_ * 0.082, H + 0.022), CU("dark"), bevel=0.003)
	for k in range(4):
		x = -0.24 + k * 0.06
		kit.cylinder(0.022, 0.02, (x, -0.1, H + 0.027), IRON("dark"), verts=10, bevel=0.002)
		kit.cylinder(0.032, 0.005, (x, -0.1, H + 0.039), CU("b"), verts=12, bevel=0.0015)
	for k in range(3):
		B((0.07 + k * 0.02, 0.05, 0.003), (0.1 + k * 0.02, 0.1 - k * 0.03, H + 0.0015 + k * 0.004), CU("b"), bevel=0.001, rot=(0, 0, 20 * k - 15))


def lw_wick_twisting_wheel():
	# stand: two A-frame legs on a base board, the axle on top
	board((0.18, 0.7, 0.06), (-0.12, 0.0, 0.03), DK())
	for s_ in (-1, 1):
		LOG((-0.12, s_ * 0.3, 0.05), (-0.12, s_ * 0.11, 0.66), 0.034, seg=7, rings=2, bend=0.02)
		LOG((-0.12, s_ * 0.11, 0.66), (-0.12, s_ * 0.11, 0.62), 0.04, seg=7, rings=1, bend=0)
	LOG((-0.12, -0.3, 0.2), (-0.12, 0.3, 0.2), 0.026, seg=7, rings=1)
	# the wheel: rim, spokes, hub, crank
	ax = (-0.04, 0.0, 0.64)

	def wheel():
		kit.ring(0.34, 0.025, (0, 0, 0), PL("b"), seg=28)
		kit.ring(0.355, 0.006, (0, 0, 0), IRON("dark"), seg=28)
		kit.cylinder(0.05, 0.08, (0, 0, 0), DK(), verts=12, bevel=0.006)
		for k in range(8):
			a = 2 * math.pi * k / 8
			LOG((math.cos(a) * 0.04, math.sin(a) * 0.04, 0), (math.cos(a) * 0.33, math.sin(a) * 0.33, 0), 0.013, PL("c"), seg=6, rings=1, bend=0)
	group(wheel, at=ax, rot=(0, 90, 0))
	rod((-0.16, 0, 0.64), (0.06, 0, 0.64), 0.016, IRON("dark"))
	B((0.025, 0.03, 0.18), (0.07, 0, 0.58), IRON("dark"), bevel=0.003)
	LOG((0.07, 0, 0.5), (0.17, 0, 0.5), 0.016, PL("b"), seg=6, rings=1)
	# drive band from the wheel down to a whorl on the twisting head
	hx, hy, hz = -0.04, -0.62, 0.42
	board((0.14, 0.14, 0.05), (-0.04, -0.62, 0.025), DK())
	LOG((-0.04, -0.62, 0.05), (-0.04, -0.62, 0.36), 0.035, seg=7, rings=2, bend=0.02)
	board((0.1, 0.16, 0.08), (-0.04, -0.62, 0.38), PL())
	board((0.14, 0.7, 0.034), (-0.07, -0.31, 0.03), DK())
	kit.cylinder(0.04, 0.04, (hx, hy + 0.1, hz + 0.02), DK(), rot=(90, 0, 0), verts=12, bevel=0.004)
	rod((hx, hy - 0.08, hz + 0.02), (hx, hy + 0.14, hz + 0.02), 0.007, IRON("dark"))
	kit.ring(0.018, 0.004, (hx, hy + 0.152, hz + 0.02), IRON("dark"), rot=(0, 90, 0), seg=10)
	kit.rope((-0.04, -0.06, 0.97), (hx, hy + 0.1, hz + 0.06), 0.005)
	kit.rope((-0.04, -0.06, 0.31), (hx, hy + 0.1, hz - 0.02), 0.005)
	# the spool rack behind: three spools, strands running to the hook
	sx, sy = -0.04, 0.55
	board((0.3, 0.12, 0.04), (sx, sy, 0.02), DK())
	for s_ in (-1, 1):
		LOG((sx + s_ * 0.13, sy, 0.04), (sx + s_ * 0.13, sy, 0.62), 0.025, seg=7, rings=2, bend=0.02)
	LOG((sx - 0.15, sy, 0.62), (sx + 0.15, sy, 0.62), 0.022, seg=7, rings=1)
	ms = (WICK(), WAXWICK(), WICK())
	for k, z in enumerate((0.18, 0.33, 0.48)):
		rod((sx - 0.13, sy, z), (sx + 0.13, sy, z), 0.008, DK())
		spool((sx, sy, z), 0.035, 0.08, "x", ms[k])
		kit.rope((sx, sy - 0.03, z + 0.01), (hx, hy + 0.165, hz + 0.02), 0.0035)


def lw_ore_sorting_table():
	W, D, H, ang = 1.2, 0.7, 0.8, 12
	sn = math.sin(math.radians(ang))
	for x in (-W / 2 + 0.07, W / 2 - 0.07):
		for y in (-D / 2 + 0.08, D / 2 - 0.08):
			LOG((x, y, 0), (x, y, H + y * sn - 0.03), 0.045, seg=7, rings=2, bend=0.03)
		LOG((x, -D / 2 + 0.08, 0.2), (x, D / 2 - 0.08, 0.2), 0.03, seg=7, rings=1)
	LOG((-W / 2 + 0.07, D / 2 - 0.08, 0.2), (W / 2 - 0.07, D / 2 - 0.08, 0.2), 0.03, seg=7, rings=1)

	def top():
		for k in range(5):
			board((W, D / 5 - 0.006, 0.04), (0, -D / 2 + D / 5 * (k + 0.5), -0.02))
		for s_ in (-1, 1):
			board((W + 0.04, 0.04, 0.12), (0, s_ * (D / 2 + 0.02), 0.04), DK())
			board((0.04, D, 0.12), (s_ * (W / 2 + 0.02), 0, 0.04), DK())
		for k in range(3):  # bin dividers at the front
			x = -W / 2 + W / 4 * (k + 1)
			board((0.025, 0.28, 0.07), (x, -D / 2 + 0.14, 0.035), PL("b"))
		board((W, 0.025, 0.07), (0, -D / 2 + 0.29, 0.035), PL("b"))
		for s_ in (-1, 1):
			for x in (-W / 2 + 0.05, W / 2 - 0.05):
				peghead(x, s_ * (D / 2 + 0.041), 0.06, 0.011)
		ore_pile(0.0, 0.13, 0.0, 0.8, 0.26, layers=3, seed=9)
		bins = (lambda i: COAL(), lambda i: T("brownrock", "abc"[i % 3]), lambda i: C((0.42, 0.22, 0.12), 0.8) if i % 2 else T("stone", "b"),
			lambda i: T("stone", "abc"[i % 3]))
		for k in range(4):
			x = -W / 2 + W / 8 * (2 * k + 1)
			ore_pile(x, -D / 2 + 0.14, 0.0, 0.22, 0.22, layers=2, seed=20 + k, mats=bins[k], smin=0.025, smax=0.05)
			if k == 2:
				for j in range(4):
					kit.gem((x - 0.06 + j * 0.04, -D / 2 + 0.12, 0.05), (0.02, 0.018, 0.015), CU("b"), seed=j + 40)
		# the rake lying on the heap
		LOG((-0.45, 0.25, 0.1), (0.25, 0.0, 0.13), 0.016, PL("b"), seg=6, rings=1, bend=0)
		B((0.04, 0.2, 0.025), (0.27, -0.01, 0.12), IRON("dark"), bevel=0.003, rot=(0, 0, -20))
		for j in range(5):
			B((0.012, 0.012, 0.05), (0.28, -0.09 + j * 0.04, 0.095), IRON("dark"), bevel=0.002, rot=(0, 0, -20))
	group(top, at=(0, 0, H), rot=(ang, 0, 0))


def lw_ore_sieve_cradle():
	def rocker():
		pts = []
		for k in range(13):
			x = -0.45 + 0.9 * k / 12
			pts.append((x, 0.07 * (x / 0.45) ** 2))
		pts += [(0.45, 0.13), (-0.45, 0.13)]
		v = [(x, -0.025, z) for x, z in pts] + [(x, 0.025, z) for x, z in pts]
		n = len(pts)
		f = [tuple(range(n)), tuple(range(2 * n - 1, n - 1, -1))] + [(i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n)]
		mesh(v, f, DK())
	for y in (-0.2, 0.2):
		group(rocker, at=(0, y, 0.0))
	z0 = 0.12
	for s_ in (-1, 1):
		board((0.86, 0.03, 0.18), (0, s_ * 0.24, z0 + 0.09), PL())
		board((0.03, 0.45, 0.18), (s_ * 0.43, 0, z0 + 0.09), PL())
		for x in (-0.43, 0.43):
			peghead(x, s_ * 0.255, z0 + 0.12, 0.011)
	for k in range(9):
		rod((-0.42, -0.2 + k * 0.05, z0 + 0.02), (0.42, -0.2 + k * 0.05, z0 + 0.02), 0.006, IRON("dark"), seg=5)
	for k in range(11):
		x = -0.4 + k * 0.08
		rod((x, -0.235, z0 + 0.032), (x, 0.235, z0 + 0.032), 0.006, IRON("dark"), seg=5)
	for s_ in (-1, 1):
		B((0.84, 0.04, 0.02), (0, s_ * 0.21, z0 + 0.01), IRON("dark"), bevel=0.003)
	ore_pile(0.05, 0.0, z0 + 0.035, 0.5, 0.3, layers=1, seed=12, smin=0.04, smax=0.07)
	# push pole fixed to one end
	for s_ in (-1, 1):
		rod((0.445, s_ * 0.15, z0 + 0.13), (0.7, s_ * 0.04, z0 + 0.34), 0.016, PL("b"), seg=6)
	LOG((0.7, -0.08, z0 + 0.34), (0.7, 0.08, z0 + 0.34), 0.022, PL("b"), seg=7, rings=1)
	# the catch trough under the front end of the rockers
	board((0.06, 0.2, 0.06), (-0.62, -0.0, 0.03), DK())
	board((0.32, 0.5, 0.025), (-0.62, 0.0, 0.0125), PL())
	for s_ in (-1, 1):
		board((0.32, 0.02, 0.07), (-0.62, s_ * 0.24, 0.045), PL())
		board((0.02, 0.48, 0.07), (-0.62 + s_ * 0.15, 0, 0.045), PL())
	ore_pile(-0.62, 0.0, 0.025, 0.24, 0.4, layers=1, seed=13, smin=0.018, smax=0.03)


def lw_rail_switch_lever():
	Lg = 1.5
	z = sleepers(-Lg / 2, Lg / 2, 1.05, 6)
	g = 0.25
	rail_seg((-g, -Lg / 2), (-g, Lg / 2), z)
	rail_seg((g, -Lg / 2), (g, Lg / 2), z)
	ang = math.radians(9)
	# the branch: its outer rail curves right, its inner rail stops short of the main rail (the frog gap)
	y0 = -0.1
	rail_seg((g + 0.06, y0), (g + 0.06 + math.tan(ang) * (Lg / 2 - y0), Lg / 2), z)
	rail_seg((-g + 0.06, y0 + 0.05), (-g + 0.06 + math.tan(ang) * 0.38, y0 + 0.43), z)
	# switch blades: thin tapered rails pivoting at their heels
	for x in (-g + 0.045, g + 0.045):
		B((0.026, 0.62, 0.045), (x, -0.42, z + 0.04), IRON("a"), bevel=0.003, rot=(0, 0, 3))
	B((0.6, 0.03, 0.02), (0.05, -0.65, z + 0.021), IRON("dark"), bevel=0.003)  # tie bar
	for x in (-g + 0.03, g + 0.03):
		rivet((x, -0.65, z + 0.022), IRON("a"), r=0.01)
	for k in range(6):
		y = -Lg / 2 + Lg * (k + 0.5) / 6
		for x in (-g, g):
			for s_ in (-1, 1):
				kit.cylinder(0.012, 0.012, (x + s_ * 0.04, y, z + 0.008), IRON("dark"), verts=6, bevel=0.002)
	# the throw lever on its block beside the track
	bx, by = -0.72, -0.62
	board((0.3, 0.22, 0.16), (bx, by, 0.08), DK())
	B((0.62, 0.025, 0.02), (bx + 0.36, -0.662, 0.07), IRON("dark"), bevel=0.003)
	# owner note (Nov 22): avoid rails in NEW decor; this one keeps its track.
	# the lever sits IN an iron fork bolted to the block: base plate, two cheeks, a pin through cheeks and hub
	B((0.24, 0.16, 0.014), (bx, by, 0.166), IRON("dark"), bevel=0.003)
	for sx in (-1, 1):
		for sy in (-1, 1):
			rivet((bx + sx * 0.1, by + sy * 0.06, 0.173), IRON("a"), r=0.008)
	for sy in (-1, 1):
		B((0.2, 0.014, 0.13), (bx, by + sy * 0.032, 0.235), IRON("dark"), bevel=0.003)
		kit.cylinder(0.018, 0.008, (bx, by + sy * 0.042, 0.22), IRON("a"), rot=(90, 0, 0), verts=8, bevel=0.002)
	rod((bx, by - 0.05, 0.22), (bx, by + 0.05, 0.22), 0.012, IRON("a"))
	kit.cylinder(0.03, 0.056, (bx, by, 0.22), IRON("dark"), rot=(90, 0, 0), verts=10, bevel=0.003)  # the hub
	rod((bx, by, 0.22), (bx + 0.2, by, 0.64), 0.016, IRON("dark"))
	sphere((bx + 0.075, by, 0.377), 0.05, IRON("dark"), seg=10, rings=7)
	LOG((bx + 0.195, by, 0.63), (bx + 0.24, by, 0.73), 0.022, PL("b"), seg=7, rings=1)


def lw_signal_lamp_post():
	for k in range(2):
		board((0.9, 0.12, 0.08), (0, 0, 0.04 + k * 0.0), DK() if k else PL(), rot=(0, 0, 90 * k))
	for k in range(4):
		a = math.pi / 2 * k
		LOG((math.cos(a) * 0.36, math.sin(a) * 0.36, 0.07), (math.cos(a) * 0.06, math.sin(a) * 0.06, 0.55), 0.025, seg=6, rings=1, bend=0)
		peghead(math.cos(a) * 0.4, math.sin(a) * 0.4, 0.08, 0.012)
	LOG((0, 0, 0.0), (0, 0, 1.75), 0.065, seg=9, rings=4, bend=0.03)
	LOG((-0.42, 0, 1.62), (0.42, 0, 1.62), 0.04, seg=8, rings=2, bend=0.02)
	for s_ in (-1, 1):
		LOG((s_ * 0.05, 0, 1.38), (s_ * 0.3, 0, 1.6), 0.022, seg=6, rings=1, bend=0)
		rod((s_ * 0.34, 0, 1.6), (s_ * 0.34, 0, 1.53), 0.006, IRON("dark"))
		kit.ring(0.018, 0.005, (s_ * 0.34, 0, 1.52), IRON("dark"), rot=(90, 0, 0), seg=10)
		lamp((s_ * 0.34, 0, 1.52 + 0.013 - 0.028 - 0.21), 1.0)
	# a copper shutter half-closed on the right lamp
	B((0.07, 0.006, 0.09), (0.34, -0.04, 1.4), CU("dark"), bevel=0.002, rot=(0, 0, 25))
	rod((0.34, -0.03, 1.45), (0.34, 0.0, 1.47), 0.004, CU("dark"))
	# a wick-tin box on a bracket half way up
	B((0.12, 0.06, 0.02), (0, -0.09, 0.95), DK(), bevel=0.004)
	kit.cylinder(0.04, 0.06, (0, -0.1, 0.99), CU("b"), verts=12, bevel=0.003)
	kit.cylinder(0.043, 0.015, (0, -0.1, 1.022), CU("dark"), verts=12, bevel=0.003)
	for s_ in (-1, 1):
		B((0.02, 0.06, 0.06), (s_ * 0.05, -0.08, 0.92), DK(), bevel=0.004, rot=(-30, 0, 0))
	for z in (0.3, 1.2):
		kit.ring(0.07, 0.009, (0, 0, z), IRON("dark"), seg=14)


def lw_walkway_ladder():
	Hh, ang = 1.95, 15
	dy = Hh * math.tan(math.radians(ang))
	for x in (-0.24, 0.24):
		stone_ = B((0.16, 0.16, 0.06), (x, -dy, 0.03), T("shackstone"), bevel=0.02)
		LOG((x, -dy, 0.05), (x, 0.0, Hh), 0.04, seg=8, rings=4, bend=0.02)
		rod((x, 0.0, Hh - 0.03), (x, 0.09, Hh + 0.03), 0.012, IRON("dark"))
		rod((x, 0.09, Hh + 0.03), (x, 0.12, Hh - 0.04), 0.012, IRON("dark"))
		kit.ring(0.045, 0.008, (x, -0.0, Hh - 0.05), IRON("dark"), rot=(ang, 0, 0), seg=12)
	for k in range(7):
		t = (k + 0.7) / 7.6
		z = 0.05 + (Hh - 0.05) * t
		y = -dy + dy * t
		if k == 3:  # a snapped rung: two halves still pegged, splintered ends
			for s_ in (-1, 1):
				board((0.2, 0.06, 0.035), (s_ * 0.15, y, z), PL(), rot=(0, s_ * 12, 0))
				splinters((s_ * 0.05, y, z - s_ * 0.0), (-s_, 0, -0.2), n=3, r=0.02)
			continue
		board((0.56, 0.065, 0.035), (0, y, z), PL("b" if k % 2 else "a"))
		for x in (-0.24, 0.24):
			peghead(x, y - 0.033, z, 0.01)
	# rope hand rail tied along the right side
	x = 0.3
	kit.rope((x, -dy + 0.03, 0.4), (x, -0.02, Hh - 0.1), 0.012)
	for z, y in ((0.4, -dy + 0.03), (Hh - 0.1, -0.02)):
		kit.ring(0.04, 0.009, (x - 0.04, y, z), kit.tex_mat("rope", "a"), rot=(0, 90, 0), seg=10)
	# a lamp on a hook on the left rail
	ty = -dy * (1 - 1.15 / Hh)
	rod((-0.24, ty, 1.15), (-0.36, ty - 0.02, 1.17), 0.008, IRON("dark"))
	rod((-0.36, ty - 0.02, 1.17), (-0.36, ty - 0.02, 1.12), 0.008, IRON("dark"))
	kit.ring(0.016, 0.004, (-0.36, ty - 0.02, 1.11), IRON("dark"), rot=(90, 0, 0), seg=10)
	lamp((-0.36, ty - 0.02, 1.11 - 0.012 - 0.21 * 0.9 + 0.0 - 0.0), 0.9)


def lw_rest_nook_bench():
	W = 1.3
	for x in (-W / 2 + 0.05, W / 2 - 0.05):
		LOG((x, 0.12, 0), (x, 0.12, 1.25), 0.05, seg=8, rings=3, bend=0.02)
		LOG((x, -0.22, 0), (x, -0.22, 0.62), 0.045, seg=7, rings=2, bend=0.02)
		LOG((x, -0.25, 0.62), (x, 0.15, 0.62), 0.032, seg=7, rings=1)
		LOG((x, -0.22, 0.15), (x, 0.12, 0.15), 0.03, seg=7, rings=1)
	for k in range(2):
		board((W - 0.02, 0.17, 0.045), (0, -0.14 + k * 0.175, 0.42))
	LOG((-W / 2 + 0.05, -0.22, 0.38), (W / 2 - 0.05, -0.22, 0.38), 0.035, seg=7, rings=1)
	for k in range(3):
		board((W - 0.06, 0.035, 0.14), (0, 0.15, 0.56 + k * 0.15), PL("b" if k % 2 else "a"))
	for k in range(3):
		for x in (-W / 2 + 0.05, W / 2 - 0.05):
			peghead(x, 0.131, 0.56 + k * 0.15, 0.011)
	for x in (-W / 2 + 0.12, W / 2 - 0.12):
		for y in (-0.14, 0.035):
			peghead(x, y, 0.4425, 0.011)
	# the shelf above
	t = 1.08
	board((W - 0.02, 0.2, 0.035), (0, 0.07, t))
	for x in (-W / 2 + 0.05, W / 2 - 0.05):
		B((0.05, 0.16, 0.05), (x, 0.07, t - 0.04), DK(), bevel=0.006)
	t += 0.0175
	lamp((-0.35, 0.07, t - 0.002), 0.9, lit=False)
	lunch_tin(0.05, 0.07, t - 0.002)
	B((0.12, 0.1, 0.004), (0.32, 0.07, t + 0.0), IRON("a"), bevel=0.001)
	for k in range(2):
		peg(0.3 + k * 0.2, 0.9, y0=0.132, ln=0.06)
	kit.ring(0.025, 0.005, (0.3, 0.09, 0.905), IRON("dark"), rot=(90, 0, 0), seg=10)
	cup((0.3, 0.09, 0.82), 0.032, 0.07, IRON("a"), t=0.004)
	rod((0.3, 0.09, 0.89), (0.3, 0.09, 0.905), 0.004, IRON("dark"))
	kit.ring(0.02, 0.005, (0.5, 0.09, 0.905), kit.tex_mat("leather", "dark"), rot=(90, 0, 0), seg=10)
	LOG((0.5, 0.09, 0.885), (0.5, 0.09, 0.7), 0.02, PL("c"), seg=6, rings=1)
	B((0.11, 0.02, 0.05), (0.5, 0.09, 0.67), IRON("dark"), bevel=0.004)


def lw_lamp_barrow():
	# wheel at the front
	wy, wz, wr = -0.48, 0.19, 0.19

	def wheel():
		for k in range(3):
			y = -wr + 2 * wr * (k + 0.5) / 3
			half = math.sqrt(wr * wr - y * y) - 0.004
			B((0.05, 2 * half, 2 * wr / 3 - 0.006), (0, 0, y), PL(), bevel=0.006)
		kit.ring(wr, 0.012, (0, 0, 0), IRON("dark"), rot=(0, 90, 0), seg=22)
		for s_ in (-1, 1):
			B((0.008, 2 * wr * 0.85, 0.03), (s_ * 0.028, 0, 0), IRON("dark"), bevel=0.002)
		kit.cylinder(0.045, 0.08, (0, 0, 0), DK(), rot=(0, 90, 0), verts=10, bevel=0.005)
	group(wheel, at=(0, wy, wz))
	rod((-0.07, wy, wz), (0.07, wy, wz), 0.014, IRON("dark"))
	# handles from the axle to the back
	for s_ in (-1, 1):
		LOG((s_ * 0.08, wy - 0.02, wz), (s_ * 0.24, 0.75, 0.5), 0.032, seg=7, rings=3, bend=0.02)
		LOG((s_ * 0.22, 0.25, 0.39), (s_ * 0.22, 0.27, 0.0), 0.03, seg=7, rings=2, bend=0.02)
	# the tray with dividers, six lamps in it
	tz = 0.31
	board((0.48, 0.5, 0.03), (0, -0.02, tz))
	for s_ in (-1, 1):
		board((0.5, 0.025, 0.14), (0, -0.02 + s_ * 0.25, tz + 0.07))
		board((0.025, 0.5, 0.14), (s_ * 0.24, -0.02, tz + 0.07))
	board((0.46, 0.02, 0.1), (0, -0.02, tz + 0.06), PL("b"))
	for x in (-0.08, 0.08):
		board((0.02, 0.48, 0.1), (x, -0.02, tz + 0.06), PL("b"))
	for i, x in enumerate((-0.16, 0.0, 0.16)):
		for j, y in enumerate((-0.145, 0.105)):
			lamp((x, y, tz + 0.015), 0.85, lit=False, chimney=not (i == 2 and j == 0))
	for s_ in (-1, 1):
		for y in (-0.25, 0.2):
			peghead(s_ * 0.253, y, tz + 0.1, 0.01)


def lw_oil_can_crate():
	crate(0.62, 0.42, 0.24, (0, 0, 0))
	for i in range(3):
		for j in range(2):
			x, y = -0.18 + i * 0.18, -0.09 + j * 0.18
			if (i, j) == (1, 1):
				disc(0.045, 0.03, 0.033, (x, y), STAIN(), seg=14, wob=0.1)
				continue
			oil_can(x, y, 0.03, 1.15)
	funnel(-0.18, -0.09, 0.03 + 0.125 * 1.15 + 0.012, 0.6, up=True)
	# lid leaning on the right side
	def lid():
		for k in range(3):
			board((0.14, 0.022, 0.6), (-0.15 + k * 0.15, 0, 0.3), PL())
		for z in (0.08, 0.52):
			board((0.44, 0.025, 0.06), (0, -0.022, z), DK())
			for x in (-0.15, 0.0, 0.15):
				peghead(x, -0.035, z, 0.009)
	group(lid, at=(0.34, 0.0, 0.0), rot=(0, -20, 90))


def lw_chimney_crate():
	crate(0.56, 0.42, 0.18, (0, 0, 0))
	for i in range(1, 4):
		board((0.015, 0.38, 0.13), (-0.28 + 0.14 * i, 0, 0.1), PL("b"))
	for j in range(1, 3):
		board((0.52, 0.015, 0.13), (0, -0.21 + 0.14 * j, 0.1), PL("b"))
	for i in range(4):
		for j in range(3):
			x, y = -0.21 + 0.14 * i, -0.14 + 0.14 * j
			if (i, j) in ((1, 2), (3, 0)):
				continue
			if (i, j) == (2, 1):
				broken_chimney(x, y, 0.03, 1.2)
				continue
			chimney(x, y, 0.03, 1.2)
	shards(0.0, -0.36, 7, 0.08, 11)

	def lid():
		top = None
		for k in range(3):
			o = board((0.18, 0.022, 0.44), (-0.18 + k * 0.18, 0, 0.22), PL())
			if k == 1:
				top = o
		for z in (0.06, 0.38):
			board((0.56, 0.025, 0.06), (0, -0.022, z), DK())
		cut(top, (0.05, 0.01, 0.06), (0, -0.011, 0.2))
		cut(top, (0.03, 0.01, 0.06), (0, -0.011, 0.26))
		cut(top, (0.025, 0.01, 0.025), (0, -0.011, 0.31), rot=(0, 45, 0))
	group(lid, at=(0.0, 0.45, 0.011), rot=(-90, 0, 0))


def lw_bell_frame():
	for x in (-0.45, 0.45):
		board((0.12, 0.6, 0.08), (x, 0, 0.04), DK())
		LOG((x, 0, 0.06), (x, 0, 1.55), 0.055, seg=8, rings=4, bend=0.02)
		for s_ in (-1, 1):
			LOG((x, s_ * 0.27, 0.07), (x, s_ * 0.04, 0.6), 0.025, seg=6, rings=1, bend=0)
			peghead(x, s_ * 0.27, 0.085, 0.011)
	LOG((-0.55, 0, 1.58), (0.55, 0, 1.58), 0.06, seg=9, rings=2, bend=0.02)
	for s_ in (-1, 1):
		LOG((s_ * 0.44, 0, 1.25), (s_ * 0.2, 0, 1.55), 0.025, seg=6, rings=1, bend=0)
	# iron strap hanger and a short yoke with the bell under it
	for s_ in (-1, 1):
		B((0.03, 0.012, 0.2), (0, s_ * 0.064, 1.52), IRON("dark"), bevel=0.003)
		rivet((0, s_ * 0.071, 1.47), IRON("a"), r=0.01)
	board((0.24, 0.1, 0.08), (0, 0, 1.42), PL("b"))
	for s_ in (-1, 1):
		B((0.03, 0.11, 0.1), (s_ * 0.09, 0, 1.4), IRON("dark"), bevel=0.003)
	bell((0, 0, 1.2), 1.25)
	# pull rope from a lever on the yoke down to a wooden handle
	rod((0.1, 0, 1.4), (0.24, 0, 1.36), 0.01, IRON("dark"))
	kit.rope((0.24, 0, 1.36), (0.24, 0, 0.55), 0.009)
	kit.ring(0.016, 0.005, (0.24, 0, 1.36), kit.tex_mat("rope", "a"), rot=(0, 90, 0), seg=8)
	LOG((0.24, 0, 0.55), (0.24, 0, 0.42), 0.022, PL("c"), seg=7, rings=1)


def lw_ledger_desk():
	H = 1.05
	for x in (-0.28, 0.28):
		LOG((x, 0.15, 0), (x, 0.15, H + 0.06), 0.04, seg=7, rings=3, bend=0.02)
		LOG((x, -0.18, 0), (x, -0.18, H - 0.06), 0.04, seg=7, rings=3, bend=0.02)
		LOG((x, -0.18, 0.22), (x, 0.15, 0.22), 0.028, seg=6, rings=1)
	LOG((-0.28, 0.15, 0.22), (0.28, 0.15, 0.22), 0.028, seg=6, rings=1)

	def top():
		for k in range(4):
			board((0.7, 0.1, 0.035), (0, -0.15 + k * 0.1, 0))
		board((0.7, 0.03, 0.04), (0, -0.21, 0.03), DK())
		# open ledger: two thick covers + page blocks, lines cut in
		for s_ in (-1, 1):
			B((0.2, 0.28, 0.012), (s_ * 0.1, -0.03, 0.024), kit.tex_mat("leather", "dark"), bevel=0.003)
			pg = B((0.18, 0.26, 0.02), (s_ * 0.1, -0.03, 0.039), PAPER(), bevel=0.004)
			for k in range(6):
				cut(pg, (0.13 - 0.03 * (k % 2), 0.006, 0.006), (s_ * 0.1, -0.12 + k * 0.035, 0.049))
		kit.cylinder(0.01, 0.28, (0, -0.03, 0.04), kit.tex_mat("leather", "dark"), rot=(90, 0, 0), verts=8, bevel=0)
	group(top, at=(0, -0.02, H), rot=(14, 0, 0))
	# flat back shelf: ink pot, quill, lamp
	board((0.72, 0.16, 0.035), (0, 0.15, H + 0.08))
	s = H + 0.0975
	kit.cylinder(0.032, 0.05, (0.2, 0.15, s + 0.025), kit.tex_mat("iron", "dark"), verts=10, bevel=0.005)
	kit.cylinder(0.012, 0.012, (0.2, 0.15, s + 0.055), IRON("a"), verts=8, bevel=0.002)
	rod((0.2, 0.15, s + 0.045), (0.25, 0.12, s + 0.2), 0.003, PAPER(), seg=4)
	kit.cone(0.012, 0.002, 0.1, (0.24, 0.125, s + 0.16), C((0.62, 0.58, 0.5), 0.9), rot=(15, 15, 0), verts=4, bevel=0)
	lamp((-0.22, 0.15, s - 0.002), 0.9)
	# tally of finished lamps cut into the left post side
	post = B((0.07, 0.05, 0.4), (-0.32, 0.15, 0.6), PL("b"), bevel=0.006)
	for k in range(9):  # bundles of four strokes and a cross stroke
		if k % 5 == 4:
			cut(post, (0.004, 0.04, 0.012), (-0.355, 0.15, 0.5 + (k // 5) * 0.12 + 0.0))
		else:
			cut(post, (0.004, 0.008, 0.06), (-0.355, 0.135 + (k % 5) * 0.009, 0.5 + (k // 5) * 0.12))


def lw_ore_bucket_hoist():
	# A-frame on two base boards, a drum with a crank and ratchet
	for x in (-0.38, 0.38):
		board((0.12, 0.9, 0.07), (x, 0.0, 0.035), DK())
		for s_ in (-1, 1):
			LOG((x, s_ * 0.38, 0.06), (x, 0.0, 1.25), 0.045, seg=8, rings=3, bend=0.02)
			peghead(x, s_ * 0.42, 0.071, 0.012)
		LOG((x, -0.25, 0.42), (x, 0.25, 0.42), 0.03, seg=7, rings=1)
	LOG((-0.48, 0.0, 1.28), (0.48, 0.0, 1.28), 0.07, seg=10, rings=3, bend=0.01)
	for x in (-0.18, 0.18):
		kit.ring(0.075, 0.008, (x, 0, 1.28), IRON("dark"), rot=(0, 90, 0), seg=16)
	for k in range(6):
		kit.ring(0.078, 0.011, (-0.1 + k * 0.022, 0, 1.28), kit.tex_mat("rope", "a"), rot=(0, 90, 0), seg=16)
	rod((0.48, 0, 1.28), (0.56, 0, 1.28), 0.016, IRON("dark"))
	B((0.025, 0.03, 0.22), (0.565, 0, 1.2), IRON("dark"), bevel=0.003)
	LOG((0.565, 0, 1.11), (0.67, 0, 1.11), 0.018, PL("b"), seg=6, rings=1)
	gear((-0.44, 0, 1.28), 0.1, 0.03, IRON("dark"), rot=(0, 90, 0), n=10)
	rod((-0.44, 0.0, 1.17), (-0.44, -0.04, 1.12), 0.012, IRON("a"))
	rod((-0.44, 0.0, 1.17), (-0.44, -0.13, 1.08), 0.01, IRON("a"))
	# rope down to the bucket hanging in front
	kit.rope((0.0, -0.075, 1.28), (0.0, -0.075, 0.62), 0.011)
	bx, by, bz = 0.0, -0.075, 0.18
	staves([(0.15, 0), (0.165, 0.15), (0.18, 0.3)], (bx, by, bz), n=12, t=0.016, gap=0.003, core_to=(0.012, 0.14))
	kit.cylinder(0.14, 0.02, (bx, by, bz + 0.02), DK(), verts=16, bevel=0.003)
	for z in (0.05, 0.25):
		kit.ring(0.153 + 0.1 * z, 0.008, (bx, by, bz + z), IRON("dark"), seg=18)
	for s_ in (-1, 1):
		B((0.03, 0.03, 0.04), (bx + s_ * 0.18, by, bz + 0.28), IRON("dark"), bevel=0.003)
	log((bx - 0.18, by, bz + 0.29), (bx, by, bz + 0.45), 0.008, IRON("dark"), seg=5, rings=1, ends=False, bend=0)
	log((bx + 0.18, by, bz + 0.29), (bx, by, bz + 0.45), 0.008, IRON("dark"), seg=5, rings=1, ends=False, bend=0)
	kit.ring(0.03, 0.008, (bx, by, bz + 0.46), IRON("dark"), rot=(90, 0, 0), seg=10)
	kit.ring(0.025, 0.006, (bx, by, 0.64), IRON("dark"), rot=(0, 90, 0), seg=10)
	rod((bx, by, 0.62), (bx, by, 0.66), 0.006, IRON("dark"))
	ore_pile(bx, by, bz + 0.12, 0.26, 0.26, layers=2, seed=31, smin=0.035, smax=0.06)


# ================= story pieces =================
def lw_lamp_fallen_spill():
	def stand():
		for k in range(2):
			board((0.6, 0.1, 0.06), (0, 0, 0.03), DK() if k else PL(), rot=(0, 0, 90 * k))
		LOG((0, 0, 0.05), (0, 0, 1.4), 0.04, seg=8, rings=3, bend=0.02)
		for k in range(4):
			a = math.pi / 2 * k
			LOG((math.cos(a) * 0.24, math.sin(a) * 0.24, 0.06), (math.cos(a) * 0.04, math.sin(a) * 0.04, 0.4), 0.018, seg=6, rings=1, bend=0)
		LOG((0, 0, 1.36), (0.3, 0, 1.36), 0.022, seg=6, rings=1)
		rod((0.28, 0, 1.36), (0.28, 0, 1.3), 0.006, IRON("dark"))
		kit.ring(0.02, 0.005, (0.28, 0, 1.29), IRON("dark"), rot=(90, 0, 0), seg=10)
	tipped(stand, "X", 84, pivot=(0, 0, 0), at=(-0.15, 0.25))
	# the lamp on its side, chimney gone, glass all round, the oil it spilled
	stain(0.05, -0.45, 0.24, seed=6)
	group(lambda: lamp((0, 0, 0), 1.0, lit=False, chimney=False), at=(0.0, -0.4, 0.058), rot=(0, 95, 30))
	broken_chimney(0.25, -0.62, 0.0, 1.0)
	shards(0.12, -0.55, 12, 0.18, 7)
	group(lambda: lathe([(0.034, 0.0), (0.022, 0.035)], (0, 0, 0), GLASS(), seg=12), at=(-0.2, -0.6, 0.03), rot=(0, 80, 0))


def lw_cart_jammed():
	top = track(2.0)
	# the cart on the rails (wheels on the rail heads)
	g, wr = 0.25, 0.11
	az = top + wr
	cy = -0.15
	w, d, h = 0.7, 0.95, 0.42
	zb = az + 0.04
	for sy in (-1, 1):
		yy = cy + sy * (d / 2 - 0.2)
		rod((-g - 0.04, yy, az), (g + 0.04, yy, az), 0.018, IRON())
		for sx in (-1, 1):
			kit.cylinder(wr, 0.04, (sx * g, yy, az), IRON("dark"), rot=(0, 90, 0), verts=14, bevel=0.004)
			kit.cylinder(wr + 0.015, 0.012, (sx * (g - 0.026), yy, az), IRON("dark"), rot=(0, 90, 0), verts=14, bevel=0.002)
			kit.cylinder(0.035, 0.06, (sx * (g + 0.02), yy, az), IRON("a"), rot=(0, 90, 0), verts=8, bevel=0.003)
			B((0.1, 0.09, 0.06), (sx * 0.15, yy, az + 0.04), DK(), bevel=0.006)
	B((w - 0.04, d - 0.04, 0.04), (0, cy, zb + 0.02), DK(), bevel=0.006)
	ph = (h - 0.04) / 3
	for k in range(3):
		zz = zb + 0.04 + ph * (k + 0.5)
		for s_ in (-1, 1):
			board((0.03, d, ph - 0.008), (s_ * (w / 2 - 0.015), cy, zz))
			board((w - 0.06, 0.03, ph - 0.008), (0, cy + s_ * (d / 2 - 0.015), zz))
	zt = zb + h
	for s_ in (-1, 1):
		B((0.056, d + 0.02, 0.03), (s_ * (w / 2 - 0.016), cy, zt - 0.01), IRON("dark"), bevel=0.003)
		B((w - 0.1, 0.056, 0.03), (0, cy + s_ * (d / 2 - 0.016), zt - 0.016), IRON("dark"), bevel=0.003)
		for cx in (-1, 1):
			B((0.06, 0.008, h - 0.02), (cx * (w / 2 - 0.03), cy + s_ * (d / 2 + 0.003), zb + h / 2), IRON("dark"), bevel=0.002)
			B((0.008, 0.06, h - 0.02), (cx * (w / 2 + 0.003), cy + s_ * (d / 2 - 0.03), zb + h / 2), IRON("dark"), bevel=0.002)
			for k in range(3):
				rivet((cx * (w / 2 - 0.03), cy + s_ * (d / 2 + 0.008), zb + 0.08 + k * 0.13), IRON("a"), r=0.008)
		kit.ring(0.03, 0.009, (0, cy + s_ * (d / 2 + 0.04), zb + 0.1), IRON("dark"), rot=(0, 90, 0), seg=10)
		B((0.06, 0.05, 0.04), (0, cy + s_ * (d / 2 + 0.012), zb + 0.1), IRON("dark"), bevel=0.004)
	before = objs()
	ore_pile(0, cy, zb + 0.04, w - 0.1, d - 0.12, layers=3, seed=17, smin=0.045, smax=0.07)
	for o in objs() - before:  # lumps stay angular with 60% of their faces (file under 2 MB)
		o.modifiers.new("few", "DECIMATE").ratio = 0.6
	# the fallen roof prop lies ON TOP of the cart, across both side rims (owner: not inside it)
	lz = zt + 0.005 + 0.11 - 0.006
	p0 = Vector((-0.8, cy + 0.22, lz))
	p1 = Vector((0.95, cy - 0.12, lz))
	LOG(tuple(p0), tuple(p1), 0.11, seg=10, rings=4, bend=0)
	splinters(tuple(p1), tuple((p1 - p0).normalized()), n=5, r=0.09)
	# the snapped stump it broke from
	LOG((0.75, 0.55, 0.0), (0.75, 0.55, 0.5), 0.11, seg=10, rings=3, bend=0.02)
	splinters((0.75, 0.55, 0.5), (0, 0, 1), n=6, r=0.1)
	board((0.32, 0.32, 0.06), (0.75, 0.55, 0.03), T("shackstone"))
	slim(small=0.03, fine=0.012, few=0.02)  # lighter file (under 2 MB), same look


def lw_last_shift_stool():
	def stool():
		LOG((0, 0, 0.36), (0, 0, 0.44), 0.17, seg=10, rings=1)
		for k in range(3):
			a = 2 * math.pi * k / 3
			LOG((math.cos(a) * 0.08, math.sin(a) * 0.08, 0.37), (math.cos(a) * 0.16, math.sin(a) * 0.16, 0.0), 0.035, seg=6, rings=2)
		kit.ring(0.115, 0.012, (0, 0, 0.18), kit.tex_mat("rope", "a"), seg=14)
	tipped(stool, "Y", 102, pivot=(0, 0, 0), at=(-0.35, 0.15))
	# the pick dropped on the floor
	group(lambda: pickaxe((0, 0, 0)), at=(0.1, 0.35, 0.04), rot=(0, -2, 160))
	# open lunch tin (empty), its lid beside it, the tin mug on its side
	lunch_tin(0.25, -0.15, 0.0, open_=True)
	kit.cylinder(0.079, 0.016, (0.42, -0.08, 0.008), CU("dark"), verts=16, bevel=0.003)
	kit.ring(0.03, 0.005, (0.42, -0.08, 0.038), IRON("dark"), rot=(90, 0, 0), seg=10)
	group(lambda: tin_mug(0, 0, 0), at=(0.08, -0.3, 0.039), rot=(0, -90, 40))
	# the lamp, still burning low
	lamp((-0.05, -0.12, 0.0), 1.0, lit=True, flame_m=FLAME_LOW())


def lw_broken_lamp_rack():
	W = 1.0
	wall_back(W, 1.0, battens=(0.94,))
	# left bracket still holds; the right one snapped (a stub with splinters)
	B((0.06, 0.08, 0.1), (-0.45, -0.035, 0.8), DK(), bevel=0.008)
	peghead(-0.45, -0.075, 0.8)
	B((0.06, 0.06, 0.05), (0.45, -0.025, 0.81), DK(), bevel=0.006)
	splinters((0.45, -0.045, 0.785), (0.1, -0.2, -1), n=3, r=0.03)
	# the rail hangs from its left end down to the floor
	p0, p1 = Vector((-0.47, -0.105, 0.82)), Vector((0.5, -0.2, 0.035))
	d = p1 - p0
	ang = math.degrees(math.atan2(d.z, d.x))
	B((d.length, 0.05, 0.07), tuple((p0 + p1) / 2), DK(), bevel=0.01, rot=(0, -ang, -5))
	# two lamps still hang near the high end
	for t in (0.18, 0.36):
		c = p0 + d * t
		rod((c.x, c.y - 0.02, c.z + 0.01), (c.x, c.y - 0.08, c.z + 0.02), 0.012, DK())
		lamp((c.x, c.y - 0.06, c.z + 0.02 + 0.013 - 0.024 - 0.21 * 0.85), 0.85, lit=(t < 0.2), chimney=True)
	# the rest slid off: lamps on their sides, smashed glass, a spilled-oil stain
	stain(0.2, -0.32, 0.16, seed=8)
	for k, (x, y, rz) in enumerate(((0.05, -0.38, 20), (0.32, -0.45, -60))):
		group(lambda: lamp((0, 0, 0), 0.85, lit=False, chimney=False), at=(x, y, 0.049), rot=(0, 92, rz))
	broken_chimney(-0.15, -0.42, 0.0, 0.85)
	shards(0.12, -0.5, 14, 0.2, 9)


def lw_leaking_oil_cask():
	for x in (-0.18, 0.18):
		board((0.1, 0.6, 0.08), (x, 0.0, 0.04), DK())
	z0 = 0.075
	prof = [(0.22, 0), (0.24, 0.06), (0.25, 0.12), (0.265, 0.22), (0.27, 0.3), (0.265, 0.38), (0.25, 0.48), (0.24, 0.54), (0.22, 0.6)]
	st = staves(prof, (0, 0, z0), n=16, t=0.022, core_to=(0.03, 0.55))
	front = st[12]  # the stave facing -Y
	cut(front, (0.012, 0.1, 0.24), (0.0, -0.27, z0 + 0.22), rot=(0, 6, 0))
	for z, r in ((0.05, 0.237), (0.16, 0.261), (0.44, 0.261), (0.55, 0.237)):
		kit.ring(r, 0.01, (0, 0, z0 + z), IRON("dark"), seg=24)
	for k in range(4):
		w = 0.1
		x = -0.15 + k * w
		half = math.sqrt(max(0.0, 0.2 ** 2 - (abs(x) + w / 2) ** 2))
		B((w - 0.006, 2 * half, 0.014), (x, 0, z0 + 0.575), PL("abc"[k % 3]), bevel=0.003)
	kit.cylinder(0.025, 0.02, (0.06, 0.06, z0 + 0.585), DK(), verts=8, bevel=0.003)
	# a wedge hammered into the crack
	B((0.016, 0.06, 0.05), (0.004, -0.27, z0 + 0.3), PL("c"), bevel=0.003, rot=(-20, 0, 0))
	# an empty catch pan on the floor under the crack (owner: dry, nothing under it)
	cup((0.0, -0.4, 0.0), 0.11, 0.07, CU("b"), t=0.006, flare=1.12)
	kit.ring(0.123, 0.006, (0.0, -0.4, 0.068), CU("dark"), seg=18)


def lw_bell_fallen():
	# the bell lying on its side, a crack cut into the skirt
	before = objs()
	bell((0, 0, 0), 1.7)
	g = [o for o in objs() - before]
	shell = [o for o in g if o.type == "MESH" and len(o.data.vertices) > 200][0]
	cut(shell, (0.014, 0.04, 0.14), (0.0, -0.11, 0.05), rot=(0, 12, 0))
	bpy.context.view_layer.update()
	turn(g, "X", 78, (0, 0, 0))
	bpy.context.view_layer.update()
	shift(g, (0.0, 0.0, -low_z(g)))
	# the yoke block that tore free, still in its iron straps
	board((0.32, 0.13, 0.1), (-0.5, -0.25, 0.05), PL("b"), rot=(0, 0, 25))
	for s_ in (-1, 1):
		B((0.035, 0.15, 0.115), (-0.5 + s_ * 0.1 * math.cos(math.radians(25)), -0.25 + s_ * 0.1 * math.sin(math.radians(25)), 0.057), IRON("dark"), bevel=0.003, rot=(0, 0, 25))
	for s_ in (-1, 1):
		B((0.03, 0.012, 0.16), (-0.5 + s_ * 0.03, -0.25 - 0.07, 0.17), IRON("dark"), bevel=0.003, rot=(0, s_ * 25, 25))
	kit.ring(0.03, 0.009, (-0.5, -0.32, 0.25), IRON("dark"), rot=(90, 0, 25), seg=12)
	# the snapped yoke beam and its torn strap
	LOG((-0.6, 0.35, 0.05), (0.1, 0.45, 0.05), 0.05, seg=9, rings=2, bend=0.02)
	splinters((0.1, 0.45, 0.05), (1, 0.15, 0), n=5, r=0.05)
	B((0.03, 0.012, 0.2), (-0.25, 0.4, 0.103), IRON("dark"), bevel=0.003, rot=(90, 0, 70))
	rivet((-0.2, 0.39, 0.107), IRON("a"), r=0.01)
	# the frayed rope lying in a loose curve
	pts = [(0.25, -0.2), (0.45, -0.3), (0.6, -0.2), (0.7, 0.05), (0.62, 0.3)]
	for a, b in zip(pts, pts[1:]):
		kit.rope((a[0], a[1], 0.011), (b[0], b[1], 0.011), 0.011)
	for k in range(3):
		kit.cone(0.006, 0.0, 0.04, (0.63 + k * 0.01, 0.34, 0.012), kit.tex_mat("rope", "a"), rot=(-90, 0, -20 + k * 20), verts=4, bevel=0)
	LOG((0.25, -0.2, 0.022), (0.12, -0.32, 0.022), 0.022, PL("c"), seg=7, rings=1)  # the pull handle still on the rope
	kit.ring(0.016, 0.005, (0.25, -0.2, 0.022), kit.tex_mat("rope", "a"), rot=(0, 90, -40), seg=8)
	for k in range(4):  # wood chips from the beam
		kit.gem((0.2 + k * 0.06, 0.52 - (k % 2) * 0.05, 0.008), (0.03, 0.012, 0.008), PL("c"), seed=k + 50)


def lw_collapsed_walkway():
	Hb = 1.5
	for x in (-0.85, 0.85):
		LOG((x, 0.42, 0.012), (x, 0.42, Hb), 0.07, seg=9, rings=4, bend=0.02)
		LOG((x, 0.42, 0.9), (x * 0.6, 0.42, Hb - 0.02), 0.03, seg=6, rings=1, bend=0)
	LOG((-1.0, 0.42, Hb + 0.06), (1.0, 0.42, Hb + 0.06), 0.075, seg=9, rings=3, bend=0.02)
	for x in (-0.85, 0.85):
		kit.ring(0.085, 0.01, (x, 0.42, Hb + 0.06), IRON("dark"), rot=(0, 90, 0), seg=14)
	L = 1.75
	th = 50.0
	for _ in range(6):  # the joists' low front edge rests on the floor
		th = math.degrees(math.asin((Hb + 0.006 - 0.12 * math.cos(math.radians(th))) / L))

	def deck():
		for x in (-0.65, 0.0, 0.65):
			B((0.08, L + 0.07, 0.12), (x, -L / 2 + 0.035, -0.058), DK(), bevel=0.01)  # the back ends reach into the beam
		n = 10
		for k in range(n):
			if k == 7:
				continue
			y = -L + L * (k + 0.5) / n
			board((1.6 - (0.25 if k == 4 else 0), L / n - 0.012, 0.035), (0 if k != 4 else -0.125, y, 0.0175))
			for x in ((-0.65,) if k == 4 else (-0.65, 0.65)):
				peghead(x, y, 0.0355, 0.01)
		for y in (-0.3, -1.3):
			LOG((0.78, y, 0.0), (0.78, y, 0.75), 0.03, seg=7, rings=2, bend=0.02)
		LOG((0.78, -0.3, 0.74), (0.78, -0.9, 0.74), 0.026, seg=7, rings=1)
		splinters((0.78, -0.9, 0.74), (0, -1, 0), n=4, r=0.025)
	group(deck, at=(0, 0.42, Hb), rot=(th, 0, 0))
	# the snapped front post: stump with splinters, the top half on the floor
	fy = 0.42 - L * math.cos(math.radians(th)) - 0.12
	LOG((-0.85, fy, 0.012), (-0.85, fy, 0.5), 0.07, seg=9, rings=2, bend=0.02)
	splinters((-0.85, fy, 0.5), (0, 0, 1), n=6, r=0.065)
	LOG((-0.6, fy - 0.25, 0.07), (0.4, fy - 0.45, 0.07), 0.07, seg=9, rings=3, bend=0.02)
	splinters((-0.6, fy - 0.25, 0.07), (-1, 0.2, 0), n=5, r=0.065)
	# a fallen lamp and some glass under the deck end
	group(lambda: lamp((0, 0, 0), 0.9, lit=False, chimney=False), at=(0.75, fy - 0.2, 0.052), rot=(0, 90, -30))
	shards(0.6, fy - 0.3, 8, 0.12, 21)


MODELS = {name: fn for name, fn in globals().items() if name.startswith("lw_") and callable(fn)}

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
