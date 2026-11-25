# The Tomb of Hald Ironbrow (dungeon map 5): every Stonehold stone piece, stair, trap, piece of decor, chest and ghost,
# laid out on the dungeon's rooms (read from src/world/dungeon_map.gd's HALD, so the rock and the pieces always match).
#   python tools/dungeons/make_hald.py   -> blueprints/dungeons/tomb_of_hald_ironbrow.json (the game builds from it)
# Positions are the dungeon's own metres (x right, z toward the cave, y up), like DungeonMap. The plan:
# docs/design/zone1-dungeons/05-tomb-of-hald-ironbrow.md + 2026-11-24-hald-decisions.md (owner, Nov 24, F843: "with
# stone. Again, some were destroyed. Maybe do half of the stone walls and ceilings and things with moss. There should
# be ghosts now. Final boss is a ghost"). Two levels: the mourners' halls at 0 and the deep burial at DEEP = -8, joined
# by two straight stone stairs (each four 2 m steps; the map gives every step its own box so the rock fills under it).
import json, random, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = (ROOT / "src/world/dungeon_map.gd").read_text(encoding="utf-8").split("const HALD")[1].split("\n}\n")[0]
D = -8.0  # DungeonMap.DEEP
SPACES = []
for m in re.findall(r'\["(\w+)",([^\]]*)\]', SRC):
	if '"' in m[1]:
		continue  # (the deadly list, not a space)
	SPACES.append([m[0]] + [float(eval(v, {"DEEP": D})) for v in m[1].split(",")])
SP = {s[0]: s for s in SPACES}
MAT = "cut_stone"
MOUTH_X, MOUTH_Z = 42.0, 70.0
CAVE_Z = MOUTH_Z + 4.0  # the round door at the end of the way in (DungeonMap.FACE)
GAP = 0.5               # DungeonMap.GAP: the rock stands this far behind the wall lines
rng = random.Random(5021)

NOT_ROOMS = {"stair_pit", "chasm"}   # spaces that are no floor cells of their own (you fall into them)
GROUP = {"grand_stair_a": "grand_stair", "grand_stair_b": "grand_stair", "grand_stair_c": "grand_stair",
	"secret_landing": "secret_stair", "secret_stair_a": "secret_stair", "secret_stair_b": "secret_stair",
	"secret_stair_c": "secret_stair", "secret_stair_d": "secret_stair"}
NATURAL = {"grand_stair", "secret_stair", "statue_corridor"}   # rock overhead (no stone ceiling): stairs, falling stones
# The stairs: cell (x, z, level) -> (its bottom, rot). A straight stair piece climbs 2 m over its 2 m cell, from its
# front (+z at rot 0) to its back; rot 1 turns the front to +x, 2 to -z, 3 to -x.
STAIRS = {}
for x in (18, 20):   # the Grand Stair: down from the Wardens' Hall (z 30) to its foot (z 22)
	for i, z in enumerate((28, 26, 24, 22)):
		STAIRS[(x, z, 2)] = (-2.0 - 2.0 * i, 2)
for z in (50, 52):   # the Secret Stair: up from its landing (x 54) to its top (x 62), the way out
	for i, x in enumerate((60, 58, 56, 54)):
		STAIRS[(x, z, 2)] = (-2.0 - 2.0 * i, 3)
for z in (34, 36):   # the Broken Stair: 4 m up to the Honour Chapel; its south half (z 34-36) stands over the spike pit
	STAIRS[(40, z, 1)] = (0.0, 3)
	STAIRS[(42, z, 1)] = (2.0, 3)
# Junctions between a level-1 room and a level-2 one (the stairs' tops): open like any other doorway.
CROSS = {("grand_stair", "wardens_hall"), ("secret_stair", "secret_top")}
NO_PIECES = {(2, 12, 2)}   # the Embalmers' niche: bare rock behind the hidden boulder
DARK = {"entry", "scribe_niche", "ossuary_stash", "embalm_niche", "collapsed_tunnel", "ossuary_door", "embalm_door",
	"chapel_door", "goods_door", "tomb_door", "bronze_door", "grand_stair", "secret_stair", "secret_top", "statue_corridor",
	"exit_way", "broken_stair"}
