extends TestCase
## The dungeon ghosts (Claude, Nov 22, 2026): the dwarf's skeleton and mace moves under a ghost body (Ghost, GhostRig).

var world: World
var auth: GameAuthority
var player: Node3D
var ps: GameAuthority.PlayerState

const KINDS := ["ghost_a", "ghost_b", "ghost_c", "ghost_lord"]


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
	player = Node3D.new()
	root.add_child(player)
	player.global_position = world.maker.cavern_spawn
	var viewer := VoxelViewer.new()
	viewer.view_distance = 48
	viewer.requires_visuals = false
	player.add_child(viewer)
	ps = auth.add_player(1, player)
	for i in 900:
		if world.terrain.is_area_meshed(AABB(player.global_position - Vector3.ONE * 8, Vector3.ONE * 16)):
			break
		await tree.physics_frame


func _teardown() -> void:
	auth.get_parent().queue_free()


func _spawn(kind: String, offset: Vector3) -> Monster:
	var uid: int = auth.monsters._next_uid
	var p := world.maker.find_floor(player.global_position.x + offset.x, player.global_position.z + offset.z, player.global_position.y + 2.0)
	auth.monsters._ev_spawn(uid, kind, p + Vector3.UP * 0.3, false, 0, "")
	return auth.monsters.get_monster(uid)


func _anims(kind: String) -> Array:
	var out := []
	for a: Dictionary in Monsters.LIST[kind].attacks:
		var f := a
		while true:
			if f.has("anim"):
				out.append(String(f.anim))
			if not f.has("follow"):
				break
			f = f.follow
	return out


func test_ghosts_wear_a_ghost_body_on_the_dwarf_skeleton() -> void:
	for kind in KINDS:
		check(Monsters.LIST.has(kind) and Monsters.LIST[kind].get("ghost", false), "%s is a ghost in the creature list" % kind)
		var model := MonsterModel.build("ghost", Monsters.LIST[kind].color, 1.0, false, kind, 1)
		tree.root.add_child(model)
		var rig := CreatureRig.find(model)
		check(rig is GhostRig, "%s moves by the dwarf's skeleton (GhostRig)" % kind)
		var skin := 0
		var other := 0
		for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			if not mi.is_visible_in_tree():
				continue
			if mi.is_in_group("ghost_skin"):
				skin += 1
				check(mi.material_override is ShaderMaterial, "%s's %s wears the ghost shader" % [kind, mi.name])
			else:
				other += 1
		check(skin >= 4, "%s shows its ghost body and its mace (%d parts)" % [kind, skin])
		check(other == 0, "%s shows none of the dwarf's own body (%d parts showing)" % [kind, other])
		var skel := model.find_child("Skeleton3D", true, false) as Skeleton3D
		check(skel != null and skel.find_bone("hand_r") >= 0, "%s has the dwarf's skeleton" % kind)
		var bound := 0
		for mi: MeshInstance3D in model.find_children("ghost_*", "MeshInstance3D", true, false):
			if mi.get_parent() == skel and mi.skin != null:
				bound += 1
		check(bound == 3, "%s's body, eyes and fists ride on that skeleton (%d)" % [kind, bound])
		model.free()


func test_three_different_mace_moves_and_the_boss_has_all_four() -> void:
	var seen := {}
	for kind in ["ghost_a", "ghost_b", "ghost_c"]:
		var a := _anims(kind)
		check(a.size() == 1 and DwarfOneSwing.has_move(String(DwarfRig.ANIMS.get(a[0], "o/" + a[0])).trim_prefix("o/")),
			"%s swings one baked one-handed move (%s)" % [kind, a])
		# owner, Nov 22: a combo's middle hit alone snaps and doesn't wind up; only the combo starter plays alone
		check(not String(a[0]) in ["mace_2", "mace_3", "mace_4"] or kind == "ghost_lord", "%s's single blow starts from standing" % kind)
		if not a.is_empty():
			check(not seen.has(a[0]), "%s's move is its own" % kind)
			seen[a[0]] = true
	var lord := _anims("ghost_lord")
	for m in ["mace_1", "mace_2", "mace_3", "mace_4"]:
		check(m in lord, "the Grey Warden swings %s" % m)
		check(m in DwarfRig.ATTACKS["mace"][0], "%s is one of the dwarf's own mace moves" % m)


