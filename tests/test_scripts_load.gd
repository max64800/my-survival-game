extends TestCase
## Every script in the game must load. (Nov 14: hud.gd had a type error that broke the game at
## startup, but no check used hud.gd, so all checks still passed. This catches that.)


func test_every_script_compiles() -> void:
	var broken: Array[String] = []
	var count := 0
	var dirs := ["res://src"]
	while not dirs.is_empty():
		var d: String = dirs.pop_back()
		for sub in DirAccess.get_directories_at(d):
			dirs.append(d + "/" + sub)
		for f in DirAccess.get_files_at(d):
			if not f.ends_with(".gd"):
				continue
			count += 1
			var s := load(d + "/" + f) as Script
			if s == null or not s.can_instantiate():
				broken.append(d + "/" + f)
	check(count > 50, "found the game's scripts (%d)" % count)
	check(broken.is_empty(), "scripts that don't compile: %s" % str(broken))
