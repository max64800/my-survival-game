# The Vigil of Orrin Stonejaw (dungeon map 9): every brick piece, stair, trap, chest and skeleton, laid out on the
# dungeon's rooms (read from src/world/dungeon_map.gd's ORRIN, so the rock and the pieces always match).
#   python tools/dungeons/make_orrin.py   -> blueprints/dungeons/vigil_of_orrin_stonejaw.json (the game builds from it)
# Positions are the dungeon's own metres (x right, z toward the cave, y up), like DungeonMap. The plan:
# docs/design/zone1-dungeons/09-vigil-of-orrin-stonejaw.md + 2026-11-28-orrin-decisions.md (owner, Nov 28, F980: very old
# Hearthbrick, a little Stonehold stone here and there; skeletons + Rune Callers; the Bell-Ringer boss). Three levels going
# UP: the halls at 0, the rune halls at RUNE = +8, the bell tower at BELL = +16, joined by three straight stairs (each four
# 2 m steps): the First Stair (up west), the Tower Stair (up south) and the Pilgrims' Slide (down east, the way out).
# Step 1 of the decisions file: rooms, stairs, way out, monsters, the old traps. (New traps and the temple look: later.)
import json, random, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = (ROOT / "src/world/dungeon_map.gd").read_text(encoding="utf-8").split("const ORRIN")[1].split("\n}\n")[0]
R, B = 8.0, 16.0  # DungeonMap.RUNE, DungeonMap.BELL
SPACES = []
for m in re.findall(r'\["(\w+)",([^\]]*)\]', SRC):
	if '"' in m[1]:
		continue  # (a list of names, not a space)
	SPACES.append([m[0]] + [float(eval(v, {"RUNE": R, "BELL": B})) for v in m[1].split(",")])
SP = {s[0]: s for s in SPACES}
MOUTH_X, MOUTH_Z = 46.0, 70.0
CAVE_Z = MOUTH_Z + 4.0  # the round door at the end of the way in (DungeonMap.FACE)
GAP = 0.5               # DungeonMap.GAP: the rock stands this far behind the wall lines
rng = random.Random(9021)

NOT_ROOMS = {"chasm", "echo_pit"}   # spaces that are no floor cells of their own (you fall into them)
GROUP = {}
for n in ("first_foot", "first_a", "first_b", "first_c", "first_d"):
	GROUP[n] = "first_stair"
for n in ("tower_foot", "tower_a", "tower_b", "tower_c", "tower_d"):
	GROUP[n] = "tower_stair"
for n in ("slide_a", "slide_b", "slide_c", "slide_d", "slide_foot"):
	GROUP[n] = "slide"
NATURAL = {"first_stair", "tower_stair", "slide"}   # rock overhead (no brick ceiling): the stairs
# The stairs: cell (x, z, level) -> (its bottom, rot). A straight stair piece climbs 2 m over its 2 m cell, from its
# front (+z at rot 0) to its back; rot 1 turns the front to +x, 2 to -z, 3 to -x.
STAIRS = {}
for z in (40, 42):   # the First Stair: up west from its foot (x 36) to the Rune Gallery (x 28)
	for i, x in enumerate((34, 32, 30, 28)):
		STAIRS[(x, z, 1)] = (2.0 * i, 1)
for x in (4, 6):     # the Tower Stair: up south from its foot (z 34) to the Bell Walk (z 42)
	for i, z in enumerate((34, 36, 38, 40)):
		STAIRS[(x, z, 2)] = (R + 2.0 * i, 2)
for z in (60, 62):   # the Pilgrims' Slide: down east from Orrin's Rest (x 56) to its foot (x 64), 8 m up over the halls
	for i, x in enumerate((56, 58, 60, 62)):
		STAIRS[(x, z, 1)] = (B - 2.0 - 2.0 * i, 1)