func test_the_ghost_swings_the_dwarf_mace_move() -> void:
	var model := MonsterModel.build("ghost", Color.WHITE, 1.0, false, "ghost_b", 1)
	tree.root.add_child(model)
	var rig := CreatureRig.find(model) as GhostRig
	check(rig != null, "it has its rig")
	if rig:
		rig.attack("SliceDiag", 0.8)
		check(rig.dm.swinging, "the swing plays")
		check(rig.dm.dwarf_rig._upper_clip == "o/SliceDiag", "it plays its own move (%s)" % rig.dm.dwarf_rig._upper_clip)
		check(absf(rig._busy - 0.8 / DwarfOneSwing.HIT_AT) < 0.01, "the blow lands with the tell (the strike at HIT_AT)")
		for i in 5:
			rig.step(0.1, 0.0, 3.0, true, false)
		check(rig.dm.position.y > 0.1, "it floats (%.2f m up)" % rig.dm.position.y)
	model.free()


func test_after_each_quarter_it_fades_away_and_rushes() -> void:
	await _setup()
	var m := _spawn("ghost_a", Vector3(5, 0, 0))
	check(m != null, "a ghost appears")
	if m == null:
		_teardown()
		return
	await tree.process_frame
	var start := m.global_position
	auth.monsters._hurt_monster(m, 1, 10, 0.0)  # (150 -> 140: no quarter yet)
	await tree.create_timer(0.8).timeout
	check(m.global_position.distance_to(start) < 2.5, "a small hit: it stays")
	start = m.global_position
	auth.monsters._hurt_monster(m, 1, 40, 0.0)  # (140 -> 100: past 112.5, a quarter gone)
	check(Ghost.rush(m) > 1.0, "it rushes after its jump")
	# F659: it breaks into small dots (no mist balls) that start in its old body...
	await tree.process_frame
	var dots := tree.get_nodes_in_group("ghost_dots")
	check(dots.size() == 1, "it breaks into dots (%d dot clouds)" % dots.size())
	var mm: MultiMesh = (dots[0] as MultiMeshInstance3D).multimesh if not dots.is_empty() else null
	check(mm != null and mm.instance_count >= 60, "lots of them")
	var near_old := 0
	if mm != null:
		for i in mm.instance_count:
			near_old += int((mm.get_meta("dots")[i] as Vector3).distance_to(start + Vector3.UP * 0.9) < 1.3)
	check(mm != null and near_old > mm.instance_count * 0.9, "they start in its old body (%d)" % near_old)
	await tree.create_timer(0.8).timeout
	# ...and gather again where it comes back
	var near_new := 0
	if is_instance_valid(mm):
		for i in mm.instance_count:
			near_new += int((mm.get_meta("dots")[i] as Vector3).distance_to(m.global_position + Vector3.UP * 0.9) < 1.3)
	check(mm != null and near_new > mm.instance_count * 0.9, "they gather where it comes back (%d)" % near_new)
	var moved := m.global_position.distance_to(start)
	check(moved >= 2.0, "it came back somewhere else (%.1f m away)" % moved)
	check(world.maker.sdf_at(m.global_position + Vector3.UP * 0.8) > 0.3, "with room to float there")
	_teardown()


func test_it_dies_into_mist_not_stone() -> void:
	await _setup()
	var m := _spawn("ghost_c", Vector3(4, 0, 2))
	check(m != null, "a ghost appears")
	if m == null:
		_teardown()
		return
	await tree.process_frame
	var model := m.model
	auth.monsters._hurt_monster(m, 1, 9999, 0.0)
	await tree.create_timer(0.4).timeout
	check(is_instance_valid(model) and model.is_inside_tree(), "its body lingers a moment")
	if is_instance_valid(model):
		var f: float = (Ghost.mats(model)[0] as ShaderMaterial).get_shader_parameter("fade")
		check(f < 1.0, "fading away (%.2f)" % f)
	await tree.create_timer(1.3).timeout
	check(not is_instance_valid(model), "then it is gone")
	check(tree.get_nodes_in_group("ghost_dots").is_empty(), "and so are its dots")
	check(tree.root.find_children("*", "Statue", true, false).is_empty(), "no stone statue left behind")
	_teardown()
