# Dungeon junk (owner, Nov 20): small floor models "just for looks", laid along the walls and in room corners.
# Shared by every dungeon script (make_mossgate.py, make_lampwick.py, ...): the script hands over its rooms, doors and
# things, this file finds the free spots and returns the junk as plan props (role "junk").
# Owner's placement rule (traps-and-variety.md, "Dungeon junk"; checked by tests/test_dungeon_junk.gd):
#   only along walls and in room corners; never on a path, a stair, a bridge, a doorway, or within 1.5 m in front of a
#   door, a lever, a chest or the recipe stand; never on rails or plank walks (the caller lists those as keep-off boxes).
# Owner, Nov 20: 3-5 pieces in a big room, 1-2 in a small one, an odd piece now and then in the tunnels; then
# (first look at the page): "a bit more" and "some are close to the middle": 5-8 / 2-3, a tunnel piece more often,
# every piece lies lengthwise along its wall (hugging it), and corners are tried first half the time.
import math, random, sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from glb_bounds import bounds  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
FLOOR_TOP = 0.25   # junk stands on the floor boards (their top is 0.24: 1 cm apart, no shimmer), like the furniture
WALL_FACE = 0.2    # the wall boards' face is ~0.15 m in from the wall line (old walls bulge a bit more): 0.2 is clear
DOOR_CLEAR = 2.0   # a doorway or door: 1.5 m in front of it, plus half its 3 m opening's corner
THING_CLEAR = 1.5  # a chest, the lever, the recipe stand: the owner's 1.5 m
TRAP_CLEAR = 1.2   # a trap's middle (spikes and plates are 2 m cells or smaller)
PATH_CLEAR = 1.2   # the walk line from doorway to doorway: the junk's middle stays this far away...
PATH_EDGE = 0.8    # ...and no corner of it comes closer than this
JUNK_GAP = 0.25    # between two junk pieces (or junk and furniture), edge to edge
# Owner, Nov 22 (F506, in the game: "a ton of the pieces are just on the right and left hand side of the rooms... all of
# it should be across the entire room, not just in the corners"): about half the junk now lies out in the room. Flat
# junk you walk over (no body: bones, rags, rubble, broken weapons, beams...) may lie anywhere, even on a walk line;
# solid junk (crates, kegs, carts) out in the room keeps a walking lane free: its middle 1.0 m, its corners 0.7 m away.
MIDDLE = 0.5
LANE_MID = 1.0
LANE_EDGE = 0.7


# Owner, Nov 22 (in the game: "two mugs exactly one beside each other... two head statues facing the exact same way"):
# no kind twice in a room (a family's pieces are all different models), except things that come in numbers: candles and
# pots. Small, roundish pieces turn any way; long ones lie along their wall, give or take 30 degrees; a group's parts
# (a dropped meal) each get their own turn.
MANY = {"candles", "urns", "urn_broken"}
# Pieces with a front (shelves, racks, cabinets): only against a wall, their back to it, front into the room.
FACE_IN = {"furn_bookcase", "furn_cabinet", "furn_drawers", "shack_shelf", "furn_weapon_stand", "firewood_rack",
	"furn_barrel_rack"}


def is_flat(model):
	"""No body in the game (DungeonBuild._is_flat_junk): you walk over it."""
	return model.startswith("dungeon/junk_") or model.startswith("treasure/tr_")

