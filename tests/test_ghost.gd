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


## Owner, Nov 22: thin maces (no toys), the Bearded Shade's twice as long, the Wrathful Shade's long too.
func test_each_ghost_has_its_own_thin_mace() -> void:
	var lengths := {}
	var widths := {}
	for kind in ["ghost_a", "ghost_b", "ghost_c"]:
		var model := MonsterModel.build("ghost", Color.WHITE, 1.0, false, kind, 1)
		tree.root.add_child(model)
		var rig := CreatureRig.find(model) as GhostRig
		var box := AABB()
		var first := true
		for mi: MeshInstance3D in rig.dm.dwarf_rig.grip.find_children("*", "MeshInstance3D", true, false):
			var bb := mi.get_aabb()
			box = bb if first else box.merge(bb)
			first = false
		lengths[kind] = box.size.y
		widths[kind] = box.size.x  # (the head is the widest part)
		check(not first and box.size.x < 0.3, "%s's mace isn't a toy club (%.2f m across)" % [kind, box.size.x])
		model.free()
	# owner, Nov 22: the Wrathful Shade's length was right, its head bigger; the Bearded Shade (and the boss) the same mace
	check(lengths.ghost_b > lengths.ghost_a * 1.5, "the Wrathful Shade's mace is long (%.2f vs %.2f m)" % [lengths.ghost_b, lengths.ghost_a])
	check(widths.ghost_b > widths.ghost_a * 1.8, "and its head is big (%.2f vs %.2f m)" % [widths.ghost_b, widths.ghost_a])
	check(is_equal_approx(lengths.ghost_c, lengths.ghost_b) and is_equal_approx(widths.ghost_c, widths.ghost_b), "the Bearded Shade has the same mace")


## F658 (owner: the Wrathful Shade's mace "goes into his neck"): over the whole swing, the long mace's shaft and head
## stay out of the head and neck.
func test_the_long_maces_stay_out_of_the_neck() -> void:
	for kind in [["ghost_b", "SliceDiag", 0.85], ["ghost_c", "Chop", 1.05]]:
		var model := MonsterModel.build("ghost", Color.WHITE, 1.0, false, kind[0], 1)
		tree.root.add_child(model)
		var rig := CreatureRig.find(model) as GhostRig
		var dr: DwarfRig = rig.dm.dwarf_rig
		var sk := dr.skeleton
		var head := sk.find_bone("Head")
		var neck := sk.find_bone("neck_01")
		var meshes := dr.grip.find_children("*", "MeshInstance3D", true, false)
		rig.attack(kind[1], kind[2])
		var length: float = kind[2] / DwarfOneSwing.HIT_AT
		var start := Time.get_ticks_msec()
		var closest := 99.0
		var at := 0.0
		while Time.get_ticks_msec() - start < length * 1000.0:
			await tree.process_frame
			var spots: Array[Vector3] = []
			for b in [head, neck]:
				if b >= 0:
					spots.append(sk.global_transform * sk.get_bone_global_pose(b).origin)
			for mi: MeshInstance3D in meshes:
				var bb := mi.get_aabb()
				for i in 12:
					var p := mi.global_transform * Vector3(bb.get_center().x, bb.position.y + bb.size.y * (i + 0.5) / 12.0, bb.get_center().z)
					# (the grip wrap is in the fist, which is near the body anyway: only the shaft above it counts)
					if bb.position.y + bb.size.y * (i + 0.5) / 12.0 < 0.3:
						continue
					for s in spots:
						if p.distance_to(s) < closest:
							closest = p.distance_to(s)
							at = (Time.get_ticks_msec() - start) / (length * 1000.0)
		print("%s closest mace-to-neck %.2f m at %.0f%%" % [kind[0], closest, at * 100])
		check(closest > 0.2, "%s's mace keeps out of the neck (%.2f m)" % [kind[0], closest])
		model.free()


## Owner, Nov 22: the ghosts were "still very fat" (then about 1.8 m arm to arm in the game). Now under 1.65 m arm to arm (arms out)
## and under 0.82 m deep.
func test_the_ghosts_are_not_fat() -> void:
	for kind in ["ghost_a", "ghost_b", "ghost_c"]:
		var model := MonsterModel.build("ghost", Color.WHITE, 1.0, false, kind, 1)
		tree.root.add_child(model)
		var box := AABB()
		var first := true
		for mi: MeshInstance3D in model.find_children("ghost_*_body", "MeshInstance3D", true, false):
			var bb := mi.global_transform * mi.get_aabb()
			box = bb if first else box.merge(bb)
			first = false
		print("%s body %.2f wide, %.2f deep, %.2f tall" % [kind, box.size.x, box.size.z, box.size.y])
		check(not first and box.size.x < 1.65 and box.size.z < 0.82, "%s is slim (%.2f wide, %.2f deep)" % [kind, box.size.x, box.size.z])
		model.free()


