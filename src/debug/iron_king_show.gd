class_name IronKingShow
extends Node
## The Iron King's moves test (F981, owner Nov 28: "moves test first"). Dev only, launched with `ironking`.
## A flat floor high above the cave, you, and the Iron King (src/combat/iron_king.gd) 7 m in front of you. He turns
## to face you, walks up if you are far, and does his attacks in turn, each one's name on a sign over his head:
## Shield Bash, Hammer Slam, Shield Charge, then the greataxe: Greataxe Chop, Greataxe Spin. He does no harm yet
## (the fight brain comes after the owner's OK). `ironshots=<folder>`: robots save a picture at each blow, then quit.

const ORIGIN := Vector3(0.0, 400.0, 0.0)
const ORDER := ["bash", "slam", "charge", "chop", "spin"]
const REST := 1.4  ## s he stands between attacks
const NEAR := 4.5  ## m: closer than this he stops walking

var _main: Node
var _king: IronKing
var _sign: Label3D
var _next := 0
var _wait := 2.0
var _shots := ""
var _back := 0.0  ## s left of stepping back
const RUN_UP := 9.0  ## m from you he starts the Shield Charge


func _ready() -> void:
	_main = get_parent()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("ironshots="):
			_shots = a.trim_prefix("ironshots=")
	_run.call_deferred()


func _run() -> void:
	var waited := 0.0
	while not _main.is_ready_to_play() and waited < 180.0:
		await get_tree().create_timer(0.25).timeout
		waited += 0.25
	_build_floor()
	var dwarf: Dwarf = _main.dwarf
	dwarf.global_position = ORIGIN + Vector3(0.0, 0.4, 8.0)
	dwarf.velocity = Vector3.ZERO
	dwarf._yaw = 0.0
	dwarf._pitch = 0.0
	dwarf.model.rotation.y = 0.0
	if _shots != "":  # (robots: the pictures are of him, not of you)
		dwarf.model.visible = false
	var ps = _main.authority.get_player(_main.authority.local_peer_id())
	if ps:
		ps.bed_pos = dwarf.global_position
	var amb: Ambience = _main.get_node_or_null("Ambience")
	if amb:
		amb.set_dev_bright(true)
	_king = IronKing.new()
	add_child(_king)
	_king.global_position = ORIGIN + Vector3(0.0, 0.0, 1.0)
	_sign = Label3D.new()
	_sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sign.font_size = 96
	_sign.outline_size = 18
	_sign.modulate = Color(0.75, 1.0, 0.8)
	_sign.no_depth_test = true
	add_child(_sign)
	_main.hud.show_toast("The Iron King's moves (no harm yet). He takes turns: bash, slam, charge, chop, spin.", 8.0)
	print("IRON_KING_SHOW ready")


func _process(delta: float) -> void:
	if _king == null or _king.dm.dwarf_rig == null:
		return
	var me: Vector3 = _main.dwarf.global_position
	var to := me - _king.global_position
	to.y = 0.0
	var dist := to.length()
	_sign.global_position = _king.global_position + Vector3(0.0, 3.3, 0.0)
	if _king.busy > 0.0:  # (turns only between blows: a blow you can see coming must not follow you round)
		_king.walk(0.0)
		return
	if _back > 0.0:  # stepping back for a run-up (before the Shield Charge)
		_back -= delta
		_face(-to, delta)
		_king.walk(2.2)
		_king.global_position -= to.normalized() * 2.2 * delta
		return
	_face(to, delta)
	var what: String = ORDER[_next % ORDER.size()]
	if dist > NEAR and what != "charge":
		_king.walk(2.2)
		_king.global_position += to.normalized() * 2.2 * delta
		return
	_king.walk(0.0)
	_wait -= delta
	if _wait > 0.0:
		return
	if what == "charge" and dist < RUN_UP - 0.5:
		_back = (RUN_UP - dist) / 2.2
		_wait = 0.9  # (time to turn round to face you again)
		return
	_next += 1
	_sign.text = IronKing.ATTACKS[what][2]
	_king.attack(what, maxf(0.0, dist - 2.5))
	_wait = REST
	if _shots != "":
		_snap(what, float(IronKing.ATTACKS[what][1]))


func _face(dir: Vector3, delta: float) -> void:
	if dir.length() > 0.1:
		_king.rotation.y = lerp_angle(_king.rotation.y, atan2(-dir.x, -dir.z), minf(1.0, delta * 4.0))


## Robots: two pictures per attack (the wind-up glow, and the blow), then quit after the last one.
func _snap(what: String, t: float) -> void:
	var last := _next >= ORDER.size()
	await get_tree().create_timer(t * 0.25).timeout
	_save("%s_%s_windup.png" % [_next, what])
	await get_tree().create_timer(t * 0.17).timeout
	_save("%s_%s_blow.png" % [_next, what])
	if last:
		await get_tree().create_timer(t).timeout
		get_tree().quit()


func _save(file: String) -> void:
	DirAccess.make_dir_recursive_absolute(_shots)
	get_viewport().get_texture().get_image().save_png(_shots.path_join(file))


func _build_floor() -> void:
	var body := StaticBody3D.new()
	body.collision_layer = World.TERRAIN_LAYER
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40.0, 2.0, 40.0)
	shape.shape = box
	shape.position = Vector3(0.0, -1.0, 0.0)
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = box.size
	mesh.mesh = bm
	mesh.position = shape.position
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.36, 0.35, 0.34)
	mat.roughness = 1.0
	mesh.material_override = mat
	body.add_child(mesh)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, 30.0, 0.0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	body.add_child(sun)
	add_child(body)
	body.global_position = ORIGIN
