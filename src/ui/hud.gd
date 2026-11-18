class_name Hud
extends CanvasLayer
## Everything drawn on top of the game: crosshair, what you're aiming at,
## dig progress, the hotbar (Item Bar), the bag, lantern fuel, frame rate, pause screen.

const SLOT_SIZE := 58
const HOTBAR_SLOT := 88  ## the item bar at the bottom of the screen is bigger than the bag's slots
const BAG_HINT := "Click: pick up / swap  ·  Shift+Click: quick move  ·  Double-click: equip  ·  Right-click: split"

## A button on the Escape menu was pressed: "resume", "save", "invite", "menu" or "quit" (F87).
signal pause_pressed(what: String)

var peer_id := 1
var seed_text := ""

var _aim_label: Label
var _dig_bar: ProgressBar
var _dig_bar_timer := 0.0
var _hotbar: HBoxContainer
var _hotbar_home: Control  ## where the hotbar lives while playing (bottom of the screen)
var _bag_panel: PanelContainer
var _bag_grid: GridContainer
var _slot_panels := {}  ## inventory index -> its slot Panel (hotbar, bag, backpack, equipment)
var _pack_title: Label
var _equip_title: Label
const EQUIP_NAMES := ["Pick", "Lamp", "Weapon", "Shield", "Head", "Chest", "Legs", "Feet", "Pack"]
var _fuel_bar: ProgressBar
var _fuel_label: Label
var _fps_label: Label
var _goals_label: Label  ## "Next steps" in the top-right corner (F103)
var _goals_wait := 0.0
var _toast: Label
var _toast_timer := 0.0
var _help: Label
var _help_timer := 25.0
var _pause: Control
var _loading: Control
var _loading_bar: ProgressBar
var _swap_from := -1
var _hover_slot := -1  ## the bag slot under the mouse (for "press 1-9 to put it on the hotbar", F155)
var _bars := {}  ## "health"/"stamina" -> framed ProgressBar, "hunger"/"thirst" -> VitalDial (F229)
var _vitals: VBoxContainer  ## health + stamina bars above the hotbar
var _dials: HBoxContainer  ## hunger + thirst dials left of the hotbar
const DIAL_SIZE := 72
const VitalDialScript := preload("res://src/ui/vital_dial.gd")
var _health_text: Label
var _level_label: Label
var _buff_label: Label
var craft: CraftPanel
var skills: SkillsPanel
var map_panel: MapPanel
var build_menu: BuildMenu
var blueprint_menu: BlueprintMenu
var dev_menu: DevMenu  ## P in dev builds
var _work_box: VBoxContainer  ## by a Builder's Chest: what's being built, how far along (owner, Nov 16)
var _work_label: Label
var _work_bar: ProgressBar
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
	process_mode = Node.PROCESS_MODE_ALWAYS  # the pause screen keeps working while the world is frozen (F239)
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
	_hotbar_home = root
	root.add_child(_hotbar)
	for i in Inventory.HOTBAR_SIZE:
		_hotbar.add_child(_make_slot(i, str(i + 1)))
	_place_hotbar()

	_bag_panel = PanelContainer.new()
	_bag_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_bag_panel.visible = false
	UiKit.panel(_bag_panel)  # "dwarf workshop" frame (owner F187)
	root.add_child(_bag_panel)
	var bag_outer := VBoxContainer.new()
	bag_outer.add_theme_constant_override("separation", 8)
	_bag_panel.add_child(bag_outer)
	UiKit.title(bag_outer, "Bag")
	# Equipped things on the left, everything you carry on the right (owner F150).
	var bag_row := HBoxContainer.new()
	bag_row.add_theme_constant_override("separation", 18)
	bag_outer.add_child(bag_row)
	var equip_col := VBoxContainer.new()
	bag_row.add_child(equip_col)
	var bag_box := VBoxContainer.new()
	bag_row.add_child(bag_box)
	# The hotbar stays at the bottom of the screen while the bag is open (owner F241); its slots
	# work the same there (click, drag, Shift+click), so it isn't repeated in here.
	_bag_grid = GridContainer.new()
	_bag_grid.columns = 10
	bag_box.add_child(_bag_grid)
	for i in Inventory.BAG_SIZE:
		_bag_grid.add_child(_make_slot(Inventory.HOTBAR_SIZE + i, ""))
	# Backpack slots (open while a backpack is worn) and the equipment slots (feedback F23).
	_pack_title = _label(bag_box, 15)
	var pack_grid := GridContainer.new()
	pack_grid.columns = 10
	bag_box.add_child(pack_grid)
	for i in Inventory.PACK_SIZE:
		pack_grid.add_child(_make_slot(Inventory.PACK_START + i, ""))
	_equip_title = _label(equip_col, 15)
	_equip_title.custom_minimum_size = Vector2(2 * (SLOT_SIZE + 4), 0)
	_equip_title.autowrap_mode = TextServer.AUTOWRAP_WORD
	var equip_grid := GridContainer.new()
	equip_grid.columns = 2
	equip_col.add_child(equip_grid)
	for i in Inventory.EQUIP.size():
		equip_grid.add_child(_make_slot(Inventory.EQUIP_START + i, ""))  # no names, the pictures say it (owner F242)
	# One short hint line, no long explanations (owner F179, F187).
	UiKit.divider(bag_outer)
	var hint := UiKit.label(bag_outer, BAG_HINT, 13, UiKit.DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Centred in the space left of the crafting list (it sits on the right), so they never overlap.
	_bag_panel.resized.connect(_layout_panels)
	root.resized.connect(_layout_panels)
	_bag_panel.visibility_changed.connect(_layout_panels)

	var fuel_box := VBoxContainer.new()
	fuel_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	fuel_box.position += Vector2(20, -170)  # above the hunger/thirst dials (F240)
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

	# Body (F229, owner F240): fat health and stamina bars as long as the hotbar, right above it;
	# big hunger and thirst dials on the hotbar's left. Same wood-and-brass kit pieces as the menus.
	_vitals = VBoxContainer.new()
	_vitals.name = "Vitals"
	_vitals.add_theme_constant_override("separation", 4)
	_vitals.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_vitals)
	_dials = HBoxContainer.new()
	_dials.name = "Dials"
	_dials.add_theme_constant_override("separation", 10)
	_dials.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_dials)
	for k in ["hunger", "thirst"]:
		var d: Control = VitalDialScript.new(k)
		d.name = k.capitalize()
		d.custom_minimum_size = Vector2(DIAL_SIZE, DIAL_SIZE)
		d.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_dials.add_child(d)
		_bars[k] = d
	var stack := _vitals
	for b in [["health", Color(1.0, 0.36, 0.3), 32], ["stamina", Color(1, 1, 1), 24]]:
		var pb := ProgressBar.new()
		pb.name = b[0].capitalize()
		pb.custom_minimum_size = Vector2(0, b[2])
		pb.show_percentage = false
		pb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pb.add_theme_stylebox_override("background", UiKit.style("slider_track"))
		var bar_fill: StyleBoxTexture = UiKit.style("slider_fill").duplicate()
		bar_fill.modulate_color = b[1]
		pb.add_theme_stylebox_override("fill", bar_fill)
		stack.add_child(pb)
		_bars[b[0]] = pb
	_place_vitals()
	_health_text = _label(_bars.health, 16)
	_health_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	_health_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_health_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Moods, food buffs and ailments: small text in the bottom-left, above the lantern.
	_buff_label = _label(root, 13)
	_buff_label.anchor_top = 1.0
	_buff_label.anchor_bottom = 1.0
	_buff_label.offset_left = 20
	_buff_label.offset_top = -300
	_buff_label.offset_bottom = -178
	_buff_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
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
	craft.resized.connect(_layout_panels)
	craft.visibility_changed.connect(_layout_panels)
	var up := craft.make_upgrade_panel()
	root.add_child(up)
	up.resized.connect(_layout_panels)
	up.visibility_changed.connect(_layout_panels)

	skills = SkillsPanel.new()
	skills.peer_id = peer_id
	skills.visible = false
	root.add_child(skills)
	skills.resized.connect(func(): skills.position = (root.size - skills.size) * 0.5)
	box_panel = BoxPanel.new()
	box_panel.visible = false
	box_panel.emptied.connect(func() -> void:  # (you took everything: back to the game, owner Nov 18)
		set_bag_open(false)
		Controls.set_captured(true))
	root.add_child(box_panel)
	box_panel.resized.connect(_layout_panels)
	box_panel.visibility_changed.connect(_layout_panels)
	build_menu = BuildMenu.new()
	build_menu.peer_id = peer_id
	build_menu.visible = false
	root.add_child(build_menu)
	build_menu.resized.connect(func(): build_menu.position = (root.size - build_menu.size) * 0.5)
	blueprint_menu = BlueprintMenu.new()
	blueprint_menu.visible = false
	root.add_child(blueprint_menu)
	blueprint_menu.resized.connect(func(): blueprint_menu.position = (root.size - blueprint_menu.size) * 0.5)
	dev_menu = DevMenu.new()
	dev_menu.visible = false
	root.add_child(dev_menu)
	dev_menu.resized.connect(func(): dev_menu.position = (root.size - dev_menu.size) * 0.5)
	_work_box = VBoxContainer.new()
	_work_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_work_box.custom_minimum_size = Vector2(460, 0)
	_work_box.position += Vector2(-230, -250)  # above the body bars (F229)
	_work_box.visible = false
	root.add_child(_work_box)
	_work_label = _label(_work_box, 16)
	_work_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_work_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_work_bar = ProgressBar.new()
	_work_bar.custom_minimum_size = Vector2(460, 20)
	_work_bar.show_percentage = false
	_work_box.add_child(_work_bar)
	# While the Build Hammer is out: what you're building and every key, on the right side (owner F131).
	_build_label = _label(root, 16)
	_build_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	_build_label.custom_minimum_size = Vector2(340, 0)
	_build_label.position += Vector2(-360, -170)
	_build_label.autowrap_mode = TextServer.AUTOWRAP_WORD
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
	_goals_label = _label(root, 15)
	_goals_label.name = "Goals"
	_goals_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_goals_label.custom_minimum_size = Vector2(440, 0)
	_goals_label.position = Vector2(16, 112)  # under the controls help, top left
	_goals_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_goals_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.62))

	_toast = _label(root, 20)
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast.position += Vector2(-250, 80)
	_toast.custom_minimum_size = Vector2(500, 0)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_help = _label(root, 14)
	_help.position = Vector2(16, 12)
	_help.text = "WASD walk · Shift run · Space jump · Mouse look\nLeft click dig/harvest · Right click eat/place · E use station\n1-9 hotbar · Wheel zoom · R refill lantern · Tab bag + crafting\nK skills · M map · Esc pause"

	_pause = _build_pause(root)
	# Loading cover (F226): its own layer above everything, fully solid, so the dwarf and the cave
	# never peek through before they're ready. Same dark colour as the "Making your world…" screen.
	var cover := CanvasLayer.new()
	cover.layer = 90
	add_child(cover)
	var cover_root := Control.new()
	cover_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	cover_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.add_child(cover_root)
	_loading = _overlay(cover_root, "Digging out the cave…", "")
	(_loading as ColorRect).color = Color(0.04, 0.035, 0.05)
	_loading.mouse_filter = Control.MOUSE_FILTER_STOP
	_loading.visible = true
	_loading.visibility_changed.connect(func(): cover.visible = _loading.visible)
	_loading_bar = ProgressBar.new()  # how far the cave around you is ready (owner, Nov 16)
	_loading_bar.custom_minimum_size = Vector2(420, 18)
	_loading_bar.show_percentage = false
	_loading_bar.value = 15
	(_loading.find_child("Sub", true, false) as Label).get_parent().add_child(_loading_bar)


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
	panel.mouse_entered.connect(func(): _hover_slot = index)
	panel.mouse_exited.connect(func(): if _hover_slot == index: _hover_slot = -1)
	_slot_panels[index] = panel
	var icon := Panel.new()
	icon.name = "Icon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(icon)
	# The item's picture (feedback F17, pictures by Claude 2). Without one, the colored square shows.
	var pic := TextureRect.new()
	pic.name = "Pic"
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(pic)
	var short := _label(panel, 15)
	short.name = "Short"
	short.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var count := _label(panel, 14)
	count.name = "Count"
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if key != "":
		_add_key_plate(panel, key)
	_size_slot(panel, SLOT_SIZE)
	return panel


