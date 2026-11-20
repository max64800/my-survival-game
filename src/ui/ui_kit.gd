class_name UiKit
## The "dwarf workshop" look for every menu (owner F187): dark oak frames with iron brackets,
## dark stone-brown insides, warm amber text, gold buttons. The pieces are cut from the
## approved kit sheet by tools/ui_kit/cut_ui_kit.py into assets/ui/kit/.
## Each piece is a "9-slice": the corners keep their size and only the middle stretches, so
## brackets and bevels never smear (MARGINS = how far in from each edge the corners reach).

const DIR := "res://assets/ui/kit/"
const MARGINS := {
	panel = Vector4(30, 30, 30, 30), panel_title = Vector4(32, 32, 32, 32),
	slot = Vector4(14, 14, 14, 14), slot_selected = Vector4(14, 14, 14, 14),
	button_gold = Vector4(16, 14, 16, 14), button_gold_hover = Vector4(16, 14, 16, 14),
	button_gold_pressed = Vector4(16, 14, 16, 14), button_dark = Vector4(16, 14, 16, 14),
	tab = Vector4(24, 14, 24, 14), tab_selected = Vector4(24, 14, 24, 14),
	slider_track = Vector4(16, 0, 16, 0), slider_fill = Vector4(16, 0, 16, 0),
	card = Vector4(14, 14, 14, 14), tooltip = Vector4(16, 16, 16, 16), divider = Vector4(20, 0, 20, 0),
}
const AMBER := Color(1.0, 0.8, 0.45)  ## titles and headings
const TEXT := Color(0.93, 0.87, 0.76)  ## normal text
const DIM := Color(0.68, 0.6, 0.5)  ## hints
const DARK_TEXT := Color(0.18, 0.1, 0.04)  ## on gold buttons
const MISSING := Color(1.0, 0.45, 0.4)  ## not enough of something

static var _styles := {}
static var _heading: Font


## Titles and buttons: Cinzel Bold (SIL Open Font Licence, assets/fonts/). Everything else uses the game's
## default font, Alegreya Sans (project setting gui/theme/custom_font).
static func heading_font() -> Font:
	if _heading == null:
		var f := FontVariation.new()
		f.base_font = load("res://assets/fonts/Cinzel.ttf")
		f.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 700}
		_heading = f
	return _heading


## A stretchable style from one kit piece. `pad` = extra space between the frame and what's inside;
## `pad_x` (if set) = the space left and right instead, so text stays clear of riveted ends.
static func style(piece: String, pad: float = -1.0, pad_x: float = -1.0) -> StyleBoxTexture:
	var key := "%s|%s|%s" % [piece, pad, pad_x]
	if not _styles.has(key):
		var s := StyleBoxTexture.new()
		s.texture = load(DIR + piece + ".png")
		var m: Vector4 = MARGINS[piece]
		s.texture_margin_left = m.x
		s.texture_margin_top = m.y
		s.texture_margin_right = m.z
		s.texture_margin_bottom = m.w
		if pad >= 0.0:
			s.set_content_margin_all(pad)
		if pad_x >= 0.0:
			s.content_margin_left = pad_x
			s.content_margin_right = pad_x
		_styles[key] = s
	return _styles[key]


## A big framed panel (bag, crafting, chests...).
static func panel(p: PanelContainer, pad: float = 22.0) -> void:
	p.add_theme_stylebox_override("panel", style("panel", pad))


## A panel's title on a riveted plaque, centred at the top.
static func title(parent: Node, text: String) -> Label:
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", style("tab", 6, 26))
	plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	plate.custom_minimum_size = Vector2(170, 0)
	parent.add_child(plate)
	var l := label(plate, text, 21, AMBER)
	l.add_theme_font_override("font", heading_font())
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_constant_override("outline_size", 4)
	l.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.02))
	return l


