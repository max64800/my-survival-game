# Lampwick Drift's mine set (dungeon 2, owner Nov 20, 2026: "new assets by type of dungeon"). Built from the same
# Delver's Shack parts as dungeon_rootwood.py (hewn logs, split boards, pegs, chisel-cut stones, its paintings), so
# the mine matches Mossgate Hold. Concept: docs/art/dungeon-model-sheets/rail_triple.jpg (look only).
#
#   blender --background --factory-startup --python builds/dungeon_mine.py -- <out_dir> [only=rail_lane,...] [grey=1]
#
# Axes like the Shack script: x across, y up, z = front. Origin bottom-centre, on the floor line (y = 0).
# Owner, Nov 20: ONE LANE PER 2 m SQUARE (the sheet's 3 lanes in one square were 66 cm each, but the dwarf is 72 cm
# wide). The Cart Junction (6 m) is three lanes; you stand in the middle of the empty one.
# Batch 1, the triple cart trap (carts roll toward +z, downhill; the game tilts the lanes 14 degrees, 0.5 m per 2 m):
#   rail_lane      one lane, 2 x 2 m, tiles along z: a stone bed (top 0.22, level with the floor boards), 5 sleepers,
#                  2 rails 0.8 m apart. Parts: "rails" (all of it) and "glint" (a bright worn strip on top of each
#                  rail: the clue, the game makes the next lane's glint shine)
#   rail_release   the frame at a lane's high end, 2 x 1 m, 1.6 m tall: posts on stone footings, a top beam, braces.
#                  Parts: "frame", "chock" (the block holding the cart, flips up 80 degrees round its back edge to let
#                  it go) and "lever" (on the beam, swings 40 degrees forward with the chock: looks only)
#   rail_buffer    the stop at a lane's low end, 2 x 1 m: two posts braced from behind, a rope-wrapped bumper log.
#                  Parts: "frame" and "bumper" (pushed back 10 cm when a cart hits it)
#   trap_cart      a heavy mine cart full of rock, 1.1 m wide, 1.5 m long, on 4 iron wheels 0.8 m apart (on the
#                  rails); origin = the wheels' bottom (place it on the rail top, y 0.36 of a lane).
#                  Parts: "body" and wheel0..wheel3 (they spin)
import math
import sys
from pathlib import Path

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kit  # noqa: E402
import kit_zone1 as K  # noqa: E402
import shack_v2 as S  # noqa: E402
import dungeon_rootwood as R  # noqa: E402  (meshes, chisel_slab, rope, save_parts, pictures; same OUT/ONLY/GREY)

J, T = K.J, K.T
meshes = R.meshes

BED_TOP = 0.22     # the lane's stone bed (the floor boards' top is 0.24: the ballast stones stick up past it)
SLEEPER = (0.19, 0.29)
RAIL = (0.275, 0.36)  # (1.5 cm down into the sleepers: they touch)
GAUGE = 0.4        # rails at x = +-0.4 (the cart's wheels sit on them)
RAIL_TOP = RAIL[1]


def board(c, s, m=None):
	"""A thick hand-cut board as a box with a little wobble (painted as one plank by paint3)."""
	o = kit.box(K.GS(s), K.G(c), m or T("wood"), bevel=0.012, wobble=0.006)
	o["role"] = "board"
	return o


def iron(c, s, bevel=0.004):
	return K.blk(c, s, T("iron", "dark"), bevel=bevel)


def nail(x, y, z):
	kit.cylinder(0.016, 0.022, K.G((x, y, z)), T("iron", "dark"), rot=(0, 0, 0), verts=8, bevel=0.003)


# ---------------------------------------------------------------- rail lane
def rail_lane():
	frame0 = meshes()
	R.chisel_slab(0.0, 0.0, 1.99, 1.99, 0.0, BED_TOP, ch=0.02)  # the bed (0.5 cm in from the square's edges)
	for k in range(5):  # sleepers 0.4 m apart, 0.2 m from each end: lanes end to end keep the same spacing
		z = -0.8 + k * 0.4 + J(0.015)
		S.board_x(-0.62 + J(0.02), 0.62 + J(0.02), z - 0.1, z + 0.1, SLEEPER[0], SLEEPER[1], chips=2)
		for x in (-GAUGE, GAUGE):
			for dx in (-0.06, 0.06):
				nail(x + dx, SLEEPER[1] + 0.008, z + J(0.02))
	# ballast: small stones packed between the sleepers and along the sides, sitting on the bed
	for k in range(5):
		zc = -0.6 + k * 0.4
		for _ in range(4):
			x = K.rng.uniform(-0.6, 0.6)
			if abs(abs(x) - GAUGE) < 0.06:
				continue
			r = K.rng.uniform(0.045, 0.07)
			S.boulder((x, BED_TOP + r * 0.4, zc + J(0.08)), r, r * 0.7, r, floor=BED_TOP - 0.01)
	for x in (-0.82, 0.82):
		for k in range(4):
			r = K.rng.uniform(0.05, 0.08)
			S.boulder((x + J(0.06), BED_TOP + r * 0.4, -0.75 + k * 0.5 + J(0.1)), r, r * 0.7, r, floor=BED_TOP - 0.01)
	for x in (-GAUGE, GAUGE):  # the rails (0.5 cm short of each end, so two lanes end to end don't share a face)
		iron((x, (RAIL[0] + RAIL[1]) / 2, 0.0), (0.06, RAIL[1] - RAIL[0], 1.99))
	rails = meshes() - frame0
	before = meshes()
	for x in (-GAUGE, GAUGE):  # the worn glint: a narrower strip sunk into each rail's top (not on its face)
		K.blk((x, RAIL_TOP - 0.004, 0.0), (0.034, 0.012, 1.97), T("iron", "a"), bevel=0.002)
	glint = meshes() - before
	return {"rails": rails, "glint": glint}


