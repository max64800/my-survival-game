extends CanvasLayer
## The first screen (F87): your saved worlds (play, host for friends, delete), a new world
## with a name, joining a friend, and quitting.

signal play_alone(seed: int, world_name: String)
signal host_direct(seed: int, world_name: String)
signal join_direct(address: String)
signal host_steam(seed: int, world_name: String)
signal continue_game(data: Dictionary)
signal host_world(data: Dictionary)
signal quit_game
signal test_dungeon  ## dev builds only: a new world, standing at the first dungeon's door with the best gear
signal test_dungeon2  ## dev builds only: the same at the second dungeon, Lampwick Drift
signal test_dungeon3  ## dev builds only: the same at the third dungeon, Old Pell's Diggings
signal test_dungeon4  ## dev builds only: the same at the fourth dungeon, Mossprop Workings

var _status: Label
var _seed_edit: LineEdit
var _name_edit: LineEdit
var _addr_edit: LineEdit
var _worlds_box: VBoxContainer
var _confirm: ColorRect  ## the "are you sure?" box in the kit look (F225)
var _confirm_text: Label
var _delete_path := ""
var _new_box: VBoxContainer
var _join_box: HBoxContainer
var _settings: SettingsPanel


func _ready() -> void:
	Controls.set_captured(false)
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.05, 0.04)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bg.add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var page := HBoxContainer.new()  # the menu, and Settings beside it when open
	page.add_theme_constant_override("separation", 16)
	center.add_child(page)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.custom_minimum_size = Vector2(620, 0)
	page.add_child(box)
	_settings = SettingsPanel.new()
	_settings.visible = false
	_settings.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	page.add_child(_settings)

	# "Dwarf workshop" look (owner F187): the game's name, then one framed panel with your worlds.
	var title := UiKit.label(box, "Dwarf Game", 64, UiKit.AMBER)
	title.add_theme_font_override("font", UiKit.heading_font())
	title.add_theme_constant_override("outline_size", 10)
	title.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var panel := PanelContainer.new()
	UiKit.panel(panel, 24)
	box.add_child(panel)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 10)
	panel.add_child(pv)
	UiKit.title(pv, "Your Worlds")
	_worlds_box = VBoxContainer.new()
	_worlds_box.add_theme_constant_override("separation", 6)
	pv.add_child(_worlds_box)
	UiKit.divider(pv)
	var big := HBoxContainer.new()
	big.add_theme_constant_override("separation", 12)
	pv.add_child(big)
	_gold(big, "New World", func(): _show_part(_new_box)).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gold(big, "Join Friend", func(): _show_part(_join_box)).size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# New world: name and seed, then play alone or host (hidden until "New World").
	_new_box = VBoxContainer.new()
	_new_box.add_theme_constant_override("separation", 8)
	pv.add_child(_new_box)
	_name_edit = _field(_new_box, "World name (empty = \"Cave\" + its number)")
	_seed_edit = _field(_new_box, "Cave seed (empty = random)")
	var new_row := HBoxContainer.new()
	new_row.add_theme_constant_override("separation", 8)
	_new_box.add_child(new_row)
	_gold(new_row, "Create and Play", func(): play_alone.emit(_seed(), _name())).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(new_row, "Host for Friends", func(): host_direct.emit(_seed(), _name())).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(_new_box, "Host on Steam (friends join from Steam)", func(): host_steam.emit(_seed(), _name()))

	# Join a friend by IP (hidden until "Join Friend").
	_join_box = HBoxContainer.new()
	_join_box.add_theme_constant_override("separation", 8)
	pv.add_child(_join_box)
	_addr_edit = _field(_join_box, "Host's IP address")
	_addr_edit.text = "127.0.0.1"
	_addr_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gold(_join_box, "Join", func(): join_direct.emit(_addr_edit.text.strip_edges())).custom_minimum_size.x = 120

	var small := HBoxContainer.new()
	small.add_theme_constant_override("separation", 12)
	small.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(small)
	_button(small, "Settings", func(): _settings.visible = not _settings.visible).custom_minimum_size.x = 190
	_button(small, "Quit", func(): quit_game.emit()).custom_minimum_size.x = 190
	if DevMenu.enabled():  # (owner, Nov 19) never in the game players get
		var purple := StyleBoxFlat.new()
		purple.bg_color = Color(0.22, 0.08, 0.26)
		purple.set_corner_radius_all(8)
		# Owner, Nov 20: "Dungeon 1" and "Dungeon 2" (F477: Dungeon 2 is Lampwick Drift, the planned second dungeon).
		var dev := _button(box, "Dev: Dungeon 1, Mossgate Hold (new world, copper gear, at the door)", func(): test_dungeon.emit())
		dev.add_theme_stylebox_override("normal", purple)
		var dev2 := _button(box, "Dev: Dungeon 2, Lampwick Drift (new world, copper gear, at the door)", func(): test_dungeon2.emit())
		dev2.add_theme_stylebox_override("normal", purple)
		var dev3 := _button(box, "Dev: Dungeon 3, Old Pell's Diggings (new world, copper gear, at the door)", func(): test_dungeon3.emit())
		dev3.add_theme_stylebox_override("normal", purple)
		var dev4 := _button(box, "Dev: Dungeon 4, Mossprop Workings (new world, copper gear, at the door)", func(): test_dungeon4.emit())
		dev4.add_theme_stylebox_override("normal", purple)
	_status = UiKit.label(box, "", 15, UiKit.AMBER)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.custom_minimum_size = Vector2(620, 40)

	_make_confirm()
	_fill_worlds()


