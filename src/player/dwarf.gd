class_name Dwarf
extends CharacterBody3D
## The dwarf: walking, running, jumping, the camera behind them, and swinging the pickaxe.
## It never changes the world itself: it ASKS the GameAuthority (ask_*).
## In co-op, other players' dwarfs are "puppets" (is_local = false): no camera,
## no controls, they just copy the position their owner sends over the network.

const BODY_LAYER := 8  ## players' bodies (friendly fire bolts can hit them)
const WALK_SPEED := 3.0  ## (owner, Nov 22: 4 m/s made his short legs spin "like anime"; was 4)
const LADDER_SPEED := 2.5
const LADDER_STAMINA := 4.0
const RUN_SPEED := 5.2   ## (was 6.5, same reason)
const JUMP_SPEED := 5.5         ## about 1.5 m high
const COYOTE_TIME := 0.15       ## you can still jump this long after walking off an edge
const JUMP_BUFFER := 0.15       ## a jump pressed this long before landing still counts
const STEP_HEIGHT := 0.5        ## ledges up to this tall are stepped up without jumping
const ACCEL := 14.0
const AIR_ACCEL := 4.0
const SPEED_BLEND := 20.0  ## m/s²: softens other speed changes (blocking, buffs); walk → sprint is ramped by _sprint_t (F775)
const SWING_TIME := 0.55
const CAMERA_DISTANCE := DwarfFeel.CAM_DISTANCE  ## starting camera distance (tune it in dwarf_feel.gd)
const ZOOM_MIN := 1.1
const ZOOM_MAX := 8.0
const ZOOM_STEP := 0.5
## The normal camera: over his right shoulder, looking at his chest (height: DwarfFeel.CAM_AIM_HEIGHT, F469).
const SHOULDER := Vector3(0.55, DwarfFeel.CAM_AIM_HEIGHT, 0.0)
## Where the camera sits while aiming (F452): x = to his right, y = height, z = distance behind.
const AIM_CAMERA := Vector3(0.45, 0.9, 2.0)
## F927 (owner, Nov 27: "aiming and looking up shows the back of the dwarf"): looking up while aiming, the camera's
## pivot rises over his helmet, slides further right and comes in a little (so it doesn't hit the floor behind him):
## the dwarf sits low on the left and the crosshair line passes clear of him.
const AIM_UP_RAISE := 0.55
const AIM_UP_SIDE := 0.4
const AIM_UP_IN := 0.6
## F946 (owner, Nov 28: looking straight up "you see the inside of his belly"): not aiming, the floor behind him
## pushed the camera into him. Looking up, its pivot rises and slides out like F927's; if it still ends up this
## close (m) to his middle line, he is hidden on your own screen until it moves out again.
const LOOK_UP_RAISE := 0.5
const LOOK_UP_SIDE := 0.3
const CAM_HIDE_GAP := 0.5
const CAM_SHOW_GAP := 0.6
var _cam_hid := false
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
var _speed_smooth := WALK_SPEED  ## eases toward the real target speed (F701), instead of snapping to it
var _sprint_t := 0.0  ## 0 = walking speed, 1 = full sprint: ramps up over DwarfFeel.SPRINT_RAMP_TIME (F775)
var _skid := false  ## skidding to a stop after a sprint (F775)
var _winded := false  ## sprint stopped to keep a dodge's worth of energy; waits to catch its breath (F775)
var carry := {}  ## your load (F793): {weight, heavy, max, load, speed} from ItemWeights.for_player, refreshed 5x a second
var _carry_wait := 0.0
var running := false  ## running this frame (DwarfFight stops a crossbow reload when you run)
var _was_playing := false  ## (F494: Shift is let go when you come back to the game)
var _layout := -2  ## the keyboard language last frame (-2 = not looked yet; F494: Ctrl+Shift switches it)
var _move_dir_buffer := Vector3.ZERO  ## last direction you were really moving in
var _move_dir_buffer_age := 999.0  ## seconds since then
const MOVE_DIR_BUFFER_TIME := 0.15  ## Ctrl+W can ghost a frame on some keyboards (F494-style); still "moving" this long
## after, so a dodge right then still rolls where you were walking instead of backward (F702).


## Owner, Nov 20 (F494, 3rd time: "sometimes I can still run without pressing Shift"): when the game window loses
## the keyboard (another window, Alt-Tab, a pop-up) while Shift is down, it never hears Shift come back up, so it
## thought you still held it. Losing the window now lets go of every key.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		for act in InputMap.get_actions():
			Input.action_release(act)
var bot_jump := false
var bot_run := false  ## tests: hold Shift
var bot_dodge := false  ## tests: start a dodge this frame, like a real press (skips Input's just-pressed timing)

var _since_floor := 0.0
var _run_time := 0.0  ## Running and Jumping practice not yet told to the host
var _jumps := 0
var shield_blocks := 0  ## hits blocked or parried with a shield, not yet told to the host
var _body_xp_wait := 0.0
var _jump_wanted := 0.0
var _jump_air_expected := 0.0  ## F807: how long this jump should hang in the air, 0.0 off a real jump (a step off a ledge)
var _jump_elapsed := 0.0  ## F807: seconds airborne so far this jump, so the hang guess below can keep refreshing instead of being stuck with its first guess
var _cam_y := NAN
var _cam_tick := 0  ## the physics frame the camera's height last glided on (F781)
var _zoom := CAMERA_DISTANCE  ## where the mouse wheel wants the camera
var _l_down := 0  ## L presses: odd while one is held and not yet used (tap = stow, hold = refill)

