class_name BuildMenu
extends PanelContainer
## Pick what to build (B while holding the Build Hammer).
## F709 (owner OK'd mock-up assets/concepts/ui/menu_build_v2_mockup.png): a wide bar along the bottom of the
## screen, so the green preview stays visible above it. Left: 1 Material. Middle: 2 Piece (6 big tabs + cards).
## Right: the chosen piece, big, with what it needs. Under it: the keys.

var mode: BuildMode
var peer_id := 1
var _grid: VBoxContainer

const CARD := Vector2(128, 140)  ## one piece card
const COLUMNS := 6
const ROWS := 2  ## rows of cards you see at once (more = scroll)
const GOOD := Color(0.55, 0.9, 0.45)  ## "you have enough" green
## How much bigger everything is drawn (owner, Nov 22: "the entire menu is quite small and hard to read"): the game
## draws menus at their pixel size, so on a big screen (1440p) they looked tiny. Grows with the screen height.
static var zoom := 1.0
## F9 dev god mode is on: every piece counts as buildable, nothing is missing (owner, Nov 22).
static var free_mode := false
## The building tabs show only pieces made in the chosen material (owner, Nov 22: Rootwood showed a stone gateway).
const MATERIAL_TABS := ["floors", "walls", "roofs", "stairs"]


func _ready() -> void:
	UiKit.panel(self, 16)  # "dwarf workshop" look (owner F187)
	_grid = VBoxContainer.new()
	_grid.add_theme_constant_override("separation", 8)
	add_child(_grid)
	# F708 (like the chest menu's F633): whenever the menu appears, the cursor shows, whoever opened it.
	visibility_changed.connect(func(): if visible: Controls.set_captured(false))


## The 6 big tabs (F709), in order: their name and the piece groups they hold. "legacy" stays hidden.
const TABS := {
	"floors": {name = "Floors", groups = ["foundation", "floor"]},
	"walls": {name = "Walls", groups = ["wall"]},
	"roofs": {name = "Roofs", groups = ["roof"]},
	"stairs": {name = "Stairs", groups = ["around", "support", "mining"]},
	"home": {name = "Home", groups = ["furnish", "decor", "living", "kitchen", "trophies"]},
	"lights": {name = "Lights", groups = ["lights"]},
}
## The small buttons inside the Home tab (one per group).
const HOME_SUBS := {"furnish": "Furniture", "decor": "Decor", "living": "Living", "kitchen": "Kitchen", "trophies": "Trophies"}
static var tab := "floors"  ## remembered while the game runs
static var home_sub := "furnish"
static var only_buildable := false  ## the "Only show what I can build now" switch (off at the start)


## The pieces in one group, in catalog order.
static func pieces_in(group: String) -> Array:
	var out := []
	for id in Pieces.LIST:
		if Pieces.LIST[id].get("group", "") == group:
			out.append(id)
	return out


## The big tab a group sits on ("" = none, like legacy).
static func tab_of(group: String) -> String:
	for t in TABS:
		if group in TABS[t].groups:
			return t
	return ""


## The pieces shown for a tab (Home: only its chosen sub-button's group).
static func tab_pieces(t: String, sub: String = "furnish") -> Array:
	if t == "home":
		return pieces_in(sub)
	var out := []
	for g in TABS[t].groups:
		out += pieces_in(g)
	return out


## You can build it right now: nothing missing and no station problem.
static func can_build(id: String, fam: String, inv: Inventory, lock: String) -> bool:
	return lock == "" and missing(id, fam, inv).is_empty()


## What a faded card says on itself (no hovering, F709): the station lock, or "need 6 more Rootwood Plank".
static func card_note(id: String, fam: String, inv: Inventory, lock: String) -> String:
	if lock != "":
		return lock.get_slice(" (", 0)  # short on the card; the chosen-piece box says the rest
	var m := missing(id, fam, inv)
	for item in m:
		return "need %d more %s" % [m[item], Items.display_name(item)]
	return ""


