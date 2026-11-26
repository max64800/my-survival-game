# The RUINED Cliff Galleries (owner, Nov 26: ruin 13, F913; docs/design/ruin13/CLIFF-GALLERIES-PLAN.md).
#   godot --headless --audio-driver Dummy --path . -s res://tools/dump_blueprint.gd -- cliff_galleries <b.json>
#   python tools/ruins/make_cliff_galleries_ruin.py <b.json>
# Writes blueprints/ruins/cliff_galleries_ruin.json (pieces, chests with loot, lootable and decor props, torches) for
# the world to place (src/world/ruin_cliff_galleries.gd, which finds a tall cave wall for it, fills any rock missing
# under its shelf and its ledge, and digs its niches, the crack and the yard).
# What happened: the owner-approved 3D page (tools/ruins/make_cliff_galleries_page.py: the same dice in the same order).
# The Hanging Gallery's middle fell onto the Stone Hall's roof, the bridge's far span sags over the crack, the lookout's
# roof leans, the tile roofs have holes, a few brick walls, battlements and railings fell. Then made sound for the game:
# no doors (gone, like every ruin's), nothing hanging in the air, rubble lies on the floor or ground it fell onto, never
# on stairs, in doorways or on the walk lines (the junk rules, tools/ruins/ruin_junk.py).
# Fallen things that keep their shape (the gallery's two floors, the bridge's sagging floor, the lookout's leaning roof
# corners) are "fallen": true pieces with a "tilt": RuinTower places them as tipped rubble (you hit them to clear them).
# The box: the crack's floor is near y 0, the cave floor y 5 (the ledge 9.5, the shelf 15.75), so every piece standing
# on its own ground gets "anchor": true (RuinTower places only y < 0.3 as anchored by itself).
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

SHIFT = (-2.0, 5.0, 5.0)                    # BlueprintLibrary.CG_SHIFT
G = 5.0


def local(p):
	return p["pos"][0] - SHIFT[0], p["pos"][1] - SHIFT[1], p["pos"][2] - SHIFT[2]


def box(x, y, z):
	"""Local metres (the cave floor y 0) -> the box's."""
	return [round(x + SHIFT[0], 3), round(y + SHIFT[1], 3), round(z + SHIFT[2], 3)]


def ground_local(x, z):
	"""BlueprintLibrary._cliff_ground (local) and the niches dug into the cliff (_cliff_rock); 99 = rock. The crack
	ramps back up to the cave floor in front (local z 0..7, RuinCliffGalleries.rise_at)."""
	if z < -11.2:
		if -5.2 < x < 5.2 and z > -15.2:
			return 0.0                         # the Stone Hall's niche
		if 10.8 < x < 21.2 and z > -15.2:
			return 4.5                         # the Ledge House's
		if -17.2 < x < -8.8 and z > -13.2:
			return 10.75                       # the Watch Tower's
		return 99.0
	if x < -7.2 and z < -1.2:
		return 10.75
	if x > 11.0 and z < -1.2:
		return 4.5
	if 7.0 < x < 11.0 and z > -9.2:
		if z > 0.0:
			t = min(1.0, z / 7.0)
			return -4.75 * (1.0 - t * t * (3.0 - 2.0 * t))
		return -4.75
	return 0.0


def rock_top(bx, bz):
	"""The ground's top in box metres at box (x, z)."""
	g = ground_local(bx - SHIFT[0], bz - SHIFT[2])
	return 99.0 if g > 90 else g + G


