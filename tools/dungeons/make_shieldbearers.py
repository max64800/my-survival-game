# The Hall of the Shieldbearers (dungeon map 8): every Stonehold stone piece, stair, trap, chest and skeleton soldier, laid
# out on the dungeon's rooms (read from src/world/dungeon_map.gd's SHIELDBEARERS, so the rock and the pieces always match).
#   python tools/dungeons/make_shieldbearers.py   -> blueprints/dungeons/hall_of_the_shieldbearers.json (the game builds from it)
# Positions are the dungeon's own metres (x right, z toward the cave, y up), like DungeonMap. The plan:
# docs/design/zone1-dungeons/08-hall-of-the-shieldbearers.md + 2026-11-28-shieldbearers-decisions.md (owner, Nov 28, F977:
# skeleton soldiers, Sergeant Halfhelm = a shield-bash skeleton, a lived-in barracks: neat stone, mostly whole). Two levels:
# the barracks at 0 and the drill cellars at CELLAR = -8, joined by two straight stone stairs (each four 2 m steps).
# Step 1 of the decisions file: rooms, stairs, way out, monsters, the old traps. (New traps and the barracks look: later.)
import json, random, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = (ROOT / "src/world/dungeon_map.gd").read_text(encoding="utf-8").split("const SHIELDBEARERS")[1].split("\n}\n")[0]
D = -8.0  # DungeonMap.CELLAR
SPACES = []
for m in re.findall(r'\["(\w+)",([^\]]*)\]', SRC):
	if '"' in m[1]:
		continue  # (a list of names, not a space)
	SPACES.append([m[0]] + [float(eval(v, {"CELLAR": D})) for v in m[1].split(",")])
SP = {s[0]: s for s in SPACES}
MAT = "cut_stone"
MOUTH_X, MOUTH_Z = 46.0, 70.0
CAVE_Z = MOUTH_Z + 4.0  # the round door at the end of the way in (DungeonMap.FACE)
GAP = 0.5               # DungeonMap.GAP: the rock stands this far behind the wall lines
rng = random.Random(8021)

NOT_ROOMS = {"chasm", "practice_spikes"}   # spaces that are no floor cells of their own (you fall into them)
GROUP = {"cellar_a": "cellar_stair", "cellar_b": "cellar_stair", "cellar_c": "cellar_stair", "cellar_foot": "cellar_stair",
	"back_a": "back_stair", "back_b": "back_stair", "back_c": "back_stair", "back_foot": "back_stair"}
NATURAL = {"cellar_stair", "back_stair"}   # rock overhead (no stone ceiling): the stairs
# The stairs: cell (x, z, level) -> (its bottom, rot). A straight stair piece climbs 2 m over its 2 m cell, from its
# front (+z at rot 0) to its back; rot 1 turns the front to +x, 2 to -z, 3 to -x.
STAIRS = {}
for z in (14, 16):   # the Cellar Stair: down east from the Training Yard (x 36) to its foot (x 42)
	for i, x in enumerate((36, 38, 40, 42)):
		STAIRS[(x, z, 2)] = (-2.0 - 2.0 * i, 1)
for x in (18, 20):   # the Back Stair: up south from its foot (z 6) into the Armoury Door hall (z 14)
	for i, z in enumerate((12, 10, 8, 6)):
		STAIRS[(x, z, 2)] = (-2.0 - 2.0 * i, 2)
# Junctions between a level-1 room and a level-2 one (the stairs' tops): open like any other doorway.
CROSS = {("cellar_stair", "training_yard"), ("back_stair", "armoury_door")}
NO_PIECES = {(2, 18, 1)}   # the boulder niche: bare rock behind the hidden boulder
DARK = {"entry", "muster_door", "sentry_door", "mess_door", "kitchen_door", "row_door", "bunk_door", "yard_door",
	"forced_door", "armoury_way", "bridge_way", "captain_door", "armoury_lock", "deserters_stash", "boulder_niche",
	"bolt_hole", "pit_door", "quarters_door", "infirmary_door", "cellar_stair", "back_stair"}
DOOR_SCALE = 1.5   # the round doorway at 1.5x: a hole about 2 m wide and 2.6 m high
# A lived-in barracks (owner): mostly whole. A few worn stones, hardly a broken top, a ceiling slab down here and there.
WORN = 0.1        # a wall piece worn and chipped
COLLAPSED = 0.03  # the top row of a wall broken off
NO_CEILING = 0.04 # a ceiling piece fallen


