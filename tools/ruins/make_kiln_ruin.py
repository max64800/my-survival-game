# The RUINED Old Kiln (owner, Nov 21, F479: ruin 5 of Zone 1): made from the real blueprint, then broken.
#   godot --headless --path . -s res://tools/dump_blueprint.gd -- hearthbrick_kiln <brick.json>
#   godot --headless --path . -s res://tools/dump_blueprint.gd -- wooden_kiln <wood.json>
#   python tools/ruins/make_kiln_ruin.py <brick.json> [wood=<wood.json>] [page=<folder>]
# Writes blueprints/ruins/kiln_ruin.json (pieces, chests with loot, beetle spots) for the world to place.
# The ruin is the blueprint piece for piece (so it rebuilds on the very same spots). What happened: a piece of the
# kiln's rim broke off on its right side (yaw 90 degrees) and fell across the lean-to shed, crushing its roof; it lies
# past the shed (kiln_rim_fallen). The kiln's upper walls there are broken down, the gallery floor has a hole where a
# triangle fell in, most of the rim is gone. The kiln's last load of bricks still stands toppled on its firing floor
# (brick_stack_toppled), another in the yard. The house's roof caved in at its left end, taking the upper floor's
# front corner with it; its walls worn, doors gone, two of the yard's half walls fallen.
# No rubble in doorways, on steps or stairs (owner, Nov 17). A flat clear base space round it (owner, Nov 21).
# With page=<folder> (and wood=): the 3D page's files: the ruin, rebuilt in wood, rebuilt in brick, side by side,
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
rng = random.Random(5)

KX, KZ = 6.268, -1.0      # the kiln's middle (BlueprintLibrary._KILN)


def rot_from(steps):
	"""Pieces.rot_from_steps: quarter turns as 0-3, other 30 degree turns as 4 + steps."""
	k = steps % 12
	return k // 3 if k % 3 == 0 else 4 + k


def steps_of(rot):
	return rot * 3 if rot < 4 else rot - 4


def turned(rot):
	return rot_from(steps_of(rot) + 6)


def ring_j(x, z):
	"""Which of the kiln's 12 directions (30 degree steps, 0 = +z front) a spot lies in (a float)."""
	return (math.degrees(math.atan2(x - KX, z - KZ)) / 30.0) % 12


def in_kiln(x, z):
	return 0.0 < x < 10.5 and math.hypot(x - KX, z - KZ) < 4.9


def near(p, x, z, r=0.3):
	return abs(p["pos"][0] - x) < r and abs(p["pos"][2] - z) < r


