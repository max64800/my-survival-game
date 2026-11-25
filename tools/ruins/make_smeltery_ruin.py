# The RUINED Smeltery Terraces (owner, Nov 24-25: ruin 10, F845; docs/design/ruin10/SMELTERY-PLAN.md).
#   godot --headless --audio-driver Dummy --path . -s res://tools/dump_blueprint.gd -- hearthbrick_smeltery <s.json>
#   python tools/ruins/make_smeltery_ruin.py <s.json>
# Writes blueprints/ruins/smeltery_ruin.json (pieces, chests with loot, lootable props, beetle spots) for the world to
# place (src/world/ruin_smeltery.gd, which also finds a natural cave for it and digs the dip under the bridge).
# What happened: the owner-approved 3D page (tools/ruins/make_smeltery_page.py: the same dice, the same parts, the same
# heights each part still stands to). The furnace lost its top, the hall its upper storey and roof, the turrets their
# tops, the bridge's span between the pier and the terrace fell into the dip, its wood roof rotted away; the tower
# keeps its ring room and a broken chimney stump. Then made sound for the game: no doors (gone, like every ruin's),
# nothing hanging in the air (railings whose floor fell, trims and ladders whose wall fell), rubble lies on the floor
# it fell onto, never on stairs, in doorways or on the walk lines (the junk rules, tools/ruins/ruin_junk.py).
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

# ---------------------------------------------------------------- the page's sketch (keep in step with make_smeltery_page.py)
FURNACE, TOWER = (-19.732, -1.0), (18.0, -6.0)
BRIDGE = (-16.0, -8.0)
TURRET, WATCH = (-4.05, -3.5), (24.052, 2.4)
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
	if x > 14.2 and (z < -1.8 or y > 3.4) or y > 12.4:
		return "tower"
	if -3.2 < x < 13.2 and z < 0.2 and y > 3.1:
		return "hall"
	return "vaults"


WALLISH = ("wall", "window_wall", "window_wide", "doorway", "sloped_wall")
rng = random.Random(10)
ruin, fell, standing = [], [], set()   # fell: (x, y it landed at or None, z, y it fell from)
for i, p in enumerate(whole):
	x, y, z = p["pos"]
	k = part(x, z, y)
	cut = CUT[k]
	top = cut - BAND.get(k, 2.3) < y <= cut
	r = rng.random()
	q = dict(p, pos=list(p["pos"]))
	if k == "bridge":
		t = x - BRIDGE[0]
		gap = 4.4 < t < 5.6
		if p["id"] in ("roof_45_ridge", "pillar") or gap or p["id"] == "railing" and r < 0.5:
			fell.append((x, "dip" if gap or 3.5 < t < 6.5 and r < 0.5 else None, z, y))
			continue
	elif k == "vaults":
		if p["id"] == "door" and r < 0.7 or p["id"] == "railing" and r < 0.35:
			continue
		if p["id"] == "floor" and abs(y - 3.0) < 0.1 and r < 0.06:
			fell.append((x, None, z, y))
			continue
	elif y > cut:
		if p["id"] in WALLISH + ("floor", "roof_45", "beam") and r < 0.18:
			fell.append((x, None, z, y))
		continue
	elif p["id"] == "door":
		if r < 0.7:
			continue
	elif top and p["id"] in WALLISH:
		if r < 0.25:
			fell.append((x, None, z, y))
			continue
		if p["id"] in ("wall", "window_wall", "doorway"):
			q["id"] = "ruin_wall_collapsed" if r < 0.55 else ("ruin_wall_worn" if r < 0.8 else p["id"])
	elif top and p["id"] in ("pillar", "railing", "cornice", "cornice_corner", "corbel"):
		if r < 0.5:
			continue
	elif top and p["id"] in ("floor", "floor_triangle") and y > 1.5:
		if k not in BAND and (r < 0.4 or y > cut - 1.0):
			continue   # (the turrets keep their top floors: their broken top walls stand on them, Structure test)
	ruin.append(q)
	if q["id"] == p["id"]:
		standing.add(i)

