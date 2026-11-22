extends TestCase
## The home decor tabs (owner, Nov 22): every approved home piece of docs/art/DECOR-CATALOG.md is in the build menu,
## shows its own model (fits its piece box, nothing floats), costs something, has a menu picture, and hangs the way
## the catalogue says (wall pieces on walls, hanging pieces from ceilings). Pieces that clash with the decor rules wait.

const WALL := ["hm_spider_trophy", "hm_beetle_shell_trophy", "hm_snail_shell_trophy", "hm_bat_skull_plaque", "dartboard",
	"spice_shelf", "dish_rack", "tool_wall", "lantern_hook", "candle_wall_shelf"]
const CEILING := ["wind_chime", "crystal_hanging_light", "fern_basket"]
const LIGHTS := ["crystal_floor_lamp", "crystal_hanging_light", "mushroom_lamp", "glowworm_jar", "lantern_hook", "candle_wall_shelf"]
## On the catalogue's clash list (or a model that doesn't pass yet): not in the menu until the owner decides.
const WAITING := ["rocking_chair", "fur_rug", "cooking_spit", "kitchen_block", "hm_lamp_history_board",
	"bat_wing_trophy", "hm_vein_slice_frame"]


func _home() -> Array:
	return Pieces.LIST.keys().filter(func(k): return Pieces.LIST[k].group in Pieces.HOME_GROUPS)


func test_home_tabs_are_full_and_on_the_menu() -> void:
	var list := _home()
	check(list.size() >= 70, "the home tabs hold every approved piece (%d)" % list.size())
	for g in Pieces.HOME_GROUPS:
		check(BuildMenu.tab_of(g) != "", "%s is on a build menu tab" % g)
		check(BuildMenu.pieces_in(g).size() <= 25, "%s fits on screen (%d pieces)" % [g, BuildMenu.pieces_in(g).size()])
	for k in WAITING:
		check(not Pieces.LIST.has(k), "%s waits for the owner" % k)


func test_every_home_piece_has_a_model_a_cost_and_a_picture() -> void:
	for k in _home():
		var p: Dictionary = Pieces.LIST[k]
		var model := String(p.get("model", ""))
		check(ResourceLoader.exists("res://assets/models/%s.glb" % model), "%s has its model file" % k)
		for fam in p.families:
			var c := Pieces.cost(k, fam)
			check(int(c.get(fam, 0)) > 0, "%s costs %s" % [k, fam])
			for item in c:
				check(Items.DATA.has(item), "%s costs a real item (%s)" % [k, item])
			check(BuildMenu.piece_picture(k, fam) != null, "%s in %s has a menu picture" % [k, fam])
		check(PieceNode.forged_mesh(k, p.families[0]) != null, "%s shows its own model (not the code box)" % k)


func test_home_pieces_hang_the_catalogue_way() -> void:
	for k in WALL:
		check(Pieces.LIST[k].get("on_wall", false) and Pieces.LIST[k].place == "edge", "%s hangs on a wall" % k)
	for k in CEILING:
		check(Pieces.LIST[k].place == "ceiling", "%s hangs from a ceiling" % k)
	for k in LIGHTS:
		check(Pieces.LIST[k].has("light"), "%s gives light" % k)
	check(Pieces.LIST.hammock.get("use", "") == "bed" and Pieces.LIST.bunk_bed.get("use", "") == "bed", "you can sleep in the hammock and bunks")
	check(Pieces.LIST.hm_carved_high_chair.get("use", "") == "sit", "you can sit in the high chair")
	check(Pieces.LIST.wardrobe.get("use", "") == "store", "the wardrobe stores things")


func test_trophies_cost_the_creature() -> void:
	check(Pieces.cost("hm_snail_shell_trophy", "plank_root").has("shell_piece"), "snail trophy: snail shell")
	check(Pieces.cost("hm_beetle_shell_trophy", "plank_root").has("chitin_plate"), "beetle trophy: beetle plates")
	check(Pieces.cost("hm_spider_trophy", "plank_root").has("venom_sac"), "spider trophy: spider parts")
	check(not Pieces.cost("wardrobe", "plank_root").has("rope"), "furniture prices: no house-building rope")
