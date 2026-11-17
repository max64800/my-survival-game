extends Control
## A small round dial for hunger or thirst (F229): a bronze ring, and inside it a coloured
## "liquid" that sinks as you get hungry or thirsty, with a little picture on top
## (a mushroom for food, a drop for water). Below a quarter it gently pulses.

var kind := "hunger"  ## "hunger" or "thirst"
var value := 100.0
var max_value := 100.0
var _t := 0.0
var _tip: PanelContainer  ## "Hunger 62 / 100" while the mouse is over the dial (owner F240)
var _tip_text: Label

const RING := Color(0.62, 0.45, 0.24)
const RING_DARK := Color(0.25, 0.15, 0.08)
const BACK := Color(0.09, 0.06, 0.05, 0.92)


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


## The little picture in the middle, dark with a light edge so it reads on any fill.
func _draw_picture(c: Vector2, r: float) -> void:
	var s := r / 23.0
	var ink := Color(0.12, 0.07, 0.04)
	var edge := Color(1.0, 0.92, 0.75, 0.9)
	if kind == "hunger":
		# A mushroom: round cap and a short stem.
		var cap := PackedVector2Array()
		for i in 13:
			var a := PI + PI * i / 12.0
			cap.append(c + Vector2(cos(a) * 11.0, sin(a) * 9.0 + 1.0) * s)
		for pass_i in 2:
			var grow := 1.6 * s if pass_i == 0 else 0.0
			var col := edge if pass_i == 0 else ink
			var big := PackedVector2Array()
			for p in cap:
				big.append(c + (p - c) * (1.0 + grow / (10.0 * s)))
			draw_colored_polygon(big, col)
			draw_rect(Rect2(c + Vector2(-4.0 * s - grow * 0.6, 0.0), Vector2(8.0 * s + grow * 1.2, 10.0 * s + grow * 0.6)), col)
	else:
		# A water drop: pointed top, round bottom.
		for pass_i in 2:
			var grow := 1.6 * s if pass_i == 0 else 0.0
			var col := edge if pass_i == 0 else ink
			var pts := PackedVector2Array([c + Vector2(0, -12.0 * s - grow)])
			for i in 17:
				var a := -0.15 * PI + 1.3 * PI * i / 16.0
				pts.append(c + Vector2(cos(a), sin(a)) * (7.5 * s + grow) + Vector2(0, 3.0 * s))
			draw_colored_polygon(pts, col)
