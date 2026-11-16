class_name SkillsPanel
extends PanelContainer
## The skill trees (K key). Spend perk points from levelling up. Each perk also needs
## a minimum skill level, which only grows by doing that kind of work.

const BRANCHES := [["mining", "Miner"], ["fighting", "Warrior"], ["smithing", "Smith & Builder"], ["survival", "Survivor & Cook"]]
const PERK_TEXT := {
	"strong_swing": "+5% dig power", "light_arms": "−15% swing stamina", "magnet_pockets": "Pickup radius +50%",
	"lucky_strike": "+5% double ore", "crystal_ear": "+1 crystal per spot", "wide_bite": "Bigger dug spots",
	"prospectors_eye": "See ore through rock", "mole_stride": "+10% run speed with a pickaxe", "rock_sense": "Cave-in warning",
	"hard_rock_hands": "Border rock −1 hit", "vein_breaker": "Every 8th ore hit breaks the whole vein",
	"thick_skin": "+5% max health", "second_wind": "+10% stamina regen", "heavy_hand": "+6% heavy attacks",
	"steady_guard": "Parry window +15%", "shield_wall": "−15% block stamina", "roll_master": "−15% dodge stamina",
	"combo_keeper": "Longer combo timing", "stunner": "Parries stun +10%", "pack_breaker": "+25% vs pack leaders",
	"last_stand": "Below 20% health: −20% damage taken", "executioner": "Dazed enemies take +30%",
	"steady_hammer": "+5 Smithing for quality", "hot_hearth": "Smelt 15% faster", "fuel_saver": "Half smelter fuel",
	"thrifty_smith": "10% chance to save an ingot", "quick_mason": "Bonus masonry output", "long_reach": "Build range +3 m",
	"blueprint_foreman": "Blueprints build 25% faster", "strong_beams": "Beams hold 25% more", "upgrade_expert": "Upgrades −25% ingots",
	"reforge": "Re-roll an item's quality", "iron_belly": "Hunger −10%", "camel_throat": "Thirst −10%",
	"good_cook": "Your food lasts +10%", "forager": "+1 from wild plants", "green_thumb": "Farms grow 15% faster",
	"big_harvest": "Chance of +1 harvest", "hunter": "Chance of +1 from animals", "deep_pockets": "+3 bag slots",
	"hearty": "Buff food 10% stronger", "way_home": "Run faster back to your grave", "fourth_plate": "A 4th food slot",
}

var peer_id := 1
var _body: VBoxContainer
var _points: Label
var _level: Label
const ICONS := {mining = "pickaxe_stone", fighting = "sword_stone", smithing = "anvil", survival = "campfire"}


## "Dwarf workshop" look (owner F187): a column per skill, each perk a card with what it does.
## Learned ranks glow gold; ones you can't take yet are faded (hover says why).
func _ready() -> void:
	UiKit.panel(self)
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
	var foot := UiKit.label(box, "Perk points come from levelling up. Each perk also needs some skill, which grows by doing that work.  ·  K close", 13, UiKit.DIM)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func refresh() -> void:
	var auth := GameAuthority.instance
	var ps: GameAuthority.PlayerState = auth.get_player(peer_id) if auth else null
	if ps == null:
		return
	var p := ps.progress
	_level.text = "Level %d" % p.level
	_points.text = "Perk points: %d" % p.points_free()
	for c in _body.get_children():
		c.queue_free()
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
		var lvl := UiKit.label(col, "skill %d" % p.skill_level[br[0]], 13, UiKit.DIM)
		lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		for id in Progression.PERKS:
			if Progression.PERKS[id][0] != br[0]:
				continue
			col.add_child(_perk_card(id, p))


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
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 0)
	row.add_child(text)
	UiKit.label(text, "%s  %d/%d" % [id.capitalize(), rank, info[1]], 15, UiKit.AMBER if rank > 0 else UiKit.TEXT)
	var eff := UiKit.label(text, PERK_TEXT.get(id, ""), 13, UiKit.DIM)
	eff.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	eff.custom_minimum_size = Vector2(170, 0)
	var b := UiKit.gold_button(Button.new(), 13)
	b.name = "Learn"
	b.text = "Learn"
	b.custom_minimum_size = Vector2(70, 36)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.disabled = why != ""
	b.tooltip_text = why if why != "" else "Costs %d point%s" % [info[2], "" if info[2] == 1 else "s"]
	card.tooltip_text = b.tooltip_text
	b.visible = rank < int(info[1])
	b.pressed.connect(func():
		GameAuthority.instance.ask_buy_perk(id)
		get_tree().create_timer(0.15).timeout.connect(refresh))
	row.add_child(b)
	if why != "" and rank == 0:
		card.modulate = Color(1, 1, 1, 0.55)
	return card
