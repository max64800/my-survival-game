class_name SkillsPanel
extends PanelContainer
## The skills window (K key): your 14 skills (they grow by doing, with a ★ perk at 25/50/75/100),
## then the perk tree: 1 point per level, 4 branches. A perk opens once the one before it has a point.
## ◆ = active perk: it goes on an ability key (Z / G / T). Resetting your points costs gold coins.

const BRANCHES := [["toughness", "Bones"], ["fighting", "Fists"], ["utility", "Hands"], ["together", "Heart"]]  ## names (owner, Nov 19); ids stay

var peer_id := 1
var _body: VBoxContainer
var _points: Label
var _level: Label
var _reset: Button
const ICONS := {toughness = "helm_shell", fighting = "sword_stone", utility = "pickaxe_stone", together = "campfire"}
const KEY_NAMES := ["Z", "G", "T"]
const BACKGROUND := "res://assets/ui/skills_background.jpg"


## "Dwarf workshop" look (owner F187): a column per skill, each perk a card with what it does.
## Learned ranks glow gold; ones you can't take yet are faded (hover says why).
func _ready() -> void:
	UiKit.panel(self)
	if ResourceLoader.exists(BACKGROUND):  # a painted dwarf hall behind the window (ChatGPT, Nov 19)
		var bg := TextureRect.new()
		bg.name = "Background"
		bg.texture = load(BACKGROUND)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.modulate = Color(0.55, 0.55, 0.55)  # darker, so the cards and text stay easy to read
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	box.add_child(top)
	_level = UiKit.label(top, "", 16, UiKit.DIM)
	_level.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_level.size_flags_stretch_ratio = 1.0
	UiKit.title(top, "Skills")
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", UiKit.style("tab_selected", 6, 24))
	plate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	plate.size_flags_stretch_ratio = 1.0
	top.add_child(plate)
	_points = UiKit.label(plate, "", 17, UiKit.AMBER)
	_points.add_theme_font_override("font", UiKit.heading_font())
	_points.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1180, 540)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_body)
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 16)
	box.add_child(bottom)
	UiKit.label(bottom, "Skills grow by doing (★ at 25, 50, 75, 100). 1 perk point per level. ◆ = active (Z / G / T).  ·  K close", 13, UiKit.DIM)
	_reset = UiKit.dark_button(Button.new(), 13)
	_reset.name = "Reset"
	_reset.pressed.connect(func():
		GameAuthority.instance.ask_respec()
		get_tree().create_timer(0.15).timeout.connect(refresh))
	bottom.add_child(_reset)


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
	for c in _body.get_children():
		c.queue_free()
	_body.add_child(_skill_grid(p))
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 12)
	_body.add_child(columns)
	for br in BRANCHES:
		var frame := PanelContainer.new()
		frame.add_theme_stylebox_override("panel", UiKit.style("card", 10))
		columns.add_child(frame)
		var col := VBoxContainer.new()
		col.custom_minimum_size = Vector2(270, 0)
		col.add_theme_constant_override("separation", 6)
		frame.add_child(col)
		var head := PanelContainer.new()
		head.add_theme_stylebox_override("panel", UiKit.style("tab", 6, 22))
		col.add_child(head)
		var hrow := HBoxContainer.new()
		hrow.alignment = BoxContainer.ALIGNMENT_CENTER
		head.add_child(hrow)
		var ic := TextureRect.new()
		ic.texture = Items.icon(ICONS.get(br[0], ""))
		ic.custom_minimum_size = Vector2(26, 26)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hrow.add_child(ic)
		UiKit.label(hrow, br[1], 16, UiKit.AMBER).add_theme_font_override("font", UiKit.heading_font())
		for id in Progression.PERKS:
			if Progression.PERKS[id][0] != br[0]:
				continue
			col.add_child(_perk_card(id, p))


## Every skill: its level, a bar to the next level, and its next ★ perk (hover: all four).
func _skill_grid(p: Progression) -> Control:
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UiKit.style("card", 10))
	var grid := GridContainer.new()
	grid.name = "SkillGrid"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 4)
	frame.add_child(grid)
	for s in Progression.SKILLS:
		var info: Array = Progression.SKILL_INFO[s]
		var lv: int = p.skill_level[s]
		var row := HBoxContainer.new()
		row.name = "Skill_" + s
		row.add_theme_constant_override("separation", 8)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UiKit.label(row, "%s %d" % [info[0], lv], 15, UiKit.AMBER if lv > 0 else UiKit.TEXT).custom_minimum_size = Vector2(150, 0)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(120, 10)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.max_value = Progression.skill_xp_to_next(lv)
		bar.value = p.skill_xp[s] if lv < Progression.MAX_SKILL else bar.max_value
		row.add_child(bar)
		var next := ""
		for i in Progression.MILESTONES.size():
			if lv < Progression.MILESTONES[i]:
				next = "★%d: %s" % [Progression.MILESTONES[i], info[2][i]]
				break
		var nl := UiKit.label(row, next if next != "" else "Master!", 13, UiKit.DIM)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nl.clip_text = true
		var tip := ["%s: every 10 levels %s" % [info[0], info[1]]]
		for i in 4:
			tip.append("%s ★%d: %s" % ["✔" if lv >= Progression.MILESTONES[i] else "  ", Progression.MILESTONES[i], info[2][i]])
		row.tooltip_text = "\n".join(tip)
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		grid.add_child(row)
	return frame


## A perk's picture (assets/icons/perks/, cut from the ChatGPT sheets in assets/concepts/perks/), or null.
static func perk_icon(id: String) -> Texture2D:
	var path := "res://assets/icons/perks/%s.png" % id
	return load(path) if ResourceLoader.exists(path) else null


func _perk_card(id: String, p: Progression) -> Control:
	var info: Array = Progression.PERKS[id]
	var rank := p.perk_rank(id)
	var why := p.why_not(id)
	var card := PanelContainer.new()
	card.name = "Perk_" + id
	card.add_theme_stylebox_override("panel", UiKit.style("slot_selected" if rank > 0 else "slot", 8, 12))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)
	var pic := TextureRect.new()
	pic.texture = perk_icon(id)
	pic.custom_minimum_size = Vector2(52, 52)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(pic)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 0)
	row.add_child(text)
	var slot := p.ability_slots().find(id)
	var tag: String = ("  ◆ " + (KEY_NAMES[slot] if slot >= 0 else "active")) if info[3] else ""
	UiKit.label(text, "%s  %d/%d%s" % [info[4], rank, info[1], tag], 15, UiKit.AMBER if rank > 0 else UiKit.TEXT)
	var eff := UiKit.label(text, info[5] + (" (recharge %d s)" % Progression.ACTIVE[id] if info[3] else ""), 13, UiKit.DIM)
	eff.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	eff.custom_minimum_size = Vector2(170, 0)
	var b := UiKit.gold_button(Button.new(), 13)
	b.name = "Learn"
	b.text = "Learn"
	b.custom_minimum_size = Vector2(70, 36)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.disabled = why != ""
	b.tooltip_text = why if why != "" else "Costs 1 point"
	card.tooltip_text = b.tooltip_text
	b.visible = rank < int(info[1])
	b.pressed.connect(func():
		GameAuthority.instance.ask_buy_perk(id)
		get_tree().create_timer(0.15).timeout.connect(refresh))
	row.add_child(b)
	if why != "" and rank == 0:
		card.modulate = Color(1, 1, 1, 0.55)
	return card
