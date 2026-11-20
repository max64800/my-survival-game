# Dungeon traps in root wood, batch 2 (owner, Nov 19, 2026: dungeons, docs/decisions/2026-11-19-dungeons.md: "all of
# the walls ... out of our root wood"). Built from the Delver's Shack's own parts (shack_v2.py: hewn logs, split
# boards, wooden pegs, its painted bark/plank/stone pictures), so they match the dungeon's walls and floors exactly.
#
#   blender --background --factory-startup --python builds/dungeon_rootwood.py -- <out_dir> [only=trap_dart_plate,...] [grey=1]
#
# Same axes as the Shack script: x across, y up, z = front (+z faces the room). Origin bottom-centre.
#   trap_dart_plate   a pressure plate (0.7 m square) of three short boards on two cleats, sitting ON a floor: it
#                     stands a finger higher than the boards around it (the clue)
#   trap_dart_wall    a 2 x 2 m Shack wall with a hewn "dart beam" across it at hip height, five holes bored in it
#                     with black plugs deep inside (the clue: a row of black holes)
#   trap_floor_break  a 2 x 2 m Shack floor gone rotten: cracked boards with jagged breaks, thin rotten joists, a
#                     sagging board (the clue). Same height as the normal floor, so it lines up with it. Parts:
#                     "frame" (beams, stay) and board0, board1... (each falls on its own)
#   bridge_plank      batch 3: a 2 m section of plank bridge (rope stringers, planks across, hand ropes), tiles along z
#   bridge_plank_broken  the same with planks gone, one hanging, a hand rope snapped
#   bridge_plank_gap  the same with the four middle planks gone (you jump the gap), hand ropes whole
#   bridge_ropes      the same with every plank gone: just the ropes (owner, Nov 20: only the middle section has planks)
#   dungeon_entrance  the front door frame in the cave wall (3 m wide): the round doorway, big posts, lintel, rune board
#   door_loot         the loot room's heavy round door: iron bands, lock plate, a big ring (fits the normal doorway)
#   chain_hanging     1.5 m of the crusher's iron chain under a ceiling plate (origin = the ceiling, chain hangs down)
#   trap_crusher      a cage of logs packed with stones hanging on two chains from a ceiling beam (3.6 m up).
#                     Two parts: "frame" (the beam, stays) and "weight" (the cage and its chains, which run up through
#                     holes in the beam into the ceiling: the weight slams down 1.6 m and the chain pays out with it)
#   batch 4: gate_round, lever, railing_broken (the hidden boulder is one of the cave's own boulders, owner Nov 19)
#   batch 5: wall_cracked (in front of the hidden vault: split boards, a broken hole, splinters; parts frame + board0..),
#            wall_old / floor_old (worn, gappy, broken, darker greyer paint), floor_loose_stone (a loose chisel-cut
#            flagstone in a Shack floor over the buried chest; parts frame + stone)
import math
import sys
from pathlib import Path

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kit  # noqa: E402
import kit_zone1 as K  # noqa: E402
import shack_v2 as S  # noqa: E402  (sets K.S = "shack")

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = Path(ARGS[0]) if ARGS else Path(".")
OPTS = dict(a.split("=", 1) for a in ARGS[1:] if "=" in a)
ONLY = OPTS.get("only", "").split(",") if OPTS.get("only") else None
GREY = OPTS.get("grey") == "1"
J, T = K.J, K.T


def meshes():
	return {o.name for o in bpy.data.objects if o.type == "MESH"}


# ---------------------------------------------------------------- dart plate
def dart_plate():
	h = 0.07
	for z in (-0.22, 0.22):  # two cleats under the boards
		S.hewn((-0.3, 0.022, z + J(0.01)), (0.3, 0.022 + J(0.003), z + J(0.01)), 0.022)
	xs = [-0.34, -0.12, 0.1, 0.34]
	for i in range(3):
		a = xs[i] + (0.007 if i else 0.0)
		b = xs[i + 1] - (0.007 if i < 2 else 0.0)
		S.rough_board(a, b, -0.33, 0.33, 0.04, h, warp=J(0.004), chips=1)
		for z in (-0.22, 0.22):
			S.peg((a + b) / 2 + J(0.02), h - 0.026, z + J(0.01), "y")


# ---------------------------------------------------------------- dart wall
def bore(target, centre_blender, r, depth, axis_rot=(math.pi / 2, 0, 0)):
	"""Cut a round hole into `target` (a boolean difference with a cylinder), then remove the cutter."""
	bpy.ops.mesh.primitive_cylinder_add(vertices=14, radius=r, depth=depth, location=centre_blender, rotation=axis_rot)
	cut = bpy.context.object
	m = target.modifiers.new("bore", "BOOLEAN")
	m.operation = "DIFFERENCE"
	m.object = cut
	m.solver = "EXACT"
	bpy.ops.object.select_all(action="DESELECT")
	target.select_set(True)
	bpy.context.view_layer.objects.active = target
	bpy.ops.object.modifier_apply(modifier=m.name)
	bpy.data.objects.remove(cut, do_unlink=True)


def dart_wall(w=2.0, h=2.0):
	px = w / 2 - 0.006 - 0.145
	for s_ in (-1, 1):
		S.hewn((s_ * px, 0.012, 0.0), (s_ * px + J(0.008), h - 0.05, J(0.006)), 0.14)
	S.hewn((-px, 0.115, 0.0), (px, 0.115 + J(0.008), 0.0), 0.1)
	S.hewn((-px, S.TOP_BEAM, 0.0), (px, S.TOP_BEAM + J(0.004), 0.0), 0.12)
	beam_y, beam_r = 0.95, 0.11
	before = meshes()
	S.hewn((-px, beam_y, 0.0), (px, beam_y + J(0.004), 0.0), beam_r)  # the dart beam, between the posts like the others
	beam = bpy.data.objects[(meshes() - before).pop()]
	x0, x1 = -px + 0.13, px - 0.13
	for (y0, y1, widths) in ((0.17, beam_y - beam_r + 0.03, [0.4, 0.34, 0.38]), (beam_y + beam_r - 0.03, S.TOP_BEAM - 0.08, [0.36, 0.42, 0.33])):
		ws = widths + [(x1 - x0) - sum(widths)]
		gaps = [0.014, 0.022, 0.016]
		x = x0
		for i, bw in enumerate(ws):
			a = x + (gaps[i - 1] / 2 if i else 0.0)
			b = x + bw - (gaps[i] / 2 if i < len(gaps) else 0.0)
			S.rough_vboard(a, b, y0, y1, J(0.008), 0.07, broken_top=(y0 > 1 and i == 2))
			x += bw
	for y in (0.115, S.TOP_BEAM):
		for xx in (-0.55, 0.0, 0.5):
			S.pegs_on(xx + J(0.04), y, 0.112 if y > 1 else 0.093)
	# five holes in the beam's front, each with a dark iron nozzle set back inside it
	hole_r, depth = 0.04, 0.2  # (round 2: bigger, they looked like pegs; round 3: deeper, black inside)
	for k in range(5):
		x = -0.6 + 0.3 * k + J(0.02)
		front = beam_r  # the beam's front face is about here (hewn: flat faces); the cutter reaches past it
		bore(beam, K.G((x, beam_y, front)), hole_r, depth)
		# (owner, Nov 19: "they have to have holes, black ones"): a black plug deep in each hole, so it reads as a dark hole
		K.log((x, beam_y, front - 0.15), (x, beam_y, front - 0.07), hole_r - 0.005, kit.mat("charcoal", -0.6), seg=12, rings=1, ends=True, bend=0)
	S.pegs_on(-0.75, beam_y, beam_r - 0.01)
	S.pegs_on(0.75, beam_y, beam_r - 0.01)


