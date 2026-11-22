class_name BuildMode
extends Node3D
## Build mode: active while the Build Hammer is in your hand.
##   Left click  = place the piece (the ghost shows where; green = OK, red = not allowed)
##   Right click = take down the piece you aim at (you get everything back)
##   Q / E = turn left / right (walking never turns it: owner, Nov 19) · Shift + mouse wheel (or PageUp / PageDown) = lift up / down · B = choose piece and material

signal changed  ## piece/material/rotation changed (the HUD shows it)
signal message(text: String)  ## something to tell the player (blueprint saved, etc.)

var dwarf: Dwarf
var piece := "floor"
var family := "plank_root"
var rot := 0
var lift := 0.0
var problem := ""  ## why the ghost is red ("" = it's fine)
var target := {}  ## {pos, rot} where the piece would go
var aimed_uid := -1  ## the built piece under the crosshair (-1 = none), for the "how steady is it" line
var _ghost: PieceNode
var blueprint: Blueprint = null  ## not null = placing a whole blueprint
var _bp_json := ""
var _bp_ghosts: Node3D
var _bp_origin := Vector3.INF
var _bp_chest := Vector3.INF  ## where its Builder's Chest will appear (INF = no room)
var _bp_chest_ghost: MeshInstance3D
var capture_corner := Vector3.INF  ## first corner while saving a blueprint (C)
var lessons := BuildLessons.new()  ## step-by-step hammer lessons (F579), ticked off as you do them


func _ready() -> void:
	_ghost = preload("res://src/build/piece_node.gd").new()
	_ghost.ghost = true
	_ghost.piece = piece
	_ghost.family = family
	add_child(_ghost)
	_ghost.visible = false


func active() -> bool:
	var auth := GameAuthority.instance
	if auth == null or dwarf == null:
		return false
	if dev_place and blueprint:  # placing a blueprint from the dev menu (P): no hammer needed
		return true
	var ps := auth.get_player(dwarf.peer_id)
	return ps != null and ps.selected_item() == "build_hammer"


func choose(p_piece: String, p_family: String) -> void:
	if blueprint:  # picking a piece in the B menu always goes back to single pieces (F101)
		stop_blueprint()
		message.emit("Back to building single pieces.")
	if _turn_unit(p_piece) != _turn_unit(piece):  # keep facing the same way: 5° (furniture), 30° (triangles) or 90° steps
		var u := _turn_unit(p_piece)
		rot = posmod(roundi(float(rot * _turn_unit(piece)) / u), Pieces.FREE_STEPS / u)
	_learn("choose")
	piece = p_piece
	family = p_family if Pieces.allowed(p_piece, p_family) else Pieces.LIST[p_piece].get("families", [p_family])[0]
	_ghost.rebuild(piece, family)
	changed.emit()


var dev_place := false  ## this blueprint came from the dev menu (P)


## Pick a blueprint from the book: its ghost follows your aim until you click. `dev` = from the dev menu.
func start_blueprint(json: String, dev: bool = false) -> void:
	var r := Blueprint.from_json(json)
	if not r.ok:
		message.emit(r.error)
		return
	stop_blueprint()
	dev_place = dev and DevMenu.enabled()
	blueprint = r.blueprint
	_bp_json = json
	_bp_ghosts = Node3D.new()
	add_child(_bp_ghosts)
	for p in blueprint.pieces:
		var g: PieceNode = preload("res://src/build/piece_node.gd").new()
		g.ghost = true
		g.piece = p.id
		g.family = p.mat
		_bp_ghosts.add_child(g)
	# A see-through chest shows where the Builder's Chest will appear.
	_bp_chest_ghost = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.0, 0.7, 0.6)
	_bp_chest_ghost.mesh = bm
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.8, 0.3, 0.45)
	_bp_chest_ghost.material_override = m
	_bp_chest_ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_bp_ghosts.add_child(_bp_chest_ghost)
	message.emit("Placing blueprint \"%s\" (blue = a build site that fills in as you add materials): aim, Q / E to turn, left click to place, right click or B to go back to single pieces" % blueprint.name)


func stop_blueprint() -> void:
	blueprint = null
	dev_place = false
	if _bp_ghosts:
		_bp_ghosts.queue_free()
		_bp_ghosts = null


var _tint_on := false
var _tint_version := -1
var _tint_timer := 0.0