WALLISH = ("wall", "window_wall", "window_wide", "doorway", "half_wall", "gable_26", "ruin_wall_worn", "ruin_wall_collapsed")
ROOF_GONE_X = (-13, -11)                  # the house roof caved in at its left end
UPPER_FLOOR_GONE = [(-13, 1), (-13, -1)]  # and took the upper floor's front-left corner with it
YARD_GONE = [(-5, 8), (-3, 8)]            # two of the yard's half walls fell
pieces = []
for p in bp["pieces"]:
	x, y, z = p["pos"]
	y = round(y, 2)
	pid = p["id"]
	q = {"id": pid, "mat": p["mat"], "pos": [round(x, 4), y, round(z, 4)], "rot": p["rot"]}
	if pid == "door":
		continue                                                    # doors gone
	if in_kiln(x, z):
		j = round(ring_j(x, z)) % 12
		if pid == "half_wall" and y > 5.0 and j not in (6, 7, 8, 9, 10, 11, 0):
			continue                                                # most of the rim is gone
		if 3.1 < y < 3.4 and pid in ("wall", "window_wall"):
			if j in (2, 3, 4):
				q["id"] = "ruin_wall_collapsed"                    # broken down where the rim chunk tore away,
				if j == 2:                                          # high ends away from the break
					q["rot"] = turned(p["rot"])
			elif rng.random() < 0.4:
				q["id"] = "ruin_wall_worn"
		if pid == "pillar" and 3.1 < y < 3.4:
			c = int(round(ring_j(x, z) - 0.5)) % 12                 # corner c sits between edges c and c+1
			if c in (2, 3):
				continue
		if pid == "floor_triangle" and 2.9 < y < 3.1 and j == 3:
			continue                                                # the gallery's hole where a triangle fell in
		if 0.9 < y < 1.1 and pid == "wall" and rng.random() < 0.35:
			q["id"] = "ruin_wall_worn"
		pieces.append(q)
		continue
	if x > 10.0:                                                    # the shed: crushed by the falling rim
		if pid in ("roof_26", "pillar"):
			continue
		if pid == "gable_26" and y > 3.5:
			continue
		if pid == "wall" and abs(x - 14) < 0.1:
			q["id"] = "ruin_wall_collapsed"                        # (its high right end already at the back, z -2)
		pieces.append(q)
		continue
	# the house and the yard
	if pid in ("roof_26",) and any(abs(x - rx) < 0.1 for rx in ROOF_GONE_X):
		continue
	if pid == "floor" and abs(y - 3.0) < 0.05 and any(near(p, fx, fz) for fx, fz in UPPER_FLOOR_GONE):
		continue
	if pid == "half_wall" and y < 0.1 and any(near(p, hx, hz) for hx, hz in YARD_GONE):
		continue
	if pid in ("wall", "window_wall"):
		if 3.1 < y < 3.4 and (near(p, -13, 2) or near(p, -14, 1)):
			q["id"] = "ruin_wall_collapsed"                        # the front-left corner upstairs fell in
			                                                        # (both high right ends already point away from it)
		elif rng.random() < 0.38:
			q["id"] = "ruin_wall_worn"
	pieces.append(q)

# Nothing may stand on a wall that collapsed (owner: a floating stone): drop what stood on top of one.
changed = True
while changed:
	changed = False
	low = [p for p in pieces if p["id"] == "ruin_wall_collapsed"]
	for p in list(pieces):
		if p["id"] in WALLISH + ("pillar",) and any(abs(c["pos"][0] - p["pos"][0]) < 0.1 and abs(c["pos"][2] - p["pos"][2]) < 0.1
				and any(abs(p["pos"][1] - c["pos"][1] - dy) < 0.02 for dy in (1.0, 2.0, 2.25)) for c in low):
			pieces.remove(p)
			changed = True
# ... and no gable or half wall hangs in the air where the roof beside it is gone (the left end's gable tops)
for p in list(pieces):
	if p["id"] in ("gable_26", "half_wall") and p["pos"][1] > 5.0 and abs(p["pos"][0] + 14) < 0.1:
		if p["pos"][1] > 6.0 or p["pos"][2] > 0:
			pieces.remove(p)


def add(pid, x, y, z, yaw_deg, mat="clay_brick"):
	pieces.append({"id": pid, "mat": mat, "pos": [round(x, 3), y, round(z, 3)], "rot": rot_from(round(yaw_deg / 30))})


def kiln_spot(step, d, y):
	a = math.radians(step * 30)
	return KX + math.sin(a) * d, y, KZ + math.cos(a) * d


# The rim chunk: fell outward to the right, over the shed, its broken-off top farthest out (the model's top points +z
# before turning: yaw 90 turns it to +x). Its near edge just past the shed's end wall.
add("kiln_rim_fallen", 16.1, 0.0, -1.2, 90)
# The kiln's last load of bricks on the firing floor (in the open middle, clear of the doors and the stairs' foot),
# another stack in the yard (clear of the path from the gate to the door, x -10..-8).
add("brick_stack_toppled", KX - 0.1, 1.0, KZ + 0.2, 0)
add("brick_stack_toppled", -12.0, 0.0, 6.0, 30)
# Rubble where things fell: under the gallery's hole, on the gallery by the broken walls, in the shed, under the
# house's fallen corner (upstairs and down), where the yard walls fell. Never in a doorway, on steps or stairs.
for (x, y, z) in [kiln_spot(2.0, 2.4, 1.0), kiln_spot(4.0, 2.75, 3.25), (12.3, 1.0, -1.1), (15.2, 0.0, 2.6),
		(-13.0, 1.0, 0.7), (-13.0, 3.25, -4.6), (-4.0, 0.0, 7.4), (-9.6, 3.25, 1.0)]:
	add("ruin_rubble", x, y, z, rng.randrange(0, 360))

