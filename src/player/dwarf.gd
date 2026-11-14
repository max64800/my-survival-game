class_name Dwarf
extends CharacterBody3D
## The dwarf: walking, running, jumping, the camera behind them, and swinging the pickaxe.
## It never changes the world itself: it ASKS the GameAuthority (request_*).

const WALK_SPEED := 4.0
const RUN_SPEED := 6.5
const JUMP_SPEED := 5.5         ## about 1.5 m high
const COYOTE_TIME := 0.15       ## you can still jump this long after walking off an edge
const JUMP_BUFFER := 0.15       ## a jump pressed this long before landing still counts
const STEP_HEIGHT := 0.5        ## ledges up to this tall are stepped up without jumping
const ACCEL := 14.0
const AIR_ACCEL := 4.0
const SWING_TIME := 0.55
const CAMERA_DISTANCE := 3.4
const SHOULDER := Vector3(0.55, 1.5, 0.0)

var peer_id := 1
var model: DwarfModel
var lantern: Lantern
var camera: Camera3D
var input_enabled := true
## For tests and robots: move/jump without a keyboard. (x = right, y = back, like the keys.)
var bot_move := Vector2.ZERO
var bot_jump := false

var _since_floor := 0.0
var _jump_wanted := 0.0
var _cam_y := NAN

var _yaw := 0.0
var _pitch := -0.25
var _cam_yaw: Node3D
var _cam_pitch: Node3D
var _spring: SpringArm3D
var _shake := 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var _respawn_point := Vector3.ZERO


func _ready() -> void:
	collision_layer = 8
	collision_mask = World.TERRAIN_LAYER
	floor_max_angle = deg_to_rad(52)
	floor_snap_length = 0.45
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.36
	cap.height = 1.35
	shape.shape = cap
	shape.position = Vector3.UP * 0.675
	add_child(shape)
	model = DwarfModel.new()
	add_child(model)
	model.swing_impact.connect(_on_swing_impact)
	lantern = Lantern.new()
	lantern.peer_id = peer_id
	model.left_hand.add_child(lantern)
	_build_camera()
	_respawn_point = global_position


func set_respawn(p: Vector3) -> void:
	_respawn_point = p


func _build_camera() -> void:
	_cam_yaw = Node3D.new()
	_cam_yaw.top_level = true
	add_child(_cam_yaw)
	_cam_pitch = Node3D.new()
	_cam_yaw.add_child(_cam_pitch)
	_spring = SpringArm3D.new()
	_spring.spring_length = CAMERA_DISTANCE
	_spring.collision_mask = World.TERRAIN_LAYER
	_spring.margin = 0.25
	var probe := SphereShape3D.new()
	probe.radius = 0.25
	_spring.shape = probe
	_spring.add_excluded_object(get_rid())
	_cam_pitch.add_child(_spring)
	camera = Camera3D.new()
	camera.fov = 72.0
	camera.near = 0.05
	camera.far = 400.0
	_spring.add_child(camera)
	camera.current = true


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * Controls.MOUSE_SENSITIVITY
		_pitch = clampf(_pitch - event.relative.y * Controls.MOUSE_SENSITIVITY, -1.35, 1.1)
	var auth := GameAuthority.instance
	if auth == null:
		return
	var ps := auth.get_player(peer_id)
	for i in 8:
		if event.is_action_pressed("hotbar_%d" % (i + 1)):
			auth.request_select_slot(peer_id, i)
	if ps and event.is_action_pressed("hotbar_next"):
		auth.request_select_slot(peer_id, (ps.selected_slot + 1) % Inventory.HOTBAR_SIZE)
	if ps and event.is_action_pressed("hotbar_prev"):
		auth.request_select_slot(peer_id, (ps.selected_slot + Inventory.HOTBAR_SIZE - 1) % Inventory.HOTBAR_SIZE)
	if event.is_action_pressed("refill_lantern"):
		auth.request_refill(peer_id)


func _physics_process(delta: float) -> void:
	var dir := Vector3.ZERO
	var running := false
	var playing := input_enabled and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	var iv := Vector2.ZERO
	if playing:
		iv = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		running = Input.is_action_pressed("run")
	if bot_move != Vector2.ZERO:
		iv = bot_move
	dir = (Basis(Vector3.UP, _yaw) * Vector3(iv.x, 0, iv.y))
	var speed := RUN_SPEED if running else WALK_SPEED
	var target := dir * speed
	var on_floor := is_on_floor()
	var a := ACCEL if on_floor else AIR_ACCEL
	velocity.x = move_toward(velocity.x, target.x, a * speed * delta)
	velocity.z = move_toward(velocity.z, target.z, a * speed * delta)

	# Jumping, made forgiving: bumpy cave floors can make "am I standing?" flicker,
	# so a jump still works a moment after leaving the ground or just before landing.
	_since_floor = 0.0 if on_floor else _since_floor + delta
	if (playing and Input.is_action_just_pressed("jump")) or bot_jump:
		_jump_wanted = JUMP_BUFFER
		bot_jump = false
	else:
		_jump_wanted = maxf(0.0, _jump_wanted - delta)
	if _jump_wanted > 0.0 and _since_floor <= COYOTE_TIME and velocity.y <= 0.5:
		velocity.y = JUMP_SPEED
		_jump_wanted = 0.0
		_since_floor = COYOTE_TIME + 1.0  # no double jump
	elif not on_floor:
		velocity.y -= _gravity * delta
	move_and_slide()
	if on_floor and velocity.y <= 0.01 and dir.length() > 0.1 and is_on_wall():
		_try_step_up(dir * speed * delta)
	_footsteps(delta)

	# Face where we're going, or where we're digging.
	var face_dir := dir
	if model.swinging or (playing and Input.is_action_pressed("dig")):
		face_dir = -(Basis(Vector3.UP, _yaw).z)
	if face_dir.length() > 0.1:
		var want := atan2(-face_dir.x, -face_dir.z)
		model.rotation.y = lerp_angle(model.rotation.y, want, minf(1.0, delta * 12.0))

	if playing and Input.is_action_pressed("dig") and not model.swinging:
		model.swing(SWING_TIME)
		Sfx.play("swing", global_position + Vector3.UP, -12.0)

	# Safety net: if we ever fall out of the cave, go back to the start.
	if global_position.y < CaveMaker.Y_MIN - 30.0:
		global_position = _respawn_point
		velocity = Vector3.ZERO


