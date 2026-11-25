# The 3D page of Brickcrown Keep (owner, Nov 25: ruin 11, F895), before its ruin is in the game: an old Stonehold
# stone fort built higher in Hearthbrick brick. Two views: a first ruin of it (what fell, what still stands) and the
# blueprint whole. No wooden rebuild (owner didn't ask for one).
#   godot --headless --audio-driver Dummy --path . -s res://tools/dump_blueprint.gd -- brickcrown_keep <b.json> <b_kinds.json>
#   python tools/ruins/make_brickcrown_page.py <b.json> <page folder> <b_kinds.json>
# Copies tools/ruins/brickcrown_page.html into the folder as index.html. Made from make_smeltery_page.py; the ruin is a
# sketch for the owner's OK, the game's real ruin (chests, junk, creatures) comes after.
import base64
import json
import math
import random
import shutil
import struct
import sys
from pathlib import Path

GAME = Path(__file__).resolve().parents[2]
bp, page = json.load(open(sys.argv[1], encoding="utf-8")), Path(sys.argv[2])
(page / "m").mkdir(parents=True, exist_ok=True)
whole = [{"id": p["id"], "mat": p["mat"], "pos": [round(v, 4) for v in p["pos"]], "rot": p["rot"]} for p in bp["pieces"]]

# The parts, after the blueprint's shift (BlueprintLibrary.BRICK_SHIFT (-6, 2.25, 6)); the cave floor is at y 2.25.
SHIFT = (-6.0, 2.25, 6.0)
LEFT, RIGHT = (-16.732, 4.0), (16.732, 2.0)   # the two round towers
G = 2.25
# How high each part still stands: pieces above are gone, the top BAND m left is broken up. The keep loses its brick
# roof and the top of its brick 4th storey; the left tower's brick neck is broken; the stone stands.
CUT = {"keep": G + 11.9, "left": G + 12.6, "right": G + 12.2, "curtain": G + 8.1, "yard": 99, "bridge": 99}
BAND = {"keep": 2.0, "left": 1.6, "right": 0.6, "curtain": 0.6}


def dist(a, b):
	return math.hypot(a[0] - b[0], a[1] - b[1])


def part(x, z, y):
	lx, lz = x - SHIFT[0], z - SHIFT[2]
	if dist((x, z), LEFT) < 4.2 and x < -13.1:   # (the ring's walls reach 3.7 m out)
		return "left"
	if dist((x, z), RIGHT) < 4.2 and x > 13.1:
		return "right"
	if 10.5 < lx < 15.5 and lz > -2.4:
		return "bridge"
	if lz < -11.4 or (lx > 7.6 and lz < -5.6 and y < G + 5):
		return "yard"
	if lx > 7.4:
		return "curtain"
	return "keep"


WALLISH = ("wall", "window_wall", "window_wide", "doorway", "sloped_wall", "gable_45")
rng = random.Random(11)
ruin, rubble, standing = [], [], set()
for i, p in enumerate(whole):
	x, y, z = p["pos"]
	k = part(x, z, y)
	cut = CUT[k]
	top = cut - BAND.get(k, 2.3) < y <= cut
	r = rng.random()
	q = dict(p)
	if p["id"] == "door" and r < 0.6:                          # wooden-hearted doors rotted
		continue
	if k in ("yard", "bridge"):
		if p["id"] == "railing" and r < 0.3 or p["id"] == "half_wall" and r < 0.25:
			rubble.append((x, None, z, y, p["mat"]))
			continue
	elif y > cut:
		if p["id"] in WALLISH + ("floor", "roof_45", "beam", "pillar") and r < 0.2:
			rubble.append((x, None, z, y, p["mat"]))
		continue
	elif p["id"] == "battlement" and r < 0.3:                  # broken teeth on the stone tops
		rubble.append((x, None, z, y, p["mat"]))
		continue
	elif top and p["id"] in WALLISH:
		if r < 0.2:
			rubble.append((x, None, z, y, p["mat"]))
			continue
		if p["id"] in ("wall", "window_wall", "doorway"):
			q["id"] = "ruin_wall_collapsed" if r < 0.55 else ("ruin_wall_worn" if r < 0.8 else p["id"])
	elif top and p["id"] in ("pillar", "railing", "cornice", "cornice_corner", "corbel", "ladder"):
		if r < 0.5:
			continue
	elif top and p["id"] in ("floor", "floor_triangle") and y > 3:
		if r < 0.4 or y > cut - 1.0:   # (a floor on top of the broken walls would float)
			continue
	ruin.append(q)
	if q["id"] == p["id"]:
		standing.add(i)

