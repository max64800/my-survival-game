class_name Hud
extends CanvasLayer
## Everything drawn on top of the game: crosshair, what you're aiming at,
## dig progress, the hotbar (Item Bar), the bag, lantern fuel, frame rate, pause screen.

const SLOT_SIZE := 58

var peer_id := 1
var seed_text := ""

var _aim_label: Label
var _dig_bar: ProgressBar
var _dig_bar_timer := 0.0
var _hotbar: HBoxContainer
var _bag_panel: PanelContainer
var _bag_grid: GridContainer
var _fuel_bar: ProgressBar
var _fuel_label: Label
var _fps_label: Label
var _toast: Label
var _toast_timer := 0.0
var _help: Label
var _help_timer := 25.0
var _pause: Control
var _loading: Control
var _swap_from := -1
var _bars := {}  ## "health"/"stamina"/"hunger"/"thirst" -> ProgressBar
var _level_label: Label
var _buff_label: Label
var craft: CraftPanel
var skills: SkillsPanel
var map_panel: MapPanel
var build_menu: BuildMenu
var blueprint_menu: BlueprintMenu
var box_panel: BoxPanel
var build_mode: BuildMode
var _build_label: Label
var _boss_label: Label
var _boss_bar: ProgressBar
var map_data := MapData.new()
var _map_timer := 0.0
var _slot_style_cache := {}