# Families: one entry in a room's list, a random one of its models (so the copies don't look copied).
FAMILY = {
	"rags": ["junk_rags", "junk_rags_b", "junk_rags_c", "junk_rags_d", "junk_rags_e", "junk_rags_f"],
	"rubble_wood": ["junk_rubble_wood", "junk_rubble_wood_b", "junk_rubble_wood_c", "junk_rubble_wood_d",
		"junk_rubble_wood_e", "junk_rubble_wood_f"],
	"urn_broken": ["junk_urn_broken_a", "junk_urn_broken_b", "junk_urn_broken_c", "junk_urn_broken_d", "junk_urn_broken_e"],
	"coffin_piece": ["junk_coffin_piece_a", "junk_coffin_piece_b", "junk_coffin_piece_c"],
	"tools": ["junk_pickaxe_broken", "junk_shovel_bent"],
}
# Little groups that lie together: [model, x, z, yaw] around the spot (a dropped meal: plate, mug, spoon).
CLUSTER = {
	"meal": [["treasure/tr_plate.glb", 0.0, 0.0, 0.0], ["treasure/tr_mug.glb", 0.28, 0.12, 30.0],
		["treasure/tr_spoon.glb", -0.05, 0.27, 75.0]],
	"candles": [["treasure/tr_candle_short.glb", 0.0, 0.0, 0.0], ["treasure/tr_candle_short.glb", 0.17, 0.09, 40.0]],
}
# Old props reused as junk (owner): their real paths.
REUSE = {n: "decor/%s.glb" % n for n in ("crate_stack", "grain_sacks", "keg", "furn_barrel_rack", "ore_basket",
	"mine_cart", "timber_stack",
	# (Nov 22: more old props for variety, none of them the catalogue's: buckets, iron crates, stools, vases...)
	"furn_bucket_wood", "furn_bucket_metal", "furn_crate_iron", "furn_stool", "furn_chair", "shack_stool",
	"furn_vase_tall", "furn_vase_wide", "furn_cauldron", "furn_bench_long", "furn_anvil_log", "furn_whetstone",
	"stone_stool", "shack_table", "furn_table_long", "furn_bookcase", "furn_cabinet", "furn_drawers", "shack_shelf",
	"furn_weapon_stand", "firewood_rack", "furn_dummy")}

_size = {}


def size(model):
	"""(x size, z size) of a model in metres, measured from its .glb once."""
	if model not in _size:
		lo, hi = bounds(str(ROOT / "assets/models" / model))
		_size[model] = (float(hi[0] - lo[0]), float(hi[2] - lo[2]), float(lo[0] + hi[0]) / 2, float(lo[2] + hi[2]) / 2)
	return _size[model]


def model_of(entry, rng):
	if entry in FAMILY:
		return "dungeon/%s.glb" % rng.choice(FAMILY[entry])
	if entry in REUSE:
		return REUSE[entry]
	return "dungeon/junk_%s.glb" % entry


def part_at(x, z, yaw, dx, dz):
	"""Where a group's part stands: its (dx, dz) from the group's spot, turned with the whole group (yaw only; the
	part's own extra turn only turns the part). Owner OK, Nov 22: the check and the written spot both use this
	(before, the check also swung the offset by the part's own turn, so it checked a different spot)."""
	a = math.radians(yaw)
	return (x + dx * math.cos(a) + dz * math.sin(a), z - dx * math.sin(a) + dz * math.cos(a))


def corners(model, x, z, yaw, dx=0.0, dz=0.0):
	"""The four corners of a model's footprint, placed at (x, z) turned `yaw` degrees (Godot: +yaw turns x toward -z)."""
	sx, sz, cx, cz = size(model)
	a = math.radians(yaw)
	c, s = math.cos(a), math.sin(a)
	out = []
	for px, pz in ((-sx / 2, -sz / 2), (sx / 2, -sz / 2), (sx / 2, sz / 2), (-sx / 2, sz / 2)):
		px, pz = px + cx + dx, pz + cz + dz
		out.append((x + px * c + pz * s, z - px * s + pz * c))
	return out


def seg_dist(p, a, b):
	ax, az = a
	bx, bz = b
	dx, dz = bx - ax, bz - az
	L = dx * dx + dz * dz
	t = 0.0 if L == 0 else max(0.0, min(1.0, ((p[0] - ax) * dx + (p[1] - az) * dz) / L))
	return math.hypot(p[0] - ax - t * dx, p[1] - az - t * dz)


def poly_dist(p, line):
	return min(seg_dist(p, line[i], line[i + 1]) for i in range(len(line) - 1))


def in_rect(p, r):
	return r[0] <= p[0] <= r[2] and r[1] <= p[1] <= r[3]


def cell_of(x, z):
	return (2 * math.floor(x / 2.0), 2 * math.floor(z / 2.0))


