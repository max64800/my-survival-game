class_name MapPanel
extends PanelContainer
## The map screen (M). Shows one floor page at a time; arrows flip floors.

var data: MapData
var floor := 0
var _tex := TextureRect.new()
var _overlay := Control.new()
var _player_pos := Vector3.ZERO
var _player_yaw := 0.0
var _stations: Array = []
var _biome := "mossy"
const BIOME_NAMES := {"mossy": "Mossy Hollows", "fungal": "Fungal Jungle"}


var _floor_label: Label
var _depth: Label


## "Dwarf workshop" look (owner F187): the map in a frame, and beside it the floor switcher and a legend.
func _ready() -> void:
	UiKit.panel(self)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	UiKit.title(box, "Map")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UiKit.style("card", 8))
	row.add_child(frame)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(540, 540)  # fits a 900 px tall window with the frame and title
	holder.clip_contents = true  # marks stop at the map's edge
	frame.add_child(holder)
	_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tex.stretch_mode = TextureRect.STRETCH_SCALE
	_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	holder.add_child(_tex)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.draw.connect(_draw_marks)
	holder.add_child(_overlay)
	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(210, 0)
	side.add_theme_constant_override("separation", 8)
	row.add_child(side)
	var floors := PanelContainer.new()
	floors.add_theme_stylebox_override("panel", UiKit.style("card", 10))
	side.add_child(floors)
	var fv := VBoxContainer.new()
	fv.add_theme_constant_override("separation", 6)
	floors.add_child(fv)
	var up := UiKit.dark_button(Button.new(), 16)
	up.text = "▲  Floor above"
	up.pressed.connect(func(): show_floor(floor + 1))
	fv.add_child(up)
	_floor_label = UiKit.label(fv, "", 18, UiKit.AMBER)
	_floor_label.add_theme_font_override("font", UiKit.heading_font())
	_floor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_depth = UiKit.label(fv, "", 13, UiKit.DIM)
	_depth.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_depth.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_depth.custom_minimum_size = Vector2(190, 0)  # a wrapping label needs a width, or it grows very tall
	var down := UiKit.dark_button(Button.new(), 16)
	down.text = "▼  Floor below"
	down.pressed.connect(func(): show_floor(floor - 1))
	fv.add_child(down)
	var legend := PanelContainer.new()
	legend.add_theme_stylebox_override("panel", UiKit.style("card", 10))
	side.add_child(legend)
	var lv := VBoxContainer.new()
	legend.add_child(lv)
	var lt := UiKit.label(lv, "Legend", 17, UiKit.AMBER)
	lt.add_theme_font_override("font", UiKit.heading_font())
	lt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.divider(lv)
	for entry in [["▲", Color(0.75, 0.1, 0.1), "You are here"], ["●", Color(0.9, 0.4, 0.15), "Your stations"],
			["▲▼", Color(0.85, 0.7, 0.5), "Way up / down"],
			["▒", Color(0.62, 0.53, 0.38), "Not explored yet"]]:
		var r := HBoxContainer.new()
		lv.add_child(r)
		var sym := UiKit.label(r, entry[0], 20, entry[1])
		sym.custom_minimum_size = Vector2(34, 0)
		sym.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiKit.label(r, entry[2], 14, UiKit.TEXT)
	var foot := UiKit.label(box, "M close", 13, UiKit.DIM)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func open(p_data: MapData, player_pos: Vector3, yaw: float, stations: Array) -> void:
	data = p_data
	_player_pos = player_pos
	_player_yaw = yaw
	_stations = stations
	_biome = CaveMaker.biome_at(player_pos)
	show_floor(MapData.floor_of(player_pos.y))


func show_floor(f: int) -> void:
	if data == null:
		return
	floor = clampi(f, 0, MapData.floor_count() - 1)
	var parchment := Image.create(data.size, data.size, false, Image.FORMAT_RGBA8)
	parchment.fill(Color(0.62, 0.53, 0.38))
	parchment.blend_rect(data.pages[_biome][floor], Rect2i(0, 0, data.size, data.size), Vector2i.ZERO)
	_tex.texture = ImageTexture.create_from_image(parchment)
	var top := CaveMaker.Y_MIN + (floor + 1) * MapData.FLOOR_HEIGHT
	var here := " (you are here)" if floor == MapData.floor_of(_player_pos.y) else ""
	_floor_label.text = "Floor %d of %d" % [floor + 1, MapData.floor_count()]
	_depth.text = "%s\n%d to %d m%s" % [BIOME_NAMES.get(_biome, _biome), top - MapData.FLOOR_HEIGHT, top, here]
	_overlay.queue_redraw()


func _draw_marks() -> void:
	if data == null:
		return
	var scale := _overlay.size / float(data.size)
	var font := ThemeDB.fallback_font
	for m in data.markers:
		if m.floor != floor or m.get("biome", "mossy") != _biome:
			continue
		var at := Vector2(data.to_pixel(m.pos, _biome)) * scale
		_overlay.draw_string(font, at - Vector2(7, -7), "▲" if m.up else "▼", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.25, 0.15, 0.08))
	for st in _stations:
		if MapData.floor_of(st.global_position.y) == floor and CaveMaker.biome_at(st.global_position) == _biome:
			_overlay.draw_circle(Vector2(data.to_pixel(st.global_position, _biome)) * scale, 5, Color(0.9, 0.4, 0.15))
	if MapData.floor_of(_player_pos.y) == floor and CaveMaker.biome_at(_player_pos) == _biome:
		var c := Vector2(data.to_pixel(_player_pos, _biome)) * scale
		var fwd := Vector2(-sin(_player_yaw), -cos(_player_yaw))
		var side := Vector2(-fwd.y, fwd.x)
		_overlay.draw_colored_polygon(PackedVector2Array([c + fwd * 12, c - fwd * 7 + side * 7, c - fwd * 7 - side * 7]), Color(0.75, 0.1, 0.1))
