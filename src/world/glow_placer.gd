class_name GlowPlacer
## Glow Placer: picks spots on cave surfaces for things you can harvest:
## glowing crystals (walls, ceilings), roots (breaking out of floors, the first wood!), and mushrooms
## and fiber tufts (floors). Same seed = same spots, so every co-op player sees the
## same things, and each spot has an id the host can refer to.
##
## How: shoot pretend rays from inside each room/tunnel until they hit rock
## (using the Cave Maker's distance numbers), then put something there.

const CRYSTAL := "crystal"
const MUSHROOM := "glowcap"  ## the glowing blue mushroom
const ROOT := "root"
const MIN_SPACING := 2.5

## What each kind is. tool: "hand" (anything, even bare hands), "pickaxe", or "axe"
## (axe at full power, pickaxe at half). hardness uses the ×10 dig scale.
## chops: a root can be chopped through this many times before it's gone.
const KINDS := {
	"crystal": {item = "crystal_blue", count = [2, 4], tool = "pickaxe", hardness = 18, glow = true, color = Color(0.35, 0.75, 1.0), xp = 4, skill = "mining"},
	"crystal_green": {item = "crystal_green", count = [2, 4], tool = "pickaxe", hardness = 18, glow = true, color = Color(0.35, 1.0, 0.5), xp = 4, skill = "mining"},
	"glowcap": {item = "glowcap", count = [1, 1], tool = "hand", glow = true, color = Color(0.25, 0.95, 0.85), xp = 1, skill = "gathering"},
	"hollowcap": {item = "hollowcap", count = [1, 1], tool = "hand", color = Color(0.55, 0.38, 0.26), xp = 1, skill = "gathering"},
	"bellcap": {item = "bellcap", count = [1, 1], tool = "hand", color = Color(0.55, 0.7, 1.0), xp = 1, skill = "gathering"},
	"firecap": {item = "firecap", count = [1, 1], tool = "hand", glow = true, color = Color(1.0, 0.35, 0.2), xp = 1, skill = "gathering"},
	"fiber": {item = "fiber", count = [2, 3], tool = "hand", color = Color(0.5, 0.65, 0.3), xp = 1, skill = "gathering"},
	# Twigs lying on the floor: pick them up (E or a hit) for a bit of wood (owner, Nov 17: "missing a ton of wood").
	"twig": {item = "rootwood", count = [1, 1], tool = "hand", color = Color(0.36, 0.25, 0.15), xp = 1, skill = "gathering"},
	"root": {item = "rootwood", count = [3, 3], extra = "fiber", tool = "axe", hardness = 30, chops = 4, color = Color(0.42, 0.29, 0.18), xp = 3, skill = "woodcutting"},
	# Fungal Jungle. Giant mushrooms are the jungle's wood: tall stalks that need a copper axe
	# (or copper pickaxe at half power), and each chop also drops some flesh.
	"giant_mushroom": {item = "mushroom_wood", count = [3, 3], extra = "mushroom_flesh", tool = "axe", hardness = 40, min_tier = 1, chops = 4, color = Color(0.72, 0.5, 0.78), xp = 4, skill = "woodcutting"},
	"drip": {item = "", tool = "none", color = Color(0.55, 0.75, 0.95)},
	# Thin roots in the starting room: pull them by hand for your first pickaxe handle (feedback F11).
	"root_dangle": {item = "rootwood", count = [1, 1], extra = "fiber", tool = "hand", color = Color(0.45, 0.31, 0.19), xp = 1, skill = "gathering"},
	"crystal_amber": {item = "crystal_amber", count = [2, 3], tool = "pickaxe", hardness = 22, glow = true, color = Color(1.0, 0.72, 0.28), xp = 5, skill = "mining"},
	# More colours (owner, Nov 17: "so many crystals are just blue"; picked: real crystals, the strong ones rare).
	"crystal_violet": {item = "crystal_violet", count = [2, 3], tool = "pickaxe", hardness = 20, glow = true, color = Color(0.68, 0.42, 1.0), xp = 5, skill = "mining"},
	"crystal_white": {item = "crystal_white", count = [1, 2], tool = "pickaxe", hardness = 26, glow = true, color = Color(0.92, 0.95, 1.0), xp = 8, skill = "mining"},
	"crystal_red": {item = "crystal_red", count = [1, 2], tool = "pickaxe", hardness = 24, glow = true, color = Color(1.0, 0.32, 0.28), xp = 7, skill = "mining"},
	"spore_truffle": {item = "spore_truffle", count = [1, 2], tool = "hand", color = Color(0.45, 0.33, 0.52), xp = 1, skill = "gathering"},
	"ember_morel": {item = "ember_morel", count = [1, 1], tool = "hand", glow = true, color = Color(1.0, 0.45, 0.15), xp = 2, skill = "gathering"},
}
const GIANT := "giant_mushroom"
## Dripping stalactites: not harvestable, they mark where a Drip Bucket collects water (doc 6.4).
const DRIP := "drip"
const DRIP_REACH := 3.0  ## a bucket within this many meters (sideways) of a drip fills up
## Kinds that stand tall (or hang long): their size is `length`, not `scale`.
const TALL := ["root", "giant_mushroom", "root_dangle"]
const ROOT_DANGLE := "root_dangle"

