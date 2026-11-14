class_name Dwarf
extends CharacterBody3D
## The dwarf: walking, running, jumping, the camera behind them, and swinging the pickaxe.
## It never changes the world itself: it ASKS the GameAuthority (ask_*).
## In co-op, other players' dwarfs are "puppets" (is_local = false): no camera,
## no controls, they just copy the position their owner sends over the network.

const BODY_LAYER := 8  ## players' bodies (friendly fire bolts can hit them)
const WALK_SPEED := 4.0
const LADDER_SPEED := 2.5
const LADDER_STAMINA := 4.0
const RUN_SPEED := 6.5
const JUMP_SPEED := 5.5         ## about 1.5 m high
const COYOTE_TIME := 0.15       ## you can still jump this long after walking off an edge
const JUMP_BUFFER := 0.15       ## a jump pressed this long before landing still counts
const STEP_HEIGHT := 0.5        ## ledges up to this tall are stepped up without jumping
const ACCEL := 14.0
const AIR_ACCEL := 4.0
const SWING_TIME := 0.55
const CAMERA_DISTANCE := 3.4  ## starting camera distance (and the longest reach used for aiming)
const ZOOM_MIN := 1.4
const ZOOM_MAX := 8.0
const ZOOM_STEP := 0.5
const SHOULDER := Vector3(0.55, 1.5, 0.0)
const POSE_SEND_TIME := 0.05  ## send our position 20 times a second
const RUN_STAMINA := 8.0  ## per second
const JUMP_STAMINA := 10.0
const SWING_STAMINA := 5.0

var peer_id := 1
var model: DwarfModel
var lantern: Lantern
var camera: Camera3D
var input_enabled := true
var is_local := true  ## false = a friend's dwarf, moved by the network
var color_index := 0  ## which shirt color (0 = host)
var fight: DwarfFight
## For tests and robots: move/jump without a keyboard. (x = right, y = back, like the keys.)
var bot_move := Vector2.ZERO
var bot_jump := false

var _since_floor := 0.0
var _jump_wanted := 0.0
var _cam_y := NAN
var _zoom := CAMERA_DISTANCE  ## where the mouse wheel wants the camera

var _yaw := 0.0
var _pitch := -0.25
var _cam_yaw: Node3D
var _cam_pitch: Node3D
var _spring: SpringArm3D
var _shake := 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var _respawn_point := Vector3.ZERO
var _pose_timer := 0.0
var _net_pos := Vector3.ZERO
var _net_yaw := 0.0


func _ready() -> void:
	collision_layer = BODY_LAYER
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
	model.tunic = DwarfModel.TUNICS[color_index % DwarfModel.TUNICS.size()]
	add_child(model)
	model.swing_impact.connect(_on_swing_impact)
	lantern = Lantern.new()
	lantern.peer_id = peer_id
	model.left_hand.add_child(lantern)
	_respawn_point = global_position
	_net_pos = global_position
	if not is_local:
		set_physics_process(false)
		return
	_build_camera()
	fight = DwarfFight.new()
	fight.dwarf = self
	add_child(fight)
	var auth := GameAuthority.instance
	if auth:
		auth.dig_feedback.connect(_on_dig_feedback)


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
	if not input_enabled or not is_local:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * Controls.MOUSE_SENSITIVITY
		_pitch = clampf(_pitch - event.relative.y * Controls.MOUSE_SENSITIVITY, -1.35, 1.1)
	var auth := GameAuthority.instance
	if auth == null:
		return
	var ps := auth.get_player(peer_id)
	for i in Inventory.HOTBAR_SIZE:
		if event.is_action_pressed("hotbar_%d" % (i + 1)):
			auth.ask_select_slot(i)
	# Mouse wheel: camera closer / farther (feedback F18).
	if event.is_action_pressed("zoom_in"):
		_zoom = maxf(ZOOM_MIN, _zoom - ZOOM_STEP)
	if event.is_action_pressed("zoom_out"):
		_zoom = minf(ZOOM_MAX, _zoom + ZOOM_STEP)
	if event.is_action_pressed("refill_lantern"):
		if fight and fight.is_crossbow():
			fight.start_reload()  # R reloads while you hold the crossbow (doc 1.5)
		else:
			auth.ask_refill()
	if event.is_action_pressed("use") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not _holding_hammer() and not fight.weapon_mode():
		var hit := aim_far(20.0) if ps and Items.kind(ps.selected_item()) == "throw" else aim()  # you can throw far
		auth.ask_use(hit.get("position", Vector3.INF), hit.get("normal", Vector3.ZERO), model.rotation.y + PI)


