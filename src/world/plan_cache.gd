class_name PlanCache
## Faster second load (owner, Nov 19; docs/research/Voxel game performance plan.md): working out where every crystal,
## plant, vine, boulder and pebble goes takes about a minute, the same answer every time for the same cave. So the
## first time, each answer is written to a file (user://plan_cache/); the next time the world opens, it's read back.
## A file is only used if it was made from the same cave (seed + layout) by the same planning code: the code's
## fingerprint is part of its name, so changing any planner simply makes it plan fresh (old files are cleaned up).

const DIR := "user://plan_cache"
const VERSION := 1
## The code every plan depends on (the cave's shape and the shared helpers); each planner adds its own file.
const SHARED := ["res://src/world/cave_maker.gd", "res://src/world/glow_placer.gd", "res://src/art/root_pillars.gd",
	"res://src/world/ruin_tower.gd", "res://src/art/ruin_treasure.gd"]

static var enabled := true  ## (tests switch it off)
static var _fingerprints := {}
static var _lock := Mutex.new()


## The saved plan `name` for this cave, or make it with `make` (and save it). `code` = the planner's own script path.
static func get_or_make(name: String, maker: CaveMaker, code: String, make: Callable) -> Variant:
	if not enabled:
		return make.call()
	var path := _path(name, maker, code)
	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		if f:
			var data: Variant = f.get_var(false)
			f.close()
			if data != null:
				return data
	var made: Variant = make.call()
	DirAccess.make_dir_recursive_absolute(DIR)
	_clean_old(name, maker, path)
	var tmp := path + ".tmp"
	var w := FileAccess.open(tmp, FileAccess.WRITE)
	if w:
		w.store_var(made, false)
		w.close()
		DirAccess.rename_absolute(tmp, path)  # (written whole first: a crash never leaves half a file)
	return made


static func _path(name: String, maker: CaveMaker, code: String) -> String:
	return "%s/%d_%d_%s_%s.bin" % [DIR, maker.seed, maker.made_layout, name, _fingerprint(code)]


## A short hash of the planning code (the shared files + this planner's own).
static func _fingerprint(code: String) -> String:
	_lock.lock()
	var fp: String = _fingerprints.get(code, "")
	if fp == "":
		var all := str(VERSION)
		for p in SHARED + [code]:
			all += FileAccess.get_file_as_string(p) if FileAccess.file_exists(p) else p
		fp = "%08x" % (all.hash() & 0xffffffff)
		_fingerprints[code] = fp
	_lock.unlock()
	return fp


## Plans of this cave made by older code are deleted (they'd never be used again).
static func _clean_old(name: String, maker: CaveMaker, keep: String) -> void:
	var prefix := "%d_%d_%s_" % [maker.seed, maker.made_layout, name]
	for f in DirAccess.get_files_at(DIR):
		if f.begins_with(prefix) and DIR.path_join(f) != keep:
			DirAccess.remove_absolute(DIR.path_join(f))
