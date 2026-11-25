class_name SkillsPanel
extends PanelContainer
## The K window, two tabs (owner, Nov 20, F445):
##  - "Skills": the 14 skills you grow by doing, all on one page, each with its ★ perks at 25 / 50 / 75 / 100 always shown,
##    one line each; what every level gives is in the card's hover text (owner, Nov 21, F576: it showed too much).
##  - "Perks" (opens first, F576): the perk tree (PerkTreeView: 1 point per level, 4 branches; a perk opens once the one before it has a
##    point) and, on the right, the perk you clicked with its Learn button. ◆ = active perk on an ability key (Z / G / T).
##  - "Notes" (F870, owner Nov 25; J opens the window here): every first-time picture card you have seen (FirstCards).
## The window has one fixed size (switching tabs never changes it) that fits above the hotbar. It is BUILT at the
## screen's size (`ui` = how much bigger than the 1600 x 900 design), not stretched afterwards, so the letters stay
## sharp (owner, Nov 20: stretching it made everything blurry).

const BRANCHES := [["toughness", "Bones"], ["fighting", "Fists"], ["utility", "Hands"], ["together", "Heart"]]  ## names (owner, Nov 19); ids stay
const KEY_NAMES := ["Z", "G", "T"]
const BACKGROUND := "res://assets/ui/skills_background.jpg"
const MILESTONE_TEXT := "★%d"
const PAGE := Vector2(1300, 700)  ## the tabs' page, at ui = 1 (the window is about 1350 x 820)
const COLS := 4  ## skill cards per row on the Skills tab (4 rows: wide enough for every ★ line on one line, F576)

var peer_id := 1
var ui := 1.0  ## set by the HUD from the screen size (see set_ui)
var tab := "perks"  ## the Perks tab opens first (owner, Nov 21, F576)
var _level: Label
var _points: Label
var _reset: Button
var _tabs := {}  ## "skills" / "perks" -> its tab Button
var _skills: GridContainer
var _skills_page: Control
var _perks_page: Control
var _notes_page: Control
var _notes: GridContainer
var notes: FirstCards  ## the cards you have seen (the HUD hands over its FirstCards)
var _help: Label
var _tree: PerkTreeView
var _detail: VBoxContainer
var _sel := "thick_skin"


## A perk's picture (assets/icons/perks/, cut from the ChatGPT sheets in assets/concepts/perks/), or null.
static func perk_icon(id: String) -> Texture2D:
	var path := "res://assets/icons/perks/%s.png" % id
	return load(path) if ResourceLoader.exists(path) else null


func _ready() -> void:
	# F429 (owner, Nov 20: "K just shows a big box"): wrapping text measures itself very tall for a moment, and a
	# container never shrinks back by itself, so the window stayed 3216 px tall with everything off the screen.
	minimum_size_changed.connect(func(): reset_size.call_deferred())
	_build()


## The HUD calls this when the screen size changes: rebuild everything at the new size (sharp letters).
func set_ui(k: float) -> void:
	if absf(k - ui) < 0.01:
		return
	ui = k
	_build()
	if visible:
		refresh()


func _px(n: float) -> int:
	return roundi(n * ui)


func _lbl(parent: Node, text: String, size: float, color: Color, heading := false) -> Label:
	var l := UiKit.label(parent, text, _px(size), color)
	if heading:
		l.add_theme_font_override("font", UiKit.heading_font())
	return l


