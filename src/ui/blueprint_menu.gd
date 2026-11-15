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
	_note.text = "Pick one, aim, Q to turn, left click to place it. It can go into the rock: the chest digs the room out.\nIts Builder's Chest (the yellow box) appears beside it. Fill the chest with materials and it builds itself.\nTo save your own: press C at one corner of your building, then C at the other."
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


## The game's ready-made buildings (library + the old ones shipped in res://blueprints). Each is
## learned by reading an Old Blueprint found in ruins (F98). Your own saved builds are always there.
static func ready_made_keys() -> Array:
	var out: Array = BlueprintLibrary.IDS.duplicate()
	for path in all_files():
		if path.begins_with("res://"):
			out.append(path.get_file().get_basename())
	return out


static func ready_made_name(key: String) -> String:
	if BlueprintLibrary.NAMES.has(key):
		return BlueprintLibrary.NAMES[key]
	return key.capitalize()


static func _known() -> Array:
	var auth := GameAuthority.instance
	return auth.world_state.get("blueprints", []) if auth else []


## Every blueprint in the book you can use: learned ready-made buildings first, then your own files.
static func entries() -> Array:
	var out := []
	var known := _known()
	for id in BlueprintLibrary.IDS:
		if known.has(id):
			out.append({name = id, json = BlueprintLibrary.make(id).to_json()})
	for path in all_files():
		if path.begins_with("res://") and not known.has(path.get_file().get_basename()):
			continue
		out.append({name = path.get_file(), json = FileAccess.get_file_as_string(path)})
	return out


## How many ready-made buildings are still waiting to be found.
static func still_hidden() -> int:
	var known := _known()
	return ready_made_keys().filter(func(k): return not known.has(k)).size()


func refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	var hint := Label.new()
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	hint.custom_minimum_size = Vector2(520, 0)
	var hidden := still_hidden()
	hint.text = ("No blueprints yet. " if entries().is_empty() else "") + 		"Save your own: C at one corner of a building, C at the other." + 		("
%d ready-made buildings are still waiting in old ruins: read an Old Blueprint to learn one." % hidden if hidden > 0 else "")
	_list.add_child(hint)
	for e in entries():
		var json: String = e.json
		var r := Blueprint.from_json(json)
		var b := Button.new()
		b.custom_minimum_size = Vector2(520, 44)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if not r.ok:
			b.text = "%s  (broken: %s)" % [e.name, r.error]
			b.disabled = true
		else:
			var bp: Blueprint = r.blueprint
			b.text = "%s%s  ·  %d pieces  ·  %s" % [bp.name, "  (ancient)" if bp.source == "ancient" else "", bp.pieces.size(), BuildMenu._cost_text(bp.cost())]
			b.pressed.connect(func():
				mode.start_blueprint(json)
				visible = false
				Controls.set_captured(true))
		_list.add_child(b)
