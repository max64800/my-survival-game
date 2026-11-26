class_name DwarfFight
extends Node
## The dwarf's fighting controls (combat doc 1.5), used while a weapon or shield is in hand:
##   Left click = light attack · click again or hold it = keep swinging (combo), each hit stronger than the last
##   Right click hold = block · tap right before a hit = PERFECT PARRY · left click while blocking (shield) = shield bash
##   Great axe / great maul: right click = heavy spin, middle click held = block (one-handed weapons have no heavy)
##   Left Ctrl (+ direction) = dodge-roll (safe from 0.05 s to 0.30 s into the roll); hold it down for a longer dash (F702)
##   Crossbow: right click hold = aim (no spread, zoom) · left click = shoot · R = reload

signal message(text: String, color: Color)

var dwarf: Dwarf
var clock := 0.0
var _busy := 0.0  ## seconds until we can attack again
var _lock_off := 0.0  ## F790: how far (radians) this swing turns him away from where the camera looks, toward an enemy
var _lock_until := 0.0  ## ... until this clock time (the end of the swing)
var _combo_step := 0
var _combo_until := 0.0
var _block_pressed_at := -100.0
var _last_press := -100.0
var _riposte_until := 0.0
var _lantern_hint_at := -100.0
var _dodge_t := -1.0
var _dodge_dir := Vector3.ZERO
var _dodge_held_grace := 0.0  ## seconds of slack so one dropped input frame doesn't end a held dash early (F702)
const DODGE_RELEASE_GRACE := 0.1
var stagger := 0.0  ## guard break / knockdown: can't act
var _heavy_until := 0.0  ## a heavy swing is still going until this clock time
var loaded := true  ## crossbow: a bolt is in it
const WHIRL_WALK := 0.5  ## walking speed share during the great maul's whirl (owner, chat 17)
const SPEAR_SPIN_STEP := 2  ## the spear's 3rd combo hit is a spin (owner, chat 16: "two hits and then a spin")
const KNOCK_DOWN_TIME := 2.0  ## down 0.85 s, then 1.1 s getting up
## Your own stun meter (owner, chat 15: "you should have your own stun meter as well"): hits fill it, blocked hits a
## little; full = stunned (UAL 2's Shield broken move, no fighting or walking), then it can't fill for 2 s.
const STUN_MAX := 100.0
const STUN_TIME := 1.5  ## s stunned
const STUN_PER_HIT := 2.5  ## stun per point of damage you take
const STUN_PER_BLOCK := 1.0  ## per point of damage your block stopped
## What a crossbow bolt can hit: rock, creatures, built pieces, dwarves, and chests/stations (owner, Nov 21, F585:
## "shooting the trapped chest does nothing": the bolt flew straight through chests, they weren't in this list).
const BOLT_MASK := World.TERRAIN_LAYER | Monster.MONSTER_LAYER | PieceNode.PIECE_LAYER | Dwarf.BODY_LAYER | Storage.BOX_LAYER
const DEATH_FALL := 0.9  ## s of the knock-back move before you wake at your bed (owner, chat 15)
var stun_meter := StunMeter.new(STUN_MAX, STUN_TIME)
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
	if Durability.broken(ps.inventory.get_slot(ps.inventory.worn_slot("shield"))):
		return false  # a broken shield doesn't block until it's repaired
	if Items.kind(item()) == "shield" or ps.inventory.equipped("shield") != "":
		return true
	for i in Inventory.HOTBAR_SIZE:
		if Items.kind(ps.inventory.get_slot(i).get("id", "")) == "shield":
			return true
	return false


## The shield shown on the left arm ("" = none): while one can be used (has_shield) and a weapon or shield is selected.
## The selected shield, else the equipped one, else the best on the hotbar.
## Tools you can hold with the shield still on your arm (owner F829, Nov 24: "a pickaxe or any other tools").
const SHIELD_TOOLS := ["pickaxe", "axe", "hammer", "shovel"]


