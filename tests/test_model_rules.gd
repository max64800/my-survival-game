extends TestCase
## The owner's model rules (docs/art/MODEL-RULES.md, Nov 15) as the build menu must follow them:
## roofs per style (rule 4), round doors only (rule 5), copper for decor only, wall decor on walls,
## and every model made by a build script (rule 1). The model shapes themselves are checked by
## tools/model_check/check_models.py (Blender), which the 3D Claudes run before saving.

const SHACK := "plank_root"
const STONE := "cut_stone"
const BRICK := "clay_brick"
const COPPER := "copper_ingot"


func _menu(family: String) -> Array:
	var out := []
	for id in Pieces.LIST:
		if Pieces.LIST[id].get("group", "") != "legacy" and Pieces.allowed(id, family):
			out.append(id)
	return out


func test_stonehold_has_flat_roofs_only() -> void:
	for id in Pieces.SLOPED_ROOFS:
		check(not Pieces.allowed(id, STONE), "Stonehold can't build %s" % id)
	for id in ["flat_roof", "battlement", "battlement_corner"]:
		check(Pieces.allowed(id, STONE), "Stonehold builds %s" % id)


func test_shack_and_hearthbrick_have_sloped_roofs_only() -> void:
	for fam in [SHACK, BRICK]:
		check(not Pieces.allowed("flat_roof", fam), "%s can't build a flat roof" % fam)
		for id in Pieces.SLOPED_ROOFS:
			check(Pieces.allowed(id, fam), "%s builds %s" % [fam, id])


func test_copper_is_for_decor_and_doors_only() -> void:
	var copper := _menu(COPPER)
	copper.sort()
	check_eq(copper, ["banner", "door", "wall_sconce", "wall_shield"], "copper only makes banners, wall shields, sconces and the door")
	for id in ["wall", "floor", "roof_26", "foundation", "beam", "pillar", "stairs", "ramp", "ladder", "mine_prop", "railing", "brace"]:
		check(not Pieces.allowed(id, COPPER), "no copper %s" % id)


func test_one_round_doorway_and_one_door_per_style() -> void:
	for fam in [SHACK, STONE, BRICK]:
		var doorways := []
		for id in _menu(fam):
			var p: Dictionary = Pieces.LIST[id]
			if p.has("opening") and float(p.opening.y) >= 1.4 and id != "gateway":  # tall enough to walk through
				doorways.append(id)  # (the gateway is the fort's big round-arched gate for a double gate, owner Nov 17)
		check_eq(doorways, ["doorway"], "%s: one doorway, the round one" % fam)
		check(Pieces.LIST.doorway.get("round", false), "the doorway is round")
		check(Pieces.allowed("door", fam), "%s has its own door" % fam)
	check(not BuildMenu.pieces_in("wall").has("arch_doorway"), "the arched doorway isn't offered any more")


func test_old_saves_with_removed_pieces_still_load() -> void:
	var s := Structure.new()
	s.add(1, "foundation", STONE, Vector3.ZERO, 0, true)
	s.add(2, "arch_doorway", STONE, Vector3(0, 1, 1), 0, false)
	s.add(3, "wall", COPPER, Vector3(0, 1, -1), 0, false)
	s.add(4, "roof_26", STONE, Vector3(0, 3, 0), 0, false)
	check_eq(s.pieces.size(), 4, "an old arched doorway, copper wall and stone roof still load")


