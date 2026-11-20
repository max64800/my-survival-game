# Mossgate Hold (dungeon map 1): every root wood piece, trap, door, piece of furniture, chest and creature, laid out on
# the dungeon's rooms (read from src/world/dungeon_map.gd, so the rock and the pieces always match).
#   python tools/dungeons/make_mossgate.py                 -> blueprints/dungeons/mossgate_hold.json (the game builds from it)
#   python tools/dungeons/make_mossgate.py <page folder>   -> also the 3D page's files (plan.json + m/<model>.json)
# Positions are the dungeon's own metres (x right, z toward the cave, y up from the floor), like DungeonMap.
# Owner's rules: root wood rooms (Delver's Shack kit), round doors only, everything on the 2 m grid (1 m halves next to
# doorways), the Pillar Hall and the Chasm room keep natural rock ceilings with stalactites (decisions, round 2).
import base64, json, math, random, re, struct, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = (ROOT / "src/world/dungeon_map.gd").read_text(encoding="utf-8")
SPACES = [[m[0]] + [float(v) for v in m[1:]] for m in
	re.findall(r'\["(\w+)",\s*([-\d.]+),\s*([-\d.]+),\s*([-\d.]+),\s*([-\d.]+),\s*([-\d.]+),\s*([-\d.]+)\]', SRC)]
SP = {s[0]: s for s in SPACES}
MAT = "plank_root"
CAVE_Z = 60.0  # the round door at the end of the way in (DungeonMap.FACE: 4 m out from the mouth, in solid rock)
rng = random.Random(1907)

# Which spaces make one room (no wall between them), how many rows of 2 m walls, and the root wood ceiling height.
GROUP = {"way_out_n": "way_out", "way_out_w": "way_out", "chasm": "chasm_room", "spike_pit": "pillar_hall"}
ROOMS = {"gate_hall", "guard_room", "store_room", "vault", "tombs", "shrine", "pillar_hall", "chasm_room",
	"crusher_hall", "pack_hall", "loot_room"}
NATURAL_CEILING = {"pillar_hall", "chasm_room"}  # rock overhead (stalactites)
# (owner, Nov 20: the crushers "a bit hidden": the Crusher Hall got a root wood ceiling at 4 m, the crushers' beams sit
# right under it and their chains run up through it, no torch: you see them late)
NO_PIECES = {(48, 4), (48, 6)}  # the hidden boulder's spot: bare rock round the boulder
# Owner, Nov 20 (3rd play): the crushers moved into the Pack Hall, just inside its door. They hang in a dark hole in
# the root wood ceiling (no ceiling boards over them), so they can lift 1 m higher and hide up there.
NO_CEILING = {(56, 4), (56, 6)}


def group(name):
	return GROUP.get(name, name)


def height(g):
	"""The root wood ceiling's height: rooms 4 m (two rows of walls), corridors 3 m (a wall + a half wall): 2.76 m to
	walk under (owner, Nov 19: "the tunnels are too small, they should be 2 m high")."""
	return 4 if g in ROOMS else 3


OLD = 0.7  # owner, Nov 19: about 70% of the floors and walls old and rotten, the rest normal
DOOR_SCALE = 1.5  # dungeon doorways 1.5x the building kit's: a round hole about 2 m wide and 2.6 m high


def space_of(x, z):
	"""The group of the 2 m cell whose corner is (x, z), or None for rock. The entry runs on to the cave wall."""
	cx, cz = x + 1, z + 1
	hit = None
	for s in SPACES:
		if s[1] < cx < s[3] and s[2] < cz < s[4] and s[5] >= 0:
			if hit is None or s[0] in GROUP or (hit not in ROOMS and s[0] in ROOMS):
				hit = s[0]
	if hit is None and 32 <= x < 36 and 56 <= z < CAVE_Z:
		hit = "entry"
	return group(hit) if hit else None


def in_box(name, x, z):
	s = SP[name]
	return s[1] <= x < s[3] and s[2] <= z < s[4]


pieces, props, creatures, chests, lights = [], [], [], [], []


def piece(pid, x, y, z, rot, scale=1.0):
	pieces.append({"id": pid, "mat": MAT, "pos": [x, y, z], "rot": rot, **({"scale": scale} if scale != 1.0 else {})})


