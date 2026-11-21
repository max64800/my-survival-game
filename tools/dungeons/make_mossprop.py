# Mossprop Workings (dungeon map 4): one tall mossy cave you climb. Old miners bolted a timber prop tower up its north
# cliff (decks at 5 and 10 m) to reach rooms they dug into the rock behind it. Everything is old and rotten (owner,
# Nov 21: "we need a lot more rotten wood, right now it looks perfect"). The way back down: a rope slide from the top
# deck to Base Camp (E at its top post). Plan + choices: docs/design/zone1-dungeons/04-mossprop-workings.md and
# 2026-11-21-mossprop-decisions.md (boss: the Prop Warden). Owner, Nov 21: no 3D page for dungeons, build it in the game.
#   python tools/dungeons/make_mossprop.py   -> blueprints/dungeons/mossprop_workings.json (the game builds from it)
# Positions are the dungeon's own metres (x right, z toward the cave you come in from, y up), like DungeonMap. The rooms
# are read from src/world/dungeon_map.gd's MOSSPROP, so the rock and the pieces always match.
import json, random, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = (ROOT / "src/world/dungeon_map.gd").read_text(encoding="utf-8").split("const MOSSPROP")[1].split("\n}\n")[0]
SPACES = []
for m in re.findall(r'\["(\w+)",([^\]]*)\]', SRC):
	SPACES.append([m[0]] + [float(v) for v in m[1].split(",")])
SP = {s[0]: s for s in SPACES}
MAT = "plank_root"
MOUTH_X, MOUTH_Z = 30.0, 60.0
CAVE_Z = MOUTH_Z + 4.0   # the round door at the end of the way in (DungeonMap.FACE)
rng = random.Random(4041)
OLD = 0.85               # rotten: most boards, walls and timbers are the old models (owner, Nov 21)
DOOR_SCALE = 1.5         # the round doorway at 1.5x in a 4 m opening (like the other dungeons)
L2, L3 = 5.0, 10.0       # the two decks (and the rooms behind them)

pieces, props, creatures, chests, lights = [], [], [], [], []


def r3(v):
	return [round(float(c), 3) for c in v]


def piece(pid, x, y, z, rot=0, scale=1.0):
	pieces.append({"id": pid, "mat": MAT, "pos": r3((x, y, z)), "rot": rot, **({"scale": scale} if scale != 1.0 else {})})


def prop(model, x, y, z, yaw=0.0, scale=1.0, role="decor", label="", tilt=0.0, **extra):
	props.append({"model": model, "pos": r3((x, y, z)), "yaw": round(yaw, 2), "scale": scale, "role": role, "label": label,
		**({"tilt": tilt} if tilt else {}), **extra})


MODEL = {"tunnel_rat": ["creatures/tunnel_rat_rust.glb", "creatures/tunnel_rat_grime.glb", "creatures/tunnel_rat_soot.glb"],
	"lost_miner": ["creatures/lost_miner_frost.glb", "creatures/lost_miner_rime.glb", "creatures/lost_miner_ghost.glb"],
	"prop_warden": ["creatures/foreman.glb"]}


def creature(kind, x, z, yaw=0.0, floor=0.0, wake=None):
	creatures.append({"kind": kind, "model": rng.choice(MODEL[kind]), "pos": r3((x, floor + 0.25, z)), "yaw": yaw,
		"scale": 1.0, "floor": floor, **({"wake": wake} if wake else {})})


def chest(kind, x, z, yaw, label, sure=False, loot="random", y=0.25):
	"""A chest (DungeonBuild.LOOT[loot]). Not `sure`: there in about 2 of 3 worlds."""
	chests.append({"kind": kind, "pos": r3((x, y, z)), "yaw": yaw, "label": label, "always": sure, "loot": loot})


def old_or(model_old, x, y, z, yaw, pid, rot, chance=OLD, **kw):
	"""The rotten model most of the time, else the plain root wood piece."""
	if rng.random() < chance:
		prop(model_old, x, y, z, yaw, **kw)
	else:
		piece(pid, x, y, z, rot)


