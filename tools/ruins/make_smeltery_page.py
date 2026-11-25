# The 3D page of the Smeltery Terraces blueprint (owner, Nov 24: ruin 10, F845), before its ruin is in the game: the
# whole bronze-works in Hearthbrick, a first ruin of it (what fell, what still stands), and the ruin mended in wood.
#   godot --headless --audio-driver Dummy --path . -s res://tools/dump_blueprint.gd -- hearthbrick_smeltery <b.json> <b_kinds.json>
#   (the same with wooden_smeltery <w.json> <w_kinds.json>)
#   python tools/ruins/make_smeltery_page.py <b.json> <page folder> <w.json> <w_kinds.json> <b_kinds.json>
# Copies tools/ruins/smeltery_page.html into the folder as index.html. Made from make_prow_hall_page.py; the ruin is a
# sketch for the owner's OK, the game's real ruin (chests, junk, beetles) comes after.
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
def pieces_of(d):
	return [{"id": p["id"], "mat": p["mat"], "pos": [round(v, 4) for v in p["pos"]], "rot": p["rot"]} for p in d["pieces"]]


whole = pieces_of(bp)
wood_bp = json.load(open(sys.argv[3], encoding="utf-8"))

# The parts, after the blueprint's shift (see BlueprintLibrary._smeltery: SMELT_SHIFT (5, 0, -3))
FURNACE, TOWER = (-19.732, -1.0), (18.0, -6.0)
BRIDGE = (-16.0, -8.0)        # the bridge's two ends (x), along z = -1, 3 m up; its pier is at x = -13
TURRET, WATCH = (-4.05, -3.5), (24.052, 2.4)   # the hall's stair turret, the terrace's watch turret (6-sided)
ROCK_Z = -10.2                # the cave wall starts behind this (BlueprintLibrary.smelt_rock_top)
DIP = 3.0                     # how deep the dip under the bridge goes (page only)
# How high each part still stands: pieces above are gone, the top BAND m left is broken up. The tower keeps its
# ring room, crown deck and a broken stump of the chimney; its band is thin so no chimney wall stands on a broken one.
CUT = {"furnace": 5.6, "tower": 19.0, "hall": 8.5, "turret": 10.5, "watch": 6.0, "bridge": 99, "vaults": 99}
BAND = {"tower": 1.0, "turret": 1.0, "watch": 1.0}


def dist(a, b):
	return math.hypot(a[0] - b[0], a[1] - b[1])


def part(x, z, y):
	if dist((x, z), FURNACE) < 4.6:
		return "furnace"
	if dist((x, z), TURRET) < 2.06 and y > 0.5:
		return "turret"
	if dist((x, z), WATCH) < 2.06 and y > 0.5:
		return "watch"
	if BRIDGE[0] - 0.1 < x < BRIDGE[1] + 0.1 and y > 1.9:
		return "bridge"
	if x > 14.2 and (z < -1.8 or y > 3.4) or y > 12.4:   # (the crown and its balconies stick out: they belong to the tower)
		return "tower"
	if -3.2 < x < 13.2 and z < 0.2 and y > 3.1:   # (z < 0.2: with its front balcony)
		return "hall"
	return "vaults"


