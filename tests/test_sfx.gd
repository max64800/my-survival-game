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


## Owner, Nov 25: F854 the mace sounded like a sword; F881 bats and snails died with a dwarf's cry; F883 the lantern
## refill sounded like a gulp of water. Each has its own sound now.
func test_mace_and_creature_death_sounds() -> void:
	for name in ["hit_blunt", "bat_death", "snail_death", "refill"]:
		check(Sfx._variants(name).size() >= 2, "%s has its own sounds" % name)
	check_eq(MonsterManager.death_sound("cave_bat"), "bat_death", "a bat's own last squeak")
	check_eq(MonsterManager.death_sound("rock_snail"), "snail_death", "a snail's shell cracks")
	var root := Node3D.new()
	tree.root.add_child(root)
	var auth := GameAuthority.new()
	root.add_child(auth)
	var me := Node3D.new()
	root.add_child(me)
	var ps := auth.add_player(auth.local_peer_id(), me)
	var mm := MonsterManager.new()
	mm.auth = auth
	ps.inventory.slots[Inventory.equip_index("weapon")] = {id = "mace_stone", count = 1}
	ps.weapon_drawn = true
	check_eq(mm.hit_sound(auth.local_peer_id(), false), "hit_blunt", "a mace lands with a dull knock")
	ps.inventory.slots[Inventory.equip_index("weapon")] = {id = "sword_copper", count = 1}
	check_eq(mm.hit_sound(auth.local_peer_id(), false), "hit", "a sword still slashes")
	mm.free()
	root.queue_free()


## Owner, Nov 25: "fix the enemy dying, it doesn't match anyone": no creature dies with the dwarf's old thump any more.
func test_every_creature_dies_with_its_own_kind_of_sound() -> void:
	for name in ["beetle_death", "spider_death", "bones_death", "ghost_death"]:
		check(Sfx._variants(name).size() >= 2, "%s has its own sounds" % name)
	check_eq(MonsterManager.death_sound("rock_beetle"), "beetle_death", "a beetle's shell cracks and it hisses out")
	check_eq(MonsterManager.death_sound("cave_spider"), "spider_death", "a spider hisses and curls up")
	check_eq(MonsterManager.death_sound("lost_miner"), "bones_death", "a skeleton miner falls into a heap of bones")
	check_eq(MonsterManager.death_sound("hald_ironbrow"), "ghost_death", "a ghost blows away as mist")
	for kind: String in Monsters.LIST:
		check(MonsterManager.death_sound(kind) != "death", "%s has its own death sound" % kind)
