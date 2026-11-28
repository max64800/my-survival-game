extends TestCase
## Ruin junk (owner, Nov 20; laid out by tools/ruins/ruin_junk.py, drawn by RuinJunk). The owner's placement rule, like
## test_columns_keep_out_of_the_tower: junk hugs the ruin's walls (outside: its walls and foundations); never inside a
## building piece, on a doorway, the gateway, stairs or foundation steps, within 1.5 m of a chest or where the
## Rebuilding Chest may stand, or on the path in front of the door. Checked against the plan's pieces.
## The ruin camp (step 3) stands free outside instead: its campfire, bedroll and pot keep FREE_CLEAR from every piece.

const HUG := ["wall", "wall_narrow", "half_wall", "window_wall", "window_wide", "ruin_wall_worn", "ruin_wall_collapsed"]
const NEAR_WALL := 1.3    # its middle is at most this far from a wall (or, outside, a foundation's side)
const DOOR_CLEAR := 2.0
const GATE_CLEAR := 3.0
const THING_CLEAR := 1.5
const STAIR_CLEAR := 0.9  # (the tool keeps 1.0)
const PATH_CLEAR := 0.9   # from the path out of the door / gateway (the tool keeps 1.0)
const FREE_CLEAR := 0.9   # the free-standing camp's middle from every building piece (the tool keeps 1.0 for every corner)
## The way in, in each ruin's frame: from just inside the door (gateway) straight out.
const PATHS := {"tower": [Vector2(0.0, 3.0), Vector2(0.0, 12.0)], "outpost": [Vector2(-0.27, 13.0), Vector2(-0.27, 25.0)],
	"brewhall": [Vector2(-5.0, 5.5), Vector2(-5.0, 14.0)], "spire": [Vector2(0.0, 3.0), Vector2(0.0, 12.0)],
	"cliff_galleries": [Vector2(-2.0, 9.0), Vector2(-2.0, 16.0)], "smeltery": [Vector2(1.0, 9.0), Vector2(1.0, 16.0)],
	"pillar_spiral": [Vector2(-7.0, 18.0), Vector2(-7.0, 27.0)], "manor": [Vector2(1.0, 7.0), Vector2(1.0, 11.0)],
	"prow_hall": [Vector2(3.0, 7.0), Vector2(3.0, 21.0)],
	"twin_gate": [Vector2(0.0, 13.0), Vector2(0.0, 22.5)]}
## More ways in (the Cliff Galleries' shed steps; the Smeltery's second yard steps and the furnace's door).
const MORE_PATHS := {"cliff_galleries": [[Vector2(-18.0, 9.0), Vector2(-18.0, 16.0)]],
	"smeltery": [[Vector2(9.0, 9.0), Vector2(9.0, 16.0)], [Vector2(-19.7, 6.0), Vector2(-19.7, 16.0)]],
	"manor": [[Vector2(-14.0, -4.0), Vector2(-19.5, -4.0)], [Vector2(7.0, -5.0), Vector2(7.0, -9.5)]],
	"prow_hall": [[Vector2(13.0, 7.0), Vector2(13.0, 21.0)]],
	"twin_gate": [[Vector2(0.0, 5.0), Vector2(0.0, -5.0)], [Vector2(-11.0, 3.0), Vector2(-11.0, -5.0)],
		[Vector2(11.0, 3.0), Vector2(11.0, -5.0)]]}
## The ruins whose catalogue pieces are their own set (prefix); the grand ruins (F976) use the shared catalogue.
const OWN_SET := {"tower": "rt_", "outpost": "ro_", "brewhall": "rb_", "spire": "rs_"}
## Each ruin's game class (its Rebuilding Chest spots).
static func _kind(n: String) -> RuinTower:
	match n:
		"tower": return RuinTower.new(null)
		"outpost": return RuinOutpost.new(null)
		"brewhall": return RuinBrewhall.new(null)
		"spire": return RuinSpire.new(null)
		"cliff_galleries": return RuinCliffGalleries.new(null)
		"smeltery": return RuinSmeltery.new(null)
		"pillar_spiral": return RuinPillarSpiral.new(null)
		"manor": return RuinManor.new(null)
		"prow_hall": return RuinProwHall.new(null)
		"twin_gate": return RuinTwinGate.new(null)
	return null
## The catalogue decor ("cat", owner Nov 21: "the rules are fluid") stands free in the room, not hugging a wall, and keeps
## less room: this much from a doorway's middle (the gateway: 1.8), stairs 0.5 (the tool: from the piece's outline).
const DECOR_DOOR := 1.2
const DECOR_STAIR := 0.4


func _ruins() -> Array:
	var out := []
	for n in RuinJunk.PLANS:
		out.append([n, RuinTower.load_plan(RuinJunk.PLANS[n]), RuinJunk.load_list(n)])
	return out


static func _top(p: Dictionary) -> float:
	return float(p.pos[1]) + Pieces.LIST[String(p.id)].size.y


static func _fp(p: Dictionary, grow := 0.0) -> PackedVector2Array:
	return Pieces.footprint(String(p.id), Vector3(p.pos[0], p.pos[1], p.pos[2]), int(p.rot), grow)


