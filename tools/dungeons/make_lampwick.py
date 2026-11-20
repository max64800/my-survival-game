# Lampwick Drift (dungeon map 2): every root wood piece, rail, trap, lamp, piece of furniture, chest and creature, laid
# out on the dungeon's rooms (read from src/world/dungeon_map.gd's LAMPWICK, so the rock and the pieces always match).
#   python tools/dungeons/make_lampwick.py   -> blueprints/dungeons/lampwick_drift.json (the game builds from it)
# Positions are the dungeon's own metres (x right, z toward the cave, y up), like DungeonMap. The plan:
# docs/design/zone1-dungeons/02-lampwick-drift.md. Owner, Nov 20: no 3D page this time, "just do the dungeon".
# Two levels: 0 (Lamp Room, Rail Tunnel) and UP = 3 m (everything after the Cart Junction's climbing rails). The Back
# Rails run down again to the Lamp Room's barred gate. Rails slope 0.5 m per 2 m lane piece (14.5 degrees): the lane
# pieces meet end to end, so a 12 m climb of 6 pieces covers 11.62 m of floor.
import json, math, random, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = (ROOT / "src/world/dungeon_map.gd").read_text(encoding="utf-8").split("const LAMPWICK")[1].split("\n}\n")[0]
UP = 3.0
SPACES = []
for m in re.findall(r'\["(\w+)",([^\]]*)\]', SRC):
	SPACES.append([m[0]] + [float(eval(v, {"UP": UP})) for v in m[1].split(",")])
SP = {s[0]: s for s in SPACES}
MAT = "plank_root"
CAVE_Z = 64.0  # the round door at the end of the way in (DungeonMap.FACE: 4 m out from the mouth at z 60)
MOUTH_X = 26.0
rng = random.Random(2007)

TH = math.asin(0.25)        # the rails' slope: 0.5 m up per 2 m lane
C, S = math.cos(TH), 0.25
TILT = round(math.degrees(TH), 3)
JUNC_TOP, BACK_TOP = 22.0, 28.0          # where the climbing rails reach the upper level (z)
JUNC_LOW = JUNC_TOP + 12.0 * C           # their foot (z 33.62)
BACK_LOW = BACK_TOP + 12.0 * C           # (39.62)
RAIL_TOP = 0.36                          # a lane's rail top above its origin (the carts' wheels sit there)
FOOT_END = JUNC_LOW + 6.0                # the end of the level rails at the junction's foot (the stoppers)

GROUP = {"rail_bend": "rail_tunnel", "junction_top": "cart_junction", "back_rails_w": "back_rails",
	"shaft_n": "old_shaft", "shaft_s": "old_shaft"}
ROOMS = {"lamp_room", "tool_store", "copper_face", "miners_rest", "office"}   # root wood ceiling at 4 m
NATURAL = {"cart_junction", "drip_tunnel", "bat_gallery", "old_shaft", "back_rails"}  # rock overhead
TALL = ROOMS | {"cart_junction", "bat_gallery", "old_shaft"}  # two rows of walls (corridors: a wall + a half wall)
NO_PIECES = {(x, z) for x in (44, 46, 48) for z in (2, 4)}  # the niche: bare rock round the hidden boulder
OLD = 0.7          # about 70% of the floors and walls old and rotten (like Mossgate)
DOOR_SCALE = 1.5   # the round doorway at 1.5x: a hole about 2 m wide and 2.6 m high


def group(name):
	return GROUP.get(name, name)


def height(g):
	return 4 if g in TALL else 3


def space_of(x, z):
	"""The space of the 2 m cell whose corner is (x, z) (rooms win over the pits; None = rock)."""
	cx, cz = x + 1, z + 1
	for s in SPACES:
		if s[1] < cx < s[3] and s[2] < cz < s[4] and s[5] >= 0:
			return s[0]
	if MOUTH_X - 2 <= x < MOUTH_X + 2 and 60 <= z < CAVE_Z:
		return "entry"
	return None


def in_box(name, x, z):
	s = SP[name]
	return s[1] <= x < s[3] and s[2] <= z < s[4]


