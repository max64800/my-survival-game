class_name MonsterArena
extends Node
## The Monster Arena (owner, Nov 23): a dev-only test place. A flat grey floor high above the cave with ONE of every
## creature standing still on it (they don't walk or attack, but you can hit, stun and kill them). F10 opens a little
## menu: "Reset" brings every creature back at full health (and clears the stone bodies of dead ones),
## "Fight back" lets them fight you for real, "Heal me" refills you.
## Dev builds only (DevMenu.enabled()): the start-menu button never shows in the game players get.

const ORIGIN := Vector3(0.0, 400.0, 0.0)  ## the middle of the floor
const SIZE := Vector2(64.0, 44.0)         ## floor width (x) and depth (z)
const COLUMNS := 5
const SPACING := 7.0
const ARENA_PACK := 900000                ## the pack number all arena creatures share (no cave room has it)

var _main: Node
var _mgr: MonsterManager
var _spots := {}     ## kind -> Vector3 (where its dummy stands)
var _uids := {}      ## kind -> uid of the one alive now (or missing)
var _fight_back := false
var _panel: PanelContainer
var _fight_button: Button
var _hp_slider: HSlider
var _hp_lock: CheckButton
var _hp_label: Label
var _god_button: Button


## Where each creature kind stands: a grid, nearest the player first, in the order of Monsters.LIST.
static func layout(kinds: Array) -> Dictionary:
	var out := {}
	for i in kinds.size():
		var col := i % COLUMNS
		var row := i / COLUMNS
		var x := (float(col) - float(COLUMNS - 1) * 0.5) * SPACING
		out[kinds[i]] = ORIGIN + Vector3(x, 0.0, -4.0 - float(row) * SPACING)
	return out


func _ready() -> void:
	_main = get_parent()
	_run.call_deferred()


func _run() -> void:
	var waited := 0.0
	while not _main.is_ready_to_play() and waited < 180.0:
		await get_tree().create_timer(0.25).timeout
		waited += 0.25
	var auth: GameAuthority = _main.authority
	_mgr = auth.monsters
	_build_floor()
	var ps := auth.get_player(auth.local_peer_id())
	if ps:  # the same copper gear as the dungeon test
		var gear = load("res://src/debug/dungeon_test_start.gd")
		var inv: Inventory = ps.inventory
		for slot in gear.WEAR:
			inv.slots[Inventory.equip_index(slot)] = {id = gear.WEAR[slot], count = 1}
		for i in Inventory.HOTBAR_SIZE:
			inv.slots[i] = {id = gear.HOTBAR[i][0], count = gear.HOTBAR[i][1]} if i < gear.HOTBAR.size() else {}
		for it in gear.BAG:
			inv.add(it[0], it[1])
		inv.changed.emit()
		ps.fuel = GameAuthority.MAX_FUEL
		give_all_food()  # (owner, Nov 23: every food and drink to try, and every recipe known)
	if ps:
		ps.bed_pos = ORIGIN + Vector3(0.0, 0.4, 8.0)  # if you die here you wake up here, not in the dungeon
	var dwarf: Dwarf = _main.dwarf
	dwarf.global_position = ORIGIN + Vector3(0.0, 0.4, 8.0)
	dwarf.velocity = Vector3.ZERO
	dwarf._yaw = 0.0  # looking toward -z, at the creatures
	dwarf._pitch = 0.0
	dwarf.model.rotation.y = 0.0
	var amb: Ambience = _main.get_node_or_null("Ambience")
	if amb:
		amb.set_dev_bright(true)  # no cave dark or fog up here
	_build_menu()
	reset_all()
	_main.hud.show_toast("Monster Arena: F10 = menu · F11 = reset everyone.", 6.0)
	print("MONSTER_ARENA ready: %d creatures" % _uids.size())
	for arg in OS.get_cmdline_user_args():  # robots: wait, check nobody walked off, kill one, reset, one picture, quit
		if arg.begins_with("shots="):
			await get_tree().create_timer(6.0).timeout
			var moved := 0
			for kind in _uids:
				var m: Monster = _mgr.monsters.get(_uids[kind])
				if m == null:
					print("MONSTER_ARENA missing: ", kind)
				elif Vector2(m.global_position.x - _spots[kind].x, m.global_position.z - _spots[kind].z).length() > 0.5 or m.global_position.y < ORIGIN.y - 1.0:
					moved += 1
					print("MONSTER_ARENA moved/fell: ", kind, " ", m.global_position)
			print("MONSTER_ARENA after 6 s: %d of %d moved or fell" % [moved, _uids.size()])
			var fps: GameAuthority.PlayerState = _main.authority.get_player(_main.authority.local_peer_id())
			var kinds := 0
			for sl in fps.inventory.slots:
				kinds += 1 if Foods.DISHES.has(sl.get("id", "")) else 0
			print("MONSTER_ARENA food kinds in bag: %d of %d" % [kinds, Foods.DISHES.size()])
			var victim: Monster = _mgr.monsters.get(_uids["rock_beetle"])
			_mgr._kill(victim, _main.authority.local_peer_id())
			await get_tree().create_timer(1.0).timeout
			print("MONSTER_ARENA beetle alive after kill: ", _mgr.monsters.has(_uids["rock_beetle"]), ", statues: ", _mgr.statues.size())
			reset_all()
			await get_tree().create_timer(1.0).timeout
			print("MONSTER_ARENA after reset: beetle alive ", _mgr.monsters.has(_uids["rock_beetle"]), ", statues: ", _mgr.statues.size())
			if "lowhp" in OS.get_cmdline_user_args():  # (the screen-edge look at low health, bigger window)
				_main.authority.get_player(_main.authority.local_peer_id()).vitals.health = 45.0
				await get_tree().create_timer(2.5).timeout
			await RenderingServer.frame_post_draw
			print("MONSTER_ARENA shot ", _main.take_screenshot(arg.trim_prefix("shots=").path_join("monster_arena.png")))
			get_tree().quit()