static func _seg_dist(q: Vector2, a: Vector2, b: Vector2) -> float:
	return q.distance_to(Geometry2D.get_closest_point_to_segment(q, a, b))


static func _poly_dist(q: Vector2, poly: PackedVector2Array) -> float:
	if Geometry2D.is_point_in_polygon(q, poly):
		return 0.0
	var d := INF
	for i in poly.size():
		d = minf(d, _seg_dist(q, poly[i], poly[(i + 1) % poly.size()]))
	return d


func test_ruins_have_junk() -> void:
	for r in _ruins():
		var junk: Array = r[2]
		check(junk.size() >= 10, "%s: some junk (got %d)" % [r[0], junk.size()])
		check(junk.any(func(j): return not j.inside), "%s: junk outside the walls" % r[0])
		check(junk.any(func(j): return j.inside and not j.ground), "%s: junk inside, on its floors" % r[0])
		for j in junk:
			check(ResourceLoader.exists("res://assets/models/" + String(j.model)), "%s: model %s exists" % [r[0], j.model])
		check(junk.any(func(j): return j.get("free", false) and String(j.model).ends_with("junk_campfire_cold.glb")),
			"%s: a free-standing camp with its cold campfire" % r[0])
	var yard: Array = _ruins()[1][2].filter(func(j): return j.inside and j.ground)
	check(yard.size() >= 5, "outpost: junk in its yard (got %d)" % yard.size())


func test_ruin_junk_keeps_off_the_ruin() -> void:
	for r in _ruins():
		var plan: Dictionary = r[1]
		var pieces: Array = plan.pieces.filter(func(p): return Pieces.LIST.has(String(p.id)))
		for j in r[2]:
			var at := Vector2(float(j.pos[0]), float(j.pos[2]))
			var y := float(j.pos[1]) - float(j.get("hung", 0.0))  # (a hung piece: the floor under it)
			var cat := bool(j.get("cat", false))
			var gap: bool = cat and j.ground and j.inside and float(j.pos[1]) == 0.0 and r[0] == "outpost" and 				(absf(at.x) > 13.0 or absf(at.y) > 13.0)  # (a palisade or gate bar filling a breach in the curtain)
			var tag := "%s: %s at %s" % [r[0], j.model, at]
			var on_floor := false
			var near_wall := INF
			var near_piece := INF
			for p in pieces:
				var id := String(p.id)
				var lo := float(p.pos[1])
				var hi := _top(p)
				var fp := _fp(p)
				var group: String = Pieces.LIST[id].get("group", "")
				if id in ["stairs", "foundation_steps"]:
					check(not (lo - 0.3 < y and y < hi + 0.3 and Geometry2D.is_point_in_polygon(at, _fp(p, DECOR_STAIR if cat else STAIR_CLEAR))),
						tag + ": clear of the %s" % id)
					continue
				if group in ["floor", "foundation"] and absf(hi - y) < 0.06 and Geometry2D.is_point_in_polygon(at, fp):
					on_floor = true
					continue
				if hi > y + 0.05 and lo < y + 0.3 and not gap:
					check(not Geometry2D.is_point_in_polygon(at, _fp(p, 0.05)), tag + ": not inside a %s" % id)
				if hi > y + 0.05:
					near_piece = minf(near_piece, _poly_dist(at, fp))
				if id == "doorway" and absf(lo - y) < 1.0:
					check(at.distance_to(Vector2(p.pos[0], p.pos[2])) >= (DECOR_DOOR if cat else DOOR_CLEAR), tag + ": off the doorway")
				if id == "gateway" and absf(lo - y) < 1.0:
					check(at.distance_to(Vector2(p.pos[0], p.pos[2])) >= GATE_CLEAR * (0.6 if cat else 1.0), tag + ": off the gateway")
				if id in HUG and lo - y > -0.1 and lo - y <= 0.35:
					near_wall = minf(near_wall, _poly_dist(at, fp))
				if j.ground and group == "foundation" and lo - y > -0.1 and lo - y < 1.1:  # (a grand ruin's: on its cave floor, or its yard dug 1 m down)
					near_wall = minf(near_wall, _poly_dist(at, fp))
			check(on_floor != bool(j.ground) or gap, tag + (": on the ground (no floor piece under it)" if j.ground else ": on a floor piece"))
			if j.get("free", false):
				check(j.ground and not j.inside, tag + ": the camp stands outside, on the ground")
				check(near_piece >= FREE_CLEAR, tag + ": the camp keeps clear of the ruin (%.2f m)" % near_piece)
			elif not cat:
				check(near_wall <= NEAR_WALL, tag + ": hugs a wall (%.2f m)" % near_wall)
			for c in plan.get("chests", []):
				if absf(float(c.pos[1]) - y) < 1.0:
					check(at.distance_to(Vector2(c.pos[0], c.pos[2])) >= THING_CLEAR, tag + ": 1.5 m from the %s" % c.kind)


