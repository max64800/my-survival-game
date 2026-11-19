class_name LearnedCards
extends VBoxContainer
## Owner (Nov 19): "any time you learn a recipe it should say on the left-hand side, like a pop-up, and actually show
## you what you've learned." A card slides in on the left middle of the screen: the item's picture, "Recipe learned",
## its name and where you make it. It stays a few seconds and fades. Several stack (newest at the bottom).

const STAY := 6.0  ## seconds on screen
const MAX_CARDS := 4
const ICON := 64.0


func _ready() -> void:
	name = "LearnedCards"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 8)
	anchor_left = 0.0
	anchor_right = 0.0
	anchor_top = 0.5
	anchor_bottom = 0.5
	offset_left = 20.0
	offset_right = 20.0 + 330.0
	offset_top = -120.0
	offset_bottom = 120.0
	alignment = BoxContainer.ALIGNMENT_CENTER


## `title`: "Recipe learned" / "Blueprint learned". `what`: the thing's name. `hint`: where to make it.
func show_card(title: String, what: String, icon: Texture2D, hint: String) -> Control:
	while get_child_count() >= MAX_CARDS:
		var old := get_child(0)
		remove_child(old)
		old.queue_free()
	var card := PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", UiKit.style("card", 10.0))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)
	var pic := TextureRect.new()
	pic.texture = icon
	pic.custom_minimum_size = Vector2(ICON, ICON)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(pic)
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", 0)
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(words)
	var t := UiKit.label(words, title, 14, UiKit.AMBER)
	t.add_theme_font_override("font", UiKit.heading_font())
	t.name = "Title"
	UiKit.label(words, what, 20, UiKit.TEXT).name = "What"
	if hint != "":
		UiKit.label(words, hint, 13, UiKit.DIM).name = "Hint"
	add_child(card)
	# Slide in from the left, stay, fade out.
	card.modulate.a = 0.0
	var tw := card.create_tween()
	tw.tween_property(card, "modulate:a", 1.0, 0.25)
	tw.tween_interval(STAY)
	tw.tween_property(card, "modulate:a", 0.0, 0.8)
	tw.tween_callback(card.queue_free)
	Sfx.ui("craft", -8.0)
	return card


## A recipe the group just learned (GameAuthority.learned).
func show_recipe(recipe_id: String) -> Control:
	var r: Dictionary = Recipes.LIST.get(recipe_id, {})
	if r.is_empty():
		return null
	var st: String = r.station
	var where := "Make it by hand" if st == Recipes.HAND else "Make it at the " + Items.display_name(Recipes.station_type(st))
	return show_card("Recipe learned", Items.display_name(r.output), Items.icon(r.output), where)


func show_blueprint(what: String, page_id: String) -> Control:
	return show_card("Blueprint learned", what, Items.icon(page_id), "V opens your blueprints")
