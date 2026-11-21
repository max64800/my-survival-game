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
const ZOOM_MIN := 1.1
const ZOOM_MAX := 8.0
const ZOOM_STEP := 0.5
## The normal camera's height: dwarf height, not human height (owner, Nov 20: "made for humans, not dwarfs";
## was 1.5 m, now close to the aim camera's 0.9 m, which the owner liked).
const SHOULDER := Vector3(0.55, 1.0, 0.0)
## Where the camera sits while aiming (F452): x = to his right, y = height, z = distance behind.
const AIM_CAMERA := Vector3(0.45, 0.9, 2.0)
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
var _run_streak := 0.0  ## seconds since you started this run (Running ★25: a quick burst at the start)
var running := false  ## running this frame (DwarfFight stops a crossbow reload when you run)
var _was_playing := false  ## (F494: Shift is let go when you come back to the game)
var _layout := -2  ## the keyboard language last frame (-2 = not looked yet; F494: Ctrl+Shift switches it)


## Owner, Nov 20 (F494, 3rd time: "sometimes I can still run without pressing Shift"): when the game window loses
## the keyboard (another window, Alt-Tab, a pop-up) while Shift is down, it never hears Shift come back up, so it
## thought you still held it. Losing the window now lets go of every key.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		for act in InputMap.get_actions():
			Input.action_release(act)
var bot_jump := false

var _since_floor := 0.0
var _run_time := 0.0  ## Running and Jumping practice not yet told to the host
var _jumps := 0
var shield_blocks := 0  ## hits blocked or parried with a shield, not yet told to the host
var _body_xp_wait := 0.0
var _jump_wanted := 0.0
var _cam_y := NAN
var _zoom := CAMERA_DISTANCE  ## where the mouse wheel wants the camera

var _yaw := 0.0
var _pitch := -0.25
var _cam_yaw: Node3D
var _cam_pitch: Node3D
var _spring: SpringArm3D
var _shake := 0.0
var _aim_t := 0.0  ## 0 = normal camera, 1 = aiming over the shoulder (F452)
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var _respawn_point := Vector3.ZERO
var _pose_timer := 0.0
var _net_pos := Vector3.ZERO
var _net_yaw := 0.0
## Sitting on a chair, stool or bench (Furnish tab, owner Nov 19). Any move or jump stands you up.
const SIT_HIPS := 0.24  ## how high the seated dwarf's bottom is above his feet' spot (m)
var _seat: PieceNode = null
var _net_sitting := false
var _net_speed := 0.0  ## a friend's dwarf: how fast it moves on our screen (drives its legs)
var _sent_look := []  ## what we last told friends we hold / how we stand
var _look_timer := 0.0


func _ready() -> void:
	collision_layer = BODY_LAYER
	collision_mask = World.TERRAIN_LAYER | Monster.MONSTER_LAYER  # (owner, Nov 18: you could walk right through a beetle)
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
	model.reacted.connect(func(what: String, duration: float):
		if is_local and _online():
			_net_react.rpc(what, duration))
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


## Set by Main: the build hammer's mode (Shift + wheel lifts its piece instead of zooming, F97).
var build_mode: BuildMode


func build_lifts() -> bool:
	return build_mode != null and build_mode.active()


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or not is_local:
		return
	if event is InputEventMouseMotion and Controls.captured():
		var sens := Controls.MOUSE_SENSITIVITY * Controls.mouse_scale
		_yaw -= event.relative.x * sens
		_pitch = clampf(_pitch - event.relative.y * sens, -1.35, 1.1)
	var auth := GameAuthority.instance
	if auth == null:
		return
	var ps := auth.get_player(peer_id)
	for i in Inventory.HOTBAR_SIZE:
		if event.is_action_pressed("hotbar_%d" % (i + 1)):
			auth.ask_select_slot(i)
	if ps and event.is_action_pressed("stow_lantern") and Lantern.has_lantern(ps):
		auth.ask_stow_lantern(not ps.lantern_stowed)
		fight.message.emit("Lantern put away (L to take it out)." if ps.lantern_stowed else "Lantern out.", Color.WHITE)
	if ps and event.is_action_pressed("draw_weapon"):
		if not ps.can_draw():
			fight.message.emit("No weapon or shield equipped. Right-click one in your bag (Tab).", Color.WHITE)
		else:
			auth.ask_draw_weapon(not ps.weapon_drawn)
	# Mouse wheel: camera closer / farther (feedback F18). Shift + wheel lifts a building piece instead (F97).
	var lifting := event is InputEventMouseButton and (event as InputEventMouseButton).shift_pressed and build_lifts()
	if event.is_action_pressed("zoom_in") and not lifting:
		_zoom = maxf(ZOOM_MIN, _zoom - ZOOM_STEP)
	if event.is_action_pressed("zoom_out") and not lifting:
		_zoom = minf(ZOOM_MAX, _zoom + ZOOM_STEP)
	if event.is_action_pressed("refill_lantern"):
		if fight and fight.is_crossbow():
			fight.start_reload()  # R reloads while you hold the crossbow (doc 1.5)
		else:
			auth.ask_refill()
	if event.is_action_pressed("use") and Controls.captured() and not _holding_hammer() and not fight.weapon_mode():
		var hit := aim_far(20.0) if ps and Items.kind(ps.selected_item()) == "throw" else aim()  # you can throw far
		var using := Items.kind(ps.selected_item()) if ps else ""
		if using in ["food", "drink", "tonic", "waterskin"]:
			model.react("eat")
		elif using == "throw":
			model.react("throw")
		var yaw := PlaceGhost.yaw if using in ["station", "chest"] else model.rotation.y + PI  # Q / E turn (owner, Nov 19)
		auth.ask_use(hit.get("position", Vector3.INF), hit.get("normal", Vector3.ZERO), yaw)