# ---------------------------------------------------------------- the page's dice (keep in step with make_cliff_galleries_page.py)
rng = random.Random(13)
pieces, fell, standing = [], [], set()      # fell: (x, z, y it fell from)  (box metres)
for i, p in enumerate(whole):
	x, y, z = local(p)
	r = rng.random()
	q = dict(p, pos=list(p["pos"]))
	brick = p["mat"] == "clay_brick"
	if -3.2 < x < 1.2 and -11.5 < z < -8.5 and y > 11.0:          # the gallery's middle, fallen onto the hall's roof
		if p["id"] == "floor":
			dx, dz = rng.uniform(-0.3, 0.3), rng.uniform(0.2, 0.8)
			tilt = rng.uniform(-0.3, 0.3)
			tilt = math.copysign(max(abs(tilt), 0.15), tilt)
			q["pos"] = box(x + dx, 5.5 + math.sin(abs(tilt)) + 0.04, z + dz)
			q["fallen"], q["tilt"] = True, round(tilt, 3)
			pieces.append(q)
		elif r < 0.6:
			fell.append((p["pos"][0], p["pos"][2], p["pos"][1]))
		continue
	if 9.0 < x < 11.2 and -5.5 < z < -2.5 and y > 5.0:            # the bridge's far span sags
		if p["id"] == "floor":
			q["pos"] = [p["pos"][0], round(p["pos"][1] - 0.35, 3), p["pos"][2]]
			q["fallen"], q["tilt"] = True, 0.12
			pieces.append(q)
		elif r < 0.5:
			fell.append((p["pos"][0], p["pos"][2], p["pos"][1]))
		continue
	if p["id"] == "roof_45_outer":                                 # the lookout's roof leans
		q["pos"] = [p["pos"][0], round(p["pos"][1] - 0.1, 3), p["pos"][2]]
		q["fallen"], q["tilt"] = True, 0.1
		pieces.append(q)
		continue
	if p["id"] == "door" and r < 0.6:
		continue
	if p["id"].startswith("roof_") and r < 0.35:
		continue
	if brick and p["id"] in ("wall", "window_wall") and y > 7.0 and r < 0.1:
		fell.append((p["pos"][0], p["pos"][2], p["pos"][1]))
		continue
	if p["id"] in ("battlement", "railing") and r < 0.25:
		fell.append((p["pos"][0], p["pos"][2], p["pos"][1]))
		continue
	pieces.append(q)
	standing.add(i)

gone_floors = [whole[i]["pos"] for i in range(len(whole)) if i not in standing and whole[i]["id"] == "floor"]
pieces = [q for q in pieces if q.get("fallen") or not (q["id"] in ("railing", "door") and any(
	0.0 < q["pos"][1] - f[1] < 0.5 and math.dist((q["pos"][0], q["pos"][2]), (f[0], f[2])) < 1.2 for f in gone_floors))]
pieces = [q for q in pieces if q["id"] != "door"]   # (every door rotted away, like every ruin's)

# ---------------------------------------------------------------- made sound: nothing hangs in the air
TRIMS = ("cornice", "cornice_corner", "corbel", "wall_sconce")
ON_WALL = TRIMS + ("ladder", "beam")   # (a beam hangs between its posts' tops)
FLOORS = ("floor", "floor_triangle", "foundation", "foundation_triangle", "foundation_steps")
WALLISH = ("wall", "window_wall", "window_wide", "doorway", "sloped_wall", "gable_26", "gable_45", "half_wall")
HOLDS = WALLISH + ("pillar", "beam", "ladder")


def height_of(p):
	return RJ.PIECES[p["id"]]["size"][1]


def top_of(p):
	return p["pos"][1] + height_of(p)


def solid():
	return [q for q in pieces if not q.get("fallen")]


def grounded(p):
	return p["pos"][1] < 0.3 or abs(p["pos"][1] - rock_top(p["pos"][0], p["pos"][2])) < 0.3


def held(p, build):
	y = p["pos"][1]
	if p["id"] in ON_WALL:
		fp = RJ.footprint(p, 0.12)
		for q in build:
			if q is not p and q["id"] in HOLDS and q["pos"][1] - 0.1 < y + (1.0 if p["id"] == "ladder" else 0.0) < top_of(q) + 0.1 \
					and RJ.overlap(fp, RJ.footprint(q, 0.05)):
				return True
		return False
	fp = RJ.footprint(p, -0.05)
	for q in build:
		if q is p or q["id"] in TRIMS or q["id"] in ("railing", "ladder"):
			continue
		if abs(top_of(q) - y) < 0.3 and RJ.overlap(fp, RJ.footprint(q, 0.02)):
			return True
	return False


changed = True
while changed:
	changed = False
	build = solid()
	for p in list(build):
		if grounded(p) or p["id"] in ("floor", "floor_triangle", "roof_26", "roof_45", "gable_26", "gable_45", "ramp") \
				or p["id"] not in RJ.PIECES:
			continue          # (floors and roofs hang on their walls and each other: the game's strength test checks them)
		if not held(p, build):
			pieces.remove(p)
			build.remove(p)
			fell.append((p["pos"][0], p["pos"][2], p["pos"][1]))
			changed = True
			print("UNHELD", p["id"], p["pos"])

