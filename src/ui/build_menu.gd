class_name BuildMenu
extends PanelContainer
## Pick what to build (B while holding the Build Hammer).

var mode: BuildMode
var peer_id := 1
var _grid: VBoxContainer


func _ready() -> void:
	UiKit.panel(self)  # "dwarf workshop" look (owner F187)
	_grid = VBoxContainer.new()
	_grid.add_theme_constant_override("separation", 8)
	add_child(_grid)


## The menu's tabs (building polish spec §7), in order, with their names.
const TABS := {"foundation": "Foundations", "floor": "Floors", "wall": "Walls", "roof": "Roofs",
	"support": "Supports", "around": "Getting around", "mining": "Mining", "decor": "Decor", "furnish": "Furnish",
	"trophies": "Trophies", "living": "Living", "kitchen": "Kitchen & Workshop", "lights": "Lights & Plants"}
static var tab := "foundation"  ## remembered while the game runs


## The pieces on one tab, in catalog order.
static func pieces_in(group: String) -> Array:
	var out := []
	for id in Pieces.LIST:
		if Pieces.LIST[id].get("group", "") == group:
			out.append(id)
	return out


func refresh() -> void:
	UiKit.clear(_grid)
	var auth := GameAuthority.instance
	var ps: GameAuthority.PlayerState = auth.get_player(peer_id) if auth else null
	if ps == null or mode == null:
		return
	UiKit.title(_grid, "Build")
	var sub := UiKit.label(_grid, "%s in %s" % [Pieces.LIST[mode.piece].name, Pieces.FAMILIES[mode.family].name], 14, UiKit.DIM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Tabs, each with a picture of its first piece.
	var tabs := HFlowContainer.new()
	tabs.add_theme_constant_override("h_separation", 4)
	tabs.add_theme_constant_override("v_separation", 4)
	tabs.custom_minimum_size = Vector2(640, 0)
	_grid.add_child(tabs)
	for g in TABS:
		var t := UiKit.dark_button(Button.new(), 13)
		t.text = TABS[g]
		var first: Array = pieces_in(g)
		if not first.is_empty():
			t.icon = piece_picture(first[0], _family_for(first[0]))
		t.expand_icon = true
		t.add_theme_constant_override("icon_max_width", 24)
		t.custom_minimum_size = Vector2(0, 40)
		t.toggle_mode = true
		t.button_pressed = g == tab
		var group: String = g
		t.pressed.connect(func(): tab = group; refresh())
		tabs.add_child(t)
	# Pieces on this tab. Locked ones (station level too low) are faded, with the reason on hover.
	var pieces := GridContainer.new()
	pieces.columns = 5
	pieces.add_theme_constant_override("h_separation", 6)
	pieces.add_theme_constant_override("v_separation", 6)
	_grid.add_child(pieces)
	var where: Vector3 = ps.node.global_position if ps.node else Vector3.ZERO
	for id in pieces_in(tab):
		var fam := _family_for(id)
		var lock := auth.builder.station_problem(id, fam, where) if auth.builder else ""
		pieces.add_child(_piece_button(id, fam, lock, ps.inventory))
	UiKit.divider(_grid)
	var fam_row := HFlowContainer.new()
	fam_row.add_theme_constant_override("h_separation", 6)
	fam_row.add_theme_constant_override("v_separation", 6)
	_grid.add_child(fam_row)
	UiKit.label(fam_row, "Material:", 16, UiKit.AMBER)
	for f in Pieces.MOSSY_FAMILIES:
		var b := UiKit.dark_button(Button.new(), 14)
		b.text = "%s (%d)" % [Pieces.FAMILIES[f].name, ps.inventory.count_of(f)]
		b.icon = Items.icon(f)
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 24)
		b.tooltip_text = "Made at the %s. You have %d." % [Items.display_name(BuildMenu.station_item(f)), ps.inventory.count_of(f)]
		b.custom_minimum_size = Vector2(0, 42)
		b.toggle_mode = true
		b.button_pressed = f == mode.family
		b.disabled = not Pieces.allowed(mode.piece, f)
		if b.disabled:
			b.modulate = Color(1, 1, 1, 0.45)
		b.pressed.connect(func(): mode.choose(mode.piece, f); refresh())
		fam_row.add_child(b)
	var help := UiKit.label(_grid, "Q / E turn  ·  Shift+Wheel height  ·  Left click place  ·  Right click pick up  ·  X break  ·  B close", 13, UiKit.DIM)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.fit(self)  # shrink back to the new content (it used to keep growing with every click)