# Junctions between rooms of different levels (the stairs' tops): open like any other doorway.
CROSS = {("first_stair", "rune_gallery"), ("tower_stair", "bell_walk"), ("slide", "orrins_rest")}
NO_PIECES = {(2, 64, 3)}   # the Bellringer's Loft: bare rock behind the hidden boulder
DARK = {"entry", "pillar_door", "robing_door", "carvers_door", "carvers_vault", "echo_door", "sanctum_door", "shrine_door",
	"rune_way", "bridge_way", "loft_niche", "bell_alcove", "vigil_door", "rune_lock", "exit_ledge", "first_stair",
	"tower_stair", "slide"}
DOOR_SCALE = 1.5   # the round doorway at 1.5x: a hole about 2 m wide and 2.6 m high
# Very old brick (owner): worn bricks all through, many walls with their top row fallen, ceilings down here and there.
# Only the tower top (Orrin's Vigil, the Rune Door, Orrin's Rest) is newer, whole brick, kept repaired.
FRESH = {"orrins_vigil", "rune_lock", "orrins_rest"}
WORN = 0.4        # a wall piece worn and chipped
COLLAPSED = 0.22  # the top row of a wall broken off
NO_CEILING = 0.1  # a ceiling piece fallen
STONE = 0.05      # a plain wall piece that is old Stonehold stone ("a mix of stone here and there, but not too much")
STONE_STAIRS = {"first_stair", "slide"}   # worn stone treads
STONE_DOORS = {("entry", "pilgrims_door"), ("hall_of_pillars", "pillar_door"), ("acolytes_sanctum", "sanctum_door")}


def level(name):
	g = GROUP.get(name, name)
	if g in ("first_stair", "slide") or name == "exit_ledge":
		return 1   # (the way out hangs 8 m up over the halls, beside the Pilgrims' Door)
	if g == "tower_stair" or name == "echo_pit":
		return 2
	if name == "chasm":
		return 3   # (it hangs under the level-3 bridge)
	f = SP[name][5]
	return 1 if f < 4.0 else 2 if f < 12.0 else 3


def space_of(x, z, lvl):
	for s in SPACES:
		if s[0] not in NOT_ROOMS and level(s[0]) == lvl and s[1] <= x < s[3] and s[2] <= z < s[4]:
			return s
	return None


def height(g):
	"""How high the room's brick goes (its ceiling): 3 m, or its height down to whole 2 m (4, 6, 8, 12 m)."""
	h = SP[g][6] if g in SP else 3.5
	return 3 if h < 4 else int(h) // 2 * 2


pieces, props, creatures, chests, lights = [], [], [], [], []


def r3(v):
	return [round(float(c), 3) for c in v]


def piece(pid, x, y, z, rot, scale=1.0, mat="clay_brick"):
	pieces.append({"id": pid, "mat": mat, "pos": r3((x, y, z)), "rot": rot, **({"scale": scale} if scale != 1.0 else {})})


def prop(model, x, y, z, yaw=0.0, scale=1.0, role="decor", label="", tilt=0.0, **extra):
	props.append({"model": model, "pos": r3((x, y, z)), "yaw": round(yaw, 1), "scale": scale, "role": role, "label": label,
		**({"tilt": tilt} if tilt else {}), **extra})


# (The Rune Callers, the Rune Elder and the Bell-Ringer wear the miners' bodies for now: their looks are step 2.)
CREATURE_MODEL = {"lost_miner": "creatures/lost_miner_frost.glb", "tunnel_rat": "creatures/tunnel_rat_soot.glb",
	"rune_caller": "creatures/lost_miner_ghost.glb", "rune_elder": "creatures/prop_warden.glb",
	"bell_ringer": "creatures/foreman.glb"}


def creature(kind, x, z, yaw=0.0, floor=0.0, wake=None, up=0.25):
	creatures.append({"kind": kind, "model": CREATURE_MODEL[kind], "pos": r3((x, floor + up, z)), "yaw": yaw, "scale": 1.0,
		"floor": floor, **({"wake": wake} if wake else {})})


def chest(kind, x, z, yaw, label, sure=False, loot="random", y=0.25):
	"""A chest (the game makes it a real chest with loot: DungeonBuild.LOOT[loot]). Not `sure`: there in about 2 of 3 worlds."""
	chests.append({"kind": kind, "pos": r3((x, y, z)), "yaw": yaw, "label": label, "always": sure, "loot": loot})


