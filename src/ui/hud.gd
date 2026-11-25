class_name Hud
extends CanvasLayer
## Everything drawn on top of the game: crosshair, what you're aiming at,
## dig progress, the hotbar (Item Bar), the bag, lantern fuel, frame rate, pause screen.

const SLOT_SIZE := 58
## Frost edge strength for 1..5 chill stacks (owner, Nov 23 round 7): small start, 3 stacks = the look he liked,
## 4 and 5 only a little more, so even 5 never covers too much of the screen.
const CHILL_EDGE_BY_STACK := [0.15, 0.35, 0.6, 0.68, 0.76]
const HOTBAR_SLOT := 88  ## the item bar at the bottom of the screen is bigger than the bag's slots
const SKILLS_HOTBAR_ROOM := 125.0  ## the K window stays above the hotbar (owner, Nov 20)
const BAG_HINT := "Click: pick up / swap  ·  Shift+Click: quick move  ·  Right-click: put on / take off, eat, split  ·  Q: throw away"
const GEAR_SLOT := 80  ## the Gear panel's slots are bigger than the bag's (owner F825: "make the gear and icons bigger")
const GEAR_NAMES := {head = "Head", chest = "Chest", legs = "Legs", feet = "Feet", lantern = "Lantern", pack = "Backpack"}

## A button on the Escape menu was pressed: "resume", "save", "invite", "menu" or "quit" (F87).
signal pause_pressed(what: String)

var peer_id := 1
var seed_text := ""

