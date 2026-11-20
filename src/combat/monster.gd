class_name Monster
extends CharacterBody3D
## One monster. On the host it thinks (states from combat doc 5.1); on other computers it
## just copies the position the host sends ("puppet").
##
## Idle → Wander → Alert → Chase → Attack (tell → hit) → Recover → Chase …
## Stunned (stun meter full) · Return (gave up: walks home, heals) · Sleep (Rustwights)

enum State { IDLE, WANDER, ALERT, CHASE, ATTACK, RECOVER, STUNNED, RETURN, SLEEP, FLEE }

const MONSTER_LAYER := 64
const RECOVER_TIME := 0.7

var uid := 0
var kind := "rock_snail"
var leader := false
var variant := ""  ## crystal colour ("" = normal), combat doc 7
var pack_id := 0
var hp := 30.0
var state := State.IDLE
var home := Vector3.ZERO
## A dungeon creature's dungeon and room (owner, Nov 20: "the pack came out and crushed me in the hallway"): it never
## steps out of its room, gives up when you leave it, and never walks under a crusher.
var dungeon := {}
var dungeon_room := ""
var target_peer := 0
var stun := StunMeter.new()
var boosted := false  ## a living pack leader is near
var data: Dictionary
var model: Node3D
var _timer := 0.0
const CHARGE_DAZE := 3.0  ## seconds a monster stands catching its breath after a charge (F111; not a real daze)
const CHARGE_RUN_PART := 0.6  ## a charge: it rears up for the first 40% of its wind-up, then runs for the last 60%
var _think := 0.0
var _attack: Dictionary = {}
var _wander_to := Vector3.INF
var _no_progress := 0.0
var _best_dist := INF
var _net_pos := Vector3.ZERO
var _net_yaw := 0.0
var _hp_label: Label3D
var _bar_fill: MeshInstance3D
var _stars: Node3D            ## only looks: the stars that circle a dazed creature's head (owner F449)
var _bars: Node3D
var _flash := 0.0
## Rock Snail (data.shell_hide): seconds left hidden in the shell, and how many of its hiding marks (health) it has used.
var shell_left := 0.0
var shell_hits := 0
var shell_shut := false  ## everyone: the snail is hiding right now (hits on it clank)
var _charging := 0.0     ## only looks: seconds of a beetle charge left (red eyes, dust trail)
var _charge_len := 1.0   ## only looks: that charge's wind-up (tell) in seconds
var _dust_t := 0.0
var _flap_was := 0.0
var _flinch := 0.0       ## only looks: a quick jolt back when hit
var _charge_dir := Vector3.ZERO  ## straight_charge: the direction locked when the charge starts
var _alt := INF                  ## swoops: the height this flyer is heading for
var _ceiling := INF              ## swoops: the rock above it (checked 4 times a second; F420)
var _ceiling_check := 0.0
var _last_pos := Vector3.ZERO
var _body_shape: CollisionShape3D  ## its body (a capsule standing up from its feet)
var _roosted := false  ## the body hangs down from the ceiling (a sleeping bat)
var _speed := 0.0
var _clock := 0.0
var _size := 1.0
var _blink := 8.0
var ailments := Ailments.new()  ## host: burn / chill / poison on this monster (doc 2.6)
var last_hitter := 0
var hit_by := {}  ## host: peer -> clock time of their last hit (Pack Hunters perk)
var _dot_sync := 0.0
var _trail := 10.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)


func setup(p_uid: int, p_kind: String, p_leader: bool, p_home: Vector3, p_variant: String = "") -> void:
	uid = p_uid
	kind = p_kind
	leader = p_leader
	home = p_home
	data = Monsters.info(kind)
	variant = p_variant if Monsters.VARIANTS.has(p_variant) else ""
	hp = Monsters.max_hp(kind, leader, variant)
	stun = StunMeter.new(data.stun * (Monsters.LEADER.stun if leader else 1.0) * (Monsters.VARIANT_STATS.stun if variant != "" else 1.0), 3.0)
	state = State.SLEEP if data.get("sleeps", false) else State.IDLE
	_timer = randf_range(3.0, 8.0)