static var _placed := {}  ## "seed:layout" -> spots (copied out, because a GlowField changes its own copy)


## Returns an Array of {id, pos, normal, kind, color, scale, spin, length}.
static func place(maker: CaveMaker) -> Array[Dictionary]:
	var key := "%d:%d" % [maker.seed, maker.made_layout]
	if not _placed.has(key):
		_placed[key] = PlanCache.get_or_make("glow", maker, "res://src/world/glow_placer.gd", func() -> Array: return _place(maker))
	var out: Array[Dictionary] = []
	for s in _placed[key]:
		out.append(s.duplicate())
	return out


static func _place(maker: CaveMaker) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = maker.seed + 777
	var spots: Array[Dictionary] = []
	var near := {}  # spacing grid (F211 speed): spots by 2.5 m box, so a new spot checks only its neighbours
	# One biome after the other, so adding a biome never moves the spots of the ones before it.
	for biome in ["mossy", "fungal"]:
		for room in maker.rooms:
			if room.get("biome", "mossy") != biome:
				continue
			var count := 70 if room.big else 14
			for i in count:
				var dir := _random_dir(rng)
				if i % 3 == 0:
					dir.y = -absf(dir.y) - 0.6  # aim at the floor (mushrooms, fiber)
				elif i % 5 == 1:
					dir.y = absf(dir.y) + 0.8  # aim at the ceiling (crystals, drips)
				_try_add(maker, rng, spots, near, room.center, dir.normalized(), 70.0, biome)
		for i in range(0, maker.segments.size(), 2):
			var s: Dictionary = maker.segments[i]
			var mid: Vector3 = (s.a + s.b) * 0.5
			if CaveMaker.biome_at(mid) == biome:
				_try_add(maker, rng, spots, near, mid, _random_dir(rng), 12.0, biome)
	# Added after everything above (with their own dice), so older spots never move.
	_add_low_crystals(maker, spots)
	_add_start_spots(maker, spots)
	_add_first_drip(maker, spots)
	_add_more_roots(maker, spots)
	_add_twigs(maker, spots)
	_mix_crystal_colours(spots)
	_thin_crystals_under_stars(maker, spots)
	_add_wood_everywhere(maker, spots)
	var trees := RootPillars.plan(maker) if maker.made_layout >= 13 else []
	# No little root, twig or fiber growing over a crystal (owner, Nov 19): the later passes add them without looking
	# at the crystals, so one that lands right by a crystal is left out (kept in the list: ids stay the same).
	var crystals := {}
	for s in spots:
		if String(s.kind).begins_with("crystal"):
			var key := Vector3i((s.pos / 2.0).floor())
			if not crystals.has(key):
				crystals[key] = []
			crystals[key].append(s)
	for s in spots:
		if s.kind in [ROOT, ROOT_DANGLE, "twig", "fiber"] and maker.made_layout >= 13:
			var c0 := Vector3i(((s.pos as Vector3) / 2.0).floor())
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					for dz in range(-1, 2):
						for c in crystals.get(c0 + Vector3i(dx, dy, dz), []):
							if (c.pos as Vector3).distance_to(s.pos) < 0.6 + 0.6 * float(c.get("scale", 1.0)):
								s.hidden = true
	for s in spots:
		if maker.is_reserved(s.pos, 0.5) or maker.on_bridge(s.pos):  # (built ground; bridge tops: owner Nov 18)
			s.hidden = true  # on a built thing's ground (the placement rule); kept in the list so ids stay the same
		for t in trees:  # nor inside a Root Tree (owner, Nov 18: water dripping inside a tree)
			var p: Vector3 = s.pos
			if p.y > (t.bottom as Vector3).y - 1.0 and p.y < (t.top as Vector3).y + 1.0 and Vector2(p.x - t.top.x, p.z - t.top.z).length() < float(t.width) * (0.75 if s.kind == DRIP else 0.5):
				s.hidden = true
	for i in spots.size():
		spots[i].id = i
	return spots