func test_ruin_junk_keeps_off_the_way_in() -> void:
	var kinds := {}
	for r in _ruins():
		var n: String = r[0]
		kinds[n] = _kind(n)
		check(kinds[n] != null, "%s: its game class is known to this test" % n)
		if kinds[n] == null:
			continue
		var spots: Array[Vector2] = (kinds[n] as RuinTower)._chest_spots(float(r[1].get("radius", 4.2)))
		var paths: Array = [PATHS[n]] + MORE_PATHS.get(n, [])
		for j in r[2]:
			if not j.ground:
				continue
			var at := Vector2(float(j.pos[0]), float(j.pos[2]))
			for path in paths:
				check(_seg_dist(at, path[0], path[1]) >= PATH_CLEAR, "%s: %s at %s off the way in" % [n, j.model, at])
			for s in spots:
				check(at.distance_to(s) >= THING_CLEAR, "%s: %s at %s clear of the Rebuilding Chest spot %s" % [n, j.model, at, s])
	for k in kinds:
		(kinds[k] as Node).free()


## Everything, inside and outside, whole or broken, goes when the ruin is being rebuilt (owner, Nov 21; F864, Nov 25:
## "remove the carts, the place where I can get coal").
func test_rebuilt_ruin_drops_all_its_junk() -> void:
	var ruins := {"5": {name = "tower", junk = [["res://assets/models/dungeon/junk_bones.glb", Vector3(1, 0, 0), 0.0, true],
		["res://assets/models/dungeon/junk_rags.glb", Vector3(9, 0, 0), 0.0, false],
		["res://assets/models/decor/keg.glb", Vector3(9, 0, 3), 0.0, false],
		["res://assets/models/decor/rt_fallen_bell.glb", Vector3(9, 0, 5), 0.0, false]]}}
	var rj := RuinJunk.new(null)
	rj._draw(ruins)
	check_eq(rj.count, 4, "all drawn while the ruin stands")
	rj._gone["5"] = true
	rj._draw(ruins)
	check_eq(rj.shown, [], "nothing is left once it is rebuilt, not even the whole keg (F864)")
	rj.free()


## The Smeltery's own searchable props (ingot stack, ingot cart, coal scuttle, charcoal bay) go after a rebuild (F864:
## they were never marked as the ruin's, so they stayed).
func test_smeltery_props_go_after_a_rebuild() -> void:
	var lp := LootProps.new()
	lp._root = Node3D.new()
	lp.add_child(lp._root)
	lp.place_ruin("7", {name = "smeltery", origin = Vector3.ZERO, turn = 0})
	var had := lp.props.keys().filter(func(key): return String(key).begins_with("r:7:")).size()
	lp.tidy_ruin("7")
	var left := lp.props.keys().filter(func(key): return String(key).begins_with("r:7:")).size()
	check(had >= 4 and left == 0, "the Smeltery's props go (%d before, %d left)" % [had, left])
	lp.free()


## The catalogue pieces (owner, Nov 21: "Brewhall and Spire: nothing; Outpost and Watchtower: 2 props each"): every
## ruin's own pieces are in its list, on each floor, and the lootable ones are left to LootProps (searchable).
func test_ruins_have_their_catalogue_decor() -> void:
	for r in _ruins():
		var n: String = r[0]
		var cat: Array = r[2].filter(func(j): return j.get("cat", false))
		check(cat.size() >= 10, "%s: catalogue decor (got %d)" % [n, cat.size()])
		var floors := {}
		for j in cat:
			if OWN_SET.has(n):
				check(String(j.model).get_file().begins_with(OWN_SET[n]), "%s: %s is its own catalogue piece" % [n, j.model])
			else:
				check(String(j.model).begins_with("decor/"), "%s: %s is a catalogue piece" % [n, j.model])
			if not j.get("loot", false):
				check(not LootProps.LOOT.has(LootProps.model_id(String(j.model))), "%s: %s is searchable: marked loot" % [n, j.model])
			if not j.ground:
				floors[snappedf(float(j.pos[1]) - float(j.get("hung", 0.0)), 0.25)] = true
			if j.get("loot", false):
				check(LootProps.LOOT.has(LootProps.model_id(String(j.model))), "%s: %s is lootable" % [n, j.model])
		check(floors.size() >= (1 if n == "outpost" else 2), "%s: decor on its floors (%s)" % [n, floors.keys()])
		check(cat.any(func(j): return not j.inside), "%s: a piece out on the ground" % n)
	for n in ["tower", "outpost"]:
		check(RuinJunk.load_list(n).any(func(j): return j.get("loot", false)), "%s: a lootable piece" % n)


## Old saves get the decor too: junk from before it (no "jv") is made again, once.
func test_old_ruin_junk_is_made_again() -> void:
	check(RuinJunk.needs_junk({name = "spire"}), "a new ruin gets junk")
	check(RuinJunk.needs_junk({name = "tower", junk = []}), "a tower saved before the decor gets it made again")
	check(not RuinJunk.needs_junk({name = "tower", junk = [], jv = RuinJunk.JUNK_V}), "...but only once")
	check(not RuinJunk.needs_junk({name = "kiln"}), "the kiln has no junk list")