func _physics_process(delta: float) -> void:
	var dir := Vector3.ZERO
	var running := false
	var playing := input_enabled and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	var iv := Vector2.ZERO
	if playing:
		iv = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		running = Input.is_action_pressed("run") and iv.length() > 0.1
	if bot_move != Vector2.ZERO:
		iv = bot_move
	dir = (Basis(Vector3.UP, _yaw) * Vector3(iv.x, 0, iv.y))
	var body := _vitals()
	if running and body and not body.drain_stamina(RUN_STAMINA, delta):
		running = false  # out of breath
	var fight_mult := fight.step(delta, playing, dir) if fight else 1.0
	if fight and (fight.is_blocking() or fight.stagger > 0.0):
		running = false
	var speed := (RUN_SPEED if running else WALK_SPEED) * fight_mult * (body.ailments.speed_mult() if body else 1.0)
	var target := dir * speed
	var on_floor := is_on_floor()
	var a := ACCEL if on_floor else AIR_ACCEL
	velocity.x = move_toward(velocity.x, target.x, a * speed * delta)
	velocity.z = move_toward(velocity.z, target.z, a * speed * delta)
	if fight and fight.dodging():
		var dv := fight.dodge_velocity()
		velocity.x = dv.x
		velocity.z = dv.z
	# Jumping, made forgiving: bumpy cave floors can make "am I standing?" flicker,
	# so a jump still works a moment after leaving the ground or just before landing.
	_since_floor = 0.0 if on_floor else _since_floor + delta
	if (playing and Input.is_action_just_pressed("jump")) or bot_jump:
		_jump_wanted = JUMP_BUFFER
		bot_jump = false
	else:
		_jump_wanted = maxf(0.0, _jump_wanted - delta)
	if _jump_wanted > 0.0 and _since_floor <= COYOTE_TIME and velocity.y <= 0.5 \
			and (body == null or body.use_stamina(JUMP_STAMINA)):
		velocity.y = JUMP_SPEED
		_jump_wanted = 0.0
		_since_floor = COYOTE_TIME + 1.0  # no double jump
	elif not on_floor:
		velocity.y -= _gravity * delta
	# Rope ladders: hold forward (or jump) to climb, 4 stamina a second (doc 6.2).
	var ladder := _ladder_here()
	if ladder and playing and (Input.is_action_pressed("move_forward") or Input.is_action_pressed("jump")) \
			and (body == null or body.drain_stamina(LADDER_STAMINA, delta)):
		velocity.y = LADDER_SPEED
	elif ladder and not is_on_floor():
		velocity.y = maxf(velocity.y, -1.5)  # hold on: slide down slowly
	move_and_slide()
	if on_floor and not ladder and velocity.y <= 0.01 and dir.length() > 0.1 and is_on_wall():
		_try_step_up(dir * speed * delta)

	# Face where we're going, or where we're digging.
	var face_dir := dir
	if model.swinging or (playing and Input.is_action_pressed("dig")):
		face_dir = -(Basis(Vector3.UP, _yaw).z)
	if face_dir.length() > 0.1:
		var want := atan2(-face_dir.x, -face_dir.z)
		model.rotation.y = lerp_angle(model.rotation.y, want, minf(1.0, delta * 12.0))

	_footsteps(delta, Vector2(velocity.x, velocity.z).length())
	model.set_motion(Vector2(velocity.x, velocity.z).length(), is_on_floor(), fight != null and fight.dodging())
	if playing and Input.is_action_pressed("dig") and not model.swinging and not _holding_hammer() and not fight.weapon_mode() and _can_swing():
		model.swing(SWING_TIME)
		if _online():
			_net_swing.rpc()

	# Safety net: if we ever fall out of the cave, go back to the start.
	if global_position.y < CaveMaker.Y_MIN - 30.0:
		global_position = _respawn_point
		velocity = Vector3.ZERO


func _process(delta: float) -> void:
	if is_local and fight:
		model.set_held(fight.item())
	if not is_local:
		global_position = global_position.lerp(_net_pos, minf(1.0, delta * 15.0))
		model.rotation.y = lerp_angle(model.rotation.y, _net_yaw, minf(1.0, delta * 15.0))
		return
	_pose_timer -= delta
	if _pose_timer <= 0.0 and _online():
		_pose_timer = POSE_SEND_TIME
		_net_pose.rpc(global_position, model.rotation.y)
	# The camera follows smoothly up and down, so stepping up a ledge doesn't jolt.
	var want_y := global_position.y + SHOULDER.y
	if is_nan(_cam_y) or absf(_cam_y - want_y) > 2.0:
		_cam_y = want_y
	_cam_y = lerpf(_cam_y, want_y, minf(1.0, delta * 14.0))
	_cam_yaw.global_position = Vector3(global_position.x, _cam_y, global_position.z)
	_cam_yaw.rotation.y = _yaw
	_cam_pitch.rotation.x = _pitch
	_spring.position = Vector3(SHOULDER.x, 0, 0)
	_spring.spring_length = lerpf(_spring.spring_length, _zoom, minf(1.0, delta * 10.0))  # smooth zoom
	_shake = maxf(0.0, _shake - delta * 4.0)
	camera.fov = lerpf(camera.fov, 48.0 if fight and fight.aiming() else 72.0, minf(1.0, delta * 10.0))  # crossbow zoom
	camera.h_offset = randf_range(-1, 1) * _shake * 0.06
	camera.v_offset = randf_range(-1, 1) * _shake * 0.06