# ---------------------------------------------------------------- floor that breaks
def floor_break(w=2.0, dd=2.0, t=0.25):
	zs = (-dd / 2 + 0.3, dd / 2 - 0.3)  # only two joists left, thin and rotten
	for z in zs:
		S.hewn((-w / 2 + 0.165, 0.1, z + J(0.01)), (w / 2 - 0.165, 0.1 + J(0.006), z + J(0.01)), 0.05)
	S.rim_beams([(-w / 2, -dd / 2), (w / 2, -dd / 2), (w / 2, dd / 2), (-w / 2, dd / 2)])
	y0, y1 = 0.148, t - 0.015
	x = -w / 2 + 0.012
	x1 = w / 2 - 0.012
	i = 0
	while x < x1 - 0.05:
		bw = min(K.rng.uniform(0.3, 0.45), x1 - x)
		if x1 - (x + bw) < 0.16:
			bw = x1 - x
		a = x + (K.rng.uniform(0.008, 0.02) if i else 0.0)  # (wider gaps than a new floor: it's old)
		b = x + bw - (K.rng.uniform(0.008, 0.02) if x + bw < x1 - 0.01 else 0.0)
		z0, z1 = -dd / 2 + 0.006, dd / 2 - 0.006
		crack = K.rng.uniform(-0.45, 0.45)  # every board is cracked across somewhere, with a jagged gap
		gap = K.rng.uniform(0.04, 0.08)  # (round 2: wider, the clue must read)
		sag = K.rng.uniform(0.015, 0.03) if i % 2 else 0.006  # every other board sags a little at the crack
		S.rough_board(a, b, z0, crack - gap / 2, y0, y1, broken="front", warp=-sag)
		hole = 0.22 if i == 2 else 0.0  # (round 2) one board has a chunk broken out: you see the dark below
		S.rough_board(a, b, crack + gap / 2 + hole, z1, y0 - sag, y1 - sag, broken="back", warp=sag)
		for zz in zs:
			S.peg((a + b) / 2 + J(0.04), (y1 - sag if zz > crack else y1) - 0.026, zz + J(0.015), "y")
		x += bw
		i += 1
	return board_groups()


def board_groups():
	"""Owner, Nov 19: the floor needs to break. Each board is its own part (board0, board1...) with the pegs in it,
	so the game can drop them one by one; the beams stay as "frame"."""
	objs = [o for o in bpy.data.objects if o.type == "MESH"]
	boards = [o for o in objs if o.get("role") == "board"]
	groups = {"frame": set()}
	boxes = []
	for k, o in enumerate(boards):
		vs = [o.matrix_world @ v.co for v in o.data.vertices]
		boxes.append((f"board{k}", min(v.x for v in vs), max(v.x for v in vs), min(v.y for v in vs), max(v.y for v in vs)))
		groups[f"board{k}"] = {o.name}
	for o in objs:
		if o in boards:
			continue
		if o.get("role") == "log":
			groups["frame"].add(o.name)
			continue
		vs = [o.matrix_world @ v.co for v in o.data.vertices]
		cx, cy = sum(v.x for v in vs) / len(vs), sum(v.y for v in vs) / len(vs)
		best = min(boxes, key=lambda bx: max(bx[1] - cx, cx - bx[2], 0) + max(bx[3] - cy, cy - bx[4], 0))
		groups[best[0]].add(o.name)
	return groups


# ---------------------------------------------------------------- the chain on its own (owner, Nov 19: "I really
# like the chains, save them"): 1.5 m of the crusher's chain under a small iron ceiling plate, for decor anywhere
def chain_hanging(length=1.5):
	K.blk((0, -0.02, 0), (0.16, 0.04, 0.16), T("iron", "dark"), bevel=0.008)  # the plate on the ceiling (y = 0 is the ceiling)
	chain(0.0, 0.0, 0.01, -length)


# ---------------------------------------------------------------- crusher
def chain(x, z, y_top, y_bot, major=0.05, minor=0.012):
	"""Iron chain links hanging from y_top to y_bot (each link through the next, turned a quarter)."""
	n = max(2, math.ceil((y_top - y_bot - 2 * major) / (2 * (major - minor) - 0.004)) + 1)
	step = (y_top - y_bot - 2 * major) / (n - 1)  # the last link ends exactly on y_bot (it rests on the beam)
	for k in range(n):
		y = y_top - major - k * step
		rot = (90, 0, 0) if k % 2 == 0 else (90, 0, 90)  # (kit.ring takes degrees)
		kit.ring(major, minor, K.G((x, y, z)), T("iron", "dark"), rot=rot, seg=10)
	return y_top - major - (n - 1) * step - major  # the lowest point of the chain


def crusher():
	beam_y, beam_r = 3.6, 0.14
	yb, yt = 1.6, 2.6            # the weight's bottom and top, raised (it slams down to the floor in the game)
	hx, hz = 0.9, 0.5
	frame0 = meshes()
	S.hewn((-0.99, beam_y, 0.0), (0.99, beam_y + J(0.006), 0.0), beam_r)  # sits into the corridor walls
	beam = bpy.data.objects[(meshes() - frame0).pop()]
	frame = meshes() - frame0
	lift_y = yt + 0.06
	# The chains belong to the weight (owner, Nov 19: "chains need to extend up and down"): they run up through
	# two holes in the beam into the ceiling rock, 1.65 m longer than needed, so when the weight slams down the
	# chain pays out of the beam with it. The hole is 6 mm wider than the links (they touch, nothing passes through).
	for x in (-0.45, 0.45):
		bore(beam, K.G((x, beam_y, 0.0)), 0.068, 0.6, axis_rot=(0, 0, 0))
		chain(x, 0.0, beam_y + beam_r + 1.65, lift_y + 0.035)
	# the weight: a thick board bottom (the crushing face), four corner posts, rails, stones packed inside, lifting beams
	for i, (a, b) in enumerate([(-0.88, -0.53), (-0.52, -0.17), (-0.16, 0.19), (0.2, 0.54), (0.55, 0.88)]):
		S.rough_board(a, b, -hz + 0.02, hz - 0.02, yb, yb + 0.09, chips=2, broken="front" if i == 3 else None)
	# little iron spikes driven into the bottom boards, pointing down (owner, Nov 19), each 1 cm into the wood
	for gx in range(6):
		for gz in range(3):
			x, z = -0.75 + gx * 0.3 + J(0.03), -0.3 + gz * 0.3 + J(0.03)
			L = 0.11 + J(0.015)
			kit.cone(0.004, 0.03, L, K.G((x, yb - L / 2 + 0.01, z)), T("iron", "dark"), verts=6, bevel=0.0)
	for sx in (-1, 1):
		for sz in (-1, 1):
			S.hewn((sx * 0.8, yb + 0.09, sz * 0.4), (sx * 0.8 + J(0.006), yt, sz * 0.4 + J(0.006)), 0.09)
	for y in (yb + 0.5, yt - 0.09):
		for sz in (-1, 1):
			S.hewn((-0.71, y, sz * 0.4), (0.71, y + J(0.004), sz * 0.4), 0.075)
		for sx in (-1, 1):
			S.hewn((sx * 0.8, y + 0.0, -0.31), (sx * 0.8, y + J(0.004), 0.31), 0.075)
	for gx in range(4):
		for gz in range(2):
			for gy in range(2):
				c = (-0.54 + gx * 0.36 + J(0.03), yb + 0.24 + gy * 0.42 + J(0.03), -0.17 + gz * 0.34 + J(0.03))
				S.boulder(c, 0.235 + J(0.02), 0.24 + J(0.02), 0.2 + J(0.015), floor=yb + 0.095)  # (packed: each touches its neighbours)
	for x in (-0.45, 0.45):  # lifting beams across the top rails; the chains hang onto them
		S.hewn((x, lift_y, -hz + 0.01), (x + J(0.006), lift_y, hz - 0.01), 0.07)
	for sx in (-1, 1):  # rope lashings where the top rails meet the posts
		for sz in (-1, 1):
			K.lash((sx * 0.8, yt - 0.09, sz * 0.4), 0.09, "y", n=2)
	weight = meshes() - frame0 - frame
	return {"frame": frame, "weight": weight}


# ================================================================ batch 3: bridge, entrance, loot door
def rope(p0, p1, r, ends=True):
	o = K.log(p0, p1, r, kit.tex_mat("rope"), seg=8, rings=3, ends=ends, bend=0.0)
	o["role"] = "rope"
	return o


