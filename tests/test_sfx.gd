extends TestCase
## Every sound the game asks for in Step 1 must exist (a missing file is just silence, easy to miss).

const USED := ["dig_rock", "dig_soft", "dig_break", "crystal", "clink", "step", "pickup", "refill", "swing", "open", "close"]


func test_every_used_sound_loads() -> void:
	for name in USED:
		var list := Sfx._variants(name)
		check(list.size() >= 1, "sound '%s' has at least one file" % name)
		for s in list:
			check(s is AudioStream, "sound '%s' loads as audio" % name)


func test_code_only_uses_listed_sounds() -> void:
	# Look through the code for Sfx.play("x") / Sfx.ui("x") and make sure each x is in USED.
	var rx := RegEx.create_from_string('Sfx[.](?:play|ui)[(]"([a-z_]+)"')
	var found := {}
	for path in ["res://src/player/dwarf.gd", "res://src/items/drop.gd", "res://src/net/game_authority.gd", "res://src/ui/hud.gd"]:
		var text := FileAccess.get_file_as_string(path)
		for m in rx.search_all(text):
			found[m.get_string(1)] = true
	check(found.size() >= 8, "found the sound calls (%d)" % found.size())
	for name in found:
		check(name in USED, "sound '%s' is used in code but not in the test list" % name)
