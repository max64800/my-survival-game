class_name BossBar
extends VBoxContainer
## The mini boss's name and a long health bar at the top of the screen (owner, Nov 20, F237).
## It follows one creature and hides itself when that creature dies or is gone.
## Hook-in (PC, not done yet): in Hud._build `boss_bar = BossBar.new(); root.add_child(boss_bar)`; when a fight with a
## mini boss starts: `hud.boss_bar.track(monster, DungeonKeys.KEYS[key].boss)`.

const WIDTH := 520.0

var target: Monster
var title: Label
var bar: ProgressBar


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	position += Vector2(-WIDTH * 0.5, 40)
	custom_minimum_size = Vector2(WIDTH, 0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	title = UiKit.label(self, "", 20, UiKit.AMBER)
	title.add_theme_font_override("font", UiKit.heading_font())
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(WIDTH, 16)
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.75, 0.18, 0.15)
	bar.add_theme_stylebox_override("fill", fill)
	add_child(bar)


func track(m: Monster, boss_name: String) -> void:
	target = m
	title.text = boss_name
	_process(0.0)


func _process(_delta: float) -> void:
	visible = is_instance_valid(target) and target.is_alive()
	if visible:
		bar.max_value = target.max_hp()
		bar.value = target.hp
