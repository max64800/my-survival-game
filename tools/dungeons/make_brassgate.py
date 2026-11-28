# The Brassgate Vault (dungeon map 7): every Stonehold stone piece, stair, trap, chest, lost miner and ghost, laid out on
# the dungeon's rooms (read from src/world/dungeon_map.gd's BRASSGATE, so the rock and the pieces always match).
#   python tools/dungeons/make_brassgate.py   -> blueprints/dungeons/brassgate_vault.json (the game builds from it)
# Positions are the dungeon's own metres (x right, z toward the cave, y up), like DungeonMap. The plan:
# docs/design/zone1-dungeons/07-brassgate-vault.md + 2026-11-28-brassgate-decisions.md (owner, Nov 28, F975: lost
# miners + ghosts, the Vault Captain = a big armoured lost miner, grand + brass: neat stone, mostly whole). Two levels:
# the toll halls at 0 and the old mint at MINT = -8, joined by two straight stone stairs (each four 2 m steps).
# Step 1 of the decisions file: rooms, stairs, way out, monsters, the old traps. (Brass looks and new traps: later steps.)
import json, random, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = (ROOT / "src/world/dungeon_map.gd").read_text(encoding="utf-8").split("const BRASSGATE")[1].split("\n}\n")[0]
D = -8.0  # DungeonMap.MINT
SPACES = []
for m in re.findall(r'\["(\w+)",([^\]]*)\]', SRC):
	if '"' in m[1]:
		continue  # (a list of names, not a space)
	SPACES.append([m[0]] + [float(eval(v, {"MINT": D})) for v in m[1].split(",")])
SP = {s[0]: s for s in SPACES}
MAT = "cut_stone"
MOUTH_X, MOUTH_Z = 40.0, 70.0
CAVE_Z = MOUTH_Z + 4.0  # the round door at the end of the way in (DungeonMap.FACE)
GAP = 0.5               # DungeonMap.GAP: the rock stands this far behind the wall lines
rng = random.Random(7021)

NOT_ROOMS = {"chute_pit"}   # spaces that are no floor cells of their own (the Coin Chute's spike pit)
GROUP = {"mint_a": "mint_stair", "mint_b": "mint_stair", "mint_c": "mint_stair", "mint_foot": "mint_stair",
	"back_a": "back_stair", "back_b": "back_stair", "back_c": "back_stair", "back_foot": "back_stair"}
NATURAL = {"mint_stair", "back_stair"}   # rock overhead (no stone ceiling): the stairs
# The stairs: cell (x, z, level) -> (its bottom, rot). A straight stair piece climbs 2 m over its 2 m cell, from its
# front (+z at rot 0) to its back; rot 1 turns the front to +x, 2 to -z, 3 to -x.
STAIRS = {}
for z in (32, 34):   # the Mint Stair: down east from the Guard Corridor (x 42) to its foot (x 48)
	for i, x in enumerate((42, 44, 46, 48)):
		STAIRS[(x, z, 2)] = (-2.0 - 2.0 * i, 1)
for x in (26, 28):   # the Back Stair: up north from its foot (z 10) into the Inner Door hall (z 18)
	for i, z in enumerate((16, 14, 12, 10)):
		STAIRS[(x, z, 2)] = (-2.0 - 2.0 * i, 2)
# Junctions between a level-1 room and a level-2 one (the stairs' tops): open like any other doorway.
CROSS = {("mint_stair", "guard_corridor"), ("back_stair", "inner_door")}
NO_PIECES = {(4, 20, 1)}   # the boulder niche: bare rock behind the hidden boulder
DARK = {"entry", "toll_door", "count_door", "clerks_door", "clerks_hoard", "inner_way", "swing_way", "boulder_niche",
	"vault_door", "vault_lock", "bolt_hole", "shrine_door", "shrine_way", "mint_stair", "back_stair", "mint_work"}
DOOR_SCALE = 1.5   # the round doorway at 1.5x: a hole about 2 m wide and 2.6 m high
# Grand and guarded (owner): mostly whole. A few worn stones, hardly a broken top, a ceiling slab down here and there.
WORN = 0.1        # a wall piece worn and chipped
COLLAPSED = 0.03  # the top row of a wall broken off
NO_CEILING = 0.04 # a ceiling piece fallen


def level(name):
	g = GROUP.get(name, name)
	return 2 if g in ("mint_stair", "back_stair") or SP[name][5] < -5.0 else 1

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


