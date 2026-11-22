# The RUINED Hearth Manor (owner, Nov 22: ruin 7, F479; docs/design/GRAND-RUIN-RECIPE.md).
#   godot --headless --audio-driver Dummy --path . -s res://tools/dump_blueprint.gd -- hearthbrick_manor <brick.json>
#   godot --headless --audio-driver Dummy --path . -s res://tools/dump_blueprint.gd -- wooden_manor <wood.json>
#   python tools/ruins/make_manor_ruin.py <brick.json> [wood=<wood.json>] [page=<folder>]
# Writes blueprints/ruins/manor_ruin.json (pieces, chests with loot, props, beetle spots) for the world to place.
# The manor (BlueprintLibrary._hearth_manor): a two-storey hall on a terrace with a grand stair, a wing on its left
# with a balcony on brackets, a low link on its right, and a 4-by-4 three-storey tower with a lookout room on its
# roof, a gallery round it.
# What happened: the tower's pointed roof blew off and the lookout's back-right corner fell with a piece of the
# gallery; the hall's roof caved in at its back-left corner and took a piece of the upper floor with it; half of the
# wing's balcony fell (its brackets still stick out of the wall); one terrace railing is down; the doors are gone and
# walls are worn. The family's things are still there (docs/art/DECOR-CATALOG.md home sets), each checked against the
# junk rules (tools/ruins/ruin_junk.py).
import base64
import json
import math
import random
import struct
import sys
from pathlib import Path

GAME = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(GAME / "tools" / "ruins"))
sys.path.insert(0, str(GAME / "tools" / "dungeons"))
import ruin_junk as RJ                      # noqa: E402  (piece sizes, outlines, overlap)
from glb_bounds import bounds               # noqa: E402

args = sys.argv[1:]
bp = json.load(open(args[0], encoding="utf-8"))
page = next((Path(a[5:]) for a in args if a.startswith("page=")), None)
wood_bp = next((json.load(open(a[5:], encoding="utf-8")) for a in args if a.startswith("wood=")), None)
rng = random.Random(7)
FLOOR_TOPS = (0.0, 1.0, 3.25, 5.5, 7.75)
WALLISH = ("wall", "window_wall", "window_wide", "doorway", "wall_narrow", "half_wall", "ruin_wall_worn", "ruin_wall_collapsed")
TRIMS = ("corbel", "cornice", "cornice_corner")


def rot_from(steps):
	k = steps % 12
	return k // 3 if k % 3 == 0 else 4 + k


def plan_of(b):
	return [{"id": p["id"], "mat": p["mat"], "pos": [round(v, 4) for v in p["pos"]], "rot": p["rot"]} for p in b["pieces"]]


def near(p, x, z, r=0.3):
	return abs(p["pos"][0] - x) < r and abs(p["pos"][2] - z) < r


def at(p, x, y, z):
	return near(p, x, z, 0.15) and abs(p["pos"][1] - y) < 0.05


# ---------------------------------------------------------------- break it
GONE = [
	# the tower's pointed roof blew off
	*[("roof_45_outer", x, 9.75, z) for x in (11, 13) for z in (-4, -2)],
	# the lookout's back-right corner fell, with the gallery's corner beside it
	("window_wide", 14, 7.75, -4), ("window_wide", 13, 7.75, -5),
	("floor", 15, 7.5, -6), ("floor", 15, 7.5, -4), ("floor", 13, 7.5, -6),
	# the hall's roof caved in at the back-left, and the upper floor under it fell in
	("roof_45", -3, 5.25, -6), ("roof_45", -1, 5.25, -6), ("roof_45", -3, 7.25, -4), ("roof_45", -1, 7.25, -4),
	("roof_45", -3, 7.25, -2), ("gable_45", -4, 7.25, -4), ("floor", -3, 3.0, -6),
	# half of the wing's balcony fell (its brackets stay in the wall)
	("floor", -11, 3.0, -2), ("floor", -9, 3.0, -2),
	# one terrace railing
	("railing", -4, 1.0, 4),
]
COLLAPSE = [(-3, 3.25, -7), (-4, 3.25, -6), (-4, 5.25, -4), (14, 7.75, -2)]   # walls broken down to a stump
KEEP_WHOLE = ("cornice", "cornice_corner", "corbel")


