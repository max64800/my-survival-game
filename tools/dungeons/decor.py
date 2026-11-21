# Dungeon decor from the decor catalogue (docs/art/DECOR-CATALOG.md, owner Nov 22: "every single piece has its own
# place"). Unlike junk (random, along the walls), every decor piece is placed by hand in its room, in the spot the
# catalogue gives. This file only turns "back against the north wall, here" into a position and checks the owner's
# placement rules (the same ones as junk: tests/test_dungeon_decor.gd checks them in the game's plan):
#   its whole footprint inside its own room (nothing inside a wall, nothing in a doorway gap);
#   off the walk lines (doorway to doorway): its middle 1.2 m away, every corner 1.0 m (catalogue: "paths and doors 1 m");
#   its edge 2 m from a doorway's middle (the 1.5 m in front of it), 1.5 m from a chest, lever, door or recipe stand,
#   1.2 m from a trap; not on another piece, a column or a creature's spot (0.15 m apart).
# Models: origin bottom-centre, front +z (its back, flat for wall pieces, at -z). yaw like Godot (+yaw turns x to -z).
import math

import junk
from junk import size, corners, poly_dist, in_rect, cell_of, WALL_FACE, FLOOR_TOP

PATH_MID = 1.2
PATH_EDGE = 1.0
DOOR_EDGE = 2.0
THING_EDGE = 1.5
TRAP_EDGE = 1.2
GAP = 0.15
SIDE_YAW = {"n": 0.0, "s": 180.0, "w": 90.0, "e": 270.0}   # back against this wall of the room: front into the room
SIDE_IN = {"n": (0, 1), "s": (0, -1), "w": (1, 0), "e": (-1, 0)}


def _origin(model, cx, cz, yaw):
	"""The model's origin so that its footprint's middle is at (cx, cz)."""
	sx, sz, ox, oz = size(model)
	a = math.radians(yaw)
	return cx - (ox * math.cos(a) + oz * math.sin(a)), cz - (-ox * math.sin(a) + oz * math.cos(a))


def footprint(model, x, z, yaw):
	return corners(model, x, z, yaw)


def wall(model, side, line, along, out=0.0, turn=0.0):
	"""Back against the wall on `side` (n/s/w/e: which wall of the room) whose line is at `line` (z for n/s, x for
	w/e), its middle at `along` on that wall. `out`: extra distance from the wall face. Returns (x, z, yaw)."""
	sx, sz, ox, oz = size(model)
	yaw = SIDE_YAW[side] + turn
	nx, nz = SIDE_IN[side]
	depth = sz / 2 + WALL_FACE + out   # the footprint's middle this far out from the wall line
	cx, cz = (along, line + nz * depth) if side in "ns" else (line + nx * depth, along)
	x, z = _origin(model, cx, cz, yaw)
	return (x, z, yaw)


def corner(model, side, line, side2, line2, out=0.0):
	"""Back against wall `side`, pushed along it until it touches wall `side2` (a corner)."""
	sx, sz, ox, oz = size(model)
	n2x, n2z = SIDE_IN[side2]
	along = line2 + (n2x if side in "ns" else n2z) * (WALL_FACE + sx / 2)
	return wall(model, side, line, along, out)


def mid(model, cx, cz, yaw):
	"""Footprint's middle at (cx, cz), turned `yaw`."""
	x, z = _origin(model, cx, cz, yaw)
	return (x, z, yaw)


def rect_dist(cs, p):
	"""How far point p is from a footprint (0 inside it)."""
	sides = [(cs[(i + 1) % 4][0] - cs[i][0]) * (p[1] - cs[i][1]) - (cs[(i + 1) % 4][1] - cs[i][1]) * (p[0] - cs[i][0])
		for i in range(4)]
	if all(v >= 0 for v in sides) or all(v <= 0 for v in sides):
		return 0.0
	return min(junk.seg_dist(p, cs[i], cs[(i + 1) % 4]) for i in range(4))


