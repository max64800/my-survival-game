extends TestCase
## Dungeon variety (owner, Nov 20, F237; traps-and-variety.md "Variety"): picked from world seed + dungeon only.

const LAYOUT := {
	swap_wings = [["east_wing", "west_wing"]],
	hidden = ["buried_a", "buried_b", "cracked_wall", "boulder", "lever", "buried_c"],
	spots = {chest_hall = 3, bear_jaws_1 = 2, tripwire_1 = 3, trapped_chest = 2},
	timed = ["carts", "pendulum_1"],
}


func test_same_world_same_dungeon_same_picks() -> void:
	check_eq(DungeonVariety.pick(42, "brassgate_vault", LAYOUT), DungeonVariety.pick(42, "brassgate_vault", LAYOUT), "always the same")
	var seen := {}
	for s in 20:
		seen[str(DungeonVariety.pick(s, "brassgate_vault", LAYOUT))] = true
	check(seen.size() > 10, "different worlds look different (%d of 20)" % seen.size())
	check(DungeonVariety.pick(7, "brassgate_vault", LAYOUT) != DungeonVariety.pick(7, "emberdeep_forge", LAYOUT) or DungeonVariety.pick(8, "brassgate_vault", LAYOUT) != DungeonVariety.pick(8, "emberdeep_forge", LAYOUT), "dungeons differ in one world")


func test_picks_stay_inside_the_rules() -> void:
	var mirrored := 0
	var swapped := 0
	for s in 400:
		var p := DungeonVariety.pick(s, "the_quiet_barrows", LAYOUT)
		mirrored += int(p.mirror)
		swapped += p.swapped.size()
		check_eq(p.hidden.size(), 3, "3 hidden spots")
		var uniq := {}
		for h in p.hidden:
			check(LAYOUT.hidden.has(h), "a real hidden spot")
			uniq[h] = true
		check_eq(uniq.size(), 3, "no spot twice")
		for t in LAYOUT.spots:
			check(p.spots[t] >= 0 and p.spots[t] < LAYOUT.spots[t], "%s sits in one of its places" % t)
		check_eq(p.spots.keys().size(), LAYOUT.spots.size(), "nothing else moves")
		for t in LAYOUT.timed:
			check(p.timing[t] in [0, 1, 2], "one of 3 patterns")
	check(mirrored > 150 and mirrored < 250, "about half the worlds are mirrored (%d of 400)" % mirrored)
	check(swapped > 150 and swapped < 250, "about half swap the wings (%d of 400)" % swapped)


func test_adding_a_chest_keeps_the_other_picks() -> void:
	var more := LAYOUT.duplicate(true)
	more.spots.new_chest = 3
	var a := DungeonVariety.pick(42, "brassgate_vault", LAYOUT)
	var b := DungeonVariety.pick(42, "brassgate_vault", more)
	b.spots.erase("new_chest")
	check_eq(a, b, "the other picks don't change")
	check_eq(DungeonVariety.pick(1, "x", {}).hidden, [], "an empty room file moves nothing")
