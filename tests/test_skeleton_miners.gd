extends TestCase
## The skeleton miners of Lampwick Drift and Old Pell's Diggings (Nov 20): Tunnel Rat, Lost Miner, the Foreman.
## They move by a skeleton (CreatureRig). Owner's wishes F462-F467.

var world: World
var auth: GameAuthority
var player: Node3D
var ps: GameAuthority.PlayerState


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


func _spawn(kind: String, offset: Vector3, variant := "") -> Monster:
	var uid: int = auth.monsters._next_uid
	var p := world.maker.find_floor(player.global_position.x + offset.x, player.global_position.z + offset.z, player.global_position.y + 2.0)
	auth.monsters._ev_spawn(uid, kind, p + Vector3.UP * 0.3, false, 0, variant)
	return auth.monsters.get_monster(uid)


func test_miners_have_skeletons_and_their_looks() -> void:
	for kind in ["tunnel_rat", "lost_miner", "foreman"]:
		check(Monsters.LIST.has(kind), "%s is in the creature list" % kind)
		var seen := {}
		for seed in 3:
			var model := MonsterModel.build("", Color.WHITE, 1.0, false, kind, seed)
			var holder := Node3D.new()
			holder.add_child(model)
			var rig := CreatureRig.find(model)
			check(rig != null, "%s (look %d) moves by its skeleton" % [kind, seed])
			if rig:
				for clip in [CreatureRig.RISE, CreatureRig.LIE, CreatureRig.DEATH, CreatureRig.HIT, "Running_A", "Idle_Combat"]:
					check(rig.ap.has_animation(clip), "%s has the move %s" % [kind, clip])
				for a in Monsters.LIST[kind].attacks:
					check(rig.ap.has_animation(a.anim), "%s's %s has its move %s" % [kind, a.name, a.anim])
				check(rig.ap.get_animation("Running_A").loop_mode == Animation.LOOP_LINEAR, "the run loops")
			var forged: Node3D = model.get_meta("forged_root", null)
			if forged:
				seen[String(forged.scene_file_path)] = true
			holder.free()
		check_eq(seen.size(), 1 if kind == "foreman" else 3, "%s: its looks are mixed (F466)" % kind)


## F462: they lie scattered on the floor and get up when you come near; then they run at you (F464).
func test_bones_rise_when_you_come_near() -> void:
	await _setup()
	var m := _spawn("tunnel_rat", Vector3(14, 0, 0))
	check_eq(m.state, Monster.State.SLEEP, "starts lying on the floor")
	check(m.rig != null and m.rig.lying, "...as a pile of bones")
	for i in 10:
		m.think(0.1, auth.monsters)
	check_eq(m.state, Monster.State.SLEEP, "14 m away: it stays down")
	m.global_position = player.global_position + Vector3(5, 0.3, 0)
	for i in 4:
		m.think(0.1, auth.monsters)
	check_eq(m.state, Monster.State.ALERT, "5 m away: it gets up")
	check(not m.rig.lying and m.rig._busy_kind == "rise", "...playing the getting-up move")
	m.think(0.1, auth.monsters)
	check_eq(m.state, Monster.State.ALERT, "it stays put while it rises")
	for i in 25:
		m.think(0.1, auth.monsters)
	check(m.state in [Monster.State.CHASE, Monster.State.ATTACK], "then it comes at you (state %d)" % m.state)
	_teardown()


## F462: hit while lying, it gets up first (it doesn't fight from the floor).
func test_hit_pile_gets_up() -> void:
	await _setup()
	var m := _spawn("lost_miner", Vector3(12, 0, 0))
	m.alert(1)
	check_eq(m.state, Monster.State.ALERT, "hit: it rises")
	m.alert(1)
	check_eq(m.state, Monster.State.ALERT, "hit again while rising: still getting up")
	_teardown()


## F466/F467: the right numbers.
func test_miner_numbers() -> void:
	var rat: Dictionary = Monsters.LIST.tunnel_rat
	var miner: Dictionary = Monsters.LIST.lost_miner
	var boss: Dictionary = Monsters.LIST.foreman
	check(rat.hp < miner.hp and rat.run > miner.run, "the rat is easier and faster than the Lost Miner")
	check(rat.attacks.all(func(a): return a.damage < 8), "the rat hits soft")
	check(miner.attacks.all(func(a): return a.get("buildup", {}).get("chill", 0) > 0), "the Lost Miner's hits give frost")
	check(boss.hp > miner.hp * 3, "the Foreman is the boss")
	check(boss.attacks.any(func(a): return a.anim == "2H_Melee_Attack_Spin"), "the Foreman has the big spin")
	# Owner, Nov 20: the spin reached too far and he only ever spun.
	var chop: Dictionary = boss.attacks.filter(func(a): return a.anim == "2H_Melee_Attack_Chop")[0]
	var whirl: Dictionary = boss.attacks.filter(func(a): return a.anim == "2H_Melee_Attack_Spin")[0]
	check(chop.reach > whirl.reach, "the chop reaches further than the spin, so he opens with the chop")
	check(whirl.reach + 0.8 <= 2.7, "the spin only hits close (its hit range is reach + 0.8 m)")
	check(whirl.get("rest", 0.0) >= 5.0, "the spin rests a few seconds after each use")
	for kind in ["tunnel_rat", "lost_miner", "foreman"]:
		check(not Monsters.LIST[kind].attacks.any(func(a): return String(a.get("anim", "")).contains("Taunt")), "%s: no taunt (F464)" % kind)