## Walked into something low (a ledge, the edge of a dug hole)? If there's room
## above it and floor on top, hop up onto it, like climbing a stair.
func _try_step_up(motion: Vector3) -> void:
	motion = motion.normalized() * maxf(motion.length(), 0.12)
	var start := global_transform
	var up := Vector3.UP * STEP_HEIGHT
	if test_move(start, up):
		return  # no head room
	var raised := start.translated(up)
	if test_move(raised, motion):
		return  # still blocked up there: it's a wall, not a step
	var ahead := raised.translated(motion)
	var hit := KinematicCollision3D.new()
	if not test_move(ahead, -up, hit):
		return  # nothing to stand on
	if hit.get_normal().angle_to(Vector3.UP) > floor_max_angle:
		return  # too steep to stand on
	global_position = ahead.origin + hit.get_travel()


func _process(delta: float) -> void:
	# The camera follows smoothly up and down, so stepping up a ledge doesn't jolt.
	var want_y := global_position.y + SHOULDER.y
	if is_nan(_cam_y) or absf(_cam_y - want_y) > 2.0:
		_cam_y = want_y
	_cam_y = lerpf(_cam_y, want_y, minf(1.0, delta * 14.0))
	_cam_yaw.global_position = Vector3(global_position.x, _cam_y, global_position.z)
	_cam_yaw.rotation.y = _yaw
	_cam_pitch.rotation.x = _pitch
	_spring.position = Vector3(SHOULDER.x, 0, 0)
	_shake = maxf(0.0, _shake - delta * 4.0)
	camera.h_offset = randf_range(-1, 1) * _shake * 0.06
	camera.v_offset = randf_range(-1, 1) * _shake * 0.06


## What's under the crosshair, within reach.
func aim() -> Dictionary:
	var from := camera.global_position
	var forward := -camera.global_basis.z
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, from + forward * (CAMERA_DISTANCE + GameAuthority.REACH + 2.0))
	q.collision_mask = World.TERRAIN_LAYER | GlowField.GLOW_LAYER
	q.exclude = [get_rid()]
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return {}
	var chest := global_position + Vector3.UP
	if chest.distance_to(hit.position) > GameAuthority.REACH:
		return {}
	return hit


func _aim_info() -> Dictionary:
	var hit := aim()
	if hit.is_empty():
		return {}
	var auth := GameAuthority.instance
	if auth and auth.glow and auth.glow.id_of(hit.collider) >= 0:
		var spot := auth.glow.get_spot(auth.glow.id_of(hit.collider))
		return {kind = "glow", name = "Glow Crystal" if spot.get("kind") == GlowPlacer.CRYSTAL else "Glowcap"}
	if auth and auth.world:
		var mat := auth.world.rock_material_near(hit.position - hit.normal * 0.3, 1.1)
		if mat >= 0:
			return {kind = "rock", material = mat, name = Mat.NAMES.get(mat, "?")}
	return {}


func _on_swing_impact() -> void:
	var auth := GameAuthority.instance
	var hit := aim()
	if auth == null or hit.is_empty():
		return
	var glow_id := auth.glow.id_of(hit.collider) if auth.glow else -1
	if glow_id >= 0:
		if auth.request_break_glow(peer_id, glow_id):
			Fx.burst(get_parent(), hit.position, Color(0.5, 0.85, 1.0), 14)
			Sfx.play("crystal", hit.position)
			_shake = 0.6
		return
	var result := auth.request_hit(peer_id, hit.position, hit.normal)
	var mat: int = result.get("material", Mat.STONE)
	var col := Fx.material_color(mat)
	var soft := mat == Mat.MOSS or mat == Mat.DIRT
	match result.get("state", ""):
		"hit":
			Fx.burst(get_parent(), hit.position + hit.normal * 0.1, col, 6, 2.5)
			Sfx.play("dig_soft" if soft else "dig_rock", hit.position)
			_shake = 0.35
		"dug":
			Fx.burst(get_parent(), hit.position, col, 16, 4.0)
			Sfx.play("dig_soft" if soft else "dig_rock", hit.position, 2.0, 0.85)
			_shake = 0.8
		"blocked":
			Fx.burst(get_parent(), hit.position + hit.normal * 0.1, Color(1.0, 0.9, 0.6), 4, 5.0)
			Sfx.play("clink", hit.position)
			_shake = 0.2


var _step_t := 0.0


## Footsteps: quicker when running.
func _footsteps(delta: float) -> void:
	var speed := Vector2(velocity.x, velocity.z).length()
	if not is_on_floor() or speed < 1.0:
		_step_t = 0.0
		return
	_step_t -= delta
	if _step_t <= 0.0:
		_step_t = 0.42 if speed < 5.0 else 0.3
		Sfx.play("step", global_position, -14.0)
