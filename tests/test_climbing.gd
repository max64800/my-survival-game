extends TestCase
## Creatures climbing walls and ceilings (owner, Nov 20: F236, F474, F475;
## docs/decisions/2026-11-20-creature-climbing.md). Run: only=climbing


var world: World
var auth: GameAuthority
var player: Node3D


## A stand-in dwarf (like test_monsters' FakeDwarf).
class FakeDwarf extends Node3D:
	var defense := {holding = false, pressed_ago = -1.0, weapon = "sword", shield = false, tier = 0}

	func defense_state() -> Dictionary:
		return defense

	func is_invulnerable() -> bool:
		return false

	func got_parry() -> void:
		pass


func _setup() -> void:
	var root := Node3D.new()
	tree.root.add_child(root)
	world = World.new()
	root.add_child(world)
	world.setup(42)
	var drops := Node3D.new()
	root.add_child(drops)
	var stations := Node3D.new()
	root.add_child(stations)
	auth = GameAuthority.new()
	auth.world = world
	auth.drops_root = drops
	auth.stations_root = stations
	root.add_child(auth)
	player = FakeDwarf.new()
	root.add_child(player)
	player.global_position = world.maker.cavern_spawn
	var viewer := VoxelViewer.new()
	viewer.view_distance = 48
	player.add_child(viewer)
	auth.add_player(1, player)
	for i in 900:
		if world.terrain.is_area_meshed(AABB(player.global_position - Vector3.ONE * 8, Vector3.ONE * 16)):
			break
		await tree.physics_frame
	for i in 30:
		await tree.physics_frame


func _teardown() -> void:
	auth.get_parent().queue_free()


func _ray(from: Vector3, to: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, to, World.TERRAIN_LAYER)
	return world.get_world_3d().direct_space_state.intersect_ray(q)


## A ceiling spot (with the real rock's collision) above the floor near the dwarf: {pos, normal, floor} or {}.
func _ceiling_near() -> Dictionary:
	var base := player.global_position
	for r: float in [0.0, 2.0, 3.0, 4.0, 5.0, 6.0]:
		for a in 8:
			var x := base.x + cos(a * TAU / 8.0) * r
			var z := base.z + sin(a * TAU / 8.0) * r
			var fl := world.maker.find_floor(x, z, base.y + 2.0)
			var hit := _ray(fl + Vector3.UP * 0.5, fl + Vector3.UP * 9.0)
			if not hit.is_empty() and hit.position.y - fl.y > 3.0 and hit.normal.y < Monster.CEILING_DOWN:
				return {pos = hit.position, normal = hit.normal, floor = fl}
	return {}


func _spawn_at(kind: String, pos: Vector3, n := Vector3.ZERO) -> Monster:
	var uid: int = auth.monsters._next_uid
	auth.monsters._ev_spawn(uid, kind, pos, false, 0, "", n)
	return auth.monsters.get_monster(uid)


## Who climbs where (owner): spider and snail walls and ceilings, beetle walls only, the Great Rock Beetle never.
func test_who_climbs_where() -> void:
	var wall := Vector3(1, 0.1, 0).normalized()
	var ceiling := Vector3(0.1, -1, 0).normalized()
	for kind in ["cave_spider", "rock_snail"]:
		var how := String(Monsters.info(kind).get("climbs", ""))
		check(Monster.may_cling(how, wall) and Monster.may_cling(how, ceiling), "%s: walls and ceilings" % kind)
	var beetle := String(Monsters.info("rock_beetle").get("climbs", ""))
	check(Monster.may_cling(beetle, wall), "rock beetle: walls")
	check(not Monster.may_cling(beetle, ceiling), "rock beetle: never ceilings")
	check_eq(String(Monsters.info("great_rock_beetle").get("climbs", "")), "", "the Great Rock Beetle never climbs")
	check(not Monster.may_cling("all", Vector3.UP), "a floor is walked on, not clung to")
	check(Monsters.info("cave_spider").get("ambush", false), "spiders ambush from the ceiling")
	check(Monsters.info("rock_snail").get("falls_dazed", false), "a knocked-down snail lands dazed")
	check_eq(Monster.UP_HIGH, 0.25, "about 1 in 4 start up high")


