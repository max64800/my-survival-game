# The 3D page of the Mine-head Works (owner, Nov 25: ruin 12, F899), before its ruin is in the game: an old mine head
# in the cave, stone below and wood above. Two views: a first ruin of it (what fell, what still stands) and the
# blueprint whole.
#   godot --headless --audio-driver Dummy --path . -s res://tools/dump_blueprint.gd -- minehead_works <b.json> <b_kinds.json>
#   python tools/ruins/make_minehead_page.py <b.json> <page folder> <b_kinds.json>
# Copies tools/ruins/minehead_page.html into the folder as index.html. Made from make_brickcrown_page.py; the ruin is a
# sketch for the owner's OK, the game's real ruin (chests, the fallen cage, junk, creatures) comes after.
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

# After the blueprint's shift (BlueprintLibrary.MINE_SHIFT (-4, 8, 4)); the cave floor is at y 8.
SHIFT = (-4.0, 8.0, 4.0)
G = 8.0


def local(p):
	return p["pos"][0] - SHIFT[0], p["pos"][1] - SHIFT[1], p["pos"][2] - SHIFT[2]


# In the ruin (the plan): the trestle's middle span lies in the dip, the wheel hangs crooked, roofs have holes, the
# wooden parts are rotten here and there (doors, railings, braces); the stone stands.
rng = random.Random(12)
ruin, rubble, standing = [], [], set()
for i, p in enumerate(whole):
	x, y, z = local(p)
	r = rng.random()
	q = dict(p)
	wood = p["mat"] == "plank_root"
	span = 11.3 < x < 15.7 and -5.5 < z < -2.5 and y > 0.5      # the trestle's middle span, over the dip
	if span:
		if p["id"] == "floor":                                    # fallen into the dip, tipped
			q["pos"] = [p["pos"][0] + rng.uniform(-0.4, 0.4), G - 4.0 + 0.15, p["pos"][2] + rng.uniform(-0.5, 0.5)]
			q["tilt"] = rng.uniform(-0.35, 0.35)
			ruin.append(q)
		elif r < 0.5:
			rubble.append((x, z, p["mat"], -4.0))
		continue
	if p["id"] == "head_wheel":
		q["tilt"] = 0.14                                          # one bearing slipped off its beam
		q["pos"] = [p["pos"][0], p["pos"][1] - 0.25, p["pos"][2]]
		ruin.append(q)
		continue
	if p["id"] == "door" and r < 0.6:                             # rotted
		continue
	if p["id"].startswith("roof_") and r < 0.35:                  # holes in the roofs
		continue
	if wood and p["id"] == "railing" and r < 0.3 or wood and p["id"] == "brace" and r < 0.15:
		continue
	if wood and p["id"] in ("wall", "window_wall") and r < 0.12:  # a few wooden walls fell out
		rubble.append((x, z, "cut_stone", None))
		continue
	if p["id"] == "battlement" and r < 0.3:
		rubble.append((x, z, p["mat"], None))
		continue
	ruin.append(q)
	standing.add(i)

# A railing or door whose floor fell goes with it (nothing may float).
fell = [whole[i]["pos"] for i in range(len(whole)) if i not in standing and whole[i]["id"] == "floor"]
for i in [i for i in standing if whole[i]["id"] in ("railing", "door", "ladder") and any(
		0.0 < whole[i]["pos"][1] - f[1] < 0.5 and math.dist((whole[i]["pos"][0], whole[i]["pos"][2]), (f[0], f[2])) < 1.2 for f in fell)]:
	standing.discard(i)
	ruin.remove(whole[i])

# Rubble lands on the cave floor where it fell (the dip's floor for the trestle; at the wall's foot for the rest).
for x, z, mat, y in rubble[:60]:
	x, z = x + rng.uniform(-0.6, 0.6), z + rng.uniform(-0.6, 0.6)
	gy = y if y is not None else (-2.25 if x > 16.8 else 0.0)
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
shutil.copy(GAME / "tools/ruins/minehead_page.html", page / "index.html")
print("page files written: whole", len(whole), "ruin", len(ruin), "kinds:", len(list((page / "m").glob("*.json"))))
