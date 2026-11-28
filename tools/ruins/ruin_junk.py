# Ruin junk (owner, Nov 20): small floor models "just for looks" in and around the ruins (the Watchtower, the Fallen
# Outpost), hugging their walls. Writes blueprints/ruins/<ruin>_junk.json beside the plan (a file of its own, so
# re-making the ruin's plan never wipes it). The game (RuinJunk) turns it into world spots once, on the host, and saves
# them in the ruin's record; every computer draws them; the junk inside goes when the ruin is rebuilt (owner).
# Owner's rules (checked by tests/test_ruin_junk.gd):
#   along walls only (outside: along the walls and foundations); never on a doorway, the gateway, stairs or foundation
#   steps; never within 1.5 m of a chest; never on the walk lines between doorways, or the path in front of the door
#   (where the Rebuilding Chest stands); never inside a building piece.
#   The ruin camp (owner's pick, step 3): one cold campfire standing free on the bare ground outside, a bedroll (feet
#   to the fire) and a cook pot beside it, all at least FREE_CLEAR from every building piece ("free" in the list).
# Decor (owner, Nov 21: "fill the ruins with props and junk, like the dungeons"): the ruin pieces of the decor
#   catalogue (docs/art/DECOR-CATALOG.md, "## Ruined Tower" .. "## Lantern Spire") go in FIRST, each searched for
#   outward from the spot the catalogue gives (DECOR below) and checked with the same rules as junk (floor under every
#   corner, not inside a piece, off stairs, doorways, chests and walk lines). The owner: "if you think it works, place
#   it", so a piece with no free spot is left out and printed. Decor is written into the same junk file with "cat": true
#   (tests/test_ruin_decor.gd); "loot": true ones (a bolt crate, a crossbow rack) are placed by LootProps instead.
#   Then junk fills round it: one of each kind per floor (candles, plates and pots may repeat), as full as it fits.
# Run: python tools/ruins/ruin_junk.py [ruin ...]   (every ruin)
import json
import os, math, random, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/dungeons"))
from junk import model_of, CLUSTER, corners, part_at, seg_dist, size  # noqa: E402
from decor import _origin, rect_dist  # noqa: E402
from glb_bounds import bounds  # noqa: E402

FLOOR_LIFT = 0.01    # junk stands 1 cm over the floor piece's top (no shimmer)
WALL_GAP = 0.05      # from the wall's face (walls are 0.3 thick; worn ones bulge a little)
DOOR_CLEAR = 2.0     # a doorway's middle (the gateway: GATE_CLEAR)
GATE_CLEAR = 3.0
THING_CLEAR = 1.5    # chests and barrels (the owner's 1.5 m)
TORCH_CLEAR = 1.0
STAIR_CLEAR = 1.0    # stairs and foundation steps: their outline grown this much (both ends free)
PATH_CLEAR = 1.0     # a walk line: the junk's middle stays this far away...
PATH_EDGE = 0.6      # ...and no corner closer than this
JUNK_GAP = 0.25      # junk to junk, edge to edge
DECOR_STAIR = 0.5    # decor: from stairs' outline (owner, Nov 21: the rules are fluid; the steps themselves stay free)
DECOR_DOOR = 0.6     # decor: a doorway's clearance times this, from the piece's outline (1.2 m; the gateway 1.8 m)
DECOR_EDGE = 0.12    # decor: its corners may hang this far past a floor's edge (a round tower's bent walls)
AUTO_APART = 3.0     # decor with no hint (auto): this far from other decor on the same floor
FREE_CLEAR = 1.0     # the free-standing camp: every corner this far from every building piece
CAMP = [("campfire_cold", 0.0, 0.0), ("bedroll_rotten", 1.35, 0.0), ("cookpot_tipped", 1.0, 105.0)]  # (dist, angle)
HUG = {"wall", "wall_narrow", "half_wall", "window_wall", "window_wide", "ruin_wall_worn", "ruin_wall_collapsed"}
OPENINGS = {"doorway": DOOR_CLEAR, "gateway": GATE_CLEAR}
STAIRS = {"stairs", "stairs_corner", "stairs_spiral", "foundation_steps"}

