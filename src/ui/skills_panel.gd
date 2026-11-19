class_name SkillsPanel
extends PanelContainer
## The skills window (K key), laid out like the owner's mock-up (Nov 20, claude.ai/artifact/MBTFW9LdXc4mA3jNNpvYWR):
##  - left: the 14 skills you grow by doing. Click one to see its ★ perks at 25 / 50 / 75 / 100; only one is open
##    at a time and the list never needs scrolling.
##  - middle: the perk tree (PerkTreeView): 1 point per level, 4 branches. A perk opens once the one before it has a point.
##  - right: the perk you clicked, with its Learn button. ◆ = active perk on an ability key (Z / G / T).
## Resetting your perk points costs gold coins (top right).

const BRANCHES := [["toughness", "Bones"], ["fighting", "Fists"], ["utility", "Hands"], ["together", "Heart"]]  ## names (owner, Nov 19); ids stay
const KEY_NAMES := ["Z", "G", "T"]
const BACKGROUND := "res://assets/ui/skills_background.jpg"
const MILESTONE_TEXT := "★%d"

var peer_id := 1
var _level: Label
var _points: Label
var _reset: Button
var _skills: VBoxContainer
var _tree: PerkTreeView
var _detail: VBoxContainer
var _open_skill := "mining"
var _sel := "thick_skin"


## A perk's picture (assets/icons/perks/, cut from the ChatGPT sheets in assets/concepts/perks/), or null.
static func perk_icon(id: String) -> Texture2D:
	var path := "res://assets/icons/perks/%s.png" % id
	return load(path) if ResourceLoader.exists(path) else null


func _ready() -> void:
	UiKit.panel(self)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	add_child(box)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	box.add_child(top)
	_level = UiKit.label(top, "", 16, UiKit.DIM)
	_level.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiKit.title(top, "Skills")
	var right := HBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.alignment = BoxContainer.ALIGNMENT_END
	right.add_theme_constant_override("separation", 14)
	top.add_child(right)
	_points = UiKit.label(right, "", 17, UiKit.AMBER)
	_points.add_theme_font_override("font", UiKit.heading_font())
	_reset = UiKit.dark_button(Button.new(), 13)
	_reset.name = "Reset"
	_reset.pressed.connect(func():
		GameAuthority.instance.ask_respec()
		get_tree().create_timer(0.15).timeout.connect(refresh))
	right.add_child(_reset)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 8)
	box.add_child(cols)
	var left := _side(cols, 270)
	UiKit.label(left, "Skills  ·  grow by doing", 15, UiKit.AMBER).add_theme_font_override("font", UiKit.heading_font())
	_skills = VBoxContainer.new()
	_skills.add_theme_constant_override("separation", 2)
	left.add_child(_skills)
	_tree = PerkTreeView.new()
	_tree.name = "Tree"
	_tree.custom_minimum_size = Vector2(660, 620)
	_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tree.picked.connect(func(id): _sel = id; _tree.selected = id; _tree.refresh(); _show_detail())
	cols.add_child(_tree)
	_detail = _side(cols, 290)
	UiKit.label(box, "Circles = always on  ·  ◆ diamonds = press Z / G / T  ·  ★ = final perk  ·  wheel = zoom, drag = move, double-click = fit  ·  K close", 13, UiKit.DIM).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _side(parent: Node, width: float) -> VBoxContainer:
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UiKit.style("card", 10))
	frame.custom_minimum_size = Vector2(width, 620)
	parent.add_child(frame)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	frame.add_child(v)
	return v


func _progress() -> Progression:
	var auth := GameAuthority.instance
	var ps: GameAuthority.PlayerState = auth.get_player(peer_id) if auth else null
	return ps.progress if ps else null


func refresh() -> void:
	var auth := GameAuthority.instance
	var ps: GameAuthority.PlayerState = auth.get_player(peer_id) if auth else null
	if ps == null:
		return
	var p := ps.progress
	_level.text = "Level %d" % p.level
	_points.text = "Perk points: %d" % p.points_free()
	_reset.text = "Reset perks · %d gold (you have %d)" % [p.respec_cost(), ps.inventory.count_of("gold_coin")]
	_reset.disabled = p.points_free() == p.points_total()
	_tree.progress = p
	_tree.selected = _sel
	_tree.refresh()
	_show_skills()
	_show_detail()


# ---------------------------------------------------------------- left: skills

