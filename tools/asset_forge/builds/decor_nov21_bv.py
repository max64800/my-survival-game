# Decor set BV (Nov 21): BRASSGATE VAULT, a MEDIUM dungeon in cut stone (Stonehold style): the old treasury and
# counting-house of a dwarf hold. Greystone blocks with carvings CUT INTO them, heavy warm worn brass, iron, copper.
#   blender --background --factory-startup --python builds/decor_nov21_bv.py -- [id ...]   (none = all)
# Output: assets/models/decor/<id>.glb (origin bottom-centre, front faces -Y in Blender = +Z in Godot).
# Wall pieces have a flat back at +Y and stand on the floor (a stone foot), so they never float.
#
# The objects (bv_ingot_stack and bv_ingot_stack_toppled were deleted by the owner, Nov 22):
#  bv_counting_table      a long stone counting table: counting lines cut in the top with copper counters on them,
#                         a brass balance, weights, sorted coin stacks, a brass coin tray, an open ledger and inkwell
#  bv_count_abandoned     (story) the count stopped mid-way: half-sorted stacks, one toppled and spilling, ink tipped
#                         over the ledger, the quill dropped, the stool knocked over on the floor
#  bv_balance_great       the great brass balance on a carved stepped plinth: chained pans, an ingot weighed against weights
#  bv_ledger_desk         a tall stone ledger desk: chained open ledger on the slope, brass inkwell, candle, ledgers below
#  bv_strongbox           an iron-banded strongbox on a stone step: brass lock plate, hasp and padlock, corner irons
#  bv_strongbox_looted    (story) the strongbox smashed open: lid flung back, lock plate torn out, padlock and pry bar on the floor
#  bv_coin_chest_tipped   (story) a brass-bound coin chest tipped on its side, lid swung open, coins spilled in a fan
#  bv_assay_bench         an assay bench: black touchstone with gold streaks, touch needles, small balance, crucibles, cupels, lens
#  bv_teller_counter      a carved stone counter with a brass grille, an arched pay window, a coin trough, a bell
#  bv_guard_post          a vault guard's post: stone pillar and bench, halberd in a brass ring, lantern, helmet, hand bell
#  bv_minting_block       a minting block: carved eight-sided stone, a cap stone with a groove ring and tally notches, the die
#                         in wedges, the punch, tray of blanks, coin bowl and stacks, tweezers, gauge, the hammer in its hole
#  bv_assay_furnace       a small cut-stone assay furnace, long cold: arched firebox (firebrick back, grate, cold charcoal),
#                         an iron-framed clay muffle with cupels and metal beads, brass-bound door swung open, tongs
#  bv_coin_cart           a low iron-wheeled vault cart carrying a brass-banded coin box, chained down
#  bv_lockbox_pedestal    a carved pedestal holding a small brass casket inside a domed brass cage, name plate
#  bv_ledger_shelf        (wall) a cut-stone shelf full of ledgers in rows, brass corners, scroll tubes, label plates
#  bv_key_rack            (wall) a carved key board: three rows of brass hooks, every key with a tag, runes cut over each row
#  bv_key_rack_looted     (story, wall) the key board stripped: hooks empty or bent, a few keys dropped at its foot
#  bv_weight_shelf        (wall) two stone shelves of brass weights from huge to tiny, bell weights and stacked discs
#  bv_name_plaque         (wall) a stone stele with a bolted brass plaque, runes cut into the brass, the scales cut below
#  bv_coin_niche_found    (story, wall) a hidden coin niche in the ashlar wall: its cover stone pulled out, coins inside
#  bv_pigeonholes         (wall) a stone block of square cubbies, each holding a coin stack, scroll tube, purse or coin bowl
#  bv_vault_door          (wall) the round vault door: iron disc, brass rim and spokes, locking wheel, voussoir surround
#  bv_lock_works          (wall) a great lock opened up on the wall: brass case, three bolts, lever tumblers, spring, key
#  bv_guild_medallion     (wall) the counting guild's round medallion: scales cut in, a rune ring, a brass rim, crossed keys
#  bv_wall_lantern        (wall) a carved stone post with a corbel and a brass cage lantern hanging on a chain, lit
#  bv_halberd_rack        (wall) a stone rack of three guard halberds with brass ferrules in brass foot cups, one slot empty
#  bv_lockbox_shelf       (wall) shelves of small iron deed boxes with brass tags; one gone, one pried open
#  bv_vault_door_forced   (story, wall) the round vault door forced open and swung wide: a walk-through round doorway, flat
#                         at the floor with a 3 cm threshold stone, bolts bent, chips, pry bar and sledge off to the right
#  bv_coin_chest_tipped_empty, bv_coin_niche_found_empty, bv_pigeonholes_empty   the same models with the coins gone
# LOOT (owner round 2, Nov 22; the looting code comes later, each full model swaps to its _empty twin):
#   bv_coin_chest_tipped 60 gold coins, bv_coin_niche_found 25 gold coins, bv_pigeonholes 40 coins (gold and silver).
# bv_strongbox opens: kit.save(lid=) makes its lid its own part (LIDS at the bottom); the padlock lies unlocked on the step.
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from night_stations import B, GAME, J, T, kit, log, rng  # noqa: E402
from night_materials import C, sphere, _cm  # noqa: E402
from decor_nov21_a import slim, bar, chain, circ, low_z, objs, prism, rod, shift, turn  # noqa: E402
from decor_nov21_b import coin  # noqa: E402
from decor_nov21_d import tube  # noqa: E402
from decor_nov21_f import glass  # noqa: E402
from decor_nov21_mg import key_part  # noqa: E402
from decor_nov21_th import (S, GROOVE, IRON, CU, SILV, LEA, GOLD, COAL, EMBER, WAX, FLAME, WOOD, foot, carve, cy,  # noqa: E402
	gline, runes, lathe, group, plinth, frame_band, rough_chips, coin_pile, candle, pry_bar, panel_wall, flat_back, coal_heap)

PAPER = lambda: C((0.7, 0.62, 0.46), 0.95)  # noqa: E731
INK = lambda: C((0.03, 0.025, 0.03), 0.3)  # noqa: E731
CLAY = lambda: C((0.42, 0.24, 0.14), 0.9)  # noqa: E731
BLACK = lambda: C((0.03, 0.03, 0.032), 0.35)  # noqa: E731  (touchstone)


def BRASS(v="a"):
	"""Warm worn brass: the silver painting multiplied by a warm yellow (keeps the hand-painted wear)."""
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
def drop(parts, z=0.0):
	"""Move a group so its lowest point sits at z (a thing lying on the floor)."""
	bpy.context.view_layer.update()
	shift(parts, (0, 0, z - low_z(parts)))
	return parts


def stack(x, y, z, h, r=0.024, m=None, mr=None):
	"""A neat coin stack: a core and coin-edge rings."""
	m = m or GOLD(-0.04)
	kit.cylinder(r, h, (x, y, z + h / 2 - 0.002), m, verts=12, bevel=0.002)
	for j in range(max(1, int(h / 0.011))):
		kit.ring(r, 0.0025, (x, y, z + 0.006 + j * 0.011), mr or GOLD(0.02), seg=12)


def coin_fan(cx, cy_, z, rx, ry, n, m=None, a0=0.0, a1=6.28, placed=None):
	"""Coins spilled flat on a surface, each a little tilted, never overlapping (overlapping flat coins shimmer)."""
	placed = [] if placed is None else placed
	for k in range(n):
		for _ in range(40):
			a, d = rng.uniform(a0, a1), math.sqrt(rng.random())
			x, y = cx + math.cos(a) * d * rx, cy_ + math.sin(a) * d * ry
			if all((x - px) ** 2 + (y - py) ** 2 > 0.052 ** 2 for px, py in placed):
				placed.append((x, y))
				coin((x, y, z + 0.0045), m or GOLD(J(0.05)), tilt=(J(4), J(4), rng.uniform(0, 90)))
				break

def ledger(w, d, h, m, at, rot=(0, 0, 0), corners=True):
	"""A closed ledger lying flat (spine at -X): two boards, a spine, the page block, brass corner caps."""
	def build():
		B((w, d, 0.008), (0, 0, 0.004), m, bevel=0.003)
		B((w, d, 0.008), (0, 0, h - 0.004), m, bevel=0.003)
		B((0.012, d + 0.004, h - 0.004), (-w / 2 + 0.003, 0, h / 2), m, bevel=0.004)
		B((w - 0.016, d - 0.01, h - 0.012), (0.002, 0, h / 2), PAPER(), bevel=0.002)
		if corners:
			for yy in (-1, 1):
				B((0.028, 0.028, 0.005), (w / 2 - 0.013, yy * (d / 2 - 0.013), h + 0.0008), BRASS("b"), bevel=0.0015)
			B((0.012, 0.05, 0.005), (-w / 2 + 0.03, 0, h + 0.0008), BRASS("dark"), bevel=0.0015)
	return group(build, at=at, rot=rot)


def page(w, d, lines=7, wet=False):
	B((w, d, 0.02), (0, 0, 0.01), PAPER(), bevel=0.004)
	for i in range(lines):
		L = w * (0.75 if i % 3 else 0.5)
		B((L, 0.004, 0.004), (-w * 0.08 + (w * 0.75 - L) / 2, -d / 2 + 0.035 + i * (d - 0.07) / max(1, lines - 1), 0.0205), INK(), bevel=0)
	for i in range(lines):  # a column of figures on the right
		B((0.018, 0.004, 0.004), (w * 0.36, -d / 2 + 0.035 + i * (d - 0.07) / max(1, lines - 1), 0.0205), INK(), bevel=0)


def open_ledger(w, d, m, at, rot=(0, 0, 0), lines=7):
	"""An open ledger: the cover, two page blocks tipped a little towards the spine, ink lines and figures."""
	def build():
		B((2 * w + 0.03, d + 0.02, 0.008), (0, 0, 0.004), m, bevel=0.003)
		for s_ in (-1, 1):
			group(lambda: page(w, d, lines), at=(s_ * (w / 2 + 0.004), 0, 0.004), rot=(0, -s_ * 4, 0))
		B((0.004, d * 0.7, 0.004), (0, 0, 0.0165), C((0.45, 0.08, 0.06), 0.8), bevel=0)  # ribbon in the fold
	return group(build, at=at, rot=rot)


def quill(at, rotz=0.0, lean=8):
	"""A quill built upright (nib at the origin, pointing down), leaned `lean` degrees; lean=90 lies it flat."""
	def build():
		prism([(0, 0), (0.012, 0.05), (0.014, 0.13), (0.004, 0.2), (-0.006, 0.12), (-0.006, 0.04)], -0.0015, 0.0015, C((0.72, 0.68, 0.6), 0.9))
		rod((0, 0, -0.025), (0, 0, 0.02), 0.002, C((0.8, 0.75, 0.62), 0.6), seg=5)
	return group(build, at=at, rot=(lean, 0, rotz))


def inkwell(x, y, z, s=1.0):
	lathe([(0.004, 0), (0.03 * s, 0), (0.034 * s, 0.006 * s), (0.032 * s, 0.035 * s), (0.016 * s, 0.045 * s), (0.014 * s, 0.05 * s),
		(0.01 * s, 0.05 * s), (0.008 * s, 0.04 * s), (0.004, 0.04 * s)], (x, y, z), BRASS("b"), seg=14)
	kit.ring(0.031 * s, 0.003, (x, y, z + 0.022 * s), BRASS("dark"), seg=14)


def bell_weight(x, y, z, s=1.0, m=None):
	"""A brass bell weight with a lifting loop."""
	m = m or BRASS("a")
	lathe([(0.004, 0), (0.045 * s, 0), (0.047 * s, 0.01 * s), (0.036 * s, 0.045 * s), (0.02 * s, 0.062 * s), (0.014 * s, 0.07 * s),
		(0.004, 0.072 * s)], (x, y, z), m, seg=14)
	kit.ring(0.045 * s, 0.003 * s + 0.001, (x, y, z + 0.008 * s), BRASS("dark"), seg=14)
	kit.ring(0.012 * s, 0.0035 * s + 0.0008, (x, y, z + 0.078 * s), BRASS("dark"), rot=(90, 0, 0), seg=10)


def disc_weights(x, y, z, n=4, r=0.045, m=None):
	"""A stack of flat brass disc weights, each smaller, with a knob on top."""
	zz = z
	for k in range(n):
		rr = r * (1 - 0.15 * k)
		h = 0.018
		kit.cylinder(rr, h, (x, y, zz + h / 2), m or BRASS("abc"[k % 3]), verts=16, bevel=0.003)
		zz += h - 0.002
	kit.cylinder(0.008, 0.016, (x, y, zz + 0.006), BRASS("dark"), verts=8, bevel=0.002)
	sphere((x, y, zz + 0.016), 0.012, BRASS("b"), seg=10, rings=6)


def balance(s=1.0, tilt=5.0, left=None, right=None):
	"""A brass balance at the origin (feet on z = 0): foot, post, beam tipped by `tilt` degrees, two pans
	on three hangers each. left/right = functions that fill the pans: f(x, y, z_floor_of_pan)."""
	H, L, pr = 0.34 * s, 0.2 * s, 0.07 * s
	lathe([(0.004, 0), (0.075 * s, 0), (0.08 * s, 0.01 * s), (0.06 * s, 0.02 * s), (0.025 * s, 0.035 * s), (0.016 * s, 0.05 * s),
		(0.004, 0.05 * s)], (0, 0, 0), BRASS("b"), seg=16)
	kit.ring(0.077 * s, 0.004 * s + 0.001, (0, 0, 0.006 * s), BRASS("dark"), seg=16)
	kit.cylinder(0.011 * s, H - 0.04 * s, (0, 0, 0.045 * s + (H - 0.04 * s) / 2), BRASS("a"), verts=10, bevel=0.002)
	for zz in (0.12, 0.22):
		kit.ring(0.012 * s, 0.004 * s + 0.0008, (0, 0, zz * s), BRASS("dark"), seg=10)
	B((0.05 * s, 0.03 * s, 0.035 * s), (0, 0, H), BRASS("b"), bevel=0.004)  # the fork
	sphere((0, 0, H + 0.03 * s), 0.014 * s, BRASS("a"), seg=10, rings=6)
	t = math.radians(tilt)
	ends = []
	beam = objs()
	B((2 * L, 0.012 * s, 0.014 * s), (0, -0.018 * s, H), BRASS("a"), bevel=0.003)
	prism([(-0.007 * s, H), (0.007 * s, H), (0.0, H + 0.11 * s)], -0.022 * s, -0.014 * s, BRASS("dark"))  # pointer
	for k in (-1, 1):
		sphere((k * L, -0.018 * s, H), 0.012 * s, BRASS("b"), seg=8, rings=5)
	turn([o for o in objs() if o not in beam], "Y", -tilt, (0, -0.018 * s, H))
	for k in (-1, 1):
		ex, ez = k * L * math.cos(t), H + k * L * math.sin(t)
		ends.append((ex, ez))
	kit.cylinder(0.006 * s, 0.03 * s, (0, -0.01 * s, H), BRASS("dark"), rot=(90, 0, 0), verts=8)  # pin
	for k, (ex, ez) in zip((-1, 1), ends):
		zp = ez - 0.2 * s
		kit.ring(0.008 * s, 0.002 * s + 0.0008, (ex, -0.018 * s, ez - 0.016 * s), BRASS("dark"), rot=(90, 0, 0), seg=8)
		for j in range(3):
			a = 2 * math.pi * j / 3 + 0.5
			rod((ex, -0.018 * s, ez - 0.02 * s), (ex + math.cos(a) * pr * 0.95, -0.018 * s + math.sin(a) * pr * 0.95, zp + 0.018 * s), 0.0018 * s + 0.0006, BRASS("dark"), seg=4)
		lathe([(0.004, 0), (pr * 0.6, 0.002 * s), (pr, 0.016 * s), (pr * 0.97, 0.019 * s), (pr * 0.6, 0.007 * s), (0.004, 0.006 * s)],
			(ex, -0.018 * s, zp), BRASS("b"), seg=16)
		fill = left if k < 0 else right
		if fill:
			fill(ex, -0.018 * s, zp + 0.006 * s)


