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
	# F429 (owner, Nov 20: "K just shows a big box"): wrapping text measures itself very tall for a moment, and a
	# container never shrinks back by itself, so the window stayed 3216 px tall with everything off the screen.
	minimum_size_changed.connect(func(): reset_size.call_deferred())
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
	_reset = UiKit.dark_button(Button.new(), 16)
	_reset.name = "Reset"
	_reset.pressed.connect(func():
		GameAuthority.instance.ask_respec()
		get_tree().create_timer(0.15).timeout.connect(refresh))
	right.add_child(_reset)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 8)
	box.add_child(cols)
	var left := _side(cols, 330)
	UiKit.label(left, "Skills  ·  grow by doing", 16, UiKit.AMBER).add_theme_font_override("font", UiKit.heading_font())
	_skills = VBoxContainer.new()
	_skills.add_theme_constant_override("separation", 2)
	left.add_child(_skills)
	_tree = PerkTreeView.new()
	_tree.name = "Tree"
	_tree.custom_minimum_size = Vector2(660, 620)
	_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tree.picked.connect(func(id): _sel = id; _tree.selected = id; _tree.refresh(); _show_detail())
	cols.add_child(_tree)
	_detail = _side(cols, 320)
	UiKit.label(box, "Circle = works by itself  ·  ◆ = press Z / G / T  ·  ★ = last perk  ·  scroll to zoom, drag to move  ·  K to close", 15, UiKit.DIM).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


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
	_level.text = "Level %d  ·  %d kills" % [p.level, p.total_kills()]
	var lines := PackedStringArray()
	for kind in p.kills:
		var rank := p.hunter_rank(kind)
		var next: String = "" if rank >= 3 else "  ·  %d to %s" % [Progression.HUNTER_STEPS[rank] - p.kills_of(kind), Progression.hunter_title(kind, rank + 1)]
		lines.append("%s: %d%s%s" % [Monsters.LIST[kind].name if Monsters.LIST.has(kind) else kind, p.kills[kind],
			"  ·  %s (+%d%% damage)" % [Progression.hunter_title(kind, rank), roundi(p.hunter_bonus(kind) * 100)] if rank > 0 else "", next])
	_level.tooltip_text = "\n".join(lines) if lines else "No kills yet"
	_level.mouse_filter = Control.MOUSE_FILTER_STOP
	_points.text = "Perk points: %d" % p.points_free()
	_reset.text = "Reset perks: %d gold" % p.respec_cost()
	_reset.tooltip_text = "Get all your perk points back to spend again. You have %d gold." % ps.inventory.count_of("gold_coin")
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
		var frame_style := UiKit.style("slot_selected" if open else "slot", 9, 18)  # (frame art is 14 px: keep text inside it)
		frame_style.content_margin_top = 8  # (owner, Nov 20: "Mining" and "Lv 0" still touched the rim)
		frame_style.content_margin_bottom = 10 if not open else 13  # (the plank's thick rim is at the bottom)
		card.add_theme_stylebox_override("panel", frame_style)
		_skills.add_child(card)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 1)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(v)
		var click := Button.new()  # an invisible button over the whole card opens / closes the skill
		click.flat = true
		click.focus_mode = Control.FOCUS_NONE
		click.pressed.connect(func(): _open_skill = "" if _open_skill == s else s; _show_skills())
		card.add_child(click)
		# F433 (owner, Nov 20: "too small to read, the words overlap the bar, too many words"): bigger letters, and the
		# name has its own wide slot, so the bar and the level can never run into it.
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(h)
		var name := UiKit.label(h, info[0], 16, UiKit.TEXT)
		name.custom_minimum_size = Vector2(112, 0)
		name.clip_text = true
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 7)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(bar)
		var lvl := UiKit.label(h, "Master" if lv >= Progression.MAX_SKILL else "Lv %d" % lv, 16, UiKit.AMBER)
		lvl.custom_minimum_size = Vector2(52, 0)
		lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var track := StyleBoxFlat.new()
		track.bg_color = Color(0.04, 0.03, 0.02, 0.85)
		track.border_color = Color(UiKit.AMBER, 0.45)
		track.set_border_width_all(1)
		track.set_corner_radius_all(3)
		var fill := StyleBoxFlat.new()
		fill.bg_color = UiKit.AMBER
		fill.set_corner_radius_all(3)
		bar.add_theme_stylebox_override("background", track)
		bar.add_theme_stylebox_override("fill", fill)
		bar.max_value = Progression.skill_xp_to_next(lv)
		bar.value = p.skill_xp[s] if lv < Progression.MAX_SKILL else bar.max_value
		for c in h.get_children():
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if open:
			_wrap(v, "[color=#%s]Each level: %s[/color]" % [UiKit.AMBER.to_html(false), info[1]])
			for i in 4:
				var got: bool = lv >= Progression.MILESTONES[i]
				_wrap(v, "[color=#%s]%s  %s %s[/color]" % [(UiKit.TEXT if got else UiKit.DIM).to_html(false), "✓" if got else "·",
					MILESTONE_TEXT % Progression.MILESTONES[i], info[2][i]])


