# The Quiet Barrows (dungeon map 6): every Stonehold stone piece, stair, ladder, trap, piece of decor, chest, ghost and
# spider, laid out on the dungeon's rooms (read from src/world/dungeon_map.gd's BARROWS, so the rock and the pieces
# always match).
#   python tools/dungeons/make_barrows.py   -> blueprints/dungeons/the_quiet_barrows.json (the game builds from it)
# Positions are the dungeon's own metres (x right, z toward the cave, y up), like DungeonMap. The plan:
# docs/design/zone1-dungeons/06-the-quiet-barrows.md + 2026-11-25-barrows-decisions.md (owner, Nov 25, F906: ghosts
# and spiders, the boss a rune ghost, each level older than the one above, 3 levels). Three levels: the newest barrows
# at 0, the old rings at OLDER = -8, the oldest at OLDEST = -16, joined by two straight stone stairs (each four 2 m
# steps). The way out: up the Air Shaft's ladder from the King's Grave to a ledge high in the Barrow Door's wall.
import json, random, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = (ROOT / "src/world/dungeon_map.gd").read_text(encoding="utf-8").split("const BARROWS")[1].split("\n}\n")[0]
D2, D3 = -8.0, -16.0  # DungeonMap.OLDER, OLDEST
SPACES = []
for m in re.findall(r'\["(\w+)",([^\]]*)\]', SRC):
	if '"' in m[1]:
		continue  # (the deadly list, not a space)
	SPACES.append([m[0]] + [float(eval(v, {"OLDER": D2, "OLDEST": D3})) for v in m[1].split(",")])
SP = {s[0]: s for s in SPACES}
MAT = "cut_stone"
MOUTH_X, MOUTH_Z = 40.0, 70.0
CAVE_Z = MOUTH_Z + 4.0  # the round door at the end of the way in (DungeonMap.FACE)
GAP = 0.5               # DungeonMap.GAP: the rock stands this far behind the wall lines
rng = random.Random(6021)

NOT_ROOMS = {"chasm"}   # spaces that are no floor cells of their own (you fall into them)
GROUP = {"spiral_a": "spiral_stair", "spiral_b": "spiral_stair", "spiral_c": "spiral_stair", "spiral_foot": "spiral_stair",
	"deep_a": "deep_stair", "deep_b": "deep_stair", "deep_c": "deep_stair", "deep_foot": "deep_stair",
	"air_hole": "air_shaft"}
NATURAL = {"spiral_stair", "deep_stair", "ash_bridge"}   # rock overhead (no stone ceiling): stairs, the bridge's cave
# The stairs: cell (x, z, level) -> (its bottom, rot). A straight stair piece climbs 2 m over its 2 m cell, from its
# front (+z at rot 0) to its back; rot 1 turns the front to +x, 2 to -z, 3 to -x.
STAIRS = {}
for z in (34, 36):   # the Spiral Stair: east from the First Ring (x 46) down to its foot (x 52-56) on level 2
	for i, x in enumerate((46, 48, 50, 52)):
		STAIRS[(x, z, 2)] = (-2.0 - 2.0 * i, 1)
for z in (28, 30):   # the Deep Stair: west from the Second Ring (x 56) down to its foot (x 46-50) on level 3
	for i, x in enumerate((54, 52, 50, 48)):
		STAIRS[(x, z, 3)] = (D2 - 2.0 - 2.0 * i, 3)
# Junctions between a stair's top and the room on the level above: open like any other doorway.
CROSS = {("spiral_stair", "first_ring"), ("deep_stair", "second_ring")}
NO_PIECES = {(40, 20, 3)}   # the Mourning Niche: bare rock behind the hidden boulder
HOLE = (30, 58)             # the Air Shaft's 2 m hole up to the exit ledge (no floor on the ledge, no ceiling below)
DARK = {"entry", "smith_door", "hunter_door", "hunter_barrow", "twins_door", "twins_vault", "shrine_door", "sunken_door",
	"sunken_barrow", "bridge_door", "spear_gate", "kings_door", "grave_gate", "spiral_stair", "deep_stair", "exit_ledge",
	"air_shaft", "alcove_w", "alcove_e", "mourning_niche"}
DOOR_SCALE = 1.5   # the round doorway at 1.5x: a hole about 2 m wide and 2.6 m high
# Older each floor (owner): level 1 nearly whole, level 2 cracked with ceilings gone, level 3 half caved in.
# level -> (worn, top row broken off, ceiling fallen)
RUIN = {1: (0.1, 0.05, 0.05), 2: (0.3, 0.15, 0.25), 3: (0.35, 0.4, 0.5)}


def level(name):
	g = GROUP.get(name, name)
	if g == "spiral_stair":
		return 2
	if g in ("deep_stair", "air_shaft"):
		return 3
	f = SP[name][5]
	return 1 if f > -5.0 else 2 if f > -13.0 else 3


LEVELS = (1, 2, 3)
LEVEL_FLOOR = {1: 0.0, 2: D2, 3: D3}