# ---------------------------------------------------------------- release frame (top of a lane)
def rail_release():
	frame0 = meshes()
	beam_y = 1.52
	for sx in (-1, 1):
		x = sx * 0.86
		R.chisel_slab(x, 0.0, 0.26, 0.3, BED_TOP - 0.02, BED_TOP + 0.12)
		S.hewn((x, BED_TOP + 0.1, 0.0), (x + J(0.006), beam_y - 0.05, J(0.006)), 0.085)
		S.hewn((x, beam_y - 0.42, 0.0), (x - sx * 0.36, beam_y - 0.06, 0.0), 0.045)  # brace under the beam
		iron((x, beam_y - 0.12, 0.0), (0.19, 0.06, 0.2))  # iron strap where the post meets the beam
	S.hewn((-0.99, beam_y, 0.0), (0.99, beam_y + J(0.006), 0.0), 0.1)
	for x in (-0.86, 0.86):
		S.peg(x, beam_y, 0.1, "z")
	# the lever's bracket on the beam's front
	for sx in (-1, 1):
		K.blk((sx * 0.06, beam_y + 0.02, 0.11), (0.04, 0.14, 0.07), T("wood", "dark"), bevel=0.01)  # (into the beam)
	kit.cylinder(0.014, 0.18, K.G((0.0, beam_y + 0.04, 0.12)), T("iron", "dark"), rot=(0, 90, 0), verts=10, bevel=0.002)
	frame = meshes() - frame0
	before = meshes()
	a = math.radians(15)
	tip = (0.0, beam_y + 0.04 + 0.42 * math.cos(a), 0.12 - 0.42 * math.sin(a))
	S.hewn((0.0, beam_y - 0.02, 0.125), tip, 0.026)
	S.boulder(tip, 0.05, 0.05, 0.05, m=T("wood"))  # the knob
	lever = meshes() - before
	before = meshes()
	# the chock: a hewn block across both rails, just downhill of the parked cart's front wheels, iron-shod
	board((0.0, RAIL_TOP + 0.02 + 0.075, 0.42), (0.96, 0.15, 0.17))  # a squared block (it read as a log)
	# it hangs from the beam on two iron rods (like the picture), so it swings up round the beam to let the cart go
	for x in (-0.3, 0.3):
		iron((x, (RAIL_TOP + 0.16 + beam_y) / 2, 0.42 - 0.07), (0.035, beam_y - RAIL_TOP - 0.16 + 0.03, 0.035))
		iron((x, beam_y - 0.02, 0.2), (0.04, 0.035, 0.34))  # the rod's arm back to its hook in the beam
	for x in (-GAUGE, GAUGE):
		iron((x, RAIL_TOP + 0.011, 0.42), (0.1, 0.02, 0.15))  # shoes where it rests on the rails
		iron((x, RAIL_TOP + 0.095, 0.42 + 0.088), (0.08, 0.13, 0.012))  # iron plate on its front, where carts push
	chock = meshes() - before
	return {"frame": frame, "lever": lever, "chock": chock}


# ---------------------------------------------------------------- buffer (bottom of a lane)
def rail_buffer():
	frame0 = meshes()
	for sx in (-1, 1):
		x = sx * 0.5
		R.chisel_slab(x, 0.18, 0.28, 0.56, BED_TOP - 0.02, BED_TOP + 0.1)  # (long enough for the strut's foot)
		S.hewn((x, BED_TOP + 0.08, 0.0), (x + J(0.006), 0.9, J(0.006)), 0.08)
		S.hewn((x, 0.78, 0.04), (x, BED_TOP + 0.1 + 0.04, 0.38), 0.055)  # strut leaning back (downhill side)
		S.peg(x, 0.78, -0.08, "z")
	S.hewn((-0.62, 0.84, 0.0), (0.62, 0.84 + J(0.006), 0.0), 0.06)  # tie beam across the post tops
	frame = meshes() - frame0
	before = meshes()
	by, bz = 0.58, -0.17
	S.hewn((-0.66, by, bz), (0.66, by + J(0.006), bz), 0.095)  # the bumper log in front of the posts
	for x in (-0.5, 0.0, 0.5):  # rope wrapped round it (thick coils, like the picture)
		for k in range(4):
			kit.ring(0.1, 0.018, K.G((x - 0.054 + k * 0.036, by, bz)), kit.tex_mat("rope"), rot=(0, 90, 0), seg=18)
	bumper = meshes() - before
	return {"frame": frame, "bumper": bumper}