def level(name):
	g = GROUP.get(name, name)
	if name == "chasm":
		return 1   # (it hangs under the level-1 bridge)
	return 2 if g in ("cellar_stair", "back_stair") or SP[name][5] < -5.0 else 1


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


# (Halfhelm and his bodyguard's leader wear the big miners' bodies for now: their soldier look is step 2.)
CREATURE_MODEL = {"lost_miner": "creatures/lost_miner_frost.glb", "tunnel_rat": "creatures/tunnel_rat_rust.glb",
	"halfhelm": "creatures/prop_warden.glb", "shield_guard": "creatures/foreman.glb"}


def creature(kind, x, z, yaw=0.0, floor=0.0, wake=None, up=0.25):
	creatures.append({"kind": kind, "model": CREATURE_MODEL[kind], "pos": r3((x, floor + up, z)), "yaw": yaw, "scale": 1.0,
		"floor": floor, **({"wake": wake} if wake else {})})


def chest(kind, x, z, yaw, label, sure=False, loot="random", y=0.25):
	"""A chest (the game makes it a real chest with loot: DungeonBuild.LOOT[loot]). Not `sure`: there in about 2 of 3 worlds."""
	chests.append({"kind": kind, "pos": r3((x, y, z)), "yaw": yaw, "label": label, "always": sure, "loot": loot})


# --- 1. The cells (x, z, level): stone floors, stone ceilings (a few fallen), the stairs. ---
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


# The Kitchens' loose stone hides a buried chest.
SPECIAL_FLOOR = {(60, 32, 1): "floor_loose_flagstone"}
# The Shield Bridge: slabs only down its middle (x 6-10) over the chasm (z 26-36); the strips either side are open.
CHASM = SP["chasm"]
OPEN = {(x, z, 1) for z in range(int(CHASM[2]), int(CHASM[4]), 2) for x in (4, 10)}
# Loose slabs that give way under you (instant death): two staggered ones on the bridge (a careful dwarf crosses on the
# sound ones), and the middle of the Practice Pit over its spikes (keep to the solid edge along the walls). The tell:
# the slab sits loose and odd among the others.
TRAP_RNG = random.Random(812)
PIT = SP["practice_spikes"]
FAKE_FLOOR = {(6, 28, 1), (8, 32, 1)} | {(x, z, 2) for x in range(int(PIT[1]), int(PIT[3]), 2)
	for z in range(int(PIT[2]), int(PIT[4]), 2)}
holes = set()   # the cells whose ceiling fell in
for key, g in cells.items():
	if key in NO_PIECES:
		continue
	x, z, lvl = key
	cx, cz, fy = x + 1.0, z + 1.0, cell_floor[key]
	if key in STAIRS:
		bottom, rot = STAIRS[key]
		piece("stairs", cx, bottom, cz, rot)
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
	if rng.random() < NO_CEILING and g not in DARK:
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
		if other is None:   # a stair's top meets a room of the other level
			k2 = (x + dx, z + dz, 3 - lvl)
			if k2 in cells and ((g, cells[k2]) in CROSS or (cells[k2], g) in CROSS):
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


def wall_piece(x, y, z, rot, yaw, top_row):
	"""One 2 m stone wall piece: plain, worn, or (top row) broken off."""
	r = rng.random()
	if top_row and r < COLLAPSED:
		piece("ruin_wall_collapsed", x, y, z, rot)
	elif r < COLLAPSED + WORN:
		piece("ruin_wall_worn", x, y, z, rot)
	else:
		piece("wall", x, y, z, rot)