## Dev only (F6, owner Nov 17): fly anywhere, straight through rock, to look at the whole cave.
## Mouse aims, WASD moves, Space up, Ctrl down, Shift fast.
var dev_fly := false
var dev_god := false  ## dev builds only (F9): monsters leave you alone (MonsterManager.ignores); Vitals.god: no damage
const FLY_SPEED := 12.0
const FLY_FAST := 45.0


func set_dev_fly(on: bool) -> void:
	dev_fly = on
	collision_mask = 0 if on else World.TERRAIN_LAYER | Monster.MONSTER_LAYER  # through rock (and back to solid)
	_spring.collision_mask = 0 if on else World.TERRAIN_LAYER  # the camera too
	velocity = Vector3.ZERO


func _fly(delta: float) -> void:
	var iv := Input.get_vector("move_left", "move_right", "move_forward", "move_back") if Controls.captured() else Vector2.ZERO
	var look := Basis(Vector3.UP, _yaw) * Basis(Vector3.RIGHT, _pitch)
	var dir := look * Vector3(iv.x, 0, iv.y)
	if Controls.captured():
		dir.y += (1.0 if Input.is_action_pressed("jump") else 0.0) - (1.0 if Input.is_action_pressed("dodge") else 0.0)
	var speed := FLY_FAST if Input.is_action_pressed("run") else FLY_SPEED
	velocity = velocity.lerp(dir.normalized() * speed if dir.length() > 0.1 else Vector3.ZERO, minf(1.0, delta * 8.0))
	global_position += velocity * delta
	model.set_motion(0.0, true, false)


