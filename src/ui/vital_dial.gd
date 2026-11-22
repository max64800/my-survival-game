extends Control
## A small round dial for hunger or thirst (F229): a bronze ring, and inside it a coloured
## "liquid" that sinks as you get hungry or thirsty, with a little picture on top
## (a painted stew bowl for food, a painted drop for water, F638). Below a quarter it gently pulses.

var kind := "hunger"  ## "hunger" or "thirst"
var value := 100.0
var max_value := 100.0
var _t := 0.0
var _tip: PanelContainer  ## "Hunger 62 / 100" while the mouse is over the dial (owner F240)
var _tip_text: Label

const RING := Color(0.62, 0.45, 0.24)
const RING_DARK := Color(0.25, 0.15, 0.08)
const BACK := Color(0.09, 0.06, 0.05, 0.92)
const PICTURES := {"hunger": preload("res://assets/icons/hud/hunger.png"), "thirst": preload("res://assets/icons/hud/thirst.png")}


func _init(p_kind: String = "hunger") -> void:
	kind = p_kind
	custom_minimum_size = Vector2(46, 46)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_tip = PanelContainer.new()
	_tip.add_theme_stylebox_override("panel", UiKit.style("tooltip", 8, 14))
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip.visible = false
	_tip.top_level = true  # drawn above everything, not squeezed by the row the dial sits in
	add_child(_tip)
	_tip_text = UiKit.label(_tip, "", 16, UiKit.TEXT)
	_tip_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mouse_entered.connect(func(): _tip.visible = true; _update_tip())
	mouse_exited.connect(func(): _tip.visible = false)


func _update_tip() -> void:
	_tip_text.text = "%s  %d / %d" % ["Hunger" if kind == "hunger" else "Thirst", roundi(value), roundi(max_value)]
	_tip.reset_size()
	_tip.global_position = global_position + Vector2((size.x - _tip.size.x) * 0.5, -_tip.size.y - 8.0)


func set_value(v: float) -> void:
	if not is_equal_approx(v, value):
		value = v
		queue_redraw()
		if _tip.visible:
			_update_tip()


func _process(delta: float) -> void:
	if _frac() < 0.25:
		_t += delta
		queue_redraw()


func _frac() -> float:
	return clampf(value / maxf(max_value, 1.0), 0.0, 1.0)


func _fill_color() -> Color:
	return Color(0.9, 0.55, 0.22) if kind == "hunger" else Color(0.3, 0.58, 1.0)


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5
	var k := r / 23.0  # rings grow with the dial
	draw_circle(c, r, RING_DARK)
	draw_circle(c, r - 2.0 * k, RING)
	draw_circle(c, r - 4.5 * k, BACK)
	# The liquid: the part of the inner circle below the level line.
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
		var col := _fill_color()
		if f < 0.25:
			col = col.lerp(Color(1, 0.3, 0.25), 0.5 + 0.5 * sin(_t * 5.0))
		draw_colored_polygon(pts, col)
	_draw_picture(c, r)


## The little painted picture in the middle (ChatGPT, F638): about two thirds of the dial.
func _draw_picture(c: Vector2, r: float) -> void:
	var tex: Texture2D = PICTURES.get(kind)
	if tex == null:
		return
	var side := r * 1.3
	draw_texture_rect(tex, Rect2(c - Vector2(side, side) * 0.5, Vector2(side, side)), false)