# ---------------------------------------------------------------- the rules check (tools/ruins/ruin_junk.py's numbers)
WALK_LOCAL = {   # walk lines between the doorways, stairs and ladders, per floor (or ground) top, local metres
	1.0: [((0, 3), (0, -9)), ((0, -6), (4, -6)), ((-6, 2), (6, 2)), ((-16, 3), (-16, 1))],
	0.0: [((-16, 5), (3, 5))],
	5.5: [((4, -9), (4, -4)), ((4, -4), (11, -4)), ((0, -7), (0, -9)), ((11, -4), (20, -4)), ((20, -4), (20, -8))],
	7.75: [((20, -8), (11, -10)), ((11, -10), (8, -10))],
	11.75: [((4, -10), (-6, -10)), ((-6, -10), (-9, -6)), ((-9, -6), (-12, -8))],
	14.0: [((-12, -11), (-16, -8))],
	16.25: [((-16, -6), (-10, -4))],
	18.5: [((-10, -6), (-11, -8)), ((-11, -8), (-13, -7))],
	-4.75: [((9, -8), (9, 3))],
}
WALK = {round(y + G, 2): [((a[0] + SHIFT[0], a[1] + SHIFT[2]), (b[0] + SHIFT[0], b[1] + SHIFT[2])) for a, b in lines]
	for y, lines in WALK_LOCAL.items()}


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
	walls = [w for w in build if w["id"] in ("wall", "window_wall", "window_wide") and abs(w["pos"][1] - door["pos"][1]) < 0.3]
	for i in range(1, 20):
		t = i / 20
		pt = (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)
		if any(RJ.inside(pt, RJ.footprint(w, 0.0)) for w in walls):
			return True
	return False


def floor_under(pt, y, build, grow=0.02):
	if abs(rock_top(pt[0], pt[1]) - y) < 0.06:
		return True                                    # (its own ground: the cave floor, the shelf, the ledge, the crack)
	return any(f["id"] in FLOORS and f["id"] != "foundation_steps" and abs(top_of(f) - y) < 0.06
		and RJ.inside(pt, RJ.footprint(f, grow)) for f in build)


def problems_of(name, pos, cs, h, kind, build, others):
	"""One thing (prop, chest, debris) against the rules. -> list of problems."""
	bad = []
	y = pos[1]
	floor_y = round(y - (0.01 if kind == "prop" else 0.0), 2)
	tag = f"{name} at ({pos[0]:.2f}, {y:.2f}, {pos[2]:.2f})"
	if not all(floor_under(pt, floor_y, build) for pt in cs + [(pos[0], pos[2])]):
		bad.append(f"{tag}: a corner over no floor")
	for p in build:
		lo, hi = p["pos"][1], top_of(p)
		if p["id"] in RJ.STAIRS or p["id"] == "ladder":
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


build = [p for p in solid() if p["id"] in RJ.PIECES]
things = []      # (name, pos, corners, height, kind)

# ---------------------------------------------------------------- its things (local metres in, box metres out)
_dims = {}


def dims(model, folder="decor"):
	if model not in _dims:
		lo, hi = bounds(str(GAME / f"assets/models/{folder}" / f"{model}.glb"))
		_dims[model] = (float(hi[0] - lo[0]), float(hi[1] - lo[1]), float(hi[2] - lo[2]))
	return _dims[model]


def chest_at(kind, x, y, z, loot, yaw=0):
	return {"kind": kind, "pos": box(x, y, z), "yaw": yaw, "loot": loot}


def prop_at(model, x, y, z, yaw=0, role="lootable", label=""):
	q = {"model": f"decor/{model}.glb", "pos": box(x, y + 0.01, z), "yaw": yaw, "role": role}
	if label:
		q["label"] = label
	return q


chests = [
	chest_at("chest_copper", -13.9, 18.5, -5.9, {"recipe_page": 2, "blueprint_page": 2}),   # the tower's lookout: the best
	chest_at("chest_stone", -3.6, 1.0, -13.6, {"recipe_page": 1, "rope": 4}),                # the Stone Hall
	chest_at("chest_small", 17.0, 7.75, -13.4, {"recipe_page": 1}),                          # the Ledge House's upper floor
]
props = [
	prop_at("bv_strongbox", 3.4, 1.0, -13.6, label="Strongbox"),                             # the Stone Hall
	prop_at("bv_pigeonholes", 14.0, 5.5, -13.6, label="Pigeonholes"),                        # the Ledge House
	prop_at("ro_quiver_rack", -15.4, 14.0, -11.4, label="Quiver rack"),                      # the tower's first floor
	prop_at("ef_coal_scuttle", -12.6, 1.0, 1.0, label="Coal scuttle"),                       # the shed
]
torches = [box(*t) for t in ((-4.4, 1.0, -9.0), (4.4, 1.0, -3.6), (-18.4, 1.0, 1.4), (13.0, 5.5, -9.0), (-15.4, 11.75, -5.0),
	(21.4, 7.75, -9.0))]
