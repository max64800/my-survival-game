class_name ItemTipSlot
extends Panel
## A bag/hotbar slot whose hover tip is a framed box with coloured text (F831, owner Nov 24: "better explanation
## of slash / blunt / pierce, right now it's just a lot of text"). tooltip_text holds BBCode ([b], [color]).
## The tip grows with the bag panels (Hud._layout_panels scales them), so it stays readable on big screens.

const WIDTH := 330.0
const FONT := 17


func _make_custom_tooltip(for_text: String) -> Object:
	var k := clampf(get_global_transform_with_canvas().get_scale().x, 1.0, 2.5)
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", _style(k))
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.scroll_active = false
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size.x = WIDTH * k
	text.add_theme_font_size_override("normal_font_size", roundi(FONT * k))
	text.add_theme_font_size_override("bold_font_size", roundi((FONT + 3) * k))
	text.add_theme_font_override("bold_font", UiKit.heading_font())
	text.add_theme_color_override("default_color", Color(0.93, 0.87, 0.76))
	text.text = for_text
	box.add_child(text)
	return box


static func _style(k: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.13, 0.09, 0.06, 0.96)
	s.border_color = Color(0.72, 0.5, 0.25)
	s.set_border_width_all(maxi(2, roundi(2 * k)))
	s.set_corner_radius_all(roundi(6 * k))
	s.set_content_margin_all(10 * k)
	return s