def space_of(x, z, lvl):
	for s in SPACES:
		if s[0] not in NOT_ROOMS and level(s[0]) == lvl and s[1] <= x < s[3] and s[2] <= z < s[4]:
			return s
	return None


def height(g):
	"""How high the room's stone goes (its ceiling): 3, 4, 6 or 8 m."""
	h = SP[g][6] if g in SP else 3.5
	return 8 if h >= 8 else 6 if h >= 6 else 4 if h >= 4 else 3


pieces, props, creatures, chests, lights = [], [], [], [], []


def r3(v):
	return [round(float(c), 3) for c in v]


def piece(pid, x, y, z, rot, scale=1.0):
	pieces.append({"id": pid, "mat": MAT, "pos": r3((x, y, z)), "rot": rot, **({"scale": scale} if scale != 1.0 else {})})


def prop(model, x, y, z, yaw=0.0, scale=1.0, role="decor", label="", tilt=0.0, **extra):
	props.append({"model": model, "pos": r3((x, y, z)), "yaw": round(yaw, 1), "scale": scale, "role": role, "label": label,
		**({"tilt": tilt} if tilt else {}), **extra})


CREATURE_MODEL = {"ghost_a": "creatures/ghost_a.glb", "ghost_b": "creatures/ghost_b.glb", "ghost_c": "creatures/ghost_c.glb",
	"hald_shade": "creatures/ghost_a.glb", "barrow_warden": "creatures/ghost_c.glb", "barrow_keeper": "creatures/ghost_b.glb",
	"cave_spider": "monsters/cave_spider_v0.glb"}


def creature(kind, x, z, yaw=0.0, floor=0.0, wake=None, up=0.25):
	"""`up`: how high over its floor it waits (spiders cling high in the corners)."""
	creatures.append({"kind": kind, "model": CREATURE_MODEL[kind], "pos": r3((x, floor + up, z)), "yaw": yaw, "scale": 1.0,
		"floor": floor, **({"wake": wake} if wake else {})})


def chest(kind, x, z, yaw, label, sure=False, loot="random", y=0.25):
	"""A chest (the game makes it a real chest with loot: DungeonBuild.LOOT[loot]). Not `sure`: there in about 2 of 3 worlds."""
	chests.append({"kind": kind, "pos": r3((x, y, z)), "yaw": yaw, "label": label, "always": sure, "loot": loot})


# --- 1. The cells (x, z, level): stone floors, stone ceilings (more fallen the deeper you go), the stairs. ---
cells, cell_floor = {}, {}
for s in SPACES:
	if s[0] in NOT_ROOMS:
		continue
	for x in range(int(s[1]), int(s[3]), 2):
		for z in range(int(s[2]), int(s[4]), 2):
			key = (x, z, level(s[0]))
			if key not in cells:
				cells[key] = GROUP.get(s[0], s[0])
				cell_floor[key] = s[5]
for z in range(int(MOUTH_Z), int(CAVE_Z), 2):  # the way in runs on through the rock to the round door
	for x in (MOUTH_X - 2, MOUTH_X):
		cells[(int(x), z, 1)] = "entry"
		cell_floor[(int(x), z, 1)] = 0.0


def top_at(key):
	"""A cell's floor height where you step off it (a stair's: its top)."""
	return cell_floor[key] + (2.0 if key in STAIRS else 0.0)


# The Ash Bridge: slabs only down its middle (z 26-30) over the chasm (x 22-30); the strips either side are open.
CHASM = SP["chasm"]
OPEN = {(x, z, 3) for x in range(int(CHASM[1]), int(CHASM[3]), 2) for z in (24, 30)}
SPECIAL_FLOOR = {(24, 38, 1): "floor_loose_flagstone"}  # the Smith's Barrow: a buried chest under the loose stone
holes = set()   # the cells whose ceiling fell in
for key, g in cells.items():
	if key in NO_PIECES:
		continue
	x, z, lvl = key
	cx, cz, fy = x + 1.0, z + 1.0, cell_floor[key]
	if key in STAIRS:
		bottom, rot = STAIRS[key]
		piece("stairs", cx, bottom, cz, rot)
	elif key in OPEN or (lvl == 1 and (x, z) == HOLE):
		pass   # (the chasm's open strips; the Air Shaft's mouth on the ledge)
	elif key in SPECIAL_FLOOR:
		prop("dungeon/%s.glb" % SPECIAL_FLOOR[key], cx, fy, cz, 0.0, role="secret", label="Loose stone")
	else:
		piece("floor", cx, fy, cz, 0)
	if g in NATURAL or g == "entry" or (lvl == 3 and (x, z) == HOLE):
		continue
	if rng.random() < RUIN[lvl][2] and g not in DARK:
		holes.add(key)
		continue
	piece("floor", cx, fy + float(height(g)), cz, 0)

