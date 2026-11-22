# The RUINED Lantern Spire (owner, Nov 20: ruin 4 of Zone 1): made from the real blueprint, then broken.
#   godot --headless --path . -s res://tools/dump_blueprint.gd -- lantern_spire <stone.json>
#   godot --headless --path . -s res://tools/dump_blueprint.gd -- wooden_spire <wood.json>
#   python tools/ruins/make_spire_ruin.py <stone.json> [wood=<wood.json>] [page=<folder>]
# Writes blueprints/ruins/spire_ruin.json (pieces, chests with loot, beetles) for the world to place.
# The ruin is the blueprint piece for piece (so it rebuilds on the very same spots): the top half snapped off and
# fell toward the front right (yaw 60 degrees). What still stands: the ground floor (door gone, worn walls), the
# second floor (its walls on the fall side broken down in a slope), a ledge of the third floor at the back with the
# stairs up to it and three stumps of its walls. The fallen top lies across the cave floor: the tower's top on its
# side (spire_top_fallen), a curved piece of wall (spire_wall_chunk), the fire bowl knocked off (beacon_bowl_fallen),
# heaps of rubble between them. No rubble in the doorway, on the steps or the stairs (owner, Nov 17).
# A landmark to FIND: no flat base space round it (owner, Nov 20), unlike the other ruins.
# With page=<folder> (and wood=): the 3D page's files: the ruin, rebuilt in wood, rebuilt in stone, side by side,
# each new piece marked (worked out with the game's rebuild rules, src/build/builder.gd "rebuilding ruins").
import base64
import json
import math
import random
import struct
import sys
from pathlib import Path

GAME = Path(__file__).resolve().parents[2]
args = sys.argv[1:]
bp = json.load(open(args[0], encoding="utf-8"))
page = next((Path(a[5:]) for a in args if a.startswith("page=")), None)
wood_bp = next((json.load(open(a[5:], encoding="utf-8")) for a in args if a.startswith("wood=")), None)
rng = random.Random(4)

FALL = 2            # the top fell toward yaw step 2 (60 degrees: front right)


def step_of(x, z):
	"""Which of the 12 directions (30 degree steps, 0 = +z front) a spot lies in, as a float."""
	return (math.degrees(math.atan2(x, z)) / 30.0) % 12


def off(s, t):
	"""How many steps apart two directions are (0..6)."""
	d = abs(s - t) % 12
	return min(d, 12 - d)


def steps_of(rot):
	return rot * 3 if rot < 4 else rot - 4


def rot_from(steps):
	"""Pieces.rot_from_steps: quarter turns as 0-3, other 30 degree turns as 4 + steps."""
	k = steps % 12
	return k // 3 if k % 3 == 0 else 4 + k


def turned(rot):
	return rot_from(steps_of(rot) + 6)


WALLISH = ("wall", "window_wall", "window_wide", "doorway", "half_wall", "ruin_wall_worn", "ruin_wall_collapsed")
pieces = []
for p in bp["pieces"]:
	x, y, z = p["pos"]
	y = round(y, 2)
	pid = p["id"]
	q = {"id": pid, "mat": p["mat"], "pos": [round(x, 4), y, round(z, 4)], "rot": p["rot"]}
	s = step_of(x, z)
	r = math.hypot(x, z)
	if pid == "door":
		continue                                                    # the door is gone
	if y > 5.6:
		continue                                                    # the top half snapped off
	if 5.0 < y < 5.6:                                               # the third floor: a ledge at the back, three stumps
		if pid in ("floor", "floor_triangle") and not (off(s, 8) <= 1.6 and r > 1.0):
			continue
		if pid in ("railing",) and off(s, 8) > 1.6:
			continue
		if pid in WALLISH:
			j = round(s) % 12
			if j not in (7, 8, 9):
				continue
			if j == 8:
				q["id"] = "ruin_wall_worn"
			else:
				q["id"] = "ruin_wall_collapsed"
				if j == 9:                                          # (high end toward edge 8: built turned round; a wall's right end points to the next edge)
					q["rot"] = turned(p["rot"])
		if pid == "pillar" and int(s - 0.5 + 12) % 12 not in (7, 8):
			continue                                                # only the pillars between the stumps stand
	elif 3.1 < y < 3.4 and pid in WALLISH + ("pillar",):            # the second floor's walls
		j = round(s) % 12 if pid != "pillar" else None
		if pid == "pillar":
			c = int(round(s - 0.5)) % 12                            # corner c sits between edges c and c+1
			if off(c, FALL) <= 1.0 or off(c + 1, FALL) <= 1.0:
				continue                                            # beside a broken-down wall: fell with it
		elif off(j, FALL) <= 1:
			q["id"] = "ruin_wall_collapsed"                        # broken down on the side the top fell to,
			if j == FALL - 1:                                       # high end away from the fall
				q["rot"] = turned(p["rot"])
		elif rng.random() < 0.45:
			q["id"] = "ruin_wall_worn"
	elif 0.9 < y < 1.1 and pid in ("wall", "window_wall") and rng.random() < 0.4:
		q["id"] = "ruin_wall_worn"
	pieces.append(q)