var _aim_label: Label
var _hotbar: HBoxContainer
var _hotbar_home: Control  ## where the hotbar lives while playing (bottom of the screen)
var _bag_panel: PanelContainer
var _bag_grid: GridContainer
var _slot_panels := {}  ## inventory index -> its slot Panel (hotbar, bag, backpack, equipment)
var _pack_title: Label
var _equip_title: Label
var _gear_panel: PanelContainer  ## left of the bag: armour, lantern, backpack (owner F825)
var _gear_names := {}  ## gear slot index -> the Label beside it ("Copper Helm" or "Head")
const EQUIP_NAMES := ["Pick", "Lamp", "Weapon", "Shield", "Head", "Chest", "Legs", "Feet", "Pack"]
var _lantern_out: PanelContainer  ## "Press R to refill the lantern" while it's out (F870)
var skill_popup: SkillPopup  ## a skill pops up for ~2 s when it grows (F870)
var _fuel_label: Label
var _fps_label: Label
var first_cards := FirstCards.new()  ## picture cards the first time you meet something (F870); kept in Notes (J)
var _cards_wait := 0.0
var _toast: Label
var _toast_timer := 0.0
var _pause: Control
var _loading: Control
var _loading_bar: ProgressBar
var _swap_from := -1
var _hover_slot := -1  ## the bag slot under the mouse (for "press 1-9 to put it on the hotbar", F155)
const VITAL_BAR_H := [38.0, 30.0]  ## health and stamina bar heights, frame included (F247)
const STUN_BAR_H := 20.0  ## your stun meter's bar (chat 15)
var learned_cards: LearnedCards
var _bars := {}  ## "health"/"stamina" -> framed ProgressBar, "hunger"/"thirst" -> VitalDial (F229)
var _vitals: VBoxContainer  ## health + stamina bars above the hotbar
var _dials: HBoxContainer  ## hunger + thirst dials left of the hotbar
const DIAL_SIZE := 72
const VitalDialScript := preload("res://src/ui/vital_dial.gd")
const WeightDialScript := preload("res://src/ui/weight_dial.gd")
var _health_text: Label
var _stamina_text: Label  ## "80 / 100" in the middle of the stamina bar (owner F823)
var _buff_label: Label
var _ailment_badges: AilmentBadges  ## burning / chilled / poisoned / frozen, above the health bar
var _weight_dial: Control  ## carry weight dial above hunger + thirst: green / yellow heavy / red overloaded (F793)
var _bag_weight: Label  ## "Weight 142 / 200" under the Bag title (F793)
var _food_slots: FoodSlots  ## the eaten foods + drink as pictures with a ring, right of the health bar (F426)
var _edge_flash: ScreenEdgeFlash  ## red flash on a hit, green/orange/blue glow while poisoned/burning/chilled (F695)
var edge_fake := ""  ## dev: show this status look at the screen edges without any ailment ("" = off)
var _edge_flash_vitals: Vitals  ## whose "damaged" signal _edge_flash is listening to right now
## Ghost health bar (F695, owner Nov 22): a pale strip behind the red fill shows the health you just
## lost, waits a moment, then drains down to the real value. Uses real time, so hit-stop can't freeze it.
var _ghost_bar: ProgressBar
var _ghost_hold_until := 0  ## Time.get_ticks_msec() when the pale strip starts draining
var _ghost_last_ms := 0
const GHOST_HOLD_MS := 600
const GHOST_DRAIN := 8.0  ## how fast it catches up once draining (about 0.4 s)
var craft: CraftPanel
var skills: SkillsPanel
var map_panel: MapPanel
var build_menu: BuildMenu
var blueprint_menu: BlueprintMenu
var dev_menu: DevMenu  ## P in dev builds
var _work_box: VBoxContainer  ## by a Builder's Chest: what's being built, how far along (owner, Nov 16)
var _work_label: Label
var _work_bar: ProgressBar
var _reload_box: PanelContainer  ## crossbow reload bar under the crosshair (owner, Nov 20; framed, no word: F573)
var _reload_fill: StyleBoxFlat
var _reload_done := 0.0  ## seconds the full bar still flashes gold after the bolt is in
const RELOAD_W := 220.0
const RELOAD_H := 30.0
const RELOAD_COLOR := Color(0.55, 0.68, 0.82)  ## steel blue while it winds
const RELOAD_DONE_COLOR := Color(1.0, 0.82, 0.3)  ## gold flash: loaded
var _reload_bar: ProgressBar
var box_panel: BoxPanel
var build_mode: BuildMode
var _build_label: Label
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

	_edge_flash = ScreenEdgeFlash.new()
	root.add_child(_edge_flash)

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


	# Crossbow reloading: a bar in the middle of the screen, under the crosshair (owner, Nov 20). Owner F573 (Nov 21):
	# no Reloading word and a much better bar: now a thick bar in the hotbar's wood-and-brass frame, a steel-blue fill
	# with a shine on top, that flashes gold for a moment when the bolt is in.
	_reload_box = PanelContainer.new()
	_reload_box.name = "ReloadFrame"
	_reload_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reload_box.add_theme_stylebox_override("panel", UiKit.style("slot", 6.0, 8.0))
	_reload_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_reload_box.custom_minimum_size = Vector2(RELOAD_W, RELOAD_H)
	_reload_box.position += Vector2(-RELOAD_W * 0.5, 64)
	_reload_box.visible = false
	root.add_child(_reload_box)
	_reload_bar = ProgressBar.new()
	_reload_bar.name = "Reload"
	_reload_bar.custom_minimum_size = Vector2(0, RELOAD_H - 12.0)
	_reload_bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_reload_bar.show_percentage = false
	_reload_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rback := StyleBoxFlat.new()
	rback.bg_color = Color(0.07, 0.045, 0.03, 0.92)
	rback.set_corner_radius_all(3)
	_reload_bar.add_theme_stylebox_override("background", rback)
	_reload_fill = StyleBoxFlat.new()
	_reload_fill.bg_color = RELOAD_COLOR
	_reload_fill.set_corner_radius_all(3)
	_reload_fill.border_width_top = 3
	_reload_fill.border_color = RELOAD_COLOR.lightened(0.35)
	_reload_fill.border_width_bottom = 2
	_reload_fill.border_blend = true
	_reload_bar.add_theme_stylebox_override("fill", _reload_fill)
	_reload_box.add_child(_reload_bar)

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
	_bag_weight = UiKit.label(bag_outer, "", 16)
	_bag_weight.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Gear on its own panel on the left, the bag in the middle, crafting on the right (owner F825).
	var bag_box := VBoxContainer.new()
	bag_outer.add_child(bag_box)
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
	_build_gear_panel(root)
	# One short hint line, no long explanations (owner F179, F187).
	UiKit.divider(bag_outer)
	var hint := UiKit.label(bag_outer, BAG_HINT, 13, UiKit.DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Centred in the space left of the crafting list (it sits on the right), so they never overlap.
	_bag_panel.resized.connect(_layout_panels)
	root.resized.connect(_layout_panels)
	_bag_panel.visibility_changed.connect(_layout_panels)
	_bag_panel.visibility_changed.connect(func(): _gear_panel.visible = _bag_panel.visible)

	var fuel_box := VBoxContainer.new()
	fuel_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	fuel_box.position += Vector2(20, -170)  # above the hunger/thirst dials (F240)
	root.add_child(fuel_box)
	_fuel_label = _label(fuel_box, 15)  # only the crossbow's bolts now (F870: no lantern bar)
	# F870 (owner, Nov 25): no lantern bar; one simple pop-up when the lantern runs out.
	_lantern_out = PanelContainer.new()
	_lantern_out.name = "LanternOut"
	UiKit.panel(_lantern_out, 18.0)
	_lantern_out.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lantern_out.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_lantern_out.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_lantern_out.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_lantern_out.offset_bottom = -300.0
	_lantern_out.visible = false
	root.add_child(_lantern_out)
	UiKit.label(_lantern_out, "Press %s to refill the lantern" % Controls.key_name("refill_lantern"), 17, UiKit.TEXT)
	skill_popup = SkillPopup.new()  # F870: a skill shows for ~2 s only when it grows
	skill_popup.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	skill_popup.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	skill_popup.position += Vector2(-16, 36)
	root.add_child(skill_popup)

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
	_weight_dial = WeightDialScript.new()
	_weight_dial.name = "WeightDial"
	root.add_child(_weight_dial)
	var stack := _vitals
	_ailment_badges = AilmentBadges.new()
	_ailment_badges.name = "AilmentBadges"
	root.add_child(_ailment_badges)
	_food_slots = FoodSlots.new()
	_food_slots.name = "FoodSlots"
	root.add_child(_food_slots)
	# F247 (owner, Nov 19): the old slider look stretched into a thin strip with the number on its top edge.
	# Now each bar sits in the hotbar slots' wood-and-brass frame, a thick fill inside, the number in the middle.
	# (+ your stun meter, owner chat 15: a thin purple bar, shown only while it has stun in it)
	for b in [["health", Color(0.86, 0.2, 0.16), VITAL_BAR_H[0]], ["stamina", Color(0.93, 0.74, 0.26), VITAL_BAR_H[1]],
			["stun", Color(0.62, 0.42, 0.86), STUN_BAR_H]]:
		var frame := PanelContainer.new()
		frame.name = b[0].capitalize() + "Frame"
		frame.custom_minimum_size = Vector2(0, b[2])
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_theme_stylebox_override("panel", UiKit.style("slot", 6.0, 8.0))
		stack.add_child(frame)
		var pb := ProgressBar.new()
		pb.name = b[0].capitalize()
		pb.custom_minimum_size = Vector2(0, b[2] - 12.0)  # fills the frame's inside (it shrank to 5 px)
		pb.size_flags_vertical = Control.SIZE_EXPAND_FILL
		pb.show_percentage = false
		pb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var back := StyleBoxFlat.new()
		back.bg_color = Color(0.07, 0.045, 0.03, 0.9)
		back.set_corner_radius_all(3)
		pb.add_theme_stylebox_override("background", back)
		var bar_fill := StyleBoxFlat.new()
		bar_fill.bg_color = b[1]
		bar_fill.set_corner_radius_all(3)
		bar_fill.border_width_top = 3  # a lighter top edge: a bit of shine, so it reads as a filled tube
		bar_fill.border_color = b[1].lightened(0.3)
		bar_fill.border_width_bottom = 2
		bar_fill.border_blend = true
		pb.add_theme_stylebox_override("fill", bar_fill)
		frame.add_child(pb)
		_bars[b[0]] = pb
	_vitals.move_child(_bars.stun.get_parent(), 0)  # (the stun meter above the health bar)
	# The ghost bar sits under the red fill and takes over its dark background (F695).
	_ghost_bar = ProgressBar.new()
	_ghost_bar.name = "HealthGhost"
	_ghost_bar.show_percentage = false
	_ghost_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ghost_bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ghost_bar.add_theme_stylebox_override("background", _bars.health.get_theme_stylebox("background"))
	var ghost_fill := StyleBoxFlat.new()
	ghost_fill.bg_color = Color(0.95, 0.82, 0.62, 0.85)
	ghost_fill.set_corner_radius_all(3)
	_ghost_bar.add_theme_stylebox_override("fill", ghost_fill)
	_bars.health.add_theme_stylebox_override("background", StyleBoxEmpty.new())
	_bars.health.get_parent().add_child(_ghost_bar)
	_bars.health.get_parent().move_child(_ghost_bar, 0)
	_bars.stun.get_parent().visible = false
	_place_vitals()
	_health_text = _label(_bars.health.get_parent(), 17)  # over the bar, centred both ways inside the frame
	_health_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_health_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_stamina_text = _label(_bars.stamina.get_parent(), 14)  # same as health, a bit smaller for the thinner bar (F823)
	_stamina_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stamina_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Moods, food buffs and ailments: small text in the bottom-left, above the lantern.
	_buff_label = _label(root, 13)
	_buff_label.anchor_top = 1.0
	_buff_label.anchor_bottom = 1.0
	_buff_label.offset_left = 20
	_buff_label.offset_top = -300
	_buff_label.offset_bottom = -178
	_buff_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM

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
	# F435/F445 (owner, Nov 20: "a lot bigger", then "blurry" and "it shouldn't go over the hotbar"): the window is
	# rebuilt at the screen's size (sharp letters, never stretched) and sits in the space above the hotbar.
	var fit_skills := func() -> void:
		var above := root.size.y - SKILLS_HOTBAR_ROOM
		skills.set_ui(clampf(minf(root.size.x * 0.94 / 1350.0, above / 840.0), 0.8, 3.0))
		skills.position = Vector2((root.size.x - skills.size.x) * 0.5, maxf(8.0, (above - skills.size.y) * 0.5))
	skills.resized.connect(fit_skills)
	root.resized.connect(fit_skills)
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
	# F709: a wide bar along the bottom, so the green preview stays visible above it.
	var place_build_menu := func(): build_menu.position = Vector2((root.size.x - build_menu.size.x) * 0.5,
		maxf(8.0, root.size.y - build_menu.size.y - 12.0))
	build_menu.resized.connect(place_build_menu)
	root.resized.connect(place_build_menu)
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

	_fps_label = _label(root, 15)
	_fps_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_fps_label.position += Vector2(-130, 10)
	# (F870: no "Next steps" goal text: the world and the first-time cards teach instead)

	learned_cards = LearnedCards.new()  # "Recipe learned" cards on the left (owner, Nov 19)
	root.add_child(learned_cards)
	_toast = _label(root, 20)
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast.position += Vector2(-250, 80)
	_toast.custom_minimum_size = Vector2(500, 0)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# (F870: the controls list lives only in the settings page now, SettingsPanel.CONTROLS)

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


## The Gear panel (owner F825, Nov 23): armour on the left column, lantern and backpack on the right, big slots
## with the item's name beside each. Pickaxe, weapon and shield aren't here: they're worn where they lie (gold E).
func _build_gear_panel(root: Control) -> void:
	_gear_panel = PanelContainer.new()
	_gear_panel.visible = false
	UiKit.panel(_gear_panel)
	root.add_child(_gear_panel)
	_gear_panel.resized.connect(_layout_panels)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_gear_panel.add_child(box)
	UiKit.title(box, "Gear")
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 14)
	box.add_child(cols)
	for group in [["head", "chest", "legs", "feet"], ["lantern", "pack"]]:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 8)
		cols.add_child(col)
		for part in group:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			col.add_child(row)
			var i := Inventory.equip_index(part)
			var slot := _make_slot(i, "")
			_size_slot(slot, GEAR_SLOT)
			row.add_child(slot)
			var name_l := UiKit.label(row, GEAR_NAMES[part], 15)
			name_l.custom_minimum_size = Vector2(96, 0)
			name_l.autowrap_mode = TextServer.AUTOWRAP_WORD
			name_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			_gear_names[i] = name_l
	UiKit.divider(box)
	_equip_title = UiKit.label(box, "", 16)


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
	var panel := ItemTipSlot.new()  # (a framed, coloured hover tip, F831)
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
		_equip_title.text = "Armour: %d%%\nF: draw your worn weapon" % roundi(ps.armor_cut() * 100.0)
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
			panel.tooltip_text = "[b]%s[/b]" % Upgrades.display_name(s)  # "Copper Sword +2" (BBCode: ItemTipSlot, F831)
			var kind_line := Combat.type_text(s.id)  # F831: "Blunt · one hand"
			if kind_line != "":
				panel.tooltip_text += "\n" + kind_line
			var each := ItemWeights.weight(s.id)  # F793: what it weighs
			if each > 0.0:
				panel.tooltip_text += "\nWeight %s%s" % [ItemWeights.pretty(each * int(s.count)),
						" (%s each)" % ItemWeights.pretty(each) if int(s.count) > 1 else ""]
			var hits := Combat.damage_text(s)  # (owner F571: weapons show their damage)
			if hits != "":
				panel.tooltip_text += "