func test_no_crystal_miners() -> void:
	await _setup()
	var m := _spawn("tunnel_rat", Vector3(12, 0, 0), "blue")
	check_eq(m.variant, "", "no icy crystal skeleton (the crystals can't follow its bones)")
	_teardown()


## F463: it falls apart, then the bones turn to stone you can mine.
func test_falls_apart_then_stone() -> void:
	await _setup()
	var m := _spawn("tunnel_rat", Vector3(4, 0, 0))
	m.show_rise()
	await tree.create_timer(Monster.RISE_TIME + 0.3).timeout  # (it stands up first)
	var at := m.global_position
	auth.monsters._kill(m, 1)
	var corpse: Node3D = null
	for id in Statue.nodes:
		if is_instance_valid(Statue.nodes[id]) and (Statue.nodes[id] as Node3D).global_position.distance_to(at) < 0.5:
			corpse = Statue.nodes[id]
	check(corpse != null, "it left a body to turn to stone")
	if corpse == null:
		_teardown()
		return
	var sk: Skeleton3D = corpse.find_children("*", "Skeleton3D", true, false)[0]
	var head := sk.find_bone("head")
	var head_y0 := (sk.global_transform * sk.get_bone_global_pose(head)).origin.y - at.y
	await tree.create_timer(2.4).timeout
	check(corpse.has_meta("statue"), "the bones turned to stone")
	var head_y := (sk.global_transform * sk.get_bone_global_pose(head)).origin.y - at.y
	check(head_y < head_y0 - 0.12,"it fell apart: its head came down (%.2f -> %.2f m)" % [head_y0, head_y])
	var shapes := corpse.find_children("*", "CollisionShape3D", true, false)
	check(shapes.size() == 1, "the pile is solid (your pickaxe hits it)")
	if shapes.size() == 1:
		var box: AABB = corpse.get_meta("bone_box")
		check(box.size.y < 1.0, "its solid box is the low pile, not a standing skeleton (%.2f m tall)" % box.size.y)
	_teardown()


## Owner, Nov 20: after a spin the Foreman can't spin again for a while, so he chops in between.
func test_foreman_spin_rests() -> void:
	await _setup()
	var m := _spawn("foreman", Vector3(12, 0, 0))
	var picked := m._pick_attack(1.0)
	var whirl_name: String = Monsters.LIST.foreman.attacks[1].name
	for i in 30:
		if picked.name == whirl_name:
			break
		picked = m._pick_attack(1.0)
	check_eq(picked.name, whirl_name, "close by he can spin")
	m._start_attack(picked, auth.monsters)
	for i in 20:
		check(m._pick_attack(1.0).name != whirl_name, "right after a spin he only chops")
	check_eq(m._pick_attack(2.2).name, Monsters.LIST.foreman.attacks[0].name, "at 2.2 m only the chop reaches")
	_teardown()


## Owner, Nov 20: the bone piles all lay the same way; and the Foreman's swing breaks a fallen miner's stone.
func test_piles_lie_every_way_and_the_foreman_smashes_stone() -> void:
	await _setup()
	var a := _spawn("tunnel_rat", Vector3(12, 0, 0))
	var b := _spawn("tunnel_rat", Vector3(12, 0, 3))
	check(absf(a.model.rotation.y - b.model.rotation.y) > 0.2, "two piles lie different ways")
	var boss := _spawn("foreman", Vector3(-12, 0, 0))
	var at := boss.global_position + Vector3(0, 0, -1.2)
	auth.monsters.statues[999] = {pos = at, kind = "lost_miner", loot = [], hits = 0, needed = 4, left = 60.0}
	boss.model.rotation.y = 0.0  # (facing -z: the stone is right in front)
	var n := auth.monsters.smash_statues_in_reach(boss, Monsters.LIST.foreman.attacks[0])
	check_eq(n, 1, "his chop breaks the stone in front of him")
	check(not auth.monsters.statues.has(999), "it is gone")
	_teardown()


