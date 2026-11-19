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
#                     with dark iron nozzles inside (the clue: rows of holes)
#   trap_floor_break  a 2 x 2 m Shack floor gone rotten: cracked boards with jagged breaks, thin rotten joists, a
#                     sagging board (the clue). Same height as the normal floor, so it lines up with it. Parts:
#                     "frame" (beams, stay) and board0, board1... (each falls on its own)
#   chain_hanging     1.5 m of the crusher's iron chain under a ceiling plate (origin = the ceiling, chain hangs down)
#   trap_crusher      a cage of logs packed with stones hanging on two chains from a ceiling beam (3.6 m up).
#                     Two parts: "frame" (the beam and chains, stays) and "weight" (the cage, slams down)
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
	hole_r, depth = 0.038, 0.16  # (round 2: bigger, they looked like pegs)
	for k in range(5):
		x = -0.6 + 0.3 * k + J(0.02)
		front = beam_r  # the beam's front face is about here (hewn: flat faces); the cutter reaches past it
		bore(beam, K.G((x, beam_y, front)), hole_r, depth)
		noz = K.log((x, beam_y, front - 0.13), (x, beam_y, front - 0.035), hole_r - 0.006, T("iron", "dark"), seg=10, rings=1, ends=True, bend=0)
		noz["role"] = "iron"
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
		kit.ring(major, minor, K.G((x, y, z)), T("iron", "dark"), rot=rot, seg=14)
	return y_top - major - (n - 1) * step - major  # the lowest point of the chain


def crusher():
	beam_y, beam_r = 3.6, 0.14
	yb, yt = 1.6, 2.6            # the weight's bottom and top, raised (it slams down to the floor in the game)
	hx, hz = 0.9, 0.5
	frame0 = meshes()
	S.hewn((-0.99, beam_y, 0.0), (0.99, beam_y + J(0.006), 0.0), beam_r)  # sits into the corridor walls
	lift_y = yt + 0.06
	low = 0.0
	for x in (-0.45, 0.45):
		low = chain(x, 0.0, beam_y - beam_r + 0.05, lift_y + 0.035)  # (the hewn beams' flat faces sit inside r: the end links reach into them)
	frame = meshes() - frame0
	# the weight: a thick board bottom (the crushing face), four corner posts, rails, stones packed inside, lifting beams
	for i, (a, b) in enumerate([(-0.88, -0.53), (-0.52, -0.17), (-0.16, 0.19), (0.2, 0.54), (0.55, 0.88)]):
		S.rough_board(a, b, -hz + 0.02, hz - 0.02, yb, yb + 0.09, chips=2, broken="front" if i == 3 else None)
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


BUILDS = {"chain_hanging": chain_hanging, "trap_dart_plate": dart_plate, "trap_dart_wall": dart_wall, "trap_floor_break": floor_break, "trap_crusher": crusher}

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
		parts = save_parts(name, groups)
		pictures(name, parts)