## The key number sits on a small dark plate on the slot's top rim (F227), not squeezed in a corner.
## Only hotbar slots have one (bag slots have no key, owner F242).
func _add_key_plate(panel: Control, key: String) -> void:
	var badge := Panel.new()
	badge.name = "KeyBadge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(0.11, 0.07, 0.05)
	bs.border_color = Color(0.62, 0.45, 0.24)
	bs.set_border_width_all(2)
	bs.set_corner_radius_all(7)
	badge.add_theme_stylebox_override("panel", bs)
	panel.add_child(badge)
	var k := _label(badge, 11)
	k.name = "Key"
	k.text = key
	k.add_theme_color_override("font_color", UiKit.AMBER)
	k.add_theme_font_override("font", UiKit.heading_font())
	k.add_theme_constant_override("outline_size", 0)
	k.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	k.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	k.set_anchors_preset(Control.PRESET_FULL_RECT)


## Sizes a slot and everything in it. The picture stays inside the painted frame (owner, Nov 17:
## "the items are going over the borders").
func _size_slot(panel: Control, s: float) -> void:
	panel.custom_minimum_size = Vector2(s, s)
	panel.size = Vector2(s, s)
	var inset := roundf(s * 0.17)  # the frame's rim
	var icon: Control = panel.get_node("Icon")
	icon.position = Vector2(inset + 3, inset + 3)
	icon.size = Vector2(s - 2 * inset - 6, s - 2 * inset - 6)
	var pic: Control = panel.get_node("Pic")
	pic.position = Vector2(inset, inset)
	pic.size = Vector2(s - 2 * inset, s - 2 * inset)
	var f := s / SLOT_SIZE
	var short: Label = panel.get_node("Short")
	short.add_theme_font_size_override("font_size", roundi(15 * f))
	short.position = Vector2(0, s * 0.3)
	short.size = Vector2(s, 20 * f)
	# How many you have: big, bright and outlined, in the bottom-right inside the frame (F227).
	var count: Label = panel.get_node("Count")
	var cf := roundi(s * 0.27)
	count.add_theme_font_size_override("font_size", cf)
	count.add_theme_constant_override("outline_size", roundi(s * 0.08))
	count.add_theme_color_override("font_color", Color(1, 0.97, 0.9))
	count.size = Vector2(s - inset, cf * 1.3)
	count.position = Vector2(0, s - inset * 0.55 - cf * 1.3)
	# Key plate: centred on the top rim, so it never covers the item or the count.
	if not panel.has_node("KeyBadge"):
		return
	var badge: Control = panel.get_node("KeyBadge")
	var bh := roundf(s * 0.26)
	badge.size = Vector2(roundf(bh * 1.25), bh)
	badge.position = Vector2(roundf((s - badge.size.x) * 0.5), roundf(-bh * 0.35))
	var k: Label = badge.get_node("Key")
	k.add_theme_font_size_override("font_size", roundi(bh * 0.72))


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
	var pack_open := ps.inventory.pack_open()
	if _pack_title:
		_pack_title.text = "Backpack" if pack_open else "Backpack  (wear a Leather Satchel to open these)"
		_equip_title.text = "Equipped\narmor: %d%%\nF: draw weapon" % roundi(ps.armor_cut() * 100.0)
	var hand := ps.hand_slot()
	for key in _slot_panels:
		var i: int = key
		var panel: Panel = _slot_panels[i]
		if Inventory.is_pack_index(i):
			panel.modulate.a = 1.0 if pack_open else 0.35
		var s := ps.inventory.get_slot(i)
		var selected: bool = i == ps.selected_slot or (i == hand and Inventory.is_equip_index(i))
		var swap_pick := i == _swap_from
		panel.add_theme_stylebox_override("panel", UiKit.style("slot_selected" if selected or swap_pick else "slot"))
		var icon: Panel = panel.get_node("Icon")
		var pic: TextureRect = panel.get_node("Pic")
		var tex: Texture2D = null if s.is_empty() else Items.icon(s.id)
		if s.is_empty() and Inventory.is_equip_index(i):
			tex = _slot_outline(Inventory.EQUIP[i - Inventory.EQUIP_START])  # faint "pickaxe goes here" (Claude 2)
		pic.texture = tex
		icon.visible = not s.is_empty() and tex == null
		if not s.is_empty():
			icon.add_theme_stylebox_override("panel", _slot_style(Items.color(s.id).darkened(0.15), Items.color(s.id).lightened(0.3)))
			panel.tooltip_text = Upgrades.display_name(s)  # "Copper Sword +2"
		(panel.get_node("Short") as Label).text = "" if s.is_empty() or tex != null else Items.short_label(s.id)
		(panel.get_node("Count") as Label).text = "" if s.is_empty() or s.count <= 1 else str(s.count)


