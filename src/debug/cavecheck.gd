extends Node
## Cave check (owner's cave-floor notes, Nov 19: F404-F407, F350): starts a fresh world and photographs the Rebuilding
## Chest (closed and opened), the starting cave's Root Trees, the calmer floor, a root in a tunnel, a boulder by a wall,
## a crystal mined and growing back, and a glowing swarm; it also measures how high the swarm stays over the floor.
## Run:  godot --audio-driver Dummy --path . -- cavecheck ruin=1 claude=cave_floor seed=42 shots=<folder>

var _main: Node
var _shots := "user://cavecheck"


func _ready() -> void:
	_main = get_parent()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("shots="):
			_shots = arg.trim_prefix("shots=")
	DirAccess.make_dir_recursive_absolute(_shots)
	_run.call_deferred()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	print("CAVECHECK shot ", _main.take_screenshot(_shots.path_join(name + ".png")))


func _run() -> void:
	var waited := 0.0
	while (not _main.is_ready_to_play() or RuinTower.last_origin == Vector3.INF) and waited < 150.0:
		await _wait(0.25)
		waited += 0.25
	Controls.set_captured(true)
	_main.hud.set_paused(false)
	var auth: GameAuthority = _main.authority
	var dwarf: Dwarf = _main.dwarf
	var maker: CaveMaker = _main.world.maker
	# F350: the Rebuilding Chest
	var box := RuinTower.last_rebuild_box
	print("CAVECHECK rebuild chest: ", box, " exists=", auth.storage.boxes.has(box))
	if auth.storage.boxes.has(box):
		var at: Vector3 = (auth.storage.boxes[box].node as Node3D).global_position
		var o: Vector3 = RuinTower.last_origin
		var out := Vector3(at.x - o.x, 0, at.z - o.z).normalized()
		await _teleport(dwarf, _floor(at + out * 4.5 + out.cross(Vector3.UP) * 3.0), at + Vector3.UP * 0.8 - out.cross(Vector3.UP) * 2.0)
		await _shot("01_rebuild_chest")
		await _teleport(dwarf, _floor(at + out * 2.0), at + Vector3.UP * 0.4)
		_main.hud.open_box(box)
		await _wait(0.8)
		await _shot("02_rebuild_chest_open")
		print("CAVECHECK chest text: ", auth.builder.ruin_intro(box).replace("\n", " | "))
		_main.hud.box_panel.visible = false
		_main.hud._bag_panel.visible = false
		Controls.set_captured(true)
	# F405: Root Trees in the starting cave
	var first: Dictionary = maker.rooms[0]
	var fc: Vector3 = first.center
	var trees: Array = _main._pillars.trunks().filter(func(t): return Vector2(t.p.x - fc.x, t.p.z - fc.z).length() < maxf(first.radii.x, first.radii.z) * 1.1)
	print("CAVECHECK root trees in the starting cave: ", trees.size())
	if trees.size() >= 2:
		var t0: Vector3 = trees[0].p
		var t1: Vector3 = trees[1].p
		var mid: Vector3 = (t0 + t1) * 0.5
		var across: Vector3 = t1 - t0
		across.y = 0
		var side: Vector3 = across.normalized().cross(Vector3.UP)
		if maker.sdf_at(mid + side * 14.0) < maker.sdf_at(mid - side * 14.0):
			side = -side
		var stand := _floor(mid + side * (across.length() * 0.6 + 8.0))
		await _teleport(dwarf, stand, mid)
		await _shot("03_root_trees")
	# F404: the floor of the starting cave
	var sp: Vector3 = maker.cavern_spawn
	await _teleport(dwarf, _floor(sp), _floor(sp + Vector3(6, 0, 3)))
	await _shot("04_cave_floor")
	# F404: a wood root in a tunnel
	var root := {}
	var best := INF
	for s in auth.glow._spots.values():
		if s.kind == GlowPlacer.ROOT and s.get("extra", false) and not CaveLife.in_cave(maker, s.pos):
			var d: float = (s.pos as Vector3).distance_to(sp)
			if d < best:
				best = d
				root = s
	if not root.is_empty():
		var rp: Vector3 = root.pos
		var stand := _open_spot_near(rp, 3.5)
		await _teleport(dwarf, stand, rp + Vector3.UP * 0.6)
		await _shot("05_tunnel_root")
	# F404: a boulder by a wall
	var rocks: Array = _main._boulders._rocks
	var near_b := {}
	best = INF
	for r in rocks:
		if not r.get("broken", false) and (r.pos as Vector3).distance_to(sp) < best:
			best = (r.pos as Vector3).distance_to(sp)
			near_b = r
	print("CAVECHECK boulders in the world: ", rocks.size())
	if not near_b.is_empty():
		var bp := Boulders.middle(near_b)
		await _teleport(dwarf, _open_spot_near(bp, 4.0 + float(near_b.scale)), bp)
		await _shot("06_boulder")
	# F413: a root on a rock bridge (the nearest one)
	var broot := {}
	best = INF
	for s in auth.glow._spots.values():
		if s.get("bridge", false) and not s.get("hidden", false) and (s.pos as Vector3).distance_to(sp) < best:
			best = (s.pos as Vector3).distance_to(sp)
			broot = s
	print("CAVECHECK bridge root: ", broot.get("pos", "none"))
	if not broot.is_empty():
		var bp2: Vector3 = broot.pos
		await _teleport(dwarf, _open_spot_near(bp2, 4.0), bp2 + Vector3.UP * 0.6)
		await _shot("06b_bridge_root")
	# F406: a crystal mined and growing back
	var cr := {}
	best = INF
	for s in auth.glow._spots.values():
		if String(s.kind).begins_with("crystal") and (s.pos as Vector3).distance_to(sp) < best and s.normal.y > 0.5:
			best = (s.pos as Vector3).distance_to(sp)
			cr = s
	if not cr.is_empty():
		var cp: Vector3 = cr.pos
		await _teleport(dwarf, _open_spot_near(cp, 2.5), cp)
		await _shot("07a_crystal")
		var id: int = cr.id
		auth._host_remove_glow(cr)
		print("CAVECHECK crystal mined, grows back in ", auth.regrow.get(id, -1.0), " s")
		await _wait(1.0)
		await _shot("07b_crystal_mined")
		auth.regrow[id] = 0.2  # (fast-forward the 90 minutes)
		await _wait(5.5)
		print("CAVECHECK crystal back: ", auth.glow._spots.has(id))
		await _shot("07c_crystal_grown_back")
	# F407: a swarm, and how high it stays over the floor
	var sws: Node = _main.get_node_or_null("GlowSwarms")
	if sws and not sws._swarms.is_empty():
		var sw: Dictionary = sws._swarms[0]
		var low := INF
		var head: Vector3 = sw.head
		await _teleport(dwarf, _floor(maker.rooms[0].center), head)  # (from the cave's middle: far enough that it doesn't flee)
		var inside := 0
		for i in 400:  # 20 s of flying, following it
			await _wait(0.05)
			head = sw.head
			if maker.sdf_at(head) < 0.0:
				inside += 1
				if inside <= 6 or inside % 10 == 0:
					print("CAVECHECK inside: head %s  cave rock %.2f  real rock %.2f  from tower %.1f m  leaving=%s fade=%.2f lift=%.2f sm_floor=%s" % [head,
						maker.sdf_at(head), _main.world.sdf_at(head), Vector2(head.x - RuinTower.last_origin.x, head.z - RuinTower.last_origin.z).length(),
						sw.get("leaving", false), float(sw.get("fade", 1.0)), float(sw.get("lift", 0.0)), sw.get("sm_floor", "-")])
			var fy: float = sws._floor_under(head)
			if fy > -INF:
				low = minf(low, head.y - fy)
			if i == 100:
				var dir := head - (dwarf.global_position + Vector3.UP * 1.5)
				dwarf._yaw = atan2(-dir.x, -dir.z)
				dwarf._pitch = clampf(atan2(dir.y, Vector2(dir.x, dir.z).length()), -1.2, 1.0)
				await _shot("08_swarm")
		print("CAVECHECK swarm lowest over the floor in 20 s: %.2f m; moments inside rock: %d of 400" % [low, inside])
	get_tree().quit()