var _yaw := 0.0
var _pitch := -0.25
var _cam_yaw: Node3D
var _cam_pitch: Node3D
var _spring: SpringArm3D  ## only feels for rock (F766): the camera itself is placed by hand, so it can glide back out
var _cam_fade := CameraFade.new()  ## built pieces in the way turn a bit see-through (F807)
var _cam_side := 0.0  ## how far over his shoulder the camera is right now (a door frame beside him can narrow it, F806)
var _cam_len := CAMERA_DISTANCE  ## how far behind him the camera really is right now (rock can push it in)
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
	collision_mask = World.TERRAIN_LAYER | Monster.MONSTER_LAYER | PieceNode.PIECE_LAYER  # (owner, Nov 18: you could walk right through a beetle; F781: the spiral stairs' rails and post are on the piece layer only)
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
	_cam_pitch.add_child(camera)  # (not on the spring arm: that one snaps the camera both ways; F766 wants a slow glide out)
	camera.current = true


## Set by Main: the build hammer's mode (Shift + wheel lifts its piece instead of zooming, F97).
var build_mode: BuildMode


func build_lifts() -> bool:
	return build_mode != null and build_mode.active()


## F494/F805, 5th time (owner, Nov 25: "I'm not holding Shift, but he's still sprinting"): the game sometimes never
## hears Shift come back up, and each fix so far guessed one way that happens. This one doesn't guess: every mouse move
## and key press carries the real Shift state from Windows, so if "run" (on Shift) thinks it is held but the event says
## Shift is up, let go of it. The mouse moves all the time while playing, so a stuck sprint heals itself at once.
func _input(event: InputEvent) -> void:
	if is_local and shift_is_really_up(event, Input.is_action_pressed("run")):
		Input.action_release("run")


