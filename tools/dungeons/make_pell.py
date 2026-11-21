# Old Pell's Diggings (dungeon map 3): every root wood piece, ladder, trap, piece of furniture, chest and creature, laid
# out on the dungeon's rooms (read from src/world/dungeon_map.gd's PELL, so the rock and the pieces always match).
#   python tools/dungeons/make_pell.py   -> blueprints/dungeons/old_pells_diggings.json (the game builds from it)
# Positions are the dungeon's own metres (x right, z toward the cave, y up), like DungeonMap. The plan:
# docs/design/zone1-dungeons/03-old-pell-s-diggings.md. Owner, Nov 20: no 3D page, "start working on dung 3", the
# Foreman again as its boss. Two levels: the hut at 0 (the cave's level) and the diggings at DOWN = -6 m, joined by two
# 2 x 2 m shafts with a root wood ladder in each: "shaft" (down from the Winch Shed) and "lift" (the way out, up from
# Pell's Last Dig to behind the hut's barred gate; it becomes a rope lift later).
import json, random, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = (ROOT / "src/world/dungeon_map.gd").read_text(encoding="utf-8").split("const PELL")[1].split("\n}\n")[0]
D = -6.0  # DungeonMap.DOWN
SPACES = []
for m in re.findall(r'\["(\w+)",([^\]]*)\]', SRC):
	SPACES.append([m[0]] + [float(eval(v, {"DOWN": D})) for v in m[1].split(",")])
SP = {s[0]: s for s in SPACES}
MAT = "plank_root"
MOUTH_X, MOUTH_Z = 36.0, 60.0
CAVE_Z = MOUTH_Z + 4.0  # the round door at the end of the way in (DungeonMap.FACE)
rng = random.Random(3011)

HOLES = {"shaft": (24, 44), "lift": (44, 46)}   # the 2 m cell of each shaft (no floor above, no ceiling below)
NOT_ROOMS = {"shaft", "lift", "spike_pit"}      # spaces that are no floor cells of their own
GROUP = {"cave_squeeze": "cave_in", "cave_in_s": "cave_in"}  # spaces that are one room (no walls between them)
NATURAL = {"cave_in", "den", "seam"}           # rock overhead (no root wood ceiling)
TALL = {s[0] for s in SPACES if s[6] >= 4.5}   # two rows of walls (the rest: a wall + a half wall)
NO_PIECES = {(32, 38, 2), (32, 40, 2)}         # the niche: bare rock behind the hidden boulder
DARK = {"pantry", "niche", "den", "seam", "entry", "shed_door", "gallery_door", "shrine_door", "dig_door"}  # no torch
OLD = 0.7          # about 70% of the floors and walls old and rotten (like Mossgate and Lampwick)
DOOR_SCALE = 1.5   # the round doorway at 1.5x: a hole about 2 m wide and 2.6 m high


def level(name):
	return 1 if SP[name][5] >= 0 else 2


def floor_y(lvl):
	return 0.0 if lvl == 1 else D


def height(g):
	return 4 if g in TALL else 3


def in_box(name, x, z):
	s = SP[name]
	return s[1] <= x < s[3] and s[2] <= z < s[4]


pieces, props, creatures, chests, lights = [], [], [], [], []


def r3(v):
	return [round(float(c), 3) for c in v]


def piece(pid, x, y, z, rot, scale=1.0):
	pieces.append({"id": pid, "mat": MAT, "pos": r3((x, y, z)), "rot": rot, **({"scale": scale} if scale != 1.0 else {})})


def prop(model, x, y, z, yaw=0.0, scale=1.0, role="decor", label="", tilt=0.0, **extra):
	props.append({"model": model, "pos": r3((x, y, z)), "yaw": round(yaw, 1), "scale": scale, "role": role, "label": label,
		**({"tilt": tilt} if tilt else {}), **extra})


CREATURE_MODEL = {"tunnel_rat": "creatures/tunnel_rat_rust.glb", "lost_miner": "creatures/lost_miner_frost.glb",
	"foreman": "creatures/foreman.glb"}


def creature(kind, x, z, yaw=0.0, floor=D, wake=None):
	creatures.append({"kind": kind, "model": CREATURE_MODEL[kind], "pos": r3((x, floor + 0.25, z)), "yaw": yaw, "scale": 1.0,
		"floor": floor, **({"wake": wake} if wake else {})})


def chest(kind, x, z, yaw, label, sure=False, loot="random", y=D + 0.25):
	"""A chest (the game makes it a real chest with loot: DungeonBuild.LOOT[loot]). Not `sure`: there in about 2 of 3 worlds."""
	chests.append({"kind": kind, "pos": r3((x, y, z)), "yaw": yaw, "label": label, "always": sure, "loot": loot})


# --- 1. The cells (x, z, level): floors (root wood boards, some old), root wood ceilings in rooms and corridors. ---
cells = {}
for s in SPACES:
	if s[0] in NOT_ROOMS:
		continue
	for x in range(int(s[1]), int(s[3]), 2):
		for z in range(int(s[2]), int(s[4]), 2):
			cells.setdefault((x, z, level(s[0])), GROUP.get(s[0], s[0]))
