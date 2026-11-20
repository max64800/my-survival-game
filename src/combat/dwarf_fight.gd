class_name DwarfFight
extends Node
## The dwarf's fighting controls (combat doc 1.5), used while a weapon or shield is in hand:
##   Left click = light attack · hold it = keep swinging (combo) · middle click = heavy attack (F430)
##   Right click hold = block · tap right before a hit = PERFECT PARRY
##   Left Ctrl (+ direction) = dodge-roll (safe from 0.05 s to 0.30 s into the roll)
##   Crossbow: right click hold = aim (no spread, zoom) · left click = shoot · R = reload

signal message(text: String, color: Color)

var dwarf: Dwarf
var clock := 0.0
var _busy := 0.0  ## seconds until we can attack again
var _combo_step := 0
var _combo_until := 0.0
var _block_pressed_at := -100.0
var _last_press := -100.0
var _riposte_until := 0.0
var _lantern_hint_at := -100.0
var _dodge_t := -1.0
var _dodge_dir := Vector3.ZERO
var stagger := 0.0  ## guard break / knockdown: can't act
var _heavy_until := 0.0  ## a heavy swing is still going until this clock time
var loaded := true  ## crossbow: a bolt is in it
const KNOCK_DOWN_TIME := 2.0  ## down 0.85 s, then 1.1 s getting up
var reload_left := -1.0  ## crossbow: seconds of reloading left (-1 = not reloading)
var reload_total := 1.0  ## crossbow: how long this reload takes in all (for the bar in the middle of the screen)


func item() -> String:
	var ps := _ps()
	return ps.selected_item() if ps else ""


## True while a weapon or shield is selected (then the mouse fights instead of digging).
func weapon_mode() -> bool:
	return Items.kind(item()) in ["weapon", "shield"]


func weapon() -> String:
	return Combat.weapon_of(item())


func tier() -> int:
	return maxi(Items.tier(item()), 0)


## A shield helps if one is on your hotbar, your weapon is one-handed, and the hand lantern
## isn't in your off hand (doc 3.4: the back lantern frees both hands; so does putting the
## hand lantern away with L, or having no lantern yet).
func has_shield() -> bool:
	var ps := _ps()
	if ps == null or Combat.WEAPONS[weapon()].hands == 2 or not off_hand_free(ps):
		return false
	if Durability.broken(ps.inventory.get_slot(Inventory.equip_index("shield"))):
		return false  # a broken shield doesn't block until it's repaired
	if Items.kind(item()) == "shield" or ps.inventory.equipped("shield") != "":
		return true
	for i in Inventory.HOTBAR_SIZE:
		if Items.kind(ps.inventory.get_slot(i).get("id", "")) == "shield":
			return true
	return false


## The shield shown on the left arm ("" = none): while one can be used (has_shield) and a weapon or shield is selected.
## The selected shield, else the equipped one, else the best on the hotbar.
func shield_item() -> String:
	if not weapon_mode() or not has_shield():
		return ""
	if Items.kind(item()) == "shield":
		return item()
	var ps := _ps()
	var best: String = ps.inventory.equipped("shield")
	if best != "":
		return best
	for i in Inventory.HOTBAR_SIZE:
		var id: String = ps.inventory.get_slot(i).get("id", "")
		if Items.kind(id) == "shield" and (best == "" or Items.tier(id) > Items.tier(best)):
			best = id
	return best


static func off_hand_free(ps: GameAuthority.PlayerState) -> bool:
	return Lantern.is_on_back(ps) or ps.lantern_stowed or not Lantern.has_lantern(ps)


## A shield you carry, but the hand lantern is in your other hand (so it can't be used).
func shield_blocked_by_lantern() -> bool:
	var ps := _ps()
	if ps == null or off_hand_free(ps):
		return false
	if Durability.broken(ps.inventory.get_slot(Inventory.equip_index("shield"))):
		return false  # a broken shield doesn't block until it's repaired
	if Items.kind(item()) == "shield" or ps.inventory.equipped("shield") != "":
		return true
	for i in Inventory.HOTBAR_SIZE:
		if Items.kind(ps.inventory.get_slot(i).get("id", "")) == "shield":
			return true
	return false


func shield_tier() -> int:
	var ps := _ps()
	var best := maxi(Items.tier(ps.inventory.equipped("shield")), 0)
	for i in Inventory.HOTBAR_SIZE:
		var id: String = ps.inventory.get_slot(i).get("id", "")
		if Items.kind(id) == "shield":
			best = maxi(best, Items.tier(id))
	return best


func is_crossbow() -> bool:
	return weapon() == "crossbow"


func aiming() -> bool:
	return is_crossbow() and stagger <= 0.0 and Input.is_action_pressed("use") and Controls.captured()