# The dart wall: the Drill Cellar's west wall at z 12-14 (a tripwire runs east across the room from its hole): a crossbow
# in a guard slot. The spear walls: one on each side of Barracks Row's east end, out of step (go when they pull back).
DART = {("drill_cellar", "w", 46, 13.0)}
SPEARS = {("barracks_row", "n", 30, 35.0): 0.0, ("barracks_row", "s", 34, 33.0): 1.0}
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
			prop("dungeon/trap_crossbow_wall_stone.glb", x, y, z, yaw, role="trap", label="A guard slot (something glints inside)")
		elif r == 0 and (g, side, line, along) in SPEARS:
			prop("dungeon/trap_spear_wall.glb", x, y, z, yaw, role="trap", label="Rows of holes (a rusty tip shows)",
				phase=SPEARS[(g, side, line, along)])
		else:
			wall_piece(x, y, z, rot, yaw, r == rows - 1 and rows >= 2)
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
# it up to the taller room's ceiling, and (a stair's top) walls under it down to the lower floor. Special ones: the
# cracked wall to the Deserter's Stash, the barred way-out gate, the boss room's round door, the locked Armoury door, the
# portcullis of the Sergeant's Quarters.
SPECIAL_J = {("bunk_rooms", "deserters_stash"): "cracked", ("bolt_hole", "muster_gate"): "gate",
	("captain_door", "captains_hall"): "hand_door", ("armoury_lock", "captains_hall"): "locked",
	("quarters_door", "sergeants_quarters"): "portcullis"}
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
	if kind == "portcullis":   # (Halfhelm's bodyguard: it drops behind you, lifts when the room is won)
		prop("dungeon/portcullis.glb", x, y, z, 90.0 if along_z else 0.0, DOOR_SCALE, role="door", label="Portcullis",
			room="sergeants_quarters")
	else:
		piece("doorway", x, y, z, rot, DOOR_SCALE)
	if kind == "hand_door":
		prop("dungeon/door_loot.glb", x, y, z, 90.0 if along_z else 0.0, DOOR_SCALE, role="door", label="Round door: E to open", opens="hand")
	if kind == "locked":   # (DungeonKeys: the Armoury Key opens it; Sergeant Halfhelm holds the key)
		prop("dungeon/door_loot.glb", x, y, z, 90.0 if along_z else 0.0, DOOR_SCALE, role="door", label="Armoury door (locked: the Armoury Key)")
	if kind == "gate":
		prop("dungeon/gate_iron.glb", x, y, z, 90.0 if along_z else 0.0, DOOR_SCALE, role="door", label="Barred gate: the way out")
		# The lever: on the bolt-hole's north wall, 1.2 m before the gate, its back on the wall's face.
		prop("dungeon/lever_iron.glb", x - 1.2, y, SP["bolt_hole"][2] + 0.15, 0.0, role="door", label="Lever: E to open the gate")
	for edge in (lo + 0.5, hi - 0.5):
		x, z = p(edge)
		piece("wall_narrow", x, y, z, rot)
		piece("wall_narrow", x, y + 2.0, z, rot)
	top = j["low"] + j["h"]   # the taller room's ceiling over the lower floor
	if top - y > 3.0:
		x, z = p(mid)
		piece("half_wall", x, y + 3.0, z, rot)
	for wy in range(int(y + 4.0), int(top), 2):   # (a 6 or 8 m room: whole walls on up)
		for al in (mid - 1.0, mid + 1.0):
			x, z = p(al)
			piece("wall", x, float(wy), z, rot)
	for wy in range(int(j["low"]), int(y), 2):    # (a stair's top: walls under the doorway down to the low floor)
		for al in (mid - 1.0, mid + 1.0):
			x, z = p(al)
			piece("wall", x, float(wy), z, rot)

# --- 3. The way in: the round stone door where the tunnel meets the cave (stone pillars and lintel, F859). ---
prop("dungeon/entrance_stone.glb", MOUTH_X, 0.0, CAVE_Z, 0.0, role="door", label="The way in: round stone door")
for x in (MOUTH_X - 1.5, MOUTH_X + 1.5):
	piece("wall_narrow", x, 0.0, CAVE_Z, 0)
for x in (MOUTH_X - 1.0, MOUTH_X + 1.0):
	piece("half_wall", x, 2.0, CAVE_Z, 0)


# --- 4. The rooms, one by one. F = the barracks' floor top, G = the drill cellars'. ---
F = 0.25
G = D + 0.25

# 2 Parade Ground: Hollow Miners still drilling.
for x, z, yaw in [(42.6, 45.0, 90.0), (49.6, 49.0, 200.0), (49.0, 42.4, 300.0)]:
	creature("lost_miner", x, z, yaw)

# 3 Sentry Walk: two guards, a chest at its far end.
for x, z, yaw in [(56.0, 49.4, 180.0), (55.4, 42.0, 20.0)]:
	creature("tunnel_rat", x, z, yaw)
chest("chest_small", 57.0, 51.0, 270.0, "Sentry's chest")

# 4 Mess Hall: Bone Rots at the tables, a chest by the wall.
for x, z, yaw in [(42.6, 33.0, 90.0), (49.4, 28.6, 250.0), (46.0, 35.4, 160.0)]:
	creature("tunnel_rat", x, z, yaw)
