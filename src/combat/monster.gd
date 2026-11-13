class_name Monster
extends CharacterBody3D
## One monster. On the host it thinks (states from combat doc 5.1); on other computers it
## just copies the position the host sends ("puppet").
##
## Idle → Wander → Alert → Chase → Attack (tell → hit) → Recover → Chase …
## Stunned (stun meter full) · Return (gave up: walks home, heals) · Sleep (Rustwights)

enum State { IDLE, WANDER, ALERT, CHASE, ATTACK, RECOVER, STUNNED, RETURN, SLEEP }

const MONSTER_LAYER := 64
const RECOVER_TIME := 0.7

var uid := 0
var kind := "mossnipper"
var leader := false
var pack_id := 0
var hp := 30.0
var state := State.IDLE
var home := Vector3.ZERO
var target_peer := 0
var stun := StunMeter.new()
var boosted := false  ## a living pack leader is near
var data: Dictionary
var model: Node3D
var phase := 0  ## bosses: which phase (0 = first)
var _cooldowns := {}  ## bosses: attack name -> seconds until it can be used again
var _stun_at_tell := 0.0
var _timer := 0.0
var _think := 0.0
var _attack: Dictionary = {}
var _wander_to := Vector3.INF
var _no_progress := 0.0
var _best_dist := INF
var _net_pos := Vector3.ZERO
var _net_yaw := 0.0
var _hp_label: Label3D
var _bar_fill: MeshInstance3D
var _stun_fill: MeshInstance3D
var _bars: Node3D
var _flash := 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)


func setup(p_uid: int, p_kind: String, p_leader: bool, p_home: Vector3) -> void:
	uid = p_uid
	kind = p_kind
	leader = p_leader
	home = p_home
	data = Monsters.info(kind)
	hp = Monsters.max_hp(kind, leader)
	var boss_kind: String = data.get("boss", "")
	stun = StunMeter.new(data.stun * (Monsters.LEADER.stun if leader else 1.0), 5.0 if boss_kind == "main" else (4.0 if boss_kind == "side" else 3.0), boss_kind != "")
	state = State.SLEEP if data.get("sleeps", false) else State.IDLE
	_timer = randf_range(3.0, 8.0)


func _ready() -> void:
	collision_layer = MONSTER_LAYER
	collision_mask = World.TERRAIN_LAYER | PieceNode.PIECE_LAYER
	set_meta("monster_uid", uid)
	var s: float = data.size * (Monsters.LEADER.size if leader else 1.0)
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35 * s + 0.1
	cap.height = maxf(cap.radius * 2.0, 0.9 * s + 0.3)
	shape.shape = cap
	shape.position = Vector3.UP * cap.height * 0.5
	add_child(shape)
	model = MonsterModel.build(data.shape, data.color, s, leader)
	add_child(model)
	_hp_label = Label3D.new()
	_hp_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_hp_label.position = Vector3.UP * (cap.height + 0.4)
	_hp_label.pixel_size = 0.004
	_hp_label.font_size = 32
	_hp_label.outline_size = 8
	_hp_label.no_depth_test = true
	_hp_label.visibility_range_end = 25.0
	add_child(_hp_label)
	# Health bar (red) and stun bar (gold): little flat bars that always face the camera.
	_bars = Node3D.new()
	_bars.position = _hp_label.position + Vector3.DOWN * 0.18
	add_child(_bars)
	_bar(Color(0.1, 0.08, 0.08, 0.8), 0.0, 1.0)
	_bar_fill = _bar(Color(0.85, 0.2, 0.2), 0.001, 1.0)
	_stun_fill = _bar(Color(1.0, 0.8, 0.3), 0.002, 0.0, -0.07)
	_net_pos = global_position
	_update_label()


func max_hp() -> float:
	return Monsters.max_hp(kind, leader)


func is_boss() -> bool:
	return data.has("boss")


## Numbers for damage math (a boss's phase can change its armor).
func stats() -> Dictionary:
	var s := Monsters.target_stats(kind, leader)
	if is_boss() and data.phases[phase].has("armor"):
		s.armor = data.phases[phase].armor
	return s


## The attacks it can use right now.
func attack_options() -> Array:
	if not is_boss():
		return data.attacks
	var out := []
	var mult: float = data.phases[phase].get("tell_mult", 1.0)
	for id in data.phases[phase].attacks:
		var a: Dictionary = data.attack_list[id].duplicate(true)
		a.tell = maxf(a.tell * mult, 0.5)
		a.id = id
		out.append(a)
	return out


## Bosses: move to the next phase when health drops low enough. Returns the phase's on_enter (or {}).
func check_phase() -> Dictionary:
	if not is_boss():
		return {}
	var frac := hp / max_hp()
	var entered := {}
	while phase < data.phases.size() - 1 and frac <= data.phases[phase].until:
		phase += 1
		entered = data.phases[phase].get("on_enter", {})
	return entered