func shield_item() -> String:
	var ps0 := _ps()
	if ps0 and not ps0.equip_job.is_empty() and Items.kind(str(ps0.equip_job.id)) == "weapon" \
			and Combat.WEAPONS.get(Combat.weapon_of(str(ps0.equip_job.id)), {}).get("hands", 1) == 1 \
			and ps0.inventory.equipped("shield") != "" and off_hand_free(ps0):
		return ps0.inventory.equipped("shield")  # swapping to a one-hand weapon: the shield stays on (owner F829)
	if not (weapon_mode() or Items.kind(item()) in SHIELD_TOOLS) or not has_shield():
		return ""
	if Items.kind(item()) == "shield":
		return item()
	var ps := _ps()
	var best: String = ps.inventory.equipped("shield")
	if best != "":
		return best
	for i in Inventory.HOTBAR_SIZE:
		var id: String = ps.inventory.get_slot(i).get("id", "")
		if Items.kind(id) == "shield" and (best == "" or Items.rank(id) > Items.rank(best)):
			best = id
	return best


static func off_hand_free(ps: GameAuthority.PlayerState) -> bool:
	return Lantern.hands_free(ps) or ps.lantern_stowed or not Lantern.has_lantern(ps)


## A shield you carry, but the hand lantern is in your other hand (so it can't be used).
func shield_blocked_by_lantern() -> bool:
	var ps := _ps()
	if ps == null or off_hand_free(ps):
		return false
	if Durability.broken(ps.inventory.get_slot(ps.inventory.worn_slot("shield"))):
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


## The button that blocks: right click, but the middle click for great weapons (their right click is the heavy spin).
func block_action() -> String:
	if tool_blocks():  # (owner F836: hammer and shovel already use right click, so they block with the middle one)
		return "use" if Items.kind(item()) in ["pickaxe", "axe"] else "heavy_attack"
	return "heavy_attack" if has_heavy() else "use"


## A tool in hand can block too, like a one-hand weapon but weaker (its `block` in Combat.WEAPONS; with a shield
## worn, the shield blocks) (owner F836, Nov 24).
func tool_blocks() -> bool:
	return Items.kind(item()) in SHIELD_TOOLS


func is_blocking() -> bool:
	return (weapon_mode() or tool_blocks()) and not is_crossbow() and stagger <= 0.0 and _dodge_t < 0.0 and Input.is_action_pressed(block_action()) \
		and Controls.captured()


func dodging() -> bool:
	return _dodge_t >= 0.0


## The roll's actual, locked travel direction (world space) for this whole roll (F702: so the body can be made to
## face exactly this, instead of chasing wherever the camera/input happens to point mid-roll).
func dodge_dir() -> Vector3:
	return _dodge_dir


func invulnerable() -> bool:
	return _dodge_t >= Combat.DODGE_IFRAME.x and _dodge_t <= Combat.DODGE_IFRAME.y


## For the monster manager: is the player blocking, and when did they press it?
func defense_state() -> Dictionary:
	var holding := is_blocking()
	return {holding = holding, pressed_ago = (clock - _block_pressed_at) if holding else -1.0,
		weapon = weapon(), shield = has_shield(), tier = shield_tier() if has_shield() else tier()}


## Fills your stun meter; full: stunned — falls down and gets back up (owner, Nov 22: "just freezing" was wrong).
func take_stun(amount: float) -> void:
	if stun_meter.add(amount):
		stagger = 0.0  # bypass the "already in brief stagger" guard so knock_down always plays the fall
		knock_down()
		stagger = 1.2  # stun recovers faster than a full knockdown (fall + get_up in ~1.2 s, not 2 s)
		message.emit("Stunned!", Color(1.0, 0.4, 0.3))


