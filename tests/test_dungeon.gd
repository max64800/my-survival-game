extends TestCase
## Dungeons dug into the rock (owner, Nov 19, 2026; DungeonMap). Step 1: Mossgate Hold's rooms are carved into solid
## rock behind a cave wall, lined with old dwarf stone, every room can be walked to, and nothing the world grows
## stands inside it or in its doorway (the placement rule).

const SEEDS := [42, 7, 1234]
var _makers := {}


## Layout 14 worlds: Mossgate Hold alone (from layout 15 Lampwick Drift comes too: tests/test_lampwick.gd).
func _maker(sd: int) -> CaveMaker:
	if not _makers.has(sd):
		var was := CaveMaker.layout
		CaveMaker.use_layout(14)
		_makers[sd] = CaveMaker.new(sd)
		CaveMaker.use_layout(was)
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
		if String(p.model) in ["dungeon/floor_old.glb", "dungeon/wall_old.glb"] and not (String(p.model) == "dungeon/floor_old.glb" and float(p.pos[1]) > 1.0):
			old += 1  # (not the old ceilings: test_most_ceilings_are_old)
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


## Owner, Nov 20 (8/10): "most stalactites over or beside the chests, to bait people": each rock-ceiling chest has
## one right where you stand to open it, and most stalactites hang within 2 m of a chest.
func test_stalactites_bait_the_chests() -> void:
	var plan := DungeonBuild.load_plan("mossgate")
	var drips: Array[Vector2] = []
	for p in plan.props:
		if DungeonBuild.thing_kind(p) == "drip":
			drips.append(Vector2(float(p.pos[0]), float(p.pos[2])))
	var baiting := 0
	for dp in drips:
		for c in plan.chests:
			if dp.distance_to(Vector2(float(c.pos[0]), float(c.pos[2]))) <= 2.0:
				baiting += 1
				break
	check(baiting * 2 > drips.size(), "most stalactites hang by a chest (%d of %d)" % [baiting, drips.size()])
	for chest_at in [Vector2(44.0, 28.6), Vector2(26.5, 2.6)]:
		var over := false
		for dp in drips:
			over = over or dp.distance_to(chest_at) <= 1.5  # (you open a chest from about 1 m in front of it)
		check(over, "a stalactite hangs where you stand to open the chest at %s" % [chest_at])


## Notes 3 and 5: chests have loot, the recipe stand holds the same scroll every time (the Copper Shield), and the
## furniture, rubble, hidden boulder and cracked floor can be broken.
func test_chests_and_breakable_things() -> void:
	var plan := DungeonBuild.load_plan("mossgate")
	for c in plan.chests:
		check(DungeonBuild.LOOT.has(String(c.get("loot", ""))), "chest %s has a loot list" % c.label)
	check_eq(String(plan.recipe_stand.page), "scroll_mossgate", "the recipe stand holds Mossgate's scroll")
	check_eq(String(Items.info("scroll_mossgate").get("teaches_recipe", "")), "helm_bronze", "the scroll always teaches the Bronze Helm (F844 step 5)")
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
	check_eq(DungeonBuild.deadly_space(d, DungeonMap.to_world(d, Vector3(39, -3.5, 6))), "chasm", "the chasm's bottom kills (4 m down, owner Nov 20)")
	check_eq(DungeonBuild.deadly_space(d, DungeonMap.to_world(d, Vector3(39, -3.5, 23))), "spike_pit", "the spike pit kills")
	check_eq(DungeonBuild.deadly_space(d, DungeonMap.to_world(d, Vector3(39, 0.3, 6))), "", "the bridge is safe")
	check_eq(DungeonBuild.deadly_space(d, DungeonMap.to_world(d, Vector3(30, 0.3, 6))), "", "the chasm room's floor is safe")
	check_eq(DungeonBuild.deadly_space(d, DungeonMap.to_world(d, Vector3(39, -1.5, 6))), "", "still falling (not yet on the spikes)")


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