func _show_skills() -> void:
	var p := _progress()
	UiKit.clear(_skills)
	for s in Progression.SKILLS:
		var info: Array = Progression.SKILL_INFO[s]
		var lv: int = p.skill_level[s]
		var open: bool = s == _open_skill
		var card := PanelContainer.new()
		card.name = "Skill_" + s
		card.add_theme_stylebox_override("panel", UiKit.style("slot_selected" if open else "slot", 9 if open else 4, 10))
		_skills.add_child(card)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 1)
		card.add_child(v)
		var row := Button.new()  # the whole line opens / closes the skill
		row.flat = true
		row.custom_minimum_size = Vector2(0, 24)
		row.pressed.connect(func(): _open_skill = "" if _open_skill == s else s; _show_skills())
		v.add_child(row)
		var h := HBoxContainer.new()
		h.set_anchors_preset(Control.PRESET_FULL_RECT)
		h.offset_left = 4
		h.offset_right = -14  # keep the level number off the card's edge
		h.add_theme_constant_override("separation", 6)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(h)
		var name := UiKit.label(h, info[0], 14, UiKit.TEXT)
		name.custom_minimum_size = Vector2(82, 0)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 6)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.max_value = Progression.skill_xp_to_next(lv)
		bar.value = p.skill_xp[s] if lv < Progression.MAX_SKILL else bar.max_value
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(bar)
		var next := 100
		for m in Progression.MILESTONES:
			if lv < m:
				next = m
				break
		UiKit.label(h, MILESTONE_TEXT % next if lv < 100 else "Master", 12, UiKit.DIM)
		var lvl := UiKit.label(h, str(lv), 14, UiKit.AMBER)
		lvl.custom_minimum_size = Vector2(24, 0)
		lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		for c in h.get_children():
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if open:
			_wrap(v, "[color=#%s]Every 10 levels: %s (a bit each level)[/color]" % [UiKit.AMBER.to_html(false), info[1]])
			for i in 4:
				var got: bool = lv >= Progression.MILESTONES[i]
				_wrap(v, "[color=#%s]%s %s%s[/color]" % [(UiKit.TEXT if got else UiKit.DIM).to_html(false), MILESTONE_TEXT % Progression.MILESTONES[i],
					info[2][i], "" if got else "  · %d to go" % (Progression.MILESTONES[i] - lv)])


## Small wrapping text that always grows to fit (a plain Label in a container can get clipped when it wraps).
func _wrap(parent: Node, bbcode: String) -> void:
	var t := RichTextLabel.new()
	t.bbcode_enabled = true
	t.fit_content = true
	t.scroll_active = false
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.add_theme_font_size_override("normal_font_size", 12)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.text = bbcode
	parent.add_child(t)


# ---------------------------------------------------------------- right: the perk you clicked

func _show_detail() -> void:
	var p := _progress()
	UiKit.clear(_detail)
	if p == null or not Progression.PERKS.has(_sel):
		return
	var info: Array = Progression.PERKS[_sel]
	var have := p.perk_rank(_sel)
	var why := p.why_not(_sel)
	var branch := ""
	for br in BRANCHES:
		if br[0] == info[0]:
			branch = br[1]
	var pic := TextureRect.new()
	pic.texture = perk_icon(_sel)
	pic.custom_minimum_size = Vector2(120, 120)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var mat := ShaderMaterial.new()
	mat.shader = PerkTreeView._shader
	mat.set_shader_parameter("diamond", info[3])
	pic.material = mat
	_detail.add_child(pic)
	var title := UiKit.label(_detail, ("★ " if _sel in PerkTreeView.FINALS else "") + info[4], 21, UiKit.AMBER)
	title.add_theme_font_override("font", UiKit.heading_font())
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var kind := UiKit.label(_detail, "%s  ·  %s" % [branch, "◆ Active" if info[3] else "● Passive"], 13, PerkTreeView.COLORS[info[0]])
	kind.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var pips := UiKit.label(_detail, "◆".repeat(have) + "◇".repeat(info[1] - have), 18, UiKit.AMBER)
	pips.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var planned: bool = info[5].contains("not in the game yet") or info[5].contains("(no ") or info[5].contains("don't wear out")
	var text := UiKit.label(_detail, info[5].get_slice(" (", 0) + ".", 15, UiKit.TEXT)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size.x = 260
	var slot := p.ability_slots().find(_sel)
	var lines := ["Points: %d of %d" % [have, info[1]]]
	if info[3]:
		lines.append("Use: " + ("press " + KEY_NAMES[slot] if slot >= 0 else ("no free key (the first 3 get Z, G, T)" if have > 0 else "goes on Z, G or T")))
		var cd: float = Progression.ACTIVE[_sel]
		lines.append("Recharge: %s" % ("%d min" % roundi(cd / 60.0) if cd >= 60.0 and fmod(cd, 60.0) == 0.0 else "%d s" % roundi(cd)))
	else:
		lines.append("Use: always on")
	lines.append("Needs: " + (Progression.PERKS[info[2]][4] if info[2] != "" else "nothing, first in the branch"))
	for l in lines:
		UiKit.label(_detail, l, 13, UiKit.DIM)
	if planned:
		var warn := UiKit.label(_detail, "Planned: needs a game system that isn't built yet.", 13, UiKit.MISSING)
		warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var learn := UiKit.gold_button(Button.new(), 16)
	learn.name = "Learn"
	learn.text = "Fully learned" if have >= info[1] else "Learn · 1 point"
	learn.disabled = why != ""
	learn.custom_minimum_size = Vector2(0, 42)
	learn.pressed.connect(func():
		GameAuthority.instance.ask_buy_perk(_sel)
		get_tree().create_timer(0.15).timeout.connect(refresh))
	_detail.add_child(learn)
	if why != "" and have < info[1]:
		var w := UiKit.label(_detail, why, 13, UiKit.DIM)
		w.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		w.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