def ingot(x, y, z, rz=0.0, m=None, l=0.13, w=0.055, h=0.034):
	o = kit.taper(l, w, l - 0.022, w - 0.016, h, (0, 0, 0), m or GOLD(J(0.04)), bevel=0.004)
	o.location = (x, y, z)
	o.rotation_euler = (0, 0, math.radians(rz))
	return o


def strongbox(w, d, h, lid_angle=0.0, lock=True, wood=None, band=None, handles=True):
	"""A hollow iron-banded strongbox at the origin (bottom on z = 0.03, iron feet under). Front = -Y.
	lid_angle < 0 swings the lid open around the back hinge. Returns the front wall."""
	wd = wood or WOOD()
	BA = band or IRON("a")
	t = 0.03
	z0 = 0.03
	for sx in (-1, 1):
		for sy in (-1, 1):
			B((0.05, 0.05, 0.04), (sx * (w / 2 - 0.03), sy * (d / 2 - 0.03), 0.02), IRON("dark"), bevel=0.006)  # feet
	B((w, d, t), (0, 0, z0 + t / 2), wd, bevel=0.006)
	walls = [B((w, t, h - t), (0, sy * (d / 2 - t / 2), z0 + t + (h - t) / 2 - 0.004), wd, bevel=0.006) for sy in (-1, 1)]
	walls += [B((t, d - 2 * t + 0.008, h - t), (sx * (w / 2 - t / 2), 0, z0 + t + (h - t) / 2 - 0.004), wd, bevel=0.006) for sx in (-1, 1)]
	top = z0 + h - 0.004
	bx = (-w * 0.3, w * 0.3)
	for x in bx:  # straps over front, bottom and back
		for sy in (-1, 1):
			B((0.045, 0.012, h - 0.012), (x, sy * (d / 2 + 0.001), z0 + h / 2 - 0.002), BA, bevel=0.003)
			for zz in (z0 + 0.05, z0 + h - 0.06):
				kit.rivet((x, sy * (d / 2 + 0.008), zz), IRON("dark"), r=0.008)
	for sx in (-1, 1):
		for sy in (-1, 1):  # corner irons
			B((0.06, 0.06, h - 0.03), (sx * (w / 2 - 0.022), sy * (d / 2 - 0.022), z0 + h / 2 - 0.004), band or IRON("dark"), bevel=0.006)
		if handles:
			kit.ring(0.04, 0.007, (sx * (w / 2 + 0.012), 0, z0 + h * 0.62), IRON("a"), rot=(0, 90, 0), seg=14)  # handle
			B((0.012, 0.06, 0.03), (sx * (w / 2 + 0.003), 0, z0 + h * 0.62 + 0.035), IRON("dark"), bevel=0.003)
	plate = None
	if lock:
		plate = B((0.13, 0.014, 0.12), (0, -d / 2 - 0.002, top - 0.08), BRASS("b"), bevel=0.004)
		carve(plate, [cy(circ(0, top - 0.07, 0.012, n=10, wob=0), -d / 2 - 0.009, 0.01), cy([(-0.006, top - 0.07), (0.006, top - 0.07), (0.009, top - 0.11), (-0.009, top - 0.11)], -d / 2 - 0.009, 0.01)])
		for x in (-0.05, 0.05):
			for zz in (top - 0.03, top - 0.13):
				kit.rivet((x, -d / 2 - 0.01, zz), BRASS("dark"), r=0.007)
	before = objs()
	lh = 0.06
	B((w + 0.014, d + 0.014, lh), (0, 0, top + lh / 2), wd, bevel=0.008)
	B((w - 0.04, d - 0.04, 0.03), (0, 0, top + lh + 0.01), wd, bevel=0.01)  # raised panel
	for x in bx:
		B((0.045, d + 0.03, 0.012), (x, 0, top + lh + 0.004), BA, bevel=0.003)
		B((0.045, 0.012, lh - 0.006), (x, -d / 2 - 0.009, top + lh / 2), BA, bevel=0.003)
		for yy in (-d / 4, d / 4):
			kit.rivet((x, yy, top + lh + 0.011), IRON("dark"), r=0.008)
	if lock:
		B((0.04, 0.016, 0.1), (0, -d / 2 - 0.012, top + 0.01), IRON("dark"), bevel=0.004)  # hasp
	for x in (-w * 0.3, w * 0.3):  # hinges at the back
		kit.cylinder(0.014, 0.08, (x, d / 2 + 0.01, top), IRON("dark"), rot=(0, 90, 0), verts=8)
	if lid_angle:
		turn([o for o in objs() if o not in before], "X", lid_angle, (0, d / 2 + 0.01, top))
	return walls[0]


def padlock(at, rot=(0, 0, 0), open_=False):
	"""A brass padlock (body centre at the origin, keyhole on the -Y face) with an iron shackle."""
	def build():
		body = B((0.06, 0.03, 0.06), (0, 0, 0), BRASS("b"), bevel=0.01)
		carve(body, [cy(circ(0, 0.004, 0.006, n=8, wob=0), -0.016, 0.01), cy([(-0.003, 0.004), (0.003, 0.004), (0.005, -0.016), (-0.005, -0.016)], -0.016, 0.01)])
		ex, ez = (0.03, 0.05) if open_ else (0.018, 0.026)
		tube([(-0.018, 0, 0.026), (-0.018, 0, 0.055), (0, 0, 0.07), (0.018, 0, 0.055), (ex, 0, ez)], 0.006, 0.006, IRON("dark"), seg=6)
	return group(build, at=at, rot=rot)


def stool(at, rot=(0, 0, 0)):
	"""A small three-legged dark wood stool (legs into a thick seat)."""
	def build():
		kit.cylinder(0.17, 0.05, (0, 0, 0.42), WOOD(), verts=14, bevel=0.01)
		kit.ring(0.168, 0.008, (0, 0, 0.4), IRON("dark"), seg=18)
		for k in range(3):
			a = 2 * math.pi * k / 3
			log((math.cos(a) * 0.17, math.sin(a) * 0.17, 0.0), (math.cos(a) * 0.1, math.sin(a) * 0.1, 0.42), 0.022, WOOD(), seg=6, rings=1, ends=False, bend=0)
		for k in range(3):
			a, b = 2 * math.pi * k / 3, 2 * math.pi * (k + 1) / 3
			rod((math.cos(a) * 0.15, math.sin(a) * 0.15, 0.14), (math.cos(b) * 0.15, math.sin(b) * 0.15, 0.14), 0.012, WOOD(), seg=5)
	return group(build, at=at, rot=rot)


def scales_emblem(cx, cz, s, yf, w=0.016, depth=0.012):
	"""The vault's sign cut into stone: a balance (post, foot, beam, hangers, two pans) with a knob on top."""
	c = gline([(cx, cz - 0.85 * s), (cx, cz + 0.55 * s)], w * 1.2, yf, depth)
	c += gline([(cx - 0.35 * s, cz - 0.88 * s), (cx + 0.35 * s, cz - 0.88 * s)], w * 1.4, yf, depth)
	c += gline([(cx - 0.85 * s, cz + 0.42 * s), (cx + 0.85 * s, cz + 0.42 * s)], w, yf, depth)
	c.append(cy(circ(cx, cz + 0.62 * s, 0.085 * s, n=10, wob=0), yf, depth))
	for k in (-1, 1):
		ex = cx + k * 0.82 * s
		c += gline([(ex - 0.22 * s, cz - 0.2 * s), (ex, cz + 0.42 * s), (ex + 0.22 * s, cz - 0.2 * s)], w * 0.8, yf, depth)
		c.append(cy([(ex - 0.3 * s, cz - 0.2 * s)] + [(ex + math.cos(a) * 0.3 * s, cz - 0.2 * s + math.sin(a) * 0.16 * s)
			for a in [math.pi + math.pi * j / 8 for j in range(1, 8)]] + [(ex + 0.3 * s, cz - 0.2 * s)], yf, depth))
	return c


def key_emblem(cx, cz, s, ang, yf, w=0.014, depth=0.01):
	"""A key cut into stone, turned `ang` degrees: round bow, shaft, two bits."""
	ca, sa = math.cos(math.radians(ang)), math.sin(math.radians(ang))
	r = lambda x, z: (cx + x * ca - z * sa, cz + x * sa + z * ca)  # noqa: E731
	c = gline([r(math.cos(a) * 0.12 * s, 0.38 * s + math.sin(a) * 0.12 * s) for a in [2 * math.pi * j / 12 for j in range(13)]], w, yf, depth)
	c += gline([r(0, 0.26 * s), r(0, -0.45 * s)], w * 1.2, yf, depth)
	c.append(cy([r(0, -0.45 * s), r(0.14 * s, -0.45 * s), r(0.14 * s, -0.36 * s), r(0, -0.36 * s)], yf, depth))
	c.append(cy([r(0, -0.3 * s), r(0.1 * s, -0.3 * s), r(0.1 * s, -0.23 * s), r(0, -0.23 * s)], yf, depth))
	return c


def hook(x, y0, z, m=None):
	"""A brass wall hook coming out of a front face at y0: a round rose, the arm, an upturned tip with a ball."""
	m = m or BRASS("b")
	kit.cylinder(0.02, 0.012, (x, y0 - 0.002, z), BRASS("dark"), rot=(90, 0, 0), verts=12, bevel=0.002)
	rod((x, y0, z), (x, y0 - 0.06, z), 0.006, m, seg=6)
	rod((x, y0 - 0.06, z - 0.003), (x, y0 - 0.066, z + 0.03), 0.006, m, seg=6)
	sphere((x, y0 - 0.066, z + 0.032), 0.009, m, seg=8, rings=5)


def tag(x, y, z, m=None):
	"""A little brass tag: a flat ring round a key shaft (or under a rail) at (x, y, z), the disc hanging in front."""
	kit.ring(0.012, 0.0022, (x, y, z), BRASS("dark"), seg=10)
	kit.cylinder(0.016, 0.004, (x, y - 0.02, z - 0.016), m or BRASS("a"), rot=(90, 0, 0), verts=10, bevel=0.001)


def halberd(L=1.75):
	"""A guard's halberd along +Z from its butt: dark shaft, brass ferrules, axe blade, back hook, top spike."""
	log((0, 0, 0.03), (0, 0, L), 0.02, WOOD(), seg=8, rings=3, bend=0.008, ends=False)
	kit.cone(0.022, 0.014, 0.06, (0, 0, 0.03), BRASS("b"), verts=8)  # butt cap
	for zz in (0.55, 0.9):
		kit.ring(0.021, 0.006, (0, 0, zz), BRASS("dark"), seg=10)
	kit.cylinder(0.026, 0.2, (0, 0, L - 0.1), IRON("dark"), verts=8, bevel=0.003)  # socket
	kit.ring(0.026, 0.006, (0, 0, L - 0.2), BRASS("b"), seg=10)
	prism([(0.015, L - 0.24), (0.11, L - 0.31), (0.175, L - 0.2), (0.17, L - 0.07), (0.11, L - 0.0), (0.015, L - 0.05)], -0.006, 0.006, IRON("a"))
	B((0.004, 0.008, 0.15), (0.172, 0, L - 0.135), SILV("a"), bevel=0, rot=(0, 2, 0))  # bright worn edge
	prism([(-0.015, L - 0.16), (-0.07, L - 0.15), (-0.14, L - 0.1), (-0.09, L - 0.12), (-0.015, L - 0.09)], -0.006, 0.006, IRON("a"))
	kit.cone(0.02, 0.002, 0.26, (0, 0, L + 0.12), IRON("a"), verts=6)
	for zz in (L - 0.04, L - 0.17):
		kit.rivet((0, -0.026, zz), BRASS("dark"), r=0.008)


def wall_slab(w, h, d=0.14):
	"""A cut-stone wall slab with a foot and cornice (from the tomb set). Returns (slab, front y)."""
	return panel_wall(w, h, d)