def ground(space, z):
	"""The floor's height in a space at z (the climbing rails slope; every other floor is level)."""
	if space == "cart_junction":
		return min(UP, max(0.0, (JUNC_LOW - z) * math.tan(TH)))
	if space == "back_rails":
		return min(UP, max(0.0, (BACK_LOW - z) * math.tan(TH)))
	return SP[space][5] if space in SP else 0.0


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


def creature(kind, x, z, yaw=0.0, floor=UP, wake=None):
	creatures.append({"kind": kind, "model": CREATURE_MODEL[kind], "pos": r3((x, floor + 0.25, z)), "yaw": yaw, "scale": 1.0,
		"floor": floor, **({"wake": wake} if wake else {})})


def chest(kind, x, z, yaw, label, sure=False, loot="random", y=None):
	"""A chest (the game makes it a real chest with loot: DungeonBuild.LOOT[loot]). Not `sure`: there in about 2 of 3 worlds."""
	chests.append({"kind": kind, "pos": r3((x, UP + 0.25 if y is None else y, z)), "yaw": yaw, "label": label, "always": sure, "loot": loot})


def slope_point(xc, z_top, s, h=0.0):
	"""A point on a climbing lane, s metres down the slope from its top (at height UP), h up from the lane's bed bottom."""
	return (xc, UP - s * S + h * C, z_top + s * C + h * S)


# --- 1. The cells: floors (root wood boards, some old), and root wood ceilings in rooms and corridors. ---
cells = {}
for x in range(0, 60, 2):
	for z in range(-4, int(CAVE_Z) + 2, 2):
		sp = space_of(x, z)
		if sp:
			cells[(x, z)] = (group(sp), sp)

SPECIAL_FLOOR = {(12, 18): "floor_loose_stone"}  # the Tool Store's loose stone (a buried chest under it)
GROOVED = {(x, z) for x in (28, 30, 32) for z in (2, 4)}  # the Old Shaft's walk under the boulder
for (x, z), (g, sp) in cells.items():
	if (x, z) in NO_PIECES or g == "vault":
		continue  # (the niche is bare rock; the vault's floor is the spike plate)
	cx, cz = x + 1.0, z + 1.0
	pit = g == "old_shaft" and (in_box("shaft_n", x, z) or in_box("shaft_s", x, z))
	if pit:
		pass  # the deep shaft: no floor
	elif sp == "cart_junction" or (sp == "back_rails" and z < 40):
		if z >= 34 or (sp == "back_rails" and z == 38):  # under the rails' level foot: boards 1 cm under the lane beds
			prop("dungeon/floor_old.glb", cx, -0.03, cz, rng.choice([0, 90, 180, 270]))
	elif (x, z) == (22, 48):
		prop("dungeon/rail_lane.glb", cx, 0.0, cz, 0.0)  # the Lamp Room's old cart stands on a bit of rail
	elif sp == "back_rails" or (sp == "back_rails_w" and x < 40):  # the rails run on to the gate
		prop("dungeon/rail_lane.glb", cx, 0.0, cz, 0.0 if sp == "back_rails" else 90.0)
	elif (x, z) in GROOVED:
		prop("dungeon/floor_grooved.glb", cx, UP, cz, 90.0, role="trap", label="Grooves (the boulder scrapes here)" if (x, z) == (30, 2) else "")
	elif (x, z) in SPECIAL_FLOOR:
		prop("dungeon/%s.glb" % SPECIAL_FLOOR[(x, z)], cx, SP[sp][5], cz, 0.0, role="secret", label="Loose stone")
	elif rng.random() < OLD:
		prop("dungeon/floor_old.glb", cx, SP[sp][5], cz, rng.choice([0, 90, 180, 270]))
	else:
		piece("floor", cx, SP[sp][5], cz, 0)
	if g in NATURAL:
		continue
	top = SP[sp][5] + float(height(g))
	if rng.random() < OLD:  # old boards upside down: their worn, gappy side faces down at you (like Mossgate)
		prop("dungeon/floor_old.glb", cx, top + 0.24, cz, rng.choice([0, 90, 180, 270]), tilt=180.0)
	else:
		piece("floor", cx, top, cz, 0)