# ---------------------------------------------------------------- the cart
def trap_cart():
	body0 = meshes()
	fy0, fy1 = 0.33, 0.39       # floor boards
	hx, hz, top = 0.55, 0.75, 0.95
	xs = [-0.5, -0.3, -0.1, 0.1, 0.3, 0.5]
	for i in range(5):
		S.rough_board(xs[i] + 0.006, xs[i + 1] - 0.006, -hz + 0.07, hz - 0.07, fy0, fy1, chips=1)
	for k in range(3):  # side boards along z (outer face at x = +-0.55), front and back boards between them
		y0 = fy0 + k * 0.2 + 0.02  # (1.5 cm+ from the floor board's underside: no shimmer)
		y1 = y0 + 0.19
		for sx in (-1, 1):
			board((sx * (hx - 0.03), (y0 + y1) / 2, 0.0), (0.06, y1 - y0, 2 * hz))
		for sz in (-1, 1):
			board((0.0, (y0 + y1) / 2, sz * (hz - 0.03 - 0.06)), (2 * hx - 0.1, y1 - y0, 0.06))  # 1 cm into the sides
	top = fy0 + 3 * 0.2
	for y in (fy0 + 0.12, top - 0.08):  # iron bands round the box, sunk 0.5 cm into the boards
		for sx in (-1, 1):
			iron((sx * (hx + 0.005), y, 0.0), (0.02, 0.07, 2 * hz + 0.03))
		for sz in (-1, 1):
			iron((0.0, y - 0.01, sz * (hz - 0.06 + 0.005)), (2 * hx + 0.03, 0.07, 0.02))  # (1 cm lower: no shared face)
	for sx in (-1, 1):
		for sz in (-1, 1):
			iron((sx * (hx + 0.005), (fy0 + top) / 2, sz * (hz - 0.02)), (0.04, top - fy0, 0.06))  # corner straps
	for sz in (-1, 1):  # bumper logs front and back
		S.hewn((-0.5, fy0 + 0.1, sz * (hz + 0.05)), (0.5, fy0 + 0.1 + J(0.004), sz * (hz + 0.05)), 0.055)
	# bearings and axles under the floor
	for z in (-0.45, 0.45):
		for x in (-0.32, 0.32):
			K.blk((x, 0.26, z), (0.09, 0.15, 0.16), T("wood", "dark"), bevel=0.01)
		kit.cylinder(0.028, 0.96, K.G((0.0, 0.15, z)), T("iron", "dark"), rot=(0, 90, 0), verts=10, bevel=0.003)
	# the load: rock packed in, heaped above the rim
	for gx in range(3):
		for gz in range(4):
			c = (-0.33 + gx * 0.33 + J(0.03), fy1 + 0.2 + J(0.03), -0.5 + gz * 0.33 + J(0.03))
			S.boulder(c, 0.21 + J(0.02), 0.22 + J(0.02), 0.2 + J(0.02), floor=fy1 + 0.005)
	for gx in range(2):
		for gz in range(3):
			c = (-0.17 + gx * 0.34 + J(0.04), top + 0.02 + J(0.03), -0.34 + gz * 0.34 + J(0.04))
			S.boulder((c[0], top - 0.07, c[2]), 0.19, 0.2 + J(0.02), 0.18, floor=fy1 + 0.2)  # (down into the pile)
	body = meshes() - body0
	groups = {"body": body}
	k = 0
	for z in (-0.45, 0.45):
		for x in (-GAUGE, GAUGE):
			before = meshes()
			kit.cylinder(0.15, 0.06, K.G((x, 0.15, z)), T("iron", "dark"), rot=(0, 90, 0), verts=16, bevel=0.008)
			kit.cylinder(0.168, 0.018, K.G((x - math.copysign(0.035, x), 0.15, z)), T("iron", "dark"), rot=(0, 90, 0), verts=16, bevel=0.004)  # flange (inside)
			for s in range(4):  # spokes as raised iron ribs on the outside
				a = s * math.pi / 4
				K.blk((x + math.copysign(0.033, x), 0.15, z), (0.012, 0.25, 0.03), T("iron", "a"), bevel=0.003, rx=math.degrees(a))
			groups[f"wheel{k}"] = meshes() - before
			k += 1
	return groups


BUILDS = {"rail_lane": rail_lane, "rail_release": rail_release, "rail_buffer": rail_buffer, "trap_cart": trap_cart}

if __name__ == "__main__":
	for name, fn in BUILDS.items():
		if R.ONLY and name not in R.ONLY:
			continue
		K.rng.seed(sum(map(ord, name)))
		kit.reset()
		groups = fn()
		if R.GREY:
			S.make_grey()
		else:
			S.paint3()
		parts = R.save_parts(name, groups)
		R.pictures(name, parts)
