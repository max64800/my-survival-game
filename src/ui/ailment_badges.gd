class_name AilmentBadges
extends HBoxContainer
## Round badges above the health bar for Burning / Chilled / Poisoned / Frozen (owner, Nov 20). A ring round each
## badge shrinks as the effect runs out; "x2" / "x3" shows the stacks.

const SIZE := 44.0
const ICONS := {"burn": "burn", "chill": "chill", "poison": "poison", "frozen": "frozen"}
const RING := {"burn": Color(1.0, 0.6, 0.2), "chill": Color(0.6, 0.8, 1.0), "poison": Color(0.55, 0.95, 0.35), "frozen": Color(0.85, 0.97, 1.0)}

var _badges := {}  ## effect -> Badge


func _init() -> void:
	add_theme_constant_override("separation", 6)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Call every frame with the dwarf's ailments.
func show_ailments(a: Ailments) -> void:
	for k in ICONS:
		var on := a.has(k)
		if on and not _badges.has(k):
			var b := Badge.new()
			b.icon = load("res://assets/icons/status/%s.png" % ICONS[k])
			b.ring = RING[k]
			b.custom_minimum_size = Vector2(SIZE, SIZE)
			add_child(b)
			_badges[k] = b
		elif not on and _badges.has(k):
			_badges[k].queue_free()
			_badges.erase(k)
		if on:
			var full: float = Ailments.FROZEN_TIME if k == "frozen" else Ailments.EFFECTS[k].time
			_badges[k].set_state(clampf(a.active[k] / full, 0.0, 1.0), a.stacks_of(k))


class Badge:
	extends Control
	var icon: Texture2D
	var ring := Color.WHITE
	var _left := 1.0
	var _stacks := 0

	func set_state(left: float, stacks: int) -> void:
		if not is_equal_approx(left, _left) or stacks != _stacks:
			_left = left
			_stacks = stacks
			queue_redraw()

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5 - 2.0
		if icon:
			draw_texture_rect(icon, Rect2(c - Vector2.ONE * (r - 3.0), Vector2.ONE * (r - 3.0) * 2.0), false)
		draw_arc(c, r, 0.0, TAU, 48, Color(0, 0, 0, 0.55), 4.0, true)  # the empty track
		draw_arc(c, r, -PI * 0.5, -PI * 0.5 + TAU * _left, 48, ring, 3.0, true)  # time left, clockwise from the top
		if _stacks > 1:
			var font := get_theme_default_font()
			var t := "x%d" % _stacks
			var at := Vector2(size.x - 16.0, size.y - 1.0)
			draw_string_outline(font, at, t, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color.BLACK)
			draw_string(font, at, t, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