func _on_slot_input(event: InputEvent, index: int) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	if not _bag_panel.visible:
		return
	var auth := GameAuthority.instance
	# Fewer clicks (owner F187): right-click splits a stack, Shift+Click moves it straight across,
	# double-click equips / takes off.
	if event.button_index == MOUSE_BUTTON_RIGHT:
		auth.ask_split(index)
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.double_click and not box_panel.visible:
		_swap_from = -1
		_quick_equip(index)
		_refresh_slots()
		return
	if event.shift_pressed and not box_panel.visible:
		_swap_from = -1
		if Inventory.is_equip_index(index):
			_quick_equip(index)  # take it off into the bag
		else:
			auth.ask_quick_move(index)
		_refresh_slots()
		return
	if _swap_from >= 0 and not box_panel.visible:
		var inv: Inventory = GameAuthority.instance.get_player(peer_id).inventory
		if _swap_from != index and not inv.swap_allowed(_swap_from, index):
			show_toast("That doesn't go in that slot (or the backpack isn't empty).", 2.5)
			_swap_from = -1
			_refresh_slots()
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


static var _outlines := {}


static func _slot_outline(slot_name: String) -> Texture2D:
	if not _outlines.has(slot_name):
		var path := "res://assets/icons/slot_%s.png" % slot_name
		_outlines[slot_name] = load(path) if ResourceLoader.exists(path) else null
	return _outlines[slot_name]


