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
# Batch 2, the other traps (sheets in docs/art/dungeon-model-sheets/):
#   trap_swing_boulder  4 m wide frame (round root posts on stone footings, a beam lashed on at 3.7 m, under a 4 m
#                  ceiling), an iron eye, a chain and a 1 m boulder in an iron strap. It swings ALONG the path (z),
#                  +-60 degrees round SWING_PIVOT: across it (the sheet) a 60 degree swing would hit the posts.
#                  Parts: "frame" (with the eye plate and eye) and "swing" (the whole chain and the boulder: owner, Nov 20)
#   trap_bear_jaws open: 0.7 m across, a bar with hinge blocks, a trigger plate, a chain to a stake.
#                  Parts: "base", "plate" (sinks 1 cm), "jaw_l"/"jaw_r" (turn 90 degrees up round the hinge line
#                  JAW_HINGE along x: jaw_l -90 back up (it lies at -z), jaw_r +90; shut, their teeth sit 1.8 cm apart)
#   trap_tripwire_wall  (owner, Nov 20: no crossbow) a 2 x 2 m root wood wall with a hip-high cross beam, a small dark
#                  hole in it (a green poison stain under it: the clue) and an iron eye on the sill for the wire.
#                  Parts: "frame", "bolt" (a poison bolt deep in the hole: the code fires it)
#   tripwire       (owner, Nov 20) a 3 mm white wire 0.12 m up, 1 m long: the game stretches it from wall to wall, no
#                  pegs. Parts: "wire_l", "wire_r" (cut: they fall)
#   trap_chest_spikes  (owner, Nov 20) a 2 x 1 dead-end tunnel's floor, 2 x 4 m: the chest's square (z = -1) and the
#                  square you stand on to open it (z = +1), both with iron-ringed spike holes.
#                  Parts: "floor", "spikes" (built up; the game hides them 0.62 m down, slams them up)
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


# ================================================================ batch 2
def bake(objs):
	"""Bake each object's own placement into its points (so a Matrix can then move them all)."""
	from mathutils import Matrix
	for o in objs:
		o.data.transform(o.matrix_basis)
		o.matrix_basis = Matrix.Identity(4)


def big_stone(c, r, m=None):
	"""A big chunky boulder: a lumpy faceted ball (more facets than S.boulder), painted with the Shack stones."""
	import bmesh
	bm = bmesh.new()
	bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0)
	verts = []
	for vt in bm.verts:
		k = 1 + J(0.09)
		verts.append((c[0] + vt.co.x * r * k, c[1] + vt.co.z * r * 0.95 * k, c[2] + vt.co.y * r * k))
	faces = [tuple(vv.index for vv in f.verts) for f in bm.faces]
	bm.free()
	o = S._flat(K.mesh(verts, faces, m or T("greystone")))
	o["role"] = "stone"
	return o


SWING_PIVOT = (0.0, 3.5, 0.13)