func _build_floor() -> void:
	var body := StaticBody3D.new()
	body.name = "ArenaFloor"
	body.collision_layer = World.TERRAIN_LAYER
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(SIZE.x, 2.0, SIZE.y)
	shape.shape = box
	shape.position = Vector3(0.0, -1.0, 0.0)  # the top of the slab is exactly at ORIGIN.y
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = box.size
	mesh.mesh = bm
	mesh.position = shape.position
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.45, 0.47)
	mat.roughness = 1.0
	mesh.material_override = mat
	body.add_child(mesh)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-60.0, 20.0, 0.0)
	sun.light_energy = 1.1
	body.add_child(sun)
	add_child(body)
	body.global_position = ORIGIN


func _build_menu() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 60
	add_child(layer)
	_panel = PanelContainer.new()
	_panel.position = Vector2(20.0, 20.0)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.04, 0.12, 0.95)  # purple: clearly a dev thing
	bg.set_corner_radius_all(10)
	bg.set_content_margin_all(14)
	_panel.add_theme_stylebox_override("panel", bg)
	var v := VBoxContainer.new()
	_panel.add_child(v)
	var title := Label.new()
	title.text = "Monster Arena  ·  F10 to close  ·  F11 = quick reset"
	title.add_theme_font_size_override("font_size", 20)
	v.add_child(title)
	for e in [["Reset all creatures (full health, back in place)", reset_all],
			["Heal me", heal_me], ["Teleport back to the start", to_start],
			["Refill all food and drinks (5 of each in the bag)", give_all_food]]:
		var b := Button.new()
		b.text = e[0]
		b.custom_minimum_size = Vector2(380, 40)
		b.pressed.connect(e[1])
		v.add_child(b)
	_fight_button = Button.new()
	_fight_button.custom_minimum_size = Vector2(380, 40)
	_fight_button.pressed.connect(toggle_fight_back)
	v.add_child(_fight_button)
	_update_fight_text()
	v.add_child(HSeparator.new())
	var look := Label.new()
	look.text = "Screen looks (nothing hurts you)"
	look.add_theme_font_size_override("font_size", 18)
	v.add_child(look)
	_god_button = Button.new()
	_god_button.custom_minimum_size = Vector2(380, 40)
	_god_button.pressed.connect(toggle_god)
	v.add_child(_god_button)
	_update_god_text()
	_hp_label = Label.new()
	v.add_child(_hp_label)
	_hp_slider = HSlider.new()
	_hp_slider.min_value = 1.0
	_hp_slider.max_value = 100.0
	_hp_slider.step = 1.0
	_hp_slider.value = 100.0
	_hp_slider.custom_minimum_size = Vector2(380, 24)
	_hp_slider.value_changed.connect(func(val): _hp_lock.button_pressed = true; _on_hp_slider(val))  # (moving it holds your health there)
	v.add_child(_hp_slider)
	_hp_lock = CheckButton.new()
	_hp_lock.text = "Holding my health at the slider (moving it turns this on)"
	_hp_lock.toggled.connect(func(_on): _on_hp_slider(_hp_slider.value))
	v.add_child(_hp_lock)
	_on_hp_slider(100.0)
	var row := HBoxContainer.new()
	v.add_child(row)
	for e in [["No look", ""], ["Poison", "poison"], ["Burn", "burn"], ["Chill", "chill"]]:
		var sb := Button.new()
		sb.text = e[0]
		sb.custom_minimum_size = Vector2(90, 36)
		sb.pressed.connect(func(): _main.hud.edge_fake = e[1])
		row.add_child(sb)
	var row2 := HBoxContainer.new()
	v.add_child(row2)
	for e in [["Small hit", 15.0], ["Big hit", 50.0]]:
		var hb := Button.new()
		hb.text = e[0] + " (look only)"
		hb.custom_minimum_size = Vector2(185, 36)
		hb.pressed.connect(func(): _main.hud._on_hurt(e[1]))
		row2.add_child(hb)
	_panel.visible = false
	layer.add_child(_panel)
	# A little how-to on the right side that is always there (owner, Nov 23).
	var help := PanelContainer.new()
	help.anchor_left = 1.0
	help.anchor_right = 1.0
	help.offset_left = -20.0
	help.offset_right = -20.0
	help.offset_top = 70.0
	help.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	help.add_theme_stylebox_override("panel", bg)
	var hv := VBoxContainer.new()
	help.add_child(hv)
	var ht := Label.new()
	ht.text = "How the Arena works"
	ht.add_theme_font_size_override("font_size", 20)
	hv.add_child(ht)
	var tips := Label.new()
	tips.text = "Creatures stand still. Hit them, kill them.