def bridge(broken=False, gap=False, bare=False):
	"""A 2 m section of plank bridge (along z, 1.3 m wide): two thick rope stringers under split planks laid
	across, hand ropes at 0.95 m tied down to the planks. Sections side by side make a bridge of any length.
	broken: two planks gone, one hanging off a stringer, the left hand rope snapped with both ends dangling.
	gap (owner, Nov 20: "leave a couple of middle boards missing so you must jump"): the four middle planks gone
	(about 1 m of bare rope), both hand ropes whole.
	bare (owner, Nov 20, 3rd play: "too easy, remove all the planks but the middle ones"): every plank gone, only the
	stringers and hand ropes, the ties running from the hand ropes down onto the stringers (you jump across)."""
	L = 0.994
	for x in (-0.5, 0.5):
		rope((x, 0.04, -L), (x, 0.04, L), 0.035)
	zs, z = [], -L + 0.01
	while z < L - 0.2:
		w = K.rng.uniform(0.2, 0.23)
		zs.append((z, min(z + w, L - 0.01)))
		z += w + K.rng.uniform(0.025, 0.035)
	gone = {3, 4} if broken else ({2, 3, 4, 5} if gap else set())
	if bare:
		gone = set(range(len(zs)))
	for i, (z0, z1) in enumerate(zs):
		if i in gone:
			continue
		o = S.board_x(-0.66 + J(0.02), 0.66 + J(0.02), z0, z1, 0.058, 0.108, chips=2,  # (rests 1.7 cm into the faceted ropes)
			 broken=("front" if broken and i == 2 else None))
		if broken and i == 6:  # hangs off the right stringer: turned down about its right end
			a = math.radians(38)  # (round 2: +, so the loose end hangs down)
			for v in o.data.vertices:
				dx, dz = v.co.x - 0.5, v.co.z - 0.058
				v.co.x, v.co.z = 0.5 + dx * math.cos(a) - dz * math.sin(a), 0.058 + dx * math.sin(a) + dz * math.cos(a)
	for x in (-0.64, 0.64):
		snapped = broken and x < 0
		if snapped:  # snapped: each end droops down from where it broke, frayed
			rope((x, 0.95, -L), (x, 0.95, -0.12), 0.028)
			rope((x, 0.95, -0.15), (x - 0.06, 0.42, 0.08), 0.026)
			rope((x, 0.95, L), (x, 0.95, 0.5), 0.028)
			rope((x, 0.95, 0.53), (x - 0.05, 0.55, 0.36), 0.026)
		else:
			rope((x, 0.95, -L), (x, 0.95, L), 0.028)
		for i, (z0, z1) in enumerate(zs):
			zc = (z0 + z1) / 2
			if (i % 2 and not (snapped and zc > 0.5)) or (i in gone and not bare) or (broken and i == 6):  # (the snapped end keeps a tie)
				continue
			zc = (z0 + z1) / 2
			if snapped and -0.12 < zc < 0.5:
				continue
			if bare:  # (down onto the stringer rope: 2 cm into it, so they touch)
				rope((x, 0.95, zc), (x * 0.81, 0.055, zc), 0.013)
				continue
			rope((x, 0.95, zc), (x * 0.97, 0.1, zc), 0.013)  # the tie from the hand rope down to the plank


def entrance():
	"""The dungeon's front door frame, set into the cave wall: the Shack round doorway in the middle, two big bark
	posts on stone footings, a heavy lintel log with a second log on it, boards between, a rune board on the front.
	The round door itself is the normal Shack door."""
	S.doorway_v3(2.0, 2.0, 0.3)
	for sx in (-1, 1):
		S.boulder((sx * 1.2, 0.1, 0.0), 0.3, 0.13, 0.3)
		S.real_log((sx * 1.2, 0.16, 0.0), (sx * 1.2 + J(0.01), 2.3, J(0.01)), 0.2, "round", stub=False)
		K.lash((sx * 1.2, 2.12, 0.0), 0.2, "y", n=2)
	S.real_log((-1.52, 2.45, 0.0), (1.52, 2.45 + J(0.01), 0.0), 0.2, "round", stub=False)
	S.real_log((-1.2, 2.77, 0.02), (1.2, 2.77, 0.02), 0.13, "round", stub=False)
	x0, x1 = -0.99, 0.99  # boards between the doorway's top beam and the lintel
	xs = [x0, -0.5, -0.02, 0.48, x1]
	for i in range(4):
		a = xs[i] + (0.008 if i else 0.0)
		b = xs[i + 1] - (0.008 if i < 3 else 0.0)
		S.rough_vboard(a, b, 1.975, 2.28, J(0.006), 0.07)
	# the rune board: a thick board pinned to the lintel's front, three runes of dark wood strips on it
	before = meshes()
	K.blk((0.0, 2.45, 0.225), (1.0, 0.26, 0.05), T("wood"), bevel=0.01)
	for n in meshes() - before:
		bpy.data.objects[n]["role"] = "board"
	for rx, strokes in ((-0.3, [(0, 0, 90), (0.04, 0.04, 35), (0.04, -0.04, -35)]), (0.0, [(-0.04, 0, 90), (0.04, 0, 90), (0, 0, 0)]),
			(0.3, [(0, 0, 90), (0.035, 0.05, -40), (0.035, -0.05, 40)])):
		for dx, dy, ang in strokes:
			K.blk((rx + dx, 2.45 + dy, 0.255), (0.15 if ang == 90 or ang == 0 else 0.1, 0.022, 0.012), T("wood", "dark"), bevel=0.003, rz=ang)
	for x in (-0.44, 0.44):
		S.peg(x, 2.45, 0.25, "z")


def loot_door():
	"""The heavy round door of the loot room: the Shack door's size and build, but thicker boards held by three
	iron bands, an iron lock plate with a keyhole and a big iron ring. It fits the normal round doorway."""
	r, cy = S.DOOR_R - 0.012, S.DOOR_CY
	E = S.E
	fr = K.Frame()
	widths = [0.3, 0.34, 0.26, 0.33]
	widths.append(2 * r - sum(widths))
	x = -r
	for bw in widths:
		a, b = x + K.rng.uniform(0.003, 0.008), x + bw - K.rng.uniform(0.003, 0.008)
		short = K.rng.uniform(0.0, 0.02)
		lo = lambda xx: max(E, cy - math.sqrt(max(0.0, r * r - xx * xx)))
		hi = (lambda sh: (lambda xx: cy + math.sqrt(max(0.0, r * r - xx * xx)) - sh - abs(J(0.01))))(short)
		before = meshes()
		K.plank_shape(fr, a, b, lo, hi, -0.01 + J(0.003), 0.08, T("wood"), k=8)
		for n in meshes() - before:
			bpy.data.objects[n]["role"] = "board"
			S._flat(bpy.data.objects[n])
		x += bw
	a0 = math.asin(-cy / r)
	for (o, am, rm) in S.rough_ring(0.0, cy, r - 0.1, 0.066, 10, 0.022, z=0.041, a0=a0, a1=math.pi - a0):
		kit.rivet(K.G((math.cos(am) * rm, cy + math.sin(am) * rm, 0.05)), T("iron", "dark"), r=0.013)
	iron = T("iron", "dark")
	for y in (cy - 0.42, cy, cy + 0.42):  # iron bands across, inside the rim, on the boards
		hw = math.sqrt(max(0.0, (r - 0.11) ** 2 - (y - cy) ** 2))
		K.slab_poly(fr, [(-hw, y - 0.045), (hw, y - 0.045), (hw, y + 0.045), (-hw, y + 0.045)], 0.034, 0.01, iron)
		for xx in (-hw + 0.06, -hw / 2, hw / 2, hw - 0.06):
			kit.rivet(K.G((xx, y, 0.039)), iron, r=0.011)
	K.slab_poly(fr, [(0.2, cy - 0.12), (0.4, cy - 0.12), (0.4, cy + 0.12), (0.2, cy + 0.12)], 0.044, 0.01, iron)  # lock plate on the band
	kit.cylinder(0.018, 0.006, K.G((0.3, cy + 0.02, 0.05)), T("charcoal") if False else kit.mat("charcoal"), rot=(90, 0, 0), verts=10, bevel=0.0)  # keyhole
	K.blk((0.3, cy - 0.045, 0.05), (0.014, 0.05, 0.006), kit.mat("charcoal"), bevel=0.0)
	kit.cylinder(0.03, 0.03, K.G((-0.22, cy + 0.03, 0.054)), iron, rot=(90, 0, 0), verts=8, bevel=0.003)  # the ring's staple
	kit.ring(0.1, 0.016, K.G((-0.22, cy - 0.075, 0.075)), iron, rot=(90, 0, 0), seg=16)  # the big ring, hanging
	for y in (cy - 0.3, cy + 0.3):  # back battens
		hw = math.sqrt(max(0.0, (r - 0.1) ** 2 - (y - cy) ** 2))
		before = meshes()
		K.blk((J(0.02), y, -0.06), (2 * hw - 0.04, 0.11, 0.02), T("wood", "dark"), bevel=0.006, rz=J(2))
		for n in meshes() - before:
			bpy.data.objects[n]["role"] = "board"