func _physics_process(delta: float) -> void:
	if dev_fly and is_local:
		_fly(delta)
		return
	if ragdoll and ragdoll.down():
		return  # floppy: the rag doll moves us (DwarfRagdoll)
	if not _slide.is_empty():
		_slide_step(delta)
		return
	if _seat != null:
		_sit_step(delta)
		return
	model.set_sitting(false, delta)
	var dir := Vector3.ZERO
	running = false
	var playing := input_enabled and Controls.captured()
	if playing and not _was_playing:
		Input.action_release("run")  # (back from a menu or the bag: Shift must be pressed again, F494 3rd time)
	_was_playing = playing
	# F494, 4th time (owner, Nov 21: "really fast, like Shift; one tap of Shift fixes it"): Ctrl+Shift (dodge while
	# running) is Windows' "switch keyboard language" shortcut when a PC has more than one, and Windows then swallows
	# Shift coming back up. When the language changes, let go of run and dodge (press Shift again to run).
	var layout := DisplayServer.keyboard_get_current_layout()
	if layout != _layout:
		if _layout != -2:
			Input.action_release("run")
			Input.action_release("dodge")
		_layout = layout
	var iv := Vector2.ZERO
	if playing:
		iv = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		running = Input.is_action_pressed("run") and iv.length() > 0.1
	if bot_move != Vector2.ZERO:
		iv = bot_move
	dir = (Basis(Vector3.UP, _yaw) * Vector3(iv.x, 0, iv.y))
	var body := _vitals()
	var prog := _progress()
	if running and body and not body.drain_stamina(RUN_STAMINA * (prog.run_stamina_mult() if prog else 1.0), delta):
		running = false  # out of breath
	var fight_mult := fight.step(delta, playing, dir) if fight else 1.0
	if fight and (fight.is_blocking() or fight.stagger > 0.0):
		running = false
	if running:
		_run_time += delta
	_run_streak = _run_streak + delta if running else 0.0
	var burst := 1.3 if running and _run_streak < 1.0 and prog and prog.has_star("running", 25) else 1.0  # Running ★25
	var speed := (RUN_SPEED * (prog.run_speed_mult() if prog else 1.0) * burst if running else WALK_SPEED) * fight_mult * (body.ailments.speed_mult() * maxf(0.2, 1.0 + body.buff_total("move_speed")) if body else 1.0)
	if held_left > 0.0:  # (Lampwick's bear jaws hold your leg: MineTraps)
		held_left -= delta
		speed = 0.0
		_jump_wanted = 0.0
	var target := dir * speed
	var on_floor := is_on_floor()
	var a := ACCEL if on_floor else AIR_ACCEL
	velocity.x = move_toward(velocity.x, target.x, a * maxf(speed, WALK_SPEED) * delta)  # (knocked down = speed 0: still
	velocity.z = move_toward(velocity.z, target.z, a * maxf(speed, WALK_SPEED) * delta)  # slow to a stop, F234)
	if fight and fight.dodging() and held_left <= 0.0:
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
			and (body == null or body.use_stamina(JUMP_STAMINA * (prog.jump_stamina_mult() if prog else 1.0))):
		velocity.y = JUMP_SPEED * (prog.jump_speed_mult() if prog else 1.0)
		_jumps += 1
		_jump_wanted = 0.0
		_since_floor = COYOTE_TIME + 1.0  # no double jump
	elif not on_floor:
		velocity.y -= _gravity * delta
	# Ladders (rope or built): hold forward (or jump) to climb, 4 stamina a second (doc 6.2).
	var ladder := _ladder_here()
	if ladder and playing and (Input.is_action_pressed("move_forward") or Input.is_action_pressed("jump")) \
			and (body == null or body.drain_stamina(LADDER_STAMINA, delta)):
		velocity.y = LADDER_SPEED
	elif ladder and not is_on_floor():
		velocity.y = maxf(velocity.y, -1.5)  # hold on: slide down slowly
	var shoved := _shove.length() > 0.05  # knocked aside by a charge (F111): fades out quickly
	if shoved:
		velocity.x += _shove.x
		velocity.z += _shove.z
	move_and_slide()
	if shoved:  # (only for this step: added every frame and kept, it piled up and threw you 100 m, F234)
		velocity.x -= _shove.x
		velocity.z -= _shove.z
		_shove = _shove.move_toward(Vector3.ZERO, SHOVE_FADE * delta)
	_guard_fall(delta)
	_send_body_xp(delta)
	model.set_climbing(ladder and not is_on_floor(), delta)  # hands on the rungs
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
		var ps_here: GameAuthority.PlayerState = GameAuthority.instance.get_player(peer_id) if GameAuthority.instance else null
		model.swing(SWING_TIME * (ps_here.progress.dig_swing_mult(Items.kind(ps_here.selected_item()) == "axe") if ps_here else 1.0))  # Mining / Woodcutting ★25
		if _online():
			_net_swing.rpc()

	# Safety net: if we ever fall out of the cave, go back to the start.
	if global_position.y < CaveMaker.Y_MIN - 30.0:
		global_position = _respawn_point
		velocity = Vector3.ZERO


