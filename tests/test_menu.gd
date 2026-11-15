extends TestCase
## The menus (F87): the main menu lists your worlds and can delete them (after asking);
## new worlds get their own file and name; Escape shows Resume / Save / main menu / Quit.


func _fake_world(file: String, seed: int, world_name: String) -> String:
	DirAccess.make_dir_recursive_absolute(SaveGame.folder())
	var path := SaveGame.folder().path_join(file)
	var f := FileAccess.open_compressed(path, FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	f.store_var({version = SaveGame.VERSION, seed = seed, name = world_name, saved_at = "2026-11-15T20:00:00",
		snap = {}, players = {}, map = {}}, false)
	f.close()
	return path


func _clean() -> void:
	if not DirAccess.dir_exists_absolute(SaveGame.folder()):
		return
	for f in DirAccess.get_files_at(SaveGame.folder()):
		if f.begins_with("world_77"):
			DirAccess.remove_absolute(SaveGame.folder().path_join(f))


func test_worlds_are_listed_and_deleted() -> void:
	_clean()
	var a := _fake_world("world_771_1.save", 771, "Mossy Home")
	var b := _fake_world("world_772_2.save", 772, "")
	var c := _fake_world("world_772_3.save", 772, "Second try")  # same seed, different world
	_fake_world("world_772_3.save.1", 772, "Second try")  # a backup: not its own world
	var names := {}
	for w in SaveGame.list_worlds():
		names[w.path] = w.name
	check_eq(names.get(a, ""), "Mossy Home", "a named world is listed by its name")
	check_eq(names.get(b, ""), "Cave 772", "an old save without a name gets one")
	check(names.has(c), "two worlds can share a cave seed")
	check(not names.has(c + ".1"), "backups aren't listed as worlds")
	check_eq(SaveGame.load_world(a).path, a, "playing a world saves back to its own file")
	SaveGame.delete_world(c)
	check(not FileAccess.file_exists(c) and not FileAccess.file_exists(c + ".1"), "deleting removes the world and its backups")
	check(FileAccess.file_exists(a), "and leaves the other worlds alone")
	SaveGame.delete_world("user://somewhere_else.save")  # never deletes outside the saves folder
	check(SaveGame.new_path(5) != SaveGame.path_for(5), "a new world never overwrites an old one with the same seed")
	_clean()


func test_main_menu_rows_and_delete_asks_first() -> void:
	_clean()
	var a := _fake_world("world_773_1.save", 773, "Deep Hall")
	var menu: CanvasLayer = load("res://src/ui/start_menu.gd").new()
	tree.root.add_child(menu)
	await tree.process_frame
	var row: Node = menu.find_child("World_world_773_1", true, false)
	check(row != null, "the world has a row in the main menu")
	if row:
		check(row.has_node("Play") and row.has_node("Host") and row.has_node("Delete"), "with Play, Host and Delete")
	var played := []
	menu.connect("continue_game", func(d: Dictionary): played.append(d))
	if row:
		(row.get_node("Play") as Button).pressed.emit()
	check(played.size() == 1 and played[0].get("path", "") == a, "Play opens that world")
	menu.call("ask_delete", a, "Deep Hall")
	check(FileAccess.file_exists(a), "Delete only asks first")
	menu.call("_delete_confirmed")
	check(not FileAccess.file_exists(a), "and deletes after 'Delete forever'")
	menu.queue_free()
	_clean()


func test_escape_menu_buttons() -> void:
	var hud := Hud.new()
	tree.root.add_child(hud)
	await tree.process_frame
	hud.set_paused(true)
	check(hud.is_paused(), "Escape shows the pause screen")
	var box: Node = hud.find_child("PauseButtons", true, false)
	check(box != null, "with buttons")
	var got := []
	hud.pause_pressed.connect(func(w: String): got.append(w))
	for b in ["resume", "save", "menu", "quit"]:
		if box and box.has_node(b):
			(box.get_node(b) as Button).pressed.emit()
	check_eq(got, ["resume", "save", "menu", "quit"], "Resume, Save, main menu and Quit all work")
	hud.queue_free()
