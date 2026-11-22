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
## Lampwick Drift (owner, Nov 20: "if I aggro them from another room, they go to me"): its map says chase_out, and
## there a woken creature follows you anywhere in the dungeon (only a long way from home does it give up).
## dungeon_wake: more rooms where seeing you wakes it (the rats above the carts wake when you come into the junction).
var dungeon := {}
var dungeon_room := ""
var dungeon_wake: Array = []
var target_peer := 0
var stun := StunMeter.new()
var boosted := false  ## a living pack leader is near
var data: Dictionary
var model: Node3D
var rig: CreatureRig  ## only looks: a creature that moves by a skeleton (null: one that moves by named parts)
var _rise_pending := false  ## host: it started getting up; tell everyone (think)
var _timer := 0.0
const CHARGE_DAZE := 3.0  ## seconds a monster stands catching its breath after a pounce (F111; not a real daze)
const CHARGE_STARS := 2.5  ## s a beetle is really dazed (stars) after every charge, hit or miss (owner F471)
const CHARGE_AIM := 0.45   ## rad: a target this far off its nose is still charged at; farther, it runs where it looks
const CHARGE_GRIP := 80.0  ## m/s² a charging beetle speeds up (a normal step is 20: the charge died after 2-4 m, F472)
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
## Bats (F460): circling you before a dive, and the dive itself (host), and its trail (everyone, only looks).
var _orbit_a := 0.0          ## where on its circle round you it is (radians)
var _orbit_r := 5.0          ## how wide it circles
var _orbit_dir := 1.0        ## which way round
var _dive_wait := 99.0       ## seconds of circling before it may dive (99: no circle picked yet)
var _dive_dir := Vector3.ZERO  ## the straight line of this dive (locked when it starts: sidestep it)
var _dive_speed := 13.0
var _dive_out := false       ## flying on and climbing away after a dive
var _trail_left := 0.0       ## only looks: seconds it still leaves a trail
var _trail_pts: Array = []   ## only looks: [position, age, right side] of the trail behind it
var _streak: MeshInstance3D
var _vy := 0.0               ## only looks: how fast it rises or sinks (to tip its nose)
var _rise := 0.0
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
var _kd_daze := 0.0  ## finisher knockdown: seconds left frozen on the floor before rising


func setup(p_uid: int, p_kind: String, p_leader: bool, p_home: Vector3, p_variant: String = "") -> void:
	uid = p_uid
	kind = p_kind
	leader = p_leader
	home = p_home
	data = Monsters.info(kind)
	variant = p_variant if Monsters.VARIANTS.has(p_variant) and not data.get("no_variant", false) else ""
	hp = Monsters.max_hp(kind, leader, variant, Monsters.party())  # (more players: more health, F532)
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
	cap.height = maxf(cap.radius * 2.0, float(data.height) * s if data.has("height") else 0.9 * s + 0.3)
	shape.shape = cap
	shape.position = Vector3.UP * cap.height * 0.5
	add_child(shape)
	_body_shape = shape
	# A bat roost is one look per cave (owner, Nov 19: "5 frost ones, or 5 ember ones"); everyone else its own.
	var look_seed := pack_id if pack_id >= MonsterManager.BAT_KEY else -1
	model = MonsterModel.build(data.shape, data.color, s, leader, kind, uid, variant, look_seed)  # uid: same individual for everyone
	_size = s
	add_child(model)
	rig = CreatureRig.find(model)  # (a skeleton creature: it plays its model's own moves)
	if rig and data.get("front_shield", false):
		rig.hold_shield()  # (the Prop Warden: his plank shield up in front while he comes at you, F548)
	if rig and state == State.SLEEP and data.get("rises", false):
		model.rotation.y = fposmod(float(uid) * 2.39996, TAU)  # (each lies its own way: owner, Nov 20, "all the same direction")
		rig.lie()  # scattered on the floor until someone comes near (F462)
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


## Only looks: the pile of bones gets up (the host decided; everyone plays it).
func show_rise() -> void:
	_risen = true
	if rig:
		rig.rise()
		Sfx.play("dig_soft", global_position, -6.0, 0.6 * _voice())  # (a dry rattle of bones on the floor)


var _risen := false  ## only looks: it got up (a fighting stance from now on)


func _awake_looks() -> bool:
	return _risen or state in [State.ALERT, State.CHASE, State.ATTACK, State.RECOVER, State.STUNNED]


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
	if rig:
		# A skeleton creature flinches with its own move (owner F464: the pack's flinch plus our white flash).
		rig.hit()
		var fade := create_tween()
		fade.tween_property(glow, "albedo_color:a", 0.0, 0.16)
		fade.tween_callback(func():
			for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
				if mi.material_overlay == glow:
					mi.material_overlay = null)
		return
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
	if _stars:  # (owner, Nov 20: the daze stars stayed on the stone corpse)
		_stars.queue_free()
		_stars = null
	collision_layer = 0
	collision_mask = 0
	for l in find_children("*", "Label3D", true, false):
		l.visible = false
	if _bars:
		_bars.visible = false
	if rig is GhostRig and is_inside_tree():
		Ghost.vanish(self)  # a ghost fades into mist (no bones, no stone); it is gone when the mist is
		return
	if rig and is_inside_tree():
		# A skeleton falls apart into a pile of bones, then the bones turn to stone (owner F463).
		Statue.from_rig(self, model, statue, rig)
		queue_free.call_deferred()
		return
	if data.get("ragdoll", true):  # (every creature, owner Nov 18)
		# It goes limp and falls apart into physics pieces, pushed away from the player (Ragdoll, owner Nov 18).
		var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
		var from := cam.global_position if cam else global_position + Vector3.BACK
		# F602: killed during wind-up (rearing, velocity≈0) → give the ragdoll a small push in the charge direction.
		if state == State.ATTACK and _attack.get("lunge", false) and data.get("straight_charge", false) \
				and velocity.length() < 1.0 and model:
			var fwd := -Basis(Vector3.UP, model.rotation.y).z
			fwd.y = 0.0
			if fwd.length() > 0.1:
				velocity = fwd.normalized() * 2.5
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
	return Monsters.max_hp(kind, leader, variant, Monsters.party())


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
var _goal := Vector3.INF    ## (host) where it wants to get to, height and all (the dwarf it chases, its home): climbers
var _stop := 0.0            ## (looks) a frozen blink when hit
var _rest := 0.0            ## (host) standing still: seconds until it checks the floor again (speed, owner Nov 19)
var far_dt := 0.0           ## (host) time saved up while it thinks less often, far from every dwarf


## Host: pushed by a hit (speed in m/s, away from the hitter). It slides back and stops quickly.
func knock(push: Vector3) -> void:
	_knock = Vector3(push.x, 0.0, push.z)


