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
	card = Vector4(14, 14, 14, 14), tooltip = Vector4(16, 16, 16, 16), divider = Vector4(20, 0, 20, 0),
}
const AMBER := Color(1.0, 0.8, 0.45)  ## titles and headings
const TEXT := Color(0.93, 0.87, 0.76)  ## normal text
const DIM := Color(0.68, 0.6, 0.5)  ## hints
const DARK_TEXT := Color(0.18, 0.1, 0.04)  ## on gold buttons
const MISSING := Color(1.0, 0.45, 0.4)  ## not enough of something

static var _styles := {}


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
	b.focus_mode = Control.FOCUS_NONE
	return b


## A thin gold line between parts of a panel.
static func divider(parent: Node) -> Control:
	var d := Panel.new()
	d.add_theme_stylebox_override("panel", style("divider", 0))
	d.custom_minimum_size = Vector2(0, 11)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(d)
	return d
