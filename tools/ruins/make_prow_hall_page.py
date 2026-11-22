# The 3D page of the Prow Hall blueprint (owner, Nov 22: ruin 9, F656 + F657), before its ruin is in the game: the
# whole hall in cut stone, and a first ruin of it (what fell, what still stands), both set into the cave's rock.
#   godot --headless --audio-driver Dummy --path . -s res://tools/dump_blueprint.gd -- stonehold_prow_hall <prow.json>
#   (the same with wooden_prow_hall <prow_wood.json>)
#   python tools/ruins/make_prow_hall_page.py <prow.json> <page folder> [<prow_wood.json> <wood_kinds.json> <stone_kinds.json>]
# (the kinds files: dump_blueprint.gd's third path, what one of each piece costs). The wood view is the ruin mended
# (owner, Nov 22: "it fixes like 80% of the castle"): what still stands stays stone, only what fell or broke is wood.
# Copies tools/ruins/prow_hall_page.html into the folder as index.html. The ruin here is a sketch for the owner's OK;
# the game's real ruin (chests, junk, beetles) comes after, like make_manor_ruin.py.
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
wood_bp = json.load(open(sys.argv[3], encoding="utf-8")) if len(sys.argv) > 5 else None   # (owner, Nov 22: "rebuild it in wood")

# The parts (after the blueprint's shift; see BlueprintLibrary._prow_hall)
TOWERS = {"front_left": (-5.732, 7), "front_right": (21.732, 7), "back_left": (-5.732, -3), "back_right": (21.732, -3)}
KEEP, LONE = (8.0, -11.464), (-20.856, -11.732)
D8 = (-math.sqrt(3) / 2, -0.5)                              # the bridge's way out (side 8 of the back-left tower)
B0 = (TOWERS["back_left"][0] + D8[0] * 3.732, TOWERS["back_left"][1] + D8[1] * 3.732)
DIP = 3.0                                                   # how deep the dip under the bridge goes (page only)
# How high each part still stands: pieces above are gone, the top storey left is broken up.
CUT = {"lone": 12.3, "front_left": 7.8, "front_right": 5.6, "back_left": 12.3, "back_right": 10.1, "keep": 12.3,
	"prow": 5.6, "hall": 3.3, "hall_back": 5.6, "bridge": 99}


def dist(a, b):
	return math.hypot(a[0] - b[0], a[1] - b[1])


def part(x, z, y):
	if dist((x, z), LONE) < 4.6:
		return "lone"
	for k, c in TOWERS.items():
		if dist((x, z), c) < 4.6:
			return k
	if y > 9.5 and x < -6:
		return "bridge"
	if dist((x, z), KEEP) < 8.3 or z < -4.4:
		return "keep"
	if z > 8.1:
		return "prow"
	return "hall_back" if z < -1.6 else "hall"


WALLISH = ("wall", "window_wall", "window_wide", "doorway", "wall_narrow")
rng = random.Random(9)
ruin, rubble, standing = [], [], set()   # standing: the whole's pieces still there, unbroken
for i, p in enumerate(whole):
	x, y, z = p["pos"]
	k = part(x, z, y)
	cut = CUT[k]
	top = cut - 2.3 < y <= cut                               # the highest storey still (partly) standing
	r = rng.random()
	q = dict(p)
	if k == "bridge" and p["id"] in ("floor", "railing"):
		t = ((x - B0[0]) * D8[0] + (z - B0[1]) * D8[1])     # how far out along the bridge
		if 2.2 < t < 8.2 or (p["id"] == "railing" and r < 0.5):
			rubble.append((x, -DIP + 0.35 if 2.2 < t < 8.2 else 0.0, z))
			continue
	elif y > cut:
		if p["id"] in WALLISH + ("floor", "battlement") and r < 0.18:
			rubble.append((x, None, z))
		continue
	elif p["id"] == "door":
		if r < 0.7:
			continue
	elif top and p["id"] in WALLISH:
		if r < 0.25:
			rubble.append((x, None, z))
			continue
		if p["id"] != "wall_narrow":
			q["id"] = "ruin_wall_collapsed" if r < 0.55 else ("ruin_wall_worn" if r < 0.8 else p["id"])
	elif top and p["id"] in ("battlement", "battlement_corner", "pillar", "railing", "cornice", "beacon_bowl"):
		if r < 0.5:
			continue
	elif top and p["id"] in ("floor", "floor_triangle") and y > 1.5:
		if r < 0.4:
			continue
	ruin.append(q)
	if q["id"] == p["id"]:
		standing.add(i)

# Rubble where things fell: on the floor of the part they fell into (its foundations' top), on the rock, or in the dip.
found = [p for p in whole if p["id"] in ("foundation", "foundation_triangle")]
for i, (x, y, z) in enumerate(rubble[:90]):
	if y is None:
		under = [f for f in found if dist((x, z), (f["pos"][0], f["pos"][2])) < 1.3]
		y = max((f["pos"][1] + 1.0 for f in under), default=0.0)
		x, z = x + rng.uniform(-0.6, 0.6), z + rng.uniform(-0.6, 0.6)
	ruin.append({"id": "ruin_rubble", "mat": "cut_stone", "pos": [round(x, 3), round(y, 3), round(z, 3)], "rot": 4 + rng.randrange(12)})

# Mending it: everything that fell or broke, made new; in wood, what still stands stays stone.
def price(pieces, kinds):
	total = {}
	for p in pieces:
		for k, n in kinds[f"{p['id']}__{p['mat']}"].items():
			total[k] = total.get(k, 0) + n
	return total


views, costs = {"stone": whole}, {"stone": bp["cost"]}
if wood_bp:
	wood = pieces_of(wood_bp)
	assert len(wood) == len(whole)
	views["wood"] = [whole[i] if i in standing else wood[i] for i in range(len(whole))]
	stone_kinds, wood_kinds = (json.load(open(sys.argv[k], encoding="utf-8")) for k in (5, 4))
	costs["stone_mend"] = price([whole[i] for i in range(len(whole)) if i not in standing], stone_kinds)
	costs["wood"] = price([wood[i] for i in range(len(whole)) if i not in standing], wood_kinds)
	print("mended pieces:", len(whole) - len(standing), "of", len(whole))
json.dump({"views": {"ruin": ruin} | views, "cost": costs, "lone": LONE, "keep": KEEP, "b0": B0, "d8": D8, "dip": DIP},
	open(page / "bp.json", "w"), separators=(",", ":"))
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
shutil.copy(GAME / "tools/ruins/prow_hall_page.html", page / "index.html")
print("page files written: whole", len(whole), "ruin", len(ruin), "kinds:", len(list((page / "m").glob("*.json"))))
