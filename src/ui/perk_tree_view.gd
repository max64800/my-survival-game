class_name PerkTreeView
extends Control
## The perk tree in the middle of the skills window (owner, Nov 19-20; mock-up: claude.ai/artifact/MBTFW9LdXc4mA3jNNpvYWR).
## Four branches grow from your level in the carved ring of the painted hall: Bones up, Fists right, Hands down,
## Heart left. Circles = passive perks, diamonds = active ones (Q / R / T), ★ = a branch's final perk.
## Click a perk to see it on the right (SkillsPanel shows the details and the Learn button).

signal picked(perk_id: String)

## Where each perk sits: [steps out from the centre, lane to the side (-1 / 0 / +1)]. Same as the mock-up.
const LAYOUT := {
	thick_skin = [1, 0], iron_belly = [2, -1], big_lungs = [2, 0], deep_well = [2, 1], poison_blood = [3, -1],
	stubborn_heart = [3, 0], fire_and_frost = [3, 1], stone_skin = [4, -1], grave_walker = [4, 0], unbreakable = [5, 0],
	stone_stance = [5, -1],
	warriors_grip = [1, 0], light_feet = [2, -1], battle_breath = [2, 0], quick_reload = [2, 1], last_swing = [3, -1],
	armor_breaker = [3, 0], steady_aim = [3, 1], monster_lore = [4, -1], heavy_hands = [4, 0], berserker = [5, 0],
	whirlwind = [5, -1], rapid_volley = [4, 1],
	deep_pockets = [1, 0], ore_smasher = [2, -1], quick_smelter = [2, 0], thrifty = [2, 1], prospector = [3, -1],
	chest_looter = [3, 0], steady_hands = [3, 1], hearth_cook = [4, 1], monster_scavenger = [4, 0],
	master_of_stone = [5, 0], quick_fix = [5, 1],
	shoulder_to_shoulder = [1, 0], shared_lessons = [2, -1], war_horn = [2, 0], quick_helper = [2, 1],
	lantern_bearer = [3, -1], healing_brew = [3, 0], stand_over = [3, 1], clan_banner = [4, 0], pack_hunters = [4, 1],
	bond_of_the_clan = [5, 0],
}
const FINALS := ["unbreakable", "berserker", "master_of_stone", "bond_of_the_clan"]
const DIRS := {toughness = Vector2(0, -1), fighting = Vector2(1, 0), utility = Vector2(0, 1), together = Vector2(-1, 0)}
const COLORS := {toughness = Color(0.66, 0.68, 0.71), fighting = Color(0.81, 0.37, 0.27), utility = Color(0.88, 0.66, 0.23),
	together = Color(0.53, 0.70, 0.37)}
const UNITS := 1120.0  ## the tree is laid out in a 1120 x 1120 box, scaled to fit
const GOLD := Color(0.91, 0.66, 0.24)
## The carved dwarf face in the background picture: 50.2% across, 45.5% down. It sits right under the Level circle.
const FACE := Vector2(0.502, 0.4554)
const BG_WIDTH := 2300.0

const MASK := """shader_type canvas_item;
uniform bool diamond = false;
uniform bool locked = false;
void fragment() {
	vec2 p = UV - 0.5;
	float inside = diamond ? step(abs(p.x) + abs(p.y), 0.5) : step(length(p), 0.5);
	vec4 c = texture(TEXTURE, UV);
	if (locked) { float g = dot(c.rgb, vec3(0.3, 0.59, 0.11)); c.rgb = mix(c.rgb, vec3(g), 0.85) * 0.45; }
	COLOR = vec4(c.rgb, c.a * inside);
}"""

