# The 3D page of the Pillar Spiral (owner, Nov 28: ruin 15, F942), before its ruin is in the game: a town wound round a
# natural rock column, stone below, brick in the middle, wood on top. Two views: a first ruin of it (what fell, what
# still stands) and the blueprint whole.
#   godot --headless --audio-driver Dummy --path . -s res://tools/dump_blueprint.gd -- pillar_spiral <b.json> <b_kinds.json>
#   python tools/ruins/make_pillar_spiral_page.py <b.json> <page folder> <b_kinds.json>
# Copies tools/ruins/pillar_spiral_page.html into the folder as index.html. Made from make_sinkhole_ring_page.py; the
# ruin is a sketch for the owner's OK, the game's real ruin (chests, junk, creatures) comes after.
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

# After the blueprint's shift (BlueprintLibrary.PS_SHIFT (-7, 4.5, 2)); the cave floor is at y 4.5.
SHIFT = (-7.0, 4.5, 2.0)
G = 4.5


def local(p):
	return p["pos"][0] - SHIFT[0], p["pos"][1] - SHIFT[1], p["pos"][2] - SHIFT[2]


def ground(x, z):  # (BlueprintLibrary._ps_ground)
	if z < -26.0:
		return 99.0
	if z < -16.0:
		return 9.75
	if 13.5 < x < 17.0:
		return -4.5
	if 17.0 <= x < 27.0 and abs(z) < 8.0:
		return 2.25
	if z > 15.2:
		return -1.0
	return 0.0


# In the ruin (the plan): the left flight of the Spiral has fallen (you go up through the Bunk House inside instead),
# the Eyrie's spire leans, a Kiln House chimney is broken, rubble from the ceiling on the terrace, holes in the roofs,
# a few wooden walls, battlements and railings fell; the stone stands.
rng = random.Random(15)
ruin, rubble, standing = [], [], set()
for i, p in enumerate(whole):
	x, y, z = local(p)
	r = rng.random()
	q = dict(p)
	wood = p["mat"] == "plank_root"
	if wood and -6.1 < x < -3.9 and -6.1 < z < 6.1 and 9.9 < y < 12.1:      # the left flight, fallen onto the terrace
		if r < 0.7:
			rubble.append((x - 1.0, z, p["mat"], 5.5))
		continue
	if p["id"] == "roof_spire":                                            # the Eyrie's spire leans
		q["tilt"] = 0.12
		q["pos"] = [p["pos"][0], p["pos"][1] - 0.1, p["pos"][2]]
		ruin.append(q)
		continue
	if x > 23.0 and z > 0.0 and y > 6.0:                                  # one kiln chimney broken
		if r < 0.6:
			rubble.append((x + 1.0, z, p["mat"], 2.25))
		continue
	if p["id"] == "door" and r < 0.5:                                     # rotted
		continue
	if (p["id"].startswith("roof_") or p["id"].startswith("gable")) and r < 0.25:   # holes in the roofs
		continue
	if wood and p["id"] in ("wall", "window_wall") and r < 0.08:
		rubble.append((x, z, "plank_root", None))
		continue
	if p["id"] in ("battlement", "railing") and r < 0.2:
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

# Rubble lands where it fell (the terrace, the lump, the cave floor), plus stones from the ceiling on the terrace.
for _ in range(14):
	a, d = rng.uniform(0, 6.283), rng.uniform(6.5, 10.5)
	rubble.append((math.sin(a) * d, math.cos(a) * d, "cut_stone", 5.5))
for x, z, mat, y in rubble[:70]:
	x, z = x + rng.uniform(-0.6, 0.6), z + rng.uniform(-0.6, 0.6)
	gy = y if y is not None else ground(x, z)
	if y is None and math.hypot(x, z) < 10.5:     # (onto the terrace, not into the hall)
		gy = 5.5
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
shutil.copy(GAME / "tools/ruins/pillar_spiral_page.html", page / "index.html")
print("page files written: whole", len(whole), "ruin", len(ruin), "kinds:", len(list((page / "m").glob("*.json"))))