# ================================================================ batch 4: gate, lever, broken railing
def gate_round():
	"""A round gate of root wood bars for the way back into the entrance room (owner: "open a gate/door from the boss
	side"). Round doors only, so it is the round door's shape: a rim of board pieces, upright poles behind, three cross
	bars in front of them (stacked, nothing passes through), iron rivets where they cross. You can see through it.
	Fits the normal round doorway; hinge on its left like the door."""
	r, cy = S.DOOR_R - 0.012, S.DOOR_CY
	E = S.E
	a0 = math.asin(-cy / r)
	S.rough_ring(0.0, cy, r - 0.11, 0.1, 10, 0.06, z=0.035, a0=a0, a1=math.pi - a0)
	ri = r - 0.105  # the rim's inside: the bars stop on it
	for x in (-0.48, -0.24, 0.0, 0.24, 0.48):
		h = math.sqrt(max(0.0, ri * ri - x * x))
		S.hewn((x + J(0.01), max(E + 0.03, cy - h), 0.0), (x + J(0.01), cy + h, 0.0), 0.034)
	for y in (cy - 0.36, cy, cy + 0.36):
		hw = math.sqrt(max(0.0, (ri + 0.045) ** 2 - (y - cy) ** 2))  # (round 3: each end lies 4 cm on the rim, riveted; never past its outer edge)
		S.hewn((-hw, y, 0.068), (hw, y + J(0.006), 0.068), 0.032)
		for sx in (-1, 1):
			kit.rivet(K.G((sx * (hw - 0.025), y, 0.102)), T("iron", "dark"), r=0.012)
		for x in (-0.48, -0.24, 0.0, 0.24, 0.48):
			if abs(x) < hw - 0.03:
				kit.rivet(K.G((x, y, 0.102)), T("iron", "dark"), r=0.012)
	hw0 = math.sqrt(max(0.0, r * r - cy * cy)) - 0.03  # the flat bottom bar on the floor, between the rim's two ends
	S.hewn((-hw0, E + 0.04, 0.035), (hw0, E + 0.04, 0.035), 0.04)


LEVER_PIVOT = (0.0, 1.05, 0.13)  # where the handle turns (x across, y up, z out of the wall), for the game and the page


def lever():
	"""A wall lever: a thick board pinned to the wall, a hewn bracket with an iron pin through it, and a long handle
	with a round wooden knob, leaning up (off). Parts: "base" (stays) and "handle" (turns about LEVER_PIVOT)."""
	before = meshes()
	S.rough_vboard(-0.17, 0.17, 0.72, 1.38, 0.03, 0.06)  # the board on the wall
	for y in (0.8, 1.3):
		S.peg(0.0, y, 0.06, "z")
	px, py, pz = LEVER_PIVOT
	for sx in (-1, 1):  # two cheek blocks either side of the handle
		K.blk((sx * 0.07, py, 0.1), (0.05, 0.16, 0.08), T("wood", "dark"), bevel=0.01)
	kit.cylinder(0.016, 0.2, K.G((0, py, pz)), T("iron", "dark"), rot=(0, 90, 0), verts=10, bevel=0.002)  # the pin
	base = meshes() - before
	before = meshes()
	a = math.radians(30)  # leaning up and out from the wall (off)
	tip = (0.0, py + 0.6 * math.cos(a), pz + 0.6 * math.sin(a))
	S.hewn((0.0, py - 0.06, pz - 0.0), tip, 0.03)
	S.boulder(tip, 0.055, 0.055, 0.055, m=T("wood"))  # the knob
	bpy.data.objects[(meshes() - before - {n for n in meshes() if bpy.data.objects[n].get("role") == "log"}).pop()]["role"] = "knob"
	handle = meshes() - before
	return {"base": base, "handle": handle}


def railing_broken(w=2.0, h=1.0):
	"""The ledge's railing, broken (owner: "drop down a ledge" back into the entrance room): the Shack railing with
	its middle post snapped off, the top rail broken in two (one half hanging down), pickets gone in the gap."""
	for x in (-w / 2 + 0.072, w / 2 - 0.072):
		S.hewn((x, 0.02, 0.0), (x + J(0.006), h - 0.052, J(0.004)), 0.056)
	S.hewn((0.0, 0.02, 0.0), (J(0.01), 0.42, 0.0), 0.056)  # the middle post, snapped
	S.hewn((-w / 2 + 0.03, h - 0.075, 0.0), (-0.12, h - 0.09, 0.0), 0.044)  # left half of the top rail
	S.hewn((w / 2 - 0.03, h - 0.075, 0.0), (0.22, h - 0.5, 0.02), 0.044)    # right half, hanging off its post
	S.hewn((-w / 2 + 0.08, 0.14, 0.0), (w / 2 - 0.08, 0.14 + J(0.008), 0.0), 0.045)
	n = 6
	for half in (-1, 1):
		a0, a1 = (-w / 2 + 0.14, -0.07) if half < 0 else (0.07, w / 2 - 0.14)
		for i in range(n):
			xc = a0 + (a1 - a0) * (i + 0.5) / n + J(0.01)
			bw = K.rng.uniform(0.07, 0.1)
			if half < 0 and i >= 4 or half > 0 and i <= 1:
				continue  # gone: the gap you drop through
			if half > 0:  # under the hanging rail: snapped short below it
				top = h - 0.5 + (xc - 0.22) / (w / 2 - 0.25) * 0.42 - 0.08
				S.rough_vboard(xc - bw / 2, xc + bw / 2, 0.12, min(h - 0.09, top), J(0.004), 0.032, broken_top=True)
			else:
				S.rough_vboard(xc - bw / 2, xc + bw / 2, 0.12, h - 0.09 + J(0.01), J(0.004), 0.032, broken_top=(i == 3))
	S.peg(-w / 2 + 0.072, h - 0.075 + 0.05 * 0.82, J(0.006), "y")


# ---------------------------------------------------------------- batch 5
import bmesh  # noqa: E402
from mathutils import Vector  # noqa: E402


def vprism(pts, z, d, m=None, role="board"):
	"""An upright board of any outline (x, y points), d thick, centred on z: for split, holed and patched boards."""
	n = len(pts)
	front = [z + d / 2 + J(0.003) for _ in pts]
	verts = [(x, y, z - d / 2) for x, y in pts] + [(x, y, f) for (x, y), f in zip(pts, front)]
	faces = [tuple(range(n)), tuple(range(n, 2 * n))] + [(i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n)]
	o = S._flat(K.mesh(verts, faces, m or T("wood")))
	o["role"] = role
	return o


def jag(x0, x1, y, amp, n=4):
	"""A jagged broken edge from x0 to x1 around height y (n teeth)."""
	return [(x0 + (x1 - x0) * k / n, y + (K.rng.uniform(-amp, amp) if 0 < k < n else K.rng.uniform(-amp, amp) * 0.4)) for k in range(n + 1)]


