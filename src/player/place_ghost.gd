class_name PlaceGhost
extends Node3D
## Holding a station or chest (workbench, campfire, bed, chest...): a see-through copy shows where it
## will go when you right-click, green when it fits and red when it doesn't (owner, Nov 15, F96).
## Only a look on your own screen: the host still decides (GameAuthority.request_use).

var dwarf: Dwarf
## Which way it faces. Set once from where you look when you take it out (no snapping), then only Q / E
## turn it, walking doesn't (owner, Nov 19). A tap turns 5°; holding the key keeps turning at one calm,
## steady speed (owner, Nov 19, F397). The dwarf places it with this turn (Dwarf, ask_use).
static var yaw := 0.0
const TURN_STEP := deg_to_rad(5.0)  ## one tap
const TURN_SPEED := deg_to_rad(60.0)  ## per second while held: a full circle in 6 s, never faster
const HOLD_DELAY := 0.25  ## seconds held before the smooth turning starts (so a tap stays a tap)
var _hold_dir := 0
var _hold_time := 0.0
var _shown_id := ""
var _look: Node3D
var _ok_mat: StandardMaterial3D
var _bad_mat: StandardMaterial3D


func _ready() -> void:
	_ok_mat = _ghost_mat(Color(0.3, 1.0, 0.4, 0.35))
	_bad_mat = _ghost_mat(Color(1.0, 0.25, 0.2, 0.35))
	visible = false


static func _ghost_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c
	return m


func _process(delta: float) -> void:
	var auth := GameAuthority.instance
	var ps: GameAuthority.PlayerState = auth.get_player(auth.local_peer_id()) if auth and dwarf else null
	var id := ps.selected_item() if ps else ""
	var kind := Items.kind(id)
	if ps == null or not kind in ["station", "chest"] or not Controls.captured() or dwarf._holding_hammer():
		visible = false
		_shown_id = ""
		return
	if _shown_id == "":
		yaw = wrapf(dwarf.model.rotation.y + PI, -PI, PI)
	_keep_turning(delta)
	var hit := dwarf.aim()
	if hit.is_empty():
		visible = false
		return
	var spot: Dictionary = where(id, hit.position, hit.normal, yaw, ps.node.global_position, auth)
	_show(id)
	global_position = spot.pos
	rotation = Vector3(0, spot.yaw, 0)
	_paint(_look, _ok_mat if spot.ok else _bad_mat)
	visible = true


## Where it would go and whether the host would say yes (the same rules as GameAuthority.request_use).
static func where(id: String, point: Vector3, normal: Vector3, yaw: float, from: Vector3, auth: GameAuthority) -> Dictionary:
	var n := normal.normalized()
	var on_wall := id in Station.ON_WALL and absf(n.y) < 0.3
	var pos := point
	if on_wall:
		var out := Vector3(n.x, 0.0, n.z).normalized()
		pos = GameAuthority.wall_spot(id, point, out)
		yaw = atan2(out.x, out.z)
	var ok := (n.y >= 0.6 or on_wall) and (from + Vector3.UP * 1.0).distance_to(point) <= GameAuthority.REACH + 1.0
	var on_fire := Station.on_fire_spot(id, point, auth.stations.values())  # a pot snaps onto a campfire
	if ok and on_fire.is_finite():
		return {pos = on_fire, yaw = yaw, ok = true}
	if ok and Items.kind(id) == "station":
		for st in auth.stations.values():
			if st.global_position.distance_to(point) < 1.5:
				ok = false  # too close to another station
		if ok and Station.in_rock(id, pos, yaw, auth.world):
			ok = false  # it would stand in the wall (owner, Nov 17)
	return {pos = pos, yaw = yaw, ok = ok}


## Q (+1, left) / E (-1, right): one small step now, and smooth turning while the key stays down.
func turn(dir: int) -> void:
	yaw = wrapf(yaw + dir * TURN_STEP, -PI, PI)
	_hold_dir = dir
	_hold_time = 0.0


## How far to turn this frame when the key has been held for `held` seconds: nothing during the short
## wait, then always the same speed (not faster the longer you hold).
static func held_turn(dir: int, held: float, delta: float) -> float:
	return 0.0 if held < HOLD_DELAY else dir * TURN_SPEED * delta


func _keep_turning(delta: float) -> void:
	if _hold_dir == 0:
		return
	# E is also "open / use": main.gd only starts an E turn when nothing is aimed at to open.
	if not Input.is_action_pressed("rotate_piece" if _hold_dir > 0 else "interact"):
		_hold_dir = 0
		return
	_hold_time += delta
	yaw = wrapf(yaw + held_turn(_hold_dir, _hold_time, delta), -PI, PI)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("rotate_piece"):
		turn(1)
		get_viewport().set_input_as_handled()


func _show(id: String) -> void:
	if id == _shown_id:
		return
	_shown_id = id
	if _look:
		_look.queue_free()
	_look = Look.forged("stations", id)
	if _look:
		_look.scale = Vector3.ONE * Station.scale_of(id)
	if _look == null:
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Station.size_of(id)
		mi.mesh = box
		mi.position.y = box.size.y * 0.5
		_look = mi
	add_child(_look)


static func _paint(node: Node, m: Material) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).material_override = m
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c in node.get_children():
		_paint(c, m)