## True when `event` says Shift is up while "run" (bound only to Shift) still counts as held.
static func shift_is_really_up(event: InputEvent, run_held: bool) -> bool:
	if not run_held or not (event is InputEventMouseMotion or event is InputEventMouseButton or event is InputEventKey):
		return false
	var ev := event as InputEventWithModifiers
	if ev.shift_pressed:
		return false
	if event is InputEventKey and (event as InputEventKey).keycode == KEY_SHIFT:
		return false  # (the Shift key's own events: pressing it reports itself as not yet held)
	for e in InputMap.action_get_events("run"):
		if not (e is InputEventKey and ((e as InputEventKey).keycode == KEY_SHIFT or (e as InputEventKey).physical_keycode == KEY_SHIFT)):
			return false  # run is on another key too (rebound): Shift tells us nothing
	return true


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
	# L: tap = put the lantern away / take it out; hold ~0.5 s = refill it (owner, Nov 27)
	if event.is_action_pressed("stow_lantern"):
		_l_down += 1
		var press := _l_down
		get_tree().create_timer(0.5).timeout.connect(func():
			if _l_down == press and Input.is_action_pressed("stow_lantern"):
				_l_down += 1  # held: refill, and the release no longer counts as a tap
				auth.ask_refill())
	if event.is_action_released("stow_lantern") and _l_down % 2 == 1:
		_l_down += 1
		if ps and Lantern.has_lantern(ps):
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
	# F959 (owner, Nov 28): "it says the mace is equipped, but I don't see it in my hands": right click with empty
	# hands while a weapon or shield is on (but put away) tells you how to get it out, instead of failing silently.
	if ps and event.is_action_pressed("use") and Controls.captured() and fight.item() == "" and ps.can_draw() 			and not ps.weapon_drawn:
		var worn := ps.inventory.equipped("weapon")
		worn = worn if worn != "" else ps.inventory.equipped("shield")
		fight.message.emit("Your %s is put away. Press F to draw it." % Items.display_name(worn), Color.WHITE)
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
	collision_mask = 0 if on else World.TERRAIN_LAYER | Monster.MONSTER_LAYER | PieceNode.PIECE_LAYER  # through rock (and back to solid)
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
	if bot_run and playing and iv.length() > 0.1:
		running = true
	dir = (Basis(Vector3.UP, _yaw) * Vector3(iv.x, 0, iv.y))
	var body := _vitals()
	var prog := _progress()
	_update_carry(delta)
	var overloaded: bool = carry.get("load", ItemWeights.Load.LIGHT) == ItemWeights.Load.OVERLOADED
	if overloaded:
		running = false  # F793: too heavy to sprint
	var equip_mult := 1.0
	if is_local and GameAuthority.instance:  # putting something on (F826): the ring fills, you walk very slowly
		GameAuthority.instance.tick_equip(delta)
		var me = GameAuthority.instance.get_player(peer_id)
		if me and not me.equip_job.is_empty():
			equip_mult = EquipTime.WALK_MULT
			running = false
	# F775: one energy bar for sprint, dodge and attack, but sprinting never spends the last dodge.
	if body:
		var keep := minf(Combat.DODGE_STAMINA * (prog.dodge_stamina_mult() if prog else 1.0) * DwarfFeel.SPRINT_KEEPS_DODGES, body.max_stamina() * 0.5)
		if body.stamina <= keep + RUN_STAMINA * delta * 2.0:  # (stop a step early: one more step would dip under it)
			_winded = true
		elif body.stamina >= keep + DwarfFeel.SPRINT_CATCH_BREATH:
			_winded = false
		if _winded:
			running = false
	if running and body and not body.drain_stamina(RUN_STAMINA * (prog.run_stamina_mult() if prog else 1.0), delta):
		running = false  # out of breath
	if dir.length() > 0.1:
		_move_dir_buffer = dir
		_move_dir_buffer_age = 0.0
	else:
		_move_dir_buffer_age += delta
	var dodge_dir := dir if dir.length() > 0.1 else (_move_dir_buffer if _move_dir_buffer_age < MOVE_DIR_BUFFER_TIME else Vector3.ZERO)
	# A dodge direction that's the dead opposite of how your body is actually already moving, at real speed, is
	# almost always one glitched input reading (the same keyboard/mouse quirk as F494), not a real instant 180°
	# turn — a body can't flip direction in 1/60th of a second, but a key or the camera yaw misreading one frame
	# can. So trust real momentum over that one bad reading (owner, PC, Nov 22: "I dodge backwards, then it dodges
	# forward, so I go back in place" — the buffer above only catches a dropped/zero frame, not a flipped one).
	var real_v := Vector2(velocity.x, velocity.z)
	if dodge_dir.length() > 0.1 and real_v.length() > WALK_SPEED * 0.5:
		var real_dir3 := Vector3(real_v.x, 0, real_v.y)
		if dodge_dir.normalized().dot(real_dir3.normalized()) < -0.5:
			dodge_dir = real_dir3
	var fight_mult := fight.step(delta, playing, dodge_dir) if fight else 1.0
	if fight and (fight.is_blocking() or fight.stagger > 0.0):
		running = false
	if running:
		_run_time += delta
	_run_streak = _run_streak + delta if running else 0.0
	var burst := 1.3 if running and _run_streak < 1.0 and prog and prog.has_star("running", 25) else 1.0  # Running ★25
	# Heavy legs: walk → sprint ramps up over SPRINT_RAMP_TIME, and back down over SPRINT_SLOW_TIME (F775).
	_sprint_t = minf(1.0, _sprint_t + delta / DwarfFeel.SPRINT_RAMP_TIME) if running else maxf(0.0, _sprint_t - delta / DwarfFeel.SPRINT_SLOW_TIME)
	var sprint_k := smoothstep(0.0, 1.0, _sprint_t)
	var top_speed := lerpf(WALK_SPEED, RUN_SPEED * (prog.run_speed_mult() if prog else 1.0) * burst, sprint_k) * fight_mult * (body.ailments.speed_mult() * maxf(0.2, 1.0 + body.buff_total("move_speed")) if body else 1.0) * float(carry.get("speed", 1.0)) * equip_mult
	_speed_smooth = move_toward(_speed_smooth, top_speed, SPEED_BLEND * delta)
	var speed := _speed_smooth
	if held_left > 0.0:  # (Lampwick's bear jaws hold your leg: MineTraps)
		held_left -= delta
		speed = 0.0
		_jump_wanted = 0.0
	var on_floor := _grounded()
	if on_floor:
		_jump_air_expected = 0.0  # (F807: only a real jump gets a stretched animation, not a step off a ledge)
	dir = _sprint_turn(dir, sprint_k, delta)  # (the dodge above already took the real key direction, F702)
	var target := dir * speed
	var a := ACCEL if on_floor else AIR_ACCEL
	# Let go of every key mid-sprint: a short skid instead of stopping dead (F775).
	var hv := Vector2(velocity.x, velocity.z)
	if dir.length() > 0.1 or not on_floor or held_left > 0.0 or (fight and fight.dodging()) or hv.length() < 0.3:
		_skid = false
	elif _sprint_t > 0.5:
		if not _skid:
			_kick_dust(DwarfFeel.SPRINT_DUST_AMOUNT * 2)  # skidding to a stop: a bigger cloud
		_skid = true
	if _skid:
		hv = hv.move_toward(Vector2.ZERO, DwarfFeel.SPRINT_STOP_GRIP * delta)
		velocity.x = hv.x
		velocity.z = hv.y
	else:
		velocity.x = move_toward(velocity.x, target.x, a * maxf(speed, WALK_SPEED) * delta)  # (knocked down = speed 0: still
		velocity.z = move_toward(velocity.z, target.z, a * maxf(speed, WALK_SPEED) * delta)  # slow to a stop, F234)
	if fight and fight.dodging() and held_left <= 0.0:
		var dv := fight.dodge_velocity()
		velocity.x = dv.x
		velocity.z = dv.z
	# Jumping, made forgiving: bumpy cave floors can make "am I standing?" flicker,
	# so a jump still works a moment after leaving the ground or just before landing.
	if on_floor and _since_floor > 0.45:
		Sfx.play("land", global_position, -8.0)  # (F707 round 11: boots hit the floor after a jump or a real fall, not a small step down)
	_since_floor = 0.0 if on_floor else _since_floor + delta
	if (playing and Input.is_action_just_pressed("jump")) or bot_jump:
		_jump_wanted = JUMP_BUFFER
		bot_jump = false
	else:
		_jump_wanted = maxf(0.0, _jump_wanted - delta)
	if _jump_wanted > 0.0 and _since_floor <= COYOTE_TIME and velocity.y <= 0.5 and not overloaded \
			and (body == null or body.use_stamina(JUMP_STAMINA * (prog.jump_stamina_mult() if prog else 1.0))):
		velocity.y = JUMP_SPEED * (prog.jump_speed_mult() if prog else 1.0)
		_jump_elapsed = 0.0
		_jump_air_expected = _jump_hang_guess(velocity.y, 0.0)  # (F807: our best guess, refreshed every tick below)
		_jumps += 1
		Sfx.play("jump", global_position, -8.0)
		_jump_wanted = 0.0
		_since_floor = COYOTE_TIME + 1.0  # no double jump
	elif not on_floor:
		velocity.y -= _gravity * delta
		# Keep re-guessing as he falls (F807/F798 🔁): a flat "up and back to launch height" guess, made once at
		# takeoff, was badly wrong for a real long jump — landing lower (a chasm) or higher (a ledge) than where he
		# left changes how long he's really airborne a lot, and the single upfront guess never caught up.
		_jump_elapsed += delta
		_jump_air_expected = _jump_hang_guess(velocity.y, _jump_elapsed)
	# Ladders (rope or built): hold forward (or jump) to climb, 4 stamina a second (doc 6.2).
	var ladder := _ladder_here()
	if ladder and playing and (Input.is_action_pressed("move_forward") or Input.is_action_pressed("jump")) \
			and (body == null or body.drain_stamina(LADDER_STAMINA, delta)):
		velocity.y = LADDER_SPEED
		_ladder_t -= delta
		if _ladder_t <= 0.0:
			_ladder_t = 0.55
			Sfx.play("ladder", global_position, -10.0)  # a rung creaks every step up (F707 round 11)
	elif ladder and not is_on_floor():
		velocity.y = maxf(velocity.y, -1.5)  # hold on: slide down slowly
	var shoved := _shove.length() > 0.05  # knocked aside by a charge (F111): fades out quickly
	if shoved:
		velocity.x += _shove.x
		velocity.z += _shove.z
	floor_max_angle = deg_to_rad(STAIRS_FLOOR_ANGLE if _on_stairs else 52.0)
	move_and_slide()
	_on_stairs = on_steep_stairs(self)
	_slide_off_small_things(delta)
	_stepped_down = on_floor and not is_on_floor() and velocity.y <= 0.01 and not ladder and _try_step_down()
	if shoved:  # (only for this step: added every frame and kept, it piled up and threw you 100 m, F234)
		velocity.x -= _shove.x
		velocity.z -= _shove.z
		_shove = _shove.move_toward(Vector3.ZERO, SHOVE_FADE * delta)
	_guard_fall(delta)
	_send_body_xp(delta)
	model.set_climbing(ladder and not is_on_floor(), delta)  # hands on the rungs
	# (F781: only a wall in front is a step: brushing past one beside you, like a spiral stair's post, lifted you)
	if on_floor and not ladder and velocity.y <= 0.01 and dir.length() > 0.1 and is_on_wall() and get_wall_normal().dot(dir.normalized()) < -0.3:
		_try_step_up(dir * speed * delta)

	# Face where we're going, or where we're digging.
	# A roll locks onto its own real travel direction for its whole length (F702): without this, the body kept
	# chasing wherever the camera/input pointed THIS frame via the usual slow turn below, so a roll that started
	# right after a quick turn (or a direction key let go mid-roll) could visibly tumble a different way than the
	# dwarf actually moved that whole time.
	if fight and fight.dodging():
		var roll_dir := fight.dodge_dir()
		if roll_dir.length() > 0.1:
			model.rotation.y = atan2(-roll_dir.x, -roll_dir.z)
	else:
		var face_dir := dir
		if model.swinging or (playing and Input.is_action_pressed("dig")):
			face_dir = -(Basis(Vector3.UP, fight.swing_yaw(_yaw) if fight else _yaw).z)  # (F790: plus the lock-on lean)
		if face_dir.length() > 0.1:
			var want := atan2(-face_dir.x, -face_dir.z)
			model.rotation.y = lerp_angle(model.rotation.y, want, minf(1.0, delta * 12.0))

	_footsteps(delta, Vector2(velocity.x, velocity.z).length())
	model.set_motion(Vector2(velocity.x, velocity.z).length(), _grounded(), fight != null and fight.dodging(), fight.dodge_expected_duration() if fight else Combat.DODGE_TIME, _jump_air_expected)
	if playing and Input.is_action_pressed("dig") and not model.swinging and not _holding_hammer() and not fight.weapon_mode() and not fight.is_blocking() and _can_swing():  # (no digging behind a raised guard, F836)
		var ps_here: GameAuthority.PlayerState = GameAuthority.instance.get_player(peer_id) if GameAuthority.instance else null
		model.swing(SWING_TIME * (ps_here.progress.dig_swing_mult(Items.kind(ps_here.selected_item()) == "axe") if ps_here else 1.0))  # Mining / Woodcutting ★25
		if _online():
			_net_swing.rpc()

	# Safety net: if we ever fall out of the cave, go back to the start.
	if global_position.y < CaveMaker.Y_MIN - 30.0:
		global_position = _respawn_point
		velocity = Vector3.ZERO