func _floor(p: Vector3) -> Vector3:
	return _main.world.maker.find_floor(p.x, p.z, p.y + 3.0) + Vector3.UP * 0.2


## A floor spot about `dist` from p with open air (tries 12 directions).
func _open_spot_near(p: Vector3, dist: float) -> Vector3:
	var maker: CaveMaker = _main.world.maker
	for k in 12:
		var a := k * TAU / 12.0
		var q := p + Vector3(cos(a), 0, sin(a)) * dist
		var f := maker.find_floor(q.x, q.z, p.y + 2.0)
		if maker.sdf_at(f + Vector3.UP * 1.0) > 0.5 and maker.sdf_at(f + Vector3.UP * 1.8) > 0.5 and absf(f.y - p.y) < 4.0:
			return f + Vector3.UP * 0.2
	return _floor(p + Vector3(dist, 0, 0))


func _teleport(dwarf: Dwarf, to: Vector3, look_at: Vector3) -> void:
	dwarf.set_physics_process(false)
	dwarf.global_position = to
	for i in 400:
		if _main.world.terrain.is_area_meshed(AABB(to - Vector3.ONE * 6, Vector3.ONE * 12)):
			break
		await get_tree().process_frame
	var dir := look_at - (to + Vector3.UP * 1.5)
	dwarf._yaw = atan2(-dir.x, -dir.z)
	dwarf._pitch = clampf(atan2(dir.y, Vector2(dir.x, dir.z).length()), -1.2, 1.0)
	dwarf.model.rotation.y = dwarf._yaw
	await _wait(1.5)
