# The RUINED Brewhall (owner, Nov 20, F479: the third ruin): made from the real blueprint, then broken.
#   godot --headless --path . -s res://tools/dump_blueprint.gd -- hearthbrick_brewhall <brick.json>
#   godot --headless --path . -s res://tools/dump_blueprint.gd -- wooden_brewhall <wood.json>
#   python tools/ruins/make_brewhall_ruin.py <brick.json> [wood=<wood.json>] [page=<folder>]
# Writes blueprints/ruins/brewhall_ruin.json (pieces, chests with loot, beetle spots, props) for the world to place.
# The ruin is the blueprint piece for piece (so it rebuilds on the very same spots, test_blueprint_matches_its_ruin):
# the hall's roof caved in at the back end (with the loft floor under it and the back gable top), the chimney
# toppled across the yard railing (only its bottom 2 m stand), doors gone, worn and collapsed walls, smashed
# barrels, the cellar's back half full of rubble. No rubble in doorways, on steps or stairs (owner, Nov 17).
# With page=<folder> (and wood=): the 3D page's files: the ruin, rebuilt in wood, rebuilt in brick, side by side,
# each new piece marked (worked out with the game's rebuild rules, src/build/builder.gd "rebuilding ruins").
import base64
import json
import random
import struct
import sys
from pathlib import Path

GAME = Path(__file__).resolve().parents[2]
args = sys.argv[1:]
bp = json.load(open(args[0], encoding="utf-8"))
page = next((Path(a[5:]) for a in args if a.startswith("page=")), None)
wood_bp = next((json.load(open(a[5:], encoding="utf-8")) for a in args if a.startswith("wood=")), None)
rng = random.Random(11)


def near(p, x, z, r=0.3):
	return abs(p["pos"][0] - x) < r and abs(p["pos"][2] - z) < r


def at(p, pid, x, y, z):
	return p["id"] == pid and near(p, x, z) and abs(p["pos"][1] - y) < 0.05


ROOF_GONE = [(-7, -5), (-5, -5), (-3, -5), (-1, -5), (-5, -3), (-3, -3), (5, -5)]   # (the hall's back end; one wing cell)
LOFT_GONE = [(-5, -5), (-3, -5)]                                                    # the loft floor under it
COLLAPSED = [(-5, -6, 3.25), (-3, -6, 3.25)]                                        # the loft's back wall where it fell
RAIL_GONE = [(6, -1, 0.0), (6, 1, 0.0), (4, 3, 0.25)]                               # the chimney fell through the yard rail
NO_COLLAPSE_Z = (4,)                                                                # the front gable wall stays up
pieces = []
for p in bp["pieces"]:
	x, y, z = p["pos"]
	y = round(y, 2)
	pid = p["id"]
	q = {"id": pid, "mat": p["mat"], "pos": [round(x, 4), y, round(z, 4)], "rot": p["rot"]}
	if pid == "door":
		continue                                                    # doors gone
	if x > 6.1 and y >= 1.9:
		continue                                                    # the chimney: only its bottom level stands
	if pid == "roof_26" and any(near(p, rx, rz) for rx, rz in ROOF_GONE):
		continue
	if pid in ("gable_26", "half_wall") and near(p, -5, -6) and y > 5:
		continue                                                    # the back gable's top fell in with the roof
	if pid in ("gable_26", "half_wall") and near(p, -3, -6) and y > 5:
		continue
	if pid == "floor" and y == 3.0 and any(near(p, fx, fz) for fx, fz in LOFT_GONE):
		continue
	if pid == "railing" and any(at(p, "railing", rx, ry, rz) for rx, rz, ry in [(a, b, c) for a, b, c in RAIL_GONE]):
		continue
	if any(at(p, pid, cx, cy, cz) for cx, cz, cy in COLLAPSED) and pid in ("wall", "window_wall"):
		q["id"] = "ruin_wall_collapsed"
		q["rot"] = p["rot"] + 2 if p["rot"] < 2 else p["rot"] - 2   # the high end by the hall's side wall
	elif pid in ("wall", "window_wall"):
		r = rng.random()
		if y >= 3.0 and r < 0.12 and abs(z - 4) > 0.1:
			q["id"] = "ruin_wall_collapsed"
			if rng.random() < 0.5:
				q["rot"] = q["rot"] + 2 if q["rot"] < 2 else q["rot"] - 2
		elif r < 0.4:
			q["id"] = "ruin_wall_worn"
	pieces.append(q)

