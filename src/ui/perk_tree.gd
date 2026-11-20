class_name PerkTree
extends Control
## The middle of the skills window (owner's mock-up, Nov 19): the perk tree drawn on the carved hall.
## The Level circle sits in the carved ring; the 4 branches grow out of it: Bones up, Fists right,
## Hands down, Heart left. Round knobs = passive perks, diamonds = active ones (Z / G / T), ★ = the
## branch's final perk. Lines turn gold once the perk at their end has a point. Click a knob to see it.
## Only a picture of Progression.PERKS: every rule stays in Progression / GameAuthority.

signal picked(id: String)

const BACKGROUND := "res://assets/ui/skills_background.jpg"
const KNOB_SHADER := preload("res://src/ui/perk_knob.gdshader")
## Where the carved ring is in the picture (50.2% across, 45.5% down), and how wide the picture is
## in tree units (the tree is about 1110 units across).
const FACE := Vector2(0.502, 0.4554)
const BG_WIDTH := 2300.0
const VIEW := 1110.0
const DIRS := {toughness = Vector2(0, -1), fighting = Vector2(1, 0), utility = Vector2(0, 1), together = Vector2(-1, 0)}
const COLORS := {toughness = Color("a9aeb4"), fighting = Color("cf5f45"), utility = Color("e0a83a"), together = Color("86b25e")}
const GOLD := Color("e8a93c")
const GOLD_LIGHT := Color("f6cf7a")
const LINE_DARK := Color("3a2c1c")
const LOCKED_RING := Color("3b2e20")
const HUB_R := 56.0

var progress: Progression
var selected := ""
var names := {}  ## branch id -> name shown (Bones, Fists...)
var background: Texture2D
var _spots := {}
var _knobs := {}
var _vignette: GradientTexture2D


func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	if ResourceLoader.exists(BACKGROUND):
		background = load(BACKGROUND)
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0.0))
	g.set_color(1, Color(0, 0, 0, 0.5))
	_vignette = GradientTexture2D.new()
	_vignette.gradient = g
	_vignette.fill = GradientTexture2D.FILL_RADIAL
	_vignette.fill_from = Vector2(0.5, 0.5)
	_vignette.fill_to = Vector2(1.05, 0.5)
	_spots = layout()
	resized.connect(_place_knobs)


## Each perk's spot in tree units, the Level circle at (0, 0). Depth = how many steps from the ring;
## the first perks after a branch's start fan out into 3 lanes and the rest keep their lane.
static func layout() -> Dictionary:
	var depth := {}
	var lane := {}
	var kids := {}
	for id in Progression.PERKS:
		var need: String = Progression.PERKS[id][2]
		if need != "":
			if not kids.has(need):
				kids[need] = []
			kids[need].append(id)
	for id in Progression.PERKS:
		if Progression.PERKS[id][2] == "":
			depth[id] = 1
			lane[id] = 0.0
			_spread(id, kids, depth, lane, true)
	var out := {}
	for id in depth:
		var dir: Vector2 = DIRS[Progression.PERKS[id][0]]
		var r := 105.0 + (float(depth[id]) - 1.0) * 90.0
		var side := float(lane[id]) * 92.0
		out[id] = Vector2(dir.x * r - dir.y * side, dir.y * r + dir.x * side)
	return out


static func _spread(id: String, kids: Dictionary, depth: Dictionary, lane: Dictionary, first: bool) -> void:
	var list: Array = kids.get(id, [])
	for i in list.size():
		var k: String = list[i]
		depth[k] = depth[id] + 1
		var off := i - (list.size() - 1) * 0.5
		lane[k] = lane[id] + (off if first else off * 0.5)
		_spread(k, kids, depth, lane, false)


## ★: the last perk of a branch (passive, only one point).
static func is_final(id: String) -> bool:
	var info: Array = Progression.PERKS[id]
	return not info[3] and int(info[1]) == 1


## The perk before it has a point (or it's first in its branch).
func is_open(id: String) -> bool:
	var need: String = Progression.PERKS[id][2]
	return need == "" or (progress != null and progress.perk_rank(need) > 0)


func _scale() -> float:
	return minf(size.x, size.y) / VIEW


func _to_screen(p: Vector2) -> Vector2:
	return size * 0.5 + p * _scale()


func _radius(id: String) -> float:
	var r := 40.0 if is_final(id) else 31.0
	return r * (1.28 if Progression.PERKS[id][3] else 1.0)


## Makes the knobs again (after learning something, or opening the window).
func rebuild() -> void:
	for k in _knobs.values():
		remove_child(k)
		k.queue_free()
	_knobs.clear()
	for id in Progression.PERKS:
		var knob := _make_knob(id)
		add_child(knob)
		_knobs[id] = knob
	_place_knobs()
	queue_redraw()


func select(id: String) -> void:
	selected = id
	for k in _knobs:
		_paint_knob(k)
	queue_redraw()


func _make_knob(id: String) -> Control:
	var info: Array = Progression.PERKS[id]
	var knob := Control.new()
	knob.name = "Perk_" + id
	knob.mouse_filter = Control.MOUSE_FILTER_STOP
	knob.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	knob.tooltip_text = info[4]
	knob.gui_input.connect(func(e: InputEvent) -> void:
		var mb := e as InputEventMouseButton
		if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			picked.emit(id))
	var pic := TextureRect.new()
	pic.name = "Pic"
	pic.texture = SkillsPanel.perk_icon(id)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_SCALE
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mat := ShaderMaterial.new()
	mat.shader = KNOB_SHADER
	mat.set_shader_parameter("diamond", info[3])
	pic.material = mat
	knob.add_child(pic)
	var rank := Label.new()
	rank.name = "Rank"
	rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank.add_theme_font_size_override("font_size", 12)
	rank.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge := StyleBoxFlat.new()
	badge.bg_color = Color("120e0a")
	badge.set_border_width_all(2)
	badge.set_corner_radius_all(8)
	badge.content_margin_left = 5
	badge.content_margin_right = 5
	rank.add_theme_stylebox_override("normal", badge)
	knob.add_child(rank)
	if is_final(id):
		var star := Label.new()
		star.name = "Star"
		star.text = "★"
		star.add_theme_font_size_override("font_size", 18)
		star.add_theme_color_override("font_color", GOLD_LIGHT)
		star.add_theme_color_override("font_outline_color", Color.BLACK)
		star.add_theme_constant_override("outline_size", 4)
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		knob.add_child(star)
	_paint_knob_of(knob, id)
	return knob