## Owner, Nov 20: you (and the creatures) walk through a stone corpse; the daze stars go when it dies.
func test_stone_corpses_dont_block_and_lose_their_stars() -> void:
	var src := FileAccess.get_file_as_string("res://src/combat/statue.gd")
	check(not src.contains("collision_layer = World.TERRAIN_LAYER"), "a stone corpse never becomes solid rock")
	await _setup()
	var m := _spawn("lost_miner", Vector3(12, 0, 0))
	m.stun.stunned_left = 3.0
	m._daze_stars()
	check(m._stars != null and m._stars.visible, "dazed: stars")
	check(m._stars.global_position.y > m.global_position.y + 1.3, "the stars circle over its head, not inside it")
	m.die_visual()
	check(m._stars == null, "dead: the stars are gone")
	_teardown()


## Owner, Nov 20: "I don't see them attacking, so I don't see when to parry": a star + "ting" on the pick 0.4 s
## before every blow lands (right away when the whole warning is shorter), drawn on top of everything.
func test_pick_glint_comes_before_the_blow() -> void:
	check_near(CreatureRig.glint_wait(0.55), 0.15, 0.001, "the Tunnel Rat's chop: the star 0.4 s before the blow")
	check_near(CreatureRig.glint_wait(1.0), 0.6, 0.001, "the Foreman's chop: also 0.4 s before")
	check_eq(CreatureRig.glint_wait(0.3), 0.0, "a warning shorter than 0.4 s: the star right away")
	for kind in ["tunnel_rat", "lost_miner", "foreman"]:
		for atk: Dictionary in Monsters.LIST[kind].attacks:
			check(float(atk.tell) - CreatureRig.glint_wait(float(atk.tell)) >= 0.4 or CreatureRig.glint_wait(float(atk.tell)) == 0.0,
				"%s %s: you get the whole warning time after the star" % [kind, atk.name])


## Owner, Nov 21 ("a tiny bit harder"): the Foreman's whirl goes on and slides after you (dodge it); the Lost Miners
## leap in with a fast chop from up to 4 m (no knock-down).
func test_foreman_whirl_chases_and_lost_miners_leap() -> void:
	var whirl: Dictionary = Monsters.LIST.foreman.attacks[1]
	var turns := 1
	var total: float = whirl.tell
	var f: Dictionary = whirl.get("follow", {})
	var last := whirl
	while not f.is_empty():
		turns += 1
		total += float(f.tell)
		last = f
		f = f.get("follow", {})
	check(turns >= 4, "the whirl hits several times (%d)" % turns)
	check_near(total, 2.97, 0.3, "about 3 s of whirling")
	check(not whirl.get("knockdown", false) and last.get("knockdown", false), "only the last turn knocks you down")
	check(float(whirl.follow.whirl_speed) < Dwarf.WALK_SPEED * 1.0 and float(whirl.follow.whirl_speed) > 3.0,
		"he slides after you a little slower than you walk (run or roll out)")
	var leap: Dictionary = {}
	for a: Dictionary in Monsters.LIST.lost_miner.attacks:
		if a.get("lunge", false):
			leap = a
	check(not leap.is_empty(), "the Lost Miner has a leap")
	check_eq(float(leap.get("reach", 0.0)), 4.0, "from up to 4 m")
	check(not MonsterManager.is_charge(leap), "a leap only hits: no knock-down or shove like a beetle's charge")
	for a: Dictionary in Monsters.LIST.tunnel_rat.attacks:
		check(not a.get("lunge", false), "the small Tunnel Rats stay as they are")


## Owner, Nov 21: "make sure the star is actually on the tip of the pickaxes": the points are measured from each tool.
func test_the_spark_sits_on_the_tool_points() -> void:
	for want in [["tunnel_rat_grime", 1, 0.9], ["lost_miner_frost", 2, 0.6], ["foreman", 2, 0.9]]:
		var s: Node = (load("res://assets/models/creatures/%s.glb" % want[0]) as PackedScene).instantiate()
		var sk: Skeleton3D = s.find_children("*", "Skeleton3D", true, false)[0]
		var tips := CreatureRig.tool_tips(sk, s)
		check_eq(tips.size(), want[1], "%s: %d point(s) on its tool" % [want[0], want[1]])
		for t in tips:
			check(t.y > float(want[2]), "%s: the point is up at the head of the tool, not at the hand (%s)" % [want[0], t])
		if tips.size() == 2:
			check(tips[0].x < -0.15 and tips[1].x > 0.15, "%s: the two ends of the pick's head (%s, %s)" % [want[0], tips[0], tips[1]])
		s.free()
