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
# Run: python tools/ruins/ruin_junk.py   (both ruins)
import json, math, random, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/dungeons"))
from junk import model_of, CLUSTER, corners, part_at, seg_dist  # noqa: E402
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
FREE_CLEAR = 1.0     # the free-standing camp: every corner this far from every building piece
CAMP = [("campfire_cold", 0.0, 0.0), ("bedroll_rotten", 1.35, 0.0), ("cookpot_tipped", 1.0, 105.0)]  # (dist, angle)
HUG = {"wall", "wall_narrow", "half_wall", "window_wall", "window_wide", "ruin_wall_worn", "ruin_wall_collapsed"}
OPENINGS = {"doorway": DOOR_CLEAR, "gateway": GATE_CLEAR}
STAIRS = {"stairs", "foundation_steps"}

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
		"yard_want": (9, 12),
		# The way in through the gateway, and the Rebuilding Chest's spots (RuinOutpost._chest_spots)
		"paths": [[(-0.27, 13.0), (-0.27, 25.0)]],
		"keep": [(7.0, 17.2), (-7.0, 17.2), (7.0, 18.6), (-7.0, 18.6), (2.2, 19.2), (-2.2, 19.2)],
		"pool": ["helmet", "shield_iron", "shield_wood", "spear_broken", "sword_snapped", "axe_head", "armour_pile",
			"rags", "lantern", "meal", "candles", "grain_sacks", "bones", "scrap", "rubble_wood", "crate_stack", "keg",
			"bedroll_rotten", "torch_dropped", "cookpot_tipped"],
		"out_pool": ["rubble_wood", "beam_snapped", "rags", "shield_wood", "spear_broken", "bones", "crate_stack",
			"timber_stack", "keg", "helmet", "armour_pile", "torch_dropped"],
	},
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
	pieces = [p for p in plan["pieces"] if p["id"] in PIECES]
	for p in pieces:
		p["fp"] = footprint(p)
		p["top"] = p["pos"][1] + PIECES[p["id"]]["size"][1]
	supports = [p for p in pieces if PIECES[p["id"]]["group"] in ("floor", "foundation") and p["id"] not in STAIRS]
	levels = sorted({round(p["top"], 2) for p in supports} | {0.0})

	def level_of(pt, y):
		"""'piece' when a floor piece with its top at y is under pt, 'ground' when no floor piece at all, else None."""
		on = [p for p in supports if inside(pt, p["fp"])]
		if any(abs(p["top"] - y) < 0.06 for p in on):
			return "piece"
		return "ground" if not on and y == 0.0 else None

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
				edges.append((fp[i], fp[(i + 1) % len(fp)], 0.0, -1.0))   # (outside, on the ground only)

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
		if y == 0.0:
			lines[y] += [tuple(l) for l in opt["paths"]]
	chests = [(c["pos"][0], c["pos"][1], c["pos"][2]) for c in plan.get("chests", [])]
	torches = [tuple(t) for t in plan.get("torches", [])]

	def free(parts_at, y, kind):
		"""parts_at: [(model, corners)]. None, or the parts' (x, z, radius)."""
		out = []
		for model, cs in parts_at:
			px, pz = sum(c[0] for c in cs) / 4, sum(c[1] for c in cs) / 4
			rad = max(math.hypot(c[0] - px, c[1] - pz) for c in cs)
			for pt in cs + [(px, pz)]:
				if level_of(pt, y) != kind:
					return None
			top = y + max(height(model), 0.3)
			for p in pieces:
				if kind == "piece" and p in supports and abs(p["top"] - y) < 0.06:
					continue
				lo, hi = p["pos"][1], p["top"]
				if p["id"] in STAIRS:
					if lo - 0.3 < y < hi + 0.3 and overlap(cs, footprint(p, STAIR_CLEAR)):
						return None
					continue
				if hi > y + 0.05 and lo < top and overlap(cs, footprint(p, 0.05)):
					return None
				if p["id"] in OPENINGS and abs(lo - y) < 1.0 and math.hypot(px - p["pos"][0], pz - p["pos"][2]) < OPENINGS[p["id"]] + rad:
					return None
			for (cx, cy, cz) in chests:
				if abs(cy - y) < 1.0 and math.hypot(px - cx, pz - cz) < THING_CLEAR + rad:
					return None
			for (tx, ty, tz) in torches:
				if abs(ty - y) < 1.0 and math.hypot(px - tx, pz - tz) < TORCH_CLEAR + rad:
					return None
			if y == 0.0:
				for (kx, kz) in opt["keep"]:
					if math.hypot(px - kx, pz - kz) < THING_CLEAR + rad:
						return None
			for (a, b) in lines.get(y, []):
				if seg_dist((px, pz), a, b) < PATH_CLEAR or any(seg_dist(c, a, b) < PATH_EDGE for c in cs):
					return None
			for (ox, oz, oy, r) in placed:
				if abs(oy - y) < 1.0 and math.hypot(px - ox, pz - oz) < r + rad + JUNK_GAP:
					return None
			out.append((px, pz, rad))
		return out

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
				if base >= 0.0 and not (-0.1 <= base - y <= 0.35):
					continue  # a wall hugs the floor it stands on
				if base < 0.0 and y != 0.0:
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
							zone = ("yard", 0.0)
						elif math.hypot(*probe) <= opt["out_reach"]:
							zone = ("out", 0.0)
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
				f = free([(model, cs)], 0.0, "ground")   # (camp mates: checked by their real outlines below)
				if f is None or any(overlap(cs, o) for o in outs):
					break
				outs.append(cs)
				got.append((f[0], {"model": model, "pos": [round(x, 3), 0.0, round(z, 3)], "yaw": round(yaw % 360.0, 1),
					"ground": True, "inside": False, "free": True}))
			if len(got) == len(CAMP):
				for f, j in got:
					placed.append((f[0], f[1], 0.0, f[2]))
					junk.append(j)
				print("  camp  at (%.1f, %.1f)" % (fx, fz))
				return True
		print("  camp  NO SPOT")
		return False

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
			want = rng.randint(3, 5) if a >= 80 else (rng.randint(2, 3) if a >= 25 else rng.randint(1, 2))
			pool = list(opt["pool"])
		rng.shuffle(pool)
		more = pool[:]
		rng.shuffle(more)
		pool = more + pool   # each kind at most twice
		n = 0
		while pool and n < want:
			if try_entry(pool.pop(), zone):
				n += 1
		print("  %-5s y=%-5s %d of %d (%d spots)" % (zone[0], zone[1], n, want, len(cands[zone])))
	out = ROOT / "blueprints/ruins" / f"{name}_junk.json"
	out.write_text(json.dumps({"junk": junk}, indent=0, separators=(",", ":")), encoding="utf-8")
	print("%s: %d junk pieces -> %s" % (name, len(junk), out.relative_to(ROOT)))
	return junk


if __name__ == "__main__":
	for n in (sys.argv[1:] or list(RUINS)):
		make(n)
