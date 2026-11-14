class_name BoxPanel
extends PanelContainer
## A chest, grave or Builder's Chest. Click a stack to move it to your bag;
## click a stack in your bag to put it in here. "Take all" empties it into your bag.

const SLOT := 52

var box_id := -1
var _title: Label
var _grid: GridContainer
var _status: Label


func _ready() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.06, 0.05, 0.92)
	bg.set_corner_radius_all(10)
	bg.set_content_margin_all(12)
	add_theme_stylebox_override("panel", bg)
	var v := VBoxContainer.new()
	add_child(v)
	var row := HBoxContainer.new()
	v.add_child(row)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 20)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_title)
	var take := Button.new()
	take.text = "Take all"
	take.pressed.connect(func(): GameAuthority.instance.storage.ask_take_all(box_id))
	row.add_child(take)
	_status = Label.new()
	_status.add_theme_color_override("font_color", Color(1.0, 0.8, 0.5))
	v.add_child(_status)
	_grid = GridContainer.new()
	_grid.columns = 8
	v.add_child(_grid)


func open(id: int) -> void:
	box_id = id
	visible = true
	refresh()


func refresh() -> void:
	var st := GameAuthority.instance.storage
	var box := st.get_box(box_id)
	if box.is_empty():
		visible = false
		return
	_title.text = {"chest_small": "Chest", "chest_stone": "Stone Chest", "grave": "Your grave", "builder": "Builder's Chest"}.get(box.kind, "Box")
	_status.text = GameAuthority.instance.builder.site_status(box_id) if box.kind == "builder" else ""
	var inv: Inventory = box.inv
	if _grid.get_child_count() != inv.slots.size():
		for c in _grid.get_children():
			c.queue_free()
		for i in inv.slots.size():
			var b := Button.new()
			b.custom_minimum_size = Vector2(SLOT, SLOT)
			b.pressed.connect(func(): GameAuthority.instance.storage.ask_transfer(box_id, true, i))
			_grid.add_child(b)
	for i in inv.slots.size():
		var b: Button = _grid.get_child(i)
		var s: Dictionary = inv.slots[i]
		b.text = "" if s.is_empty() else "%s\n%d" % [Items.short_label(s.id), s.count]
		b.tooltip_text = "" if s.is_empty() else Items.display_name(s.id)
		b.modulate = Color.WHITE if s.is_empty() else Items.color(s.id).lightened(0.4)


func _process(_d: float) -> void:
	if visible:
		refresh()
