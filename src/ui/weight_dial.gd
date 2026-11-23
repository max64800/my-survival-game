extends "res://src/ui/vital_dial.gd"
## Carry weight dial (owner, Nov 23, F793): sits centred above the hunger and thirst dials.
## The fill RISES as your load gets heavier (full = the overloaded line). Green = fine,
## yellow = heavy (a bit slower), red = overloaded (slow plod). Red gently pulses.
## Fed from the local dwarf's `carry` ({weight, heavy, max, load}) by hud.gd _show_carry.

const GREEN := Color(0.42, 0.72, 0.3)
const YELLOW := Color(0.95, 0.78, 0.25)
const RED := Color(0.9, 0.25, 0.2)
const WEIGHT_PICTURE := preload("res://assets/icons/hud/weight.png")

var heavy := ItemWeights.HEAVY
var load_state := ItemWeights.Load.LIGHT


func _init(_p_kind: String = "weight") -> void:
	super("weight")
	value = 0.0
	max_value = ItemWeights.MAX


## The dwarf's carry dictionary (empty = nothing yet).
func set_carry(c: Dictionary) -> void:
	if c.is_empty():
		return
	var new_load: int = c.get("load", ItemWeights.Load.LIGHT)
	var changed := new_load != load_state or not is_equal_approx(float(c.max), max_value) or not is_equal_approx(float(c.heavy), heavy)
	load_state = new_load
	heavy = float(c.heavy)
	max_value = float(c.max)
	if changed:
		queue_redraw()
	set_value(float(c.weight))


func _update_tip() -> void:
	var word: String = ["", "  Heavy: slower", "  OVERLOADED"][load_state]
	_tip_text.text = "Weight  %s / %s%s" % [ItemWeights.pretty(value), ItemWeights.pretty(max_value), word]
	_tip.reset_size()
	_tip.global_position = global_position + Vector2((size.x - _tip.size.x) * 0.5, -_tip.size.y - 8.0)


func _process(delta: float) -> void:
	if load_state == ItemWeights.Load.OVERLOADED:
		_t += delta
		queue_redraw()


func _frac() -> float:
	# Overloaded still shows a full dial (the red tells the rest).
	return 1.0 if load_state == ItemWeights.Load.OVERLOADED else clampf(value / maxf(max_value, 1.0), 0.0, 1.0)


func _fill_color() -> Color:
	match load_state:
		ItemWeights.Load.OVERLOADED:
			return RED.lerp(Color(1.0, 0.5, 0.4), 0.5 + 0.5 * sin(_t * 5.0))
		ItemWeights.Load.HEAVY:
			return YELLOW
	return GREEN


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5
	var k := r / 23.0
	draw_circle(c, r, RING_DARK)
	draw_circle(c, r - 2.0 * k, RING)
	draw_circle(c, r - 4.5 * k, BACK)
	var ri := r - 5.5 * k
	var f := _frac()
	if f > 0.0:
		var level := c.y + ri - 2.0 * ri * f
		var half := sqrt(maxf(0.0, ri * ri - pow(level - c.y, 2.0)))
		var pts := PackedVector2Array()
		for i in 40:
			var a := TAU * i / 40.0
			var p := c + Vector2(cos(a), sin(a)) * ri
			if p.y < level:
				p = Vector2(clampf(p.x, c.x - half, c.x + half), level)
			pts.append(p)
		draw_colored_polygon(pts, _fill_color())
	# A thin mark where "heavy" starts, so you can see it coming.
	var hy := c.y + ri - 2.0 * ri * clampf(heavy / maxf(max_value, 1.0), 0.0, 1.0)
	var hh := sqrt(maxf(0.0, ri * ri - pow(hy - c.y, 2.0)))
	draw_line(Vector2(c.x - hh, hy), Vector2(c.x + hh, hy), Color(1, 0.9, 0.6, 0.55), maxf(1.0, k))
	var side := r * 1.3
	draw_texture_rect(WEIGHT_PICTURE, Rect2(c - Vector2(side, side) * 0.5, Vector2(side, side)), false)