def crack_line(y0, y1, x, amp=0.025, n=7):
	"""A crack running up a board from y0 to y1, wandering around x."""
	return [(x + (K.rng.uniform(-amp, amp) if 0 < k < n else K.rng.uniform(-amp, amp) * 0.5), y0 + (y1 - y0) * k / n) for k in range(n + 1)]


def split_board(a, b, y0, y1, z, d, line, gap):
	"""One board split in two along `line` (bottom to top), with a dark gap `gap` wide between the halves."""
	left = [(a, y0)] + [(x - gap / 2, y) for x, y in line] + [(a, y1)]
	right = [(b, y0), (b, y1)] + [(x + gap / 2, y) for x, y in reversed(line)]
	return [vprism(left, z, d), vprism(right, z, d)]


def wall_frame3(w=2.0, h=2.0, sag=0.0):
	"""The Shack wall_v3 frame: two hewn posts, the sill beam and the top beam (sag: the old wall's top beam droops)."""
	px = w / 2 - 0.006 - 0.145
	for s_ in (-1, 1):
		S.hewn((s_ * px, 0.012, 0.0), (s_ * px + J(0.008), h - 0.05, J(0.006)), 0.14)
	S.hewn((-px, 0.115, 0.0), (px, 0.115 + J(0.008), 0.0), 0.1)
	S.hewn((-px, S.TOP_BEAM - sag, 0.0), (px, S.TOP_BEAM - sag * 0.4, 0.0), 0.12)
	return px


def wall_cracked(w=2.0, h=2.0):
	"""The cracked wall in front of the hidden vault (map 1): a Shack wall whose boards are split top to bottom,
	one with a jagged hole broken out of it (you see the dark room behind), splinters on the floor in front: the clue.
	Parts: "frame" (posts and beams, can't break) and board0, board1... (the pieces the pickaxe/club knocks out)."""
	px = wall_frame3(w, h)
	x0, x1 = -px + 0.13, px - 0.13
	y0, y1 = 0.17, S.TOP_BEAM - 0.08
	widths = [0.36, 0.42, 0.33]
	widths.append((x1 - x0) - sum(widths))
	gaps = [0.014, 0.02, 0.016]
	x = x0
	for i, bw in enumerate(widths):
		a = x + (gaps[i - 1] / 2 if i else 0.0)
		b = x + bw - (gaps[i] / 2 if i < len(gaps) else 0.0)
		z = J(0.006)
		if i == 0:    # split right up the middle
			split_board(a, b, y0, y1, z, 0.07, crack_line(y0, y1, (a + b) / 2), 0.022)
		elif i == 1:  # the hole: a lower piece with a jagged broken top, an upper piece with a jagged broken bottom
			lo = jag(a, b, 0.82, 0.07)
			hi = jag(a, b, 1.3, 0.07)
			vprism([(a, y0), (b, y0)] + list(reversed(lo)), z, 0.07)
			vprism([(a, y1)] + hi + [(b, y1)], z, 0.07)
		elif i == 2:  # a slanting crack, and its top corner broken off
			line = [((a + b) / 2 + (yy - (y0 + y1) / 2) * 0.12 + xx, yy) for xx, yy in crack_line(y0, y1, 0.0, 0.02)]
			split_board(a, b, y0, y1, z, 0.07, line, 0.018)
		else:         # whole, but cracked part way at the bottom (a dark split from the floor up)
			m = (a + b) / 2 + J(0.02)
			top = 0.95
			vprism([(a, y0), (m - 0.012, y0)] + [(m - 0.012 + J(0.008), y0 + (top - y0) * k / 4) for k in (1, 2, 3)] + [(m, top)]
				+ [(m + 0.012 + J(0.008), y0 + (top - y0) * k / 4) for k in (3, 2, 1)] + [(m + 0.012, y0), (b, y0), (b, y1), (a, y1)], z, 0.07)
		x += bw
	# pegs: one into the sill and one into the top beam for every piece wide enough to hold one
	for o in [o for o in bpy.data.objects if o.type == "MESH" and o.get("role") == "board"]:
		vs = [(v.co.x, v.co.z, -v.co.y) for v in o.data.vertices]  # Blender -> game axes
		xa, xb = min(v[0] for v in vs), max(v[0] for v in vs)
		ya, yb = min(v[1] for v in vs), max(v[1] for v in vs)
		if xb - xa < 0.1:
			continue
		if ya < 0.2:
			S.pegs_on((xa + xb) / 2 + J(0.02), 0.115, 0.093)
		if yb > 1.7:
			S.pegs_on((xa + xb) / 2 + J(0.02), S.TOP_BEAM, 0.112)
	# splinters lying on the floor in front of the hole (fresh: someone was here)
	for k in range(4):
		cx, cz = -0.25 + 0.17 * k + J(0.04), 0.16 + K.rng.uniform(0.0, 0.18)
		ln = K.rng.uniform(0.1, 0.22)
		S.rough_board(cx - ln / 2, cx + ln / 2, cz - 0.022, cz + 0.022, 0.0, 0.022, chips=0)
	return board_groups()


def wall_old(w=2.0, h=2.0):
	"""An old root wood wall (the dungeon was lived in long ago): the top beam sags, wider gaps between the boards,
	one board rotted away at the bottom, broken tops, a split, a patch board pegged across two boards, darker and
	greyer paint (age_paint)."""
	px = wall_frame3(w, h, sag=0.025)
	x0, x1 = -px + 0.13, px - 0.13
	y0, y1 = 0.17, S.TOP_BEAM - 0.11
	widths = [0.3, 0.37, 0.28, 0.33]
	widths.append((x1 - x0) - sum(widths))
	gaps = [0.03, 0.022, 0.04, 0.026]
	x = x0
	for i, bw in enumerate(widths):
		a = x + (gaps[i - 1] / 2 if i else 0.0)
		b = x + bw - (gaps[i] / 2 if i < len(gaps) else 0.0)
		z = J(0.008)
		if i == 1:    # rotted away at the bottom: a jagged rotten end well above the sill
			bot = jag(a, b, 0.5, 0.06, 5)
			vprism(bot + [(b, y1), (a, y1)], z, 0.07)
		elif i == 3:  # split up the middle, the right half's top broken off lower
			line = crack_line(y0, y1, (a + b) / 2 + J(0.02), 0.02)
			vprism([(a, y0)] + [(xx - 0.012, yy) for xx, yy in line] + [(a, y1)], z, 0.07)
			lr = [(xx + 0.012, yy) for xx, yy in line if yy < 1.42]
			vprism(lr + jag(lr[-1][0], b, 1.45, 0.05, 3)[1:] + [(b, y0)], z, 0.07)
		else:
			S.rough_vboard(a, b, y0, y1 + J(0.02), z, 0.07, broken_top=(i in (0, 4)), knot=(1, 1.1, 0.08) if i == 2 else None)
		if i != 1 and K.rng.random() < 0.75:  # some pegs fell out long ago
			S.pegs_on((a + b) / 2 + J(0.03), 0.115, 0.093)
		if K.rng.random() < 0.7:
			S.pegs_on((a + b) / 2 + J(0.03), S.TOP_BEAM - 0.015, 0.112)
		x += bw
	# the patch: a short board pegged slanting across boards 1 and 2 (someone mended the rotten board once)
	xa, xb, ya, yb, hw = x0 + 0.2, x0 + 0.95, 0.62, 0.9, 0.06
	dx, dy = xb - xa, yb - ya
	L = math.hypot(dx, dy)
	nx, ny = -dy / L * hw, dx / L * hw
	pts = [(xa - nx, ya - ny), (xb - nx + J(0.01), yb - ny), (xb + nx, yb + ny + J(0.01)), (xa + nx + J(0.01), ya + ny)]
	vprism(pts, 0.052, 0.03)
	for t in (0.18, 0.82):
		S.peg(xa + dx * t, ya + dy * t, 0.06, "z")


