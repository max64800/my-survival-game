extends Node
## Gem check (Mac gem rebuild, Nov 20; docs/design/gems.md): in a real game, combine 3 Rough gems at a Gem Bench,
## read the gem tooltips, get poisoned by a Rock Snail's spit (round badge above the health bar), and let a fiery red
## snail's slams burn you through a raised shield. The creature attacks go through the game's own attack code.
## Run:  godot --audio-driver Dummy --path . -- gemcheck claude=gems seed=42 shots=/some/folder

var _main: Node
var _shots := "user://gemcheck"
var _auth: GameAuthority
var _ps: GameAuthority.PlayerState


func _ready() -> void:
	_main = get_parent()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("shots="):
			_shots = arg.trim_prefix("shots=")
	DirAccess.make_dir_recursive_absolute(_shots)
	_run.call_deferred()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	print("gemcheck: shot ", _main.take_screenshot(_shots.path_join(name + ".png")))


func _say(ok: bool, what: String) -> void:
	print("gemcheck: %s %s" % ["PASS" if ok else "FAIL", what])


func _run() -> void:
	var waited := 0.0
	while not _main.is_ready_to_play() and waited < 120.0:
		await _wait(0.25)
		waited += 0.25
	_auth = _main.authority
	_ps = _auth.get_player(_auth.local_peer_id())
	_main.hud.set_paused(false)
	await _wait(1.0)
	await _gem_bench()
	await _snail_poison()
	await _fire_through_block()
	get_tree().quit()


func _ahead(metres: float) -> Vector3:
	var n: Node3D = _ps.node
	var f := -n.global_basis.z
	f.y = 0.0
	return n.global_position + f.normalized() * metres


# ------------------------------------------------------------------ Gem Bench

func _gem_bench() -> void:
	_auth._ev_place_station(990001, "gem_bench", _ahead(1.6), 0.0)
	_ps.inventory.add("gem_keen", 3)
	_ps.inventory.add("gold_coin", 20)
	for g in ["keen", "keen_2", "keen_3", "ember"]:
		print("gemcheck: tooltip %s = %s" % [g, Gems.describe(g).replace("\n", " | ")])
	var st: Station = _auth.stations[990001]
	Controls.set_captured(false)
	_main.hud.open_station(st)
	await _wait(0.8)
	await _shot("01_gem_bench")
	var button: Button = null
	for b in _main.hud.find_children("*", "Button", true, false):
		if (b as Button).text.begins_with("Combine 3 "):
			button = b
			print("gemcheck: button '%s' disabled=%s tooltip='%s'" % [b.text, b.disabled, b.tooltip_text.replace("\n", " | ")])
	_say(button != null and not button.disabled, "the bench offers to combine 3 Rough Edge Quartz")
	if button:
		button.pressed.emit()
	await _wait(0.6)
	_say(_ps.inventory.count_of("gem_keen_2") == 1, "made 1 Cut Edge Quartz")
	_say(_ps.inventory.count_of("gem_keen") == 0, "the 3 Rough ones are used up")
	_say(_ps.inventory.count_of("gold_coin") == 20 - Gems.COMBINE_GOLD[2], "it cost %d gold" % Gems.COMBINE_GOLD[2])
	await _shot("02_after_combine")
	_main.hud.set_bag_open(false)
	Controls.set_captured(true)
	await _wait(0.5)


# ------------------------------------------------------------------ poison and fire

func _snail(uid: int, variant: String) -> Monster:
	# Off to the dwarf's side, so the Gem Bench in front isn't in the way (a hit can't go through things).
	var n: Node3D = _ps.node
	var side := n.global_basis.x
	side.y = 0.0
	_auth.monsters._ev_spawn(uid, "rock_snail", n.global_position + side.normalized() * 2.2 + Vector3.UP * 0.3, false, 0, variant)
	var m: Monster = _auth.monsters.monsters.get(uid)
	m.target_peer = _auth.local_peer_id()
	return m