func guard_break() -> void:
	dwarf.model.react("stunned", 1.2)  # (UAL 2's Shield broken, owner chat 15)
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
	# (F870: no parry words on screen: the spark star and the ringing blade show it, MonsterManager._parry_feel)


## Called every physics frame by the dwarf. Returns a speed multiplier for walking.
func step(delta: float, playing: bool, move_dir: Vector3) -> float:
	clock += delta
	stun_meter.tick(delta)
	_busy = maxf(0.0, _busy - delta)
	if stagger > 0.0:
		stagger -= delta
		return 0.0
	if _dodge_t >= 0.0:
		_dodge_t += delta
		# Still holding the button past the usual roll keeps the dash going, up to DASH_HOLD_MAX (F702). A little
		# grace so one dropped input frame on a real keyboard doesn't end the dash early (owner, PC, Nov 22: a held
		# "big dodge" was cutting out partway, then just sprinting the rest of the way instead of dashing).
		_dodge_held_grace = DODGE_RELEASE_GRACE if Input.is_action_pressed("dodge") else maxf(0.0, _dodge_held_grace - delta)
		var still_held := _dodge_held_grace > 0.0 and _dodge_t < Combat.DASH_HOLD_MAX
		if _dodge_t >= Combat.DODGE_TIME and not still_held:
			_dodge_t = -1.0
			_busy = maxf(_busy, 0.15)  # recovery after a roll
		return 0.0
	if not playing:
		return 1.0
	if (Input.is_action_just_pressed("dodge") or dwarf.bot_dodge) and _busy <= 0.0 and not dwarf.is_overloaded() and _ps() and _ps().vitals.use_stamina(Combat.DODGE_STAMINA * _ps().progress.dodge_stamina_mult()):
		dwarf.bot_dodge = false
		_dodge_t = 0.0
		# No direction pressed = roll the way you're already facing (owner, PC, Nov 22: "I'm looking forward, I
		# press Ctrl, I dash backwards" - this used to default to a backstep, which then flips which way is
		# "backward" every time, since the roll ends by facing the way it just went).
		_dodge_dir = move_dir.normalized() if move_dir.length() > 0.1 else Basis(Vector3.UP, dwarf.model.rotation.y) * Vector3.FORWARD
		return 0.0
	if not weapon_mode():
		if not tool_blocks():
			return 1.0
		if Input.is_action_just_pressed(block_action()) and clock - _last_press >= Combat.PARRY_COOLDOWN:
			_block_pressed_at = clock  # (the same parry window as a weapon, F836)
			_last_press = clock
		elif Input.is_action_just_pressed(block_action()):
			_last_press = clock
		return (_ps().progress.guard_walk_mult(false) if _ps() else 0.6) if is_blocking() else 1.0
	if is_crossbow():
		return _crossbow_step(delta, move_dir)
	if Input.is_action_just_pressed("use") and clock - _lantern_hint_at > 4.0 and shield_blocked_by_lantern():
		_lantern_hint_at = clock  # say why the shield isn't raised (owner, Nov 17: "I cannot use the shield")
		message.emit("Your lantern is in your other hand: press L to put it away and raise the shield.", Color.WHITE)
	if Input.is_action_just_pressed(block_action()) and clock - _last_press >= Combat.PARRY_COOLDOWN:
		_block_pressed_at = clock  # anti-spam: a new parry window only every 0.5 s
		_last_press = clock
	elif Input.is_action_just_pressed(block_action()):
		_last_press = clock
	# F430 (owner, Nov 20: "holding the mouse button keeps the pickaxe swinging; I want the same for weapons"):
	# hold left click = light swings one after another (the combo keeps going).
	# Owner, chat 16: one-handed weapons have no heavy attack; right click blocks, and left click while blocking with
	# a shield = a shield bash (sword, mace, spear, axe alike). Great weapons: right click = heavy (owner, chat 16:
	# "the heavy spin should be the right mouse button"), their block moved to the middle click.
	if is_blocking():
		if Input.is_action_just_pressed("dig") and has_shield():
			_shield_bash()
	elif Input.is_action_just_pressed("use") and has_heavy():
		_attack(true)
	elif Input.is_action_pressed("dig"):
		_attack(false)  # (does nothing while the last swing is still going: the next starts as soon as it ends)
	if clock < _heavy_until and weapon() == "mace_2h":
		return WHIRL_WALK  # (owner, chat 17: "you can still move a little bit slower" in the maul's whirl)
	return (_ps().progress.guard_walk_mult(false) if _ps() else 0.6) if is_blocking() else 1.0  # Shield ★25