func test_wall_decor_hangs_on_walls() -> void:
	for id in ["banner", "wall_shield", "wall_sconce", "banner_anvil", "banner_landscape", "bat_trophy", "crossed_pickaxes",
			"fossil_plaque", "horn_plaque", "map_board", "rune_shield", "peg_rack", "wall_torch"]:
		check(Pieces.LIST.has(id) and Pieces.LIST[id].get("on_wall", false), "%s hangs on walls" % id)
	check("tool_rack" in Station.ON_WALL, "the tool rack hangs on walls")
	# Aimed at a wall's face, it lands flat against that face, not inside the wall.
	var wall := Pieces.box("wall", Vector3(0, 0, 0), 0)
	var at := Pieces.snap("map_board", Vector3(0.3, 1.2, 0.15), Vector3(0, 0, 1), 0.0, 0, 0.0, wall, {piece = "wall", pos = Vector3.ZERO, rot = 0})
	var box := Pieces.box("map_board", at.pos, at.rot)
	check_near(box.position.z, wall.end.z, 0.01, "map board's back is on the wall's face")
	var spot := GameAuthority.wall_spot("tool_rack", Vector3(0, 1.2, 0.15), Vector3(0, 0, 1))
	check_near(spot.z - Station.size_of("tool_rack").z * 0.5, 0.15, 0.01, "tool rack's back is on the wall's face")


func test_wall_decor_models_exist() -> void:
	for id in Pieces.LIST:
		var model: String = Pieces.LIST[id].get("model", "")
		if model != "":
			check(ResourceLoader.exists("res://assets/models/%s.glb" % model), "%s has its model %s" % [id, model])
			# Until a model fits its wall spot (flat back, agreed size) the game shows a plain board instead.
			var mesh := PieceNode.forged_mesh(id, "plank_root")
			if mesh == null:
				print("        %s: model not used yet (doesn't fit %s)" % [model, Pieces.LIST[id].size])


## Rule 1: every model in the game is hand-built by a script in tools/asset_forge (no Play-Doh).
## A name made in a loop (f"gem_{kind}", piece + "__" + family) counts when both halves appear.
func test_every_model_has_a_build_script() -> void:
	var text := ""
	for f in _files("res://tools/asset_forge", ".py"):
		text += FileAccess.get_file_as_string(f) + "\n"
	var missing := []
	for f in _files("res://assets/models", ".glb"):
		var stem: String = f.get_file().get_basename()
		if not _made_by_script(stem, text, f.get_base_dir()):
			missing.append(f.trim_prefix("res://assets/models/"))
	check(missing.is_empty(), "every model has a build script (missing: %s)" % ", ".join(missing))


func _made_by_script(stem: String, text: String, _dir: String) -> bool:
	if FileAccess.file_exists("res://tools/asset_forge/builds/%s.py" % stem) or _said(stem, text):
		return true
	var bits := stem.split("_")
	for i in range(1, bits.size()):
		var left := "_".join(bits.slice(0, i)).trim_suffix("_")
		var right := "_".join(bits.slice(i)).trim_prefix("_")
		if left != "" and right != "" and _said(left, text) and _said(right, text):
			return true
	return false


func _said(w: String, text: String) -> bool:
	# ("_far": name + "_far" in a loop; "def name(": the decor scripts build each model in a function of its own name)
	for q in ["\"%s\"", "'%s'", "{%s}", "\"%s_{", "\"%s{", "'%s_{", "\"_%s\"", "def %s("]:
		if text.contains(q % w):
			return true
	return false


func _files(dir: String, ext: String) -> Array:
	var out := []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with(ext):
			out.append(dir + "/" + f)
	for sub in d.get_directories():
		if not sub.begins_with(".") and sub != "__pycache__":
			out.append_array(_files(dir + "/" + sub, ext))
	return out


## F114: wood from the start, stone needs a Mason's Table, brick needs it at level 2.
func test_building_styles_unlock_with_station_levels() -> void:
	check_eq(Pieces.station_for("plank_root"), "workbench", "wood is built at the Workbench")
	check_eq(Pieces.needed_level("wall", "cut_stone"), 1, "stone walls: any Mason's Table")
	check(Pieces.needed_level("wall", "clay_brick") >= 2, "brick walls: Mason's Table level 2")
	check(Pieces.needed_level("floor", "clay_brick") >= 2, "brick floors too")
