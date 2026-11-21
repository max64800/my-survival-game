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
SRC = (ROOT / "src/world/dungeon_map.gd").read_text(encoding="utf-8").split("const MOSSGATE")[1].split("\n}\n")[0]  # (only map 1)
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
# (Nov 22, decor catalogue: the keg and crate stack made way for the snapped gate bar; the chest moved to the north-west
# corner: the gatekeeper's corner is where it stood)
# (the bench made way for the diggers' barricade, Nov 22)
for i, (x, z) in enumerate([(31.5, 40.0), (36.0, 42.5), (38.5, 39.0)]):
	creature("rock_beetle", x, 0.25, z, 40.0 + i * 110.0)
chest("chest_small", 27.2, 37.3, 90.0, "Random chest")

# 2 Dart Hall: raised plates in the floor; the holed beam on the south wall.
for x, z in [(44.0, 39.4), (45.6, 40.6), (47.2, 39.6), (48.4, 40.8)]:
	prop("dungeon/trap_dart_plate.glb", x, 0.25, z, rng.choice([0, 15, 30]), role="trap", label="Raised plate" if x == 45.6 else "")

# 3 Guard Room: weapon stands, a table with stools, a whetstone; four spiders up in the corners.
# (Nov 22, decor catalogue: the weapon stand, spear rack, table and stools made way for the guards' own pieces, section 5)
prop("decor/furn_whetstone.glb", 58.6, 0.25, 44.4, 200.0)
for i, (x, z) in enumerate([(51.0, 45.0), (59.0, 45.0), (59.0, 36.0), (52.5, 38.0)]):
	creature("cave_spider", x, 3.6 if i < 3 else 0.25, z, i * 90.0)
chest("chest_small", 58.0, 37.4, 270.0, "Random chest")

# 4 Store Room: shelves, barrels, sacks, crates; a snail.
# (Nov 22, decor catalogue: the shelf, barrel rack, keg, sacks and crates made way for the store's own pieces along the
# south wall, section 5; the two chests moved to the north corners, out of their way)
creature("rock_snail", 66.0, 0.25, 39.0, 200.0)
chest("chest_small", 62.9, 37.0, 90.0, "Random chest")
chest("chest_small", 69.1, 37.0, 270.0, "Random chest")

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
# Owner, Nov 20 (8/10 note: "make sure most stalactites are over or beside the chests, to bait people"): one hangs
# right in front of the chest (where you stand to open it), one beside it; one stays over the hall's middle.
for x, z, m in [(44.0, 27.4, "trap_drip_fat"), (42.3, 28.6, "trap_drip_thin"), (30.0, 22.0, "trap_drip_thin")]:
	prop("dungeon/%s.glb" % m, x, 8.5 + 0.1, z, rng.choice([0, 120, 240]), role="trap", tilt=180.0,
		label="Stalactite over the chest (bait)" if (x, z) == (44.0, 27.4) else "")
chest("chest_small", 44.0, 28.6, 180.0, "Random chest")

# 10 Chasm Bridge: posts and planks across the 4 m drop onto spikes, a broken plank in the middle, broken railings along the edge,
# stalactites that fall over the bridge (dust first), bats, and spikes at the bottom.
BRIDGE_Y = 0.13  # the deck's top (0.11 in the models) level with the floor boards' top (0.24): you walk straight on
# Owner, Nov 20 (3rd play: "too easy"): every plank gone but the middle section's. Then ("I can still jump the whole
# bridge") the chasm is 8 m wide (x 36-44): a running jump (about 7 m) can't clear it, so you jump 3 m onto the middle
# boards (x 39-41) and 3 m on (about 4.5 m walking). The ropes run from post to post; the posts stand on the edges.
prop("dungeon/bridge_posts.glb", 35.0, BRIDGE_Y, 6.0, 90.0, role="door", label="")
prop("dungeon/bridge_posts.glb", 45.0, BRIDGE_Y, 6.0, 270.0, role="door", label="")
BRIDGE = {0: "bridge_ropes_3m", 1: "bridge_plank", 2: "bridge_ropes_3m"}  # (3 m of rope, 2 m of boards, 3 m of rope)
for i, x in enumerate([37.5, 40.0, 42.5]):
	prop("dungeon/%s.glb" % BRIDGE[i], x, BRIDGE_Y, 6.0, 90.0, role="trap" if i != 1 else "door",
		label="Only ropes: jump 3 m!" if i == 0 else ("The middle boards (fall: spikes)" if i == 1 else ""))