func _process(delta: float) -> void:
	if _step_dy != 0.0 and model:
		_step_dy = move_toward(_step_dy, 0.0, delta * 1.5)
		model.position.y = _step_dy
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
	# F806: measured from the zoom you chose, not from where rock or a wall pushed the camera: that made a loop in
	# doorways (pushed in -> slid to the middle -> room again -> glided out -> slid to the shoulder -> hit the frame).
	# Instead CameraRoom.best_side feels for the shoulder spot with a clear line back (F766: in a narrow tunnel or
	# a doorway that's nearer behind his head, never inside the wall).
	var near := clampf((_spring.spring_length - ZOOM_MIN) / (CAMERA_DISTANCE - ZOOM_MIN), 0.0, 1.0)
	# Aiming (F452, owner Nov 20: "I'm looking at his head"): whatever the zoom, the camera slides to a fixed spot over
	# his right shoulder, so the crosshair sits just past it. Letting go slides back to the normal camera.
	_aim_t = move_toward(_aim_t, 1.0 if fight and fight.aiming() else 0.0, delta * 6.0)
	var aim_k := smoothstep(0.0, 1.0, _aim_t)
	var aim_up := aim_k * smoothstep(0.15, 1.0, _pitch)  # (F927: aiming AND looking up)
	var look_up := (1.0 - aim_k) * smoothstep(0.3, 1.1, _pitch)  # (F946: looking up, not aiming)
	var want_y := global_position.y + lerpf(SHOULDER.y, AIM_CAMERA.y, aim_k) + AIM_UP_RAISE * aim_up 		+ LOOK_UP_RAISE * look_up
	if is_nan(_cam_y) or absf(_cam_y - want_y) > 2.0:
		_cam_y = want_y
	# F781 (owner, Nov 22: climbing the spiral stairs was "very jittery"): the body only moves 60 times a second, but
	# this runs every drawn frame. Gliding the camera's height every frame made him hop up and down against it while
	# climbing, so the height glide now steps along with the body, like the camera's sideways follow always did.
	var tick := Engine.get_physics_frames()
	if tick != _cam_tick:
		var k := minf(1.0, 14.0 * float(mini(tick - _cam_tick, 4)) / Engine.physics_ticks_per_second)
		_cam_y = lerpf(_cam_y, want_y, k)
		_cam_tick = tick
	_cam_yaw.global_position = Vector3(global_position.x, _cam_y, global_position.z)
	_cam_yaw.rotation.y = _yaw
	_cam_pitch.rotation.x = _pitch
	var side := CameraRoom.best_side(_spring, lerpf(lerpf(0.08, SHOULDER.x, near), AIM_CAMERA.x, aim_k) + AIM_UP_SIDE * aim_up 		+ LOOK_UP_SIDE * look_up, [get_rid()])
	_cam_side = side if side < _cam_side else lerpf(_cam_side, side, minf(1.0, delta * DwarfFeel.CAM_RETURN_SPEED))
	_spring.position = Vector3(_cam_side, 0, 0)
	# Looking down pulls the camera out a little, looking up brings it in (F766, "come in close when looking up").
	var tilt := 1.0
	if _pitch < 0.0:
		tilt = lerpf(1.0, DwarfFeel.CAM_LOOK_DOWN_STRETCH, smoothstep(0.0, 1.35, -_pitch))
	else:
		tilt = lerpf(1.0, DwarfFeel.CAM_LOOK_UP_SQUEEZE, smoothstep(0.0, 1.1, _pitch))
	var want_len := lerpf(_zoom * tilt, AIM_CAMERA.z - AIM_UP_IN * aim_up, aim_k)
	_spring.spring_length = lerpf(_spring.spring_length, want_len, minf(1.0, delta * 10.0))  # smooth zoom
	_place_camera(delta)
	_kill_push_step(delta)
	_shake = maxf(0.0, _shake - delta * 4.0)
	var sprint_view := DwarfFeel.SPRINT_WIDER_VIEW * _sprint_t  # (F775: a little wider while sprinting)
	camera.fov = lerpf(camera.fov, 32.0 if fight and fight.aiming() else 72.0 + sprint_view, minf(1.0, delta * 10.0))  # crossbow zoom
	var shake := _shake * 0.06 * SoundSettings.camera_shake  # the Settings slider can turn it down/off (F695)
	camera.h_offset = randf_range(-1, 1) * shake
	camera.v_offset = randf_range(-1, 1) * shake