## Host: non-lethal knockdown for `duration` seconds (falls apart, then rises). Used by finisher and stun.
func start_knockdown(duration: float) -> void:
	if rig == null or data.get("boss", false):
		return
	_kd_daze = duration
	if _knock.length() > 6.0:
		_knock = _knock.normalized() * 6.0  # keep the direction but cap so player can follow up
	rig.knock_down()
	collision_layer = 0  # walk through while on the floor (F651)


## Looks: a red outline round the whole creature while it winds up an attack no weapon parries (only a shield).
## For the multi-spin chain: each follow turn calls _red_outline again; a generation counter stops the previous
## timer clearing the outline early (F646).
static var _outline_mat: StandardMaterial3D
var _outline_gen := 0


func _red_outline(seconds: float) -> void:
	if _outline_mat == null:
		_outline_mat = StandardMaterial3D.new()
		_outline_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_outline_mat.albedo_color = Color(1.0, 0.08, 0.04)
		_outline_mat.cull_mode = BaseMaterial3D.CULL_FRONT  # (only the grown back faces show: a rim round it)
		_outline_mat.grow = true
		_outline_mat.grow_amount = 0.025
	_outline_gen += 1
	var gen := _outline_gen
	var meshes: Array = []
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		if mi.visible:
			mi.material_overlay = _outline_mat  # apply or re-apply; keeps it on through follow turns
			meshes.append(mi)
	get_tree().create_timer(seconds + 0.1).timeout.connect(func() -> void:
		if gen == _outline_gen:
			_clear_outline(meshes))  # only clear when no newer call has taken over


func _clear_outline(meshes: Array) -> void:
	for mi in meshes:
		if is_instance_valid(mi) and (mi as MeshInstance3D).material_overlay == _outline_mat:
			(mi as MeshInstance3D).material_overlay = null


## Looks: freeze for a blink (the hit "lands").
func hit_stop(seconds: float) -> void:
	_stop = maxf(_stop, seconds)


func think(delta: float, mgr: Node) -> void:
	if _rise_pending:
		_rise_pending = false
		mgr.monster_rise(self)  # everyone sees it get up
	_mgr = mgr
	if not (global_position.is_finite() and velocity.is_finite() and _knock.is_finite()):
		# Safety net (owner F564: the play log had 8,000 "not a number" warnings in 20 s from one creature, which also
		# cost frames): a creature whose place broke goes back home, standing still, instead of flooding the log.
		global_position = home + Vector3.UP * 0.3
		velocity = Vector3.ZERO
		_knock = Vector3.ZERO
		_dive_out = false
		_last_pos = global_position
	if _knock.length() > 0.05 and clinging():
		_knock = Vector3.ZERO  # (a creature on the wall doesn't slide; a hit knocks it off instead: _hurt_monster)
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
	if _kd_daze > 0.0:
		_kd_daze -= delta
		if _kd_daze <= 0.0 and rig != null and rig.knocked_down:
			rig.get_up()
			collision_layer = MONSTER_LAYER  # walkable again once upright (F651)
			_no_progress = 0.0  # don't give up immediately after getting up
		else:
			velocity = Vector3(0, velocity.y, 0)
			_move(delta, Vector3.ZERO, 0.0)
			return
	if stun.is_stunned():
		if rig != null and not rig.knocked_down and not rig.dead:  # stun start: fall apart
			rig.knock_down()
			collision_layer = 0  # walk through while stunned (F651)
		state = State.STUNNED
		velocity = Vector3(0, velocity.y, 0)
		_move(delta, Vector3.ZERO, 0.0)
		return
	if state == State.STUNNED:
		if rig != null and rig.knocked_down:  # stun ended: get back up
			rig.get_up()
			collision_layer = MONSTER_LAYER  # walkable again once upright (F651)
			_no_progress = 0.0  # don't give up immediately after getting up
		state = State.FLEE if data.get("passive", false) or (data.get("neutral", false) and hp < max_hp() * 0.5) else State.CHASE
		_timer = 6.0
	_think -= delta
	if _think <= 0.0:
		_think = 0.3
		_perceive(mgr)
	var target: Node3D = mgr.player_node(target_peer)
	_goal = target.global_position if target and state in [State.CHASE, State.ATTACK, State.RECOVER] \
		else (home if state == State.RETURN else Vector3.INF)
	if clinging() and _cling_think(delta, target, mgr):
		return
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
			if is_on_ceiling():
				_ceiling_check = 0.0  # it touched the rock: look again at once (circling, F460, it flies under lower rock)
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
			if variant == "violet" and not data.get("flies", false):
				# (Only walkers blink. A bat blinked onto the floor beside you: it "teleported when it attacked" and got
				# stuck in the floor, owner F564 / F368. A Shift-crested bat fights like any bat.)
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
			# F620: dungeon boss blocked by shaft/doorway geometry: give up quickly when literally not moving.
			if data.get("dungeon_only", false) and velocity.length() < 0.1 and _no_progress > 3.0:
				gives_up = true
			if data.get("stays_in_cave", false):  # (bats, F419: only when you leave their cave)
				gives_up = not mgr.in_cave(self, target.global_position) and not angry()
			if not dungeon.is_empty():
				var at_room := DungeonMap.space_at(dungeon, target.global_position + Vector3.UP)
				if (at_room == "" and not angry()) or (at_room != dungeon_room and not chases_out()):
					gives_up = true  # (you left its room; in Lampwick only when you leave the dungeon)
			if gives_up:
				state = State.RETURN
				target_peer = 0
				return
			if data.get("swoops", false):
				_circle_and_dive(delta, target, dist, mgr)
				return
			# Far above it (a hole's edge), or it's still clinging to the wall: climb up first, then fight (F236).
			var atk := _pick_attack(dist, mgr) if to.y < 1.3 and (is_on_floor() or to.y < 0.4) else {}
			if not atk.is_empty():
				_start_attack(atk, mgr)
				return
			var speed: float = data.run * (1.0 + (Monsters.PACK_BOOST.speed if boosted else 0.0)) * Ghost.rush(self)
			to.y = 0
			if data.get("no_push", false) and dist < 1.5:  # F609: stop before running into the player
				_move(delta, Vector3.ZERO, 0.0)
			else:
				_move(delta, to.normalized(), speed)
			_face(target)
		State.ATTACK:
			if _attack.get("dive", false):
				_dive_step(delta)
			elif _charge_dir == Vector3.ZERO:
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
				var charge_speed := lunge_speed(data, _attack)
				if data.get("straight_charge", false) or _attack.get("straight", false):
					# A charge doesn't steer: sidestep and it thunders past (then its back is open).
					# (`straight` on one attack: the Prop Warden's Shield Charge, F548; he breaks nothing on the way.)
					if _charge_dir == Vector3.ZERO:
						# Locked once, and it faces that way at once: no standing to turn in the middle of its run (F472).
						_charge_dir = charge_line(-Basis(Vector3.UP, model.rotation.y).z, rush)
						model.rotation.y = atan2(-_charge_dir.x, -_charge_dir.z)
					_move(delta, _charge_dir, charge_speed)
					if data.get("straight_charge", false):
						mgr.charge_smash(self, _charge_dir)  # it breaks what it runs into (owner F447)
				elif rush.length() > 1.2:
					_move(delta, rush.normalized(), charge_speed)
				else:
					_move(delta, Vector3.ZERO, 0.0)
			elif _attack.has("whirl_speed") and target:
				# The Foreman's whirl (owner, Nov 21: "he should move towards the player, you have to dodge that"):
				# while it keeps spinning he slides after you at about your walking speed.
				var after := target.global_position - global_position
				after.y = 0
				_move(delta, after.normalized() if after.length() > 0.8 else Vector3.ZERO, float(_attack.whirl_speed))
			elif not _attack.get("dive", false):
				_move(delta, Vector3.ZERO, 0.0)
			if _timer <= 0.0:
				if _attack.has("raise_miners"):
					mgr.finish_raise(self)  # (the Prop Warden's Rally Slam: his fallen miners get up)
				elif data.get("smashes_statues", false):
					mgr.smash_statues_in_reach(self, _attack)  # (the Foreman's swings break fallen miners' stone, owner Nov 20)
				mgr.attack_smash_things(self, _attack)  # F603: break furniture within attack reach
				if _attack.has("follow"):
					var f: Dictionary = _attack.follow
					var next := _attack.duplicate()
					for k in f:  # (tell, damage, and anything else the next blow changes; null = drop it, e.g. a warning sound)
						if f[k] == null:
							next.erase(k)
						elif k != "follow":
							next[k] = f[k]
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
						if MonsterManager.is_charge(_attack) and data.get("straight_charge", false):
							daze_after_charge(mgr)
					_charge_dir = Vector3.ZERO
					if _attack.get("dive", false):
						_timer = DIVE_OUT  # it doesn't stop: on through you and up again
						_dive_out = true
						_wander_to = Vector3.INF
					elif data.get("hit_and_run", false):
						var away: float = data.get("retreat", 3.0)
						_wander_to = global_position - (target.global_position - global_position).normalized() * away if target else home
		State.RECOVER:
			if _dive_out:
				# On through you, slowing from dive speed to its cruise and climbing back up (the height: _alt).
				# (Straight on, no wobble and no stopping to turn: it already faces this way.)
				var k := clampf(1.0 - _timer / DIVE_OUT, 0.0, 1.0)
				var flat := Vector3(_dive_dir.x, 0.0, _dive_dir.z).normalized() * lerpf(_dive_speed, data.run, k)
				velocity = Vector3(flat.x, clampf((_alt - global_position.y) * 3.0, -7.0, 6.0) if _alt != INF else 0.0, flat.z)
				move_and_slide()
			elif data.get("hit_and_run", false) and _wander_to != Vector3.INF:
				var back := _wander_to - global_position
				back.y = 0
				_move(delta, back.normalized(), data.run * 0.6)
			else:
				_move(delta, Vector3.ZERO, 0.0)
			if _timer <= 0.0:
				state = State.CHASE
				if _dive_out:
					_dive_out = false
					_new_circle(target)
		State.RETURN:
			hp = minf(max_hp(), hp + max_hp() * 0.1 * delta)
			var to := home - global_position
			to.y = 0
			var dist_home := to.length()
			if dist_home < 1.5:
				state = State.IDLE
				_timer = randf_range(3.0, 8.0)
				_best_dist = INF
				_no_progress = 0.0
				mgr.monster_changed(self)
			else:
				if dist_home < _best_dist - 0.5:
					_best_dist = dist_home
					_no_progress = 0.0
				else:
					_no_progress += delta
				if _no_progress > 5.0 and data.get("dungeon_only", false):  # F610: teleport home if stuck in doorway/shaft
					global_position = home + Vector3.UP * 0.1
					_best_dist = INF
					_no_progress = 0.0
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
	if state == State.SLEEP and data.get("rises", false):
		_start_rise()
		mgr.alert_pack(self, found)  # (the whole room gets up together)
	elif state == State.SLEEP or state == State.IDLE or state == State.WANDER or state == State.RETURN:
		state = State.ALERT
		_timer = 0.8
		mgr.alert_pack(self, found)


