extends Node
## Build check: puts every building piece in each Mossy material in rows, and each ready-made
## blueprint, then takes pictures (building polish spec §8).
## Run:  godot --audio-driver Dummy --path . -- buildcheck seed=42 shots=/some/folder

var _main: Node
var _shots := "user://buildcheck"
var _uid := 900000


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
	_main.take_screenshot(_shots.path_join(name + ".png"))


func _place(piece: String, family: String, pos: Vector3, rot: int) -> void:
	_main.authority.builder._ev_add_piece(_uid, piece, family, pos, rot, true)
	_uid += 1


## Takes down everything this robot built.
func _clear() -> void:
	var b: Builder = _main.authority.builder
	for uid in b.structure.pieces.keys():
		if int(uid) >= 900000:
			b._ev_remove_piece(uid)


func _look(dwarf: Dwarf, from: Vector3, at: Vector3) -> void:
	dwarf.set_physics_process(false)
	dwarf.global_position = from
	var d := at - (from + Vector3.UP * 1.5)
	dwarf._yaw = atan2(-d.x, -d.z)
	dwarf._pitch = clampf(atan2(d.y, Vector2(d.x, d.z).length()), -1.2, 1.0)
	dwarf.model.rotation.y = dwarf._yaw


func _run() -> void:
	var waited := 0.0
	while not _main.is_ready_to_play() and waited < 90.0:
		await _wait(0.25)
		waited += 0.25
	var dwarf: Dwarf = _main.dwarf
	Controls.set_captured(true)
	_main.hud.set_paused(false)
	_main.hud.visible = false
	dwarf._zoom = 3.0
	# Build up in the air above the start, on a big stone foundation, so the cave doesn't get in the way.
	var base := (_main.world.maker.cavern_spawn as Vector3).round() + Vector3(0, 3, 0)
	# A work light for the photos (only in this robot run), following the camera's target.
	var lamp := OmniLight3D.new()
	lamp.omni_range = 18.0
	lamp.light_energy = 2.5
	lamp.shadow_enabled = true
	add_child(lamp)
	var n := 0
	var only := ""
	var only_group := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("family="):
			only = arg.trim_prefix("family=")
		if arg.begins_with("group="):
			only_group = arg.trim_prefix("group=")
		if arg == "nomodels":
			PieceNode.use_models = false
		if arg == "part=house":
			await _house(dwarf, base, lamp)
			get_tree().quit()
			return
		if arg == "part=edges":
			await _edges(dwarf, base, lamp)
			get_tree().quit()
			return
		if arg == "part=stacked":
			await _stacked(dwarf, base, lamp)
			get_tree().quit()
			return
		if arg == "part=extras":
			await _extras(dwarf, base, lamp)
			get_tree().quit()
			return
	# Six pieces at a time, 3.5 m apart, photographed from 7 m; built where the last batch was
	# (each batch is cleared first), so they never run into the cave walls.
	var only_blueprints := OS.get_cmdline_user_args().has("part=blueprints")
	for fam in Pieces.MOSSY_FAMILIES:
		if only_blueprints or (only != "" and fam != only):
			continue
		var batch: Array = []
		for id in Pieces.LIST:
			if Pieces.allowed(id, fam) and Pieces.needed_level(id, fam) < 99 					and (only_group == "" or Pieces.LIST[id].get("group", "") == only_group):
				batch.append(id)
		var i := 0
		while i < batch.size():
			_clear()
			for k in 6:
				if i + k >= batch.size():
					break
				var p := base + Vector3((k - 2.5) * 3.5, 0, 0)
				_place("foundation", "cut_stone", p + Vector3(0, -1, 0), 0)
				_place("foundation", "cut_stone", p + Vector3(0, -1, -2), 0)
				_place(batch[i + k], fam, p, 0)
			await _wait(0.6)
			lamp.global_position = base + Vector3(-4, 6, 6)
			_look(dwarf, base + Vector3(0, 1.5, 7.5), base + Vector3(0, 1.0, 0))
			dwarf._zoom = 5.0
			await _wait(0.8)
			await _shot("%02d_%s_%s" % [n, fam, batch[i]])
			n += 1
			i += 6
	_clear()
	if only_group != "":
		get_tree().quit()
		return
	# The blueprints, side by side further along.
	var bx := base + Vector3(0, 0, 20)
	for id in BlueprintLibrary.IDS:
		var bp := BlueprintLibrary.make(id)
		for p in bp.world_pieces(bx, 0):
			_place(p.piece, p.family, p.pos, p.rot)
		await _wait(0.8)
		lamp.global_position = bx + Vector3(6, 9, 10)
		_look(dwarf, bx + Vector3(7, 4, 12), bx + Vector3(0, 2, 0))
		dwarf._zoom = 6.0
		await _wait(1.0)
		await _shot("%02d_blueprint_%s" % [n, id])
		# From above, to see the furniture inside (the lamp goes in the middle).
		lamp.global_position = bx + Vector3(0, 2.2, 0)
		_look(dwarf, bx + Vector3(0.5, 9.0, 3.0), bx + Vector3(0, 0, -0.5))
		dwarf._zoom = 1.0
		dwarf.visible = false
		await _wait(0.8)
		await _shot("%02d_blueprint_%s_inside" % [n, id])
		dwarf.visible = true
		n += 1
		bx += Vector3(16, 0, 0)
	get_tree().quit()


