class_name SkillsPanel
extends PanelContainer
## The skills window (K key), built like the owner's approved mock-up (Nov 19):
##   left:   your 14 skills (they grow by doing). Click one to see its ★ perks at 25/50/75/100.
##   middle: the perk tree on the carved hall (PerkTree): 1 point per level, 4 branches.
##   right:  the chosen perk: what it does, what it needs, and the Learn button.
## A perk opens once the one before it has a point. ◆ = active perk: it goes on an ability key
## (Z / G / T). Resetting your points costs gold coins. Every rule lives in Progression / GameAuthority.

const BRANCHES := [["toughness", "Bones"], ["fighting", "Fists"], ["utility", "Hands"], ["together", "Heart"]]  ## names (owner, Nov 19); ids stay
const KEY_NAMES := ["Z", "G", "T"]
const SIDE_BG := Color(0.08, 0.063, 0.047, 0.94)
const EDGE := Color("4a3620")

var peer_id := 1
var tree: PerkTree
var _skills: VBoxContainer
var _detail: VBoxContainer
var _points: Label
var _level: Label
var _reset: Button
var _open_skill := "mining"


func _ready() -> void:
	UiKit.panel(self, 14)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	add_child(box)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	box.add_child(top)
	_level = UiKit.label(top, "", 16, UiKit.DIM)
	_level.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_level.size_flags_stretch_ratio = 1.0
	UiKit.title(top, "Skills")
	var right := HBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 1.0
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
	cols.add_theme_constant_override("separation", 0)
	box.add_child(cols)
	var left := _side(cols, 290)
	UiKit.label(left, "Skills  ·  grow by doing", 15, UiKit.AMBER).add_theme_font_override("font", UiKit.heading_font())
	_skills = VBoxContainer.new()
	_skills.name = "SkillList"
	_skills.add_theme_constant_override("separation", 2)
	left.add_child(_skills)
	tree = PerkTree.new()
	tree.name = "PerkTree"
	tree.custom_minimum_size = Vector2(720, 690)
	for br in BRANCHES:
		tree.names[br[0]] = br[1]
	tree.picked.connect(func(id: String) -> void:
		tree.select(id)
		_fill_detail())
	cols.add_child(tree)
	var det := _side(cols, 290)
	UiKit.label(det, "Perk", 15, UiKit.AMBER).add_theme_font_override("font", UiKit.heading_font())
	_detail = VBoxContainer.new()
	_detail.name = "Detail"
	_detail.add_theme_constant_override("separation", 8)
	det.add_child(_detail)

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(bottom)
	UiKit.label(bottom, "1 perk point per level  ·  ● passive   ◆ active (Z / G / T)   ★ final perk  ·  K close", 13, UiKit.DIM)


## A dark stone column at the side of the tree.
func _side(parent: Node, width: float) -> VBoxContainer:
	var frame := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = SIDE_BG
	sb.border_color = EDGE
	sb.set_border_width_all(2)
	sb.set_content_margin_all(10)
	frame.add_theme_stylebox_override("panel", sb)
	frame.custom_minimum_size = Vector2(width, 0)
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
	_reset.text = "Reset perks (%d gold, you have %d)" % [p.respec_cost(), ps.inventory.count_of("gold_coin")]
	_reset.disabled = p.points_free() == p.points_total()
	tree.progress = p
	if tree.selected == "":
		tree.selected = _first_to_learn(p)
	tree.rebuild()
	tree.select(tree.selected)
	_fill_skills(p)
	_fill_detail()


## Opens on a perk you could learn now (else the first one).
static func _first_to_learn(p: Progression) -> String:
	for id in Progression.PERKS:
		if p.why_not(id) == "":
			return id
	return Progression.PERKS.keys()[0]


## A perk's picture (assets/icons/perks/, cut from the ChatGPT sheets in assets/concepts/perks/), or null.
static func perk_icon(id: String) -> Texture2D:
	var path := "res://assets/icons/perks/%s.png" % id
	return load(path) if ResourceLoader.exists(path) else null


# ---------- left: the skills ----------

func _fill_skills(p: Progression) -> void:
	UiKit.clear(_skills)
	for s in Progression.SKILLS:
		_skills.add_child(_skill_row(s, p))


