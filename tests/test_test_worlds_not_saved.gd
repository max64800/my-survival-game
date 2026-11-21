extends TestCase
## Owner, Nov 21: the menu's dev Dungeon and Ruin test worlds are never saved (no test saves to delete).


func test_dev_test_worlds_never_save() -> void:
	var m = load("res://src/main.gd").new()
	check(m.saves_world(), "a normal world saves")
	m.dungeon_test = true
	check(not m.saves_world(), "a dungeon test world never saves")
	# (a Ruin test world turns dungeon_test on too: _start_ruin_test)
	m.dungeon_test = false
	m._saving = false
	check(not m.saves_world(), "robot runs never save either")
	m.free()