def prop(model, x, y, z, yaw=0.0, scale=1.0, role="decor", label="", tilt=0.0, opens=""):
	props.append({"model": model, "pos": [round(x, 3), round(y, 3), round(z, 3)], "yaw": round(yaw, 1), "scale": scale,
		"role": role, "label": label, **({"tilt": tilt} if tilt else {}), **({"opens": opens} if opens else {})})


def creature(kind, x, y, z, yaw=0.0):
	model = {"rock_beetle": "creatures/rock_beetle_mossy.glb", "great_rock_beetle": "creatures/rock_beetle_mossy.glb",
		"cave_spider": "monsters/cave_spider_v0.glb", "cave_bat": "creatures/cave_bat_mossy.glb",
		"rock_snail": "creatures/rock_snail_mossy.glb"}[kind]
	creatures.append({"kind": kind, "model": model, "pos": [x, y, z], "yaw": yaw, "scale": 1.5 if kind == "great_rock_beetle" else 1.0})


def chest(kind, x, z, yaw, label, sure=False, loot="random"):
	"""A chest (the game makes it a real chest with loot: DungeonBuild.LOOT[loot]). Not `sure`: there in about 2 of 3 worlds."""
	chests.append({"kind": kind, "pos": [x, 0.25, z], "yaw": yaw, "label": label, "always": sure, "loot": loot})


# --- 1. Floors (root wood boards; some old ones), and the root wood ceilings. ---
cells = {}
for x in range(0, 86, 2):
	for z in range(-2, int(CAVE_Z) + 2, 2):
		g = space_of(x, z)
		if g:
			cells[(x, z)] = g
SPECIAL_FLOOR = {}
for x in range(36, 42, 2):
	for z in range(20, 26, 2):
		SPECIAL_FLOOR[(x, z)] = "trap_floor_break"  # the cracked tiles over the spike pit
SPECIAL_FLOOR[(8, 42)] = "floor_loose_stone"  # the tombs' loose stone (a buried chest under it)
for (x, z), g in cells.items():
	if (x, z) in NO_PIECES or (in_box("chasm", x, z) and g == "chasm_room"):
		continue  # the boulder's spot; the chasm is a drop, no floor
	cx, cz = x + 1.0, z + 1.0
	sp = SPECIAL_FLOOR.get((x, z))
	if sp:
		prop("dungeon/%s.glb" % sp, cx, 0.0, cz, rng.choice([0, 90, 180, 270]), role="trap" if sp == "trap_floor_break" else "secret",
			label="Breaking floor" if sp == "trap_floor_break" else "Loose stone")
	elif rng.random() < (0.85 if g in ("tombs", "rubble_tunnel", "way_out") else OLD):
		prop("dungeon/floor_old.glb", cx, 0.0, cz, rng.choice([0, 90, 180, 270]))
	else:
		piece("floor", cx, 0.0, cz, 0)
	if g in NATURAL_CEILING or (x, z) in NO_CEILING:
		continue
	# A root wood ceiling on the walls. Owner, Nov 20 (3rd play: "the ceilings look too new"): about 70% are old,
	# like the floors and walls: the old floor turned upside down, so its worn, gappy boards face down at you.
	if rng.random() < (0.85 if g in ("tombs", "rubble_tunnel", "way_out") else OLD):
		prop("dungeon/floor_old.glb", cx, float(height(g)) + 0.24, cz, rng.choice([0, 90, 180, 270]), tilt=180.0)
	else:
		piece("floor", cx, float(height(g)), cz, 0)