" + hits
			if Durability.wears(s.id):
				panel.tooltip_text += "\n" + Durability.status_text(s)
			if Items.kind(s.id) == "lantern":
				panel.tooltip_text += "\n" + Lantern.tip(s.id)  # F562: which one frees your hands
			if Items.kind(s.id) == "page":
				panel.tooltip_text += "\nRight-click to read it."
			elif Foods.is_buff_food(s.id):  # healing hearts first, then the other effects (owner, Nov 19)
				var halves := Foods.heart_halves(Foods.buff_of(s.id).get("regen", 0.0))
				if halves > 0:
					panel.tooltip_text += "\n• Healing " + ("½♥" if halves == 1 else "♥".repeat(halves / 2) + ("½" if halves % 2 else ""))
				for line in Foods.effect_lines(s.id):
					panel.tooltip_text += "\n• " + line
		(panel.get_node("Short") as Label).text = "" if s.is_empty() or tex != null else Items.short_label(s.id)
		(panel.get_node("Count") as Label).text = "" if s.is_empty() or s.count <= 1 else str(s.count)
		_show_wear(panel, s)
		_show_cooldown(panel, s, auth)
		_show_worn_badge(panel, s.get("worn", false))
		if _gear_names.has(i):
			var part: String = Inventory.EQUIP[i - Inventory.EQUIP_START]
			(_gear_names[i] as Label).text = GEAR_NAMES[part] if s.is_empty() else Upgrades.display_name(s)
			(_gear_names[i] as Label).add_theme_color_override("font_color", UiKit.DIM if s.is_empty() else UiKit.TEXT)