# A railing whose floor fell goes with it (the page's rule).
gone_floors = [whole[i]["pos"] for i in range(len(whole)) if i not in standing and whole[i]["id"] in ("floor", "floor_triangle")]
gone_floors = [f for f in gone_floors if not any(q["pos"] == f and q["id"].startswith("floor") for q in ruin)]
ruin = [q for q in ruin if not (q["id"] in ("railing", "door") and any(0.0 < q["pos"][1] - f[1] < 0.5
	and dist((q["pos"][0], q["pos"][2]), (f[0], f[2])) < 1.2 for f in gone_floors))]
pieces = [q for q in ruin if q["id"] != "door"]   # (the game's ruins have lost every door, like the Prow Hall's)

# ---------------------------------------------------------------- made sound: nothing hangs in the air
TRIMS = ("cornice", "cornice_corner", "corbel")
ON_WALL = TRIMS + ("ladder",)
FLOORS = ("floor", "floor_triangle", "foundation", "foundation_triangle", "foundation_steps")
HOLDS = WALLISH + ("ruin_wall_worn", "pillar", "column", "column_shaft", "column_capital")


def height_of(p):
	return 0.8 if p["id"] == "ruin_wall_collapsed" else RJ.PIECES[p["id"]]["size"][1]


def top_of(p):
	return p["pos"][1] + height_of(p)


def grounded(p):
	return p["pos"][1] < 0.3


def held(p):
	"""Something solid right under it (a floor's or a wall's top), or for trims and ladders the wall they hang on."""
	y = p["pos"][1]
	if p["id"] in ON_WALL:
		fp = RJ.footprint(p, 0.12)
		for q in pieces:
			if q is not p and q["id"] in HOLDS and q["pos"][1] - 0.1 < y + (1.0 if p["id"] == "ladder" else 0.0) < top_of(q) + 0.1 \
					and RJ.overlap(fp, RJ.footprint(q, 0.05)):
				return True
		return False
	fp = RJ.footprint(p, -0.05)
	for q in pieces:
		if q is p or q["id"] in TRIMS or q["id"] in ("railing", "ladder"):
			continue
		if abs(top_of(q) - y) < 0.3 and RJ.overlap(fp, RJ.footprint(q, 0.02)):
			return True
	return False


changed = True
while changed:
	changed = False
	for p in list(pieces):
		if grounded(p) or p["id"] in ("floor", "floor_triangle", "roof_45", "roof_45_ridge", "gable_45", "dormer"):
			continue          # (floors and roofs hang on their walls and each other: the game's strength test checks them)
		if not held(p):
			pieces.remove(p)
			fell.append((p["pos"][0], None, p["pos"][2], p["pos"][1]))
			changed = True
			print("UNHELD", p["id"], p["pos"])

# A ladder must go from a floor that still stands to one that still stands (the turrets' tops fell: their top ladders
# would lead into the sky).
def floor_top_near(x, z, y, r=1.7):
	return any(q["id"] in FLOORS and abs(top_of(q) - y) < 0.1 and math.hypot(q["pos"][0] - x, q["pos"][2] - z) < r for q in pieces)


for p in list(pieces):
	if p["id"] == "ladder" and not (floor_top_near(p["pos"][0], p["pos"][2], p["pos"][1])
			and floor_top_near(p["pos"][0], p["pos"][2], p["pos"][1] + 2.25)):
		pieces.remove(p)
		print("LADDER TO NOWHERE", p["pos"])


# ---------------------------------------------------------------- the dip under the bridge (ruin_smeltery.gd: dip_at)
def smooth(t):
	t = max(0.0, min(1.0, t))
	return t * t * (3 - 2 * t)


