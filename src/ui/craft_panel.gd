class_name CraftPanel
extends PanelContainer
## The crafting list: by hand (shown next to the bag) or at a station (press E at it).
## Only recipes you've unlocked appear. Missing ingredients show in red.

var peer_id := 1
var station: Station = null  ## null = crafting by hand
var _title: Label
var _status: Label
var _list: VBoxContainer


func _ready() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.06, 0.05, 0.05, 0.9)
	bg.set_corner_radius_all(10)
	bg.set_content_margin_all(12)
	add_theme_stylebox_override("panel", bg)
	custom_minimum_size = Vector2(430, 0)
	var box := VBoxContainer.new()
	add_child(box)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 20)
	box.add_child(_title)
	_status = Label.new()
	_status.add_theme_color_override("font_color", Color(1.0, 0.8, 0.5))
	box.add_child(_status)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(410, 360)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)


func open_for(st: Station) -> void:
	station = st
	visible = true
	refresh()


func refresh() -> void:
	var auth := GameAuthority.instance
	var ps: GameAuthority.PlayerState = auth.get_player(peer_id) if auth else null
	if ps == null or not is_inside_tree():
		return
	var where := Recipes.HAND if station == null else station.kind
	_title.text = "Craft by hand" if station == null else Items.display_name(station.kind)
	_status.text = station.busy_text() if station else ""
	for c in _list.get_children():
		c.queue_free()
	var shown := 0
	for id in Recipes.for_station(where):
		if not Recipes.is_unlocked(id, ps.seen, auth.rune_slab.taught_recipes()):
			continue
		shown += 1
		_list.add_child(_row(id, ps.inventory))
	if shown == 0:
		var l := Label.new()
		l.text = "Nothing to make here yet. Explore and collect more!"
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		_list.add_child(l)


func _row(recipe_id: String, inv: Inventory) -> Control:
	var r := Recipes.get_recipe(recipe_id)
	var row := HBoxContainer.new()
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.scroll_active = false
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var parts := []
	var ok := true
	for item in r.inputs:
		var have := inv.count_of(item)
		var need: int = r.inputs[item]
		var col := "white" if have >= need else "#ff7070"
		if have < need:
			ok = false
		parts.append("[color=%s]%d/%d %s[/color]" % [col, mini(have, need), need, Items.display_name(item)])
	if r.get("fuel", 0) > 0:
		parts.append("+ %d wood fuel" % r.fuel)
	var out := Items.display_name(r.output) + ("" if r.count == 1 else " ×%d" % r.count)
	var timer := "" if r.get("seconds", 0) == 0 else "  (%ds)" % r.seconds
	text.text = "[b]%s[/b]%s\n[font_size=13]%s[/font_size]" % [out, timer, ", ".join(parts)]
	row.add_child(text)
	var b := Button.new()
	b.text = "Make"
	b.disabled = not ok
	b.custom_minimum_size = Vector2(70, 0)
	b.pressed.connect(func():
		GameAuthority.instance.ask_craft(recipe_id, station.station_id if station else 0)
		get_tree().create_timer(0.15).timeout.connect(refresh))
	row.add_child(b)
	return row