## An item that is cooling down (a bandage: 30 s) gets a dark shade over its slot. Right after you use it, the shade
## covers the whole slot; then its edge climbs from the bottom to the top, and when it's gone you can use it again
## (owner F470). Owner F570 (Nov 21: "barely visible, make it a lot more visible"): the shade is much darker, its edge
## is a bright gold line, and the seconds left count down big in the middle. Hotbar and bag both.
func _show_cooldown(panel: Control, s: Dictionary, auth: GameAuthority) -> void:
	var left := 0.0 if s.is_empty() or auth == null else auth.cooldown_left(s.id)
	var shade: ColorRect = panel.get_node_or_null("Cooldown")
	if left <= 0.0:
		if shade:
			shade.visible = false
			(panel.get_node("Secs") as Label).visible = false
		return
	if shade == null:
		shade = ColorRect.new()
		shade.name = "Cooldown"
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shade.color = COOLDOWN_SHADE
		panel.add_child(shade)
		var edge := ColorRect.new()
		edge.name = "Edge"
		edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		edge.color = COOLDOWN_EDGE
		shade.add_child(edge)
		var secs := Label.new()
		secs.name = "Secs"
		secs.mouse_filter = Control.MOUSE_FILTER_IGNORE
		secs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		secs.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		secs.add_theme_color_override("font_color", Color(1.0, 0.92, 0.6))
		secs.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.02))
		panel.add_child(secs)
		if panel.has_node("KeyBadge"):
			panel.move_child(shade, panel.get_node("KeyBadge").get_index())  # (the key number stays readable on top)
	shade.visible = true
	shade.position = Vector2(4, 4)
	shade.size = Vector2(panel.size.x - 8, cooldown_shade_height(panel.size.y - 8, left))
	var edge: ColorRect = shade.get_node("Edge")
	edge.position = Vector2(0, shade.size.y - 3)
	edge.size = Vector2(shade.size.x, 3)
	var secs: Label = panel.get_node("Secs")
	secs.visible = true
	secs.text = str(ceili(cooldown_seconds(auth, s.id)))
	secs.add_theme_font_size_override("font_size", roundi(panel.size.x * 0.36))
	secs.add_theme_constant_override("outline_size", roundi(panel.size.x * 0.09))
	secs.position = Vector2.ZERO
	secs.size = panel.size


const COOLDOWN_SHADE := Color(0.03, 0.03, 0.04, 0.86)  ## (was 0.68 grey: barely visible, F570)
const COOLDOWN_EDGE := Color(1.0, 0.8, 0.3)


## Seconds until an item's cooldown is over (0 when ready).
static func cooldown_seconds(auth: GameAuthority, item_id: String) -> float:
	var c: Dictionary = auth.my_cooldowns.get(item_id, {}) if auth else {}
	return 0.0 if c.is_empty() else maxf(0.0, float(c.until) - GameAuthority.now())


## How tall the grey cooldown shade is: it hangs from the slot's top and shrinks upward as the cooldown runs out.
static func cooldown_shade_height(inner: float, left: float) -> float:
	return roundf(inner * clampf(left, 0.0, 1.0))


## Durability (owner F504, said 2×: "the way it shows now isn't good"; they picked: under the tool, inside the slot's
## frame but not touching it). Every tool, weapon and piece of gear that wears shows a chunky bar under its picture,
## inside the frame's rim with a gap all round: a dark trough with a coloured fill (green -> yellow -> red), even when
## it's brand new. A broken one is greyed out and its trough shows empty.
func _show_wear(panel: Control, s: Dictionary) -> void:
	var bar: ColorRect = panel.get_node_or_null("Wear")
	var pic: TextureRect = panel.get_node("Pic")
	var wears := not s.is_empty() and Durability.wears(s.id)
	pic.modulate = Color(0.45, 0.4, 0.4) if not s.is_empty() and Durability.broken(s) else Color.WHITE
	if not wears:
		if bar:
			bar.visible = false
		return
	if bar == null:
		bar = ColorRect.new()  # the trough
		bar.name = "Wear"
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.color = Color(0.06, 0.04, 0.03, 0.92)
		panel.add_child(bar)
		var fill := ColorRect.new()
		fill.name = "Fill"
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.add_child(fill)
		if panel.has_node("KeyBadge"):
			panel.move_child(bar, panel.get_node("KeyBadge").get_index())
	var f := Durability.fraction(s)
	var r := wear_bar_rect(panel.size.x)
	bar.visible = true
	bar.position = r.position
	bar.size = r.size
	var fill: ColorRect = bar.get_node("Fill")
	fill.color = wear_color(f)
	fill.position = Vector2(1, 1)
	fill.size = Vector2(roundf((r.size.x - 2.0) * clampf(f, 0.0, 1.0)), r.size.y - 2.0)