# --- 2. Walls round every room (rock behind them) and doorways where two groups meet. ---
DIRS = [((-2, 0), "w"), ((2, 0), "e"), ((0, -2), "n"), ((0, 2), "s")]
INWARD_YAW = {"w": 90.0, "e": 270.0, "n": 0.0, "s": 180.0}  # a wall model's front (+z) turned to face into the room
junctions = {}
rock_edges = []
for (x, z), (g, sp) in cells.items():
	if (x, z) in NO_PIECES:
		continue
	for (dx, dz), side in DIRS:
		other = cells.get((x + dx, z + dz))
		if side in "we":
			line, along, rot = (x if side == "w" else x + 2), z + 1.0, 1
		else:
			line, along, rot = (z if side == "n" else z + 2), x + 1.0, 0
		if other and other[0] == g:
			continue
		if other is None:
			if g == "entry" and side == "s":
				continue  # the cave
			# the wall's foot: the lower end of the cell's floor (the climbing rails slope along z)
			y0 = min(ground(sp, z), ground(sp, z + 2)) if side in "we" else ground(sp, line)
			rock_edges.append((g, sp, side, line, along, rot, (x, z), y0))
		elif (x + dx, z + dz) not in NO_PIECES:
			key = (min(g, other[0]), max(g, other[0]), side in "we", line)
			y0 = max(ground(sp, along if side in "we" else line), ground(other[1], along if side in "we" else line))
			junctions.setdefault(key, {"spots": set(), "y": 0.0})
			junctions[key]["spots"].add(along)
			junctions[key]["y"] = max(junctions[key]["y"], y0)


def wall_pos(rot, line, along):
	return (line, along) if rot == 1 else (along, line)


# The tripwire's dart wall: the Rail Tunnel's west wall at z 40-42 (its hole shoots across the tunnel).
DART = {("rail_tunnel", "w", 24, 41.0)}
lamp_every = {}
LAMPS = []
for g, sp, side, line, along, rot, cell, y0 in rock_edges:
	x, z = wall_pos(rot, line, along)
	yaw = INWARD_YAW[side]
	for r in range(2):
		y = y0 + 2.0 * r
		if r == 1 and height(g) == 3:
			piece("half_wall", x, y, z, rot)
		elif r == 0 and (g, side, line, along) in DART:
			prop("dungeon/trap_tripwire_wall.glb", x, y, z, yaw, role="trap", label="Dart hole (green stain under it)")
		elif rng.random() < OLD:
			prop("dungeon/wall_old.glb", x, y, z, yaw)
		else:
			piece("wall", x, y, z, rot)
	# An old mine lamp on about every third wall of a room, every fourth of a corridor (unlit: E lights it). None in
	# the vault, the niche, the junction's slope (the carts) or over the deep shaft.
	n = lamp_every.get(g, 0)
	lamp_every[g] = n + 1
	over_pit = g == "old_shaft" and side in "ns"
	if g not in ("vault", "entry") and not over_pit and not (sp == "cart_junction" and cell[1] < 34) \
			and n % (3 if g in TALL else 4) == 1:
		ox, oz = {"w": (0.15, 0), "e": (-0.15, 0), "n": (0, 0.15), "s": (0, -0.15)}[side]
		prop("dungeon/mine_lamp.glb", x + ox, y0 + 1.75, z + oz, yaw, role="lamp", label="Old mine lamp (E: light it)",
			floor=y0)
		LAMPS.append((x + ox, z + oz))

# Junctions: the round doorway (1.5x) in the middle of a 4 m opening, 1 m narrow walls beside it, two high, a half
# wall over it up to a taller room's ceiling. Special ones: the cracked wall to the vault, the barred way-out gate.
SPECIAL_J = {("bat_gallery", "vault"): "cracked", ("back_rails", "lamp_room"): "gate",
	("office", "office_door"): "hand_door"}  # (owner, Nov 20: a door you open, so you can't see the boss from outside)
for (a, b, along_z, line), jn in junctions.items():
	spots = sorted(jn["spots"])
	y = jn["y"]
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
		# The lever: on the Back Rails' north wall, 1.2 m past the gate, its back on the boards' face.
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

# --- 4. The rooms, one by one (the plan's 13 spaces). F = the upper level's floor top for furniture. ---
F = UP + 0.25