WALLISH = ("wall", "window_wall", "window_wide", "doorway", "sloped_wall")
rng = random.Random(10)
ruin, rubble, standing = [], [], set()   # standing: the whole's pieces still there, unbroken
for i, p in enumerate(whole):
	x, y, z = p["pos"]
	k = part(x, z, y)
	cut = CUT[k]
	top = cut - BAND.get(k, 2.3) < y <= cut                               # the highest storey still (partly) standing
	r = rng.random()
	q = dict(p)
	if k == "bridge":
		t = x - BRIDGE[0]                                    # how far out along the bridge
		gap = 4.4 < t < 5.6                                  # the span between the pier and the terrace fell
		if p["id"] in ("roof_45_ridge", "pillar") or gap or p["id"] == "railing" and r < 0.5:   # (its wood roof rotted)
			rubble.append((x, -DIP + 0.35 if gap or 3.5 < t < 6.5 and r < 0.5 else None, z, y))
			continue
	elif k == "vaults":                                      # the vaults stand; doors rotted, terrace railings broken
		if p["id"] == "door" and r < 0.7 or p["id"] == "railing" and r < 0.35:
			continue
		if p["id"] == "floor" and abs(y - 3.0) < 0.1 and r < 0.06:
			rubble.append((x, None, z, y))
			continue
	elif y > cut:
		if p["id"] in WALLISH + ("floor", "roof_45", "beam") and r < 0.18:
			rubble.append((x, None, z, y))
		continue
	elif p["id"] == "door":
		if r < 0.7:
			continue
	elif top and p["id"] in WALLISH:
		if r < 0.25:
			rubble.append((x, None, z, y))
			continue
		if p["id"] in ("wall", "window_wall", "doorway"):
			q["id"] = "ruin_wall_collapsed" if r < 0.55 else ("ruin_wall_worn" if r < 0.8 else p["id"])
	elif top and p["id"] in ("pillar", "railing", "cornice", "cornice_corner", "corbel"):
		if r < 0.5:
			continue
	elif top and p["id"] in ("floor", "floor_triangle") and y > 1.5:
		if r < 0.4 or y > cut - 1.0:   # (a floor on top of the broken walls would float)
			continue
	ruin.append(q)
	if q["id"] == p["id"]:
		standing.add(i)

# A railing whose floor fell goes with it (nothing may float).
fell = [whole[i]["pos"] for i in range(len(whole)) if i not in standing and whole[i]["id"] in ("floor", "floor_triangle")]
fell = [f for f in fell if not any(q["pos"] == f and q["id"].startswith("floor") for q in ruin)]
for i in [i for i in standing if whole[i]["id"] in ("railing", "door") and any(0.0 < whole[i]["pos"][1] - f[1] < 0.5
		and dist((whole[i]["pos"][0], whole[i]["pos"][2]), (f[0], f[2])) < 1.2 for f in fell)]:
	standing.discard(i)
	ruin.remove(whole[i])

# Rubble lands on the highest floor still standing under it (a vault roof, the yard, a tower floor), or the cave floor.
floors = [whole[i] for i in standing if whole[i]["id"] in ("floor", "floor_triangle", "foundation", "foundation_triangle")]
for i, (x, y, z, was) in enumerate(rubble[:80]):
	if y is None:
		x, z = x + rng.uniform(-0.6, 0.6), z + rng.uniform(-0.6, 0.6)
		y = max([f["pos"][1] + (1.0 if f["id"].startswith("foundation") else 0.25) for f in floors
			if dist((x, z), (f["pos"][0], f["pos"][2])) < 1.3 and f["pos"][1] < was - 0.1], default=0.0)
	ruin.append({"id": "ruin_rubble", "mat": "clay_brick", "pos": [round(x, 3), round(y, 3), round(z, 3)], "rot": 4 + rng.randrange(12)})


def price(pieces, kinds):
	total = {}
	for p in pieces:
		for k, n in kinds[f"{p['id']}__{p['mat']}"].items():
			total[k] = total.get(k, 0) + n
	return total


wood = pieces_of(wood_bp)
assert len(wood) == len(whole)
views = {"stone": whole, "wood": [whole[i] if i in standing else wood[i] for i in range(len(whole))]}
brick_kinds, wood_kinds = (json.load(open(sys.argv[k], encoding="utf-8")) for k in (5, 4))
gone = [i for i in range(len(whole)) if i not in standing]
costs = {"stone": bp["cost"], "stone_mend": price([whole[i] for i in gone], brick_kinds),
	"wood": price([wood[i] for i in gone], wood_kinds)}
print("mended pieces:", len(gone), "of", len(whole))
json.dump({"views": {"ruin": ruin} | views, "cost": costs, "furnace": FURNACE, "tower": TOWER, "bridge": BRIDGE,
	"rock_z": ROCK_Z, "dip": DIP, "n_whole": len(whole), "n_mend": len(gone)}, open(page / "bp.json", "w"), separators=(",", ":"))
for v in [ruin] + list(views.values()):
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
shutil.copy(GAME / "tools/ruins/smeltery_page.html", page / "index.html")
print("page files written: whole", len(whole), "ruin", len(ruin), "kinds:", len(list((page / "m").glob("*.json"))))