chests = [
	{"kind": "chest_stone", "pos": [-3.0, 1.0, -5.2], "yaw": 0, "loot": {"recipe_page": 1, "rope": 2}},          # the house
	{"kind": "chest_small", "pos": [-7.0, 3.25, -5.2], "yaw": 0, "loot": {"recipe_page": 1}},                   # upstairs
	{"kind": "chest_copper", "pos": [round(KX, 3), 3.25, round(KZ + 2.9, 3)], "yaw": 180,                        # the kiln's
		"loot": {"recipe_page": 2, "blueprint_page": 1}},                                                        # gallery
]
props = []
beetles = [[KX - 1.6, 1.0, KZ + 1.9], [-7.0, 1.0, -1.0], [-6.0, 0.0, 5.0], [12.0, 0.0, 3.0]]

out = GAME / "blueprints" / "ruins" / "kiln_ruin.json"
json.dump({"name": "Old Kiln", "radius": 15.5, "height": 7.5, "front": 9.5, "square": True, "reach": 18.0,
	"pieces": pieces, "chests": chests, "beetles": beetles, "props": props}, open(out, "w", encoding="utf-8"), separators=(",", ":"))
counts = {}
for p in pieces:
	counts[p["id"]] = counts.get(p["id"], 0) + 1
print("WROTE", out.name, len(pieces), "pieces,", len(chests), "chests;", counts)


# ---------------------------------------------------------------- the rebuilds (builder.gd's rules)
DEBRIS = ("ruin_rubble", "kiln_rim_fallen", "brick_stack_toppled", "ruin_wall_collapsed")


def same_here(p, ruin):
	return next((q for q in ruin if q["id"] == p["id"] and q["rot"] == p["rot"]
		and sum((a - b) ** 2 for a, b in zip(q["pos"], p["pos"])) < 0.05 ** 2), None)


def rebuild(plan, wood):
	"""-> (pieces shown, new pieces). Whole ruin pieces stay; in wood, worn walls stay too unless something new
	stands right on top of one (1.9 to 2.35 m above: RuinTower.worn_over, Hearthbrick floors are 2.25 m apart)."""
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
	return [{"id": p["id"], "mat": p["mat"], "pos": [round(v, 4) for v in p["pos"]], "rot": p["rot"]} for p in b["pieces"]]


if page:
	(page / "m").mkdir(parents=True, exist_ok=True)
	views = {"ruin": pieces}
	views["brick"], new_b = rebuild(plan_of(bp), False)
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
	for k in ("wood", "brick"):
		if k in views:
			views[k] = views[k] + keep_props
	json.dump({"views": views}, open(page / "bp.json", "w"), separators=(",", ":"))
	json.dump({"wood": [{"id": p["id"], "mat": p["mat"]} for p in new_w], "brick": [{"id": p["id"], "mat": p["mat"]} for p in new_b]},
		open(page / "new_pieces.json", "w"), separators=(",", ":"))
	SRC = {"chest_stone": "assets/models/stations/chest_stone.glb", "chest_small": "assets/models/stations/chest_small.glb",
		"chest_copper": "assets/models/stations/chest_copper.glb", "rock_beetle_mossy": "assets/models/creatures/rock_beetle_mossy.glb"}
	NEWDIR = GAME / "journey" / "hearthbrick_v2" / "glb"   # the new kiln models (not in the game until the owner's OK)
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
	print("page files written:", {k: len(v) for k, v in views.items()}, "new:", len(new_w), "wood,", len(new_b), "brick")