func refresh() -> void:
	UiKit.clear(_grid)
	var auth := GameAuthority.instance
	var ps: GameAuthority.PlayerState = auth.get_player(peer_id) if auth else null
	if ps == null or mode == null:
		return
	zoom = zoom_for(get_viewport_rect().size.y)
	_grid.add_theme_constant_override("separation", _z(8))
	var inv := ps.inventory
	var where: Vector3 = ps.node.global_position if ps.node else Vector3.ZERO
	var free := Builder.free_build(ps)  # F9: build anything, free (owner, Nov 22)
	var lock_of := func(id: String, fam: String) -> String:
		return auth.builder.station_problem(id, fam, where) if auth.builder and not free else ""
	free_mode = free
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	_grid.add_child(row)
	row.add_child(_material_column(inv))
	row.add_child(_piece_column(inv, lock_of))
	var fam := _family_for(mode.piece)
	row.add_child(_detail_box(mode.piece, fam, inv, lock_of.call(mode.piece, fam)))
	_grid.add_child(_key_hints())
	UiKit.fit(self)  # shrink back to the new content (it used to keep growing with every click)


## A column heading: a gold number in a circle-ish plaque, then the words ("1 Material").
func _heading(parent: Node, number: String, text: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	parent.add_child(h)
	var num := PanelContainer.new()
	num.add_theme_stylebox_override("panel", _cap_style(Color(0.93, 0.7, 0.3), Color(0.35, 0.2, 0.06), 13))
	num.custom_minimum_size = _v(28, 28)
	num.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(num)
	var nl := UiKit.label(num, number, _z(15), UiKit.DARK_TEXT)
	nl.add_theme_font_override("font", UiKit.heading_font())
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var t := UiKit.label(h, text, _z(19), UiKit.AMBER)
	t.add_theme_font_override("font", UiKit.heading_font())
	return h


# ------------------------------------------------------------------ 1 Material

func _material_column(inv: Inventory) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	_heading(col, "1", "Material")
	for f in Pieces.MOSSY_FAMILIES:
		col.add_child(_material_card(f, inv))
	return col


func _material_card(f: String, inv: Inventory) -> Button:
	var b := Button.new()
	b.name = "Material_" + f
	b.custom_minimum_size = _v(230, 62)
	b.focus_mode = Control.FOCUS_NONE
	b.toggle_mode = true
	b.button_pressed = f == mode.family
	var look := UiKit.style("slot_selected" if f == mode.family else "card", 6)
	for st in ["normal", "pressed", "focus", "hover_pressed", "disabled"]:
		b.add_theme_stylebox_override(st, look)
	b.add_theme_stylebox_override("hover", UiKit.style("slot_selected", 6))
	var h := HBoxContainer.new()
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	h.add_theme_constant_override("separation", 10)
	b.add_child(h)
	var ic := _icon(Items.icon(f), _z(44))
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 0)
	h.add_child(v)
	var n := UiKit.label(v, Pieces.FAMILIES[f].name, _z(17), UiKit.TEXT)
	n.add_theme_font_override("font", UiKit.heading_font())
	var have := inv.count_of(f)
	if have > 0:
		UiKit.label(v, "you have %d" % have, _z(13), GOOD)
	else:
		UiKit.label(v, "none yet: %s" % Items.display_name(station_item(f)), _z(13), UiKit.DIM)
		b.modulate = Color(1, 1, 1, 0.6)
	_ignore_mouse(h)
	b.pressed.connect(func(): mode.choose(piece_for_material(mode.piece, f, tab), f); refresh())
	return b


# ------------------------------------------------------------------ 2 Piece