chest("chest_small", 41.0, 27.0, 90.0, "Mess chest")

# 5 Kitchens: the loose stone hides a buried chest.
chest("chest_small", 61.0, 33.0, 270.0, "Buried chest (under the loose stone)", True, "buried")

# 7 Bunk Rooms: Bone Rots in the bunks; 8 what a deserter hid behind the cracked wall.
for x, z, yaw in [(28.0, 42.0, 120.0), (32.4, 38.6, 300.0)]:
	creature("tunnel_rat", x, z, yaw)
chest("chest_small", 23.0, 40.0, 90.0, "The deserter's stash (always)", True, "vault")

# 9 Training Yard: Bone Rots drilling; bear jaws in the sand (a rusty glint: step round them).
for x, z, yaw in [(26.6, 18.0, 60.0), (33.4, 23.0, 250.0)]:
	creature("tunnel_rat", x, z, yaw)
prop("dungeon/trap_bear_jaws.glb", 29.4, F - 0.01, 21.6, 40.0, role="trap", label="Bear jaws (a rusty glint in the sand)")
prop("dungeon/trap_bear_jaws.glb", 31.6, F - 0.01, 17.6, 160.0, role="trap")
prop("dungeon/trap_bear_jaws.glb", 26.6, F - 0.01, 22.6, 100.0, role="trap")

# 17 Armoury: a chest by the wall; the hidden boulder at its west end, the spiked chest in the niche behind it.
chest("chest_small", 11.0, 15.0, 270.0, "Armoury chest")
prop("cave/boulder_round.glb", 4.4, 0.0, 19.0, 30.0, scale=2.4, role="secret", label="Hidden boulder (hit it)")
prop("dungeon/trap_chest_spikes_stone.glb", 3.0, 0.0, 19.0, 90.0, role="trap", label="Spike holes round the chest")
chest("chest_small", 2.6, 19.0, 90.0, "The niche hoard (always): shoot it first", True, "buried", y=0.24)

# 18 Shield Bridge: the chasm under it, 10 m down onto spikes; Bone Rots waiting on the far landing.
for x in range(int(CHASM[1]), int(CHASM[3]), 2):
	for z in range(int(CHASM[2]), int(CHASM[4]), 2):
		prop("dungeon/trap_spikes.glb", x + 1.0, CHASM[5], z + 1.0, rng.choice([0, 90, 180, 270]), role="trap",
			label="The chasm (falling in kills)" if (x, z) == (4, 26) else "")
for x, z, yaw in [(5.0, 37.0, 150.0), (11.0, 37.0, 210.0)]:
	creature("tunnel_rat", x, z, yaw)

# 20 Captain's Hall: Sergeant Halfhelm waits at the back, about 9 m from the door (the Armoury Key on him), two soldiers.
creature("halfhelm", 8.0, 61.0, 180.0)
for x, z, yaw in [(3.6, 63.0, 150.0), (12.4, 55.6, 220.0)]:
	creature("lost_miner", x, z, yaw)

# Drill cellars (level 2). 12 Drill Cellar: a thin wire across it at ankle height, from the dart hole's sill (west wall)
# 4 m east: step over it or cut it, or the crossbow in the guard slot shoots down the wire. Soldiers drilling.
prop("dungeon/tripwire_iron.glb", 48.0, G - 0.01, 12.88, 0.0, role="trap", label="Tripwire (step over it, or cut it)",
	stretch=round(4.0 - 0.3, 2))
creature("lost_miner", 51.0, 16.0, 200.0, floor=D)
creature("tunnel_rat", 52.0, 11.6, 300.0, floor=D)

# 13 Practice Pit: the loose slabs in its middle (above), the spikes 4 m under them.
for x in range(int(PIT[1]), int(PIT[3]), 2):
	for z in range(int(PIT[2]), int(PIT[4]), 2):
		prop("dungeon/trap_spikes.glb", x + 1.0, PIT[5], z + 1.0, rng.choice([0, 90, 180, 270]), role="trap",
			label="The practice pit: spikes at the bottom (falling in kills)" if (x, z) == (44, 2) else "")

# 14 Sergeant's Quarters: Halfhelm's bodyguard (a big skeleton leader and two soldiers); the portcullis drops behind you.
creature("shield_guard", 35.0, 4.6, 90.0, floor=D)
for x, z, yaw in [(33.6, 6.6, 120.0), (37.6, 1.4, 300.0)]:
	creature("lost_miner", x, z, yaw, floor=D)