# ================= floor pieces =================
def bv_counting_table():
	W, D, Hh = 1.55, 0.78, 0.8
	for s_ in (-1, 1):
		leg = kit.taper(0.26, 0.66, 0.18, 0.56, Hh - 0.12, (s_ * 0.58, 0, 0.06), S("b"), bevel=0.0)
		carve(leg, scales_emblem(s_ * 0.58, 0.42, 0.06, -0.31, w=0.01, depth=0.014))
		B((0.34, 0.72, 0.06), (s_ * 0.58, 0, 0.03), S("c"), bevel=0.012)
	B((0.95, 0.12, 0.1), (0, 0, 0.28), S("c"), bevel=0.012)
	top = B((W, D, 0.1), (0, 0, Hh - 0.05), S("a"), bevel=0.015)
	zt = Hh
	cuts = []
	for i in range(5):  # counting lines across the front half
		yy = -0.34 + i * 0.055
		cuts.append(prism(bar((-0.7, yy), (0.1, yy), 0.012), zt - 0.009, zt + 0.03, GROOVE(), axis="z"))
	cuts.append(prism(bar((-0.3, -0.36), (-0.3, -0.1), 0.012), zt - 0.009, zt + 0.03, GROOVE(), axis="z"))
	cuts += runes(-0.7, 0.7, Hh - 0.05, -D / 2, h=0.05, w=0.01, gap=0.05, depth=0.007, under=False)
	carve(top, cuts)
	for i in range(5):  # copper counters lying on the lines
		yy = -0.34 + i * 0.055
		for j in range(rng.randint(1, 4)):
			x = -0.66 + 0.1 * j + (0.38 if j > 1 else 0) + J(0.01)
			kit.cylinder(0.017, 0.006, (x, yy + J(0.004), zt + 0.0025), CU("b"), verts=12, bevel=0.0015)
	# brass balance at the back left, weighing coins against a disc weight
	group(lambda: balance(1.0, 4, left=lambda x, y, z: [stack(x - 0.015, y, z, 0.03), stack(x + 0.022, y + 0.01, z, 0.02)],
		right=lambda x, y, z: disc_weights(x, y, z - 0.002, n=2, r=0.035)), at=(-0.45, 0.2, zt - 0.003))
	for k, x in enumerate((-0.12, -0.05, 0.01, 0.06)):  # weights in a row, largest first
		bell_weight(x, 0.27, zt - 0.003, s=1.0 - 0.18 * k)
	# brass coin tray with three compartments: gold heap, silver, copper
	tx, ty = 0.18, 0.14
	B((0.32, 0.18, 0.014), (tx, ty, zt + 0.004), BRASS("b"), bevel=0.003)
	for yy in (-0.095, 0.095):
		B((0.34, 0.012, 0.035), (tx, ty + yy, zt + 0.02), BRASS("a"), bevel=0.003)
	for xx in (-0.165, -0.055, 0.055, 0.165):
		B((0.012, 0.18, 0.033), (tx + xx, ty, zt + 0.019), BRASS("a"), bevel=0.003)
	coin_pile(tx - 0.11, ty, zt + 0.01, 0.035, 0.06, 10, 0.012)
	for xx, m in ((0.0, SILV("a")), (0.11, CU("b"))):
		for j in range(7):
			coin((tx + xx + J(0.02), ty + J(0.05), zt + 0.016 + j * 0.002), m, tilt=(J(5), J(5), J(90)))
	for k, (x, y) in enumerate(((0.45, 0.25), (0.51, 0.25), (0.57, 0.25), (0.45, 0.19), (0.51, 0.19))):
		stack(x, y, zt - 0.002, 0.03 + 0.012 * (k % 3), m=GOLD(-0.04) if k < 3 else SILV("b"), mr=GOLD(0.02) if k < 3 else SILV("a"))
	open_ledger(0.17, 0.24, LEA("b"), at=(0.38, -0.18, zt - 0.003), rot=(0, 0, 6))
	inkwell(0.66, -0.06, zt - 0.003)
	quill((0.665, -0.06, zt + 0.035), rotz=30, lean=16)


def bv_count_abandoned():
	W, D, Hh = 1.15, 0.68, 0.78
	for sx in (-1, 1):
		for sy in (-1, 1):
			kit.taper(0.14, 0.14, 0.11, 0.11, Hh - 0.08, (sx * 0.46, sy * 0.24, 0.0), S("b"), bevel=0.01)
	for sy in (-1, 1):
		B((0.86, 0.08, 0.08), (0, sy * 0.24, 0.2), S("c"), bevel=0.01)
	top = B((W, D, 0.09), (0, 0, Hh - 0.045), S("a"), bevel=0.015)
	carve(top, runes(-0.45, 0.45, Hh - 0.045, -D / 2, h=0.045, w=0.009, gap=0.05, depth=0.006, under=False))
	zt = Hh
	# sorted stacks, then the half-done row, then one stack toppled and spilling
	for k, x in enumerate((-0.48, -0.42, -0.36, -0.3)):
		for j, y in enumerate((0.2, 0.14)):
			stack(x, y, zt - 0.002, 0.044 + 0.011 * ((k + j) % 2))
	stack(-0.24, 0.2, zt - 0.002, 0.022)
	for k in range(9):  # the toppled stack: coins lying in a slid line, each overlapping the last
		coin((-0.18 + k * 0.022, 0.1 - k * 0.012, zt + 0.006 + k * 0.0022), GOLD(J(0.05)), tilt=(J(4), 12 + J(3), J(30)))
	coin_pile(-0.1, 0.0, zt, 0.12, 0.08, 26, 0.02)  # the unsorted heap still waiting
	for k in range(4):  # coins rolled off onto the floor
		coin((0.15 + k * 0.07, -0.42 - J(0.04), 0.004 + k * 0.002), GOLD(J(0.05)), tilt=(J(4), J(4), J(90)))
	group(lambda: balance(0.8, -9, right=lambda x, y, z: coin_pile(x, y, z, 0.03, 0.03, 8, 0.012)), at=(0.3, 0.22, zt - 0.003))
	open_ledger(0.15, 0.22, LEA("dark"), at=(0.2, -0.13, zt - 0.003), rot=(0, 0, -8), lines=5)
	# the inkwell knocked over, ink run across the table, the quill dropped beside the book
	group(lambda: inkwell(0, 0, 0), at=(0.47, -0.08, zt + 0.031), rot=(0, 90, 20))
	kit.cylinder(0.07, 0.003, (0.45, -0.17, zt + 0.0015), INK(), verts=14, bevel=0).scale = (1.2, 0.8, 1)
	quill((-0.06, -0.2, zt + 0.0025), rotz=70, lean=90)
	# a burnt-down candle on a brass dish
	kit.cylinder(0.05, 0.01, (-0.42, -0.18, zt + 0.003), BRASS("b"), verts=14, bevel=0.003)
	kit.cylinder(0.022, 0.03, (-0.42, -0.18, zt + 0.022), WAX(), verts=10, bevel=0.005)
	sphere((-0.4, -0.2, zt + 0.012), 0.015, WAX(), scale=(1.4, 1.2, 0.5), seg=8, rings=5)
	# the counter's stool knocked over behind the table
	drop(stool((0.1, 0.5, 0.2), rot=(-90, 0, 25)))


def bv_balance_great():
	body, z = plinth(0.58, 0.48, 0.42)
	carve(body, scales_emblem(0, 0.24, 0.07, -0.24, w=0.012, depth=0.014))
	s = 2.4
	group(lambda: balance(s, 6,
		left=lambda x, y, z_: [ingot(x - 0.02, y, z_ - 0.002, 20, l=0.14), ingot(x + 0.03, y + 0.01, z_ + 0.026, -15, l=0.12)],
		right=lambda x, y, z_: [bell_weight(x - 0.03, y, z_ - 0.002, 1.3), disc_weights(x + 0.06, y + 0.02, z_ - 0.002, 3, 0.04)]),
		at=(0, 0.04, z))
	# a brass scale arc behind the pointer on a post from the fork, with notches
	zc = z + 0.34 * s
	pts = [(math.sin(a) * 0.24, zc + math.cos(a) * 0.24) for a in [math.radians(-25 + 5 * j) for j in range(11)]]
	tube([(x, 0.04, zz) for x, zz in pts], 0.008, 0.008, BRASS("dark"), seg=6)
	B((0.014, 0.014, 0.18), (0, 0.04, zc + 0.07 + 0.08), BRASS("dark"), bevel=0.002)
	for x, zz in pts[::2]:
		B((0.005, 0.012, 0.028), (x, 0.03, zz - 0.012), BRASS("b"), bevel=0)


def bv_ledger_desk():
	B((0.78, 0.6, 0.08), (0, 0.02, 0.04), S("c"), bevel=0.015)
	ped = kit.taper(0.56, 0.42, 0.48, 0.36, 0.86, (0, 0.02, 0.075), S("b"), bevel=0.0)
	carve(ped, scales_emblem(0, 0.62, 0.08, -0.168, w=0.012, depth=0.014) + runes(-0.18, 0.18, 0.25, -0.178, h=0.05, gap=0.05))
	B((0.56, 0.2, 0.06), (0, -0.25, 0.4), S("a"), bevel=0.01)  # low shelf for spare ledgers
	for k in range(3):
		ledger(0.2, 0.15, 0.045, LEA("abc"[k]), at=(-0.1 + 0.07 * k, -0.27, 0.43 + k * 0.045 - 0.002), rot=(0, 0, J(8)))
	# the sloped top: a stone slab tipped 16 degrees towards the reader, a lip at the front, a flat ledge at the back
	z = 0.93

	def top():
		B((0.82, 0.56, 0.07), (0, 0, 0), S("a"), bevel=0.012)
		B((0.82, 0.05, 0.05), (0, -0.27, 0.05), S("c"), bevel=0.01)  # book lip
		open_ledger(0.19, 0.28, LEA("b"), at=(0, -0.02, 0.031), lines=8)
	group(top, at=(0, -0.02, z), rot=(16, 0, 0))
	B((0.84, 0.18, 0.08), (0, 0.27, z + 0.08), S("b"), bevel=0.012)  # back ledge
	zl = z + 0.12
	inkwell(0.24, 0.27, zl - 0.002)
	quill((0.245, 0.27, zl + 0.03), rotz=-20, lean=14)
	kit.cylinder(0.05, 0.012, (-0.27, 0.27, zl + 0.004), BRASS("b"), verts=14, bevel=0.003)
	kit.cylinder(0.012, 0.09, (-0.27, 0.27, zl + 0.05), BRASS("a"), verts=10, bevel=0.002)
	kit.cylinder(0.024, 0.014, (-0.27, 0.27, zl + 0.1), BRASS("b"), verts=12, bevel=0.002)
	candle(-0.27, 0.27, zl + 0.104, 0.017, 0.08)
	B((0.3, 0.02, 0.008), (0.0, 0.25, zl + 0.003), BRASS("b"), bevel=0.001)  # brass rule
	for k in range(6):
		B((0.002, 0.012, 0.003), (-0.12 + k * 0.05, 0.245, zl + 0.0075), BRASS("dark"), bevel=0)
	# the ledger is chained to the desk: a ring in the ledge, a chain down to the book's corner
	kit.ring(0.018, 0.005, (0.33, 0.17, zl - 0.03), IRON("dark"), rot=(0, 90, 0), seg=10)
	chain((0.33, 0.165, zl - 0.045), (0.205, 0.02, z + 0.06), link=0.016, wire=0.0045)


def bv_strongbox():
	# round 2 (owner: "make sure the lid opens"): the lid is its own part (LIDS below); the padlock lies unlocked on the step
	B((0.82, 0.6, 0.1), (0, 0, 0.05), S("b"), bevel=0.015)
	group(lambda: strongbox(0.64, 0.42, 0.32), at=(0, 0, 0.096))
	drop(padlock((0.2, -0.255, 0.2), rot=(90, 0, 100), open_=True), 0.1 - 0.003)


def bv_strongbox_looted():
	front = strongbox(0.64, 0.42, 0.32, lid_angle=-112, lock=False)
	carve(front, [cy([(-0.07, 0.24), (0.06, 0.25), (0.08, 0.31), (0.03, 0.36), (-0.05, 0.36), (-0.08, 0.3)], -0.24, 0.07)])  # the lock torn out
	for x, z, a in ((0.07, 0.29, 30), (-0.075, 0.31, -40), (0.03, 0.245, 80)):  # splinters round the hole
		B((0.05, 0.012, 0.01), (x, -0.2, z), WOOD(), bevel=0.002, rot=(0, a, 0))

	def plate():
		B((0.13, 0.014, 0.12), (0, 0, 0), BRASS("b"), bevel=0.004)
		for x in (-0.05, 0.05):
			kit.rivet((x, -0.008, 0.04), BRASS("dark"), r=0.007)
	drop(group(plate, at=(0.25, -0.45, 0.2), rot=(84, 0, 30)))
	drop(padlock((-0.25, -0.42, 0.2), rot=(90, 0, -20), open_=True))
	pry_bar((0.12, -0.5, 0.012), (0.12, -0.12, 0.44))
	for k in range(5):  # a few coins still inside, two on the floor
		coin((J(0.15), J(0.08), 0.068 + k * 0.002), GOLD(J(0.05)), tilt=(J(5), J(5), J(90)))
	coin_fan(-0.05, -0.4, 0.0, 0.08, 0.04, 3)


def bv_coin_chest_tipped(loot=True):
	before = objs()
	strongbox(0.56, 0.38, 0.3, lid_angle=-100, lock=False, band=BRASS("b"), handles=False)
	box = [o for o in objs() if o not in before]
	turn(box, "Y", 90, (0, 0, 0))  # tipped onto its side: the open top faces +X, the lid stands open like a door
	drop(box)
	if not loot:
		return
	x1 = 0.03 + 0.3 - 0.004  # the mouth: the old top rim, now standing at x = its old height
	spots = []
	coin_fan(x1 - 0.12, -0.03, 0.038, 0.08, 0.1, 9, placed=spots)  # coins still lying in the chest
	coin_fan(x1 + 0.03, -0.06, 0.0, 0.42, 0.34, 40, a0=-math.pi * 0.62, a1=math.pi * 0.08, placed=spots)  # the spill
	stack(x1 + 0.3, -0.36, 0.0, 0.03)
	for k in range(3):
		ingot(x1 + 0.22 + k * 0.05, -0.32 - k * 0.07, 0.0, 30 + k * 40, l=0.11)


def bv_coin_chest_tipped_empty():
	bv_coin_chest_tipped(loot=False)


