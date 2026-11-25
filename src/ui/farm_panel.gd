class_name FarmPanel
extends PanelContainer
## F892 (owner, Nov 25: "open the plot's menu, put a seed in, and see that plant growing on the plot"): E at a Farm
## Plot opens this beside your bag. Empty plot: what you can plant shows as buttons (picture, name, how many you
## have); click one to plant it and the menu closes so you see it on the plot. Planted: its picture, no timer.
## Ready: a "Pick" button (E at a ready plot picks it straight away too).

signal done  ## you planted or picked: back to the game

const BUTTON := Vector2(170, 64)

var station: Station
var _info: Label
var _row: HFlowContainer
var _sig := "-"


func _ready() -> void:
	UiKit.panel(self)
	custom_minimum_size = Vector2(380, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	add_child(v)
	UiKit.title(v, "Farm Plot")
	_info = UiKit.label(v, "", 15, UiKit.TEXT)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.custom_minimum_size = Vector2(340, 0)
	_row = HFlowContainer.new()
	_row.add_theme_constant_override("h_separation", 8)
	_row.add_theme_constant_override("v_separation", 8)
	v.add_child(_row)


func open(st: Station) -> void:
	station = st
	_sig = "-"
	visible = true
	_refresh()


func _process(_delta: float) -> void:
	if visible:
		_refresh()


## What you could plant from your bag: item -> how many.
static func plantable(inv: Inventory) -> Dictionary:
	var have := {}
	for id in Station.CROPS.keys() + Station.SEEDS.keys():
		if Station.can_plant(id) and inv.count_of(id) > 0:
			have[id] = inv.count_of(id)
	return have


func _refresh() -> void:
	var auth := GameAuthority.instance
	if station == null or not is_instance_valid(station) or auth == null:
		visible = false
		return
	var me := auth.get_player(auth.local_peer_id())
	if me == null:
		return
	var have := plantable(me.inventory)
	var sig := "%s|%s|%s" % [station.crop, station.crop_ripe(), have]
	if sig == _sig:
		return
	_sig = sig
	for c in _row.get_children():
		c.queue_free()
	if station.crop_ripe():
		_info.text = "Your %s is ready!" % Items.display_name(station.crop)
		_button(station.crop, "Pick", func() -> void: _ask(""))
	elif station.crop != "":
		_info.text = "%s planted. Watch it grow on the plot." % Items.display_name(station.crop)
		var pic := TextureRect.new()
		pic.texture = Items.icon(station.crop)
		pic.custom_minimum_size = Vector2(64, 64)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_row.add_child(pic)
	elif have.is_empty():
		_info.text = "You have nothing to plant. Glowcaps, Hollowcaps, Bellcaps and Firecaps grow here, and Tuber Seeds grow Root Tubers."
	else:
		_info.text = "Pick what to plant:"
		for id in have:
			_button(id, "%s  ×%d" % [Items.display_name(id), have[id]], func() -> void: _ask(id))


func _button(id: String, text: String, on_press: Callable) -> void:
	var b := UiKit.gold_button(Button.new(), 15)
	b.name = id
	b.text = text
	b.icon = Items.icon(id)
	b.expand_icon = false
	b.add_theme_constant_override("icon_max_width", 44)
	b.custom_minimum_size = BUTTON
	b.pressed.connect(on_press)
	_row.add_child(b)


func _ask(seed_item: String) -> void:
	GameAuthority.instance.ask_farm(station.station_id, seed_item)
	done.emit()
