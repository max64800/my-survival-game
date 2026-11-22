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


## F547 (owner, Nov 21): the Prop Warden's Plank Sweep comes at random against his chop, not only up close; from
## further off he charges behind his shield (F548), never from close by.
func test_prop_warden_picks_his_moves() -> void:
	await _setup()
	var m := _spawn("prop_warden", Vector3(12, 0, 0))
	var seen := {}
	for i in 60:
		seen[String(m._pick_attack(2.2).get("name", ""))] = true
	check(seen.has("Axe Chop") and seen.has("Plank Sweep"), "at chop range he picks the chop or the sweep (%s)" % [seen.keys()])
	check(not seen.has("Shield Charge"), "no charge from close by")
	var far := m._pick_attack(6.0)
	check_eq(String(far.get("name", "")), "Shield Charge", "from 6 m he charges")
	m._start_attack(far, auth.monsters)
	check(m._pick_attack(6.0).is_empty(), "the charge rests before it comes again")
	_teardown()


## F548 (owner, Nov 21: "no shield showed"): the Prop Warden holds his shield up in front while he comes at you, and
## lowers it for his two-handed moves.
func test_prop_warden_raises_his_shield() -> void:
	var model := MonsterModel.build("foreman", Color.WHITE, 1.0, false, "prop_warden", 0)
	var holder := Node3D.new()
	tree.root.add_child(holder)
	holder.add_child(model)
	var rig := CreatureRig.find(model)
	check(rig != null, "he moves by his skeleton")
	if rig == null:
		holder.free()
		return
	rig.hold_shield()
	check(rig.shield != null, "he has a shield arm (from the Block move)")
	if rig.shield == null:
		holder.free()
		return
	for i in 20:
		rig.step(0.05, 1.3, 3.3, true, false)
	check(rig.shield.influence > 0.95, "walking at you: the shield is up (%.2f)" % rig.shield.influence)
	rig.attack("2H_Melee_Attack_Spin", 0.97)
	for i in 10:
		rig.step(0.05, 0.0, 3.3, true, false)
	check(rig.shield.influence < 0.05, "the sweep needs both hands: the shield comes down (%.2f)" % rig.shield.influence)
	var sk := rig.skel
	var hand := sk.find_bone("hand.l")
	var guard := Quaternion(rig.shield._pose.get(hand, Quaternion.IDENTITY))
	var rest := Quaternion(sk.get_bone_pose_rotation(hand))
	check(guard.angle_to(rest) > 0.05, "the Block pose really moves his left hand")
	holder.free()
	var plain := MonsterModel.build("foreman", Color.WHITE, 1.0, false, "foreman", 0)
	var h2 := Node3D.new()
	h2.add_child(plain)
	var r2 := CreatureRig.find(plain)
	check(r2 != null and r2.shield == null, "the Pit Boss has no shield arm")
	h2.free()


## F526 (owner, Nov 21): the Lost Miner's leap was way too long and it chopped again as it landed: a short leap, its only blow.
func test_lost_miner_only_leaps() -> void:
	var leap: Dictionary = Monsters.LIST.lost_miner.attacks.filter(func(a): return a.get("lunge", false))[0]
	check(leap.reach <= 3.0, "it leaps from 3 m at most (was 4)")
	await _setup()
	var m := _spawn("lost_miner", Vector3(12, 0, 0))
	var picked := m._pick_attack(2.6)
	check_eq(String(picked.get("name", "")), String(leap.name), "from 2.6 m it leaps")
	m._start_attack(picked, auth.monsters)
	check(m._pick_attack(1.0).is_empty(), "landing next to you it doesn't swing again")
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
## leap in with a fast chop from up to 3 m (no knock-down; F526: was 4, "way too long").
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
	check_near(total, 4.57, 0.5, "about 4-5 s of whirling (Nov 22: follow tells raised to 0.9 s for telegraph)")
	check(not whirl.get("knockdown", false) and last.get("knockdown", false), "only the last turn knocks you down")
	check(float(whirl.follow.whirl_speed) < Dwarf.WALK_SPEED * 1.0 and float(whirl.follow.whirl_speed) > Dwarf.WALK_SPEED * 0.5,
		"he slides after you slower than you walk (run or roll out)")
	var leap: Dictionary = {}
	for a: Dictionary in Monsters.LIST.lost_miner.attacks:
		if a.get("lunge", false):
			leap = a
	check(not leap.is_empty(), "the Lost Miner has a leap")
	check_eq(float(leap.get("reach", 0.0)), 3.0, "from up to 3 m (F526)")
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