func _process(delta: float) -> void:
	if is_local and fight:
		model.set_held(fight.item())
		var shield := fight.shield_item()
		model.set_shield(shield)  # (on the left arm, the weapon in the right hand)
		model.set_pose(fight.is_blocking(), fight.aiming(), shield != "")
		# Friends see what we hold and how we stand (sent only when it changes).
		var worn := _worn_items()
		model.set_wear(worn)
		var look := [fight.item(), fight.is_blocking(), fight.aiming(), shield, worn]
		_look_timer -= delta
		if (look != _sent_look or _look_timer <= 0.0) and _online():
			_sent_look = look
			_look_timer = 2.0  # also every 2 s, so friends who join late catch up
			_net_look.rpc(look[0], look[1], look[2], look[3], look[4])
	if not is_local:
		if ragdoll and ragdoll.down():
			return  # (the rag doll places a friend's dwarf, pulled toward where its owner has it)
		var before := global_position
		global_position = global_position.lerp(_net_pos, minf(1.0, delta * 15.0))
		model.rotation.y = lerp_angle(model.rotation.y, _net_yaw, minf(1.0, delta * 15.0))
		# A friend's legs walk/run at the speed their dwarf is moving on our screen.
		var moved := Vector2(global_position.x - before.x, global_position.z - before.z).length()
		_net_speed = lerpf(_net_speed, moved / maxf(delta, 0.001), minf(1.0, delta * 8.0))
		model.set_motion(_net_speed, absf(global_position.y - before.y) < delta * 3.0, false)
		model.set_sitting(_net_sitting, delta)
		return
	_pose_timer -= delta
	if _pose_timer <= 0.0 and _online():
		_pose_timer = POSE_SEND_TIME
		_net_pose.rpc(global_position, model.rotation.y)
	# The camera follows smoothly up and down, so stepping up a ledge doesn't jolt.
	# Zoomed in, the camera looks at the dwarf itself (chest height, no shoulder offset); zoomed out, over the
	# shoulder as before (owner, Nov 16: zooming went to the middle of the screen, not to the dwarf).
	var near := clampf((_spring.spring_length - ZOOM_MIN) / (CAMERA_DISTANCE - ZOOM_MIN), 0.0, 1.0)
	# Aiming (F452, owner Nov 20: "I'm looking at his head"): whatever the zoom, the camera slides to a fixed spot over
	# his right shoulder, so the crosshair sits just past it. Letting go slides back to the normal camera.
	_aim_t = move_toward(_aim_t, 1.0 if fight and fight.aiming() else 0.0, delta * 6.0)
	var aim_k := smoothstep(0.0, 1.0, _aim_t)
	var want_y := global_position.y + lerpf(lerpf(1.0, SHOULDER.y, near), AIM_CAMERA.y, aim_k)
	if is_nan(_cam_y) or absf(_cam_y - want_y) > 2.0:
		_cam_y = want_y
	_cam_y = lerpf(_cam_y, want_y, minf(1.0, delta * 14.0))
	_cam_yaw.global_position = Vector3(global_position.x, _cam_y, global_position.z)
	_cam_yaw.rotation.y = _yaw
	_cam_pitch.rotation.x = _pitch
	_spring.position = Vector3(lerpf(lerpf(0.08, SHOULDER.x, near), AIM_CAMERA.x, aim_k), 0, 0)
	var want_len := lerpf(_zoom, AIM_CAMERA.z, aim_k)
	_spring.spring_length = lerpf(_spring.spring_length, want_len, minf(1.0, delta * 10.0))  # smooth zoom
	_shake = maxf(0.0, _shake - delta * 4.0)
	camera.fov = lerpf(camera.fov, 32.0 if fight and fight.aiming() else 72.0, minf(1.0, delta * 10.0))  # crossbow zoom
	camera.h_offset = randf_range(-1, 1) * _shake * 0.06
	camera.v_offset = randf_range(-1, 1) * _shake * 0.06


