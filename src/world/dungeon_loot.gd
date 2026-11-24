class_name DungeonLoot
## Dungeon chests that fill up again (owner, Nov 19, F237; docs/design/zone1-dungeons-plan.md). An hour of play after
## someone takes something out, the chest is topped back up to what it started with: its recipe page too, which always
## teaches the same recipe. The clock only runs while the world is played (world_state.played, saved with the world).

const REFILL := 3600.0      ## seconds of play before a taken chest fills again (owner: 1 hour)
const CHECK_EVERY := 10.0   ## how often the host looks
const KEEP_AWAY := 30.0     ## it only refills while nobody is this close (loot never pops in under your nose)


## Host: makes a chest a dungeon chest and puts its loot in ({item: count}). Remembered in the save.
static func add(auth: GameAuthority, box_id: int, loot: Dictionary) -> void:
	for item in loot:
		auth.storage.put(box_id, item, int(loot[item]))
	var all: Dictionary = auth.world_state.get("dungeon_chests", {}).duplicate()
	all[str(box_id)] = {loot = loot, taken_at = -1.0}
	auth.world_state.dungeon_chests = all


## Host, every CHECK_EVERY seconds: starts a chest's clock when something is taken, refills it when the hour is up.
static func tick(auth: GameAuthority) -> void:
	var played: float = auth.world_state.get("played", 0.0)
	for key in auth.world_state.get("dungeon_chests", {}):
		var c: Dictionary = auth.world_state.dungeon_chests[key]
		var box: Dictionary = auth.storage.get_box(int(key))
		if box.is_empty():
			continue  # broken or picked up
		var missing := {}
		for item in c.loot:
			var n: int = int(c.loot[item]) - box.inv.count_of(item)
			if n > 0:
				missing[item] = n
		if missing.is_empty():
			c.taken_at = -1.0
		elif float(c.taken_at) < 0.0:
			c.taken_at = played
		elif played - float(c.taken_at) >= REFILL and not _someone_near(auth, box.node.global_position):
			for item in missing:
				auth.storage.put(int(key), item, missing[item])
			c.taken_at = -1.0


static func _someone_near(auth: GameAuthority, p: Vector3) -> bool:
	for pid in auth.players:
		if auth.players[pid].node.global_position.distance_to(p) < KEEP_AWAY:
			return true
	return false