for z in (1.0, 3.0, 9.0, 11.0):
	prop("dungeon/railing_broken.glb", 35.6, 0.25, z, 90.0)
	prop("dungeon/railing_broken.glb", 44.4, 0.25, z, 270.0)
# (owner, Nov 20: most stalactites bait the chests) one cluster over the middle boards, two at the chest.
for x, z, m in [(40.0, 6.0, "trap_drip_cluster"), (26.5, 3.8, "trap_drip_cluster"), (28.0, 2.2, "trap_drip_thin")]:
	prop("dungeon/%s.glb" % m, x, 7.5 + 0.1, z, rng.choice([0, 90]), role="trap", tilt=180.0,
		label="Falling stalactites" if x == 40.0 else ("Stalactites over the chest (bait)" if x == 26.5 else ""))
for x in range(36, 44, 2):
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

# --- 5. Decor from the decor catalogue (docs/art/DECOR-CATALOG.md, Nov 22): every piece in its own room and spot, off
# the walk lines and clear of doors, chests and traps (tools/dungeons/decor.py; tests/test_dungeon_decor.gd).
# The rule clashes are fine (owner, Nov 22: the rules are fluid): the lit lantern posts and the toll table are in.
import decor  # noqa: E402
import junk  # noqa: E402


def _d(n):
	return "decor/%s.glb" % n