All dead? Bring them back:
  1. Press F10 (the mouse appears)
  2. Click \"Reset all creatures\"
  3. Press F10 again to keep playing

Quick way: press F11 = reset at once.

In the menu you can also:
  · Heal me (refill health)
  · Fight back ON (they attack you)
  · Teleport back to the start"
	hv.add_child(tips)
	layer.add_child(help)


func _unhandled_input(event: InputEvent) -> void:
	if _panel == null:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		reset_all()
		_main.hud.show_toast("Arena reset: everyone is back.", 2.0)
		get_viewport().set_input_as_handled()
		return
	var open_key: bool = event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10
	var close_key: bool = _panel.visible and event.is_action_pressed("pause")
	if open_key or close_key:
		_panel.visible = not _panel.visible
		Controls.set_captured(not _panel.visible)
		get_viewport().set_input_as_handled()


func _update_fight_text() -> void:
	_fight_button.text = "Fight back: %s (click to switch)" % ("ON, they attack you" if _fight_back else "OFF, they stand still")


## Every creature comes back at full health, standing in its place. Stone bodies of the dead go too.
func reset_all() -> void:
	for kind in _uids:
		if _mgr.monsters.has(_uids[kind]):
			_mgr._ev_remove.rpc(_uids[kind], -1)  # (sinks away: no stone body)
	_uids.clear()
	for id in _mgr.statues.keys():
		_mgr.statues.erase(id)
		_mgr._ev_statue_gone.rpc(id, false)
	var kinds := Monsters.LIST.keys()
	_spots = layout(kinds)
	for kind in kinds:
		_spawn(kind)
	_heal_everyone()