for z in range(int(MOUTH_Z), int(CAVE_Z), 2):  # the way in runs on through the rock to the round door
	for x in (MOUTH_X - 2, MOUTH_X):
		cells[(int(x), z, 1)] = "entry"

PIT = {(x, z, 2) for x in (34, 36) for z in (22, 24, 26)}   # the Rotten Gallery's boards over the spike pit
SPECIAL_FLOOR = {(10, 24, 2): "floor_loose_stone"}          # the Den's loose stone (a buried chest under it)
GROOVED = {(38, 30, 2), (40, 30, 2)}                         # the Deep Seam's floor under the crushers
for (x, z, lvl), g in cells.items():
	if (x, z, lvl) in NO_PIECES:
		continue
	cx, cz, fy = x + 1.0, z + 1.0, floor_y(lvl)
	hole_top = lvl == 1 and (x, z) in HOLES.values()   # the shaft's mouth: no floor
	hole_bottom = lvl == 2 and (x, z) in HOLES.values()  # the shaft's foot: no ceiling
	if hole_top:
		pass
	elif (x, z, lvl) in PIT:
		prop("dungeon/trap_floor_break.glb", cx, fy, cz, rng.choice([0, 90, 180, 270]), role="trap",
			label="Rotten boards (the spike pit under them)" if (x, z) == (34, 24) else "")
	elif (x, z, lvl) in GROOVED:
		prop("dungeon/floor_grooved.glb", cx, fy, cz, 90.0, role="trap", label="Grooves (the crushers land here)" if x == 38 else "")
	elif (x, z, lvl) in SPECIAL_FLOOR:
		prop("dungeon/%s.glb" % SPECIAL_FLOOR[(x, z, lvl)], cx, fy, cz, 0.0, role="secret", label="Loose stone")
	elif rng.random() < OLD:
		prop("dungeon/floor_old.glb", cx, fy, cz, rng.choice([0, 90, 180, 270]))
	else:
		piece("floor", cx, fy, cz, 0)
	if g in NATURAL or hole_bottom:
		continue
	top = fy + float(height(g))
	if rng.random() < OLD:  # old boards upside down: their worn, gappy side faces down at you
		prop("dungeon/floor_old.glb", cx, top + 0.24, cz, rng.choice([0, 90, 180, 270]), tilt=180.0)
	else:
		piece("floor", cx, top, cz, 0)

# --- 2. Walls round every room (rock behind them) and doorways where two spaces meet (each level on its own). ---
DIRS = [((-2, 0), "w"), ((2, 0), "e"), ((0, -2), "n"), ((0, 2), "s")]
INWARD_YAW = {"w": 90.0, "e": 270.0, "n": 0.0, "s": 180.0}  # a wall model's front (+z) turned to face into the room
junctions = {}
rock_edges = []
for (x, z, lvl), g in cells.items():
	if (x, z, lvl) in NO_PIECES:
		continue
	for (dx, dz), side in DIRS:
		other = cells.get((x + dx, z + dz, lvl))
		if side in "we":
			line, along, rot = (x if side == "w" else x + 2), z + 1.0, 1
		else:
			line, along, rot = (z if side == "n" else z + 2), x + 1.0, 0
		if other == g:
			continue
		if other is None:
			if g == "entry" and side == "s":
				continue  # the cave
			rock_edges.append((g, side, line, along, rot, lvl))
		elif (x + dx, z + dz, lvl) not in NO_PIECES:
			key = (min(g, other), max(g, other), side in "we", line, lvl)
			junctions.setdefault(key, set()).add(along)


def wall_pos(rot, line, along):
	return (line, along) if rot == 1 else (along, line)


# The dart walls: the Winch Shed's north wall at x 28-30 (its tripwire runs across the shed), the Sorting Room's north
# wall at x 24-26 (its floor plate). The dart wall model's hole sits 0.12 m along its face from its middle.
DART = {("winch_shed", "n", 44, 29.0), ("sorting", "n", 22, 25.0)}
# The spear walls: both sides of the Cave-in Tunnel's 2 m squeeze (x 24-26, z 32-36); the z 35 pair stabs a moment
# after the z 33 pair. The push walls: the Rotten Gallery's north wall over the spike pit (x 34-38): the strip along
# that wall looks like the safe way round the rotten boards, and the blocks shove you off it onto them.
SPEARS = {("cave_in", "w", 24, 33.0): 0.0, ("cave_in", "e", 26, 33.0): 0.0,
	("cave_in", "w", 24, 35.0): 0.25, ("cave_in", "e", 26, 35.0): 0.25}