## What's under the crosshair, up to `reach` meters from the dwarf (building reaches further).
func aim_far(reach: float) -> Dictionary:
	var from := camera.global_position
	var forward := -camera.global_basis.z
	var q := PhysicsRayQueryParameters3D.create(from, from + forward * (_spring.spring_length + reach + 2.0))
	q.collision_mask = World.TERRAIN_LAYER | GlowField.GLOW_LAYER | Station.STATION_LAYER | Monster.MONSTER_LAYER | PoiField.POI_LAYER | PieceNode.PIECE_LAYER | Storage.BOX_LAYER 		| Ragdoll.LAYER  # (chests: the hammer picks them up; a fallen body: mine it the moment it dies)
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
	var chest := global_position + Vector3.UP
	var end := from + forward * (_spring.spring_length + GameAuthority.REACH + 2.0)
	# Start the ray level with the dwarf, not at the camera: a root, crystal or monster between the camera and
	# the dwarf was hit instead of what you aim at (owner, Nov 17: "the axe isn't axing the right stuff").
	from += forward * maxf(0.0, (chest - from).dot(forward) - 0.4)
	var q := PhysicsRayQueryParameters3D.create(from, end)
	q.collision_mask = World.TERRAIN_LAYER | GlowField.GLOW_LAYER | Station.STATION_LAYER | Monster.MONSTER_LAYER | PoiField.POI_LAYER \
		| Ragdoll.LAYER  # (stone corpses: walk-through since F495, so the swing must look for them on their own layer, owner Nov 20)
	q.exclude = [get_rid()]
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return {}
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
			nm = "Root (%d chops left)" % spot.get("chops", 1)
		elif spot.get("kind") == GlowPlacer.ROOT_DANGLE:
			nm = "Thin Root · click to pull it out"
		elif spot.get("kind") == GlowPlacer.GIANT:
			nm = "Giant Mushroom (%d chops left · copper axe)" % spot.get("chops", 1)
		if k.get("tool", "") == "hand":  # mushrooms, fiber, twigs, thin roots: E picks them (owner, Nov 17)
			if spot.get("kind") == GlowPlacer.ROOT_DANGLE:
				nm = "Thin Root"
			return {kind = "glow", name = nm + " · E to pick", pick_glow = auth.glow.id_of(hit.collider)}
		return {kind = "glow", name = nm}
	if hit.collider is PieceNode and Pieces.LIST[(hit.collider as PieceNode).piece].get("use", "") == "sit":
		var chair: PieceNode = hit.collider
		return {kind = "seat", name = "%s · E to sit" % Pieces.LIST[chair.piece].name, seat = chair}
	if hit.collider is PieceNode and (hit.collider as PieceNode).piece in Pieces.DOORS:
		var door: PieceNode = hit.collider
		return {kind = "door", name = "Door · E to %s" % ("close" if door.is_open else "open"), door_uid = door.uid}
	if hit.collider is Station:
		var st: Station = hit.collider
		return {kind = "station", name = "%s · E to use" % Items.display_name(st.kind), station = st}
	var poi_id := PoiField.poi_id_of(hit.collider)
	if poi_id >= 0 and auth:
		return {kind = "poi", poi_id = poi_id, name = "Rune shrine · E to take"}
	var loot_key := LootProps.key_of(hit.collider)  # lootable decor: a coin chest, an ingot cart... (Nov 22: E takes)
	if loot_key != "" and auth and auth.loot_props:
		var li := auth.loot_props.use_info(loot_key)
		if not li.is_empty():
			return li
	var thing := DungeonBuild.id_of(hit.collider)  # a dungeon's round door or lever (owner, Nov 20: E opens / pulls)
	if thing >= 0 and DungeonBuild.instance:
		var use := DungeonBuild.instance.use_info(thing)
		if not use.is_empty():
			return {kind = "dungeon", name = use.name, dungeon_use = use.use}
	var box_id := Storage.box_id_of(hit.collider)
	if box_id >= 0 and auth:
		var box := auth.storage.get_box(box_id)
		var nm: String = {"grave": "Your grave", "builder": "Builder's Chest", "rebuild": "Rebuilding Chest"}.get(box.get("kind", ""), "Chest")
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
	if auth == null:
		return
	# Hanging roots between you and what you aim at break first (they have no solid shape: the aim line finds them).
	var chest := global_position + Vector3.UP * 1.1
	var reach_to: Vector3 = hit.position if not hit.is_empty() else chest + (-camera.global_basis.z) * GameAuthority.REACH
	if auth.curtains:
		var sid := auth.curtains.strand_near_ray(chest, reach_to)
		if sid >= 0:
			auth.ask_break_hanging("strand", str(sid))
			Fx.burst(get_parent(), auth.curtains.top_of(sid).lerp(reach_to, 0.5), Color(0.4, 0.3, 0.2), 8, 2.0)
			return
	if auth.clutter:
		var rid := auth.clutter.hroot_near_ray(chest, reach_to)
		if rid != "":
			auth.ask_break_hanging("hroot", rid)
			Fx.burst(get_parent(), reach_to, Color(0.45, 0.32, 0.2), 10, 2.5)
			_shake = 0.3
			return
	if hit.is_empty():
		return
	var statue_id := Statue.id_of(hit.collider)
	if statue_id >= 0:  # a dead creature turning to stone (owner, Nov 18): mine it for its stone and loot, even at once
		auth.monsters.ask_hit_statue(statue_id)
		return
	if hit.collider is CollisionObject3D and (hit.collider as CollisionObject3D).collision_layer == Ragdoll.LAYER:
		return  # (a fallen creature's limp pieces: nothing to mine, and don't dig the ground through it)
	var thing_id := DungeonBuild.id_of(hit.collider)
	if thing_id >= 0 and DungeonBuild.instance:  # a dungeon's furniture, rubble or hidden boulder (owner, Nov 19)
		DungeonBuild.instance.ask_hit(thing_id)
		_shake = 0.3
		return
	var boulder_id := Boulders.id_of(hit.collider)
	if boulder_id >= 0:  # a boulder: stone every hit, it bursts after a few (owner, Nov 18)
		auth.ask_hit_boulder(boulder_id)
		return
	var column_id := PoiField.column_id_of(hit.collider)
	if column_id >= 0:  # an old ruin column: stone every hit, it crumbles after a few (owner, Nov 19)
		auth.ask_hit_column(column_id)
		return
	var pillar_id := RootPillars.id_of(hit.collider)
	if pillar_id >= 0:  # a giant root pillar: chop bits of wood off it (F189)
		auth.ask_chop_pillar(pillar_id)
		Fx.burst(get_parent(), hit.position, Color(0.45, 0.32, 0.2), 10, 2.5)
		_shake = 0.3
		return
	var grove_id := GlowGroves.id_of(hit.collider)
	if grove_id >= 0:  # a glow-grove tree: chop wood off it (owner, Nov 19)
		auth.ask_chop_grove(grove_id)
		Fx.burst(get_parent(), hit.position, Color(0.45, 0.32, 0.2), 10, 2.5)
		_shake = 0.3
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
	if hit.collider is Rubble:  # clearing fallen pieces (F90)
		auth.builder.ask_hit_rubble((hit.collider as Rubble).rubble_id)
		Fx.burst(get_parent(), hit.position, Pieces.FAMILIES[(hit.collider as Rubble).family].color, 6)
		_shake = 0.3
		return
	if hit.collider is Station or hit.collider is PieceNode or Storage.box_id_of(hit.collider) >= 0 \
			or (hit.collider is Node and (hit.collider as Node).is_in_group(RuinKit.GROUP)):
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
		if speed >= 5.0:  # running kicks up a little dust
			Fx.dust(get_parent(), global_position + Vector3.UP * 0.05, Color(0.5, 0.45, 0.38), 2, 0.25)