## Hammer out: only SHAKY pieces glow faintly, yellow or red, as a "this might fall" warning. Strong and good pieces
## don't glow at all (F567, said 3×: the strong colour was blue, so a rebuilt tower turned all blue with the hammer).
## Aim at any piece to read how steady it is (the HUD line).
static func warning_tint(stability: float) -> Color:
	return Structure.strength_color(stability) if stability < 0.5 else Color(0, 0, 0, 0)


func _update_tints(delta: float, on: bool) -> void:
	var auth := GameAuthority.instance
	if auth == null or auth.builder == null:
		return
	var b: Builder = auth.builder
	if not on:
		if _tint_on:
			for uid in b.nodes:
				(b.nodes[uid] as PieceNode).set_tint(Color(0, 0, 0, 0))
			_tint_on = false
		return
	_tint_timer -= delta
	if _tint_on and _tint_timer > 0.0 and _tint_version == b.structure.version:
		return
	_tint_timer = 0.5
	if not auth.is_host():
		b.structure.recompute()  # friends work out the steadiness themselves (the host does it anyway)
	_tint_version = b.structure.version
	for uid in b.nodes:
		if b.structure.pieces.has(uid):
			(b.nodes[uid] as PieceNode).set_tint(warning_tint(b.structure.pieces[uid].stability))
	_tint_on = true


var work_site := -1  ## the build site you're working on (by its chest, hammer in hand), or -1
var _work_t := 0.0


## Hammer in hand by a Builder's Chest: the dwarf hammers away and the site builds (owner, Nov 16).
## Walk away or put the hammer down to stop; come back to carry on.
func _update_work(delta: float) -> void:
	var auth := GameAuthority.instance
	work_site = -1
	if auth == null or dwarf == null or blueprint or not active():
		return
	var site := auth.builder.work_site_for(dwarf.global_position)
	if site < 0 or auth.builder.site_progress(site) >= 1.0:
		return
	work_site = site
	_work_t -= delta
	if _work_t <= 0.0:
		_work_t = 1.0
		dwarf.model.work(0.9)


## Q (dir +1, left) or E (dir -1, right). Pieces turn a quarter, triangles 30°: they stay on the grid so walls always
## line up (owner, Nov 19). Holding the key keeps turning, one step at a time at one calm pace (like the stations, F397).
const HOLD_DELAY := 0.35  ## seconds held before it starts repeating (so a tap stays one step)
const REPEAT := 0.4  ## then one step every this many seconds, never faster
var _hold_dir := 0
var _hold_time := 0.0


## Ticks off a hammer lesson the first time you do it (F579), with a little "well done".
func _learn(id: String) -> void:
	if lessons.mark(id):
		message.emit("✓ Got it!" if not lessons.all_done() else "✓ You know the hammer now! The keys stay on the right in one short line.")


func turn(dir: int) -> void:
	_step(dir)
	_hold_dir = dir
	_hold_time = 0.0


func _step(dir: int) -> void:
	_learn("turn")
	rot = posmod(rot + dir, 4 if blueprint else Pieces.FREE_STEPS / _turn_unit(piece))
	changed.emit()


## One Q / E step for this piece, in 5° steps: furniture 5° (like the stations, F726), triangles 30°, the rest 90°.
static func _turn_unit(p: String) -> int:
	return 1 if Pieces.turns_freely(p) else (6 if Pieces.is_tri(p) else 18)


## Furniture held down turns smoothly at the stations' calm speed (60° a second, F397), not in 0.4 s steps.
const FREE_HOLD_DELAY := PlaceGhost.HOLD_DELAY
const FREE_REPEAT := 1.0 / 12.0


## How many extra steps holding the key adds between `before` and `after` seconds held.
static func held_steps(before: float, after: float, delay: float = HOLD_DELAY, every: float = REPEAT) -> int:
	var n := func(t: float) -> int: return 0 if t < delay else floori((t - delay) / every) + 1
	return n.call(after) - n.call(before)


func _keep_turning(delta: float) -> void:
	if _hold_dir == 0:
		return
	# E is also "open / use": main.gd only starts an E turn when nothing is aimed at to open.
	if not active() or not Input.is_action_pressed("rotate_piece" if _hold_dir > 0 else "interact"):
		_hold_dir = 0
		return
	var before := _hold_time
	_hold_time += delta
	var fine := Pieces.turns_freely(piece) and not blueprint
	for i in (held_steps(before, _hold_time, FREE_HOLD_DELAY, FREE_REPEAT) if fine else held_steps(before, _hold_time)):
		_step(_hold_dir)