# --- 1. The cells (x, z, level): brick floors, brick ceilings (some fallen), the stairs. ---
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


# The Robing Room's loose stone hides a buried chest.
SPECIAL_FLOOR = {(60, 46, 1): "floor_loose_flagstone"}
# The Broken Bridge: slabs only down its middle (x 6-10) over the chasm (z 54-64); the strips either side are open.
CHASM = SP["chasm"]
OPEN = {(x, z, 3) for z in range(int(CHASM[2]), int(CHASM[4]), 2) for x in (4, 10)}
# Loose slabs that give way under you (instant death): two staggered ones on the bridge (a careful dwarf crosses on the
# sound ones), and the middle of the Hall of Echoes over its spikes (keep to the solid edge along the walls). The tell:
# the slab sits loose and odd among the others. (Step 3 turns the Hall of Echoes' into crumbling brick.)
TRAP_RNG = random.Random(912)
PIT = SP["echo_pit"]
FAKE_FLOOR = {(6, 56, 3), (8, 60, 3)} | {(x, z, 2) for x in range(int(PIT[1]), int(PIT[3]), 2)
	for z in range(int(PIT[2]), int(PIT[4]), 2)}
holes = set()   # the cells whose ceiling fell in
for key, g in cells.items():
	if key in NO_PIECES:
		continue
	x, z, lvl = key
	cx, cz, fy = x + 1.0, z + 1.0, cell_floor[key]
	if key in STAIRS:
		bottom, rot = STAIRS[key]
		piece("stairs", cx, bottom, cz, rot, mat="cut_stone" if g in STONE_STAIRS else "clay_brick")
	elif key in OPEN:
		pass   # (the chasm's open strips)
	elif key in FAKE_FLOOR:
		prop("dungeon/floor_loose_flagstone.glb", cx, fy, cz, TRAP_RNG.choice([0, 90, 180, 270]), role="trap",
			label="Fake floor (it gives way: spikes below)")
	elif key in SPECIAL_FLOOR:
		prop("dungeon/%s.glb" % SPECIAL_FLOOR[key], cx, fy, cz, 0.0, role="secret", label="Loose stone")
	else:
		piece("floor", cx, fy, cz, 0)
	if g in NATURAL or g == "entry":
		continue
	if g not in FRESH and g not in DARK and rng.random() < NO_CEILING:
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
			for l2 in (1, 2, 3):
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
			j = junctions.setdefault(key, {"spots": set(), "y": -99.0, "low": 99.0, "top": 0.0})
			j["spots"].add(along)
			j["y"] = max(j["y"], top_at((x, z, lvl)), top_at(nkey))
			j["low"] = min(j["low"], cell_floor[(x, z, lvl)], cell_floor[nkey])
			j["top"] = max(j["top"], cell_floor[(x, z, lvl)] + height(g), cell_floor[nkey] + height(other))


def wall_pos(rot, line, along):
	return (line, along) if rot == 1 else (along, line)


def wall_piece(x, y, z, rot, top_row, g):
	"""One 2 m wall piece: old brick (worn, or its top row broken off), now and then old stone; whole in the tower top."""
	if g in FRESH:
		piece("wall", x, y, z, rot)
		return
	r = rng.random()
	if top_row and r < COLLAPSED:
		piece("ruin_wall_collapsed", x, y, z, rot)
	elif r < COLLAPSED + WORN:
		piece("ruin_wall_worn", x, y, z, rot)
	elif r > 1.0 - STONE:
		piece("wall", x, y, z, rot, mat="cut_stone")
	else:
		piece("wall", x, y, z, rot)