## Lantern fuel you can actually reach (feedback F12): most crystals grow high on walls and
## ceilings, so every room also gets a few at dwarf height, found by looking sideways from the floor.
static func _add_low_crystals(maker: CaveMaker, spots: Array[Dictionary]) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = maker.seed + 778
	var near := {}
	for s in spots:
		_grid_put(near, s.pos)
	for room in maker.rooms:
		if room.get("sealed", false):
			continue
		var c: Vector3 = room.center
		var fl := maker.find_floor(c.x, c.z, c.y)
		var eye := fl + Vector3.UP * 1.3
		if maker.sdf_at(eye) <= 0.0:
			continue
		var want := 8 if room.big else 3
		var first := rng.randf_range(0.0, TAU)
		for i in want * 2:
			if want <= 0:
				break
			var a := first + i * TAU / float(want * 2)
			var dir := Vector3(cos(a), rng.randf_range(-0.12, 0.05), sin(a)).normalized()
			var hit := _march(maker, eye, dir, 60.0)
			if hit == Vector3.INF:
				continue
			var below := _march(maker, hit + Vector3.UP * 0.3 + (eye - hit).normalized() * 0.6, Vector3.DOWN, 6.0)
			if below == Vector3.INF or hit.y - below.y > 2.2:
				continue  # too high to reach from the floor here
			if not _spaced_grid(near, hit):
				continue
			var kind := CRYSTAL
			if room.get("biome", "mossy") == "fungal":
				kind = "crystal_amber" if rng.randf() < 0.35 else CRYSTAL
			_add_spot(spots, hit, normal_at(maker, hit), kind, rng.randf_range(1.3, 2.0), rng.randf_range(0, TAU), 0.0)
			_grid_put(near, hit)
			want -= 1


## More roots for wood (owner, Nov 17: "I'm missing a ton of wood... make more of them"): a few extra roots on the
## floor of every room, more in big caverns. Added after everything else, with their own dice, so every older spot keeps
## its id; marked `extra` so the cave plants don't grow new patches round them (the plants keep their ids too).
const MORE_ROOTS_BIG := 6
const MORE_ROOTS_ROOM := 2