def trap_swing_boulder():
	frame0 = meshes()
	beam_y, bz, px = 3.7, 0.13, 1.74
	for sx in (-1, 1):
		x = sx * px
		R.chisel_slab(x, -0.02, 0.56, 0.56, 0.0, 0.16)
		S.real_log((x, 0.14, -0.08), (x + J(0.01), 3.93, -0.08 + J(0.01)), 0.19, "round", stub=False)
		for y in (beam_y - 0.17, beam_y + 0.17):  # rope lashed round the post above and below the beam
			K.lash((x, y, -0.08), 0.195, "y", n=2)
		S.hewn((x - sx * 0.17, 3.05, -0.02), (x - sx * 0.7, beam_y - 0.1, bz - 0.02), 0.055)  # knee brace
	S.real_log((-1.97, beam_y, bz), (1.97, beam_y + J(0.006), bz), 0.14, "round", stub=False)  # the beam, in front of the posts
	for sx in (-1, 1):
		S.peg(sx * px, beam_y, bz + 0.12, "z")
	# the eye plate and its eye stay on the beam; the whole chain swings (owner, Nov 20: the top links moved too little)
	K.blk((0.0, beam_y - 0.135, bz), (0.22, 0.04, 0.2), T("iron", "dark"), bevel=0.006)
	kit.ring(0.045, 0.014, K.G((0.0, beam_y - 0.19, bz)), T("iron", "dark"), rot=(90, 0, 0), seg=12)
	frame = meshes() - frame0
	before = meshes()
	ball_r = 0.5
	ball_c = (0.0, 0.45 + ball_r, bz)
	R.chain(0.0, bz, beam_y - 0.225, ball_c[1] + ball_r + 0.05, major=0.07, minor=0.018)
	links = sorted(meshes() - before, key=lambda n: -bpy.data.objects[n].location.z)
	big_stone(ball_c, ball_r)
	kit.ring(ball_r + 0.005, 0.04, K.G(ball_c), T("iron", "dark"), rot=(0, 90, 0), seg=28)  # iron strap round it (over the top)
	last = bpy.data.objects[links[-1]]  # the strap's eye turns crosswise to the chain's last link (no shared faces)
	eye_rot = (90, 0, 0) if abs(math.degrees(last.rotation_euler.z)) > 45 else (90, 0, 90)
	kit.ring(0.06, 0.018, K.G((0.0, ball_c[1] + ball_r + 0.05, bz)), T("iron", "dark"), rot=eye_rot, seg=12)  # strap's eye
	swing = meshes() - before
	return {"frame": frame, "swing": swing}


JAW_HINGE = 0.04   # the jaws' hinge line: along x at this height, z = 0
JAW_R = 0.3


def jaw(zoff, side, teeth_at):
	"""One jaw, built SHUT: a half ring standing up in the x-y plane (z = zoff), its teeth on the inside of the arch
	pointing across the seam (side = +1: toward +z). Open (lying flat) the teeth stand straight up (owner, Nov 20);
	shut, each tooth sits between two of the other jaw's teeth, 1 cm or more apart."""
	ri, ro, n, t = JAW_R - 0.035, JAW_R, 14, 0.012
	verts, faces = [], []
	for k in range(n + 1):
		a = math.pi * k / n
		for r in (ri, ro):
			for z in (zoff - t / 2, zoff + t / 2):
				verts.append((math.cos(a) * r, JAW_HINGE + math.sin(a) * r, z))
	for k in range(n):
		b = 4 * k
		q = [b, b + 1, b + 3, b + 2, b + 4, b + 5, b + 7, b + 6]
		faces += [(q[0], q[1], q[5], q[4]), (q[2], q[3], q[7], q[6]), (q[0], q[2], q[6], q[4]), (q[1], q[3], q[7], q[5])]
	faces += [(0, 1, 3, 2), (4 * n, 4 * n + 1, 4 * n + 3, 4 * n + 2)]
	S._flat(K.mesh(verts, faces, T("iron", "dark")))
	r0, r1 = ri - 0.03, ri - 0.01  # (1 cm clear of the other band)    # each tooth sits just inside the arch (the other jaw's band is out at ri..ro)
	z0 = zoff - side * t / 2           # it starts at the far face of its own band and reaches across the seam
	for a in teeth_at:
		a = math.radians(a)
		w = math.radians(4.0)  # (1.7 cm between neighbouring teeth)
		tip_z = zoff + side * 0.055
		pts = []
		for r in (r0, r1):
			pts += [(math.cos(a - w) * r, JAW_HINGE + math.sin(a - w) * r, z0), (math.cos(a + w) * r, JAW_HINGE + math.sin(a + w) * r, z0),
				(math.cos(a) * r, JAW_HINGE + math.sin(a) * r, tip_z)]
		S._flat(K.mesh(pts, [(0, 1, 2), (3, 5, 4), (0, 3, 4, 1), (1, 4, 5, 2), (2, 5, 3, 0)], T("iron", "a")))
		# a root block joining the tooth to its band (inside the band's own thickness only)
		ra = (r1 + ri) / 2
		K.blk((math.cos(a) * ra, JAW_HINGE + math.sin(a) * ra, zoff), (0.016, 0.016, t * 0.9), T("iron", "dark"), bevel=0.002,
			rz=math.degrees(a))
	for x in (-JAW_R + 0.017, JAW_R - 0.017):  # the eye round the hinge pin
		kit.ring(0.02, 0.006, K.G((x, JAW_HINGE, zoff)), T("iron", "dark"), rot=(0, 90, 0), seg=10)