# The dart walls: the Hall of Pillars' west wall at z 46-48 (a tripwire runs east across the hall from its hole), the
# Rune Gallery's west wall at z 44-46 (a cracked plate 2.5 m out in front of it). The spear walls: one on each side of
# the Bell Run's west end, out of step (go when they pull back).
DART = {("hall_of_pillars", "w", 40, 47.0), ("rune_gallery", "w", 16, 45.0)}
SPEARS = {("bell_run", "n", 64, 15.0): 0.0, ("bell_run", "s", 68, 13.0): 1.0}
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
		if r == 0 and (g, side, line, along) in DART:
			prop("dungeon/trap_tripwire_wall_stone.glb", x, y, z, yaw, role="trap", label="Dart hole (green stain under it)")
		elif r == 0 and (g, side, line, along) in SPEARS:
			prop("dungeon/trap_spear_wall.glb", x, y, z, yaw, role="trap", label="Rows of holes (a rusty tip shows)",
				phase=SPEARS[(g, side, line, along)])
		else:
			wall_piece(x, y, z, rot, r == rows - 1 and rows >= 2, g)
	if h % 2:
		piece("half_wall", x, fy + 2.0 * rows, z, rot)
	# A lamp on about every eighth wall of a lit room (the dark places get none: your lantern).
	n = torch_every.get(g, 0)
	torch_every[g] = n + 1
	if g not in DARK and key not in STAIRS and (g, side, line, along) not in DART and (g, side, line, along) not in SPEARS \
			and n % 8 == 2:
		ox, oz = {"w": (0.2, 0), "e": (-0.2, 0), "n": (0, 0.2), "s": (0, -0.2)}[side]
		prop("decor/furn_wall_torch_iron.glb", x + ox, fy + 1.2, z + oz, yaw, role="light")
		lights.append([round(x + ox * 3, 2), fy + 2.0, round(z + oz * 3, 2)])

# Junctions: the round doorway (1.5x) in the middle of a 4 m opening, 1 m narrow walls beside it, two high, walls over
# it up to the taller room's ceiling, and (a stair's top, the exit ledge) walls under it down to the lower floor. Special
# ones: the cracked wall to the Carvers' Vault, the boss room's round door, the locked Rune Door.
SPECIAL_J = {("carvers_vault", "carvers_workshop"): "cracked", ("orrins_vigil", "vigil_door"): "hand_door",
	("orrins_vigil", "rune_lock"): "locked"}
for (a, b, along_z, line, lvl), j in junctions.items():
	spots = sorted(j["spots"])
	y = j["y"]
	lo, hi = spots[0] - 1.0, spots[-1] + 1.0
	mid = (lo + hi) / 2.0
	rot = 1 if along_z else 0
	kind = SPECIAL_J.get((a, b), "")
	mat = "cut_stone" if (a, b) in STONE_DOORS else "clay_brick"

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
	piece("doorway", x, y, z, rot, DOOR_SCALE, mat=mat)
	if kind == "hand_door":
		prop("dungeon/door_loot.glb", x, y, z, 90.0 if along_z else 0.0, DOOR_SCALE, role="door", label="Round door: E to open", opens="hand")
	if kind == "locked":   # (DungeonKeys: the Rune Key opens it; the Bell-Ringer holds the key)
		prop("dungeon/door_loot.glb", x, y, z, 90.0 if along_z else 0.0, DOOR_SCALE, role="door", label="Rune Door (locked: the Rune Key)")
	for edge in (lo + 0.5, hi - 0.5):
		x, z = p(edge)
		piece("wall_narrow", x, y, z, rot, mat=mat)
		piece("wall_narrow", x, y + 2.0, z, rot, mat=mat)
	top = j["top"]   # the taller room's ceiling
	if top - y > 3.0:
		x, z = p(mid)
		piece("half_wall", x, y + 3.0, z, rot)
	for wy in range(int(y + 4.0), int(top), 2):   # (a tall room: whole walls on up)
		for al in (mid - 1.0, mid + 1.0):
			x, z = p(al)
			piece("wall", x, float(wy), z, rot)
	for wy in range(int(j["low"]), int(y), 2):    # (a stair's top, the exit ledge: walls under the doorway down to the low floor)
		for al in (mid - 1.0, mid + 1.0):
			x, z = p(al)
			piece("wall", x, float(wy), z, rot)