## The body turns so its feet are on the rock, also straight upside down.
func test_body_turns_onto_the_rock() -> void:
	for n in [Vector3.UP, Vector3.DOWN, Vector3.RIGHT, Vector3(0.3, -0.9, 0.2).normalized(), Vector3(0, 0.2, -1).normalized()]:
		var b := Monster.up_on(n)
		check(b.y.distance_to(n) < 0.01, "up points off the rock (%s)" % str(n))
		check(absf(b.determinant() - 1.0) < 0.01, "a clean turn, no stretching (%s)" % str(n))


## F475: a snail on the ceiling stays there; any hit knocks it down; it lands on its shell, dazed with stars.
func test_snail_on_ceiling_knocked_down_dazed() -> void:
	await _setup()
	var c := _ceiling_near()
	check(not c.is_empty(), "found a ceiling near the start")
	if c.is_empty():
		_teardown()
		return
	var m := _spawn_at("rock_snail", c.pos, c.normal)
	for i in 120:
		await tree.physics_frame
	check(m.clinging(), "it stays on the ceiling")
	check(m.global_position.distance_to(c.pos) < 0.5, "it doesn't fall or wander (%.2f m)" % m.global_position.distance_to(c.pos))
	check(m.global_transform.basis.y.dot(Vector3.DOWN) > 0.7, "upside down, feet on the rock")
	auth.monsters._hurt_monster(m, 1, 1, 0.0)  # (a bolt, a thrown thing or a long reach: any hit)
	check(not m.clinging(), "a hit knocks it off")
	var landed := false
	for i in 240:
		await tree.physics_frame
		if m.is_on_floor():
			landed = true
			break
	check(landed, "it falls to the floor")
	for i in 3:
		await tree.physics_frame
	check(m.stun.is_stunned(), "it lands dazed (stars)")
	check(m._on_back > 0.0, "it lies on its shell")
	check(m.global_position.y < c.floor.y + 1.0, "down on the floor (%.1f m above it)" % (m.global_position.y - c.floor.y))
	_teardown()


## F474: a spider waiting on the ceiling hisses first when you walk under it (time to dodge), then drops on you.
func test_spider_ambush_hisses_then_drops() -> void:
	await _setup()
	var c := _ceiling_near()
	if c.is_empty():
		check(false, "found a ceiling near the start")
		_teardown()
		return
	var m := _spawn_at("cave_spider", c.pos, c.normal)
	player.global_position = c.floor + Vector3(0.5, 0.0, 0.0)
	m.alert(1)
	var hiss_at := -1.0
	var left_at := -1.0
	var t := 0.0
	for i in 600:
		await tree.physics_frame
		t += 1.0 / 60.0
		if hiss_at < 0.0 and m._hiss > 0.0:
			hiss_at = t
		if left_at < 0.0 and not m.clinging():
			left_at = t
		if left_at > 0.0 and m.is_on_floor():
			break
	check(hiss_at >= 0.0, "it hisses before it drops")
	check(left_at - hiss_at >= Monster.HISS_TIME - 0.05, "a %.2f s hiss before it lets go (%.2f)" % [Monster.HISS_TIME, left_at - hiss_at])
	check(left_at > 0.0 and m.global_position.distance_to(c.floor) < 2.5, "it drops down by you")
	await tree.physics_frame
	check(m.state == Monster.State.ATTACK, "landing by you, it bites")
	_teardown()