## F775: a sprinting dwarf can't turn on the spot: his path swings round at most SPRINT_TURN_SPEED turns a second
## (walking still turns at once). `k` = how far into the sprint (0..1).
func _sprint_turn(dir: Vector3, k: float, delta: float) -> Vector3:
	var hv := Vector2(velocity.x, velocity.z)
	if k <= 0.0 or dir.length() <= 0.1 or hv.length() < WALK_SPEED * 0.8:
		return dir
	var cur := atan2(hv.x, hv.y)
	var want := atan2(dir.x, dir.z)
	var step := TAU * lerpf(4.0, DwarfFeel.SPRINT_TURN_SPEED, k) * delta
	var ang := cur + clampf(angle_difference(cur, want), -step, step)
	return Vector3(sin(ang), 0.0, cos(ang)) * dir.length()


## F766: the camera never sits inside rock. The spring arm feels how far back it can go; when rock is closer than the
## camera, the camera jumps in at once; when the rock is gone, it glides back out (no popping).
## Then the rock between the camera and his chest fades to a see-through speckle (terrain.gdshader "see_*").
func _place_camera(delta: float) -> void:
	var room := CameraRoom.room(_spring, [get_rid()])  # (F783: thin pieces like railings don't push it in)
	if room < _cam_len:
		_cam_len = room
	else:
		_cam_len = lerpf(_cam_len, room, minf(1.0, delta * DwarfFeel.CAM_RETURN_SPEED))
	camera.position = _spring.position + Vector3(0, 0, _cam_len)
	_cam_fade.update(get_world_3d(), camera.global_position, _cam_yaw.global_position, delta, [get_rid()], not dev_fly,
		camera)
	_hide_if_camera_inside()