beetles = [box(*b) for b in ((-2.0, 1.0, -9.0), (-4.0, 1.0, 1.0), (9.0, -4.75, -6.0), (16.0, 5.5, -9.0), (-13.0, 11.75, -6.0))]

for c in chests:
	sx, h, sz = dims(c["kind"], "stations")
	things.append((c["kind"], c["pos"], corners_of(c["pos"][0], c["pos"][2], sx, sz, c["yaw"]), h, "chest"))
for pr in props:
	sx, h, sz = dims(pr["model"][6:-4])
	things.append((pr["model"], pr["pos"], corners_of(pr["pos"][0], pr["pos"][2], sx, sz, pr["yaw"]), h, "prop"))
for t in torches:
	things.append(("crystal_torch", t, corners_of(t[0], t[2], 0.4, 0.4, 0), 1.6, "prop"))

# ---------------------------------------------------------------- rubble where things fell
CELLS = {(math.floor(p["pos"][0] / 2 + 0.5), math.floor(p["pos"][2] / 2 + 0.5)) for p in whole}   # (RuinCliffGalleries.ground)
rubble = []
for (x0, z0, y0) in fell:
	for attempt in range(24):
		x, z = x0 + rng.uniform(-1.2, 1.2), z0 + rng.uniform(-1.2, 1.2)
		under = [f for f in build if f["id"] in FLOORS and f["id"] != "foundation_steps" and top_of(f) < y0 + 0.1
			and RJ.inside((x, z), RJ.footprint(f, 0.0))]
		if under:
			f = max(under, key=top_of)
			ry = top_of(f)
			x = f["pos"][0] + max(-0.35, min(0.35, x - f["pos"][0]))
			z = f["pos"][2] + max(-0.35, min(0.35, z - f["pos"][2]))
		else:
			ry = rock_top(x, z)
			if ry > 90 or ry > y0 + 0.1 or ry != rock_top(x + 0.6, z + 0.6) or ry != rock_top(x - 0.6, z - 0.6) \
					or (math.floor(x / 2 + 0.5), math.floor(z / 2 + 0.5)) not in CELLS:
				continue
		q = {"id": "ruin_rubble", "mat": "cut_stone", "pos": [round(x, 3), ry, round(z, 3)], "rot": 4 + rng.randrange(12)}
		cs = RJ.footprint(q)
		if problems_of("ruin_rubble", q["pos"], cs, 0.7, "debris", build, things):
			continue
		rubble.append(q)
		things.append(("ruin_rubble", q["pos"], cs, 0.7, "debris"))
		break
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
pieces += rubble
anchored = 0
for p in pieces:
	if not p.get("fallen") and p["pos"][1] >= 0.3 and abs(p["pos"][1] - rock_top(p["pos"][0], p["pos"][2])) < 0.3:
		p["anchor"] = True
		anchored += 1
out = GAME / "blueprints" / "ruins" / "cliff_galleries_ruin.json"
radius = round(max(math.hypot(p["pos"][0], p["pos"][2]) for p in pieces) + 1.5, 1)
json.dump({"name": "Cliff Galleries", "radius": radius, "height": 30.0, "front": 14.0, "square": True, "reach": radius + 6.0,
	"floor": G, "pieces": pieces, "chests": chests, "beetles": beetles, "props": props, "torches": torches},
	open(out, "w", encoding="utf-8"), separators=(",", ":"))
counts = {}
for p in pieces:
	counts[p["id"]] = counts.get(p["id"], 0) + 1
print("WROTE", out.name, len(pieces), "pieces (whole had", len(whole), "),", len(rubble), "rubble,", anchored, "anchored,",
	len(chests), "chests,", len(props), "props, radius", radius, ";", len(problems), "rule problems")
print(sorted(counts.items()))