static func _add_more_roots(maker: CaveMaker, spots: Array[Dictionary]) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = maker.seed + 780
	var near := {}
	for s in spots:
		_grid_put(near, s.pos)
	for room in maker.rooms:
		if room.get("sealed", false) or room.get("biome", "mossy") == "fungal" or maker.sdf_at(room.center) <= 0.0:
			continue
		var want: int = MORE_ROOTS_BIG if room.big else MORE_ROOTS_ROOM
		for i in want * 4:
			if want <= 0:
				break
			var dir := Vector3(rng.randf_range(-1, 1), -rng.randf_range(0.5, 1.0), rng.randf_range(-1, 1)).normalized()
			var hit := _march(maker, room.center, dir, 60.0)
			if hit == Vector3.INF or normal_at(maker, hit).y < 0.8:
				continue  # floors only
			if maker.sdf_at(hit + Vector3.UP * 1.0) <= 0.4 or not _solid_ground(maker, hit) or not _spaced_grid(near, hit):
				continue
			if maker.sdf_at(hit - Vector3.UP * 0.8) >= 0.0:
				continue
			var length := 1.2 + 0.7 * fposmod(hit.x * 7.3 + hit.z * 3.1, 1.0)
			spots.append({id = -1, pos = hit, normal = Vector3.UP, kind = ROOT, color = KINDS[ROOT].color, scale = 1.0,
				spin = rng.randf_range(0, TAU), length = length, chops = KINDS[ROOT].get("chops", 1), extra = true})
			_grid_put(near, hit)
			want -= 1


## Every crystal gets its colour from its own spot (no dice, so nothing else moves; the same on every computer):
## blue 38%, green 24%, violet 18%, amber 14%, and the strong ones rare: white 3% (burns 10 min), red 3% (Ember Bolts).
const CRYSTAL_MIX := [["crystal", 0.38], ["crystal_green", 0.62], ["crystal_violet", 0.8], ["crystal_amber", 0.94], ["crystal_white", 0.97], ["crystal_red", 1.0]]

static func _mix_crystal_colours(spots: Array[Dictionary]) -> void:
	for s in spots:
		if not String(s.kind).begins_with("crystal"):
			continue
		var p: Vector3 = s.pos
		var h := float(posmod(hash(Vector3i((p * 10.0).round())), 10007)) / 10007.0
		for m in CRYSTAL_MIX:
			if h < m[1]:
				s.kind = m[0]
				s.color = KINDS[m[0]].color
				break


## Under the glow-worm stars (the ceiling patches the rock shader lights up), only about 1 crystal in 8 stays (owner,
## Nov 17: "less crystals around the dots, not none, very rare"). The others are only marked `hidden` (the game doesn't
## build them), so every spot keeps its id and saves still match.
static func _thin_crystals_under_stars(maker: CaveMaker, spots: Array[Dictionary]) -> void:
	var first := maker.star_room()
	for s in spots:
		if not String(s.kind).begins_with("crystal") or (s.normal as Vector3).y > -0.3:
			continue  # only crystals on ceilings and the tops of walls
		var big := 0.0
		if not first.is_empty():  # the star room has more star patches (terrain.gdshader `inbig`)
			var rr: float = first.radius
			big = 1.0 - smoothstep(rr * 0.8, rr * 1.05, Vector2(s.pos.x - first.center.x, s.pos.z - first.center.z).length())
			big *= smoothstep(0.36, 0.56, _vnoise(s.pos * 0.05 + Vector3(7.0, 1.0, 3.0)))
		if maxf(star_patch(s.pos), big) < 0.15:
			continue
		var p: Vector3 = s.pos
		if float(posmod(hash(Vector3i((p * 7.0).round())), 1009)) / 1009.0 > 0.12:
			s.hidden = true


## How much the rock shader's glow-worm star patch covers p (0..1): the same sum as terrain.gdshader
## (patches = smoothstep(0.45, 0.68, vnoise(v_world * 0.05 + vec3(7, 1, 3))), its hash() and vnoise() copied).
static func star_patch(p: Vector3) -> float:
	return smoothstep(0.45, 0.68, _vnoise(p * 0.05 + Vector3(7.0, 1.0, 3.0)))