# --- 2. Walls round every room (rock behind them) and doorways where two spaces meet. ---
DIRS = [((-2, 0), "w"), ((2, 0), "e"), ((0, -2), "n"), ((0, 2), "s")]
INWARD_YAW = {"w": 90.0, "e": 270.0, "n": 0.0, "s": 180.0}  # a wall model's front (+z) turned to face into the room
junctions = {}
rock_edges = []
for (x, z), g in cells.items():
	if (x, z) in NO_PIECES:
		continue
	for (dx, dz), side in DIRS:
		other = cells.get((x + dx, z + dz))
		if side in "we":
			line, along, rot = (x if side == "w" else x + 2), z + 1.0, 1
		else:
			line, along, rot = (z if side == "n" else z + 2), x + 1.0, 0
		if other == g:
			continue
		if other is None:
			if g == "entry" and side == "s":
				continue  # the cave
			if g == "chasm_room" and in_box("chasm", x, z):
				continue  # the chasm's own rock sides
			rock_edges.append((g, side, line, along, rot, (x, z)))
		elif (x + dx, z + dz) not in NO_PIECES:
			key = (min(g, other), max(g, other), side in "we", line)
			junctions.setdefault(key, set()).add(along)


def wall_pos(rot, line, along):
	return (line, along) if rot == 1 else (along, line)


# Rock edges: two rows in rooms, a wall + a half wall in corridors; mostly old walls, the dart hall's holed beam, torches.
DART = {("dart_hall", "s", 42, 45.0), ("dart_hall", "s", 42, 47.0)}
torch_every = {}
for g, side, line, along, rot, cell in rock_edges:
	x, z = wall_pos(rot, line, along)
	yaw = INWARD_YAW[side]
	for r in range(2):
		y = 2.0 * r
		if r == 1 and height(g) == 3:
			piece("half_wall", x, y, z, rot)  # (no old half wall model yet)
		elif r == 0 and (g, side, line, along) in DART:
			prop("dungeon/trap_dart_wall.glb", x, y, z, yaw, role="trap", label="Dart holes")
		elif rng.random() < (0.85 if g in ("tombs", "rubble_tunnel", "vault") else OLD):
			prop("dungeon/wall_old.glb", x, y, z, yaw)
		else:
			piece("wall", x, y, z, rot)
	# A torch on about every third wall of a room (none in the dark vault: you find it with your lantern).
	n = torch_every.get(g, 0)
	torch_every[g] = n + 1
	if g not in ("vault", "boulder_way", "crusher_hall") and n % (3 if g in ROOMS else 5) == 1:
		ox, oz = {"w": (0.2, 0), "e": (-0.2, 0), "n": (0, 0.2), "s": (0, -0.2)}[side]
		prop("decor/furn_wall_torch_iron.glb", x + ox, 1.2, z + oz, yaw, role="light")
		lights.append([round(x + ox * 3, 2), 2.0, round(z + oz * 3, 2)])

# Junctions: a big round doorway (3 m, the kit's doorway at 1.5x) in the middle, 1 m narrow walls beside it on a 4 m
# opening, two high (the doorway's sides hide their inner half); a half wall over the doorway up to a room's 4 m
# ceiling. Special ones: the cracked wall to the vault, the loot door, the one-way gate.
SPECIAL_J = {
	("store_room", "vault_way"): "cracked",
	("loot_door", "loot_room"): "loot_door",
	("store_room", "way_out"): "gate",
	("crusher_hall", "pack_hall"): "hand_door",
}
for (a, b, along_z, line), spots in junctions.items():
	spots = sorted(spots)
	lo, hi = spots[0] - 1.0, spots[-1] + 1.0
	mid = (lo + hi) / 2.0
	rot = 1 if along_z else 0
	kind = SPECIAL_J.get((a, b), "")
	# Which side is the room you see it from (for a model's front): the side whose cell holds `a`.
	def p(al):
		return wall_pos(rot, line, al)
	if kind == "cracked":
		x, z = p(mid)
		prop("dungeon/wall_cracked.glb", x, 0.0, z, 0.0 if not along_z else 90.0, role="secret", label="Cracked wall (hollow sound)")
		for al in spots:
			x, z = p(al)
			piece("wall", x, 2.0, z, rot)
		continue
	print("junction %s/%s: %.0f m" % (a, b, hi - lo))
	x, z = p(mid)
	piece("doorway", x, 0.0, z, rot, DOOR_SCALE)
	if kind == "loot_door":
		prop("dungeon/door_loot.glb", x, 0.0, z, 90.0 if along_z else 0.0, DOOR_SCALE, role="door", label="Loot door: opens when the pack is dead")
	elif kind == "hand_door":  # (owner, Nov 20, 3rd play: shut, so the pack doesn't hear the boulder; E opens it)
		prop("dungeon/door_loot.glb", x, 0.0, z, 90.0 if along_z else 0.0, DOOR_SCALE, role="door", label="Round door: E to open", opens="hand")
	elif kind == "gate":
		prop("dungeon/gate_round.glb", x, 0.0, z, 90.0 if along_z else 0.0, DOOR_SCALE, role="door", label="One-way gate: opens from the way out")
		# The lever (owner, Nov 20, 3rd play: it floated beside a wall post): on the way out's north wall, 1 m past
		# the gate, its back on the boards' face (the wall's middle line + half its 0.29 m).
		prop("dungeon/lever.glb", x + 1.0, 0.0, 38.0 + 0.15, 0.0, role="door", label="Lever: E to open the gate")
	for edge in (lo + 0.5, hi - 0.5) if hi - lo >= 4.0 else ():
		x, z = p(edge)
		piece("wall_narrow", x, 0.0, z, rot)
		piece("wall_narrow", x, 2.0, z, rot)
	if max(height(a), height(b)) > 3:
		x, z = p(mid)
		piece("half_wall", x, 3.0, z, rot)