func _paint_knob(id: String) -> void:
	if _knobs.has(id):
		_paint_knob_of(_knobs[id], id)


func _paint_knob_of(knob: Control, id: String) -> void:
	var info: Array = Progression.PERKS[id]
	var have := progress.perk_rank(id) if progress else 0
	var open := is_open(id)
	var ring: Color = GOLD_LIGHT if id == selected else GOLD if have > 0 else COLORS[info[0]] if open else LOCKED_RING
	var mat := (knob.get_node("Pic") as TextureRect).material as ShaderMaterial
	mat.set_shader_parameter("ring", ring)
	mat.set_shader_parameter("locked", not open and have == 0)
	mat.set_shader_parameter("ring_width", 0.16 if id == selected else 0.11)
	var rank := knob.get_node("Rank") as Label
	rank.text = "%d/%d" % [have, info[1]]
	rank.add_theme_color_override("font_color", GOLD_LIGHT if have > 0 else UiKit.DIM)
	(rank.get_theme_stylebox("normal") as StyleBoxFlat).border_color = GOLD if have > 0 else Color("5a4730")


func _place_knobs() -> void:
	var s := _scale()
	for id in _knobs:
		var knob: Control = _knobs[id]
		var r := _radius(id) * s
		knob.position = _to_screen(_spots[id]) - Vector2(r, r)
		knob.size = Vector2(r, r) * 2.0
		var rank := knob.get_node("Rank") as Label
		rank.reset_size()
		rank.position = Vector2(r * 1.25, r * 1.5) - Vector2(rank.size.x * 0.5, rank.size.y * 0.5)
		var star := knob.get_node_or_null("Star") as Label
		if star:
			star.reset_size()
			star.position = Vector2(r - star.size.x * 0.5, -star.size.y * 0.75)
	queue_redraw()


func _draw() -> void:
	var s := _scale()
	var c := size * 0.5
	if background:
		var bw := BG_WIDTH * s
		var bh := bw * background.get_height() / background.get_width()
		var rect := Rect2(c - Vector2(FACE.x * bw, FACE.y * bh), Vector2(bw, bh))
		draw_texture_rect(background, rect, false, Color(1.25, 1.2, 1.15))
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color("0d0b09"))
	draw_texture_rect(_vignette, Rect2(Vector2.ZERO, size), false)
	# Lines first: from the perk before (or the Level circle) to each perk.
	for id in Progression.PERKS:
		var info: Array = Progression.PERKS[id]
		var to: Vector2 = _spots[id]
		var from: Vector2 = _spots[info[2]] if info[2] != "" else DIRS[info[0]] * (HUB_R + 2.0)
		var lit := progress != null and progress.perk_rank(id) > 0
		draw_line(_to_screen(from), _to_screen(to), GOLD if lit else LINE_DARK, (6.0 if lit else 4.0) * s, true)
	# A soft glow behind learned and chosen perks.
	for id in Progression.PERKS:
		var have := progress.perk_rank(id) if progress else 0
		if have == 0 and id != selected:
			continue
		var glow: Color = GOLD_LIGHT if id == selected else GOLD
		for i in 4:
			var r := (_radius(id) + 4.0 + i * 4.0) * s
			glow.a = 0.16 - i * 0.035
			_draw_shape(_to_screen(_spots[id]), r, Progression.PERKS[id][3], glow)
	# Branch names.
	var font := UiKit.heading_font()
	var fs := int(maxf(15.0, 26.0 * s))
	for br in SkillsPanel.BRANCHES:
		var d: Vector2 = DIRS[br[0]]
		var at := Vector2(d.x * 470.0, -528.0 if d.y < 0 else 552.0 if d.y > 0 else -150.0)
		var text: String = names.get(br[0], br[1]).to_upper()
		var w := 300.0
		var pos := _to_screen(at) - Vector2(w * 0.5, 0)
		draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, w, fs, 6, Color.BLACK)
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, w, fs, COLORS[br[0]])
	# The Level circle, in the carved ring.
	draw_circle(c, HUB_R * s, Color("1a130c"))
	draw_arc(c, HUB_R * s, 0, TAU, 64, GOLD, 4.0 * s, true)
	var small := int(maxf(11.0, 14.0 * s))
	var big := int(maxf(20.0, 34.0 * s))
	draw_string(get_theme_default_font(), c + Vector2(-60, -6 * s), "Level", HORIZONTAL_ALIGNMENT_CENTER, 120, small, UiKit.DIM)
	draw_string(font, c + Vector2(-60, 24 * s), str(progress.level if progress else 0), HORIZONTAL_ALIGNMENT_CENTER, 120, big, GOLD_LIGHT)


func _draw_shape(at: Vector2, r: float, diamond: bool, color: Color) -> void:
	if diamond:
		draw_colored_polygon(PackedVector2Array([at + Vector2(0, -r), at + Vector2(r, 0), at + Vector2(0, r), at + Vector2(-r, 0)]), color)
	else:
		draw_circle(at, r, color)
