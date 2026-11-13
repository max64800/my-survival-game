class_name BuildMode
extends Node3D
## Build mode: active while the Build Hammer is in your hand.
##   Left click  = place the piece (the ghost shows where; green = OK, red = not allowed)
##   Right click = take down the piece you aim at (you get everything back)
##   Q = turn · PageUp / PageDown = lift up / down · B = choose piece and material

signal changed  ## piece/material/rotation changed (the HUD shows it)

var dwarf: Dwarf
var piece := "floor"
var family := "plank_root"
var rot := 0
var lift := 0.0
var problem := ""  ## why the ghost is red ("" = it's fine)
var target := {}  ## {pos, rot} where the piece would go
var _ghost: PieceNode


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


func _process(_delta: float) -> void:
	if not active():
		_ghost.visible = false
		return
	var hit := dwarf.aim_far(Pieces.BUILD_REACH)
	if hit.is_empty():
		_ghost.visible = false
		target = {}
		return
	target = Pieces.snap(piece, hit.position, hit.normal, dwarf.model.rotation.y + PI, rot, lift)
	_ghost.visible = true
	_ghost.global_position = target.pos
	_ghost.rotation = Vector3(0, target.rot * PI / 2.0, 0)
	var auth := GameAuthority.instance
	problem = auth.builder.problem(auth.get_player(dwarf.peer_id), piece, family, target.pos, target.rot)
	_ghost.set_ghost_ok(problem == "")


func _unhandled_input(event: InputEvent) -> void:
	if not active() or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var auth := GameAuthority.instance
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