def gone(p):
	return any(p["id"] == g[0] and at(p, *g[1:]) for g in GONE)


pieces = []
for p in plan_of(bp):
	pid = p["id"]
	q = dict(p, pos=list(p["pos"]))
	if pid == "door" or gone(p):
		continue
	if pid in WALLISH and any(at(p, *c) for c in COLLAPSE):
		q["id"] = "ruin_wall_collapsed"
	pieces.append(q)


def top_of(p):
	return p["pos"][1] + RJ.PIECES[p["id"]]["size"][1]


def under_something(w):
	"""A wall with a roof, gable or wall right on top of it (wearing it would leave that floating)."""
	fw = RJ.footprint(w, -0.05)
	for p in pieces:
		if p is w or p["id"] in TRIMS or p["id"] not in RJ.PIECES:
			continue
		if abs(p["pos"][1] - top_of(w)) < 0.3 and RJ.overlap(fw, RJ.footprint(p, 0.0)):
			return True
	return False


# worn walls: about a third of the walls with nothing resting on them
for w in pieces:
	if w["id"] in ("wall", "window_wall") and not under_something(w) and rng.random() < 0.35:
		w["id"] = "ruin_wall_worn"


def supported(p):
	"""Railings need the floor they stand on (a floor edge within reach, 0.25 m below)."""
	x, y, z = p["pos"]
	for f in pieces:
		if f["id"] in ("floor", "floor_half", "small_floor", "foundation") and abs(top_of(f) - y) < 0.06:
			if RJ.inside((x, z), RJ.footprint(f, 0.06)):
				return True
	return False


# Nothing stands on a collapsed wall; no railing where its floor fell in.
changed = True
while changed:
	changed = False
	low = [p for p in pieces if p["id"] == "ruin_wall_collapsed"]
	for p in list(pieces):
		if p["id"] in WALLISH + ("gable_45",) and p not in low:
			if any(near(c, p["pos"][0], p["pos"][2], 0.1) and 1.9 < p["pos"][1] - c["pos"][1] < 2.1 for c in low):
				pieces.remove(p)
				changed = True
				continue
		if p["id"] in ("railing", "railing_narrow") and not supported(p):
			pieces.remove(p)
			changed = True


def add(pid, x, y, z, yaw_deg, mat="clay_brick"):
	pieces.append({"id": pid, "mat": mat, "pos": [round(x, 3), y, round(z, 3)], "rot": rot_from(round(yaw_deg / 30))})


DEBRIS = ("ruin_rubble", "ruin_wall_collapsed")
n_before = len(pieces)
# Rubble where things fell: beside the tower's back-right corner (its lookout's corner), under the hall's caved roof (downstairs and up),
# below the wing's fallen balcony, by the terrace's fallen railing. Never in a doorway, on steps or stairs.
for (x, y, z, yaw) in [(17.0, 0.0, -5.6, 30), (17.2, 0.0, -3.3, 120), (-1.9, 1.0, -5.7, 0), (-1.0, 3.25, -5.75, 0),
		(-10.6, 0.0, -1.2, 60), (-8.4, 0.0, -0.9, 150), (-5.3, 0.0, 4.2, 210)]:
	add("ruin_rubble", x, y, z, yaw)

# ---------------------------------------------------------------- the family's things
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


def on_wall(model, facing, line, along, y, lift=0.0):
	"""Back to a wall (on the line), facing into the room; y = the floor's top. -> prop."""
	pos, yaw = wall_spot(dims(model)[2], facing, line, along, y + 0.01 + lift)
	return {"model": model, "pos": pos, "yaw": yaw}


def free_at(model, x, z, y, yaw=0):
	return {"model": model, "pos": [x, y + 0.01, z], "yaw": yaw}


def chest(kind, facing, line, along, y, loot):
	pos, yaw = wall_spot(dims(kind, "stations")[2], facing, line, along, y)
	return {"kind": kind, "pos": pos, "yaw": yaw, "loot": loot}