RUINS = {
	"watchtower_ruin": {
		"seed": 254,
		"yard": False,                           # its ground floor is all foundations
		"out_reach": 9.0,                        # outside junk: this close to the middle
		"camp_reach": 13.0,                      # the camp: this close (it needs room past the walls)
		"out_want": (5, 7),
		# The path out of the door and the Rebuilding Chest's spots (RuinTower._chest_spots, rad 4.2)
		"paths": [[(0.0, 3.0), (0.0, 12.0)]],
		"keep": [(3.4, 5.8), (-3.4, 5.8), (3.4, 7.2), (-3.4, 7.2), (4.6, 4.6), (-4.6, 4.6)],
		"pool": ["helmet", "shield_wood", "spear_broken", "sword_snapped", "axe_head", "rags", "lantern", "meal",
			"candles", "grain_sacks", "bones", "scrap", "armour_pile", "bedroll_rotten", "torch_dropped", "cookpot_tipped"],
		"out_pool": ["rubble_wood", "beam_snapped", "rags", "shield_wood", "spear_broken", "bones", "crate_stack",
			"timber_stack", "keg", "helmet", "torch_dropped"],
	},
	"outpost_ruin": {
		"seed": 478,
		"yard": True,                            # bare ground with ruin walls all round is its yard
		"out_reach": 22.0,
		"camp_reach": 26.0,
		"out_want": (7, 10),
		"yard_want": (14, 18),
		"wall_box": 14.0,                        # decor inside the curtain walls goes when it is rebuilt
		# The way in through the gateway, and the Rebuilding Chest's spots (RuinOutpost._chest_spots)
		"paths": [[(-0.27, 13.0), (-0.27, 25.0)]],
		"keep": [(7.0, 17.2), (-7.0, 17.2), (7.0, 18.6), (-7.0, 18.6), (2.2, 19.2), (-2.2, 19.2)],
		"pool": ["helmet", "shield_iron", "shield_wood", "spear_broken", "sword_snapped", "axe_head", "armour_pile",
			"rags", "lantern", "meal", "candles", "grain_sacks", "bones", "scrap", "rubble_wood", "crate_stack", "keg",
			"bedroll_rotten", "torch_dropped", "cookpot_tipped"],
		"out_pool": ["rubble_wood", "beam_snapped", "rags", "shield_wood", "spear_broken", "bones", "crate_stack",
			"timber_stack", "keg", "helmet", "armour_pile", "torch_dropped"],
	},
	"brewhall_ruin": {
		"seed": 331,
		"yard": False,
		"out_reach": 13.0,
		"camp_reach": 17.0,
		"out_want": (6, 8),
		# The way in to the front door's steps, and the Rebuilding Chest's spots (RuinBrewhall._chest_spots)
		"paths": [[(-5.0, 5.5), (-5.0, 14.0)]],
		"keep": [(-2.6, 6.6), (-7.4, 6.6), (-2.6, 7.8), (-7.4, 7.8), (0.4, 6.8), (-1.2, 8.4)],
		"pool": ["helmet", "rags", "lantern", "meal", "candles", "grain_sacks", "bones", "scrap", "rubble_wood", "keg",
			"crate_stack", "bedroll_rotten", "torch_dropped", "cookpot_tipped", "shield_wood", "beam_snapped"],
		"out_pool": ["rubble_wood", "beam_snapped", "rags", "bones", "crate_stack", "timber_stack", "keg", "torch_dropped",
			"grain_sacks"],
	},
	"spire_ruin": {
		"seed": 612,
		"yard": False,
		"out_reach": 10.0,
		"camp_reach": 15.0,
		"out_want": (5, 7),
		"paths": [[(0.0, 3.0), (0.0, 12.0)]],
		"keep": [(-3.4, 5.8), (-3.4, 7.2), (-4.6, 5.0), (-2.8, 8.4), (3.4, 5.8), (3.4, 7.2)],
		"pool": ["helmet", "rags", "lantern", "meal", "candles", "bones", "scrap", "spear_broken", "torch_dropped",
			"cookpot_tipped", "grain_sacks", "bedroll_rotten", "shield_wood"],
		"out_pool": ["rubble_wood", "beam_snapped", "rags", "bones", "crate_stack", "timber_stack", "torch_dropped",
			"helmet"],
	},
	# The grand ruins (F976, owner Nov 28: "go through all of the ruins and see if they have garbage and other assets
	# laying around"). Built into cave shapes: "ground" is their cave floor in their box (the plan's "floor"), outside
	# junk and the camp only go in the yard each one digs flat in front ("out_box": x0, x1, z0, z1), and junk keeps off
	# the plan's own furniture ("props"). "keep": the ruin's _chest_spots; "paths": the way in to its _path_z.
	"cliff_galleries_ruin": {
		"seed": 913,
		"yard": False,
		"props": True,
		"out_reach": 30.0,
		"camp_reach": 30.0,
		"out_want": (3, 5),
		"out_box": [(-23.0, 4.0, 8.0, 17.0)],   # (RuinCliffGalleries.YARD_X / YARD_Z: the dug yard)
		"paths": [[(-2.0, 9.0), (-2.0, 16.0)], [(-18.0, 9.0), (-18.0, 16.0)]],
		"keep": [(-7.5, 11.5), (2.5, 11.5), (-10.5, 12.0), (-5.0, 14.0), (0.0, 14.5)],
		"pool": ["rags", "meal", "candles", "cookpot_tipped", "lantern", "grain_sacks", "bones", "rubble_brick", "keg",
			"crate_stack", "furn_stool", "furn_bucket_wood", "bedroll_rotten", "urn_broken", "torch_dropped", "tools",
			"rubble_wood", "furn_vase_wide"],
		"out_pool": ["rubble_brick", "rubble_wood", "beam_snapped", "rags", "bones", "crate_stack", "timber_stack", "keg",
			"torch_dropped", "furn_bucket_wood"],
	},
}
REPEAT = {"candles", "meal", "cookpot_tipped"}   # (owner: one of each kind per room; candles and pots may repeat)

# The catalogue's ruin decor: (id, floor top y, how it stands, hint x, hint z, extras). Spots are in the ruin's own
# frame (x right, z toward the door). "wall": back to the nearest wall to the hint ("up": hung this high); "mid": free
# standing near the hint ("yaw"); "ground": outside on the bare ground near the hint ("yaw"); "gap": exactly there,
# filling a breach in a wall. "n": how many (each spot searched on its own, from its hint).
def A(did, mount, **ex):
	"""A decor piece with no hint: the tool finds it a spot (see auto_tries). ex: "up" (hung), "y"/"lo"/"hi" (floors)."""
	return (did, None, mount, None, None, ex)