## A pile of bones gets up (F462): it stands still while it rises (ALERT), then runs at you.
func _start_rise() -> void:
	state = State.ALERT
	_timer = RISE_TIME
	_rise_pending = true


const RISE_TIME := 2.3  ## s: the getting-up move (Skeletons_Awaken_Floor is 2.29 s)


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
	if data.get("rises", false) and (state == State.SLEEP or (state == State.ALERT and _timer > 0.0)):
		target_peer = peer
		if state == State.SLEEP:
			_start_rise()  # hit or called while lying: it gets up first (it can't fight from the floor)
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


## Bats (owner F460): loop round you in a loose, wobbly circle (each bat its own size and way round), then dive
## through you. Only one bat of a pack starts a dive every DIVE_GAP seconds, so they take turns.
func _circle_and_dive(delta: float, target: Node3D, dist: float, mgr: Node) -> void:
	if _dive_wait > 50.0:
		_new_circle(target)
	var r := _orbit_r * (1.0 + 0.15 * sin(_clock * 0.7 + uid))  # the circle breathes in and out
	_orbit_a += _orbit_dir * data.run / maxf(r, 1.0) * delta * 0.8
	var want := target.global_position + Vector3(cos(_orbit_a), 0.0, sin(_orbit_a)) * r
	var go := want - global_position
	go.y = 0.0
	_move(delta, go.normalized() if go.length() > 0.3 else Vector3.ZERO, data.run * (1.0 + (Monsters.PACK_BOOST.speed if boosted else 0.0)))
	_dive_wait -= delta
	if _dive_wait <= 0.0 and dist >= DIVE_MIN and dist <= DIVE_MAX and mgr.may_dive(self) and _clear_line(target):
		_start_dive(target, mgr)


## A fresh circle round the target, starting where it is now; a few seconds before its next dive.
func _new_circle(target: Node3D) -> void:
	var off := global_position - (target.global_position if target else home)
	_orbit_a = atan2(off.z, off.x)
	_orbit_r = randf_range(4.0, 6.5)
	_orbit_dir = 1.0 if randf() < 0.5 else -1.0
	_dive_wait = randf_range(1.5, 3.5)


## Nothing (rock, a wall you built) between it and your chest?
func _clear_line(target: Node3D) -> bool:
	var q := PhysicsRayQueryParameters3D.create(global_position, target.global_position + Vector3.UP * 0.9,
		World.TERRAIN_LAYER | PieceNode.PIECE_LAYER)
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