# --- 2. Walls round every room (rock behind them) and doorways where two spaces meet. ---
DIRS = [((-2, 0), "w"), ((2, 0), "e"), ((0, -2), "n"), ((0, 2), "s")]
INWARD_YAW = {"w": 90.0, "e": 270.0, "n": 0.0, "s": 180.0}  # a wall model's front (+z) turned to face into the room
junctions = {}
rock_edges = []
for (x, z, lvl), g in cells.items():
	if (x, z, lvl) in NO_PIECES:
		continue
	for (dx, dz), side in DIRS:
		nkey = (x + dx, z + dz, lvl)
		other = cells.get(nkey)
		if other is None:   # a stair's top meets a room of another level
			for l2 in LEVELS:
				k2 = (x + dx, z + dz, l2)
				if l2 != lvl and k2 in cells and ((g, cells[k2]) in CROSS or (cells[k2], g) in CROSS):
					nkey, other = k2, cells[k2]
		if side in "we":
			line, along, rot = (x if side == "w" else x + 2), z + 1.0, 1
		else:
			line, along, rot = (z if side == "n" else z + 2), x + 1.0, 0
		if other == g:
			continue
		if other is None:
			if g == "entry" and side == "s":
				continue  # the cave
			rock_edges.append((g, side, line, along, rot, (x, z, lvl)))
		elif nkey not in NO_PIECES:
			key = (min(g, other), max(g, other), side in "we", line, min(lvl, nkey[2]))
			j = junctions.setdefault(key, {"spots": set(), "y": -99.0, "low": 99.0, "h": 3})
			j["spots"].add(along)
			j["y"] = max(j["y"], top_at((x, z, lvl)), top_at(nkey))
			j["low"] = min(j["low"], cell_floor[(x, z, lvl)], cell_floor[nkey])
			j["h"] = max(j["h"], height(g), height(other))


def wall_pos(rot, line, along):
	return (line, along) if rot == 1 else (along, line)


def wall_piece(x, y, z, rot, top_row, lvl):
	"""One 2 m stone wall piece: plain, worn, or (top row) broken off (more of them the older the level)."""
	worn, broken, _ = RUIN[lvl]
	r = rng.random()
	if top_row and r < broken:
		piece("ruin_wall_collapsed", x, y, z, rot)
	elif r < broken + worn:
		piece("ruin_wall_worn", x, y, z, rot)
	else:
		piece("wall", x, y, z, rot)


# The spear walls: both sides of the Spear Gate (x 18-22, z 32-42); the z 39 pair stabs a moment after the z 35 pair.
SPEARS = {("spear_gate", "w", 18, 35.0): 0.0, ("spear_gate", "e", 22, 35.0): 0.0,
	("spear_gate", "w", 18, 39.0): 0.25, ("spear_gate", "e", 22, 39.0): 0.25}
