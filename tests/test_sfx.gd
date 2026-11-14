extends TestCase
## Every sound the game asks for must exist (a missing file is just silence, easy to miss).


func _sound_names_in_code() -> Dictionary:
	# Finds Sfx.play("x") / Sfx.ui("x") in every script under src/.
	var rx := RegEx.create_from_string('Sfx[.](?:play|ui)[(]"([a-z_]+)"')
	var found := {}
	var dirs := ["res://src"]
	while not dirs.is_empty():
		var d: String = dirs.pop_back()
		for sub in DirAccess.get_directories_at(d):
			dirs.append(d + "/" + sub)
		for f in DirAccess.get_files_at(d):
			if f.ends_with(".gd"):
				for m in rx.search_all(FileAccess.get_file_as_string(d + "/" + f)):
					found[m.get_string(1)] = d + "/" + f
	return found


func test_every_sound_used_in_code_loads() -> void:
	var found := _sound_names_in_code()
	check(found.size() >= 10, "found the sound calls (%d)" % found.size())
	for name in found:
		var list := Sfx._variants(name)
		check(list.size() >= 1, "sound '%s' (used in %s) has at least one file" % [name, found[name]])
		for s in list:
			check(s is AudioStream, "sound '%s' loads as audio" % name)