## Double-click: equip an item into its slot (swapping out what was there), or take an
## equipped item off into the first free bag slot.
func _quick_equip(index: int) -> void:
	var auth := GameAuthority.instance
	var inv: Inventory = auth.get_player(peer_id).inventory
	var s := inv.get_slot(index)
	if s.is_empty():
		return
	if Inventory.is_equip_index(index):
		for i in Inventory.SIZE:
			if inv.get_slot(i).is_empty():
				if inv.swap_allowed(index, i):
					auth.ask_swap(index, i)
				else:
					show_toast("Empty the backpack first.", 2.5)
				return
		show_toast("No room in the bag to take that off.", 2.5)
		return
	var where := Inventory.equip_slot_for(s.id)
	if where == "":
		show_toast("%s can't be equipped." % Items.display_name(s.id), 2.0)
		return
	var target := Inventory.equip_index(where)
	if inv.swap_allowed(index, target):
		auth.ask_swap(index, target)
	else:
		show_toast("Empty the backpack first.", 2.5)


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


## "What do I do now?" for the first minutes of a new game (feedback F11).
## One line at the top of the screen that changes as you go, then disappears.
var _steps_label: Label
var _steps_done := false


func _update_first_steps(ps: GameAuthority.PlayerState, has_lantern: bool) -> void:
	if _steps_done:
		return
	if _steps_label == null:
		_steps_label = Label.new()
		_steps_label.add_theme_font_size_override("font_size", 20)
		_steps_label.add_theme_color_override("font_outline_color", Color.BLACK)
		_steps_label.add_theme_constant_override("outline_size", 6)
		_steps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_steps_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		# Centered, below the top corner texts, wrapping onto a second line if it's long.
		_steps_label.anchor_left = 0.5
		_steps_label.anchor_right = 0.5
		_steps_label.offset_left = -360
		_steps_label.offset_right = 360
		_steps_label.offset_top = 120
		add_child(_steps_label)
	var inv := ps.inventory
	var has_pick := inv.count_of("pickaxe_stone") + inv.count_of("pickaxe_copper") + inv.count_of("pickaxe_silver") > 0
	var t := ""
	if not has_pick and (inv.count_of("stone") < 3 or inv.count_of("rootwood") < 2):
		t = "Pick up the loose rocks (walk over them) and pull down the hanging roots (click them)."
	elif not has_pick:
		t = "Press Tab and make a Stone Pickaxe."
	elif not has_lantern and inv.count_of("crystal_blue") < 1:
		t = "Grab the little glow crystal on the floor, then make a Lantern (Tab)."
	elif not has_lantern:
		t = "Press Tab and make a Lantern."
	elif _in_start_room() and get_tree().root.find_child("Peephole", true, false) != null:
		t = "Something glows through that little hole… Dig through the soft wall (hold left click)."
	else:
		_steps_done = true
	_steps_label.text = t
	_steps_label.visible = t != ""


