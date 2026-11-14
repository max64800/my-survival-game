class_name BlueprintMenu
extends PanelContainer
## The blueprint book (V while holding the Build Hammer). Blueprints that ship with the
## game live in res://blueprints, your own in user://blueprints.

const FOLDERS := ["res://blueprints", "user://blueprints"]

var mode: BuildMode
var _list: VBoxContainer
var _note: Label


func _ready() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.06, 0.05, 0.05, 0.94)
	bg.set_corner_radius_all(10)
	bg.set_content_margin_all(14)
	add_theme_stylebox_override("panel", bg)
	var v := VBoxContainer.new()
	add_child(v)
	var title := Label.new()
	title.text = "Blueprint book  ·  V to close"
	title.add_theme_font_size_override("font_size", 20)
	v.add_child(title)
	_list = VBoxContainer.new()
	v.add_child(_list)
	_note = Label.new()
	_note.text = "Pick one, aim, Q to turn, left click to place it with its Builder's Chest.\nFill the chest with materials and it builds itself.\nTo save your own: press C at one corner of your building, then C at the other."
	v.add_child(_note)


static func all_files() -> Array:
	var out := []
	for folder in FOLDERS:
		if not DirAccess.dir_exists_absolute(folder):
			continue
		for f in DirAccess.get_files_at(folder):
			if f.ends_with(".dwbp"):
				out.append(folder.path_join(f))
	return out


func refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	var files := all_files()
	if files.is_empty():
		var l := Label.new()
		l.text = "No blueprints yet."
		_list.add_child(l)
	for path in files:
		var json := FileAccess.get_file_as_string(path)
		var r := Blueprint.from_json(json)
		var b := Button.new()
		b.custom_minimum_size = Vector2(520, 44)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if not r.ok:
			b.text = "%s  (broken: %s)" % [path.get_file(), r.error]
			b.disabled = true
		else:
			var bp: Blueprint = r.blueprint
			b.text = "%s%s  ·  %d pieces  ·  %s" % [bp.name, "  (ancient)" if bp.source == "ancient" else "", bp.pieces.size(), BuildMenu._cost_text(bp.cost())]
			b.pressed.connect(func():
				mode.start_blueprint(json)
				visible = false
				Controls.set_captured(true))
		_list.add_child(b)
