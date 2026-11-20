extends TestCase
## Dungeons dug into the rock (owner, Nov 19, 2026; DungeonMap). Step 1: Mossgate Hold's rooms are carved into solid
## rock behind a cave wall, lined with old dwarf stone, every room can be walked to, and nothing the world grows
## stands inside it or in its doorway (the placement rule).

const SEEDS := [42, 7, 1234]
var _makers := {}


func _maker(sd: int) -> CaveMaker:
	if not _makers.has(sd):
		_makers[sd] = CaveMaker.new(sd)
	return _makers[sd]


func test_every_new_world_gets_mossgate_hold() -> void:
	for sd in SEEDS:
		var m := _maker(sd)
		check_eq(m.dungeons.size(), 1, "seed %d: one dungeon" % sd)
		if m.dungeons.is_empty():
			continue
		var d: Dictionary = m.dungeons[0]
		var far := Vector2(d.mouth.x - m.cavern_spawn.x, d.mouth.z - m.cavern_spawn.z).length()
		check(far > 60.0 and far < 300.0, "seed %d: a walk away from the start (%.0f m)" % [sd, far])
		var mouth: Vector3 = d.mouth
		check(is_equal_approx(fposmod(mouth.x, 2.0), 0.0) and is_equal_approx(fposmod(mouth.z, 2.0), 0.0),
			"seed %d: on the 2 m building grid" % sd)


func test_old_worlds_keep_their_caves() -> void:
	var was := CaveMaker.layout
	CaveMaker.use_layout(13)
	check(CaveMaker.new(42).dungeons.is_empty(), "a layout 13 world has no dungeon (old saves stay the same)")
	CaveMaker.use_layout(was)


func test_rooms_are_open_and_walls_are_old_dwarf_stone() -> void:
	check(not Mat.is_diggable(Mat.DWARF, 9), "no pickaxe breaks old dwarf stone")
	for sd in SEEDS:
		var m := _maker(sd)
		if m.dungeons.is_empty():
			continue
		var d: Dictionary = m.dungeons[0]
		for s in d.map.spaces:
			var mid := DungeonMap.space_floor(d, String(s[0])) + Vector3.UP * minf(1.5, float(s[6]) * 0.5)
			check(m.sdf_at(mid) > 0.5, "seed %d: %s is open" % [sd, s[0]])
		# Just behind each wall of the gate hall (1 m into the rock): rock, old dwarf stone.
		for q in [Vector3(25.0, 2.0, 37.0), Vector3(43.0, 2.0, 45.0), Vector3(34.0, 6.0, 40.0), Vector3(34.0, -1.0, 40.0)]:
			var w := DungeonMap.to_world(d, q)
			check(m.sdf_at(w) < 0.0, "seed %d: rock at %s" % [sd, q])
			check_eq(m.material_at(Vector3i(w.round())), Mat.DWARF, "seed %d: old dwarf stone at %s" % [sd, q])


## Walk the floor 1 m at a time from the way in: every space must be reached (the chasm is crossed by its bridge
## later, so here its open air counts as floor).
func test_every_room_can_be_reached() -> void:
	for sd in SEEDS:
		var m := _maker(sd)
		if m.dungeons.is_empty():
			continue
		var d: Dictionary = m.dungeons[0]
		var mouth: Vector2 = d.map.mouth
		var start := Vector2i(int(mouth.x), int(mouth.y) + 2)
		var seen := {start: true}
		var todo := [start]
		while not todo.is_empty():
			var c: Vector2i = todo.pop_back()
			for n in [c + Vector2i(1, 0), c - Vector2i(1, 0), c + Vector2i(0, 1), c - Vector2i(0, 1)]:
				if seen.has(n) or n.x < -2 or n.x > 90 or n.y < -2 or n.y > 70:
					continue
				if m.sdf_at(DungeonMap.to_world(d, Vector3(n.x + 0.5, 1.0, n.y + 0.5))) > 0.3:
					seen[n] = true
					todo.append(n)
		for s in d.map.spaces:
			var c := Vector2i(int((float(s[1]) + float(s[3])) * 0.5), int((float(s[2]) + float(s[4])) * 0.5))
			check(seen.has(c), "seed %d: %s can be walked to" % [sd, s[0]])