# A railing or door whose floor fell goes with it (nothing may float).
fell = [whole[i]["pos"] for i in range(len(whole)) if i not in standing and whole[i]["id"] in ("floor", "floor_triangle")]
fell = [f for f in fell if not any(q["pos"] == f and q["id"].startswith("floor") for q in ruin)]
for i in [i for i in standing if whole[i]["id"] in ("railing", "door", "ladder", "battlement") and any(
		0.0 < whole[i]["pos"][1] - f[1] < 0.5 and dist((whole[i]["pos"][0], whole[i]["pos"][2]), (f[0], f[2])) < 1.2 for f in fell)]:
	standing.discard(i)
	ruin.remove(whole[i])

# Rubble lands on the highest floor still standing under it, or the cave floor (2.25; 0 in the dip).
floors = [whole[i] for i in standing if whole[i]["id"] in ("floor", "floor_triangle", "foundation", "foundation_triangle")]
for x, y, z, was, mat in rubble[:90]:
	if y is None:
		x, z = x + rng.uniform(-0.6, 0.6), z + rng.uniform(-0.6, 0.6)
		y = max([f["pos"][1] + (1.0 if f["id"].startswith("foundation") else 0.25) for f in floors
			if dist((x, z), (f["pos"][0], f["pos"][2])) < 1.3 and f["pos"][1] < was - 0.1], default=G)
	ruin.append({"id": "ruin_rubble", "mat": mat, "pos": [round(x, 3), round(y, 3), round(z, 3)], "rot": 4 + rng.randrange(12)})


def price(pieces, kinds):
	total = {}
	for p in pieces:
		for k, n in kinds[f"{p['id']}__{p['mat']}"].items():
			total[k] = total.get(k, 0) + n
	return total


kinds = json.load(open(sys.argv[3], encoding="utf-8"))
gone = [whole[i] for i in range(len(whole)) if i not in standing]
costs = {"stone": bp["cost"], "mend": price(gone, kinds)}
print("mended pieces:", len(gone), "of", len(whole))
json.dump({"views": {"ruin": ruin, "stone": whole}, "cost": costs, "shift": SHIFT, "left": LEFT, "right": RIGHT,
	"n_whole": len(whole), "n_mend": len(gone)}, open(page / "bp.json", "w"), separators=(",", ":"))
for v in (ruin, whole):
	for p in v:
		key = f"{p['id']}__{p['mat']}"
		f = page / "m" / f"{key}.json"
		if f.exists():
			continue
		dat = (GAME / f"assets/models/build/{key}.glb").read_bytes()
		n = struct.unpack("<I", dat[12:16])[0]
		g = json.loads(dat[20:20 + n])
		b = dat[20 + n + 8:]
		g["buffers"] = [{"byteLength": len(b), "uri": "data:application/octet-stream;base64," + base64.b64encode(b).decode()}]
		f.write_text(json.dumps(g, separators=(",", ":")))
shutil.copy(GAME / "tools/ruins/brickcrown_page.html", page / "index.html")
print("page files written: whole", len(whole), "ruin", len(ruin), "kinds:", len(list((page / "m").glob("*.json"))))
