extends TestCase
## Item pictures (F17): every item has one, and they load as small square pictures.
## Pictures live in assets/icons/<id>.png and are made by tools/asset_forge/icons.py.


func test_every_item_has_an_icon() -> void:
	var missing := []
	for id in Items.ids():
		if Items.icon(id) == null:
			missing.append(id)
	check(missing.is_empty(), "items without a picture: %s" % [missing])


func test_icons_are_small_squares() -> void:
	var tex := Items.icon("stone")
	check(tex != null, "stone has a picture")
	if tex:
		check_eq(tex.get_width(), 128, "128 pixels wide")
		check_eq(tex.get_height(), 128, "128 pixels tall")


func test_runes_share_their_colour_picture() -> void:
	check(Items.icon("rune_ochre_m1") != null, "a rune finds its colour's picture")
	check(Items.icon("rune_ochre_m1") == Items.icon("rune_ochre_f6"), "same colour = same picture")
	check(Items.icon("rune_ochre_m1") != Items.icon("rune_cobalt_m1"), "different colour = different picture")


func test_unknown_item_has_no_icon() -> void:
	check(Items.icon("not_a_real_item") == null, "no picture -> null (HUD falls back to colour + short label)")