var _was_active := false
var level := {cut = [], fill = [], fill_ground = [], steep = false}  ## how the aimed piece would level the ground (F159)
var _fill_boxes: Array[MeshInstance3D] = []
var _fill_mat: StandardMaterial3D


## F159: see-through packed-dirt blocks under the ghost where it would fill a dip.
func _show_fill(plan: Dictionary) -> void:
	if _fill_mat == null:
		_fill_mat = StandardMaterial3D.new()
		_fill_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_fill_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_fill_mat.albedo_color = Color(0.62, 0.45, 0.27, 0.45)
	var fills: Array = plan.get("fill", [])
	while _fill_boxes.size() < fills.size():
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.96, 1.0, 0.96)
		mi.mesh = bm
		mi.material_override = _fill_mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_fill_boxes.append(mi)
	for i in _fill_boxes.size():
		var mi := _fill_boxes[i]
		mi.visible = i < fills.size()
		if mi.visible:
			var top: Vector3 = fills[i]
			var depth := maxf(0.1, top.y - float(plan.fill_ground[i]))
			mi.global_position = top - Vector3.UP * depth * 0.5
			mi.scale = Vector3(1.0, depth, 1.0)


## The HUD line: what placing it would do to the ground ("" = nothing).
func level_text() -> String:
	var parts := []
	if not level.get("cut", []).is_empty():
		parts.append("cuts the bump away (you get it back)")
	if not level.get("fill", []).is_empty():
		parts.append("fills %d dips (%d dirt or stone)" % [level.fill.size(), level.fill.size()])
	return "" if parts.is_empty() else "Levels the ground: " + ", ".join(parts)


func _process(delta: float) -> void:
	_update_work(delta)
	_update_tints(delta, active())
	_keep_turning(delta)
	if active() and not _was_active and dwarf:
		# Taking the hammer out: the piece starts facing the way you look, then stays put while you walk (owner,
		# Nov 19: "it turns when you walk"); only Q / E turn it from here.
		var u := _turn_unit(piece)
		rot = posmod(roundi((dwarf.model.rotation.y + PI) / (PI / 36.0 * u)), Pieces.FREE_STEPS / u)
	_was_active = active()
	if not active() or blueprint:
		_show_fill({})
	if not active():
		_ghost.visible = false
		if _bp_ghosts:
			_bp_ghosts.visible = false
		return
	if blueprint:
		_ghost.visible = false
		var bhit := dwarf.aim_far(24.0)
		_bp_ghosts.visible = not bhit.is_empty()
		if bhit.is_empty():
			_bp_origin = Vector3.INF
			return
		_bp_origin = Vector3(roundf(bhit.position.x), snappedf(bhit.position.y, 0.5), roundf(bhit.position.z))
		var placed := blueprint.world_pieces(_bp_origin, rot)
		for i in placed.size():
			var g: Node3D = _bp_ghosts.get_child(i)
			g.global_position = placed[i].pos
			g.rotation.y = Pieces.yaw_of(placed[i].rot)
		var auth_bp := GameAuthority.instance
		_bp_chest = Builder.chest_spot(blueprint.size, _bp_origin, rot, dwarf.global_position, auth_bp.world.sdf_at)
		_bp_chest_ghost.visible = _bp_chest.is_finite()
		if _bp_chest.is_finite():
			_bp_chest_ghost.global_position = _bp_chest + Vector3.UP * 0.35
			_bp_chest_ghost.rotation.y = rot * PI / 2.0
		return
	var hit := dwarf.aim_far(Pieces.BUILD_REACH)
	aimed_uid = -1
	if hit.is_empty():
		_ghost.visible = false
		target = {}
		_show_fill({})
		return
	var auth := GameAuthority.instance
	# Aiming at something already built? Snap to it (its top edge, corner, or side).
	var anchor := AABB()
	var anchor_piece := {}
	var hit_node: Object = hit.get("collider")
	if hit_node is PieceNode and auth.builder.structure.pieces.has((hit_node as PieceNode).uid):
		anchor = auth.builder.structure.box_of((hit_node as PieceNode).uid)
		anchor_piece = auth.builder.structure.pieces[(hit_node as PieceNode).uid]
		aimed_uid = (hit_node as PieceNode).uid
	target = Pieces.snap(piece, hit.position, hit.normal, 0.0, rot, lift, anchor, anchor_piece)
	_ghost.visible = true
	_ghost.global_position = target.pos
	_ghost.rotation = Vector3(0, Pieces.yaw_of(target.rot), 0)
	_ghost.set_legs(Pieces.leg_drops(piece, family, target.pos, target.rot, auth.world.sdf_at))
	problem = auth.builder.problem(auth.get_player(dwarf.peer_id), piece, family, target.pos, target.rot)
	_ghost.set_ghost_ok(problem == "")
	level = auth.builder.last_level.duplicate()
	_show_fill(level)