func _in_start_room() -> bool:
	var me := _local_dwarf()
	var st: Dictionary = GameAuthority.instance.world.maker.start
	if me == null or st.is_empty():
		return false
	return me.global_position.distance_to(st.room_c) < CaveMaker.START_ROOM_R.x + 1.5


func show_toast(text: String, seconds: float = 2.5) -> void:
	_toast.text = text
	_toast_timer = seconds


## 0..1: how much of the cave around you is ready.
func set_loading_progress(f: float) -> void:
	if _loading_bar:
		_loading_bar.value = maxf(_loading_bar.value, clampf(f, 0.0, 1.0) * 100.0)


func set_loading(on: bool, text: String = "") -> void:
	_loading.visible = on
	if text != "":
		(_loading.find_child("Sub", true, false) as Label).text = text


func is_bag_open() -> bool:
	return _bag_panel.visible


## The bag and the panel beside it (crafting list or a chest) sit side by side as one group, centred on
## the screen, never overlapping (owner, Nov 16: "not centred, overlap"). Alone, each is centred.
func _layout_panels() -> void:
	var screen: Vector2 = _bag_panel.get_parent().size
	var side: Control = craft if craft.visible else (box_panel if box_panel.visible else null)
	var gap := 16.0
	var panels: Array[Control] = []
	if craft.upgrade_panel and craft.upgrade_panel.visible:
		panels.append(craft.upgrade_panel)  # gear upgrades: left of the bag (owner F178)
	if _bag_panel.visible:
		panels.append(_bag_panel)
	if side:
		panels.append(side)
	var total := -gap
	var tallest := 0.0
	for p in panels:
		total += p.size.x + gap
		tallest = maxf(tallest, p.size.y)
	var x := maxf(10.0, (screen.x - total) * 0.5)
	var top := maxf(10.0, (screen.y - tallest) * 0.5 - 30.0)  # a little above the middle, clear of the hotbar
	# The hotbar and body bars stay on screen under the bag (owner F241): never cover them.
	var free_bottom := screen.y - (HOTBAR_SLOT + 18.0 + 14.0 + 60.0 + 10.0)
	if top + tallest > free_bottom:
		top = maxf(10.0, free_bottom - tallest)
	for p in panels:
		p.position = Vector2(x, top)
		x += p.size.x + gap