## F946: the camera this close to his middle line (feet to helmet top) would show the inside of him: hide him on
## this screen (only the local camera's view; the others still see him), show him again once it's out a bit more.
func _hide_if_camera_inside() -> void:
	if model == null:
		return
	var c := camera.global_position
	var foot := global_position
	var t := clampf(c.y - foot.y, 0.0, 1.4)
	var gap := Vector2(c.x - foot.x, c.z - foot.z).length() if c.y - foot.y == t 		else c.distance_to(foot + Vector3.UP * t)
	if model.visible and gap < CAM_HIDE_GAP:
		model.visible = false
		_cam_hid = true
	elif _cam_hid and gap > CAM_SHOW_GAP:
		model.visible = true  # (only if this hid him: the photo robots hide him themselves)
		_cam_hid = false


## How long this jump is expected to last in total (F807): `elapsed` seconds in already, moving at `vy` right now.
## Casts straight down to find the real landing height instead of assuming he comes back to the exact height he
## left from — a long jump across a dip or up onto a rise needs more or less time than that flat guess.
func _jump_hang_guess(vy: float, elapsed: float) -> float:
	var drop := 0.0
	var q := PhysicsRayQueryParameters3D.create(global_position, global_position + Vector3.DOWN * 30.0)
	q.collision_mask = World.TERRAIN_LAYER | PieceNode.PIECE_LAYER
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		drop = global_position.y - hit.position.y  # + falling further down than launch, - landing higher up
	var discriminant := vy * vy + 2.0 * _gravity * drop
	var remaining := (vy + sqrt(discriminant)) / _gravity if discriminant >= 0.0 else 2.0 * maxf(vy, 0.0) / _gravity
	return elapsed + maxf(remaining, 0.0)


## What's under the crosshair, up to `reach` meters from the dwarf (building reaches further).
func aim_far(reach: float) -> Dictionary:
	var from := camera.global_position
	var forward := -camera.global_basis.z
	var end := from + forward * (_spring.spring_length + reach + 2.0)
	# (F766: the camera may sit inside rock now; start level with him, like aim(), so the rock behind isn't hit)
	from += forward * maxf(0.0, (global_position + Vector3.UP - from).dot(forward) - 0.4)
	var q := PhysicsRayQueryParameters3D.create(from, end)
	q.collision_mask = World.TERRAIN_LAYER | GlowField.GLOW_LAYER | Station.STATION_LAYER | Monster.MONSTER_LAYER | PoiField.POI_LAYER | PieceNode.PIECE_LAYER | Storage.BOX_LAYER 		| Ragdoll.LAYER  # (chests: the hammer picks them up; a fallen body: mine it the moment it dies)
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty() or (global_position + Vector3.UP).distance_to(hit.position) > reach:
		return {}
	return _piece_of(hit)


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
	return _piece_of(hit)


## A spiral stair's rail or post is its own small body inside the piece (F781): aiming at it means the piece.
static func _piece_of(hit: Dictionary) -> Dictionary:
	var c: Object = hit.get("collider")
	if c is Node and not (c is PieceNode) and (c as Node).get_parent() is PieceNode:
		hit.collider = (c as Node).get_parent()
	return hit


func _aim_info() -> Dictionary:
	var hit := aim()
	var auth := GameAuthority.instance
	var sid := vine_in_aim(hit)
	if sid >= 0:  # F569: glowing vines are picked with E (they're thin and sway: hard to hit with a swing)
		return {kind = "vine", name = "Glowing Vine · E to pick", pick_strand = sid}
	if hit.is_empty():
		return {}
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
	if auth and hit.collider is PieceNode and Pieces.LIST[(hit.collider as PieceNode).piece].get("use", "") == "bed":  # F727
		var bed: PieceNode = hit.collider
		var key := "p%d" % bed.uid
		return {kind = "bed", name = auth.bed_label(key, Pieces.LIST[bed.piece].name), bed_key = key}
	if auth and hit.collider is Station and (hit.collider as Station).kind == "bed":
		var key := "s%d" % (hit.collider as Station).station_id
		return {kind = "bed", name = auth.bed_label(key, "Bed"), bed_key = key}
	if hit.collider is PieceNode and Pieces.LIST[(hit.collider as PieceNode).piece].get("use", "") == "sit":
		var chair: PieceNode = hit.collider
		return {kind = "seat", name = "%s · E to sit" % Pieces.LIST[chair.piece].name, seat = chair}
	if hit.collider is PieceNode and (hit.collider as PieceNode).piece in Pieces.DOORS:
		var door: PieceNode = hit.collider
		return {kind = "door", name = "Door · E to %s" % ("close" if door.is_open else "open"), door_uid = door.uid}
	if hit.collider is Station:
		var st: Station = hit.collider
		# F568: say that benches also upgrade and (freely) repair gear, so the side panel isn't missed.
		var does := "E: craft, upgrade, repair (free)" if st.kind in ["workbench", "anvil"] else "E to use"
		return {kind = "station", name = "%s · %s" % [Items.display_name(st.kind), does], station = st}
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