def trap_bear_jaws():
	base0 = meshes()
	K.blk((0.0, 0.0125, 0.0), (0.86, 0.025, 0.06), T("iron", "dark"), bevel=0.005)  # the bar under it all
	for sx in (-1, 1):
		K.blk((sx * 0.3, 0.03, 0.0), (0.03, 0.035, 0.05), T("iron", "dark"), bevel=0.004)  # hinge block
		kit.cylinder(0.009, 0.075, K.G((sx * (JAW_R - 0.017), JAW_HINGE, 0.0)), T("iron", "dark"), rot=(0, 90, 0), verts=8, bevel=0.002)  # pin
		for k in range(3):  # the spring: a bent leaf at each end
			K.blk((sx * (0.36 + k * 0.025), 0.03 + k * 0.012, 0.0), (0.03, 0.012, 0.05), T("iron", "dark"), bevel=0.003, rz=-sx * 25)
	kit.cylinder(0.1, 0.016, K.G((0.0, 0.031, 0.0)), T("iron", "dark"), verts=18, bevel=0.003)  # round plate the trigger sits on
	x, k = 0.445, 0  # the chain to a stake (links lying along the floor), and the stake
	while x < 0.86:
		if k % 2 == 0:
			kit.ring(0.03, 0.008, K.G((x, 0.03, 0.0)), T("iron", "dark"), rot=(90, 0, 0), seg=10)
		else:
			kit.ring(0.03, 0.008, K.G((x, 0.009, 0.0)), T("iron", "dark"), rot=(0, 0, 0), seg=10)
		x += 2 * (0.03 - 0.008) - 0.004
		k += 1
	K.blk((x + 0.02, 0.06, 0.0), (0.05, 0.16, 0.05), T("wood", "dark"), bevel=0.01, rx=8)  # the stake, driven into the floor
	base = meshes() - base0
	before = meshes()
	kit.cylinder(0.085, 0.012, K.G((0.0, 0.045, 0.0)), T("iron", "a"), verts=16, bevel=0.003)
	plate = meshes() - before
	groups = {"base": base, "plate": plate}
	for name, zoff, side, teeth, ang in (("jaw_l", -0.011, 1, range(12, 180, 24), -90), ("jaw_r", 0.011, -1, range(24, 180, 24), 90)):
		before = meshes()
		jaw(zoff, side, teeth)
		new = meshes() - before
		R.rot_x([bpy.data.objects[n] for n in new], math.radians(ang), (0.0, JAW_HINGE, 0.0))  # lay it open
		groups[name] = new
	return groups