static func _shader_hash(p: Vector3) -> float:
	var q := Vector3(fposmod(p.x * 0.3183099 + 0.1, 1.0), fposmod(p.y * 0.3183099 + 0.1, 1.0), fposmod(p.z * 0.3183099 + 0.1, 1.0)) * 17.0
	return fposmod(q.x * q.y * q.z * (q.x + q.y + q.z), 1.0)


static func _vnoise(x: Vector3) -> float:
	var i := x.floor()
	var f := x - i
	f = f * f * (Vector3.ONE * 3.0 - 2.0 * f)
	var a := lerpf(lerpf(_shader_hash(i), _shader_hash(i + Vector3(1, 0, 0)), f.x), lerpf(_shader_hash(i + Vector3(0, 1, 0)), _shader_hash(i + Vector3(1, 1, 0)), f.x), f.y)
	var b := lerpf(lerpf(_shader_hash(i + Vector3(0, 0, 1)), _shader_hash(i + Vector3(1, 0, 1)), f.x), lerpf(_shader_hash(i + Vector3(0, 1, 1)), _shader_hash(i + Vector3(1, 1, 1)), f.x), f.y)
	return lerpf(a, b, f.z)


## Twigs on the floors of Mossy rooms and caverns (they replace the old look-only twigs).
const TWIGS_BIG := 10
const TWIGS_ROOM := 3

static func _add_twigs(maker: CaveMaker, spots: Array[Dictionary]) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = maker.seed + 781
	for room in maker.rooms:
		if room.get("sealed", false) or room.get("biome", "mossy") == "fungal" or maker.sdf_at(room.center) <= 0.0:
			continue
		var want: int = TWIGS_BIG if room.big else TWIGS_ROOM
		for i in want * 3:
			if want <= 0:
				break
			var dir := Vector3(rng.randf_range(-1, 1), -rng.randf_range(0.4, 1.0), rng.randf_range(-1, 1)).normalized()
			var spin := rng.randf_range(0, TAU)
			var hit := _march(maker, room.center, dir, 60.0)
			if hit == Vector3.INF:
				continue
			var n := normal_at(maker, hit)
			if n.y < 0.8:
				continue
			spots.append({id = -1, pos = hit, normal = n, kind = "twig", color = KINDS["twig"].color, scale = rng.randf_range(0.8, 1.3),
				spin = spin, length = 0.0, chops = 1, extra = true})
			want -= 1


## Wood in every cave (owner, Nov 18: "I want to build there [the Fallen Outpost's cave] but there's no wood at all...
## every cave should have roots, quite a bit of them"): 8 more roots in each big cave, 3 in each small one, all over
## Mossy Hollows, round the edges of ground kept clear for ruins too. Added last (ids of everything before stay the same).
const WOOD_BIG := 8
const WOOD_ROOM := 3


static func _add_wood_everywhere(maker: CaveMaker, spots: Array[Dictionary]) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = maker.seed + 782
	var near := {}
	for s in spots:
		_grid_put(near, s.pos)
	for room in maker.rooms:
		# (the Fungal Jungle has no roots by design: its wood is the giant mushrooms)
		if room.get("sealed", false) or room.get("biome", "mossy") == "fungal" or maker.sdf_at(room.center) <= 0.0:
			continue
		var want: int = WOOD_BIG if room.big else WOOD_ROOM
		for i in want * 14:
			if want <= 0:
				break
			# low, far-reaching lines: they reach the cave's edges too (round a ruin's kept-clear middle)
			var dir := Vector3(rng.randf_range(-1, 1), -rng.randf_range(0.12, 0.7), rng.randf_range(-1, 1)).normalized()
			var hit := _march(maker, room.center, dir, 60.0)
			if hit == Vector3.INF or normal_at(maker, hit).y < 0.8 or maker.is_reserved(hit, 2.0):
				continue
			if maker.sdf_at(hit + Vector3.UP * 1.0) <= 0.4 or not _solid_ground(maker, hit) or not _spaced_grid(near, hit):
				continue
			if maker.sdf_at(hit - Vector3.UP * 0.8) >= 0.0:
				continue
			var length := 1.2 + 0.7 * fposmod(hit.x * 7.3 + hit.z * 3.1, 1.0)
			spots.append({id = -1, pos = hit, normal = Vector3.UP, kind = ROOT, color = KINDS[ROOT].color, scale = 1.0,
				spin = rng.randf_range(0, TAU), length = length, chops = KINDS[ROOT].get("chops", 1), extra = true})
			_grid_put(near, hit)
			want -= 1