PUSH = {("gallery", "n", 20, 35.0), ("gallery", "n", 20, 37.0)}
torch_every = {}
for g, side, line, along, rot, lvl in rock_edges:
	x, z = wall_pos(rot, line, along)
	yaw = INWARD_YAW[side]
	fy = floor_y(lvl)
	for r in range(2):
		y = fy + 2.0 * r
		if r == 1 and height(g) == 3:
			piece("half_wall", x, y, z, rot)
		elif r == 0 and (g, side, line, along) in DART:
			prop("dungeon/trap_tripwire_wall.glb", x, y, z, yaw, role="trap", label="Dart hole (green stain under it)")
		elif r == 0 and (g, side, line, along) in SPEARS:
			prop("dungeon/trap_spear_wall.glb", x, y, z, yaw, role="trap", label="Rows of holes (a stake tip shows)",
				phase=SPEARS[(g, side, line, along)])
		elif r == 0 and (g, side, line, along) in PUSH:
			prop("dungeon/trap_push_wall.glb", x, y, z, yaw, role="trap", label="A gap round a block in the wall")
			# (owner, Nov 20: no scrape marks on the floor: nothing tells you it will push you)
		elif rng.random() < OLD:
			prop("dungeon/wall_old.glb", x, y, z, yaw)
		else:
			piece("wall", x, y, z, rot)
	# A torch on about every third wall of a room, every fifth of a corridor (the dark places get none: your lantern).
	n = torch_every.get(g, 0)
	torch_every[g] = n + 1
	if g not in DARK and (g, side, line, along) not in DART | set(SPEARS) | PUSH and n % (3 if g in TALL else 5) == 1:
		ox, oz = {"w": (0.2, 0), "e": (-0.2, 0), "n": (0, 0.2), "s": (0, -0.2)}[side]
		prop("decor/furn_wall_torch_iron.glb", x + ox, fy + 1.2, z + oz, yaw, role="light")
		lights.append([round(x + ox * 3, 2), fy + 2.0, round(z + oz * 3, 2)])

# The two shafts: root wood walls line them between the levels (from the lower room's 4 m ceiling up to the upper
# floor), a ladder on one wall all the way (and 2 m on up out of the hole, to step off), a railing on one open side.
for name, (hx, hz) in HOLES.items():
	for side in "wens":
		if side in "we":
			piece("wall", hx + (0 if side == "w" else 2), D + 4.0, hz + 1.0, 1)
		else:
			piece("wall", hx + 1.0, D + 4.0, hz + (0 if side == "n" else 2), 0)
# Shaft: the ladder on its west wall, near its south side (you step onto it from the Winch Shed's floor south of the
# hole); the railing on the east side. Lift: the ladder on its east wall, near its south side; the railing on the west.
LADDERS = {"shaft": (24.2, 45.55)}  # (the lift shaft has the rope lift)
for name, (lx, lz) in LADDERS.items():
	for k in range(4):
		piece("ladder", lx, D + 0.24 + 2.0 * k, lz, 1)
piece("railing", 26.0, 0.24, 45.0, 1)
piece("railing", 44.0, 0.24, 47.0, 1)

# Junctions: the round doorway (1.5x) in the middle of a 4 m opening, 1 m narrow walls beside it, two high, a half
# wall over it up to a taller room's ceiling. Special ones: the cracked wall to the pantry, the barred way-out gate,
# the round door into the Last Dig (you open it: you can't see the boss from outside, like Lampwick's office).
SPECIAL_J = {("pantry", "winch_shed"): "cracked", ("lift_top", "pells_hut"): "gate", ("dig", "dig_door"): "hand_door"}
for (a, b, along_z, line, lvl), spots in junctions.items():
	spots = sorted(spots)
	y = floor_y(lvl)
	lo, hi = spots[0] - 1.0, spots[-1] + 1.0
	mid = (lo + hi) / 2.0
	rot = 1 if along_z else 0
	kind = SPECIAL_J.get((a, b), "")

	def p(al):
		return wall_pos(rot, line, al)
	if kind == "cracked":
		x, z = p(mid)
		prop("dungeon/wall_cracked.glb", x, y, z, 90.0 if along_z else 0.0, role="secret", label="Cracked wall (hollow sound)",
			floor=y)
		for al in spots:
			x, z = p(al)
			piece("wall", x, y + 2.0, z, rot)
		continue
	if hi - lo != 4.0:
		sys.exit("junction %s/%s is %.0f m wide (doorways need 4 m)" % (a, b, hi - lo))
	x, z = p(mid)
	piece("doorway", x, y, z, rot, DOOR_SCALE)
	if kind == "hand_door":
		prop("dungeon/door_loot.glb", x, y, z, 90.0 if along_z else 0.0, DOOR_SCALE, role="door", label="Round door: E to open", opens="hand")
	if kind == "gate":
		prop("dungeon/gate_round.glb", x, y, z, 90.0 if along_z else 0.0, DOOR_SCALE, role="door", label="Barred gate: the way out")
		# The lever: on the lift top's north wall, 1.2 m past the gate, its back on the boards' face.
		prop("dungeon/lever.glb", x + 1.2, y, 46.0 + 0.15, 0.0, role="door", label="Lever: E to open the gate")
	for edge in (lo + 0.5, hi - 0.5):
		x, z = p(edge)
		piece("wall_narrow", x, y, z, rot)
		piece("wall_narrow", x, y + 2.0, z, rot)
	if max(height(a), height(b)) > 3:
		x, z = p(mid)
		piece("half_wall", x, y + 3.0, z, rot)

