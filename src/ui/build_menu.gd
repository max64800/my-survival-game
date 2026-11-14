class_name BuildMenu
extends PanelContainer
## Pick what to build (B while holding the Build Hammer).

var mode: BuildMode
var peer_id := 1
var _grid: VBoxContainer


func _ready() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.06, 0.05, 0.05, 0.94)
	bg.set_corner_radius_all(10)
	bg.set_content_margin_all(14)
	add_theme_stylebox_override("panel", bg)
	_grid = VBoxContainer.new()
	add_child(_grid)


func refresh() -> void:
	for c in _grid.get_children():
		c.queue_free()
	var auth := GameAuthority.instance
	var ps: GameAuthority.PlayerState = auth.get_player(peer_id) if auth else null
	if ps == null or mode == null:
		return
	var title := Label.new()
	title.text = "Build: %s in %s  ·  B to close" % [Pieces.LIST[mode.piece].name, Pieces.FAMILIES[mode.family].name]
	title.add_theme_font_size_override("font_size", 20)
	_grid.add_child(title)
	_grid.add_child(_header("Piece"))
	var pieces := GridContainer.new()
	pieces.columns = 4
	_grid.add_child(pieces)
	for id in Pieces.LIST:
		var b := Button.new()
		var c := Pieces.cost(id, mode.family) if Pieces.allowed(id, mode.family) else {}
		b.text = "%s\n%s" % [Pieces.LIST[id].name, _cost_text(c)]
		b.custom_minimum_size = Vector2(180, 52)
		b.toggle_mode = true
		b.button_pressed = id == mode.piece
		b.pressed.connect(func(): mode.choose(id, mode.family); refresh())
		pieces.add_child(b)
	_grid.add_child(_header("Material (you have)"))
	var fams := GridContainer.new()
	fams.columns = 5
	_grid.add_child(fams)
	for f in Pieces.FAMILIES:
		var b := Button.new()
		b.text = "%s\n(%d)" % [Pieces.FAMILIES[f].name, ps.inventory.count_of(f)]
		b.custom_minimum_size = Vector2(140, 52)
		b.toggle_mode = true
		b.button_pressed = f == mode.family
		b.disabled = not Pieces.allowed(mode.piece, f)
		b.pressed.connect(func(): mode.choose(mode.piece, f); refresh())
		fams.add_child(b)
	var help := Label.new()
	help.text = "Left click place · Right click take down (all back) · Q turn · PageUp/PageDown lift\nNeeds a Workbench within 20 m. Pieces touching rock are steady; others get shakier the further they reach."
	_grid.add_child(help)


func _header(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_color_override("font_color", Color(1.0, 0.8, 0.5))
	return l


static func _cost_text(c: Dictionary) -> String:
	var parts := []
	for item in c:
		parts.append("%d %s" % [c[item], Items.short_label(item)])
	return ", ".join(parts)