## The placement rule (CLAUDE.md, owner Nov 17): nothing the world grows inside the dungeon or in its doorway.
func test_nothing_grows_inside_the_dungeon() -> void:
	for sd in SEEDS:
		var m := _maker(sd)
		if m.dungeons.is_empty():
			continue
		var d: Dictionary = m.dungeons[0]
		# Every room, and the cave floor in front of the door, is kept clear for the placers (they ask is_reserved).
		for s in d.map.spaces:
			check(m.is_reserved(DungeonMap.space_floor(d, String(s[0])) + Vector3.UP * 0.3), "seed %d: %s kept clear" % [sd, s[0]])
		var door := DungeonMap.to_world(d, Vector3(d.map.mouth.x, 0.2, d.map.mouth.y + float(d.entry_out) + 1.0))
		check(m.is_reserved(door), "seed %d: the doorway kept clear" % sd)
		for p in m.pois:
			check(not DungeonMap.covers(d, p.pos, 1.0), "seed %d: no %s inside the dungeon" % [sd, p.type])
		for o in m._cols:
			check(not DungeonMap.covers(d, Vector3(o.x, d.mouth.y + 2.0, o.y), o.z), "seed %d: no stone column in the dungeon" % sd)
		for k in range(0, 13, 2):  # (owner, Nov 19: a column stood right in front of the door)
			var q := DungeonMap.to_world(d, Vector3(d.map.mouth.x, 1.0, d.map.mouth.y + float(d.entry_out) + float(k)))
			check(not m._in_column(q, 1.0), "seed %d: no column in front of the door (%d m out)" % [sd, k])
			for p in m.pois:
				check(Vector2(q.x - p.pos.x, q.z - p.pos.z).length() >= 10.0 or absf(q.y - p.pos.y) >= 8.0,
					"seed %d: no %s in front of the door (%d m out)" % [sd, p.type, k])
	# Crystals, roots, twigs and drips (one world: the placer is slow).
	var m42 := _maker(42)
	if not m42.dungeons.is_empty():
		var bad := 0
		for spot in GlowPlacer.place(m42):
			if not spot.get("hidden", false) and DungeonMap.covers(m42.dungeons[0], spot.pos, 0.5):
				bad += 1
		check_eq(bad, 0, "no crystals, roots or twigs in the dungeon or its doorway")


## Step 2 (owner, Nov 19): the hold's root wood, traps and furniture come from its plan; every model it names exists,
## and every piece, prop and chest gets a place.
func test_the_plan_builds() -> void:
	var m := _maker(42)
	if m.dungeons.is_empty():
		return
	var plan := DungeonBuild.load_plan("mossgate")
	check(not plan.is_empty(), "Mossgate Hold's plan loads")
	var all := DungeonBuild.placements(m.dungeons[0], plan)
	var n := 0
	for model in all:
		check(ResourceLoader.exists("res://assets/models/" + String(model)), "model %s exists" % model)
		n += (all[model] as Array).size()
	check_eq(n, plan.pieces.size() + plan.props.size() + plan.chests.size(), "every piece, prop and chest is placed")
	check(plan.pieces.size() + plan.props.size() > 1500, "root wood rooms (%d pieces and props)" % (plan.pieces.size() + plan.props.size()))


# ---- The owner's first play of the dungeon test (Nov 19) ----

