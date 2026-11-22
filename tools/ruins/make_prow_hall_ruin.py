# The RUINED Prow Hall (owner, Nov 22: ruin 9, F656 + F657 + F479; docs/design/GRAND-RUIN-RECIPE.md).
#   godot --headless --audio-driver Dummy --path . -s res://tools/dump_blueprint.gd -- stonehold_prow_hall <prow.json>
#   python tools/ruins/make_prow_hall_ruin.py <prow.json>
# Writes blueprints/ruins/prow_hall_ruin.json (pieces, chests with loot, props, beetle spots) for the world to place
# (src/world/ruin_prow_hall.gd, which also shapes the cave round it: the dip, the lump, the rock wall).
# What happened: the owner-approved sketch of the 3D page (tools/ruins/make_prow_hall_page.py: the same dice, the same
# heights each part still stands to). The hall lost its upper storey, the front-right tower and the prow their tops, the
# bridge's middle fell into the dip, the lone tower's roof is half gone. Then made sound for the game: no doors (gone),
# nothing hanging in the air (railings, trims, battlements, walls whose floor fell), rubble lies on the floor it fell
# onto, never on stairs, in doorways or on the walk lines, and the castle's things (chests, racks, tables) checked
# against the junk rules (tools/ruins/ruin_junk.py).
import json
import math
import random
import sys
from pathlib import Path

GAME = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(GAME / "tools" / "ruins"))
sys.path.insert(0, str(GAME / "tools" / "dungeons"))
import ruin_junk as RJ                      # noqa: E402  (piece sizes, outlines, overlap)
from glb_bounds import bounds               # noqa: E402

bp = json.load(open(sys.argv[1], encoding="utf-8"))
whole = [{"id": p["id"], "mat": p["mat"], "pos": [round(v, 4) for v in p["pos"]], "rot": p["rot"]} for p in bp["pieces"]]

# ---------------------------------------------------------------- the page's sketch (keep in step with make_prow_hall_page.py)
TOWERS = {"front_left": (-5.732, 7), "front_right": (21.732, 7), "back_left": (-5.732, -3), "back_right": (21.732, -3)}
KEEP, LONE = (8.0, -11.464), (-20.856, -11.732)
D8 = (-math.sqrt(3) / 2, -0.5)
B0 = (TOWERS["back_left"][0] + D8[0] * 3.732, TOWERS["back_left"][1] + D8[1] * 3.732)
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


def along_bridge(x, z):
	return (x - B0[0]) * D8[0] + (z - B0[1]) * D8[1]


WALLISH = ("wall", "window_wall", "window_wide", "doorway", "wall_narrow")
rng = random.Random(9)
pieces, fell = [], []          # fell: (x, y it fell from, z) of what broke off
for p in whole:
	x, y, z = p["pos"]
	k = part(x, z, y)
	cut = CUT[k]
	top = cut - 2.3 < y <= cut
	r = rng.random()
	q = dict(p, pos=list(p["pos"]))
	if k == "bridge" and p["id"] in ("floor", "railing"):
		t = along_bridge(x, z)
		if 2.2 < t < 8.2 or (p["id"] == "railing" and r < 0.5):
			fell.append((x, y, z))
			continue
	elif y > cut:
		if p["id"] in WALLISH + ("floor", "battlement") and r < 0.18:
			fell.append((x, y, z))
		continue
	elif p["id"] == "door":
		continue                  # (the page kept a few; the game's ruins have lost every door, like the manor)
	elif top and p["id"] in WALLISH:
		if r < 0.25:
			fell.append((x, y, z))
			continue
		if p["id"] != "wall_narrow":
			q["id"] = "ruin_wall_collapsed" if r < 0.55 else ("ruin_wall_worn" if r < 0.8 else p["id"])
	elif top and p["id"] in ("battlement", "battlement_corner", "pillar", "railing", "cornice", "beacon_bowl"):
		if r < 0.5:
			continue
	elif top and p["id"] in ("floor", "floor_triangle") and y > 1.5:
		if r < 0.4:
			fell.append((x, y, z))
			continue
	pieces.append(q)

# ---------------------------------------------------------------- made sound: nothing hangs in the air
TRIMS = ("cornice", "corbel")
FLOORS = ("floor", "floor_triangle", "foundation", "foundation_triangle", "foundation_steps")


def rock_top(x, z):
	"""BlueprintLibrary.prow_rock_top: the lump under the lone tower (the cave wall never holds pieces)."""
	return 7.0 if dist((x, z), LONE) < 5.5 else 0.0


