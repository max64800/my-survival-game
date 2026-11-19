class_name BlueprintMenu
extends PanelContainer
## The blueprint book (V while holding the Build Hammer). Blueprints that ship with the
## game live in res://blueprints, your own in user://blueprints.

const FOLDERS := ["res://blueprints", "user://blueprints"]

var mode: BuildMode
var peer_id := 1
var _list: VBoxContainer
var _note: Label
var _picked := 0  ## which entry is open on the right page
var _page_name: Label
var _preview: BlueprintPreview
var _page_size: Label
var _needs: GridContainer
var _place: Button
var _entries: Array = []


## Two pages, like the owner's mock-up (F187): the list on the left, the picked building on the right
## (turning in 3D, F99), with its materials (have / need) and one gold Place button.
func _ready() -> void:
	UiKit.panel(self)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	add_child(v)
	UiKit.title(v, "Blueprint Book")
	var pages := HBoxContainer.new()
	pages.add_theme_constant_override("separation", 12)
	v.add_child(pages)
	var left := PanelContainer.new()
	left.add_theme_stylebox_override("panel", UiKit.style("card", 12))
	pages.add_child(left)
	var lv := VBoxContainer.new()
	lv.custom_minimum_size = Vector2(300, 0)
	left.add_child(lv)
	UiKit.label(lv, "Blueprints", 18, UiKit.AMBER).add_theme_font_override("font", UiKit.heading_font())
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(300, 330)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	lv.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_list)
	_note = UiKit.label(lv, "", 13, UiKit.DIM)
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note.custom_minimum_size = Vector2(300, 0)
	var right := PanelContainer.new()
	right.add_theme_stylebox_override("panel", UiKit.style("card", 12))
	pages.add_child(right)
	var rv := VBoxContainer.new()
	rv.custom_minimum_size = Vector2(360, 0)
	rv.add_theme_constant_override("separation", 6)
	right.add_child(rv)
	_page_name = UiKit.label(rv, "", 21, UiKit.AMBER)
	_page_name.add_theme_font_override("font", UiKit.heading_font())
	_page_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview = BlueprintPreview.new()
	rv.add_child(_preview)
	_page_size = UiKit.label(rv, "", 14, UiKit.DIM)
	_page_size.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.divider(rv)
	UiKit.label(rv, "Total materials  (have / need)", 14, UiKit.AMBER)
	_needs = GridContainer.new()
	_needs.columns = 3
	_needs.add_theme_constant_override("h_separation", 8)
	rv.add_child(_needs)
	_place = UiKit.gold_button(Button.new(), 20)
	_place.text = "Place Blueprint"
	_place.custom_minimum_size = Vector2(0, 50)
	_place.pressed.connect(_place_picked)
	rv.add_child(_place)
	var foot := UiKit.label(v, "Q / E turn  ·  Left click place  ·  fill its Builder's Chest and it builds itself  ·  V close", 13, UiKit.DIM)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


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
	var out: Array = BlueprintLibrary.IDS.filter(func(k): return not BlueprintLibrary.STARTER.has(k))
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
		if known.has(id) or BlueprintLibrary.STARTER.has(id):  # starters: from the very start (F161)
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
	UiKit.clear(_list)
	_entries = []
	for e in entries():
		var r := Blueprint.from_json(e.json)
		_entries.append({name = e.name, json = e.json, ok = r.ok, error = r.get("error", ""), bp = r.get("blueprint")})
	var hidden := still_hidden()
	_note.text = ("No blueprints yet. " if _entries.is_empty() else "") + "Save your own: C at one corner of a building, C at the other." + \
		("\n%d more wait in old ruins: read an Old Blueprint to learn one." % hidden if hidden > 0 else "")
	_picked = clampi(_picked, 0, maxi(_entries.size() - 1, 0))
	for i in _entries.size():
		var e: Dictionary = _entries[i]
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 46)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_NONE
		b.icon = load("res://assets/icons/blueprint_page.png")
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 30)
		b.add_theme_color_override("font_color", UiKit.TEXT)
		b.add_theme_color_override("font_hover_color", UiKit.AMBER)
		var look := UiKit.style("slot_selected" if i == _picked else "card", 8, 12)
		for st in ["normal", "pressed", "focus"]:
			b.add_theme_stylebox_override(st, look)
		b.add_theme_stylebox_override("hover", UiKit.style("slot_selected", 8, 12))
		if not e.ok:
			b.text = "%s (broken)" % e.name
			b.tooltip_text = e.error
		else:
			var bp: Blueprint = e.bp
			b.text = bp.name + ("  (ancient)" if bp.source == "ancient" else "")
		var pick := i
		b.pressed.connect(func(): _picked = pick; refresh())
		_list.add_child(b)
	_show_page()


## The right page: the picked blueprint, its size, and every material as have / need.
func _show_page() -> void:
	UiKit.clear(_needs)
	var e: Dictionary = _entries[_picked] if _picked < _entries.size() else {}
	var bp: Blueprint = e.get("bp") if e.get("ok", false) else null
	_page_name.text = bp.name if bp else ("" if e.is_empty() else "%s (broken: %s)" % [e.name, e.error])
	_preview.show_blueprint(bp)
	_place.disabled = bp == null
	_page_size.text = "" if bp == null else "Size: %d × %d × %d m  ·  %d pieces" % [roundi(bp.size.x), roundi(bp.size.z), roundi(bp.size.y), bp.pieces.size()]
	if bp == null:
		return
	var auth := GameAuthority.instance
	var ps: GameAuthority.PlayerState = auth.get_player(peer_id) if auth else null
	var cost := bp.cost()
	for item in cost:
		var have := ps.inventory.count_of(item) if ps else 0
		var col := UiKit.TEXT if have >= cost[item] else UiKit.MISSING
		var pic := TextureRect.new()
		pic.texture = Items.icon(item)
		pic.custom_minimum_size = Vector2(22, 22)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_needs.add_child(pic)
		UiKit.label(_needs, Items.display_name(item), 14, col).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UiKit.label(_needs, "%d / %d" % [have, cost[item]], 14, col)


## You don't need everything now: the Builder's Chest collects it (so Place works with an empty bag).
func _place_picked() -> void:
	if _picked >= _entries.size() or not _entries[_picked].ok:
		return
	mode.start_blueprint(_entries[_picked].json)
	visible = false
	Controls.set_captured(true)