## Note 1: no gaps beside the round door. The corridor ends at the door inside solid rock, and from there to the cave
## the hole is smaller than the door's stone frame (3.07 x 2.64 m), so the frame covers its edges.
func test_the_door_frame_covers_its_hole() -> void:
	check(DungeonMap.DOOR_HOLE.x < 3.0 and DungeonMap.DOOR_HOLE.y < 2.6, "the hole is smaller than the frame")
	for sd in SEEDS:
		var m := _maker(sd)
		if m.dungeons.is_empty():
			continue
		var d: Dictionary = m.dungeons[0]
		var face := DungeonMap.mouth_z(d.map)
		var mx: float = d.map.mouth.x
		for q in [Vector3(mx - 1.7, 1.0, face + 0.5), Vector3(mx + 1.7, 1.0, face + 0.5), Vector3(mx, 2.8, face + 0.5),
				Vector3(mx - 2.6, 1.0, face - 0.5), Vector3(mx + 2.6, 2.0, face - 1.0)]:
			check(m.sdf_at(DungeonMap.to_world(d, q)) < 0.0, "seed %d: rock beside the door at %s" % [sd, q])
		check(m.sdf_at(DungeonMap.to_world(d, Vector3(mx, 1.2, face + 0.5))) > 0.3, "seed %d: the door's hole is open" % sd)
		check(m.sdf_at(DungeonMap.to_world(d, Vector3(mx, 1.2, face - 1.0))) > 0.3, "seed %d: the corridor reaches the door" % sd)


## Note 7: the tunnels are 2 m+ high: corridors' root wood ceilings at 3 m (2.76 m to walk under), rooms' at 4 m,
## and every doorway 1.5x the kit's (a round hole about 2 m wide and 2.6 m high). The rock is higher than every ceiling.
func test_corridors_and_doorways_are_tall_enough() -> void:
	var plan := DungeonBuild.load_plan("mossgate")
	var doors := 0
	for p in plan.pieces:
		if p.id == "doorway":
			doors += 1
			check_eq(float(p.get("scale", 1.0)), 1.5, "doorway at %s is 1.5x" % [p.pos])
		if p.id == "floor" and float(p.pos[1]) > 1.0:
			check(float(p.pos[1]) >= 3.0, "ceiling at %s is 3 m+ high" % [p.pos])
	check(doors >= 20, "every junction has its doorway (%d)" % doors)
	for s in DungeonMap.MOSSGATE.spaces:
		if float(s[5]) >= 0.0:
			check(float(s[6]) + DungeonMap.GAP >= 3.5, "%s: the rock stands over its ceiling" % s[0])


## The owner, Nov 19: "about 70% old and rotten, the rest normal".
func test_most_floors_and_walls_are_old() -> void:
	var plan := DungeonBuild.load_plan("mossgate")
	var old := 0
	var normal := 0
	for p in plan.props:
		if String(p.model) in ["dungeon/floor_old.glb", "dungeon/wall_old.glb"]:
			old += 1
	for p in plan.pieces:
		if p.id == "wall" or (p.id == "floor" and float(p.pos[1]) < 1.0):
			normal += 1
	var share := float(old) / float(old + normal)
	check(share > 0.6 and share < 0.8, "%.0f%% of floors and walls are old" % (share * 100.0))


## Owner: "I couldn't get onto the bridge". Its deck is level with the floor boards' top (0.24 m), and the post frames
## only block at their two posts.
func test_the_bridge_is_level_with_the_floor() -> void:
	var plan := DungeonBuild.load_plan("mossgate")
	for p in plan.props:
		if String(p.model).begins_with("dungeon/bridge_"):
			check(absf(float(p.pos[1]) + 0.11 - 0.24) < 0.02, "%s deck top at the floor's height" % p.model)
	var posts: Array = DungeonBuild.BOXES["dungeon/bridge_posts.glb"]
	for bx in posts:
		var top: float = (bx[0] as Vector3).y + (bx[1] as Vector3).y * 0.5
		var mid: float = absf((bx[0] as Vector3).x)
		check(top <= 0.12 or mid > 0.5, "the posts' boxes leave the walkway free")