def height_of(p):
	return 0.8 if p["id"] == "ruin_wall_collapsed" else RJ.PIECES[p["id"]]["size"][1]


def top_of(p):
	return p["pos"][1] + height_of(p)


def grounded(p):
	return p["pos"][1] < 0.3 or (p["id"].startswith("foundation") and p["pos"][1] < rock_top(p["pos"][0], p["pos"][2]) + 0.05)


def held(p):
	"""Something solid right under it (a floor's or a wall's top), or for trims the wall they hang on."""
	fp = RJ.footprint(p, -0.05)
	y = p["pos"][1]
	for q in pieces:
		if q is p or q["id"] in TRIMS or q["id"] == "railing":
			continue
		if p["id"] in TRIMS:
			if q["id"] in WALLISH + ("ruin_wall_worn",) and q["pos"][1] - 0.05 < y < top_of(q) + 0.1 \
					and RJ.overlap(RJ.footprint(p, 0.05), RJ.footprint(q, 0.05)):
				return True
			continue
		if abs(top_of(q) - y) < 0.08 and RJ.overlap(fp, RJ.footprint(q, 0.02)):
			return True
	return False


changed = True
while changed:
	changed = False
	for p in list(pieces):
		if grounded(p) or p["id"] in ("floor", "floor_triangle"):
			continue          # (floors hang on their walls and each other: the game's strength test checks them)
		if not held(p):
			pieces.remove(p)
			changed = True

# ---------------------------------------------------------------- the dip under the bridge (ruin_prow_hall.gd: dip_at)
def smooth(t):
	t = max(0.0, min(1.0, t))
	return t * t * (3 - 2 * t)


DIP = 3.0


def dip_at(x, z):
	t = along_bridge(x, z)
	side = abs((x - B0[0]) * -D8[1] + (z - B0[1]) * D8[0])
	return -DIP * smooth(min(t - 0.5, 9 - t) / 2.0) * smooth(1 - side / 4.5)


def by_the_rock(x, z):
	"""On the lump's slope, or by the rock wall behind the keep (the world shapes those: no rubble there)."""
	if dist((x, z), LONE) < 10.5:
		return True
	return z < KEEP[1] + 0.5 and x > -7.0 and dist((x, z), KEEP) > 8.0


# ---------------------------------------------------------------- the rules check (tools/ruins/ruin_junk.py's numbers)
WALK = {   # walk lines between the doorways (and stairs), per floor top
	1.0: [((4, 11), (8, 8.5)), ((12, 11), (8, 8.5)), ((8, 8.5), (8, -4.5)), ((-2, 7), (18, 7)), ((-2, -3), (18, -3)),
		((8, -4.5), (8, -11.5))],
	0.0: [((3, 11), (3, 20)), ((13, 11), (13, 20)), ((3, 20), (13, 20))],
}


def corners_of(x, z, sx, sz, yaw):
	a = math.radians(yaw)
	return [(x + u * math.cos(a) + v * math.sin(a), z - u * math.sin(a) + v * math.cos(a))
		for (u, v) in ((-sx / 2, -sz / 2), (sx / 2, -sz / 2), (sx / 2, sz / 2), (-sx / 2, sz / 2))]


def seg_dist(p, a, b):
	ax, az = b[0] - a[0], b[1] - a[1]
	L = ax * ax + az * az
	t = 0 if L == 0 else max(0.0, min(1.0, ((p[0] - a[0]) * ax + (p[1] - a[1]) * az) / L))
	return math.hypot(p[0] - a[0] - t * ax, p[1] - a[1] - t * az)


def poly_pt_dist(cs, pt):
	if RJ.inside(pt, cs):
		return 0.0
	return min(seg_dist(pt, cs[i], cs[(i + 1) % len(cs)]) for i in range(len(cs)))


def poly_dist(a, b):
	if RJ.overlap(a, b):
		return 0.0
	return min(min(poly_pt_dist(b, p) for p in a), min(poly_pt_dist(a, p) for p in b))


def walled_off(pos, door, build):
	a, b = (pos[0], pos[2]), (door["pos"][0], door["pos"][2])
	walls = [w for w in build if w["id"] in ("wall", "window_wall", "window_wide", "ruin_wall_worn") and abs(w["pos"][1] - door["pos"][1]) < 0.3]
	for i in range(1, 20):
		t = i / 20
		pt = (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)
		if any(RJ.inside(pt, RJ.footprint(w, 0.0)) for w in walls):
			return True
	return False