## F873 (owner, Nov 25): after its jump it shows again right behind you (you face what you hit, so: the far side of
## you from where it stood), in open air, close enough to swing, and swings at once.
func test_it_comes_back_behind_you_and_swings() -> void:
	await _setup()
	var m := _spawn("ghost_a", Vector3(4, 0, 0))
	check(m != null, "a ghost appears")
	if m == null:
		_teardown()
		return
	await tree.process_frame
	m.alert(1)
	var start := m.global_position
	auth.monsters._hurt_monster(m, 1, 40, 0.0)
	var me := player.global_position
	var was := (start - me) * Vector3(1, 0, 1)
	var swung := false
	for i in 120:
		await tree.physics_frame
		if String(m._attack.get("name", "")) == "Ambush Chop":
			swung = true
			break
	var now := (m.global_position - me) * Vector3(1, 0, 1)
	check(now.normalized().dot(was.normalized()) < -0.3, "it came back on your other side (behind you)")
	check(now.length() < 2.6, "close behind you (%.1f m)" % now.length())
	check(world.maker.sdf_at(m.global_position + Vector3.UP * 0.8) > Ghost.BODY_ROOM, "in open air, not in the rock")
	check(swung, "and swings at once (the ambush chop)")
	_teardown()


## F851 / F743: every ghost swing shows the parry star on its mace head first.
func test_every_ghost_swing_shows_the_star_first() -> void:
	await _setup()
	var m := _spawn("ghost_a", Vector3(4, 0, 0))
	await tree.process_frame
	var rig := m.rig as GhostRig
	check(rig != null, "a ghost has a ghost rig")
	if rig == null:
		_teardown()
		return
	rig.attack("mace_1", 0.85)
	var star_at := -1.0
	var t0 := Time.get_ticks_msec()
	for i in 120:
		await tree.process_frame
		if rig.stars > 0:
			star_at = (Time.get_ticks_msec() - t0) / 1000.0
			break
	check(star_at >= 0.0, "the star shows on its mace")
	check(star_at < 0.85, "before the blow lands (%.2f s)" % star_at)
	_teardown()


## F850 (owner, Nov 25): the Shield-Brother holds a shield you can see; it drops when he swings and while he's down.
func test_the_shield_brother_shows_and_drops_his_shield() -> void:
	await _setup()
	var m := _spawn("shield_brother", Vector3(4, 0, 0))
	await tree.process_frame
	var rig := m.rig as GhostRig
	check(rig != null and rig.guard, "he guards with a shield")
	if rig == null:
		_teardown()
		return
	var shield := rig.dm.dwarf_rig.shield_grip.find_children("*", "MeshInstance3D", true, false)
	check(not shield.is_empty() and shield.any(func(s): return s.is_visible_in_tree()), "his shield shows")
	check(not rig.shield_open(), "shield up while he waits")
	check(auth.monsters._shield_blocks(m, m.global_position - m.model.global_basis.z * 2.0, false), "it blocks from the front")
	rig.attack("Chop", 1.0)
	check(rig.shield_open(), "his shield drops as he swings")
	check(not auth.monsters._shield_blocks(m, m.global_position - m.model.global_basis.z * 2.0, false), "so a hit then gets through")
	check(m.data.get("turns_in_place", false), "he turns slowly: step round him")
	check(m.data.attacks.any(func(a): return a.name == "Shield Charge"), "he charges behind his shield")
	_teardown()


## Owner, Nov 22: after every ghost attack the mace "teleports a little bit at the last second" on its way back to
## the resting pose (all four ghosts). The mace's head is followed frame by frame through each swing and its ease
## back; no frame near the end may jump far more than the frames around it.
## F849 🔁 (owner, Nov 25: "he does two attacks and then just stands there"): a parry no longer cuts Hald's combo short.
func test_a_parry_doesnt_stop_halds_combo() -> void:
	await _setup()
	var m := _spawn("hald_ironbrow", Vector3(2, 0, 0))
	check(m != null, "Hald appears")
	if m == null:
		_teardown()
		return
	await tree.process_frame
	m.alert(1)
	var combo: Dictionary = m.data.attacks[0]
	m._start_attack(combo, auth.monsters)
	auth.monsters.request_parried(m.uid, 1.0, 1)
	check(m.state == Monster.State.ATTACK, "still swinging after the parry")
	var seen := {}
	for i in 400:
		await tree.physics_frame
		if m.state == Monster.State.ATTACK:
			seen[String(m._attack.get("anim", ""))] = true
		elif not seen.is_empty() and m.state != Monster.State.ATTACK:
			break
	check(seen.has("mace_4"), "all four blows come (saw %s)" % str(seen.keys()))
	_teardown()