chest("chest_small", 33.0, 1.0, 90.0, "Sergeant's chest", y=G)

# 15 Infirmary: the healing basin on the north wall.
prop("decor/healing_fountain.glb", 26.0, G + 0.01, 1.6, 0.0, role="heal", label="Healing basin")  # face turned to the room
lights.append([26.0, D + 1.6, 1.6])

# 21 Captain's Armoury: the recipe stand, the big chest.
RECIPE_STAND = {"pos": [20.0, F, 62.6], "yaw": 180.0, "page": "scroll_shieldbearers", "kind": "recipe_stand_stone"}
prop("dungeon/recipe_stand_stone.glb", 20.0, F, 62.6, 180.0, role="loot", label="Recipe stand (same recipe every time)")
prop("dungeon/recipe_scroll.glb", 20.0, F + 0.90, 62.6 - 0.007, 180.0, role="loot", tilt=20.0)
chest("chest_copper", 21.0, 57.4, 0.0, "The captain's chest (always)", True, "big")

# --- 4b. Decor from the catalogue: none yet (the barracks look is step 4). The checks still run on what is there. ---
sys.path.insert(0, str(Path(__file__).resolve().parent))
import decor  # noqa: E402
import junk  # noqa: E402

W = decor.wall


def _d(n):
	return "decor/%s.glb" % n


DECOR = []
_plvl = lambda p: 1 if p["pos"][1] > -3.0 else 2
_flatj = {"dungeon/wall_cracked_stone.glb", "dungeon/floor_loose_flagstone.glb"}
_dxz = lambda p: (p["pos"][0], p["pos"][2])
_cells_l = {l: {(k[0], k[1]): v for k, v in cells.items() if k[2] == l and k not in NO_PIECES} for l in (1, 2)}
_spaces_l = {l: [s for s in SPACES if s[0] not in NOT_ROOMS and level(s[0]) == l] for l in (1, 2)}
_group = lambda n: GROUP.get(n, n)
_items = {1: [], 2: []}
for n, room, at, *up in DECOR:
	_items[level(room)].append((_d(n), at[0], at[1], at[2], room) + tuple(up))


def _doorways(l):
	dw = [_dxz(p) for p in pieces if p["id"] == "doorway" and _plvl(p) == l]
	return dw + [_dxz(p) for p in props if p["model"] in ("dungeon/entrance_stone.glb", "dungeon/wall_cracked_stone.glb",
		"dungeon/portcullis.glb") and _plvl(p) == l]


def _things(l):
	t = [_dxz(c) for c in chests if _plvl(c) == l] + [_dxz(p) for p in props if "lever" in p["model"] and _plvl(p) == l]
	return t + ([(RECIPE_STAND["pos"][0], RECIPE_STAND["pos"][2])] if l == 1 else [])


def _traps(l):
	return [_dxz(p) for p in props if p["role"] in ("trap", "secret") and p["model"] not in _flatj and _plvl(p) == l]


def _doors(l):
	return _doorways(l) + [_dxz(p) for p in props if p["role"] == "door" and "lever" not in p["model"] and _plvl(p) == l]


_problems = []
for l in (1, 2):
	_obst = [(p["pos"][0], p["pos"][2], max(junk.size(p["model"])[:2]) / 2, 0.0, decor.height(p["model"])) for p in props
		if p["role"] in ("decor", "heal") and p["model"] not in _flatj and _plvl(p) == l]
	_obst += [(p["pos"][0], p["pos"][2], 0.4, 1.0, 2.4) for p in props if p["role"] == "light" and _plvl(p) == l]
	_obst += [(c["pos"][0], c["pos"][2], 0.5, 0.0, 1.5) for c in creatures if _plvl(c) == l]
	_pr, _ = decor.check(_items[l], _cells_l[l], junk.walk_lines(_spaces_l[l], _group, _cells_l[l], _doorways(l)),
		doors=_doors(l), things=_things(l), traps=_traps(l), obstacles=_obst)
	_problems += _pr
if _problems:
	sys.exit("decor breaks the placement rules:\n  " + "\n  ".join(_problems))
for l in (1, 2):
	props += decor.props(_items[l], lambda g: SP[g][5])