## `part=extras`: a door (closed, then open), a built ladder, the Kiln and Smelter, and three Ore Crates
## (empty, half, full) to check the ore pile rises.
func _extras(dwarf: Dwarf, base: Vector3, lamp: OmniLight3D) -> void:
	var auth: GameAuthority = _main.authority
	for x in range(-3, 4):
		for z in range(-2, 2):
			_place("foundation", "cut_stone", base + Vector3(x * 2, -1, z * 2), 0)
	_place("doorway", "plank_root", base + Vector3(-4, 0, -1), 0)
	_place("door", "plank_root", base + Vector3(-4, 0, -1), 0)
	var door_uid := _uid - 1
	_place("wall", "plank_root", base + Vector3(-2, 0, -1), 0)
	_place("ladder", "plank_root", base + Vector3(-2, 0, -0.75), 0)
	auth._ev_place_station(990001, "kiln", base + Vector3(1, 0, -1), 0.0)
	auth._ev_place_station(990002, "smelter", base + Vector3(3, 0, -1), 0.0)
	var fills := [0, 150, 500]
	for i in 3:
		var id: int = auth.storage.create_box("crate_ore", base + Vector3(0.5 + i * 1.6, 0, 1.5), 0.0)
		if fills[i] > 0:
			auth.storage.put(id, "copper_ore", fills[i])
	await _wait(0.8)
	lamp.global_position = base + Vector3(0, 5, 5)
	_look(dwarf, base + Vector3(0, 1.8, 6.5), base + Vector3(0, 0.7, 0))
	dwarf._zoom = 5.0
	await _wait(1.0)
	await _shot("extras_closed")
	auth.builder._ev_door(door_uid, 1)
	await _wait(0.8)
	await _shot("extras_door_open")
	_look(dwarf, base + Vector3(2.4, 1.2, 4.0), base + Vector3(2.0, 0.2, 1.5))
	dwarf._zoom = 2.5
	await _wait(0.8)
	await _shot("extras_crates")