DIP = 2.5
DIP_X = (-11.7, -8.6)     # between the bridge's pier (x -14..-12) and the terrace's side wall (x -8)
DIP_Z = (0.5, 5.0)        # a gully in the cave floor just in front of the bridge (z -1): its 3 rows of columns stand on flat ground (owner, Nov 25)


def dip_at(x, z):
	return -DIP * smooth((x - DIP_X[0]) / 0.9) * smooth((DIP_X[1] - x) / 0.9) * smooth((z - DIP_Z[0]) / 2.0) * smooth((DIP_Z[1] - z) / 2.0)


# ---------------------------------------------------------------- the rules check (tools/ruins/ruin_junk.py's numbers)
WALK = {   # walk lines between the doorways and stairs, per floor top
	0.0: [((1, 12), (1, 9.5)), ((9, 12), (9, 9.5)), ((-19.73, 9), (-19.73, 6.5)), ((-10.5, -7), (-9.5, -7)),
		((24.5, -7), (23.5, -7)), ((22.6, 7), (22.6, 5.5))],
	1.0: [((1, 8), (5, 4.6)), ((9, 8), (5, 4.6)), ((-1, 2), (-1, -2)), ((11, 2), (11, -2)), ((19, 2), (19, -2)),
		((-8, -7), (-4, -7)), ((22, -7), (21, -6)), ((-19.73, 4.9), (-21, -1)), ((23.19, 3.9), (23.3, 1.6))],
	3.25: [((5, 1.6), (5, -2)), ((-8, -1), (-16, -1)), ((5, 0), (-4.9, -1.5)), ((5, 0), (17, -1.5)), ((-19.73, 1.7), (-16.5, -1))],
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
	if floor_y > 0.05 and not all(floor_under(pt, floor_y, build) for pt in cs + [(pos[0], pos[2])]):
		bad.append(f"{tag}: a corner over no floor")
	for p in build:
		lo, hi = p["pos"][1], top_of(p)
		if p["id"] in RJ.STAIRS or p["id"] == "ladder":
			grow = RJ.STAIR_CLEAR if kind != "debris" else 0.5
			if p["id"] == "foundation_steps" and y > hi - 0.05:
				grow = 0.0
			if lo - 0.3 < y < hi + 0.3 and RJ.overlap(cs, RJ.footprint(p, grow)):
				bad.append(f"{tag}: on or by the stairs/ladder at {p['pos']}")
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

# ---------------------------------------------------------------- the works' things
_dims = {}


def dims(model, folder="decor"):
	if model not in _dims:
		lo, hi = bounds(str(GAME / f"assets/models/{folder}" / f"{model}.glb"))
		_dims[model] = (float(hi[0] - lo[0]), float(hi[1] - lo[1]), float(hi[2] - lo[2]))
	return _dims[model]


def chest_at(kind, x, z, y, loot):
	return {"kind": kind, "pos": [round(x, 3), y, round(z, 3)], "yaw": 0, "loot": loot}


def loot_at(model, label, x, z, y, yaw=0):
	return {"model": f"decor/{model}.glb", "pos": [x, round(y + 0.01, 3), z], "yaw": yaw, "role": "lootable", "label": label}


chests = [
	chest_at("chest_stone", -4.5, -9.0, 1.0, {"recipe_page": 1, "rope": 3}),                      # the back-left ore vault
	chest_at("chest_stone", 6.0, -9.0, 1.0, {"recipe_page": 1, "blueprint_page": 1}),             # the long vault under the hall
	chest_at("chest_small", 4.0, 0.0, 1.0, {"recipe_page": 1}),                                   # the front vault
	chest_at("chest_copper", 16.6, -7.9, 14.5, {"recipe_page": 2, "blueprint_page": 2}),         # the tower's ring room, way up
]
props = [   # (lootable: an ingot stack, carts and coal by the furnaces; LootProps gives their few things)
	loot_at("cf_ingot_stack", "Ingot stack", 9.0, -8.8, 1.0),
	loot_at("hw_ingot_cart", "Ingot cart", 15.5, 0.0, 1.0, 90),
	loot_at("ef_coal_scuttle", "Coal scuttle", -18.0, -3.6, 1.0),
	loot_at("cf_charcoal_bay", "Charcoal bay", -4.5, 0.2, 1.0),
]
beetles = [[5.0, 1.0, 6.0], [5.0, 3.25, -6.0], [-10.0, 0.2, 3.0], [18.0, 1.0, -6.0], [-19.7, 1.0, -1.0]]

for c in chests:
	sx, h, sz = dims(c["kind"], "stations")
	things.append((c["kind"], c["pos"], corners_of(c["pos"][0], c["pos"][2], sx, sz, c["yaw"]), h, "chest"))
for pr in props:
	sx, h, sz = dims(pr["model"][6:-4])
	things.append((pr["model"], pr["pos"], corners_of(pr["pos"][0], pr["pos"][2], sx, sz, pr["yaw"]), h, "prop"))

# ---------------------------------------------------------------- rubble where things fell
CELLS = {(math.floor(p["pos"][0] / 2 + 0.5), math.floor(p["pos"][2] / 2 + 0.5)) for p in whole}   # (RuinSmeltery.ground)
rubble = []
for (x0, y, z0, y0) in fell:
	for attempt in range(8):                           # (a few spots around where it fell, the first that keeps the rules)
		x, z = x0 + rng.uniform(-1.2, 1.2), z0 + rng.uniform(-1.2, 1.2)
		if y == "dip":
			x = min(max(x, DIP_X[0] + 0.9), DIP_X[1] - 0.9)
			ry = round(dip_at(x, z), 2)                # down in the dip under the bridge
		else:
			under = [f for f in build if f["id"] in FLOORS and f["id"] != "foundation_steps" and top_of(f) < y0 + 0.1
				and RJ.inside((x, z), RJ.footprint(f, 0.0))]
			if under:
				f = max(under, key=top_of)             # the highest floor under where it fell: it lands on that tile
				ry = top_of(f)
				x = f["pos"][0] + max(-0.35, min(0.35, x - f["pos"][0]))
				z = f["pos"][2] + max(-0.35, min(0.35, z - f["pos"][2]))
			else:
				ry = 0.0                               # the cave floor (only its own ground: the world keeps that clear)
				if z < -9.5 or dip_at(x, z) < -0.05 or (math.floor(x / 2 + 0.5), math.floor(z / 2 + 0.5)) not in CELLS:
					continue                           # (behind the back walls is the cave's rock; not on the dip's slope)
		q = {"id": "ruin_rubble", "mat": "clay_brick", "pos": [round(x, 3), ry, round(z, 3)], "rot": 4 + rng.randrange(12)}
		cs = RJ.footprint(q)
		if problems_of("ruin_rubble", q["pos"], cs, 0.7, "debris", build, things):
			continue
		rubble.append(q)
		things.append(("ruin_rubble", q["pos"], cs, 0.7, "debris"))
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
pieces += rubble
out = GAME / "blueprints" / "ruins" / "smeltery_ruin.json"
radius = round(max(math.hypot(p["pos"][0], p["pos"][2]) for p in pieces) + 1.5, 1)
json.dump({"name": "Smeltery Terraces", "radius": radius, "height": 24.0, "front": 12.0, "square": True, "reach": radius + 6.0,
	"pieces": pieces, "chests": chests, "beetles": beetles, "props": props},
	open(out, "w", encoding="utf-8"), separators=(",", ":"))
counts = {}
for p in pieces:
	counts[p["id"]] = counts.get(p["id"], 0) + 1
print("WROTE", out.name, len(pieces), "pieces (whole had", len(whole), "),", len(rubble), "rubble,", len(chests), "chests,",
	len(props), "props, radius", radius, ";", len(problems), "rule problems")
print(sorted(counts.items()))