func _ready() -> void:
	collision_layer = MONSTER_LAYER
	collision_mask = World.TERRAIN_LAYER | PieceNode.PIECE_LAYER
	if not data.get("flies", false):
		collision_mask |= MONSTER_LAYER  # walkers bump into each other, never overlap (owner, F233); a bat flock doesn't
	set_meta("monster_uid", uid)
	var s: float = data.size * (Monsters.LEADER.size if leader else 1.0)
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35 * s + 0.1
	cap.height = maxf(cap.radius * 2.0, 0.9 * s + 0.3)
	shape.shape = cap
	shape.position = Vector3.UP * cap.height * 0.5
	add_child(shape)
	_body_shape = shape
	# A bat roost is one look per cave (owner, Nov 19: "5 frost ones, or 5 ember ones"); everyone else its own.
	var look_seed := pack_id if pack_id >= MonsterManager.BAT_KEY else -1
	model = MonsterModel.build(data.shape, data.color, s, leader, kind, uid, variant, look_seed)  # uid: same individual for everyone
	_size = s
	add_child(model)
	if variant != "":
		# Crystal variants: glowing crystals on the back that light up the cave around them
		# (creatures made from the approved pictures already wear their variant's look).
		var vc: Color = Monsters.VARIANTS[variant].color
		if not model.get_meta("variant_look", false):
			MonsterModel.add_crystals(model, vc)
		var light := OmniLight3D.new()
		GraphicsSettings.cheap_light(light, 30.0)  # off smoothly when far away (owner, Nov 19)
		light.light_color = vc
		light.omni_range = 5.0 + s * 2.0
		light.light_energy = 1.0
		light.position = Vector3.UP * cap.height
		add_child(light)
	_hp_label = Label3D.new()
	_hp_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_hp_label.position = Vector3.UP * (cap.height + 0.4)
	_hp_label.pixel_size = 0.004
	_hp_label.font_size = 32
	_hp_label.outline_size = 8
	_hp_label.no_depth_test = true
	_hp_label.visibility_range_end = 25.0
	add_child(_hp_label)
	# Health bar (red): a little flat bar that always faces the camera. (No stun bar: dazed shows as stars, F449.)
	_bars = Node3D.new()
	_bars.position = _hp_label.position + Vector3.DOWN * 0.18
	add_child(_bars)
	_bar(Color(0.1, 0.08, 0.08, 0.8), 0.0, 1.0)
	_bar_fill = _bar(Color(0.85, 0.2, 0.2), 0.001, 1.0)
	_net_pos = global_position
	_update_label()


## Only looks: the snail pulls into its shell (or comes back out). The host decides when.
func show_shell(hidden: bool) -> void:
	MonsterModel.set_shell(model, hidden)
	if hidden and not shell_shut:
		Sfx.play("shell_clunk", global_position, 0.0, _voice())
	shell_shut = hidden


## Bigger creatures sound deeper.
func _voice() -> float:
	return clampf(1.0 / sqrt(maxf(_size, 0.3)), 0.6, 1.4)