## The dive: a straight line at where your chest is right now. Its warning lasts exactly until it gets there, so the
## bite is judged as it passes through you (sidestep and it misses).
func _start_dive(target: Node3D, mgr: Node) -> void:
	var aim := target.global_position + Vector3.UP * 0.9
	var line := aim - global_position
	_dive_dir = line.normalized()
	_dive_speed = float(data.run) * DIVE_SPEED
	var glide: float = minf(DIVE_WIND * float(data.walk), line.length() * 0.5)
	var atk: Dictionary = data.attacks[0].duplicate()
	atk.tell = DIVE_WIND + (line.length() - glide) / _dive_speed
	_start_attack(atk, mgr)


## One step of the dive: a slow glide along its line for a moment, then it shoots down it (through you).
func _dive_step(delta: float) -> void:
	var since: float = _attack.tell - _timer
	velocity = _dive_dir * (float(data.walk) if since < DIVE_WIND else _dive_speed)
	model.rotation.y = atan2(-_dive_dir.x, -_dive_dir.z)
	move_and_slide()


## Attack name -> _clock time it may be used again (attacks with `rest`, e.g. the Foreman's spin).
var _rest_until := {}
var raising: Array = []  ## (host) the Prop Warden's Rally Slam: the statue ids he is raising now


## `mgr` (when given) lets a raise move be picked only while there is a fallen miner to raise.
func _pick_attack(dist: float, mgr: Node = null) -> Dictionary:
	var options := []
	for a in attack_options():
		if a.has("raise_miners") and (mgr == null or mgr.raisable_statues(self).is_empty()):
			continue
		if dist <= a.reach and dist >= a.get("min_reach", 0.0) and (not a.get("lunge", false) or dist > 2.0) 				and _clock >= float(_rest_until.get(a.name, 0.0)):
			options.append(a)
	if options.is_empty():
		return {}
	# F622: prefer a whirl/spin when the player is running fast (the spin chases a moving target).
	if mgr != null and target_peer != 0:
		var tgt: Node3D = mgr.player_node(target_peer)
		if tgt is CharacterBody3D and (tgt as CharacterBody3D).velocity.length() > 4.0:
			var spinners: Array = options.filter(func(a: Dictionary) -> bool: return a.has("whirl_speed"))
			if not spinners.is_empty():
				return spinners[0]
	return options.pick_random()


func _start_attack(atk: Dictionary, mgr: Node) -> void:
	if rig != null and rig.knocked_down:
		return  # never start an attack while on the floor (F652)
	if atk.has("rest"):
		_rest_until[atk.name] = _clock + float(atk.rest)
	if atk.has("quiet_after"):
		# No other swing until this long after the blow (F526: a Lost Miner's leap is its only blow, no chop on landing).
		for o: Dictionary in attack_options():
			if o.name != atk.name:
				_rest_until[o.name] = maxf(float(_rest_until.get(o.name, 0.0)), _clock + float(atk.tell) + float(atk.quiet_after))
	# F602: snap to face the player before the wind-up so a straight charge never starts half-turned.
	if atk.get("lunge", false) and data.get("straight_charge", false) and target_peer != 0:
		var tgt: Node3D = mgr.player_node(target_peer)
		if tgt != null:
			var to_tgt: Vector3 = (tgt.global_position - global_position) * Vector3(1, 0, 1)
			if to_tgt.length() > 0.1:
				model.rotation.y = atan2(-to_tgt.x, -to_tgt.z)
	_attack = atk
	_charge_dir = Vector3.ZERO  # a new charge picks its own straight line
	state = State.ATTACK
	_timer = atk.tell
	mgr.send_tell(self, atk)
	if atk.has("raise_miners"):
		mgr.start_raise(self, atk)


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


func chases_out() -> bool:
	return (not dungeon.is_empty() and bool(dungeon.map.get("chase_out", false))) or angry()


## Hit (owner F572 🔁, Nov 21: "I shot them from another room and they did nothing"): for GRUDGE seconds after a hit it
## follows you out of its room, its dungeon or its bat cave, instead of giving up at once because you stand elsewhere.
const GRUDGE := 15.0
var grudge_until := -1.0  ## (host) its _clock time the grudge ends


func hurt_by_someone() -> void:
	grudge_until = _clock + GRUDGE


func angry() -> bool:
	return _clock < grudge_until


## A dungeon creature may step to `p`: still in its own room, not under a crusher. One that already stands outside its
## room (`from`: pushed or slid into a doorway) may walk anywhere but under a crusher, so it can get back in: before,
## every step from a doorway was "out of its room", so it stood there charging and dazing itself over and over (owner,
## Nov 20, F473).
func may_step(p: Vector3, from := Vector3.INF) -> bool:
	if chases_out() and state in [State.CHASE, State.ATTACK, State.RECOVER, State.RETURN]:
		return DungeonMap.space_at(dungeon, p + Vector3.UP * 0.5) != "" and (DungeonBuild.instance == null or not DungeonBuild.instance.near_crusher(p))
	var outside_now := from != Vector3.INF and DungeonMap.space_at(dungeon, from + Vector3.UP * 0.5) != dungeon_room
	if not outside_now and DungeonMap.space_at(dungeon, p + Vector3.UP * 0.5) != dungeon_room:
		return false
	return DungeonBuild.instance == null or not DungeonBuild.instance.near_crusher(p)


func _move(delta: float, dir: Vector3, speed: float) -> void:
	speed *= ailments.speed_mult()
	if clinging():
		_crawl(delta, dir, speed)  # on a wall or ceiling: its feeler keeps it stuck to the rock (F236, F474, F475)
		return
	if data.get("weaves", false) and dir.length() > 0.1 and state != State.ATTACK:
		dir = weave(dir)
	var charging := state == State.ATTACK and _charge_dir != Vector3.ZERO  # (straight on, full grip: F472)
	if data.get("turns_in_place", false) and not charging:
		var turned := _turn_toward(dir, delta)
		dir = turned[0]
		speed *= turned[1]
	var blocked := false
	if dir.length() > 0.1 and not data.get("flies", false) and is_on_floor() and _drop_ahead(dir):
		blocked = true  # a pit it couldn't climb out of: stop at the edge and find another way (F125)
	if dir.length() > 0.1 and not dungeon.is_empty() and not data.get("flies", false) \
			and not may_step(global_position + Vector3(dir.x, 0, dir.z).normalized() * 0.7, global_position):
		blocked = true  # (a dungeon creature stops at its room's doorway and in front of a crusher)
	if blocked:
		dir = Vector3.ZERO
		velocity.x = 0.0  # it stops right there: a charge used to slide on, out of its room into the doorway (F473)
		velocity.z = 0.0
	if data.get("flies", false):
		# Smooth flight (F630): the speed and the way it flies change gradually, not in one frame.
		var want := Vector2(dir.x, dir.z) * speed
		var flat := Vector2(velocity.x, velocity.z).move_toward(want, FLY_ACCEL * delta)
		velocity = Vector3(flat.x, 0.0, flat.y)
		if data.get("swoops", false) and _alt != INF:
			velocity.y = clampf((_alt - global_position.y) * 2.0, -FLY_CLIMB, FLY_CLIMB)
	else:
		var grip := CHARGE_GRIP if charging else 20.0
		velocity.x = move_toward(velocity.x, dir.x * speed, grip * delta)
		velocity.z = move_toward(velocity.z, dir.z * speed, grip * delta)
		velocity.y -= _gravity * delta
		if is_on_floor():
			velocity.y = maxf(velocity.y, -0.5)
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
	if _falling != "" and is_on_floor():
		_landed()
	elif not data.get("flies", false) and dir.length() > 0.1 and is_on_wall():
		_try_cling(dir)