## Only the great (two-handed) weapons have a heavy attack (owner, chat 16).
## (and not the stone ones: owner, chat 16; a stone great weapon blocks with right click like the rest)
func has_heavy() -> bool:
	return Combat.has_heavy(weapon(), tier())


static func weapon_has_heavy(w: String) -> bool:
	return Combat.WEAPONS[w].hands == 2


## Left click while blocking with a shield (owner, chat 16): a quick push with the shield, the guard stays up.
## Hits like the shield's own light attack (its stun, its tier).
func _shield_bash() -> void:
	var ps := _ps()
	var wd: Dictionary = Combat.WEAPONS["shield"]
	if _busy > 0.0 or ps == null or ps.vitals.stamina < 1.0:
		return
	ps.vitals.use_stamina(minf(wd.light_sta * ps.progress.attack_stamina_mult("shield"), ps.vitals.stamina))
	var speed: float = wd.light_speed
	_busy = speed
	_combo_until = 0.0  # a bash ends the combo
	dwarf.model.attack(speed, false, 0, "shield")
	dwarf.get_tree().create_timer(speed * 0.4).timeout.connect(func(): _impact(false, 0, false, false, true))
	dwarf.face_camera()


## Where a roll moves you this frame. Same speed the whole way, tap or held (owner, Nov 23: "the entire speed at
## the beginning of the dodge and the end of the dodge should be exactly the same... he's traveling too fast at
## the end of the long dodge" — an earlier version sped up toward DASH_HOLD_MAX; removed). Holding goes farther
## only because it keeps going longer (toward DASH_HOLD_MAX), never because it moves faster.
func dodge_velocity() -> Vector3:
	return _dodge_dir * (Combat.DODGE_DISTANCE / Combat.DODGE_TIME)


## How long the roll is on track to last (s), updated live so the roll animation can be stretched or shortened to
## match it instead of always playing the same length (F702). The usual tap: DODGE_TIME. Held past that: grows
## toward DASH_HOLD_MAX while the button's still down, then settles the moment you let go or hit the cap.
func dodge_expected_duration() -> float:
	if _dodge_t < 0.0:
		return Combat.DODGE_TIME
	var still_held := _dodge_held_grace > 0.0 and _dodge_t < Combat.DASH_HOLD_MAX
	# A held dash is still actively moving right up to DASH_HOLD_MAX (F702), so the roll clip can't be done "stood
	# up" by then like a tap roll is: give it its recovery tail on top, to play out after he's done moving instead
	# of while he's still mid-dash (F798: "after my animation of the dodge is done, he propels me forward").
	return (Combat.DASH_HOLD_MAX + Combat.DASH_RECOVERY_TAIL if still_held
			else maxf(_dodge_t, Combat.DODGE_TIME))


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
	_combo_step = (_combo_step + 1) % Combat.combo_hits(weapon(), tier()) if clock < _combo_until else 0  # (stone: no finisher)
	var speed: float = DwarfRig.attack_seconds(weapon(), heavy, _combo_step, wd.heavy_speed if heavy else wd.light_speed)
	_busy = speed
	if heavy:
		_heavy_until = clock + speed  # (Warhammer ★25: a heavy swing can't be knocked out of)
	if _combo_step == 0 and Progression.weapon_skill(weapon()) == "sword" and ps.progress.has_star("sword", 25):
		dwarf.shove(Basis(Vector3.UP, dwarf.model.rotation.y) * Vector3.FORWARD * 4.0)  # Sword ★25: a quick step in
	_combo_until = clock + speed + Combat.COMBO_WINDOW
	var step := _combo_step
	var riposte := clock < _riposte_until
	dwarf.model.attack(speed, heavy, step)  # (the combo's hits look different: DwarfRig.ATTACKS)
	var airborne := not dwarf.is_on_floor()  # Jumping ★75: hits in the air
	dwarf.get_tree().create_timer(speed * 0.4).timeout.connect(func(): _impact(heavy, step, riposte, airborne))
	dwarf.face_camera()
	# F790 soft lock-on: lean the swing toward the best enemy in front. The dwarf's body turns there over the next
	# blink (Dwarf: the swinging body follows swing_yaw), so the hit lands where the enemy really is.
	var cam_yaw := dwarf.model.rotation.y
	_lock_off = angle_difference(cam_yaw, soft_lock_yaw(dwarf.global_position, cam_yaw, _lock_targets()))
	_lock_until = clock + speed