func test_the_mace_eases_back_without_a_jump() -> void:
	for kind in [["ghost_a", "mace_1", 0.85], ["ghost_b", "SliceDiag", 0.85], ["ghost_c", "Chop", 1.05], ["ghost_lord", "mace_4", 0.75]]:
		var model := MonsterModel.build("ghost", Color.WHITE, 1.0, false, kind[0], 1)
		tree.root.add_child(model)
		var rig := CreatureRig.find(model) as GhostRig
		var dr: DwarfRig = rig.dm.dwarf_rig
		var mi := dr.grip.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
		for i in 10:
			await tree.process_frame
		rig.attack(kind[1], kind[2])
		var length: float = kind[2] / DwarfOneSwing.HIT_AT
		var start := Time.get_ticks_usec()
		var bb := mi.get_aabb()
		var top := Vector3(bb.get_center().x, bb.end.y, bb.get_center().z)
		var prev := mi.global_transform * top
		var rows: Array = []  # [how far into the swing (1 = its end), the mace head's speed (m/s)]
		while (Time.get_ticks_usec() - start) / 1e6 < length + Ghost.RETURN_TIME + 0.2:
			await tree.process_frame
			rig.step(0.016, 0.0, 3.0, true, false)
			var p := mi.global_transform * top
			rows.append([(Time.get_ticks_usec() - start) / 1e6 / length, p.distance_to(prev) / maxf(tree.root.get_process_delta_time(), 0.0005)])
			prev = p
		var worst := 0.0
		var worst_at := 0.0
		for i in range(2, rows.size() - 2):
			if rows[i][0] < 0.8:
				continue
			var around: float = (rows[i - 2][1] + rows[i + 2][1]) * 0.5
			var jump: float = rows[i][1] / maxf(around, 0.3)
			if jump > worst:
				worst = jump
				worst_at = rows[i][0]
		print("%s mace's worst jump %.1fx at %.0f%% of the swing" % [kind[0], worst, worst_at * 100])
		check(worst < 3.0, "%s's mace eases back without a jump (%.1fx at %.0f%%)" % [kind[0], worst, worst_at * 100])
		model.free()


## Owner, Nov 25 (4th round): "I don't want ghosts to have the stun whatsoever ... anytime they teleport, they should
## teleport behind me, facing me, and always attack" (a hard hit used to daze it: it came back and did nothing).
func test_a_hard_hit_never_stuns_a_ghost_and_it_still_swings_facing_you() -> void:
	await _setup()
	var m := _spawn("ghost_b", Vector3(4, 0, 0))
	check(m != null, "a ghost appears")
	if m == null:
		_teardown()
		return
	await tree.process_frame
	m.alert(1)
	auth.monsters._hurt_monster(m, 1, 40, 500.0)  # (a big two-handed mace blow's worth of stun, and more)
	check(not m.stun.is_stunned(), "no stun from the hardest blow")
	m.start_knockdown(3.0)
	check(not m.rig.knocked_down, "and it never falls apart")
	var swung := false
	var facing := -1.0
	for i in 120:
		await tree.physics_frame
		if String(m._attack.get("name", "")) == "Ambush Chop":
			swung = true
			var fwd := -m.model.global_basis.z * Vector3(1, 0, 1)
			facing = fwd.normalized().dot(((player.global_position - m.global_position) * Vector3(1, 0, 1)).normalized())
			break
	check(swung, "it comes back and swings at once")
	check(facing > 0.8, "facing you (%.2f)" % facing)
	_teardown()


## Owner, Nov 25: "the blue ghost will just run towards me and not do anything until I hit him": its only blow is a
## lunge, and lunges never started closer than 2 m.
func test_the_blue_ghost_swings_when_right_next_to_you() -> void:
	await _setup()
	var m := _spawn("ghost_b", Vector3(1.4, 0, 0))
	check(m != null, "a ghost appears")
	if m == null:
		_teardown()
		return
	await tree.process_frame
	check(not m._pick_attack(1.2, auth.monsters).is_empty(), "it has a blow at 1.2 m")
	var miner: Monster = _spawn("lost_miner", Vector3(-3, 0, 0)) if Monsters.LIST.has("lost_miner") else null
	if miner:
		check(miner._pick_attack(1.2, auth.monsters).is_empty(), "(a Lost Miner still circles close up: its leap needs room)")
	_teardown()