def walk_lines(spaces, group_of, cells, doors, extra=()):
	"""The walk lines through every room: from each doorway to every other doorway of the same room (through the middle
	of each box on the way), or to the room's middle if it has only one. `doors` = [(x, z)] on the wall lines."""
	by_group = {}
	for dx_, dz_ in doors:
		for ox, oz in ((1, 0), (-1, 0), (0, 1), (0, -1)):
			g = cells.get(cell_of(dx_ + ox * 0.9, dz_ + oz * 0.9))
			if g:
				by_group.setdefault(g, []).append(((dx_, dz_), (dx_ + ox * 0.9, dz_ + oz * 0.9)))

	def box_at(g, p):
		best = None
		for s in spaces:
			if group_of(s[0]) == g and s[1] <= p[0] <= s[3] and s[2] <= p[1] <= s[4]:
				if best is None or s[5] > best[5]:
					best = s
		return best

	def mid(s):
		return ((s[1] + s[3]) / 2.0, (s[2] + s[4]) / 2.0)

	lines = {}
	for g, ds in by_group.items():
		out = lines.setdefault(g, [])
		if len(ds) == 1:
			b = box_at(g, ds[0][1])
			out.append([ds[0][0], mid(b)] if b else [ds[0][0], ds[0][1]])
		for i in range(len(ds)):
			for j in range(i + 1, len(ds)):
				(a, ai), (b, bi) = ds[i], ds[j]
				ba, bb = box_at(g, ai), box_at(g, bi)
				out.append([a, b] if ba is bb or not ba or not bb else [a, mid(ba), mid(bb), b])
	for g, line in extra:
		lines.setdefault(g, []).append(line)
	return lines