DECOR = {
	"watchtower_ruin": [
		("rt_water_cistern", 0.0, "ground", -4.6, -3.0, {"yaw": 300}),
		("rt_stair_landing_broken", 0.0, "ground", 4.4, -3.6, {"yaw": 30}),
		("rt_weapon_rack", 3.25, "wall", 0.0, -3.4, {}),
		("rt_arrow_crate_spill", 3.25, "mid", 0.4, 0.6, {"yaw": 0, "loot": True}),
		("rt_arrow_slit_shutter", 3.25, "wall", 3.2, 0.6, {}),
		("rt_watch_table_map", 5.5, "mid", 0.0, -0.4, {"yaw": 90}),
		("rt_map_tube_rack", 5.5, "wall", -1.8, 3.0, {}),
		("rt_watch_roster_slab", 5.5, "wall", -1.0, -3.4, {"up": 0.5}),
		("rt_watch_hooks", 5.5, "wall", 3.2, 1.6, {"up": 1.0}),
		("rt_arrow_slit_shutter", 5.5, "wall", -3.2, 0.4, {}),
		("rt_lookout_brazier", 7.75, "mid", 0.0, 1.4, {"yaw": 0}),
		("rt_signal_mirror_stand", 7.75, "mid", -1.2, 2.6, {"yaw": 0}),
		("rt_fallen_bell", 0.0, "ground", 0.6, -5.6, {"yaw": 20}),
	],
	"outpost_ruin": [
		("ro_gate_bar_brackets", 0.0, "gap", -14.0, 1.0, {"yaw": 90}),
		("ro_palisade_section", 0.0, "gap", 3.0, -14.0, {"yaw": 0}),
		("ro_palisade_section", 0.0, "gap", 14.73, 5.0, {"yaw": 270}),
		("ro_flag_pole", 0.0, "ground", 0.0, 0.0, {"yaw": 0}),
		("ro_camp_cookery", 0.0, "ground", -4.0, -5.0, {"yaw": 0}),
		("ro_stake_bundle", 0.0, "ground", -11.0, 3.0, {"yaw": 90}),
		("ro_duty_board", 0.0, "ground", 4.6, 9.9, {"yaw": 180}),
		("ro_ladder_platform", 0.0, "ground", 11.5, 7.0, {"yaw": 270}),
		("ro_archery_bale", 0.0, "ground", -9.0, 4.0, {"yaw": 0}),
		("ro_archery_bale", 0.0, "ground", -7.0, 4.0, {"yaw": 0}),
		("ro_armour_bench", 0.25, "wall", 13.4, 1.3, {}),
		("ro_quiver_rack", 0.25, "wall", 13.4, -1.5, {"up": 0.4, "loot": True}),
		("ro_supply_cart", 0.0, "ground", -6.5, 17.5, {"yaw": 0}),
		("ro_gate_wing_broken", 0.0, "ground", 4.5, 18.5, {"yaw": 30}),
	],
	"brewhall_ruin": [
		("rb_brew_kettle", 1.0, "wall", 5.5, -4.0, {}),
		("rb_recipe_board", 1.0, "wall", 1.0, -5.6, {}),
		("rb_mash_tun", 1.0, "mid", -3.6, 2.2, {"yaw": 0}),
		("rb_fermenting_vats", 1.0, "wall", -7.6, 1.6, {}),
		("rb_grain_quern", 1.0, "wall", -0.6, -1.0, {}),
		("rb_horn_wall", 1.0, "wall", -7.6, -1.4, {"up": 1.0}),
		("rb_feast_table_broken", 1.0, "mid", -2.0, -0.4, {"yaw": 90}),
		("rb_drying_rack", 3.25, "wall", -2.6, 3.6, {}),
		("rb_cask_bay", 3.25, "wall", -7.4, 0.0, {"reach": 8.0}),
		("rb_vat_burst", 0.0, "ground", 4.2, 0.2, {"yaw": 0}),
		("rb_cooper_bench", 0.0, "ground", 2.4, 3.0, {"yaw": 0}),
		("rb_cask_rolled", 0.0, "ground", 2.5, 7.5, {"yaw": 90}),
	],
	"spire_ruin": [
		("rs_keeper_log_desk", 1.0, "wall", -1.8, 3.0, {}),
		("rs_oil_hoist", 0.0, "ground", -4.8, -1.0, {"yaw": 270}),
		("rs_oil_jar_stand", 1.0, "wall", -2.0, -3.0, {}),
		("rs_chimney_rack", 1.0, "wall", 1.8, 3.0, {}),
		("rs_lens_workbench", 3.25, "wall", -3.4, 1.0, {}),
		("rs_wick_board", 3.25, "wall", -1.6, 3.2, {}),
		("rs_reflector_plates", 3.25, "wall", 0.0, -3.4, {}),
		("rs_great_lens_cradle", 3.25, "mid", 0.8, 1.2, {"yaw": 0}),
		("rs_keeper_last_watch", 3.25, "wall", 0.0, 3.0, {}),
		("rs_signal_shutters", 0.0, "ground", 7.0, 9.6, {"yaw": 200}),
		("rs_lantern_cage_fallen", 0.0, "ground", 13.4, 9.4, {"yaw": 30}),
		("rs_lens_shattered", 0.0, "ground", 14.6, 3.4, {"yaw": 0}),
	],
	# Dwarf homes up a cliff: house things in every home, a watchman's corner up in the tower, a cart in the yard.
	"cliff_galleries_ruin": [
		A("wardrobe", "wall"), A("writing_desk", "wall"), A("rocking_chair", "wall"), A("storage_trunk", "wall"),
		A("washbasin", "wall"), A("bookshelf_collapsed", "wall"), A("table_overturned", "mid"), A("boot_rack", "wall"),
		A("spice_shelf", "wall", up=1.0), A("dish_rack", "wall", up=1.0), A("candle_wall_shelf", "wall", up=1.2),
		A("bunk_bed", "wall"), A("chandelier_fallen", "mid"), A("hs_watch_brazier", "mid", lo=9.0),
		A("mg_last_watch", "wall", lo=9.0), A("mg_wheelbarrow", "ground"), A("mg_water_butt", "ground"),
	],
}


