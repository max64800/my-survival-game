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


func _ready() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.06, 0.05, 0.05, 0.94)
	bg.set_corner_radius_all(10)
	bg.set_content_margin_all(14)
	add_theme_stylebox_override("panel", bg)
	var box := VBoxContainer.new()
	add_child(box)
	_points = Label.new()
	_points.add_theme_font_size_override("font_size", 20)
	box.add_child(_points)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1160, 560)
	box.add_child(scroll)
	_body = VBoxContainer.new()
	scroll.add_child(_body)


func refresh() -> void:
	var auth := GameAuthority.instance
	var ps: GameAuthority.PlayerState = auth.get_player(peer_id) if auth else null
	if ps == null:
		return
	var p := ps.progress
	_points.text = "Level %d · %d perk point%s to spend · K to close" % [p.level, p.points_free(), "" if p.points_free() == 1 else "s"]
	for c in _body.get_children():
		c.queue_free()
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 18)
	_body.add_child(columns)
	for br in BRANCHES:
		var col := VBoxContainer.new()
		col.custom_minimum_size = Vector2(270, 0)
		columns.add_child(col)
		var head := Label.new()
		head.text = "%s  (skill %d)" % [br[1], p.skill_level[br[0]]]
		head.add_theme_font_size_override("font_size", 18)
		head.add_theme_color_override("font_color", Color(1.0, 0.8, 0.5))
		col.add_child(head)
		for id in Progression.PERKS:
			if Progression.PERKS[id][0] != br[0]:
				continue
			col.add_child(_perk_button(id, p))


func _perk_button(id: String, p: Progression) -> Button:
	var info: Array = Progression.PERKS[id]
	var b := Button.new()
	var why := p.why_not(id)
	b.text = "%s  %d/%d\n%s" % [id.capitalize(), p.perk_rank(id), info[1], PERK_TEXT.get(id, "")]
	b.tooltip_text = why if why != "" else "Costs %d point%s" % [info[2], "" if info[2] == 1 else "s"]
	b.disabled = why != ""
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(260, 52)
	b.pressed.connect(func():
		GameAuthority.instance.ask_buy_perk(id)
		get_tree().create_timer(0.15).timeout.connect(refresh))
	return b