## `part=edges` (feedback F58/F59/F76): in each style a doorway built next to a wall (like a real house) and
## one doorway on its own (its open ends show), photographed close up from several angles, lit by a small
## warm lamp by the camera (like the lantern). Two shots 2° apart at each angle: shimmer shows as stripes
## that change between them. `norim` turns the shader's rim light off, to compare.
## `part=stacked` (F833): in each style a wall, then a wall, window and doorway a storey (2.25 m) up with no floor
## between (the Prow Hall's tall hall), and a stone wall on a wood one. The 25 cm slit should show a beam.
func _stacked(dwarf: Dwarf, base: Vector3, lamp: OmniLight3D) -> void:
	var rows := [["plank_root", "plank_root"], ["cut_stone", "cut_stone"], ["clay_brick", "clay_brick"], ["plank_root", "cut_stone"]]
	for i in rows.size():
		var row := base + Vector3(0, 0, -i * 5.0)
		for k in 3:
			var x := (k - 1) * 2.0
			_place("foundation", "cut_stone", row + Vector3(x, -1, 0), 0)
			_place("wall", rows[i][0], row + Vector3(x, 0, -1), 0)
			_place(["wall", "window_wall", "doorway"][k], rows[i][1], row + Vector3(x, 2.25, -1), 0)
	await _wait(0.8)
	dwarf.visible = false
	for i in rows.size():
		var at := base + Vector3(0, 2.1, -i * 5.0 - 1)
		var from := at + Vector3(1.5, 0.3, 4.5)
		_look(dwarf, from - Vector3.UP * 1.5, at)
		dwarf._zoom = 0.0
		lamp.global_position = from + Vector3(0.4, 0.3, 0)
		await _wait(0.5)
		await _shot("stacked_%s_%s" % rows[i])


func _edges(dwarf: Dwarf, base: Vector3, lamp: OmniLight3D) -> void:
	var fams := ["cut_stone", "clay_brick", "plank_root"]
	for i in fams.size():
		var row := base + Vector3(0, 0, -i * 4.0)
		for x in [-4.0, 0.0, 2.0]:
			_place("foundation", fams[i] if fams[i] != "plank_root" else "cut_stone", row + Vector3(x, -1, 0), 0)
		_place("doorway", fams[i], row + Vector3(-4.0, 0, 0), 0)  # on its own
		_place("wall", fams[i], row, 0)
		_place("doorway", fams[i], row + Vector3(2.0, 0, 0), 0)  # beside the wall
	await _wait(0.8)
	if OS.get_cmdline_user_args().has("norim"):
		for m in Look._cache.values():
			if m is ShaderMaterial:
				(m as ShaderMaterial).set_shader_parameter("rim", 0.0)
	dwarf.visible = false
	lamp.light_color = Color(1.0, 0.75, 0.45)
	lamp.omni_range = 9.0
	lamp.light_energy = 1.6
	for row in 3:
		for view in [[2.0, 0.0], [2.0, 40.0], [1.0, -60.0], [-4.0, 75.0], [-4.0, -110.0]]:
			for wiggle in [0.0, 2.0]:
				var a := deg_to_rad(view[1] + wiggle)
				var at := base + Vector3(view[0], 1.1, -row * 4.0)
				var from := at + Vector3(sin(a) * 2.6, 0.4, cos(a) * 2.6)
				_look(dwarf, from - Vector3.UP * 1.5, at)
				dwarf._zoom = 0.0
				lamp.global_position = from + Vector3(0.4, 0.3, 0)
				await _wait(0.4)
				await _shot("edges_%s_%+04d%s" % [fams[row], int(view[1]), "b" if wiggle > 0.0 else ""])


# ================================================================== part=house (owner's test list, Nov 15)

var _report: Array[String] = []


## Places a piece where the hammer would put it: aiming at `aim` (normal `n`) on the built piece `on_uid`
## (or open ground when -1). Returns the new uid, or -1 if it didn't fit.
func _snap_place(piece: String, fam: String, aim: Vector3, n: Vector3, on_uid: int, rot: int = 0, anchored: bool = true) -> int:
	var b: Builder = _main.authority.builder
	var anchor := AABB()
	var ap := {}
	if on_uid >= 0:
		anchor = b.structure.box_of(on_uid)
		ap = b.structure.pieces[on_uid]
	var t := Pieces.snap(piece, aim, n, 0.0, rot, 0.0, anchor, ap)
	if b.structure.overlaps(piece, t.pos, t.rot):
		_report.append("  %s at %s: overlaps something" % [piece, t.pos])
		return -1
	b._ev_add_piece(_uid, piece, fam, t.pos, t.rot, anchored)
	_uid += 1
	return _uid - 1