# --- 3. The way in: the round stone door where the tunnel meets the cave. ---
prop("dungeon/dungeon_entrance.glb", 34.0, 0.0, CAVE_Z, 0.0, role="door", label="The way in: round stone door")
# The corridor's end wall round the door (the frame's stone sides hide the inner ends of these).
for x in (32.5, 35.5):
	piece("wall_narrow", x, 0.0, CAVE_Z, 0)
for x in (33.0, 35.0):
	piece("half_wall", x, 2.0, CAVE_Z, 0)

# --- 4. The rooms, one by one (from the sketch the owner OK'd). ---
# 1 Gate Hall: banners, barrels, crates, a bench; three beetles chewing the floor.
for x in (30.0, 38.0):
	prop("decor/furn_banner_tall_1.glb", x, 0.0, 36.35, 0.0)
prop("props/barrel.glb" if (ROOT / "assets/models/props/barrel.glb").exists() else "decor/keg.glb", 27.2, 0.25, 37.2, 30.0)
prop("decor/crate_stack.glb", 40.6, 0.25, 37.4, 15.0)
prop("decor/shack_bench.glb", 27.4, 0.25, 43.5, 90.0)
for i, (x, z) in enumerate([(31.5, 40.0), (36.0, 42.5), (38.5, 39.0)]):
	creature("rock_beetle", x, 0.25, z, 40.0 + i * 110.0)
chest("chest_small", 28.5, 44.6, 180.0, "Random chest")

# 2 Dart Hall: raised plates in the floor; the holed beam on the south wall.
for x, z in [(44.0, 39.4), (45.6, 40.6), (47.2, 39.6), (48.4, 40.8)]:
	prop("dungeon/trap_dart_plate.glb", x, 0.25, z, rng.choice([0, 15, 30]), role="trap", label="Raised plate" if x == 45.6 else "")

# 3 Guard Room: weapon stands, a table with stools, a whetstone; four spiders up in the corners.
prop("decor/furn_weapon_stand.glb", 51.0, 0.25, 35.4, 0.0)
piece("spear_rack", 57.0, 0.25, 35.0, 0)
prop("decor/shack_table.glb", 55.0, 0.25, 41.0, 0.0)
prop("decor/shack_stool.glb", 55.0, 0.25, 42.2, 0.0)
prop("decor/shack_stool.glb", 53.6, 0.25, 41.0, 90.0)
prop("decor/furn_whetstone.glb", 58.6, 0.25, 44.4, 200.0)
for i, (x, z) in enumerate([(51.0, 45.0), (59.0, 45.0), (59.0, 36.0), (52.5, 38.0)]):
	creature("cave_spider", x, 3.6 if i < 3 else 0.25, z, i * 90.0)
chest("chest_small", 58.0, 37.4, 270.0, "Random chest")