# 1 Lamp Room: an old cart on its bit of rail, crates, a chest. The barred gate on the east wall (above).
prop("dungeon/trap_cart.glb", 23.0, RAIL_TOP, 49.0, 0.0, label="An old ore cart")
prop("decor/crate_stack.glb", 23.0, 0.25, 51.2, 20.0)
prop("decor/keg.glb", 27.2, 0.25, 51.2, 0.0)
chest("chest_small", 26.6, 46.9, 0.0, "Random chest", y=0.25)

# 2 Rail Tunnel: a thin white wire across at ankle height, from the dart hole's sill to the far wall (cut it, or step
# over it). The dart wall model's hole is 0.12 m along its face from its middle (toward -z here).
WIRE_Z = 41.0 - 0.12
prop("dungeon/tripwire.glb", 26.0, 0.24, WIRE_Z, 0.0, role="trap", label="Tripwire (step over it, or cut it)",
	stretch=round(4.0 - 0.3, 2))
prop("dungeon/rail_wedge.glb", 27.0, 0.24, 44.2, 200.0)  # (broken bits of old rail gear lying about)
prop("decor/crate_stack.glb", 27.1, 0.25, 36.9, 60.0)

# 3 Cart Junction: three lanes climbing north (x 16-18, 18-20, 20-22), each with a cart held at the top by a rotten
# wedge. Step into a lane and its wedge snaps: that cart comes down at you (a rattle first). It crashes into the
# stopper at the foot and stays there. Two level lane pieces at the foot hold the stoppers.
for i in range(3):
	xc = 17.0 + 2.0 * i
	for k in range(6):
		px, py, pz = slope_point(xc, JUNC_TOP, 11.0 - 2.0 * k)
		prop("dungeon/rail_lane.glb", px, py, pz, 0.0, tilt=TILT)
	for zc in (JUNC_LOW + 1.0, JUNC_LOW + 3.0, JUNC_LOW + 5.0):  # (3 level pieces: a crashed cart stops past the doorway)
		prop("dungeon/rail_lane.glb", xc, 0.0, zc, 0.0)
	prop("dungeon/rail_buffer.glb", xc, 0.0, FOOT_END - 0.47, 0.0)
	start = slope_point(xc, JUNC_TOP, 1.0, RAIL_TOP)
	foot = slope_point(xc, JUNC_TOP, 12.0, RAIL_TOP)
	stop = (xc, RAIL_TOP, FOOT_END - 0.47 - 0.29 - 0.86)
	prop("dungeon/trap_cart.glb", *start, 0.0, role="trap", tilt=TILT, label="Cart (its lane's wedge snaps when you step in)" if i == 0 else "",
		path=[r3(start), r3(foot), r3(stop)], lane=[xc - 1.0, JUNC_TOP, xc + 1.0, FOOT_END])
	prop("dungeon/rail_wedge.glb", *slope_point(xc, JUNC_TOP, 1.0 + 0.45 + 0.17, RAIL_TOP), 0.0, role="trap", tilt=TILT,
		label="Rotten wedge" if i == 0 else "")
for i, (x, z) in enumerate([(17.5, 19.6), (20.4, 20.6), (19.0, 18.8)]):
	creature("tunnel_rat", x, z, 180.0 + i * 40.0, wake=["cart_junction"])  # (they get up as you come in below, owner Nov 20)

# 4 Tool Store: shelves, a barrel rack, crates; the loose stone with a buried chest under it.
prop("decor/shack_shelf.glb", 13.0, F, 16.45, 0.0)
prop("decor/furn_barrel_rack.glb", 10.7, F, 20.0, 90.0)
prop("decor/crate_stack.glb", 15.0, F, 21.2, 30.0)
prop("decor/firewood_rack.glb", 10.6, F, 17.4, 90.0)
chest("chest_small", 13.0, 19.0, 90.0, "Buried chest (under the loose stone)", True, "buried")
chest("chest_small", 15.2, 17.2, 270.0, "Random chest")

# 5 Drip Tunnel: stalactites low over the way (shoot them down first, or run); rats.
DRIP_Y = UP + 4.5 + 0.6
for x, z, m in [(19.2, 15.4, "trap_drip_fat"), (20.8, 12.6, "trap_drip_cluster"), (19.6, 9.8, "trap_drip_thin")]:
	prop("dungeon/%s.glb" % m, x, DRIP_Y, z, rng.choice([0, 120, 240]), role="trap", tilt=180.0, floor=UP, warn=0.35, fall=0.45,
		label="Stalactite (cracks and dust)" if m == "trap_drip_fat" else "")