# ---------------------------------------------------------------- fighting (see DwarfFight)

func defense_state() -> Dictionary:
	return fight.defense_state()


func is_invulnerable() -> bool:
	return fight.invulnerable()


func guard_break() -> void:
	fight.guard_break()


## Never lost inside the rock (owner, Nov 18: a beetle's charge knocked him through the floor and out of the map):
## remembers the last floor you stood on, and if your body ends up inside solid rock it puts you back there.
var _safe_spot := Vector3.INF
var _in_rock := 0.0


func _guard_fall(delta: float) -> void:
	var auth := GameAuthority.instance
	if not is_local or auth == null or auth.world == null:
		return
	var w: World = auth.world
	var inside := w.sdf_at(global_position + Vector3.UP * 0.9) < -0.5 and w.sdf_at(global_position + Vector3.UP * 0.3) < -0.5
	if is_on_floor() and not inside:
		_safe_spot = global_position
	_in_rock = _in_rock + delta if inside else 0.0
	if _in_rock > 0.3 and _safe_spot != Vector3.INF:
		global_position = _safe_spot + Vector3.UP * 0.3
		velocity = Vector3.ZERO
		_shove = Vector3.ZERO
		_in_rock = 0.0


## Riding a rope slide (Mossprop Workings, owner Nov 21: "a way to get down that rope back to the first level"): from
## grab point `a` to let-go point `b` (world, where the hands are), the rope sagging a little in the middle. The host
## said yes (MineTraps._ev_slide); we move ourselves, like walking, so everyone sees us through the usual sync.
var _slide := {}
const SLIDE_TOP_SPEED := 9.0
const SLIDE_SPEED_UP := 4.0
const SLIDE_SAG := 0.25


func slide_down(a: Vector3, b: Vector3) -> void:
	_slide = {a = a, b = b, t = 0.0, speed = 1.5, length = maxf(a.distance_to(b), 0.1)}
	velocity = Vector3.ZERO
	_shove = Vector3.ZERO


func sliding() -> bool:
	return not _slide.is_empty()


func _slide_step(delta: float) -> void:
	var a: Vector3 = _slide.a
	var b: Vector3 = _slide.b
	_slide.speed = minf(float(_slide.speed) + SLIDE_SPEED_UP * delta, SLIDE_TOP_SPEED)
	var t := minf(float(_slide.t) + float(_slide.speed) * delta / float(_slide.length), 1.0)
	_slide.t = t
	var hands := a.lerp(b, t) - Vector3.UP * SLIDE_SAG * 4.0 * t * (1.0 - t)
	global_position = hands - Vector3.UP * lerpf(1.75, 1.45, t)  # (feet just over the ground at the end)
	var flat := (b - a) * Vector3(1, 0, 1)
	if flat.length() > 0.01:
		model.rotation.y = lerp_angle(model.rotation.y, atan2(-flat.x, -flat.z), minf(1.0, delta * 10.0))
	model.set_climbing(true, delta)  # (hands up on the rope)
	model.set_motion(0.0, false, false)
	if t >= 1.0:
		_slide = {}
		velocity = flat.normalized() * 3.0 if flat.length() > 0.01 else Vector3.ZERO


## Bear jaws hold your leg for `secs` (0 = let go): you can't walk or jump, you can still swing and look round.
var held_left := 0.0


func hold_legs(secs: float) -> void:
	held_left = secs
	if secs > 0.0:
		velocity.x = 0.0
		velocity.z = 0.0
		_shake = maxf(_shake, 0.5)


## Knocked to one side (a beetle's charge hit you, F111): `push` is the sideways speed in m/s.
var _shove := Vector3.ZERO
const SHOVE_FADE := 18.0


func shove(push: Vector3) -> void:
	_shove = Vector3(push.x, 0.0, push.z)
	_shake = maxf(_shake, 0.6)