func _build() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	UiKit.panel(self, _px(22))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", _px(6))
	add_child(box)
	# Top row: level and kills | the two tabs | perk points and reset.
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", _px(16))
	box.add_child(top)
	_level = _lbl(top, "", 17, UiKit.DIM)
	_level.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", _px(10))
	top.add_child(tabs)
	for t in [["perks", "Perks"], ["skills", "Skills"], ["notes", "Notes"]]:
		var b := UiKit.dark_button(Button.new(), _px(22))
		b.name = "Tab_" + t[0]
		b.text = "  %s  " % t[1]
		b.custom_minimum_size = Vector2(_px(170), _px(44))
		b.pressed.connect(func(): show_tab(t[0]))
		tabs.add_child(b)
		_tabs[t[0]] = b
	var right := HBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.alignment = BoxContainer.ALIGNMENT_END
	right.add_theme_constant_override("separation", _px(14))
	top.add_child(right)
	_points = _lbl(right, "", 18, UiKit.AMBER, true)
	_reset = UiKit.dark_button(Button.new(), _px(16))
	_reset.name = "Reset"
	_reset.pressed.connect(func():
		GameAuthority.instance.ask_respec()
		get_tree().create_timer(0.15).timeout.connect(refresh))
	right.add_child(_reset)
	# The page: both tabs live in the same fixed-size box, so switching never changes the window's size.
	var page := Control.new()
	page.custom_minimum_size = PAGE * ui
	box.add_child(page)
	_skills_page = _framed(page)
	var scroll := ScrollContainer.new()  # (never needed at the design size; only a safety net on odd screens)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_skills_page.get_child(0).add_child(scroll)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_skills = GridContainer.new()
	_skills.columns = COLS
	_skills.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_skills.add_theme_constant_override("h_separation", _px(8))
	_skills.add_theme_constant_override("v_separation", _px(6))
	scroll.add_child(_skills)
	_notes_page = _framed(page)
	_notes_page.name = "NotesPage"
	var nscroll := ScrollContainer.new()
	nscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	nscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_notes_page.get_child(0).add_child(nscroll)
	_notes = GridContainer.new()
	_notes.name = "Notes"
	_notes.columns = 3
	_notes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_notes.add_theme_constant_override("h_separation", _px(10))
	_notes.add_theme_constant_override("v_separation", _px(10))
	nscroll.add_child(_notes)
	_perks_page = HBoxContainer.new()
	_perks_page.set_anchors_preset(Control.PRESET_FULL_RECT)
	_perks_page.add_theme_constant_override("separation", _px(8))
	page.add_child(_perks_page)
	_tree = PerkTreeView.new()
	_tree.name = "Tree"
	_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tree.picked.connect(func(id): _sel = id; _tree.selected = id; _tree.refresh(); _show_detail())
	_perks_page.add_child(_tree)
	var side := PanelContainer.new()
	side.add_theme_stylebox_override("panel", UiKit.style("card", _px(12)))
	side.custom_minimum_size.x = _px(380)
	_perks_page.add_child(side)
	_detail = VBoxContainer.new()
	_detail.add_theme_constant_override("separation", _px(6))
	side.add_child(_detail)
	_help = _lbl(box, "", 15, UiKit.DIM)
	_help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	show_tab(tab)


## A wooden card filling the page, with a VBox inside.
func _framed(page: Control) -> PanelContainer:
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UiKit.style("card", _px(12)))
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.add_child(frame)
	var v := VBoxContainer.new()
	frame.add_child(v)
	return frame


func show_tab(which: String) -> void:
	tab = which
	_skills_page.visible = which == "skills"
	_perks_page.visible = which == "perks"
	_notes_page.visible = which == "notes"
	if which == "notes":
		_show_notes()
	for k in _tabs:
		var b: Button = _tabs[k]
		b.add_theme_color_override("font_color", UiKit.AMBER if k == which else UiKit.DIM)
		b.modulate = Color.WHITE if k == which else Color(0.8, 0.8, 0.8)
	_help.text = ("Everything new you have met. J opens this page, K the skills" if which == "notes" else
		"Skills grow by doing (dig for Mining, chop for Woodcutting...). ★ = a bonus at levels 25, 50, 75 and 100. Point at a skill to see what each level gives."
		if which == "skills" else "Circle = works by itself  ·  ◆ = press Z / G / T  ·  ★ = last perk  ·  scroll to zoom, drag to move  ·  K to close")
	if which == "perks" and _tree.progress:
		_tree.refresh.call_deferred()


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


# ---------------------------------------------------------------- the Notes tab (F870)

## One card per thing you have met: its picture, its name and its one line.
func _show_notes() -> void:
	UiKit.clear(_notes)
	var seen: Array = notes.seen if notes else []
	if seen.is_empty():
		_lbl(_notes, "Nothing yet. Each new thing you find adds a note here.", 16, UiKit.DIM)
		return
	for id in seen:
		var c: Array = FirstCards.CARDS[id]
		var card := PanelContainer.new()
		card.name = "Note_" + id
		card.add_theme_stylebox_override("panel", UiKit.style("card", _px(10)))
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", _px(10))
		card.add_child(row)
		var pic := TextureRect.new()
		pic.texture = FirstCards.picture(id)
		pic.custom_minimum_size = Vector2(_px(56), _px(56))
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(pic)
		var words := VBoxContainer.new()
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		words.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(words)
		_lbl(words, c[0], 18, UiKit.AMBER, true)
		var line := _lbl(words, c[1], 14, UiKit.TEXT)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.custom_minimum_size.x = _px(260)  # (a wrapping label needs a width, or it measures itself very tall: F429)
		_notes.add_child(card)


# ---------------------------------------------------------------- the Skills tab