DOOR_SCALE = 1.5   # the round doorway at 1.5x: a hole about 2 m wide and 2.6 m high
# Half of it fallen in (owner): about half the wall pieces worn or broken off at the top (the rock shows), about half
# the ceilings gone (the dark rock over them), rubble and moss under the holes.
WORN = 0.3        # a wall piece worn and chipped
COLLAPSED = 0.35  # the top row of a wall broken off
NO_CEILING = 0.45 # a ceiling piece fallen


def level(name):
	g = GROUP.get(name, name)
	return 2 if g in ("grand_stair", "secret_stair") or SP[name][5] < -5.0 else 1   # (the spike pit, -3: under level 1)


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
	"shield_brother": "creatures/ghost_c.glb", "hald_shade": "creatures/ghost_a.glb", "hald_ironbrow": "creatures/ghost_c.glb",
	"cave_spider": "monsters/cave_spider_v0.glb"}


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


BRIDGE = {(x, z, 2) for x in range(30, 40, 2) for z in (12, 14)}   # stone slabs over the chasm (the cracked ones: next)
SPECIAL_FLOOR = {(12, 56, 1): "floor_loose_flagstone"}  # the Scribe's Niche: a buried chest under it (stone, not boards: F856)
holes = set()   # the cells whose ceiling fell in
for key, g in cells.items():
	if key in NO_PIECES:
		continue
	x, z, lvl = key
	cx, cz, fy = x + 1.0, z + 1.0, cell_floor[key]
	if key in STAIRS:
		bottom, rot = STAIRS[key]
		piece("stairs", cx, bottom, cz, rot)
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


# The dart walls: the Hall of Candles' north wall at x 28-30 and the Collapsed Tunnel's north wall at x 60-62 (a
# tripwire runs across each). The dart wall model's hole sits 0.12 m along its face from its middle.
DART = {("candle_hall", "n", 56, 29.0), ("collapsed_tunnel", "n", 14, 61.0)}
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
			prop("dungeon/trap_tripwire_wall.glb", x, y, z, yaw, role="trap", label="Dart hole (green stain under it)")
		else:
			wall_piece(x, y, z, rot, yaw, r == rows - 1 and rows >= 2)
	if h % 2:
		piece("half_wall", x, fy + 2.0 * rows, z, rot)
	# A lamp on about every seventh wall of a lit room (the dark places get none: your lantern). (F860, owner Nov 25:
	# "make it darker": was every fourth wall; the game dims Hald's torches too, DungeonMap.HALD torch_energy.)
	n = torch_every.get(g, 0)
	torch_every[g] = n + 1
	if g not in DARK and key not in STAIRS and (g, side, line, along) not in DART and n % 8 == 2:
		ox, oz = {"w": (0.2, 0), "e": (-0.2, 0), "n": (0, 0.2), "s": (0, -0.2)}[side]
		prop("decor/furn_wall_torch_iron.glb", x + ox, fy + 1.2, z + oz, yaw, role="light")
		lights.append([round(x + ox * 3, 2), fy + 2.0, round(z + oz * 3, 2)])

# Junctions: the round doorway (1.5x) in the middle of a 4 m opening, 1 m narrow walls beside it, two high, walls over
# it up to the taller room's ceiling, and (a stair's top) walls under it down to the lower floor. Special ones: the
# cracked wall to the Ossuary stash, the barred way-out gate, the boss room's round door, the locked Bronze door.
SPECIAL_J = {("ossuary", "ossuary_stash"): "cracked", ("exit_way", "mourners_gate"): "gate",
	("halds_tomb", "tomb_door"): "hand_door", ("bronze_door", "halds_tomb"): "bronze",
	("broken_stair", "honour_chapel"): "portcullis", ("honour_chapel", "broken_stair"): "portcullis"}
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
	if kind == "portcullis":   # (the Honour Chapel's ambush, F843: its own stone doorway with the gate hanging raised in it)
		prop("dungeon/portcullis.glb", x, y, z, 90.0 if along_z else 0.0, DOOR_SCALE, role="door", label="Rusted portcullis",
			room="honour_chapel")
	else:
		piece("doorway", x, y, z, rot, DOOR_SCALE)
	if kind == "hand_door":
		prop("dungeon/door_loot.glb", x, y, z, 90.0 if along_z else 0.0, DOOR_SCALE, role="door", label="Round door: E to open", opens="hand")
	if kind == "bronze":   # (DungeonKeys: the Bronze Key opens it; the Shield-Brother holds the key)
		prop("dungeon/door_loot.glb", x, y, z, 90.0 if along_z else 0.0, DOOR_SCALE, role="door", label="Bronze door (locked: the Bronze Key)")
	if kind == "gate":
		prop("dungeon/gate_iron.glb", x, y, z, 90.0 if along_z else 0.0, DOOR_SCALE, role="door", label="Barred gate: the way out")
		# The lever: on the way out's north wall, 1.2 m past the gate, its back on the wall's face.
		prop("dungeon/lever_iron.glb", x + 1.2, y, 56.0 + 0.15, 0.0, role="door", label="Lever: E to open the gate")
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