func knock_down() -> void:
	fight.knock_down()


var ragdoll: DwarfRagdoll  ## made on the first big hit


## A big hit (F237: mine cart, swinging boulder or anvil, spiked flail): the dwarf goes floppy like a rag doll,
## tumbles, then gets back up. push = which way and how hard (m/s), e.g. cart_direction * 8.
## Only the host's call counts (trap code runs there); every player then sees the same tumble.
## Damage is up to the caller.
func big_hit(push: Vector3) -> void:
	if multiplayer.is_server():
		_net_big_hit.rpc(push)


@rpc("any_peer", "call_local", "reliable")
func _net_big_hit(push: Vector3) -> void:
	if multiplayer.get_remote_sender_id() > 1:
		return  # only the host throws dwarfs
	if model.dwarf_rig == null:  # (the old looks have no skeleton to go floppy)
		if fight:
			knock_down()
		return
	if _seat != null and is_local:
		stand_up()
	if ragdoll == null:
		ragdoll = DwarfRagdoll.new()
		ragdoll.dwarf = self
		var sk := model.dwarf_rig.skeleton
		sk.add_child(ragdoll)
		for c in sk.get_children():  # before DwarfProportions, so he stays dwarf-shaped
			if c is SkeletonModifier3D:
				sk.move_child(ragdoll, c.get_index())
				break
	ragdoll.start(push)


func got_parry() -> void:
	fight.got_parry()
	_shake = 0.5


func add_shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


var _tree: AnimationTree = null


## A hit lands: his animation holds still for a blink, then carries on (owner, Nov 18: "juicy hits").
func hit_stop(seconds: float) -> void:
	if _tree == null:
		var found := find_children("*", "AnimationTree", true, false)
		if found.is_empty():
			return
		_tree = found[0]
	_tree.active = false
	get_tree().create_timer(seconds, true, false, true).timeout.connect(func() -> void:
		if is_instance_valid(_tree):
			_tree.active = true)


## Are we touching a ladder (a rope ladder station, or a built Ladder piece)?
func _ladder_here() -> bool:
	var auth := GameAuthority.instance
	if auth == null:
		return false
	for st in auth.stations.values():
		if st.kind != "rope_ladder":
			continue
		var d: Vector3 = global_position - st.global_position
		if Vector2(d.x, d.z).length() < 0.9 and d.y > -0.5 and d.y < Station.LADDER_HEIGHT + 0.5:
			return true
	if DungeonBuild.instance and DungeonBuild.instance.ladder_at(global_position):
		return true  # (Old Pell's shafts)
	return auth.builder != null and auth.builder.ladder_at(global_position)


## Turn to face where the camera looks (when attacking).
func face_camera() -> void:
	model.rotation.y = _yaw


func _holding_hammer() -> bool:
	var auth := GameAuthority.instance
	var ps := auth.get_player(peer_id) if auth else null
	return ps != null and ps.selected_item() == "build_hammer"


## Every few seconds, tell the host how much we ran and jumped (it checks and gives the XP).
func _send_body_xp(delta: float) -> void:
	_body_xp_wait += delta
	if _body_xp_wait < 5.0:
		return
	if is_local and (_run_time > 0.0 or _jumps > 0 or shield_blocks > 0) and GameAuthority.instance:
		GameAuthority.instance.ask_body_xp(_run_time, _jumps, shield_blocks)
	_body_xp_wait = 0.0
	_run_time = 0.0
	_jumps = 0
	shield_blocks = 0


func _progress() -> Progression:
	var auth := GameAuthority.instance
	var ps := auth.get_player(peer_id) if auth else null
	return ps.progress if ps else null


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
	var swift: float = Gems.bonus(ps.inventory.get_slot(ps.hand_slot())).get("mine_stamina", 0.0)
	var skill := "woodcutting" if Items.kind(ps.selected_item()) == "axe" else "mining"
	return ps.vitals.use_stamina(SWING_STAMINA * ps.progress.swing_stamina_mult(skill) * (1.0 - swift))