## The hotbar at the bottom middle of the screen.
func _place_hotbar() -> void:
	# Pinned to the bottom middle by its anchors, so it stays centred at any window size (F152).
	# Bigger than the bag's slots while it's on its own (owner, Nov 17: "needs to be a lot larger").
	_size_hotbar(HOTBAR_SLOT)
	var w := float((HOTBAR_SLOT + 6) * Inventory.HOTBAR_SIZE - 6)
	_hotbar.anchor_left = 0.5
	_hotbar.anchor_right = 0.5
	_hotbar.anchor_top = 1.0
	_hotbar.anchor_bottom = 1.0
	_hotbar.offset_left = -w * 0.5
	_hotbar.offset_right = w * 0.5
	_hotbar.offset_top = -HOTBAR_SLOT - 18.0
	_hotbar.offset_bottom = -18.0


## Body bars: exactly as wide as the hotbar, right above it (clear of the key plates);
## the dials sit to the hotbar's left, level with it (owner F240).
func _place_vitals() -> void:
	var w := float((HOTBAR_SLOT + 6) * Inventory.HOTBAR_SIZE - 6)
	for c in [_vitals, _dials]:
		c.anchor_left = 0.5
		c.anchor_right = 0.5
		c.anchor_top = 1.0
		c.anchor_bottom = 1.0
	_vitals.offset_left = -w * 0.5
	_vitals.offset_right = w * 0.5
	_vitals.offset_bottom = -HOTBAR_SLOT - 18.0 - 14.0
	_vitals.offset_top = _vitals.offset_bottom - 60.0
	var dw := DIAL_SIZE * 2.0 + 10.0
	_dials.offset_right = -w * 0.5 - 16.0
	_dials.offset_left = _dials.offset_right - dw
	_dials.offset_bottom = -18.0 - (HOTBAR_SLOT - DIAL_SIZE) * 0.5
	_dials.offset_top = _dials.offset_bottom - DIAL_SIZE


func _size_hotbar(s: float) -> void:
	for i in Inventory.HOTBAR_SIZE:
		if _slot_panels.has(i):
			_size_slot(_slot_panels[i], s)


## Always false now: the hotbar stays at the bottom of the screen (owner F241).
func is_hotbar_in_bag() -> bool:
	return false


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


func is_dev_menu_open() -> bool:
	return dev_menu.visible


func set_dev_menu_open(open: bool) -> void:
	dev_menu.mode = build_mode
	dev_menu.visible = open
	if open:
		dev_menu.refresh()


## The Builder's Chest open right now (the box panel showing a build site's chest), or -1.
func open_builder_chest() -> int:
	if not is_bag_open() or not box_panel.visible or box_panel.box_id < 0:
		return -1
	var auth := GameAuthority.instance
	return box_panel.box_id if auth and auth.builder.sites.has(box_panel.box_id) else -1


func is_blueprints_open() -> bool:
	return blueprint_menu.visible


func set_blueprints_open(open: bool) -> void:
	blueprint_menu.mode = build_mode
	blueprint_menu.peer_id = peer_id
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


func is_paused() -> bool:
	return _pause.visible


func set_paused(on: bool) -> void:
	_pause.visible = on
	# Alone in your world, the pause screen really stops the game: monsters, falling, hunger,
	# time (F239). With friends in it, the world keeps going for them.
	get_tree().paused = on and multiplayer.get_peers().is_empty()
	var auth := GameAuthority.instance
	var host := auth == null or auth.is_host()
	var box: VBoxContainer = _pause.find_child("PauseButtons", true, false)
	# A friend in someone else's game can't save it, so they get "Leave" instead.
	(box.get_node("save") as Button).visible = host
	(box.get_node("menu") as Button).text = "Save & Quit to Menu" if host else "Leave the Game"
	(box.get_node("quit") as Button).text = "Quit Game"
	var ff: CheckButton = _pause.find_child("FriendlyFire", true, false)
	ff.visible = auth != null and host
	if auth:
		ff.set_pressed_no_signal(auth.friendly_fire())
	(_pause.find_child("Sub", true, false) as Label).text = "Cave seed: %s  ·  Esc or click outside to keep digging" % seed_text