## Only looks: a quick white flash and a little "punch" when something hits us.
func hit_flash() -> void:
	if model == null:
		return
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	glow.albedo_color = Color(1.0, 0.95, 0.85, 0.75)
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		mi.material_overlay = glow
	_flinch = 1.0  # jolts back (see _process)
	var base: Vector3 = model.get_meta("base_scale", model.scale)
	model.set_meta("base_scale", base)
	# Squash and stretch (owner, Nov 18, the Disney rules): squashed flat by the blow, it springs up a little too tall,
	# then settles.
	var t := create_tween()
	t.tween_property(model, "scale", base * Vector3(1.16, 0.84, 1.16), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(model, "scale", base * Vector3(0.94, 1.08, 0.94), 0.08).set_trans(Tween.TRANS_SINE)
	t.tween_property(model, "scale", base, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(glow, "albedo_color:a", 0.0, 0.16)
	t.tween_callback(func():
		for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			if mi.material_overlay == glow:
				mi.material_overlay = null)


## Only looks: the monster is already gone from the game. Its body tips over and sinks into
## the ground in a puff of dust, instead of popping out of existence.
## `statue` >= 0: it turns into that stone statue (owner, Nov 18: everything that dies turns to stone; mine it).
func die_visual(statue := -1) -> void:
	set_physics_process(false)
	set_process(false)
	collision_layer = 0
	collision_mask = 0
	for l in find_children("*", "Label3D", true, false):
		l.visible = false
	if _bars:
		_bars.visible = false
	if data.get("ragdoll", true):  # (every creature, owner Nov 18)
		# It goes limp and falls apart into physics pieces, pushed away from the player (Ragdoll, owner Nov 18).
		var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
		var from := cam.global_position if cam else global_position + Vector3.BACK
		if Ragdoll.make(self, model, from, velocity, statue):  # (killed in a charge, it flies on)
			queue_free.call_deferred()
			return
	if statue >= 0 and is_inside_tree():  # (no ragdoll: it tips over where it stands and turns to stone there)
		Statue.from_model(self, model, statue)
		queue_free.call_deferred()
		return
	var t := create_tween()
	t.tween_property(model, "rotation:z", deg_to_rad(80.0) * (1.0 if uid % 2 == 0 else -1.0), 0.35) 		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_interval(0.3)
	t.tween_property(model, "position:y", model.position.y - 0.6, 0.6)
	t.parallel().tween_property(model, "scale", model.scale * 0.3, 0.6)
	t.tween_callback(queue_free)


func max_hp() -> float:
	return Monsters.max_hp(kind, leader, variant)


## Numbers for damage math.
func stats() -> Dictionary:
	return Monsters.target_stats(kind, leader, variant)


## The attacks it can use.
func attack_options() -> Array:
	return data.attacks


func is_alive() -> bool:
	return hp > 0.0


## How strong its hits are right now (leader ×1.3, pack boost +20%).
func damage_mult() -> float:
	return (Monsters.LEADER.damage if leader else 1.0) * (1.0 + (Monsters.PACK_BOOST.damage if boosted else 0.0)) \
		* (Monsters.VARIANT_STATS.damage if variant != "" else 1.0)


# ================================================================== host brain

var _knock := Vector3.ZERO  ## (host) a push from a hit, fading out fast
var _climb_to := -INF       ## (host) the height of the dwarf it chases: against a wall below him, it climbs (F236)
const CLIMB_SPEED := 2.2    ## m/s up a wall
var _climbing := 0.0        ## (host) just left the wall while climbing: seconds of push over the lip left
var _stop := 0.0            ## (looks) a frozen blink when hit
var _rest := 0.0            ## (host) standing still: seconds until it checks the floor again (speed, owner Nov 19)
var far_dt := 0.0           ## (host) time saved up while it thinks less often, far from every dwarf


## Host: pushed by a hit (speed in m/s, away from the hitter). It slides back and stops quickly.
func knock(push: Vector3) -> void:
	_knock = Vector3(push.x, 0.0, push.z)


## Looks: freeze for a blink (the hit "lands").
func hit_stop(seconds: float) -> void:
	_stop = maxf(_stop, seconds)


func think(delta: float, mgr: Node) -> void:
	if _knock.length() > 0.05:
		move_and_collide(_knock * minf(delta, 0.05))  # (walls stop it; a long step can't fling it far)
		_knock = _knock.move_toward(Vector3.ZERO, 14.0 * delta)
	stun.decay_mult = Monsters.PACK_BOOST.decay if boosted else 1.0
	var was_dazed := stun.is_stunned()
	stun.tick(delta)
	if was_dazed and not stun.is_stunned():
		mgr.monster_changed(self)  # the daze wore off: everyone's stars go away (F448: they stayed up until its next hit)
	_timer -= delta
	if variant == "green":
		# Blight-crested: leaves a small poison cloud every 10 s (doc 7.1).
		_trail -= delta
		if _trail <= 0.0 and state in [State.CHASE, State.ATTACK, State.RECOVER]:
			_trail = 10.0
			mgr.spawn_cloud(global_position, 2.0, 4.0, 25.0, 0.0)
	var dot := ailments.tick(delta)
	if dot > 0.0:
		hp -= dot
		_dot_sync -= delta
		if hp <= 0.0:
			mgr._kill(self, last_hitter)
			return
		if _dot_sync <= 0.0:
			_dot_sync = 1.0
			mgr.monster_changed(self)
	if ailments.has("frozen"):
		_move(delta, Vector3.ZERO, 0.0)
		return
	if shell_left > 0.0:
		shell_left -= delta
		_move(delta, Vector3.ZERO, 0.0)
		if shell_left <= 0.0:
			mgr.monster_shell(self, false)  # comes back out
		return
	if stun.is_stunned():
		state = State.STUNNED
		velocity = Vector3(0, velocity.y, 0)
		_move(delta, Vector3.ZERO, 0.0)
		return
	if state == State.STUNNED:
		state = State.FLEE if data.get("passive", false) or (data.get("neutral", false) and hp < max_hp() * 0.5) else State.CHASE
		_timer = 6.0
	_think -= delta
	if _think <= 0.0:
		_think = 0.3
		_perceive(mgr)
	var target: Node3D = mgr.player_node(target_peer)
	_climb_to = target.global_position.y if target and state in [State.CHASE, State.ATTACK, State.RECOVER] else -INF
	if data.get("swoops", false):
		# Cruise high above you, dive down to bite, climb away again (owner's bat design).
		var ground := target.global_position.y if target else home.y - 2.5
		if state == State.ATTACK:
			_alt = ground + 0.9
		elif state in [State.CHASE, State.ALERT, State.RECOVER]:
			_alt = ground + 3.0
		elif state == State.SLEEP:
			_alt = global_position.y
		else:
			_alt = home.y - 1.5
		# Never aim above the ceiling (owner, Nov 19, F420: "attacking bats bounce off the ceiling"): where the rock
		# is lower than 3 m above you, it cruises just under it.
		if state != State.SLEEP:
			_ceiling_check -= delta
			if _ceiling_check <= 0.0:
				_ceiling_check = 0.25
				_ceiling = _rock_above()
			_alt = minf(_alt, _ceiling - _body_height() - CEILING_ROOM)
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
		State.FLEE:
			if target == null or _timer <= 0.0:
				state = State.IDLE
				home = global_position  # its new safe spot
				_timer = randf_range(3.0, 8.0)
				return
			var away := global_position - target.global_position
			away.y = 0
			_move(delta, away.normalized(), data.run)
		State.CHASE:
			if target == null:
				state = State.RETURN
				return
			if MonsterManager.ignores(target):  # its target took off flying (dev fly): forget them
				state = State.RETURN
				target_peer = 0
				return
			var to := target.global_position - global_position
			var dist := Vector2(to.x, to.z).length()
			if variant == "violet":
				_blink -= delta
				if _blink <= 0.0 and dist < 12.0 and _try_blink(target, to, mgr):
					_blink = Monsters.VARIANTS.violet.blink
					return
			# Gave up? (too far from home, or can't get closer for 10 s)
			if dist < _best_dist - 0.5:
				_best_dist = dist
				_no_progress = 0.0
			else:
				_no_progress += delta
			var gives_up := global_position.distance_to(home) > Monsters.LEASH or _no_progress > Monsters.GIVE_UP
			if data.get("stays_in_cave", false):  # (bats, F419: only when you leave their cave)
				gives_up = not mgr.in_cave(self, target.global_position)
			if not dungeon.is_empty() and DungeonMap.space_at(dungeon, target.global_position + Vector3.UP) != dungeon_room:
				gives_up = true  # (you left its room)
			if gives_up:
				state = State.RETURN
				target_peer = 0
				return
			# Far above it (a hole's edge), or it's still clinging to the wall: climb up first, then fight (F236).
			var atk := _pick_attack(dist) if to.y < 1.3 and (is_on_floor() or to.y < 0.4) else {}
			if not atk.is_empty():
				_start_attack(atk, mgr)
				return
			var speed: float = data.run * (1.0 + (Monsters.PACK_BOOST.speed if boosted else 0.0))
			to.y = 0
			_move(delta, to.normalized(), speed)
			_face(target)
		State.ATTACK:
			if _charge_dir == Vector3.ZERO:
				_face(target)
			if _timer <= 0.0 and _attack.has("cloud"):
				var c: Dictionary = _attack.cloud
				var at := global_position
				if target and c.at == "target":
					at = target.global_position
				elif target and c.at == "between":
					at = global_position.lerp(target.global_position, 0.6)
				mgr.spawn_cloud(at, c.radius, c.time, c.rate, c.get("dps", 0.0))
			if _attack.get("lunge", false) and target and _timer < _attack.tell * CHARGE_RUN_PART:
				# Charges and pounces: rush at the target during the last part of the wind-up.
				var rush := target.global_position - global_position
				rush.y = 0
				var charge_speed := maxf(data.run * 2.0, _attack.reach / maxf(_attack.tell * 0.6, 0.1))
				if data.get("straight_charge", false):
					# A charge doesn't steer: sidestep and it thunders past (then its back is open).
					if _charge_dir == Vector3.ZERO:
						_charge_dir = rush.normalized()
					_move(delta, _charge_dir, charge_speed)
					mgr.charge_smash(self, _charge_dir)  # it breaks what it runs into (owner F447)
				elif rush.length() > 1.2:
					_move(delta, rush.normalized(), charge_speed)
				else:
					_move(delta, Vector3.ZERO, 0.0)
			else:
				_move(delta, Vector3.ZERO, 0.0)
			if _timer <= 0.0:
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
					_timer = data.get("recover", RECOVER_TIME)
					if _attack.get("lunge", false):
						# After a charge it stands catching its breath: your chance to hit it (F111). It isn't dazed (no
						# stars, no "Dazed!"): the old word here made it say dazed when it wasn't (owner F448).
						_timer = maxf(_timer, CHARGE_DAZE)
					_charge_dir = Vector3.ZERO
					if data.get("hit_and_run", false):
						var away: float = data.get("retreat", 3.0)
						_wander_to = global_position - (target.global_position - global_position).normalized() * away if target else home
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
	if state in [State.ALERT, State.CHASE, State.ATTACK, State.RECOVER, State.FLEE]:
		return
	if data.get("passive", false) or data.get("neutral", false):
		return  # animals mind their own business until you hit them
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
	var hurt := hp < max_hp() * 0.5
	if data.get("passive", false) or (data.get("neutral", false) and hurt):
		if state != State.FLEE:
			target_peer = peer
			state = State.FLEE
			_timer = 6.0
		return
	if state in [State.CHASE, State.ATTACK, State.RECOVER, State.STUNNED]:
		return
	target_peer = peer
	state = State.CHASE
	_best_dist = INF
	_no_progress = 0.0


## Shift-crested: pops up behind or beside its target (doc 7.1).
func _try_blink(target: Node3D, to: Vector3, mgr: Node) -> bool:
	var maker: CaveMaker = mgr.auth.world.maker
	var dir := Vector3(to.x, 0, to.z).normalized().rotated(Vector3.UP, [0.0, PI / 2.0, -PI / 2.0].pick_random())
	var spot := target.global_position + dir * 2.5
	spot = maker.find_floor(spot.x, spot.z, target.global_position.y + 1.5)
	if maker.sdf_at(spot + Vector3.UP * 0.8) <= 0.3 or absf(spot.y - target.global_position.y) > 2.0:
		return false
	show_tell(0.5)
	global_position = spot + Vector3.UP * 0.2
	velocity = Vector3.ZERO
	return true


func _pick_attack(dist: float) -> Dictionary:
	var options := []
	for a in attack_options():
		if dist <= a.reach and dist >= a.get("min_reach", 0.0) and (not a.get("lunge", false) or dist > 2.0):
			options.append(a)
	return options.pick_random() if not options.is_empty() else {}


func _start_attack(atk: Dictionary, mgr: Node) -> void:
	_attack = atk
	_charge_dir = Vector3.ZERO  # a new charge picks its own straight line
	state = State.ATTACK
	_timer = atk.tell
	mgr.send_tell(self, atk)


## Is there a drop deeper than MAX_DROP just ahead (a hole it couldn't climb back out of)?
const MAX_DROP := 1.6


func _drop_ahead(dir: Vector3) -> bool:
	if not is_inside_tree():
		return false
	var ahead := global_position + Vector3(dir.x, 0.0, dir.z).normalized() * (float(data.get("size", 1.0)) * 0.5 + 0.6)
	var space := get_world_3d().direct_space_state
	# A wall ahead isn't a drop (F236: in a hole the spot ahead is inside the wall, the floor ray found nothing there,
	# so it stood still and never climbed out).
	var wall := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.4, ahead + Vector3.UP * 0.4)
	wall.collision_mask = World.TERRAIN_LAYER
	if not space.intersect_ray(wall).is_empty():
		return false
	var q := PhysicsRayQueryParameters3D.create(ahead + Vector3.UP * 0.6, ahead + Vector3.DOWN * (MAX_DROP + 0.1))
	q.collision_mask = World.TERRAIN_LAYER
	return space.intersect_ray(q).is_empty()


## Elemental buildup from a bolt (resistance shrinks it).
func add_buildup(kind: String, amount: float) -> void:
	var resist: float = stats().get({"burn": "fire", "chill": "frost", "poison": "poison"}.get(kind, ""), 0.0)
	ailments.add(kind, amount * maxf(0.0, 1.0 - resist))


## A dungeon creature may step to `p`: still in its own room, not under a crusher.
func may_step(p: Vector3) -> bool:
	if DungeonMap.space_at(dungeon, p + Vector3.UP * 0.5) != dungeon_room:
		return false
	return DungeonBuild.instance == null or not DungeonBuild.instance.near_crusher(p)


func _move(delta: float, dir: Vector3, speed: float) -> void:
	speed *= ailments.speed_mult()
	if data.get("weaves", false) and dir.length() > 0.1 and state != State.ATTACK:
		dir = weave(dir)
	if data.get("turns_in_place", false):
		var turned := _turn_toward(dir, delta)
		dir = turned[0]
		speed *= turned[1]
	if dir.length() > 0.1 and not data.get("flies", false) and is_on_floor() and _drop_ahead(dir):
		dir = Vector3.ZERO  # a pit it couldn't climb out of: stop at the edge and find another way (F125)
	if dir.length() > 0.1 and not dungeon.is_empty() and not data.get("flies", false) and not may_step(global_position + Vector3(dir.x, 0, dir.z).normalized() * 0.7):
		dir = Vector3.ZERO  # (a dungeon creature stops at its room's doorway and in front of a crusher)
	if data.get("flies", false):
		velocity = dir * speed
		velocity.y = 0.0
		if data.get("swoops", false) and _alt != INF:
			velocity.y = clampf((_alt - global_position.y) * 3.0, -7.0, 6.0)
	else:
		velocity.x = move_toward(velocity.x, dir.x * speed, 20.0 * delta)
		velocity.z = move_toward(velocity.z, dir.z * speed, 20.0 * delta)
		velocity.y -= _gravity * delta
		if is_on_floor():
			velocity.y = maxf(velocity.y, -0.5)
		# Stuck against a wall with the dwarf above (a hole he dug, a ledge): climb up it, like a real beetle or snail
		# (owner, F236 said twice: "they charge into a hole and you beat them easily; they should climb out").
		if dir.length() > 0.1 and is_on_wall() and _climb_to > global_position.y + 0.4 and not data.get("no_climb", false):
			velocity.y = maxf(velocity.y, CLIMB_SPEED)
			_climbing = 0.4
		elif _climbing > 0.0 and dir.length() > 0.1:  # over the lip: a last push up and forward, or it slips back
			_climbing -= delta
			velocity.y = maxf(velocity.y, CLIMB_SPEED * 0.7)
			var flat := Vector2(dir.x, dir.z).normalized() * maxf(Vector2(velocity.x, velocity.z).length(), 1.6)
			velocity.x = flat.x
			velocity.z = flat.y
	# Standing still (owner, Nov 19: 5 FPS, the physics step was too slow): a creature at rest on the floor (or a
	# roosting bat) doesn't ask the physics engine to move it every step; twice a second it checks the floor is still
	# there (a dwarf may have dug it away).
	var resting: bool = dir.length() < 0.1 and _knock.length() <= 0.05 and Vector2(velocity.x, velocity.z).length() < 0.05 		and (is_on_floor() or (data.get("flies", false) and absf(velocity.y) < 0.05))
	if resting:
		_rest -= delta
		if _rest > 0.0:
			return
		_rest = 0.5
	else:
		_rest = 0.0
	move_and_slide()
	if global_position.y < CaveMaker.Y_MIN - 20.0:
		global_position = home + Vector3.UP


## How high the rock is above this flyer (INF: more than 12 m of room).
const CEILING_ROOM := 0.3  ## m a flyer keeps between its back and the ceiling
func _rock_above() -> float:
	var from := global_position + Vector3.UP * 0.2
	var q := PhysicsRayQueryParameters3D.create(from, from + Vector3.UP * 12.0, World.TERRAIN_LAYER)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	return INF if hit.is_empty() else float(hit.position.y)


func _body_height() -> float:
	return (_body_shape.shape as CapsuleShape3D).height if _body_shape else 1.0


func _face(target: Node3D) -> void:
	if target == null:
		return
	var to := target.global_position - global_position
	if Vector2(to.x, to.z).length() > 0.1:
		if data.get("turns_in_place", false):
			_turn_toward(to, get_physics_process_delta_time())
		else:
			model.rotation.y = lerp_angle(model.rotation.y, atan2(-to.x, -to.z), 0.25)


## Rock Snails, Rock Beetles and Cave Bats move only forward (owner, Nov 18-19: no sliding sideways or backwards; each
## kind its own turn_speed, the snail slowest).
## The Rock Snail moves only forward (owner, Nov 18: "he can move backwards"): it turns slowly toward where it wants
## to go, hopping in place while it turns (model meta "turning", MonsterModel._snail), and only sets off once it faces
## that way. Returns [the direction it really moves (its own forward, or none), a speed factor].
const TURN_SPEED := 0.9  ## radians a second (about 7 s for a full turn)
const TURN_GO := 0.45    ## radians: it sets off once it faces within this of the way it wants to go


## Bats fly in curves with a bit of randomness (owner, Nov 19: "only forward and backward"): the way it wants to go
## sways slowly from side to side, each bat in its own rhythm.
func weave(dir: Vector3) -> Vector3:
	return dir.rotated(Vector3.UP, sin(_clock * 1.1 + uid * 1.7) * 0.55 + sin(_clock * 2.9 + uid * 0.6) * 0.2)


func _turn_toward(dir: Vector3, delta: float) -> Array:
	var flat := Vector2(dir.x, dir.z)
	if flat.length() < 0.1:
		model.set_meta("turning", false)
		return [Vector3.ZERO, 0.0]
	var want := atan2(-dir.x, -dir.z)
	var diff := angle_difference(model.rotation.y, want)
	model.rotation.y = rotate_toward(model.rotation.y, want, float(data.get("turn_speed", TURN_SPEED)) * delta)
	model.set_meta("turning", absf(diff) > 0.08)
	if absf(diff) > TURN_GO:
		return [Vector3.ZERO, 0.0]  # still turning: hops in place
	var fwd := -Basis(Vector3.UP, model.rotation.y).z
	return [fwd, maxf(0.0, cos(diff))]


# ================================================================== everyone: looks

## A puppet copy follows the host's numbers.
func set_net(pos: Vector3, yaw: float) -> void:
	_net_pos = pos
	_net_yaw = yaw


func puppet_step(delta: float) -> void:
	global_position = global_position.lerp(_net_pos, minf(1.0, delta * 12.0))
	model.rotation.y = lerp_angle(model.rotation.y, _net_yaw, minf(1.0, delta * 12.0))


## The warning before a hit: eyes flash and the body leans in. Each attack can name a sound
## for the warning (warn_sound) and for the moment it lands (land_sound), in Monsters.LIST.
## A beetle's charge also turns its eyes red and kicks up dust.
func show_tell(seconds: float, attack_name: String = "", aim: Node3D = null) -> void:
	_flash = seconds
	var atk: Dictionary = {}
	for a: Dictionary in data.get("attacks", []):
		if a.name == attack_name:
			atk = a
	if atk.get("spit", false):
		# The Rock Snail's spit (owner, Nov 17): he rears up, snaps forward and a gob flies 2-3 m (MonsterModel._snail).
		model.set_meta("spit_t0", _clock + uid * 0.37)  # (the clock MonsterModel.animate gets)
		model.set_meta("spit_len", seconds)
		get_tree().create_timer(seconds).timeout.connect(_spit_fx.bind(aim))
		return
		Sfx.play(atk.warn_sound, global_position, 0.0, _voice())
	if atk.has("land_sound"):
		get_tree().create_timer(seconds).timeout.connect(_land_sound.bind(atk.land_sound))
	if atk.get("lunge", false) and data.get("straight_charge", false):
		_charging = seconds + 0.6
		_charge_len = seconds
		MonsterModel.set_angry(model, true)
	# Squash relative to the monster's own size (leaders are bigger than 1).
	var base: Vector3 = model.get_meta("base_scale", model.scale)
	model.set_meta("base_scale", base)
	var t := create_tween()
	t.tween_property(model, "scale", base * Vector3(1.0, 0.85, 1.15), seconds * 0.8).set_trans(Tween.TRANS_SINE)
	t.tween_property(model, "scale", base * Vector3(1.0, 1.1, 0.9), 0.08)
	t.tween_property(model, "scale", base, 0.2)
	if atk.get("pounce", false) and model.has_meta("forged_root"):
		# A pounce (the Cave Spider): it crouches, then leaps up in an arc while it rushes in, landing as the bite lands.
		var body: Node3D = model.get_meta("forged_root")
		var y0 := 0.0
		var leap := create_tween()
		leap.tween_interval(seconds * 0.4)
		leap.tween_property(body, "position:y", y0 + 0.45, seconds * 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		leap.tween_property(body, "position:y", y0, seconds * 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


## Only looks: a gob of spit flies from the snail's mouth to the target in a low arc and splats.
## (Whether it hurts is judged by the target's own computer, like every attack: a shield stops it completely.)
func _spit_fx(aim: Node3D) -> void:
	if not is_alive() or not is_inside_tree():
		return
	Sfx.play("snail_spit", global_position, 0.0, _voice())  # a real recording (CC0, "80 CC0 creature SFX")
	var fwd := -model.global_transform.basis.z.normalized()
	var mouth := global_position + fwd * 0.6 * _size + Vector3.UP * 0.45 * _size
	var to := mouth + fwd * 3.0 + Vector3.DOWN * 0.3
	if aim and is_instance_valid(aim) and aim.global_position.distance_to(global_position) < 5.0:
		to = aim.global_position + Vector3.UP * 0.9
	var gob := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.07
	s.height = 0.12
	gob.mesh = s
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.55, 0.62, 0.2)
	m.roughness = 0.15  # wet
	gob.material_override = m
	gob.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var world := get_parent()  # (the gob outlives the snail if it dies mid-spit)
	world.add_child(gob)
	gob.global_position = mouth
	var t := gob.create_tween()
	t.tween_method(func(k: float) -> void:
		if is_instance_valid(gob):
			gob.global_position = mouth.lerp(to, k) + Vector3.UP * sin(k * PI) * 0.25, 0.0, 1.0, 0.22)
	t.tween_callback(func() -> void:
		if is_instance_valid(world):
			Fx.burst(world, to, Color(0.55, 0.62, 0.2), 8, 2.0)
		gob.queue_free())


func _land_sound(sound: String) -> void:
	if is_alive():
		Sfx.play(sound, global_position, 0.0, _voice())


## A sleeping bat hangs from the ceiling by its feet, so its body hangs DOWN from there with its picture (owner, Nov 19:
## bolts at a hanging bat did nothing: its body stood up into the rock above, where no bolt could reach it). Waking up,
## it drops its body's height out of the ceiling, so it doesn't start stuck in the rock (owner: "bats stuck in the walls").
func _hang_body(hang: bool) -> void:
	if hang == _roosted or _body_shape == null:
		return
	_roosted = hang
	var h: float = (_body_shape.shape as CapsuleShape3D).height
	_body_shape.position = Vector3.UP * h * (-0.5 if hang else 0.5)
	if not hang and is_inside_tree() and multiplayer.is_server():
		global_position += Vector3.DOWN * h  # (the host moves it; everyone else gets its new place)


func _process(delta: float) -> void:
	# Coming alive (only looks): walk, waddle, flap, breathe, at the speed we really move.
	if _clock == 0.0:
		_last_pos = global_position  # first frame: we didn't really "move" from the origin
	var moved := Vector2(global_position.x - _last_pos.x, global_position.z - _last_pos.z).length()
	_last_pos = global_position
	_speed = lerpf(_speed, moved / maxf(delta, 0.001), minf(1.0, delta * 8.0))
	_clock += delta
	model.set_meta("roosting", data.get("roosts", false) and state == State.SLEEP)
	_hang_body(model.get_meta("roosting"))
	if _stop > 0.0:
		_stop -= delta
		_clock -= delta  # (frozen: its moves wait)
	else:
		MonsterModel.animate(model, _speed, _size, _clock + uid * 0.37)
	if _flash > 0.0:
		_flash -= delta
		MonsterModel.set_glow(model, 1.0 if _flash < 0.25 else 0.35)  # bright gleam in the last 250 ms
	else:
		MonsterModel.set_glow(model, 0.0)
	_creature_fx(delta)
	_daze_stars()
	if model.get_meta("roosting", false):
		pass  # hanging upside down (MonsterModel.animate)
	elif stun.is_stunned():
		MonsterModel.dazed_sway(model, daze_sway(_clock, model.has_meta("foot")))  # (a snail sways, its foot stays put)
	elif model.has_meta("foot"):
		MonsterModel.dazed_sway(model, 0.0)  # a snail hops, it doesn't waddle
	else:
		model.rotation.z = sin(_clock * (5.0 + _speed * 2.5)) * 0.07 * clampf(_speed / 3.0, 0.0, 1.0)  # waddle


## Only looks and sounds: charge dust, wing beats, the jolt when hit.
func _creature_fx(delta: float) -> void:
	if _charging > 0.0:
		_charging -= delta
		_dust_t -= delta
		if _dust_t <= 0.0:
			var fast := _speed > 2.5
			_dust_t = 0.06 if fast else 0.25  # pawing the ground, then a trail while it thunders along
			Fx.dust(get_parent(), global_position, Color(0.45, 0.4, 0.33), 3 if fast else 1, 0.5 * _size)
		if _charging <= 0.0:
			MonsterModel.set_angry(model, false)
			if data.get("straight_charge", false):  # the charge ends with a thump: stone chips and dust shake off its shell
				Fx.burst(get_parent(), global_position + Vector3.UP * 0.7 * _size, Color(0.5, 0.46, 0.42), 8, 2.0)
				Fx.dust(get_parent(), global_position, Color(0.45, 0.4, 0.33), 4, 0.6 * _size)
	if data.has("flap_sound") and not model.get_meta("roosting", false) and is_alive():
		var wing := sin((_clock + uid * 0.37) * 9.0)  # same beat as MonsterModel.animate's wings
		if _flap_was > 0.0 and wing <= 0.0:
			Sfx.play(data.flap_sound, global_position, -20.0, _voice())  # one beat per downstroke (-20: a pack of 10 was too loud, owner Nov 19)
		_flap_was = wing
	if _charging > 0.0 and data.get("straight_charge", false):
		# Charging (owner F446): it rears up (head down, back end up) while it winds up, then runs normally (red eyes).
		var rear := charge_rear(_charge_len + 0.6 - _charging, _charge_len)
		model.rotation.x -= 0.22 * rear
		model.position.y += 0.05 * _size * rear
	if _flinch > 0.0:
		_flinch = maxf(0.0, _flinch - delta * 6.0)
		if model.has_meta("foot"):
			model.set_meta("flinch", _flinch)  # a snail: only the body jolts, its foot stays put (MonsterModel._snail)
		else:
			model.rotation.x += 0.3 * _flinch  # head tips back
			model.position.y += 0.06 * _flinch * _size
	model.set_meta("flinch_any", _flinch)  # (blink lids squeeze shut while it flinches: MonsterModel._blinks)


func set_hp(value: float, stun_frac: float, stunned: bool) -> void:
	hp = value
	if stunned and not stun.is_stunned():
		stun.stunned_left = 3.0
	elif not stunned:
		stun.stunned_left = 0.0
	# (While dazed the meter is empty: a daze empties it. The host's own copy came here too and was filled to the top,
	# so its next small hit after the daze dazed it again at once: owner F448, "dazed when I'm not hitting them".)
	stun.value = 0.0 if stunned else stun_frac * stun.max_value
	_update_label()


func _update_label() -> void:
	if _hp_label == null:
		return
	# No names over creatures (owner, Nov 17), no "Dazed!" word and no stun meter (owner F449: stars show a daze).
	_hp_label.text = ""
	_hp_label.modulate = Color(1.0, 0.85, 0.3) if leader else Color(1, 1, 1, 0.75)
	_bars.visible = hp < max_hp()
	_set_bar(_bar_fill, clampf(hp / max_hp(), 0.0, 1.0))


## How far a charging beetle rears up (0..1), `elapsed` seconds into a charge whose wind-up is `tell` (owner F446):
## up quickly at the start, held while it paws the ground, then down flat the moment it starts to run.
static func charge_rear(elapsed: float, tell: float) -> float:
	var run_at := tell * (1.0 - CHARGE_RUN_PART)
	if elapsed < run_at:
		return clampf(elapsed / 0.15, 0.0, 1.0)
	return clampf(1.0 - (elapsed - run_at) / 0.1, 0.0, 1.0)


## Dazed: a slow, gentle sway from side to side, like a dizzy dwarf (owner F450). A snail's body sways a bit more.
static func daze_sway(clock: float, snail: bool) -> float:
	return sin(clock * 4.0) * (0.15 if snail else 0.09) + sin(clock * 1.7) * 0.03


## Dazed: little stars circle its head (owner F449, every creature). Built the first time it is dazed.
func _daze_stars() -> void:
	var dazed: bool = stun.is_stunned() and is_alive() and not model.get_meta("roosting", false)  # (a hanging bat wakes when hit)
	if dazed and _stars == null:
		_stars = MonsterModel.add_daze_stars(model)
	if _stars:
		_stars.visible = dazed
		if dazed:
			MonsterModel.spin_daze_stars(_stars, _clock)


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