func is_alive() -> bool:
	return hp > 0.0


## How strong its hits are right now (leader ×1.3, pack boost +20%).
func damage_mult() -> float:
	return (Monsters.LEADER.damage if leader else 1.0) * (1.0 + (Monsters.PACK_BOOST.damage if boosted else 0.0))


# ================================================================== host brain

func think(delta: float, mgr: Node) -> void:
	stun.decay_mult = Monsters.PACK_BOOST.decay if boosted else 1.0
	stun.tick(delta)
	_timer -= delta
	if stun.is_stunned():
		state = State.STUNNED
		velocity = Vector3(0, velocity.y, 0)
		_move(delta, Vector3.ZERO, 0.0)
		return
	if state == State.STUNNED:
		state = State.CHASE
	for k in _cooldowns.keys():
		_cooldowns[k] -= delta
		if _cooldowns[k] <= 0.0:
			_cooldowns.erase(k)
	_think -= delta
	if _think <= 0.0:
		_think = 0.3
		_perceive(mgr)
	var target: Node3D = mgr.player_node(target_peer)
	match state:
		State.SLEEP:
			_move(delta, Vector3.ZERO, 0.0)
		State.IDLE:
			_move(delta, Vector3.ZERO, 0.0)
			if _timer <= 0.0:
				state = State.WANDER
				var a := randf() * TAU
				_wander_to = home + Vector3(cos(a), 0, sin(a)) * randf_range(3.0, Monsters.WANDER_RADIUS)
				_timer = 6.0
		State.WANDER:
			var to := _wander_to - global_position
			to.y = 0
			if to.length() < 1.0 or _timer <= 0.0:
				state = State.IDLE
				_timer = randf_range(3.0, 8.0)
			_move(delta, to.normalized(), data.walk)
		State.ALERT:
			_face(target)
			_move(delta, Vector3.ZERO, 0.0)
			if _timer <= 0.0:
				state = State.CHASE
				_best_dist = INF
				_no_progress = 0.0
		State.CHASE:
			if target == null:
				state = State.RETURN
				return
			var to := target.global_position - global_position
			var dist := Vector2(to.x, to.z).length()
			# Gave up? (too far from home, or can't get closer for 10 s)
			if dist < _best_dist - 0.5:
				_best_dist = dist
				_no_progress = 0.0
			else:
				_no_progress += delta
			if not is_boss() and (global_position.distance_to(home) > Monsters.LEASH or _no_progress > Monsters.GIVE_UP):
				state = State.RETURN
				target_peer = 0
				return
			var atk := _pick_attack(dist)
			if not atk.is_empty():
				_start_attack(atk, mgr)
				return
			var speed: float = data.run * (1.0 + (Monsters.PACK_BOOST.speed if boosted else 0.0))
			to.y = 0
			_move(delta, to.normalized(), speed)
			_face(target)
		State.ATTACK:
			_face(target)
			_move(delta, Vector3.ZERO, 0.0)
			if _timer <= 0.0:
				if _attack.has("summon"):
					# Interrupted if it took 30 stun during the call (doc 8.3).
					if stun.value - _stun_at_tell < 30.0 and not stun.is_stunned():
						mgr.boss_summon(self, _attack.summon[0], _attack.summon[1])
					_cooldowns[_attack.get("id", _attack.name)] = _attack.get("cooldown", 30.0)
				if _attack.has("follow"):
					var f: Dictionary = _attack.follow
					var next := _attack.duplicate()
					next.tell = f.tell
					next.damage = f.damage
					if f.has("follow"):
						next.follow = f.follow  # chains like Hall Quake's 3 rings
					else:
						next.erase("follow")
					_start_attack(next, mgr)
				else:
					state = State.RECOVER
					_timer = RECOVER_TIME
					if data.get("hit_and_run", false):
						_wander_to = global_position - (target.global_position - global_position).normalized() * 3.0 if target else home
		State.RECOVER:
			if data.get("hit_and_run", false) and _wander_to != Vector3.INF:
				var back := _wander_to - global_position
				back.y = 0
				_move(delta, back.normalized(), data.run * 0.6)
			else:
				_move(delta, Vector3.ZERO, 0.0)
			if _timer <= 0.0:
				state = State.CHASE
		State.RETURN:
			hp = minf(max_hp(), hp + max_hp() * 0.1 * delta)
			var to := home - global_position
			to.y = 0
			if to.length() < 1.5:
				state = State.IDLE
				_timer = randf_range(3.0, 8.0)
				mgr.monster_changed(self)
			_move(delta, to.normalized(), data.walk)


func _perceive(mgr: Node) -> void:
	if state in [State.ALERT, State.CHASE, State.ATTACK, State.RECOVER]:
		return
	var found: int = mgr.nearest_noticer(self)
	if found == 0:
		return
	target_peer = found
	if state == State.SLEEP or state == State.IDLE or state == State.WANDER or state == State.RETURN:
		state = State.ALERT
		_timer = 0.8
		mgr.alert_pack(self, found)