# 4 Store Room: shelves, barrels, sacks, crates; a snail.
prop("decor/shack_shelf.glb", 66.0, 0.25, 43.6, 180.0)
prop("decor/furn_barrel_rack.glb", 69.3, 0.25, 37.2, 270.0)
prop("decor/keg.glb", 62.8, 0.25, 37.0, 10.0)
prop("decor/grain_sacks.glb", 68.6, 0.25, 41.0, 260.0)
prop("decor/crate_stack.glb", 63.0, 0.25, 39.4, 80.0)
creature("rock_snail", 67.0, 0.25, 39.0, 200.0)
chest("chest_small", 64.5, 42.6, 180.0, "Random chest")
chest("chest_small", 68.0, 42.6, 180.0, "Random chest")

# 5 Hidden Vault (behind the cracked wall): the chest that's always there and an old wall marking.
chest("chest_stone", 65.0, 28.0, 0.0, "Vault chest (always)", True, "vault")
prop("decor/fossil_plaque.glb", 65.0, 1.5, 26.2, 0.0, label="Old wall marking")

# 6 Rubble Tunnel: a fallen wall and rubble to clear.
# (owner, Nov 20: the broken wall standing in the middle of the tunnel looked like a weird door: gone. The stone
# rubble breaks now, like the tower's: DungeonBuild "rubble")
prop("build/ruin_rubble__cut_stone.glb", 20.4, 0.25, 40.6, 30.0, role="secret", label="Rubble: hit it to clear")
prop("build/ruin_rubble__cut_stone.glb", 23.8, 0.25, 41.0, 150.0, role="secret")
creature("rock_snail", 19.2, 0.25, 39.0, 90.0)

# 7 Old Tombs: candles and vases (no coffin model yet); bats roosting high; the loose stone in the corner.
for x, z in [(13.0, 36.6), (13.0, 40.0), (13.0, 43.4), (7.6, 36.6)]:
	prop("decor/furn_candle_stand.glb", x, 0.25, z, rng.choice([0, 45, 90]))
prop("decor/furn_vase_tall.glb", 16.8, 0.25, 35.2, 0.0)
prop("decor/furn_vase_wide.glb", 7.2, 0.25, 39.0, 0.0)
creature("cave_bat", 10.0, 3.4, 39.0, 30.0)
creature("cave_bat", 8.6, 3.6, 41.0, 200.0)
chest("chest_small", 8.5, 36.4, 0.0, "Random chest")
chest("chest_small", 9.0, 43.0, 90.0, "Buried chest (under the loose stone)", True, "buried")

# 8 Rune Shrine: the healing basin, stone lanterns, a rune shield. No creatures.
prop("decor/mushroom_fountain.glb", 12.0, 0.25, 22.0, 0.0, role="heal", label="Healing basin")
prop("decor/stone_lantern.glb", 9.0, 0.25, 17.4, 0.0, role="light")
prop("decor/stone_lantern.glb", 15.0, 0.25, 17.4, 0.0, role="light")
lights.append([12.0, 1.6, 21.0])
prop("decor/rune_shield.glb", 12.0, 1.6, 16.25, 0.0, label="Glowing rune stone")
chest("chest_small", 16.0, 24.4, 270.0, "Random chest")

# 9 Pillar Hall: root wood columns up to the rock (8 m), the spike pit's floor in the middle, stalactites, four beetles.
for x, z in [(28.0, 20.0), (28.0, 26.0), (44.0, 20.0), (44.0, 26.0), (33.0, 18.0), (33.0, 28.0)]:
	for y in (0.25, 2.25, 4.25, 6.0):
		piece("column", x, y, z, 0)
for x in range(36, 42, 2):
	for z in range(20, 26, 2):
		prop("dungeon/trap_spikes.glb", x + 1.0, -4.0, z + 1.0, rng.choice([0, 90, 180, 270]), role="trap", label="Spike pit (kills)" if (x, z) == (38, 22) else "")
lights.append([39.0, -2.6, 23.0])  # (owner, Nov 20: "nothing visible under it": a faint glow down in the pit shows the spikes)
for i, (x, z) in enumerate([(26.5, 23.0), (31.0, 28.0), (44.0, 23.0), (35.0, 28.6)]):
	creature("rock_beetle", x, 0.25, z, i * 80.0 + 20.0)
