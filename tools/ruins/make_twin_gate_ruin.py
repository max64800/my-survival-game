# The RUINED Twin Gate (owner, Nov 21: ruin 6, the first GRAND ruin, docs/design/GRAND-RUIN-RECIPE.md).
#   godot --headless --audio-driver Dummy --path . -s res://tools/dump_blueprint.gd -- stonehold_twin_gate <stone.json>
#   godot --headless --audio-driver Dummy --path . -s res://tools/dump_blueprint.gd -- wooden_twin_gate <wood.json>
#   python tools/ruins/make_twin_gate_ruin.py <stone.json> [wood=<wood.json>] [page=<folder>]
# Writes blueprints/ruins/twin_gate_ruin.json (pieces, chests with loot, props, beetle spots) for the world to place.
# The new Stonehold trims (tools/asset_forge/builds/stonehold_v2_twin.py; game pieces and in the blueprint since Nov 22,
# BlueprintLibrary._twin_trims, which must stay the same as extras() here):
# brackets (corbel) under every floor that juts out, trim bands (cornice) at the floor lines with corner blocks,
# buttresses on the foundation buildings' walls, and a turret (bartizan) on every corner of both towers.
# What happened: the right tower cracked in half and its outer half fell outward (two big wall pieces and rubble lie
# past it); the gate room's right roof, the right barracks wing's roof and the kitchen's roof fell in; part of the left
# yard wall is down; the doors are gone and the outer gate's leaves were torn off (they lie past the grand steps).
# The left tower still stands and its fire still burns. The guards' things are still there (docs/art/DECOR-CATALOG.md,
# Hall of the Shieldbearers set and kitchen pieces), each checked against the junk rules (tools/ruins/ruin_junk.py).
# Coordinates: the blueprint's z is shifted +8 (BlueprintLibrary._twin_gate); this script works in the plan's own
# coordinates (z - 8) and shifts everything back when it writes.
import base64
import json
import math
import random
import struct
import sys
from pathlib import Path

GAME = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(GAME / "tools" / "ruins"))
sys.path.insert(0, str(GAME / "tools" / "dungeons"))
import ruin_junk as RJ                      # noqa: E402  (piece sizes, outlines, overlap)
from glb_bounds import bounds               # noqa: E402

args = sys.argv[1:]
bp = json.load(open(args[0], encoding="utf-8"))
page = next((Path(a[5:]) for a in args if a.startswith("page=")), None)
wood_bp = next((json.load(open(a[5:], encoding="utf-8")) for a in args if a.startswith("wood=")), None)
rng = random.Random(6)
ZS = 8.0                                    # the blueprint's z shift
TOWERS = (-11.0, 11.0)                      # the towers' middles (x), 10 x 10, walls on x +-5 and z +-5
NEW_MAT = "cut_stone"
# the new trims' sizes (for the checks; measured from their models)
RJ.PIECES.update({"corbel": {"size": [0.49, 1.0, 0.81], "group": ""},
	"cornice": {"size": [1.99, 0.39, 0.16], "group": ""}, "cornice_corner": {"size": [0.31, 0.39, 0.31], "group": ""},
	"buttress": {"size": [0.79, 2.84, 1.23], "group": ""}, "bartizan": {"size": [3.33, 2.99, 3.33], "group": ""},
	"battlement_narrow": {"size": [0.99, 0.88, 0.39], "group": ""}})
TRIMS = ("corbel", "cornice", "cornice_corner", "buttress", "bartizan", "battlement_narrow")
TURRET_SH = 0.32                            # the turret's middle sits this far in from the tower corner (both ways)


def rot_from(steps):
	k = steps % 12
	return k // 3 if k % 3 == 0 else 4 + k


def steps_of(rot):
	return rot * 3 if rot < 4 else rot - 4


def turned(rot):
	return rot_from(steps_of(rot) + 6)


OUT_ROT = {(0, 1): 0, (1, 0): 1, (0, -1): 2, (-1, 0): 3}   # +z of the piece points this way


def plan_of(b):
	return [{"id": p["id"], "mat": p["mat"], "pos": [round(p["pos"][0], 4), round(p["pos"][1], 4), round(p["pos"][2] - ZS, 4)],
		"rot": p["rot"]} for p in b["pieces"]]


# ---------------------------------------------------------------- the new trims (both plans)
WALLISH = ("wall", "window_wall", "window_wide", "doorway", "wall_narrow", "half_wall", "ruin_wall_worn", "ruin_wall_collapsed")