def trap_tripwire_wall(w=2.0, h=2.0):
	"""Owner, Nov 20: no crossbow, just a small dark hole in the wall that a poison bolt shoots out of. The wire runs
	from an iron eye on the wall's sill beam out across the floor (the `tripwire` model's pegs)."""
	frame0 = meshes()
	px = R.wall_frame3(w, h)
	hole_y, hole_x = 0.95, 0.12
	x0, x1 = -px + 0.13, px - 0.13
	beam_y, beam_r = 0.95, 0.09
	before = meshes()
	S.hewn((-px, beam_y, 0.0), (px, beam_y + J(0.004), 0.0), beam_r)  # a cross beam at hip height (the hole is in it)
	beam = bpy.data.objects[(meshes() - before).pop()]
	for (y0, y1, widths) in ((0.17, beam_y - beam_r + 0.03, [0.4, 0.34, 0.38]), (beam_y + beam_r - 0.03, S.TOP_BEAM - 0.08, [0.36, 0.42, 0.33])):
		ws = widths + [(x1 - x0) - sum(widths)]
		gaps = [0.014, 0.022, 0.016]
		x = x0
		for i, bw in enumerate(ws):
			a = x + (gaps[i - 1] / 2 if i else 0.0)
			b = x + bw - (gaps[i] / 2 if i < len(gaps) else 0.0)
			S.rough_vboard(a, b, y0, y1, J(0.008), 0.07)
			x += bw
	for y in (0.115, S.TOP_BEAM):
		for xx in (-0.55, 0.0, 0.5):
			S.pegs_on(xx + J(0.04), y, 0.112 if y > 1 else 0.093)
	R.bore(beam, K.G((hole_x, hole_y, beam_r)), 0.025, 0.24)
	K.log((hole_x, hole_y, beam_r - 0.17), (hole_x, hole_y, beam_r - 0.09), 0.021, kit.mat("charcoal", -0.6), seg=12, rings=1, ends=True, bend=0)
	# the clue: a dark green poison stain run down the beam under the hole
	K.blk((hole_x, hole_y - 0.06, beam_r - 0.004), (0.022, 0.07, 0.012), kit.mat("sprout", -0.25, rough=0.3), bevel=0.004)
	kit.ring(0.022, 0.006, K.G((hole_x, 0.15, 0.1)), T("iron", "dark"), rot=(0, 90, 0), seg=10)  # the wire's eye on the sill, under the hole
	frame = meshes() - frame0
	# the poison bolt waiting deep in the hole (the player's blight bolt from items_tools.py, its shape code only)
	from mathutils import Matrix
	path = Path(__file__).resolve().parent / "items_tools.py"
	src = path.read_text(encoding="utf-8")
	ns = {"__file__": str(path), "__name__": "items_tools_borrowed"}
	exec(compile(src[:src.index("ids = sys.argv")], str(path), "exec"), ns)
	before = meshes()
	ns["bolt"]("blight")
	new = [bpy.data.objects[n] for n in meshes() - before]
	bake(new)
	M = Matrix.Translation(K.G((hole_x, hole_y, beam_r - 0.6))) @ Matrix.Rotation(math.pi, 4, "Z") @ Matrix.Rotation(-math.pi / 2, 4, "X")
	for o in new:
		o.data.transform(M)
	return {"frame": frame, "bolt": {o.name for o in new}}


def tripwire():
	"""Owner, Nov 20: very thin (hard to see), and it runs straight from wall to wall, no pegs. 1 m long along x,
	origin in its middle: the game stretches it (x) to the corridor's width. Two halves, so it can be cut."""
	white = kit.mat("bone", 0.12, rough=0.35)
	groups = {}
	for name, a, b in (("wire_l", -0.5, 0.008), ("wire_r", -0.008, 0.5)):
		before = meshes()
		kit.cylinder(0.0015, b - a, K.G(((a + b) / 2, 0.12, 0.0)), white, rot=(0, 90, 0), verts=6, bevel=0.0)
		groups[name] = meshes() - before
	return groups