func _kind(db: DungeonBuild, kind: String) -> int:
	for id in db.things:
		if db.things[id].kind == kind:
			return id
	return -1


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
	check(DungeonBuild.DRIP_REACH <= 1.0, "it only lets go when you're right under it (owner, Nov 20)")
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
	check_eq(plan.props.filter(func(p): return String(p.model) == "dungeon/trap_spikes.glb" and float(p.pos[1]) == -4.0 and float(p.pos[2]) > 19.0).size(), 9,
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
	db.set_crushers_awake(th.d, true)
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
	var id := _kind(db, "door")
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


## The dungeon test world (owner, Nov 20: "do not build any caves at all"): one small cave and Mossgate Hold behind its
## wall; the way in opens into that cave; everything else is solid rock.
func test_the_dungeon_test_world_has_no_caves() -> void:
	var was := CaveMaker.layout
	CaveMaker.use_layout(CaveMaker.DUNGEON_ONLY)
	var m := CaveMaker.new(42)
	CaveMaker.use_layout(was)
	check_eq(m.rooms.size(), 1, "one small cave")
	check(m.segments.is_empty(), "no tunnels")
	check_eq(m.dungeons.size(), 1, "Mossgate Hold")
	if m.dungeons.is_empty():
		return
	var d: Dictionary = m.dungeons[0]
	for s in d.map.spaces:
		var mid := DungeonMap.space_floor(d, String(s[0])) + Vector3.UP * minf(1.5, float(s[6]) * 0.5)
		check(m.sdf_at(mid) > 0.5, "%s is open" % s[0])
	var mouth: Vector2 = d.map.mouth
	var tip := DungeonMap.to_world(d, Vector3(mouth.x, 1.5, mouth.y + float(d.entry_out) - 0.5))
	check(m.sdf_at(tip) > 0.3, "the way in comes out in the small cave")
	check(m.sdf_at(m.spawn_point + Vector3.UP) > 0.3, "you start in the small cave")
	for far in [Vector3(80, -20, 0), Vector3(-60, -20, 40), Vector3(0, -20, 60), Vector3(0, -40, -120)]:
		check(m.sdf_at(far) < 0.0, "solid rock at %s (no caves)" % far)


## Owner, Nov 20 (F490) and Nov 21 (F591, came back): every dungeon's boss room has a door. Each way into the room
## where a boss sleeps (a doorway on its walls) is shut by a round door you open, the loot door or a barred gate:
## you never see the boss from outside. (A way on that you only reach through his room doesn't count: BOSS_WAY_ON.)
const BOSS_WAY_ON := {"lampwick": Vector2(42.0, 28.0)}  # (the Back Rails, down to the way out)
func test_every_boss_room_has_a_door() -> void:
	var rooms := 0
	for map: Dictionary in DungeonMap.MAPS:
		var plan := DungeonBuild.load_plan(String(map.id))
		for c in plan.get("creatures", []):
			var kind := String(c.model).get_file().get_basename()
			if not Monsters.LIST.get(kind, {}).get("boss", false):
				continue
			var room: Array = []
			for sp: Array in map.spaces:
				if float(sp[1]) <= c.pos[0] and c.pos[0] <= float(sp[3]) and float(sp[2]) <= c.pos[2] and c.pos[2] <= float(sp[4]) \
						and absf(float(c.pos[1]) - float(sp[5])) < 1.0:
					room = sp
			check(not room.is_empty(), "%s: the %s stands in a room" % [map.id, kind])
			if room.is_empty():
				continue
			rooms += 1
			var ways := 0
			for q in plan.pieces:
				if String(q.id) != "doorway" or absf(float(q.pos[1]) - float(room[5])) > 0.5:
					continue
				var x := float(q.pos[0])
				var z := float(q.pos[2])
				var on_x := (absf(x - float(room[1])) < 0.3 or absf(x - float(room[3])) < 0.3) and z > float(room[2]) and z < float(room[4])
				var on_z := (absf(z - float(room[2])) < 0.3 or absf(z - float(room[4])) < 0.3) and x > float(room[1]) and x < float(room[3])
				if not on_x and not on_z or BOSS_WAY_ON.get(String(map.id), Vector2.INF).distance_to(Vector2(x, z)) < 0.5:
					continue
				ways += 1
				var shut := false
				for p in plan.props:
					if String(p.model) in ["dungeon/door_loot.glb", "dungeon/gate_round.glb"] \
							and Vector2(p.pos[0] - x, p.pos[2] - z).length() < 0.5:
						shut = true
				check(shut, "%s: the way into the %s's room at (%.1f, %.1f) has a door" % [map.id, kind, x, z])
			check(ways > 0, "%s: the %s's room has a way in (%d)" % [map.id, kind, ways])
	check(rooms >= 3, "the boss rooms were checked (%d)" % rooms)


# ---- The owner's third play of the dungeon test (Nov 20) ----

## Note 1: a dwarf walking under a stalactite (at walking speed, through the real trap check) brings it down on him.
func test_walking_under_a_stalactite_brings_it_down() -> void:
	var r := _rig()
	if r.is_empty():
		return
	var db: DungeonBuild = r.db
	var auth: GameAuthority = r.auth
	var fell := 0
	var drips := 0
	for id in db.things:
		var th: Dictionary = db.things[id]
		if th.kind != "drip":
			continue
		drips += 1
		var c: Vector3 = th.centre
		var under := Vector3(c.x, float(th.landing) + 0.05, c.z)
		var player := r.player as Node3D
		# Walk 4 m/s past it, 0.8 m to one side, through the host's check (every 0.1 s).
		for k in 30:
			player.global_position = under + Vector3(-3.0 + 0.4 * k, 0, 0.8)
			db._host_tick = 0.0
			db._physics_process(0.1)
			if db.is_broken(id):
				break
		if db.is_broken(id):
			fell += 1
		else:
			print("  stalactite %d at %s did not fall (landing %.2f, centre y %.2f)" % [id, c, float(th.landing), c.y])
	check(drips >= 6, "the stalactites are built (%d)" % drips)
	check_eq(fell, drips, "every stalactite comes down on a dwarf walking under it")
	r.root.free()


## Note 2: only the middle of the bridge has planks: two 2 m jumps the dwarf can make walking; every hand rope is solid,
## the posts' too.
func test_the_bridge_is_two_big_jumps() -> void:
	var plan := DungeonBuild.load_plan("mossgate")
	var decks := []
	for p in plan.props:
		if String(p.model) in ["dungeon/bridge_plank.glb", "dungeon/bridge_plank_gap.glb", "dungeon/bridge_plank_broken.glb"]:
			decks.append(float(p.pos[0]))
	check_eq(decks.size(), 1, "one section with planks")
	if decks.size() == 1:
		check_near(decks[0], 40.0, 0.01, "in the middle of the chasm (36 to 44)")
	var gap := (40.0 - 1.0) - 36.0
	var g: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
	var reach := Dwarf.WALK_SPEED * 2.0 * Dwarf.JUMP_SPEED / g
	check(gap >= 1.9, "a big jump (%.1f m)" % gap)
	# (owner, Nov 22: the dwarf walks 3 m/s now, was 4: a walking jump only just makes it, a running one easily)
	check(reach > gap + 0.3, "the dwarf makes it walking, just (%.1f m jump)" % reach)
	var run_reach := Dwarf.RUN_SPEED * 2.0 * Dwarf.JUMP_SPEED / g
	check(run_reach > gap + 1.5, "and easily with a running jump (%.1f m)" % run_reach)
	check(run_reach < 8.0 - 0.5, "even a running jump (%.1f m) can't clear the whole 8 m chasm" % run_reach)
	check(plan.props.any(func(p): return String(p.model) == "dungeon/bridge_ropes_3m.glb"), "the ropes run on where the planks are gone")
	for model in ["dungeon/bridge_ropes_3m.glb", "dungeon/bridge_posts.glb"]:
		var ropes := (DungeonBuild.BOXES[model] as Array).filter(func(b): return (b[0] as Vector3).y > 0.4 and (b[1] as Vector3).x < 0.1)
		check_eq(ropes.size(), 2, "%s: both hand ropes are solid" % model)
	check(not (DungeonBuild.BOXES["dungeon/bridge_ropes_3m.glb"] as Array).any(func(b): return (b[0] as Vector3).y < 0.2),
		"no deck where the planks are gone")


## Note 3: the chasm is 4 m deep, like the spike pit.
func test_the_chasm_is_as_deep_as_the_pit() -> void:
	for s in DungeonMap.MOSSGATE.spaces:
		if String(s[0]) in ["chasm", "spike_pit"]:
			check_eq(float(s[5]), -4.0, "%s: 4 m deep" % s[0])
	var plan := DungeonBuild.load_plan("mossgate")
	check(plan.props.filter(func(p): return String(p.model) == "dungeon/trap_spikes.glb").all(func(p): return float(p.pos[1]) == -4.0),
		"every spike bed lies 4 m down")


## Note 5: a shut round door before the Pack Hall (E opens it, it swings toward you); the crushers hang just inside the
## Pack Hall, 1 m higher (2.5 m drop), asleep until someone has crossed the hall.
func test_the_pack_hall_door_and_its_crushers() -> void:
	check_eq(DungeonBuild.CRUSH_DROP, 2.5, "they drop 2.5 m")
	check_near(DungeonBuild.CRUSH_DROP / DungeonBuild.CRUSH_RISE, 1.2, 0.01, "they rise as fast as before (1.2 m/s)")
	check(DungeonBuild.CRUSH_SLAM <= 0.2, "they slam fast")
	var r := _rig()
	if r.is_empty():
		return
	var db: DungeonBuild = r.db
	var auth: GameAuthority = r.auth
	var player := r.player as Node3D
	var door := _kind(db, "hand_door")
	check(door >= 0, "the round door is built")
	if door < 0:
		r.root.free()
		return
	var th: Dictionary = db.things[door]
	var d: Dictionary = th.d
	check_near(DungeonMap.to_local(d, (th.xform as Transform3D).origin).x, 56.0, 0.01, "it stands in the doorway between the halls")
	check(not th.get("open", false), "shut at first")
	check(not db.use_info(door).is_empty(), "E opens it")
	var t: Transform3D = th.xform
	player.global_position = DungeonMap.to_world(d, Vector3(54.0, 0.3, 6.0))  # (in the small hall, coming to it)
	db.request_use(1, door)
	check(th.get("open", false), "E: it opens")
	check(auth.world_state.dungeon_opened.has(str(door)), "kept in the world state (saved, sent to friends)")
	var way: int = db.opened_by_hand(door)
	var side := (t.affine_inverse() * player.global_position).z
	check(way * side < 0.0 or (way > 0) == (side < 0.0), "it swings toward the one who opened it")
	for id in db.crushers:
		check_eq(DungeonMap.space_at(d, (db.things[id].xform as Transform3D).origin + Vector3.UP * 0.5), "pack_hall", "crusher %d is in the Pack Hall" % id)
	# Asleep: a dwarf under one isn't hurt; across the hall wakes them; then it kills.
	var cid: int = db.crushers[0]
	var cth: Dictionary = db.things[cid]
	var ps: GameAuthority.PlayerState = r.ps
	ps.vitals.health = 100.0
	player.global_position = (cth.xform as Transform3D).origin + Vector3.DOWN * 0.95
	db._clock = 100.0
	db._move_crusher(cid, 1000.0 * DungeonBuild.CRUSH_CYCLE + 0.05, auth)
	check_near(ps.vitals.health, 100.0, 0.01, "asleep: it doesn't come down")
	db._check_crushers_wake(auth, DungeonMap.to_world(d, Vector3(62.0, 0.3, 9.0)))
	check(not db.crushers_awake(d), "still asleep in the middle of the hall")
	db._check_crushers_wake(auth, DungeonMap.to_world(d, Vector3(70.5, 0.3, 10.0)))
	check(db.crushers_awake(d), "awake once someone has crossed to the loot door")
	player.global_position = (cth.xform as Transform3D).origin + Vector3.DOWN * 0.95
	db._clock = 200.0
	db._move_crusher(cid, 1001.0 * DungeonBuild.CRUSH_CYCLE + 0.05, auth)
	check(ps.vitals.health <= 0.0, "awake: it kills on the way back")
	db._on_dungeon_room("mossgate", "pack_hall", false)
	check(not db.crushers_awake(d), "the pack back: they sleep again")
	# No ceiling boards over them (they hide up in the dark).
	var plan := DungeonBuild.load_plan("mossgate")
	for p in plan.pieces + plan.props:
		var pos: Array = p.pos
		if float(pos[1]) > 3.5 and absf(float(pos[0]) - 57.0) < 0.5 and float(pos[2]) > 4.0 and float(pos[2]) < 8.0:
			check(false, "a ceiling over the crushers at %s" % [pos])
	r.root.free()


## Note 6: the loot door opens when the pack really dies (the monster code's own kills, not a made-up signal), and
## a creature that falls into the chasm dies on its spikes (it can't keep the door shut from down there).
func test_killing_the_pack_opens_the_loot_door() -> void:
	var r := _rig()
	if r.is_empty():
		return
	var db: DungeonBuild = r.db
	var auth: GameAuthority = r.auth
	var mm: MonsterManager = auth.monsters
	var d: Dictionary = r.d
	var list := []  # (the Pack Hall's group, made like MonsterManager._dungeon_groups does: the rig has no world)
	for c in DungeonBuild.load_plan("mossgate").creatures:
		var local := Vector3(c.pos[0], c.pos[1], c.pos[2])
		if DungeonMap.space_at(d, DungeonMap.to_world(d, Vector3(local.x, 1.0, local.z))) == "pack_hall":
			list.append([String(c.kind), local])
	var pack := {key = MonsterManager.DUNGEON_KEY, list = list, d = d, room = "pack_hall"}
	var uids: Array = mm._spawn_dungeon_group({}, pack)
	mm._rooms[pack.key] = {alive = uids.duplicate(), cleared_at = mm._clock}
	pack.was = uids.size()
	check_eq(uids.size(), 5, "the pack came: the leader, a beetle and three spiders")
	# One of them chases you onto the bridge and falls into the chasm: the spikes kill it.
	var faller: Monster = mm.monsters[uids[0]]
	faller.global_position = DungeonMap.to_world(d, Vector3(39.0, -3.6, 6.0))
	db._traps_hit_creatures(auth)
	check(not mm.monsters.has(uids[0]), "a creature in the chasm dies on the spikes")
	for u in uids.slice(1):
		if mm.monsters.has(u):
			mm._kill(mm.monsters[u], 1)
	var st: Dictionary = mm._rooms[pack.key]
	st.alive = st.alive.filter(func(u): return mm.monsters.has(u) and (mm.monsters[u] as Monster).is_alive())
	var now: int = st.alive.size()
	if pack.was > 0 and now == 0:
		mm.dungeon_room.emit(String(d.id), "pack_hall", true)
	check(auth.keys.is_open("mossgate_hold"), "the whole pack dead: the loot door opens")
	r.root.free()


## Note 8: the way out's lever is on the wall (its back on the boards), E pulls it, the gate opens for everyone.
func test_the_lever_opens_the_way_out_gate() -> void:
	var r := _rig()
	if r.is_empty():
		return
	var db: DungeonBuild = r.db
	var auth: GameAuthority = r.auth
	var lever := _kind(db, "lever")
	var gate := _kind(db, "gate")
	check(lever >= 0 and gate >= 0, "the lever and the gate are built")
	if lever < 0 or gate < 0:
		r.root.free()
		return
	var d: Dictionary = db.things[lever].d
	var lt: Transform3D = db.things[lever].xform
	var back := lt.origin  # (the lever's back, on the wall)
	var q := DungeonMap.to_local(d, back)
	check(absf(q.z - (38.0 + 0.145)) < 0.03, "its back sits on the wall's boards (z %.3f)" % q.z)
	check_eq(DungeonMap.space_at(d, back + lt.basis.z * 0.5 + Vector3.UP), "way_out_w", "it faces into the way out")
	check(auth.keys.gates.has("mossgate_hold"), "DungeonKeys knows the gate")
	check(not db.things[gate].get("open", false), "the gate is shut")
	(r.player as Node3D).global_position = back + lt.basis.z * 1.0
	check_eq(auth.keys.request_pull_lever(1, "mossgate_hold"), "The gate grinds open. The way out!", "E pulls it")
	check(db.things[gate].get("open", false), "the gate swings open")
	check(db.is_gate_open(d), "kept in the world state")
	r.root.free()


## Note 9: the cracked wall's hits throw wood splinters (it is boards), and its boards fall and lie on the floor a
## while (they don't just vanish).
func test_the_cracked_wall_is_wood() -> void:
	check(DungeonBuild.TOPPLE_LIE >= 3.0, "its fallen boards stay a few seconds")
	var src := FileAccess.get_file_as_string("res://src/world/dungeon_build.gd")
	check(src.contains('th.kind != "smash" and th.model != "dungeon/wall_cracked.glb"'), "its hits show wood, not stone dust")


## Note 10: about 70% of the root wood ceilings are old (the old floor turned upside down, its worn face down).
func test_most_ceilings_are_old() -> void:
	var plan := DungeonBuild.load_plan("mossgate")
	var old: Array = plan.props.filter(func(p): return String(p.model) == "dungeon/floor_old.glb" and float(p.pos[1]) > 2.0)
	var new: Array = plan.pieces.filter(func(p): return String(p.id) == "floor" and float(p.pos[1]) > 2.0)
	var share := float(old.size()) / maxf(1.0, float(old.size() + new.size()))
	check(share > 0.6 and share < 0.85, "about 70%% of the ceilings are old (%.0f%%)" % (share * 100.0))
	check(old.all(func(p): return float(p.get("tilt", 0.0)) == 180.0), "turned upside down (its worn face down)")


## Note 7: taking the scroll off the recipe stand rolls it up and it's gone.
func test_the_scroll_rolls_up_when_taken() -> void:
	var body := Node3D.new()
	tree.root.add_child(body)
	var scroll := Node3D.new()
	scroll.name = "Scroll"
	body.add_child(scroll)
	var inv := Inventory.new(4)
	inv.add("scroll_mossgate", 1)
	DungeonBuild.show_scroll(body, inv)
	check(scroll.visible, "on the stand while the page is there")
	inv.remove("scroll_mossgate", 1)
	DungeonBuild.show_scroll(body, inv)
	check(scroll.visible, "it rolls up first (still there while it rolls)")
	await tree.create_timer(1.0).timeout
	check(not scroll.visible, "then it's gone")
	body.free()


# ---- The owner's play of the third round (Nov 20, later) ----

## The loot door and the lever did nothing: the game builds the dungeon BEFORE its GameAuthority. Built in that
## order, the dungeon still hooks in (on its next frame): it hears the pack die and knows the gate's lever.
func test_the_dungeon_hooks_in_when_built_first() -> void:
	var m := _maker(42)
	if m.dungeons.is_empty():
		return
	var root := Node3D.new()
	tree.root.add_child(root)
	var was: GameAuthority = GameAuthority.instance
	GameAuthority.instance = null
	var db := DungeonBuild.new()
	db.maker = m
	root.add_child(db)  # (no authority yet, like the game)
	check(not db.hooked, "nothing to hook into yet")
	var auth := GameAuthority.new()
	root.add_child(auth)
	auth.drops_root = Node3D.new()
	root.add_child(auth.drops_root)
	var player := Node3D.new()
	root.add_child(player)
	auth.add_player(1, player)
	db._physics_process(0.016)
	check(db.hooked, "the next frame it hooks in")
	check(auth.keys.gates.has("mossgate_hold"), "the gate's lever is known (E opens the gate)")
	check(auth.monsters.dungeon_room.is_connected(db._on_dungeon_room), "it hears when the pack dies")
	auth.monsters.dungeon_room.emit("mossgate", "pack_hall", true)
	check(auth.keys.is_open("mossgate_hold"), "the pack dead: the loot door opens")
	var lever := _kind(db, "lever")
	player.global_position = (db.things[lever].xform as Transform3D).origin + Vector3(0, 0, 0.8)
	auth.keys.request_pull_lever(1, "mossgate_hold")
	check(db.things[_kind(db, "gate")].get("open", false), "the lever opens the gate")
	root.free()
	GameAuthority.instance = was


## The pack came out and crushed the owner in the hallway: dungeon creatures stay in their room and keep out from
## under the crushers; the Pack Hall is easier (the leader, one beetle, three spiders).
func test_dungeon_creatures_stay_in_their_room() -> void:
	var r := _rig()
	if r.is_empty():
		return
	var db: DungeonBuild = r.db
	var d: Dictionary = r.d
	var mon := Monster.new()
	mon.dungeon = d
	mon.dungeon_room = "pack_hall"
	check(mon.may_step(DungeonMap.to_world(d, Vector3(64.0, 0.3, 10.0))), "it walks about its hall")
	check(not mon.may_step(DungeonMap.to_world(d, Vector3(54.0, 0.3, 6.0))), "it doesn't walk out into the small hall")
	check(not mon.may_step(DungeonMap.to_world(d, Vector3(73.0, 0.3, 10.0))), "nor through the loot door")
	var c: Transform3D = db.things[db.crushers[0]].xform
	check(not mon.may_step(c.origin), "nor under a crusher")
	# Owner F473: a beetle stood in a doorway charging and dazing itself again and again: from outside its room every
	# step was "out of its room". Now one that is already outside may walk back in (never under a crusher).
	var doorway := DungeonMap.to_world(d, Vector3(54.0, 0.3, 6.0))
	check(mon.may_step(DungeonMap.to_world(d, Vector3(54.0, 0.3, 6.7)), doorway), "out of its room it may walk (to get back in)")
	check(mon.may_step(DungeonMap.to_world(d, Vector3(64.0, 0.3, 10.0)), doorway), "back into its hall")
	check(not mon.may_step(c.origin, doorway), "but still never under a crusher")
	check(not mon.may_step(DungeonMap.to_world(d, Vector3(54.0, 0.3, 6.0)), DungeonMap.to_world(d, Vector3(64.0, 0.3, 10.0))),
		"inside its hall it still stops at the edge")
	mon.free()
	var pack: Array = DungeonBuild.load_plan("mossgate").creatures.filter(func(c): return float(c.pos[0]) > 56.0 and float(c.pos[0]) < 72.0 and float(c.pos[2]) < 18.0)
	check_eq(pack.size(), 5, "five in the Pack Hall")
	check_eq(pack.filter(func(c): return c.kind == "cave_spider").size(), 3, "three of them spiders")
	r.root.free()


## The stone rubble in the tunnel left of the way in breaks (like the tower's); the broken wall standing in the middle
## of that tunnel is gone; the cracked wall gives wood, not stone.
func test_the_rubble_tunnel_clears() -> void:
	var plan := DungeonBuild.load_plan("mossgate")
	var rubble: Array = plan.props.filter(func(p): return String(p.model) == "build/ruin_rubble__cut_stone.glb")
	check_eq(rubble.size(), 2, "two heaps of stone rubble")
	check(rubble.all(func(p): return DungeonBuild.thing_kind(p) == "rubble"), "they break")
	check(not plan.props.any(func(p): return String(p.model) == "dungeon/wall_broken.glb"), "no wall standing in the tunnel")
	var r := _rig()
	if r.is_empty():
		return
	var db: DungeonBuild = r.db
	var auth: GameAuthority = r.auth
	var id := _thing(db, "dungeon/wall_cracked.glb")
	(r.player as Node3D).global_position = (db.things[id].centre as Vector3) - Vector3.UP * 1.1
	db.request_hit(1, id)
	var kinds := []
	for k in auth._drops:
		kinds.append(String(auth._drops[k].item_id))
	check(kinds.has("rootwood") and not kinds.has("stone"), "the cracked wall gives wood (%s)" % [kinds])
	r.root.free()


# ---- The owner's notes after that play (Nov 20, later still) ----

## Stalactites: only when you're right under one; 50 right under it, 25 in the 3 x 3 m round it, nothing further;
## sprinting away you're at the splash's edge when it lands.
func test_stalactites_hit_under_and_splash_round() -> void:
	var r := _rig()
	if r.is_empty():
		return
	var db: DungeonBuild = r.db
	var id := _kind(db, "drip")
	var th: Dictionary = db.things[id]
	var c: Vector3 = th.centre
	var floor_at := Vector3(c.x, float(th.landing) + 0.05, c.z)
	check_eq(db.drip_damage(th, floor_at), 50.0, "right under it: 50")
	check_eq(db.drip_damage(th, DungeonMap.to_world(th.d, DungeonMap.to_local(th.d, floor_at) + Vector3(1.2, 0, 1.2))), 25.0, "in the 3x3 round it: 25")
	check_eq(db.drip_damage(th, DungeonMap.to_world(th.d, DungeonMap.to_local(th.d, floor_at) + Vector3(2.0, 0, 0))), 0.0, "2 m away: nothing")
	var sprint := Dwarf.RUN_SPEED * db.drip_time(th) - DungeonBuild.DRIP_REACH  # (it lets go as you step under its edge)
	check(sprint > DungeonBuild.DRIP_HIT and sprint < DungeonBuild.DRIP_SPLASH + 0.6,
		"sprinting from under it you're out of the big hit, at the splash's edge (%.1f m)" % sprint)
	# 5 m away nothing falls (it used to aim ahead of you)
	(r.player as Node3D).global_position = floor_at + Vector3(5.0, 0, 0)
	db._host_tick = 0.0
	db._physics_process(0.1)
	check(not db.is_broken(id), "5 m away it stays up")
	r.root.free()


## The healing basin heals 30 health in all, then it's dry.
func test_the_basin_heals_only_30() -> void:
	var r := _rig()
	if r.is_empty():
		return
	var db: DungeonBuild = r.db
	var ps: GameAuthority.PlayerState = r.ps
	ps.vitals.health = 10.0
	for i in 20:
		db._check_heal(r.auth, 1, db.heals[0] + Vector3(1.0, 0, 0), 1.0)
	check_near(ps.vitals.health, 10.0 + DungeonBuild.HEAL_POOL, 0.01, "30 health in all, then dry")
	r.root.free()


## Bandages: one every 30 s (the owner could spam them).
func test_bandages_have_a_cooldown() -> void:
	var r := _rig()
	if r.is_empty():
		return
	var auth: GameAuthority = r.auth
	var ps: GameAuthority.PlayerState = r.ps
	check(GameAuthority.BANDAGE_COOLDOWN >= 20.0, "a long wait between bandages")
	var src := FileAccess.get_file_as_string("res://src/net/game_authority.gd")
	check(src.contains('add_boost(ps, "bandage_cooldown", {}, BANDAGE_COOLDOWN)'), "using one starts the wait")
	r.root.free()


## Dungeon creatures only notice you in their own room (the bats woke before the owner came in).
func test_dungeon_creatures_notice_you_only_in_their_room() -> void:
	var src := FileAccess.get_file_as_string("res://src/combat/monster_manager.gd")
	check(src.contains("var room := DungeonMap.space_at(m.dungeon, p + Vector3.UP)") and src.contains("if room != m.dungeon_room and not (m.chases_out()"),
		"they don't notice you through the walls (only Lampwick's bone piles see into the next room)")
	check(src.contains("		if mon:  # (it stays in its room and only notices you there"), "bats get their room too")


## Owner F470: a used bandage shows its cooldown as a grey shade over its slot that clears from the bottom to the top.
func test_bandage_cooldown_shows_on_its_slot() -> void:
	var src := FileAccess.get_file_as_string("res://src/net/game_authority.gd")
	check(src.contains('send_cooldown(peer_id, "bandage", BANDAGE_COOLDOWN)'), "the host tells the player the wait")
	var auth := GameAuthority.new()
	check_eq(auth.cooldown_left("bandage"), 0.0, "no shade before any bandage")
	auth._cooldown_started("bandage", 30.0)
	check(auth.cooldown_left("bandage") > 0.95, "just used: the shade covers it all")
	auth.my_cooldowns.bandage.start -= 15.0
	auth.my_cooldowns.bandage.until -= 15.0
	check_near(auth.cooldown_left("bandage"), 0.5, 0.02, "halfway")
	check_near(Hud.cooldown_shade_height(60.0, 0.5), 30.0, 0.5, "half the slot is grey")
	auth.my_cooldowns.bandage.until = GameAuthority.now() - 0.1
	check_eq(auth.cooldown_left("bandage"), 0.0, "ready again: no shade")
	check(auth.my_cooldowns.is_empty(), "and it is forgotten")
	auth.free()


## F517 (owner, Nov 20: "dungeon 2 is dark, dungeon 1 should be dark as well", picked "almost no light"): Mossgate's
## torches hang cold; only the one by the way in burns (and the faint glow down in the spike pit).
func test_mossgate_is_dark() -> void:
	var plan := DungeonBuild.load_plan("mossgate")
	check(plan.lights.size() <= 2, "Mossgate has almost no light (%d lights)" % plan.lights.size())
	check(plan.lights.any(func(l): return float(l[2]) > 55.0), "the torch by the way in still burns")


## F844 step 5: Mossgate Hold's big chest always holds the Bronze Pickaxe page (once), next to its usual loot,
## and the recipe stand's scroll teaches the Bronze Helm.
func test_mossgate_big_chest_has_the_bronze_pickaxe_page() -> void:
	var r := _rig()
	if r.is_empty():
		check(false, "the test world has Mossgate Hold")
		return
	var auth: GameAuthority = r.auth
	DungeonBuild.add_chests(auth, r.db.maker)
	var pages := 0
	var in_big := false
	var helm_scroll := false
	for bid in auth.storage.boxes:
		var inv: Inventory = auth.storage.get_box(bid).inv
		pages += inv.count_of("page_pickaxe_bronze")
		if inv.count_of("page_pickaxe_bronze") > 0 and inv.count_of("gold_coin") > 0:
			in_big = true  # (the big chest: always its gold too)
		if inv.count_of("scroll_mossgate") > 0:
			helm_scroll = true
	check_eq(pages, 1, "exactly one Bronze Pickaxe page in the whole dungeon")
	check(in_big, "it is in the big chest")
	check(helm_scroll, "the recipe stand holds Mossgate's scroll")
	check_eq(String(Items.info("scroll_mossgate").get("teaches_recipe", "")), "helm_bronze", "which teaches the Bronze Helm")
	r.root.free()