func is_blocking() -> bool:
	return weapon_mode() and not is_crossbow() and stagger <= 0.0 and _dodge_t < 0.0 and Input.is_action_pressed("use") \
		and Controls.captured()


func dodging() -> bool:
	return _dodge_t >= 0.0


func invulnerable() -> bool:
	return _dodge_t >= Combat.DODGE_IFRAME.x and _dodge_t <= Combat.DODGE_IFRAME.y


## For the monster manager: is the player blocking, and when did they press it?
func defense_state() -> Dictionary:
	var holding := is_blocking()
	return {holding = holding, pressed_ago = (clock - _block_pressed_at) if holding else -1.0,
		weapon = weapon(), shield = has_shield(), tier = shield_tier() if has_shield() else tier()}


func guard_break() -> void:
	dwarf.model.react("knock")
	stagger = 1.2
	message.emit("Guard broken!", Color(1.0, 0.4, 0.3))


## Knocked down (owner, Nov 19, F234: "fly a couple of metres at most, go limp, then get back up"): he falls back,
## lies a moment, then gets up; no fighting or walking meanwhile.
func knock_down() -> void:
	if stagger > 0.5:
		return  # (already down)
	if clock < _heavy_until and weapon() == "mace_2h" and _ps() and _ps().progress.has_star("warhammer", 25):
		return  # Warhammer ★25: heavy swings can't be interrupted
	dwarf.model.react("knock")
	stagger = KNOCK_DOWN_TIME
	dwarf.get_tree().create_timer(0.85).timeout.connect(func() -> void:
		if is_instance_valid(dwarf) and stagger > 0.0:
			dwarf.model.react("get_up"))
	message.emit("Knocked down!", Color(1.0, 0.4, 0.3))


func got_parry() -> void:
	_riposte_until = clock + Combat.RIPOSTE_TIME
	if has_shield() and _ps() and _ps().progress.has_star("shield", 100):
		_ps().vitals.stamina = minf(_ps().vitals.max_stamina(), _ps().vitals.stamina + 20.0)  # Shield ★100: stamina back
	message.emit("Perfect parry!", Color(1.0, 0.85, 0.3))


## Called every physics frame by the dwarf. Returns a speed multiplier for walking.
func step(delta: float, playing: bool, move_dir: Vector3) -> float:
	clock += delta
	_busy = maxf(0.0, _busy - delta)
	if stagger > 0.0:
		stagger -= delta
		return 0.0
	if _dodge_t >= 0.0:
		_dodge_t += delta
		if _dodge_t >= Combat.DODGE_TIME:
			_dodge_t = -1.0
			_busy = maxf(_busy, 0.15)  # recovery after a roll
		return 0.0
	if not playing:
		return 1.0
	if Input.is_action_just_pressed("dodge") and _busy <= 0.0 and _ps() and _ps().vitals.use_stamina(Combat.DODGE_STAMINA * _ps().progress.dodge_stamina_mult()):
		_dodge_t = 0.0
		# No direction pressed = roll backward.
		_dodge_dir = move_dir.normalized() if move_dir.length() > 0.1 else Basis(Vector3.UP, dwarf.model.rotation.y) * Vector3.BACK
		return 0.0
	if not weapon_mode():
		return 1.0
	if is_crossbow():
		return _crossbow_step(delta, move_dir)
	if Input.is_action_just_pressed("use") and clock - _lantern_hint_at > 4.0 and shield_blocked_by_lantern():
		_lantern_hint_at = clock  # say why the shield isn't raised (owner, Nov 17: "I cannot use the shield")
		message.emit("Your lantern is in your other hand: press L to put it away and raise the shield.", Color.WHITE)
	if Input.is_action_just_pressed("use") and clock - _last_press >= Combat.PARRY_COOLDOWN:
		_block_pressed_at = clock  # anti-spam: a new parry window only every 0.5 s
		_last_press = clock
	elif Input.is_action_just_pressed("use"):
		_last_press = clock
	# F430 (owner, Nov 20: "holding the mouse button keeps the pickaxe swinging; I want the same for weapons"):
	# hold left click = light swings one after another (the combo keeps going); middle click = heavy attack.
	if Input.is_action_just_pressed("heavy_attack"):
		_attack(true)
	elif Input.is_action_pressed("dig"):
		_attack(false)  # (does nothing while the last swing is still going: the next starts as soon as it ends)
	return (_ps().progress.guard_walk_mult(false) if _ps() else 0.6) if is_blocking() else 1.0  # Shield ★25


## Where a roll moves you this frame.
func dodge_velocity() -> Vector3:
	return _dodge_dir * (Combat.DODGE_DISTANCE / Combat.DODGE_TIME)