# Nothing may stand on a wall that collapsed (owner: a floating stone): drop what stood on top of one.
changed = True
while changed:
	changed = False
	low = [p for p in pieces if p["id"] == "ruin_wall_collapsed"]
	for p in list(pieces):
		if p["id"] in WALLISH + ("pillar",) and any(abs(c["pos"][0] - p["pos"][0]) < 0.1 and abs(c["pos"][2] - p["pos"][2]) < 0.1
				and any(abs(p["pos"][1] - c["pos"][1] - dy) < 0.02 for dy in (2.0, 2.25)) for c in low):
			pieces.remove(p)
			changed = True


def add(pid, x, y, z, yaw_deg, mat="cut_stone"):
	pieces.append({"id": pid, "mat": mat, "pos": [round(x, 3), y, round(z, 3)], "rot": rot_from(round(yaw_deg / 30))})


def along(d, side=0.0):
	"""A spot d m out from the middle toward the fall, `side` m to its left."""
	a = math.radians(FALL * 30)
	return (math.sin(a) * d - math.cos(a) * side, math.cos(a) * d + math.sin(a) * side)


# The fallen top: its snapped end toward the tower, lying out along the fall; the curved wall piece beside it; the
# fire bowl rolled furthest. Rubble heaps where stones broke off as it hit.
x, z = along(11.6)
add("spire_top_fallen", x, 0.0, z, FALL * 30 + 0)
x, z = along(8.4, -5.6)                                # (on the far side of the fallen top: clear of the front steps)
add("spire_wall_chunk", x, 0.0, z, FALL * 30 + 60)
x, z = along(17.2, -2.4)
add("beacon_bowl_fallen", x, 0.0, z, FALL * 30 + 30)
for (d, side) in [(5.6, -1.6), (6.4, 1.8), (6.9, -3.8), (15.8, 3.2), (9.0, 6.4), (18.0, 2.0), (5.3, 3.9)]:
	x, z = along(d, side)
	add("ruin_rubble", x, 0.0, z, rng.randrange(0, 360))
# inside: the ground floor and the second floor (never on the stairs' squares or in the doorway)
for (d, a, y) in [(2.6, 7.0, 1.0), (1.2, 10.5, 1.0), (2.7, 2.0, 3.25), (1.0, 6.0, 3.25)]:
	add("ruin_rubble", math.sin(math.radians(a * 30)) * d, y, math.cos(math.radians(a * 30)) * d, rng.randrange(0, 360))


def ring_spot(step, d, y):
	return [round(math.sin(math.radians(step * 30)) * d, 3), y, round(math.cos(math.radians(step * 30)) * d, 3)]


chests = [
	{"kind": "chest_stone", "pos": ring_spot(9.6, 2.9, 1.0), "yaw": round(9.6 * 30 + 180) % 360, "loot": {"recipe_page": 1, "rope": 2}},
	{"kind": "chest_copper", "pos": ring_spot(6.85, 3.25, 5.5), "yaw": 26, "loot": {"recipe_page": 2, "blueprint_page": 1}},   # on the ledge, behind the stairwell's railing (owner, Nov 22: not on the stairs' top)
]
props = []
beetles = [ring_spot(6.0, 2.2, 1.0), ring_spot(10.0, 2.3, 3.25), list(along(9.0, -4.0)[:1]) + [0.0] + list(along(9.0, -4.0)[1:])]

out = GAME / "blueprints" / "ruins" / "spire_ruin.json"
json.dump({"name": "Lantern Spire", "radius": 4.2, "height": 12.0, "front": 6.8, "reach": 21.0, "pieces": pieces,
	"chests": chests, "beetles": beetles, "props": props}, open(out, "w", encoding="utf-8"), separators=(",", ":"))
