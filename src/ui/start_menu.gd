extends CanvasLayer
## The first screen: play alone, or play with friends.
## (A nicer menu comes in Step 7. This one is for testing co-op.)

signal play_alone(seed: int)
signal host_direct(seed: int)
signal join_direct(address: String)
signal host_steam(seed: int)
signal continue_game(data: Dictionary)

var _status: Label
var _seed_edit: LineEdit
var _addr_edit: LineEdit


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.035, 0.05)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.custom_minimum_size = Vector2(420, 0)
	bg.add_child(box)
	box.resized.connect(func(): box.position = (bg.size - box.size) * 0.5)
	bg.resized.connect(func(): box.position = (bg.size - box.size) * 0.5)

	var title := Label.new()
	title.text = "Dwarf Game"
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var save := SaveGame.newest()
	if not save.is_empty():
		var b := _button(box, "Continue (saved %s)" % str(save.saved_at).replace("T", " "), func(): continue_game.emit(save))
		b.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	_seed_edit = _field(box, "Cave seed (empty = random)")
	_button(box, "New world (play alone)", func(): play_alone.emit(_seed()))
	box.add_child(HSeparator.new())
	_button(box, "Host a game (direct / same network)", func(): host_direct.emit(_seed()))
	var row := HBoxContainer.new()
	box.add_child(row)
	_addr_edit = _field(row, "Host's IP address")
	_addr_edit.text = "127.0.0.1"
	_addr_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(row, "Join", func(): join_direct.emit(_addr_edit.text.strip_edges()))
	box.add_child(HSeparator.new())
	_button(box, "Host on Steam (friends join from Steam)", func(): host_steam.emit(_seed()))
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.custom_minimum_size = Vector2(420, 50)
	box.add_child(_status)


func set_status(text: String) -> void:
	if _status:
		_status.text = text


func _seed() -> int:
	return _seed_edit.text.strip_edges().to_int()


func _field(parent: Node, hint: String) -> LineEdit:
	var e := LineEdit.new()
	e.placeholder_text = hint
	e.custom_minimum_size = Vector2(0, 40)
	parent.add_child(e)
	return e


func _button(parent: Node, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 46)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b