# Nothing may stand on a wall that collapsed (owner: a floating stone): drop what stood on top of one.
WALLISH = ("wall", "window_wall", "window_wide", "doorway", "half_wall", "gable_26", "ruin_wall_worn", "ruin_wall_collapsed")
changed = True
while changed:
	changed = False
	low = [p for p in pieces if p["id"] == "ruin_wall_collapsed"]
	for p in list(pieces):
		if p["id"] in WALLISH and any(abs(c["pos"][0] - p["pos"][0]) < 0.1 and abs(c["pos"][2] - p["pos"][2]) < 0.1
				and any(abs(p["pos"][1] - c["pos"][1] - dy) < 0.02 for dy in (2.0, 2.25)) for c in low):
			pieces.remove(p)
			changed = True


def add(pid, x, y, z, yaw_deg, mat="clay_brick"):
	pieces.append({"id": pid, "mat": mat, "pos": [round(x, 3), y, round(z, 3)], "rot": 4 + round(yaw_deg / 30) % 12})


# Rubble where things fell: under the caved-in roof (hall floor and loft), the cellar's front half (two heaps on
# top; its stairs are at the back); never in a doorway, on steps or stairs, or on the cellar stairs' landing.
for (x, y, z) in [(-4.4, 1.0, -4.7), (-2.2, 1.0, -5.1), (-6.4, 1.0, -5.0), (-6.6, 3.25, -3.6), (-1.6, 3.25, -4.4),
		(3.0, -1.25, -3.0), (4.3, -1.25, -3.0), (5.3, -1.25, -3.0), (3.6, -0.8, -3.0), (4.9, -0.8, -3.0)]:
	add("ruin_rubble", x, y, z, rng.randrange(0, 360))
add("chimney_fallen", 6.839, 0.0, -0.71, 330)   # toppled toward the front left over the yard rail (its middle: its foot
                                                  # at (7.86, -2.8), the model centred 2.32 m along it)
for (x, y, z, yaw) in [(5.2, 1.0, -3.0, 30), (-2.5, 1.0, -3.2, 200), (-1.5, 1.0, 2.9, 120)]:
	add("barrel_smashed", x, y, z, yaw, mat="plank_root")          # smashed barrels: rubble you hit to clear

chests = [
	{"kind": "chest_stone", "pos": [-7.2, 1.0, -2.8], "yaw": 90, "loot": {"recipe_page": 1, "rope": 3}},         # the hall
	{"kind": "chest_small", "pos": [-7.2, 3.25, 2.6], "yaw": 90, "loot": {"recipe_page": 1}},                    # the loft
	{"kind": "chest_copper", "pos": [5.5, -1.25, -5.5], "yaw": 270, "loot": {"recipe_page": 2, "blueprint_page": 1}},  # the cellar
	{"kind": "barrel", "pos": [-1.4, 1.0, -5.4], "yaw": 0, "loot": {}},                                         # the hall's barrel
]
props = []   # (ruins don't place props yet: the smashed barrels are pieces above)
beetles = [[-3.0, 1.0, -1.0], [2.6, 0.0, -0.4], [-2.0, 3.25, 1.6], [5.0, -1.25, -4.8]]

out = GAME / "blueprints" / "ruins" / "brewhall_ruin.json"
json.dump({"name": "Brewhall", "radius": 8.6, "height": 8.0, "front": 6.5, "square": True, "pieces": pieces,
	"chests": chests, "beetles": beetles, "props": props}, open(out, "w", encoding="utf-8"), separators=(",", ":"))
counts = {}
for p in pieces:
	counts[p["id"]] = counts.get(p["id"], 0) + 1
print("WROTE", out.name, len(pieces), "pieces,", len(chests), "chests;", counts)


# ---------------------------------------------------------------- the rebuilds (builder.gd's rules)
DEBRIS = ("ruin_rubble", "chimney_fallen", "ruin_wall_collapsed", "barrel_smashed")


def same_here(p, ruin):
	return next((q for q in ruin if q["id"] == p["id"] and q["rot"] == p["rot"]
		and sum((a - b) ** 2 for a, b in zip(q["pos"], p["pos"])) < 0.05 ** 2), None)