# (The Vault Captain and his bodyguard's leader wear the big miners' bodies for now: their brass look is step 2.)
CREATURE_MODEL = {"ghost_a": "creatures/ghost_a.glb", "ghost_b": "creatures/ghost_b.glb", "ghost_c": "creatures/ghost_c.glb",
	"lost_miner": "creatures/lost_miner_frost.glb", "vault_captain": "creatures/prop_warden.glb",
	"vault_guard": "creatures/foreman.glb"}


def creature(kind, x, z, yaw=0.0, floor=0.0, wake=None, up=0.25):
	"""`up`: how high over its floor it waits (spiders cling high in the corners)."""
	creatures.append({"kind": kind, "model": CREATURE_MODEL[kind], "pos": r3((x, floor + up, z)), "yaw": yaw, "scale": 1.0,
		"floor": floor, **({"wake": wake} if wake else {})})


def chest(kind, x, z, yaw, label, sure=False, loot="random", y=0.25):
	"""A chest (the game makes it a real chest with loot: DungeonBuild.LOOT[loot]). Not `sure`: there in about 2 of 3 worlds."""
	chests.append({"kind": kind, "pos": r3((x, y, z)), "yaw": yaw, "label": label, "always": sure, "loot": loot})


# --- 1. The cells (x, z, level): stone floors, stone ceilings (about half fallen), the stairs. ---
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


# Owner's picks (F975): the old traps come back here. The loose stone in the Counting Room hides a buried chest; the
# grooved floor under the coin presses (the crushers) in the Workers' Hall.
SPECIAL_FLOOR = {(54, 48, 1): "floor_loose_flagstone"}
GROOVED = {(56, 20, 2), (58, 20, 2)}
# The Coin Chute's north half is open: the chute the coins slid down, 4 m onto spikes (falling in kills).
CHUTE = {(x, 14, 2) for x in (44, 46, 48)}
holes = set()   # the cells whose ceiling fell in
for key, g in cells.items():
	if key in NO_PIECES:
		continue
	x, z, lvl = key
	cx, cz, fy = x + 1.0, z + 1.0, cell_floor[key]
	if key in STAIRS:
		bottom, rot = STAIRS[key]
		piece("stairs", cx, bottom, cz, rot)
	elif key in CHUTE:
		pass
	elif key in GROOVED:
		prop("dungeon/floor_grooved.glb", cx, fy, cz, 90.0, role="trap", label="Grooves (the coin presses land here)" if x == 56 else "")
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


# The dart wall: the Guard Corridor's west wall at z 34-36 (a tripwire runs across the corridor from its hole): a
# crossbow in a guard slot. The push walls: the Coin Chute's south wall over the chute (x 44-50): a block slams out
# and shoves you north into it. (Set one off and jump back, then slip past while it slides home.)
DART = {("guard_corridor", "w", 38, 35.0)}
PUSH = {("coin_chute", "s", 18, x) for x in (45.0, 47.0, 49.0)}
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
		elif r == 0 and (g, side, line, along) in PUSH:
			prop("dungeon/trap_push_wall_stone.glb", x, y, z, yaw, role="trap",
				label="A gap round a block in the wall" if along == 45.0 else "")
		else:
			wall_piece(x, y, z, rot, yaw, r == rows - 1 and rows >= 2)
	if h % 2:
		piece("half_wall", x, fy + 2.0 * rows, z, rot)
	# A lamp on about every seventh wall of a lit room (the dark places get none: your lantern). (F860, owner Nov 25:
	# "make it darker": was every fourth wall; the game dims Hald's torches too, DungeonMap.HALD torch_energy.)
	n = torch_every.get(g, 0)
	torch_every[g] = n + 1
	if g not in DARK and key not in STAIRS and (g, side, line, along) not in DART | PUSH and n % 8 == 2:
		ox, oz = {"w": (0.2, 0), "e": (-0.2, 0), "n": (0, 0.2), "s": (0, -0.2)}[side]
		prop("decor/furn_wall_torch_iron.glb", x + ox, fy + 1.2, z + oz, yaw, role="light")
		lights.append([round(x + ox * 3, 2), fy + 2.0, round(z + oz * 3, 2)])

