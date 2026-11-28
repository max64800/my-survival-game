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
	check_eq(mm.hit_sound(auth.local_peer_id(), false), "hit_mace", "a mace lands with its own thump (F707)")
	ps.inventory.slots[Inventory.equip_index("weapon")] = {id = "sword_copper", count = 1}
	check_eq(mm.hit_sound(auth.local_peer_id(), false), "hit", "a sword still slashes")
	mm.free()
	root.queue_free()


## Owner, Nov 25: "fix the enemy dying, it doesn't match anyone": no creature dies with the dwarf's old thump any more.
func test_every_creature_dies_with_its_own_kind_of_sound() -> void:
	for name in ["beetle_death", "bones_death", "ghost_death"]:
		check(Sfx._variants(name).size() >= 2, "%s has its own sounds" % name)
	check_eq(MonsterManager.death_sound("rock_beetle"), "beetle_death", "a beetle's shell cracks and it hisses out")
	check_eq(MonsterManager.death_sound("cave_spider"), "spider_death", "a spider hisses and curls up")
	check_eq(MonsterManager.death_sound("lost_miner"), "bones_death", "a skeleton miner falls into a heap of bones")
	check_eq(MonsterManager.death_sound("hald_ironbrow"), "ghost_boss_death", "a ghost boss wails as it blows away (round 8)")
	for kind: String in Monsters.LIST:
		check(MonsterManager.death_sound(kind) != "death", "%s has its own death sound" % kind)


## F707/F792 (owner's picks, sound rounds 6+7, Nov 26): each weapon its own hit, creatures cry when hit, spot you
## and move, the bosses roar, a bandage rips, and the dungeons whisper (stone) or moan (wooden mines).
func test_round_6_and_7_sounds() -> void:
	for name in ["spider_hurt", "spider_move", "spider_notice", "spider_death", "snail_hurt", "snail_move", "beetle_hurt",
			"beetle_notice", "bat_hurt", "bones_hurt", "bones_move", "bones_notice", "boss_notice", "boss_death",
			"ghost_notice", "ambient_stone", "ambient_wood", "bandage", "hit_mace", "hit_axe", "hit_axe_2h",
			"hit_warhammer", "hit_spear", "swing_heavy"]:
		check(Sfx._variants(name).size() >= 1, "%s has a sound" % name)
	check_eq(MonsterManager.WEAPON_HITS.mace_2h, "hit_warhammer", "the two-handed warhammer crushes")
	check_eq(MonsterManager.hurt_sound("tunnel_rat"), "bones_hurt", "a small skeleton's bones knock")
	check_eq(MonsterManager.hurt_sound("ghost_a"), "", "ghosts keep their own mist hit")
	check_eq(MonsterManager.notice_sound("rock_snail"), "", "snails stay quiet (owner: skip)")
	check_eq(MonsterManager.notice_sound("lost_miner"), "bones_notice", "a skeleton groans when it spots you")
	check_eq(MonsterManager.notice_sound("foreman"), "boss_notice", "the boss skeleton roars")
	check_eq(MonsterManager.death_sound("prop_warden"), "boss_death", "a boss skeleton's own last roar")
	check_eq(Monster.move_sound("cave_spider")[0], "spider_move", "a spider skitters")
	check(Monster.move_sound("cave_bat").is_empty(), "bats only flap")
	check_eq(Monster.move_sound("rock_beetle")[0], "beetle_move", "a beetle clicks along (round 8)")
	check_eq(MonsterManager.death_sound("ghost_lord"), "ghost_boss_death", "a ghost boss's own last wail (round 8)")
	check_eq(MonsterManager.death_sound("ghost_a"), "ghost_death", "small ghosts keep theirs")
	check(Sfx._variants("swing_light").size() >= 1, "one-handed swings swish")
	check(Sfx._variants("level_up").size() >= 1, "a new level: men shout Hey! (round 15, F944)")
	check(Sfx._variants("boss_cheer").size() >= 1, "a boss down: the dwarf cheers (round 9)")
	for s: String in ["warn_spider", "warn_bones", "warn_ghost", "warn_ghost_sting", "jump", "land", "ladder", "crossbow_shot", "crossbow_reload", "key_unlock"]:
		check(Sfx._variants(s).size() >= 1, "round 11 sound %s is in the game" % s)
	for m: Dictionary in Monsters.LIST.values():
		for a: Dictionary in m.get("attacks", []):
			if a.get("warn_sound") != null:
				check(Sfx._variants(a.warn_sound).size() >= 1, "%s: warning sound %s exists" % [a.name, a.warn_sound])


## Owner, Nov 27: F925 a bat's bite rang like a sword ('ding'); F937 cooking sounded like repairing; F934 skill-ups were
## too arcade-like. Sound round 12: beasts land with a body hit, the campfire sizzles, skill-ups are a small real sound.
func test_bites_cooking_and_skill_ups_have_their_own_sounds() -> void:
	for kind: String in ["cave_bat", "cave_spider", "rock_beetle"]:
		var s := MonsterManager.you_hit_sound(kind, 6.0)
		check_eq(s, "", "%s's bite adds no ring, only the dwarf's 'oof' (F925, owner Nov 28)" % kind)
	check(Sfx._variants("hurt").size() >= 1, "the dwarf's 'oof' that every hit plays exists")
	check_eq(MonsterManager.you_hit_sound("lost_miner", 6.0), "hit", "an armed skeleton still lands a weapon hit")
	check_eq(MonsterManager.you_hit_sound("ghost_lord", 20.0), "hit_heavy", "a big armed blow is heavy")
	check(GameAuthority.craft_sound_name("campfire") != "craft" or not Sfx.has("cook"), "the campfire sizzles once 'cook' is in")
	check_eq(GameAuthority.craft_sound_name("workbench"), "craft", "the workbench still hammers")
	check(Sfx.has(GameAuthority.craft_sound_name("campfire")), "the campfire's sound exists")
	check(Sfx.has(Sfx.pick("skill_up", "level_up")), "a skill-up has a sound")
	# Round 13 (owner's picks, Nov 28): a metal plate tap for a skill-up, 4 axe blows, 2 hammers, 2 sizzles.
	for want: Array in [["skill_up", 1], ["chop", 4], ["craft", 2], ["cook", 2]]:
		check_eq(Sfx._variants(want[0]).size(), want[1], "round 13: %s has the owner's %d picks" % want)
	check_eq(GameAuthority.craft_sound_name("campfire"), "cook", "the campfire sizzles")
