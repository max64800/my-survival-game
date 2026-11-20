# Old Pell's Diggings' new pieces (dungeon 3, owner Nov 20, 2026: "build whatever you need for Dungeon 3"). Built from
# the same Delver's Shack parts as dungeon_rootwood.py / dungeon_mine.py (hewn logs, split boards, pegs, its paintings),
# so they match the root wood dungeon walls. Sheets (look only): docs/art/dungeon-model-sheets/trap_spear_wall.md,
# trap_push_wall.md, lift_platform.md.
#
#   blender --background --factory-startup --python builds/dungeon_pell.py -- <out_dir> [only=trap_spear_wall,...] [grey=1]
#
# Axes like the Shack script: x across, y up, z = front (+z faces the room). Origin bottom-centre, on the floor line.
#   trap_spear_wall  a 2 x 2 m root wood wall with two hewn beams (0.6 and 1.1 m up), five holes bored in
#                  each; a sharpened, fire-blackened stake waits in every hole (one tip shows: the clue).
#                  Parts: "frame", "spears" (all ten stakes: the game slides them out 0.8 m along z and back)
#   trap_push_wall   a 2 x 2 m root wood wall with a square hole (1.38 x 1.3 m, 0.23 m up) and a block of
#                  planks on a dark backing 2 m deep sitting in it, flush. Parts: "frame", "block" (slides out 1.8 m)
#   floor_scrape   pale scrape marks for the floor in front of the push wall (1.3 x 1.2 m, 6 mm thin; lies on the
#                  boards). One part
#   lift_platform  the rope lift's cage floor: 1.5 x 1.5 m deck on three bearers, a railing on three sides (open at
#                  +z), four corner ropes up to an iron ring 2.1 m up. Parts: "platform", "rope" (the hoist rope above
#                  the ring, 1 m long: the game stretches it up to the winch's drum)
#   lift_winch     the winch over the lift shaft: two posts standing beside the shaft (at x -1.15), two arms over it, a
#                  rope drum along z right over the middle (2.6 m up) with a crank. Parts: "frame", "drum" (turns)
import math
import sys
from pathlib import Path

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kit  # noqa: E402
import kit_zone1 as K  # noqa: E402
import shack_v2 as S  # noqa: E402
import dungeon_rootwood as R  # noqa: E402  (meshes, bore, wall_frame3, rope, save_parts, pictures; same OUT/ONLY/GREY)

J, T = K.J, K.T
meshes = R.meshes

SPEAR_ROWS = (0.6, 1.1)
SPEAR_XS = (-0.6, -0.3, 0.0, 0.3, 0.6)
SPEAR_BEAM_R = 0.1
SPEAR_HOLE_R = 0.045
SPEAR_R = 0.027
PUSH_HOLE = (0.69, 0.23, 1.52)   # the block's half width, bottom and top
PUSH_DEPTH = 2.0  # (owner, Nov 20: it slams out 1.8 m, so its back stays in the wall)
LIFT_HALF = 0.75
LIFT_RING_Y = 2.1
WINCH_Y = 2.6


def boards_between(x0, x1, y0, y1, widths, gaps=(0.014, 0.022, 0.016)):
	"""Upright split boards filling x0..x1 between heights y0..y1 (like the dart wall's)."""
	ws = list(widths) + [(x1 - x0) - sum(widths)]
	x = x0
	for i, bw in enumerate(ws):
		a = x + (gaps[i - 1] / 2 if i else 0.0)
		b = x + bw - (gaps[i] / 2 if i < len(gaps) else 0.0)
		S.rough_vboard(a, b, y0, y1, J(0.008), 0.07)
		x += bw