# Junctions: the round doorway (1.5x) in the middle of a 4 m opening, 1 m narrow walls beside it, two high, walls over
# it up to the taller room's ceiling, and (a stair's top) walls under it down to the lower floor. Special ones: the
# cracked wall to the Clerks' Hoard, the barred way-out gate, the boss room's round door, the locked Vault door, the
# portcullis of the Captain's Quarters.
SPECIAL_J = {("clerks_hoard", "clerks_rooms"): "cracked", ("bolt_hole", "brass_gate"): "gate",
	("vault_door", "vault_hall"): "hand_door", ("vault_hall", "vault_lock"): "vault",
	("captains_quarters", "coin_chute"): "portcullis"}
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
		for edge in [e for e in (lo + 0.5, hi - 0.5) if abs(e - mid) > 1.0]:   # (F857 🔁: the narrow walls beside it)
			x, z = p(edge)
			piece("wall_narrow", x, y, z, rot)
		continue
	if hi - lo != 4.0:
		sys.exit("junction %s/%s is %.0f m wide (doorways need 4 m)" % (a, b, hi - lo))
	x, z = p(mid)
	if kind == "portcullis":   # (the Captain's bodyguard: it drops behind you, lifts when the room is won)
		prop("dungeon/portcullis.glb", x, y, z, 90.0 if along_z else 0.0, DOOR_SCALE, role="door", label="Portcullis",
			room="captains_quarters")
	else:
		piece("doorway", x, y, z, rot, DOOR_SCALE)
	if kind == "hand_door":
		prop("dungeon/door_loot.glb", x, y, z, 90.0 if along_z else 0.0, DOOR_SCALE, role="door", label="Round door: E to open", opens="hand")
	if kind == "vault":   # (DungeonKeys: the Vault Key opens it; the Vault Captain holds the key)
		prop("dungeon/door_loot.glb", x, y, z, 90.0 if along_z else 0.0, DOOR_SCALE, role="door", label="Vault door (locked: the Vault Key)")
	if kind == "gate":
		prop("dungeon/gate_iron.glb", x, y, z, 90.0 if along_z else 0.0, DOOR_SCALE, role="door", label="Barred gate: the way out")
		# The lever: on the Bolt-hole's north wall, 1.2 m before the gate, its back on the wall's face.
		prop("dungeon/lever_iron.glb", x - 1.2, y, 56.0 + 0.15, 0.0, role="door", label="Lever: E to open the gate")
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


# --- 4. The rooms, one by one. F = the toll halls' floor top, G = the old mint's. ---
F = 0.25
G = D + 0.25

# 4 Toll Hall: the first lost miners (they still guard the toll), and a chest by the wall.
for x, z, yaw in [(36.6, 45.0, 90.0), (43.6, 49.0, 200.0), (43.0, 42.0, 300.0)]:
	creature("lost_miner", x, z, yaw)
chest("chest_small", 35.0, 41.0, 90.0, "Toll chest")

# 6 Counting Room: the loose stone hides a buried chest.
chest("chest_small", 55.0, 49.0, 270.0, "Buried chest (under the loose stone)", True, "buried")

# 8 Guard Corridor: a thin wire across it at ankle height, from the dart hole's sill (west wall) to the east wall:
# step over it or cut it, or the crossbow in the guard slot shoots down the wire.
prop("dungeon/tripwire_iron.glb", 40.0, 0.24, 34.88, 0.0, role="trap", label="Tripwire (step over it, or cut it)",
	stretch=round(4.0 - 0.3, 2))

# 16 Weighing Hall: lost miners round the scales; a cracked floor plate in the middle of the way.
for x, z, yaw in [(37.0, 25.0, 30.0), (43.4, 19.0, 250.0), (36.4, 18.4, 120.0)]:
	creature("lost_miner", x, z, yaw)
prop("dungeon/trap_dart_plate.glb", 40.12, F - 0.01, 22.6, 0.0, role="trap", label="Cracked floor plate", fires=True)

# 17 Clerks' Rooms: two clerks still at work; 18 their hoard behind the cracked wall.
for x, z, yaw in [(51.0, 24.0, 160.0), (54.0, 19.6, 300.0)]:
	creature("lost_miner", x, z, yaw)
chest("chest_small", 59.0, 22.0, 270.0, "The clerks' hoard (always)", True, "vault")