W = decor.wall
DECOR = [
	# 1 Gate Hall (x 26-42, z 36-46; the way in at the south wall's middle, x 34). The gatekeeper's corner: left of
	# the way in as you come in (south wall, west end): desk, ledger shelf, key board, the forced strongbox, the chair.
	("mg_gatekeeper_desk", "gate_hall", W(_d("mg_gatekeeper_desk"), "s", 46, 29.8)),
	("mg_ledger_shelf", "gate_hall", W(_d("mg_ledger_shelf"), "s", 46, 28.6)),
	("mg_key_board", "gate_hall", W(_d("mg_key_board"), "s", 46, 31.0)),
	("mg_strongbox_forced", "gate_hall", decor.corner(_d("mg_strongbox_forced"), "s", 46, "w", 26)),
	("mg_gatekeeper_chair", "gate_hall", decor.mid(_d("mg_gatekeeper_chair"), 29.6, 44.55, 30.0)),
	# right of the way in: the gate's winch and the alarm bell; the snapped gate bar dragged to the north wall.
	("mg_gate_windlass", "gate_hall", W(_d("mg_gate_windlass"), "s", 46, 37.3)),
	("mg_alarm_bell", "gate_hall", W(_d("mg_alarm_bell"), "s", 46, 38.9)),
	("mg_gate_bar_snapped", "gate_hall", W(_d("mg_gate_bar_snapped"), "n", 36, 40.6)),
	# the gate lanterns either side of the round door (in the way in, just outside it: inside, the paths fork from the
	# door), the toll table right of the way in, out of the paths; the diggers' barricade, dragged out of the Rubble
	# Tunnel (too narrow to stand it in) against the wall beside the tunnel's mouth, where the bench stood.
	# (side on to the wall, the lantern arms reaching toward the door: the way in is only 4 m wide)
	("mg_lantern_post", "entry", decor.mid(_d("mg_lantern_post"), 32.6, 48.6, 0.0)),
	("mg_lantern_post", "entry", decor.mid(_d("mg_lantern_post"), 35.4, 48.6, 0.0)),
	("mg_toll_table", "gate_hall", decor.mid(_d("mg_toll_table"), 40.4, 43.4, 0.0)),
	("mg_barricade", "gate_hall", W(_d("mg_barricade"), "w", 26, 43.4)),
	# 3 Guard Room (x 50-60, z 34-46; doors west and east at z 40). Cots along the north wall (left as you come in),
	# heads to the wall, the armour stand in the corner beside them; mess shelf and trestle further along; shields and
	# crossbows on the wall facing you; helmets just inside the door; the last watch's table and the fallen spear rack.
	("mg_guard_cot", "guard_room", W(_d("mg_guard_cot"), "n", 34, 51.9)),
	("mg_guard_cot", "guard_room", W(_d("mg_guard_cot"), "n", 34, 53.0)),
	("mg_guard_cot", "guard_room", W(_d("mg_guard_cot"), "n", 34, 54.1)),
	("mg_armour_stand", "guard_room", decor.corner(_d("mg_armour_stand"), "n", 34, "w", 50)),
	("mg_bowl_shelf", "guard_room", W(_d("mg_bowl_shelf"), "n", 34, 56.2)),
	("mg_mess_trestle", "guard_room", decor.mid(_d("mg_mess_trestle"), 54.2, 37.55, 0.0)),  # (owner, Nov 22: out in the room)
	("mg_shield_wall", "guard_room", W(_d("mg_shield_wall"), "e", 60, 43.2)),
	("mg_crossbow_rack", "guard_room", W(_d("mg_crossbow_rack"), "e", 60, 44.95)),
	("mg_helmet_pegs", "guard_room", W(_d("mg_helmet_pegs"), "w", 50, 43.6)),
	("mg_last_watch", "guard_room", decor.mid(_d("mg_last_watch"), 53.0, 42.4, 0.0)),
	("mg_spear_rack_fallen", "guard_room", W(_d("mg_spear_rack_fallen"), "s", 46, 56.3)),
	# 4 Store Room (x 62-70, z 36-44; doors west, east (the gate) and the cracked wall north): everything along the
	# south wall, the rope board right of the door, the collapsed shelf in the far corner with its crate slid off.
	("mg_rope_wall", "store_room", W(_d("mg_rope_wall"), "w", 62, 43.0)),
	("mg_water_butt", "store_room", W(_d("mg_water_butt"), "s", 44, 63.1)),
	("mg_supply_shelf", "store_room", W(_d("mg_supply_shelf"), "s", 44, 64.4)),
	("mg_grain_bin", "store_room", W(_d("mg_grain_bin"), "s", 44, 65.7)),
	("mg_collapsed_shelf", "store_room", decor.corner(_d("mg_collapsed_shelf"), "s", 44, "e", 70)),
	("mg_crate_pried_open", "store_room", decor.mid(_d("mg_crate_pried_open"), 66.9, 41.85, 15.0)),
	# 9 Pillar Hall (x 24-46, z 16-30; the spike pit in the middle). The carpenter's corner by the east wall between
	# the columns; the cold cook spot by the west columns; two root-gripped stone columns beside the real ones.
	("mg_wheelbarrow", "pillar_hall", W(_d("mg_wheelbarrow"), "e", 46, 21.5)),
	("mg_sawhorse_left", "pillar_hall", W(_d("mg_sawhorse_left"), "e", 46, 23.0)),
	("mg_tool_chest", "pillar_hall", W(_d("mg_tool_chest"), "e", 46, 24.9)),
	("mg_cookpot_tripod", "pillar_hall", decor.mid(_d("mg_cookpot_tripod"), 26.4, 27.2, 0.0)),
	("column_rootwrapped", "pillar_hall", decor.mid(_d("column_rootwrapped"), 30.6, 21.6, 0.0)),
	("column_rootwrapped", "pillar_hall", decor.mid(_d("column_rootwrapped"), 31.8, 19.4, 90.0)),
]
_items = [(_d(n), at[0], at[1], at[2], room) for n, room, at in DECOR]
_doorways = [(p["pos"][0], p["pos"][2]) for p in pieces if p["id"] == "doorway"]
_ways = [(p["pos"][0], p["pos"][2]) for p in props if p["model"] in ("dungeon/dungeon_entrance.glb", "dungeon/wall_cracked.glb")]
_low = lambda p: p["pos"][1] < 1.0  # on the floor (not torches, chains, stalactites' bases up high... see traps)
_flat = {"dungeon/floor_old.glb", "dungeon/wall_old.glb", "dungeon/wall_cracked.glb"}  # (the loose stone counts as a trap: keep off it)
_problems, _ = decor.check(_items, cells, junk.walk_lines(SPACES, group, cells, _doorways + _ways,
		[("chasm_room", [(34.0, 12.0), (34.0, 6.0), (46.0, 6.0)])]),
	doors=_doorways + _ways + [(p["pos"][0], p["pos"][2]) for p in props if p["role"] == "door" and "lever" not in p["model"]],
	things=[tuple(c["pos"][0::2]) for c in chests] + [(79.0, 5.2)] + [(p["pos"][0], p["pos"][2]) for p in props if "lever" in p["model"]],
	traps=[(p["pos"][0], p["pos"][2]) for p in props if p["role"] in ("trap", "secret") and p["model"] not in _flat and _low(p)],
	obstacles=[(p["pos"][0], p["pos"][2], max(junk.size(p["model"])[:2]) / 2) for p in props
		if _low(p) and p["role"] in ("decor", "light", "heal") and p["model"] not in _flat]
		+ [(p["pos"][0], p["pos"][2], 0.6) for p in pieces if p["id"] == "column" and p["pos"][1] < 1]
		+ [(c["pos"][0], c["pos"][2], 0.5) for c in creatures if c["pos"][1] < 1],
	keep_off=[[35.2, -1.0, 44.8, 13.0], [35.2, 19.2, 42.8, 26.8]])