func _attack(m: Monster, name: String, atk_override := {}) -> void:
	var n: Node3D = _ps.node
	var d := m.global_position - n.global_position
	var q := PhysicsRayQueryParameters3D.create(m.global_position + Vector3.UP * 0.6, n.global_position + Vector3.UP * 0.9,
		World.TERRAIN_LAYER | PieceNode.PIECE_LAYER)
	var hit := n.get_world_3d().direct_space_state.intersect_ray(q)
	print("gemcheck: %s from %.1f m (%.1f up), in the way: %s" % [name, Vector2(d.x, d.z).length(), d.y, hit.get("collider")])
	if not atk_override.is_empty():
		_auth.monsters.send_tell(m, atk_override)
		return
	for atk in m.data.attacks:
		if atk.name == name:
			_auth.monsters.send_tell(m, atk)


func _snail_poison() -> void:
	var v := _ps.vitals
	var hp0: float = v.health
	var m := _snail(990101, "")
	await _wait(1.5)
	_attack(m, "Spit")
	await _wait(1.3)  # its tell is 0.8 s
	print("gemcheck: after the spit: %s, health %.0f -> %.0f" % [v.ailments.describe(), hp0, v.health])
	_say(v.ailments.describe().size() > 0 and str(v.ailments.describe()).to_lower().contains("poison"), "the spit poisons you")
	await _wait(0.4)
	await _shot("03_poisoned_badge")
	await _wait(3.0)
	print("gemcheck: 3 s later: health %.0f, %s" % [v.health, v.ailments.describe()])
	await _shot("04_poisoned_later")
	_auth.monsters.monsters.erase(m.uid)
	m.queue_free()
	await _wait(9.0)  # let the poison run out


func _fire_through_block() -> void:
	var v := _ps.vitals
	_ps.lantern_stowed = true  # the hand lantern takes the shield hand; put it away
	_ps.inventory.slots[0] = {id = "sword_copper", count = 1}
	_ps.inventory.slots[1] = {id = "shield_copper", count = 1, worn = true}  # worn where it lies (F825)
	_ps.inventory.changed.emit()
	_auth.request_select_slot(_auth.local_peer_id(), 0)
	await _wait(0.5)
	Controls.set_captured(true)
	Input.action_press("use")  # shield up and held (a block, not a parry)
	await _wait(1.2)
	var fight = _ps.node.get("fight")
	print("gemcheck: blocking=%s (%s)" % [fight.is_blocking(), fight.defense_state()])
	var m := _snail(990102, "red")
	await _wait(1.5)
	var hp0: float = v.health
	for i in 5:  # each red slam carries 30 fire; 100 lights you up
		v.stamina = v.max_stamina()
		var before: float = v.health
		_attack(m, "Lunging Bite")
		await _wait(1.5)
		print("gemcheck: slam %d: health %.0f -> %.0f, %s (snail stunned: %s, stamina %.0f)" % [i + 1, before, v.health, v.ailments.describe(), m.stun.is_stunned(), v.stamina])
	print("gemcheck: after 5 blocked red slams: %s, health %.0f -> %.0f" % [v.ailments.describe(), hp0, v.health])
	_say(str(v.ailments.describe()).to_lower().contains("burn"), "fire goes through the block")
	await _wait(0.3)
	await _shot("05_burning_through_block")
	_auth.monsters.monsters.erase(m.uid)
	m.queue_free()
	await _wait(8.0)  # let the fire burn out
	# And poison does not get through a block:
	var green := _snail(990103, "")
	await _wait(1.5)
	for atk in green.data.attacks:
		if atk.name == "Lunging Bite":
			var poisoned: Dictionary = atk.duplicate()
			poisoned.buildup = {poison = 100}
			_attack(green, "Shell Slam (with poison)", poisoned)
	await _wait(1.6)
	print("gemcheck: after a blocked poison slam: %s" % [v.ailments.describe()])
	_say(not str(v.ailments.describe()).to_lower().contains("poison"), "poison does not go through a block")
	Input.action_release("use")