# 19 Swinging Hall: two boulders swing across the hall on their chains (shoot the chain, or time your run). The hidden
# boulder at its west end, the spiked chest in the niche behind it.
for i, x in enumerate((18.0, 14.0)):
	prop("dungeon/trap_swing_boulder.glb", x, 0.0, 22.0, 90.0, role="trap", label="Swinging boulder (shoot the chain)" if i == 0 else "")
prop("cave/boulder_round.glb", 6.4, 0.0, 21.0, 30.0, scale=2.4, role="secret", label="Hidden boulder (hit it)")
prop("dungeon/trap_chest_spikes_stone.glb", 5.0, 0.0, 21.0, 90.0, role="trap", label="Spike holes round the chest")
chest("chest_small", 4.6, 21.0, 90.0, "The niche hoard (always): shoot it first", True, "buried", y=0.24)

# 20 Treasury Corridor: two chests set by the walls, each with spike holes round it (shoot it first).
for cx, tx, z, yaw in [(8.6, 9.0, 27.0, 90.0), (11.4, 11.0, 33.0, 270.0)]:
	prop("dungeon/trap_chest_spikes_stone.glb", tx, 0.0, z, yaw, role="trap", label="Spike holes round the chest",
		on_open=True)   # (F975: open it unshot and the spikes stab you; walking past is safe)
	chest("chest_small", cx, z, yaw, "Treasury chest: shoot it first", True, "vault", y=0.24)

# 21 Vault Hall: the Vault Captain waits at the back, about 8 m from the door (the Vault Key on him), two miners with him.
creature("vault_captain", 11.0, 46.0, 180.0)
for x, z, yaw in [(6.0, 48.0, 150.0), (16.0, 41.0, 220.0)]:
	creature("lost_miner", x, z, yaw)

# Old mint (level 2). 9 Old Mint: Drifting Shades over the cold furnaces.
for x, z, yaw in [(56.0, 37.0, 30.0), (61.0, 33.0, 250.0), (58.6, 30.4, 140.0)]:
	creature("ghost_a", x, z, yaw, floor=D)
chest("chest_small", 63.0, 39.0, 270.0, "Mint chest", y=G)

# 11 Workers' Hall: the coin presses (crushers) across the way to the Coin Chute; run under the one that rises.
for i, x in enumerate((57.0, 59.0)):
	prop("dungeon/trap_crusher.glb", x, D + 1.25, 21.0, 0.0, role="trap", floor=D,
		label="Coin presses (watch their rhythm)" if i == 0 else "")
for x, z, yaw in [(55.0, 14.6, 60.0), (62.0, 15.0, 300.0)]:
	creature("ghost_c", x, z, yaw, floor=D)
chest("chest_small", 63.0, 13.0, 270.0, "Workers' chest", y=G)

# 12 Coin Chute: the open chute along its north wall, 4 m down onto spikes (the push walls across it shove you in).
for x, z, l in sorted(CHUTE):
	prop("dungeon/trap_spikes.glb", x + 1.0, D - 4.0, z + 1.0, rng.choice([0, 90, 180, 270]), role="trap",
		label="The coin chute: spikes at the bottom (falling in kills)" if x == 44 else "")

# 13 Captain's Quarters: his bodyguard (a big miner leader and two miners); the portcullis drops behind you.
creature("vault_guard", 36.0, 18.6, 90.0, floor=D)
for x, z, yaw in [(33.6, 20.4, 120.0), (38.4, 16.4, 300.0)]:
	creature("lost_miner", x, z, yaw, floor=D)
chest("chest_small", 33.0, 15.0, 90.0, "Captain's chest", y=G)

# 14 Guard Shrine: the healing basin.
prop("decor/healing_fountain.glb", 36.0, G + 0.01, 3.6, 0.0, role="heal", label="Healing basin")  # face turned to the room
lights.append([36.0, D + 1.6, 3.6])

# 22 Strongroom: the recipe stand, the big chest.
RECIPE_STAND = {"pos": [18.0, F, 60.6], "yaw": 180.0, "page": "scroll_brassgate", "kind": "recipe_stand_stone"}
prop("dungeon/recipe_stand_stone.glb", 18.0, F, 60.6, 180.0, role="loot", label="Recipe stand (same recipe every time)")
prop("dungeon/recipe_scroll.glb", 18.0, F + 0.90, 60.6 - 0.007, 180.0, role="loot", tilt=20.0)
chest("chest_copper", 15.4, 59.6, 90.0, "The strongroom chest (always)", True, "big")