## Where the durability bar sits in a slot `s` pixels wide: under the picture, inside the frame's rim, with a gap of
## WEAR_GAP from the rim on every side (never touching the frame).
const WEAR_GAP := 3.0
static func wear_bar_rect(s: float) -> Rect2:
	var inset := roundf(s * 0.17)  # (the frame's rim: _size_slot)
	var h := maxf(5.0, roundf(s * 0.085))
	return Rect2(Vector2(inset + WEAR_GAP, s - inset - WEAR_GAP - h), Vector2(s - 2.0 * (inset + WEAR_GAP), h))


static func wear_color(f: float) -> Color:
	return Color(0.9, 0.25, 0.2) if f < 0.25 else (Color(0.95, 0.78, 0.25) if f < 0.5 else Color(0.45, 0.85, 0.35))


func _on_slot_input(event: InputEvent, index: int) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	if not _bag_panel.visible:
		return
	var auth := GameAuthority.instance
	# Fewer clicks (owner F187): right-click equips / takes off anything you can wear or hold
	# (owner F23, Nov 17: "right-click a shield, it should go directly in its slot") and splits
	# other stacks; Shift+Click moves it straight across; double-click equips / takes off too.
	if event.button_index == MOUSE_BUTTON_RIGHT:
		_swap_from = -1
		if Items.kind(auth.get_player(peer_id).inventory.get_slot(index).get("id", "")) == "page":
			auth.ask_read(index)  # right-click an old page to read it (owner: "I cannot read the recipe")
			_refresh_slots()
		elif Items.kind(auth.get_player(peer_id).inventory.get_slot(index).get("id", "")) in ["food", "drink"]:
			auth.ask_eat(index)  # right-click a food or drink to eat it (owner F827)
			_refresh_slots()
		elif wants_equip_click(index, auth.get_player(peer_id).inventory):
			_quick_equip(index)
		else:
			auth.ask_split(index)
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.double_click and not box_panel.visible:
		_swap_from = -1
		_quick_equip(index)
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
	elif Inventory.is_equip_index(_swap_from) or Inventory.is_equip_index(index):
		GameAuthority.instance.ask_equip_move(_swap_from, index)  # into/out of a gear slot: the ring first (F828)
		_swap_from = -1
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


## Right-click equips (or takes off) instead of splitting: anything in an equipment slot, or
## any single item that has an equipment slot (shield, weapon, pickaxe, lantern, clothes, backpack).
static func wants_equip_click(index: int, inv: Inventory) -> bool:
	var s := inv.get_slot(index)
	if s.is_empty():
		return false
	return Inventory.is_equip_index(index) or Inventory.equip_slot_for(s.id) != ""


## Double-click / right-click: put an item on or take it off (a ring fills first, F826/F828).
## Says why right away when it can't (no room, backpack not empty), before asking the host.
func _quick_equip(index: int) -> void:
	var auth := GameAuthority.instance
	var inv: Inventory = auth.get_player(peer_id).inventory
	if inv.get_slot(index).is_empty():
		return
	var why := inv.equip_problem(index)
	if why != "":
		show_toast(why, 2.5)
		return
	auth.ask_equip(index)
	_refresh_slots()


func _on_dig_feedback(pid: int, result: Dictionary) -> void:
	if pid != peer_id:
		return
	match result.get("state", ""):
		"hit", "dug":
			pass  # (no progress bar on what you mine: owner F574, Nov 21. The cracks and chips show it.)
		"blocked":
			if result.get("why", "-") != "":  # "" = nothing to say (F552: a broken tree growing back)
				show_toast(result.get("why", "Too hard! This rock needs a better pickaxe."))
		"no_tool":
			show_toast("Pick your pickaxe in the hotbar (key 1).")