func _skill_row(s: String, p: Progression) -> Control:
	var info: Array = Progression.SKILL_INFO[s]
	var lv: int = p.skill_level[s]
	var open := s == _open_skill
	var card := PanelContainer.new()
	card.name = "Skill_" + s
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("2a241c") if open else Color("1d1914")
	sb.border_color = Color("8a5a22") if open else Color("3e3020")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(5)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	card.add_theme_stylebox_override("panel", sb)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.gui_input.connect(func(e: InputEvent) -> void:
		var mb := e as InputEventMouseButton
		if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_open_skill = "" if _open_skill == s else s  # only one open at a time
			_fill_skills(_progress()))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(v)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(row)
	var nm := UiKit.label(row, info[0], 14, UiKit.TEXT)
	nm.custom_minimum_size = Vector2(92, 0)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 6)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.max_value = Progression.skill_xp_to_next(lv)
	bar.value = p.skill_xp[s] if lv < Progression.MAX_SKILL else bar.max_value
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(bar)
	var next := 100
	for m in Progression.MILESTONES:
		if lv < m:
			next = m
			break
	UiKit.label(row, "★%d" % next if lv < Progression.MAX_SKILL else "Master", 12, UiKit.DIM)
	var lvl := UiKit.label(row, str(lv), 14, UiKit.AMBER)
	lvl.custom_minimum_size = Vector2(26, 0)
	lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	for c in row.get_children():
		(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	if open:
		_wrap(v, "[color=#f6cf7a][b]Every 10 levels:[/b][/color] %s" % info[1], 12)
		for i in Progression.MILESTONES.size():
			var m: int = Progression.MILESTONES[i]
			var got := lv >= m
			var col := "#f6cf7a" if got else "#a89a82"
			var togo := "" if got else "  [color=#a89a82]· %d to go[/color]" % (m - lv)
			_wrap(v, "[color=%s][b]★%d[/b][/color]  [color=%s]%s[/color]%s" % [col, m, "#f1e7d3" if got else "#a89a82", info[2][i], togo], 12)
	return card


func _wrap(parent: Node, bb: String, size: int) -> RichTextLabel:
	var t := RichTextLabel.new()
	t.bbcode_enabled = true
	t.fit_content = true
	t.scroll_active = false
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size = Vector2(250, 0)
	t.add_theme_font_size_override("normal_font_size", size)
	t.add_theme_font_size_override("bold_font_size", size)
	t.add_theme_color_override("default_color", UiKit.TEXT)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.text = bb
	parent.add_child(t)
	return t


# ---------- right: the chosen perk ----------

## The text without "(not in the game yet)" and friends; `later` says whether it had one.
static func perk_text(id: String) -> Dictionary:
	var t: String = Progression.PERKS[id][5]
	var re := RegEx.create_from_string("\\s*\\([^)]*\\byet\\)")
	var later := re.search(t) != null
	return {text = re.sub(t, "", true), later = later}


func _fill_detail() -> void:
	UiKit.clear(_detail)
	var p := _progress()
	var id := tree.selected
	if p == null or not Progression.PERKS.has(id):
		return
	var info: Array = Progression.PERKS[id]
	var have := p.perk_rank(id)
	var why := p.why_not(id)
	var active: bool = info[3]
	var color: Color = PerkTree.COLORS[info[0]]
	var pic := TextureRect.new()
	pic.name = "Pic"
	pic.texture = perk_icon(id)
	pic.custom_minimum_size = Vector2(124, 124)
	pic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_SCALE
	var mat := ShaderMaterial.new()
	mat.shader = PerkTree.KNOB_SHADER
	mat.set_shader_parameter("diamond", active)
	mat.set_shader_parameter("ring", PerkTree.GOLD if have > 0 else color)
	mat.set_shader_parameter("ring_width", 0.06)
	pic.material = mat
	_detail.add_child(pic)
	var title := UiKit.label(_detail, ("★ " if PerkTree.is_final(id) else "") + info[4], 21, UiKit.AMBER)
	title.add_theme_font_override("font", UiKit.heading_font())
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var chips := HBoxContainer.new()
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	chips.add_theme_constant_override("separation", 6)
	_detail.add_child(chips)
	var bname := ""
	for br in BRANCHES:
		if br[0] == info[0]:
			bname = br[1]
	_chip(chips, bname, color)
	_chip(chips, "◆ Active" if active else "● Passive", UiKit.DIM)
	if PerkTree.is_final(id):
		_chip(chips, "Final perk", UiKit.DIM)
	var pips := HBoxContainer.new()
	pips.alignment = BoxContainer.ALIGNMENT_CENTER
	pips.add_theme_constant_override("separation", 0)
	_detail.add_child(pips)
	UiKit.label(pips, "◆ ".repeat(have), 18, PerkTree.GOLD)
	UiKit.label(pips, "◇ ".repeat(int(info[1]) - have), 18, Color("7a5426"))
	var txt := perk_text(id)
	var desc := UiKit.label(_detail, txt.text + ".", 15, UiKit.TEXT)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(260, 0)
	var kv := GridContainer.new()
	kv.columns = 2
	kv.add_theme_constant_override("h_separation", 10)
	kv.add_theme_constant_override("v_separation", 3)
	_detail.add_child(kv)
	_kv(kv, "Points", "%d of %d" % [have, info[1]])
	if active:
		var slot := p.ability_slots().find(id)
		var use := ("Press %s" % KEY_NAMES[slot]) if slot >= 0 else ("No free key (the first 3 active perks get Z, G, T)" if have > 0 else "Goes on Z, G or T once learned")
		_kv(kv, "Use", use)
		var cd: float = Progression.ACTIVE[id]
		_kv(kv, "Recharge", ("%s min" % String.num(cd / 60.0, 1)) if cd >= 60.0 else ("%d s" % cd))
	else:
		_kv(kv, "Use", "Always on")
	_kv(kv, "Needs", Progression.PERKS[info[2]][4] if info[2] != "" else "Nothing: first in the branch")
	if txt.later:
		var warn := UiKit.label(_detail, "Planned. This needs a game system that isn't built yet.", 13, Color("e6b27a"))
		warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		warn.custom_minimum_size = Vector2(260, 0)
	var b := UiKit.gold_button(Button.new(), 15)
	b.name = "Learn"
	b.text = "Fully learned" if have >= int(info[1]) else "Learn  ·  1 point"
	b.custom_minimum_size = Vector2(0, 40)
	b.disabled = why != ""
	b.pressed.connect(func():
		GameAuthority.instance.ask_buy_perk(id)
		get_tree().create_timer(0.15).timeout.connect(refresh))
	_detail.add_child(b)
	if why != "" and have < int(info[1]):
		UiKit.label(_detail, why, 13, UiKit.DIM).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _chip(parent: Node, text: String, color: Color) -> void:
	var l := UiKit.label(parent, text, 12, color)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = color if color != UiKit.DIM else Color("5a4730")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	l.add_theme_stylebox_override("normal", sb)


func _kv(grid: GridContainer, k: String, v: String) -> void:
	UiKit.label(grid, k, 13, UiKit.DIM)
	var l := UiKit.label(grid, v, 13, UiKit.TEXT)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(190, 0)
