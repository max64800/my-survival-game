extends TestCase
## F885 (owner, Nov 25): what you pick up pops up on the left, its picture and the amount.


func test_pickups_pop_up() -> void:
	var feed := PickupFeed.new()
	tree.root.add_child(feed)
	var bag := Inventory.new(Inventory.PLAYER_SIZE)
	bag.add("stone", 3)
	feed.watch(bag, false)
	check_eq(feed.shown(), 0, "what you start with doesn't pop up")
	bag.add("stone", 5)
	feed.watch(bag, false)
	check_eq(feed.shown(), 1, "5 stones picked up: one row")
	bag.add("stone", 2)
	feed.watch(bag, false)
	check_eq(feed.shown(), 1, "more stones top up the same row")
	check(feed._rows.stone.label.text.begins_with("+7"), "it says +7 (%s)" % feed._rows.stone.label.text)
	bag.add("copper_ore", 1)
	feed.watch(bag, true)
	check_eq(feed.shown(), 1, "quiet while a chest or the bag is open")
	bag.remove("stone", 4)
	feed.watch(bag, false)
	check_eq(feed.shown(), 1, "losing things doesn't pop up")
	for i in 8:
		bag.add(["fiber", "rootwood", "clay", "tin_ore", "moss", "dirt", "marble", "basalt"][i], 1)
		feed.watch(bag, false)
	check_eq(feed.shown(), PickupFeed.MAX_ROWS, "never more than %d rows" % PickupFeed.MAX_ROWS)
	feed._process(PickupFeed.SHOW + 0.1)
	check_eq(feed.shown(), 0, "they go after a few seconds")
	feed.queue_free()


## F911 (owner, Nov 26): taking things out of a chest pops up too; sorting your own bag doesn't.
func test_chest_takes_pop_up() -> void:
	check(not PickupFeed.quiet_for(false, true), "a chest open: not quiet")
	check(not PickupFeed.quiet_for(true, true), "bag and chest open: not quiet")
	check(PickupFeed.quiet_for(true, false), "only the bag open: quiet")
	check(not PickupFeed.quiet_for(false, false), "nothing open: not quiet")
	var feed := PickupFeed.new()
	tree.root.add_child(feed)
	var bag := Inventory.new(Inventory.PLAYER_SIZE)
	var chest := Inventory.new(8)
	chest.add("copper_ore", 4)
	chest.add("rootwood", 6)
	bag.add("stone", 2)
	feed.watch(bag, false)
	bag.changed.connect(func(): feed.watch(bag, PickupFeed.quiet_for(true, true)))
	Storage._move_slot(chest, 0, bag)  # the way the host moves a stack you take out
	check_eq(feed.shown(), 1, "a stack taken from the chest pops up")
	check(feed._rows.has("copper_ore") and feed._rows.copper_ore.label.text.begins_with("+4"), "it says +4 copper ore")
	var stone_i := -1
	for i in bag.slots.size():
		if bag.slots[i].get("id", "") == "stone":
			stone_i = i
	Storage._move_slot(bag, stone_i, chest)
	check_eq(feed.shown(), 1, "putting things into the chest doesn't pop up")
	feed.queue_free()


## F933 (owner, Nov 27): flattening or raising with the Mason's Shovel, the stone you lose shows like stone you get.
func test_shovel_shows_stone_spent() -> void:
	var feed := PickupFeed.new()
	tree.root.add_child(feed)
	var bag := Inventory.new(Inventory.PLAYER_SIZE)
	bag.add("stone", 10)
	feed.watch(bag, false, "masons_shovel")
	bag.remove("stone", 3)
	feed.watch(bag, false, "masons_shovel")
	check(feed._rows.has("-stone"), "spent stone pops up")
	check(feed._rows["-stone"].label.text.begins_with("-3"), "it says -3 (%s)" % feed._rows["-stone"].label.text)
	bag.remove("stone", 1)
	feed.watch(bag, false, "masons_shovel")
	check(feed._rows["-stone"].label.text.begins_with("-4"), "more spent tops up the row")
	bag.remove("stone", 2)
	feed.watch(bag, false, "pickaxe_stone")
	check(feed._rows["-stone"].label.text.begins_with("-4"), "crafting with other things in hand stays quiet")
	feed.queue_free()