# ================================================================== climbing walls and ceilings (F236, F474, F475)
# The owner's decisions: docs/decisions/2026-11-20-creature-climbing.md. A climber (Monsters.LIST `climbs`: "walls" or
# "all") that clings to rock has `surface` = the way that rock faces (its normal). Its whole body is turned so its feet
# touch the rock; every step a feeler (a ray) finds the rock under its feet again and it slides along it ("stick with
# feelers"; rejected: turning gravity sideways, which jitters on bumpy rock and breaks every "on the floor?" check).
# The host moves it and decides when it lets go; everyone hears which surface it is on (MonsterManager._ev_cling).

var surface := Vector3.ZERO  ## everyone: the way the rock it clings to faces (ZERO: on the floor, as before)
var _mgr: Node               ## host: the manager (set every think)
var _falling := ""           ## host: falling off: "knocked" (a hit: lands on its shell, dazed), "drop" (ambush: bites as it lands), "fall"
var _hiss := 0.0             ## host: an ambush hiss: seconds before it lets go
var _grip_lost := 0.0        ## host: seconds its feeler found no rock (dug away): then it falls
var _feel_wait := 0.0        ## host: sitting still up there: seconds until it feels for the rock again
var _sent_surface := Vector3.ZERO  ## host: the surface everyone last heard about
var _on_back := 0.0          ## looks: seconds it still lies on its shell after being knocked down
const FLOOR_UP := 0.7        ## a surface this flat (its normal's height) is a floor: walked on, not clung to
const CEILING_DOWN := -0.35  ## a surface facing down more than this is a ceiling
const CLING_SPEED := 0.8     ## a climber moves this part of its floor speed on a wall
const FEEL := 0.9            ## m the feeler reaches into the rock
const HISS_TIME := 0.6       ## s between the ambush hiss and the drop (owner: "a short hiss first so I can dodge")
const AMBUSH_NEAR := 1.8     ## m (flat) from right over you, it hisses and lets go
const FALL_DAZE := 4.0       ## s a knocked-down snail lies dazed on its shell (owner)
const UP_HIGH := 0.25        ## part of the snails and spiders that start on a wall or ceiling (owner: "about 1 in 4")
const DROP_BITE_TELL := 0.2  ## s: landing by you, its bite comes this fast (step away while it falls)


func climbs() -> String:
	return String(data.get("climbs", ""))


func clinging() -> bool:
	return surface != Vector3.ZERO


## May a creature that climbs `how` ("", "walls", "all") cling to rock facing `n`?
static func may_cling(how: String, n: Vector3) -> bool:
	if how == "" or n.y >= FLOOR_UP:
		return false
	if n.y < CEILING_DOWN:
		return how == "all"  # a ceiling (the Rock Beetle: walls only, owner)
	return true


## A turn that stands "up" on `n` (feet on the rock).
static func up_on(n: Vector3) -> Basis:
	if n == Vector3.ZERO:
		return Basis.IDENTITY
	n = n.normalized()
	if n.dot(Vector3.UP) < -0.999:
		return Basis(Vector3.RIGHT, PI)
	return Basis(Quaternion(Vector3.UP, n))


## Everyone: turn the body onto the surface it is on (ZERO: upright on the floor).
func apply_surface(n: Vector3) -> void:
	surface = n
	global_transform.basis = up_on(n)
	velocity = Vector3.ZERO


## Host: it takes hold of the rock at `p` (facing `n`).
func cling_to(p: Vector3, n: Vector3, cue := "") -> void:
	_falling = ""
	_grip_lost = 0.0
	global_position = p
	apply_surface(n)
	_tell_surface(cue)


## Host: it lets go of the wall or ceiling (or is knocked off) and falls. `why`: see _falling.
func let_go(why: String) -> void:
	if not clinging():
		return
	var n := surface
	var r := (_body_shape.shape as CapsuleShape3D).radius if _body_shape else 0.4
	# Off the rock first, upright again: under a ceiling a whole body below it, off a wall a body's width out.
	global_position += n * ((_body_height() if n.y < CEILING_DOWN else r) + 0.08)
	apply_surface(Vector3.ZERO)
	_falling = why
	_hiss = 0.0
	_tell_surface("fall")


## Host: knocked off by a hit (owner: any hit on a snail up high knocks it down; it lands dazed on its shell).
func knocked_off() -> void:
	if clinging():
		let_go("knocked" if data.get("falls_dazed", false) else "fall")


func _tell_surface(cue := "") -> void:
	_sent_surface = surface
	if _mgr and _mgr.has_method("monster_cling"):
		_mgr.monster_cling(self, cue)


func _set_surface(n: Vector3) -> void:
	apply_surface(n)
	if _sent_surface == Vector3.ZERO or n.angle_to(_sent_surface) > 0.3:
		_tell_surface()


func _feel(from: Vector3, dir: Vector3, length: float) -> Dictionary:
	if not is_inside_tree():
		return {}
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * length, World.TERRAIN_LAYER)
	return get_world_3d().direct_space_state.intersect_ray(q)


## Host, on the floor, pushing into a wall: a climber takes hold of it. Spiders run along walls whenever one is in the
## way of a chase (owner); snails and beetles only climb to get up to you or home (out of holes, up ledges).
func _try_cling(dir: Vector3) -> void:
	var how := climbs()
	if how == "" or state not in [State.CHASE, State.RETURN]:
		return
	var wn := get_wall_normal()
	if Vector3(dir.x, 0.0, dir.z).normalized().dot(-wn) < 0.3:
		return  # (it brushes along the wall, it isn't walking into it)
	var above := _goal != Vector3.INF and _goal.y > global_position.y + 0.6
	if not above and not (data.get("wall_runner", false) and state == State.CHASE):
		return
	var hit := _feel(global_position + Vector3.UP * 0.4, -wn, 1.2)
	if hit.is_empty() or not may_cling(how, hit.normal):
		return
	cling_to(hit.position, hit.normal)