# ---------------------------------------------------------------- the pieces (sizes read from src/build/pieces.gd)

def _pieces():
	out = {}
	for line in (ROOT / "src/build/pieces.gd").read_text(encoding="utf-8").splitlines():
		m = re.match(r'\s*"(\w+)": \{.*?size = Vector3\(([^)]*)\)', line)
		if m:
			vals = [float(v.strip().replace("TRI_DEPTH", "1.7320508")) for v in m.group(2).split(",")]
			g = re.search(r'group = "(\w+)"', line)
			out[m.group(1)] = {"size": vals, "group": g.group(1) if g else ""}
	return out


PIECES = _pieces()


def steps_of(rot):
	return rot * 3 if rot < 4 else rot - 4


def turn(x, z, yaw):
	"""Godot's Basis(UP, yaw) * (x, 0, z), flat."""
	c, s = math.cos(yaw), math.sin(yaw)
	return (x * c + z * s, -x * s + z * c)


def outline(pid, grow=0.0):
	sx, _, sz = PIECES[pid]["size"]
	if "triangle" in pid:
		k = sx * 0.5
		r_in = 0.57735027 * k
		f = max(r_in + grow, 0.01) / r_in
		return [(-k * f, r_in * f), (k * f, r_in * f), (0.0, -1.1547005 * k * f)]
	hx, hz = max(sx / 2 + grow, 0.005), max(sz / 2 + grow, 0.005)
	return [(-hx, -hz), (hx, -hz), (hx, hz), (-hx, hz)]


def footprint(p, grow=0.0):
	yaw = steps_of(int(p["rot"])) * math.pi / 6.0
	out = []
	for (x, z) in outline(p["id"], grow):
		w = turn(x, z, yaw)
		out.append((p["pos"][0] + w[0], p["pos"][2] + w[1]))
	return out


def grow_by(poly, g):
	"""A convex outline grown outward by about g (from its middle)."""
	mx, mz = sum(c[0] for c in poly) / len(poly), sum(c[1] for c in poly) / len(poly)
	out = []
	for (x, z) in poly:
		d = math.hypot(x - mx, z - mz) or 1.0
		out.append((x + (x - mx) / d * g, z + (z - mz) / d * g))
	return out


def overlap(a, b):
	"""Two convex outlines overlap (separating axes; touching is not overlapping)."""
	for poly in (a, b):
		for i in range(len(poly)):
			e = (poly[(i + 1) % len(poly)][0] - poly[i][0], poly[(i + 1) % len(poly)][1] - poly[i][1])
			ax = (-e[1], e[0])
			ta = [ax[0] * q[0] + ax[1] * q[1] for q in a]
			tb = [ax[0] * q[0] + ax[1] * q[1] for q in b]
			if max(ta) <= min(tb) + 1e-4 or max(tb) <= min(ta) + 1e-4:
				return False
	return True


def inside(pt, poly):
	sign = 0
	for i in range(len(poly)):
		a, b = poly[i], poly[(i + 1) % len(poly)]
		cr = (b[0] - a[0]) * (pt[1] - a[1]) - (b[1] - a[1]) * (pt[0] - a[0])
		if abs(cr) < 1e-9:
			continue
		s = 1 if cr > 0 else -1
		if sign == 0:
			sign = s
		elif s != sign:
			return False
	return True


_h = {}


def height(model):
	if model not in _h:
		lo, hi = bounds(str(ROOT / "assets/models" / model))
		_h[model] = float(hi[1] - lo[1])
	return _h[model]


# ---------------------------------------------------------------- spots