var progress: Progression
var selected := ""
var zoom := 1.0  ## mouse wheel zooms (1 = the whole tree fits); drag empty space to move it; double-click = fit
var pan := Vector2.ZERO  ## how far the tree is moved, in screen pixels
var _dragging := false
var _bg: Texture2D
var _nodes := {}  ## perk id -> its clickable Control (with the picture inside)
var _over: Control  ## draws borders, badges, the Level circle and branch names on top of the pictures
static var _shader: Shader


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	_bg = load(SkillsPanel.BACKGROUND) if ResourceLoader.exists(SkillsPanel.BACKGROUND) else null
	if _shader == null:
		_shader = Shader.new()
		_shader.code = MASK
	for id in Progression.PERKS:
		var box := Control.new()
		box.name = "Perk_" + id
		box.tooltip_text = Progression.PERKS[id][4]
		box.mouse_filter = Control.MOUSE_FILTER_STOP
		box.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT: picked.emit(id))
		box.set_drag_forwarding(func(_at): return _drag(box, id), Callable(), Callable())
		var pic := TextureRect.new()
		pic.name = "Pic"
		pic.texture = SkillsPanel.perk_icon(id)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.set_anchors_preset(Control.PRESET_FULL_RECT)
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mat := ShaderMaterial.new()
		mat.shader = _shader
		mat.set_shader_parameter("diamond", Progression.PERKS[id][3])
		pic.material = mat
		box.add_child(pic)
		add_child(box)
		_nodes[id] = box
	_over = Control.new()
	_over.set_anchors_preset(Control.PRESET_FULL_RECT)
	_over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_over.draw.connect(_draw_over)
	add_child(_over)
	resized.connect(refresh)


## A learned ability (◆) can be dragged onto the Q / R / T boxes (SkillsPanel._keys).
func _drag(box: Control, id: String) -> Variant:
	if progress == null or not Progression.ACTIVE.has(id) or progress.perk_rank(id) < 1:
		return null
	box.set_drag_preview(drag_picture(id))
	return {ability = id}


static func drag_picture(id: String) -> Control:
	var pic := TextureRect.new()
	pic.texture = SkillsPanel.perk_icon(id)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.size = Vector2(64, 64)
	pic.position = -pic.size / 2.0
	var holder := Control.new()  # (the preview's top-left follows the mouse: centre the picture on it)
	holder.add_child(pic)
	return holder


func _scale() -> float:
	return minf(size.x, size.y) / UNITS * zoom


func _center() -> Vector2:
	return size * 0.5 + pan


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var old := zoom
		zoom = clampf(zoom * (1.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.15), 1.0, 3.0)
		pan = (pan + size * 0.5 - event.position) * (zoom / old) + event.position - size * 0.5  # zoom where the mouse is
		_clamp_pan()
		refresh()
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.double_click:
			zoom = 1.0
			pan = Vector2.ZERO
			refresh()
		_dragging = event.pressed
	elif event is InputEventMouseMotion and _dragging:
		pan += event.relative
		_clamp_pan()
		refresh()


## Keep part of the tree on screen while dragging.
func _clamp_pan() -> void:
	var room := minf(size.x, size.y) * zoom * 0.5
	pan = pan.clamp(-Vector2(room, room), Vector2(room, room))


## Screen spot of a perk (inside this control).
func spot(id: String) -> Vector2:
	var p: Array = Progression.PERKS[id]
	var d: Vector2 = DIRS[p[0]]
	var at: Array = LAYOUT.get(id, [1, 0])
	var r: float = 105.0 + (at[0] - 1) * 90.0
	var lane: float = at[1] * 92.0
	return _center() + Vector2(d.x * r - d.y * lane, d.y * r + d.x * lane) * _scale()


func radius(id: String) -> float:
	var r := 40.0 if id in FINALS else 31.0
	return r * (1.28 if Progression.PERKS[id][3] else 1.0) * _scale()


func refresh() -> void:
	if progress == null:
		return
	for id in _nodes:
		var box: Control = _nodes[id]
		var r := radius(id)
		box.position = spot(id) - Vector2(r, r)
		box.size = Vector2(r, r) * 2.0
		var open: bool = progress.perk_rank(id) > 0 or progress.why_not(id) == ""
		((box.get_node("Pic") as TextureRect).material as ShaderMaterial).set_shader_parameter("locked", not open)
	queue_redraw()
	_over.queue_redraw()