## Woken up by being hit or by a pack-mate.
func alert(peer: int) -> void:
	if state in [State.CHASE, State.ATTACK, State.RECOVER, State.STUNNED]:
		return
	target_peer = peer
	state = State.CHASE
	_best_dist = INF
	_no_progress = 0.0


func _pick_attack(dist: float) -> Dictionary:
	var options := []
	for a in attack_options():
		if _cooldowns.has(a.get("id", a.name)):
			continue
		if dist <= a.reach and (not a.get("lunge", false) or dist > 2.0) and (not a.get("ranged", false) or dist > 3.0 or not is_boss()):
			options.append(a)
	return options.pick_random() if not options.is_empty() else {}


func _start_attack(atk: Dictionary, mgr: Node) -> void:
	_attack = atk
	_stun_at_tell = stun.value
	state = State.ATTACK
	_timer = atk.tell
	mgr.send_tell(self, atk)


func _move(delta: float, dir: Vector3, speed: float) -> void:
	if data.get("flies", false):
		velocity = dir * speed
		velocity.y = 0.0
	else:
		velocity.x = move_toward(velocity.x, dir.x * speed, 20.0 * delta)
		velocity.z = move_toward(velocity.z, dir.z * speed, 20.0 * delta)
		velocity.y -= _gravity * delta
		if is_on_floor():
			velocity.y = maxf(velocity.y, -0.5)
	move_and_slide()
	if global_position.y < CaveMaker.Y_MIN - 20.0:
		global_position = home + Vector3.UP


func _face(target: Node3D) -> void:
	if target == null:
		return
	var to := target.global_position - global_position
	if Vector2(to.x, to.z).length() > 0.1:
		model.rotation.y = lerp_angle(model.rotation.y, atan2(-to.x, -to.z), 0.25)


# ================================================================== everyone: looks

## A puppet copy follows the host's numbers.
func set_net(pos: Vector3, yaw: float) -> void:
	_net_pos = pos
	_net_yaw = yaw


func puppet_step(delta: float) -> void:
	global_position = global_position.lerp(_net_pos, minf(1.0, delta * 12.0))
	model.rotation.y = lerp_angle(model.rotation.y, _net_yaw, minf(1.0, delta * 12.0))


## The warning before a hit: eyes flash and the body leans in.
func show_tell(seconds: float) -> void:
	_flash = seconds
	var t := create_tween()
	t.tween_property(model, "scale", Vector3(1.0, 0.85, 1.15), seconds * 0.8).set_trans(Tween.TRANS_SINE)
	t.tween_property(model, "scale", Vector3(1.0, 1.1, 0.9), 0.08)
	t.tween_property(model, "scale", Vector3.ONE, 0.2)


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash -= delta
		MonsterModel.set_glow(model, 1.0 if _flash < 0.25 else 0.35)  # bright gleam in the last 250 ms
	else:
		MonsterModel.set_glow(model, 0.0)
	if stun.is_stunned():
		model.rotation.z = sin(Time.get_ticks_msec() * 0.01) * 0.15
	else:
		model.rotation.z = 0.0


func set_hp(value: float, stun_frac: float, stunned: bool) -> void:
	hp = value
	if stunned and not stun.is_stunned():
		stun.stunned_left = 3.0
	elif not stunned:
		stun.stunned_left = 0.0
	stun.value = stun_frac * stun.max_value
	_update_label()


func _update_label() -> void:
	if _hp_label == null:
		return
	_hp_label.text = (data.get("leader", "Leader") if leader else data.name) + (" (dazed!)" if stun.is_stunned() else "")
	_hp_label.modulate = Color(1.0, 0.85, 0.3) if leader or stun.is_stunned() else Color(1, 1, 1, 0.75)
	var hurt := hp < max_hp() or stun.value > 0.0
	_bars.visible = hurt
	_set_bar(_bar_fill, clampf(hp / max_hp(), 0.0, 1.0))
	_set_bar(_stun_fill, stun.fraction())


const BAR_W := 0.8


func _bar(color: Color, z: float, fill: float, y: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(BAR_W, 0.08 if y == 0.0 else 0.04)
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.billboard_keep_scale = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.no_depth_test = true
	m.albedo_color = color
	m.render_priority = int(z * 1000)
	mi.material_override = m
	mi.position = Vector3(0, y, 0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_bars.add_child(mi)
	_set_bar(mi, fill)
	return mi


## Shrinks a bar from the right. (Billboards turn with the camera, so we change the quad's size.)
func _set_bar(mi: MeshInstance3D, f: float) -> void:
	var q: QuadMesh = mi.mesh
	q.size.x = maxf(BAR_W * f, 0.001)
	q.center_offset = Vector3(-BAR_W * (1.0 - f) * 0.5, 0, 0)
	mi.visible = f > 0.0