## F870: a picture card the first time you meet something new (unless "Hints and cards" is off in Settings).
func show_first_card(id: String) -> Control:
	if not FirstCards.hints_on:
		return null
	var c: Array = FirstCards.CARDS[id]
	return learned_cards.show_card("New note  (J)", c[0], FirstCards.picture(id), c[1])


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
	if _gear_panel and _gear_panel.visible:
		panels.append(_gear_panel)  # armour + lantern on the left (owner F825)
	if _bag_panel.visible:
		panels.append(_bag_panel)
	if side:
		panels.append(side)
	var total := -gap
	var tallest := 0.0
	for p in panels:
		total += p.size.x + gap
		tallest = maxf(tallest, p.size.y)
	# Gear + bag + crafting fill the screen (owner F825, Nov 23: "this needs to be a lot bigger"): all three grow
	# (or shrink on a small screen) the same, as wide as the screen and never down over the bars + hotbar.
	var room_h := screen.y - (HOTBAR_SLOT + 18.0 + 14.0 + 60.0 + 10.0) - 30.0
	var k := minf((screen.x - 40.0) / maxf(total, 1.0), room_h / maxf(tallest, 1.0))
	k = clampf(k, 0.5, 2.5)
	total *= k
	tallest *= k
	gap *= k
	var x := maxf(10.0, (screen.x - total) * 0.5)
	var top := maxf(10.0, (screen.y - tallest) * 0.5 - 30.0)  # a little above the middle, clear of the hotbar
	# The hotbar and body bars stay on screen under the bag (owner F241): never cover them.
	var free_bottom := screen.y - (HOTBAR_SLOT + 18.0 + 14.0 + 60.0 + 10.0)
	if top + tallest > free_bottom:
		top = maxf(10.0, free_bottom - tallest)
	for p in panels:
		p.scale = Vector2(k, k)
		p.position = Vector2(x, top)
		x += p.size.x * k + gap


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
	_vitals.offset_top = _vitals.offset_bottom - VITAL_BAR_H[0] - VITAL_BAR_H[1] - 4.0
	_vitals.grow_vertical = Control.GROW_DIRECTION_BEGIN  # (the stun bar, when it shows, goes on top: chat 15)
	if _ailment_badges:
		_ailment_badges.anchor_left = 0.5
		_ailment_badges.anchor_right = 0.5
		_ailment_badges.anchor_top = 1.0
		_ailment_badges.anchor_bottom = 1.0
		_ailment_badges.offset_left = -w * 0.5
		_ailment_badges.offset_right = w * 0.5
		_ailment_badges.offset_bottom = _vitals.offset_top - 6.0
		_ailment_badges.offset_top = _ailment_badges.offset_bottom - AilmentBadges.SIZE
	var dw := DIAL_SIZE * 2.0 + 10.0
	_dials.offset_right = -w * 0.5 - 16.0
	_dials.offset_left = _dials.offset_right - dw
	_dials.offset_bottom = -18.0 - (HOTBAR_SLOT - DIAL_SIZE) * 0.5
	_dials.offset_top = _dials.offset_bottom - DIAL_SIZE
	if _weight_dial:  # centred above hunger + thirst (owner, Nov 23)
		for k in ["anchor_left", "anchor_right"]:
			_weight_dial.set(k, 0.5)
		_weight_dial.anchor_top = 1.0
		_weight_dial.anchor_bottom = 1.0
		_weight_dial.offset_left = _dials.offset_left + (dw - DIAL_SIZE) * 0.5
		_weight_dial.offset_right = _weight_dial.offset_left + DIAL_SIZE
		_weight_dial.offset_bottom = _dials.offset_top - 8.0
		_weight_dial.offset_top = _weight_dial.offset_bottom - DIAL_SIZE
	if _food_slots:  # right of the health and stamina bars, level with them (F426; the left has the lantern bar)
		for k in ["anchor_left", "anchor_right"]:
			_food_slots.set(k, 0.5)
		_food_slots.anchor_top = 1.0
		_food_slots.anchor_bottom = 1.0
		_food_slots.offset_left = w * 0.5 + 16.0
		_food_slots.offset_right = _food_slots.offset_left + 260.0
		var mid := (_vitals.offset_top + _vitals.offset_bottom) * 0.5 + 6.0  # (+6: the minutes sit under the ring)
		_food_slots.offset_top = mid - (FoodSlots.SIZE + 14.0) * 0.5
		_food_slots.offset_bottom = mid + (FoodSlots.SIZE + 14.0) * 0.5


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


func set_skills_open(open: bool, tab := "") -> void:
	skills.visible = open
	if open:
		skills.notes = first_cards
		if tab != "":
			skills.show_tab(tab)
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


func _update_reload_bar(delta: float = 0.0) -> void:
	var me := _local_dwarf()
	var reloading := me != null and me.fight != null and me.fight.is_crossbow() and me.fight.reload_left >= 0.0
	if reloading:
		_reload_bar.value = (1.0 - me.fight.reload_left / maxf(me.fight.reload_total, 0.01)) * 100.0
		_reload_fill.bg_color = RELOAD_COLOR
		_reload_done = 0.35 if _reload_bar.value > 0.0 else 0.0
	elif _reload_done > 0.0 and me != null and me.fight != null and me.fight.is_crossbow() and me.fight.loaded:
		_reload_done -= delta  # (just loaded: the full bar flashes gold, then goes)
		_reload_bar.value = 100.0
		_reload_fill.bg_color = RELOAD_DONE_COLOR
	else:
		_reload_done = 0.0
	_reload_box.visible = reloading or _reload_done > 0.0