func _ready() -> void:
	layer = 10
	_build()
	var auth := GameAuthority.instance
	if auth:
		auth.dig_feedback.connect(_on_dig_feedback)
		var ps := auth.get_player(peer_id)
		if ps:
			ps.inventory.changed.connect(_refresh_slots)
	_refresh_slots()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var cross := Label.new()
	cross.text = "+"
	cross.add_theme_font_size_override("font_size", 22)
	cross.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cross.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	cross.add_theme_color_override("font_outline_color", Color.BLACK)
	cross.add_theme_constant_override("outline_size", 4)
	root.add_child(cross)

	_aim_label = _label(root, 16)
	_aim_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_aim_label.position += Vector2(-100, 26)
	_aim_label.custom_minimum_size = Vector2(200, 0)
	_aim_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_dig_bar = ProgressBar.new()
	_dig_bar.show_percentage = false
	_dig_bar.custom_minimum_size = Vector2(90, 8)
	_dig_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_dig_bar.position += Vector2(-45, 52)
	_dig_bar.visible = false
	root.add_child(_dig_bar)

	_hotbar = HBoxContainer.new()
	_hotbar.add_theme_constant_override("separation", 6)
	_hotbar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_hotbar.position += Vector2(-(SLOT_SIZE + 6) * 4, -SLOT_SIZE - 18)
	root.add_child(_hotbar)
	for i in Inventory.HOTBAR_SIZE:
		_hotbar.add_child(_make_slot(i, str(i + 1)))

	_bag_panel = PanelContainer.new()
	_bag_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_bag_panel.visible = false
	var bag_bg := StyleBoxFlat.new()
	bag_bg.bg_color = Color(0.06, 0.05, 0.05, 0.88)
	bag_bg.set_corner_radius_all(10)
	bag_bg.set_content_margin_all(14)
	_bag_panel.add_theme_stylebox_override("panel", bag_bg)
	root.add_child(_bag_panel)
	var bag_box := VBoxContainer.new()
	_bag_panel.add_child(bag_box)
	var title := _label(bag_box, 18)
	title.text = "Bag  (click two slots to swap them)"
	_bag_grid = GridContainer.new()
	_bag_grid.columns = 10
	bag_box.add_child(_bag_grid)
	for i in Inventory.BAG_SIZE:
		_bag_grid.add_child(_make_slot(Inventory.HOTBAR_SIZE + i, ""))
	_bag_panel.resized.connect(func(): _bag_panel.position = (root.size - _bag_panel.size) * 0.5)

	var fuel_box := VBoxContainer.new()
	fuel_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	fuel_box.position += Vector2(20, -70)
	root.add_child(fuel_box)
	_fuel_label = _label(fuel_box, 15)
	_fuel_bar = ProgressBar.new()
	_fuel_bar.custom_minimum_size = Vector2(200, 10)
	_fuel_bar.show_percentage = false
	_fuel_bar.max_value = GameAuthority.MAX_FUEL
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(1.0, 0.75, 0.35)
	_fuel_bar.add_theme_stylebox_override("fill", fill)
	fuel_box.add_child(_fuel_bar)

	# Body bars (bottom left, above the lantern).
	var bars := VBoxContainer.new()
	bars.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	bars.position += Vector2(20, -190)
	bars.add_theme_constant_override("separation", 3)
	root.add_child(bars)
	for b in [["health", Color(0.85, 0.25, 0.25)], ["stamina", Color(0.95, 0.85, 0.3)], ["hunger", Color(0.9, 0.55, 0.25)], ["thirst", Color(0.35, 0.6, 1.0)]]:
		var row := HBoxContainer.new()
		bars.add_child(row)
		var l := _label(row, 13)
		l.text = b[0].capitalize()
		l.custom_minimum_size = Vector2(62, 0)
		var pb := ProgressBar.new()
		pb.custom_minimum_size = Vector2(150, 10)
		pb.show_percentage = false
		var bar_fill := StyleBoxFlat.new()
		bar_fill.bg_color = b[1]
		pb.add_theme_stylebox_override("fill", bar_fill)
		row.add_child(pb)
		_bars[b[0]] = pb
	_buff_label = _label(bars, 13)
	_level_label = _label(root, 16)
	_level_label.anchor_left = 1.0
	_level_label.anchor_right = 1.0
	_level_label.offset_left = -460
	_level_label.offset_right = -16
	_level_label.offset_top = 36
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	craft = CraftPanel.new()
	craft.peer_id = peer_id
	craft.visible = false
	root.add_child(craft)
	craft.resized.connect(func(): craft.position = Vector2(root.size.x - craft.size.x - 30, 90))

	skills = SkillsPanel.new()
	skills.peer_id = peer_id
	skills.visible = false
	root.add_child(skills)
	skills.resized.connect(func(): skills.position = (root.size - skills.size) * 0.5)
	box_panel = BoxPanel.new()
	box_panel.visible = false
	root.add_child(box_panel)
	box_panel.resized.connect(func(): box_panel.position = Vector2(root.size.x - box_panel.size.x - 30, 90))
	build_menu = BuildMenu.new()
	build_menu.peer_id = peer_id
	build_menu.visible = false
	root.add_child(build_menu)
	build_menu.resized.connect(func(): build_menu.position = (root.size - build_menu.size) * 0.5)
	blueprint_menu = BlueprintMenu.new()
	blueprint_menu.visible = false
	root.add_child(blueprint_menu)
	blueprint_menu.resized.connect(func(): blueprint_menu.position = (root.size - blueprint_menu.size) * 0.5)
	_build_label = _label(root, 16)
	_build_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_build_label.position += Vector2(-300, -110)
	_build_label.custom_minimum_size = Vector2(600, 0)
	_build_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	map_panel = MapPanel.new()
	map_panel.visible = false
	root.add_child(map_panel)
	map_panel.resized.connect(func(): map_panel.position = (root.size - map_panel.size) * 0.5)

	_boss_label = _label(root, 20)
	_boss_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_boss_label.position += Vector2(-300, 120)
	_boss_label.custom_minimum_size = Vector2(600, 0)
	_boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_bar = ProgressBar.new()
	_boss_bar.show_percentage = false
	_boss_bar.custom_minimum_size = Vector2(600, 14)
	_boss_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_boss_bar.position += Vector2(-300, 150)
	var boss_fill := StyleBoxFlat.new()
	boss_fill.bg_color = Color(0.75, 0.15, 0.15)
	_boss_bar.add_theme_stylebox_override("fill", boss_fill)
	root.add_child(_boss_bar)

	_fps_label = _label(root, 15)
	_fps_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_fps_label.position += Vector2(-130, 10)

	_toast = _label(root, 20)
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast.position += Vector2(-250, 80)
	_toast.custom_minimum_size = Vector2(500, 0)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_help = _label(root, 14)
	_help.position = Vector2(16, 12)
	_help.text = "WASD walk · Shift run · Space jump · Mouse look\nLeft click dig/harvest · Right click eat/place · E use station\n1-8 / wheel hotbar · R refill lantern · Tab bag + crafting\nK skills · M map · Esc pause"

	_pause = _overlay(root, "Paused", "Click to keep digging")
	_loading = _overlay(root, "Digging out the cave…", "")
	_loading.visible = true


