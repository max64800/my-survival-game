class_name BuildMode
extends Node3D
## Build mode: active while the Build Hammer is in your hand.
##   Left click  = place the piece (the ghost shows where; green = OK, red = not allowed)
##   Right click = take down the piece you aim at (you get everything back)
##   Q = turn · PageUp / PageDown = lift up / down · B = choose piece and material

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
	var ps := auth.get_player(dwarf.peer_id)
	return ps != null and ps.selected_item() == "build_hammer"


func choose(p_piece: String, p_family: String) -> void:
	piece = p_piece
	family = p_family if Pieces.allowed(p_piece, p_family) else Pieces.LIST[p_piece].get("families", [p_family])[0]
	_ghost.rebuild(piece, family)
	changed.emit()


## Pick a blueprint from the book: its ghost follows your aim until you click.
func start_blueprint(json: String) -> void:
	var r := Blueprint.from_json(json)
	if not r.ok:
		message.emit(r.error)
		return
	stop_blueprint()
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
	message.emit("Placing \"%s\": aim, Q to turn, left click to place, right click to cancel" % blueprint.name)


func stop_blueprint() -> void:
	blueprint = null
	if _bp_ghosts:
		_bp_ghosts.queue_free()
		_bp_ghosts = null


var _tint_on := false
var _tint_version := -1
var _tint_timer := 0.0


## Hammer out: every built piece glows faintly in its strength color (blue/green/yellow/red).
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
			(b.nodes[uid] as PieceNode).set_tint(Structure.strength_color(b.structure.pieces[uid].stability))
	_tint_on = true


func _process(delta: float) -> void:
	_update_tints(delta, active())
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
			g.rotation.y = placed[i].rot * PI / 2.0
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
		return
	var auth := GameAuthority.instance
	# Aiming at something already built? Snap to it (its top edge, corner, or side).
	var anchor := AABB()
	var hit_node: Object = hit.get("collider")
	if hit_node is PieceNode and auth.builder.structure.pieces.has((hit_node as PieceNode).uid):
		anchor = auth.builder.structure.box_of((hit_node as PieceNode).uid)
		aimed_uid = (hit_node as PieceNode).uid
	target = Pieces.snap(piece, hit.position, hit.normal, dwarf.model.rotation.y + PI, rot, lift, anchor)
	_ghost.visible = true
	_ghost.global_position = target.pos
	_ghost.rotation = Vector3(0, target.rot * PI / 2.0, 0)
	problem = auth.builder.problem(auth.get_player(dwarf.peer_id), piece, family, target.pos, target.rot)
	_ghost.set_ghost_ok(problem == "")


func _unhandled_input(event: InputEvent) -> void:
	if not active() or not Controls.captured():
		return
	var auth := GameAuthority.instance
	if blueprint:
		if event.is_action_pressed("dig") and _bp_origin != Vector3.INF:
			if not _bp_chest.is_finite():
				message.emit("No room for the Builder's Chest next to it. Turn it (Q) or pick a spot with open floor beside it.")
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
			rot = (rot + 1) % 4
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
	if event.is_action_pressed("dig") and not target.is_empty():
		auth.builder.ask_place(piece, family, target.pos, target.rot)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("use"):
		var hit := dwarf.aim_far(Pieces.BUILD_REACH)
		if hit.get("collider") is PieceNode:
			auth.builder.ask_remove(hit.collider.uid)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("rotate_piece"):
		rot = (rot + 1) % 4
		changed.emit()
	elif event.is_action_pressed("lift_up"):
		lift += 0.5
		changed.emit()
	elif event.is_action_pressed("lift_down"):
		lift -= 0.5
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