def spike_floor(zc, holes, joists, w=2.0, dd=2.0, t=0.25):
	"""One 2 x 2 m root wood floor square (centre z = zc) with iron-ringed holes at `holes` (x, z from its middle).
	The joists (z from the middle) run between the hole rows (owner, Nov 20: orange bark showed through the holes)."""
	zs = tuple(zc + j for j in joists)
	for z in zs:
		S.hewn((-w / 2 + 0.165, 0.1, z + J(0.01)), (w / 2 - 0.165, 0.1 + J(0.006), z + J(0.01)), 0.06)
	y0, y1 = 0.148, t - 0.015
	x, x1, i = -w / 2 + 0.012, w / 2 - 0.012, 0
	boards = []
	while x < x1 - 0.05:
		bw = min(K.rng.uniform(0.3, 0.42), x1 - x)
		if x1 - (x + bw) < 0.16:
			bw = x1 - x
		a = x + (0.008 if i else 0.0)
		b = x + bw - (0.008 if x + bw < x1 - 0.01 else 0.0)
		before = meshes()
		S.rough_board(a, b, -dd / 2 + 0.006, dd / 2 - 0.006, y0, y1, chips=1)  # built at the middle, then slid to zc
		o = bpy.data.objects[(meshes() - before).pop()]  # (rough_board built away from z = 0 came out short)
		o.location.y -= zc  # (Blender y = -game z)
		boards.append((a, b, o))
		for zz in zs:
			gx, gz = (a + b) / 2 + J(0.04), zz + J(0.015)
			if min(math.hypot(gx - hx, gz - zc - hz) for hx, hz in holes) > SPIKE_HOLE + 0.06:  # (never in a spike hole)
				S.peg(gx, y1 - 0.026, gz, "y")
		x += bw
		i += 1
	for hx, hz in holes:  # bore each hole through its board(s), an iron ring round it
		for a, b, o in boards:
			if a - SPIKE_HOLE < hx < b + SPIKE_HOLE:
				R.bore(o, K.G((hx, (y0 + y1) / 2, zc + hz)), SPIKE_HOLE, 0.4, axis_rot=(0, 0, 0))
		kit.ring(SPIKE_HOLE + 0.012, 0.011, K.G((hx, y1 + 0.002, zc + hz)), T("iron", "dark"), rot=(0, 0, 0), seg=14)


SPIKE_HOLE = 0.042


def trap_chest_spikes():
	"""Owner, Nov 20: you could open the chest without standing on the spikes, so the trap is a 2 x 1 dead-end tunnel
	(two squares, 2 x 4 m): the chest's square (back, z = -1) and the square you stand on to open it (front, z = +1),
	both full of spike holes. Origin: the middle of the two squares, floor bottom."""
	floor0 = meshes()
	chest_sq = []
	for k in range(12):  # round the chest (its 0.9 x 0.6 m spot stays clear)
		a = k * math.tau / 12 + math.radians(15)
		chest_sq.append((0.8 * math.cos(a), 0.8 * math.sin(a)))
	stand_sq = [(x, z) for x in (-0.72, -0.24, 0.24, 0.72) for z in (-0.72, -0.24, 0.24, 0.72)]  # where you stand: a grid
	spike_floor(-1.0, chest_sq, (-0.39, 0.0, 0.39))  # (each joist 18 cm or more from every hole's middle)
	spike_floor(1.0, stand_sq, (-0.48, 0.0, 0.48))
	for sx in (-1, 1):  # the rim: long side beams the whole length, end beams stopping 1 cm short of them (no corner overlap)
		S.hewn((sx * 0.92, 0.115, -1.985), (sx * 0.92, 0.115 + J(0.004), 1.985), 0.068)
	for sz in (-1, 1):
		S.hewn((-0.84, 0.115, sz * 1.92), (0.84, 0.115 + J(0.004), sz * 1.92), 0.068)
	floor = meshes() - floor0
	before = meshes()
	for zc, holes in ((-1.0, chest_sq), (1.0, stand_sq)):
		for hx, hz in holes:  # iron spikes, up (tip 0.6 m above the floor); each shaft just fills its hole
			kit.cylinder(SPIKE_HOLE - 0.003, 0.3, K.G((hx, 0.1, zc + hz)), T("iron", "dark"), verts=10, bevel=0.003)
			kit.cone(SPIKE_HOLE - 0.003, 0.003, 0.62, K.G((hx, 0.25 + 0.31 - 0.002, zc + hz)), T("iron", "a"), verts=10, bevel=0.0)
	spikes = meshes() - before
	return {"floor": floor, "spikes": spikes}

BUILDS = {"rail_lane": rail_lane, "rail_wedge": rail_wedge, "rail_buffer": rail_buffer, "trap_cart": trap_cart,
	"trap_swing_boulder": trap_swing_boulder, "trap_bear_jaws": trap_bear_jaws,
	"trap_tripwire_wall": trap_tripwire_wall, "tripwire": tripwire, "trap_chest_spikes": trap_chest_spikes}

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
