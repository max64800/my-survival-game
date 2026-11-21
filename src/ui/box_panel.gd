class_name BoxPanel
extends PanelContainer
## A chest, grave or Builder's Chest. Click a stack to move it to your bag;
## click a stack in your bag to put it in here. "Take all" empties it into your bag.

const SLOT := 52

signal emptied  ## you took the last thing out (owner, Nov 18: then the menu closes by itself)

var box_id := -1
var _had := false  ## it had something in it (an empty chest you opened to fill stays open)
var _title: Label
var _grid: GridContainer
var _status: Label
var _ways: HBoxContainer  ## pictures of what goes in: the two ways (an untouched Rebuilding Chest, F560) or what's still missing (F578)
var _ways_for := -1  ## which chest the pictures are of (they're built once, not every frame)


func _ready() -> void:
	UiKit.panel(self)  # "dwarf workshop" look (owner F187)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	add_child(v)
	_title = UiKit.title(v, "Chest")
	_status = UiKit.label(v, "", 14, UiKit.AMBER)
	_ways = HBoxContainer.new()
	_ways.add_theme_constant_override("separation", 12)
	_ways.alignment = BoxContainer.ALIGNMENT_CENTER
	_ways.visible = false
	v.add_child(_ways)
	_grid = GridContainer.new()
	_grid.columns = 8
	v.add_child(_grid)
	var take := UiKit.gold_button(Button.new())
	take.text = "Take all"
	take.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	take.custom_minimum_size = Vector2(150, 0)
	take.pressed.connect(func(): GameAuthority.instance.storage.ask_take_all(box_id))
	v.add_child(take)


func open(id: int) -> void:
	if visible and id != box_id:
		_shut_lid()
	if not visibility_changed.is_connected(_on_visibility):
		visibility_changed.connect(_on_visibility)
	box_id = id
	visible = true
	_had = false
	refresh()
	var box := GameAuthority.instance.storage.get_box(box_id)
	_had = not box.is_empty() and has_items(box.inv)


## The menu closed: the chest's lid drops shut (owner F345).
func _on_visibility() -> void:
	if not visible:
		_shut_lid()


func _shut_lid() -> void:
	if GameAuthority.instance == null or box_id < 0:
		return
	var box := GameAuthority.instance.storage.get_box(box_id)
	if not box.is_empty() and is_instance_valid(box.node):
		ChestOpen.close(box.node)


## Is there anything in it?
static func has_items(inv: Inventory) -> bool:
	for s in inv.slots:
		if not (s as Dictionary).is_empty() and String((s as Dictionary).get("id", "")) != "":
			return true
	return false


func refresh() -> void:
	var st := GameAuthority.instance.storage
	var box := st.get_box(box_id)
	if box.is_empty():
		visible = false
		return
	_title.text = {"barrel": "Barrel", "chest_small": "Chest", "chest_stone": "Stone Chest", "grave": "Your grave", "chest_loot": "Old Chest", "builder": "Builder's Chest", "rebuild": "Rebuilding Chest"}.get(box.kind,
		Pieces.LIST[box.kind].name if Pieces.LIST.has(box.kind) else "Box")
	_status.text = GameAuthority.instance.builder.site_status(box_id) if box.kind in ["builder", "rebuild"] else ""
	var intro: bool = box.kind == "rebuild" and _status.text == ""
	if intro:  # not started yet: one short line and a picture of each tower (F350, F411)
		_status.text = GameAuthority.instance.builder.ruin_intro(box_id)
		if _ways_for != box_id:
			_show_ways()
	elif box.kind in ["builder", "rebuild"]:
		_show_missing(GameAuthority.instance.builder.still_needed(box_id))
	_ways.visible = _ways.get_child_count() > 0 and box.kind in ["builder", "rebuild"]
	var inv: Inventory = box.inv
	if visible and _had and not has_items(inv):
		_had = false
		emptied.emit.call_deferred()  # (all taken: the menu closes)
	if _grid.get_child_count() != inv.slots.size():
		UiKit.clear(_grid)
		for i in inv.slots.size():
			var b := Button.new()
			b.custom_minimum_size = Vector2(SLOT, SLOT)
			b.focus_mode = Control.FOCUS_NONE
			b.expand_icon = true
			b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			b.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
			b.alignment = HORIZONTAL_ALIGNMENT_RIGHT
			b.add_theme_constant_override("icon_max_width", SLOT - 14)
			b.add_theme_font_size_override("font_size", 13)
			for look in ["normal", "pressed", "disabled", "focus"]:
				b.add_theme_stylebox_override(look, UiKit.style("slot", 5))
			b.add_theme_stylebox_override("hover", UiKit.style("slot_selected", 5))
			b.pressed.connect(func(): GameAuthority.instance.storage.ask_transfer(box_id, true, i))
			_grid.add_child(b)
	for i in inv.slots.size():
		var b: Button = _grid.get_child(i)
		var s: Dictionary = inv.slots[i]
		var tex: Texture2D = null if s.is_empty() else Items.icon(s.id)
		b.icon = tex
		if s.is_empty():
			b.text = ""
		elif tex == null:  # no picture yet: the short name, like the bag does
			b.text = "%s\n%d" % [Items.short_label(s.id), s.count]
		else:
			b.text = "" if int(s.count) <= 1 else str(s.count)
		b.tooltip_text = "" if s.is_empty() else Items.display_name(s.id)


## The Rebuilding Chest before it starts (owner F560, said 3×: "only show, in pictures, what you need for the two
## options. That's it."): two cards, each just the pictures and counts of what that way needs.
func _show_ways() -> void:
	_ways_for = box_id
	_missing_sig = ""
	UiKit.clear(_ways)
	var choices: Array[Dictionary] = GameAuthority.instance.builder.ruin_choices(box_id)
	for n in choices.size():
		if n > 0:
			UiKit.label(_ways, "or", 18, UiKit.AMBER).size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var w: Dictionary = choices[n]
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UiKit.style("slot", 8))
		_ways.add_child(card)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 6)
		card.add_child(col)
		UiKit.label(col, "Wood" if w.wood else "Stone", 16, UiKit.AMBER).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_need_row(col, w.need)


## F578: once it's being built, the pictures of what still has to go in (rebuilt only when that changes).
var _missing_sig := ""
func _show_missing(need: Dictionary) -> void:
	var sig := str(box_id) + str(need)
	if sig == _missing_sig:
		return
	_missing_sig = sig
	_ways_for = -1
	UiKit.clear(_ways)
	if need.is_empty():
		return
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	_ways.add_child(col)
	UiKit.label(col, "Still to put in:", 15, UiKit.AMBER).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_need_row(col, need)


## A row of item pictures, each with its count under it.
static func _need_row(parent: Control, need: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(row)
	for item in need:
		var cell := VBoxContainer.new()
		cell.tooltip_text = Items.display_name(item)
		cell.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(cell)
		var tex := Items.icon(item)
		if tex:
			var pic := TextureRect.new()
			pic.texture = tex
			pic.custom_minimum_size = Vector2(48, 48)
			pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			pic.tooltip_text = Items.display_name(item)
			cell.add_child(pic)
		else:
			UiKit.label(cell, Items.short_label(item), 13, UiKit.TEXT)
		UiKit.label(cell, "%d" % int(need[item]), 16, UiKit.TEXT).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _process(_d: float) -> void:
	if visible:
		refresh()