func _attack(heavy: bool) -> void:
	if _busy > 0.0 or is_blocking():
		return
	var ps := _ps()
	var wd: Dictionary = Combat.WEAPONS[weapon()]
	var cost: float = (wd.heavy_sta if heavy else wd.light_sta) * (1.0 - Gems.bonus(ps.inventory.get_slot(ps.hand_slot())).get("stamina", 0.0)) \
		* ps.progress.attack_stamina_mult(weapon())
	if heavy:
		if not ps.vitals.use_stamina(cost):
			message.emit("Too tired for a heavy attack", Color(0.9, 0.9, 0.9))
			return
	else:
		if ps.vitals.stamina < 1.0:
			return
		ps.vitals.use_stamina(minf(cost, ps.vitals.stamina))  # a light swing always happens
	_combo_step = (_combo_step + 1) % wd.combo.size() if clock < _combo_until else 0
	var speed: float = wd.heavy_speed if heavy else wd.light_speed
	_busy = speed
	if heavy:
		_heavy_until = clock + speed  # (Warhammer ★25: a heavy swing can't be knocked out of)
	if _combo_step == 0 and Progression.weapon_skill(weapon()) == "sword" and ps.progress.has_star("sword", 25):
		dwarf.shove(Basis(Vector3.UP, dwarf.model.rotation.y) * Vector3.FORWARD * 4.0)  # Sword ★25: a quick step in
	_combo_until = clock + speed + Combat.COMBO_WINDOW
	var step := _combo_step
	var riposte := clock < _riposte_until
	dwarf.model.attack(speed, heavy, step)  # (the combo's hits look different: DwarfRig.ATTACKS)
	Sfx.play("swing", dwarf.global_position + Vector3.UP, -8.0, 0.8 if heavy else 1.1)
	var airborne := not dwarf.is_on_floor()  # Jumping ★75: hits in the air
	dwarf.get_tree().create_timer(speed * 0.4).timeout.connect(func(): _impact(heavy, step, riposte, airborne))
	dwarf.face_camera()


## The swing lands: find monsters in front of us within reach.
func _impact(heavy: bool, combo_step: int, riposte: bool, airborne: bool = false) -> void:
	var auth := GameAuthority.instance
	if auth == null or auth.monsters == null:
		return
	var w := weapon()
	var wd: Dictionary = Combat.WEAPONS[w]
	var prog: Progression = _ps().progress if _ps() else Progression.new()
	var reach: float = wd.reach * prog.reach_mult(w) + 0.5  # Spear: +1.5% reach per 10 levels
	var arc := 160.0 if wd.get("sweep", false) else 70.0
	if w == "mace_2h" and heavy:
		arc = 360.0
		reach = 2.5 * (1.25 if prog.has_star("warhammer", 50) else 1.0)  # Warhammer ★50: wider ground slam
	var fwd := Basis(Vector3.UP, dwarf.model.rotation.y) * Vector3.FORWARD
	var found := []
	for m: Monster in auth.monsters.monsters.values():
		if not m.is_alive():
			continue
		var to := m.global_position - dwarf.global_position
		var flat := Vector3(to.x, 0, to.z)
		if flat.length() > reach + m.data.size * 0.4 or absf(to.y) > 2.0:
			continue
		if arc < 360.0 and rad_to_deg(fwd.angle_to(flat.normalized())) > arc * 0.5:
			continue
		found.append([flat.length(), m.uid])
	found.sort()
	var uids := PackedInt32Array()
	for f in found:
		uids.append(f[1])
	if not uids.is_empty():
		auth.monsters.ask_attack(uids, heavy, combo_step, riposte, airborne)
		dwarf.add_shake(0.3 if heavy else 0.15)
	else:
		# A dungeon thing under the crosshair (rubble, the cracked wall, the hidden boulder, furniture): weapons break
		# them too (owner, Nov 20: "ANY hit must break it"; tools go through Dwarf._on_swing_impact).
		var aimed: Dictionary = dwarf.aim()
		var thing_id := DungeonBuild.id_of(aimed.get("collider"))
		if thing_id >= 0 and DungeonBuild.instance:
			DungeonBuild.instance.ask_hit(thing_id)
			dwarf.add_shake(0.3 if heavy else 0.15)
			return
		var dummy: Station = auth.station_near(dwarf.global_position + fwd * 1.2, reach)
		if dummy and dummy.kind == "training_dummy":
			auth.ask_train(dummy.station_id)
			dwarf.add_shake(0.1)
	# Friendly fire (doc 2.7): friends standing in the swing get hit too.
	if auth.friendly_fire():
		for pid in auth.players:
			var other: Node3D = auth.players[pid].node
			if pid == dwarf.peer_id or other == null:
				continue
			var to := other.global_position - dwarf.global_position
			var flat := Vector3(to.x, 0, to.z)
			if flat.length() > reach or absf(to.y) > 2.0:
				continue
			if arc < 360.0 and rad_to_deg(fwd.angle_to(flat.normalized())) > arc * 0.5:
				continue
			auth.monsters.ask_hit_friend(pid, heavy)