# --- 4. The rooms, one by one. F = the mourners' halls' floor top, G = the deep burial's. ---
F = 0.25
G = D + 0.25
C = 4.0 + 0.25   # the Honour Chapel's floor top

# 2 Hall of Candles: a thin wire across the hall at ankle height, from the dart hole's sill (north wall) to the south
# wall: step over it or cut it.
prop("dungeon/tripwire.glb", 29.12, 0.24, 58.0, 90.0, role="trap", label="Tripwire (step over it, or cut it)",
	stretch=round(4.0 - 0.3, 2))

# 4 Scribe's Niche: the loose stone hides a buried chest.
chest("chest_small", 13.0, 57.0, 90.0, "Buried chest (under the loose stone)", True, "buried")

# 5 Statue Corridor: loose stones over the way (cracks and dust): shoot them down, or run under them.
for x, z, m in [(19.4, 45.0, "trap_drip_fat"), (20.8, 48.4, "trap_drip_cluster"), (19.6, 51.4, "trap_drip_thin")]:
	prop("dungeon/%s.glb" % m, x, 4.0 + GAP + 0.1, z, rng.choice([0, 120, 240]), role="trap", tilt=180.0, floor=0.0,
		warn=0.35, fall=0.45, label="Loose stones overhead (cracks and dust)" if m == "trap_drip_fat" else "")

# 6 Wardens' Hall: Bearded Shades still on guard.
for x, z, yaw in [(17.0, 33.0, 0.0), (25.0, 38.0, 200.0)]:
	creature("ghost_c", x, z, yaw)

# 7 Ossuary: Drifting Shades waiting in the bone walls. Its cracked north wall (above) hides a stash.
for x, z, yaw in [(31.6, 33.4, 30.0), (36.4, 38.6, 220.0), (36.2, 33.6, 140.0)]:
	creature("ghost_a", x, z, yaw)
chest("chest_small", 34.0, 29.0, 180.0, "Ossuary stash (always)", True, "vault")

# 8 Broken Stair: its south half stands over a spike pit (the collapsing steps come next: for now the pit waits).
for x in (40, 42):
	prop("dungeon/trap_spikes.glb", x + 1.0, -3.0, 35.0, rng.choice([0, 90, 180, 270]), role="trap",
		label="The spike pit (falling in kills)" if x == 40 else "")

# 9 Honour Chapel: the Shield-Brother on guard, the Bronze Key on him; a chest by the altar.
creature("shield_brother", 50.0, 36.0, 270.0, floor=4.0)
chest("chest_small", 52.4, 31.6, 270.0, "Chapel chest", y=C)

# 11 Hall of Names: Wrathful Shades swoop down at you.
for x, z, yaw in [(17.0, 11.0, 30.0), (24.6, 10.4, 300.0), (21.0, 16.4, 180.0)]:
	creature("ghost_b", x, z, yaw, floor=D)

# 12 Embalmers' Room: Drifting Shades; the hidden boulder on its west wall, the spiked chest in the niche behind it.
for x, z, yaw in [(6.4, 16.4, 120.0), (10.6, 11.2, 260.0)]:
	creature("ghost_a", x, z, yaw, floor=D)