func _process(delta: float) -> void:
	var auth := GameAuthority.instance
	var ps: GameAuthority.PlayerState = auth.get_player(peer_id) if auth else null
	_update_work_bar(auth)
	_update_reload_bar(delta)
	_show_equip_ring(ps)
	if auth and not auth.my_cooldowns.is_empty() and ps:  # the grey cooldown shades climb every frame (owner F470)
		for i in _slot_panels:
			_show_cooldown(_slot_panels[i], ps.inventory.get_slot(i), auth)
	if ps:
		var v := ps.vitals
		if v != _edge_flash_vitals:  # a new/other player's body: listen to its hits instead (F695)
			if _edge_flash_vitals and _edge_flash_vitals.damaged.is_connected(_on_hurt):
				_edge_flash_vitals.damaged.disconnect(_on_hurt)
			v.damaged.connect(_on_hurt)
			_edge_flash_vitals = v
		_update_edge_status(v.ailments)
		_edge_flash.set_health(v.health / maxf(v.max_health(), 1.0))
		_bars.health.max_value = v.max_health()
		_bars.health.value = v.health
		_update_ghost_bar(v)
		_bars.stamina.max_value = v.max_stamina()
		_bars.stamina.value = v.stamina
		_show_carry(_local_dwarf())
		var fighter := _local_dwarf()
		var sm: StunMeter = fighter.fight.stun_meter if fighter != null and fighter.fight != null else null
		_bars.stun.get_parent().visible = sm != null and sm.fraction() > 0.0
		if sm:
			_bars.stun.max_value = 1.0
			_bars.stun.step = 0.0
			_bars.stun.value = sm.fraction()
		_bars.hunger.set_value(v.hunger)
		_bars.thirst.set_value(v.thirst)
		_health_text.text = "%d / %d" % [ceili(v.health), roundi(v.max_health())]
		_stamina_text.text = "%d / %d" % [floori(v.stamina), roundi(v.max_stamina())]
		var buffs := []  # (eaten foods show as pictures in _food_slots now, F426)
		_food_slots.show_buffs(v)
		if v.in_dark:
			buffs.append("In the dark: no healing, tiring")  # F293
		if v.cozy_time > 0.0:
			buffs.append("Cozy (comfort %d) %d:%02d" % [v.cozy_points, int(v.cozy_time) / 60, int(v.cozy_time) % 60])
		var slots: Array = ps.progress.ability_slots()
		for i in slots.size():  # active perks: which key, ready or recharging
			var cd: Dictionary = v.effects.get("cd_" + slots[i], {})
			buffs.append("%s %s %s" % [["Z", "G", "T"][i], Progression.PERKS[slots[i]][4], "%d s" % ceili(cd.left) if cd.has("left") else "ready"])
		for e in v.effects:
			if not e.begins_with("cd_") and Progression.PERKS.has(e) or e == "bond":
				buffs.append("%s %d s" % [Progression.PERKS[e][4] if Progression.PERKS.has(e) else "Bond of the Clan", ceili(v.effects[e].left)])
			elif e == "bandage_heal":
				buffs.append("Bandage healing %d s" % ceili(v.effects[e].left))
		# (F870: no well-fed / peckish words: the hunger dial shows it)
		_buff_label.text = "\n".join(buffs + Array(v.ailments.describe(false)))
		_ailment_badges.show_ailments(v.ailments)
		skill_popup.watch(ps.progress, delta)  # (F870: no skills list in the corner; K shows them all)
		if craft.visible and craft.station:
			craft._status.text = craft.station.busy_text()
		var has_lantern := Lantern.has_lantern(ps)
		_lantern_out.visible = has_lantern and ps.fuel <= 0.0  # F870: no bar, just this when it runs out
		_fuel_label.text = ""
		_cards_wait -= delta
		if _cards_wait <= 0.0:
			_cards_wait = 0.5
			for id in first_cards.check(ps):
				show_first_card(id)
		var me := _local_dwarf()
		if me and me.fight and me.fight.is_crossbow():
			var bolts := 0
			for id in Combat.BOLT_ORDER:
				bolts += ps.inventory.count_of(id)
			var state := "loaded" if me.fight.loaded else ("reloading %.1f s" % me.fight.reload_left if me.fight.reload_left >= 0.0 else "empty: R to reload")
			_fuel_label.text = "Crossbow %s, %d bolts" % [state, bolts]
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
	if build_mode and build_mode.active() and build_mode.blueprint:
		_build_label.text = "Blueprint: %s (%s)\nQ turn · left click place (a blue build site) · right click or B: back to single pieces" % [build_mode.blueprint.name, BuildMenu._cost_text(build_mode.blueprint.cost())]
	elif build_mode and build_mode.active():
		var c := BuildMenu._cost_text(Pieces.cost(build_mode.piece, build_mode.family))
		# (F870: no hammer lessons or key list here: the build menu pictures are enough; keys are in Settings)
		_build_label.text = "Building: %s (%s)\nCost: %s%s%s" % [
			Pieces.LIST[build_mode.piece].name, Pieces.FAMILIES[build_mode.family].name, c,
			" (now %+.1f m)" % build_mode.lift if build_mode.lift != 0.0 else "",
			"" if build_mode.problem == "" else "\nCan't place: " + build_mode.problem]
		if build_mode.level_text() != "":  # F159: what placing it does to the ground
			_build_label.text += "\n" + build_mode.level_text()
		var aimed: Dictionary = auth.builder.structure.pieces.get(build_mode.aimed_uid, {}) if auth and auth.builder else {}
		if not aimed.is_empty():
			_build_label.text = "Aimed piece: %s\n%s\n\n" % [steadiness_text(aimed),
				take_down_text(auth.builder.pickup_seconds_left(build_mode.aimed_uid))] + _build_label.text
	else:
		_build_label.text = ""
	_map_timer -= delta
	if _map_timer <= 0.0 and dwarf and auth and auth.world:
		_map_timer = 0.5
		map_data.reveal(dwarf.global_position, auth.world.sdf_at)
	_toast_timer -= delta
	_toast.modulate.a = clampf(_toast_timer, 0.0, 1.0)


var _last_selected := -1


func _refresh_selection(sel: int) -> void:
	if sel != _last_selected:
		_last_selected = sel
		_refresh_slots()


## You got hurt (F695, owner Nov 22: subtle, not the whole screen): the health bar keeps a pale ghost
## of what you lost, your dwarf flashes and the camera bumps a little, and only a BIG hit touches the
## screen edge. Only for this computer's player: the hit itself was already decided by the host.
func _on_hurt(amount: float) -> void:
	var v := _edge_flash_vitals
	var max_hp := v.max_health() if v else 100.0
	_edge_flash.flash_hit(amount, max_hp)
	_ghost_hold_until = Time.get_ticks_msec() + GHOST_HOLD_MS
	var me := _local_dwarf()
	if me:
		me.got_hurt(amount, max_hp)


## Which ailment shows at the screen edges, and how strongly (F695, F799). Burning wins, then poison, then cold.
func _update_edge_status(a: Ailments) -> void:
	if edge_fake != "":  # the Monster Arena's "show me the look" buttons: looks only, no damage
		_edge_flash.set_status(edge_fake, CHILL_EDGE_BY_STACK[4] if edge_fake == "chill" else 1.0)
		return
	if a.has("burn"):
		_edge_flash.set_status("burn", 1.0)
	elif a.has("poison"):
		_edge_flash.set_status("poison", a.stacks_of("poison") / 3.0)
	elif a.has("frozen"):
		_edge_flash.set_status("chill", CHILL_EDGE_BY_STACK[4])  # frozen = the 5th stack
	elif a.has("chill"):
		var i := clampi(int(a.stacks_of("chill")) - 1, 0, 4)
		_edge_flash.set_status("chill", CHILL_EDGE_BY_STACK[i])
	else:
		_edge_flash.set_status("")


