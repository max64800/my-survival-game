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


## The menu's tabs (building polish spec §7), in order, with their names.
const TABS := {"foundation": "Foundations", "floor": "Floors", "wall": "Walls", "roof": "Roofs",
	"support": "Supports", "around": "Getting around", "mining": "Mining", "decor": "Decor"}
static var tab := "foundation"  ## remembered while the game runs


## The pieces on one tab, in catalog order.
static func pieces_in(group: String) -> Array:
	var out := []
	for id in Pieces.LIST:
		if Pieces.LIST[id].get("group", "") == group:
			out.append(id)
	return out


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
	# Tabs
	var tabs := HBoxContainer.new()
	_grid.add_child(tabs)
	for g in TABS:
		var t := Button.new()
		t.text = TABS[g]
		t.toggle_mode = true
		t.button_pressed = g == tab
		var group: String = g
		t.pressed.connect(func(): tab = group; refresh())
		tabs.add_child(t)
	# Pieces on this tab. Locked ones (station level too low) are greyed out with the reason.
	var pieces := GridContainer.new()
	pieces.columns = 4
	_grid.add_child(pieces)
	var where: Vector3 = ps.node.global_position if ps.node else Vector3.ZERO
	for id in pieces_in(tab):
		var b := Button.new()
		var fam: String = mode.family if Pieces.allowed(id, mode.family) else Pieces.LIST[id].get("families", [mode.family])[0]
		var lock := auth.builder.station_problem(id, fam, where) if auth.builder else ""
		b.text = "%s
%s" % [Pieces.LIST[id].name, _cost_text(Pieces.cost(id, fam)) if lock == "" else lock.replace(" within 20 m", "")]
		b.custom_minimum_size = Vector2(190, 52)
		b.toggle_mode = true
		b.button_pressed = id == mode.piece
		if lock != "":
			b.modulate = Color(1, 1, 1, 0.45)
			b.tooltip_text = lock
		b.pressed.connect(func(): mode.choose(id, mode.family); refresh())
		pieces.add_child(b)
	_grid.add_child(_header("Material (you have)"))
	var fams := GridContainer.new()
	fams.columns = 4
	_grid.add_child(fams)
	for f in Pieces.MOSSY_FAMILIES:
		var b := Button.new()
		b.text = "%s
(%d) · %s" % [Pieces.FAMILIES[f].name, ps.inventory.count_of(f), Items.display_name(BuildMenu.station_item(f))]
		b.custom_minimum_size = Vector2(190, 52)
		b.toggle_mode = true
		b.button_pressed = f == mode.family
		b.disabled = not Pieces.allowed(mode.piece, f)
		b.pressed.connect(func(): mode.choose(mode.piece, f); refresh())
		fams.add_child(b)
	var help := Label.new()
	help.text = "Left click place · Right click take down (all back) · Q turn · PageUp/PageDown lift
Wood needs a Workbench, stone and brick a Mason's Table, copper an Anvil (within 20 m).
Build extras next to a station to unlock greyed-out pieces. Pieces touching rock or on foundations are steadiest."
	_grid.add_child(help)


## The station item that works this material (for the material buttons).
static func station_item(family: String) -> String:
	return Builder.STATION_KIND[Pieces.station_for(family)]


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