def floor_old(w=2.0, dd=2.0, t=0.25):
	"""An old root wood floor: worn boards with wide gaps, broken ends that show the joist below, one board cracked
	across, notches, some pegs gone. Same heights and outline as the Shack floor, so it lines up with it."""
	zs = (-dd / 2 + 0.3, 0.0, dd / 2 - 0.3)
	for z in zs:
		S.hewn((-w / 2 + 0.165, 0.088, z + J(0.01)), (w / 2 - 0.165, 0.088 + J(0.004), z + J(0.01)), 0.07)
	S.rim_beams([(-w / 2, -dd / 2), (w / 2, -dd / 2), (w / 2, dd / 2), (-w / 2, dd / 2)])
	y0, y1 = 0.148, t - 0.015
	x, x1 = -w / 2 + 0.012, w / 2 - 0.012
	z0, z1 = -dd / 2 + 0.006, dd / 2 - 0.006
	i = 0
	while x < x1 - 0.05:
		bw = min(K.rng.uniform(0.28, 0.42), x1 - x)
		if x1 - (x + bw) < 0.16:
			bw = x1 - x
		a = x + (K.rng.uniform(0.012, 0.03) if i else 0.0)  # (wide old gaps)
		b = x + bw - (K.rng.uniform(0.012, 0.03) if x + bw < x1 - 0.01 else 0.0)
		warp = J(0.012)
		if i == 1:    # cracked right across, the two halves sunk a little differently
			c = K.rng.uniform(-0.3, 0.3)
			S.rough_board(a, b, z0, c - 0.012, y0, y1, broken="front", warp=warp)
			S.rough_board(a, b, c + 0.012, z1, y0 - 0.006, y1 - 0.006, broken="back", warp=-warp)
		elif i == 3:  # the front end broken off short: you see the joist under it
			S.rough_board(a, b, z0, z1 - 0.2, y0, y1, broken="front", warp=warp)
		elif i == 4:  # a big bite worn out of one edge
			S.rough_board(a, b, z0, z1, y0, y1, notch=(-1, -0.4, 0.13), warp=warp)
		else:
			S.rough_board(a, b, z0, z1, y0, y1 - abs(J(0.008)), warp=warp, broken="back" if i == 0 else None)
		for zz in zs:
			if K.rng.random() < 0.7 and not (i == 3 and zz > 0.5):
				S.peg((a + b) / 2 + J(0.04), y1 - 0.026, zz + J(0.015), "y")
		x += bw
		i += 1


def chisel_slab(cx, cz, sx, sz, y0, y1, tilt=(0.0, 0.0), ch=0.025):
	"""A flat stone cut with a chisel: an uneven outline with chipped corners, straight sides, a chamfer all round
	the top (flat cut faces, no round edges). tilt = (rise along x, rise along z) in metres across the stone."""
	n_pts = []
	corners = [(-1, -1), (1, -1), (1, 1), (-1, 1)]
	for k, (ux, uz) in enumerate(corners):
		nxt = corners[(k + 1) % 4]
		cut = K.rng.uniform(0.03, 0.07)
		p = (ux * sx / 2, uz * sz / 2)
		q = (nxt[0] * sx / 2, nxt[1] * sz / 2)
		d = ((q[0] - p[0]), (q[1] - p[1]))
		L = math.hypot(*d)
		e = (d[0] / L, d[1] / L)
		n_pts.append((p[0] + e[0] * cut, p[1] + e[1] * cut))
		mid = (p[0] + d[0] * 0.5 + J(0.015), p[1] + d[1] * 0.5 + J(0.015))
		n_pts.append(mid)
		n_pts.append((q[0] - e[0] * cut, q[1] - e[1] * cut))
	n = len(n_pts)
	h = lambda x, z: (x / sx) * tilt[0] + (z / sz) * tilt[1]
	bot = [(cx + x, y0 + h(x, z), cz + z) for x, z in n_pts]
	mid = [(cx + x, y1 - ch + h(x, z) + J(0.004), cz + z) for x, z in n_pts]
	sh = [(x * (1 - 2 * ch / sx), z * (1 - 2 * ch / sz)) for x, z in n_pts]
	top = [(cx + x, y1 + h(x, z) + J(0.005), cz + z) for x, z in sh]
	verts = bot + mid + top
	faces = [tuple(reversed(range(n))), tuple(range(2 * n, 3 * n))]
	faces += [(i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n)]
	faces += [(n + i, n + (i + 1) % n, 2 * n + (i + 1) % n, 2 * n + i) for i in range(n)]
	o = S._flat(K.mesh(verts, faces, T("shackstone")))
	o["role"] = "stone"
	return o


def floor_loose_stone(w=2.0, dd=2.0, t=0.25):
	"""The buried chest's hiding place: a Shack floor with a big chisel-cut flagstone set in it, framed by board
	ends. The stone is loose: one corner sits a finger high and there's a dark gap all round (the clue). Parts:
	"frame" (floor, stays) and "stone" (lifts off; the chest is under it)."""
	zs = (-dd / 2 + 0.3, 0.0, dd / 2 - 0.3)
	for z in zs:
		S.hewn((-w / 2 + 0.165, 0.088, z + J(0.01)), (w / 2 - 0.165, 0.088 + J(0.004), z + J(0.01)), 0.07)
	S.rim_beams([(-w / 2, -dd / 2), (w / 2, -dd / 2), (w / 2, dd / 2), (-w / 2, dd / 2)])
	y0, y1 = 0.148, t - 0.015
	hz = 0.4   # the opening runs from -hz to hz along z; across, it lines up with the board edges
	x, x1 = -w / 2 + 0.012, w / 2 - 0.012
	edges = []
	while x < x1 - 0.05:
		bw = min(K.rng.uniform(0.3, 0.45), x1 - x)
		if x1 - (x + bw) < 0.16:
			bw = x1 - x
		a = x + (K.rng.uniform(0.006, 0.015) if edges else 0.0)
		b = x + bw - (K.rng.uniform(0.006, 0.015) if x + bw < x1 - 0.01 else 0.0)
		edges.append((a, b))
		x += bw
	cut = [(a, b) for a, b in edges if abs((a + b) / 2) < 0.45]
	hx0, hx1 = min(a for a, b in cut), max(b for a, b in cut)
	for a, b in edges:
		if (a, b) not in cut:
			S.rough_board(a, b, -dd / 2 + 0.006, dd / 2 - 0.006, y0, y1, warp=J(0.008))
			pz = zs
		else:  # the board stops either side of the stone
			S.rough_board(a, b, hz, dd / 2 - 0.006, y0, y1, warp=J(0.006), chips=0)
			S.rough_board(a, b, -dd / 2 + 0.006, -hz, y0, y1, warp=J(0.006), chips=0)
			pz = (zs[0], zs[2])
		for zz in pz:
			S.peg((a + b) / 2 + J(0.04), y1 - 0.026, zz + J(0.015), "y")
	frame = meshes()
	# the stone rests on the middle joist (its top is at 0.158); one corner rocked up a finger high
	# (round 2: a wider dark gap and a higher corner, it didn't look loose)
	stone = chisel_slab((hx0 + hx1) / 2, 0.0, hx1 - hx0 - 0.09, 2 * hz - 0.09, 0.156, y1 + 0.006, tilt=(0.05, 0.035))
	groups = {"frame": set(frame), "stone": {stone.name}}
	return groups


# ---------------------------------------------------------------- batch 6
def rot_x(objs, theta, pivot):
	"""Turn finished parts about the game's x axis through `pivot` (game coords): + tips the top toward the front."""
	from mathutils import Matrix
	px, py, pz = pivot
	piv = Vector(K.G((px, py, pz)))
	m = Matrix.Rotation(theta, 4, "X")  # game +x rotation (top toward +z) = Blender +x rotation (round 2: the sign was flipped)
	for o in objs:
		o.data.transform(o.matrix_basis)  # (pegs are placed by position, not by their points: bake that in first)
		o.matrix_basis = Matrix.Identity(4)
		for v in o.data.vertices:
			v.co = piv + (m @ (v.co - piv))