## Host: the thinking of a creature on a wall or ceiling. True: done for this step.
func _cling_think(delta: float, target: Node3D, _m: Node) -> bool:
	if _hiss > 0.0:
		_hiss -= delta  # (it holds still and hisses: look up and step aside)
		if _hiss <= 0.0:
			let_go("drop")
		return true
	match state:
		State.CHASE:
			if target == null or MonsterManager.ignores(target):
				return false  # (the floor thinking sends it home)
			var to := target.global_position - global_position
			var d3 := to.length()
			if d3 < _best_dist - 0.5:
				_best_dist = d3
				_no_progress = 0.0
			else:
				_no_progress += delta
			if _no_progress > Monsters.GIVE_UP:
				let_go("fall")  # (it can't get to you along the rock: it drops and tries the floor)
				return true
			var flat := Vector2(to.x, to.z).length()
			var on_ceiling := surface.y < CEILING_DOWN
			if to.y < -0.8 and flat < (AMBUSH_NEAR if on_ceiling else 1.6):
				if on_ceiling and data.get("ambush", false):
					_hiss = HISS_TIME  # right over you: a short hiss, then it drops on you (owner)
					_tell_surface("hiss")
				else:
					let_go("drop" if data.get("ambush", false) else "fall")
				return true
			_move(delta, Vector3(to.x, 0.0, to.z).normalized(), data.run)
			return true
		State.IDLE, State.WANDER, State.SLEEP:
			if state == State.WANDER:
				state = State.IDLE  # (up there it waits; it doesn't wander off along the rock)
			_timer = maxf(_timer, 2.0)
			_move(delta, Vector3.ZERO, 0.0)
			return true
	return false


## Host: one step along the rock toward `dir` (or toward _goal, height and all, when it has one).
func _crawl(delta: float, dir: Vector3, speed: float) -> void:
	var n := surface
	var want := dir
	if _goal != Vector3.INF and dir.length() > 0.1:
		want = _goal - global_position  # (the wall leads up or down to it)
	var t := want - n * want.dot(n)
	if t.length() < 0.05 or speed <= 0.0 or dir.length() < 0.1:
		# Sitting still: twice a second it checks the rock is still there (a dwarf may dig it away).
		_feel_wait -= delta
		if _feel_wait > 0.0:
			return
		_feel_wait = 0.5
		if _feel(global_position + n * 0.3, -n, FEEL).is_empty():
			_grip_lost += 0.5
			if _grip_lost >= 1.0:
				let_go("fall")
		else:
			_grip_lost = 0.0
		return
	_feel_wait = 0.0
	t = t.normalized()
	_face_along(t)
	var step := speed * CLING_SPEED * delta
	var p := global_position
	# A corner going in (the wall meets the ceiling or the floor): rock right ahead along the surface.
	var ahead := _feel(p + n * 0.25, t, step + 0.3)
	if not ahead.is_empty():
		var n2: Vector3 = ahead.normal
		if n2.y >= FLOOR_UP:
			_step_onto_floor(ahead.position + n * ((_body_shape.shape as CapsuleShape3D).radius + 0.05))
		elif may_cling(climbs(), n2):
			global_position = ahead.position
			_set_surface(n2)
		else:
			let_go("fall")  # (a beetle reaching a ceiling can't hold on there)
		return
	if not dungeon.is_empty() and not may_step(p + t * step, p):
		return  # (a dungeon creature keeps to its own room on the walls too)
	p += t * step
	var under := _feel(p + n * 0.4, -n, FEEL)
	if under.is_empty():
		under = _feel(p - n * 0.35, -t, 0.9)  # a corner going out (over a hole's lip): feel round it
	if under.is_empty():
		_grip_lost += delta
		if _grip_lost > 0.6:
			let_go("fall")
		return
	_grip_lost = 0.0
	var n3: Vector3 = under.normal
	if n3.y >= FLOOR_UP:
		_step_onto_floor(under.position - Vector3(n.x, 0.0, n.z) * 0.2)  # over the lip, a little in from the edge
		return
	if not may_cling(climbs(), n3):
		let_go("fall")
		return
	global_position = under.position
	_set_surface(n.lerp(n3.normalized(), minf(1.0, delta * 12.0)).normalized())


func _step_onto_floor(at: Vector3) -> void:
	global_position = at + Vector3.UP * 0.05
	apply_surface(Vector3.ZERO)
	_tell_surface()


## Host: it hit the floor after falling.
func _landed() -> void:
	var why := _falling
	_falling = ""
	if why == "knocked":
		# On its shell, dazed with stars (owner F475); everyone sees it lie there.
		stun.value = 0.0
		stun.stunned_left = maxf(stun.stunned_left, FALL_DAZE)
		state = State.STUNNED
		_tell_surface("on_back")
		if _mgr:
			_mgr.monster_changed(self)
	elif why == "drop" and _mgr:
		state = State.CHASE
		_best_dist = INF
		_no_progress = 0.0
		for a: Dictionary in data.get("attacks", []):
			if not a.get("lunge", false) and mgr_target_near(a.reach + 0.5):
				var bite := a.duplicate()
				bite.tell = DROP_BITE_TELL  # landing by you it bites at once (you dodge by stepping away while it falls)
				_start_attack(bite, _mgr)
				break


## How fast a creature rushes in during a charge or a leap (an attack may set its own: the Lost Miner's leap is slower
## than you walk, F593).
static func lunge_speed(d: Dictionary, atk: Dictionary) -> float:
	if atk.has("lunge_speed"):
		return float(atk.lunge_speed)
	return maxf(float(d.run) * 2.0, float(atk.reach) / maxf(float(atk.tell) * 0.6, 0.1))


func mgr_target_near(r: float) -> bool:
	var target: Node3D = _mgr.player_node(target_peer) if _mgr else null
	return target != null and target.global_position.distance_to(global_position) < r


## Its face turns along the rock toward `t` (a world direction along the surface).
func _face_along(t: Vector3) -> void:
	var local := global_transform.basis.inverse() * t
	if Vector2(local.x, local.z).length() > 0.05:
		model.rotation.y = lerp_angle(model.rotation.y, atan2(-local.x, -local.z), 0.3)