## "New World" / "Join Friend" open their part of the panel (one at a time; again = close).
func _show_part(part: Control) -> void:
	var open := not part.visible
	_new_box.visible = false
	_join_box.visible = false
	part.visible = open


## One card per saved world: its name and when it was saved, then Play / Host / Delete.
func _fill_worlds() -> void:
	UiKit.clear(_worlds_box)
	var worlds := SaveGame.list_worlds()
	_join_box.visible = false
	_new_box.visible = worlds.is_empty()  # no worlds yet: show "make one" straight away
	if worlds.is_empty():
		var none := UiKit.label(_worlds_box, "No saved worlds yet. Make your first one!", 16, UiKit.DIM)
		none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		return
	for w in worlds:
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UiKit.style("card", 10, 14))
		_worlds_box.add_child(card)
		var row := HBoxContainer.new()
		row.name = "World_" + str(w.path).get_file().get_basename()
		row.add_theme_constant_override("separation", 8)
		card.add_child(row)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 0)
		row.add_child(info)
		UiKit.label(info, str(w.name), 20, UiKit.AMBER).add_theme_font_override("font", UiKit.heading_font())
		UiKit.label(info, "saved %s  ·  seed %d" % [str(w.saved_at).replace("T", " ").left(16), w.seed], 13, UiKit.DIM)
		var path: String = w.path
		var play := _gold(row, "Play", func(): _open_world(path, false))
		play.name = "Play"
		play.custom_minimum_size = Vector2(96, 44)
		var host := _button(row, "Host", func(): _open_world(path, true))
		host.name = "Host"
		var del := _button(row, "Delete", func(): ask_delete(path, w.name))
		del.name = "Delete"
		del.add_theme_color_override("font_color", UiKit.MISSING)
		del.add_theme_font_size_override("font_size", 13)


func _open_world(path: String, host: bool) -> void:
	var data := SaveGame.load_world(path)
	if data.is_empty():
		set_status("That world's save is broken and has no good backup.")
		return
	if host:
		host_world.emit(data)
	else:
		continue_game.emit(data)


## Deleting asks first ("are you sure?").
func ask_delete(path: String, world_name: String) -> void:
	_delete_path = path
	_confirm_text.text ="Delete \"%s\" forever?\nIts cave, buildings and your dwarf's things will be gone." % world_name
	_confirm.visible = true


## The "are you sure?" box in the menu's own look (F225): a framed panel over a dark veil,
## "Keep it" (the safe choice, focused) and a red "Delete forever".
func _make_confirm() -> void:
	_confirm = ColorRect.new()
	_confirm.name = "ConfirmDelete"
	_confirm.color = Color(0, 0, 0, 0.6)
	_confirm.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm.mouse_filter = Control.MOUSE_FILTER_STOP  # clicks don't reach the menu behind
	_confirm.visible = false
	add_child(_confirm)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm.add_child(center)
	var panel := PanelContainer.new()
	UiKit.panel(panel, 26)
	panel.custom_minimum_size = Vector2(520, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)
	UiKit.title(v, "Delete World?")
	_confirm_text = UiKit.label(v, "", 17, UiKit.TEXT)
	_confirm_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	_confirm_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.divider(v)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	var keep := _gold(row, "Keep it", func(): _confirm.visible = false)
	keep.name = "Keep"
	keep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var del := _button(row, "Delete forever", _delete_confirmed)
	del.name = "DeleteForever"
	del.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	del.custom_minimum_size.y = 50
	del.add_theme_color_override("font_color", UiKit.MISSING)
	del.add_theme_color_override("font_hover_color", Color(1.0, 0.6, 0.55))
	_confirm.visibility_changed.connect(func():
		if keep.is_visible_in_tree() and keep.focus_mode != Control.FOCUS_NONE:
			keep.grab_focus.call_deferred())


func _unhandled_input(event: InputEvent) -> void:
	if _confirm and _confirm.visible and event.is_action_pressed("ui_cancel"):
		_confirm.visible = false
		get_viewport().set_input_as_handled()


func _delete_confirmed() -> void:
	_confirm.visible = false
	SaveGame.delete_world(_delete_path)
	_delete_path = ""
	_fill_worlds()
	set_status("World deleted.")


func set_status(text: String) -> void:
	if _status:
		_status.text = text


func _seed() -> int:
	return _seed_edit.text.strip_edges().to_int()


func _name() -> String:
	return _name_edit.text.strip_edges().left(40)


func _field(parent: Node, hint: String) -> LineEdit:
	var e := UiKit.line_edit(LineEdit.new())
	e.placeholder_text = hint
	e.custom_minimum_size = Vector2(0, 44)
	parent.add_child(e)
	return e


## A dark kit button.
func _button(parent: Node, text: String, cb: Callable) -> Button:
	var b := UiKit.dark_button(Button.new(), 15)
	b.text = text
	b.custom_minimum_size = Vector2(0, 44)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


## A big gold kit button.
func _gold(parent: Node, text: String, cb: Callable) -> Button:
	var b := UiKit.gold_button(Button.new(), 19)
	b.text = text
	b.custom_minimum_size = Vector2(0, 50)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b
