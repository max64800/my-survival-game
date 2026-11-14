class_name MapPanel
extends PanelContainer
## The map screen (M). Shows one floor page at a time; arrows flip floors.

var data: MapData
var floor := 0
var _tex := TextureRect.new()
var _title := Label.new()
var _overlay := Control.new()
var _player_pos := Vector3.ZERO
var _player_yaw := 0.0
var _stations: Array = []
var _biome := "mossy"
const BIOME_NAMES := {"mossy": "Mossy Hollows", "fungal": "Fungal Jungle"}


func _ready() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.32, 0.25, 0.17, 0.97)
	bg.border_color = Color(0.2, 0.15, 0.1)
	bg.set_border_width_all(4)
	bg.set_corner_radius_all(6)
	bg.set_content_margin_all(12)
	add_theme_stylebox_override("panel", bg)
	var box := VBoxContainer.new()
	add_child(box)
	var row := HBoxContainer.new()
	box.add_child(row)
	var down := Button.new()
	down.text = "▼ floor below"
	down.pressed.connect(func(): show_floor(floor - 1))
	row.add_child(down)
	_title.add_theme_font_size_override("font_size", 20)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(_title)
	var up := Button.new()
	up.text = "floor above ▲"
	up.pressed.connect(func(): show_floor(floor + 1))
	row.add_child(up)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(640, 640)
	box.add_child(holder)
	_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tex.stretch_mode = TextureRect.STRETCH_SCALE
	_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	holder.add_child(_tex)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.draw.connect(_draw_marks)
	holder.add_child(_overlay)


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
	_title.text = "%s · Floor %d of %d · %d to %d m%s" % [BIOME_NAMES.get(_biome, _biome), floor + 1, MapData.floor_count(), top - MapData.FLOOR_HEIGHT, top, here]
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
	# Boss clues (world doc 3.2): circles shrink with every wall marking read.
	var auth := GameAuthority.instance
	if auth and auth.world:
		var maker: CaveMaker = auth.world.maker
		var found: int = auth.world_state.clues.filter(func(id): return maker.pois[id].biome == _biome).size()
		var circles: Array = maker.clue_circles(_biome)
		var lair: Dictionary = maker.lair_poi(_biome)
		for i in mini(found, circles.size()):
			var c: Vector2 = circles[i][0]
			var px := Vector2(data.to_pixel(Vector3(c.x, 0, c.y), _biome)) * scale
			var col := Color(0.6, 0.1, 0.1, 0.9)
			if i < 2:
				_overlay.draw_arc(px, circles[i][1] * scale.x, 0, TAU, 64, col, 2.0 if i == found - 1 else 1.0)
			elif MapData.floor_of(lair.pos.y) == floor:
				_overlay.draw_line(px - Vector2(8, 8), px + Vector2(8, 8), col, 3.0)
				_overlay.draw_line(px - Vector2(8, -8), px + Vector2(8, -8), col, 3.0)
		if found > 0 and not lair.is_empty():
			var f := MapData.floor_of(lair.pos.y)
			var hint := "floors %d–%d" % [maxi(f, 1), mini(f + 2, MapData.floor_count())] if found == 1 else "floor %d" % (f + 1)
			_overlay.draw_string(font, Vector2(8, 20), "Boss clues: %d of 3 · the lair is on %s" % [found, hint], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.4, 0.05, 0.05))
	for st in _stations:
		if MapData.floor_of(st.global_position.y) == floor and CaveMaker.biome_at(st.global_position) == _biome:
			_overlay.draw_circle(Vector2(data.to_pixel(st.global_position, _biome)) * scale, 5, Color(0.9, 0.4, 0.15))
	if MapData.floor_of(_player_pos.y) == floor and CaveMaker.biome_at(_player_pos) == _biome:
		var c := Vector2(data.to_pixel(_player_pos, _biome)) * scale
		var fwd := Vector2(-sin(_player_yaw), -cos(_player_yaw))
		var side := Vector2(-fwd.y, fwd.x)
		_overlay.draw_colored_polygon(PackedVector2Array([c + fwd * 12, c - fwd * 7 + side * 7, c - fwd * 7 - side * 7]), Color(0.75, 0.1, 0.1))
