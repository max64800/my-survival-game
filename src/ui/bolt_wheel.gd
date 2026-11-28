class_name BoltWheel
extends Control
## F956 (owner, Nov 28): "holding R when the crossbow is already loaded opens a wheel of your bolt types".
## A ring in the middle of the screen: one slice per bolt type you carry (picture + how many), the one the mouse
## points at lit up, its name in the middle. DwarfFight decides what opens it and what is picked; this only draws.

const RADIUS := 150.0  ## px, to the middle of the slices
const INNER := 70.0
const OUTER := 220.0
const ICON := 56.0

var choices: Array = []  ## bolt ids, clockwise from the top
var lit := -1  ## the slice the mouse points at
var chosen := ""  ## the bolt in use now (a gold ring)
var counts := {}


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false


func show_wheel(ids: Array, have: Dictionary, now: String, point: int) -> void:
	choices = ids
	counts = have
	chosen = now
	lit = point
	visible = true
	queue_redraw()


## Which slice a mouse push of `v` (px) points at: -1 while it's still near the middle.
static func slice_of(v: Vector2, n: int) -> int:
	if n <= 0 or v.length() < 24.0:
		return -1
	var ang := fposmod(atan2(v.x, -v.y) + PI / n, TAU)  # 0 = straight up, clockwise
	return int(ang / (TAU / n)) % n


func _draw() -> void:
	var c := size * 0.5
	var n := choices.size()
	if n == 0:
		return
	draw_circle(c, OUTER, Color(0.05, 0.035, 0.025, 0.55))
	var step := TAU / n
	for i in n:
		var a0 := -PI / 2.0 + step * (i - 0.5)
		var pts := PackedVector2Array()
		for k in 17:
			pts.append(c + Vector2.from_angle(a0 + step * k / 16.0) * (OUTER - 6.0))
		for k in 17:
			pts.append(c + Vector2.from_angle(a0 + step * (16 - k) / 16.0) * INNER)
		var fill := Color(0.55, 0.38, 0.16, 0.75) if i == lit else Color(0.16, 0.11, 0.07, 0.8)
		draw_colored_polygon(pts, fill)
		draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.75, 0.58, 0.32, 0.8), 2.0, true)
		var mid := c + Vector2.from_angle(a0 + step * 0.5) * RADIUS
		var tex := Items.icon(choices[i])
		if tex:
			draw_texture_rect(tex, Rect2(mid - Vector2.ONE * ICON * 0.5, Vector2.ONE * ICON), false)
		if choices[i] == chosen:
			draw_arc(mid, ICON * 0.62, 0.0, TAU, 32, UiKit.AMBER, 3.0, true)
		var font := get_theme_default_font()
		var txt := "%d" % counts.get(choices[i], 0)
		draw_string(font, mid + Vector2(-20, ICON * 0.5 + 18), txt, HORIZONTAL_ALIGNMENT_CENTER, 40, 16, UiKit.TEXT)
	var name_id: String = choices[lit] if lit >= 0 else chosen
	var font := UiKit.heading_font()
	draw_string(font, c + Vector2(-INNER, 6), Items.display_name(name_id), HORIZONTAL_ALIGNMENT_CENTER, INNER * 2.0, 15,
		UiKit.AMBER)