func _piece_column(inv: Inventory, lock_of: Callable) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	var top := _heading(col, "2", "Piece")
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(gap)
	var only := UiKit.dark_button(Button.new(), _z(13))  # glows gold while on
	only.name = "OnlyBuildable"
	only.text = ("[x] " if only_buildable else "[  ] ") + "Only show what I can build now"
	only.toggle_mode = true
	only.button_pressed = only_buildable
	only.toggled.connect(func(on: bool): only_buildable = on; refresh())
	top.add_child(only)
	# The 6 big picture tabs.
	var tabs := HBoxContainer.new()
	tabs.name = "Tabs"
	tabs.add_theme_constant_override("separation", 6)
	col.add_child(tabs)
	for t in TABS:
		var b := UiKit.dark_button(Button.new(), _z(14))
		b.name = "Tab_" + t
		b.text = TABS[t].name
		var all := []
		for g in TABS[t].groups:
			all += pieces_in(g)
		for id in all:  # the first piece with a picture
			b.icon = piece_picture(id, _family_for(id))
			if b.icon:
				break
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", _z(34))
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.custom_minimum_size = Vector2(CARD.x * zoom, _z(64))
		b.toggle_mode = true
		b.button_pressed = t == tab
		var which: String = t
		b.pressed.connect(func(): tab = which; refresh())
		tabs.add_child(b)
	# Home: small sub-buttons (Furniture, Decor, Living, Kitchen, Trophies).
	var rows := ROWS
	if tab == "home":
		var subs := HBoxContainer.new()
		subs.name = "HomeSubs"
		subs.add_theme_constant_override("separation", 4)
		col.add_child(subs)
		for g in HOME_SUBS:
			var s := UiKit.dark_button(Button.new(), _z(12))
			s.text = HOME_SUBS[g]
			s.custom_minimum_size = _v(0, 30)
			s.toggle_mode = true
			s.button_pressed = g == home_sub
			var grp: String = g
			s.pressed.connect(func(): home_sub = grp; refresh())
			subs.add_child(s)
	# The piece cards (scroll when there are more than fit).
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var h := (rows * CARD.y + (rows - 1) * 6 - (36 if tab == "home" else 0)) * zoom
	scroll.custom_minimum_size = Vector2((COLUMNS * CARD.x + (COLUMNS - 1) * 6) * zoom + 14, h)
	col.add_child(scroll)
	var pieces := GridContainer.new()
	pieces.name = "Pieces"
	pieces.columns = COLUMNS
	pieces.add_theme_constant_override("h_separation", 6)
	pieces.add_theme_constant_override("v_separation", 6)
	scroll.add_child(pieces)
	for id in tab_pieces(tab, home_sub):
		if tab in MATERIAL_TABS and not Pieces.allowed(id, mode.family):
			continue
		var fam := _family_for(id)
		var lock: String = lock_of.call(id, fam)
		if only_buildable and not can_build(id, fam, inv, lock):
			continue
		pieces.add_child(_piece_button(id, fam, lock, inv))
	if pieces.get_child_count() == 0:
		UiKit.label(pieces, "Nothing here you can build yet.", _z(14), UiKit.DIM)
	return col


## Switching material: keep the piece if it can be made in it, else the first piece on this tab that can
## (else the first floor piece that can).
static func piece_for_material(piece: String, fam: String, on_tab: String) -> String:
	if Pieces.allowed(piece, fam):
		return piece
	for t in [on_tab, "floors"]:
		for id in tab_pieces(t, home_sub):
			if Pieces.allowed(id, fam):
				return id
	return piece


## The material a piece is shown in: the chosen one if it allows it, else its first.
func _family_for(id: String) -> String:
	return mode.family if Pieces.allowed(id, mode.family) else Pieces.LIST[id].get("families", [mode.family])[0]


## The station item that works this material (for the material cards).
static func station_item(family: String) -> String:
	return Builder.STATION_KIND[Pieces.station_for(family)]


static func _cost_text(c: Dictionary) -> String:
	var parts := []
	for item in c:
		parts.append("%d %s" % [c[item], Items.display_name(item)])  # real names, not codes like "CI" (F130)
	return ", ".join(parts)