# --- 3. The way in: the round stone door where the tunnel meets the cave (old stone round the door, F859). ---
prop("dungeon/entrance_stone.glb", MOUTH_X, 0.0, CAVE_Z, 0.0, role="door", label="The way in: round stone door")
for x in (MOUTH_X - 1.5, MOUTH_X + 1.5):
	piece("wall_narrow", x, 0.0, CAVE_Z, 0, mat="cut_stone")
for x in (MOUTH_X - 1.0, MOUTH_X + 1.0):
	piece("half_wall", x, 2.0, CAVE_Z, 0, mat="cut_stone")


# --- 4. The rooms, one by one. F / G / H = the floor tops of the halls, the rune halls, the bell tower. ---
F = 0.25
G = R + 0.25
H = B + 0.25
COLUMNS = []   # (x, z): the pillars (stacked column pieces), kept clear by the decor and the junk


def column(x, z, fy, h, fresh=False):
	"""A pillar from floor to ceiling: old ancient-brick base, shafts and top, or (the tower top) newer brick columns."""
	COLUMNS.append((x, z, cell_floor_level(fy)))
	if fresh:
		for k in range(int(h // 2)):
			piece("column", x, fy + 2.0 * k, z, 0)
		return
	piece("column_base", x, fy, z, 0, mat="ancient_brick")
	for k in range(int(h - 1)):
		piece("column_shaft", x, fy + 0.5 + k, z, 0, mat="ancient_brick")
	piece("column_capital", x, fy + h - 0.5, z, 0, mat="ancient_brick")


def cell_floor_level(fy):
	return 1 if fy < 4.0 else 2 if fy < 12.0 else 3


# 1 Pilgrims' Door: the heap of old rags under the exit ledge's hole (high in the east wall): jump down onto it.
for x, z, yaw in [(50.6, 55.4, 30.0), (51.0, 57.0, 200.0), (50.2, 56.6, 110.0)]:
	prop("dungeon/junk_rags%s.glb" % rng.choice(["", "_b", "_c"]), x, F, z, yaw, label="Old rags (a soft heap)" if yaw == 30.0 else "")

# 2 Hall of Pillars: four old pillars; Bone Rots among them; a thin wire across the hall from the dart hole (west wall).
for x, z in [(44.0, 42.0), (48.0, 42.0), (44.0, 46.0), (48.0, 46.0)]:
	column(x, z, 0.0, 6.0)
for x, z, yaw in [(46.0, 40.0, 30.0), (50.4, 48.0, 220.0), (42.0, 49.0, 140.0)]:
	creature("tunnel_rat", x, z, yaw)
prop("dungeon/tripwire_iron.glb", 42.0, F - 0.01, 46.88, 0.0, role="trap", label="Tripwire (step over it, or cut it)",
	stretch=round(4.0 - 0.3, 2))

# 3 Robing Room: the loose stone hides a buried chest.
chest("chest_small", 61.0, 47.0, 270.0, "Buried chest (under the loose stone)", True, "buried")

# 4 First Stair: loose bricks over the steps (cracks and dust): shoot them down, or run under them.
for x, z, m, fl in [(35.0, 41.4, "trap_drip_fat", 1.0), (33.0, 42.8, "trap_drip_cluster", 3.0), (31.0, 41.2, "trap_drip_thin", 5.0)]:
	top = SP[space_of(int(x) // 2 * 2, int(z) // 2 * 2, 1)[0]]
	prop("dungeon/%s.glb" % m, x, top[5] + top[6] + GAP + 0.1, z, rng.choice([0, 120, 240]), role="trap", tilt=180.0, floor=fl,
		warn=0.35, fall=0.45, label="Loose bricks overhead (cracks and dust)" if m == "trap_drip_fat" else "")

# Rune halls (level 2). 5 Rune Gallery: Rune Callers and a Bone Rot; a cracked plate 2.5 m out from the west wall's dart hole.
for x, z, yaw in [(22.0, 38.4, 30.0), (19.0, 46.6, 120.0)]:
	creature("rune_caller", x, z, yaw, floor=R)
creature("tunnel_rat", 25.4, 46.0, 250.0, floor=R)
prop("dungeon/trap_dart_plate.glb", 18.5, G - 0.01, 44.88, 0.0, role="trap", label="Cracked floor plate", fires=True)

# 6 Carvers' Workshop: a Hollow Miner still carving, a chest; 7 the carvers' vault behind the cracked east wall.
creature("lost_miner", 31.0, 27.0, 200.0, floor=R)
chest("chest_small", 34.6, 31.0, 270.0, "Carver's chest", y=G)
chest("chest_small", 39.0, 26.0, 270.0, "The carvers' vault (always)", True, "vault", y=G)

# 8 Acolytes' Cells: Bone Rots in the corridor.
for x, z, yaw in [(21.0, 33.0, 160.0), (23.0, 27.0, 340.0)]:
	creature("tunnel_rat", x, z, yaw, floor=R)

# 9 Hall of Echoes: the loose slabs in its middle (above), the spikes 4 m under them; a Rune Caller on the far edge.
for x in range(int(PIT[1]), int(PIT[3]), 2):
	for z in range(int(PIT[2]), int(PIT[4]), 2):
		prop("dungeon/trap_spikes.glb", x + 1.0, PIT[5], z + 1.0, rng.choice([0, 90, 180, 270]), role="trap",
			label="The pit: spikes at the bottom (falling in kills)" if (x, z) == (16, 12) else "")
creature("rune_caller", 15.0, 11.0, 60.0, floor=R)

# 10 Acolyte's Sanctum: the Rune Elder and two Rune Callers.
creature("rune_elder", 6.4, 16.0, 90.0, floor=R)
for x, z, yaw in [(8.0, 13.4, 120.0), (9.0, 18.6, 30.0)]:
	creature("rune_caller", x, z, yaw, floor=R)
chest("chest_small", 5.0, 19.0, 90.0, "Acolyte's chest", y=G)

# 11 Quiet Shrine: the healing basin on the north wall.
prop("decor/healing_fountain.glb", 8.0, G + 0.01, 3.6, 0.0, role="heal", label="Healing basin")  # face turned to the room
lights.append([8.0, R + 1.6, 3.6])

# 12 Rune Door hall: a chest by the wall.
chest("chest_small", 11.0, 27.0, 270.0, "Rune hall chest", y=G)

# Bell tower (level 3). 14 Bell Walk: Hollow Miners keep the bells.
for x, z, yaw in [(3.6, 48.0, 120.0), (8.6, 45.0, 250.0)]:
	creature("lost_miner", x, z, yaw, floor=B)

# 15 Broken Bridge: the chasm under it, 10 m down onto spikes; Bone Rots waiting on the far landing.
for x in range(int(CHASM[1]), int(CHASM[3]), 2):
	for z in range(int(CHASM[2]), int(CHASM[4]), 2):
		prop("dungeon/trap_spikes.glb", x + 1.0, CHASM[5], z + 1.0, rng.choice([0, 90, 180, 270]), role="trap",
			label="The chasm (falling in kills)" if (x, z) == (4, 54) else "")
for x, z, yaw in [(7.4, 66.6, 150.0), (10.6, 65.4, 210.0)]:
	creature("tunnel_rat", x, z, yaw, floor=B)

# 17 Bellringer's Loft: the hidden boulder at the landing's west end, the spiked chest in the niche behind it.
prop("cave/boulder_round.glb", 4.4, B, 65.0, 30.0, scale=2.4, role="secret", label="Hidden boulder (hit it)")
prop("dungeon/trap_chest_spikes_stone.glb", 3.0, B, 65.0, 90.0, role="trap", label="Spike holes round the chest")
chest("chest_small", 2.6, 65.0, 90.0, "The bellringer's hoard (always): shoot it first", True, "buried", y=B + 0.24)

# 18 Antechamber: a quiet room before the end (a chest).
chest("chest_small", 25.0, 69.0, 90.0, "Antechamber chest", y=H)

# 19 Orrin's Vigil: four newer brick pillars (step 2: hide behind them from the bell's ring); the Bell-Ringer waits at
# the back, about 9 m from the door (the Rune Key on him), two Hollow Miners.
for x, z in [(37.6, 60.0), (42.4, 60.0), (37.6, 66.0), (42.4, 66.0)]:
	column(x, z, B, 8.0, fresh=True)
creature("bell_ringer", 41.0, 58.6, 0.0, floor=B)
for x, z, yaw in [(35.6, 58.0, 150.0), (44.4, 68.4, 220.0)]:
	creature("lost_miner", x, z, yaw, floor=B)

# 21 Orrin's Rest: the recipe stand on the north wall, the big chest by the south wall.
RECIPE_STAND = {"pos": [52.0, H, 59.4], "yaw": 0.0, "page": "scroll_orrin", "kind": "recipe_stand_stone"}
prop("dungeon/recipe_stand_stone.glb", 52.0, H, 59.4, 0.0, role="loot", label="Recipe stand (same recipe every time)")
prop("dungeon/recipe_scroll.glb", 52.0, H + 0.90, 59.4 + 0.007, 0.0, role="loot", tilt=20.0)
chest("chest_copper", 51.0, 64.6, 180.0, "Orrin's chest (always)", True, "big", y=H)

# --- 4b. Decor from the catalogue: none yet (the temple look is step 4). The checks still run on what is there. ---
sys.path.insert(0, str(Path(__file__).resolve().parent))
import decor  # noqa: E402
import junk  # noqa: E402

LEVELS = (1, 2, 3)


def _d(n):
	return "decor/%s.glb" % n


DECOR = []
def _plvl_at(p):
	"""A prop's level: by its height, except the exit ledge and the slide (level 1, 8-16 m up)."""
	x, y, z = p["pos"]
	if 52.0 <= x < 68.0 and 54.0 <= z < 64.0 and y < B - 0.5:
		return 1
	return cell_floor_level(y + 0.5)


_plvl = _plvl_at
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
	return dw + [_dxz(p) for p in props if p["model"] in ("dungeon/entrance_stone.glb", "dungeon/wall_cracked_stone.glb")
		and _plvl(p) == l]


def _things(l):
	t = [_dxz(c) for c in chests if _plvl(c) == l]
	return t + ([(RECIPE_STAND["pos"][0], RECIPE_STAND["pos"][2])] if l == 3 else [])


def _traps(l):
	return [_dxz(p) for p in props if p["role"] in ("trap", "secret") and p["model"] not in _flatj and _plvl(p) == l]


def _doors(l):
	return _doorways(l) + [_dxz(p) for p in props if p["role"] == "door" and _plvl(p) == l]


_cols = lambda l: [(x, z, 0.5) for x, z, cl in COLUMNS if cl == l]
_problems = []
for l in LEVELS:
	_obst = [(p["pos"][0], p["pos"][2], max(junk.size(p["model"])[:2]) / 2, 0.0, decor.height(p["model"])) for p in props
		if p["role"] in ("decor", "heal") and p["model"] not in _flatj and _plvl(p) == l]
	_obst += [(p["pos"][0], p["pos"][2], 0.4, 1.0, 2.4) for p in props if p["role"] == "light" and _plvl(p) == l]
	_obst += [(c["pos"][0], c["pos"][2], 0.5, 0.0, 1.5) for c in creatures if _plvl(c) == l]
	_obst += [(x, z, r, 0.0, 6.0) for x, z, r in _cols(l)]
	_pr, _ = decor.check(_items[l], _cells_l[l], junk.walk_lines(_spaces_l[l], _group, _cells_l[l], _doorways(l)),
		doors=_doors(l), things=_things(l), traps=_traps(l), obstacles=_obst)
	_problems += _pr
if _problems:
	sys.exit("decor breaks the placement rules:\n  " + "\n  ".join(_problems))
for l in LEVELS:
	props += decor.props(_items[l], lambda g: SP[g][5])

# --- 4c. Junk: an old temple long left: bones, rags, candles, urns, a lot of fallen brick
# (tools/dungeons/junk.py; tests/test_dungeon_junk.gd). (The full temple look is step 4.)
OLD = ["bones", "rags", "candles", "urn_broken", "rubble_brick", "rubble_brick", "torch_dropped"]
JUNK_THEMES = {
	"pilgrims_door": OLD + ["lantern", "tools"],
	"hall_of_pillars": OLD + ["urns"],
	"robing_room": ["rags", "rags", "bedroll_rotten", "candles", "urns", "rubble_brick", "stone_stool"],
	"rune_gallery": OLD + ["urns"],
	"cells_way": ["bones", "rags", "rubble_brick", "torch_dropped"],
	"carvers_workshop": ["tools", "tools", "rubble_brick", "stone_stool", "candles", "bones"],
	"carvers_vault": ["rubble_brick", "bones"],
	"hall_of_echoes": ["bones", "rubble_brick", "urn_broken", "candles"],
	"acolytes_sanctum": OLD + ["bedroll_rotten", "meal"],
	"quiet_shrine": ["candles", "candles", "urns", "rags", "bedroll_rotten"],
	"rune_hall": OLD,
	"bell_walk": OLD + ["lantern"],
	"antechamber": ["candles", "urns", "urn_broken", "bones", "rubble_brick"],
	"orrins_vigil": ["bones", "candles", "urns", "rags", "torch_dropped"],
	"orrins_rest": ["candles", "urns"],
}
_jcounts = {}
for g in JUNK_THEMES:
	_floor = [c for c, v in cells.items() if v == g]
	_lv = level(g)
	_there = sum(1 for p in props if p["role"] in ("decor", "light", "heal") and p["model"] not in _flatj
		and SP[g][5] - 0.5 < p["pos"][1] < SP[g][5] + 1.0 and cells.get((*junk.cell_of(p["pos"][0], p["pos"][2]), _lv)) == g)
	_there += sum(1 for c in chests if cells.get((*junk.cell_of(c["pos"][0], c["pos"][2]), _lv)) == g)
	_jcounts[g] = max(2, round(1.8 * len(_floor) * 4 / 10) - _there)
for l in LEVELS:
	_new = junk.place_junk(
		_spaces_l[l], _group, _cells_l[l], lambda g, l=l: SP[g][5] if g in SP else {1: 0.0, 2: R, 3: B}[l],
		{r for r in JUNK_THEMES if level(r) == l}, JUNK_THEMES,
		doors=_doors(l), path_doors=_doorways(l), things=_things(l), traps=_traps(l),
		furniture=[(p["pos"][0], p["pos"][2], max(junk.size(p["model"])[:2]) / 2) for p in props
			if p["role"] in ("decor", "light", "heal") and p["model"] not in _flatj and _plvl(p) == l] + _cols(l),
		seed=9013, skip={"entry"}, counts={r: n for r, n in _jcounts.items() if level(r) == l},
	)

	def _ok(j):   # (no junk on a stair or its foot, an open strip, a fake slab, under the ledge's heap, or near a pit)
		x, z = j["pos"][0], j["pos"][2]
		k = (*junk.cell_of(x, z), l)
		if k not in cells or cells[k] in NATURAL or k in OPEN or k in FAKE_FLOOR:   # (NATURAL: the stairs and their feet)
			return False
		if l == 1 and 49.0 < x < 52.0 and 53.5 < z < 58.5:
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
plan = {"name": "Vigil of Orrin Stonejaw", "map": "orrin", "pieces": pieces, "props": props, "creatures": creatures,
	"chests": chests, "lights": lights, "recipe_stand": RECIPE_STAND}
out = ROOT / "blueprints/dungeons/vigil_of_orrin_stonejaw.json"
out.write_bytes(json.dumps(plan, indent=0, separators=(",", ":")).encode("utf-8"))
print("WROTE %s: %d pieces, %d props, %d creatures, %d chests, %d junctions, %d lights, %d ceiling holes" % (out.name,
	len(pieces), len(props), len(creatures), len(chests), len(junctions), len(lights), len(holes)))