## F919 (owner, Nov 27: "you can walk on top of small things like the box that gives bolts... it doesn't look good"):
## small loot boxes and crates are marked "small_thing". You bump into their sides, never step up onto them, and if
## you jump on top you slide off.
const SLIDE_OFF_SPEED := 3.5


static func is_small_thing(o: Object) -> bool:
	return o is Node and (o as Node).has_meta("small_thing")


func _slide_off_small_things(_delta: float) -> void:
	if not is_on_floor():
		return
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var o := c.get_collider()
		if is_small_thing(o) and c.get_normal().y > 0.7:
			var shape := c.get_collider_shape() as Node3D  # (the loot body sits at the world's middle; its box doesn't)
			var away := global_position - (shape.global_position if shape else (o as Node3D).global_position)
			away.y = 0.0
			if away.length() < 0.05:
				away = -model.global_transform.basis.z if model else Vector3.FORWARD
			global_position += away.normalized() * SLIDE_OFF_SPEED * get_physics_process_delta_time()
			return


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
	if is_small_thing(hit.get_collider()):
		return  # F919: a crate is something you bump into, not a step
	var y0 := global_position.y
	global_position = ahead.origin + hit.get_travel()
	_step_dy = clampf(_step_dy - (global_position.y - y0), -STEP_HEIGHT, 0.0)  # F781: the body pops up, the look glides


## F803 (owner, Nov 23: going down the stairs "feels like jumping instead of walking down"): walking off the edge
## of a step, or down a slope steeper than you can stand on (the middle of corner stairs is ~55 degrees), the dwarf
## lost the floor and fell in an arc. Now, when he was standing, isn't jumping and the ground is at most STEP_DOWN
## below, he keeps his feet on it, like walking down steps. (A real drop, deeper than that, is still a fall.)
const STEP_DOWN := 0.75
const STEP_DOWN_STEEPEST := 65.0  ## degrees: steeper than this below you is a wall, not ground
const STEP_DOWN_STEEPEST_STAIRS := 80.0  ## (near the post of corner stairs they're about 70 degrees)


## F781 🔁: corner stairs are one smooth slope, steeper than ground you can stand on (52 degrees). While touching
## stairs, the dwarf counts up to this as ground: he walks up and down them smoothly instead of popping up steps.
const STAIRS_FLOOR_ANGLE := 78.0
var _on_stairs := false


## Is `body` touching a stairs piece (after its move_and_slide)?
static func on_steep_stairs(body: CharacterBody3D) -> bool:
	for i in body.get_slide_collision_count():
		if step_down_steepest(body.get_slide_collision(i).get_collider()) == STEP_DOWN_STEEPEST_STAIRS:
			return true
	return false


## How steep the ground under `what` may be and you still keep your feet on it going down.
static func step_down_steepest(what: Object) -> float:
	var n := what as Node
	while n and not n is PieceNode:
		n = n.get_parent()
	if n and (n as PieceNode).piece in ["stairs", "stairs_corner", "stairs_spiral"]:
		return STEP_DOWN_STEEPEST_STAIRS
	return STEP_DOWN_STEEPEST
var _stepped_down := false


func _try_step_down() -> bool:
	var hit := KinematicCollision3D.new()
	if not test_move(global_transform, Vector3.DOWN * STEP_DOWN, hit):
		return false
	if hit.get_normal().angle_to(Vector3.UP) > deg_to_rad(step_down_steepest(hit.get_collider())):
		return false
	global_position += hit.get_travel()
	velocity.y = 0.0
	if hit.get_travel().y < -0.2:   # a real step down (not just following a slope): the look glides down after
		_step_dy = clampf(_step_dy - hit.get_travel().y, 0.0, STEP_DOWN)
	return true


## Standing on the ground, or keeping his feet on steps going down (F803).
func _grounded() -> bool:
	return is_on_floor() or _stepped_down


## F781 (owner, Nov 22: "very jittery"): a step-up lifts the body in one go; the model starts this far below it
## and glides up (about a tenth of a second), so you see a smooth climb, not a hop.
var _step_dy := 0.0


var _step_t := 0.0
var _ladder_t := 0.0
var _steps_heard := 0


## Footsteps on stone, each time a foot comes down (F577, owner Nov 21: "step sounds that match the feet"). The rigged
## dwarf counts his foot plants (DwarfRig.steps); the old shapes look has no feet to watch, so it keeps a timer.
func _footsteps(delta: float, speed: float) -> void:
	var rig: DwarfRig = model.dwarf_rig if model else null
	var counted := rig.steps if rig else 0
	var new_step := counted != _steps_heard
	_steps_heard = counted
	if not _grounded() or speed < 1.0:
		_step_t = 0.0
		return
	if rig:
		if not new_step:
			return
	else:
		_step_t -= delta
		if _step_t > 0.0:
			return
		_step_t = 0.42 if speed < 5.0 else 0.3
	Sfx.play("step", global_position, -14.0)
	if _sprint_t >= DwarfFeel.SPRINT_DUST_FROM:  # sprinting: his heels throw the floor up behind him (F775)
		_kick_dust(DwarfFeel.SPRINT_DUST_AMOUNT)
	else:  # walking: just a faint puff (owner, Nov 22)
		_kick_dust(DwarfFeel.WALK_DUST_AMOUNT, DwarfFeel.WALK_DUST_SIZE, DwarfFeel.WALK_DUST_SEE)


