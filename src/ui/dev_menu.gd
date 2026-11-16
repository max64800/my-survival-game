class_name DevMenu
extends PanelContainer
## The owner's dev menu (P, Nov 16): place ANY ready-made blueprint to preview it (learned or not, no hammer
## needed), and P while a Builder's Chest is open fills it with everything that building still needs, so you
## can watch it build itself. Only in dev builds (running from Godot / the dev icon), never in a shipped game.

var mode: BuildMode
var _list: VBoxContainer


## Dev tools exist only in debug builds (the exported game for players is a release build).
static func enabled() -> bool:
	return OS.is_debug_build()


## Every ready-made blueprint, learned or not: [{name, json}].
static func all_blueprints() -> Array:
	var out := []
	for id in BlueprintLibrary.IDS:
		out.append({name = BlueprintLibrary.NAMES[id], json = BlueprintLibrary.make(id).to_json()})
	for path in BlueprintMenu.all_files():
		if path.begins_with("res://"):
			out.append({name = path.get_file().get_basename().capitalize(), json = FileAccess.get_file_as_string(path)})
	return out


func _ready() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.04, 0.12, 0.95)  # purple: clearly not part of the real game
	bg.set_corner_radius_all(10)
	bg.set_content_margin_all(14)
	add_theme_stylebox_override("panel", bg)
	var v := VBoxContainer.new()
	add_child(v)
	var title := Label.new()
	title.text = "Dev menu  ·  P to close"
	title.add_theme_font_size_override("font_size", 20)
	v.add_child(title)
	var note := Label.new()
	note.text = "Pick a blueprint to preview and place it (no hammer needed): aim, Q to turn, left click to place.\nThen open its Builder's Chest (E) and press P: it fills with everything the building still needs."
	v.add_child(note)
	_list = VBoxContainer.new()
	v.add_child(_list)


func refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	for e in all_blueprints():
		var r := Blueprint.from_json(e.json)
		var b := Button.new()
		b.custom_minimum_size = Vector2(520, 40)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if not r.ok:
			b.text = "%s  (broken: %s)" % [e.name, r.error]
			b.disabled = true
		else:
			var bp: Blueprint = r.blueprint
			b.text = "%s  ·  %d pieces  ·  %s" % [e.name, bp.pieces.size(), BuildMenu._cost_text(bp.cost())]
			var json: String = e.json
			b.pressed.connect(func():
				mode.start_blueprint(json, true)
				visible = false
				Controls.set_captured(true))
		_list.add_child(b)