# --- 3. The way in: the round stone door where the tunnel meets the cave. ---
prop("dungeon/dungeon_entrance.glb", MOUTH_X, 0.0, CAVE_Z, 0.0, role="door", label="The way in: round stone door")
for x in (MOUTH_X - 1.5, MOUTH_X + 1.5):
	piece("wall_narrow", x, 0.0, CAVE_Z, 0)
for x in (MOUTH_X - 1.0, MOUTH_X + 1.0):
	piece("half_wall", x, 2.0, CAVE_Z, 0)

# --- 4. The rooms, one by one (the plan's 13 spaces). F = the hut's floor top, G = the diggings' floor top. ---
F = 0.25
G = D + 0.25

# 1 Pell's Hut: his bed, table and stools, a shelf, a keg, a chest. The barred gate on the east wall (above).
prop("decor/shack_bed.glb", 38.6, F, 45.6, 90.0)
prop("decor/shack_table.glb", 35.8, F, 46.0, 0.0)  # (by the north wall: the way from the shed to the gate stays open)
prop("decor/shack_stool.glb", 35.8, F, 47.1, 0.0)
prop("decor/shack_shelf.glb", 34.5, F, 44.45, 0.0)
prop("decor/keg.glb", 32.8, F, 51.2, 0.0)
prop("decor/firewood_rack.glb", 39.4, F, 51.0, 270.0)
chest("chest_small", 39.2, 49.4, 270.0, "Random chest", y=F)

# 2 Winch Shed: a thin wire across the shed at ankle height, from the dart hole's sill (north wall) to the south wall:
# step over it or cut it. The shaft's mouth in the north-west corner (the ladder down).
prop("dungeon/tripwire.glb", 29.12, 0.24, 47.0, 90.0, role="trap", label="Tripwire (step over it, or cut it)",
	stretch=round(6.0 - 0.3, 2))
prop("decor/grain_sacks.glb", 26.8, F, 49.2, 15.0)
prop("decor/crate_stack.glb", 28.6, F, 49.1, 80.0)
prop("dungeon/rail_wedge.glb", 27.2, 0.24, 45.0, 120.0)  # (bits of old gear)

# 3 Pantry (behind the cracked wall): shelves of old jars, Pell's stash.
prop("decor/furn_shelf_bottles.glb", 22.0, F, 48.45, 0.0)
prop("decor/shack_shelf.glb", 20.45, F, 50.4, 90.0)
chest("chest_small", 22.6, 51.0, 180.0, "Pell's stash (always)", True, "vault", y=F)

# 5 Ladder Landing: the shaft's foot; Tunnel Rats.
prop("decor/crate_stack.glb", 29.0, G, 40.9, 30.0)
for i, (x, z) in enumerate([(27.0, 42.0), (28.6, 44.2), (26.0, 41.0)]):
	creature("tunnel_rat", x, z, 180.0 + i * 50.0)

# 6 Cave-in Tunnel: half fallen in: 4 m wide at its ends, a 2 m squeeze in the middle with a spear wall on each side
# (above). Old props hold up what's left; rubble and a snapped beam at its ends.
piece("mine_prop", 24.33, D, 38.6, 1)
piece("mine_prop", 27.67, D, 37.0, 1)
prop("dungeon/junk_beam_snapped.glb", 27.1, G, 31.0, 75.0)
prop("dungeon/junk_rubble_wood.glb", 24.8, G, 38.9, 0.0)
prop("dungeon/rubble_ore.glb", 27.0, G, 39.0, 30.0)

# 7 Sorting Room: old ore tables, a chest, Lost Miners still sorting ore. A cracked plate fires a dart from the north
# wall; bear jaws hide in the dust. Shoot the plate (or hit it with a long tool) to use it up.
prop("decor/furn_work_table.glb", 28.6, G, 23.4, 270.0)
prop("decor/shack_table.glb", 23.4, G, 23.2, 90.0)
prop("dungeon/rubble_ore.glb", 29.0, G, 28.8, 0.0)
prop("dungeon/trap_dart_plate.glb", 25.12, G - 0.01, 25.6, 0.0, role="trap", label="Cracked floor plate", fires=True)
prop("dungeon/trap_bear_jaws.glb", 27.6, D + 0.24, 26.4, 40.0, role="trap", label="Bear jaws (a rusty glint in the dust)")
prop("dungeon/trap_bear_jaws.glb", 23.4, D + 0.24, 27.2, 160.0, role="trap")
chest("chest_small", 29.2, 25.0, 270.0, "Random chest")
for x, z in [(26.0, 23.2), (28.2, 27.0)]:
	creature("lost_miner", x, z, 0.0)

# 8 Spoil Tunnel: where they dumped the rubble.
prop("dungeon/rubble_ore.glb", 16.0, G, 24.9, 0.0)
prop("dungeon/junk_rubble_wood_b.glb", 19.4, G, 27.1, 40.0)
prop("dungeon/junk_pickaxe_broken.glb", 15.2, G, 27.0, 200.0)