## The material a piece is shown in: the chosen one if it allows it, else its first.
func _family_for(id: String) -> String:
	return mode.family if Pieces.allowed(id, mode.family) else Pieces.LIST[id].get("families", [mode.family])[0]


## The station item that works this material (for the material buttons).
static func station_item(family: String) -> String:
	return Builder.STATION_KIND[Pieces.station_for(family)]


static func _cost_text(c: Dictionary) -> String:
	var parts := []
	for item in c:
		parts.append("%d %s" % [c[item], Items.display_name(item)])  # real names, not codes like "CI" (F130)
	return ", ".join(parts)


## One piece: its picture and name (owner F132: pictures, not reading). Hover: what it needs, what you
## have and what's missing, and any station it still needs (F133). Greyed out when you can't build it.
func _piece_button(id: String, fam: String, lock: String, inv: Inventory) -> Button:
	var b := Button.new()
	b.name = "Piece_" + id
	b.custom_minimum_size = Vector2(122, 148)
	b.focus_mode = Control.FOCUS_NONE
	b.toggle_mode = true
	b.button_pressed = id == mode.piece
	var normal := UiKit.style("slot_selected" if id == mode.piece else "card", 6)
	for st in ["normal", "pressed", "focus", "hover_pressed"]:
		b.add_theme_stylebox_override(st, normal)
	b.add_theme_stylebox_override("hover", UiKit.style("slot_selected", 6))
	# Picture, name, and the cost under it (missing amounts in red), drawn on top of the button.
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 2)
	b.add_child(v)
	var pic := TextureRect.new()
	pic.texture = piece_picture(id, fam)
	pic.custom_minimum_size = Vector2(0, 76)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(pic)
	var name_l := UiKit.label(v, Pieces.LIST[id].name, 13, UiKit.TEXT)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_l.clip_text = true
	var costs := HBoxContainer.new()
	costs.alignment = BoxContainer.ALIGNMENT_CENTER
	costs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(costs)
	var cost := Pieces.cost(id, fam)
	for item in cost:
		var ic := TextureRect.new()
		ic.texture = Items.icon(item)
		ic.custom_minimum_size = Vector2(16, 16)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		costs.add_child(ic)
		UiKit.label(costs, str(cost[item]), 13, UiKit.TEXT if inv.count_of(item) >= cost[item] else UiKit.MISSING)
	for c in v.get_children():
		if c is Control:
			(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tip := needs_text(id, fam, inv)
	if lock != "":
		tip += "\n" + lock
	b.tooltip_text = tip
	if lock != "" or not missing(id, fam, inv).is_empty():
		b.modulate = Color(1, 1, 1, 0.5)
	b.pressed.connect(func(): mode.choose(id, mode.family); refresh())
	return b


static func piece_picture(id: String, fam: String) -> Texture2D:
	var path := "res://assets/icons/build/%s__%s.png" % [id, fam]
	return load(path) if ResourceLoader.exists(path) else null


## What's missing to build one (item -> how many more you need).
static func missing(id: String, fam: String, inv: Inventory) -> Dictionary:
	var out := {}
	var cost := Pieces.cost(id, fam)
	for item in cost:
		if inv.count_of(item) < cost[item]:
			out[item] = cost[item] - inv.count_of(item)
	return out


## "Needs: 4 Rootwood Plank (you have 2, 2 missing) ..." for the hover note.
static func needs_text(id: String, fam: String, inv: Inventory) -> String:
	var lines := ["%s in %s" % [Pieces.LIST[id].name, Pieces.FAMILIES[fam].name]]
	var cost := Pieces.cost(id, fam)
	for item in cost:
		var have := inv.count_of(item)
		lines.append("%d %s: you have %d%s" % [cost[item], Items.display_name(item), have,
			"" if have >= cost[item] else " (%d missing)" % (cost[item] - have)])
	return "
".join(lines)