for x, z, m in [(30.0, 22.0, "trap_drip_thin"), (41.0, 18.5, "trap_drip_fat"), (26.0, 28.0, "trap_drip_thin")]:
	prop("dungeon/%s.glb" % m, x, 8.5 + 0.1, z, rng.choice([0, 120, 240]), role="trap", tilt=180.0)
chest("chest_small", 44.0, 28.6, 180.0, "Random chest")

# 10 Chasm Bridge: posts and planks across the 4 m drop onto spikes, a broken plank in the middle, broken railings along the edge,
# stalactites that fall over the bridge (dust first), bats, and spikes at the bottom.
BRIDGE_Y = 0.13  # the deck's top (0.11 in the models) level with the floor boards' top (0.24): you walk straight on
# Owner, Nov 20 (3rd play: "too easy"): every plank gone but the middle section's: two big jumps, 2 m each, from the
# edge onto the middle boards and on to the far edge (the dwarf jumps about 4.5 m walking). The ropes still run
# from post to post. The posts stand on the floor right at the chasm's edges (x 36 and 42).
prop("dungeon/bridge_posts.glb", 35.0, BRIDGE_Y, 6.0, 90.0, role="door", label="")
prop("dungeon/bridge_posts.glb", 43.0, BRIDGE_Y, 6.0, 270.0, role="door", label="")
BRIDGE = {0: "bridge_ropes", 1: "bridge_plank", 2: "bridge_ropes"}
for i, x in enumerate([37.0, 39.0, 41.0]):
	prop("dungeon/%s.glb" % BRIDGE[i], x, BRIDGE_Y, 6.0, 90.0, role="trap" if i != 1 else "door",
		label="Only ropes: jump 2 m!" if i == 0 else ("The middle boards (fall: spikes)" if i == 1 else ""))
for z in (1.0, 3.0, 9.0, 11.0):
	prop("dungeon/railing_broken.glb", 35.6, 0.25, z, 90.0)
	prop("dungeon/railing_broken.glb", 42.4, 0.25, z, 270.0)
for x, m in [(37.4, "trap_drip_thin"), (39.0, "trap_drip_cluster"), (40.8, "trap_drip_fat")]:
	prop("dungeon/%s.glb" % m, x, 7.5 + 0.1, 6.0, rng.choice([0, 90]), role="trap", label="Falling stalactites" if x == 39.0 else "", tilt=180.0)
for x in range(36, 42, 2):
	for z in range(0, 12, 2):
		prop("dungeon/trap_spikes.glb", x + 1.0, -4.0, z + 1.0, rng.choice([0, 90, 180, 270]), role="trap")  # (owner, Nov 20: 4 m like the pit)
creature("cave_bat", 30.0, 4.5, 8.0, 0.0)
creature("cave_bat", 44.0, 4.0, 3.0, 220.0)
chest("chest_small", 26.5, 2.6, 0.0, "Random chest")

# 11 The hidden boulder: one of our cave boulders, made big enough to fill the low tunnel (breaks like cave boulders).
prop("cave/boulder_round.glb", 49.0, 0.0, 6.0, 30.0, scale=3.0, role="secret", label="Hidden boulder (6 hits)")

# 12 The small hall before the Pack Hall: its round door is shut (E opens it, it swings toward you).
# 13 Pack Hall: the two crushers hang just inside its door (owner, Nov 20, 3rd play), up in a dark hole in the
# ceiling, 1 m higher than before. They wake only once someone has crossed the hall (to the loot door), then slam
# in turn to block the way back (the game: DungeonBuild; a dwarf under one dies).
prop("dungeon/trap_crusher.glb", 57.2, 1.25, 5.0, 90.0, role="trap", label="Crushers (wake once you've crossed)")
prop("dungeon/trap_crusher.glb", 57.2, 1.25, 7.0, 90.0, role="trap")

# Pack Hall: hanging chains, an old cauldron and firewood; the pack leader (a bigger beetle) with beetles and spiders.
for x, z in [(60.0, 4.0), (68.0, 4.0), (60.0, 14.0), (68.0, 14.0)]:
	prop("dungeon/chain_hanging.glb", x, 4.0, z, 0.0)