torch_every = {}
for g, side, line, along, rot, key in rock_edges:
	x, z = wall_pos(rot, line, along)
	yaw = INWARD_YAW[side]
	fy = cell_floor[key]
	h = height(g)
	if key in STAIRS:
		h = min(6, int(SP[space_of(key[0], key[1], key[2])[0]][6] // 2 * 2))
	rows = h // 2
	for r in range(rows):
		y = fy + 2.0 * r
		if r == 0 and (g, side, line, along) in SPEARS:
			prop("dungeon/trap_spear_wall.glb", x, y, z, yaw, role="trap", label="Rows of holes (a stake tip shows)",
				phase=SPEARS[(g, side, line, along)])
		else:
			wall_piece(x, y, z, rot, r == rows - 1 and rows >= 2, key[2])
	if h % 2:
		piece("half_wall", x, fy + 2.0 * rows, z, rot)
	# A lamp on about every eighth wall of a lit room (the dark places get none: your lantern).
	n = torch_every.get(g, 0)
	torch_every[g] = n + 1
	if g not in DARK and key not in STAIRS and (g, side, line, along) not in SPEARS and n % 8 == 2:
		ox, oz = {"w": (0.2, 0), "e": (-0.2, 0), "n": (0, 0.2), "s": (0, -0.2)}[side]
		prop("decor/furn_wall_torch_iron.glb", x + ox, fy + 1.2, z + oz, yaw, role="light")
		lights.append([round(x + ox * 3, 2), fy + 2.0, round(z + oz * 3, 2)])

# The Air Shaft: stone walls line its hole from the shaft's 4 m ceiling (-12) up to the exit ledge's floor (+6); the
# ladder climbs its west wall all the way (and 2 m on up out of the hole, to step off onto the ledge).
HX, HZ = HOLE
for wy in range(int(D3 + 4.0), 6, 2):
	piece("wall", HX, float(wy), HZ + 1.0, 1)
	piece("wall", HX + 2, float(wy), HZ + 1.0, 1)
	piece("wall", HX + 1.0, float(wy), HZ, 0)
	piece("wall", HX + 1.0, float(wy), HZ + 2, 0)
for k in range(12):
	piece("ladder", HX + 0.2, D3 + 0.24 + 2.0 * k, HZ + 1.55, 1)

# Junctions: the round doorway (1.5x) in the middle of a 4 m opening, 1 m narrow walls beside it, two high, walls over
# it up to the taller room's ceiling, and (a stair's top, the exit ledge) walls under it down to the lower floor.
# Special ones: the cracked wall to the Twins' vault, the King's round door, the locked gate to the King's Grave.
SPECIAL_J = {("twins", "twins_vault"): "cracked", ("kings_barrow", "kings_door"): "hand_door",
	("grave_gate", "kings_grave"): "locked"}
for (a, b, along_z, line, lvl), j in junctions.items():
	spots = sorted(j["spots"])
	y = j["y"]
	lo, hi = spots[0] - 1.0, spots[-1] + 1.0
	mid = (lo + hi) / 2.0
	rot = 1 if along_z else 0
	kind = SPECIAL_J.get((a, b), "")

	def p(al):
		return wall_pos(rot, line, al)
	if kind == "cracked":
		x, z = p(mid)
		prop("dungeon/wall_cracked_stone.glb", x, y, z, 90.0 if along_z else 0.0, role="secret", label="Cracked wall (hollow sound)",
			floor=y)
		for al in spots:
			x, z = p(al)
			piece("wall", x, y + 2.0, z, rot)
		for edge in [e for e in (lo + 0.5, hi - 0.5) if abs(e - mid) > 1.0]:
			x, z = p(edge)
			piece("wall_narrow", x, y, z, rot)
		continue
	if hi - lo != 4.0:
		sys.exit("junction %s/%s is %.0f m wide (doorways need 4 m)" % (a, b, hi - lo))
	x, z = p(mid)
	piece("doorway", x, y, z, rot, DOOR_SCALE)
	if kind == "hand_door":
		prop("dungeon/door_loot.glb", x, y, z, 90.0 if along_z else 0.0, DOOR_SCALE, role="door", label="Round door: E to open", opens="hand")
	if kind == "locked":   # (DungeonKeys: the Barrow Key opens it; the Barrow Keeper holds the key)
		prop("dungeon/door_loot.glb", x, y, z, 90.0 if along_z else 0.0, DOOR_SCALE, role="door", label="Barrow gate (locked: the Barrow Key)")
	for edge in (lo + 0.5, hi - 0.5):
		x, z = p(edge)
		piece("wall_narrow", x, y, z, rot)
		piece("wall_narrow", x, y + 2.0, z, rot)
	top = j["low"] + j["h"]   # the taller room's ceiling over the lower floor
	if a == "barrow_door" or b == "barrow_door":
		top = SP["barrow_door"][5] + SP["barrow_door"][6]   # (the 9 m hall: walls on up past the ledge's hole)
	if top - y > 3.0:
		x, z = p(mid)
		piece("half_wall", x, y + 3.0, z, rot)
	for wy in range(int(y + 4.0), int(top), 2):   # (a tall room: whole walls on up)
		for al in (mid - 1.0, mid + 1.0):
			x, z = p(al)
			piece("wall", x, float(wy), z, rot)
	for wy in range(int(j["low"]), int(y), 2):    # (a stair's top, the ledge: walls under the doorway down to the low floor)
		for al in (mid - 1.0, mid + 1.0):
			x, z = p(al)
			piece("wall", x, float(wy), z, rot)

# --- 3. The way in: the round stone door where the tunnel meets the cave. ---
prop("dungeon/entrance_stone.glb", MOUTH_X, 0.0, CAVE_Z, 0.0, role="door", label="The way in: round stone door")
for x in (MOUTH_X - 1.5, MOUTH_X + 1.5):
	piece("wall_narrow", x, 0.0, CAVE_Z, 0)
for x in (MOUTH_X - 1.0, MOUTH_X + 1.0):
	piece("half_wall", x, 2.0, CAVE_Z, 0)

# --- 4. The rooms, one by one. F, G, H = the three levels' floor tops. ---
F = 0.25
G = D2 + 0.25
H = D3 + 0.25

# 3 First Ring: Drifting Shades among the family niches.
for x, z, yaw in [(36.6, 33.0, 30.0), (43.4, 39.4, 220.0), (43.0, 32.4, 140.0)]:
	creature("ghost_a", x, z, yaw)

# 4 Smith's Barrow: the loose stone hides a buried chest.
chest("chest_small", 25.0, 39.0, 90.0, "Buried chest (under the loose stone)", True, "buried")

# 6 Spiral Stair: loose stones over the steps (cracks and dust): shoot them down, or run under them.
for x, z, m, fl in [(47.0, 36.6, "trap_drip_fat", -1.0), (49.0, 35.2, "trap_drip_cluster", -3.0), (51.0, 36.8, "trap_drip_thin", -5.0)]:
	prop("dungeon/%s.glb" % m, x, 4.0 + GAP + 0.1, z, rng.choice([0, 120, 240]), role="trap", tilt=180.0, floor=fl,
		warn=0.35, fall=0.45, label="Loose stones overhead (cracks and dust)" if m == "trap_drip_fat" else "")

# 7 Second Ring: Bearded Shades still keep the rings.
for x, z, yaw in [(59.0, 31.0, 300.0), (65.4, 37.6, 200.0), (66.0, 30.4, 120.0)]:
	creature("ghost_c", x, z, yaw, floor=D2)

# 8 Barrow of the Twins: two Drifting Shades by the coffins; 9 the vault behind its cracked wall.
for x, z, yaw in [(60.4, 49.6, 90.0), (63.6, 46.4, 270.0)]:
	creature("ghost_a", x, z, yaw, floor=D2)
chest("chest_small", 62.0, 55.0, 180.0, "The Twins' vault (always)", True, "vault", y=G)

# 10 Keepers' Corridor: bear jaws in the dust.
prop("dungeon/trap_bear_jaws.glb", 61.4, G - 0.01, 22.6, 40.0, role="trap", label="Bear jaws (a rusty glint in the dust)")
prop("dungeon/trap_bear_jaws.glb", 62.8, G - 0.01, 18.4, 160.0, role="trap")

# 11 Keepers' Barrow: the Barrow Warden (a big Bearded Shade) and his two keepers.
creature("barrow_warden", 62.0, 7.4, 0.0, floor=D2)
for x, z, yaw in [(58.6, 9.0, 20.0), (65.4, 9.4, 340.0)]:
	creature("ghost_c", x, z, yaw, floor=D2)

# 12 Sunken Barrow: Drifting Shades; the spiked chest in the far corner (shoot it first).
for x, z, yaw in [(46.0, 12.6, 120.0), (50.4, 6.4, 260.0)]:
	creature("ghost_a", x, z, yaw, floor=D2)
prop("dungeon/trap_chest_spikes_stone.glb", 43.4, D2, 5.6, 90.0, role="trap", label="Spike holes round the chest")
chest("chest_small", 43.0, 5.6, 90.0, "The sunken hoard (always): shoot it first", True, "buried", y=D2 + 0.24)

# 13 Shrine of Rest: the healing basin against its back wall.
prop("decor/healing_fountain.glb", 72.4, G + 0.01, 22.0, 270.0, role="heal", label="Healing basin")  # face turned to the room
lights.append([72.4, D2 + 1.6, 22.0])

# 15 Hall of Bones: spiders and Drifting Shades; a cracked plate fires a dart; the hidden boulder on its north wall
# (x 40-42) hides the Mourning Niche, a spiked chest behind it.
for x, z, yaw in [(37.0, 31.4, 60.0), (43.6, 25.0, 250.0)]:
	creature("ghost_a", x, z, yaw, floor=D3)
prop("dungeon/trap_dart_plate.glb", 39.12, H - 0.01, 28.6, 0.0, role="trap", label="Cracked floor plate", fires=True)
prop("cave/boulder_round.glb", 41.0, D3, 22.4, 30.0, scale=2.4, role="secret", label="Hidden boulder (hit it)")
prop("dungeon/trap_chest_spikes_stone.glb", 41.0, D3, 21.0, 180.0, role="trap", label="Spike holes round the chest")
chest("chest_small", 41.0, 20.6, 180.0, "The mourners' hoard (always): shoot it first", True, "buried", y=D3 + 0.24)

# 16 Ash Bridge: two swinging boulders over the slabs, the chasm 10 m down onto spikes, Wrathful Shades on the far end.
for x in (25.0, 29.0):
	prop("dungeon/trap_swing_boulder.glb", x, D3, 28.0, 90.0, role="trap", label="Swinging boulder (shoot the chain)" if x == 25.0 else "")
for x in range(int(CHASM[1]), int(CHASM[3]), 2):
	for z in range(int(CHASM[2]), int(CHASM[4]), 2):
		prop("dungeon/trap_spikes.glb", x + 1.0, CHASM[5], z + 1.0, rng.choice([0, 90, 180, 270]), role="trap",
			label="The chasm (falling in kills)" if (x, z) == (22, 24) else "")
for x, z, yaw in [(19.4, 25.4, 90.0), (20.6, 30.6, 90.0), (19.6, 28.0, 90.0)]:
	creature("ghost_b", x, z, yaw, floor=D3)

# 19 First King's Barrow: the Barrow Keeper waits at the back by the oldest graves (about 9 m from the door, so you
# walk in first), two Tomb Shades rise with him.
creature("barrow_keeper", 21.0, 53.0, 0.0, floor=D3)
creature("hald_shade", 16.6, 52.4, 0.0, floor=D3)
creature("hald_shade", 25.6, 52.8, 0.0, floor=D3)

# Cave Spiders (owner: ghosts and spiders): many, most up in the dark corners near the ceiling (they drop on you), a
# few on the floor. Not in the Keeper's fight, the chasm or the Air Shaft.
SPIDERS = [  # (x, z, floor, height over the floor)
	(37.0, 55.0, 0.0, 3.0),                                    # 1 Barrow Door (low on its tall walls)
	(36.6, 47.0, 0.0, 2.6), (43.4, 49.0, 0.0, 2.6),            # 2 Long Barrow's alcoves
	(34.6, 41.4, 0.0, 4.6), (45.4, 30.6, 0.0, 4.6),            # 3 First Ring
	(31.4, 32.6, 0.0, 4.0), (31.0, 39.4, 0.0, 0.25),           # 4 Smith's Barrow
	(24.6, 20.6, 0.0, 4.0), (31.4, 20.6, 0.0, 4.0), (28.0, 21.0, 0.0, 0.25), (25.0, 26.4, 0.0, 0.25),  # 5 Hunter's
	(56.6, 39.4, D2, 4.6), (67.4, 28.6, D2, 4.6),              # 7 Second Ring
	(58.6, 51.4, D2, 4.0),                                     # 8 Twins
	(42.6, 4.6, D2, 4.6), (53.4, 15.4, D2, 4.6), (47.0, 15.0, D2, 0.25),  # 12 Sunken Barrow
	(34.6, 22.6, D3, 5.6), (45.4, 33.4, D3, 5.6), (35.4, 26.0, D3, 0.25), (42.0, 26.0, D3, 0.25),  # 15 Hall of Bones
	(18.6, 33.0, D3, 3.4), (21.4, 41.0, D3, 3.4),              # 17 Spear Gate (clear of the spear walls)
	(37.4, 55.4, D3, 4.0),                                     # 21 King's Grave
]
for i, (x, z, fl, up) in enumerate(SPIDERS):
	creature("cave_spider", x, z, (i * 97.0) % 360.0, floor=fl, up=up)

# 21 King's Grave: the recipe stand, the big chest.
RECIPE_STAND = {"pos": [37.2, H, 52.0], "yaw": 270.0, "page": "scroll_barrows", "kind": "recipe_stand_stone"}
prop("dungeon/recipe_stand_stone.glb", 37.2, H, 52.0, 270.0, role="loot", label="Recipe stand (same recipe every time)")
prop("dungeon/recipe_scroll.glb", 37.2 - 0.007, H + 0.90, 52.0, 270.0, role="loot", tilt=20.0)
chest("chest_copper", 36.4, 49.4, 270.0, "The First King's grave chest (always)", True, "big", y=H)

# --- 4b. Decor from the catalogue (docs/art/DECOR-CATALOG.md, "The Quiet Barrows"): each piece in its room, off the
# walk lines, clear of doors, chests, traps and lamps (tools/dungeons/decor.py; tests/test_dungeon_decor.gd), each level
# checked on its own (they lie under each other).
sys.path.insert(0, str(Path(__file__).resolve().parent))
import decor  # noqa: E402
import junk  # noqa: E402

W = decor.wall


def _d(n):
	return "decor/%s.glb" % n


DECOR = [
	# 1 Barrow Door (x 36-44, z 54-62): the gravedigger's tools, the mourners' wash basin.
	("qb_digger_tool_wall", "barrow_door", W(_d("qb_digger_tool_wall"), "e", 44, 57.4)),
	("qb_wash_basin", "barrow_door", W(_d("qb_wash_basin"), "s", 62, 43.0)),
	# 2 Long Barrow: too narrow for decor (the walk lines to its alcoves); the rolling boulder comes in step 3.
	# 3 First Ring (x 34-46, z 30-42): the family niches, a bench, headstones, the bier.
	("qb_loculus_wall", "first_ring", W(_d("qb_loculus_wall"), "n", 30, 36.4)),
	("qb_loculus_wall", "first_ring", W(_d("qb_loculus_wall"), "n", 30, 39.8)),
	("qb_mourners_bench", "first_ring", W(_d("qb_mourners_bench"), "s", 42, 36.6)),
	("qb_headstone_row", "first_ring", W(_d("qb_headstone_row"), "s", 42, 44.2)),
	# 4 Smith's Barrow (x 24-32, z 32-40)
	("qb_crest_hammers", "smith_barrow", W(_d("qb_crest_hammers"), "w", 24, 33.2)),
	("sarcophagus_closed", "smith_barrow", W(_d("sarcophagus_closed"), "s", 40, 29.0)),
	# 5 Hunter's Barrow (x 24-32, z 20-28)
	("qb_urn_shelves", "hunter_barrow", W(_d("qb_urn_shelves"), "n", 20, 26.4)),
	("qb_crest_mountain", "hunter_barrow", W(_d("qb_crest_mountain"), "n", 20, 29.6)),
	# 7 Second Ring (x 56-68, z 28-40): more niches, one opened, the urn cart, a walled-up passage.
	("qb_loculus_wall", "second_ring", W(_d("qb_loculus_wall"), "e", 68, 38.4)),
	("qb_loculus_open", "second_ring", W(_d("qb_loculus_open"), "e", 68, 34.4)),
	("qb_urn_cart", "second_ring", W(_d("qb_urn_cart"), "s", 40, 66.4)),
	("qb_sealed_passage", "second_ring", W(_d("qb_sealed_passage"), "n", 28, 66.2)),
	# 8 Twins (x 58-66, z 44-52): the two coffins side by side.
	("sarcophagus_closed", "twins", W(_d("sarcophagus_closed"), "w", 58, 48.0)),
	("sarcophagus_closed", "twins", W(_d("sarcophagus_closed"), "e", 66, 48.0)),
	# 11 Keepers' Barrow (x 56-68, z 4-16): the name roll and the mason's bench, the digger's corner.
	("qb_name_roll", "keepers_barrow", W(_d("qb_name_roll"), "e", 68, 13.0)),
	("qb_mason_bench", "keepers_barrow", W(_d("qb_mason_bench"), "e", 68, 9.4)),
	("qb_digger_rest", "keepers_barrow", decor.corner(_d("qb_digger_rest"), "n", 4, "w", 56)),
	# 12 Sunken Barrow (x 42-54, z 4-16)
	("qb_loculus_collapsed", "sunken_barrow", W(_d("qb_loculus_collapsed"), "n", 4, 49.0)),
	("qb_bone_chest", "sunken_barrow", W(_d("qb_bone_chest"), "s", 16, 44.6)),
	# 13 Shrine of Rest (x 66-74, z 18-26)
	("qb_candle_ledge", "shrine", W(_d("qb_candle_ledge"), "n", 18, 70.0)),
	("qb_kneeler_stele", "shrine", W(_d("qb_kneeler_stele"), "s", 26, 70.0)),
	# 15 Hall of Bones (x 34-46, z 22-34): bone walls.
	("qb_ossuary_wall", "hall_of_bones", W(_d("qb_ossuary_wall"), "s", 34, 37.4)),
	("qb_ossuary_wall", "hall_of_bones", W(_d("qb_ossuary_wall"), "s", 34, 42.6)),
	("qb_ossuary_wall", "hall_of_bones", W(_d("qb_ossuary_wall"), "n", 22, 36.4)),
	("bone_pile", "hall_of_bones", decor.corner(_d("bone_pile"), "n", 22, "e", 46)),
	# 19 First King's Barrow (x 14-28, z 44-56): the cairn graves down the west side, the founder's bust, the vault gate.
	("qb_cairn_grave", "kings_barrow", W(_d("qb_cairn_grave"), "w", 14, 47.4)),
	("qb_cairn_grave", "kings_barrow", W(_d("qb_cairn_grave"), "w", 14, 51.4)),
	("qb_ancestor_bust", "kings_barrow", W(_d("qb_ancestor_bust"), "s", 56, 21.0)),
	("qb_vault_gate", "kings_barrow", W(_d("qb_vault_gate"), "e", 28, 54.4)),
	# 21 King's Grave (x 30-38, z 48-56)
	("sarcophagus_closed", "kings_grave", W(_d("sarcophagus_closed"), "n", 48, 33.6)),
]
_plvl = lambda p: 1 if p["pos"][1] > -4.5 else 2 if p["pos"][1] > -12.5 else 3
_flatj = {"dungeon/wall_cracked_stone.glb", "dungeon/floor_loose_flagstone.glb"}
_dxz = lambda p: (p["pos"][0], p["pos"][2])
_cells_l = {l: {(k[0], k[1]): v for k, v in cells.items() if k[2] == l and k not in NO_PIECES} for l in LEVELS}
_spaces_l = {l: [s for s in SPACES if s[0] not in NOT_ROOMS and level(s[0]) == l] for l in LEVELS}
_group = lambda n: GROUP.get(n, n)
_items = {l: [] for l in LEVELS}
for n, room, at, *up in DECOR:
	_items[level(room)].append((_d(n), at[0], at[1], at[2], room) + tuple(up))


def _doorways(l):
	dw = [_dxz(p) for p in pieces if p["id"] == "doorway" and _plvl(p) == l]
	return dw + [_dxz(p) for p in props if p["model"] in ("dungeon/entrance_stone.glb", "dungeon/wall_cracked_stone.glb") and _plvl(p) == l]


def _things(l):
	t = [_dxz(c) for c in chests if _plvl(c) == l]
	return t + ([(RECIPE_STAND["pos"][0], RECIPE_STAND["pos"][2])] if l == 3 else [])


def _traps(l):
	return [_dxz(p) for p in props if p["role"] in ("trap", "secret") and p["model"] not in _flatj and _plvl(p) == l]


def _doors(l):
	return _doorways(l) + [_dxz(p) for p in props if p["role"] == "door" and _plvl(p) == l]


_problems = []
for l in LEVELS:
	_obst = [(p["pos"][0], p["pos"][2], max(junk.size(p["model"])[:2]) / 2, 0.0, decor.height(p["model"])) for p in props
		if p["role"] in ("decor", "heal") and p["model"] not in _flatj and _plvl(p) == l]
	_obst += [(p["pos"][0], p["pos"][2], 0.4, 1.0, 2.4) for p in props if p["role"] == "light" and _plvl(p) == l]
	_obst += [(c["pos"][0], c["pos"][2], 0.5, 0.0, 1.5) for c in creatures if _plvl(c) == l]
	_pr, _ = decor.check(_items[l], _cells_l[l], junk.walk_lines(_spaces_l[l], _group, _cells_l[l], _doorways(l)),
		doors=_doors(l), things=_things(l), traps=_traps(l), obstacles=_obst)
	_problems += _pr
if _problems:
	sys.exit("decor breaks the placement rules:\n  " + "\n  ".join(_problems))
for l in LEVELS:
	props += decor.props(_items[l], lambda g: SP[g][5])

# --- 4c. Junk: the years' mess (tools/dungeons/junk.py; tests/test_dungeon_junk.gd), about 1.8 things per 10 m2
# counting the decor; more fallen stone the deeper (older) you go.
JUNK_THEMES = {
	"barrow_door": ["candles", "urn_broken", "rags", "tools", "lantern"],
	"long_barrow": ["candles", "urn_broken", "rags", "bones"],
	"first_ring": ["candles", "urns", "urn_broken", "rags", "bones", "meal"],
	"smith_barrow": ["urns", "candles", "tools", "bones", "rubble_brick"],
	"hunter_barrow": ["urns", "urn_broken", "bones", "rags", "spear_broken"],
	"second_ring": ["rubble_brick", "urn_broken", "urns", "bones", "candles", "coffin_piece", "rags"],
	"twins": ["urns", "candles", "bones", "rubble_brick"],
	"twins_vault": ["urns", "bones"],
	"keepers_corridor": ["rubble_brick", "bones", "rags", "torch_dropped"],
	"keepers_barrow": ["tools", "candles", "rubble_brick", "bones", "urn_broken", "lantern"],
	"sunken_barrow": ["rubble_brick", "coffin_piece", "bones", "urn_broken", "rags"],
	"shrine": ["candles", "urns", "rags"],
	"hall_of_bones": ["bones", "rubble_brick", "coffin_piece", "urn_broken", "coffin_lid", "statue_head"],
	"ash_bridge": ["rubble_brick", "bones"],
	"spear_gate": ["rubble_brick", "bones", "helmet", "spear_broken"],
	"kings_barrow": ["rubble_brick", "coffin_lid", "urn_broken", "bones", "candles", "statue_head", "helmet"],
	"kings_grave": ["urns", "candles", "bones", "rubble_brick"],
	"air_shaft": ["rubble_brick", "bones"],
	"exit_ledge": ["rubble_brick"],
}
_jcounts = {}
for g in JUNK_THEMES:
	_floor = [c for c, v in cells.items() if v == g]
	_lv = level(g)
	_there = sum(1 for p in props if p["role"] in ("decor", "light", "heal") and p["model"] not in _flatj
		and p["pos"][1] < SP[g][5] + 1.0 and cells.get((*junk.cell_of(p["pos"][0], p["pos"][2]), _lv)) == g)
	_there += sum(1 for c in chests if cells.get((*junk.cell_of(c["pos"][0], c["pos"][2]), _lv)) == g)
	_jcounts[g] = max(2, round(1.8 * len(_floor) * 4 / 10) - _there)
for l in LEVELS:
	_new = junk.place_junk(
		_spaces_l[l], _group, _cells_l[l], lambda g, l=l: SP[g][5] if g in SP else LEVEL_FLOOR[l], {r for r in JUNK_THEMES if level(r) == l}, JUNK_THEMES,
		doors=_doors(l), path_doors=_doorways(l), things=_things(l), traps=_traps(l),
		furniture=[(p["pos"][0], p["pos"][2], max(junk.size(p["model"])[:2]) / 2) for p in props
			if p["role"] in ("decor", "light", "heal") and p["model"] not in _flatj and _plvl(p) == l],
		seed=6013, skip={"entry"}, counts={r: n for r, n in _jcounts.items() if level(r) == l},
	)

	def _ok(j):   # (no junk on a stair, an open strip or the shaft's hole, past a room's edge, or within 0.8 m of the chasm)
		x, z = j["pos"][0], j["pos"][2]
		c = (*junk.cell_of(x, z), l)
		if c not in cells or c in STAIRS or c in OPEN or (c[0], c[1]) == HOLE:
			return False
		return not any(SP[n][1] - 0.8 < x < SP[n][3] + 0.8 and SP[n][2] - 0.8 < z < SP[n][4] + 0.8 and level(n) == l
			for n in NOT_ROOMS)
	props += [j for j in _new if _ok(j)]

# --- Write it out. ---
missing = sorted({p["model"] for p in props if not (ROOT / "assets/models" / p["model"]).exists()} |
	{c["model"] for c in creatures if not (ROOT / "assets/models" / c["model"]).exists()} |
	{"build/%s__%s.glb" % (p["id"], p["mat"]) for p in pieces if not (ROOT / ("assets/models/build/%s__%s.glb" % (p["id"], p["mat"]))).exists()})
if missing:
	sys.exit("missing models: %s" % missing)
plan = {"name": "The Quiet Barrows", "map": "barrows", "pieces": pieces, "props": props, "creatures": creatures,
	"chests": chests, "lights": lights, "recipe_stand": RECIPE_STAND}
out = ROOT / "blueprints/dungeons/the_quiet_barrows.json"
out.write_text(json.dumps(plan, indent=0, separators=(",", ":")), encoding="utf-8")
print("WROTE %s: %d pieces, %d props, %d creatures, %d chests, %d junctions, %d lights, %d ceiling holes" % (out.name,
	len(pieces), len(props), len(creatures), len(chests), len(junctions), len(lights), len(holes)))