if _problems:
	sys.exit("decor breaks the placement rules:\n  " + "\n  ".join(_problems))
props += decor.props(_items, lambda g: 0.0)
# A tall piece against a wall would stand through the cold torch holder hanging there (1.2 m up): that holder goes.
props = [p for p in props if p["model"] != "decor/furn_wall_torch_iron.glb" or not decor.blocks_wall_spot(_items, p["pos"])]

# --- 6. Junk (owner, Nov 20): along the walls and in the corners, never on a walk line or by a door, chest, lever or
# the recipe stand (tools/dungeons/junk.py; tests/test_dungeon_junk.gd). Mossgate is small: the "all 12" junk + the
# small dungeons' (wood shield, wood rubble, broken tools, snapped beam, helmet, lantern) + the old props; the Old Tombs
# also get broken urns and coffin chunks (owner, Nov 20). Its own dice, so nothing placed above moves.
JUNK_THEMES = {   # (owner, Nov 20, 2nd look in the game: "it needs a lot more, it still feels empty": more kinds, ~2x as many)
	# (owner, Nov 22: no kind twice in a room but candles and pots, and "more variety": many more kinds per room, old
	# props too, so the rooms past the Gate Hall and Guard Room hold real furniture-sized pieces like those two do)
	"gate_hall": ["beam_snapped", "rubble_wood", "rags", "crate_stack", "keg", "meal", "bones", "scrap", "lantern",
		"rubble_brick", "grain_sacks", "shield_wood", "furn_bucket_wood", "torch_dropped", "spear_broken", "furn_crate_iron"],
	"guard_room": ["sword_snapped", "spear_broken", "shield_wood", "shield_iron", "helmet", "axe_head", "armour_pile",
		"meal", "bones", "candles", "rags", "keg", "furn_dummy", "furn_whetstone", "furn_stool", "furn_bucket_metal"],
	"store_room": ["crate_stack", "grain_sacks", "ore_basket", "timber_stack", "rags", "rubble_wood", "keg", "scrap",
		"urns", "beam_snapped", "furn_bucket_wood", "furn_crate_iron", "tools", "furn_bucket_metal", "shack_stool"],
	"vault": ["bones", "rags", "lantern", "scrap", "urn_broken", "candles", "helmet", "axe_head", "furn_vase_wide",
		"furn_crate_iron"],
	"tombs": ["bones", "urn_broken", "coffin_piece", "coffin_lid", "rags", "candles", "statue_head", "urns", "helmet",
		"sword_snapped", "shield_iron", "torch_dropped", "lantern", "rubble_brick", "stone_stool", "furn_bench_long",
		"scrap", "axe_head", "armour_pile", "spear_broken"],
	"shrine": ["bones", "rags", "candles", "statue_head", "urn_broken", "lantern", "rubble_brick", "stone_stool", "scrap",
		"axe_head", "shield_wood", "urns", "torch_dropped", "furn_bucket_metal", "furn_vase_tall", "furn_vase_wide",
		"helmet", "sword_snapped", "furn_bench_long", "rubble_wood"],
	"pillar_hall": ["beam_snapped", "rubble_wood", "rubble_brick", "bones", "tools", "mine_cart", "timber_stack",
		"statue_head", "scrap", "rags", "ore_basket", "firewood_rack", "furn_bucket_wood", "lantern", "torch_dropped",
		"helmet", "crate_stack", "grain_sacks", "keg", "furn_crate_iron", "shack_stool", "furn_anvil_log", "furn_whetstone",
		"furn_bucket_metal", "shield_wood", "spear_broken", "axe_head", "armour_pile", "urns", "urn_broken",
		"cookpot_tipped", "furn_barrel_rack", "shack_table", "furn_stool", "meal", "candles", "sword_snapped"],
	"chasm_room": ["bones", "lantern", "helmet", "rags", "spear_broken", "rubble_brick", "scrap", "beam_snapped",
		"rubble_wood", "torch_dropped", "shield_wood", "sword_snapped", "tools", "ore_basket", "crate_stack",
		"furn_bucket_wood", "keg", "timber_stack", "axe_head", "armour_pile", "furn_crate_iron", "shield_iron", "meal",
		"mine_cart"],
	"crusher_hall": ["bones", "rags", "helmet", "armour_pile", "scrap", "rubble_brick", "torch_dropped", "shield_iron"],
	"pack_hall": ["bones", "helmet", "shield_wood", "shield_iron", "rags", "sword_snapped", "meal", "armour_pile",
		"spear_broken", "scrap", "axe_head", "beam_snapped", "rubble_wood", "cookpot_tipped", "lantern", "torch_dropped",
		"furn_stool", "furn_bucket_wood", "keg", "crate_stack", "urns", "urn_broken", "rubble_brick", "tools",
		"grain_sacks", "furn_crate_iron", "timber_stack", "furn_bench_long", "shack_stool", "statue_head", "campfire_cold",
		"furn_bucket_metal", "ore_basket", "candles", "furn_table_long", "furn_barrel_rack"],
	"loot_room": ["helmet", "axe_head", "rags", "bones", "scrap", "candles", "armour_pile", "shield_iron", "sword_snapped",
		"urns", "statue_head", "lantern", "furn_crate_iron", "urn_broken", "furn_drawers", "shield_wood"],
}
# How many (owner, Nov 22: "look at the first room and the room to the right... see their size versus how many things
# are in there and learn from it"): those two hold about 1.8 pieces per 10 m2 (furniture, decor, chests and junk
# together; about half of it furniture-sized), the rest held 0.6-1.4. Every other room gets as much, counted on the floor
# you can stand on (not the chasm or the spike pit); the Pack Hall a little less (1.5: you fight the pack in it). The
# Gate Hall and Guard Room keep their counts.
DENSITY = {"pack_hall": 1.5}
_keep_off = [[35.2, -1.0, 44.8, 13.0], [35.2, 19.2, 42.8, 26.8], [31.0, 56.0, 37.0, 61.0]]  # the chasm and the spike pit (and their edges); the way in past the map, through the cave wall
_counts = {"gate_hall": 15, "guard_room": 12}
for g in ROOMS - set(_counts):
	floor = [c for c, cg in cells.items() if cg == g and not any(in_r[0] <= c[0] + 1 <= in_r[2] and in_r[1] <= c[1] + 1 <= in_r[3] for in_r in _keep_off)]
	there = sum(1 for p in props if _low(p) and p["role"] in ("decor", "light", "heal") and p["model"] not in _flat
		and cells.get(junk.cell_of(p["pos"][0], p["pos"][2])) == g) + sum(1 for c in chests if cells.get(junk.cell_of(c["pos"][0], c["pos"][2])) == g)
	_counts[g] = max(2, round(DENSITY.get(g, 1.8) * len(floor) * 4 / 10) - there)