def bv_assay_bench():
	W, D, Hh = 1.35, 0.62, 0.8
	for s_ in (-1, 1):
		leg = B((0.2, 0.52, Hh - 0.145), (s_ * 0.5, 0.0, 0.06 + (Hh - 0.145) / 2), S("b"), bevel=0.015)
		carve(leg, runes(s_ * 0.5 - 0.07, s_ * 0.5 + 0.07, 0.5, -0.26, h=0.05, gap=0.045))
		B((0.28, 0.6, 0.07), (s_ * 0.5, 0, 0.035), S("c"), bevel=0.012)
	B((0.85, 0.42, 0.06), (0, 0.0, 0.25), S("c"), bevel=0.012)  # low shelf
	for k in range(4):  # cupel moulds on the low shelf
		kit.cylinder(0.035, 0.03, (-0.3 + k * 0.08, -0.08, 0.292), S("a"), verts=10, bevel=0.006)
	B((W, D, 0.09), (0, 0, Hh - 0.045), S("a"), bevel=0.015)
	zt = Hh
	# the black touchstone with gold streaks, and touch needles fanned on a brass ring
	B((0.22, 0.13, 0.03), (-0.42, -0.12, zt + 0.012), BLACK(), bevel=0.006)
	for k in range(5):
		B((0.06, 0.006, 0.003), (-0.48 + k * 0.025, -0.13 + J(0.02), zt + 0.0275), GOLD(0.1), bevel=0, rot=(0, 0, 70 + J(8)))
	kit.ring(0.04, 0.004, (-0.18, -0.12, zt + 0.004), BRASS("dark"), seg=16)
	for k in range(6):
		a = 0.4 + k * 0.28
		x, y = -0.18 + math.cos(a) * 0.04, -0.12 + math.sin(a) * 0.04
		B((0.008, 0.07, 0.004), (x + math.cos(a) * 0.035, y + math.sin(a) * 0.035, zt + 0.004), BRASS("abc"[k % 3]), bevel=0.001, rot=(0, 0, math.degrees(a) - 90))
		B((0.004, 0.025, 0.006), (x + math.cos(a) * 0.077, y + math.sin(a) * 0.077, zt + 0.004), GOLD(0.08 - 0.03 * k), bevel=0.001, rot=(0, 0, math.degrees(a) - 90))
	group(lambda: balance(0.6, 3, right=lambda x, y, z: sphere((x, y, z + 0.006), 0.008, GOLD(0.05), seg=8, rings=5),
		left=lambda x, y, z: kit.cylinder(0.008, 0.008, (x, y, z + 0.004), BRASS("dark"), verts=8)), at=(0.05, 0.13, zt - 0.003))
	# three-cornered clay crucibles, a brass dish of ore samples, a stone mortar, a lens on a stand
	for x, y, s in ((0.3, 0.16, 1.0), (0.38, 0.17, 0.8), (0.34, 0.06, 0.7)):
		lathe([(0.004, 0), (0.03 * s, 0), (0.045 * s, 0.07 * s), (0.04 * s, 0.072 * s), (0.026 * s, 0.01 * s), (0.004, 0.01 * s)], (x, y, zt - 0.002), CLAY(), seg=3)
	lathe([(0.004, 0), (0.1, 0.004), (0.12, 0.025), (0.115, 0.028), (0.09, 0.01), (0.004, 0.009)], (0.33, -0.15, zt - 0.002), BRASS("b"), seg=18)
	for k in range(7):
		a = k * 0.9
		kit.gem((0.33 + math.cos(a) * 0.05 * (k % 3) / 2, -0.15 + math.sin(a) * 0.05 * (k % 3) / 2, zt + 0.022), (0.024, 0.02, 0.016),
			(S("dark"), CU("dark"), GOLD(-0.1), IRON("b"))[k % 4], seed=k + 11)
	lathe([(0.004, 0), (0.05, 0), (0.06, 0.05), (0.054, 0.052), (0.04, 0.012), (0.004, 0.012)], (0.55, 0.12, zt - 0.002), S("c"), seg=12)
	rod((0.55, 0.12, zt + 0.02), (0.6, 0.15, zt + 0.13), 0.011, S("b"), seg=6)
	kit.cylinder(0.05, 0.02, (0.55, -0.12, zt + 0.008), BRASS("b"), verts=14, bevel=0.004)
	rod((0.55, -0.12, zt + 0.015), (0.55, -0.12, zt + 0.17), 0.007, BRASS("a"))
	rod((0.55, -0.12, zt + 0.17), (0.48, -0.14, zt + 0.17), 0.006, BRASS("a"))
	kit.ring(0.045, 0.007, (0.43, -0.14, zt + 0.16), BRASS("b"), rot=(70, 0, 0), seg=18)
	kit.cylinder(0.042, 0.004, (0.43, -0.14, zt + 0.16), glass((0.7, 0.85, 0.9), 0.3), rot=(70, 0, 0), verts=18, bevel=0)
	for k in (-1, 1):  # tongs
		tube([(-0.1, -0.24, zt + 0.006), (0.04, -0.23 + k * 0.012, zt + 0.007), (0.1, -0.23 + k * 0.025, zt + 0.007)], 0.006, 0.006, IRON("dark"), seg=5)
	ledger(0.2, 0.15, 0.04, LEA("c"), at=(-0.45, 0.17, zt - 0.002), rot=(0, 0, 8))


def bv_teller_counter():
	W, D, Hh = 1.5, 0.52, 0.95
	B((W + 0.06, D + 0.06, 0.08), (0, 0, 0.04), S("c"), bevel=0.012)
	body = B((W, D, Hh - 0.15), (0, 0, 0.075 + (Hh - 0.15) / 2), S("b"), bevel=0.015)
	carve(body, [cy([(x - 0.2, 0.18), (x + 0.2, 0.18), (x + 0.2, 0.72), (x - 0.2, 0.72)], -D / 2, 0.02) for x in (-0.48, 0.0, 0.48)])
	yv = -D / 2 + 0.005
	fields = [B((0.36, 0.06, 0.5), (x, -D / 2 + 0.035, 0.45), S("a"), bevel=0.012) for x in (-0.48, 0.0, 0.48)]
	carve(fields[0], scales_emblem(-0.48, 0.47, 0.07, yv, w=0.011, depth=0.012))
	carve(fields[1], key_emblem(-0.04, 0.47, 0.22, 35, yv) + key_emblem(0.04, 0.47, 0.22, -35, yv))
	carve(fields[2], runes(0.35, 0.61, 0.56, yv, h=0.05, gap=0.05) + runes(0.35, 0.61, 0.42, yv, h=0.05, gap=0.05, under=False))
	B((W + 0.08, D + 0.08, 0.08), (0, 0, Hh - 0.04), S("a"), bevel=0.015)
	zt = Hh
	# the brass grille: bottom rails either side of the window, top rail, posts, bars, cross rails
	yg = 0.1
	for s_ in (-1, 1):
		B((W / 2 - 0.2, 0.06, 0.05), (s_ * (W / 4 + 0.09), yg, zt + 0.02), BRASS("b"), bevel=0.006)
		B((0.05, 0.05, 0.66), (s_ * (W / 2 - 0.025), yg, zt + 0.35), BRASS("b"), bevel=0.006)
		sphere((s_ * (W / 2 - 0.025), yg, zt + 0.73), 0.035, BRASS("a"), seg=10, rings=6)
		B((W / 2 - 0.22, 0.02, 0.02), (s_ * (W / 4 + 0.095), yg, zt + 0.25), BRASS("dark"), bevel=0.003)
	B((W - 0.012, 0.05, 0.05), (0, yg, zt + 0.68), BRASS("b"), bevel=0.006)
	B((W - 0.06, 0.02, 0.02), (0, yg, zt + 0.52), BRASS("dark"), bevel=0.003)
	for i in range(25):
		x = -W / 2 + 0.08 + i * (W - 0.16) / 24
		if abs(x) < 0.2:
			continue
		kit.cylinder(0.008, 0.62, (x, yg, zt + 0.35), BRASS("a" if i % 2 else "c"), verts=6, bevel=0.001)
	# the arched pay window and the short bars above it
	pts = [(-0.17, zt + 0.03)] + [(math.cos(a) * 0.17, zt + 0.3 + math.sin(a) * 0.17) for a in [math.pi - math.pi * j / 10 for j in range(11)]] + [(0.17, zt + 0.03)]
	tube([(x, yg, z) for x, z in pts], 0.018, 0.018, BRASS("b"), seg=7)
	for x in (-0.11, -0.04, 0.04, 0.11):
		ztop = zt + 0.3 + math.sqrt(0.17 ** 2 - x * x)
		kit.cylinder(0.008, zt + 0.68 - ztop, (x, yg, (zt + 0.68 + ztop) / 2), BRASS("a"), verts=6, bevel=0.001)
	# the coin trough through the window, a counter bell, a closed ledger, coin stacks
	trough = B((0.32, 0.3, 0.03), (0, yg - 0.06, zt + 0.01), BRASS("dark"), bevel=0.004)
	carve(trough, [prism([(-0.135, yg - 0.195), (0.135, yg - 0.195), (0.135, yg + 0.075), (-0.135, yg + 0.075)], zt + 0.012, zt + 0.06, GROOVE(), axis="z")])
	coin_fan(0.0, yg - 0.1, zt + 0.008, 0.07, 0.05, 6)
	kit.cylinder(0.05, 0.012, (-0.45, -0.12, zt + 0.004), BRASS("dark"), verts=14, bevel=0.003)
	lathe([(0.004, 0), (0.05, 0.0), (0.047, 0.01), (0.032, 0.05), (0.02, 0.065), (0.004, 0.068)], (-0.45, -0.12, zt + 0.009), BRASS("b"), seg=16)
	rod((-0.45, -0.12, zt + 0.07), (-0.45, -0.12, zt + 0.1), 0.007, BRASS("a"))
	sphere((-0.45, -0.12, zt + 0.105), 0.012, BRASS("a"), seg=8, rings=5)
	ledger(0.24, 0.17, 0.05, LEA("b"), at=(0.45, -0.11, zt - 0.002), rot=(0, 0, -6))
	stack(0.3, -0.16, zt - 0.002, 0.04)
	stack(0.25, -0.12, zt - 0.002, 0.026)


def bv_guard_post():
	foot((0.5, 0.5, 0.1), (0, 0.1, 0.05), tone=S("c"))
	pil = B((0.36, 0.36, 1.7), (0, 0.1, 0.095 + 0.85), S("b"), bevel=0.02)
	carve(pil, key_emblem(0, 1.15, 0.28, 0, -0.08) + runes(-0.12, 0.12, 0.8, -0.08, h=0.05, gap=0.045) + runes(-0.12, 0.12, 0.68, -0.08, h=0.05, gap=0.045, under=False))
	B((0.44, 0.44, 0.08), (0, 0.1, 1.83), S("a"), bevel=0.015)
	for x in (0.42, 0.78):  # stone bench on the right
		B((0.12, 0.34, 0.38), (x, 0.08, 0.19), S("c"), bevel=0.012)
	B((0.7, 0.38, 0.07), (0.51, 0.08, 0.41), S("a"), bevel=0.012)
	# the guard's helmet left on the bench
	sphere((0.65, 0.06, 0.445), 0.11, IRON("dark"), scale=(1, 1.05, 0.9), seg=16, rings=8, cut=0.0)
	kit.ring(0.11, 0.012, (0.65, 0.06, 0.455), BRASS("b"), seg=18)
	B((0.024, 0.02, 0.09), (0.65, -0.055, 0.49), IRON("dark"), bevel=0.004)
	tube([(0.65, -0.06, 0.48), (0.65, 0.0, 0.56), (0.65, 0.08, 0.55), (0.65, 0.16, 0.47)], 0.012, 0.012, BRASS("a"), seg=6)
	# halberd in a brass floor cup and a brass ring bracket on the pillar
	kit.cylinder(0.05, 0.05, (-0.22, -0.06, 0.125), BRASS("b"), verts=12, bevel=0.004)
	group(lambda: halberd(1.8), at=(-0.22, -0.06, 0.1), rot=(0, 0, 180))
	kit.ring(0.03, 0.008, (-0.22, -0.06, 1.25), BRASS("b"), seg=12)
	B((0.06, 0.03, 0.03), (-0.17, -0.06, 1.25), BRASS("dark"), bevel=0.004)
	# a hand bell on a bracket and a lantern on a hook on the front
	B((0.03, 0.2, 0.03), (0.08, -0.16, 1.45), IRON("dark"), bevel=0.004)
	rod((0.08, -0.25, 1.45), (0.08, -0.25, 1.395), 0.005, IRON("dark"))
	lathe([(0.004, 0), (0.06, 0.0), (0.055, 0.01), (0.04, 0.06), (0.02, 0.08), (0.004, 0.082)], (0.08, -0.25, 1.32), BRASS("b"), seg=16)
	kit.ring(0.057, 0.005, (0.08, -0.25, 1.33), BRASS("dark"), seg=16)
	rod((0.08, -0.25, 1.33), (0.08, -0.25, 1.3), 0.004, BRASS("dark"))
	sphere((0.08, -0.25, 1.3), 0.014, BRASS("dark"), seg=8, rings=5)
	B((0.03, 0.14, 0.03), (-0.08, -0.13, 0.95), IRON("dark"), bevel=0.004)
	tube([(-0.08, -0.19, 0.95), (-0.08, -0.205, 0.93), (-0.08, -0.205, 0.9)], 0.006, 0.006, IRON("dark"), seg=6)
	lantern((-0.08, -0.205, 0.7), 0.2)


def lantern(c, h, lit=True):
	"""A brass cage lantern hanging from its ring at the top: base, posts, glass panes, cap, candle."""
	x, y, z = c
	r = h * 0.32
	lathe([(0.004, 0), (r * 1.05, 0), (r * 1.1, 0.015), (r * 0.9, 0.025), (0.004, 0.025)], (x, y, z), BRASS("b"), seg=6)
	for k in range(6):
		a = 2 * math.pi * k / 6
		rod((x + math.cos(a) * r, y + math.sin(a) * r, z + 0.02), (x + math.cos(a) * r, y + math.sin(a) * r, z + h * 0.72), 0.005, BRASS("a"), seg=5)
	kit.cylinder(r * 0.96, h * 0.66, (x, y, z + 0.02 + h * 0.33), glass((0.95, 0.75, 0.45), 0.25, glow=0.3), verts=6, bevel=0)
	kit.cone(r * 1.12, r * 0.25, h * 0.22, (x, y, z + h * 0.72 + h * 0.11 - 0.005), BRASS("b"), verts=6)
	kit.ring(0.018, 0.005, (x, y, z + h * 0.95), BRASS("dark"), rot=(90, 0, 0), seg=10)
	for k in range(6):
		a = 2 * math.pi * k / 6
		kit.rivet((x + math.cos(a) * r, y + math.sin(a) * r, z + h * 0.73), BRASS("dark"), r=0.006)
	if lit:
		candle(x, y, z + 0.024, r * 0.3, h * 0.3)