## Note 6: stalactites hang down from the rock (flipped, their base in the ceiling) and can fall.
func test_stalactites_hang_down() -> void:
	var plan := DungeonBuild.load_plan("mossgate")
	var n := 0
	for p in plan.props:
		if DungeonBuild.thing_kind(p) == "drip":
			n += 1
			check_eq(float(p.get("tilt", 0.0)), 180.0, "stalactite at %s is upside down (hanging)" % [p.pos])
			check(float(p.pos[1]) > 7.0, "stalactite at %s hangs from the rock ceiling" % [p.pos])
	check_eq(n, 6, "six stalactites")


## Notes 3 and 5: chests have loot, the recipe stand holds the same scroll every time (the Copper Shield), and the
## furniture, rubble, hidden boulder and cracked floor can be broken.
func test_chests_and_breakable_things() -> void:
	var plan := DungeonBuild.load_plan("mossgate")
	for c in plan.chests:
		check(DungeonBuild.LOOT.has(String(c.get("loot", ""))), "chest %s has a loot list" % c.label)
	check_eq(String(plan.recipe_stand.page), "scroll_mossgate", "the recipe stand holds Mossgate's scroll")
	check_eq(String(Items.info("scroll_mossgate").get("teaches_recipe", "")), "shield_copper", "the scroll always teaches the Copper Shield")
	var kinds := {}
	for p in plan.props:
		var k := DungeonBuild.thing_kind(p)
		kinds[k] = int(kinds.get(k, 0)) + 1
	check_eq(int(kinds.get("boulder", 0)), 1, "one hidden boulder")
	check_eq(int(kinds.get("floor", 0)), 9, "nine cracked floor tiles over the spike pit")
	check(int(kinds.get("smash", 0)) >= 15, "furniture to smash (%d)" % kinds.get("smash", 0))
	check(int(kinds.get("rubble", 0)) >= 1, "rubble to clear")


## Note 4: falling into the chasm or the spike pit is death; standing on the bridge or by the edge is not.
func test_the_chasm_and_spike_pit_kill() -> void:
	var m := _maker(42)
	if m.dungeons.is_empty():
		return
	var d: Dictionary = m.dungeons[0]
	check_eq(DungeonBuild.deadly_space(d, DungeonMap.to_world(d, Vector3(39, -23.5, 6))), "chasm", "the chasm's bottom kills")
	check_eq(DungeonBuild.deadly_space(d, DungeonMap.to_world(d, Vector3(39, -3.5, 23))), "spike_pit", "the spike pit kills")
	check_eq(DungeonBuild.deadly_space(d, DungeonMap.to_world(d, Vector3(39, 0.3, 6))), "", "the bridge is safe")
	check_eq(DungeonBuild.deadly_space(d, DungeonMap.to_world(d, Vector3(30, 0.3, 6))), "", "the chasm room's floor is safe")
	check_eq(DungeonBuild.deadly_space(d, DungeonMap.to_world(d, Vector3(39, -10.0, 6))), "", "still falling (not yet on the spikes)")


# ---- The owner's second play of the dungeon test (Nov 20) ----

## A small game round the dungeon: the host, one player and the built dungeon (seed 42).
func _rig() -> Dictionary:
	var m := _maker(42)
	if m.dungeons.is_empty():
		return {}
	var root := Node3D.new()
	tree.root.add_child(root)
	var auth := GameAuthority.new()
	root.add_child(auth)
	auth.drops_root = Node3D.new()
	root.add_child(auth.drops_root)
	var player := Node3D.new()
	root.add_child(player)
	var ps := auth.add_player(1, player)
	var db := DungeonBuild.new()
	db.maker = m
	root.add_child(db)
	return {root = root, auth = auth, player = player, ps = ps, db = db, d = m.dungeons[0]}


func _thing(db: DungeonBuild, model: String) -> int:
	for id in db.things:
		if db.things[id].model == model:
			return id
	return -1


