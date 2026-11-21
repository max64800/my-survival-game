# The RUINED Stone Outpost (the "Fallen Outpost", owner Nov 17): made from the real blueprint, then broken.
#   godot --headless --path . -s res://tools/dump_blueprint.gd -- stone_outpost_grid <outpost.json>
#   (the grid layout: this script slides it the way the Stone Outpost blueprint is lined up, BlueprintLibrary._outpost_line_up)
#   python tools/ruins/make_outpost_ruin.py <outpost.json> [page=<folder>]
# Writes blueprints/ruins/outpost_ruin.json (pieces, chests with loot, beetle spots) for the world to place, and
# with page=<folder> the 3D preview page's files. Same damage ideas as the watchtower ruin: no doors (two lie
# smashed by the gate), worn walls with stones out, collapsed walls, breaches in the curtain wall with rubble, part of
# the barracks roof and a gatehouse roof fallen in, battlements missing, a shed pillar down. No rubble in doorways or
# on/in front of steps (owner: rubble blocked the watchtower's door).
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
rng = random.Random(7)


def steps(rot):
	return rot * 3 if rot < 4 else rot - 4


def near(p, x, z, r=0.6):
	return abs(p["pos"][0] - x) < r and abs(p["pos"][2] - z) < r


# (kept away from the walkway, its stairs and landings, so nothing up there is left hanging)
BREACH = [(-14, 1), (3, -14), (14, 5)]                              # whole curtain-wall cells gone (both levels)
BREACH_TOP = [(14, 3), (7, -14), (14, -3)]                          # only the top level gone
ROOF_GONE = [(-3, -11), (-1, -11), (-3, -9), (3, 11), (3, 13), (5, 11)]   # roofs that fell in
FLOOR_GONE = [(-3, -11)]                                            # and a barracks floor under one of them
pieces = []
for p in bp["pieces"]:
	x, y, z = p["pos"]
	y = round(y, 2)
	pid = p["id"]
	q = {"id": pid, "mat": p["mat"], "pos": [round(x, 4), y, round(z, 4)], "rot": p["rot"]}
	if pid in ("door", "gate_leaf"):
		continue                                                    # doors gone; the gate lies torn down outside
	on_curtain = (abs(abs(z) - 14) < 0.1 or abs(abs(x) - 14) < 0.1)
	if pid in ("wall", "battlement") and on_curtain:
		if any(near(p, bx, bz) for bx, bz in BREACH):
			continue
		if any(near(p, bx, bz) for bx, bz in BREACH_TOP) and y >= 2.0:
			continue
	if pid in ("floor",) and y >= 4.0 and any(near(p, rx, rz) for rx, rz in ROOF_GONE):
		continue
	if pid == "floor" and y == 3.0 and any(near(p, rx, rz) for rx, rz in FLOOR_GONE):
		continue
	if pid == "floor" and y == 2.25 and near(p, 11, -1):
		continue                                                    # a hole in the forge's roof
	if pid == "pillar" and near(p, 10, -2):
		continue                                                    # a forge pillar fell
	if pid == "battlement" and rng.random() < 0.45:
		continue
	if pid in ("wall", "window_wall"):
		r = rng.random()
		if y >= 2.0 and r < 0.12:
			q["id"] = "ruin_wall_collapsed"
			if rng.random() < 0.5:
				q["rot"] = q["rot"] + 2 if q["rot"] < 2 else q["rot"] - 2   # the broken end on the other side
		elif r < 0.45:
			q["id"] = "ruin_wall_worn"
	pieces.append(q)

# Nothing may stand on a wall that collapsed (owner: a floating stone): drop the battlements and walls on top of one.
WALLISH = ("wall", "window_wall", "doorway", "ruin_wall_worn", "ruin_wall_collapsed", "battlement")
changed = True
while changed:
	changed = False
	low = [p for p in pieces if p["id"] == "ruin_wall_collapsed"]
	for p in list(pieces):
		if p["id"] in WALLISH and any(abs(c["pos"][0] - p["pos"][0]) < 0.1 and abs(c["pos"][2] - p["pos"][2]) < 0.1
				and any(abs(p["pos"][1] - c["pos"][1] - dy) < 0.02 for dy in (2.0, 2.25, 2.5)) for c in low):
			pieces.remove(p)
			changed = True


# Owner, Nov 17: line the ruin up with its round towers. A 12-sided tower can't match the 2 m grid on two sides, so
# here (the wall is broken anyway) two parts slide: the whole front (gate, gatehouse, front wall, front-right tower,
# and the right wall up to the breach) moves 0.73 m out and 0.27 m left, so the front walkway meets the front-left
# round tower's flat side exactly; the right wall from the breach back (with its walkway and the armoury/forge
# against it) moves 0.73 m out and 0.27 m back, to meet the back-right round tower the same way.
FRONT = (-0.27, 0.73)
RIGHT = (0.73, -0.27)
RT_BACK = (13.732, -13.0)


def part_of(pid, x, z):
	if pid == "pillar" and (near_xz(x, z, -9.1, 14) or near_xz(x, z, 14, -9.1)):
		return "gone"                                   # the posts that closed the old 27 cm seams
	if (x > -9.35 and z >= 7.9) or (pid == "foundation_steps" and near_xz(x, z, 11, 7)) or (x >= 13.9 and 5.9 <= z < 7.9):
		return "front"
	if x >= 9.9 and -9.35 <= z < 4.5 and math.hypot(x - RT_BACK[0], z - RT_BACK[1]) > 4.0:
		return "right"
	return ""