## The host's answer to our pickaxe hit (arrives right away when playing alone).
func _on_dig_feedback(pid: int, result: Dictionary) -> void:
	if pid != peer_id or not result.has("point"):
		return
	var at: Vector3 = result.point
	var col := Fx.material_color(result.get("material", Mat.STONE))
	var soft: bool = result.get("material", Mat.STONE) in [Mat.MOSS, Mat.DIRT, Mat.CLAY]
	if result.get("state", "") in ["hit", "dug"]:
		FreezeWatch.hits += 1
	match result.get("state", ""):
		"hit":
			if not soft and not result.get("statue", false):  # cracks spread on rock with each hit (F261); dirt and moss just
				# crumble; a stone corpse cracks itself (Statue.hit): owner, Nov 20, the cracks showed on the floor
				DigCracks.hit(get_parent(), at, result.get("normal", Vector3.UP), int(result.get("hits", 1)), int(result.get("needed", 3)))
			Fx.burst(get_parent(), at, col, 6, 2.5)
			_shake = 0.35
			Sfx.play("dig_soft" if soft else "dig_rock", at)
		"dug":
			DigCracks.clear()
			var n: Vector3 = result.get("normal", Vector3.UP)
			if not soft and not result.get("statue", false):  # rock bursts into real chunks (F261); dirt, moss and clay just crumble (owner, Nov 18); a statue bursts itself, sized to it (Statue.remove)
				RockShatter.burst(get_parent(), at - n * 0.55, n, col, int(result.get("material", -1)))
				if not result.get("boulder", false):  # a second burst, like a boulder (owner, Nov 18: "this is what I want from mining the rock")
					RockShatter.burst(get_parent(), at - n * 0.3, (n + Vector3.UP * 0.6).normalized(), col, int(result.get("material", -1)))
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
			if k == "fiber":  # a grass tuft, fern or small root broke (F197): a puff of green bits
				Fx.burst(get_parent(), at + Vector3.UP * 0.15, Color(0.6, 0.66, 0.38), 12, 2.5)
			Sfx.play("crystal" if k.begins_with("crystal") else ("chop" if k in GlowPlacer.TALL else "pickup"), at)


# ---------------------------------------------------------------- sitting

## Sit down on `chair` (a built seat): turned to face the way the seat faces.
func sit_on(chair: PieceNode) -> void:
	if not is_instance_valid(chair) or not is_on_floor():
		return
	_seat = chair
	velocity = Vector3.ZERO
	if _online():
		_net_sit.rpc(true)


func stand_up() -> void:
	if _seat == null:
		return
	if is_instance_valid(_seat):  # step off the front of the seat
		var front := _seat.global_basis.z.normalized()
		global_position = _seat.global_position + front * (float(Pieces.LIST[_seat.piece].size.z) * 0.5 + 0.45) + Vector3.UP * 0.05
	_seat = null
	if _online():
		_net_sit.rpc(false)


func _sit_step(delta: float) -> void:
	var playing := input_enabled and Controls.captured()
	var wants_up := playing and (Input.get_vector("move_left", "move_right", "move_forward", "move_back").length() > 0.1 		or Input.is_action_just_pressed("jump") or Input.is_action_pressed("dig"))
	if not is_instance_valid(_seat) or _seat.is_queued_for_deletion() or wants_up or bot_move != Vector2.ZERO:
		stand_up()
		return
	var front := _seat.global_basis.z.normalized()
	global_position = _seat.global_position + Vector3.UP * (float(Pieces.LIST[_seat.piece].get("seat", 0.5)) - SIT_HIPS) - front * 0.06
	velocity = Vector3.ZERO
	model.rotation.y = atan2(-front.x, -front.z)  # the dwarf faces -Z: turn him to the seat's front
	model.set_motion(0.0, true, false)
	model.set_sitting(true, delta)


## Is this dwarf sitting (for the HUD and tests)?
func sitting() -> bool:
	return _seat != null


@rpc("authority", "reliable")
func _net_sit(on: bool) -> void:
	_net_sitting = on


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


## A friend's dwarf: what they hold, and whether they block / aim (only looks).
@rpc("authority", "reliable")
func _net_look(item: String, blocking: bool, aiming: bool, shield: String, worn: Array = []) -> void:
	model.set_held(item)
	model.set_shield(shield)
	model.set_pose(blocking, aiming, shield != "")
	model.set_wear(worn)


## What the dwarf wears, from the equipment slots (head, chest, legs, feet), as the looks
## DwarfRig knows: "spore_mask", or "armor_<slot>_<look>" (look = leather, copper, shell…).
func _worn_items() -> Array:
	var out := []
	var auth := GameAuthority.instance
	var ps: GameAuthority.PlayerState = auth.get_player(peer_id) if auth else null
	if ps == null:
		return out
	for part in ["head", "chest", "legs", "feet"]:
		var id := ps.inventory.equipped(part)
		if id == "":
			continue
		var look: String = Items.info(id).get("look", "")
		if look == "mask":
			out.append("spore_mask")
		elif look != "":
			out.append("armor_%s_%s" % [part, look])
	return out


## A friend's dwarf flinched, ate, threw, shot… (only looks).
@rpc("authority", "reliable")
func _net_react(what: String, duration := -1.0) -> void:
	model.react(what, duration)