prop("cave/boulder_round.glb", 4.4, D, 13.0, 30.0, scale=2.4, role="secret", label="Hidden boulder (hit it)")
prop("dungeon/trap_chest_spikes_stone.glb", 3.0, D, 13.0, 90.0, role="trap", label="Spike holes round the chest")
chest("chest_small", 2.6, 13.0, 90.0, "Embalmers' hoard (always): shoot it first", True, "buried", y=D + 0.24)

# 13 Quiet Chapel: the healing basin.
prop("decor/healing_fountain.glb", 8.0, G + 0.01, 1.6, 0.0, role="heal", label="Healing basin")  # face turned to the room
lights.append([8.0, D + 1.6, 1.6])

# 14 Bridge of Oaths: the chasm under it, 10 m down onto spikes.
for x in range(30, 40, 2):
	for z in (12, 14):
		prop("dungeon/trap_spikes.glb", x + 1.0, D - 10.0, z + 1.0, rng.choice([0, 90, 180, 270]), role="trap",
			label="The chasm (falling in kills)" if (x, z) == (30, 12) else "")

# 19 Grave Goods: a chest the robbers missed.
chest("chest_small", 54.6, 18.6, 270.0, "Grave goods chest", y=G)

# 20 Collapsed Tunnel: a tripwire across it (the dart hole on its north wall), a robber's chest at its end.
prop("dungeon/tripwire.glb", 61.12, D + 0.24, 16.0, 90.0, role="trap", label="Tripwire (step over it, or cut it)",
	stretch=round(4.0 - 0.3, 2))
chest("chest_small", 64.9, 17.0, 270.0, "The robbers' chest (always)", True, "vault", y=G)

# 16 Antechamber: Bearded Shades guard the tomb's door.
for x, z, yaw in [(42.2, 29.6, 0.0), (45.8, 29.6, 0.0)]:
	creature("ghost_c", x, z, yaw, floor=D)

# 17 Hald's Tomb: Hald Ironbrow rises from his tomb.
# (owner, Nov 25: "the boss stands too close to the door, I couldn't come in until I defeated 2 other ones"): he waits
# at the back by his tomb, about 9 m from the door, and his shades in the two back corners, so you walk in first.
creature("hald_ironbrow", 46.0, 44.6, 0.0, floor=D)
# F849 (owner, Nov 25: "too easy"): two weak Tomb Shades rise with him, one on each side.
creature("hald_shade", 42.6, 46.4, 0.0, floor=D)
creature("hald_shade", 50.4, 46.6, 0.0, floor=D)

# Cave Spiders (owner, Nov 25: "add lots of tiny spiders like in the 1st dungeon, but more"): 16 (Mossgate has 7),
# most up in the corners near the ceiling (they drop on you, like Mossgate's Guard Room), a few on the floor.
# Not in Hald's fight, the Shield-Brother's chapel, the pit, the chasm or the tripwire tunnel.
SPIDERS = [  # (x, z, floor, height over the floor)
	(25.0, 57.0, 0.0, 2.9), (34.8, 59.0, 0.0, 0.25),          # 2 Candle Hall
	(16.6, 54.6, 0.0, 3.9), (23.4, 61.4, 0.0, 3.9),           # 3 Offering Room
	(18.6, 43.0, 0.0, 3.4),                                   # 5 Statue Corridor
	(14.6, 41.4, 0.0, 5.0), (27.4, 30.6, 0.0, 5.0), (20.0, 40.0, 0.0, 0.25),  # 6 Wardens' Hall
	(30.6, 39.4, 0.0, 3.9),                                   # 7 Ossuary
	(14.6, 8.6, D, 6.0), (27.4, 19.4, D, 6.0),                # 11 Hall of Names
	(11.4, 17.4, D, 3.9),                                     # 12 Embalmers' Room
	(45.4, 23.0, D, 3.4), (42.6, 13.0, D, 0.25),              # 15 Shield Hall
	(55.4, 12.6, D, 3.9), (49.0, 19.4, D, 0.25),              # 19 Grave Goods
]
for i, (x, z, fl, up) in enumerate(SPIDERS):
	creature("cave_spider", x, z, (i * 97.0) % 360.0, floor=fl, up=up)