for x, z in [(20.6, 16.4), (19.4, 11.2)]:
	creature("tunnel_rat", x, z, 0.0)

# 6 Bat Gallery: tall and dark, rats; old props and rubble; the cracked wall on the west (to the vault). Bear jaws by
# the rubble.
for x, z, yaw in [(14.33, 6.0, 90.0), (23.67, 1.2, 270.0)]:
	piece("mine_prop", x, UP, z, 1)
prop("dungeon/rubble_ore.glb", 22.6, F, 6.6, 40.0)
prop("dungeon/trap_bear_jaws.glb", 19.4, UP + 0.24, 1.6, 20.0, role="trap", label="Bear jaws (a rusty glint in the dust)")
for i, (x, z) in enumerate([(16.2, 2.0), (18.0, 6.2), (21.0, 3.0), (22.4, 4.6)]):
	creature("tunnel_rat", x, z, i * 90.0)

# 7 Hidden Vault (behind the cracked wall): a 2 x 4 m dead end, its floor full of spike holes. The chest sits on the
# far square. Shoot the chest (or the floor) and the spikes slam up and go down again: then it's safe to open.
prop("dungeon/trap_chest_spikes.glb", 12.0, UP, 3.0, 90.0, role="trap", label="Spike holes round the chest")
chest("chest_stone", 11.0, 3.0, 90.0, "Vault chest (always): shoot it first", True, "vault")

# 8 The Old Shaft: a 4 m plank walk over the deep shaft, railings each side (two broken), the boulder on its chain
# swinging along the walk (grooves under it, a creaking chain). Shoot the chain and it drops.
for x in (29.0, 31.0, 33.0, 35.0):
	for zl in (2.0, 6.0):
		if (x, zl) in ((31.0, 6.0), (35.0, 2.0)):
			prop("dungeon/railing_broken.glb", x, UP + 0.24, zl, 0.0 if zl == 6.0 else 180.0)
		else:
			piece("railing", x, UP + 0.24, zl, 0)
prop("dungeon/trap_swing_boulder.glb", 31.0, UP, 4.0, 90.0, role="trap", label="Swinging boulder (shoot the chain)")
for x in range(28, 36, 2):
	for z in (0, 6):
		prop("dungeon/trap_spikes.glb", x + 1.0, UP - 6.0, z + 1.0, rng.choice([0, 90, 180, 270]), role="trap",
			label="The shaft (falling in kills)" if (x, z) == (30, 0) else "")
lights.append([32.0, UP - 4.5, 1.0])  # (a faint glow far down: you see how deep it is)
lights.append([32.0, UP - 4.5, 7.0])

# 9 Old Copper Face: rubble and ore, Lost Miners, bear jaws (one in a pile's dust, one bare), the hidden boulder in
# the east wall with a chest behind it.
prop("dungeon/rubble_ore.glb", 39.4, F, 1.4, 10.0)
prop("dungeon/trap_bear_jaws.glb", 39.4, UP + 0.26, 1.4, 70.0, role="trap", label="Bear jaws in the dust")
prop("dungeon/rubble_ore.glb", 42.8, F, 1.3, 200.0)  # (an empty one: every pile has the dust, so it gives nothing away)
prop("dungeon/trap_bear_jaws.glb", 41.0, UP + 0.24, 4.0, 150.0, role="trap")
prop("decor/crate_stack.glb", 38.8, F, 5.2, 0.0)
prop("cave/boulder_round.glb", 45.6, UP, 4.0, 30.0, scale=3.0, role="secret", label="Hidden boulder (hit it)")
chest("chest_small", 48.9, 4.0, 270.0, "Niche chest (always)", True, "buried", y=UP)
for x, z in [(40.2, 2.6), (42.6, 3.8)]:
	creature("lost_miner", x, z, 0.0)

# 10 Prop Corridor: old props hold up the roof along both walls; rats in the dark; bear jaws.
for z in (8.0, 10.6):  # (west wall: none in front of the Miners' Rest doorway, z 12.5-15.5: owner, Nov 20, it blocked the way)
	piece("mine_prop", 40.33, UP, z, 1)
for z in (8.0, 11.0, 14.0):
	piece("mine_prop", 43.67, UP, z, 1)