## The Prop Warden's Rally Slam (owner, Nov 21): his fallen Lost Miners' stone glows, then up to 2 get up; a hit on him
## during the slam calls it off; a statue mined away can't come back; never more than 3 miners up; he doesn't smash them.
## Owner, Nov 21 (F592): the Prop Warden doesn't raise his miners in Mossprop Workings (its map says no_raising);
## the Rally Slam's code stays for the next boss.
func test_no_raising_in_mossprop() -> void:
	await _setup()
	var mm := auth.monsters
	var boss := _spawn("prop_warden", Vector3(-12, 0, 0))
	var old := MonsterManager.STATUE_LIFE - 10.0
	for i in 2:
		mm.statues[900 + i] = {pos = boss.global_position + Vector3(2.0 + i, 0, 0), kind = "lost_miner", loot = [], hits = 0, needed = 4, left = old}
	check_eq(mm.raisable_statues(boss).size(), 2, "out in the caves he could raise them")
	boss.dungeon = {map = DungeonMap.MOSSPROP}
	check(mm.raisable_statues(boss).is_empty(), "in Mossprop he raises nobody")
	for i in 20:
		check(not boss._pick_attack(10.0, mm).has("raise_miners"), "and never uses the Rally Slam there")
	boss.dungeon = {}  # (only a map, no rooms: off again before he thinks)
	_teardown()


func test_prop_warden_raises_fallen_miners() -> void:
	await _setup()
	var mm := auth.monsters
	var boss := _spawn("prop_warden", Vector3(-12, 0, 0))
	check(not boss.data.get("smashes_statues", false), "he doesn't break his own miners' stone")
	check(mm.raisable_statues(boss).is_empty(), "no fallen miners: nothing to raise")
	var slam: Dictionary = {}
	for a in boss.attack_options():
		if a.has("raise_miners"):
			slam = a
	check(not slam.is_empty(), "he has the Rally Slam")
	check_eq(float(slam.rest), 25.0, "about every 25 s")
	for i in 20:
		check(not boss._pick_attack(10.0, mm).has("raise_miners"), "no slam while nothing lies there")
	var old := MonsterManager.STATUE_LIFE - 10.0
	for i in 3:
		mm.statues[900 + i] = {pos = boss.global_position + Vector3(2.0 + i, 0, 0), kind = "lost_miner", loot = [], hits = 0, needed = 4, left = old}
	mm.statues[950] = {pos = boss.global_position + Vector3(0, 0, 2), kind = "lost_miner", loot = [], hits = 0, needed = 4, left = MonsterManager.STATUE_LIFE}
	mm.statues[960] = {pos = boss.global_position + Vector3(0, 0, -2), kind = "tunnel_rat", loot = [], hits = 0, needed = 2, left = old}
	check_eq(mm.raisable_statues(boss), [900, 901], "the 2 nearest old-enough miners (not a fresh one, not a rat)")
	check_eq(boss._pick_attack(10.0, mm).get("name", ""), "Rally Slam", "out of reach of his swings, he calls them")
	# A hit during the slam calls it off.
	boss._start_attack(slam, mm)
	check_eq(boss.raising, [900, 901], "the slam picked its statues")
	check(not mm._shield_blocks(boss, boss.global_position - boss.model.global_transform.basis.z * 2.0, false), "his plank is up: no shield")
	mm._hurt_monster(boss, 1, 5, 0.0)
	check(boss.raising.is_empty() and boss.state == Monster.State.RECOVER, "hit: called off")
	check(mm.statues.has(900) and mm.statues.has(901), "the stone stays")
	# Next time: one statue is mined away during the slam.
	boss._start_attack(slam, mm)
	mm.statues.erase(900)
	var up: Array = mm.finish_raise(boss)
	check_eq(up.size(), 1, "the mined one can't come back")
	check(not mm.statues.has(901), "its stone is gone")
	var miner: Monster = mm.get_monster(up[0])
	check(miner != null and miner.kind == "lost_miner", "a Lost Miner again")
	check(miner.state != Monster.State.SLEEP, "it gets up at once")
	# Never more than 3 up: with 3 standing, nothing more rises.
	_spawn("lost_miner", Vector3(-10, 0, 2))
	_spawn("lost_miner", Vector3(-10, 0, -2))
	check(mm.raisable_statues(boss).is_empty(), "3 miners standing: no more")
	_teardown()