func _spawn(kind: String) -> void:
	var uid := _mgr._next_uid
	_mgr._next_uid += 1
	var pos: Vector3 = _spots[kind]
	if Monsters.LIST[kind].get("flies", false):
		pos.y += 1.6  # a flyer hangs in the air
	_mgr._ev_spawn.rpc(uid, kind, pos + Vector3.UP * 0.3, false, ARENA_PACK)
	var m: Monster = _mgr.monsters.get(uid)
	if m == null:
		return
	m.dummy = not _fight_back
	m.state = Monster.State.IDLE  # (not asleep or lying: they stand and wait)
	if m.rig != null and m.data.get("rises", false):
		m.rig.rise()  # (the skeletons start as a pile of bones: they stand up, then wait)
	_uids[kind] = uid
	var tag := Label3D.new()
	tag.text = String(Monsters.LIST[kind].name)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.pixel_size = 0.006
	tag.font_size = 48
	tag.outline_size = 12
	tag.position = Vector3(0.0, float(m.data.get("height", 1.2)) * float(m.data.size) + 0.9, 0.0)
	m.add_child(tag)


func toggle_fight_back() -> void:
	_fight_back = not _fight_back
	for kind in _uids:
		var m: Monster = _mgr.monsters.get(_uids[kind])
		if m:
			m.dummy = not _fight_back
			if _fight_back:
				m.alert(_main.authority.local_peer_id())
	_update_fight_text()


func _heal_everyone() -> void:
	heal_me()


## Every food and drink, 5 of each, in the bag (26 kinds fit next to the gear), and every food recipe known
## (owner, Nov 23). Old food in the bag is thrown out first so a refill never runs out of room.
func give_all_food() -> void:
	var auth: GameAuthority = _main.authority
	var ps := auth.get_player(auth.local_peer_id())
	if ps == null:
		return
	var inv: Inventory = ps.inventory
	for i in inv.slots.size():
		if Foods.DISHES.has(inv.slots[i].get("id", "")):
			inv.slots[i] = {}
	var left := 0
	for id in Foods.DISHES:
		left += inv.add(id, 5)
	inv.changed.emit()
	var learned: Array = auth.world_state.get("learned", [])
	for r in Recipes.LIST:
		if not Foods.DISHES.has(String(Recipes.LIST[r].output)):
			continue
		var u = Recipes.LIST[r].unlock
		if u is String:
			if not learned.has(r):
				learned.append(r)
		else:
			for item in u:
				ps.seen[item] = true
	auth.world_state["learned"] = learned
	_main.hud.show_toast("Every food and drink is in your bag (5 of each)%s; every cooking recipe is known." % ("" if left == 0 else ", %d didn't fit" % left), 4.0)


func heal_me() -> void:
	if _hp_lock != null:
		_hp_lock.button_pressed = false  # (stop holding it at the slider)
		_hp_slider.set_value_no_signal(100.0)
		_hp_label.text = "My health: 100%"
	var auth: GameAuthority = _main.authority
	var ps := auth.get_player(auth.local_peer_id())
	if ps:
		ps.vitals.health = ps.vitals.max_health()


func to_start() -> void:
	var dwarf: Dwarf = _main.dwarf
	dwarf.global_position = ORIGIN + Vector3(0.0, 0.4, 8.0)
	dwarf.velocity = Vector3.ZERO


func toggle_god() -> void:
	var dwarf: Dwarf = _main.dwarf
	dwarf.dev_god = not dwarf.dev_god
	var me = _main.authority.get_player(_main.authority.local_peer_id())
	if me:
		me.vitals.god = dwarf.dev_god
	_update_god_text()


func _update_god_text() -> void:
	_god_button.text = "God mode: %s (click to switch)" % ("ON, nothing hurts" if _main.dwarf.dev_god else "OFF")


func _on_hp_slider(value: float) -> void:
	_hp_label.text = "My health: %d%%" % int(value)
	if _hp_lock.button_pressed:
		_hold_health()


func _hold_health() -> void:
	var ps = _main.authority.get_player(_main.authority.local_peer_id())
	if ps:
		ps.vitals.god = false  # (god mode would refill you at once)
		_main.dwarf.dev_god = false
		_update_god_text()
		ps.vitals.health = ps.vitals.max_health() * _hp_slider.value / 100.0


func _process(_delta: float) -> void:
	if _hp_lock != null and _hp_lock.button_pressed:
		_hold_health()