# 9 Spider Den (the rats' nest): dark, a Tunnel Rat pack; a loose stone hides a buried chest.
chest("chest_small", 11.0, 25.0, 90.0, "Buried chest (under the loose stone)", True, "buried")
prop("dungeon/junk_bones.glb", 12.6, G, 23.0, 30.0)
prop("dungeon/junk_rags.glb", 8.9, G, 27.0, 0.0)
for i, (x, z) in enumerate([(9.4, 23.4), (12.4, 26.4), (13.0, 23.8), (9.2, 26.8), (11.6, 22.8)]):
	creature("tunnel_rat", x, z, i * 70.0)

# 10 Rotten Gallery: rotten boards over a 4 m spike pit, right where you'd walk; the safe way runs along its north
# wall (the shoving wall comes next). Old props along the walls.
for x in range(34, 38, 2):
	for z in range(22, 28, 2):
		prop("dungeon/trap_spikes.glb", x + 1.0, D - 4.0, z + 1.0, rng.choice([0, 90, 180, 270]), role="trap",
			label="The spike pit (falling in kills)" if (x, z) == (34, 22) else "")
for x in (33.0, 39.0):
	piece("mine_prop", x, D, 20.33, 0)
prop("dungeon/junk_bones.glb", 40.6, G, 26.8, 120.0)

# 11 Deep Seam: two crushers side by side across the seam (one is always up: watch them and run under the one that
# rises). Grooves under them. Rock overhead: they hang from beams up in the dark.
for i, x in enumerate((39.0, 41.0)):
	prop("dungeon/trap_crusher.glb", x, D + 1.25, 31.0, 0.0, role="trap", floor=D,
		label="Crushers (watch their rhythm)" if i == 0 else "")

# 12 Miner's Shrine: the healing basin in a ring of rubble, a bench; the hidden boulder on its south side, a chest
# in the niche behind it.
prop("dungeon/rubble_ore.glb", 33.0, G, 34.6, 0.0)
prop("decor/mushroom_fountain.glb", 33.0, G + 0.01, 34.6, 0.0, role="heal", label="Healing basin")
lights.append([33.0, D + 1.6, 34.6])
prop("decor/shack_bench.glb", 30.9, G, 35.0, 90.0)
prop("cave/boulder_round.glb", 33.0, D, 39.4, 30.0, scale=2.6, role="secret", label="Hidden boulder (hit it)")
chest("chest_small", 33.0, 41.2, 180.0, "Niche chest (always)", True, "buried", y=D)

# 13 Pell's Last Dig: the Foreman and his Lost Miners, the recipe stand, the big chest; the lift shaft (east) up to
# behind the hut's gate.
creature("foreman", 42.0, 50.0, 180.0)
for x, z in [(39.0, 46.0), (47.0, 47.5), (40.5, 53.0)]:
	creature("lost_miner", x, z, 180.0)
RECIPE_STAND = {"pos": [36.8, G, 45.0], "yaw": 90.0, "page": "scroll_pell"}
prop("dungeon/recipe_stand.glb", 36.8, G, 45.0, 90.0, role="loot", label="Recipe stand (same recipe every time)")
prop("dungeon/recipe_scroll.glb", 36.8 + 0.007, G + 0.90, 45.0, 90.0, role="loot", tilt=20.0)
chest("chest_copper", 36.8, 48.6, 90.0, "The Foreman's chest (always)", True, "big")
prop("decor/shack_table.glb", 48.4, G, 54.2, 0.0)
prop("dungeon/rubble_ore.glb", 47.6, G, 43.0, 0.0)
prop("decor/crate_stack.glb", 37.2, G, 55.0, 30.0)
prop("dungeon/junk_pickaxe_broken.glb", 37.4, G, 41.0, 60.0)
prop("treasure/tr_coins_wide.glb", 37.6, G, 47.2, 20.0)

# The rope lift: the platform waits down in the Last Dig (E on it: up or down); the winch over the shaft's top and a
# lever on the Last Dig's east wall call it.
prop("dungeon/lift_platform.glb", 45.0, D + 0.04, 47.0, 0.0, role="trap", label="Rope lift: E to ride it", travel=[D + 0.04, 0.04])
prop("dungeon/lift_winch.glb", 45.0, 0.24, 47.0, 0.0, role="trap", label="Winch: E to call the lift", calls="lift")
prop("dungeon/lever.glb", 45.0, D, 40.0 + 0.15, 0.0, role="trap", label="Lever: E to call the lift", calls="lift")

# Behind the gate (the lift's top): crates.
prop("decor/crate_stack.glb", 41.0, F, 49.1, 10.0)

# --- 4b. Decor from the decor catalogue (docs/art/DECOR-CATALOG.md, Nov 22): every piece in its own room and spot, off
# the walk lines, clear of doors, chests, traps and the wall torches (tools/dungeons/decor.py; tests/test_dungeon_decor.gd).
# Pell has two levels that overlap seen from above (the hut over the Last Dig), so each level is checked on its own.
# The rule clashes are fine now (owner, Nov 22: the rules are fluid): every op_ piece in the catalogue is placed.
import decor  # noqa: E402
import junk  # noqa: E402

HUNG = -0.03
W = decor.wall


def _d(n):
	return "decor/%s.glb" % n