def extras():
	"""-> [(piece, hosts)]: hosts are (x, y, z) spots of the walls/floors it hangs on (it goes when one is gone)."""
	out = []

	def put(pid, x, y, z, rot, hosts):
		out.append(({"id": pid, "mat": NEW_MAT, "pos": [round(x, 4), round(y, 4), round(z, 4)], "rot": rot}, hosts))

	def band(axis, line, s, cells, y):
		"""Trim band on a face: axis "z" = a wall along x at z=line, facing s*z; "x" = along z at x=line."""
		below = 1.0 if y < 3 else 3.25
		for c in cells:
			if axis == "z":
				put("cornice", c, y, line + s * 0.245, OUT_ROT[(0, s)], [("wall", c, below, line)])
			else:
				put("cornice", line + s * 0.245, y, c, OUT_ROT[(s, 0)], [("wall", line, below, c)])

	def corner(x, z, sx, sz, y, hosts):
		put("cornice_corner", x + sx * 0.17, y, z + sz * 0.17, 0, hosts)

	# --- the towers: bands on the front, back and outer faces, corner blocks, buttresses, turrets
	for cx in TOWERS:
		o = 1 if cx > 0 else -1                      # the outer side
		xs = [cx + d for d in (-4, -2, 0, 2, 4)]
		for y in (2.95, 5.2):
			band("z", 5.0, 1, xs, y)
			band("z", -5.0, -1, [x for x in xs if not (y < 3 and abs(abs(x) - 13) < 0.1)], y)   # (the yard wall)
			band("x", cx + 5 * o, o, [-4, -2, 0, 2, 4], y)
			below = 1.0 if y < 3 else 3.25
			for sx in (-1, 1):
				for sz in (-1, 1):
					x, z = cx + 5 * sx, 5 * sz
					corner(x, z, sx, sz, y, [("wall", x - sx, below, z), ("wall", x, below, z - sz)])
		for j in (-3, -1, 1, 3):
			put("buttress", cx + j, 0.0, 5.626, 0, [("wall", cx + j - 1, 1.0, 5.0), ("wall", cx + j + 1, 1.0, 5.0)])
			put("buttress", cx + (5 + 0.626) * o, 0.0, j, OUT_ROT[(o, 0)],
				[("wall", cx + 5 * o, 1.0, j - 1), ("wall", cx + 5 * o, 1.0, j + 1)])
		for j in (-3, 3):
			put("buttress", cx + j, 0.0, -5.626, 2, [("wall", cx + j - 1, 1.0, -5.0), ("wall", cx + j + 1, 1.0, -5.0)])
		for sx in (-1, 1):
			for sz in (-1, 1):
				if sx == -o and sz == 1:
					continue                              # (the gate room's roof juts past this corner: no room)
				x, z = cx + 5 * sx, 5 * sz
				rot = {(1, 1): 0, (1, -1): 1, (-1, -1): 2, (-1, 1): 3}[(sx, sz)]
				put("bartizan", x - sx * TURRET_SH, 6.0, z - sz * TURRET_SH, rot,
					[("wall", x - sx, 5.5, z), ("wall", x, 5.5, z - sz), ("floor", x - sx, 7.5, z - sz)])
	# --- the gate room's jutting floor (z 3 -> 4): brackets under it on the guard rooms' fronts
	for sx in (-1, 1):
		for a in (2.5, 3.5, 4.5, 5.5):
			put("corbel", sx * a, 4.25, 3.57, 0, [("floor_half", sx * (1 + 2 * int((a - 0.5) // 2)), 5.25, 3.5), ("wall", sx * (3 if a < 4 else 5), 3.0, 3.0)])
	# --- the barracks: brackets under the wings' jutting upper floor, bands, corner blocks, buttresses
	for sx in (-1, 1):
		for i in range(8):
			a = 5.5 + i
			if abs(a - 10) < 1.0:
				continue                                  # (never in front of the wing's door)
			hx = sx * (6 + 2 * int((a - 5) // 2))
			put("corbel", sx * a, 2.0, -14.43, 0, [("floor_half", hx, 3.0, -14.5), ("wall", hx, 1.0, -15.0)])
	for y in (2.95, 5.2):
		band("z", -15.0, 1, [-2, 0, 2], y) if y > 3 else band("z", -15.0, 1, [-2, 0, 2], y)
		band("z", -14.0, 1, [-12, -10, -8, -6, 6, 8, 10, 12], y) if y > 3 else None
		band("x", -13.0, -1, [-22, -20, -18, -16], y)
		corner(-13, -23, -1, -1, y, [("wall", -12, 1.0 if y < 3 else 3.25, -23), ("wall", -13, 1.0 if y < 3 else 3.25, -22)])
	band("z", -23.0, -1, list(range(-12, 17, 2)), 2.95)
	band("z", -23.0, -1, list(range(-12, 13, 2)), 5.2)
	band("x", 13.0, 1, [-22, -20, -18, -16], 5.2)
	corner(13, -23, 1, -1, 5.2, [("wall", 12, 3.25, -23), ("wall", 13, 3.25, -22)])
	band("z", -17.0, 1, [14, 16], 2.95)                   # the kitchen
	band("x", 17.0, 1, [-22, -20, -18], 2.95)
	corner(17, -23, 1, -1, 2.95, [("wall", 16, 1.0, -23), ("wall", 17, 1.0, -22)])
	corner(17, -17, 1, 1, 2.95, [("wall", 16, 1.0, -17), ("wall", 17, 1.0, -18)])
	for x in (-11, -7, -3, 3, 7, 11, 15):
		put("buttress", x, 0.0, -23.626, 2, [("wall", x - 1, 1.0, -23), ("wall", x + 1, 1.0, -23)])
	# --- the wings' roofs: a 1 m battlement on both ends of the strip that juts out (x 5 and 13, z -15..-14)
	for sx in (-1, 1):
		for ex in (5, 13):
			put("battlement_narrow", sx * ex, 5.5, -14.5, 1, [("floor_half", sx * (ex + (1 if ex == 5 else -1)), 5.25, -14.5)])
	return out


def turret_corner_gaps(e):
	"""The deck battlements (or wooden railings) a turret takes the place of: the two next to its corner."""
	x, z = e["pos"][0], e["pos"][2]
	sx = 1 if x > (11 if x > 0 else -11) else -1
	sz = 1 if z > 0 else -1
	cx, cz = x + sx * TURRET_SH, z + sz * TURRET_SH        # the corner
	return [(cx - sx, 7.75, cz), (cx, 7.75, cz - sz)]


def turret_gap(p, turrets):
	return p["id"] in ("battlement", "railing") and any(at(p, *g) for e in turrets for g in turret_corner_gaps(e))


EXTRAS = extras()


def with_extras(plan):
	if any(p["id"] in TRIMS for p in plan):
		return plan                               # (Nov 22: the blueprint has them itself now, BlueprintLibrary._twin_trims)
	turrets = [p for p, _ in EXTRAS if p["id"] == "bartizan"]
	return [p for p in plan if not turret_gap(p, turrets)] + [dict(p) for p, _ in EXTRAS]


# ---------------------------------------------------------------- break it
def near(p, x, z, r=0.3):
	return abs(p["pos"][0] - x) < r and abs(p["pos"][2] - z) < r


def at(p, x, y, z):
	return near(p, x, z, 0.15) and abs(p["pos"][1] - y) < 0.05


R_CX = 11.0


def in_r_tower(x, z):
	return 5.9 < x < 16.5 and -5.5 < z < 5.5


def break_r_tower(p, q):
	"""The right tower cracked in half (between x 11 and 13): its outer half fell outward. None = gone."""
	x, y, z = p["pos"]
	pid = p["id"]
	wallish = pid in WALLISH
	face = abs(abs(z) - 5) < 0.1                         # the front or back face
	if y < 0.5:
		return q                                          # foundations
	if y > 9.0:                                           # the ring stage's top floors
		if pid == "wall" and abs(y - 10.0) < 0.05 and x < 7.5 and abs(z) < 0.3:
			q["id"] = "ruin_wall_collapsed"               # one broken stump over the ring's doorway
			return q
		return None
	if 7.6 < y < 9.0:                                     # on the deck: battlements, the ring stage's walls
		if pid == "stairs":
			return None
		if pid == "battlement":
			return q if x < 9.5 else None
		if pid == "railing":
			return q if x < 10.1 else None
		if x >= 10.0:
			return None
		if wallish and abs(z) > 2.9 and x > 8.5:
			q["id"] = "ruin_wall_collapsed"               # the ring's broken ends
			if z > 0:
				q["rot"] = turned(q["rot"])               # (high ends away from the break)
		return q
	if 7.4 < y < 7.6:
		return q if x < 9.5 else None                     # the deck
	if 5.2 < y < 5.3:
		return q if x < 11.5 else None                    # the second floor
	if 5.4 < y < 5.9:
		if wallish:
			if x > 15.9 or x > 12.0:
				return None
			if face and abs(x - 11) < 0.1:
				q["id"] = "ruin_wall_collapsed"
				if z > 0:
					q["rot"] = turned(q["rot"])
			return q
		return q if x < 11.5 else None                    # railings, stairs
	if 2.9 < y < 3.1:
		return q if x < 11.5 else None                    # the first floor
	if 3.2 < y < 3.7:
		if wallish:
			if x > 15.9 or (face and x > 14):
				return None
			if face and abs(x - 13) < 0.1:
				q["id"] = "ruin_wall_collapsed"
			return q
		if pid in ("stairs", "stairs_corner") and x > 11.5:
			return None
		return q if x < 12.5 else None
	if wallish:                                           # the ground floor
		if x > 15.9 or (face and abs(x - 15) < 0.1):
			q["id"] = "ruin_wall_collapsed"
		elif face and abs(x - 13) < 0.1:
			q["id"] = "ruin_wall_worn"
	return q


GATE_ROOF_GONE = lambda p: p["id"] in ("floor", "floor_half") and abs(p["pos"][1] - 7.5) < 0.05 and p["pos"][0] > 0 and -4 < p["pos"][2] < 4
WING_ROOF_GONE = lambda p: (p["id"] in ("floor", "floor_half") and abs(p["pos"][1] - 5.25) < 0.05 and p["pos"][0] > 5.5
	and p["pos"][2] < -13)
KITCHEN_ROOF_GONE = lambda p: p["id"] == "floor" and abs(p["pos"][1] - 3.0) < 0.05 and p["pos"][0] > 13.5 and p["pos"][2] < -16
COLLAPSE = [(5, 5.5, 4), (8, 3.25, -14), (13, 3.25, -22), (-13, 0.0, -10)]     # walls broken down to a stump
WORN = [(12, 3.25, -23), (-13, 0.0, -12), (3, 5.5, 4)]
GONE = [(-13, 2.0, -10), (-13, 2.0, -12), (-13, 4.0, -10), (-13, 4.0, -12)]   # the left yard wall's top, fallen

pieces, extra_ids = [], set()
extra_hosts = {}
for p in [p for p in plan_of(bp) if p["id"] not in TRIMS] + [dict(e) for e, _ in EXTRAS]:   # (never twice: the blueprint has them too)
	pid = p["id"]
	x, y, z = p["pos"]
	q = dict(p, pos=list(p["pos"]))
	if pid == "door":
		continue                                          # doors gone
	if pid == "gate_leaf" and z > 0:
		continue                                          # the outer gate torn off
	if pid in TRIMS:
		pieces.append(q)                                  # (checked against their hosts below)
		continue
	if in_r_tower(x, z) or (y > 7.6 and x > 6 and math.hypot(x - R_CX, z) < 4.3):
		q = break_r_tower(p, q)
		if q is None:
			continue
		if q["id"] in ("wall", "window_wall") and rng.random() < 0.3:
			q["id"] = "ruin_wall_worn"
		pieces.append(q)
		continue
	if GATE_ROOF_GONE(p) or WING_ROOF_GONE(p) or KITCHEN_ROOF_GONE(p):
		continue
	if any(at(p, *g) for g in GONE):
		continue
	if pid in WALLISH and any(at(p, *c) for c in COLLAPSE):
		q["id"] = "ruin_wall_collapsed"
	elif pid in WALLISH and any(at(p, *c) for c in WORN):
		q["id"] = "ruin_wall_worn"
	elif pid in ("wall", "window_wall", "lattice_wall") and rng.random() < 0.3 and pid != "lattice_wall":
		q["id"] = "ruin_wall_worn"                        # (the lattice draws too: the worn walls stay where they were)
	pieces.append(q)


def is_piece(pid, x, y, z, kinds):
	return next((p for p in pieces if p["id"] in kinds and at(p, x, y, z)), None)


def supported(p):
	"""Battlements and railings need the floor they stand on (a floor edge within reach, 0.25 m below)."""
	x, y, z = p["pos"]
	for f in pieces:
		if f["id"] in ("floor", "floor_half", "floor_triangle") and abs(f["pos"][1] + 0.25 - y) < 0.06:
			if RJ.inside((x, z), RJ.footprint(f, 0.06)):
				return True
	return False


# Nothing may stand on a wall that collapsed (a floating stone), nor right on top of a worn one (the yard wall),
# no battlement or railing where its floor fell in.
changed = True
while changed:
	changed = False
	low = [p for p in pieces if p["id"] == "ruin_wall_collapsed"]
	worn = [p for p in pieces if p["id"] == "ruin_wall_worn"]
	for p in list(pieces):
		if p["id"] in WALLISH + ("pillar", "battlement"):
			on = any(near(c, p["pos"][0], p["pos"][2], 0.1) and any(abs(p["pos"][1] - c["pos"][1] - dy) < 0.02 for dy in (1.0, 2.0, 2.25))
				for c in low) or any(near(c, p["pos"][0], p["pos"][2], 0.1) and abs(p["pos"][1] - c["pos"][1] - 2.0) < 0.02 for c in worn)
			if on:
				pieces.remove(p)
				changed = True
				continue
		if p["id"] in ("battlement", "railing") and p["pos"][1] > 1.5 and not supported(p):
			pieces.remove(p)
			changed = True
		elif p["id"] == "edge_strip" and not supported(dict(p, pos=[p["pos"][0], p["pos"][1] + 0.25, p["pos"][2]])):
			pieces.remove(p)                              # (its floor fell in)
			changed = True

# the trims go where what they hang on is gone or broken
WHOLE = ("wall", "window_wall", "window_wide", "doorway", "wall_narrow")
for (e, hosts) in EXTRAS:
	ok = True
	for (kind, hx, hy, hz) in hosts:
		kinds = WHOLE if kind == "wall" else (kind,)
		if e["id"] == "buttress" and kind == "wall":
			kinds = WHOLE + ("ruin_wall_worn",)
		if not is_piece(kinds[0], hx, hy, hz, kinds) and not (kind == "wall" and is_piece("", hx, hy, hz, kinds)):
			ok = False
	if not ok:
		pieces[:] = [p for p in pieces if not (p["id"] == e["id"] and p["pos"] == e["pos"] and p["rot"] == e["rot"])]
# the deck corners open where a turret still stands (where one fell, the deck's own battlements stay)
standing = [p for p in pieces if p["id"] == "bartizan"]
pieces[:] = [p for p in pieces if not turret_gap(p, standing)]


def add(pid, x, y, z, yaw_deg, mat="cut_stone"):
	pieces.append({"id": pid, "mat": mat, "pos": [round(x, 3), y, round(z, 3)], "rot": rot_from(round(yaw_deg / 30))})


DEBRIS = ("ruin_rubble", "spire_wall_chunk", "gate_broken", "ruin_wall_collapsed")
n_before = len(pieces)
# The right tower's outer half: two big wall pieces lying past it, broken tops farthest out; rubble at its foot.
add("spire_wall_chunk", 20.6, 0.0, 2.0, 0)
add("spire_wall_chunk", 20.2, 0.0, -2.9, 330)
# The outer gate's leaves, torn off and thrown past the grand steps.
add("gate_broken", -2.3, 0.0, 10.5, 30)
add("gate_broken", 2.7, 0.0, 11.5, 300)
# Rubble where things fell: at the cracked tower's foot and inside it, the gate room's right side, the right wing's
# upper floor, the kitchen, the left yard wall. Never in a doorway, on steps or stairs.
for (x, y, z) in [(17.0, 0.0, -6.4), (18.0, 0.0, 4.4), (23.6, 0.0, -0.6), (14.2, 1.0, -2.5), (14.4, 1.0, 2.9),
		(10.3, 3.25, -3.3), (3.0, 5.5, -1.5), (9.5, 3.25, -17.5), (10.8, 3.25, -19.0), (15.6, 1.0, -19.6),
		(-14.3, 0.0, -10.4), (-11.0, 0.0, -11.7)]:
	add("ruin_rubble", x, y, z, rng.randrange(0, 12) * 30)

chests = [
	{"kind": "chest_stone", "pos": [-4.0, 1.0, -2.38], "yaw": 0, "loot": {"recipe_page": 1, "rope": 2}},                 # guard room
	{"kind": "chest_copper", "pos": [3.0, 5.5, -22.42], "yaw": 0, "loot": {"recipe_page": 2, "blueprint_page": 1}},      # captain
	{"kind": "chest_copper", "pos": [-11.0, 12.25, -1.16], "yaw": 0, "loot": {"recipe_page": 2, "blueprint_page": 1}},   # lantern
]

# ---------------------------------------------------------------- the guards' things
_dims = {}


def dims(model):
	if model not in _dims:
		lo, hi = bounds(str(GAME / "assets/models/decor" / f"{model}.glb"))
		_dims[model] = (float(hi[0] - lo[0]), float(hi[1] - lo[1]), float(hi[2] - lo[2]))
	return _dims[model]


FACE = {"+z": (0, 1, 0), "-z": (0, -1, 180), "+x": (1, 0, 90), "-x": (-1, 0, 270)}


def on_wall(model, facing, line, along, y, lift=0.0):
	"""Back to a wall (on the line), facing into the room; y = the floor's top. -> prop."""
	nx, nz, yaw = FACE[facing]
	d = dims(model)[2]
	off = 0.15 + 0.06 + d / 2
	pos = [along, y + 0.01 + lift, line + nz * off] if nx == 0 else [line + nx * off, y + 0.01 + lift, along]
	return {"model": model, "pos": [round(v, 3) for v in pos], "yaw": yaw}


def free_at(model, x, z, y, yaw=0):
	return {"model": model, "pos": [x, y + 0.01, z], "yaw": yaw}


props = [
	# the guard rooms beside the passage
	on_wall("hs_axe_rack", "-z", 3.0, -4.0, 1.0),
	on_wall("hs_war_horn_stand", "-z", 3.0, 4.0, 1.0),
	on_wall("hs_axe_rack", "+z", -3.0, 4.0, 1.0),
	# the gate room (its left half still roofed)
	on_wall("hs_tower_shields_chained", "+z", -3.0, -5.0, 5.5),       # (on the solid wall: the lattice is beside it)
	on_wall("banner_torn_faded", "+z", -3.0, -1.2, 5.5),
	# the barracks' mess hall
	free_at("mg_mess_trestle", 2.5, -21.4, 1.0),
	on_wall("mg_bowl_shelf", "+z", -23.0, 2.5, 1.0),
	on_wall("hs_squad_pennants", "+z", -23.0, -2.5, 1.0),
	on_wall("banner_torn_faded", "-z", -15.0, 2.4, 1.0),
	on_wall("banner_torn_faded", "-z", -15.0, -2.4, 1.0),
	# the sergeants' floor
	free_at("hs_muster_table", 0.0, -22.0, 3.25),
	on_wall("hs_duty_roster", "-z", -15.0, 4.0, 3.25),
	on_wall("hs_shieldbearer_stand", "+z", -23.0, 4.0, 3.25),
	# the captain's floor: his chair under an old banner, a split shield hung as a trophy (rooms are 2 m high: no tall pieces)
	on_wall("banner_torn_faded", "+z", -23.0, -3.0, 5.5),
	on_wall("hs_split_shield_trophy", "+x", -5.0, -22.3, 5.5, lift=0.8),
	free_at("hs_captains_chair", -3.0, -21.7, 5.5),
	# the wings' bunk rooms
	on_wall("hs_guard_bunk", "+z", -23.0, -11.7, 1.0), on_wall("hs_guard_bunk", "+z", -23.0, -9.2, 1.0),
	on_wall("hs_guard_bunk", "+z", -23.0, -6.7, 1.0),
	on_wall("hs_axe_rack", "+x", -13.0, -18.0, 1.0),
	on_wall("hs_duty_roster", "-z", -15.0, -7.0, 1.0),
	on_wall("hs_guard_bunk", "+z", -23.0, 6.7, 1.0), on_wall("hs_guard_bunk", "+z", -23.0, 9.2, 1.0),
	on_wall("hs_guard_bunk", "+z", -23.0, 11.7, 1.0),
	on_wall("hs_guard_bunk", "+z", -23.0, -11.7, 3.25), on_wall("hs_guard_bunk", "+z", -23.0, -7.2, 3.25),
	on_wall("hs_guard_bunk", "+z", -23.0, 7.2, 3.25),
	# the kitchen
	on_wall("bread_oven", "+z", -23.0, 15.3, 1.0),
	on_wall("kitchen_block", "+z", -23.0, 13.9, 1.0),
	on_wall("dish_rack", "+z", -23.0, 13.9, 1.0, lift=1.0),
	on_wall("pie_rack", "-x", 17.0, -21.6, 1.0),
	# the left tower: stores downstairs, bunks on the first floor, a trophy pole on the second
	free_at("mg_crate_pried_open", -14.9, -4.0, 1.0),
	free_at("storage_trunk", -14.8, -1.6, 1.0, 90),
	on_wall("hs_guard_bunk", "-z", 5.0, -7.7, 3.25),
	on_wall("hs_guard_bunk", "+z", -5.0, -7.7, 3.25),
	on_wall("hs_tower_shields_chained", "+x", -16.0, 4.0, 5.5),
	# the yard: practice pells, the buckler rail and trough on the right wall, braziers by the gate house's steps
	free_at("hs_shield_pell", -5.0, -10.5, 0.0), free_at("hs_shield_pell", -7.5, -10.5, 0.0, 30),
	free_at("hs_shield_pell", 5.5, -10.5, 0.0, 330),
	free_at("hs_buckler_rail", 8.5, -11.5, 0.0),
	on_wall("hs_practice_trough", "-x", 13.0, -10.9, 0.0),
	free_at("hs_watch_brazier", -5.42, -3.8, 0.0, 180), free_at("hs_watch_brazier", 5.42, -3.8, 0.0, 180),
]
beetles = [[-9.5, 0.0, -8.0], [3.0, 1.0, -18.6], [9.0, 3.25, -21.0], [13.8, 1.0, 0.3]]

# ---------------------------------------------------------------- the rules check (tools/ruins/ruin_junk.py's numbers)
# walk lines between the doorways (and stairs), per floor top
PATHS = {
	0.0: [((0, -5), (0, -11)), ((-11, -7), (0, -8)), ((11, -7), (0, -8)), ((0, 7), (0, 14)), ((16, -15), (14, -11))],
	1.0: [((-2, 0), (-6, 0)), ((2, 0), (6, 0)), ((-11, -5), (-6, 0)), ((-11, -5), (-11, 0)), ((11, -5), (6, 0)),
		((0, -15), (5, -20)), ((0, -15), (-5, -20)), ((-5, -20), (5, -20)), ((-10, -15), (-5, -20)),
		((10, -15), (5, -20)), ((10, -15), (13, -20)), ((5, -20), (13, -20)), ((16, -17), (13, -20))],
	3.25: [((-5, -20), (5, -20)), ((-5, -20), (-12, -20)), ((5, -20), (12, -20))],
	5.5: [((-6, 0), (6, 0)), ((-5, -20), (5, -20))],
}


def corners_of(x, z, sx, sz, yaw):
	a = math.radians(yaw)
	return [(x + u * math.cos(a) + v * math.sin(a), z - u * math.sin(a) + v * math.cos(a))
		for (u, v) in ((-sx / 2, -sz / 2), (sx / 2, -sz / 2), (sx / 2, sz / 2), (-sx / 2, sz / 2))]


def poly_pt_dist(cs, pt):
	if RJ.inside(pt, cs):
		return 0.0
	return min(seg_dist(pt, cs[i], cs[(i + 1) % len(cs)]) for i in range(len(cs)))


def seg_dist(p, a, b):
	ax, az = b[0] - a[0], b[1] - a[1]
	L = ax * ax + az * az
	t = 0 if L == 0 else max(0.0, min(1.0, ((p[0] - a[0]) * ax + (p[1] - a[1]) * az) / L))
	return math.hypot(p[0] - a[0] - t * ax, p[1] - a[1] - t * az)


def poly_dist(a, b):
	if RJ.overlap(a, b):
		return 0.0
	return min(min(poly_pt_dist(b, p) for p in a), min(poly_pt_dist(a, p) for p in b))


def top_of(p):
	return p["pos"][1] + RJ.PIECES[p["id"]]["size"][1]


def check_things():
	"""Every prop, chest and bit of debris against the rules. -> list of problems."""
	bad = []
	things = []
	for pr in props:
		sx, h, sz = dims(pr["model"])
		things.append((pr["model"], pr["pos"], corners_of(pr["pos"][0], pr["pos"][2], sx, sz, pr["yaw"]), h, "prop"))
	for c in chests:
		lo, hi = bounds(str(GAME / "assets/models/stations" / f"{c['kind']}.glb"))
		things.append((c["kind"], c["pos"], corners_of(c["pos"][0], c["pos"][2], float(hi[0] - lo[0]), float(hi[2] - lo[2]), c["yaw"]),
			float(hi[1] - lo[1]), "chest"))
	for p in pieces[n_before:]:
		if p["id"] != "ruin_wall_collapsed":
			things.append((p["id"], p["pos"], RJ.footprint(p), RJ.PIECES[p["id"]]["size"][1], "debris"))
	build = [p for p in pieces[:n_before] if p["id"] in RJ.PIECES]
	for (name, pos, cs, h, kind) in things:
		y = pos[1]
		floor_y = round(y - (0.01 if kind == "prop" else 0.0), 2)
		lift = kind == "prop" and any(abs(floor_y - f) < 0.02 for f in (0.0, 1.0, 3.25, 5.5, 12.25)) is False
		tag = f"{name} at ({pos[0]:.2f}, {y:.2f}, {pos[2]:.2f})"
		# stands on something (all four corners and the middle), unless hung on a wall
		if y > 0.05 and not lift:
			for pt in cs + [(pos[0], pos[2])]:
				if not any(abs(top_of(f) - floor_y) < 0.06 and RJ.inside(pt, RJ.footprint(f, 0.02)) for f in build
						if f["id"] in ("floor", "floor_half", "floor_triangle", "foundation")):
					bad.append(f"{tag}: a corner over no floor")
					break
		for p in build:
			lo, hi = p["pos"][1], top_of(p)
			if p["id"] == "bartizan" and y + h < 7.5 and any(abs(pos[0] - c) < 4.85 and abs(pos[2]) < 4.85 for c in TOWERS):
				continue                                  # (its box reaches into the tower's corner; its stones don't)
			if p["id"] in RJ.STAIRS:
				grow = RJ.STAIR_CLEAR if kind != "debris" else 0.5
				if p["id"] == "foundation_steps" and y > hi - 0.05:
					grow = 0.0                                # (outside steps, the thing is up on the floor behind a wall)
				if lo - 0.3 < y < hi + 0.3 and RJ.overlap(cs, RJ.footprint(p, grow)):
					bad.append(f"{tag}: on or by the stairs at {p['pos']}")
				continue
			if p["id"] in ("doorway", "gateway") and abs(lo - y) < 1.0:
				need = (2.5 if p["id"] == "gateway" else 1.5)
				if poly_pt_dist(cs, (p["pos"][0], p["pos"][2])) < need:
					bad.append(f"{tag}: in the {p['id']} at {p['pos']}")
			if hi > y + 0.05 and lo < y + h and RJ.overlap(cs, RJ.footprint(p, 0.05 if kind != "debris" else 0.0)):
				if kind == "debris" and p["id"] in ("foundation", "floor", "floor_half"):
					continue
				bad.append(f"{tag}: inside {p['id']} at {p['pos']}")
		if kind != "debris":
			for c in chests:
				if c["pos"] is not pos and abs(c["pos"][1] - y) < 0.5 and poly_pt_dist(cs, (c["pos"][0], c["pos"][2])) < RJ.THING_CLEAR:
					bad.append(f"{tag}: too near the chest at {c['pos']}")
			for (a, b) in PATHS.get(floor_y if not lift else -1, []):
				if seg_dist((pos[0], pos[2]), a, b) < RJ.PATH_CLEAR or any(seg_dist(c, a, b) < RJ.PATH_EDGE for c in cs):
					bad.append(f"{tag}: on the walk line {a}->{b}")
	for i, (n1, p1, c1, h1, k1) in enumerate(things):
		for (n2, p2, c2, h2, k2) in things[i + 1:]:
			if p1[1] < p2[1] + h2 and p2[1] < p1[1] + h1 and poly_dist(c1, c2) < (RJ.JUNK_GAP if "debris" not in (k1, k2) else 0.05):
				bad.append(f"{n1} at {p1} and {n2} at {p2}: too close")
	return bad


problems = check_things()
for b in problems:
	print("RULE:", b)


# ---------------------------------------------------------------- write it (blueprint z again)
def shifted(p):
	return dict(p, pos=[p["pos"][0], p["pos"][1], round(p["pos"][2] + ZS, 4)])


out = GAME / "blueprints" / "ruins" / "twin_gate_ruin.json"
all_pts = [(p["pos"][0], p["pos"][2] + ZS) for p in pieces]
radius = round(max(math.hypot(x, z) for x, z in all_pts) + 1.5, 1)
json.dump({"name": "Twin Gate", "radius": radius, "height": 16.5, "front": 15.0, "square": True, "reach": radius + 6.0,
	"pieces": [shifted(p) for p in pieces],
	"chests": [dict(c, pos=[c["pos"][0], c["pos"][1], round(c["pos"][2] + ZS, 3)]) for c in chests],
	"beetles": [[b[0], b[1], b[2] + ZS] for b in beetles],
	"props": [dict(pr, pos=[pr["pos"][0], pr["pos"][1], round(pr["pos"][2] + ZS, 3)]) for pr in props]},
	open(out, "w", encoding="utf-8"), separators=(",", ":"))
counts = {}
for p in pieces:
	counts[p["id"]] = counts.get(p["id"], 0) + 1
print("WROTE", out.name, len(pieces), "pieces,", len(chests), "chests,", len(props), "props, radius", radius, ";", counts)


# ---------------------------------------------------------------- the rebuilds (builder.gd's rules, as the kiln)
def same_here(p, ruin):
	return next((q for q in ruin if q["id"] == p["id"] and q["rot"] == p["rot"]
		and sum((a - b) ** 2 for a, b in zip(q["pos"], p["pos"])) < 0.05 ** 2), None)


def rebuild(plan, wood):
	ruin = [q for q in pieces if q["id"] not in DEBRIS]
	kept, new = [], []
	news = [p for p in plan if not same_here(p, ruin)]
	go = set()
	if wood:
		for i, q in enumerate(ruin):
			if q["id"] == "ruin_wall_worn" and any(1.9 < a["pos"][1] - q["pos"][1] < 2.35 and abs(a["pos"][0] - q["pos"][0]) < 0.1
					and abs(a["pos"][2] - q["pos"][2]) < 0.1 for a in news):
				go.add(i)
	used = set()
	for p in plan:
		q = same_here(p, ruin)
		if q is not None:
			used.add(id(q))
			continue
		if wood and p["id"] in ("wall", "window_wall"):
			w = next((i for i, q in enumerate(ruin) if q["id"] == "ruin_wall_worn" and i not in go and id(q) not in used
				and sum((a - b) ** 2 for a, b in zip(q["pos"], p["pos"])) < 0.6 ** 2), None)
			if w is not None:
				used.add(id(ruin[w]))
				continue
		new.append(dict(p, new=True))
	for q in ruin:
		if id(q) in used:
			kept.append(q)
	return kept + new, new


if page:
	(page / "m").mkdir(parents=True, exist_ok=True)
	views = {"ruin": pieces}
	views["stone"], new_s = rebuild(with_extras(plan_of(bp)), False)
	new_w = []
	if wood_bp:
		views["wood"], new_w = rebuild(with_extras(plan_of(wood_bp)), True)
	extra = []
	for c in chests:
		extra.append({"id": c["kind"], "mat": "prop", "pos": c["pos"], "rot": 4 + round(c["yaw"] / 30) % 12})
	for pr in props:
		extra.append({"id": pr["model"], "mat": "prop", "pos": pr["pos"], "rot": 4 + round(pr["yaw"] / 30) % 12})
	for i, b in enumerate(beetles):
		extra.append({"id": "rock_beetle_mossy", "mat": "prop", "pos": b, "rot": 4 + (i * 5) % 12})
	views["ruin"] = views["ruin"] + extra
	keep_props = [e for e in extra if e["id"].startswith("chest")]
	for k in ("wood", "stone"):
		if k in views:
			views[k] = views[k] + keep_props
	views = {k: [shifted(p) for p in v] for k, v in views.items()}
	trims = TRIMS
	json.dump({"views": views, "trims": list(trims)}, open(page / "bp.json", "w"), separators=(",", ":"))
	json.dump({"wood": [{"id": p["id"], "mat": p["mat"]} for p in new_w], "stone": [{"id": p["id"], "mat": p["mat"]} for p in new_s]},
		open(page / "new_pieces.json", "w"), separators=(",", ":"))
	SRC = {"chest_stone": "assets/models/stations/chest_stone.glb", "chest_small": "assets/models/stations/chest_small.glb",
		"chest_copper": "assets/models/stations/chest_copper.glb", "rock_beetle_mossy": "assets/models/creatures/rock_beetle_mossy.glb"}
	NEWDIR = GAME / "journey" / "stonehold_v2" / "glb"   # the new trims (not in the game until the owner's OK)
	for v in views.values():
		for p in v:
			key = p["id"] if p["mat"] == "prop" else f"{p['id']}__{p['mat']}"
			f = page / "m" / f"{key}.json"
			if f.exists():
				continue
			src = GAME / SRC[p["id"]] if p["id"] in SRC else GAME / f"assets/models/build/{key}.glb"
			if p["mat"] == "prop" and p["id"] not in SRC:
				src = GAME / f"assets/models/decor/{key}.glb"
			if not src.exists():
				src = NEWDIR / f"{key}.glb"
			dat = src.read_bytes()
			n = struct.unpack("<I", dat[12:16])[0]
			g = json.loads(dat[20:20 + n])
			b = dat[20 + n + 8:]
			g["buffers"] = [{"byteLength": len(b), "uri": "data:application/octet-stream;base64," + base64.b64encode(b).decode()}]
			f.write_text(json.dumps(g, separators=(",", ":")))
	print("page files written:", {k: len(v) for k, v in views.items()}, "new:", len(new_w), "wood,", len(new_s), "stone")