chests = [
	chest("chest_stone", "-x", 6.0, -2.3, 1.0, {"recipe_page": 1, "rope": 2}),                    # the great hall
	chest("chest_small", "+z", -7.0, -6.0, 3.25, {"recipe_page": 1, "blueprint_page": 1}),         # the wing upstairs
	chest("chest_copper", "+x", 10.0, -3.0, 7.75, {"recipe_page": 2, "blueprint_page": 1}),         # the lookout
]
props = [
	# the great hall: the family's game table and the master's high chair, a sideboard, the old lamps
	on_wall("hm_banded_sideboard", "+x", -4.0, -1.6, 1.0),
	free_at("stone_game_table", -1.3, -1.3, 1.0),
	free_at("hm_carved_high_chair", -1.3, -0.15, 1.0, 180),
	# the bedroom upstairs (front): bed under the window, wardrobe, desk under the wide window's side, books, basin
	on_wall("bunk_bed", "-z", 1.0, -2.5, 3.25),
	on_wall("wardrobe", "+x", -4.0, -1.5, 3.25),
	on_wall("writing_desk", "-z", 1.0, 4.0, 3.25),
	on_wall("hm_book_nook", "-x", 6.0, -1.5, 3.25),
	on_wall("washbasin", "-x", 6.0, 0.1, 3.25),
	# the kitchen (the wing downstairs, back right: the rest of it is the way through and the stairs)
	on_wall("bread_oven", "+z", -7.0, -5.2, 1.0),
	# the tower: a bin of bits downstairs, scrolls on the first floor, books on the second
	on_wall("parts_bin", "+z", -7.0, 10.5, 1.0),
	on_wall("hm_scroll_lattice", "-z", 1.0, 9.0, 3.25),
	on_wall("hm_book_nook", "-z", 1.0, 9.0, 5.5),
]
beetles = [[3.0, 1.0, -2.0], [-6.0, 1.0, -5.0], [-2.0, 1.0, 3.0], [11.0, 1.0, -3.0]]