# ---------------------------------------------------------------- spear wall
def trap_spear_wall():
	frame0 = meshes()
	px = R.wall_frame3()
	x0, x1 = -px + 0.13, px - 0.13
	beams = []
	for y in SPEAR_ROWS:
		before = meshes()
		S.hewn((-px, y, 0.0), (px, y + J(0.004), 0.0), SPEAR_BEAM_R)
		beams.append(bpy.data.objects[(meshes() - before).pop()])
	r = SPEAR_BEAM_R - 0.03
	boards_between(x0, x1, 0.17, SPEAR_ROWS[0] - r, [0.4, 0.34, 0.38])
	boards_between(x0, x1, SPEAR_ROWS[0] + r, SPEAR_ROWS[1] - r, [0.36, 0.4, 0.35])
	boards_between(x0, x1, SPEAR_ROWS[1] + r, S.TOP_BEAM - 0.08, [0.38, 0.33, 0.41])
	for y in (0.115, S.TOP_BEAM):
		for xx in (-0.55, 0.0, 0.5):
			S.pegs_on(xx + J(0.04), y, 0.112 if y > 1 else 0.093)
	for beam, y in zip(beams, SPEAR_ROWS):
		for x in SPEAR_XS:
			R.bore(beam, K.G((x, y, 0.0)), SPEAR_HOLE_R, 0.4)  # (right through: the stakes slide in it)
		S.pegs_on(-0.77, y, SPEAR_BEAM_R - 0.01)
		S.pegs_on(0.77, y, SPEAR_BEAM_R - 0.01)
		# a guide beam pegged on behind the holed beam: the stakes lie on it and slide along it (hidden in the rock)
		K.log((-0.7, y - SPEAR_HOLE_R - 0.045, -0.13), (0.7, y - SPEAR_HOLE_R - 0.045, -0.13), 0.055, None, seg=8, rings=2,
			ends=True, bend=0.0)
	frame = meshes() - frame0
	# The stakes: a split root shaft and an axe-cut, fire-blackened point; waiting with the point just inside the hole.
	before = meshes()
	tip_m = kit.mat("charcoal", -0.35, rough=0.7)
	for row, y in enumerate(SPEAR_ROWS):
		for k, x in enumerate(SPEAR_XS):
			show = 0.07 if (row, k) == (0, 3) else 0.0  # (one tip shows a little: the clue)
			front = 0.06 + show
			yy = y - (SPEAR_HOLE_R - SPEAR_R * 1.12)  # (each lies on the bottom of its hole: it touches, and slides along it)
			K.log((x, yy, front - 0.95), (x, yy, front - 0.17), SPEAR_R, T("wood"), seg=7, rings=2, ends=False, bend=0.0)
			kit.cone(SPEAR_R * 0.95, 0.003, 0.19, K.G((x, yy, front - 0.095)), tip_m, rot=(90, 0, 0), verts=6, bevel=0.002)
	return {"frame": frame, "spears": meshes() - before}


# ---------------------------------------------------------------- push wall
def trap_push_wall():
	hw, b0, b1 = PUSH_HOLE
	frame0 = meshes()
	px = R.wall_frame3()
	S.hewn((-px + 0.12, 1.6, 0.0), (px - 0.12, 1.6 + J(0.004), 0.0), 0.065)  # the lintel over the hole (between the posts)
	x0, x1 = -px + 0.13, px - 0.13
	boards_between(x0, x1, 1.64, S.TOP_BEAM - 0.1, [0.4, 0.36, 0.33])
	for xx in (-0.55, 0.0, 0.5):
		S.pegs_on(xx + J(0.04), S.TOP_BEAM, 0.118)
	# The dark gap round the block (the clue): dark iron runner strips along the hole's sides, set back.
	for s_ in (-1, 1):
		K.blk((s_ * (hw + 0.024), (b0 + b1) / 2, -0.35), (0.024, b1 - b0, 0.6), kit.mat("charcoal", -0.6), bevel=0.002)
	frame = meshes() - frame0
	# The block: planks on a dark backing, two battens across, pegs.
	before = meshes()
	K.blk((0.0, (b0 + b1) / 2, -PUSH_DEPTH / 2 - 0.01), (2 * hw - 0.04, b1 - b0 - 0.02, PUSH_DEPTH - 0.02),
		kit.mat("charcoal", -0.45), bevel=0.01)
	boards_between(-hw, hw, b0 + 0.005, b1 - 0.005, [0.33, 0.37, 0.36], gaps=(0.012, 0.016, 0.012))
	for y in (b0 + 0.28, b1 - 0.28):
		S.hewn((-hw + 0.05, y, 0.065), (hw - 0.05, y + J(0.004), 0.065), 0.035)
		for xx in (-0.45, 0.0, 0.45):
			S.pegs_on(xx + J(0.02), y, 0.095)
	return {"frame": frame, "block": meshes() - before}


def floor_scrape():
	"""Pale scrape marks: long thin strips along z where the block has dragged over the boards, a few short ones."""
	m = kit.mat("bone", -0.38, rough=0.95)  # (dusty pale brown, not white)
	for i, x in enumerate((-0.5, -0.27, -0.05, 0.2, 0.44)):
		ln = K.rng.uniform(0.75, 1.15)
		K.blk((x + J(0.03), 0.003, 0.15 + ln / 2), (K.rng.uniform(0.025, 0.05), 0.006, ln), m, bevel=0.0015, ry=J(0.05))
	for x, z in ((-0.35, 0.9), (0.33, 0.6)):
		K.blk((x, 0.003, z), (0.16, 0.006, 0.03), m, bevel=0.0015, ry=J(0.3))