## Which way the swinging dwarf should face (F790): where the camera looks, plus this swing's lock-on lean.
func swing_yaw(cam_yaw: float) -> float:
	return cam_yaw + (_lock_off if clock < _lock_until else 0.0)


## Living enemies near enough to lean toward: [position, how far it may be (m)] each.
func _lock_targets() -> Array:
	var out := []
	var auth := GameAuthority.instance
	if auth == null or auth.monsters == null:
		return out
	var prog: Progression = _ps().progress if _ps() else Progression.new()
	var reach: float = Combat.WEAPONS[weapon()].reach * prog.reach_mult(weapon()) + 0.5
	for m: Monster in auth.monsters.monsters.values():
		if m.is_alive():
			out.append([m.global_position, reach + m.data.size * 0.4 + DwarfFeel.LOCK_EXTRA_RANGE])
	return out


## F790: the yaw a swing should face. Only enemies inside the cone in front of `yaw` (DwarfFeel.LOCK_CONE) and in range
## count; the best is the one nearest your aim (and closest). It turns you toward it by at most LOCK_MAX_TURN.
## No enemy in front = `yaw` unchanged (it never turns you toward one beside or behind you).
## targets: [[position, range], ...]. Pure maths, so the tests can check it.
static func soft_lock_yaw(from: Vector3, yaw: float, targets: Array) -> float:
	var best := INF
	var best_turn := 0.0
	for t in targets:
		var to: Vector3 = t[0] - from
		var flat := Vector3(to.x, 0, to.z)
		var dist := flat.length()
		if dist < 0.3 or dist > float(t[1]) or absf(to.y) > 2.0:
			continue
		var turn := angle_difference(yaw, atan2(-flat.x, -flat.z))
		var off := rad_to_deg(absf(turn))
		if off > DwarfFeel.LOCK_CONE:
			continue
		var score := off + dist * DwarfFeel.LOCK_DIST_WEIGHT
		if score < best:
			best = score
			best_turn = turn
	var most := deg_to_rad(DwarfFeel.LOCK_MAX_TURN)
	return yaw + clampf(best_turn, -most, most)


