class_name SkillPopup
extends PanelContainer
## F870 (owner, Nov 25: "too much text"): the skills are no longer always on screen (top right). A skill only pops up for
## ~2.5 s when it LEVELS UP (F880, owner Nov 25: not on every XP gain), with its picture ("Mining 12!"), then fades.
## A dwarf level up shows here too. The full list is in K.
## The HUD calls watch() every frame with the local player's Progression; it compares with what it saw last frame.

const SHOW_SECONDS := 2.5
const FADE := 0.4

var _seen := {}  ## skill -> [level, xp] last frame
var _seen_level := -1
var _progress: Progression  ## whose numbers _seen holds (a new player = start over, no pop-up)
var _skill := ""  ## the skill shown right now
var _left := -FADE  ## seconds before it starts to fade (starts faded out)
var _name: Label
var _pic: TextureRect
## A picture per skill (item icons; perk pictures where no item fits).
const ICON := {running = "perks/light_feet", jumping = "boots_leather", mining = "pickaxe_stone", woodcutting = "axe_stone",
	gathering = "bellcap", crafting = "workbench", cooking = "cooking_pot", sword = "sword_stone", axe = "axe_stone",
	mace = "mace_stone", warhammer = "perks/heavy_hands", spear = "spear_stone", shield = "shield_stone",
	crossbow = "crossbow_stone"}


func _ready() -> void:
	name = "SkillPopup"
	UiKit.panel(self, 18.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(240, 0)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(h)
	_pic = TextureRect.new()
	_pic.custom_minimum_size = Vector2(48, 48)
	_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(_pic)
	_name = UiKit.label(h, "", 18, UiKit.AMBER)
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	modulate.a = 0.0
	visible = false


## Every frame: pops up when a skill's level (or the dwarf's level) went up since last frame. XP alone shows nothing.
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
				if p.skill_level[s] > int(was[0]):
					_show_skill(p, s)
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


## The picture for a skill (null if it has none).
static func icon(s: String) -> Texture2D:
	var path := "res://assets/icons/%s.png" % ICON.get(s, "")
	return load(path) if s in ICON and ResourceLoader.exists(path) else null


func _show_skill(p: Progression, s: String) -> void:
	_skill = s
	# F934 (owner, Nov 27: "way too arcade-like"): a skill going up plays a small, quiet real sound; only the big
	# Level-up keeps the treasure chest reveal (round 10).
	Sfx.ui(Sfx.pick("skill_up", "level_up"), -6.0)
	_name.text = "%s %d!" % [Progression.SKILL_INFO[s][0], p.skill_level[s]]
	_pic.texture = icon(s)
	_pic.visible = _pic.texture != null
	_left = SHOW_SECONDS


func _show_level(p: Progression) -> void:
	_skill = ""
	Sfx.ui("level_up", -2.0)
	_name.text = "Level %d!   +1 perk point (K)" % p.level
	_pic.visible = false
	_left = SHOW_SECONDS + 1.0