# Old plain furniture that made way for the catalogue's own pieces.
GONE = {("decor/shack_bed.glb", 38.6, 45.6), ("decor/keg.glb", 32.8, 51.2), ("decor/firewood_rack.glb", 39.4, 51.0),
	("decor/grain_sacks.glb", 26.8, 49.2), ("decor/shack_table.glb", 23.4, 23.2), ("decor/shack_table.glb", 35.8, 46.0), ("decor/shack_stool.glb", 35.8, 47.1), ("decor/shack_table.glb", 48.4, 54.2),
	("decor/shack_shelf.glb", 34.5, 44.45), ("dungeon/junk_rags.glb", 8.9, 27.0), ("decor/crate_stack.glb", 28.6, 49.1), ("decor/crate_stack.glb", 29.0, 40.9), ("dungeon/rail_wedge.glb", 27.2, 45.0), ("dungeon/rubble_ore.glb", 29.0, 28.8)}
props[:] = [p for p in props if (p["model"], p["pos"][0], p["pos"][2]) not in GONE]

DECOR = [
	# Pell's Hut (x 32-40, z 44-52)
	("op_cot", "pells_hut", W(_d("op_cot"), "n", 44, 33.4)),
	("op_root_armchair", "pells_hut", decor.corner(_d("op_root_armchair"), "s", 52, "e", 40)),
	("op_bone_board", "pells_hut", W(_d("op_bone_board"), "w", 32, 47.0, out=HUNG), 1.0),
	("op_map_rack", "pells_hut", W(_d("op_map_rack"), "n", 44, 36.0, out=HUNG), 0.7),
	("op_key_board", "pells_hut", W(_d("op_key_board"), "e", 40, 45.4, out=HUNG), 0.8),
	("op_tinker_bench", "pells_hut", decor.corner(_d("op_tinker_bench"), "s", 52, "w", 32)),
	("op_strongbox_pried", "pells_hut", decor.mid(_d("op_strongbox_pried"), 38.6, 45.5, 0.0)),
	("op_pipe_rack", "pells_hut", W(_d("op_pipe_rack"), "w", 32, 46.0, out=HUNG), 1.0),
	("op_rock_shelf", "pells_hut", W(_d("op_rock_shelf"), "n", 44, 37.4, out=HUNG), 0.8),
	("spider_eggs", "landing", W(_d("spider_eggs"), "s", 46, 25.6, out=HUNG), 1.0),
	("op_spike_crate", "cave_in", W(_d("op_spike_crate"), "w", 24, 36.9)),
	("graffiti_pell", "spoil", W(_d("graffiti_pell"), "n", 24, 17.0, out=HUNG), 0.5),
	("op_decoy_chest", "den", decor.corner(_d("op_decoy_chest"), "s", 28, "w", 8)),
	("spider_eggs", "den", W(_d("spider_eggs"), "n", 22, 10.0, out=HUNG), 1.0),
	("spider_eggs", "den", W(_d("spider_eggs"), "w", 8, 25.5, out=HUNG), 1.0),
	("pickaxe_in_wall", "dig", W(_d("pickaxe_in_wall"), "e", 50, 50.0, out=HUNG), 1.0),
	("op_diary_table", "dig", W(_d("op_diary_table"), "w", 36, 53.6)),
	("last_meal", "pells_hut", W(_d("last_meal"), "n", 44, 35.4)),
	("table_overturned", "pells_hut", decor.mid(_d("table_overturned"), 36.4, 45.6, 20.0)),
	# Winch Shed (x 24-30, z 44-50)
	# Ladder Landing (x 24-30, z 40-46)
	("op_watch_post", "landing", decor.corner(_d("op_watch_post"), "s", 46, "e", 30)),
	# Cave-in Tunnel
	("op_warning_plank", "cave_in", W(_d("op_warning_plank"), "e", 28, 38.8, out=HUNG), 1.0),
	# Sorting Room (x 22-30, z 22-30)
	("op_tumbler", "sorting", W(_d("op_tumbler"), "n", 22, 27.0)),
	("op_sieve_stack", "sorting", decor.corner(_d("op_sieve_stack"), "s", 30, "e", 30)),
	("op_caught_boot", "sorting", decor.corner(_d("op_caught_boot"), "n", 22, "w", 22)),
	# Spoil Tunnel (x 14-22, z 24-28)
	("op_signpost", "landing", W(_d("op_signpost"), "e", 30, 41.8)),
	# Spider Den (x 8-14, z 22-28)
	("op_barricade", "den", W(_d("op_barricade"), "s", 28, 11.0)),
	# Miner's Shrine (x 30-36, z 32-38)
	("op_hat_on_pick", "shrine", W(_d("op_hat_on_pick"), "n", 32, 33.0)),
	# Pell's Last Dig (x 36-50, z 40-56)
	("op_madness_board", "dig", W(_d("op_madness_board"), "w", 36, 51.0, out=HUNG), 0.8),
	("op_x_marks_dig", "dig", decor.corner(_d("op_x_marks_dig"), "s", 56, "e", 50)),
	# The rule-clash pieces (owner, Nov 22: the rules are fluid). The trapmaker's table out in the Winch Shed (its walls
	# are the shaft, the tripwire and the doors); the still in the pantry's dry corner; the scale beside the sieve stack;
	# the cold hearth in the hut; the bell tripwire by the ladder's foot; the rat traps in the Spider Den, where the
# rat pack is (no room left in the pantry beside the still).
	("op_trapmaker_table", "winch_shed", decor.mid(_d("op_trapmaker_table"), 26.5, 47.1, 0.0)),
	("op_wire_spools", "winch_shed", decor.mid(_d("op_wire_spools"), 27.4, 46.2, 0.0)),
	("op_trap_parts_rack", "winch_shed", W(_d("op_trap_parts_rack"), "s", 50, 26.5, out=HUNG), 0.9),
	("op_still", "pantry", decor.mid(_d("op_still"), 20.55, 48.9, 90.0)),
	("op_ore_scale", "sorting", decor.mid(_d("op_ore_scale"), 29.3, 29.0, 0.0)),
	("op_hearth_tripod", "pells_hut", decor.mid(_d("op_hearth_tripod"), 34.8, 46.2, 0.0)),
	("op_bell_tripwire", "landing", decor.mid(_d("op_bell_tripwire"), 25.6, 44.6, 0.0)),
	("op_rat_traps", "den", decor.mid(_d("op_rat_traps"), 10.5, 22.7, 90.0)),
]
for _c in creatures:   # (the Sorting Room's miner and a Den rat step aside)
	if (_c["pos"][0], _c["pos"][2]) == (26.0, 23.2):
		_c["pos"][0], _c["pos"][2] = 25.0, 25.0
	elif (_c["pos"][0], _c["pos"][2]) == (9.2, 26.8):
		_c["pos"][0], _c["pos"][2] = 10.6, 24.6
	elif (_c["pos"][0], _c["pos"][2]) == (12.4, 26.4):
		_c["pos"][0], _c["pos"][2] = 12.0, 25.2