# ---------------------------------------------------------------- crossbow (doc 3.6)

## Reloading needs you to stand still (owner, Nov 20): walking or running away stops it, and the next reload starts
## from the beginning.
func _crossbow_step(delta: float, move_dir := Vector3.ZERO) -> float:
	if reload_left >= 0.0:
		if dwarf.running or move_dir.length() > 0.1:
			reload_left = -1.0
			message.emit("Reload stopped: stand still to reload", Color(0.9, 0.9, 0.9))
		else:
			reload_left -= delta
			if reload_left < 0.0:
				loaded = true
				Sfx.play("clink", dwarf.global_position + Vector3.UP, -6.0, 1.3)
	if Input.is_action_just_pressed("dig") and _busy <= 0.0:
		if loaded:
			_shoot(aiming())
		else:
			start_reload()
	if reload_left >= 0.0:
		return 0.0  # standing still while reloading (moving stopped it above)
	return (_ps().progress.guard_walk_mult(true) if _ps() else 0.6) if aiming() else 1.0  # Crossbow ★25


## R while holding the crossbow (or clicking when it's empty).
func start_reload() -> void:
	if not is_crossbow() or loaded or reload_left >= 0.0:
		return
	if bolt() == "":
		message.emit("No bolts! Craft some at a Workbench.", Color(1.0, 0.6, 0.4))
		return
	var fx: Dictionary = _ps().vitals.effects.get("rapid_volley", {}) if _ps() else {}
	if fx.get("free_reloads", 0.0) >= 1.0:  # Rapid Volley perk: no wait for the next few bolts
		fx.free_reloads -= 1.0
		reload_left = 0.05
		reload_total = 0.05
		return
	reload_left = Combat.RELOAD[clampi(tier(), 0, 4)] * (_ps().progress.crossbow_reload_mult() if _ps() else 1.0)
	reload_total = reload_left
	dwarf.model.react("reload")
	message.emit("Reloading…", Color(0.9, 0.9, 0.9))


## The bolt the next shot uses (first one in Combat.BOLT_ORDER that we carry).
func bolt() -> String:
	var ps := _ps()
	if ps:
		for id in Combat.BOLT_ORDER:
			if ps.inventory.count_of(id) > 0:
				return id
	return ""


func _shoot(aimed: bool) -> void:
	var ps := _ps()
	var b := bolt()
	if ps == null or b == "":
		message.emit("No bolts! Craft some at a Workbench.", Color(1.0, 0.6, 0.4))
		return
	ps.vitals.use_stamina(minf(Combat.WEAPONS.crossbow.light_sta, ps.vitals.stamina))
	loaded = false
	dwarf.model.react("shoot")
	_busy = Combat.WEAPONS.crossbow.heavy_speed if aimed else Combat.WEAPONS.crossbow.light_speed
	var cam := dwarf.camera
	var from := cam.global_position
	var dir := -cam.global_basis.z
	if not aimed:
		# Hip shot: up to 3° off.
		var spread := deg_to_rad(Combat.HIP_SPREAD) * sqrt(randf())
		dir = dir.rotated(cam.global_basis.y, cos(randf() * TAU) * spread).rotated(cam.global_basis.x, sin(randf() * TAU) * spread)
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * Combat.BOLT_MAX)
	q.collision_mask = World.TERRAIN_LAYER | Monster.MONSTER_LAYER | PieceNode.PIECE_LAYER | Dwarf.BODY_LAYER
	q.exclude = [dwarf.get_rid()]
	var hit := dwarf.get_world_3d().direct_space_state.intersect_ray(q)
	var point: Vector3 = hit.get("position", from + dir * Combat.BOLT_MAX)
	var uid := MonsterManager.uid_of(hit.get("collider"))
	dwarf.face_camera()
	dwarf.model.attack(0.3, false)
	Sfx.play("swing", dwarf.global_position + Vector3.UP, -4.0, 1.6)
	var auth := GameAuthority.instance
	var thing_id := DungeonBuild.id_of(hit.get("collider"))
	if thing_id >= 0 and DungeonBuild.instance:  # a bolt brings a dungeon stalactite down (decisions round 2)
		DungeonBuild.instance.ask_hit(thing_id, true)
	if auth and auth.monsters:
		auth.monsters.ask_shoot(b, aimed, uid, from, point)
		var friend = hit.get("collider")
		if friend is Dwarf and auth.friendly_fire():
			auth.monsters.ask_hit_friend(friend.peer_id, aimed, b, from.distance_to(point))  # bolts hit the first body in line


func _ps() -> GameAuthority.PlayerState:
	var auth := GameAuthority.instance
	return auth.get_player(dwarf.peer_id) if auth else null