## What's under the crosshair, up to `reach` meters from the dwarf (building reaches further).
func aim_far(reach: float) -> Dictionary:
	var from := camera.global_position
	var forward := -camera.global_basis.z
	var q := PhysicsRayQueryParameters3D.create(from, from + forward * (_spring.spring_length + reach + 2.0))
	q.collision_mask = World.TERRAIN_LAYER | GlowField.GLOW_LAYER | Station.STATION_LAYER | Monster.MONSTER_LAYER | PoiField.POI_LAYER | PieceNode.PIECE_LAYER
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty() or (global_position + Vector3.UP).distance_to(hit.position) > reach:
		return {}
	return hit


## What's under the crosshair, within reach.
func aim() -> Dictionary:
	var from := camera.global_position
	var forward := -camera.global_basis.z
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, from + forward * (_spring.spring_length + GameAuthority.REACH + 2.0))
	q.collision_mask = World.TERRAIN_LAYER | GlowField.GLOW_LAYER | Station.STATION_LAYER | Monster.MONSTER_LAYER | PoiField.POI_LAYER
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
		var k: Dictionary = GlowPlacer.KINDS.get(spot.get("kind", ""), {})
		var nm := Items.display_name(k.get("item", ""))
		if spot.get("kind") == GlowPlacer.ROOT:
			nm = "Hanging Root (%d chops left)" % spot.get("chops", 1)
		elif spot.get("kind") == GlowPlacer.ROOT_DANGLE:
			nm = "Thin Root · click to pull it down"
		elif spot.get("kind") == GlowPlacer.GIANT:
			nm = "Giant Mushroom (%d chops left · copper axe)" % spot.get("chops", 1)
		return {kind = "glow", name = nm}
	if hit.collider is Station:
		var st: Station = hit.collider
		return {kind = "station", name = "%s · E to use" % Items.display_name(st.kind), station = st}
	var poi_id := PoiField.poi_id_of(hit.collider)
	if poi_id >= 0 and auth:
		var t: String = auth.world.maker.pois[poi_id].type
		var label: String = {"marking": "Old carving · E to read", "lair": "Summoning altar · E"}.get(t, "Rune shrine · E to take")
		return {kind = "poi", poi_id = poi_id, name = label}
	var box_id := Storage.box_id_of(hit.collider)
	if box_id >= 0 and auth:
		var box := auth.storage.get_box(box_id)
		var nm: String = {"grave": "Your grave", "builder": "Builder's Chest"}.get(box.get("kind", ""), "Chest")
		return {kind = "box", name = "%s · E to open" % nm, box_id = box_id}
	if auth and auth.world:
		var mat := auth.world.rock_material_near(hit.position - hit.normal * 0.3, 1.1)
		if mat >= 0:
			var nm: String = Mat.NAMES.get(mat, "?")
			var ps := auth.get_player(peer_id)
			if ps and ps.selected_item() == "prospectors_lens":
				# The lens shows how hard the rock is and what's 3 m behind it.
				var behind := auth.world.sdf_at(hit.position - hit.normal * 3.0)
				var behind_mat := auth.world.material_at(hit.position - hit.normal * 3.0)
				nm = "%s · hardness %d%s · 3 m behind: %s" % [nm, Mat.hardness(mat), " (needs a better pickaxe)" if Mat.min_tier(mat) > 0 else "",
					"open air!" if behind > 0.0 else Mat.NAMES.get(behind_mat, "rock")]
			return {kind = "rock", material = mat, name = nm}
	return {}