_lvl = lambda g: 1 if SP[g][5] >= 0 else 2
_plvl = lambda p: 1 if p["pos"][1] > -3.0 else 2
_flatj = {"dungeon/floor_old.glb", "dungeon/wall_old.glb", "dungeon/wall_cracked.glb", "dungeon/trap_floor_break.glb",
	"dungeon/floor_grooved.glb", "dungeon/floor_loose_stone.glb"}
_dxz = lambda p: (p["pos"][0], p["pos"][2])
_cells_l = {l: {(k[0], k[1]): v for k, v in cells.items() if k[2] == l and k not in NO_PIECES} for l in (1, 2)}
_spaces_l = {l: [s for s in SPACES if s[0] not in NOT_ROOMS and level(s[0]) == l] for l in (1, 2)}
_items = {1: [], 2: []}
for n, room, at, *up in DECOR:
	_items[_lvl(room)].append((_d(n), at[0], at[1], at[2], room) + tuple(up))
_problems = []
for l in (1, 2):
	_dw = [_dxz(p) for p in pieces if p["id"] == "doorway" and _plvl(p) == l]
	_dw += [_dxz(p) for p in props if p["model"] in ("dungeon/dungeon_entrance.glb", "dungeon/wall_cracked.glb") and _plvl(p) == l]
	_obst = [(p["pos"][0], p["pos"][2], max(junk.size(p["model"])[:2]) / 2, 0.0, decor.height(p["model"])) for p in props
		if p["role"] in ("decor", "heal") and p["model"] not in _flatj and _plvl(p) == l]
	_obst += [(p["pos"][0], p["pos"][2], 0.4, 1.0, 2.4) for p in props if p["role"] == "light" and _plvl(p) == l]
	_obst += [(p["pos"][0], p["pos"][2], 0.9) for p in pieces if p["id"] in ("mine_prop", "railing") and _plvl(p) == l]
	_obst += [(c["pos"][0], c["pos"][2], 0.5, 0.0, 1.5) for c in creatures if _plvl(c) == l]
	_pr, _ = decor.check(_items[l], _cells_l[l], junk.walk_lines(_spaces_l[l], lambda n: GROUP.get(n, n), _cells_l[l], _dw),
		doors=_dw + [_dxz(p) for p in props if p["role"] == "door" and "lever" not in p["model"] and _plvl(p) == l],
		things=[_dxz(c) for c in chests if _plvl(c) == l] + ([(RECIPE_STAND["pos"][0], RECIPE_STAND["pos"][2])] if l == 2 else [])
			+ [_dxz(p) for p in props if "lever" in p["model"] and _plvl(p) == l],
		traps=[_dxz(p) for p in props if p["role"] in ("trap", "secret") and p["model"] not in _flatj and _plvl(p) == l],
		obstacles=_obst)
	_problems += _pr
if _problems:
	sys.exit("decor breaks the placement rules:\n  " + "\n  ".join(_problems))
for l in (1, 2):
	props += decor.props(_items[l], lambda g: SP[g][5])