## F236 (said 3x) / F474: chasing, a spider runs up the wall of a pit to the dwarf above; a beetle and a snail climb out
## too (walls only); the Great Rock Beetle stays down there (owner: the boss never climbs).
func test_climbers_get_out_of_a_pit_the_boss_doesnt() -> void:
	await _setup()
	var base := player.global_position
	var c := world.maker.find_floor(base.x + 4.0, base.z, base.y + 2.0)
	for k in 7:
		world.apply_dig(c + Vector3.DOWN * (0.5 * k), 1.5, 4)
	for i in 90:
		await tree.physics_frame
	var bottom := c + Vector3.DOWN * 2.8
	player.global_position = world.maker.find_floor(base.x + 7.5, base.z, base.y + 2.0)
	for kind in ["cave_spider", "rock_beetle", "great_rock_beetle"]:
		var m := _spawn_at(kind, bottom + Vector3.UP * 0.3)
		for i in 30:
			await tree.physics_frame
		var y0 := m.global_position.y
		m.alert(1)
		var top := y0
		var clung := false
		for i in 600:
			await tree.physics_frame
			if not is_instance_valid(m):
				break
			top = maxf(top, m.global_position.y)
			clung = clung or m.clinging()
		if kind == "great_rock_beetle":
			check(top < c.y - 1.0 and not clung, "the Great Rock Beetle never climbs (top %.1f, edge %.1f)" % [top, c.y])
		else:
			check(clung, "%s takes hold of the wall" % kind)
			check(top > c.y - 1.0, "%s climbed out (from %.1f to %.1f, edge %.1f)" % [kind, y0, top, c.y])
			check(is_instance_valid(m) and not m.clinging(), "%s is back on its feet up there" % kind)
		if is_instance_valid(m):
			auth.monsters._ev_remove(m.uid, -1)
	_teardown()


## Placement rule (CLAUDE.md): creatures up high never sit in or over something built, or over its paths.
func test_up_high_keeps_clear_of_built_things() -> void:
	var was := CaveMaker.layout
	CaveMaker.use_layout(CaveMaker.LAYOUT_LATEST)
	for sd in [42, 7]:
		var maker := CaveMaker.new(sd)
		var rng := RandomNumberGenerator.new()
		rng.seed = sd
		var found := 0
		var ceilings := 0
		var bad := 0
		for room: Dictionary in maker.rooms:
			for k in 6:
				var a := rng.randf() * TAU
				var r := rng.randf_range(2.0, minf(room.radii.x, room.radii.z) * 0.5)
				var spot := maker.find_floor(room.center.x + cos(a) * r, room.center.z + sin(a) * r, room.center.y)
				if maker.sdf_at(spot + Vector3.UP) <= 0.0:
					continue
				var hs := Monster.high_spot(maker, spot, "all", rng)
				if hs.is_empty():
					continue
				found += 1
				if (hs.normal as Vector3).y < Monster.CEILING_DOWN:
					ceilings += 1
				var p: Vector3 = hs.pos
				if maker.is_reserved(p, 1.0) or maker.in_dungeon_stone(p) or not maker._far_from_pois(p, 6.0):
					bad += 1
				if maker.is_reserved(spot, 1.0) and spot.distance_to(p) < 4.0:
					bad += 1
		check(found > 20, "seed %d: plenty of spots up high (%d)" % [sd, found])
		check(ceilings > 5, "seed %d: some of them on ceilings (%d)" % [sd, ceilings])
		check_eq(bad, 0, "seed %d: none in or over built ground, places or their paths" % sd)
		# And the check itself says no right on top of a place.
		if not maker.pois.is_empty():
			var poi: Vector3 = maker.pois[0].pos
			check(not Monster.high_spot_clear(maker, poi + Vector3.UP * 3.0, poi), "seed %d: never over a place" % sd)
	CaveMaker.use_layout(was)


## Co-op: everyone sees which surface it is on, also a player who joins later.
func test_everyone_sees_the_surface() -> void:
	await _setup()
	var c := _ceiling_near()
	var n: Vector3 = c.normal if not c.is_empty() else Vector3.DOWN
	var m := _spawn_at("cave_spider", c.get("pos", player.global_position + Vector3.UP * 3.0), n)
	check(m.clinging() and m.surface.distance_to(n) < 0.01, "spawned on the ceiling for everyone")
	var snap: Array = auth.monsters.snapshot()
	var mine: Array = snap.filter(func(e: Array) -> bool: return e[0] == m.uid)
	check(not mine.is_empty() and (mine[0][7] as Vector3).distance_to(n) < 0.01, "a late joiner gets the surface too")
	m.show_cling(m.global_position, Vector3.ZERO, "")
	check(not m.clinging() and m.global_transform.basis.y.distance_to(Vector3.UP) < 0.01, "back on the floor: upright")
	_teardown()
