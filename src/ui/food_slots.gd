class_name FoodSlots
extends HBoxContainer
## The foods and drink you have eaten, as picture slots next to the health bar (owner, Nov 23, F426):
## 2 food slots (3 with Cooking ★75) + 1 drink slot. A gold ring round each picture empties as the meal wears off,
## the minutes left sit under it, and empty slots stay faded so you see you can still eat. Hover = what it does.

const SIZE := 50.0
const FOOD_RING := Color(1.0, 0.78, 0.3)
const DRINK_RING := Color(0.45, 0.8, 1.0)

var _food: Array[Slot] = []
var _drink: Array[Slot] = []
var _gap: Control


func _init() -> void:
	add_theme_constant_override("separation", 6)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gap = Control.new()  # a little space between the foods and the drink
	_gap.custom_minimum_size = Vector2(4, 0)
	_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE


## Call every frame with the dwarf's body.
func show_buffs(v: Vitals) -> void:
	_fit(_food, v.food_slots(), false)
	_fit(_drink, Vitals.DRINK_SLOTS, true)
	var foods := []
	var drinks := []
	for b in v.buffs:
		(drinks if Foods.is_drink(b.id) else foods).append(b)
	for i in _food.size():
		_food[i].show_buff(foods[i] if i < foods.size() else {})
	for i in _drink.size():
		_drink[i].show_buff(drinks[i] if i < drinks.size() else {})


## How many slots of one sort there are right now (the 3rd food slot comes with Cooking ★75).
func slot_count(drink: bool) -> int:
	return (_drink if drink else _food).size()


## The slots, for tests: [{id, left}] in order, foods first ({} = empty).
func shown() -> Array:
	var out := []
	for s in _food + _drink:
		out.append({} if s.id == "" else {id = s.id, left = s.left})
	return out


func _fit(list: Array[Slot], n: int, drink: bool) -> void:
	while list.size() < n:
		var s := Slot.new()
		s.drink = drink
		s.ring = DRINK_RING if drink else FOOD_RING
		s.custom_minimum_size = Vector2(SIZE, SIZE + 14.0)
		list.append(s)
		add_child(s)
	while list.size() > n:
		list.pop_back().queue_free()
	# order: foods, gap, drink
	var at := 0
	for s in _food:
		move_child(s, at)
		at += 1
	if _gap.get_parent() == null:
		add_child(_gap)
	move_child(_gap, at)


class Slot:
	extends Control
	var drink := false
	var ring := Color.WHITE
	var id := ""
	var left := 0.0  ## 0..1 of its time
	var _seconds := 0
	var _icon: Texture2D

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS  # hover shows the tooltip while the bag is open

	func show_buff(b: Dictionary) -> void:
		var new_id: String = b.get("id", "")
		var secs: int = ceili(b.get("time_left", 0.0))
		var full := Foods.minutes_of(new_id) * 60.0
		var new_left := clampf(secs / full, 0.0, 1.0) if full > 0.0 else 0.0
		if new_id != id:
			id = new_id
			_icon = Items.icon(id) if id != "" else null
			tooltip_text = _tip()
		if secs != _seconds or not is_equal_approx(new_left, left):
			_seconds = secs
			left = new_left
			if id != "":
				tooltip_text = _tip()
			queue_redraw()

	func _tip() -> String:
		if id == "":
			return "Empty drink slot: drink something brewed to fill it." if drink else "Empty food slot: eat a cooked meal to fill it."
		var t := Items.display_name(id)
		var halves := Foods.heart_halves(Foods.buff_of(id).get("regen", 0.0))
		if halves > 0:
			t += "\n• Healing " + ("½♥" if halves == 1 else "♥".repeat(halves / 2) + ("½" if halves % 2 else ""))
		for line in Foods.effect_lines(id):
			if not line.begins_with("lasts"):
				t += "\n• " + line
		t += "\n%d:%02d left" % [_seconds / 60, _seconds % 60]
		return t

	func _draw() -> void:
		var c := Vector2(size.x * 0.5, SIZE * 0.5)
		var r := SIZE * 0.5 - 2.0
		draw_circle(c, r, Color(0.08, 0.06, 0.04, 0.55 if id != "" else 0.3))
		if id == "":
			draw_arc(c, r, 0.0, TAU, 48, Color(1, 1, 1, 0.18), 2.0, true)  # faded: you can still eat
			var font := get_theme_default_font()
			var mark := "drink" if drink else "food"  # (plain words: the game font has no emoji)
			var w := font.get_string_size(mark, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			draw_string(font, c + Vector2(-w * 0.5, 4), mark, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.3))
			return
		if _icon:
			var h := r - 4.0
			draw_texture_rect(_icon, Rect2(c - Vector2.ONE * h, Vector2.ONE * h * 2.0), false)
		draw_arc(c, r, 0.0, TAU, 48, Color(0, 0, 0, 0.6), 5.0, true)  # the empty track
		draw_arc(c, r, -PI * 0.5, -PI * 0.5 + TAU * left, 48, ring, 3.5, true)  # time left, clockwise from the top
		var font := get_theme_default_font()
		var t := "%dm" % ceili(_seconds / 60.0) if _seconds >= 60 else "%ds" % _seconds
		var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		var at := Vector2((size.x - tw) * 0.5, SIZE + 12.0)
		draw_string_outline(font, at, t, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, Color.BLACK)
		draw_string(font, at, t, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