func _label(parent: Node, size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 5)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _overlay(root: Control, title: String, sub: String) -> Control:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.04, 0.72)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.visible = false
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	bg.add_child(box)
	var t := _label(box, 40)
	t.text = title
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var s := _label(box, 18)
	s.name = "Sub"
	s.text = sub
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.resized.connect(func(): box.position = (bg.size - box.size) * 0.5)
	return bg


func _make_slot(index: int, key: String) -> Control:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	panel.name = "Slot%d" % index
	panel.gui_input.connect(_on_slot_input.bind(index))
	var icon := Panel.new()
	icon.name = "Icon"
	icon.position = Vector2(9, 9)
	icon.size = Vector2(SLOT_SIZE - 18, SLOT_SIZE - 18)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(icon)
	var short := _label(panel, 15)
	short.name = "Short"
	short.position = Vector2(0, 17)
	short.size = Vector2(SLOT_SIZE, 20)
	short.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var count := _label(panel, 14)
	count.name = "Count"
	count.position = Vector2(4, SLOT_SIZE - 22)
	count.size = Vector2(SLOT_SIZE - 8, 20)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var k := _label(panel, 11)
	k.text = key
	k.position = Vector2(4, 1)
	return panel


func _slot_style(color: Color, border: Color) -> StyleBoxFlat:
	var key := [color, border]
	if not _slot_style_cache.has(key):
		var s := StyleBoxFlat.new()
		s.bg_color = color
		s.border_color = border
		s.set_border_width_all(2)
		s.set_corner_radius_all(6)
		_slot_style_cache[key] = s
	return _slot_style_cache[key]


func _refresh_slots() -> void:
	if craft and craft.visible:
		craft.refresh()
	var auth := GameAuthority.instance
	var ps: GameAuthority.PlayerState = auth.get_player(peer_id) if auth else null
	if ps == null:
		return
	for i in Inventory.SIZE:
		var panel: Panel = _hotbar.get_child(i) if i < Inventory.HOTBAR_SIZE else _bag_grid.get_child(i - Inventory.HOTBAR_SIZE)
		var s := ps.inventory.get_slot(i)
		var selected := i == ps.selected_slot
		var swap_pick := i == _swap_from
		var border := Color(1, 0.85, 0.4) if selected or swap_pick else Color(0.4, 0.38, 0.35, 0.9)
		panel.add_theme_stylebox_override("panel", _slot_style(Color(0.08, 0.07, 0.07, 0.75), border))
		var icon: Panel = panel.get_node("Icon")
		icon.visible = not s.is_empty()
		if not s.is_empty():
			icon.add_theme_stylebox_override("panel", _slot_style(Items.color(s.id).darkened(0.15), Items.color(s.id).lightened(0.3)))
			panel.tooltip_text = Items.display_name(s.id)
		(panel.get_node("Short") as Label).text = "" if s.is_empty() else Items.short_label(s.id)
		(panel.get_node("Count") as Label).text = "" if s.is_empty() or s.count <= 1 else str(s.count)


func _on_slot_input(event: InputEvent, index: int) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if not _bag_panel.visible:
		return
	if box_panel.visible:
		GameAuthority.instance.storage.ask_transfer(box_panel.box_id, false, index)
		return
	if _swap_from < 0:
		_swap_from = index
	else:
		GameAuthority.instance.ask_swap(_swap_from, index)
		_swap_from = -1
	_refresh_slots()