func _update_ghost_bar(v: Vitals) -> void:
	var now := Time.get_ticks_msec()
	var dt := clampf((now - _ghost_last_ms) / 1000.0, 0.0, 0.1)
	_ghost_last_ms = now
	_ghost_bar.max_value = v.max_health()
	if v.health >= _ghost_bar.value:
		_ghost_bar.value = v.health  # healing (or nothing lost): no ghost
	elif now >= _ghost_hold_until:
		_ghost_bar.value = lerpf(_ghost_bar.value, v.health, 1.0 - exp(-GHOST_DRAIN * dt))
		if _ghost_bar.value - v.health < 0.2:
			_ghost_bar.value = v.health


## Carry weight (F793): the weight dial above hunger + thirst (green / yellow heavy / red overloaded),
## and the bag window shows the numbers.
func _show_carry(d: Dwarf) -> void:
	var c: Dictionary = d.carry if d else {}
	var load: int = c.get("load", ItemWeights.Load.LIGHT)
	if _weight_dial:
		_weight_dial.set_carry(c)
	if _bag_weight and _bag_panel.visible and not c.is_empty():
		var word: String = ["", "   Heavy: slower", "   OVERLOADED: drop something"][load]
		_bag_weight.text = "Weight %s / %s   (overloaded past %s)%s" % [ItemWeights.pretty(c.weight),
				ItemWeights.pretty(c.heavy), ItemWeights.pretty(c.max), word]
		_bag_weight.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3) if load == ItemWeights.Load.OVERLOADED
				else (Color(1.0, 0.85, 0.35) if load == ItemWeights.Load.HEAVY else UiKit.TEXT))


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
	if k.keycode == KEY_Q:  # Q over a slot: throw it on the floor (owner F825)
		GameAuthority.instance.ask_throw(_hover_slot)
		_swap_from = -1
		get_viewport().set_input_as_handled()
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
## How you can take the aimed piece down (F100, owner Nov 19: make it clear). `left` = pick-up seconds left, -1 = unknown.
static func take_down_text(left: float) -> String:
	if left > 0.0:
		return "Right click: pick up, all back (%d s left)  ·  X: break, half back" % ceili(left)
	if left < 0.0:
		return "Right click: pick up (right after placing)  ·  X: break, half back"
	return "X: break it, half back (too late to pick up)"


static func steadiness_text(p: Dictionary) -> String:
	if p.get("anchored", false):
		return "rock-steady (on rock or a foundation)"
	var pct := roundi(float(p.get("stability", 0.0)) * 100.0)
	if pct < 25:
		return "shaky! (%d%%) prop it up" % pct
	return "%d%% steady" % pct


## The gold "E" in a slot's top-right corner: you're wearing this pickaxe/weapon/shield (F825, like Valheim).
func _show_worn_badge(panel: Control, on: bool) -> void:
	var b: Label = panel.get_node_or_null("Worn")
	if not on:
		if b:
			b.visible = false
		return
	if b == null:
		b = Label.new()
		b.name = "Worn"
		b.text = "E"
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.91, 0.69, 0.29)
		st.border_color = Color(0.23, 0.13, 0.03)
		st.set_border_width_all(2)
		st.set_corner_radius_all(20)
		b.add_theme_stylebox_override("normal", st)
		b.add_theme_color_override("font_color", UiKit.DARK_TEXT)
		b.add_theme_font_override("font", UiKit.heading_font())
		panel.add_child(b)
	var d := roundf(panel.size.x * 0.3)
	b.size = Vector2(d, d)
	b.position = Vector2(panel.size.x - d * 0.85, -d * 0.15)
	b.add_theme_font_size_override("font_size", roundi(d * 0.62))
	b.visible = true


var _ring_at := []  ## the slots that show a putting-on ring (F826; several at once since F828)


## Putting something on (F826): a gold ring fills around its slot (hotbar, bag or gear). Several can fill together
## (F828). Gone when done or a hit stops it.
func _show_equip_ring(ps) -> void:
	var jobs: Array = []
	if ps and not ps.equip_job.is_empty():
		jobs = [ps.equip_job] + ps.equip_queue
	var now := []
	for job in jobs:
		var at: int = job.get("ring", job.get("index", -1))
		if not _slot_panels.has(at):
			continue
		now.append(at)
		var panel: Control = _slot_panels[at]
		var ring: Control = panel.get_node_or_null("Ring")
		if ring == null:
			ring = Control.new()
			ring.name = "Ring"
			ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
			panel.add_child(ring)
			ring.draw.connect(_draw_equip_ring.bind(ring))
		ring.position = Vector2.ZERO
		ring.size = panel.size
		ring.set_meta("job", job)
		ring.visible = true
		ring.queue_redraw()
	for old in _ring_at:
		if old not in now and _slot_panels.has(old):
			var r: Control = _slot_panels[old].get_node_or_null("Ring")
			if r:
				r.visible = false
	_ring_at = now


func _draw_equip_ring(ring: Control) -> void:
	var p := EquipTime.progress(ring.get_meta("job", {}))
	var c := ring.size * 0.5
	var r := ring.size.x * 0.5 - 1.0
	ring.draw_arc(c, r, 0.0, TAU, 48, Color(0, 0, 0, 0.5), 7.0, true)
	if p > 0.0:
		ring.draw_arc(c, r, -PI * 0.5, -PI * 0.5 + TAU * p, 48, Color(1.0, 0.8, 0.45), 5.0, true)