## The Escape screen (F87, look F187): the Paused panel (Resume, Save, Invite Friends, Save & Quit to
## Menu, Quit Game) with the Settings panel beside it, over the dimmed game.
func _build_pause(root: Control) -> Control:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.04, 0.72)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.visible = false
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE  # a click outside the panels resumes (main.gd)
	root.add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(center)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(row)
	var paused := PanelContainer.new()
	UiKit.panel(paused)
	paused.custom_minimum_size = Vector2(340, 0)
	row.add_child(paused)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	paused.add_child(v)
	UiKit.title(v, "Paused")
	var box := VBoxContainer.new()
	box.name = "PauseButtons"
	box.add_theme_constant_override("separation", 8)
	v.add_child(box)
	for b in [["resume", "Resume"], ["save", "Save"], ["invite", "Invite Friends"], ["menu", "Save & Quit to Menu"], ["quit", "Quit Game"]]:
		var btn := Button.new()
		btn.name = b[0]
		btn.text = b[1]
		btn.custom_minimum_size = Vector2(0, 46)
		if b[0] == "resume":
			UiKit.gold_button(btn, 19)
		else:
			UiKit.dark_button(btn, 16)
		var what: String = b[0]
		btn.pressed.connect(func(): pause_pressed.emit(what))
		box.add_child(btn)
	var ff := CheckButton.new()
	ff.name = "FriendlyFire"
	ff.text = "Friendly fire (half damage)"
	ff.tooltip_text = "Your hits can hurt friends, at half damage."
	ff.focus_mode = Control.FOCUS_NONE
	ff.add_theme_color_override("font_color", UiKit.TEXT)
	ff.toggled.connect(func(on: bool): if GameAuthority.instance: GameAuthority.instance.set_friendly_fire(on))
	v.add_child(ff)
	var sub := UiKit.label(v, "", 13, UiKit.DIM)
	sub.name = "Sub"
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size = Vector2(290, 0)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(SettingsPanel.new())
	return bg


## By a Builder's Chest: a progress bar for the whole building. Hammer out = you're building it.
func _update_work_bar(auth: GameAuthority) -> void:
	var me := _local_dwarf()
	var site := auth.builder.work_site_for(me.global_position) if auth and auth.builder and me else -1
	_work_box.visible = site >= 0
	if site < 0:
		return
	var f := auth.builder.site_progress(site)
	var nm: String = auth.builder.sites[site].get("name", "Blueprint")
	_work_bar.value = f * 100.0
	var working := build_mode != null and build_mode.work_site == site
	var status := auth.builder.site_status(site)
	if working:
		_work_label.text = "Building %s: %d%%
%s" % [nm, roundi(f * 100.0), status]
	else:
		_work_label.text = "%s: %d%% built
Take out your Build Hammer here to build it (walk away to stop)." % [nm, roundi(f * 100.0)]


func _process(delta: float) -> void:
	var auth := GameAuthority.instance
	var ps: GameAuthority.PlayerState = auth.get_player(peer_id) if auth else null
	_update_work_bar(auth)
	_goals_wait -= delta
	if ps and _goals_wait <= 0.0:
		_goals_wait = 1.0
		var steps := Goals.next_steps(ps, auth)
		_goals_label.text = "" if steps.is_empty() else "Next steps