def rebuild(plan, wood):
	"""-> (pieces shown, new pieces). Whole ruin pieces stay; in wood, worn walls stay too unless something new
	stands right on top of one (2 m above)."""
	ruin = [q for q in pieces if q["id"] not in DEBRIS]
	kept, new = [], []
	news = [p for p in plan if not same_here(p, ruin)]
	go = set()
	if wood:
		for i, q in enumerate(ruin):
			if q["id"] == "ruin_wall_worn" and any(1.9 < a["pos"][1] - q["pos"][1] < 2.1 and abs(a["pos"][0] - q["pos"][0]) < 0.1
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


if page:
	(page / "m").mkdir(parents=True, exist_ok=True)
	plan_b = [{"id": p["id"], "mat": p["mat"], "pos": [round(v, 4) for v in p["pos"]], "rot": p["rot"]} for p in bp["pieces"]]
	views = {"ruin": pieces, "brick": rebuild(plan_b, False)[0]}
	new_b = rebuild(plan_b, False)[1]
	new_w = []
	if wood_bp:
		plan_w = [{"id": p["id"], "mat": p["mat"], "pos": [round(v, 4) for v in p["pos"]], "rot": p["rot"]} for p in wood_bp["pieces"]]
		views["wood"], new_w = rebuild(plan_w, True)
	extra = []
	for c in chests:
		extra.append({"id": c["kind"], "mat": "prop", "pos": c["pos"], "rot": 4 + round(c["yaw"] / 30) % 12})
	for pr in props:
		extra.append({"id": pr["model"], "mat": "prop", "pos": pr["pos"], "rot": 4 + round(pr["yaw"] / 30) % 12})
	for i, b in enumerate(beetles):
		extra.append({"id": "rock_beetle_mossy", "mat": "prop", "pos": b, "rot": 4 + (i * 5) % 12})
	views["ruin"] = views["ruin"] + extra
	keep_props = [e for e in extra if e["id"].startswith("chest") or e["id"] == "barrel"]
	for k in ("wood", "brick"):
		if k in views:
			views[k] = views[k] + keep_props
	json.dump({"views": views, "new": {"wood": [p["id"] + "__" + p["mat"] for p in new_w], "brick": [p["id"] + "__" + p["mat"] for p in new_b]}},
		open(page / "bp.json", "w"), separators=(",", ":"))
	json.dump({"wood": [{"id": p["id"], "mat": p["mat"]} for p in new_w], "brick": [{"id": p["id"], "mat": p["mat"]} for p in new_b]},
		open(page / "new_pieces.json", "w"), separators=(",", ":"))
	SRC = {"chest_stone": "assets/models/stations/chest_stone.glb", "chest_small": "assets/models/stations/chest_small.glb",
		"chest_copper": "assets/models/stations/chest_copper.glb", "barrel": "assets/models/stations/barrel_box.glb",
		"keg": "assets/models/decor/keg.glb", "tavern_table": "assets/models/decor/tavern_table.glb",
		"furn_stool": "assets/models/decor/furn_stool.glb", "rock_beetle_mossy": "assets/models/creatures/rock_beetle_mossy.glb"}
	NEWDIR = GAME / "journey" / "hearthbrick_v2" / "glb"   # the new ruin models (not in the game until the owner's OK)
	for v in views.values():
		for p in v:
			key = p["id"] if p["mat"] == "prop" else f"{p['id']}__{p['mat']}"
			f = page / "m" / f"{key}.json"
			if f.exists():
				continue
			src = GAME / SRC[p["id"]] if p["id"] in SRC else GAME / f"assets/models/build/{key}.glb"
			if not src.exists():
				src = NEWDIR / (f"{p['id']}.glb" if p["mat"] == "prop" else f"{key}.glb")
			dat = src.read_bytes()
			n = struct.unpack("<I", dat[12:16])[0]
			g = json.loads(dat[20:20 + n])
			b = dat[20 + n + 8:]
			g["buffers"] = [{"byteLength": len(b), "uri": "data:application/octet-stream;base64," + base64.b64encode(b).decode()}]
			f.write_text(json.dumps(g, separators=(",", ":")))
	print("page files written:", {k: len(v) for k, v in views.items()}, "new:", len(new_w), "wood,", len(new_b), "brick")