static func label(parent: Node, text: String = "", size: int = 15, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


## The big gold button (Craft, Upgrade...).
static func gold_button(b: Button, font_size: int = 16) -> Button:
	b.add_theme_stylebox_override("normal", style("button_gold", 8))
	b.add_theme_stylebox_override("hover", style("button_gold_hover", 8))
	b.add_theme_stylebox_override("pressed", style("button_gold_pressed", 8))
	b.add_theme_stylebox_override("disabled", style("button_dark", 8))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, DARK_TEXT)
	b.add_theme_color_override("font_disabled_color", DIM)
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_font_override("font", heading_font())
	b.focus_mode = Control.FOCUS_NONE
	return b


## A dark button; toggle buttons (×1 ×5 All, tabs) glow gold while picked.
static func dark_button(b: Button, font_size: int = 14) -> Button:
	b.add_theme_stylebox_override("normal", style("tab", 6, 22))
	b.add_theme_stylebox_override("hover", style("tab_selected", 6, 22))
	b.add_theme_stylebox_override("pressed", style("tab_selected", 6, 22))
	b.add_theme_stylebox_override("hover_pressed", style("tab_selected", 6, 22))
	b.add_theme_stylebox_override("disabled", style("tab", 6, 22))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_focus_color"]:
		b.add_theme_color_override(c, TEXT)
	b.add_theme_color_override("font_pressed_color", AMBER)
	b.add_theme_color_override("font_hover_pressed_color", AMBER)
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_font_override("font", heading_font())
	b.focus_mode = Control.FOCUS_NONE
	return b


## A slider in the kit's look: gold fill, dark track, a gold gem knob.
static func slider(s: HSlider) -> HSlider:
	var track := style("slider_track")
	track.content_margin_top = 7
	track.content_margin_bottom = 7
	var fill := style("slider_fill")
	s.add_theme_stylebox_override("slider", track)
	s.add_theme_stylebox_override("grabber_area", fill)
	s.add_theme_stylebox_override("grabber_area_highlight", fill)
	var knob: Texture2D = load(DIR + "slider_knob.png")
	s.add_theme_icon_override("grabber", knob)
	s.add_theme_icon_override("grabber_highlight", knob)
	s.focus_mode = Control.FOCUS_NONE
	s.custom_minimum_size.y = 30
	return s


## A text box: dark inset, amber when you're typing in it.
static func line_edit(e: LineEdit) -> LineEdit:
	e.add_theme_stylebox_override("normal", style("card", 10, 14))
	e.add_theme_stylebox_override("focus", style("slot_selected", 10, 14))
	e.add_theme_color_override("font_color", TEXT)
	e.add_theme_color_override("font_placeholder_color", DIM)
	e.add_theme_font_size_override("font_size", 16)
	return e


## A thin gold line between parts of a panel.
static func divider(parent: Node) -> Control:
	var d := Panel.new()
	d.add_theme_stylebox_override("panel", style("divider", 0))
	d.custom_minimum_size = Vector2(0, 11)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(d)
	return d


## Empties a box right away. Plain queue_free() leaves the old children in place until the next
## frame, so a panel refilled in the same frame briefly holds old + new, grows, and never shrinks
## back (owner: "the build menu keeps expanding every time I click").
static func clear(parent: Node) -> void:
	for c in parent.get_children():
		parent.remove_child(c)
		c.queue_free()


## Shrinks a floating panel back to just what it holds (after its content got smaller).
static func fit(panel: Control) -> void:
	panel.reset_size.call_deferred()


## Half hearts for healing (food cards): `halves` 1 = ½ heart, 2 = 1 heart ... 10 = 5 hearts.
static func hearts(halves: int, size: int = 18) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in ceili(halves / 2.0):
		var t := TextureRect.new()
		t.texture = load("res://assets/ui/heart_half.png" if i * 2 + 1 == halves else "res://assets/ui/heart.png")
		t.custom_minimum_size = Vector2(size, size)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(t)
	return box
