# The 3D page of the Cliff Galleries (owner, Nov 26: ruin 13, F913), before its ruin is in the game: buildings up a
# tall cave wall, stone below and brick above. Two views: a first ruin of it (what fell, what still stands) and the
# blueprint whole.
#   godot --headless --audio-driver Dummy --path . -s res://tools/dump_blueprint.gd -- cliff_galleries <b.json> <b_kinds.json>
#   python tools/ruins/make_cliff_galleries_page.py <b.json> <page folder> <b_kinds.json>
# Copies tools/ruins/cliff_galleries_page.html into the folder as index.html. Made from make_minehead_page.py; the ruin
# is a sketch for the owner's OK, the game's real ruin (chests, junk, creatures) comes after.
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

# After the blueprint's shift (BlueprintLibrary.CG_SHIFT (-2, 5, 5)); the cave floor is at y 5.
SHIFT = (-2.0, 5.0, 5.0)
G = 5.0


def local(p):
	return p["pos"][0] - SHIFT[0], p["pos"][1] - SHIFT[1], p["pos"][2] - SHIFT[2]


def ground(x, z):  # (BlueprintLibrary._cliff_ground)
	if x < -7.2 and z < -1.2:
		return 10.75
	if x > 11.0 and z < -1.2:
		return 4.5
	if 7.0 < x < 11.0 and z > -9.2:
		return -4.75
	return 0.0


# In the ruin (the plan): the gallery's middle has fallen onto the hall's roof, the crack bridge sags, the tower's
# roof leans, holes in the tile roofs, a few brick walls and battlements fell; the stone stands.
rng = random.Random(13)
ruin, rubble, standing = [], [], set()
for i, p in enumerate(whole):
	x, y, z = local(p)
	r = rng.random()
	q = dict(p)
	brick = p["mat"] == "clay_brick"
	if -3.2 < x < 1.2 and -11.5 < z < -8.5 and y > 11.0:          # the gallery's middle, fallen onto the hall's roof
		if p["id"] == "floor":
			q["pos"] = [p["pos"][0] + rng.uniform(-0.3, 0.3), G + 5.5 + 0.2, p["pos"][2] + rng.uniform(0.2, 0.8)]
			q["tilt"] = rng.uniform(-0.3, 0.3)
			ruin.append(q)
		elif r < 0.6:
			rubble.append((x, z, p["mat"], 5.5))
		continue
	if 9.0 < x < 11.2 and -5.5 < z < -2.5 and y > 5.0:            # the bridge's far span sags
		if p["id"] == "floor":
			q["pos"] = [p["pos"][0], p["pos"][1] - 0.35, p["pos"][2]]
			q["tilt"] = 0.12
			ruin.append(q)
		elif r < 0.5:
			rubble.append((x, z, p["mat"], -4.75))
		continue
	if p["id"] == "roof_45_outer":                                 # the lookout's roof leans
		q["tilt"] = 0.1
		q["pos"] = [p["pos"][0], p["pos"][1] - 0.1, p["pos"][2]]
		ruin.append(q)
		continue
	if p["id"] == "door" and r < 0.6:                             # rotted
		continue
	if p["id"].startswith("roof_") and r < 0.35:                  # holes in the roofs
		continue
	if brick and p["id"] in ("wall", "window_wall") and y > 7.0 and r < 0.1:
		rubble.append((x, z, "clay_brick", None))
		continue
	if p["id"] in ("battlement", "railing") and r < 0.25:
		rubble.append((x, z, p["mat"], None))
		continue
	ruin.append(q)
	standing.add(i)

# A railing or door whose floor fell goes with it (nothing may float).
fell = [whole[i]["pos"] for i in range(len(whole)) if i not in standing and whole[i]["id"] == "floor"]
for i in [i for i in standing if whole[i]["id"] in ("railing", "door") and any(
		0.0 < whole[i]["pos"][1] - f[1] < 0.5 and math.dist((whole[i]["pos"][0], whole[i]["pos"][2]), (f[0], f[2])) < 1.2 for f in fell)]:
	standing.discard(i)
	ruin.remove(whole[i])

# Rubble lands where it fell: on the ground under it (the shelf, the ledge, the crack's floor, the cave floor).
for x, z, mat, y in rubble[:60]:
	x, z = x + rng.uniform(-0.6, 0.6), z + rng.uniform(-0.6, 0.6)
	gy = y if y is not None else ground(x, max(z, -11.0))
	ruin.append({"id": "ruin_rubble", "mat": "cut_stone", "pos": [round(x + SHIFT[0], 3), round(G + gy, 3), round(z + SHIFT[2], 3)],
		"rot": 4 + rng.randrange(12)})


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
json.dump({"views": {"ruin": ruin, "stone": whole}, "cost": costs, "shift": SHIFT,
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
shutil.copy(GAME / "tools/ruins/cliff_galleries_page.html", page / "index.html")
print("page files written: whole", len(whole), "ruin", len(ruin), "kinds:", len(list((page / "m").glob("*.json"))))
