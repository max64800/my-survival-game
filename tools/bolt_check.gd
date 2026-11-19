extends SceneTree
## Real crossbow shot at a bat in the air (Claude, Nov 19: owner "I shoot at the bat and nothing happened").
## Starts a world (saving OFF), gives a crossbow and bolts, puts a bat in front of the dwarf, aims, shoots.
##   godot --audio-driver Dummy --path . --script res://tools/bolt_check.gd -- seed=42
var main: Node


func _init() -> void:
	main = (load("res://src/main.tscn") as PackedScene).instantiate()
	main.set("_saving", false)
	root.add_child.call_deferred(main)
	_run.call_deferred()


func _run() -> void:
	while not main.call("is_ready_to_play"):
		await process_frame
	for i in 120:
		await physics_frame
	var auth := GameAuthority.instance
	var ps: GameAuthority.PlayerState = auth.get_player(auth.local_peer_id())
	var dwarf: Dwarf = ps.node
	ps.inventory.add("crossbow_stone", 1)
	ps.inventory.add("bolt_stone", 10)
	for i in Inventory.HOTBAR_SIZE:
		if ps.inventory.get_slot(i).get("id", "") == "crossbow_stone":
			auth.request_select_slot(auth.local_peer_id(), i)
	dwarf.global_position = auth.world.maker.cavern_spawn + Vector3.UP * 0.5  # (the big first cavern: room to shoot)
	for i in 60:
		await physics_frame
	for case in [["ground", 0.0], ["air", 1.8], ["high", 3.0]]:
		var mm: MonsterManager = auth.monsters
		var uid: int = mm._next_uid
		var fwd := -dwarf.camera.global_basis.z
		fwd.y = 0
		var at: Vector3 = dwarf.global_position + fwd.normalized() * 5.0 + Vector3.UP * float(case[1])
		mm._ev_spawn(uid, "cave_bat", at, false, 0)
		var m: Monster = mm.get_monster(uid)
		m.state = Monster.State.CHASE
		m.set_physics_process(false)
		m.global_position = at
		for i in 3:
			await physics_frame
		var hp0 := m.hp
		dwarf.camera.look_at(m.global_position + Vector3.UP * 0.4)
		var q := PhysicsRayQueryParameters3D.create(dwarf.camera.global_position, dwarf.camera.global_position - dwarf.camera.global_basis.z * 30.0)
		q.collision_mask = World.TERRAIN_LAYER | Monster.MONSTER_LAYER | PieceNode.PIECE_LAYER | Dwarf.BODY_LAYER
		q.exclude = [dwarf.get_rid()]
		var hit := dwarf.get_world_3d().direct_space_state.intersect_ray(q)
		var c: Object = hit.get("collider")
		var c_is_bat: bool = c != null and MonsterManager.uid_of(c) == uid
		var c_name := str(c)
		dwarf.fight.reload_left = 0.0
		dwarf.fight.loaded = true
		dwarf.fight._shoot(true)
		for i in 3:
			await physics_frame
		print("BOLT %s: cam %s bat %s aim hits %s at %s (bat? %s), bat hp %.0f -> %s, bolts left %d" % [case[0], dwarf.camera.global_position.snapped(Vector3.ONE * 0.1), at.snapped(Vector3.ONE * 0.1), c_name, (hit.get("position", Vector3.ZERO) as Vector3).snapped(Vector3.ONE * 0.1), c_is_bat, hp0, ("%.0f" % m.hp) if is_instance_valid(m) and m.is_alive() else "DEAD", ps.inventory.count_of("bolt_stone")])
		if is_instance_valid(m):
			m.global_position += Vector3.UP * 100.0
	# A roost: a sleeping bat hanging from the cave ceiling, shot where you see it.
	var mm2: MonsterManager = auth.monsters
	var maker: CaveMaker = auth.world.maker
	var fwd2 := -dwarf.camera.global_basis.z
	fwd2.y = 0
	var ceiling := Vector3.INF
	for k in 16:  # a spot 5-7 m away with a ceiling 3-7 m up, like a real roost
		var dir := fwd2.normalized().rotated(Vector3.UP, k * TAU / 16.0)
		var fl := maker.find_floor(dwarf.global_position.x + dir.x * 6.0, dwarf.global_position.z + dir.z * 6.0, dwarf.global_position.y + 2.0)
		var c := GlowPlacer._march(maker, fl + Vector3.UP * 1.0, Vector3.UP, 30.0)
		if c != Vector3.INF and c.y - fl.y > 2.5 and c.y - fl.y < 16.0:
			ceiling = c
			dwarf.camera.look_at(c)
			break
	if ceiling != Vector3.INF:
		var uid2: int = mm2._next_uid
		mm2._next_uid += 1
		mm2._ev_spawn(uid2, "cave_bat", ceiling + Vector3.DOWN * 0.3, false, 0)
		var b: Monster = mm2.get_monster(uid2)
		b.state = Monster.State.SLEEP
		for i in 10:
			await process_frame
		var seen := Vector3.ZERO
		var cnt := 0
		for mi in b.model.find_children("*", "MeshInstance3D", true, false):
			seen += (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb().get_center()
			cnt += 1
		seen /= maxf(1, cnt)
		dwarf.camera.look_at(seen)
		var hp1 := b.hp
		dwarf.fight.reload_left = 0.0
		dwarf.fight.loaded = true
		var q2 := PhysicsRayQueryParameters3D.create(dwarf.camera.global_position, dwarf.camera.global_position - dwarf.camera.global_basis.z * 30.0)
		q2.collision_mask = World.TERRAIN_LAYER | Monster.MONSTER_LAYER | PieceNode.PIECE_LAYER | Dwarf.BODY_LAYER
		q2.exclude = [dwarf.get_rid()]
		print("BOLT   roost aim line hits: ", dwarf.get_world_3d().direct_space_state.intersect_ray(q2).get("collider"), " bat body at ", b.global_position.snapped(Vector3.ONE * 0.1))
		dwarf.fight._shoot(true)
		for i in 3:
			await physics_frame
		print("BOLT roosting bat (ceiling %.1f m above, picture at %s): hp %.0f -> %s" % [ceiling.y - dwarf.global_position.y, seen.snapped(Vector3.ONE * 0.1), hp1, ("%.0f" % b.hp) if is_instance_valid(b) and b.is_alive() else "DEAD"])
	print("BOLT_END")
	quit()
