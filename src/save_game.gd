class_name SaveGame
## Saving and loading a world (spec 5.11: autosave every 5 minutes and when you quit,
## plus a few backups in case one breaks).
##
## A save = the cave's seed (so the cave can be re-made exactly) + everything that changed
## since (the same "catch-up" package co-op friends get when they join) + each player's dwarf.
## Files live in user://saves/. Writing goes to a temp file first, then replaces the old save,
## and the previous saves are kept as .1 .2 .3 backups.
##
## Loading only reads plain data (store_var without objects), so a tampered save can't run code.

const FOLDER := "user://saves"
const VERSION := 1
const BACKUPS := 3


static func path_for(seed: int) -> String:
	return FOLDER.path_join("world_%d.save" % seed)


## Writes the save. Returns "" or an error message.
static func save(main: Node) -> String:
	var auth: GameAuthority = main.authority
	if auth == null or not auth.is_host():
		return "Only the host saves the world."
	DirAccess.make_dir_recursive_absolute(FOLDER)
	var snap := auth.snapshot()
	snap.erase("monsters")  # monsters come back on their own
	var players := {}
	for pid in auth.players:
		var ps: GameAuthority.PlayerState = auth.players[pid]
		var slot: int = main.player_slots.get(pid, 0)
		players[slot] = player_data(ps)
	# Friends who are offline right now keep the dwarf they had when they left.
	var offline = main.get("_loaded")
	if offline is Dictionary:
		for slot in offline.get("players", {}):
			if not players.has(slot):
				players[slot] = offline.players[slot]
	var map: MapData = main.hud.map_data if main.hud else null
	var data := {
		version = VERSION, seed = main.seed, saved_at = Time.get_datetime_string_from_system(),
		snap = snap, players = players,
		map = map.to_data() if map else {},
	}
	var path := path_for(main.seed)
	var tmp := path + ".tmp"
	var f := FileAccess.open_compressed(tmp, FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	if f == null:
		return "Couldn't write the save (%s)." % error_string(FileAccess.get_open_error())
	f.store_var(data, false)
	f.close()
	# Keep backups: .2 → .3, .1 → .2, current → .1, then the new one becomes current.
	for i in range(BACKUPS - 1, 0, -1):
		if FileAccess.file_exists("%s.%d" % [path, i]):
			DirAccess.rename_absolute("%s.%d" % [path, i], "%s.%d" % [path, i + 1])
	if FileAccess.file_exists(path):
		DirAccess.rename_absolute(path, path + ".1")
	DirAccess.rename_absolute(tmp, path)
	return ""


## Reads a save. Returns the data, or {} if it's missing or broken.
static func read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open_compressed(path, FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	if f == null:
		return {}
	var data = f.get_var(false)  # false = never create objects from the file
	f.close()
	if not data is Dictionary or data.get("version") != VERSION or not data.has("seed") or not data.has("snap"):
		return {}
	return data


## The newest save (for "Continue"), trying backups if the newest is broken.
static func newest() -> Dictionary:
	if not DirAccess.dir_exists_absolute(FOLDER):
		return {}
	var best := ""
	var best_time := 0
	for f in DirAccess.get_files_at(FOLDER):
		if f.ends_with(".save"):
			var p := FOLDER.path_join(f)
			var t := FileAccess.get_modified_time(p)
			if t > best_time:
				best_time = t
				best = p
	if best == "":
		return {}
	for candidate in [best, best + ".1", best + ".2", best + ".3"]:
		var d := read(candidate)
		if not d.is_empty():
			return d
	return {}


static func player_data(ps: GameAuthority.PlayerState) -> Dictionary:
	return {inv = ps.inventory.to_data(), vitals = ps.vitals.to_data(), progress = ps.progress.to_data(),
		fuel = ps.fuel, pos = ps.node.global_position, bed = ps.bed_pos, slot = ps.selected_slot, seen = ps.seen.keys()}


static func apply_player(ps: GameAuthority.PlayerState, d: Dictionary) -> void:
	ps.inventory.load_data(d.inv)
	ps.vitals.load_data(d.vitals)
	ps.progress.load_data(d.progress)
	ps.fuel = d.fuel
	ps.bed_pos = d.bed
	ps.selected_slot = d.slot
	for id in d.seen:
		ps.seen[id] = true
	ps.node.global_position = d.pos