def wall_broken(w=2.0, h=2.0):
	"""A Shack wall that fell down long ago (decor): the left post stands, the right one snapped off, the top beam
	lying on the floor in front, board stubs broken off at different heights, loose boards lying about."""
	px = w / 2 - 0.006 - 0.145
	S.hewn((-px, 0.012, 0.0), (-px + J(0.008), h - 0.05, J(0.006)), 0.14)
	S.hewn((px, 0.012, 0.0), (px + J(0.01), 1.05, J(0.006)), 0.14)        # snapped
	S.hewn((-px, 0.115, 0.0), (px, 0.115 + J(0.008), 0.0), 0.1)            # the sill stays
	x0, x1 = -px + 0.13, px - 0.13
	tops = [1.55, 1.0, 0.5]                                                 # the fourth board is gone
	widths = [0.36, 0.42, 0.33]
	x = x0
	for i, (bw, top) in enumerate(zip(widths, tops)):
		a, b = x + (0.008 if i else 0.0), x + bw - 0.008
		S.rough_vboard(a, b, 0.17, top + J(0.04), J(0.008), 0.07, broken_top=True)
		S.pegs_on((a + b) / 2 + J(0.03), 0.115, 0.093)
		x += bw
	S.hewn((-0.62, 0.12, 0.5), (0.72, 0.12 + J(0.004), 0.6), 0.12)           # the top beam, fallen, lying on the floor
	S.rough_board(-0.75, -0.42, 0.74, 0.96, 0.0, 0.07, broken="front", chips=1)  # loose boards on the floor
	S.rough_board(-0.3, 0.42, 0.8, 0.98, 0.0, 0.07, broken="back", chips=1)
	S.rough_board(0.12, 0.8, 0.18, 0.35, 0.0, 0.07, broken="front", chips=1)


STAND_TILT = math.radians(20)
STAND_PIVOT = (0.0, 1.01, -0.11)
STAND_DY = -0.11  # everything above the bottom foot log moves down this much (into that log)


def recipe_stand():
	"""Where a dungeon's prize recipe lies (the loot room): a root wood lectern. Two crossed hewn logs as its foot
	(stacked, notched), a hewn post, a head block, and a slanted top of two split boards with a lip at the front so
	the scroll can't slide off. The scroll is its own model (recipe_scroll), laid on the top at RECIPE_SPOT."""
	S.hewn((-0.34, 0.065, J(0.01)), (0.34, 0.065, J(0.01)), 0.065)
	foot = meshes()
	S.hewn((J(0.01), 0.175, -0.3), (J(0.01), 0.175, 0.3), 0.06)       # crossed, resting in a notch on the first
	S.hewn((0.0, 0.2, 0.0), (J(0.01), 0.95, J(0.01)), 0.075)
	before = meshes()  # (the head block tilts with the top: flat, it poked up through the boards)
	K.blk((0.0, 0.97, -0.02), (0.3, 0.08, 0.2), T("wood", "dark"), bevel=0.012)
	S.rough_board(-0.3, -0.006, -0.21, 0.21, 1.01, 1.05, warp=J(0.004))
	S.rough_board(0.006, 0.3, -0.21, 0.21, 1.01, 1.05, warp=J(0.004))
	S.rough_board(-0.29, 0.29, 0.18, 0.215, 1.044, 1.08, chips=0)          # the lip
	for x in (-0.15, 0.15):
		S.peg(x + J(0.01), 1.05 - 0.026, -0.12, "y")
	top = [bpy.data.objects[n] for n in meshes() - before]
	rot_x(top, STAND_TILT, STAND_PIVOT)
	# where the scroll lies: the middle of the top surface, turned with it
	py, pz = 1.05 - STAND_PIVOT[1], 0.0 - STAND_PIVOT[2]
	spot = (0.0, STAND_PIVOT[1] + py * math.cos(STAND_TILT) - pz * math.sin(STAND_TILT),
		STAND_PIVOT[2] + py * math.sin(STAND_TILT) + pz * math.cos(STAND_TILT))
	# (owner, Nov 19: the two foot logs stood one on top of the other: the whole stand is pushed down into the
	# bottom log, so the crossing log sits sunk in it, level with it)
	for nm in meshes() - foot:
		o = bpy.data.objects[nm]
		o.data.transform(o.matrix_basis)
		o.matrix_basis.identity()
		for v in o.data.vertices:
			v.co.z += STAND_DY  # (Blender z = game up)
	spot = (spot[0], spot[1] + STAND_DY, spot[2])
	print(f"RECIPE_SPOT {spot[0]:.3f} {spot[1]:.3f} {spot[2]:.3f} tilt {math.degrees(STAND_TILT):.0f}")


def parchment():
	"""Old parchment, painted by the script: warm yellow-brown, blotchy stains, darker speckles (packed in the model)."""
	import numpy as np
	n = 256
	rs = np.random.default_rng(7)
	yy, xx = np.mgrid[0:n, 0:n] / n
	blot = np.zeros((n, n))
	for k in range(14):  # soft stains, tiling (built from sines of whole periods)
		fx, fy = rs.integers(1, 5, 2)
		blot += np.sin(2 * np.pi * (fx * xx + rs.random())) * np.sin(2 * np.pi * (fy * yy + rs.random())) / (fx + fy)
	blot = (blot - blot.min()) / (blot.max() - blot.min())
	speck = (rs.random((n, n)) > 0.985) * rs.random((n, n)) * 0.25
	base = np.array([0.8, 0.66, 0.42])
	dark = np.array([0.55, 0.4, 0.22])
	col = base[None, None, :] * (1 - blot[..., None] * 0.45) + dark[None, None, :] * (blot[..., None] * 0.45)
	col = np.clip(col * (1 - speck[..., None]), 0, 1)
	img = bpy.data.images.new("parchment", n, n)
	px = np.ones((n, n, 4), dtype=np.float32)
	px[..., :3] = col ** 2.2  # (colours above are by eye: turn them into the image's linear light)
	img.pixels.foreach_set(px.ravel())
	img.pack()
	m = bpy.data.materials.new("parchment")
	m.use_nodes = True
	b = m.node_tree.nodes["Principled BSDF"]
	b.inputs["Roughness"].default_value = 0.85
	t = m.node_tree.nodes.new("ShaderNodeTexImage")
	t.image = img
	m.node_tree.links.new(t.outputs["Color"], b.inputs["Base Color"])
	return m


def recipe_scroll():
	"""The dungeon's prize: a recipe scroll, half unrolled between two rolls on wooden rods with knobs, a red wax
	seal, and lines of glowing ink (the part "glow_ink": its material starts with glow_, so the game lights and
	tints it). Origin: the middle of its underside (it lies on the recipe stand or a chest). 0.36 m long."""
	w, d, r = 0.26, 0.2, 0.028
	paper = parchment()  # (round 2: plain linen looked like white plastic)
	nx = 12
	top, bot = [], []
	for i in range(nx + 1):  # the sheet: flat in the middle, curling up into the two rolls
		x = -w / 2 + w * i / nx
		e = max(0.0, abs(x) / (w / 2) - 0.7) / 0.3
		y = 0.003 + (r * 1.2) * e * e
		top.append((x, y + 0.004))
		bot.append((x, y))
	verts, faces = [], []
	for z in (-d / 2, d / 2):
		verts += [(x, y, z) for x, y in top] + [(x, y, z) for x, y in bot]
	n = nx + 1
	for i in range(nx):
		a, b = i, i + 1
		faces.append((a, b, 2 * n + b, 2 * n + a))                  # top
		faces.append((n + b, n + a, 3 * n + a, 3 * n + b))          # bottom
		faces.append((a, n + a, n + b, b))                          # back edge
		faces.append((2 * n + a, 2 * n + b, 3 * n + b, 3 * n + a))  # front edge
	faces.append((0, 2 * n, 3 * n, n))
	faces.append((nx, n + nx, 3 * n + nx, 2 * n + nx))
	K.mesh(verts, faces, paper)
	rod = T("wood", "dark")
	for sx in (-1, 1):
		cx = sx * (w / 2 + r * 0.55)
		K.log((cx, r, -d / 2 - 0.004), (cx, r, d / 2 + 0.004), r, paper, seg=14, rings=2, ends=True, bend=0.0)
		K.log((cx, r, -d / 2 - 0.035), (cx, r, d / 2 + 0.035), 0.008, rod, seg=8, rings=1, ends=True, bend=0.0)
		for sz in (-1, 1):
			S.boulder((cx, r, sz * (d / 2 + 0.045)), 0.016, 0.016, 0.016, m=rod, floor=r - 0.02)
	for o in [o for o in bpy.data.objects if o.type == "MESH" and paper.name in [m.name for m in o.data.materials]]:
		kit._uv_box(o, 0.3)
	kit.cylinder(0.026, 0.008, K.G((0.07, 0.009, 0.055)), kit.mat("target_red", -0.2), rot=(0, 0, 0), verts=12, bevel=0.002)  # wax seal
	glow = kit.mat("fire_core", glow=4.0)  # (round 2: golden ink, the cyan read as white)
	glow.name = "glow_ink"
	ys = 0.0066
	for k, (x0, x1) in enumerate([(-0.08, 0.08), (-0.09, 0.06), (-0.09, 0.09), (-0.09, 0.03), (-0.09, 0.07)]):
		z = -0.065 + k * 0.026
		K.blk(((x0 + x1) / 2, ys, z), (x1 - x0, 0.004, 0.007), glow, bevel=0.0)
	for k in range(3):  # a little drawing: three short strokes like a rune
		K.blk((-0.04 + k * 0.012, ys, 0.072), (0.004, 0.004, 0.03), glow, bevel=0.0, ry=0.4 * (k - 1))


