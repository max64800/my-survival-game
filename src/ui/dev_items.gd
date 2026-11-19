class_name DevItems
extends PanelContainer
## The owner's item menu (F8, Nov 19: "a menu where if I click an item, it just gets into my inventory so I don't
## have to craft it"). Every item in the game with its picture; click = 1, right-click = a full stack. Type to search.
## Dev builds only (like the P dev menu and F6/F7), never in a shipped game. It gives straight to the host's own bag.

var _grid: GridContainer
var _search: LineEdit
var _info: Label


func _ready() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.04, 0.12, 0.95)  # purple, like the P dev menu: clearly not part of the real game
	bg.set_corner_radius_all(10)
	bg.set_content_margin_all(14)
	add_theme_stylebox_override("panel", bg)
	custom_minimum_size = Vector2(760, 520)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	UiKit.label(box, "Dev: get any item (F8)  ·  click = 1, right-click = a full stack", 16, UiKit.AMBER)
	_search = LineEdit.new()
	_search.placeholder_text = "Search (bolt, crossbow, copper…)"
	_search.text_changed.connect(func(_t: String) -> void: refresh())
	box.add_child(_search)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 10
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(_grid)
	_info = UiKit.label(box, "", 14, UiKit.DIM)
	refresh()


## Every item id, sorted by name, filtered by the search box.
static func all_ids(filter: String = "") -> Array:
	var ids := []
	var f := filter.strip_edges().to_lower()
	for id in Items._data():
		if f == "" or String(id).to_lower().contains(f) or Items.display_name(id).to_lower().contains(f):
			ids.append(id)
	ids.sort_custom(func(a, b): return Items.display_name(a) < Items.display_name(b))
	return ids


func refresh() -> void:
	if _grid == null:
		return
	for c in _grid.get_children():
		c.queue_free()
	for id in all_ids(_search.text):
		var b := Button.new()
		b.custom_minimum_size = Vector2(64, 64)
		b.tooltip_text = Items.display_name(id)
		b.icon = Items.icon(id)
		b.expand_icon = true
		if b.icon == null:
			b.text = Items.display_name(id).left(6)
		b.button_mask = MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_RIGHT
		b.gui_input.connect(func(e: InputEvent) -> void:
			if e is InputEventMouseButton and e.pressed:
				var n := Items.stack_size(id) if e.button_index == MOUSE_BUTTON_RIGHT else 1
				_info.text = give(id, n))
		_grid.add_child(b)


## Puts `count` of `id` straight into the local dwarf's bag. Returns a line for the menu.
static func give(id: String, count: int) -> String:
	var auth := GameAuthority.instance
	if auth == null or not auth.is_host():
		return "Only the host can use this menu."
	var ps: GameAuthority.PlayerState = auth.get_player(auth.local_peer_id())
	if ps == null:
		return ""
	var left: int = ps.inventory.add(id, count)
	if left >= count:
		return "Your bag is full."
	return "+%d %s" % [count - left, Items.display_name(id)] + ("  (bag full: %d didn't fit)" % left if left > 0 else "")