# ---------------------------------------------------------------- the rope lift
def lift_platform():
	h = LIFT_HALF
	before = meshes()
	for x in (-0.55, 0.0, 0.55):  # three bearers under the deck
		S.hewn((x + J(0.01), 0.05, -h + 0.02), (x + J(0.01), 0.05, h - 0.02), 0.05)
	z = -h
	while z < h - 0.05:  # split planks across
		w = min(K.rng.uniform(0.2, 0.24), h - z)
		S.board_x(-h, h, z + 0.006, z + w - 0.006, 0.095, 0.2, chips=1)
		z += w
	for x in (-h + 0.06, h - 0.06):
		for zz in (-h + 0.06, h - 0.06):
			K.log((x, 0.19, zz), (x, 1.2, zz), 0.042, None, seg=7, rings=2, ends=True, bend=0.02)
	rails = [((-h + 0.06, -h + 0.06), (h - 0.06, -h + 0.06)),   # back (-z)
		((-h + 0.06, -h + 0.06), (-h + 0.06, h - 0.06)),          # left
		((h - 0.06, -h + 0.06), (h - 0.06, h - 0.06))]             # right (the front, +z, stays open)
	for (ax, az), (bx, bz) in rails:
		for y in (1.12, 0.66):
			K.log((ax, y, az), (bx, y, bz), 0.032 if y > 1 else 0.026, None, seg=7, rings=2, ends=False, bend=0.03)
	# four corner ropes up to the iron ring
	ring_y = LIFT_RING_Y
	for x in (-h + 0.06, h - 0.06):
		for zz in (-h + 0.06, h - 0.06):
			R.rope((x, 1.18, zz), (x * 0.03, ring_y - 0.03, zz * 0.03), 0.014, ends=False)
	kit.ring(0.05, 0.012, K.G((0.0, ring_y, 0.0)), T("iron", "dark"), rot=(90, 0, 0), seg=14)
	platform = meshes() - before
	before = meshes()
	R.rope((0.0, ring_y + 0.04, 0.0), (0.0, ring_y + 1.04, 0.0), 0.018, ends=False)
	return {"platform": platform, "rope": meshes() - before}


def lift_winch():
	before = meshes()
	px = -1.15
	for zz in (-0.6, 0.6):
		K.log((px, 0.0, zz), (px, WINCH_Y + 0.12, zz), 0.07, None, seg=8, rings=3, ends=True, bend=0.02)
		S.hewn((px - 0.05, WINCH_Y, zz), (0.12, WINCH_Y + J(0.004), zz), 0.06)  # the arm out over the shaft
		K.log((px + 0.02, 0.9, zz), (px + 0.5, WINCH_Y - 0.06, zz), 0.035, None, seg=6, rings=2, ends=False, bend=0.0)  # brace
		K.blk((0.0, WINCH_Y - 0.1, zz), (0.09, 0.13, 0.05), T("iron", "dark"), bevel=0.004)  # the drum's bearing under the arm
	frame = meshes() - before
	before = meshes()
	K.log((0.0, WINCH_Y - 0.15, -0.52), (0.0, WINCH_Y - 0.15, 0.52), 0.13, None, seg=10, rings=3, ends=True, bend=0.0)  # the drum
	for zz in (-0.36, 0.0, 0.36):  # rope wound round it
		kit.ring(0.142, 0.014, K.G((0.0, WINCH_Y - 0.15, zz)), kit.tex_mat("rope"), rot=(90, 0, 0), seg=16)
	K.log((0.0, WINCH_Y - 0.15, -0.7), (0.0, WINCH_Y - 0.15, 0.7), 0.03, T("iron", "dark"), seg=6, rings=1, ends=False, bend=0.0)  # the axle (through the bearings)
	K.blk((0.0, WINCH_Y - 0.3, 0.66), (0.05, 0.3, 0.04), T("iron", "dark"), bevel=0.004)  # crank arm
	K.log((0.0, WINCH_Y - 0.44, 0.66), (0.0, WINCH_Y - 0.44, 0.82), 0.022, T("wood"), seg=6, rings=1, ends=False, bend=0.0)  # handle
	drum = meshes() - before
	return {"frame": frame, "drum": drum}


BUILDS = {"trap_spear_wall": trap_spear_wall, "trap_push_wall": trap_push_wall,
	"lift_platform": lift_platform, "lift_winch": lift_winch}  # (floor_scrape: owner, Nov 20, no marks; not built)

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