counts = {}
for p in pieces:
	counts[p["id"]] = counts.get(p["id"], 0) + 1
print("WROTE", out.name, len(pieces), "pieces,", len(chests), "chests;", counts)


# ---------------------------------------------------------------- the rebuilds (builder.gd's rules)
DEBRIS = ("ruin_rubble", "spire_top_fallen", "spire_wall_chunk", "beacon_bowl_fallen", "ruin_wall_collapsed")


def same_here(p, ruin):
	return next((q for q in ruin if q["id"] == p["id"] and q["rot"] == p["rot"]
		and sum((a - b) ** 2 for a, b in zip(q["pos"], p["pos"])) < 0.05 ** 2), None)


def rebuild(plan, wood):
	"""-> (pieces shown, new pieces). Whole ruin pieces stay; in wood, worn walls stay too unless something new
	stands right on top of one (2 to 2.35 m above: Stonehold floors are 2.25 m apart)."""
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
			w = next((i for i, q in enumerate(ruin) if q["id"] == "ruin_wall_worn" and i not in go
				and sum((a - b) ** 2 for a, b in zip(q["pos"], p["pos"])) < 0.6 ** 2), None)
			if w is not None:
				used.add(id(ruin[w]))
				continue
		new.append(dict(p, new=True))
	for q in ruin:
		if id(q) in used:
			kept.append(q)
	return kept + new, new


def plan_of(b):
	return [{"id": p["id"], "mat": p["mat"], "pos": [round(v, 4) for v in p["pos"]], "rot": p["rot"]} for p in b["pieces"]]   # (the fire bowl is in the blueprint, stone in both)


if page:
	(page / "m").mkdir(parents=True, exist_ok=True)
	plan_s = plan_of(bp)
	views = {"ruin": pieces}
	views["stone"], new_s = rebuild(plan_s, False)
	new_w = []
	if wood_bp:
		views["wood"], new_w = rebuild(plan_of(wood_bp), True)
	extra = []
	for c in chests:
		extra.append({"id": c["kind"], "mat": "prop", "pos": c["pos"], "rot": 4 + round(c["yaw"] / 30) % 12})
	for i, b in enumerate(beetles):
		extra.append({"id": "rock_beetle_mossy", "mat": "prop", "pos": b, "rot": 4 + (i * 5) % 12})
	views["ruin"] = views["ruin"] + extra
	keep_props = [e for e in extra if e["id"].startswith("chest")]
	for k in ("wood", "stone"):
		if k in views:
			views[k] = views[k] + keep_props
	json.dump({"views": views}, open(page / "bp.json", "w"), separators=(",", ":"))
	cost = {"wood": [{"id": p["id"], "mat": p["mat"]} for p in new_w], "stone": [{"id": p["id"], "mat": p["mat"]} for p in new_s]}
	json.dump(cost, open(page / "new_pieces.json", "w"), separators=(",", ":"))
	SRC = {"chest_stone": "assets/models/stations/chest_stone.glb", "chest_copper": "assets/models/stations/chest_copper.glb",
		"rock_beetle_mossy": "assets/models/creatures/rock_beetle_mossy.glb"}
	NEWDIR = GAME / "journey" / "stonehold_v2" / "glb"   # the new Spire models (not in the game until the owner's OK)
	for v in views.values():
		for p in v:
			key = p["id"] if p["mat"] == "prop" else f"{p['id']}__{p['mat']}"
			f = page / "m" / f"{key}.json"
			if f.exists():
				continue
			src = GAME / SRC[p["id"]] if p["id"] in SRC else GAME / f"assets/models/build/{key}.glb"
			if not src.exists():
				src = NEWDIR / f"{key}.glb"
			dat = src.read_bytes()
			n = struct.unpack("<I", dat[12:16])[0]
			g = json.loads(dat[20:20 + n])
			b = dat[20 + n + 8:]
			g["buffers"] = [{"byteLength": len(b), "uri": "data:application/octet-stream;base64," + base64.b64encode(b).decode()}]
			f.write_text(json.dumps(g, separators=(",", ":")))
	print("page files written:", {k: len(v) for k, v in views.items()}, "new:", len(new_w), "wood,", len(new_s), "stone")