prop("decor/furn_cauldron.glb", 70.0, 0.25, 16.6, 0.0)
prop("decor/firewood_rack.glb", 57.4, 0.25, 16.4, 90.0)
creature("great_rock_beetle", 64.5, 0.25, 9.0, 270.0)
# (owner, Nov 20: "a bit too difficult": the leader, one beetle and three spiders)
creature("rock_beetle", 61.0, 0.25, 13.0, 270.0)
for i, (x, z) in enumerate([(67.0, 13.5), (70.0, 9.0), (58.0, 9.5)]):
	creature("cave_spider", x, 0.25, z, 270.0 + i * 30.0)

# 14 Loot Room: the big chest, the recipe stand with its glowing scroll, coins, candles, banners.
chest("chest_copper", 82.4, 10.0, 270.0, "Big loot chest (always)", True, "big")
# The recipe stand: the game makes it a stand you open, holding this dungeon's scroll (always the same recipe,
# decisions round 4: Mossgate Hold teaches the Copper Shield).
RECIPE_STAND = {"pos": [79.0, 0.25, 5.2], "yaw": 0.0, "page": "scroll_mossgate"}
prop("dungeon/recipe_stand.glb", 79.0, 0.25, 5.2, 0.0, role="loot", label="Recipe stand (same recipe every time)")
prop("dungeon/recipe_scroll.glb", 79.0, 0.25 + 0.90, 5.2 + 0.007, 0.0, role="loot", tilt=20.0)
prop("decor/furn_candle_stand.glb", 76.0, 0.25, 5.0, 0.0, role="light")
prop("decor/furn_candle_stand.glb", 82.6, 0.25, 14.6, 0.0, role="light")
prop("treasure/tr_coins_wide.glb", 81.4, 0.25, 12.0, 40.0)
prop("treasure/tr_chalice.glb", 81.6, 0.25, 8.0, 0.0)
prop("decor/furn_banner_tall_2.glb", 83.65, 0.25, 10.0, 270.0)
lights.append([79.0, 2.2, 7.0])

# 15 Way Out: a long low tunnel back to the Store Room.
lights.append([78.0, 1.8, 30.0])

for x, z in [(34.0, 50.0), (34.0, 33.0), (66.0, 40.0), (12.0, 40.0), (28.0, 6.0), (64.0, 9.0)]:  # (no light over the crushers)
	lights.append([x, 3.0, z])

# --- Write it out. ---
missing = sorted({p["model"] for p in props if not (ROOT / "assets/models" / p["model"]).exists()} |
	{c["model"] for c in creatures if not (ROOT / "assets/models" / c["model"]).exists()})
if missing:
	sys.exit("missing models: %s" % missing)
plan = {"name": "Mossgate Hold", "map": "mossgate", "pieces": pieces, "props": props, "creatures": creatures,
	"chests": chests, "lights": lights, "recipe_stand": RECIPE_STAND}
out = ROOT / "blueprints/dungeons/mossgate_hold.json"
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps(plan, indent=0, separators=(",", ":")), encoding="utf-8")
print("WROTE %s: %d pieces, %d props, %d creatures, %d chests" % (out.name, len(pieces), len(props), len(creatures), len(chests)))

if len(sys.argv) > 1:  # the 3D page's files: each model once, as .json (pages can't be served .glb)
	page = Path(sys.argv[1])
	(page / "m").mkdir(parents=True, exist_ok=True)
	plan["spaces"] = SPACES
	(page / "plan.json").write_text(json.dumps(plan, separators=(",", ":")), encoding="utf-8")
	files = {f"build/{p['id']}__{p['mat']}.glb" for p in pieces} | {p["model"] for p in props} | {c["model"] for c in chests and []} \
		| {c["model"] for c in creatures} | {f"stations/{c['kind']}.glb" for c in chests}
	for f in sorted(files):
		d = (ROOT / "assets/models" / f).read_bytes()
		n = struct.unpack("<I", d[12:16])[0]
		g = json.loads(d[20:20 + n])
		b = d[20 + n + 8:]
		g["buffers"] = [{"byteLength": len(b), "uri": "data:application/octet-stream;base64," + base64.b64encode(b).decode()}]
		name = f.replace("/", "__").replace(".glb", ".json")
		(page / "m" / name).write_text(json.dumps(g, separators=(",", ":")))
	print("page files:", len(files), "models")