func _on_dig_feedback(pid: int, result: Dictionary) -> void:
	if pid != peer_id:
		return
	match result.get("state", ""):
		"hit":
			_dig_bar.max_value = result.needed
			_dig_bar.value = result.hits
			_dig_bar.visible = true
			_dig_bar_timer = 1.2
		"dug":
			_dig_bar.value = _dig_bar.max_value
			_dig_bar_timer = 0.25
		"blocked":
			show_toast(result.get("why", "Too hard! This rock needs a better pickaxe."))
		"no_tool":
			show_toast("Pick your pickaxe in the hotbar (key 1).")


func show_toast(text: String, seconds: float = 2.5) -> void:
	_toast.text = text
	_toast_timer = seconds


func set_loading(on: bool, text: String = "") -> void:
	_loading.visible = on
	if text != "":
		(_loading.find_child("Sub", true, false) as Label).text = text


func is_bag_open() -> bool:
	return _bag_panel.visible


func set_bag_open(open: bool) -> void:
	if open != _bag_panel.visible:
		Sfx.ui("open" if open else "close", -10.0)
	_bag_panel.visible = open
	_swap_from = -1
	_refresh_slots()
	box_panel.visible = false
	if open:
		craft.open_for(null)
	else:
		craft.visible = false


## E at a chest or grave: your bag on the left, the box on the right.
func open_box(id: int) -> void:
	_bag_panel.visible = true
	_refresh_slots()
	craft.visible = false
	box_panel.open(id)


func is_build_menu_open() -> bool:
	return build_menu.visible


func set_build_menu_open(open: bool) -> void:
	build_menu.mode = build_mode
	build_menu.visible = open
	if open:
		build_menu.refresh()


func is_blueprints_open() -> bool:
	return blueprint_menu.visible


func set_blueprints_open(open: bool) -> void:
	blueprint_menu.mode = build_mode
	blueprint_menu.visible = open
	if open:
		blueprint_menu.refresh()


func is_map_open() -> bool:
	return map_panel.visible


func set_map_open(open: bool) -> void:
	map_panel.visible = open
	var d := _local_dwarf()
	if open and d:
		map_panel.open(map_data, d.global_position, d.model.rotation.y + PI, GameAuthority.instance.stations.values())


func is_skills_open() -> bool:
	return skills.visible


func set_skills_open(open: bool) -> void:
	skills.visible = open
	if open:
		skills.refresh()


func open_station(st: Station) -> void:
	_bag_panel.visible = true
	_refresh_slots()
	craft.open_for(st)


func set_paused(on: bool) -> void:
	_pause.visible = on
	(_pause.find_child("Sub", true, false) as Label).text = "Click to keep digging\n\nCave seed: %s" % seed_text


