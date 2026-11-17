# The RUINED Stone Watchtower (owner, Nov 17): made from the real blueprint, then broken.
#   godot --headless --path . -s res://tools/dump_blueprint.gd -- stone_watchtower <tower.json>
#   python tools/ruins/make_watchtower_ruin.py <tower.json> [page=<folder>]
# Writes blueprints/ruins/watchtower_ruin.json, which the game places in the first cave of a new world
# (src/world/ruin_tower.gd): building pieces (incl. the ruin pieces from builds/stonehold_v2.py), chests with their
# loot, and where beetles would live (the first-cave tower has none: owner). page=<folder> also writes the 3D
# preview page's files (bp.json + m/<piece>.json).
# The owner's notes, in order: no door (it lies split outside); worn walls with stones missing; much more ruined at
# the FRONT (floors 1 and 2) than the back, but floor 3 keeps its front so the top stairs stay covered; part of the
# roof and the top floor fallen in at the back; only three battlements left; rubble where things fell; a chest on
# every floor (the roof one holds the Watchtower Plans); beetles on floors 1 and 3 and the roof, none on floor 2.
import base64
import json
import math
import struct
import sys
from pathlib import Path

GAME = Path(__file__).resolve().parents[2]
args = sys.argv[1:]
tower = json.load(open(args[0], encoding="utf-8"))
page = next((Path(a[5:]) for a in args if a.startswith("page=")), None)


def steps(rot):
	return rot * 3 if rot < 4 else rot - 4


def dir_of(x, z):  # which of the 12 directions a spot is in (0 = the door's side)
	return round(math.degrees(math.atan2(x, z)) / 30) % 12


def at(st, r):  # a spot in direction `st` (12ths of a turn), r metres out
	a = st * math.pi / 6
	return math.sin(a) * r, math.cos(a) * r


WALL_1 = {1: "ruin_wall_collapsed", 11: "ruin_wall_collapsed~", 2: "ruin_wall_worn", 10: "ruin_wall_worn",
	3: "ruin_wall_worn", 9: "ruin_wall_worn", 5: "ruin_wall_worn", 7: "ruin_wall_worn"}
WALL_2 = {0: None, 1: "ruin_wall_collapsed", 11: "ruin_wall_collapsed~", 2: "ruin_wall_collapsed", 10: "ruin_wall_worn",
	6: "ruin_wall_collapsed", 5: "ruin_wall_worn", 7: "ruin_wall_worn", 3: "ruin_wall_worn", 9: "ruin_wall_worn"}
WALL_3 = {11: "ruin_wall_worn", 0: "ruin_wall_worn", 1: "ruin_wall_worn", 5: None, 6: None, 10: "ruin_wall_collapsed~",
	2: "ruin_wall_collapsed", 4: "ruin_wall_collapsed", 7: "ruin_wall_collapsed~", 3: "ruin_wall_worn", 8: "ruin_wall_worn",
	9: "ruin_wall_worn"}

pieces = []
for p in tower["pieces"]:
	x, y, z = p["pos"]
	y = round(y, 2)
	j = dir_of(x, z)
	r = math.hypot(x, z)
	q = {"id": p["id"], "mat": p["mat"], "pos": [round(x, 4), y, round(z, 4)], "rot": p["rot"]}
	pid = q["id"]
	if pid == "door":
		continue                                                    # no door: it lies broken outside
	if pid in ("wall", "window_wall"):
		table = {1.0: WALL_1, 3.25: WALL_2, 5.5: WALL_3}.get(y, {})
		if j in table:
			if table[j] is None:
				continue                                            # fallen out completely
			q["id"] = table[j].rstrip("~")
			if table[j].endswith("~"):                             # the broken end on the other side
				q["rot"] = 4 + (steps(q["rot"]) + 6) % 12
	if pid == "pillar":
		pj = round(math.degrees(math.atan2(x, z)) / 30 - 0.5) % 12   # the corner between directions pj and pj+1
		if (y == 5.5 and pj in (4, 5, 6)) or (y == 3.25 and pj in (11, 0, 5)) or (y == 1.0 and pj == 0):
			continue
	if y == 7.5 and pid in ("floor", "floor_triangle") and r > 1.5 and j in (5, 6):
		continue                                                    # the roof fell in at the back
	if y == 7.75 and pid == "battlement" and j not in (3, 8, 9):
		continue                                                    # only three battlements still stand
	if y == 5.25 and pid in ("floor_triangle", "floor") and r > 2.5 and j == 5:
		continue                                                    # a hole in the top floor
	if y == 3.0 and pid == "floor_triangle" and r > 2.5 and j == 1:
		continue                                                    # a hole in floor 2 by the front breach
	pieces.append(q)


def add(pid, x, y, z, yaw_deg, mat="cut_stone"):
	pieces.append({"id": pid, "mat": mat, "pos": [round(x, 4), y, round(z, 4)], "rot": 4 + round(yaw_deg / 30) % 12})