## A cloud of whatever he's running on, thrown back behind his heels (F775: cave rock, moss, dungeon wood...).
func _kick_dust(amount: int, size := DwarfFeel.SPRINT_DUST_SIZE, see := 0.5) -> void:
	var back := Vector3(-velocity.x, 0.0, -velocity.z)
	if back.length() < 0.1:
		back = model.global_basis.z
	Fx.run_kick(get_parent(), global_position + back.normalized() * 0.25 + Vector3.UP * 0.08, back, floor_surface(), amount, size, see)


## What he's standing on, for dust: "rock", "dirt", "moss", "fungus", "wood", "stone", "brick" or "metal".
## A built piece says its own material; a dungeon floor box says wood or stone; the cave asks the rock underfoot.
func floor_surface() -> String:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		if c.get_normal().y < 0.6:
			continue
		var shape := c.get_collider_shape() as Node
		if shape and shape.has_meta("surface"):
			return String(shape.get_meta("surface"))
		var n := c.get_collider() as Node
		while n:
			if n is PieceNode:
				var kind := Fx.build_dust_kind((n as PieceNode).family)
				return "wood" if kind == "wood" else kind
			n = n.get_parent()
		break
	var auth := GameAuthority.instance
	if auth == null or auth.world == null:
		return "rock"
	match auth.world.rock_material_near(global_position + Vector3.DOWN * 0.2, 1.0):
		Mat.MOSS:
			return "moss"
		Mat.DIRT, Mat.CLAY:
			return "dirt"
		Mat.MYCELIUM, Mat.SPORESTONE:
			return "fungus"
		Mat.DWARF, Mat.PATH:  # (the old brick road, F900)
			return "stone"
	return "rock"


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


var _kill_push_left := 0.0  ## F800: seconds left of the killing-blow camera push-in


## F800: you landed a killing blow: your camera pushes in a little and back out (only on your own screen).
func kill_push() -> void:
	_kill_push_left = DwarfFeel.KILL_PUSH_TIME


## The push-in: quick in, slower back out, scaled by the camera shake setting (0 = off). Never closer than 1 m.
func _kill_push_step(delta: float) -> void:
	if _kill_push_left <= 0.0:
		return
	_kill_push_left = maxf(0.0, _kill_push_left - delta)
	var p := 1.0 - _kill_push_left / DwarfFeel.KILL_PUSH_TIME
	var push := sin(PI * sqrt(p)) * DwarfFeel.KILL_PUSH * SoundSettings.camera_shake
	camera.position.z -= minf(push, maxf(0.0, _cam_len - 1.0))


## You got hurt (F695, owner Nov 22): a small camera bump, bigger for a bigger share of your health,
## and the dwarf's body flashes pale for a blink. Smaller than the bump when YOU land a hit (0.25).
const HURT_SHAKE_MIN := 0.12
const HURT_SHAKE_MAX := 0.3


func got_hurt(amount: float, max_health: float) -> void:
	var share := clampf(amount / maxf(max_health, 1.0) / 0.3, 0.0, 1.0)
	add_shake(lerpf(HURT_SHAKE_MIN, HURT_SHAKE_MAX, share))
	if model:
		model.hurt_flash()


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


## Carry weight (F793): what you're carrying and how much it slows you. Your own inventory comes from the host.
func _update_carry(delta: float) -> void:
	_carry_wait -= delta
	if _carry_wait > 0.0 and not carry.is_empty():
		return
	_carry_wait = 0.2
	var auth := GameAuthority.instance
	var ps := auth.get_player(peer_id) if auth else null
	carry = ItemWeights.for_player(ps) if ps else {}


func is_overloaded() -> bool:
	return carry.get("load", ItemWeights.Load.LIGHT) == ItemWeights.Load.OVERLOADED


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
	var wood: bool = result.get("kind", "") in GlowPlacer.TALL  # roots, Root Trees, grove trees, giant mushrooms
	match result.get("state", ""):
		"hit" when result.has("kind"):  # a root or mushroom that needs more hits: the swing already played its chop
			# (F558: this used to fall through to the rock sound + cracks below, so wood sounded like metal on the first hit)
			Fx.burst(get_parent(), at, Color(0.45, 0.32, 0.2) if wood else col, 6, 2.5)
			_shake = 0.35
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
			Sfx.play("chop" if wood else "clink", at, -6.0 if wood else 0.0)  # wood knocks like wood, never a metal clink (F558)
		"done":
			var k: String = result.get("kind", "")
			if k == "fiber":  # a grass tuft, fern or small root broke (F197): a puff of green bits
				Fx.burst(get_parent(), at + Vector3.UP * 0.15, Color(0.6, 0.66, 0.38), 12, 2.5)
			Sfx.play("crystal" if k.begins_with("crystal") else ("chop" if k in GlowPlacer.TALL else "pickup"), at)


## The glowing vine (curtain strand) along your aim, in reach and in front of what you aim at, or -1 (F569).
## Generous (0.6 m from the aim line): the vines sway away from you as you come close.
const VINE_PICK_NEAR := 0.6


func vine_in_aim(hit: Dictionary) -> int:
	var auth := GameAuthority.instance
	if auth == null or auth.curtains == null or camera == null:
		return -1
	var chest := global_position + Vector3.UP * 1.1
	var reach_to: Vector3 = hit.position if not hit.is_empty() else chest + (-camera.global_basis.z) * GameAuthority.REACH
	return auth.curtains.strand_near_ray(chest, reach_to, VINE_PICK_NEAR)


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
