# Lampwick Drift's mine set (dungeon 2, owner Nov 20, 2026: "new assets by type of dungeon"). Built from the same
# Delver's Shack parts as dungeon_rootwood.py (hewn logs, split boards, pegs, chisel-cut stones, its paintings), so
# the mine matches Mossgate Hold. Concept: docs/art/dungeon-model-sheets/rail_triple.jpg (look only).
#
#   blender --background --factory-startup --python builds/dungeon_mine.py -- <out_dir> [only=rail_lane,...] [grey=1]
#
# Axes like the Shack script: x across, y up, z = front. Origin bottom-centre, on the floor line (y = 0).
# Owner, Nov 20: ONE LANE PER 2 m SQUARE (the sheet's 3 lanes in one square were 66 cm each, but the dwarf is 72 cm
# wide). The Cart Junction (6 m) is three lanes; you stand in the middle of the empty one.
# Batch 1, the triple cart trap (carts roll toward +z, downhill; the game tilts the lanes 14 degrees, 0.5 m per 2 m).
# Owner, Nov 20 (1st look): rails 12 m long (6 lanes end to end), no glint, no frame or lever at the top: each cart is
# held by an old rotten wedge that snaps when someone steps into its lane; it crashes into the stopper and stays there.
#   rail_lane      one lane, 2 x 2 m, tiles along z: a stone bed (top 0.22, level with the floor boards), 5 sleepers,
#                  2 rails 0.8 m apart. One part: "rails"
#   rail_wedge     the rotten wedges holding a cart: one on each rail in front of the front wheels, a cracked board
#                  pegged across them. Origin = the rail top. Parts piece0..piece3 (each bursts off when it snaps)
#   rail_buffer    the stopper at a lane's low end, 2 x 1 m: two posts braced from behind, a rope-wrapped bumper log.
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
	return {"rails": meshes() - frame0}


# ---------------------------------------------------------------- the rotten wedges (top of a lane)
def side_prism(pts, x0, x1, m=None, role="board"):
	"""A block of any side outline (z, y points), from x0 to x1 (for wedges)."""
	n = len(pts)
	verts = [(x0 + J(0.004), y, z) for z, y in pts] + [(x1 + J(0.004), y, z) for z, y in pts]
	faces = [tuple(range(n)), tuple(range(n, 2 * n))] + [(i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n)]
	o = S._flat(K.mesh(verts, faces, m or T("wood")))
	o["role"] = role
	return o


def rail_wedge():
	"""A wedge on each rail (its slope against the cart's front wheel, which comes from -z), a cracked board across
	them on top, wooden pegs. Old and rotten (aged paint), split along a crack."""
	groups = {}
	for k, x in enumerate((-GAUGE, GAUGE)):
		before = meshes()
		h = 0.17 + J(0.01)
		side_prism([(-0.17, 0.0), (0.11, 0.0), (0.11 + J(0.01), h), (0.03, h + 0.005), (-0.06, h * 0.55)], x - 0.08, x + 0.08)
		S.peg(x, h + 0.006, 0.07, "y")
		groups[f"piece{k}"] = meshes() - before
	top = 0.17
	for k, (a, b) in enumerate(((-0.56, -0.03), (-0.01, 0.56))):  # the board, broken in two along a crack (2 cm apart)
		before = meshes()
		S.board_x(a + J(0.01), b + J(0.01), 0.0, 0.14, top - 0.006, top + 0.05, chips=2, broken="back" if k else "front")  # (jagged where they meet)
		groups[f"piece{k + 2}"] = meshes() - before
	return groups


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


BUILDS = {"rail_lane": rail_lane, "rail_wedge": rail_wedge, "rail_buffer": rail_buffer, "trap_cart": trap_cart}

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
			if name == "rail_wedge":
				R.age_paint()  # old and rotten
		parts = R.save_parts(name, groups)
		R.pictures(name, parts)