# --- 4c. Junk (owner, Nov 22): across the whole room, about 1.8 things per 10 m2 counting the furniture, decor and chests;
# one of each kind per room but candles and pots (tools/dungeons/junk.py; tests/test_dungeon_junk.gd). Own dice (seed).
JUNK_THEMES = {
	"pells_hut": ["meal", "rags", "candles", "bones", "furn_stool", "cookpot_tipped", "furn_bucket_wood", "lantern",
		"tools", "furn_bucket_metal", "scrap", "helmet", "urns", "axe_head"],
	"winch_shed": ["tools", "furn_bucket_metal", "scrap", "rubble_wood", "timber_stack", "lantern", "beam_snapped", "rags"],
	"pantry": ["meal", "rags", "furn_bucket_wood", "grain_sacks", "keg", "candles", "bones", "urns"],
	"landing": ["tools", "rubble_wood", "lantern", "helmet", "bones", "rags", "scrap", "beam_snapped"],
	"cave_in": ["rubble_wood", "beam_snapped", "tools", "helmet", "bones", "scrap"],
	"sorting": ["ore_basket", "tools", "rubble_wood", "furn_bucket_metal", "scrap", "helmet", "lantern", "rags", "furn_stool",
		"crate_stack", "bones", "timber_stack"],
	"spoil": ["rubble_wood", "tools", "ore_basket", "bones", "scrap", "rags"],
	"den": ["bones", "rags", "helmet", "scrap", "rubble_wood", "torch_dropped"],
	"shrine": ["candles", "urns", "bones", "rags", "helmet", "lantern"],
	"dig": ["tools", "ore_basket", "rubble_wood", "helmet", "lantern", "furn_bucket_metal", "scrap", "bones", "beam_snapped",
		"timber_stack", "rags", "torch_dropped", "furn_stool", "crate_stack", "spear_broken", "axe_head", "candles", "meal"],
}
JUNK_ROOMS = set(JUNK_THEMES)
_jcounts = {}
for g in JUNK_ROOMS:
	_floor = [c for c, v in cells.items() if v == g]
	_low = lambda p: p["pos"][1] < SP[g][5] + 1.0
	_there = sum(1 for p in props if p["role"] in ("decor", "light", "heal") and p["model"] not in _flatj and _low(p)
		and cells.get((*junk.cell_of(p["pos"][0], p["pos"][2]), _lvl(g))) == g)
	_there += sum(1 for c in chests if cells.get((*junk.cell_of(c["pos"][0], c["pos"][2]), _lvl(g))) == g)
	_jcounts[g] = max(2, round(1.8 * len(_floor) * 4 / 10) - _there)
print("junk per room:", dict(sorted(_jcounts.items())))
for l in (1, 2):
	_dw = [_dxz(p) for p in pieces if p["id"] == "doorway" and _plvl(p) == l]
	_dw += [_dxz(p) for p in props if p["model"] in ("dungeon/dungeon_entrance.glb", "dungeon/wall_cracked.glb") and _plvl(p) == l]
	props += junk.place_junk(
		_spaces_l[l], lambda n: GROUP.get(n, n), _cells_l[l], lambda g: SP[g][5], {r for r in JUNK_ROOMS if _lvl(r) == l}, JUNK_THEMES,
		doors=_dw + [_dxz(p) for p in props if p["role"] == "door" and "lever" not in p["model"] and _plvl(p) == l],
		path_doors=_dw,
		things=[_dxz(c) for c in chests if _plvl(c) == l] + ([(RECIPE_STAND["pos"][0], RECIPE_STAND["pos"][2])] if l == 2 else [])
			+ [_dxz(p) for p in props if "lever" in p["model"] and _plvl(p) == l],
		traps=[_dxz(p) for p in props if p["role"] in ("trap", "secret") and p["model"] not in _flatj and _plvl(p) == l],
		furniture=[(p["pos"][0], p["pos"][2], max(junk.size(p["model"])[:2]) / 2) for p in props
			if p["role"] in ("decor", "light", "heal") and p["model"] not in _flatj and _plvl(p) == l and p["pos"][1] < SP["landing"][5] + 1.0 + (6.0 if l == 1 else 0.0)]
			+ [(p["pos"][0], p["pos"][2], 0.9) for p in pieces if p["id"] in ("mine_prop", "railing") and _plvl(p) == l],
		seed=2013, skip={"entry"},
		counts={r: n for r, n in _jcounts.items() if _lvl(r) == l},
	)

# --- Write it out. ---
missing = sorted({p["model"] for p in props if not (ROOT / "assets/models" / p["model"]).exists()} |
	{c["model"] for c in creatures if not (ROOT / "assets/models" / c["model"]).exists()} |
	{"build/%s__%s.glb" % (p["id"], p["mat"]) for p in pieces if not (ROOT / ("assets/models/build/%s__%s.glb" % (p["id"], p["mat"]))).exists()})
if missing:
	sys.exit("missing models: %s" % missing)
plan = {"name": "Old Pell's Diggings", "map": "pell", "pieces": pieces, "props": props, "creatures": creatures,
	"chests": chests, "lights": lights, "recipe_stand": RECIPE_STAND}
out = ROOT / "blueprints/dungeons/old_pells_diggings.json"
out.write_text(json.dumps(plan, indent=0, separators=(",", ":")), encoding="utf-8")
print("WROTE %s: %d pieces, %d props, %d creatures, %d chests, %d junctions, %d lights" % (out.name, len(pieces), len(props),
	len(creatures), len(chests), len(junctions), len(lights)))