## The first cavern always has a dripping stalactite, so you learn early how to get water (owner F140).
## Hung from the ceiling over open floor, a few metres from the middle.
static func _add_first_drip(maker: CaveMaker, spots: Array[Dictionary]) -> void:
	var first: Dictionary = {}
	for room in maker.rooms:
		if room.get("kind", "") == "spawn":
			first = room
	if first.is_empty():
		return
	var c: Vector3 = first.center
	for s in spots:
		if s.kind == DRIP and s.pos.distance_to(c) < maxf(first.radii.x, first.radii.z):
			return  # it already has one
	# (layout 4's first cavern is huge with a high dome: try further out toward its walls too, where the ceiling is low
	# enough for a bucket under it to catch the drops: Drip Buckets fill from up to 15 m below)
	var rings := [0.35, 0.6, 0.75, 0.85, 0.92] if maker.huge_first() else [0.35]
	for frac in rings:
		for k in 8:
			var a := k * TAU / 8.0
			var r := minf(first.radii.x, first.radii.z) * float(frac)
			var fl := maker.find_floor(c.x + cos(a) * r, c.z + sin(a) * r, c.y)
			if maker.sdf_at(fl + Vector3.UP * 1.0) <= 0.0:
				continue
			var top := _march(maker, fl + Vector3.UP * 1.0, Vector3.UP, 20.0)
			if top == Vector3.INF or (maker.huge_first() and top.y - fl.y > 14.0):
				continue
			_add_spot(spots, top, Vector3.DOWN, DRIP, 1.0, 0.0, 0.0)
			return


## The starting room: roots to pull, glowing mushrooms, and the crystals you see through the peephole.
static func _add_start_spots(maker: CaveMaker, spots: Array[Dictionary]) -> void:
	var st := maker.start
	if st.is_empty():
		return
	for p in st.roots:  # small roots sticking out of the floor (owner, Nov 16: roots grow out of the ground)
		var fl := _march(maker, p, Vector3.DOWN, 8.0)
		if fl == Vector3.INF:
			continue
		_add_spot(spots, fl, Vector3.UP, ROOT_DANGLE, 1.0, fposmod(p.x * 3.7 + p.z * 1.3, TAU), 0.55)
	for p in st.caps:
		var fl := _march(maker, p + Vector3.UP * 1.0, Vector3.DOWN, 4.0)
		if fl != Vector3.INF:
			_add_spot(spots, fl, Vector3.UP, MUSHROOM, 1.1, 0.0, 0.0)
	var a0: Vector3 = st.tunnel[0].a
	var u: Vector3 = st.dir
	for gp in st.tunnel_glow:
		var p: Vector3 = gp
		var axis: Vector3 = a0 + u * (p - a0).dot(u)
		var out: Vector3 = p - axis
		var dir := out.normalized() if out.length() > 0.1 else Vector3.UP
		var hit := _march(maker, axis, dir, 6.0)
		if hit != Vector3.INF:
			_add_spot(spots, hit, normal_at(maker, hit), CRYSTAL, 1.8, 0.0, 0.0)


static func _spaced(spots: Array[Dictionary], p: Vector3) -> bool:
	for s in spots:
		if s.pos.distance_to(p) < MIN_SPACING:
			return false
	return true


## The spacing grid: same answer as checking every spot (boxes as wide as the spacing, so the 27 boxes round a point
## hold every spot that could be too close), but only looks at a few spots instead of thousands.
static func _grid_put(near: Dictionary, p: Vector3) -> void:
	var c := Vector3i((p / MIN_SPACING).floor())
	if not near.has(c):
		near[c] = []  # a plain Array: a PackedVector3Array taken out of a Dictionary is a copy, so appending to it is lost
	(near[c] as Array).append(p)