func _unhandled_input(event: InputEvent) -> void:
	if not active() or not Controls.captured():
		return
	var auth := GameAuthority.instance
	if blueprint:
		if event.is_action_pressed("dig") and _bp_origin != Vector3.INF:
			if not _bp_chest.is_finite():
				message.emit("No room for the Builder's Chest next to it. Turn it (Q / E) or pick a spot with open floor beside it.")
				get_viewport().set_input_as_handled()
				return
			auth.builder.ask_place_blueprint(_bp_json, _bp_origin, rot, _bp_chest)
			message.emit("Blueprint placed. Put materials in its Builder's Chest (E) and it builds itself!")
			stop_blueprint()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("use"):
			stop_blueprint()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("rotate_piece"):
			turn(1)
		return
	if event.is_action_pressed("capture"):
		var chit := dwarf.aim_far(Pieces.BUILD_REACH * 2.0)
		if chit.is_empty():
			return
		if capture_corner == Vector3.INF:
			capture_corner = chit.position
			message.emit("Corner 1 marked. Press C at the opposite corner of your building.")
		else:
			_save_blueprint(capture_corner, chit.position)
			capture_corner = Vector3.INF
		return
	var wheel := event as InputEventMouseButton
	if wheel and wheel.pressed and wheel.shift_pressed and wheel.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		# Shift + mouse wheel: raise / lower the piece half a metre (F97). Page Up / Down still work.
		lift += 0.5 if wheel.button_index == MOUSE_BUTTON_WHEEL_UP else -0.5
		_learn("lift")
		changed.emit()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("dig") and not target.is_empty():
		auth.builder.ask_place(piece, family, target.pos, target.rot)
		_learn("place")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("use"):
		var hit := dwarf.aim_far(Pieces.BUILD_REACH)
		if hit.get("collider") is PieceNode:
			_learn("pickup")
			auth.builder.ask_remove(hit.collider.uid)  # careful pick-up: all back, right after placing (F100)
		elif hit.get("collider") is Station:
			auth.ask_pickup_station((hit.collider as Station).station_id)  # stations always come back whole
		elif Storage.box_id_of(hit.get("collider")) >= 0:
			auth.storage.ask_pick_up(Storage.box_id_of(hit.collider))  # chests and barrels move too (owner), when empty
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("break_piece"):
		var hit := dwarf.aim_far(Pieces.BUILD_REACH)
		if hit.get("collider") is PieceNode:
			auth.builder.ask_remove(hit.collider.uid, true)  # break it: half back
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("rotate_piece"):
		turn(1)  # (E turns the other way: main.gd, because E is also "use / open")
	elif event.is_action_pressed("lift_up"):
		lift += 0.5
		_learn("lift")
		changed.emit()
	elif event.is_action_pressed("lift_down"):
		lift -= 0.5
		_learn("lift")
		changed.emit()


## Saves everything built between the two corners (and up to 6 m higher) as a blueprint file.
func _save_blueprint(a: Vector3, b: Vector3) -> void:
	var auth := GameAuthority.instance
	var lo := a.min(b) + Vector3(-0.5, -0.5, -0.5)
	var hi := a.max(b) + Vector3(0.5, 6.0, 0.5)
	DirAccess.make_dir_recursive_absolute("user://blueprints")
	var n := BlueprintMenu.all_files().size() + 1
	var bp := Blueprint.capture(auth.builder.structure, auth.world.sdf_at, lo, hi, "My Blueprint %d" % n)
	if bp.pieces.is_empty():
		message.emit("Nothing built between those corners.")
		return
	bp.author = "Player %d" % dwarf.peer_id
	var path := "user://blueprints/my_blueprint_%d.dwbp" % n
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(bp.to_json())
	f.close()
	message.emit("Saved \"%s\" (%d pieces). Press V to place it again anywhere." % [bp.name, bp.pieces.size()])