## Where a snail or spider that starts up high clings near `floor_spot` (its floor spawn spot), or {} if there's no good
## rock: a ceiling high enough to walk under ("all" climbers), else a wall a little above head height. Never over or in
## something built or on its paths (CLAUDE.md placement rule): Monster.high_spot_clear. Planned on the cave's shape
## (the host, at spawn).
static func high_spot(maker: CaveMaker, floor_spot: Vector3, how: String, rng: RandomNumberGenerator) -> Dictionary:
	if how == "":
		return {}
	if maker.is_reserved(floor_spot, HIGH_CLEAR):
		return {}  # (standing on kept-clear ground, e.g. a dungeon's doorway: it stays down; Old Pell's door, seed 7)
	if how == "all" and rng.randf() < 0.6:
		var c := GlowPlacer._march(maker, floor_spot + Vector3.UP * 1.0, Vector3.UP, 9.0)
		if c != Vector3.INF and c.y - floor_spot.y > 2.4:
			var n := GlowPlacer.normal_at(maker, c + Vector3.DOWN * 0.3)
			if may_cling(how, n) and high_spot_clear(maker, c, floor_spot):
				return {pos = c, normal = n}
	for i in 4:
		var a := rng.randf() * TAU
		var from := floor_spot + Vector3.UP * rng.randf_range(1.6, 2.8)
		var w := GlowPlacer._march(maker, from, Vector3(cos(a), 0.0, sin(a)), 8.0)
		if w == Vector3.INF:
			continue
		var n := GlowPlacer.normal_at(maker, w - Vector3(cos(a), 0.0, sin(a)) * 0.3)
		var below := maker.find_floor(w.x + n.x, w.z + n.z, w.y)
		if may_cling(how, n) and w.y - below.y > 1.3 and high_spot_clear(maker, w, below):
			return {pos = w, normal = n}
	return {}


const HIGH_CLEAR := 1.5  ## m it keeps from built ground (the tower, the Outpost, dungeons and their doorways)
const HIGH_POI_CLEAR := 8.0  ## m it keeps from a place (ruins, camps, the great hall: their paths and stairs)


## The placement rule for creatures up high: not in or over something built, not over its paths (the floor below too).
static func high_spot_clear(maker: CaveMaker, at: Vector3, floor_below: Vector3) -> bool:
	for p in [at, floor_below]:
		if maker.is_reserved(p, HIGH_CLEAR) or maker.in_dungeon_stone(p) or not maker._far_from_pois(p, HIGH_POI_CLEAR):
			return false
	return true


## How high the rock is above this flyer (INF: more than 12 m of room).
const CEILING_ROOM := 0.3  ## m a flyer keeps between its back and the ceiling
const DIVE_SPEED := 2.0    ## a dive is this many times its normal flying speed (owner F460: "twice as fast")
const DIVE_WIND := 0.25    ## s it glides slowly along its line before shooting down it (its screech warns you)
const DIVE_OUT := 1.1      ## s it flies on and climbs away after passing through you
const DIVE_MIN := 3.0      ## m: it dives from this far away...
const DIVE_MAX := 11.0     ## ...up to this far
const TRAIL_LIFE := 0.4    ## s a bit of the trail lasts
const TRAIL_TINT := Color(0.9, 0.91, 0.95)  ## the streak of air behind a diving bat: the same pale air for every bat (F563)
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
	if clinging():
		_face_along(to - surface * to.dot(surface))  # (on the rock it turns about its own feet)
		return
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
const FLY_TURN_SLOW := 0.55  ## a flyer turning right round still flies at this part of its speed (F630)
const FLY_ACCEL := 9.0   ## m/s² a flyer speeds up, slows down and swings its flight with (F630: no instant changes)
const FLY_CLIMB := 3.5   ## m/s a flyer climbs or sinks at most while cruising (it was 6-7: it bobbed up and down fast)


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
	if data.get("flies", false):
		# A bat never stops in the air to turn (owner, Nov 22, F630: "very sharp turns"): it flies on along its own
		# nose while it swings round, like a bird banking, a little slower in a tight turn.
		return [-Basis(Vector3.UP, model.rotation.y).z, FLY_TURN_SLOW + (1.0 - FLY_TURN_SLOW) * maxf(0.0, cos(diff))]
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
	if String(atk.get("parry", "any")) == "shield":
		_red_outline(seconds)  # (owner, Nov 20: the Foreman's spin can't be parried with a weapon: a red outline says so)
	if atk.get("spit", false):
		# The Rock Snail's spit (owner, Nov 17): he rears up, snaps forward and a gob flies 2-3 m (MonsterModel._snail).
		model.set_meta("spit_t0", _clock + uid * 0.37)  # (the clock MonsterModel.animate gets)
		model.set_meta("spit_len", seconds)
		get_tree().create_timer(seconds).timeout.connect(_spit_fx.bind(aim))
		return
		Sfx.play(atk.warn_sound, global_position, 0.0, _voice())
	if atk.has("land_sound"):
		get_tree().create_timer(seconds).timeout.connect(_land_sound.bind(atk.land_sound))
	if atk.get("dive", false):
		_trail_left = seconds + 0.5  # a streak of air behind it while it dives through you and climbs away (F460)
	if atk.get("lunge", false) and data.get("straight_charge", false):
		_charging = seconds + 0.6
		_charge_len = seconds
		MonsterModel.set_angry(model, true)
	if rig:
		rig.attack(String(atk.get("anim", "1H_Melee_Attack_Chop")), seconds, String(atk.get("parry", "")) == "shield",
			atk.has("whirl_speed"))  # its own swing; the blow lands with the hit (a whirl's next turns: no new wind-up)
		return
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
	if not is_alive() or not is_inside_tree() or shell_shut:  # F601: shell hides cancel the spit
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
	if clinging():
		moved = minf(global_position.distance_to(_last_pos), 1.0)  # (up a wall it moves up: its legs still walk)
	_rise = global_position.y - _last_pos.y
	if absf(_rise) > 1.0:
		_rise = 0.0  # (put somewhere new, not flown there: no nose tip)
	_last_pos = global_position
	_speed = lerpf(_speed, moved / maxf(delta, 0.001), minf(1.0, delta * 8.0))
	_clock += delta
	model.set_meta("roosting", data.get("roosts", false) and state == State.SLEEP)
	_hang_body(model.get_meta("roosting"))
	if rig:
		rig.step(delta, _speed, float(data.run), _awake_looks(), _stop > 0.0)
		_stop = maxf(0.0, _stop - delta)
	elif _stop > 0.0:
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
	if data.get("flies", false) and not model.get_meta("roosting", false):
		# A flyer tips its nose down as it dives and up as it climbs (F460).
		_vy = lerpf(_vy, _rise / maxf(delta, 0.001), minf(1.0, delta * 10.0))
		model.rotation.x += clampf(atan2(_vy, maxf(_speed, 1.0)), -0.8, 0.6) * 0.8
	if _trail_left > 0.0 or not _trail_pts.is_empty():
		_draw_trail(delta)
	if rig:
		pass  # (its moves do the walking and the daze sways nothing: no waddle on top)
	elif model.get_meta("roosting", false):
		pass  # hanging upside down (MonsterModel.animate)
	elif stun.is_stunned():
		MonsterModel.dazed_sway(model, daze_sway(_clock, model.has_meta("foot")))  # (a snail sways, its foot stays put)
	elif model.has_meta("foot"):
		MonsterModel.dazed_sway(model, 0.0)  # a snail hops, it doesn't waddle
	else:
		MonsterModel.dazed_sway(model, 0.0)  # (puts a swayed shell back once the daze is over)
		model.rotation.z = sin(_clock * (5.0 + _speed * 2.5)) * 0.07 * clampf(_speed / 3.0, 0.0, 1.0)  # waddle
	_lie_on_back(delta)


