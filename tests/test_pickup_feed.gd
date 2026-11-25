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