" + "
".join(steps.map(func(t): return "• " + t))
	# "Next steps" would run over any big panel (F187): hidden while one is open.
	_goals_label.visible = not (_bag_panel.visible or skills.visible or map_panel.visible or build_menu.visible or blueprint_menu.visible)
	if ps:
		var v := ps.vitals
		_bars.health.max_value = v.max_health()
		_bars.health.value = v.health
		_bars.stamina.max_value = v.max_stamina()
		_bars.stamina.value = v.stamina
		_bars.hunger.set_value(v.hunger)
		_bars.thirst.set_value(v.thirst)
		_health_text.text = "%d / %d" % [ceili(v.health), roundi(v.max_health())]
		var buffs := []
		for b in v.buffs:
			buffs.append("%s %d:%02d" % [Items.display_name(b.id), int(b.time_left) / 60, int(b.time_left) % 60])
		var mood: String = {"well_fed": "Well fed", "peckish": "Peckish", "starving": "Starving (tired)"}.get(v.status(), "")
		if v.cozy_time > 0.0:
			buffs.append("Cozy (comfort %d) %d:%02d" % [v.cozy_points, int(v.cozy_time) / 60, int(v.cozy_time) % 60])
		var slots: Array = ps.progress.ability_slots()
		for i in slots.size():  # active perks: which key, ready or recharging
			var cd: Dictionary = v.effects.get("cd_" + slots[i], {})
			buffs.append("%s %s %s" % [["Z", "G", "T"][i], Progression.PERKS[slots[i]][4], "%d s" % ceili(cd.left) if cd.has("left") else "ready"])
		for e in v.effects:
			if not e.begins_with("cd_") and Progression.PERKS.has(e) or e == "bond":
				buffs.append("%s %d s" % [Progression.PERKS[e][4] if Progression.PERKS.has(e) else "Bond of the Clan", ceili(v.effects[e].left)])
		_buff_label.text = "\n".join(([mood] if mood != "" else []) + buffs + Array(v.ailments.describe()))
		var p := ps.progress
		var best := Progression.SKILLS.duplicate()
		best.sort_custom(func(a, b): return p.skill_level[a] > p.skill_level[b])
		_level_label.text = "Level %d  (%d/%d XP)%s\n%s" % [
			p.level, p.xp, Progression.xp_to_next(p.level), "  · %d perk points" % p.points_free() if p.points_free() > 0 else "",
			" · ".join(best.slice(0, 3).map(func(s): return "%s %d" % [Progression.SKILL_INFO[s][0], p.skill_level[s]]))]
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
			_fuel_label.text = "Lantern is out!  Get a glow crystal or rootwood, press R"
		var has_lantern := Lantern.has_lantern(ps)
		_fuel_bar.visible = has_lantern
		if not has_lantern:
			_fuel_label.text = "No lantern yet"
		_update_first_steps(ps, has_lantern)
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
		# No names or hit counts for what you're aiming at (owner F134: other games don't; you find out by
		# digging it and reading it in your bag). Only what a key does: "E to open", "E to use"...
		if info.is_empty() or info.kind in ["rock", "glow"]:
			_aim_label.text = ""
		else:
			var nm: String = info.name
			_aim_label.text = nm.get_slice("· ", 1) if nm.contains("· ") else nm
	_fps_label.text = "%d FPS" % Engine.get_frames_per_second()
	_update_boss_bar(dwarf)
	if build_mode and build_mode.active() and build_mode.blueprint:
		_build_label.text = "Blueprint: %s (%s)\nQ turn · left click place (a blue build site) · right click or B: back to single pieces" % [build_mode.blueprint.name, BuildMenu._cost_text(build_mode.blueprint.cost())]
	elif build_mode and build_mode.active():
		var c := BuildMenu._cost_text(Pieces.cost(build_mode.piece, build_mode.family))
		_build_label.text = "Building: %s (%s)\nCost: %s%s%s\n\nB  choose another piece or material\nLeft click  place it\nQ  turn it\nShift + mouse wheel  raise / lower\nRight click  pick up (first 10 s)\nX  break it (80%% back)\nV  blueprints  ·  C  save your own" % [
			Pieces.LIST[build_mode.piece].name, Pieces.FAMILIES[build_mode.family].name, c,
			" (now %+.1f m)" % build_mode.lift if build_mode.lift != 0.0 else "",
			"" if build_mode.problem == "" else "\nCan't place: " + build_mode.problem]
		var aimed: Dictionary = auth.builder.structure.pieces.get(build_mode.aimed_uid, {}) if auth and auth.builder else {}
		if not aimed.is_empty():
			_build_label.text = "Aimed piece: %s\n\n" % steadiness_text(aimed) + _build_label.text
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


## Leaving the game (main menu, quitting) never leaves the world frozen (F239).
func _exit_tree() -> void:
	if _pause and _pause.visible and get_tree():
		get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fps"):
		_fps_label.visible = not _fps_label.visible
	# While the world is frozen the game's own input handler sleeps too, so the pause screen
	# answers Escape and "click outside" itself (F239).
	if get_tree().paused and _pause.visible:
		var click: bool = event is InputEventMouseButton and event.pressed
		if event.is_action_pressed("pause") or click:
			get_viewport().set_input_as_handled()
			pause_pressed.emit("resume")


## Bag open, mouse over a slot, press 1-9: that item goes to that hotbar slot (owner F155).
func _input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo or not _bag_panel.visible or box_panel.visible or _hover_slot < 0:
		return
	var n := hotbar_key(k.keycode)
	if n < 0 or n == _hover_slot:
		return
	var inv: Inventory = GameAuthority.instance.get_player(peer_id).inventory if GameAuthority.instance else null
	if inv and inv.swap_allowed(_hover_slot, n):
		GameAuthority.instance.ask_swap(_hover_slot, n)
		_refresh_slots.call_deferred()
	get_viewport().set_input_as_handled()


## Which hotbar slot a number key means (1 = slot 0 ... 9 = slot 8), or -1.
static func hotbar_key(code: int) -> int:
	if code >= KEY_1 and code <= KEY_9:
		return code - KEY_1
	return -1


## "rock-steady", "85% steady", "shaky (31%)": how well a built piece is held up.
static func steadiness_text(p: Dictionary) -> String:
	if p.get("anchored", false):
		return "rock-steady (on rock or a foundation)"
	var pct := roundi(float(p.get("stability", 0.0)) * 100.0)
	if pct < 25:
		return "shaky! (%d%%) prop it up" % pct
	return "%d%% steady" % pct