## The swing lands: find monsters in front of us within reach.
func _impact(heavy: bool, combo_step: int, riposte: bool, airborne: bool = false, bash: bool = false) -> void:
	var auth := GameAuthority.instance
	if auth == null or auth.monsters == null:
		return
	var w := "shield" if bash else weapon()
	var wd: Dictionary = Combat.WEAPONS[w]
	var prog: Progression = _ps().progress if _ps() else Progression.new()
	var reach: float = wd.reach * prog.reach_mult(w) + 0.5  # Spear: +1.5% reach per 10 levels
	var arc := 160.0 if wd.get("sweep", false) else 70.0
	if w == "spear" and not heavy and combo_step == SPEAR_SPIN_STEP:
		arc = 360.0  # the spear's spin (owner, chat 16) hits everything round him
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
		var kd := m.rig != null and m.rig.knocked_down
		var eff_reach: float = reach + m.data.size * 0.4 + (m.data.height * 0.5 if kd else 0.0)
		if flat.length() > eff_reach or absf(to.y) > 2.0:
			continue
		if not kd and arc < 360.0 and flat.length() > 0.3 and rad_to_deg(fwd.angle_to(flat.normalized())) > arc * 0.5:
			continue
		found.append([flat.length(), m.uid])
	found.sort()
	var uids := PackedInt32Array()
	for f in found:
		uids.append(f[1])
	if not uids.is_empty():
		auth.monsters.ask_attack(uids, heavy, combo_step, riposte, airborne, bash)
		dwarf.add_shake(0.3 if heavy else 0.15)
		# F621: also break smash/rubble furniture in the same arc even when monsters were hit.
		if DungeonBuild.instance != null:
			for id: int in DungeonBuild.instance.things.keys():
				var th: Dictionary = DungeonBuild.instance.things[id]
				if th.kind not in ["smash", "rubble"] or DungeonBuild.instance.is_broken(id):
					continue
				var centre: Vector3 = th.centre
				var to_th := centre - dwarf.global_position
				var flat_th := Vector3(to_th.x, 0, to_th.z)
				if flat_th.length() > reach + float(th.radius) or absf(to_th.y) > 2.0:
					continue
				if arc < 360.0 and rad_to_deg(fwd.angle_to(flat_th.normalized())) > arc * 0.5:
					continue
				DungeonBuild.instance.ask_hit(id)
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
			dwarf.model.react("reload_stop")  # the reload move stops too
			message.emit("Reload stopped: stand still to reload", Color(0.9, 0.9, 0.9))
		else:
			reload_left -= delta
			if reload_left < 0.0:
				loaded = true
				Sfx.play("crossbow_reload", dwarf.global_position + Vector3.UP, -4.0)
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
	dwarf.model.react("reload", reload_total)  # the reload move lasts exactly as long as the reload (owner, Nov 20)
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
	Sfx.play("crossbow_shot", dwarf.global_position + Vector3.UP)
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
	q.collision_mask = BOLT_MASK
	q.exclude = [dwarf.get_rid()]
	var hit := dwarf.get_world_3d().direct_space_state.intersect_ray(q)
	var point: Vector3 = hit.get("position", from + dir * Combat.BOLT_MAX)
	var uid := MonsterManager.uid_of(hit.get("collider"))
	dwarf.face_camera()
	dwarf.model.attack(0.3, false)
	var auth := GameAuthority.instance
	var thing_id := DungeonBuild.id_of(hit.get("collider"))
	if thing_id >= 0 and DungeonBuild.instance:  # a bolt brings a dungeon stalactite down (decisions round 2)
		DungeonBuild.instance.ask_hit(thing_id, true)
	elif Storage.box_id_of(hit.get("collider")) >= 0 and DungeonBuild.instance:  # Lampwick's vault chest: its spikes go off
		var spikes := DungeonBuild.instance.mine.spikes_near(point)
		if spikes >= 0:
			DungeonBuild.instance.ask_hit(spikes, true)
	if auth and auth.monsters:
		auth.monsters.ask_shoot(b, aimed, uid, from, point)
		var friend = hit.get("collider")
		if friend is Dwarf and auth.friendly_fire():
			auth.monsters.ask_hit_friend(friend.peer_id, aimed, b, from.distance_to(point))  # bolts hit the first body in line


func _ps() -> GameAuthority.PlayerState:
	var auth := GameAuthority.instance
	return auth.get_player(dwarf.peer_id) if auth else null