def near_xz(x, z, px, pz, r=0.2):
	return abs(x - px) < r and abs(z - pz) < r


def slide(p, key="pos"):
	part = part_of(p.get("id", ""), p[key][0], p[key][2])
	if part == "gone":
		return False
	if part:
		d = FRONT if part == "front" else RIGHT
		p[key] = [round(p[key][0] + d[0], 4), p[key][1], round(p[key][2] + d[1], 4)]
	return True


pieces = [p for p in pieces if slide(p)]


def add(pid, x, y, z, yaw_deg, mat="cut_stone"):
	q = {"id": pid, "mat": mat, "pos": [round(x, 3), y, round(z, 3)], "rot": 4 + round(yaw_deg / 30) % 12}
	if slide(q):                                        # (rubble and props move with the part they lie in)
		pieces.append(q)


# Rubble where things fell: at each breach (inside and out), under the fallen roofs, by the fallen pillar; never in
# a doorway, on steps or stairs, or in the training yard.
spots = [(-15.6, 1.2, 0), (-11.2, 1.6, 0), (3, -15.8, 0), (15.6, 5, 0), (12.3, 5.4, 0), (-3, -11, 1.0), (-5, -10.4, 1.0),
	(4.2, 12.4, 0), (11.4, -1.6, 0.25), (9.0, -2.6, 0), (5.5, 4.5, 0), (2.6, -4.5, 0), (16.2, -3, 0), (7, -15.7, 0)]
for (x, z, y) in spots:
	add("ruin_rubble", x, y, z, rng.randrange(0, 360))
add("gate_broken", -4.2, 0.0, 16.4, 75)                            # the gate's two leaves, torn off and lying flat
add("gate_broken", 4.4, 0.0, 16.8, 110)                            # on the ground, one each side of the way in

chests = [
	{"kind": "chest_stone", "pos": [-7.0, 1.0, -13.0], "yaw": 0, "loot": {"recipe_page": 1, "rope": 3}},          # barracks A
	{"kind": "chest_small", "pos": [-13.0, 3.25, -1.0], "yaw": 90, "loot": {"recipe_page": 1}},                   # barracks B, upstairs
	{"kind": "chest_copper", "pos": [12.8, 0.25, -3.6], "yaw": 270, "loot": {"recipe_page": 2, "blueprint_page": 1}},  # the armoury
	{"kind": "chest_small", "pos": [-4.0, 0.0, 12.6], "yaw": 180, "loot": {"recipe_page": 1}},                    # the left gatehouse tower
	{"kind": "chest_copper", "pos": [-10.4, 5.5, -12.9], "yaw": 0, "loot": {"outpost_plans": 1, "recipe_page": 1}},  # the back tower's roof, one cell along from the stairs' top (owner, Nov 22: it stood on the stairs)
	{"kind": "barrel", "pos": [-6.0, 1.0, -12.6], "yaw": 0, "loot": {}},                                          # storage barrels
	{"kind": "barrel", "pos": [-12.5, 1.0, -1.0], "yaw": 0, "loot": {}},
	{"kind": "barrel", "pos": [13.0, 0.25, -5.4], "yaw": 0, "loot": {}},
]
beetles = [[-4.0, 1.0, -10.0], [-11.0, 1.0, -4.0], [12.0, 0.25, -1.0], [3.0, 0.0, 0.0], [-11.0, 5.5, -11.0], [13.0, 3.25, 13.0]]
props = [{"model": "crate_stack", "pos": [12.8, 0.25, 1.0], "yaw": 0}, {"model": "grain_sacks", "pos": [-12.8, 1.0, -6.0], "yaw": 90}]
for c in chests + props:
	slide(c)
beetles = [b for b in beetles]
for i, b in enumerate(beetles):
	q = {"pos": b}
	slide(q)
	beetles[i] = q["pos"]

out = GAME / "blueprints" / "ruins" / "outpost_ruin.json"
json.dump({"name": "Fallen Outpost", "radius": 18.5, "height": 7.5, "front": 18.5, "square": True, "pieces": pieces,
	"chests": chests, "beetles": beetles, "props": props}, open(out, "w", encoding="utf-8"), separators=(",", ":"))
counts = {}
for p in pieces:
	counts[p["id"]] = counts.get(p["id"], 0) + 1
print("WROTE", out.name, len(pieces), "pieces,", len(chests), "chests;", counts)

if page:
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
		f = page / "m" / f"{p['id']}.json"
		if f.exists():
			continue
		dat = (GAME / SRC.get(p["id"], f"assets/models/build/{p['id']}__{p['mat']}.glb")).read_bytes()
		n = struct.unpack("<I", dat[12:16])[0]
		g = json.loads(dat[20:20 + n])
		b = dat[20 + n + 8:]
		g["buffers"] = [{"byteLength": len(b), "uri": "data:application/octet-stream;base64," + base64.b64encode(b).decode()}]
		f.write_text(json.dumps(g, separators=(",", ":")))
	print("page files written")