## Note 1: stalactites come down in under a second and always hurt 50 (armour or not), anyone within 1.5 m.
func test_stalactites_fall_fast_and_hurt() -> void:
	var r := _rig()
	if r.is_empty():
		return
	var db: DungeonBuild = r.db
	for id in db.things:
		if db.things[id].kind == "drip":
			check(db.drip_time(db.things[id]) < 1.0, "stalactite %d lands in under 1 s (%.2f s)" % [id, db.drip_time(db.things[id])])
	check(DungeonBuild.DRIP_HIT >= 1.4, "it hurts you even a step off its line")
	var ps: GameAuthority.PlayerState = r.ps
	ps.vitals.health = 100.0
	(r.auth as GameAuthority).hurt(1, DungeonBuild.DRIP_DAMAGE, {pierce = true})
	check_near(ps.vitals.health, 50.0, 0.01, "50 damage, armour doesn't cut it")
	r.root.free()


## Note 2: the spike pit is open right up to the floor (no rock skin under the cracked boards), lit at the bottom,
## its boards give way quickly, and they come apart (boards that fall one by one).
func test_the_spike_pit_shows_under_the_breaking_floor() -> void:
	var m := _maker(42)
	if m.dungeons.is_empty():
		return
	var d: Dictionary = m.dungeons[0]
	for y in [-3.0, -1.0, -0.1, 0.1]:
		check(m.sdf_at(DungeonMap.to_world(d, Vector3(39, y, 23))) > 0.3, "the pit is open at y %.1f" % y)
	var plan := DungeonBuild.load_plan("mossgate")
	check(plan.lights.any(func(l): return float(l[1]) < -1.0), "a light down in the pit shows the spikes")
	check_eq(plan.props.filter(func(p): return String(p.model) == "dungeon/trap_spikes.glb" and float(p.pos[1]) == -4.0).size(), 9,
		"nine spike beds on the pit's floor")
	check(DungeonBuild.FLOOR_GIVE <= 0.2, "the cracked floor gives way fast")
	var boards := 0
	var scene := load("res://assets/models/dungeon/trap_floor_break.glb") as PackedScene
	var inst := scene.instantiate()
	boards = inst.find_children("board*", "MeshInstance3D", true, false).size()
	inst.free()
	check(boards >= 6, "the cracked tile has loose boards that fall (%d)" % boards)


## Note 3: the cracked wall in front of the hidden vault (right of the way in) breaks; so does anything with any hit.
func test_the_cracked_wall_breaks() -> void:
	check_eq(DungeonBuild.thing_kind({model = "dungeon/wall_cracked.glb"}), "rubble", "the cracked wall is a breakable thing")
	var r := _rig()
	if r.is_empty():
		return
	var db: DungeonBuild = r.db
	var id := _thing(db, "dungeon/wall_cracked.glb")
	check(id >= 0, "the cracked wall is built as its own body")
	if id >= 0:
		(r.player as Node3D).global_position = (db.things[id].centre as Vector3) - Vector3.UP * 1.1
		for i in DungeonBuild.RUBBLE_HITS:
			db.request_hit(1, id)
		check(db.is_broken(id), "four hits break it (bare hands, tool or weapon: no tool check)")
	r.root.free()


## Note 4: standing by the Rune Shrine's basin heals.
func test_the_shrine_basin_heals() -> void:
	var r := _rig()
	if r.is_empty():
		return
	var db: DungeonBuild = r.db
	check_eq(db.heals.size(), 1, "one healing basin")
	var ps: GameAuthority.PlayerState = r.ps
	ps.vitals.health = 20.0
	db._check_heal(r.auth, 1, db.heals[0] + Vector3(1.2, 0, 0), 1.0)
	check_near(ps.vitals.health, 20.0 + DungeonBuild.HEAL_RATE, 0.01, "next to the basin you heal")
	db._check_heal(r.auth, 1, db.heals[0] + Vector3(6, 0, 0), 1.0)
	check_near(ps.vitals.health, 20.0 + DungeonBuild.HEAL_RATE, 0.01, "away from it you don't")
	r.root.free()