static func _spaced_grid(near: Dictionary, p: Vector3) -> bool:
	var c := Vector3i((p / MIN_SPACING).floor())
	for x in range(-1, 2):
		for y in range(-1, 2):
			for z in range(-1, 2):
				var k := c + Vector3i(x, y, z)
				if near.has(k):
					for q: Vector3 in near[k]:
						if q.distance_to(p) < MIN_SPACING:
							return false
	return true


static func _add_spot(spots: Array[Dictionary], pos: Vector3, n: Vector3, kind: String, scale: float, spin: float, length: float) -> void:
	spots.append({id = -1, pos = pos, normal = n, kind = kind, color = KINDS[kind].color,
		scale = 1.0 if kind in TALL else scale, spin = spin, length = length, chops = KINDS[kind].get("chops", 1)})


static func _random_dir(rng: RandomNumberGenerator) -> Vector3:
	var v := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1))
	return v.normalized() if v.length() > 0.01 else Vector3.UP


static func _try_add(maker: CaveMaker, rng: RandomNumberGenerator, spots: Array[Dictionary], near: Dictionary, start: Vector3, dir: Vector3, max_dist: float, biome: String) -> void:
	if maker.sdf_at(start) <= 0.0:
		return
	var hit := _march(maker, start, dir, max_dist)
	if hit == Vector3.INF:
		return
	if not _spaced_grid(near, hit):
		return
	var n := normal_at(maker, hit)
	var kind := _pick_kind(n, rng) if biome == "mossy" else _pick_fungal(n, rng)
	if kind == ROOT and (maker.sdf_at(hit + Vector3.UP * 1.0) <= 0.4 or not _solid_ground(maker, hit)):
		kind = MUSHROOM  # no room above, or no solid ground for the root's ends to dive into
	var length := 0.0
	if kind == ROOT:
		# Roots break out of the floor (owner, Nov 16), standing straight up; `length` = how big (about its height).
		# Sized from the spot itself, not the dice, so the spots after it keep their places.
		n = Vector3.UP
		length = 1.2 + 0.7 * fposmod(hit.x * 7.3 + hit.z * 3.1, 1.0)
	elif kind == GIANT:
		# Giant mushrooms stand straight up, 3-6 m tall, never touching the ceiling.
		n = Vector3.UP
		var above := _march(maker, hit + Vector3.UP * 0.5, Vector3.UP, 12.0)
		var room := hit.distance_to(above) if above != Vector3.INF else 12.0
		length = minf(rng.randf_range(3.0, 6.0), room - 1.2)
		if length < 2.5:
			kind = "spore_truffle"
			length = 0.0
	var scale := rng.randf_range(0.7, 1.3) * (1.8 if kind.begins_with("crystal") else size_boost(hit))
	if kind in TALL:
		scale = 1.0  # stretched by `length` instead
	if maker.sdf_at(hit - n * 0.8) >= 0.0 or maker.sdf_at(hit + n * 0.8) <= 0.0:
		return  # on the edge of a rock slab or block: no solid rock behind it, or rock in front (F109)
	_grid_put(near, hit)
	spots.append({id = -1, pos = hit, normal = n, kind = kind, color = KINDS[kind].color, scale = scale,
		spin = rng.randf_range(0, TAU), length = length, chops = KINDS[kind].get("chops", 1)})