def place_junk(spaces, group_of, cells, floor_y, rooms, themes, doors, path_doors, things, traps, furniture,
		seed, keep_off=(), extra_paths=(), skip=(), corridor=("bones", "rags", "axe_head", "sword_snapped", "tools"),
		long_corridor=16.0, big=(5, 8), small=(2, 3), repeat=2, tunnel_every=0.0, counts=None):
	"""Junk props for one dungeon.
	spaces: the map's [name, x0, z0, x1, z1, floor_y, height] boxes; group_of(name) -> its room.
	cells: {(x, z) 2 m cell corner: room}; floor_y(room) -> its floor height.
	rooms: the rooms (3-5 pieces, 1-2 if small); everything else is a corridor (now and then one piece).
	themes: {room: [entries]} (an entry = a junk model name, a FAMILY, a REUSE prop or a CLUSTER); corridors use `corridor`.
	doors / path_doors: (x, z) of every doorway and door (kept DOOR_CLEAR away) / those the walk lines run between.
	things: (x, z) of chests, levers and recipe stands (THING_CLEAR); traps: (x, z) (TRAP_CLEAR);
	furniture: (x, z, radius) of other things on the floor; keep_off: [x0, z0, x1, z1] boxes with no junk at all
	(pits, chasms, rails, plank walks); extra_paths: [(room, [(x, z), ...])] walk lines the doors don't give (a bridge).
	skip: rooms with no junk.
	big / small: how many in a big (80 m2 or more) / small room; repeat: each kind of junk at most this often per room;
	tunnel_every: one more tunnel piece per this many metres of tunnel (0: none); counts: {room: how many}, instead of big/small."""
	rng = random.Random(seed)
	lines = walk_lines(spaces, group_of, cells, path_doors, extra_paths)
	used = {}   # room -> models (and groups) already lying there

	def parts_of(entry, g):
		"""The models to lay for this entry in room g (its own turn and a little shuffle for a group's parts), or None
		if every model it could be already lies in the room."""
		u = used.setdefault(g, set())
		if entry in CLUSTER:
			if entry not in MANY and entry in u:
				return None
			return [[m, dx + rng.uniform(-0.04, 0.04), dz + rng.uniform(-0.04, 0.04), dyaw + rng.uniform(-60, 60)]
				for m, dx, dz, dyaw in CLUSTER[entry]]
		if entry in FAMILY:
			free_models = ["dungeon/%s.glb" % m for m in FAMILY[entry] if entry in MANY or "dungeon/%s.glb" % m not in u]
			return [[rng.choice(free_models), 0.0, 0.0, 0.0]] if free_models else None
		m = model_of(entry, rng)
		return None if (m in u and entry not in MANY) else [[m, 0.0, 0.0, 0.0]]

	def mark(entry, g, models):
		used.setdefault(g, set()).update(models + [entry])
	placed = []      # (x, z, radius) of junk so far
	props = []

	def free(model, x, z, yaw, g, dx=0.0, dz=0.0, out_in_room=False):
		cs = corners(model, x, z, yaw, dx, dz)
		px, pz = sum(c[0] for c in cs) / 4, sum(c[1] for c in cs) / 4
		rad = max(math.hypot(c[0] - px, c[1] - pz) for c in cs)
		for c in cs + [(px, pz)]:
			if cells.get(cell_of(c[0], c[1])) != g:
				return None  # a corner over another room, a doorway gap or rock
			if any(in_rect(c, r) for r in keep_off):
				return None
		if not out_in_room:
			for line in lines.get(g, []):
				if poly_dist((px, pz), line) < PATH_CLEAR or any(poly_dist(c, line) < PATH_EDGE for c in cs):
					return None
		elif not is_flat(model):
			for line in lines.get(g, []):
				if poly_dist((px, pz), line) < LANE_MID or any(poly_dist(c, line) < LANE_EDGE for c in cs):
					return None
		for (ox, oz) in doors:
			if math.hypot(px - ox, pz - oz) < DOOR_CLEAR + rad:
				return None
		for (ox, oz) in things:
			if math.hypot(px - ox, pz - oz) < THING_CLEAR + rad:
				return None
		for (ox, oz) in traps:
			if math.hypot(px - ox, pz - oz) < TRAP_CLEAR + rad:
				return None
		for (ox, oz, r) in list(furniture) + placed:
			if math.hypot(px - ox, pz - oz) < r + rad + JUNK_GAP:
				return None
		return (px, pz, rad)

	# Every wall spot and corner spot of every room: (room, cell centre, [wall normals pointing into the room]).
	spots = {}
	for (x, z), g in cells.items():
		if g in skip:
			continue
		walls = []
		for (ox, oz) in ((-1, 0), (1, 0), (0, -1), (0, 1)):
			if cells.get((x + 2 * ox, z + 2 * oz)) is None:   # rock (a doorway's neighbour is another room: no wall)
				walls.append((ox, oz))
		if not walls:
			continue
		spots.setdefault(g, [])
		for w in walls:
			spots[g].append(((x + 1.0, z + 1.0), [w]))
		for i in range(len(walls)):
			for j in range(i + 1, len(walls)):
				a, b = walls[i], walls[j]
				if a[0] * b[0] + a[1] * b[1] == 0:   # two walls at a right angle: a corner
					spots[g].append(((x + 1.0, z + 1.0), [a, b]))

	def try_middle(entry, g):
		"""Out in the room: any of its cells, anywhere in it, turned any way."""
		cands = [c for c, cg in cells.items() if cg == g]
		rng.shuffle(cands)
		for (cx, cz) in cands[:40]:
			x, z = cx + 1.0 + rng.uniform(-0.7, 0.7), cz + 1.0 + rng.uniform(-0.7, 0.7)
			yaw = rng.uniform(0.0, 360.0)
			parts = parts_of(entry, g)
			if parts is None:
				return False
			got = []
			for model, ddx, ddz, dyaw in parts:
				f = free(model, *part_at(x, z, yaw, ddx, ddz), yaw + dyaw, g, out_in_room=True)
				if f is None:
					got = None
					break
				got.append((model, f, dyaw, ddx, ddz))
			if not got:
				continue
			for model, f, dyaw, ddx, ddz in got:
				px, pz = part_at(x, z, yaw, ddx, ddz)
				placed.append(f)
				props.append({"model": model, "pos": [round(px, 3), round(floor_y(g) + FLOOR_TOP, 3), round(pz, 3)],
					"yaw": round((yaw + dyaw) % 360.0, 1), "scale": 1.0, "role": "junk", "label": "", "spot": "room"})
			mark(entry, g, [m for m, *_ in got])
			return True
		return False

	def try_entry(entry, g):
		if g in rooms and entry not in FACE_IN and rng.random() < MIDDLE and try_middle(entry, g):
			return True
		cands = spots.get(g, [])[:]
		rng.shuffle(cands)
		if rng.random() < 0.5:   # corners first, half the time
			cands.sort(key=lambda c: -len(c[1]))
		for (cx, cz), walls in cands:
			parts = parts_of(entry, g)
			if parts is None:
				return False
			lead = parts[0][0]
			sx, sz = size(lead)[:2]
			(wx, wz) = walls[0]
			wall_yaw = 90.0 if wx != 0 else 0.0   # the model's long side (x) along the wall
			if entry in FACE_IN:   # back to the wall, front into the room
				yaw = math.degrees(math.atan2(-wx, -wz)) + rng.uniform(-4, 4)
			elif max(sx, sz) < 1.5 * min(sx, sz):   # small and roundish: any way (owner, Nov 22)
				yaw = rng.uniform(0.0, 360.0)
			else:   # long: along its wall, give or take 30 degrees, either end first
				yaw = wall_yaw + rng.uniform(-30, 30) + rng.choice([0, 180])
			# Push it toward its wall(s) until its footprint touches WALL_FACE.
			x, z = cx, cz
			for _ in range(2):
				cs = [c for part in parts for c in corners(part[0], *part_at(x, z, yaw, part[1], part[2]), yaw + part[3])]
				for (ox, oz) in walls:
					if ox:
						line = cx + ox * 1.0
						reach = max(c[0] for c in cs) if ox > 0 else min(c[0] for c in cs)
						x += (line - ox * WALL_FACE) - reach
					else:
						line = cz + oz * 1.0
						reach = max(c[1] for c in cs) if oz > 0 else min(c[1] for c in cs)
						z += (line - oz * WALL_FACE) - reach
			if len(walls) == 1:   # slide along the wall a little (not all on the cell middles)
				slide = rng.uniform(-0.4, 0.4)
				x, z = (x, z + slide) if walls[0][0] else (x + slide, z)
			cs = corners(lead, x, z, yaw + parts[0][3], parts[0][1], parts[0][2])
			mx, mz = sum(c[0] for c in cs) / 4, sum(c[1] for c in cs) / 4
			if min(abs(cx + ox - mx) if ox else abs(cz + oz - mz) for (ox, oz) in walls) > 0.95:
				continue  # a wide piece whose middle ends up too far out (owner: none near the middle)
			got = []
			for model, ddx, ddz, dyaw in parts:
				f = free(model, *part_at(x, z, yaw, ddx, ddz), yaw + dyaw, g)
				if f is None:
					got = None
					break
				got.append((model, f, dyaw, ddx, ddz))
			if not got:
				continue
			for model, f, dyaw, ddx, ddz in got:
				px, pz = part_at(x, z, yaw, ddx, ddz)
				placed.append(f)
				props.append({"model": model, "pos": [round(px, 3), round(floor_y(g) + FLOOR_TOP, 3), round(pz, 3)],
					"yaw": round((yaw + dyaw) % 360.0, 1), "scale": 1.0, "role": "junk", "label": ""})
			mark(entry, g, [m for m, *_ in got])
			return True
		return False

	for g in sorted(spots):
		boxes = [s for s in spaces if group_of(s[0]) == g and s[5] == floor_y(g)]
		area = sum((s[3] - s[1]) * (s[4] - s[2]) for s in boxes)
		length = max([max(s[3] - s[1], s[4] - s[2]) for s in boxes] or [0])
		if counts and g in counts:   # (owner, Nov 22: "see their size versus how many things are in there")
			want = counts[g]
		elif g in rooms:
			want = rng.randint(*big) if area >= 80 else rng.randint(*small)
		else:
			want = (1 if rng.random() < 0.7 else 0) + (1 if length >= long_corridor else 0)
			if tunnel_every > 0:
				want += int(length / tunnel_every)
		pool = list(themes.get(g, corridor))
		rng.shuffle(pool)
		full = pool[:]
		for _ in range(repeat - 1):
			more = pool[:]
			rng.shuffle(more)
			full = more + full   # each kind at most `repeat` times (the families pick another model each time)
		pool = full
		n = 0
		while pool and n < want:
			if try_entry(pool.pop(), g):
				n += 1
	return props