def bridge_posts():
	"""Where the plank bridge starts (one at each end of the chasm): two hewn posts on chisel-cut stone footings
	with the hand ropes lashed round them, two low stakes holding the stringer ropes, and the first three planks.
	The bridge sections join on at z = +1 (the ropes line up: stringers x = +-0.5, hand ropes x = +-0.64, 0.95 m)."""
	L = 0.994
	rp = 0.09
	for sx in (-1, 1):
		x = sx * 0.64
		chisel_slab(x, -0.05, 0.36, 0.34, 0.0, 0.12)
		S.hewn((x, 0.1, -0.05), (x + J(0.008), 1.25, -0.05 + J(0.008)), rp)
		rope((x, 0.95, -0.05 + rp * 0.6), (x, 0.95, L), 0.028)            # hand rope, from the post to the bridge
		for k in range(3):                                                  # lashed round the post
			kit.ring(rp * 0.97, 0.014, K.G((x, 0.91 + k * 0.03, -0.05)), kit.tex_mat("rope"), rot=(0, 0, 0), seg=16)
		xs = sx * 0.5
		S.hewn((xs, 0.0, -0.32), (xs + J(0.01), 0.36, -0.36), 0.05, stub=False)  # the stake, leaning back
		rope((xs, 0.06, -0.3), (xs, 0.04, L), 0.035)                        # stringer
		for k in range(2):
			kit.ring(0.052, 0.012, K.G((xs, 0.1 + k * 0.03, -0.325)), kit.tex_mat("rope"), rot=(0, 0, 0), seg=14)
	z = L - 0.01
	for k in range(3):
		w_ = K.rng.uniform(0.2, 0.23)
		S.board_x(-0.66 + J(0.02), 0.66 + J(0.02), z - w_, z, 0.058, 0.108, chips=2)
		z -= w_ + K.rng.uniform(0.025, 0.035)


def age_paint(amount=0.55):  # (round 2: 0.35 didn't read next to new wood)
	"""Old wood: every painted texture on the model gets a darker, greyer copy (a little green in the dark grain),
	so old walls and floors look weathered next to new ones. The copies are packed into the model file."""
	import numpy as np
	done = {}
	for o in [o for o in bpy.data.objects if o.type == "MESH"]:
		for slot in o.material_slots:
			m = slot.material
			if not m or not m.use_nodes:
				continue
			if m.name in done:
				slot.material = done[m.name]
				continue
			tex = [nd for nd in m.node_tree.nodes if nd.type == "TEX_IMAGE" and nd.image]
			if not tex:
				done[m.name] = m
				continue
			m2 = m.copy()
			m2.name = m.name + "_old"
			img = tex[0].image
			im2 = img.copy()
			im2.name = img.name + "_old"
			px = np.array(im2.pixels[:], dtype=np.float32).reshape(-1, 4)
			lum = px[:, :3] @ np.array([0.3, 0.59, 0.11], dtype=np.float32)
			grey = np.stack([lum * 0.95, lum * 0.97, lum * 0.9], axis=1)
			rgb = px[:, :3] * (1 - amount) + grey * amount
			rgb *= 1 - amount * 0.45
			dark = np.clip(1 - lum / 0.25, 0, 1)[:, None]
			rgb = rgb + dark * amount * 0.08 * np.array([-0.3, 0.4, -0.2], dtype=np.float32)
			px[:, :3] = np.clip(rgb, 0, 1)
			im2.pixels.foreach_set(px.ravel())
			im2.pack()
			for nd in m2.node_tree.nodes:
				if nd.type == "TEX_IMAGE" and nd.image == img:
					nd.image = im2
			done[m.name] = m2
			slot.material = m2


# ---------------------------------------------------------------- save
def save_parts(name, groups=None):
	"""Apply modifiers, join each group into one named part (or everything into "model"), export .glb."""
	objs = [o for o in bpy.data.objects if o.type == "MESH"]
	for o in objs:
		bpy.ops.object.select_all(action="DESELECT")
		o.select_set(True)
		bpy.context.view_layer.objects.active = o
		for m in list(o.modifiers):
			bpy.ops.object.modifier_apply(modifier=m.name)
	if not groups:
		groups = {"model": {o.name for o in objs}}
	parts = []
	for part, names in groups.items():
		members = [bpy.data.objects[n] for n in names if n in bpy.data.objects]
		bpy.ops.object.select_all(action="DESELECT")
		for o in members:
			o.select_set(True)
		bpy.context.view_layer.objects.active = members[0]
		bpy.ops.object.join()
		ob = bpy.context.object
		ob.name = part
		parts.append(ob)
	for img in bpy.data.images:
		if img.size[0] > 512:
			img.scale(512, 512)
	bpy.ops.object.select_all(action="DESELECT")
	for o in parts:
		o.select_set(True)
	OUT.mkdir(parents=True, exist_ok=True)
	path = str(OUT / f"{name}.glb")
	bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_yup=True,
		export_image_format="JPEG", export_image_quality=85)
	import glb_jpeg_fix
	glb_jpeg_fix.fix(path)
	tris = sum(len(p.vertices) - 2 for o in parts for p in o.data.polygons)
	print(f"ROOT_DONE {name} {tris} triangles, parts {[o.name for o in parts]}")
	return parts


def pictures(name, parts):
	import cave_plants as cp
	cp.OUT = OUT
	cp.pictures(name, parts)


BUILDS = {"wall_broken": wall_broken, "recipe_stand": recipe_stand, "recipe_scroll": recipe_scroll, "bridge_posts": bridge_posts,
	"wall_cracked": wall_cracked, "wall_old": wall_old, "floor_old": floor_old,
	"floor_loose_stone": floor_loose_stone, "gate_round": gate_round, "lever": lever, "railing_broken": railing_broken,
	"bridge_plank": bridge, "bridge_plank_broken": lambda: bridge(True), "bridge_plank_gap": lambda: bridge(gap=True), "bridge_ropes": lambda: bridge(bare=True), "dungeon_entrance": entrance,
	"door_loot": loot_door, "chain_hanging": chain_hanging, "trap_dart_plate": dart_plate, "trap_dart_wall": dart_wall, "trap_floor_break": floor_break, "trap_crusher": crusher}

if __name__ == "__main__":
	for name, fn in BUILDS.items():
		if ONLY and name not in ONLY:
			continue
		K.rng.seed(sum(map(ord, name)))
		kit.reset()
		groups = fn()
		if GREY:
			S.make_grey()
		else:
			S.paint3()
			if name in ("wall_old", "floor_old"):
				age_paint()
		parts = save_parts(name, groups)
		pictures(name, parts)