def floor_under(pt, y, build, grow=0.02):
	return any(f["id"] in FLOORS and f["id"] != "foundation_steps" and abs(top_of(f) - y) < 0.06
		and RJ.inside(pt, RJ.footprint(f, grow)) for f in build)


def problems_of(name, pos, cs, h, kind, build, others):
	"""One thing (prop, chest, debris) against the rules. -> list of problems."""
	bad = []
	y = pos[1]
	floor_y = round(y - (0.01 if kind == "prop" else 0.0), 2)
	tag = f"{name} at ({pos[0]:.2f}, {y:.2f}, {pos[2]:.2f})"
	if floor_y > 0.05 or kind != "debris":
		if floor_y > 0.05 and not all(floor_under(pt, floor_y, build) for pt in cs + [(pos[0], pos[2])]):
			bad.append(f"{tag}: a corner over no floor")
	for p in build:
		lo, hi = p["pos"][1], top_of(p)
		if p["id"] in RJ.STAIRS:
			grow = RJ.STAIR_CLEAR if kind != "debris" else 0.5
			if p["id"] == "foundation_steps" and y > hi - 0.05:
				grow = 0.0
			if lo - 0.3 < y < hi + 0.3 and RJ.overlap(cs, RJ.footprint(p, grow)):
				bad.append(f"{tag}: on or by the stairs at {p['pos']}")
			continue
		if p["id"] == "doorway" and abs(lo - y) < 1.0 and not walled_off(pos, p, build):
			if poly_pt_dist(cs, (p["pos"][0], p["pos"][2])) < 1.5:
				bad.append(f"{tag}: in the doorway at {p['pos']}")
		if hi > y + 0.05 and lo < y + h and RJ.overlap(cs, RJ.footprint(p, 0.05 if kind != "debris" else 0.0)):
			bad.append(f"{tag}: inside {p['id']} at {p['pos']}")
	for (a, b) in WALK.get(floor_y, []):
		if seg_dist((pos[0], pos[2]), a, b) < RJ.PATH_CLEAR or any(seg_dist(c, a, b) < RJ.PATH_EDGE for c in cs):
			bad.append(f"{tag}: on the walk line {a}->{b}")
	for (n2, p2, c2, h2, k2) in others:
		gap = RJ.JUNK_GAP if "debris" not in (kind, k2) else 0.05
		if "chest" in (kind, k2) and "debris" not in (kind, k2):
			gap = RJ.THING_CLEAR
		if y < p2[1] + h2 and p2[1] < y + h and poly_dist(cs, c2) < gap:
			bad.append(f"{tag} and {n2} at {p2}: too close")
	return bad


build = [p for p in pieces if p["id"] in RJ.PIECES]
things = []      # (name, pos, corners, height, kind)

# ---------------------------------------------------------------- the castle's things
_dims = {}


def dims(model, folder="decor"):
	if model not in _dims:
		lo, hi = bounds(str(GAME / f"assets/models/{folder}" / f"{model}.glb"))
		_dims[model] = (float(hi[0] - lo[0]), float(hi[1] - lo[1]), float(hi[2] - lo[2]))
	return _dims[model]


FACE = {"+z": (0, 1, 0), "-z": (0, -1, 180), "+x": (1, 0, 90), "-x": (-1, 0, 270)}


def wall_spot(d, facing, line, along, y):
	nx, nz, yaw = FACE[facing]
	off = 0.15 + 0.06 + d / 2
	pos = [along, y, line + nz * off] if nx == 0 else [line + nx * off, y, along]
	return [round(v, 3) for v in pos], yaw


def on_wall(model, facing, line, along, y):
	pos, yaw = wall_spot(dims(model)[2], facing, line, along, y + 0.01)
	return {"model": model, "pos": pos, "yaw": yaw}


def free_at(model, x, z, y, yaw=0):
	return {"model": model, "pos": [x, round(y + 0.01, 3), z], "yaw": yaw}


def chest_at(kind, x, z, y, loot):
	return {"kind": kind, "pos": [round(x, 3), y, round(z, 3)], "yaw": 0, "loot": loot}