## Ground things are sometimes bigger, never smaller (owner F218: "sometimes bigger, sometimes a lot bigger"):
## about 2 in 3 stay as they are, 1 in 4 grow by 1.25-1.7x, 1 in 12 by 1.9-3.2x. Worked out from the spot's position,
## not from the dice, so every computer gets the same and nothing else in the cave moves. Used by the little
## mushrooms here, pebbles and rocks (Clutter), and ferns, grass, small roots, gravel, tiny mushrooms (CaveLife).
static func size_boost(p: Vector3) -> float:
	var h := hash(Vector3i((p * 20.0).round()))
	var r := float(posmod(h, 10007)) / 10007.0
	var t := float(posmod(h >> 14, 997)) / 997.0
	if r < 0.67:
		return 1.0
	if r < 0.92:
		return lerpf(1.25, 1.7, t)
	return lerpf(1.9, 3.2, t)


## Rock under the middle and all round (a root is ~1.6 m wide and turns any way): no ends hanging in the air.
static func _solid_ground(maker: CaveMaker, p: Vector3) -> bool:
	for o in [Vector3(0, -0.5, 0), Vector3(0.8, -0.3, 0), Vector3(-0.8, -0.3, 0), Vector3(0, -0.3, 0.8), Vector3(0, -0.3, -0.8)]:
		if maker.sdf_at(p + o) >= 0.0:
			return false
	return true


static func _pick_kind(n: Vector3, rng: RandomNumberGenerator) -> String:
	var r := rng.randf()
	if n.y > 0.65:  # floor
		# Lots more fiber on the floor (owner F175): 40% of floor plants, was 22%.
		if r < 0.18: return ROOT  # roots break out of the ground (owner, Nov 16; they used to hang from the ceiling)
		if r < 0.32: return "glowcap"
		if r < 0.43: return "hollowcap"
		if r < 0.52: return "bellcap"
		if r < 0.92: return "fiber"
		return "firecap"
	if n.y < -0.55 and r < 0.1:  # ceiling
		return DRIP
	return "crystal_green" if r > 0.88 else CRYSTAL


## Jungle choices. Wood comes from giant mushrooms on the floor instead of roots.
static func _pick_fungal(n: Vector3, rng: RandomNumberGenerator) -> String:
	var r := rng.randf()
	if n.y > 0.65:  # floor
		if r < 0.22: return GIANT
		if r < 0.45: return "spore_truffle"
		if r < 0.58: return "bellcap"
		if r < 0.78: return "fiber"
		if r < 0.88: return "ember_morel"
		return "hollowcap"
	if n.y < -0.55 and r < 0.15:
		return DRIP
	if r < 0.3:
		return "crystal_amber"
	return "crystal_green" if r > 0.9 else CRYSTAL


## Sphere tracing: jump forward by the distance to the nearest wall until we touch it.
static func _march(maker: CaveMaker, start: Vector3, dir: Vector3, max_dist: float) -> Vector3:
	var t := 0.0
	var p := start
	while t < max_dist:
		p = start + dir * t
		var d := maker.sdf_at(p)
		if d < 0.05:
			return p
		t += maxf((d - maker.march_slack()) * 0.8, 0.2)  # rock slab edges can be nearer than d (F109)
	return Vector3.INF


## Points away from the rock, into the air.
static func normal_at(maker: CaveMaker, p: Vector3) -> Vector3:
	const E := 0.4
	var g := Vector3(
		maker.sdf_at(p + Vector3(E, 0, 0)) - maker.sdf_at(p - Vector3(E, 0, 0)),
		maker.sdf_at(p + Vector3(0, E, 0)) - maker.sdf_at(p - Vector3(0, E, 0)),
		maker.sdf_at(p + Vector3(0, 0, E)) - maker.sdf_at(p - Vector3(0, 0, E)))
	return g.normalized() if g.length() > 0.0001 else Vector3.UP


## Drip spots near p (sideways distance), for Drip Buckets.
static func drip_near(spots: Array, p: Vector3) -> bool:
	for s in spots:
		if s.kind == DRIP and Vector2(s.pos.x - p.x, s.pos.z - p.z).length() <= DRIP_REACH and s.pos.y > p.y and s.pos.y - p.y < 15.0:
			return true
	return false


static func is_plant(kind: String) -> bool:
	return KINDS.get(kind, {}).get("tool", "") == "hand"