for (st, r, y, yaw) in ((0.6, 2.6, 1.0, 10), (1.0, 2.7, 3.25, 80), (11.3, 2.5, 3.25, 200), (5.5, 2.4, 5.5, 20),
		(5.0, 2.6, 3.25, 70), (1.2, 2.5, 1.0, 140), (6, 5.0, 0.0, 0), (5.3, 5.4, 0.0, 120), (0.9, 5.3, 0.0, 40),
		(11.2, 5.2, 0.0, 300), (1.6, 5.6, 0.0, 200), (0.0, 6.6, 0.0, 90)):
	add("ruin_rubble", *at(st, r)[:1], y, at(st, r)[1], yaw)
add("door_broken", 2.3, 0.0, 6.0, 30)
add("barrel", *at(9.6, 2.9)[:1], 1.0, at(9.6, 2.9)[1], 0, "plank_root")
add("barrel", *at(11, 2.8)[:1], 3.25, at(11, 2.8)[1], 0, "plank_root")

# Chests: kind, spot, which way they face, and what's inside (rare finds only, like other ruins: F102).
chests = [
	{"kind": "chest_stone", "pos": [*at(6, 2.55)[:1], 1.0, at(6, 2.55)[1]], "yaw": 0, "loot": {"recipe_page": 1, "dish_hollowcap_stew": 1}},
	{"kind": "chest_small", "pos": [*at(8, 2.6)[:1], 3.25, at(8, 2.6)[1]], "yaw": 60, "loot": {"rope": 2}},
	{"kind": "chest_small", "pos": [*at(10, 2.6)[:1], 5.5, at(10, 2.6)[1]], "yaw": 120, "loot": {"recipe_page": 1}},
	{"kind": "chest_copper", "pos": [*at(2, 1.0)[:1], 7.75, at(2, 1.0)[1]], "yaw": 210, "loot": {"watchtower_plans": 1, "recipe_page": 1}},
]
beetles = [[*at(st, r)[:1], y, at(st, r)[1]] for (st, r, y) in ((7.5, 1.5, 1.0), (8.5, 1.7, 5.5), (9.5, 2.0, 7.75))]
props = [{"model": "crate_stack", "pos": [*at(3.4, 2.7)[:1], 1.0, at(3.4, 2.7)[1]], "yaw": 200},
	{"model": "grain_sacks", "pos": [*at(8.6, 2.6)[:1], 1.0, at(8.6, 2.6)[1]], "yaw": 60}]

out = GAME / "blueprints" / "ruins" / "watchtower_ruin.json"
json.dump({"name": "Watchtower Ruin", "radius": 4.2, "height": 9.0, "front": 6.8, "pieces": pieces, "chests": chests,
	"beetles": beetles, "props": props}, open(out, "w", encoding="utf-8"), indent=0, separators=(",", ":"))
counts = {}
for p in pieces:
	counts[p["id"]] = counts.get(p["id"], 0) + 1
print("WROTE", out.name, len(pieces), "pieces,", len(chests), "chests;", counts)

if page:  # the 3D preview page: pieces + chests + props + beetles as plain models
	(page / "m").mkdir(parents=True, exist_ok=True)
	view = [dict(p) for p in pieces]
	for c in chests:
		view.append({"id": c["kind"], "mat": "prop", "pos": c["pos"], "rot": 4 + round(c["yaw"] / 30) % 12})
	for pr in props:
		view.append({"id": pr["model"], "mat": "prop", "pos": pr["pos"], "rot": 4 + round(pr["yaw"] / 30) % 12})
	for i, b in enumerate(beetles):
		view.append({"id": "rock_beetle_mossy", "mat": "prop", "pos": b, "rot": 4 + (i * 5) % 12})
	json.dump({"pieces": view}, open(page / "bp.json", "w"), separators=(",", ":"))
	SRC = {"chest_stone": "assets/models/stations/chest_stone.glb", "chest_small": "assets/models/stations/chest_small.glb",
		"chest_copper": "assets/models/stations/chest_copper.glb", "crate_stack": "assets/models/decor/crate_stack.glb",
		"grain_sacks": "assets/models/decor/grain_sacks.glb", "rock_beetle_mossy": "assets/models/creatures/rock_beetle_mossy.glb"}
	for p in view:
		pid = p["id"]
		f = page / "m" / f"{pid}.json"
		if f.exists():
			continue
		path = GAME / SRC.get(pid, f"assets/models/build/{pid}__{p['mat']}.glb")
		dat = path.read_bytes()
		n = struct.unpack("<I", dat[12:16])[0]
		g = json.loads(dat[20:20 + n])
		b = dat[20 + n + 8:]
		g["buffers"] = [{"byteLength": len(b), "uri": "data:application/octet-stream;base64," + base64.b64encode(b).decode()}]
		f.write_text(json.dumps(g, separators=(",", ":")))
	print("page files written")