# --- 4c. Junk: a barracks the soldiers just left: their gear, bedding, meals, a few fallen stones
# (tools/dungeons/junk.py; tests/test_dungeon_junk.gd). (The full lived-in look is step 4.)
SOLDIERS = ["helmet", "shield_iron", "sword_snapped", "spear_broken", "bones", "torch_dropped", "lantern"]
JUNK_THEMES = {
	"muster_gate": SOLDIERS + ["rubble_brick", "furn_crate_iron"],
	"bolt_hole": ["bones", "rags", "torch_dropped", "rubble_brick"],
	"parade_ground": SOLDIERS + ["furn_weapon_stand", "armour_pile"],
	"sentry_walk": ["helmet", "bones", "torch_dropped", "lantern", "rags"],
	"mess_hall": ["furn_table_long", "stone_stool", "meal", "candles", "bones", "cookpot_tipped"],
	"kitchens": ["cookpot_tipped", "meal", "furn_crate_iron", "crate_stack", "bones", "urns"],
	"barracks_row": ["helmet", "bones", "rags", "torch_dropped"],
	"bunk_rooms": ["bedroll_rotten", "rags", "bones", "stone_stool", "candles", "helmet"],
	"deserters_stash": ["rags", "bones"],
	"training_yard": SOLDIERS + ["furn_weapon_stand", "rubble_brick"],
	"armoury_door": ["helmet", "bones", "rubble_brick", "shield_iron"],
	"armoury": ["shield_iron", "sword_snapped", "spear_broken", "armour_pile", "furn_weapon_stand", "axe_head"],
	"banner_hall": ["bones", "helmet", "torch_dropped", "rags"],
	"captains_hall": SOLDIERS + ["armour_pile", "furn_weapon_stand", "rubble_brick"],
	"captains_armoury": ["furn_crate_iron", "armour_pile", "shield_iron", "candles"],
	"drill_cellar": SOLDIERS + ["furn_weapon_stand"],
	"sergeants_quarters": SOLDIERS + ["furn_table_long", "stone_stool", "meal"],
	"infirmary": ["bedroll_rotten", "rags", "candles", "urns", "bones"],
}
_jcounts = {}
for g in JUNK_THEMES:
	_floor = [c for c, v in cells.items() if v == g]
	_lv = level(g)
	_there = sum(1 for p in props if p["role"] in ("decor", "light", "heal") and p["model"] not in _flatj
		and p["pos"][1] < SP[g][5] + 1.0 and cells.get((*junk.cell_of(p["pos"][0], p["pos"][2]), _lv)) == g)
	_there += sum(1 for c in chests if cells.get((*junk.cell_of(c["pos"][0], c["pos"][2]), _lv)) == g)
	_jcounts[g] = max(2, round(1.8 * len(_floor) * 4 / 10) - _there)
for l in (1, 2):
	_new = junk.place_junk(
		_spaces_l[l], _group, _cells_l[l], lambda g, l=l: SP[g][5] if g in SP else (0.0 if l == 1 else D),
		{r for r in JUNK_THEMES if level(r) == l}, JUNK_THEMES,
		doors=_doors(l), path_doors=_doorways(l), things=_things(l), traps=_traps(l),
		furniture=[(p["pos"][0], p["pos"][2], max(junk.size(p["model"])[:2]) / 2) for p in props
			if p["role"] in ("decor", "light", "heal") and p["model"] not in _flatj and _plvl(p) == l],
		seed=8013, skip={"entry"}, counts={r: n for r, n in _jcounts.items() if level(r) == l},
	)

	def _ok(j):   # (no junk on a stair or its foot, an open strip, a fake slab, past a room's edge, or within 0.8 m of a pit)
		x, z = j["pos"][0], j["pos"][2]
		k = (*junk.cell_of(x, z), l)
		if k not in cells or cells[k] in NATURAL or k in OPEN or k in FAKE_FLOOR:   # (NATURAL: the stairs and their feet)
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
plan = {"name": "Hall of the Shieldbearers", "map": "shieldbearers", "pieces": pieces, "props": props, "creatures": creatures,
	"chests": chests, "lights": lights, "recipe_stand": RECIPE_STAND}
out = ROOT / "blueprints/dungeons/hall_of_the_shieldbearers.json"
out.write_text(json.dumps(plan, indent=0, separators=(",", ":")), encoding="utf-8")
print("WROTE %s: %d pieces, %d props, %d creatures, %d chests, %d junctions, %d lights, %d ceiling holes" % (out.name,
	len(pieces), len(props), len(creatures), len(chests), len(junctions), len(lights), len(holes)))