ROOF_KEEP_Y = 10.25
chests = [
	chest_at("chest_stone", 8.0, -16.0, 1.0, {"recipe_page": 1, "rope": 3}),                       # the keep, downstairs
	chest_at("chest_small", 21.732, -3.0, 7.75, {"recipe_page": 1, "blueprint_page": 1}),           # the back-right tower, top floor left
	chest_at("chest_small", 8.0, 16.0, 3.25, {"recipe_page": 1, "blueprint_page": 1}),              # the prow, upstairs
	chest_at("chest_copper", LONE[0], LONE[1], 10.0, {"recipe_page": 2, "blueprint_page": 2}),      # the lone tower, past the fallen bridge
]
props = [
	# the great hall: two long feast tables with their benches (its ceiling is too low for the tall racks)
	free_at("furn_table_long", 4.0, 2.0, 1.0, 90),
	free_at("furn_bench_long", 5.4, 2.0, 1.0, 90),
	free_at("furn_table_long", 12.5, 2.0, 1.0, 90),
	free_at("furn_bench_long", 11.1, 2.0, 1.0, 90),
	# the keep: the lord's map table, an armour bench, a crossbow rack (lootable)
	free_at("hm_map_table", 11.5, -11.0, 1.0),
	free_at("ro_armour_bench", 4.0, -10.0, 1.0, 90),
	# the prow: crates of bolts by its point (lootable)
	free_at("rt_arrow_crate_spill", 8.0, 16.2, 1.0),
]
beetles = [[8.0, 1.0, 2.0], [8.0, 1.0, -9.0], [3.0, 0.2, 14.0], [13.0, 0.2, 14.0], [-5.7, 1.0, 7.0]]

for c in chests:
	sx, h, sz = dims(c["kind"], "stations")
	things.append((c["kind"], c["pos"], corners_of(c["pos"][0], c["pos"][2], sx, sz, c["yaw"]), h, "chest"))
for pr in props:
	sx, h, sz = dims(pr["model"])
	things.append((pr["model"], pr["pos"], corners_of(pr["pos"][0], pr["pos"][2], sx, sz, pr["yaw"]), h, "prop"))
# ---------------------------------------------------------------- rubble where things fell
rubble = []
for (x, y0, z) in fell:
	x, z = x + rng.uniform(-0.6, 0.6), z + rng.uniform(-0.6, 0.6)
	if 2.2 < along_bridge(x, z) < 8.2 and y0 > 9:
		if along_bridge(x, z) > 4.5:
			continue                                   # (that end lies on the lump's slope)
		y = round(dip_at(x, z), 2)                     # down in the dip under the bridge
	else:
		tops = [top_of(f) for f in build if f["id"] in FLOORS and f["id"] != "foundation_steps" and top_of(f) < y0 + 0.1
			and RJ.inside((x, z), RJ.footprint(f, -0.3))]
		y = max(tops, default=0.0)                     # the highest floor under where it fell, or the cave floor
		if y == 0.0 and by_the_rock(x, z):
			continue
	q = {"id": "ruin_rubble", "mat": "cut_stone", "pos": [round(x, 3), y, round(z, 3)], "rot": 4 + rng.randrange(12)}
	cs = RJ.footprint(q)
	if problems_of("ruin_rubble", q["pos"], cs, 0.7, "debris", build, things):
		continue
	rubble.append(q)
	things.append(("ruin_rubble", q["pos"], cs, 0.7, "debris"))
	if len(rubble) >= 60:
		break

problems = []
for i, (n, pos, cs, h, kind) in enumerate(things):
	if kind == "debris":
		continue
	others = [t for j, t in enumerate(things) if j != i and (t[4] == "debris" or j > i)]
	problems += problems_of(n, pos, cs, h, kind, build, others)
for b in problems:
	print("RULE:", b)

# ---------------------------------------------------------------- write it
for p in pieces:
	if p["id"].startswith("foundation") and 0.3 <= p["pos"][1] < rock_top(p["pos"][0], p["pos"][2]) + 0.05:
		p["anchor"] = True                             # (the lone tower's foundations sit in the rock lump)
pieces += rubble
out = GAME / "blueprints" / "ruins" / "prow_hall_ruin.json"
radius = round(max(math.hypot(p["pos"][0], p["pos"][2]) for p in pieces) + 1.5, 1)
json.dump({"name": "Prow Hall", "radius": radius, "height": 16.0, "front": 21.0, "square": True, "reach": radius + 6.0,
	"pieces": pieces, "chests": chests, "beetles": beetles, "props": props},
	open(out, "w", encoding="utf-8"), separators=(",", ":"))
counts = {}
for p in pieces:
	counts[p["id"]] = counts.get(p["id"], 0) + 1
print("WROTE", out.name, len(pieces), "pieces (whole had", len(whole), "),", len(rubble), "rubble,", len(chests), "chests,",
	len(props), "props, radius", radius, ";", len(problems), "rule problems")