## Note 5: the bridge's hand ropes and the edge railings are solid, and one section has a 1 m hole you jump.
func test_the_bridge_has_ropes_and_a_gap() -> void:
	var plan := DungeonBuild.load_plan("mossgate")
	check(plan.props.any(func(p): return String(p.model) == "dungeon/bridge_plank_gap.glb"), "a bridge section with a gap")
	check(not DungeonBuild.NO_BODY.has("dungeon/railing_broken.glb"), "the edge railings are solid")
	for model in ["dungeon/bridge_plank.glb", "dungeon/bridge_plank_gap.glb"]:
		var ropes := (DungeonBuild.BOXES[model] as Array).filter(func(b): return (b[0] as Vector3).y > 0.4)
		check_eq(ropes.size(), 2, "%s: both hand ropes are solid" % model)
	for b in DungeonBuild.BOXES["dungeon/bridge_plank_gap.glb"]:
		var c: Vector3 = b[0]
		var sz: Vector3 = b[1]
		if c.y < 0.2:
			check(absf(c.z) - sz.z * 0.5 >= 0.49, "the deck leaves a hole in the middle (%s)" % c)


## Note 6: the crushers slam down fast, take turns (one is always up), and kill a dwarf under one.
func test_the_crushers_kill() -> void:
	check(DungeonBuild.CRUSH_SLAM <= 0.2, "they slam down fast")
	check_near(DungeonBuild.crush_down(0.0), 0.0, 0.001, "up at the start")
	check_near(DungeonBuild.crush_down(DungeonBuild.CRUSH_SLAM), 1.0, 0.001, "down after the slam")
	var t := 0.0
	while t < DungeonBuild.CRUSH_CYCLE:
		check(DungeonBuild.crush_down(t) < 0.5 or DungeonBuild.crush_down(t - DungeonBuild.CRUSH_CYCLE * 0.5) < 0.5,
			"never both down at %.1f s" % t)
		t += 0.1
	var r := _rig()
	if r.is_empty():
		return
	var db: DungeonBuild = r.db
	check_eq(db.crushers.size(), 2, "two working crushers")
	var id: int = db.crushers[0]
	var th: Dictionary = db.things[id]
	var ps: GameAuthority.PlayerState = r.ps
	ps.vitals.health = 100.0
	(r.player as Node3D).global_position = (th.xform as Transform3D).origin + Vector3.UP * 0.25
	db._clock = 100.0
	db._move_crusher(id, 1000.0 * DungeonBuild.CRUSH_CYCLE + 0.05, r.auth)  # (0.05 s into its slam)
	check(ps.vitals.health <= 0.0, "a dwarf under it while it slams is dead")
	r.root.free()


## Note 7: the loot door opens when the Pack Hall's pack is dead (a DungeonKeys lock: saved, sent to everyone) and
## shuts when the pack comes back.
func test_the_loot_door_opens_when_the_pack_dies() -> void:
	var r := _rig()
	if r.is_empty():
		return
	var db: DungeonBuild = r.db
	var auth: GameAuthority = r.auth
	var id := _thing(db, "dungeon/door_loot.glb")
	check(id >= 0, "the loot door is built as its own body")
	check(not auth.keys.is_open("mossgate_hold"), "shut at first")
	db._on_dungeon_room("mossgate", "guard_room", true)
	check(not auth.keys.is_open("mossgate_hold"), "another room's creatures don't open it")
	db._on_dungeon_room("mossgate", "pack_hall", true)
	check(auth.keys.is_open("mossgate_hold"), "the pack dead: it opens")
	check(auth.world_state.dungeon_doors.mossgate_hold.has("pack"), "kept in the world state (saved, sent to friends)")
	check(db.things[id].get("open", false), "the door swings open")
	db._on_dungeon_room("mossgate", "pack_hall", false)
	check(not auth.keys.is_open("mossgate_hold"), "the pack back: it shuts")
	check(not db.things[id].get("open", false), "the door is shut again")
	r.root.free()