# --- 4b. Decor from the catalogue: none yet (the brass decor is step 4). The checks still run on what is there. ---
sys.path.insert(0, str(Path(__file__).resolve().parent))
import decor  # noqa: E402
import junk  # noqa: E402

W = decor.wall


def _d(n):
	return "decor/%s.glb" % n


DECOR = []
_plvl = lambda p: 1 if p["pos"][1] > -3.0 else 2
_flatj = {"dungeon/wall_cracked_stone.glb", "dungeon/floor_loose_flagstone.glb", "dungeon/floor_grooved.glb"}
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

# --- 4c. Junk: a guarded vault, not a ruin: the guards' gear, the clerks' and minters' tools, a few fallen stones
# (tools/dungeons/junk.py; tests/test_dungeon_junk.gd).
GUARDS = ["helmet", "shield_iron", "sword_snapped", "spear_broken", "bones", "torch_dropped", "lantern"]
JUNK_THEMES = {
	"brass_gate": GUARDS + ["rubble_brick", "furn_crate_iron"],
	"bolt_hole": ["bones", "rags", "torch_dropped", "rubble_brick"],
	"toll_hall": GUARDS + ["furn_crate_iron", "stone_stool", "candles", "meal"],
	"counting_room": ["furn_crate_iron", "stone_stool", "candles", "rags", "bones", "furn_drawers"],
	"guard_corridor": ["helmet", "bones", "torch_dropped", "rags"],
	"weighing_hall": GUARDS + ["furn_crate_iron", "crate_stack", "candles", "rubble_brick"],
	"clerks_rooms": ["stone_stool", "furn_table_long", "candles", "rags", "bones", "furn_bookcase", "meal"],
	"clerks_hoard": ["furn_crate_iron", "bones"],
	"inner_door": ["helmet", "bones", "rubble_brick", "torch_dropped"],
	"swing_hall": ["rubble_brick", "bones", "helmet", "shield_iron"],
	"treasury_corridor": ["bones", "rags", "torch_dropped"],
	"vault_hall": GUARDS + ["armour_pile", "axe_head", "furn_crate_iron", "rubble_brick"],
	"strongroom": ["furn_crate_iron", "crate_stack", "candles", "bones"],
	"old_mint": ["crucible_mould", "slag", "tongs_hammer", "scrap", "bones", "rags", "furn_anvil_log"],
	"mint_work": ["slag", "scrap", "tools", "bones"],
	"workers_hall": ["crucible_mould", "slag", "tongs_hammer", "tools", "bedroll_rotten", "cookpot_tipped", "bones", "meal"],
	"coin_chute": ["slag", "scrap", "bones", "rubble_brick"],
	"captains_quarters": GUARDS + ["furn_table_long", "stone_stool", "furn_weapon_stand", "meal"],
	"guard_shrine": ["candles", "urns", "bones", "rags"],
	"shrine_way": ["bones", "rags"],
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
		seed=7013, skip={"entry"}, counts={r: n for r, n in _jcounts.items() if level(r) == l},
	)

	def _ok(j):   # (no junk on a stair or past a room's edge)
		x, z = j["pos"][0], j["pos"][2]
		k = (*junk.cell_of(x, z), l)
		return k in cells and k not in STAIRS and k not in CHUTE
	props += [j for j in _new if _ok(j)]

# --- Write it out. ---
missing = sorted({p["model"] for p in props if not (ROOT / "assets/models" / p["model"]).exists()} |
	{c["model"] for c in creatures if not (ROOT / "assets/models" / c["model"]).exists()} |
	{"build/%s__%s.glb" % (p["id"], p["mat"]) for p in pieces if not (ROOT / ("assets/models/build/%s__%s.glb" % (p["id"], p["mat"]))).exists()})
if missing:
	sys.exit("missing models: %s" % missing)
plan = {"name": "Brassgate Vault", "map": "brassgate", "pieces": pieces, "props": props, "creatures": creatures,
	"chests": chests, "lights": lights, "recipe_stand": RECIPE_STAND}
out = ROOT / "blueprints/dungeons/brassgate_vault.json"
out.write_text(json.dumps(plan, indent=0, separators=(",", ":")), encoding="utf-8")
print("WROTE %s: %d pieces, %d props, %d creatures, %d chests, %d junctions, %d lights, %d ceiling holes" % (out.name,
	len(pieces), len(props), len(creatures), len(chests), len(junctions), len(lights), len(holes)))