func _on_swing_impact() -> void:
	if not is_local:
		return
	var auth := GameAuthority.instance
	var hit := aim()
	if auth == null or hit.is_empty():
		return
	var glow_id := auth.glow.id_of(hit.collider) if auth.glow else -1
	if glow_id >= 0:
		auth.ask_harvest(glow_id)
		var spot := auth.glow.get_spot(glow_id)
		var sk: String = spot.get("kind", "")
		Sfx.play("crystal" if sk.begins_with("crystal") else ("chop" if sk == "root" else "dig_soft"), hit.position, -3.0)
		Fx.burst(get_parent(), hit.position, spot.get("color", Color.WHITE), 8)
		_shake = 0.4
		return
	var mon := MonsterManager.uid_of(hit.collider)
	if mon >= 0:
		auth.monsters.ask_attack(PackedInt32Array([mon]), false, 0, false)  # a pickaxe works in a pinch
		return
	if hit.collider is Station or hit.collider is PieceNode or Storage.box_id_of(hit.collider) >= 0:
		return  # don't dig through your own furniture or buildings
	auth.ask_hit(hit.position, hit.normal)


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


var _step_t := 0.0


## Footsteps on stone: faster when running.
func _footsteps(delta: float, speed: float) -> void:
	if not is_on_floor() or speed < 1.0:
		_step_t = 0.0
		return
	_step_t -= delta
	if _step_t <= 0.0:
		_step_t = 0.42 if speed < 5.0 else 0.3
		Sfx.play("step", global_position, -14.0)


# ---------------------------------------------------------------- fighting (see DwarfFight)

func defense_state() -> Dictionary:
	return fight.defense_state()


func is_invulnerable() -> bool:
	return fight.invulnerable()


func guard_break() -> void:
	fight.guard_break()


func knock_down() -> void:
	fight.knock_down()


func got_parry() -> void:
	fight.got_parry()
	_shake = 0.5


func add_shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


## A rope ladder we're touching, or null.
func _ladder_here() -> Station:
	var auth := GameAuthority.instance
	if auth == null:
		return null
	for st in auth.stations.values():
		if st.kind != "rope_ladder":
			continue
		var d: Vector3 = global_position - st.global_position
		if Vector2(d.x, d.z).length() < 0.9 and d.y > -0.5 and d.y < Station.LADDER_HEIGHT + 0.5:
			return st
	return null


## Turn to face where the camera looks (when attacking).
func face_camera() -> void:
	model.rotation.y = _yaw


func _holding_hammer() -> bool:
	var auth := GameAuthority.instance
	var ps := auth.get_player(peer_id) if auth else null
	return ps != null and ps.selected_item() == "build_hammer"


func _vitals() -> Vitals:
	var auth := GameAuthority.instance
	var ps := auth.get_player(peer_id) if auth else null
	return ps.vitals if ps else null


## Swinging costs stamina (less with Mining skill and the Light Arms perk).
func _can_swing() -> bool:
	var auth := GameAuthority.instance
	var ps := auth.get_player(peer_id) if auth else null
	if ps == null:
		return true
	var swift: float = Gems.bonus(ps.inventory.get_slot(ps.selected_slot)).get("mine_stamina", 0.0)
	return ps.vitals.use_stamina(SWING_STAMINA * ps.progress.swing_stamina_mult() * (1.0 - swift))


## The host's answer to our pickaxe hit (arrives right away when playing alone).
func _on_dig_feedback(pid: int, result: Dictionary) -> void:
	if pid != peer_id or not result.has("point"):
		return
	var at: Vector3 = result.point
	var col := Fx.material_color(result.get("material", Mat.STONE))
	var soft: bool = result.get("material", Mat.STONE) in [Mat.MOSS, Mat.DIRT, Mat.CLAY]
	match result.get("state", ""):
		"hit":
			Fx.burst(get_parent(), at, col, 6, 2.5)
			_shake = 0.35
			Sfx.play("dig_soft" if soft else "dig_rock", at)
		"dug":
			Fx.burst(get_parent(), at, col, 16, 4.0)
			ChunkSwarm.burst(get_parent(), at, col, self)  # 25-50 bits fly into you (F13)
			_shake = 0.8
			Sfx.play("dig_soft" if soft else "dig_rock", at, 2.0, 0.85)
		"blocked":
			Fx.burst(get_parent(), at, Color(1.0, 0.9, 0.6), 4, 5.0)
			_shake = 0.2
			Sfx.play("clink", at)
		"done":
			var k: String = result.get("kind", "")
			Sfx.play("crystal" if k.begins_with("crystal") else ("chop" if k in GlowPlacer.TALL else "pickup"), at)


# ---------------------------------------------------------------- network pose

func _online() -> bool:
	return not multiplayer.get_peers().is_empty()


@rpc("authority", "unreliable_ordered")
func _net_pose(pos: Vector3, yaw: float) -> void:
	_net_pos = pos
	_net_yaw = yaw


@rpc("authority", "reliable")
func _net_swing() -> void:
	model.swing(SWING_TIME)