# ---- 1. Rooms dug into the rock: rotten floors, walls, ceilings; 4 m round doorways where the ways go. ----
WALLED = ["entry", "tool_niche", "prop_room", "store_shed", "vault", "climbers_rest", "gallery", "roost", "hall_door",
	"top_hall"]
NO_CEILING = {"gallery"}                     # the crushers hang from the rock up there
DARK = {"vault", "tool_niche"}               # no torch: your lantern
INWARD_YAW = {"w": 90.0, "e": 270.0, "n": 0.0, "s": 180.0}
# Openings: (room, side, middle) -> kind. Every one is 4 m wide (a 1.5x round doorway, 1 m narrow walls beside it).
OPEN = {("tool_niche", "e", 28): "door", ("prop_room", "s", 22): "door", ("store_shed", "s", 26): "door",
	("climbers_rest", "w", 30): "door", ("gallery", "s", 22): "door", ("gallery", "w", 16): "door",
	("roost", "e", 16): "door", ("gallery", "e", 14): "door", ("hall_door", "w", 14): "door",
	("hall_door", "e", 14): "door", ("top_hall", "w", 14): "door", ("top_hall", "s", 38): "gate",
	("store_shed", "n", 26): "cracked", ("vault", "s", 26): "cracked"}
OPEN_SIDES = {("entry", "n"), ("entry", "s")}  # the cave end, and the round stone door's wall (below)
DART = ("prop_room", "w", 21.0)                # the dart wall: its middle 2 m of the west wall
SPEAR = ("climbers_rest", "w", 33.0)           # a spear wall stabs out across the deck by the upper ladder


def wall_h(name):
	h = SP[name][6]
	return 3.0 if h < 4 else (4.0 if h < 6 else 6.0)