func _draw() -> void:
	var s := _scale()
	if _bg:  # the painted hall, its carved face under the Level circle
		var w := BG_WIDTH * s
		var h := w * _bg.get_height() / _bg.get_width()
		draw_texture_rect(_bg, Rect2(_center() - Vector2(w * FACE.x, h * FACE.y), Vector2(w, h)), false, Color(0.62, 0.62, 0.62))
	if progress == null:
		return
	for id in Progression.PERKS:
		var p: Array = Progression.PERKS[id]
		var from: Vector2 = spot(p[2]) if p[2] != "" else _center() + DIRS[p[0]] * 58.0 * s
		var lit := progress.perk_rank(id) > 0
		draw_line(from, spot(id), GOLD if lit else Color(0.23, 0.17, 0.11), (6.0 if lit else 4.0) * s * 1.4, true)


func _draw_over() -> void:
	if progress == null:
		return
	var s := _scale()
	var font := UiKit.heading_font()
	var c := _center()
	for id in Progression.PERKS:
		var p: Array = Progression.PERKS[id]
		var at := spot(id)
		var r := radius(id)
		var have := progress.perk_rank(id)
		var open: bool = have > 0 or progress.why_not(id) == ""
		var col: Color = Color(1.0, 0.86, 0.5) if id == selected else (GOLD if have > 0 else (COLORS[p[0]] if open else Color(0.25, 0.19, 0.13)))
		var w := (5.0 if id == selected else 4.0) * s * 1.3
		if p[3]:
			_over.draw_polyline(PackedVector2Array([at + Vector2(0, -r), at + Vector2(r, 0), at + Vector2(0, r), at + Vector2(-r, 0), at + Vector2(0, -r)]), col, w, true)
		else:
			_over.draw_arc(at, r, 0.0, TAU, 40, col, w, true)
		# points badge "1/3"
		var b := Rect2(at + Vector2(r * 0.3, r * 0.5), Vector2(34, 19) * s * 1.3)
		_over.draw_rect(b, Color(0.07, 0.055, 0.04))
		_over.draw_rect(b, GOLD if have > 0 else Color(0.35, 0.28, 0.19), false, 1.5)
		_over.draw_string(font, b.position + Vector2(0, b.size.y * 0.78), "%d/%d" % [have, p[1]], HORIZONTAL_ALIGNMENT_CENTER, b.size.x, int(13 * s * 1.3), Color(0.97, 0.81, 0.48) if have > 0 else UiKit.DIM)
		if id in FINALS:
			_over.draw_string(font, at + Vector2(-20, -r - 4) * Vector2(1, 1), "★", HORIZONTAL_ALIGNMENT_CENTER, 40, int(22 * s * 1.3), Color(0.97, 0.81, 0.48))
	# the Level circle in the carved ring
	_over.draw_circle(c, 56.0 * s, Color(0.1, 0.075, 0.05))
	_over.draw_arc(c, 56.0 * s, 0.0, TAU, 48, GOLD, 4.0 * s * 1.3, true)
	_over.draw_string(font, c + Vector2(-60, -6) * s, "Level", HORIZONTAL_ALIGNMENT_CENTER, 120 * s, int(15 * s * 1.3), UiKit.DIM)
	_over.draw_string(font, c + Vector2(-60, 30) * s, str(progress.level), HORIZONTAL_ALIGNMENT_CENTER, 120 * s, int(34 * s * 1.3), Color(0.97, 0.81, 0.48))
	# branch names
	for br in SkillsPanel.BRANCHES:
		var d: Vector2 = DIRS[br[0]]
		var at := c + (Vector2(d.x * 470.0, -150.0) if d.y == 0 else Vector2(0, -528.0 if d.y < 0 else 548.0)) * s
		_over.draw_string_outline(font, at - Vector2(150, 0), br[1].to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 300, int(24 * s * 1.3), 6, Color.BLACK)
		_over.draw_string(font, at - Vector2(150, 0), br[1].to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 300, int(24 * s * 1.3), COLORS[br[0]])