## One piece card: picture, name, cost icons (owner F132: pictures, not reading). A green tick if you can build it
## now; faded with what's missing written on the card if not (F709: no hovering needed).
func _piece_button(id: String, fam: String, lock: String, inv: Inventory) -> Button:
	var b := Button.new()
	b.name = "Piece_" + id
	b.custom_minimum_size = CARD * zoom
	b.focus_mode = Control.FOCUS_NONE
	b.toggle_mode = true
	b.button_pressed = id == mode.piece
	var normal := UiKit.style("slot_selected" if id == mode.piece else "card", 6)
	for st in ["normal", "pressed", "focus", "hover_pressed"]:
		b.add_theme_stylebox_override(st, normal)
	b.add_theme_stylebox_override("hover", UiKit.style("slot_selected", 6))
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 7)
	v.add_theme_constant_override("separation", 1)
	b.add_child(v)
	var pic := _icon(piece_picture(id, fam), 0)
	pic.custom_minimum_size = _v(0, 60)
	v.add_child(pic)
	var name_l := UiKit.label(v, Pieces.LIST[id].name, _z(13), UiKit.TEXT)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_l.clip_text = true
	var costs := HBoxContainer.new()
	costs.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(costs)
	var cost := Pieces.cost(id, fam)
	for item in cost:
		costs.add_child(_icon(Items.icon(item), _z(16)))
		UiKit.label(costs, str(cost[item]), _z(13), UiKit.TEXT if inv.count_of(item) >= cost[item] else UiKit.MISSING)
	var ok := can_build(id, fam, inv, lock)
	if ok:
		b.add_child(_tick(Vector2(CARD.x * zoom - _z(26), _z(6))))
	else:
		var note := UiKit.label(v, card_note(id, fam, inv, lock), _z(12), UiKit.MISSING)
		note.name = "Note"
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.max_lines_visible = 2
		note.custom_minimum_size = Vector2((CARD.x - 14) * zoom, 0)
		b.modulate = Color(1, 1, 1, 0.6)
	_ignore_mouse(v)
	b.tooltip_text = needs_text(id, fam, inv) + ("\n" + lock if lock != "" else "")
	b.pressed.connect(func(): mode.choose(id, mode.family); refresh())
	return b


# ------------------------------------------------------------------ 3 The chosen piece

