class_name SkillPopup
extends PanelContainer
## F870 (owner, Nov 25: "too much text"): the skills are no longer always on screen (top right). A skill only pops up for
## ~2 s when it grows ("Mining 12  +6" over a bar), then fades away. A level up shows here too. The full list is in K.
## The HUD calls watch() every frame with the local player's Progression; it compares with what it saw last frame.

const SHOW_SECONDS := 2.0
const FADE := 0.4

var _seen := {}  ## skill -> [level, xp] last frame
var _seen_level := -1
var _progress: Progression  ## whose numbers _seen holds (a new player = start over, no pop-up)
var _skill := ""  ## the skill shown right now
var _gained := 0  ## XP gained while this pop-up has been up
var _left := 0.0  ## seconds before it starts to fade
var _name: Label
var _bar: ProgressBar


func _ready() -> void:
	name = "SkillPopup"
	UiKit.panel(self, 18.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(240, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v)
	_name = UiKit.label(v, "", 16, UiKit.AMBER)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(0, 8)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(1.0, 0.75, 0.35)
	fill.set_corner_radius_all(3)
	_bar.add_theme_stylebox_override("fill", fill)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.1, 0.07, 0.05, 0.9)
	back.set_corner_radius_all(3)
	_bar.add_theme_stylebox_override("background", back)
	v.add_child(_bar)
	modulate.a = 0.0
	visible = false


## Every frame: pops up when a skill (or the level) went up since last frame.
func watch(p: Progression, delta: float) -> void:
	if p != _progress:
		_progress = p
		_snapshot(p)
		return
	if p != null:
		if p.level > _seen_level and _seen_level >= 0:
			_show_level(p)  # (a level up wins over the skill that caused it)
		elif _skill != "" or _left <= 0.0:  # (and isn't covered by a skill until it has shown)
			for s in p.skill_level:
				var was: Array = _seen.get(s, [p.skill_level[s], p.skill_xp[s]])
				var got := _gain(was, p.skill_level[s], p.skill_xp[s])
				if got > 0:
					_show_skill(p, s, got)
		_snapshot(p)
	_left -= delta
	modulate.a = clampf((_left + FADE) / FADE, 0.0, 1.0)
	visible = modulate.a > 0.0


## The text shown right now ("" when hidden).
func text() -> String:
	return _name.text if visible else ""


func _snapshot(p: Progression) -> void:
	_seen.clear()
	_seen_level = -1
	if p == null:
		return
	_seen_level = p.level
	for s in p.skill_level:
		_seen[s] = [p.skill_level[s], p.skill_xp[s]]


## XP gained between two readings (over a level-up too).
static func _gain(was: Array, level: int, xp: int) -> int:
	if level == was[0]:
		return xp - int(was[1])
	var got := Progression.skill_xp_to_next(was[0]) - int(was[1]) + xp
	for n in range(int(was[0]) + 1, level):
		got += Progression.skill_xp_to_next(n)
	return got


func _show_skill(p: Progression, s: String, got: int) -> void:
	if s != _skill or _left <= -FADE:
		_gained = 0
	_skill = s
	_gained += got
	var lv: int = p.skill_level[s]
	_name.text = "%s %d   +%d" % [Progression.SKILL_INFO[s][0], lv, _gained]
	_bar.visible = true
	_bar.max_value = Progression.skill_xp_to_next(lv)
	_bar.value = p.skill_xp[s]
	_left = SHOW_SECONDS


func _show_level(p: Progression) -> void:
	_skill = ""
	_gained = 0
	_name.text = "Level %d!   +1 perk point (K)" % p.level
	_bar.visible = false
	_left = SHOW_SECONDS + 1.0
