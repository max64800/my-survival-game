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

var _status: Label
var _seed_edit: LineEdit
var _name_edit: LineEdit
var _addr_edit: LineEdit
var _worlds_box: VBoxContainer
var _confirm: ConfirmationDialog
var _delete_path := ""


func _ready() -> void:
	Controls.set_captured(false)
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.035, 0.05)
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
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.custom_minimum_size = Vector2(560, 0)
	center.add_child(box)

	var title := Label.new()
	title.text = "Dwarf Game"
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	_heading(box, "Your worlds")
	_worlds_box = VBoxContainer.new()
	_worlds_box.add_theme_constant_override("separation", 6)
	box.add_child(_worlds_box)
	_fill_worlds()

	_heading(box, "New world")
	_name_edit = _field(box, "World name (empty = \"Cave\" + its number)")
	_seed_edit = _field(box, "Cave seed (empty = random)")
	var new_row := HBoxContainer.new()
	new_row.add_theme_constant_override("separation", 8)
	box.add_child(new_row)
	_button(new_row, "Create and play", func(): play_alone.emit(_seed(), _name())).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(new_row, "Create and host for friends", func(): host_direct.emit(_seed(), _name())).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(box, "Create and host on Steam (friends join from Steam)", func(): host_steam.emit(_seed(), _name()))

	_heading(box, "Join a friend")
	var row := HBoxContainer.new()
	box.add_child(row)
	_addr_edit = _field(row, "Host's IP address")
	_addr_edit.text = "127.0.0.1"
	_addr_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(row, "Join", func(): join_direct.emit(_addr_edit.text.strip_edges()))

	box.add_child(HSeparator.new())
	_button(box, "Quit game", func(): quit_game.emit())
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.custom_minimum_size = Vector2(560, 50)
	box.add_child(_status)

	_confirm = ConfirmationDialog.new()
	_confirm.ok_button_text = "Delete forever"
	_confirm.cancel_button_text = "Keep it"
	_confirm.confirmed.connect(_delete_confirmed)
	add_child(_confirm)


## One row per saved world: name and when it was saved, then Play / Host / Delete.
func _fill_worlds() -> void:
	for c in _worlds_box.get_children():
		c.queue_free()
	var worlds := SaveGame.list_worlds()
	if worlds.is_empty():
		var none := Label.new()
		none.text = "No saved worlds yet. Make one below!"
		none.add_theme_color_override("font_color", Color(0.7, 0.68, 0.64))
		_worlds_box.add_child(none)
		return
	for w in worlds:
		var row := HBoxContainer.new()
		row.name = "World_" + str(w.path).get_file().get_basename()
		row.add_theme_constant_override("separation", 8)
		_worlds_box.add_child(row)
		var lbl := Label.new()
		lbl.text = "%s\n   saved %s · seed %d" % [w.name, str(w.saved_at).replace("T", " ").left(16), w.seed]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		var path: String = w.path
		var play := _button(row, "Play", func(): _open_world(path, false))
		play.name = "Play"
		play.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
		_button(row, "Host", func(): _open_world(path, true)).name = "Host"
		var del := _button(row, "Delete", func(): ask_delete(path, w.name))
		del.name = "Delete"
		del.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45))


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
	_confirm.dialog_text = "Delete \"%s\" forever?\nIts cave, buildings and your dwarf's things will be gone." % world_name
	_confirm.popup_centered()


func _delete_confirmed() -> void:
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


func _heading(parent: Node, text: String) -> void:
	parent.add_child(HSeparator.new())
	var h := Label.new()
	h.text = text
	h.add_theme_font_size_override("font_size", 22)
	h.add_theme_color_override("font_color", Color(0.95, 0.75, 0.5))
	parent.add_child(h)


func _field(parent: Node, hint: String) -> LineEdit:
	var e := LineEdit.new()
	e.placeholder_text = hint
	e.custom_minimum_size = Vector2(0, 40)
	parent.add_child(e)
	return e


func _button(parent: Node, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 44)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b