def rects_dist(a, b):
	"""How far apart two footprints are (0 if they overlap)."""
	return min([rect_dist(b, c) for c in a] + [rect_dist(a, c) for c in b])


def check(items, cells, lines, doors, things, traps, obstacles, keep_off=()):
	"""items: [(model, x, z, yaw, room)]. Returns ([problem text], [(name, footprint corners)] of the placed pieces).
	obstacles: (x, z, radius) of things already on the floor (furniture, columns, creatures)."""
	probs, placed = [], []
	for model, x, z, yaw, room in items:
		cs = footprint(model, x, z, yaw)
		px, pz = sum(c[0] for c in cs) / 4, sum(c[1] for c in cs) / 4
		rad = max(math.hypot(c[0] - px, c[1] - pz) for c in cs)
		name = model.split("/")[-1][:-4]
		for c in cs + [(px, pz)]:
			if cells.get(cell_of(c[0], c[1])) != room:
				probs.append("%s: corner (%.2f, %.2f) is outside %s" % (name, c[0], c[1], room))
				break
			if any(in_rect(c, r) for r in keep_off):
				probs.append("%s: over a keep-off area at (%.2f, %.2f)" % (name, c[0], c[1]))
				break
		for line in lines.get(room, []):
			d = poly_dist((px, pz), line)
			e = min(poly_dist(c, line) for c in cs)
			if (d < PATH_MID or e < PATH_EDGE) and not any(q.startswith(name + ": on a walk") for q in probs):
				probs.append("%s: on a walk line %s (middle %.2f, edge %.2f)" % (name, [tuple(p) for p in (line[0], line[-1])], d, e))
		for (ox, oz) in doors:
			d = rect_dist(cs, (ox, oz))
			if d < DOOR_EDGE:
				probs.append("%s: %.2f m from the doorway at (%.1f, %.1f)" % (name, d, ox, oz))
		for (ox, oz) in things:
			d = rect_dist(cs, (ox, oz))
			if d < THING_EDGE:
				probs.append("%s: %.2f m from the chest/lever/stand at (%.1f, %.1f)" % (name, d, ox, oz))
		for (ox, oz) in traps:
			d = rect_dist(cs, (ox, oz))
			if d < TRAP_EDGE:
				probs.append("%s: %.2f m from the trap at (%.1f, %.1f)" % (name, d, ox, oz))
		for (ox, oz, r) in obstacles:
			d = rect_dist(cs, (ox, oz)) - r
			if d < GAP:
				probs.append("%s: touches something at (%.1f, %.1f) (gap %.2f)" % (name, ox, oz, d))
		for other, ocs in placed:
			d = rects_dist(cs, ocs)
			if d < GAP:
				probs.append("%s: touches %s (gap %.2f)" % (name, other, d))
		placed.append((name, cs))
	return probs, placed


def height(model):
	from glb_bounds import bounds
	return float(bounds(str(junk.ROOT / "assets/models" / model))[1][1])


def blocks_wall_spot(items, pos, reach=0.5, low=0.9):
	"""Does a decor piece taller than `low` stand within `reach` of this wall spot (a torch holder, a plaque)?"""
	for model, x, z, yaw, room in items:
		if height(model) > low and rect_dist(footprint(model, x, z, yaw), (pos[0], pos[2])) < reach:
			return True
	return False


def props(items, floor_y):
	"""Plan props (role "decor", `cat` = from the catalogue, `foot` = its footprint size for the test)."""
	out = []
	for model, x, z, yaw, room in items:
		sx, sz = size(model)[:2]
		cs = footprint(model, x, z, yaw)
		out.append({"model": model, "pos": [round(x, 3), round(floor_y(room) + FLOOR_TOP, 3), round(z, 3)],
			"yaw": round(yaw % 360.0, 1), "scale": 1.0, "role": "decor", "label": "", "cat": True,
			"foot": [round(sx, 2), round(sz, 2)],   # (its footprint's size and middle: the test needs no model)
			"mid": [round(sum(c[0] for c in cs) / 4, 3), round(sum(c[1] for c in cs) / 4, 3)]})
	return out