prop("dungeon/trap_bear_jaws.glb", 42.6, UP + 0.24, 10.2, 100.0, role="trap")
for i, (x, z) in enumerate([(41.0, 9.0), (43.0, 12.6), (41.4, 14.6)]):
	creature("tunnel_rat", x, z, 180.0 + i * 30.0)

# 11 Miners' Rest: the healing basin in a ring of rubble, a bench, a table, a chest.
prop("dungeon/rubble_ore.glb", 35.0, F, 13.0, 0.0)
prop("decor/mushroom_fountain.glb", 35.0, F + 0.01, 13.0, 0.0, role="heal", label="Healing basin")
lights.append([35.0, UP + 1.6, 13.0])
prop("decor/shack_bench.glb", 37.4, F, 11.0, 270.0)
prop("decor/shack_table.glb", 33.2, F, 11.0, 0.0)
prop("decor/shack_stool.glb", 33.2, F, 12.2, 0.0)
chest("chest_small", 33.0, 15.4, 180.0, "Random chest")

# 12 The Foreman's Office: the Foreman and his Lost Miners, the recipe stand, the big chest, a desk and shelves.
creature("foreman", 43.0, 23.5, 0.0)
for x, z in [(40.2, 21.0), (45.8, 21.0), (44.6, 26.4)]:
	creature("lost_miner", x, z, 0.0)
RECIPE_STAND = {"pos": [47.2, F, 23.0], "yaw": 270.0, "page": "scroll_lampwick"}
prop("dungeon/recipe_stand.glb", 47.2, F, 23.0, 270.0, role="loot", label="Recipe stand (same recipe every time)")
prop("dungeon/recipe_scroll.glb", 47.2 - 0.007, F + 0.90, 23.0, 270.0, role="loot", tilt=20.0)
chest("chest_copper", 47.2, 19.4, 270.0, "The Foreman's chest (always)", True, "big")
prop("decor/shack_table.glb", 39.6, F, 26.4, 90.0)
prop("decor/shack_stool.glb", 40.8, F, 26.4, 270.0)
prop("decor/shack_shelf.glb", 39.0, F, 18.45, 0.0)
prop("treasure/tr_coins_wide.glb", 46.6, F, 26.8, 20.0)

# 13 Back Rails: two rails climbing down south from the office to the level, then west to the gate (lever above).
for i in range(2):
	xc = 41.0 + 2.0 * i
	for k in range(6):
		px, py, pz = slope_point(xc, BACK_TOP, 11.0 - 2.0 * k)
		prop("dungeon/rail_lane.glb", px, py, pz, 0.0, tilt=TILT)

# Owner, Nov 20: stalactites at the end of the Back Rails too (the level stretch and the way to the gate).
for x, z, y, m in [(42.4, 43.4, 7.0, "trap_drip_fat"), (34.0, 48.6, 3.5, "trap_drip_thin"), (30.8, 47.3, 3.5, "trap_drip_thin")]:
	prop("dungeon/%s.glb" % m, x, y + 0.6, z, rng.choice([0, 120, 240]), role="trap", tilt=180.0, floor=0.0, warn=0.35, fall=0.45)

# --- Write it out. ---
missing = sorted({p["model"] for p in props if not (ROOT / "assets/models" / p["model"]).exists()} |
	{c["model"] for c in creatures if not (ROOT / "assets/models" / c["model"]).exists()} |
	{"build/%s__%s.glb" % (p["id"], p["mat"]) for p in pieces if not (ROOT / ("assets/models/build/%s__%s.glb" % (p["id"], p["mat"]))).exists()})
if missing:
	sys.exit("missing models: %s" % missing)
plan = {"name": "Lampwick Drift", "map": "lampwick", "pieces": pieces, "props": props, "creatures": creatures,
	"chests": chests, "lights": lights, "recipe_stand": RECIPE_STAND}
out = ROOT / "blueprints/dungeons/lampwick_drift.json"
out.write_text(json.dumps(plan, indent=0, separators=(",", ":")), encoding="utf-8")
print("WROTE %s: %d pieces, %d props (%d lamps), %d creatures, %d chests, %d junctions" % (out.name, len(pieces), len(props),
	len(LAMPS), len(creatures), len(chests), len(junctions)))