func _detail_box(id: String, fam: String, inv: Inventory, lock: String) -> PanelContainer:
	var box := PanelContainer.new()
	box.name = "Chosen"
	box.add_theme_stylebox_override("panel", UiKit.style("card", 12))
	box.custom_minimum_size = _v(290, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	box.add_child(v)
	var n := UiKit.label(v, Pieces.LIST[id].name, _z(22), UiKit.AMBER)
	n.add_theme_font_override("font", UiKit.heading_font())
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var m := UiKit.label(v, Pieces.FAMILIES[fam].name, _z(14), UiKit.DIM)
	m.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var pic := _icon(piece_picture(id, fam), 0)
	pic.custom_minimum_size = _v(0, 130)
	v.add_child(pic)
	UiKit.divider(v)
	var cost := Pieces.cost(id, fam)
	for item in cost:
		var have := inv.count_of(item)
		_need_row(v, Items.icon(item), Items.display_name(item), "%d / %d" % [have, cost[item]], have >= cost[item])
	var kind := station_item(fam)
	_need_row(v, Items.icon(kind), lock if lock != "" else "%s nearby" % Items.display_name(kind), "", lock == "")
	if free_mode:
		UiKit.label(v, "F9 god mode: free, no station needed", _z(13), GOOD).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(gap)
	var go := PanelContainer.new()
	go.name = "PlaceLine"
	var ok := can_build(id, fam, inv, lock)
	go.add_theme_stylebox_override("panel", UiKit.style("button_gold" if ok else "button_dark", 8))
	v.add_child(go)
	var gl := UiKit.label(go, "Left click in the world to place" if ok else "Still missing something (red above)",
		_z(15) if ok else _z(13), UiKit.DARK_TEXT if ok else UiKit.DIM)
	gl.add_theme_font_override("font", UiKit.heading_font())
	gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return box


## One "needs" line: icon, name, "have / need", and a tick (or red).
func _need_row(parent: Node, icon: Texture2D, text: String, amount: String, ok: bool) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	parent.add_child(h)
	h.add_child(_icon(icon, _z(22)))
	var l := UiKit.label(h, text, _z(14), UiKit.TEXT if ok else UiKit.MISSING)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = _v(150, 0)
	if amount != "":
		UiKit.label(h, amount, _z(14), GOOD if ok else UiKit.MISSING)
	var mark := Control.new()
	mark.custom_minimum_size = _v(18, 18)
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(mark)
	if ok:
		mark.add_child(_tick(Vector2.ZERO))


# ------------------------------------------------------------------ keys

## The key hint row as little key caps (F709).
func _key_hints() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "Keys"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 5)
	var parts := [["Q", "E"], "turn", null, ["Shift"], "+", ["Wheel"], "up / down", null, ["Left click"], "place", null,
		["Right click"], "pick up", null, ["B"], "close"]
	for p in parts:
		if p == null:
			var s := Control.new()
			s.custom_minimum_size = _v(14, 0)
			row.add_child(s)
		elif p is Array:
			for k in p:
				var cap := PanelContainer.new()
				cap.add_theme_stylebox_override("panel", _cap_style(Color(0.9, 0.82, 0.66), Color(0.45, 0.3, 0.14), 4))
				row.add_child(cap)
				var l := UiKit.label(cap, k, _z(13), UiKit.DARK_TEXT)
				l.add_theme_font_override("font", UiKit.heading_font())
		else:
			UiKit.label(row, p, _z(14), UiKit.DIM)
	return row


# ------------------------------------------------------------------ helpers

## The zoom for a screen this tall: 1 at 900 px (the game's base size), 1.6 at 1440 px, never smaller than 1.
static func zoom_for(screen_height: float) -> float:
	return clampf(screen_height / 900.0, 1.0, 3.0)


static func _z(px: float) -> int:
	return roundi(px * zoom)


static func _v(x: float, y: float) -> Vector2:
	return Vector2(x, y) * zoom


## A small rounded box (key caps, the 1 / 2 badges): the kit's frames are too ornate at this size.
static func _cap_style(fill: Color, edge: Color, round: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = edge
	s.set_border_width_all(2)
	s.border_width_bottom = 3  # a little depth, like a real key
	s.set_corner_radius_all(round)
	s.content_margin_left = 7
	s.content_margin_right = 7
	s.content_margin_top = 1
	s.content_margin_bottom = 2
	return s


static func _icon(tex: Texture2D, side: int) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.custom_minimum_size = Vector2(side, side)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## A green tick, drawn (no font needed for the ✔ sign).
static func _tick(at: Vector2) -> Control:
	var c := Control.new()
	c.name = "Tick"
	c.position = at
	c.size = Vector2(18, 18) * zoom
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var pts := PackedVector2Array([Vector2(2, 10) * zoom, Vector2(7, 15) * zoom, Vector2(16, 3) * zoom])
		c.draw_polyline(pts, Color(0.05, 0.1, 0.03, 0.8), 5.0 * zoom, true)
		c.draw_polyline(pts, GOOD, 3.0 * zoom, true))
	return c


## Clicks go through pictures and words to the card underneath.
static func _ignore_mouse(n: Node) -> void:
	if n is Control:
		(n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in n.get_children():
		_ignore_mouse(c)


static func piece_picture(id: String, fam: String) -> Texture2D:
	var path := "res://assets/icons/build/%s__%s.png" % [id, fam]
	return load(path) if ResourceLoader.exists(path) else null


## What's missing to build one (item -> how many more you need).
static func missing(id: String, fam: String, inv: Inventory) -> Dictionary:
	var out := {}
	if free_mode:
		return out
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
	return "\n".join(lines)