## Small wrapping text that always grows to fit (a plain Label in a container can get clipped when it wraps).
func _wrap(parent: Node, bbcode: String) -> void:
	var t := RichTextLabel.new()
	t.bbcode_enabled = true
	t.fit_content = true
	t.scroll_active = false
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.add_theme_font_size_override("normal_font_size", 14)
	t.custom_minimum_size.x = 280  # (wraps at the card's width, never measures itself one word wide)
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
	pic.custom_minimum_size = Vector2(170, 170)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var mat := ShaderMaterial.new()
	mat.shader = PerkTreeView._shader
	mat.set_shader_parameter("diamond", info[3])
	pic.material = mat
	_detail.add_child(pic)
	var title := UiKit.label(_detail, ("★ " if _sel in PerkTreeView.FINALS else "") + info[4], 25, UiKit.AMBER)
	title.add_theme_font_override("font", UiKit.heading_font())
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# F434 (owner, Nov 20: "very tiny text"): bigger letters and plain words, one fact per line.
	var kind := UiKit.label(_detail, "%s branch  ·  %s" % [branch, "◆ you press a key" if info[3] else "● works by itself"], 16, PerkTreeView.COLORS[info[0]])
	kind.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var pips := UiKit.label(_detail, "◆".repeat(have) + "◇".repeat(info[1] - have), 24, UiKit.AMBER)
	pips.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var planned: bool = info[5].contains("not in the game yet") or info[5].contains("(no ") or info[5].contains("don't wear out")
	var text := UiKit.label(_detail, info[5].get_slice(" (", 0).replace("per rank", "per point") + ".", 21, UiKit.TEXT)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size.x = 260
	var slot := p.ability_slots().find(_sel)
	var lines := ["Learned: %d of %d points" % [have, info[1]]]
	if info[3]:
		lines.append("Key: " + ("press " + KEY_NAMES[slot] if slot >= 0 else ("no free key (only 3 fit on Z, G, T)" if have > 0 else "it goes on Z, G or T")))
		var cd: float = Progression.ACTIVE[_sel]
		lines.append("Use again after: %s" % ("%d min" % roundi(cd / 60.0) if cd >= 60.0 and fmod(cd, 60.0) == 0.0 else "%d s" % roundi(cd)))
	lines.append("First learn: " + (Progression.PERKS[info[2]][4] if info[2] != "" else "nothing, it's the first one"))
	for l in lines:
		var line := UiKit.label(_detail, l, 17, UiKit.DIM)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if planned:
		var warn := UiKit.label(_detail, "Not working yet: comes in a later update.", 16, UiKit.MISSING)
		warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var learn := UiKit.gold_button(Button.new(), 16)
	learn.name = "Learn"
	learn.text = "Fully learned" if have >= info[1] else "Learn (1 point)"
	learn.disabled = why != ""
	learn.custom_minimum_size = Vector2(0, 42)
	learn.pressed.connect(func():
		GameAuthority.instance.ask_buy_perk(_sel)
		get_tree().create_timer(0.15).timeout.connect(refresh))
	_detail.add_child(learn)
	if why != "" and have < info[1]:
		var w := UiKit.label(_detail, why, 17, UiKit.DIM)
		w.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		w.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# (owner, Nov 20: "a lot of empty space" here) how points work, at the bottom of the card
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail.add_child(gap)
	var how := UiKit.label(_detail, "You get 1 perk point each time your level goes up. Level up by doing anything: digging, fighting, crafting, exploring.", 16, UiKit.DIM)
	how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	how.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