def make(name):
	opt = RUINS[name]
	plan = json.loads((ROOT / "blueprints/ruins" / f"{name}.json").read_text(encoding="utf-8"))
	rng = random.Random(opt["seed"])
	G = float(opt.get("ground", plan.get("floor", 0.0)))   # (a grand ruin's cave floor in its box: Cliff Galleries 5.0)
	pieces = [p for p in plan["pieces"] if p["id"] in PIECES]
	for p in pieces:
		p["fp"] = footprint(p)
		p["top"] = p["pos"][1] + PIECES[p["id"]]["size"][1]
	supports = [p for p in pieces if PIECES[p["id"]]["group"] in ("floor", "foundation") and p["id"] not in STAIRS]
	# Things that aren't building pieces but stand in the way (the grand ruins, F976): the plan's own props (furniture,
	# lootable racks) and any piece the game doesn't have yet (the Kiln's own models): junk keeps off their outlines.
	others = []
	for p in plan.get("props", []):
		m = p["model"] if "/" in p["model"] else "decor/%s.glb" % p["model"]
		if (ROOT / "assets/models" / m).exists():
			others.append((corners(m, p["pos"][0], p["pos"][2], float(p.get("yaw", 0.0))), p["pos"][1], p["pos"][1] + height(m)))
	for p in plan["pieces"]:
		if p["id"] not in PIECES:
			m = "build/%s.glb" % p["id"]
			if (ROOT / "assets/models" / m).exists():
				others.append((corners(m, p["pos"][0], p["pos"][2], steps_of(int(p.get("rot", 0))) * 30.0), p["pos"][1],
					p["pos"][1] + height(m)))
			else:
				print("  (no model for %s: left out)" % p["id"])
	if not opt.get("props", False):
		others = []   # (the first four ruins: their junk was laid out before this, Nov 21)
	levels = sorted({round(p["top"], 2) for p in supports} | {G})

	def out_ok(x, z):
		"""Outside ground junk and the camp: only in the dug-out yard(s) of a grand ruin (real, level floor), if listed."""
		boxes = opt.get("out_box")
		return boxes is None or any(b[0] <= x <= b[1] and b[2] <= z <= b[3] for b in boxes)

	def level_of(pt, y):
		"""'piece' when a floor piece with its top at y is under pt, 'ground' when no floor piece at all, else None."""
		on = [p for p in supports if inside(pt, p["fp"])]
		if any(abs(p["top"] - y) < 0.06 for p in on):
			return "piece"
		return "ground" if not on and y == G else None

	# The edges junk hugs at each level: (a, b, face offset from the line, base y).
	edges = []
	for p in pieces:
		if p["id"] in HUG:
			sx, _, sz = PIECES[p["id"]]["size"]
			yaw = steps_of(int(p["rot"])) * math.pi / 6.0
			d = turn(1.0, 0.0, yaw)
			c = (p["pos"][0], p["pos"][2])
			edges.append(((c[0] - d[0] * sx / 2, c[1] - d[1] * sx / 2), (c[0] + d[0] * sx / 2, c[1] + d[1] * sx / 2),
				sz / 2, p["pos"][1]))
		elif PIECES[p["id"]]["group"] == "foundation" and p["id"] not in STAIRS:
			fp = p["fp"]
			for i in range(len(fp)):
				edges.append((fp[i], fp[(i + 1) % len(fp)], 0.0, None))   # (outside, on the ground only)

	# Walk lines at each level: between every two openings (doorways, the gateway, stairs, foundation steps).
	def openings_at(y):
		out = []
		for p in pieces:
			if p["id"] in OPENINGS and abs(p["pos"][1] - y) < 0.3:
				out.append((p["pos"][0], p["pos"][2]))
			elif p["id"] in STAIRS and (abs(p["pos"][1] - y) < 0.3 or abs(p["top"] - y) < 0.3):
				out.append((p["pos"][0], p["pos"][2]))
		return out

	lines = {y: [(a, b) for i, a in enumerate(openings_at(y)) for b in openings_at(y)[i + 1:]] for y in levels}
	for y in lines:
		if y == G:
			lines[y] += [tuple(l) for l in opt["paths"]]
	chests = [(c["pos"][0], c["pos"][1], c["pos"][2]) for c in plan.get("chests", [])]
	torches = [tuple(t) for t in plan.get("torches", [])]

	why = {}

	def _no(r):
		why[r] = why.get(r, 0) + 1
		why["last"] = r
		return None

	def free(parts_at, y, kind, up=0.0, solo=False, stair=STAIR_CLEAR, edge=0.0, yard_lines=True):
		"""parts_at: [(model, corners)]. None, or the parts' (x, z, radius). up: a hung piece's bottom over the floor
		(it skips the walk lines, chests and torches: you walk under it). solo: a decor piece (checked against the
		other decor by its real outline, in place_decor, instead of by circles). Decor (owner: "if you think it works")
		keeps DECOR_STAIR from stairs, may hang `edge` over a floor's edge, and on the bare ground (yard_lines False)
		keeps off only the way in, not every door-to-door line across the yard."""
		out = []
		if why is not None:
			why["last"] = None
		for model, cs in parts_at:
			px, pz = sum(c[0] for c in cs) / 4, sum(c[1] for c in cs) / 4
			rad = max(math.hypot(c[0] - px, c[1] - pz) for c in cs)
			for pt in grow_by(cs, -edge) + [(px, pz)]:
				if level_of(pt, y) != kind:
					return _no('floor')
			low = y + up
			top = low + max(height(model), 0.3)
			for p in pieces:
				if kind == "piece" and p in supports and abs(p["top"] - y) < 0.06:
					continue
				lo, hi = p["pos"][1], p["top"]
				if p["id"] in STAIRS:
					if lo - 0.3 < y < hi + 0.3 and overlap(cs, footprint(p, stair)):
						return _no('stairs' + (':%s@%s' % (p['id'], p['pos']) if os.environ.get('DBG') else ''))
					continue
				if hi > low + 0.05 and lo < top and overlap(cs, footprint(p, 0.05)):
					return _no('piece' + (':%s@%s' % (p['id'], p['pos']) if os.environ.get('DBG') else ''))
				if p["id"] in OPENINGS and abs(lo - y) < 1.0 and not far(cs, px, pz, rad, solo, p["pos"][0], p["pos"][2], OPENINGS[p["id"]] * (DECOR_DOOR if solo else 1.0)):
					return _no('opening')
			for (cx, cy, cz) in ([] if up > 0.3 else chests):
				if abs(cy - y) < 1.0 and not far(cs, px, pz, rad, solo, cx, cz, THING_CLEAR):
					return _no('chest')
			for (tx, ty, tz) in ([] if up > 0.3 else torches):
				if abs(ty - y) < 1.0 and not far(cs, px, pz, rad, solo, tx, tz, TORCH_CLEAR):
					return _no('torch')
			for (ocs, olo, ohi) in others:
				if olo < top and ohi > low and overlap(cs, grow_by(ocs, JUNK_GAP)):
					return _no('prop')
			if kind == "ground" and not out_ok(px, pz):
				return _no('out_box')
			if y == G:
				for (kx, kz) in opt["keep"]:
					if not far(cs, px, pz, rad, solo, kx, kz, THING_CLEAR):
						return _no('keep')
			for (a, b) in ([] if up > 0.3 or (solo and kind == "piece") else
					lines.get(y, []) if yard_lines else [tuple(l) for l in opt["paths"]]):   # (decor indoors: rooms are walked round it)
				if seg_dist((px, pz), a, b) < PATH_CLEAR or any(seg_dist(c, a, b) < PATH_EDGE for c in cs):
					return _no('path')
			for (ox, oz, oy, r) in ([] if solo else placed):
				if abs(oy - y) < 1.0 and math.hypot(px - ox, pz - oz) < r + rad + JUNK_GAP:
					return _no('junk')
			out.append((px, pz, rad))
		return out

	def far(cs, px, pz, rad, solo, ox, oz, clear):
		"""Is a piece (corners cs, middle, radius) at least `clear` from the spot (ox, oz)? Junk: by its middle and
		radius; decor (solo): by its real outline (a long table may stand 1.5 m from a chest beside its end)."""
		if solo:
			return rect_dist(cs, (ox, oz)) >= clear
		return math.hypot(px - ox, pz - oz) >= clear + rad

	# The yard: bare ground with the ruin's walls (or its buildings) in all four directions.
	CELL, HALF = 0.25, 30.0
	n_cells = int(2 * HALF / CELL)
	solid = set()
	for p in pieces:
		if p["pos"][1] > 1.3 or not (p["id"] in HUG or p["id"] in OPENINGS or PIECES[p["id"]]["group"] in ("foundation", "floor")):
			continue
		xs, zs = [q[0] for q in p["fp"]], [q[1] for q in p["fp"]]
		for i in range(int((min(xs) + HALF) / CELL), int((max(xs) + HALF) / CELL) + 1):
			for k in range(int((min(zs) + HALF) / CELL), int((max(zs) + HALF) / CELL) + 1):
				if inside(((i + 0.5) * CELL - HALF, (k + 0.5) * CELL - HALF), p["fp"]):
					solid.add((i, k))

	def in_yard(x, z):
		if not opt["yard"]:
			return False
		i0, k0 = int((x + HALF) / CELL), int((z + HALF) / CELL)
		for (di, dk) in ((1, 0), (-1, 0), (0, 1), (0, -1)):
			i, k = i0, k0
			while 0 <= i < n_cells and 0 <= k < n_cells and (i, k) not in solid:
				i, k = i + di, k + dk
			if not (0 <= i < n_cells and 0 <= k < n_cells):
				return False
		return True

	# Every spot along every edge, on both sides: (zone, x, z, yaw, normal, face line point, face offset, y, kind)
	cands = {}
	for (a, b, face, base) in edges:
		L = math.hypot(b[0] - a[0], b[1] - a[1])
		if L < 0.5:
			continue
		d = ((b[0] - a[0]) / L, (b[1] - a[1]) / L)
		for nrm in ((-d[1], d[0]), (d[1], -d[0])):
			for y in levels:
				if base is not None and not (-0.1 <= base - y <= 0.35):
					continue  # a wall hugs the floor it stands on (a cellar's too)
				if base is None and y != G:
					continue  # a foundation's side: only the bare ground beside it
				t = 0.35
				while t <= L - 0.35:
					q = (a[0] + d[0] * t, a[1] + d[1] * t)
					probe = (q[0] + nrm[0] * (face + 0.3), q[1] + nrm[1] * (face + 0.3))
					kind = level_of(probe, y)
					if kind is not None:
						if kind == "piece":
							zone = ("in", y)
						elif in_yard(*probe):
							zone = ("yard", G)
						elif math.hypot(*probe) <= opt["out_reach"]:
							zone = ("out", G)
						else:
							zone = None
						if zone:
							cands.setdefault(zone, []).append((q, d, nrm, face, y, kind))
					t += 0.45
	placed = []
	junk = []

	def try_entry(entry, zone):
		spots = cands.get(zone, [])[:]
		rng.shuffle(spots)
		for (q, d, nrm, face, y, kind) in spots:
			parts = CLUSTER.get(entry) or [[model_of(entry, rng), 0.0, 0.0, 0.0]]
			yaw = math.degrees(math.atan2(-d[1], d[0])) + rng.uniform(-12, 12) + rng.choice([0, 180])
			x, z = q
			for _ in range(2):  # push it to the wall: its nearest corner WALL_GAP off the face
				cs = [c for pt in parts for c in corners(pt[0], *part_at(x, z, yaw, pt[1], pt[2]), yaw + pt[3])]
				near = min((c[0] - q[0]) * nrm[0] + (c[1] - q[1]) * nrm[1] for c in cs)
				x += nrm[0] * (face + WALL_GAP - near)
				z += nrm[1] * (face + WALL_GAP - near)
			at = [(pt[0], corners(pt[0], *part_at(x, z, yaw, pt[1], pt[2]), yaw + pt[3])) for pt in parts]
			got = free(at, y, kind)
			if got is None:
				continue
			for pt, f in zip(parts, got):
				placed.append((f[0], f[1], y, f[2]))
				px, pz = part_at(x, z, yaw, pt[1], pt[2])   # (the spot the check used)
				junk.append({"model": pt[0], "pos": [round(px, 3), round(y + (FLOOR_LIFT if kind == "piece" else 0.0), 3),
					round(pz, 3)], "yaw": round((yaw + pt[3]) % 360.0, 1), "ground": kind == "ground",
					"inside": zone[0] != "out"})
			return True
		return False

	def try_camp():
		"""The ruin camp: a campfire on bare ground outside, its bedroll and cook pot round it, all clear of the ruin."""
		for _ in range(3000):
			ang, dist = rng.uniform(0, 2 * math.pi), rng.uniform(2.0, opt["camp_reach"])
			fx, fz = math.cos(ang) * dist, math.sin(ang) * dist
			if in_yard(fx, fz):
				continue
			turn0 = rng.uniform(0, 360)
			got, outs = [], []
			for (entry, d, a) in CAMP:
				phi = math.radians(turn0 + a)
				x, z = fx + math.cos(phi) * d, fz + math.sin(phi) * d
				yaw = math.degrees(math.pi - phi) if d > 0 else rng.uniform(0, 360)   # (the bedroll's feet to the fire)
				model = model_of(entry, rng)
				cs = corners(model, x, z, yaw)
				if any(overlap(cs, footprint(p, FREE_CLEAR)) for p in pieces):
					break
				if any(math.hypot(*c) > opt["camp_reach"] for c in cs):
					break
				f = free([(model, cs)], G, "ground")   # (camp mates: checked by their real outlines below)
				if f is None or any(overlap(cs, o) for o in outs):
					break
				outs.append(cs)
				got.append((f[0], {"model": model, "pos": [round(x, 3), G, round(z, 3)], "yaw": round(yaw % 360.0, 1),
					"ground": True, "inside": False, "free": True}))
			if len(got) == len(CAMP):
				for f, j in got:
					placed.append((f[0], f[1], G, f[2]))
					junk.append(j)
				print("  camp  at (%.1f, %.1f)" % (fx, fz))
				return True
		print("  camp  NO SPOT")
		return False

	decor_fps = []   # (corners, low, high) of the decor placed
	decor_at = []    # (x, z, floor y) of the decor placed

	def auto_tries(model, mount, ex, sz):
		"""A decor piece with no hint (the grand ruins, F976: "if you think it works, place it"): every wall, floor or
		yard spot of the ruin, the floors with the least decor first, shuffled, so the pieces spread over the ruin.
		ex "y": only that floor; "lo"/"hi": only floors between."""
		out = []
		lo, hi = ex.get("lo", -99.0), ex.get("hi", 99.0)
		if "y" in ex:
			lo = hi = ex["y"]
		if mount == "wall":
			for zone, spots in cands.items():
				for (q, d, nrm, face, cy, kind) in spots:
					if kind != "piece" or not (lo - 0.01 <= cy <= hi + 0.01):
						continue
					yaw = math.degrees(math.atan2(nrm[0], nrm[1]))
					for o in (0.0, 0.2):
						w = face + WALL_GAP + o + sz / 2
						out.append((0.0, *_origin(model, q[0] + nrm[0] * w, q[1] + nrm[1] * w, yaw), yaw, kind, cy))
		elif mount == "mid":
			rooms = [(q, cy) for zone, spots in cands.items() if zone[0] == "in" for (q, d, nrm, face, cy, kind) in spots]
			for p in supports:
				if not (lo - 0.01 <= p["top"] <= hi + 0.01):
					continue
				mx, mz = sum(c[0] for c in p["fp"]) / len(p["fp"]), sum(c[1] for c in p["fp"]) / len(p["fp"])
				if not any(abs(cy - p["top"]) < 0.01 and math.hypot(q[0] - mx, q[1] - mz) < 4.0 for (q, cy) in rooms):
					continue   # (a room's floor, with walls round it: not a bridge, a roof or a ledge)
				for yaw in (0.0, 90.0):
					out.append((0.0, *_origin(model, mx, mz, yaw + rng.uniform(-15, 15)), yaw, "piece", round(p["top"], 2)))
		else:   # "ground": out on the bare floor of the dug yard
			for b in opt.get("out_box", [(-25.0, 25.0, -25.0, 25.0)]):
				x = b[0] + 1.0
				while x <= b[1] - 1.0:
					z = b[2] + 1.0
					while z <= b[3] - 1.0:
						yaw = rng.uniform(0, 360)
						out.append((0.0, *_origin(model, x, z, yaw), yaw, "ground", G))
						z += 0.5
					x += 0.5
		count = {}
		for (_, _, oy) in decor_at:
			count[round(oy, 1)] = count.get(round(oy, 1), 0) + 1
		rng.shuffle(out)
		out.sort(key=lambda t: count.get(round(t[5], 1), 0))
		return out

	def place_decor():
		"""The catalogue pieces (DECOR), nearest free spot to each hint first."""
		for (did, y, mount, hx, hz, ex) in DECOR.get(name, []):
			model = "decor/%s.glb" % did
			sx, sz, ox, oz = size(model)
			up = ex.get("up", 0.0)
			tries = []   # (distance from the hint, x, z, yaw, kind[, floor y])
			if hx is None:
				tries = auto_tries(model, mount, ex, sz)
			elif mount == "wall":
				for zone, spots in cands.items():
					for (q, d, nrm, face, cy, kind) in spots:
						if abs(cy - y) > 0.01 or kind != "piece":
							continue
						yaw = math.degrees(math.atan2(nrm[0], nrm[1]))   # (front, +z, into the room; back flat on the wall)
						for out in (0.0, 0.1, 0.2, 0.3, 0.45, 0.6, 0.8):   # (a round tower's walls bend: step off it a little)
							w = face + WALL_GAP + out + sz / 2
							cx, cz = q[0] + nrm[0] * w, q[1] + nrm[1] * w
							tries.append((math.hypot(cx - hx, cz - hz) + out * 2.0, *_origin(model, cx, cz, yaw), yaw, kind))
			elif mount == "gap":
				tries.append((0.0, *_origin(model, hx, hz, ex["yaw"]), ex["yaw"], "ground"))
			else:
				kind = "ground" if mount == "ground" else "piece"
				n = int(ex.get("reach", 4.0) / 0.25)
				for i in range(-n, n + 1):
					for k in range(-n, n + 1):
						cx, cz = hx + i * 0.25, hz + k * 0.25
						tries.append((math.hypot(cx - hx, cz - hz), *_origin(model, cx, cz, ex["yaw"]), ex["yaw"], kind))
			tries.sort(key=lambda t: t[0])
			why.clear()
			got = None
			for t in tries:
				dist, x, z, yaw, kind = t[:5]
				if hx is None:
					y = t[5]
				elif dist > ex.get("reach", 5.0):
					break
				cs = corners(model, x, z, yaw)
				if hx is None and any(abs(oy - y) < 1.0 and rect_dist(cs, (ox, oz)) < AUTO_APART for (ox, oz, oy) in decor_at):
					continue
				low, high = y + up, y + up + height(model)
				if any(overlap(cs, [(c[0], c[1]) for c in grow_by(o, 0.1)]) for (o, olo, ohi) in decor_fps if ohi > low and olo < high):
					continue
				if mount == "gap":
					f = [(sum(c[0] for c in cs) / 4, sum(c[1] for c in cs) / 4, 0.0)]   # (it fills the breach: placed as given)
				else:
					f = free([(model, cs)], y, kind, up, solo=True, stair=DECOR_STAIR, edge=DECOR_EDGE, yard_lines=False)
				if f is None:
					if os.environ.get("DBG") == did and dist < 1.6:
						print("    dbg (%.2f, %.2f) yaw %.0f: %s" % (x, z, yaw, why.get("last")))
					continue
				got = (dist, x, z, yaw, kind, cs, f[0], low, high)
				break
			if got is None:
				print("  decor %-26s y=%-5s NO SPOT near (%s, %s) %s" % (did, y, hx, hz, {k: v for k, v in why.items() if k != "last"}))
				continue
			dist, x, z, yaw, kind, cs, f, low, high = got
			decor_fps.append((cs, low, high))
			decor_at.append((f[0], f[1], y))
			placed.append((f[0], f[1], y, f[2]))
			box = opt.get("wall_box", 0.0)
			inside = mount == "gap" or kind == "piece" or in_yard(f[0], f[1]) or (abs(f[0]) < box and abs(f[1]) < box)
			j = {"model": model, "pos": [round(x, 3), round(y + up + (FLOOR_LIFT if kind == "piece" else 0.0), 3), round(z, 3)],
				"yaw": round(yaw % 360.0, 1), "ground": kind == "ground", "inside": inside, "cat": True}
			if up:
				j["hung"] = up
			if ex.get("loot"):
				j["loot"] = True
			junk.append(j)
			print("  decor %-26s y=%-5s at (%.2f, %.2f) yaw %3.0f, %.1f m from its spot%s" % (did, y, f[0], f[1], yaw % 360, dist,
				"" if inside else " (outside)"))

	place_decor()
	try_camp()   # (first: it needs the most room)
	area = {}
	for p in supports:
		k = round(p["top"], 2)
		fp = p["fp"]
		area[k] = area.get(k, 0.0) + abs(sum(fp[i][0] * fp[(i + 1) % len(fp)][1] - fp[(i + 1) % len(fp)][0] * fp[i][1]
			for i in range(len(fp)))) / 2
	for zone in sorted(cands):
		if zone[0] == "out":
			want, pool = rng.randint(*opt["out_want"]), list(opt["out_pool"])
		elif zone[0] == "yard":
			want, pool = rng.randint(*opt["yard_want"]), list(opt["pool"])
		else:
			a = area.get(zone[1], 0.0)
			want = max(2, int(a / 5.0))   # (owner, Nov 21: as full as Mossgate's Gate Hall)
			pool = list(opt["pool"])
		rng.shuffle(pool)
		pool = [e for e in pool if e in REPEAT] + pool   # one of each kind (candles, plates, pots: twice)
		n = 0
		why.clear()
		while pool and n < want:
			if try_entry(pool.pop(), zone):
				n += 1
		if n < want and os.environ.get("DBG"):
			print("    why:", {k: v for k, v in why.items() if k != "last"})
		print("  %-5s y=%-5s %d of %d (%d spots)" % (zone[0], zone[1], n, want, len(cands[zone])))
	out = ROOT / "blueprints/ruins" / f"{name}_junk.json"
	out.write_text(json.dumps({"junk": junk}, indent=0, separators=(",", ":")), encoding="utf-8")
	print("%s: %d junk pieces -> %s" % (name, len(junk), out.relative_to(ROOT)))
	return junk


if __name__ == "__main__":
	for n in (sys.argv[1:] or list(RUINS)):
		make(n)