func _show_skills(p: Progression = null) -> void:
	if p == null:
		p = _progress()
	UiKit.clear(_skills)
	for s in Progression.SKILLS:
		var info: Array = Progression.SKILL_INFO[s]
		var lv: int = p.skill_level[s]
		var card := PanelContainer.new()
		card.name = "Skill_" + s
		var st := UiKit.style("slot", _px(10), _px(16))  # (the frame art is 14 px: the text stays inside it)
		st.content_margin_top = _px(10)
		st.content_margin_bottom = _px(12)
		card.add_theme_stylebox_override("panel", st)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_skills.add_child(card)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", _px(3))
		card.add_child(v)
		var h := HBoxContainer.new()
		v.add_child(h)
		var name := _lbl(h, info[0], 19, UiKit.TEXT, true)
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_lbl(h, "Master" if lv >= Progression.MAX_SKILL else "Level %d" % lv, 18, UiKit.AMBER)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, _px(7))
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
		v.add_child(bar)
		card.tooltip_text = "Each level: %s" % info[1]  # (hover: kept off the card so it shows less, F576)
		for i in 4:
			var got: bool = lv >= Progression.MILESTONES[i]
			var star := _lbl(v, "%s %s  %s" % ["✓" if got else "·", MILESTONE_TEXT % Progression.MILESTONES[i], info[2][i]],
				13, UiKit.TEXT if got else UiKit.DIM)
			star.name = "Star_%d" % i
			star.autowrap_mode = TextServer.AUTOWRAP_OFF  # one line each (F576)


# ---------------------------------------------------------------- the Perks tab: the perk you clicked

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
	pic.custom_minimum_size = Vector2.ONE * _px(170)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var mat := ShaderMaterial.new()
	mat.shader = PerkTreeView._shader
	mat.set_shader_parameter("diamond", info[3])
	pic.material = mat
	_detail.add_child(pic)
	var title := _lbl(_detail, ("★ " if _sel in PerkTreeView.FINALS else "") + info[4], 25, UiKit.AMBER, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# F434 (owner, Nov 20: "very tiny text"): bigger letters and plain words, one fact per line.
	var kind := _lbl(_detail, "%s branch  ·  %s" % [branch, "◆ you press a key" if info[3] else "● works by itself"], 17, PerkTreeView.COLORS[info[0]])
	kind.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var pips := _lbl(_detail, "◆".repeat(have) + "◇".repeat(info[1] - have), 24, UiKit.AMBER)
	pips.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var planned: bool = info[5].contains("not in the game yet") or info[5].contains("(no ") or info[5].contains("don't wear out")
	var text := _lbl(_detail, info[5].get_slice(" (", 0).replace("per rank", "per point") + ".", 21, UiKit.TEXT)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size.x = _px(340)
	var slot := p.ability_slots().find(_sel)
	var lines := ["Learned: %d of %d points" % [have, info[1]]]
	if info[3]:
		lines.append("Key: " + ("press " + KEY_NAMES[slot] if slot >= 0 else ("no free key (only 3 fit on Z, G, T)" if have > 0 else "it goes on Z, G or T")))
		var cd: float = Progression.ACTIVE[_sel]
		lines.append("Use again after: %s" % ("%d min" % roundi(cd / 60.0) if cd >= 60.0 and fmod(cd, 60.0) == 0.0 else "%d s" % roundi(cd)))
	lines.append("First learn: " + (Progression.PERKS[info[2]][4] if info[2] != "" else "nothing, it's the first one"))
	for l in lines:
		var line := _lbl(_detail, l, 17, UiKit.DIM)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if planned:
		var warn := _lbl(_detail, "Not working yet: comes in a later update.", 17, UiKit.MISSING)
		warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var learn := UiKit.gold_button(Button.new(), _px(18))
	learn.name = "Learn"
	learn.text = "Fully learned" if have >= info[1] else "Learn (1 point)"
	learn.disabled = why != ""
	learn.custom_minimum_size = Vector2(0, _px(46))
	learn.pressed.connect(func():
		GameAuthority.instance.ask_buy_perk(_sel)
		get_tree().create_timer(0.15).timeout.connect(refresh))
	_detail.add_child(learn)
	if why != "" and have < info[1]:
		var w := _lbl(_detail, why, 17, UiKit.DIM)
		w.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		w.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# (owner, Nov 20: "a lot of empty space" here) how points work, at the bottom of the card
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail.add_child(gap)
	var how := _lbl(_detail, "You get 1 perk point each time your level goes up. Level up by doing anything: digging, fighting, crafting, exploring.", 16, UiKit.DIM)
	how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	how.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