def bv_minting_block():
	# a squat eight-sided cut-stone block, the hold's scales cut into its front, an iron plate holding the die.
	# Round 2 (owner): more on the top, and the hammer stands in its own hole in the top (its handle clear of the floor).
	B((0.62, 0.62, 0.06), (0, 0, 0.03), S("c"), bevel=0.012)
	blk = kit.cylinder(0.27, 0.57, (0, 0, 0.055 + 0.285), S("b"), rot=(0, 0, 22.5), verts=8, bevel=0.012)
	yf = -0.27 * math.cos(math.radians(22.5))
	hx, hy = 0.2, -0.1  # the hammer's hole
	sock = lambda: kit.cylinder(0.024, 0.3, (hx, hy, 0.6), GROOVE(), verts=12, bevel=0)  # noqa: E731
	carve(blk, scales_emblem(0, 0.36, 0.08, yf, w=0.012, depth=0.014) + runes(-0.08, 0.08, 0.16, yf, h=0.045, gap=0.04) + [sock()])
	# a cap stone, a little wider than the block: a groove ring round the die plate and tally notches cut in its edge
	cap = kit.cylinder(0.29, 0.05, (0, 0, 0.645), S("a"), rot=(0, 0, 22.5), verts=8, bevel=0.01)
	ring_ = [prism(bar(p0, p1, 0.012), 0.662, 0.7, GROOVE(), axis="z") for p0, p1 in
		(((-0.17, -0.17), (0.17, -0.17)), ((0.17, -0.17), (0.17, 0.17)), ((0.17, 0.17), (-0.17, 0.17)), ((-0.17, 0.17), (-0.17, -0.17)))]
	yc = -0.29 * math.cos(math.radians(22.5))
	notches = [cy(bar((x, 0.628), (x, 0.662), 0.01), yc, 0.012) for x in (-0.07, -0.045, -0.02, 0.005, 0.03)]
	carve(cap, ring_ + notches + [sock()])
	z = 0.05  # everything on top sits on the cap
	B((0.3, 0.3, 0.02), (0, 0, 0.625 + z), IRON("dark"), bevel=0.004)
	for sx in (-1, 1):
		for sy in (-1, 1):
			kit.rivet((sx * 0.12, sy * 0.12, 0.636 + z), IRON("a"), r=0.01)
		kit.taper(0.03, 0.05, 0.012, 0.05, 0.035, (sx * 0.068, 0, 0.633 + z), IRON("a"), bevel=0.003)  # wedges holding the die
	kit.cylinder(0.05, 0.08, (0, 0, 0.6 + z), IRON("dark"), verts=10, bevel=0.004)  # lower die
	kit.cylinder(0.02, 0.006, (0, 0, 0.641 + z), GOLD(0.05), verts=12, bevel=0.001)  # a blank on it
	kit.cylinder(0.026, 0.16, (0, 0, 0.723 + z), IRON("a"), verts=8, bevel=0.003)  # the upper die (punch) standing on it
	kit.cylinder(0.036, 0.03, (0, 0, 0.815 + z), IRON("dark"), verts=8, bevel=0.006)  # its struck, spread head
	kit.ring(0.028, 0.006, (0, 0, 0.7 + z), BRASS("b"), seg=10)
	kit.ring(0.028, 0.006, (0, 0, 0.76 + z), BRASS("b"), seg=10)

	def ham():  # the minting hammer standing head-up in its hole
		log((0, 0, 0), (0, 0, 0.42), 0.017, WOOD(), seg=6, rings=2, ends=False, bend=0.0)
		B((0.06, 0.06, 0.15), (0, 0, 0.44), IRON("dark"), bevel=0.01, rot=(0, 90, 0))
		for s_ in (-1, 1):
			B((0.012, 0.066, 0.066), (s_ * 0.05, 0, 0.44), BRASS("b"), bevel=0.003)  # brass bands on the head
		kit.ring(0.02, 0.005, (0, 0, 0.36), BRASS("b"), seg=10)
	group(ham, at=(hx, hy, 0.455), rot=(0, 0, 30))  # handle end on the hole's floor
	kit.ring(0.03, 0.006, (hx, hy, 0.671), IRON("a"), seg=12)  # an iron collar round the hole
	# a brass tray of copper blanks, a bowl of struck coins, struck stacks, tweezers and a gauge plate on the cap
	tx = -0.14
	B((0.16, 0.1, 0.012), (tx, 0.07, 0.63 + z), BRASS("b"), bevel=0.003)
	for s_ in (-1, 1):
		B((0.16, 0.008, 0.024), (tx, 0.07 + s_ * 0.05, 0.64 + z), BRASS("a"), bevel=0.002)
		B((0.008, 0.1, 0.024), (tx + s_ * 0.08, 0.07, 0.64 + z), BRASS("a"), bevel=0.002)
	for k in range(9):
		kit.cylinder(0.016, 0.005, (tx - 0.05 + (k % 3) * 0.05, 0.04 + (k // 3) * 0.03, 0.638 + z + (k % 2) * 0.0018), CU("b"), verts=10, bevel=0.001)
	lathe([(0.004, 0), (0.05, 0.003), (0.065, 0.03), (0.06, 0.032), (0.045, 0.008), (0.004, 0.007)], (0.13, 0.13, 0.623 + z), BRASS("b"), seg=14)
	coin_pile(0.13, 0.13, 0.628 + z, 0.04, 0.04, 9, 0.012)
	for k, (x, y) in enumerate(((-0.2, -0.04), (-0.155, -0.08), (-0.2, -0.12))):
		stack(x, y, 0.67, 0.025 + 0.012 * k, r=0.02)
	for s_ in (-1, 1):  # tweezers lying on the cap, the two legs meeting at the bow
		rod((0.03, -0.215, 0.674), (0.12, -0.215 + s_ * 0.012, 0.674), 0.004, IRON("a"))
	gauge = B((0.1, 0.05, 0.008), (-0.03, 0.2, 0.674), BRASS("dark"), bevel=0.002, rot=(0, 0, 8))
	carve(gauge, [prism(circ(-0.06 + 0.03 * k, 0.2 + 0.004 * k, 0.006 + 0.003 * k, n=10, wob=0), 0.66, 0.69, GROOVE(), axis="z") for k in range(3)])
	# the punched blank strip and loose blanks on the floor
	strip = B((0.38, 0.06, 0.006), (-0.2, -0.32, 0.003), CU("b"), bevel=0.001, rot=(0, 0, 20))
	ca, sa = math.cos(math.radians(20)), math.sin(math.radians(20))
	carve(strip, [prism(circ(-0.2 + ca * d, -0.32 + sa * d, 0.017, n=10, wob=0), -0.01, 0.02, GROOVE(), axis="z") for d in (-0.14, -0.07, 0.0, 0.07)])
	for k in range(4):
		kit.cylinder(0.016, 0.005, (0.1 + k * 0.05, -0.35 + J(0.03), 0.003 + k * 0.0018), CU("b"), rot=(J(4), J(4), 0), verts=10, bevel=0.001)


def bv_assay_furnace():
	W, D, Hh = 0.74, 0.62, 1.0
	B((W + 0.1, D + 0.1, 0.08), (0, 0, 0.04), S("c"), bevel=0.012)
	body = B((W, D, Hh - 0.08), (0, 0, 0.075 + (Hh - 0.08) / 2), S("b"), bevel=0.02)
	yf = -D / 2
	fire = [(-0.15, 0.1), (0.15, 0.1)] + [(math.cos(a) * 0.15, 0.24 + math.sin(a) * 0.15) for a in [math.pi * k / 10 for k in range(11)]]
	muf = [(-0.17, 0.5), (0.17, 0.5)] + [(math.cos(a) * 0.17, 0.62 + math.sin(a) * 0.12) for a in [math.pi * k / 10 for k in range(11)]]
	carve(body, [prism(fire, yf - 0.03, yf + 0.3, GROOVE()), prism(muf, yf - 0.03, yf + 0.26, GROOVE())] + runes(-0.26, 0.26, 0.88, yf, h=0.05, gap=0.05))
	B((0.4, 0.08, 0.05), (0, yf - 0.02, 0.48), S("a"), bevel=0.01)  # muffle sill
	B((0.4, 0.07, 0.05), (0, yf - 0.015, 0.075), S("a"), bevel=0.01)
	# Round 2 (owner: "more details in the holes"). The furnace is long cold (no glow, round-2 rule).
	# Firebox: an arch of wedge stones round the mouth, a sooty firebrick back, an iron grate on two bearers, cold charcoal.
	def arch(cx, cz, rx, rz, z0, n, depth=0.04, band=0.055):
		for k in range(n):  # every other stone stands 1 cm prouder
			depth = 0.04 + 0.012 * (k % 2)
			a = math.pi * (k + 0.5) / n
			px, pz = cx + math.cos(a) * (rx + band / 2), cz + math.sin(a) * (rz + band / 2)
			L = math.pi * ((rx + rz) / 2 + band * 0.25) / n - 0.004  # a 4 mm joint at the inner edge
			B((L, depth, band), (px, yf - depth / 2 + 0.006, pz), S("a" if k % 2 else "c"), bevel=0.006,
				rot=(0, -math.degrees(a) + 90, 0))
		for sx in (-1, 1):  # jamb stones down the straight sides
			B((band, depth, cz - z0 - 0.008), (cx + sx * (rx + band / 2), yf - depth / 2 + 0.006, (cz + z0) / 2), S("b"), bevel=0.006)
	arch(0, 0.24, 0.15, 0.15, 0.1, 7)
	for row in range(6):  # firebricks lining the back of the firebox
		zb = 0.115 + row * 0.045
		half = 0.14 if zb < 0.24 else math.sqrt(max(0.0, 0.15 ** 2 - (zb + 0.022 - 0.24) ** 2)) - 0.012
		x = -half + (0.04 if row % 2 else 0.0)
		while x < half - 0.03:
			w = min(0.085, half - x)
			B((w - 0.006, 0.02, 0.04), (x + w / 2, yf + 0.294, zb + 0.02), C((0.2, 0.12, 0.08), 0.95), bevel=0.003)
			x += w
	for sx in (-1, 1):  # grate bearers let into the side walls, the grate bars across them
		B((0.03, 0.25, 0.02), (sx * 0.142, yf + 0.15, 0.165), IRON("dark"), bevel=0.003)
	for k in range(6):
		B((0.012, 0.25, 0.016), (-0.112 + k * 0.045, yf + 0.15, 0.183), IRON("dark" if k % 2 else "a"), bevel=0.002)
	coal_heap(0, yf + 0.15, 0.19, 0.1, 12, hot=0, seed=3)  # the last charge, gone cold on the grate
	coal_heap(0, yf + 0.12, 0.1, 0.07, 4, hot=0, seed=9)  # bits that fell through
	# Muffle: an iron frame round the mouth, the clay muffle (a little arched oven) inside, cupels and beads in it
	mo = [(0.165, 0.5)] + [(math.cos(a) * 0.165, 0.62 + math.sin(a) * 0.115) for a in [math.pi * k / 12 for k in range(13)]] + [(-0.165, 0.5)]
	tube([(x, yf - 0.004, z) for x, z in mo], 0.011, 0.011, IRON("dark"), seg=6)
	mclay = C((0.42, 0.33, 0.24), 0.9)
	outer = [(0.15, 0.513)] + [(math.cos(a) * 0.15, 0.6 + math.sin(a) * 0.1) for a in [math.pi * k / 10 for k in range(11)]] + [(-0.15, 0.513)]
	inner = [(-0.125, 0.513)] + [(math.cos(a) * 0.125, 0.6 + math.sin(a) * 0.075) for a in [math.pi - math.pi * k / 10 for k in range(11)]] + [(0.125, 0.513)]
	prism(outer + inner, yf + 0.02, yf + 0.245, mclay)  # the muffle's arched shell, open at the front
	prism([(-0.15, 0.513), (0.15, 0.513)] + [(math.cos(a) * 0.15, 0.6 + math.sin(a) * 0.1) for a in [math.pi * k / 10 for k in range(11)]][::-1],
		yf + 0.235, yf + 0.255, mclay)  # its back wall
	B((0.33, 0.22, 0.012), (0, yf + 0.135, 0.507), mclay, bevel=0.002)  # the muffle floor plate
	for k, x in enumerate((-0.08, 0.0, 0.08)):
		for j, yy in enumerate((yf + 0.07, yf + 0.16)):
			lathe([(0.004, 0), (0.025, 0), (0.03, 0.02), (0.026, 0.022), (0.016, 0.01), (0.004, 0.01)], (x, yy, 0.513), C((0.75, 0.72, 0.66), 0.9), seg=10)
			if (k + j) % 2 == 0:
				sphere((x, yy, 0.525), 0.008, GOLD(0.15) if j else SILV("a"), seg=8, rings=5)  # a cooled bead of metal

	def door():
		B((0.3, 0.025, 0.24), (0.15, 0, 0), IRON("dark"), bevel=0.006)
		for zz in (-0.08, 0.08):
			B((0.32, 0.03, 0.03), (0.15, -0.004, zz), BRASS("b"), bevel=0.004)
		B((0.02, 0.06, 0.02), (0.28, -0.04, 0.0), BRASS("a"), bevel=0.003)
		sphere((0.28, -0.075, 0.0), 0.016, BRASS("a"), seg=8, rings=5)
	group(door, at=(0.19, yf - 0.035, 0.6), rot=(0, 0, -30))  # swung well open: the firebox and muffle show
	for zz in (0.52, 0.68):  # hinge pins and straps
		kit.cylinder(0.014, 0.05, (0.19, yf - 0.035, zz), IRON("dark"), verts=8)
		B((0.04, 0.03, 0.02), (0.2, yf - 0.012, zz), IRON("dark"), bevel=0.003)
	B((W + 0.04, D + 0.04, 0.07), (0, 0, Hh + 0.035), S("a"), bevel=0.015)
	flue = [(-0.08, 0.0), (0.08, 0.0), (0.08, 0.14), (-0.08, 0.14)]
	ch = B((0.3, 0.3, 0.42), (0, 0.06, Hh + 0.28), S("b"), bevel=0.015)
	carve(ch, [prism(flue, Hh + 0.3, Hh + 0.6, GROOVE(), axis="z")])
	cap = B((0.36, 0.36, 0.05), (0, 0.06, Hh + 0.505), S("a"), bevel=0.012)
	carve(cap, [prism(flue, Hh + 0.3, Hh + 0.6, GROOVE(), axis="z")])
	for k, zz in enumerate((0.85, 0.6)):  # tongs and a rake on hooks on the side
		B((0.06, 0.02, 0.02), (W / 2 + 0.025, -0.1 + k * 0.18, zz), IRON("dark"), bevel=0.003)
	for k in (-1, 1):
		tube([(W / 2 + 0.05, -0.1, 0.86), (W / 2 + 0.06, -0.1 + k * 0.015, 0.6), (W / 2 + 0.06, -0.1 + k * 0.025, 0.45)], 0.006, 0.006, IRON("dark"), seg=5)
	rod((W / 2 + 0.05, 0.08, 0.61), (W / 2 + 0.05, 0.08, 0.2), 0.008, IRON("dark"))
	B((0.02, 0.1, 0.05), (W / 2 + 0.05, 0.08, 0.2), IRON("dark"), bevel=0.003)


def bv_coin_cart():
	B((0.9, 0.56, 0.05), (0, 0, 0.24), WOOD(), bevel=0.008)
	for sy in (-1, 1):
		B((0.96, 0.06, 0.08), (0, sy * 0.27, 0.24), WOOD(), bevel=0.01)
		for x in (-0.4, 0.0, 0.4):
			B((0.05, 0.072, 0.09), (x, sy * 0.27, 0.24), IRON("dark"), bevel=0.004)
	for sx in (-1, 1):
		B((0.06, 0.6, 0.08), (sx * 0.45, 0, 0.24), WOOD(), bevel=0.01)
	for x in (-0.3, 0.3):  # solid iron wheels outside the frame, brass hubs, axle brackets
		rod((x, -0.37, 0.12), (x, 0.37, 0.12), 0.02, IRON("dark"))
		for sy in (-1, 1):
			kit.cylinder(0.12, 0.05, (x, sy * 0.34, 0.12), IRON("dark"), rot=(90, 0, 0), verts=14, bevel=0.008)
			kit.cylinder(0.04, 0.06, (x, sy * 0.355, 0.12), BRASS("b"), rot=(90, 0, 0), verts=10, bevel=0.004)
			B((0.06, 0.04, 0.12), (x, sy * 0.23, 0.18), IRON("a"), bevel=0.004)
	for sy in (-1, 1):  # push handle
		rod((0.47, sy * 0.2, 0.26), (0.72, sy * 0.2, 0.62), 0.02, WOOD())
	rod((0.72, -0.24, 0.62), (0.72, 0.24, 0.62), 0.024, WOOD())
	kit.cylinder(0.03, 0.2, (0.72, 0, 0.62), LEA("dark"), rot=(90, 0, 0), verts=10, bevel=0.004)
	for sy in (-1, 1):
		kit.ring(0.026, 0.006, (0.72, sy * 0.1, 0.62), BRASS("b"), rot=(90, 0, 0), seg=10)
	group(lambda: strongbox(0.56, 0.38, 0.26, band=BRASS("b")), at=(-0.04, 0, 0.262))
	for sx in (-1, 1):  # chained down to rings on the bed
		kit.ring(0.02, 0.005, (-0.04 + sx * 0.34, -0.24, 0.27), IRON("a"), rot=(0, 90, 0), seg=10)
		chain((-0.04 + sx * 0.34, -0.24, 0.29), (-0.04 + sx * 0.18, -0.205, 0.58), link=0.016, wire=0.0045)
	padlock((-0.04, -0.222, 0.47))


def bv_lockbox_pedestal():
	body, zt = plinth(0.46, 0.4, 0.92)
	carve(body, key_emblem(-0.05, 0.55, 0.24, 30, -0.2) + key_emblem(0.05, 0.55, 0.24, -30, -0.2)
		+ runes(-0.15, 0.15, 0.3, -0.2, h=0.045, gap=0.045))
	# the casket
	z = zt
	B((0.24, 0.16, 0.12), (0, 0, z + 0.06), BRASS("b"), bevel=0.008)
	B((0.26, 0.18, 0.02), (0, 0, z + 0.01), BRASS("dark"), bevel=0.004)
	lid = B((0.25, 0.17, 0.04), (0, 0, z + 0.14), BRASS("a"), bevel=0.01)
	B((0.16, 0.1, 0.03), (0, 0, z + 0.17), BRASS("b"), bevel=0.01)
	sphere((0, 0, z + 0.2), 0.018, GOLD(0.05), seg=10, rings=6)
	for x in (-0.06, 0.06):
		B((0.03, 0.172, 0.13), (x, 0, z + 0.07), BRASS("dark"), bevel=0.003)
	B((0.05, 0.01, 0.05), (0, -0.084, z + 0.08), IRON("dark"), bevel=0.003)
	for sx in (-1, 1):
		for sy in (-1, 1):
			sphere((sx * 0.11, sy * 0.07, z + 0.01), 0.016, BRASS("dark"), seg=8, rings=5)
	# the domed brass cage over it
	R = 0.19
	kit.ring(R, 0.012, (0, 0, z + 0.01), BRASS("b"), seg=24)
	kit.ring(R, 0.01, (0, 0, z + 0.26), BRASS("b"), seg=24)
	for k in range(12):
		a = 2 * math.pi * k / 12
		rod((math.cos(a) * R, math.sin(a) * R, z + 0.01), (math.cos(a) * R, math.sin(a) * R, z + 0.26), 0.005, BRASS("a"))
	for k in range(6):
		a = math.pi * k / 6
		pts = [(math.cos(a) * R * math.cos(t), math.sin(a) * R * math.cos(t), z + 0.26 + R * 0.8 * math.sin(t)) for t in [math.pi * j / 12 for j in range(13)]]
		tube(pts, 0.005, 0.005, BRASS("a"), seg=5)
	sphere((0, 0, z + 0.26 + R * 0.8 + 0.01), 0.025, BRASS("b"), seg=10, rings=6)
	kit.ring(0.02, 0.005, (0, 0, z + 0.26 + R * 0.8 + 0.04), BRASS("dark"), rot=(90, 0, 0), seg=10)
	# name plate on the plinth front
	plate = B((0.2, 0.012, 0.06), (0, -0.206, 0.82), BRASS("b"), bevel=0.003)
	carve(plate, runes(-0.08, 0.08, 0.82, -0.213, h=0.03, w=0.006, gap=0.028, depth=0.004, under=False))


# ================= wall pieces =================
def bv_ledger_shelf():
	W, H, D = 1.25, 1.75, 0.38
	foot((W + 0.06, D + 0.04, 0.08), (0, 0, 0.04), tone=S("c"))
	B((W, 0.08, H), (0, D / 2 - 0.04, 0.075 + H / 2), S("b"), bevel=0.012)  # back
	for s_ in (-1, 1):
		B((0.09, D, H), (s_ * (W / 2 - 0.045), 0, 0.075 + H / 2), S("a"), bevel=0.012)
	B((W + 0.06, D + 0.04, 0.07), (0, -0.01, 0.075 + H + 0.03), S("a"), bevel=0.012)
	zs = (0.1, 0.55, 1.0, 1.42)
	for k, z in enumerate(zs):
		sh = B((W - 0.17, D - 0.075, 0.06), (0, -0.035, z + 0.03), S("c" if k % 2 else "a"), bevel=0.01)
		if k:
			carve(sh, runes(-0.48, -0.38, z + 0.03, -D / 2 + 0.003, h=0.032, w=0.007, gap=0.05, depth=0.006, under=False)
				+ runes(0.38, 0.48, z + 0.03, -D / 2 + 0.003, h=0.032, w=0.007, gap=0.05, depth=0.006, under=False))
			for x in (-0.2, 0.2):  # brass label plates
				B((0.14, 0.008, 0.04), (x, -D / 2 + 0.002 - 0.003, z + 0.03), BRASS("b"), bevel=0.002)
	inner = W - 0.18
	yb = D / 2 - 0.085
	for k, z in enumerate(zs[:-1]):
		z0 = z + 0.06 - 0.003
		x = -inner / 2 + 0.01
		limit = inner / 2 - 0.01
		while x < limit - 0.05:
			t = rng.uniform(0.04, 0.07)
			if k == 1 and x > -0.29 and x < 0.15:  # a stack lying flat in the middle
				for j in range(3):
					ledger(0.27, 0.2, 0.05, LEA("abc"[j]), at=(-0.04, yb - 0.12, z0 + j * 0.05 - 0.001), rot=(0, 0, 180 + J(4)))
				x = 0.15
				continue
			hh = rng.uniform(0.26, 0.36)
			d = rng.uniform(0.22, 0.27)

			def bk(t=t, hh=hh, d=d, m=LEA(rng.choice(("a", "b", "c", "dark")))):
				B((0.007, d, hh), (-t / 2 + 0.0035, 0, hh / 2), m, bevel=0.002)
				B((0.007, d, hh), (t / 2 - 0.0035, 0, hh / 2), m, bevel=0.002)
				B((t + 0.004, 0.012, hh + 0.002), (0, -d / 2 - 0.002, hh / 2 + 0.001), m, bevel=0.004)  # spine
				B((t - 0.01, d - 0.01, hh - 0.016), (0, 0.004, hh / 2), PAPER(), bevel=0.002)
				for zz in (0.035, hh - 0.035):
					B((t + 0.008, 0.008, 0.012), (0, -d / 2 - 0.007, zz), BRASS("b" if zz < 0.1 else "a"), bevel=0.002)
			lean = 9 if (k == 2 and limit - x < 0.12) else 0
			if lean:
				x += 0.03
			group(bk, at=(x + t / 2, yb - d / 2, z0), rot=(0, lean, 0))
			x += t + 0.004
	z0 = zs[3] + 0.057  # top shelf: brass scroll tubes and a pile of ledgers
	for j, x in enumerate((-0.4, -0.33, -0.26, -0.19)):
		kit.cylinder(0.03, 0.26, (x, 0.0, z0 + 0.027), BRASS("abc"[j % 3]), rot=(90, 0, 0), verts=12, bevel=0.003)
		kit.cylinder(0.034, 0.03, (x, -0.13, z0 + 0.027), BRASS("dark"), rot=(90, 0, 0), verts=12, bevel=0.003)
	for j in range(3):
		x = -0.365 + j * 0.07
		kit.cylinder(0.03, 0.26, (x, 0.0, z0 + 0.027 + 0.052), BRASS("a"), rot=(90, 0, 0), verts=12, bevel=0.003)
		kit.cylinder(0.034, 0.03, (x, -0.13, z0 + 0.027 + 0.052), BRASS("dark"), rot=(90, 0, 0), verts=12, bevel=0.003)
	for j in range(4):
		ledger(0.27, 0.2, 0.05, LEA("abc"[j % 3]), at=(0.3, yb - 0.11, z0 + j * 0.05 - 0.001), rot=(0, 0, 180 + J(5)))
	flat_back(D / 2)
	slim(small=0.03, fine=0.005, few=0.02)  # lighter file (under 2 MB), same look


def key_board(looted=False):
	W, H = 0.95, 1.5
	slab, yf = wall_slab(W, H, 0.14)
	cuts = []
	rows = (1.3, 0.98, 0.66)
	for z in rows:
		cuts += runes(-0.36, 0.36, z + 0.1, yf, h=0.04, w=0.008, gap=0.144, depth=0.008, under=False)
	cuts += key_emblem(-0.07, 0.3, 0.36, 35, yf, w=0.016, depth=0.014) + key_emblem(0.07, 0.3, 0.36, -35, yf, w=0.016, depth=0.014)
	carve(slab, cuts)
	frame_band(W - 0.04, 1.08, yf, z0=0.5)
	yr = yf - 0.035  # front of the brass hook rails
	for i, z in enumerate(rows):
		B((W - 0.2, 0.04, 0.06), (0, yf - 0.015, z), BRASS("dark"), bevel=0.005)
		for j in range(5):
			x = -0.34 + j * 0.17
			k = i * 5 + j
			if looted and k in (2, 8):  # bent hooks
				kit.cylinder(0.02, 0.012, (x, yr - 0.002, z), BRASS("dark"), rot=(90, 0, 0), verts=12, bevel=0.002)
				tube([(x, yr - 0.004, z), (x + 0.01, yr - 0.04, z - 0.02), (x + 0.03, yr - 0.05, z - 0.06)], 0.006, 0.005, BRASS("b"), seg=6)
				continue
			hook(x, yr, z)
			if looted and k not in (5, 13):
				continue
			yk = yr - 0.058
			L = 0.12 + 0.04 * ((k * 7) % 3)
			m = BRASS("b") if k % 3 else IRON("dark")
			if k == 7 and not looted:  # a ring of three keys
				kit.ring(0.035, 0.005, (x, yk, z - 0.025), IRON("a"), rot=(90, 0, 0), seg=16)
				for q, dx in enumerate((-0.02, 0.0, 0.02)):
					zq = z - 0.025 - math.sqrt(0.035 ** 2 - dx * dx) + 0.006
					group(lambda q=q: key_part(0.08 + 0.015 * q, 0.6, BRASS("b") if q == 1 else IRON("dark"), 1), at=(x + dx, yk, zq), rot=(0, 0, 90))
				continue
			group(lambda L=L, m=m, k=k: key_part(L, 1.0, m, 1 + k % 3), at=(x, yk, z + 0.006))
			tag(x, yk, z - 0.07)
	if looted:  # keys dropped at the foot
		for k, (x, rz) in enumerate(((-0.25, 30), (0.1, -60), (0.3, 110))):
			drop(group(lambda k=k: key_part(0.14 + 0.03 * k, 1.0, BRASS("b") if k != 1 else IRON("dark"), 2), at=(x, -0.22, 0.3), rot=(90, 0, rz)))
	flat_back(0.07)


def bv_key_rack():
	key_board(False)


def bv_key_rack_looted():
	key_board(True)


def bv_weight_shelf():
	W, H = 1.05, 1.55
	slab, yf = wall_slab(W, H, 0.14)
	carve(slab, scales_emblem(0, 0.42, 0.13, yf, w=0.016, depth=0.014) + runes(-0.4, 0.4, 0.2, yf, h=0.05, gap=0.06))
	for k, z in enumerate((0.78, 1.18)):
		sh = B((W - 0.08, 0.24, 0.06), (0, yf - 0.1, z), S("a"), bevel=0.01)
		carve(sh, runes(-0.4, 0.4, z, yf - 0.22, h=0.032, w=0.007, gap=0.1, depth=0.006, under=False))
		for x in (-0.38, 0.38):  # corbels
			prism([(yf + 0.01, z - 0.17), (yf - 0.04, z - 0.17), (yf - 0.2, z - 0.025), (yf + 0.01, z - 0.025)], x - 0.04, x + 0.04, S("b"), axis="x")
		zt = z + 0.03
		if k == 1:  # top shelf: bell weights from huge to tiny, and a small balance
			x = -0.4
			for j in range(6):
				s = 1.25 - 0.17 * j
				bell_weight(x, yf - 0.1, zt - 0.002, s)
				x += 0.045 * s + 0.045 * (1.25 - 0.17 * (j + 1)) + 0.012
			group(lambda: balance(0.6, 0), at=(0.33, yf - 0.1, zt - 0.003))
		else:  # bottom shelf: disc stacks, a cup-weight case with its lid ajar, loose cups
			for j, (x, n) in enumerate(((-0.38, 5), (-0.26, 4), (-0.15, 3), (-0.06, 2))):
				disc_weights(x, yf - 0.1, zt - 0.002, n, r=0.05 - 0.007 * j)
			lathe([(0.004, 0), (0.05, 0), (0.055, 0.06), (0.05, 0.062), (0.044, 0.006), (0.004, 0.006)], (0.07, yf - 0.1, zt - 0.002), BRASS("b"), seg=16)
			kit.ring(0.054, 0.004, (0.07, yf - 0.1, zt + 0.03), BRASS("dark"), seg=16)
			kit.cylinder(0.057, 0.012, (0.085, yf - 0.1, zt + 0.067), BRASS("a"), rot=(0, 9, 0), verts=16, bevel=0.003)
			for j in range(3):
				r = 0.042 - 0.009 * j
				lathe([(0.004, 0), (r, 0), (r + 0.004, 0.035 - 0.006 * j), (r, 0.036 - 0.006 * j), (r - 0.004, 0.004), (0.004, 0.004)],
					(0.18 + j * 0.085, yf - 0.1, zt - 0.002), BRASS("abc"[j]), seg=14)
	flat_back(0.07)


def bv_name_plaque():
	W, H = 1.0, 1.6
	slab, yf = wall_slab(W, H, 0.16)
	carve(slab, scales_emblem(0, 0.44, 0.17, yf, w=0.02, depth=0.016) + runes(-0.36, 0.36, 0.17, yf, h=0.05, gap=0.06))
	frame_band(W - 0.04, 0.52, yf, z0=1.0)
	yp = yf - 0.05  # front of the brass plaque
	plate = B((0.72, 0.03, 0.4), (0, yp + 0.015, 1.26), BRASS("b"), bevel=0.012)
	cuts = []
	for z in (1.36, 1.25, 1.15):
		cuts += runes(-0.26, 0.26, z, yp, h=0.06, w=0.011, gap=0.048, depth=0.007, under=z == 1.36)
	cuts += gline([(-0.33, 1.09), (0.33, 1.09), (0.33, 1.43), (-0.33, 1.43), (-0.33, 1.09)], 0.008, yp, 0.004)
	carve(plate, cuts)
	for sx in (-1, 1):
		for z in (1.1, 1.42):
			kit.cylinder(0.012, 0.06, (sx * 0.335, yf - 0.03, z), IRON("dark"), rot=(90, 0, 0), verts=8, bevel=0.002)
			kit.cylinder(0.022, 0.012, (sx * 0.335, yp - 0.005, z), IRON("dark"), rot=(90, 0, 0), verts=6, bevel=0.002)
	flat_back(0.08)


def bv_coin_niche_found(loot=True):
	W, H, D = 1.1, 1.4, 0.42
	foot((W + 0.08, D + 0.06, 0.1), (0, -0.03, 0.05), tone=S("c"))
	body = B((W, D, H - 0.1), (0, 0, 0.1 + (H - 0.1) / 2), S("b"), bevel=0.02)
	B((W + 0.06, D + 0.04, 0.07), (0, -0.01, H + 0.03), S("a"), bevel=0.015)
	yf = -D / 2
	cuts = [cy(bar((-W / 2 - 0.01, z), (W / 2 + 0.01, z), 0.014), yf, 0.012) for z in (0.42, 0.74, 1.06)]
	for (z0, z1), xs in (((0.1, 0.42), (-0.28, 0.24)), ((0.42, 0.74), (-0.34,)), ((0.74, 1.06), (-0.02, 0.4)), ((1.06, 1.4), (-0.28, 0.24))):
		cuts += [cy(bar((x, z0), (x, z1), 0.014), yf, 0.012) for x in xs]
	nx0, nx1, nz0, nz1 = 0.0, 0.38, 0.413, 0.747  # the hidden niche where one block came out
	cuts.append(prism([(nx0, nz0), (nx1, nz0), (nx1, nz1), (nx0, nz1)], yf - 0.03, yf + 0.28, GROOVE()))
	carve(body, cuts)
	yc = yf + 0.15
	cx = (nx0 + nx1) / 2
	B((0.14, 0.1, 0.08), (cx - 0.08, yc + 0.06, nz0 + 0.036), IRON("dark"), bevel=0.006)  # a small iron coffer
	B((0.15, 0.11, 0.02), (cx - 0.08, yc + 0.06, nz0 + 0.084), IRON("a"), bevel=0.004)
	B((0.03, 0.01, 0.03), (cx - 0.08, yc + 0.006, nz0 + 0.06), BRASS("b"), bevel=0.002)
	if loot:
		for k, x in enumerate((cx + 0.06, cx + 0.12)):
			stack(x, yc + 0.08, nz0 - 0.002, 0.06 + 0.02 * k)
		coin_pile(cx + 0.03, yc - 0.06, nz0, 0.1, 0.05, 22, 0.025)
	# the cover block lying on the floor, the pry bar, a few coins on the wall foot, chips
	B((0.37, 0.3, 0.27), (0.32, yf - 0.36, 0.135), S("b"), bevel=0.02, rot=(0, 0, 14))
	pry_bar((-0.25, yf - 0.3, 0.025), (0.08, yf - 0.4, 0.013))
	if loot:
		coin_fan(0.17, yf - 0.035, 0.1, 0.06, 0.012, 3)
	rough_chips([(0.0, yf - 0.24, 0.025), (0.05, yf - 0.62, 0.02), (-0.4, yf - 0.2, 0.022)])
	flat_back(D / 2)


def bv_coin_niche_found_empty():
	bv_coin_niche_found(loot=False)


def bv_pigeonholes(loot=True):
	W, H, D = 1.25, 1.55, 0.4
	foot((W + 0.08, D + 0.06, 0.1), (0, -0.03, 0.05), tone=S("c"))
	body = B((W, D, H - 0.1), (0, 0, 0.1 + (H - 0.1) / 2), S("b"), bevel=0.02)
	B((W + 0.06, D + 0.04, 0.07), (0, -0.01, H + 0.03), S("a"), bevel=0.015)
	yf = -D / 2
	cw, ch, gap = 0.24, 0.24, 0.05
	cols = [-1.5 * (cw + gap), -0.5 * (cw + gap), 0.5 * (cw + gap), 1.5 * (cw + gap)]
	rows = [0.32, 0.32 + ch + gap + 0.05, 0.32 + 2 * (ch + gap + 0.05)]
	cuts = [prism([(x - cw / 2, z), (x + cw / 2, z), (x + cw / 2, z + ch), (x - cw / 2, z + ch)], yf - 0.03, yf + 0.3, GROOVE()) for z in rows for x in cols]
	cuts += runes(-0.5, 0.5, 0.18, yf, h=0.05, gap=0.07)
	carve(body, cuts)
	yc = yf + 0.15
	k = 0
	for zi, z in enumerate(rows):
		for xi, x in enumerate(cols):
			kind = (zi * 4 + xi) % 6
			k += 1
			B((0.1, 0.008, 0.035), (x, yf - 0.002, z - 0.04), BRASS("b"), bevel=0.002)  # label
			if kind in (0, 2, 3, 5) and not loot:  # the coin cubbies, looted: the brass bowl stays, the rest is gone
				if kind == 3:
					coin_bowl(x, yc, z, False)
				continue
			if kind == 0:
				stack(x - 0.05, yc, z - 0.002, 0.07)
				stack(x + 0.02, yc + 0.03, z - 0.002, 0.05)
				stack(x + 0.07, yc - 0.03, z - 0.002, 0.03, m=SILV("b"), mr=SILV("a"))
			elif kind == 1:
				for j in range(3):
					kit.cylinder(0.026, 0.27, (x - 0.06 + j * 0.055, yc + 0.0, z + 0.024 + 0.0), BRASS("abc"[j]), rot=(90, 0, 0), verts=12, bevel=0.003)
				kit.cylinder(0.026, 0.27, (x - 0.032, yc, z + 0.068), BRASS("a"), rot=(90, 0, 0), verts=12, bevel=0.003)
			elif kind == 2:  # a coin purse with a brass clasp
				sphere((x, yc, z + 0.047), 0.075, LEA("b"), scale=(1, 0.9, 0.82), seg=12, rings=8, cut=-0.06)
				kit.cylinder(0.04, 0.02, (x, yc, z + 0.12), LEA("b"), verts=10, bevel=0.003)
				kit.ring(0.04, 0.006, (x, yc, z + 0.125), BRASS("b"), seg=12)
				coin((x + 0.09, yc - 0.06, z + 0.006), GOLD(), tilt=(3, 2, 0))
			elif kind == 3:
				coin_bowl(x, yc, z, True)
			elif kind == 4:
				ledger(0.2, 0.16, 0.05, LEA("c"), at=(x, yc, z - 0.002), rot=(0, 0, 90))
				ledger(0.19, 0.15, 0.045, LEA("dark"), at=(x, yc, z + 0.047), rot=(0, 0, 96))
			else:  # emptied: just two coins left behind
				coin((x - 0.04, yc - 0.05, z + 0.006), GOLD(), tilt=(3, 0, 0))
				coin((x + 0.05, yc + 0.02, z + 0.006), SILV("a"), tilt=(0, 3, 0))
	flat_back(D / 2)


def bv_pigeonholes_empty():
	bv_pigeonholes(loot=False)


def coin_bowl(x, y, z, full):
	"""A low brass bowl standing on a cubby floor at z, heaped with coins when full."""
	lathe([(0.004, 0), (0.06, 0.002), (0.085, 0.045), (0.079, 0.047), (0.054, 0.009), (0.004, 0.008)], (x, y, z - 0.002), BRASS("b"), seg=16)
	kit.ring(0.083, 0.004, (x, y, z + 0.044), BRASS("a"), seg=16)
	if full:
		coin_pile(x, y, z + 0.01, 0.05, 0.05, 14, 0.035)


def vault_disc(r=0.58, t=0.14):
	"""The round vault door at the origin, facing -Y (y from -t/2 to t/2)."""
	yf = -t / 2
	kit.cylinder(r, t, (0, 0, 0), IRON("dark"), rot=(90, 0, 0), verts=36, bevel=0.012)
	kit.ring(r - 0.012, 0.03, (0, yf + 0.012, 0), BRASS("b"), rot=(90, 0, 0), seg=40)
	kit.ring(r * 0.55, 0.018, (0, yf, 0), BRASS("a"), rot=(90, 0, 0), seg=32)
	for k in range(8):
		a = 2 * math.pi * k / 8 + math.pi / 8
		mid = (0.17 + r * 0.92) / 2
		L = r * 0.92 - 0.17
		B((0.06, 0.024, L), (math.sin(a) * mid, yf - 0.002, math.cos(a) * mid), BRASS("b" if k % 2 else "c"), bevel=0.005, rot=(0, math.degrees(a), 0))
		for d in (0.24, r * 0.55 + 0.05, r * 0.8):
			kit.rivet((math.sin(a) * d, yf - 0.016, math.cos(a) * d), BRASS("dark"), r=0.011)
	for k in range(16):
		if k == 8:
			continue
		a = 2 * math.pi * k / 16
		kit.rivet((math.sin(a) * r * 0.72, yf - 0.006, math.cos(a) * r * 0.72), IRON("a"), r=0.014)
	kit.cylinder(0.13, 0.04, (0, yf - 0.012, 0), BRASS("b"), rot=(90, 0, 0), verts=16, bevel=0.006)
	kit.cylinder(0.035, 0.1, (0, yf - 0.07, 0), BRASS("dark"), rot=(90, 0, 0), verts=10, bevel=0.004)
	yw = yf - 0.11
	kit.ring(0.22, 0.016, (0, yw, 0), BRASS("b"), rot=(90, 0, 0), seg=28)
	kit.cylinder(0.05, 0.03, (0, yw, 0), BRASS("a"), rot=(90, 0, 0), verts=12, bevel=0.004)
	for k in range(6):
		a = 2 * math.pi * k / 6
		rod((math.sin(a) * 0.04, yw, math.cos(a) * 0.04), (math.sin(a) * 0.215, yw, math.cos(a) * 0.215), 0.01, BRASS("a"))
		kit.cylinder(0.014, 0.06, (math.sin(a) * 0.22, yw - 0.035, math.cos(a) * 0.22), BRASS("dark"), rot=(90, 0, 0), verts=8, bevel=0.003)
	kz = -r * 0.76  # keyhole plate below the hub, clear of the inner brass ring
	p = B((0.1, 0.02, 0.12), (0, yf - 0.006, kz), BRASS("b"), bevel=0.006)
	carve(p, [cy(circ(0, kz + 0.015, 0.014, n=10, wob=0), yf - 0.016, 0.012), cy([(-0.007, kz + 0.01), (0.007, kz + 0.01), (0.01, kz - 0.03), (-0.01, kz - 0.03)], yf - 0.016, 0.012)])


def vault_wall(forced=False):
	"""forced (owner round 2: "it has to be walkable"): a bigger round doorway cut right through the wall and its
	foot, flat at the floor, a low flat threshold stone, the door swung wide to the left, the tools off to the right."""
	W, H, d = (2.1, 1.85, 0.2) if forced else (1.9, 1.85, 0.2)
	r, cz = (0.76, 0.66) if forced else (0.58, 0.82)
	before = objs()
	slab, yf = wall_slab(W, H, d)
	foot_ = [o for o in objs() if o not in before][0]
	cuts = runes(-0.75, 0.75, 1.75, yf, h=0.05, gap=0.07)
	if forced:  # the doorway, through the slab and its foot stone
		def cut(rr):  # the round doorway, flat at the floor
			xf_ = math.sqrt(rr ** 2 - cz ** 2)
			a0 = -math.asin(cz / rr)  # where the circle meets the floor, bottom right; then round over the top to bottom left
			pts = [(xf_, -0.05)] + [(math.cos(a) * rr, cz + math.sin(a) * rr) for a in
				[a0 + (math.pi - 2 * a0) * (k + 1) / 41 for k in range(40)]] + [(-xf_, -0.05)]
			return prism(pts, yf - 0.2, d / 2 + 0.1, GROOVE()), xf_
		c_, xf = cut(r - 0.01)
		cuts.append(c_)
		carve(foot_, [cut(r + 0.005)[0]])  # the foot's cut a little wider: two cut walls in one place would shimmer
	carve(slab, cuts)
	n = 18  # the voussoir ring and the threshold
	for k in range(n):
		a = 2 * math.pi * (k + 0.5) / n
		if (cz + math.cos(a) * (r + 0.11) < 0.12) if forced else abs(math.cos(a) + 1) < 0.25:
			continue
		R = r + 0.11
		v = B((2 * math.pi * R / n - 0.015, 0.08, 0.17), (math.sin(a) * R, yf - 0.03, cz + math.cos(a) * R), S("a" if k % 2 else "c"), bevel=0.012, rot=(0, math.degrees(a), 0))
		if forced and k in (3, 4, 5):  # the bolt holes, on the right of the ring
			carve(v, [prism(circ(yf - 0.03, cz + zz, 0.026, n=8, wob=0), r - 0.02, r + 0.12, GROOVE(), axis="x") for zz in (-0.18, 0.0, 0.18)])
	keys = B((0.18, 0.1, 0.24), (0, yf - 0.04, cz + r + 0.1), S("b"), bevel=0.015)  # keystone
	carve(keys, key_emblem(0, cz + r + 0.1, 0.16, 0, yf - 0.09, w=0.01, depth=0.01))
	if forced:  # a low flat threshold stone right through the doorway (3 cm: a dwarf walks over it)
		B((2 * xf + 0.06, d + 0.45, 0.03), (0, yf - 0.2 + (d + 0.45) / 2, 0.015), S("a"), bevel=0.008)
	else:
		B((1.0, 0.24, 0.08), (0, yf - 0.1, 0.13), S("a"), bevel=0.012)  # threshold step
	hx = -r - 0.03
	dy = yf - 0.07 if forced else yf - 0.03  # the door's centre depth
	for zz in (cz - 0.3, cz + 0.3):  # hinge blocks and barrels on the left
		B((0.1, 0.09, 0.1), (hx - 0.02, yf - 0.035, zz), IRON("dark"), bevel=0.006)
		kit.cylinder(0.035, 0.14, (hx, dy if forced else yf - 0.07, zz), BRASS("b"), verts=12, bevel=0.004)
		sphere((hx, dy if forced else yf - 0.07, zz + 0.075), 0.03, BRASS("a"), seg=10, rings=6)
		if forced:
			B((0.06, 0.08, 0.06), (hx, (yf - 0.03 + dy) / 2, zz), IRON("dark"), bevel=0.004)
	door = group(lambda: vault_disc(r), at=(0, dy, cz))
	for zz in (cz - 0.3, cz + 0.3):  # hinge straps from the barrels onto the door
		door.append(B((0.24, 0.05, 0.06), (hx + 0.12, dy - 0.05, zz), BRASS("dark"), bevel=0.004))
	if forced:
		for j, zz in enumerate((-0.18, 0.0, 0.18)):  # locking bolts out of the door's right edge: two straight, one bent
			if j == 1:
				door.append(tube([(r - 0.03, dy, cz + zz), (r + 0.06, dy, cz + zz), (r + 0.12, dy - 0.03, cz + zz - 0.05)], 0.022, 0.02, BRASS("b"), seg=8))
			else:
				door.append(kit.cylinder(0.022, 0.14, (r + 0.03, dy, cz + zz), BRASS("b"), rot=(0, 90, 0), verts=10, bevel=0.003))
		bpy.context.view_layer.update()
		for i, o in enumerate(door):  # the door is cut flat at the floor like its doorway (each part 3 mm apart: no shimmer)
			mw = o.matrix_world.copy()
			inv = mw.inverted()
			for v in o.data.vertices:
				w = mw @ v.co
				if w.z < 0.04 + 0.003 * i:
					w.z = 0.04 + 0.003 * i
					v.co = inv @ w
		turn(door, "Z", -95, (hx, dy, 0))  # swung wide open against the left, out of the way
		rough_chips([(0.78, yf - 0.25, 0.03), (0.62, yf - 0.4, 0.025), (0.88, yf - 0.35, 0.02), (0.7, yf - 0.55, 0.03)])

		def sledge():
			log((0, 0, 0), (0, 0, 0.75), 0.02, WOOD(), seg=6, rings=2, ends=False, bend=0.006)
			B((0.09, 0.09, 0.2), (0, 0, 0.78), IRON("dark"), bevel=0.014, rot=(0, 90, 0))
		drop(group(sledge, at=(0.64, yf - 0.15, 0.1), rot=(90, 0, 15)))
		pry_bar((0.6, yf - 0.18, 0.025), (0.98, yf - 0.1, 0.013))
	flat_back(d / 2)


def bv_vault_door():
	vault_wall(False)


def bv_vault_door_forced():
	vault_wall(True)


def bv_lock_works():
	W, H = 1.1, 1.55
	slab, yf = wall_slab(W, H, 0.16)
	carve(slab, runes(-0.4, 0.4, 0.3, yf, h=0.05, gap=0.06) + runes(-0.4, 0.4, 0.2, yf, h=0.05, gap=0.06, under=False))
	cz = 0.92
	B((0.82, 0.02, 0.62), (0, yf - 0.008, cz), BRASS("dark"), bevel=0.006)  # back plate of the opened case
	yp = yf - 0.03
	walls = []
	for s_ in (-1, 1):
		B((0.82, 0.07, 0.03), (0, yf - 0.045, cz + s_ * 0.3), BRASS("b"), bevel=0.005)
		walls.append(B((0.03, 0.07, 0.6), (s_ * 0.4, yf - 0.045, cz), BRASS("b"), bevel=0.005))
		for t in (-1, 1):
			kit.cylinder(0.022, 0.02, (s_ * 0.4, yf - 0.088, cz + t * 0.3), IRON("dark"), rot=(90, 0, 0), verts=6, bevel=0.002)
	carve(walls[1], [cy([(0.3, zz - 0.04), (0.5, zz - 0.04), (0.5, zz + 0.04), (0.3, zz + 0.04)], yf - 0.1, 0.12) for zz in (cz + 0.18, cz, cz - 0.18)])
	for zz in (cz + 0.18, cz, cz - 0.18):  # three heavy bolts sliding out through the right wall, in guides
		B((0.5, 0.035, 0.07), (0.25, yp, zz), IRON("a"), bevel=0.008)
		sphere((0.5, yp, zz), 0.036, IRON("a"), scale=(0.6, 0.5, 1), seg=10, rings=6)
		B((0.04, 0.045, 0.09), (0.05, yp - 0.005, zz), BRASS("a"), bevel=0.004)
		B((0.04, 0.045, 0.09), (0.3, yp - 0.005, zz), BRASS("a"), bevel=0.004)
		B((0.06, 0.036, 0.022), (0.15, yp, zz + 0.045), IRON("dark"), bevel=0.003)  # notch stud
	B((0.04, 0.04, 0.48), (0.0, yp - 0.03, cz), IRON("dark"), bevel=0.006)  # the bar tying the bolts to the lever
	for zz in (cz + 0.18, cz, cz - 0.18):
		kit.rivet((0.0, yp - 0.052, zz), BRASS("dark"), r=0.012)
	for j in range(4):  # lever tumblers stacked on a pivot
		prism([(-0.32, cz - 0.04), (-0.06, cz - 0.02), (-0.06, cz + 0.04), (-0.18, cz + 0.06), (-0.32, cz + 0.03)],
			yp - 0.006 * j - 0.012, yp - 0.006 * j - 0.008, BRASS("abc"[j % 3]))
	kit.cylinder(0.02, 0.07, (-0.3, yp - 0.015, cz), IRON("dark"), rot=(90, 0, 0), verts=8, bevel=0.003)
	tube([(-0.36, yp - 0.02, cz - 0.25), (-0.3, yp - 0.02, cz - 0.1), (-0.22, yp - 0.025, cz + 0.06)], 0.008, 0.006, IRON("a"), seg=6)  # spring
	kit.cylinder(0.02, 0.06, (-0.36, yp, cz - 0.25), IRON("dark"), rot=(90, 0, 0), verts=8, bevel=0.003)
	# the great key in its hole
	kit.cylinder(0.05, 0.03, (-0.15, yp, cz - 0.17), BRASS("b"), rot=(90, 0, 0), verts=14, bevel=0.004)
	rod((-0.15, yp - 0.01, cz - 0.17), (-0.15, yp - 0.12, cz - 0.17), 0.012, BRASS("b"))
	kit.ring(0.05, 0.012, (-0.15, yp - 0.17, cz - 0.17), BRASS("b"), rot=(0, 90, 0), seg=16)
	frame_band(W - 0.04, 0.8, yf, z0=cz - 0.4)
	flat_back(0.08)


def bv_guild_medallion():
	W, H = 1.2, 1.7
	slab, yf = wall_slab(W, H, 0.16)
	cz, R = 1.08, 0.42
	med = kit.cylinder(R, 0.08, (0, yf - 0.03, cz), S("a"), rot=(90, 0, 0), verts=40, bevel=0.012)
	yfm = yf - 0.07
	cuts = scales_emblem(0, cz - 0.03, 0.2, yfm, w=0.02, depth=0.016)
	for k in range(14):  # a ring of runes round the scales
		a = 2 * math.pi * k / 14
		x, z = math.sin(a) * R * 0.8, cz + math.cos(a) * R * 0.8
		ux, uz = math.sin(a), math.cos(a)  # outward
		tx, tz = uz, -ux  # along the ring
		g = GLYPH_PICK[k % len(GLYPH_PICK)]
		cuts += gline([(x - ux * 0.03, z - uz * 0.03), (x + ux * 0.03, z + uz * 0.03)], 0.01, yfm, 0.008)
		cuts += gline([(x + ux * g[0] * 0.03, z + uz * g[0] * 0.03), (x + ux * g[1] * 0.03 + tx * 0.022, z + uz * g[1] * 0.03 + tz * 0.022)], 0.009, yfm, 0.008)
	cuts += gline([(math.sin(a) * R * 0.65, cz + math.cos(a) * R * 0.65) for a in [2 * math.pi * j / 40 for j in range(41)]], 0.01, yfm, 0.008)
	carve(med, cuts)
	kit.ring(R - 0.005, 0.03, (0, yf - 0.035, cz), BRASS("b"), rot=(90, 0, 0), seg=48)
	for k in range(12):
		a = 2 * math.pi * k / 12
		kit.rivet((math.sin(a) * (R - 0.005), yf - 0.066, cz + math.cos(a) * (R - 0.005)), BRASS("dark"), r=0.012)
	carve(slab, key_emblem(-0.08, 0.36, 0.4, 35, yf, w=0.018, depth=0.014) + key_emblem(0.08, 0.36, 0.4, -35, yf, w=0.018, depth=0.014))
	flat_back(0.08)


GLYPH_PICK = ((1, 0.2), (0.2, -1), (-1, 0.4), (0.6, 1), (-0.3, 0.9))


def bv_wall_lantern():
	foot((0.56, 0.3, 0.08), (0, -0.06, 0.04), tone=S("c"))
	st = B((0.44, 0.12, 1.75), (0, 0.0, 0.08 + 0.875), S("b"), bevel=0.012)
	carve(st, key_emblem(0, 1.0, 0.24, 0, -0.06) + runes(-0.14, 0.14, 0.65, -0.06, h=0.05, gap=0.045) + runes(-0.14, 0.14, 0.53, -0.06, h=0.05, gap=0.045, under=False))
	B((0.5, 0.16, 0.06), (0, -0.01, 1.85), S("a"), bevel=0.012)
	kit.taper(0.16, 0.08, 0.22, 0.3, 0.14, (0, -0.08, 1.46), S("a"), bevel=0.012)  # corbel
	B((0.04, 0.16, 0.035), (0, -0.25, 1.62), BRASS("b"), bevel=0.004)  # brass arm out of the corbel top
	B((0.06, 0.08, 0.06), (0, -0.18, 1.62), BRASS("dark"), bevel=0.006)
	sphere((0, -0.335, 1.62), 0.018, BRASS("a"), seg=8, rings=5)
	kit.ring(0.02, 0.005, (0, -0.32, 1.59), BRASS("dark"), rot=(0, 90, 0), seg=10)
	chain((0, -0.32, 1.57), (0, -0.32, 1.38), link=0.02, wire=0.0055, m=BRASS("dark"))
	lantern((0, -0.32, 1.115), 0.26)
	flat_back(0.06)


def bv_halberd_rack():
	W = 1.05
	foot((W + 0.12, 0.36, 0.1), (0, -0.08, 0.05), tone=S("c"))
	back = B((W, 0.14, 1.95), (0, 0.03, 0.095 + 0.975), S("b"), bevel=0.015)
	carve(back, runes(-0.4, 0.4, 1.9, -0.04, h=0.05, gap=0.06) + scales_emblem(0, 0.7, 0.1, -0.04, w=0.014, depth=0.012))
	B((W + 0.06, 0.18, 0.07), (0, 0.02, 2.08), S("a"), bevel=0.015)
	rail = B((W - 0.04, 0.14, 0.08), (0, -0.1, 1.35), S("a"), bevel=0.012)
	carve(rail, [prism(circ(x, -0.14, 0.03, n=10, wob=0), 1.3, 1.4, GROOVE(), axis="z") for x in (-0.3, 0.0, 0.3)])
	for x in (-0.3, 0.0, 0.3):
		kit.ring(0.03, 0.006, (x, -0.14, 1.392), BRASS("b"), seg=12)
	B((W - 0.04, 0.24, 0.08), (0, -0.13, 0.13), S("a"), bevel=0.012)
	for k, x in enumerate((-0.3, 0.0, 0.3)):
		kit.cylinder(0.042, 0.05, (x, -0.14, 0.19), BRASS("b"), verts=12, bevel=0.004)
		kit.ring(0.042, 0.005, (x, -0.14, 0.21), BRASS("dark"), seg=12)
		if k == 1:  # this slot's halberd is gone: only its brass tag hangs under the rail
			tag(x, -0.12, 1.3)
			continue
		group(lambda: halberd(1.8), at=(x, -0.14, 0.17), rot=(0, 0, 0 if k == 2 else 180))
	flat_back(0.1)


def bv_lockbox_shelf():
	W, H, D = 1.2, 1.6, 0.36
	foot((W + 0.06, D + 0.04, 0.08), (0, 0, 0.04), tone=S("c"))
	B((W, 0.08, H), (0, D / 2 - 0.04, 0.075 + H / 2), S("b"), bevel=0.012)
	for s_ in (-1, 1):
		B((0.09, D, H), (s_ * (W / 2 - 0.045), 0, 0.075 + H / 2), S("a"), bevel=0.012)
	B((W + 0.06, D + 0.04, 0.07), (0, -0.01, 0.075 + H + 0.03), S("a"), bevel=0.012)
	zs = (0.1, 0.62, 1.12)
	for k, z in enumerate(zs):
		sh = B((W - 0.17, D - 0.075, 0.06), (0, -0.035, z + 0.03), S("c" if k % 2 else "a"), bevel=0.01)
		carve(sh, runes(-0.48, 0.48, z + 0.03, -D / 2 + 0.003, h=0.032, w=0.007, gap=0.12, depth=0.006, under=False))
	yb = D / 2 - 0.08
	for k, z in enumerate(zs):
		z0 = z + 0.057
		for j in range(4):
			x = -0.39 + j * 0.26
			idx = k * 4 + j
			if idx == 6:  # a gap: one box is gone, its tag left lying on the shelf
				kit.cylinder(0.018, 0.004, (x, -0.1, z0 + 0.004), BRASS("a"), verts=10, bevel=0.001)
				continue
			bw, bd, bh = 0.2, 0.22, 0.14 + 0.03 * (idx % 2)
			yc = yb - bd / 2 - 0.01
			B((bw, bd, bh), (x, yc, z0 + bh / 2), IRON("dark" if idx % 3 else "b"), bevel=0.008)
			for xx in (-0.06, 0.06):
				B((0.022, bd + 0.008, 0.012), (x + xx, yc, z0 + bh - 0.025), BRASS("dark"), bevel=0.002)
			B((0.06, 0.008, 0.035), (x, yc - bd / 2 - 0.002, z0 + bh * 0.62), BRASS("b"), bevel=0.002)  # tag
			if idx == 9:  # pried open: the lid stands up on its hinge, the hasp bent
				def lid(bw=bw, bd=bd):
					B((bw + 0.006, bd + 0.006, 0.02), (0, -bd / 2, 0.0), IRON("a"), bevel=0.005)
				group(lid, at=(x, yc + bd / 2, z0 + bh + 0.008), rot=(-86, 0, 0))
				tube([(x, yc - bd / 2 - 0.004, z0 + bh - 0.02), (x + 0.01, yc - bd / 2 - 0.03, z0 + bh - 0.03), (x + 0.03, yc - bd / 2 - 0.04, z0 + bh - 0.06)], 0.006, 0.005, BRASS("a"), seg=6)
				continue
			B((bw + 0.006, bd + 0.006, 0.02), (x, yc, z0 + bh + 0.006), IRON("a"), bevel=0.005)
			B((0.024, 0.01, 0.03), (x, yc - bd / 2 - 0.004, z0 + bh - 0.012), BRASS("a"), bevel=0.002)  # hasp
	flat_back(D / 2)
MODELS = {k: v for k, v in globals().items() if k.startswith("bv_") and callable(v)}
LIDS = {"bv_strongbox": 0.447}  # chests whose lid is its own part (kit.save lid=): just above the box rim at z 0.442

if __name__ == "__main__":
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	outdir = GAME / "assets" / "models" / "decor"
	jdir = GAME / "journey" / "3d" / "v2_hand_built" / "decor"
	outdir.mkdir(parents=True, exist_ok=True)
	jdir.mkdir(parents=True, exist_ok=True)
	for name in args or list(MODELS):
		rng.seed(sum(map(ord, name.removesuffix("_empty"))))  # an _empty twin matches its full model
		kit.reset()
		_cm.clear()
		try:
			MODELS[name]()
			for o in bpy.data.objects:  # parts in plain colours have no UVs; joining into one of them drops every texture
				if o.type == "MESH" and not o.data.uv_layers:
					o.data.uv_layers.new()
			kit.save(str(outdir / f"{name}.glb"), str(jdir / f"{name}.png"), tex_size=256, lid=LIDS.get(name))
			print(f"MODEL_OK {name}")
		except Exception as e:
			import traceback
			traceback.print_exc()
			print(f"MODEL_FAILED {name}: {e!r}")