# ---------------------------------------------------------------- the rules check (tools/ruins/ruin_junk.py's numbers)
# walk lines between the doorways (and stairs), per floor top
PATHS = {
	0.0: [((-13, -4), (-15, -4)), ((7, -4), (7, -6))],
	1.0: [((1, 6), (1, 0)), ((1, 0), (1, -4)), ((1, -4), (-4, -4)), ((1, -4), (1.2, -6)), ((1, 0), (6, 0)),
		((-4, -4), (-12, -4)), ((-7.3, -6), (-7.3, -4)), ((6, 0), (8, 0)), ((7, 0), (7, -3)), ((8, 0), (13, -6))],
	3.25: [((5, -6), (5, -4)), ((5, -4), (-4, -4)), ((-4, -4), (-11, -4)), ((-11, -6), (-11, -4)), ((-7, -4), (-7, -2)),
		((-7, -2), (-5, -2)), ((13, -6), (11, -6))],
	5.5: [((11, -6), (13, 0))],
	7.75: [((13, 0), (13, -2)), ((9, 0), (13, 0)), ((9, 0), (9, -6)), ((9, -6), (11, -6))],
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
	"""A whole wall stands between the thing and the doorway (it is in another room)."""
	a, b = (pos[0], pos[2]), (door["pos"][0], door["pos"][2])
	walls = [w for w in build if w["id"] in ("wall", "window_wall", "window_wide", "ruin_wall_worn") and abs(w["pos"][1] - door["pos"][1]) < 0.3]
	for i in range(1, 20):
		t = i / 20
		pt = (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)
		if any(RJ.inside(pt, RJ.footprint(w, 0.0)) for w in walls):
			return True
	return False


def check_things():
	"""Every prop, chest and bit of debris against the rules. -> list of problems."""
	bad = []
	things = []
	for pr in props:
		sx, h, sz = dims(pr["model"])
		things.append((pr["model"], pr["pos"], corners_of(pr["pos"][0], pr["pos"][2], sx, sz, pr["yaw"]), h, "prop"))
	for c in chests:
		sx, h, sz = dims(c["kind"], "stations")
		things.append((c["kind"], c["pos"], corners_of(c["pos"][0], c["pos"][2], sx, sz, c["yaw"]), h, "chest"))
	for p in pieces[n_before:]:
		things.append((p["id"], p["pos"], RJ.footprint(p), RJ.PIECES[p["id"]]["size"][1], "debris"))
	build = [p for p in pieces[:n_before] if p["id"] in RJ.PIECES]
	for (name, pos, cs, h, kind) in things:
		y = pos[1]
		floor_y = round(y - (0.01 if kind == "prop" else 0.0), 2)
		lift = kind == "prop" and not any(abs(floor_y - f) < 0.02 for f in FLOOR_TOPS)
		tag = f"{name} at ({pos[0]:.2f}, {y:.2f}, {pos[2]:.2f})"
		# stands on something (all four corners and the middle), unless hung on a wall
		if y > 0.05 and not lift:
			for pt in cs + [(pos[0], pos[2])]:
				if not any(abs(top_of(f) - floor_y) < 0.06 and RJ.inside(pt, RJ.footprint(f, 0.02)) for f in build
						if f["id"] in ("floor", "floor_half", "small_floor", "foundation")):
					bad.append(f"{tag}: a corner over no floor")
					break
		for p in build:
			lo, hi = p["pos"][1], top_of(p)
			if p["id"] in RJ.STAIRS:
				grow = RJ.STAIR_CLEAR if kind != "debris" else 0.5
				if p["id"] == "foundation_steps" and y > hi - 0.05:
					grow = 0.0                                # (outside steps, the thing is up on the floor behind a wall)
				if lo - 0.3 < y < hi + 0.3 and RJ.overlap(cs, RJ.footprint(p, grow)):
					bad.append(f"{tag}: on or by the stairs at {p['pos']}")
				continue
			if p["id"] == "doorway" and abs(lo - y) < 1.0 and not walled_off(pos, p, build):
				if poly_pt_dist(cs, (p["pos"][0], p["pos"][2])) < 1.5:
					bad.append(f"{tag}: in the doorway at {p['pos']}")
			if hi > y + 0.05 and lo < y + h and RJ.overlap(cs, RJ.footprint(p, 0.05 if kind != "debris" else 0.0)):
				if kind == "debris" and p["id"] in ("foundation", "floor", "floor_half"):
					continue
				bad.append(f"{tag}: inside {p['id']} at {p['pos']}")
		if kind != "debris":
			for c in chests:
				if c["pos"] is not pos and abs(c["pos"][1] - y) < 0.5 and poly_pt_dist(cs, (c["pos"][0], c["pos"][2])) < RJ.THING_CLEAR:
					bad.append(f"{tag}: too near the chest at {c['pos']}")
			for (a, b) in PATHS.get(floor_y if not lift else -1, []):
				if seg_dist((pos[0], pos[2]), a, b) < RJ.PATH_CLEAR or any(seg_dist(c, a, b) < RJ.PATH_EDGE for c in cs):
					bad.append(f"{tag}: on the walk line {a}->{b}")
	for i, (n1, p1, c1, h1, k1) in enumerate(things):
		for (n2, p2, c2, h2, k2) in things[i + 1:]:
			if p1[1] < p2[1] + h2 and p2[1] < p1[1] + h1 and poly_dist(c1, c2) < (RJ.JUNK_GAP if "debris" not in (k1, k2) else 0.05):
				bad.append(f"{n1} at {p1} and {n2} at {p2}: too close")
	return bad


problems = check_things()
for b in problems:
	print("RULE:", b)

# ---------------------------------------------------------------- write it
out = GAME / "blueprints" / "ruins" / "manor_ruin.json"
radius = round(max(math.hypot(p["pos"][0], p["pos"][2]) for p in pieces) + 1.5, 1)
json.dump({"name": "Hearth Manor", "radius": radius, "height": 13.5, "front": 8.0, "square": True, "reach": radius + 6.0,
	"pieces": pieces, "chests": chests, "beetles": beetles, "props": props},
	open(out, "w", encoding="utf-8"), separators=(",", ":"))
counts = {}
for p in pieces:
	counts[p["id"]] = counts.get(p["id"], 0) + 1
print("WROTE", out.name, len(pieces), "pieces,", len(chests), "chests,", len(props), "props, radius", radius, ";", counts)


# ---------------------------------------------------------------- the rebuilds (builder.gd's rules, as the kiln)
def same_here(p, ruin):
	return next((q for q in ruin if q["id"] == p["id"] and q["rot"] == p["rot"]
		and sum((a - b) ** 2 for a, b in zip(q["pos"], p["pos"])) < 0.05 ** 2), None)


def rebuild(plan, wood):
	ruin = [q for q in pieces if q["id"] not in DEBRIS]
	kept, new = [], []
	news = [p for p in plan if not same_here(p, ruin)]
	go = set()
	if wood:
		for i, q in enumerate(ruin):
			if q["id"] == "ruin_wall_worn" and any(1.9 < a["pos"][1] - q["pos"][1] < 2.35 and abs(a["pos"][0] - q["pos"][0]) < 0.1
					and abs(a["pos"][2] - q["pos"][2]) < 0.1 for a in news):
				go.add(i)
	used = set()
	for p in plan:
		q = same_here(p, ruin)
		if q is not None:
			used.add(id(q))
			continue
		if wood and p["id"] in ("wall", "window_wall"):
			w = next((i for i, q in enumerate(ruin) if q["id"] == "ruin_wall_worn" and i not in go and id(q) not in used
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
	views = {"ruin": pieces}
	views["brick"], new_b = rebuild(plan_of(bp), False)
	new_w = []
	if wood_bp:
		views["wood"], new_w = rebuild(plan_of(wood_bp), True)
	extra = []
	for c in chests:
		extra.append({"id": c["kind"], "mat": "prop", "pos": c["pos"], "rot": 4 + round(c["yaw"] / 30) % 12})
	for pr in props:
		extra.append({"id": pr["model"], "mat": "prop", "pos": pr["pos"], "rot": 4 + round(pr["yaw"] / 30) % 12})
	# The beetles are left off the page: their model alone is 9 MB and the page must stay under 64 MB.
	views["ruin"] = views["ruin"] + extra
	keep_props = [e for e in extra if e["id"].startswith("chest")]
	for k in ("wood", "brick"):
		if k in views:
			views[k] = views[k] + keep_props
	json.dump({"views": views}, open(page / "bp.json", "w"), separators=(",", ":"))
	json.dump({"wood": [{"id": p["id"], "mat": p["mat"]} for p in new_w], "brick": [{"id": p["id"], "mat": p["mat"]} for p in new_b]},
		open(page / "new_pieces.json", "w"), separators=(",", ":"))
	SRC = {"chest_stone": "assets/models/stations/chest_stone.glb", "chest_small": "assets/models/stations/chest_small.glb",
		"chest_copper": "assets/models/stations/chest_copper.glb"}
	for v in views.values():
		for p in v:
			key = p["id"] if p["mat"] == "prop" else f"{p['id']}__{p['mat']}"
			f = page / "m" / f"{key}.json"
			if f.exists():
				continue
			src = GAME / SRC[p["id"]] if p["id"] in SRC else GAME / f"assets/models/build/{key}.glb"
			if p["mat"] == "prop" and p["id"] not in SRC:
				src = GAME / f"assets/models/decor/{key}.glb"
			dat = src.read_bytes()
			n = struct.unpack("<I", dat[12:16])[0]
			g = json.loads(dat[20:20 + n])
			b = dat[20 + n + 8:]
			g["buffers"] = [{"byteLength": len(b), "uri": "data:application/octet-stream;base64," + base64.b64encode(b).decode()}]
			f.write_text(json.dumps(g, separators=(",", ":")))
	print("page files written:", {k: len(v) for k, v in views.items()}, "new:", len(new_w), "wood,", len(new_b), "brick")