## Everyone (from the host, MonsterManager._ev_cling): the creature is now on this surface (ZERO: the floor).
## `cue`: "hiss" (an ambush: it is about to drop), "on_back" (knocked down: lies on its shell), "fall", "".
func show_cling(pos: Vector3, n: Vector3, cue: String) -> void:
	global_position = pos  # (the host is already there: the same numbers)
	_net_pos = pos
	apply_surface(n)
	match cue:
		"hiss":
			_flash = HISS_TIME
			Sfx.play("beetle_hiss", global_position, 2.0, 1.3 * _voice())  # (a sharper, higher hiss than its bite)
		"on_back":
			_on_back = FALL_DAZE
			Sfx.play("shell_clunk", global_position, 0.0, _voice())


## Only looks: a knocked-down snail lies upside down on its shell, legs (its foot) in the air, then rolls back.
func _lie_on_back(delta: float) -> void:
	if _on_back <= 0.0 and not model.has_meta("back_pos"):
		return
	if not model.has_meta("back_pos"):
		model.set_meta("back_pos", model.position)
	_on_back = maxf(0.0, _on_back - delta)
	var k := clampf(minf((FALL_DAZE - _on_back) / 0.25, _on_back / 0.4), 0.0, 1.0)
	k = k * k * (3.0 - 2.0 * k)  # (eased over and back)
	model.rotation.z = PI * k
	model.position = (model.get_meta("back_pos") as Vector3) + Vector3.UP * _body_height() * 0.8 * k
	if _stars:
		# The stars keep circling over it, not under the floor.
		_stars.top_level = k > 0.0
		if _stars.top_level:
			_stars.global_position = global_position + Vector3.UP * (_body_height() + 0.2)
	if _on_back <= 0.0:
		model.position = model.get_meta("back_pos")
		model.remove_meta("back_pos")


## Only looks and sounds: charge dust, wing beats, the jolt when hit.
func _creature_fx(delta: float) -> void:
	if _charging > 0.0:
		_charging -= delta
		_dust_t -= delta
		if _dust_t <= 0.0:
			var fast := _speed > 2.5
			_dust_t = 0.05 if fast else 0.2  # pawing the ground, then a trail while it thunders along
			# Big, light puffs left behind it (owner, Nov 20, liked the 3D page's trail: the old small dark ones
			# were hard to see in a cave).
			var back := global_basis.z * Vector3(1, 0, 1) * 0.4 * _size
			Fx.dust(get_parent(), global_position + back, Color(0.66, 0.6, 0.5), 4 if fast else 2, (0.9 if fast else 0.7) * _size)
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
	if _flinch > 0.0 and rig == null:
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


## Which way a charge runs (F472): straight at the target if it is roughly in front (within CHARGE_AIM), else straight
## ahead, where the beetle is looking (a dwarf who slipped to its side during the wind-up has dodged).
static func charge_line(forward: Vector3, to_target: Vector3) -> Vector3:
	var f := Vector3(forward.x, 0.0, forward.z).normalized()
	var t := Vector3(to_target.x, 0.0, to_target.z)
	if t.length() < 0.1 or f.angle_to(t) > CHARGE_AIM:
		return f
	return t.normalized()


## Host: after every charge the beetle is dazed for a moment (owner F471: "like the bats after a parry"): stars
## over its head, your chance to hit it. Everyone sees it (monster_changed sends it).
func daze_after_charge(mgr: Node) -> void:
	stun.value = 0.0
	stun.stunned_left = CHARGE_STARS
	state = State.STUNNED
	if mgr and mgr.has_method("monster_changed"):
		mgr.monster_changed(self)


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


## Only looks: two thin streaks of air from its wingtips while it dives (F460), fading out behind it.
func _draw_trail(delta: float) -> void:
	if _streak == null:
		_streak = MeshInstance3D.new()
		_streak.mesh = ImmediateMesh.new()
		_streak.top_level = true
		_streak.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.vertex_color_use_as_albedo = true
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		_streak.material_override = m
		add_child(_streak)
		_streak.global_transform = Transform3D.IDENTITY
	_trail_left = maxf(0.0, _trail_left - delta)
	for p in _trail_pts:
		p[1] += delta
	_trail_pts = _trail_pts.filter(func(p: Array) -> bool: return p[1] < TRAIL_LIFE)
	if _trail_left > 0.0 and is_alive():
		var side := Basis(Vector3.UP, model.rotation.y).x * 0.5 * _size
		_trail_pts.push_front([global_position + Vector3.UP * (model.position.y + 0.35 * _size), 0.0, side])
	var im := _streak.mesh as ImmediateMesh
	im.clear_surfaces()
	if _trail_pts.size() < 2:
		return
	var tint := TRAIL_TINT  # (pale air for every bat: a crested one's purple streak looked like "purple things behind it", F563)
	for wing in [-1.0, 1.0]:
		im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
		for p in _trail_pts:
			var fade := 1.0 - float(p[1]) / TRAIL_LIFE
			var at: Vector3 = p[0] + (p[2] as Vector3) * wing
			var thick := Vector3.UP * 0.03 * _size * (0.4 + fade)
			im.surface_set_color(Color(tint, 0.55 * fade))
			im.surface_add_vertex(at - thick)
			im.surface_set_color(Color(tint, 0.55 * fade))
			im.surface_add_vertex(at + thick)
		im.surface_end()


## Dazed: little stars circle its head (owner F449, every creature). Built the first time it is dazed.
func _daze_stars() -> void:
	# Knocked down = already on the floor; stars above an empty space look wrong.
	var on_floor := rig != null and rig.knocked_down
	var dazed: bool = stun.is_stunned() and is_alive() and not on_floor and not model.get_meta("roosting", false)  # (a hanging bat wakes when hit)
	if dazed and _stars == null:
		_stars = MonsterModel.add_daze_stars(model)
	if _stars:
		_stars.visible = dazed
		if dazed:
			MonsterModel.spin_daze_stars(_stars, _clock)
			if rig:  # (a skeleton's mesh box is its rest pose: the stars sat inside its body, owner Nov 20; over its head)
				_stars.top_level = true
				_stars.global_position = global_position + Vector3.UP * (float(data.get("height", 1.0)) + 0.25)


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