print("junk per room:", dict(sorted(_counts.items())))
props += junk.place_junk(
	SPACES, group, cells, lambda g: 0.0, ROOMS, JUNK_THEMES,
	doors=_doorways + _ways + [(p["pos"][0], p["pos"][2]) for p in props if p["role"] == "door" and "lever" not in p["model"]],
	path_doors=_doorways + _ways,
	things=[tuple(c["pos"][0::2]) for c in chests] + [(79.0, 5.2)] + [(p["pos"][0], p["pos"][2]) for p in props if "lever" in p["model"]],
	traps=[(p["pos"][0], p["pos"][2]) for p in props if p["role"] in ("trap", "secret") and p["model"] not in _flat],
	furniture=[(p["pos"][0], p["pos"][2], max(junk.size(p["model"])[:2]) / 2) for p in props
		if _low(p) and p["role"] in ("decor", "light", "heal") and p["model"] not in _flat]
		+ [(p["pos"][0], p["pos"][2], 0.6) for p in pieces if p["id"] == "column" and p["pos"][1] < 1]
		+ [(p["pos"][0], p["pos"][2], 1.0) for p in pieces if p["id"] == "spear_rack"]
		+ [(c["pos"][0], c["pos"][2], 0.8) for c in creatures if c["pos"][1] < 1],
	seed=2011,
	keep_off=_keep_off,
	extra_paths=[("chasm_room", [(34.0, 12.0), (34.0, 6.0), (46.0, 6.0)])],  # over the bridge
	skip={"boulder_way", "loot_door"},
	big=(12, 16), small=(5, 7), repeat=3, tunnel_every=8.0, counts=_counts,  # (owner, Nov 20: "a lot more")
)

# --- 7. Dark (owner, Nov 20, F517: "dungeon 2 is dark, dungeon 1 should be dark as well"; picked "almost no light"):
# only the torch nearest the way in still burns, and the faint glow down in the spike pit stays (owner, Nov 20: see the
# spikes). The other torches hang cold on the walls (the torch model is just its iron holder: the light was its flame).
_way_in = min(lights, key=lambda l: math.hypot(l[0] - 34.0, l[2] - CAVE_Z))
lights = [l for l in lights if l is _way_in or l == [39.0, -2.6, 23.0]]

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