# 21 Grave Chamber: the recipe stand, the big chest.
RECIPE_STAND = {"pos": [46.0, G, 54.6], "yaw": 180.0, "page": "scroll_hald", "kind": "recipe_stand_stone"}  # (stone, F856)
prop("dungeon/recipe_stand_stone.glb", 46.0, G, 54.6, 180.0, role="loot", label="Recipe stand (same recipe every time)")
prop("dungeon/recipe_scroll.glb", 46.0, G + 0.90, 54.6 - 0.007, 180.0, role="loot", tilt=20.0)
chest("chest_copper", 43.4, 53.6, 90.0, "Hald's grave chest (always)", True, "big", y=G)

# --- 4b. Decor from the catalogue (docs/art/DECOR-CATALOG.md, "Tomb of Hald Ironbrow"): each piece in its room, off the
# walk lines, clear of doors, chests, traps and lamps (tools/dungeons/decor.py; tests/test_dungeon_decor.gd), each level
# checked on its own (the deep burial lies under the mourners' halls).
sys.path.insert(0, str(Path(__file__).resolve().parent))
import decor  # noqa: E402
import junk  # noqa: E402

W = decor.wall


def _d(n):
	return "decor/%s.glb" % n


DECOR = [
	# 1 Mourners' Gate (x 36-48, z 54-62): banners either side of the way in, the bell in a corner, a bench.
	("th_mourning_banner", "mourners_gate", W(_d("th_mourning_banner"), "s", 62, 38.6)),
	("th_mourning_banner", "mourners_gate", W(_d("th_mourning_banner"), "s", 62, 45.4)),
	("th_mourning_bell", "mourners_gate", decor.corner(_d("th_mourning_bell"), "n", 54, "w", 36)),
	("th_mourning_bench", "mourners_gate", W(_d("th_mourning_bench"), "n", 54, 43.0)),
	# 2 Hall of Candles (x 24-36, z 56-60): candle niches down both walls.
	("th_niche_candles", "candle_hall", W(_d("th_niche_candles"), "s", 60, 26.6)),
	("th_niche_candles", "candle_hall", W(_d("th_niche_candles"), "s", 60, 32.6)),
	("th_niche_candles", "candle_hall", W(_d("th_niche_candles"), "n", 56, 33.4)),
	# 3 Offering Room (x 16-24, z 54-62)
	("th_niche_coins", "offering_room", W(_d("th_niche_coins"), "s", 62, 18.6)),
	("th_niche_looted", "offering_room", W(_d("th_niche_looted"), "s", 62, 21.4)),
	("th_offering_table", "offering_room", decor.corner(_d("th_offering_table"), "n", 54, "e", 24)),
	# 6 Wardens' Hall (x 14-28, z 30-42): a fallen pillar, a toppled brazier, a guard statue.
	("th_pillar_fallen", "wardens_hall", W(_d("th_pillar_fallen"), "w", 14, 37.4)),
	("th_brazier_toppled", "wardens_hall", decor.mid(_d("th_brazier_toppled"), 16.6, 40.6, 30.0)),
	("th_honour_guard", "wardens_hall", W(_d("th_honour_guard"), "e", 28, 32.4)),
	# 7 Ossuary (x 30-38, z 32-40)
	("th_urn_shelf", "ossuary", W(_d("th_urn_shelf"), "s", 40, 33.4)),
	("bone_pile", "ossuary", decor.corner(_d("bone_pile"), "s", 40, "e", 38)),
	# 9 Honour Chapel (x 44-52, z 32-40, 4 m up): a guard on each side wall (the stair top is too near the door wall), the altar.
	("th_honour_guard", "honour_chapel", W(_d("th_honour_guard"), "s", 42, 46.4)),
	("th_honour_guard", "honour_chapel", W(_d("th_honour_guard"), "n", 30, 46.4)),
	("altar_candles", "honour_chapel", W(_d("altar_candles"), "e", 54, 36.0)),
	# 11 Hall of Names (x 14-28, z 8-20, deep): the two carved panels on the north wall, name plaques, a sealed door.
	("th_relief_battle", "names_hall", W(_d("th_relief_battle"), "n", 8, 19.0)),
	("th_relief_forge", "names_hall", W(_d("th_relief_forge"), "n", 8, 21.0)),
	("th_sealed_door", "names_hall", W(_d("th_sealed_door"), "n", 8, 25.4)),
	("th_name_plaque", "names_hall", W(_d("th_name_plaque"), "s", 20, 16.0)),
	("th_name_plaque", "names_hall", W(_d("th_name_plaque"), "s", 20, 24.6)),
	("th_mourning_banner", "names_hall", W(_d("th_mourning_banner"), "w", 14, 18.4)),
	# 12 Embalmers' Room (x 4-12, z 10-18)
	("th_urn_shelf", "embalmers", W(_d("th_urn_shelf"), "s", 18, 6.0)),
	# 13 Quiet Chapel (x 4-12, z 0-8): urns either side of the healing basin, a bench.
	("th_ash_urn", "quiet_chapel", W(_d("th_ash_urn"), "n", 0, 6.0)),
	("th_ash_urn", "quiet_chapel", W(_d("th_ash_urn"), "n", 0, 10.0)),
	("th_mourning_bench", "quiet_chapel", W(_d("th_mourning_bench"), "e", 12, 4.0)),
	# 15 Shield Hall (x 42-46, z 12-24): too narrow for the shield slabs (the walk line); its junk is the guards' shields.
	# 19 Grave Goods (x 48-56, z 12-20)
	("th_chest_looted", "grave_goods", decor.mid(_d("th_chest_looted"), 51.0, 18.7, 0.0)),
	("th_drinking_horn", "grave_goods", W(_d("th_drinking_horn"), "n", 12, 52.0)),
	# 20 Collapsed Tunnel: the robber pinned under the fallen lintel, near its rubble end.
	("th_robber_pinned", "collapsed_tunnel", W(_d("th_robber_pinned"), "n", 14, 64.4)),
	# 16 Antechamber (x 40-48, z 24-32)
	("th_weapon_rack", "antechamber", W(_d("th_weapon_rack"), "w", 40, 29.4)),
	("th_honour_guard", "antechamber", W(_d("th_honour_guard"), "e", 48, 27.4)),
	# 17 Hald's Tomb (x 40-52, z 36-48): his tomb chest off to the east (the fight needs the middle), braziers at its
	# ends, the helm on its plinth, a banner.
	("th_hald_tomb", "halds_tomb", decor.mid(_d("th_hald_tomb"), 49.0, 42.0, 90.0)),
	("th_brazier_grand", "halds_tomb", decor.mid(_d("th_brazier_grand"), 49.0, 39.4, 0.0)),
	("th_brazier_grand", "halds_tomb", decor.mid(_d("th_brazier_grand"), 49.0, 44.6, 0.0)),
	("th_brow_helm_plinth", "halds_tomb", W(_d("th_brow_helm_plinth"), "e", 52, 42.0)),
	("th_mourning_banner", "halds_tomb", W(_d("th_mourning_banner"), "w", 40, 42.0)),
	# 21 Grave Chamber (x 42-50, z 50-56): his armour and his hammer.
	("th_armour_stand", "grave_chamber", W(_d("th_armour_stand"), "s", 56, 48.6)),
	("th_hammer_rest", "grave_chamber", W(_d("th_hammer_rest"), "w", 42, 51.4)),
]
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
	return dw + [_dxz(p) for p in props if p["model"] in ("dungeon/entrance_stone.glb", "dungeon/wall_cracked_stone.glb") and _plvl(p) == l]