func _process(delta: float) -> void:
	var auth := GameAuthority.instance
	var ps: GameAuthority.PlayerState = auth.get_player(peer_id) if auth else null
	if ps:
		var v := ps.vitals
		_bars.health.max_value = v.max_health()
		_bars.health.value = v.health
		_bars.stamina.max_value = v.max_stamina()
		_bars.stamina.value = v.stamina
		_bars.hunger.value = v.hunger
		_bars.thirst.value = v.thirst
		var buffs := []
		for b in v.buffs:
			buffs.append("%s %d:%02d" % [Items.display_name(b.id), int(b.time_left) / 60, int(b.time_left) % 60])
		var mood: String = {"well_fed": "Well fed", "peckish": "Peckish", "starving": "Starving (tired)"}.get(v.status(), "")
		_buff_label.text = "\n".join(([mood] if mood != "" else []) + buffs + Array(v.ailments.describe()))
		var p := ps.progress
		_level_label.text = "Level %d  (%d/%d XP)%s\nMining %d · Fighting %d · Smithing %d · Survival %d" % [
			p.level, p.xp, Progression.xp_to_next(p.level), "  · %d perk points" % p.points_free() if p.points_free() > 0 else "",
			p.skill_level.mining, p.skill_level.fighting, p.skill_level.smithing, p.skill_level.survival]
		if craft.visible and craft.station:
			craft._status.text = craft.station.busy_text()
		_fuel_bar.value = ps.fuel
		var crystals := 0
		for id in GameAuthority.FUEL_ORDER:
			crystals += ps.inventory.count_of(id)
		var mins := int(ps.fuel) / 60
		var secs := int(ps.fuel) % 60
		_fuel_label.text = "Lantern %d:%02d   (R: refill, %d fuel)" % [mins, secs, crystals]
		if ps.fuel <= 0.0:
			_fuel_label.text = "Lantern is out!  Mine a glow crystal, press R"
		var me := _local_dwarf()
		if me and me.fight and me.fight.is_crossbow():
			var bolts := 0
			for id in Combat.BOLT_ORDER:
				bolts += ps.inventory.count_of(id)
			var state := "loaded" if me.fight.loaded else ("reloading %.1f s" % me.fight.reload_left if me.fight.reload_left >= 0.0 else "empty: R to reload")
			_fuel_label.text = "Lantern %d:%02d   ·   Crossbow %s, %d bolts" % [mins, secs, state, bolts]
		_refresh_selection(ps.selected_slot)
	var dwarf := _local_dwarf()
	if dwarf:
		var info := dwarf._aim_info()
		if info.is_empty():
			_aim_label.text = ""
		elif info.kind == "rock":
			var tool := ps.selected_item() if ps else ""
			var power := Items.dig_power(tool) if Items.dig_power(tool) > 0 else 10
			var hits := Mat.hits_needed(info.material, power, maxi(Items.tier(tool), 0))
			_aim_label.text = "%s · %s" % [info.name, "needs a %s pickaxe" % Mat.TIER_NAMES[Mat.min_tier(info.material)] if hits == 0 else "%d hit%s" % [hits, "" if hits == 1 else "s"]]
		else:
			_aim_label.text = info.name
	_fps_label.text = "%d FPS" % Engine.get_frames_per_second()
	_update_boss_bar(dwarf)
	if build_mode and build_mode.active() and build_mode.blueprint:
		_build_label.text = "Blueprint: %s (%s)\nQ turn · left click place · right click cancel" % [build_mode.blueprint.name, BuildMenu._cost_text(build_mode.blueprint.cost())]
	elif build_mode and build_mode.active():
		var c := BuildMenu._cost_text(Pieces.cost(build_mode.piece, build_mode.family))
		_build_label.text = "%s · %s (%s)%s\nB choose · Q turn · PgUp/PgDn lift · right click take down · C save blueprint · V blueprints" % [
			Pieces.LIST[build_mode.piece].name, Pieces.FAMILIES[build_mode.family].name, c,
			"" if build_mode.problem == "" else "  —  " + build_mode.problem]
	else:
		_build_label.text = ""
	_map_timer -= delta
	if _map_timer <= 0.0 and dwarf and auth and auth.world:
		_map_timer = 0.5
		map_data.reveal(dwarf.global_position, auth.world.sdf_at)
	_dig_bar_timer -= delta
	if _dig_bar_timer <= 0.0:
		_dig_bar.visible = false
	_toast_timer -= delta
	_toast.modulate.a = clampf(_toast_timer, 0.0, 1.0)
	_help_timer -= delta
	_help.modulate.a = clampf(_help_timer / 3.0, 0.0, 1.0)


var _last_selected := -1


func _refresh_selection(sel: int) -> void:
	if sel != _last_selected:
		_last_selected = sel
		_refresh_slots()


## A big health bar at the top while a boss is near.
func _update_boss_bar(dwarf: Dwarf) -> void:
	var auth := GameAuthority.instance
	var boss: Monster = null
	if dwarf and auth and auth.monsters:
		for m: Monster in auth.monsters.monsters.values():
			if m.is_boss() and m.global_position.distance_to(dwarf.global_position) < 50.0:
				boss = m
	_boss_label.visible = boss != null
	_boss_bar.visible = boss != null
	if boss:
		_boss_label.text = boss.data.name + ("  —  DAZED!" if boss.stun.is_stunned() else "")
		_boss_bar.max_value = boss.max_hp()
		_boss_bar.value = boss.hp


func _local_dwarf() -> Dwarf:
	var auth := GameAuthority.instance
	var ps: GameAuthority.PlayerState = auth.get_player(peer_id) if auth else null
	return ps.node as Dwarf if ps else null


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fps"):
		_fps_label.visible = not _fps_label.visible