done_edges = set()
torch_n = {}
for name in sorted(WALLED, key=lambda n: -wall_h(n)):   # (the taller room puts the shared wall up once)
	_, x0, z0, x1, z1, fy, _h = SP[name]
	if name == "entry":
		z1 = CAVE_Z
	wh = wall_h(name)
	for x in range(int(x0), int(x1), 2):
		for z in range(int(z0), int(z1), 2):
			cx, cz = x + 1.0, z + 1.0
			old_or("dungeon/floor_old.glb", cx, fy, cz, rng.choice([0, 90, 180, 270]), "floor", 0)
			if name in NO_CEILING:
				continue
			if rng.random() < OLD:  # old boards upside down: their worn, gappy side faces down at you
				prop("dungeon/floor_old.glb", cx, fy + wh + 0.24, cz, rng.choice([0, 90, 180, 270]), tilt=180.0)
			else:
				piece("floor", cx, fy + wh, cz, 0)
	edges = [("w", x0, z, 1) for z in range(int(z0), int(z1), 2)] + [("e", x1, z, 1) for z in range(int(z0), int(z1), 2)] \
		+ [("n", z0, x, 0) for x in range(int(x0), int(x1), 2)] + [("s", z1, x, 0) for x in range(int(x0), int(x1), 2)]
	opens = {(side, mid): kind for (room, side, mid), kind in OPEN.items() if room == name}
	for side, line, a, rot in edges:
		if (name, side) in OPEN_SIDES:
			continue
		along = a + 1.0
		x, z = (line, along) if rot == 1 else (along, line)
		key = (round(x, 2), round(z, 2), fy)
		if key in done_edges:
			continue
		done_edges.add(key)
		yaw = INWARD_YAW[side]
		hit = [(mid, kind) for (s2, mid), kind in opens.items() if s2 == side and mid - 2 <= a < mid + 2]
		if hit:
			mid, kind = hit[0]
			if a != mid - 2:
				continue  # the opening is built once, from its first 2 m
			ox, oz = (line, float(mid)) if rot == 1 else (float(mid), line)
			if kind == "cracked":
				if name == "store_shed":
					prop("dungeon/wall_cracked.glb", ox, fy, oz, 90.0 if rot == 1 else 0.0, role="secret",
						label="Cracked wall (hollow sound)", floor=fy)
				for k in (-1, 1):
					px, pz = (line, mid + k) if rot == 1 else (mid + k, line)
					for r in range(1, int(wh // 2)):
						piece("wall", px, fy + 2.0 * r, pz, rot)
				continue
			piece("doorway", ox, fy, oz, rot, DOOR_SCALE)
			if kind == "gate":
				prop("dungeon/gate_round.glb", ox, fy, oz, 90.0 if rot == 1 else 0.0, DOOR_SCALE, role="door",
					label="Barred gate: the short way out to the slide")
			for k in (-1.5, 1.5):
				px, pz = (line, mid + k) if rot == 1 else (mid + k, line)
				piece("wall_narrow", px, fy, pz, rot)
				piece("wall_narrow", px, fy + 2.0, pz, rot)
			if wh > 3:
				piece("half_wall", ox, fy + 3.0, oz, rot)
			for k in (-1, 1):
				px, pz = (line, mid + k) if rot == 1 else (mid + k, line)
				for r in range(2, int(wh // 2)):
					piece("wall", px, fy + 2.0 * r, pz, rot)
			continue
		for r in range(int(wh // 2) + (1 if wh % 2 else 0)):
			y = fy + 2.0 * r
			if wh % 2 and r == int(wh // 2):
				piece("half_wall", x, y, z, rot)
			elif r == 0 and (name, side, along) == DART:
				prop("dungeon/trap_dart_wall.glb", x, y, z, yaw, role="trap", label="Dart holes")
			elif r == 0 and (name, side, along) == SPEAR:
				prop("dungeon/trap_spear_wall.glb", x, y, z, 270.0, role="trap", label="Rows of holes (a stake tip shows)",
					phase=0.0)
			else:
				old_or("dungeon/wall_old.glb", x, y, z, yaw, "wall", rot)
		n = torch_n.get(name, 0)
		torch_n[name] = n + 1
		if name not in DARK and n % 4 == 1 and (name, side, along) not in (DART, SPEAR):
			ox, oz = {"w": (0.2, 0), "e": (-0.2, 0), "n": (0, 0.2), "s": (0, -0.2)}[side]
			prop("decor/furn_wall_torch_iron.glb", x + ox, fy + 1.2, z + oz, yaw, role="light")
			lights.append([round(x + ox * 3, 2), fy + 2.0, round(z + oz * 3, 2)])

# The way in: the round stone door where the tunnel meets the cave.
prop("dungeon/dungeon_entrance.glb", MOUTH_X, 0.0, CAVE_Z, 0.0, role="door", label="The way in: round stone door")
for x in (MOUTH_X - 1.5, MOUTH_X + 1.5):
	piece("wall_narrow", x, 0.0, CAVE_Z, 0)
for x in (MOUTH_X - 1.0, MOUTH_X + 1.0):
	piece("half_wall", x, 2.0, CAVE_Z, 0)

# ---- 2. The prop tower: the showpiece. Decks bolted to the cliff (z 24), their cave side held up by a timber face
# along z = 28.2: a prop frame (3 m) then a diagonal brace (2 m), stacked to 10 m (15 m over the chasm). Most timbers
# are the old ones; some braces have fallen out, some railings are broken or gone. ----
FRONT = 28.2
HOLE = (18, 24)   # the rockfall ladder comes up through here
deck2 = [(x, z) for x in range(18, 46, 2) for z in (24, 26) if (x, z) != HOLE and not 30 <= x < 38] + \
	[(44, z) for z in (28, 30, 32, 34)]
bridge = [(x, z) for x in range(30, 38, 2) for z in (24, 26)]
deck3 = [(x, z) for x in range(20, 46, 2) for z in (24, 26)] + [(44, z) for z in (28, 30, 32)]
BREAK = {(24, 26, L2), (40, 24, L2), (30, 26, L3)}   # rotten boards that give way (a 5 m fall)
for lv, cells in ((L2, deck2 + bridge), (L3, deck3)):
	for x, z in cells:
		cx, cz = x + 1.0, z + 1.0
		if (x, z, lv) in BREAK:
			prop("dungeon/trap_floor_break.glb", cx, lv, cz, rng.choice([0, 90, 180, 270]), role="trap",
				label="Rotten boards (they give way)" if (x, z) == (24, 26) else "")
		else:
			old_or("dungeon/floor_old.glb", cx, lv, cz, rng.choice([0, 90, 180, 270]), "floor", 0, chance=0.75)


def frame(x, y, z, east_arm=False):
	old_or("dungeon/prop_old.glb", x, y, z, 90.0 if east_arm else 0.0, "mine_prop", 1 if east_arm else 0, chance=0.75)


def brace(x, y, z, east_arm=False):
	if rng.random() < 0.15:
		return   # fallen out
	old_or("dungeon/brace_old.glb", x, y, z, 90.0 if east_arm else 0.0, "brace", 1 if east_arm else 0, chance=0.7)


def rail(x, y, z, rot, yaw, chance_broken=0.35, chance_gone=0.12):
	r = rng.random()
	if r < chance_gone:
		return
	if r < chance_gone + chance_broken:
		prop("dungeon/railing_broken.glb", x, y, z, yaw)
	else:
		piece("railing", x, y, z, rot)


for x in range(18, 46, 2):
	if x == 18:          # over the rockfall ledge: one frame on its boards up to the deck
		frame(x + 1, 2.24, FRONT)
	else:
		y = -5.0 if 30 <= x < 38 else 0.0
		while y < L3 - 0.1:
			frame(x + 1, y, FRONT)
			brace(x + 1, y + 3.0, FRONT)
			y += 5.0
	for lv in (L2, L3):
		if lv == L3 and x < 20:
			continue
		old_or("dungeon/beam_old.glb", x + 1, lv - 0.31, FRONT - 0.25, 0.0, "beam", 0, chance=0.75)
	if x == 44:
		continue         # the decks go on south along the east arm
	if 30 <= x < 38:     # the bridge: railings all along (one broken): the swinging boulder still shoves you
		if x == 32:
			prop("dungeon/railing_broken.glb", x + 1, L2 + 0.24, 27.85, 0.0)
		else:
			piece("railing", x + 1, L2 + 0.24, 27.85, 0)
	elif x != 18:
		rail(x + 1, L2 + 0.24, 27.85, 0, 0.0)
	if x >= 20 and x != 38:   # (bay 38: the slide's rope goes out over it)
		rail(x + 1, L3 + 0.24, 27.85, 0, 0.0)
# The east arm (Far Ledge and the top deck above it): its frames on the cave side, x = 43.8.
for z in (28, 30, 32, 34):
	frame(43.8, 0.0, z + 1, True)
	brace(43.8, 3.0, z + 1, True)
	rail(44.15, L2 + 0.24, z + 1, 1, 270.0)
	if z < 34:
		frame(43.8, 5.0, z + 1, True)
		brace(43.8, 8.0, z + 1, True)
		rail(44.15, L3 + 0.24, z + 1, 1, 270.0)
# The bridge's swinging boulder, and the chasm's spikes 10 m down (falling in kills).
prop("dungeon/trap_swing_boulder.glb", 34.0, L2, 26.0, 90.0, role="trap", label="Swinging boulder (shoot the chain)")
for x in range(30, 38, 2):
	for z in range(24, 34, 2):
		prop("dungeon/trap_spikes.glb", x + 1.0, -5.0, z + 1.0, rng.choice([0, 90, 180, 270]), role="trap",
			label="The chasm (falling in kills)" if (x, z) == (32, 28) else "")
lights.append([34.0, -3.5, 29.0])   # (a faint glow far down: you see how deep it is)
# The old hoist chains hanging from the top deck's beams.
for x, z in ((25.0, 27.9), (41.0, 27.9)):
	for k in range(3):
		prop("dungeon/chain_hanging.glb", x, L3 - 0.35 - 1.5 * k, z)

# ---- 3. Level 1: Base Camp, the Lower Walk (boards 2 m up on posts), the Rockfall Ledge, the Tool Niche. ----
prop("dungeon/junk_campfire_cold.glb", 31.0, 0.0, 45.0)
prop("dungeon/junk_bedroll_rotten.glb", 28.5, 0.0, 43.5, 70.0)
prop("decor/crate_stack.glb", 34.5, 0.0, 41.5, 20.0)
prop("decor/timber_stack.glb", 27.0, 0.0, 48.0, 90.0)
chest("chest_small", 33.0, 43.0, 200.0, "Camp chest", y=0.0)
for z in range(30, 46, 2):
	old_or("dungeon/floor_old.glb", 15.0, 2.0, z + 1.0, rng.choice([0, 90, 180, 270]), "floor", 0)
	piece("pillar", 16.2, 0.0, z + 1.0)
	rail(15.85, 2.24, z + 1.0, 1, 90.0, chance_broken=0.5, chance_gone=0.2)
for x, z in ((14, 24), (16, 24), (18, 24), (14, 26), (16, 26), (18, 26), (14, 28), (16, 28), (18, 28)):
	old_or("dungeon/floor_old.glb", x + 1.0, 2.0, z + 1.0, rng.choice([0, 90, 180, 270]), "floor", 0)
for x, z in ((16.2, 30.2), (20.2, 30.2), (20.2, 26.0)):
	piece("pillar", x, 0.0, z)
# Ladders (2 m pieces stacked, one more above the top to step off): up onto the Lower Walk, and the Rockfall Ledge up
# through the deck's hole.
for k in range(2):
	piece("ladder", 15.0, 0.24 + 2.0 * k, 46.2, 0)
for k in range(3):
	piece("ladder", 19.0, 2.24 + 2.0 * k, 24.2, 0)
for x, z, m in ((15.0, 25.5, "trap_drip_fat"), (16.6, 27.6, "trap_drip_cluster"), (15.4, 29.2, "trap_drip_thin")):
	prop("dungeon/%s.glb" % m, x, 15.9, z, rng.choice([0, 120, 240]), role="trap", tilt=180.0, floor=2.0, warn=0.35,
		fall=0.45, label="Stalactite (cracks and dust)" if m == "trap_drip_fat" else "")
prop("cave/boulder_round.glb", 15.4, 2.0, 28.0, 30.0, scale=2.2, role="secret", label="Hidden boulder (hit it)")
prop("dungeon/trap_chest_spikes.glb", 11.5, 2.0, 28.0, 90.0, role="trap", label="Spike holes round the chest")
chest("chest_small", 11.0, 28.0, 90.0, "Old tools (always): shoot it first", True, "buried", y=2.24)
creature("lost_miner", 15.0, 37.0, 180.0, 2.0)
creature("lost_miner", 15.0, 41.0, 180.0, 2.0)
creature("tunnel_rat", 34.0, 36.0, 180.0)
creature("tunnel_rat", 36.5, 37.0, 200.0)

# ---- 4. Level 2: Prop Room (dart wall), Store Shed (cracked wall to the vault), the Bridge, Far Ledge, Climbers'
# Rest (healing basin), the upper ladder. F2 = the boards' top. ----
F2 = L2 + 0.24
prop("decor/timber_stack.glb", 18.0, F2, 19.5, 0.0)
prop("decor/furn_work_table.glb", 22.6, F2, 19.0, 180.0)
prop("decor/shack_shelf.glb", 29.6, F2, 21.0, 270.0)
prop("decor/grain_sacks.glb", 25.4, F2, 19.4, 30.0)
chest("chest_small", 28.4, 19.4, 180.0, "Store chest", y=F2)
chest("chest_stone", 26.0, 15.2, 180.0, "Vault chest (always)", True, "vault", y=F2)
creature("lost_miner", 40.0, 26.0, 270.0, L2)
creature("lost_miner", 42.5, 25.0, 270.0, L2)
prop("decor/mushroom_fountain.glb", 49.5, F2 + 0.01, 31.0, 0.0, role="heal", label="Healing basin")
lights.append([49.5, L2 + 1.6, 31.0])
prop("decor/shack_bench.glb", 51.4, F2, 31.0, 270.0)
for k in range(4):
	piece("ladder", 45.0, F2 + 2.0 * k, 34.2, 0)

# ---- 5. Level 3: Crusher Gallery, Rat Roost (loose stone), Top Hall (the Prop Warden), the top deck, the slide. ----
F3 = L3 + 0.24
for x in (21.0, 23.0):
	prop("dungeon/floor_grooved.glb", x, L3, 19.0, 90.0, role="trap", label="Grooves (the crushers land here)" if x == 21.0 else "")
	prop("dungeon/trap_crusher.glb", x, L3 + 1.25, 19.0, 0.0, role="trap", floor=L3,
		label="Crushers (watch their rhythm)" if x == 21.0 else "")
for x, z in ((15.5, 13.5), (17.5, 16.5), (18.5, 13.0), (15.0, 16.0)):
	creature("tunnel_rat", x, z, rng.choice([0, 90, 180, 270]), L3)
prop("dungeon/floor_loose_stone.glb", 17.0, L3, 15.0, 0.0, role="secret", label="Loose stone")
chest("chest_small", 17.0, 15.0, 0.0, "Buried chest (under the loose stone)", True, "buried", y=L3 - 0.5)
creature("prop_warden", 37.0, 15.0, 180.0, L3, ["top_hall"])
for x, z in ((33.0, 18.0), (41.0, 18.0), (37.0, 20.5)):
	creature("lost_miner", x, z, 180.0, L3, ["top_hall"])
RECIPE_STAND = {"pos": [33.0, F3, 11.2], "yaw": 0.0, "page": "scroll_mossprop"}
prop("dungeon/recipe_stand.glb", 33.0, F3, 11.2, 0.0, role="loot", label="Recipe stand (same recipe every time)")
prop("dungeon/recipe_scroll.glb", 33.0, F3 + 0.90, 11.2 + 0.007, 0.0, role="loot", tilt=20.0)
chest("chest_copper", 41.0, 11.2, 0.0, "The Prop Warden's chest (always)", True, "big", y=F3)
prop("dungeon/lever.glb", 41.0, L3, 24.0 - 0.15, 180.0, role="door", label="Lever: E to open the gate")
for x in (31.0, 43.0):
	for z in (12.0, 22.0):
		for k in range(3):
			piece("column", x, F3 + 2.0 * k, z)
# The rope slide: from its top post on the top deck (by the gate) down over the cave to Base Camp. E at the top post.
prop("dungeon/rope_slide.glb", 38.6, F3, 27.4, -9.76, role="door", label="Rope slide: E to slide down to Base Camp")

# ---- 6. Rotten wood and junk everywhere (owner, Nov 21): snapped beams, heaps of rotten boards, old lanterns. ----
ROT = ["junk_rubble_wood", "junk_rubble_wood_b", "junk_rubble_wood_c", "junk_rubble_wood_d", "junk_rubble_wood_e",
	"junk_rubble_wood_f", "junk_beam_snapped", "junk_beam_snapped"]
KEEP_OUT = [(c["pos"][0], c["pos"][2], 1.2) for c in creatures] + [(c["pos"][0], c["pos"][2], 1.2) for c in chests] + \
	[(p["pos"][0], p["pos"][2], 1.3) for p in props if p["role"] in ("door", "trap", "secret", "heal", "loot")
		and "spikes" not in p["model"] and "floor" not in p["model"] and "chain" not in p["model"]] + \
	[(15.0, 47.0, 1.6), (19.0, 24.6, 1.4), (45.0, 34.6, 1.4), (35.4, 46.0, 1.6), (31.0, 45.0, 1.4), (28.5, 43.5, 1.4),
		(34.5, 41.5, 1.4), (27.0, 48.0, 1.6), (30.0, 54.0, 2.5)]
placed = []


def scatter(n, y, x0, x1, z0, z1, kinds=ROT, gap=1.1):
	tries = 0
	while n > 0 and tries < 400:
		tries += 1
		x, z = rng.uniform(x0, x1), rng.uniform(z0, z1)
		if any((x - a) ** 2 + (z - b) ** 2 < r * r for a, b, r in KEEP_OUT):
			continue
		if any((x - a) ** 2 + (z - b) ** 2 < gap * gap and abs(y - c) < 1 for a, b, c in placed):
			continue
		placed.append((x, z, y))
		prop("dungeon/%s.glb" % rng.choice(kinds), x, y, z, rng.uniform(0, 360))
		n -= 1


# (the chasm, x 29.5-38.5 z 23.5-34.5, stays clear; posts stand along z 28.2 and x 43.8)
scatter(8, 0.0, 20.5, 29.0, 28.9, 33.5)            # under the tower, west of the chasm
scatter(5, 0.0, 39.0, 43.0, 28.9, 34.5)            # under the tower, east
scatter(6, 0.0, 26.5, 36.0, 34.8, 49.5)            # Base Camp and the cave floor
scatter(4, 0.0, 17.0, 26.0, 33.0, 45.0)            # the cave floor by the Lower Walk
scatter(3, 2.24, 14.3, 15.6, 31.0, 44.5, gap=2.0)  # on the Lower Walk
scatter(3, 2.24, 14.3, 17.5, 24.5, 29.5)           # on the Rockfall Ledge
scatter(3, F2, 28.2, 29.7, 24.4, 25.2)             # deck 2, along the cliff
scatter(3, F2, 38.5, 43.5, 24.4, 25.2)
scatter(4, F3, 24.5, 35.5, 24.4, 25.2)             # deck 3, along the cliff
scatter(2, F3, 40.5, 43.5, 24.4, 25.2)
scatter(2, F2, 16.6, 20.0, 20.0, 23.4)             # in the Prop Room and the Store Shed
scatter(2, F2, 24.6, 27.6, 21.0, 23.4)
scatter(3, F3, 31.0, 43.0, 13.0, 23.0, ROT + ["junk_bones", "junk_helmet"], gap=1.6)   # the Top Hall
scatter(2, F3, 14.6, 19.4, 12.6, 17.4, ["junk_bones", "junk_rubble_wood_c", "junk_rubble_wood_e"])   # the Roost
# Old lanterns left on the decks and the walk (they still glow a little).
for x, y, z in ((26.6, F2, 24.5), (42.6, F2, 25.0), (28.0, F3, 24.5), (44.6, F3, 31.0), (14.5, 2.24, 33.5),
		(29.6, 0.0, 44.2)):
	prop("dungeon/junk_lantern.glb", x, y, z, rng.uniform(0, 360))
	lights.append([x, y + 0.8, z])

plan = {"name": "Mossprop Workings", "map": "mossprop", "pieces": pieces, "props": props, "creatures": creatures,
	"chests": chests, "lights": lights, "recipe_stand": RECIPE_STAND}

if __name__ == "__main__":
	out = ROOT / "blueprints/dungeons/mossprop_workings.json"
	out.write_text(json.dumps(plan, indent=1), encoding="utf-8")
	files = {f"build/{p['id']}__{p['mat']}.glb" for p in pieces} | {p["model"] for p in props} \
		| {c["model"] for c in creatures} | {f"stations/{c['kind']}.glb" for c in chests}
	missing = [f for f in sorted(files) if not (ROOT / "assets/models" / f).exists()]
	for f in missing:
		print("missing model:", f)
	old = sum(1 for p in props if "_old" in p["model"] or "rubble_wood" in p["model"] or "beam_snapped" in p["model"]
		or "broken" in p["model"])
	print("pieces", len(pieces), "props", len(props), "(rotten:", old, ") creatures", len(creatures), "chests", len(chests),
		"->", out.relative_to(ROOT))
	if missing:
		sys.exit(1)