def _things(l):
	t = [_dxz(c) for c in chests if _plvl(c) == l] + [_dxz(p) for p in props if "lever" in p["model"] and _plvl(p) == l]
	return t + ([(RECIPE_STAND["pos"][0], RECIPE_STAND["pos"][2])] if l == 2 else [])


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

# --- 4c. Junk: the robbers' and the years' mess (tools/dungeons/junk.py; tests/test_dungeon_junk.gd), about 1.8
# things per 10 m2 counting the decor: fallen stone under the broken ceilings, the guards' broken gear, pots, bones.
JUNK_THEMES = {
	"mourners_gate": ["candles", "urn_broken", "rags", "rubble_brick", "bones", "lantern", "statue_head"],
	"candle_hall": ["candles", "urn_broken", "rubble_brick", "bones", "rags"],
	"offering_room": ["urn_broken", "urns", "candles", "rubble_brick", "bones", "meal", "tools"],
	"scribe_niche": ["rags", "candles", "bones"],
	"statue_corridor": ["rubble_brick", "statue_head", "bones", "urn_broken"],
	"wardens_hall": ["helmet", "shield_iron", "sword_snapped", "armour_pile", "bones", "rubble_brick", "spear_broken",
		"statue_head", "axe_head", "rags", "torch_dropped"],
	"ossuary": ["bones", "urn_broken", "urns", "coffin_piece", "rubble_brick", "candles"],
	"ossuary_stash": ["bones", "urns"],
	"honour_chapel": ["candles", "shield_iron", "helmet", "bones", "rubble_brick"],
	"names_hall": ["rubble_brick", "statue_head", "candles", "urn_broken", "bones", "rags", "coffin_lid", "helmet",
		"torch_dropped"],
	"embalmers": ["urns", "urn_broken", "rags", "coffin_piece", "tools", "candles", "bones"],
	"quiet_chapel": ["candles", "urns", "rags", "bones"],
	"shield_hall": ["shield_iron", "helmet", "sword_snapped", "bones", "rubble_brick"],
	"grave_goods": ["urn_broken", "urns", "coffin_piece", "tools", "bones", "rags", "scrap"],
	"collapsed_tunnel": ["rubble_brick", "tools", "lantern", "bones", "rags"],
	"antechamber": ["helmet", "shield_iron", "sword_snapped", "bones", "rubble_brick", "candles"],
	"halds_tomb": ["coffin_lid", "urn_broken", "candles", "bones", "rubble_brick"],
	"grave_chamber": ["urns", "candles", "bones", "urn_broken"],
	"exit_way": ["rubble_brick", "bones", "rags", "torch_dropped"],
	"secret_top": ["rubble_brick", "bones"],
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
		_spaces_l[l], _group, _cells_l[l], lambda g, l=l: SP[g][5] if g in SP else (0.0 if l == 1 else D), {r for r in JUNK_THEMES if level(r) == l}, JUNK_THEMES,  # (the stairs get none)
		doors=_doors(l), path_doors=_doorways(l), things=_things(l), traps=_traps(l),
		furniture=[(p["pos"][0], p["pos"][2], max(junk.size(p["model"])[:2]) / 2) for p in props
			if p["role"] in ("decor", "light", "heal") and p["model"] not in _flatj and _plvl(p) == l],
		seed=5013, skip={"entry"}, counts={r: n for r, n in _jcounts.items() if level(r) == l},
	)

	def _ok(j):   # (no junk on a stair, past a room's edge, or within 0.8 m of the spike pit or the chasm)
		x, z = j["pos"][0], j["pos"][2]
		if (*junk.cell_of(x, z), l) not in cells or (*junk.cell_of(x, z), l) in STAIRS:
			return False
		return not any(SP[n][1] - 0.8 < x < SP[n][3] + 0.8 and SP[n][2] - 0.8 < z < SP[n][4] + 0.8 and level(n) == l
			for n in NOT_ROOMS)
	props += [j for j in _new if _ok(j)]  # (a group with no space of its own, F860's fewer torches: its level's floor, then _ok drops stair ones)

# --- Write it out. ---
missing =sorted({p["model"] for p in props if not (ROOT / "assets/models" / p["model"]).exists()} |
	{c["model"] for c in creatures if not (ROOT / "assets/models" / c["model"]).exists()} |
	{"build/%s__%s.glb" % (p["id"], p["mat"]) for p in pieces if not (ROOT / ("assets/models/build/%s__%s.glb" % (p["id"], p["mat"]))).exists()})
if missing:
	sys.exit("missing models: %s" % missing)
plan = {"name": "Tomb of Hald Ironbrow", "map": "hald", "pieces": pieces, "props": props, "creatures": creatures,
	"chests": chests, "lights": lights, "recipe_stand": RECIPE_STAND}
out = ROOT / "blueprints/dungeons/tomb_of_hald_ironbrow.json"
out.write_text(json.dumps(plan, indent=0, separators=(",", ":")), encoding="utf-8")
print("WROTE %s: %d pieces, %d props, %d creatures, %d chests, %d junctions, %d lights, %d ceiling holes" % (out.name,
	len(pieces), len(props), len(creatures), len(chests), len(junctions), len(lights), len(holes)))