func _edge_toward(uid: int, dir: Vector3) -> Dictionary:
	var p: Dictionary = _main.authority.builder.structure.pieces[uid]
	var best := {}
	for e in Pieces.edges(p.piece, p.pos, p.rot):
		if best.is_empty() or (e.normal as Vector3).dot(dir) > (best.normal as Vector3).dot(dir):
			best = e
	return best


## Aim at the top of piece `uid`, near its side facing `dir`.
func _top_near(uid: int, dir: Vector3) -> Vector3:
	var p: Dictionary = _main.authority.builder.structure.pieces[uid]
	var e := _edge_toward(uid, dir)
	return (e.mid as Vector3) - (e.normal as Vector3) * 0.3 + Vector3.UP * float(Pieces.LIST[p.piece].size.y)


## Aim at the side of piece `uid` facing `dir`.
func _side_of(uid: int, dir: Vector3) -> Array:
	var e := _edge_toward(uid, dir)
	return [(e.mid as Vector3) + (e.normal as Vector3) * 0.01 + Vector3.UP * 0.3, e.normal]


func _house(dwarf: Dwarf, base: Vector3, lamp: OmniLight3D) -> void:
	var b: Builder = _main.authority.builder
	var S := "cut_stone"
	var W := "plank_root"
	# --- 1. A stone house: 2 × 2 foundations, a 60° triangle on the front and on the right side.
	var f1 := _snap_place("foundation", S, base, Vector3.UP, -1)
	var f2 := _snap_place("foundation", S, _side_of(f1, Vector3.RIGHT)[0], _side_of(f1, Vector3.RIGHT)[1], f1)
	var f3 := _snap_place("foundation", S, _side_of(f1, Vector3.FORWARD)[0], _side_of(f1, Vector3.FORWARD)[1], f1)
	var f4 := _snap_place("foundation", S, _side_of(f2, Vector3.FORWARD)[0], _side_of(f2, Vector3.FORWARD)[1], f2)
	var t1 := _snap_place("foundation_triangle", S, _side_of(f1, Vector3.BACK)[0], _side_of(f1, Vector3.BACK)[1], f1)
	var t2 := _snap_place("foundation_triangle", S, _side_of(f2, Vector3.RIGHT)[0], _side_of(f2, Vector3.RIGHT)[1], f2)
	# Walls on the outside sides: squares get walls, the triangles get walls on their two free sides.
	var walls := 0
	for pair in [[f3, Vector3.FORWARD], [f4, Vector3.FORWARD], [f3, Vector3.LEFT], [f1, Vector3.LEFT], [f4, Vector3.RIGHT]]:
		if _snap_place("wall", W, _top_near(pair[0], pair[1]), Vector3.UP, pair[0], 0, false) >= 0:
			walls += 1
	# The doorway on the right foundation's front... the front triangle gets the round doorway + door.
	var tri_sides := 0
	for tri in [t1, t2]:
		var p: Dictionary = b.structure.pieces[tri]
		for e in Pieces.edges(p.piece, p.pos, p.rot):
			var shared := false
			for sq in [f1, f2]:
				var sp: Dictionary = b.structure.pieces[sq]
				for se in Pieces.edges(sp.piece, sp.pos, sp.rot):
					shared = shared or (se.mid as Vector3).distance_to(e.mid) < 0.02
			if shared:
				continue
			var id := "doorway" if tri == t1 and tri_sides == 0 else "wall"
			var aim: Vector3 = (e.mid as Vector3) - (e.normal as Vector3) * 0.3 + Vector3.UP * 1.0
			var w := _snap_place(id, S if id == "doorway" else W, aim, Vector3.UP, tri, 0, false)
			if w >= 0:
				tri_sides += 1
				if id == "doorway":
					var wp: Dictionary = b.structure.pieces[w]
					b._ev_add_piece(_uid, "door", W, wp.pos, wp.rot, false)
					_uid += 1
	_report.append("house: %d square walls, %d walls/doorway on 60° triangle sides" % [walls, tri_sides])
	# Stairs up the back (left) onto the foundations, and a gentle roof on the right.
	var hexc := base + Vector3(10, 0, 0)
	# --- 2. A hexagon tower base: 6 triangle foundations around a point, walls on the outside.
	var first := _snap_place("foundation_triangle", S, hexc + Vector3(0, 0, -Pieces.TRI_OUT), Vector3.UP, -1, 6)
	var ring := [first]
	var fpc: Dictionary = b.structure.pieces[first]
	var tip := Pieces.footprint(fpc.piece, fpc.pos, fpc.rot)[0]
	for q in Pieces.footprint(fpc.piece, fpc.pos, fpc.rot):
		if q.distance_to(Vector2(hexc.x, hexc.z)) < tip.distance_to(Vector2(hexc.x, hexc.z)):
			tip = q
	hexc = Vector3(tip.x, hexc.y, tip.y)  # the hexagon's middle is this triangle's point
	for i in 5:
		var last: int = ring[-1]
		var lp: Dictionary = b.structure.pieces[last]
		var placed := -1
		for e in Pieces.edges(lp.piece, lp.pos, lp.rot):
			var c := Vector3(hexc.x, lp.pos.y, hexc.z)
			if absf((e.mid as Vector3).distance_to(c) - 1.0) > 0.05:
				continue
			var t := Pieces.snap("foundation_triangle", (e.mid as Vector3) + (e.normal as Vector3) * 0.01 + Vector3.UP * 0.3, e.normal, 0.0, 0, 0.0, b.structure.box_of(last), lp)
			if not b.structure.overlaps("foundation_triangle", t.pos, t.rot):
				b._ev_add_piece(_uid, "foundation_triangle", S, t.pos, t.rot, true)
				placed = _uid
				_uid += 1
				break
		if placed < 0:
			_report.append("  hexagon: triangle %d didn't fit" % (i + 2))
			break
		ring.append(placed)
	var hex_walls := 0
	for tri in ring:
		var p: Dictionary = b.structure.pieces[tri]
		for e in Pieces.edges(p.piece, p.pos, p.rot):
			if (e.mid as Vector3).distance_to(Vector3(hexc.x, p.pos.y, hexc.z)) > 1.5:  # the outer side
				if _snap_place("wall", S, (e.mid as Vector3) - (e.normal as Vector3) * 0.3 + Vector3.UP * 1.0, Vector3.UP, tri, 0, false) >= 0:
					hex_walls += 1
	_report.append("hexagon: %d triangles, %d outer walls" % [ring.size(), hex_walls])
	await _wait(1.0)
	lamp.global_position = base + Vector3(4, 8, 8)
	lamp.omni_range = 30.0
	_look(dwarf, base + Vector3(5, 5.5, 11), base + Vector3(4, 1, -1))
	dwarf._zoom = 7.0
	await _wait(0.8)
	await _shot("house_01_overview")
	_look(dwarf, base + Vector3(-1.5, 2.6, 4.5), base + Vector3(0.5, 0.6, 1.5))
	dwarf._zoom = 1.5
	lamp.global_position = base + Vector3(0, 4, 5)
	await _wait(0.6)
	await _shot("house_02_triangle_doorway_closeup")
	_look(dwarf, hexc + Vector3(0.3, 9, 2.5), hexc)
	dwarf._zoom = 1.0
	lamp.global_position = hexc + Vector3(0, 6, 0)
	await _wait(0.6)
	await _shot("house_03_hexagon_from_above")
	# --- 3. The real dwarf walks up stairs onto a 2 m platform, then up a roof.
	var wc := base + Vector3(-12, 0, 0)
	_snap_place("stairs", S, wc, Vector3.UP, -1)
	for z in [2.0, 4.0]:  # ground to start from (we're building up in the air)
		b._ev_add_piece(_uid, "foundation", S, b.structure.pieces[_uid - 1].pos + Vector3(0, -1, z), 0, true)
		_uid += 1
	var p1 := _snap_place("foundation", S, wc + Vector3(0, 0, -2), Vector3.UP, -1)
	b._ev_add_piece(_uid, "foundation", S, b.structure.pieces[p1].pos + Vector3.UP, 0, true)
	var p2 := _uid
	_uid += 1
	b._ev_add_piece(_uid, "roof_26", W, b.structure.pieces[p2].pos + Vector3(0, 1.0, -2), 0, true)
	_uid += 1
	b._ev_add_piece(_uid, "foundation", S, b.structure.pieces[p2].pos + Vector3(0, 0, -2), 0, true)
	_uid += 1
	await _wait(0.5)
	dwarf.visible = true
	dwarf.set_physics_process(true)
	dwarf.global_position = wc + Vector3(0, 0.1, 3.0)
	dwarf.velocity = Vector3.ZERO
	dwarf._yaw = 0.0  # facing −z, up the stairs
	dwarf._pitch = -0.25
	dwarf._zoom = 4.0
	lamp.global_position = wc + Vector3(2, 6, 1)
	Input.action_press("move_forward")
	var heights := []
	var roof_back: float = wc.z - 2.0 - 1.0 - 2.0 + 0.5  # stairs, platform, roof; stop near its top edge
	for i in 60:
		await _wait(0.05)
		heights.append(dwarf.global_position.y - wc.y)
		if i == 14:
			await _shot("house_04_dwarf_on_stairs")
		if dwarf.global_position.z < roof_back:
			break
	Input.action_release("move_forward")
	await _wait(0.4)
	var top := dwarf.global_position.y - wc.y
	_report.append("walk: up the stairs and the roof, ended %.2f m up (roof top is 3.0 m), highest %.2f m" % [top, heights.max()])
	await _shot("house_05_dwarf_on_roof")
	dwarf.set_physics_process(false)
	# --- 4. Taking supports away: a wooden floor on two pillars, with a wall on it.
	var sc := base + Vector3(-12, 0, 12)
	var fa := _snap_place("foundation", S, sc, Vector3.UP, -1)
	var fb := _snap_place("foundation", S, _side_of(fa, Vector3.RIGHT)[0], _side_of(fa, Vector3.RIGHT)[1], fa)
	var fa_top: float = b.structure.pieces[fa].pos.y + 1.0
	var fa_c: Vector3 = b.structure.pieces[fa].pos
	var pil_a := _snap_place("pillar", W, fa_c + Vector3(-0.8, 1.0, -0.8), Vector3.UP, fa, 0, false)
	var pil_b := _snap_place("pillar", W, fa_c + Vector3(0.8, 1.0, 0.8), Vector3.UP, fa, 0, false)
	b._ev_add_piece(_uid, "floor", W, Vector3(fa_c.x, fa_top + 2.0, fa_c.z), 0, false)
	var deck := _uid
	_uid += 1
	b._ev_add_piece(_uid, "wall", W, b.structure.pieces[deck].pos + Vector3(0, 0.25, -1.0), 0, false)
	var deck_wall := _uid
	_uid += 1
	var steady := b.structure.recompute().is_empty()
	_report.append("deck on two pillars: everything steady %s (deck %.0f%%)" % [steady, b.structure.pieces[deck].stability * 100.0])
	await _wait(0.5)
	_look(dwarf, sc + Vector3(1, 3.2, 7.5), sc + Vector3(1, 2.0, 0))
	dwarf._zoom = 3.0
	dwarf.visible = false
	lamp.global_position = sc + Vector3(1, 6, 5)
	await _wait(0.5)
	await _shot("house_06_deck_on_two_pillars")
	b._ev_remove_piece(pil_a)
	await _wait(2.6)
	var after_one := b.structure.pieces.has(deck) and b.structure.pieces.has(deck_wall)
	await _shot("house_07_one_pillar_removed")
	b._ev_remove_piece(pil_b)
	await _wait(0.8)
	await _shot("house_08_last_pillar_removed_shaking")
	await _wait(2.0)
	await _shot("house_09_collapsed")
	var gone := not b.structure.pieces.has(deck) and not b.structure.pieces.has(deck_wall)
	_report.append("supports: one pillar out -> deck stands %s; both out -> deck and wall fell %s; foundations stay %s" % [after_one, gone,
		b.structure.pieces.has(fa) and b.structure.pieces.has(fb)])
	print("===== HOUSE CHECK =====")
	for line in _report:
		print("  ", line)
	print("=======================")
